#******************************************************************************
#
#       Copyright:      2007-2010 Paul Obermeier (obermeier@tcl3d.org)
#
#                       See the file "Tcl3D_License.txt" for information on
#                       usage and redistribution of this file, and for a
#                       DISCLAIMER OF ALL WARRANTIES.
#
#       Module:         Tcl3D -> tcl3dOgl
#       Filename:       tcl3dOglQuery.tcl
#
#       Author:         Paul Obermeier
#
#       Description:    Tcl module with query procedures related to
#                       the OpenGL module.
#
#******************************************************************************

###############################################################################
#[@e
#       Name:           tcl3dOglGetVersion - Get OpenGL version string.
#
#       Synopsis:       tcl3dOglGetVersion {}
#
#       Description:    Return the version string of the wrapped OpenGL library.
#                       The version string does not have a specific format.
#                       It depends on the vendor of the OpenGL implementation.
#                       Some examples:
#                       1.4 APPLE-1.6.18
#                       2.1.2 NVIDIA 173.14.12
#
#                       If no OpenGL context has been established (i.e. a Togl
#                       window has not been created), the function returns an 
#                       empty string.
#
#       See also:       tcl3dOglGetVersions
#                       tcl3dGetLibraryInfo
#                       tcl3dOglHaveVersion
#
###############################################################################

proc tcl3dOglGetVersion {} {
    if { [info commands glGetString] ne "" } {
        return [glGetString GL_VERSION]
    } else {
        return ""
    }
}

###############################################################################
#[@e
#       Name:           tcl3dOglGetVersionNumber - Get OpenGL version number.
#
#       Synopsis:       tcl3dOglGetVersionNumber {}
#
#       Description:    Return the OpenGL version number as a dictionary
#                       containing the following elements:
#                       major: int
#                       minor: int
#                       patch: int
#
#                       If a component of the OpenGL version number is not
#                       supplied by the OpenGL driver, the corresponding element
#                       is set to -1.
#
#                       Note: The version number of the OpenGL implementation
#                             is extracted from the string returned by calling
#                             "glGetString GL_VERSION". As some vendors format
#                             the version in an unusual way, this function may
#                             not work correctly on all platforms.
#
#                       If no OpenGL context has been established (i.e. a Togl
#                       window has not been created), the function returns an 
#                       empty dictionary.
#
#       See also:       tcl3dOglGetVersions
#                       tcl3dOglGetVersion
#                       tcl3dOglHaveVersion
#
###############################################################################

proc tcl3dOglGetVersionNumber {} {
    set versionStr [tcl3dOglGetVersion]
    if { $versionStr eq "" } {
        return [dict]
    }

    if {3 != [scan $versionStr "%d.%d.%d" majorHave minorHave patchHave] } {
        set patchHave -1
        if {2 != [scan $versionStr "%d.%d" majorHave minorHave] } {
            set minorHave -1
            if {1 != [scan $versionStr "%d" majorHave] } {
                set majorHave -1
            }
        }
    }
    dict set versionDict "major" $majorHave
    dict set versionDict "minor" $minorHave
    dict set versionDict "patch" $patchHave
    return $versionDict
}

###############################################################################
#[@e
#       Name:           tcl3dOglGetGlewVersion - Get GLEW version string.
#
#       Synopsis:       tcl3dOglGetGlewVersion {}
#
#       Description:    Return the version string of the GLEW wrapper library.
#                       The version is returned as "Major.Minor.Patch".
#
#                       If no OpenGL context has been established (i.e. a Togl
#                       window has not been created), the function returns an 
#                       empty string.
#
#       See also:       tcl3dOglGetVersion
#                       tcl3dOglGetVersions
#
###############################################################################

proc tcl3dOglGetGlewVersion {} {
    if { [info commands glewGetString] ne "" } {
        # 1 corresponds to GLEW_VERSION.
        # GLEW_* defines and variables are not wrapped.
        return [glewGetString 1]
    } else {
        return ""
    }
}

###############################################################################
#[@e
#       Name:           tcl3dOglHaveFunc - Check availability of a specific
#                       OpenGL function.
#
#       Synopsis:       tcl3dOglHaveFunc { glFuncName }
#
#       Description:    glFuncName : string
#
#                       Return 1, if the OpenGL function "glFuncName" is
#                       provided by the underlying OpenGL implementation.
#                       Otherwise return 0. 
#                   
#                       Example: tcl3dOglHaveFunc glGenQueriesARB
#                                checks the availability of the occlussion query
#                                related ARB extension function glGenQueriesARB.
#
#                       Note: A Togl window (and therefore a graphics context)
#                             must have been created before issuing a call to
#                             this function.
#
#       See also:       tcl3dOglHaveExtension
#
###############################################################################

