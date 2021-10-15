/*
 * LatticeMico32 C startup code.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

/* Exception handlers - Must be 32 bytes long. */
	.section    .text, "ax", @progbits        
	.global     _start  
	.global     irq_enable, irq_disable, irq_set_mask, irq_get_mask
	.global     jump, halt
	.global     get_sp, get_gp
  
_start:    
_reset_handler:
        bi      _crt0
        nop
        nop
        nop
        nop
        nop
        nop
        nop

_breakpoint_handler:
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop

_ibuserror_handler:
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop

_watchpoint_handler:
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop

_dbuserror_handler:
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop

_divzero_handler:
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop

_interrupt_handler:
	sw      (sp+0), ra
	calli   _save_all
	rcsr	r1, IP 
	calli   irq_handler
	mvhi    r1, 0xffff
	ori     r1, r1, 0xffff
	wcsr	IP, r1 
	bi      _restore_all_and_eret

_scall_handler:
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop

_crt0:           
        /* Clear r0 */
        xor     r0, r0, r0
        
        /* Clear all other regs (needed so that simulations match) */
        mvi     r1, 0
        mvi     r2, 0
        mvi     r3, 0
        mvi     r4, 0
        mvi     r5, 0
        mvi     r6, 0
        mvi     r7, 0
        mvi     r8, 0
        mvi     r9, 0
        mvi     r10, 0
        mvi     r11, 0
        mvi     r12, 0
        mvi     r13, 0
        mvi     r14, 0
        mvi     r15, 0
        mvi     r16, 0
        mvi     r17, 0
        mvi     r18, 0
        mvi     r19, 0
        mvi     r20, 0
        mvi     r21, 0
        mvi     r22, 0
        mvi     r23, 0
        mvi     r24, 0
        mvi     r25, 0
        mvi     r26, 0
        mvi     r27, 0
        mvi     r28, 0
        mvi     r29, 0
        mvi     r30, 0
        mvi     r31, 0

        /* Setup stack and global pointer */
        mvhi    sp, hi(_fstack)
        ori     sp, sp, lo(_fstack)
        mvhi    gp, hi(_gp)
        ori     gp, gp, lo(_gp)
                        
        /* Clear BSS */
        mvhi    r1, hi(_fbss)
        ori     r1, r1, lo(_fbss)
        mvhi    r3, hi(_ebss)
        ori     r3, r3, lo(_ebss)
.clearBSS:
        be      r1, r3, .callMain
        sw      (r1+0), r0
        addi    r1, r1, 4
        bi      .clearBSS

	
.callMain:
	mvi     r1, 0
	mvi     r2, 0
	mvi     r3, 0
	/*initial_global_data then run main*/
	calli   __main  

irq_enable:
	mvi     r1, 1
	wcsr	IE, r1
	ret

irq_disable:
	mvi     r1, 0
	wcsr	IE, r1
	ret

irq_set_mask:
	wcsr	IM, r1
	ret

irq_get_mask:
	rcsr    r1, IM
	ret
	
jump:
	b       r1 

halt:
	bi halt

	/* Save all registers onto the stack */ 
_save_all:
	addi    sp, sp, -128
	sw      (sp+4), r1
	sw      (sp+8), r2
	sw      (sp+12), r3
	sw      (sp+16), r4
	sw      (sp+20), r5
	sw      (sp+24), r6
	sw      (sp+28), r7
	sw      (sp+32), r8
	sw      (sp+36), r9
	sw      (sp+40), r10
#ifdef MICO32_FULL_CONTEXT_SAVE_RESTORE
	sw      (sp+44), r11
	sw      (sp+48), r12
	sw      (sp+52), r13
	sw      (sp+56), r14
	sw      (sp+60), r15
	sw      (sp+64), r16
	sw      (sp+68), r17
	sw      (sp+72), r18
	sw      (sp+76), r19
	sw      (sp+80), r20
	sw      (sp+84), r21
	sw      (sp+88), r22
	sw      (sp+92), r23
	sw      (sp+96), r24
	sw      (sp+100), r25
	sw      (sp+104), r26
	sw      (sp+108), r27
#endif
	sw      (sp+120), ea
	sw      (sp+124), ba
	/* ra and sp need special handling, as they have been modified */
	lw      r1, (sp+128)
	sw      (sp+116), r1
	mv      r1, sp
	addi    r1, r1, 128
	sw      (sp+112), r1        
	ret

        /* Restore all registers and return from exception */
_restore_all_and_eret:
        lw      r1, (sp+4)
        lw      r2, (sp+8) 
        lw      r3, (sp+12) 
        lw      r4, (sp+16) 
        lw      r5, (sp+20) 
        lw      r6, (sp+24) 
        lw      r7, (sp+28) 
        lw      r8, (sp+32) 
        lw      r9, (sp+36) 
        lw      r10, (sp+40)
#ifdef MICO32_FULL_CONTEXT_SAVE_RESTORE
        lw      r11, (sp+44)
        lw      r12, (sp+48)
        lw      r13, (sp+52)
        lw      r14, (sp+56)
        lw      r15, (sp+60)
        lw      r16, (sp+64)
        lw      r17, (sp+68)
        lw      r18, (sp+72)
        lw      r19, (sp+76)
        lw      r20, (sp+80)
        lw      r21, (sp+84)
        lw      r22, (sp+88)
        lw      r23, (sp+92)
        lw      r24, (sp+96)
        lw      r25, (sp+100)
        lw      r26, (sp+104)
        lw      r27, (sp+108)
#endif
        lw      ra, (sp+116)
        lw      ea, (sp+120)
        lw      ba, (sp+124)
        /* Stack pointer must be restored last, in case it has been updated */
        lw      sp, (sp+112)
        eret

get_sp:
	mv      r1, sp
	ret

get_gp:
	mv      r1, gp
	ret       

