[bits 64]
[org 0x4000]

;=============================================================================
;          HyperVisor for AMD - Designed by The Ghost In The Matrix
;=============================================================================

Hv_entry:
    cli                         ; Disable hardware interrupts
    
    ; --- 1. Host Stack Setup & Write Protection ---
    mov rsp, 0x0003F000         ; Set up a pristine, isolated Host stack
    mov rax, cr0
    bts rax, 16                 ; Enable Write Protect (WP) bit to prevent code injection
    mov cr0, rax

    ; --- 2. Enable SVME & Backup Original EFER ---
    mov ecx, 0xC0000080         ; EFER MSR
    rdmsr
    bts eax, 12                 ; Enable SVME (Secure Virtual Machine Enable) for Host
    wrmsr
    push rax                    ; Save modified EAX to stack (Takes only 1 byte!)
    push rdx                    ; Save modified EDX to stack (Takes only 1 byte!)

    ; --- 3. Wire Host Save Area (HSAVE) ---
    mov ecx, 0xC0010114         ; VM_HSAVE_PA MSR
    mov eax, 0x00003000        
    xor edx, edx                
    wrmsr

    ; --- 4. Purge RAM for Absolute Sterility ---
    mov rdi, 0x00010000
    mov rcx, 5120               ; Clear 40KB (0x10000 to 0x1AFFF) - Cleans NPT and GPT buffers
    xor rax, rax
    rep stosq

    mov rdi, 0x00002000
    mov rcx, 512                ; Clear VMCB page (4KB at 0x2000)
    rep stosq


; Pages: NPT (Physical Cage) + GPT (4-Level Virtual Isolation Dungeon)
Pages:
    ; --- 5. Wire Host Nested Page Tables (NPT) ---
    mov qword [0x00010000], 0x00011003   ; PML4 -> Points to PDPT
    mov qword [0x00011000], 0x00012003   ; PDPT -> Points to PD

    mov qword [0x00012000], 0x00013003   ; Entry 1 -> PT1 (0x13000)
    mov qword [0x00012008], 0x00014003   ; Entry 2 -> PT2 (0x14000)
    mov qword [0x00012010], 0x00015003   ; Entry 3 -> PT3 (0x15000)

    ; Atomic Identity Mapping Loop for NPT (Maps the first 2MB)
    mov rdi, 0x00013000        
    mov rcx, 512               
    mov rax, 0x0000000000000003 ; Present + R/W
.map_global_zone:
    mov [rdi], rax             
    add rax, 0x1000             
    add rdi, 8                  
    loop .map_global_zone       

    mov dword [0x00002008], 0xFFFFFFFF   ; Open intercept traps in VMCB

    ; --- 6. Wire Isolated Guest Page Tables (GPT) (0x17000 to 0x1AFFF) ---
    mov qword [0x00017000], 0x00018003   ; Guest PML4 -> Guest PDPT
    mov qword [0x00018000], 0x00019003   ; Guest PDPT -> Guest PD
    mov qword [0x00019000], 0x0001A003   ; Guest PD   -> Guest PT
    
    ; Virtual Dungeon: Map ONLY the 4KB Payload page at 0x40000 (Offset 0x200 in PT)
    mov qword [0x0001A200], 0x00040003   ; Present + R/W (Single 4KB page restriction)

    ; Activate Nested Paging in VMCB Control Area
    Active_NPT:
    mov qword [0x0000207C], 1            ; NPT = ON
    mov qword [0x00002090], 0x00010000   ; NPT CR3 pointing to PML4 at 0x10000

; 7. Construct Secure Host IDT at 0x16000 (Ghosts Qword Optimization)
Setup_IDT:
    mov rax, .unknown_exit              ; Load atomic Triple Fault bunker address
    
    mov [0x00016030], ax                ; Bits 0-15: Offset Low
    mov word [0x00016032], 0x0008       ; Bits 16-31: Host Code Segment Selector
    mov word [0x00016034], 0x8E00       ; Bits 32-47: Interrupt Gate Flags (Ring 0, Present)
    
    shr rax, 16
    mov [0x00016036], ax                ; Bits 48-63: Offset Middle
    
    shr rax, 16
    mov [0x00016038], rax               ; Bits 64-127: Single Qword Injection (Handles Upper Offset & Reserved)

    lidt [idt_descriptor]               ; Commit IDT to CPU register

; 8. Restore Saved MSRs & Configure VMCB Guest State Area

Setup_Guest_State:
    pop rdx                            
    pop rax                             
    btr eax, 12                         ; Clear SVME bit for Guest (Hides hypervisor existence)
    mov [0x000022D0], eax       
    mov [0x000022D4], edx

    ; Set intercept parameters in Control Area
    mov dword [0x00002000], 0x00000100   ; Intercept RDTSC + Double Fault (#DF)
    mov dword [0x0000200C], 0x00000001   ; Intercept system state changes
    mov dword [0x00002058], 1            ; ASID = 1 (Prevents TLB flush overhead)

    ; Configure execution entry points for Guest
    mov qword [0x00002200], 0x00040000   ; Guest RIP = Payload base address at 0x40000
    mov qword [0x00002208], 0x00000002   ; Guest RFLAGS

    mov rax, cr0
    mov [0x00002268], rax       ; Guest CR0
    
    mov qword [0x00002270], 0x00017000   ; Guest CR3 points strictly to 0x17000 dungeon
    
    mov rax, cr4
    mov [0x00002278], rax       ; Guest CR4

    ; Mandatory AMD CPU segment attributes required for VMRUN consistency check
    mov word [0x000021F2], 0x0008        ; Guest CS Selector
    mov qword [0x000021F4], 0x00009B00   ; Guest CS Attributes (64-bit Protected Mode Code)
    mov word [0x00002202], 0x0010        ; Guest SS Selector
    mov qword [0x00002204], 0x00009300   ; Guest SS Attributes (Data Segment)


; 9. Launch Hypervisor 

Launch_VM:
    mov rax, 0x0000000000002000          ; Hardwired constraint: RAX must contain VMCB pointer
    vmrun                                ; Fire! Hypervisor active, Guest caged


; 10. VM EXIT Engine & Clock Freeze Handler

VM_Exit_Handler:
    mov ebx, [0x00002070]       ; Fetch Exit Code from VMCB Control Area
    cmp ebx, 0x0000005E         ; Did the Guest invoke RDTSC?
    jne .unknown_exit           ; Unrecognized exit/anomaly -> Kill the entire runtime!

    mov qword [0x00002100], 0xFA7       ; Force static timeframe into Guest RAX
    mov qword [0x00002108], 0x00000000   ; Reset Guest RDX
    
    mov rax, [0x00002200]
    add rax, 2
    mov [0x00002200], rax

    jmp Launch_VM               ; Resume Guest execution seamlessly (Time frozen, exploit neutralized)

    .unknown_exit:
    xor rax, rax
    mov cr3, rax                ; Smash CR3 register entirely (Null page pointer destroys Paging context)
    int 3                       ; Trigger hardware crash cascade - Instantly purges volatile RAM context

; Aligned Hardware Descriptors

    align 8
idt_descriptor:
    dw 4095                     ; IDT Limit
    dq 0x0000000000016000       ; Physical Base address of Host IDT mapping
