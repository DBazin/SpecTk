itcl::class Display1D {
	private variable parent
	private variable page
	private variable id
	private variable graph
	private variable waves
	private variable unit
	private variable vunit
	private variable button
	private variable wavecolors
	private variable autoscale
	private variable log
	private variable xmin
	private variable xmax
	private variable min
	private variable max
	private variable center
	private variable roiwave
	private variable postscript
	private variable symbol
	private variable errorbar
	private variable smooth
	private variable pixels
	private variable linewidth
	private variable legend
	private variable xgrid
	private variable ygrid
	private variable message
	private variable binding
	private variable index
	
	constructor {w} {
		set parent $w
		set waves ""
		set unit unknown
		set vunit unknown
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
		set wavecolors {darkblue darkgreen blue purple brown black}
		set autoscale 1
		set log 0
		set min 0.0
		set max ""
		set xmin ""
		set xmax ""
		set center 0
		set roiwave 0
		set postscript ""
		set symbol none
		set errorbar 0
		set smooth step
		set pixels 4
		set linewidth 1
		set legend 1
		set xgrid 0
		set ygrid 0
		set binding select
		set index 0
		$graph configure -width $width -height $height -plotpadx 0 -plotpady 0
		if {[string equal [$parent cget -relief] sunken]} {$graph configure -background gray}
		$graph legend configure -position plotarea -anchor ne -hide yes -font graphlabels -bd 1
		$graph axis configure y -title $vunit -logscale no -rotate 90
		button $graph.magnify -image plus -width 8 -height 8 -command "$page Magnify $id"
		$graph marker create window -window $graph.magnify -coords {Inf Inf} -anchor ne
		button $graph.sigma -image sigma -width 8 -height 8 -command "$this ShowROIResults"
		$graph marker create window -window $graph.sigma -coords {-Inf Inf} -anchor nw
		pack $graph -expand 1 -fill both -anchor center
		UpdateDisplay
	}
	
	destructor {
		$page RemoveDisplay $id
	}
	
	public method GetMember {m} {set $m}
	public method SetMember {m v} {set $m $v}
	public method Resize {}
	public method UpdateDisplay {}
	public method UpdateROIs {}
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
	public method UnZoom {}
	public method ZoomShrink {}
	public method ZoomExpand {}
	public method ScrollMotion {x}
	public method Scroll {}
	public method ButtonPress {x y m}
	public method ButtonRelease {}
	public method ExpandMotion {x y}
	public method ExpandLeftClick {x y m}
	public method ExpandMinus {}
	public method ExpandPlus {}
	public method ExpandAuto {}
	public method SetLog {}
	public method SetLin {}
	public method InspectMotion {x y}
	public method InspectLeftClick {x y m}
	public method EditClick {x y m}
	public method AssignWave {w}
	public method AppendWave {w}
	public method RemoveWave {w}
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
	public method CreateGraph {}
	public method getWave {}
}

itcl::body Display1D::getWave {} {
    if {[info exists waves]} {
        return $waves
    }
}

itcl::body Display1D::CreateGraph {} {
	if {[winfo exist $graph]} {return}
	set graph [blt::graph $parent.graph]
	set width [$parent cget -width]
	set height [$parent cget -height]
	$graph configure -width $width -height $height -plotpadx 0 -plotpady 0
	if {[string equal [$parent cget -relief] sunken]} {$graph configure -background gray}
	$graph legend configure -position plotarea -anchor ne -hide yes -font graphlabels -bd 1
	$graph axis configure y -title $vunit -logscale no -rotate 90
	button $graph.magnify -image plus -width 8 -height 8 -command "$page Magnify $id"
	$graph marker create window -window $graph.magnify -coords {Inf Inf} -anchor ne
	button $graph.sigma -image sigma -width 8 -height 8 -command "$this ShowROIResults"
	$graph marker create window -window $graph.sigma -coords {-Inf Inf} -anchor nw
	pack $graph -expand 1 -fill both -anchor center
}

