itcl::class Display2D {
	private variable parent
	private variable page
	private variable id
	private variable graph
	private variable waves
	private variable unit
	private variable vunit
	private variable image
	private variable limits
	private variable palette
	private variable background
	private variable button
	private variable autoscale
	private variable log
	private variable xmin
	private variable xmax
	private variable ymin
	private variable ymax
	private variable min
	private variable max
	private variable center
	private variable roiwave
	private variable postscript
	private variable xgrid
	private variable ygrid
	private variable message
	private variable timer
	private variable binding
	
	constructor {w} {
		global SpecTkHome
		set parent $w
		set waves ""
		set unit "unknown unknown"
		set message ""
		if {![winfo exist $parent.message]} {
			label $parent.message -text "" -font "Helvetica -10"
			grid propagate $parent 0
			grid $parent.message
		}
		set graph [blt::graph $w.graph]
		set width [$w cget -width]
		set height [$w cget -height]
		set page [lindex [split $w .] end-1]
		set id [string trimleft [lindex [split $w .] end] display]
		set image [image create photo $this.image]
		set palette [format "%spalette" $this]
		Palette $palette
		$palette LoadColors $SpecTkHome/Rainbow.pal
		set limits "0 0 100 100"
		set center "50 50"
		set background white
		set autoscale 1
		set log 0
		set roiwave 0
		set postscript ""
		set xmin ""
		set xmax ""
		set ymin ""
		set ymax ""
		set min 1
		set max ""
		set xgrid 0
		set ygrid 0
		set binding BindSelect
		$graph configure -width $width -height $height -plotpadx 0 -plotpady 0
		if {[string equal [$parent cget -relief] sunken]} {$graph configure -background gray}
		$graph legend configure -position plotarea -anchor nw -hide yes
		$graph axis configure y -title [lindex $unit 1] -logscale no -rotate 90
		$graph axis configure x -title [lindex $unit 0]
		$graph marker create image -image $image -name $image -anchor sw -coords {-Inf -Inf}
		button $graph.magnify -image plus -width 8 -height 8 -command "$page Magnify $id"
		$graph marker create window -window $graph.magnify -coords {Inf Inf} -anchor ne
		button $graph.sigma -image sigma -width 8 -height 8 -command "$this ShowROIResults"
		$graph marker create window -window $graph.sigma -coords {-Inf Inf} -anchor nw
		canvas $graph.scale -height [expr $height-20] -width 15 -borderwidth 2 -relief sunken
		$graph marker create window -window $graph.scale -coords {Inf -Inf} -anchor sw
		pack $graph -expand 1 -fill both -anchor center
		bind $graph <Configure> "$this ResizeImage"
	}
	
	destructor {
		itcl::delete object $palette
		image delete $this.image
		$page RemoveDisplay $id
	}
	
	public method GetMember {m} {set $m}
	public method SetMember {m v} {set $m $v}
	public method Resize {}
	public method ResizeImage {}
	public method UpdateScale {}
	public method BindSelect {}
	public method BindDisplay {}
	public method BindZoom {}
	public method BindScroll {}
	public method BindExpand {}
	public method BindInspect {}
	public method BindEdit {}
	public method Unbind {}
	public method SelectEnter {}
	public method SelectLeave {}
	public method SelectMotion {x y}
	public method ZoomEnter {}
	public method ZoomLeave {}
	public method ZoomMotion {x y}
	public method ZoomLeftClick {x y m}
	public method ZoomRightClick {}
	public method ZoomDoubleClick {}
	public method UnZoom {}
	public method ZoomShrink {}
	public method ZoomExpand {}
	public method ZoomImage {}
	public method ScrollMotion {x y}
	public method Scroll {}
	public method ButtonPress {x y m}
	public method ButtonRelease {}
	public method ExpandMinus {}
	public method ExpandPlus {}
	public method ExpandAuto {}
	public method SetLog {}
	public method SetLin {}
	public method InspectMotion {x y}
	public method Click {x y m}
	public method AssignWave {w}
#	public method AppendWave {w}
#	public method RemoveWave {w}
	public method UpdateDisplay {}
	public method UpdateROIs {}
	public method Update {}
	public method BuildROIResults {}
	public method UpdateROIResults {wave}
	public method ShowROIResults {}
	public method HideROIResults {}
	public method LeftROIResults {}
	public method RightROIResults {}
	public method Write {file}
	public method Read {}
	public method Print {w h}
	public method PostScript {l}
	public method DrawXGrid {}
	public method DrawYGrid {}
	public method RemoveXGrid {}
	public method RemoveYGrid {}
}

itcl::body Display2D::Resize {} {
	global spectk
	if {![winfo exist $graph]} {return}
	set font(0) graphs1
	set font(1) graphs2
	set font(2) graphs3
	set font(3) graphs4
	set tick(0) 2
	set tick(1) 4
	set tick(2) 6
	set tick(3) 8
	set topmargin(0) 16
	set topmargin(1) 18
	set topmargin(2) 20
	set topmargin(3) 22
	set thresholds [list 150 300 400 600]
	set width [expr [$parent cget -width] - 4]
	set height [expr [$parent cget -height] - 4]
	set tw -1
	set th -1
	for {set i 0} {$i < 4} {incr i} {
		if {$width > [lindex $thresholds $i]} {set tw $i}
		if {$height > [lindex $thresholds $i]} {set th $i}
	}
	$graph configure -width $width -height $height
	if {$tw == -1} {
		$graph axis configure y -hide yes
	} else {
		$graph axis configure y -tickfont $font($tw) -titlefont $font($tw) -hide no \
		-ticklength $tick($tw)
	}
	if {$th == -1} {
		$graph axis configure x -hide yes
		$graph configure -font $font(0) -topmargin $topmargin(0)
	} else {
		$graph axis configure x -tickfont $font($th) -titlefont $font($th) -hide no \
		-ticklength $tick($th)
		$graph configure -font $font($th) -topmargin $topmargin($th)
	}
}

