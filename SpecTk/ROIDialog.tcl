proc CreateROIDialog {} {
	global spectk
	set spectk(roitype) roi
	set spectk(roispan) parameter
	set spectk(roiname) roi1
	set spectk(roiobject) ::ROI::roi1
	set spectk(roicoord) ""
	set w $spectk(drawer).pages.roi
	frame $w.create -borderwidth 2 -relief groove
	frame $w.history
	frame $w.buttons
	grid $w.create -sticky news
	grid $w.history -sticky news
	grid $w.buttons -sticky news
	grid rowconfigure $w 0 -weight 0
	grid rowconfigure $w 1 -weight 1
	grid rowconfigure $w 2 -weight 0
	grid columnconfigure $w 0 -weight 1

# Create frame
	set w $spectk(drawer).pages.roi.create

	label $w.type -text Type: -font "generalbold" -anchor w
	radiobutton $w.gate -text Gate -command ROIDialogGate -variable spectk(roitype) \
	-value gate -font "general" -anchor w
	radiobutton $w.roi -text ROI -command ROIDialogROI -variable spectk(roitype) \
	-value roi -font "general" -anchor w
	grid $w.type $w.gate $w.roi -sticky news

#	label $w.span -text Span: -font "Helvetica 10 bold" -anchor w
#	radiobutton $w.parameter -text Parameter -variable spectk(roispan) \
	-value parameter -font "Helvetica 10" -anchor w
#	radiobutton $w.unit -text Unit -variable spectk(roispan) \
	-value unit -font "Helvetica 10" -anchor w
#	grid $w.span $w.parameter $w.unit -sticky news

	button $w.slice -text Slice -command "ROIDialogCreateROI slice" -width 5
	button $w.contour -text Contour -command "ROIDialogCreateROI contour" -width 5
	button $w.band -text Band -command "ROIDialogCreateROI band" -width 5 -state disable
	grid $w.slice $w.contour $w.band -sticky news
	
	entry $w.coord -textvariable spectk(roicoord) -background white -width 10 -font "general"
	button $w.enter -text "X (Y)" -font "general" -command ROIDialogEnterPoint
	button $w.cancel -text "Cancel" -font "general" -command ROIDialogCancel
	button $w.validate -text "Validate" -font "general" -command ROIDialogValidate
	grid $w.coord - $w.enter -sticky news
	grid $w.cancel x $w.validate -sticky news

	menubutton $w.namemenu -text "Select:" -menu $w.namemenu.menu
	menu $w.namemenu.menu
	entry $w.name -textvariable spectk(roiname) -width 10 -background white
	grid $w.namemenu $w.name - -sticky news

	button $w.upgrade -text "Upgrade Selected to Gate" -font "general" -command ROIDialogUpgrade
	button $w.copyselected -text "Copy to selected Graph(s)" -font "general" -command ROIDialogCopyToSelected
#	button $w.copyall -text "Copy to all same unit Spectra" -font "general" -command ROIDialogCopyToAll
	button $w.deleteselected -text "Delete selected" -font "general" -command ROIDialogDeleteSelected
	button $w.deleteall -text "Delete all in selected Graph(s)" -font "general" -command ROIDialogDeleteAll
	grid $w.upgrade - - -sticky news
	grid $w.copyselected - - -sticky news
#	grid $w.copyall - - -sticky news
	grid $w.deleteselected - - -sticky news
	grid $w.deleteall - - -sticky news

# History frame
	set w $spectk(drawer).pages.roi.history
	text $w.text -width 100 -height 100 -font "results" -background white -wrap none 
	scrollbar $w.xbar -orient horizontal -command "$w.text xview" -width 12
	scrollbar $w.ybar -orient vertical -command "$w.text yview" -width 12
	$w.text configure -xscrollcommand "$w.xbar set" -yscrollcommand "$w.ybar set"
	$w.text tag configure green -font "results" -foreground darkgreen
	$w.text tag configure red -font "results" -foreground red
	$w.text tag configure blue -font "results" -foreground blue
	$w.text tag configure black -font "results" -foreground black
	grid $w.text $w.ybar -sticky news
	grid $w.xbar x -sticky news
	grid columnconfigure $w 0 -weight 1
	grid columnconfigure $w 1 -weight 0
	grid rowconfigure $w 0 -weight 1
	grid rowconfigure $w 1 -weight 0
	
# Buttons frame
	set w $spectk(drawer).pages.roi.buttons
	button $w.calcsel -text "Calculate Selected Graph(s)" -font "general" -command ROIDialogCalculateSelected
	button $w.calcall -text "Calculate Selected Page" -font "general" -command ROIDialogCalculateAll
	button $w.clear -text "Clear History" -font "general" -command ROIDialogClearHistory
	button $w.print -text "Write ROI" -font "general" -command printResults

	grid $w.calcsel -sticky news
	grid $w.calcall -sticky news
	grid $w.clear -sticky news
	grid $w.print -sticky news

	set w $spectk(drawer).pages.roi.create
	grid remove $w.coord $w.enter $w.cancel $w.validate
}

