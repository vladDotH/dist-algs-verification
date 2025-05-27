spin -a -X model.pml
gcc -DMEMLIM=1024 -O2 -DXUSAFE -w -o model.exe pan.c
del pan.*