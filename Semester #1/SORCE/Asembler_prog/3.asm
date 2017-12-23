MODEL SMALL
STACK 256

DATASEG
	envir db 'Окружение=****h',10,13,'$'
	psp db 'Префикс= ****h',10,13,'$'
	csseg db 'Код прог=****h',10,13,'$' 
	tblhex db '0123456789ABCDFE','$'

CODESEG

Start:   mov ax,@data
	 mov ds,ax
	 mov ax,[es:2Ch]
	 mov si,offset envir+10
	 call binasc
	 mov ah,09h
	 mov dx,offset envir
	 int 21h
	 mov ax,es
	 mov si,offset psp+10
	 call binasc
	 mov ah,09h
	 mov dx,offset psp
	 int 21h
	 mov ax,es
	 mov si,offset csseg+10
	 call binasc
	 mov ah,09h
	 mov dx,offset csseg
	 int 21h
 	 mov ax,4C00h
	 int 21h
	 
proc 	 hexasc
	 push bx
	 mov bx,offset tblhex
	 xlat
	 mov [si],al
	 pop bx
	 ret
endp	 hexasc

proc 	 binasc
	 push cx
	 push ax
	 and ax,0F000h
	 mov cl,12
	 shr ax,cl
	 call hexasc
	 pop ax
	 push ax
	 and ax,0F00h
	 mov cl,8
	 shr ax,cl
	 inc si
	 call hexasc
	 pop ax
	 push ax
	 and ax,0F0h
	 mov cl,4
	 shr ax,cl
	 inc si
	 call hexasc
	 pop ax
	 push ax
	 and ax,0Fh
	 inc si
	 call hexasc
	 pop ax
	 push ax
	 ret
endp	 binasc

	 
END START