proc ROIDialogGate {} {
	global spectk
	set spectk(roitype) gate
#	set spectk(roispan) parameter
#	$spectk(drawer).pages.roi.create.unit configure -state disabled
}

proc ROIDialogROI {} {
	global spectk
	set spectk(roitype) roi
#	$spectk(drawer).pages.roi.create.unit configure -state normal
}

proc ROIDialogUpdateCreate {roi} {
	global spectk
	set spectk(roiobject) $roi
	set spectk(roiname) [$roi GetMember name]
	if {[$roi GetMember isgate]} {
		ROIDialogGate
	} else {
		ROIDialogROI
#		set spectk(roispan) [$roi GetMember span]
	}
}

proc UpdateROIDialog {} {
	global spectk
	set tab [$spectk(pages) id select]
	if {[string equal $tab ""]} {return}
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split $frame .] end]
	set selected [$page GetMember selected]
	set current [$page GetMember current]
	set display [format %s%s $page $current]
	set w $spectk(drawer).pages.roi.create
	$w.namemenu.menu delete 0 end
	if {[lsearch [itcl::find object] $display] != -1 && [winfo exist [$display GetMember graph]]} {
		if {[$display isa Display1D]} {
			$spectk(drawer).pages.roi.create.slice configure -state normal
			$spectk(drawer).pages.roi.create.contour configure -state disabled
			$spectk(drawer).pages.roi.create.band configure -state disabled
		}
		if {[$display isa Display2D]} {
			$spectk(drawer).pages.roi.create.slice configure -state disabled
			$spectk(drawer).pages.roi.create.contour configure -state normal
#			$spectk(drawer).pages.roi.create.band configure -state normal
		}
		foreach wave [$display GetMember waves] {
			if {[lsearch [itcl::find object] $wave] != -1} {
				foreach roi [$wave FindROIs] {
					$w.namemenu.menu add command -label [$roi GetMember name] \
					-command "ROIDialogUpdateCreate $roi"
				}
			}
		}
	} else {
		$spectk(drawer).pages.roi.create.slice configure -state disabled
		$spectk(drawer).pages.roi.create.contour configure -state disabled
		$spectk(drawer).pages.roi.create.band configure -state disabled
	}
}

proc ROIDialogCalculateSelected {} {
	global spectk
	set tab [$spectk(pages) id select]
	if {[string equal $tab ""]} {return}
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split $frame .] end]
	set selected [$page GetMember selected]
	set w $spectk(drawer).pages.roi.history
	foreach d $selected {
		set display [format %s%s $page $d]
		ROIDialogCalculateDisplay $display
	}
	$w.text see end
}

proc ROIDialogCalculateAll {} {
	global spectk
	set tab [$spectk(pages) id select]
	if {[string equal $tab ""]} {return}
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split $frame .] end]
	set rows [$page GetMember rows]
	set cols [$page GetMember columns]
	set w $spectk(drawer).pages.roi.history
	for {set ir 0} {$ir < $rows} {incr ir} {
		for {set ic 0} {$ic < $cols} {incr ic} {
			set display [format %sR%dC%d $page $ir $ic]
			ROIDialogCalculateDisplay $display
		}
	}
	$w.text see end
}

