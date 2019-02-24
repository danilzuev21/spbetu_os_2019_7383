AStack SEGMENT STACK
		DW 256 DUP(?)
AStack ENDS

DATA SEGMENT

TYPE_OF_PC	db		'Type of PC is ','$'
OS_VERSION 	db		'OS Version is   .  ',0DH,0AH,'$'
OEM_NUMBER 	db		'OEM number is    ',0DH,0AH,'$'
USER_NUMBER	db		'User number is ','$'

ENDLINE		db		0DH,0AH,'$'
EMPTY_STR	db 		'	','$'

PC			db 		'PC',0DH,0AH,'$'
PC_XT		db		'PC/XT',0DH,0AH,'$'
AT_			db		'AT',0DH,0AH,'$'
PS2_30		db		'PS2 model 30',0DH,0AH,'$'
PS2_50_60	db		'PS2 model 50 or 60',0DH,0AH,'$'
PS2_80		db		'PS2 model 80',0DH,0AH,'$'
PCJR		db		'PCjr',0DH,0AH,'$'
PC_CONV		db		'PC Convertible',0DH,0AH,'$'

DATA ENDS

CODE SEGMENT
		ASSUME CS:CODE, DS:DATA, SS:AStack

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
;-------------------------------------------------- 
BYTE_TO_DEC   PROC  near
            push     CX
            push     DX
            xor      AH,AH
            xor      DX,DX
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
FOUND_PC_TYPE PROC far
			mov DX, offset TYPE_OF_PC
			call PRINT
			mov BX, 0F000h
			mov ES, BX
			mov AX, ES:0FFFEh
			mov DX, offset PC	
			cmp AL, 0FFh
			je writing
            mov DX, offset PC_XT	
			cmp	AL, 0FEh
			je writing
			cmp AL, 0FBh
			je writing
			mov DX, offset AT_
			cmp AL, 0FCh
			je writing
			mov DX, offset PS2_30
			cmp AL, 0FAh
			je writing
			mov DX,offset PS2_50_60
			cmp AL,0FCh
			je writing
			mov DX, offset PS2_80
			cmp AL, 0F8h
			je writing
			mov DX, offset PCJR
			cmp AL, 0FDh
			je writing
			mov DX, offset PC_CONV
			cmp AL, 0F9h
			je writing
			call BYTE_TO_HEX
			mov BX, AX
			mov DL, BL
			mov AH, 02h
			int 21h
			mov DL, BH
			int 21h
			mov DX, offset ENDLINE
writing:
			call PRINT
			ret
FOUND_PC_TYPE ENDP
;-------------------------------
FOUND_VERSION_OS PROC far
			xor AX, AX
			mov ah, 30h
			int 21h
			
			mov SI, offset OS_VERSION
			add SI, 15
			push AX
			call BYTE_TO_DEC
			
			add SI, 3
			pop AX
			mov AL, AH
			call BYTE_TO_DEC
			mov DX, offset OS_VERSION
			call PRINT
			
			mov SI, offset OEM_NUMBER
			add SI, 16
			mov AL, BH
			call BYTE_TO_DEC
			mov DX, offset OEM_NUMBER
			call PRINT
			
			mov DX, offset USER_NUMBER
			call PRINT
			mov AL, BL
			call BYTE_TO_HEX
			mov BX, AX
			mov DL, BL
			mov AH, 02h
			int 21h
			mov DL, BH
			int 21h
			mov DI, offset EMPTY_STR
			add DI, 3
			mov AX, CX
			call WRD_TO_HEX
			mov DX,offset EMPTY_STR
			call PRINT
			ret
			
FOUND_VERSION_OS ENDP
			
BEGIN:      				
			mov AX, DATA
			mov DS, AX
					
			call FOUND_PC_TYPE
			call FOUND_VERSION_OS
			xor     AL,AL
            mov     AH,4Ch
            int     21H 
CODE		ENDS            
			END     BEGIN