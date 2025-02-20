;**********************************************************************************	
; Program name: A Simple Automated Home Garden Irrigation System
;
; Program description: This program represents an environment-aware fully-automa-
; ted home garden irrigation system using PIC16F877A that is supposed to manage a
; garden with two zones, each containing a different plant
;
; Created by: Yusuf Qwareeq and Osama Abuhamdan
;
; Date last revised: December 7th, 2019
;**********************************************************************************
; Inputs:
; 		Manual/automated button: RB4
; 		Pump 1 button: RB6
; 		Pump 2 button: RB5
; 		LCD zone 1/2 button: RB7
; 		Temperature sensor (potentiometer): RA5 (AN4)
; 		Zone 1 pH sensor (potentiometer): RA1 (AN1)
; 		Zone 1 humidity sensor (potentiometer): RA0 (AN0)
; 		Zone 2 pH sensor (potentiometer): RA3 (AN3)
; 		Zone 2 humidity sensor (potentiometer): RA2 (AN2)
; Outputs:
;		LCD: PORTD, pins 0-7 and PORTE, pins 0-2
;		Pump 1 LED: RC0
;		Pump 2 LED: RC1
;		Frost alert (red) LED: RC2
;**********************************************************************************
	__CONFIG _DEBUG_OFF&_CP_OFF&_WRT_HALF&_CPD_OFF&_LVP_OFF&_BODEN_OFF&_PWRTE_OFF&_WDT_OFF&_XT_OSC
;**********************************************************************************
	INCLUDE "P16F877A.INC"
;**********************************************************************************
; cblock assignments.
;**********************************************************************************
	cblock	0x20
TEMP1
TEMP2
DCOUNTER
COUNTER
RESULT
MODE
TEMPERATURE
PH1
HUMIDITY1
PUMP1_MODE
PH2
HUMIDITY2
PUMP2_MODE
FROST_STATUS
FAULT_STATUS
MSD
LSD
ZONE
D1
D2
D3
HUNDS
TENS
ONES
FRACTION_STATUS
NEGATIVE_STATUS
OLD_PORTB
NEW_PORTB
PH1_RBA
PH2_RBA
	endc
;**********************************************************************************
; Start of executable code.
;**********************************************************************************
	org 0x000
	goto MAIN
	org 0x004
	goto ISR
MAIN
	call INITIAL
;**********************************************************************************
; LOOP subroutine: Checks if the system is in automatic or manual mode.
;**********************************************************************************
LOOP
	banksel MODE
	btfss MODE,0
	goto AUTO
	btfsc MODE,0
	goto MANUAL
	goto LOOP
;**********************************************************************************
; INITIAL subroutine: Disables the annoying "Register in operand not in bank 0.  E-
;					  nsure that bank bits are correct." message.
;					  Configures I/O ports.
;					  Configures LCD module.
;					  Enables TMR0 overflow interrupt.
;					  Enables PORTB change interrupt.
;					  Turns on the A/D module and configures it.
;					  Sets mode as automatic.
;					  Turns both pumps off.
;					  Configures Timer0 module.
;**********************************************************************************
INITIAL
	errorlevel -302
	banksel TMR0
	movlw .178
	movwf TMR0
	movlw .150
	movwf COUNTER
	clrf FROST_STATUS
	clrf FAULT_STATUS
	clrf PUMP1_MODE
	clrf PUMP2_MODE
	clrf MODE
	clrf OLD_PORTB
	banksel TRISA
	movlw b'11111111'
	movwf TRISA
	movlw b'11110000'
	movwf TRISB
	clrf TRISE
	clrf TRISC
	clrf TRISD
	banksel ADCON1
	movlw b'00000010'
	movwf ADCON1
	banksel PORTB
	movf PORTB,w
	bcf INTCON,RBIF
	bsf INTCON,RBIE
	bsf INTCON,TMR0IE
	bsf INTCON,PEIE
	bsf INTCON,GIE
	banksel OPTION_REG
	movlw b'11000100'
	movwf OPTION_REG
	banksel PORTC
	clrf PORTC
	clrf PORTD
	movlw b'01100001'
	movwf ADCON0
	movlw 0x38
	call SEND_CMD
	movlw 0x0C
	call SEND_CMD
	movlw 0x02
	call SEND_CMD
	movlw 0x01
	call SEND_CMD
	call SHOW_AUTO_ON_LCD
	return
