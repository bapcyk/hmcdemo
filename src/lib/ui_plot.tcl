package provide ui_plot 1.0

#package require Tcl 8.5
package require Tk
package require Ttk
package require Itcl
package require mylsn
#package require mydsp
#package require mysens

# NOTE: <Configure> may did not occur but ondata is going! To avoid this
# _configured is used!

# Got values in grid of cells
itcl::class Uiplot {
    inherit DataListener

    protected variable _parent
    protected variable _pl
    # <Configure> already occured, there are plot
    protected variable _configured 0

    protected variable cw; # canvas width
    protected variable ch; # canvas height
    protected variable pw; # plot width
    protected variable ph; # plot height
    protected variable horizpad 80; # padding between plot and canvas
    protected variable vertpad 40; # padding between plot and canvas
    protected variable bw; # width of bar
    protected variable NT 8.; # ticks number on Oy
    protected variable title {P O S I T I O N  Ox, Oy, Oz [m]:}
    protected variable x_center; # Ox center of 1 bar in pixels
    protected variable y_center; # Ox center of 2 bar in pixels
    protected variable z_center; # Ox center of 3 bar in pixels
    protected variable x_end; # end on Ox of 1 bar in pixels
    protected variable y_end; # end on Ox of 2 bar in pixels
    protected variable z_end; # end on Ox of 3 bar in pixels
    protected variable x_color #b11; # color of 1 bar
    protected variable y_color #3b3; # color of 2 bar
    protected variable z_color #55b; # color of 3 bar

    method ondata {values}
    method onrun {columns units}
    protected method _update {values}
    method create {parent}
    method set_intr {intrname}

    protected method _onconfigure {args}
    protected method _create_plot

    protected method _canv2plot {args}
    protected method _plot2canv {args}
}

itcl::body Uiplot::create {w} {
    set _parent $w
    canvas $_parent.c -bg #777 -bd 0
    bind $_parent.c <Configure> [itcl::code $this _onconfigure]
    pack $_parent.c -fill both -expand 1

}

itcl::body Uiplot::_onconfigure args {
    global redo
    # To avoid redrawing the plot many times during resizing,
    # cancel the callback, until the last one is left.
    if {[info exists redo]} {
        after cancel $redo
    }
    set redo [after 50 [itcl::code $this _create_plot]]
}

itcl::body Uiplot::_create_plot {} {
    $_parent.c delete all

    # calculate sizes
    set cw [winfo width $_parent.c]
    set ch [winfo height $_parent.c]

    set pw [expr {$cw - 2*$horizpad}]
    set ph [expr {$ch - 2*$vertpad}]

    set bw [expr {$pw/3}]
    set x_center [expr {0.5*$bw}]
    set y_center [expr {1.5*$bw}]
    set z_center [expr {2.5*$bw}]
    set x_end $bw
    set y_end [expr {2*$bw}]
    set z_end [expr {3*$bw}]

    # create canvas items

    # axes
    set arr 15; # additional length to arrow

    $_parent.c create line {*}[_plot2canv \
        0 0 [expr {$pw+$arr}] 0] -arrow last

    $_parent.c create line {*}[_plot2canv \
        0 [expr {-$ph/2}] 0 [expr {$ph/2+$arr}]] -arrow last

    # title
    $_parent.c create text {*}[_plot2canv \
        [expr {$pw/2}] [expr {($ph + $vertpad)/2}]] -text $title -anchor center

    # horiz izolines: from up to down
    set d [expr {$ph/$NT}]
    for {set i 0} {$i <= $NT} {incr i} {
        set izoy [expr {$ph/2. - $i*$d}]

        $_parent.c create line {*}[_plot2canv 0 $izoy $pw $izoy] -dash "2 2"

        $_parent.c create text {*}[_plot2canv -1 $izoy] -text ?m -anchor e \
            -tags "tick$i"
    }

    # 3 bars
    lassign {5 10 20} y1 y2 y3
    $_parent.c create rectangle {*}[_plot2canv \
        0 $y1 $x_end 0] -fill $x_color -tags barx

    $_parent.c create rectangle {*}[_plot2canv \
        $x_end $y2 $y_end 0] -fill $y_color -tags bary

    $_parent.c create rectangle {*}[_plot2canv \
        $y_end $y3 $z_end 0] -fill $z_color -tags barz

    # values
    $_parent.c create text {*}[_plot2canv $x_center $y1] -text ?m \
        -anchor s -tags valx
    $_parent.c create text {*}[_plot2canv $y_center $y2] -text ?m \
        -anchor s -tags valy
    $_parent.c create text {*}[_plot2canv $z_center $y3] -text ?m \
        -anchor s -tags valz

    set _configured 1
}

itcl::body Uiplot::_update {values} {
    lassign $values x y z

    # auto-scale
    set halfy 1; # half of Oy in SI units
    set scale_coff 2; # meters (step for finding of necessary halfy value)
    set max_value [expr "max(abs($x), abs($y), abs($z))"]
    while 1 {
        if {$max_value < $halfy} {
            break
        } else {
            set halfy [expr {$halfy * $scale_coff}]
        }
    }

    # set values on ticks (up-to-down)
    set tick_step [expr {2.0*$halfy/$NT}]
    for {set i 0} {$i <= $NT} {incr i} {
        $_parent.c itemconfigure "tick$i" \
            -text [format "%0.2f" [expr {$halfy - $i*$tick_step}]]
    }

    # scale bars and change values on its labels
    foreach v $values \
        bar "barx bary barz" \
        center "$x_center $y_center $z_center" \
        x0 "0 $x_end $y_end" \
        x1 "$x_end $y_end $z_end" \
        lab "valx valy valz" {
            if {$v < 0.0} {
                set y0 0
                set y1 [expr {-1*(abs($v) * $ph/(2.0 * $halfy))}]
                set ylab $y1
                set anchor n
            } else {
                set y0 [expr {abs($v) * $ph/(2.0 * $halfy)}]
                set y1 0
                set ylab $y0
                set anchor s
            }
            # set new coords to bars
            $_parent.c coords $bar {*}[_plot2canv $x0 $y0 $x1 $y1]
            # set values on bars and shift (up-down) if needed
            $_parent.c coords $lab {*}[_plot2canv $center $ylab]
            $_parent.c itemconfigure $lab -text [format %0.2fm $v] -anchor $anchor
    }
}

# convert canvas to plot coordinates
itcl::body Uiplot::_canv2plot {args} {
    set res {}
    foreach {x y} $args {
        lappend res [expr {$x - $horizpad}]
        lappend res [expr {-$y + $ch/2}]
    }
    return $res
}

# convert plot coordinates to plot
itcl::body Uiplot::_plot2canv {args} {
    set res {}
    foreach {x y} $args {
        lappend res [expr {$x + $horizpad}]
        lappend res [expr {-$y + $ch/2}]
    }
    return $res
}

itcl::body Uiplot::ondata {values} {
    $this _update $values
}

itcl::body Uiplot::onrun {columns units} {
    if {!$_configured} { _create_plot }
}

itcl::body Uiplot::set_intr {intrname} {
    # Changes used integrator. intrname is {dsintr|cintr}


    switch -nocase $intrname {
        dsintr {
            ::cintr listen -off
            ::cintr del_listener $this
            ::dsintr add_listener $this
            ::dsintr listen -on
        }
        cintr {
            ::dsintr listen -off
            ::dsintr del_listener $this
            ::cintr add_listener $this
            ::cintr listen -on
        }
        default { error "Unsupported integrator" }
    }
}

Uiplot ::uiplot
::uiplot configure -datatypes {s}
