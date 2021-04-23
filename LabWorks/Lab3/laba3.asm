; LAB-3
; variant 5
; .small

.model small
.stack 100h

.data
    add_str             db      "Press '+' to add$", "$"
    sub_str             db      "Press '-' to sub$", "$"
    mul_str             db      "Press '*' to mul$", "$"
    div_str             db      "Press '/' to div$", "$"
    exit_str            db      "Press 'q' to exit$", "$"
    new_ops             db      "Press 'n' to input new operands$", "$"
    choice_str          db      "--> $", "$"
    input_st_number     db      "Enter first number: $", "$"
    input_nd_number     db      "Enter second number: $", "$"
    result_message      db      "Result: $", "$"
    except_msg          db      "Input errors!$"
    reg_ovf             db      "Register 'AX' overflow!$", "$"
    st_number           db      7, 7 dup("$"), "$"
    nd_number           db      7, 7 dup("$"), "$"
    callback_str        db      2, 2 dup("$"), "$"
    new_str             db      0Ah, 0Dh, "$"
    
.code
main proc
;########### macro-commands ############
    print_newline macro
        mov ah, 09h
        mov dx, offset new_str
        int 21h
    endm    
    
    print_comment macro msg
        mov ah, 09h
        mov dx, offset msg
        int 21h
    endm
;#######################################
        start:
            mov ax, @data
            mov ds, ax
            mov es, ax
        
            print_comment input_st_number
            mov ah, 0Ah
            mov dx, offset st_number
            int 21h
            
            print_newline
            print_comment input_nd_number
            mov ah, 0Ah
            mov dx, offset nd_number
            int 21h
            
            print_newline
            call print_options_menu
            mov ah, 08h
            int 21h
            
            cmp al, "+"
            je addition
            cmp al, "-"
            je subtraction
            cmp al, "*"
            je multiplication
            cmp al, "/"
            je division
            cmp al, "q"
            je exit
            ;cmp al, "n"
            ;je ;;;
            jne call input_errors                    
        exit:
            mov ah, 4Ch
            int 21h
 
;##############################    
addition:
    mov si, offset st_number[2]
    push si
    call fromCharToInt
    pop si    
    mov bx, ax
    mov si, offset nd_number[2]
    push bx
    push si
    call fromCharToInt
    pop si
    pop bx
    add ax, bx
    jo overflow_exc 
    call fromIntToChar
    jmp exit
;-------- END ADDITION --------   

subtraction:
    mov si, offset st_number[2]
    push si
    call fromCharToInt
    pop si
    mov bx, ax
    mov si, offset nd_number[2]
    push bx
    push si
    call fromChartoInt
    pop si
    pop bx
    sub bx, ax
    mov ax, bx
    jo overflow_exc
    call fromIntToChar
    jmp exit
;------ END SUBTRACTION -------
                
multiplication:
    mov si, offset st_number[2]
    push si
    call fromCharToInt
    pop si    
    mov bx, ax
    mov si, offset nd_number[2]
    push bx
    push si
    call fromCharToInt
    pop si
    pop bx
    imul bx
    jo overflow_exc 
    call fromIntToChar                
    jmp exit
;----- END MULTIPLICATION -----
                   
division:
    mov si, offset st_number[2]
    push si
    call fromCharToInt
    pop si    
    mov bx, ax
    mov si, offset nd_number[2]
    push bx
    push si
    call fromCharToInt
    pop si
    pop bx
    mov cx, ax;
    mov ax, bx;
    mov bx, cx;
    test ax, ax
    jns pos_div
    neg ax
    jmp neg_div    
        pos_div:    
            idiv bx
            jo overflow_exc
            jmp remainder
        neg_div:
            idiv bx    
            neg ax
            jo overflow_exc 
            jmp remainder
    remainder:
        push bx
        push dx
        call fromIntToChar
        pop dx
        pop bx
        cmp dx, 0
        je exit
        push dx
        test bx, bx
        jns out_rem
        neg bx
    out_rem:
        mov ah, 02h
        mov dl, "."
        int 21h
            pop ax
            mov cx, 10
            mul cx
            div bx
            mov dx, ax
            mov ah, 02h
            add dx, "0"
            int 21h
        jmp exit
                   
;##############################

print_options_menu proc
    print_comment add_str
    print_newline
    print_comment sub_str
    print_newline
    print_comment mul_str
    print_newline
    print_comment div_str
    print_newline
    print_comment exit_str
    print_newline
    print_comment choice_str
    ret
endp print_options_menu

;##############################                  
fromCharToInt proc
    push bp
    mov bp, sp
    mov si, [bp+4]
    xor di, di
    xor bx, bx
    xor ax, ax
    mov bx, 10
    cmp [si], "-"
    jnz checkingChar
    inc si
    mov di, 1
        checkingChar:
            xor cx, cx
            mov cl, [si]
            cmp cl, 0Dh
            je checkingBorder
            
            cmp cl, "0"
            jb input_errors
            cmp cl, "9"
            ja input_errors
            
            sub cl, "0"
            mul bx
            add ax, cx
            inc si
            jmp checkingChar
                
        checkingBorder:
            cmp di, 1
            jnz positive_check 
            cmp ax, 32768
            ja input_errors
            je equal_high_border
            
        equal_high_border:
            neg ax    
            jmp end
            
    cmp di, 1
    je sign
    jne end   
sign:
    neg ax
positive_check:
    cmp ax, 32767
    ja input_errors                
end:
    mov sp, bp
    pop bp
    ret                  
endp fromCharToInt

;*******************************

fromIntToChar proc 
    test ax, ax
    jns n_sign
    push ax
    mov ah, 02h
    mov dl, "-"
    mov bl, 1
    int 21h
    pop ax
    neg ax

        n_sign:  
            xor cx, cx
            mov bx, 10
        cr_digit:        
            xor dx, dx
            div bx         
            push dx   
            inc cx 
            test ax, ax
            jnz cr_digit 
       mov ah, 02h
    itoa:      
        pop dx   
        add dl, "0"
        int 21h
        loop itoa 
        ret        
endp fromIntToChar
;###############################

overflow_exc proc
    print_comment reg_ovf
    jmp exit    
endp overflow_exc

input_errors proc
    print_comment except_msg
    jmp exit    
endp input_errors

end start        
endp main