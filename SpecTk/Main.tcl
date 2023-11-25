# 12/13/09: Added Print buttons on main window
# 12/14/09: Changed bindings to individual displays

package require BLT
package require Itcl

if {![string equal [itcl::find classes Fit] ""]} {itcl::delete class Fit}
if {![string equal [itcl::find classes Page] ""]} {itcl::delete class Page}
if {![string equal [itcl::find classes ROI] ""]} {itcl::delete class ROI}
if {![string equal [itcl::find classes Wave1D] ""]} {itcl::delete class Wave1D}
if {![string equal [itcl::find classes Display1D] ""]} {itcl::delete class Display1D}
if {![string equal [itcl::find classes Wave2D] ""]} {itcl::delete class Wave2D}
if {![string equal [itcl::find classes Display2D] ""]} {itcl::delete class Display2D}
if {![string equal [itcl::find classes Palette] ""]} {itcl::delete class Palette}

if {[info exist env(SpecTkHome)]} {
	set SpecTkHome $env(SpecTkHome)
} else {
	set SpecTkHome [pwd]
}
source $SpecTkHome/Client.tcl
source $SpecTkHome/Page.tcl
source $SpecTkHome/Display1D.tcl
source $SpecTkHome/Wave1D.tcl
source $SpecTkHome/Display2D.tcl
source $SpecTkHome/Wave2D.tcl
source $SpecTkHome/Palette.tcl
source $SpecTkHome/TreeSpectrum.tcl
source $SpecTkHome/Drawer.tcl
source $SpecTkHome/Geometry.tcl
source $SpecTkHome/Assign.tcl
source $SpecTkHome/ROI.tcl
source $SpecTkHome/ROIDialog.tcl
source $SpecTkHome/ExpandDialog.tcl
source $SpecTkHome/FitDialog.tcl
source $SpecTkHome/Help.tcl
source $SpecTkHome/Fit.tcl
source $SpecTkHome/FitDialog.tcl
source $SpecTkHome/Print.tcl
source $SpecTkHome/GraphDialog.tcl
source $SpecTkHome/List.tcl

proc SetupSpecTk {} {
	global spectk
	set spectk(version) "1.3.3"
	set spectk(configName) unknown.spk
	set spectk(smartmenu) .
	set spectk(smartprevious) .
	set spectk(printchoice) page
	set spectk(printorient) 0
	set spectk(printscale) same
	set spectk(printcommand) lpr
	set spectk(printstamp) 0
	set spectk(printroi) 0
	set spectk(printfit) 0
	set spectk(resizeWindow) 1
	set spectk(autoscale) 0
	set spectk(pageUpdate) 0
	set spectk(preferences) mac
	set spectk(disablemouse) 0

	global List
	set List [PageList create]

	set spectk(toplevel) .top
	frame $spectk(toplevel) -borderwidth 2 -relief raised -width 1600 -height 1200
	set spectk(drawer) .drawer
	set spectk(drawerwidth) 250
	set spectk(draweropen) 0
	frame $spectk(drawer) -borderwidth 2 -relief sunken -width $spectk(drawerwidth) -height 1200
	grid $spectk(toplevel) $spectk(drawer) -sticky news
	grid columnconfigure . 0 -weight 1
	grid columnconfigure . 1 -weight 0
	grid rowconfigure . 0 -weight 1
	grid remove $spectk(drawer)
#	pack $spectk(toplevel) -anchor w -expand 1 -fill y
#	toplevel $spectk(toplevel) -width 500 -height 500
	wm title . "SpecTk $spectk(version) ($spectk(configName))"
	wm minsize . 400 400
	wm geometry . 800x600+100+100

	set spectk(menubar) .menubar
	menu $spectk(menubar)
	. configure -menu $spectk(menubar)
	
	set spectk(status) $spectk(toplevel).status
	frame $spectk(status) -width 500 -height 16 -borderwidth 2 -relief groove -bg white

	set spectk(tools) $spectk(toplevel).tools
	set spectk(toolwidth) 32
	frame $spectk(tools) -width $spectk(toolwidth) -height 500 -borderwidth 2 -relief groove

	set spectk(info) $spectk(toplevel).info
	set spectk(infoheight) 20
	frame $spectk(info) -width 500 -height $spectk(infoheight) -borderwidth 2 -relief groove

	set spectk(help) $spectk(toplevel).help
	frame $spectk(help) -width 500 -height 20 -borderwidth 2 -relief groove

	set spectk(buttons) $spectk(toplevel).buttons
	set spectk(buttonheight) 50
	frame $spectk(buttons) -width 500 -height $spectk(buttonheight) -borderwidth 2 -relief groove

	set spectk(pages) $spectk(toplevel).pages
	blt::tabnotebook $spectk(pages) -borderwidth 0 -outerpad 0
	grid $spectk(status) - -sticky news
	grid $spectk(tools) $spectk(pages) -sticky news
	grid ^ $spectk(info) -sticky news
	grid $spectk(help) - -sticky news
	grid $spectk(buttons) - -sticky news
	grid columnconfigure $spectk(toplevel) 0 -weight 0
	grid columnconfigure $spectk(toplevel) 1 -weight 1
	grid rowconfigure $spectk(toplevel) 0 -weight 0
	grid rowconfigure $spectk(toplevel) 1 -weight 1
	grid rowconfigure $spectk(toplevel) 2 -weight 0
	grid rowconfigure $spectk(toplevel) 3 -weight 0
	grid rowconfigure $spectk(toplevel) 4 -weight 0
	grid remove $spectk(help)
	bind $spectk(pages) <Configure> ResizePages
	set spectk(ButtonPressed) 0
	
	SetupFonts
	SetupImages
	SetupMenuBar
	SetupStatus
	SetupToolBar
	SetupHelp
	SetupButtons
	SetupInfo
	SetupDrawer
	BindArrows
	LoadOptions
	UpdateAssignDialog
}

