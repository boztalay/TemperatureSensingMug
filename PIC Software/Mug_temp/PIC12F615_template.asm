;*******************************************************************************
;                                                                              *
;    Filename:         mug_temp.asm                                            *
;    Date:             January 16, 2011                                        *
;    File Version:     0.1                                                     *
;                                                                              *
;    Author:           Ben Oztalay                                             *
;                                                                              *
;*******************************************************************************
;                                                                              *
;    Description:      A 10-LED bar temperature sensor for a mug   			   *
;                                                                              *
;                                                                              *
;                                                                              *
;                                                                              *
;*******************************************************************************
;                                                                              *
;    Revision Information:                                                     *
;                      0.1 - File created                                      *
;                                                                              *
;                                                                              *
;                                                                              *
;*******************************************************************************
;                                                                              *
;    Pin Assignments:  Pin 2 - GPIO5, output, SR data     					   *
;                      Pin 3 - GPIO4, output, SR clock                         *
;                                                                              *
;                                                                              *
;*******************************************************************************

;------------------------------------------------------------------------------
; PROCESSOR DECLARATION
;------------------------------------------------------------------------------

     LIST      p=12F615              ; list directive to define processor
     #INCLUDE <P12F615.INC>          ; processor specific variable definitions

;------------------------------------------------------------------------------
; EXTERNALS
;------------------------------------------------------------------------------
	EXTERN  delayX10ms_R

;------------------------------------------------------------------------------
; CONFIGURATION WORD SETUP
;
; Set up for a 8 MHz clock, code protection off, brownout off, MCLR functions
; as a reset, watchdog timer is off, and GPIO 4 and 5 are I/O instead of clock
;------------------------------------------------------------------------------

     __CONFIG   _CP_OFF & _BOR_OFF & _MCLRE_ON & _WDT_OFF & _PWRTE_ON & _INTRC_OSC_NOCLKOUT

;------------------------------------------------------------------------------
; VARIABLE DEFINITIONS
;------------------------------------------------------------------------------
		UDATA

tmp_rd	res 1
tempor	res 1
loop_ct	res 1

;------------------------------------------------------------------------------
; VECTORS
;------------------------------------------------------------------------------

;Effective reset vector
START	CODE	0x0000		; processor reset vector
		pagesel START
		goto    START       ; go to beginning of program

;Subroutine vectors
delayX10ms				                                           
		pagesel delayX10ms_R                                     
		goto    delayX10ms_R 

;------------------------------------------------------------------------------
; MAIN PROGRAM
;------------------------------------------------------------------------------

MAIN	CODE
START
		
		BANKSEL TRISIO 		;
		MOVLW 	b'001111' 	;Set GP0 to input
		MOVWF	TRISIO
		BANKSEL ANSEL		;
		MOVLW	B'01010001' ;ADC Frc/16 clock,
		MOVWF 	ANSEL 		;and GP0 as analog
		BANKSEL ADCON0 		;
		MOVLW 	B'10000111' ;Right justify,
		MOVWF 	ADCON0 		;Vdd Vref, AN0, On

		banksel GPIO		;Initialize GPIO
		clrf	GPIO

loop
		movlw 	.10
		pagesel	delayX10ms
		call	delayX10ms
		pagesel	loop
	
		clrf	loop_ct
		clrf	tempor
		clrf	tmp_rd

		banksel ADCON0
		BSF 	ADCON0,GO 	;Start conversion
adc_tst	BTFSC 	ADCON0,NOT_DONE 	;Is conversion done?
		GOTO 	adc_tst		;No, test again
		BANKSEL ADRESL 		;
		MOVF 	ADRESL,W 	;Read upper 8 bits
		banksel tmp_rd
		MOVWF 	tmp_rd 	;Store in GPR space
		
;		movlw	.123
;		movwf	tmp_rd

		movlw	.115
		subwf	tmp_rd,W
		sublw	.30
		movwf	tempor

disp	
		decf	tempor
		btfsc	tempor,7
		goto	disp_blanks

		decf	tempor
		btfsc	tempor,7
		goto	disp_blanks

		decf	tempor
		btfsc	tempor,7
		goto	disp_blanks

		movlw	b'000000'
		movwf	GPIO
		movlw	b'010000'
		movwf	GPIO
		movlw	b'000000'
		movwf	GPIO

		incf	loop_ct
		goto disp

disp_blanks
		movf	loop_ct,W
		sublw	.11
		movwf	loop_ct

disp_blanks_loop
		movlw	b'100000'
		movwf	GPIO
		movlw	b'110000'
		movwf	GPIO
		movlw	b'100000'
		movwf	GPIO

		decfsz	loop_ct
		goto disp_blanks_loop

		goto loop

		END