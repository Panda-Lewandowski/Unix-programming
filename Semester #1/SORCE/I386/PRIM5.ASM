;/*
; Пример 5
; Программа проверки ошибки по отсутствующему сегменту

.386p

include struct.ash
include macros.ash

INTNO           equ     21      ; число векторов в таблице IDT
DSCPSIZE        equ     8       ; размер дескриптора
INTSIZE         equ     4       ; размер задачи монитора прерываний

TWO             equ     2
WORDLEN         equ     4       ; число символов в строке чисел
prot_enable     equ     01h     ; бит включения защищенного режима
attribute       equ     07h     ; атрибут символов на экране
space           equ     20h     ; код символа пробела

;
; Шаг 1: глобальная таблица дескрипторов сегментов системы
;
GDT             segment para    public  use16   'GDT'

gdt_tab label   qword   ; дескриптора *!! требуют инициализации адреса

; NULL селектор GDT, должен быть всегда и первым в таблице
null_selec      equ     0
   dscp         <0,0,0,0,0,0>

; селектор к сегменту GDT как к сегменту данных
gdt_selec      equ     $-gdt_tab or TBL_GDT or RPL_0
   dscp         <gdt_limit,0,0,DATA_ACC or DPL_0,0,0>           ;*!!

; сегмент системных кодов загрузки программы, всегда RPL=DPL=0
code_selec      equ     $-gdt_tab or TBL_GDT or RPL_0
   dscp         <code_limit,0,0,CODE_ACC or DPL_0,0,0>          ;*!!

; сегмент TSS задачи загрузки, RPL,DPL с которого можно запросить
task0_TSS_selec equ     $-gdt_tab or TBL_GDT or RPL_0
   dscp         <task0_TSS_limit,0,0,TSS_ACC or DPL_0,0,0>      ;*!!

; сегмент стека задачи уровня 0, RPL=DPL=0 всегда
stk0_selec      equ     $-gdt_tab or TBL_GDT or RPL_0
   dscp         <stk0_limit,0,0,DATA_ACC or DPL_0,0,0>          ;*!!

; сегмент стека задачи уровня 1, RPL=DPL=1 всегда
stk1_selec      equ     $-gdt_tab or TBL_GDT or RPL_1
   dscp         <stk1_limit,0,0,DATA_ACC or DPL_1,0,0>          ;*!!

; сегмент стека задачи уровня 2, RPL=DPL=2 всегда
stk2_selec      equ     $-gdt_tab or TBL_GDT or RPL_2
   dscp         <stk2_limit,0,0,DATA_ACC or DPL_2,0,0>          ;*!!

; сегмент стека задачи уровня 3, RPL=DPL=3 всегда
stk3_selec      equ     $-gdt_tab or TBL_GDT or RPL_3
   dscp         <stk3_limit,0,0,DATA_ACC or DPL_3,0,0>          ;*!!

; сегмент видеопамяти цветного режима, RPL=0, DPL=3
video_selec     equ     $-gdt_tab or TBL_GDT or RPL_0
   dscp         <CRT_SIZE-1,CRT_LOW,CRT_SEG,DATA_ACC or DPL_3,0,0>

; сегмент данных задачи загрузки, RPL,DPL разрешенного доступа
gdata_selec     equ     $-gdt_tab or TBL_GDT or RPL_0
   dscp         <gdata_limit,0,0,DATA_ACC or DPL_3,0,0>         ;*!!

; сегмент кодов программ обработки прерываний, RPL,DPL времени выполнения
int_selec       equ     $-gdt_tab or TBL_GDT or RPL_0
   dscp         <code_limit,0,0,CODE_ACC or DPL_0,0,0>          ;*!!

; селектор и дескриптор данных в формате реальной моды процессора
dmy_selec       equ     $-gdt_tab or TBL_GDT or RPL_0
   dscp         <0ffffh,0,0,DATA_ACC or DPL_0,0,0>              ;*!!

