proc CreateGeometryDialog {} {
	global spectk
	set w $spectk(drawer).pages.geometry
	set spectk(pageName) page1
	set spectk(pageRows) 2
	set spectk(pageColumns) 2
	set name $spectk(pageName)
	set rows $spectk(pageRows)
	set columns $spectk(pageColumns)
	set spectk(pageGeometry) [format "%d rows by %d columns" $rows $columns]
	image create bitmap blank -data "
	#define blank_width 2\n
	#define blank_height 2\n
	static unsigned char blank_bits\[\] = {\n
	0x00, 0x00};"

	set w $w.top
	frame $w
	label $w.namelabel -text Name: -font generalbold
	entry $w.name -textvariable spectk(pageName) -width 10 -background white -font general
	label $w.geometrylabel -text "Selected geometry:" -font generalbold
	label $w.geometry -textvariable spectk(pageGeometry) -font general
	grid $w.namelabel $w.name -sticky news
	grid $w.geometrylabel - -sticky news
	grid $w.geometry - -sticky news
	pack $w

	set w $spectk(drawer).pages.geometry.grid
	frame $w
	label $w.display -textvariable spectk(pageInfo)
	for {set r 1} {$r <= 10} {incr r} {
		for {set c 1} {$c <= 10} {incr c} {
			set id [format "%dRx%dC" $r $c]
			button $w.button$id -image blank -width 8 -height 8 \
			-activebackground lightgreen -borderwidth 2 -padx 0 -pady 0 \
			-command "SelectMagicButtons $w $r $c"
			bind $w.button$id <Enter> "SetMagicButtons $w $r $c"
			bind $w.button$id <Leave> "SetMagicButtons $w 0 0"
			grid $w.button$id -row $r -column $c
		}
	}
	grid $w.display -columnspan 10
	pack $w
	
	set w $spectk(drawer).pages.geometry.bottom
	frame $w
	button $w.create -text Create -width 5 -command CreateNewPage -font general
	button $w.modify -text Modify -width 5 -command ModifyPage -font general
	button $w.delete -text Delete -width 5 -command DeletePage -font general
	grid $w.create $w.modify $w.delete -sticky news
	pack $w -side top -anchor n
}

proc SetMagicButtons {w r c} {
	global spectk
	if {[info exist spectk(pageRows)]} {
		set sr $spectk(pageRows)
		set sc $spectk(pageColumns)
	} else {
		set sr 0
		set sc 0
	}
	if {$r != 0} {
		set spectk(pageInfo) [format "%d rows by %d columns" $r $c]
	} else {
		set spectk(pageInfo) [format "%d rows by %d columns" $sr $sc]
	}
	for {set ir 1} {$ir <= 10} {incr ir} {
		for {set ic 1} {$ic <= 10} {incr ic} {
			set id [format "%dRx%dC" $ir $ic]
			if {$ir <= $r && $ic <= $c} {
				$w.button$id configure -background lightgreen
			} elseif {$ir <= $sr && $ic <= $sc} {
				$w.button$id configure -background green
			} elseif {$ir > [expr max($r,$sr)] || $ic > [expr max($c,$sc)]} {
				$w.button$id configure -background lightgray
			}
		}
	}
}

proc SelectMagicButtons {w r c} {
	global spectk
	set spectk(pageGeometry) [format "%d rows by %d columns" $r $c]
	set spectk(pageRows) $r
	set spectk(pageColumns) $c
	for {set ir 1} {$ir <= 10} {incr ir} {
		for {set ic 1} {$ic <= 10} {incr ic} {
			set id [format "%dRx%dC" $ir $ic]
			if {$ir <= $r && $ic <= $c} {
				$w.button$id configure -background green
			} else {
				$w.button$id configure -background lightgray
			}
		}
	}
}

proc CreateNewPage {} {
	global spectk
	global List

	set pName $spectk(pageName)
	set lowerName [string tolower $pName]
	set spectk(pageName) $lowerName

# if the page already exists we need to find a new name for it
	if {[lsearch [itcl::find objects -isa Page] $spectk(pageName)] != -1} {
		set i 1
		while {[lsearch [itcl::find objects -isa Page] page$i] != -1} {incr i}
		set spectk(pageName) page$i
	}
	Page $spectk(pageName) $spectk(pages) $spectk(pageRows) $spectk(pageColumns)
	$List addPage $spectk(pageName)
	$spectk(pageName) Resize
	$spectk(tools).select select
	$spectk(tools).select invoke
	$spectk(pageName) SelectDisplay R0C0 1

	if {$pName ne $lowerName} {
		$lowerName Modify $pName $spectk(pageRows) $spectk(pageColumns)
        }
}

proc ModifyPage {} {
	global spectk
	set tab [$spectk(pages) id select]
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split $frame .] end]
	$page Modify $spectk(pageName) $spectk(pageRows) $spectk(pageColumns)
	$page Resize
	$spectk(tools).select select
	$spectk(tools).select invoke
	$page SelectDisplay R0C0 1
}

proc DeletePage {} {
	global spectk
	global List
	set tab [$spectk(pages) id select]
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split $frame .] end]
	$List removePage $page
#	$spectk(pages) delete $tab
#	destroy $frame
	itcl::delete object $page
}

proc UpdateGeometryDialog {} {
	global spectk
	set tab [$spectk(pages) id select]
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split $frame .] end]
	set spectk(pageName) [$spectk(pages) tab cget $tab -text]
	set spectk(pageRows) [$page GetMember rows]
	set spectk(pageColumns) [$page GetMember columns]
	set w $spectk(drawer).pages.geometry.grid
	SelectMagicButtons $w $spectk(pageRows) $spectk(pageColumns)
}