;**********************************************************************************
; MANUAL subroutine
;**********************************************************************************
MANUAL
	call SHOW_MAN_ON_LCD
MAN_WORK
	goto AUTO_WORK
;**********************************************************************************
; AUTO subroutine
;**********************************************************************************
AUTO
	call SHOW_AUTO_ON_LCD
AUTO_WORK
	call CONVERT_TEMPERATURE
	call CONVERT_HUMIDITY1
	call CONVERT_HUMIDITY2
	call CONVERT_PH1
	call CONVERT_PH2
	call CHECK_FOR_FROST
	call CHECK_FOR_FAULT
	call RBA1
	call RBA2
	goto LOOP
;**********************************************************************************
; CONVERT_TEMPERATURE subroutine: Configures the ADC to convert the analog input of
;								  the TEMPERATURE sensor to a digital value and ad-
;								  justs it to match the given transfer function.
;**********************************************************************************
CONVERT_TEMPERATURE
	banksel ADCON0
	bcf FRACTION_STATUS,0
	bcf NEGATIVE_STATUS,0
	movlw b'01100001'
	movwf ADCON0
	call DELAY
	bsf ADCON0,GO
WAIT_TEMPERATURE
	btfss PIR1,ADIF
	goto WAIT_TEMPERATURE
	bcf PIR1,ADIF
	movf ADRESH,w
	call DIV10
	bcf STATUS,C
	rlf RESULT,f
	bcf STATUS,C
	rlf RESULT,f
	movf RESULT,w
	movwf TEMPERATURE
	call FROST
	call FAULT
	call DISPLAY_TEMP
	return
;**********************************************************************************
; CONVERT_HUMIDITY1 subroutine: Configures the ADC to convert the analog input of
;								the HUMIDITY1 sensor to a digital value and adjusts
;								it to match the given transfer function.
;**********************************************************************************
CONVERT_HUMIDITY1
	banksel ADCON0
	bcf FRACTION_STATUS,0
	bcf NEGATIVE_STATUS,0
	movlw b'01000001'
	movwf ADCON0
	call DELAY
	bsf ADCON0,GO
WAIT_HUMIDITY1
	btfss PIR1,ADIF
	goto WAIT_HUMIDITY1
	bcf PIR1,ADIF
	movf ADRESH,w
	call DIV10
	bcf STATUS,C
	rlf RESULT,f
	bcf STATUS,C
	rlf RESULT,f
	movf RESULT,w
	movwf HUMIDITY1
	btfss ZONE,0
	call DISPLAY_HUMIDITY1
	return
;**********************************************************************************
; CONVERT_HUMIDITY2 subroutine: Configures the ADC to convert the analog input of
;								the HUMIDITY2 sensor to a digital value and adjusts
;								it to match the given transfer function.
;**********************************************************************************
CONVERT_HUMIDITY2
	banksel ADCON0
	bcf FRACTION_STATUS,0
	bcf NEGATIVE_STATUS,0
	movlw b'01010001'
	movwf ADCON0
	call DELAY
	bsf ADCON0,GO
WAIT_HUMIDITY2
	btfss PIR1,ADIF
	goto WAIT_HUMIDITY2
	bcf PIR1,ADIF
	movf ADRESH,w
	call DIV10
	bcf STATUS,C
	rlf RESULT,f
	bcf STATUS,C
	rlf RESULT,f
	movf RESULT,w
	movwf HUMIDITY2
	btfsc ZONE,0
	call DISPLAY_HUMIDITY2
	return
;**********************************************************************************
; CONVERT_PH1 subroutine: Configures the ADC to convert the analog input of the PH1
;						  sensor to a digital value ranging from 0-15.
;**********************************************************************************
CONVERT_PH1
	banksel ADCON0
	bcf FRACTION_STATUS,0
	bcf NEGATIVE_STATUS,0
	movlw b'01001001'
	movwf ADCON0
	call DELAY
	bsf ADCON0,GO
WAIT_PH1
	btfss PIR1,ADIF
	goto WAIT_PH1
	bcf PIR1,ADIF
	movf ADRESH,w
	movwf PH1
	bcf STATUS,C
	rrf PH1,f
	bcf STATUS,C
	rrf PH1,f
	bcf STATUS,C
	rrf PH1,f
	movf PH1,f
	movlw .1
	btfss STATUS,Z
	subwf PH1,f
	movf PH1,w
	movwf PH1_RBA
	btfsc PH1,0
	bsf FRACTION_STATUS,0
	bcf STATUS,C
	rrf PH1,f
	btfss ZONE,0
	call DISPLAY_PH1
	return
