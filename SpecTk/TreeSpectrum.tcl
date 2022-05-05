proc UpdateTreeSpectrum {split} {
	global spectk
	global treeSpectrumRoot treeSpectrumName treeSpectrumSeparator
	global treeSpectrumNom treeSpectrumType treeSpectrumX treeSpectrumY treeSpectrumGate
	if {[info exist treeSpectrumRoot]} {
		unset treeSpectrumRoot treeSpectrumName treeSpectrumSeparator
		unset treeSpectrumNom treeSpectrumType treeSpectrumX treeSpectrumY treeSpectrumGate
	}
	set theList [spectrum -list]
	foreach s $theList {
		set theName [lindex $s 1]
		set theGate [lindex [lindex [apply -list $theName] 0] 1]
		if {[string equal [lindex $theGate 2] T]} {
			set theGate True
		} elseif {[string equal [lindex $theGate 2] F]} {
			set theGate False
		} else {
			set theGate [lindex $theGate 0]
		}
		set theType [lindex $s 2]
		set theParameters [lindex $s 3]
		set thePath [split $theName $split]
# Get rid of empty slots created by repetition of split characters
		while {[set i [lsearch $thePath ""]] != -1} {
			set thePath [lreplace $thePath $i $i]
		}
		set theLength [llength $thePath]
		set rootName [lindex $thePath 0]
# Add spectrum root name if it hasn't been registered yet
		if {[info exist treeSpectrumRoot]} {
			if {[lsearch $treeSpectrumRoot $rootName] == -1} {
				append treeSpectrumRoot "$rootName "
				append treeSpectrumName(root) "$rootName "
			}
		} else {
			set treeSpectrumRoot "$rootName "
			set treeSpectrumName(root) "$rootName "
		}
		set Name ""
# Fill name array
		for {set i 0} {$i < [expr $theLength-1]} {incr i} {
# Find separator
			set element [lindex $thePath $i]
			set index [expr [string first $element $theName] + [string length $element]]
			set separator [string range $theName $index $index]
			if {$i > 0} {append Name ,}
			append Name [lindex $thePath $i]
			set subName [lindex $thePath [expr $i+1]]
			if {[info exist treeSpectrumName($Name)]} {
				if {[set Index [lsearch $treeSpectrumName($Name) $subName]] == -1} {
					append treeSpectrumName($Name) "$subName "
					append treeSpectrumSeparator($Name) "$separator "
				}
			} else {
				set treeSpectrumName($Name) "$subName "
				set treeSpectrumSeparator($Name) "$separator "
			}
		}
# Fill last path entry with spectrum info
		if {$theLength == 1} {
			set Name $rootName
		} else {
			set Name $Name,$subName
		}
		set treeSpectrumNom($Name) $theName
		set treeSpectrumType($Name) $theType
		set treeSpectrumX($Name) [lindex $theParameters 0]
		set treeSpectrumY($Name) [lindex $theParameters 1]
		set treeSpectrumGate($Name) $theGate
	}
}

