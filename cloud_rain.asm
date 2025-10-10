; Draw raining clouds

        format PE GUI 4.0
        include 'win32wx.inc'

        ID_TEXT         = 100
        ID_TEST         = 101

        NUM_CLOUDS      = 20
        RAIN_INTERVAL   = 8
        NUM_RAIN        = 30
.data
        hwnd            dd              ?
        hdc             dd              ?
        my_brush        dd              ?

        h_pen           dd              ?
        old_pen         dd              ?

        thread_handle   dd              ?
        thread_id       dd              1

        time_text       rb              0xFF
        rec             RECT            20,20,40,40
        rec_x           dd              15

        cloud_x         rb              4 * 50          ; reserve 50 dword
        cloud_y         rb              4 * 50          ; reserve 50 dword

        rain_x          rb              4 * 500
        rain_y          rb              4 * 500
        rain_a          rb              4 * 500
        rain_c          dd              0               ; next rain counter

        cloud_i         dd              0
        cloud_s         dd              0

        counter         dd              0
        paint_counter   dd              0
        random          dd              0

        paintstruct     PAINTSTRUCT

.code
;       START

start:
        mov     [counter], 0
 .init_rain:
        mov     eax,[counter]
        shl     eax, 2
        mov     dword [rain_a + eax], 0
        inc     [counter]
        cmp     [counter], 400
        jl      .init_rain
 .init_clouds:
; clouds x
        mov     dword [cloud_x + 0],  211
        mov     dword [cloud_x + 4],  60
        mov     dword [cloud_x + 8],  150
        mov     dword [cloud_x + 12], 197
        mov     dword [cloud_x + 16], 100
        mov     dword [cloud_x + 20], -100
        mov     dword [cloud_x + 24], -49
        mov     dword [cloud_x + 28], 29
        mov     dword [cloud_x + 32], 120
        mov     dword [cloud_x + 36], -20

; clouds y
        mov     dword [cloud_y + 0],  21 /2
        mov     dword [cloud_y + 4],  53 /2
        mov     dword [cloud_y + 8],  33 /2
        mov     dword [cloud_y + 12], 93 /2
        mov     dword [cloud_y + 16], 28 /2
        mov     dword [cloud_y + 20], 78 /2
        mov     dword [cloud_y + 24], 85 /2
        mov     dword [cloud_y + 28], 28 /2
        mov     dword [cloud_y + 32], 60 /2
        mov     dword [cloud_y + 36], 99 /2

        invoke  GetModuleHandle,0
        invoke  DialogBoxParam, eax, 123, HWND_DESKTOP, DialogProc, 0
        invoke  ExitProcess,0

proc DialogProc hwnddlg,msg,wparam,lparam
        push    ebx esi edi
        cmp     [msg], WM_INITDIALOG
        je      .wm_initdialog
        cmp     [msg], WM_COMMAND
        je      .wm_command
        cmp     [msg], WM_TIMER
        je      .wm_timer
        cmp     [msg], WM_PAINT
        je      .wm_paint
        cmp     [msg], WM_CLOSE
        je      .wm_close
        xor     eax, eax
        jmp     .finish
 .wm_command:
        jmp     .exit
 .wm_initdialog:
        mov     eax, [hwnddlg]
        mov     [hwnd], eax
        invoke  SetTimer, eax, 1, 50, NULL
        jmp     .exit
 .wm_timer:
        invoke  InvalidateRect, [hwnd], NULL, TRUE
        jmp     .exit
 .wm_paint:
        invoke  BeginPaint, [hwnd], paintstruct
        mov     [hdc], eax
        inc     [rain_c]                                ; next rain counter
        cmp     [rain_c], RAIN_INTERVAL
        jl      .snr
        stdcall spawn_rain
        mov     [rain_c], 0
 .snr:
        stdcall select_next_cloud                       ; select the next cloud to use
        ;0x00bbggrr
        invoke  CreatePen, PS_SOLID, 2, 0x00ff0000
        mov     [h_pen], eax
        mov     [cloud_i], 0
        invoke  SelectObject, [hdc], [h_pen]
        mov     [old_pen], eax
        mov     [counter], -1
 .rain_loop:
        inc     [counter]
        mov     ecx, [counter]
        shl     ecx, 2                                  ; ecx = i * 4
        stdcall draw_rain, ecx
        cmp     [counter], NUM_RAIN                     ; max rain active at the same time
        jl      .rain_loop
        invoke  SelectObject, [hdc], [old_pen]
 .clouds_loop:
        mov     ecx, [cloud_i]
        shl     ecx, 2                                  ; ecx = i * 4
        stdcall draw_cloud, ecx                         ; call draw_cloud(clouds[i])
        inc     [cloud_i]
        cmp     [cloud_i], NUM_CLOUDS
        jl      .clouds_loop

        ;stdcall update_paint_count
        invoke  EndPaint, [hwnd], paintstruct
        jmp     .exit
 .wm_close:
        invoke  TerminateThread, [thread_handle], 0
        invoke  EndDialog, [hwnddlg], 0
 .exit:
        mov     eax,1
 .finish:
        pop     edi esi ebx
        ret
