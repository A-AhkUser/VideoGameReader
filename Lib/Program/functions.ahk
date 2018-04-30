In(_matchList, _var) {
If _var in %_matchList%
	return true
return false
}
Between(_lowerBound, _upperBound, _var) {
If _var between %_lowerBound% and %_upperBound%
	return true
return false
}
Is(_type, _var) {
If _var is %_type%
	return true
return false
}
deref(_v) {
return (%_v%)
}
; cf https://github.com/Run1e/Vibrancer/blob/master/lib/Class%20HTTP.ahk
request(_url, ByRef _outData:="", ByRef _headers:="", _timeout:=5) {

	_request := ComObjCreate("Msxml2.XMLHTTP")

	; if not (DllCall("WinINet.dll\InternetCheckConnectionW", "Str", _url, "UInt", 1, "UInt", 0))
	if not (DllCall("Wininet.dll\InternetGetConnectedState", "Str", "0x40", "Int", 0)) ; INTERNET_CONNECTION_PROXY
		return !ErrorLevel:=-3

	try _request.Open("GET", _url, true)
	catch {
		return !ErrorLevel:=-2
	}
	if (IsObject(_headers))
		for _header, _value in _headers
			_request.SetRequestHeader(_header, _value)
	else _request.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded")
	_request.Send()

	_timeout := round(_timeout) * 4
	Loop {
	sleep, 250
	} Until ((_boolean:=(a_index > _timeout)) or _request.readyState = 4)
	if not (_boolean) {
		_outData := {"ResponseText":_request.ResponseText, "Status":_request.Status, "StatusText":_request.StatusText}
		_headers := (!InStr(_h:=_request.GetAllResponseHeaders(), "`n:") and IsObject(_o:=Object(StrSplit(_h, ["`n", ":"])*))) ? _o : ""
	}
	return !ErrorLevel:=-_boolean

}

Menu_GetItemName(_hMenu, _itemPos) { ; https://autohotkey.com/boards/viewtopic.php?t=3068
   ; http://msdn.microsoft.com/en-us/library/ms647983(v=vs.85).aspx
   VarSetCapacity(_str, 1024, 0) ; should be sufficient
   If DllCall("User32.dll\GetMenuString", "Ptr", _hMenu, "UInt", _itemPos - 1, "Str", _str, "Int", 512, "UInt", 0x0400, "Int")
      Return _str
   Return ""
}

SetWinEventHook(_eventMin, _eventMax, _hmodWinEventProc, _lpfnWinEventProc, _idProcess, _idThread, _dwFlags) {
   DllCall("CoInitialize", "Uint", 0)
   return DllCall("SetWinEventHook"
			, "Uint", _eventMin
			, "Uint", _eventMax
			, "Ptr", _hmodWinEventProc
			, "Ptr", _lpfnWinEventProc
			, "Uint", _idProcess
			, "Uint", _idThread
			, "Uint", _dwFlags)
} ; cf. https://autohotkey.com/boards/viewtopic.php?t=830
UnhookWinEvent(_hWinEventHook) {
    _v := DllCall("UnhookWinEvent", "Ptr", _hWinEventHook)
    DllCall("CoUninitialize")
return _v
} ;  cf. https://autohotkey.com/boards/viewtopic.php?t=830

bind(_fn, _args*) {
return new Bound.Func(_fn, _args*)
}

concatenate(_str, _x) {
	return (_x < 1) ? "" : (_x < 2 ? _str : _str concatenate(_str, _x-1))
}
mouseIsOver(_winTitle) { ; requires 'Between'
_coordMode := A_CoordModeMouse
CoordMode, Mouse, Screen
	WinGetPos, _x, _y, _w, _h, % _winTitle
	MouseGetPos, _mouseX, _mouseY
CoordMode, Mouse, % _coordMode
return (Between(_x, _x+_w, _mouseX) && Between(_y, _y+_h, _mouseY))
}