proc SetupFonts {} {
	global spectk
	set spectk(generalFamily) helvetica
	set spectk(generalSize) -12
	set spectk(treeFamily) helvetica
	set spectk(treeSize) -12
	set spectk(resultsFamily) fixed
	set spectk(resultsSize) -10
	set spectk(graphsFamily) helvetica
	set spectk(graphsSize) -9
	set spectk(graphlabelsFamily) helvetica
	set spectk(graphlabelsSize) -9
	set spectk(roiresultsFamily) helvetica
	set spectk(roiresultsSize) -9
	set fonts [font names]
	if {[lsearch $fonts general] == -1} {font create general -family helvetica -size -12 -weight normal}
	if {[lsearch $fonts generalbold] == -1} {font create generalbold -family helvetica -size -12 -weight bold}
	if {[lsearch $fonts smaller] == -1} {font create smaller -family helvetica -size -10 -weight normal}
	if {[lsearch $fonts smallerbold] == -1} {font create smallerbold -family helvetica -size -10 -weight bold}
	if {[lsearch $fonts tree] == -1} {font create tree -family helvetica -size -12 -weight normal}
	if {[lsearch $fonts treebold] == -1} {font create treebold -family helvetica -size -12 -weight bold}
	if {[lsearch $fonts results] == -1} {font create results -family fixed -size -10 -weight normal}
	if {[lsearch $fonts graphs1] == -1} {font create graphs1 -family helvetica -size -9 -weight normal}
	if {[lsearch $fonts graphs2] == -1} {font create graphs2 -family helvetica -size -10 -weight normal}
	if {[lsearch $fonts graphs3] == -1} {font create graphs3 -family helvetica -size -12 -weight normal}
	if {[lsearch $fonts graphs4] == -1} {font create graphs4 -family helvetica -size -14 -weight normal}
	if {[lsearch $fonts graphlabels] == -1} {font create graphlabels -family helvetica -size -9 -weight normal}
	if {[lsearch $fonts roiresults] == -1} {font create roiresults -family helvetica -size -9 -weight normal}
}	

proc SetupMenuBar {} {
	global spectk SpecTkHome
	
# SpecTk menu
	set w $spectk(menubar).spectk
	menu $w -tearoff 0
	$w add command -label "About SpecTk" -command DisplayAbout
	$w add separator
	$w add command -label "Connect To..." -command ConnectTo
	menu $w.recent -tearoff 0
	if {[file exist $SpecTkHome/SpecTkRecentServers.tcl]} {
		set f [open $SpecTkHome/SpecTkRecentServers.tcl r]
		gets $f spectk(recentservers)
		close $f
	}
	$w add cascade -label "Connect To Recent" -menu $w.recent
	UpdateRecentServerMenu
	$w add command -label "Disconnect" -command DisconnectFromServer
	$w add separator
	$w add command -label "Quit SpecTk" -command ExitSpecTk -accelerator "Ctrl-Q"
	bind $w <Motion> "%W postcascade @%y"
	$spectk(menubar) add cascade -label SpecTk -menu $w
	bind $spectk(toplevel) <Control-q> ExitSpecTk

# File menu
	set w $spectk(menubar).file
	menu $w -tearoff 0
	$w add command -label New -command NewConfiguration -accelerator "Ctrl-N"
	bind $spectk(toplevel) <Control-n> NewConfiguration
	$w add command -label Open... -command "LoadConfiguration \"\"" -accelerator "Ctrl-O"
	bind $spectk(toplevel) <Control-o> "LoadConfiguration \"\""
	menu $w.recent -tearoff 0
	if {[file exist SpecTkRecentFiles.tcl]} {source SpecTkRecentFiles.tcl}
	$w add cascade -label "Open Recent" -menu $w.recent
	UpdateRecentFileMenu
	$w add separator
	$w add command -label Save -command SaveConfiguration -accelerator "Ctrl-S"
	bind $spectk(toplevel) <Control-s> SaveConfiguration
	$w add command -label "Save As..." -command SaveAsConfiguration
	$w add separator
	$w add command -label "Print..." -command CreatePrintDialog -accelerator "Ctrl-P"
	bind $spectk(toplevel) <Control-p> CreatePrintDialog
	bind $w <Motion> "%W postcascade @%y"
	$spectk(menubar) add cascade -label File -menu $w

# Options menu
	set w $spectk(menubar).options
	menu $w -tearoff 0
	$w add checkbutton -label "Resize Window from File" -variable spectk(resizeWindow)
	$w add separator
#	menu $w.preferences -tearoff 0
#	$w add cascade -label "X Windows Preferences" -menu $w.preferences
#	$w.preferences add radiobutton -label "Macintosh" -command SetMacintoshOptions -variable spectk(preferences) -value mac
#	$w.preferences add radiobutton -label "Linux" -command SetLinuxOptions -variable spectk(preferences) -value linux
#	$w.preferences add radiobutton -label "Windows" -command SetWindowsOptions -variable spectk(preferences) -value windows
	$w add command -label "Fonts..." -command CreateFontDialog
	$w add separator
	menu $w.autoscale -tearoff 0
	$w add cascade -label "Autoscale" -menu $w.autoscale
	$w.autoscale add radiobutton -label "Whole Data" -variable spectk(autoscale) -value 0
	$w.autoscale add radiobutton -label "Exclude Bin 0" -variable spectk(autoscale) -value 1
	$w.autoscale add radiobutton -label "Displayed Range" -variable spectk(autoscale) -value 2
	$w add checkbutton -label "Update Page when Selected" -variable spectk(pageUpdate)
	$w add separator
	$w add command -label "Save Options" -command SaveOptions
	bind $w <Motion> "%W postcascade @%y"
	$spectk(menubar) add cascade -label "Options" -menu $w
	
# Help menu
	set w $spectk(menubar).help
	menu $w -tearoff 0
	$w add checkbutton -label "Display Help" -command EnableHelp -variable spectk(helptoggle)
	$spectk(menubar) insert end cascade -label Help -menu $w 

# Tab menu
	set w $spectk(menubar).tab
	menu $w -tearoff 0
	$w add command -label "Reorder" -command initReorder
	$w add command -label "Alphabetical" -command alphabeticalTab 
	$spectk(menubar) insert end cascade -label Tab -menu $w 
}

proc SetupStatus {} {
	global spectk
	set w $spectk(status)
	label $w.icon -image Communicate -bg white
	label $w.status -text "Status: " -font "helvetica -12" -bg white
	label $w.message -text "Not Connected" -font "helvetica -12" -bg white
	pack $w.status $w.message -side left
}

