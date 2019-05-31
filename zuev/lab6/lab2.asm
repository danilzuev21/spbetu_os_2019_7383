TESTPC     SEGMENT
            ASSUME  CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
            ORG     100H 
START:     JMP     BEGIN

INACCESS	db		'Inaccessible memory adress is      ',0DH,0AH,'$'
SEG_ADRESS 	db		'Segment adress of the environment is     ',0DH,0AH,'$'
TAIL 		db		'Tail of the command string is ','$'
MISSING_T	db		'missing',0DH,0AH,'$'
CONTENT		db		'Content of the envoronment is ',0DH,0AH,'$'
PATH		db		'Loadable module path is ','$'

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
PRINT PROC near
			mov AH, 09h
			int 21h
			ret
PRINT ENDP
NEW_LINE PROC near
			mov DL, 0Dh
			int 21h
			mov DL, 0AH
			int 21h
			ret
NEW_LINE ENDP
;-------------------------------
GET_INACCESS PROC near
			mov DI, offset INACCESS
			add DI, 34
			mov AX, ES:[2]
			call WRD_TO_HEX
			mov DX, offset INACCESS
			call PRINT
			ret
GET_INACCESS ENDP
;-------------------------------
GET_ENVIR PROC near
			mov DI, offset SEG_ADRESS
			add DI, 41
			mov AX, ES:[2Ch]
			call WRD_TO_HEX
			mov DX, offset SEG_ADRESS
			call PRINT
			ret
GET_ENVIR ENDP
;-------------------------------
GET_TAIL PROC near
			mov DX, offset TAIL
			call PRINT
			xor CX, CX
			mov CL, ES:[80h]
			cmp CL, 0
			je missing
			xor BX, BX
			mov AH, 02h

getting_tail:
			mov DL, ES:[81h+BX] 
			inc BX
			int 21h
			loop getting_tail
			call NEW_LINE
			jmp termination
missing:
			mov DX, offset MISSING_T
			call PRINT
termination:
			ret
GET_TAIL ENDP
;-------------------------------
GET_CONTENTS PROC near
			mov DX, offset CONTENT
			call PRINT
			mov BX, ES:[2Ch]
			mov ES, BX
			xor SI, SI
			mov AH, 02h
new_line_c:
output_content:
			cmp word ptr ES:[SI], 0000h
			je end_content
			cmp byte ptr ES:[SI], 00h
			jne not_new_line
			call NEW_LINE
			inc SI
not_new_line:
			mov DL, ES:[SI]
			int 21h
			inc SI
			jmp output_content
end_content:
			call NEW_LINE
			add SI, 4;
			mov DX, offset PATH
			call PRINT
			mov AH, 02h		
outpput_path:
			cmp byte ptr ES:[SI], 00h
			je end_path
			mov DL, ES:[SI]
			int 21h
			inc SI
			jmp outpput_path
end_path:
			call NEW_LINE
			ret
GET_CONTENTS ENDP
;-------------------------------
BEGIN:      				
					
			call GET_INACCESS
			call GET_ENVIR
			call GET_TAIL
			call GET_CONTENTS		

			xor AL,AL
			mov AH,01h
			int 21h
            mov     AH,4Ch
            int     21H 
TESTPC      ENDS            
			END     START