
PUTC    MACRO   char
        PUSH    AX
        MOV     AL, char
        MOV     AH, 0Eh
        INT     10h     
        POP     AX
ENDM
data segment
    ;declaration des donnees 
    msg1 db 'entrer '1' pour la base binaire, '2' pour decimal et '3' pour hexadecimal : $'
    msg2 db 'entrer le symbole d operation souhaite "+,*,/,-": $'     
    msg3 db 'entrez une premiere operande:  $'
    msg4 db 'entrez une deuxieme operande:  $'
    msg5 db 'erreur deuxieme operarande nulle $' 
    msg6 db 'depacement, valeurs trop grandes(depassant 16 bits) $'
    msg7 db 'le resultat est :  $'
    oper db ?
    base db ?
    divi dw 16
    
    sautligne db 0Dh,0Ah,'$'
    
ends

strack segment
    dw 128 dup(0)    
ends

code segment
    
assume cs:code,ds: date,ss: strack

start:
mov ax, data
mov ds,ax
mov ax, strack
mov ss,ax
             
                    lea       dx,msg1
                    mov       ah,09h    
                    int       21h  
                                
                    
                    call      SCAN_base   
                    call      saut
                    
                                         
                    lea       dx,msg2
                    mov       ah,09h    
                    int       21h
                                         
                    call      SCAN_operation
                    call      saut
                    cmp       base,'2'
                    je        decimal
                    cmp       base,'1'
                    je        binaire  
                    
                    lea       dx,msg3
                    mov       ah,09h    
                    int       21h
                   
                   
                    call      SCAN_hexa
                    call      saut
                    
                     
                    mov       bx,cx 
                     
                    lea       dx,msg4
                    mov       ah,09h    
                    int       21h
                    
                    call      SCAN_hexa  
                    call      saut
                    jmp       operation
                    
binaire:            
                    mov       divi,02h
                    lea       dx,msg3
                    mov       ah,09h    
                    int       21h
                   
                   
                    call      SCAN_bin
                    call      saut
                    
                     
                    mov       bx,cx 
                     
                    lea       dx,msg4
                    mov       ah,09h    
                    int       21h
                    
                    call      SCAN_bin  
                    call      saut 
                    jmp       operation
                                        
                    
decimal:             
                    mov       divi,10  
                    lea       dx,msg3
                    mov       ah,09h    
                    int       21h
                   
                   
                    call      SCAN_dec
                    call      saut
                    
                     
                    mov       bx,cx 
                     
                    lea       dx,msg4
                    mov       ah,09h    
                    int       21h
                    
                    call      SCAN_dec  
                    call      saut
                    jmp       operation
                      
operation:          lea       dx,msg7
                    mov       ah,09h    
                    int       21h 
                    cmp       oper,'+'
                    je        addition
                    cmp       oper,'-'
                    je        soustraction
                    cmp       oper,'*'
                    je        multiplication 
                                   
                    mov       dx,0
                    mov       ax,bx
                    cmp       cx,0
                    je        erreur
                    div       cx
                    jmp       resultat
                    
addition:           add       bx,cx
                    mov       ax,bx
                    jc        erreur1
                    jmp       resultat 
                    
soustraction:       sub       bx,cx
                    mov       ax,bx
                    jmp       resultat 
                    
multiplication:     mov       ax,cx
                    mul       bx  
                    jc        erreur1
                    jmp       resultat  
                    
                             
resultat:                                
                    mov       cx,0
                    mov       dx,0
                    mov       bx,divi                     
                                     
                    empiler:
                    div       bx
                    add       dx,48 
                    cmp       dx,'9'
                    jbe       sinon
                    add       dx,7
sinon:              push      dx 
                    mov       dx,0
                    inc       cx
                    cmp       ax,0 
                    
                    jne empiler    
                    
                    depiler:
                    pop       dx
                    mov       ah,02h
                    int       21h     
                    
                    loop depiler 
 
