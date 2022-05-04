proc CreateFitDialog {} {
	global spectk
	set spectk(fitmaxiter) 100
	set spectk(fitepsilon) 1e-5
	set spectk(fitpoints) 200
	set spectk(fitquiet) 0
	set spectk(fitguess) 1
	set spectk(fitdisplay) 1
	set w $spectk(drawer).pages.fit
	frame $w.input -borderwidth 2 -relief groove
#	frame $w.function -borderwidth 2 -relief groove
	frame $w.coeff -borderwidth 2 -relief groove
	frame $w.history
	frame $w.buttons
	grid $w.input -sticky news
#	grid $w.function -sticky news
	grid $w.coeff -sticky news
	grid $w.history -sticky news
	grid $w.buttons -sticky news
	grid rowconfigure $w 0 -weight 0
	grid rowconfigure $w 1 -weight 0
	grid rowconfigure $w 2 -weight 1
	grid rowconfigure $w 3 -weight 0
	grid columnconfigure $w 0 -weight 1
	
# Input frame
	set w $spectk(drawer).pages.fit.input
	label $w.lwave -text "Data:" -font "generalbold" -anchor w
	menubutton $w.wave -text "Choose data" -menu $w.wave.menu -font "general"
	menu $w.wave.menu -tearoff 0
	label $w.lroi -text "ROI:" -font "generalbold" -anchor w
	menubutton $w.roi -text "Choose ROI" -menu $w.roi.menu -font "general"
	menu $w.roi.menu -tearoff 0
	label $w.lfunction -text "Fit:" -font "generalbold" -anchor w
	menubutton $w.function -text "Choose function" -menu $w.function.menu -font "general"
	menu $w.function.menu -tearoff 0
	foreach f {"Gaussian" "Lorentzian" "Exponential" "Polynomial" \
	 \
	} {
		$w.function.menu add command -label $f -font "general" \
		-command "FitDialogSelectFunction \"$f\""
	}
	FitDialogSelectFunction "Gaussian"
	label $w.iterlabel -text "Maximum iterations:" -anchor w -font "smallerbold"
	entry $w.iterations -textvariable spectk(fitmaxiter) -background white -width 5 -font "Helvetica 10"
	label $w.epslabel -text "Fit precision:" -anchor w -font "smallerbold"
	entry $w.epsilon -textvariable spectk(fitepsilon) -background white -width 5 -font "Helvetica 10"
	label $w.ptslabel -text "Points in display:" -anchor w -font "smallerbold"
	entry $w.points -textvariable spectk(fitpoints) -background white -width 5 -font "Helvetica 10"
	checkbutton $w.guess -text "Auto Guess" -variable spectk(fitguess) -font "smaller"
	checkbutton $w.display -text "Results on Graph" -variable spectk(fitdisplay) -font "smaller"
#	checkbutton $w.quiet -text Quiet -variable spectk(fitquiet)
	grid $w.lwave $w.wave - -sticky news
	grid $w.lroi $w.roi - -sticky news
	grid $w.lfunction $w.function - -sticky news
	grid $w.iterlabel - $w.iterations -sticky news
	grid $w.epslabel - $w.epsilon -sticky news
	grid $w.ptslabel - $w.points -sticky news
	grid $w.guess $w.display - -sticky news
#	grid $w.quiet - -sticky news
	
# History frame
	set w $spectk(drawer).pages.fit.history
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
	set w $spectk(drawer).pages.fit.buttons
	button $w.dofit -text "Do Fit" -font "general" -command FitDialogDoFit
	button $w.clear -text "Clear History" -font "general" -command FitDialogClearHistory
	button $w.remove -text "Remove Fit" -font "general" -command FitDialogRemoveFit
	grid $w.dofit - -sticky news
	grid $w.clear $w.remove -sticky news
}

proc UpdateFitDialog {} {
	global spectk
	set tab [$spectk(pages) id select]
	if {[string equal $tab ""]} {return}
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split $frame .] end]
	set current [$page GetMember current]
	set display [format %s%s $page $current]
	if {[lsearch [itcl::find object -isa Display1D] $display] == -1} {return}
	if {![winfo exist [$display GetMember graph]]} {return}
	set w $spectk(drawer).pages.fit.input
	set waves [$display GetMember waves]
	set spectk(fitgraph) [$display GetMember graph]
	$w.wave.menu delete 0 end
	foreach wave $waves {
		if {[lsearch [itcl::find object -isa Wave1D] $wave] != -1} {
			$w.wave.menu add command -label [$wave GetMember name] \
			-command "FitDialogSelectWave $wave" \
			-font "general"
		}
	}
	if {[lsearch [itcl::find object -isa Wave1D] [lindex $waves 0]] != -1} {
		FitDialogSelectWave [lindex $waves 0]
	}
}
	
