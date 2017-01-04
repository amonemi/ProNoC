.nodelay

#include "exception.inc"


#-------------------------------------------------------------
# VECTOR 0x100 - Reset
#-------------------------------------------------------------
.org    0x100
vector_reset:

    # Setup SP (R1)
    l.movhi r4,hi(_sp);
    l.ori r1,r4,lo(_sp);
    
    # R4 = _bss_start
    l.movhi r4,hi(_bss_start);
    l.ori r4,r4,lo(_bss_start);
    
    # R5 = _bss_end
    l.movhi r5,hi(_bss_end);
    l.ori r5,r5,lo(_bss_end);
    
BSS_CLEAR:
    l.sw 0x0(r4),r0         # Write 0x00 to mem[r4]
    l.sfleu r4,r5           # SR[F] = (r4 < r5)
    l.addi r4, r4, 4        # r4 += 4
    l.bf  BSS_CLEAR         # If SR[F] == 0, jump to BSS_CLEAR    
    l.nop

    # Jump to debug agent
    l.j main
    l.nop

.size vector_reset, .-vector_reset

#-------------------------------------------------------------
# VECTOR 0x200 - Fault / Illegal Instruction
#-------------------------------------------------------------
.org    0x200
vector_fault:

    # Save context
    asm_save_context

    # Arg 2 = Fault
    l.addi r4, r0, 1

    l.j handle_exception
    l.nop

.size vector_fault, .-vector_fault

#-------------------------------------------------------------
# VECTOR 0x300 - External Interrupt
#-------------------------------------------------------------
.org    0x300
vector_extint:

    # Save context
    asm_save_context

    # Arg 2 = Ext Int
    l.addi r4, r0, 2

    l.j handle_exception
    l.nop

.size vector_extint, .-vector_extint

#-------------------------------------------------------------
# VECTOR 0x400 - Syscall
#-------------------------------------------------------------
.org    0x400
vector_syscall:

    # Save context
    asm_save_context

    # Arg 2 = Syscall
    l.addi r4, r0, 3

    l.j handle_exception
    l.nop

.size vector_syscall, .-vector_syscall

#-------------------------------------------------------------
# VECTOR 0x600 - Trap
#-------------------------------------------------------------
.org    0x600
vector_trap:

    # Save context
    asm_save_context
    
    # Arg 2 = Trap
    l.addi r4, r0, 4

    # Fall through...

.size vector_trap, .-vector_trap

#-------------------------------------------------------------
# handle_exception: Common exception handling code
#-------------------------------------------------------------
handle_exception:

    # Copy stack pointer to arg1
    l.add r3, r0, r1

    # Jump to debug handler
    l.movhi r10,hi(exception);
    l.ori r10,r10,lo(exception);   
    l.jalr r10
    l.nop

    # Return value is stack pointer
    l.add r1, r0, r11

    # Restore context
    asm_load_context

.size   handle_exception, .-handle_exception


#------------------------------------
#
#------------------------------------

hang:
    l.trap 0
    l.j hang
    l.nop

.globl PUT32
PUT32:
    l.jr r9
    l.sw 0(r3),r4

.globl GET32
GET32:
    l.jr r9
    l.lwz r11,0(r3)

    l.j hang
    l.nop