exit:               mov       ah,04Ch
                    int       21h                                           
                    
saut     PROC    NEAR 
mov       dl,10         
mov       ah,02h    
int       21h  
RET 
saut ENDP                     
     
SCAN_HEXA    PROC    NEAR
        PUSH    DX
        PUSH    AX
        PUSH    SI
        MOV     CX, 0

        ; reset flag:
        MOV     CS:make_hexadecimal_minus, 0

next_hexadecimal_digit:

        ; get char from keyboard
        ; into AL:
        MOV     AH, 00h
        INT     16h
        ; and print it:
        MOV     AH, 0Eh
        INT     10h

        ; check for ENTER key:
        CMP     AL, 13  ; carriage return?
        JNE     not_hexadecimal_cr
        JMP     stop_hexadecimal_input  
        
not_hexadecimal_cr:
        CMP     AL, 8                   ; 'BACKSPACE' pressed?
        JNE     hexadecimal_backspace_checked
        MOV     DX, 0                   ; remove last digit by
        MOV     AX, CX                  ; division:
        DIV     CS:hexa                  ; AX = DX:AX / 10 (DX-rem).
        MOV     CX, AX
        PUTC    ' '                     ; clear position.
        PUTC    8                       ; backspace again.
        JMP     next_hexadecimal_digit
        
hexadecimal_backspace_checked:
        ; allow only digits:
        CMP     AL, '0'
        JAE     ok_AE_0H
        JMP     remove_not_hexadecimal_digit
ok_AE_0H:        
        CMP     AL, '9'
        JBE     ok_hexadecimal_digit
        SUB     AL, 7
        CMP     AL, '9'
        JBE     remove_not_hexadecimal_digit
        CMP     AL, '?'
        JBE     ok_hexadecimal_digit
remove_not_hexadecimal_digit:       
        PUTC    8       ; backspace.
        PUTC    ' '     ; clear last entered not digit.
        PUTC    8       ; backspace again.        
        JMP     next_hexadecimal_digit ; wait for next input.       
ok_hexadecimal_digit:


        ; multiply CX by 10 (first time the result is zero)
        PUSH    AX
        MOV     AX, CX
        MUL     CS:hexa                  ; DX:AX = AX*10
        MOV     CX, AX
        POP     AX

        ; check if the number is too big
        ; (result should be 16 bits)
        CMP     DX, 0
        JNE     too_bigH

        ; convert from ASCII code:
        SUB     AL, 30h

        ; add AL to CX:
        MOV     AH, 0
        MOV     DX, CX      ; backup, in case the result will be too big.
        ADD     CX, AX
        JC      too_big2H    ; jump if the number is too big.

        JMP     next_hexadecimal_digit

too_big2H:
        MOV     CX, DX      ; restore the backuped value before add.
        MOV     DX, 0       ; DX was zero before backup!
too_bigH:
        MOV     AX, CX
        DIV     CS:hexa  ; reverse last DX:AX = AX*10, make AX = DX:AX / 10
        MOV     CX, AX
        PUTC    8       ; backspace.
        PUTC    ' '     ; clear last entered digit.
        PUTC    8       ; backspace again.        
        JMP     next_hexadecimal_digit ; wait for Enter/Backspace.
        
        
stop_hexadecimal_input:
        ; check flag:make_hexadecimal_minus 0
        JE      not_hexadecimal_minus
        NEG     CX
not_hexadecimal_minus:

        POP     SI
        POP     AX
        POP     DX
        RET
make_hexadecimal_minus      DB      ?       ; used as a flag.
hexa             DW      10h       ; used as multiplier.
SCAN_HEXA        ENDP

SCAN_BIN    PROC    NEAR
        PUSH    DX
        PUSH    AX
        PUSH    SI
        MOV     CX, 0

        MOV     CS:make_binary_minus, 0

