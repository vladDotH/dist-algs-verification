spin -a model.pml
gcc -DMEMLIM=8192 -DNFAIR=3 -O2 -w -o model.exe pan.c
del pan.*