#lappend auto_path {*}{lib lib\Tcl3d0.5.0 lib\mym}
package require starkit
#lappend auto_path {*}{lib lib\Tcl3d0.5.0}
starkit::startup
# equals:
#lappend auto_path {*}[file join $starkit::topdir lib/app-hmcdemo/Tcl3d0.5.0]
starkit::autoextend [file join $starkit::topdir lib/app-hmcdemo/Tcl3d0.5.0]
package require Tk
package require myutl
package require mydoc
package require mylsn
package require myser
package require mycons
package require mysens
package require ui_main
package require starkit

namespace import mydoc::*

# FIXME or another way to show errors?
proc bgerror { msg } {
    tk_messageBox -icon error -type ok -message "Error: $msg\n\n$::errorInfo"
    exit
}

# TODO add command doc (to help on proc docstrings, help file via WebBrowser
# TODO add about command/dialog with icon

#proc kit_path {p} {
    #set ret [file join $starkit::topdir $p]
    #return [file normalize $ret]
#}

proc set_icons {} {
    #global APPICON
    # tclkit.ico placed where is it is automatic set as app ico
    # (for explorer) but also I set up it's as window icon
    #set APPICON [kit_path "../../tclkit.ico"] ;# needed for pgdlg window
    #wm iconbitmap . $APPICON
    image create photo .imgf -format GIF -file [myutl::kit_path f.gif]
    image create photo .imgt -format GIF -file [myutl::kit_path t.gif]
    image create photo .imgs -format GIF -file [myutl::kit_path s.gif]
    image create photo .imgi -format GIF -file [myutl::kit_path i.gif]
}

proc script {args} {
    # The same as source but with variable binding:
    #   script some.tcl A 1 B 2


    set scr [lindex $args 0]
    set vars [lrange $args 1 end]
    foreach {n v} $vars {
        set $n $v
    }
    source $scr
    foreach {n v} $vars {
        unset $n
    }
}

proc main {} {
    #set SCRIPT [info script]

    # First icons, to have app icon in possible error in XXX-1
    # FIXME
    set_icons

    # If .lock dir exists, say about it and exit
    #if {[file exists .lock]} {
        #wm withdraw .
        #update idletasks
        # XXX-1
        #tk_messageBox -title Error -icon error -message "Already is runned"
        #exit 1
    #}

    # Setup myexit handler on exit
    #trace add execution exit enterstep myexit
    #wm protocol . WM_DELETE_WINDOW myexit
    # Lock (once run)
    #file mkdir .lock


    #set dlg [toplevel .topLevel -class Dialog]
    #set root ""
    #frame $root.fr -container 1 
    #pack $root.fr -fill both -expand 1
    #set cons [mycons::ConsoleInit $root.fr]

    Uimain uimain
    uimain create

    # bind listeners
    ::sensor   add_listener ::phvals
    ::phvals   add_listener ::lpfilter
    ::phvals   add_listener ::lpfir
    ::phvals   add_listener ::uicells
    ::lpfilter add_listener ::ui3d
    ::phvals   add_listener ::saver
    ::phvals   add_listener ::cintr
    ::phvals   add_listener ::dsintr
    #::lpfilter    add_listener ::dsintr
    ::dsintr   add_listener ::uiplot
    #::cintr    add_listener ::uiplot

    #mycons::EmbeddedConsoleDemo ""
}

#proc myexit {{errno 0}} {
    #tk_messageBox -message QUIT
    #file delete -force .lock
    #destroy .
    #exit $errno
#}

# main entry
if {[catch {main} res]} {
    wm withdraw .
    update idletasks
    tk_messageBox -title Error -icon error -message "Error: $res"
    exit 1
}