itcl::body Display2D::ResizeImage {} {
	if {![winfo exist $graph]} {return}
	if {[lsearch [itcl::find object -isa Wave2D] $waves] == -1} {return}
# recalculate the image display of the spectrum
# updates are required to get the dimensions of the plot right
	update
	UpdateScale
	update
	$image configure -width [$graph extents plotwidth] -height [$graph extents plotheight]
	set scale [$palette GetMember scale]
	set colors [$palette GetMember colors]
	if {[string equal $background black]} {
		Set2DImage $image "$waves.x $waves.y $waves.z" $limits $scale $colors
	} else {
		Set2DImage $image "$waves.x $waves.y $waves.z" $limits $scale $colors -background $background
	}
# Update grid if shown
	if {$xgrid} {DrawXGrid} else {RemoveXGrid}
	if {$ygrid} {DrawYGrid} else {RemoveYGrid}
}

itcl::body Display2D::UpdateScale {} {
	if {![winfo exist $graph]} {return}
	$palette SetDisplay $graph [expr [$graph extents plotheight]-4] [$parent cget -width]
}

itcl::body Display2D::BindSelect {} {
	if {![winfo exist $graph]} {return}
	bind $graph <ButtonPress-1> "$page SelectDisplay $id 1"
	bind $graph <Shift-ButtonPress-1> "$page SelectDisplay $id 0"
	bind $graph <Enter> "$this SelectEnter"
	bind $graph <Leave> "$this SelectLeave"
	bind $graph <Motion> "$this SelectMotion %x %y"
	$graph configure -cursor arrow
	set binding BindSelect
}

itcl::body Display2D::SelectEnter {} {
	global spectk
	set spectk(spectruminfo) [$waves GetMember name]
	set spectk(xunit) [lindex $unit 0]
	set spectk(yunit) [lindex $unit 1]
	set spectk(vunit) ""
	set spectk(vvalue) ""
}

itcl::body Display2D::SelectLeave {} {
	global spectk
	set spectk(spectruminfo) ""
	set spectk(xunit) ""
	set spectk(xvalue) ""
	set spectk(yunit) ""
	set spectk(yvalue) ""
	set spectk(vunit) ""
	set spectk(vvalue) ""
}

itcl::body Display2D::SelectMotion {xscreen yscreen} {
	global spectk
	set x [$graph axis invtransform x $xscreen]
	set y [$graph axis invtransform y $yscreen]
	set waveinfo [$waves GetBin $x $y]
	set x [lindex $waveinfo 0]
	set y [lindex $waveinfo 1]
	set v [lindex $waveinfo 2]
	set spectk(xunit) [lindex $unit 0]
	set spectk(xvalue) [format %.4g $x]
	set spectk(yunit) [lindex $unit 1]
	set spectk(yvalue) [format %.4g $y]
	set spectk(vunit) $vunit
	set spectk(vvalue) [format %.4g $v]
}

itcl::body Display2D::BindDisplay {} {
}

itcl::body Display2D::Unbind {} {
	global spectk
	if {![winfo exist $graph]} {return}
	foreach roi [itcl::find objects -class ROI] {
		foreach w $waves {
			if {[lsearch [itcl::find object -isa Wave2D] $w] != -1} {
				if {[string equal [$w GetMember parameter] [$roi GetMember parameters]]} {
					$roi UnbindEdit $graph
				}
			}
		}
	}
	foreach b [bind $graph] {
		bind $graph $b {}
	}
	bind $graph <Configure> "$this ResizeImage"
	$graph configure -cursor left_ptr
	set spectk(spectruminfo) ""
	set spectk(xunit) ""
	set spectk(xvalue) ""
	set spectk(yunit) ""
	set spectk(yvalue) ""
	set spectk(vunit) ""
	set spectk(vvalue) ""
}

itcl::body Display2D::BindZoom {} {
	if {![winfo exist $graph]} {return}
	Unbind
	bind $graph <Enter> "$this ZoomEnter"
	bind $graph <Leave> "$this ZoomLeave"
	bind $graph <Motion> "$this ZoomMotion %x %y"
	bind $graph <Double-ButtonPress-1> "$this ZoomDoubleClick"
	bind $graph <ButtonPress-1> "$this ZoomLeftClick %x %y 1"
	bind $graph <Shift-ButtonPress-1> "$this ZoomLeftClick %x %y 0"
	bind $graph <ButtonPress-3> "$this ZoomRightClick"
	$graph configure -cursor crosshair
	set binding BindZoom
}

itcl::body Display2D::ZoomEnter {} {
	global spectk
	$graph crosshairs configure -hide no -color red
	$graph marker create text -name value -anchor sw -font "graphlabels" -background ""
	set spectk(spectruminfo) [$waves GetMember name]
	set spectk(xunit) [lindex $unit 0]
	set spectk(yunit) [lindex $unit 1]
	set spectk(vunit) ""
	set spectk(vvalue) ""
}

itcl::body Display2D::ZoomLeave {} {
	global spectk
	$graph crosshairs configure -hide yes
	$graph marker delete value
	set spectk(spectruminfo) ""
	set spectk(xunit) ""
	set spectk(xvalue) ""
	set spectk(yunit) ""
	set spectk(yvalue) ""
	set spectk(vunit) ""
	set spectk(vvalue) ""
}

