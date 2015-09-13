package provide mydsp 1.0

package require Itcl
package require mydoc
package require mylsn
package require mym

set DEG [format %c 176]

set A0 ""
set Apre 0.0
set Vpre 0.0
set Ppre 0.0
set Tpre 0
set Si 0

# NOTE listened only HMC6343 object
itcl::class PhysValues {
    inherit DataListener DataProvider

    # correct gravity effect?
    public variable corrg 1 { $_cphvals setup $corrg }

    # columns and units of provided data
    protected variable COLUMNS "Head Pitch Roll Ax Ay Az Mx My Mz Temp"
    protected variable UNITS "$DEG $DEG $DEG g g g G G G ${DEG}C"
    protected variable _cphvals {}

    constructor {} {
        set _cphvals [CPhysValues [itcl::scope _cphvals]]
    }

    method reset {} {
        # Reset internal state


        $_cphvals reset
    }

    method fixed_columns_units {} {
        return [list $COLUMNS $UNITS]
    }

    protected method onrun {columns units} { notify_all run $COLUMNS $UNITS }

    protected method onstop {} { notify_all stop }

    protected method ondata {values} {
        # values is {H P R Ax Ay Az Mx My Mz T}:
        if {[$this number] != 0} {
            set phvalues [$_cphvals convert $values]
            notify_all data $phvalues
        }
    }
}

itcl::class LPFilter {
    inherit DataListener DataProvider
    # columns and units of provided data
    protected variable COLUMNS "Head Pitch Roll Ax Ay Az Mx My Mz Temp"
    protected variable UNITS "$DEG $DEG $DEG g g g G G G ${DEG}C"

    protected variable _flt {}
    protected variable _aturn {}
    protected variable _sensor {}

    public variable rc 0.5 { $_flt setup $rc $dt }
    public variable dt 0.2 { $_flt setup $rc $dt }

    method get_coeff {args} {
        # Returns coefficient


        return [$_flt cget -a]
    }

    method ref args {
        array set kw {}
        myutl::proc_opts {} kw $args
        set _sensor $kw(-sensor)
    }

    method reset {} {
        # Reset internal state


        $_flt reset
        $_aturn reset
    }

    constructor {} {
        set _flt [CLPFilter [itcl::scope _flt] [llength $COLUMNS] $rc $dt]
        set _aturn [CAntiTurn [itcl::scope _aturn]]
    }

    method fixed_columns_units {} { return [list $COLUMNS $UNITS] }

    protected method onrun {columns units} {
        notify_all run $COLUMNS $UNITS
        # obtain sampling period from sensor
        catch {
            $this configure -dt [expr {1.0/[$_sensor get_freq]}]
        }
    }

    protected method onstop {} { notify_all stop }

    protected method ondata {values} {
        # using of antiturn algorithm
        set values [list \
            {*}[$_aturn prefilt [lrange $values 0 2]] \
            {*}[lrange $values 3 end] \
        ]
        if {[$this number]} {
            set values [$_flt filter $values]
            set values [list \
                {*}[$_aturn postfilt [lrange $values 0 2]] \
                {*}[lrange $values 3 end] \
            ]
            notify_all data $values
        }
    }
}

itcl::class HPFilter {
    inherit DataListener DataProvider
    # columns and units of provided data
    protected variable COLUMNS "Head Pitch Roll Ax Ay Az Mx My Mz Temp"
    protected variable UNITS "$DEG $DEG $DEG g g g G G G ${DEG}C"

    protected variable _flt {}
    #protected variable _aturn {}
    protected variable _sensor {}

    public variable rc 0.5 { $_flt setup $rc $dt }
    public variable dt 0.2 { $_flt setup $rc $dt }

    method get_coeff {args} {
        # Returns coefficient


        return [$_flt cget -a]
    }

    method ref args {
        array set kw {}
        myutl::proc_opts {} kw $args
        set _sensor $kw(-sensor)
    }

    method reset {} {
        # Reset internal state


        $_flt reset
        #$_aturn reset
    }

    constructor {} {
        set _flt [CHPFilter [itcl::scope _flt] [llength $COLUMNS] $rc $dt]
        #set _aturn [CAntiTurn [itcl::scope _aturn]]
    }

    method fixed_columns_units {} { return [list $COLUMNS $UNITS] }

    protected method onrun {columns units} {
        notify_all run $COLUMNS $UNITS
        # obtain sampling period from sensor
        catch {
            $this configure -dt [expr {1.0/[$_sensor get_freq]}]
        }
    }

    protected method onstop {} { notify_all stop }

    protected method ondata {values} {
        if {[$this number]} {
            notify_all data [$_flt filter $values]
        }
    }
}


