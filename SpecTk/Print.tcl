# 12/12/09: Changed printing to PDF files instead of EPS, using epstopdf which should be available
# 12/13/09: Added procs to implement direct Print buttons

proc CreatePrintDialog {} {
	global spectk
	set tab [$spectk(pages) id select]
	if {[string equal $tab ""]} {return}
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split $frame .] end]
	set spectk(printpage) $page
	set current [$page GetMember current]
	set display [format %s%s $page $current]
	set spectk(printdisplay) $display
	set graph [$display GetMember graph]
	set title [$graph cget -title]

	set w .spectkprint
	toplevel $w
	wm title $w "SpecTk Print Dialog"

	set w .spectkprint.choice
	frame $w -borderwidth 2 -relief groove
	radiobutton $w.page -text "Print Page:" -variable spectk(printchoice) \
	-value page -font general -anchor w -command PrintDialogUpdate
	label $w.pagename -text $page -font "generalbold" -anchor w
	radiobutton $w.graph -text "Print Graph:" -variable spectk(printchoice) \
	-value graph -font general -anchor w -command PrintDialogUpdate
	label $w.graphname -text $title -font "generalbold" -anchor w
	grid $w.page $w.pagename $w.graph $w.graphname -sticky news
	grid columnconfigure $w 0 -weight 1
	grid columnconfigure $w 1 -weight 1
	grid columnconfigure $w 2 -weight 1
	grid columnconfigure $w 3 -weight 1
	pack $w -expand 1 -fill both -pady 5

	set w .spectkprint.orient
	frame $w -borderwidth 2 -relief groove
	radiobutton $w.portrait -text "Portrait" -variable spectk(printorient) \
	-value 0 -font general -anchor w -command PrintDialogUpdate
	radiobutton $w.landscape -text "Landscape" -variable spectk(printorient) \
	-value 1 -font general -anchor w -command PrintDialogUpdate
	grid $w.portrait $w.landscape -sticky news
	grid columnconfigure $w 0 -weight 1
	grid columnconfigure $w 1 -weight 1
	pack $w -expand 1 -fill both -pady 5
	
	set w .spectkprint.scale
	frame $w -borderwidth 2 -relief groove
	radiobutton $w.fill -text "Fill Page" -variable spectk(printscale) \
	-value fill -font general -anchor w -command PrintDialogUpdate
	radiobutton $w.custom -text "Custom Size" -variable spectk(printscale) \
	-value custom -font general -anchor w -command PrintDialogUpdate
	radiobutton $w.same -text "Same Size" -variable spectk(printscale) \
	-value same -font general -anchor w -command PrintDialogUpdate
	radiobutton $w.aspect -text "Fit Page" -variable spectk(printscale) \
	-value aspect -font general -anchor w -command PrintDialogUpdate
	label $w.widthlabel -text "Width:" -font general -anchor w
	entry $w.width -textvariable spectk(printwidthin) -width 5 -background white
	label $w.widthunit -text "in" -font general -anchor w
	label $w.heightlabel -text "Height:" -font general -anchor w
	entry $w.height -textvariable spectk(printheightin) -width 5 -background white
	label $w.heightunit -text "in" -font general -anchor w
	grid $w.fill $w.custom $w.widthlabel $w.width $w.widthunit -sticky news
	grid $w.same $w.aspect $w.heightlabel $w.height $w.heightunit -sticky news
	grid columnconfigure $w 0 -weight 1
	grid columnconfigure $w 1 -weight 1
	grid columnconfigure $w 2 -weight 1
	grid columnconfigure $w 3 -weight 1
	grid columnconfigure $w 4 -weight 1
	pack $w -expand 1 -fill both -pady 5
	
	set w .spectkprint.include
	frame $w -borderwidth 2 -relief groove
	checkbutton $w.stamp -text "Include Time Stamp" -anchor w -variable spectk(printstamp) \
	-font "general"
#	checkbutton $w.roi -text "Include ROI Results" -anchor w -variable spectk(printroi) \
#	-font "general"
#	checkbutton $w.fit -text "Include Fit Results" -anchor w -variable spectk(printfit) \
#	-font "general"
	grid $w.stamp -sticky news
	grid columnconfigure $w 0 -weight 1
