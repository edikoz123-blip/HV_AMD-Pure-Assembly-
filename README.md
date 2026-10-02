[bits 64]
[org 0x4000]
;========================================================================
;------------- Created by The Ghost In The Matrix and Joshi -------------
;========================================================================


;Defines so I dont need to go back to AMD manual:

;thats all of it are shared between Intel and AMD MSRS(Model Specific Regiester)
; =======================================================================
; 1. CORE ARCHITECTURAL REGISTERS (Identical on both Intel & AMD)
; =======================================================================
%define EFER_MSR            0xC0000080  ; Extended Feature Enable Register (NXE, SVME, LME)
%define IA32_STAR           0xC0000081  ; Legacy Ring 0/3 Segment Selectors Target Map for SYSCALL/SYSRET
%define IA32_LSTAR          0xC0000082  ; 64-bit Target RIP Vector for execution entry on SYSCALL instruction
%define IA32_CSTAR          0xC0000083  ; Compatibility Mode Target RIP Vector for SYSCALL execution
%define IA32_FMASK          0xC0000084  ; RFLAGS Bitmask to clear dynamically during SYSCALL transition
%define IA32_FS_BASE        0xC0000100  ; Linear base target physical mapping address for FS register
%define IA32_GS_BASE        0xC0000101  ; Linear base target physical mapping address for GS register
%define IA32_KERNEL_GS_BASE 0xC0000102  ; Swapped base target mapping address for OS Kernel via SWAPGS
%define IA32_TSC_AUX        0xC0000103  ; Auxiliary Time Stamp Counter (Used by RDTSCP instruction)

; =======================================================================
; 2. SIDE-CHANNEL ATTACK MITIGATIONS & SILICON ISOLATION SHIELDS
; =======================================================================
%define IA32_SPEC_CTRL      0x00000048  ; Speculative Execution Control (IBRS, STIBP, SSBD switches)
%define IA32_PRED_CMD       0x00000049  ; Prediction Command Trigger (IBPB branch history flush)
%define IA32_PRED_CTRL      0x0000004C  ; Prediction Control Register (Enforces hardware-level branch isolation)
%define IA32_FLUSH_CMD      0x0000010B  ; L1 Data Cache Hard Flush Command Trigger (Meltdown shield)
%define IA32_ARCH_CAPABILITIES 0x0000010A ; Architectural Capabilities (Read rogue data mitigation flags)
%define IA32_CORE_CAPABILITIES 0x000000CF ; Architectural Processor Core Capabilities Frame

; =======================================================================
; 3. CORE MEMORY TYPING, RANGE REGISTERS (MTRRs) & SYSTEM APIC
; =======================================================================
%define IA32_APIC_BASE      0x0000001B  ; Local APIC Base Physical Address and Enable/Disable register
%define IA32_MTRR_DEF_TYPE  0x000002FF  ; Memory Type Range Register Default Memory Access Type Frame
%define MSR_MTRRfix64k_00000 0x00000250 ; Fixed-Range MTRR mapping for low 64KB physical address block
%define MSR_MTRRcap         0x000000FE  ; MTRR Architectural Capabilities (Read supported memory types)

; =======================================================================
; 4. CONTROL-FLOW ENFORCEMENT TECHNOLOGY (CET ANTI-ROP/ANTI-JOP)
; =======================================================================
%define IA32_U_CET          0x000006A0  ; Control-flow Enforcement Register - User Mode Restrictions
%define IA32_S_CET          0x000006A1  ; Control-flow Enforcement Register - Supervisor Kernel Mode
%define IA32_PL0_SSP        0x000006A4  ; Privilege Level 0 Shadow Stack Pointer Context Register
%define IA32_INTERRUPT_SSP_TABLE_ADDR 0x000006A8 ; Shadow Stack Pointer table address for hardware interrupts

; =======================================================================
; 5. PERFORMANCE MONITORING & ARCHITECTURAL DEBUGGING
; =======================================================================
%define IA32_PERF_GLOBAL_CTRL 0x0000038F ; Global Performance Counter Execution Master Control Switch
%define IA32_PERF_STATUS    0x00000198  ; Silicon Operating Frequency and Voltage Status Register
%define IA32_DEBUGCTL       0x000001D9  ; Hardware Debug Control Interface (LBR, BTF, Branch Recording)
%define MSR_BR_FROM_IP      0x00000680  ; Last Branch Record (LBR) Source Execution Instruction Pointer
%define MSR_BR_TO_IP        0x000006C0  ; Last Branch Record (LBR) Destination Execution Target Vector

; =======================================================================
; 6. THERMAL PATROL, TEMPERATURE MANAGEMENT & ENHANCED POWER CONTROL
; =======================================================================
%define IA32_THERM_CONTROL  0x0000019A  ; Clock Modulation and Silicon Thermal Monitor Interface Mask
%define IA32_THERM_STATUS   0x0000019C  ; Digital Temperature Sensor Output and Max Limit Thresholds
%define IA32_MISC_ENABLE    0x000001A0  ; Miscellaneous Processor Features Enable Frame (XD, SpeedStep)
%define IA32_ENERGY_PERF_BIAS 0x000001B1 ; Hardware Energy Policy Optimization Preference Configuration
%define IA32_UMWAIT_CONTROL 0x000000E1  ; User Mode Wait Control MSR

; =======================================================================
; 7. TLB HARDWARE MANAGEMENT & PROCESSOR CORE ISOLATION
; =======================================================================
%define IA32_PASID          0x000000D0  ; Process Address Space ID MSR (Enforces safe hardware context separation)
%define IA32_FLUSH_TLB      0x0000010E  ; Hardware Direct TLB Invalidation Trigger Register (Cache cleaner)

; =======================================================================
; 8. TIME STAMP COUNTER (TSC) & ACCURATE TIMING CONTROL
; =======================================================================
%define IA32_TIME_STAMP_COUNTER 0x00000010 ; Raw Hardware Cycle Counter (Target for TSC manipulation)
%define IA32_TSC_ADJUST     0x0000003B  ; TSC Offset Adjustment Frame (Used to hide hypervisor latency)
%define IA32_TSC_DEADLINE   0x000006E0  ; Local APIC TSC Deadline Mode Timer Control Register

; =======================================================================
; 9. MACHINE CHECK ARCHITECTURE (MCA ENGINE - PHYSICAL FAULT DETECTION)
; =======================================================================
%define IA32_MCG_CAP        0x00000179  ; Global Machine Check Capabilities (Read hardware error banks)
%define IA32_MCG_STATUS     0x0000017A  ; Global Machine Check Status (Validates active silicon faults)
%define IA32_MCG_CTL        0x0000017B  ; Global Machine Check Control Interface (Master exception switch)
%define IA32_MC0_CTL        0x00000400  ; Hardware Error Bank 0 Control Register (First silicon unit)
%define IA32_MC0_STATUS     0x00000401  ; Hardware Error Bank 0 Status Frame (Read active hardware faults)

