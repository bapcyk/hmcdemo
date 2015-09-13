package provide mydoc 1.0

# Usage:
#
#   proc f {} {
#     # help
#     # help
#
#
#     ... body ...
#   }
#
# Then call:
#
#   doc f
#
# With Itcl:
#
#   class S {
#     method m {} {
#         # help
#
#
#         ... body ...
#     }
#   }
#   S the_s
#
# Then call:
#
#   doc the_s m
#   doc S m

namespace eval mydoc {
    namespace export doc
}

set _NOHELPMSG "No help."

proc ::mydoc::_docstring {body} {
    set body [string trim $body]
    set docstring ""
    # without 1st '^' will match any FIRST docstring block even after
    # commands!
    if {[regexp {^#\s*([^\n]+\n)+(\n\n)} $body docstring]} {
        set docstring [regsub -all {\s*#\s?} $docstring \n]
        set docstring [string trim $docstring]
        return $docstring
    }
}

proc ::mydoc::doc args {
    # Help on command: procedure or class method. Call:
    #   doc some_object some_method
    #   doc some_class some_method
    #   doc some_proc


    global _NOHELPMSG
    set found ""
    switch -- [llength $args] {
        1 {
            # args: proc
            set name [lindex $args 0]
            set arguments [info args $name]
            set body [info body $name]
            set found [_docstring $body]
        }
        2 {
            # FIXME not optimal!
            # args: object|class method
            lassign $args cls_obj meth
            set objs [itcl::find objects]
            # cls_obj may be object OR class. What is it?
            if {-1 != [lsearch -regexp $objs :*$cls_obj]} {
                # this is the object
                set arguments [$cls_obj info args $meth]
                set body [$cls_obj info body $meth]
                set found [_docstring $body]
            } else {
                # this is the class
                set arguments [namespace eval ::$cls_obj info args $meth]
                set body [namespace eval ::$cls_obj info body $meth]
                set found [_docstring $body]
            }
        }
        default { error "wrong args: proc | object method | class method" }
    }
    if {$found eq ""} {
        return $_NOHELPMSG
    } else {
        return $found
    }
}

# txt is the string with \n, shifter is like '\t' or '\t\t'..
proc mydoc::_shift_strings {txt shifter} {
    if {$txt ne ""} {
        return "$shifter[regsub -all \n $txt \n$shifter]"
    }
}


# Generate only for documented with docstrings
proc mydoc::_genrst {fname} {
    set result {}
    # Collect help on objects and it's methods
    set clshelp {}
    foreach cls [itcl::find classes] {
        set her [namespace eval $cls "info heritage"]

        set varhelp {}
        foreach v [namespace eval $cls info variable] {
            catch {
                #lappend varhelp [namespace eval $cls info variable $v -protection public]
                if {[string first "::_" $v] == -1} {
                    switch -- [namespace eval $cls info variable $v -protection] {
                        public { set vprot "public" }
                        protected { set vprot "protected" }
                        private { set vprot "private" }
                    }
                    lappend varhelp "- $vprot $v"
                }
            }
        }

        set methelp {}
        foreach func [namespace eval $cls "info function"] {
            catch {
                set body [string trim [namespace eval $cls "info body $func"]]
                if {$body ne ""} {
                    set arguments [namespace eval $cls "info args $func"]
                    if {$arguments eq ""} { set arguments "no args." }
                    set docstring [_shift_strings [_docstring $body] \t]
                    if {$docstring ne ""} {
                        lappend methelp "*${func}*: **${arguments}**"
                        lappend methelp ""
                        lappend methelp "::"
                        lappend methelp ""
                        lappend methelp $docstring
                        lappend methelp ""
                        lappend methelp ""
                    }
                }
            }
        }
        if {$methelp ne ""} {
            # there are methods with docstrings!
            if {[llength $her] > 1} {
                # there are base classes
                set bases [lrange $her 1 end]
                set her "[lindex $her 0] (*extends ${bases}*)"
            }
            lappend clshelp "$her"
            lappend clshelp [string repeat "-" [string length $her]]
            lappend clshelp ""
            lappend clshelp "Variables"
            lappend clshelp "~~~~~~~~~"
            lappend clshelp ""
            if {$varhelp ne ""} {
                lappend clshelp [join $varhelp "\n"]
            } else {
                lappend clshelp "No variables."
            }
            lappend clshelp ""
            lappend clshelp "Methods"
            lappend clshelp "~~~~~~~"
            lappend clshelp ""
            lappend clshelp {*}$methelp
        }
    }
    # Collect procs help
    set prochelp {}
    foreach func [uplevel #0 info procs] {
        catch {
            set body [string trim [uplevel #0 info body $func]]
            if {$body ne ""} {
                set arguments [uplevel #0 info args $func]
                if {$arguments eq ""} { set arguments "no args." }
                set docstring [_shift_strings [_docstring $body] \t]
                if {$docstring ne ""} {
                    lappend prochelp "*${func}*: **${arguments}**"
                    lappend prochelp ""
                    lappend prochelp "::"
                    lappend prochelp ""
                    lappend prochelp $docstring
                    lappend prochelp ""
                    lappend prochelp ""
                }
            }
        }
    }

    if {$clshelp ne ""} {
        lappend result ""
        lappend result "Classes"
        lappend result "======="
        lappend result ""
        lappend result {*}$clshelp
    }
    if {$prochelp ne ""} {
        lappend result ""
        lappend result "Procedures"
        lappend result "=========="
        lappend result ""
        lappend result {*}$prochelp
    }


    set fid [open $fname w]
    puts -nonewline $fid [join $result "\n"]
    close $fid
}

#proc f2 {} {
#
#    # Configure channels' filters:
#    #   -ord int|{int0 int1...} -- order of filter
#    #   -f1 double|{double0 double1...} -- cut freq 1
#    #   -f2 double|{double0 double1...} -- cut freq 2
#    #   -win bool|{bool0 bool1...} -- need Blackman window?
#    #   -norm bool|{bool0 bool1...} -- need normalization of coefficients?
#    #   -fs double|{double0 double1...} -- sampling freq (if omitted, sensor get_freq is used)
#    # Positional args are indexes of channels to be filtered or 'all'. Ex:
#    #   chconfigure 0 1 3 -f1 {10 20 30} -ord {15 20 25}
#    # All freqs are in Hz. Sampling freq is obtained from sensor when onrun is called.
#    # Without args, returns last chconfigure string
#
#
#    # ---not doc----
#
#
#    # lalllalalaal
#
#
#    puts end
#    return 1
#}
#
#proc f1 {} {
#
#    # Help
#    # Run:
#    #     $call
#    #
#    # to see result
#      
#    # lalalalal
#    # ---not doc----
#
#    puts end
#    return 1
#}
#puts [mydoc::doc f2]
