IDEAL
MODEL small
STACK 128
DATASEG
CLEAR   DB 27,'[2J'
MESSAGE DB 27,'['
	
COLOR   DB '32'
	DB 'm',27,'[12;35H',201,9 dup(205),187
	DB 27,'[13;35H',186,'Внимание!',186
	DB 27,'[14;35H',200,9 dup(205),188
	DB 27,'[0m',27,'[25;1H$'
CODESEG
BEGIN:  mov ax,@data
	mov ds,ax
	mov ah,9
	mov dx,offset clear
	int 21h
again:	mov ah, 02h
	mov dl, '>'
	int 21h
	mov ah,01h
	int 21h
	mov [COLOR],al
	mov ah,01h
	int 21h
	mov [COLOR+1], al
	mov ah,9
	mov dx, offset message
	int 21h
	jmp again
	mov ax,4c00h
	int 21h
End BEGIN