endp

; args: index
draw_rain:
        push    ebp
        mov     ebp, esp
        mov     ecx, [ebp + 8]                          ; eax = index
        mov     eax, dword [rain_a + ecx]
        cmp     eax, 1
        jne     .exit
        cmp     dword [rain_y + ecx], 180               ; reset when out of frame
        jl      .ok
        mov     dword [rain_a + ecx], 0
        jmp     .exit
 .ok:
        mov     esi, ecx
        invoke  MoveToEx, [hdc], dword [rain_x + ecx], dword [rain_y + ecx], 0
        mov     ecx, esi
        invoke  MoveToEx, [hdc], dword [rain_x + ecx], dword [rain_y + ecx], 0
        mov     ecx, esi
        mov     eax, dword [rain_x + ecx]               ; load & update x
        add     eax, 1
        mov     dword [rain_x + ecx], eax
        add     eax, 2                                  ; x2
        mov     ebx, dword [rain_y + ecx]               ; load & update y
        add     ebx, 2
        mov     dword [rain_y + ecx], ebx
        add     ebx, 10                                 ; y2
        invoke  LineTo, [hdc], eax, ebx
 .exit:
        mov     esp, ebp
        pop     ebp
        ret     4

select_next_cloud:
        push    ebp
        mov     ebp, esp
        mov     eax, [cloud_s]
 .select:
        inc     [cloud_s]
        cmp     [cloud_s], 10
        jle      .nr
        mov     [cloud_s], 0
 .nr:
        mov     esp, ebp
        pop     ebp
        ret


; find an inactive rain location and activate
; at the selected cloud
spawn_rain:
        push    ebp
        mov     ebp, esp
        mov     [counter], -1
 .find_rain:
        inc     [counter]
        mov     eax, [counter]
        shl     eax, 2
        cmp     dword [rain_a + eax], 0
        jne     .find_rain
        mov     ebx, [cloud_s]                          ; selected cloud index
        shl     ebx, 2
        mov     ecx, dword [cloud_x + ebx]              ; selected cloud x
        add     ecx, 30
        mov     dword [rain_x + eax], ecx               ; store in rain x
        mov     ecx, dword [cloud_y + ebx]              ; selected cloud y
        add     ecx, 5                                  ; a little under the cloud
        mov     dword [rain_y + eax], ecx               ; store in rain y
        mov     dword [rain_a + eax], 1                 ; set active
        mov     esp, ebp
        pop     ebp
        ret

; args: index
draw_cloud:
        push    ebp
        mov     ebp, esp
        mov     ecx, [ebp + 8]                          ; eax = index
        mov     eax, dword [cloud_x + ecx]              ; load x into eax
        add     eax, 2                                  ; add 1
        cmp     eax, 300
        jl      .no_x_reset
        mov     eax, -40
 .no_x_reset:
        mov     dword [cloud_x + ecx], eax              ; store updated x
        add     eax, 40                                 ; x2
        mov     ebx, dword [cloud_y + ecx]              ; load y into ebx
        add     ebx, 20                                 ; y2
        invoke  Ellipse, [hdc], dword [cloud_x + ecx], dword [cloud_y + ecx], eax, ebx
        mov     esp, ebp
        pop     ebp
        ret     4

update_paint_count:
        push    ebp
        mov     ebp,esp
        inc     [paint_counter]
        invoke  wsprintf, time_text, 'paint messages: %i', [paint_counter]
        invoke  GetDlgItem, [hwnd], ID_TEXT
        invoke  SetWindowText, eax, time_text
        mov     esp,ebp
        pop     ebp
        ret

 .end start

section '.rsrc' resource data readable

 directory RT_DIALOG,dialogs
 resource dialogs,123,LANG_ENGLISH+SUBLANG_DEFAULT,demonstration

 dialog demonstration, 'Raining Clouds'        ,350,350,200,100,     WS_CAPTION+WS_POPUP+WS_SYSMENU+DS_MODALFRAME
  ;dialogitem 'STATIC','0'            ,ID_TEXT  ,80,83,120,15,        WS_VISIBLE+WS_CHILD
 enddialog