;**********************************************************************************
; CONVERT_PH2 subroutine: Configures the ADC to convert the analog input of the PH2
;						  sensor to a digital value ranging from 0-15.
;**********************************************************************************
CONVERT_PH2
	banksel ADCON0
	bcf FRACTION_STATUS,0
	bcf NEGATIVE_STATUS,0
	movlw b'01011001'
	movwf ADCON0
	call DELAY
	bsf ADCON0,GO
WAIT_PH2
	btfss PIR1,ADIF
	goto WAIT_PH2
	bcf PIR1,ADIF
	movf ADRESH,w
	movwf PH2
	bcf STATUS,C
	rrf PH2,f
	bcf STATUS,C
	rrf PH2,f
	bcf STATUS,C
	rrf PH2,f
	btfsc ZONE,0
	movf PH2,f
	movlw .1
	btfss STATUS,Z
	subwf PH2,f
	movf PH2,w
	movwf PH2_RBA
	btfsc PH2,0
	bsf FRACTION_STATUS,0
	bcf STATUS,C
	rrf PH2,f
	btfsc ZONE,0
	call DISPLAY_PH2
	return
;**********************************************************************************
; TABLE subroutine: Used to get the address of the digits from CGRAM.
;**********************************************************************************
TABLE
	addwf PCL,f
	retlw '0'
	retlw '1'
	retlw '2'
	retlw '3'
	retlw '4'
	retlw '5'
	retlw '6'
	retlw '7'
	retlw '8'
	retlw '9'
;**********************************************************************************
; DIV10 subroutine: Divides the value in register TEMP1 by ten.
;**********************************************************************************
DIV10
	clrf RESULT
	movwf TEMP1
DIV_AGAIN
	movlw .10
	subwf TEMP1,f
	btfss STATUS,C
	goto DIV_DONE
	incf RESULT,f
	goto DIV_AGAIN
DIV_DONE
	return
;**********************************************************************************
; DELAY subroutine: This subroutine was taken from the A/D module experiment and it
; 					ensures the required acquisition time has passed.
;**********************************************************************************
DELAY
  	movlw 0xFF
  	movwf TEMP1
L1
	decfsz TEMP1,f
	goto L1
	return
;**********************************************************************************
; FROST subroutine: Checks if frosting is happening.
;**********************************************************************************
FROST
	movf TEMPERATURE,w
	sublw .45
	btfsc STATUS,C
	bsf FROST_STATUS,0
	btfss STATUS,C
	bcf FROST_STATUS,0
	return
;**********************************************************************************
; FAULT subroutine: Checks for faulty sensor.
;**********************************************************************************
FAULT
	movf TEMPERATURE,w
	sublw .90
    btfss STATUS,C
    bsf FAULT_STATUS,0
    btfsc STATUS,C
    bcf FAULT_STATUS,0
	return
;**********************************************************************************
; ISR subroutine: Decides which interrupt happened and acts accordingly.
;**********************************************************************************
ISR
	banksel INTCON
	call DEBOUNCE
	btfsc INTCON,TMR0IF
	goto FLASH_FROST_LED
	movf PORTB,w
	movwf NEW_PORTB
	xorwf OLD_PORTB,f
	btfsc OLD_PORTB,7
	call CHANGE_ZONE
	btfsc OLD_PORTB,6
	call CHANGE_PUMP2_LED
	btfsc OLD_PORTB,5
	call CHANGE_PUMP1_LED
	btfsc OLD_PORTB,4
	call CHANGE_MODE
	movf NEW_PORTB,w
	movwf OLD_PORTB
	movf PORTB,w
	bcf INTCON,RBIF
	retfie
CHANGE_ZONE
	btfss PORTB,7
	return
	comf ZONE,f
	return
CHANGE_PUMP2_LED
	btfss PORTB,6
	return
	btfss MODE,0
	return
	comf PUMP2_MODE,f
	btfsc PUMP2_MODE,0
	bsf PORTC,1
	btfss PUMP2_MODE,0
	bcf PORTC,1
	return
CHANGE_PUMP1_LED
	btfss PORTB,5
	return
	btfss MODE,0
	return
	comf PUMP1_MODE,f
	btfsc PUMP1_MODE,0
	bsf PORTC,0
	btfss PUMP1_MODE,0
	bcf PORTC,0
	return
