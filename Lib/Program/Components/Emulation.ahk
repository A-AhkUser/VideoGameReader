global Emulation :=
(LTrim Join C
	{
		WORKING_DIRECTORY: A_ScriptDir . "\__Emulation",
		_configRead: Func("Emulation_configRead"),
		_configWrite: Func("Emulation_configWrite"),
		_settings: {0: [], 1: []},
		__New: Func("Emulation_New"),
		configurables: "",
		emulator: "",
		game: "",
		AHKPID: "",
		windows: [],
		_isPaused: Func("Emulation_isPaused"),
		pause: Func("Emulation_pause"),
		paused: "",
		start: Func("Emulation_start"),
		__close: Func("Emulation_onClose"),
		Init: Func("Emulation_Init")
	}
)
Emulation_Init() {
static _init := 0
IfEqual _init, 1, return _init
	Emulation.configurables := new JSONData(Emulation.WORKING_DIRECTORY . "\configurables.json")
return Emulation, _init:=!ErrorLevel
}
Emulation_configRead(this) {

	this._settings := {0: [], 1: []}
	_configFileFullPath := this._configFileFullPath
	for _each, _setting in new JSONData.Enumerator(this.emulator.config.settings) {
		IniRead, _value, % _configFileFullPath, % _setting.section, % _setting.key
		if (_value == "ERROR")
			return false
	this._settings[0].push(_value), this._settings[1].push(_setting.value)
	}
	return true

}
Emulation_configWrite(this, _param) {
_configFileFullPath := this._configFileFullPath, _params := this._settings[_param]
for _each, _setting in new JSONData.Enumerator(this.emulator.config.settings) {
	IniWrite, % _params[ a_index ], % _configFileFullPath, % _setting.section, % _setting.key
	if (ErrorLevel)
		return false
}
sleep, 50
return true
}

Emulation_New(this) {
return (Emulation.Init()) ? (this, this.onClose:="") : ""
}
Emulation_start(this, _game, _cd) {

_configurables := Emulation.configurables.data

this.game := _gameObject := ((_configurables.games)[_game])[ _cd - 1 ]
this.emulator := _emulatorObject := ((_configurables.emulation)[_gameObject.platform])[_gameObject.emulator]

	if not ((_e:=FileExist(_emulatorObject.fullPath)) and FileExist(_gameObject.fullPath))
		return false, ErrorLevel:=-3+!!_e

	this._configFileFullPath := _emulatorObject.dir . "\" . _emulatorObject.config.fileName
	if not (this._configRead() && this._configWrite(1))
		return ErrorLevel:=-1

	_CMD := _emulatorObject.CMD
	, _cmdl := _CMD.switches . A_Space . Chr(34) . _emulatorObject.fullPath . Chr(34) . A_Space
			. _CMD.flag . Chr(34) . _gameObject.fullPath . Chr(34) . A_Space . _CMD.parameters
	run % Trim(_cmdl, A_Space), % _emulatorObject.dir, UseErrorLevel, _PID
	if (ErrorLevel)
		return false, ErrorLevel:=1
	this.AHKPID := "ahk_pid " . (this.PID:=_PID)

	_critical := A_IsCritical
	_titleMatchMode := A_TitleMatchMode
	Critical
	SetTitleMatchMode, RegEx

	_windows := this.windows := []
	for _each, _window in new JSONData.Enumerator(_emulatorObject.windows) {
		for _key, _title in new JSONData.Enumerator(_window) {
			if (_ID:=WinWait(_title . A_Space . this.AHKPID,, 11))
				_windows[_key] := Object("HWND", _ID, "AHKID", "ahk_id " . _ID)
			else return false, ErrorLevel:=2
		}
	}

	SetTitleMatchMode % _titleMatchMode
	Critical % _critical

	sleep, 3000

	WinSet, Style, -0x00020000L, % _windows.mainWindow.AHKID ; WS_MINIMIZEBOX
	_WMSIParams := _emulatorObject.WMSIParams
	, _hwnd := DllCall("User32.dll\GetSubMenu", "Ptr", DllCall("User32.dll\GetMenu", "Ptr", _windows[ _WMSIParams.0 ].HWND, "Ptr"), "Int", _WMSIParams.1 - 1, "Ptr")
	, this._pauseItemStartupName := (this._pauseItemGetName:=Func("Menu_GetItemName").bind(_hwnd, _WMSIParams.2)).call()
	, this.paused := 0

	_f := this.__close.bind(this)
	SetTimer, % _f, -1500, -2147483647

return true
}
Emulation_isPaused(this) {
	_pauseItemStartupName := this._pauseItemStartupName
	if (_pauseItemStartupName = "")
		return -1
return (this._pauseItemGetName() <> _pauseItemStartupName)
}
Emulation_pause(this, _boolean:=true) {

	_WMSIParams := this.emulator.WMSIParams
	if not (WinExist(this.windows[ _WMSIParams.0 ].AHKID))
return !ErrorLevel:=1

	if ((this.paused <> _boolean) && (this._isPaused() <> this.paused:=_boolean)) {
		WinMenuSelectItem,,, % _WMSIParams.1 . "&", % _WMSIParams.2 . "&"
	}

return true
}
Emulation_onClose(this) {

	WinWaitClose % this.windows.defaultWindow.AHKID
	sleep, 100
	if (WinExist(this.windows.mainWindow.AHKID)) {
		WinSet, Style, +0x00020000L ; WS_MINIMIZEBOX
		WinSet, Enable
		WinWaitClose
	}
	sleep, 100
	this._configWrite(0)

	(this.onClose && this.onClose.call(this))

}

Emulation_dispose(this) {
this.onClose := ""
}