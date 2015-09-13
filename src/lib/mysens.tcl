package provide mysens 1.0
package require Itcl
package require myser
package require myutl
package require mylsn
package require ui_eeprom

# NOTE All object should be linked together with 'ref' command (see
# classes). It done at the end (after global objects creation)

# Protocol meta-info: bytes, response length, timings 
# =====================================================================
itcl::class HMC6343Protocol {
    protected variable _defs
    protected variable _serial_bound 0

    constructor defs {
        # Creates object.
        #   - defs is the list of CMD RESPONSE_LEN RESPONSE_FMT { Serial commands }...
        #   - RESPONSE_FMT is like in binary command


        foreach {cmdname resplen respfmt cmdseq} $defs {
            set _defs($cmdname) [list $resplen $respfmt $cmdseq]
        }
    }

    # References:
    # -serial serial_obj (actually replace $SERIAL with serial_obj)
    method ref args {
        if {$_serial_bound == 1} {
            error "Protocol is already linked with Serial"
        } else {
            array set kw {}
            myutl::proc_opts {} kw $args
            set SERIAL $kw(-serial)
            set ADDR {$ADDR}; # keep $ADDR as $ADDR for future substitution
            set DATA {$DATA}; # same
            foreach {cmdname cmdinfo} [array get _defs] {
                set cmdseq [lindex $cmdinfo 2]
                set cmddef {}
                foreach cmd $cmdseq {
                    lappend cmddef [subst $cmd]
                }
                lset _defs($cmdname) 2 $cmddef
            }
            set _serial_bound 1
        }
    }

    method commands {} {
        # Returns known commands names


        return [array names _defs]
    }

    method get {cmd what} {
        # Returns protocol info (what) about command cmd. What is:
        #   -def - definition of command (Tcl commands list to be execute for request)
        #   -resplen - length of response in bytes
        #   -respfmt - format of response
        #   -all - as fields as list


        set cmddef $_defs($cmd)
        switch -nocase $what {
            "-resplen" { return [lindex $cmddef 0] }
            "-respfmt" { return [lindex $cmddef 1] }
            "-def"     { return [lindex $cmddef 2] }
            "-all"     { return $cmddef }
        }
    }

    method unpack {cmd buf} {
        # Returns unpacked (as list) values from buf for cmd


        set fmt [$this get $cmd -respfmt]
        binary scan $buf $fmt res
        return $res
    }
}

# Saver to file 
# =====================================================================
itcl::class Saver {
    inherit DataListener

    # where to save files
    public variable dir "C:/tmp"
    # pattern of file name
    public variable fpatt {hmcdemo-$THIS}
    # only for user read
    public variable name ""

    protected variable _fid ""

    # Generate name of file in dir, uses fpatt as name part,
    # suffix is generated from current date-time, extension is .csv
    protected method _genfname {} {
        set suff [clock format [clock microseconds] -format %y-%m-%d_%H_%M_%S]
        set THIS [regsub -all : $this {}]
        set name [subst "$dir/$fpatt-$suff.csv"]
        return [file normalize $name]
    }

    # open new, old close
    protected method _open {fname} {
        $this _close
        set _fid [open $fname a]
    }

    protected method _close {} {
        if {$_fid ne ""} {
            chan flush $_fid
            chan close $_fid
            set _fid ""
        }
    }

    constructor {} {
        # default state - does not save
        $this listen -off
    }

    destructor { $this _close }

    protected method onrun {columns units} {
        $this _open [$this _genfname]
        set columns_and_units [join_columns_units $columns $units ","]
        chan puts $_fid [join $columns_and_units ";"]
    }

    protected method onstop {} {
        $this _close
    }

    protected method ondata {values} {
        if {$_fid ne ""} {
            set line [join $values ";"]
            chan puts $_fid $line
        }
    }
}