# Base class for all filters (FIRs while only)
itcl::class BaseFilter {
    inherit DataListener DataProvider
    # columns and units of provided data
    protected variable COLUMNS "Head Pitch Roll Ax Ay Az Mx My Mz Temp"
    protected variable UNITS "$DEG $DEG $DEG g g g G G G ${DEG}C"

    protected variable _filters
    protected variable _cfir_factory "";# expression to eval - created some CFir
    protected variable _sensor {}
    protected variable _last_chconfigure_chans {}
    protected variable _last_chconfigure_opts

    # XXX should be called in successors constructor
    protected method _set_cfir_factory {cfir_factory} {
        set _cfir_factory $cfir_factory
    }

    method ref args {
        array set kw {}
        myutl::proc_opts {} kw $args
        set _sensor $kw(-sensor)
    }

    method reset {} {
        # Reset internal state


        foreach {iflt flt} [array get _filters] {
            $flt reset
        }
    }

    method fixed_columns_units {} { return [list $COLUMNS $UNITS] }

    public method chconfigure {args} {
        # Configure channels' filters:
        #   -ord int|{int0 int1...} -- order of filter
        #   -f1 double|{double0 double1...} -- cut freq 1
        #   -f2 double|{double0 double1...} -- cut freq 2
        #   -win bool|{bool0 bool1...} -- need Blackman window?
        #   -norm bool|{bool0 bool1...} -- need normalization of coefficients?
        #   -fs double|{double0 double1...} -- sampling freq (if omitted, sensor get_freq is used)
        #
        # Positional args are indexes of channels to be filtered or 'all'. Ex:
        #
        #   chconfigure 0 1 3 -f1 {10 20 30} -ord {15 20 25}
        #
        # All freqs are in Hz. Sampling freq is obtained from sensor when onrun is called.
        # Without args, returns last chconfigure string


        # FIXME no validation of NEGATIVE values!!!

        if {$args eq ""} {
            # if no args, return last chconfigure options
            if {$_last_chconfigure_chans ne ""} {
                return "$_last_chconfigure_chans [array get _last_chconfigure_opts]"
            } else {
                return ""
            }
        }

        set ncolumns [llength $COLUMNS]
        set chans {}
        array set chanscfg {-ord 15 -win 1 -norm 1 -f1 "" -f2 "" -fs ""}
        myutl::proc_opts chans chanscfg $args

        if {$chans eq "all"} {
            set chans {}
            for {set c 0} {$c < $ncolumns} {incr c} {
                lappend chans $c
            }
        }

        set nchans [llength $chans]

        # Validate args

        if {$nchans != [llength [lsort -unique $chans]]} {
            error "Repetition in channels list"
        }

        if {$nchans > $ncolumns || $nchans <= 0} {
            error "Channels aren't specified: there are $ncolumns channels"
        } else {
            foreach ch $chans {
                if {![string is integer -strict $ch] || $ch >= $ncolumns || $ch < 0} {
                    error "Each channel number should be integer 0..[expr $ncolumns-1]"
                }
            }
        }

        if {[string is boolean -strict $chanscfg(-win)]} {
            # -win will be list with the same booleans for all channels
            set chanscfg(-win) [lrepeat $nchans $chanscfg(-win)]
        } elseif {![myutl::vbooleanlist $chanscfg(-win) $nchans]} {
            error "-win should be boolean or list of booleans with length $nchans"
        }

        if {[string is boolean -strict $chanscfg(-norm)]} {
            # -norm will be list with the same booleans for all channels
            set chanscfg(-norm) [lrepeat $nchans $chanscfg(-norm)]
        } elseif {![myutl::vbooleanlist $chanscfg(-norm) $nchans]} {
            error "-norm should be boolean or list of booleans with length $nchans"
        }

        if {[string is integer -strict $chanscfg(-ord)]} {
            # -ord will be list with the same integer for all channels
            set chanscfg(-ord) [lrepeat $nchans $chanscfg(-ord)]
        } elseif {![myutl::vintlist $chanscfg(-ord) $nchans]} {
            error "-ord should be integer or list of integers with length $nchans"
        }

        if {$chanscfg(-fs) ne ""} {
            # if -fs is not omitted
            if {[string is double -strict $chanscfg(-fs)]} {
            # -fs will be list with the same double for all channels
                set chanscfg(-fs) [lrepeat $nchans $chanscfg(-fs)]
            } elseif {![myutl::vdoublelist $chanscfg(-fs) $nchans]} {
                error "-fs should be double or list of double with length $nchans"
            }
        } else {
            # -fs is omitted
            if {[catch {set chanscfg(-fs) [$_sensor get_freq]}]} {
                error "Can not obtain -fs from sensor. Use -fs option instead"
            } else {
                set chanscfg(-fs) [lrepeat $nchans $chanscfg(-fs)]
            }
        }

        if {[string is double -strict $chanscfg(-f1)]} {
            # -f1 will be list with the same double for all channels
            set chanscfg(-f1) [lrepeat $nchans $chanscfg(-f1)]
        } elseif {![myutl::vdoublelist $chanscfg(-f1) $nchans]} {
            error "-f1 should be double or list of double with length $nchans"
        }

        if {-1 != [lsearch $_cfir_factory \$f2]} {
            # there is $f in the _cfir_factory, so validate it
            if {[string is double -strict $chanscfg(-f2)]} {
            # -f2 will be list with the same double for all channels
                set chanscfg(-f2) [lrepeat $nchans $chanscfg(-f2)]
            } elseif {![myutl::vdoublelist $chanscfg(-f2) $nchans]} {
                error "-f2 should be double or list of double with length $nchans"
            }
        }

        # FIXME need or not? Problem: ::lpfir chconfigure -f1 should be fs/2?
        # But in onrun fs is obtained via ::sensor and f1 should be recalculated
        # as fs/2 -- how to do this??
        #foreach fs $chanscfg(-fs) f1 $chanscfg(-f1) f2 $chanscfg(-f2) {
        #    # -f1 and -f2 should <= -fs/2 (Nyquist frequency?)
        #    set fs_2 [expr {$fs/2.}]
        #    if {$f1 > $fs_2 || $f2 > $fs_2} {
        #        error "-f1 and -f2 should be <= half of -fs"
        #    }
        #}

        # Create filters

        #puts "chans: $chans"
        #puts "ord: $chanscfg(-ord)"
        #puts "win: $chanscfg(-win)"
        #puts "norm: $chanscfg(-norm)"
        #puts "fs: $chanscfg(-fs)"
        #puts "f1: $chanscfg(-f1)"
        #puts "f2: $chanscfg(-f2)"
        array unset _filters
        foreach ch $chans \
            ord $chanscfg(-ord) \
            fs $chanscfg(-fs) \
            f1 $chanscfg(-f1) \
            f2 $chanscfg(-f2) \
            win $chanscfg(-win) \
            norm $chanscfg(-norm) {
                set name {[itcl::scope _filters($ch)]}
                set factory [subst $_cfir_factory]
                #puts $factory
                set _filters($ch) [eval $factory]
                #set _filters($ch) [Clpfir $name $ord $fs $f1 $f2 $win $norm]
        }
        set _last_chconfigure_chans $chans
        myutl::acompact chanscfg
        array set _last_chconfigure_opts [array get chanscfg]
    }

    method get_cfir {i} {
        # Returns core FIR (on C in DLL) object


        return $_filters($i)
    }

    # Return options of last chconfigure via variable names:
    # chansvarname, optsvarname. If chconfigured early, returns 1,
    # 0 otherwise
    #protected method _get_cfir_opts {chansvarname optsvarname} {
    #    set chans {}

    #    if {-1 != [lsearch $_cfir_factory \$f2]} {
    #        # filters are band (there are -f2 in its factory)
    #        array set opts {-ord "" -win "" -norm "" -fs "" -f1 "" -f2 ""}
    #    } else {
    #        # filters are not band
    #        array set opts {-ord "" -win "" -norm "" -fs "" -f1 "" }
    #    }
    #    foreach {iflt flt} [array get _filters] {
    #        lappend chans $iflt
    #        foreach opt [array names opts] {
    #            lappend opts($opt) [$_filters($iflt) cget $opt]
    #        }
    #    }
    #    if {$chans ne ""} {
    #        # when was configured
    #        upvar $chansvarname retchans $optsvarname retopts
    #        set retchans $chans
    #        array set retopts [array get opts]
    #        return 1
    #    } else {
    #        return 0
    #    }
    #}

    protected method onrun {columns units} {
        catch {
            # Try to obtain last sampling freq from sensor
            # and reconfigure chans with last chconfigure opts but
            # new -fs value
            set fs [$_sensor get_freq]
            array set tmpopts [array get _last_chconfigure_opts]
            array set tmpopts "-fs $fs"
            chconfigure {*}$_last_chconfigure_chans {*}[array get tmpopts]
        }
        notify_all run $COLUMNS $UNITS
    }

    #method f {} {
        #array set _last_chconfigure_opts "-fs 123"
        #parray _last_chconfigure_opts
    #}

    protected method onstop {} { notify_all stop }

    # filter channels (which needed)
    protected method _filter_chans {values} {
        foreach {iflt flt} [array get _filters] {
            set values [lreplace $values $iflt $iflt [$flt filter [lindex $values $iflt]]]
        }
        return $values
    }
}

