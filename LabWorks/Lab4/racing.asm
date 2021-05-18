.model small

.stack 100h

.data
end_of_game         db      0
BRICK               equ     0D2Eh

car_position        dw      0D70h
car_size            equ     3
speed               dw      0AAAAh

left_offset         db      20
right_offset        db      20

remove_car_str      dw      00DBh, 00DBh, 00DBh
barrier             dw      0EFEh, 0EFEh, 0EFEh, 0EFEh, 0EFEh

game_over           dw      0C47h, 0C61h, 0C6Dh, 0C65h, 0C20h, 0C4Fh, 0C76h, 0C65h, 0C72h

e_message           dw      0F50h, 0F72h, 0F65h, 0F73h, 0F73h, 0C20h, 0F27h, 0F65h, 0F73h, 0F63h, 0F27h, 0C20h, 0F74h, 0F6Fh, 0C20h, 0F65h, 0F78h, 0F69h, 0F74h
e_offset            dw      085Ch
                            
r_message           dw      0F50h, 0F72h, 0F65h, 0F73h, 0F73h, 0C20h, 0F27h, 0F65h, 0F6Eh, 0F74h, 0F65h, 0F72h, 0F27h, 0C20h, 0F74h, 0F6Fh, 0C20h, 0F72h, 0F65h, 0F6Ch, 0F6Fh, 0F61h, 0F64h                      
r_offset            dw      08F8h

score_message       dw      0F53h, 0F63h, 0F6Fh, 0F72h, 0F65h, 0F3Ah
score               dw      0
score_pr            dw      0F00h

barr_occur_freq     db      15

.code

drawing_edge proc
    drawing_edge_loop:
        mov es:[bx], BRICK
        add bx, 2
    loop drawing_edge_loop    
drawing_edge endp

next_frame_delay proc
    mov ah, 86h
    mov dx, speed
    int 15h
    ret
next_frame_delay endp

key_press_check proc 
    mov ah, 01h
    int 16h
    jz endpr
    mov dl, al
    mov ah, 0Ch
    int 21h 
    mov al, dl
    cmp al, "a"
    je move_left
    cmp al, "d"
    je move_right
    jne endpr
    
    move_left:
        sub car_position, 2
        jmp endpr    
    move_right:
        add car_position, 2
        jmp endpr
endpr:
    ret
key_press_check endp

show_border proc
    push ax
    xor dx, dx
    xor di, di
    call generate_race
    cmp dl, 4
    jbe left
    cmp dl, 5
    jae right
    
    show_border_cntn:
        mov di, 0
        mov cl, left_offset  
        show_left_border_loop:
            add di, 2
        loop show_left_border_loop
        
        mov es:[di], BRICK
        add di, 80
        mov es:[di], BRICK
        
        dec barr_occur_freq
        cmp barr_occur_freq, 0
        jne end_sh
        mov barr_occur_freq, 15
        call create_barrier
    end_sh:    
        pop ax
        ret
        
    left:
        cmp left_offset, 1
        je show_border_cntn
        dec left_offset
        inc right_offset
        jmp show_border_cntn
    right:
        cmp right_offset, 1
        je show_border_cntn
        inc left_offset
        dec right_offset
        jmp show_border_cntn
        
show_border endp

car_crush_checking proc
    mov si, car_position
    sub si, 160
    mov cx, car_size
    
        is_crush_loop:
            mov ax, es:[si]
            cmp ax, BRICK
            je car_crush
            cmp ax, 0EFEh
            je car_crush
            add si, 2
        loop is_crush_loop
        ret
        
    car_crush:
        mov end_of_game, 1
        ret    
car_crush_checking endp

generate_race proc
    push ax
    push bx
    push cx
    mov ah, 2Ch    ;CH - hours, CL - minutes, DH - seconds, DL - fraction of second
    int 21h
    xor bx, bx
    mov bl, dl
    mov ax, dx
    mul bx
    mov bx, 10
    xor dx, dx
    div bx
    pop cx
    pop bx
    pop ax
    ret 
generate_race endp

draw_car_on_the_screen proc
    mov di, car_position
    mov es:[di], 03DAh
    mov es:[di] + 2, 03CFEh
    mov es:[di] + 4, 03BFh
    ret    
draw_car_on_the_screen endp

shift_down_screen proc
    mov ah, 07h
    mov al, 01h
    mov dh, 19h
    mov dl, 50h
    int 10h
    ret
shift_down_screen endp

remove_car proc
    mov di, car_position
    mov si, offset remove_car_str
    mov cx, car_size
    rep movsw
    ret
remove_car endp

create_barrier proc
    call generate_race
    xor bx, bx
    xor ax, ax
    mov al, dl
    mov bx, 8
    mul bx
    mov dl, left_offset
    mov di, dx
    add di, dx
    add di, ax
    mov si, offset barrier
    mov cx, 5
    rep movsw
    ret
create_barrier endp

show_score proc
    mov di, 0F46h
    mov si, offset score_message
    mov cx, 6
    rep movsw
    mov ax, score
    mov cx, 5
    mov di, 0F5Ah
    
        score_loop:
            xor dx, dx
            mov bx, 10
            div bx
            add dl, "0"
            add score_pr, dx
            mov si, offset score_pr
            movsw
            mov score_pr, 0F00h
            sub di, 4
        loop score_loop
    ret
show_score endp

main:
    mov ax, @data
    mov ds, ax
    mov ah, 00h
    mov al, 03h
    int 10h
    mov ax, 0B800h
    mov es, ax
new_game:    
        xor bx, bx
        xor cx, cx

        mov cl, 20    
        call drawing_edge
        
        add bx, 80
        mov cl, 20
        call drawing_edge
        
    mov end_of_game, 0
    mov left_offset, 20
    mov right_offset, 20
    mov car_position, 0D70h
    mov score, 0
        call shift_down_screen
;####################################
game_process_loop:
    call next_frame_delay
    call remove_car
    call show_border
    call key_press_check  
    call car_crush_checking
    cmp end_of_game, 1
    je end_msg
    call shift_down_screen
    call draw_car_on_the_screen
    inc score
    call show_score
jmp game_process_loop
;####################################
    end_msg:    
        mov ax, 0003h
        int 10h
        mov di, 07C6h
        mov si, offset game_over
        mov cx, 9
        rep movsw
        mov di, e_offset                                   
        mov si, offset e_message                           
        mov cx, 19
        rep movsw
        mov di, r_offset
        mov si, offset r_message
        mov cx, 23
        rep movsw
        call show_score
    end:
        mov ah, 00h
        int 16h
        cmp al, 00Dh
        je new_game
        cmp al, 01Bh
        jne end
        
        mov ax, 0003h
        int 10h        
        mov ax, 4C00h
        int 21h                
end main   