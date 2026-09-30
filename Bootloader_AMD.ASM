[bits 16]
[org 0x7C00]

;=============================================================================
;     Bare-Metal 3-Stage Bootloader - Designed by The Ghost In The Matrix
;=============================================================================

boot_entry:
    cli                         ; Disable real mode interrupts execution
    xor ax, ax                  ; Segment clean state sterilization
    mov es, ax                  ; you cant do xor segments only ax 
    mov ds, ax                  ; because ax (bits 16) = rax (64 bits)
    mov ss, ax

Protecting_mode_entry:
    lgdt [gdt_descriptor]       ; Commit temporary 32-bit GDT to the GDTR
    mov eax, cr0
    bts eax, 0                  ; Set bit 0 (PE - Protection Enable) to trigger Protected Mode
    mov cr0, eax

    jmp 0x08:entry_32bit        ; Far jump to clear real mode pre-fetch pipeline execution

[bits 32]
entry_32bit:
    ; --- STEP 0: Prepare EAX Register for SKINIT Instruction ---
    ; The SKINIT instruction requires EAX to contain the starting physical address
    ; of the Secure Loader Block (SLB). The address must be 4KB aligned.
    mov eax, 0x00010000         
    skinit                      ; Trigger hardware Secure Startup, reset cores, and intercept SMM

    ; --- STEP 1: Load Protected Mode Segment Selectors ---
    mov ax, 0x10                ; Load flat 32-bit data descriptor (0x10 offset in GDT)
    mov ds, ax
    mov ss, ax 
    mov es, ax

    ; --- STEP 2: Activate PAE (Physical Address Extension) ---
    mov eax, cr4
    or eax, 1  Points to PDPT at 0xA000 (Present + Read/Write)
    mov dword [0xA000], 0xB003  ; PDPT Entry -> Points to PD at 0xB000 (Present + Read/Write)
    mov dword [0xB000], 0xC003  ; PD Entry   -> Points to PT at 0xC000 (Present + Read/Write)

    ; --- STEP 5: Construct Page Table Entries (PTEs - 64-bit Aligned) ---
    ; Structural Fix: Every entry occupies exactly 8 bytes (0x8 byte increments) to avoid Triple Faults.
    mov dword [0xC000], 0x00000003  ; Maps 0x0000  to 0x0FFF (Present + Read/Write)
    mov dword [0xC008], 0x00001003  ; Maps 0x1000  to 0x1FFF
    mov dword [0xC010], 0x00002003  ; Maps 0x2000  to 0x2FFF (VMCB Area)
    mov dword [0xC018], 0x00003003  ; Maps 0x3000  to 0x3FFF (HSAVE Area)
    mov dword [0xC020], 0x00004003  ; Maps 0x4000  to 0x4FFF (Hypervisor Entry Zone)
    mov dword [0xC028], 0x00005003  ; Maps 0x5000  to 0x5FFF   
    mov dword [0xC030], 0x00006003  ; Maps 0x6000  to 0x6FFF
    mov dword [0xC038], 0x00007003  ; Maps 0x7000  to 0x7FFF (Boot Sector Context Location)

    ; Commit Paging Base into Control Register 3
    mov eax, 0x9000		
    mov cr3, eax

    ; --- STEP 6: Enable Long Mode & AMD Secure Virtual Machine (SVM) ---
    mov ecx, 0xC0000080         ; Access EFER MSR (Extended Feature Enable Register)
    rdmsr 
    or eax, (1 << 8) | (1 << 12); Set Bit 8 (Long Mode Enable) & Bit 12 (Secure Virtual Machine Enable)
    wrmsr

    ; --- STEP 7: Fire Paging Context and Flip CPU into 64-bit Long Mode ---
    mov eax, cr0
    or eax, 1 << 31             ; Enable Bit 31 (PG - Paging) to execute the architecture switch
    mov cr0, eax		

    ; Far jump to break segment limits and cross officially into 64-bit hardware execution
    jmp 0x18:entry_64bit        

[bits 64]
entry_64bit:
    ; --- Activate Advanced Kernel Exploitation Safeguard ---
    mov rax, cr4
    or rax, 1 << 20             ; Set bit 20 (SMEP - Supervisor Mode Execution Prevention) to lock Ring 0
    mov cr4, rax

    ; --- Hardware Constraint: Bind Host Save Area (HSAVE) ---
    mov ecx, 0xC0010114         ; VM_HSAVE_PA MSR (AMD specific hardware specification address)
    mov eax, 0x00003000        
    xor edx, edx                
    wrmsr

    jmp 0x4000                  ; Vector execution directly into the Hypervisor core address space

;----------------------------------
; Hardware Descriptor Structures
;----------------------------------
    align 8
gdt_start:
    dq 0x0000000000000000       ; Null Descriptor
    dq 0x00cf9a000000ffff       ; 32-bit Code Segment Descriptor (Offset 0x08)
    dq 0x00cf92000000ffff       ; 32-bit Data Segment Descriptor (Offset 0x10)
    dq 0x00209a0000000000       ; 64-bit Code Segment Descriptor (Offset 0x18)
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1  ; GDT Limit Size
    dd gdt_start                ; Physical memory address base allocation layout

; --- Hardcoded Master Boot Record Magic Geometry Constraints ---
times 510-($-$$) db 0
dw 0xAA55                       ; Hardwired MBR validation marker signature for standard BIOS boot sequence

;=================================
; Documentation Context Block
;=================================
; Bootloaders are limited to 512 bytes (4096 bits) on Intel or AMD CPUs.
; When the BIOS starts, it scans for 0xAA55 as the last byte sequence of the 
; sector, then loads your bootloader directly into address 0x7C00 in RAM. 
; Hope this documentation context helped you understand the architectural execution!
; You can ask me in the repository comments for a detailed code explanation, 
; I'm here to help the low-level security development community!

