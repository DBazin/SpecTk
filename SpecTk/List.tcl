itcl::class PageList {

	public variable pageList
	public variable newOrder
	public variable read
	public variable disabled
	public variable disableList
	public variable originalObjects
	public variable newObjects
	public variable appendedObjects
	public variable appended

	constructor {} {
        	set pageList [list]
		set newOrder [list]
		set disableList [list]
		set originalObjects [list]
		set newObjectsList [list]
		set appendedObjects [list]
		set read 0
		set disabled 0
		set appended 0
	}

	method getList {file}
	method readList {file}
	method appendList {file}
	method writeList {file file2}
	method getPages {}
	method getPages2 {file}
	method clearList {}
	method clearList2 {}
	method reorder {list}
	method addPage {page}
	method removePage {page}
	method alphaPage {}
	method checkList {list}
	method listName {}
	method disable {p}
	method disable+ {}
	method enable {p}
	method enable+ {}
	method reorderDisable {x}
	method disableCheck {}
	method flipDisabled {}
	method getDisabled {}
	method clearDisable {}
	method getObjects1 {}
	method getObjects2 {}
	method compareObjects {}
	method getMoreObjects {}
	method removeAppended {}
}

itcl::body PageList::getList {file} {
	
	set pageList [list]	
    	foreach p [itcl::find object -isa Page] {
        if {[string match "::*" $p]} {
            set pageName [string range $p 2 end]
        } else {
            set pageName $p
        }
        lappend pageList $pageName
    }

}

itcl::body PageList::readList {file} {
	clearList
    
	set line [gets $file]
	set line2 [gets $file]
	set line3 [gets $file]

	if {[string match "# pagelist*" $line2]} {
        	set listContent [string range $line2 11 end]
        	set pageList [split $listContent " "]
    	} else {
        	getList $file
    	}
	if {[string match "# disableList*" $line3]} {
		set listContent [string range $line3 14 end]
		set disableList [split $listContent " "] 
	}
	set read 1
	getObjects1
}

itcl::body PageList::appendList {file} {
    
	set line [gets $file]
	set line2 [gets $file]
	set line3 [gets $file]

	set holdList [list]

	if {[string match "# pagelist*" $line2]} {
        	set listContent [string range $line2 11 end]
        	set holdList [split $listContent " "]
		set pageList [concat $pageList $holdList]
    	} else {
        	getList $file
    	}
	if {[string match "# disableList*" $line3]} {
		set listContent [string range $line3 14 end]
		set holdList  [split $listContent " "] 
		set disableList [concat $disableList $holdList]
	}
	set read 1
}

itcl::body PageList::writeList {file file2} {
	
	if {$read == 0} {
		readList $file2
		puts $file "# pagelist [join $pageList { }]"
		puts $file "# disableList [join $disableList { }]"
	} else {
	puts $file "# pagelist [join $pageList { }]"
	puts $file "# disableList [join $disableList { }]"
	}
}

itcl::body PageList::clearList {} {
        set pageList [list]
	set newOrder [list]
	set disableList [list]
	set originalObjects [list]
	set newObjectsList [list]
	set difList [list]
	set appendedObjects [list]
	set read 0
	set disabled 0
	set appended 0
}

itcl::body PageList::reorder {list} {
	enable+
	set disableList [list]
	set j 0
	foreach i $list {
		lappend newOrder [list $i [lindex $pageList [expr $j]]]
		incr j
	}
	set sortedList [lsort -index 0 $newOrder]
	set pageList [list]
	foreach i $sortedList {
        	lappend pageList [lindex $i 1]
	}
	set newOrder [list]	

	foreach i $pageList {
		$i disableTab
	}

	foreach i $pageList {
		$i enableTab
	}
}

itcl::body PageList::getPages {} {

	return $pageList

}

itcl::body PageList::getPages2 {file} {
			
	if {[llength $pageList] == 0} {
        	readList $file
    	}

	return $pageList

}

itcl::body PageList::addPage {page} {

	lappend pageList $page

}

itcl::body PageList::removePage {page} {
	
	set index [lsearch $pageList $page]

	if {$index != -1} {
        	set pageList [lreplace $pageList $index $index]
	}

} 

itcl::body PageList::alphaPage {} {
	set nameList  [list]
	foreach p $pageList {
        	set name [$p getName]
        	lappend nameList [list $name $p]
	}
    
    	set sortedList [lsort -dictionary -index 0 $nameList]
    
    	set pageList [list]
    	foreach i $sortedList {
        	lappend pageList [lindex $i 1]
    	}

	foreach i $pageList {
		$i disableTab
	}

	foreach i $pageList {
		$i enableTab
	}

}

itcl::body PageList::checkList {list} {
	foreach i $list {
		if {$i eq "Disable"} {
			return 2
		}
		if {![string is integer -strict $i]} {
			tk_messageBox -title "Error" -message "A box was left empty." -icon error
			return 0
		}
	}

	if {[llength [lsort -unique $list]] != [llength $list]} {
		tk_messageBox -title "Error" -message "Two boxes have the same values." -icon error
		return 0
	}

	return 1
}