proc SetupToolBar {} {
	global spectk
	set w $spectk(tools)
	radiobutton $w.select -image select -width $spectk(toolwidth) -height $spectk(toolwidth) \
	-command "ToolCommand BindSelect" -variable spectk(currentTool) -value BindSelect \
	-indicatoron 0
	pack $w.select -side top
#	radiobutton $w.display -image display -width $spectk(toolwidth) -height $spectk(toolwidth) \
	-command "ToolCommand BindDisplay" -variable spectk(currentTool) -value BindDisplay \
	-indicatoron 0
#	pack $w.display -side top
	radiobutton $w.zoom -image zoom -width $spectk(toolwidth) -height $spectk(toolwidth) \
	-command "ToolCommand BindZoom" -variable spectk(currentTool) -value BindZoom \
	-indicatoron 0
	pack $w.zoom -side top
	radiobutton $w.expand -image expand -width $spectk(toolwidth) -height $spectk(toolwidth) \
	-command "ToolCommand BindExpand" -variable spectk(currentTool) -value BindExpand \
	-indicatoron 0
	pack $w.expand -side top
	radiobutton $w.scroll -image scroll -width $spectk(toolwidth) -height $spectk(toolwidth) \
	-command "ToolCommand BindScroll" -variable spectk(currentTool) -value BindScroll \
	-indicatoron 0
	pack $w.scroll -side top
	radiobutton $w.inspect -image inspect -width $spectk(toolwidth) -height $spectk(toolwidth) \
	-command "ToolCommand BindInspect" -variable spectk(currentTool) -value BindInspect \
	-indicatoron 0
	pack $w.inspect -side top
	radiobutton $w.edit -image edit -width $spectk(toolwidth) -height $spectk(toolwidth) \
	-command "ToolCommand BindEdit" -variable spectk(currentTool) -value BindEdit \
	-indicatoron 0
	pack $w.edit -side top
	ToolCommand BindSelect
	set spectk(currentTool) BindSelect
}

# Old ToolCommand proc not used anymore
proc ToolCommandAll {command} {
	global spectk
	foreach tab [$spectk(pages) tab names] {
		set frame [$spectk(pages) tab cget $tab -window]
		set page [lindex [split $frame .] end]
		$page $command
	}
}

proc ToolCommand {command} {
	global spectk
	set tab [$spectk(pages) id select]
	if {[string equal $tab ""]} {return}
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split $frame .] end]
	foreach id [$page GetMember selected] {
		set display [format "%s%s" $page $id]
		if {[lsearch [itcl::find objects] $display] != -1} {
			$display Unbind
			$display $command
		}
	}
}

proc SetupImages {} {
	global SpecTkHome
	image create photo gaussian -file $SpecTkHome/gaussian.gif
	image create photo lorentzian -file $SpecTkHome/lorentzian.gif
	image create photo exponential -file $SpecTkHome/exponential.gif
	image create photo polynomial -file $SpecTkHome/polynomial.gif
	image create photo select -file $SpecTkHome/select.gif
	image create photo display -file $SpecTkHome/display.gif
	image create photo zoom -file $SpecTkHome/zoom.gif
	image create photo expand -file $SpecTkHome/expand.gif
	image create photo scroll -file $SpecTkHome/scroll.gif
	image create photo inspect -file $SpecTkHome/inspect.gif
	image create photo edit -file $SpecTkHome/edit.gif
	image create photo 1D -file $SpecTkHome/1D.gif
	image create photo 2D -file $SpecTkHome/2D.gif
	image create photo Summary -file $SpecTkHome/Summary.gif
	image create photo Bitmask -file $SpecTkHome/Bitmask.gif
	image create photo Gamma1D -file $SpecTkHome/G1.gif
	image create photo Gamma2D -file $SpecTkHome/G2.gif
	image create photo Node -file $SpecTkHome/Node.gif
	image create photo Open -file $SpecTkHome/Open.gif
	image create photo Close -file $SpecTkHome/Closed.gif
	image create photo Communicate -file $SpecTkHome/Communicate.gif
	image create bitmap dot -data "
	#define blank_width 2\n
	#define blank_height 2\n
	static unsigned char blank_bits\[\] = {\n
	0x03, 0x03};"
	image create bitmap plus -data "
	#define plus_width 5\n
	#define plus_height 5\n
	static unsigned char plus_bits\[\] = {\n
	0x04, 0x04, 0x1F, 0x04, 0x04};"
	image create bitmap minus -data "
	#define minus_width 5\n
	#define minus_height 5\n
	static unsigned char minus_bits\[\] = {\n
	0x00, 0x00, 0x1F, 0x00, 0x00};"
	image create bitmap sigma -data "
	#define sigma_width 5\n
	#define sigma_height 5\n
	static unsigned char sigma_bits\[\] = {\n
	0x1F, 0x02, 0x04, 0x02, 0x1F};"
	image create bitmap cross -data "
	#define cross_width 5\n
	#define cross_height 5\n
	static unsigned char cross_bits\[\] = {\n
	0x11, 0x0A, 0x04, 0x0A, 0x11};"
	image create bitmap leftarrow -data "
	#define leftarrow_width 5\n
	#define leftarrow_height 5\n
	static unsigned char leftarrow_bits\[\] = {\n
	0x10, 0x1C, 0x1F, 0x1C, 0x10};"
	image create bitmap rightarrow -data "
	#define rightarrow_width 5\n
	#define rightarrow_height 5\n
	static unsigned char rightarrow_bits\[\] = {\n
	0x01, 0x07, 0x1F, 0x07, 0x01};"
	blt::bitmap define diamond {
	#define diamond_width 7
	#define diamond_height 7
	#define diamond_x_hot 4
	#define diamond_y_hot 4
	static unsigned char diamond_bits[] = {
	0x08, 0x1C, 0x3E, 0x7F, 0x3E, 0x1C, 0x08};
	}
}

