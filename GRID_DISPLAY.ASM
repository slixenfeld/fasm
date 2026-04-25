        format pe gui 4.0
        include 'win32wx.inc'

        GRID_W   = 25
        GRID_H   = 16

        BMP_SIZE = 500
.data
        mem     rb  0xff
        txt     rb  4096

        buffer  rb  4096
        bytes   dd  0

        gx      dd  0
        gy      dd  0

        sx      dd  0           ; Selected Cell X
        sy      dd  0           ; Selected Cell Y

        A       dd  0
        B       dd  0
        C       dd  0

        lpdx    dd  5

        hwnd       dd ?         ; hwnddlg
        hdc        dd ?
        memdc      dd ?         ; in-memory device context
        bmp        dd ?         ; bmp to draw to
        ps         PAINTSTRUCT  ; Paintstruct for drawing
        pen        dd ?         ; Main Pen for drawing
        cyan_b     dd ?         ; Cyan Brush for drawing
        blue_b     dd ?         ; Blue Brush for drawing
        old_brush  dd ?
        black_b    dd ?
        gray_b     dd ?
        rect       RECT         ; RECT for FillRect

        cursorpos  POINT

.code
start:
        invoke  GetModuleHandle,0
        invoke  DialogBoxParam,eax,100,HWND_DESKTOP,\
                winproc,0
        invoke  ExitProcess,0

proc winproc hwnddlg,msg,wparam,lparam
        push    ebx esi edi
        cmp     [msg],  WM_INITDIALOG
        je      .wminitdialog
        cmp     [msg],  WM_COMMAND
        je      .wmcommand
        cmp     [msg],   WM_MOUSEMOVE
        je      .wmposchanged
        cmp     [msg],  WM_PAINT
        je      .paint
        cmp     [msg],  WM_CLOSE
        je      .wmclose
        xor     eax,eax
        jmp     .finish
.wmcommand:
        jmp     .exit
.wmposchanged:
        invoke  GetCursorPos,cursorpos
        invoke  ScreenToClient,[hwnd],cursorpos
        invoke  InvalidateRect,[hwnd],NULL,0
        jmp     .exit
.done:
        jmp     .exit
.wminitdialog:
        mov     eax, [hwnddlg]
        mov     [hwnd], eax

        ; Setup Bitmap for drawing
        invoke  BeginPaint,[hwnd],ps
        mov     [hdc],eax
        invoke  CreateCompatibleDC,[hdc]
        mov     [memdc],eax
        invoke  CreateCompatibleBitmap,[hdc],\
                BMP_SIZE,BMP_SIZE
        mov     [bmp],eax
        invoke  EndPaint,[hwnd],ps

        ; Setup brushes
        invoke  CreateSolidBrush,0x00ffff00
        mov     [cyan_b],eax
        invoke  CreateSolidBrush,0x00ff0000
        mov     [blue_b],eax
        invoke  GetStockObject,BLACK_BRUSH
        mov     [black_b],eax

        ; Initialize txt array
        mov     eax,0
        mov     esi,txt
.ltxt:
        mov     byte [esi],' '
        inc     eax
        inc     esi
        cmp     eax,4095
        jl      .ltxt

        ; Set txt memory
        mov     dword [txt+0], 'TEST'

        jmp     .exit
.paint:
        ; Setup DC
        invoke  BeginPaint,[hwnd],ps
        mov     [hdc],eax

        ; Draw Background
        invoke  SelectObject,[memdc],[bmp]
        invoke  GetStockObject,BLACK_BRUSH
        mov     [rect.left],0
        mov     [rect.top],0
        mov     [rect.right],BMP_SIZE
        mov     [rect.bottom],BMP_SIZE
        invoke  FillRect,[memdc],rect,eax

        ; Draw ASCII Grid
        mov     [A],0
        mov     esi,txt

        invoke  SetBkMode,[memdc],TRANSPARENT

        ; Setup ASCII Box
        mov     [B],16
        mov     eax,[B]
        mov     [rect.left],0
        mov     [rect.top],0
        mov     [rect.right],eax
        mov     [rect.bottom],eax

        mov     [gx],0
        mov     [gy],0

        ; Calculate Select Cell X
        mov     eax,[cursorpos.x]
        add     eax,[B]
        xor     edx,edx
        mov     ecx,[B]
        div     ecx
        mov     [sx],eax

        ; Calculate Select Cell Y
        mov     eax,[cursorpos.y]
        xor     edx,edx
        mov     ecx,[B]
        div     ecx
        mov     [sy],eax

.LYasc:
.LXasc:
        inc     [gx]

; on X,Y mouse position, use a different brush:
        mov     eax,[sx]
        cmp     [gx],eax
        jne     .nmpos
        mov     eax,[sy]
        cmp     [gy],eax
        jne     .nmpos
        invoke  SelectObject,[memdc],[blue_b]
        invoke  SelectObject,[memdc],[blue_b]
        jmp     .selected
.nmpos:
        invoke  SelectObject,[memdc],[cyan_b]
        invoke  SelectObject,[memdc],[cyan_b]
.selected:
        invoke  FillRect,[memdc],rect,eax
        invoke  SelectObject,[memdc],[black_b]

        mov     eax, [rect.left]
        add     eax, 3
        invoke  TextOutA,[memdc],eax,[rect.top],esi,1
        mov     eax,[B]
        add     [rect.right], eax
        add     [rect.left],  eax

        inc     esi
        cmp     [gx],GRID_W
        jl      .LXasc

        ; Setup for next line
        mov     eax,[B]
        add     [rect.top],   eax
        add     [rect.bottom],eax
        mov     [rect.right], eax
        mov     [rect.left],  0

        ;mov     eax,[gy]
        ;mov     ebx,GRID_W
        ;mul     ebx
        ;add     eax,txt

        mov     [gx],0
        inc     [gy]
        cmp     [gy],GRID_H
        jl      .LYasc

        invoke  BitBlt,[hdc],0,0,BMP_SIZE,BMP_SIZE,\
                [memdc],0,0,SRCCOPY
        ; Destroy DC
        invoke  EndPaint,[hwnd],ps

        jmp     .exit
.wmclose:
        invoke  DeleteObject,[bmp]
        invoke  DeleteDC,[memdc]
        invoke  EndDialog,[hwnd],0
.exit:  mov     eax,1
.finish:
        pop     edi esi ebx
        ret
endp

.end start

section '.rsrc' resource data readable

directory RT_DIALOG,dialogs
resource dialogs,100,LANG_ENGLISH+SUBLANG_DEFAULT,\
         demonstration

dialog demonstration,'ASCII',250,380,320,200,\
        WS_CAPTION+WS_POPUP+WS_SYSMENU+DS_MODALFRAME

enddialog
