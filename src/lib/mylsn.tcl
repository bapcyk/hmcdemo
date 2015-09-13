package provide mylsn 1.0
package require Itcl

# ListenEvent
# =====================================================================
itcl::class ListenEvent {
    public variable name
    public variable src
    public variable data
    constructor {aname asrc {adata ""}} {
        set name aname
        set src asrc
        set data adata
    }
}

# DataListener 
# =====================================================================
itcl::class DataListener {
    # list of understandable providers' datatypes. Empty - all
    public variable datatypes ""

    protected variable _event {};  # ListenEvent

    # all listeners
    public common all {}

    constructor {} { lappend all $this }

    destructor {
        set i [lsearch -exact $all $this]
        if {$i >= 0} { set all [lreplace $all $i $i] }
    }

    # FSM state: LISTEN|SESSION|OFF. Means:
    #   LISTEN - ready for data from data provider
    #   SESSION - already reading some data (first data packet was received)
    #   OFF - reading of data is disabled
    protected variable _lstate LISTEN

    # values is list of values
    protected method ondata {values} {}

    # on run polling (listening session). columns is the list of columns names,
    # units is the list of unit names
    protected method onrun {columns units} {}

    # on stop listening session
    protected method onstop {} {}

    # on add to data provider
    protected method onadd {provider} {}

    # on delete from data provider
    protected method ondel {provider} {}

    method event {ev src args} {
        # generate event (call callback) for this listener.
        # ev is ListenEvent object, src is the source of event.
        # ev is one of run|stop|data|on|off|add|del:
        #   run - before first packet sent
        #   stop - after last packet sent
        #   data - packet is received
        #   on - enable listening
        #   off - disable listening
        #   add - connect with some data provider
        #   del - disconnect from some data provider


        set _event [ListenEvent #auto $ev $src $args]
        switch -- $_lstate {
            LISTEN {
                switch -- $ev {
                    run  { set _lstate SESSION
                           catch { $this onrun {*}$args } }
                    off  { set _lstate OFF }
                    add  { catch { $this onadd {*}$args } }
                    del  { catch { $this ondel {*}$args } }
                }
            }

            SESSION {
                switch -- $ev {
                    stop { set _lstate LISTEN
                           catch { $this onstop } }
                    data { catch { $this ondata {*}$args } }
                }
            }

            OFF {
                switch -- $ev {
                    on   { set _lstate LISTEN }
                    add  { catch { $this onadd {*}$args } }
                    del  { catch { $this ondel {*}$args } }
                }
            }
        }
    }

    # listen -on|-off
    method listen {what} {
        # listen -on -- turn-on listening
        # listen -off -- turn-off listening


        # event without src ("" - user call is event source)
        switch -- $what {
            -on     { $this event on "" }
            -off    { $this event off "" }
            default { error  "listen can be -on or -off only" }
        }
        return
    }

    method listened {} {
        # Is listening now?


        return [expr {$_lstate ne "OFF"}]
    }

    # join columns and units with delimiter into new list
    method join_columns_units {columns units {delim ","}} {
        set res {}
        foreach c $columns u $units {
            lappend res "$c$delim$u"
        }
        return $res
    }
}

# DataProvider
# =====================================================================
itcl::class DataProvider {
    # static list of all providers
    public common all {}
    public variable datatype ""

    protected variable _listeners

    constructor {} { lappend all $this }

    destructor {
        set i [lsearch -exact $all $this]
        if {$i >= 0} { set all [lreplace $all $i $i] }
    }

    # returns list (pair) of columns (list) and units - if they are
    # fixed all the time (for any session)
    method fixed_columns_units {} {}

    # normalize name, need bcz user can use quilified name as
    # ::a, not a.
    # FIXME namespace which -variable does not work in Itcl, so
    # i cut all :, but is possible to add/del only listeners on
    # top-level namespace
    protected method _normname {name} {
        return [regsub -all ":" $name ""]
    }

    method get_listeners {} {
        # Returns names of all listeners


        return [array names _listeners]
    }

    method add_listener {listener} {
        # Add some listener


        set lsndts [$listener cget -datatypes]; # datatypes expected by listener
        if {[llength $lsndts] && !($datatype in $lsndts)} {
            # if listener datatypes not empty (expect some) and my datatype
            # is not in it's datatypes, so I can't add this listener
            error "Listener $listener does not understand $this provider"
        }

        set name [_normname $listener]
        if {[itcl::is object -class DataListener $listener]} {
            if {[array get _listeners $name] ne ""} {
                error "Listener $name already exists"
            }
            set _listeners($name) $listener
            $listener event add $this $this
        } else {
            error "listener should be DataListener object"
        }
    }

    method del_listener {listener {stop 1}} {
        # Deletes listener, sends before stop event if needed


        set name [_normname $listener]
        set listener [lindex [array get _listeners $name] 1]
        if {$listener ne ""} {
            if {$stop} { $listener event stop $this }
            array unset _listeners $name
            $listener event del $this $this
        }
        return $listener
    }

    # XXX not effective
    method del_all_listeners {{stop 1}} {
        # Deletes all listeners, send stop event before, if needed


        foreach name [array names _listeners] {
            del_listener $name $stop
        }
    }

    method notify_all {ev args} {
        # Notify all listeners with event ev and some args


        foreach {name listener} [array get _listeners] {
            $listener event $ev $this {*}$args
        }
    }

    method number {} {
        # Returns number of listeners


        return [array size _listeners]
    }

}

# ProxyListener - general object for process events without creating
# a special class
# =====================================================================
itcl::class ProxyListener {
    inherit DataListener DataProvider

    # which DataProvider owns this proxy. Not auto sets
    public variable origin {}

    public variable onrunproc ""
    public variable onstopproc ""
    public variable ondataproc ""
    public variable onaddproc ""
    public variable ondelproc ""

    protected method onrun {columns units} {
        if {$onrunproc eq ""} {
            notify_all run $columns $units
        } else {
            $onrunproc $columns $units
        }
    }

    protected method onstop {} {
        if {$onstopproc eq ""} {
            notify_all stop
        } else {
            $onstopproc
        }
    }

    protected method ondata {values} {
        if {$ondataproc eq ""} {
            notify_all data $values
        } else {
            $ondataproc $values
        }
    }

    protected method onadd {provider} {
        if {$onaddproc eq ""} {
            notify_all add $provider
        } else {
            $onaddproc $provider
        }
    }

    protected method ondel {provider} {
        if {$ondelproc eq ""} {
            notify_all del $provider
        } else {
            $ondelproc $provider
        }
    }

    method get_listeners {} {
        if {$origin ne ""} {
            return [$origin get_listeners]
        } else {
            return {"@proxy"}
        }
    }
}

# DebugListener - repeater
# =====================================================================
itcl::class DebugListener {
    inherit ProxyListener

    protected variable _out ""
    protected variable _fmt {*DEBUG_${THIS} ${EVENT}*: $ARGS}

    public variable fixed_cu ""

    constructor {{f stdout} {fmt ""}} {
        # f - output channel id. fmt - format string, default is the
        # "*DEBUG_${THIS} ${EVENT}*: $ARGS"


        $this configure -datatype phys -datatypes {v s flt raw phys} \
            -onrunproc [itcl::code $this onrunproc] \
            -onstopproc [itcl::code $this onstopproc] \
            -ondataproc [itcl::code $this ondataproc]

        set _out $f
        if {$fmt ne ""} { set _fmt $fmt }
    }

    method fixed_columns_units {} {
        return $fixed_cu
    }

    method onrunproc {columns units} {
        notify_all run $columns $units
        set THIS $this
        set EVENT onrun
        set ARGS "$columns, $units"
        puts $_out [subst $_fmt]
    }

    method onstopproc {} {
        notify_all stop
        set THIS $this
        set EVENT onstop
        set ARGS ""
        puts $_out [subst $_fmt]
    }

    method ondataproc {values} {
        notify_all data $values
        set THIS $this
        set EVENT ondata
        set ARGS "$values"
        puts $_out [subst $_fmt]
    }
}

# procedures
# =====================================================================

proc debug_listen {d between0 between1} {
    #DebugListener $this.#auto
    $d configure -fixed_cu [$between0 fixed_columns_units]
    listen $between0:$d
    listen $d:$between1
}

proc listen args {
    # Set who listen who:
    #   listen provider...: listener...
    # or
    #   listen prov...: all
    # or
    #   listen -- return list of lists {provider {listeners}}
    # or
    #   listen -txt -- return formatted string (for user)
    # or
    #   listen -p -- returns formatted string with providers and it's datatypes
    # or
    #   listen -l -- returns formatted string with listeners and it's datatypes


    if {[lsearch -exact $args "-txt"] != -1} {
        # if there is "-txt" option, return formatted string
        set res {}
        foreach prov $DataProvider::all {
            set nprov [regsub -all ":" $prov ""]
            lappend res "$nprov: [join [$prov get_listeners] ,\ ]"
        }
        return [join $res "\n"]

    } elseif {[lsearch -exact $args "-p"] != -1} {
        set res {}
        foreach prov $DataProvider::all {
            set nprov [regsub -all ":" $prov ""]
            set dt [$prov cget -datatype]
            lappend res "$nprov: provides '$dt'"
        }
        return [join $res "\n"]

    } elseif {[lsearch -exact $args "-l"] != -1} {
        set res {}
        foreach lsn $DataListener::all {
            set nlsn [regsub -all ":" $lsn ""]
            set dt [join [$lsn cget -datatypes] "','"]
            lappend res "$nlsn: listens '$dt'"
        }
        return [join $res "\n"]

    } elseif {$args eq ""} {
        # if no args, returns listening table (all links)
        set res {}
        foreach prov $DataProvider::all {
            lappend res [list $prov [$prov get_listeners]]
        }
        return $res

    } else {
        # normalize args (make ':' like arg, not part of another arg)
        lassign [split [join $args " "] :] providers listeners

        # if there is 'all' in listeners then it'll be all of them :)
        if {[lsearch -exact $listeners all] != -1} {
            set listeners $DataListener::all
        }

        # delete each listener from ALL known providers then attach
        # to selected
        foreach lsn $listeners {
            foreach prov $DataProvider::all { $prov del_listener $lsn 1 }
            foreach prov $providers { $prov add_listener $lsn }
        }
    }
}
