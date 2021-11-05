.model small
.stack 100h
.data
    max_cmd_size            equ     127
    cmd_size                db      ?
    cmd_text                db      max_cmd_size + 2 dup(0)
    
    source_file_path        db      max_cmd_size + 2 dup(0)    
    file_descriptor         dw      0
    
    tmp_file                db      "C:\", 0Dh dup(0)
    tmp_file_descriptor     dw      0
    
    buffer                  dw      0
    ASCIIZ_char             equ     0
    
    starting_prog_msg       db      "Program is running$", '$'
    bad_cmd_args_msg        db      "Bad CMD args!$", '$'
    bad_open_file_msg       db      "Cannot open source file$", '$'
    file_not_found_msg      db      "File not found$", '$'
    closing_file_error_msg  db      "Cannot close file$", '$'
    end_prog_msg            db      "Program is complete$", '$'
    read_file_error_msg     db      "Reading source file ERROR$", '$'
    bad_number_msg          db      "Bad number!$", '$'
    number_range_error      db      "Number range was exceeted!$", '$'
    processing_error        db      "File processing ERROR$", '$'
    too_long_word_msg       db      "Too long word for removing found!$", '$'
    
    number_str              db      7, 7 dup(0)
    frequency               dw      0
    counter                 db      0
    current_word_index      dw      0       

.code
print_comment macro message
    push ax
    push dx

    mov ah, 09h
    mov dx, offset message
    int 21h
    
    mov ah, 02h 
    mov dl, 0Ah
    int 21h
    
    mov ah, 02h 
    mov dl, 0Dh
    int 21h
 
    pop dx
    pop ax
endm

reset_file_pointer macro descriptor
    push ax 
    push bx
    push cx
    push dx
 
    mov ah, 42h
    mov bx, descriptor
    mov al, 0       
    mov cx, 0
    mov dx, 0         
    int 21h
 
    pop dx
    pop cx
    pop bx
    pop ax
endm

main:
    mov ax, @data
    mov ds, ax
    
    mov cl, es:[80h]
    cmp cl, 1
    jbe bad_cmd_mark
    mov cmd_size, cl
    
    mov di, 81h
    lea si, cmd_text
        get_cmd_text:
            mov al, es:[di]
            cmp al, 0Dh
            je start_processing
            mov [si], al
            inc di
            inc si
        jmp get_cmd_text
            
    start_processing:
    print_comment starting_prog_msg
    
    call parce_cmd        
    call open_source_file
    call files_handler    
    call close_files
    jmp end_main
    
bad_cmd_mark:
   print_comment bad_cmd_args_msg
   jmp end_main     
    
end_main:
    print_comment end_prog_msg
    mov ax, 4C00h
    int 21h
    
;---------------end main----------------    
    
parce_cmd proc
    push bx
    push ax 
    push cx 
    push dx
    
    mov cl, cmd_size
    xor ch, ch
        
        mov si, offset cmd_text
        mov di, offset source_file_path

        skip_spacebars1:
            cmp [si], ' '
            jne write_filepath1            
            skip_sym1:
                inc si
                dec cl
                jmp skip_spacebars1
                
        write_filepath1:
            mov al, [si]
            mov [di], al
            inc si
            inc di
            dec cl
            cmp cl, 0
            je bad_args_mark
            cmp [si], ' '
            jne write_filepath1
            
        mov al, ASCIIZ_char
        mov ds:[di], al
        
        mov di, offset number_str
        skip_spacebars2:
            cmp cl, 0
            je bad_args_mark
            cmp [si], ' '
            jne write_number                        
            skip_sym2:
                inc si
                dec cl
                jmp skip_spacebars2
                
        write_number:
            mov al, [si]
            mov [di], al
            inc si
            inc di
            dec cl
            cmp cl, 0
            je atoi_mark
            cmp [si], ' '
            jne write_number
        
        atoi_mark:    
            call str_to_int
            
        cmp frequency, 0
        jne parce_cmd_end
        
        bad_args_mark:
            print_comment bad_cmd_args_msg
            jmp end_main        

parce_cmd_end:
    pop dx 
    pop cx
    pop ax 
    pop bx     
    ret        
parce_cmd endp 

;----------end cmd parcer----------

str_to_int proc
    push ax
    push bx
    push dx
    push si
    
    lea si, number_str
    
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
        	mov ax, frequency
        	mov dx, 10
        	mul dx
        	mov frequency, ax
        	add frequency, bx
        
        	inc si
        jmp make_int
        
        cmp frequency, 07FFFh
        jae out_of_range
        
    exit_str_to_int:
        cmp frequency, 07FFFh
        jae out_of_range
        pop si
    	pop dx
    	pop bx
    	pop ax
    	ret
    	