#	grid columnconfigure $w 1 -weight 1
#	grid columnconfigure $w 2 -weight 1
	pack $w -expand 1 -fill both -pady 5

	set w .spectkprint.command
	frame $w -borderwidth 2 -relief groove
	label $w.label -text "Print Command:" -font general -anchor w
	entry $w.command -textvariable spectk(printcommand) -width 20 \
	-background white
	grid $w.label $w.command -sticky news
	grid columnconfigure $w 0 -weight 1
	grid columnconfigure $w 1 -weight 1
	pack $w -expand 1 -fill both -pady 5
	
	set w .spectkprint.buttons
	frame $w -borderwidth 2 -relief groove
	button $w.save -text "Save As PDF..." -font general -command PrintDialogSaveAsPDF -width 12
	button $w.cancel -text "Cancel" -font general -command PrintDialogCancel -width 5
	button $w.preview -text "Preview" -font general -command PrintDialogPreview -width 8
	button $w.print -text "Print" -font general -command PrintDialogPrint -width 5
	grid $w.save $w.cancel $w.preview $w.print
	grid columnconfigure $w 0 -weight 1
	grid columnconfigure $w 1 -weight 1
	grid columnconfigure $w 2 -weight 1
	grid columnconfigure $w 3 -weight 1
	pack $w -expand 1 -fill both -pady 5
	
	PrintDialogUpdate
}

proc PrintDialogUpdate {} {
	global spectk
	if {[string equal $spectk(printchoice) graph]} {
		set width [[$spectk(printdisplay) GetMember graph] cget -width]
		set height [[$spectk(printdisplay) GetMember graph] cget -height]
	} else {
		set width [[$spectk(printpage) GetMember frame] cget -width]
		set height [[$spectk(printpage) GetMember frame] cget -height]
	}
	set w .spectkprint.scale
	switch -- $spectk(printscale) {
		fill {
			set spectk(printwidthin) 8.0
			set spectk(printheightin) 10.5
			$w.width configure -state disable
			$w.height configure -state disable
		}
		custom {
			$w.width configure -state normal
			$w.height configure -state normal
		}
		same {
			set spectk(printwidthin) [format %.1f [expr 1.0*$width/72]]
			set spectk(printheightin) [format %.1f [expr 1.0*$height/72]]
			if {$spectk(printorient)} {
				set temp $spectk(printwidthin)
				set spectk(printwidthin) $spectk(printheightin)
				set spectk(printheightin) $temp
			}
			$w.width configure -state disable
			$w.height configure -state disable
		}
		aspect {
			if {$spectk(printorient)} {
				if {1.0*$width/$height*8.0 > 10.5} {
					set spectk(printwidthin) [format %.1f [expr 1.0*$height/$width*10.5]]
					set spectk(printheightin) 10.5
				} else {
					set spectk(printwidthin) 8.0
					set spectk(printheightin) [format %.1f [expr 1.0*$width/$height*8.0]]
				}
			} else {
				if {1.0*$height/$width*8.0 > 10.5} {
					set spectk(printwidthin) [format %.1f [expr 1.0*$width/$height*10.5]]
					set spectk(printheightin) 10.5
				} else {
					set spectk(printwidthin) 8.0
					set spectk(printheightin) [format %.1f [expr 1.0*$height/$width*8.0]]
				}
			}
			$w.width configure -state disable
			$w.height configure -state disable
		}
	}
}

proc PrintDialogCancel {} {
	PrintDialogDeleteFiles
	destroy .spectkprint
	if {[winfo exist .spectkpreview]} {destroy .spectkpreview}
}