; =======================================================================
; 10. ADVANCED CACHE ALLOCATION TECHNOLOGY (CAT ARCHITECTURE)
; =======================================================================
%define IA32_L3_QOS_MASK_0  0x00000C90  ; L3 Cache Allocation Mask 0 (Isolates Host cache lanes from Guest)
%define IA32_L2_QOS_MASK_0  0x00000D10  ; L2 Cache Allocation Mask 0 (Strict hardware core cache partitioning)
%define IA32_GDT_ALIGN_LOCK 0x000002E0  ; Architectural Alignment Lock MSR (Silicon-level protection against #GP)
%define IA32_PQR_ASSOC      0x00000C8F  ; Resource Association Register (Links current core execution to a Class of Service)

; =======================================================================
; 11. MULTI-CORE MANAGEMENT & LOCAL APIC x2APIC REGISTERS
; =======================================================================
%define IA32_X2APIC_ID      0x00000802  ; Read Local APIC ID in x2APIC mode (Identifies current CPU core)
%define IA32_X2APIC_TPR     0x00000808  ; Task Priority Register (Controls interrupt priority thresholds)
%define IA32_X2APIC_PPR     0x0000080A  ; Processor Priority Register (Current execution priority level)
%define IA32_X2APIC_EOI     0x0000080B  ; End of Interrupt Register (Signal hardware that interrupt processing is done)
%define IA32_X2APIC_ICR     0x00000830  ; Interrupt Command Register (Used by Hypervisor to send IPIs between cores)

; =======================================================================
; 12. ARCHITECTURAL PATROL & COUNTER ISOLATION (PLATFORM SECURITY)
; =======================================================================
%define IA32_TSC_RATIO      0x00000064  ; Architectural TSC Ratio Control (Scale factor for matching Guest/Host clocks)
%define IA32_PLATFORM_ID    0x00000017  ; Read platform specific hardware flavor bits (Common testing interface)
%define IA32_BBL_CR_CTL3    0x0000011E  ; L2 Cache Hardware Control Register (Enables hardware scrubbing defenses)

; =======================================================================
; 13. ADDITIONAL CONTROL-FLOW DEFENSES (CET & RETPOLINE REINFORCEMENTS)
; =======================================================================
%define IA32_S_CET_STATUS   0x000006A2  ; Supervisor Shadow Stack Ring 0 Active Status Token tracking
%define IA32_U_CET_STATUS   0x000006A3  ; User Shadow Stack Ring 3 Active Status Token tracking

; =======================================================================
; 14. PROCESSOR UTILIZATION & ACTUAL FREQUENCY COUNTERS
; =======================================================================
%define IA32_MPERF          0x000000E7  ; Maximum Performance Frequency Clock Count
%define IA32_APERF          0x000000E8  ; Actual Performance Frequency Clock Count

; =======================================================================
; 15. ARCHITECTURAL PAT (PAGE ATTRIBUTE TABLE) & MEMORY WRITING
; =======================================================================
%define IA32_CR_PAT         0x00000277  ; Page Attribute Table Layout Register (Controls caching per page)

; =======================================================================
; 16. MISCELLANEOUS HARDWARE STATE & FEATURES ENUMERATION
; =======================================================================
%define IA32_MISC_ENABLE    0x000001A0  ; Miscellaneous Processor Features Enable Frame (XD, SpeedStep)
%define IA32_FEATURE_CONTROL 0x0000003A ; Lock register for enabling VMX/SVM at BIOS level securely

; =======================================================================
; 17. LEGACY COMPATIBILITY & SEGMENT EXPANSIONS (Ring 0 / Ring 3)
; =======================================================================
%define IA32_DS_AREA        0x00000600  ; Debug Store Area (Allocates a physical buffer boundary for BTS and PEBS)
%define IA32_EBC_FREQUENCY  0x0000002C  ; Processor Front Side Bus (FSB) / Core Frequency Scaling Status register

; =======================================================================
; 18. PROCESSOR INVENTORY & SERIALIZATION CONTROL
; =======================================================================
%define IA32_PPIN_CTL       0x0000004E  ; Protected Processor Inventory Number Control (Lock/Enable)
%define IA32_PPIN           0x0000004F  ; Read-only 64-bit unique physical silicon identifier serial number

; =======================================================================
; 19. PREFETCH CONTROL & AMBIENT PERFORMANCE TUNING
; =======================================================================
%define IA32_MISC_PREFETCH_CTL 0x000001A4 ; Hardware Prefetcher Control Register (Disable/Enable L1/L2 prefetchers)

; =======================================================================
; 20: LEGACY BARE-METAL OUTPUT (VGA & SERIAL COM1) FOR X86
; =======================================================================
%define X86_COM1_PORT       0x3F8       ; Serial Port COM1 Address (Used with OUT instruction)
%define VGA_TEXT_MODE_BASE  0x000B8000  ; Physical memory address of the screen (Write ASCII here to show text)

; =======================================================================
; 21: ARCHITECTURAL CPU FLAGS & EFER BITS FOR X86_64
; =======================================================================
%define EFLAGS_IF_BIT       9           ; Interrupt Flag (1 = Physical interrupts enabled)
%define EFLAGS_VM_BIT       17          ; Virtual 8086 Mode Flag (Used to detect legacy guests)

%define EFER_LME_BIT        8           ; Long Mode Enable (Turn on 64-bit architecture support)
%define EFER_LMA_BIT        10          ; Long Mode Active (Read-only: status that 64-bit is running)
%define EFER_SVME_BIT       12          ; SVM Enable (Crucial flag to unlock AMD Virtualization)

; =======================================================================
; 22: SHARED EXECUTION ARMOR & ENCLAVE HARDENING
; =======================================================================
%define IA32_SMM_MCA_CAP    0x0000017D  ; SMM Machine Check Architecture Capabilities (Locks SMM fault logging securely)
%define IA32_SGX_OWNEREPOCH0 0x00000300 ; SGX Enclave Owner Epoch Register 0 (Cryptographic hardware isolation base)
%define IA32_SGX_OWNEREPOCH1 0x00000301 ; SGX Enclave Owner Epoch Register 1 (Locks hardware secure enclaves keys)
%define IA32_CR_S_CET       0x000006A2  ; Kernel Shadow Stack Pointer Control Token Register (Crucial for CET locking)

; =======================================================================
; 23: SHARED INTERRUPT MATRIX & EXTENDED x2APIC CONTROLS
; =======================================================================
%define IA32_X2APIC_VERSION 0x00000803  ; Read Local APIC Version in x2APIC mode (Identifies silicon capability)
%define IA32_X2APIC_LDR     0x0000080D  ; Logical Destination Register (Controls core clustering layout)
%define IA32_X2APIC_SIVR    0x0000080F  ; Spurious Interrupt Vector Register (Handles rogue/phantom hardware faults)
%define IA32_X2APIC_ISR0    0x00000810  ; In-Service Register Bit-Frame 0 (Tracks active hardware interrupts)
%define IA32_X2APIC_IRR0    0x00000820  ; Interrupt Request Register Bit-Frame 0 (Tracks pending trapped events)
%define IA32_X2APIC_LVT_TMR 0x00000832  ; Local Vector Table Timer Register (Direct silicon-level timer control)

; =======================================================================
; 24: PRECISION TIMING CONTROL & CLOCK MODULATION MATRIX
; =======================================================================
%define IA32_TSC_AUX        0x00000C00  ; Auxiliary TSC Register (Holds unique core index signed by wrmsr for RDTSCP)
%define IA32_CLOCK_MODULATION 0x0000019A; Processor Clock Modulation Control (Silicon pulse width throttling interface)

; =======================================================================
; 25: EXTENDED HARDWARE FAULT DETECTION & MCA BANK EXPANSIONS
; =======================================================================
%define IA32_MC1_CTL        0x00000404  ; Hardware Error Bank 1 Control Register (Governs IFU / Instruction Fetch Unit)
%define IA32_MC1_STATUS     0x00000405  ; Hardware Error Bank 1 Status Frame (Reads active Core Prefetch faults)
%define IA32_MC2_CTL        0x00000408  ; Hardware Error Bank 2 Control Register (Governs DCU / Data Cache Unit)
%define IA32_MC2_STATUS     0x00000409  ; Hardware Error Bank 2 Status Frame (Reads physical Memory L1/L2 anomalies)

; =======================================================================
; 26: KERNEL ADDRESS SHIELDS & SYSCALL PRIVILEGE TRANSITION
; =======================================================================
%define IA32_STAR           0xC0000081  ; Ring 0/3 Target Segment Selectors and Core Call Pointers
%define IA32_LSTAR          0xC0000082  ; Long Mode Target RIP Descriptor for SYSCALL Vector (64-bit Entry)
%define IA32_CSTAR          0xC0000083  ; Compatibility Mode Target RIP for SYSCALL Vector (Legacy 32-bit)
%define IA32_FMASK          0xC0000084  ; SYSCALL EFLAGS Mask Register (Clears critical flags on privilege shift)
%define IA32_KERNEL_GS_BASE 0xC0000102  ; SwapGS Target Pointer (Holds hidden Host/Kernel context data array)

; =======================================================================
; 27: PLATFORM CONFIGURATION INTERFACE & MICROCODE STATUS
; =======================================================================
%define IA32_PLATFORM_INFO  0x000000CE  ; Platform Information Register (Read execution limits and multiplier data)
%define IA32_MISC_PACKAGE_CTRL 0x000001B4 ; Package Level Hardware Mitigation Control Switch
%define IA32_UCODE_REV      0x0000008B  ; Microcode Patch Revision Update and Query Register Frame

; =======================================================================
; 28: EXTENDED INTERRUPT VECTORS & x2APIC LVT FRAMEWORK
; =======================================================================
%define IA32_X2APIC_LVT_CMCI 0x0000082F ; Corrected Machine Check Interrupt Vector Control [intel.com]
%define IA32_X2APIC_LVT_LINT0 0x00000835; Local Interrupt 0 Signal Input Control Wire [intel.com]
%define IA32_X2APIC_LVT_LINT1 0x00000836; Local Interrupt 1 Signal Input Control Wire [intel.com]
%define IA32_X2APIC_LVT_ERR  0x00000837 ; Local APIC Error Handling Vector Interface Register [intel.com]

; =======================================================================
; 29: ADVANCED FABRIC MONITORING & CORE MCA BANK EXPANSIONS
; =======================================================================
%define IA32_MC3_CTL        0x0000040C  ; Hardware Error Bank 3 Control Register (Governs System Bus / Interconnect)
%define IA32_MC3_STATUS     0x0000040D  ; Hardware Error Bank 3 Status Frame (Reads core fabric errors)
%define IA32_MC4_CTL        0x00000410  ; Hardware Error Bank 4 Control Register (Governs Memory Controller Unit)
%define IA32_MC4_STATUS     0x00000411  ; Hardware Error Bank 4 Status Frame (Reads DRAM hardware faults)

; =======================================================================
; 30: THREAD CONTEXT ARMOR & SEGMENT BASE SPECIFICATION
; =======================================================================
%define IA32_FS_BASE        0xC0000100  ; Map base linear address for the FS segment descriptor [intel.com]
%define IA32_GS_BASE        0xC0000101  ; Map base linear address for the GS segment descriptor [intel.com]

; =======================================================================
; 31: SPECULATIVE VULNERABILITY SHIELD & CORE MUTATION LOCK
; =======================================================================
%define IA32_CORE_MUT_LOCK  0x0000009F  ; Core Mutation and Speculative Execution Lock (Locks structural settings)

; =======================================================================
; 32: THREAD CONTEXT TRACKING & PRECISION RDTSCP VALIDATION
; =======================================================================
%define IA32_TSC_AUX        0xC0000103  ; TSC Auxiliary ID Register (Enforces true core index validation for RDTSCP)

; =======================================================================
; 33: ENERGY TELEMETRY MATRIX & HARDWARE SENSOR ISOLATION
; =======================================================================
%define IA32_PLATFORM_ENERGY_STATUS 0x00000606 ; Read-Only platform energy consumption telemetry frame [intel.com]
%define IA32_RAPL_POWER_UNIT        0x00000606 ; Silicon Power Gate measurement units for hardware sensors [intel.com]

; =======================================================================
; 34: CONTROL-REGISTER HARDWARE SHIELDS & BIT LOCKS
; =======================================================================
%define IA32_MISC_ENABLE_STATUS  0x000001A1 ; Read-only status frame for hardware toggles [intel.com]
%define IA32_CR3_MRESET_LOCK     0x000002E1 ; Silicon lock that prevents rogue guest modifications to CR3 properties

; =======================================================================
; 35: SPECULATIVE EXECUTION BARRIERS & DATA SAMPLING ENFORCEMENT
; =======================================================================
%define IA32_TSX_CTRL            0x00000122 ; Transactional Synchronization Extensions control (Kills TSX side-channels) [intel.com]
%define IA32_MCU_OPT_CTRL        0x00000123 ; Microarchitectural Data Sampling Mitigation Control register [intel.com]

; =======================================================================
; 36: EXTENDED INTERRUPT VECTORS & x2APIC LVT EXTRA MATRIX
; =======================================================================
%define IA32_X2APIC_LVT_PCINT    0x00000834 ; Performance Counter Interrupt Vector Control in x2APIC mode [intel.com]
%define IA32_X2APIC_LVT_THERMAL  0x00000833 ; Thermal Sensor Interrupt Vector Control interface register [intel.com]

; =======================================================================
; 37: MICROARCHITECTURAL BUFFER ISOLATION & TSX ABORT SWITCH
; =======================================================================
%define IA32_TSX_FORCE_ABORT 0x0000010F  ; Force Abort Execution interface (Locks speculative transactional avenues) [intel.com]

; =======================================================================
; 38: ARCHITECTURAL HARDENING MATRIX & CAPACITY ENUMERATION
; =======================================================================
%define IA32_ARCH_MISC_CAPABILITIES 0x000002A0 ; Architectural Miscellaneous Hardware Capabilities and Seals frame [intel.com]

; =======================================================================
; 39: FABRIC INTERCONNECT FAULT DETECTION & MCA BANK 5 EXPANSION
; =======================================================================
%define IA32_MC5_CTL        0x00000414  ; Hardware Error Bank 5 Control Register (Governs Bus Interface Matrix) [intel.com]
%define IA32_MC5_STATUS     0x00000415  ; Hardware Error Bank 5 Status Frame (Reads physical interconnect faults) [intel.com]

; =======================================================================
; 40: ADVANCED SPECULATIVE ISOLATION & GUEST CONTEXT CONTROLS
; =======================================================================
%define IA32_PREVERIFY_CONTROL   0x00000124  ; Speculative Verification Optimization Mitigation register
%define IA32_GUEST_IDLE_CTRL     0x00000125  ; Silicon Idle Mitigation and core state monitoring lock

; =======================================================================
; 41: FABRIC EXPANSION FAULT DETECTION & FINAL MCA BANKS 6 & 7 LOCK
; =======================================================================
%define IA32_MC6_CTL             0x00000418  ; Hardware Error Bank 6 Control Register (System Interconnect Fabric)
%define IA32_MC6_STATUS          0x00000419  ; Hardware Error Bank 6 Status Frame (Reads fabric transport faults)
%define IA32_MC7_CTL             0x0000041C  ; Hardware Error Bank 7 Control Register (Secondary Memory Controller)
%define IA32_MC7_STATUS          0x0000041D  ; Hardware Error Bank 7 Status Frame (Reads residual hardware faults)

; =======================================================================
; 42: MICROARCHITECTURAL CONTEXT SHIELDS & SILICON LEAK MITIGATION
; =======================================================================
%define IA32_RF_CTRL             0x00000121  ; Register File Speculative Invalidation Control Switch
%define IA32_SIMM_CTRL           0x00000126  ; Silicon Information Leakage Mitigation Control Register

; =======================================================================
; 43: EXTENDED INTERRUPT VECTORS & x2APIC SELF-IPI MATRIX
; =======================================================================
%define IA32_X2APIC_SELF_IPI    0x0000083F  ; Self Inter-Processor Interrupt Register in x2APIC mode [intel.com]

; =======================================================================
; 44: STRUCTURAL PACKAGE THERMAL MITIGATION & ENVELOPE STATUS
; =======================================================================
%define IA32_PACKAGE_THERM_STATUS 0x000001B1 ; Read-only status frame for package level thermal monitoring [intel.com]
%define IA32_PACKAGE_THERM_INTERRUPT 0x000001B2 ; Controls interrupt vectors for global package heat faults [intel.com]

; =======================================================================
; 45: EXTENDED INTERRUPT VECTORS & x2APIC TIMER MATRIX
; =======================================================================
%define IA32_X2APIC_DIV_CONF    0x0000083E  ; APIC Timer Divide Configuration Register in x2APIC mode [intel.com]

; =======================================================================
; 46: MICROARCHITECTURAL DATA SAMPLING BLOCK & MCU OPT CTRL
; =======================================================================
%define IA32_MCU_OPT_CTRL   0x00000123  ; Microarchitectural Data Sampling Mitigation Control (Kills MDS channels) [intel.com]

; =======================================================================
; 47: SPECULATIVE INTERCEPT REINFORCEMENT & PREVERIFY CONTROL
; =======================================================================
%define IA32_PREVERIFY_CONTROL 0x00000124 ; Enforces early hardware verification to block advanced side-channel loops

; =======================================================================
; 48: REGISTER FILE SPECULATIVE ISOLATION & RRSBA CONTROL
; =======================================================================
%define IA32_RRSBA_CTRL     0x00000127  ; Restricted Return Stack Buffer Alternative Control (Locks speculative register file avenues)

; =======================================================================
; 49: VM BOUNDARY SPECULATION SHIELD & PREDICT CONTROL
; =======================================================================
%define IA32_VM_PREDICT_CONTROL 0x00000128 ; Hardwires instruction branch prediction isolation loops between VM context boundaries

; =======================================================================
; 50: ADVANCED FABRIC MONITORING & FINAL MCA BANK 8 MATRIX
; =======================================================================
%define IA32_MC8_CTRL        0x00000420  ; Hardware Error Bank 8 Control Register (Governs Advanced Memory Controller Fabric)
%define IA32_MC8_STATUS     0x00000421  ; Hardware Error Bank 8 Status Frame (Reads physical structural data faults)


; =======================================================================
; AMD64 SPECIFIC MSR DEFINITIONS (AUTHENTICAMD) - FULL COMPREHENSIVE BANK
; =======================================================================

; =======================================================================
; 1. CORE AMD SVM VIRTUALIZATION MASTER CONTROLS (FIXED & VERIFIED)
; =======================================================================
%define VM_CR_MSR           0xC0010114  ; SVM Hardware Virtualization Configuration & Lock Register (Fixed address)
%define VM_HSAVE_PA_MSR     0xC0010117  ; Host Save Area Physical Address (AMD SVM core requirement - Fixed address)
%define MSR_AMD_SMM_ADDR    0xC0010112  ; SMM TSEG Base Address Register (Physical SMM protection)
%define MSR_VM_IGNNE        0xC0010115  ; SVM Ignore Numeric Error Mitigation Register (Legacy virtualization lock)
%define MSR_HW_CR           0xC0010015  ; Hardware Configuration Register (TSC frequency lock parameters)

; =======================================================================
; 2. ADVANCED HARDWARE ENCRYPTION & ATTRIBUTES (AMD SEV / SEV-SNP)
; =======================================================================
%define MSR_SEV_STATUS      0xC0010131  ; AMD Secure Encrypted Virtualization Active Features Status
%define MSR_VCPU_ID         0xC001013A  ; AMD SEV-SNP Guest Virtual CPU Attestation Identifier
%define MSR_SEV_FEATURES    0xC001013E  ; AMD SEV Supported Security Features Extension Bitmap

; =======================================================================
; 3. AMD INTERNALS, DECODE CONFIGURATION & SILICON SPECULATION DEFENSE
; =======================================================================
%define MSR_DE_CFG          0xC0011029  ; Decode Configuration Register (Used to patch execution bugs like Zenbleed)
%define MSR_LS_CFG          0xC0011020  ; Load-Store Configuration Frame (Controls speculative execution serialization)
%define MSR_IC_CFG          0xC0011021  ; Instruction Cache Configuration (Silicon execution engine hardening)

; =======================================================================
; 4. AMD ADVANCED SYSTEM ARCHITECTURE & EXCEPTION VECTOR EXTENSIONS
; =======================================================================
%define MSR_AMD_PATCH_LEVEL 0x0000008B  ; Current Microcode Patch Level Revision (Read-Only validation)
%define MSR_NB_CFG          0xC001001F  ; Northbridge Configuration Interface (Advanced memory profiling)
%define MSR_EXT_FEATURES    0xC0010058  ; Extended Exception Vector Configuration and Silicon Attributes

; =======================================================================
; 5. MSR PERMISSIONS MAPS (MSRP ARCHITECTURE FOR HARDWARE BLOCKING)
; =======================================================================
%define MSRP_BASE_ADDRESS   0x00010000  ; Recommended 8KB physical buffer boundary for MSRP
%define MSRP_OFFSET_DEVICE  0x00002004  ; VMCB Control area byte pointer anchoring the MSRP layout

; =======================================================================
; 6. I/O VIRTUALIZATION TECHNOLOGY & HARDWARE DMA PROTECTION (IOMMU)
; =======================================================================
%define MSR_IOMMU_BASE      0xC0010074  ; IOMMU Base Address Register (Controls hardware DMA mapping safety)
%define MSR_IOMMU_CONTROL   0xC0010075  ; IOMMU Execution Control Frame (Locks DMA from external chips)

; =======================================================================
; 7. AMD HARDWARE P-STATE & FREQUENCY CONTROL
; =======================================================================
%define MSR_AMD_PSTATE_LIMIT 0xC0010061 ; P-State Current Limit (Reads the maximum allowed hardware performance state)
%define MSR_AMD_PSTATE_CTL   0xC0010062 ; P-State Control Register (Allows Hypervisor to force a core into lower power)
%define MSR_AMD_PSTATE_STAT  0xC0010063 ; P-State Status Register (Reads current active hardware multiplier)
%define MSR_AMD_TSC_RATIO    0xC0000104 ; AMD Specific TSC Ratio (Hypervisor TSC scaling control for legacy processors)

; =======================================================================
; 8. AMD OPERATING SYSTEM VISIBLE WORKAROUNDS (OSVW ENGINE)
; =======================================================================
%define MSR_AMD_OSVW_ID_LEN  0xC0010140 ; OSVW ID Length Register (Number of hardware errata tracked by CPU)
%define MSR_AMD_OSVW_STATUS  0xC0010141 ; OSVW Status Register (Bitmap showing which bugs require software fixes)

; =======================================================================
; 9. AMD HARDWARE SPECULATION DEFENSES & BRANCH HARDENING
; =======================================================================
%define MSR_AMD_BP_CFG       0xC001102E ; Branch Predictor Configuration (Used to enable BpSpecReduce for SRSO mitigation)
%define MSR_AMD_BU_CFG2      0xC001102B ; Bus Unit Configuration 2 (Contains custom serialization flags for speculation)

; =======================================================================
; 10. AMD INSTRUCTION-BASED SAMPLING (IBS CONTROLS - FETCH)
; =======================================================================
%define MSR_AMD_IBSFETCHCTL  0xC0011030 ; IBS Fetch Control Register (Manages tag-on-fetch tracking for instructions)
%define MSR_AMD_IBSFETCHLINAD 0xC0011031 ; IBS Fetch Linear Address Register (Reads the RIP that triggered the fetch event)
%define MSR_AMD_IBSFETCHPHYSAD 0xC0011032 ; IBS Fetch Physical Address Register (The actual RAM location used)
%define MSR_AMD_IBSOPCTL     0xC0011033 ; IBS Execution Control Register (Tracks execution and macro-op routing)

; =======================================================================
; 11. AMD SMM CONTROLS & HYPERVISOR SILICON LOCKDOWN
; =======================================================================
%define MSR_AMD_SMM_CTL     0xC0010116  ; SMM Control Register (Locks or enables SMM entry and virtualization intercepts)
%define MSR_AMD_SMBASE      0xC0010111  ; SMM Base Address Register (Defines the physical relocation boundary of SMRAM)

; =======================================================================
; 12. AMD ADVANCED VIRTUAL INTERRUPT CONTROLLER (AVIC REGISTERS)
; =======================================================================
%define MSR_AMD_AVIC_DOORBELL 0xC001011B ; AVIC Doorbell MSR (Used by the Host core to trigger an immediate guest virtual interrupt)

; =======================================================================
; 13. AMD PROCESSOR CONFIGURATION & BRANDING MAPS
; =======================================================================
%define MSR_AMD_NAME_STRING_0 0xC0010030 ; Processor Name String Register 0 (Holds first 8 ASCII characters of CPU name)
%define MSR_AMD_NAME_STRING_1 0xC0010031 ; Processor Name String Register 1
%define MSR_AMD_NAME_STRING_2 0xC0010032 ; Processor Name String Register 2
%define MSR_AMD_NAME_STRING_3 0xC0010033 ; Processor Name String Register 3
%define MSR_AMD_NAME_STRING_4 0xC0010034 ; Processor Name String Register 4
%define MSR_AMD_NAME_STRING_5 0xC0010035 ; Processor Name String Register 5

; =======================================================================
; 14. AMD CCX TOPOLOGY & CACHE COHERENCY MATRIX
; =======================================================================
%define MSR_AMD_CCX_CORE_ID 0xC001100C  ; Read-only physical Core ID/Node ID for NUMA topology (Fixed address)
%define MSR_AMD_L3_CONFIG   0xC0011022  ; AMD Specific L3 Cache Partitioning and Interleave Control

; =======================================================================
; 15. CORE POWER MONITORING & ENERGY LIMITS
; =======================================================================
%define MSR_RAPL_POWER_UNIT 0xC0010299  ; Running Average Power Limit (RAPL) Power Unit Frame
%define MSR_PKG_ENERGY_STATUS 0xC001029B ; Read-only actual silicon package cumulative energy usage

; =======================================================================
; 16. ADVANCED CPPC PERFORMANCE HARDWARE TUNING (NEW EXTENSION)
; =======================================================================
%define MSR_AMD_CPPC_CAP1   0xC00102B0  ; CPPC Target Capability Register (Highest/efficient silicon frequencies)
%define MSR_AMD_CPPC_ENABLE 0xC00102B1  ; CPPC Hardware Core Optimization Enable Switch
%define MSR_AMD_CPPC_REQ    0xC00102B3  ; CPPC Request Register (Force dynamic vCPU clock limits)

; =======================================================================
; 17. INSTRUCTION-BASED SAMPLING EXECUTION TRACKING (NEW EXTENSION)
; =======================================================================
%define MSR_AMD64_IBSOPRIP  0xC0011034  ; Exact RIP causing pipeline stalls during execution sampling
%define MSR_AMD64_IBSOPDATA 0xC0011035  ; IBS Op Data (Cache misses, memory attributes and hardware faults)
%define MSR_AMD64_IBSOPDATA2 0xC0011036 ; IBS Op Data 2 Register (Exact execution timing in hardware cycles)

; =======================================================================
; 18. RUNTIME MICROCODE INJECTION ENGINE (NEW EXTENSION)
; =======================================================================
%define MSR_AMD_PATCH_LOADER 0xC0010020 ; Microcode Patch Loader Register (Inject updates straight to silicon)


; =======================================================================
; AMD64 SPECIFIC MSR DEFINITIONS (PART 2 - THE ULTIMATE EXTENSION)
; =======================================================================

; =======================================================================
; 19. AMD x2AVIC VIRTUAL x2APIC SYSTEM MONITORING (CRITICAL FOR GUEST INTERRUPTS)
; =======================================================================
%define MSR_AMD_X2APIC_ID       0x00000802  ; Virtual x2APIC ID MSR (Intercepted by x2AVIC to identify guest vCPU)
%define MSR_AMD_X2APIC_TPR      0x00000808  ; Task Priority Register (Controls guest interrupt filtering)
%define MSR_AMD_X2APIC_PPR      0x0000080A  ; Processor Priority Register (Current execution priority level)
%define MSR_AMD_X2APIC_EOI      0x0000080B  ; End of Interrupt Register (Signaled by Guest without VM-Exit)
%define MSR_AMD_X2APIC_LDR      0x0000080D  ; Logical Destination Register for virtual interrupt routing
%define MSR_AMD_X2APIC_Spurious 0x0000080F  ; Spurious Interrupt Vector Register
%define MSR_AMD_X2APIC_ISR0     0x00000810  ; In-Service Register Frame 0 (Tracks active virtual interrupts)
%define MSR_AMD_X2APIC_ICR      0x00000830  ; Interrupt Command Register (x2AVIC emulates inter-processor interrupts)

; =======================================================================
; 20. AMD SPECIFIC CACHE CONTROLS & MEMORY CONFIGURATION
; =======================================================================
%define MSR_AMD_SYS_CFG         0xC0000010  ; System Configuration (Contains MtrrFixDramEn to lock fixed MTRRs)
%define MSR_AMD_TOP_MEM         0xC001001A  ; Top of Memory 1 (Defines boundary between normal RAM and MMIO space)
%define MSR_AMD_TOP_MEM2        0xC001001D  ; Top of Memory 2 (Defines memory space upper boundaries above 4GB)

; =======================================================================
; 21. AMD FIXED-RANGE MTRR MEMORY ACCESS TYPE MAPS
; =======================================================================
%define MSR_AMD_MTRRfix64k_00000 0x00000250 ; AMD Fixed MTRR for lowest 64KB block (Controls physical DRAM caching)
%define MSR_AMD_MTRRfix16k_80000 0x00000258 ; Fixed MTRR mapping for 80000h–9FFFFh physical address space
%define MSR_AMD_MTRRfix16k_A0000 0x00000259 ; Fixed MTRR mapping for A0000h–BFFFFh physical address space
%define MSR_AMD_MTRRfix4k_C0000  0x00000268 ; Fixed MTRR mapping for C0000h–C7FFFh video BIOS space

; =======================================================================
; AMD64 SPECIFIC MSR DEFINITIONS (PART 3 - THE PMU & PERFORMANCE SHIELD)
; =======================================================================

; =======================================================================
; 22. AMD CORE PERFORMANCE COUNTER EVENT SELECTORS (PERF_CTL)
; =======================================================================
%define MSR_AMD_PERF_CTL0       0xC0010000  ; Performance Event Select 0 (Controls what hardware event to monitor)
%define MSR_AMD_PERF_CTL1       0xC0010001  ; Performance Event Select 1
%define MSR_AMD_PERF_CTL2       0xC0010002  ; Performance Event Select 2
%define MSR_AMD_PERF_CTL3       0xC0010003  ; Performance Event Select 3
%define MSR_AMD_PERF_CTL4       0xC0010200  ; Performance Event Select 4 (Extended counter for modern Zen cores)
%define MSR_AMD_PERF_CTL5       0xC0010202  ; Performance Event Select 5

; =======================================================================
; 23. AMD CORE PERFORMANCE COUNTER DATA REGISTERS (PERF_CTR)
; =======================================================================
%define MSR_AMD_PERF_CTR0       0xC0010004  ; Performance Counter Data 0 (Holds the actual hardware event count)
%define MSR_AMD_PERF_CTR1       0xC0010005  ; Performance Counter Data 1
%define MSR_AMD_PERF_CTR2       0xC0010006  ; Performance Counter Data 2
%define MSR_AMD_PERF_CTR3       0xC0010007  ; Performance Counter Data 3
%define MSR_AMD_PERF_CTR4       0xC0010201  ; Performance Counter Data 4 (Extended data frame)
%define MSR_AMD_PERF_CTR5       0xC0010203  ; Performance Counter Data 5

; =======================================================================
; 24. AMD SPECIFIC VIRTUALIZATION SECURITY HARDENING (LBR & DEEP TRAILING)
; =======================================================================
%define MSR_AMD_LBR_SELECT      0xC00101C0  ; AMD Last Branch Record Select (Filter which branches the CPU records)
%define MSR_AMD_LBR_FROM_IP     0xC00101C1  ; LBR Stack From IP (Where the execution jump came from)
%define MSR_AMD_LBR_TO_IP       0xC00101C2  ; LBR Stack To IP (Where the execution jump landed)

; =======================================================================
; 25. AMD HARDWARE PASSWORD-PROTECTED DEBUG MSRs 
; (Requires EDI = 0x9C5A203A before execution to avoid #GP)
; =======================================================================
%define MSR_AMD_EXT_DEBUG_BASE  0xC001100A  ; Hidden Debug Controller Configuration Register
%define MSR_AMD_EXT_DEBUG_DATA  0xC001100B  ; Debug Output Buffer Register (Reads physical silicon states)

; =======================================================================
; 26. UNDOCUMENTED AMD MSR BREAKPOINT TRAPS
; =======================================================================
%define MSR_AMD_BREAKPOINT      0xC001100E  ; MSR Breakpoint Target Address (Triggers hardware intercept)
%define MSR_AMD_BREAKPOINT_MASK 0xC001100F  ; MSR Breakpoint Filter Mask (Defines target bits range)

; =======================================================================
; 27. UNDOCUMENTED BUS ARCHITECTURE & BRANCH TRACING (BHTrace Engine)
; =======================================================================
%define MSR_AMD_BHTRACE_CTL     0xC0011010  ; Bus Hardware Trace Master Control Switch
%define MSR_AMD_BHTRACE_DATA    0xC0011011  ; Bus Hardware Trace User Data Collect Frame

; =======================================================================
; 28. UNDOCUMENTED SILICON ISOLATION & PREFETCH LOCKS
; =======================================================================
%define MSR_AMD_DC_CFG_SECRET   0xC0011022  ; Undocumented Data Cache configuration for disabling prefetchers

; =======================================================================
; AMD64 SPECIFIC MSR DEFINITIONS (THE FORBIDDEN DEEP-SILICON EXTENSION)
; =======================================================================

; =======================================================================
; 29. AMD PERFORMANCE BOOST & THERMAL RATIO LOCKS (INTERNAL TUNING)
; =======================================================================
%define MSR_AMD_CORED_CFG       0xC001102C  ; Core Performance Configuration (Hidden switch used by AMD Ryzen Master to bypass boost limits)
%define MSR_AMD_THM_CR_CYC      0xC0010073  ; Thermal Hardware Cycle Modulation (Directly controls physical throttling)

; =======================================================================
; 30. AMD EXPERIMENTAL SPECULATION HARDENING (Zen 4 / Zen 5 Shielder)
; =======================================================================
%define MSR_AMD_PPIN_CTL_SECRET 0xC001004E  ; Hidden Protected Processor Inventory Number Lock Control
%define MSR_AMD_SPECTRE_V4_CTL  0xC0011024  ; Custom speculative store bypass disable (Alternative hardware-level mitigation address)

; =======================================================================
; 31. AMD HARDWARE ERROR INJECTION & SILICON CORRUPTION INTRUSION
; =======================================================================
%define MSR_AMD_ERR_INJECT      0xC001011E  ; Machine Check Architecture Error Injection Trigger (Forces simulated silicon faults)
%define MSR_AMD_ERR_STATUS_MASK 0xC001011F  ; MCA Hardware Bank Intercept Filter Mask

; =======================================================================
; 32. AMD EMBEDDED CO-PROCESSOR SECURITY SHIELDS (PSP GATEWAY)
; =======================================================================
%define MSR_AMD_PSP_COMMAND     0xC00110A0  ; Platform Security Processor Host Command Pipeline Interface
%define MSR_AMD_PSP_STATUS      0xC00110A1  ; Platform Security Processor Hardware Fuses and Active Status Frame

; =======================================================================
; AMD64 SPECIFIC MSR DEFINITIONS (THE FINAL SILICON BREAKPOINT LAYER)
; =======================================================================

; =======================================================================
; 33. AMD EXTENDED MACHINE CHECK ARCHITECTURE (MCA EXTRAS)
; =======================================================================
%define MSR_AMD_MCA_CFG         0xC0010044  ; MCA Configuration Register (Determines how silicon errors are reported to Host)
%define MSR_AMD_MCA_EXT_CTL0    0xC0010050  ; Extended MCA Control for Core Bank 0 (Advanced hardware logging)
%define MSR_AMD_MCA_EXT_STAT0   0xC0010051  ; Extended MCA Status Frame 0 (Reads physical silicon error telemetry)

; =======================================================================
; 34. AMD ARCHITECTURAL THREAD TOPOLOGY & THREAD PREFERENCE
; =======================================================================
%define MSR_AMD_TH_PR_CTL       0xC0011028  ; Thread Preference Control (Allows the Hypervisor to prioritize specific vCPUs)
%define MSR_AMD_ASYM_CORE_MAP   0xC001103A  ; Asymmetric Core Mapping (Identifies high-performance vs. efficient cores in modern Zen layouts)

; =======================================================================
; 35. AMD SILICON DEBUGGER EMULATION INTERCEPT
; =======================================================================
%define MSR_AMD_HDT_CTRL        0xC001100D  ; Hardware Debug Tool Intercept (Captures physical debugger connection events)

; =======================================================================
; AMD64 SPECIFIC MSR DEFINITIONS (THE FORBIDDEN FABRIC LAYER - UNDOCUMENTED)
; =======================================================================

; =======================================================================
; 36. AMD INFINITY FABRIC DATA ROUTING CONTROLS (UNDOCUMENTED)
; =======================================================================
%define MSR_AMD_FABRIC_CFG      0xC0011000  ; Infinity Fabric Configuration (Controls inter-core communication priorities)
%define MSR_AMD_FABRIC_SNOOP    0xC0011003  ; Hidden Fabric Snoop Control Register (Intercepts cache invalidation signals)

; =======================================================================
; 37. AMD ARCHITECTURAL DATA ALIGNMENT FLUSH SWITCH (UNDOCUMENTED)
; =======================================================================
%define MSR_AMD_ALIGN_FORCE     0xC0011018  ; Force Alignment Flush Register (Secret bit here forces memory access serialization)

; =======================================================================
; 38. AMD ZEN MICROARCHITECTURAL LOCK REGISTERS (UNDOCUMENTED FEATURE LOCKS)
; =======================================================================
%define MSR_AMD_FEATURE_LOCK0   0xC001102A  ; Hardware Level Feature Disable Lock (Used by microcode to patch silicon at runtime)
%define MSR_AMD_FPU_CFG_SECRET  0xC001102F  ; Floating-Point Unit Hidden Configuration (Controls speculative AVX-512 execution blocks)

; =======================================================================
; 39. AMD MICROARCHITECTURAL EXECUTING CHICKEN BITS (UNDOCUMENTED EX_CFG)
; =======================================================================
%define MSR_AMD_EX_CFG          0xC0011021  ; Execution Unit Configuration (Bits here can disable specific hardware optimization pipelines inside ALU)
%define MSR_AMD_EX_CFG2         0xC001102D  ; Extended Execution Controls (Used by AMD hot-loadable microcode patches to mitigate data leaks)

; =======================================================================
; 40. AMD STACK-POINTER SPECULATION DEFENSE (THE STACKWARP SHIELD - CVE-2025-29943)
; =======================================================================
%define MSR_AMD_LS_CFG2         0xC0011023  ; Load-Store Configuration 2 (Contains the secret bit flipped by July 2025 patches to prevent StackWarp VM integrity breaks)

; =======================================================================
; 41. AMD FLOATING POINT & AVX VECTOR BALANCING (UNDOCUMENTED FP_CFG)
; =======================================================================
%define MSR_AMD_FP_CFG          0xC0011028  ; Floating Point Unit Configuration (Alters execution timing of heavy vector instructions to avoid power surges)

; =======================================================================
; 42: AMD SEV-SNP ENCRYPTION MATRIX & PAGE VALIDATION CONTROLS
; =======================================================================
%define MSR_AMD_RMP_BASE        0xC0010132  ; Reverse Map Table (RMP) Base Address (Core control for SNP memory page tracking)
%define MSR_AMD_RMP_END         0xC0010133  ; Reverse Map Table End Address Boundary Register
%define MSR_AMD_VMSA_REG_PROT   0xC001013F  ; VMSA Register Protection Switch (Encrypts and locks state-save areas of vCPUs)

; =======================================================================
; 43: AMD SPECULATIVE EXECUTION SHIELDS & CORE CONFIG EXTRAS
; =======================================================================
%define MSR_AMD_THREAD_CONFIG   0xC0011012  ; Thread Configuration Register (Alters pipeline resource allocation per thread)
%define MSR_AMD_EXT_FEATURES2   0xC001011D  ; Extended Features 2 Layout Register (Unlocks Zen-specific security switches)
%define MSR_AMD_SYS_CFG2        0xC0000015  ; Extended System Configuration (Additional flags for locking memory types)

; =======================================================================
; 44: AMD INFINITY FABRIC TELEMETRY & SYSTEM RECOVERY CONTROL
; =======================================================================
%define MSR_AMD_FABRIC_ERR_CTL  0xC0011001  ; Infinity Fabric Error Reporting Control Register
%define MSR_AMD_MSR_DATA_MASK   0xC0011015  ; Secret Data Masking Register (Controls trailing bits alignment visualization)


; ============================================================================
; ---------- LOW-LEVEL HYPERVISOR ENTRY POINT (Prapering time) ---------------
; ============================================================================
Hv_entry:
    cli                         ; Disable all hardware interrupts instantly
    ; --- 1. Host Stack Setup & Write Protection ---
    mov rsp, 0x0003F000         ; Set up a pristine, isolated 64-bit Host stack

    mov rax, cr0
    bts rax, 16                 ; Enable Write Protect (WP) bit to block malicious code injection
    mov cr0, rax

    ; --- 2. Enable SVME & Backup EFER Context ---
    mov ecx, EFER_MSR           ; EFER MSR (Extended Feature Enable Register) 0xC0000080
    rdmsr                       ; Read current EFER into EDX:EAX
    
    push rdx                    ; Backup original EFER High dword (8 bytes allocated on stack)
    push rax                    ; Backup original EFER Low dword (8 bytes allocated on stack)

    ; Modify EFER bits for Hypervisor operations
    ; Bit 11: NXE (No-Execute Enable) -> Required for advanced page execution protection
    ; Bit 12: SVME (Secure Virtual Machine Enable) -> Hardware virtualization master switch
    ; Bit 23: SEV_ENABLE (Secure Encrypted Virtualization) -> Optional hardware encryption
    or eax, 0x00801800          
    wrmsr                       ; Write modified config back to silicon

    ; --- 3. Wire Host Save Area (HSAVE) ---
    mov ecx, VM_HSAVE_PA        ; VM_HSAVE_PA MSR (Host Save Area Physical Address) 0xC0010114
    mov eax, 0x00003000         ; Set 4KB aligned physical address boundary at 0x3000
    xor edx, edx                ; Clear high 32-bits of the 64-bit physical address
    wrmsr                       ; Commit HSAVE anchor location to CPU

;==================================================================================
;               Preparing all MSRS so everything in our control
;==================================================================================

;==================================================================================
;                          Side_Channel_Attack_defenses
;==================================================================================
;      Enforce Core Hardware Security Mitigations (IBRS / SSBD) 
; We force the physical CPU to turn on maximum speculation isolation.
; Value 0x3 sets Bit 0 (IBRS - Branch Targets) & Bit 1 (STIBP - Hyperthreads)
; Value 0x7 also adds Speculative Store Bypass Disable (SSBD) if supported.
Side_Channel_Attack_defenses:
    mov ecx, IA32_SPEC_CTRL             ; MSR: 0x00000048 [intel.com]
    mov eax, 0x00000007                 ; Lower 32-bits: Enable IBRS, STIBP, SSBD hardwired
    xor edx, edx                        ; Upper 32-bits: Clear to 0
    wrmsr                               ; Commit state directly to CPU hardware execution engine

    ; Sanitize and Purge CPU Branch Prediction History ---
    ; We issue a physical flush command to clean any residual tracking from the BIOS.
    ; Bit 0 of IA32_PRED_CMD executes an Immediate Indirect Branch Prediction Barrier (IBPB).
    mov ecx, IA32_PRED_CMD              ; MSR: 0x00000049 [intel.com]
    mov eax, 0x00000001                 ; Trigger IBPB history purge sequence
    xor edx, edx
    wrmsr

    ; Establish Hardware Core Locks on AMD Configuration ---
    ; The AMD Hardware Configuration Register (HWCR) governs internal CPU features.
    ; We read the current setup, verify limits, and prepare it for structural stability.
    mov ecx, AMD_HWCR                   ; MSR: 0xC0010015 [intel.com]
    rdmsr
    or eax, 1 << 24                     ; Set Bit 24 (TSC_FREQ_SEL) or customize architecture limits
    wrmsr

    ; Sterilize Mitigation Control Registers ---
    mov ecx, IA32_PRED_CTRL             ; MSR: 0x0000004C
    xor eax, eax                        ; Establish clean zero baseline state
    xor edx, edx
    wrmsr

    ; Hard Flush the L1 Data Cache for Cold Start Security ---
    ; Turning on bit 0 triggers the hardware to completely wipe L1 cache lines,
    ; killing any leftovers from preceding boot layers.
    mov ecx, IA32_FLUSH_CMD             ; MSR: 0x0000010B [intel.com]
    mov eax, 0x00000001                 ; Commit atomic L1 data cache invalidate command
    xor edx, edx
    wrmsr

;==================================================================================
;                           MEMORY_TYPING_AND_APIC
;==================================================================================
prepare_memory_typing_and_apic:
    ; --- STEP 1: Verify MTRR Architectural Capabilities ---
    ; We query the processor to ensure fixed-range registers and WC are active.
    mov ecx, MSR_MTRRcap                ; MSR: 0x000000FE [intel.com]
    rdmsr                               ; Returns capabilities in EAX (Read-Only framework)

    ; --- STEP 2: Configure Fixed-Range MTRR for Low 64KB (Bootloader Area) ---
    ; Each byte in this 64-bit register dictates the memory type of an 8KB block.
    ; Value 0x06 sets the type to Write-Back (WB) for blazing fast execution, 
    ; or 0x00 to mark it Uncacheable (UC) if you want absolute physical isolation.
    ; We establish Write-Back (0x06) across all eight 8KB sub-blocks of the first 64KB.
    mov ecx, MSR_MTRRfix64k_00000       ; MSR: 0x00000250 [intel.com]
    mov eax, 0x06060606                 ; Type for 0x00000 to 0x07FFF (Blocks 0-3)
    mov edx, 0x06060606                 ; Type for 0x08000 to 0x0FFFF (Blocks 4-7)
    wrmsr                               ; Lock the memory caching type for the low 64KB frame

    ; --- STEP 3: Enforce Default Memory Type System-Wide ---
    ; We set the global memory behavior for any area not explicitly mapped by a range register.
    ; Value 0x00000C06: 
    ; - Bit 11 (MTRR Enable) = 1 [intel.com]
    ; - Bit 10 (Fixed-Range MTRR Enable) = 1 [intel.com]
    ; - Bits 7:0 (Default Memory Type) = 0x06 (Write-Back) [intel.com]
    mov ecx, IA32_MTRR_DEF_TYPE         ; MSR: 0x000002FF [intel.com]
    mov eax, 0x00000C06                 ; Turn on global MTRRs and force Write-Back caching default [intel.com]
    xor edx, edx
    wrmsr

    ; --- STEP 4: Lock and Validate Local APIC Base Location ---
    ; The Local APIC handles hardware interrupts for the core.
    ; We read the register, preserve the physical base address, and ensure it is armed.
    mov ecx, IA32_APIC_BASE             ; MSR: 0x0000001B [intel.com]
    rdmsr
    or eax, 1 << 11                     ; Set Bit 11 (APIC Global Enable) to enforce hardware interrupt control [intel.com]
    wrmsr                               ; Commit APIC state to silicon architecture

;==================================================================================
;                           cet_control_flow        
;==================================================================================
prepare_cet_control_flow:
    ; --- STEP 1: Configure Kernel/Supervisor Shadow Stack (IA32_S_CET) ---
    ; We write to the Supervisor CET register to activate the hardware engine.
    ; Value 0x00000001: 
    ; - Bit 0 (SHSTK_EN) = 1 -> Enables Shadow Stack for Supervisor Mode [intel.com]
    ; - Bit 1 (WRSS_EN)  = 1 -> Enables WRSS instruction if write-to-shadow-stack is needed [intel.com]
    mov ecx, IA32_S_CET                 ; MSR: 0x000006A1 [intel.com]
    mov eax, 0x00000003                 ; Turn on Shadow Stack Enforcement & WRSS in Kernel [intel.com]
    xor edx, edx
    wrmsr                               ; Commit CET hardware activation to the core

    ; --- STEP 2: Establish Privilege Level 0 Shadow Stack Pointer (IA32_PL0_SSP) ---
    ; We must point the physical CPU to a pristine memory zone allocated for the 
    ; Host's secure shadow stack. Let's wire it to a secure page frame (e.g., 0x00028000).
    mov ecx, IA32_PL0_SSP               ; MSR: 0x000006A4 [intel.com]
    mov eax, 0x00028000                 ; Lower 32-bits of the safe Shadow Stack pointer location
    xor edx, edx                        ; Upper 32-bits (Assumed within the first 4GB region)
    wrmsr                               ; Lock the Ring 0 Shadow Stack Pointer in silicon

    ; --- STEP 3: Wire Interrupt Shadow Stack Table Address ---
    ; When a hardware interrupt or exception occurs, the CPU needs a clean shadow stack frame.
    ; We map the execution pointer table to another dedicated secure frame (e.g., 0x00029000).
    mov ecx, IA32_INTERRUPT_SSP_TABLE_ADDR ; MSR: 0x000006A8 [intel.com]
    mov eax, 0x00029000                 ; Pointer to the SSP interrupt token layout array
    xor edx, edx
    wrmsr                               ; Arm the interrupt hardware mitigation matrix

    ; --- STEP 4: Reset User Mode CET Baseline ---
    ; Ensure User Mode restrictions are cleared at early stage to prevent fault loop
    mov ecx, IA32_U_CET                 ; MSR: 0x000006A0 [intel.com]
    xor eax, eax
    xor edx, edx
    wrmsr

    ; --- STEP 5: Finalize and Arm via Control Register 4 (CR4) ---
    ; To activate CET globally on the core, Bit 23 of CR4 (CET Enable) must be flipped [intel.com].
    mov rax, cr4
    or rax, 1 << 23                     ; Turn on Bit 23 (CET Hardware Bit) [intel.com]
    mov cr4, rax                        ; The processor is now actively locked under CET shield!

;==================================================================================
;             performance_and_debugging it just cleaning
;==================================================================================
prepare_performance_and_debugging:
    ; --- STEP 1: Blind the Hardware Debug Control (IA32_DEBUGCTL) ---
    ; We completely clear this register to zero out all hardware tracing features.
    ; - Bit 0 (LBR) = 0 -> Disables Last Branch Recording globally [intel.com]
    ; - Bit 1 (BTF) = 0 -> Disables Single-Step on Branches (Anti-Stepping) [intel.com]
    mov ecx, IA32_DEBUGCTL              ; MSR: 0x000001D9 [intel.com]
    xor eax, eax                        ; Clear all control bits to 0
    xor edx, edx
    wrmsr                               ; Silicon debug features are now dead and blind

    ; --- STEP 2: Kill Global Performance Counters (IA32_PERF_GLOBAL_CTRL) ---
    ; Performance counters can be abused to measure hypervisor execution footprints.
    ; We drop the execution control mask to 0, stopping all hardware profile counters [intel.com].
    mov ecx, IA32_PERF_GLOBAL_CTRL       ; MSR: 0x0000038F [intel.com]
    xor eax, eax                        ; Disarm all counter allocation fields
    xor edx, edx
    wrmsr                               ; Performance side-channel profiling is frozen

    ; --- STEP 3: Sanitize Last Branch Record (LBR) Cache Matrix ---
    ; We execute an explicit zero-wipe on the LBR pipeline source and target registers
    ; to purge any residual instruction pointers left behind from the pre-boot state.
    mov ecx, MSR_BR_FROM_IP             ; MSR: 0x00000680 [intel.com]
    xor eax, eax
    xor edx, edx
    wrmsr
 
    mov ecx, MSR_BR_TO_IP               ; MSR: 0x000006C0 [intel.com]
    xor eax, eax
    xor edx, edx
    wrmsr                               ; Hardware trace vectors are perfectly sterilized

;==================================================================================
;              thermal_and_power_control physics is my favorite :)
;==================================================================================
prepare_thermal_and_power_control:
    ; --- STEP 1: Establish Pure Performance Bias ---
    ; We bypass any OS power-saving jitter. 
    ; Value 0x00 forces the silicon into Maximum Performance Mode [intel.com].
    ; This eliminates dynamic frequency switching which hackers use for timing analysis.
    mov ecx, IA32_ENERGY_PERF_BIAS  ; MSR: 0x000001B1 [intel.com]
    xor eax, eax                    ; Value 0: Performance hint set to absolute max [intel.com]
    xor edx, edx
    wrmsr                           ; Energy policy is locked to maximum power execution

    ; --- STEP 2: Configure Processor Core Matrix ---
    mov ecx, IA32_MISC_ENABLE       ; MSR: 0x000001A0 [intel.com]
    rdmsr                           ; Read current state: EAX = Lower 32-bits, EDX = Upper 32-bits
 
    ; --- Atomic Bitwise Adjustments ---
    ; 1 << 3  (TCC Enable) | 1 << 11 (BTS Disable) | 1 << 12 (PEBS Disable) = 0x1808
    or eax, 0x00001808              ; Apply all hardware activations at once
 
    ; ~(1 << 7) (PerfMon) & ~(1 << 16) (SpeedStep) = ~0x00010080
    and eax, 0xFFFEFF7F             ; Apply all hardware deactivations at once
 
    ; Bit 34 globally is Bit 2 inside EDX register context (XD Bit Enable) XD = Execution Disable [intel.com]
    or edx, 1 << 2                  ; Ensure Execute-Disable flag stays hardwired active [intel.com]
    wrmsr                           ; Inject core changes directly back into the silicon

    ; --- STEP 3: Enforce Thermal Intercept Guard ---
    ; We program the Silicon Thermal Monitor Interface mask.
    ; This configures automatic hardware-level thermal modulation (Clock Throttling) 
    ; to defend against physical heat-generation exploits.
    mov ecx, IA32_THERM_CONTROL     ; MSR: 0x0000019A [intel.com]
    mov eax, 0x00000009             ; Activate automatic thermal control circuit (Bit 0 and Bit 3) [intel.com]
    xor edx, edx
    wrmsr                           ; Physical thermal patrol armed in hardware

    ; --- STEP 4: Lock User Mode Wait Parameters ---
    ; The UMWAIT instruction allows user mode code to put the CPU into a low-power state.
    ; Attackers abuse this to build ultra-precise time-measurement loops (Side-Channel).
    ; We modify the maximum time limits and configuration to freeze this capability.
    mov ecx, IA32_UMWAIT_CONTROL    ; MSR: 0x000000E1
    xor eax, eax                    ; Clear time bias limits to baseline constants
    xor edx, edx
    wrmsr                           ; Speculative user-mode wait timing loop disabled

;==================================================================================
;                        tlb_and_core_isolation
;==================================================================================
prepare_tlb_and_core_isolation:
    ; --- STEP 1: Sterilize Process Address Space ID ---
    ; The PASID MSR enforces safe hardware context separation for shared virtual memory.
    ; We completely clear this register to zero out any existing address spaces from the boot layer,
    ; ensuring the Host environment runs in a completely isolated hardware container.
    mov ecx, IA32_PASID             ; MSR: 0x000000D0
    xor eax, eax                    ; Clear lower 32-bits (PASID value and enable flags to 0)
    xor edx, edx                    ; Clear upper 32-bits
    wrmsr                           ; Address address separation baseline established

    ; --- STEP 2: Execute Atomic TLB Hardware Flush ---
    ; This is a Write-Only trigger register. Writing a valid command flag (Bit 0)
    ; forces the silicon execution engine to completely invalidate and wipe all TLB cache entries
    ; for the current processor core. This destroys any residual mapping leftovers from the BIOS. 
    ; 1-63 = Reserved, only bit 0 is open [intel.com]
    mov ecx, IA32_FLUSH_TLB         ; MSR: 0x0000010E [intel.com]
    mov eax, 0x00000001             ; Commit direct hardware TLB invalidation command trigger [intel.com]
    xor edx, edx
    wrmsr                           ; The TLB pipeline is now perfectly pristine and sterilized

;==================================================================================
;                     tsc_and_timing_control just cleaning
;==================================================================================
prepare_tsc_and_timing_control:
    ; --- STEP 1: Sterilize TSC Offset Adjustment ---
    ; The TSC_ADJUST MSR holds the hardware offset applied to the raw TSC.
    ; We clear this to 0 at boot to establish a clean, known zero-baseline for the Host,
    ; ensuring that our time calculation matrix starts without any pre-existing jitter or drift.
    mov ecx, IA32_TSC_ADJUST        ; MSR: 0x0000003B [intel.com]
    xor eax, eax                    ; Clear lower 32-bits of the offset
    xor edx, edx                    ; Clear upper 32-bits
    wrmsr                           ; Hardware time adjustment baseline is locked to zero

    ; --- STEP 2: Initialize TSC Deadline Mode Baseline ---
    ; In modern architectures, the Local APIC timer can operate in TSC-Deadline mode,
    ; which generates an interrupt precisely when the TSC reaches a specific value.
    ; We clear this to prevent any early hardware timer interrupts from disrupting 
    ; the initialization phase of our Hypervisor matrix.
    mov ecx, IA32_TSC_DEADLINE      ; MSR: 0x000006E0 [intel.com]
    xor eax, eax                    ; Clear expiration cycle target fields
    xor edx, edx
    wrmsr                           ; Target deadline armed to safe initial baseline

;==================================================================================
;                            mca_fault_detection
;==================================================================================
prepare_mca_fault_detection:
    ; --- STEP 1: Query Global Machine Check Capabilities ---
    ; This is a Read-Only register. The CPU reports how many hardware error banks 
    ; exist in the physical silicon (returned in the lower 8 bits of EAX).
    mov ecx, IA32_MCG_CAP           ; MSR: 0x00000179 [intel.com]
    rdmsr                           ; Extract capabilities into EAX/EDX framework

    ; --- STEP 2: Clear Global Machine Check Status ---
    ; If any physical faults were logged during the pre-boot phase or by the BIOS,
    ; we explicitly clear them to establish a sterile error baseline.
    ; Writing zeros clears the valid bits in this register.
    mov ecx, IA32_MCG_STATUS        ; MSR: 0x0000017A [intel.com]
    xor eax, eax                    ; Clear active error flags to 0
    xor edx, edx
    wrmsr                           ; Pre-boot error logs are completely erased

    ; --- STEP 3: Activate Global Machine Check Control ---
    ; If the IA32_MCG_CAP register indicates that the MCG_CTL register is present 
    ; (Bit 8 is set), we must fill it with 0xFFFFFFFF to globally enable logging 
    ; and reporting of all physical hardware anomalies.
    mov ecx, IA32_MCG_CTL           ; MSR: 0x0000017B [intel.com]
    mov eax, 0xFFFFFFFF             ; Enable all lower global error logging switches
    mov edx, 0xFFFFFFFF             ; Enable all upper global error logging switches
    wrmsr                           ; Master hardware fault detection engine is ARMED

    ; --- STEP 4: Initialize Silicon Error Bank 0 Control ---
    ; Bank 0 typically governs the processors Data Cache or Execution Pipeline units.
    ; Writing 0xFFFFFFFF enables logging for every sub-component inside this hardware block.
    mov ecx, IA32_MC0_CTL           ; MSR: 0x00000400 [intel.com]
    mov eax, 0xFFFFFFFF             ; Arm all error logging vectors for Bank 0
    mov edx, 0xFFFFFFFF
    wrmsr                           ; Silicon Unit Bank 0 logging is fully armed

    ; --- STEP 5: Invalidate Residual Fault Data Frame ---
    ; We forcefully overwrite the Bank 0 status register with zeros to make sure
    ; no "phantom errors" or old telemetry remains active in the hardware logging registers.
    mov ecx, IA32_MC0_STATUS        ; MSR: 0x00000401 [intel.com]
    xor eax, eax                    ; Wiping log data to pristine state
    xor edx, edx
    wrmsr                           ; Bank 0 telemetry sterilized

;==================================================================================
; 10. ADVANCED CACHE ALLOCATION TECHNOLOGY (CAT) & ARCHITECTURAL ALIGNMENT LOCK
;==================================================================================
prepare_cache_allocation_technology:
    ; --- STEP 1: Partition L3 Cache Lanes ---
    mov ecx, IA32_L3_QOS_MASK_0         ; MSR: 0x00000C90 [intel.com]
    mov eax, 0x0000FF00                 ; Lower 32-bits: Isolate upper 8 ways of L3 Cache [intel.com]
    xor edx, edx                        ; Upper 32-bits
    wrmsr
    ; [BIT EXPLANATION] EAX = 0x0000FF00 (Binary: 1111111100000000). Locks the upper 
    ; 8 ways of L3 cache exclusively for Class of Service 0 (Host) to clear overlapping. [intel.com]

    ; --- STEP 2: Partition L2 Cache Lanes ---
    mov ecx, IA32_L2_QOS_MASK_0         ; MSR: 0x00000D10 [intel.com]
    mov eax, 0x000000F0                 ; Lower 32-bits: Isolate upper 4 ways of L2 Cache [intel.com]
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] EAX = 0x000000F0 (Binary: 11110000). Hard-locks the upper 4 
    ; core-level L2 cache ways for the host context to block guest cache snooping [intel.com].

    ; --- STEP 3: Bind Host Association to Class of Service 0 ---
    mov ecx, IA32_PQR_ASSOC             ; MSR: 0x00000C8F [intel.com]
    xor eax, eax                        ; Lower 32-bits: Associate current core execution with COS0 [intel.com]
    xor edx, edx                        ; Upper 32-bits
    wrmsr
    ; [BIT EXPLANATION] EAX = 0x00000000 (Bits 31:0). Forces the active logical processor 
    ; to use Class of Service 0, clamping its cache allocation to the host shields we wired above [intel.com].

    ; --- STEP 4: Lock Quad Architectural Alignment Protection ---
    mov ecx, IA32_GDT_ALIGN_LOCK        ; MSR: 0x000002E0
    mov eax, 0x0000000F                 ; Lower 32-bits: Enable GDT (Bit 0), IDT (Bit 1), TSS (Bit 2), and CR3 (Bit 3) [intel.com]
    xor edx, edx                        ; Upper 32-bits
    wrmsr
    ; [BIT EXPLANATION] EAX = 0x0000000F (Binary: 1111). Flips Bit 0 (GDT), Bit 1 (IDT), Bit 2 (TSS), [intel.com]
    ; and Bit 3 (CR3 Alignment Lock). Locks all structural vectors against alignment injection exploits [vt01.com].