proc FitDialogSelectWave {wave} {
	global spectk
	set spectk(fitwave) $wave
	set w $spectk(drawer).pages.fit.input
	$w.wave configure -text [$wave GetMember name]
	set rois [$wave FindROIs]
	$w.roi.menu delete 0 end
	foreach roi $rois {
		$w.roi.menu add command -label [$roi GetMember name] -command "FitDialogSelectROI $roi" \
		-font "general"
	}
	if {[llength $rois] == 0} {
		$spectk(drawer).pages.fit.buttons.dofit configure -state disable
		set w $spectk(drawer).pages.fit.input
		$w.roi configure -text "Choose ROI"
	} else {
		$spectk(drawer).pages.fit.buttons.dofit configure -state normal
		FitDialogSelectROI [lindex $rois 0]
	}	
}

proc FitDialogSelectROI {roi} {
	global spectk
	set spectk(fitroi) $roi
	set w $spectk(drawer).pages.fit.input
	$w.roi configure -text [$roi GetMember name]
}

proc FitDialogSelectFunction {f} {
	global spectk
	set spectk(fitfunction) $f
	set w $spectk(drawer).pages.fit.input
	$w.function configure -text $f
	set w $spectk(drawer).pages.fit.coeff
	foreach c [winfo children $w] {destroy $c}
	switch -- $spectk(fitfunction) {
		"Gaussian" {
			set spectk(ncoeff) 5
			label $w.f -image gaussian
#			label $w.f -text "y0 + A * exp(-(x-x0)^2 / 2 / sig^2)" -font "Times 12"
			checkbutton $w.y0h -text y0: -font "smaller" -variable spectk(hold0) -anchor w
			entry $w.y0  -font "smaller" -width 9 -textvariable spectk(coeff0) -background white
			checkbutton $w.ah -text a: -font "smaller" -variable spectk(hold1) -anchor w
			entry $w.a  -font "smaller" -width 9 -textvariable spectk(coeff1) -background white
			checkbutton $w.cah -text A: -font "smaller" -variable spectk(hold2) -anchor w
			entry $w.ca  -font "smaller" -width 9 -textvariable spectk(coeff2) -background white
			checkbutton $w.x0h -text x0: -font "smaller" -variable spectk(hold3) -anchor w
			entry $w.x0  -font "smaller" -width 9 -textvariable spectk(coeff3) -background white
			checkbutton $w.sigh -text sig: -font "smaller" -variable spectk(hold4) -anchor w
			entry $w.sig  -font "smaller" -width 9 -textvariable spectk(coeff4) -background white
			grid $w.f - - - -sticky news
			grid $w.y0h $w.y0 $w.ah $w.a -sticky news
			grid $w.cah $w.ca $w.x0h $w.x0 -sticky news
			grid $w.sigh $w.sig x x -sticky news
		}
		"Lorentzian" {
			set spectk(ncoeff) 5
			label $w.f -image lorentzian
#			label $w.f -text "y0 + A / ((x-x0)^2 + B)" -font "Times 12"
			checkbutton $w.y0h -text y0: -font "smaller" -variable spectk(hold0) -anchor w
			entry $w.y0  -font "smaller" -width 9 -textvariable spectk(coeff0) -background white
			checkbutton $w.ah -text a: -font "smaller" -variable spectk(hold1) -anchor w
			entry $w.a  -font "smaller" -width 9 -textvariable spectk(coeff1) -background white
			checkbutton $w.cah -text A: -font "smaller" -variable spectk(hold2) -anchor w
			entry $w.ca  -font "smaller" -width 9 -textvariable spectk(coeff2) -background white
			checkbutton $w.x0h -text x0: -font "smaller" -variable spectk(hold3) -anchor w
			entry $w.x0  -font "smaller" -width 9 -textvariable spectk(coeff3) -background white
			checkbutton $w.bh -text B: -font "smaller" -variable spectk(hold4) -anchor w
			entry $w.b  -font "smaller" -width 9 -textvariable spectk(coeff4) -background white
			grid $w.f - - - -sticky news
			grid $w.y0h $w.y0 $w.ah $w.a -sticky news
			grid $w.cah $w.ca $w.x0h $w.x0 -sticky news
			grid $w.bh $w.b x x -sticky news
		}
		"Exponential" {
			set spectk(ncoeff) 4
			label $w.f -image exponential
#			label $w.f -text "y0 + A * exp(-a * x)" -font "Times 12"
			checkbutton $w.y0h -text y0: -font "smaller" -variable spectk(hold0) -anchor w
			entry $w.y0  -font "smaller" -width 9 -textvariable spectk(coeff0) -background white
			checkbutton $w.ah -text a: -font "smaller" -variable spectk(hold1) -anchor w
			entry $w.a  -font "smaller" -width 9 -textvariable spectk(coeff1) -background white
			checkbutton $w.cah -text A: -font "smaller" -variable spectk(hold2) -anchor w
			entry $w.ca  -font "smaller" -width 9 -textvariable spectk(coeff2) -background white
			checkbutton $w.sh -text s: -font "smaller" -variable spectk(hold3) -anchor w
			entry $w.s  -font "smaller" -width 9 -textvariable spectk(coeff3) -background white
			grid $w.f - - - -sticky news
			grid $w.y0h $w.y0 $w.ah $w.a -sticky news
			grid $w.cah $w.ca $w.sh $w.s -sticky news
		}
		"Polynomial" {
			label $w.f -image polynomial
#			label $w.f -text "a0 + a1*x + a2*x^2 + ..." -font "Times 12"
			button $w.dp -text "+" -font "smaller" -width 2 -command FitDialogIncreasePoly
			button $w.dm -text "-" -font "smaller" -width 2 -command FitDialogDecreasePoly
			label $w.d -font "smallerbold" -width 2 -textvariable spectk(ncoeff)
			grid $w.f - - - -sticky news
			grid $w.dm $w.d $w.dp x -sticky news
			FitDialogPolynomialCoeff
		}
	}
}