proc tcl3dOglHaveFunc { glFuncName } {
    set checkCmd [format "__%sAvail" $glFuncName]
    if { [info commands $checkCmd] eq "" } {
        if { [info commands $glFuncName] eq "" } {
            return 0
        } else { 
            return 1
        }
    } else {
        return [$checkCmd]
    }
}

###############################################################################
#[@e
#       Name:           tcl3dOglHaveExtension - Check availability of a specific
#                       OpenGL extension.
#
#       Synopsis:       tcl3dOglHaveExtension { extensionName }
#
#       Description:    extensionName : string
#
#                       Return 1, if the OpenGL extension "extensionName" is
#                       provided by the underlying OpenGL implementation.
#                       Otherwise return 0. 
#                   
#                       Example: tcl3dOglHaveExtension GL_ARB_multitexture
#                                checks the availability of the multitexturing
#                                extension.
#
#                       Note: A Togl window (and therefore a graphics context)
#                             must have been created before issuing a call to
#                             this function.
#
#       See also:       tcl3dOglGetExtensions
#
###############################################################################

proc tcl3dOglHaveExtension { extensionName } {
    foreach glInfo [tcl3dOglGetExtensions] {
        set found [lsearch -exact [lindex $glInfo 1] $extensionName]
        if { $found >= 0 } {
            return 1
        }
    }
    return 0
}

# OBSOLETE tcl3dHaveExtension 0.3.3 tcl3dOglHaveExtension
proc tcl3dHaveExtension { extensionName } {
    return [tcl3dOglHaveExtension $extensionName]
}

###############################################################################
#[@e
#       Name:           tcl3dOglHaveVersion - Check availability of a specific
#                       OpenGL version.
#
#       Synopsis:       tcl3dOglHaveVersion { majorWanted { minorWanted -1 }
#                                           { patchWanted -1 } }
#
#       Description:    majorWanted : int
#                       minorWanted : int
#                       patchWanted : int
#
#       Description:    Return 1, if the OpenGL version offered by the driver
#                       is equal to or greater than the supplied
#                       major, minor and patch level numbers.
#                       Otherwise return 0.
#
#                       Note: The version number of the OpenGL implementation
#                             is extracted from the string returned by calling
#                             "glGetString GL_VERSION". As some vendors format
#                             the version in an unusual way, this function may
#                             not work correctly on all platforms.
#
#                       Note: A Togl window (and therefore a graphics context)
#                             must have been created before issueing a call to
#                             this function.
#
#       See also:       tcl3dOglGetVersions
#
###############################################################################

proc tcl3dOglHaveVersion { majorWanted { minorWanted -1 } { patchWanted -1 } } {
    set versionDict [tcl3dOglGetVersionNumber]
    set majorHave [dict get $versionDict "major"]
    set minorHave [dict get $versionDict "minor"]
    set patchHave [dict get $versionDict "patch"]

    if { $majorHave > $majorWanted } {
        return 1
    } elseif { $majorHave < $majorWanted } {
        return 0
    } else {
        # Major versions are identical.
        if { $minorHave > $minorWanted || $minorHave < 0 } {
            return 1
        } elseif { $minorHave < $minorWanted } {
            return 0
        } else {
            # Minor versions are identical.
            if { $patchHave >= $patchWanted || $patchHave < 0 } {
                return 1
            } else {
                return 0
            }
        }
    }
}

# OBSOLETE tcl3dHaveVersion 0.3.3 tcl3dOglHaveVersion
proc tcl3dHaveVersion { majorWanted { minorWanted 0 } { patchWanted 0 } } {
    return [tcl3dOglHaveVersion $majorWanted $minorWanted $patchWanted]
}

###############################################################################
#[@e
#       Name:           tcl3dOglGetVersions - Get OpenGL version information.
#
#       Synopsis:       tcl3dOglGetVersions {}
#
#       Description:    Return OpenGL version information as a list of 
#                       (key,value) pairs. 
#                       Keys are the following OpenGL version types: 
#                       GL_VENDOR, GL_RENDERER, GL_VERSION, GLU_VERSION,
#                       GL_SHADING_LANGUAGE_VERSION, GLEW_VERSION.
#                       Values are the corresponding version strings as returned
#                       by the underlying OpenGL implementation.
#
#                       Example:
#                       {GL_VENDOR {Intel Inc.}}
#                       {GL_RENDERER {Intel GMA 950 OpenGL Engine}}
#                       {GL_VERSION {1.2 APPLE-1.4.56}}
#                       {GLU_VERSION {1.3 MacOSX}}
#
#                       Note: A Togl window (and therefore a graphics context)
#                             must have been created before issuing a call to
#                             this function.
#
#       See also:       tcl3dOglHaveVersion
#                       tcl3dOglGetExtensions
#
###############################################################################