itcl::body Display2D::ZoomMotion {xscreen yscreen} {
	global spectk
	set x [$graph axis invtransform x $xscreen]
	set y [$graph axis invtransform y $yscreen]
	$graph crosshairs configure -position @$xscreen,$yscreen -hide no -color red
	if {![$graph marker exist value]} {
		$graph marker create text -name value -anchor sw -font "graphlabels" -background ""
	}
	$graph marker configure value -coords [list $x $y] -text [format x:%.4g\ny:%.4g $x $y] \
	-outline black
	set waveinfo [$waves GetBin $x $y]
	set x [lindex $waveinfo 0]
	set y [lindex $waveinfo 1]
	set v [lindex $waveinfo 2]
	set spectk(xunit) [lindex $unit 0]
	set spectk(xvalue) [format %.4g $x]
	set spectk(yunit) [lindex $unit 1]
	set spectk(yvalue) [format %.4g $y]
	set spectk(vunit) $vunit
	set spectk(vvalue) [format %.4g $v]
}

itcl::body Display2D::ZoomImage {} {
	global spectk
	set low [$waves GetMember low]
	set high [$waves GetMember high]
	set bins [$waves GetMember bins]
	set xlow [lindex $low 0]; set ylow [lindex $low 1]
	set xhigh [lindex $high 0]; set yhigh [lindex $high 1]
	set xbins [lindex $bins 0]; set ybins [lindex $bins 1]
# get the bin numbers
	set limits [expr int(($xmin-$xlow)/($xhigh-$xlow)*$xbins+0.5)]
	lappend limits [expr int(($ymin-$ylow)/($yhigh-$ylow)*$ybins+0.5)]
	lappend limits [expr int(($xmax-$xlow)/($xhigh-$xlow)*$xbins+0.5)]
	lappend limits [expr int(($ymax-$ylow)/($yhigh-$ylow)*$ybins+0.5)]
# recalculate the limits to match exactly the bin boundaries
	set xmin [expr 1.0*[lindex $limits 0]/$xbins*($xhigh-$xlow)+$xlow]
	set ymin [expr 1.0*[lindex $limits 1]/$ybins*($yhigh-$ylow)+$ylow]
	set xmax [expr 1.0*[lindex $limits 2]/$xbins*($xhigh-$xlow)+$xlow]
	set ymax [expr 1.0*[lindex $limits 3]/$ybins*($yhigh-$ylow)+$ylow]
	$graph axis configure x -min $xmin -max $xmax
	$graph axis configure y -min $ymin -max $ymax
	if {$autoscale && $spectk(autoscale) == 2} {ExpandAuto}
	ResizeImage
}

itcl::body Display2D::ZoomLeftClick {xscreen yscreen mode} {
	global spectk
	set x [$graph axis invtransform x $xscreen]
	set y [$graph axis invtransform y $yscreen]
	set xmin [lindex [$graph axis limits x] 0]
	set xmax [lindex [$graph axis limits x] 1]
	set ymin [lindex [$graph axis limits y] 0]
	set ymax [lindex [$graph axis limits y] 1]
# this selects the display instead of performing the binding’s action
	if {$x < $xmin || $x > $xmax || $y < $ymin || $y > $ymax} {
		$page SelectDisplay $id $mode
		return
	}
	if {[$graph marker exists limit1]} {
# this is our second limit being entered
		set x1 [lindex [$graph marker cget limit1 -coords] 0]
		set y1 [lindex [$graph marker cget limit1 -coords] 1]
		$graph marker delete limit1 line1 line2
#		foreach w [winfo children $spectk(tools)] {
#			$w configure -state normal
#		}
		if {$x1 == $x || $y1 == $y} {
			ZoomDoubleClick
			return
		}
		set xmin [expr $x1<$x? $x1 : $x]
		set xmax [expr $x1>=$x? $x1 : $x]
		set ymin [expr $y1<$y? $y1 : $y]
		set ymax [expr $y1>=$y? $y1 : $y]
		ZoomImage
		set center [list [expr ($xmax+$xmin)/2] [expr ($ymax+$ymin)/2]]
	} else {
# this is our first limit being entered
		$graph marker create line -name line1 -coords [list $x $ymin $x $ymax] -outline red
		$graph marker create line -name line2 -coords [list $xmin $y $xmax $y] -outline red
		$graph marker create text -name limit1 -coords [list $x $y] -text [format x:%.4g\ny:%.4g $x $y] \
		-font "graphlabels" -outline black -background ""
		$graph marker configure value -anchor se
#		foreach w [winfo children $spectk(tools)] {
#			if {[string first zoom $w] == -1} {$w configure -state disable}
#		}
	}
}

itcl::body Display2D::ZoomRightClick {} {
	global spectk
	if {[$graph marker exists limit1]} {
		$graph marker delete limit1 line1 line2
	}
#	foreach w [winfo children $spectk(tools)] {
#		$w configure -state normal
#	}
}

itcl::body Display2D::ZoomDoubleClick {} {
	global spectk
	set low [$waves GetMember low]
	set high [$waves GetMember high]
	set bins [$waves GetMember bins]
	set xmin [lindex $low 0]
	set xmax [lindex $high 0]
	set ymin [lindex $low 1]
	set ymax [lindex $high 1]
	$graph axis configure x -min $xmin -max $xmax
	$graph axis configure y -min $ymin -max $ymax
	set limits "0 0 [lindex $bins 0] [lindex $bins 1]"
#	ZoomRightClick
	if {[$graph marker exists limit1]} {
		$graph marker delete limit1 line1 line2
	}
	if {$autoscale && $spectk(autoscale) == 2} {ExpandAuto}
	ResizeImage
}

itcl::body Display2D::UnZoom {} {
	ZoomDoubleClick
}

