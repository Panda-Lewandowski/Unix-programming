;  2.12.2  Character Device Driver
;The following program illustrates a character device driver
;program

;********************** A CHARACTER DEVICE ****************************
title vt52 console for 2.0  (IBM)
;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;
; IBM ADDRESSES FOR I/O
;
;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

        cr = 13         ;carriage return
        backsp = 8      ;backspace
        escape = 1Bh
        brkaddr = 6Ch   ;006C break vector address
        asnmax = 200    ;size of key assignment buffer

code    segment byte
   assume  cs:code,ds:nothing,es:nothing
;--------------------------------------------------------------------
;
;  C O N - CONSOLE DEVICE DRIVER
;
condev:                           ;header for device "con"
        dw      -1,-1
        dw      1000000000000011b ;con in  and  con out
        dw      strategy
        dw      entry
        db      'CON     '

;--------------------------------------------------------------------
;
;  COMMAND JUMP TABLES
;
contbl:
        dw      con$init
        dw      exit
        dw      exit
        dw      cmderr
        dw      con$read
        dw      con$rdnd
        dw      exit
        dw      con$flsh
        dw      con$writ
        dw      con$writ
        dw      exit
        dw      exit

cmdtabl db      'A'

;                                                               page 2 - 44

        dw      CUU     ;cursor up
        db      'B'
        dw      CUD     ;cursor down
        db      'C'
        dw      CUF     ;cursor forward
        db      'D'
        dw      CUB     ;cursor back
        db      'H'
        dw      CUH     ;cursor position
        db      'J'
        dw      ED      ;erase display
        db      'K'
        dw      EL      ;erase line
        db      'Y'
        dw      CUP     ;cursor position
        db      'j'
        dw      PSCP    ;save   cursor position
        db      'k'
        dw      PRCP    ;restore cursor position
        db      'y'
        dw      RM      ;restore mode
        db      'x'
        dw      SM      ;set mode
        db      00


;       Device entry point

CmdLen  =       0       ;Lenght of this command
Unit    =       1       ;Sub unit specifier
Cmd     =       2       ;Command code
Status  =       3       ;Status
Media   =       13      ;Media descriptor
Trans   =       14      ;Transfer address
Count   =       18      ;Count of blocks or characters
Start   =       20      ;First  block to transfer

PtrSav  dd      0

Stratp  proc    far

Strategy:
        mov     word ptr cs:[PtrSav],bx
        mov     word ptr cs:[PtrSav+2],es
        ret

Stratp  endp

Entry:
        push    si
        push    ax
        push    cx
        push    dx


;                                                               page 2 - 45

        push    di
        push    bp
        push    ds
        push    es
        push    bx

        lds     bx,cs:[PtrSav]                  ;Get pointer to I/O packet

        mov     cx,word ptr ds:[bx].Count       ;cx = Count

        mov     al,byte ptr ds:[bx].Cmd
        cbw
        mov     si,offset ConTbl
        add     si,ax
        add     si,ax
        cmp     al,11
        ja      CmdErr

        les     di,dword ptr ds:[bx].Trans

        push    cs
        pop     ds

        assume  ds:Code

        jmp     word ptr [si]                   ;Go do command

;       Subroutines shared by multiple devices

;       Exit - all routines return through this path

Bus$Exit:                               ; Device busy exit
        mov     ah,00000011b
        jmp     short Err1

CmdErr:                                 ;unknown command error
        mov     al,3

Err$Exit:                               ;Mark error return
        mov     ah,10000001b
        jmp     short Err1

Exitp   proc far

Exit:
        mov     ah,00000001b
Err1:
        lds     bx,cs:[PtrSav]
        mov     word ptr [bx].Status,ax ; Mark
                                        ; operation complete

;                                                               page 2-46
                pop     bx
                pop     es
                pop     ds
                pop     bp
                pop     di
                pop     dx
                pop     cx
                pop     ax
                pop     si
                ret
exitp   endp

;       break key handling

break:
                mov     cs:altah,3
intret:
                iret

;
;  Warning ! Variables are very order dependent, so be careful when
;            adding new ones