next_binary_digit:

     
        MOV     AH, 00h
        INT     16h
      
        MOV     AH, 0Eh
        INT     10h

        CMP     AL, 13  
        JNE     not_binary_cr
        JMP     stop_binary_input  
        
not_binary_cr:
        CMP     AL, 8                   ; 'BACKSPACE' pressed?
        JNE     binary_backspace_checked
        MOV     DX, 0                   ; remove last digit by
        MOV     AX, CX                  ; division:
        DIV     CS:two                  ; AX = DX:AX / 10 (DX-rem).
        MOV     CX, AX
        PUTC    ' '                     ; clear position.
        PUTC    8                       ; backspace again
        JMP     next_binary_digit
        
binary_backspace_checked:
        ; allow only digits:
        CMP     AL, '0'
        JAE     ok_AE_0B
        JMP     remove_not_binary_digit
ok_AE_0B:        
        CMP     AL, '1'
        JBE     ok_binary_digit
remove_not_binary_digit:       
        PUTC    8       ; backspace.
        PUTC    ' '     ; clear last entered not digit.
        PUTC    8       ; backspace again.        
        JMP     next_binary_digit ; wait for next input.       
ok_binary_digit:


        ; multiply CX by 10 (first time the result is zero)
        PUSH    AX
        MOV     AX, CX
        MUL     CS:two                  ; DX:AX = AX*10
        MOV     CX, AX
        POP     AX

        ; check if the number is too big
        ; (result should be 16 bits)
        CMP     DX, 0
        JNE     too_bigB

        ; convert from ASCII code:
        SUB     AL, 30h

        ; add AL to CX:
        MOV     AH, 0
        MOV     DX, CX      ; backup, in case the result will be too big.
        ADD     CX, AX
        JC      too_big2B    ; jump if the number is too big.

        JMP     next_binary_digit

too_big2B:
        MOV     CX, DX      ; restore the backuped value before add.
        MOV     DX, 0       ; DX was zero before backup!
too_bigB:
        MOV     AX, CX
        DIV     CS:two  ; reverse last DX:AX = AX*10, make AX = DX:AX / 10
        MOV     CX, AX
        PUTC    8       ; backspace.
        PUTC    ' '     ; clear last entered digit.
        PUTC    8       ; backspace again.        
        JMP     next_binary_digit ; wait for Enter/Backspace.
        
        
stop_binary_input:
        ; check flag:
        CMP     CS:make_binary_minus, 0
        JE      not_minusB
        NEG     CX
not_minusB:

        POP     SI
        POP     AX
        POP     DX
        RET
make_binary_minus      DB      ?       ; used as a flag.
two             DW      2       ; used as multiplier.
SCAN_BIN        ENDP


SCAN_dec    PROC    NEAR
        PUSH    DX
        PUSH    AX
        PUSH    SI
        MOV     CX, 0

        ; reset flag:
        MOV     CS:make_minus, 0

next_digit:

        ; get char from keyboard
        ; into AL:
        MOV     AH, 00h
        INT     16h
        ; and print it:
        MOV     AH, 0Eh
        INT     10h

        ; check for ENTER key:
        CMP     AL, 13  ; carriage return?
        JNE     not_cr
        JMP     stop_input  
        
not_cr:
        CMP     AL, 8                   ; 'BACKSPACE' pressed?
        JNE     backspace_checked
        MOV     DX, 0                   ; remove last digit by
        MOV     AX, CX                  ; division:
        DIV     CS:ten                  ; AX = DX:AX / 10 (DX-rem).
        MOV     CX, AX
        PUTC    ' '                     ; clear position.
        PUTC    8                       ; backspace again.
        JMP     next_digit
        
backspace_checked:
        ; allow only digits:
        CMP     AL, '0'
        JAE     ok_AE_0
        JMP     remove_not_digit
ok_AE_0:        
        CMP     AL, '9'
        JBE     ok_digit
