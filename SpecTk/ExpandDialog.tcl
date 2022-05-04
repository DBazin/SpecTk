proc CreateExpandDialog {} {
	global spectk
	set w $spectk(drawer).pages.expand
	frame $w.main
	pack $w.main
	pack $w -expand 1 -fill y
	
	set w $spectk(drawer).pages.expand.main
	label $w.dlabel -text Graph -font "generalbold"
	grid $w.dlabel - - -sticky news
	label $w.display -textvariable spectk(expanddisplay) -font "general"
	grid $w.display - - -sticky news
	
	button $w.updatesel -text "Load from Graph" -command LoadExpandDialog -font "general"
	grid $w.updatesel - - -sticky news
	
	label $w.xminlabel -text "xmin:" -font "generalbold" -anchor w
	entry $w.xminvalue -textvariable spectk(expandxmin) -background white -width 8
	label $w.xminunit -textvariable spectk(expandunitx) -font "generalbold" -anchor w
	grid $w.xminlabel $w.xminvalue $w.xminunit -sticky news
	
	label $w.xmaxlabel -text "xmax:" -font "generalbold" -anchor w
	entry $w.xmaxvalue -textvariable spectk(expandxmax) -background white -width 8
	label $w.xmaxunit -textvariable spectk(expandunitx) -font "generalbold" -anchor w
	grid $w.xmaxlabel $w.xmaxvalue $w.xmaxunit -sticky news

	label $w.yminlabel -text "ymin:" -font "generalbold" -anchor w
	entry $w.yminvalue -textvariable spectk(expandymin) -background white -width 8
	label $w.yminunit -textvariable spectk(expandunity) -font "generalbold" -anchor w
	grid $w.yminlabel $w.yminvalue $w.yminunit -sticky news
	
	label $w.ymaxlabel -text "ymax:" -font "generalbold" -anchor w
	entry $w.ymaxvalue -textvariable spectk(expandymax) -background white -width 8
	label $w.ymaxunit -textvariable spectk(expandunity) -font "generalbold" -anchor w
	grid $w.ymaxlabel $w.ymaxvalue $w.ymaxunit -sticky news

	set spectk(expandauto) 1
	label $w.verlabel -text "Data:" -font "generalbold" -anchor w
	radiobutton $w.verauto -text Auto -font "general" -variable spectk(expandauto) \
	-value 1
	radiobutton $w.vermanual -text Manual -font "general" -variable spectk(expandauto) \
	-value 0
	grid $w.verlabel $w.verauto $w.vermanual -sticky news

	label $w.minlabel -text "min:" -font "generalbold" -anchor w
	entry $w.minvalue -textvariable spectk(expandmin) -background white -width 8
	label $w.minunit -textvariable spectk(expandunit) -font "generalbold" -anchor w
	grid $w.minlabel $w.minvalue $w.minunit -sticky news
	
	label $w.maxlabel -text "max:" -font "generalbold" -anchor w
	entry $w.maxvalue -textvariable spectk(expandmax) -background white -width 8
	label $w.maxunit -textvariable spectk(expandunit) -font "generalbold" -anchor w
	grid $w.maxlabel $w.maxvalue $w.maxunit -sticky news
	
	button $w.expsel -text "Expand Selected" -command ExpandSelected -font "general"
	grid $w.expsel - - -sticky news
	
	button $w.unexpsel -text "Unexpand Selected" -command UnexpandSelected -font "general"
	grid $w.unexpsel - - -sticky news
		
	button $w.exppage -text "Expand Page" -command ExpandPage -font "general"
	grid $w.exppage - - -sticky news
	
	button $w.unexppage -text "Unexpand Page" -command UnexpandPage -font "general"
	grid $w.unexppage - - -sticky news
}

proc LoadExpandDialog {} {
	global spectk
	set tab [$spectk(pages) id select]
	if {[string equal $tab ""]} {return}
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split $frame .] end]
	set current [$page GetMember current]
	set display [format %s%s $page $current]
	if {[lsearch [itcl::find object] $display] == -1} {return}
	set graph [$display GetMember graph]
	set xl [$graph axis limits x]
	set yl [$graph axis limits y]
	set spectk(expandunit) [$display GetMember vunit]
	if {[$display isa Display1D]} {
		set spectk(expandunitx) [$display GetMember unit]
		set spectk(expandunity) ""
		set spectk(expandxmin) [lindex $xl 0]
		set spectk(expandxmax) [lindex $xl 1]
		set spectk(expandymin) ""
		set spectk(expandymax) ""
		set spectk(expandmin) [lindex $yl 0]
		set spectk(expandmax) [lindex $yl 1]
	}
	if {[$display isa Display2D]} {
		set spectk(expandunitx) [lindex [$display GetMember unit] 0]
		set spectk(expandunity) [lindex [$display GetMember unit] 1]
		set spectk(expandxmin) [lindex $xl 0]
		set spectk(expandxmax) [lindex $xl 1]
		set spectk(expandymin) [lindex $yl 0]
		set spectk(expandymax) [lindex $yl 1]
		set palette [$display GetMember palette]
		set spectk(expandmin) [lindex [$palette GetMember scale] 0]
		set spectk(expandmax) [lindex [$palette GetMember scale] end]
	}
}