proc SetupButtons {} {
	global spectk
# Select frame
	set spectk(selectMode) single
	set w $spectk(buttons).select
	frame $w -borderwidth 2 -relief groove
	label $w.title -text "Select Mode" -font "generalbold"
	radiobutton $w.single -text Single -variable spectk(selectMode) -value single -font "general" -command DoSelectMode
	radiobutton $w.all -text All -variable spectk(selectMode) -value all -font "general" -command DoSelectMode
	radiobutton $w.row -text Row -variable spectk(selectMode) -value row -font "general" -command DoSelectMode
	radiobutton $w.column -text Column -variable spectk(selectMode) -value column -font "general" -command DoSelectMode
	grid $w.title - -sticky news
	grid $w.single $w.all -sticky w
	grid $w.column $w.row -sticky w
#	grid $w -column 0 -row 0 -sticky nsw
	pack $w -side left -expand 1 -fill y -anchor w
# Spectrum frame
	set spectk(autoUpdate) 0
	set spectk(autoPeriod) 2
	set w $spectk(buttons).spectrum
	frame $w -borderwidth 2 -relief groove
#	label $w.title -text Graph -font "generalbold"
	button $w.clearpage -text "Clear Page" -font "general" -command ClearPage
	button $w.clearall -text "Clear All" -font "general" -command ClearAll
	button $w.clearselected -text "Clear Selected" -font "general" -command ClearSelected
	button $w.updatepage -text "Update Page" -font "generalbold" -command UpdatePage
	button $w.updateselected -text "Update Selected" -font "generalbold" -command UpdateSelected
	button $w.updateall -text "Update All" -font "generalbold" -command UpdateAll
#	frame $w.autoupdate
#		checkbutton $w.autoupdate.toggle -text Auto -font "general" -command AutoUpdateSpectra \
		-variable spectk(autoUpdate)
#		entry $w.autoupdate.value -textvariable spectk(autoPeriod) -width 4 -background white
#		label $w.autoupdate.s -text s -font "general"
#	pack $w.autoupdate.toggle $w.autoupdate.value $w.autoupdate.s -side left
	frame $w.ll
		button $w.ll.log -text Log  -font "general" -command "SetScale SetLog"
		button $w.ll.lin -text Lin  -font "general" -command "SetScale SetLin"
	grid $w.ll.log $w.ll.lin -sticky news
	grid columnconfigure $w.ll "0 1" -weight 1
	frame $w.pm
		button $w.pm.plus -width 0 -text + -font "general" -command "SetScale ExpandPlus"
		button $w.pm.minus -width 0 -text - -font "general" -command "SetScale ExpandMinus"
		button $w.pm.autoscale -width 4 -text Auto -font "general" -command "SetScale ExpandAuto"
	grid $w.pm.minus $w.pm.autoscale $w.pm.plus -sticky news
	grid columnconfigure $w.pm "0 1 2" -weight 1
	frame $w.zo
		button $w.zo.shrink -width 0 -text >|< -font "general" -command "SetScale ZoomShrink"
		button $w.zo.expand -width 0 -text <|> -font "general" -command "SetScale ZoomExpand"
		button $w.zo.unzoom -width 0 -text |_| -font "general" -command "SetScale UnZoom"
	grid $w.zo.shrink $w.zo.unzoom $w.zo.expand -sticky news
	grid columnconfigure $w.zo "0 1 2" -weight 1
	grid $w.clearselected $w.updateselected $w.ll -sticky news
	grid $w.clearpage $w.updatepage $w.pm -sticky news
	grid $w.clearall $w.updateall $w.zo -sticky news
#	grid $w -column 1 -row 0 -sticky nsw
	pack $w -side left -expand 1 -fill y -anchor w
# Print frame
	set w $spectk(buttons).print
	frame $w -borderwidth 2 -relief groove
	button $w.printdisplay -text "Print Display" -font "general" -command PrintDisplayButton
	button $w.printpage -text "Print Page" -font "general" -command PrintPageButton
	pack $w.printdisplay $w.printpage -expand 1 -fill both
	pack $w -side left -anchor w -expand 1 -fill y
# Drawer button
	set w $spectk(buttons).drawer
	frame $w -borderwidth 2 -relief groove
#	label $w.title -text Drawer -font "generalbold"
	button $w.button -text "Open\n\nDrawer" -font "general" \
	-command OpenCloseDrawer -justify center
	button $w.expand -text <> -font "general" -command ExpandDrawer -justify center
	button $w.shrink -text >< -font "general" -command ShrinkDrawer -justify center
	grid $w.button - -sticky news
	grid $w.shrink $w.expand -sticky news
#	pack $w.button -side top -expand 1 -fill both
	
#	grid $w -column 2 -row 0 -sticky nse
	pack $w -side right -expand 1 -fill y -anchor e -before $spectk(buttons).select
}

proc SetupInfo {} {
	global spectk
	set w $spectk(info)
	set w $spectk(info).s
	set spectk(spectruminfo) ""
	frame $w
	label $w.label -text Spectrum: -width 8 -font "general" -justify left -anchor w
	label $w.value -textvariable spectk(spectruminfo) -width 15 -font "generalbold" -justify left -anchor w
	pack $w.label $w.value -side left -anchor w
	set spectk(xvalue) ""
	set spectk(xunit) ""
	set w $spectk(info).x
	frame $w
	label $w.label -text X: -width 2 -font "general" -justify left -anchor w
	label $w.value -textvariable spectk(xvalue) -width 8 -font "generalbold" -justify left -anchor w
	label $w.unit -textvariable spectk(xunit) -width 8 -font "generalbold" -justify left -anchor w
	pack $w.label $w.value $w.unit -side left -anchor w
	set spectk(yvalue) ""
	set spectk(yunit) ""
	set w $spectk(info).y
	frame $w
	label $w.label -text Y: -width 2 -font "general" -justify left -anchor w
	label $w.value -textvariable spectk(yvalue) -width 8 -font "generalbold" -justify left -anchor w
	label $w.unit -textvariable spectk(yunit) -width 8 -font "generalbold" -justify left -anchor w
	pack $w.label $w.value $w.unit -side left -anchor w
	set spectk(vvalue) ""
	set spectk(vunit) ""
	set w $spectk(info).v
	frame $w
	label $w.label -text Value: -width 6 -font "general" -justify left -anchor w
	label $w.value -textvariable spectk(vvalue) -width 8 -font "generalbold" -justify left -anchor w
	label $w.unit -textvariable spectk(vunit) -width 8 -font "generalbold" -justify left -anchor w
	pack $w.label $w.value $w.unit -side left -anchor w
	set w $spectk(info)
	pack $w.s $w.x $w.y $w.v -side left -expand 1 -fill x
}

