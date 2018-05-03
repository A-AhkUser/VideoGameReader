VGR_UI_About_UI() {

static _w := 500

	_program := VGR.base
	_localization := (VGR.UI.localization.data)["UI.About_UI"]

	if (WinExist("ahk_group VGR_UI"))
		return
	_GUI := VGR.UI.About_UI := new GUI("-MinimizeBox -MaximizeBox +LastFound")
	_GUI.onClose := Func("VGR_UI_GuiDestroy")
	_GUI.setColor("White", "White")
	ControlGetPos,,, _posw,,, % "ahk_id " . (_GUI.add("Picture", "0x1000", _program.logotype)).HWND ; SS_SUNKEN
	_GUI.lastFoundControl.set("move", "x" . (_w - _posw) // 2)
	_GUI.add("Text", "0x10 x1 w" . (_w - 2) . " h1") ; SS_ETCHEDHORZ
	_GUI.setMargin(5, 25)
	_GUI.setFont("s11 c2e84f4 bold")
	_GUI.add("Text", "Section x30", "Video Game")
	_GUI.setFont("c505356")
	_GUI.add("Text", "ys", "Reader")
	_GUI.setFont("s8 norm italic")
	_GUI.add("Text", "vversion ys+5 w" . _w)
	_GUI.lastFoundControl.set("", (_localization.controls)[_GUI.lastControlV] . A_Space . _program.version)
	_GUI.setFont()
	_GUI.add("Picture", "Section xs x70", _program.APPDATA_DIRECTORY . "\Resources\Visual\Language-AutoHotkey-yellowgreen.png")
	_GUI.add("Link", "ys+2 -TabStop", "<a href=""https://autohotkey.com/"">https://autohotkey.com/</a>")
	_GUI.add("Link", "Section " . (_v:="x70 y+m -TabStop w" . _w), _program.year A_Space _program.author A_Space "<<a href=""" _program.github """>" _program.github "</a>>")
	_GUI.add("Link", "vwebsite " . _v)
	_GUI.lastFoundControl.set("", (_localization.controls)[_GUI.lastControlV] A_Space "<<a href=""" _program.homepage_url """>" _program.homepage_url "</a>>")
	_GUI.add("Link", "vcontact " . _v)
	_GUI.lastFoundControl.set("", (_localization.controls)[_GUI.lastControlV] A_Space "<<a id=""mailto"">" _program.contact "</a>>")
	_GUI.add("Text", "0x10 xs w" . (_w - 70 * 2) . " h1")
	_GUI.add("Button", "x" . ((_w - 80) // 2) . " w80 h24 Default", "&OK").onEvent := Func("VGR_UI_GuiClose")
	_GUI.show("w" . _w, StrReplace(_localization.title, "$", _program.name))
	GroupAdd, VGR_UI, % _GUI.AHKID

}

; ====================================================================================================

VGR_UI_Play_UI() {

static _w := 420
static _h1 := 120, _h2 := 325

	_localization := (VGR.UI.localization.data)["UI.Play_UI"]
	_configurables := Emulation.configurables

	if (WinExist("ahk_group VGR_UI") || !(VGR.getStatus() = VGR.VGRSTATUS_WAITSTART))
		return
	_GUI := VGR.UI.Play_UI := new GUI("+LastFound")
	_GUI.onClose := Func("VGR_UI_GuiDestroy")
	_GUI.inputControls := []
	_GUI.setColor("White", "White")
	_GUI.setFont()
	_GUI.setMargin(_b:=10, 10)
	_GUI.add("Tab", "vTab_1 x-1 y-32 -Disabled -TabStop +Buttons", "Outer")
	GUI % _GUI.HWND ":Tab", 1, 1
		_GUI.add("GroupBox", "xm ym w" . (_w - (2 * _b)) . " h" . _h1)
		_GUI.add("ComboBox", "Section vgameTitle xm+30 ym+40 w" . (_w - 140) . " +Limit Sort", _configurables.getKeys("games").join("|"))
		_text := (_localization.controls)[_GUI.lastControlV]
		SendMessage, 0x1501, true, &_text,, % "ahk_id  " . DllCall("GetWindow", "Ptr", _GUI.lastFoundControl.HWND, "Uint", 5) ; EM_SETCUEBANNER, GW_CHILD
		_GUI.lastFoundControl.onEvent := Func("VGR_UI_Play_UI_gameTitleControl")
		_GUI.add("Pic", "ys Icon179", "shell32.dll")
		_GUI.add("Edit", "yp xp+16 w32 +ReadOnly")
		_GUI.add("UpDown", "vcd Range1-1", 1).onEvent := Func("VGR_UI_Play_UI_cdControl")
		_GUI.add("Button", "vdelete Section xs yp+30 w80 h21 +Disabled", _localization).onEvent := Func("VGR_UI_Play_UI_deleteControl")
		_GUI.add("Button", "vcreate ys wp hp +Disabled", _localization).onEvent := Func("VGR_UI_Play_UI_createControl")
	GUI % _GUI.HWND ":Tab"
		_GUI.add("GroupBox", "xm+10 y" . (_h1 + (2 * _b)) " w" . (_w - (10 * 2) - (2 * _b)) . " h" . _h2)
		_GUI.add("Button", "vmodify xp yp w80 h21 +Disabled").onEvent := Func("VGR_UI_Play_UI_modifyControl")
		_GUI.lastFoundControl.set("", (_localization.controls)[_GUI.lastControlV].0)
	GUI % _GUI.HWND ":Tab", 1, 1
		_GUI.add("Button", "vplay x" (_w - 130) " y" (_h2 + (_y:=_h1 + 3 * _b)) " w90 h24 +Disabled +Default", _localization).onEvent := Func("VGR_UI_Play_UI_playControl")
		_GUI.add("Tab", "vTab_2 x-1 y-32 +Disabled -TabStop +Buttons", "Inner")
	GUI % _GUI.HWND ":Tab", 1, 2

		static _w1 := 155, _w2 := 120
		static _settings := [["platform", "emulator", "dictionary", "language"], ["gamePath", "gameGuidePath"]]

		for _n, _setting in _settings.1 {
			_GUI.add("Text", "Section xm+30 y" . (_y + (30 * a_index)) . " w" . _w1 . " +Right v" . _setting, _localization)
			_GUI.add("DropDownList", "v" . _setting . "Input ys-3 w" . _w2 . " Sort")
			_GUI.inputControls.push(_GUI.lastFoundControl)
			_GUI.add("Picture", "vPicture_" . a_index . " ys+3 Icon16 +Hidden", "dmdskres.dll")
		}
		_GUI.controls["platformInput"].set("", _configurables.getKeys("emulation").join("|"))
		_GUI.controls["dictionaryInput"].set("", Translation.manifest.getKeys().join("|"))
		_GUI.controls["platformInput"].onEvent := Func("VGR_UI_Play_UI_platformInputControl")
		_GUI.controls["dictionaryInput"].onEvent := Func("VGR_UI_Play_UI_dictionaryInputControl")

		for _i, _setting in _settings.2
			ControlGetPos,, _ypos%_i%,,,, % "ahk_id " . (_GUI.add("Text", "Section xm+30 ys+70 w" . (_w1 + _w2 + _b) . " +Right v" . _setting, _localization)).HWND
		for _i, _setting in _settings.2 {
			_GUI.add("Picture", "Section xm+30 y" . (_ypos%_i% - 50) . " Icon16 +Hidden vPicture_" . ++_n, "dmdskres.dll")
			_GUI.add("Edit", "v" . _setting . "Input cGray  ys-3 w" . (_w1 + _w2) . " +ReadOnly", "")
			_GUI.inputControls.push(_GUI.lastFoundControl)
			_GUI.add("Pic", "vbrowse" . _setting . " ys-5 Icon22", "ieframe.dll").onEvent := Func("VGR_UI_Play_UI_browse" . _setting . "Control")
		}

	_GUI.show("w" . _w . " h" . (_h1 + _h2 + 24 + 6 * _b), _localization.title)
	GroupAdd, VGR_UI, % _GUI.AHKID

}

VGR_UI_Play_UI_gameTitleControl(_GUI, _control) {

static _input := ""

	_name := Format("{:T}", Trim(_control.get()))

	if not (Is("alnum", StrReplace(_name, A_Space, ""))) {

		ControlGetPos, _x, _y,, _h,, % (_id:="ahk_id " . _control.HWND)
		ToolTip, % (VGR.UI.localization.data)["UI.Play_UI"].OwnDialogs.INVALID_ALPHANUMERIC_STRING, % _x, % _y + _h
		_f := Func("SendMessage").bind("0x112", "0xF060",,, "ahk_pid " . VGR.base.PID . " ahk_class tooltips_class32") ; https://www.autohotkey.com/docs/commands/WinClose.htm#Remarks
		SetTimer, % _f, -5000

		ControlSetText,, % _input, % _id
		ControlSend,, {End}, % _id

	return
	}
	_input := _name

	_controls := _GUI.controls
	_games := Emulation.configurables.data.games

	if not (_games.hasOwnProperty(_name)) {
		_controls["cd"].set("+Range1-1"), _controls["cd"].set("", 1)
		VGR_UI_Play_UI_restoreControls()
		VGR_UI_Play_UI_setButtonsState("delete", false, "create", !!StrLen(_name), "modify", false, "play", false)
	} else {
		_game := _games[_name]
		, _controls["cd"].set("+Range1-" . _game.length + 1), _controls["cd"].set("", 1)
		VGR_UI_Play_UI_restoreControls()
		VGR_UI_Play_UI_fillControls(_game)
		VGR_UI_Play_UI_setButtonsState("delete", true, "create", false, "modify", true, "play", true)
	}
	Loop % _GUI.inputControls.length()
		_controls[ "Picture_" . a_index ].set("+Hidden")

}
VGR_UI_Play_UI_cdControl(_GUI, _control) {

_controls := _GUI.controls
_game := (Emulation.configurables.data.games)[ Format("{:T}", Trim(_controls["gameTitle"].get())) ], _cd := _control.get()

	if (_cd = _game.length + 1) {
		VGR_UI_Play_UI_restoreControls()
		VGR_UI_Play_UI_setButtonsState("delete", false, "create", true, "modify", false, "play", false)
	} else {
		VGR_UI_Play_UI_restoreControls(), VGR_UI_Play_UI_fillControls(_game, _cd)
		VGR_UI_Play_UI_setButtonsState("delete", true, "create", false, "modify", true, "play", true)
	}
	Loop % _GUI.inputControls.length()
		_controls[ "Picture_" . a_index ].set("+Hidden")

}
VGR_UI_Play_UI_deleteControl(_GUI, _control) {

	_comboBox := _GUI.controls["gameTitle"], _game := Format("{:T}", Trim(_comboBox.get()))

	VarSetCapacity(_rMax, 4)
	SendMessage, 1136,, &_rMax,, % "ahk_id " . _GUI.controls["cd"].HWND ; UDM_GETRANGE32
	_str := StrReplace((VGR.UI.localization.data)["UI.Play_UI"].OwnDialogs.ERASURE_CONFIRMATION_PROMPT, "$", _game) . A_Space . "[" . (NumGet(_rMax, 0, "Int") - 1) . " CD]"
	_GUI.setOptions("+OwnDialogs")
	MsgBox, % 48+256+1, % VGR.base.name, % _str
	IfMsgBox, Cancel
		return

	_configurables := Emulation.configurables, _games := _configurables.data.games
	JSONData.delete(_games, _game), _configurables.updateData()
	_comboBox.set("", "|" . _configurables.getKeys("games").join("|")), _comboBox.set("Choose", "|" . 0)

}
VGR_UI_Play_UI_createControl(_GUI, _control) {

	_comboBox := _GUI.controls["gameTitle"]
	_configurables := Emulation.configurables, _games := _configurables.data.games

	_game := Format("{:T}", Trim(_comboBox.get()))

	if not (_games.hasOwnProperty(_game))
		_games[_game] := new JSONData.DataTypes.Array()
	_o := new JSONData.DataTypes.Object()
	_o.platform:=_o.emulator:=_o.fullPath:=_o.language:=_o.dictionary:="", _o.gameGuide := "about:blank", _o._gameGuidePageCurrent := 1
	_games[_game].push(_o)
	_configurables.updateData()

	_comboBox.set("", "|" . _configurables.getKeys("games").join("|")), _comboBox.set("ChooseString", "|" . _game)

}
VGR_UI_Play_UI_modifyControl(_GUI, _control) {

static _disabled := true
local _tab1, _tab2, _configurables, _oTemp

	_tab1 := _GUI.controls["Tab_1"], _tab2 := _GUI.controls["Tab_2"]

	if not (_disabled) {

		_tab2.disable(), _GUI.submit(false)

			_configurables := Emulation.configurables
				_oTemp := ((_configurables.data.games)[ Format("{:T}", Trim(gameTitle)) ])[ cd - 1 ]
				, _oTemp.platform := platformInput
				, _oTemp.emulator := emulatorInput
				, _oTemp.fullPath := gamePathInput
				, _oTemp.language := languageInput
				, _oTemp.dictionary := dictionaryInput
				, _oTemp.gameGuide := gameGuidePathInput
			_configurables.updateData()

		_tab1.enable(), VGR_UI_Play_UI_validate()

	} else _tab1.disable(), _tab2.enable(), _GUI.controls["platformInput"].set("focus")

	_control.set("", (((VGR.UI.localization.data)["UI.Play_UI"].controls)["modify"])[_disabled]), _disabled := !_disabled

	WinSet, Redraw,, % _GUI.AHKID

}
VGR_UI_Play_UI_platformInputControl(_GUI, _control) {

_controls := _GUI.controls

	if (_platform:=_control.get()) {
		_configurables := Emulation.configurables
		_controls["emulatorInput"].set("", "|" . _configurables.getKeys("emulation", _platform).join("|"))
			if (_GUI.focusedControlV <> "platformInput") {
				_oGame := (_configurables.data.games)[ Format("{:T}", Trim(_controls["gameTitle"].get())) ].0
				_controls["emulatorInput"].set("ChooseString", _oGame.emulator)
				if (FileExist(_oGame.fullPath))
					_controls["gamePathInput"].set("", _oGame.fullPath)
			} else {
				_controls["emulatorInput"].set("Choose", 1)
				_controls["gamePathInput"].set("", "")
			}
	} else _controls["emulatorInput"].set("", "|")

}
VGR_UI_Play_UI_dictionaryInputControl(_GUI, _control) {

_controls := _GUI.controls

	if (_dictionary:=_control.get()) {
		_languages := Translation.dictionaries[_dictionary].languages.slice()
		_languages.splice(_languages.indexOf(VGR.settings.data.language), 1)
		_controls["languageInput"].set("", "|" . _languages.join("|"))
			if (_GUI.focusedControlV <> "dictionaryInput") {
				_game := (Emulation.configurables.data.games)[ Format("{:T}", Trim(_controls["gameTitle"].get())) ].0
				_controls["languageInput"].set("ChooseString", _game.language)
			} else _controls["languageInput"].set("Choose", 1)
	} else _controls["languageInput"].set("", "|")

}
VGR_UI_Play_UI_browseGamePathControl(_GUI, _control) {

static _root := A_MyDocuments

	_controls := _GUI.controls

	_GUI.setOptions("+OwnDialogs")
	if ((_platform:=_controls["platformInput"].get()) = "") {
		MsgBox, 64, % VGR.base.name, % (VGR.UI.localization.data)["UI.Play_UI"].OwnDialogs.PLATFORM_NOT_SPECIFIED
	return
	}
	_emulator := _controls["emulatorInput"].get()
	, _extensions := ((Emulation.configurables.data.emulation)[_platform])[_emulator].extensions

	FileSelectFile, _file, 1, % _root, % (VGR.UI.localization.data)["UI.Play_UI"].OwnDialogs.FILE_SELECT_SELECT_GAME, % "(" . _extensions . ")"
	if not (ErrorLevel) {

		SplitPath % _file,, _root, _extension
		if (In(StrReplace(_extensions, ";", ","), "*." . _extension))
			_controls["gamePathInput"].set("", _file)

	}

}
VGR_UI_Play_UI_browseGameGuidePathControl(_GUI, _control) {

static _root := A_MyDocuments

	_GUI.setOptions("+OwnDialogs")
	FileSelectFile, _file, 1, % _root, % (VGR.UI.localization.data)["UI.Play_UI"].OwnDialogs.FILE_SELECT_SELECT_GAME_GUIDE, (*.pdf)
	if not (ErrorLevel) {

		SplitPath % _file,, _root, _extension
		if not (_extension = "pdf")
	return

		if not (GUI.ShellEmbedded.canOpenPDFFiles) {
			MsgBox, 64, % VGR.base.name, % (VGR.UI.localization.data)["UI.Play_UI"].OwnDialogs.SHELL_EMBEDDED_CANNOT_OPEN_PDF_FILES
		} else _GUI.controls["gameGuidePathInput"].set("", _file)

	}

}
VGR_UI_Play_UI_playControl(_GUI, _control) {
if not (VGR_UI_Play_UI_validate())
return
_game := Format("{:T}", Trim(_GUI.controls["gameTitle"].get())), _cd := _GUI.controls["cd"].get()
SendMessage, 0x112, 0xF060,,, % _GUI.AHKID
sleep, 100
VGR.emulationStart(_game, _cd) VGR.base.Debug.exceptionMonitor(Exception(ErrorLevel, "VGR.emulationStart"))
}

VGR_UI_Play_UI_validate() {

	_GUI := GUI.instances[ A_GUI ], _controls := _GUI.controls
	_boolean := true

	for _index, _iControl in _GUI.inputControls {
		if (_iControl.get() = "") {
			_boolean := false
			_controls[ "Picture_" . _index ].set("-Hidden")
		} else _controls[ "Picture_" . _index ].set("+Hidden")
	}
	return _boolean

}
VGR_UI_Play_UI_fillControls(_game, _cd:=1) {
_controls := GUI.instances[ A_GUI ].controls, _game := _game[ _cd - 1 ]
_controls["platformInput"].set("ChooseString", "|" . _game.platform)
_controls["dictionaryInput"].set("ChooseString", "|" . _game.dictionary)
_controls["gameGuidePathInput"].set("", _game.gameGuide)
}
VGR_UI_Play_UI_restoreControls() {
_controls := GUI.instances[ A_GUI ].controls
_controls["platformInput"].set("Choose", "|" . 0), _controls["dictionaryInput"].set("Choose", "|" . 0)
_controls["gamePathInput"].set("", ""), _controls["gameGuidePathInput"].set("", "")
}
VGR_UI_Play_UI_setButtonsState(_params*) {
_controls := GUI.instances[ A_GUI ].controls, _i := 0
Loop % _params.length() // 2
	_controls[_params[++_i]].enable(_params[++_i])
}

; ====================================================================================================

VGR_UI_Emulation_UI() {

static _w := 400, _h := 400

	_configurables := Emulation.configurables
	_localization := (VGR.UI.localization.data)["UI.Emulation_UI"]

	if (WinExist("ahk_group VGR_UI") || !(VGR.getStatus() = VGR.VGRSTATUS_WAITSTART))
		return
	_GUI := VGR.UI.Emulation_UI := new GUI("+LastFound")
	_GUI.onClose := Func("VGR_UI_Emulation_UI_GUIClose").bind(false)
	_GUI.setColor("White", "White")
	_GUI.setFont()
	_GUI.setMargin(_b:=7, 7)
	_GUI.add("Text", "Section vplatform xm+35 ym+35 w" . _w // 3, _localization)
	_GUI.add("DropDownList", "vplatformInput " . _options:="y+m w" . _w // 3, _configurables.getKeys("emulation").join("|")).onEvent := Func("VGR_UI_Emulation_UI_platformInputControl")
	_GUI.add("Text", "Section vemulator ys w" . _w // 3, _localization)
	_GUI.add("DropDownList", "vemulatorInput " . _options, "").onEvent := Func("VGR_UI_Emulation_UI_emulatorInputControl")
	_GUI.add("Edit", "Section vemulatorPathInput cGray  xm+35 w" . (((2 * _w) // 3) + _b) . " +ReadOnly", "")
	_GUI.add("Picture", "vbrowseEmulatorPathInput ys-3 Icon22", "ieframe.dll").onEvent := Func("VGR_UI_Emulation_UI_browseEmulatorPathInputControl")
	_GUI.add("Text", "0x10 x30 y" . (_h - 24 - 2 * _b) . " w" . (_w - 30 * 2) . " h1") ; SS_ETCHEDHORZ
	_GUI.add("Button", "Section vcancel x" . ((_w // 2) - 80 - (_b // 2)) . " y+m w80 h24", _localization)
	_GUI.lastFoundControl.onEvent := Func("VGR_UI_Emulation_UI_cancelControl")
	_GUI.add("Button", "vconfirm ys wp hp", _localization)
	_GUI.lastFoundControl.onEvent := Func("VGR_UI_Emulation_UI_confirmControl").bind(false)
	_GUI.controls["platformInput"].set("Choose", "|" . 1)
	_GUI.show("w" . _w . " h" . _w, _localization.title)
	GroupAdd, VGR_UI, % _GUI.AHKID

}

VGR_UI_Emulation_UI_platformInputControl(_GUI, _control) {
_emulatorInput := _GUI.controls["emulatorInput"]
_emulatorInput.set("", "|" . Emulation.configurables.getKeys("emulation", _platform:=_control.get()).join("|"))
_emulatorInput.set("Choose", "|" . 1)
}
VGR_UI_Emulation_UI_emulatorInputControl(_GUI, _control) {
_platform := _GUI.controls["platformInput"].get()
_GUI.controls["emulatorPathInput"].set("", ((Emulation.configurables.data.emulation)[_platform])[_control.get()].fullPath)
}
VGR_UI_Emulation_UI_browseEmulatorPathInputControl(_GUI, _control) {

static _root := A_MyDocuments
local _file, _emulator, _name, _extension

	_GUI.setOptions("+OwnDialogs")
	FileSelectFile, _file, 1, % _root, % (VGR.UI.localization.data)["UI.Emulation_UI"].OwnDialogs.FILE_SELECT_SELECT_EMULATOR_EXE, (*.exe)
	if not (ErrorLevel) {

		_GUI.submit(false)
		_emulator := ((Emulation.configurables.data.emulation)[platformInput])[emulatorInput]

		SplitPath % _file,, _root, _extension, _name
		if ((_extension <> "exe") or (_name <> _emulator.executableName))
	return

		_GUI.controls["emulatorPathInput"].set("", _file)
		_GUI.controls["confirm"].onEvent := Func("VGR_UI_Emulation_UI_confirmControl").bind(true)
		_GUI.onClose := Func("VGR_UI_Emulation_UI_GUIClose").bind(true)
		_emulator.dir := _root, _emulator.fullPath := _file

	}

}
VGR_UI_Emulation_UI_cancelControl(_GUI, _control) {
Emulation.configurables.restore()
_GUI.close(true)
}
VGR_UI_Emulation_UI_confirmControl(_boundBoolean, _GUI) {
if (_boundBoolean)
	Emulation.configurables.updateData()
_GUI.close(false)
}
VGR_UI_Emulation_UI_GUIClose(_boundBoolean, _GUI) {

	if (_boundBoolean) {
		_GUI.setOptions("+OwnDialogs")
		MsgBox, 324, % VGR.base.name, % (VGR.UI.localization.data)["UI.Emulation_UI"].OwnDialogs.DISMISS_CONFIRMATION_PROMPT
		IfMsgBox, No
			return -1
		Emulation.configurables.restore()
	}
	GUI.Destroy(_GUI)

}

; ====================================================================================================

VGR_UI_Hotkeys_UI(_device) {

static _w := 680, _h := 450
static _tw := _w // 2
static HOTKEYS_PER_PAGE := 5

	_device := Format("{:L}", _device)
	if _device not in joystick,keyboard
		return
	if (WinExist("ahk_group VGR_UI"))
		return

	_hotkeys := VGR.settings.data.hotkeys
	_localization := (VGR.UI.localization.data)["UI.Hotkeys_UI"]

	_GUI := VGR.UI.Hotkeys_UI := new GUI("+LastFound")
	_GUI.onClose := Func("VGR_UI_Hotkeys_UI_GUIClose")
	_GUI.setColor("White", "White")
	_GUI.setMargin(29, 19)
	_GUI.setFont()
	_GUI.add("Picture", "xm ym Icon18", "setupapi.dll")
	_GUI.add("Button", "Section vcancel xm+" . _tw " y" . (_height:=_h - 3 * _GUI.margin.v) . " w80 h24", _localization).onEvent := Func("VGR_UI_GuiClose")
	_GUI.add("Button", "vconfirm xp+90 yp wp hp", _localization)
	_controlType := (_device == "keyboard") ? "hotkey" : "button"
	_GUI.lastFoundControl.onEvent := Func("VGR_UI_Hotkeys_UI_Submit").bind(_device, _controlType)
	_tab := _GUI.add("Tab", "Section vTab_1 c514d51 xs ym w" . (210 + 2 * _GUI.margin.v) . " h" . _height:=_height - 24, _t:=1)
	GUI % _GUI.HWND ":Tab", % _t

		if (_device == "joystick") {
			_GUI.setOptions("+Disabled")
			_enum := _GUI.enum := new JSONData.Enumerator(_hotkeys.joystick)
			_f := Func("VGR_UI_Hotkeys_UI_jInputConnect").bind(_GUI, _GUI.jInput:=new Joystick())
			SetTimer % _f, -2000
		} else {
			_enum := _GUI.enum := new JSONData.Enumerator(_hotkeys.keyboard)
		}

		_options := "0x10 xm+32 yp-3 w" . _tw - 32 . " h1" ; SS_ETCHEDHORZ
		_height := (_height // (HOTKEYS_PER_PAGE + 1))
		_i := 1
		while (_enum.next(_k, _v)) {

			_GUI.add("Text", "c514d51 xm ym+" . _height * _i . " w" . (_tw - 5) . " h31 +Right v" . _k, _localization)
			_GUI.add("Text", _options)
			_GUI.setFont("s10 bold", "Calibri")
			_GUI.add(_controlType, "xm+" . (_tw + 5) . " yp w200 h21 v" . _controlType . "Input_" . a_index, _v)
			_GUI.setFont()

			if (++_i <> HOTKEYS_PER_PAGE + 1)
				continue

				if (_enum.count > HOTKEYS_PER_PAGE * _t) {
					SendMessage, 0x1304,,, SysTabControl321 ; TCM_GETITEMCOUNT
					_tab.set("", ++ErrorLevel)
					GUI % _GUI.HWND ":Tab", % ++_t
					_i := 1
				}

		}

	GUI % _GUI.HWND ":Tab"

	_controls := _GUI.controls, _readOnlyValues := (_hotkeys.readOnlyValues)[_device]
	Loop % (_GUI.enum.count)
		if (In(_readOnlyValues, (_control:=_controls[ _controlType . "Input_" . a_index ]).get()))
			_control.disable()

	_GUI.show("w" . _tw + 210 + 2 * _GUI.margin.v . " h" . _h, _localization.title)
	GroupAdd, VGR_UI, % _GUI.AHKID
	GroupAdd, Keypad, % _GUI.AHKID

}
VGR_UI_Hotkeys_UI_jInputConnect(_GUI, _joystick) {

	WinWait % _GUI.AHKID

	if (_joystick.connect()) {

		_GUI.setOptions("-Disabled")
		ControlGetPos, _x, _y,,,, % "ahk_id " . _GUI.controls["Tab_1"].HWND
		_str := StrReplace((VGR.UI.localization.data)["UI.Hotkeys_UI"].OwnDialogs.JOYSTICK_SETUP_SUCCESSFUL, "$", _joystick.name)
		ToolTip, % _str, % _x, % _y - _GUI.margin.v
		_f := Func("SendMessage").bind("0x112", "0xF060",,, "ahk_pid " . VGR.base.PID . " ahk_class tooltips_class32")
		SetTimer, % _f, -4000

		Loop % _GUI.enum.count
			_GUI.controls[ "buttonInput_" . a_index ].onEvent := _joystick.controlSet.bind(_joystick, 2)

	} else {

		_GUI.setOptions("+OwnDialogs")
		MsgBox, % 64+5, % VGR.base.name, % (VGR.UI.localization.data)["UI.Hotkeys_UI"].OwnDialogs.JOYSTICK_DEVICE_UNREACHABLE
		IfMsgBox, Cancel
			_GUI.close(true)
		else IfMsgBox, Retry
			%A_ThisFunc%(_GUI, _joystick)

	}

}

VGR_UI_Hotkeys_UI_Submit(_boundInputType, _boundControlType, _GUI) {

	_controls := _GUI.controls, _str := Chr(44)

	Loop % (_GUI.enum.count) {
		if not (In(_str, _x:=%_boundControlType%Input_%a_index%:=_controls[ _boundControlType . "Input_" . a_index ].get())) {
			_str .= _x . ","
		} else {
			GUI.instances[ A_GUI ].setOptions("+OwnDialogs")
			MsgBox, 48, % VGR.base.name, % (VGR.UI.localization.data)["UI.Hotkeys_UI"].OwnDialogs.INVALID_INPUT
		return
		}
	}
	_keys := (VGR.settings.data.hotkeys)[_boundInputType]
	while (_GUI.enum.next(_x))
		_keys[_x] := %_boundControlType%Input_%a_index%

	VGR.settings.updateData(), VGR.setHotkeys(_isKeyboard:=(_boundInputType == "keyboard"), !_isKeyboard)
	_GUI.close(true)

}

VGR_UI_Hotkeys_UI_GUIClose(_GUI) {

	if (_GUI.hasKey("jInput")) {
		Loop % _GUI.enum.count
			_GUI.controls[ "buttonInput_" . a_index ].onEvent := ""
		_GUI.jInput.dispose()
	}
	VGR_UI_GuiDestroy(_GUI)

}


VGR_UI_GuiClose(_GUI) {
_GUI.close(true)
}
VGR_UI_GuiDestroy(_GUI) {
(WinExist("ahk_pid " . VGR.base.PID . " ahk_class tooltips_class32") && SendMessage("0x112", "0xF060"))
; OnMessage(0x53, "")
GUI.destroy(_GUI)
}

; ====================================================================================================

VGR_UI_setLanguage(_itemName, _itemPos:="", _menuName:="Language") {

	if (_itemName <> VGR.settings.data.language && (VGR.getStatus() = VGR.VGRSTATUS_WAITSTART) && !WinExist("ahk_group VGR_UI")) {

		_localization := VGR.base.Localization.localizations[_itemName]
		try {

			_data := (_localization.data)["TrayMenu"], _tray := _data.Tray, _smData := _data["Tray#InputDevices"]
			Loop % _tray.length
				Menu, Tray, rename, % a_index + 2 . "&", % _tray[ a_index - 1 ]
			Loop % _smData.length
				Menu, Tray#InputDevices, rename, % a_index . "&", % _smData[ a_index - 1 ]

		} catch {
			VGR_UI_setLanguage(VGR.settings.data.language)
		}

		Menu, % _menuName, Uncheck, % VGR.settings.data.language
		Menu, % _menuName, Check, % _itemName
		Translation.GUI.controls["Tab_1"].set("", "|" . (_localization.data)["UI.Reader_UI"].controls.Tab_1)

		VGR.settings.data.language := _itemName, VGR.UI.localization := _localization, VGR.settings.updateData()

	}

}