proc ROIDialogCalculateDisplay {display} {
	global spectk
	set w $spectk(drawer).pages.roi.history
	if {[lsearch [itcl::find object] $display] != -1} {
		foreach wave [$display GetMember waves] {
			$w.text insert end "[$wave GetMember name] ([$wave GetMember unit]):\n" "green"
			$w.text insert end "Gated on: [$wave GetMember gate]\n" "green"
			$wave CalculateAll
			set r [$wave GetMember calc(All)]
			if {[$display isa Display1D]} {
				$w.text insert end "ROI	Sum	Ratio	<X>	FWHM\n" "blue"
				$w.text insert end "All" "red" "	[lindex $r 0]	[lindex $r 1]	[lindex $r 2]	[lindex $r 3]\n" "black"
			}
			if {[$display isa Display2D]} {
				$w.text insert end "ROI	Sum	Ratio	<X/Y>	FWHM\n" "blue"
				$w.text insert end "All" "red" "	[lindex $r 0]	[lindex $r 1]	[lindex $r 2]	[lindex $r 4]\n" "black"
				$w.text insert end "			[lindex $r 3]	[lindex $r 5]\n" "black"
			}
			foreach roi [$wave FindROIs] {
				$wave CalculateROI $roi
				set r [$wave GetMember calc($roi)]
				if {[$display isa Display1D]} {
					$w.text insert end "[$roi GetMember name]" "red" "	[lindex $r 0]	[lindex $r 1]	[lindex $r 2]	[lindex $r 3]\n" "black"
				}
				if {[$display isa Display2D]} {
					$w.text insert end "[$roi GetMember name]" "red" "	[lindex $r 0]	[lindex $r 1]	[lindex $r 2]	[lindex $r 4]\n" "black"
					$w.text insert end "			[lindex $r 3]	[lindex $r 5]\n" "black"
				}
			}
			$w.text insert end "\n"
		}
	}
}

proc ROIDialogClearHistory {} {
	global spectk
	$spectk(drawer).pages.roi.history.text delete 1.0 end
}

proc ROIDialogCopyToSelected {} {
	global spectk
	if {[lsearch [itcl::find object -isa ROI] $spectk(roiobject)] == -1} {return}
	set tab [$spectk(pages) id select]
	if {[string equal $tab ""]} {return}
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split $frame .] end]
	set selected [$page GetMember selected]
	foreach d $selected {
		set display [format %s%s $page $d]
		set waves [$display GetMember waves]
		set w [lindex $waves 0]
# If the wave(s) have different units we don't make a copy
		if {![string equal [$w GetMember unit] [$spectk(roiobject) GetMember units]]} {continue}
		foreach w $waves {
# We don't want to redefine a ROI on the same parameter(s)
			if {[string equal [$w GetMember parameter] [$spectk(roiobject) GetMember parameters]]} {continue}
# No ROI on Bitmask and Summary waves
			if {[string equal [$w GetMember type] b] || [string equal [$w GetMember type] s]} {continue}
			set i 1
			set object $spectk(roiobject)_$i
			set name $spectk(roiname)_$i
			while {[lsearch [itcl::find object -isa ROI] $object] != -1} {
				incr i
				set object $spectk(roiobject)_$i
				set name $spectk(roiname)_$i
			}
			ROI $object $name
			$object SetMember parameters [$w GetMember parameter]
			$object SetMember units [$w GetMember unit]
			$object SetMember xlimits [$spectk(roiobject) GetMember xlimits]
			$object SetMember ylimits [$spectk(roiobject) GetMember ylimits]
			$object SetMember color [$spectk(roiobject) GetMember color]
			$object SetMember type [$spectk(roiobject) GetMember type]
			if {[string equal $spectk(roitype) gate]} {
				$object SetMember isgate 1
				$object GateDefine
			} else {
				$object SetMember isgate 0
				$object ProcessDisplays UpdateDisplay
			}
		}
	}
	UpdateROIDialog
}

