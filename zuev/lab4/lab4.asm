AStack SEGMENT STACK
	dw 256 dup (?)
AStack ENDS

DATA SEGMENT
		LOAD_RES 		db	'Resident interrupt is loaded',0Dh,0Ah,'$'
		UNLOAD_RES 		db	'Resident interrupt is unloaded',0Dh,0Ah,'$'
		LOAD_RES_ER 	db	'Resident interrupt is already loaded',0Dh,0Ah,'$'
		UNLOAD_RES_ER	db	'Resident interrupt is not loaded',0Dh,0Ah,'$'
DATA ENDS

CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, SS:AStack

TETR_TO_HEX PROC near
		and AL,0Fh
		cmp AL,09
		jbe NEXT
		add AL,07
NEXT: 	add AL,30h
		ret
TETR_TO_HEX ENDP
;-------------------------------
BYTE_TO_HEX PROC near
		push CX
		mov AH,AL
		call TETR_TO_HEX
		xchg AL,AH
		mov CL,4
		shr AL,CL
		call TETR_TO_HEX
		pop CX 
		ret
BYTE_TO_HEX ENDP
;-------------------------------
WRD_TO_HEX PROC near
		push BX
		mov BH,AH
		call BYTE_TO_HEX
		mov [DI],AH
		dec DI
		mov [DI],AL
		dec DI
		mov AL,BH
		call BYTE_TO_HEX
		mov [DI],AH
		dec DI
		mov [DI],AL
		pop BX
		ret
WRD_TO_HEX ENDP
;-------------------------------
getCurs PROC near
		push AX
		push BX
		push CX
		mov AH, 03h
		mov BH, 0
		int 10h
		pop CX
		pop BX
		pop AX
		ret
getCurs ENDP
;-------------------------------
setCurs PROC near
		push AX
		push BX
		push CX
		push DX
		mov AH, 02h
		mov BH, 0
		mov DH, 22
		mov DL, 0
		int 10h
		pop CX
		pop DX
		pop BX
		pop AX
		ret
setCurs ENDP
;-------------------------------
outputBP proc near
		push AX
		push BX
		push CX
		push DX
		mov AH, 13h
		mov AL, 1
		mov BH, 0
		mov DH, 10
		mov DL, 22
		mov CX, 40
		int 10h
		pop DX
		pop CX
		pop BX
		pop AX
		ret
outputBP  endp 
;-------------------------------
ROUT PROC far
		jmp begin
		KEEP_PSP	dw 0
		KEEP_SS		dw 0
		KEEP_SP		dw 0
		KEEP_CS 	dw 0
		KEEP_IP 	dw 0
		SIGNATURE	dw 1234h
		COUNTER 	dw 0
		RES_STRING	db 'The interrupt is triggered by      times$'
		INTERRUPT_STACK dw 64 dup (?)
		STACK_PTR:
	
begin:
		mov KEEP_SP, SP
		mov KEEP_SS, SS
		mov AX, seg INTERRUPT_STACK
		mov SS, AX
		mov SP,   offset STACK_PTR
	
		push AX
		push BX
		push CX
		push DX
		
		call getCurs
		push DX
		call setCurs
		
		push DS
		mov AX, seg COUNTER
		mov DS, AX
		mov AX, COUNTER
		inc AX
		mov COUNTER, AX
		
		push DI
		mov DI, offset RES_STRING+34
		call WRD_TO_HEX
		pop DI
		pop DS
		
		push ES
		push BP
		mov AX, seg RES_STRING
		mov ES, AX
		mov BP, offset RES_STRING
		call outputBP
		pop BP
		pop ES
		
		pop DX
		mov AH, 02h
		mov BH, 0
		int 10h
		
		pop CX
		pop DX
		pop BX
		pop AX
		mov SP, KEEP_SP
		mov SS, KEEP_SS
		
		mov AL, 20h
		out 20h, AL
		iret
ROUT ENDP
;-------------------------------
LAST_BYTE:
;-------------------------------
PRINT PROC near
		push AX
		mov AH,09h
		int 21h
		pop AX
		ret
PRINT ENDP
;-------------------------------
LOAD_ROUT PROC far
		push AX
		push BX
		push DX
		push ES
		push DS
		
		mov AH, 35h
		mov AL, 1Ch
		int 21h
		
		mov KEEP_IP, BX
		mov KEEP_CS, ES
		
		mov DX, offset ROUT
		mov AX, seg ROUT
		mov DS, AX
		mov AH, 25h
		mov AL, 1Ch
		int 21h
		
		pop DS
		mov DX, offset LOAD_RES
		call PRINT
		
		pop ES
		pop DX
		pop BX
		pop AX
		ret
LOAD_ROUT ENDP
;-------------------------------
KEEP_ROUT PROC
		mov DX, offset LAST_BYTE
		mov CL, 4
		shr DX, CL
		inc DX
		add DX, CODE
		sub DX, KEEP_PSP
		mov AX, 3100h
		int 21h
		ret
KEEP_ROUT ENDP
;-------------------------------
UNLOAD_ROUT PROC near
		cli
		push DS
		mov DX, ES:KEEP_IP
		mov AX, ES:KEEP_CS
		mov DS, AX 
		mov AH, 25h 
		mov AL, 1Ch 
		int 21h 
		pop DS
		
		mov ES, ES:KEEP_PSP 
		push ES
		mov ES, ES:[2Ch]  
		mov AH, 49h     
		int 21h 	
		pop ES
		int 21h
		sti

		mov DX,offset UNLOAD_RES
		call PRINT
		ret
UNLOAD_ROUT ENDP
;-------------------------------
CHECK PROC
		push AX
		push BX
		push DX
		cmp byte ptr ES:[82h],'/'
		jne load
		cmp byte ptr ES:[83h],'u'
		jne load
		cmp byte ptr ES:[84h],'n'
		jne load
		jmp unload
load: 	
		
		mov AH, 35h
		mov AL, 1ch
		int 21h
		mov SI, offset SIGNATURE
		sub SI, offset ROUT
		mov AX, 1234h
		cmp AX, ES:[BX+SI]
		je load_err
		call LOAD_ROUT
		call KEEP_ROUT
		jmp end_ch
load_err:
		mov DX, offset LOAD_RES_ER
		call PRINT
		jmp end_ch
unload:
		mov AH, 35h
		mov AL, 1ch
		int 21h
		mov SI, offset SIGNATURE
		sub SI, offset ROUT
		mov AX, 1234h
		cmp AX, ES:[BX+SI]
		jne unload_err
		call UNLOAD_ROUT
		jmp end_ch
unload_err:
		mov DX, offset UNLOAD_RES_ER
		call PRINT
end_ch:
		pop DX
		pop BX
		pop AX
		ret
CHECK ENDP
;-------------------------------
MAIN PROC near
		mov KEEP_PSP, ES
		mov AX, seg DATA
		mov DS, AX
		call CHECK
		mov AX,4C00h
		int 21h
		ret
MAIN ENDP
CODE ENDS
END MAIN