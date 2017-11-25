;	Author: Marcelo Bertoldi Diani
;*****************************************************************************
KMA	EQU 20h		;keypad memory address, indica ultimo endereco salvo 
KMA1	EQU 21h		;keypad memory address 1, primeiro endereco de memoria 
KMA2	EQU 22h		;keypad memory address 2, segundo endereco de memoria
KMA3 	EQU 23h		;keypad memory address 3, terceiro endereco de memoria
KMA4	EQU 24h		;keypad memory address 4, quarto endereco de memoria

DRK	EQU 25h		;data read from keypad, dado lido do keypad pela funcao ack

ADE	EQU 26h		;indica qual input esta habilitado para conversao
ADF	EQU 27h 	;flag do estado anterior do clock para o AD

ADA	EQU 0C100h	;endereco de dados do conversor AD
ADVALUE	EQU 28h		;valor lido de AD
DAA	EQU 0C400h	;endereco de dados do conversor DA
ADCOUNT	EQU 29h		;conta quantas vezes timer foi chamado (100) para gravar na memoria 
MEMEXL	EQU 2Ah		;parte inferior do endereço de memoria externa
MEMEXH	EQU 2Bh		;parte superior do endereco de memoria externa

RS	EQU 00h		;RS do LCD para ser usado como endereço 
RW	EQU 01h		;RW do LCD
ENAB	EQU 02h		;enab do LCD

ASCIIL 	EQU 2Ch		;ascii low da leitura AD 
ASCIIH 	EQU 2Dh		;ascii high da leitura AD

;*****************************************
	org 0 
	SJMP START
;*****************************************
	org 000bh
	ACALL FTM0
	RETI 
;*****************************************
	org 0013h
	ACALL FEX1
	RETI
;*****************************************
	org 0023h
	ACALL FES
	RETI 
;*****************************************
;Programa principal 
START: 	ACALL SRL 		;seta o modo serial 
	ACALL SETTM0
	MOV KMA, #21h		;move o valor do primeiro endereco de memoria do keypad

	MOV ADCOUNT, #0h	;inicia o contador de escrita na memoria como zero
	MOV MEMEXH, #0h		;inicia os enrecos de memoria como 0 
	MOV MEMEXL, #0h		 
	SETB TR0		;liga timer de 100hz 
	SETB EX0 		;liga interrupcao para o sensor otico
	SETB EX1 		;liga interrupcao para o teclado matricial 
	SETB EA
	ACALL SETDISPLAY 

LOOP:	ACALL READAD		
	ACALL WRITEDA
	ACALL HEX2ASCII
	ACALL SENDADDISPLAY 
	ACALL SENDADSERIAL 
	ACALL LIGHTLEDS
	SJMP LOOP 
;*****************************************
;rotina para acender os leds a cada 20h
LIGHTLEDS:
	MOV B, #020h
	MOV A, READAD
	DIV AB
	MOV DPL, A
	MOV DPH, #40h
	MOVX @DPTR, A
	RET
;*****************************************
;rotina que cuida da interrupcao serial 
FES:	RET
;*****************************************
;envia valor hexadecimal de cada byte lido em AD serialmente
SENDADSERIAL:
	MOV A, ASCIIH
	MOV SBUF, A
	JNB TI, $
	CLR TI 
	MOV A, ASCIIL
	MOV SBUF, A
	JNB TI, $
	CLR TI 
	RET
;*****************************************
;envia valor hexadecimal de cada byte lido em AD na mesma posicao  
SENDADDISPLAY:
	MOV A, #00h
	ACALL POS
	MOV A, ASCIIH
	ACALL SENDLCD
	MOV A, ASCIIL
	ACALL SENDLCD
	RET
;*****************************************
;rotina de conversao de dois digitos para ascii
HEX2ASCII:
	MOV A, READAD
	MOV R1, A
	ANL A, #0Fh
	ACALL CONVHEX2ASCII
	MOV ASCIIL, A
	MOV A, R1
	SWAP A
	ANL A, #0Fh
	ACALL CONVHEX2ASCII
	MOV ASCIIH, A
	RET	
;*****************************************
;rotina de conversão de um digito para ascii
CONVHEX2ASCII:
	CNJA A, #0Ah, CONVTEST
CONVTEST: 
	JC CONVNUM
	ADD A, #07h
CONVNUM:ADD A, #30h
	RET
;*****************************************
;apaga um bit de controle do LCD
CLRBITLCD:
	CJNE A, #RS, CLRBITRW
	MOV DPTR, #0A208h
	MOVX @DPTR, A
	RET
CLRBITRW:
	CJNE A, #RW, CLRBITENAB		       
	MOV DPTR, #0A210h
	MOVX @DPTR, A
	RET
CLRBITENAB:
	CJNE A, #ENAB, CLRBITEND		       
	MOV DPTR,#0A220h
	MOVX @DPTR, A
	RET 
CLRBITEND:	
	RET
;*****************************************	
;seta um bit de controle do lcd
SETBITLCD:
	CJNE A, #RS, SETBITRW
	MOV DPTR, #0A209h
	MOVX @DPTR, A
	RET
SETBITRW:
	CJNE A, #RW, SETBITENAB		       
	MOV DPTR, #0A212h
	MOVX @DPTR, A
	RET
SETBITENAB:
	CJNE A, #ENAB, SETBITEND		       
	MOV DPTR,#0A224h
	MOVX @DPTR, A
	RET 
SETBITEND:	
	RET
;*****************************************
;envia dados para o LCD
SENDLCD:MOV DPH, #0A1h
	MOV DPL, A
	MOVX @DPTR,A
	RET
