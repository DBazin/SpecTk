proc SetupHelp {} {
	global spectk
	set w $spectk(help)
	set spectk(helpmessage) ""
	$spectk(help) configure -background white
	label $w.message -textvariable spectk(helpmessage) -font "general" -anchor w \
	-foreground darkred -background white
	pack $w.message -side left -expand 1 -fill x
}

proc EnableHelp {} {
	global spectk
	if {$spectk(helptoggle)} {
		grid $spectk(help)
		EnableHelpRecursive $spectk(toplevel)
		EnableHelpRecursive $spectk(drawer)
	} else {
		grid remove $spectk(help)
		DisableHelpRecursive $spectk(toplevel)
		DisableHelpRecursive $spectk(drawer)
	}
}

proc EnableHelpRecursive {w} {
	foreach c [winfo children $w] {
		if {![string equal [winfo children $c] ""]} {EnableHelpRecursive $c}
		if {[string match *utton [winfo class $c]]} {
			if {[string match .drawer.pages.geometry.grid.button* $c]} {continue}
			bind $c <Enter> "EnterHelp %W"
		}
	}
}

proc DisableHelpRecursive {w} {
	foreach c [winfo children $w] {
		if {![string equal [winfo children $c] ""]} {EnableHelpRecursive $c}
		if {[string match *utton [winfo class $c]]} {
			if {[string match .drawer.pages.geometry.grid.button* $c]} {continue}
			bind $c <Enter> ""
		}
	}
}

proc EnterHelp {w} {
	global spectk
	switch -- $w {
		.top.tools.select {
			set spectk(helpmessage) \
			"Select: Left=Select; Shift-Left=Gang; (Keyboard arrows have same effect)"
		}
		.top.tools.display {
			set spectk(helpmessage) \
			"Display: Left=Assign; Shift-Left=Append; Right=Remove; Shift-Right=Cancel"
		}
		.top.tools.zoom {
			set spectk(helpmessage) \
			"Expand: Left=Enter; Right=Cancel; Double-Left=Autoscale"
		}
		.top.tools.expand {
			set spectk(helpmessage) \
			"Data scale: Left=Enter (1D), Plus (2D); Right=Minus (2D); Double-Left=Auto"
		}
		.top.tools.scroll {
			set spectk(helpmessage) \
			"Scroll: scroll spectrum any direction"
		}
		.top.tools.inspect {
			set spectk(helpmessage) \
			"Inspect: display data"
		}
		.top.tools.edit {
			set spectk(helpmessage) \
			"Edit ROI: Left=Move highlighted; Shift-Left=Move together (1D)"
		}
		.top.buttons.select.single {
			set spectk(helpmessage) \
			"Single select mode; Use shift key to gang"
		}
		.top.buttons.select.row {
			set spectk(helpmessage) \
			"Row select mode; Use shift key to gang"
		}
		.top.buttons.select.column {
			set spectk(helpmessage) \
			"Column select mode; Use shift key to gang"
		}
		.top.buttons.select.all {
			set spectk(helpmessage) \
			"Select all graphs on page"
		}
		.top.buttons.spectrum.clearall {
			set spectk(helpmessage) \
			"Clear all graphs"
		}
		.top.buttons.spectrum.clearsel {
			set spectk(helpmessage) \
			"Clear graph(s) selected on page"
		}
		.top.buttons.spectrum.updateall {
			set spectk(helpmessage) \
			"Update all graphs on page"
		}
		.top.buttons.spectrum.updateselected {
			set spectk(helpmessage) \
			"Update graphs selected on page"
		}
		.top.buttons.spectrum.autoupdate.toggle {
			set spectk(helpmessage) \
			"Turn On/Off automatic page update"
		}
		.top.buttons.spectrum.ll.log {
			set spectk(helpmessage) \
			"Set Logarithmic scale"
		}
		.top.buttons.spectrum.ll.lin {
			set spectk(helpmessage) \
			"Set Linear scale"
		}
		.top.buttons.spectrum.pm.plus {
			set spectk(helpmessage) \
			"Increase data scale"
		}
		.top.buttons.spectrum.pm.minus {
			set spectk(helpmessage) \
			"Decrease data scale"
		}
		.top.buttons.spectrum.pm.autoscale {
			set spectk(helpmessage) \
			"Automatically adjust data scale"
		}
		.top.buttons.spectrum.zo.shrink {
			set spectk(helpmessage) \
			"Shrink around last expansion"
		}
		.top.buttons.spectrum.zo.expand {
			set spectk(helpmessage) \
			"Expand around last expansion"
		}
		.top.buttons.spectrum.zo.unzoom {
			set spectk(helpmessage) \
			"Unzoom to full scale"
		}
		.top.buttons.drawer.button {
			set spectk(helpmessage) \
			"Open/Close Drawer"
		}
		.top.buttons.drawer.expand {
			set spectk(helpmessage) \
			"Expand Drawer"
		}
		.top.buttons.drawer.shrink {
			set spectk(helpmessage) \
			"Shrink Drawer"
		}
		.drawer.pages.geometry.bottom.create {
			set spectk(helpmessage) \
			"Create new page with selected name and geometry after current page"
		}
		.drawer.pages.geometry.bottom.modify {
			set spectk(helpmessage) \
			"Modify current page with selected name and geometry"
		}
		.drawer.pages.geometry.bottom.delete {
			set spectk(helpmessage) \
			"Delete current page"
		}
		.drawer.pages.assign.divider.divide {
			set spectk(helpmessage) \
			"Rebuild spectrum tree using dividers"
		}
		.drawer.pages.assign.buttons.selected {
			set spectk(helpmessage) \
			"Assign spectrum to selected graph(s); Bound to return key if underlined"
		}
		.drawer.pages.assign.buttons.next {
			set spectk(helpmessage) \
			"Same as \"Selected\" and advance to next graph; Toggle return key binding with shift key"
		}
		.drawer.pages.expand.main.updatesel {
			set spectk(helpmessage) \
			"Load limits from current graph"
		}
		.drawer.pages.expand.main.verauto {
			set spectk(helpmessage) \
			"Set data scale to auto"
		}
		.drawer.pages.expand.main.vermanual {
			set spectk(helpmessage) \
			"Set data scale to manual"
		}
		.drawer.pages.expand.main.expsel {
			set spectk(helpmessage) \
			"Expand selected graph(s) according to entered limits"
		}
		.drawer.pages.expand.main.unexpsel {
			set spectk(helpmessage) \
			"Unexpand selected graph(s)"
		}
		.drawer.pages.expand.main.exppage {
			set spectk(helpmessage) \
			"Expand all graphs on page with same units"
		}
		.drawer.pages.expand.main.unexppage {
			set spectk(helpmessage) \
			"Unexpand all graphs on page with same units"
		}
		.drawer.pages.roi.create.gate {
			set spectk(helpmessage) \
			"Region Of Interest is also a SpecTcl gate"
		}
		.drawer.pages.roi.create.roi {
			set spectk(helpmessage) \
			"Region Of Interest is NOT a SpecTcl gate"
		}
		.drawer.pages.roi.create.slice {
			set spectk(helpmessage) \
			"Create or replace a 1D slice with specified name; Use right-click to cancel"
		}
		.drawer.pages.roi.create.contour {
			set spectk(helpmessage) \
			"Create or replace a 2D closed contour wiith specified name; Use right-click to cancel"
		}
		.drawer.pages.roi.create.band {
			set spectk(helpmessage) \
			"Create or replace a 2D band with specified name; Use right-click to cancel"
		}
		.drawer.pages.roi.create.enter {
			set spectk(helpmessage) \
			"Enter coordinates manually"
		}
		.drawer.pages.roi.create.namemenu {
			set spectk(helpmessage) \
			"Select Region Of Interest from current graph"
		}
		.drawer.pages.roi.create.copyselected {
			set spectk(helpmessage) \
			"Copy Region Of Interest to selected graph(s)"
		}
		.drawer.pages.roi.create.deleteselected {
			set spectk(helpmessage) \
			"Delete Region Of Interest with selected name"
		}
		.drawer.pages.roi.create.deleteall {
			set spectk(helpmessage) \
			"Delete all Regions Of Interest in selected graph(s)"
		}
		.drawer.pages.roi.buttons.calcsel {
			set spectk(helpmessage) \
			"Calculate for selected graph(s)"
		}
		.drawer.pages.roi.buttons.calcall {
			set spectk(helpmessage) \
			"Calculate for all graph(s) in current page"
		}
		.drawer.pages.roi.buttons.clear {
			set spectk(helpmessage) \
			"Clear calculation history"
		}
		.drawer.pages.fit.input.wave {
			set spectk(helpmessage) \
			"Choose data to fit from current graph"
		}
		.drawer.pages.fit.input.roi {
			set spectk(helpmessage) \
			"Choose Region Of Interest as fit boundaries from current graph"
		}
		.drawer.pages.fit.input.function {
			set spectk(helpmessage) \
			"Choose fitting function"
		}
		.drawer.pages.fit.input.guess {
			set spectk(helpmessage) \
			"Guess Initial values"
		}
		.drawer.pages.fit.buttons.dofit {
			set spectk(helpmessage) \
			"Attempt to fit data"
		}
		.drawer.pages.fit.buttons.clear {
			set spectk(helpmessage) \
			"Clear fitting results history"
		}
		.drawer.pages.fit.buttons.remove {
			set spectk(helpmessage) \
			"Remove fit from display"
		}
	}
	if {[string match .drawer.pages.fit.coeff.* $w]} {
		set spectk(helpmessage) \
		"Hold (selected) or free (unselected) coefficient"
	}
}

