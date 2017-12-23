MODEL small
STACK 128
DATASEG
actlet  dw 0
outbuf  db 27, '[34;46m'
escc = $-outbuf
inbuf  db 128 dup('*')
reset  db 27,'[0m$'
CODESEG
BEGIN:  mov ax,@data
	mov ds,ax
	;mov ah,9
	;mov dx,offset clear
	;int 21h
	mov ah, 02h
	mov dl, '>'
	int 21h
	mov ah,3fh
	mov bx,0
	mov cx,128
	mov dx, offset inbuf
	int 21h
	mov actlet, ax
	mov ah, 40h
	mov bx, 1
	mov cx, actlet
	add cx, escc-2
	mov dx, offset outbuf
	int 21h
	mov ah, 09h
	mov dx, offset reset
	int 21h
	mov ax,4c00h
	int 21h
End BEGIN