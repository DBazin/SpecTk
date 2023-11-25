itcl::class PageList {

	public variable pageList
	public variable newOrder
	public variable read

	constructor {} {
        	set pageList [list]
		set newOrder [list]
		set read 0
	}

	method getList {file}
	method readList {file}
	method writeList {file file2}
	method getPages {}
	method getPages2 {file}
	method clearList {}
	method clearList2 {}
	method reOrder {list}
	method addPage {page}
	method removePage {page}
	method alphaPage {}
	method checkList {list}
	method listName {}

}

itcl::body PageList::getList {file} {
	
	clearList	
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

	if {[string match "# pagelist*" $line2]} {
        	set listContent [string range $line2 11 end]
        	set pageList [split $listContent " "]
    	} else {
        	getList $file
    	}
	set read 1
}

itcl::body PageList::writeList {file file2} {
	
	if {$read == 0} {
		readList $file2
		puts $file "# pagelist [join $pageList { }]"
	} else {
	puts $file "# pagelist [join $pageList { }]"
	}
}

itcl::body PageList::clearList {} {

	set pageList [list]
}

itcl::body PageList::reOrder {list} {
	
	foreach i $list {
		lappend newOrder [lindex $pageList [expr $i-1]]
	}
	clearList
	foreach i $newOrder {
        	lappend pageList $i
	}
	set newOrder [list]
	
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
    	foreach item $sortedList {
        	lappend pageList [lindex $item 1]
    	}

}

itcl::body PageList::checkList {list} {
	foreach i $list {
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
	set nameList  [list]
	foreach p $pageList {
        	set name [$p getName]
        	lappend nameList [list $name]
	}
	return $nameList
}