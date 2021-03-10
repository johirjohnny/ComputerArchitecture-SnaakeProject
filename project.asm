left equ 0
top equ 2
row equ 15
col equ 40 
right equ left+col
bottom equ top+row

.model small
.data 
msg db "Welcome to the Snake Game !",0
instructions db 0ah,0dh,"Use a,s,d and f to coontrol your Snake",0ah,0dh,"Use q anytime to quit",0dh,0ah,"Press any key to continue$"
quitmsg db "Thanks for playing! Hope you enjoyed it",0 
gameovermsg db "OOPS!! Your Snake died ! :P ",0
scoremsg db "Score: ",0
head db '^',10,10
body db '*',10,11,3*15 dup(0)
segmentcount db 1
fruitactive db 1
fruitx db 8
fruity db 8
gameover db 0
quit db 0
delaytime db 5

.stack
dw 128 dup(0)

.code
main proc far
    mov ax,@data
    mov ds,ax
    
    mov ax,0b800h
    mov es,ax
    
    ;clearing the screen
    mov ax,0003h
    int 10h
    
    lea bx,msg
    mov dx,00
    call writestringat
    
    lea dx,instructions
    mov ah,09h
    int 21h
    
    mov ah,07h
    int  21h
    mov ax,0003h
    int 10h
  call printbox
  
mainloop:
    call delay
    lea bx,msg
    mov dx,00
    call writestringat
    call shiftsnake 
    cmp gameover,1 
    je gameover_mainloop
    
    call keyboardfunctions
    cmp quit,1
    je quitpressed_mainloop
    call fruitgeneration
    call draw
    
    ;TODO check gameover and quit
    
    jmp mainloop
    
gameover_mainloop:
    mov ax,0003h
    int 10h
    mov delaytime,100
    mov dx,0000h
    lea bx,gameovermsg
    call writestringat
    jmp quit_mainloop
    
quitpressed_mainloop:
                
    mov ax,0003h
    int 10h
    mov delaytime, 100
    lea bx,quitmsg
    call writestringat
    call delay
    jmp quit_mainloop

quit_mainloop:
    ;first clear screen
    mov ax,0003h
    int 10h
    mov ax,4c00h
    int 21h

delay proc
    
    mov ah,00
    mov bx,dx
    int 1ah
    mov bx,dx
    
jmp_delay:
    
    int 1ah
    sub dx,bx
    cmp dl,delaytime
    jl jmp_delay
    ret
delay endp

;continue from 3:24

fruitgeneration proc
    mov ch,fruity
    mov cl,fruitx
regenerate:

    cmp fruitactive,1
    je ret_fruitactive
    mov ah,00
    int 1ah
    ;contains the ticks
    push dx
    mov ax,dx
    xor dx,dx
    xor bh,bh
    mov bl,row
    dec bl
    div bx
    inc fruity
    
    
    pop ax
    mov bl,col
    dec dl
    xor bh,bh
    xor dx,dx
    div bx
    mov fruitx,dl
    inc fruitx
    
    cmp fruitx,cl
    jne nevermind  
    cmp fruity,ch
    jne nevermind
    jmp regenerate
nevermind:
    mov al,fruitx
    ror al,1
    jc regenerate
    
    add fruity,top
    add fruitx,left
    
    
    mov dh,fruity
    mov dl,fruitx
    call readcharat
    cmp bl,'*'
    je regenerate
    cmp bl,'^' 
    je regenerate
    cmp bl,'<'
    je regenerate
    cmp bl,'>'
    je regenerate
    cmp bl,'v'
    je regenerate
    
ret_fruitactive:
    ret
fruitgeneration endp

dispdigit proc
    add dl,'0'
    mov ah,02h
    int 21h
    ret
    dispdigit endp
dispnum proc
    test ax,ax
    jz retz
    xor dx,dx
    ;ax contains the number to displayed
    ;b mmust contain 10
    mov bx,10
    div bx
    ;dispnum ax first
    push dx
    call dispnum
    pop dx
    call dispdigit 
    ret
    
retz:
    mov ah,02
    ret
    dispnum endp 
;set the cursor position ,ax and bx used, dh=row,dl=colomn
;preserve other register
setcursorpos proc
    mov ah,02h
    push bx
    mov bh,0
    int 10h
    pop bx
    ret
    setcursorpos endp
draw proc
    lea bx,scoremsg
    mov dx,0109
    call writestringat
    
    
    add dx,7
    call setcursorpos
    mov al,segmentcount
    dec al
    xor ah,ah
    call  dispnum
    
    les si,head
draw_loop:
    mov bl,ds:[si]
    test bl,bl
    jz out_draw
    mov dx,ds:[si+1]
    call writecharat
    add si,3
    jmp draw_loop
    
out_draw:
    mov bl,'F'
    mov dh,fruity
    mov dl,fruitx
    call writecharat
    mov fruitactive,1
    
    ret
    
draw endp


;dl comntains the ascii charecter if keypress,else dl contains 0
;users dx and ax,preserves other registers
readchar proc
    mov ah,01h
    int 16h
    jnz keybdpressed
    xor dl,dl
    ret
keybdpressed:
    ;extract keystrike from the buffer
    mov ah,00h
    int 16h
    mov dl,al
    ret
    
    

;Continue from 4:26 of the  video  


