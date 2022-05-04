set server [interp create -safe]
$server eval {}

proc DataServerAccept {cid addr port} {
	global clients
	fileevent $cid readable "DataServerHandle $cid"
	fconfigure $cid -translation binary -encoding binary
	set clients(data$clients(connected)) $cid
#	puts "Server accepted connection from $cid at address $addr, port $port"
}

proc CommandServerAccept {cid addr port} {
	global clients
	fileevent $cid readable "CommandServerHandle $cid"
	fconfigure $cid -buffering line
	incr clients(connected)
	set clients(message) "$clients(connected) clients connected"
	set clients(command$clients(connected)) $cid
	puts "Server accepted connection from $cid at address $addr, port $port"
}

proc DataServerHandle {cid} {
	global server buffer clients
	if {[gets $cid request] < 0} {
		close $cid
	} else {
		append buffer $request "\n"
		if {[info complete $buffer]} {
			set request $buffer
			set buffer ""
			if {[catch {$server eval $request} result] == 0} {
				puts $cid [binary format "i" [string length $result]]
				puts $cid $result
				flush $cid
			} else {
				tk_messageBox -message "Invalid data client request: $request"
			}
		}
	}
}

proc CommandServerHandle {cid} {
	global server buffer clients
	if {[gets $cid request] < 0} {
		close $cid
		incr clients(connected) -1
		set clients(message) "$clients(connected) clients connected"
		puts "Client $cid closed connection"
	} else {
		append buffer $request "\n"
		if {[info complete $buffer]} {
			set request $buffer
			set buffer ""
			if {[catch {$server eval $request} result] < 3} {
				foreach line [split $result "\n"] {
					puts $cid "AddResponseLine [list $line]"
				}
				puts $cid ServerDone
			} else {
				tk_messageBox -message "Invalid command client request: $request"
			}
		}
	}
}

# Now rename Ron's commands to be able to catch them later
rename spectrum ronspectrum
rename gate rongate
rename apply ronapply
rename ungate ronungate
rename clear ronclear
# Catch the Load command likewise
# rename Load InactiveLoad

# We can now redefine these commands and therefore catch them
# They will call the original commands, catch the result and
# call the clients to notify them of a change
proc spectrum {args} {
	global clients
	set result [eval ronspectrum $args]
	if {[string equal [lindex $args 0] -list]} {return $result}
	if {$clients(inhibit)} {return $result}
	for {set c 1} {$c <= $clients(connected)} {incr c} {
		puts $clients(command$c) "ClientSpectrum $args"
		puts $clients(command$c) ServerDone
	}
	return $result
}

proc gate {args} {
	global clients
	set result [eval rongate $args]
	if {[string equal [lindex $args 0] -list]} {return $result}
	if {$clients(inhibit)} {return $result}
	for {set c 1} {$c <= $clients(connected)} {incr c} {
		puts $clients(command$c) "ClientGate $args"
		puts $clients(command$c) ServerDone
	}
	return $result
}

proc apply {args} {
	global clients
	set result [eval ronapply $args]
	if {[string equal [lindex $args 0] -list]} {return $result}
	if {$clients(inhibit)} {return $result}
	for {set c 1} {$c <= $clients(connected)} {incr c} {
		puts $clients(command$c) "ClientApply $args"
		puts $clients(command$c) ServerDone
	}
	return $result
}

proc ungate {args} {
	global clients
	set result [eval ronungate $args]
	if {[string equal [lindex $args 0] -list]} {return $result}
	if {$clients(inhibit)} {return $result}
	for {set c 1} {$c <= $clients(connected)} {incr c} {
		puts $clients(command$c) "ClientUngate $args"
		puts $clients(command$c) ServerDone
	}
	return $result
}

proc clear {args} {
	global clients
	set result [eval ronclear $args]
	if {[string equal [lindex $args 0] -list]} {return $result}
	if {$clients(inhibit)} {return $result}
	for {set c 1} {$c <= $clients(connected)} {incr c} {
		puts $clients(command$c) "ClientClear $args"
		puts $clients(command$c) ServerDone
	}
	return $result
}

# We are catching the Load command to inhibit SpecTk clients during the loading of definition file
# This is to prevent SpecTk clients to get confused by the fast stream of broadcasting when
# the definition file is sourced.
# D. Bazin - Dec 2009
proc Load {} {
	global clients
	global spectrumType spectrumDatatype spectrumName spectrumParameterX spectrumResolutionX spectrumParameterY spectrumResolutionY
	global spectrumInfoX spectrumInfoY
	global definitionFile fullDefinitionFile definitionDirectory deleteAll
	
	set fullDefinitionFile [tk_getOpenFile -filetypes {\
	{"Tcl Script file" {.tcl}}\
	{"Definition file" {.sdef}}\
	}\
	-initialdir $definitionDirectory -title "Load Spectrum Definition file" -parent .gui]
	if {[string match $fullDefinitionFile ""]} {return}
	set definitionFile [lindex [split $fullDefinitionFile /] end]
	set definitionDirectory [string trimright $fullDefinitionFile $definitionFile]
	set clients(inhibit) 1
	if {$deleteAll == 0} {
		spectrum -delete -all
	}
	LoadDefinitionFile $fullDefinitionFile
	UpdateTreeParameters
	set spectrumInfoX [GetParameterInfo $spectrumParameterX]
	set spectrumInfoY [GetParameterInfo $spectrumParameterY]
	UpdateGateList
	UpdateSpectrumList
	set clients(inhibit) 0
# Now tell all our clients to update themselves and reassign spectra where necessary
	for {set c 1} {$c <= $clients(connected)} {incr c} {
		puts $clients(command$c) ClientUpdateAll
		puts $clients(command$c) AssignAll
		puts $clients(command$c) ServerDone
	}
}


# We now tell our server interpreter which commands it is allowed to run
$server alias Get1DData Get1DData
$server alias Get2DData Get2DData
$server alias spectrum spectrum
$server alias gate gate
$server alias apply apply
$server alias ungate ungate
$server alias clear clear
$server alias parameter parameter

proc StartServer {} {
	global clients
	set clients(connected) 0
	set clients(message) "0 clients connected"
	set clients(port) 9001
	set clients(inhibit) 0
	while {[catch "socket -server CommandServerAccept $clients(port)"] || [catch "socket -server DataServerAccept [expr $clients(port)+1]"]} {
		incr clients(port) 2
	}
	#socket -server CommandServerAccept 9001
	#socket -server DataServerAccept 9002
	frame .server -borderwidth 2 -relief groove
	label .server.text -text "SpecTcl Server is up and listening on port $clients(port)" -font "Helvetica 12"
	label .server.clients -textvariable clients(message) -font "Helvetica 12"
	pack .server.text .server.clients -expand 1 -fill both
	pack .server -expand 1 -fill both
}

StartServer
