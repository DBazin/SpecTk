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