itcl::body Display2D::ZoomShrink {} {
	if {![winfo exist $graph]} {return}
	set xrange [expr [lindex [$graph axis limits x] 1] - [lindex [$graph axis limits x] 0]]
	set yrange [expr [lindex [$graph axis limits y] 1] - [lindex [$graph axis limits y] 0]]
	set xmin [expr [lindex $center 0] - $xrange]
	set xmax [expr [lindex $center 0] + $xrange]
	set ymin [expr [lindex $center 1] - $yrange]
	set ymax [expr [lindex $center 1] + $yrange]
	set low [$waves GetMember low]
	set high [$waves GetMember high]
	set xlow [lindex $low 0]; set ylow [lindex $low 1]
	set xhigh [lindex $high 0]; set yhigh [lindex $high 1]
	if {$xmin < $xlow} {set xmin $xlow}
	if {$xmax > $xhigh} {set xmax $xhigh}
	if {$ymin < $ylow} {set ymin $ylow}
	if {$ymax > $yhigh} {set ymax $yhigh}
	ZoomImage
}

itcl::body Display2D::ZoomExpand {} {
	if {![winfo exist $graph]} {return}
	set xrange [expr [lindex [$graph axis limits x] 1] - [lindex [$graph axis limits x] 0]]
	set yrange [expr [lindex [$graph axis limits y] 1] - [lindex [$graph axis limits y] 0]]
	set xmin [expr [lindex $center 0] - $xrange/4]
	set xmax [expr [lindex $center 0] + $xrange/4]
	set ymin [expr [lindex $center 1] - $yrange/4]
	set ymax [expr [lindex $center 1] + $yrange/4]
	set low [$waves GetMember low]
	set high [$waves GetMember high]
	set xlow [lindex $low 0]; set ylow [lindex $low 1]
	set xhigh [lindex $high 0]; set yhigh [lindex $high 1]
	if {$xmin < $xlow} {set xmin $xlow}
	if {$xmax > $xhigh} {set xmax $xhigh}
	if {$ymin < $ylow} {set ymin $ylow}
	if {$ymax > $yhigh} {set ymax $yhigh}
	ZoomImage
}

itcl::body Display2D::BindExpand {} {
	global spectk
	if {![winfo exist $graph]} {return}
	Unbind
	$graph configure -cursor sb_v_double_arrow
	bind $graph <Enter> "set spectk(spectruminfo) [[$this GetMember waves] GetMember name]"
	bind $graph <Leave> "set spectk(spectruminfo) \"\""
	bind $graph <ButtonPress-1> "$this ExpandMinus %x %y 1"
	bind $graph <Shift-ButtonPress-1> "$this ExpandMinus %x %y 0"
	bind $graph <ButtonPress-3> "$this ExpandPlus"
	bind $graph <Double-ButtonPress-1> "$this ExpandAuto"
	bind $graph <Motion> "$this SelectMotion %x %y"
	set spectk(spectruminfo) [$waves GetMember name]
	set spectk(xunit) ""
	set spectk(xvalue) ""
	set spectk(yunit) ""
	set spectk(yvalue) ""
	set spectk(vunit) ""
	set spectk(vvalue) ""
	set binding BindExpand
}
itcl::body Display2D::ExpandMinus {} {
	if {![winfo exist $graph]} {return}
	set x [$graph axis invtransform x 100]
	set y [$graph axis invtransform y 100]
	set xmin [lindex [$graph axis limits x] 0]
	set xmax [lindex [$graph axis limits x] 1]
	set ymin [lindex [$graph axis limits y] 0]
	set ymax [lindex [$graph axis limits y] 1]
# this selects the display instead of performing the binding’s action
	if {$x < $xmin || $x > $xmax || $y < $ymin || $y > $ymax} {
		$page SelectDisplay $id 0
		return
	}
	set min [$palette GetMember min]
	set max [$palette GetMember max]
	set range [expr ($max-$min)/2]
	set max [expr $min+$range]
	$palette SetScale $min $max
	UpdateScale
	ResizeImage
	set autoscale 0
}
itcl::body Display2D::ExpandPlus {} {
	if {![winfo exist $graph]} {return}
	set min [$palette GetMember min]
	set max [$palette GetMember max]
	set range [expr ($max-$min)*2]
	set max [expr $min+$range]
	$palette SetScale $min $max
	UpdateScale
	ResizeImage
	set autoscale 0
}

itcl::body Display2D::ExpandAuto {} {
	global spectk
	if {![winfo exist $graph]} {return}
	set min 1
	if {[$waves.z length] == 0} {
		set max 2
	} else {
		if {$spectk(autoscale) == 0} {
			set max [blt::vector expr max($waves.z)]
		}
		if {$spectk(autoscale) == 1} {
			blt::vector create x y z
			x set [blt::vector expr $waves.x+1]
			y set [blt::vector expr $waves.y+1]
			z set [blt::vector expr $waves.x*$waves.y*$waves.z]
			z set [blt::vector expr z/x/y]
			set max [blt::vector expr max(z)]
			blt::vector destroy x y z
		}
		if {$spectk(autoscale) == 2} {
			set xlow [lindex [$waves GetMember low] 0]
			set ylow [lindex [$waves GetMember low] 1]
			set xinc [lindex [$waves GetMember increment] 0]
			set yinc [lindex [$waves GetMember increment] 1]
			set xl [list $xmin $xmax $xmax $xmin]
			set yl [list $ymin $ymin $ymax $ymax]
			blt::vector create x y z
			Wave2DInPolygon $xl $yl "$xlow $ylow $xinc $yinc" "$waves.x $waves.y $waves.z" "x y z"
			set max [blt::vector expr max(z)]
			blt::vector destroy x y z
		}
	}
	$palette SetScale $min $max
	UpdateScale
	ResizeImage
	set autoscale 1
}

itcl::body Display2D::SetLog {} {
	if {![winfo exist $graph]} {return}
	set log 1
	$palette SetLog
	UpdateScale
	ResizeImage
}

itcl::body Display2D::SetLin {} {
	if {![winfo exist $graph]} {return}
	set log 0
	$palette SetLin
	UpdateScale
	ResizeImage
}