CHANGE_MODE
	btfss PORTB,4
	return
	comf MODE,f
	bcf PORTC,0
	bcf PORTC,1
	return
FLASH_FROST_LED
	bcf INTCON,TMR0IF
	movlw .178
	movwf TMR0
	btfss FROST_STATUS,0
	goto NO_FROST
	decfsz COUNTER,f
	retfie
	movlw b'00000100'
	xorwf PORTC,f
	movlw .150
	movwf COUNTER
	retfie
NO_FROST
	decfsz COUNTER,f
	bcf PORTC,2
	retfie
;**********************************************************************************
; SHOW_AUTO_ON_LCD subroutine: Displays 'AUTO MODE' on the first line of the LCD.
;**********************************************************************************
SHOW_AUTO_ON_LCD
	movlw 0x80
	call SEND_CMD
	movlw 'A'
	call SEND_CHAR
	movlw 'U'
	call SEND_CHAR
	movlw 'T'
	call SEND_CHAR
	movlw 'O'
	call SEND_CHAR
	movlw ' '
	call SEND_CHAR
	movlw 'M'
	call SEND_CHAR
	movlw 'O'
	call SEND_CHAR
	movlw 'D'
	call SEND_CHAR
	movlw 'E'
	call SEND_CHAR
	movlw ' '
	call SEND_CHAR
	movlw ' '
	call SEND_CHAR
	return
;**********************************************************************************
; SHOW_MAN_ON_LCD subroutine: Displays 'MANUAL MODE' on the first line of the LCD.
;**********************************************************************************
SHOW_MAN_ON_LCD
	movlw 0x80
	call SEND_CMD
	movlw 'M'
	call SEND_CHAR
	movlw 'A'
	call SEND_CHAR
	movlw 'N'
	call SEND_CHAR
	movlw 'U'
	call SEND_CHAR
	movlw 'A'
	call SEND_CHAR
	movlw 'L'
	call SEND_CHAR
	movlw ' '
	call SEND_CHAR
	movlw 'M'
	call SEND_CHAR
	movlw 'O'
	call SEND_CHAR
	movlw 'D'
	call SEND_CHAR
	movlw 'E'
	call SEND_CHAR
	return
;**********************************************************************************
; DISPLAY_TEMP subroutine: Displays 'TEMPERATURE:' on the second line of the LCD.
;**********************************************************************************
DISPLAY_TEMP
	movlw 0xC0
	call SEND_CMD
	movlw 'T'
	call SEND_CHAR
	movlw 'E'
	call SEND_CHAR
	movlw 'M'
	call SEND_CHAR
	movlw 'P'
	call SEND_CHAR
	movlw 'E'
	call SEND_CHAR
	movlw 'R'
	call SEND_CHAR
	movlw 'A'
	call SEND_CHAR
	movlw 'T'
	call SEND_CHAR
	movlw 'U'
	call SEND_CHAR
	movlw 'R'
	call SEND_CHAR
	movlw 'E'
	call SEND_CHAR
	movlw ':'
	call SEND_CHAR
	movlw .40
	subwf TEMPERATURE,w
	btfsc STATUS,C
	goto POSITIVE
	bsf NEGATIVE_STATUS,0
	goto NEGATIVE
POSITIVE
	movlw .40
	subwf TEMPERATURE,f
NEGATIVE
	movf TEMPERATURE,w
	call DISPLAY_NUMBERS
	call DELAY_1S
	return
;**********************************************************************************
; DISPLAY_HUMIDITY1 subroutine: Displays 'Z1 HUMIDITY:' on the second line of the
;								LCD.
;**********************************************************************************
DISPLAY_HUMIDITY1
	movlw 0xC0
	call SEND_CMD
	movlw 'Z'
	call SEND_CHAR
	movlw '1'
	call SEND_CHAR
	movlw ' '
	call SEND_CHAR
	movlw 'H'
	call SEND_CHAR
	movlw 'U'
	call SEND_CHAR
	movlw 'M'
	call SEND_CHAR
	movlw 'I'
	call SEND_CHAR
	movlw 'D'
	call SEND_CHAR
	movlw 'I'
	call SEND_CHAR
	movlw 'T'
	call SEND_CHAR
	movlw 'Y'
	call SEND_CHAR
	movlw ':'
	call SEND_CHAR
	movf HUMIDITY1,w
	call DISPLAY_NUMBERS
	call DELAY_1S
	return