proc CreateFontDialog {} {
	global spectk
	toplevel .spectkfont
	wm title .spectkfont "SpecTk Font Dialog"
	set families [font families]
	foreach f $families {if {[llength $f] == 1} {lappend familles $f}}
	set familles [lsort -dictionary $familles]
	set spectk(generalFamily) [font configure general -family]
	set spectk(generalSize) [font configure general -size]
	set spectk(treeFamily) [font configure tree -family]
	set spectk(treeSize) [font configure tree -size]
	set spectk(resultsFamily) [font configure results -family]
	set spectk(resultsSize) [font configure results -size]
	set spectk(graphsFamily) [font configure graphs1 -family]
	set spectk(graphsSize) [font configure graphs1 -size]
	set spectk(graphlabelsFamily) [font configure graphlabels -family]
	set spectk(graphlabelsSize) [font configure graphlabels -size]
	set spectk(roiresultsFamily) [font configure roiresults -family]
	set spectk(roiresultsSize) [font configure roiresults -size]

	set w .spectkfont.main
	frame $w -borderwidth 2 -relief groove

	label $w.label1 -text General: -anchor w -font "helvetica -12 bold"
	label $w.lfamily1 -text Family -anchor w -font "helvetica -12"
	menubutton $w.family1 -textvariable spectk(generalFamily) -menu $w.family1.choice -anchor w -font "helvetica -12"
	menu $w.family1.choice -tearoff 0
	foreach f $familles {
		$w.family1.choice add radiobutton -label $f -variable spectk(generalFamily) -value $f \
		-command "SetFont general" -font "helvetica -12"
	}
	label $w.lsize1 -text Size -anchor w -font "helvetica -12"
	button $w.psize1 -text + -command "IncrementFont general" -font "helvetica -12"
	label $w.size1 -textvariable spectk(generalSize) -font "helvetica -12"
	button $w.msize1 -text - -command "DecrementFont general" -font "helvetica -12"
	grid $w.label1 $w.lfamily1 $w.family1 $w.lsize1 $w.psize1 $w.size1 $w.msize1 -sticky news

	label $w.label2 -text "Spectrum Tree:" -anchor w -font "helvetica -12 bold"
	label $w.lfamily2 -text Family -anchor w -font "helvetica -12"
	menubutton $w.family2 -textvariable spectk(treeFamily) -menu $w.family2.choice -anchor w -font "helvetica -12"
	menu $w.family2.choice -tearoff 0
	foreach f $familles {
		$w.family2.choice add radiobutton -label $f -variable spectk(treeFamily) -value $f \
		-command "SetFont tree" -font "helvetica -12"
	}
	label $w.lsize2 -text Size -anchor w -font "helvetica -12"
	button $w.psize2 -text + -command "IncrementFont tree" -font "helvetica -12"
	label $w.size2 -textvariable spectk(treeSize) -font "helvetica -12"
	button $w.msize2 -text - -command "DecrementFont tree" -font "helvetica -12"
	grid $w.label2 $w.lfamily2 $w.family2 $w.lsize2 $w.psize2 $w.size2 $w.msize2 -sticky news

	label $w.label3 -text "Calculation Results:" -anchor w -font "helvetica -12 bold"
	label $w.lfamily3 -text Family -anchor w -font "helvetica -12"
	menubutton $w.family3 -textvariable spectk(resultsFamily) -menu $w.family3.choice -anchor w -font "helvetica -12"
	menu $w.family3.choice -tearoff 0
	foreach f $familles {
		$w.family3.choice add radiobutton -label $f -variable spectk(resultsFamily) -value $f \
		-command "SetFont results" -font "helvetica -12"
	}
	label $w.lsize3 -text Size -anchor w -font "helvetica -12"
	button $w.psize3 -text + -command "IncrementFont results" -font "helvetica -12"
	label $w.size3 -textvariable spectk(resultsSize) -font "helvetica -12"
	button $w.msize3 -text - -command "DecrementFont results" -font "helvetica -12"
	grid $w.label3 $w.lfamily3 $w.family3 $w.lsize3 $w.psize3 $w.size3 $w.msize3 -sticky news

	label $w.label4 -text "Graphs:" -anchor w -font "helvetica -12 bold"
	label $w.lfamily4 -text Family -anchor w -font "helvetica -12"
	menubutton $w.family4 -textvariable spectk(graphsFamily) -menu $w.family4.choice -anchor w -font "helvetica -12"
	menu $w.family4.choice -tearoff 0
	foreach f $familles {
		$w.family4.choice add radiobutton -label $f -variable spectk(graphsFamily) -value $f \
		-command "SetFont graphs" -font "helvetica -12"
	}
	label $w.lsize4 -text Size -anchor w -font "helvetica -12"
	button $w.psize4 -text + -command "IncrementFont graphs" -font "helvetica -12"
	label $w.size4 -textvariable spectk(graphsSize) -font "helvetica -12"
	button $w.msize4 -text - -command "DecrementFont graphs" -font "helvetica -12"
	grid $w.label4 $w.lfamily4 $w.family4 $w.lsize4 $w.psize4 $w.size4 $w.msize4 -sticky news

	label $w.label5 -text "Graph Labels:" -anchor w -font "helvetica -12 bold"
	label $w.lfamily5 -text Family -anchor w -font "helvetica -12"
	menubutton $w.family5 -textvariable spectk(graphlabelsFamily) -menu $w.family5.choice -anchor w -font "helvetica -12"
	menu $w.family5.choice -tearoff 0
	foreach f $familles {
		$w.family5.choice add radiobutton -label $f -variable spectk(graphlabelsFamily) -value $f \
		-command "SetFont graphlabels" -font "helvetica -12"
	}
	label $w.lsize5 -text Size -anchor w -font "helvetica -12"
	button $w.psize5 -text + -command "IncrementFont graphlabels" -font "helvetica -12"
	label $w.size5 -textvariable spectk(graphlabelsSize) -font "helvetica -12"
	button $w.msize5 -text - -command "DecrementFont graphlabels" -font "helvetica -12"
	grid $w.label5 $w.lfamily5 $w.family5 $w.lsize5 $w.psize5 $w.size5 $w.msize5 -sticky news

	label $w.label6 -text "Graph Results:" -anchor w -font "helvetica -12 bold"
	label $w.lfamily6 -text Family -anchor w -font "helvetica -12"
	menubutton $w.family6 -textvariable spectk(roiresultsFamily) -menu $w.family6.choice -anchor w -font "helvetica -12"
	menu $w.family6.choice -tearoff 0
	foreach f $familles {
		$w.family6.choice add radiobutton -label $f -variable spectk(roiresultsFamily) -value $f \
		-command "SetFont roiresults" -font "helvetica -12"
	}
	label $w.lsize6 -text Size -anchor w -font "helvetica -12"
	button $w.psize6 -text + -command "IncrementFont roiresults" -font "helvetica -12"
	label $w.size6 -textvariable spectk(roiresultsSize) -font "helvetica -12"
	button $w.msize6 -text - -command "DecrementFont roiresults" -font "helvetica -12"
	grid $w.label6 $w.lfamily6 $w.family6 $w.lsize6 $w.psize6 $w.size6 $w.msize6 -sticky news
	pack $w -expand 1 -fill both
	
	set w .spectkfont.buttons
	frame $w
	button $w.dismiss -text Dismiss -command "destroy .spectkfont"
	grid $w.dismiss -sticky news
	pack $w -expand 1 -fill both
}

