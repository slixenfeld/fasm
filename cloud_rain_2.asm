        format PE GUI 4.0
        include 'win32wx.inc'

        CLOUDS = 10
        RAIN_INTERVAL = 10
        NUM_RAIN = 30

        KEY_A = 65
        KEY_S = 83
        KEY_W = 87
        KEY_D = 68

        BITMAP_WIDTH = 350
.data
        hwnd    dd ?
        hdc     dd ?
        brush   dd ?
        pen     dd ?
        old_pen dd ?
        bmp     dd ?
        memdc   dd ?

        count   dd 0

        cloud_x rb 2 * (CLOUDS + 1)
        cloud_y rb 2 * (CLOUDS + 1)

        rain_x  rb 2 * (NUM_RAIN + 1)
        rain_y  rb 2 * (NUM_RAIN + 1)
        rain_a  rb 1 * (NUM_RAIN + 1)
        rain_c  dd ?

        cloud_i dd 0
        cloud_s dd 0

        ps PAINTSTRUCT
        rect RECT
        
        debug_text_w db "W Pressed"
        debug_text_a db "A Pressed"
        debug_text_s db "S Pressed"
        debug_text_d db "D Pressed"

        KEY_DOWN_W db 0
        KEY_DOWN_A db 0
        KEY_DOWN_S db 0
        KEY_DOWN_D db 0

        buffer rb 0xfff
.code
start:
        mov ebx, 0
.init_rain:
        mov eax, ebx
        mov byte [rain_a+eax], 0
        inc ebx
        cmp ebx, NUM_RAIN
        jl .init_rain
.init_clouds:
; clouds x
        mov     word[cloud_x+0],  211
        mov     word[cloud_x+2],  60
        mov     word[cloud_x+4],  150
        mov     word[cloud_x+6],  197
        mov     word[cloud_x+8],  100
        mov     word[cloud_x+10], -30
        mov     word[cloud_x+12], -70
        mov     word[cloud_x+14], 29
        mov     word[cloud_x+16], 120
        mov     word[cloud_x+18], -140
; clouds y
        mov     word[cloud_y+0],  21 /2
        mov     word[cloud_y+2],  53 /2
        mov     word[cloud_y+4],  33 /2
        mov     word[cloud_y+6],  93 /2
        mov     word[cloud_y+8],  28 /2
        mov     word[cloud_y+10], 78 /2
        mov     word[cloud_y+12], 85 /2
        mov     word[cloud_y+14], 28 /2
        mov     word[cloud_y+16], 60 /2
        mov     word[cloud_y+18], 99 /2
        invoke  CreatePen,PS_SOLID,2,0x00ff0000
        mov     [pen],eax
        invoke  GetModuleHandle,0
        invoke  DialogBoxParam,eax,123,HWND_DESKTOP,DialogProc,0
        invoke  ExitProcess,0

proc    DialogProc hwnddlg, msg, wparam, lparam
        push ebx esi edi
        cmp     [msg],WM_INITDIALOG
        je      .init
        cmp     [msg],WM_COMMAND
        je      .cmd
        cmp     [msg],WM_KEYDOWN
        je      .kd
        cmp     [msg],WM_KEYUP
        je      .ku        
        cmp     [msg],WM_TIMER
        je      .timer
        cmp     [msg],WM_PAINT
        je      .paint
        cmp     [msg],WM_CLOSE
        je      .close
        xor     eax,eax
        jmp     .finish
.cmd:   jmp     .exit

.kd:    cmp     [wparam],KEY_W  ;cinvoke wsprintf,buffer,'%d',[wparam]
        je      .kd_w
        cmp     [wparam],KEY_A
        je      .kd_a
        cmp     [wparam],KEY_S
        je      .kd_s
        cmp     [wparam],KEY_D
        je      .kd_d
.kd_w:  mov     [KEY_DOWN_W],TRUE
        jmp     .af_kd
.kd_a:  mov     [KEY_DOWN_A],TRUE
        jmp     .af_kd
.kd_s:  mov     [KEY_DOWN_S],TRUE
        jmp     .af_kd
.kd_d:  mov     [KEY_DOWN_D],TRUE
        jmp     .af_kd
.af_kd: jmp     .exit

.ku:    cmp     [wparam],KEY_W
        je      .ku_w
        cmp     [wparam],KEY_A
        je      .ku_a
        cmp     [wparam],KEY_S
        je      .ku_s
        cmp     [wparam],KEY_D
        je      .ku_d
.ku_w:  mov     [KEY_DOWN_W],FALSE
        jmp     .af_ku
.ku_a:  mov     [KEY_DOWN_A],FALSE
        jmp     .af_ku
.ku_s:  mov     [KEY_DOWN_S],FALSE
        jmp     .af_ku
.ku_d:  mov     [KEY_DOWN_D],FALSE
        jmp     .af_ku
.af_ku: jmp     .exit

.init:  mov     eax,[hwnddlg]
        mov     [hwnd],eax
        invoke  SetTimer,eax,1,40,NULL
        jmp     .exit
.timer: invoke  InvalidateRect,[hwnd],NULL,1
        jmp     .exit
.paint: invoke  BeginPaint,[hwnd],ps
        mov     [hdc],eax
        invoke  CreateCompatibleDC,[hdc]
        mov     [memdc],eax
        invoke  CreateCompatibleBitmap,[hdc],BITMAP_WIDTH,0xff
        mov     [bmp],eax     
        invoke  SelectObject,[memdc],[bmp]
        invoke  GetStockObject,WHITE_BRUSH
        mov     [rect.left],0
        mov     [rect.top],0
        mov     [rect.right],BITMAP_WIDTH
        mov     [rect.bottom],0xff
        invoke  FillRect,[memdc],rect,eax
        inc     [rain_c]
        cmp     [rain_c],RAIN_INTERVAL
        jl      .snr
        call    sp_rain
        mov     [rain_c],0
