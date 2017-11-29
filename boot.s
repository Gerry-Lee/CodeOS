! First, load kernel code(head) to memory address 0x10000 by IDT of BIOS. Then, move kernel to memory address 0.
! Last, enter protect mode and jump to memory address 0 to run.

BOOTSEG = 0x7c0         ! Load sector(this program) is loaded to memory address 0x7c00 by BIOS
SYSSEG = 0x1000         ! Kernel code(head) is loaded to 0x10000, then moved to 0x0.
SYSLEN = 17             ! kernel take the max sector numbers.

entry start

start:
    jmpi    go, #BOOTSEG    ! Jump to 0x7c0:go. Before the running of this program, all segment registers' value is zero.This statement change the value of CS register to 0x7c00(origin 0).

go:
    mov     ax, cs           
    mov     ds, ax          ! Make ds and ss valued 0x7c0 segment.
    mov     ss, ax
    mov     sp, #0x400      ! Set the temporary stack pointer. The value must be greater than the end of program and there just is some space. 

! Load kernel to the begin of memory address 0x10000.
load_system:
    mov     dx, #0x0000     ! Utilizing the interrupt 0x13 function 2 of BIOS reads the head code from start device.
    mov     cx, #0x0002     ! DH - head num; DL - driver num; CH - lower-byte(8 bit) of track num(total 10 bit)
    mov     ax, #SYSSEG     ! CL - bit 7, bit 6 are the high 2 bit of track num. Bit 5 ~ 0 is the start sector num(count from 1).
    mov     es, ax          ! ES:BX - position of buffer 
    xor     bx, bx          ! AH - sector funciton number; AL - the amount of sector
    mov     ax, #0x200+SYSLEN
    int     0x13
    jnc     ok_load         ! Continue to run if no error, else endless loop

die:
    jmp     die

! Move kernel code to memory address 0. We move totally 8KB(the length of kernel is less than 8KB)
ok_load:
    cli                     ! Close the interrupt
    mov     ax, #SYSSEG     ! Move start position DS:SI = 0x1000:0; destination position ES:DI = 0:0
    mov     ds, ax
    xor     ax, ax
    mov     es, ax
    mov     cx, #0x1000     ! Set moving totally 4K times, moving a word once
    sub     si, si
    sub     di, di
    rep     movw            ! execute repeat move instruction
! Load IDT and GDT's base address register IDTR and GDTR
    mov     ax, #BOOTSEG
    mov     ds, ax          ! Make ds point to 0x7c0 segment
    lidt    idt_48          ! Load IDTR. 6 bytes operand, 2 bytes table length, 4 bytes linear base address
    lgdt    gdt_48          ! Load GDTR. 6 bytes operand, 2 bytes table length, 4 bytes linear base address 

! Set CR0(as machine state word). Entering protect mode. Segment selector value 8 corresponds to the second segment descriptor of GDT.
    mov     ax, #0x0001     ! Set protect mode flag PE(bit 0) in CR0.
    lmsw    ax              ! Then jump to the segment of segment selector, offset is 0.
    jmpi    0, 8            ! Notice: the segment value is right now segment selector. The base address of this segment is 0.

! Below is the content of GDT.
