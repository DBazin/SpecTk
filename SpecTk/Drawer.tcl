proc SetupDrawer {} {
	global spectk
#	set spectk(drawer) .drawer
#	set spectk(drawerwidth) 250
#	set spectk(draweropen) 0
#	frame $spectk(drawer) -borderwidth 2 -relief sunken
#	place $spectk(drawer) -in $spectk(toplevel) -bordermode outside -anchor nw \
#	-width $spectk(drawerwidth) -height [expr [winfo height $spectk(toplevel)]-20] -y 10
#	lower $spectk(drawer)
	label $spectk(drawer).title -text Page
	pack $spectk(drawer).title -side top -expand 1 -fill x
	pack propagate $spectk(drawer) 0
#	toplevel $spectk(drawer)
#	wm resizable $spectk(drawer) 1 0
#	wm minsize $spectk(drawer) 250 0
#	wm maxsize $spectk(drawer) 400 0
#	wm title $spectk(drawer) Page
#	bind . <Configure> ResizeSpecTk
#	bind $spectk(toplevel) <Enter> FocusTopLevel
#	bind $spectk(drawer) <Enter> FocusDrawer
#	bind $spectk(toplevel) <Configure> FollowMe
#	bind $spectk(drawer) <Configure> FollowMe
#	bind $spectk(toplevel) <Destroy> DestroyTopLevel
#	bind $spectk(drawer) <Destroy> DestroyDrawer
#	bind $spectk(toplevel) <Map> IconTopLevel
#	bind $spectk(toplevel) <Unmap> IconTopLevel
#	bind $spectk(drawer) <Map> IconDrawer
#	bind $spectk(drawer) <Unmap> IconDrawer
	set w $spectk(drawer).pages
	blt::tabnotebook $w -borderwidth 2 -outerpad 0 -side right -rotate 270
	pack $w -expand 1 -fill both
	frame $w.geometry -borderwidth 2 -relief groove
	CreateGeometryDialog
	set index [$w insert end -text Page -window $w.geometry]
	$w tab configure $index -command SelectGeometry
	frame $w.assign
	CreateAssignDialog
	set index [$w insert end -text Spectrum -window $w.assign]
	$w tab configure $index -command SelectAssign
	frame $w.graph
	CreateGraphDialog
	set index [$w insert end -text Graph -window $w.graph]
	$w tab configure $index -command SelectGraph
	frame $w.expand -borderwidth 2 -relief groove
	CreateExpandDialog
	set index [$w insert end -text Axis -window $w.expand]
	$w tab configure $index -command SelectExpand
	frame $w.roi
	CreateROIDialog
	set index [$w insert end -text ROI -window $w.roi]
	$w tab configure $index -command SelectROI
	frame $w.fit
	CreateFitDialog
	set index [$w insert end -text Fit -window $w.fit]
	$w tab configure $index -command SelectFit

	frame $w.marker
	CreateMarkerDialog
	set index [$w insert end -text Marker -window $w.marker]
	$w tab configure $index -command SelectMarker

#	bind $spectk(drawer) <Control-q> ExitSpecTk
#	bind $spectk(drawer) <Control-n> NewConfiguration
#	bind $spectk(drawer) <Control-o> "LoadConfiguration \"\""
#	bind $spectk(drawer) <Control-s> SaveConfiguration
#	bind $spectk(drawer) <Control-p> CreatePrintDialog
#	set g [wm geometry $spectk(toplevel)]
#	scan $g "%dx%d+%d+%d" gw gh gx gy	
#	set dx [expr $gx+$gw-$spectk(drawerwidth)]
#	set dh [expr $gh+10]
#	set dy [expr $gy+10]
#	set d [format "%dx%d+%d+%d" $spectk(drawerwidth) $dh $dx $dy]
#	wm geometry $spectk(drawer) $d
#	raise $spectk(drawer)
#	raise $spectk(toplevel)
}

proc FocusTopLevel {} {
	global spectk
	focus $spectk(toplevel)
	lower $spectk(drawer) $spectk(toplevel)
}

proc FocusDrawer {} {
	global spectk
	if {[string equal [$spectk(drawer).pages id select] tab1]} {
		focus $spectk(drawer).pages.assign.tree.tree
	} else {
		focus $spectk(drawer)
	}
}