proc DisplayAbout {} {
	toplevel .about
	wm title .about "About SpecTk"
	text .about.text -background white -width 40 -height 16
	pack .about.text -expand 1 -fill both
	button .about.dismiss -text Dismiss -command "destroy .about"
	pack .about.dismiss
	.about.text tag configure big -font "Times -24" -justify center
	.about.text tag configure normal -font "Helvetica -12" -justify center
	.about.text tag configure green -foreground darkgreen
	.about.text insert end "SpecTk\n" "big green"
	.about.text insert end "version 1.4.3c\n" "normal green"
	.about.text insert end "01/29/2024\n\n" "normal green"
	.about.text insert end "A displayer for SpecTcl\n" "normal"
	.about.text insert end "\A9 NSCL/MSU 2004\n" "normal"
	.about.text insert end "Written after hours by D. Bazin\n" "normal"
	.about.text insert end "on a PowerBook G4 running Mac OS X\n" "normal"
	.about.text insert end "with the help of two great Tcl/Tk packages:\n" "normal"
	.about.text insert end "BLT 2.4z and Itcl 3.2\n" "normal"
	.about.text insert end "Inspired by Xamine, Igor Pro and Mac OS X\n\n" "normal"
	.about.text insert end "Please send comments and suggestions to:\n" "normal"
	.about.text insert end "bazin@frib.msu.edu" "normal"
	.about.text insert end "  or\n" "normal"
	.about.text insert end "kaloyano@frib.msu.edu" "normal"
	.about.text configure -state disabled
}
