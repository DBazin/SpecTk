#!/bin/bash
##
# Configure the VM-USB unpacker software:

#
# You should probably change the code below to
# load the configuration file of your choice.
#
#    This software is Copyright by the Board of Trustees of Michigan
#    State University (c) Copyright 2005.
#
#    You may use this software under the terms of the GNU public license
#    (GPL).  The terms of this license are described at:
#
#     http://www.gnu.org/licenses/gpl.txt
#
#    Author:
#             Ron Fox
#	     NSCL
#	     Michigan State University
#	     East Lansing, MI 48824-1321


# (C) Copyright Michigan State University 2014, All rights reserved 
#
#
#  Setup the standard scripted commandsin SpecTcl.
#


#  Access SpecTcl Packages, 
#  Load splash and jpeg support:

if {[catch {set daqversion $env(daqversion)} result]} {
    set daqversion "11.3-027"
    puts $daqversion
 }

if {[catch {set DAQHOST $env(DAQHOST)} result]} {
    set DAQHOST "spdaq37.nscl.msu.edu"
 }

lappend auto_path $SpecTclHome/TclLibs
package require splash
package require img::jpeg

set daqconfig [file join daqconfig.tcl]; # default config file.
puts "Config file $daqconfig"
lappend auto_path [file join $SpecTclHome TclLibs]

puts "constants loaded"
source ./constants.tcl

puts "spectclSteup loaded"
source ./spectclSetup.tcl

puts "configFile.tcl loaded"
source ./configFile.tcl

#package require vmusbsetup
#puts "vmusbsetup package loaded"
vmusbConfig $daqconfig
puts "vmusbConfig invoked"

set splash [splash::new -text 1 -imgfile $splashImage -progress 6 -hidemain 0]
splash::progress $splash {Loading button bar} 0

puts -nonewline "Loading SpecTcl gui..."
#source $SpecTclHome/Script/gui.tcl
source ./gui.tcl
puts  "Done."

splash::progress $splash {Loading state I/O scripts} 1

puts -nonewline "Loading state I/O scripts..."
source $SpecTclHome/Script/fileall.tcl
puts "Done."

splash::progress $splash {Loading formatted listing scripts} 1

puts -nonewline "Loading formatted listing scripts..."
source $SpecTclHome/Script/listall.tcl
puts "Done."

splash::progress $splash {Loading gate copy scripts} 1

puts -nonewline "Loading gate copy script procs..."
source $SpecTclHome/Script/CopyGates.tcl
puts "Done."

splash::progress $splash {Loading tkcon console} 1

if {$tcl_platform(os) != "Windows NT"} {
	puts -nonewline "Loading TKCon console..."
	source $SpecTclHome/Script/tkcon.tcl
	puts "Done."
}

splash::progress $splash {Loading SpecTcl Tree Gui} 1

puts -nonewline "Starting treeparamgui..."
source $SpecTclHome/Script/SpecTclGui.tcl
puts " Done"


puts -nonewline "Loading Aris scripts..."
source ./ArisVariables.tcl
puts "Done."

puts "SpecTk server..."
source Server/Server.tcl
puts "Done"

splash::progress $splash {SpecTcl ready for use} 1

splash::config $splash -delay 2000

proc updateFormat {ms} {

    after $ms updateFormat $ms
    if {[winfo exists .hostprompt]} {
	.hostprompt configure -format ring11
    }

    if {[winfo exists .prompt]} {
	catch {.prompt configure -format ring11}
    }

}
updateFormat 100

# attach online
proc attonline {} {
    global SpecTclHome
    global RunState
    global DAQHOST
    global daqversion
    if $RunState stop

    set daqconfig "/user/arisdaq/vme/config/daqconfig.tcl"
    
    puts $daqconfig
    uplevel #0 exec ln -sfn $daqconfig daqconfig.tcl
    
    set DataSource "tcp://$DAQHOST/aris_vme_1"
    set ringHelper "/usr/opt/nscldaq/$daqversion/bin/ringselector"
    
     attach -format ring -pipe \
	$ringHelper  --source=$DataSource \
	--sample=PHYSICS_EVENT 
    ringformat 11.0
   
    uplevel #0 source "ArisVariables.tcl"
    puts "sourced ArisVariables.tcl"
    
    after 50 start
}

# attach file
proc attachFile {} {
    global SpecTclHome
    global RunState
    set fname [tk_getOpenFile -defaultextension ".evt" -initialdir "/user/arisdaq/stagearea_vme/complete" -title "Select listmode file:"]
    if {$fname != {} } {
	if $RunState stop
	puts -nonewline "File name is ... $fname"

	attach -format ring -file $fname

	uplevel #0 source "ArisVariables.tcl"
	puts " sourced ArisVariables.tcl"

	puts $fname
	
	set val [split $fname \ /]
	set val [lindex $val 5]

#	exec rm -f -- daqconfig.tcl
	
	if { $val=="complete" } {
	    set fbasename [file rootname [file tail $fname]]
	    set fbasename [string range $fbasename 0 end-3]
	    
	    set runnum [string range $fbasename 4 end]
	    set runnum [string trimleft $runnum 0]

	    set path "/user/arisdaq/stagearea_vme/experiment/run"
	    append path $runnum "/daqconfig.tcl"
	
	    set daqconfig $path	    
	    puts $daqconfig

	    exec ln -sfn $daqconfig daqconfig.tcl	
	} else {
	    set daqconfig "/user/arisdaq/vme/config/daqconfig.tcl"
	    puts $daqconfig
	    exec ln -sfn $daqconfig daqconfig.tcl
	}
	
	after 50 start
    }
}

# SpecTcl efficiency calculation
set AnalysisEfficiency 0
set LastSequence0 0
set BuffersAnalyzed0 0
set RunNumber0 -1

proc newrun {} {
    global LastSequence
    global LastSequence0
    global BuffersAnalyzed
    puts "Start new run......"
    set BuffersAnalyzed 0
    puts "BuffersAnalyzed reset to 0"
    set LastSequence0 $LastSequence
    puts "Initial LastSequence remembered $LastSequence0"
}

proc Efficiency {} {
    ;# Will reschedule self to compute every second.
    global AnalysisEfficiency
    global LastSequence
    global LastSequence0
    global RunNumber BuffersAnalyzed
    global RunNumber0 BuffersAnalyzed0

    # Reset at beginning of run
    if { $RunNumber0 != $RunNumber } {
	set LastSequence0 $LastSequence
	set BuffersAnalyzed0 $BuffersAnalyzed
	set RunNumber0 $RunNumber
    }
    if {$LastSequence != $LastSequence0} {
	set eff [expr ($BuffersAnalyzed - $BuffersAnalyzed0) * 100.0 / ($LastSequence - $LastSequence0)]
	set AnalysisEfficiency [format "%5.1f" $eff]
    }
    after 1000 Efficiency
}

Efficiency

