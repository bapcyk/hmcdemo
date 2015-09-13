package provide ui_3d 1.0

package require Tk
package require Ttk
package require mym
package require Itcl
package require mysens
package require myutl
package require mylsn
package require tcl3d 0.5.0

# TODO more contrast light
# FIXME rotation more then 90 degrees (pitch)

# 3D frame
itcl::class Ui3d {
    inherit DataListener

    # 3D model
    protected variable _3dm ""
    protected variable _scalefactor 1.0

    # lights
    protected variable _l0_ambient { 0.0 0.0 0.0 1.0 }
    protected variable _l0_diffuse { 1.0 1.0 1.0 1.0 }
    protected variable _l0_specular { 1.0 1.0 1.0 1.0 }
    protected variable _l0_position { 0.0 3.0 2.0 0.0 }
    protected variable _l0_lmodel_ambient { 0.4 0.4 0.4 1.0 }
    protected variable _l0_local_view { 0.0 }

    protected variable _heading 0.0
    protected variable _pitch 0.0
    protected variable _roll 0.0
    protected variable _parent
    protected variable _pov f; # variable of radiobuttons (angle of view)
    protected variable _vdist -6; # variable of scale widget (initial value)

    protected variable _font_base

    #protected variable _h_ab
    #protected variable _p_ab
    #protected variable _r_ab
    #protected variable _q

    method create {parent}

    constructor {} {
        #set _q  [Quat [itcl::scope _q]]
        #set _h_ab [CAntiBias [itcl::scope _h_ab]    0 360 2]
        #set _p_ab [CAntiBias [itcl::scope _p_ab]  -90 90  2]
        #set _r_ab [CAntiBias [itcl::scope _r_ab] -180 180 2]
    }

    destructor {
        if {$_3dm ne ""} {
            glmDelete $_3dm
            set _3dm ""
        }
    }

    method ondata {values}

    # OpenGL (Tcl3d) callbacks
    protected method _oncreate {toglwin}
    protected method _onreshape {toglwin {w -1} {h -1}}
    protected method _ondisplay {toglwin}

    # utilities
    protected method _draw_grid
    protected method _draw_string {str x y}
    protected method _redisplay {args}
    #protected method _create_materials
    protected method _create_lights
    protected method _load_model {fname}
}

itcl::body Ui3d::_load_model {fname} {
    if {$_3dm ne ""} {
        glmDelete $_3dm
        set _3dm ""
    }
    tcl3dGetExtFile "3dm/$fname.mtl"
    set fullname [tcl3dGetExtFile "3dm/$fname.obj"]
    set _3dm [glmReadOBJ $fullname]
    set _scalefactor [glmUnitize $_3dm]
    glmFacetNormals $_3dm
    glmVertexNormals $_3dm 90.0
}

# Print string "str" to raster position (x,y).
itcl::body Ui3d::_draw_string {str x y} {
    glRasterPos2f $x $y
    glListBase $_font_base
    set len [string length $str]
    set sa [tcl3dVectorFromString GLubyte $str]
    glCallLists $len GL_UNSIGNED_BYTE $sa
    $sa delete
}

itcl::body Ui3d::_oncreate {toglwin} {
    glShadeModel GL_SMOOTH         ; # Enable smooth shading
    glClearColor 0.0 0.0 0.0 0.5   ; # Black background
    glClearDepth 1.0               ; # Depth buffer setup
    glEnable GL_DEPTH_TEST         ; # Enable depth testing

    _create_lights

    # XXX I dont know what does next 3 lines
    # XXX path use / not \ !

    #tcl3dGetExtFile {3dmodels\f-16.mtl}
    #set fullName [tcl3dGetExtFile {3dmodels\f-16.obj}]
    #_load_model $fullName
    _load_model f-16; #[myutl::kit_path 3dm/f-16.obj]
    set _font_base [$toglwin loadbitmapfont "fixed"]
}

itcl::body Ui3d::_onreshape {toglwin {w -1} {h -1} } {
    set w [$toglwin width]        ; # Get Togl window width
    set h [$toglwin height]       ; # Get Togl window height
    glViewport 0 0 $w $h          ; # Reset the current viewport
    glMatrixMode GL_PROJECTION    ; # Select the projection matrix
    glLoadIdentity                ; # Reset the projection matrix
    # Calculate the aspect ratio of the window
    gluPerspective 45.0 [expr double($w)/double($h)] 0.1 100.0
    glMatrixMode GL_MODELVIEW     ; # Select the modelview matrix
    glLoadIdentity                ; # Reset the modelview matrix
}

