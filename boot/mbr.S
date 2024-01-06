; 主引导记录MBR
;
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

;-------------- 打印字符串结束 -------------------
	jmp $			; 使程序悬停
	
	;message db "1 MBR" ; 在此处内存定义变量,存储待打印字符串
	times 510-($-$$) db 0	; 填充剩余字节,确保MBR将磁盘第一扇区占满即512字节
	db 0x55,0xaa 	; MBR魔数





