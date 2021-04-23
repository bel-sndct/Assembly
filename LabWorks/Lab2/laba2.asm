; LAB-2
; variant 7
; .exe

.model small
.stack 100h

.data
    input_msg       db      "Enter your string (max lenght - 200ch): $"       
    ;orig_str        db      200, 200 dup('$')
    orig_str        db      200, 200 dup(?), ?
    input_dword     db      "Enter word for removing (max lenght - 25ch): $"
    msg_for_ofw     db      "Word for removing is too long!$"
    result_msg      db      "Original string after removing: $"
    spcbar_exc      db      "Enter string without spacebars!$"
    space_bar       db      ' '
    end_str         db      '$'
    new_str         db      0Dh, 0Ah, "$"
    
    del_word        db      25, 25 dup("$")
    
.code
main proc
;--------macro-commands--------
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
;------------------------------
        start:
            mov ax, @data
            mov ds, ax
            mov es, ax
            
            print_comment input_msg
            mov ah, 0Ah
            mov dx, offset orig_str
            int 21h
            
            mov bx, dx
            mov al, orig_str[1]
            mov ah, 0
            add bx, ax
            mov [bx+2], "$"
            
            print_newline
            
            print_comment input_dword
            mov ah, 0Ah
            mov dx, offset del_word
            int 21h
            
            xor cx, cx
            mov cl, del_word[1]
            cmp cl, 0
            je endprog ; if ZF = 1
            
            call checkDelWord
            
            xor cx, cx
            mov cl, orig_str[1]
            sub cl, del_word[1]
            jb len_exception
            
            mov cl, orig_str[1]
            mov ch, 0
            cld
            
            mov si, offset orig_str[2]
            mov di, offset del_word[2]
    
    delcycle:                   ; loop by string
        call compareStrings
        loop delcycle

    endprog:
        print_newline
        print_comment result_msg
        print_comment orig_str[2]
        mov ax, 4C00h
        int 21h
        
        ; end start
        
    checkDelWord proc
        mov al, ' '
        mov di, offset del_word[2]
        xor cx, cx
        mov cl, del_word[1]
        repne scasb
        je jmpend
        jne jmpret
        
        jmpend:
            print_newline
            print_comment spcbar_exc
            je endprog
              
        jmpret:
            ret
    endp checkDelWord
        
    len_exception proc
        print_newline
        print_comment msg_for_ofw
        mov ax, 4C00h
        int 21h
        ret
    endp len_exception
    
    deletingWord proc
        push si
        push di
        mov di, bx
        xor cx, cx
        mov cl, orig_str[1]
        repe movsb    
        pop di
        pop si
        ret
    endp deletingWord
    
    compareStrings proc     ; strings comparison
        push cx
        push si
        push di
        mov bx, si
        xor cx, cx
        mov cl, del_word[1]
        repe cmpsb  ; while ZF = 1
        je found
        jne notfound
    
        found:
            push si
            push di
            push cx
            xor cx, cx
            mov di, offset space_bar
            mov cl, 1
            repe cmpsb
            pop cx
            pop di
            pop si
            je delPoint
            
            push si
            push di
            push cx
            xor cx, cx
            mov di, offset end_str
            mov cl, 1
            repe cmpsb
            pop cx
            pop di
            pop si
            je delPoint
            jne notfound
            
        delPoint:
            push si
            push bx
            mov si, offset orig_str[1]
            sub bx, 1
            cmp bx, si
            pop bx
            pop si
            je del
        
            cmp [bx-1], ' ' 
            je del
            jne notfound
            
        del:
            call deletingWord  
                
        notfound:
            pop di
            pop si
            pop cx
            inc si
            ret        
    endp compareStrings

endp main