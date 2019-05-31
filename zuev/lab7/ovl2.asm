ASSUME CS:OVL2, DS:OVL2


OVL2 SEGMENT


		push AX
		push DX
		push DI
		push DS
		mov AX, CS
		mov DS, AX
		mov DI, offset ADDRES2+29
		call WRD_TO_HEX
		mov DX, offset ADDRES2
		call PRINT
		pop DS
		pop DI
		pop DX
		pop AX
		retf

;-------------------------------
PRINT PROC near
		push AX
		mov AH,09h
		int 21h
		pop AX
		ret
PRINT ENDP
;-------------------------------
TETR_TO_HEX PROC near       
		and AL,0Fh
		cmp AL,09
		jbe NEXT
		add AL,07
NEXT: 
		add AL,30h
		ret
TETR_TO_HEX ENDP
;-------------------------------
BYTE_TO_HEX PROC near 
		push CX
		mov AH, AL
		call TETR_TO_HEX
		xchg AL, AH
		mov CL, 4
		shr AL, CL
		call TETR_TO_HEX 
		pop CX 
		ret
BYTE_TO_HEX ENDP
;-------------------------------
WRD_TO_HEX PROC near
		push BX
		mov BH, AH
		call BYTE_TO_HEX
		mov [DI], AH
		dec DI
		mov [DI], AL
		dec DI
		mov AL, BH
		call BYTE_TO_HEX
		mov [DI], AH
		dec DI
		mov [DI], AL
		pop BX
		ret
WRD_TO_HEX ENDP

		ADDRES2		db	'Segment address of ovl2:     ',0DH,0AH,'$'

OVL2 ENDS
END 