proc UpdateExpandDialog {} {
	global spectk
	set tab [$spectk(pages) id select]
	if {[string equal $tab ""]} {return}
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split $frame .] end]
	set current [$page GetMember current]
	set display [format %s%s $page $current]
	if {[lsearch [itcl::find object] $display] != -1} {
		set graph [$display GetMember graph]
		if {[winfo exist $graph]} {set spectk(expanddisplay) [$graph cget -title]}
	} else {
		set spectk(expanddisplay) ""
	}
}

proc ExpandSelected {} {
	global spectk
	set tab [$spectk(pages) id select]
	if {[string equal $tab ""]} {return}
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split $frame .] end]
	set selected [$page GetMember selected]
	foreach id $selected {
		set display [format %s%s $page $id]
		ExpandDisplay $display
	}
}

proc ExpandPage {} {
	global spectk
	set tab [$spectk(pages) id select]
	if {[string equal $tab ""]} {return}
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split $frame .] end]
	set rows [$page GetMember rows]
	set cols [$page GetMember columns]
	for {set ir 0} {$ir < $rows} {incr ir} {
		for {set ic 0} {$ic < $cols} {incr ic} {
			set display [format %sR%dC%d $page $ir $ic]
			ExpandDisplay $display
		}
	}
}

proc ExpandDisplay {display} {
	global spectk
	if {[lsearch [itcl::find object] $display] == -1} {return}
	set graph [$display GetMember graph]
	if {[$display isa Display1D]} {
		if {![string equal $spectk(expandunity) ""]} {return}
		if {![string equal $spectk(expandunitx) [$display GetMember unit]]} {return}
		$graph axis configure x -min $spectk(expandxmin) -max $spectk(expandxmax)
		$display SetMember xmin $spectk(expandxmin)
		$display SetMember xmax $spectk(expandxmax)
		if {$spectk(expandauto)} {
			$display ExpandAuto
		} else {
			$graph axis configure y -min $spectk(expandmin) -max $spectk(expandmax)
			$display SetMember autoscale 0
			$display SetMember min $spectk(expandmin)
			$display SetMember max $spectk(expandmax)
		}
		set center [expr ($spectk(expandxmax)+$spectk(expandxmin))/2]
		$display SetMember center $center
	}
	if {[$display isa Display2D]} {
		if {[string equal $spectk(expandunity) ""]} {return}
		if {![string equal "$spectk(expandunitx) $spectk(expandunity)" \
		[$display GetMember unit]]} {return}
		$display SetMember xmin $spectk(expandxmin)
		$display SetMember xmax $spectk(expandxmax)
		$display SetMember ymin $spectk(expandymin)
		$display SetMember ymax $spectk(expandymax)
		$display ZoomImage
		set palette [$display GetMember palette]
		if {$spectk(expandauto)} {
			$palette SetMember min 1
			$display ExpandAuto
		} else {
			$palette SetScale $spectk(expandmin) $spectk(expandmax)
			$display UpdateScale
			$display ResizeImage
			$display SetMember autoscale 0
			$display SetMember min $spectk(expandmin)
			$display SetMember max $spectk(expandmax)
		}
		set center "[expr ($spectk(expandxmax)+$spectk(expandxmin))/2] [expr ($spectk(expandymax)+$spectk(expandymin))/2]"
		$display SetMember center $center
	}
}

proc UnexpandSelected {} {
	global spectk
	set tab [$spectk(pages) id select]
	if {[string equal $tab ""]} {return}
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split $frame .] end]
	set selected [$page GetMember selected]
	foreach id $selected {
		set display [format %s%s $page $id]
		UnexpandDisplay $display
	}
}

proc UnexpandPage {} {
	global spectk
	set tab [$spectk(pages) id select]
	if {[string equal $tab ""]} {return}
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split $frame .] end]
	set rows [$page GetMember rows]
	set cols [$page GetMember columns]
	for {set ir 0} {$ir < $rows} {incr ir} {
		for {set ic 0} {$ic < $cols} {incr ic} {
			set display [format %sR%dC%d $page $ir $ic]
			UnexpandDisplay $display
		}
	}
}

proc UnexpandDisplay {display} {
	global spectk
	if {[lsearch [itcl::find object] $display] == -1} {return}
	$display UnZoom
	if {$spectk(expandauto)} {
		if {[$display isa Display2D]} {
			set palette [$display GetMember palette]
			$palette SetMember min 1
		}
		$display ExpandAuto
	}
}

