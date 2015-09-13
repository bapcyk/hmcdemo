package provide myutl 1.0
namespace eval ::myutl {}

proc myutl::kit_path {p} {
    set ret [file join $starkit::topdir $p]
    return [file normalize $ret]
}

proc myutl::or args {
    foreach a $args {
        if {$a!=0 && $a!=""} {
            return $a
        }
    }
    return $a
}

#proc myutl::isint {x} {
#    return [expr {![catch {expr {int($x)}}]}]
#}

# like getopt for proc/method, ex:
#   set args {}; # positional args
#   array set kw {-a 1 -b 2}; # default kw-args
#   set inputArgs {-a 20 -c 30 zzz -q -v xxx yyy}
#   myutl::proc_opts args kw $inputArgs
#   puts "Args:\n $args"
#   puts "KW Args:"
#   foreach {k v} [array get kw] {
#       puts " $k = $v"
#   }
#
# 1) argsName may be ""|{} - to avoid positional args saving
# 2) if no value of keyword argument, then it's value will be "Y"
proc myutl::proc_opts {argsName kwArgsName argsList} {
    proc isKw opt {
        return [expr {"-" eq [string index $opt 0]}]
    }

    set kw ""
    set state OPT; # OPT|VAL|END
    lappend argsList ""
    foreach opt $argsList {
        switch -- $state {
            OPT {
                if {$opt eq ""} {
                    set state END
                } elseif {[isKw $opt]} {
                    set kw $opt
                    set state VAL
                } else {
                    # save to positional args only if argsName is set
                    if {$argsName ne ""} { uplevel "lappend $argsName \"$opt\""; }
                }
            }

            VAL {
                if {$opt eq ""} {
                    if {$kw ne ""} {
                        uplevel "set $kwArgsName\($kw\) Y"
                    }
                    set state END
                } elseif {[isKw $opt]} {
                    uplevel "set $kwArgsName\($kw\) Y"
                    set kw $opt
                } else {
                    uplevel "set $kwArgsName\($kw\) \"$opt\""
                    set state OPT
                }
            }

            END { return; }
        }
    }
}

# Author: Sarnold (http://wiki.tcl.tk/9126)
# Used in: http://wiki.tcl.tk/19851
# The nice thing in 'foreach $var' is that you can map tuples
# (like option-values pairs). The following code is used to put
# the assertion that the user does *not* put a -fill option:
#   myutl::lmap {option value} {assert {$option ne "-fill"}} {-opt val ...}
# Another example:
#   myutl::lmap x {puts $x} {1 2 3}
#   => 1
#   => 2
#   => 3
#   => {} {} {}
# or:
#  myutl::lmap x {expr {$x*100}} {1 2 3}
#  => 100 200 300; # list
proc myutl::lmap {var body list} {
    set o {}
    foreach $var $list {lappend o [eval $body]}
    set o
}

#set args {}; # positional args
#array set kw {-a 1 -b 2}; # default kw-args
##set inputArgs {-a 20 -c 30 zzz -q -v xxx yyy}
#set inputArgs {-loop}
#myutl::proc_opts args kw $inputArgs
#puts "Args:\n $args"
#puts "KW Args:"
#foreach {k v} [array get kw] {
#    puts " $k = $v"
#}

# Verify that value is in the type range. Known types are b (byte),
# w (word), d (doubleword), q (quadword). If is out-of-range, then
# raise will be callen
proc myutl::ibounds {type value} {
    set absvalue [::tcl::mathfunc::abs $value]

    proc raise {t v} {
        # Raise error message. t is type name, such as "word" or "quadword"
        error [format "Value 0x%X is not a %s" $v $t]
    }

    switch -- $type {
        b { if {$absvalue > 255} {raise byte $absvalue} }
        w { if {$absvalue > 65536} {raise word $absvalue} }
        d { if {$absvalue > 4294967296} {raise doubleword $absvalue} }
        q { if {$absvalue > 18446744073709551616} {raise quadword $absvalue} }
    }
    return 1
}

# Converts args to list of bytes (binary form of args). See
# >>> args2bytes b1 w4A
# 01 00 4A
# Each arg is integer prefixed by b|w|d|q and is in hex-form.
proc args2bytes {args} {
    set bytes [list]
    foreach arg $args {
        set r [scan $arg %1s%x argtype argvalue]
        if {$r != 2} {
            #puts "some string..."
            continue
        } else {
            # verify value of argvalue (in type bounds)
            myutl::ibounds $argtype $argvalue
            # format argvalue into string
            switch -- $argtype {
                b {set fmt %02X}
                w {set fmt %04X}
                d {set fmt %08X}
                q {set fmt %016X}
            }
            set sarg [format $fmt $argvalue]
            set argbytes [regexp -all -inline .. $sarg]
            set bytes [concat $bytes $argbytes]
        }
    }
    return $bytes
}

# Validate that min <= val <= max
proc myutl::vintrng {val min max {empty_possible 1}} {
    if {$empty_possible && $val eq ""} {
        return 1
    } else {
        return [expr {[string is integer -strict $val] && $val >= $min && $val <= $max}]
    }
}

# Validate that min <= val <= max
proc myutl::vdoublerng {val min max {empty_possible 1}} {
    if {$empty_possible && $val eq ""} {
        return 1
    } else {
        return [expr {[string is double -strict $val] && $val >= $min && $val <= $max}]
    }
}

# Compact array -- remove all empty values
proc myutl::acompact arrname {
     upvar 1 $arrname arr
     foreach key [array names arr] {
         if {$arr($key) == ""} {unset arr($key)}
     }
 }


# cond is expr with $el for element substitution
proc myutl::all {seq cond} {
    foreach el $seq {
        if {![eval [subst $cond]]} {
            return 0
        }
    }
    return 1
}

# cond is expr with $el for element substitution
proc myutl::any {seq cond} {
    foreach el $seq {
        if {[eval [subst $cond]]} {
            return 1
        }
    }
    return 0
}

# Validate that val is list of booleans. If len is used, validate also length
proc myutl::vbooleanlist {val {len -1}} {
    foreach v $val {
        if {![string is boolean -strict $v]} {
            return 0
        }
    }
    if {$len != -1 && [llength $val] != $len} {
        return 0
    }
    return 1
}

# Validate that val is list of integers. If len is used, validate also length
proc myutl::vintlist {val {len -1}} {
    foreach v $val {
        if {![string is integer -strict $v]} {
            return 0
        }
    }
    if {$len != -1 && [llength $val] != $len} {
        return 0
    }
    return 1
}

# Validate that val is list of doubles. If len is used, validate also length
proc myutl::vdoublelist {val {len -1}} {
    foreach v $val {
        if {![string is double -strict $v]} {
            return 0
        }
    }
    if {$len != -1 && [llength $val] != $len} {
        return 0
    }
    return 1
}


# Returns text description of value's bits described in masks.
# The masks looks like:
# set masks {
#   "field title" {mask0 descr0 mask1 descr1...}
#   ...
# }
# TODO add support of operation of testing (ex. &0b1010101) and 
# false text for each entry individual
proc myutl::bitsdescr {bitsdef value {false "NO"}} {
    set result {}
    foreach {title masks} $bitsdef {
        set r $false
        foreach {mask descr} $masks {
            if {[expr {$mask & $value}]} {
                set r $descr
                break
            }
        }
        lappend result "$title: $r"
    }
    return $result
}