proc PrintDialogPreview {} {
	global spectk
# If preview window doesn't exist create it
	if {![winfo exist .spectkpreview]} {
		toplevel .spectkpreview
		wm title .spectkpreview "SpecTk Print Preview"
		set c .spectkpreview.preview
		canvas $c -width [expr int(8.5*72/2)] -height [expr int(11*72/2)] -bg white
		set w .spectkpreview.buttons
		frame $w -borderwidth 2 -relief groove
		button $w.save -text "Save As PDF..." -font general -command PrintDialogSaveAsPDF -width 12
		button $w.cancel -text "Cancel" -font general -command "destroy .spectkpreview" -width 5
		button $w.print -text "Print" -font general -command PrintDialogPrint -width 5
		grid $w.save $w.cancel $w.print
		grid columnconfigure $w 0 -weight 1
		grid columnconfigure $w 1 -weight 1
		grid columnconfigure $w 2 -weight 1
		pack $w -expand 1 -fill both -pady 5
		pack $c
# Else update the canvas
	} else {
		set c .spectkpreview.preview
		destroy $c
		canvas $c -width [expr int(8.5*36)] -height [expr int(11*36)] -bg white
		pack $c
	}
	PrintDialogProcessPrint $c
}

proc PrintDialogProcessPrint {c} {
	global spectk RunNumber RunTitle
# Info string
	if {![info exist RunNumber]} {set RunNumber 0}
	if {![info exist RunTitle]} {set RunTitle unknown}
	set strinfo "[clock format [clock second]]	Run: $RunNumber	Title: $RunTitle"
# Display print
	if {[string equal $spectk(printchoice) graph]} {
		$spectk(printdisplay) PostScript $spectk(printorient)
		set dx [expr int((4.25-$spectk(printwidthin)/2)*36)]
		set dy [expr int((5.5-$spectk(printheightin)/2)*36)]
		set dw [expr int($spectk(printwidthin)*36)]
		set dh [expr int($spectk(printheightin)*36)]
		if {$spectk(printstamp)} {
			set is 24
			set iw [font measure [format "Times -%d" $is] $strinfo]
			while {$iw > $spectk(printwidthin)*36} {
				incr is -1
				set iw [font measure [format "Times -%d" $is] $strinfo]
			}
			$c create text $dx $dy -text $strinfo -font [format "Times -%d" $is] -anchor sw -tags info
		}
		$c create eps $dx $dy -file $spectk(printdisplay).eps -width $dw -height $dh -anchor nw
# If 2D display add the color scale
		if {[$spectk(printdisplay) isa Display2D]} {
			set name [format "%s%s" $spectk(printdisplay) scale]
			set graph [$spectk(printdisplay) GetMember graph]
			set scalew [$graph.scale cget -width]
			set scaleh [$graph.scale cget -height]
			set disw [$graph cget -width]
			set dish [$graph cget -height]
			set scalex [winfo x $graph.scale]
			set scaley [winfo y $graph.scale]
			if {$spectk(printorient)} {
				set sw [expr int(1.0*$scaleh/$dish*$dw)]
				set sh [expr int(1.0*$scalew/$disw*$dh)]
				set sx [expr $dx+3+int(1.0*$scaley/$dish*$dw)]
				set sy [expr $dy+int(1.0*($disw-$scalex-$scalew)/$disw*$dh)]
			} else {
				set sw [expr int(1.0*$scalew/$disw*$dw)]
				set sh [expr int(1.0*$scaleh/$dish*$dh)]
				set sx [expr $dx+3+int(1.0*$scalex/$disw*$dw)]
				set sy [expr $dy+3+int(1.0*$scaley/$dish*$dh)]
			}
			$c create eps $sx $sy -file $name.eps -width $sw -height $sh -anchor nw
		}

# Page print
	} else {
		$spectk(printpage) PostScript $spectk(printorient)
		set rows [$spectk(printpage) GetMember rows]
		set columns [$spectk(printpage) GetMember columns]
		if {$spectk(printorient)} {
			set dw [expr int($spectk(printwidthin)*36/$rows)]
			set dh [expr int($spectk(printheightin)*36/$columns)]
		} else {
			set dw [expr int($spectk(printwidthin)*36/$columns)]
			set dh [expr int($spectk(printheightin)*36/$rows)]
		}
		if {$spectk(printstamp)} {$c create text 9 9 -text $strinfo \
		-font "graphlabels" -anchor sw}
		for {set ir 0} {$ir < $rows} {incr ir} {
			for {set ic 0} {$ic < $columns} {incr ic} {
				if {$spectk(printorient)} {
					set dx [expr $ir*$dw + 9]
					set dy [expr ($columns-$ic-1)*$dh + 9]
				} else {
					set dx [expr $ic*$dw + 9]
					set dy [expr $ir*$dh + 9]
				}
				set display [format "%sR%dC%d" $spectk(printpage) $ir $ic]
				set id [format "R%dC%d" $ir $ic]
				if {![catch "$spectk(printpage) GetMember Display($id)"]} {
					$c create eps $dx $dy -file $display.eps -width $dw -height $dh -anchor nw
# If 2D display add the color scale
					if {[$display isa Display2D]} {
						set name [format "%s%s" $display scale]
						set graph [$display GetMember graph]
						set scalew [$graph.scale cget -width]
						set scaleh [$graph.scale cget -height]
						set disw [$graph cget -width]
						set dish [$graph cget -height]
						set scalex [winfo x $graph.scale]
						set scaley [winfo y $graph.scale]
						if {$spectk(printorient)} {
							set sw [expr int(1.0*$scaleh/$dish*$dw)]
							set sh [expr int(1.0*$scalew/$disw*$dh)]
							set sx [expr $dx+3+int(1.0*$scaley/$dish*$dw)]
							set sy [expr $dy+int(1.0*($disw-$scalex-$scalew)/$disw*$dh)]
						} else {
							set sw [expr int(1.0*$scalew/$disw*$dw)]
							set sh [expr int(1.0*$scaleh/$dish*$dh)]
							set sx [expr $dx+3+int(1.0*$scalex/$disw*$dw)]
							set sy [expr $dy+3+int(1.0*$scaley/$dish*$dh)]
						}
						$c create eps $sx $sy -file $name.eps -width $sw -height $sh -anchor nw
					}
				}
			}
		}
	}
	set spectk(printcanvas) $c
}