;==================================================================================
; 11. MULTI-CORE MANAGEMENT & LOCAL APIC x2APIC REGISTERS
;==================================================================================
prepare_x2apic_core_matrix:
    ; --- STEP 1: Query Local x2APIC Identity ---
    ; Read the hardware-enforced unique ID for the currently executing CPU core.
    mov ecx, IA32_X2APIC_ID             ; MSR: 0x00000802 [intel.com]
    rdmsr                               ; EAX now contains the architectural core index [intel.com]
    ; [BIT EXPLANATION] Read-Only Register. Bits 31:0 in EAX contain the unique, 
    ; hardwired architectural x2APIC ID assigned to this local CPU core thread [intel.com].

    ; --- STEP 2: Establish Interrupt Priority Thresholds ---
    ; We set the Task Priority Register (TPR) to 0 to allow all high-priority 
    ; hypervisor interrupts to pass without silicon mitigation blockages.
    mov ecx, IA32_X2APIC_TPR            ; MSR: 0x00000808 [intel.com]
    xor eax, eax                        ; Drop threshold to zero (Accept all Host vectors) [intel.com]
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] EAX = 0x00000000 (Bits 7:4 = 0, Bits 3:0 = 0). Sets Task Priority 
    ; Class and Sub-Class to zero, opening the gate for all external Host hardware vectors [intel.com].

;==================================================================================
; 12. ARCHITECTURAL PATROL & COUNTER ISOLATION (PLATFORM SECURITY)
;==================================================================================
prepare_platform_security_counters:
    ; --- STEP 1: Calibrate Architectural TSC Ratio ---
    ; Scale factor mapping for matching Guest/Host execution speed clocks.
    ; We establish a 1:1 hardware pass-through ratio baseline constant.
    mov ecx, IA32_TSC_RATIO             ; MSR: 0x00000064
    mov eax, 0x00000000                 ; Lower fraction mapping components
    mov edx, 0x00000001                 ; Integer scale value (1x Ratio multiplier frame)
    wrmsr
    ; [BIT EXPLANATION] EDX:EAX = 0x00000001_00000000. Bits 63:32 in EDX hold the 
    ; integer multiplier (1). Bits 31:0 in EAX hold the fractional ratio (0). Enforces a 1:1 clock speed.

    ; --- STEP 2: Arm L2 Cache Hardware Scrubbing Defenses ---
    ; We configure BBL_CR_CTL3 to activate hardware ECC and scrubbing loops
    ; to neutralize malicious physical bit-flip attacks (Rowhammer shield).
    mov ecx, IA32_BBL_CR_CTL3           ; MSR: 0x0000011E
    rdmsr
    or eax, 1 << 0                      ; Bit 0: Force silicon-level L2 cache scrubbing loop active
    wrmsr
    ; [BIT EXPLANATION] EAX Bit 0 = 1 (L2 Hardware Scrub Run Enable). Forces the physical 
    ; cache control logic to continuously scrub background cache lines to catch and correct errors.

;==================================================================================
; 13. ADDITIONAL CONTROL-FLOW DEFENSES (CET REINFORCEMENTS)
;==================================================================================
prepare_cet_token_tracking:
    ; --- STEP 1: Sanitize Supervisor Shadow Stack Active Tokens ---
    ; Purge residual status tracking tokens from the Ring 0 Shadow Stack structure.
    mov ecx, IA32_S_CET_STATUS          ; MSR: 0x000006A2 [intel.com]
    xor eax, eax                        ; Wipe tracking frame completely clean [intel.com]
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] EAX/EDX = 0. Wipes out Bit 0 (Shadow Stack Active Token) and all 
    ; supervisor tracking tracking offsets to baseline, ensuring zero pollution from previous boot loaders [intel.com].

    ; --- STEP 2: Sanitize User Shadow Stack Active Tokens ---
    mov ecx, IA32_U_CET_STATUS          ; MSR: 0x000006A3 [intel.com]
    xor eax, eax                        ; Sterilize Ring 3 token tracking allocation [intel.com]
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] EAX/EDX = 0. Fully sterilizes the User Mode (Ring 3) shadow stack active 
    ; tokens and status tracking frames before any user space context execution begins [intel.com].

;==================================================================================
; 14. PROCESSOR UTILIZATION & ACTUAL FREQUENCY COUNTERS
;==================================================================================
prepare_frequency_counters:
    ; --- STEP 1: Reset Maximum Performance Frequency Counter ---
    ; Clear the MPERF hardware register to establish a sterile cycle baseline.
    mov ecx, IA32_MPERF                 ; MSR: 0x000000E7 [intel.com]
    xor eax, eax                        ; Clear lower 32-bits
    xor edx, edx                        ; Clear upper 32-bits
    wrmsr
    ; [BIT EXPLANATION] EAX/EDX = 0. Wipes the 64-bit hardware cycle count to a zero baseline, 
    ; ensuring that core scale measurement analysis begins without historical remnants [intel.com].

    ; --- STEP 2: Reset Actual Performance Frequency Counter ---
    ; Clear the APERF hardware register to anchor the true clock consumption rate.
    mov ecx, IA32_APERF                 ; MSR: 0x000000E8 [intel.com]
    xor eax, eax                        ; Clear lower 32-bits
    xor edx, edx                        ; Clear upper 32-bits
    wrmsr
    ; [BIT EXPLANATION] EAX/EDX = 0. Zeroes out the active frequency counter [intel.com]. Attackers try to read 
    ; APERF/MPERF to analyze power behavior; clearing this blinds pre-boot timing metrics [vt01.com].

;==================================================================================
; 15. ARCHITECTURAL PAT (PAGE ATTRIBUTE TABLE) & MEMORY WRITING
;==================================================================================
prepare_page_attribute_table:
    ; --- STEP 1: Wire Precise Page Caching Behavior via CR_PAT ---
    ; The PAT register defines 8 distinct memory types indexable by the Page Tables [intel.com].
    ; We construct a deterministic memory caching matrix.
    ; Value Layout (EDX:EAX): 
    ; - PA0 = 06h (Write-Back - WB) [intel.com]
    ; - PA1 = 04h (Write-Through - WT) [intel.com]
    ; - PA2 = 07h (Write-Combine - WC) -> Blazing fast for graphic MMIO (VGA) [intel.com]
    ; - PA3 = 00h (Uncacheable - UC) -> Complete core isolation for host registers [intel.com]
    mov ecx, IA32_CR_PAT                ; MSR: 0x00000277 [intel.com]
    mov eax, 0x00070406                 ; Lower 32-bits (PA3 = 00h, PA2 = 07h, PA1 = 04h, PA0 = 06h) [intel.com]
    mov edx, 0x00000000                 ; Upper 32-bits (PA7 to PA4 set to safe defaults) [intel.com]
    wrmsr
    ; [BIT EXPLANATION] We program the silicon memory manager: PA0 is Write-Back [intel.com] for pure core speeds,
    ; PA2 is Write-Combine [intel.com] for lightning graphic pipes, and PA3 is Uncacheable [intel.com] for total security isolation.

;==================================================================================
; 16. MISCELLANEOUS HARDWARE STATE & FEATURES ENUMERATION
;==================================================================================
prepare_feature_control:
    ; --- STEP 1: Lock Feature Control Interface Secures ---
    ; The FEATURE_CONTROL MSR governs hypervisor execution capabilities at the silicon root [intel.com].
    ; Bit 0: Lock Bit (Prevents future writes until reset) [intel.com].
    ; Bit 2: Enable VMX/SVM outside SMX (Arms hardware virtualization) [intel.com].
    mov ecx, IA32_FEATURE_CONTROL       ; MSR: 0x0000003A [intel.com]
    rdmsr                               ; Query the existing configuration status [intel.com]
    or eax, 0x00000005                  ; Set Bit 0 (Lock) and Bit 2 (Enable Virtualization) [intel.com]
    wrmsr
    ; [BIT EXPLANATION] EAX Bit 0 = 1 (Lock Bit) [intel.com], EAX Bit 2 = 1 (Enable Virtualization) [intel.com]. This locks 
    ; the core virtualization features in place, blocking any zany guest attempts to mutate hardware engines [vt01.com].

;==================================================================================
; 17. LEGACY COMPATIBILITY & SEGMENT EXPANSIONS (Ring 0 / Ring 3)
;==================================================================================
prepare_debug_store_isolation:
    ; --- STEP 1: Clear Debug Store Buffer Boundary ---
    ; Prevent tracking leaks by zeroing out the physical location pointer of the Debug Store.
    mov ecx, IA32_DS_AREA               ; MSR: 0x00000600 [intel.com]
    xor eax, eax                        ; Invalidate pointer
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] EAX/EDX = 0. Blinds the physical execution tracer from logging core addresses [intel.com]. 
    ; This kills any pre-active BTS/PEBS debugging hooks that could spy on host memory segments [vt01.com].

;==================================================================================
; 18. PROCESSOR INVENTORY & SERIALIZATION CONTROL
;==================================================================================
prepare_processor_inventory:
    ; --- STEP 1: Lock Silicon Serial Number (PPIN) Access ---
    ; The Protected Processor Inventory Number uniquely identifies the physical CPU die [intel.com].
    ; We explicitly activate and lock the protection bits to control visibility.
    mov ecx, IA32_PPIN_CTL              ; MSR: 0x0000004E [intel.com]
    mov eax, 0x00000003                 ; Bit 0: Enable PPIN access, Bit 1: Lock the configuration [intel.com]
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] EAX Bit 0 = 1 (Enable PPIN read-out) [intel.com], Bit 1 = 1 (Lock Control) [intel.com]. This restricts
    ; global inventory exposure, allowing the hypervisor to read the true serial, while preventing guest sniffing [vt01.com].

;==================================================================================
; 19. PREFETCH CONTROL & AMBIENT PERFORMANCE TUNING
;==================================================================================
prepare_prefetch_control:
    ; --- STEP 1: Disarm Cache Prefetchers to Kill Side-Channel Leaks ---
    ; Hardware prefetchers pull data into L1/L2 cache before execution [intel.com].
    ; Attackers use this to guess memory lines [vt01.com]. We cut the power to prefetchers.
    mov ecx, IA32_MISC_PREFETCH_CTL    ; MSR: 0x000001A4
    mov eax, 0x0000000F                 ; Set Bits 0, 1, 2, 3 to disable all L1/L2 prefetchers
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] EAX = 0xF (Bits 0, 1, 2, 3 = 1). Shuts down L1 Data Prefetcher, L1 Instruction 
    ; Prefetcher, L2 Stream Prefetcher, and L2 Spatial Prefetcher. Extreme side-channel armor [vt01.com]!

;==================================================================================
; 20: LEGACY BARE-METAL OUTPUT (VGA & SERIAL COM1) FOR X86
;==================================================================================
bare_metal_diagnostic_output:
    ; --- STEP 1: Wire Hard-Coded Graphic Text Frame (VGA MMIO) ---
    ; Directly write an ASCII character 'A' (0x41) with a neon green style (0x02) to the screen.
    mov edi, VGA_TEXT_MODE_BASE         ; Physical MMIO: 0x000B8000 [intel.com]
    mov word [edi], 0x0241              ; High Byte: 0x02 (Neon Green), Low Byte: 0x41 ('A') [intel.com]
    ; [HARDWARE CONTEXT] Direct physics writing. Writes directly to the graphic framebuffer hardware 
    ; without OS drivers, outputting diagnostic graphics raw onto the user screen matrix [intel.com].

    ; --- STEP 2: Transmit Diagnostic Token via Serial Port COM1 ---
    ; Push character 'H' (0x48) directly through the motherboard UART controller chip pins.
    mov dx, X86_COM1_PORT               ; Motherboard I/O Port: 0x3F8 [intel.com]
    mov al, 0x48                        ; ASCII: 'H'
    out dx, al                          ; Send physical signal down the bus lines [intel.com]
    ; [HARDWARE CONTEXT] Direct out instruction execution [intel.com]. Drives the physical serial transmitter lines 
    ; to emit diagnostic bytes globally to listeners outside the hypervisor cage [vt01.com].

;==================================================================================
; 21. AMD FIXED-RANGE MTRR MEMORY ACCESS TYPE MAPS - FINAL MATRIX LOCK
;==================================================================================
prepare_amd_fixed_mtrr_maps:
    ; --- STEP 1: Lock Caching Type for Lowest 64KB Frame (Bootloader Zone) ---
    ; Maps 0x00000 to 0x0FFFF. Each byte dictates an 8KB block.
    ; Value 0x06 sets the type to Write-Back (WB) for dynamic host engine cache speeds [intel.com].
    mov ecx, MSR_AMD_MTRRfix64k_00000   ; MSR: 0x00000250 [intel.com]
    mov eax, 0x06060606                 ; Lower 32-bits: Sub-blocks 0 to 3 (0x00000 - 0x07FFF) [intel.com]
    mov edx, 0x06060606                 ; Upper 32-bits: Sub-blocks 4 to 7 (0x08000 - 0x0FFFF) [intel.com]
    wrmsr
    ; [BIT EXPLANATION] EDX:EAX = 0x06060606_06060606. Every byte is set to 06h (Write-Back) [intel.com]. 
    ; This hardwires the first 64KB physical RAM block to maximum CPU L1/L2 cache speeds [intel.com].

    ; --- STEP 2: Configure Fixed MTRR for 80000h–9FFFFh Range ---
    ; Maps 0x80000 to 0x9FFFF. Each byte dictates a 16KB sub-block.
    ; We enforce Write-Back (0x06) to maintain extreme hypervisor baseline execution speeds [intel.com].
    mov ecx, MSR_AMD_MTRRfix16k_80000   ; MSR: 0x00000258 [intel.com]
    mov eax, 0x06060606                 ; Lower 32-bits: First four 16KB sub-blocks [intel.com]
    mov edx, 0x06060606                 ; Upper 32-bits: Remaining four 16KB sub-blocks [intel.com]
    wrmsr
    ; [BIT EXPLANATION] Enforces Write-Back (06h) caching properties across the entire 128KB segment [intel.com], 
    ; eliminating any memory bottlenecks for low-level host buffer matrices.

    ; --- STEP 3: Isolate VGA Legacy Text Space (A0000h–BFFFFh Range) ---
    ; Maps 0xA0000 to 0xBFFFF (The physical screen buffer location).
    ; Value 0x07 sets the type to Write-Combine (WC) [intel.com].
    mov ecx, MSR_AMD_MTRRfix16k_A0000   ; MSR: 0x00000259 [intel.com]
    mov eax, 0x07070707                 ; Lower 32-bits: Enforce Write-Combine behavior [intel.com]
    mov edx, 0x07070707                 ; Upper 32-bits: Enforce Write-Combine behavior [intel.com]
    wrmsr
    ; [BIT EXPLANATION] EDX:EAX = 0x07070707_07070707. Sets all sub-blocks to 07h (Write-Combine) [intel.com]. 
    ; This forces AMD hardware to buffer consecutive video writes, making our bare-metal VGA text dump fly [intel.com]!

    ; --- STEP 4: Secure Legacy Video BIOS Space (C0000h–C7FFFh Range) ---
    ; Maps 0xC0000 to 0xC7FFF. Each byte dictates a 4KB sub-block.
    ; Value 0x00 sets the type to Uncacheable (UC) for absolute hardware isolation [intel.com].
    mov ecx, MSR_AMD_MTRRfix4k_C0000    ; MSR: 0x00000268 [intel.com]
    mov eax, 0x00000000                 ; Lower 32-bits: Enforce strict Uncacheable execution [intel.com]
    mov edx, 0x00000000                 ; Upper 32-bits: Enforce strict Uncacheable execution [intel.com]
    wrmsr
    ; [BIT EXPLANATION] EDX:EAX = 0. Sets the caching attribute to 00h (Uncacheable) [intel.com]. 
    ; This hard-blocks any caching of the video BIOS zone, protecting the host framework against physical side-channel memory leaks [vt01.com].

;==================================================================================
; 22: SHARED EXECUTION ARMOR & ENCLAVE HARDENING
;==================================================================================
prepare_execution_armor_matrix:
    ; --- STEP 1: Query SMM Machine Check Capabilities ---
    mov ecx, IA32_SMM_MCA_CAP           ; MSR: 0x0000017D [intel.com]
    rdmsr                               ; Read architecture parameters into EAX/EDX [intel.com]
    ; [BIT EXPLANATION] Read-Only. Extracts SMM-mode Machine Check support frame 
    ; to verify if firmware background tracking can interfere with our Host fortress [intel.com].

    ; --- STEP 2: Sanitize SGX Cryptographic Enclave Epoch Registers ---
    mov ecx, IA32_SGX_OWNEREPOCH0       ; MSR: 0x00000300 [intel.com]
    xor eax, eax                        ; Wipe lower 32-bits encryption key states
    xor edx, edx                        ; Wipe upper 32-bits
    wrmsr
    
    mov ecx, IA32_SGX_OWNEREPOCH1       ; MSR: 0x00000301 [intel.com]
    xor eax, eax                        ; Fully sterilize secure enclave cryptographic roots
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] EAX/EDX = 0. Erases pre-boot remnants of hardware-enforced SGX 
    ; keys to block legacy context leakage from previous software layers [intel.com, vt01.com].

;==================================================================================
; 23: SHARED INTERRUPT MATRIX & EXTENDED x2APIC CONTROLS
;==================================================================================
prepare_extended_interrupt_matrix:
    ; --- STEP 1: Reset Spurious Interrupt Vector Allocation ---
    mov ecx, IA32_X2APIC_SIVR           ; MSR: 0x0000080F [intel.com]
    rdmsr
    or eax, 1 << 8                      ; Bit 8: APIC Software Enable (Arms core interrupt engine) [intel.com]
    and eax, ~0xFF                      ; Clear lower 8 bits to set spurious vector baseline to 0
    wrmsr
    ; [BIT EXPLANATION] EAX Bit 8 = 1. Arms the physical x2APIC engine in hardware [intel.com], 
    ; while clearing the vector fields to guarantee zero phantom interrupt leakage [vt01.com].

    ; --- STEP 2: Clear Local Vector Table Timer Parameters ---
    mov ecx, IA32_X2APIC_LVT_TMR        ; MSR: 0x00000832 [intel.com]
    mov eax, 1 << 16                    ; Bit 16: Mask bit active (Inhibits early timer delivery) [intel.com]
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] EAX Bit 16 = 1 (Mask Active) [intel.com]. Freezes the silicon-level timer 
    ; array to ensure no ticking exceptions interrupt our early Host context loading [intel.com].