proc FitDialogIncreasePoly {} {
	global spectk
	incr spectk(ncoeff)
	if {$spectk(ncoeff) > 10} {incr spectk(ncoeff) -1}
	FitDialogPolynomialCoeff
}

proc FitDialogDecreasePoly {} {
	global spectk
	incr spectk(ncoeff) -1
	if {$spectk(ncoeff) < 2} {incr spectk(ncoeff)}
	FitDialogPolynomialCoeff
}

proc FitDialogPolynomialCoeff {} {
	global spectk
	set w $spectk(drawer).pages.fit.coeff
	foreach c [winfo children $w] {
		if {[string match *poly* $c]} {destroy $c}
	}
	for {set i 0} {$i < $spectk(ncoeff)} {incr i 2} {
		checkbutton $w.polyh$i -text "a$i" -font "smaller" -variable spectk(hold$i) -anchor w
		entry $w.poly$i -font "smaller" -width 9 -textvariable spectk(coeff$i) -background white
		if {[expr $i+1] == $spectk(ncoeff)} {
			grid $w.polyh$i $w.poly$i x x -sticky news
		} else {
			set j [expr $i+1]
			checkbutton $w.polyh$j -text "a$j" -font "smaller" -variable spectk(hold$j) -anchor w
			entry $w.poly$j -font "smaller" -width 9 -textvariable spectk(coeff$j) -background white
			grid $w.polyh$i $w.poly$i $w.polyh$j $w.poly$j -sticky news
		}
	}
}

proc FitDialogDoFit {} {
	global spectk
	set w $spectk(drawer).pages.fit.history
# First create a name for the Fit object and create it if it doesn't exist
	set name [format %s_%s [$spectk(fitwave) GetMember name] [$spectk(fitroi) GetMember name]]
	if {[lsearch [itcl::find object -isa Fit] $name] == -1} {Fit $name}
# Then initialize the Fit object with input choices
	$name SetMember wave $spectk(fitwave)
	$name SetMember roi $spectk(fitroi)
	$name SetMember graph $spectk(fitgraph)
	$name SetMember maxiter $spectk(fitmaxiter)
	$name SetMember epsilon $spectk(fitepsilon)
	$name SetMember fitpoints $spectk(fitpoints)
	$name SetMember quiet $spectk(fitquiet)
# Initialize function
	switch -- $spectk(fitfunction) {
		"Gaussian" {$name SetFunction gaussian}
		"Lorentzian" {$name SetFunction lorentzian}
		"Exponential" {$name SetFunction exponential}
		"Polynomial" {$name SetFunction polynomial}
	}
# Initialize Fit object vectors with data
	$name Initialize
	if {$spectk(fitguess)} {
# Guess initial values for coefficients
		$name Guess
		for {set i 0} {$i < $spectk(ncoeff)} {incr i} {set spectk(coeff$i) [$name.coeff index $i]}
	} else {
# Set Initial values from entries
		for {set i 0} {$i < $spectk(ncoeff)} {incr i} {lappend coefflist $spectk(coeff$i)}
		$name.coeff set $coefflist
	}
	$w.text insert end "$spectk(fitfunction) fit on [$spectk(fitwave) GetMember name] inside [$spectk(fitroi) GetMember name]\n"
# Do Fit!
	$name Do
# Display Fit curve on graph
	$name Display
# Print results in history
	FitDialogPrintResults $name
}

