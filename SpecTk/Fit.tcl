itcl::class Fit {
	private variable wave
	private variable roi
	private variable graph
	private variable function
	private variable coeffnames
	private variable chisq
	private variable maxiter
	private variable epsilon
	private variable fitpoints
	private variable quiet
	private variable message
	private variable area
	private variable coords
	
	constructor {} {
		set wave ""
		set roi ""
		set graph ""
		set function gaussian
		set coeffnames [list y0 A x0 sig]
		set chisq 0
		set maxiter 100
		set epsilon 1e-1
		set fitpoints 200
		set quiet 0
		set message ""
		set area 0.0
		set coords "0.0 0.0"
		blt::vector create $this.x $this.y $this.sig
		blt::vector create $this.coeff $this.error $this.hold
		blt::vector create $this.fx $this.fy
	}
	
	destructor {
		set name [string trimleft $this :]
		if {[$graph element exist $name]} {$graph element delete $name}
		if {[$graph marker exist $name]} {$graph marker delete $name}
		blt::vector destroy $this.x $this.y $this.sig
		blt::vector destroy $this.coeff $this.error $this.hold
		blt::vector destroy $this.fx $this.fy
	}

	public method GetMember {m} {set $m}
	public method SetMember {m v} {set $m $v}
	public method Initialize {}
	public method SetFunction {f}
	public method Display {}
	public method Enter {}
	public method Leave {}
	public method ButtonPress1 {xw yw}
	public method Motion {xw yw}
	public method ButtonRelease1 {xw yw}
	public method Guess {}
	public method Do {}
	public method Write {file}
	public method Read {}
}

itcl::body Fit::Initialize {} {
	global spectk
	set xmin [lindex [$roi GetMember xlimits] 0]
	set xmax [lindex [$roi GetMember xlimits] 1]
	set low [$wave GetMember low]
	set inc [$wave GetMember increment]
	set bmin [expr int(($xmin - $low) / $inc)]
	set bmax [expr int(($xmax - $low) / $inc)]
	set xbmin [expr $bmin*$inc + $low]
	set xbmax [expr $bmax*$inc + $low + $inc/2]
	$this.x seq $xbmin $xbmax $inc
	$this.y set [$wave.data range $bmin $bmax]
	$this.sig set [blt::vector expr sqrt(abs($this.y))]
	for {set i 0} {$i < [$this.y length]} {incr i} {
		if {[$this.y index $i] == 0} {$this.sig index $i 1}
	}
	set step [expr ($xmax-$xmin) / $fitpoints]
	$this.fx length $fitpoints
	$this.fx seq $xmin $xmax $step
	$this.fy length $fitpoints
	$this.fy notify always
	for {set i 0} {$i < $spectk(ncoeff)} {incr i} {lappend holdlist $spectk(hold$i)}
	$this.hold set $holdlist
	FitIterate configure -quiet $quiet
	FitIterate init -input $this.x $this.y $this.sig
	FitIterate init -output $this.fx $this.fy
	FitIterate init -coefficient $this.coeff $this.error $this.hold
}

itcl::body Fit::SetFunction {f} {
	global spectk
	set d $spectk(ncoeff)
	set function $f
	switch -- $function {
		gaussian {set coeffnames [list y0 a A x0 sig]}
		lorentzian {set coeffnames [list y0 a A x0 B]}
		exponential {set coeffnames [list y0 a A s]}
		polynomial {
			set coeffnames ""
			for {set i 0} {$i < $spectk(ncoeff)} {incr i} {lappend coeffnames a$i}
		}
	}
	FitIterate configure -function $f
	$this.coeff length $d
	$this.error length $d
	$this.hold length $d
}