; селектор и дескриптор кодов в формате реальной моды процессора
rc_selec        equ     $-gdt_tab or TBL_GDT or RPL_0
   dscp         <0ffffh,0,0,CODE_ACC or DPL_0,0,0>              ;*!!

; сегмент области коммуникации BIOS, RPL,DPL по усмотрению автора
bios_selec      equ     $-gdt_tab or TBL_GDT or RPL_0
   dscp         <B_DATA_SIZE-1,B_DATA_ADDR,0,DATA_ACC or DPL_0,0,0>
;
; Шаг 1.1: дескриптор с отсутствующим сегментом
;
notp_selec      equ     $-gdt_tab
; нет признака присутствия сегмента
   dscp         <0ffffh,0,0,ACC_DSEG or DPL_3,0,0>              ;*!!

GDT_size        equ     $-gdt_tab       ; длина таблицы
GDT_limit       equ     GDT_size-1
GDT             ends

;
; Шаг 2: таблица дескрипторов прерываний системы
;
IDT             segment para    public  use16   'IDT'

idt_tab         equ     $
        REPT    INTNO
; дескр. вентиля прерывания, DPL определяет привелегии доступа к вектору,
; привелегии обработки прерывания заданы как DPL в дескрипторе кодов
          dscp  <0,int_selec,0,INT_ACC or DPL_3,0,0>
        ENDM
IDT_size        equ     $-idt_tab
IDT_limit       equ     IDT_size-1
IDT             ends

;
; Сегмент данных системы
;
Gdata           segment para    public  use16   'Gdata'

;
; Шаг 3: описатели дескрипторных таблиц для загрузки регистров
;
pGDT    label   fword
        dw      GDT_limit               ; размер GDT
        dd      0                       ; физ. базовый адрес GDT
pIDT    label   fword
        dw      IDT_limit               ; размер IDT защищ. режима
        dd      0                       ; физ. базовый адрес IDT
pold    label   fword
        dw      03ffh                   ; размер IDT реальной моды
        dd      0                       ; физ. базовый адрес IDT

;
; Шаг 4: таблица преобразователей дескрипторов сегментов GDT
;
gdt_phys_tab    label   word
        dw      task0_TSS_selec,task0_TSS       ; селектор,сегментный адрес
        dw      stk0_selec,stk0
        dw      stk1_selec,stk1
        dw      stk2_selec,stk2
        dw      stk3_selec,stk3
        dw      code_selec,code
        dw      gdata_selec,Gdata
        dw      int_selec,code
        dw      dmy_selec,dmy
        dw      rc_selec,code
        dw      gdt_selec,gdt
gdt_tab_count   equ     ($-gdt_phys_tab)/4

;
; Шаг 5: системные сообщения
;
msg_addr        dw      10               ; строка начала вывода на экран
in_protected    db      'in protected mode',0
int_msg         db      'interrupt '
int_num         db      '????','H',0
;
; Память для хранения регистров SS,SP,ES.
; Они сохраняются здесь перед входом в защищенный режим.
real_ss         dw      ?
real_sp         dw      ?
real_es         dw      ?
int_mask        db      ?       ; для спасения маски прерываний

Gdata_size      equ     $
Gdata_limit     equ     Gdata_size-1
Gdata           ends

;
; Шаг 6: стековые сегменты для всех уровней привелегий
;
stk0            segment para    public  use16   'stk0'
        db      100h    dup(0)
stk0_size       equ     $
stk0_limit      equ     stk0_size-1
stk0            ends

stk1            segment para    public  use16   'stk1'
        db      100h    dup(0)
stk1_size       equ     $
stk1_limit      equ     stk1_size-1
stk1            ends

stk2            segment para    public  use16   'stk2'
        db      100h    dup(0)
stk2_size       equ     $
stk2_limit      equ     stk2_size-1
stk2            ends

