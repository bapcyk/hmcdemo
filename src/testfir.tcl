load lib/mym
set ORD 5

Clpfir lf $ORD 10 2 1 1
puts "Low-Pass FIR"
puts "------------"
puts "H:"
set h [lf cget -h]
puts "\t[join $h \n\t]"
puts "Response:"
set res {}
for {set i 0} {$i<[expr 2*$ORD]} {incr i} {
    set v [lf filter [expr $i==$ORD]]
    lappend res $v
    puts "\t$v"
}
set rng1 [lrange $h 0 [expr $ORD-1]]
set rng2 [lrange $res $ORD end]
if {$rng1 eq $rng2} {
    puts "Result: test passed."
} else {
    puts "Result: test faulted!"
}

puts ""

Chpfir hf $ORD 10 1 1 1
puts "High-Pass FIR"
puts "-------------"
puts "H:"
set h [hf cget -h]
puts "\t[join $h \n\t]"
puts "Response:"
set res {}
for {set i 0} {$i<[expr 2*$ORD]} {incr i} {
    set v [hf filter [expr $i==$ORD]]
    lappend res $v
    puts "\t$v"
}
set rng1 [lrange $h 0 [expr $ORD-1]]
set rng2 [lrange $res $ORD end]
if {$rng1 eq $rng2} {
    puts "Result: test passed."
} else {
    puts "Result: test faulted!"
}

puts ""

Cbpfir bf $ORD 10 1 4 1 1
puts "Band-Pass FIR"
puts "-------------"
puts "H:"
set h [bf cget -h]
puts "\t[join $h \n\t]"
puts "Response:"
set res {}
for {set i 0} {$i<[expr 2*$ORD]} {incr i} {
    set v [bf filter [expr $i==$ORD]]
    lappend res $v
    puts "\t$v"
}
set rng1 [lrange $h 0 [expr $ORD-1]]
set rng2 [lrange $res $ORD end]
if {$rng1 eq $rng2} {
    puts "Result: test passed."
} else {
    puts "Result: test faulted!"
}