proc UpdateTreeSpectrumMatch {split type units} {
	global treeSpectrumRoot treeSpectrumName treeSpectrumSeparator
	if {[info exist treeSpectrumRoot]} {unset treeSpectrumRoot}
	if {[info exist treeSpectrumName]} {unset treeSpectrumName}
	if {[info exist treeSpectrumSeparator]} {unset treeSpectrumSeparator}
	set theList [spectrum -list]
	foreach s $theList {
		set theName [lindex $s 1]
		set theType [lindex $s 2]
		if {[string equal $theType b]} {set theType 1}
		if {[string equal $theType g1]} {set theType 1}
		if {[string equal $theType s]} {set theType 2}
		if {[string equal $theType g2]} {set theType 2}
# if different type go to next spectrum
		if {$theType != $type} {continue}
		set theParameters [lindex $s 3]
# if different unit(s) go to next spectrum
		if {$type == 1} {
			set unit [lindex $units 0]
			set l [parameter -list [lindex $theParameters 0]]
			set r [lindex $l 3]
			set theUnit [lindex $r 2]
			if {![string equal $theUnit $unit]} {continue}
		}
		if {$type == 2} {
			set unitx [lindex $units 0]
			set unity [lindex $units 1]
			set l [parameter -list [lindex $theParameters 0]]
			set r [lindex $l 3]
			set theUnitx [lindex $r 2]
			set l [parameter -list [lindex $theParameters 1]]
			set r [lindex $l 3]
			set theUnity [lindex $r 2]
			if {![string equal $theUnitx $unitx] || ![string equal $theUnity $unity]} {continue}
		}
		set thePath [split $theName $split]
# Get rid of empty slots created by repetition of split characters
		while {[set i [lsearch $thePath ""]] != -1} {
			set thePath [lreplace $thePath $i $i]
		}
		set theLength [llength $thePath]
		set rootName [lindex $thePath 0]
# Add spectrum root name if it hasn't been registered yet
		if {[info exist treeSpectrumRoot]} {
			if {[lsearch $treeSpectrumRoot $rootName] == -1} {
				append treeSpectrumRoot "$rootName "
				append treeSpectrumName(root) "$rootName "
			}
		} else {
			set treeSpectrumRoot "$rootName "
			set treeSpectrumName(root) "$rootName "
		}
# Fill name array
		for {set i 0} {$i < [expr $theLength-1]} {incr i} {
# Find separator
			set element [lindex $thePath $i]
			set index [expr [string first $element $theName] + [string length $element]]
			set separator [string range $theName $index $index]
			set Name ""
			for {set j 0} {$j <= $i} {incr j} {
				append Name [lindex $thePath $j] ,
			}
			set Name [string trimright $Name ,]
			set subName [lindex $thePath [expr $i+1]]
			if {[info exist treeSpectrumName($Name)]} {
				if {[set Index [lsearch $treeSpectrumName($Name) $subName]] == -1} {
					append treeSpectrumName($Name) "$subName "
					append treeSpectrumSeparator($Name) "$separator "
				}
			} else {
				set treeSpectrumName($Name) "$subName "
				set treeSpectrumSeparator($Name) "$separator "
			}
		}
	}
}

### Tree generation ###