stk3            segment para    public  use16   'stk3'
        db      100h    dup(0)
stk3_size       equ     $
stk3_limit      equ     stk3_size-1
stk3            ends

DOS_stack       segment para    stack   'stack'
        db      100h    dup(?)
stk_DOS_size    equ     $
stk_DOS_limit   equ     stk_DOS_size-1
DOS_stack       ends
;
; Шаг 7: сегмент состояния задачи TSS
;
task0_TSS       segment para    public  use16   'task0'
TSS_stack       stk0_selec,stk0_size,stk1_selec,stk1_size,stk2_selec,stk2_size
TSS_cr3         0
TSS_regs        0,0,0,0,0,0,0,0,0,stk0_size
TSS_seg         gdata_selec,code_selec,stk0_selec,gdata_selec,gdata_selec,gdata_selec
                dd      0       ; LDT
                dw      0       ; T бит TSS всегда 0 при инициализации
                dw      068h    ; I/O table start
task0_TSS_size  equ     $
task0_TSS_limit equ     task0_TSS_size-1
task0_TSS       ends

;
; Шаг 8: сегмент данных в формате реальной моды для возврата в DOS
;
dmy             segment para    public  use16   'dmy'
        db      128     dup(0)
dmy_size        equ     $
dmy_limit       equ     0ffffh
dmy             ends

;
; Сегмент кодов системы
;
code            segment para    public  use16   'code'
        assume  cs:code, ds:gdata

main    proc    far
        cli
        mov     ax,gdata
        mov     ds,ax

        mov     ax,stk0
        mov     ss,ax
        mov     sp,offset stk0_size
        sti
;
; Шаг 9: инициализация IDT
;
        mov     ax,IDT
        mov     es,ax
        mov     di,offset idt_tab       ; DI=таблица прерываний IDT
        mov     ax,offset int_entry     ; AX=адрес прогр. обраб. прерываний
                                        ; как смещение от int_selec
        mov     cx,INTNO
fillidt:
        mov     es:[di],ax              ; точку входа в дескриптор вызова
        add     di,DSCPSIZE             ; след. дескриптор в IDT
        add     ax,INTSIZE              ; точка входа для след. прерывания
        loop    fillidt                 ; для всех прерываний в IDT

;
; Шаг 10: строим описатель GDT
;
        build_gdtr      gdt,pgdt,gdt_limit

;
; Шаг 11: строим описатель IDT
;
        build_idtr      idt,pidt,idt_limit

;
; Шаг 12: строим глобальную таблицу дескрипторов системы GDT
;
        build_dt        gdt,gdt_phys_tab,gdt_tab_count

;
; Шаг 13: переходим в защищенный режим на 0 уровне привелегий
;
        goto_prot       pgdt,pidt,code_selec,stk0_selec,stk0_size,Gdata_selec

;
; Шаг 14: вывод сообщения о переходе в защищенный режим
;
        call    clr_disp                ; очистим экран

        mov     ax,[msg_addr]           ; номер строки на экране
        inc     [msg_addr]              ; след. строка на 1 больше
        mov     cl,160                  ; длина строки в байтах
        mul     cl                      ; AX = адрес сообщения на экране
        mov     si,offset in_protected  ; адрес строки (источник)
        mov     di,ax                   ; адрес экрана (приемник)
        call    disp_it                 ; вывести строку на экран

;
; Шаг 15: загрузка в TR TSS
;
        mov     ax,task0_TSS_selec
        ltr     ax

;
; Шаг 15.1: генерация ошибки отказа страницы
;
        mov     ax,notp_selec           ; селектор с отсутств. страницей
        mov     es,ax                   ; должны попасть в исключение (11)

;
; Шаг 16: возврат обратно в DOS через прерывание
;
        int     20

;
; Шаг 17: массив точек входа по обработке прерываний
;
int_entry:
      REPT    INTNO
        call  disp                      ; процедура обработки прерывания
        iret
      ENDM