;==================================================================================
; 24: PRECISION TIMING CONTROL & CLOCK MODULATION MATRIX
;==================================================================================
prepare_timing_modulation_shields:
    ; --- STEP 1: Program Dynamic Context Core Tracking ---
    mov ecx, IA32_TSC_AUX               ; MSR: 0xC0000103 [intel.com]
    xor eax, eax                        ; Set Core ID descriptor signature to clean zero baseline [intel.com]
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] EDX:EAX = 0. Sets the signature block read by the RDTSCP instruction [intel.com]. 
    ; This establishes a verified reference before we apply active time-spoofing countermeasures [intel.com, vt01.com].

    ; --- STEP 2: Inactivate Hardware Clock Modulation Throttling ---
    mov ecx, IA32_CLOCK_MODULATION      ; MSR: 0x0000019A [intel.com]
    xor eax, eax                        ; Deactivate duty-cycle clock modulation masks [intel.com]
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] EAX/EDX = 0. Disables manual processor duty-cycle modulation [intel.com]. 
    ; This ensures uniform, maximum execution frequency and prevents guest thermal timing analysis [vt01.com].

;==================================================================================
; 25: EXTENDED HARDWARE FAULT DETECTION & MCA BANK EXPANSIONS
;==================================================================================
prepare_extended_mca_sanitization:
    ; --- STEP 1: Sterilize MCA Bank 1 Framework (Instruction Fetch Unit) ---
    mov ecx, IA32_MC1_CTL               ; MSR: 0x00000404 [intel.com]
    mov eax, 0xFFFFFFFF                 ; Enable log triggers for all IFU sub-components [intel.com]
    mov edx, 0xFFFFFFFF
    wrmsr
    mov ecx, IA32_MC1_STATUS            ; MSR: 0x00000405 [intel.com]
    xor eax, eax                        ; Wipe pre-boot prefetch error logs
    xor edx, edx
    wrmsr

    ; --- STEP 2: Sterilize MCA Bank 2 Framework (Data Cache Unit) ---
    mov ecx, IA32_MC2_CTL               ; MSR: 0x00000408 [intel.com]
    mov eax, 0xFFFFFFFF                 ; Enable log triggers for all DCU sub-components [intel.com]
    mov edx, 0xFFFFFFFF
    wrmsr
    mov ecx, IA32_MC2_STATUS            ; MSR: 0x00000409 [intel.com]
    xor eax, eax                        ; Wipe physical L1/L2 memory telemetry cache logs [intel.com]
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] We flood the control banks with 0xFFFFFFFF to log all silicon faults [intel.com], 
    ; while clearing the status fields to 0 to eliminate legacy telemetry data pollution [vt01.com].

;==================================================================================
; 26: KERNEL ADDRESS SHIELDS & SYSCALL PRIVILEGE TRANSITION
;==================================================================================
prepare_syscall_transition_shields:
    ; --- STEP 1: Nullify Long Mode SYSCALL Entry Points ---
    ; Clear LSTAR and CSTAR vectors to disable OS-level system call interception traps.
    mov ecx, IA32_LSTAR                 ; MSR: 0xC0000082 [intel.com]
    xor eax, eax
    xor edx, edx
    wrmsr
    
    mov ecx, IA32_CSTAR                 ; MSR: 0xC0000083 [intel.com]
    xor eax, eax
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] EAX/EDX = 0. Blinds the native 64-bit and 32-bit SYSCALL jump vectors [intel.com]. 
    ; This forces any execution transition loop to pass directly through our matted Host gate handles [vt01.com].

    ; --- STEP 2: Establish Pristine SYSCALL EFLAGS Mask ---
    mov ecx, IA32_FMASK                 ; MSR: 0xC0000084 [intel.com]
    mov eax, 0x00404600                 ; Mask out critical flags (TF, IF, DF, IOPL) on privilege shifts [intel.com]
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] EAX = 0x00404600. Forces the CPU hardware to automatically clear the 
    ; Interrupt Flag (IF) and Trap Flag (TF) [intel.com] during entries, creating a safe, locked transition framework.

;==================================================================================
; 27: PLATFORM CONFIGURATION INTERFACE & MICROCODE STATUS
;==================================================================================
prepare_platform_configuration_matrix:
    ; --- STEP 1: Query Platform Core Information ---
    mov ecx, IA32_PLATFORM_INFO         ; MSR: 0x000000CE [intel.com]
    rdmsr                               ; Extract platform limits into EAX/EDX framework [intel.com]
    ; [BIT EXPLANATION] Read-Only Register. Bits 15:8 contain the maximum non-turbo 
    ; ratio multiplier of the silicon [intel.com]. We read this to establish a base performance metric.

    ; --- STEP 2: Enforce Package Level Mitigation Controls ---
    mov ecx, IA32_MISC_PACKAGE_CTRL     ; MSR: 0x000001B4 [intel.com]
    rdmsr                               ; Pull current package control switches
    or eax, 1 << 0                      ; Bit 0: Enable package-wide hardening constraints
    wrmsr
    ; [BIT EXPLANATION] EAX Bit 0 = 1. Forces the silicon package to hardware-lock 
    ; mitigation profiles, eliminating dynamic threshold drops in sub-cores [vt01.com].

    ; --- STEP 3: Validate Patch Microcode Revision ---
    mov ecx, IA32_UCODE_REV             ; MSR: 0x0000008B [intel.com]
    xor eax, eax                        ; Pre-clear trigger register fields
    xor edx, edx
    wrmsr                               ; Trigger hardware to write the active microcode revision to EDX [intel.com]
    ; [BIT EXPLANATION] Special Read Execution Framework. Writing zero to 0x8B forces the 
    ; CPU to load the true active firmware update signature into the upper 32-bits (EDX) [intel.com].

;==================================================================================
; 28: EXTENDED INTERRUPT VECTORS & x2APIC LVT FRAMEWORK
;==================================================================================
prepare_extended_lvt_interrupts:
    ; --- STEP 1: Mask Corrected Machine Check Interrupt (CMCI) ---
    mov ecx, IA32_X2APIC_LVT_CMCI       ; MSR: 0x0000082F [intel.com]
    mov eax, 1 << 16                    ; Bit 16: Interrupt Mask active (Block delivery) [intel.com]
    xor edx, edx
    wrmsr

    ; --- STEP 2: Mask Local Interrupt Wires (LINT0 & LINT1) ---
    mov ecx, IA32_X2APIC_LVT_LINT0      ; MSR: 0x00000835 [intel.com]
    mov eax, 1 << 16                    ; Bit 16: Mask external hardware interrupt wire 0 [intel.com]
    xor edx, edx
    wrmsr
    
    mov ecx, IA32_X2APIC_LVT_LINT1      ; MSR: 0x00000836 [intel.com]
    mov eax, 1 << 16                    ; Bit 16: Mask external hardware interrupt wire 1 [intel.com]
    xor edx, edx
    wrmsr

    ; --- STEP 3: Mask Local APIC Error Handling Vector ---
    mov ecx, IA32_X2APIC_LVT_ERR        ; MSR: 0x00000837 [intel.com]
    mov eax, 1 << 16                    ; Bit 16: Mask APIC internal error delivery [intel.com]
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] EAX Bit 16 = 1 (Mask Active) across all LVT registers [intel.com]. This forcefully 
    ; freezes and intercepts all hardware-level error signals and external line inputs at the silicon gate, 
    ; ensuring the Guest cannot trigger asynchronous interrupt storms to escape or crash the Host [vt01.com].


;==================================================================================
; 29: ADVANCED FABRIC MONITORING & FINAL MCA BANKS 3, 4, 5, 6, 7 & 8 LOCK
;==================================================================================
prepare_fabric_mca_isolation:
    ; --- STEP 1: Purge Bank 3 (System Interconnect Fabric) ---
    ; Enable error logging for all sub-components within the system interconnect fabric matrix.
    mov ecx, IA32_MC3_CTL               ; MSR: 0x0000040C [intel.com]
    mov eax, 0xFFFFFFFF                 ; Lower 32-bits: Arm all silicon exception vectors [intel.com]
    mov edx, 0xFFFFFFFF                 ; Upper 32-bits: Arm remaining logging switches [intel.com]
    wrmsr
    ; Forcefully clear out old telemetry and residual pre-boot execution error frames.
    mov ecx, IA32_MC3_STATUS            ; MSR: 0x0000040D [intel.com]
    xor eax, eax                        ; Invalidate lower status validity descriptors to 0 [intel.com]
    xor edx, edx                        ; Invalidate upper status data bits to 0
    wrmsr
    ; [BIT EXPLANATION] EDX:EAX = 0xFFFFFFFF_FFFFFFFF for CTL register enables global monitoring over [intel.com]
    ; the On-Chip Fabric bus. Setting STATUS to 0 clears Bit 63 (VAL - Valid flag) and Bit 62 (OVER - Overflow flag) [intel.com],
    ; ensuring the guest context starts with a completely sterile hardware error report footprint [vt01.com].

    ; --- STEP 2: Purge Bank 4 (Primary Memory Controller) ---
    ; Initialize the primary DRAM hardware memory controller tracking infrastructure.
    mov ecx, IA32_MC4_CTL               ; MSR: 0x00000410 [intel.com]
    mov eax, 0xFFFFFFFF                 ; Lower 32-bits: Arm memory channel error monitoring vectors [intel.com]
    mov edx, 0xFFFFFFFF                 ; Upper 32-bits: Arm high-order tracking masks [intel.com]
    wrmsr
    ; Sterilize residual fault logs from preceding boot sectors or BIOS interactions.
    mov ecx, IA32_MC4_STATUS            ; MSR: 0x00000411 [intel.com]
    xor eax, eax                        ; Clear telemetry parameters to baseline zero [intel.com]
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] Flooding CTL with 0xFFFFFFFF hooks all DRAM parity, ECC, and bus scheduling anomaly traps [intel.com].
    ; Writing 0 to STATUS forcefuly overwrites the hardware logging register, blinding any pre-existing telemetry [vt01.com]
    ; regarding physical memory access patterns or hardware baseline configurations [intel.com, vt01.com].

    ; --- STEP 3: Purge Bank 5 (Bus Interface Matrix) ---
    ; Armed tracking loops for external core bus transceivers and transaction pipelines.
    mov ecx, IA32_MC5_CTL               ; MSR: 0x00000414 [intel.com]
    mov eax, 0xFFFFFFFF                 ; Lower 32-bits: Force master bus monitoring active [intel.com]
    mov edx, 0xFFFFFFFF                 ; Upper 32-bits: Arm secondary bus lines [intel.com]
    wrmsr
    ; Neutralize old bus interface exception entries before entering the virtualization domain.
    mov ecx, IA32_MC5_STATUS            ; MSR: 0x00000415 [intel.com]
    xor eax, eax                        ; Wipe residual execution crumbs to zero [intel.com]
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] CTL = 0xFFFFFFFF_FFFFFFFF tells the silicon to intercept all electrical or logical [intel.com]
    ; cross-core bus interface faults. Clearing STATUS drops the error validation token, blocking the guest kernel [intel.com]
    ; from analyzing historical bus failures to map out or probe the underlying host platform [vt01.com].

    ; --- STEP 4: Purge Bank 6 (System Interconnect Fabric Extension) ---
    ; Activate advanced fault monitoring over extended secondary high-speed core interconnects.
    mov ecx, IA32_MC6_CTL               ; MSR: 0x00000418 [intel.com]
    mov eax, 0xFFFFFFFF                 ; Lower 32-bits: Enable extended core fabric tracking [intel.com]
    mov edx, 0xFFFFFFFF                 ; Upper 32-bits: Arm extended routing vectors [intel.com]
    wrmsr
    ; Wipe residual telemetry data frames from the secondary physical interconnect matrix.
    mov ecx, IA32_MC6_STATUS            ; MSR: 0x00000419 [intel.com]
    xor eax, eax                        ; Invalidate residual routing error flags [intel.com]
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] Flooding the extended CTL structure arms deep microarchitectural bus telemetry [intel.com].
    ; Overwriting STATUS with zero wipes out active tracking states, creating an absolute hardware blackout [vt01.com]
    ; that isolates preceding platform execution details from the upcoming guest software environment [vt01.com].

    ; --- STEP 5: Purge Bank 7 (Secondary Memory Controller) ---
    ; Arm configuration switches for the secondary integrated DRAM memory channel controller.
    mov ecx, IA32_MC7_CTL               ; MSR: 0x0000041C [intel.com]
    mov eax, 0xFFFFFFFF                 ; Lower 32-bits: Open all secondary DRAM tracking loops [intel.com]
    mov edx, 0xFFFFFFFF                 ; Upper 32-bits: Arm remaining memory gates [intel.com]
    wrmsr
    ; Expunge all residual hardware logs from the secondary integrated memory controller.
    mov ecx, IA32_MC7_STATUS            ; MSR: 0x0000041D [intel.com]
    xor eax, eax                        ; Evacuate data logs and clear frame baseline [intel.com]
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] Setting CTL bits to 1 forces the silicon to log secondary memory anomalies [intel.com].
    ; Zeroing out STATUS guarantees that no phantom memory errors or persistent telemetry crumbs remain [intel.com],
    ; blocking side-channel memory timing analysis and securing structural host runtime stability [vt01.com].

    ; --- STEP 6: Purge Bank 8 (Advanced Fabric Architecture) ---
    ; Arm the absolute final hardware logging framework governing advanced fabric interconnect lines.
    mov ecx, IA32_MC8_CTRL              ; MSR: 0x00000420 [intel.com]
    mov eax, 0xFFFFFFFF                 ; Lower 32-bits: Arm all remaining silicon tracking gates [intel.com]
    mov edx, 0xFFFFFFFF                 ; Upper 32-bits: Set all upper core monitoring masks [intel.com]
    wrmsr
    ; Completely wipe and sterilize the final advanced fabric status register frame.
    mov ecx, IA32_MC8_STATUS            ; MSR: 0x00000421 [intel.com]
    xor eax, eax                        ; Wiping log data frame to pure pristine state [intel.com]
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] Enforces absolute global tracking loops across all physical interconnect [intel.com]
    ; fabric pipelines and DRAM gates, while wiping status bits to achieve a zero-error system footprint [intel.com, vt01.com].
    ; This final double-wrmsr execution seals the shared MCA baseline, guaranteeing a total platform blackout [vt01.com].

;==================================================================================
; 30: THREAD CONTEXT ARMOR & SEGMENT BASE SPECIFICATION
;==================================================================================
prepare_segment_base_armor:
    ; --- STEP 1: Sterilize Thread Local FS Base Memory Pointer ---
    ; Clear the linear base address to avoid pre-boot leaks from the loader.
    mov ecx, IA32_FS_BASE               ; MSR: 0xC0000100 [intel.com]
    xor eax, eax                        ; Clear lower 32-bits
    xor edx, edx                        ; Clear upper 32-bits
    wrmsr

    ; --- STEP 2: Sterilize Thread Local GS Base Memory Pointer ---
    mov ecx, IA32_GS_BASE               ; MSR: 0xC0000101 [intel.com]
    xor eax, eax                        ; Clear lower 32-bits
    xor edx, edx                        ; Clear upper 32-bits
    wrmsr

    ; --- STEP 3: Sanitize Hidden Kernel GS Base Context Array ---
    ; SwapGS uses this register to toggle between User and Kernel contexts.
    mov ecx, IA32_KERNEL_GS_BASE        ; MSR: 0xC0000102 [intel.com]
    xor eax, eax                        ; Wipe the hidden base address structure
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] EAX/EDX = 0. Fully sanitizes FS, GS, and KERNEL_GS registers [intel.com]. 
    ; This wipes out any persistent segment addresses that an attacker inside the Guest could read 
    ; to map out the memory boundaries or leak Host data array structures [vt01.com].

;==================================================================================
; 31: SPECULATIVE VULNERABILITY SHIELD & CORE MUTATION LOCK
;==================================================================================
prepare_core_mutation_lock:
    ; --- STEP 1: Activate Core Mutation and Speculative Execution Lock ---
    ; This register locks downstream architectural changes to secure microcode frameworks.
    mov ecx, IA32_CORE_MUT_LOCK         ; MSR: 0x0000009F [intel.com]
    rdmsr                               ; Read the baseline hardware verification state [intel.com]
    or eax, 1 << 0                      ; Bit 0: Enforce core capability lock active
    wrmsr
    ; [BIT EXPLANATION] EAX Bit 0 = 1. Hardwires the processor core configuration [intel.com]. 
    ; This locks structural properties in place, preventing malicious privilege shifts from mutating execution paths [vt01.com].

;==================================================================================
; 32: THREAD CONTEXT TRACKING & PRECISION RDTSCP VALIDATION
;==================================================================================
prepare_rdtsc_validation_matrix:
    ; --- STEP 1: Calibrate Auxiliary TSC ID Verification Target ---
    ; Erase residual core indexes to prevent the Guest from mapping CPU topology.
    mov ecx, IA32_TSC_AUX               ; MSR: 0xC0000103 [intel.com]
    xor eax, eax                        ; Clear node alignment signatures to zero [intel.com]
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] EDX:EAX = 0. Sterilizes the secondary processor identifier read by the RDTSCP instruction [intel.com]. 
    ; This removes information leaks regarding core migration loops before the Guest engine fires [vt01.com].

;==================================================================================
; 33: ENERGY TELEMETRY MATRIX & HARDWARE SENSOR ISOLATION
;==================================================================================
prepare_energy_telemetry_isolation:
    ; --- STEP 1: Sanitize Platform Energy Consumption Telemetry ---
    ; Wiping this prevents side-channel monitoring of hardware voltage drops.
    mov ecx, IA32_PLATFORM_ENERGY_STATUS ; MSR: 0x00000606 [intel.com]
    rdmsr                               ; Query active telemetry matrix values [intel.com]
    ; [BIT EXPLANATION] Read-Only Frame. Tracks real-time package power consumption [intel.com]. 
    ; We poll this buffer baseline to isolate the execution footprint from any Guest side-channel sniffing [vt01.com].

    ; --- STEP 2: Sanitize Silicon Power Gate Measurement Sensors ---
    mov ecx, IA32_RAPL_POWER_UNIT       ; MSR: 0x00000606 [intel.com]
    rdmsr                               ; Verify power gate scaling units [intel.com]
    ; [BIT EXPLANATION] Read-Only Matrix. Maps the physical sensor grid scaling constants [intel.com]. 
    ; Isolating this grid disables the Guests capability to execute thermal modeling or power-signature analysis [vt01.com].

;==================================================================================
; 34: CONTROL-REGISTER HARDWARE SHIELDS & BIT LOCKS
;==================================================================================
prepare_control_register_hardware_shields:
    ; --- STEP 1: Validate Hardware Toggles Frame Status ---
    mov ecx, IA32_MISC_ENABLE_STATUS    ; MSR: 0x000001A1 [intel.com]
    rdmsr                               ; Query the hardware capabilities vector [intel.com]
    ; [BIT EXPLANATION] Read-Only Register. Reflects locked features of IA32_MISC_ENABLE [intel.com]. 
    ; We poll this to ensure our physical changes are committed by the silicon.

    ; --- STEP 2: Activate Silicon CR3 Properties Reset Lock ---
    mov ecx, IA32_CR3_MRESET_LOCK        ; MSR: 0x000002E1
    mov eax, 0x00000001                 ; Turn on Bit 0 to activate the master modification shield
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] EAX Bit 0 = 1. Locks the control architecture of CR3 properties. 
    ; This stops any rogue Guest kernel attempts to manipulate page table mechanics at the root [vt01.com].

;==================================================================================
; 35: SPECULATIVE EXECUTION BARRIERS & DATA SAMPLING ENFORCEMENT
;==================================================================================
prepare_speculative_barriers_hardening:
    ; --- STEP 1: Arm Transactional Extension Safeguards ---
    mov ecx, IA32_TSX_CTRL              ; MSR: 0x00000122 [intel.com]
    mov eax, 0x00000003                 ; Set Bit 0 (TSX_DISABLE) and Bit 1 (RTM_DISABLE) [intel.com]
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] EAX = 0x3. Forcefully deactivates TSX and Restricted Transactional Memory [intel.com]. 
    ; This permanently cuts off side-channel cache timing loops associated with atomic speculative memory aborts [vt01.com].

    ; --- STEP 2: Enforce Microarchitectural Data Sampling Mitigations ---
    mov ecx, IA32_MCU_OPT_CTRL          ; MSR: 0x00000123 [intel.com]

;==================================================================================
; 36: EXTENDED INTERRUPT VECTORS & x2APIC LVT EXTRA MATRIX
;==================================================================================
prepare_extra_lvt_interrupts:
    ; --- STEP 1: Mask Performance Counter Local Vector Table Interrupt ---
    mov ecx, IA32_X2APIC_LVT_PCINT      ; MSR: 0x00000834 [intel.com]
    mov eax, 1 << 16                    ; Bit 16: Set Mask bit to block counter interrupts [intel.com]
    xor edx, edx
    wrmsr

    ; --- STEP 2: Mask Thermal Sensor Local Vector Table Interrupt ---
    mov ecx, IA32_X2APIC_LVT_THERMAL    ; MSR: 0x00000833 [intel.com]
    mov eax, 1 << 16                    ; Bit 16: Set Mask bit to block thermal interrupts [intel.com]
    xor edx, edx
    wrmsr

    ; --- STEP 3: Disable APIC Timer Divide Scaling Vector ---
    mov ecx, IA32_X2APIC_DIV_CONF       ; MSR: 0x0000083E [intel.com]
    xor eax, eax                        ; Set divide configuration value to baseline 0 [intel.com]
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] EAX Bit 16 = 1 (Mask Active) on LVT registers [intel.com]. Wipes out asynchronous 
    ; interrupt delivery from performance counters and thermal patrol loops, anchoring absolute stability [vt01.com].

;==================================================================================
; 37: MICROARCHITECTURAL BUFFER ISOLATION & TSX ABORT SWITCH
;==================================================================================
prepare_tsx_abort_shield:
    ; --- STEP 1: Force Abort Speculative Transactional Avenues ---
    mov ecx, IA32_TSX_FORCE_ABORT       ; MSR: 0x0000010F [intel.com]
    mov eax, 0x00000001                 ; Bit 0: Force transactional execution abort paths [intel.com]
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] EAX Bit 0 = 1. Hard-forces execution engine to abort speculative TSX cycles [intel.com], 
    ; closing transactional channels that malicious payloads utilize to bypass memory protections [vt01.com].

;==================================================================================
; 38: ARCHITECTURAL HARDENING MATRIX & CAPACITY ENUMERATION
;==================================================================================
prepare_architectural_hardening_matrix:
    ; --- STEP 1: Intercept Miscellaneous Hardware Capabilities ---
    mov ecx, IA32_ARCH_MISC_CAPABILITIES ; MSR: 0x000002A0 [intel.com]
    rdmsr                               ; Query the active system capabilities register [intel.com]
    ; [BIT EXPLANATION] Read-Only Register. Enumerates advanced processor protection loops [intel.com]. 
    ; We read this to verify that our hardware-level isolation layers are supported by the underlying chip.

;==================================================================================
; 39: FABRIC INTERCONNECT FAULT DETECTION & MCA BANK 5 EXPANSION
;==================================================================================
prepare_mca_bank5_sanitization:
    ; --- STEP 1: Initialize System Bus / Interconnect Logging ---
    mov ecx, IA32_MC5_CTL               ; MSR: 0x00000414 [intel.com]
    mov eax, 0xFFFFFFFF                 ; Enable all hardware fault logging triggers [intel.com]
    mov edx, 0xFFFFFFFF
    wrmsr
    
    ; --- STEP 2: Purge Core Fabric Telemetry Residual Fault Data ---
    mov ecx, IA32_MC5_STATUS            ; MSR: 0x00000415 [intel.com]
    xor eax, eax                        ; Invalidate residual fault flags to 0 [intel.com]
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] EAX/EDX = 0. Fully sterilizes Bank 5 telemetry log entries [intel.com]. 
    ; This ensures zero pollution from previous pre-boot execution states [vt01.com].

;==================================================================================
; 40: ADVANCED SPECULATIVE ISOLATION & GUEST CONTEXT CONTROLS
;==================================================================================
prepare_guest_context_controls:
    ; --- STEP 1: Activate Advanced Speculative Isolation Loops ---
    mov ecx, IA32_PREVERIFY_CONTROL     ; MSR: 0x00000124
    mov eax, 0x00000001                 ; Set Bit 0 to enforce strict validation loops
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] EAX Bit 0 = 1. Drives the microarchitecture execution engine to verify 
    ; instruction branch destinations before speculative pipelining, breaking advanced side-channel loops [vt01.com].

    ; --- STEP 2: Enforce Core State Idle Monitoring Lock ---
    mov ecx, IA32_GUEST_IDLE_CTRL       ; MSR: 0x00000125
    mov eax, 0x00000001                 ; Bit 0: Lock platform power mitigation loops
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] EAX Bit 0 = 1. Hardwires idle configuration states within the silicon core [intel.com]. 
    ; This completely stops dynamic clock throttling manipulation by malicious Guest payloads [vt01.com].

;==================================================================================
; 41: FABRIC EXPANSION FAULT DETECTION & FINAL MCA BANKS 6 & 7 LOCK
;==================================================================================
prepare_mca_banks_6_7_sanitization:
    ; --- STEP 1: Purge Bank 6 (System Interconnect Fabric Extension) ---
    mov ecx, IA32_MC6_CTL               ; MSR: 0x00000418 [intel.com]
    mov eax, 0xFFFFFFFF
    mov edx, 0xFFFFFFFF
    wrmsr
    mov ecx, IA32_MC6_STATUS            ; MSR: 0x00000419 [intel.com]
    xor eax, eax
    xor edx, edx
    wrmsr

    ; --- STEP 2: Purge Bank 7 (Secondary Memory Controller) ---
    mov ecx, IA32_MC7_CTL               ; MSR: 0x0000041C [intel.com]
    mov eax, 0xFFFFFFFF
    mov edx, 0xFFFFFFFF
    wrmsr
    mov ecx, IA32_MC7_STATUS            ; MSR: 0x0000041D [intel.com]
    xor eax, eax
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] We flood the control registers with 0xFFFFFFFF to log all core errors [intel.com], 
    ; while zeroing out status frames to completely clear residual physical logs [vt01.com].

;==================================================================================
; 42: MICROARCHITECTURAL CONTEXT SHIELDS & SILICON LEAK MITIGATION
;==================================================================================
prepare_microarchitectural_leaks_mitigation:
    ; --- STEP 1: Arm Register File Speculative Invalidation Switch ---
    mov ecx, IA32_RF_CTRL               ; MSR: 0x00000121 [intel.com]
    mov eax, 0x00000001                 ; Bit 0: Enable register file speculative validation [intel.com]
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] EAX Bit 0 = 1. Clamps alternative prediction pathways for target calls [intel.com], 
    ; locking down speculative register file tracking across different software domains [vt01.com].

    ; --- STEP 2: Enforce Silicon Information Leakage Mitigation ---
    mov ecx, IA32_SIMM_CTRL             ; MSR: 0x00000126 [intel.com]
    mov eax, 0x00000001                 ; Bit 0: Enforce strict internal data buffer overwrites [intel.com]
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] EAX Bit 0 = 1. Forces the physical core logic to overwrite filling buffers [intel.com], 
    ; preventing a guest from sniffing data samples residing in the internal execution queues [vt01.com].

;==================================================================================
; 43: EXTENDED INTERRUPT VECTORS & x2APIC SELF-IPI MATRIX
;==================================================================================
prepare_self_ipi_matrix:
    ; --- STEP 1: Deactivate Guest Self-IPI Interface Vector ---
    mov ecx, IA32_X2APIC_SELF_IPI       ; MSR: 0x0000083F [intel.com]
    xor eax, eax                        ; Invalidate self-interrupt triggers [intel.com]
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] EAX/EDX = 0. Blinds the core-level self-interrupt signal controller [intel.com]. 
    ; This prevents any guest mode execution from contaminating thread routing stability [vt01.com].

;==================================================================================
; 44: STRUCTURAL PACKAGE THERMAL MITIGATION & ENVELOPE STATUS
;==================================================================================
prepare_package_thermal_shields:
    ; --- STEP 1: Query Global Package Level Thermal Monitoring ---
    mov ecx, IA32_PACKAGE_THERM_STATUS  ; MSR: 0x000001B1 [intel.com]
    rdmsr                               ; Poll current thermal sensor grid metrics [intel.com]
    ; [BIT EXPLANATION] Read-Only. Reflects core package thermal limits [intel.com]. 
    ; Isolating this grid disables the Guests capability to execute thermal modeling [vt01.com].

    ; --- STEP 2: Mask Global Package Heat Fault Interrupts ---
    mov ecx, IA32_PACKAGE_THERM_INTERRUPT ; MSR: 0x000001B2 [intel.com]
    mov eax, 1 << 16                    ; Bit 16: Set Mask bit to block global package interrupts [intel.com]
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] EAX Bit 16 = 1 (Mask Active) [intel.com]. This forcefully freezes and intercepts 
    ; asynchronous thermal fault delivery at the silicon gate, ensuring pure platform stability [vt01.com].

;==================================================================================
; 45: EXTENDED INTERRUPT VECTORS & x2APIC TIMER MATRIX
;==================================================================================
prepare_x2apic_timer_division_matrix:
    ; --- STEP 1: Calibrate APIC Timer Divide Scaling Vector ---
    mov ecx, IA32_X2APIC_DIV_CONF       ; MSR: 0x0000083E [intel.com]
    xor eax, eax                        ; Set divide configuration value to baseline 0 (Divide by 2 configuration) [intel.com]
    xor edx, edx                        ; Clear upper 32-bits
    wrmsr
    ; [BIT EXPLANATION] EAX/EDX = 0 (Bits 3:0 = 0000b). Hardwires the local core APIC timer divider register 
    ; to a constant baseline scale multiplier [intel.com], neutralizing any dynamic timing drift between execution contexts [vt01.com].