;**********************************************************************************
; DISPLAY_HUMIDITY2 subroutine: Displays 'Z2 HUMIDITY:' on the second line of the
;								LCD.
;**********************************************************************************
DISPLAY_HUMIDITY2
	movlw 0xC0
	call SEND_CMD
	movlw 'Z'  
	call SEND_CHAR
	movlw '2'  
	call SEND_CHAR
	movlw ' '  
	call SEND_CHAR
	movlw 'H'  
	call SEND_CHAR
	movlw 'U'  
	call SEND_CHAR
	movlw 'M'  
	call SEND_CHAR
	movlw 'I'  
	call SEND_CHAR
	movlw 'D'  
	call SEND_CHAR
	movlw 'I'  
	call SEND_CHAR
	movlw 'T'  
	call SEND_CHAR
	movlw 'Y'  
	call SEND_CHAR
	movlw ':'  
	call SEND_CHAR
	movf HUMIDITY2,w
	call DISPLAY_NUMBERS
	call DELAY_1S
	return
;**********************************************************************************
; DISPLAY_PH1 subroutine: Displays 'Z1 PH LEVEL:' on the second line of the LCD.
;**********************************************************************************
DISPLAY_PH1
	movlw 0xC0
	call SEND_CMD
	movlw 'Z'
	call SEND_CHAR
	movlw '1'
	call SEND_CHAR
	movlw ' '
	call SEND_CHAR
	movlw 'P'
	call SEND_CHAR
	movlw 'H'
	call SEND_CHAR
	movlw ' '
	call SEND_CHAR
	movlw 'L'
	call SEND_CHAR
	movlw 'E'
	call SEND_CHAR
	movlw 'V'
	call SEND_CHAR
	movlw 'E'
	call SEND_CHAR
	movlw 'L'
	call SEND_CHAR
	movlw ':'
	call SEND_CHAR
	movf PH1,w
	call DISPLAY_NUMBERS
	call DELAY_1S
	return
;**********************************************************************************
; DISPLAY_PH2 subroutine: Displays 'Z2 PH LEVEL:' on the second line of the LCD.
;**********************************************************************************
DISPLAY_PH2
	movlw 0xC0
	call SEND_CMD
	movlw 'Z'
	call SEND_CHAR
	movlw '2'
	call SEND_CHAR
	movlw ' '
	call SEND_CHAR
	movlw 'P'
	call SEND_CHAR
	movlw 'H'
	call SEND_CHAR
	movlw ' '
	call SEND_CHAR
	movlw 'L'
	call SEND_CHAR
	movlw 'E'
	call SEND_CHAR
	movlw 'V'
	call SEND_CHAR
	movlw 'E'
	call SEND_CHAR
	movlw 'L'
	call SEND_CHAR
	movlw ':'
	call SEND_CHAR
	movf PH2,w
	call DISPLAY_NUMBERS
	call DELAY_1S
	return
;**********************************************************************************
; DISPLAY_NUMBERS subroutine: Displays the numbers stored in the working register
; 							  on the LCD after properly adjusting them.
;**********************************************************************************
DISPLAY_NUMBERS
	movwf TEMP2
	btfsc NEGATIVE_STATUS,0
	call ADJUST_NEGATIVE
	call CHANGE_TO_BCD
	movf HUNDS,f
	btfsc STATUS,Z
	GOTO DISPLAY_TENS
	movf HUNDS,w
	call TABLE
	call SEND_CHAR
DISPLAY_TENS
	movf HUNDS,f
	btfss STATUS,Z
	goto IGNORE_TEST
	movf TENS,f
	btfsc STATUS,Z
	GOTO DISPLAY_ONES
IGNORE_TEST
	movf TENS,w
	call TABLE
	call SEND_CHAR
DISPLAY_ONES
	movf ONES,w
	call TABLE
	call SEND_CHAR
	btfsc FRACTION_STATUS,0
	goto ADD_0.5
	btfss FRACTION_STATUS,0
	goto REMOVE_0.5
	return
;**********************************************************************************
; CHANGE_TO_BCD subroutine: Changes numbers into BCD format.
;**********************************************************************************
CHANGE_TO_BCD
	clrf HUNDS
	clrf TENS
	clrf ONES
