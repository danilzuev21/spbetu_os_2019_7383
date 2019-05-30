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

ROUT PROC far
		jmp begin
		KEEP_PSP	dw 0
		SIGNATURE	dw 1234h
		KEEP_IP		dw 0
		KEEP_CS		dw 0
		KEEP_AX		dw 0
		KEEP_SS		dw 0
		KEEP_SP		dw 0
		REQ_KEY_A	db 1Eh
		REQ_KEY_B	db 30h
		REQ_KEY_C	db 2Eh
		REQ_KEY_D	db 20h
		INTERRUPT_STACK dw 64 dup (?)
		STACK_PTR:
	
begin:
		mov KEEP_AX, AX
		mov KEEP_SS, SS
		mov KEEP_SP, SP
		mov AX, seg INTERRUPT_STACK
		mov SS, AX
		mov SP,   offset STACK_PTR
		mov AX, KEEP_AX
		push AX 
		push DX
		push DS
		push ES
		
		in AL, 60h
		cmp AL, REQ_KEY_A
		je do_req_A
		cmp AL, REQ_KEY_B
		je do_req_B
		cmp AL, REQ_KEY_C
		je do_req_C
		cmp AL, REQ_KEY_D
		je do_req_D
		
		pushf
		call dword ptr CS:KEEP_IP 
		jmp end_root

do_req_A:
		mov CL, 'A'
		jmp do_req
do_req_B:
		mov CL, 'B'
		jmp do_req		
do_req_C:
		mov CL, 'C'
		jmp do_req
do_req_D:
		mov CL, 'D'
		
do_req: ;отработка аппаратного прерывания
		push AX
		push ES
		in AL, 61h
		mov AH, AL
		or AL, 80h
		out 61h, AL
		xchg AH, AL
		out 61h, AL
		mov AL, 20h
		out 20h, AL
	
		mov	AX, 0040h
		mov ES, AX
		mov AX, ES:[17h]
		and AL, 00000011b
		cmp AL, 0
		je shift_is_not_pushed
		mov CH, 1
shift_is_not_pushed:
		cmp CH, 0
		je 	no_changes
		add CL, 20h
no_changes:		
		pop ES
		pop AX
			
add_sym_to_buff:
		mov AH, 05h
		mov CH, 00h
		int 16h
		or AL, AL
		jz end_root
		
		mov AX, 0040h
		mov ES, AX
		mov AX, ES:[1Ah]
		mov ES:[1Ch], AX
		jmp add_sym_to_buff

end_root:	
		pop ES 
		pop DS
		pop DX
		pop AX 
		mov SS, KEEP_SS
		mov SP, KEEP_SP
		mov AL,20h
		out 20h,AL
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
		mov AL, 09h
		int 21h
		
		mov KEEP_IP, BX
		mov KEEP_CS, ES
		
		mov DX, offset ROUT
		mov AX, seg ROUT
		mov DS, AX
		mov AH, 25h
		mov AL, 09h
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
		mov AL, 09h 
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
		mov AL, 09h
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
		mov AL, 09h
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