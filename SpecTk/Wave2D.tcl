itcl::class Wave2D {
	private variable name
	private variable bins
	private variable low
	private variable high
	private variable increment
	private variable unit
	private variable vunit
	private variable parameter
	private variable spectrum
	private variable type
	private variable datatype
	private variable gate
	private variable calc
	
	constructor {theName} {
		set name $theName
		set bins "100 100"
		set low "0 0"
		set high "100 100"
		set unit "unknown unknown"
		set vunit ""
		set parameter ""
		set spectrum ""
		set increment ""
		set type ""
		set gate True
		blt::vector create $this.x $this.y $this.z
	}
	
	destructor {
		blt::vector destroy $this.x $this.y $this.z
# To look alive we need to delete the displays as well
		foreach d [FindDisplays] {
			destroy [$d GetMember graph]
#			itcl::delete object $d
		}
	}
	
	public method GetMember {m} {set $m}
	public method SetMember {m v} {set $m $v}
	public method Assign {s}
	public method Update {withdata}
	public method SetVectors {}
	public method GetBin {x y}
	public method FindROIs {}
	public method FindGates {}
	public method FindDisplays {}
	public method CreateROI {}
	public method CalculateROI {roi}
	public method CalculateAll {}
	public method Clear {}
	public method Write {file}
	public method Read {}
	public method getName {}
}

itcl::body Wave2D::Clear {} {
	set bins 100
	set low 0
	set high 100
	set increment ""
	set unit unknown
	set vunit unknown
	set parameter ""
	set spectrum ""
	set type ""
	set datatype ""
	set gate True
	set xlist ""
	blt::vector destroy $this.data
	blt::vector destroy $this.error
	blt::vector create $this.data
	blt::vector create $this.error
}

itcl::body Wave2D::getName {} {
	return $name
}

itcl::body Wave2D::Assign {s} {
	set spectrum $s
	set vunit Counts
	Update 1
}

itcl::body Wave2D::Update {withdata} {
	set l [spectrum -list $spectrum]
	set type [lindex $l 2]
	set parameter [lindex $l 3]
	set rx [lindex [lindex $l 4] 0]
	set ry [lindex [lindex $l 4] 1]
	set datatype [lindex $l 5]
# Get units from parameters histogrammed in spectrum
# 2D spectrum case
	if {$type == 2} {
		set low [list [lindex $rx 0] [lindex $ry 0]]
		set high [list [lindex $rx 1] [lindex $ry 1]]
		set bins [list [lindex $rx 2] [lindex $ry 2]]
		set increment [list [expr 1.0*([lindex $high 0]-[lindex $low 0])/[lindex $bins 0]] \
		[expr 1.0*([lindex $high 1]-[lindex $low 1])/[lindex $bins 1]]]
		set lx [parameter -list [lindex $parameter 0]]
		set ly [parameter -list [lindex $parameter 1]]
		set rx [lindex $lx 3]
		set ry [lindex $ly 3]
		set unit [list [lindex $rx 2] [lindex $ry 2]]
	}
# Summary spectrum case
	if {[string equal $type s]} {
		set pbegin [lindex $parameter 0]
		set pend [lindex $parameter end]
		set xlow [string range $pbegin [expr [string last . $pbegin]+1] end]
		set xhigh [string range $pend [expr [string last . $pend]+1] end]
		set low [list $xlow [lindex $rx 0]]
		set high [list [expr $xhigh+1] [lindex $rx 1]]
		set bins [list [llength $parameter] [lindex $rx 2]]
		set increment [list [expr 1.0*([lindex $high 0]-[lindex $low 0])/[lindex $bins 0]] \
		[expr 1.0*([lindex $high 1]-[lindex $low 1])/[lindex $bins 1]]]
		set lx [parameter -list [lindex $parameter 0]]
		set rx [lindex $lx 3]
		set unit [list index [lindex $rx 2]]
		set parameter "xx [string range $pbegin 0 [string last . $pbegin]]xx"
	}
# Gamma 2D spectrum case
	if {[string equal $type g2]} {
		set low [list [lindex $rx 0] [lindex $ry 0]]
		set high [list [lindex $rx 1] [lindex $ry 1]]
		set bins [list [lindex $rx 2] [lindex $ry 2]]
		set increment [list [expr 1.0*([lindex $high 0]-[lindex $low 0])/[lindex $bins 0]] \
		[expr 1.0*([lindex $high 1]-[lindex $low 1])/[lindex $bins 1]]]
		set p [lindex $parameter 0]
		set l [parameter -list $p]
		set r [lindex $l 3]
		set unit [list [lindex $r 2] [lindex $r 2]]
		set par "[string range $p 0 [string last . $p]]xx"
		set parameter [list $par $par]
	}
# Fill vectors with data
	if {$withdata} {
		SetVectors
	}
# Get gate condition on spectrum
	set l [lindex [apply -list $spectrum] 0]
	set r [lindex $l 1]
	set gate [lindex $r 0]
	if {[string equal [lindex $r 2] T]} {set gate True}
	if {[string equal [lindex $r 2] F]} {set gate False}
# Create ROI is necessary
	CreateROI
# Calculate all ROIs
	if {$withdata} {
		CalculateAll
		foreach roi [FindROIs] {CalculateROI $roi}
	}
}

