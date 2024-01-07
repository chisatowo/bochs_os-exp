; 主引导记录MBR
;
%include "boot.inc"
;LOADER_BASE_ADDR equ 0xA000
;LOADER_START_SECTOR equ 0x2
; ---------------------------------------------
SECTION MBR vstart=0x7c00	; 指定mbr在链接后的重定位地址为0x7c00(只负责为程序编址即当前程序中所有代码的基地址都从0x7c00开始,不负责加载)
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov ss,ax
	mov fs,ax
	mov sp,0x7c00
	mov ax,0xb800	; VGA文本模式显存地址
	mov gs,ax		; gs为内存段寄存器,专门用来对内存进行操作

; 清屏利用功能 0x06,上卷全部行
; INT 0x10 功能号:0x06 功能描述:上卷窗口
; AH 功能号=0x06
; AL = 上卷的行数(如果为0,则表示全部)
; BH = 上卷行属性
; (CL,CH) = 窗口左上角的(X,Y)位置
; (DL,DH) = 窗口右下角的(X,Y)位置
; 无返回值.
	mov ax, 0x600
	mov bx, 0x700
	mov cx, 0x0		; 左上角: (0,0)
	mov dx, 0x184f	; 右下角: (80,25)
					; VGA文本模式中一行最多80个字符,共25行
					; 下标从0开始,故有24行=0x18, 79个字符=0x4f
	int 0x10		; 呼叫INT中断

;----------- 下面这三行代码获取光标位置 ----------
; .get_cursor获取当前光标位置,在光标位置处打印字符
	mov ah, 3 		; 输入: 3号子功能
	mov bh, 0		; 输入: bh寄存器放入待获取光标的页号
	int 0x10		; 呼叫INT中断
					; 输出: (CH,CL)存放的是光标的起始行与终止行
					; 输出: (DH,DL)存放的是光标的行和列(即Y坐标与X坐标)

;;---------------- 打印字符串 ---------------------
;; INT 0x10 功能号: 0x13 功能描述: 在Teletype模式下显示字符串
	;mov ax, message 
	;mov bp, ax		; es:bp 为字符串首地址,es此时同cs一致
					;; 在文件开头已经为sreg初始化
	;mov cx, 5		; 输入: cx放入串长度,不包括结束符0的字符个数
	;mov ax, 0x1301	; 输入: ah放入功能号0x13 al设置写字符方式 al=0x1: 显示字符串,光标跟随移动
	;mov bx, 0x2		; 输入: bh放入要显示的页号 bl设置字符属性,黑底绿字(bl = 02h)
	;int 0x10		; 呼叫INT中断

;--------------- 操纵显存打印字符串 -----------
; 获取光标所在位置,并将位置转换为字节形式存储到cx寄存器
	mov bx,dx	; 将前面获取的光标位置取出
	mov ax,2	; 一个字符两个字节
	mul bl		; 先求列的字节数,ax与bl相乘,结果值存入ax
	mov si,0	; 由于后面需要用到变址寻址,而实模式下的变址寄存器只能是si,di
	add si,ax	; 累加列字节数
	mov ax,160	; 再求行字节数,一行80个字符,一个字符两个字节
	mul bh
	add si,ax	; 累加行字节数
	
	mov byte [gs:si],'1'		; 在VGA文本模式中,高字节代表字符本身
	mov byte [gs:si+0x1],0x94		; 低字节代表字符属性,此处9代表背景蓝色闪烁,4代表前景色为红色

	mov byte [gs:si+0x2],' '
	mov byte [gs:si+0x3],0x94

	mov byte [gs:si+0x4],'M'
	mov byte [gs:si+0x5],0x94

	mov byte [gs:si+0x6],'B'
	mov byte [gs:si+0x7],0x94

	mov byte [gs:si+0x8],'R'
	mov byte [gs:si+0x9],0x94

;-------------- 准备读取硬盘扇区 ----------------
 	mov eax,LOADER_START_SECTOR		; 起始扇区lba地址
	mov bx,LOADER_BASE_ADDR			; 读入LOADER的地址
	mov cx,1						; 待读取的扇区数
	call rd_disk_m_16				; 调用函数读入LOADER

	jmp LOADER_BASE_ADDR			; 读取完成后,跳转到LOADER所在的地址,执行内核加载并初始化

;-------------- 读取硬盘n个扇区 ------------------
rd_disk_m_16:

; eax=LBA扇区号
; bx=将要读取LOADER的地址
; cx=将要读入的扇区数
	mov esi,eax	;备份eax
	mov di,cx	;备份cx
; 读取硬盘:
; 1. 设置要读取的扇区数:
	mov dx,0x1f2
	mov al,cl
	out dx,al	;读取的扇区数
	mov eax,esi ;恢复eax的值

; 2. 将LBA地址存入0x1f3~0x1f6
	; LBA地址7~0位写入端口0x1f3
	mov dx,0x1f3
	out dx,al

	; LBA地址15~8位写入端口0x1f4
	mov cl,8
	shr eax,cl	; 将eax的值右移8位

	; LBA地址23~16位写入端口0x1f5
	shr eax,cl
	mov dx,0x1f5
	out dx,al

	shr eax,cl
	and al,0x0f	; 获取LBA第24~27位
	or al,0xe0	; 将第7~4位设置为1110,表示LBA模式
	mov dx,0x1f6
	out dx,al

; 3. 向0x1f7端口写入读命令,0x20
	mov dx,0x1f7
	mov al,0x20
	out dx,al

; 4. 检测硬盘状态
.not_ready:
	; 同一端口,out表示写入命令,in表示读入硬盘状态
	nop
	in al,dx
	and al,0x88	; 第3位为1表示硬盘控制器准备就绪,第7位为1表示硬盘忙
	cmp al,0x08
	jnz .not_ready	; 第3位不为1说明未准备好,则进入循环

; 5. 从0x1f0端口读取数据
	mov ax,di	; di为要读取的扇区数,每次读入一个字(即两个字节)共需di*256次
	mov dx,256
	mul dx
	mov cx,ax
	mov dx,0x1f0

.go_on_read:
	in ax,dx
	mov [bx],ax
	add bx,2
	loop .go_on_read	; loop循环次数以cx寄存器中的值为准,每次loop时cx的值-1，不为0则跳转
	ret
	
	;message db "1 MBR" ; 在此处内存定义变量,存储待打印字符串
	times 510-($-$$) db 0	; 填充剩余字节,确保MBR将磁盘第一扇区占满即512字节
	db 0x55,0xaa 	; MBR魔数





