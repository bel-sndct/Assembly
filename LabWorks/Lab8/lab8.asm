.model tiny 
.code
org 100h
start:       
jmp installer
    
;data
ret_old_int_flag            db      0                                                              
    
original_IRQ1 	            dd      ?
original_IRQ2 		        dd      ? 
    	 
key_code                    db      0 
save_flag                   db      0   
raw_buffer                  db      screen_width dup (?)
file_newline                db      0Ah  
screen_width                equ     80  
screen_height               equ     25
     
filename                    db      125 dup (?)
file_descriptor             dd      ? 

key_code_str                db      "Enter key for saving terminal information", 0Dh, 0Ah, '$'
key_code_error_str          db      "This symbol is reserved!", 0Dh, 0Ah, '$'
set_key_success             db      "Key is saved", 0Dh, 0Ah, '$'
       
bad_CMD_args                db      "Bad CMD args!", '$'       
file_creation_error 	    db      "File creation ERROR", 0Dh, 0Ah, '$'
   
hello_string			    db      "<Ctrl+G> - save screenshot", 0Dh, 0Ah, "<Ctrl+'your symbol'> - terminate resident program", 0Dh, 0Ah, '$' 
	      
return_ints_str        	    db      0Dh, 0Ah, "Handlers returned. Resident program is terminated", 0Dh, 0Ah
return_ints_str_len   	    equ     51		

file_open_error_str		    db      0Dh, 0Ah, "Error in save proccess!", 0Dh, 0Ah
file_open_error_str_len	    equ     25
	
grab_terminal_str		    db      0Dh, 0Ah, "Screenshot of the terminal is saved!", 0Dh, 0Ah
grab_terminal_str_len 	    equ     38	

macro read_string message
    mov ah, 09h  
    mov dx, offset message 
    int 21h
endm  

macro insert_message_in_vmem message, lenght  
	mov ax, cs
	mov es, ax
	mov ah, 03h
	mov bh, 0
	int 10h 					
	
	mov ah, 13h
	mov al, 00000001b	 
	mov bh, 0                               
	mov bl, 07h  
	mov cx, lenght                          
	lea bp, message
	int 10h  						
endm
    
IRQ1 proc far
		pusha
	    push ds
	    push es
	        
	    mov ax, cs
	    mov ds, ax 
	        
	    cmp save_flag, 1
	    je save_CMD
	        
	    cmp ret_old_int_flag, 1 
	    je ret_interruptions
        
        jmp IRQ1End 
         
        save_CMD:  
	    	mov cs:save_flag, 0  
			open_file:
				mov ah, 3Dh
				mov al, 00000001b	
				lea dx, filename   
				int 21h  
				jc file_open_error
				
				mov file_descriptor, ax
				jmp grab_terminal
			    
			    file_open_error: 
			    	insert_message_in_vmem file_open_error_str, file_open_error_str_len
                	mov cs:ret_old_int_flag, 1
                	jmp IRQ1End                  	
                	
			grab_terminal:
				mov ax, 0B800h
		        mov es, ax 
	
				mov di, 0
				mov cx, screen_height
				  
				get_terminal_loop:	
					push cx	 
					lea si, raw_buffer
					lea dx, raw_buffer 
					mov cx, screen_width
					
					get_raw_loop:  						
						mov al, es:di
						mov [si], al
						inc si
						add di, 2
				    loop get_raw_loop
				    
		       		mov ah, 40h 
		       		mov bx, file_descriptor
		       		mov cx, screen_width 
		       		inc cx
		       		lea dx, raw_buffer
		       		int 21h	 
			     
			        pop cx
		        loop get_terminal_loop
		         
		         closeFile:
					mov ah, 3Eh
					mov bx, file_descriptor
					cli
					int 21h
					sti						
		        	insert_message_in_vmem grab_terminal_str, grab_terminal_str_len  		        	
		    	    jmp IRQ1End 			
	      
	        ret_interruptions: 
			    mov ah, 25h                			  	 
			    mov al, 08h                      		
			    mov dx, word ptr cs:original_IRQ1      
			    mov ds, word ptr cs:original_IRQ1 + 2  
			    int 21h                               
		        
			    mov ah, 25h
			    mov al, 09h                     
			    mov dx, word ptr cs:original_IRQ2
			    mov ds, word ptr cs:original_IRQ2 + 2 	   
			    int 21h                    						                                           	
			    insert_message_in_vmem return_ints_str, return_ints_str_len
    IRQ1End: 
        pushf
        call cs:dword ptr original_IRQ1
        pop es
        pop ds
        popa 
        iret 