remove_not_digit:       
        PUTC    8       ; backspace.
        PUTC    ' '     ; clear last entered not digit.
        PUTC    8       ; backspace again.        
        JMP     next_digit ; wait for next input.       
ok_digit:


        ; multiply CX by 10 (first time the result is zero)
        PUSH    AX
        MOV     AX, CX
        MUL     CS:ten                  ; DX:AX = AX*10
        MOV     CX, AX
        POP     AX

        ; check if the number is too big
        ; (result should be 16 bits)
        CMP     DX, 0
        JNE     too_big

        ; convert from ASCII code:
        SUB     AL, 30h

        ; add AL to CX:
        MOV     AH, 0
        MOV     DX, CX      ; backup, in case the result will be too big.
        ADD     CX, AX
        JC      too_big2    ; jump if the number is too big.

        JMP     next_digit

too_big2:
        MOV     CX, DX      ; restore the backuped value before add.
        MOV     DX, 0       ; DX was zero before backup!
too_big:
        MOV     AX, CX
        DIV     CS:ten  ; reverse last DX:AX = AX*10, make AX = DX:AX / 10
        MOV     CX, AX
        PUTC    8       ; backspace.
        PUTC    ' '     ; clear last entered digit.
        PUTC    8       ; backspace again.        
        JMP     next_digit ; wait for Enter/Backspace.
                
stop_input:
        ; check flag:
        CMP     CS:make_minus, 0
        JE      not_minus
        NEG     CX
not_minus:

        POP     SI
        POP     AX
        POP     DX
        RET
make_minus      DB      ?       ; used as a flag.
ten             DW      10      ; used as multiplier.
SCAN_dec        ENDP  

           
           
SCAN_base     PROC    NEAR
          mov ax,0 
          mov cx,00h  
  
attente:    
        
       mov al,00h
       mov AH,01h ;saisie
       int 21h   ;le caractäre lu arrive dans AL 
       cmp al,13 
       je  return 
       
       CMP AL, 8
       je  decrem
       
       CMP al,'1'
       je  re1 
       CMP al,'2'
       je  re1
       CMP al,'3'
       je  re1      
       
       jmp supression_num
           
  
re1:    cmp cx,01h
       je  supression_num 
       
       mov cx,01h
       mov base,al
       mov dl, base
       mov ah,02h
        
       jmp attente          
       
decrem:
        
       mov     cx,00h
       jmp     supression_num1
                
supression_num: 
       
       PUTC    8                        ; backspace again
        
supression_num1:
       
       PUTC    ' '                     ; clear position.       
       PUTC    8                       ; backspace again
       
       jmp attente
         
return:          RET      

SCAN_base        ENDP  
       

SCAN_operation   PROC    NEAR  
    
       mov ax,0 
       mov cx,00h       
att:            
       mov al,00h
       mov AH,01h ;saisie
       int 21h   ;le caractäre lu arrive dans AL 
       cmp al,13 
       je  retour 
       
       CMP AL, 8
       je  decre
       
       CMP al,'+'
       je  re 
       CMP al,'-'
       je  re
       CMP al,'*'
       je  re
       CMP al,'/'
       je  re       
       
       jmp supression_car
           
  
re:    cmp cx,01h
       je  supression_car 
       
       mov cx,01h
       mov oper,al
       mov dl, oper
       mov ah,02h
        
       jmp att
               
decre:
        
       mov     cx,00h
       jmp     supression_car1
                
supression_car: 
       
       PUTC    8                        ; backspace again
        
supression_car1:
       
       PUTC    ' '                     ; clear position.       
       PUTC    8                       ; backspace again
       
       jmp att
retour:              RET
          
SCAN_operation       ENDP  

erreur: 
       lea       dx,msg5
       mov       ah,09h    
       int       21h  
       jmp       exit
erreur1: 
       lea       dx,msg6
       mov       ah,09h    
       int       21h
       jmp       exit
       
             
end start 