proc TreeSpectrum {parent} {
	global spectk
	global treeSpectrumNom treeSpectrumType treeSpectrumX treeSpectrumY treeSpectrumGate
	set t $parent.tree
	if {![winfo exist $t]} {
		blt::treeview $t -autocreate yes -font "tree" -activeicons "Node Node" -icons "Node Node"
		$t button configure -images "Close Open"
		$t configure -width 150 -height 1000 -selectmode single
		bind $t <Motion> "set spectk(disablemouse) 0"
		if {[info exist treeSpectrumNom]} {
			unset treeSpectrumNom treeSpectrumType treeSpectrumX treeSpectrumY treeSpectrumGate
		}
		set spectk(spectrumList) ""
	}
	set currentList ""
	set pid ""

# get all apply conditions
	set al [apply -list]
# loop on spectra
	foreach s [spectrum -list] {
		set name [lindex $s 1]
		lappend currentList $name
#		if {![string equal [$t find -full $path] ""]} {continue}
#		if {[lsearch $spectk(spectrumList) $name] != -1} {continue}
		set path [split $name $spectk(smartmenu)]
# Get rid of empty slots created by repetition of split characters
		while {[set i [lsearch $path ""]] != -1} {
			set path [lreplace $path $i $i]
		}
# prepare data
#		set gate [lindex [lindex [apply -list $name] 0] 1]
		set gate [lindex [lindex $al [lsearch $al $name*]] 1]
		if {[string equal [lindex $gate 2] T]} {
			set gate True
		} elseif {[string equal [lindex $gate 2] F]} {
			set gate False
		} else {
			set gate [lindex $gate 0]
		}
		set type [lindex $s 2]
		switch -- $type {
			1 {set type 1D}
			2 {set type 2D}
			s {set type Summary}
			b {set type Bitmask}
			g1 {set type Gamma1D}
			g2 {set type Gamma2D}
		}
		set parameters [lindex $s 3]
		set Name [join $path ,]
		set flag 0
# now that we have the info about the spectrum, we have a few cases to consider:
# - this is a new spectrum and its node doesn't exist: we need to add it to the tree
# - this is a new spectrum but its node already exists: we need to change the entry
# - this is an existing spectrum but its definition has changed: we need to change the entry
# - this is an existing spectrum and nothing has changed: go to the next
		if {[lsearch $spectk(spectrumList) $name] != -1} {
			if {[string equal $treeSpectrumType($Name) $type] \
			&& [string equal $treeSpectrumX($Name) [lindex $parameters 0]] \
			&& [string equal $treeSpectrumY($Name) [lindex $parameters 1]] \
			&& [string equal $treeSpectrumGate($Name) $gate]} {
				continue
			} else {
# flag the entry so that it is not duplicated and its icon is updated
#				set id [$t find -name $path]
				set id [$t index -path -quiet $path]
				set flag 1
			}
		}
		if {![string equal [$t find -name $path] ""]} {
#			set id [$t find -name $path]
			set id [$t index -path -quiet $path]
			set flag 1
		}
# store or update data
		set treeSpectrumNom($Name) $name
		set treeSpectrumType($Name) $type
		set treeSpectrumX($Name) [lindex $parameters 0]
		set treeSpectrumY($Name) [lindex $parameters 1]
		set treeSpectrumGate($Name) $gate
# insert spectrum in tree unless the flag is raised
		if {$flag == 0} {
# since the sort function in treeview seems to be buggy, we need to insert at the right place
# if our path is a singlet its parent will be root
			if {[llength $path] == 1} {set pid ""}
# try to find the closest parent
			for {set i [expr [llength $path]-2]} {$i >= 0} {incr i -1} {
#				set pid [$t find -name [lrange $path 0 $i]]
				set pid [$t index -path -quiet [lrange $path 0 $i]]
				if {![string equal $pid ""]} {break}
			}
# if we didn't find it then it is root
			if {[string equal $pid ""]} {
				set pid 0
				set i -1
			}
# point to our child
			incr i
# make a list of all children from parent
			set clist [$t entry children $pid]
# get their names
			set cnames ""
			foreach n $clist {lappend cnames [lindex [$t get -full $n] $i]}
# add our child
			lappend cnames [lindex $path $i]
# sort them
			set cnames [lsort -dictionary $cnames]
# find position of our child
			set pos [lsearch $cnames [lindex $path $i]]
# somehow the positioning only works when inserting singlet nodes (another bug in BLT)
#			set id [$t insert -at $pid $pos [lindex $path $i]]
			set id [$t insert $pos [lindex $path $i] -at $pid]
# this makes sure the final node gets created if it is a multiplet
			if {$i < [expr [llength $path]-1]} {set id [$t insert end $path]}
		}
		$t entry configure $id -activeicons [list $type $type] -icons [list $type $type]
		$t bind $id <Enter> "MouseSetSpectrumInfo $t %x %y"
		$t bind $id <Leave> "MouseClearSpectrumInfo $t"
		$t bind $id <Button-1> SelectSpectrumInfo
		$t bind $id <Double-Button-1> DoAssignButton
	}
# now we need to remove eventual deleted spectra from the tree
	foreach s $spectk(spectrumList) {
		if {[lsearch $currentList $s] == -1} {
			set path [split $s $spectk(smartmenu)]
# Get rid of empty slots created by repetition of split characters
			while {[set i [lsearch $path ""]] != -1} {
				set path [lreplace $path $i $i]
			}
			set Name [join $path ,]
			if {[info exist treeSpectrumNom($Name)]} {
				unset treeSpectrumNom($Name) treeSpectrumType($Name) treeSpectrumX($Name)
				unset treeSpectrumY($Name) treeSpectrumGate($Name)
			}
			for {set i [expr [llength $path]-1]} {$i >= 0} {incr i -1} {
				set node [lrange $path 0 $i]
#				set nid [$t find -name $node]
				set nid [$t index -path -quiet $node]
				if {[llength $nid] == 0} {continue}
				set Name [join $node ,]
				if {[llength [$t entry children $nid]] == 0} {
					$t delete $nid
				} elseif {![info exist treeSpectrumNom($Name)]} {
					$t entry configure $nid -activeicons "Node Node" -icons "Node Node"
					$t bind $nid <Enter> ""
					$t bind $nid <Leave> ""
					$t bind $nid <Button-1> ""
					$t bind $nid <Double-Button-1> ""
				}
			}
		}
	}

# for all nodes of the tree, bind keys
	foreach n [$t find] {
		$t bind $n <KeyPress> "KeyPressedTree $t %K"
	}

# finally update spectrum list
	set spectk(spectrumList) $currentList
}

proc MouseSetSpectrumInfo {t x y} {
	global spectk
	if {$spectk(disablemouse)} {return}
	set id [$t nearest $x $y]
	ClearSpectrumInfo $t
	SetSpectrumInfo $t $id
}

