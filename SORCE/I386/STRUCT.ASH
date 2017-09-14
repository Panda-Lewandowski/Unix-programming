;/*
; биты состояния дескриптора сегмента в байте состояния
ACC_ACCESS      EQU     00000001b ; бит регистрации обращения
ACC_DATAWR      EQU     00000010b ; разрешена запись в данные
ACC_CODERD      EQU     00000010b ; разрешено чтение кодов
ACC_EXPDOWN     EQU     00000100b ; сегмент расширяется вниз (для стека)
ACC_CONFORM     EQU     00000100b ; подчиненный сегмент      (для кода)

ACC_TSS2        EQU     00000001b ; дескриптор TSS 286 свободен (01h)
ACC_LDT         EQU     00000010b ; дескриптор LDT              (02h)
ACC_TSSBSY      EQU     00000010b ; признак - TSS 286/386 занят (02h)
ACC_TSS2B       EQU     00000011b ; дескриптор TSS 286 занят    (03h)
ACC_CALL2       EQU     00000100b ; вентиль вызова 286          (04h)
ACC_TASK        EQU     00000101b ; вентиль задачи 286/386      (05h)
ACC_INT2        EQU     00000110b ; вентиль прерывания 286      (06h)
ACC_TRAP2       EQU     00000111b ; вентиль ловушки 286         (07h)
ACC_TSS3        EQU     00001001b ; дескриптор TSS 386 свободен (09h)
ACC_TSS3B       EQU     00001011b ; дескриптор TSS 386 занят    (0bh)
ACC_CALL3       EQU     00001100b ; вентиль вызова 386          (0ch)
ACC_INT3        EQU     00001110b ; вентиль прерывания 386      (0eh)
ACC_TRAP3       EQU     00001111b ; вентиль ловушки 386         (0fh)

ACC_DSEG        EQU     00010000b ; сегмент данных
ACC_CSEG        EQU     00011000b ; сегмент кода
ACC_DPLMSK      EQU     01100000b ; маска привелегий доступа (0-высший)
ACC_PRESENT     EQU     10000000b ; присутствие сегмента кода в памяти
;
; биты состояния дескриптора сегмента в расширенном байте состояния
ACC2_AVAIL      EQU     00010000b ; разрешено для использ. программ
ACC2_B_BIG      EQU     01000000b ; размер операнда по умолчанию 32bit (i386)
ACC2_B_SMALL    EQU     00000000b ; размер операнда по умолчанию 16bit (i386)
ACC2_G_PAGE     EQU     10000000b ; дробность сегмента 4кбайта         (i386)
ACC2_G_BYTE     EQU     00000000b ; дробность сегмента 1байт           (i386)
;
;  типы сегментов
;  сегмент данных
DATA_ACC = ACC_PRESENT OR ACC_DSEG OR ACC_DATAWR

; сегмент кода
CODE_ACC = ACC_PRESENT OR ACC_CSEG OR ACC_CODERD

; согласованный сегмент кода
CONF_ACC = ACC_PRESENT OR ACC_CSEG OR ACC_CODERD; OR ACC_CONFORM

; сегмент стека
STACK_ACC= ACC_PRESENT OR ACC_DSEG OR ACC_DATAWR OR ACC_EXPDOWN

; сегменты данных и стека в формате DOS
DATA_REAL= ACC_PRESENT OR ACC_DSEG OR ACC_DATAWR
CODE_REAL= ACC_PRESENT OR ACC_CSEG OR ACC_CODERD

; системные сегменты
TSS_ACC  = ACC_PRESENT OR ACC_TSS3
CALL_ACC = ACC_PRESENT OR ACC_CALL3
INT_ACC  = ACC_PRESENT OR ACC_INT3
TRAP_ACC = ACC_PRESENT OR ACC_TRAP3
TASK_ACC = ACC_PRESENT OR ACC_TASK

; Привелегии доступа к сегменту в дескрипторе сегмента (DPL)
DPL_0           equ     00000000b
DPL_1           equ     00100000b
DPL_2           equ     01000000b
DPL_3           equ     01100000b

; Привелегии доступа к сегменту в селекторе (RPL)
RPL_0           equ     00000000b
RPL_1           equ     00000001b
RPL_2           equ     00000010b
RPL_3           equ     00000011b

; Признак ссылки селектора на таблицу дескрипторов
TBL_LDT         equ     00000100b ; селектор ссылается на LDT
TBL_GDT         equ     00000000b ; селектор ссылается на GDT
TBL_ADDR        equ     0fff8h    ; индекс дескриптора в селекторе

; Общие константы адресов и размеров сегментов системы
STACK_SIZE      EQU     00400h   ; размер стека
B_DATA_SIZE     EQU     00300h   ; размер области данных BIOS
B_DATA_ADDR     EQU     00400h   ; адрес  области данных BIOS
MONO_SEG        EQU     0b000h   ; cегмент видеопамяти монохромного адаптера
COLOR_SEG       EQU     0b800h   ; сегмент видеопамяти цветного видеоадаптера
CRT_SIZE        EQU      8000h   ; размер сегмента видеопамяти
MONO_SIZE       EQU      1000h   ; размер сегмента видеопамяти
CRT_ADDR        EQU    0b8000h   ; полный адрес видеопамяти color
MONO_ADDR       EQU    0b0000h   ; полный адрес видеопамяти mono
CRT_SEG         EQU        0Bh   ; старший байт физ. адреса видеопамяти
CRT_LOW         EQU      8000h   ; младшее слово физ. адреса видеопамяти
MONO_LOW        EQU      0000h   ; младшее слово физ. адреса видеопамяти
; Значения портов и констант системы
CMOS_PORT       EQU        70h   ; Порт для доступа к CMOS-памяти
PORT_6845       EQU        63h   ; Адрес области данных BIOS, где
                                 ; хранится адрес порта контроллера
                                 ; 6845
COLOR_PORT      EQU      03d4h   ; Порт цветного видеоконтроллера
MONO_PORT       EQU      03b4h   ; Порт монохромного видеоконтроллера
STATUS_PORT     EQU       064h   ; Порт состояния клавиатуры
SHUT_DOWN       EQU       0feh   ; Команда сброса процессора
VIRTUAL_MODE    EQU      0001h   ; Бит перехода в защищенный режим
A20_PORT        EQU       0d1h   ; Команда управления линией A20
A20_ON          EQU       0dfh   ; Открыть А20
A20_OF          EQU       0ddh   ; Закрыть А20
KBD_PORT_A      EQU       060h   ; Адреса портов клавиатуры
KBD_PORT_B      EQU       061h   ;
INT_MASK_PORT   EQU       021h   ; Порт для маскирования прерываний
;
;
; Описание структуры дискриптора сегмента
dscp    struc
        D_lim1    dw    0
        D_base1   dw    0
        D_base2   db    0
        D_type    db    0
        D_lim2    db    0
        D_base3   db    0
dscp    ends

;
; Заполнение дескриптора сегмента кода
d_code  macro limit,base,type1,type2
        dw    (offset (limit)) and 00000ffffh
        dw    (base) and 00000ffffh
        db    ((base) and 000ff0000h) shr 10h
        db    (type1)
        db    (((offset (limit)) and 0000f0000h) shr 10h) or (type2)
        db    ((base) and 0ff000000h) shr 18h
endm
;
; Заполнение дескриптора сегмента данных
d_data  macro limit,base,type1,type2
        dw    (offset (limit)) and 00000ffffh
        dw    (base) and 00000ffffh
        db    ((base) and 000ff0000h) shr 10h
        db    (type1)
        db    (((offset (limit)) and 0000f0000h) shr 10h) or (type2)
        db    ((base) and 0ff000000h) shr 18h
endm
;
; Заполнение дескриптора вентиля задачи
d_task  macro selector,type
        dw    0h
        dw    (selector)
        db    0h
        db    (type)
        dw    0h
endm
;
; Заполнение дескриптора вентиля вызова
d_call  macro offs,selector,type,count
        dw    (offset (offs)) and 00000ffffh
        dw    (selector)
        db    (count) and 01fh
        db    (type)
        dw    ((offset (offs)) and 0ffff0000h) shr 10h
endm
;
; Заполнение дескриптора вентиля прерывания
d_int   macro offs,selector,type
        dw    (offset (offs)) and 00000ffffh
        dw    (selector)
        db    0h
        db    (type)
        dw    ((offset (offs)) and 0ffff0000h) shr 10h
endm
;
; Заполнение дескриптора сегмента LDT
d_ldt   macro limit,base,type1,type2
        dw    (offset (limit)) and 00000ffffh
        dw    (base) and 00000ffffh
        db    ((base) and 000ff0000h) shr 10h
        db    (type1)
        db    (((offset (limit)) and 0000f0000h) shr 10h) or (type2)
        db    ((base) and 0ff000000h) shr 18h
endm
;
; Заполнение дескриптора сегмента TSS
d_tss   macro limit,base,type1,type2
        dw    (offset (limit)) and 00000ffffh
        dw    (base) and 00000ffffh
        db    ((base) and 000ff0000h) shr 10h
        db    (type1)
        db    (((offset (limit)) and 0000f0000h) shr 10h) or (type2)
        db    ((base) and 0ff000000h) shr 18h
endm

;
; Структура сегмента TSS 386
tss386df        struc
        T_eblink  dd    0
        T_esp0    dd    0
        T_ess0    dd    0
        T_esp1    dd    0
        T_ess1    dd    0
        T_esp2    dd    0
        T_ess2    dd    0
        T_cr3     dd    0
        T_eip     dd    0
        T_eflags  dd    0
        T_eax     dd    0
        T_ecx     dd    0
        T_edx     dd    0
        T_ebx     dd    0
        T_esp     dd    0
        T_ebp     dd    0
        T_esi     dd    0
        T_edi     dd    0
        T_ees     dd    0
        T_ecs     dd    0
        T_ess     dd    0
        T_eds     dd    0
        T_efs     dd    0
        T_egs     dd    0
        T_eldt    dd    0
        T_trap    dw    0
        T_iom     dw    0
tss386df        ends

;
; Структура сегмента TSS 286
tss286df        struc
        T_blink   dw    0
        T_sp0     dw    0
        T_ss0     dw    0
        T_sp1     dw    0
        T_ss1     dw    0
        T_sp2     dw    0
        T_ss2     dw    0
        T_ip      dw    0
        T_flags   dw    0
        T_ax      dw    0
        T_cx      dw    0
        T_dx      dw    0
        T_bx      dw    0
        T_sp      dw    0
        T_bp      dw    0
        T_si      dw    0
        T_di      dw    0
        T_es      dw    0
        T_cs      dw    0
        T_ss      dw    0
        T_ds      dw    0
        T_ldt     dw    0
tss286df        ends

;
; Структура stack after pushad
pushaddef       struc
        P_edi     dd    0
        P_esi     dd    0
        P_ebp     dd    0
        P_esp     dd    0
        P_ebx     dd    0
        P_edx     dd    0
        P_ecx     dd    0
        P_eax     dd    0
pushaddef       ends
;
; Структура stack after pusha
pushadef        struc
        P_di      dw    0
        P_si      dw    0
        P_bp      dw    0
        P_sp      dw    0
        P_bx      dw    0
        P_dx      dw    0
        P_cx      dw    0
        P_ax      dw    0
pushadef        ends

;
; Структура стека 386 после прерывания
intstk386  struc
        oldeip    dd    0               ; all interrupts frame
        oldecs    dd    0
        oldeflg   dd    0
intnolvl386len    label
;--------------------------
        oldesp    dd    0               ; privelege level change add frame
        oldess    dd    0
intlvl386len      label
;--------------------------
        oldees    dd    0               ; v86 interrupts add frame
        oldeds    dd    0
        oldefs    dd    0
        oldegs    dd    0
v86stklen         label
intstk386  ends

;
; Структура стека 286 после прерывания
intstk286  struc
        oldip     dw    0               ; all interrupts frame
        oldcs     dw    0
        oldflg    dw    0
intnolvl286len    label
;--------------------------
        oldsp     dw    0               ; privelege level change add frame
        oldss     dw    0
intlvl286len      label
intstk286  ends

;
; Структура стека 386 после far call
callstk386  struc
        saveip    dd    0               ; all interrupts frame
        savecs    dd    0
callnolvl386len   label
;--------------------------
        savesp    dd    0               ; privelege level change add frame
        savess    dd    0
calllvl386len     label
callstk386  ends

;
; Структура стека 286 после far call
callstk286  struc
        savip     dw    0               ; all interrupts frame
        savcs     dw    0
callnolvl286len   label
;--------------------------
        savsp     dw    0               ; privelege level change add frame
        savss     dw    0
calllvl286len     label
callstk286  ends

;
; Структура дескриптора страницы в таблице страниц
pg_present      equ     000000001h      ; признак присутствия
pg_write        equ     000000002h      ; разрешена запись
pg_user         equ     000000004h      ; уровень пользователя
pg_accessed     equ     000000020h      ; был доступ к странице
pg_dirty        equ     000000040h      ; была запись в страницу
pg_addrmsk      equ     0fffff000h      ; маска битов адреса страницы
pg_addrctl      equ     000000fffh      ; маска битов управления
pg_pgmsk        equ     0003ff000h      ; маска индекса в таблице страниц
pg_dirmsk       equ     0ffc00000h      ; маска индекса в каталоге страниц
pg_pgshift      equ     0ch             ; число сдвигов линейного адреса
                                        ; вправо для получения индекса в
                                        ; таблице страниц
pg_dirshift     equ     16h             ; число сдвигов линейного адреса
                                        ; вправо для получения индекса в
                                        ; каталоге страниц
pte_mask        equ     00000007h       ; User,Write,Present
pdbr_offset     equ     1000h           ; размер страницы 4 кб.

; Биты в регистре CR0
pg_enable       equ     80000000h       ; включение режима страниц
pg_cachedis     equ     40000000h       ; запретить внутреннюю кэш     (i486)
pg_notwrite     equ     20000000h       ; Запись в кэш запрещена       (i486)
cr0_alig        equ     00040000h       ; проверка выравнивания        (i486)
pg_wrprot       equ     00010000h       ; запрещена запись супервизору (i486)
cr0_numerr      equ     00000020h       ; разр. прер. сопроцессора     (i486)
cr0_numext      equ     00000010h       ; тип процессора i80387(1)/i80287(0)
cr0_tasksw      equ     00000008h       ; было переключение задач (сбр. прогр.)
cr0_numemu      equ     00000004h       ; любая инстр. сопроцессора, кроме
                                        ; WAIT генерирует искл. отс. сопр.
cr0_numpres     equ     00000002h       ; сопроцессор есть
cro_protena     equ     00000001h       ; вкл. режим защищенной моды

; Биты в регистре CR3
cr3_addrmsk     equ     0fffff000h      ; маска битов адреса каталога
cr3_addrctl     equ     000000fffh      ; маска битов управления
cr3_pcd         equ     000000010h      ; управляет сигналом PCD (CD в CR0)
cr3_pwt         equ     000000008h      ; управляет сигналом PWT (WT в CR0)

; Биты в регистре флагов EFLAGS
fl_ac           equ     00040000h       ; проверка выравнивания разр.  (i486)
fl_vm           equ     00020000h       ; установлен режим вирт. v86
fl_rf           equ     00010000h       ; запрет двойного искл. по одному адресу
fl_nt           equ     00004000h       ; вложенный вызов по CALLF TSS
fl_iopl0        equ     00000000h       ; привелегия i/o = 0
fl_iopl1        equ     00001000h       ; привелегия i/o = 1
fl_iopl2        equ     00002000h       ; привелегия i/o = 2
fl_iopl3        equ     00003000h       ; привелегия i/o = 3
fl_ioplmsk      equ     00003000h       ; IOPL bits clear
fl_of           equ     00000800h       ; флаг переполнения            overflow
fl_df           equ     00000400h       ; флаг направления строк       direction
fl_if           equ     00000200h       ; флаг разрешения прерываний   interrupt
fl_tf           equ     00000100h       ; флаг пошаговой отладки       trace
fl_sf           equ     00000080h       ; флаг признака знакового бита sign
fl_zf           equ     00000040h       ; флаг признака нулевого рез.  zerro
fl_af           equ     00000010h       ; флаг признака bcd переноса   auxiliary
fl_pf           equ     00000004h       ; флаг признака паритета рез.  parity
fl_set          equ     00000002h       ; всегда 1
fl_cf           equ     00000001h       ; флаг признака переноса рез.  carry

; Биты в регистре флагов EFLAGS для режима v86
v86_flags       equ     fl_vm or fl_iopl3 or fl_if or fl_set

;
; DR6
drstat_B0       equ     0000000000000001b
drstat_B1       equ     0000000000000010b
drstat_B2       equ     0000000000000100b
drstat_B3       equ     0000000000001000b
drstat_EMU      equ     0010000000000000b
drstat_TBIT     equ     0100000000000000b
drstat_TASK     equ     1000000000000000b

;
; DR7
drctrl_lcl0     equ     00000000000000000000000000000001b
drctrl_gbl0     equ     00000000000000000000000000000010b
drctrl_msk0     equ     00000000000000000000000000000011b
drctrl_lcl1     equ     00000000000000000000000000000100b
drctrl_gbl1     equ     00000000000000000000000000001000b
drctrl_msk1     equ     00000000000000000000000000001100b
drctrl_lcl2     equ     00000000000000000000000000010000b
drctrl_gbl2     equ     00000000000000000000000000100000b
drctrl_msk2     equ     00000000000000000000000000110000b
drctrl_lcl3     equ     00000000000000000000000001000000b
drctrl_gbl3     equ     00000000000000000000000010000000b
drctrl_msk3     equ     00000000000000000000000011000000b
drctrl_lcle     equ     00000000000000000000000100000000b
drctrl_gble     equ     00000000000000000000001000000000b
drctrl_mske     equ     00000000000000000000001100000000b

drctrl_mskt0    equ     00000000000000110000000000000000b
drctrl_inst0    equ     00000000000000000000000000000000b
drctrl_wo0      equ     00000000000000010000000000000000b
drctrl_rw0      equ     00000000000000110000000000000000b
drctrl_1bl0     equ     00000000000000000000000000000000b
drctrl_2bl0     equ     00000000000001000000000000000000b
drctrl_4bl0     equ     00000000000011000000000000000000b
drctrl_mskl0    equ     00000000000011000000000000000000b

drctrl_mskt1    equ     00000000001100000000000000000000b
drctrl_inst1    equ     00000000000000000000000000000000b
drctrl_wo1      equ     00000000000100000000000000000000b
drctrl_rw1      equ     00000000001100000000000000000000b
drctrl_1bl1     equ     00000000000000000000000000000000b
drctrl_2bl1     equ     00000000010000000000000000000000b
drctrl_4bl1     equ     00000000110000000000000000000000b
drctrl_mskl1    equ     00000000110000000000000000000000b

drctrl_mskt2    equ     00000011000000000000000000000000b
drctrl_inst2    equ     00000000000000000000000000000000b
drctrl_wo2      equ     00000001000000000000000000000000b
drctrl_rw2      equ     00000011000000000000000000000000b
drctrl_1bl2     equ     00000000000000000000000000000000b
drctrl_2bl2     equ     00000100000000000000000000000000b
drctrl_4bl2     equ     00001100000000000000000000000000b
drctrl_mskl2    equ     00001100000000000000000000000000b

drctrl_mskt3    equ     00110000000000000000000000000000b
drctrl_inst3    equ     00000000000000000000000000000000b
drctrl_wo3      equ     00010000000000000000000000000000b
drctrl_rw3      equ     00110000000000000000000000000000b
drctrl_1bl3     equ     00000000000000000000000000000000b
drctrl_2bl3     equ     01000000000000000000000000000000b
drctrl_4bl3     equ     11000000000000000000000000000000b
drctrl_mskl3    equ     11000000000000000000000000000000b

; Error code format (dd in stack)
err_ext         equ     00001h
err_idt         equ     00002h
err_ldt         equ     00004h
err_selec       equ     0fff8h

; Page Fault Error code format (dd in stack)
pgerr_prot      equ     00001h          ; =1 page protection
                                        ; =0 page not present
pgerr_write     equ     00002h          ; =1 was writing in page
                                        ; =0 was reading from page
pgerr_superv    equ     00004h          ; =1 processor was in supervisor lvl
                                        ; =0 processor was in user lvl

;
; interrupts with error codes in stack
err_in_int0     equ     0               ; NO  in Divide Error
err_in_int1     equ     0               ; NO  in Debug Exeption (DR6)
err_in_int2     equ     0               ; NO  in NMI Interrupt
err_in_int3     equ     0               ; NO  in Instruction Breakpoint
err_in_int4     equ     0               ; NO  in INTO Overflow
err_in_int5     equ     0               ; NO  in BOUND Range Exceeded
err_in_int6     equ     0               ; NO  in Invalid Opcode
err_in_int7     equ     0               ; NO  in Coprocessor Not Available
err_in_int8     equ     1               ; YES in Double Exeption Fault
err_in_int9     equ     0               ; NO  in Coprocessor Segment Overrun
err_in_int10    equ     1               ; YES in Invalid TSS
err_in_int11    equ     1               ; YES in Segment Not Present
err_in_int12    equ     1               ; YES in Stack Fault
err_in_int13    equ     1               ; YES in General Protection
err_in_int14    equ     1               ; YES in Page Fault (CR2)
err_in_int16    equ     0               ; NO  in Coprocessor Error
err_reserved    equ     0               ; vector not present

err_tbl         struc
        err_int0        db      err_in_int0
        err_int1        db      err_in_int1
        err_int2        db      err_in_int2
        err_int3        db      err_in_int3
        err_int4        db      err_in_int4
        err_int5        db      err_in_int5
        err_int6        db      err_in_int6
        err_int7        db      err_in_int7
        err_int8        db      err_in_int8
        err_int9        db      err_in_int9
        err_int10       db      err_in_int10
        err_int11       db      err_in_int11
        err_int12       db      err_in_int12
        err_int13       db      err_in_int13
        err_int14       db      err_in_int14
        err_int15       db      err_reserved
        err_int16       db      err_in_int16
err_tbl         ends