itcl::body Fit::Display {} {
	global spectk
	set name [string trimleft $this :]
	if {[$graph element exist $name]} {$graph element delete $name}
	if {[$graph marker exist $name]} {$graph marker delete $name}
	$graph element create $name -xdata $this.fx -ydata $this.fy \
	-symbol "" -smooth linear -color red -label ""
	if {$spectk(fitdisplay)} {
		set xmin [lindex [$roi GetMember xlimits] 0]
		set xmax [lindex [$roi GetMember xlimits] 1]
		set xmiddle [expr ($xmax+$xmin)/2]
		set str "$function fit"
		set freedom [expr [$this.x length] + [$this.coeff length] - 1]
		set chi2 [expr $chisq / $freedom]
		append str "\nChi2=[format %.5g $chi2]"
		for {set i 0} {$i < $spectk(ncoeff)}  {incr i} {
			set c [set $this.coeff($i)]
			set e [set $this.error($i)]
			append str "\n[lindex $coeffnames $i]=[format %.5g $c] ± [format %.5g $e]"
		}
		append str "\narea=[format %.5g $area] [$wave GetMember vunit]"
		set coords "$xmiddle 0.0"
		$graph marker create text -name $name -text $str -coords $coords \
		-background ivory -anchor s -font graphlabels -justify left
#		$graph marker create line -name l$name -linewidth 1 -coords 
		$graph marker bind $name <Enter> "$this Enter"
		$graph marker bind $name <Leave> "$this Leave"
	}
	set nlist [$graph element show]
	set i [lsearch $nlist $name]
	set nlist [lreplace $nlist $i $i]
	lappend nlist $name
	$graph element show $nlist
}

itcl::body Fit::Enter {} {
	global SpecTkHome spectk
	set name [string trimleft $this :]
	set path [split $graph .]
	set dindex [lsearch $path display*]
	set page [lindex $path [expr $dindex-1]]
	set display [format %s%s $page [string trimleft [lindex $path $dindex] display]]
	$display Unbind
	$graph configure -cursor [list @$SpecTkHome/images/handopen.xbm black]
	$graph marker bind $name <ButtonPress-1> "$this ButtonPress1 %x %y"
	$graph marker bind $name <ButtonRelease-1> "$this ButtonRelease1 %x %y"
}

itcl::body Fit::Leave {} {
	global spectk
	set name [string trimleft $this :]
	set path [split $graph .]
	set dindex [lsearch $path display*]
	set page [lindex $path [expr $dindex-1]]
	set display [format %s%s $page [string trimleft [lindex $path $dindex] display]]
	$page $spectk(currentTool)
	$graph marker bind $name <ButtonPress-1> ""
	$graph marker bind $name <ButtonRelease-1> ""
}

itcl::body Fit::ButtonPress1 {xw yw} {
	global SpecTkHome spectk
	set name [string trimleft $this :]
	$graph configure -cursor [list @$SpecTkHome/images/handclose.xbm black]
	$graph marker bind $name <Enter> ""
	$graph marker bind $name <Leave> ""
	$graph marker bind $name <Motion> "$this Motion %x %y"
	set x [$graph axis invtransform x $xw]
	set y [$graph axis invtransform y $yw]
	set spectk(xref) $x
	set spectk(yref) $y
}

itcl::body Fit::Motion {xw yw} {
	global SpecTkHome spectk
	set name [string trimleft $this :]
	set x [$graph axis invtransform x $xw]
	set y [$graph axis invtransform y $yw]
	set xdiff [expr $x - $spectk(xref)]
	set ydiff [expr $y - $spectk(yref)]
	set xp [expr [lindex $coords 0] + $xdiff]
	set yp [expr [lindex $coords 1] + $ydiff]
	$graph marker configure $name -coords "$xp $yp"
}

itcl::body Fit::ButtonRelease1 {xw yw} {
	global SpecTkHome spectk
	set name [string trimleft $this :]
	$graph configure -cursor [list @$SpecTkHome/images/handopen.xbm black]
	set x [$graph axis invtransform x $xw]
	set y [$graph axis invtransform y $yw]
	set xdiff [expr $x - $spectk(xref)]
	set ydiff [expr $y - $spectk(yref)]
	set xp [expr [lindex $coords 0] + $xdiff]
	set yp [expr [lindex $coords 1] + $ydiff]
	$graph marker configure $name -coords "$xp $yp"
	$graph marker bind $name <Motion> ""
	$graph marker bind $name <Enter> "$this Enter"
	$graph marker bind $name <Leave> "$this Leave"
	set coords "$xp $yp"
}

