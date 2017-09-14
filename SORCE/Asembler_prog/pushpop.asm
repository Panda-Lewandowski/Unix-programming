;Using instructions push/pop
        IDEAL
        MODEL small  
        STACK 256
        DATASEG
exCode  DB     0

        CODESEG
Start:
        mov ax, @data
        mov ds, ax
        push ax           ;save ax
        push bx
        mov  ax, -1       ; test values
        mov  bx, -2
        mov  cx, 0
        mov  dx, 0
        push ax
        push bx
        pop cx            ; take from stack
        pop dx
        pop bx   
        pop ax
Exit:
        mov ah, 04Ch
        mov al, [exCode]
        int 21h

        END Start 