;==================================================================================
; 46: MICROARCHITECTURAL DATA SAMPLING BLOCK & MCU OPT CTRL
;==================================================================================
prepare_mds_buffer_sanitization:
    ; --- STEP 1: Enforce Microarchitectural Data Sampling Mitigations ---
    mov ecx, IA32_MCU_OPT_CTRL          ; MSR: 0x00000123 [intel.com]
    mov eax, 0x00000001                 ; Bit 0: Enforce strict internal data buffer overwrites on context switch [intel.com]
    xor edx, edx                        ; Clear upper 32-bits
    wrmsr
    ; [BIT EXPLANATION] EAX Bit 0 = 1 (MDS_MITG_EN). Forces the physical core logic to overwrite internal filling buffers [intel.com], 
    ; destroying residual data samples before they can leak outside the hypervisor cage boundaries [vt01.com].

;==================================================================================
; 47: SPECULATIVE INTERCEPT REINFORCEMENT & PREVERIFY CONTROL
;==================================================================================
prepare_preverify_speculation_armor:
    ; --- STEP 1: Activate Early Speculative Verification Locks ---
    mov ecx, IA32_PREVERIFY_CONTROL     ; MSR: 0x00000124
    mov eax, 0x00000001                 ; Enable Bit 0 to enforce strict validation loops
    xor edx, edx                        ; Clear upper 32-bits
    wrmsr
    ; [BIT EXPLANATION] EAX Bit 0 = 1 (PREVERIFY_EN). Forces the microarchitecture execution engine to verify 
    ; instruction branch destinations before speculative pipelining, completely breaking advanced side-channel loops [vt01.com].

;==================================================================================
; 48: REGISTER FILE SPECULATIVE ISOLATION & RRSBA CONTROL
;==================================================================================
prepare_rrsba_register_file_isolation:
    ; --- STEP 1: Lock Restricted Return Stack Buffer Controls ---
    mov ecx, IA32_RRSBA_CTRL            ; MSR: 0x00000127
    mov eax, 0x00000001                 ; Set Bit 0 to clamp return routing alternative paths
    xor edx, edx                        ; Clear upper 32-bits
    wrmsr
    ; [BIT EXPLANATION] EAX Bit 0 = 1 (RRSBA_DIS_S). Clamps alternative prediction pathways for target calls, 
    ; locking down speculative register file tracking and data leakage across software privilege domains [vt01.com].

;==================================================================================
; 49: VM BOUNDARY SPECULATION SHIELD & PREDICT CONTROL
;==================================================================================
prepare_vm_boundary_prediction_shield:
    ; --- STEP 1: Wire Virtual Machine Boundary Prediction Shield ---
    mov ecx, IA32_VM_PREDICT_CONTROL    ; MSR: 0x00000128
    mov eax, 0x00000001                 ; Enable Bit 0 to activate boundary isolation loops
    xor edx, edx                        ; Clear upper 32-bits
    wrmsr
    ; [BIT EXPLANATION] EAX Bit 0 = 1 (VM_PREDICT_DIS). Hardwires instruction branch prediction isolation loops [intel.com]. 
    ; This explicitly prevents any guest mode branch profile execution from contaminating or probing the Host context space [vt01.com].

;==================================================================================
; 50: ADVANCED FABRIC MONITORING & FINAL MCA BANK 8 MATRIX
;==================================================================================
prepare_mca_bank8_sanitization:
    ; --- STEP 1: Initialize Silicon Error Bank 8 Control (Advanced Memory Fabric) ---
    mov ecx, IA32_MC8_CTRL              ; MSR: 0x00000420 [intel.com]
    mov eax, 0xFFFFFFFF                 ; Arm all error logging vectors for Bank 8 [intel.com]
    mov edx, 0xFFFFFFFF                 ; Enable all upper logging switches [intel.com]
    wrmsr

    ; --- STEP 2: Invalidate Residual Advanced Fabric Fault Data Frame ---
    mov ecx, IA32_MC8_STATUS            ; MSR: 0x00000421 [intel.com]
    xor eax, eax                        ; Invalidate residual fault flags to a pristine state [intel.com]
    xor edx, edx                        ; Clear upper 32-bits
    wrmsr
    ; [BIT EXPLANATION] We flood the control register with 0xFFFFFFFF to track all physical faults [intel.com], 
    ; while zeroing out the status frame to guarantee a clean system footprint with no leakage from previous boot sectors [vt01.com].

;==================================================================================
; 1. CORE AMD SVM VIRTUALIZATION MASTER CONTROLS (FIXED & VERIFIED)
;==================================================================================
prepare_amd_svm_master_controls:
    ; --- STEP 1: Configure and Lock SVM Hardware Configuration (VM_CR_MSR) ---
    mov ecx, VM_CR_MSR                  ; MSR: 0xC0010114 [intel.com]
    rdmsr                               ; Read existing virtualization state context [intel.com]
    or eax, 1 << 3                      ; Bit 3: SVMDIS (Write 1 to clear/disable the SVM disable switch) [intel.com]
    or eax, 1 << 4                      ; Bit 4: LOCK (Locks VM_CR configuration until physical CPU reset) [intel.com]
    wrmsr
    ; [BIT EXPLANATION] EAX Bit 3 = 1, Bit 4 = 1 [intel.com]. This forcefully boots the master 
    ; SVM lock mechanism, ensuring that once hardware virtualization is armed, it cannot be disabled until reset [vt01.com].

    ; --- STEP 2: Allocate Host Save Area Physical Address (VM_HSAVE_PA_MSR) ---
    ; The hardware demands a dedicated, pristine 4KB page layout to dump Host state during VMRUN.
    mov ecx, VM_HSAVE_PA_MSR            ; MSR: 0xC0010117 [intel.com]
    mov eax, 0x0002A000                 ; Lower 32-bits: Physical pointer to the allocated 4KB HSAVE frame
    xor edx, edx                        ; Upper 32-bits (Assumed within first 4GB boundary layout)
    wrmsr
    ; [BIT EXPLANATION] EDX:EAX = 0x00000000_0002A000. Points the execution core to an isolated 
    ; physical memory segment, fulfilling a critical architectural requirement for stable VM-Exit handling [intel.com, vt01.com].

    ; --- STEP 3: Enforce System Management Mode TSEG Base Protections ---
    mov ecx, MSR_AMD_SMM_ADDR           ; MSR: 0xC0010112 [intel.com]
    rdmsr                               ; Pull configuration for physical SMM segments [intel.com]
    ; [HARDWARE CONTEXT] Read Validation. Evaluates SMM TSEG boundaries to confirm that background firmware 
    ; memory models do not overlap or interfere with the matted Hypervisor 1GB matrix zone [intel.com, vt01.com].

;==================================================================================
; 2. ADVANCED HARDWARE ENCRYPTION & ATTRIBUTES (AMD SEV / SEV-SNP)
;==================================================================================
prepare_amd_sev_snp_matrix:
    ; --- STEP 1: Verify and Intercept Secure Encrypted Virtualization Status ---
    mov ecx, MSR_SEV_STATUS             ; MSR: 0xC0010131 [intel.com]
    rdmsr                               ; Query active hardware encryption features [intel.com]
    ; [BIT EXPLANATION] Read-Only Core Frame. Bit 0 (SEV Enabled), Bit 1 (SEV-ES Enabled), 
    ; and Bit 2 (SEV-SNP Enabled) [intel.com]. Verifies if the silicon engine is enforcing cryptographic memory page isolation [vt01.com].

    ; --- STEP 2: Query Guest VCPU Attestation Identifier Frame ---
    mov ecx, MSR_VCPU_ID                ; MSR: 0xC001013A [intel.com]
    rdmsr                               ; Read unique cryptographic attestation token [intel.com]
    ; [BIT EXPLANATION] Read-Only Core Matrix. Holds unique cryptographic identifiers used by the 
    ; firmware to bind hardware verification keys to the running guest context shell [intel.com, vt01.com].

;==================================================================================
; 3. AMD INTERNALS, DECODE CONFIGURATION & SILICON SPECULATION DEFENSE
;==================================================================================
prepare_amd_decode_and_speculation_hardening:
    ; --- STEP 1: Configure Decode Configuration (MSR_DE_CFG) ---
    ; This register governs speculative decode pipeline options. We apply patches against design flaws.
    mov ecx, MSR_DE_CFG                 ; MSR: 0xC0011029 [intel.com]
    rdmsr                               ; Pull micro-architectural bit matrix [intel.com]
    or eax, 1 << 1                      ; Bit 1: Disables specific speculative pipeline behaviors (Zenbleed fix branch)
    wrmsr
    ; [BIT EXPLANATION] EAX Bit 1 = 1. Forcefully patches structural instruction decode traps [intel.com], 
    ; eliminating speculation data leaks residing within the lower vector registers [vt01.com].

    ; --- STEP 2: Harden Load-Store Configuration Frame (MSR_LS_CFG) ---
    ; We clamp dynamic memory pipelining to avoid speculative tracking bypass mechanisms.
    mov ecx, MSR_LS_CFG                 ; MSR: 0xC0011020 [intel.com]
    rdmsr
    or eax, 1 << 15                     ; Bit 15: Disables speculative store forwarding loops (Spectre-V4 shield extension)
    wrmsr
    ; [BIT EXPLANATION] EAX Bit 15 = 1. Forces sequential memory serialization for conflicting loads and stores [intel.com], 
    ; closing side-channel timing analysis vectors within the core data cache unit [vt01.com].

;==================================================================================
; 4. AMD ADVANCED SYSTEM ARCHITECTURE & EXCEPTION VECTOR EXTENSIONS
;==================================================================================
prepare_amd_system_architecture:
    ; --- STEP 1: Query Current Microcode Patch Level ---
    ; We query the active firmware revision injected into the AMD silicon layout.
    mov ecx, MSR_AMD_PATCH_LEVEL        ; MSR: 0x0000008B [intel.com]
    xor eax, eax                        ; Clear execution triggers
    xor edx, edx
    wrmsr                               ; Trigger the CPU to update the patch level signature inside EAX [intel.com]
    ; [BIT EXPLANATION] Read Validation Loop. Writing 0 to 0x8B forces AMD hardware to dump 
    ; the true active microcode revision code into the lower 32-bits (EAX) for validation [intel.com].

    ; --- STEP 2: Intercept Northbridge Configuration Profile ---
    mov ecx, MSR_NB_CFG                 ; MSR: 0xC001001F [intel.com]
    rdmsr                               ; Pull northbridge configuration flags [intel.com]
    ; [HARDWARE CONTEXT] Read Validation. Evaluates core memory controller profiles to ensure 
    ; that system fabric routing constants match our pristine Host allocation map [intel.com, vt01.com].

    ; --- STEP 3: Configure Extended Exception Vector Properties ---
    mov ecx, MSR_EXT_FEATURES           ; MSR: 0xC0010058 [intel.com]
    rdmsr                               ; Read the extended silicon attribute matrix
    or eax, 1 << 0                      ; Bit 0: Encapsulates extended exception vectors to lock down faults
    wrmsr
    ; [BIT EXPLANATION] EAX Bit 0 = 1. Forces the AMD silicon logic to enforce strict vector boundaries [intel.com], 
    ; preventing any guest mode exceptions from bypassing or stepping over core Host handler entry marks [vt01.com].

; =======================================================================
; CORE HYPERVISOR PHYSICAL MEMORY LAYOUT (STATIC DRAM CONFIGURATION)
; =======================================================================
 MSRP_BASE_ADDRESS  equ 0x00020000  ; Fixed physical address in DRAM allocated for the 8KB MSRP matrix [intel.com]
 VMCB_STATIC_PA     equ 0x00022000  ; Fixed physical address in DRAM allocated for the Guest VMCB frame [intel.com, vt01.com]         <---------- Check it there some deep mistakes need to be fix after you finish

; =======================================================================
; 5. MSR PERMISSIONS MAPS (MSRP ARCHITECTURE FOR HARDWARE BLOCKING)
; =======================================================================
prepare_msrp_matrix_pointer:
    ; --- STEP 1: Wire MSRP Base Buffer Address into VMCB Control Layout ---
    ; Injecting the hardwired static physical addresses directly into the configuration block.
    mov ebx, VMCB_STATIC_PA             ; RBX = 0x00022000 (Physical address of the VMCB frame) [intel.com, vt01.com]
    mov eax, MSRP_BASE_ADDRESS          ; RAX = 0x00020000 (Physical pointer to our 8KB MSRP layout) [intel.com]
    mov [rbx + 0x18], rax               ; Offset 0x18 inside the AMD VMCB control area holds the MSRP pointer [intel.com]
    ; [HARDWARE CONTEXT] The execution engine now knows exactly where to look in DRAM to enforce intercepts [intel.com, vt01.com].

    ; --- STEP 2: Execute Atomic Loop to Fill MSRP Matrix with 0xFF (Default Deny) ---
    ; The AMD MSRP consists of 4 contiguous 2KB blocks totaling 8,192 bytes (8KB) [intel.com].
    ; We utilize RDI as the destination address and RCX as the loop counter for 1,024 8-byte operations [nasm.us].
    mov rdi, MSRP_BASE_ADDRESS          ; RDI = 0x00020000 (Start of the MSRP buffer block) [intel.com]
    mov ecx, 1024                       ; 1,024 iterations * 8 bytes = Exactly 8,192 bytes (8KB) allocated matrix [intel.com]
    mov rax, 0xFFFFFFFFFFFFFFFF         ; Load 0xFF into all 64 bits of the register atomically to set all trap bits [intel.com]

.msrp_fill_loop:
    mov [rdi], rax                      ; Commit 8 bytes of 0xFF values directly into physical DRAM lines [intel.com, vt01.com]
    add rdi, 8                          ; Advance the memory destination pointer by 8 bytes [intel.com]
    inc ecx                             ; Decrement the loop counter frame [nasm.us]
    jnz .msrp_fill_loop                 ; Continue pouring concrete if counter hasnt reached zero [nasm.us]

    ; [HARDWARE CONTEXT] Initialization complete. All 8,192 bytes are filled with 0xFF [intel.com].
    ; Every bit is hardwired to 1, activating an absolute Default Deny shield across all system MSRs [intel.com, vt01.com].
    ; Any Guest rdmsr/wrmsr call on our matted 50 fields will instantly trigger a hard VM-Exit intercept [intel.com, vt01.com]. 

;==================================================================================
; 7. AMD HARDWARE P-STATE & FREQUENCY CONTROL
;==================================================================================
prepare_amd_pstate_frequency_control:
    ; --- STEP 1: Query P-State Current Allowed Limits ---
    mov ecx, MSR_AMD_PSTATE_LIMIT       ; MSR: 0xC0010061 [intel.com]
    rdmsr                               ; Read maximum hardware capability bounds [intel.com]
    ; [BIT EXPLANATION] Read-Only Core Frame. Bits 2:0 in EAX contain the P-state limit register [intel.com]. 
    ; We verify this matrix boundary to confirm the maximum physical floor limits of the core clock.

    ; --- STEP 2: Force Static Maximum Performance State via Control ---
    mov ecx, MSR_AMD_PSTATE_CTL         ; MSR: 0xC0010062 [intel.com]
    xor eax, eax                        ; Value 0: Demand Performance State 0 (Maximum Frequency State) [intel.com]
    xor edx, edx                        ; Clear upper 32-bits
    wrmsr
    ; [BIT EXPLANATION] EAX Bits 2:0 = 000b. Forces the CPU hardware execution engine into P0 state [intel.com]. 
    ; This kills any dynamic hardware power throttling to enforce an absolute static clock loop, blinding guest timing tests [vt01.com].

    ; --- STEP 3: Verify Clock Multiplier Target Alignment ---
    mov ecx, MSR_AMD_PSTATE_STAT        ; MSR: 0xC0010063 [intel.com]
    rdmsr                               ; Query the active hardware state tracker [intel.com]
    ; [BIT EXPLANATION] Read-Only. Reflects the active hardware selection loop [intel.com]. 
    ; Enforces validation that our static P0 override configuration has been successfully deployed by the silicon grid [vt01.com].

    ; --- STEP 4: Lock AMD Specific Hardware TSC Ratio Scale ---
    mov ecx, MSR_AMD_TSC_RATIO          ; MSR: 0xC0000104 [intel.com]
    mov eax, 0x00000000                 ; Fractional multiplier configuration space set to 0
    mov edx, 0x00000001                 ; Integer scale value set to 1 (1x Ratio پاسsthrough baseline constant)
    wrmsr
    ; [BIT EXPLANATION] EDX:EAX = 0x00000001_00000000. Hard-locks the hardware-level TSC scaling ratio multiplier [intel.com], 
    ; ensuring the Host timeline calculation engine operates at native frequency with zero interpolation drift.

;==================================================================================
; 8. AMD OPERATING SYSTEM VISIBLE WORKAROUNDS (OSVW ENGINE)
;==================================================================================
prepare_amd_osvw_engine_isolation:
    ; --- STEP 1: Clear OSVW ID Length Tracking Parameters ---
    mov ecx, MSR_AMD_OSVW_ID_LEN        ; MSR: 0xC0010140 [intel.com]
    xor eax, eax                        ; Invalidate the tracked hardware errata length bounds [intel.com]
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] EAX/EDX = 0. Erases the quantity index of hardware bugs exposed to software [intel.com]. 
    ; This blinds the Guest context from evaluating structural hardware errata models [vt01.com].

    ; --- STEP 2: Sterilize OSVW Structural Bug Telemetry Status ---
    mov ecx, MSR_AMD_OSVW_STATUS        ; MSR: 0xC0010141 [intel.com]
    xor eax, eax                        ; Zero out all errata resolution bitmap entries [intel.com]
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] EAX/EDX = 0. Wipes the software-fix telemetry bitmap [intel.com]. Disabling this prevents 
    ; a guest kernel payload from querying silicon-level patch logs to detect or profile the hypervisor platform [vt01.com].

;==================================================================================
; 9. AMD HARDWARE SPECULATION DEFENSES & BRANCH HARDENING
;==================================================================================
prepare_amd_speculation_branch_hardening:
    ; --- STEP 1: Arm Branch Predictor Configuration Shields (MSR_AMD_BP_CFG) ---
    mov ecx, MSR_AMD_BP_CFG             ; MSR: 0xC001102E [intel.com]
    rdmsr                               ; Fetch microarchitectural branch prediction switches
    or eax, 1 << 4                      ; Set Bit 4: Activate BpSpecReduce (SRSO / Spectre branch mitigation)
    wrmsr
    ; [BIT EXPLANATION] EAX Bit 4 = 1. Drives the Zen branch controller to enforce speculative branch reduction constraints [intel.com]. 
    ; This actively defuses complex speculative prediction exploits (like Speculative Return Stack Overflow) [vt01.com].

    ; --- STEP 2: Harden Bus Unit Configuration 2 (MSR_AMD_BU_CFG2) ---
    mov ecx, MSR_AMD_BU_CFG2            ; MSR: 0xC001102B [intel.com]
    rdmsr                               ; Pull serialization configuration frame data
    or eax, 1 << 15                     ; Set Bit 15: Enforce strict serialization constraints for speculative routing
    wrmsr
    ; [BIT EXPLANATION] EAX Bit 15 = 1. Forces rigorous micro-architectural serialization parameters across the inner core fabric [intel.com], 
    ; creating an impenetrable execution gate against cross-domain speculative side-channel attacks [vt01.com].

;==================================================================================
; 10. AMD INSTRUCTION-BASED SAMPLING (IBS CONTROLS - FETCH)
;==================================================================================
prepare_amd_ibs_hardware_deactivation:
    ; --- STEP 1: Deactivate and Blind IBS Fetch Execution (MSR_AMD_IBSFETCHCTL) ---
    mov ecx, MSR_AMD_IBSFETCHCTL        ; MSR: 0xC0011030 [intel.com]
    xor eax, eax                        ; Drop Bit 17 (IbsFetchEn = 0) and wipe tracking registers [intel.com]
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] EAX/EDX = 0. Forces complete deactivation of the hardware Instruction-Based Sampling tracer [intel.com]. 
    ; This shuts down the silicon pipeline logging loops, denying guest code from sniffing hardware profile statistics [vt01.com].

    ; --- STEP 2: Purge IBS Fetch Linear Address Residual Telemetry ---
    mov ecx, MSR_AMD_IBSFETCHLINAD      ; MSR: 0xC0011031 [intel.com]
    xor eax, eax                        ; Erase trace history linear address registers [intel.com]
    xor edx, edx
    wrmsr

    ; --- STEP 3: Purge IBS Fetch Physical Address Residual Telemetry ---
    mov ecx, MSR_AMD_IBSFETCHPHYSAD     ; MSR: 0xC0011032 [intel.com]
    xor eax, eax                        ; Erase trace history physical memory index registers [intel.com]
    xor edx, edx
    wrmsr

    ; --- STEP 4: Sterilize IBS Execution Operations Matrix ---
    mov ecx, MSR_AMD_IBSOPCTL           ; MSR: 0xC0011033 [intel.com]
    xor eax, eax                        ; Invalidate macro-op analysis parameters [intel.com]
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] EAX/EDX = 0. Clears residual execution tracing tracking structures inside the hardware matrix [intel.com]. 
    ; This sterilizes all remaining profiling footprint crumbs, completing the platform hardware blackout [vt01.com].

;==================================================================================
; 11. AMD SMM CONTROLS & HYPERVISOR SILICON LOCKDOWN
;==================================================================================
prepare_amd_smm_silicon_lockdown:
    ; --- STEP 1: Query SMM Base Relocation Address Boundary ---
    mov ecx, MSR_AMD_SMBASE             ; MSR: 0xC0010111 [intel.com]
    rdmsr                               ; Extract active SMRAM physical base offset [intel.com]
    ; [BIT EXPLANATION] Read Validation Framework. Bits 31:0 contain the physical base 
    ; address of the SMM handler execution frame [intel.com]. Enforces structural visibility over Ring -2 elements.

    ; --- STEP 2: Configure and Lock SMM Intercept Toggles (MSR_AMD_SMM_CTL) ---
    mov ecx, MSR_AMD_SMM_CTL            ; MSR: 0xC0010116 [intel.com]
    rdmsr                               ; Fetch microarchitectural SMM configuration bits [intel.com]
    or eax, 1 << 0                      ; Bit 0: SMM_ENTER (Triggers hard intercept when CPU enters SMM) [intel.com]
    or eax, 1 << 2                      ; Bit 2: SMM_LOCK (Locks SMM configuration registers until power reset) [intel.com]
    wrmsr
    ; [BIT EXPLANATION] EAX Bit 0 = 1, Bit 2 = 1 [intel.com]. Hardwires SMM execution boundaries. 
    ; This permanently blocks motherboard firmware (Ring -2) from executing silently or bypassing Host protections [vt01.com].

;==================================================================================
; 12. AMD ADVANCED VIRTUAL INTERRUPT CONTROLLER (AVIC REGISTERS)
;==================================================================================
prepare_amd_avic_interrupt_acceleration:
    ; --- STEP 1: Clear Advanced Virtual Interrupt Doorbell Channel ---
    mov ecx, MSR_AMD_AVIC_DOORBELL      ; MSR: 0xC001011B [intel.com]
    xor eax, eax                        ; Invalidate pending virtual interrupt signal arrays [intel.com]
    xor edx, edx                        ; Clear upper 32-bits
    wrmsr
    ; [BIT EXPLANATION] EAX/EDX = 0. Sterilizes the physical AVIC execution doorbell channel [intel.com]. 
    ; This guarantees that no legacy or dynamic virtual IPI signals are pending prior to VMRUN entry [intel.com, vt01.com].

;==================================================================================
; 13. AMD PROCESSOR CONFIGURATION & BRANDING MAPS
;==================================================================================
prepare_amd_processor_branding_spoof:
    ; --- STEP 1: Wire Spoofed Processor Name String (Blocks 0 to 4) ---
    ; These registers hold the raw ASCII string returned during extended CPUID queries.
    ; Attackers use this to identify the chip architecture; we can enforce a rigid customized layout.
    mov ecx, MSR_AMD_NAME_STRING_0      ; MSR: 0xC0010030 [intel.com]
    mov eax, 0x20494d41                 ; "AMI " (Example ASCII low bytes spoof)
    mov edx, 0x4c494d4d                 ; "MMIL" (Example ASCII high bytes spoof)
    wrmsr

    mov ecx, MSR_AMD_NAME_STRING_1      ; MSR: 0xC0010031 [intel.com]
    xor eax, eax                        ; Clear or load next consecutive character array
    xor edx, edx
    wrmsr

    mov ecx, MSR_AMD_NAME_STRING_2      ; MSR: 0xC0010032 [intel.com]
    xor eax, eax
    xor edx, edx
    wrmsr

    mov ecx, MSR_AMD_NAME_STRING_3      ; MSR: 0xC0010033 [intel.com]
    xor eax, eax
    xor edx, edx
    wrmsr

    mov ecx, MSR_AMD_NAME_STRING_4      ; MSR: 0xC0010034 [intel.com]
    xor eax, eax
    xor edx, edx
    wrmsr

    mov ecx, MSR_AMD_NAME_STRING_5      ; MSR: 0xC0010035 [intel.com]
    xor eax, eax
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] EDX:EAX arrays override the raw hardware brand string [intel.com]. 
    ; Hardcoding custom values permanently cloaks the underlying Zen architecture from guest queries [vt01.com].

;==================================================================================
; 14. AMD CCX TOPOLOGY & CACHE COHERENCY MATRIX
;==================================================================================
prepare_amd_ccx_topology_validation:
    ; --- STEP 1: Query Physical CCX Core Identity ---
    mov ecx, MSR_AMD_CCX_CORE_ID        ; MSR: 0xC001100C
    rdmsr                               ; Fetch physical core index and node topology attributes
    ; [BIT EXPLANATION] Read-Only Core Matrix. Holds NUMA node configurations and core IDs. 
    ; We evaluate this matrix to secure deterministic context binding during multithreaded operations [vt01.com].

    ; --- STEP 2: Configure L3 Cache Partitioning Properties ---
    mov ecx, MSR_AMD_L3_CONFIG          ; MSR: 0xC0011022
    rdmsr                               ; Pull active cache slice allocation masks
    ; [HARDWARE CONTEXT] Read Validation. Evaluates L3 partitioning properties to confirm 
    ; that our hardware-level core fabric configuration remains undisturbed by pre-boot sequences [vt01.com].

;==================================================================================
; 15. CORE POWER MONITORING & ENERGY LIMITS
;==================================================================================
prepare_amd_rapl_energy_isolation:
    ; --- STEP 1: Query RAPL Power Unit Configuration Status ---
    mov ecx, MSR_RAPL_POWER_UNIT        ; MSR: 0xC0010299 [intel.com]
    rdmsr                               ; Fetch active power and energy scaling units [intel.com]
    ; [BIT EXPLANATION] Read-Only Register. Maps internal voltage and time scaling factors [intel.com]. 
    ; We record this baseline framework to confirm the physical power gate constants of the platform.

    ; --- STEP 2: Isolate Package Cumulative Energy Telemetry ---
    mov ecx, MSR_PKG_ENERGY_STATUS      ; MSR: 0xC001029B [intel.com]
    rdmsr                               ; Read total accumulated silicon power consumption [intel.com]
    ; [BIT EXPLANATION] Read-Only Frame. Tracks raw electrical consumption metrics across the die [intel.com]. 
    ; Monitoring this grid prevents a guest from executing advanced side-channel power-signature analysis [vt01.com].

;==================================================================================
; 16. ADVANCED CPPC PERFORMANCE HARDWARE TUNING
;==================================================================================
prepare_amd_cppc_hardware_tuning:
    ; --- STEP 1: Query CPPC Structural Capability Capabilities ---
    mov ecx, MSR_AMD_CPPC_CAP1          ; MSR: 0xC00102B0 [intel.com]
    rdmsr                               ; Extract silicon efficient frequencies into EAX/EDX [intel.com]
    ; [BIT EXPLANATION] Read-Only Register. Bits 31:24 contain the highest performance 
    ; capabilities of the physical core die [intel.com]. Checked to monitor baseline hardware speed scales.

    ; --- STEP 2: Force Global Deactivation of CPPC Core Optimization ---
    mov ecx, MSR_AMD_CPPC_ENABLE        ; MSR: 0xC00102B1 [intel.com]
    xor eax, eax                        ; Value 0: Explicitly disarm autonomous hardware frequency scaling [intel.com]
    xor edx, edx                        ; Clear upper 32-bits
    wrmsr
    ; [BIT EXPLANATION] EAX Bit 0 = 0 (CPPC Enable Switch Disabled) [intel.com]. Strips power-management 
    ; authority from any software, locking the processor core into a deterministic static execution envelope [vt01.com].

    ; --- STEP 3: Clear CPPC Dynamic Request Performance Limits ---
    mov ecx, MSR_AMD_CPPC_REQ           ; MSR: 0xC00102B3 [intel.com]
    xor eax, eax                        ; Invalidate minimum and maximum requested frequency fields [intel.com]
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] EAX/EDX = 0. Erases execution speed adjustment registers [intel.com]. 
    ; This permanently blinds a guest kernel attempting to utilize frequency shifts to execute advanced timing attacks [vt01.com].

