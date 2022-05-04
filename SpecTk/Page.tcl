itcl::class Page {
	private variable rows
	private variable columns
	private variable index
	private variable selected
	private variable current
	private variable currentBinding
	private variable oneDisplay
	private variable postscript
	
	private variable parent
	private variable frame
	private variable display
	private variable Display
	
	constructor {w r c} {
		global spectk
		set parent $w
		set rows $r
		set columns $c
		set selected R0C0
		set current R0C0
		set currentBinding $spectk(currentTool)
		set buttonPressed 0
		set oneDisplay ""
		set name [string trimleft $this ::]
		set frame [frame $w.$name]
		if {[catch "$w tab cget select -text"]} {
			set index [$w insert end -text $name -window $frame]
		} else {
			set index [$w insert select -text $name -window $frame]
			$w move $index after [$w id select]
			$w select $index
		}
		$w tab configure $index -command "$this TabCommand"
		for {set ir 0} {$ir < $rows} {incr ir} {
			for {set ic 0} {$ic < $columns} {incr ic} {
				set id [format "R%dC%d" $ir $ic]
				set display($id) [frame $frame.display$id -borderwidth 2 -relief raised]
				grid $display($id) -row $ir -column $ic
				pack propagate $display($id) false
			}
		}
		Resize
		BindSelect
	}
	
	destructor {
		global spectk
		$spectk(pages) delete $index
		destroy $frame
		foreach id [array names Display] {
			itcl::delete object $Display($id)
		}
	}
	
	public method GetMember {m} {set $m}
	public method SetMember {m v} {set $m $v}
	public method GetReference {m} {upvar 1 $m ref; return $ref}
	public method Modify {n r c}
	public method Resize {}
	public method Magnify {id}
	public method Update {}
	public method Unbind {}
	public method BindSelect {}
	public method BindDisplay {}
	public method BindZoom {}
	public method BindScroll {}
	public method BindExpand {}
	public method BindInspect {}
	public method BindEdit {}
	public method SelectDisplay {id new}
	public method SelectSpectrum {id w s}
	public method AssignDisplay {id type}
	public method AssignSpectrum {id}
	public method AppendSpectrum {id}
	public method MenuAssignSpectrum {id w}
	public method MenuAppendSpectrum {id}
	public method MenuRemoveSpectrum {id}
	public method Write {file}
	public method Read {}
	public method Print {w h}
	public method PostScript {l}
	public method TabCommand {}
	public method RemoveDisplay {id} {unset Display($id)}
}

itcl::body Page::Resize {} {
	set fw [expr [winfo width $parent] - 20]
	set fh [expr [winfo height $parent] - 44]
	$frame configure -width $fw -height $fh
	if {[string equal $oneDisplay ""]} {
		set dw [expr $fw / $columns]
		set dh [expr $fh / $rows]
		foreach id [array names display] {
			$display($id) configure -width $dw -height $dh
			if {[info exist Display($id)]} {$Display($id) Resize}
		}
	} else {
		$display($oneDisplay) configure -width $fw -height $fh
		if {[info exist Display($oneDisplay)]} {$Display($oneDisplay) Resize}
	}
}

itcl::body Page::Modify {n r c} {
# Delete displays if we want less
	for {set ir 0} {$ir < $rows} {incr ir} {
		for {set ic 0} {$ic < $columns} {incr ic} {
			set id [format "R%dC%d" $ir $ic]
			if {$ir >= $r || $ic >= $c} {
				if {[info exist Display($id)]} {
					itcl::delete object $Display($id)
#					unset Display($id)
				}
				destroy $display($id)
				unset display($id)
				if {[set i [lsearch $selected $id]] != -1} {
					set selected [lreplace $selected $i $i]
				}
			}
		}
	}
# Create displays if we want more
	for {set ir 0} {$ir < $r} {incr ir} {
		for {set ic 0} {$ic < $c} {incr ic} {
			set id [format "R%dC%d" $ir $ic]
			if {$ir >= $rows || $ic >= $columns} {
				set display($id) [frame $frame.display$id -borderwidth 2 -relief raised]
				grid $display($id) -row $ir -column $ic
				pack propagate $display($id) false
				bind $display($id) <ButtonPress-1> "$this SelectDisplay $id 1"
				bind $display($id) <Shift-ButtonPress-1> "$this SelectDisplay $id 0"
				$display($id) configure -cursor arrow
			}
		}
	}
	set rows $r
	set columns $c
	$parent tab configure $index -text $n
#	UnBind
#	BindSelect
}

