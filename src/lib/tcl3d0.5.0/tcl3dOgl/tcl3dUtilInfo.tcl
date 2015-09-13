#******************************************************************************
#
#       Copyright:      2005-2010 Paul Obermeier (obermeier@tcl3d.org)
#
#                       See the file "Tcl3D_License.txt" for information on
#                       usage and redistribution of this file, and for a
#                       DISCLAIMER OF ALL WARRANTIES.
#
#       Module:         Tcl3D -> tcl3dOgl
#       Filename:       tcl3dUtilInfo.tcl
#
#       Author:         Paul Obermeier
#
#       Description:    Tcl module to get Tcl3D related information:
#                       Version, extensions, state variables.
#
#******************************************************************************

###############################################################################
#[@e
#       Name:           tcl3dHavePackage - Check availability of a specific 
#                       Tcl3D package.
#
#       Synopsis:       tcl3dHavePackage { pkgName version }
#
#       Description:    pkgName : string
#                       version : string
#
#                       Return 1, if Tcl package "pkgName" is available in at 
#                       least version "version". Otherwise return 0. 
#
#                       Example: tcl3dHavePackage tcl3dcg 0.3.2
#                                checks availability of the tcl3dCg package in
#                                at least version 0.3.2.
#
#       See also:       tcl3d{SubPackage}GetVersion
#
###############################################################################

proc tcl3dHavePackage { pkgName version } {
    uplevel #0 [package unknown] [list $pkgName $version]
    foreach found [package versions $pkgName] {
        if {[package vsatisfies $found $version]} {
            return 1
        }
    }
    return 0
}

###############################################################################
#[@e
#       Name:           tcl3dGetLibraryInfo - Get library version of a Tcl3D
#                       module. 
#
#       Synopsis:       tcl3dGetLibraryInfo { pkgName }
#
#       Description:    pkgName : string
#
#                       Return the library version corresponding to supplied 
#                       Tcl3D package name "pkgName" as a string. If no version
#                       information is available, an empty string is returned.
#
#       See also:       tcl3dGetPackageInfo
#
###############################################################################

proc tcl3dGetLibraryInfo { pkgName } {
    set retVal ""
    switch $pkgName {
        "tcl3dcg"    { if { [info procs tcl3dCgGetVersion] ne "" } {
                           return [tcl3dCgGetVersion] 
                       }
                     }
        "tcl3dftgl"  { if { [info procs tcl3dFTGLGetVersion] ne "" } { 
                           return [tcl3dFTGLGetVersion]
                       }
                     }
        "tcl3dgl2ps" { if { [info procs tcl3dGl2psGetVersion] ne "" } {
                           return [tcl3dGl2psGetVersion]
                       }
                     }
        "tcl3dode"   { if { [info procs tcl3dOdeGetVersion] ne "" } {
                           return [tcl3dOdeGetVersion]
                       }
                     }
        "tcl3dogl"   { if { [info procs tcl3dOglGetVersion] ne "" } {
                           return [tcl3dOglGetVersion]
                       }
                     }
        "tcl3dosg"   { if { [info procs tcl3dOsgGetVersion] ne "" } {
                           return [tcl3dOsgGetVersion]
                       }
                     }
        "tcl3dsdl"   { if { [info procs tcl3dSDLGetVersion] ne "" } {
                           return [tcl3dSDLGetVersion]
                       }
                     }
    }
    return $retVal
}

###############################################################################
#[@e
#       Name:           tcl3dGetPackageInfo - Get Tcl3D package information.
#
#       Synopsis:       tcl3dGetPackageInfo {}
#
#       Description:    Return a list of sub-lists containing Tcl3D package 
#                       information. Each sub-list contains the name of the 
#                       sub-package, the availability flag (0 or 1), the 
#                       sub-package version as well as the version of the
#                       wrapped library.
#
#                       Example:
#                       {tcl3dcg 1 0.3.3 1.5.0015}     {tcl3ddemoutil 1 0.3.3 {}}
#                       {tcl3dftgl 1 0.3.3 2.1.2}      {tcl3dgauges 1 0.3.3 {}} 
#                       {tcl3dgl2ps 1 0.3.3 1.3.2}     {tcl3dode 1 0.3.3 0.7.0}
#                       {tcl3dogl 1 0.3.3 {APPLE-1.4}} {tcl3dsdl 1 0.3.3 1.2.9}
#                       {tcl3dtogl 1 0.3.3 {}}         {tcl3dutil 1 0.3.3 {}}
#
#                       Note: A Togl window (and therefore a graphics context)
#                             must have been created before issuing a call to
#                             this function.
#
#       See also:       tcl3dShowPackageInfo
#
###############################################################################

proc tcl3dGetPackageInfo {} {
    set msgList {}
    foreach name [lsort [array names ::__tcl3dPkgInfo "*,avail"]] {
        set pkg [lindex [split $name ","] 0]
        set libVersion [tcl3dGetLibraryInfo $pkg]
        lappend msgList [list $pkg $::__tcl3dPkgInfo($pkg,avail) \
                                   $::__tcl3dPkgInfo($pkg,version) \
                                   $libVersion]
    }
    return $msgList
}

###############################################################################
#[@e
#       Name:           tcl3dShowPackageInfo - Display package information. 
#
#       Synopsis:       tcl3dShowPackageInfo {}
#
#       Description:    Display the version info returned by 
#                       tcl3dGetPackageInfo in a toplevel window.
#
#                       Note: A Togl window (and therefore a graphics context)
#                             must have been created before issuing a call to
#                             this function.
#
#       See also:       tcl3dGetPackageInfo
#
###############################################################################