proc tcl3dOglGetVersions {} {
    set versList {}

    set version [glGetString GL_VENDOR]
    lappend versList [list GL_VENDOR $version]
    set version [glGetString GL_RENDERER]
    lappend versList [list GL_RENDERER $version]
    set version [glGetString GL_VERSION]
    lappend versList [list GL_VERSION $version]
    if { [info exists ::GLU_VERSION_1_1] } {
        set version [gluGetString GLU_VERSION]
        lappend versList [list GLU_VERSION $version]
    } else {
        lappend versList [list GLU_VERSION "1.0"]
    }
    if { [info global GL_SHADING_LANGUAGE_VERSION] ne "" } {
        set version [glGetString GL_SHADING_LANGUAGE_VERSION]
        lappend versList [list GL_SHADING_LANGUAGE_VERSION $version]
    }
    set version [tcl3dOglGetGlewVersion]
    lappend versList [list GLEW_VERSION $version]

    return $versList
}

# OBSOLETE tcl3dGetVersions 0.3.3 tcl3dOglGetVersions
proc tcl3dGetVersions {} {
    return [tcl3dOglGetVersions]
}

###############################################################################
#[@e
#       Name:           tcl3dOglGetExtensions - Get all supported OpenGL extensions.
#
#       Synopsis:       tcl3dOglGetExtensions {}
#
#       Description:    Return a two-element list containing OpenGL extension
#                       information. The first sub-list constains all OpenGL 
#                       extensions, the second sub-list contains all GLU 
#                       extensions supported by the OpenGL implementaion.
#
#                       Note: A Togl window (and therefore a graphics context)
#                             must have been created before issuing a call to
#                             this function.
#
#       See also:       tcl3dOglHaveExtension
#                       tcl3dOglGetVersions
#
###############################################################################

proc tcl3dOglGetExtensions {} {
    set versList {}

    set version [string trim [glGetString GL_EXTENSIONS]]
    lappend versList [list GL_EXTENSIONS $version]
    if { [info exists ::GLU_VERSION_1_1] } {
        set version [string trim [gluGetString GLU_EXTENSIONS]]
        lappend versList [list GLU_EXTENSIONS $version]
    }

    return $versList
}

# OBSOLETE tcl3dGetExtensions 0.3.3 tcl3dOglGetExtensions
proc tcl3dGetExtensions {} {
    return [tcl3dOglGetExtensions]
}

###############################################################################
#[@e
#       Name:           tcl3dOglGetIntState - Get OpenGL state variable.
#
#       Synopsis:       tcl3dOglGetIntState { state { numVals 1 } }
#
#       Description:    state    : GLenum
#                       numVals  : int
#
#                       Utility function to query an integer OpenGL state
#                       variable with glGetIntegerv.
#                       The state variable to be queried is specified as an
#                       GLenum in parameter "state".
#
#                       The value of the state variable is returned as an 
#                       integer scalar value, if "numVals" is 1. If "numVals" is
#                       greater than 1, a Tcl list is returned.
#
#                       Note: See Appendix B of the OpenGL Red Book for a list
#                             of state variables.
#
#       See also:       tcl3dOglGetFloatState
#                       tcl3dOglGetDoubleState
#
###############################################################################

proc tcl3dOglGetIntState { state { numVals 1 } } {
    if { $numVals <= 0 } {
        error "Number of values must be greater than zero"
    }
    set vec [tcl3dVector GLint $numVals]
    glGetIntegerv $state $vec
    if { $numVals == 1 } {
        set val [$vec get 0]
    } else {
        set val [tcl3dVectorToList $vec $numVals]
    }
    $vec delete
    return $val
}

###############################################################################
#[@e
#       Name:           tcl3dOglGetFloatState - Get OpenGL state variable.
#
#       Synopsis:       tcl3dOglGetFloatState { state { numVals 1 } }
#
#       Description:    state    : GLenum
#                       numVals  : int
#
#                       Utility function to query a 32-bit floating point
#                       OpenGL state variable with glGetFloatv.
#                       The state variable to be queried is specified as an
#                       GLenum in parameter "state".
#
#                       The value of the state variable is returned as a
#                       float scalar value, if "numVals" is 1. If "numVals" is
#                       greater than 1, a Tcl list is returned.
#
#                       Note: See Appendix B of the OpenGL Red Book for a list
#                             of state variables.
#
#       See also:       tcl3dOglGetIntState
#                       tcl3dOglGetDoubleState
#
###############################################################################

proc tcl3dOglGetFloatState { state { numVals 1 } } {
    if { $numVals <= 0 } {
        error "Number of values must be greater than zero"
    }
    set vec [tcl3dVector GLfloat $numVals]
    glGetFloatv $state $vec
    if { $numVals == 1 } {
        set val [$vec get 0]
    } else {
        set val [tcl3dVectorToList $vec $numVals]
    }
    $vec delete
    return $val
}

