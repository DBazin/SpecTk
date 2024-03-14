proc CreateAssignDialog {} {
	global spectk
	set w $spectk(drawer).pages.assign
	frame $w.info -borderwidth 2 -relief groove
	frame $w.tree
	frame $w.entry
	frame $w.divider
	frame $w.buttons
	grid $w.info -sticky news
	grid $w.tree -sticky news
	grid $w.entry -sticky news
	grid $w.divider -sticky news
	grid $w.buttons -sticky news
	grid rowconfigure $w 0 -weight 0
	grid rowconfigure $w 1 -weight 1
	grid rowconfigure $w 2 -weight 0
	grid rowconfigure $w 3 -weight 0
	grid rowconfigure $w 4 -weight 0
	grid columnconfigure $w 0 -weight 1
	grid propagate $w 1

# Info frame
	set w $spectk(drawer).pages.assign.info.label
	frame $w
	pack $w -side left
	label $w.name -text Name: -font "general"
	label $w.type -text Type: -font "general"
	label $w.xpar -text X: -font "general"
	label $w.ypar -text Y: -font "general"
	label $w.gate -text Gate: -font "general"
	pack $w.name $w.type $w.xpar $w.ypar $w.gate -anchor w -side top
	set spectk(spectrumName) ""
	set spectk(spectrumType) ""
	set spectk(spectrumX) ""
	set spectk(spectrumY) ""
	set spectk(spectrumGate) ""
	set spectk(spectrum) ""
	set w $spectk(drawer).pages.assign.info.data
	frame $w
	label $w.name -textvariable spectk(spectrumName) -font "generalbold"
	label $w.type -textvariable spectk(spectrumType) -font "generalbold"
	label $w.xpar -textvariable spectk(spectrumX) -font "generalbold"
	label $w.ypar -textvariable spectk(spectrumY) -font "generalbold"
	label $w.gate -textvariable spectk(spectrumGate) -font "generalbold"
	pack $w.name $w.type $w.xpar $w.ypar $w.gate -anchor w -side top
	pack $w -side left -anchor w

# Tree frame
	set w $spectk(drawer).pages.assign.tree
#	CreateTreeSpectrum $w
	TreeSpectrum $w
	scrollbar $w.xbar -orient horizontal -command "$w.tree xview" -takefocus 0 -width 12
	scrollbar $w.ybar -orient vertical -command "$w.tree yview" -takefocus 0 -width 12
	$w.tree configure -xscrollcommand "$w.xbar set" -yscrollcommand "$w.ybar set"
	$w.tree configure -width 400
	grid $w.tree $w.ybar -sticky news
	grid $w.xbar x -sticky news
	grid columnconfigure $w 0 -weight 1
	grid columnconfigure $w 1 -weight 0
	grid rowconfigure $w 0 -weight 1
	grid rowconfigure $w 1 -weight 0

# Entry frame
	set w $spectk(drawer).pages.assign.entry
	label $w.label -text Spectrum: -font "general" -anchor w
	label $w.selected -textvariable spectk(spectrum) -width 20 -anchor w
	pack $w.label $w.selected -side left -expand 1 -fill x
	
# Divider frame
	set w $spectk(drawer).pages.assign.divider
	label $w.label -text Divider(s): -font "general" -anchor w
	entry $w.divider -textvariable spectk(smartmenu) -width 3 -background white
	button $w.divide -text Process -command UpdateAssignDialog
	pack $w.label $w.divider $w.divide -side left -expand 1 -fill x

# Button frame
	set w $spectk(drawer).pages.assign.buttons
	button $w.display -text Display -width 8 -command DoAssignButton -takefocus 0 \
	-activebackground lightgreen -underline 0
	button $w.superpose -text Superpose -width 8 -command SuperposeSelected -takefocus 0 -activebackground lightgreen
	grid $w.display $w.superpose -sticky news
	
# Bindings
#	bind $spectk(drawer).pages.assign <Enter> UpdateAssignDialog
}