;*****************************************
;funçao que inicializa o display LCD
SETDISPLAY:
	MOV A, #RW
	ACALL CLRBITLCD
	MOV A,#ENAB
	ACALL SETBITLCD
	MOV A, #RS
	ACALL CLRBITLCD
	MOV A, #38h
	ACALL SENDLCD
	MOV A,#ENAB
	ACALL CLRBITLCD
	LCALL WAIT
;**
	MOV A,#ENAB
	ACALL SETBITLCD
	MOV A, #RS
	ACALL CLRBITLCD
	MOV A, #0Eh
	ACALL SENDLCD
	MOV A,#ENAB
	ACALL CLRBITLCD
	LCALL WAIT

	MOV A,#ENAB
	ACALL SETBITLCD
	MOV A, #RS
	ACALL CLRBITLCD
	MOV A, #06h
	ACALL SENDLCD
	MOV A,#ENAB
	ACALL CLRBITLCD
	LCALL WAIT 
	RET
;*****************************************
;tempo de espera para LCD concluir execucao 
WAIT:	MOV	R2, #002h
	MOV	R1, #0DAh
	MOV	R0, #0E3h
	NOP
	DJNZ	R0, $
	DJNZ	R1, $-5
	DJNZ	R2, $-9
	MOV	R0, #098h
	DJNZ	R0, $
	RET
;*****************************************
 ;funcao de escrita de texto no lcd
WRITE:	MOV R0, A
	MOV A, #RW
	ACALL CLRBITLCD
	MOV A,#ENAB
	ACALL SETBITLCD
	MOV A, #RS
	ACALL SETBITLCD
	MOV A, R0
	ACALL SENDLCD
	MOV A,#ENAB
	ACALL CLRBITLCD
	LCALL WAIT
	RET 
;********************************
POS:	MOV R0, A
	MOV A, #RW
	ACALL CLRBITLCD
	MOV A,#ENAB
	ACALL SETBITLCD
	MOV A, #RS
	ACALL CLRBITLCD
	MOV A, R0
	ADD A, #80h
	ACALL SENDLCD
	MOV A,#ENAB
	ACALL CLRBITLCD
	LCALL WAIT
	RET
;********************************
CLEAR:	MOV A, #RW
	ACALL CLRBITLCD
	MOV A,#ENAB
	ACALL SETBITLCD
	MOV A, #RS
	ACALL CLRBITLCD
	MOV A, #01h
	ACALL SENDLCD
	MOV A,#ENAB
	ACALL CLRBITLCD
	LCALL WAIT
	RET
;**********************************
;Seta timer 0 em 100hz , mas não ativa  
SETTM0:	MOV A, TMOD
	ORL A, #00000001b	;timer 0 no modo 1 
	MOV TMOD, A
	MOV TH0, #0FFh
	MOV TL0, #0FBh
	SETB ET0
	RET
;*****************************************
;Rotina que trata de recarregar o timer em sua interrupcao 
;alem de armazenar na memoria ram o valor de AD a cada 1s 
FTM0:	MOV TH0, #0FFh
	MOV TL0, #0FBh

	MOV A, ADCOUNT			;verifica se deve ser escrito na memoria 
	CJNE A, #100d, FTM0ADD
	ACALL WRITEMEM
	MOV ADCOUNT, #0h		;zera novamente o contador 
	SJMP FTM0F	

FTM0ADD:ADD A, #01h
	MOV ADCOUNT, A

FTM0F:	MOV A, ADF			;complemente flag 
	CPL A
	MOV ADF, A

	CJNE A, #1h, FTMN1		;se o flag eh 1 
	MOV A, ADE			;pega o valor que esta selecionando o AD
	ORL A, #00001000b		;e complementa clock 
	MOV DPL, A
	MOV DPH, #0C2h
	MOVX @DPTR, A			;acessa posicao 
	RET
FTMN1:					;se o flag eh 0
	MOV A, ADE			;pega o valor que esta selecionando o AD
	ANL A, #11110111b		;e complementa clock 
	MOV DPL, A
	MOV DPH, #0C2h
	MOVX @DPTR, A			;acessa posicao 
	RET
;*****************************************
;Escreve na memoria externa o valor obtido pelo conversor AD
WRITEMEM:
	MOV DPL, MEMEXL
	MOV DPH, MEMEXH
	MOV A, ADVALUE
	MOVX @DPTR, A
	INC DPTR
	MOV A, DPH
	CJNE A, #40h, WRITEMEMRET		;checa se ja chegou no limite da memoria ram externa
	MOV DPH, #00h 
WRITEMEMRET:
	MOV MEMEXL, DPL
	MOV MEMEXH, DPH
	RET
;*****************************************
;Seta os parametros da transmissao serial
SRL:	ORL TMOD, #00100000b	;timer 1 no modo 2
	MOV TH1, #253
	SETB TR1
	MOV SCON,#01000000b	;modo 1 canal serial, baud variavel
	SETB ES			;liga interrupcao serial 
				
	RET 
;*****************************************
;le o valor no AD
READAD:	MOV DPTR, #ADA
	MOVX A, @DPTR
	MOV ADVALUE, A
	RET
;*****************************************
;escreve valor no DA
WRITEDA:MOV DPTR, #DAA
	MOV A, ADVALUE
	MOVX @DPTR, A
	RET
;*****************************************
;Rotina de interrupcao externa 1, ativada quando teclado matricial
;for pressionado  
FEX1:	MOV A, KMA
	CJNE A, #24h, FEX1ADD	;compara para saber se é ultimo input
;caso for segundo input, reseta enderco e
;chama rotina controladora de comandos do teclado matricial 
	MOV KMA, #21h
	ACALL ACK
	RET
;caso nao for ultimo, salva dado e incrementa endereco
FEX1ADD:ACALL RDK
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
	JNB A.6, TECLAA
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