proc DestroyTopLevel {} {
	global spectk	
	if {![winfo exist $spectk(toplevel)]} {destroy $spectk(drawer)}
}

proc DestroyDrawer {} {
	global spectk
	if {![winfo exist $spectk(drawer)]} {destroy $spectk(toplevel)}
}

proc IconTopLevel {} {
	global spectk
	if {[string equal [wm state $spectk(toplevel)] normal]} {
		wm deiconify $spectk(drawer)
		if {$spectk(draweropen)} {raise $spectk(drawer)}
	}
	if {[string equal [wm state $spectk(toplevel)] iconic]} {wm iconify $spectk(drawer)}
}

proc IconDrawer {} {
	global spectk
	if {[string equal [wm state $spectk(drawer)] normal]} {wm deiconify $spectk(toplevel)}
	if {[string equal [wm state $spectk(drawer)] iconic]} {wm iconify $spectk(toplevel)}
}

proc FollowMe {} {
	global spectk
	if {[winfo ismapped $spectk(drawer)] && [wm stackorder $spectk(drawer) isbelow $spectk(toplevel)] && $spectk(draweropen)} {
		raise $spectk(drawer)
	}
	if {![info exist spectk(savedg)]} {set spectk(savedg) ""}
	if {![info exist spectk(savedd)]} {set spectk(savedd) ""}
	set px [winfo pointerx $spectk(toplevel)]
	set py [winfo pointery $spectk(toplevel)]
	set rgx [winfo rootx $spectk(toplevel)]
	set rgy [winfo rooty $spectk(toplevel)]
	set rdx [winfo rootx $spectk(drawer)]
	set rdy [winfo rooty $spectk(drawer)]
	set g [wm geometry $spectk(toplevel)]
	set d [wm geometry $spectk(drawer)]
	scan $g "%dx%d+%d+%d" gw gh gx gy
	scan $d "%dx%d+%d+%d" dw dh dx dy
	set spectk(drawerwidth) $dw
	if {$px > $gx && $px < $rgx+$gw && $py > $gy && $py < $rgy+$gh} {
		set intop 1
	} else {
		set intop 0
	}
	if {$px > $dx && $px < $rdx+$dw && $py > $dy && $py < $rdy+$dh} {
		set indrawer 1
	} else {
		set indrawer 0
	}
	if {![string equal $g $spectk(savedg)] && $intop} {
		if {$spectk(draweropen)} {
			set dx [expr $gx+$gw]
		} else {
			set dx [expr $gx+$gw-$dw]
		}
		set dh [expr $gh+10]
		set dy [expr $gy+10]
		set d [format "%dx%d+%d+%d" $dw $dh $dx $dy]
		wm geometry $spectk(drawer) $d
		set spectk(savedg) $g
	}
	if {![string equal $d $spectk(savedd)] && $spectk(draweropen) && $indrawer} {
		set gx [expr $dx-$gw]
		set gy [expr $dy-10]
		set g [format "%dx%d+%d+%d" $gw $gh $gx $gy]
		wm geometry $spectk(toplevel) $g
		set spectk(savedd) $d
	}
}

proc FollowDrawer {} {
	global spectk
	set d [wm geometry $spectk(drawer)]
	scan $d "%dx%d+%d+%d" dw dh dx dy
	set g [wm geometry $spectk(toplevel)]
	scan $g "%dx%d+%d+%d" gw gh gx gy
	set gx [expr $dx-$gw]
	set gy [expr $dy-10]
	set g [format "%dx%d+%d+%d" $gw $gh $gx $gy]
	wm geometry $spectk(toplevel) $g
}

proc ResizeSpecTk {} {
	global spectk
	ResizePages
	if {$spectk(draweropen) == -1} {return}
	set topw [winfo width .]
	set toph [winfo height .]
	set dw [winfo width $spectk(drawer)]
	if {$spectk(draweropen)} {
		$spectk(toplevel) configure -width [expr $topw-$dw]
		place $spectk(drawer) -x [winfo width $spectk(toplevel)] \
		-height [expr [winfo height $spectk(toplevel)]-20] -y 10
	} else {
		$spectk(toplevel) configure -width $topw
	}
}

