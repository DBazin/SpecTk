proc ConnectToServer {name port} {
	global server spectk
	if {[info exist server(connected)] && $server(connected)} {DisconnectFromServer}
	set commandPort $port
	set dataPort [expr $port+1]
	if {[catch "socket $name $commandPort" server(command)] || [catch "socket $name $dataPort" server(data)]} {
		tk_messageBox -message "Unable to connect to Server!" -icon error
		return 0
	}
	fileevent $server(command) readable CommandClientHandle
	fconfigure $server(command) -buffering line
	fconfigure $server(data) -translation binary -encoding binary
	ClientUpdateAll
	set server(connected) 1
	$spectk(status).message configure -text "Connected to $name on port $port"
	return 1
}

proc ClientUpdateAll {} {
	UpdateSpectrumList
	UpdateGateList
	UpdateApplyList
	UpdateParameterList
	UpdateAssignDialog
	AssignAll
}

proc ConnectTo {} {
	global server spectk
	set w .spectkserver
	toplevel $w
	wm title $w "Connect to Server"
	set w .spectkserver.input
	frame $w -width 200 -height 100
	label $w.server -text "Server:" -font "helvetica -12"
	entry $w.name -width 20 -textvariable server(name)
	label $w.port -text "Port:" -font "helvetica -12"
	entry $w.theport -width 10 -textvariable server(port)
	grid $w.server $w.name -sticky news
	grid $w.port $w.theport -sticky news
	pack $w -expand 1 -fill both
	set w .spectkserver.buttons
	frame $w
	button $w.cancel -text "Cancel" -command "destroy .spectkserver"
	button $w.connect -text "Connect" -command DoConnectTo
	grid $w.cancel $w.connect -sticky news
	pack $w -expand 1 -fill both
}

proc DoConnectTo {} {
	global spectk server
	if {[ConnectToServer $server(name) $server(port)]} {
		StoreRecentServer "$server(name) $server(port)"
		UpdateRecentServerMenu
		destroy .spectkserver
	}
}

proc DisconnectFromServer {} {
	global server spectk
	close $server(data)
	close $server(command)
	set server(connected) 0
	$spectk(status).message configure -text "Not Connected"
}	

proc CommandClientHandle {} {
	global server spectk
	if {[gets $server(command) request] < 0} {
		close $server(command)
		close $server(data)
		tk_messageBox -message "Lost connection to Server!"
		set server(response) ""
		set server(done) 1
		set server(connected) 0
		$spectk(status).message configure -text "Not Connected"
	} else {
		append server(requestbuffer) $request "\n"
		if {[info complete $server(requestbuffer)]} {
			set request $server(requestbuffer)
			set server(requestbuffer) ""
#			puts "Received request from server: $request"
			if {[catch {eval $request} message] != 0} {
				tk_messageBox -message "Error while executing: $request\nMessage: $message"
			}
		}
	}
}

proc AddResponseLine {line} {
	global server
	if {![info exist server(buffer)]} {set server(buffer) ""}
	append server(buffer) $line "\n"
}

proc ServerDone {} {
	global server
	if {![info exist server(buffer)]} {set server(buffer) ""}
	set server(response) [string trimright $server(buffer) "\n"]
	unset server(buffer)
	set server(done) 1
}

proc Get1DData {spectrum} {
	global server spectk
	pack $spectk(status).icon -side right
	update
	puts $server(data) "Get1DData $spectrum"
	flush $server(data)
# The "5" is to take the \n into account
	binary scan [read $server(data) 5] "i" server(bytes)
# Same thing with the "+1" (\n)
	set server(response) [read $server(data) [expr $server(bytes)+1]]
	after 10
	pack forget $spectk(status).icon
	update
	return
}

proc Get2DData {spectrum} {
	global server spectk
	pack $spectk(status).icon -side right
	update
	puts $server(data) "Get2DData $spectrum"
	flush $server(data)
# The "5" is to take the \n into account
	binary scan [read $server(data) 5] "i" server(bytes)
# Same thing with the "+1" (\n)
	set server(response) [read $server(data) [expr $server(bytes)+1]]
	after 10
	pack forget $spectk(status).icon
	update
	return
}

# The client-server dialog optimization uses a local list of objects that is
# first loaded at startup, then consulted whenever info is needed.
# The server notifies its clients if any changes need to be made on the list.

#############Spectrum###################################################