.snr:   call    selnc
        invoke  SelectObject,[memdc],[pen]
        mov     [old_pen],eax
        mov     [count],-1
.rainl: inc     [count]
        mov     ecx,[count]
        call    d_rain
        cmp     [count],NUM_RAIN
        jl      .rainl
        mov     [cloud_i],0
        invoke  SelectObject,[memdc],[old_pen]
.clloop:mov     ecx,[cloud_i]
        shl     ecx,1
        call    draw_cloud
        inc     [cloud_i]
        cmp     [cloud_i],CLOUDS
        jl      .clloop
        call    d_debug
        invoke  BitBlt,[hdc],10,10,BITMAP_WIDTH,0xff,[memdc],0,0,SRCCOPY
        invoke  DeleteObject,[bmp]
        invoke  DeleteDC,[memdc]
        invoke  EndPaint,[hwnd],ps
        jmp     .exit
.close: invoke  EndDialog,[hwnddlg],0
.exit:  mov     eax,1
.finish:pop     edi esi ebx
        ret
endp

d_rain: mov     edx,ecx                     ; 8 bit index
        shl     ecx,1                       ; 16 bit index
        mov     al,byte[rain_a+edx]
        cmp     al,1
        jne     .exit
        cmp     word[rain_y+ecx],180        ; reset when out of frame
        jl      .ok
        mov     byte[rain_a+edx],0
        jmp     .exit
.ok:    mov     esi,ecx
        movzx   eax,word[rain_x+ecx]
        movzx   ebx,word[rain_y+ecx]
        invoke  MoveToEx,[memdc],eax,ebx,0

        mov     ecx,esi
        movzx   eax,word[rain_x+ecx]
        movzx   ebx,word[rain_y+ecx]
        invoke  MoveToEx,[memdc],eax,ebx,0

        mov     ecx,esi
        mov     ax,word[rain_x+ecx]         ; load & update x
        add     ax,1
        mov     word[rain_x+ecx],ax
        cmp     ax,0
        jle     .exit                      ; no drawing until > 0
        add     ax,3                        ; x2
        mov     bx,word[rain_y+ecx]         ; load & update y
        add     bx,1
        mov     word[rain_y+ecx],bx
        add     bx,10                       ; y2
        movzx   eax,ax
        movzx   ebx,bx
        invoke  LineTo,[memdc],eax,ebx
 .exit: ret

d_debug:cmp     [KEY_DOWN_W],TRUE
        jne     .nw
        invoke  TextOutA,[memdc],5,10,debug_text_w,9
.nw:    cmp     [KEY_DOWN_A],TRUE
        jne     .na
        invoke  TextOutA,[memdc],5,30,debug_text_a,9
.na:    cmp     [KEY_DOWN_S],TRUE
        jne     .ns
        invoke  TextOutA,[memdc],5,50,debug_text_s,9
.ns:    cmp     [KEY_DOWN_D],TRUE
        jne     .nd
        invoke  TextOutA,[memdc],5,70,debug_text_d,9
.nd:   
.exit:  
        ret

selnc:  mov     eax,[cloud_s]
.select:inc     [cloud_s]
        cmp     [cloud_s],CLOUDS
        jle     .nr
        mov     [cloud_s],0
.nr:    ret

sp_rain:mov     [count],-1
.f_rain:inc     [count]
        mov     eax,[count]
        mov     edx,eax                     ; edx 8 bit index
        shl     eax,1                       ; eax 16 bit index
        cmp     byte[rain_a+edx],0
        jne     .f_rain
        mov     ebx,[cloud_s]               ; selected cloud index
        shl     ebx,1
        mov     cx,word[cloud_x+ebx]        ; load cloud x
        sub     cx,10
        mov     word[rain_x+eax],cx         ; store into rain x
        mov     cx,word[cloud_y+ebx]        ; load cloud y
        add     cx,5
        mov     word[rain_y+eax],cx         ; store into rain y
        mov     byte[rain_a+edx],1          ; set index active
        ret

draw_cloud:
        mov     ax,word[cloud_x+ecx]        ; load x into eax
        add     ax,2                        ; add 1
        cmp     ax,420
        jl      .no_x_reset
        mov     ax,word 0
 .no_x_reset:
        mov     word[cloud_x+ecx],ax        ; store updated x
        cmp     ax,0
        jle      .exit                       ; no drawing until > 0
        add     ax,40                       ; x2
        mov     bx,word[cloud_y+ecx]        ; load y into ebx
        add     bx,20                       ; y2
        movzx   eax,ax
        sub     eax,40
        movzx   ebx,bx
        movzx   edx,word[cloud_x+ecx]
        sub     edx,40
        movzx   esi,word[cloud_y+ecx]
        invoke  Ellipse,[memdc],edx,esi,eax,ebx
.exit:
        ret

 .end start

 section '.rsrc' resource data readable

 directory RT_DIALOG,dialogs
 resource dialogs,123,LANG_ENGLISH+SUBLANG_DEFAULT,demonstration

 dialog demonstration, 'Raining Clouds'        ,350,350,250,170,     WS_CAPTION+WS_POPUP+WS_SYSMENU+DS_MODALFRAME
  ;dialogitem 'STATIC','0'            ,ID_TEXT  ,80,83,120,15,        WS_VISIBLE+WS_CHILD
 enddialog