proc OpenCloseDrawer {} {
	global spectk
	scan [wm geometry .] "%dx%d+%d+%d" tw th tx ty
	if {$spectk(draweropen)} {
		$spectk(buttons).drawer.button configure -text "Open\n\nDrawer"
		grid remove $spectk(drawer)
		set geo [format "%dx%d+%d+%d" [expr $tw-$spectk(drawerwidth)] $th $tx $ty]
		wm geometry . $geo
		set spectk(draweropen) 0
	} else {
		$spectk(buttons).drawer.button configure -text "Close\n\nDrawer"
		grid $spectk(drawer)
		set geo [format "%dx%d+%d+%d" [expr $tw+$spectk(drawerwidth)] $th $tx $ty]
		wm geometry . $geo
		set spectk(draweropen) 1
	}
}

proc ExpandDrawer {} {
	global spectk
	if {!$spectk(draweropen)} {return}
	if {$spectk(drawerwidth) >= 500} {return}
	scan [wm geometry .] "%dx%d+%d+%d" tw th tx ty
	set newwidth [expr [$spectk(drawer) cget -width]+10]
	set spectk(drawerwidth) $newwidth
	$spectk(drawer) configure -width $newwidth
	set geo [format "%dx%d+%d+%d" [expr $tw+10] $th $tx $ty]
	wm geometry . $geo
}

proc ShrinkDrawer {} {
	global spectk
	if {!$spectk(draweropen)} {return}
	if {$spectk(drawerwidth) <= 150} {return}
	scan [wm geometry .] "%dx%d+%d+%d" tw th tx ty
	set newwidth [expr [$spectk(drawer) cget -width]-10]
	set spectk(drawerwidth) $newwidth
	$spectk(drawer) configure -width $newwidth
	set geo [format "%dx%d+%d+%d" [expr $tw-10] $th $tx $ty]
	wm geometry . $geo
}

proc SelectGeometry {} {
	global spectk
	$spectk(drawer).title configure -text Page
}

proc SelectAssign {} {
	global spectk
	$spectk(drawer).title configure -text Spectrum
	focus $spectk(drawer).pages.assign.tree.tree
}

proc SelectGraph {} {
	global spectk
	$spectk(drawer).title configure -text Graph
	UpdateGraphDialog
}

proc SelectExpand {} {
	global spectk
	$spectk(drawer).title configure -text Axis
	UpdateExpandDialog
}

proc SelectROI {} {
	global spectk
	$spectk(drawer).title configure -text ROI
	UpdateROIDialog
}

proc SelectFit {} {
	global spectk
	$spectk(drawer).title configure -text Fit
	UpdateFitDialog
}

proc SelectMarker {} {
	global spectk
	$spectk(drawer).title configure -text Marker

	set tab [$spectk(pages) id select]
	if {$tab eq ""} {return}
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split $frame .] end]
	set current [$page GetMember current]
	set display "${page}${current}"
	if {[catch {set graph [$display GetMember graph]}]} {return}

	if {![info exists spectk(markerName)] || [string trim $spectk(markerName)] eq ""} {
		set spectk(markerName) [GenerateUniqueMarkerName $graph "Line"]
	}
}