proc MouseClearSpectrumInfo {t} {
	global spectk
	if {$spectk(disablemouse)} {return}
	ClearSpectrumInfo $t
	set path [$t get -full focus]
#	set id [$t find -name $path]
	set id [$t index -path -quiet $path]
# if this is only a node without spectrum, return
	if {[llength [$t bind $id]] == 1} {return}
	SetSpectrumInfo $t $id
}

proc SetSpectrumInfo {t id} {
	global spectk
	global treeSpectrumNom treeSpectrumType treeSpectrumX treeSpectrumY treeSpectrumGate
#	set id [$t nearest $x $y]
	set path [$t get -full $id]
	set name [join $path ,]
	if {[string length $name] == 0} {return 0}
	set spectk(treepath) $path
	for {set i 0} {$i < [llength $path]} {incr i} {
		set node [lrange $path 0 $i]
		set nid [$t find -name $node]
		$t entry configure $nid -foreground red -font "treebold"
	}
	$t entry activate $id
	set spectk(spectrumName) $treeSpectrumNom($name)
	set spectk(spectrumType) $treeSpectrumType($name)
	set spectk(spectrumX) $treeSpectrumX($name)
	set spectk(spectrumY) $treeSpectrumY($name)
	set spectk(spectrumGate) $treeSpectrumGate($name)
}

proc ClearSpectrumInfo {t} {
	global spectk
	if {![info exist spectk(treepath)]} {return}
	set path $spectk(treepath)
	for {set i 0} {$i < [llength $path]} {incr i} {
		set node [lrange $path 0 $i]
		set nid [$t find -name $node]
		if {![string equal $nid ""]} {
			$t entry configure $nid -foreground black -font "tree"
		}
	}
	set spectk(spectrumName) ""
	set spectk(spectrumType) ""
	set spectk(spectrumX) ""
	set spectk(spectrumY) ""
	set spectk(spectrumGate) ""
}

proc SelectSpectrumInfo {} {
	global spectk
	set spectk(spectrum) $spectk(spectrumName)
}

proc KeyPressedTree {t key} {
	global spectk
	set spectk(disablemouse) 1
	if {[string equal $key Down] || [string equal $key Up]} {
		if {[string equal $key Down]} {set path [$t get -full down]}
		if {[string equal $key Up]} {set path [$t get -full up]}
#		set id [$t find -name $path]
		set id [$t index -path -quiet $path]
# if this is only a node without spectrum, clear and return
		if {[llength [$t bind $id]] == 1} {
			ClearSpectrumInfo $t
			set spectk(spectrum) ""
			return
		}
		ClearSpectrumInfo $t
		SetSpectrumInfo $t $id
		SelectSpectrumInfo
	}
	if {[string match *Shift* $key]} {
		SelectAssignButton
	}
	if {[string equal $key Return]} {
		DoAssignButton
	}
}

### Cascade menu generation ###

proc GenerateTreeSpectrumMenu {parent command} {
# Generate tree spectrum menu and attach it to the parent widget
	global treeSpectrumRoot treeSpectrumName treeSpectrumSeparator treeSpectrumNom
	destroy $parent.root
	set wymax [winfo vrootheight .]
	menu $parent.root -tearoff 0
	set scrollMenu 0
	foreach e $treeSpectrumRoot {
# replace dots (.) by commas (,) in name used for submenus
		set em $e
		while {[set index [string first . $em]] != -1} {set em [string replace $em $index $index ,]}
# Does this entry have a submenu?
# Yes. Recursively create the submenu and cascade it to the item
		if {[info exist treeSpectrumName($e)]} {
			GenerateTreeSpectrumMenus $e $em $parent.root $command
			if {$scrollMenu == 0} {
# if the spectrum corresponding to the cascade name exists, we need to be able to select it
				if {[info exist treeSpectrumNom($e)]} {
					$parent.root add cascade -command "$command $e" -label $e -menu $parent.root.$em \
					-activebackground yellow
				} else {
					$parent.root add cascade -label $e -menu $parent.root.$em \
					-background lightyellow -activebackground yellow
				}
			}
# No. Set it as a regular menu item
		} else {
# If the menu has become too tall to fit on the root window we make a scrollable menu
			if {[$parent.root yposition last] > $wymax-100 && $scrollMenu == 0} {
				$parent.root insert 0 command -image uparrow -activebackground green
				$parent.root add command -image downarrow -activebackground green
				set scrollMenu 1
			}
			if {$scrollMenu == 0} {
				$parent.root add command -label $e -command "$command $e" \
				-activebackground yellow
			}
		}
	}
# Bindings for scrollable menu
	if {$scrollMenu} {
		bind $parent.root <Enter> "ScrollSpectrumMenu $parent.root root {$command}"
		bind $parent.root <ButtonRelease-1> CancelScrollMenu
		bind $parent.root <Leave> CancelScrollMenu
	}
# Allows to cascade submenus without having to click on the item
	bind $parent.root <Motion> "%W postcascade @%y"		
	$parent configure -menu $parent.root
}