proc ROIDialogDeleteSelected {} {
	global spectk
	if {[lsearch [itcl::find object -isa ROI] $spectk(roiobject)] == -1} {return}
	if {[$spectk(roiobject) GetMember isgate]} {
		gate -delete [$spectk(roiobject) GetMember name]
	} else {
		itcl::delete object $spectk(roiobject)
	}
	UpdateROIDialog
}

proc ROIDialogDeleteAll {} {
	global spectk
	set tab [$spectk(pages) id select]
	if {[string equal $tab ""]} {return}
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split $frame .] end]
	set selected [$page GetMember selected]
	foreach d $selected {
		set display [format %s%s $page $d]
		set waves [$display GetMember waves]
		foreach w $waves {
			foreach r [$w FindROIs] {
				$r ProcessDisplays RemoveDisplay
				if {[$r GetMember isgate]} {
					gate -delete [$r GetMember name]
				} else {
					itcl::delete object $r
				}
			}
		}
	}
	UpdateROIDialog
}

proc ROIDialogEnterPoint {} {
	global spectk
	if {[string equal $spectk(roicoord) ""]} {return}
	set x [lindex $spectk(roicoord) 0]
	set y 0
	if {[llength $spectk(roicoord)] > 1} {set y [lindex $spectk(roicoord) 1]}
	set xw [$spectk(roigraph) axis transform x $x]
	set yw [$spectk(roigraph) axis transform y $y]
	$spectk(roiobject) B1Create $spectk(roigraph) $spectk(roikind) $xw $yw
}

proc ROIDialogCreateROI {rtype} {
	global spectk
	set spectk(roikind) $rtype
	set tab [$spectk(pages) id select]
	if {[string equal $tab ""]} {return}
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split $frame .] end]
	set current [$page GetMember current]
	set display [format %s%s $page $current]
	set spectk(roigraph) [$display GetMember graph]
# bugbugbug: BLT crashes if we enter roi while roi display is on
	if {[winfo exist $spectk(roigraph).hide]} {$display HideROIResults}
	set waves [$display GetMember waves]
	set wave [lindex $waves 0]
	set stype [$wave GetMember type]
	set spectk(roiwave) $wave
	set w $spectk(drawer).pages.roi.create
# No ROI on Bitmask and Summary spectra
	if {[string equal $stype b] || [string equal $stype s]} {return}
# Find new ROI or Gate name
	set i 1
	if {[string equal $spectk(roitype) gate]} {
		while {[lsearch [itcl::find object -isa ROI] ::ROI::gate$i] != -1} {incr i}
		set spectk(roiobject) ::ROI::gate$i
		set spectk(roiname) gate$i
	} else {
		while {[lsearch [itcl::find object -isa ROI] ::ROI::roi$i] != -1} {incr i}
		set spectk(roiobject) ::ROI::roi$i
		set spectk(roiname) roi$i
	}
# Create new ROI
	ROI $spectk(roiobject) $spectk(roiname)
	set spectk(savedroiobject) $spectk(roiobject)
	set spectk(savedroiname) $spectk(roiname)
	set spectk(rtype) $rtype
# Indicate modal input by changing button color
	switch -- $rtype {
		slice {$w.slice configure -background red}
		contour {$w.contour configure -background red}
		band {$w.band configure -background red}
	}
# Setup bindings for entering ROI
	$spectk(roiobject) BindCreate [$display GetMember graph] $rtype
	set spectk(vwait) 0
	set spectk(limits) ""
# Disable all tool buttons to prevent other bindings
	foreach t [winfo children $spectk(tools)] {
		$t configure -state disable
	}
# Setup manual entry
	grid $w.coord - $w.enter
# Wait for user to input ROI
	vwait spectk(vwait)
	grid remove $w.coord $w.enter
