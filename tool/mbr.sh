nasm -o ~/Desktop/bochs_os-exp/boot/mbr.bin ~/Desktop/bochs_os-exp/boot/mbr.S
dd if=/home/haoyu/Desktop/bochs_os-exp/boot/mbr.bin of=/home/haoyu/桌面/bochs/hd60M.img bs=512 count=1 conv=notrunc