###############################################################################
#[@e
#       Name:           tcl3dOglGetDoubleState - Get OpenGL state variable.
#
#       Synopsis:       tcl3dOglGetDoubleState { state { numVals 1 } }
#
#       Description:    state    : GLenum
#                       numVals  : int
#
#                       Utility function to query a 64-bit floating point
#                       OpenGL state variable with glGetDoublev.
#                       The state variable to be queried is specified as an
#                       GLenum in parameter "state".
#
#                       The value of the state variable is returned as a
#                       double scalar value, if "numVals" is 1. If "numVals" is
#                       greater than 1, a Tcl list is returned.
#
#                       Note: See Appendix B of the OpenGL Red Book for a list
#                             of state variables.
#
#       See also:       tcl3dOglGetIntState
#                       tcl3dOglGetFloatState
#
###############################################################################

proc tcl3dOglGetDoubleState { state { numVals 1 } } {
    if { $numVals <= 0 } {
        error "Number of values must be greater than zero"
    }
    set vec [tcl3dVector GLdouble $numVals]
    glGetDoublev $state $vec
    if { $numVals == 1 } {
        set val [$vec get 0]
    } else {
        set val [tcl3dVectorToList $vec $numVals]
    }
    $vec delete
    return $val
}

###############################################################################
#[@e
#       Name:           tcl3dOglGetMaxTextureSize - Get maximum texture size.
#
#       Synopsis:       tcl3dOglGetMaxTextureSize {} 
#
#       Description:    Utility function to get maximum size of a texture.
#                       The maximum texture size is returned as integer value.
#                       This function corresponds to querying state variable
#                       GL_MAX_TEXTURE_SIZE.
#
#       See also:       tcl3dOglGetIntState
#                       tcl3dOglGetMaxTextureUnits
#
###############################################################################

proc tcl3dOglGetMaxTextureSize {} {
    return [tcl3dOglGetIntState GL_MAX_TEXTURE_SIZE]
}

###############################################################################
#[@e
#       Name:           tcl3dOglGetMaxTextureUnits - Get maximum texture units.
#
#       Synopsis:       tcl3dOglGetMaxTextureUnits {} 
#
#       Description:    Utility function to get maximum number of texture units.
#                       The maximum number of texture units is returned as an
#                       integer value.
#                       This function corresponds to querying state variable
#                       GL_MAX_TEXTURE_UNITS.
#
#       See also:       tcl3dOglGetIntState
#                       tcl3dOglGetMaxTextureSize
#
###############################################################################

proc tcl3dOglGetMaxTextureUnits {} {
    return [tcl3dOglGetIntState GL_MAX_TEXTURE_UNITS]
}

###############################################################################
#[@e
#       Name:           tcl3dOglGetViewport - Get current viewport.
#
#       Synopsis:       tcl3dOglGetViewport {}
#
#       Description:    Utility function to get the current viewport.
#                       The viewport is returned as a 4-element Tcl list:
#                       { LowerLeftX LowerLeftY Width Height }
#                       This function corresponds to querying state variable
#                       GL_VIEWPORT.
#
#       See also:       tcl3dOglGetIntState
#
###############################################################################

proc tcl3dOglGetViewport {} {
    return [tcl3dOglGetIntState GL_VIEWPORT 4]
}

###############################################################################
#[@e
#       Name:           tcl3dOglGetProfile - Get OpenGL profile settings.
#
#       Synopsis:       tcl3dOglGetProfile {}
#
#       Description:    Utility function to get the currently available OpenGL
#                       profile.
#
#                       The wished profile (Core or Compatibility profile, 
#                       OpenGL major and minor version) are set when creating a
#                       Togl window with the following command line options:
#                           "-coreprofile bool" "-major int" "-minor int"
#
#                       As the wished combination might not be available with
#                       the installed OpenGL driver, the following situations
#                       can occur:
#                       1. An error is generated at Togl creation time.
#                       2. A compatibility profile is automatically selected by
#                          the driver.
#
#                       To check for the second case, issue a call to 
#                       tcl3dOglGetProfile after Togl creation to check, if your
#                       wished profile has been established.
#                       
#                       The procedure returns a dictionary with the following
#                       entries:
#                       coreprofile true|false
#                       major       int
#                       minor       int
#
#                       Note: A Togl window (and therefore a graphics context)
#                             must have been created before issueing a call to
#                             this function.
#
#       See also:       tcl3dOglHaveVersion
#                       tcl3dOglGetVersionNumber
#                       tcl3dOglGetIntState
#
###############################################################################