;
; Шаг 18: монитор стандартной обработки прерываний
;         вычисляет номер вектора, выводит его на экран
;         и возвращается в DOS
;
disp:
        xor     eax,eax                 ; очистим число для преобразования
        pop     ax                      ; адрес возврата из стека
        sub     ax,offset int_entry
        shr     ax,TWO                  ; ax= номер вектора
        xor     esi,esi                 ; очистим адрес строки
        mov     si,offset int_num       ; адрес строки номера вектора
        mov     cx,WORDLEN              ; число символов в строке
        call    htoa                    ; HEX->ASCII (esi,cx,eax)

        mov     ax,[msg_addr]           ; номер строки на экране
        inc     [msg_addr]              ; след. строка на 1 больше
        mov     cl,160                  ; длина строки в байтах
        mul     cl                      ; AX = адрес сообщения на экране
        mov     si,offset int_msg       ; адрес строки (источник)
        mov     di,ax                   ; адрес экрана (приемник)
        call    disp_it                 ; вывести строку на экран

;
; Шаг 19: возврат в реальный режим процессора
;
        goto_real dmy_selec,code,stk0,stk0_size,Gdata

;
; Шаг 20: возврат в DOS
;
        mov     ax,4c00h                ; Exit Process
        int     21h

main    endp

;
; Процедура вывода строки на дисплей в защищенном режиме
; Вход:
;       DS:SI - адрес строки символов ASCIZ
;          DI - смещение в видеопамяти
; Выход:
;       DS:SI - следующий за строкой байт
;          DI - адрес следующего байта экрана
;
disp_it         proc    near
        push    ax
        push    es

        mov     ax,video_selec          ; селектор видеопамяти
        mov     es,ax
        mov     ah,attribute            ; атрибут символов
        inc     di                      ; округлим до границы слова
        and     di,NOT 1
disp_loop:
        lodsb                           ; символ из строки
        cmp     al,0                    ; конец строки ?
        jz      end_disp                ; z, да, возврат
        stosw                           ; символ в видеопамять
        jmp     disp_loop               ; повторить до конца строки
end_disp:
        pop     es
        pop     ax
        ret
disp_it         endp

;
; Процедура очистки дисплея в защищенном режиме
; Вход:
; Выход:
;
clr_disp        proc    near
        push    ax
        push    cx
        push    di
        push    es

        mov     ax,video_selec          ; селектор видеопамяти
        mov     es,ax
        mov     cx,CRT_SIZE             ; размер видеопамяти
        shr     cx,TWO                  ; в словах
        xor     di,di
        mov     ah,attribute
        mov     al,space
        rep     stosw                   ; очистим экран

        pop     es
        pop     di
        pop     cx
        pop     ax
        ret
clr_disp        endp

;
; Процедура преобразования HEX->ASCII
; Вход:
;       DS:ESI - адрес строки символов, CX - ее длина,
;       EAX    - число для преобразования
; Выход:
;       DS:ESI - адрес следующего за строкой символа
;
htoa_tab        db      '0123456789ABCDEF'
htoa            proc    near
        push    esi
        push    eax
        push    ebx
        push    ecx

        xor     ebx,ebx
        add     si,cx
        dec     si                      ; встанем на конец строки
htoa_loop:
        mov     bl,al
        and     bl,0fh
        mov     bl,cs:[ebx+htoa_tab]    ; ASCII код символа
        mov     byte ptr [esi],bl       ; его в строку символов
        dec     esi                     ; продвинемся в строке символов
        shr     eax,4                   ; продвинемся в числе на тетраду
        loop    htoa_loop

        pop     ecx
        pop     ebx
        pop     eax
        pop     esi
        add     si,cx                   ; встанем за строкой
        ret
htoa            endp

code_size       equ     $
code_limit      equ     code_size-1
code            ends
        end     main