proc CreateMarkerDialog {} {
	global spectk
	set spectk(markerRowId) 0
	set spectk(markerStyle) "solid"
	set spectk(markerColor) "blue"

	set w $spectk(drawer).pages.marker

	frame $w.style
	radiobutton $w.style.solid -text "Solid" -variable spectk(markerStyle) -value "solid"
	radiobutton $w.style.dashed -text "Dashed" -variable spectk(markerStyle) -value "dashed"
	pack $w.style.solid $w.style.dashed -side left -padx 4
	grid $w.style -row 0 -column 0 -sticky w -padx 4 -pady 4

	frame $w.colorframe
	label $w.colorframe.label -text "Color:"
	ttk::combobox $w.colorframe.combo -textvariable spectk(markerColor) \
	-values {"Black" "Blue" "Crimson" "Cyan" "Gold" "Gray" "Green" \
	         "Magenta" "Orange" "Purple" "Red" "Teal" "Yellow"} \
	-state readonly
	$w.colorframe.combo current 0
	pack $w.colorframe.label -side left
	pack $w.colorframe.combo -side left -padx 4
	grid $w.colorframe -row 1 -column 0 -sticky w -padx 4 -pady 4

	frame $w.nameframe
	label $w.nameframe.label -text "Name:"
	entry $w.nameframe.entry -textvariable spectk(markerName) -width 20
	pack $w.nameframe.label -side left
	pack $w.nameframe.entry -side left -padx 4
	grid $w.nameframe -row 2 -column 0 -sticky w -padx 4 -pady 4

	button $w.create -text "Create Mark" -command MarkerToolActivate
	grid $w.create -row 3 -column 0 -sticky w -padx 4 -pady 4

	frame $w.list -borderwidth 1 -relief sunken
	canvas $w.list.canvas -width 200 -highlightthickness 0 -yscrollincrement 10
	scrollbar $w.list.scroll -orient vertical -command "$w.list.canvas yview"
	$w.list.canvas configure -yscrollcommand "$w.list.scroll set"

	set spectk(markerListFrame) $w.list.canvas.inner
	frame $spectk(markerListFrame)
	$w.list.canvas create window 0 0 -anchor nw -window $spectk(markerListFrame)

	grid $w.list.canvas -row 0 -column 0 -sticky news
	grid $w.list.scroll -row 0 -column 1 -sticky ns
	grid $w.list -row 4 -column 0 -sticky news -padx 4 -pady 4

	bind $spectk(markerListFrame) <Configure> "
		$w.list.canvas configure -scrollregion \[list 0 0 200 \[winfo reqheight $spectk(markerListFrame)\]]
	"

	grid rowconfigure $w.list 0 -weight 1
	grid columnconfigure $w.list 0 -weight 1
	grid rowconfigure $w 4 -weight 1
	grid columnconfigure $w 0 -weight 1

	button $w.deleteall -text "Delete All" -command DeleteAllMarkers
	grid $w.deleteall -row 5 -column 0 -sticky ew -padx 4 -pady 6

	if {![info exists spectk(markerName)] || [string trim $spectk(markerName)] eq ""} {
		set tab [$spectk(pages) id select]
		if {$tab ne ""} {
			set frame [$spectk(pages) tab cget $tab -window]
			set page [lindex [split $frame .] end]
			set current [$page GetMember current]
			set display "${page}${current}"
			if {![catch {set graph [$display GetMember graph]}]} {
				set spectk(markerName) [GenerateUniqueMarkerName $graph "Line"]
			}
		}
	}
}

proc MarkerToolActivate {} {
	global spectk markerToolPoints markerToolName markerToolDotName

	set tab [$spectk(pages) id select]
	if {$tab eq ""} {return}
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split $frame .] end]
	set current [$page GetMember current]
	set display "${page}${current}"
	if {[catch {set graph [$display GetMember graph]}]} {return}
	if {![winfo exist $graph]} {return}

	set markerToolPoints {}

	if {![info exists spectk(markerName)] || [string trim $spectk(markerName)] eq ""} {
		set markerToolName [GenerateUniqueMarkerName $graph "Line"]
		set spectk(markerName) $markerToolName
	} else {
		set desiredName [string trim $spectk(markerName)]
		if {[$graph marker exists $desiredName] || [$graph marker exists "${desiredName}_label"]} {
			set markerToolName [GenerateUniqueMarkerName $graph $desiredName]
			set spectk(markerName) $markerToolName
		} else {
			set markerToolName $desiredName
		}
	}

	set markerToolDotName ""

	bind $graph <Button-1> [list MarkerToolAddPoint $display %x %y]
	bind $graph <Double-Button-1> [list MarkerToolFinish $display]
}

