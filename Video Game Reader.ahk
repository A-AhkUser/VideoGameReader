/*
____________________________### VIDEO GAME READER ###____________________________

Version ..................................: 0.3 (28/04/2018)
AHK Version ...........................: 1.1.28.00 (Unicode 32-bit)
OS Version .............................: Windows 8.1
Author ...................................: Jérémy Duthois <A_AhkUser@hotmail.com>
Change history ......................:


; This software is provided 'as-is', without any express or implied warranty. In no event will the authors be held liable for any damages arising from the use of this software.
; Video Game Reader does not in any way facilitate the download of illegal ROM images or warez of any kind.
__________________________________________________________________________________
*/

#NoEnv
#SingleInstance ignore
; #NoTrayIcon
#KeyHistory 0
SendMode, Input
; SetWinDelay, 50
; SetControlDelay, 10

; #Warn

#Include %A_ScriptDir%\lib\
	#Include wrapper.ahk
#Include %A_ScriptDir%\lib\Redistribuables\
	#Include Bound.ahk ; namespace
	#Include GUI.ahk ; namespace
	#Include Hotkey.ahk ; namespace
	#Include Joystick.ahk ; namespace
#Include %A_ScriptDir%\lib\Program
	#Include JSONData.ahk ; namespace
	#Include Program.ahk ; namespace
	#Include functions.ahk
#Include %A_ScriptDir%\Lib\Program\Components\
	#Include Emulation.ahk ; namespace
	#Include Keypad.ahk ; namespace
	#Include Translation.ahk ; namespace
#Include %A_ScriptDir%\Lib\Program\UI\
	#Include subroutines.ahk

global VGR ; namespace
VGR :=
(LTrim Join C
	{
		base: Program,
		components: {
			"Emulation": Emulation,
			"Keypad": Keypad,
			"Translation": Translation
		},
		SETTINGS_FILE: A_ScriptDir . "\settings.json",
		settings: "",
		updateSettings: "VGR_updateSettings",
		hotkeys: {
			keyboard: {},
			_keyboard: {},
			joystick: {},
			_joystick: {}
		},
		setHotkeys: "VGR_setHotkeys",
		UI: {
			localization: "",
			setLanguage: "VGR_UI_setLanguage",
			About_UI: "VGR_UI_About_UI",
			Play_UI: "VGR_UI_Play_UI",
			Emulation_UI: "VGR_UI_Emulation_UI",
			Hotkeys_UI: "VGR_UI_Hotkeys_UI"
		},
		execCommandLine: "VGR_execCommandLine",
		VGRSTATUS_WAITSTART: -1,
		VGRSTATUS_IDLE: 0,
		VGRSTATUS_DEPLOYED: 1,
		getStatus: "VGR_getStatus",
		emulationStart: "VGR_emulationStart",
		Init: "VGR_Init"
	}
)
VGR.base.Debug.exceptionHandler := Func("VGR_exceptionHandler")

for component, oComponent in VGR.components {
	oComponent.WORKING_DIRECTORY := Program.APPDATA_DIRECTORY . "\Components\" . component
	oComponent.Init() VGR.base.Debug.exceptionMonitor(Exception(ErrorLevel, "VGR.components." . component . ".Init"))
	Func(component . "_customize").call()
}
Keypad := new Keypad()
VGR.base.Debug.exceptionMonitor(Exception(ErrorLevel, "VGR.components.Keypad.__New"))

OnExit("VGR_handleExit"), VGR.Init() VGR.base.Debug.exceptionMonitor(Exception(ErrorLevel, "VGR.Init"))
if (A_Args.length() <= Program.ARG_MAX)
	VGR.execCommandLine() VGR.base.Debug.exceptionMonitor(Exception(ErrorLevel, "VGR.execCommandLine"))
return


; ============================================================================================