itcl::body Display2D::BindScroll {} {
	global spectk
	if {![winfo exist $graph]} {return}
	Unbind
	bind $graph <Enter> "set spectk(spectruminfo) [[$this GetMember waves] GetMember name]"
	bind $graph <Leave> "set spectk(spectruminfo) \"\""
	bind $graph <Motion> "$this ScrollMotion %x %y"
	bind $graph <ButtonPress-1> "$this ButtonPress %x %y 1"
	bind $graph <Shift-ButtonPress-1> "$this ButtonPress %x %y 0"
	bind $graph <ButtonRelease-1> "$this ButtonRelease"
	set spectk(spectruminfo) [$waves GetMember name]
	set spectk(xunit) ""
	set spectk(xvalue) ""
	set spectk(yunit) ""
	set spectk(yvalue) ""
	set spectk(vunit) ""
	set spectk(vvalue) ""
	set binding BindScroll
}

itcl::body Display2D::ScrollMotion {xscreen yscreen} {
	global spectk
	global scrollMotion
	set x [$graph axis invtransform x $xscreen]
	set y [$graph axis invtransform y $yscreen]
	set xmin [$graph axis cget x -min]
	set xmax [$graph axis cget x -max]
	set ymin [$graph axis cget y -min]
	set ymax [$graph axis cget y -max]
	set xmid [expr ($xmax+$xmin) / 2]
	set ymid [expr ($ymax+$ymin) / 2]
	if {$x == $xmid} {set x [expr $xmid+0.0001]}
	set angle [expr atan(($y-$ymid)/($x-$xmid))*180.0/3.141592]
	if {$x-$xmid < 0.0} {set angle [expr $angle+180.0]}
	if {$angle < 0.0} {set angle [expr $angle+360.0]}
	if {$angle > 45.0 && $angle < 135.0} {
		$graph configure -cursor sb_up_arrow
		set scrollMotion 2
	} elseif {$angle > 135.0 && $angle < 225.0} {
		$graph configure -cursor sb_left_arrow
		set scrollMotion -1
	} elseif {$angle > 225.0 && $angle < 315.0} {
		$graph configure -cursor sb_down_arrow
		set scrollMotion -2
	} else {
		$graph configure -cursor sb_right_arrow
		set scrollMotion 1
	}
	set x [$graph axis invtransform x $xscreen]
	set y [$graph axis invtransform y $yscreen]
	set waveinfo [$waves GetBin $x $y]
	set x [lindex $waveinfo 0]
	set y [lindex $waveinfo 1]
	set v [lindex $waveinfo 2]
	set spectk(xunit) [lindex $unit 0]
	set spectk(xvalue) [format %.4g $x]
	set spectk(yunit) [lindex $unit 1]
	set spectk(yvalue) [format %.4g $y]
	set spectk(vunit) $vunit
	set spectk(vvalue) [format %.4g $v]
}

itcl::body Display2D::Scroll {} {
	global scrollMotion
	set xmin [lindex [$graph axis limits x] 0]
	set xmax [lindex [$graph axis limits x] 1]
	set ymin [lindex [$graph axis limits y] 0]
	set ymax [lindex [$graph axis limits y] 1]

	set low [$waves GetMember low]
	set high [$waves GetMember high]
	set bins [$waves GetMember bins]
	set xlow [lindex $low 0]; set ylow [lindex $low 1]
	set xhigh [lindex $high 0]; set yhigh [lindex $high 1]
	set xbins [lindex $bins 0]; set ybins [lindex $bins 1]

# get the bin numbers
	set xbmin [expr int(($xmin-$xlow)/($xhigh-$xlow)*$xbins+0.5)]
	set ybmin [expr int(($ymin-$ylow)/($yhigh-$ylow)*$ybins+0.5)]
	set xbmax [expr int(($xmax-$xlow)/($xhigh-$xlow)*$xbins+0.5)]
	set ybmax [expr int(($ymax-$ylow)/($yhigh-$ylow)*$ybins+0.5)]
	set xinc [expr ($xbmax - $xbmin) / 100]
	set yinc [expr ($ybmax - $ybmin) / 100]
	if {$xinc == 0} {incr xinc}
	if {$yinc == 0} {incr yinc}

	if {$scrollMotion == 1} {
		if {$xbmin-$xinc > 0} {
			set xbmin [expr $xbmin-$xinc]
			set xbmax [expr $xbmax-$xinc]
			set limits [list $xbmin $ybmin $xbmax $ybmax]
		}
	} elseif {$scrollMotion == -1} {
		if {$xbmax+$xinc < $xbins} {
			set xbmin [expr $xbmin+$xinc]
			set xbmax [expr $xbmax+$xinc]
			set limits [list $xbmin $ybmin $xbmax $ybmax]
		}
	} elseif {$scrollMotion == 2} {
		if {$ybmin-$yinc > 0} {
			set ybmin [expr $ybmin-$yinc]
			set ybmax [expr $ybmax-$yinc]
			set limits [list $xbmin $ybmin $xbmax $ybmax]
		}
	} elseif {$scrollMotion == -2} {
		if {$ybmax+$yinc < $ybins} {
			set ybmin [expr $ybmin+$yinc]
			set ybmax [expr $ybmax+$yinc]
			set limits [list $xbmin $ybmin $xbmax $ybmax]
		}
	}
# recalculate the limits to match exactly the bin boundaries
	set xmin [expr 1.0*[lindex $limits 0]/$xbins*($xhigh-$xlow)+$xlow]
	set ymin [expr 1.0*[lindex $limits 1]/$ybins*($yhigh-$ylow)+$ylow]
	set xmax [expr 1.0*[lindex $limits 2]/$xbins*($xhigh-$xlow)+$xlow]
	set ymax [expr 1.0*[lindex $limits 3]/$ybins*($yhigh-$ylow)+$ylow]
	$graph axis configure x -min $xmin -max $xmax
	$graph axis configure y -min $ymin -max $ymax
	set center [list [expr ($xmax+$xmin)/2] [expr ($ymax+$ymin)/2]]
	ResizeImage
	if {$button} {after idle $this Scroll}
}

