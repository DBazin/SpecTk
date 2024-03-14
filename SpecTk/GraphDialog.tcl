proc CreateGraphDialog {} {
	global spectk
	
	set spectk(symboltype) none
	set spectk(symbolsize) 4
	set spectk(linestyle) step
	set spectk(legend) 1
	set spectk(errorbars) 0
	set spectk(xgrid1d) 0
	set spectk(ygrid1d) 0
	set spectk(xgrid2d) 0
	set spectk(ygrid2d) 0
	
# Graph 1D options
	set w $spectk(drawer).pages.graph.1d
	frame $w -borderwidth 2 -relief sunken
	label $w.title -text "1D Graphs" -font generalbold
	frame $w.trace -borderwidth 2 -relief groove
	frame $w.symbol -borderwidth 2 -relief groove
	frame $w.line -borderwidth 2 -relief groove
	frame $w.options -borderwidth 2 -relief groove
	frame $w.buttons -borderwidth 2 -relief groove
	grid $w.title -sticky news
	grid $w.trace -sticky news
	grid $w.symbol -sticky news
	grid $w.line -sticky news
	grid $w.options -sticky news
	grid $w.buttons -sticky news
	grid columnconfigure $w 0 -weight 1
	pack $w -expand 1 -fill both
	pack $spectk(drawer).pages.graph
	
# Trace frame
	set w $spectk(drawer).pages.graph.1d.trace
	label $w.label -text "Trace:" -font "generalbold" -anchor w
	menubutton $w.trace -text "Choose trace" -menu $w.trace.menu -font "general"
	menu $w.trace.menu -tearoff 0
	grid $w.label $w.trace -sticky news
	
# Symbol frame
	set w $spectk(drawer).pages.graph.1d.symbol
	label $w.title -text "Symbol" -font "generalbold"
	label $w.ltype -text "Type:" -font "generalbold" -anchor w
	menubutton $w.type -menu $w.type.menu -textvariable spectk(symboltype) -font "general"
	menu $w.type.menu -tearoff 0
	$w.type.menu add radiobutton -label "none" -variable spectk(symboltype) -value none -font "general"
	$w.type.menu add radiobutton -label "square" -variable spectk(symboltype) -value square -font "general"
	$w.type.menu add radiobutton -label "circle" -variable spectk(symboltype) -value circle -font "general"
	$w.type.menu add radiobutton -label "diamond" -variable spectk(symboltype) -value diamond -font "general"
	$w.type.menu add radiobutton -label "plus" -variable spectk(symboltype) -value plus -font "general"
	$w.type.menu add radiobutton -label "cross" -variable spectk(symboltype) -value cross -font "general"
	$w.type.menu add radiobutton -label "splus" -variable spectk(symboltype) -value splus -font "general"
	$w.type.menu add radiobutton -label "scross" -variable spectk(symboltype) -value scross -font "general"
	$w.type.menu add radiobutton -label "triangle" -variable spectk(symboltype) -value triangle -font "general"
	label $w.lsize -text "Size:" -font "generalbold" -anchor w
	entry $w.size -background white -textvariable spectk(symbolsize) -width 4
	grid $w.title - - - -sticky news
	grid $w.ltype $w.type $w.lsize $w.size -sticky news
	
# Line frame
	set w $spectk(drawer).pages.graph.1d.line
	label $w.title -text "Line" -font "generalbold"
	label $w.lstyle -text "Style:" -font "generalbold" -anchor w
	menubutton $w.style -menu $w.style.menu -textvariable spectk(linestyle) -font "general"
	menu $w.style.menu -tearoff 0
	$w.style.menu add radiobutton -label "step" -variable spectk(linestyle) -value step -font "general"
	$w.style.menu add radiobutton -label "linear" -variable spectk(linestyle) -value linear -font "general"
	$w.style.menu add radiobutton -label "quadratic" -variable spectk(linestyle) -value quadratic -font "general"
	$w.style.menu add radiobutton -label "natural" -variable spectk(linestyle) -value natural -font "general"
	$w.style.menu add radiobutton -label "none" -variable spectk(linestyle) -value none -font "general"
	grid $w.title - -sticky news
	grid $w.lstyle $w.style -sticky news

# Options frame
	set w $spectk(drawer).pages.graph.1d.options
	checkbutton $w.legend -text "Legend" -font "general" -variable spectk(legend) -anchor w
	checkbutton $w.error -text "Error Bars" -font "general" -variable spectk(errorbars) -anchor w
	checkbutton $w.xgrid -text "X Grid" -font "general" -variable spectk(xgrid1d) -anchor w
	checkbutton $w.ygrid -text "Y Grid" -font "general" -variable spectk(ygrid1d) -anchor w
	grid $w.legend $w.error -sticky news
	grid $w.xgrid $w.ygrid -sticky news

# Buttons frame
	set w $spectk(drawer).pages.graph.1d.buttons
	button $w.apply -text "Apply" -command GraphDialogApply1D \
	-font "general" -state disable -width 12
	grid $w.apply -sticky news
	
# Graph 2D options
	set w $spectk(drawer).pages.graph.2d
	frame $w -borderwidth 2 -relief sunken
	label $w.title -text "2D Graphs" -font generalbold
	frame $w.options -borderwidth 2 -relief groove
	frame $w.buttons -borderwidth 2 -relief groove
	grid $w.title -sticky news
	grid $w.options -sticky news
	grid $w.buttons -sticky news
	pack $w -expand 1 -fill both -pady 10
	
# Options frame
	set w $spectk(drawer).pages.graph.2d.options
	checkbutton $w.xgrid -text "X Grid" -font "general" -variable spectk(xgrid2d) -anchor w
	checkbutton $w.ygrid -text "Y Grid" -font "general" -variable spectk(ygrid2d) -anchor w
	grid $w.xgrid $w.ygrid -sticky news

# Buttons frame
	set w $spectk(drawer).pages.graph.2d.buttons
	button $w.apply -text "Apply" -command GraphDialogApply2D \
	-font "general" -state disable -width 12
	grid $w.apply -sticky news
}