VGR_execCommandLine() {

	_arguments := VGR.base.arguments

	if (_arguments.hasKey("game")) {

		_game := Format("{:T}", Trim(_arguments.game)), _cd := _arguments.hasKey("cd") ? _arguments.cd : 1
		try _oGame := ((Emulation.configurables.data.games)[_game])[ _cd - 1 ]
		catch
			return false ; , ErrorLevel:=-3
		_source := _oGame.language, _target := VGR.settings.data.language
		if not ((_source <> _target))
			return false ; , ErrorLevel:=-2
		for _property, _value in new JSONData.Enumerator(_oGame) {
			if (_value = "")
				return false ; , ErrorLevel:=-1
		}

	return VGR.emulationStart(_game, _cd)
	}

}
VGR_Init() {

	Translation.GUI.onClose := Keypad.GUI.onClose
	Keypad.setActivationContext("IfWinActive", "ahk_group Emulation"), Keypad.GUI.setOptions("-AlwaysOnTop")

	if not (_settings:=Keypad.settings:=VGR.settings:=new JSONData(VGR.SETTINGS_FILE))
		return false, ErrorLevel:=1

	try _locale := _settings.data.language, _hotkeys := _settings.data.hotkeys
	catch
		return false, ErrorLevel:=2

	_program := VGR.base

	if (_locale = "")
		_locale := _settings.data.language := _program.Localization.locale, _settings.updateData()
	_UI := VGR.UI, _localization := _UI.localization := _program.Localization.localizations[_locale]

	_mAbout := Func(_UI.About_UI).bind()
	_mPlay := Func(_UI.Play_UI).bind()
	_mEmulation := Func(_UI.Emulation_UI).bind()
	_smHotkeys0 := Func(_UI.Hotkeys_UI).bind("keyboard")
	_smHotkeys1 := Func(_UI.Hotkeys_UI).bind("joystick")
	_smLanguage := Func(_UI.setLanguage).bind()
	_mExit := ObjBindMethod(_program, "exit")
	_dummy := Func("WinActive")

	try {

		_data := (_localization.data)["TrayMenu"], _tray := _data.Tray, _smData := _data["Tray#InputDevices"]

		Menu, Tray, add, % _program.name, % _dummy
		Menu, Tray, default, % _program.name
		Menu, Tray, disable, % _program.name
		Menu, Tray, add

		Menu, Tray, add, % _text:=_tray.0, % _mAbout
		try Menu, Tray, Icon, % _text, mstscax.dll, 10
		Menu, Tray, add
		Menu, Tray, add, % _text:=_tray.2, % _mPlay
		try Menu, Tray, Icon, % _text, ddores.dll, 26
		Menu, Tray, add, % _text:=_tray.3, % _mEmulation
		try Menu, Tray, Icon, % _text, ddores.dll, 39
			Menu, Tray#InputDevices, add, % _text:=_smData.0, % _smHotkeys0
			try Menu, Tray#InputDevices, Icon, % _text, ddores.dll, 24
			Menu, Tray#InputDevices, add, % _text:=_smData.1, % _smHotkeys1
			try Menu, Tray#InputDevices, Icon, % _text, ddores.dll, 26
		Menu, Tray, add, % _text:=_tray.4, :Tray#InputDevices
		try Menu, Tray, Icon, % _text, setupapi.dll, 18

		for _lNativeName, _oLocale in Program.Localization.localizations {
			Menu, Languages, add, % _lNativeName, % _smLanguage
			try Menu, Languages, Icon, % _lNativeName, % _program.APPDATA_DIRECTORY . "\Resources\Visual\Languages\" . _oLocale.data.language.name . ".png"
		}
		Menu, Tray, add, % _text:=_tray.5, :Languages
		try Menu, Tray, Icon, % _text, ieframe.dll, 82
		Menu, Tray, add, % _text:=_tray.6, % _mExit
		try Menu, Tray, Icon, % _text, imageres.dll, 162

		Menu, Languages, Check, % _locale

		Menu, Tray, Tip, % _program.name . A_Space . _program.version
		Menu, Tray, % ((_program.Debug.debugMode) ? "" : "No") . "Standard"
		Menu, Tray, Icon, % _program.icon

	} catch
		return false, ErrorLevel:=3

	Translation.GUI.controls["Tab_1"].set("", "|" . (_localization.data)["UI.Reader_UI"].controls.Tab_1)

	VGR.setHotkeys()

	GroupAdd, VGR_Reader, % Translation.GUI.AHKID
	GroupAdd, VGR, % Translation.GUI.AHKID
	GroupAdd, VGR_Reader, % Keypad.GUI.AHKID
	GroupAdd, VGR, % Keypad.GUI.AHKID

	Menu, Tray, Icon

return true
}
VGR_setHotkeys(_keyboard:=true, _joystick:=true) {

static _ := (Hotkey.setGroup("VGR_keyboard"), Hotkey.setGroup("VGR_joystick"), Hotkey.setGroup())

	_hotkeys := VGR.settings.data.hotkeys
	_reader := Translation.GUI

	Keypad.setHotkeys(_keyboard, _joystick), _joystickDeviceIsCompatible := !ErrorLevel

	if (_keyboard) {

		try {

			Hotkey.deleteAll("VGR_keyboard"), Hotkey.setGroup("VGR_keyboard"), _khk := _hotkeys.keyboard
			Hotkey.setContext("IfWinActive", "ahk_group VGR")
				new Hotkey(_khk.getGameGuide, bind(_reader, "show")
						, bind(_reader.controls["Tab_1"], "set", "Choose", "|" . 2)
						, bind(Keypad, "__display", true)
						, bind(_reader, "activate"))
			Hotkey.setContext("IfWinActive", _reader.AHKID)
				new Hotkey(_khk.autocompleteMenuSet_U, bind(_reader, "setTransparency", "+5"))
				new Hotkey(_khk.autocompleteMenuSet_D, bind(_reader, "setTransparency", "-5"))
				new Hotkey(_khk.displayEvent, bind(Keypad.GUI, "activate"))
				new Hotkey(_khk.inputSendBackSpace, bind(Keypad, "__display", false))
				new Hotkey(_khk.submitEvent, Func("Translation_GUI_ShellEmbedded_1").bind(_reader, _reader.controls["ShellEmbedded_1"])) ; /ComObjConnect

		} catch {
			return false, ErrorLevel:=1
		} finally Hotkey.setGroup(), Hotkey.clearContext()

	}

	if (_joystick) {

		_jInput := Keypad.jInput

		if (_jInput.connected) {

			if (_joystickDeviceIsCompatible) {

				try {

					Hotkey.deleteAll("VGR_joystick"), Hotkey.setGroup("VGR_joystick"), _jhk := _hotkeys.joystick
					Hotkey.setContext("IfWinActive", "ahk_group VGR")
						new Hotkey(_jhk.getGameGuide, bind(_reader, "show")
								, bind(_reader.controls["Tab_1"], "set", "Choose", "|" . 2)
								, bind(Keypad, "__display", true)
								, bind(_reader, "activate"))
					Hotkey.setContext("IfWinActive", _reader.AHKID)
						new Hotkey(_jhk.autocompleteMenuSet_U, bind(_reader, "setTransparency", "+15"))
						new Hotkey(_jhk.autocompleteMenuSet_D, bind(_reader, "setTransparency", "-15"))
						new Hotkey(_jhk.displayEvent, bind(Keypad.GUI, "activate"))
						new Hotkey(_jhk.inputSendBackSpace, bind(Keypad, "__display", false))
						new Hotkey(_jhk.submitEvent, Func("Translation_GUI_ShellEmbedded_1").bind(_reader, _reader.controls["ShellEmbedded_1"]))

					Hotkey.setContext("If", Func("XShouldFire"))
						new Hotkey(_jhk.keyPressEvent, Func("click"))

				} catch {
					return false, ErrorLevel:=1
				} finally Hotkey.setGroup(), Hotkey.clearContext()

			} else {
			TrayTip
			TrayTip, % VGR.base.name, % StrReplace(VGR.UI.localization.data.messages.INCOMPATIBLE_JOYSTICK_DEVICE, "$", _jInput.name),, 0x2
			}

		}

	}

}