wrap    db      0
state   dw      s1
mode    db      3
maxcol  db      79
col     db      0
row     db      0
savcr   dw      0
altah   db      0               ; Special key handling

;---------------------------------------------------------------------------
;
;  chrout - write out char in al using current attribute
attrw   label   word
attr    db      00000111b       ; char attribute
bpage   db      0               ; base page
base    dw      0B800h

chrout:
                cmp     al,13
                jnz     trylf
                mov     col,0
                jmp     short setit

trylf:
                cmp     al,10
                jz      lf
                cmp     al,7
                jne     tryback

torom:
                mov     bx,attrw
                and     bl,7
                mov     ah,14


;                                                               page 2-47

                int     10h
ret5:
                ret

tryback:
                cmp     al,8
                jne     outchr
                cmp     col,0
                je      ret5
                dec     col
                jmp     short setit

outchr:
                mov     bx,attrw
                mov     cx,1
                mov     ah,9
                int     10h
                inc     col
                mov     al,col
                cmp     al,maxcol
                jbe     setit
                cmp     wrap,0
                je      outchr1
                dec     col
                ret
outchr1:
                mov     col,0
lf:
                inc     row
                cmp     row,24
                jb      setit
                mov     row,23
                call    scroll
setit:
                mov     dh,row
                mov     dl,col
                xor     bh,bh
                mov     ah,2
                int     10h
                ret

scroll:
                call    getmod
                cmp     al,2
                je      myscroll
                cmp     al,3
                je      myscroll
                mov     al,10
                jmp     torom
myscroll:
                mov     bh,attr
                mov     bl,' '
                mov     bp,80
                mov     ax,base
                mov     es,ax
                mov     ds,ax
                xor     di,di
                mov     si,160


;                                                               page 2 - 48

                mov     cx,23*80
                cld
                cmp     ax,0B800h
                jz      colorcard

                rep     movsw
                mov     ax,bx
                mov     cx,bp
                rep     stosw
sret:           push    cs
                pop     ds
                ret

colorcard:
                mov     dx,3dah
wait2:          in      al,dx
                test    al,8
                jz      wait2
                mov     al,25h
                mov     dx,3d8h
                out     dx,al           ;turn off video
                rep     movsw
                mov     ax,bx
                mov     cx,bp
                rep     stosw
                mov     al,29h
                mov     dx,3d8h
                out     dx,al           ;turn on video
                jmp     sret

getmod:         mov     ah,15
                int     16
                mov     bpage,bh
                dec     ah
                mov     word ptr mode,ax
                ret
;------------------------------------------
;       Console Read Routine
con$read:
                jcxz    con$exit
con$loop:
                push    cx                    ;Save Count
                call    chrin                 ;Get Char in Al
                pop     cx
                stosb                         ;Store Char at ES:DI
                loop    con$loop
con$exit:
                jmp     exit

;------------------------------------------
;       Input Single Char Into Al
chrin:          xor     ax,ax


;                                                               page 2 - 49

                xchg    al,altah                ;get character & zero altah
                or      al,al
                jnz     keyret

inagn:          xor     ah,ah
                int     22
alt10:
                or      ax,ax                   ;check for non-key after BREAK
                jz      inagn
                or      al,al                   ;Special Case?
                jnz     keyret
                mov     altah,ah                ;Store Special key
keyret:         ret
;------------------------------------
;       Keyboard Non Destructive Read, No Wait
;
con$rdnd:
                mov     al,altah
                or      al,al
                jnz     rdexit

rd1:            mov     ah,1
                int     22
                jz      conbus
                or      ax,ax
                jnz     rdexit
                mov     ah,0
                int     22
                jmp     con$rdnd

rdexit:         lds     bx,[ptrsav]
                mov     [bx].media,al
exvec:          jmp     exit
conbus:         jmp     bus$exit
;-----------------------------------------
;       Keyboard Flush Routine
con$flsh:
                mov     altah,0                 ;Clear Out Holding buffer

                push    ds
                xor     bp,bp
                mov     ds,bp                           ;Select Segment 0
                mov     ds:byte ptr 41ah,1eh            ;Reset KB queue head
                                                        ;pointer
                mov     ds:byte ptr 41ch,1eh            ;Reset tail pointer
                pop     ds
                jmp     exvec