proc SetFont {category} {
	global spectk
	switch -- $category {
		general {
			font configure general -family $spectk(generalFamily) -size $spectk(generalSize)
			font configure generalbold -family $spectk(generalFamily) -size $spectk(generalSize)
			font configure smaller -family $spectk(generalFamily) -size [expr $spectk(generalSize)+2]
			font configure smallerbold -family $spectk(generalFamily) -size [expr $spectk(generalSize)+2]
		}
		tree {
			font configure tree -family $spectk(treeFamily) -size $spectk(treeSize)
			font configure treebold -family $spectk(treeFamily) -size $spectk(treeSize)
		}
		results {
			font configure results -family $spectk(resultsFamily) -size $spectk(resultsSize)
		}
		graphs {
			font configure graphs1 -family $spectk(graphsFamily) -size $spectk(graphsSize)
			font configure graphs2 -family $spectk(graphsFamily) -size [expr $spectk(graphsSize)-1]
			font configure graphs3 -family $spectk(graphsFamily) -size [expr $spectk(graphsSize)-3]
			font configure graphs4 -family $spectk(graphsFamily) -size [expr $spectk(graphsSize)-5]
		}
		graphlabels {
			font configure graphlabels -family $spectk(graphlabelsFamily) -size $spectk(graphlabelsSize)
		}
		roiresults {
			font configure roiresults -family $spectk(roiresultsFamily) -size $spectk(roiresultsSize)
		}
	}
}

proc IncrementFont {category} {
	global spectk
	set name [format %s%s $category Size]
	incr spectk($name) -1
	if {$spectk($name) < -24} {set spectk($name) -24}
	SetFont $category
}

proc DecrementFont {category} {
	global spectk
	set name [format %s%s $category Size]
	incr spectk($name)
	if {$spectk($name) > -6} {set spectk($name) -6}
	SetFont $category
}

proc SetMacintoshOptions {} {
	global spectk
}

proc SetLinuxOptions {} {
	global spectk
}

proc SetWindowsOptions {} {
	global spectk
}

proc AssignAll {} {
	global spectk
	DisableUpdate
# for each page of our display
	foreach tab [$spectk(pages) tab names] {
		set frame [$spectk(pages) tab cget $tab -window]
		set page [lindex [split $frame .] end]
# for each pane of the page
		for {set ir 0} {$ir < [$page GetMember rows]} {incr ir} {
			for {set ic 0} {$ic < [$page GetMember columns]} {incr ic} {
				set disp [format "%sR%dC%d" $page $ir $ic]
# if the display doesnÕt exists, there is nothing to display
				if {[lsearch [itcl::find objects] $disp] == -1} {continue}
# if the display exists and so does the graph, just update the display
				if {[winfo exists [$disp GetMember graph]]} {
					$disp Update
					continue
				}
# if the display doesnÕt exist, check to see if the spectrum is in the spectrum list
				set id [format "R%dC%d" $ir $ic]
				set waves [$disp GetMember waves]
				set i 0
				foreach w $waves {
					if {[$disp isa Display1D]} {set s [string trimleft $w ::Wave1D::]}
					if {[$disp isa Display2D]} {set s [string trimleft $w ::Wave2D::]}
# if spectrum found in list, assign or append to the display
					if {[lsearch $spectk(spectrumList) $s] != -1} {
						set spectk(spectrum) $s
						if {$i == 0} {$page AssignSpectrum $id}
						if {$i > 0} {$page AppendSpectrum $id}
						incr i
					}
				}
			}
		}
	}
	EnableUpdate
}

proc UpdateAll {} {
	global spectk
	DisableUpdate
	foreach tab [$spectk(pages) tab names] {
		set frame [$spectk(pages) tab cget $tab -window]
		set page [lindex [split $frame .] end]
		$page Update
	}
	EnableUpdate
#	if {$spectk(autoUpdate)} {
#		set spectk(autoCancel) [after [expr $spectk(autoPeriod)*1000] UpdateAllSpectra]
#	}
}

proc UpdatePage {} {
	global spectk
	set tab [$spectk(pages) id select]
	if {[string equal $tab ""]} {return}
	DisableUpdate
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split $frame .] end]
	$page Update
	EnableUpdate
#	if {$spectk(autoUpdate)} {
#		set spectk(autoCancel) [after [expr $spectk(autoPeriod)*1000] UpdatePage]
#	}
}

proc UpdateSelected {} {
	global spectk
	set objects [itcl::find objects]
	set tab [$spectk(pages) id select]
	if {[string equal $tab ""]} {return}
	DisableUpdate
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split $frame .] end]
	foreach id [$page GetMember selected] {
		set display [format "%s%s" $page $id]
		set index [lsearch $objects $display]
		if {$index >= 0} {$display Update}
	}
	EnableUpdate
}

proc AutoUpdateSpectra {} {
	global spectk
	if {$spectk(autoUpdate)} {
		set spectk(autoCancel) [after [expr $spectk(autoPeriod)*1000] UpdateAllSpectra]
	} else {
		after cancel $spectk(autoCancel)
	}
}

proc DisableUpdate {} {
	global spectk
	set w $spectk(buttons).spectrum
	$w.updateall configure -state disabled
	$w.updatepage configure -state disabled
	$w.updateselected configure -state disabled
#	after 1000 EnableUpdate
}

