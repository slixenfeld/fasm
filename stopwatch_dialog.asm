; Stopwatch Dialog

format PE GUI 4.0

include 'win32wx.inc'

	ID_STATIC= 50
	ID_START = 200
	ID_STOP  = 201

	ID_TIMER = 1
.data

; handle
	hwnd	       dd	?

; timer
	timer_text     rb	0xFF
	second	       dd	0
	minute	       dd	0
	hour	       dd	0

; thread
	threadID       dd	1
	threadHandle   dd	0
.code

start:
		invoke	GetModuleHandle,0
		invoke	DialogBoxParam,eax,123,HWND_DESKTOP,DialogProc,0
		invoke	ExitProcess,0
ThreadProc:
		push	ebp
		mov	ebp,esp
		mov	[second],-1
		mov	[minute],0
		mov	[hour],0
  .loop:
		inc	[second]
		cmp	[second],60
		jne	.skip
		mov	[second],0
		inc	[minute]
		cmp	[minute],60
		jne	.skip
		mov	[minute],0
		inc	[hour]
  .skip:
		invoke	wsprintf,timer_text,'%02i:%02i:%02i',[hour],[minute],[second]
		invoke	GetDlgItem,[hwnd],ID_STATIC
		invoke	SetWindowText,eax,timer_text

		invoke	Sleep,1000
		jmp	.loop

		mov	esp,ebp
		pop	ebp
		ret

proc DialogProc hwnddlg,msg,wparam,lparam
		push	ebx esi edi

		cmp	[msg],WM_INITDIALOG
		je	.wminitdialog
		cmp	[msg],WM_COMMAND
		je	.wmcommand
		cmp	[msg],WM_CLOSE
		je	.wmclose

		xor	eax,eax
		jmp	.finish
  .wmcommand:
		cmp	[wparam],BN_CLICKED shl 16 + ID_START
		je	.f_start
		cmp	[wparam],BN_CLICKED shl 16 + ID_STOP
		je	.f_stop
		jmp	.exit
  .f_start:
		invoke	TerminateThread,[threadHandle],0
		invoke	CreateThread,0,0,ThreadProc,0,0,threadID
		mov	[threadHandle],eax
		jmp	.exit
  .f_stop:
		invoke	TerminateThread,[threadHandle],0
		jmp	.exit
  .wminitdialog:
		mov	eax,[hwnddlg]
		mov	[hwnd],eax
		jmp	.exit
  .wmclose:
		invoke	EndDialog,[hwnddlg],0
  .exit:
		mov	eax,1
  .finish:
		pop	edi esi ebx
		ret
endp

.end start

section '.rsrc' resource data readable

    directory RT_DIALOG,dialogs
    resource dialogs,123,LANG_ENGLISH+SUBLANG_DEFAULT,demonstration

    dialog demonstration,   'Stopwatch' 	  ,250,250,130,50,	WS_CAPTION+WS_POPUP+WS_SYSMENU+DS_MODALFRAME
	dialogitem 'STATIC','00:00:00',ID_STATIC  ,48,10,120,15,	WS_VISIBLE+WS_CHILD
	dialogitem 'BUTTON','Start'   ,ID_START   ,5,30,50,15,		WS_VISIBLE+WS_TABSTOP+BS_DEFPUSHBUTTON
	dialogitem 'BUTTON','Stop'    ,ID_STOP	  ,70,30,50,15, 	WS_VISIBLE+WS_TABSTOP+BS_DEFPUSHBUTTON
    enddialog