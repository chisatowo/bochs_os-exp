	%include "boot.inc"
	section loader vstart=LOADER_BASE_ADDR
	LOADER_STACK_TOP equ LOADER_BASE_ADDR
	jmp loader_start

; 构建GDT及其内部描述符
	GDT_BASE: dd 0x00000000
				dd 0x00000000
	CODE_DESC: dd 0x0000FFFF
				dd DESC_CODE_HIGH4
	DATA_STACK_DESC: dd 0x0000FFFF
						dd DESC_DATA_HIGH4
	VIDEO_DESC: dd 0x80000007	; segment limit=(0xbffff-0xb8000)/4k
				dd DESC_VIDEO_HIGH4 ; 此时dpl为0

	GDT_SIZE equ $ - GDT_BASE	; 这行到GDT_BASE的标签就是目前整个GDT的大小
	GDT_LIMIT equ GDT_SIZE -1	
	times 60 dq 0				; 此处预留60个描述符的空位
	SELECTOR_CODE equ (0x0001<<3)	+ TI_GDT + RPL0
	SELECTOR_DATA equ (0x0002<<3)	+ TI_GDT + RPL0
	SELECTOR_VIDEO equ (0x0003<<3)	+ TI_GDT + RPL0

	; 以下是GDT的指针,前2字节是GDT界限,后4字节是GDT起始地址

	gdt_ptr dw GDT_LIMIT 
			dd GDT_BASE

	loadermsg db '2 loader in real.'
loader_start:
	mov ax,0
	mov ds,ax
	mov es,ax
	mov si,0
	mov cx,17
	mov bx,loadermsg
	call cp_msg

; ---------------------- 准备进入保护模式 ------------------------
; 1. 打开A20
; 2. 加载GDT
; 3. 将cr0的pe位置1

	; ------------- 打开A20 --------------
	in al,0x92
	or al,0000_0010b
	out 0x92,al
	; ------------- 加载GDT --------------
	lgdt [gdt_ptr]

	; ---- cr0第0位置1，开启保护模式-------
	mov eax,cr0
	or eax,0x00000001
	mov cr0,eax

	jmp dword SELECTOR_CODE:p_mode_start	; 刷新流水线


[bits 32]	; 声明接下来的代码在32位模式下执行
p_mode_start:
	mov ax,SELECTOR_DATA
	mov ds,ax	; 赋值段寄存器
	mov es,ax
	mov ss,ax
	mov esp,LOADER_STACK_TOP	; 令栈指针寄存器以当前LOADER所在基地址作栈顶,栈向下扩展
	mov ax,SELECTOR_VIDEO		; 将视频段选择子赋值到gs寄存器,视频段主要是内存中0xb8000~0xbffff的部分也即VGA文本模式部分
	mov gs,ax
	mov byte [gs:160],'P'		; 此处就是通过保护模式的分段基址来访问内存了
	jmp $

; BUG1: 这里必须要加上[bits 16],因为这里还没进入保护模式,但是前面又有[bits32]说明,所以最后会导致此处的编译处理错误
[bits 16]
cp_msg:
	mov byte al,[bx]
	mov byte [gs:si],al
	mov byte [gs:si+1],0x94
	add si,2
	add bx,1
	loop cp_msg
	ret