# HMC6343 sensor 
# =====================================================================
# NOTE _request, _poll... - should be call after serial listen -on
# (serial listen -off after call!). It's analogs like request, poll...
# does the same work but check that serial listened, if not then turn
# on listeing
itcl::class HMC6343 {
    inherit DataProvider
    # columns and units of provided data
    protected variable COLUMNS "Head Pitch Roll Ax Ay Az Mx My Mz Temp"
    protected variable UNITS "# # # # # # # # # #"

    protected variable _serial {}
    protected variable _proto {}
    protected variable _eeprom {}
    protected variable _cancel_loop 0
    protected variable _looping 0

    # Add internal references to some global objects:
    # ex., # ref -serial serial_objname -protocol protocol_objname
    #  -eeprom eeprom_objname
    method ref args {
        array set kw {}
        myutl::proc_opts {} kw $args
        # TODO check that -serial, -protocol, -eeprom are set
        set _serial $kw(-serial)
        set _proto $kw(-protocol)
        set _eeprom $kw(-eeprom)
    }

    method fixed_columns_units {} {
        return [list $COLUMNS $UNITS]
    }

    # One request to sensor device
    #   ex.: request REEPROM ADDR 0x00; # XXX 0x00 but not 0 !!!
    # XXX Should be call serial listen -on before! To get read value, use
    # $_proto unpack CMD $_request_return
    protected method _request {cmdname args} {
        set nbytes [$_proto get $cmdname -resplen]
        set cmddef [join [$_proto get $cmdname -def] "\n"]
        # substitute with args
        foreach {argname argval} $args {
            set $argname $argval
        }
        set cmddef [subst $cmddef]
        $_serial expect $nbytes $cmddef
        return [$_serial read -nb]
    }

    # once polling sensor (but with 4 requests)
    # XXX serial listen -on should be call before do this proc
    protected method _poll_once {} {
        catch {
            set T [clock milliseconds]
            foreach cmdname {GETACC GETMAG GETHEAD GETTILT} {
                set respbuf [$this _request $cmdname]
                set resp($cmdname) [$_proto unpack $cmdname $respbuf]
            }

            # already unpacked but not physical values
            set rawvalues [list \
                {*}$resp(GETHEAD) \
                {*}$resp(GETACC) \
                {*}$resp(GETMAG) \
                [lindex $resp(GETTILT) 2]]

            # XXX not sure about updates
            update
            $this notify_all data $rawvalues
            update
        }
    }

    # Polling, possible in loop. Has options:
    # -loop - infinite loop of polling
    # -loop N - loop N times polling
    # -loop stop|cancel - stop looping
    protected method _poll args {
        array set kw {}
        myutl::proc_opts {} kw $args

        if {[array get kw "-loop"] eq ""} {
            # no loop, run only once
            if {$_looping} {
                error "Loop polling is run already"
            }
            $this notify_all run $COLUMNS $UNITS
            $this _poll_once
            $this notify_all stop

        } elseif {$kw(-loop) eq "stop" || $kw(-loop) eq "cancel"} {
            if {!$_looping} {
                error "Loop polling is not running"
            }
            set _cancel_loop 1

        } elseif {$kw(-loop) eq "Y"} {
            if {$_looping} {
                error "Loop polling is run already"
            }
            set _looping 1
            $this notify_all run $COLUMNS $UNITS
            while {!$_cancel_loop} {
                $this _poll_once
            }
            # occurs while breaking
            set _looping 0
            set _cancel_loop 0
            $this notify_all stop
            puts "Canceled polling"

        } elseif {[string is integer $kw(-loop)]} {
            if {$_looping} {
                error "Loop polling is run already"
            }
            set _looping 1
            $this notify_all run $COLUMNS $UNITS
            for {set i 0} {$i<$kw(-loop)} {incr i} {
                if {$_cancel_loop} { break }
                $this _poll_once
            }
            # for ended
            set _looping 0
            set _cancel_loop 0
            $this notify_all stop
            puts "Canceled polling"

        } else {
            error "Should be -loop, -loop N"
        }
    }

    #--------------------- users methods: -------------------------
    # args like _* versions of procs
    #--------------------------------------------------------------

    method request args {
        # One request to sensor device:
        #   request REEPROM ADDR 0x00; # 0x00 but not 0 !
        # Should be call serial listen -on before!


        # XXX: Need requests since polling!
        # Its not dangerous.
        #if {$_looping} {
            #error "Loop polling is run already"
        #}

        if {[$_serial listened]} {
            return [$this _request {*}$args]
        } else {
            $_serial listen -on
            set ret [$this _request {*}$args]
            $_serial listen -off
            return $ret
        }
    }

    method poll args {
        # Polling, possible in loop. Has options:
        #   -loop - infinite loop of polling
        #   -loop N - loop N times polling
        #   -loop stop|cancel - stop looping


        # doesnt need to check _looping here bcz _poll does it self
        # and bcz it's possible to call "poll" twise - "poll -loop stop"
        if {[$_serial listened]} {
            return [$this _poll {*}$args]
        } else {
            $_serial listen -on
            set ret [$this _poll {*}$args]
            $_serial listen -off
            return $ret
        }
    }

    method get_op_mode1 {{form "-dec"}} {
        # Get OPMODE1 register. Forms are form of output: -hex/-dec/-bin/-txt
        #   -hex - like 0x0F
        #   -dec - like 15
        #   -bin - like 0b00001111
        #   -txt - text decription


        $_serial listen -on
        set respbuf [$this _request OP_MODE1]
        $_serial listen -off
        set byte [$_proto unpack OP_MODE1 $respbuf]
        # byte is decimal string representation, lets transform to 0b11010...
        binary scan [binary format c $byte] B* byte
        set byte "0b$byte"
        switch -- $form {
            "-hex" { return [format 0x%02X $byte] }
            "-dec" { return [format %d $byte] }
            "-bin" { return $byte }
            "-txt" {
                set bitsdef {
                    "7: Calculating compass data"        { 0b10000000 YES }
                    "6: Calculating calibration offsets" { 0b01000000 YES }
                    "5: IIR Heading Filter used"         { 0b00100000 YES }
                    "4: Run Mode"                        { 0b00010000 YES }
                    "3: Standby Mode"                    { 0b00001000 YES }
                    "2: Upright Front Orientation"       { 0b00000100 YES }
                    "1: Upright Edge Orientation"        { 0b00000010 YES }
                    "0: Level Orientation"               { 0b00000001 YES }
                }
                return [join [myutl::bitsdescr $bitsdef $byte] "\n"]
            }
        }
    }

    method get_op_mode2 {{form "-dec"}} {
        # Get OPMODE2 register. Forms are form of output: -hex/-dec/-bin/-txt
        #   -hex - like 0x0F
        #   -dec - like 15
        #   -bin - like 0b00001111
        #   -txt - text decription


        set resp [$_eeprom read OP_MODE2]
        # byte is decimal string representation, lets transform to 0b11010...
        binary scan [binary format c $resp] B* byte
        set byte "0b$byte"
        switch -- $form {
            "-hex" { return [format 0x%02X $byte] }
            "-dec" { return [format %d $byte] }
            "-bin" { return $byte }
            "-txt" {
                # TODO add "Reserved" with testing on all bits are 0 (after TODO in bitsdescr)
                set bitsdef {
                    "Measurement Rate" { 0b00000001 5Hz 0b00000010 10Hz 0b00000011 INCORRECT }
                }
                return [join [myutl::bitsdescr $bitsdef $byte 1Hz] "\n"]
            }
        }
    }

    # TODO better mode managment, may be via -mode option? Or ensemble command?

    method enter_mode {mode} {
        # Enter to mode, mode is {CALIBR|RUN|STANDBY|SLEEP}


        switch -- $mode {
            "CALIBR" {
                $_serial listen -on
                $this _request ENTER_CALIBR_MODE
                $_serial listen -off
            }
            "RUN" {
                $_serial listen -on
                $this _request ENTER_RUN_MODE
                $_serial listen -off
            }
            "STANDBY" {
                $_serial listen -on
                $this _request ENTER_STANDBY_MODE
                $_serial listen -off
            }
            "SLEEP" {
                $_serial listen -on
                $this _request ENTER_SLEEP_MODE
                $_serial listen -off
            }
            default {
                error "Mode should be one of CALIBR, RUN, STANDBY, SLEEP"
            }
        }
    }

    method exit_mode {mode} {
        # Exit from mode, mode is {CALIBR|SLEEP}


        switch -- $mode {
            "CALIBR" {
                $_serial listen -on
                $this _request EXIT_CALIBR_MODE
                $_serial listen -off
            }
            "SLEEP" {
                $_serial listen -on
                $this _request EXIT_SLEEP_MODE
                $_serial listen -off
            }
            default {
                error "Mode should be one of CALIBR, SLEEP"
            }
        }
    }

    # TODO UI for chip orientation (with images from Datasheet)

    # set orientation of the chip. When chip stay on the table you see labels
    # "Honeywell" on the front panel (LEVEL orientation). As is convenion in
    # the algrebra there are X,Y,Z axis: Z is up of label, X is direction of
    # writing the label, Y is axes from bottom of front panel to up:
    #
    # +-----------+
    # |           |    ^ Y
    # | Honeywell |    |
    # |           |    0--------> X
    # +-----------+    Z
    #
    # To describe orientation imagine that first axes is direction of your eyes,
    # second - is direction when you turn the head to right and third is - when
    # you up the head. The argument orient may be: LEVEL or YXZ,
    # UPRIGHT_EDGE or UE or XZY, UPRIGHT_FRONT or UF or -ZYX
    method set_orient {orient} {
        # Set orientation of the sensor chip package. orient may be:
        # {LEVEL or YXZ, UPRIGHT_EDGE or UE or XZY, UPRIGHT_FRONT or UF or -ZYX}


        switch -- $orient {
            YXZ -
            LEVEL {
                $_serial listen -on
                $this _request LEVEL_ORIENT
                $_serial listen -off
            }

            UE -
            XZY -
            UPRIGHT_EDGE {
                $_serial listen -on
                $this _request UE_ORIENT
                $_serial listen -off
            }

            UF -
            -ZYX -
            UPRIGHT_FRONT {
                $_serial listen -on
                $this _request UF_ORIENT
                $_serial listen -off
            }

            default { error "orient should be one of LEVEL, UE, UF" }
        }
    }

    method set_hfilter {{value 1}} {
        # Turn-on filtering with this value (1..15: order of the filter);
        # 0 value turn-off filtering


        if {$value > 15 || $value < 0} {
            error "Filter order should be 0..15"
        } elseif {$value == 0} {
            #turn-off filtering
            set op_mode1 [$_eeprom read OP_MODE1]
            $_eeprom write OP_MODE1 [expr {$op_mode1 ^ 0b100000}]
            $_eeprom write FILTER 0
            # to have effect of changing EEPROM!
            reset_mcu
        } else {
            # else turn-on filtering
            set op_mode1 [$_eeprom read OP_MODE1]
            $_eeprom write FILTER $value
            $_eeprom write OP_MODE1 [expr {$op_mode1 | 0b100000}]
            # to have effect of changing EEPROM!
            reset_mcu
        }
    }

    method set_freq {{freq 5}} {
        # Set sampling frequency: 1, 5, 10


        set freqvalues {1 5 10}
        set freqvalue [lsearch $freqvalues $freq]
        if {-1 == $freqvalue} {
            error "Frequency should be 1, 5, 10 only"
        } else {
            # in OP_MODE2 register is only frequency - nothing else, so
            # no need to read its value before
            $_eeprom write OP_MODE2 $freqvalue
            # to have effect of changing EEPROM!
            reset_mcu
        }
    }

    method get_freq {} {
        # Get current sampling frequency


        return [lindex {1 5 10} [get_op_mode2]]
    }

    method reset_mcu {} {
        # Reset sensor MCU


        $_serial listen -on
        $this _request RESET_MCU
        $_serial listen -off
    }

}


