itcl::class Palette {
	private variable colors
	private variable scale
	private variable min
	private variable max
	private variable log
	private variable ticks
	
	constructor {} {
		set colors ""
		set scale ""
		set min 1
		set max 10
		set log 0
		set ticks ""
	}
	
	public method GetMember {m} {set $m}
	public method SetMember {m v} {set $m $v}
	public method LoadColors {file}
	public method SetLin {}
	public method SetLog {}
	public method SetScale {min max}
	public method SetTicks {n}
	public method SetDisplay {g h w}
}

itcl::body Palette::LoadColors {file} {
	set handle [open $file r]
	set colors ""
	while {![eof $handle]} {
		lappend colors [gets $handle]
	}
	SetLin
	close $handle
}

itcl::body Palette::SetLin {} {
	set scale ""
	set inc [expr 1.0*($max-$min)/([llength $colors]+1.0)]
	for {set i 0} {$i < [llength $colors]} {incr i} {
		lappend scale [expr $min + $inc*$i]
	}
	set log 0
}

itcl::body Palette::SetLog {} {
	set scale ""
	if {$min <= 0} {set min 0.001}
	set loginc [expr (log($max)-log($min))/([llength $colors]+1.0)]
	for {set i 0} {$i < [llength $colors]} {incr i} {
		lappend scale [expr exp(log($min) + $loginc*$i)]
	}
	set log 1
}

itcl::body Palette::SetScale {mini maxi} {
	set min $mini
	set max $maxi
	if {$log} {
		SetLog
	} else {
		SetLin
	}
}

itcl::body Palette::SetTicks {n} {
	if {$n <= 0} {return}
	set ticks ""
	lappend ticks [format "%g" $min]
	set range [expr $max-$min]
	if {$log} {
		set fac [expr floor(log10($range))]
		if {$fac <= 0} {set fac 1}
		set num [expr floor($n/$fac)]
		if {$num <= 1} {
			set nlist [list 1]
		} elseif {$num == 2} {
			set nlist [list 1 5]
		} else {
			set nlist [list 1 2 5]
		}
		for {set j 0} {$j < [llength $nlist]} {incr j} {
			set i 0
			while {[lindex $nlist $j] * pow(10, $i) < $max} {
				set value [expr [lindex $nlist $j] * pow(10, $i)]
				if {$value > $min} {lappend ticks [format "%g" $value]}
				incr i
			}
		}
	} else {
		set inc [expr 1.0*$range/$n]
		if {$inc <= 0} {return}
		set power [expr floor(log10($inc))]
		set inc [expr $inc/pow(10,$power)]
		if {$inc >= 1 && $inc < 2} {
			set inc 1
		} elseif {$inc >= 2 && $inc < 5} {
			set inc 2
		} else {
			set inc 5
		}
		set inc [expr $inc*pow(10,$power)]
		set first [expr int($min/$inc)*$inc]
		if {$first < $min} {
			set first [expr $first+$inc]
		}
		if {$inc == 0} {
			puts "Trouble! inc is equal to $inc in Palette::SetTicks!"
			return
		}
		set i 0
		while {$first + $i*$inc < $max} {
			lappend ticks [format "%g" [expr $first + $i*$inc]]
			incr i
		}
	}
}

itcl::body Palette::SetDisplay {g h w} {
	SetTicks [expr int($h/50)]
	set digits 0
	foreach t $ticks {
		set d [string length $t]
		if {$d > $digits} {set digits $d}
	}
	if {$w < 200} {set digits 0}
	$g.scale configure -height $h -width [expr 12+$digits*5]
	$g configure -rightmargin [expr 12+$digits*5]
	set h [expr $h-8]
	if {![string equal [$g.scale find withtag lines] ""]} {
		$g.scale delete lines
	}
	set ls [llength $scale]
	set lw [expr int($h/$ls)+1]
	for {set i 0} {$i < $ls} {incr i} {
		set y [expr (1.0*$ls-$i)/$ls*$h+4]
		$g.scale create line 2 $y 10 $y -fill [lindex $colors $i] -width $lw -tags lines
	}
	if {![string equal [$g.scale find withtag ticks] ""]} {
		$g.scale delete ticks
	}
	if {$w < 200} {return}
	set tick [lindex $ticks 0]
	$g.scale create text 12 [expr $h+4] -anchor w -text $tick \
	-font *-Helvetica-Medium-R-Normal-*-9-* -tags ticks
	for {set i 1} {$i < [llength $ticks]} {incr i} {
		set tick [lindex $ticks $i]
		set j 0
		while {$tick > [lindex $scale $j]} {
			incr j
			if {$j == [llength $scale]} {return}
		}
#		set pos [expr (1.0*$tick-$min)/($max-$min)]
#		set y [expr (1.0-$pos)*$h]
		set y [expr (1.0*$ls-$j)/$ls*$h+4]
		$g.scale create text 12 [expr $y] -anchor w -text $tick \
		-font *-Helvetica-Medium-R-Normal-*-9-* -tags ticks
	}
}