proc UpdateSpectrumList {} {
	global client
	set client(spectrumList) [ServerSpectrum -list]
	set wl [itcl::find object -isa Wave1D]
	set w2 [itcl::find object -isa Wave2D]
	foreach w $w2 {lappend wl $w}
	foreach w $wl {
		set s [$w GetMember name]
		set index [lsearch $client(spectrumList) "* $s *"]
# if spectrum corresponding to wave doesn't exist anymore, delete wave
		if {$index == -1} {
			itcl::delete object $w
# else update with new data
		} else {
			$w Update 1
		}
	}
	return
}

# Local spectrum command
proc spectrum {args} {
	global client
	if {[string equal [lindex $args 0] -list]} {
		if {[llength $args] == 1} {return $client(spectrumList)}
		if {[llength $args] == 2} {
			set index [lsearch $client(spectrumList) "* [lindex $args 1] *"]
			return [lindex $client(spectrumList) $index]
		}
	}
}

# Procedure to execute the spectrum command on server
proc ServerSpectrum {args} {
	global server spectk
	pack $spectk(status).icon -side right
	update
	puts $server(command) "spectrum $args"
	flush $server(command)
	vwait server(done)
	after 10
	pack forget $spectk(status).icon
	update
	return $server(response)
}

# Procedure called by the server on notification
proc ClientSpectrum {args} {
	global spectk client
	pack $spectk(status).icon -side right
	update
# First catch -delete keyword
	if {[string equal [lindex $args 0] -delete]} {
# Make a list of all existing waves
		set names ""
		set wnames [itcl::find object -class Wave1D]
		set n2 [itcl::find object -class Wave2D]
		foreach n $n2 {lappend wnames $n}
# Catch -all keyword - all spectra deleted
		if {[string equal [lindex $args 1] -all]} {
			set names $wnames
			set client(spectrumList) ""
			set client(applyList) ""
# List of spectra to delete
		} else {
			set snames [lreplace $args 0 0]
			foreach w $wnames {
				if {[lsearch $snames [$w GetMember name]] != -1} {lappend names $w}
			}
			foreach s $snames {
				set index [lsearch $client(spectrumList) "* $s *"]
				set client(spectrumList) [lreplace $client(spectrumList) $index $index]
				set index [lsearch $client(applyList) "$s *"]
				set client(applyList) [lreplace $client(applyList) $index $index]
			}
		}
# for each deleted spectrum delete wave and graph but not display
		foreach name $names {
			itcl::delete object $name
		}
		UpdateAssignDialog
		after 10
		pack forget $spectk(status).icon
		update
		return
	}

# Just return nothing if -list keyword
	if {[string equal [lindex $args 0] -list]} {return}

# If the optional keyword -new is there we get rid of it
	if {[string equal [lindex $args 0] -new]} {set args [lreplace $args 0 0]}

# This is a spectrum definition command
# First we need to append it to our local list so that spectrum -list works!
# Append spectrum definition to local list (999 is a dummy id number - unused)
	lappend client(spectrumList) "999 $args"
# If the spectrum was already displayed before we need to rebuild
# the display with the modified definition
	set name [lindex $args 0]
# add an entry to the applyList for the spectrum
	lappend client(applyList) "$name \{-TRUE- 0 T \{\}\}"
	set displays [itcl::find object -class Display1D]
	set d2 [itcl::find object -class Display2D]
	foreach d $d2 {lappend displays $d}
	foreach d $displays {
		set waves [$d GetMember waves]
		if {[$d isa Display1D]} {set objectname "::Wave1D::[Proper $name]"}
		if {[$d isa Display2D]} {set objectname "::Wave2D::[Proper $name]"}
		if {[lsearch $waves $objectname] != -1} {
			set spectk(spectrum) $name
			set page [$d GetMember page]
			set id [$d GetMember id]
# This will destroy the Display and recreate a new one based on spectrum
			$page AssignSpectrum $id
# If this was a Display1D with more than one wave displayed
			if {[$d isa Display1D] && [llength $waves] > 1} {
				set waves [lreplace $waves 0 0]
				foreach w $waves {
					set spectk(spectrum) [$w GetMember name]
					$page AppendSpectrum $id
				}
			}
		}
	}
	UpdateAssignDialog
	after 10
	pack forget $spectk(status).icon
	update
	return
}

##########Gate######################################################