itcl::body PageList::listName {} {
	set nameList [list]
	foreach p $pageList {
        	set name [$p getName]
        	lappend nameList [list $name]
	}
	return $nameList
}

itcl::body PageList::disable {p} {
	$p disableTab
}

itcl::body PageList::enable {p} {
	$p enableTab
}

itcl::body PageList::reorderDisable {x} {
    	set i 0
	
	enable+
	set disableList [list]

	set intList [list]
    	set hold [list]

    	foreach p $pageList {
        	set y [lindex $x $i]
        	incr i
        	lappend disableList [list $y $p]
    	}

    	foreach i $disableList {
        	if {[lindex $i 0] eq "Disable"} {
            		lappend hold [lindex $i]
        	} else {
            		lappend intList [lindex $i]
        	}
    	}

	set intList [lsort -index 0 -integer $intList]
	set disableList [list]
	set pageList [list]

	foreach i $intList {
		lappend pageList [lindex $i 1]
	}
	foreach i $hold {
		lappend pageList [lindex $i 1]
		lappend disableList [lindex $i 1]
	}
	foreach i $pageList {
		$i disableTab
	}

	foreach i $pageList {
		$i enableTab
	}
	disable+
	set disabled 1
}

itcl::body PageList::disableCheck {} {
	return $disabled
}

itcl::body PageList::getDisabled {} {
	return $disableList
}

itcl::body PageList::flipDisabled {} {
	if {$disabled == 0} {
		set disabled 1
	} else {
		set disabled 0
	}
}

itcl::body PageList::disable+ {} {
	if {$disabled == 0} {
		foreach p $disableList {
			disable $p
		}
		set disabled 1
	}
}

itcl::body PageList::enable+ {} {
	if {$disabled == 1} {
		foreach p $disableList {
			enable $p
		}
		set disabled 0
	}
}

itcl::body PageList::clearDisable {} {
	set disableList [list]
}

itcl::body PageList::getObjects1 {} {
	foreach p [itcl::find object -isa Page] {lappend originalObjects $p}
	foreach d [itcl::find object -isa Display1D] {lappend originalObjects $d}
	foreach d [itcl::find object -isa Display2D] {lappend originalObjects $d}
	foreach w [itcl::find object -isa Wave1D] {lappend originalObjects $w}
	foreach w [itcl::find object -isa Wave2D] {lappend originalObjects $w}
	foreach r [itcl::find object -isa ROI] {lappend originalObjects $r}
}

itcl::body PageList::getObjects2 {} {
	foreach p [itcl::find object -isa Page] {lappend newObjects $p}
	foreach d [itcl::find object -isa Display1D] {lappend newObjects $d}
	foreach d [itcl::find object -isa Display2D] {lappend newObjects $d}
	foreach w [itcl::find object -isa Wave1D] {lappend newObjects $w}
	foreach w [itcl::find object -isa Wave2D] {lappend newObjects $w}
	foreach r [itcl::find object -isa ROI] {lappend newObjects $r}
}

itcl::body PageList::compareObjects {} {
	getObjects2
	set appended 1
	foreach o $newObjects {
		if {$o ni $originalObjects  && $o ni $appendedObjects} {
			lappend appendedObjects $o
		}
	}
	puts "$appendedObjects"
}

itcl::body PageList::getMoreObjects {} {
	if {$appended == 1} {
		getObjects2
		foreach o $newObjects {
			if {$o ni $originalObjects && $o ni $appendedObjects} {
				lappend orgList $o
			}
		}
	}
	puts "$appendedObjects"
}

itcl::body PageList::removeAppended {} {

	foreach p [itcl::find object -isa Page] {
		set pageName [string map {:: ""} $p]
		if {[lsearch $appendedObjects $p] != -1} {
			puts "page: $p"
			itcl::delete object $p
			set index [lsearch $pageList $pageName]
			if {$index != -1} {
				set pageList [lreplace $pageList $index $index]
			}
			puts "$pageList"
		}
	}

	foreach d [itcl::find object -isa Display1D] {
		if {[lsearch $appendedObjects $d] != -1} {
			itcl::delete object $d
    		}
	}

	foreach d [itcl::find object -isa Display2D] {
		if {[lsearch $appendedObjects $d] != -1} {
			itcl::delete object $d
		}
	}

	foreach w [itcl::find object -isa Wave1D] {
		if {[lsearch $appendedObjects $w] != -1} {
			itcl::delete object $w
		}
	}

	foreach w [itcl::find object -isa Wave2D] {
		if {[lsearch $appendedObjects $w] != -1} {
			itcl::delete object $w
		}
	}

	foreach r [itcl::find object -isa ROI] {
		if {[lsearch $appendedObjects $r] != -1} {
			itcl::delete object $r
		}
	}

	set appendedObjects [list]
	set appended 0
}