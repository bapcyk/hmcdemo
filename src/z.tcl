lappend auto_path {C:\Tcl\lib\teapot\package\tcl\lib\BWidget1.9.5}
package require BWidget
 Tree .t ;# Because of the way BWidget is written it is not BWidget::Tree
 pack .t
 .t insert end root   fruit      -text fruit
 .t insert end fruit  apple      -text apple
 .t insert end fruit  orange     -text orange
 .t insert end fruit  peach      -text peach
 .t insert end fruit  grape      -text grape
 .t insert end root   cake       -text cake
 .t insert end cake   cheese     -text cheese
 .t insert end cake   cream      -text cream
 .t insert end cake   strawberry -text strawberry
 .t insert end root   drinks     -text drinks
 .t insert end drinks coffee     -text coffee
 .t insert end drinks tea        -text tea
 .t insert end drinks beer       -text beer
 .t insert end drinks water      -text water