proc UpdateAssignDialog {} {
	global spectk
	if {[string equal $spectk(smartmenu) ""]} {return}
	set w $spectk(drawer).pages.assign.tree
	if {[string equal $spectk(smartmenu) $spectk(smartprevious)]} {
		TreeSpectrum $w
		return
	}
	set spectk(smartprevious) $spectk(smartmenu)
	destroy $w.tree $w.xbar $w.ybar
	TreeSpectrum $w
	scrollbar $w.xbar -orient horizontal -command "$w.tree xview" -width 12
	scrollbar $w.ybar -orient vertical -command "$w.tree yview" -width 12
	$w.tree configure -xscrollcommand "$w.xbar set" -yscrollcommand "$w.ybar set"
	$w.tree configure -width 400
	grid $w.tree $w.ybar -sticky news
	grid $w.xbar x -sticky news
	grid columnconfigure $w 0 -weight 1
	grid columnconfigure $w 1 -weight 0
	grid rowconfigure $w 0 -weight 1
	grid rowconfigure $w 1 -weight 0
}

proc AssignSelected {} {
	global spectk
	if {[string equal $spectk(spectrum) ""]} {return}
	set page [lindex [split [$spectk(pages) tab cget select -window] .] end]
	set selected [$page GetMember selected]
	foreach id $selected {
		$page AssignSpectrum $id
	}
}

proc AssignSelectedPlus {} {
	global spectk
	if {[string equal $spectk(spectrum) ""]} {return}
	set page [lindex [split [$spectk(pages) tab cget select -window] .] end]
	set selected [$page GetMember selected]
	foreach id $selected {
		$page AssignSpectrum $id
	}
	scan $id "R%dC%d" row column
	incr column
	if {$column == [$page GetMember columns]} {
		set column 0
		incr row
	}
	if {$row == [$page GetMember rows]} {
		set row 0
	}
	set id [format "R%dC%d" $row $column]
	set mode $spectk(selectMode)
	set spectk(selectMode) single
	$page SelectDisplay $id 1
	set spectk(selectMode) $mode
}

proc reAssignSelectedPlus {} {
	global spectk
	if {[string equal $spectk(spectrum) ""]} {return}
	set page [lindex [split [$spectk(pages) tab cget select -window] .] end]
	set selected [$page GetMember selected]
	foreach id $selected {
		reAssign $id
	}
	scan $id "R%dC%d" row column
	incr column
	if {$column == [$page GetMember columns]} {
		set column 0
		incr row
	}
	if {$row == [$page GetMember rows]} {
		set row 0
	}
	set id [format "R%dC%d" $row $column]
	set mode $spectk(selectMode)
	set spectk(selectMode) single
	$page SelectDisplay $id 1
	set spectk(selectMode) $mode
}

proc SuperposeSelected {} {
	global spectk
	if {[string equal $spectk(spectrum) ""]} {return}
# Check that we are trying to superpose a 1D spectrum
	set type [lindex [spectrum -list $spectk(spectrum)] 2]
	if {[string equal $type b]} {set type 1}
	if {[string equal $type g1]} {set type 1}
	if {[string equal $type s]} {set type 2}
	if {[string equal $type g2]} {set type 2}
	if {$type != 1} {
		tk_messageBox -icon error -message "Can only superpose 1D spectra with same units"
		return
	}
	set para [lindex [spectrum -list $spectk(spectrum)] 3]
	set unit [lindex [lindex [parameter -list $para] 3] 2]
	set page [lindex [split [$spectk(pages) tab cget select -window] .] end]
	set selected [$page GetMember selected]
	foreach id $selected {
		set obj [itcl::find objects]
		if {[lsearch $obj $page$id] == -1} {continue}
# Check that superposed spectrum has same units as already displayed
		set wave [lindex [$page$id GetMember waves] 0]
		set match [$wave GetMember unit]
		if {[string equal $match $unit]} {
			$page AppendSpectrum $id
		}
	}
}

proc SelectAssignButton {} {
	global spectk
	set w $spectk(drawer).pages.assign.buttons
	if {[string equal [$w.display cget -text] Display]} {
		$w.display configure -text Display+
	} else {
		$w.display configure -text Display
	}
}

proc DoAssignButton {} {
	global spectk
	set w $spectk(drawer).pages.assign.buttons
	if {[string equal [$w.display cget -text] Display]} {
		AssignSelected
	} else {
		AssignSelectedPlus
	}
}