itcl::body Display2D::ButtonPress {xscreen yscreen mode} {
	set x [$graph axis invtransform x $xscreen]
	set y [$graph axis invtransform y $yscreen]
	set xmin [lindex [$graph axis limits x] 0]
	set xmax [lindex [$graph axis limits x] 1]
	set ymin [lindex [$graph axis limits y] 0]
	set ymax [lindex [$graph axis limits y] 1]
# this selects the display instead of performing the binding’s action
	if {$x < $xmin || $x > $xmax || $y < $ymin || $y > $ymax} {
		$page SelectDisplay $id $mode
		return
	}
	set button 1
	Scroll
}

itcl::body Display2D::ButtonRelease {} {
	set button 0
}

itcl::body Display2D::BindInspect {} {
	global spectk
	if {![winfo exist $graph]} {return}
	Unbind
	bind $graph <Enter> "$this ZoomEnter"
	bind $graph <Leave> "$this ZoomLeave"
	bind $graph <Motion> "$this InspectMotion %x %y"
	bind $graph <ButtonPress> "$this Click %x %y 1"
	bind $graph <Shift-ButtonPress> "$this Click %x %y 0"
	$graph configure -cursor dotbox
	set binding BindInspect
}

itcl::body Display2D::InspectMotion {xscreen yscreen} {
	global spectk
	set x [$graph axis invtransform x $xscreen]
	set y [$graph axis invtransform y $yscreen]
	set waveinfo [$waves GetBin $x $y]
	set x [lindex $waveinfo 0]
	set y [lindex $waveinfo 1]
	set v [lindex $waveinfo 2]
	set xs [$graph axis transform x $x]
	set ys [$graph axis transform y $y]
	$graph crosshairs configure -position @$xs,$ys -hide no -color red
	if {![$graph marker exist value]} {
		$graph marker create text -name value -anchor sw -font "graphlabels" -background ""
	}
	$graph marker configure value -coords [list $x $y] -text [format %.4g $v] -outline black
	set spectk(xunit) [lindex $unit 0]
	set spectk(xvalue) [format %.4g $x]
	set spectk(yunit) [lindex $unit 1]
	set spectk(yvalue) [format %.4g $y]
	set spectk(vunit) $vunit
	set spectk(vvalue) [format %.4g $v]
}

itcl::body Display2D::Click {xscreen yscreen mode} {
	global spectk
	set x [$graph axis invtransform x $xscreen]
	set y [$graph axis invtransform y $yscreen]
	set xmin [lindex [$graph axis limits x] 0]
	set xmax [lindex [$graph axis limits x] 1]
	set ymin [lindex [$graph axis limits y] 0]
	set ymax [lindex [$graph axis limits y] 1]
# this selects the display instead of performing the binding’s action
	if {$x < $xmin || $x > $xmax || $y < $ymin || $y > $ymax} {
		$page SelectDisplay $id $mode
		return
	}
}

itcl::body Display2D::BindEdit {} {
	if {![winfo exist $graph]} {return}
	foreach roi [itcl::find objects -class ROI] {
		foreach w $waves {
			if {[string equal [$w GetMember parameter] [$roi GetMember parameters]]} {$roi BindEdit $graph}
			if {[string equal $w [$roi GetMember parameters]]} {$roi BindEdit $graph}
		}
	}
	bind $graph <ButtonPress> "$this Click %x %y 1"
	bind $graph <Shift-ButtonPress> "$this Click %x %y 0"
	set binding BindEdit
}

itcl::body Display2D::AssignWave {w} {
	set message "Spectrum [$w GetMember name]\nnot found!"
	$parent.message configure -text $message
	set waves $w
	set unit [$w GetMember unit]
	set vunit [$w GetMember vunit]
	set p [$w GetMember parameter]
	set low [$w GetMember low]
	set high [$w GetMember high]
	set bins [$w GetMember bins]
	set xmin [lindex $low 0]
	set xmax [lindex $high 0]
	set ymin [lindex $low 1]
	set ymax [lindex $high 1]
	$graph axis configure x -title [format "%s (%s)" [lindex $p 0] [lindex $unit 0]] \
	-min $xmin -max $xmax
	$graph axis configure y -title [format "%s (%s)" [lindex $p 1] [lindex $unit 1]] \
	-min $ymin -max $ymax
	set limits "0 0 [lindex $bins 0] [lindex $bins 1]"
	$graph configure -title [format "%s (%s)" $w [$w GetMember gate]]
	set center [list [expr ($xmax+$xmin)/2] [expr ($ymax+$ymin)/2]]
	Resize
	Update
}

itcl::body Display2D::UpdateDisplay {} {
	if {![winfo exist $graph]} {return}
	set p [$waves GetMember parameter]
	set unit [$waves GetMember unit]
	$graph axis configure x -title [format "%s (%s)" [lindex $p 0] [lindex $unit 0]] -min $xmin -max $xmax
	$graph axis configure y -title [format "%s (%s)" [lindex $p 1] [lindex $unit 1]] -min $ymin -max $ymax
	$graph configure -title [format "%s (%s)" [$waves GetMember name] [$waves GetMember gate]]
	if {$log} {SetLog}
	if {!$log} {SetLin}
	$palette SetScale $min $max
	UpdateScale
}

itcl::body Display2D::UpdateROIs {} {
	if {![winfo exist $graph]} {return}
	foreach wave $waves {
		foreach roi [$wave FindROIs] {
			$roi UpdateDisplay $graph
		}
	}
}

itcl::body Display2D::Update {} {
	if {![winfo exist $graph]} {return}
	if {[lsearch [itcl::find object -isa Wave2D] $waves] == -1} {return}
	$waves Update 1
	if {[winfo exist $graph.hide]} {UpdateROIResults $waves}
	if {$autoscale} {ExpandAuto}
	UpdateDisplay
	UpdateROIs
	UpdateROIDialog
	UpdateExpandDialog
}

