spin -a model.pml
gcc -DMEMLIM=1024 -O2 -w -o model.exe pan.c
del pan.*