proc EnableUpdate {} {
	global spectk
	set w $spectk(buttons).spectrum
	$w.updateall configure -state normal
	$w.updatepage configure -state normal
	$w.updateselected configure -state normal
}

proc ClearAll {} {
# SpecTcl Clear All
	clear -all
}

proc ClearPage {} {
	global spectk
	set objects [itcl::find objects]
	set tab [$spectk(pages) id select]
	if {[string equal $tab ""]} {return}
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split $frame .] end]
	set rows [$page GetMember rows]
	set columns [$page GetMember columns]
	for {set ir 0} {$ir < $rows} {incr ir} {
		for {set ic 0} {$ic < $columns} {incr ic} {
			set id [format "R%dC%d" $ir $ic]
			set display [format "%s%s" $page $id]
			set index [lsearch $objects $display]
			if {$index >= 0} {
				set waves [$display GetMember waves]
				foreach w $waves {$w Clear}
			}
		}
	}
}

proc ClearSelected {} {
	global spectk
	set objects [itcl::find objects]
	set tab [$spectk(pages) id select]
	if {[string equal $tab ""]} {return}
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split $frame .] end]
	foreach id [$page GetMember selected] {
		set display [format "%s%s" $page $id]
		set index [lsearch $objects $display]
		if {$index >= 0} {
			set waves [$display GetMember waves]
			foreach w $waves {$w Clear}
		}
	}
}

proc SetScale {command} {
	global spectk
	set objects [itcl::find objects]
	set tab [$spectk(pages) id select]
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split $frame .] end]
	foreach id [$page GetMember selected] {
		set display [format "%s%s" $page $id]
		set index [lsearch $objects $display]
		if {$index >= 0} {$display $command}
	}
}

proc DoSelectMode {} {
	global spectk
	foreach tab [$spectk(pages) tab names] {
		set frame [$spectk(pages) tab cget $tab -window]
		set page [lindex [split $frame .] end]
		set current [$page GetMember current]
		$page SelectDisplay $current 1
	}
}

proc DeleteAllObjects {} {
#	global spectk
	foreach f [itcl::find object -isa Fit] {itcl::delete object $f}
	foreach r [itcl::find object -isa ROI] {itcl::delete object $r}
	foreach w [itcl::find object -isa Wave1D] {itcl::delete object $w}
	foreach w [itcl::find object -isa Wave2D] {itcl::delete object $w}
	foreach p [itcl::find object -isa Page] {itcl::delete object $p}
#	foreach c [winfo children $spectk(pages)] {destroy $c}
}

proc NewConfiguration {} {
	DeleteAllObjects
}

proc LoadConfiguration {config} {
	global spectk
	global List
	if {![info exist spectk(loaddir)]} {set spectk(loaddir) ""}
	if {[string equal $config ""]} {
		set config [tk_getOpenFile -title "Select a SpecTk configuration file" \
		-filetypes {{"SpecTk Configuration File" {.spk}}} \
		-initialdir $spectk(loaddir)]
	}
	if {[string equal $config ""]} {return}
	set f [lindex [split $config /] end]
	set spectk(loaddir) [string trimright $config $f]
	DeleteAllObjects
# Keep drawer state
	set drawer $spectk(draweropen)
	source $config
	set spectk(draweropen) $drawer
# Update spectrum list
	set spectk(spectrumList) ""
	foreach s [spectrum -list] {
		set name [lindex $s 1]
		lappend spectk(spectrumList) $name
	}
# Process all objects

	set fr [open $spectk(configName) r]
	$List readList $fr
	set pages [$List getPages]

	foreach w [itcl::find object -isa Wave1D] {$w Read}
	foreach w [itcl::find object -isa Wave2D] {$w Read}
	foreach d [itcl::find object -isa Display1D] {$d Read}
	foreach d [itcl::find object -isa Display2D] {$d Read}
	foreach r [itcl::find object -isa ROI] {$r Read}
	foreach p [$List getPages] {$p Read}
	UpdateAll
	if {[info exist spectk(geometry)] && $spectk(resizeWindow)} {wm geometry . $spectk(geometry)}
	EnableHelp
	StoreRecentFile $config
	UpdateRecentFileMenu
	wm title . "SpecTk $spectk(version) ($config)"
}

proc UpdateRecentFileMenu {} {
	global spectk
	set w $spectk(menubar).file
	$w.recent delete 0 end
	if {[info exist spectk(recentfiles)]} {
		foreach f $spectk(recentfiles) {
			$w.recent insert 0 command -label $f -command "LoadConfiguration $f"
		}
	}
}

proc StoreRecentFile {config} {
	global spectk
	if {![info exist spectk(recentfiles)]} {
		set spectk(recentfiles) $config
	} else {
		if {[set index [lsearch $spectk(recentfiles) $config]] == -1} {
			lappend spectk(recentfiles) $config
		} else {
			set spectk(recentfiles) [lreplace $spectk(recentfiles) $index $index]
			lappend spectk(recentfiles) $config
		}
		if {[llength $spectk(recentfiles)] > 10} {
			set spectk(recentfiles) [lreplace $spectk(recentfiles) 0 0]
		}
	}
	set f [open SpecTkRecentFiles.tcl w]
	puts $f "set spectk(recentfiles) \"$spectk(recentfiles)\""
	close $f
}

proc UpdateRecentServerMenu {} {
	global spectk
	set w $spectk(menubar).spectk
	$w.recent delete 0 end
	if {[info exist spectk(recentservers)]} {
		foreach s $spectk(recentservers) {
			scan $s "Server: %s - Port: %d" name port
			$w.recent insert 0 command -label $s -command "ConnectToServer $name $port"
		} 
	}
}

proc StoreRecentServer {config} {
	global spectk SpecTkHome
	set str "Server: [lindex $config 0] - Port: [lindex $config 1]"
	if {![info exist spectk(recentservers)]} {
		lappend spectk(recentservers) $str
	} else {
		if {[set index [lsearch $spectk(recentservers) $str]] == -1} {
			lappend spectk(recentservers) $str
		} else {
			set spectk(recentservers) [lreplace $spectk(recentservers) $index $index]
			lappend spectk(recentservers) $str
		}
		if {[llength $spectk(recentservers)] > 10} {
			set spectk(recentservers) [lreplace $spectk(recentservers) 0 0]
		}
	}
	set f [open $SpecTkHome/SpecTkRecentServers.tcl w]
	puts $f $spectk(recentservers)
	close $f
}

