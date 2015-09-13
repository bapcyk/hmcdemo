package provide ui_eeprom 1.0

package require Tk
package require Ttk
package require Itcl
package require myutl
package require mysens
#package require BWidget

itcl::class Uieeprom {

    protected variable _vars
    protected method _create {{w ""}}
    # set _vars item
    protected method _setvar {cellname value}
    # get _vars item
    protected method _getvar {cellname}
    # write to EEPROM from entry
    protected method _write_cell {cellname}
    # read from EEPROM to entry
    protected method _read_cell {cellname}

    method create {{w ""}}
}

itcl::body Uieeprom::create {{w ""}} {
    if {[winfo exists $w._eepromf]} {
        error "EEPROM editor is running already"
    }

    #return [$this _create $w]
    if {[catch {set ret [$this _create $w]}]} {
        if {[winfo exists $w._eepromf]} {
            destroy $w._eepromf
        }
        error "Error occurs! Check connection"
    }
    return $ret
}

itcl::body Uieeprom::_getvar {cellname} {
    return $_vars($cellname)
}

itcl::body Uieeprom::_setvar {cellname value} {
    set _vars($cellname) $value
}

itcl::body Uieeprom::_write_cell {cellname} {
    set ans [tk_messageBox -type yesno -title Question -icon question \
    -message "This operation will rewrite EEPROM cell of the chip! Are you sure?"]
    if {$ans == "no"} { return }

    set value [string trim [$this _getvar $cellname]]
    if {$value eq ""} {
        tk_messageBox -icon warning -title Warning -message "Empty values are denied!"
        return
    }
    ::eeprom write $cellname $value
}

itcl::body Uieeprom::_read_cell {cellname} {
    $this _setvar $cellname [::eeprom read $cellname]
}

itcl::body Uieeprom::_create {{w ""}} {
    set me [toplevel $w._eepromf -padx 5 -pady 5]

    set row 0
    # TODO add frame with 3 labels-links: 0x0F, 0b00001111, 15 -
    # to switch mode of in/out and validation: hex, bin, dec
    #set msg [ttk::label $me.msg -justify left -text "Use values like 0x0F, 0b00001111, 15"]
    set msg [ttk::label $me.msg -justify left -text "Use decimal values"]
    grid $msg -row $row -column 0 -columnspan 4 -sticky we -pady 5

    # here bcz hint widget is used in foreach
    set hint [ttk::label $me.hint -width 50 -text Hint:]

    incr row
    foreach cellname [::eeprom cells] {
        # cellname but for windows names (lower-case)
        set cellvalue [::eeprom read $cellname]
        set _vars($cellname) $cellvalue
        set wcellname [string tolower $cellname]
        set labname "$me.${wcellname}l"
        set entname "$me.${wcellname}e"

        set readonly [expr {[::eeprom get $cellname -fact] eq "--"}]
        set lab [ttk::label $labname -text $cellname:]
        set ent [ttk::entry $entname -textvariable [itcl::scope _vars($cellname)]]
        $ent configure -validate all -validatecommand [::eeprom get $cellname -valid]

        # set hint callback for $ent
        set hintmsg "[::eeprom get $cellname -len]bytes, [::eeprom get $cellname -descr]"
        bind $ent <Any-Enter> "$hint configure -text \"Hint: $hintmsg\""
        # TODO add on focus entering too
        #bind $ent <Any-Leave> "$hint configure -text Hint:"

        # TODO use icons instead of text
        # TODO add button for reset to factorial default value
        set btnPUT [ttk::button $me.${wcellname}putbtn -text put -width 3 \
            -command "[itcl::code $this _write_cell $cellname]"]
        set btnGET [ttk::button $me.${wcellname}getbtn -text get -width 3 \
            -command "[itcl::code $this _read_cell $cellname]"]

        grid $lab -row $row -column 0 -sticky e
        grid $ent -row $row -column 1 -sticky we

        grid $btnPUT -row $row -column 2 -sticky we
        grid $btnGET -row $row -column 3 -sticky we

        if {$readonly} {
            # if no factory value so it's read-only cell (thees cells are
            # like serial number, date...)
            $ent configure -state readonly
            $btnPUT configure -state disabled
        }
        # 1st column will be stretchable
        grid columnconfigure $me 1 -weight 1
        incr row
    }
    incr row

    grid $hint -row $row -column 0 -columnspan 4 -sticky we -pady 10
    incr row

    set sep [ttk::separator $me.sep]
    grid $sep -row $row -column 0 -columnspan 4 -sticky we -pady 10
    incr row

    set btn [ttk::button $me.closebtn -text "Close" -width 10 -command "destroy $me"]
    grid $btn -row $row -column 0 -sticky s -columnspan 4

    wm title $me "EEPROM editor"
    wm resizable $me 0 0
}
