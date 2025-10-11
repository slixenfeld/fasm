; Draw raining clouds

        format PE GUI 4.0
        include 'win32wx.inc'

        ID_TEXT         = 100
        ID_TEST         = 101

        NUM_CLOUDS      = 10 ; cannot be changed
        RAIN_INTERVAL   = 10
        NUM_RAIN        = 30

.data
        hwnd            dd              ?
        hdc             dd              ?
        my_brush        dd              ?
        h_pen           dd              ?
        old_pen         dd              ?

        cloud_x         rb              2 * (NUM_CLOUDS+1)              ; reserve 50 word
        cloud_y         rb              2 * (NUM_CLOUDS+1)              ; reserve 50 word

        rain_x          rb              2 * (NUM_RAIN+1)
        rain_y          rb              2 * (NUM_RAIN+1)
        rain_a          rb              1 * (NUM_RAIN+1)
        rain_c          dd              0                               ; next rain counter

        cloud_i         dd              0
        cloud_s         dd              0                               ; selected cloud

        paint_counter   dd              0
        random          dd              0
        count           dd              0                               ; generic counter

        paintstruct     PAINTSTRUCT

.code
;       START

start:
        mov     ebx, 0
 .init_rain:
        mov     eax,ebx
        mov     byte [rain_a+eax],0
        inc     ebx
        cmp     ebx,NUM_RAIN
        jl      .init_rain
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

        invoke  GetModuleHandle,0
        invoke  DialogBoxParam,eax,123,HWND_DESKTOP,DialogProc,0
        invoke  ExitProcess,0

proc DialogProc hwnddlg,msg,wparam,lparam
        push    ebx esi edi
        cmp     [msg],WM_INITDIALOG
        je      .wm_initdialog
        cmp     [msg],WM_COMMAND
        je      .wm_command
        cmp     [msg],WM_TIMER
        je      .wm_timer
        cmp     [msg],WM_PAINT
        je      .wm_paint
        cmp     [msg],WM_CLOSE
        je      .wm_close
        xor     eax, eax
        jmp     .finish
 .wm_command:
        jmp     .exit
 .wm_initdialog:
        mov     eax,[hwnddlg]
        mov     [hwnd],eax
        invoke  SetTimer,eax,1,50,NULL
        jmp     .exit
 .wm_timer:
        invoke  InvalidateRect,[hwnd],NULL,1
        jmp     .exit
 .wm_paint:
        invoke  BeginPaint,[hwnd],paintstruct
        mov     [hdc],eax

        inc     [rain_c]
        cmp     [rain_c],RAIN_INTERVAL
        jl      .snr
        stdcall spawn_rain
        mov     [rain_c],0
 .snr:
        stdcall select_next_cloud
        ; 0x00bbggrr
        invoke  CreatePen,PS_SOLID,2,0x00ff0000
        mov     [h_pen],eax
        invoke  SelectObject,[hdc],[h_pen]
        mov     [old_pen],eax
        mov     [count],-1
 .rain_loop:
        inc     [count]
        mov     ecx,[count]
        stdcall draw_rain,ecx
        cmp     [count],NUM_RAIN
        jl      .rain_loop
        mov     [cloud_i],0
        invoke  SelectObject,[hdc],[old_pen]
 .clouds_loop:
        mov     ecx,[cloud_i]
        shl     ecx,1
        stdcall draw_cloud,ecx
        inc     [cloud_i]
        cmp     [cloud_i],NUM_CLOUDS
        jl      .clouds_loop
        ; stdcall update_paint_count
        invoke  EndPaint,[hwnd],paintstruct
        jmp     .exit
 .wm_close:
        invoke  EndDialog,[hwnddlg],0
 .exit:
        mov     eax,1
 .finish:
        pop     edi esi ebx
        ret
endp

