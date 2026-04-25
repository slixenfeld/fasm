;       Dialog Template - (C) 2026 Simlx
;       Template for creating win32 dialog programs

        format pe gui 4.0
        include 'win32wx.inc'
.data
        mem     rb  0xff
.code
start:
        invoke  GetModuleHandle,0
        invoke  DialogBoxParam,eax,100,HWND_DESKTOP,winproc,0
        invoke  ExitProcess,0

proc winproc hwnddlg,msg,wparam,lparam
        push    ebx esi edi
        cmp     [msg],  WM_INITDIALOG
        je      .wminitdialog
        cmp     [msg],  WM_CLOSE
        je      .wmclose
        xor     eax,eax
        jmp     .finish
.wminitdialog:
        jmp     .exit
.wmclose:
        invoke  EndDialog,[hwnddlg],0
.exit:  mov     eax,1
.finish:
        pop     edi esi ebx
        ret
endp

.end start
                                                  
section '.rsrc' resource data readable

directory RT_DIALOG,dialogs
resource dialogs,100,LANG_ENGLISH+SUBLANG_DEFAULT,demonstration

dialog demonstration,'Dialog Window',450,220,240,120,\
        WS_CAPTION+WS_POPUP+WS_SYSMENU+DS_MODALFRAME

enddialog
