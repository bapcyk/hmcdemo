# Generate hlp.rst file with references to all classes, its methods
# and procedures with docstrings (see lib/mydoc.tcl)

package require starkit
starkit::startup
starkit::autoextend [file join $starkit::topdir lib/app-hmcdemo/Tcl3d0.5.0]
package require myutl
set packages [glob -directory lib -tails "*.tcl"]
foreach pkg $packages {
    set pkg [regsub {.tcl$} $pkg ""]
    if {$pkg ne "pkgIndex"} {
        package require $pkg
    }
}
mydoc::_genrst hlp.rst
exit 0