itcl::body Display1D::Resize {} {
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
		if {[llength $waves] > 1} {$graph legend configure -hide yes}
	} else {
		$graph axis configure y -tickfont $font($tw) -titlefont $font($tw) -hide no \
		-ticklength $tick($tw)
		if {[llength $waves] > 1} {$graph legend configure -hide no}
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

itcl::body Display1D::UpdateDisplay {} {
	if {![winfo exist $graph]} {return}
	if {[lsearch [itcl::find object -isa Wave1D] [lindex $waves 0]] == -1} {return}
	if {[llength $waves] == 0} {
		set unit unknown
		set vunit unknown
		$graph axis configure x -title $unit
		$graph axis configure y -title $vunit
		$graph legend configure -hide yes
		$graph configure -title ""
	} elseif {[llength $waves] == 1} {
		set label [format "%s (%s)" [$waves GetMember parameter] $unit]
		$graph axis configure x -title $label
		$graph axis configure y -title $vunit
		$graph legend configure -hide yes
		set color [lindex $wavecolors 0]
		set sym [lindex $symbol 0]
		set err [lindex $errorbar 0]
		set smo [lindex $smooth 0]
		set pix [lindex $pixels 0]
		set line [lindex $linewidth 0]
		if {[lindex $legend 0]} {set lab $waves} else {set lab ""}
		$graph element configure $waves -color $color -symbol $sym -smooth $smo \
		-pixels $pix -fill "" -linewidth $line -label $lab
		if {$err} {
			$graph element configure $waves -yerror $waves.error
		} else {
			$graph element configure $waves -yerror ""
		}
		$graph configure -title [format "%s (%s)" [$waves GetMember name] [$waves GetMember gate]]
	} else {
		$graph axis configure x -title $unit
		$graph axis configure y -title $vunit
		$graph legend configure -hide no
		set i 0
		set title [[lindex $waves 0] GetMember name]
		foreach w $waves {
			set color [lindex $wavecolors [expr int(fmod($i, [llength $wavecolors]))]]
			set sym [lindex $symbol $i]
			set err [lindex $errorbar $i]
			set smo [lindex $smooth $i]
			set pix [lindex $pixels $i]
			set line [lindex $linewidth $i]
			if {[lindex $legend $i]} {set lab [format "%s (%s)" [$w GetMember name] [$w GetMember gate]]} else {set lab ""}
			$graph element configure $w -color $color -symbol $sym -smooth $smo \
			-pixels $pix -fill "" -linewidth $line -label $lab
			if {$err} {
				$graph element configure $w -yerror $w.error
			} else {
				$graph element configure $w -yerror ""
			}
			if {$i > 0} {append title ", [[lindex $waves $i] GetMember name]"}
			incr i
		}
		$graph configure -title $title
	}
	if {$autoscale} {ExpandAuto}
	if {$log} {
		$waves OffZero
		SetLog
	}
	if {!$log} {SetLin}
	if {$xgrid || $ygrid} {$graph grid on} else {$graph grid off}
	if {$xgrid} {$graph grid configure -mapx x} else {$graph grid configure -mapx ""}
	if {$ygrid} {$graph grid configure -mapy y} else {$graph grid configure -mapy ""}
	if {$xmax > $xmin} {$graph axis configure x -min $xmin -max $xmax}
	if {$log && $min <= 0} {
		if {$max > 1} {$graph axis configure y -min 1 -max $max}
	} else {
		if {$max > $min} {$graph axis configure y -min $min -max $max}
	}
}

itcl::body Display1D::UpdateROIs {} {
	if {![winfo exist $graph]} {return}
	foreach wave $waves {
		if {[lsearch [itcl::find object -isa Wave1D] $waves] != -1} {
#			set color [$graph element cget $wave -color]
			set color red
			foreach roi [$wave FindROIs] {
				$roi UpdateDisplay $graph
				$graph marker configure "min[$roi GetMember name]" -outline $color
				$graph marker configure "max[$roi GetMember name]" -outline $color
			}
		}
	}
}

itcl::body Display1D::BindZoom {} {
	global spectk
	if {![winfo exist $graph]} {return}
	Unbind
	bind $graph <Enter> "$this ZoomEnter"
	bind $graph <Leave> "$this ZoomLeave"
	bind $graph <Motion> "$this ZoomMotion %x %y"
	bind $graph <ButtonPress-1> "$this ZoomLeftClick %x %y 1"
	bind $graph <Shift-ButtonPress-1> "$this ZoomLeftClick %x %y 0"
	bind $graph <ButtonPress-3> "$this ZoomRightClick"
	bind $graph <Double-ButtonPress-1> "$this UnZoom"
	$graph configure -cursor sb_h_double_arrow
	set binding BindZoom
}

itcl::body Display1D::UnZoom {} {
	global spectk
	set xmin 1.0e10
	set xmax -1.0e10
	foreach w $waves {
		set xm [lindex [$w GetMember xlist] 0]
		set xp [lindex [$w GetMember xlist] end]
		if {$xm < $xmin} {set xmin $xm}
		if {$xp > $xmax} {set xmax $xp}
	}
	if {$xmax > $xmin} {$graph axis configure x -min $xmin -max $xmax}
#	ZoomRightClick
	if {[$graph marker exists limit1]} {
		$graph marker delete limit1 line1
	}
	if {$autoscale && $spectk(autoscale) == 2} {ExpandAuto}
}

itcl::body Display1D::ZoomEnter {} {
	global spectk
	$graph crosshairs configure -hide no -color red
	$graph marker create text -name value -anchor sw -font "graphlabels" -background ""
	set spectk(spectruminfo) [[lindex $waves 0] GetMember name]
	set spectk(yunit) ""
	set spectk(yvalue) ""
	set spectk(vunit) ""
	set spectk(vvalue) ""
}

itcl::body Display1D::ZoomLeave {} {
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

itcl::body Display1D::ZoomMotion {xscreen yscreen} {
	global spectk
	set x [$graph axis invtransform x $xscreen]
	set y [$graph axis invtransform y $yscreen]
	$graph crosshairs configure -position @$xscreen,$yscreen -hide no -color red
	if {![$graph marker exist value]} {
		$graph marker create text -name value -anchor sw -font "graphlabels" -background ""
	}
	$graph marker configure value -coords [list $x $y] -text [format %.4g $x]
#	set spectk(xunit) $unit
#	set spectk(xvalue) [format %.4g $x]
#	set x [$graph axis invtransform x $xscreen]
	set waveinfo [[lindex $waves $index] GetBin $x]
	set x [lindex $waveinfo 0]
	set y [lindex $waveinfo 1]
	set spectk(spectruminfo) [[lindex $waves $index] GetMember name]
	set spectk(xunit) $unit
	set spectk(xvalue) [format %.4g $x]
	set spectk(yunit) ""
	set spectk(yvalue) ""
	set spectk(vunit) $vunit
	set spectk(vvalue) [format %.4g $y]
}

itcl::body Display1D::ZoomLeftClick {xscreen yscreen mode} {
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
	set x [$graph axis invtransform x $xscreen]
	set ymin [lindex [$graph axis limits y] 0]
	set ymax [lindex [$graph axis limits y] 1]
	set y [expr ($ymin + $ymax) / 2]
	if {[$graph marker exists limit1]} {
# this is our second limit being entered
		set x1 [lindex [$graph marker cget limit1 -coords] 0]
		$graph marker delete limit1 line1
		foreach w [winfo children $spectk(tools)] {
			$w configure -state normal
		}
		if {$x1 == $x} {
			UnZoom
			return
		}
		set xmin [expr $x1<$x? $x1 : $x]
		set xmax [expr $x1>=$x? $x1 : $x]
		if {$xmax > $xmin} {$graph axis configure x -min $xmin -max $xmax}
		set center [expr ($xmin+$xmax)/2]
		if {$autoscale && $spectk(autoscale) == 2} {ExpandAuto}
	} else {
# this is our first limit being entered
		$graph marker create line -name line1 -coords [list $x $ymin $x $ymax] -outline red
		$graph marker create text -name limit1 -coords [list $x $y] -text [format %.4g $x] \
		-font "graphlabels" -rotate 90 -background ""
		$graph marker configure value -anchor se
		foreach w [winfo children $spectk(tools)] {
			if {[string first zoom $w] == -1} {$w configure -state disable}
		}
	}
}

itcl::body Display1D::ZoomRightClick {} {
	global spectk
	if {[$graph marker exists limit1]} {
		$graph marker delete limit1 line1
	}
	foreach w [winfo children $spectk(tools)] {
		$w configure -state normal
	}
}

itcl::body Display1D::ZoomShrink {} {
	global spectk
	if {![winfo exist $graph]} {return}
	set range [expr [lindex [$graph axis limits x] 1]-[lindex [$graph axis limits x] 0]]
	set xmin [expr $center-$range]
	set xmax [expr $center+$range]
	set xlow [[lindex $waves 0] GetMember low]
	set xhigh [[lindex $waves 0] GetMember high]
	foreach w $waves {
		if {[$w GetMember low] < $xlow} {set xlow [$w GetMember low]}
		if {[$w GetMember high] > $xhigh} {set xhigh [$w GetMember high]}
	}
	if {$xmin < $xlow} {set xmin $xlow}
	if {$xmax > $xhigh} {set xmax $xhigh}
	$graph axis configure x -min $xmin -max $xmax
	if {$autoscale && $spectk(autoscale) == 2} {ExpandAuto}
}

itcl::body Display1D::ZoomExpand {} {
	global spectk
	if {![winfo exist $graph]} {return}
	set range [expr [lindex [$graph axis limits x] 1]-[lindex [$graph axis limits x] 0]]
	set xmin [expr $center-$range/4]
	set xmax [expr $center+$range/4]
	set xlow [[lindex $waves 0] GetMember low]
	set xhigh [[lindex $waves 0] GetMember high]
	foreach w $waves {
		if {[$w GetMember low] < $xlow} {set xlow [$w GetMember low]}
		if {[$w GetMember high] > $xhigh} {set xhigh [$w GetMember high]}
	}
	if {$xmin < $xlow} {set xmin $xlow}
	if {$xmax > $xhigh} {set xmax $xhigh}
	$graph axis configure x -min $xmin -max $xmax
	if {$autoscale && $spectk(autoscale) == 2} {ExpandAuto}
}

itcl::body Display1D::BindExpand {} {
	global spectk
	if {![winfo exist $graph]} {return}
	Unbind
	bind $graph <Enter> "$this ZoomEnter"
	bind $graph <Leave> "$this ZoomLeave"
	bind $graph <Motion> "$this ExpandMotion %x %y"
	bind $graph <ButtonPress-1> "$this ExpandLeftClick %x %y 1"
	bind $graph <Shift-ButtonPress-1> "$this ExpandLeftClick %x %y 0"
	bind $graph <Double-ButtonPress-1> "$this ExpandAuto"
	$graph configure -cursor sb_v_double_arrow
	set spectk(xunit) ""
	set spectk(xvalue) ""
	set spectk(yunit) ""
	set spectk(yvalue) ""
	set binding BindExpand
}

itcl::body Display1D::ExpandMotion {xscreen yscreen} {
	global spectk
	set x [$graph axis invtransform x $xscreen]
	set y [$graph axis invtransform y $yscreen]
	$graph crosshairs configure -position @$xscreen,$yscreen
	if {![$graph marker exist value]} {
		$graph marker create text -name value -anchor sw -font "graphlabels" -background ""
	}
	$graph marker configure value -coords [list $x $y] -text [format %.4g $y]
#	set spectk(spectruminfo) [[lindex $waves 0] GetMember name]
#	set spectk(vvalue) [format %.4g $y]
#	set spectk(vunit) $vunit
	set x [$graph axis invtransform x $xscreen]
	set waveinfo [[lindex $waves $index] GetBin $x]
	set x [lindex $waveinfo 0]
	set y [lindex $waveinfo 1]
	set spectk(spectruminfo) [[lindex $waves $index] GetMember name]
	set spectk(xunit) $unit
	set spectk(xvalue) [format %.4g $x]
	set spectk(yunit) ""
	set spectk(yvalue) ""
	set spectk(vunit) $vunit
	set spectk(vvalue) [format %.4g $y]
}

itcl::body Display1D::ExpandLeftClick {xscreen yscreen mode} {
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
	set max [$graph axis invtransform y $yscreen]
	if {$log} {
		$graph axis configure y -min 1.0 -max $max
	} else {
		$graph axis configure y -min $min -max $max
	}
	set autoscale 0
}

itcl::body Display1D::ExpandPlus {} {
	if {![winfo exist $graph]} {return}
	set max [expr [lindex [$graph axis limits y] 1] *2]
	if {$log} {
		$graph axis configure y -min .5 -max $max
	} else {
		$graph axis configure y -min $min -max $max
	}
	set autoscale 0
}

itcl::body Display1D::ExpandMinus {} {
	if {![winfo exist $graph]} {return}
	set max [expr [lindex [$graph axis limits y] 1] /2]
	if {$log} {
		if {$max > 1.0} {$graph axis configure y -min .5 -max $max}
	} else {
		if {$max > $min} {$graph axis configure y -min $min -max $max}
	}
	set autoscale 0
}

itcl::body Display1D::ExpandAuto {} {
	global spectk
	if {![winfo exist $graph]} {return}
	set min 0.0
	set max 1.0
	blt::vector create dummy
	if {$spectk(autoscale) == 0} {
		foreach w $waves {
			set wmin [blt::vector expr min($w.data)]
			if {$wmin < $min} {set min $wmin}
			set wmax [blt::vector expr max($w.data)]
			if {$wmax*1.1 > $max} {set max [expr $wmax*1.1]}
		}
	}
	if {$spectk(autoscale) == 1} {
		foreach w $waves {
			set bins [$w GetMember bins]
			dummy set [$w.data range 1 [expr $bins-1]]
			set wmin [blt::vector expr min(dummy)]
			if {$wmin < $min} {set min $wmin}
			set wmax [blt::vector expr max(dummy)]
			if {$wmax*1.1 > $max} {set max [expr $wmax*1.1]}
		}
	}
	if {$spectk(autoscale) == 2} {
		foreach w $waves {
			set bins [$w GetMember bins]
			set low [$w GetMember low]
			set high [$w GetMember high]
			if {$xmin > $high || $xmax < $low} {continue}
			set xm $xmin
			set xp $xmax
			if {$xm < $low} {set xm $low}
			if {$xp > $high} {set xp $high}
			set xbmin [expr int(($xm-$low)/($high-$low)*$bins+0.5)]
			set xbmax [expr int(($xp-$low)/($high-$low)*$bins+0.5)]
			dummy set [$w.data range $xbmin $xbmax]
			set wmin [blt::vector expr min(dummy)]
			if {$wmin < $min} {set min $wmin}
			set wmax [blt::vector expr max(dummy)]
			if {$wmax*1.1 > $max} {set max [expr $wmax*1.1]}
		}
	}
	if {$log} {set min .5}
	if {!$log && $min > 0.0} {set min 0.0}
	if {$max > $min} {$graph axis configure y -min $min -max $max}
	set autoscale 1
	blt::vector destroy dummy
}

itcl::body Display1D::SetLog {} {
    if {![winfo exist $graph]} {return}
    set log 1

    if {$log} {
        foreach w $waves {
            if {[lsearch [itcl::find object -isa Wave1D] $w] != -1} {
                $w toggleOffset true
            }
        }
    }

    if {$min <= 0} {set min 0.5}
    if {$max > $min} {$graph axis configure y -min $min}
    catch "$graph axis configure y -log 1"
}

itcl::body Display1D::SetLin {} {
	if {![winfo exist $graph]} {return}
	set log 0
        foreach w $waves {
        if {[lsearch [itcl::find object -isa Wave1D] $w] != -1} {
            $w toggleOffset false ;
        }
    	}
	$graph axis configure y -log 0
	if {$autoscale} {
		ExpandAuto
	} else {
		$graph axis configure y -min $min
	}
}

itcl::body Display1D::BindScroll {} {
	global spectk
	if {![winfo exist $graph]} {return}
	Unbind
	bind $graph <Enter> "set spectk(spectruminfo) [[lindex [$this GetMember waves] 0] GetMember name]"
	bind $graph <Leave> "set spectk(spectruminfo) \"\""
	bind $graph <Motion> "$this ScrollMotion %x"
	bind $graph <ButtonPress-1> "$this ButtonPress %x %y 1"
	bind $graph <Shift-ButtonPress-1> "$this ButtonPress %x %y 0"
	bind $graph <ButtonRelease-1> "$this ButtonRelease"
	set spectk(spectruminfo) [[lindex $waves 0] GetMember name]
	set spectk(xunit) ""
	set spectk(xvalue) ""
	set spectk(yunit) ""
	set spectk(yvalue) ""
	set spectk(vunit) ""
	set spectk(vvalue) ""
	set binding BindScroll
}

itcl::body Display1D::ScrollMotion {xscreen} {
	global spectk
	global scrollMotion
	if {$xscreen > [expr [$graph cget -width] / 2]} {
		$graph configure -cursor sb_right_arrow
		set scrollMotion 1
	} else {
		$graph configure -cursor sb_left_arrow
		set scrollMotion -1
	}
	set x [$graph axis invtransform x $xscreen]
	set waveinfo [[lindex $waves $index] GetBin $x]
	set x [lindex $waveinfo 0]
	set y [lindex $waveinfo 1]
	set spectk(spectruminfo) [[lindex $waves $index] GetMember name]
	set spectk(xunit) $unit
	set spectk(xvalue) [format %.4g $x]
	set spectk(yunit) ""
	set spectk(yvalue) ""
	set spectk(vunit) $vunit
	set spectk(vvalue) [format %.4g $y]
}

itcl::body Display1D::Scroll {} {
	global scrollMotion spectk
	set xmin [lindex [$graph axis limits x] 0]
	set xmax [lindex [$graph axis limits x] 1]
	set xinc [expr ($xmax - $xmin) / 100]
	set xlimit $xmin
	if {$scrollMotion == 1} {
		foreach w $waves {
			if {[$w GetMember low] < $xlimit} {set xlimit [$w GetMember low]}
		}
		if {[expr $xmin-$xinc] > $xlimit} {
			set xmin [expr $xmin-$xinc]
			set xmax [expr $xmax-$xinc]
			if {$xmax > $xmin} {$graph axis configure x -min $xmin -max $xmax}
			set center [expr $center-$xinc]
			if {$autoscale && $spectk(autoscale) == 2} {ExpandAuto}
		}
	} else {
		foreach w $waves {
			if {[$w GetMember high] > $xlimit} {set xlimit [$w GetMember high]}
		}
		if {[expr $xmax+$xinc] < $xlimit} {
			set xmin [expr $xmin+$xinc]
			set xmax [expr $xmax+$xinc]
			if {$xmax > $xmin} {$graph axis configure x -min $xmin -max $xmax}
			set center [expr $center+$xinc]
			if {$autoscale && $spectk(autoscale) == 2} {ExpandAuto}
		}
	}
	if {$button} {after 10 $this Scroll}
}

itcl::body Display1D::ButtonPress {xscreen yscreen mode} {
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

itcl::body Display1D::ButtonRelease {} {
	set button 0
}

itcl::body Display1D::BindInspect {} {
	global spectk
	if {![winfo exist $graph]} {return}
	Unbind
	bind $graph <Enter> "$this ZoomEnter"
	bind $graph <Leave> "$this ZoomLeave"
	bind $graph <Motion> "$this InspectMotion %x %y"
	bind $graph <ButtonPress-1> "$this InspectLeftClick %x %y 1"
	bind $graph <Shift-ButtonPress-1> "$this InspectLeftClick %x %y 0"
	$graph configure -cursor dotbox
	set binding BindInspect
}

itcl::body Display1D::InspectLeftClick {xscreen yscreen mode} {
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
	incr index
	if {$index == [llength $waves]} {set index 0}
	InspectMotion $xscreen $yscreen
}

itcl::body Display1D::InspectMotion {xscreen yscreen} {
	global spectk
	set x [$graph axis invtransform x $xscreen]
	set yc [$graph axis invtransform y $yscreen]
	set waveinfo [[lindex $waves $index] GetBin $x]
	set x [lindex $waveinfo 0]
	set y [lindex $waveinfo 1]
	set xs [$graph axis transform x $x]
	set ys [$graph axis transform y $y]
	$graph crosshairs configure -position @$xs,$ys -hide no -color red
	if {![$graph marker exist value]} {
		$graph marker create text -name value -anchor sw -font "graphlabels" -background ""
	}
	$graph marker configure value -coords [list $x $yc] -text [format %.4g $y]
	set spectk(spectruminfo) [[lindex $waves $index] GetMember name]
	set spectk(xunit) $unit
	set spectk(xvalue) [format %.4g $x]
	set spectk(yunit) ""
	set spectk(yvalue) ""
	set spectk(vunit) $vunit
	set spectk(vvalue) [format %.4g $y]
}

itcl::body Display1D::BindEdit {} {
	if {![winfo exist $graph]} {return}
	foreach roi [itcl::find objects -class ROI] {
		foreach w $waves {
			if {[string equal [$w GetMember parameter] [$roi GetMember parameters]]} {$roi BindEdit $graph}
			if {[string equal $w [$roi GetMember parameters]]} {$roi BindEdit $graph}
		}
	}
	set binding BindEdit
	bind $graph <ButtonPress> "$this EditClick %x %y 1"
	bind $graph <Shift-ButtonPress> "$this EditClick %x %y 0"
}

itcl::body Display1D::EditClick {xscreen yscreen mode} {
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

itcl::body Display1D::BindSelect {} {

	if {![winfo exist $graph]} {return}
	bind $graph <ButtonPress-1> "$page SelectDisplay $id 1"
	bind $graph <Shift-ButtonPress-1> "$page SelectDisplay $id 0"
	bind $graph <Enter> "$this SelectEnter"
	bind $graph <Leave> "$this SelectLeave"
	bind $graph <Motion> "$this SelectMotion %x %y"
	$graph configure -cursor arrow
	set binding BindSelect
}

itcl::body Display1D::SelectEnter {} {
	global spectk
	set spectk(spectruminfo) [[lindex $waves 0] GetMember name]
	set spectk(xunit) [lindex $unit 0]
	set spectk(xvalue) ""
	set spectk(yunit) ""
	set spectk(yvalue) ""
	set spectk(vunit) ""
	set spectk(vvalue) ""
}

itcl::body Display1D::SelectLeave {} {
	global spectk
	set spectk(spectruminfo) ""
	set spectk(xunit) ""
	set spectk(xvalue) ""
	set spectk(yunit) ""
	set spectk(yvalue) ""
	set spectk(vunit) ""
	set spectk(vvalue) ""
}

itcl::body Display1D::SelectMotion {xscreen yscreen} {
	global spectk
	set x [$graph axis invtransform x $xscreen]
	set yc [$graph axis invtransform y $yscreen]
	set waveinfo [[lindex $waves $index] GetBin $x]
	set x [lindex $waveinfo 0]
	set y [lindex $waveinfo 1]
	set spectk(spectruminfo) [[lindex $waves $index] GetMember name]
	set spectk(xunit) $unit
	set spectk(xvalue) [format %.4g $x]
	set spectk(yunit) ""
	set spectk(yvalue) ""
	set spectk(vunit) $vunit
	set spectk(vvalue) [format %.4g $y]
}

itcl::body Display1D::BindDisplay {} {
}

itcl::body Display1D::Unbind {} {
	global spectk
	if {![winfo exist $graph]} {return}
	foreach roi [itcl::find objects -class ROI] {
		foreach w $waves {
			if {[lsearch [itcl::find object -isa Wave1D] $w] != -1} {
				if {[string equal [$w GetMember parameter] [$roi GetMember parameters]]} {
					$roi UnbindEdit $graph
				}
			}
		}
	}
	foreach b [bind $graph] {
		bind $graph $b {}
	}
	$graph configure -cursor left_ptr
	set spectk(spectruminfo) ""
	set spectk(xunit) ""
	set spectk(xvalue) ""
	set spectk(yunit) ""
	set spectk(yvalue) ""
	set spectk(vunit) ""
	set spectk(vvalue) ""
}

itcl::body Display1D::AssignWave {w} {
# Need to delete previously displayed elements and markers
	foreach e [$graph element names] {
		$graph element delete $e
	}
# Then we set display on the assigned wave
	set message "Spectrum [$w GetMember name]\nnot found!"
	$parent.message configure -text $message
	set waves $w
	set n [format "%s (%s)" [$w GetMember parameter] [$w GetMember gate]]
	$graph element create $w -symbol none -smooth step -label $n \
	-xdata [$w GetMember xlist] -ydata $w.data
	set unit [$w GetMember unit]
	set vunit [$w GetMember vunit]
	set center [expr ([lindex [$graph axis limits x] 0]+[lindex [$graph axis limits x] 1])/2]
	set xmin ""
	set xmax ""
	Update
	Resize
}


itcl::body Display1D::AppendWave {w} {
# just create a new element with the wave
	if {[lsearch $waves $w] != -1} {return}
	lappend waves $w
	lappend symbol none
	lappend errorbar 0
	lappend smooth step
	lappend pixels 4
	lappend linewidth 1
	lappend legend 1
	set n [format "%s (%s)" [$w GetMember parameter] [$w GetMember gate]]
	$graph element create $w -symbol none -smooth step -label $n \
	-xdata [$w GetMember xlist] -ydata $w.data
	Update
}

itcl::body Display1D::RemoveWave {w} {
# remove element from graph and from list
	set i [lsearch $waves $w]
	set waves [lreplace $waves $i $i]
	set symbol [lreplace $symbol $i $i]
	set errorbar [lreplace $errorbar $i $i]
	set smooth [lreplace $smooth $i $i]
	set pixels [lreplace $pixels $i $i]
	set linewidth [lreplace $linewidth $i $i]
	set legend [lreplace $legend $i $i]
	$graph element delete $w
	foreach roi [$w FindROIs] {
		set roiname [$roi GetMember name]
		$graph marker delete min$roiname
		$graph marker delete max$roiname
		$graph marker delete lmin$roiname
		$graph marker delete lmax$roiname
	}
	Update
}

itcl::body Display1D::Update {} {
    set waveObjects [itcl::find object -isa Wave1D]
    foreach w $waves {
        if {[lsearch -exact $waveObjects $w] != -1} {
            $w Update 1
            if {[winfo exists $graph.hide]} {
                UpdateROIResults $w
            }
        }
    }
    UpdateDisplay
    UpdateROIs
    UpdateROIDialog
    UpdateExpandDialog
}

itcl::body Display1D::BuildROIResults {} {
	button $graph.hide -image cross -width 8 -height 8 -command "$this HideROIResults"
	$graph marker create window -window $graph.hide -coords {-Inf Inf} -anchor nw -name roihide
	button $graph.right -image rightarrow -width 8 -height 8 -command "$this RightROIResults"
	$graph marker create window -window $graph.right -coords {-Inf Inf} -anchor nw -name roileft -xoffset 16
}

itcl::body Display1D::UpdateROIResults {wave} {
	global spectk
	if {[$graph marker exist roidisplay]} {$graph marker delete roidisplay}
	set str [format "			%s" [$wave GetMember name]]
	append str [format "\n%-8s%-8s%-8s%-8s%-8s" ROI Sum Ratio <X> FWHM]
	set r [$wave GetMember calc(All)]
	append str [format "\n%-8s%- 8.7g%- 8.5g%- 8.5g%- 8.5g" \
	All [lindex $r 0] [lindex $r 1] [lindex $r 2] [lindex $r 3]]
	foreach roi [$wave FindROIs] {
		set r [$wave GetMember calc($roi)]
		append str [format "\n%-8.8s%- 8.7g%- 8.5g%- 8.5g%- 8.5g" \
		[$roi GetMember name] [lindex $r 0] [lindex $r 1] [lindex $r 2] [lindex $r 3]]
	}
	$graph marker create text -name roidisplay -coords "-Inf Inf" -text $str -anchor nw \
	-background ivory -justify left -font roiresults
}

itcl::body Display1D::ShowROIResults {} {
	BuildROIResults
#	Update
	foreach w $waves {
		if {[lsearch [itcl::find object -isa Wave1D] $w] != -1} {
			foreach roi [$w FindROIs] {$w CalculateROI $roi}
		}
	}
	if {$roiwave >= [llength $waves]} {set roiwave 0}
	UpdateROIResults [lindex $waves $roiwave]
}

itcl::body Display1D::LeftROIResults {} {
	incr roiwave -1
	if {$roiwave < 0} {set roiwave [expr [llength $waves] -1]}
	UpdateROIResults [lindex $waves $roiwave]
}

itcl::body Display1D::RightROIResults {} {
	incr roiwave
	if {$roiwave == [llength $waves]} {set roiwave 0}
	UpdateROIResults [lindex $waves $roiwave]
}

itcl::body Display1D::HideROIResults {} {
	$graph marker delete roidisplay roihide roiright
	destroy $graph.hide $graph.right
}

itcl::body Display1D::Write {file} {
	set name [format %s%s $page $id]
	puts $file "##### Begin Display1D $name definition #####"
	puts $file "Display1D $name $parent"
	puts $file "$name SetMember waves \"$waves\""
	puts $file "$name SetMember unit \"$unit\""
	puts $file "$name SetMember vunit \"$vunit\""
	puts $file "$name SetMember autoscale $autoscale"
	puts $file "$name SetMember log $log"
	puts $file "$name SetMember min \"$min\""
	puts $file "$name SetMember max \"$max\""
	puts $file "$name SetMember xmin \"$xmin\""
	puts $file "$name SetMember xmax \"$xmax\""
	puts $file "$name SetMember center $center"
	puts $file "$name SetMember roiwave $roiwave"
	puts $file "$name SetMember symbol \"$symbol\""
	puts $file "$name SetMember errorbar \"$errorbar\""
	puts $file "$name SetMember smooth \"$smooth\""
	puts $file "$name SetMember pixels \"$pixels\""
	puts $file "$name SetMember linewidth \"$linewidth\""
	puts $file "$name SetMember legend \"$legend\""
	puts $file "$name SetMember xgrid \"$xgrid\""
	puts $file "$name SetMember ygrid \"$ygrid\""
	puts $file "$name SetMember message \"$message\""
	puts $file "##### End Display1D $name definition #####"
}

itcl::body Display1D::Read {} {
	$parent.message configure -text $message
	if {![winfo exist $graph]} {return}
#	set ws $waves
	set w [lindex $waves 0]
	set nowave 1
	if {[lsearch [itcl::find object -isa Wave1D] $w] != -1} {
		set s [spectrum -list [$w GetMember spectrum]]
		if {[string equal $s ""]} {
			itcl::delete object $w
#			set ws [lreplace $ws 0 0]
		} else {
			set nowave 0
			set n [format "%s (%s)" [$w GetMember parameter] [$w GetMember gate]]
			$graph element create $w -symbol none -smooth step -label $n \
			-xdata [$w GetMember xlist] -ydata $w.data
		}
	}
	for {set i 1} {$i < [llength $waves]} {incr i} {
		set w [lindex $waves $i]
		if {[lsearch [itcl::find object -isa Wave1D] $w] != -1} {
			set s [spectrum -list [$w GetMember spectrum]]
			if {[string equal $s ""]} {
				itcl::delete object $w
#				set ind [lsearch $ws $w]
#				set ws [lreplace $ws $ind $ind]
			} else {
				set nowave 0
				set n [format "%s (%s)" [$w GetMember parameter] [$w GetMember gate]]
				$graph element create $w -symbol none -smooth step -label $n \
				-xdata [$w GetMember xlist] -ydata $w.data
			}
		}
	}
#	set waves $ws
	if {$nowave} {destroy $graph}
}

itcl::body Display1D::PostScript {landscape} {
	if {![winfo exist $graph]} {return}
	set bg [$graph cget -background]
	$graph configure -background lightgray
	set postscript [$graph postscript output -landscape $landscape -preview 1]
	set postscript [RemovePostScriptMarker $postscript marker1]
	set postscript [RemovePostScriptMarker $postscript marker2]
	if {[winfo exist $graph.roi]} {set postscript [RemovePostScriptMarker $postscript roidisplay]}
	set cela [string trimleft $this :]
	set file [open $cela.eps w]
	puts $file $postscript
	close $file
	$graph configure -background $bg
	if {[winfo exist $graph.roi]} {
		set cela [format "%s%s" $cela "roi"]
		set postscript [$graph.roi postscript -rotate $landscape]
		set postscript [RemovePostScriptButton $postscript $graph.roi.hide]
		set postscript [RemovePostScriptButton $postscript $graph.roi.left]
		set postscript [RemovePostScriptButton $postscript $graph.roi.right]
		set file [open $cela.eps w]
		puts $file $postscript
		close $file
	}
}

itcl::body Display1D::Print {width height} {
	global spectk postscriptfunctions
	set bg [$graph cget -background]
	$graph configure -background lightgray
	set savewidth [$parent cget -width]
	set saveheight [$parent cget -height]
	$parent configure -width $width -height $height
	Resize
	if {[winfo exist $graph.roi]} {
		foreach i [$graph.roi find all] {
			if {[string equal [$graph.roi type $i] text]} {$graph.roi itemconfigure $i -fill lightgray}
		}
		update
		set gpost [$graph postscript output -width $width -height $height]
		set gpost [RemovePostScriptMarker $gpost marker1]
		set gpost [RemovePostScriptMarker $gpost marker2]
#		set gpost [RemovePostScriptMarker $gpost roidisplay]
		foreach i [$graph.roi find all] {
			if {[string equal [$graph.roi type $i] text]} {$graph.roi itemconfigure $i -fill black}
		}
		update
		set i [string first BoundingBox: $gpost]
		set gbound [string range $gpost [expr $i+13] [expr $i+27]]
		set gwidth [expr [lindex $gbound 2] - [lindex $gbound 0] + 1]
		set gheight [expr [lindex $gbound 3] - [lindex $gbound 1] + 1]
		set postscript "%!PS-Adobe-3.0 EPSF-3.0\n"
		append postscript "%%BoundingBox: $gbound\n"
		append postscript "%%EndComments\n"
		append postscript "%%BeginProlog\n"
		append postscript $postscriptfunctions
		append postscript "%%EndProlog\n"
		append postscript "BeginEPSF\n"
		append postscript "%%BeginDocument\n"
		append postscript $gpost
		append postscript "%%EndDocument\n"
		append postscript "EndEPSF\n"
		set rpost [$graph.roi postscript]
		set rpost [RemovePostScriptButton $rpost $graph.roi.hide]
		set rpost [RemovePostScriptButton $rpost $graph.roi.left]
		set rpost [RemovePostScriptButton $rpost $graph.roi.right]
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
	} else {
		set postscript [$graph postscript output -width $width -height $height]
		set postscript [RemovePostScriptMarker $postscript marker1]
		set postscript [RemovePostScriptMarker $postscript marker2]
	}
	$parent configure -width $savewidth -height $saveheight
	Resize
	$graph configure -background $bg
	return $postscript
}