# Setup for Cancellation or Validation
	grid $w.cancel x $w.validate
# If user wants to abort give up
	if {$spectk(vwait) == 0} {
		switch -- $rtype {
			slice {$spectk(drawer).pages.roi.create.slice configure -background lightgray}
			contour {$spectk(drawer).pages.roi.create.contour configure -background lightgray}
			band {$spectk(drawer).pages.roi.create.band configure -background lightgray}
		}
		itcl::delete object $spectk(roiobject)
		grid remove $w.cancel $w.validate
		foreach t [winfo children $spectk(tools)] {
			$t configure -state normal
		}
		return
	}
}

proc ROIDialogCancel {} {
	global spectk
	set w $spectk(drawer).pages.roi.create
	switch -- $spectk(rtype) {
		slice {$w.slice configure -background lightgray}
		contour {$w.contour configure -background lightgray}
		band {$w.band configure -background lightgray}
	}
	if {[lsearch [itcl::find object -isa ROI] $spectk(savedroiobject)] != -1} {itcl::delete object $spectk(savedroiobject)}
	if {[$spectk(roigraph) marker exist roi]} {$spectk(roigraph) marker delete roi}
	if {[$spectk(roigraph) marker exist roi2]} {$spectk(roigraph) marker delete roi2}
	grid remove $w.cancel $w.validate
# Enable tool buttons back
	foreach t [winfo children $spectk(tools)] {
		$t configure -state normal
	}
}

proc ROIDialogValidate {} {
	global spectk
	set w $spectk(drawer).pages.roi.create
	set wave $spectk(roiwave)
	set stype [$wave GetMember type]
	if {[$spectk(roigraph) marker exist roi]} {$spectk(roigraph) marker delete roi}
	if {[$spectk(roigraph) marker exist roi2]} {$spectk(roigraph) marker delete roi2}
# If the user entered a different name for the ROI
	if {![string equal $spectk(roiname) $spectk(savedroiname)]} {
		set spectk(roiobject) "::ROI::[Proper $spectk(roiname)]"
		if {[lsearch [itcl::find object -isa ROI] $spectk(roiobject)] == -1} {
			ROI $spectk(roiobject) $spectk(roiname)
		} else {
			$spectk(roiobject) ProcessDisplays RemoveDisplay
		}
		$spectk(roiobject) Copy $spectk(savedroiobject)
		$spectk(roiobject) SetMember name $spectk(roiname)
		itcl::delete object $spectk(savedroiobject)
	}
# Create ROI or gate
	switch -- $spectk(rtype) {
		slice {
			if {[string equal $stype 1]} {$spectk(roiobject) SetMember type s}
			if {[string equal $stype g1]} {$spectk(roiobject) SetMember type gs}			
			set x1 [lindex $spectk(limits) 0]
			set x2 [lindex $spectk(limits) 1]
			if {$x1 > $x2} {
				set xl "$x2 $x1"
			} else {
				set xl "$x1 $x2"
			}
			set yl ""
			$spectk(roiobject) SetMember color red
			$w.slice configure -background lightgray
		}
		contour {
			if {[string equal $stype 2]} {$spectk(roiobject) SetMember type c}
			if {[string equal $stype g2]} {$spectk(roiobject) SetMember type gc}
			for {set i 0} {$i < [llength $spectk(limits)]} {incr i 2} {
				lappend xl [lindex $spectk(limits) $i]
				lappend yl [lindex $spectk(limits) [expr $i+1]]
			}
			$spectk(roiobject) SetMember color red
			$w.contour configure -background lightgray
		}
		band {
			if {[string equal $stype 2]} {$spectk(roiobject) SetMember type b}
			if {[string equal $stype g2]} {$spectk(roiobject) SetMember type gb}
			for {set i 0} {$i < [llength $spectk(limits)]} {incr i 2} {
				lappend xl [lindex $spectk(limits) $i]
				lappend yl [lindex $spectk(limits) [expr $i+1]]
			}
			$spectk(roiobject) SetMember color red
			$w.band configure -background lightgray
		}
	}
	if {[string equal $stype g1] || [string equal $stype g2]} {
		$spectk(roiobject) SetMember parameters $wave
	} else {
		$spectk(roiobject) SetMember parameters [$wave GetMember parameter]
	}
	$spectk(roiobject) SetMember units [$wave GetMember unit]
	$spectk(roiobject) SetMember xlimits $xl
	$spectk(roiobject) SetMember ylimits $yl
# Calculate the newly defined ROI
	$spectk(roiwave) CalculateROI $spectk(roiobject)
	if {[string equal $spectk(roitype) gate]} {
		$spectk(roiobject) SetMember isgate 1
		$spectk(roiobject) GateDefine
	} else {
		$spectk(roiobject) SetMember isgate 0
		$spectk(roiobject) ProcessDisplays UpdateDisplay
	}
	grid remove $w.cancel $w.validate
# Enable tool buttons back
	foreach t [winfo children $spectk(tools)] {
		$t configure -state normal
	}
	UpdateROIDialog
}

