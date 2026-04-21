; Stopwatch Dialog

format PE GUI 4.0
include 'win32w.inc'
entry start
            ; PlaySound Enum
            SND_SYNC        = 00000000h
            SND_ASYNC       = 00000001h
            SND_NODEFAULT   = 00000002h
            SND_MEMORY      = 00000004h
            SND_ALIAS       = 00010000h
            SND_FILENAME    = 00020000h
            SND_RESOURCE    = 00040004h
            SND_ALIAS_ID    = 00110000h
            SND_ALIAS_START = 00000000h
            SND_LOOP        = 00000008h
            SND_NOSTOP      = 00000010h
            SND_VALID       = 0000001Fh
            SND_NOWAIT      = 00002000h
            SND_VALIDFLAGS  = 0017201Fh
            SND_RESERVED    = 0FF000000h
            SND_TYPE_MASK   = 00170007h

            TIMER_ID        = 123

            ; IDs
            ID_WINDOW       =       123
            ID_STATIC       =       50
            ID_START        =       200
            ID_STOP         =       201
            ID_5            =       305
            ID_10           =       310
            ID_15           =       315
            ID_20           =       320

section '.data' data readable writeable
            hwnd           dd       ?

            timerText      rb       32
            titleText      db       '   Minutes',0
            second         dd       0
            minute         dd       0
            hour           dd       0
            timer_running  db       FALSE

            sound          db       'beep.wav',0

            threadID       dd       ?
            ps             PAINTSTRUCT

section '.code' code readable executable

start:      invoke  GetModuleHandle,0
            invoke  DialogBoxParam,eax,123,HWND_DESKTOP,DialogProc,0
            invoke  ExitProcess,0

proc DialogProc hwnddlg,msg,wparam,lparam
            push    ebx esi edi
      ; Window Message
            cmp     [msg],WM_INITDIALOG
            je      .wminitdialog
            cmp     [msg],WM_COMMAND
            je      .wmcommand
            cmp     [msg],WM_PAINT
            je      .wmpaint
            cmp     [msg],WM_CLOSE
            je      .wmclose
            cmp     [msg],WM_TIMER
            je      .wmtimer
            xor     eax,eax
            jmp     .finish
      ; Select Button
.wmcommand: cmp     [wparam],BN_CLICKED shl 16 + ID_5
            jne     .c10
            mov     eax,5
            call    SetupTimer
            jmp     .exit
.c10:       cmp     [wparam],BN_CLICKED shl 16 + ID_10
            jne     .c15
            mov     eax,10
            call    SetupTimer
            jmp     .exit
.c15:       cmp     [wparam],BN_CLICKED shl 16 + ID_15
            jne     .c20
            mov     eax,15
            call    SetupTimer
            jmp     .exit
.c20:       cmp     [wparam],BN_CLICKED shl 16 + ID_20
            mov     eax,20
            call    SetupTimer
            jmp     .exit
      ; Timer
.wmtimer:
            cmp     [wparam],TIMER_ID
            jne     .exit
            mov     [timerText+6],':'
            mov     [timerText+12],':'
            mov     eax, [hour]
            mov     ecx, 10
            xor     edx, edx
            div     ecx

            add     al, '0' ;tens
            add     dl, '0' ;ones

            mov     [timerText+2], al
            mov     [timerText+4], dl

            mov     eax, [minute]
            mov     ecx, 10
            xor     edx, edx
            div     ecx

            add     al, '0' ;tens
            add     dl, '0' ;ones

            mov     [timerText+8], al
            mov     [timerText+10], dl

            mov     eax, [second]
            mov     ecx, 10
            xor     edx, edx
            div     ecx

            add     al, '0' ;tens
            add     dl, '0' ;ones

            mov     [timerText+14], al
            mov     [timerText+16], dl
           
            invoke  InvalidateRect,[hwnd],NULL,1 ; Trigger WM_PAINT

            dec     [second]
            jns     ._dec 
            mov     [second],59
            dec     [minute]
            jns     ._dec
            mov     [minute],59
            dec     [hour]

._dec:      mov     eax, [hour]
            or      eax, [minute]
            or      eax, [second]
            jnz     .exit

            invoke KillTimer,[hwnd],TIMER_ID
            invoke PlaySound,sound,NULL,SND_ASYNC or SND_FILENAME

      ; Draw
.wmpaint:   invoke  BeginPaint,[hwnd],ps
            cmp     [timer_running],TRUE
            jne     .p3
            invoke  TextOut,eax,5,5,timerText,15
.p3:        invoke  EndPaint,[hwnd],ps
            jmp     .exit
.wminitdialog:
            mov     eax,[hwnddlg]
            mov     [hwnd],eax
            jmp     .exit
.wmclose:   
            invoke KillTimer,[hwnd],TIMER_ID
            invoke EndDialog,[hwnddlg],0
.exit:      mov     eax,1
.finish:    pop     edi esi ebx
            ret
                
endp

; ==============
; Setup timer minutes and start timer
; --------------
; eax: minutes
; --------------
SetupTimer: mov     [hour],0
            mov     [minute],eax
            mov     [second],0
            invoke  SetTimer,[hwnd],TIMER_ID,1000,0

            mov     [timer_running],TRUE

            mov     eax, [minute]
            mov     ecx, 10
            xor     edx, edx
            div     ecx

            add     al, '0' ;tens
            add     dl, '0' ;ones

            mov     [titleText+0],al
            mov     [titleText+1],dl

            invoke  SetWindowTextA,[hwnd],titleText
            ret
                
section '.idata' import data readable writeable

library kernel32,'kernel32.dll',\
        user32,'user32.dll',\
        gdi32,'gdi32.dll',\
        winmm,'winmm.dll'

import  winmm,\
        PlaySound,'PlaySound'

include 'api/kernel32.inc'
include 'api/user32.inc'
include 'api/gdi32.inc'

section '.rsrc' resource data readable

    directory RT_DIALOG,dialogs
    resource dialogs,ID_WINDOW,LANG_ENGLISH+SUBLANG_DEFAULT,demonstration

    dialog demonstration,   'Countdown'                       ,600,300,130,50,      WS_CAPTION+WS_POPUP+WS_SYSMENU+DS_MODALFRAME
        dialogitem 'BUTTON','5 min'               ,ID_5       ,5,30,30,15,          WS_VISIBLE+WS_TABSTOP+BS_DEFPUSHBUTTON
        dialogitem 'BUTTON','10 min'              ,ID_10      ,35,30,30,15,         WS_VISIBLE+WS_TABSTOP+BS_DEFPUSHBUTTON
        dialogitem 'BUTTON','15 min'              ,ID_15      ,65,30,30,15,         WS_VISIBLE+WS_TABSTOP+BS_DEFPUSHBUTTON
        dialogitem 'BUTTON','20 min'              ,ID_20      ,95,30,30,15,         WS_VISIBLE+WS_TABSTOP+BS_DEFPUSHBUTTON
    enddialog