proc MarkerToolAddPoint {display x y} {
	global markerToolPoints markerToolName markerToolDotName spectk

	if {[catch {set graph [$display GetMember graph]}]} {return}

	set xcoord [$graph axis invtransform x $x]
	set ycoord [$graph axis invtransform y $y]
	lappend markerToolPoints $xcoord $ycoord

	set dotRadius 1
	set color $spectk(markerColor)

	if {[llength $markerToolPoints] == 2} {
		set markerToolDotName "${markerToolName}_dot"
		catch { $graph marker delete $markerToolDotName }
		set coords {}
		for {set i 0} {$i < 8} {incr i} {
			set angle [expr {2.0 * $i * acos(-1) / 8}]
			set dx [expr {$dotRadius * cos($angle)}]
			set dy [expr {$dotRadius * sin($angle)}]
			lappend coords [expr {$xcoord + $dx}] [expr {$ycoord + $dy}]
		}
		$graph marker create polygon -name $markerToolDotName -coords $coords \
			-outline $color -fill $color -linewidth 1
	} elseif {[llength $markerToolPoints] >= 4} {
		catch { $graph marker delete $markerToolDotName }
		set dash {}
		if {$spectk(markerStyle) eq "dashed"} {
			set dash {4 4}
		}
		if {[$graph marker exist $markerToolName]} {
			$graph marker configure $markerToolName -coords $markerToolPoints -dashes $dash
		} else {
			$graph marker create line -name $markerToolName -coords $markerToolPoints \
				-outline $color -linewidth 2 -dashes $dash
		}
	}
}

proc MarkerToolFinish {display} {
	global markerToolName markerToolPoints spectk

	if {[catch {set graph [$display GetMember graph]}]} {return}

	bind $graph <Button-1> {}
	bind $graph <Double-Button-1> {}
	bind $graph <B1-Motion> {}
	bind $graph <ButtonRelease-1> {}
	focus $spectk(toplevel)

	if {[llength $markerToolPoints] >= 2} {
		set x0 [lindex $markerToolPoints 0]
		set y0 [lindex $markerToolPoints 1]
		set labelName "${markerToolName}_label"
		$graph marker create text -name $labelName -text $markerToolName -anchor n -rotate 90 \
			-coords "$x0 $y0" -font "graphlabels" -background "" -outline black
	}

	if {![info exists spectk(markerRowId)]} {
		set spectk(markerRowId) 0
	}

	set entryFrame [frame $spectk(markerListFrame).row[incr spectk(markerRowId)]]
	label $entryFrame.name -text $markerToolName -anchor w -width 15
	label $entryFrame.graph -text $graph
	button $entryFrame.delete -text "Delete" -command [list DeleteMarkerFromGraph $graph $markerToolName $entryFrame]
	pack $entryFrame.name -side left
	pack $entryFrame.delete -side right
	pack $entryFrame -in $spectk(markerListFrame) -fill x -pady 2 -padx 2

	set spectk(markerName) [GenerateUniqueMarkerName $graph "Line"]

	set tab [$spectk(pages) id select]
	if {$tab ne ""} {
		set pageName [lindex [split [$spectk(pages) tab cget $tab -window] .] end]
		if {[info commands $pageName] ne ""} {
			$pageName BindSelect
		}
	}
}

proc DeleteMarkerFromGraph {graph markerName widget} {
	catch { $graph marker delete $markerName }
	catch { $graph marker delete ${markerName}_label }
	catch { $graph marker delete ${markerName}_dot }
	catch { destroy $widget }
}

proc GenerateUniqueMarkerName {graph baseName} {
	set name $baseName
	set count 2
	while {[$graph marker exists $name] || [$graph marker exists "${name}_label"]} {
		set name "$baseName $count"
		incr count
	}
	return $name
}

proc DeleteAllMarkers {} {
	global spectk

	set tab [$spectk(pages) id select]
	if {$tab eq ""} {return}
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split $frame .] end]
	set current [$page GetMember current]
	set display "${page}${current}"
	if {[catch {set graph [$display GetMember graph]}]} {return}
	if {![winfo exist $graph]} {return}

	set children [winfo children $spectk(markerListFrame)]
	for {set i 0} {$i < [llength $children]} {incr i} {
		set child [lindex $children $i]
		if {[winfo exists $child.graph] && [$child.graph cget -text] eq $graph} {
			if {[winfo exists $child.name]} {
				set name [$child.name cget -text]
				catch { $graph marker delete $name }
				catch { $graph marker delete ${name}_label }
				catch { $graph marker delete ${name}_dot }
			}
			catch { destroy $child }
		}
	}
}
