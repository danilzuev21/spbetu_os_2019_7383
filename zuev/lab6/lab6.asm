AStack SEGMENT STACK
	dw 256 dup (?)
AStack ENDS

DATA SEGMENT
		ERROR_1			db	'Function number is incorrect',0Dh,0Ah,'$'
		ERROR_2			db	'File is not found',0Dh,0Ah,'$'
		ERROR_5			db	'Disk error',0Dh,0Ah,'$'
		ERROR_7			db	'Сontrol memory block destroyed',0Dh,0Ah,'$'
		ERROR_8			db	'Not enough memory to perform the function',0Dh,0Ah,'$'
		ERROR_9			db	'Invalid memory block address',0Dh,0Ah,'$'
		ERROR_10		db	'Invalid environment string',0Dh,0Ah,'$'
		ERROR_11		db	'Invalid format',0Dh,0Ah,'$'
		
		END_0			db	'Normal end',0Dh,0Ah,'$'
		END_1			db	'End by Ctrl-Break',0Dh,0Ah,'$'
		END_2			db	'End by device error',0Dh,0Ah,'$'
		END_3			db	'End by function 31h',0Dh,0Ah,'$'
		END_CODE		db	'End code: $'
		
		SEG_ADDR		dw 0
						dd 0
						dd 0
						dd 0
		
		PATH			db '0000000000000000', 0
		
		KEEP_SS			dw 0
		KEEP_SP			dw 0

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
PRINT_ERROR PROC
		
		cmp AX, 1
		je err_1
		cmp AX, 2
		je err_2
		cmp AX, 5
		je err_5
		cmp AX, 7
		je err_7
		cmp AX, 8
		je err_8
		cmp AX, 9
		je err_9
		cmp AX, 10
		je err_10
		cmp AX, 11
		je err_11
err_1:
		mov DX, offset ERROR_1
		jmp end_err
err_2:
		mov DX, offset ERROR_2
		jmp end_err
err_5:
		mov DX, offset ERROR_5
		jmp end_err
err_7:
		mov DX, offset ERROR_7
		jmp end_err
err_8:
		mov DX, offset ERROR_8
		jmp end_err
err_9:
		mov DX, offset ERROR_9
		jmp end_err
err_10:
		mov DX, offset ERROR_10
		jmp end_err
err_11:
		mov DX, offset ERROR_11
end_err:
		call PRINT
		mov AX, 4C00h
		int 21h
		ret
PRINT_ERROR ENDP
;-------------------------------
PRINT_END PROC
		push DX
		mov AH,4Dh
		int 21h

		cmp AH, 0
		je end_e0
		cmp AH, 1
		je end_e1
		cmp AH, 2
		je end_e2
		cmp AH, 3
		je end_e3
end_e0:
		mov DX, offset END_0
		call PRINT

		mov DX,offset END_CODE
		call PRINT
		call BYTE_TO_HEX
		push AX
		mov AH, 02h
		mov DL, AL
		int 21h
		pop AX
		mov AL, AH
		mov AH,02h
		mov DL, AL
		int 21h
		
		jmp end_end
end_e1:
		mov DX, offset END_1
		call PRINT
		jmp end_end
end_e2:
		mov DX, offset END_2
		call PRINT
		jmp end_end
end_e3:
		mov DX, offset END_3
		call PRINT
		jmp end_end		
end_end:
		pop DX
		ret
PRINT_END ENDP
;-------------------------------
PREPARE_PLACE PROC
		push AX
		push BX
		mov AH, 4Ah
		mov BX, offset END_OF_PROGRAMM
		int 21h
		jnc exec_completed ; CF = 0
		call PRINT_ERROR
exec_completed:
		pop BX
		pop AX
		ret
PREPARE_PLACE ENDP
;-------------------------------
MAKE_PARAM_BLOCK PROC
		push AX
		push ES
		
		mov AX, ES:[2Ch]
		mov SEG_ADDR, AX
		mov SEG_ADDR+2, AX
		mov AX, ES
		mov SEG_ADDR+4, 80h
		mov SEG_ADDR+6, AX
		mov SEG_ADDR+8, 5Ch
		mov SEG_ADDR+10, AX
		mov SEG_ADDR+12, 6Ch
		
		pop ES
		pop AX

		ret
MAKE_PARAM_BLOCK ENDP
;-------------------------------
MAKE_PATH PROC
		push AX
		push BX
		push ES
		push SI
		push DI

		mov BX, ES:[2Ch]
		mov ES, BX
		xor SI, SI
output_content:
		cmp word ptr ES:[SI], 0000h
		je end_content
		cmp byte ptr ES:[SI], 00h
		jne not_new_line
		inc SI
		jmp output_content
not_new_line:
		inc SI
		jmp output_content
end_content:
		add SI, 4;
		xor DI, DI
rec_path:
		mov DL, ES:[SI]
		cmp DL, 00h
		je end_path
		mov PATH[DI], DL
		inc DI
		inc SI
		jmp rec_path
end_path:
		sub DI,8
		mov PATH[DI], 'l'
		mov PATH[DI+1], 'a'
		mov PATH[DI+2], 'b'
		mov PATH[DI+3], '2'
		mov PATH[DI+4], '.'
		mov PATH[DI+5], 'c'
		mov PATH[DI+6], 'o'
		mov PATH[DI+7], 'm'
		
		
		pop DI
		pop SI
		pop ES
		pop BX
		pop AX
		
		ret
MAKE_PATH ENDP
;-------------------------------
EXECUTION PROC
		mov DX, offset PATH
		mov AX, DS
		mov ES, AX
		mov BX, offset SEG_ADDR
		mov KEEP_SP, SP
		mov KEEP_SS, SS
		push DS
		mov KEEP_SP, SP
		mov KEEP_SS, SS
		mov AX, 4B00h
		int 21h
		mov SP, KEEP_SP
		mov SS, KEEP_SS
		jnc end_exec
		call PRINT_ERROR
end_exec:
		call PRINT_END
		pop DS
		ret
EXECUTION ENDP
;-------------------------------		
MAIN PROC near
		mov AX, seg DATA
		mov DS, AX
		call PREPARE_PLACE
		call MAKE_PARAM_BLOCK
		call MAKE_PATH
		call EXECUTION
		mov AX,4C00h
		int 21h
		ret
MAIN ENDP
END_OF_PROGRAMM:
CODE ENDS
END MAIN