proc tcl3dShowPackageInfo {} {
    set tw .tcl3d:PkgInfoWin
    catch { destroy $tw }

    toplevel $tw
    wm title $tw "Tcl3D Packages"
    wm resizable $tw true true

    frame $tw.fr0 -relief sunken -borderwidth 1
    grid  $tw.fr0 -row 0 -column 0 -sticky nwse

    set pkgInfoList [tcl3dGetPackageInfo]
    set numPkgs [llength $pkgInfoList]

    set textId [tcl3dCreateScrolledText $tw.fr0 "" -wrap word -height $numPkgs]
    foreach pkgInfo $pkgInfoList {
        set msgStr "Package [lindex $pkgInfo 0]: [lindex $pkgInfo 2] [lindex $pkgInfo 3]\n"
        if { [lindex $pkgInfo 1] == 1} {
            set tag avail
        } else {
            set tag unavail
        }
        $textId insert end $msgStr $tag
    }
    $textId tag configure avail   -background green
    $textId tag configure unavail -background red
    $textId configure -state disabled

    # Create OK button
    frame $tw.fr1 -relief sunken -borderwidth 1
    grid  $tw.fr1 -row 1 -column 0 -sticky nwse
    button $tw.fr1.b -text "OK" -command "destroy $tw" -default active
    bind $tw.fr1.b <KeyPress-Return> "destroy $tw"
    pack $tw.fr1.b -side left -fill x -padx 2 -expand 1

    grid columnconfigure $tw 0 -weight 1
    grid rowconfigure    $tw 0 -weight 1

    bind $tw <Escape> "destroy $tw"
    bind $tw <Return> "destroy $tw"
    focus $tw
}

###############################################################################
#[@e
#       Name:           tcl3dHaveCg - Check availability of tcl3dCg module. 
#
#       Synopsis:       tcl3dHaveCg {}
#
#       Description:    Return 1, if the Cg library has been loaded successfully
#                       via the tcl3dCg module. Otherwise return 0.
#
#                       Note: This function is only available when loading Tcl3D
#                             via a "package require tcl3d".
#
#       See also:       tcl3dGetPackageInfo
#                       tcl3dCgGetVersion
#
###############################################################################

proc tcl3dHaveCg {} {
    return $::__tcl3dPkgInfo(tcl3dcg,avail)
}

###############################################################################
#[@e
#       Name:           tcl3dHaveSDL - Check availability of tcl3dSDL module.
#
#       Synopsis:       tcl3dHaveSDL {}
#
#       Description:    Return 1, if the SDL library has been loaded successfully
#                       via the tcl3dSDL module. Otherwise return 0.
#
#                       Note: This function is only available when loading Tcl3D
#                             via a "package require tcl3d".
#
#       See also:       tcl3dGetPackageInfo
#                       tcl3dSDLGetVersion
#
###############################################################################

proc tcl3dHaveSDL {} {
    return $::__tcl3dPkgInfo(tcl3dsdl,avail)
}

###############################################################################
#[@e
#       Name:           tcl3dHaveFTGL - Check availability of tcl3dFTGL module.
#
#       Synopsis:       tcl3dHaveFTGL {}
#
#       Description:    Return 1, if the FTGL library has been loaded successfully
#                       via the tcl3dFTGL module. Otherwise return 0.
#
#                       Note: This function is only available when loading Tcl3D
#                             via a "package require tcl3d".
#
#       See also:       tcl3dGetPackageInfo
#                       tcl3dFTGLGetVersion
#
###############################################################################

proc tcl3dHaveFTGL {} {
    return $::__tcl3dPkgInfo(tcl3dftgl,avail)
}

###############################################################################
#[@e
#       Name:           tcl3dHaveOde - Check availability of tcl3dOde module.
#
#       Synopsis:       tcl3dHaveOde {}
#
#       Description:    Return 1, if the ODE library has been loaded successfully
#                       via the tcl3dOde module. Otherwise return 0.
#
#                       Note: This function is only available when loading Tcl3D
#                             via a "package require tcl3d".
#
#       See also:       tcl3dGetPackageInfo
#                       tcl3dOdeGetVersion
#
###############################################################################

proc tcl3dHaveOde {} {
    return $::__tcl3dPkgInfo(tcl3dode,avail)
}

###############################################################################
#[@e
#       Name:           tcl3dHaveOsg - Check availability of tcl3dOsg module. 
#
#       Synopsis:       tcl3dHaveOsg {}
#
#       Description:    Return 1, if the OSG library has been loaded successfully
#                       via the tcl3dOsg module. Otherwise return 0.
#
#                       Note: This function is only available when loading Tcl3D
#                             via a "package require tcl3d".
#
#       See also:       tcl3dGetPackageInfo
#                       tcl3dOsgGetVersion
#
###############################################################################

proc tcl3dHaveOsg {} {
    return $::__tcl3dPkgInfo(tcl3dosg,avail)
}

###############################################################################
#[@e
#       Name:           tcl3dHaveGl2ps - Check availability of tcl3dGl2ps module.
#
#       Synopsis:       tcl3dHaveGl2ps {}
#
#       Description:    Return 1, if the GL2PS library has been loaded successfully
#                       via the tcl3dGl2ps module. Otherwise return 0.
#
#                       Note: This function is only available when loading Tcl3D
#                             via a "package require tcl3d".
#
#       See also:       tcl3dGetPackageInfo
#                       tcl3dGl2psGetVersion
#
###############################################################################

proc tcl3dHaveGl2ps {} {
    return $::__tcl3dPkgInfo(tcl3dgl2ps,avail)
}