itcl::body Page::Update {} {
	foreach id [array names Display] {$Display($id) Update}
}

itcl::body Page::Unbind {} {
	set currentBinding None
	for {set ir 0} {$ir < $rows} {incr ir} {
		for {set ic 0} {$ic < $columns} {incr ic} {
			set id [format "R%dC%d" $ir $ic]
			foreach b [bind $display($id)] {bind $display($id) $b ""}
			if {[info exist Display($id)]} {$Display($id) Unbind}
			$display($id) configure -cursor left_ptr
		}
	}
}

itcl::body Page::BindSelect {} {
	Unbind
	set currentBinding BindSelect
	for {set ir 0} {$ir < $rows} {incr ir} {
		for {set ic 0} {$ic < $columns} {incr ic} {
			set id [format "R%dC%d" $ir $ic]
			bind $display($id) <ButtonPress-1> "$this SelectDisplay $id 1"
			bind $display($id) <Shift-ButtonPress-1> "$this SelectDisplay $id 0"
			$display($id) configure -cursor arrow
			if {[info exist Display($id)]} {
				$Display($id) Unbind
				$Display($id) BindSelect	
			}
		}
	}
	foreach d $selected {SelectDisplay $d 0}
}

itcl::body Page::SelectDisplay {id new} {
	global spectk
	set current $id
# if new = 1 we need to deselect the previously selected frames
	if {$new} {
		foreach f $selected {
			$display($f) configure -relief raised -background lightgray
			if {[info exist Display($f)] && [winfo exist $display($f).graph]} {
				$display($f).graph configure -background lightgray
			}
		}
	} else {
		foreach f $selected {
			$display($f) configure -relief sunken -background gray
			if {[info exist Display($f)] && [winfo exist $display($f).graph]} {
				$display($f).graph configure -background gray
			}
		}
	}
# Update current tool
	if {[llength [itcl::find objects [format "%s%s" $this $id]]]} {
		set spectk(currentTool) [[format "%s%s" $this $id] GetMember binding]
	} else {
		set spectk(currentTool) BindSelect
	}
# select frame we are on and others depending on selection mode
	switch -- $spectk(selectMode) {
		single {
			$display($id) configure -relief sunken -background darkgray
			if {[info exist Display($id)] && [winfo exist $display($id).graph]} {
				$display($id).graph configure -background darkgray
			}
		}
		all {
			for {set ir 0} {$ir < $rows} {incr ir} {
				for {set ic 0} {$ic < $columns} {incr ic} {
					set id [format "R%dC%d" $ir $ic]
					if {[string equal $id $current]} {set color darkgrey} else {set color gray}
					$display($id) configure -relief sunken -background $color
					if {[info exist Display($id)] && [winfo exist $display($id).graph]} {
						$display($id).graph configure -background $color
					}
				}
			}
		}
		row {
			scan $id "R%dC%d" ir ic
			for {set ic 0} {$ic < $columns} {incr ic} {
				set id [format "R%dC%d" $ir $ic]
				if {[string equal $id $current]} {set color darkgrey} else {set color gray}
				$display($id) configure -relief sunken -background $color
				if {[info exist Display($id)] && [winfo exist $display($id).graph]} {
					$display($id).graph configure -background $color
				}
			}
		}
		column {
			scan $id "R%dC%d" ir ic
			for {set ir 0} {$ir < $rows} {incr ir} {
				set id [format "R%dC%d" $ir $ic]
				if {[string equal $id $current]} {set color darkgrey} else {set color gray}
				$display($id) configure -relief sunken -background $color
				if {[info exist Display($id)] && [winfo exist $display($id).graph]} {
					$display($id).graph configure -background $color
				}
			}
		}
	}
# Update the list of selected frames
	set selected ""
	for {set ir 0} {$ir < $rows} {incr ir} {
		for {set ic 0} {$ic < $columns} {incr ic} {
			set id [format "R%dC%d" $ir $ic]
			if {[string equal [$display($id) cget -relief] sunken]} {lappend selected $id}
		}
	}
# Update ROI Dialog
	UpdateROIDialog
# Update Expand Dialog
	UpdateExpandDialog
# Update Fit Dialog
	UpdateFitDialog
# Update Graph Dialog
	UpdateGraphDialog
}