proc tcl3dOglGetProfile {} {
    set haveCoreProfile false
    # Call GetError function here to clear previous OpenGL errors.
    # Otherwise we cannot determine, whether the driver supports the
    # GL_CONTEXT_PROFILE_MASK enumeration.
    set errMsg [tcl3dOglGetError]
    set profile [tcl3dOglGetIntState GL_CONTEXT_PROFILE_MASK]
    set errMsg [tcl3dOglGetError]
    if { $errMsg eq "" } {
        if { $profile == 1 } {
            set haveCoreProfile true
        }
        set major [tcl3dOglGetIntState GL_MAJOR_VERSION]
        set minor [tcl3dOglGetIntState GL_MINOR_VERSION]
    } else {
        set versionDict [tcl3dOglGetVersionNumber]
        set major [dict get $versionDict "major"]
        set minor [dict get $versionDict "minor"]
    }

    dict set profileDict "coreprofile" $haveCoreProfile
    dict set profileDict "major" $major
    dict set profileDict "minor" $minor
    return $profileDict
}

###############################################################################
#[@e
#       Name:           tcl3dOglGetExtSuffixes - Get OpenGL extension suffixes.
#
#       Synopsis:       tcl3dOglGetExtSuffixes {}
#
#       Description:    Return a list of all OpenGL extension suffixes.
#                       Currently these are:
#                       "ARB" "EXT" "NV" "ATI" "SGI" "SGIX" "SGIS"
#                       "SUN" "WIN" "MESA" "INTEL" "IBM" "HP"
#
#       See also:       tcl3dOglGetExtensions
#
###############################################################################

proc tcl3dOglGetExtSuffixes {} {
    return { "ARB" "EXT" "NV" "ATI" "SGI" "SGIX" "SGIS" \
             "SUN" "WIN" "MESA" "INTEL" "IBM" "HP" }
}

###############################################################################
#[@e
#       Name:           tcl3dOglFindFunc - Find an OpenGL function.
#
#       Synopsis:       tcl3dOglFindFunc { glFunc }
#
#       Description:    Return the name of an OpenGL function implemented in
#                       the available OpenGL driver.
#                       First it is checked, if the function is available 
#                       as a native implementation. If the OpenGL version does
#                       not supply the function, all possible extension names
#                       are checked in the order as returned by
#                       tcl3dOglGetExtSuffixes.
#                       If none of these checks succeed, an empty string is
#                       returned.
#
#       See also:       tcl3dOglGetExtSuffixes
#
###############################################################################

proc tcl3dOglFindFunc { glFunc } {
    if { [tcl3dOglHaveFunc $glFunc] } {
        return $glFunc
    } else {
        foreach ext [tcl3dOglGetExtSuffixes] {
            set func "${glFunc}${ext}"
            if { [tcl3dOglHaveFunc $func] } {
                return $func
            }
        }
    }
    return ""
}

# Internal procedure to find a specific OpenGL extension.
# "type" may be either "cmd" to find an OpenGL extension command: gl*
# "val" is the command or enumeration prefix to be searched in the list
# of extension suffixes.

proc __tcl3dOglFindExtension { type val } {
    set extList [tcl3dOglGetExtSuffixes]
    if { [string compare $type "cmd"] == 0 } {
        set typeList [info commands gl*]
        set fmtStr "%s%s"
    } else {
        set typeList [info globals GL_*]
        set fmtStr "%s_%s"
    }
    set result {}
    foreach ext $extList {
        set typeExt [format $fmtStr $val $ext]
        if { [lsearch -exact $typeList $typeExt] >= 0 } {
            lappend result $typeExt
        }
    }
    return $result
}

###############################################################################
#[@e
#       Name:           tcl3dOglGetStates - Get OpenGL state variables.
#
#       Synopsis:       tcl3dOglGetStates { {sortFlag "none"} }
#
#       Description:    sortFlag : string (increasing|decreasing|none)
#
#                       Query all state variables of the OpenGL library and
#                       return the results as a list of sub-lists. Each sublist
#                       contains a flag indicating the sucess of the query,
#                       the query command used, the key and the value(s).
#
#                       Note: This function is still incomplete. Chances are
#                             high, it will never be finished.
#                             This function has been declared obsolete with
#                             Tcl3D version 0.4.2.
#
#       See also:       tcl3dOglGetExtensions
#                       tcl3dOglGetVersions
#
###############################################################################

# OBSOLETE tcl3dOglGetStates 0.4.2 None