# Low-pass FIR
itcl::class Lpfir {
    inherit BaseFilter

    protected variable _aturn {}

    constructor {} {
        _set_cfir_factory {Clpfir $name $ord $fs $f1 $win $norm}
        set _aturn [CAntiTurn [itcl::scope _aturn]]
    }

    method reset {} {
        # Reset internal state


        $_aturn reset
        BaseFilter::reset
    }

    protected method ondata {values} {
        # using of antiturn algorithm
        set values [list \
            {*}[$_aturn prefilt [lrange $values 0 2]] \
            {*}[lrange $values 3 end] \
        ]
        if {[$this number]} {
            set values [_filter_chans $values]
            set values [list \
                {*}[$_aturn postfilt [lrange $values 0 2]] \
                {*}[lrange $values 3 end] \
            ]
            notify_all data $values
        }
    }
}

# High-pass FIR
itcl::class Hpfir {
    inherit BaseFilter

    constructor {} {
        _set_cfir_factory {Chpfir $name $ord $fs $f1 $win $norm}
    }

    method reset {} {
        # Reset internal state


        BaseFilter::reset
    }

    protected method ondata {values} {
        if {[$this number]} {
            notify_all data [_filter_chans $values]
        }
    }
}

# Band-pass FIR
itcl::class Bpfir {
    inherit BaseFilter

    constructor {} {
        _set_cfir_factory {Cbpfir $name $ord $fs $f1 $f2 $win $norm}
    }

    method reset {} {
        # Reset internal state


        BaseFilter::reset
    }

    protected method ondata {values} {
        if {[$this number]} {
            notify_all data [_filter_chans $values]
        }
    }
}