itcl::body Wave2D::SetVectors {} {
	global server
	Get2DData $spectrum
# Get mode (0=bins; 1=compressed)
	binary scan $server(response) "c1" mode
	if {![info exist mode]} {return}
	set xbins [lindex $bins 0]
	set ybins [lindex $bins 1]
	$this.x length 0
	$this.y length 0
	$this.z length 0
	if {$mode == 0} {
		set allbins [expr $xbins * $ybins]
		if {[string equal $datatype byte]} {set fmt "c1 c$allbins"}
		if {[string equal $datatype word]} {set fmt "c1 s$allbins"}
		if {[string equal $datatype long]} {set fmt "c1 i$allbins"}
		binary scan $server(response) $fmt mode datalist
		set lind [lsearch -not $datalist 0]
		while {$lind >= 0} {
			set y [expr int($lind/$xbins)]
			set x [expr $lind-$y*$xbins]
			set data [lindex $datalist $lind]
			if {$data < 0} {
				if {[string equal $datatype byte]} {set data [expr $data+256]}
				if {[string equal $datatype word]} {set data [expr $data+65536]}
				if {[string equal $datatype long]} {set data [expr $data+4294967296]}
			}
			$this.x append $x
			$this.y append $y
			$this.z append $data
			set lind [lsearch -start [expr $lind+1] -not $datalist 0]
			if {$lind == $allbins-1} break
		}
	}
	if {$mode == 1} {
		binary scan $server(response) "c1 i1" mode nchan
		if {$nchan == 0} {return}
		if {[string equal $datatype byte]} {set fmt "c1 i1 s$nchan s$nchan c$nchan"}
		if {[string equal $datatype word]} {set fmt "c1 i1 s$nchan s$nchan s$nchan"}
		if {[string equal $datatype long]} {set fmt "c1 i1 s$nchan s$nchan i$nchan"}
		binary scan $server(response) $fmt mode nchan xchan ychan data
# This loop looks for negative signed integers and converts them into unsigned integers
		set lind [lsearch $data -*]
		while {$lind >= 0} {
			set neg [lindex $data $lind]
			if {[string equal $datatype byte]} {set data [lreplace $data $lind $lind [expr $neg+256]]}
			if {[string equal $datatype word]} {set data [lreplace $data $lind $lind [expr $neg+65536]]}
			if {[string equal $datatype long]} {set data [lreplace $data $lind $lind [expr $neg+4294967296]]}
			set lind [lsearch -start [expr $lind+1] $data -*]
		}
		$this.x set $xchan
		$this.y set $ychan
		$this.z set $data
	}
}

itcl::body Wave2D::GetBin {x y} {
	set binx [expr int(($x - [lindex $low 0]) / [lindex $increment 0])]
	set biny [expr int(($y - [lindex $low 1]) / [lindex $increment 1])]
	set xbin [expr [lindex $low 0] + $binx * [lindex $increment 0]]
	set ybin [expr [lindex $low 1] + $biny * [lindex $increment 1]]
	set xlist [$this.x search $binx]
	set ylist [$this.y search $biny]
	set index -1
	foreach xb $xlist {
		if {[set index [lsearch $ylist $xb]] != -1} break
	}
	if {$index == -1} {return [list $x $y 0]}
	set index [lindex $ylist $index]
	set value [$this.z index $index]
	return [list $xbin $ybin $value]
}

itcl::body Wave2D::FindROIs {} {
	set rois ""
	foreach roi [itcl::find object -class ROI] {
#		set roi [string trimleft $roi :]
		if {[string equal [$roi GetMember parameters] $parameter]} {lappend rois $roi}
#		set cela [string trimleft $this :]
		if {[string equal [$roi GetMember parameters] $this]} {lappend rois $roi}
	}
	return $rois
}

# This method finds gates defined on the same parameters as the wave
# or on a specific spectrum in the case of gamma gates
# Returns a list of gate names
itcl::body Wave2D::FindGates {} {
	set returnList ""
	set gateList [gate -list]
	for {set i 0} {$i < [llength $gateList]} {incr i} {
		set theGate [lindex $gateList $i]
		set gatename [lindex $theGate 0]
		set data [lindex $theGate 3]
		set p [lindex $data 0]
		if {[string equal $p $parameter]} {lappend returnList $gatename}
		set s [lindex $data 1]
#		set cela [string trimleft $this :]
		if {[string equal $s $name]} {lappend returnList $gatename}
	}
	return $returnList
}