itcl::body Page::Magnify {id} {
	SelectDisplay $id 1
	if {[string equal $oneDisplay $id]} {
		set oneDisplay ""
		for {set ir 0} {$ir < $rows} {incr ir} {
			for {set ic 0} {$ic < $columns} {incr ic} {
				set id2 [format "R%dC%d" $ir $ic]
				grid $display($id2) -row $ir -column $ic
#				grid propagate $display($id) 0
			}
		}
		$this Resize
		$display($id).graph.magnify configure -image plus
	} else {
		set oneDisplay $id
		for {set ir 0} {$ir < $rows} {incr ir} {
			for {set ic 0} {$ic < $columns} {incr ic} {
				set id2 [format "R%dC%d" $ir $ic]
				if {$id2 != $id} {grid remove $display($id2)}
			}
		}
		$display($id) configure -width [$frame cget -width] -height [$frame cget -height]
		$Display($id) Resize
		$display($id).graph.magnify configure -image minus
	}
}

itcl::body Page::BindDisplay {} {
	global spectk
	Unbind
	set currentBinding BindDisplay
	for {set ir 0} {$ir < $rows} {incr ir} {
		for {set ic 0} {$ic < $columns} {incr ic} {
			set id [format "R%dC%d" $ir $ic]
			if {[info exist Display($id)] && [winfo exist $display($id).graph]} {
				$Display($id) Unbind
				bind $display($id).graph <ButtonPress-3> "set spectk(spectrum) \"\"; destroy $display($id).graph.popup"
				bind $display($id).graph <ButtonPress-1> "$this MenuAssignSpectrum $id $display($id).graph"
				bind $display($id).graph <Shift-ButtonPress-1> "$this MenuAppendSpectrum $id"
				bind $display($id).graph <Shift-ButtonPress-3> "$this MenuRemoveSpectrum $id"
				$display($id).graph configure -cursor cross
			} else {
				bind $display($id) <ButtonPress-3> "set spectk(spectrum) \"\"; destroy $display($id).popup"
				bind $display($id) <ButtonPress-1> "$this MenuAssignSpectrum $id $display($id)"
				$display($id) configure -cursor cross
			}
		}
	}
}

itcl::body Page::AssignDisplay {id type} {
# destroy existing display if it exists
	if {[info exist Display($id)]} {
		itcl::delete object $Display($id)
		if {[winfo exist $display($id).graph]} {destroy $display($id).graph}
	}
# create new one based on type and assign it to display frame
	set n [format "%s%s" $this $id]
	set Display($id) $n
	if {$type == 1} {
		Display1D $n $display($id)
	}
	if {$type == 2} {
		Display2D $n $display($id)
	}
}

itcl::body Page::MenuAssignSpectrum {id w} {
	global spectk
	if {![winfo exist $w.popup]} {
		menubutton $w.popup -text Assign
		pack $w.popup
	}
	UpdateTreeSpectrum $spectk(smartmenu)
	GenerateTreeSpectrumMenu $w.popup "$this SelectSpectrum $id $w"
	tkwait window $w.popup
	AssignSpectrum $id
	BindDisplay
}