# complementary integrator
itcl::class CIntr {
    inherit DataListener DataProvider
    # columns and units of provided data
    protected variable COLUMNS "Sx Sy Sz"
    protected variable UNITS "m m m"

    protected variable _ccintr {}
    protected variable _Tpre 0

    public variable a 0.92 { $_ccintr setup $a }

    method get_coeff {args} {
        # Returns coefficient


        return [list [$_ccintr cget -a] [$_ccintr cget -b]]
    }

    constructor {} {
        set _ccintr [CCIntr [itcl::scope _ccintr] $a]
    }

    method fixed_columns_units {} { return [list $COLUMNS $UNITS] }

    # Reset internal state
    method reset {} {
        # Reset internal state


        set _Tpre 0
        $_ccintr reset
    }

    protected method onrun {columns units} {
        notify_all run $COLUMNS $UNITS
    }

    protected method onstop {} { notify_all stop }

    protected method ondata {values} {
        if {[$this number]} {
            set Tnow [clock milliseconds]
            if {$_Tpre == 0} {
                set _Tpre $Tnow
                return
            }
            set dt [expr {($Tnow - $_Tpre)/1000.0}]
            # select with lindex only accelerometer data
            set res [$_ccintr estimate $dt \
                [lindex $values 3] \
                [lindex $values 4] \
                [lindex $values 5] \
                ]
            set _Tpre $Tnow
            notify_all data $res
            #puts "res = $res"
        }
    }
}