proc UpdateGraphDialog {} {
	global spectk
	set tab [$spectk(pages) id select]
	if {[string equal $tab ""]} {return}
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split $frame .] end]
	set current [$page GetMember current]
	set display [format %s%s $page $current]
# 1D graphs
	if {[lsearch [itcl::find object -isa Display1D] $display] != -1} {
		$spectk(drawer).pages.graph.1d.buttons.apply configure -state normal
		$spectk(drawer).pages.graph.2d.buttons.apply configure -state disable
		set w $spectk(drawer).pages.graph.1d.trace
		set waves [$display GetMember waves]
		$w.trace.menu delete 0 end
		foreach wave $waves {
			if {[lsearch [itcl::find object -isa Wave1D] $wave] != -1} {
				$w.trace.menu add command -label [$wave GetMember name] \
				-command "GraphDialogSelectTrace $display $wave" \
				-font "general"
			}
		}
		GraphDialogSelectTrace $display [lindex $waves 0]
		set spectk(xgrid1d) [$display GetMember xgrid]
		set spectk(ygrid1d) [$display GetMember ygrid]
# 2D graphs
	} elseif {[lsearch [itcl::find object -isa Display2D] $display] != -1} {
		$spectk(drawer).pages.graph.2d.buttons.apply configure -state normal
		$spectk(drawer).pages.graph.1d.buttons.apply configure -state disable
		set spectk(xgrid2d) [$display GetMember xgrid]
		set spectk(ygrid2d) [$display GetMember ygrid]
	} else {
		$spectk(drawer).pages.graph.2d.buttons.apply configure -state disable
		$spectk(drawer).pages.graph.1d.buttons.apply configure -state disable
	}
}

proc GraphDialogSelectTrace {display wave} {
	global spectk
	if {[lsearch [itcl::find object -isa Wave1D] $wave] == -1} {return}
	set spectk(trace) $wave
	set waves [$display GetMember waves]
	set index [lsearch $waves $wave]
	if {$index == -1} {return}
	$spectk(drawer).pages.graph.1d.trace.trace configure -text [$wave GetMember name]
	set symbol [lindex [$display GetMember symbol] $index]
	set size [lindex [$display GetMember pixels] $index]
	set errorbar [lindex [$display GetMember errorbar] $index]
	set style [lindex [$display GetMember smooth] $index]
	set linewidth [lindex [$display GetMember linewidth] $index]
	set legend [lindex [$display GetMember legend] $index]
	if {$linewidth == 0} {
		set spectk(linestyle) none
	} else {
		set spectk(linestyle) $style
	}
	set spectk(symboltype) $symbol
	set spectk(symbolsize) $size
	set spectk(legend) $legend
	set spectk(errorbars) $errorbar
}

