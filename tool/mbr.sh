nasm -I ~/Desktop/bochos/boot/include -o ~/Desktop/bochos/boot/mbr.bin ~/Desktop/bochos/boot/mbr.S
nasm -I ~/Desktop/bochos/boot/include -o ~/Desktop/bochos/boot/loader.bin ~/Desktop/bochos/boot/loader.S
dd if=/home/haoyu/Desktop/bochos/boot/mbr.bin of=/home/haoyu/桌面/bochs/hd60M.img bs=512 count=1 conv=notrunc
dd if=/home/haoyu/Desktop/bochos/boot/loader.bin of=/home/haoyu/桌面/bochs/hd60M.img bs=512 count=1 seek=2 conv=notrunc
# count表示要读取的块数,bs表示一个块的大小,seek表示要跳过的块数(由于此处loader是第2扇区,所以跳过两个块),conv指定如何转换文件,notrunc表示不打断文件.