itcl::body Display2D::DrawXGrid {} {
	if {![winfo exist $graph]} {return}
	foreach m [$graph marker names xgrid*] {$graph marker delete $m}
	set major [$graph axis cget x -majorticks]
	set minor [$graph axis cget x -minorticks]
	set gap [expr [lindex $major 1]-[lindex $major 0]]
	set i 0
	foreach majeur $major {
		$graph marker create line -name xgrid$i -coords "$majeur -Inf $majeur Inf" \
		-linewidth 1 -outline gray -dashes 1.0
		if {$majeur == [lindex $major end]} {break}
		incr i
		foreach mineur $minor {
			set xtick [expr $majeur+$gap*$mineur]
			$graph marker create line -name xgrid$i -coords "$xtick -Inf $xtick Inf" \
			-linewidth 1 -outline gray -dashes 1.0
			incr i
		}
	}
}

itcl::body Display2D::DrawYGrid {} {
	if {![winfo exist $graph]} {return}
	foreach m [$graph marker names ygrid*] {$graph marker delete $m}
	set major [$graph axis cget y -majorticks]
	set minor [$graph axis cget y -minorticks]
	set gap [expr [lindex $major 1]-[lindex $major 0]]
	set i 0
	foreach majeur $major {
		$graph marker create line -name ygrid$i -coords "-Inf $majeur Inf $majeur" \
		-linewidth 1 -outline gray -dashes 1.0
		if {$majeur == [lindex $major end]} {break}
		incr i
		foreach mineur $minor {
			set xtick [expr $majeur+$gap*$mineur]
			$graph marker create line -name ygrid$i -coords "-Inf $xtick Inf $xtick" \
			-linewidth 1 -outline gray -dashes 1.0
			incr i
		}
	}
}

itcl::body Display2D::RemoveXGrid {} {
	if {![winfo exist $graph]} {return}
	foreach m [$graph marker names xgrid*] {$graph marker delete $m}
}

itcl::body Display2D::RemoveYGrid {} {
	if {![winfo exist $graph]} {return}
	foreach m [$graph marker names ygrid*] {$graph marker delete $m}
}

itcl::body Display2D::BuildROIResults {} {
	button $graph.hide -image cross -width 8 -height 8 -command "$this HideROIResults"
	$graph marker create window -window $graph.hide -coords {-Inf Inf} -anchor nw -name roihide
}

itcl::body Display2D::UpdateROIResults {wave} {
	global spectk
	if {[$graph marker exist roidisplay]} {$graph marker delete roidisplay}
	set str [$wave GetMember name]
	append str [format "\n%-8s%-8s%-8s%-8s%-8s%-8s%-8s" ROI Sum Ratio <X> <Y> FWHM_X FWHM_Y]
	set r [$wave GetMember calc(All)]
	append str [format "\n%-8s%- 8.7g%- 8.5g%- 8.5g%- 8.5g%- 8.5g%- 8.5g" \
	All [lindex $r 0] [lindex $r 1] [lindex $r 2] [lindex $r 3] [lindex $r 4] [lindex $r 5]]
	foreach roi [$wave FindROIs] {
		set r [$wave GetMember calc($roi)]
		append str [format "\n%-8.8s%- 8.7g%- 8.5g%- 8.5g%- 8.5g%- 8.5g%- 8.5g" \
		[$roi GetMember name] [lindex $r 0] [lindex $r 1] [lindex $r 2] [lindex $r 3] [lindex $r 4] [lindex $r 5]]
	}
	$graph marker create text -name roidisplay -coords "-Inf Inf" -text $str -anchor nw \
	-background ivory -justify left -font roiresults
}

itcl::body Display2D::ShowROIResults {} {
	BuildROIResults
#	Update
	foreach roi [$waves FindROIs] {$waves CalculateROI $roi}
	if {$roiwave >= [llength $waves]} {set roiwave 0}
	UpdateROIResults [lindex $waves $roiwave]
}

itcl::body Display2D::LeftROIResults {} {
	incr roiwave -1
	if {$roiwave < 0} {set roiwave [expr [llength $waves] -1]}
	UpdateROIResults [lindex $waves $roiwave]
}

itcl::body Display2D::RightROIResults {} {
	incr roiwave
	if {$roiwave == [llength $waves]} {set roiwave 0}
	UpdateROIResults [lindex $waves $roiwave]
}

itcl::body Display2D::HideROIResults {} {
	$graph marker delete roidisplay roihide
	destroy $graph.hide
}

itcl::body Display2D::Write {file} {
	set name [format %s%s $page $id]
	puts $file "##### Begin Display2D $name definition #####"
	puts $file "Display2D $name $parent"
	puts $file "$name SetMember waves \"$waves\""
	puts $file "$name SetMember unit \"$unit\""
	puts $file "$name SetMember vunit \"$vunit\""
	puts $file "$name SetMember autoscale $autoscale"
	puts $file "$name SetMember log $log"
	puts $file "$name SetMember min \"$min\""
	puts $file "$name SetMember max \"$max\""
	puts $file "$name SetMember xmin \"$xmin\""
	puts $file "$name SetMember xmax \"$xmax\""
	puts $file "$name SetMember ymin \"$ymin\""
	puts $file "$name SetMember ymax \"$ymax\""
	puts $file "$name SetMember center \"$center\""
	puts $file "$name SetMember roiwave $roiwave"
#	puts $file "$name SetMember background $background"
	puts $file "$name SetMember xgrid $xgrid"
	puts $file "$name SetMember ygrid $ygrid"
	puts $file "$name SetMember message \"$message\""
	puts $file "##### End Display2D $name definition #####"
}

