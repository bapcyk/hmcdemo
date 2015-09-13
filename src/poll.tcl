# $C - loop count; $A - axis
set dir c:/prj/hmcdemo/src
saver listen -on
saver configure -dir $dir
serial open 4
sensor set_freq 10
sensor poll -loop $C
serial close
file rename -force [saver cget -name] $dir/$A.csv
exit 0