# Simpson integrator
itcl::class SIntr {
    inherit DataListener DataProvider

    protected variable _sensor {}
    protected variable _csintr

    # common h for all integrators. But also individual h are available
    public variable h 0.2 { foreach {iintr intr} [array get _csintr] { $intr setup_h $h } }

    constructor {} {
        for {set i 0} {$i < 3} {incr i} {
            set _csintr($i) [CSIntr [itcl::scope _csintr($i)] $h]
        }
    }

    # Reset internal state
    method reset {} {
        # Reset internal state


        foreach {iintr intr} [array get _csintr] { $intr reset }
    }

    method ref args {
        array set kw {}
        myutl::proc_opts {} kw $args
        set _sensor $kw(-sensor)
    }

    method get_intr {i} {
        # Returns 1 of 3 integrators


        return $_csintr($i)
    }

    protected method onrun {columns units} {
        catch {
            $this configure -h [expr {1./[$_sensor get_freq]}]
        }
        notify_all run $columns $units
    }

    protected method onstop {} { notify_all stop }

    protected method ondata {values} {
        if {[$this number]} {
            # Ax, Ay, Az - {3 4 5} channels
            foreach {iintr intr} [array get _csintr] iacc {3 4 5} {
                lset values $iacc [$intr calculate [lindex $values $iacc]]
            }
            notify_all data $values
        }
    }
}