# EEPROM 
# =====================================================================
itcl::class HMC6343EEPROM {
    protected variable _serial {}
    protected variable _proto {}
    protected variable _sensor {}
    protected variable _defs
    # insertion order
    protected variable _ordered_keys {}

    constructor {defs} {
        # Creates object. defs - definition of EEPROM cells


        foreach {addr len fact fmt valid name descr} $defs {
            set _defs($name) [list $addr $len $fact $fmt $valid $descr]
            lappend _ordered_keys $name
        }
    }

    # ex., ref -serial serial_objname -protocol protocol_objname
    method ref args {
        array set kw {}
        myutl::proc_opts {} kw $args
        # TODO check that -serial, -protocol are set!
        set _serial $kw(-serial)
        set _proto $kw(-protocol)
        set _sensor $kw(-sensor)
    }

    method cells {} {
        # Returns cells names


        #return [array names _defs]
        return $_ordered_keys
    }

    method get {name what} {
        # Returns info about named cell.
        # what is one of the:
        #   -addr - start address
        #   -len - number of bytes from this address
        #   -fact - factory default | --
        #   -fmt - format (like binary scan)
        #   -valid - validator
        #   -descr - description


        set celldef $_defs($name)
        switch -nocase $what {
            "-addr"      { return [lindex $celldef 0] }
            "-len"       { return [lindex $celldef 1] }
            "-fact"      { return [lindex $celldef 2] }
            "-fmt"       { return [lindex $celldef 3] }
            "-valid"     { return [lindex $celldef 4] }
            "-descr"     { return [lindex $celldef 5] }
            "-all"       { return $celldef }
        }
    }

    method read {addr} {
        # Reads data from EEPROM cell.
        # addr may be integer (0x00|0, or cell name). When addr is integer,
        # reads one address, when is cell name, then reads all addresses of
        # this named entry


        if {[string is integer $addr]} {
            # integer - address
            set respbuf [$_sensor request REEPROM ADDR [format 0x%02X $addr]]
            return [$_proto unpack REEPROM $respbuf]
        } else {
            # not integer - not address - name of cell
            set cell_name $addr

            set addr [$this get $cell_name -addr]
            set len [$this get $cell_name -len]
            set fmt [$this get $cell_name -fmt]
            set respbuf ""
            for {set i 0} {$i < $len} {incr i} {
                set a [format 0x%02X [expr {$addr + $i}]]
                lappend respbuf [$_sensor request REEPROM ADDR $a]
            }
            set respbuf [join $respbuf ""]
            binary scan $respbuf $fmt res
            return $res
        }
    }

    method write {addr value} {
        # Writes data into cell.
        # addr is integer or cell name. When is the integer, write
        # only into this address, when is the cell name, writes
        # into several addresses (of this named cell)


        # reverse bcz of LSB,MSB (LittleEndian BYTE order)
        # FOR DEBUG
        #::serial configure -simulate 1

        if {[string is integer $addr]} {
            # integer - address
            $_sensor request WEEPROM \
                ADDR [format 0x%02X $addr] \
                DATA [format 0x%02X $value]
        } else {
            # not integer - not address - name of cell
            set cell_name $addr
            set addr [$this get $cell_name -addr]
            set len [$this get $cell_name -len]
            set fmt [$this get $cell_name -fmt]
            # from value to binary buffer of value then to string of hex
            # like ff0099...
            binary scan [binary format $fmt $value] H* bytes
            # split into 2 chars: ff 00 99...
            set bytes [regexp -all -inline .. $bytes]
            if {[llength $bytes] != $len} {
                error "value $value is out of bounds. Should be $len bytes"
            }
            foreach byte $bytes {
                set a [format 0x%02X $addr]
                set d "0x$byte"
                $_sensor request WEEPROM ADDR $a DATA $d
                incr addr
            }
        }
        #::serial configure -simulate 0
    }

    method edit {} {
        # Call UI editor of EEPROM cells


        [Uieeprom #auto] create
        return; # to avoid putting in console returned value of create
    }

    method save {fname} {
        # Saves EEPROM content to CSV file fname


        set fid [open $fname w]
        catch {
            foreach cellname [$this cells] {
                set cellvalue [$this read $cellname]
                chan puts $fid "$cellname;$cellvalue"
            }
        }
        chan close $fid
    }

    method load {fname {reset ""}} {
        # Loads EEPROM content from CSV file, early saved by save method.
        # If reset is "-reset", then reset MCU after loading (to apply
        # EEPROM setup)


        set fid [open $fname r]
        catch {
            while 1 {
                chan gets $fid line
                if {$line eq ""} { break }
                set line [split $line ";"]
                set cellname [string trim [lindex $line 0]]
                set cellvalue [string trim [lindex $line 1]]
                set readonly [expr {[$this get $cellname -fact] eq "--"}]
                if {!$readonly} {
                    $this write $cellname $cellvalue
                }
            }
            if {$reset eq "-reset"} {
                $_sensor reset_mcu
            }
        }
        chan close $fid
    }
}



# Global objects 
# =====================================================================

# Bytes sequence is in rules of the USB-I2C protocol:
#   Command 0x53 (device request):
#
#       0x53 SLAVE_ADDR1 NBYTES BYTE0 BYTE1... 0x50
#
#         then tell how many bytes will reading:
#
#       0x53 SLAVE_ADDR2 NBYTES 0x50
#         and read from port...
#
#       SLAVE_ADDR1 and SLAVE_ADDR2 often are the different - one
#       for writing, another for reading from the same device (highest
#       bit of address is set/reset, for ex.).
# CMDNAME RESPLEN RESPFMT SCRIPT
HMC6343Protocol ::proto {
    GETACC    6 S3  { "$SERIAL send {0x53 0x32 0x01 0x40 0x50}"
        "after 1"
        "$SERIAL send {0x53 0x33 0x06 0x50}"
        "after 1" }
    GETMAG    6 S3  { "$SERIAL send {0x53 0x32 0x01 0x45 0x50}" 
        "after 1" 
        "$SERIAL send {0x53 0x33 0x06 0x50}"
        "after 1" } 
    GETHEAD   6 S3  { "$SERIAL send {0x53 0x32 0x01 0x50 0x50}" 
        "after 1" 
        "$SERIAL send {0x53 0x33 0x06 0x50}"
        "after 1" } 
    GETTILT   6 S3  { "$SERIAL send {0x53 0x32 0x01 0x55 0x50}" 
        "after 1" 
        "$SERIAL send {0x53 0x33 0x06 0x50}"
        "after 1" }
    REEPROM   1 c  { "$SERIAL send {0x53 0x32 0x02 0xE1 $ADDR 0x50}"
        "after 10"
        "$SERIAL send {0x53 0x33 0x01 0x50}"
        "after 10" }
    WEEPROM   0 -- { "$SERIAL send {0x53 0x32 0x03 0xF1 $ADDR $DATA 0x50}"
        "after 10" }
    OP_MODE1  1 c { "$SERIAL send {0x53 0x32 0x01 0x65 0x50}"
        "after 1"
        "$SERIAL send {0x53 0x33 0x01 0x50}"
        "after 1" }
    ENTER_CALIBR_MODE 0 -- { "$SERIAL send {0x53 0x32 0x01 0x71 0x50}"
        "after 1" }
    ENTER_RUN_MODE 0 -- { "$SERIAL send {0x53 0x32 0x01 0x75 0x50}"
        "after 1" }
    ENTER_STANDBY_MODE 0 -- { "$SERIAL send {0x53 0x32 0x01 0x76 0x50}"
        "after 1" }
    ENTER_SLEEP_MODE 0 -- { "$SERIAL send {0x53 0x32 0x01 0x83 0x50}"
        "after 1" }
    EXIT_CALIBR_MODE 0 -- { "$SERIAL send {0x53 0x32 0x01 0x7E 0x50}"
        "after 50" }
    EXIT_SLEEP_MODE 0 -- { "$SERIAL send {0x53 0x32 0x01 0x84 0x50}"
        "after 20" }
    LEVEL_ORIENT 0 -- { "$SERIAL send {0x53 0x32 0x01 0x72 0x50}"
        "after 1" }
    UE_ORIENT 0 -- { "$SERIAL send {0x53 0x32 0x01 0x73 0x50}"
        "after 1" }
    UF_ORIENT 0 -- { "$SERIAL send {0x53 0x32 0x01 0x74 0x50}"
        "after 1" }
    RESET_MCU 0 -- { "$SERIAL send {0x53 0x32 0x01 0x82 0x50}"
        "after 500"
    }
}

Serial ::serial

# FIXME validation of SLAVE_ADDRESS is buggy: cant enter nothing: treated incorrect by Tcl
# addr len factory-default fmt name description
HMC6343EEPROM ::eeprom {
    0x00 1 0x32 c {myutl::vintrng %P 16 246}       SLAVE_ADDRESS {I2C Slave Address}
    0x02 1 --   c {}                             SW_VERSION    {Software Version Number}
    0x04 1 0x11 c {myutl::vintrng %P 0 255}        OP_MODE1      {Operational Mode Register 1}
    0x05 1 0x01 c {myutl::vintrng %P 0 255}        OP_MODE2      {Operational Mode Register 2}
    0x06 2 --   s {}                             SN            {Device Serial Number}
    0x08 1 --   c {}                             DATE_YY       {Package Date Code: Last Two Digits of the Year}
    0x09 1 --   c {}                             DATE_WW       {Package Date Code: Fiscal Week}
    0x0A 2 0x00 s {myutl::vintrng %P -1800 1800}   DEVIATION     {Deviation Angle (+-1800) in tenths of a degree}
    0x0C 2 0x00 s {myutl::vintrng %P -1800 1800}   VARIATION     {Variation Angle (+-1800) in tenths of degree}
    0x0E 2 0x00 s {myutl::vintrng %P -32768 32767} X_OFFSET      {Hard-Iron Calibration Offset of the X-axis}
    0x10 2 0x00 s {myutl::vintrng %P -32768 32767} Y_OFFSET      {Hard-Iron Calibration Offset of the Y-axis}
    0x12 2 0x00 s {myutl::vintrng %P -32768 32767} Z_OFFSET      {Hard-Iron Calibration Offset of the Z-axis}
    0x14 2 0x00 s {myutl::vintrng %P 0 15}         FILTER        {Heading IIR Filter (0..15 typical)}
}

HMC6343 ::sensor
::sensor configure -datatype raw

Saver ::saver
::saver configure -datatypes {raw phys flt}

# bindings (references)
::proto ref -serial ::serial
::eeprom ref -serial ::serial -protocol ::proto -sensor ::sensor
::sensor ref -serial ::serial -protocol ::proto -eeprom ::eeprom