GEN_HUNDS
	movlw .100
	subwf TEMP2,w
	btfss STATUS,C
	goto GEN_TENS
	movwf TEMP2
	incf HUNDS,f
	goto GEN_HUNDS
GEN_TENS
	movlw .10
	subwf TEMP2,w
	btfss STATUS,C
	goto GEN_ONES
	movwf TEMP2
	incf TENS,f
	goto GEN_TENS
GEN_ONES
	movf TEMP2,w
	movwf ONES
	return
;**********************************************************************************
; SEND_CHAR subroutine: Sends a show character command to the LCD.
;**********************************************************************************
SEND_CHAR
	banksel PORTD
	movwf PORTD
	bsf PORTE,0
	bsf PORTE,2
	nop
	bcf PORTE,2
	bcf PORTE,1
	call DELAY2
	return
;**********************************************************************************
; SEND_CMD subroutine: Sends a control command to the LCD.
;**********************************************************************************
SEND_CMD
	banksel PORTD
	movwf PORTD
	bcf PORTE,0
	bsf PORTE,2
	nop
	bcf PORTE,2
	bcf PORTE,1
	call DELAY2
	return
;**********************************************************************************
; ADD_0.5 subroutine: Displays '.5' on the LCD.
;**********************************************************************************
ADD_0.5
	movlw '.'
	call SEND_CHAR
	movlw '5'
	call SEND_CHAR
	return
;**********************************************************************************
; REMOVE_0.5 subroutine: Overrides '.5' from previous runs with 3 blank spaces.
;**********************************************************************************
REMOVE_0.5
	movlw ' '
	call SEND_CHAR
	movlw ' '
	call SEND_CHAR
	movlw ' '
	call SEND_CHAR
	return
;**********************************************************************************
; ADJUST_NEGATIVE subroutine: Uses 2's complement addition to adjust negative temp-
;							  eratures.
;**********************************************************************************
ADJUST_NEGATIVE
	movlw '-'
	call SEND_CHAR
	movlw .215
	addwf TEMP2,f
	comf TEMP2,f
	return
;**********************************************************************************
; DELAY_1S subroutine: A simple one second delay. This code was taken from
;					   http://www.piclist.com/Techref/piclist/codegen/delay.htm
;**********************************************************************************
DELAY_1S
	movlw 0x08
	movwf D1
	movlw 0x2F
	movwf D2
	movlw 0x03
	movwf D3
DELAY_0
	decfsz D1,f
	goto $+2
	decfsz D2,f
	goto $+2
	decfsz D3,f
	goto DELAY_0
	goto $+1
	nop
	return
;**********************************************************************************
; DELAY2 subroutine: This code was taken from the LCD experiment to ensure enough
;					 time was given to the LCD to process the sent command.
;**********************************************************************************
DELAY2
	movlw 0x80
	movwf MSD
	clrf LSD
LOOP2
	decfsz LSD,f
	goto LOOP2
	decfsz MSD,f
	goto LOOP2
	return
;**********************************************************************************
; RBA1 subroutine: Follows the basic logic of the control table for zone 1 to deci-
;				   de whether to turn pump 1 on or off (or do nothing).
;**********************************************************************************
RBA1
	btfsc MODE,0
	return
	btfsc FROST_STATUS,0
	return
	btfsc FAULT_STATUS,0
	return
FIRST_PH1_CHECK
	movf PH1_RBA,w
    movwf TEMP2
    movlw .13
    subwf TEMP2,w
    btfsc STATUS,Z
    goto FIRST_HT_Z1_CHECKING_ZONE
    btfss STATUS,C
    goto SECOND_PH1_CHECK
    bsf PORTC,0
    goto FINISH_RBA_Z1
SECOND_PH1_CHECK
	movf PH1_RBA,w
    movwf TEMP2
    movlw .10
    subwf TEMP2,w
    btfsc STATUS,Z
    goto FIRST_HT_Z1_CHECKING_ZONE
    btfsc STATUS,C
    goto FIRST_HT_Z1_CHECKING_ZONE
    bsf PORTC,0
    goto FINISH_RBA_Z1
FIRST_HT_Z1_CHECKING_ZONE
    movlw .20
    subwf HUMIDITY1,w
    btfsc STATUS,Z
    goto SECOND_HT_Z1_CHECKING_ZONE
    btfsc STATUS,C
    goto SECOND_HT_Z1_CHECKING_ZONE
    bsf PORTC,0
    goto FINISH_RBA_Z1