; VGR_updateSettings() {
; Emulation.configurables.updateData(), VGR.settings.updateData()
; }
VGR_emulationStart(_game, _cd) {

	_foxitToolbarId := 0x0+0

	Emulation.start(_game, _cd)
	if (ErrorLevel)
		return false
	_game := Emulation.game

	Keypad.setLayout(VGR.base.Localization.localizations[_game.language].data.language.code)
	if (ErrorLevel)
		return false, ErrorLevel:=3
	Translation.GUI.controls["DropDownList_3"].set("ChooseString", "|" . _game.dictionary)
	if (ErrorLevel)
		return false, ErrorLevel:=4
	if ((_game.gameGuide <> "about:blank") && FileExist(_game.gameGuide) && GUI.ShellEmbedded.canOpenPDFFiles) {
		Translation.GUI.controls["ShellEmbedded_2"].updateURI(_game.gameGuide)
		_detectHiddenWindows := A_DetectHiddenWindows, _titleMatchMode := A_TitleMatchMode
		DetectHiddenWindows, On
		SetTitleMatchMode, RegEx
			WinWait % "ahk_class Afx:.* ahk_exe FoxitReader.exe",, 3
			if not (ErrorLevel)
				ControlGet, _foxitToolbarId, Hwnd,, Edit1, % "ahk_id " . WinExist()
		SetTitleMatchMode % _titleMatchMode
		DetectHiddenWindows % _detectHiddenWindows
	}
	if not (WinExist(_ahkId:="ahk_id " . _hwnd:=Emulation.windows.defaultWindow.HWND))
		return false, ErrorLevel:=5

	WinActivate
	VGR.hWinEventHook := SetWinEventHook("0x800B", "0x800B", 0, RegisterCallback("VGR_EmulatorOnLocationChange"), Emulation.PID, 0, 0) ; EVENT_OBJECT_LOCATIONCHANGE
	VGR_EmulatorOnLocationChange(0, 0, 1)
	(_control:=Translation.GUI.controls["Tab_1"]).onEvent := Func("Translation_GUI_Tab_1").bind(_foxitToolbarId)
	Emulation.onClose := Func("Emulation_closeEvent").bind(_foxitToolbarId)
	Keypad.GUI.setOptions("+Owner" . _hwnd), Translation.GUI.setOptions("+Owner" . _hwnd)
	GroupAdd, Emulation, % _ahkId
	GroupAdd, VGR, % _ahkId

return true
}
VGR_getStatus() {
return VGR[!WinExist("ahk_group Emulation") ? "VGRSTATUS_WAITSTART" : WinActive("ahk_group VGR_Reader") ? "VGRSTATUS_DEPLOYED" : "VGRSTATUS_IDLE"]
}

