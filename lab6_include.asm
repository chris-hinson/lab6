# .include this from your abc123_lab6.asm file.

# MMIO Registers
.eqv DISPLAY_CTRL 0xFFFF0000
.eqv DISPLAY_KEYS 0xFFFF0004
.eqv DISPLAY_BASE 0xFFFF0008

# Display stuff
.eqv DISPLAY_W       64
.eqv DISPLAY_H       64
.eqv DISPLAY_W_SHIFT 6

# LED Colors
.eqv COLOR_BLACK   0
.eqv COLOR_RED     1
.eqv COLOR_ORANGE  2
.eqv COLOR_YELLOW  3
.eqv COLOR_GREEN   4
.eqv COLOR_BLUE    5
.eqv COLOR_MAGENTA 6
.eqv COLOR_WHITE   7
.eqv COLOR_NONE    0xFF

# Input key flags
.eqv KEY_NONE 0x00
.eqv KEY_U    0x01
.eqv KEY_D    0x02
.eqv KEY_L    0x04
.eqv KEY_R    0x08
.eqv KEY_B    0x10


# increment the value in a register
.macro inc %reg
	addi %reg, %reg, 1
.end_macro

# decrement the value in a register
.macro dec %reg
	addi %reg, %reg, -1
.end_macro

# these all push ra as well as any registers you list after them.
# so "enter s0, s1" will save ra, s0, and s1, letting you use those s regs.
.macro enter
	addi sp, sp, -4
	sw ra, 0(sp)
.end_macro

.macro enter %r1
	addi sp, sp, -8
	sw ra, 0(sp)
	sw %r1, 4(sp)
.end_macro

.macro enter %r1, %r2
	addi sp, sp, -12
	sw ra, 0(sp)
	sw %r1, 4(sp)
	sw %r2, 8(sp)
.end_macro

.macro enter %r1, %r2, %r3
	addi sp, sp, -16
	sw ra, 0(sp)
	sw %r1, 4(sp)
	sw %r2, 8(sp)
	sw %r3, 12(sp)
.end_macro

.macro enter %r1, %r2, %r3, %r4
	addi sp, sp, -20
	sw ra, 0(sp)
	sw %r1, 4(sp)
	sw %r2, 8(sp)
	sw %r3, 12(sp)
	sw %r4, 16(sp)
.end_macro

.macro enter %r1, %r2, %r3, %r4, %r5
	addi sp, sp, -24
	sw ra, 0(sp)
	sw %r1, 4(sp)
	sw %r2, 8(sp)
	sw %r3, 12(sp)
	sw %r4, 16(sp)
	sw %r5, 20(sp)
.end_macro

.macro enter %r1, %r2, %r3, %r4, %r5, %r6
	addi sp, sp, -28
	sw ra, 0(sp)
	sw %r1, 4(sp)
	sw %r2, 8(sp)
	sw %r3, 12(sp)
	sw %r4, 16(sp)
	sw %r5, 20(sp)
	sw %r6, 24(sp)
.end_macro

# the counterpart to enter. these pop the registers, and ra, and then return.
.macro leave
	lw ra, 0(sp)
	addi sp, sp, 4
	jr ra
.end_macro

.macro leave %r1
	lw ra, 0(sp)
	lw %r1, 4(sp)
	addi sp, sp, 8
	jr ra
.end_macro

.macro leave %r1, %r2
	lw ra, 0(sp)
	lw %r1, 4(sp)
	lw %r2, 8(sp)
	addi sp, sp, 12
	jr ra
.end_macro

.macro leave %r1, %r2, %r3
	lw ra, 0(sp)
	lw %r1, 4(sp)
	lw %r2, 8(sp)
	lw %r3, 12(sp)
	addi sp, sp, 16
	jr ra
.end_macro

.macro leave %r1, %r2, %r3, %r4
	lw ra, 0(sp)
	lw %r1, 4(sp)
	lw %r2, 8(sp)
	lw %r3, 12(sp)
	lw %r4, 16(sp)
	addi sp, sp, 20
	jr ra
.end_macro

.macro leave %r1, %r2, %r3, %r4, %r5
	lw ra, 0(sp)
	lw %r1, 4(sp)
	lw %r2, 8(sp)
	lw %r3, 12(sp)
	lw %r4, 16(sp)
	lw %r5, 20(sp)
	addi sp, sp, 24
	jr ra
.end_macro

.macro leave %r1, %r2, %r3, %r4, %r5, %r6
	lw ra, 0(sp)
	lw %r1, 4(sp)
	lw %r2, 8(sp)
	lw %r3, 12(sp)
	lw %r4, 16(sp)
	lw %r5, 20(sp)
	lw %r6, 24(sp)
	addi sp, sp, 28
	jr ra
.end_macro

.data

.globl frame_counter
frame_counter:    .word 0
last_frame_time:  .word 0

.text

# --------------------------------------------------------------------------------------------------
# returns a bitwise OR of the above key constants, indicating which keys are being held down.
.globl input_get_keys
input_get_keys:
	lw	v0, DISPLAY_KEYS
	jr	ra