itcl::body Display2D::Read {} {
	$parent.message configure -text $message
	if {![winfo exist $graph]} {return}
	set w [lindex $waves 0]
	if {[lsearch [itcl::find object -isa Wave2D] $w] != -1} {
		set s [spectrum -list [$w GetMember spectrum]]
		if {[string equal $s ""]} {
			itcl::delete object $w
#			set waves ""
			destroy $graph
		} else {
			ZoomImage
		}
	} else {
		destroy $graph
	}
}

itcl::body Display2D::PostScript {landscape} {
	if {![winfo exist $graph]} {return}
#	set bg $background
#	set background white
	set dbg [$graph cget -background]
	$graph configure -background lightgray
#	ResizeImage
	set postscript [$graph postscript output -landscape $landscape -preview 1]
	set postscript [RemovePostScriptMarker $postscript marker1]
	set postscript [RemovePostScriptMarker $postscript marker2]
	if {[winfo exist $graph.roi]} {set postscript [RemovePostScriptMarker $postscript roidisplay]}
	set cela [string trimleft $this :]
	set file [open $cela.eps w]
	puts $file $postscript
	close $file
#	set background $bg
#	ResizeImage
	$graph configure -background $dbg
	set cela [format "%s%s" $cela "scale"]
	set postscript [$graph.scale postscript -rotate $landscape]
	set file [open $cela.eps w]
	puts $file $postscript
	close $file
	if {[winfo exist $graph.roi]} {
		set cela [string trimleft $this :]
		set cela [format "%s%s" $cela "roi"]
		set postscript [$graph.roi postscript -rotate $landscape]
		set postscript [RemovePostScriptButton $postscript $graph.roi.hide]
#		set postscript [RemovePostScriptButton $postscript $graph.roi.left]
#		set postscript [RemovePostScriptButton $postscript $graph.roi.right]
		set file [open $cela.eps w]
		puts $file $postscript
		close $file
	}
}

itcl::body Display2D::Print {width height} {
	global spectk postscriptfunctions
	set savewidth [$parent cget -width]
	set saveheight [$parent cget -height]
	set bg $background
	set background white
	set dbg [$graph cget -background]
	$graph configure -background lightgray
	$parent configure -width $width -height $height
	Resize
	ResizeImage
	foreach m [$graph marker names] {
		if {[string match *text* $m]} {$graph marker configure $m -outline black}
	}
	if {[winfo exist $graph.roi]} {
		foreach i [$graph.roi find all] {
			if {[string equal [$graph.roi type $i] text]} {$graph.roi itemconfigure $i -fill lightgray}
		}
		update
	}
	set gpost [$graph postscript output -width 0 -height 0]
	set gpost [RemovePostScriptMarker $gpost marker1]
	set gpost [RemovePostScriptMarker $gpost marker2]
	if {[winfo exist $graph.roi]} {
		foreach i [$graph.roi find all] {
			if {[string equal [$graph.roi type $i] text]} {$graph.roi itemconfigure $i -fill black}
		}
		update
	}
	set i [string first BoundingBox: $gpost]
	set gbound [string range $gpost [expr $i+13] [expr $i+27]]
	set spost [$graph.scale postscript]
	set i [string first BoundingBox: $spost]
	set sbound [string range $spost [expr $i+13] [expr $i+27]]
	set swidth [expr [lindex $sbound 2] - [lindex $sbound 0] + 1]
	set gwidth [expr [lindex $gbound 2] - [lindex $gbound 0] + 1]
	set gheight [expr [lindex $gbound 3] - [lindex $gbound 1] + 1]
	set sleft [expr ($gwidth-$swidth)/2 + 3]
	set sbottom [expr ([$graph extents bottommargin] - [$graph extents topmargin]) / 2]
	set postscript "%!PS-Adobe-3.0 EPSF-3.0\n"
	append postscript "%%BoundingBox: $gbound\n"
	append postscript "%%EndComments\n"
	append postscript "%%BeginProlog\n"
	append postscript $postscriptfunctions
	append postscript "%%EndProlog\n"
	append postscript "BeginEPSF\n"
	append postscript "0 0 translate\n"
	append postscript "%%BeginDocument\n"
	append postscript $gpost
	append postscript "%%EndDocument\n"
	append postscript "EndEPSF\n"
	append postscript "BeginEPSF\n"
	append postscript "$sleft $sbottom translate\n"
	append postscript "%%BeginDocument\n"
	append postscript $spost
	append postscript "%%EndDocument\n"
	append postscript "EndEPSF\n"		
	if {[winfo exist $graph.roi]} {
		set rpost [$graph.roi postscript]
		set rpost [RemovePostScriptButton $rpost $graph.roi.hide]
#		set rpost [RemovePostScriptButton $rpost $graph.roi.left]
#		set rpost [RemovePostScriptButton $rpost $graph.roi.right]
		set i [string first BoundingBox: $rpost]
		set rbound [string range $rpost [expr $i+13] [expr $i+27]]
		set rwidth [expr [lindex $rbound 2] - [lindex $rbound 0] + 1]
		set rheight [expr [lindex $rbound 3] - [lindex $rbound 1] + 1]
		set rleft [expr (-$gwidth+$rwidth)/2 + [$graph extents leftmargin] + 2]
		set rbottom [expr ($gheight-$rheight)/2 - [$graph extents topmargin] - 2]
		append postscript "BeginEPSF\n"
		append postscript "$rleft $rbottom translate\n"
		append postscript "%%BeginDocument\n"
		append postscript $rpost
		append postscript "%%EndDocument\n"
		append postscript "EndEPSF\n"		
	}
	set background $bg
	$parent configure -width $savewidth -height $saveheight
	Resize
	ResizeImage
	foreach m [$graph marker names] {
		if {[string match *text* $m]} {$graph marker configure $m -outline white}
	}
	$graph configure -background $dbg
	return $postscript
}
