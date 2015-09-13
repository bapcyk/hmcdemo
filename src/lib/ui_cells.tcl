package provide ui_cells 1.0

package require Tk
package require Ttk
package require Itcl
package require myutl
package require mylsn
package require mydsp
package require mysens

# Got values in grid of cells
itcl::class Uicells {
    inherit DataListener

    protected variable _tree
    protected variable _font

    # for units/caption switching
    protected variable FMT
    protected variable _src
    protected variable _columns
    protected variable _units

    constructor {} {
        array set FMT {
            raw  "%d %d %d %d %d %d %d %d %d %d"
            phys "%.1f %.1f %.1f %.3f %.3f %.3f %.3f %.3f %.3f %.1f"
        }
    }

    method create {parent}
    method clear
    method line {{char =}}
    method append {columns}
    method set_header {columns units}

    method ondata {values}
    method onadd {provider}
}

# FIXME movement by keyboards does not work (but is it needed?)
itcl::body Uicells::create {w} {
    # tree - grid of cells
    set _tree [ttk::treeview $w.tree \
        -yscroll "$w.vsb set" -xscroll "$w.hsb set"]
    if {[tk windowingsystem] ne "aqua"} {
        ttk::scrollbar $w.vsb -orient vertical -command "$w.tree yview"
        ttk::scrollbar $w.hsb -orient horizontal -command "$w.tree xview"
    } else {
        scrollbar $w.vsb -orient vertical -command "$w.tree yview"
        scrollbar $w.hsb -orient horizontal -command "$w.tree xview"
    }
    set _font [ttk::style lookup [$_tree cget -style] -font]; # font of widget

    # Show all
    pack $w.tree -fill both -expand 1
    grid $w.tree $w.vsb -in $w -sticky nsew
    grid $w.hsb -in $w -sticky nsew
    grid column $w 0 -weight 1
    grid row $w 0 -weight 1
}

# updating caption on headers
itcl::body Uicells::set_header {columns units} {
    # if no columns yet, so it's 1st call
    set first_call [expr {[$_tree cget -columns] eq ""}]
    if {$first_call} {
        $_tree configure -columns $columns -show headings
    }

    set icol 0
    foreach c $columns u $units {
        set txt "$c,$u"
        $_tree heading $icol -text $txt; # set captions (the same as IDs)
        set len [font measure $_font $txt]
        if {$first_call} {
            # unconditionally set width when 1st call
            $_tree column $icol -width $len
        } else {
            # if not 1st call - set width only if need to expand
            if {[$_tree column $icol -width] < $len} {
                $_tree column $icol -width $len
            }
        }
        incr icol
    }
}

itcl::body Uicells::clear {} {
    # Clears content of the grid


    $_tree delete [$_tree children {}]
}

itcl::body Uicells::line {{char =}} {
    # Adds delimiter line filled with char symbol


    set ncolumns [llength $FMT(raw)]
    set empty "$char$char$char$char"
    $this append [lrepeat $ncolumns $empty]
}

# append {xxx yyy ...} - number of columns should be equal to headers
itcl::body Uicells::append {columns} {
    set item [$_tree insert {} end -values $columns]
    set icol 0
    foreach col $columns {
        set len [font measure $_font $col]
        if {[$_tree column $icol -width] < $len} {
            $_tree column $icol -width $len
        }
        incr icol
    }
    $_tree see $item
}

# called by DataProvider
itcl::body Uicells::onadd {provider} {
    lassign [$provider fixed_columns_units] _columns _units
    set_header $_columns $_units
    set _src [$provider cget -datatype]
}

itcl::body Uicells::ondata {values} {
    switch -- $_src {
        phys {
            set columns {}
            foreach fmt $FMT($_src) u $_units val $values {
                lappend columns "[format $fmt $val]$u"
            }
            $this append $columns
        }
        raw { $this append $values }
    }
}

Uicells ::uicells
::uicells configure -datatypes {raw phys flt}
