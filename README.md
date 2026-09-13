[bits 64]
[org 0x4000]

;=============================================================================
;          HyperVisor for AMD - Designed by The Ghost In The Matrix
;=============================================================================

;0x0000800000000000 ;bit 47 SVE 

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
    or eax, 0x00801800                
    ; Bit 11: NXE (No-Execute Enable) for page protection   0x00000800
    ; Bit 12: SVME (Secure Virtual Machine Enable)          0x00001000
    ; Bit 23: SEV_ENABLE (Secure Encrypted Virtualization)  0x00800000
    wrmsr
    push rax                    ; Save modified EAX to stack (Takes only 1 byte!)
    push rdx                    ; Save modified EDX to stack (Takes only 1 byte!)

    ; --- 3. Wire Host Save Area (HSAVE) ---
    mov ecx, 0xC0010114         ; VM_HSAVE_PA MSR
    mov eax, 0x00003000        
    xor edx, edx                
    wrmsr

    ; --- 4. Purge RAM for Absolute Sterility ---    
    ; Btw BIOS always makes the low memory dirty, 
    ; so we purge this upper 40KB block for clean NPT/GPT structures.
    mov rdi, 0x00010000
    mov rcx, 5120               ; Clear 40KB (0x10000 to 0x1AFFF) - Cleans NPT and GPT buffers
    xor eax, eax
    rep stosq

    mov edi, 0x00002000
    mov ecx, 512                ; Clear VMCB page (4KB at 0x2000)
    rep stosq
    
    ; --- Loop 1: Mapping the Secure Hypervisor Base inside PT1 (0MB to 2MB) ---
    mov rdi, 0x00013000         ; Base physical address of PT1
    mov rcx, 512                ; Fill all 512 entries (Maps a solid 2MB block)

    ; Target: Start strictly from Physical Address 0x00000000 + SEV Bit 47 + Present + R/W
    mov rax, 0x0000800000000003 ; Encrypted base for Host structures and code
    
.map_global_zone:
    ; Safety Check: If we hit the Guest region inside this 2MB block (0x40000)
    ; we conditionally STRIP the encryption bit so the Host can read it
    cmp rax, 0x0000800000040003 ; Are we at the 0x40000 boundary? (With SEV bit applied)
    jne .commit_pt1_entry
    
    ;Strip SEV Bit 47 only for the 4KB Guest page
    and rax, 0xFFFF7FFFFFFFFFFF ; Turn OFF Bit 47 strictly for the Guest cell
    mov [rdi], rax
    or rax, 0x0000800000000000 ; Restore SEV Mask for subsequent Host mappings
    jmp .next_pt1_step

.commit_pt1_entry:
    mov [rdi], rax             

.next_pt1_step:
    add rax, 0x1000             ; Advance exact physical address template by 4KB
    add rdi, 8                  ; Advance table slot selector
    loop .map_global_zone       

    ; --- Loop 2: Mapping PT2 for Clean Linear Extended Memory (2MB to 4MB) ---
    mov rdi, 0x00014000         ; Base physical address of PT2
    mov rcx, 512                ; Map the next 2MB block systematically
    ; Target: Start exactly where PT1 finished -> Physical 2MB (0x200000) + SEV Enabled
    mov rax, 0x0000800000200003 
    
.map_HyperVisor_zone:
    mov [rdi], rax
    add rax, 0x1000             ; Advance physical memory index lineally
    add rdi, 8                  ; Move cursor forward
    loop .map_HyperVisor_zone



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

; --------------- TSS (Task Stack Sagment) ---------------

    ;1: Dynamic TSS Descriptor Injection into Bootloader GDT 

    sub rsp, 10                 ; Allocate 10 bytes on stack for GDTR structure
    sgdt [rsp]                  ; Read current GDT base and limit from the CPU
    mov rbx, [rsp + 2]          ; rbx = Physical base address of Bootloader GDT
    movzx rcx, word [rsp]       ; rcx = Current GDT limit in bytes
    add rsp, 10                 ; Clean up temporary stack allocation

    ; Calculate exact injection target (First free byte at the end of current GDT)
    lea rdi, [rbx + rcx + 1]    ; rdi points to the injection offset

    ; Inject 16-byte Expanded TSS Descriptor into the existing GDT
    ; Hardwired to the pristine physical address 0x0001B000
    mov word [rdi], 0x0208      ; TSS Limit (520 bytes for TSS structure allocation)
    mov word [rdi + 2], 0xB000  ; TSS Base Low (Bits 0-15 of 0x0001B000)
    mov byte [rdi + 4], 0x01    ; TSS Base Middle (Bits 16-23 of 0x0001B000 -> 0x01)
    mov byte [rdi + 5], 0x89    ; Access Type (TSS Present, Busy)
    mov byte [rdi + 6], 0x00    ; Granularity
    mov byte [rdi + 7], 0x00    ; TSS Base High (Bits 24-31 of 0x0001B000 -> 0x00)
    mov qword [rdi + 8], 0x0000000000000000 ; Upper 32-bits of TSS Base + Reserved

    ; Update GDTR with the expanded GDT Limit (+16 bytes)
    sub rsp, 10
    sgdt [rsp]
    add word [rsp], 16          ; Increase the GDT limit by 16 bytes
    lgdt [rsp]                  ; Reload the expanded GDT configuration into CPU
    add rsp, 10

    ;2: Initialize TSS Structure at 0x1B000 & Wire IST1 
    mov rdi, 0x0001B000
    mov rcx, 132                ; Atomic purge of 528 bytes in RAM
    xor rax, rax
    rep stosq

    ; Configure IST1 at offset 36 (0x24) inside the TSS
    ; Wires an isolated emergency stack frame right above the TSS block at 0x1C000
    mov qword [0x0001B024], 0x0001C000 ; IST1 Stack Pointer redirection

    ;3: Commit Task Register (TR) to Activate TSS 
    mov ax, cx                  ; Fetch the original GDT limit
    inc ax                      ; Increment to resolve the precise TSS Selector offset
    ltr ax                      ; Hardware instruction: Load Task Register. TSS Active! 