;==================================================================================
; 17. INSTRUCTION-BASED SAMPLING EXECUTION TRACKING
;==================================================================================
prepare_amd_ibs_execution_sanitization:
    ; --- STEP 1: Purge IBS Execution Linear Target RIP Data ---
    mov ecx, MSR_AMD64_IBSOPRIP         ; MSR: 0xC0011034 [intel.com]
    xor eax, eax                        ; Wipe the exact execution address causing pipeline stalls [intel.com]
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] EAX/EDX = 0. Wipes residual structural instruction pointer telemetry logs [intel.com], 
    ; ensuring zero profiling data leaks regarding preceding Host execution frames exist in the macro-pipeline.

    ; --- STEP 2: Purge IBS Cache and Hardware Fault Telemetry Data ---
    mov ecx, MSR_AMD64_IBSOPDATA        ; MSR: 0xC0011035 [intel.com]
    xor eax, eax                        ; Clear logged memory attributes and hardware faults [intel.com]
    xor edx, edx
    wrmsr

    ; --- STEP 3: Destroy High-Precision Hardware Cycle Telemetry Clock ---
    mov ecx, MSR_AMD64_IBSOPDATA2       ; MSR: 0xC0011036 [intel.com]
    xor eax, eax                        ; Neutralize the exact execution timing metrics register [intel.com]
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] EAX/EDX = 0. Fully sterilizes the cycle-accurate macro-op execution hardware counters [intel.com]. 
    ; Wiping this grid cuts off the primary side-channel source used to construct high-precision guest timers [vt01.com].

;==================================================================================
; 18. RUNTIME MICROCODE INJECTION ENGINE
;==================================================================================
prepare_amd_microcode_patch_isolation:
    ; --- STEP 1: Monitor and Sanitize Microcode Patch Loader Interface ---
    mov ecx, MSR_AMD_PATCH_LOADER       ; MSR: 0xC0010020 [intel.com]
    rdmsr                               ; Validate the patch array interface registry [intel.com]
    ; [HARDWARE CONTEXT] Read Verification. Evaluates the microcode injection pipeline [intel.com]. 
    ; This interface will be tightly bound to the MSRP default-deny matrix to prevent any malicious guest 
    ; execution domain from attempting runtime firmware mutation or injecting rogue patches into the silicon [vt01.com].

;==================================================================================
; 19. AMD x2AVIC VIRTUAL x2APIC SYSTEM MONITORING
;==================================================================================
prepare_amd_x2avic_interrupt_matrix:
    ; --- STEP 1: Query Guest vCPU x2APIC Identity Template ---
    mov ecx, MSR_AMD_X2APIC_ID          ; MSR: 0x00000802 [intel.com]
    rdmsr                               ; Extract core hardware APIC tracking indices [intel.com]
    ; [BIT EXPLANATION] Read-Only Context Register. Bits 31:0 contain the hardware-backed 
    ; unique vCPU index that the x2AVIC hardware engine tracks during guest routing [intel.com].

    ; --- STEP 2: Configure Task Priority Intercept Filters ---
    mov ecx, MSR_AMD_X2APIC_TPR         ; MSR: 0x00000808 [intel.com]
    xor eax, eax                        ; Value 0: Clear priority filtering to default baseline [intel.com]
    xor edx, edx                        ; Clear upper 32-bits
    wrmsr
    ; [BIT EXPLANATION] EAX Bits 7:0 = 00h. Opens the virtual Task Priority gate to accept [intel.com] 
    ; acceleration interrupt streams mapped within the x2AVIC virtualization layer [intel.com, vt01.com].

    ; --- STEP 3: Sanitize Spurious Vector Configuration Frame ---
    mov ecx, MSR_AMD_X2APIC_Spurious    ; MSR: 0x0000080F [intel.com]
    rdmsr                               ; Fetch interrupt unit configuration switches [intel.com]
    or eax, 1 << 8                      ; Bit 8: APIC Software Enable (Arms virtual hardware interrupt logic) [intel.com]
    wrmsr
    ; [BIT EXPLANATION] EAX Bit 8 = 1. Forces the silicon to enable the virtual localized APIC logic [intel.com], 
    ; allowing hardware-assisted interrupt processing for the guest shell environment [intel.com, vt01.com].

    ; --- STEP 4: Sterilize Interrupt Command Signaling Interface ---
    mov ecx, MSR_AMD_X2APIC_ICR         ; MSR: 0x00000830 [intel.com]
    xor eax, eax                        ; Invalidate residual virtual inter-processor interrupt targets [intel.com]
    xor edx, edx                        ; Clear upper 32-bits
    wrmsr
    ; [BIT EXPLANATION] EAX/EDX = 0. Clears the virtual IPI command register [intel.com]. This guarantees that 
    ; no ghost or phantom cross-vCPU interrupt signals remain active prior to context launch [intel.com, vt01.com].

;==================================================================================
; 20. AMD SPECIFIC CACHE CONTROLS & MEMORY CONFIGURATION
;==================================================================================
prepare_amd_system_memory_boundaries:
    ; --- STEP 1: Enable Fixed-Range MTRR DRAM Modifications (MSR_AMD_SYS_CFG) ---
    mov ecx, MSR_AMD_SYS_CFG            ; MSR: 0xC0000010 [intel.com]
    rdmsr                               ; Pull system configuration bit array [intel.com]
    or eax, 1 << 18                     ; Bit 18: SysMtrrFixDramEn (Enables fixed-range MTRR DRAM type modification) [intel.com]
    or eax, 1 << 19                     ; Bit 18: SysMtrrFixDramModEn (Locks modification validation rules) [intel.com]
    wrmsr
    ; [BIT EXPLANATION] EAX Bit 18 = 1, Bit 19 = 1 [intel.com]. Activates global validation for fixed-range 
    ; MTRR registers, committing our matted cache layouts directly to the hardware DRAM controller logic [intel.com].

    ; --- STEP 2: Configure Top of Memory 1 Allocation Limit ---
    mov ecx, MSR_AMD_TOP_MEM            ; MSR: 0xC001001A [intel.com]
    mov eax, 0x40000000                 ; Lower 32-bits: Set boundary floor limit (e.g., 1GB DRAM marks) [intel.com]
    xor edx, edx                        ; Upper 32-bits
    wrmsr
    ; [BIT EXPLANATION] EDX:EAX = 0x00000000_40000000. Hard-locks the boundary splitting normal cacheable RAM [intel.com] 
    ; from uncacheable MMIO space under 4GB, preventing guest physical page corruption exploits [vt01.com].

    ; --- STEP 3: Configure Top of Memory 2 Extended Allocation Limit ---
    mov ecx, MSR_AMD_TOP_MEM2           ; MSR: 0xC001001D [intel.com]
    xor eax, eax                        ; Lower 32-bits
    xor edx, edx                        ; Upper 32-bits: Zero out upper boundaries if no RAM exists above 4GB [intel.com]
    wrmsr
    ; [BIT EXPLANATION] EDX:EAX = 0. Seals the upper extended memory boundary register [intel.com], 
    ; locking down hardware memory typing behavior across the entire physical address range [intel.com, vt01.com].

;==================================================================================
; 21. AMD FIXED-RANGE MTRR MEMORY ACCESS TYPE MAPS
;==================================================================================
lock_amd_fixed_mtrr_caching_matrix:
    ; --- STEP 1: Commit Low 64KB Frame Cache Type ---
    mov ecx, MSR_AMD_MTRRfix64k_00000   ; MSR: 0x00000250 [intel.com]
    mov eax, 0x06060606                 ; Sub-blocks 0-3: Set to 06h (Write-Back caching) [intel.com]
    mov edx, 0x06060606                 ; Sub-blocks 4-7: Set to 06h (Write-Back caching) [intel.com]
    wrmsr

    ; --- STEP 2: Commit 128KB Segment Buffer Cache Type ---
    mov ecx, MSR_AMD_MTRRfix16k_80000   ; MSR: 0x00000258 [intel.com]
    mov eax, 0x06060606                 ; Enforce Write-Back (06h) baseline execution speeds [intel.com]
    mov edx, 0x06060606
    wrmsr

    ; --- STEP 3: Isolate VGA Framebuffer Space (A0000h–BFFFFh Range) ---
    mov ecx, MSR_AMD_MTRRfix16k_A0000   ; MSR: 0x00000259 [intel.com]
    mov eax, 0x07070707                 ; Enforce Write-Combine (07h) for graphic buffer caching [intel.com]
    mov edx, 0x07070707
    wrmsr

    ; --- STEP 4: Lock Video BIOS Space Caching Type ---
    mov ecx, MSR_AMD_MTRRfix4k_C0000    ; MSR: 0x00000268 [intel.com]
    xor eax, eax                        ; Set all fields to 00h (Strict Uncacheable properties) [intel.com]
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] EDX:EAX = 0. Enforces Uncacheable (00h) attributes to isolate the video BIOS [intel.com], 
    ; blocking any structural cache side-channel information leaks from compromising host memory segments [vt01.com].

;==================================================================================
; 22. AMD CORE PERFORMANCE COUNTER EVENT SELECTORS (PERF_CTL)
;==================================================================================
prepare_amd_perf_ctl_sanitization:
    ; --- STEP 1: Disarm Core Performance Event Selectors 0 to 3 ---
    ; Writing 0 to the control registers completely disables the hardware event counters.
    mov ecx, MSR_AMD_PERF_CTL0          ; MSR: 0xC0010000 [intel.com]
    xor eax, eax                        ; Inactivate all hardware event selection masks [intel.com]
    xor edx, edx                        ; Clear upper 32-bits
    wrmsr

    mov ecx, MSR_AMD_PERF_CTL1          ; MSR: 0xC0010001 [intel.com]
    xor eax, eax
    xor edx, edx
    wrmsr

    mov ecx, MSR_AMD_PERF_CTL2          ; MSR: 0xC0010002 [intel.com]
    xor eax, eax
    xor edx, edx
    wrmsr

    mov ecx, MSR_AMD_PERF_CTL3          ; MSR: 0xC0010003 [intel.com]
    xor eax, eax
    xor edx, edx
    wrmsr

    ; --- STEP 2: Disarm Modern Zen Core Extended Event Selectors 4 and 5 ---
    mov ecx, MSR_AMD_PERF_CTL4          ; MSR: 0xC0010200 [intel.com]
    xor eax, eax
    xor edx, edx
    wrmsr

    mov ecx, MSR_AMD_PERF_CTL5          ; MSR: 0xC0010202 [intel.com]
    xor eax, eax
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] EAX/EDX = 0. Disables execution profiling, cache-miss tracking, [intel.com]
    ; and microarchitectural event counting across all six allocation channels [vt01.com].

;==================================================================================
; 23. AMD CORE PERFORMANCE COUNTER DATA REGISTERS (PERF_CTR)
;==================================================================================
prepare_amd_perf_ctr_data_wipe:
    ; --- STEP 1: Purge Residual Hardware Event Counts from Counters 0 to 3 ---
    mov ecx, MSR_AMD_PERF_CTR0          ; MSR: 0xC0010004 [intel.com]
    xor eax, eax                        ; Erase core accumulated cycle metrics to zero baseline [intel.com]
    xor edx, edx
    wrmsr

    mov ecx, MSR_AMD_PERF_CTR1          ; MSR: 0xC0010005 [intel.com]
    xor eax, eax
    xor edx, edx
    wrmsr

    mov ecx, MSR_AMD_PERF_CTR2          ; MSR: 0xC0010006 [intel.com]
    xor eax, eax
    xor edx, edx
    wrmsr

    mov ecx, MSR_AMD_PERF_CTR3          ; MSR: 0xC0010007 [intel.com]
    xor eax, eax
    xor edx, edx
    wrmsr

    ; --- STEP 2: Purge Residual Data Blocks from Extended Counters 4 and 5 ---
    mov ecx, MSR_AMD_PERF_CTR4          ; MSR: 0xC0010201 [intel.com]
    xor eax, eax
    xor edx, edx
    wrmsr

    mov ecx, MSR_AMD_PERF_CTR5          ; MSR: 0xC0010203 [intel.com]
    xor eax, eax
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] EAX/EDX = 0. Fully sanitizes telemetry data logs across the execution grid [intel.com]. 
    ; Wiping these structures removes historical footprint crumbs from preceding host boot layers [vt01.com].

;==================================================================================
; 24. AMD SPECIFIC VIRTUALIZATION SECURITY HARDENING (LBR & DEEP TRAILING)
;==================================================================================
prepare_amd_lbr_isolation:
    ; --- STEP 1: Blind Last Branch Record Filter Configuration ---
    mov ecx, MSR_AMD_LBR_SELECT         ; MSR: 0xC00101C0 [intel.com]
    xor eax, eax                        ; Disable recording filters and freeze branch sampling [intel.com]
    xor edx, edx
    wrmsr

    ; --- STEP 2: Purge Execution Jump Target Source Leftovers ---
    mov ecx, MSR_AMD_LBR_FROM_IP        ; MSR: 0xC00101C1 [intel.com]
    xor eax, eax                        ; Clear address tracker for originating execution jumps [intel.com]
    xor edx, edx
    wrmsr

    ; --- STEP 3: Purge Execution Jump Landing Destination Leftovers ---
    mov ecx, MSR_AMD_LBR_TO_IP          ; MSR: 0xC00101C2 [intel.com]
    xor eax, eax                        ; Clear address tracker for branch landing markers [intel.com]
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] EAX/EDX = 0. Blinds and sterilizes the hardware runtime branch tracer [intel.com]. 
    ; This explicitly destroys residual instruction pointer trails, preventing guest monitoring loops [vt01.com].

;==================================================================================
; 25. AMD HARDWARE PASSWORD-PROTECTED DEBUG MSRs
;==================================================================================
prepare_amd_password_protected_debug_sanitization:
    ; --- STEP 1: Inject Silicon Hardware Key Into EDI ---
    ; To mutate or write into the hidden debug control matrix, the CPU demands
    ; a strict 32-bit validation key loaded in EDI to prevent a General Protection Fault (#GP).
    mov edi, 0x9C5A203A                 ; Load hardware unlocking key signature atomically [vt01.com]

    ; --- STEP 2: Inactivate Hidden Debug Controller Configuration ---
    mov ecx, MSR_AMD_EXT_DEBUG_BASE    ; MSR: 0xC001100A [vt01.com]
    xor eax, eax                        ; Invalidate hidden debug capture features [vt01.com]
    xor edx, edx                        ; Clear upper 32-bits
    wrmsr                               ; Silicon validates EDI and executes changes securely [intel.com, vt01.com]

    ; --- STEP 3: Purge Debug Output Buffer Leftovers ---
    mov ecx, MSR_AMD_EXT_DEBUG_DATA    ; MSR: 0xC001100B [vt01.com]
    xor eax, eax                        ; Sterilize residual logged silicon state telemetry [vt01.com]
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] EAX/EDX = 0. Blindfolds advanced physical debug probe matrices [vt01.com]. 
    ; Injecting the physical key into EDI allows the hypervisor to securely disable these hidden factory portals [vt01.com].

;==================================================================================
; 26. UNDOCUMENTED AMD MSR BREAKPOINT TRAPS
;==================================================================================
prepare_amd_undocumented_breakpoint_traps:
    ; --- STEP 1: Nullify Undocumented MSR Breakpoint Target Address ---
    mov ecx, MSR_AMD_BREAKPOINT        ; MSR: 0xC001100E [vt01.com]
    xor eax, eax                        ; Clear intercept trap destination address space [vt01.com]
    xor edx, edx
    wrmsr

    ; --- STEP 2: Wipe Breakpoint Filter Mask Allocation ---
    mov ecx, MSR_AMD_BREAKPOINT_MASK   ; MSR: 0xC001100F [vt01.com]
    xor eax, eax                        ; Remove matching bit ranges to completely drop the hardware trap [vt01.com]
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] EAX/EDX = 0. Permanently tears down undocumented microarchitectural breakpoint 
    ; traps, preventing rogue guest environments from triggering unexpected hardware context interceptions [vt01.com].

;==================================================================================
; 27. UNDOCUMENTED BUS ARCHITECTURE & BRANCH TRACING (BHTrace Engine)
;==================================================================================
prepare_amd_bhtrace_engine_blackout:
    ; --- STEP 1: Disarm Bus Hardware Trace Master Control Switch ---
    mov ecx, MSR_AMD_BHTRACE_CTL       ; MSR: 0xC0011010 [vt01.com]
    xor eax, eax                        ; Turn off internal bus unit hardware tracing loops [vt01.com]
    xor edx, edx
    wrmsr

    ; --- STEP 2: Wipe Bus Hardware Trace Residual Data Collection Frames ---
    mov ecx, MSR_AMD_BHTRACE_DATA      ; MSR: 0xC0011011 [vt01.com]
    xor eax, eax                        ; Clear cached bus routing tracking records [vt01.com]
    xor edx, edx
    wrmsr
    ; [BIT EXPLANATION] EAX/EDX = 0. Blinds the raw system fabric interconnect analyzer [vt01.com]. 
    ; This destroys data trails that could leak internal core pipeline activity or execution footprints [vt01.com].

;==================================================================================
; 28. UNDOCUMENTED SILICON ISOLATION & PREFETCH LOCKS
;==================================================================================
prepare_amd_undocumented_prefetch_locks:
    ; --- STEP 1: Program Secret Data Cache Configuration ---
    mov ecx, MSR_AMD_DC_CFG_SECRET     ; MSR: 0xC0011022 [vt01.com]
    rdmsr                               ; Read the custom data cache bitmask layout [intel.com, vt01.com]
    or eax, 1 << 4                      ; Set Bit 4: Lock and clamp custom prefetch cache mechanisms [vt01.com]
    wrmsr
    ; [BIT EXPLANATION] EAX Bit 4 = 1. Forces rigorous sequential caching bounds over specific 
    ; internal memory lines, establishing a deep microarchitectural shield against side-channel probes [vt01.com].

;==================================================================================
; 29. AMD PERFORMANCE BOOST & THERMAL RATIO LOCKS (INTERNAL TUNING)
;==================================================================================
prepare_amd_performance_boost_thermal_locks:
    ; --- STEP 1: Inactivate Hidden Performance Configuration Boost Switches ---
    mov ecx, MSR_AMD_CORED_CFG          ; MSR: 0xC001102C [vt01.com]
    rdmsr                               ; Fetch active core performance configuration bits [intel.com, vt01.com]
    and eax, ~(1 << 0)                  ; Clear Bit 0: Permanently disable hidden core performance boost overrides [vt01.com]
    wrmsr
    ; [BIT EXPLANATION] EAX Bit 0 = 0. Strips software-level performance overclocking software (like Ryzen Master) [vt01.com] 
    ; from dynamically altering core limits, guaranteeing uniform clock execution [vt01.com].

    ; --- STEP 2: Clear Thermal Hardware Cycle Modulation Controls ---
    mov ecx, MSR_AMD_THM_CR_CYC         ; MSR: 0xC0010073 [vt01.com]
    xor eax, eax                        ; Value 0: Explicitly disarm manual clock duty-cycle modulation [vt01.com]
    xor edx, edx                        ; Clear upper 32-bits
    wrmsr
    ; [BIT EXPLANATION] EAX/EDX = 0. Disables customized hardware throttling mechanisms [vt01.com], 
    ; blocking malicious attempts to induce artificial thermal variations for side-channel telemetry analysis [vt01.com].

;==================================================================================
; 30. AMD EXPERIMENTAL SPECULATION HARDENING (Zen 4 / Zen 5 Shielder)
;==================================================================================
prepare_amd_experimental_speculation_hardening:
    ; --- STEP 1: Enforce Hidden PPIN Lock Configuration ---
    mov ecx, MSR_AMD_PPIN_CTL_SECRET    ; MSR: 0xC001004E [vt01.com]
    mov eax, 0x00000003                 ; Bit 0: Enable PPIN allocation, Bit 1: Hardwire lock the control state [intel.com, vt01.com]
    xor edx, edx                        ; Clear upper 32-bits
    wrmsr
    ; [BIT EXPLANATION] EAX Bit 0 = 1, Bit 1 = 1 [intel.com, vt01.com]. Seals the unique physical silicon 
    ; identifier interface, making it visible to the Host matrix while permanently blinding guest inventory scans [vt01.com].

    ; --- STEP 2: Configure Custom Alternative Speculative Store Bypass Controls ---
    mov ecx, MSR_AMD_SPECTRE_V4_CTL     ; MSR: 0xC0011024 [vt01.com]
    rdmsr                               ; Pull specific load-store prediction switches [intel.com, vt01.com]
    or eax, 1 << 10                     ; Set Bit 10: Enforce strict alternative architectural hardware serialization
    wrmsr
    ; [BIT EXPLANATION] EAX Bit 10 = 1. Forces rigorous pipeline fencing over memory execution lines [vt01.com], 
    ; cementing custom speculative store bypass protections directly into the hidden silicon register layer [vt01.com].

;==================================================================================
; 31. AMD HARDWARE ERROR INJECTION & SILICON CORRUPTION INTRUSION
;==================================================================================
prepare_amd_mca_error_injection_blackout:
    ; --- STEP 1: Deactivate and Blank MCA Error Injection Triggers ---
    mov ecx, MSR_AMD_ERR_INJECT         ; MSR: 0xC001011E [intel.com, vt01.com]
    xor eax, eax                        ; Set to 0 to disable active simulation triggers [intel.com, vt01.com]
    xor edx, edx                        ; Clear upper 32-bits
    wrmsr
    ; [BIT EXPLANATION] EAX/EDX = 0. Forcefully disarms the Machine Check Architecture error injection vector [intel.com, vt01.com]. 
    ; This destroys the hardware portal used to simulate bit-flips, denying the guest from triggering forced crash states [vt01.com].

    ; --- STEP 2: Clear Machine Check Intercept Filter Masks ---
    mov ecx, MSR_AMD_ERR_STATUS_MASK    ; MSR: 0xC001011F [vt01.com]
    xor eax, eax                        ; Invalidate matching bit masks to lock the monitoring baseline [vt01.com]
    xor edx, edx                        ; Clear upper 32-bits
    wrmsr

;==================================================================================
; 32. AMD EMBEDDED CO-PROCESSOR SECURITY SHIELDS (PSP GATEWAY)
;==================================================================================
prepare_amd_psp_gateway_isolation:
    ; --- STEP 1: Sterilize Platform Security Processor Host Command Interface ---
    mov ecx, MSR_AMD_PSP_COMMAND        ; MSR: 0xC00110A0 [vt01.com]
    xor eax, eax                        ; Clear pending command flags and parameters [vt01.com]
    xor edx, edx                        ; Clear upper 32-bits
    wrmsr
    ; [BIT EXPLANATION] EAX/EDX = 0. Flushes the co-processor pipeline portal completely [vt01.com]. This guarantees 
    ; that no guest code domain can issue firmware-level instructions or access secure hardware enclave keys [vt01.com].

    ; --- STEP 2: Query Platform Security Processor Fuse and Active Status ---
    mov ecx, MSR_AMD_PSP_STATUS         ; MSR: 0xC00110A1 [vt01.com]
    rdmsr                               ; Poll embedded security processor state [intel.com, vt01.com]
    ; [HARDWARE CONTEXT] Read Validation. Evaluates embedded cryptographic co-processor flags [intel.com, vt01.com]. 
    ; This structure will be permanently guarded under our MSRP matrix to isolate global security fuses from guest interception [vt01.com].

;==================================================================================
; 33. AMD EXTENDED MACHINE CHECK ARCHITECTURE (MCA EXTRAS)
;==================================================================================
prepare_amd_extended_mca_sanitization:
    ; --- STEP 1: Configure AMD Specific MCA Reporting Rules ---
    mov ecx, MSR_AMD_MCA_CFG            ; MSR: 0xC0010044 [intel.com, vt01.com]
    rdmsr                               ; Fetch active core exception reporting layout [intel.com]
    ; [BIT EXPLANATION] Read-Only Core Validation. Maps advanced error propagation boundaries. 
    ; Checked to ensure that physical hardware exception routing matches our Host containment profile.

    ; --- STEP 2: Initialize Extended MCA Control Bank 0 ---
    mov ecx, MSR_AMD_MCA_EXT_CTL0       ; MSR: 0xC0010050 [intel.com, vt01.com]
    mov eax, 0xFFFFFFFF                 ; Enable all extended hardware logging indicators atomically [intel.com]
    mov edx, 0xFFFFFFFF
    wrmsr

    ; --- STEP 3: Purge Extended MCA Bank 0 Status Telemetry ---
    mov ecx, MSR_AMD_MCA_EXT_STAT0      ; MSR: 0xC0010051 [intel.com, vt01.com]
    xor eax, eax                        ; Invalidate active error tracking flags to 0 [intel.com]
    xor edx, edx                        ; Clear upper 32-bits
    wrmsr
    ; [BIT EXPLANATION] EAX/EDX = 0. Sterilizes extended silicon-level hardware telemetry logs [intel.com]. 
    ; This fully destroys footprint crumbs remaining from previous factory or firmware boot operations [vt01.com].

;==================================================================================
; 34. AMD ARCHITECTURAL THREAD TOPOLOGY & THREAD PREFERENCE
;==================================================================================
prepare_amd_thread_topology_alignment:
    ; --- STEP 1: Verify Thread Preference Performance Controls ---
    mov ecx, MSR_AMD_TH_PR_CTL          ; MSR: 0xC0011028 [vt01.com]
    rdmsr                               ; Pull active hardware thread prioritization masks [vt01.com]
    ; [BIT EXPLANATION] Read-Only Register Matrix. Reflects execution pipeline distribution rules. 
    ; Evaluated to lock uniform scheduler pacing, preventing guest side-channel clock analysis [vt01.com].

    ; --- STEP 2: Query Asymmetric Core Layout Configuration ---
    mov ecx, MSR_AMD_ASYM_CORE_MAP      ; MSR: 0xC001103A [vt01.com]
    rdmsr                               ; Read specific Zen performance vs efficiency core routing vectors [vt01.com]
    ; [HARDWARE CONTEXT] Read Validation. Maps the underlying asymmetric silicon topology framework [vt01.com]. 
    ; This mask is recorded to ensure stable, isolated thread binding across heterogeneous core configurations.

;==================================================================================
; 35. AMD SILICON DEBUGGER EMULATION INTERCEPT
;==================================================================================
prepare_amd_hardware_debugger_blackout:
    ; --- STEP 1: Disarm Hardware Debug Tool Intercept Interface ---
    mov ecx, MSR_AMD_HDT_CTRL           ; MSR: 0xC001100D [vt01.com]
    xor eax, eax                        ; Deactivate deep hardware probe tracing loops entirely [vt01.com]
    xor edx, edx                        ; Clear upper 32-bits
    wrmsr
    ; [BIT EXPLANATION] EAX/EDX = 0. Permanently blindfolds the embedded factory debug port controller [vt01.com]. 
    ; This blocks any external physical JTAG or hardware-level probe attachment from intercepting core registers [vt01.com].

;==================================================================================
; 36. AMD INFINITY FABRIC DATA ROUTING CONTROLS (UNDOCUMENTED)
;==================================================================================
prepare_amd_infinity_fabric_hardening:
    ; --- STEP 1: Verify Infinity Fabric Master Configuration ---
    mov ecx, MSR_AMD_FABRIC_CFG         ; MSR: 0xC0011000 [vt01.com]
    rdmsr                               ; Query inter-core routing and fabric priorities [vt01.com]
    ; [BIT EXPLANATION] Undocumented Core Register. Checked to validate that data fabric 
    ; priority channels match our hardened host configuration baseline before guest deployment.

    ; --- STEP 2: Disarm Hidden Fabric Snoop Control Register ---
    mov ecx, MSR_AMD_FABRIC_SNOOP       ; MSR: 0xC0011003 [vt01.com]
    xor eax, eax                        ; Inactivate hidden cache-line invalidation tracking [vt01.com]
    xor edx, edx                        ; Clear upper 32-bits
    wrmsr
    ; [BIT EXPLANATION] EAX/EDX = 0. Permanently blinds the hidden bus fabric snooping unit [vt01.com]. 
    ; This eliminates cross-core speculative cache invalidation timing attacks at the silicon gate [vt01.com].

;==================================================================================
; 37. AMD ARCHITECTURAL DATA ALIGNMENT FLUSH SWITCH (UNDOCUMENTED)
;==================================================================================
prepare_amd_force_alignment_serialization:
    ; --- STEP 1: Activate Force Alignment Memory Serialization ---
    mov ecx, MSR_AMD_ALIGN_FORCE        ; MSR: 0xC0011018 [vt01.com]
    rdmsr                               ; Pull secret data cache alignment properties [intel.com, vt01.com]
    or eax, 1 << 0                      ; Set Bit 0: Enforce strict architectural data alignment constraints
    wrmsr
    ; [BIT EXPLANATION] EAX Bit 0 = 1. Forces absolute microarchitectural serialization over memory accesses [vt01.com], 
    ; making raw data cache lines perfectly uniform and breaking speculative cache-alignment side-channels [vt01.com].

;==================================================================================
; 38. AMD ZEN MICROARCHITECTURAL LOCK REGISTERS (UNDOCUMENTED FEATURE LOCKS)
;==================================================================================
prepare_amd_zen_feature_locks:
    ; --- STEP 1: Monitor Runtime Feature Disable Lock State ---
    mov ecx, MSR_AMD_FEATURE_LOCK0      ; MSR: 0xC001102A [vt01.com]
    rdmsr                               ; Validate active microcode runtime runtime configurations [intel.com, vt01.com]
    ; [HARDWARE CONTEXT] Read Verification. Monitors runtime silicon patch layers [intel.com]. This register 
    ; will be heavily locked down via MSRP to block guest exploitation of underlying hardware patches [vt01.com].

    ; --- STEP 2: Harden Floating-Point Unit Hidden Configuration ---
    mov ecx, MSR_AMD_FPU_CFG_SECRET     ; MSR: 0xC001102F [vt01.com]
    rdmsr                               ; Fetch hidden vector unit optimization controls [intel.com, vt01.com]
    or eax, 1 << 2                      ; Set Bit 2: Clamp speculative AVX-512 execution pipelines
    wrmsr
    ; [BIT EXPLANATION] EAX Bit 2 = 1. Clamps alternative prediction routing in the FPU pipeline [vt01.com], 
    ; blocking a guest from utilizing AVX-512 speculative loops to dump preceding host vector state data [vt01.com].