proc UpdateGateList {} {
	global client
	set client(gateList) [ServerGate -list]
	set gl [itcl::find object -isa ROI]
	foreach g $gl {
# only touch the SpecTcl gates, not the SpecTk ROIs
		if {[$g GetMember isgate]} {
			set name [$g GetMember name]
			set index [lsearch $client(gateList) "$name *"]
			set type [lindex [lindex $client(gateList) $index] 2]
# if gate doesn't exist in SpecTcl anymore, delete its object
			if {$index == -1 || [string equal $type F]} {
				itcl::delete object $g
# else update it with the new definition
			} else {
				$g GateUpdate $name
			}
		}
	}
	return
}

# Local gate command
proc gate {args} {
	global client
	if {[string equal [lindex $args 0] -list]} {
		if {[llength $args] == 1} {return $client(gateList)}
		if {[llength $args] == 2} {
			set index [lsearch $client(gateList) "[lindex $args 1] *"]
			return [lindex $client(gateList) $index]
		}
# else we are defining a gate and need to pass the command to SpecTcl
	} else {
		return [ServerGate $args]
	}
}

# Procedure to execute the gate command on server
proc ServerGate {args} {
	global server spectk
	pack $spectk(status).icon -side right
	update
# the join is necessary to convert the list $args into a string
	puts $server(command) "gate [join $args]"
	flush $server(command)
	vwait server(done)
	after 10
	pack forget $spectk(status).icon
	update
	return $server(response)
}

# Procedure called by the server on notification
proc ClientGate {args} {
	global spectk client
	pack $spectk(status).icon -side right
	update
# First catch -delete keyword
	if {[string equal [lindex $args 0] -delete]} {
		set names [lreplace $args 0 0]
		foreach name $names {
# Delete ROI if it exists
			set objectname "::ROI::[Proper $name]"
			if {[lsearch [itcl::find object -class ROI] $objectname] != -1} {
				$objectname ProcessDisplays RemoveDisplay
				itcl::delete object $objectname
			}
# Update local gate list
			set index [lsearch $client(gateList) "$name *"]
			set client(gateList) [lreplace $client(gateList) $index $index]
		}
		after 10
		pack forget $spectk(status).icon
		update
		return
	}

# Just return nothing if -list keyword
	if {[string equal [lindex $args 0] -list]} {return}

# If the optional keyword -new is there we get rid of it
	if {[string equal [lindex $args 0] -new]} {set args [lreplace $args 0 0]}

# This is a gate definition command
# Catch the name and type of gate
	set name [lindex $args 0]
	set type [lindex $args 1]
# If this gate already exists we need to replace its definition
	set index [lsearch $client(gateList) "$name *"]
	if {$index != -1} {set client(gateList) [lreplace $client(gateList) $index $index]}
# If non-composite display or update it wherever necessary
	switch -- $type {
		s - gs - c - gc - b - gb {
# Update local gate list - need to reformat because gate -list != gate -new (Ron!)
			set desc [lindex $args 2]
			if {[llength $desc] == 2} {set dlist $desc}
			if {[llength $desc] == 3} {
				set dlist "\{[lindex $desc 0] [lindex $desc 1]\}"
				foreach pair [lindex $desc 2] {lappend dlist $pair}
#				lappend dlist [lindex $desc 2]
			}
			lappend client(gateList) "$name 999 $type \{$dlist\}"
# Create a ROI if it doesn't exist yet
			set objectname "::ROI::[Proper $name]"
			if {[lsearch [itcl::find object -class ROI] $objectname] == -1} {
				ROI $objectname $name
			}
# Update ROI with gate
			$objectname GateUpdate $name
# Update all relevant displays
			$objectname ProcessDisplays UpdateDisplay
		}
	}
	after 10
	pack forget $spectk(status).icon
	update
	return
}

############Apply####################################################

proc UpdateApplyList {} {
	global client
	set client(applyList) [ServerApply -list]
	return
}

# Local apply command
proc apply {args} {
	global client
	if {[string equal [lindex $args 0] -list]} {
		if {[llength $args] == 1} {return $client(applyList)}
		if {[llength $args] == 2} {
			set index [lsearch $client(applyList) "[lindex $args 1] *"]
# The {} are there because apply in SpecTcl is not self consistent!
			return "\{[lindex $client(applyList) $index]\}"
		}
	}
}

proc ServerApply {args} {
	global server spectk
	pack $spectk(status).icon -side right
	update
	puts $server(command) "apply $args"
	flush $server(command)
	vwait server(done)
	after 10
	pack forget $spectk(status).icon
	update
	return $server(response)
}