; ============================================================================================

Translation_GUI_ShellEmbedded_1(_GUI, _control, _type:="") {

	sleep, 300
	if (WinActive(_GUI.AHKID)) {
		_GUI := Keypad.GUI, _autocomplete := _GUI.controls["Autocomplete_1"]
		_autocomplete.set("", (_type = 1) ? clipboard : _control.doc.selection.createRange().text)
		_GUI.activate()
		ControlSend,, {End}{Pgdn}{End}, % _autocomplete.AHKID
	}

}
Translation_GUI_DropDownListX(_GUI, _control) {
_source := _GUI.controls["DropDownList_1"].get(), _target := _GUI.controls["DropDownList_2"].get()
Translation.setDicSysName(_source, _target)
_layout := Keypad.keyboard.layout, Keypad.setLayout(VGR.base.Localization.localizations[_source].data.language.code)
if (ErrorLevel)
	Keypad.setLayout(_layout)
Keypad.GUI.activate()
}
Translation_GUI_Button_1(_GUI) {
_dictionary := Translation.dictionary
_GUI.controls["DropDownList_2"].set("ChooseString", _dictionary.source.nativeName)
, _GUI.controls["DropDownList_1"].set("ChooseString", "|" . _dictionary.target.nativeName)
}
Translation_GUI_DropDownList_3(_GUI, _control) {

	if not (Translation.setDictionary(_v:=_control.get())) {
		_GUI.setOptions("+OwnDialogs")
		MsgBox, 64, % VGR.base.name, % StrReplace(VGR.UI.localization.data.messages.LANGUAGE_PAIR_NOT_AVAILABLE, "$", _v), 3
		_GUI.controls["DropDownList_3"].set("ChooseString", "|" . Translation.dictionary.name)
	}

}
Translation_GUI_Tab_1(_foxitToolbarId, _GUI, _control) {

	local _controls := _GUI.controls
	local _isGameGuideTab := (%A_GuiControl% = 1)

	_controls["ShellEmbedded_" . %A_GuiControl%].set("+hidden"), _controls["ShellEmbedded_" . _control.get()].set("-hidden")
	OnClipboardChange(Func("Translation_GUI_ShellEmbedded_1").bind(_GUI, _controls["ShellEmbedded_1"]), _isGameGuideTab)
	if (_isGameGuideTab && _foxitToolbarId) {
		WinWaitActive % _GUI.AHKID,, 1
		if not (ErrorLevel) {
			_foxitToolbarId := "ahk_id " . _foxitToolbarId
			ControlSetText,, % Emulation.game._gameGuidePageCurrent, % _foxitToolbarId
			ControlSend,, {Enter}, % _foxitToolbarId
		}
		_controls["Tab_1"].onEvent := Func(A_ThisFunc).bind(0x0+0)
	}

}
Translation_GUI_GUISize(_staticBoundY, _GUI, _eventInfo, _w, _h) {
_controls := _GUI.controls
_controls["Tab_1"].set("move", (_width:="w" . (_w - _GUI.margin.h*2)))
_controls["ShellEmbedded_1"].set("move", _pos:=(_width . " h" . (_h - (_staticBoundY + _GUI.margin.v)))), _controls["ShellEmbedded_2"].set("move", _pos)
}