; args: index
draw_rain:
        push    ebp
        mov     ebp,esp
        mov     ecx,[ebp+8]
        mov     edx,ecx                ; 8 bit index
        shl     ecx,1                  ; 16 bit index
        mov     al,byte[rain_a+edx]
        cmp     al,1
        jne     .exit
        cmp     word[rain_y+ecx],180   ; reset when out of frame
        jl      .ok
        mov     byte[rain_a+edx],0
        jmp     .exit
 .ok:
        mov     esi,ecx
        movzx   eax,word[rain_x+ecx]
        movzx   ebx,word[rain_y+ecx]
        invoke  MoveToEx,[hdc],eax,ebx,0

        mov     ecx,esi
        movzx   eax,word[rain_x+ecx]
        movzx   ebx,word[rain_y+ecx]
        invoke  MoveToEx,[hdc],eax,ebx,0

        mov     ecx,esi
        mov     ax,word[rain_x+ecx]    ; load & update x
        add     ax,1
        mov     word[rain_x+ecx],ax
        add     ax,3                   ; x2
        mov     bx,word[rain_y+ecx]    ; load & update y
        add     bx,1
        mov     word[rain_y+ecx],bx
        add     bx,10                  ; y2

        movzx   eax,ax
        movzx   ebx,bx

        invoke  LineTo,[hdc],eax,ebx
 .exit:
        mov     esp,ebp
        pop     ebp
        ret     4

select_next_cloud:
        push    ebp
        mov     ebp,esp
        mov     eax,[cloud_s]
 .select:
        inc     [cloud_s]
        cmp     [cloud_s],NUM_CLOUDS
        jle     .nr
        mov     [cloud_s],0
 .nr:
        mov     esp,ebp
        pop     ebp
        ret
; find an inactive rain location and activate
; at the selected cloud
spawn_rain:
        push    ebp
        mov     ebp,esp
        mov     [count],-1
 .find_rain:
        inc     [count]
        mov     eax,[count]
        mov     edx,eax                 ; edx 8 bit index
        shl     eax,1                   ; eax 16 bit index
        cmp     byte[rain_a+edx],0
        jne     .find_rain
        mov     ebx,[cloud_s]           ; selected cloud index
        shl     ebx,1
        mov     cx,word[cloud_x+ebx]    ; load cloud x
        sub     cx,10
        mov     word[rain_x+eax],cx     ; store into rain x
        mov     cx,word[cloud_y+ebx]    ; load cloud y
        add     cx,5
        mov     word[rain_y+eax],cx     ; store into rain y
        mov     byte[rain_a+edx],1      ; set index active
        mov     esp,ebp
        pop     ebp
        ret

; args: index
draw_cloud:
        push    ebp
        mov     ebp,esp
        mov     ecx,[ebp+8]             ; eax = index
        mov     ax,word[cloud_x+ecx]    ; load x into eax
        add     ax,2                    ; add 1
        cmp     ax,340
        jl      .no_x_reset
        mov     ax,word 0
 .no_x_reset:
        mov     word[cloud_x+ecx],ax    ; store updated x
        add     ax,40                   ; x2
        mov     bx,word[cloud_y+ecx]    ; load y into ebx
        add     bx,20                   ; y2
        movzx   eax,ax
        sub     eax,40
        movzx   ebx,bx
        movzx   edx,word[cloud_x+ecx]
        sub     edx,40
        movzx   esi,word[cloud_y+ecx]
        invoke  Ellipse,[hdc],edx,esi,eax,ebx
        mov     esp,ebp
        pop     ebp
        ret     4

;update_paint_count:
;        push    ebp
;        mov     ebp,esp
;        inc     [paint_counter]
;        invoke  wsprintf,time_text,'paint messages: %i',[paint_counter]
;        invoke  GetDlgItem,[hwnd],ID_TEXT
;        invoke  SetWindowText,eax,time_text
;        mov     esp,ebp
;        pop     ebp
;        ret

 .end start

section '.rsrc' resource data readable

 directory RT_DIALOG,dialogs
 resource dialogs,123,LANG_ENGLISH+SUBLANG_DEFAULT,demonstration

 dialog demonstration, 'Raining Clouds'        ,350,350,200,100,     WS_CAPTION+WS_POPUP+WS_SYSMENU+DS_MODALFRAME
  ;dialogitem 'STATIC','0'            ,ID_TEXT  ,80,83,120,15,        WS_VISIBLE+WS_CHILD
 enddialog