proc GenerateTreeSpectrumMenus {member item parent command} {
# Recursive procedure to create menus
	global treeSpectrumName treeSpectrumSeparator treeSpectrumNom
	set wymax [winfo vrootheight .]
	menu $parent.$item -tearoff 0
	set scrollMenu 0
	set index 0
# in case member is already a sub-menu, it contains comma instead of the correct separator
	set mel [split $member ,]
	set menumember [lindex $mel 0]
	for {set i 1} {$i < [llength $mel]} {incr i} {
		set m [join [lrange $mel 0 [expr $i-1]] ,]
		set ind [lsearch $treeSpectrumName($m) [lindex $mel $i]]
		set separator [lindex $treeSpectrumSeparator($m) $ind]
		append menumember [format "%s%s" $separator [lindex $mel $i]]
	}
	foreach entry $treeSpectrumName($member) {
# replace dots (.) by commas (,) in name used for submenus
		set em $entry
		while {[set i [string first . $em]] != -1} {set em [string replace $em $i $i ,]}
		set separator [lindex $treeSpectrumSeparator($member) $index]
		set menucommand $menumember
		append menucommand [format "%s%s" $separator $entry]
# Does this entry have a submenu?
		if {![info exist treeSpectrumName($member,$entry)]} {
# No. Set it as a regular menu item
# If the menu has become too tall to fit on the root window we make a scrollable menu
			if {[$parent.$item yposition last] > $wymax-100 && $scrollMenu == 0} {
				$parent.$item insert 0 command -image uparrow -activebackground green
				$parent.$item add command -image downarrow -activebackground green
				set scrollMenu 1
			}
			if {$scrollMenu == 0} {
				set label [format "%s%s" $separator $entry]
				$parent.$item add command -label $label -command "$command $menucommand" \
				-activebackground yellow
			}
		} else {
# Yes. Recursively create the submenu and cascade it to the item
			GenerateTreeSpectrumMenus $member,$entry $em $parent.$item $command
			if {$scrollMenu == 0} {
				set label [format "%s%s" $separator $entry]
# if the spectrum corresponding to the cascade name exists, we need to be able to select it
				if {[info exist treeSpectrumNom($member,$entry)]} {
					$parent.$item add cascade -label $label -menu $parent.$item.$em \
					-activebackground yellow -command "$command $menucommand"
				} else {
					$parent.$item add cascade -label $label -menu $parent.$item.$em \
					-background lightyellow -activebackground yellow
				}
			}
		}
		incr index
	}
# Bindings for scrollable menu
	if {$scrollMenu} {
		bind $parent.$item <Enter> "ScrollSpectrumMenu $parent.$item $member {$command}"
		bind $parent.$item <ButtonRelease-1> CancelScrollMenu
		bind $parent.$item <Leave> CancelScrollMenu
	}
# Allows to cascade submenus without having to click on the item
	bind $parent.$item <Motion> "%W postcascade @%y"
}	