itcl::body Page::AssignSpectrum {id} {
	global spectk
	if {[string equal $spectk(spectrum) ""]} {return}
# find type of spectrum
	set type [lindex [spectrum -list $spectk(spectrum)] 2]
	if {[string equal $type b]} {set type 1}
	if {[string equal $type g1]} {set type 1}
	if {[string equal $type s]} {set type 2}
	if {[string equal $type g2]} {set type 2}
	if {$type == 1} {set objectname "::Wave1D::[Proper $spectk(spectrum)]"}
	if {$type == 2} {set objectname "::Wave2D::[Proper $spectk(spectrum)]"}
# if wave doesn't exist we need to create it
	if {[lsearch [itcl::find object] $objectname] == -1} {		
		if {$type == 1} {Wave1D  $objectname $spectk(spectrum)}
		if {$type == 2} {Wave2D  $objectname $spectk(spectrum)}
	}
# assign wave with contents of spectrum
	$objectname Assign $spectk(spectrum)
# create ROI for gates (if any)
	$objectname CreateROI
# assign display to frame id
	AssignDisplay $id $type
# assign wave to display
	$Display($id) AssignWave $objectname
# update ROI displays
	$Display($id) UpdateROIs
# set binding to select
	$Display($id) BindSelect
}

itcl::body Page::SelectSpectrum {id w s} {
	global spectk
	set spectk(spectrum) $s
	destroy $w.popup
}

itcl::body Page::MenuAppendSpectrum {id} {
	global spectk
	if {![winfo exist $display($id).graph.popup]} {
		menubutton $display($id).graph.popup -text Append -width 8
		pack $display($id).graph.popup
	}
	if {[$Display($id) isa Display1D]} {
		set type 1
		set units [list [$Display($id) GetMember unit]]
	}
	if {[$Display($id) isa Display2D]} {
		set type 2
		set units [list [$Display($id) GetMember unitx] [$Display($id) GetMember unity]]
	}
	UpdateTreeSpectrumMatch $spectk(smartmenu) $type $units
	GenerateTreeSpectrumMenu $display($id).graph.popup "$this SelectSpectrum $id $display($id).graph"
	tkwait window $display($id).graph.popup
	AppendSpectrum $id
	BindDisplay
}

itcl::body Page::AppendSpectrum {id} {
	global spectk
	if {[string equal $spectk(spectrum) ""]} {return}
# find type of spectrum
	set type [lindex [spectrum -list $spectk(spectrum)] 2]
	if {[string equal $type b]} {set type 1}
	if {[string equal $type g1]} {set type 1}
	if {[string equal $type s]} {set type 2}
	if {[string equal $type g2]} {set type 2}
	if {$type == 1} {set objectname "::Wave1D::[Proper $spectk(spectrum)]"}
	if {$type == 2} {set objectname "::Wave2D::[Proper $spectk(spectrum)]"}
# if wave doesn't exist we need to create it
	if {[lsearch [itcl::find object] $objectname] == -1} {		
		if {$type == 1} {Wave1D  $objectname $spectk(spectrum)}
		if {$type == 2} {Wave2D  $objectname $spectk(spectrum)}
	}
# assign wave with contents of spectrum
	$objectname Assign $spectk(spectrum)
# create ROI for gates (if any)
	$objectname CreateROI
# append wave to display
	$Display($id) AppendWave $objectname
# update ROI displays
	$Display($id) UpdateROIs
}

itcl::body Page::MenuRemoveSpectrum {id} {
	global spectk
	if {![winfo exist $display($id).graph.popup]} {
		menubutton $display($id).graph.popup -text Remove -width 8
		pack $display($id).graph.popup
	}
	menu $display($id).graph.popup.menu -tearoff 0
	foreach w [$Display($id) GetMember waves] {
		$display($id).graph.popup.menu add command -label [$w GetMember name] \
		-command "$this SelectSpectrum $id $display($id).graph $w"
	}
	$display($id).graph.popup configure -menu $display($id).graph.popup.menu
	tkwait window $display($id).graph.popup
	if {[string equal $spectk(spectrum) ""]} {return}
	$Display($id) RemoveWave $spectk(spectrum)
# update ROI displays
	$Display($id) UpdateROIs
	BindDisplay
}

itcl::body Page::BindZoom {} {
	Unbind
	set currentBinding BindZoom
	for {set ir 0} {$ir < $rows} {incr ir} {
		for {set ic 0} {$ic < $columns} {incr ic} {
			set id [format "R%dC%d" $ir $ic]
			if {[info exist Display($id)]} {$Display($id) BindZoom}
		}
	}
}