; ============================================================================================

Translation_setTranslationClientEventMonitor(_Translation, _oDictionary) {

	_languages := _oDictionary.languages, _nativeNames := _languages.join("|")
	_lSource := Emulation.game.language, _lTarget := VGR.settings.data.language

	if ((_languages.indexOf(_lSource) = -1) || (_languages.indexOf(_lTarget) = - 1))
		return false, ErrorLevel:=1

	_controls := _Translation.GUI.controls
	_controls["DropDownList_1"].set("", "|" . _nativeNames), _controls["DropDownList_2"].set("", "|" . _nativeNames)
	_controls["DropDownList_2"].set("ChooseString", _lTarget), _controls["DropDownList_1"].set("ChooseString", "|" . _lSource)

return true
}
Translation_setDictionarySystemNameErrorLevelMonitor(_Translation, _errorLevel) {

	if (_errorLevel) {
		_Translation.GUI.controls["DropDownList_1"].set("ChooseString", _Translation.dictionary.source.nativeName)
		_Translation.GUI.controls["DropDownList_2"].set("ChooseString", _Translation.dictionary.target.nativeName)
	Exit
	}

}
Translation_getArticleMessageMonitor(_Translation, _msg) {

static _html := {ERR_CONNECTION: ["<div class='error'>ERR_CONNECTION_TIMED_OUT</div>", "", "<div class='error'>ERR_INTERNET_DISCONNECTED</div>"]
				, ERR_PARSE_ERROR: "<div class='error'>ERR_PARSE_ERROR</div>"
				, NOT_FOUND: "<div class='not_found'>NOT_FOUND</div>"}

	_controls := _Translation.GUI.controls
	_dictionary := _Translation.dictionary

	if (_msg = "LANGUAGES_REVERSED") {
		_controls["DropDownList_1"].set("ChooseString", _dictionary.source.nativeName)
		_controls["DropDownList_2"].set("ChooseString", _dictionary.target.nativeName)
	}
	if (_msg = "S_OK") {
		_dictionary._container.innerHTML := _Translation.responseArticle
	} else if (_msg = "ERR_CONNECTION") {
		_dictionary._container.innerHTML := _html.ERR_CONNECTION[ Abs(ErrorLevel) ]
	} else if ((_msg = "ERR_PARSE_ERROR") || (_msg = "NOT_FOUND")) {
		_dictionary._container.innerHTML := _html[_msg]
	}
	(_controls["ShellEmbedded_1"].doc).selection.empty() ; https://msdn.microsoft.com/en-us/library/ms535869(v=vs.85).aspx

}