;------------------------------------------
;       Console Write Routine
con$writ:

;                                                               page 2 - 50

        jcxz    exvec
        push    cx
        mov     ah,3                    ;set current cursor position
        xor     bx,bx
        int     10h
        mov     word ptr col,dx
        pop     cx

  con$lp:
        mov     al,es:[di]              ;get char
        inc     di
        call    outc                    ;output char
        loop    con$lp                  ;repeat until all through
        jmp     exvec

  cout:
        sti
        push    ds
        push    cs
        pop     ds
        call    outc
        pop     ds
        iret

  outc:
        push    ax
        push    cx
        push    dx
        push    si
        push    di
        push    es
        push    bp
        call    video
        pop     bp
        pop     es
        pop     di
        pop     si
        pop     dx
        pop     cx
        pop     ax
        ret

;---------------------------------------------------------------------------
;
;       output single char in al to video device

  video:
        mov     si,offset state
        jmp     [si]

  s1:
        cmp     al,escape               ;escape sequence?
        jnz     s1b
        mov     word ptr [si],offset s2
        ret

  s1b:
        call    chrout
  s1a:
        mov     state,offset s1
        ret


;                                                               page 2 - 51

  s2:
        push    ax
        call    getmod
        pop     ax
        mov     bx, offset cmdtabl-3
  s7a:
        add     bx,3
        cmp     byte ptr [bx],0
        jz      s1a
        cmp     byte ptr [bx],al
        jnz     s7a
        jmp     word ptr [bx+1]

  movcur:
        cmp     byte ptr [bx],ah
        jz      setcur
        add     byte ptr [bx],al
  setcur:
        mov     dx,word ptr col
        xor     bx,bx
        mov     ah,2
        int     10h
        jmp     s1a

  cup:
        mov     word ptr [si], offset cup1
        ret
  cup1:
        sub     al,32
        mov     row,al
        mov     word ptr [si], offset cup2
        ret
  cup2:
        sub     al,32
        mov     col,al
        jmp     setcur

  sm:
        mov     word ptr [si],offset  s1a
        ret

  cuh:
        mov     word ptr col, 0
        jmp     setcur

  cuf:
        mov     ah,maxcol
        mov     al,1
  cuf1:
        mov     bx,offset col
        jmp     movcur

  cub:
        mov     ax,00FFh
        jmp     cuf1

  cuu:
        mov     ax,00FFh
  cuu1:
        mov     bx,offset row
        jmp     movcur

  cud:
        mov     ax,23*256+1
        jmp     cuu1

; page 2 - 52

pscp:
                mov     ax,word ptr col
                mov     savcr,ax
                jmp     SetCur
prcp:
                mov     ax,savcr
                mov     word ptr col,ax
                jmp     SetCur
ed:
                cmp     byte ptr row,24
                jae     el1
                mov     cx,word ptr col
                mov     dh,24
                jmp     erase
el1:
                mov     byte ptr col,0
el:
                mov     cx,word ptr col
el2:
                mov     dh,ch
erase:
                mov     dl,maxcol
                mov     bh,attr
                mov     ax,0600h
                int     10h
ed3:
                jmp     setcur

rm:
                mov     word ptr [si],offset rm1
                ret
rm1:
                xor     cx,cx
                mov     ch,24
                jmp     el1
con$init:
                int     11h
                and     al,00110000b
                cmp     al,00110000b
                jnz     iscolor
                mov     base,0B000h     ; look for bw card
iscolor:
                cmp     al,00010000b
                ja      setbrk
                mov     mode,0
                mov     maxcol,39
setbrk:
                xor     bx,bx
                mov     ds,bx
                mov     bx,brkaddr
                mov     word ptr [bx],offset break
                mov     word ptr [bx+2],cs

                mov     bx,29h*4
                mov     word ptr [bx],offset cout
                mov     word ptr [bx+2],cs


;                                                               page 2 - 53

                lds     bx,cs:ptrsav
                mov     word ptr [bx].trans, offset con$init
                mov     word ptr [bx].trans+2,cs
                jmp     exit

code    ends
end
                