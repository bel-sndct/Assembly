.model small

.stack 100h

.data

block_EPB        dw  0        ;сегмент среды для загружаемой программы
    cmd_offset   dw  offset cmd, 0   ;смещение командной строки
    struct_FCB1  dw  005Ch, 0
    struct_FCB2  dw  006Ch, 0
    cmd          db  0Ah, ' '
    cmd_text     db  125 dup(0), 0Dh, '$'
lenght_block_EPB = $ - block_EPB

program_path        db      "lab7.exe", 0
no_args_cmd         db      "One argument is expected!", '$'
error_msg           db      "Bad CMD args! Range [1 - 255]", '$'
realloc_error_msg   db      "Realloc error!", '$'
run_error_msg       db      "Running error!", '$'
run_msg             db      "Program is running. ID - ", '$'
end_msg             db      "Program is ended. ID - ", '$'
number_rep          dw      ?
cmd_lenght          db      0
minus               dw      0
bad_num_flag        dw      ?
bad_cmd_flag        dw      ?
num_buffer          dw      0

string              db      7, 7 dup('$')
string_end = $ - 1

data_segment_size = $ - block_EPB

.code
main:
    mov ax, es
    mov bx, (code_segment_size/16 + 1) + (data_segment_size/16 + 1) + 256/16 + 256/16
    
    mov ah, 4Ah
    int 21h
    jc realloc_error

    mov ax, @data
    mov es, ax
    
        xor ch, ch
        mov cl, ds:[80h]
        cmp cl, 1
        jl no_cmd
        dec cl
        mov cmd_lenght, cl
    
    mov si, 81h
    inc si
    lea di, cmd_text
    rep movsb
    
    mov ds, ax
    call cmd_parser
    cmp bad_cmd_flag, 1
    je exit
    
    lea dx, run_msg
    call print_msg
    lea dx, cmd_text
    call print_msg
    
    dec number_rep
    cmp number_rep, 0
    je zero_out
    
    call change_cmd
    
    mov bx, offset block_EPB
    mov ax, ds
    mov word ptr[block_EPB + 4], ax 
	mov ax, cs 
	mov word ptr[block_EPB + 8], ax 
	mov word ptr[block_EPB + 12], ax

    mov ax, 4B00h
    lea dx, program_path
    lea bx, block_EPB
    int 21h
    jc run_program_error

zero_out:    
    lea dx, end_msg
    call print_msg
    inc number_rep
    call int_to_str
    lea dx, [di + 1]
    call print_msg
    call newline
    ;inc number_rep
    
exit:
    mov ax, 4C00h
    int 21h

no_cmd:
    mov ds, ax
    lea dx, no_args_cmd
    call print_msg
    jmp exit
    
realloc_error:
    lea dx, realloc_error_msg
    call print_msg
    jmp exit
    
run_program_error:
    lea dx, run_error_msg                     
    call print_msg
    jmp exit
    
change_cmd proc
    push ax
    push si
    lea si, cmd_text
    
    cur_cmd_loop:    
        mov al, [si]
        cmp al, 0
        je dec_number
        inc si
    jmp cur_cmd_loop
    
    dec_number:
        dec si
        mov al, [si]
        cmp al, '0'
        je prev_sym
    back:
        sub al, 1
        mov [si], al
        jmp exit_change_cmd
        
    prev_sym:
        mov al, '9'
        mov [si], al
        dec si
        mov al, [si]
        cmp al, '1'
        je nine
        cmp al, '0'
        je prev_sym
        jmp back
            
    nine:
        inc si
        inc si
        mov al, [si]
        dec si
        dec si
        cmp al, '9'
        jne next
        mov al, ' '
        mov [si], al
        jmp exit_change_cmd
    next:
        mov al, '9'
        mov [si], al
        inc si
        mov al, 0
        mov [si], al
        
exit_change_cmd:
    pop si
    pop ax
    ret   
change_cmd endp    

newline proc
    mov dl, 0Ah
    mov ah, 02h
    int 21h    
    ret
newline endp

cmd_parser proc
    push dx
    mov bad_cmd_flag, 0
    
        call str_to_int
        cmp bad_num_flag, 1
        je cmd_error
        
        cmp number_rep, 255
        jg cmd_error
        
        cmp number_rep, 1
        jl cmd_error
    
    exit_cmd_parse:
        pop dx
        ret
        
cmd_error:
    mov bad_cmd_flag, 1
    lea dx, error_msg
    call print_msg
    jmp exit_cmd_parse
    
cmd_parser endp

print_msg proc
    push ax
    mov ah, 09h
    int 21h
    pop ax
    ret
print_msg endp
    
str_to_int proc
    push ax
    push bx
    push dx
    push si
    
    mov bad_num_flag, 0
    lea si, cmd_text
    
    skip_bad_chars:
        cmp [si], ' '
        je inc_si
        jne start_atoi
    inc_si:
        inc si
        jmp skip_bad_chars
            
    start_atoi:
        mov number_rep, 0
    
        make_int:
            xor ax, ax
            mov al, [si]
            cmp al, 0
            je exit_str_to_int
            
            cmp al, '0'
            jl bad_num
            cmp al, '9'
            jg bad_num
            
            sub al, '0'
        	mov bx, ax
        	mov ax, number_rep
        	mov dx, 10
        	mul dx
        	mov number_rep, ax
        	add number_rep, bx
        
        	inc si
        jmp make_int
    
    exit_str_to_int:
        pop si
    	pop dx
    	pop bx
    	pop ax
    	ret
    	
bad_num:
    mov bad_num_flag, 1
    jmp exit_str_to_int    
str_to_int endp

int_to_str proc 
	push ax
	push cx
	push dx
	
	mov ax, number_rep
	std 
	lea di, string_end - 1 

	mov cx,10 
	
        repeat: 
        	xor dx,dx 	
        	idiv cx 	 
        			 
        	xchg ax,dx 	 
        	add al,'0' 	 
        	stosb 		 
        	xchg ax,dx 	 
        	or ax,ax	
        jne repeat 

	pop dx
	pop cx
	pop ax
	ret 
endp int_to_str    
    
code_segment_size = $ - main    
    
end main