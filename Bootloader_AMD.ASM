[bits 16]
[org 0x7C00]

boot_entry:
    cli
    xor ax, ax
    mov es, ax
    mov ds, ax
    mov ss, ax

Protecting_mode_entry:
    lgdt [gdt_descriptor]
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    jmp 0x08:entry_32bit

[bits 32]
entry_32bit:
    mov ax, 0x10
    mov ds, ax
    mov ss, ax 
    mov es, ax

    mov eax, cr4
    or eax, 1 << 5             ;  PAE 
    mov cr4, eax

    mov edi, 0x9000
    xor eax, eax
    mov ecx, 4096
    rep stosd

    ; PML4, PDPT, PD
    mov dword [0x9000], 0xA003 
    mov dword [0xA000], 0xB003 
    mov dword [0xB000], 0xC003 

    ;--------------- PT  ---------------
    mov dword [0xC000], 0x00000003 
    mov dword [0xC008], 0x00001003    
    mov dword [0xC010], 0x00002003
    mov dword [0xC018], 0x00003003
    mov dword [0xC020], 0x00004003
    mov dword [0xC028], 0x00005003    
    mov dword [0xC030], 0x00006003
    mov dword [0xC038], 0x00007003    ; BOOT SECTOR

    ; 2. CR3
    mov eax, 0x9000		
    mov cr3, eax

    ; 3. ACTIVE Long Mode and SVM in EFER MSR
    mov ecx, 0xC0000080         ; EFER MSR
    rdmsr 
    or eax, (1 << 8) | (1 << 12); Bits 8 and 12
    wrmsr

    ; Paging bit 31 in CR0
    mov eax, cr0
    or eax, 1 << 31
    mov cr0, eax		

    jmp 0x18:entry_64bit

[bits 64]
entry_64bit:

    mov rax, cr4
    or rax, 1 << 20             ; SMEP 
    mov cr4, rax

    jmp 0x4000

align 8
gdt_start:
    dq 0x0000000000000000       ; Null Descriptor
    dq 0x00cf9a000000ffff       ; 32-bit Code Descriptor (Offset 0x08)
    dq 0x00cf92000000ffff       ; 32-bit Data Descriptor (Offset 0x10)
    dq 0x00209a0000000000       ; 64-bit Code Descriptor (Offset 0x18)
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start                 
times 510-($-$$) db 0
dw 0xAA55
; Bootloader are limited for 512 bytes in Intel or AMD CPU 
; When BIOS starting he going to 0xAA55 that his last byte 
; on the CPU and he takes your bootloader into 0X7C00 in 
; Intel and AMD hope that helped you to understand :)