itcl::body Ui3d::_ondisplay {toglwin} {
    # Clear color and depth buffer
    glClear [expr $::GL_COLOR_BUFFER_BIT | $::GL_DEPTH_BUFFER_BIT] 
    glLoadIdentity                 ; # Reset the current modelview matrix
    
    glPushMatrix
    # $_vdist * -1.0 -- direction of zooming (in or out)
    glPushMatrix
    glTranslatef 0 0 -6
    _draw_string "H: [format %.1f%c $_heading 176]" -4.5 2.2
    _draw_string "P: [format %.1f%c $_pitch 176]" -4.5 2.0
    _draw_string "R: [format %.1f%c $_roll 176]" -4.5 1.8
    glPopMatrix
    glTranslatef 0 0 $_vdist

    # no "f" bcz it's initial position (front) and it not requires any
    # additional transformations
    switch -- $_pov {
        s { glRotated 90 0 1 0 }
        t { glRotated 90 1 0 0 }
        i { gluLookAt 0.6 0.2 0.6  0 0 0  0 1 0 }
    }

    glPushMatrix

    # TODO rotation depends on sensor orientation
    glRotatef $_heading 0.0 -1.0 0.0
    glRotatef $_pitch -1.0 0.0 0.0
    glRotatef $_roll 0.0 0.0 1.0

    #if {$_heading > 180.} {
        #set _heading [expr {$_heading - 360.}]
    #}
    #set h [expr {0.01745329251994329576 * $_heading}]
    #set p [expr {0.01745329251994329576 * $_pitch}]
    #set r [expr {0.01745329251994329576 * $_roll}]
    #$_q from_euler $r $h $p
    #set rotmx [$_q to_rotmx]
    #glMultMatrixf $rotmx

    glmDraw $_3dm [expr $::GLM_SMOOTH | $::GLM_MATERIAL]; # draw sensor model

    glPopMatrix

    _draw_grid
    glPopMatrix

    #glFlush
    $toglwin swapbuffers           ; # Swap front and back buffer  
}

itcl::body Ui3d::_create_lights {} {
    glClearColor 0.0 0.1 0.1 0
    glEnable GL_DEPTH_TEST

    glLightfv GL_LIGHT0 GL_AMBIENT $_l0_ambient
    glLightfv GL_LIGHT0 GL_DIFFUSE $_l0_diffuse
    glLightfv GL_LIGHT0 GL_POSITION $_l0_position
    glLightModelfv GL_LIGHT_MODEL_AMBIENT $_l0_lmodel_ambient
    glLightModelfv GL_LIGHT_MODEL_LOCAL_VIEWER $_l0_local_view

    glEnable GL_LIGHTING
    glEnable GL_LIGHT0
}

itcl::body Ui3d::_draw_grid {} {
    glDisable GL_LIGHTING
    glBegin GL_LINES
    glColor3f 0 0.3 0

    set h -0.5
    set size 3
    set step 0.5
    for { set i $step } { $i <= $size } { set i [expr {$i + $step}] } {
        glVertex3f -$size $h  $i ;   # lines parallel to X-axis
        glVertex3f  $size $h  $i
        glVertex3f -$size $h -$i ;   # lines parallel to X-axis
        glVertex3f  $size $h -$i

        glVertex3f  $i $h -$size ;   # lines parallel to Z-axis
        glVertex3f  $i $h  $size
        glVertex3f -$i $h -$size ;   # lines parallel to Z-axis
        glVertex3f -$i $h  $size
    }

    # x-axis
    glColor3f 0.5 0 0

    glVertex3f -$size $h 0
    glVertex3f  $size $h 0

    # y-axis
    glColor3f 0 0.5 0
    glVertex3f 0 $h 0
    glVertex3f 0 $size 0

    # z-axis
    glColor3f 0 0 0.5
    glVertex3f 0 $h -$size
    glVertex3f 0 $h  $size

    glEnd
    glEnable GL_LIGHTING
}

itcl::body Ui3d::create {w} {
    set _parent $w

    ttk::frame $_parent.tb
    pack $_parent.tb -side top -fill x

    radiobutton $_parent.tb.b0 -indicatoron 0 -value f -image .imgf \
        -command [itcl::code $this _redisplay] -width 22 -height 22 \
        -variable [itcl::scope _pov]
    radiobutton $_parent.tb.b1 -indicatoron 0 -value s -image .imgs \
        -command [itcl::code $this _redisplay] -width 22 -height 22 \
        -variable [itcl::scope _pov]
    radiobutton $_parent.tb.b2 -indicatoron 0 -value t -image .imgt \
        -command [itcl::code $this _redisplay] -width 22 -height 22 \
        -variable [itcl::scope _pov]
    radiobutton $_parent.tb.b3 -indicatoron 0 -value i -image .imgi \
        -command [itcl::code $this _redisplay] -width 22 -height 22 \
        -variable [itcl::scope _pov]

    pack $_parent.tb.b0 -side left -pady 1 -padx 1
    pack $_parent.tb.b1 -side left -pady 1 -padx 1
    pack $_parent.tb.b2 -side left -pady 1 -padx 1
    pack $_parent.tb.b3 -side left -pady 1 -padx 1

    ttk::scale $_parent.tb.sc -from "-100" -to 30 -orient horiz \
        -command [itcl::code $this _redisplay] \
        -variable [itcl::scope _vdist]
    pack $_parent.tb.sc -fill x -expand 1 -padx 5

    togl $_parent.toglwin -width 250 -height 250 \
        -double true -depth true \
        -createproc  [itcl::code $this _oncreate] \
        -reshapeproc [itcl::code $this _onreshape] \
        -displayproc [itcl::code $this _ondisplay]

    pack $_parent.toglwin -fill both -expand 1
}

# Set point of view: control angle of view of 3D model (does not manage buttons!)
itcl::body Ui3d::_redisplay {args} {
    $_parent.toglwin postredisplay
}

itcl::body Ui3d::ondata {values} {
    # values: heading, pitch, roll...
    lassign $values _heading _pitch _roll
    #set _heading [$_h_ab correct $_heading]
    #set _pitch [$_p_ab correct $_pitch]
    #set _roll [$_r_ab correct $_roll]
    # change model position
    _redisplay
}

Ui3d ::ui3d
::ui3d configure -datatypes {phys flt}
