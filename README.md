[bits 64]
[org 0x4000]
;========================================================================
;------------------ Created by The Ghost In The Matrix ------------------
;========================================================================


;Defines so I dont need to go back to AMD manual:

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
    mov ecx, IA32_SPEC_CTRL
    mov eax, 0x00000007         ; Lower 32-bits: Enable IBRS, STIBP, SSBD hardwired
    xor edx, edx                ; Upper 32-bits: Clear to 0
    wrmsr                       ; Commit state directly to CPU hardware execution engine

    ; Sanitize and Purge CPU Branch Prediction History ---
    ; We issue a physical flush command to clean any residual tracking from the BIOS.
    ; Bit 0 of IA32_PRED_CMD executes an Immediate Indirect Branch Prediction Barrier (IBPB).
    mov ecx, IA32_PRED_CMD
    mov eax, 0x00000001         ; Trigger IBPB history purge sequence
    xor edx, edx
    wrmsr

    ; Establish Hardware Core Locks on AMD Configuration ---
    ; The AMD Hardware Configuration Register (HWCR) governs internal CPU features.
    ; We read the current setup, verify limits, and prepare it for structural stability.
    mov ecx, AMD_HWCR
    rdmsr
    or eax, 1 << 24             ; Set Bit 24 (TSC_FREQ_SEL) or customize architecture limits
    wrmsr

    ; Sterilize Mitigation Control Registers ---
    mov ecx, IA32_PRED_CTRL
    xor eax, eax                ; Establish clean zero baseline state
    xor edx, edx
    wrmsr

    ; Hard Flush the L1 Data Cache for Cold Start Security ---
    ; Turning on bit 0 triggers the hardware to completely wipe L1 cache lines,
    ; killing any leftovers from preceding boot layers.
    mov ecx, IA32_FLUSH_CMD
    mov eax, 0x00000001         ; Commit atomic L1 data cache invalidate command
    xor edx, edx
    wrmsr

    ;==================================================================================
    ;                           MEMORY_TYPING_AND_APIC
    ;==================================================================================
    prepare_memory_typing_and_apic:
    ; --- STEP 1: Verify MTRR Architectural Capabilities ---
    ; We query the processor to ensure fixed-range registers and WC are active.
    mov ecx, MSR_MTRRcap
    rdmsr                       ; Returns capabilities in EAX (Read-Only framework)

    ; --- STEP 2: Configure Fixed-Range MTRR for Low 64KB (Bootloader Area) ---
    ; Each byte in this 64-bit register dictates the memory type of an 8KB block.
    ; Value 0x06 sets the type to Write-Back (WB) for blazing fast execution, 
    ; or 0x00 to mark it Uncacheable (UC) if you want absolute physical isolation.
    ; We establish Write-Back (0x06) across all eight 8KB sub-blocks of the first 64KB.
    mov ecx, MSR_MTRRfix64k_00000
    mov eax, 0x06060606         ; Type for 0x00000 to 0x07FFF (Blocks 0-3)
    mov edx, 0x06060606         ; Type for 0x08000 to 0x0FFFF (Blocks 4-7)
    wrmsr                       ; Lock the memory caching type for the low 64KB frame

    ; --- STEP 3: Enforce Default Memory Type System-Wide ---
    ; We set the global memory behavior for any area not explicitly mapped by a range register.
    ; Value 0x00000C06: 
    ; - Bit 11 (MTRR Enable) = 1 [intel.com]
    ; - Bit 10 (Fixed-Range MTRR Enable) = 1 [intel.com]
    ; - Bits 7:0 (Default Memory Type) = 0x06 (Write-Back) [intel.com]
    mov ecx, IA32_MTRR_DEF_TYPE
    mov eax, 0x00000C06         ; Turn on global MTRRs and force Write-Back caching default [intel.com]
    xor edx, edx
    wrmsr

    ; --- STEP 4: Lock and Validate Local APIC Base Location ---
    ; The Local APIC handles hardware interrupts for the core.
    ; We read the register, preserve the physical base address, and ensure it is armed.
    mov ecx, IA32_APIC_BASE
    rdmsr
    or eax, 1 << 11             ; Set Bit 11 (APIC Global Enable) to enforce hardware interrupt control [intel.com]
    wrmsr                       ; Commit APIC state to silicon architecture

    ;==================================================================================
    ;                           cet_control_flow        
    ;==================================================================================
    prepare_cet_control_flow:
    ; --- STEP 1: Configure Kernel/Supervisor Shadow Stack (IA32_S_CET) ---
    ; We write to the Supervisor CET register to activate the hardware engine.
    ; Value 0x00000001: 
    ; - Bit 0 (SHSTK_EN) = 1 -> Enables Shadow Stack for Supervisor Mode [intel.com]
    ; - Bit 1 (WRSS_EN)  = 1 -> Enables WRSS instruction if write-to-shadow-stack is needed [intel.com]
    mov ecx, IA32_S_CET
    mov eax, 0x00000003         ; Turn on Shadow Stack Enforcement & WRSS in Kernel [intel.com]
    xor edx, edx
    wrmsr                       ; Commit CET hardware activation to the core

    ; --- STEP 2: Establish Privilege Level 0 Shadow Stack Pointer (IA32_PL0_SSP) ---
    ; We must point the physical CPU to a pristine memory zone allocated for the 
    ; Host's secure shadow stack. Let's wire it to a secure page frame (e.g., 0x00028000).
    mov ecx, IA32_PL0_SSP
    mov eax, 0x00028000         ; Lower 32-bits of the safe Shadow Stack pointer location
    xor edx, edx                ; Upper 32-bits (Assumed within the first 4GB region)
    wrmsr                       ; Lock the Ring 0 Shadow Stack Pointer in silicon

    ; --- STEP 3: Wire Interrupt Shadow Stack Table Address ---
    ; When a hardware interrupt or exception occurs, the CPU needs a clean shadow stack frame.
    ; We map the execution pointer table to another dedicated secure frame (e.g., 0x00029000).
    mov ecx, IA32_INTERRUPT_SSP_TABLE_ADDR
    mov eax, 0x00029000         ; Pointer to the SSP interrupt token layout array
    xor edx, edx
    wrmsr                       ; Arm the interrupt hardware mitigation matrix

    ; --- STEP 4: Reset User Mode CET Baseline ---
    ; Ensure User Mode restrictions are cleared at early stage to prevent fault loop
    mov ecx, IA32_U_CET
    xor eax, eax
    xor edx, edx
    wrmsr

    ; --- STEP 5: Finalize and Arm via Control Register 4 (CR4) ---
    ; To activate CET globally on the core, Bit 23 of CR4 (CET Enable) must be flipped [intel.com].
    mov rax, cr4
    or rax, 1 << 23             ; Turn on Bit 23 (CET Hardware Bit) [intel.com]
    mov cr4, rax                ; The processor is now actively locked under CET shield!

    ;==================================================================================
    ;             performance_and_debugging it just cleaning
    ;==================================================================================

    prepare_performance_and_debugging:
    ; --- STEP 1: Blind the Hardware Debug Control (IA32_DEBUGCTL) ---
    ; We completely clear this register to zero out all hardware tracing features.
    ; - Bit 0 (LBR) = 0 -> Disables Last Branch Recording globally [intel.com]
    ; - Bit 1 (BTF) = 0 -> Disables Single-Step on Branches (Anti-Stepping) [intel.com]
    mov ecx, IA32_DEBUGCTL
    xor eax, eax                ; Clear all control bits to 0
    xor edx, edx
    wrmsr                       ; Silicon debug features are now dead and blind

    ; --- STEP 2: Kill Global Performance Counters (IA32_PERF_GLOBAL_CTRL) ---
    ; Performance counters can be abused to measure hypervisor execution footprints.
    ; We drop the execution control mask to 0, stopping all hardware profile counters [intel.com].
    mov ecx, IA32_PERF_GLOBAL_CTRL
    xor eax, eax                ; Disarm all counter allocation fields
    xor edx, edx
    wrmsr                       ; Performance side-channel profiling is frozen

    ; --- STEP 3: Sanitize Last Branch Record (LBR) Cache Matrix ---
    ; We execute an explicit zero-wipe on the LBR pipeline source and target registers
    ; to purge any residual instruction pointers left behind from the pre-boot state.
    mov ecx, MSR_BR_FROM_IP
    xor eax, eax
    xor edx, edx
    wrmsr
    
    mov ecx, MSR_BR_TO_IP
    xor eax, eax
    xor edx, edx
    wrmsr                       ; Hardware trace vectors are perfectly sterilized 

    ;==================================================================================
    ;              thermal_and_power_control physics is my favorite :)
    ;==================================================================================
    prepare_thermal_and_power_control:
    ; --- STEP 1: Establish Pure Performance Bias (IA32_ENERGY_PERF_BIAS) ---
    ; We bypass any OS power-saving jitter. 
    ; Value 0x00 forces the silicon into Maximum Performance Mode [intel.com].
    ; This eliminates dynamic frequency switching which hackers use for timing analysis.
    mov ecx, IA32_ENERGY_PERF_BIAS
    xor eax, eax                ; Value 0: Performance hint set to absolute max [intel.com]
    xor edx, edx
    wrmsr                       ; Energy policy is locked to maximum power execution

    ; --- STEP 2: Configure Processor Core Matrix (IA32_MISC_ENABLE) ---
    ; We read the current setup, verify hardwired limits, and enforce critical flags.
    ; - Bit 34 (XD Bit Enable) = 1 -> Hard-enforces Execute-Disable flag for page safety [intel.com].
    ; - Bit 16 (Enhanced Intel SpeedStep) = 0 -> We kill dynamic throttling to enforce static clock speed [intel.com].
    mov ecx, IA32_MISC_ENABLE
    rdmsr
    or eax, 1 << 34             ; Force Execute-Disable (XD Bit) active [intel.com]
    and eax, ~(1 << 16)         ; Strip out dynamic SpeedStep control [intel.com]
    wrmsr                       ; Core structural properties successfully committed

    ; --- STEP 3: Enforce Thermal Intercept Guard (IA32_THERM_CONTROL) ---
    ; We program the Silicon Thermal Monitor Interface mask.
    ; This configures automatic hardware-level thermal modulation (Clock Throttling) 
    ; to defend against physical heat-generation exploits.
    mov ecx, IA32_THERM_CONTROL
    mov eax, 0x00000009         ; Activate automatic thermal control circuit (Bit 0 and Bit 3) [intel.com]
    xor edx, edx
    wrmsr                       ; Physical thermal patrol armed in hardware

    ; --- STEP 4: Lock User Mode Wait Parameters (IA32_UMWAIT_CONTROL) ---
    ; The UMWAIT instruction allows user mode code to put the CPU into a low-power state.
    ; Attackers abuse this to build ultra-precise time-measurement loops (Side-Channel).
    ; We modify the maximum time limits and configuration to freeze this capability.
    mov ecx, IA32_UMWAIT_CONTROL
    xor eax, eax                ; Clear time bias limits to baseline constants
    xor edx, edx
    wrmsr                       ; Speculative user-mode wait timing loop disabled



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