IRQ1 endp
    
IRQ2 proc far 
        pusha
        pushf
        call cs:dword ptr original_IRQ2
        
        mov ah, 01h
        int 16h   
        jz IRQ2end   
         
        mov dh, ah 
        
        mov ah, 02h
        int 16h   
        and al, 4
        cmp al, 0	
        jne check_exec_key  
        jmp IRQ2end
        
    check_exec_key:        
        cmp dh, cs:key_code	
        jne check_Q   
   
        mov cs:save_flag, 1
        mov ah, 00h
        int 16h     
      
        jmp IRQ2end
        
    check_Q:
        cmp dh, 10h 
        jne IRQ2end
        mov cs:ret_old_int_flag, 1 
        
        mov ah, 00h
        int 16h
    IRQ2end:
        popa 
        iret 
IRQ2 endp


installer:
    get_cmd_args:
        mov ch, 0
		mov cl, [80h]		    
		cmp cl, 1
		jbe no_param_error		                      
		mov si, 81h
		lea di, filename
		   	
		    parse_cmd:
		        space_check:
		            cmp [si], ' '
		            je space_found
		        	movsb 
		            jmp end_loop
		            
		        space_found:
		        	inc si
		            
		    end_loop:
			loop parse_cmd
		
		create_file:
			mov ah, 3Ch
			mov cx, 00h 
			lea dx, filename    
			int 21h 
			
			jc file_creating_error
				
			mov file_descriptor, ax  
				
			close_file:
				mov ah, 3Eh
				mov bx, file_descriptor
				int 21h    
		
		set_running_key:
		    mov ah, 09h
		    mov dx, offset key_code_str
		    int 21h
		    mov ah, 00h
		    int 16h
		    
		    cmp ah, 10h
		    je q_pressed
            jmp set_key
            
		    q_pressed:
		        mov ah, 09h
		        mov dx, offset key_code_error_str
		        int 21h
		        jmp set_running_key
		        
		    set_key:
		        mov key_code, ah
		        mov ah, 09h
		        mov dx, offset set_key_success
		        int 21h
		        jmp hello_string_mark 
		jmp set_running_key
		
		hello_string_mark:    	 
		    read_string hello_string	    
        
        get_orig_int_addresses:       
            mov ah, 35h
        	mov al, 09h
        	int 21h   
        	
        	mov word ptr original_IRQ2, bx
        	mov word ptr original_IRQ2 + 2, es   
        
	        mov ah, 35h 
	        mov al, 08h 
	        int 21h  
	        
	        mov word ptr original_IRQ1, bx
	        mov word ptr original_IRQ1 + 2, es   
        
        set_interruptions:
            mov ah, 25h
	        mov al, 09h
	        mov dx, offset IRQ2
	        int 21h 
        	
	        mov ah, 25h
	        mov al, 08h 
	        mov dx, offset IRQ1
	        int 21h
	       
        stay_resident:
	        mov ah, 31h
	        mov dx, (installer - start + 10Fh) / 16 
	        int 21h
        
        no_param_error:
            read_string bad_CMD_args 
            jmp end
        file_creating_error:
		    read_string file_creation_error 
		    jmp end
			
    end:
        mov ax, 4Ch
        int 21h                           
end start