proc FitDialogPrintResults {fit} {
	global spectk
	set w $spectk(drawer).pages.fit.history
	set message [$fit GetMember message]
	$w.text insert end "$message\n"
	if {[string match *failed* $message]} {return}
	set chisq [$fit GetMember chisq]
	set freedom [expr [$fit.x length] + [$fit.coeff length] - 1]
	set chisq [expr $chisq / $freedom]
	$w.text insert end "Normalized Chi2 = " "black" "[format %.5g $chisq]\n" "red"
	set area [format %.5g [$fit GetMember area]]
	set vunit [[$fit GetMember wave] GetMember vunit]
	for {set i 0} {$i < [$fit.coeff length]} {incr i} {
		set r($i) [format %.5g [$fit.coeff range $i $i]]
		set e($i) [format %.5g [$fit.error range $i $i]]
		set spectk(coeff$i) $r($i)
	}
	switch -- $spectk(fitfunction) {
		"Gaussian" {
			$w.text insert end "y0	= " "black" "$r(0)" "blue" " ± $e(0)\n" "green"
			$w.text insert end "a	= " "black" "$r(1)" "blue" " ± $e(1)\n" "green"
			$w.text insert end "A	= " "black" "$r(2)" "blue" " ± $e(2)\n" "green"
			$w.text insert end "x0	= " "black" "$r(3)" "blue" " ± $e(3)\n" "green"
			$w.text insert end "sig	= " "black" "$r(4)" "blue" " ± $e(4)\n" "green"
			$w.text insert end "area	= " "black" "$area" "blue" " $vunit" "black"
		}
		"Lorentzian" {
			$w.text insert end "y0	= " "black" "$r(0)" "blue" " ± $e(0)\n" "green"
			$w.text insert end "a	= " "black" "$r(1)" "blue" " ± $e(1)\n" "green"
			$w.text insert end "A	= " "black" "$r(2)" "blue" " ± $e(2)\n" "green"
			$w.text insert end "x0	= " "black" "$r(3)" "blue" " ± $e(3)\n" "green"
			$w.text insert end "B	= " "black" "$r(4)" "blue" " ± $e(4)\n" "green"
			$w.text insert end "area	= " "black" "$area" "blue" " $vunit" "black"
		}
		"Exponential" {
			$w.text insert end "y0	= " "black" "$r(0)" "blue" " ± $e(0)\n" "green"
			$w.text insert end "a	= " "black" "$r(1)" "blue" " ± $e(1)\n" "green"
			$w.text insert end "A	= " "black" "$r(2)" "blue" " ± $e(2)\n" "green"
			$w.text insert end "s	= " "black" "$r(3)" "blue" " ± $e(3)\n" "green"
			$w.text insert end "area	= " "black" "$area" "blue" " $vunit" "black"
		}
		"Polynomial" {
			for {set i 0} {$i < $spectk(ncoeff)} {incr i} {
				$w.text insert end "a$i	= " "black" "$r($i)" "blue" " ± $e($i)\n" "green"
			}
		}
	}
	$w.text insert end "\n"
	$w.text see end
}

proc FitDialogClearHistory {} {
	global spectk
	$spectk(drawer).pages.fit.history.text delete 1.0 end
}

proc FitDialogRemoveFit {} {
	global spectk
	set name [format %s_%s [$spectk(fitwave) GetMember name] [$spectk(fitroi) GetMember name]]
	if {[lsearch [itcl::find object -isa Fit] $name] != -1} {itcl::delete object $name}
}

proc FitDialogPostScript {} {
	global spectk
	toplevel .temp
	set c .temp.fit
	set w [winfo width $spectk(drawer).pages.fit.history.text]
	set h [winfo height $spectk(drawer).pages.fit.history.text]
	canvas $c -width $w -height $h -bg white
	pack $c
	set t [$spectk(drawer).pages.fit.history.text get 1.0 end]
	$c create text 1 1 -text $t -font "results" -anchor nw
	update
	$c postscript -file fitresults.eps
	destroy .temp
}
