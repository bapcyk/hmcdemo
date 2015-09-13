#******************************************************************************
#
#       Copyright:      2005-2010 Paul Obermeier (obermeier@tcl3d.org)
#
#                       See the file "Tcl3D_License.txt" for information on
#                       usage and redistribution of this file, and for a
#                       DISCLAIMER OF ALL WARRANTIES.
#
#       Module:         Tcl3D -> tcl3dOgl
#       Filename:       pkgIndex.tcl
#
#       Author:         Paul Obermeier
#
#       Description:    Tcl index file for the tcl3dOgl package.
#
#******************************************************************************

proc __tcl3dOglSourcePkgs { dir } {
    # Source the files from sub-module tcl3dOgl
    source [file join $dir tcl3dOglQuery.tcl]
    source [file join $dir tcl3dOglStateList.tcl]
    source [file join $dir tcl3dOglHelp.tcl]
    source [file join $dir tcl3dOglFormats.tcl]
    source [file join $dir tcl3dOglShaderUtil.tcl]

    load [file join $dir tcl3dOgl[info sharedlibextension]] tcl3dOgl

    source [file join $dir tcl3dShapesGlut.tcl]
    source [file join $dir tcl3dShapesGlus.tcl]
    # Note: This file must be loaded after the wrapped OGL library,
    # because of the redefined glMultiDrawElements function.
    source [file join $dir tcl3dOglUtil.tcl]

    # Source the file from former sub-module tcl3dDemoUtil
    source [file join $dir tcl3dDemoHeightMap.tcl]

    # Source the files from former sub-module tcl3dUtil
    source [file join $dir tcl3dGuiAutoscroll.tcl]
    source [file join $dir tcl3dGuiDirSelect.tcl]
    source [file join $dir tcl3dGuiWidgets.tcl]
    source [file join $dir tcl3dGuiConsole.tcl]
    source [file join $dir tcl3dGuiToolhelp.tcl]
    source [file join $dir tcl3dUtilColors.tcl]
    source [file join $dir tcl3dUtilImg.tcl]
    source [file join $dir tcl3dUtilInfo.tcl]
    source [file join $dir tcl3dUtilFile.tcl]
    source [file join $dir tcl3dUtilTrackball.tcl]
    source [file join $dir tcl3dUtilLogo.tcl]
    source [file join $dir tcl3dUtilCapture.tcl]
    source [file join $dir tcl3dVecMath.tcl]
    source [file join $dir tcl3dVector.tcl]
}

if {![package vsatisfies [package provide Tcl] 8.4]} {return}
package ifneeded tcl3dogl 0.5.0 "[list __tcl3dOglSourcePkgs $dir]"