; &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
Keypad_displayEventMonitor(_Keypad, _visible) {

	if (_visible) {
		Emulation.pause(true)
		WinSet, Disable,, % Emulation.windows.defaultWindow.AHKID
	} else {
		WinSet, Enable,, % _id:=Emulation.windows.defaultWindow.AHKID
		_reader := Translation.GUI, _reader.hide(), _reader.controls["Tab_1"].set("Choose", "|" . 1)
		Emulation.pause(false)
		sleep, 200
		WinActivate % _id
	}

}
Keypad_submitEventMonitor(_Keypad, _text) {

	if (StrLen(_v:=Trim(_text, A_Space . "`r`n"))) {
		if (Translation.getArticle(_v))
			_reader := Translation.GUI
			ControlSend, Internet Explorer_Server1, {NumpadHome}, VGR.UI.Reader_UI
			_reader.controls["Tab_1"].set("Choose", "|" . 1), _reader.show(), _reader.activate(), _reader.controls["Tab_1"].set("focus")
	} else _Keypad.__display()

}
Emulation_closeEvent(_foxitToolbarId) {

	Keypad.__display(false)
	if (_foxitToolbarId) {
		ControlGetText, _pages,, % "ahk_id " . _foxitToolbarId
		Emulation.game._gameGuidePageCurrent := StrSplit(_pages, A_Space . "/" . A_Space).1 + 0, Emulation.configurables.updateData()
	}
	Translation.GUI.controls["ShellEmbedded_2"].updateURI()
	UnhookWinEvent(VGR.hWinEventHook)

}
; &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

Keypad_jInputDPadEventMonitor2(_Keypad, _jInput, _direction) {
static _o := {Left: [ "columns", -1 ], Up: [ "rows", -1 ], Right: [ "columns", 1 ], Down: [ "rows", 1 ]}
	if (WinActive(_Keypad.GUI.AHKID)) {
		_e := _o[_direction], _Keypad._keyboardButtonsShiftFocus(_e.1, _e.2)
	} else if (_control:=XShouldFire()) {
		; ControlSend,, % "{" . _direction . " 2}", % "ahk_id " . _GUI.controls["ShellEmbedded_" . _GUI.controls["Tab_1"].get()].HWND
		ControlSend,, % "{" . _direction . " 1}", % "ahk_id " . _control
	}
}
Keypad_JInput_onConnection(_jInput) {
TrayTip
TrayTip, % VGR.base.name, % StrReplace(VGR.UI.localization.data.messages.JOYSTICK_SETUP_SUCCESSFUL, "$", _jInput.name)
}
Keypad_JInput_onDisconnected(_jInput) {
MsgBox, 64,, % A_ThisFunc ; <<<<
; TrayTip, % VGR.base.name, % StrReplace(VGR.UI.localization.data.messages.JOYSTICK_DEVICE_DISCONNECTION, "$", _jInput.name),, 0x2
}

; ============================================================================================

