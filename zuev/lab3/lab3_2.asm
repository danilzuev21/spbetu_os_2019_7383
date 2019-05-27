TESTMEM     SEGMENT
            ASSUME  CS:TESTMEM, DS:TESTMEM, ES:NOTHING, SS:NOTHING
            ORG     100H 
START:     JMP     BEGIN

AV_MEM		db 		'Amount of available memory is        b',0DH,0AH,'$'
EXT_MEM		db		'Size of extended memory is       Kb',0DH,0AH,'$'
MCB_CHAIN	db		'Chain of MCB is ',0DH,0AH,'Address | Type | PSP owner |  Size  | Name',0DH,0AH,'$'
MCB_LIST	db		'             h          h                     ',0DH,0AH,'$'
ENDLINE		db		0DH,0AH,'$'

;----------------------------------------------------- 
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
WRD_TO_HEX   PROC  near
            push     BX
            mov      BH,AH
            call     BYTE_TO_HEX
            mov      [DI],AH
            dec      DI
            mov      [DI],AL
            dec      DI
            mov      AL,BH
            call     BYTE_TO_HEX
            mov      [DI],AH
            dec      DI
            mov      [DI],AL
            pop      BX
            ret 
WRD_TO_HEX ENDP 
;------------------------------- 
BYTE_TO_DEC   PROC  near
            push     CX
            push     DX
            ;xor      AH,AH
            ;xor      DX,DX
            mov      CX,10 
loop_bd:    div      CX
            or       DL,30h
            mov      [SI],DL
            dec      SI
            xor      DX,DX
            cmp      AX,10
            jae      loop_bd
            cmp      AL,00h
            je       end_l
            or       AL,30h
            mov      [SI],AL 
end_l:      pop      DX
            pop      CX
            ret
BYTE_TO_DEC    ENDP 
;-------------------------------
PRINT PROC near
			mov AH, 09h
			int 21h
			ret
PRINT ENDP
;-------------------------------
NEW_LINE PROC near
			mov DL, 0Dh
			int 21h
			mov DL, 0AH
			int 21h
			ret
NEW_LINE ENDP
;-------------------------------
GET_AV_MEMORY PROC near
			mov 	AH, 4Ah
			mov 	BX, 0FFFFh
			int 	21h
			mov 	AX, BX
			mov 	BX, 16
			mul 	BX
	
			mov  	SI, offset av_mem+35
			call 	BYTE_TO_DEC
		
			mov 	DX, offset AV_MEM
			call 	PRINT
			ret
GET_AV_MEMORY ENDP
;-------------------------------
GET_EXT_MEMORY PROC near
			mov AL, 30h
			out 70h, AL
			in AL, 71h
			mov BL, AL
			mov AL, 31h
			out 70h, AL
			in AL, 71h
			mov	AH, AL
			mov AL, BL
			mov SI, offset EXT_MEM+31
			xor DX,DX
			call BYTE_TO_DEC
			mov	DX, offset EXT_MEM
			call PRINT
			ret
GET_EXT_MEMORY ENDP
;-------------------------------
GET_MCB_CHAIN PROC near
			mov AH, 52h
			int 21h
			mov ES, ES:[BX-2]
			;mov ES, BX
			mov DX, offset MCB_CHAIN
			call PRINT
			;mov CX, 5
MCB_list_loop:
			mov AX, ES
			mov DI, offset MCB_LIST+5
			call WRD_TO_HEX
			
			mov AX, ES:[00h]
			mov DI, offset MCB_LIST+11
			call BYTE_TO_HEX
			
			mov [di], AH
			inc di
			mov [di], AL
			
			mov AX, ES:[01h]
			mov DI, offset MCB_LIST+23
			call WRD_TO_HEX
			
			mov AX,ES:[03h]
			mov BX, 10h
			mul BX
			mov SI, offset MCB_LIST+34
			call BYTE_TO_DEC
						
			mov CX,8
			mov BX,0
			mov DI, offset MCB_LIST+37
name_loop:
			mov AX, ES:[08h+BX]
			mov [DI+BX], AX
			inc BX
			loop name_loop
						
			mov DX, offset MCB_LIST
			call PRINT
			
			mov BL, ES:[00h]

			
			mov AX, ES
			add AX, ES:[03h]
			inc AX
			mov ES, AX

			cmp BL, 4Dh
			je MCB_list_loop
			ret
GET_MCB_CHAIN ENDP
BEGIN:      				
					
			call GET_AV_MEMORY	
			call GET_EXT_MEMORY
			mov 	AH, 4Ah
			mov 	BX, offset END_OF_PROGRAMM
			int 	21h
			call GET_MCB_CHAIN
			xor     AL,AL
            mov     AH,4Ch
            int     21H 
END_OF_PROGRAMM	db	0
TESTMEM     ENDS            
			END     START