AStack SEGMENT STACK
	dw 256 dup (?)
AStack ENDS

DATA SEGMENT

		ERROR_1_7			db	'Сontrol memory block destroyed',0Dh,0Ah,'$'
		ERROR_1_8			db	'Not enough memory to perform the function',0Dh,0Ah,'$'
		ERROR_1_9			db	'Invalid memory block address',0Dh,0Ah,'$'

		PATH			db	100 dup (0)
		DTA				db 	43 dup (?)
		BLOCK_ADDR		dw	0
		CALL_ADDR		dd	0
		
		ERROR_2_1			db	'Function doesnt exists',0Dh,0Ah,'$'
		ERROR_2_2			db	'File is not found',0Dh,0Ah,'$'
		ERROR_2_3			db	'Path is not found',0Dh,0Ah,'$'
		ERROR_2_4			db	'Too much open files',0Dh,0Ah,'$'
		ERROR_2_5			db	'There is no access',0Dh,0Ah,'$'
		ERROR_2_8			db	'Not enough memory to perform the function',0Dh,0Ah,'$'
		ERROR_2_10		db	'Wrong environment',0Dh,0Ah,'$'
		
		MEM_ERR_2		db	'File is not found',0Dh,0Ah,'$'
		MEM_ERR_3		db	'Path is not found',0Dh,0Ah,'$'
		END_2			db	'End by device error',0Dh,0Ah,'$'
		END_3			db	'End by function 31h',0Dh,0Ah,'$'
		END_CODE		db	'End code: $'
		

DATA ENDS

CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, SS:AStack

TETR_TO_HEX   PROC  near 
			and      AL,0Fh
			cmp      AL,09
			jbe      NEXT
			add      AL,07 
NEXT:  	    add      AL,30h
            ret 
TETR_TO_HEX   ENDP 
;------------------------------- 
BYTE_TO_HEX   PROC  near
            push     CX
            mov      AH,AL
            call     TETR_TO_HEX
            xchg     AL,AH
            mov      CL,4
            shr      AL,CL
            call     TETR_TO_HEX
			pop      CX
            ret 
BYTE_TO_HEX  ENDP 
;-------------------------------
PRINT PROC near
		push AX
		mov AH,09h
		int 21h
		pop AX
		ret
PRINT ENDP
;-------------------------------
PRINT_ERROR_2 PROC
		
		cmp AX, 1
		je err_2_1
		cmp AX, 2
		je err_2_2
		cmp AX, 3
		je err_2_3
		cmp AX, 4
		je err_2_4
		cmp AX, 5
		je err_2_5
		cmp AX, 8
		je err_2_8
		cmp AX, 10
		je err_2_10
err_2_1:
		mov DX, offset ERROR_2_1
		jmp end_err_2
err_2_2:
		mov DX, offset ERROR_2_2
		jmp end_err_2
err_2_3:
		mov DX, offset ERROR_2_3
		jmp end_err_2
err_2_4:
		mov DX, offset ERROR_2_4
		jmp end_err_2
err_2_5:
		mov DX, offset ERROR_2_5
		jmp end_err_2
err_2_8:
		mov DX, offset ERROR_2_8
		jmp end_err_2
err_2_10:
		mov DX, offset ERROR_2_10
		jmp end_err_2
end_err_2:
		call PRINT
		mov AX, 4C00h
		int 21h
		ret
PRINT_ERROR_2 ENDP
;-------------------------------
PRINT_ERROR_1 PROC
		
		cmp AX, 7
		je err_1_7
		cmp AX, 8
		je err_1_8
		cmp AX, 9
		je err_1_9
err_1_7:
		mov DX, offset ERROR_1_7
		jmp end_err_1
err_1_8:
		mov DX, offset ERROR_1_8
		jmp end_err_1
err_1_9:
		mov DX, offset ERROR_1_9
		jmp end_err_1
end_err_1:
		call PRINT
		mov AX, 4C00h
		int 21h
		ret
PRINT_ERROR_1 ENDP
;-------------------------------
PRINT_MEM_ERROR PROC
		cmp AX, 2
		je mem_err2
		cmp AX, 3
		je mem_err3
