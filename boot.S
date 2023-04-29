    .section .init,"ax",@progbits
    .global _start
    .align 1
_start:
    j handle_reset
    .section    .vector,"ax",@progbits
    .align  1
_vector_base:
    .option norvc;
    .word   _irq_trap
    
    .section .text.handle_reset,"ax",@progbits
    .weak handle_reset
    .align 1

handle_reset:
    .option push
    .option norelax
    la gp, __global_pointer$
    .option pop
1:
    la sp, _eusrstack /* load stack pointer */
2:
    la a0, _data_lma  /* Data section offset in ROM */
    la a1, _data_vma  /* Data section offset in RAM */
    la a2, _edata     /* Data section size */
    bgeu a1, a2, 2f   /* If offsets are equal to data section size, than DATA section size is*/
                      /* zero so skip following step */
1:
    lw t0, (a0)       /* load word from DATA section in ROM from the address in a0 pointer to t0 register */
    sw t0, (a1)       /* store word from t0 register to RAM at the address of a1 pointer  */
    addi a0, a0, 4    /* increment a0 pointer */
    addi a1, a1, 4    /* increment a1 pointer */
    bltu a1, a2, 1b   /* check copied size. If it's equal to DATA section size, than we're done. Else repeat */
2:
    la a0, _sbss      /* load start of bss section */
    la a1, _ebss      /* load end of bss section */
    bgeu a0, a1, 2f   /* If the size of bss section is equal to zero, than skip following step. */

1:
    sw zero, (a0)     /* clear bss section at a0 */
    addi a0, a0, 4    /* increment a0 pointer */
    bltu a0, a1, 1b   /* check the size */

2:
    /* Setup corecfgr register (0xbc0). Datasheet describes this register as: Mainly used for configuring     */
    /* processor pipelining and branch prediction features, and should not be operated by user. Default value */
    /* is 0x1f                                                                                                */
    li t0, 0x1f
    csrw 0xbc0, t0


    /* Enable interrupt nesting and HW stack */
    li t0, 0x01   /* 1011: PMT_CFG (preemption config): 0b10 - 4 nested levels, 2 preemption bits */
                  /*       INESTEN (interrupt nesting): 0b1  - interrupt nesting enabled          */
                  /*       HWSTKEN (HW stack enable):   0b1 - hardware stack enabled              */
    csrw 0x804, t0

    /* Enable interrupts */
    li t0, 0x88
    csrs mstatus, t0

    
    /* Load interrupt vector table */
    la t0, _vector_base
    ori t0, t0, 2
    csrw mtvec, t0

    /* Jump to C */
    la t0, main     /* Load address of main function to t0 register.                     */
    csrw mepc, t0   /* store address of main function from t0 register to mepc register. */
    
    /* Couple of words for MEPC (_M_achine _E_xception _P_rogram _C_ounter) register: */
    /* When a trap is taken into M-mode, mepc is written with the virtual address of  */
    /* the instruction that was interrupted or that encountered the exception.        */
    /* Otherwise, mepc is never written by the implementation, though it may be       */
    /* explicitly written by software.                                                */
    
    mret /* "Return" from interrupt routine to the address stored in mret register. In other words, jump to C code :) */
