#******************************************************************************
#
#       Copyright:      2005-2010 Paul Obermeier (obermeier@tcl3d.org)
#
#                       See the file "Tcl3D_License.txt" for information on
#                       usage and redistribution of this file, and for a
#                       DISCLAIMER OF ALL WARRANTIES.
#
#       Module:         Tcl3D -> tcl3dOgl
#       Filename:       tcl3dOglUtil.tcl
#
#       Author:         Paul Obermeier
#
#       Description:    Tcl module with miscellaneous utility
#                       procedures related to the OpenGL module.
#
#******************************************************************************

###############################################################################
#[@e
#       Name:           tcl3dOglExtInit - Initialize the extension library.
#
#       Synopsis:       tcl3dOglExtInit {}
#
#       Description:    Initialize the OpenGL extension library.
#                       If no OpenGL context has been established (i.e. a Togl
#                       window has not been created), the function throws an 
#                       error.
#                       It is recommended to add a call to tcl3dOglExtInit in
#                       the create callback.
#                       Note: With Tcl3D versions starting at 0.4, this 
#                       procedure is not needed anymore, because the GLEW 
#                       extension functions are initialized within the Togl
#                       widget start-up code.
#                       You may leave it in your code however for backwards
#                       compatibility.
#
#       See also:
#
###############################################################################

# OBSOLETE tcl3dOglExtInit 0.4.0 None
proc tcl3dOglExtInit {} {
    if { [info commands glewInit] ne "" } {
        # GLEW based wrapper. Tcl3D Version >= 0.4
        glewInit
    } elseif { [info commands glexGetVersion] ne "" } {
        # OglExt based wrapper. Tcl3D Version >= 0.2
        glexGetVersion
    } else {
        error "OpenGL extension library not wrapped"
    }
}

# OBSOLETE tcl3dInit 0.3.2 tcl3dOglExtInit
proc tcl3dInit {} {
    tcl3dOglExtInit
}

###############################################################################
#[@e
#       Name:           glMultiDrawElements - Draw multiple array elements.
#
#       Synopsis:       glMultiDrawElements {
#                               mode count type indices primcount }
#
#       Description:    mode      : GLenum
#                       count     : tcl3dVector of type GLuint
#                       type      : GLenum
#                       indices   : List of tcl3dVectors
#                       primcount : integer
#
#                       Tcl wrapper for the OpenGL function glMultiDrawElements.
#                       As the Tcl3D Swig wrapper currently does not support
#                       "void **" pointers, the multiple array elements must be
#                       specified as a list of tcl3dVectors.
#
#       See also:
#
###############################################################################

proc glMultiDrawElements { mode count type indices primcount } {
    for { set i 0 } { $i < $primcount } { incr i } {
        if { [$count get $i] > 0 } {
            glDrawElements $mode [$count get $i] $type [lindex $indices $i]
        }
    }
}

###############################################################################
#[@e
#       Name:           tcl3dOglGetError - Check for an OpenGL error.
#
#       Synopsis:       tcl3dOglGetError {}
#
#       Description:    Check, if an OpenGL related error has occurred.
#
#                       If no error occurred, an emtpy string is returned.
#                       Otherwise a formatted string showing the error number
#                       and the error message is returned.
#
#       See also:
#
###############################################################################

proc tcl3dOglGetError {} {
    set errEnum [glGetError]
    if { $errEnum == $::GL_NO_ERROR } {
        return ""
    }
    set errMsg [format "GL error: 0X%X (%s)" $errEnum [gluErrorString $errEnum]]
    while { 1 } {
        set errEnum [glGetError]
        if { $errEnum == $::GL_NO_ERROR } {
            return $errMsg
        }
        append errMsg [format " 0X%X (%s)" $errEnum [gluErrorString $errEnum]]
    }
}

# OBSOLETE tcl3dCheckGlError 0.3.2 tcl3dOglGetError
proc tcl3dCheckGlError { msg } {
    set err [glGetError]

    if { $err == $::GL_NO_ERROR } {
        return 0
    }

    puts [format "%s: GL error: 0X%X (%s)" $msg $err [gluErrorString $err]]
    return 1
}