itcl::body Page::BindScroll {} {
	Unbind
	set currentBinding BindScroll
	for {set ir 0} {$ir < $rows} {incr ir} {
		for {set ic 0} {$ic < $columns} {incr ic} {
			set id [format "R%dC%d" $ir $ic]
			if {[info exist Display($id)]} {$Display($id) BindScroll}
		}
	}
}

itcl::body Page::BindExpand {} {
	Unbind
	set currentBinding BindExpand
	for {set ir 0} {$ir < $rows} {incr ir} {
		for {set ic 0} {$ic < $columns} {incr ic} {
			set id [format "R%dC%d" $ir $ic]
			if {[info exist Display($id)]} {$Display($id) BindExpand}
		}
	}
}

itcl::body Page::BindInspect {} {
	Unbind
	set currentBinding BindInspect
	for {set ir 0} {$ir < $rows} {incr ir} {
		for {set ic 0} {$ic < $columns} {incr ic} {
			set id [format "R%dC%d" $ir $ic]
			if {[info exist Display($id)]} {$Display($id) BindInspect}
		}
	}
}

itcl::body Page::BindEdit {} {
	Unbind
	set currentBinding BindEdit
	for {set ir 0} {$ir < $rows} {incr ir} {
		for {set ic 0} {$ic < $columns} {incr ic} {
			set id [format "R%dC%d" $ir $ic]
			if {[info exist Display($id)]} {$Display($id) BindEdit}
		}
	}
}

itcl::body Page::Write {file} {
	set name [string trimleft $this :]
	puts $file "##### Begin Page $name definition #####"
	puts $file "Page $name $parent $rows $columns"
	puts $file "$name SetMember selected \"$selected\""
	puts $file "$name SetMember current $current"
	puts $file "$name SetMember currentBinding \"$currentBinding\""
	puts $file "$name SetMember oneDisplay \"$oneDisplay\""
	foreach n [array names display] {puts $file "$name SetMember display($n) $display($n)"}
	foreach n [array names Display] {puts $file "$name SetMember Display($n) $Display($n)"}
	puts $file "$parent tab configure \[$name GetMember index\] -text [$parent tab cget $index -text]"
	puts $file "##### End Page $name definition #####"
}

itcl::body Page::Read {} {
	global spectk
	foreach d [array names Display] {
		if {[llength [$Display($d) GetMember waves]] == 0} {
#			itcl::delete object $Display($d)
#			unset Display($d)
		}
	}
	$currentBinding
	foreach id $selected {SelectDisplay $id 0}
	Resize
}

itcl::body Page::PostScript {landscape} {
	global spectk
	foreach id [array names Display] {$Display($id) PostScript $landscape}
}

itcl::body Page::TabCommand {} {
	global spectk
	UpdateGeometryDialog
	UpdateROIDialog
	UpdateExpandDialog
	UpdateFitDialog
	UpdateGraphDialog
	if {$spectk(pageUpdate)} {Update}
# Update current tool
	if {[llength [itcl::find objects [format "%s%s" $this $current]]]} {
		set spectk(currentTool) [[format "%s%s" $this $current] GetMember binding]
	} else {
		set spectk(currentTool) BindSelect
	}
}