proc PrintDialogSave {} {
	global spectk
	if {![info exist spectk(printdir)]} {set spectk(printdir) ""}
	if {[string equal $spectk(printchoice) graph]} {
		set graph [$spectk(printdisplay) GetMember graph]
		set name [lindex [split [$graph cget -title] " "] 0]
		set initialfile [format "%s%s" $name .eps]
	} else {
		set initialfile [format "%s%s" $spectk(printpage) .eps]
	}
	set file [tk_getSaveFile -title "Enter a file name" \
	-defaultextension .eps \
	-filetypes {{"Encapsulated PostScript File" {.eps}}} \
	-initialdir $spectk(printdir) \
	-initialfile $initialfile]
	if {[string equal $file ""]} {return}
	set f [lindex [split $file /] end]
	set spectk(printdir) [string trimright $file $f]
	if {![winfo exist .spectkpreview]} {
#		set c $spectk(toplevel).preview
		toplevel .print
		set c .print.preview
		canvas $c -width [expr int(8.5*72/2)] -height [expr int(11*72/2)] -bg white
		pack $c
		PrintDialogProcessPrint $c
		update
		$spectk(printcanvas) postscript -file $file -pagewidth 8.5i
		destroy .print
	} else {
		$spectk(printcanvas) postscript -file $file -pagewidth 8.5i
	}
	PrintDialogCancel
}