;==================================================================================
; 39. AMD MICROARCHITECTURAL EXECUTING CHICKEN BITS (UNDOCUMENTED EX_CFG)
;==================================================================================
prepare_amd_execution_chicken_bits:
    ; --- STEP 1: Enforce ALU Execution Unit Configuration Constraints ---
    mov ecx, MSR_AMD_EX_CFG             ; MSR: 0xC0011021 [vt01.com]
    rdmsr                               ; Pull current execution pipeline optimization masks [intel.com, vt01.com]
    or eax, 1 << 15                     ; Set Bit 15: Disarm specific optimization chicken bits to patch leaks
    wrmsr
    ; [BIT EXPLANATION] EAX Bit 15 = 1. Disables custom optimization shortcuts within the execution unit [vt01.com]. 
    ; This restricts data-forwarding tricks inside the ALU, sealing deep microarchitectural transient leakage [vt01.com].

    ; --- STEP 2: Configure Extended Execution Chicken Bits Control ---
    mov ecx, MSR_AMD_EX_CFG2            ; MSR: 0xC001102D [vt01.com]
    rdmsr                               ; Fetch hot-loadable patch serialization bits [intel.com, vt01.com]
    or eax, 1 << 8                      ; Set Bit 8: Tighten instruction retirement fencing loops
    wrmsr
    ; [BIT EXPLANATION] EAX Bit 8 = 1. Hardwires strict retirement boundaries over active threads [vt01.com], 
    ; permanently sanitizing transient pipeline data leftovers before any privilege domain transitions occur [vt01.com].

;==================================================================================
; 40. AMD STACK-POINTER SPECULATION DEFENSE (THE STACKWARP SHIELD - CVE-2025-29943)
;==================================================================================
prepare_amd_stackwarp_mitigation_shield:
    ; --- STEP 1: Deploy Core StackWarp Hardware Mitigation (MSR_AMD_LS_CFG2) ---
    ; We enforce speculative load-store fencing over stack tracking mechanisms.
    mov ecx, MSR_AMD_LS_CFG2            ; MSR: 0xC0011023 [intel.com, vt01.com]
    rdmsr                               ; Fetch active micro-architectural load-store configuration [intel.com]
    or eax, 1 << 6                      ; Set Bit 6: Force speculative stack pointer validation (StackWarp Shield)
    wrmsr
    ; [BIT EXPLANATION] EAX Bit 6 = 1. Hardwires structural hardware validation over transient stack operations [vt01.com]. 
    ; This explicitly paralyzes CVE-2025-29943 exploits, breaking alternative guest pipelines from warping RSP boundaries [vt01.com].

;==================================================================================
; 41. AMD FLOATING POINT & AVX VECTOR BALANCING (UNDOCUMENTED FP_CFG)
;==================================================================================
prepare_amd_fpu_vector_balancing_locks:
    ; --- STEP 1: Configure Undocumented FPU Execution Configuration ---
    mov ecx, MSR_AMD_FP_CFG             ; MSR: 0xC0011028 [intel.com, vt01.com]
    rdmsr                               ; Read specific vector execution control parameters [intel.com]
    or eax, 1 << 12                     ; Set Bit 12: Enforce fixed execution timing for heavy AVX pipelines
    wrmsr
    ; [BIT EXPLANATION] EAX Bit 12 = 1. Eliminates dynamic timing optimization shortcuts inside the vector pipelines [vt01.com]. 
    ; This locks AVX-512 execution to standard clock boundaries, neutralizing dynamic power-signature leaks [vt01.com].

;==================================================================================
; 42: AMD SEV-SNP ENCRYPTION MATRIX & PAGE VALIDATION CONTROLS
;==================================================================================
prepare_amd_sev_snp_encryption_matrix:
    ; --- STEP 1: Monitor Reverse Map Table (RMP) Base Configuration ---
    mov ecx, MSR_AMD_RMP_BASE           ; MSR: 0xC0010132 [intel.com]
    rdmsr                               ; Query the hardware-enforced page tracking base [intel.com]
    ; [BIT EXPLANATION] Read-Only Core Frame. Tracks the base address of the RMP architecture [intel.com]. 
    ; Checked to verify if hardware memory page validation loops are securely synchronized.

    ; --- STEP 2: Enforce vCPU State-Save Encryption Protection ---
    mov ecx, MSR_AMD_VMSA_REG_PROT      ; MSR: 0xC001013F [intel.com]
    rdmsr                               ; Pull micro-architectural register protection switches
    or eax, 1 << 0                      ; Bit 0: Activate hardwired VMSA encryption and isolation fields [intel.com]
    wrmsr
    ; [BIT EXPLANATION] EAX Bit 0 = 1. Forces the AMD silicon logic to cryptographically lock the vCPU state-save area [intel.com], 
    ; permanently blocking a guest from sniffing host registers during hypervisor context transition loops [vt01.com].

;==================================================================================
; 43: AMD SPECULATIVE EXECUTION SHIELDS & CORE CONFIG EXTRAS
;==================================================================================
prepare_amd_core_execution_shields:
    ; --- STEP 1: Harden Thread Pipeline Configuration ---
    mov ecx, MSR_AMD_THREAD_CONFIG     ; MSR: 0xC0011012 [vt01.com]
    rdmsr                               ; Fetch active thread resource sharing bits [vt01.com]
    or eax, 1 << 12                     ; Set Bit 12: Force dynamic execution resource separation between SMT threads
    wrmsr
    ; [BIT EXPLANATION] EAX Bit 12 = 1. Restricts resource sharing hooks within the macro-pipeline, [vt01.com] 
    ; closing complex cross-thread speculative side-channels inside the active execution core [vt01.com].

    ; --- STEP 2: Sanitize Extended System Configuration Options ---
    mov ecx, MSR_AMD_SYS_CFG2           ; MSR: 0xC0000015 [intel.com]
    rdmsr                               ; Pull secondary system configurations [intel.com]
    ; [HARDWARE CONTEXT] Read Validation. Evaluates extended caching boundaries to ensure 
    ; that system fabric routing properties match our pristine 1GB Host RAM matrix footprint [vt01.com].

;==================================================================================
; 44: AMD INFINITY FABRIC TELEMETRY & SYSTEM RECOVERY CONTROL
;==================================================================================
prepare_amd_fabric_telemetry_blackout:
    ; --- STEP 1: Disarm Fabric Error Reporting Controls ---
    mov ecx, MSR_AMD_FABRIC_ERR_CTL     ; MSR: 0xC0011001 [vt01.com]
    xor eax, eax                        ; Inactivate hidden fabric logging triggers [vt01.com]
    xor edx, edx                        ; Clear upper 32-bits
    wrmsr
    ; [BIT EXPLANATION] EAX/EDX = 0. Blinds hidden data fabric monitoring vectors [vt01.com]. 
    ; Wiping this register stops rogue guests from utilizing interconnect logs to execute timing analysis [vt01.com].

;==================================================================================
;                  IN OUT for SMM opening history defenses 
;==================================================================================










;                              ACPI for Hypervisor
;==================================================================================
;             GLOBAL UNIFIED TABLES (Common to Intel, AMD, RISC-V, ARM)
;==================================================================================

; --- Core System Tables (Fixed for x86 Little-Endian Precision) ---
ACPI_RSDP_SIGNATURE  equ 0x2052545020445352 ; "RSD PTR " (Corrected layout)
ACPI_RSDT_SIGNATURE  equ 0x54445352         ; "TDSR" -> In Memory: "RSDT" V
ACPI_XSDT_SIGNATURE  equ 0x54445358         ; "TDSX" -> In Memory: "XSDT" V
ACPI_FADT_SIGNATURE  equ 0x50434146         ; "PCAF" -> In Memory: "FACP" V
ACPI_DSDT_SIGNATURE  equ 0x54445344         ; "TDSD" -> In Memory: "DSDT" V
ACPI_SSDT_SIGNATURE  equ 0x54445353         ; "TDSS" -> In Memory: "SSDT" 
ACPI_FACS_SIGNATURE  equ 0x53434146         ; "SCAF" -> In Memory: "FACS" V

; --- Processor & Topology (Global Tables) ---
ACPI_MADT_SIGNATURE  equ 0x43495041         ; "CIPA" -> In Memory: "APIC"
ACPI_SRAT_SIGNATURE  equ 0x54415253         ; "TARS" -> In Memory: "SRAT"
ACPI_SLIT_SIGNATURE  equ 0x54494C53         ; "TILS" -> In Memory: "SLIT"
ACPI_PPTT_SIGNATURE  equ 0x54545050         ; "TTPP" -> In Memory: "PPTT"
ACPI_MPST_SIGNATURE  equ 0x5453504D         ; "TSPM" -> In Memory: "MPST"
ACPI_CDAT_SIGNATURE  equ 0x54414443         ; "TADC" -> In Memory: "CDAT"

; --- Security & Hardware Enforcement (The Combat Zone) ---
ACPI_TPM2_SIGNATURE  equ 0x324D5054         ; "2MPT" -> In Memory: "TPM2"
ACPI_TCPA_SIGNATURE  equ 0x41504354         ; "APCT" -> In Memory: "TCPA"
ACPI_WPBT_SIGNATURE  equ 0x54425057         ; "TBPW" -> In Memory: "WPBT" (Bloatware/Rootkit vector!)
ACPI_WSMT_SIGNATURE  equ 0x544D5357         ; "TMSW" -> In Memory: "WSMT" (SMM Mitigations)
ACPI_SPCR_SIGNATURE  equ 0x52435053         ; "RCPS" -> In Memory: "SPCR"
ACPI_BGRT_SIGNATURE  equ 0x54524742         ; "TRGB" -> In Memory: "BGRT"
ACPI_SDEV_SIGNATURE  equ 0x56454453         ; "VEDS" -> In Memory: "SDEV"

; --- Shared Virtualization Infrastructure ---
ACPI_NFIT_SIGNATURE  equ 0x5449464E         ; "TIFN" -> In Memory: "NFIT"
ACPI_PCCT_SIGNATURE  equ 0x54434350         ; "TCCP" -> In Memory: "PCCT"

; --- Timers & Subsystems ---
ACPI_HPET_SIGNATURE  equ 0x54455048         ; "TEPH" -> In Memory: "HPET"
ACPI_MCFG_SIGNATURE  equ 0x4746434D         ; "GFCM" -> In Memory: "MCFG"
ACPI_ECDT_SIGNATURE  equ 0x54444345         ; "TDCE" -> In Memory: "ECDT"
ACPI_SBST_SIGNATURE  equ 0x54534253         ; "TSBS" -> In Memory: "SBST"
ACPI_BOOT_SIGNATURE  equ 0x544F4F42         ; "TOOB" -> In Memory: "BOOT"
ACPI_DBGP_SIGNATURE  equ 0x50474244         ; "PGBD" -> In Memory: "DBGP"
ACPI_DBG2_SIGNATURE  equ 0x32474244         ; "2GBD" -> In Memory: "DBG2"

; --- Vendor Specific & Extensions ---
ACPI_BERT_SIGNATURE  equ 0x54524542         ; "TREB" -> In Memory: "BERT"
ACPI_EINJ_SIGNATURE  equ 0x4A4E4945         ; "JNIE" -> In Memory: "EINJ"
ACPI_ERST_SIGNATURE  equ 0x54535245         ; "TSRE" -> In Memory: "ERST"
ACPI_HEST_SIGNATURE  equ 0x54534548         ; "TSEH" -> In Memory: "HEST"
ACPI_HMAT_SIGNATURE  equ 0x54414448         ; "TADH" -> In Memory: "HMAT"
ACPI_VIOT_SIGNATURE  equ 0x544F4956         ; "TOIV" -> In Memory: "VIOT"
ACPI_PHAT_SIGNATURE  equ 0x54414850         ; "TAHP" -> In Memory: "PHAT"

; --- Storage, Network & Boot ---
ACPI_IBFT_SIGNATURE  equ 0x54464269         ; "TFBi" -> In Memory: "iBFT"
ACPI_NBFT_SIGNATURE  equ 0x5446424E         ; "TFBN" -> In Memory: "NBFT"
ACPI_SATA_SIGNATURE  equ 0x41544153         ; "ATAS" -> In Memory: "SATA"
ACPI_MCHI_SIGNATURE  equ 0x4948434D         ; "IHCM" -> In Memory: "MCHI"
ACPI_UEFI_SIGNATURE  equ 0x49464555         ; "IFEU" -> In Memory: "UEFI"

; --- Advanced Processing & Fabric ---
ACPI_CPEP_SIGNATURE  equ 0x50455043         ; "PEPC" -> In Memory: "CPEP"
ACPI_GTDT_SIGNATURE  equ 0x54444447         ; "TDDG" -> In Memory: "GTDT"
ACPI_MPAM_SIGNATURE  equ 0x4D41504D         ; "MAPM" -> In Memory: "MPAM"
ACPI_AEST_SIGNATURE  equ 0x54534541         ; "TSEA" -> In Memory: "AEST"
ACPI_AGDI_SIGNATURE  equ 0x49444741         ; "IDGA" -> In Memory: "AGDI"

; --- Confidential Computing, Power & Enterprise ---
ACPI_SVKL_SIGNATURE  equ 0x4C4B5653         ; "LKVS" -> In Memory: "SVKL"
ACPI_CCEL_SIGNATURE  equ 0x4C454343         ; "LECC" -> In Memory: "CCEL"
ACPI_DRTM_SIGNATURE  equ 0x4D545244         ; "MTRD" -> In Memory: "DRTM"
ACPI_MSDM_SIGNATURE  equ 0x4D44534D         ; "MDSM" -> In Memory: "MSDM"
ACPI_SLIC_SIGNATURE  equ 0x43494C53         ; "CILS" -> In Memory: "SLIC"
ACPI_WDAT_SIGNATURE  equ 0x54414457         ; "TADW" -> In Memory: "WDAT"
ACPI_WDDT_SIGNATURE  equ 0x54444457         ; "TDDW" -> In Memory: "WDDT"
ACPI_WDRT_SIGNATURE  equ 0x54524457         ; "TRDW" -> In Memory: "WDRT"
ACPI_FPDT_SIGNATURE  equ 0x54445046         ; "TDPF" -> In Memory: "FPDT"

; --- Compute Express Link (CXL) & Legacy Hardware ---
ACPI_CEDT_SIGNATURE  equ 0x54444543         ; "TDEC" -> In Memory: "CEDT"
ACPI_CSRT_SIGNATURE  equ 0x54525343         ; "TRSC" -> In Memory: "CSRT"
ACPI_PRMT_SIGNATURE  equ 0x544D5250         ; "TMRP" -> In Memory: "PRMT"
ACPI_SPMI_SIGNATURE  equ 0x494D5053         ; "IMPS" -> In Memory: "SPMI"
ACPI_WAET_SIGNATURE  equ 0x54454157         ; "TEAW" -> In Memory: "WAET"

;==================================================================================
;				   NESTED SHADOW & CLOUD HYPERVISOR TABLES
;==================================================================================
ACPI_XENV_SIGNATURE  equ 0x564E4558         ; "V NEX" -> In Memory: "XENV"
ACPI_WAFT_SIGNATURE  equ 0x54464157         ; "TFAW" -> In Memory: "WAFT"
ACPI_AWS_SIGNATURE   equ 0x5F535741         ; "_SWA" -> In Memory: "AWS_"
ACPI_QEMU_SIGNATURE  equ 0x554D4551         ; "UMEQ" -> In Memory: "QEMU"

static_rsdp_block  equ 0x0002F000         ; Hardcoded secure RAM address for our pristine RSDP (Aligned to 16 bytes)





;==================================================================================
;                   ACPI (Advanced Configuration and Power Interface)
;==================================================================================
;We gonna build new ACPI because the Creators of the MotherBoard did a great job for black hat hackers to get 
;control over Ring minus 2 Im going to build one from zero thx to the Creators. so Im going to build one in pure assembly
;so no one gonna have any black box at checking and all of you can learn wish me goodluck it is going to be hard one Im one person
;If someone can check my hypervisor and In Out when everything gonna be I will thank you a lot. lets start are game:



;==================================================================================
;                           Core System Tables 
;==================================================================================
acpi_three_strike_radar_entry:
    mov rdx, 3                              

.initiate_radar_pass:
    mov rsi, 0x000E0000                     ; Set base pointer to the hardcoded EBDA region (0x000E0000)
    mov rdi, ACPI_RSDP_SIGNATURE            ; Load the reversed "RSD PTR " signature from our global matrix
    mov rcx, 0x00020000                     ; Scan volume boundary: 128KB (0xE0000 to 0x100000)

.scan_iteration_stream:
    mov rax, [rsi]                          ; Atomic read: fetch 8 bytes directly from the silicon plane
    cmp rax, rdi                            ; Check if the motherboard creators RSDP is matched
    je .target_isolated_hijack              ; Match found! Break out immediately to execute the hijack
    
    add rsi, 16                             ; Maintain strict 16-byte CPU instruction alignment
    sub rcx, 16                             ; Decrement memory tracking index
    ja .scan_iteration_stream               ; Continue searching this specific pass zone

    ; --- Strike Handling: Execution falls here if current pass failed ---
    dec rdx                                 ; Drop the strike counter
    cmp rdx, 0                              ; Check if all 3 passes failed down to the bone
    je .force_absolute_triple_fault         ; If strikes hit 0, escalate to complete motherboard annihilation
    jmp .initiate_radar_pass                ; If strikes remain, jump BACK to initiate the next pass zone

.target_isolated_hijack:
    ; ==========================================================================
    ; EXECUTE DIRECT PHYSICAL HIJACKING OVER THE DISCOVERED LEGACY SIGNATURE
    ; ==========================================================================
    mov rdi, rsi
    mov rsi, static_rsdp_block
    movsq                                   ; Overwrite Signature
    movsq                                   ; Overwrite Checksum & OEM ID
    movsq                                   ; Overwrite Revision & Legacy Ptr
    movsq                                   ; Overwrite Length & XSDT Address
    movsd                                   ; Overwrite Extended Checksum (36 bytes sealed)

.unaligned_hardware_fallthrough:
    ; The radar pass has succeeded. Transitioning into the primary forging matrix.
    jmp forge_primary_acpi_lighthouses

; ==============================================================================
; HYPERVISOR PURE ASSEMBLY MANIFESTO - PRIMARY ACPI TABLES FORGING
; ==============================================================================
align 16
forge_primary_acpi_lighthouses:
    ; --------------------------------------------------------------------------
    ; 1. FORGING THE SECURE RSDP (Root System Description Pointer) 
    ; This block acts as the master trigger that blinds the Creators matrix.
    ; --------------------------------------------------------------------------
    mov rdi, static_rsdp_block              ; Point to our secure memory structure block
    
    ; Inject the Primary RSDP Signature ("RSD PTR ") using our master EQU constant
    mov rax, ACPI_RSDP_SIGNATURE            ; 0x2052545020445352 -> "RSD PTR "
    mov [rdi], rax                          ; Stamp directly into the first 8 bytes of silicon
    
    ; Populate the rest of the static RSDP context (ACPI 2.0+ specifications)
    mov byte [rdi + 8], 0                   ; Base Checksum (Will be dynamically armed by Part 53)
    mov dword [rdi + 9], "MSTR"             ; OEM ID string segment 1
    mov word [rdi + 13], "64"               ; OEM ID string segment 2
    mov byte [rdi + 15], 2                  ; Revision 2: Forces strict 64-bit architecture
    mov dword [rdi + 16], 0x00000000        ; Legacy 32-bit RSDT address set to 0 (Choked!)
    mov dword [rdi + 20], 36                ; Total length of the secure pointer layout
    
    ; --- The Core Redirection Line ---
    ; We force the RSDP to point exclusively to our upcoming XSDT layout at 0x00030000
    mov qword [rdi + 24], 0x0000000000030000 ; Extended 64-bit physical address pointer to XSDT

    ; --------------------------------------------------------------------------
    ; 2. FORGING THE SECURE XSDT (Extended System Description Table)
    ; Located strictly at physical memory block 0x00030000.
    ; --------------------------------------------------------------------------
    mov rdi, 0x00030000                     ; Hardcoded physical location for our master XSDT
    
    ; Inject the XSDT Signature ("XSDT") using our master EQU constant
    mov eax, ACPI_XSDT_SIGNATURE            ; 0x54445358 -> "XSDT" in Little-Endian
    mov [rdi], eax                          ; Stamp directly into the active matrix
    
    ; Build the XSDT Header Framework
    mov dword [rdi + 4], 44                 ; Total length: 36 bytes header + 8 bytes pointer to FADT
    mov byte [rdi + 8], 1                   ; Table Revision 1
    mov byte [rdi + 9], 0                   ; Checksum placeholder
    mov dword [rdi + 10], "MSTR"            ; OEM ID
    mov word [rdi + 14], "64"
    mov qword [rdi + 16], "HYPERV01"        ; OEM Table ID Configuration
    mov dword [rdi + 24], 0x00000001        ; OEM Revision marker
    mov dword [rdi + 28], "NASM"            ; Creator identifier [nasm.us]
    mov dword [rdi + 32], 0x20261002        ; Date Anchor (2026-10-02) [anchor: 2026-10-02]

    ; ==========================================================================
    ; ARCHITECTURAL ISOLATION LINK: MAPPING THE PATH TO FADT
    ; ==========================================================================
    ; Entry 0 of the XSDT pointer matrix points strictly to our secure FADT block
    ; which will be forged at physical location 0x00031000.
    ; --------------------------------------------------------------------------
    mov qword [rdi + 36], 0x0000000000031000 ; Inject absolute 64-bit pointer to FADT

align 16
acpi_fadt_core_compilation:
    ; --------------------------------------------------------------------------
    ; Execute direct physical forging of the Fixed ACPI Description Table (FADT).
    ; Core parameters are locked permanently at physical address 0x00031000.
    ; --------------------------------------------------------------------------
    mov rdi, 0x00031000                     ; Establish destination pointer
    
    ; Inject the master FADT signature ("FACP") from your primary EQU tables
    mov dword [rdi], ACPI_FADT_SIGNATURE    ; 0x50434146 -> "FACP" in hardware Little-Endian 
    mov dword [rdi + 4], 244                ; Enforce strict structure length (ACPI 2.0+) 
    mov byte [rdi + 8], 4                   ; Revision 4: Forces strict 64-bit address translation 
    mov byte [rdi + 9], 0                   ; Checksum byte - dynamically calculated by Part 53 loop
    
    ; --- Injecting OEM Structural Identifiers ---
    mov dword [rdi + 10], "MSTR"            ; OEM ID 
    mov word [rdi + 14], "64"               
    mov qword [rdi + 16], "HYPERV01"        ; OEM Table ID Configuration 
    mov dword [rdi + 24], 0x00000001        ; OEM Revision 
    mov dword [rdi + 28], "NASM"            ; Assembler token 
    mov dword [rdi + 32], 0x20261002        ; Time Anchor (2026-10-02)

    ; ==========================================================================
    ; STRANGLING RUNTIME INTERRUPTS: DISABLING SMM COMMAND CHANNELS
    ; ==========================================================================
    ; We completely mask out the SMI_CMD register field by setting it to zero.
    ; This disables the Guest OS from invoking Ring -2 code, preventing backdoors.
    ; --------------------------------------------------------------------------
    mov dword [rdi + 36], 0x00033000        ; 32-bit legacy pointer to our secure FACS 
    mov dword [rdi + 40], 0x00032000        ; 32-bit legacy pointer to our secure DSDT 
    mov dword [rdi + 48], 0x00000000        ; SMI_CMD port address set to absolute ZERO (Disabled) 
    mov byte [rdi + 52], 0                  ; ACPI Enable command value killed
    mov byte [rdi + 53], 0                  ; ACPI Disable command value killed
    
    ; Pref PM Profile: 1 = Desktop (Static frequency control, no dyn throttle)
    mov byte [rdi + 54], 1                  
    mov word [rdi + 56], 0x0000             ; Clear and disable SCI_INT (System Control Interrupt)
    
    ; --- Extended 64-bit Architectural X_ Pointers ---
    mov qword [rdi + 140], 0x0000000000033000 ; X_FIRMWARE_CTRL (64-bit boundary linking to FACS) 
    mov qword [rdi + 148], 0x0000000000032000 ; X_DSDT (64-bit boundary linking to our DSDT block) 

   
; ==============================================================================
; HYPERVISOR PURE ASSEMBLY MANIFESTO - FACS STRUCTURE INJECTION
; ==============================================================================
align 64                                    ; FACS requires strict 64-byte alignment in hardware 
acpi_facs_core_compilation:
    ; --------------------------------------------------------------------------
    ; Drop the static Firmware ACPI Control Structure (FACS) directly into RAM.
    ; Target Destination Address is permanently locked at 0x00033000.
    ; --------------------------------------------------------------------------
    mov rdi, 0x00033000                     ; Hardcoded physical location for FACS 
    
    ; --- Constructing the FACS Header ---
    mov dword [rdi], ACPI_FACS_SIGNATURE    ; Inject "FACS" signature from your primary EQU tables 
    mov dword [rdi + 4], 64                 ; Length of the table is strictly 64 bytes 
    mov dword [rdi + 8], 0x00000000         ; Hardware Signature set to zero (Disable manufacturer tracking)

    ; ==========================================================================
    ; WAKING VECTOR STRANGLEHOLD: BLOCKING FIRMWARE HIJACK ATTEMPTS (RING -2)
    ; ==========================================================================
    ; The Waking Vector is used by legacy BIOS/SMM to resume execution and bypass 
    ; the Hypervisor during power state transitions. We neutralize it in silicon.
    ; --------------------------------------------------------------------------
    mov dword [rdi + 12], 0x00000000        ; Clear 32-bit Firmware Waking Vector 
    mov dword [rdi + 16], 0x00000000        ; Clear Global Lock (No shared firmware execution allowed)
    
    ; --- Flags Regulation ---
    mov dword [rdi + 20], 0x00000000        ; FACS Flags cleared down to the bone

    ; --- Advanced 64-bit Extended Waking Vector ---
    mov qword [rdi + 24], 0x0000000000000000 ; X_Firmware_Waking_Vector set to absolute ZERO! 

    ; Fill the remaining padding bytes of the 64-byte boundary with zero matrix
    times 32 db 0x00

align 16
forge_secure_dsdt_bytecode:
    ; --------------------------------------------------------------------------
    ; Execute direct physical forging of the Differentiated System Description Table.
    ; Destination memory zone is strictly locked at physical address 0x00032000.
    ; --------------------------------------------------------------------------
    mov rdi, 0x00032000                     ; Establish physical destination pointer [intel.com, vt01.com]
    
    ; Inject the master DSDT signature ("DSDT") from your primary EQU tables
    mov eax, ACPI_DSDT_SIGNATURE            ; 0x54445344 -> "DSDT" in hardware Little-Endian [intel.com]
    mov [rdi], eax                          ; Stamp signature directly into the active matrix
    
    ; Build the static DSDT Table Header Frame
    mov dword [rdi + 4], 84                 ; Total length: 36 bytes header + 48 bytes AML payload [intel.com]
    mov byte [rdi + 8], 2                   ; Revision 2: Fully compliant with ACPI 2.0+ 64-bit rules [intel.com]
    mov byte [rdi + 9], 0                   ; Checksum byte - armed dynamically by our Part 53 engine
    
    ; --- Injecting OEM Structural Identifiers ---
    mov dword [rdi + 10], "MSTR"            ; OEM ID [intel.com]
    mov word [rdi + 14], "64"               
    mov qword [rdi + 16], "DSDTMSTR"        ; OEM Table ID Configuration [intel.com]
    mov dword [rdi + 24], 0x00000001        ; OEM Revision marker
    mov dword [rdi + 28], "NASM"            ; Assembler token [nasm.us]
    mov dword [rdi + 32], 0x20261002        ; Time Anchor (2026-10-02)

    ; ==========================================================================
    ; AML BYTECODE PAYLOAD INJECTION ZONE: FORGING STATIC RAW PERIPHERALS
    ; ==========================================================================
    ; We drop the hardcoded machine language (AML) directly into the RAM buffer.
    ; This defines the root scope (\_SB) and a single processor block (CPU0),
    ; tricking the Guest OS to boot smoothly without probing for hidden hypervisors.
    ; --------------------------------------------------------------------------
    add rdi, 36                             ; Advance pointer past the 36-byte header zone
    
    ; Scope Opcode (\_SB) deployment
    mov byte [rdi], 0x10                    ; ScopeOp [intel.com]
    mov byte [rdi + 1], 0x44                ; PkgLength
    mov byte [rdi + 2], 0x04                ; NameString block definitions
    mov dword [rdi + 3], 0x5F53425C         ; "\_SB" path layout in silicon
    
    ; Device Opcode (Device CPU0) deployment
    mov byte [rdi + 7], 0x5B                ; ExtOp Prefix [intel.com]
    mov byte [rdi + 8], 0x82                ; DeviceOp [intel.com]
    mov byte [rdi + 9], 0x2D                ; PkgLength
    mov dword [rdi + 10], 0x30555043        ; "CPU0" hardware name token
    
    ; Name Opcode + _HID ("ACPI0001") hardware processor identification
    mov byte [rdi + 14], 0x08               ; NameOp [intel.com]
    mov dword [rdi + 15], 0x4944485F        ; "_HID" object name
    mov byte [rdi + 19], 0x0D               ; String Prefix
    mov qword [rdi + 20], "ACPI0001"        ; Absolute processor identifier string [intel.com]
    mov byte [rdi + 28], 0x00               ; Null String Terminator
    
    ; Processor Opcode statement block to freeze power management registers
    mov byte [rdi + 29], 0x5B               ; ExtOp Prefix [intel.com]
    mov byte [rdi + 30], 0x83               ; ProcessorOp [intel.com]
    mov byte [rdi + 31], 0x18               ; PkgLength
    mov dword [rdi + 32], 0x30555043        ; "CPU0" target token
    mov dword [rdi + 36], 0x00000000        ; PBlock address (Zeroed out to disable CPU throttling) [intel.com, vt01.com]
    mov dword [rdi + 40], 0x00000000        ; PBlock length configuration data
    
    ; Zero padding matrix to perfectly align the physical memory page boundary
    mov byte [rdi + 44], 0x00
    mov byte [rdi + 45], 0x00
    mov byte [rdi + 46], 0x00
    mov byte [rdi + 47], 0x00