itcl::body Fit::Guess {} {
	global spectk
	$wave CalculateROI $roi
	set max [blt::vector expr max($this.y)]
	set min [blt::vector expr min($this.y)]
	switch -- $function {
		gaussian {
			set $this.coeff(2) [expr $max-$min]
			set $this.coeff(0) $min
			set $this.coeff(1) 0.0
			set roicalc [$wave GetMember calc($roi)]
			set $this.coeff(3) [lindex $roicalc 2]
			set $this.coeff(4) [expr [lindex $roicalc 3] / 2.35482]
		}
		lorentzian {
			set $this.coeff(0) $min
			set $this.coeff(1) 0.0
			set roicalc [$wave GetMember calc($roi)]
			set $this.coeff(3) [lindex $roicalc 2]
			set xh [expr [lindex $roicalc 3] / 2]
			set $this.coeff(4) [expr $xh * $xh]
			set $this.coeff(2) [expr ($max-$min) * $xh * $xh]
		}
		exponential {
			set $this.coeff(0) $min
			set $this.coeff(1) 0.0
			set xmin [set $this.x(0)]
			set ymin [set $this.y(0)]
			set i 1
			while {$ymin <= 0 && $i < [$this.x length]} {
				set xmin [set $this.x($i)]
				set ymin [set $this.y($i)]
				incr i
			}
			set xmax [set $this.x(end)]
			set ymax [set $this.y(end)]
			set i [expr [$this.x length] - 1]
			while {$ymax <= 0 && $i > 0} {
				set xmax [set $this.x($i)]
				set ymax [set $this.y($i)]
				incr i -1
			}
			set $this.coeff(3) [expr log($ymax/$ymin) / ($xmin-$xmax)]
			set alpha [set $this.coeff(2)]
			set $this.coeff(2) [expr $ymin / exp(-$alpha * $xmin)]
		}
		polynomial {
			set xmin [set $this.x(0)]
			set xmax [set $this.x(end)]
			set xstep [expr int(($xmax-$xmin)/$spectk(ncoeff))]
		}
	}
	for {set i 0} {$i < $spectk(ncoeff)} {incr i} {
		if {$spectk(hold$i)} {set $this.coeff($i) $spectk(coeff$i)}
	}
}

itcl::body Fit::Do {} {
	set name [string trimleft $this :]
	set pi 3.141592
	set inc [$wave GetMember increment]
	Initialize
	set iter 1
	set test 0
	set chisq [FitIterate init -fit]
	while {$iter < $maxiter} {
		set ochisq $chisq
		set chisq [FitIterate iterate]
		if {$chisq == -1} {
			set message "Fit failed: calculation error"
			FitIterate finish
			return
		}
		if {$chisq > $ochisq} {
			set test 0
		} elseif {[expr abs($ochisq-$chisq)] < $epsilon} {
			incr test
		}
		if {$test > 3} {
			set message "Fit succeeded after $iter iterations"
			switch -- $function {
				gaussian {set area [expr sqrt(2*$pi)*[$this.coeff index 2]*[$this.coeff index 4]/$inc]}
				lorentzian {set area [expr $pi*[$this.coeff index 2]/sqrt([$this.coeff index 4])/$inc]}
				exponential {	set area [expr 1.0/[$this.coeff index 3]/$inc]}
				polynomial {set area 0.0}
			}
			break
		}
		incr iter
	}
	if {$iter == $maxiter} {
		set message "Fit failed to converge after $iter iterations"
	}
	FitIterate finish
}

itcl::body Fit::Write {file} {
	set name [format %s_%s $wave $roi]
	puts $file "##### Begin Fit $name definition #####"
	puts $file "Fit $name"
	puts $file "$name SetMember wave $wave"
	puts $file "$name SetMember roi $roi"
	puts $file "$name SetMember graph $graph"
	puts $file "$name SetMember function $function"
	puts $file "$name SetMember chisq $chisq"
	puts $file "$name SetMember maxiter $maxiter"
	puts $file "$name SetMember epsilon $epsilon"
	puts $file "$name SetMember fitpoints $fitpoints"
	puts $file "$name SetMember area $area"
	puts $file "$name.coeff set \"[$name.coeff range 0 end]\""
	puts $file "$name.error set \"[$name.error range 0 end]\""
	puts $file "$name.hold set \"[$name.hold range 0 end]\""
	puts $file "$name.fx set \"[$name.fx range 0 end]\""
	puts $file "$name.fy set \"[$name.fy range 0 end]\""
	puts $file "##### End Fit $name definition #####"
}

itcl::body Fit::Read {} {
	Display
}


