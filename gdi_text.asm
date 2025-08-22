;
; win32 gdi text

format PE GUI 4.0

include 'win32wx.inc'

.data

_class TCHAR 'FASMWIN32',0
_title TCHAR 'TextOut',0
_error TCHAR 'Startup failed.',0

wc WNDCLASS 0,WindowProc,0,0,NULL,NULL,NULL,COLOR_BACKGROUND,NULL,_class
msg MSG
hdc dd ?
paintstruct PAINTSTRUCT

.code

start:
    invoke  GetModuleHandle,0
    mov     [wc.hInstance],eax
    invoke  LoadIcon,0,IDI_APPLICATION
    mov     [wc.hIcon],eax
    invoke  LoadCursor,0,IDC_ARROW
    mov     [wc.hCursor],eax
    invoke  CreateSolidBrush, 0x000000
    mov     [wc.hbrBackground], eax
    invoke  RegisterClass,wc
    test    eax,eax
    jz	    error
    invoke  CreateWindowEx,0,_class,_title,WS_VISIBLE+WS_SYSMENU,320,320,256,192,NULL,NULL,[wc.hInstance],NULL
    test    eax,eax
    jz	    error

msg_loop:
    invoke  GetMessage,msg,NULL,0,0
    cmp     eax,1
    jb	    end_loop
    jne     msg_loop
    invoke  TranslateMessage,msg
    invoke  DispatchMessage,msg
    jmp     msg_loop

error:
    invoke  MessageBox,NULL,_error,NULL,MB_ICONERROR+MB_OK

end_loop:
    invoke  ExitProcess,[msg.wParam]


proc WindowProc uses ebx esi edi, hwnd,wmsg,wparam,lparam
    cmp     [wmsg], WM_DESTROY
    je	    .wmdestroy
    cmp     [wmsg], WM_PAINT
    je	    .wmpaint

.defwndproc:
    invoke  DefWindowProc,[hwnd],[wmsg],[wparam],[lparam]
    jmp     .finish

.wmdestroy:
    invoke  PostQuitMessage,0
    xor     eax,eax
    jmp     .finish

.wmpaint:
    invoke  BeginPaint, [hwnd], paintstruct
    mov     [hdc], eax
    invoke  CreatePen,PS_SOLID, 1, 0xFFFF00
    invoke  SelectObject, [hdc], eax
    invoke  SetBkColor, [hdc], 0xFFFFFF
    invoke  SetTextColor,[hdc], 0xFF0000
    invoke  TextOut, [hdc], 5, 5, 'hello world 123',15

    invoke  EndPaint, [hwnd], paintstruct

.finish:
    ret
endp

.end start