# -------------------------------------------------------------------------------------------------
# call once per main loop to keep the game running at a given FPS.
# a0 is the time between frames. typically 16 for 60FPS.
.globl wait_for_next_frame
wait_for_next_frame:
enter	s0
	lw	s0, last_frame_time
_wait_next_frame_loop:
	# while (sys_time() - last_frame_time) < a0 {}
	li	v0, 30
	syscall
	sub	t1, v0, s0
	bltu	t1, a0, _wait_next_frame_loop

	# save the time
	sw	v0, last_frame_time

	# frame_counter++
	lw	t0, frame_counter
	inc	t0
	sw	t0, frame_counter
leave	s0

# --------------------------------------------------------------------------------------------------
# copies the color data from display RAM onto the screen.
.globl display_update
display_update:
	sw	zero, DISPLAY_CTRL
	jr	ra

# --------------------------------------------------------------------------------------------------
# copies the color data from display RAM onto the screen, and then clears display RAM.
# does not clear the display, only the RAM so you can draw a new frame from scratch!
.globl display_update_and_clear
display_update_and_clear:
	li	t0, 1
	sw	t0, DISPLAY_CTRL
	jr	ra

# --------------------------------------------------------------------------------------------------
# quickly draw a 5x5-pixel pattern to the display without transparency.
# if it has any COLOR_NONE pixels, the result is undefined.
#	a0 = top-left x
#	a1 = top-left y
#	a2 = address of pattern (an array of 25 bytes stored row-by-row)

.globl display_blit_5x5
display_blit_5x5:
	tlti a0, 0
	tgei a0, 64
	tlti a1, 0
	tgei a1, 64

	sll	a1, a1, DISPLAY_W_SHIFT
	add	a1, a1, DISPLAY_BASE
	add	a1, a1, a0

.macro BLIT_PIXEL %off1, %off2
	lb t0, %off1(a2)
	sb t0, %off2(a1)
.end_macro

	BLIT_PIXEL 0, 0
	BLIT_PIXEL 1, 1
	BLIT_PIXEL 2, 2
	BLIT_PIXEL 3, 3
	BLIT_PIXEL 4, 4
	BLIT_PIXEL 5, 64
	BLIT_PIXEL 6, 65
	BLIT_PIXEL 7, 66
	BLIT_PIXEL 8, 67
	BLIT_PIXEL 9, 68
	BLIT_PIXEL 10, 128
	BLIT_PIXEL 11, 129
	BLIT_PIXEL 12, 130
	BLIT_PIXEL 13, 131
	BLIT_PIXEL 14, 132
	BLIT_PIXEL 15, 192
	BLIT_PIXEL 16, 193
	BLIT_PIXEL 17, 194
	BLIT_PIXEL 18, 195
	BLIT_PIXEL 19, 196
	BLIT_PIXEL 20, 256
	BLIT_PIXEL 21, 257
	BLIT_PIXEL 22, 258
	BLIT_PIXEL 23, 259
	BLIT_PIXEL 24, 260
	jr	ra

# --------------------------------------------------------------------------------------------------
# quickly draw a 5x5-pixel pattern to the display. it can have transparent
# pixels; those with COLOR_NONE (-1) will not change the display. This way you can
# have "holes" in your images.
#	a0 = top-left x
#	a1 = top-left y
#	a2 = address of pattern (an array of 25 bytes stored row-by-row)

.globl display_blit_5x5_trans
display_blit_5x5_trans:
	tlti a0, 0
	tgei a0, 64
	tlti a1, 0
	tgei a1, 64

	sll	a1, a1, DISPLAY_W_SHIFT
	add	a1, a1, DISPLAY_BASE
	add	a1, a1, a0

.macro BLIT_TRANS_PIXEL %off1, %off2
	lb   t0, %off1(a2)
	bltz t0, _transparent
	sb   t0, %off2(a1)
_transparent:
.end_macro

	BLIT_TRANS_PIXEL 0, 0
	BLIT_TRANS_PIXEL 1, 1
	BLIT_TRANS_PIXEL 2, 2
	BLIT_TRANS_PIXEL 3, 3
	BLIT_TRANS_PIXEL 4, 4
	BLIT_TRANS_PIXEL 5, 64
	BLIT_TRANS_PIXEL 6, 65
	BLIT_TRANS_PIXEL 7, 66
	BLIT_TRANS_PIXEL 8, 67
	BLIT_TRANS_PIXEL 9, 68
	BLIT_TRANS_PIXEL 10, 128
	BLIT_TRANS_PIXEL 11, 129
	BLIT_TRANS_PIXEL 12, 130
	BLIT_TRANS_PIXEL 13, 131
	BLIT_TRANS_PIXEL 14, 132
	BLIT_TRANS_PIXEL 15, 192
	BLIT_TRANS_PIXEL 16, 193
	BLIT_TRANS_PIXEL 17, 194
	BLIT_TRANS_PIXEL 18, 195
	BLIT_TRANS_PIXEL 19, 196
	BLIT_TRANS_PIXEL 20, 256
	BLIT_TRANS_PIXEL 21, 257
	BLIT_TRANS_PIXEL 22, 258
	BLIT_TRANS_PIXEL 23, 259
	BLIT_TRANS_PIXEL 24, 260
	jr	ra