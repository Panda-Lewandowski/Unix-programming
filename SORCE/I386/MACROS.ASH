;/*
; Макро описания стекового фрагмента в TSS
TSS_stack macro ss0,esp0,ss1,esp1,ss2,esp2
        dd      0h              ; Связь назад при вызове CALL
                                ; при инициализации всегда 0
        dd      offset (esp0)
        dd      (ss0)
        dd      offset (esp1)
        dd      (ss1)
        dd      offset (esp2)
        dd      (ss2)
endm

;
; Макро описания фрагмента cr3 в TSS
TSS_cr3   macro tcr3
        dd      (tcr3)
endm

;
; Макро описания фрагмента регистров общего назначения в TSS
TSS_regs  macro teip,tflg,teax,tebx,tecx,tedx,tesi,tedi,tebp,tesp
        dd      offset (teip)
        dd      tflg
        dd      teax
        dd      tecx
        dd      tedx
        dd      tebx
        dd      offset (tesp)
        dd      tebp
        dd      tesi
        dd      tedi
endm

;
; Макро описания фрагмента сегментных регистров в TSS
TSS_seg   macro tes,tcs,tss,tds,tfs,tgs
        dd      (tes)
        dd      (tcs)
        dd      (tss)
        dd      (tds)
        dd      (tfs)
        dd      (tgs)
endm

;
; Макро описания вызова подпрограммы через вентиль вызова
; Передача возможна только в кодовый сегмент того же уровня привелегий
; или более привелегированный (простой или согласованный)
callf   macro selector
        db      09ah            ; far call code
        dw      0h              ; смещение всегда 0
        dw      (selector)      ; селектор вентиля вызова в GDT/LDT
endm

;
; Макро описания перехода на подпрограмму через вентиль вызова
; Передача возможна только в кодовый сегмент того же уровня привелегий
; или в согласованный сегмент
jmpf   macro selector
        db      0eah            ; far jmp code
        dw      0h              ; смещение всегда 0
        dw      (selector)      ; селектор вентиля вызова в GDT/LDT
endm

;
; Макро вычисления линейных адресов и пределов таблицы GDT
; выполняется в реальном режиме процессора
; Параметры : gdt      - сегментный адрес сегмента таблицы GDT
;             pgdt     - адрес FWORD описателя сегмента GDT
;             gdtlimit - предел таблицы GDT
build_gdtr      macro gdt,pgdt,gdtlimit
        mov     ax,(gdtlimit)           ; предел сегмента GDT
        mov     word ptr [(pgdt)],ax    ; запомнить в описателе GDT.limit
        xor     eax,eax
        mov     ax,(gdt)                ; сегментный адрес таблицы GDT
        shl     eax,4                   ; получим 32-разрядный лин. адрес
        mov     dword ptr [(pgdt)+2],eax; запомним в описателе GDT.base
endm
;
; Макро вычисления линейных адресов и пределов таблицы IDT
; выполняется в реальном режиме процессора
; Параметры : idt      - сегментный адрес сегмента таблицы IDT
;             pidt     - DS:адрес FWORD описателя сегмента IDT
;             idtlimit - предел таблицы IDT
build_idtr      macro idt,pidt,idtlimit
        mov     ax,(idtlimit)           ; предел сегмента IDT
        mov     word ptr [(pidt)],ax    ; запомнить в описателе IDT.limit
        xor     eax,eax
        mov     ax,(idt)                ; сегментный адрес таблицы IDT
        shl     eax,4                   ; получим 32-разрядный лин. адрес
        mov     dword ptr [(pidt)+2],eax; запомним в описателе IDT.base
endm

;
; Макро инициализации базовых адресов сегментов
; дескрипторов таблицы сегментов
; Параметры : dtseg     -  сегментный адрес сегмента таблицы дескрипторов
;             dttable   -  DS:адрес таблицы описателей преобразования
;             dtcount   -  число описателей в таблице преобразований
build_dt        macro dtseg,dttable,dtcount
        local   bdtl
        mov     ax,(dtseg)
        mov     es,ax                   ; ES    = таблица дискрипторов
        mov     si,offset (dttable)     ; DS:SI = таблица описателей преобр.
        mov     cx,(dtcount)            ; CX    = счетчик циклов
bdtl:
        lodsw
        mov     bx,ax                   ; bx = селектор текущего сегмента
        and     bx,0fff8h               ; очистка битов TI и RPL
        lodsw                           ; ax = сегментный адрес тек. сегмента
        mov     dl,ah
        shl     ax,4                    ; low 16 бит физ. адрес сегмента
        mov     es:[bx+D_base1],ax
        shr     dl,4                    ; high 8 бит физ. адрес сегмента
        mov     es:[bx+D_base2],dl
        loop    bdtl
endm

;
; Макро перевода процессора в защищенный режим работы
goto_prot       macro   gdtptr,idtptr,cseg,stkseg,stkptr,dseg
        local   now_in_prot

        lgdt    [(gdtptr)]              ; загрузить таблицу GDT в gdtr
        lidt    [(idtptr)]              ; загрузить таблицу IDT в idtr

        cli

        mov     al,A20_PORT             ; открыть линию A20
        out     STATUS_PORT,al
        mov     al,A20_ON
        out     KBD_PORT_A,al

        mov     [real_es],es            ; запомнить ES для реального режима
        mov     [real_ss],ss            ; запомнить указатель стека
        mov     [real_sp],sp

        mov     al,8fh                  ; немаскируемые прерывания запрещаются
        out     CMOS_PORT,al            ; битом 80h при доступе к CMOS
        jmp     $+2                     ; небольшая задержка
        in      al,CMOS_PORT+1

        in      al,INT_MASK_PORT        ; разрешение маскируемых прерываний
        mov     [int_mask],al           ; запомним маску прерываний
        mov     al,0ffh                 ; запретим прерывания контроллеру
        out     INT_MASK_PORT,al        ; прерываний

        mov     eax,cr0
        or      al,prot_enable          ; перекл. проц. в защищенный реж.
        mov     cr0,eax                 ; мы в защищенном режиме

; Во входной очереди команд находятся команды, дешифрированные
; в реальном режиме процессора, их надо сбросить
        jmp     $+2                     ; near jmp для сброса очереди команд

        db      0eah                    ; far jmp для загрузки селектора
        dw      offset now_in_prot      ; и дескр. сегмента кодов защищ.
        dw      (cseg)                  ; режима на нулевом уровне защиты
now_in_prot:

        xor     ax,ax
        lldt    ax                      ; NULL селектор в LDT

        mov     ax,(stkseg)             ; селектор сегмента SS
        mov     ss,ax
        mov     sp,offset (stkptr)

        mov     ax,(dseg)               ; сегментный адрес данных prot mode
        mov     ds,ax                   ; загрузка всех сегментных регистров
        mov     es,ax                   ; для загрузки селекторов и
        mov     fs,ax                   ; дескрипторов сегментов правильными
        mov     gs,ax                   ; значениями всех полей
endm

;
; Макро перевода процессора в реальный режим работы
goto_real       macro   dummy_sel,cseg,stkseg,stkptr,dseg
        local   limit_r,now_in_real

        cli

        mov     ax,(dummy_sel)          ; селектор данных реального режима
        mov     es,ax                   ; для загрузки дескрипторов сегм.
        mov     ds,ax                   ; регистров правильной для DOS
        mov     fs,ax                   ; границей сегментов и атрибутами
        mov     gs,ax                   ; доступа
        mov     ss,ax

        db      0eah                    ; far jmp для загрузки дескриптора
        dw      OFFSET  limit_r         ; сегмента кодов правильной для DOS
        dw      rc_selec                ; границей и атрибутами доступа
limit_r:

        mov     eax,cr0
        and     eax,not prot_enable     ; перекл. проц. в реальный режим
        mov     cr0,eax                 ; мы в реальном режиме

; Во входной очереди команд находятся команды, дешифрированные
; в защищенном режиме процессора, их надо сбросить
        jmp     $+2                     ; near jmp для сброса очереди команд

        db      0eah                    ; far jmp для загрузки селектора
        dw      offset now_in_real      ; и дескриптора кодов правильным
        dw      (cseg)                  ; в DOS адресом базы сегмента
now_in_real:

        assume  ds:gdata

        mov     ax,(dseg)               ; сегментный адрес данных real mode
        mov     ds,ax                   ; загрузка всех сегментных регистров
        mov     es,ax                   ; для загрузки селекторов и
        mov     fs,ax                   ; дескрипторов сегментов правильным
        mov     gs,ax                   ; в DOS адресом базы

        mov     ax,(stkseg)             ; сегментный адрес стека real mode
        mov     ss,ax                   ; правильный адрес сегмента
        mov     sp,offset (stkptr)      ; стек реального режима

        lidt    [pold]                  ; таблица прерываний реального режима

        mov     al,A20_PORT             ; Закрыть адресную шину A20
        out     STATUS_PORT,al
        mov     al,A20_OF
        out     KBD_PORT_A,al

        mov     ax,00fh                 ; разрешение немаскируемых прерываний
        out     CMOS_PORT,al
        jmp     $+2                     ; небольшая задержка
        in      al,CMOS_PORT+1

        mov     al,[int_mask]           ; восстановим маску прерываний
        out     INT_MASK_PORT,al        ; разрешим маскируемые прерывания

        sti
endm
