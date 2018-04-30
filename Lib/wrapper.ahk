IniRead(_fileName, _section:="", _key:="", _default:="ERROR") {
	IniRead, _outputVar, %_fileName%, %_section%, %_key%, %_default%
return _outputVar, ErrorLevel := (ErrorLevel = _default)
}
WinWait(_winTitle:="", _winText:="", _seconds:="", _excludeTitle:="", _excludeText:="") {
	WinWait, %_winTitle%, %_winText%, %_seconds%, %_excludeTitle%, %_excludeText%
return (ErrorLevel) ? false : WinExist()
}
WinWaitActive(_winTitle:="", _winText:="", _seconds:="", _excludeTitle:="", _excludeText:="") {
	WinWait, %_winTitle%, %_winText%, %_seconds%, %_excludeTitle%, %_excludeText%
return (ErrorLevel) ? false : WinExist()
}
WinGet(_command, _winTitle:="", _winText:="", _excludeTitle:="", _excludeText:="") {
	WinGet, _outputVar, %_command%, %_winTitle%, %_winText%, %_excludeTitle%, %_excludeText%
return _outputVar
}
WinSet(_attribute, _value:="", _winTitle:="", _winText:="", _excludeTitle:="", _excludeText:="") {
WinSet, %_attribute%, %_value%, %_winTitle%, %_winText%, %_excludeTitle%, %_excludeText%
}
MouseGetPos(ByRef _outputVarX:="", ByRef _outputVarY:="", ByRef _outputVarWin:="", ByRef _outputVarControl:="", _mode:="") {
MouseGetPos, _outputVarX, _outputVarY, _outputVarWin, _outputVarControl, %_mode%
}
Random(_min:="", _max:="") {
Random, _r, %_min%, %_max%
return _r
}
RegRead(_regKey, _valueName) {
RegRead, _var, %_regKey%, %_valueName% ; v1.1.21+
return _var
}
WinActivate(_winTitle:="", _winText:="", _excludeTitle:="", _excludeText:="") {
WinActivate, %_winTitle%, %_winText%, %_excludeTitle%, %_excludeText%
}
Click() {
Click
}
GroupActivate(_groupName, _r:="") {
GroupActivate % _groupName, % _r
}
ControlGet(_cmd, _value:="", _control:="", _winTitle:="") {
ControlGet, _outputVar, %_cmd%, %_value%, %_control%, %_winTitle%
return _outputVar
}
SendMessage(_msg, _wParam:="", _lParam:="", _control:="", _winTitle:="", _winText:="", _excludeTitle:="", _excludeText:="", _timeout:="") {
SendMessage %_msg%, %_wParam%, %_lParam%, %_control%, %_winTitle%, %_winText%, %_excludeTitle%, %_excludeText%, %_timeout%
_msgReply := (ErrorLevel = "FAIL") ? "" : ErrorLevel, ErrorLevel := (ErrorLevel = "FAIL")
return _msgReply
} ; commands as functions (AHK v2 functions for AHK v1) - AutoHotkey Community (https://autohotkey.com/boards/viewtopic.php?f=37&t=29689)