proc GraphDialogApply1D {} {
	global spectk
	set tab [$spectk(pages) id select]
	if {[string equal $tab ""]} {return}
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split $frame .] end]
	set current [$page GetMember current]
	set display [format %s%s $page $current]
	set waves [$display GetMember waves]
	set i [lsearch $waves $spectk(trace)]
	set symbol [$display GetMember symbol]
	set size [$display GetMember pixels]
	set errorbar [$display GetMember errorbar]
	set style [$display GetMember smooth]
	set linewidth [$display GetMember linewidth]
	set legend [$display GetMember legend]
	set sym $spectk(symboltype)
	set siz $spectk(symbolsize)
	set err $spectk(errorbars)
	set leg $spectk(legend)
	if {[string equal $spectk(linestyle) none]} {
		set line 0
		set sty step
	} else {
		set line 1
		set sty $spectk(linestyle)
	}
	$display SetMember symbol [lreplace $symbol $i $i $sym]
	$display SetMember pixels [lreplace $size $i $i $siz]
	$display SetMember errorbar [lreplace $errorbar $i $i $err]
	$display SetMember smooth [lreplace $style $i $i $sty]
	$display SetMember linewidth [lreplace $linewidth $i $i $line]
	$display SetMember legend [lreplace $legend $i $i $leg]
	$display SetMember xgrid $spectk(xgrid1d)
	$display SetMember ygrid $spectk(ygrid1d)
	$display UpdateDisplay
}

proc GraphDialogApply2D {} {
	global spectk
	set tab [$spectk(pages) id select]
	if {[string equal $tab ""]} {return}
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split $frame .] end]
	set current [$page GetMember current]
	set display [format %s%s $page $current]
	$display SetMember xgrid $spectk(xgrid2d)
	$display SetMember ygrid $spectk(ygrid2d)
	$display UpdateDisplay
}

proc GDA_1D {id} {
	global spectk
	set tab [$spectk(pages) id select]
	if {[string equal $tab ""]} {return}
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split $frame .] end]
	set current [$page GetMember current]
	set display [format %s%s $page $id]
	set waves [$display GetMember waves]
	set i [lsearch $waves $spectk(trace)]
	set symbol [$display GetMember symbol]
	set size [$display GetMember pixels]
	set errorbar [$display GetMember errorbar]
	set style [$display GetMember smooth]
	set linewidth [$display GetMember linewidth]
	set legend [$display GetMember legend]
	set sym $spectk(symboltype)
	set siz $spectk(symbolsize)
	set err $spectk(errorbars)
	set leg $spectk(legend)
	if {[string equal $spectk(linestyle) none]} {
		set line 0
		set sty step
	} else {
		set line 1
		set sty $spectk(linestyle)
	}
	$display SetMember symbol [lreplace $symbol $i $i $sym]
	$display SetMember pixels [lreplace $size $i $i $siz]
	$display SetMember errorbar [lreplace $errorbar $i $i $err]
	$display SetMember smooth [lreplace $style $i $i $sty]
	$display SetMember linewidth [lreplace $linewidth $i $i $line]
	$display SetMember legend [lreplace $legend $i $i $leg]
	$display SetMember xgrid $spectk(xgrid1d)
	$display SetMember ygrid $spectk(ygrid1d)
	$display UpdateDisplay
}

proc GDA_2D {id} {
	global spectk
	puts "GDA_2D, $id"
	set tab [$spectk(pages) id select]
	if {[string equal $tab ""]} {return}
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split $frame .] end]
	set display [format "%s%s" $page $id]
	$display SetMember xgrid $spectk(xgrid2d)
	$display SetMember ygrid $spectk(ygrid2d)
	$display UpdateDisplay
}