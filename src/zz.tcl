#lappend auto_path {C:\Tcl\lib\teapot\package\tcl\lib\BWidget1.9.5}
lappend auto_path {lib\BWidget1.9.5}

package require BWidget
 ScrolledWindow .sw
 pack .sw
 Tree .sw.t
 pack .sw.t
 .sw setwidget .sw.t   ;# Make ScrolledWindow manage the Tree widget
 update                ;# Process all UI events before moving on.

 .sw.t insert end root   fruit      -text fruit
 .sw.t insert end fruit  apple      -text apple
 .sw.t insert end fruit  orange     -text orange
 .sw.t insert end fruit  peach      -text peach
 .sw.t insert end fruit  grape      -text grape
 .sw.t insert end root   cake       -text cake
 .sw.t insert end cake   cheese     -text cheese
 .sw.t insert end cake   cream      -text cream
 .sw.t insert end cake   strawberry -text strawberry
 .sw.t insert end root   drinks     -text drinks
 .sw.t insert end drinks coffee     -text coffee
 .sw.t insert end drinks tea        -text tea
 .sw.t insert end drinks beer       -text beer
 .sw.t insert end drinks water      -text water

