spin -a model.pml
gcc -DMEMLIM=4096 -DNFAIR=3 -O2 -w -o model.exe pan.c
del pan.*