proc ROIDialogUpgrade {} {
	global spectk
	if {[$spectk(roiobject) GetMember isgate]} {return}
	$spectk(roiobject) SetMember isgate 1
	$spectk(roiobject) GateDefine
#	$spectk(roiname) ProcessDisplays UpdateDisplay
}

proc ROIDialogPostScript {} {
	global spectk
	toplevel .temp
	set c .temp.roi
	set w [winfo width $spectk(drawer).pages.roi.history.text]
	set h [winfo height $spectk(drawer).pages.roi.history.text]
	canvas $c -width $w -height $h -bg white
	pack $c
	set t [$spectk(drawer).pages.roi.history.text get 1.0 end]
	$c create text 1 1 -text $t -font "results" -anchor nw
	update
	$c postscript -file roiresults.eps
	destroy .temp
}

proc printResults {} {

	global spectk
	set tab [$spectk(pages) id select]
	if {[string equal $tab ""]} {return}
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split $frame .] end]
	set rows [$page GetMember rows]
	set cols [$page GetMember columns]
	set w $spectk(drawer).pages.roi.history

	set fName [tk_getSaveFile -defaultextension ".csv" -filetypes {{"CSV Files" .csv} {"All Files" *}}]
	if {$fName eq ""} {return}

	set f [open $fName w]
	puts $f "ROI,Sum,Ratio,<X>,<Y>,FWHM1,FWHM2"
	for {set ir 0} {$ir < $rows} {incr ir} {
		for {set ic 0} {$ic < $cols} {incr ic} {
			set display [format %sR%dC%d $page $ir $ic]
			ROIPrint $display $f
		}
	}
	close $f
}

proc ROIPrint {display file} {
	if {[lsearch [itcl::find object] $display] != -1} {
		foreach wave [$display GetMember waves] {
			$wave CalculateAll
			set waveName [lindex [split [$display GetMember waves] "::"] end]
			set r [$wave GetMember calc(All)]
			if {[$display isa Display1D]} {
				puts $file " All- $waveName,[lindex $r 0],[lindex $r 1],[lindex $r 2],-,[lindex $r 3],-"
            		}

            		if {[$display isa Display2D]} {
				puts $file "All- $waveName,[lindex $r 0],[lindex $r 1],[lindex $r 2],[lindex $r 3],[lindex $r 4],[lindex $r 5]"
            		}

			foreach roi [$wave FindROIs] {
				$wave CalculateROI $roi
 				set r [$wave GetMember calc($roi)]

				if {[$display isa Display1D]} {
					puts $file "[$roi GetMember name],[lindex $r 0],[lindex $r 1],[lindex $r 2],-,[lindex $r 3],-"
				}

				if {[$display isa Display2D]} {
					puts $file "[$roi GetMember name],[lindex $r 0],[lindex $r 1],[lindex $r 2],[lindex $r 3],[lindex $r 4],[lindex $r 5]"
				}
			}
		}
	}
}