# Double Simpson's integrator of all channels (produces meters)
itcl::class DSIntr {
    inherit DataListener DataProvider
    # columns and units of provided data
    protected variable COLUMNS "Sx Sy Sz"
    protected variable UNITS "m m m"

    # enabled filtering (or only integration)
    public variable fon 1 {
        # relink (depends on $fon)
        link_all
    }

    protected variable _sensor {}
    # first, input component
    protected variable _in {}
    # high-pass filters
    protected variable _flt
    # Simpson integrators
    protected variable _intr
    # Output (proxy)
    protected variable _out

    method prepare_flt {iflt flt} {
        # Configures some filter object (flt) with standard options for this algorithm.
        # iflt is needed to specified position (in common way options should depends on
        # position: input filter or, for ex., output filter cascade)


        switch -- [$flt info class] {
            ::Hpfir { $flt chconfigure 3 4 5 -ord 15 -fs 10 -f1 0.7 }
            ::Bpfir { $flt chconfigure 3 4 5 -ord 15 -fs 10 -f1 0.7 -f2 2 }
            ::HPFilter { $flt configure -rc 0.5 }
        }
        $flt ref -sensor $_sensor
        $flt configure -datatype flt -datatypes {raw phys flt v s}
    }

    constructor {} {
        # filter - need filtering or only integrate


        # Create Hpfir objects
        for {set i 0} {$i < 3} {incr i} {
            # XXX There is problems with standard [itcl::scope] here!
            #set _flt($i) [Hpfir $this.#auto]
            #set _flt($i) [Bpfir $this.#auto]
            set _flt($i) [HPFilter $this.#auto]
            #set _flt($i) [Hpfir [itcl::scope _flt($i)]]
            prepare_flt $i $_flt($i)
        }
        # Create C integrators
        for {set i 0} {$i < 2} {incr i} {
            set _intr($i) [SIntr $this.#auto]
        }
        $_intr(0) configure -datatype v -datatypes {raw phys flt}
        $_intr(1) configure -datatype s -datatypes {raw phys flt v}

        set _out [ProxyListener $this._out]
        $_out configure -origin $this
        $_out configure -datatype s -datatypes {flt s}
        $_out configure \
            -ondataproc [itcl::code $this _proxy_ondata] \
            -onrunproc [itcl::code $this _proxy_onrun] \
            -onstopproc [itcl::code $this _proxy_onstop]

        link_all
    }

    method link_all {} {
        # Links all cascades with filtering usage (filter=1), otherwise
        # without filters.


        # Components links are:
        #   _flt(0) -> _intr(0) -> _flt(1) -> _intr(1) -> _flt(2) -> _out
        # _in is the input component

        $_flt(0) del_all_listeners
        $_flt(1) del_all_listeners
        $_flt(2) del_all_listeners
        $_intr(0) del_all_listeners
        $_intr(1) del_all_listeners

        if {$fon} {
            $_flt(0)  add_listener $_intr(0)
            $_intr(0) add_listener $_flt(1)
            $_flt(1)  add_listener $_intr(1)
            $_intr(1) add_listener $_flt(2)
            $_flt(2)  add_listener $_out
            set _in $_flt(0)
        } else {
            $_intr(0) add_listener $_intr(1)
            $_intr(1) add_listener $_out
            set _in $_intr(0)
        }
    }

    method links {{mode ""}} {
        # Describes links in column mode (mode is "-col"), string mode otherwise.


        set prov $_in
        set res {}
        while {[namespace which $prov] ne [namespace which $_out]} {
            set cls [$prov info class]
            lappend res "[regsub -all : $prov {}]@[regsub -all : $cls {}]"
            set prov [$prov get_listeners]; # expect only one member
        }
        if {$mode eq "-col"} {
            return [join $res [format "\n    %c\n" 0x2193]]
        } else {
            return [join $res " -> "]
        }
    }

    method ref args {
        array set kw {}
        myutl::proc_opts {} kw $args
        set _sensor $kw(-sensor)
        # set also ref. in all internal components
        foreach {iflt flt} [array get _flt] { $flt ref -sensor $kw(-sensor) }
        foreach {iintr intr} [array get _intr] { $intr ref -sensor $kw(-sensor) }
        # XXX ProxyListener doesnt contain sensor ref
        #$_out ref -sensor $kw(-sensor)
    }

    method fixed_columns_units {} { return [list $COLUMNS $UNITS] }

    # Reset internal state
    method reset {} {
        # Reset internal state


        foreach {iintr intr} [array get _intr] { $intr reset }
        foreach {iflt flt} [array get _flt] { $flt reset }
    }

    method get_flt {i} {
        # Returns filter by cascade number i


        return $_flt($i)
    }

    method get_intr {i} {
        # Returns integrator by cascade number i:
        #   channel0 -> .. -> 0 -> .. -> 3
        #   channel1 -> .. -> 1 -> .. -> 4
        #   channel2 -> .. -> 2 -> .. -> 5


        return $_intr($i)
    }

    method set_flt {iflt flt} {
        # Replaces existent filter object in iflt position with another one.
        # Flt may be any filter, but High-Pass are preferred by algorithm.
        # After replacing returns old.


        if {[array get _flt $iflt] ne ""} {
            # if there is flt with such key iflt
            $flt ref -sensor $_sensor
            set _flt($iflt) $flt
            link_all
        } else {
            error "Unknown filter $iflt"
        }
    }


    # proxy handlers:

    protected method _proxy_onrun {columns units} {
        notify_all run $COLUMNS $UNITS
    }
    protected method _proxy_onstop {} {
        notify_all stop
    }
    protected method _proxy_ondata {values} {
        if {[$this number]} {
            notify_all data [lrange $values 3 5]
        }
    }


    # repeater input for first component:

    protected method onrun {columns units} {
        # on run all listeners will refresh sensor frequency
        $_in event run $this $columns $units
    }

    protected method onstop {} {
        $_in event stop $this
    }

    protected method ondata {values} {
        $_in event data $this $values
    }
}


# Reset internal (collected data) state of DSP components
proc reset_dsp {} {
    # Reset internal state of all DSP components


    ::lpfilter reset
    ::cintr reset
    ::phvals reset
    ::lpfir reset
    ::hpfir reset
    ::dsintr reset
}

PhysValues ::phvals
::phvals configure -datatype phys -datatypes {raw}

LPFilter ::lpfilter
::lpfilter ref -sensor ::sensor
::lpfilter configure -datatype flt -datatypes {raw phys flt}

Lpfir ::lpfir
::lpfir ref -sensor ::sensor
::lpfir chconfigure 0 1 2 -ord 20 -fs 10 -f1 5
::lpfir configure -datatype flt -datatypes {raw phys flt}

Hpfir ::hpfir
::hpfir ref -sensor ::sensor
::hpfir chconfigure 0 1 2 -ord 20 -fs 10 -f1 5
::hpfir configure -datatype flt -datatypes {raw phys flt}

Bpfir ::bpfir
::bpfir ref -sensor ::sensor
::bpfir chconfigure 0 1 2 -ord 20 -fs 10 -f1 1 -f2 2.5
::bpfir configure -datatype flt -datatypes {raw phys flt}

CIntr ::cintr
::cintr configure -datatype s -datatypes {phys flt}

DSIntr ::dsintr
::dsintr ref -sensor ::sensor
::dsintr configure -datatype s -datatypes {phys flt}