proc ScrollSpectrumMenu {wmenu member command} {
	global treeSpectrumName afterScrollMenu treeSpectrumSeparator
	set afterScrollMenu [after 20 "ScrollSpectrumMenu $wmenu $member {$command}"]
	set activeItem [$wmenu index active]
	if {$activeItem != 0 && $activeItem != [$wmenu index last]} {
		update
		return
	}

# Make a list of our entries and find indexes of first and last
	set i 0
	set lastItem [expr [$wmenu index last]-1]
	foreach entry $treeSpectrumName($member) {
		if {[string equal [$wmenu entrycget 1 -label] $entry]} {set indexFirst $i}
		if {[string equal [$wmenu entrycget $lastItem -label] $entry]} {set indexLast $i}
		lappend lentries $entry
		incr i
	}

# Process Down arrow
	if {$activeItem == [$wmenu index last]} {
# if the last menu item is on the last entry we do nothing and return
		if {$indexLast+1 == [llength $lentries]} {return}
# For the main body of the menu, shift all items up
		for {set i 1} {$i < $lastItem} {incr i} {
# If the types of entries are different we need to delete the old entry and insert a new with the right type
			set newType [$wmenu type [expr $i+1]]
			if {![string equal [$wmenu type $i] $newType]} {
				$wmenu delete $i
				$wmenu insert $i $newType
			}
			$wmenu entryconfigure $i -label [$wmenu entrycget [expr $i+1] -label]
			$wmenu entryconfigure $i -background [$wmenu entrycget [expr $i+1] -background]
			$wmenu entryconfigure $i -activebackground [$wmenu entrycget [expr $i+1] -activebackground]
			if {[string equal $newType cascade]} {
				$wmenu entryconfigure $i -menu [$wmenu entrycget [expr $i+1] -menu]
			} else {
				$wmenu entryconfigure $i -command [$wmenu entrycget [expr $i+1] -command]
			}
		}
# The last item gets the new entry
		set newEntry [lindex $lentries [expr $indexLast+1]]
		if {![string equal $member root]} {
			set separator [lindex $treeSpectrumSeparator($member) $indexLast]
		} else {
			set separator ""
		}
		set menucommand [format "%s%s%s" $member $separator $newEntry]
# Does this entry have a submenu?
		if {[info exist treeSpectrumName($member,$newEntry)] == 0} {
			set newType command
		} else {
			set newType cascade
		}
# If the types of entries are different we need to delete the old entry and insert a new with the right type
		if {![string equal [$wmenu type $lastItem] $newType]} {
			$wmenu delete $lastItem
			$wmenu insert $lastItem $newType
		}
		if {[string equal $newType command]} {
			$wmenu entryconfigure $lastItem -label $newEntry -command "$command $menucommand" \
			-activebackground yellow
		} else {
			$wmenu entryconfigure $lastItem -label $newEntry -menu $wmenu.$newEntry \
			-background lightyellow -activebackground yellow
		}
	}

# Process Up arrow
	if {$activeItem == 0} {
# if the first menu item is on the first entry we do nothing and return
		if {$indexFirst == 0} {return}
# For the main body of the menu, shift all items down
		for {set i $lastItem} {$i > 1} {incr i -1} {
# If the types of entries are different we need to delete the old entry and insert a new with the right type
			set newType [$wmenu type [expr $i-1]]
			if {![string equal [$wmenu type $i] $newType]} {
				$wmenu delete $i
				$wmenu insert $i $newType
			}
			$wmenu entryconfigure $i -label [$wmenu entrycget [expr $i-1] -label]
			$wmenu entryconfigure $i -background [$wmenu entrycget [expr $i-1] -background]
			$wmenu entryconfigure $i -activebackground [$wmenu entrycget [expr $i-1] -activebackground]
			if {[string equal $newType cascade]} {
				$wmenu entryconfigure $i -menu [$wmenu entrycget [expr $i-1] -menu]
			} else {
				$wmenu entryconfigure $i -command [$wmenu entrycget [expr $i-1] -command]
			}
		}
# The first item gets the new entry
		set newEntry [lindex $lentries [expr $indexFirst-1]]
		if {![string equal $member root]} {
			set separator [lindex $treeSpectrumSeparator($member) $indexFirst]
		} else {
			set separator ""
		}
		set menucommand [format "%s%s%s" $member $separator $newEntry]
# Does this entry have a submenu?
		if {[info exist treeSpectrumName($member,$newEntry)] == 0} {
			set newType command
		} else {
			set newType cascade
		}
# If the types of entries are different we need to delete the old entry and insert a new with the right type
		if {![string equal [$wmenu type 1] $newType]} {
			$wmenu delete 1
			$wmenu insert 1 $newType
		}
		if {[string equal $newType command]} {
			$wmenu entryconfigure 1 -label $newEntry -command "$command $menucommand" \
			-activebackground yellow
		} else {
			$wmenu entryconfigure 1 -label $newEntry -menu $wmenu.$newEntry \
			-background lightyellow -activebackground yellow
		}
	}
}


