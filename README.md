# bochs_os-exp
基于操作系统真象还原在bochs虚拟机上搭建的x86体系结构下的迷你仿Linux操作系统.
## 第二章:编写MBR主引导记录
1. 编写MBR,调用BIOS中断0x10实现清屏和打印字符串.
2. 将编译后的MBR,通过dd命令放入虚拟磁盘hd60M.img中的第一扇区(安全起见,MBR需要占满512字节).
## 第三章:改进MBR主引导记录
1. 修改MBR,从调用BIOS中断打印字符串改为直接对VGA文本模式显存(基地址为0xb800)进行操作,打印字符串.
2. 修改MBR,通过I/O端口(LBA模式:0x1f0~0x1f7)对磁盘进行读取操作(目前只读1扇区),将位于磁盘第2扇区的LOADER程序调入内存0x900中.
3. 添加LOADER程序,打印跳动字符串"2 LOADER".
4. 需要注意的是,主引导记录MBR是由BIOS主动从磁盘第1扇区读取到指定内存0x7c00的位置的,这部分内容是BIOS程序写死的,但是加载器LOADER需要我们主动从磁盘中读取到指定地址,0x900这个地址是作者选定的.
