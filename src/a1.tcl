Hpfir hpf
hpf configure -datatype flt -datatypes {phys}
hpf chconfigure 3 4 5 -fs 10 -ord 20 -f1 2
Saver saver1
saver1 listen -on
saver listen -on
listen phvals:hpf
listen hpf:saver1
serial open 4
sensor poll -loop