proc PrintDialogSaveAsPDF {} {
	global spectk
	if {![info exist spectk(printdir)]} {set spectk(printdir) ""}
	if {[string equal $spectk(printchoice) graph]} {
		set graph [$spectk(printdisplay) GetMember graph]
		set name [lindex [split [$graph cget -title] " "] 0]
		set initialfile [format "%s%s" $name .pdf]
	} else {
		set initialfile [format "%s%s" $spectk(printpage) .pdf]
	}
	set file [tk_getSaveFile -title "Enter a file name" \
	-defaultextension .pdf \
	-filetypes {{"Portable Document Format" {.pdf}}} \
	-initialdir $spectk(printdir) \
	-initialfile $initialfile]
	if {[string equal $file ""]} {return}
	set f [lindex [split $file /] end]
	set spectk(printdir) [string trimright $file $f]
	if {![winfo exist .spectkpreview]} {
#		set c $spectk(toplevel).preview
		toplevel .print
		set c .print.preview
		canvas $c -width [expr int(8.5*72/2)] -height [expr int(11*72/2)] -bg white
		pack $c
		PrintDialogProcessPrint $c
		update
		set epsfile [string trimright $file ".pdf"]
		append epsfile ".eps"
		$spectk(printcanvas) postscript -file $epsfile -pagewidth 8.5i
		set command "exec epstopdf $epsfile"
		eval $command
		file delete $epsfile
		destroy .print
	} else {
		set epsfile [string trimright $file ".pdf"]
		append epsfile ".eps"
		$spectk(printcanvas) postscript -file $file -pagewidth 8.5i
		set command "exec epstopdf $epsfile"
		eval $command
		file delete $epsfile
	}
	PrintDialogCancel
}

proc PrintDialogPrint {} {
	global spectk
	if {![winfo exist .spectkpreview]} {
#		set c $spectk(toplevel).preview
		toplevel .print
		set c .print.preview
		canvas $c -width [expr int(8.5*72/2)] -height [expr int(11*72/2)] -bg white
		pack $c
		PrintDialogProcessPrint $c
		update
		$spectk(printcanvas) postscript -file print.eps -pagewidth 8.5i
		set command "exec epstopdf print.eps"
		eval $command
		file delete print.eps
		destroy .print
	} else {
		$spectk(printcanvas) postscript -file print.eps -pagewidth 8.5i
		set command "exec epstopdf print.eps"
		eval $command
		file delete print.eps
	}
	set command exec
	for {set i 0} {$i < [llength $spectk(printcommand)]} {incr i} {
		append command " [lindex $spectk(printcommand) $i]"
	}
	append command " print.pdf &"
	eval $command
	PrintDialogCancel
}

proc PrintDisplayButton {} {
	global spectk
	set spectk(printchoice) graph
	PrintDialogPrint
}

proc PrintPageButton {} {
	global spectk
	set spectk(printchoice) page
	PrintDialogPrint
}

proc PrintDialogDeleteFiles {} {
	global spectk
	if {[string equal $spectk(printchoice) graph]} {
		if {[file exist $spectk(printdisplay)]} {file delete $spectk(printdisplay)}
		set name [format "%s%s" $spectk(printdisplay) scale]
		if {[file exist $name.eps]} {file delete $name.eps}
		set name [format "%s%s" $spectk(printdisplay) roi]
		if {[file exist $name.eps]} {file delete $name.eps}
	} else {
		set rows [$spectk(printpage) GetMember rows]
		set columns [$spectk(printpage) GetMember columns]
		for {set ir 0} {$ir < $rows} {incr ir} {
			for {set ic 0} {$ic < $columns} {incr ic} {
				set prefix [format "%sR%dC%d" $spectk(printpage) $ir $ic]
			if {[file exist $prefix.eps]} {file delete $prefix.eps}
				set name [format "%s%s" $prefix scale]
				if {[file exist $name.eps]} {file delete $name.eps}
				set name [format "%s%s" $prefix roi]
				if {[file exist $name.eps]} {file delete $name.eps}
			}
		}
	}
}

proc RemovePostScriptMarker {postscript marker} {
	set ib [string first "% Marker \"$marker\" is a WindowMarker marker" $postscript]
	set ie [string first "grestore" $postscript $ib]
	set ie [expr $ie+9]
	return [string replace $postscript $ib $ie]
}

proc RemovePostScriptButton {postscript pathname} {
	set ib [string first "%% Button item ($pathname" $postscript]
	set ie [string first "gsave" $postscript $ib]
	set ie [expr $ie+5]
	return [string replace $postscript $ib $ie]
}

proc InsertPostScriptFunctions {postscript} {
	global postscriptfunctions
	set ib [string first "%%EndProlog" $postscript]
	return [string replace $postscript [expr $ib-1] [expr $ib-1] $postscriptfunctions]
}