# This method finds displays displaying the wave
# Returns a list of displays
itcl::body Wave2D::FindDisplays {} {
	set returnList ""
	set displays [itcl::find object -class Display2D]
#	set cela $this
#	if {[string first : $cela] == 0} {set cela [string trimleft $cela :]}
	foreach d $displays {
		if {[lsearch [$d GetMember waves] $this] != -1} {lappend returnList $d}
	}
	return $returnList
}

itcl::body Wave2D::CreateROI {} {
	foreach g [FindGates] {
		if {[lsearch [itcl::find object -class ROI] "::ROI::[Proper $g]"] == -1} {
			ROI "::ROI::[Proper $g]" $g
			"::ROI::[Proper $g]" GateUpdate $g
		}
	}
}

itcl::body Wave2D::CalculateAll {} {
	set xlow [lindex $low 0]
	set ylow [lindex $low 1]
	set xinc [lindex $increment 0]
	set yinc [lindex $increment 1]
	set sz [blt::vector expr sum($this.z)]
	set calc(All) [format %.7g $sz]
	if {$sz == 0} {
		lappend calc(All) 0 0 0 0 0
	} else {
		lappend calc(All) 100
		lappend calc(All) [set xm [format %.5g [expr [blt::vector expr sum($this.z*($this.x*$xinc+$xlow))] / $sz]]]
		lappend calc(All) [set ym [format %.5g [expr [blt::vector expr sum($this.z*($this.y*$yinc+$ylow))] / $sz]]]
		lappend calc(All) [format %.5g [expr 2.35482*sqrt([blt::vector expr sum($this.z*($this.x*$xinc+$xlow-$xm)^2)] / $sz)]]
		lappend calc(All) [format %.5g [expr 2.35482*sqrt([blt::vector expr sum($this.z*($this.y*$yinc+$ylow-$ym)^2)] / $sz)]]
	}
}

itcl::body Wave2D::CalculateROI {roi} {
	set roitype [$roi GetMember type]
	if {![string equal $roitype c] && ![string equal $roitype gc]} {return}
	set xlow [lindex $low 0]
	set ylow [lindex $low 1]
	set xinc [lindex $increment 0]
	set yinc [lindex $increment 1]
	set xl [$roi GetMember xlimits]
	set yl [$roi GetMember ylimits]
	blt::vector create x y z
	Wave2DInPolygon $xl $yl "$xlow $ylow $xinc $yinc" "$this.x $this.y $this.z" "x y z"
	set sz [blt::vector expr sum(z)]
	set calc($roi) [format %.7g $sz]
	set total [lindex $calc(All) 0]
	if {$sz == 0} {
		lappend calc($roi) 0 0 0 0 0
	} else {
		lappend calc($roi) [format %.5g [expr (100.0*$sz)/$total]]
		lappend calc($roi) [set xm [format %.5g [expr [blt::vector expr sum(z*(x*$xinc+$xlow))] / $sz]]]
		lappend calc($roi) [set ym [format %.5g [expr [blt::vector expr sum(z*(y*$yinc+$ylow))] / $sz]]]
		lappend calc($roi) [format %.5g [expr 2.35482*sqrt([blt::vector expr sum(z*(x*$xinc+$xlow-$xm)^2)] / $sz)]]
		lappend calc($roi) [format %.5g [expr 2.35482*sqrt([blt::vector expr sum(z*(y*$yinc+$ylow-$ym)^2)] / $sz)]]
	}
	blt::vector destroy x y z
}

itcl::body Wave2D::Clear {} {
	if {![string equal $spectrum ""]} {clear $spectrum}
}

itcl::body Wave2D::Write {file} {
	puts $file "##### Begin Wave2D $this definition #####"
	puts $file "Wave2D $this $name"
	puts $file "$this SetMember bins \"$bins\""
	puts $file "$this SetMember low \"$low\""
	puts $file "$this SetMember high \"$high\""
	puts $file "$this SetMember increment \"$increment\""
	puts $file "$this SetMember unit \"$unit\""
	puts $file "$this SetMember vunit \"$vunit\""
	puts $file "$this SetMember parameter \"$parameter\""
	puts $file "$this SetMember spectrum \"$spectrum\""
	puts $file "$this SetMember type \"$type\""
	puts $file "$this SetMember gate \"$gate\""
	puts $file "##### End Wave2D $this definition #####"
}

itcl::body Wave2D::Read {} {
	set s [spectrum -list $spectrum]
	if {[string equal $s ""]} {return}
	Update 0
}
