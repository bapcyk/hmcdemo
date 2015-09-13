#******************************************************************************
#
#       Copyright:      2005-2010 Paul Obermeier (obermeier@tcl3d.org)
#
#                       See the file "Tcl3D_License.txt" for information on
#                       usage and redistribution of this file, and for a
#                       DISCLAIMER OF ALL WARRANTIES.
#
#       Module:         Tcl3D -> tcl3dGauges
#       Filename:       pkgIndex.tcl
#
#       Author:         Paul Obermeier
#
#       Description:    Tcl index file for the tcl3dGauges package.
#
#******************************************************************************

proc __tcl3dGaugesSourcePkgs { dir } {
    source [file join $dir gaugeImgs.tcl]
    source [file join $dir gaugeBase64.tcl]
    source [file join $dir airspeed.tcl]
    source [file join $dir altimeter.tcl]
    source [file join $dir compass.tcl]
    source [file join $dir tiltmeter.tcl]
}

if {![package vsatisfies [package provide Tcl] 8.4]} {return}
# All modules are exported as package tcl3dgauges
package ifneeded tcl3dgauges 0.5.0 "[list __tcl3dGaugesSourcePkgs $dir]"