mem_err2:
		mov DX, offset MEM_ERR_2
		jmp end_mem_err
mem_err3:
		mov DX, offset MEM_ERR_3
end_mem_err:
		call PRINT
		mov AX, 4C00h
		int 21h		
		ret
PRINT_MEM_ERROR ENDP
;-------------------------------------------------- 
PREPARE_PLACE PROC far
		push AX
		push BX
		push CX
		push DX

		mov BX,  offset END_OF_PROGRAM
		mov AH,  4Ah
		int 21h
		jnc free_success
		call PRINT_ERROR_1
free_success:
		pop DX
		pop CX
		pop BX
		pop AX
		ret
PREPARE_PLACE ENDP
;-------------------------------------------------- 
MAKE_PATH PROC far
		push BX
		push DX
		push SI

		xor SI,  SI
		mov BX,  ES:[2Ch]
		mov ES,  BX
			
output_content:
		inc SI
		cmp WORD PTR ES:[SI], 0000h
		je end_content
		cmp BYTE PTR ES:[SI], 00h
		je not_new_line
		jmp output_content
not_new_line:
		inc SI
		jmp output_content
end_content:
		add SI,  4
		xor DI,  DI
rec_path:
		mov DL,  ES:[SI]
		cmp DL, 00h
		je end_path
		mov PATH[DI], DL
		inc DI
		inc SI
		jmp rec_path
end_path:

		sub DI,  8
		mov PATH[DI], 'o'
		mov PATH[DI+1], 'v'
		mov PATH[DI+2], 'l'
		mov PATH[DI+3], '1'
		mov PATH[DI+4], '.'
		mov PATH[DI+5], 'o'
		mov PATH[DI+6], 'v'
		mov PATH[DI+7], 'l'
		add DI, 3
					
		pop SI
		pop DX
		pop BX
		ret
MAKE_PATH ENDP
;-------------------------------------------------- 
OVL_MEM PROC near
		push AX
		push BX
		push CX
		push DX
		push DI
		push ES

		mov DX, offset PATH

		xor CX, CX
		mov AX, 4E00h
		int 21h
		jnc without_err
		call PRINT_MEM_ERROR
without_err:
		mov BX, offset DTA
		mov DX, [BX+1Ch] 
		mov AX, [BX+1Ah] 
		add AX, 15
		mov CL, 4 
		shr AX, CL
		mov CL, 12 
		sal DX, CL 
		add AX, DX 
		mov BX, AX
		mov AX, 4800h
		int 21h
		jnc end_ovl_mem
		call PRINT_ERROR_1
end_ovl_mem:
		mov BLOCK_ADDR, AX
		pop ES
		pop DI
		pop DX
		pop CX
		pop BX
		pop AX
		ret
OVL_MEM ENDP
;-------------------------------------------------- 
EXECUTION PROC near
		push AX
		push BX
		push DX
		push DI
		push ES
	
		mov AX, seg DATA
		mov DS, AX
		mov DX, offset PATH

		mov ES, AX
		mov BX, offset BLOCK_ADDR


		mov AX, 4B03h
		int 21h
		jnc exec_without_err
		call PRINT_ERROR_2

exec_without_err:
		mov AX, BLOCK_ADDR
		mov WORD ptr CALL_ADDR+2, AX
		call CALL_ADDR

		mov AX, BLOCK_ADDR
		mov ES, AX
		mov AX, 4900h
		int 21h


		pop ES
		pop DI
		pop DX
		pop BX
		pop AX
		ret
EXECUTION ENDP
;-------------------------------------------------- 
MAIN PROC far
	mov AX, seg DATA
	mov DS, AX

	call PREPARE_PLACE
	call MAKE_PATH

	call OVL_MEM
	call EXECUTION

	mov PATH[DI], '2'
	call OVL_MEM
	call EXECUTION

	xor AL, AL
	mov AH, 4Ch
	int 21h
	ret
MAIN ENDP
END_OF_PROGRAM:
CODE ENDS
END MAIN 