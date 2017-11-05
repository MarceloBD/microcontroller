;	Author: Marcelo Bertoldi Diani
;*****************************************************************************
KMA	EQU 2000h	;keypad memory address, indica ultimo endereco salvo 
KMA1	EQU 2001h	;keypad memory address 1, primeiro endereco de memoria 
KMA2	EQU 2002h	;keypad memory address 2, segundo endereco de memoria
KMA3 	EQU 2003h	;keypad memory address 3, terceiro endereco de memoria
KMA4	EQU 2004h	;keypad memory address 4, quarto endereco de memoria

DRK	EQU 2005h	;data read from keypad, dado lido do keypad pela funcao ack

;CA1	EQU 2003h	;convertion address 1, endereco para conversao high bits
;CA2	EQU 2004h 	;convertion address 2, endereco para conversao low bits 
;CA3	EQU 2005h	;convertion address 3, endereco de saida da conversao 
	org 0 
	SJMP START
;*****************************************
	org 0013h
	ACALL FEX1
	RET
;*****************************************
;Programa principal 
START: 	ACALL SRL 

	MOV KMA, #2001h		;move o valor do primeiro endero de memoria do keypad
	
	SJMP $ 

;*****************************************
;Seta os parametros da transmissao serial
SRL:	ORL TMOD, #00100000b	;timer 1 no modo 2
	MOV TH1, #253h
	SETB TR1
	MOV SCON,#01000000b	;modo 1 canal serial, baud variavel
	RET 
;*****************************************
;Rotina de interrupcao externa 1, ativada quando teclado matricial
;for pressionado  
FEX1:	MOV A, KMA
	CJNE A, #2004h, FEX1ADD	;compara para saber se é ultimo input
;caso for segundo input, reseta enderco e
;chama rotina controladora de comandos do teclado matricial 
	MOV KMA, #2001h
	ACALL ACK
	RET
;caso nao for ultimo, salva dado e incrementa endereco
FEX1ADD:ACALL RKD 
	MOV A, KMA
	MOV R0, A
	MOV A, DRK
	MOV @R0, A

	MOV A, KMA
	ADD A, #01h		
	MOV KMA, A
	RET
;*****************************************
;Funcao que le keypad e salva em DRK (data read from keypad)
RDK:	MOV A, #0FEh
	MOV R0, A
	MOV DPTR, #4000h
	MOVX @DPTR, A

	MOVX A,@DPTR
	ORL A, #0Fh
	CJNE A, #0FFh, RDKKEY
	SJMP RDK 
;*****************************************
RDKKEY: JNB A.4, TECLA1
	JNB A.5, TECLA5
	JNB A.6, TECLA6
	JNB A.7, TECLAD
	MOV A, R0
	RLC A
	MOV R0, A
	JNB A.4, TECLA2
	JNB A.5, TECLA6
	JNB A.7, TECLAE
	MOV A, R0
	RLC A
	MOV R0, A
	JNB A.4, TECLA3
	JNB A.5, TECLA7
	JNB A.6, TECLAB
	JNB A.7, TECLAF
	MOV A, R0
	RLC A
	MOV R0, A
	JNB A.4, TECLA0
	JNB A.5, TECLA4
	JNB A.6, TECLA8
	JNB A.7,TECLAC
	LJMP RDK
;*****************************************
TECLA0:	MOV A,#00h
	MOV DRK, A
	RET
TECLA1:	MOV A,#01h
	MOV DRK, A
	RET
TECLA2:	MOV A,#02h
	MOV DRK, A
	RET
TECLA3:	MOV A,#03h
	MOV DRK, A
	RET
TECLA4:	MOV A,#04h
	MOV DRK, A
	RET
TECLA5:	MOV A,#05h
	MOV DRK, A
	RET	
TECLA6:	MOV A,#06h
	MOV DRK, A
	RET
TECLA7:	MOV A,#07h
	MOV DRK, A
	RET
TECLA8:	MOV A,#08h
	MOV DRK, A
	RET
TECLA9:	MOV A,#09h
	MOV DRK, A
	RET
TECLAA:	MOV A,#0Ah
	MOV DRK, A
	RET
TECLAB:	MOV A,#0Bh
	MOV DRK, A
	RET
TECLAC:	MOV A,#0Ch
	MOV DRK, A
	RET
TECLAD:	MOV A,#0Dh
	MOV DRK, A
	RET
TECLAE:	MOV A,#0Eh
	MOV DRK, A
	RET
TECLAF:	MOV A,#0Fh
	MOV DRK, A
	RET
;*****************************************
;Action controller of keypad, controla as acoes provenientes de 
;entradas no teclado matricial 
ACK:
;identificacao de 3F4Dh, caso passe dispara processo 
	MOV A, KMA1
	CJNE A, #03h, ACKE
	MOV A, KMA2
	CJNE A, #0Fh, ACKE
	MOV A, KMA3
	CJNE A, #04h, ACKE
	MOV A, KMA4
	CJNE A, #0Dh, ACKE
	;FUNCAO QUE DISPARA PROCESSO 
	RET
ACKE:	
;identificacao de E123h
	MOV A, KMA1
	CJNE A, #0Eh, ACKF
	MOV A, KMA2
	CJNE A, #01h, ACKF
	MOV A, KMA3
	CJNE A, #02h, ACKF
	MOV A, KMA4
	CJNE A, #03h, ACKF

	MOV DPTR, #KEM
	ACALL SEND
	;FUNCAO PARA ENVIAR PARA O DISPLAY LCD

ACKF:	RET 
;*****************************************
SEND:	
;Envia dados via serial 
SENDL:	MOV A, #00h
	MOVC A, @A+DPTR
	CJNE A, #'$', SENDC		;Envia dados ate achar o cifrao 
	RET

SENDC:	MOV SBUF, A	
	JNB TI, $
	CLR TI
	INC DPTR
	ACALL SENDL
;*****************************************
KEM:	DB 'Programa suspenso$'		;keypad end message, mensagem de termino via teclado matricial 
	END