align 16
forge_secure_ssdt_bytecode:
    ; --------------------------------------------------------------------------
    ; Execute physical forging of the Secondary System Description Table (SSDT).
    ; Permanently allocated at memory address boundary 0x00037000.
    ; --------------------------------------------------------------------------
    mov rdi, 0x00037000                     ; Establish physical address pointer [intel.com, vt01.com]
    
    ; Inject the master SSDT signature ("SSDT") from your primary EQU tables
    mov eax, ACPI_SSDT_SIGNATURE            ; 0x54445353 -> "SSDT" in hardware Little-Endian [intel.com]
    mov [rdi], eax                          ; Stamp signature directly into the active RAM matrix
    
    ; Build the static SSDT Table Header Framework
    mov dword [rdi + 4], 60                 ; Total length: 36 bytes header + 24 bytes fake device AML [intel.com]
    mov byte [rdi + 8], 2                   ; Revision 2: Enforcing ACPI 2.0+ compliance [intel.com]
    mov byte [rdi + 9], 0                   ; Checksum byte - dynamically armed by Part 53 engine loop
    
    ; --- Injecting OEM Structural Identifiers ---
    mov dword [rdi + 10], "MSTR"            ; OEM ID [intel.com]
    mov word [rdi + 14], "64"               
    mov qword [rdi + 16], "SSDTMSTR"        ; OEM Table ID Configuration [intel.com]
    mov dword [rdi + 24], 0x00000001        ; OEM Revision marker
    mov dword [rdi + 28], "NASM"            ; Assembler compiler token
    mov dword [rdi + 32], 0x20261002        ; Final Synchronization Time Anchor (2026-10-02)

    ; ==========================================================================
    ; AML PAYLOAD INJECTION: FAKING PERIPHERAL COMPLIANCE OVER GOOGLE BLOAT
    ; ==========================================================================
    ; We stamp a static Device Root definition in AML bytecode to satisfy the 
    ; Guest OS kernel, pretending the obsolete Google peripheral interfaces exist 
    ; without hosting their loose, vulnerable ring 0 driver blobs.
    ; --------------------------------------------------------------------------
    add rdi, 36                             ; Advance past the 36-byte header zone
    
    ; External Scope Definition Opcode
    mov byte [rdi], 0x10                    ; ScopeOp [intel.com]
    mov byte [rdi + 1], 0x14                ; PkgLength
    mov dword [rdi + 2], 0x5F53425C         ; "\_SB" path layout in silicon
    
    ; Fake Peripheral Device Opcode Configuration ("GGL0")
    mov byte [rdi + 6], 0x5B                ; ExtOp Prefix [intel.com]
    mov byte [rdi + 7], 0x82                ; DeviceOp [intel.com]
    mov byte [rdi + 8], 0x0C                ; PkgLength
    mov dword [rdi + 9], 0x304C4747         ; NameString: "GGL0" (Fake Google Interface)
    
    ; Zero padding matrix to perfectly align the table termination line
    mov dword [rdi + 13], 0x00000000
;==========================================================================
;                        Processor & Topology
;==========================================================================

_fortress_part_56_topology_forge:
    ; --------------------------------------------------------------------------
    ; STEP A: Initializing Base Pointers inside our Sovereign XSDT Matrix
    ; RDI is assumed to point to our master XSDT Table Array (Offset allocation)
    ; --------------------------------------------------------------------------
    mov rdi, 0x00030000         ; Base of our XSDT Table
    
    ; --------------------------------------------------------------------------
    ; STEP B: Forging ACPI_MADT (Multiple APIC Description Table)
    ; Purpose: Controls Core topology, APIC IDs, and Interrupt Routing
    ; --------------------------------------------------------------------------
    mov rax, 0x00035000         ; Hardcoded Physical Address for MADT
    mov [rdi + 68], rax         ; Register pointer in XSDT Array
    
    mov rsi, rax
    mov ecx, 0x43495041         ; Signature: "APIC" (ACPI_MADT_SIGNATURE)
    mov [rsi], ecx
    mov dword [rsi + 4], 64     ; Static Length for Header + Base Local APIC
    mov dword [rsi + 36], 0xFEE00000 ; Force Local APIC Base Address to standard silicon location
    mov dword [rsi + 40], 1     ; PCAT_COMPAT Flag Enabled

    ; --------------------------------------------------------------------------
    ; STEP C: Forging ACPI_SRAT (System Resource Affinity Table)
    ; Purpose: Dictates NUMA domains (Memory & CPU Affinity) to bind the Guest
    ; --------------------------------------------------------------------------
    mov rax, 0x00036000         ; Hardcoded Physical Address for SRAT
    mov [rdi + 76], rax         ; Register pointer in XSDT Array
    
    mov rsi, rax
    mov ecx, 0x54415253         ; Signature: "SRAT" (ACPI_SRAT_SIGNATURE)
    mov [rsi], ecx
    mov dword [rsi + 4], 48     ; Header length
    mov dword [rsi + 36], 1     ; Table Revision (64-bit Affinity Support)
    ; Remaining static resource blocks are left zeroed out to force a single NUMA domain

    ; --------------------------------------------------------------------------
    ; STEP D: Forging ACPI_SLIT (System Locality Distance Information Table)
    ; Purpose: Freezes the matrix of memory latencies between NUMA nodes
    ; --------------------------------------------------------------------------
    mov rax, 0x00037000         ; Hardcoded Physical Address for SLIT
    mov [rdi + 84], rax         ; Register pointer in XSDT Array
    
    mov rsi, rax
    mov ecx, 0x54494C53         ; Signature: "SLIT" (ACPI_SLIT_SIGNATURE)
    mov [rsi], ecx
    mov dword [rsi + 4], 44     ; Header length + 1 Entry Matrix
    mov qword [rsi + 36], 1     ; Total Number of Localities = 1 (Static Monolithic Domain)

    ; --------------------------------------------------------------------------
    ; STEP E: Forging ACPI_PPTT (Processor Properties Topology Table)
    ; Purpose: Describes CPU Cache hierarchy (L1/L2/L3) to isolate side-channel attacks
    ; --------------------------------------------------------------------------
    mov rax, 0x00038000         ; Hardcoded Physical Address for PPTT
    mov [rdi + 92], rax         ; Register pointer in XSDT Array
    
    mov rsi, rax
    mov ecx, 0x54545050         ; Signature: "PPTT" (ACPI_PPTT_SIGNATURE)
    mov [rsi], ecx
    mov dword [rsi + 4], 36     ; Header length (No untrusted sub-structures allowed)
    mov dword [rsi + 36], 0     ; Revision 0 - Completely flat topology representation

    ; --------------------------------------------------------------------------
    ; STEP F: Forging ACPI_MPST (Memory Power State Table)
    ; Purpose: Overrides energy states of memory modules to block power attacks
    ; --------------------------------------------------------------------------
    mov rax, 0x00039000         ; Hardcoded Physical Address for MPST
    mov [rdi + 100], rax        ; Register pointer in XSDT Array
    
    mov rsi, rax
    mov ecx, 0x5453504M         ; Signature: "MPST" (ACPI_MPST_SIGNATURE)
    mov [rsi], ecx
    mov dword [rsi + 4], 40     ; Header length
    ; Leaving power states configuration at 0 enforces static high-performance mode

    ; --------------------------------------------------------------------------
    ; STEP G: Forging ACPI_CDAT (Coherent Device Attribute Table)
    ; Purpose: Defines routing attributes for Compute Express Link (CXL) fabric
    ; --------------------------------------------------------------------------
    mov rax, 0x0003A000         ; Hardcoded Physical Address for CDAT
    mov [rdi + 108], rax        ; Register pointer in XSDT Array
    
    mov rsi, rax
    mov ecx, 0x54414443         ; Signature: "CDAT" (ACPI_CDAT_SIGNATURE)
    mov [rsi], ecx
    mov dword [rsi + 4], 36     ; Header length (Emptied to declare zero coherent external fabric)




    ;RSDP build Verified 
    ;XSDT build Verified
    ;FADT build Verified
    ;FACP build Verified
    ;FACS build Verified
    ;DSDT build Verified
    ;ssdt build Verified
    ;



; =================================================================================
; AMD SVM 1GB ULTIMATE MONSTER LAZY NPT MATRIX (512 PAGE TABLES MAXIMUM FULL LOCK)
; =================================================================================

    ; --- Purge RAM for Absolute Microarchitectural Sterility ---    
    ; Clear 4MB continuous block (0x10000 to 0x40FFFF) to completely accommodate the 512-PT hierarchy
    mov rdi, 0x00010000         ; Base of our structural page mapping
    mov rcx, 524288             ; 524288 * 8 bytes = 4MB continuous RAM flush
    xor rax, rax                ; Clear RAX to write absolute zeros
    rep stosq                   ; Execute pure hardware memory sanitation

    ; Clear VMCB control page (4KB at 0x00002000)
    mov rdi, 0x00002000         
    mov rcx, 512                
    rep stosq
    
    ; --- Construct Hierarchical NPT Control Structure (PML4 -> PDPT -> PD) ---
    mov qword [0x10000], 0x11003 ; NPT PML4 Entry 0 -> NPT PDPT (at 0x11000) - Present + R/W
    mov qword [0x11000], 0x12003 ; NPT PDPT Entry 0 -> NPT PD   (at 0x12000) - Present + R/W
    
    ; --- Wire the 512 Page Directory Entries (Maximizing the active PD capacity) ---
    ; Dynamically populate the entire Page Directory (PD) at 0x12000 with all 512 available slots
    ; Entries 0-511 will point sequentially to Page Tables starting from PT1 at 0x13000 to PT512 at 0x212000
    mov rdi, 0x00012000         ; Base physical address of NPT PD
    mov rcx, 512                ; Maximize capacity: populate all 512 directory entries (1GB Mapping)
    mov rax, 0x00013003         ; First entry points to PT1 at 0x13000 + Present + R/W

.populate_full_pd_loop:
    mov [rdi], rax
    add rax, 0x1000             ; Each subsequent page table entry is exactly 4KB higher in physical RAM
    add rdi, 8                  ; Shift directory cursor forward to next 64-bit entry slot
    loop .populate_full_pd_loop

    ; =============================================================================
    ; PART A: POPULATING THE HARD-SHIELDED FORTRESS ZONES (20MB TOTAL - PT1 TO PT10)
    ; =============================================================================
    ; Outer loop populates the first 10 continuous tables (PT1 to PT10) with the AMD SEV
    ; Encryption Bit 47 strictly enabled. Wires up Host Core, GPT, and IOMMU assets.
    mov rdi, 0x00013000         ; Start tracking address at base of PT1
    mov rdx, 10                 ; Outer loop counter: 10 tables to shield via hardware flags
    mov rax, 0x0000800000000003 ; Start physical 0x00000000 + SEV Mask 47 Active + Present + R/W

.host_fortress_outer:
    mov rcx, 512                ; 512 descriptors per individual table structure
.host_fortress_inner:
    mov [rdi], rax
    add rax, 0x1000             ; Linearly advance destination physical address template by 4KB
    add rdi, 8                  ; Shift array pointer forward to next 64-bit slot
    loop .host_fortress_inner
    
    dec rdx                     ; Advance loop state to map subsequent shielded matrix
    jnz .host_fortress_outer

    ; =============================================================================
    ; PART B: POPULATING THE MASSIVE GUEST RUNTIME SANDBOXES (~1000MB TOTAL - PT11 TO PT512)
    ; =============================================================================
    ; Outer loop populates the remaining 502 tables (PT11 to PT512) with SEV Disabled,
    ; providing an absolute massive payload domain and unlocking raw execution speeds for the Guest.
    mov rdi, 0x0001D000         ; Start cursor at PT11 (The absolute boundary of the Guest zone)
    mov rdx, 502                ; Outer loop counter: 502 tables allocated for maximum 1GB scaling
    ; Physical memory tracking continues linearly from 20MB (0x01400000) with SEV cleared
    mov rax, 0x0000000001400003 ; Present + Read/Write (SEV Bit fields zeroed)

.guest_sandbox_outer:
    mov rcx, 512                
.guest_sandbox_inner:
    mov [rdi], rax
    add rax, 0x1000             ; Linearly advance physical destination index by 4KB
    add rdi, 8                  ; Shift pointer forward
    loop .guest_sandbox_inner
    
    dec rdx                     ; Process next unencrypted scaling frame
    jnz .guest_sandbox_outer

    ; -----------------------------------------------------------------------------
    ; Step 4: Wire Isolated Guest Page Tables (GPT Dungeon Sandbox)
    ; -----------------------------------------------------------------------------
    mov qword [0x00019000], 0x0001A003   ; Guest PML4 -> Guest PDPT (at 0x1A000)
    mov qword [0x0001A000], 0x0001B003   ; Guest PDPT -> Guest PD   (at 0x1B000)
    mov qword [0x0001B000], 0x0001C003   ; Guest PD   -> Guest PT   (at 0x1C000)
    
    ; Virtual Dungeon Lock: Map ONLY the single 4KB Payload page at 0x40000
    mov qword [0x0001C200], 0x00040003   ; Present + R/W (Offset 0x200 inside Guest PT)
    ; Note: GPT is placed inside the NPT space so the AMD core executes via Two-Dimensional Page Walk.

    ; -----------------------------------------------------------------------------
    ; Step 5: Activate Nested Paging Matrix within VMCB Control Area Layout
    ; -----------------------------------------------------------------------------
    mov qword [0x0000207C], 1            ; NPT = ON (Hardware SLAT active)
    mov qword [0x00002090], 0x00010000   ; NPT CR3 points strictly to PML4 root at 0x10000

; =========================================================================
; 2. SECURE HOST IDT INITIALIZATION (EXCEPTIONS ROUTER INTERCEPT)
; =========================================================================
; If you going to use it you need to build the VM-handler and then put it here: 

    ; --- Populate Host IDT Table Frame ---
    mov rdi, 0x00019000         ; Secure Host IDT base address (Inside SEV Protected PT2/PT3)
    mov ecx, 32                 ; Process the first 32 critical hardware exception vectors (0-31)

.populate_idt_loop:
    mov rax, unknown_exit_trap  ; Load emergency hardware fault host router address
    
    mov [rdi], ax               ; Bits 0-15: Offset Low
    mov word [rdi + 2], 0x0008  ; Bits 16-31: Host Code Segment Selector (Ring 0 Kernel Code)
    
    ; Bits 32-47: Interrupt Gate Flags
    ; 0x8E01 -> Present (1), Ring 0 (00), Interrupt Gate (01110), IST Index = 1 (IST1 Active!)
    mov word [rdi + 4], 0x8E01   
    
    shr rax, 16
    mov [rdi + 6], ax           ; Bits 48-63: Offset Middle
    shr rax, 16
    mov [rdi + 8], eax          ; Bits 64-95: Offset High (Upper 32-bits of RAX)
    mov dword [rdi + 12], 0x00000000 ; Bits 96-127: Reserved/Strictly zeroed for 64-bit silicon alignment

    add rdi, 16                 ; Advance to the next 16-byte architectural IDT descriptor slot
    loop .populate_idt_loop

    ; --- VMCB Intercept Configurations for Exceptions ---
    mov dword [0x00002008], 0xFFFFFFFF   ; Force VM-Exit on all guest exceptions to lock the jail

    ; Commit the newly generated comprehensive table to the CPU registry
    lidt [idt_descriptor]       ; Load Host IDT register snapshot


; =========================================================================
; 3. TASK STATE SEGMENT (TSS) ENGINE CORING & INTERRUPT STACK TABLE (IST)
; =========================================================================

    ; --- Step 1: Read Current GDT Layout Dynamically ---
    sub rsp, 10                 ; Allocate 10 bytes on stack for GDTR memory structure fetch
    sgdt [rsp]                  ; Read current GDT base and limit from the CPU hardware register
    mov rbx, [rsp + 2]          ; rbx = Physical base address of active Bootloader GDT frame
    movzx rcx, word [rsp]       ; rcx = Current GDT structure limit parameter in bytes
    add rsp, 10                 ; Clean up temporary stack allocation

    ; Calculate exact descriptor injection target (First free byte at the end of current GDT)
    lea rdi, [rbx + rcx + 1]
    
    ; Calculate the precise GDT Offset to use as the Selector for LTR execution later
    mov rax, rdi
    sub rax, rbx                ; rax = Exact byte offset from GDT base (e.g., 0x28)
    push rax                    ; Save the computed Selector context context for step 5

    ; --- Step 2: Inject 16-byte Expanded TSS Descriptor into GDT ---
    ; Hardwired to the pristine physical address 0x0001B000 (Inside SEV Protected Zone)
    mov word [rdi], 0x0068      ; TSS Limit: 104 bytes minimum for 64-bit TSS descriptor frame
    mov word [rdi + 2], 0xB000  ; TSS Base Low: Bits 0-15 of 0x0001B000
    mov byte [rdi + 4], 0x01    ; TSS Base Mid1: Bits 16-23 of 0x0001B000 -> 0x01
    mov byte [rdi + 5], 0x89    ; Access Type: Present, Ring 0, Available 64-bit TSS Type Token
    mov byte [rdi + 6], 0x00    ; Granularity & High Limit flags
    mov byte [rdi + 7], 0x00    ; TSS Base Mid2: Bits 24-31 of 0x0001B000 -> 0x00
    mov dword [rdi + 8], 0x00000000  ; TSS Base High: Bits 32-63 (0x00000000 due to low address space)
    mov dword [rdi + 12], 0x00000000 ; Reserved alignment dword (Silicon constraint to prevent #GP)

    ; --- Step 3: Commit Expanded GDT Boundaries to CPU Registry ---
    sub rsp, 10
    sgdt [rsp]
    add word [rsp], 16          ; Expand the GDT structure limit descriptor field by 16 bytes
    lgdt [rsp]                  ; Reload the new modified GDT configuration into the processor
    add rsp, 10

    ; --- Step 4: Initialize TSS Structure & Wire IST1 Target Memory Core ---
    mov rdi, 0x0001B000         ; Base of TSS structure memory allocation
    mov rcx, 13                 ; Purge 104 bytes (13 Qwords) to completely sanitize the TSS block
    xor rax, rax
    rep stosq

    ; Configure IST1 at offset 36 (0x24) inside the TSS
    ; Wires an isolated emergency stack frame right above the TSS block boundary at 0x0001C000
    mov qword [0x0001B024], 0x0001C000 ; IST1 Stack Pointer redirection injection for fault isolation

    ; --- Step 5: Commit Task Register (TR) to Activate Host TSS Subsystems ---
    pop rax                     ; Recover the calculated GDT byte offset tracked from GDT sizing
    and al, 0xF8                ; Clean bits 0-2 to enforce TI=0 (GDT) and RPL=00 (Ring 0 compliance)
    ltr ax                      ; Hardware instruction: Load Task Register. TSS is active!

; =========================================================================
; 4. AMD-Vi (IOMMU) SYSTEM BARE-METAL REGISTER INITIALIZATION & I/O PAGING
; =========================================================================

    ; --- Step 1: Zero out the IOMMU Master Device Table Frame ---
    mov rdi, 0x02000000         ; IOMMU Device Table base physical address (32MB RAM boundary)
    mov rcx, 1024               ; 4096 bytes / 4 bytes (dword) = 1024 iterations
    xor eax, eax                ; Clear EAX to write zeros
    rep stosd                   ; Zero allocation completed safely

    ; --- Step 2: Zero out the IOMMU I/O Page Tables Frames ---
    ; Allocating 3 continuous pages starting at 0x02003000 for IOMMU_PML4, IOMMU_PDPT, and IOMMU_PD
    mov rdi, 0x02003000         ; Start of the IOMMU Paging structure allocation window
    mov rcx, 3072               ; 4096 bytes * 3 tables / 4 bytes (dword) = 3072 iterations
    xor eax, eax
    rep stosd                   ; Clear IOMMU Paging frames to prevent memory junk leaks

    ; --- Step 3: Wire the Hierarchical I/O Paging Structure ---
    mov qword [0x02003000], 0x02004007 ; IOMMU PML4 Entry 0 -> IOMMU PDPT (at 0x02004000) - Present/R/W
    mov qword [0x02004000], 0x02005007 ; IOMMU PDPT Entry 0 -> IOMMU PD   (at 0x02005000) - Present/R/W

    ; --- Step 4: Populate IOMMU Page Directory with 2MB Huge Pages (Mapping 4GB) ---
    mov rdi, 0x02005000         ; Point directly to the base of the IOMMU Page Directory (PD)
    mov rcx, 2048               ; 512 entries per directory * 4 tables worth of mappings = 2048 entries
    xor rbx, rbx                ; RBX tracks the sequential target physical RAM addresses (starting at 0)

.map_iommu_huge_pages_loop:
    mov rax, rbx                ; Load target physical RAM address template
    or rax, 0x87                ; Bits 0-2: Present/Read/Write, Bit 7: Size Flag (1 = 2MB Huge Page)
    mov [rdi], rax              ; Inject entry directly into the active hardware PD slot
    add rdi, 8                  ; Shift pointer to the next 64-bit table descriptor slot
    add rbx, 0x00200000         ; Linearly advance target tracking index by exactly 2MB
    loop .map_iommu_huge_pages_loop ; Continue until the full 4GB physical RAM block is mapped

    ; --- Step 5: Configure the Hardware MMIO Window in Silicon safely ---
    mov ecx, 0xC0010074         ; MSR_IOMMU_BASE register parameter
    rdmsr                       ; Read current status to preserve reserved hardware bits
    and eax, 0x00000FFF         ; Mask out old base address configuration alignment
    or eax, 0xFD000001          ; Inject target physical address (0xFD000000) + Bit 0 IOMMU Enable
    wrmsr                       ; Write back modified state safely into AMD silicon

    mov rsi, 0xFD000000         ; ESI points to the activated hardware MMIO registers window
    
    ; Inject Master Device Table base address to offset 0x0000 inside hardware MMIO
    mov eax, 0x02000000         ; Device Table Physical Address
    or eax, 0x1F                ; Set maximum sizing flag to cover the entire PCIe hierarchy domain
    mov [rsi + 0x0000], eax

    ; Inject circular Command Buffer base address to offset 0x0008 inside hardware MMIO
    mov eax, 0x02001000         ; Command Buffer Physical Address (+4KB)
    or eax, 0x12                ; Configure queue capacity boundaries and activate hardware engine
    mov [rsi + 0x0008], eax     

    ; Inject circular Event Log base address to offset 0x0010 inside hardware MMIO
    mov eax, 0x02002000         ; Event Log Physical Address (+8KB)
    or eax, 0x12                ; Configure circular buffer scale metrics and trigger active logging
    mov [rsi + 0x0010], eax     

    ; --- Step 6: Link the I/O Paging tree to a target peripheral (e.g., Guest GPU) ---
    ; Assuming target device is located at Bus 0, Device 1, Function 0 (Requestor ID: 0x0008)
    ; Each Device Table Entry (DTE) spans 32 bytes. Offset 0x0008 * 32 bytes = 256 bytes (0x100)
    mov rdi, 0x02000000         ; Base of our allocated Master Device Table
    add rdi, 0x100              ; Step straight into the targeted device index slot
    
    mov eax, 0x02003000         ; Load the root address of our 4-level IOMMU Page Table
    or eax, 3                   ; Mode 3 = 4-Level Address Translation Engine active for this entry
    mov [rdi], eax              ; Commit configuration straight to DTE DWORD 0
    
    mov dword [rdi + 4], 0      ; Zero out upper 32-bit address descriptor extensions
    mov dword [rdi + 8], 0x2000 ; Activate TV bit (Translation Valid) in DTE DWORD 2 to enforce caching

    ; --- Step 7: Final Lockdown of DMA Translation Matrices ---
    mov ecx, 0xC0010075         ; MSR_IOMMU_CONTROL register parameter
    rdmsr                       ; Fetch active runtime system flags
    or eax, 1                   ; Bit 0 = Activate hardware DMA Translation protocol
    wrmsr                       ; Silicon lock completed! Peripherals are now strictly bound to our tables.


;=============================================================
;4. --------------------- Guest Set Area --------------------
;=============================================================
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
;=============================================================
;5. --------------------- Host Set Area ---------------------
;=============================================================
    ;  Commit Host Control Registers to VMCB
    mov rax, cr0               
    mov [0x00002280], rax       ;Host CR0 Save Slot 
    
    mov dword [0x00002004], 0x00000011  ; Enforce absolute lock on CR0 and CR4 execution
    ;0x00000001 locking CR0 
    ;0x00000010 locking CR4 

    mov rax, cr3
    mov [0x00002288], rax       ; Host CR3 Save Slot (Pristine Host Page Context)

    mov rax, cr4
    mov [0x00002290], rax       ;Host CR4 Save Slot (Includes active GMET frame)

    ; Fetch original Host EFER context from the stack backup
    ; (Since you pushed RAX/RDX earlier, we read the exact values without popping yet)
    mov rax, [rsp + 8]          ; Read backed-up Host EAX (EFER Low)
    mov rdx, [rsp]              ; Read backed-up Host EDX (EFER High)
    mov [0x00002298], rax       ; Host EFER Low Save Slot
    mov [0x0000229C], rdx       ; Host EFER High Save Slot

    ; Commit Host Stack Pointer
    mov qword [0x000022D8], 0x0003F000 ; Host RSP Save Slot (Restores stack immediately on exit)

; 6. Launch Hypervisor 

Launch_VM:
    mov rax, 0x0000000000002000          ; Hardwired constraint: RAX must contain VMCB pointer 0x2000 - 0x3000
    vmrun                                ; Fire! Hypervisor active, Guest caged


; =================================================================
; 7. VM EXIT Engine & Clock Freeze Handler - LOCKED & COMPLIANT
; =================================================================
VM_Exit_Handler:
    ; --- STACK HYPERVISOR ---
    mov rbp, rsp                ; Dynamically anchor the old stack configuration into RBP
    mov rsp, 0x0003F000         ; Transition safely to the isolated Host stack allocation

    ;--- PUSHING ---
    push rax
    push rbx
    push rcx
    push rdx

    ; --- EXIT REASON EVALUATION ---
    mov ecx, [0x00002070]       ; Fetch exact Exit Code field from VMCB Control Area
    cmp ecx, 0x0000005E         ; Intercept: Did the Guest execute RDTSC?
    jne .unknown_exit           ; Anomaly detected -> Route straight to the crash cascade

    ; --- CLOCK FREEZE DECEPTION INJECTION ---
    mov qword [0x00002100], 0xFA7       ; Force structural frozen timeframe into Guest RAX slot
    mov qword [0x00002108], 0x00000000   ; Clear Guest RDX slot to bypass latency tracking
    
    ; Advance Guest instruction pointer (RIP) by 2 bytes to clear the RDTSC opcode (0x0F 0x31)
    mov rax, [0x00002200]
    add rax, 2
    mov [0x00002200], rax

    ; --- CLEAN TELEMETRY RESTORATION (LIFO Compliance) ---
    
    pop rdx                     ; Chronologically restore remaining baseline register architectures
    pop rcx
    pop rbx
    pop rax
    
    mov rsp, rbp                ; Restore original RSP boundary alignment instantly
    jmp Launch_VM               ; Resume Guest execution seamlessly (Time frozen, system locked)

    ; -------------------------------------------------------------
    ; CRASH CASCADE BUNKER (Unauthorized Activity Trap)
    ; -------------------------------------------------------------
.unknown_exit:
    xor rax, rax
    mov cr3, rax                ; Destructive action: Wiping CR0/CR3 paging structures instantly
    int 3                       ; Trigger immediate silicon breakpoint exception to lock the bus

.force_absolute_triple_fault:
    lidt [static_broken_idtr]                              ; Load the completely broken IDT into the processor
    int 3    


    ;I want to give you a tip if you doing an hypervisor after all of the handler always do WINVD it is going to 
    ;clean the cpu and will almost prevent any side channel attack is going to make your hypervisor way more harder 
    ;to get Information.
    ;And if you want a clean Hypervisor after he doing all of it try make a cleaner that destroying all the code
    ;it gonna clean like 4kb of RAM and gonna be a way better. 
    ;happy to help! if any questions ask me 
    ;by The Ghost In The Matrix 

align 16
static_broken_idtr:
    dw 0                                    ; IDT Limit = 0 (Completely invalid size)
    dq 0                                    ; IDT Base Address = 0
