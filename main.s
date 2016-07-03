@SCHKUZ002 MLKTSH012

	.syntax unified
	.global _start

vectors:
	.word 0x20002000
	.word _start + 1

_start:
	@ The following block enables the GPIOB and GPIOA by setting the 18th and 17ths bit of the RCC_AHBENR
	LDR R0, =0x40021000								@ R0 = RCC base address
	LDR R1, [R0, #0x14]								@ R1 = RCC_AHBENR			
	LDR R2, =0b1100000000000000000					@ 17th & 18th bit high (Clock Port A & Port B)
	ORRS R1, R1, R2 								@ Force 17th & 18th bit (IOBEN) high	
	STR R1, [R0,#0x14]								@ Write back to RCC_AHBENR

	LDR R3, =#1

	LDR R0, =0x48000400								@ R0 = GPIOB base address
	LDR R1, [R0, #0x00]								@ R1 = GPIOB_MODER
	LDR R2, =0b0101010101010101						@ Pattern to set first 8 pairs of bits to be 01 (output)
	ORRS R1, R1, R2									@ Force the bits high, leaving the other bits unchanged
	STR R1, [R0, #0x00]								@ Write back to GPIOB_MODER

	LDR R6, =0x48000000								@ R0 = GPIOA base address		
	LDR R7, [R6, #0x00]								@ R1 = GPIOA_MODER
	LDR R2, =0b0000000000000000 					@ Pattern to set all bits to be 00 (input)
	ORRS R7, R7, R2									@ Force the bits low, leaving the other bits unchanged
	STR R7, [R6]									@ Write back to GPIOA_MODER

	LDR R6, =0x48000000								@ R0 = GPIOA base address
	LDR R7, [R6, #0x0C]								@ R1 = GPIOA_PUPDR
	LDR R2, =0b0000000001000000						@ Pattern to set switch 3 to be 01 (input)
	ORRS R7, R7, R2									@ Force the bit high, leaving the other bits unchanged
	STR R7, [R6, #0x0C]								@ Write back to GPIOA_PUPDR

	LDR R5, =0b0000000000001000						@ R5 = Switch press pattern (SW3 pressed)
	LDR R7, =#0										@ R6 = Display Number

all_off:
	@ Read in the data from GPIOB_ODR, force the lower byte to 0 and write back
    LDR R1, [R0, #0x14]                 			@ R1 = GPIOB_ODR (R0 still contains GPIOB base address from above)
    LDR R2, =0xFFFFFF00								@ Pattern which will leave upper 3 bytes unchanged while clearing lower byte                 
    ANDS R1, R1, R2                     			@ Clear lower byte of ODR
    STR R1, [R0, #0x14]								@ Write back to GPIOB_ODR 

init_display:
	@ R2 already contains the pattern on the LEDs - just OR it with 0xA
	MOVS R2, #0xA
	STR R2, [R0,#0x14]								@ Write back to GPIOB_ODR
	B main_loop

button_press:
	@ Routine for decrementing the value in the R2 register, during a button press
	SUBS R2, R2, R3									@ R2 = R2 - #0x1
	B sub_display									@ Branch to routine to display the 

button_nopress:
	@ Routine for incrementing the value in the R2 register, in the absence of a button press
	ADDS R2, R2, R3									@ R2 = R2 + #0x1
	B add_display									@ Branch to LED Display Routine (ADD MODE)

add_display:
	STR R2, [R0,#0x14]								@ R2 = LED display value
	CMP R2, #21										@ Compare LED value against lower boundary (When LED's display 20)
	BEQ display_10									@ Wrap around to 10 via display_10 routine
	B end											@ Branch to end

sub_display:
	STR R2, [R0,#0x14]								@ R2 = LED display value
	CMP R2, #9										@ Compare LED value against lower boundary (When LED's display 10)
	BEQ display_20									@ Wrap around to 20 via display_20 routine
	B end											@ Branch to end

display_10:
	@ This block initialises the LEDs to 10 after wrapping around via the increment method
	MOVS R2, #0xA									@ R2 = LED Display = 10
	STR R2, [R0,#0x14]								@ Write back to GPIOB_ODR
	B end											@ Branch to end

display_20:
	@ This block initialises the LEDs to 20 after wrapping around via the decrement method
	MOVS R2, #0x14									@ R2 = LED Display = 20
	STR R2, [R0,#0x14]								@ Write back to GPIOB_ODR
	B end           								@ Branch to end     

check_switch:	
	LDR R6, =0x48000000								@ R0 = GPIOA base address
	LDR R7, [R6, #0x10]								@ R1 = GPIOA_IDR
	ANDS R7, R7, R5									@ Set button press indicator (R7 = 8 = no_press, R7 = 0 = press)
	CMP R7, #0 										@ Compare R7 to press value (0)
	BEQ button_press 								@ Branch to button_press routine
	CMP R7, #8										@ Compare R7 to no press value (8)
	BEQ	button_nopress								@ Branch to button_nopress routine

main_loop:
	@ Infinite loop to check switch then perform the require routine
	B check_switch									@ Branch to check_switch routine
end: B main_loop									@ Loop back to start of main routine (infinte loop)