SECOND_HT_Z1_CHECKING_ZONE
    movlw .35
    subwf HUMIDITY1,w
    btfsc STATUS,Z
    goto THIRD_HT_Z1_CHECKING_ZONE
    btfsc STATUS,C
    goto THIRD_HT_Z1_CHECKING_ZONE
    movlw .25
    subwf TEMPERATURE,w
    btfsc STATUS,Z
	goto EQUAL25_Z1
    btfss STATUS,C
    goto THIRD_HT_Z1_CHECKING_ZONE
EQUAL25_Z1
    bsf PORTC,0
    goto FINISH_RBA_Z1
THIRD_HT_Z1_CHECKING_ZONE
    movlw .50
    subwf HUMIDITY1,w
    btfsc STATUS,Z
    goto FORTH_HT_Z1_CHECKING_ZONE
    btfsc STATUS,C
    goto FORTH_HT_Z1_CHECKING_ZONE
    movlw .30
    subwf TEMPERATURE,w
    btfsc STATUS,Z
    goto EQUAL30_Z1
    btfss STATUS,C
    goto FORTH_HT_Z1_CHECKING_ZONE
EQUAL30_Z1
    bsf PORTC,0
    goto FINISH_RBA_Z1
FORTH_HT_Z1_CHECKING_ZONE
    movlw .65
    subwf HUMIDITY1,w
    btfsc STATUS,Z
    goto FIFTH_HT_Z1_CHECKING_ZONE
    btfsc STATUS,C
    goto FIFTH_HT_Z1_CHECKING_ZONE
    movlw .35
    subwf TEMPERATURE,w
    btfsc STATUS,Z
    goto EQUAL35_Z1
    btfss STATUS,C
    goto FIFTH_HT_Z1_CHECKING_ZONE
EQUAL35_Z1
    bsf PORTC,0
    goto FINISH_RBA_Z1
FIFTH_HT_Z1_CHECKING_ZONE
    movlw .80
    subwf HUMIDITY1,w
    btfsc STATUS,Z
    goto SIXTH_HT_Z1_CHECKING_ZONE
    btfsc STATUS,C
    goto SIXTH_HT_Z1_CHECKING_ZONE
    movlw .40
    subwf TEMPERATURE,w
    btfsc STATUS,Z
    goto EQUAL40_Z1
    btfss STATUS,C
    goto SIXTH_HT_Z1_CHECKING_ZONE
EQUAL40_Z1
    bsf PORTC,0
    goto FINISH_RBA_Z1
SIXTH_HT_Z1_CHECKING_ZONE
    movlw .95
    subwf HUMIDITY1,w
    btfsc STATUS,Z
    goto TURN_OFF_1
    btfsc STATUS,C
    goto TURN_OFF_1
    movlw .45
    subwf TEMPERATURE,w
    btfsc STATUS,Z
    goto EQUAL45_Z1
    btfss STATUS,C
    goto TURN_OFF_1
EQUAL45_Z1
    bsf PORTC,0
FINISH_RBA_Z1
    return
TURN_OFF_1
	bcf PORTC,0
	return
;**********************************************************************************
; RBA2 subroutine: Follows the basic logic of the control table for zone 2 to deci-
;				   de whether to turn pump 2 on or off (or do nothing).
;**********************************************************************************
RBA2
	btfsc MODE,0
	return
	btfsc FROST_STATUS,0
	return
	btfsc FAULT_STATUS,0
	return
FIRST_PH2_CHECK
	movf PH2_RBA,w
	movwf TEMP2
    movlw .14
    subwf TEMP2,w
    btfsc STATUS,Z
    goto FIRST_HT_Z2_CHECKING_ZONE
    btfss STATUS,C
    goto SECOND_PH2_CHECK
    bsf PORTC,1
    goto FINISH_RBA_Z2
SECOND_PH2_CHECK
	movf PH2_RBA,w
    movwf TEMP2
    movlw .9
    subwf TEMP2,w
    btfsc STATUS,Z
    goto FIRST_HT_Z2_CHECKING_ZONE
    btfsc STATUS,C
    goto FIRST_HT_Z2_CHECKING_ZONE
    bsf PORTC,1
    goto FINISH_RBA_Z2