# OpenGL function "glFunc" is renamed to create either a debug version
# or a safe version.
proc __tcl3dOglCreateSafeOrDebugFunc { glFunc debugFlag normalFlag \
                                       { printCmd puts }  } {
    if { [info commands ${glFunc}Standard] eq "${glFunc}Standard" } {
        rename ::${glFunc} {}
        rename ::${glFunc}Standard $glFunc
    }
    if { $normalFlag } {
        return
    }
    set code \
        [format "
        if { \[__%sAvail\] } {
            if { %d } {
                %s \"%s \$args\"
            }
            eval %sStandard \$args
        } else {
            %s \">>> %s \$args (N/A in driver)\"
        }" \
        $glFunc $debugFlag $printCmd $glFunc $glFunc $printCmd $glFunc]
    
    uplevel "proc ${glFunc}Safe args { $code }"

    rename ::$glFunc ::${glFunc}Standard
    rename ::${glFunc}Safe ::$glFunc
}

###############################################################################
#[@e
#       Name:           tcl3dOglSetNormalMode - Set the execution mode of OpenGL
#                                               functions to normal.
#
#       Synopsis:       tcl3dOglSetNormalMode { { printCmd puts } }
#
#       Description:    printCmd : command name
#       
#                       Set the execution mode of all OpenGL functions to normal.
#
#                       The "printCmd" will be used to output OpenGL command
#                       execution infos. If not specified, the information is
#                       printed onto stdout with the puts command.
#                       The printCmd must be a command with a single string 
#                       parameter.
#
#                       See the documentation of tcl3dOglSetMode for a 
#                       description of the OpenGL execution modes.
#
#       See also:       tcl3dOglSetSafeMode
#                       tcl3dOglSetDebugMode
#                       tcl3dOglSetMode
#
###############################################################################

proc tcl3dOglSetNormalMode { { printCmd puts } } {
    foreach glFunc [tcl3dOglGetFuncList] {
        __tcl3dOglCreateSafeOrDebugFunc $glFunc 0 1
    }
}

###############################################################################
#[@e
#       Name:           tcl3dOglSetSafeMode - Set the execution mode of OpenGL
#                                             functions to safe.
#
#       Synopsis:       tcl3dOglSetSafeMode { { printCmd puts } }
#
#       Description:    printCmd : command name
#       
#                       Set the execution mode of all OpenGL functions to safe.
#
#                       The "printCmd" will be used to output OpenGL command
#                       execution infos. If not specified, the information is
#                       printed onto stdout with the puts command.
#                       The printCmd must be a command with a single string 
#                       parameter.
#
#                       See the documentation of tcl3dOglSetMode for a 
#                       description of the OpenGL execution modes.
#
#       See also:       tcl3dOglSetNormalMode
#                       tcl3dOglSetDebugMode
#                       tcl3dOglSetMode
#
###############################################################################

proc tcl3dOglSetSafeMode { { printCmd puts } } {
    foreach glFunc [tcl3dOglGetFuncList] {
        __tcl3dOglCreateSafeOrDebugFunc $glFunc 0 0
    }
}


###############################################################################
#[@e
#       Name:           tcl3dOglSetDebugMode - Set the execution mode of OpenGL
#                                              functions to debug.
#
#       Synopsis:       tcl3dOglSetDebugMode { { printCmd puts } }
#
#       Description:    printCmd : command name
#       
#                       Set the execution mode of all OpenGL functions to debug.
#
#                       The "printCmd" will be used to output OpenGL command
#                       execution infos. If not specified, the information is
#                       printed onto stdout with the puts command.
#                       The printCmd must be a command with a single string 
#                       parameter.
#
#                       See the documentation of tcl3dOglSetMode for a 
#                       description of the OpenGL execution modes.
#
#       See also:       tcl3dOglSetNormalMode
#                       tcl3dOglSetSafeMode
#                       tcl3dOglSetMode
#
###############################################################################

proc tcl3dOglSetDebugMode { { printCmd puts } } {
    foreach glFunc [tcl3dOglGetFuncList] {
        __tcl3dOglCreateSafeOrDebugFunc $glFunc 1 0
    }
}

###############################################################################
#[@e
#       Name:           tcl3dOglSetMode - Set the execution mode for OpenGL
#                                         functions.
#
#       Synopsis:       tcl3dOglSetMode { mode { printCmd puts } }
#
#       Description:    mode     : string
#                       printCmd : command name
#       
#                       The OpenGL core and extension functions can be used
#                       in 3 different modes:
#                       "normal", "safe", "debug".
#
#                       normal: Use the OpenGL functions as wrapped by SWIG.
#                               This is the fastest mode. If using an
#                               OpenGL function not available in the used driver
#                               implementation, this mode will dump core.
#                       safe:   In this mode every OpenGL function is checked
#                               for availability in the driver before execution.
#                               If it's not available, a message is printed out.
#                       debug:  This mode checks the availability of an OpenGL
#                               function like the safe mode, and additionally
#                               prints out every OpenGL function before
#                               execution.
#
#                       The "printCmd" will be used to output OpenGL command
#                       execution infos. If not specified, the information is
#                       printed onto stdout with the puts command.
#                       The printCmd must be a command with a single string 
#                       parameter.
#
#       See also:       tcl3dOglSetNormalMode
#                       tcl3dOglSetSafeMode
#                       tcl3dOglSetDebugMode
#
###############################################################################

proc tcl3dOglSetMode { mode { printCmd puts } } {
    if { $mode eq "normal" } {
        tcl3dOglSetNormalMode $printCmd
    } elseif { $mode eq "safe" } {
        tcl3dOglSetSafeMode $printCmd
    } elseif { $mode eq "debug" } {
        tcl3dOglSetDebugMode $printCmd
    } else {
        error "Unknown OpenGL mode: $mode"
    }
}
