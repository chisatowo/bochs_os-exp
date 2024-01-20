;------------ loader & kernel ------------

LOADER_BASE_ADDR equ 0x900
LOADER_START_SECTOR equ 0x2

;------------ gdt描述符属性 --------------
DESC_G_4K equ 1_00000000000000000000000b	; 设置字段G表示段描述符步长为4K
DESC_D_32 equ  1_0000000000000000000000b	; 设置字段D表示默认段大小为32位
DESC_L	  equ   0_000000000000000000000b	; 字段L主要用来设置是否启动64位段大小(仅限IA32_e模式,即64位操作系统)
DESC_AVL  equ	 0_00000000000000000000b	; 字段AVL设置段描述符所指向段能否为CPU所用
DESC_LIMIT_CODE2 equ 1111_0000000000000000b ; 段限制字段19:16位
DESC_LIMIT_DATA2 equ DESC_LIMIT_CODE2		
; 疑点: 此处VIDEO段的处理是否少了个0
DESC_LIMIT_VIDEO2 equ 0000_0000000000000000b
DESC_P equ 1_000000000000000b				; 存在位
DESC_DPL_0 equ 00_0000000000000b			; DPL代表段描述符的特权级,0级为系统级
DESC_DPL_1 equ 01_0000000000000b			
DESC_DPL_2 equ 10_0000000000000b
DESC_DPL_3 equ 11_0000000000000b
DESC_S_CODE equ 1_000000000000b				; 字段S代表当前段描述符为系统描述符还是数据段描述符/代码段描述符
DESC_S_DATA equ DESC_S_CODE
DESC_S_SYS equ 0_000000000000b
DESC_TYPE_CODE equ 1000_00000000b			; 字段TYPE由四个位组成:
; x=1,c=0,r=0,a=0 表示代码段可执行,忽视描述符优先级,不可读,已访问位a为0
DESC_TYPE_DATA equ 0010_00000000b
; x=0,e=0,w=1,a=0 表示数据段不可执行,数据段向上扩展(为1则栈段向下扩展),可写,已访问位a清0

; 代码段描述符高4字节
DESC_CODE_HIGH4 equ (0x00 << 24) + DESC_G_4K + DESC_D_32 + DESC_L + DESC_AVL + DESC_LIMIT_CODE2 + DESC_P + DESC_DPL_0 + DESC_S_CODE + DESC_TYPE_CODE + 0x00
; 数据段描述符高4字节
DESC_DATA_HIGH4 equ (0x00 << 24) + DESC_G_4K + DESC_D_32 + DESC_L + DESC_AVL + DESC_LIMIT_DATA2 + DESC_P + DESC_DPL_0 + DESC_S_DATA + DESC_TYPE_DATA + 0x00
; 视频段描述符高4字节
DESC_VIDEO_HIGH4 equ (0x00 << 24) + DESC_G_4K + DESC_D_32 + DESC_L + DESC_AVL + DESC_LIMIT_VIDEO2 + DESC_P + DESC_DPL_0 + DESC_S_DATA + DESC_TYPE_DATA + 0x0b

;----------- 段选择子属性----------
RPL0 equ 00b	; RPL代表请求特权级,即当前程序所处特权级
RPL1 equ 01b
RPL2 equ 10b
RPL3 equ 11b
TI_GDT equ 000b	; TI代表当前段选择子要访问LDT还是GDT
TI_LDT equ 100b






