;/*
; Пример 15
; Пример использования встроенного процессорного отладчика для
;  отладки доступа к данным программы, программа содержит ошибку

.386p

include struct.ash
include macros.ash

INTNO           equ     256     ; число векторов в таблице IDT
DSCPSIZE        equ     8       ; размер дескриптора
INTSIZE         equ     4       ; размер задачи монитора прерываний

TWO             equ     2
WORDLEN         equ     4       ; число символов в строке чисел
DOUBLELEN       equ     8       ; число символов в строке чисел DWORD
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
gdt_selec      equ     $-gdt_tab or TBL_GDT or RPL_0            ;*!!
   d_data       <gdt_limit>,0,<DATA_ACC or DPL_0>,<ACC2_B_SMALL or ACC2_G_BYTE>

; сегмент системных кодов загрузки программы, всегда RPL=DPL=0
code_selec      equ     $-gdt_tab or TBL_GDT or RPL_0           ;*!!
   d_code       <code_limit>,0,<CODE_ACC or DPL_0>,<ACC2_B_SMALL or ACC2_G_BYTE>

; сегмент TSS задачи загрузки, RPL,DPL с которого можно запросить
task0_TSS_selec equ     $-gdt_tab or TBL_GDT or RPL_0           ;*!!
   d_tss        <task0_TSS_limit>,0,<TSS_ACC or DPL_0>,<ACC2_G_BYTE>

; сегмент стека задачи уровня 0, RPL=DPL=0 всегда
stk0_selec      equ     $-gdt_tab or TBL_GDT or RPL_0           ;*!!
   d_data       <stk0_limit>,0,<DATA_ACC or DPL_0>,<ACC2_B_SMALL or ACC2_G_BYTE>

; сегмент стека задачи уровня 1, RPL=DPL=1 всегда
stk1_selec      equ     $-gdt_tab or TBL_GDT or RPL_1           ;*!!
   d_data       <stk1_limit>,0,<DATA_ACC or DPL_1>,<ACC2_B_SMALL or ACC2_G_BYTE>

; сегмент стека задачи уровня 2, RPL=DPL=2 всегда
stk2_selec      equ     $-gdt_tab or TBL_GDT or RPL_2           ;*!!
   d_data       <stk2_limit>,0,<DATA_ACC or DPL_2>,<ACC2_B_SMALL or ACC2_G_BYTE>

; сегмент стека задачи уровня 3, RPL=DPL=3 всегда
stk3_selec      equ     $-gdt_tab or TBL_GDT or RPL_3           ;*!!
   d_data       <stk3_limit>,0,<DATA_ACC or DPL_3>,<ACC2_B_SMALL or ACC2_G_BYTE>

; сегмент видеопамяти цветного режима, RPL=0, DPL=3
video_selec     equ     $-gdt_tab or TBL_GDT or RPL_0
   d_data       <CRT_SIZE-1>,<CRT_ADDR>,<DATA_ACC or DPL_3>,<ACC2_B_SMALL or ACC2_G_BYTE>

; сегмент данных задачи загрузки, RPL,DPL разрешенного доступа
gdata_selec     equ     $-gdt_tab or TBL_GDT or RPL_0           ;*!!
   d_data       <gdata_limit>,0,<DATA_ACC or DPL_3>,<ACC2_B_SMALL or ACC2_G_BYTE>

; сегмент кодов программ обработки прерываний, RPL,DPL времени выполнения
int_selec       equ     $-gdt_tab or TBL_GDT or RPL_0           ;*!!
   d_code       <code_limit>,0,<CODE_ACC or DPL_0>,<ACC2_B_SMALL or ACC2_G_BYTE>

; селектор и дескриптор данных в формате реальной моды процессора
dmy_selec       equ     $-gdt_tab or TBL_GDT or RPL_0           ;*!!
   d_data       <0ffffh>,0,<DATA_ACC or DPL_0>,<ACC2_B_SMALL or ACC2_G_BYTE>

; селектор и дескриптор кодов в формате реальной моды процессора
rc_selec        equ     $-gdt_tab or TBL_GDT or RPL_0           ;*!!
   d_code       <0ffffh>,0,<CODE_ACC or DPL_0>,<ACC2_B_SMALL or ACC2_G_BYTE>

; сегмент области коммуникации BIOS, RPL,DPL по усмотрению автора
bios_selec      equ     $-gdt_tab or TBL_GDT or RPL_0
   d_data       <B_DATA_SIZE-1>,<B_DATA_ADDR>,<DATA_ACC or DPL_0>,<ACC2_B_SMALL or ACC2_G_BYTE>

;
; Шаг 1.1: дескриптора сегментов вортуального v86
;
; сегмент данных области векторов IDT                           ;*!!
idt_selec       equ     $-gdt_tab or TBL_GDT or RPL_0
   d_data       0,0,<DATA_ACC or DPL_0>,<ACC2_B_SMALL or ACC2_G_BYTE>

; сегмент данных v86 от области векторов до 1Мбайта
dos_selec       equ     $-gdt_tab or TBL_GDT or RPL_0
   d_data       <0fffffh>,0,<DATA_ACC or DPL_0>,<ACC2_B_SMALL or ACC2_G_BYTE>

; сегмент TSS задачи v86, RPL = DPL = 3         (above 1M)
task1_TSS_selec equ     $-gdt_tab or TBL_GDT or RPL_3           ;*!!
   d_tss        <task1_TSS_limit>,0,<TSS_ACC or DPL_3>,<ACC2_G_BYTE>
;;;   d_tss        <task1_TSS_limit>,00080000h,<TSS_ACC or DPL_3>,<ACC2_G_BYTE>

; сегмент data on TSS задачи v86, DPL = 3
task1_OTSS_selec equ    $-gdt_tab or TBL_GDT or RPL_0           ;*!!
   d_data       <task1_TSS_limit>,0,<DATA_ACC or DPL_3>,<ACC2_B_SMALL or ACC2_G_BYTE>

; DPL = 3
task1_seg_selec equ     $-gdt_tab or TBL_GDT or RPL_0           ;*!!
   d_data       <0ffffh>,0,<DATA_ACC or DPL_3>,<ACC2_B_SMALL or ACC2_G_BYTE>

; сегмент стека монитора v86 уровня 0, RPL=DPL=0 всегда
stack0_selec    equ     $-gdt_tab or TBL_GDT or RPL_0           ;*!!
   d_data       <stack0_limit>,0,<DATA_ACC or DPL_0>,<ACC2_B_SMALL or ACC2_G_BYTE>

; сегмент стека задачи v86 уровня 0, RPL=DPL=0 всегда
stack3_selec    equ     $-gdt_tab or TBL_GDT or RPL_0           ;*!!
   d_data       <stack3_limit>,0,<DATA_ACC or DPL_0>,<ACC2_B_SMALL or ACC2_G_BYTE>

; сегмент данных задачи v86, RPL,DPL разрешенного доступа
; использ. для доступа к кодам v86 для анализа инструкций
; и для доступа к стеку задачи v86
gdata1_selec    equ     $-gdt_tab or TBL_GDT or RPL_0
gdata1  label   byte
   d_data       <0ffffh>,0,<DATA_ACC or DPL_3>,<ACC2_B_SMALL or ACC2_G_BYTE>

; сегмент данных задачи for base linear address 00180000h
gdata3_selec    equ     $-gdt_tab or TBL_GDT or RPL_0
   d_data       <0fffffh>,00180000h,<DATA_ACC or DPL_3>,<ACC2_B_SMALL or ACC2_G_BYTE>

; сегмент данных задачи for base linear address 00190000h
gdata4_selec    equ     $-gdt_tab or TBL_GDT or RPL_0
   d_data       <0fffffh>,00190000h,<DATA_ACC or DPL_3>,<ACC2_B_SMALL or ACC2_G_BYTE>

; сегмент данных задачи for base linear address 00000000h
gdata5_selec    equ     $-gdt_tab or TBL_GDT or RPL_0           ;*!!
   d_data       <0fffffh>,00000000h,<DATA_ACC or DPL_3>,<ACC2_B_SMALL or ACC2_G_BYTE>

; сегмент данных задачи for base linear address 00100000h
gdata6_selec    equ     $-gdt_tab or TBL_GDT or RPL_0           ;*!!
   d_data       <0fffffh>,00100000h,<DATA_ACC or DPL_3>,<ACC2_B_SMALL or ACC2_G_BYTE>

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
; При наличии v86 привелегии доступа к дескрипторам прерываний должны
; быть нулевыми (DPL=0) для перехвата прерываний режима v86 по общей защите
          d_int 0,<int_selec>,<INT_ACC or DPL_0>
        ENDM
IDT_size        equ     $-idt_tab
IDT_limit       equ     IDT_size-1
IDT             ends

;
; Сегмент данных системы
;
Gdata           segment para    public  use16   'Gdata'
gdata_beg       equ     $
;
; Шаг 3: описатели дескрипторных таблиц для загрузки регистров
;
pGDT    label   fword
        dw      GDT_limit               ; размер GDT
        dd      0                       ; лин. базовый адрес GDT
pIDT    label   fword
        dw      IDT_limit               ; размер IDT защищ. режима
        dd      0                       ; лин. базовый адрес IDT
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
;
; Шаг 4.1: для дополнительных дескрипторов
;
        dw      idt_selec,idt
        dw      stack0_selec,stack0
        dw      stack3_selec,stack3
        dw      task1_TSS_selec,task1_TSS
        dw      task1_OTSS_selec,task1_TSS
        dw      task1_seg_selec,task1_seg

gdt_tab_count   equ     ($-gdt_phys_tab)/4

;
; Шаг 5: системные сообщения
;
msg_addr        dw      05               ; строка начала вывода на экран
in_protected    db      'in protected mode',0
int_msg         db      'interrupt '
int_num         db      '????','H '
err_num         db      '????','H',0

;
; Шаг 5.1: системные сообщения v86
;
error           db      'error !',0
retmsg          db      'return to protected mode',0
stopmsg         db      'stop',0
intnum          db      ?
retaddr         dw      ?
err1            dw      0
err2            dw      0
pdbr1           dd      ?               ; cr3 для задачи 1
pdbr0           dd      ?               ; cr3 для задачи 0

;
; Память для хранения регистров SS,SP,ES.
; Они сохраняются здесь перед входом в защищенный режим.
real_ss         dw      ?
real_sp         dw      ?
real_es         dw      ?
int_mask        db      ?       ; для спасения маски прерываний

Gdata_size      equ     $-gdata_beg
Gdata_limit     equ     Gdata_size-1
Gdata           ends

;
; Шаг 6: стековые сегменты для всех уровней привелегий
;
stk0            segment para    public  use16   'stk0'
stk0_beg        equ     $
        db      100h    dup(0)
stk0_size       equ     $-stk0_beg
stk0_limit      equ     stk0_size-1
stk0            ends

stk1            segment para    public  use16   'stk1'
stk1_beg        equ     $
        db      100h    dup(0)
stk1_size       equ     $-stk1_beg
stk1_limit      equ     stk1_size-1
stk1            ends

stk2            segment para    public  use16   'stk2'
stk2_beg        equ     $
        db      100h    dup(0)
stk2_size       equ     $-stk2_beg
stk2_limit      equ     stk2_size-1
stk2            ends

stk3            segment para    public  use16   'stk3'
stk3_beg        equ     $
        db      100h    dup(0)
stk3_size       equ     $-stk3_beg
stk3_limit      equ     stk3_size-1
stk3            ends

DOS_stack       segment para    stack   'stack'
DOS_stack_beg   equ     $
        db      100h    dup(?)
stk_DOS_size    equ     $-DOS_stack_beg
stk_DOS_limit   equ     stk_DOS_size-1
DOS_stack       ends

;
; Шаг 6.1: стековые сегменты для v86
;
stack0          segment para    public  use16   'stack0'
stack0_beg      equ     $
        db      100h    dup(?)
stack0_size     equ     $-stack0_beg
stack0_limit    equ     stack0_size-1
stack0          ends

stack3          segment para    public  use16   'stack3'
stack3_beg      equ     $
        db      100h    dup(?)
stack3_size     equ     $-stack3_beg
stack3_limit    equ     stack3_size-1
stack3          ends

;
; Шаг 7: сегмент состояния задачи TSS
;
task0_TSS       segment para    public  use16   'task0'
task0_TSS_beg   equ     $
TSS_stack       stk0_selec,stk0_size,stk1_selec,stk1_size,stk2_selec,stk2_size
TSS_cr3         0
TSS_regs        0,0,0,0,0,0,0,0,0,stk0_size
TSS_seg         gdata_selec,code_selec,stk0_selec,gdata_selec,gdata_selec,gdata_selec
                dd      0       ; LDT
                dw      0       ; T бит TSS всегда 0 при инициализации
                dw      068h    ; I/O table start
                db      200h dup(0ffh) ; 4096 i/o ports bit map disable
task0_TSS_size  equ     $-task0_TSS_beg
task0_TSS_limit equ     task0_TSS_size-1
task0_TSS       ends

;
; Шаг 7.1: сегмент состояния задачи v86
; EFLAGS имеет IOPL=3, VM-set, IF-set
; v86_flags     equ     fl_vm or fl_iopl3 or fl_if or fl_set
; спасенные сегментные регистры содержат сегментные адреса (CS,SS)
task1_TSS       segment para    public  use16   'task1'
task1_TSS_beg   equ     $
TSS_stack       stack0_selec,stack0_size,stk1_selec,stk1_size,stk2_selec,stk2_size
TSS_cr3         0
TSS_regs        task1_entry,v86_flags,0,0,0,0,0,0,0,stack3_size
TSS_seg         0,9000h,stack3,0,0,0
                dd      0       ; LDT
                dw      0       ; T бит TSS всегда 0 при инициализации
                dw      068h    ; I/O table start
                db      200h dup(0)    ; 4096 байт портов i/o enable
task1_TSS_size  equ     $-task1_TSS_beg
task1_TSS_limit equ     task1_TSS_size-1
task1_TSS       ends

;
; Шаг 7.2: сегмент страниц, содержит таблицу страниц и каталогов
;          для физического адресного пространства 0..1Мбайт
;
pagetbl0        segment para    public  use16   'pagetbl0'
pagetbl0_beg    equ     $

        db      4096    dup(0)  ; для выравнивания на границу 4кб.

tmp_ptbl0       label   byte    ; таблица страниц, будет перемещаться вверх

      REPT      256     ; 256 дескрипторов на странице (1Мбайт)
        dd      (($-tmp_ptbl0)/4*1000h + pg_present+pg_write+pg_user)
      ENDM

page_tbl0_size  equ     ($-tmp_ptbl0)/4 ; число входов в таблицу страниц

;
; Размер страницы на самом деле на 1024 дескриптора страниц,
; поэтому конец страницы каталога страниц надо подсчитать
;
        org     tmp_ptbl0+pdbr_offset   ; начало каталога страниц
        dd      ?                       ; в каталоге страниц будет
                                        ; только один вход
ptbl0_addr      dw      ?               ; для вычисленного смещения таблицы
                                        ; страниц на физической границе 4к.
pagetbl0_size   equ     $-pagetbl0_beg
pagetbl0_limit  equ     pagetbl0_size-1

pagetbl0        ends

;
; Шаг 7.3: сегмент страниц, содержит таблицу страниц и каталогов
;          для физического адресного пространства 1..2Мбайт
;
pagetbl1        segment para    public  use16   'pagetbl1'
pagetbl1_beg    equ     $

        db      4096    dup(0)  ; для выравнивания на границу 4кб.

tmp_ptbl1       label   byte    ; таблица страниц, будет перемещаться вверх

      REPT      256     ; 256 дескрипторов на странице (1Мбайт)
        dd      (($-tmp_ptbl1)/4*1000h + pg_present+pg_write+pg_user + 100000h)
      ENDM

page_tbl1_size  equ     ($-tmp_ptbl1)/4 ; число входов в таблицу страниц

;
; Размер страницы на самом деле на 1024 дескриптора страниц,
; поэтому конец страницы каталога страниц надо подсчитать
;
        org     tmp_ptbl1+pdbr_offset   ; начало каталога страниц
        dd      ?                       ; в каталоге страниц будет
                                        ; только один вход
ptbl1_addr      dw      ?               ; для вычисленного смещения таблицы
                                        ; страниц на физической границе 4к.
pagetbl1_size   equ     $-pagetbl1_beg
pagetbl1_limit  equ     pagetbl1_size-1

pagetbl1        ends

;
; Шаг 8: сегмент данных в формате реальной моды для возврата в DOS
;
dmy             segment para    public  use16   'dmy'
dmy_beg         equ     $
        db      128     dup(0)
dmy_size        equ     $-dmy_beg
dmy_limit       equ     0ffffh
dmy             ends

;
; Сегмент кодов системы
;
code            segment para    public  use16   'code'
code_beg        equ     $
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
; Шаг 9.1: строим таблицу страниц
;
        call    setup_pgtbl0            ; настроим таблицу страниц 0
        call    setup_pgtbl1            ; настроим таблицу страниц 1

;
; Шаг 9.2: set PDBR 0
;
        mov     eax,pdbr0               ; адрес базы каталога страниц 0
        mov     cr3,eax                 ; ее в CR3
        mov     bx,task0_TSS
        mov     es,bx                   ; ES = task0 TSS selector
        mov     es:[T_cr3],eax          ; CR3 in task0 TSS

;
; Шаг 9.3: set PDBR 1
;
        mov     eax,pdbr1               ; адрес базы каталога страниц 1
        mov     bx,task1_TSS
        mov     es,bx                   ; ES = task1 TSS selector
        mov     es:[T_cr3],eax          ; CR3 in task1 TSS

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
        call    clr_disp                ; clear display

        mov     ax,[msg_addr]           ; номер строки на экране
        inc     [msg_addr]              ; след. строка на 1 больше
        mov     cl,160                  ; длина строки в байтах
        mul     cl                      ; AX = адрес сообщения на экране
        mov     si,offset in_protected  ; адрес сообщения (источник)
        mov     di,ax                   ; адрес зкрана    (приемник)
        call    disp_it                 ; вывести строку на экран

;
; Шаг 14.1: copy data from first megabyte to second
;
        push    ds

        cld
        mov     ax,gdata5_selec
        mov     ds,ax                   ; ds = 0..0fffffh address
        mov     ax,gdata6_selec
        mov     es,ax                   ; es = 100000h..1fffffh address
        xor     esi,esi
        xor     edi,edi
        mov     ecx,0fffffh             ; counter= 1M
        db      066h                    ; large operand
        db      067h                    ; large address
        rep     movsb                   ; copy 1-st Mbyte to 2-nd Mbyte

;
; Шаг 14.2: copy task1 TSS to linear address 180000h
;
        mov     ax,task1_OTSS_selec     ; task1 TSS selector as data in 1M
        mov     ds,ax
        mov     ax,gdata3_selec         ; selector for linear address 180000h
        mov     es,ax
        xor     si,si
        xor     di,di
        mov     cx,task1_TSS_size
        rep     movsb                   ; task 1 TSS from 1M to 180000h

;
; Шаг 14.3: copy task1 code to linear address 190000h
;
        mov     ax,task1_seg_selec      ; task1 code selector in first Mbyte
        mov     ds,ax
        mov     ax,gdata4_selec         ; linear address 190000h
        mov     es,ax
        xor     si,si
        xor     di,di
        mov     cx,task1_seg_size
        rep     movsb                   ; copy code task1

        pop     ds

;
; Шаг 15: загрузка в TR TSS
;
        mov     ax,task0_TSS_selec
        ltr     ax

;
; Шаг 15.0: enable memory paging
;
        mov     eax,cr0
        or      eax,pg_enable           ; enable paging
        mov     cr0,eax

;
; Шаг 15.1: переключение на задачу v86
;
        jmpf    task1_TSS_selec

;
; Шаг 15.2: вернемся сюда после возврата из v86
;
        mov     eax,cr0
        and     eax,not pg_enable       ; disable paging
        mov     cr0,eax
        xor     eax,eax
        mov     cr3,eax                 ; очистить кэш страниц

;;;                jmp     $

        mov     ax,[msg_addr]           ; номер строки на экране
        inc     [msg_addr]              ; след. строка на 1 больше
        mov     cl,160                  ; длина строки в байтах
        mul     cl                      ; AX = адрес сообщения на экране
        mov     si,offset retmsg        ; адрес строки (источник)
        mov     di,ax                   ; адрес экрана (приемник)
        call    disp_it

;
; Шаг 16: возврат обратно в DOS
;
        jmp     goto_real_

;
; Шаг 16.1: определим стек при входе в прерывание
;
spcheck         equ     offset (stk0_size - v86stklen - 4)
                ; по этому адресу будет код ошибки, если он был,
                ; при прерывании из режима v86

;
; Шаг 17: массив точек входа по обработке прерываний
;
int_entry:
      REPT    INTNO
        call  intchk                    ; процедура обработки прерывания
        iret
      ENDM

;
; Шаг 17.1: монитор обработки прерываний системы
;       1. устанавливает селектор системных данных
;       2. запоминает адрес возврата из монитора прерываний
;       3. запоминает код ошибки, если она была
intchk:
        push    eax
        mov     ax,gdata_selec
        mov     ds,ax                   ; встанем на системные данные
        pop     eax

        pop     [retaddr]               ; адрес инструкции iret

        mov     [err1],0ffffh
        cmp     sp,spcheck              ; глубина стека включает ошибку ?
        jne     contint                 ; neq, нет, пропустим
        pop     [err1]                  ; код ошибки из стека
        pop     [err2]                  ; туда был помещен dd, очистим стек

;
; Шаг 17.2: получим номер вектора прерывания
;
contint:
        pushad                          ; push all regs

        call    disp

        mov     ax,[retaddr]            ; адрес точки возврата
        sub     ax,offset int_entry     ; смещение точки входа в вектора
        shr     ax,TWO                  ; /4 для получения номера вектора

        cmp     ax,13                   ; прерывание общей защиты 13 ?
        je      int_13                  ; eq, да, обработаем его

;
; Шаг 17.3: не прерывание общей защиты, получим адрес возврата
;
        mov     cx,stk0_selec
        mov     es,cx                   ; ES = stk0
        mov     bx,sp
        add     bx,size pushaddef       ; пропустим pushad
        mov     esi,es:[bx].oldeip      ; адрес возврата из прерывания (DOS)
        jmp     setint                  ; ax = #прерывания

;
; Шаг 17.4: прерывание общей защиты, если это intn, то отработаем,
;           иначе конец программы
;
int_13:
        mov     ax,stk0_selec
        mov     es,ax                   ; ES = stk0
        mov     bx,sp
        add     bx,size pushaddef       ; пропустим pushad
        mov     eax,es:[bx].oldecs      ; сегмент кодов в DOS
        mov     ch,ah
        shl     ax,4
        shr     ch,4                    ; ch:ax = 24 bit линейный адрес

        assume  ds:gdt

        mov     dx,gdt_selec
        mov     ds,dx                   ; DS = gdt
        mov     [gdata1.d_base1],ax     ; линейный адрес кодов в дескриптор
        mov     [gdata1.d_base2],ch     ; данных для доступа к инструкциям
        mov     ax,gdata1_selec
        mov     ds,ax                   ; DS = сегмент кодов задачи v86
        mov     esi,es:[bx].oldeip      ; si = адрес инструкции прерывания
        cld
        lodsb                           ; al = команда, вызвавшая прерывание
        cmp     al,0cdh                 ; код команды "INT n" ?
        jne     stop                    ; neq, нет, конец программы

;
; Шаг 17.5: было прерывание v86 "INT n", узнаем номер
;
procint:
        lodsb                           ; al = # запрошенного прерывания

;
; Шаг 17.6: если запрошено прерывание INT 1 (T-bit), конец работы
;
        cmp     al,1
        je      int_1

;
; Шаг 17.7: готовим стек задачи v86 для выхода из своего прерывания,
;           поскольку операция прерывания была выполнена в режиме
;           v86, а не 8086 и в стеке 0 системы
;   SI = IP (v86) возврата из прерывания
;   AL = произошедшее или запрошенное прерывание в режиме v86
setint:
        mov     ecx,es:[bx].oldess
        mov     dh,ch
        shl     cx,4
        shr     dh,4                    ; dh:cx = 24 bit адрес стека v86
        mov     di,gdt_selec
        mov     ds,di
        mov     [gdata1.d_base1],cx
        mov     [gdata1.d_base2],dh     ; настроим рабочий дескриптор на SS
        mov     dx,gdata1_selec
        mov     ds,dx                   ; DS = v86 SS селектор
        mov     edi,es:[bx].oldesp      ; DI = v86 SP
        sub     edi,6                   ; зарезервируем место под 3 параметра
        mov     es:[bx].oldesp,edi      ; прерывания (IP,CS,FLAGS)
        mov     [di],si                 ; IP поместить в стек v86
        mov     edx,es:[bx].oldecs
        mov     [di+2],dx               ; CS поместить в стек v86
        mov     edx,es:[bx].oldeflg
        mov     [di+4],dx               ; FLAGS поместить в стек v86

;
; Шаг 17.8: готовим переход на обработку прерывания DOS
;   AL  = произошедшее или запрошенное прерывание в режиме v86
;   EDX = слово флагов v86 в момент прерывания
        and     dx,NOT (fl_if or fl_tf) ; очистим IF и TF в слове флагов v86
        mov     cx,dos_selec
        mov     ds,cx                   ; DS = селектор векторов v86
        xor     ah,ah
        shl     ax,2                    ; адрес описателя вектора
        xor     si,si
        add     si,ax                   ; SI = индекс вектора в таблице DOS
        xor     eax,eax
        mov     ax,[si]                 ; v86 vector offset
        xor     ecx,ecx
        mov     cx,[si+2]               ; v86 vector segment
        mov     es:[bx].oldecs,ecx      ; vector's CS     поместить в stk0
        mov     es:[bx].oldeip,eax      ; vector's EIP    поместить в stk0
        mov     es:[bx].oldeflg,edx     ; vector's EFLAGS поместить в stk0
        popad
        db      066h                    ; LARGE префикс
        iret                            ; перейти на обработку прерывания
                                        ; в задаче v86

;
; Шаг 17.9: останов программы, где то ошибка
;
stop:
        assume  ds:gdata

        mov     dx,gdata_selec
        mov     ds,dx                   ; DS = gdata
        mov     ax,[msg_addr]           ; номер строки на экране
        inc     [msg_addr]              ; след. строка на 1 больше
        mov     cl,160                  ; длина строки в байтах
        mul     cl                      ; AX = адрес сообщения на экране
        mov     si,offset stopmsg       ; адрес строки (источник)
        mov     di,ax                   ; адрес экрана (приемник)
        call    disp_it

;
; Шаг 17.10: возврат в защищенный режим из режима v86
;
int_1:
        popad                           ; восстановить стек

        jmpf    task0_TSS_selec         ; переключить задачу

;
; Шаг 18: монитор стандартной обработки прерываний
;         вычисляет номер вектора и выводит его на экран
;         и возвращается в DOS
;
disp    proc    near
        push    eax
        push    esi
        push    ecx

        xor     eax,eax                 ; очистим число для преобразования
        mov     ax,[err1]               ; код ошибки
        shr     ax,3                    ; ax = номер вектора DOS

        cmp     ax,029h
        jz      no_disp
        cmp     ax,010h
        jz      no_disp
        cmp     ax,028h
        jz      no_disp
        cmp     ax,016h
        jz      no_disp
        cmp     ax,02ah
        jz      no_disp
        cmp     ax,01ch
        jz      no_disp
        cmp     ax,01ah
        jz      no_disp
        cmp     ax,015h
        jz      no_disp

        xor     eax,eax                 ; очистим число для преобразования
        mov     ax,[retaddr]            ; адрес возврата
        sub     ax,offset int_entry
        shr     ax,TWO                  ; ax= номер вектора

        cmp     ax,008h                 ; DOS timer пропустим
        jz      no_disp

        xor     esi,esi                 ; очистим адрес строки
        mov     si,offset int_num       ; адрес строки номера вектора
        mov     cx,WORDLEN              ; число символов в строке
        call    htoa                    ; HEX->ASCII (esi,cx,eax)

        xor     eax,eax                 ; очистим число для преобразования
        mov     ax,[err1]               ; код ошибки
        xor     esi,esi
        mov     si,offset err_num       ; адрес строки кода ошибки
        mov     cx,WORDLEN              ; число символов в строке
        call    htoa                    ; HEX->ASCII (esi,cx,eax)

        mov     ax,[msg_addr]           ; номер строки на экране
        cmp     ax,25
        ja      no_disp
        inc     [msg_addr]              ; след. строка на 1 больше
        mov     cl,160                  ; длина строки в байтах
        mul     cl                      ; AX = адрес сообщения на экране
        mov     si,offset int_msg       ; адрес строки (источник)
        mov     di,ax                   ; адрес экрана (приемник)
        call    disp_it                 ; вывести строку на экран

no_disp:
        pop     ecx
        pop     esi
        pop     eax
        ret
disp    endp

;
; Шаг 19: возврат в реальный режим процессора
;
goto_real_:
        cli
;;        mov     eax,cr0
;;        and     eax,not pg_enable       ; disable paging
;;        mov     cr0,eax
;;        xor     eax,eax
;;        mov     cr3,eax                 ; очистить кэш страниц

        goto_real dmy_selec,code,stk0,stk0_size,Gdata

;
; Шаг 20: возврат в DOS
;
        mov     ax,4c00h                ; Exit Process
        int     21h

main    endp

;
; Процедура вывода строки на дисплей в защищенном режиме
;  DS:SI - адрес строки символов ASCIZ; DI - смещение в видеопамяти
;
disp_it         proc    near
        push    ax
        push    es
        mov     ax,video_selec          ; селектор видеопамяти
        mov     es,ax
        mov     ah,attribute            ; атрибут символов
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
;  DS:ESI - адрес строки символов, CX - ее длина,
;  EAX    - число для преобразования
htoa_tab        db      '0123456789ABCDEF'
htoa            proc    near
        push    ebx
        push    eax
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
        pop     eax
        pop     ebx
        ret
htoa            endp

;
; 1. Процедура вычисляет физический адрес таблицы страниц на границе
;    4кбайта и перемещает туда заготовленную таблицу страниц
; 2. Формирует дескриптор этой таблицы в каталоге страниц, которая
;    размещена сразу за ней
;
setup_pgtbl0    proc    near
        assume  ds:pagetbl0

        push    ds
        push    es
        push    eax

        mov     ax,pagetbl0
        mov     ds,ax
        mov     es,ax                   ; DS=ES= pagetbl sement
        mov     cx,page_tbl0_size       ; число входов в таблицу страниц

        mov     bx,ax                   ; BX= pagetbl sement
        and     bx,00ffh                ; смещение от границы в 4кбайта
        xor     edi,edi
        mov     di,0100h                ; мы зарезервировали 4096 байт
        sub     di,bx                   ; чтобы попасть на границу 4кбайта
        shl     di,4                    ; надо переместить таблицу по этому
                                        ; физическому адресу
        mov     [ptbl0_addr],di         ; запомним смещение до таблицы
        push    di                      ; страниц от начала сегмента

        mov     si,offset tmp_ptbl0     ; наша таблица находится по этому адр.

        rep     movsd                   ; переместим таблицу в мл. адреса

        pop     di                      ; di= смещение до табл. стр. от сегм.

;
; устанавливаем каталог страниц
;
        xor     ebx,ebx
        mov     bx,ax                   ; bx = seg pagetbl
        shl     ebx,4                   ; 20-бит адрес сегмента
        add     ebx,edi                 ; 20-бит адрес таблицы страниц
        or      bl,pg_present or pg_user or pg_write
                                        ; атрибуты дескриптора таблицы стр.
        mov     dword ptr [di + pdbr_offset],ebx
                                        ; каталог сразу за таблицей страниц
                                        ; туда и поместим ее адрес
        add     ebx,offset pdbr_offset  ; встанем на этот адрес базы каталога
        and     ebx,pg_addrmsk          ; оставим в дескрипторе только адрес
                                        ; это и будет адресом базы каталога
        push    ds

        assume  ds:gdata

        mov     ax,gdata
        mov     ds,ax
        mov     pdbr0,ebx               ; запомним базу каталога
        pop     ds

        assume  ds:pagetbl0

        pop     eax
        pop     es
        pop     ds
        ret
setup_pgtbl0    endp

;
; 1. Процедура вычисляет физический адрес таблицы страниц на границе
;    4кбайта и перемещает туда заготовленную таблицу страниц
; 2. Формирует дескриптор этой таблицы в каталоге страниц, которая
;    размещена сразу за ней
;
setup_pgtbl1    proc    near
        assume  ds:pagetbl1

        push    ds
        push    es
        push    eax

        mov     ax,pagetbl1
        mov     ds,ax
        mov     es,ax                   ; DS=ES= pagetbl sement
        mov     cx,page_tbl1_size       ; число входов в таблицу страниц

        mov     bx,ax                   ; BX= pagetbl sement
        and     bx,00ffh                ; смещение от границы в 4кбайта
        xor     edi,edi
        mov     di,0100h                ; мы зарезервировали 4096 байт
        sub     di,bx                   ; чтобы попасть на границу 4кбайта
        shl     di,4                    ; надо переместить таблицу по этому
                                        ; физическому адресу
        mov     [ptbl1_addr],di         ; запомним смещение до таблицы
        push    di                      ; страниц от начала сегмента

        mov     si,offset tmp_ptbl1     ; наша таблица находится по этому адр.

        rep     movsd                   ; переместим таблицу в мл. адреса

        pop     di                      ; di= смещение до табл. стр. от сегм.

;
; устанавливаем каталог страниц
;
        xor     ebx,ebx
        mov     bx,ax                   ; bx = seg pagetbl
        shl     ebx,4                   ; 20-бит адрес сегмента
        add     ebx,edi                 ; 20-бит адрес таблицы страниц
        or      bl,pg_present or pg_user or pg_write
                                        ; атрибуты дескриптора таблицы стр.
        mov     dword ptr [di + pdbr_offset],ebx
                                        ; каталог сразу за таблицей страниц
                                        ; туда и поместим ее адрес
        add     ebx,offset pdbr_offset  ; встанем на этот адрес базы каталога
        and     ebx,pg_addrmsk          ; оставим в дескрипторе только адрес
                                        ; это и будет адресом базы каталога
        push    ds

        assume  ds:gdata

        mov     ax,gdata
        mov     ds,ax
        mov     pdbr1,ebx               ; запомним базу каталога
        pop     ds

        assume  ds:pagetbl1
;
; Set Linear Video Memory Address To Physical Area b8000h..bffffh
;
        mov     bx,ptbl1_addr           ; смещение до таблицы страниц
        add     bx,0b8h shl 2           ; get entry 0b8000h
        mov     eax,0b8000h + pg_present+pg_write+pg_user
        mov     dword ptr [bx],eax      ; 0b8000h
        add     eax,001000h             ; next video page address
        add     bx,4                    ; next video page descriptor
        mov     dword ptr [bx],eax      ; 0b9000h
        add     eax,001000h             ; next video page address
        add     bx,4                    ; next video page descriptor
        mov     dword ptr [bx],eax      ; 0ba000h
        add     eax,001000h             ; next video page address
        add     bx,4                    ; next video page descriptor
        mov     dword ptr [bx],eax      ; 0bb000h
        add     eax,001000h             ; next video page address
        add     bx,4                    ; next video page descriptor
        mov     dword ptr [bx],eax      ; 0bc000h
        add     eax,001000h             ; next video page address
        add     bx,4                    ; next video page descriptor
        mov     dword ptr [bx],eax      ; 0bd000h
        add     eax,001000h             ; next video page address
        add     bx,4                    ; next video page descriptor
        mov     dword ptr [bx],eax      ; 0be000h
        add     eax,001000h             ; next video page address
        add     bx,4                    ; next video page descriptor
        mov     dword ptr [bx],eax      ; 0bf000h

        pop     eax
        pop     es
        pop     ds
        ret
setup_pgtbl1    endp

code_size       equ     $-code_beg
code_limit      equ     code_size-1
code            ends

;
; Шаг 23: кодовый сегмент задачи v86
;       Исполнение осуществляется в режиме v86
;
task1_seg       segment para    public  use16   'task1_seg'
task1_seg_beg   equ     $
        assume  cs:task1_seg, ds:gdata

task_entry      proc    near
entry:
                        jmp $
        push    cs
        pop     ds                      ; cs=ds

;;        mov     al,[int_mask]           ; маска прерываний
;;        and     al,NOT 002h             ; разрешим прерывания клавиатуре
        mov     al,NOT 002h             ; разрешим прерывания клавиатуре
        out     INT_MASK_PORT,al        ; прерываний
;
; Шаг 24: запрос к DOS (INT 21h) на вывод строки
;
        mov     dx,offset task1msg      ; адрес сообщения DOS
        mov     ah,09                   ; команда вывода строки
        int     21h                     ; прерывание к DOS

        mov     dx,offset success       ; адрес сообщения DOS
        mov     ah,09                   ; команда вывода строки
        int     21h                     ; прерывание к DOS

;
; Шаг 25: запрос к DOS (INT 21h) на ввод символа с клавиатуры
;
        mov     ah,1
        int     21h                     ; ждем ввода символа с клавиатуры

;
; Шаг 26: возврат из режима v86 в защищенный режим
;
        mov     al,0ffh                 ; запретим прерывания контроллеру
        out     INT_MASK_PORT,al        ; прерываний

        int     1
task_entry      endp

task1msg        db      'now in v86 mode task1',0dh,0ah,'$'
success         db      'press any key to return to protected mode',0dh,0ah,'$'

task1_seg_size  equ     $-task1_seg_beg
task1_seg_limit equ     task1_seg_size-1

task1_seg       ends

        end     main

