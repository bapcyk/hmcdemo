package provide ui_main 1.0

package require Tk
package require Ttk
package require Itcl
package require mycons
package require ui_3d
package require ui_plot
package require ui_cells

itcl::class Uimain {
    variable _nb ""
    method create {{parent ""}}
    method switch_tab {tabid}
}

# main window creation
itcl::body Uimain::create {{parent ""}} {
    wm title . "Application"
    # TODO auto-center and select sizes
    wm geometry . 800x600+300+100
    wm resizable . 0 0

    set mf [frame $parent.mf]
    pack $mf -fill both -expand 1

    set _nb [ttk::notebook $mf.nb]
    place $_nb -relheight 0.8 -relwidth 1

    #----- page -----
    set page0f [frame $_nb.page0 -container 0]
    $_nb add $page0f -text "Values"

    set cf [frame $mf.cf -container 1]
    place $cf -rely 0.8 -relheight 0.2 -relwidth 1
    mycons::ConsoleInit $cf cons; #$cf.c
    # TODO next line to app level destroy
    bind $cf <Destroy> {interp delete $cf.c}
    puts "Honeywell HMC6343 demo, v 1.0"

    ::uicells create $page0f

    #----- page -----
    set page1f [frame $_nb.page1 -container 0]
    $_nb add $page1f -text "3D"
    ::ui3d create $page1f

    #----- page -----
    set page2f [frame $_nb.page2 -container 0]
    $_nb add $page2f -text "Distance"
    ::uiplot create $page2f

    #ttk::notebook::enableTraversal $_nb
}

itcl::body Uimain::switch_tab {tabid} {

    switch -nocase $tabid {
        0 -
        values { $_nb select 0 }

        1 -
        3d { $_nb select 1 }
    }
}