itcl::body Page::Print {width height} {
	global spectk postscriptfunctions
	set dwidth [expr $width/$columns]
	set dheight [expr $height/$rows]
	foreach id [array names Display] {set dpost($id) [$Display($id) Print $dwidth $dheight]}
	if {![array exist dpost]} {return}
	foreach id [array names dpost] {if {[info exist dpost($id)]} {break}}
	set i [string first BoundingBox: $dpost($id)]
	set dbound [string range $dpost($id) [expr $i+13] [expr $i+27]]
	set dwidth [expr [lindex $dbound 2] - [lindex $dbound 0] + 1]
	set dheight [expr [lindex $dbound 3] - [lindex $dbound 1] + 1]
	set llx [expr int((610-$width)/2)]
	set urx [expr int((610+$width)/2)]
	set lly [expr int((796-$height)/2)]
	set ury [expr int((796+$height)/2)]
	set postscript "%!PS-Adobe-3.0 EPSF-3.0\n"
	append postscript "%%BoundingBox: $llx $lly $urx $ury\n"
	append postscript "%%EndComments\n"
	append postscript "%%BeginProlog\n"
	append postscript $postscriptfunctions
	append postscript "%%EndProlog\n"
	foreach id [array names dpost] {
		scan $id "R%dC%d" ir ic
		set dleft [expr int(($ic+0.5-$columns/2)*$dwidth)]
		set dbottom [expr int(($rows/2-$ir-0.5)*$dheight)]
		append postscript "BeginEPSF\n"
#		append postscript "0 0 translate\n"
		append postscript "$dleft $dbottom translate\n"
		append postscript "%%BeginDocument\n"
		append postscript $dpost($id)
		append postscript "%%EndDocument\n"
		append postscript "EndEPSF\n"
	}
	return $postscript
}

############################################################

proc ResizePages {} {
	global spectk
	foreach e [winfo child $spectk(pages)] {
		set page [lindex [split $e .] end]
		$page Resize
	}
}

proc CreatePage {} {
	global spectk
	Page $spectk(pageName) $spectk(pages) $spectk(pageRows) $spectk(pageColumns)
	$spectk(pageName) Resize
	$spectk(tools).select select
	$spectk(tools).select invoke
	$spectk(pageName) SelectDisplay R0C0 1
}

proc BindArrows {} {
	global spectk
	bind $spectk(toplevel) <KeyPress> "ProcessBindArrows %K 1"
	bind $spectk(toplevel) <Shift-KeyPress> "ProcessBindArrows %K 0"
#	bind $spectk(drawer).pages.geometry <KeyPress> "ProcessBindArrows %K 1"
#	bind $spectk(drawer).pages.geometry <Shift-KeyPress> "ProcessBindArrows %K 0"
#	bind $spectk(drawer).pages.graph <KeyPress> "ProcessBindArrows %K 1"
#	bind $spectk(drawer).pages.graph <Shift-KeyPress> "ProcessBindArrows %K 0"
#	bind $spectk(drawer).pages.expand <KeyPress> "ProcessBindArrows %K 1"
#	bind $spectk(drawer).pages.expand <Shift-KeyPress> "ProcessBindArrows %K 0"
#	bind $spectk(drawer).pages.roi <KeyPress> "ProcessBindArrows %K 1"
#	bind $spectk(drawer).pages.roi <Shift-KeyPress> "ProcessBindArrows %K 0"
#	bind $spectk(drawer).pages.fit <KeyPress> "ProcessBindArrows %K 1"
#	bind $spectk(drawer).pages.fit <Shift-KeyPress> "ProcessBindArrows %K 0"
}	

proc ProcessBindArrows {key new} {
	global spectk
# First find out which page and frame are currently selected (if they exist)
	if {[catch "set page [lindex [split [$spectk(pages) tab cget select -window] .] end]"]} {return}
#	set selected [$page GetMember selected]
	set id [$page GetMember current]
	scan $id "R%dC%d" ir ic
	if {[string equal $key Up]} {
		incr ir -1
		if {$ir < 0} {set ir [expr [$page GetMember rows]-1]}
	} elseif {[string equal $key Down]} {
		incr ir
		if {$ir == [$page GetMember rows]} {set ir 0}
	} elseif {[string equal $key Left]} {
		incr ic -1
		if {$ic < 0} {set ic [expr [$page GetMember columns]-1]}
	} elseif {[string equal $key Right]} {
		incr ic
		if {$ic == [$page GetMember columns]} {set ic 0}
	} else {
		return
	}
	set id [format "R%dC%d" $ir $ic]
	$page SelectDisplay $id $new
}

proc DoubleClickTab {} {
	global spectk
	if {![info exist spectk(doubleClick)]} {
		set spectk(doubleClick) 1
	} else {
		incr spectk(doubleClick)
	}
	after 500 set spectk(doubleClick) 0
	if {$spectk(doubleClick) == 2} {
		PageMenuModify
	}
}