out_of_range:
    print_comment number_range_error
    jmp end_main
    	
bad_num:
    print_comment bad_number_msg
    jmp end_main   
str_to_int endp

open_source_file proc
    push bx 
    push dx
 
        mov ah, 3Dh
        mov al, 01000010b         
        mov dx, offset source_file_path
        mov cl, 01h
        int 21h
         
        jb bad_open_file         
        mov file_descriptor, ax
        
        mov ah, 5Ah       
	    mov cx, 00h		
	    mov dx, offset tmp_file
	    int 21h

	    jb bad_open_tmp_file		
	    mov tmp_file_descriptor, ax	

	    jmp end_open_source_file
 
    bad_open_file:
        print_comment bad_open_file_msg
        cmp ax, 02h
        jne error_found     
        print_comment file_not_found_msg     
        jmp error_found
        
    bad_open_tmp_file:     
        jmp error_found
        
error_found:
    jmp end_main
    
end_open_source_file:
    pop dx
    pop bx
    ret
open_source_file endp

;---------------read-write------------

read_char_from_file proc
    mov ah, 3Fh
    mov cx, 01h
    mov dx, offset buffer
    int 21h
    ret
read_char_from_file endp

write_char_to_file proc
    mov ah, 40h
    mov cx, 01h
    mov dx, offset buffer
    int 21h
    ret    
write_char_to_file endp

;-------------------------------------

files_handler proc
    pusha
    
    reset_file_pointer file_descriptor
    reset_file_pointer tmp_file_descriptor
    
    cmp frequency, 1
    je clear_src_file
    
    processing_files:
        mov bx, file_descriptor
        call read_char_from_file
        jb error_mark
        
        cmp ax, cx
        jne get_info_from_tmp_file
    
        mov ax, buffer
        
        cmp ax, 020h
        je check_removing_flag                
        
    continue:    
        mov bx, tmp_file_descriptor
        call write_char_to_file
        jb error_mark
        jmp processing_files
    
            check_removing_flag:
                inc current_word_index
                push ax
                mov ax, current_word_index
                inc ax
                cmp ax, frequency
                pop ax
                jne continue
                
                push bx
                mov bx, tmp_file_descriptor
                call write_char_to_file
                pop bx
                
                skip_word_loop:
                    call read_char_from_file
                    cmp buffer, 0Dh
                    jne check_spacebar
                    jmp reset_index
                        check_spacebar:
                            cmp buffer, 020h
                            je reset_index
                            cmp buffer, 02Eh
                            je is_spec_point
                            cmp buffer, 02Ch
                            je is_spec_point        
                            cmp buffer, 09h
                            je is_spec_point
                        jmp skip_word_loop
                                                
            reset_index:    
                mov current_word_index, 0                                
                jmp continue
                
            is_spec_point:
                mov bx, tmp_file_descriptor
                call write_char_to_file
                mov bx, file_descriptor
                call read_char_from_file
                mov current_word_index, 0                                
                jmp continue                 
        
    get_info_from_tmp_file:
        reset_file_pointer file_descriptor
        reset_file_pointer tmp_file_descriptor
        
        mov ah, 40h
        mov bx, file_descriptor
        mov cx, 0
        int 21h
        
        rewrite_source_file:
            mov bx, tmp_file_descriptor
            call read_char_from_file
            jb error_mark
            
            cmp ax, cx
            jne files_handler_end
            
            mov bx, file_descriptor
            call write_char_to_file
            jb error_mark
            jmp rewrite_source_file            

    clear_src_file:
        mov ah, 40h
	    mov bx, file_descriptor 
        mov cx, 0
        int 21h

files_handler_end:
    popa
    ret        
        
error_mark:
    print_comment processing_error
    jmp end_main
files_handler endp

close_files proc 
	push bx 
	push cx
	xor cx, cx

	mov ah, 3Eh 
	mov bx, file_descriptor
	int 21h
    jnb closing_file_ok
	jmp closing_error

    closing_file_ok:         
        mov ah, 3Eh
    	mov bx, tmp_file_descriptor
    	int 21h
    
    	jnb closing_tmp_file_ok			
        jmp closing_error
    
    closing_tmp_file_ok:
        mov ah, 41h            
        xor cx, cx
        mov dx, offset tmp_file 
        int 21h
        jnb closing_files_end
        jmp closing_error

closing_files_end:
    pop cx 
	pop bx
	ret
    
closing_error:
    print_comment closing_file_error_msg
    jmp end_main
close_files endp

end main