# Procedure called by the server on notification
proc ClientApply {args} {
	global spectk client
	UpdateGateList
	pack $spectk(status).icon -side right
	update
# Just return nothing if -list keyword
	if {[string equal [lindex $args 0] -list]} {return}

# This is a real apply command
	set gate [lindex $args 0]
	set spectra [lreplace $args 0 0]
	set waves [itcl::find object -class Wave1D]
	set w2 [itcl::find object -class Wave2D]
	foreach w $w2 {lappend waves $w}
	foreach s $spectra {
		set index [lsearch $client(applyList) "$s *"]
		if {$index != -1} {
			set client(applyList) [lreplace $client(applyList) $index $index "$s \{[gate -list $gate]\}"]
		} else {
			lappend client(applyList) "$s \{[gate -list $gate]\}"
		}
		foreach w $waves {
			if {[string equal [$w GetMember name] $s] != -1} {
				$w Update 0
				foreach d [$w FindDisplays] {$d UpdateDisplay}
			}
		}
	}
# Update the spectrum tree with correct gate condition
	UpdateTreeSpectrum $spectk(smartmenu)
	after 10
	pack forget $spectk(status).icon
	update
	return
}

##########Parameter######################################################

proc UpdateParameterList {} {
	global client
	set client(parameterList) [ServerParameter -list]
	return
}

proc parameter {args} {
	global client
	if {[string equal [lindex $args 0] -list]} {
		if {[llength $args] == 1} {return $client(parameterList)}
		if {[llength $args] == 2} {
			set index [lsearch $client(parameterList) "[lindex $args 1] *"]
			return [lindex $client(parameterList) $index]
		}
	}
}

proc ServerParameter {args} {
	global server spectk
	pack $spectk(status).icon -side right
	update
	puts $server(command) "parameter $args"
	flush $server(command)
	vwait server(done)
	after 10
	pack forget $spectk(status).icon
	update
	return $server(response)
}

###########Ungate#####################################################

proc ServerUngate {args} {
	global server spectk
	pack $spectk(status).icon -side right
	update
	puts $server(command) "ungate $args"
	flush $server(command)
	vwait server(done)
	after 10
	pack forget $spectk(status).icon
	update
	return $server(response)
}

proc ClientUngate {args} {
	global spectk client
	pack $spectk(status).icon -side right
	update
	set spectra $args
	set waves [itcl::find object -class Wave1D]
	set w2 [itcl::find object -class Wave2D]
	foreach w $w2 {lappend waves $w}
	foreach s $spectra {
		set index [lsearch $client(applyList) "$s *"]
		if {$index != -1} {
			set client(applyList) [lreplace $client(applyList) $index $index "$s \{-TRUE- 0 T \{\}\}"]
		}
		foreach w $waves {
			if {[string equal [$w GetMember name] $s] != -1} {
				$w Update 0
				foreach d [$w FindDisplays] {$d UpdateDisplay}
			}
		}
	}
	after 10
	pack forget $spectk(status).icon
	update
	return
}

###########Clear#####################################################

proc clear {args} {
	ServerClear $args
}

proc ServerClear {args} {
	global server spectk
	pack $spectk(status).icon -side right
	update
	puts $server(command) "clear $args"
	flush $server(command)
	vwait server(done)
	after 10
	pack forget $spectk(status).icon
	update
	return $server(response)
}

proc ClientClear {args} {
	global spectk
	pack $spectk(status).icon -side right
	update
# To be implemented...
	after 10
	pack forget $spectk(status).icon
	update
	return
}

###########Translate###################################################

proc Proper {name} {
	set ch [list ":" ";" "\[" "\]" "\{" "\}" "," "?" "/" "<" ">" "|" "\\" "!" "@" "#" "$" "%" "^" "&" "*" "(" ")" "-" "=" "+" "~"]
	set pr [list cc sc lc rc lb rb co in sl le gr or bs ex at di do pe po an ti lp rl mi eq pl ti]
	set j 0
	foreach c $ch {
		set i 0
		while {[set i [string first $c $name $i]] != -1} {set name [string replace $name $i $i [lindex $pr $j]]}
		incr j
	}
	return $name
}

set client(spectrumList) ""
set client(gateList) ""
set client(applyList) ""
set client(parameterList) ""