readchar endp

keyboardfunctions proc
    call readchar
    cmp dl, 0
    je next_14
    
    ;so a key was pressed , which was passed then solti?
    
    cmp dl,'w'
    jne next_11
    cmp head, 'v'
    je next_14
    mov head, '^'
    ret
    
next_11:
    cmp dl,'s'
    jne next_12
    cmp head,'^'
    je next_14
    mov head,'v'
    ret
    
next_12:
    cmp dl,'a'
    jne next_13
    cmp head,'>'
    je next_14
    mov head ,'<'
    ret
    
next_13:
    cmp dl,'d'
    jne next_14
    cmp head,'<'
    je next_14
    mov head,'>'
    
next_14: 
    cmp dl,'q'
    je quit_keyboardfunctions
    ret
quit_keyboardfunctions:    
    ;conditions for quiting in here please
    inc quit
    ret
    
keyboardfunctions endp 



shiftsnake proc
    mov bx,offset head
    
    ; determine the where should the head go solti?
    ; preserve the head 
    
    xor ax, ax
    mov al,[bx]
    push ax
    inc bx
    mov ax,[bx]
    inc bx
    inc bx
    xor cx,cx
    
 l:
    mov si,[bx]
    test si,[bx]
    jz outside
    inc cx
    inc bx
    mov dx,[bx]
    mov ax,dx
    inc bx
    inc bx
    jmp 1
    
outside:

;hopefully trhe snake will be shifted ,i .e moved. 
;now shift the head in its proper direction and then clean the last segment
;but, don't clean the last segment if the snake has eaten the fruit
pop ax
;al contains the snake head direction

push dx
;dx now consists the coordinates of the last segment , we can use this 

    lea bx, head
    inc bx
    mov dx,[bx]
    
    cmp al,'<'
    jne  next_1
    dec dl
    dec dl
    jmp done_checking_the_head
next_1:
    cmp al,'>'
    jne next_2
    inc dl
    inc dl 
    jmp done_checking_the_head    
    
next_2:
    cmp al,'^'
    jne  next_3
    dec dh
    
    jmp done_checking_the_head
    
next_3:
;must be 'v'
    inc dh
    
    
done_checking_the_head: 

    mov [bx], dx
    ;dx contains the new positions of the head, now check whats in the position
    call readcharat ;dx
    ;bl contins the result
    
    cmp bl,'F'
    je i_ate_fruit 
    
    
    ;if fruit was not eaten, then clear the last segment,
    ;it will be cleared where?
    
    mov cx,dx
    pop dx
    cmp bl,'*'  ;the snake bit itself , gameover 
    je game_over 
    mov bl,0
    call writecharat
    mov dx,cx
    
    
    ;check whether the snake is within the boundary
    cmp dh, top
    je game_over 
    cmp dh,bottom
    je game_over 
    cmp dl,left
    je game_over
    cmp dl,right
    je game_over 
    
    
    ;balance the stack, number of segment and the coordinate of the last segment 
    ret
    
 game_over:
    inc gameover 
    ret
    
    
i_ate_fruit:

    ;add a new segment then
    mov al, segmentcount
    xor ah, ah
    
    lea bx, body 
    mov cx, 3
    mul cx
    
    pop dx
    add bx,ax
    mov byte ptr ds:[bx],'*'
    mov [bx+1],dx 
    inc segmentcount
    mov dh, fruity
    mov dl, fruitx
    mov bl,0
    call writecharat
    mov fruitactive,0
    ret
shiftsnake endp 

;printbox
printbox proc
;draw a box around
    mov dh,top
    mov dl,left
    mov cx,col
    mov bl,'*'
    
11:

    call writecharat
    inc dl
    loop 11
    mov cx, row
    
12:
    call writecharat
    inc dh
    loop 12
    
    mov cx, col
    
13:
    call writecharat
    dec dl
    loop 13
    mov cx, row
    
14:
    call writecharat
    dec dh 
    loop 14
    
    ret
printbox endp 


;dx contains row ,col
;bl contains the character to write
;uses di.

writecharat proc
    ;80x25
    push dx
    mov ax,dx
    and ax,0FF00H
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    
    push bx
    mov bh,160
    mul bh
    pop bx
    and dx,0FFH
    shl dx,1
    add ax,dx
    mov di,ax
    mov es:[di],bl
    pop dx
    ret
    
writecharat endp

;dx contains row ,col
;returns the character at b1
;uses di
readcharat proc
    push dx
    mov ax,dx
    and ax,0FF00H
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    
    push bx
    mov bh,160
    mul bh
    pop bx
    and dx,0FFH
    shl dx,1
    add ax,dx
    mov di,ax
    mov es:[di],bl
    pop dx
    ret
readcharat endp 
    
;dx contains row,col
;bx contains the offset of the string
writestringat proc
    push dx
    mov ax,dx
    and ax,0FF00H
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    
    push bx
    mov bh,160
    mul bh
    
    
    pop bx
    and dx,0FFH
    shl dx,1
    add ax,dx
    mov di,ax
loop_writestringat:

    mov al,[bx]
    test al,al
    jz exit_writestringat
    mov es:[di],al
    inc di
    inc di
    inc bx
    jmp loop_writestringat
    
exit_writestringat:
    pop dx
    ret  
    
    
writestringat endp

end main   