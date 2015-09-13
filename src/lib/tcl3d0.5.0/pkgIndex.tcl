#******************************************************************************
#
#       Copyright:      2005-2010 Paul Obermeier (obermeier@tcl3d.org)
#
#                       See the file "Tcl3D_License.txt" for information on
#                       usage and redistribution of this file, and for a
#                       DISCLAIMER OF ALL WARRANTIES.
#
#       Module:         Tcl3D
#       Filename:       pkgIndex.tcl
#
#       Author:         Paul Obermeier
#
#       Description:    Tcl index file for the Tcl3D package.
#
#******************************************************************************

# All Tcl3D packages need Tcl/Tk 8.4
if {![package vsatisfies [package provide Tcl] 8.4]} {return}

# Extend the auto_path to make Tcl3D subpackages available
if {[lsearch -exact $::auto_path $dir] == -1} {
    lappend ::auto_path $dir
}

proc __tcl3dSourcePkgs { dir } {
    set subPkgs [list tcl3dogl tcl3dgauges \
                      tcl3dcg  tcl3dftgl tcl3dsdl tcl3dgl2ps tcl3dode tcl3dosg]
    foreach pkg $subPkgs {
        set retVal [catch {package require $pkg} ::__tcl3dPkgInfo($pkg,version)]
        set ::__tcl3dPkgInfo($pkg,avail) [expr !$retVal]
    }
    package provide tcl3d 0.5.0
}

package ifneeded tcl3d 0.5.0 "[list __tcl3dSourcePkgs $dir]"