;--------------------- Guest Set Area --------------------
Setup_Guest_State:
    pop rdx                            
    pop rax                             
    btr eax, 12                         ; Clear SVME bit for Guest (Hides hypervisor existence)
    btr eax, 23
    mov [0x000022D0], eax       
    mov [0x000022D4], edx

    ; Set intercept parameters in Control Area
    mov dword [0x00002000], 0x00000100   ; Intercept RDTSC + Double Fault (#DF)
    mov dword [0x0000200C], 0x00000001   ; Intercept system state changes
    mov dword [0x00002058], 1            ; ASID = 1 (Prevents TLB flush overhead)

    ; Configure execution entry points for Guest
    mov qword [0x00002200], 0x00040000   ; Guest RIP = Payload base address at 0x40000
    mov qword [0x00002208], 0x00000002   ; Guest RFLAGS

 ;   mov rax, cr0
 ;   mov [0x00002268], rax       ; Guest CR0
    
    mov dword [0x00002004], 0x00000011  ; Enforce absolute lock on CR0 and CR4 execution
    ;0x00000001 locking CR0 
    ;0x00000010 locking CR4 

    mov qword [0x00002270], 0x00017000   ; Guest CR3 points strictly to 0x17000 dungeon
    
;    mov rax, cr4
;    mov [0x00002278], rax       ; Guest CR4

    ; Mandatory AMD CPU segment attributes required for VMRUN consistency check
    mov word [0x000021F2], 0x0008        ; Guest CS Selector
    mov qword [0x000021F4], 0x00009B00   ; Guest CS Attributes (64-bit Protected Mode Code)
    mov word [0x00002202], 0x0010        ; Guest SS Selector
    mov qword [0x00002204], 0x00009300   ; Guest SS Attributes (Data Segment)

    ;--------------------- Host Set Area ---------------------
    ; 1. Commit Host Control Registers to VMCB
    mov rax, cr0               
    mov [0x00002280], rax       ;Host CR0 Save Slot 
    
    mov dword [0x00002004], 0x00000011  ; Enforce absolute lock on CR0 and CR4 execution
    ;0x00000001 locking CR0 
    ;0x00000010 locking CR4 

    mov rax, cr3
    mov [0x00002288], rax       ; Host CR3 Save Slot (Pristine Host Page Context)

    mov rax, cr4
    mov [0x00002290], rax       ;Host CR4 Save Slot (Includes active GMET frame)

    ; 2. Fetch original Host EFER context from the stack backup
    ; (Since you pushed RAX/RDX earlier, we read the exact values without popping yet)
    mov rax, [rsp + 8]          ; Read backed-up Host EAX (EFER Low)
    mov rdx, [rsp]              ; Read backed-up Host EDX (EFER High)
    mov [0x00002298], rax       ; Host EFER Low Save Slot
    mov [0x0000229C], rdx       ; Host EFER High Save Slot

    ; 3. Commit Host Stack Pointer
    mov qword [0x000022D8], 0x0003F000 ; Host RSP Save Slot (Restores stack immediately on exit)

; 9. Launch Hypervisor 

Launch_VM:
    mov rax, 0x0000000000002000          ; Hardwired constraint: RAX must contain VMCB pointer 0x2000 - 0x3000
    vmrun                                ; Fire! Hypervisor active, Guest caged


; 10. VM EXIT Engine & Clock Freeze Handler

VM_Exit_Handler:
push rax
push rbx
push rcx
push rdx
push rsp 
mov rsp, 0x3F000

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

; LIFO (Last in first out)
pop rdx
pop rcx
pop rbx
pop rax
pop rsp
; Aligned Hardware Descriptors

    align 8
idt_descriptor:
    dw 4095                     ; IDT Limit
    dq 0x0000000000016000       ; Physical Base address of Host IDT mapping