FIRST_HT_Z2_CHECKING_ZONE
    movlw .20
    subwf HUMIDITY2,w
    btfsc STATUS,Z
    goto SECOND_HT_Z2_CHECKING_ZONE
    btfsc STATUS,C
    goto SECOND_HT_Z2_CHECKING_ZONE
    bsf PORTC,1
    goto FINISH_RBA_Z2
SECOND_HT_Z2_CHECKING_ZONE
    movlw .35
    subwf HUMIDITY2,w
    btfsc STATUS,Z
    goto THIRD_HT_Z2_CHECKING_ZONE
    btfsc STATUS,C
    goto THIRD_HT_Z2_CHECKING_ZONE
    movlw .35
    subwf TEMPERATURE,w
    btfsc STATUS,Z
    goto EQUAL35_Z2
    btfss STATUS,C
    goto THIRD_HT_Z2_CHECKING_ZONE
EQUAL35_Z2
    bsf PORTC,1
    goto FINISH_RBA_Z2
THIRD_HT_Z2_CHECKING_ZONE
    movlw .50
    subwf HUMIDITY2,w
    btfsc STATUS,Z
    goto FORTH_HT_Z2_CHECKING_ZONE
    btfsc STATUS,C
    goto FORTH_HT_Z2_CHECKING_ZONE
    movlw .40
    subwf TEMPERATURE,w
    btfsc STATUS,Z
    goto EQUAL40_Z2
    btfss STATUS,C
    goto FORTH_HT_Z2_CHECKING_ZONE
EQUAL40_Z2
    bsf PORTC,1
    goto FINISH_RBA_Z2
FORTH_HT_Z2_CHECKING_ZONE
    movlw .65
    subwf HUMIDITY2,w
    btfsc STATUS,Z
    goto TURN_OFF_2
    btfsc STATUS,C
    goto TURN_OFF_2
    movlw .45
    subwf TEMPERATURE,w
    btfsc STATUS,Z
    goto EQUAL45_Z2
    btfss STATUS,C
    goto TURN_OFF_2
EQUAL45_Z2
    bsf PORTC,1
FINISH_RBA_Z2
    return
TURN_OFF_2
	bcf PORTC,1
	return
;**********************************************************************************
; CHECK_FOR_FROST subroutine: Turns the pumps off in case frost happens during aut-
;							  omatic mode.
;**********************************************************************************
CHECK_FOR_FROST
	btfss FROST_STATUS,0
	return
	btfss MODE,0
	goto FROST_AUTO
	goto FROST_MANUAL
FROST_AUTO
	bcf PORTC,0
	bcf PORTC,1
	return
FROST_MANUAL
	return
;**********************************************************************************
; CHECK_FOR_FAULT subroutine: Turns the pumps off in case fault happens during aut-
;							  omatic mode and displays 'FAULT ALERT' message on the
;							  first line of the LCD regardless of the mode.
;**********************************************************************************
CHECK_FOR_FAULT
	btfss FAULT_STATUS,0
	return
	btfss MODE,0
	goto FAULT_AUTO
	goto FAULT_MANUAL
FAULT_AUTO
	bcf PORTC,0
	bcf PORTC,1
	call FAULT_MESSAGE
	return
FAULT_MANUAL
	call FAULT_MESSAGE
	return
;**********************************************************************************
; FAULT_MESSAGE subroutine: Displays 'FAULT ALERT' on the first line of the LCD.
;**********************************************************************************
FAULT_MESSAGE
	movlw 0x80
	call SEND_CMD
	movlw 'F'
	call SEND_CHAR
	movlw 'A'
	call SEND_CHAR
	movlw 'U'
	call SEND_CHAR
	movlw 'L'
	call SEND_CHAR
	movlw 'T'
	call SEND_CHAR
	movlw ' '
	call SEND_CHAR
	movlw 'A'
	call SEND_CHAR
	movlw 'L'
	call SEND_CHAR
	movlw 'E'
	call SEND_CHAR
	movlw 'R'
	call SEND_CHAR
	movlw 'T'
	call SEND_CHAR
	call DELAY_1S
	return
;**********************************************************************************
; DEBOUNCE subroutine: A 200 microsecond delay to solve the bouncing problem. This
;					   code was taken from:
;					   http://www.onlinepiccompiler.com/delayGeneratorENG.php
;**********************************************************************************
DEBOUNCE
	movlw 0x41
	movwf DCOUNTER
LOOP_D
	decfsz DCOUNTER,1
	goto LOOP_D
	return
;**********************************************************************************
; End of executable code.
;**********************************************************************************
	end