proc SaveConfiguration {} {
	global spectk
	foreach n [array names spectk] {
		if {[string match *Family* $n]} {lappend forbidden $n}
		if {[string match *Size* $n]} {lappend forbidden $n}
		if {[string match *print* $n]} {lappend forbidden $n}
	}
	lappend forbidden version drawerEffect resizeWindow smartmenu smartprevious preferences
	lappend forbidden pageUpdate autoscale
	set spectk(geometry) [wm geometry .]
	set f [open $spectk(configName) w]
	puts $f "# SpecTk configuration written on [clock format [clock seconds]]"
	
	global List
	set fr [open $spectk(configName) r]
	$List getPages
	$List writeList $f $fr

	foreach n [array names spectk] {
		if {[lsearch $forbidden $n] == -1} {puts $f "set spectk($n) \"$spectk($n)\""}
	}
	foreach d [itcl::find object -isa Display1D] {
		if {[llength [$d GetMember waves]] == 0} {itcl::delete object $d}
	}
	foreach d [itcl::find object -isa Display2D] {
		if {[llength [$d GetMember waves]] == 0} {itcl::delete object $d}
	}
	foreach p [$List getPages] {$p Write $f}
	foreach d [itcl::find object -isa Display1D] {$d Write $f}
	foreach d [itcl::find object -isa Display2D] {$d Write $f}
	foreach w [itcl::find object -isa Wave1D] {$w Write $f}
	foreach w [itcl::find object -isa Wave2D] {$w Write $f}
	foreach r [itcl::find object -isa ROI] {
		if {![$r GetMember isgate]} {$r Write $f}
	}
	close $f
}

proc SaveAsConfiguration {} {
	global spectk
	if {![info exist spectk(savedir)]} {set spectk(savedir) ""}
	set initialfile [lindex [split $spectk(configName) /] end]
	set config [tk_getSaveFile -title "Enter a SpecTk configuration file name" \
	-defaultextension .spk \
	-filetypes {{"SpecTk Configuration File" {.spk}}} \
	-initialdir $spectk(savedir) \
	-initialfile $initialfile]
	if {[string equal $config ""]} {return}
	set f [lindex [split $config /] end]
	set spectk(savedir) [string trimright $config $f]
	set spectk(configName) $config
	SaveConfiguration
	wm title . "SpecTk $spectk(version) ($config)"
}

proc SaveOptions {} {
	global spectk
	foreach n [array names spectk] {
		if {[string match *Family* $n]} {lappend forbidden $n}
		if {[string match *Size* $n]} {lappend forbidden $n}
		if {[string match *print* $n]} {lappend forbidden $n}
	}
	lappend forbidden resizeWindow smartmenu
	lappend forbidden pageUpdate autoscale
	set file [open SpecTkOptions.tcl w]
	puts $file "# SpecTk options written on [clock format [clock seconds]]"
	foreach n $forbidden {
		puts $file "set spectk($n) \"$spectk($n)\""
	}
	close $file
}
	
proc LoadOptions {} {
	global spectk
	if {[file exist SpecTkOptions.tcl]} {
		source SpecTkOptions.tcl
		foreach font "general tree results graphs graphlabels roiresults" {SetFont $font}
	}
}

proc ExitSpecTk {} {
	global spectk
	if {![string equal [itcl::find classes Fit] ""]} {itcl::delete class Fit}
	if {![string equal [itcl::find classes Page] ""]} {itcl::delete class Page}
	if {![string equal [itcl::find classes ROI] ""]} {itcl::delete class ROI}
	if {![string equal [itcl::find classes Wave1D] ""]} {itcl::delete class Wave1D}
	if {![string equal [itcl::find classes Display1D] ""]} {itcl::delete class Display1D}
	if {![string equal [itcl::find classes Wave2D] ""]} {itcl::delete class Wave2D}
	if {![string equal [itcl::find classes Display2D] ""]} {itcl::delete class Display2D}
	if {![string equal [itcl::find classes Palette] ""]} {itcl::delete class Palette}
	destroy .
}

proc reorderDisplay {pageList} {
    	 global List
   	 toplevel .pages
   	 wm title .pages "Reorder Window"

   	 set options [list]
   	 for {set i 1} {$i <= [llength $pageList]} {incr i} {
   		 lappend options $i
   	 }

   	 set i 0
    	 set names [$List listName]
  	 foreach page $pageList {
   		 frame .pages.frame_$page
   		 set position [expr {$i + 1}]  ;# Calculate the position (starting from 1)
   		 set selectedOptionVar(selectedOption_$page) $position
   		 incr i
   		 label .pages.label_$page -text "[lindex $names [expr $i-1]] Position:"
   		 ttk::combobox .pages.dropdown_$page -values $options -textvariable selectedOptionVar(selectedOption_$page) -state readonly
   		 pack .pages.frame_$page -side top -fill x
   		 pack .pages.label_$page -side top -padx 10
   		 pack .pages.dropdown_$page -side top -padx 10
   		 .pages.dropdown_$page current [expr {$position-1}]  ;# Set the default value
   	 }

   	 button .pages.goButton -text "Go" -command [list goReOrder $pageList]
   	 pack .pages.goButton -side bottom -pady 10
}

proc goReOrder {pageList} {
	global spectk
	global List
	set selectedValues [list]
	foreach page $pageList {
		lappend selectedValues [.pages.dropdown_$page get]
	}
	set bool [$List checkList $selectedValues]
	if {$bool == 1} {
		$List reOrder $selectedValues
		SaveConfiguration
		LoadConfiguration $spectk(configName)

		destroy .pages
	}
}

proc initReorder {} {

	global spectk
	global List
	set fr [open $spectk(configName) r]
	set pages [$List getPages2 $fr]
	reorderDisplay $pages

}

proc alphabeticalTab {} {
	global spectk
	global List
	set fr [open $spectk(configName) r]
	$List getPages2 $fr
	$List alphaPage
	SaveConfiguration
	LoadConfiguration $spectk(configName)
	
}

SetupSpecTk