proc tcl3dOglGetStates { {sortFlag "none"} } {
    set maxSize 20
    set intVec    [tcl3dVector GLint     $maxSize]
    set boolVec   [tcl3dVector GLboolean $maxSize]
    set ubyteVec  [tcl3dVector GLubyte   $maxSize]
    set floatVec  [tcl3dVector GLfloat   $maxSize]
    set doubleVec [tcl3dVector GLdouble  $maxSize]

    set stateList [__tcl3dGetStateList]
    set row 0
    set globalResult {}
    foreach line $stateList {
        for { set i 0 } { $i < $maxSize } { incr i } {
            $intVec    set $i -10000
            $ubyteVec  set $i  100
            $boolVec   set $i  100
            $floatVec  set $i -10000.0
            $doubleVec set $i -10000.0
        }
        set glCmd   [lindex $line 0]
        set enumVal [lindex $line 1]
        set numVals [lindex $line 2]
        set initVal [lindex $line 3]

        if { [llength [info commands $glCmd]] == 0 } {
            puts "Not found cmd: $glCmd"
            lappend globalResult [list 0 $glCmd $enumVal "Not available"]
            set cmdList [__tcl3dOglFindExtension "cmd" $glCmd]
            puts "\tFound $cmdList instead"
        } else {
            set cmdList $glCmd
        }
        if { [llength [info globals $enumVal]] == 0 } {
            puts "Not found enum: $enumVal"
            set enumList [__tcl3dOglFindExtension "enum" $enumVal]
            puts "\tFound $enumList instead"
        } else {
            set enumList $enumVal
        }
        # Put all functions ending with "fv" which need special handling
        # at the top. All others are handled with the default case used
        # for glGetFloatv.
        foreach glCmd $cmdList {
            set result {}
            if { [string equal "glGetPixelMapfv" $glCmd] } {
                set sizeEnum [format "%s_SIZE" $enumVal]
                glGetIntegerv $sizeEnum $intVec
                set numMapEntries [$intVec get 0]
                set mapTable [tcl3dVector GLfloat $numMapEntries]
                $glCmd $enumVal $mapTable
                set result [list 1 $glCmd $enumVal]
                for { set i 0 } { $i < $numMapEntries } { incr i } {
                    lappend result [$mapTable get $i]
                }
                $mapTable delete
                # puts "\t$enumVal is $result (Should be $initVal)"
            } elseif { [string equal "glGetMaterialfv" $glCmd] } {
                foreach face { GL_FRONT GL_BACK GL_FRONT_AND_BACK } {
                    $glCmd $face $enumVal $floatVec
                    set result [list 1 $glCmd $enumVal]
                    for { set i 0 } { $i < $numVals } { incr i } {
                        lappend result [$floatVec get $i]
                    }
                    # puts "\t$face $enumVal is $result (Shoud be $initVal)"
                }
            } elseif { [string equal "glGetLightfv" $glCmd] } {
                for {set lgtNum 0 } { $lgtNum < 8 } { incr lgtNum } {
                    set light [format "GL_LIGHT%d" $lgtNum]
                    $glCmd $light $enumVal $floatVec
                    set result [list 1 $glCmd $enumVal]
                    for { set i 0 } { $i < $numVals } { incr i } {
                        lappend result [$floatVec get $i]
                    }
                    # puts "\t$light $enumVal is $result (Shoud be $initVal)"
                }
            } elseif { [string match "glGetTexLevel*iv" $glCmd] } {
                foreach target { GL_TEXTURE_1D GL_TEXTURE_2D } {
                    $glCmd $target 0 $enumVal $intVec
                    set result [list 1 $glCmd $enumVal]
                    for { set i 0 } { $i < $numVals } { incr i } {
                        lappend result [$intVec get $i]
                    }
                    # puts "\t$target $enumVal is $result (Shoud be $initVal)"
                }
            } elseif { [string match "glGetTex*fv" $glCmd] } {
                foreach target { GL_TEXTURE_1D GL_TEXTURE_2D } {
                    $glCmd $target $enumVal $floatVec
                    set result [list 1 $glCmd $enumVal]
                    for { set i 0 } { $i < $numVals } { incr i } {
                        lappend result [$floatVec get $i]
                    }
                    # puts "\t$target $enumVal is $result (Shoud be $initVal)"
                }
            } elseif { [string match "glGetTex*iv" $glCmd] } {
                foreach enumVal $enumList {
                    foreach target { GL_TEXTURE_1D GL_TEXTURE_2D } {
                        $glCmd $target $enumVal $intVec
                        set tmpResult [list 1 $glCmd $enumVal]
                        for { set i 0 } { $i < $numVals } { incr i } {
                            lappend tmpResult [$intVec get $i]
                        }
                        set result $tmpResult
                    }
                    # puts "\t$target $enumVal is $result (Shoud be $initVal)"
                }
            } elseif { [string equal "glGetColorTableParameterfv" $glCmd] } {
                foreach enumVal $enumList {
                    foreach target { GL_COLOR_TABLE GL_POST_CONVOLUTION_COLOR_TABLE GL_POST_COLOR_MATRIX_COLOR_TABLE GL_PROXY_COLOR_TABLE GL_PROXY_POST_CONVOLUTION_COLOR_TABLE GL_PROXY_POST_COLOR_MATRIX_COLOR_TABLE } {
                        $glCmd $target $enumVal $floatVec
                        set tmpResult [list 1 $glCmd $enumVal]
                        for { set i 0 } { $i < $numVals } { incr i } {
                            lappend tmpResult [$floatVec get $i]
                        }
                        set result $tmpResult
                    }
                    # puts "\t$target $enumVal is $result (Shoud be $initVal)"
                }
            } elseif { [string equal "glGetColorTableParameteriv" $glCmd] } {
                foreach enumVal $enumList {
                    foreach target { GL_COLOR_TABLE GL_POST_CONVOLUTION_COLOR_TABLE GL_POST_COLOR_MATRIX_COLOR_TABLE GL_PROXY_COLOR_TABLE GL_PROXY_POST_CONVOLUTION_COLOR_TABLE GL_PROXY_POST_COLOR_MATRIX_COLOR_TABLE } {
                        $glCmd $target $enumVal $intVec
                        set tmpResult [list 1 $glCmd $enumVal]
                        for { set i 0 } { $i < $numVals } { incr i } {
                            lappend tmpResult [$intVec get $i]
                        }
                        set result $tmpResult
                    }
                    # puts "\t$target $enumVal is $result (Shoud be $initVal)"
                }
            } elseif { [string equal "glGetConvolutionParameterfv" $glCmd] } {
                foreach enumVal $enumList {
                    foreach target { GL_CONVOLUTION_1D GL_CONVOLUTION_2D GL_SEPARABLE_2D } {
                        $glCmd $target $enumVal $floatVec
                        set tmpResult [list 1 $glCmd $enumVal]
                        for { set i 0 } { $i < $numVals } { incr i } {
                            lappend tmpResult [$floatVec get $i]
                        }
                        set result $tmpResult
                    }
                    # puts "\t$target $enumVal is $result (Shoud be $initVal)"
                }
            } elseif { [string equal "glGetConvolutionParameteriv" $glCmd] } {
                foreach enumVal $enumList {
                    foreach target { GL_CONVOLUTION_1D GL_CONVOLUTION_2D GL_SEPARABLE_2D } {
                        $glCmd $target $enumVal $intVec
                        set tmpResult [list 1 $glCmd $enumVal]
                        for { set i 0 } { $i < $numVals } { incr i } {
                            lappend tmpResult [$intVec get $i]
                        }
                        set result $tmpResult
                    }
                    # puts "\t$target $enumVal is $result (Shoud be $initVal)"
                }
            } elseif { [string equal "glGetVertexAttribiv" $glCmd] } {
                if { [llength [info globals GL_MAX_VERTEX_ATTRIBS]] == 0 } {
                    set enumName [lindex [__tcl3dOglFindExtension "enum" GL_MAX_VERTEX_ATTRIBS] 0]
                } else {
                    set enumName GL_MAX_VERTEX_ATTRIBS
                }
                glGetIntegerv $enumName $intVec
                set numAttributes [$intVec get 0]

                foreach enumVal $enumList {
                    set tmpResult [list 1 $glCmd $enumVal]
                    for { set i 0 } { $i < $numAttributes } { incr i } {
                        $glCmd $i $enumVal $intVec
                        for { set j 0 } { $j < 4 } { incr j } {
                            lappend tmpResult [$intVec get $j]
                        }
                    }
                    set result $tmpResult
                # puts "\t$target $enumVal is $result (Shoud be $initVal)"
                }
            } elseif { [string equal "glGetVertexAttribfv" $glCmd] } {
                if { [llength [info globals GL_MAX_VERTEX_ATTRIBS]] == 0 } {
                    set enumName [lindex [__tcl3dOglFindExtension "enum" GL_MAX_VERTEX_ATTRIBS] 0]
                } else {
                    set enumName GL_MAX_VERTEX_ATTRIBS
                }
                glGetFloatv $enumName $floatVec
                set numAttributes [$floatVec get 0]

                foreach enumVal $enumList {
                    set tmpResult [list 1 $glCmd $enumVal]
                    for { set i 0 } { $i < $numAttributes } { incr i } {
                        $glCmd $i $enumVal $floatVec
                        for { set j 0 } { $j < 4 } { incr j } {
                            lappend tmpResult [$floatVec get $j]
                        }
                    }
                    set result $tmpResult
                # puts "\t$target $enumVal is $result (Shoud be $initVal)"
                }
            } elseif { [string equal "glGetMapfv" $glCmd] } {
                foreach enumVal $enumList {
                    foreach target { GL_MAP1_VERTEX_3 GL_MAP1_VERTEX_4 GL_MAP1_INDEX GL_MAP1_COLOR_4 GL_MAP1_NORMAL GL_MAP1_TEXTURE_COORD_1 GL_MAP1_TEXTURE_COORD_2 GL_MAP1_TEXTURE_COORD_3 GL_MAP1_TEXTURE_COORD_4 } {
                        $glCmd $target $enumVal $floatVec
                        set tmpResult [list 1 $glCmd $enumVal]
                        for { set i 0 } { $i < $numVals } { incr i } {
                            lappend tmpResult [$floatVec get $i]
                        }
                        set result $tmpResult
                    }
                    # puts "\t$target $enumVal is $result (Shoud be $initVal)"
                }
            } elseif { [string equal "glGetMapiv" $glCmd] } {
                foreach enumVal $enumList {
                    foreach target { GL_MAP1_VERTEX_3 GL_MAP1_VERTEX_4 GL_MAP1_INDEX GL_MAP1_COLOR_4 GL_MAP1_NORMAL GL_MAP1_TEXTURE_COORD_1 GL_MAP1_TEXTURE_COORD_2 GL_MAP1_TEXTURE_COORD_3 GL_MAP1_TEXTURE_COORD_4 } {
                        $glCmd $target $enumVal $intVec
                        set tmpResult [list 1 $glCmd $enumVal]
                        for { set i 0 } { $i < $numVals } { incr i } {
                            lappend tmpResult [$intVec get $i]
                        }
                        set result $tmpResult
                    }
                    # puts "\t$target $enumVal is $result (Shoud be $initVal)"
                }
            } elseif { [string match "glGetUniform*v" $glCmd] } {
                puts "NOT handled glCmd <$glCmd $enumVal $numVals>"
                set result [list 0 $glCmd $enumVal "--"]
            } elseif { [string equal "glGetFloatv" $glCmd] || \
                       [string match "*fv" $glCmd] } {
                $glCmd $enumVal $floatVec
                set result [list 1 $glCmd $enumVal]
                for { set i 0 } { $i < $numVals } { incr i } {
                    lappend result [$floatVec get $i]
                }
                # puts "\t$enumVal is $result (Should be $initVal)"
            } elseif { [string equal "glGetIntegerv" $glCmd] } {
                foreach enumVal $enumList {
                    $glCmd $enumVal $intVec
                    set tmpResult [list 1 $glCmd $enumVal]
                    for { set i 0 } { $i < $numVals } { incr i } {
                        lappend tmpResult [$intVec get $i]
                    }
                    set result $tmpResult
                }
                # puts "\t$enumVal is $result (Shoud be $initVal)"
            } elseif { [string equal "glGetBooleanv" $glCmd] } {
                $glCmd $enumVal $boolVec
                set result [list 1 $glCmd $enumVal]
                for { set i 0 } { $i < $numVals } { incr i } {
                    lappend result [$boolVec get $i]
                }
                # puts "\t$enumVal is $result (Shoud be $initVal)"
            } elseif { [string equal "glGetClipPlane" $glCmd] } {
                $glCmd $enumVal $doubleVec
                set result [list 1 $glCmd $enumVal]
                for { set i 0 } { $i < $numVals } { incr i } {
                    lappend result [$doubleVec get $i]
                }
                # puts "\t$enumVal is $result (Should be $initVal)"
            } elseif { [string equal "glIsEnabled" $glCmd] } {
                foreach enumVal $enumList {
                    set tmpResult [list 1 $glCmd $enumVal]
                    lappend tmpResult [$glCmd $enumVal]
                    set result $tmpResult
                }
                # puts "\t$enumVal is $result (Shoud be $initVal)"
            } elseif { [string equal "glGetPolygonStipple" $glCmd] } {
    # OPA TODO Core dump on Windows
    #                $glCmd $ubyteVec
    #                set result [list 1 $glCmd $enumVal]
    #                for { set i 0 } { $i < $numVals } { incr i } {
    #                    lappend result [$ubyteVec get $i]
    #                }
    #                puts "\t$enumVal is $result (Shoud be $initVal)"
            } else {
                puts "NOT handled glCmd <$glCmd $enumVal $numVals>"
                set result [list 0 $glCmd $enumVal "--"]
            }
            lappend globalResult $result
            incr row
        }
    }
    if { $sortFlag eq "increasing" || $sortFlag eq "decreasing" } {
        return [lsort -index 1 -$sortFlag $globalResult]
    } else {
        return $globalResult
    }
}

# OBSOLETE tcl3dGetStates 0.3.3 tcl3dOglGetStates
proc tcl3dGetStates { {sortFlag "none"} } {
    return [tcl3dOglGetStates $sortFlag]
}
