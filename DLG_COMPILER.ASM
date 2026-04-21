        format pe gui 4.0
        include 'win32wx.inc'

        ID_BUTTON_COMPILE       = 0x10
        ID_BUTTON_RUN           = 0x11
        ID_EDIT_FILEPATH        = 0x20
        ID_EDIT_OUTPUT          = 0x30

        HANDLE_FLAG_INHERIT = 1

.data
        mem     rb  0xff

        cmdRun  db ' && ',0
        cmdFasm db 'cmd /c fasm.exe ',0
        cmdLine db '                                                      '
                db '                                                      '
                db '                                                      ',0

        hwnd    dd ?

        buffer  rb  4096
        bytes   dd  0

        hRead   dd ?
        hWrite  dd ?
        hEdit   dd ?

        struct SECURITY_ATTRIBUTES
          nLength              dd ?
          lpSecurityDescriptor dd ?
          bInheritHandle       dd ?
        ends

        _si     STARTUPINFO
        _pi     PROCESS_INFORMATION
        sa1     SECURITY_ATTRIBUTES

        wc      WNDCLASS
        msg     MSG
.code
start:
        invoke  GetModuleHandle,0
        invoke  DialogBoxParam,eax,100,HWND_DESKTOP,winproc,0
        invoke  ExitProcess,0

ReadThread:
.read_loop:
    invoke ReadFile, [hRead], buffer, 4095, bytes, 0
    test eax, eax
    jz .check_end

    mov eax, [bytes]
    mov byte [buffer+eax], 0

    invoke SendMessageA, [hEdit], EM_SETSEL, -1, -1
    invoke SendMessageA, [hEdit], EM_REPLACESEL, TRUE, buffer

    jmp .read_loop

.check_end:
    invoke CloseHandle, [hRead]
    invoke ExitThread, 0


proc winproc hwnddlg,msg,wparam,lparam
        push    ebx esi edi
        cmp     [msg],  WM_INITDIALOG
        je      .wminitdialog
        cmp     [msg],  WM_COMMAND
        je      .wmcommand
        cmp     [msg],  WM_CLOSE
        je      .wmclose
        xor     eax,eax
        jmp     .finish
.wmcommand:
        cmp     [wparam],BN_CLICKED shl 16 + ID_BUTTON_COMPILE
        je      .bcomp
        cmp     [wparam],BN_CLICKED shl 16 + ID_BUTTON_RUN
        je      .brun
        jmp     .exit
.brun:
; COMPILE & RUN:
        mov     eax, 1
        call    execute_cmd
        jmp     .exit
.bcomp:
; COMPILE ONLY:
        mov     eax, 0
        call    execute_cmd
.done:
        jmp     .exit
.wminitdialog:
        mov     eax, [hwnddlg]
        mov     [hwnd], eax
        jmp     .exit
.wmclose:
        invoke  EndDialog,[hwnd],0
.exit:  mov     eax,1
.finish:
        pop     edi esi ebx
        ret


; EAX: 0: compile, 1: compile and run
;
execute_cmd:
        push    eax

; CMD AUSFUEHREN:
        invoke  GetDlgItem,[hwnd],ID_EDIT_OUTPUT
        mov     [hEdit],eax

; copy fasm string into cmd
        mov     esi, cmdFasm
        mov     edi, cmdLine
.sl0:   mov     al, [esi]
        mov     [edi], al
        inc     esi
        inc     edi
        test    al, al
        jnz     .sl0

; replace 0 byte of fasm base string
        dec     edi
        mov     [edi], byte ' '

; copy filepath string into cmd
        invoke  GetDlgItemTextA,[hwnd],ID_EDIT_FILEPATH,buffer,4095
        mov     esi, buffer
.sl1:   mov     al, [esi]
        mov     [edi], al
        inc     esi
        inc     edi
        test    al, al
        jnz     .sl1

        pop     eax ; get eax parameter
        test    eax, eax
        jz      .norun

; replace 0 byte of filepath string
        dec     edi
        mov     [edi], byte ' '

; copy run string into cmd
        mov     esi, cmdRun
.sl2:   mov     al, [esi]
        mov     [edi], al
        inc     esi
        inc     edi
        test    al, al
        jnz     .sl2
; replace 0 byte of run string
        dec     edi
        mov     [edi], byte ' '


; copy filepath string into cmd and replace end with .exe
        invoke  GetDlgItemTextA,[hwnd],ID_EDIT_FILEPATH,buffer,4096
        mov     esi, buffer
.sl3:   mov     al, [esi]
        mov     [edi], al
        inc     esi
        inc     edi
        test    al, al
        jnz     .sl3

        dec     edi
        dec     edi
        mov     [edi], byte 'e'
        dec     edi
        mov     [edi], byte 'x'
        dec     edi
        mov     [edi], byte 'e'
.norun:

        ;invoke MessageBoxA, [hwnd], cmdLine, "cmd", MB_OK

        mov     [sa1.nLength], sizeof.SECURITY_ATTRIBUTES
        mov     [sa1.lpSecurityDescriptor], 0
        mov     [sa1.bInheritHandle], TRUE

        invoke  CreatePipe, addr hRead, addr hWrite, addr sa1, 0
        invoke  SetHandleInformation, [hRead], HANDLE_FLAG_INHERIT, 0

        invoke  RtlZeroMemory, addr _si, sizeof.STARTUPINFO
        invoke  RtlZeroMemory, addr _pi, sizeof.PROCESS_INFORMATION

        mov     [_si.cb], sizeof.STARTUPINFO
        mov     [_si.dwFlags], STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW
        mov     [_si.wShowWindow], SW_HIDE

        mov     eax, [hWrite]
        mov     [_si.hStdOutput], eax
        mov     [_si.hStdError], eax
        mov     [_si.hStdInput], 0

        invoke  CreateProcessA, 0, cmdLine, 0, 0, TRUE, 0, 0, 0, _si, _pi
        
        invoke  CloseHandle, [hWrite]
        invoke  CreateThread, 0, 0, addr ReadThread, 0, 0, 0

        ret

endp

.end start

section '.rsrc' resource data readable

directory RT_DIALOG,dialogs
resource dialogs,100,LANG_ENGLISH+SUBLANG_DEFAULT,demonstration

dialog demonstration,'Flat Assembler GUI',450,220,210,140,\
        WS_CAPTION+WS_POPUP+WS_SYSMENU+DS_MODALFRAME

dialogitem 'EDIT','filepath',ID_EDIT_FILEPATH,5,5,200,12,\
        WS_VISIBLE+WS_TABSTOP+WS_BORDER+WS_VSCROLL

dialogitem 'BUTTON','Compile + Run',ID_BUTTON_RUN,5,20,80,20,\
        WS_VISIBLE+WS_TABSTOP+BS_DEFPUSHBUTTON

dialogitem 'BUTTON','Compile',ID_BUTTON_COMPILE,90,20,80,20,\
        WS_VISIBLE+WS_TABSTOP+BS_DEFPUSHBUTTON

dialogitem 'EDIT','',ID_EDIT_OUTPUT,5,45,200,80,\
        WS_VISIBLE+WS_TABSTOP+WS_BORDER+WS_VSCROLL\
        +ES_MULTILINE+ES_AUTOVSCROLL+ES_WANTRETURN

enddialog
