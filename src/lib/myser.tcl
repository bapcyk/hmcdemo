package provide myser 1.0
package require Itcl
package require myutl
package require mycons
package require registry

# TODO remove simulate (comment!!!)

# TODO add timeout in constructor for expect (if no bytes number for this timeout value)

itcl::class Serial {

    # for debug
    #public variable simulate 0
    # channel id
    protected variable _port {}
    # input bytes
    protected variable _inbuf ""
    # input bytes number
    protected variable _innbytes 0
    # wait for count bytes incoming
    protected variable _wait_nbytes 0
    # input is ready
    protected variable _inready 0

    # FIXME does not call when Alt-F4
    # TODO should be call explicitly
    destructor {
        close
    }

    # list all ports as FTDIBUS and USB. Returns list of {PortName, FriendlyName, Auto?}
    # where Auto is flag - port for HMC6343 or not
    proc _ls_virt {} {
        set res {}
        foreach type {USB FTDIBUS} {
            set k0 "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Enum\\$type"
            #puts "k0 = $k0"
            set k0ch [registry keys "$k0" {V[iI][dD]_*}]
            #puts "k0ch = $k0ch"
            foreach k1 $k0ch {
                set k1ch [registry keys "$k0\\$k1"]
                #puts "k1 = $k1ch"
                foreach k2 $k1ch {
                    catch {
                        set Class [registry get "$k0\\$k1\\$k2" Class]
                        #puts "=> $k0\\$k1\\$k2"
                        if {$Class == "Ports"} {
                            set FriendlyName [registry get "$k0\\$k1\\$k2" FriendlyName]
                            set PortName [registry get "$k0\\$k1\\$k2\\Device Parameters" PortName]
                            set Auto [expr {"silabser" == [registry get "$k0\\$k1\\$k2" "Service"]}]; #auto-detected
                            lappend res [list $PortName $FriendlyName $Auto]
                        }
                    }
                }
            }
        }
        return $res
    }

    # Returns list of {PortName, "Com Port", 0} -
    # auto-detect is impossible in this mode, no friendly name also
    proc _ls_all {} {
        set serial_base "HKEY_LOCAL_MACHINE\\HARDWARE\\DEVICEMAP\\SERIALCOMM"
        set values [registry values $serial_base]
        set res {}
        foreach valueName $values {
            set PortName [registry get $serial_base $valueName]
            set FriendlyName "COM Port"
            set Auto 0
            lappend res [list $PortName $FriendlyName $Auto]
        }
        return $res
    }

    method ls {{what "-all"}} {
        # Prints -all|-virt|-auto - detected COM-ports from Windows registry
        #   -all - is without FriendlyName
        #   -virt - virtual ports


        switch -- $what {
            "-all" {
                foreach port [Serial::_ls_all] {
                    puts [lindex $port 0]
                }
            }
            "-auto" {
                foreach port [Serial::_ls_virt] {
                    if {1 == [lindex $port 2]} {
                        puts "[lindex $port 0]: [lindex $port 1]"
                    }
                }
            }
            "-virt" {
                foreach port [Serial::_ls_virt] {
                    if {1 == [lindex $port 2]} { set hd "* "
                    } else { set hd "  "; }
                    puts "$hd[lindex $port 0]: [lindex $port 1]"
                }
            }
        }
    }

    # Occurs when input bytes are ready for reading
    # NOTE should be public to call on readable event (or use itcl::code command)
    method _onresponse {} {
        set buf [chan read $_port]
        incr _innbytes [string length $buf]
        lappend _inbuf $buf

        if {$_wait_nbytes != 0 && $_innbytes >= $_wait_nbytes} {
            # client wait number of bytes
            set _wait_nbytes 0
            set _inready 1
        }
    }

    # TODO add timeout (via after {set _inready})!! May be syntax:
    # expect 6 {...} - 6 bytes; expect 6usec { ...} - 6 uSeconds
    method expect {nbytes body} {
        # Used for sending with waiting for nbytes bytes, ex.
        # serial expect 6 { serial docmd SOME_CMD }


        #if {$simulate} {
            #puts "Simulate expect. Bytes are $nbytes, body is $body"
            #set _inready 0
            #return
        #}

        # how many bytes will be waiting for
        if {$nbytes == 0} {
            eval $body
        } else {
            set _wait_nbytes $nbytes
            eval $body
            # wait for input-ready
            vwait [itcl::scope _inready]
            # reset input-ready
            set _inready 0
        }
    }

#    method sendw {msec body} {
#        eval $body
#        after $msec
#        set _inready 0
#    }

    # TODO add support of default port number detecting (via registry)
    method open {port {mode "9600,n,8,1"}} {
        # Opens port with name or number (1,2..) port and mode (like "9600,n,8,1")


        if {[regexp {^\d+$} $port]} {
            # if port is number
            set portname "//./com$port"
        } else {
            # else is the file path
            set portname $port
        }
        set _port [::open $portname RDWR]
        chan configure $_port -mode $mode -translation binary -encoding binary \
            -blocking 0 -buffering none -eofchar {}
            #-blocking 0 -buffering none
    }

    method listen {{enabled "-on"}} {
        # Turn-on/off listening of incoming bytes in async manner.
        #   -on - enables listening
        #   -off - disables listening


        #if {$simulate} {
            #puts "Simulate listen"
            #return
        #}

        set do_on "chan event $_port readable \"$this _onresponse\""
        set do_off "chan event $_port readable {}"
        switch -nocase $enabled {
            "-on" { eval $do_on }
            "-off" { eval $do_off }
            default { eval $do_on }
        }
    }

    method listened {} {
        # Returns 1 if listened readable events, 0 otherwise


        return [expr {$_port ne "" && [chan event $_port readable] ne ""}]
    }

    method opened {} {
        # Is it opened?


        return [expr {$_port!=""}]
    }

    method closed {} {
        # Is it closed?


        return [expr {![opened]}]
    }

    method close {} {
        # Safe closing of port (listening turn-off)


        if {[opened]} {
            listen -off
            chan close $_port
            set _port ""
        }
    }

    method send {bytes} {
        # Sends bytes (like {0x53 0x30 ...}) sequence


        #if {$simulate} {
            #mycons::ConsolePuts cons "send $bytes"
            #puts "Simulate send: $bytes"
            #return
        #}

        set nbytes [llength $bytes]
        chan puts -nonewline $_port [binary format c$nbytes $bytes]
    }

    method read {args} {
        # Receive bytes from port. With -nb -- in NON-BLOCKED manner, but
        # returns _inbuf (early readed asynchronously)


        #if {$simulate} {
            #puts "Simulate read"
            #return ""
        #}

        if {-1 != [lsearch $args "-nb"]} {
            # return _inbuf (NON-BLOCKED), it will be set when
            # input bytes incomes
            set ret [join $_inbuf ""]
            set _inbuf ""
            set _innbytes 0
            return $ret
        } else {
            # else read real data from channel
            return [chan read $_port]
        }
    }

    method got {{what "-size"}} {
        # Returns incoming data as string with -data option or
        # it's size with -size option but unlike read does not
        # clear _inbuf


        switch -nocase $what {
            "-data" { return [join $_inbuf ""] }
            "-size" { return $_innbytes }
            default { return $_innbytes }
        }
    }

}