VGR_EmulatorOnLocationChange(_hWinEventHook, _event, _hwnd) { ; https://msdn.microsoft.com/en-us/library/windows/desktop/dd373885(v=vs.85).aspx
_listLines := A_ListLines
ListLines, Off

static _margin := {h: 7, v: 31}, _m := 21

	if not (_hwnd)
return

	SetWinDelay, -1
	WinGetPos, _x, _y, _w, _h, % Emulation.windows.defaultWindow.AHKID
	Keypad.GUI.setPos(_x + (_w // 2) - (Keypad.GUI.getPos().w // 2), _y + _m)
	Translation.GUI.setPos(_x + _margin.h, _y + _margin.v, _w - _margin.h * 2, _h - (_margin.v + _margin.h))

ListLines % _listLines ? "On" : "Off"
}
; ============================================================================================





redistEx() {
static _a := (JSONData.getKeys := Func("JSONData_datumGetKeys"))
static _c := (Joystick.controlSet := Func("Joystick_waitForButtonButtonControlSet"))
}
JSONData_datumGetKeys(this, _params*) {
	for _k, _v in _params, _o := this.data
		_o := (_o)[_v]
return JSONData.oHTML.parentWindow.Object.keys(_o)
}
Joystick_waitForButtonButtonControlSet(_joystick, _length, _GUI, _control) {

static _string := concatenate(Chr("9611"), 20)

	_substr := SubStr(_string, 1, _length)

	_v := _control.get()
	, _control.disable(), _GUI.disable(), _control.set("", _str:="")

	Loop 10 {

		Loop % (_buttons:=_joystick.buttons).length()
		{
			if (GetKeyState(_buttons[ a_index ])) {
				_v := "Joy" . a_index
			break, 2
			}
			sleep, 10
		}
		_control.set("", _str:= _str . _substr)

	}
	_control.set("", _v), _control.enable(), _GUI.enable()

}


; ============================================================================================


VGR_exceptionHandler(_exception) {

static EXIT_APP := 1

	if (_exception.message) {

		if (_exception.what = "VGR.emulationStart") {
			if (_exception.message = -3) {
				MsgBox, 64, % VGR.base.name, % VGR.UI.localization.data.messages.ERROR_EMULATOR_EXECUTABLE_NOT_FOUND, 7
				VGR_UI_Emulation_UI()
				WinWaitClose
				VGR_UI_Play_UI()
			return not EXIT_APP
			}
		}

	return EXIT_APP
	} else return not EXIT_APP

}
VGR_handleExit() {

	if (VGR.getStatus() > VGR.VGRSTATUS_WAITSTART)
		ObjBindMethod(Emulation, "onClose").()

		((_hwnd:=WinExist("ahk_group VGR_UI")) && VGR_UI_GuiDestroy(GUI.instances[_hwnd]))
		Emulation.dispose(), Translation.dispose()
		Keypad.destroy()
		Hotkey.deleteAll("VGR_keyboard"), Hotkey.deleteAll("VGR_joystick")
		try ((_component:=Translation.GUI.controls["ShellEmbedded_1"].component) && ComObjConnect(_component))
		GUI.destroy(Translation.GUI)
		Menu, Tray, DeleteAll
		VGR.base.dispose()

return 0
}

XShouldFire() {
	if not (VGR.getStatus() = VGR.VGRSTATUS_DEPLOYED)
return false
	_coordModeMouse := A_CoordModeMouse
	CoordMode, Mouse, Screen
	WinGetPos, _x, _y, _w, _h, % Emulation.windows.defaultWindow.AHKID
	MouseGetPos, _mouseX, _mouseY,, _control, 3
	CoordMode, Mouse, % _coordModeMouse
return (Between(_x, _x + _w, _mouseX) && Between(_y, _y + _h, _mouseY)) ? _control : false
}

; ========================================================================================================================

Translation_customize() {
_reader := Translation.GUI
_reader.setOptions("+ToolWindow -Caption")
_reader.setMargin(5, 5)
_reader.setFont()
_reader.setColor("FFFFFF", "FFFFFF")
_reader.add("DropDownList", "vDropDownList_1 Section xm+25 ym w90")
_reader.lastFoundControl.onEvent := Func("Translation_GUI_DropDownListX")
_reader.add("Button", "ys w40 hp", Chr(8646)) ; https://unicode-table.com/fr/21C6/
_reader.lastFoundControl.onEvent := Func("Translation_GUI_Button_1")
_reader.add("DropDownList", "vDropDownList_2 ys w90")
_reader.lastFoundControl.onEvent := Func("Translation_GUI_DropDownListX")
_reader.add("DropDownList", "vDropDownList_3 ys", Translation.manifest.getKeys().join("|"))
_reader.lastFoundControl.onEvent := Func("Translation_GUI_DropDownList_3")
_tab := _reader.add("Tab", "vTab_1 xm y" . (_y:=51) . " h21 +AltSubmit")
_tab.onEvent := Func("Translation_GUI_Tab_1")
GUI % _reader.HWND . ":Tab"
_reader.controls["ShellEmbedded_1"].set("move", "xm y" . _y:=_y + 22)
_reader.add("ShellEmbedded", "vShellEmbedded_2 xm y" . _y . " +hidden")
_reader.onSize := Func("Translation_GUI_GUISize").bind(_y)
_reader.show("hide", "VGR.UI.Reader_UI")
Translation.__SetDictionary := Func("Translation_setTranslationClientEventMonitor")
Translation.__SetDicSysName := Func("Translation_setDictionarySystemNameErrorLevelMonitor")
Translation.getArticleMessageMonitor := Func("Translation_getArticleMessageMonitor")
}
Keypad_customize() {
Keypad._jInputDPadEventMonitor := Func("Keypad_jInputDPadEventMonitor2")
Keypad.onDisplay := Func("Keypad_displayEventMonitor")
Keypad.noHideOnSubmit := true, Keypad.onSubmit := Func("Keypad_submitEventMonitor")
Keypad.jInputOnConnection := Func("Keypad_JInput_onConnection")
Keypad.jInputOnDisconnected := Func("Keypad_JInput_onDisconnected")
}
Emulation_customize() {
Emulation.onClose := Func("Emulation_closeEvent")
}