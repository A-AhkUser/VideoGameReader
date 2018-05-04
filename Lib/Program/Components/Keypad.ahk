global Keypad :=
(LTrim Join C
	{
		WORKING_DIRECTORY: A_ScriptDir . "\Keypad",
		settings: "",
		updateSettings: Func("Keypad_updateSettings"),
		setHotkeys: Func("Keypad_setHotkeys"),
		__New: Func("Keypad_New"),
		GUI: "",
		GUITransparency: 200,
		style: "",
		setLayout: Func("Keypad_setLayout"),
		_setLayer: Func("Keypad_setLayer"),
		lastFoundControl: {HWND: ""},
		activationContext: {
			type: "IfWinNotActive",
			title: "ahk_group Keypad"
		},
		setActivationContext: Func("Keypad_setActivationContext"),
		onDisplay: "",
		__display: Func("Keypad_displayEvent"),
		onKeyPress: "",
		__keyPress: Func("Keypad_keyPressEvent"),
		onSubmit: "",
		noHideOnSubmit: false,
		__submit: Func("Keypad_submitEvent"),
		jInput: "",
		jInputOnConnection: "",
		jInputOnDisconnected: "",
		_jInputThumbstickLEventMonitor: Func("Keypad_jInputThumbstickLEventMonitor"),
		_jInputDPadEventMonitor: Func("Keypad_jInputDPadEventMonitor"),
		_jInputThumbstickREventMonitor: Func("Keypad_jInputThumbstickREventMonitor"),
		_keyboardButtonsShiftFocus: Func("Keypad_keyboardButtonsShiftFocus"),
		destroy: Func("Keypad_destroy"),
		Init: Func("Keypad_Init")
	}
)
; backgroundLayer: "",
; backgroundLayerTransparency: 110,

Keypad_Init() {

static _init := 0
IfNotEqual _init, 0, return _init

	if not (_settings:=Keypad.settings:=new JSONData(Keypad.WORKING_DIRECTORY . "\settings.json"))
		return 0, ErrorLevel:=-6

	if not (FileExist(_filePattern:=Keypad.WORKING_DIRECTORY . "\keymaps\*.json"))
		return 0, ErrorLevel:=-5

	_str := ""

	Loop, Files, % _filePattern
	{

		if not (_data:=new JSONData(A_LoopFilePath))
			return 0, ErrorLevel:=-4

		Loop % (_rows:=_data.data.0).length - 1 {
			if (_rows[ a_index-1 ].length <> _rows[ a_index ].length)
				continue
		}

			SplitPath % A_LoopFileName,,,, _layout
			_str .= ",""" . _layout . """:" . RegExReplace(_data.raw, "\s", "")

	}
	if not ((_str <> ""))
		return 0, ErrorLevel:=-3

	if not (_f:=FileOpen(Keypad.WORKING_DIRECTORY . "\Keypad.html", "r", "UTF-8"))
		return 0, ErrorLevel:=-2
	Keypad._html := RegExReplace(_f.read(), "\$", "{" . LTrim(_str, ",") . "}"), _f.close()

	Autocomplete.getSelection := Func("Autocomplete_getSelectionRange")
	Autocomplete.shiftCaretPosition := Func("Autocomplete_shiftCaretPosition")

return 1
}
Keypad_New(this, _style:="") {

	if not (Keypad.Init())
		return false

	_GUI := this.GUI := new GUI("+ToolWindow +AlwaysOnTop -Caption")
	, _GUI.onClose := Func("Keypad_GUI_GUICloseEvent")

	_GUI.setMargin(_m:=5, _m)
	_GUI.add("Text", "vText_1 x0 y0 h" . 21 . " Border").onEvent := Func("Keypad_GUI_Text_1")

	_control := _GUI.add("InternetExplorerServer", "vInternetExplorerServer_1 x" . 2 * _m . " y" . (_m + 21 + 58 + 3 * _m) . " +Disabled")
	try {
		if (_style && FileExist(_file:=Keypad.WORKING_DIRECTORY . "\styles\" . _style . ".css")) {
			_control.docWrite(RegExReplace(Keypad._html, "si).+?<style>\K.+?(?=</style>)", (_file:=FileOpen(_file, "r", "UTF-8")).read())), _file.close(), this.style := _style
		} else _control.docWrite(Keypad._html), this.style := "default"
	} catch {
		return false, ErrorLevel:=-1
	}
	sleep, 300

	_doc := _control.doc, this.keyboard := _doc.parentWindow.Keyboard

	_input := _doc.createElement("span"), _input.setAttribute("id", "input"), _input.setAttribute("class", "autocomplete"), _doc.body.appendChild(_input)
	_menu := _doc.createElement("span"), _menu.setAttribute("id", "menu"), _menu.setAttribute("class", "autocomplete"), _doc.body.appendChild(_menu)
	_sInput := _input.currentStyle, _sMenu := _menu.currentStyle

	_GUI.setColor(_doc.body.currentStyle.getAttribute("background-color"), _sInput.getAttribute("background-color"))
	, _GUI.setFont("s" . _sInput.getAttribute("font-size") . " c" . _sInput.color, _sInput.getAttribute("font-family"))

	_editOptions := "vAutocomplete_1 Section xm y" . _m + 21 . " h" . 58 . " Limit +Resize"
	, _editContent := ""
	, _menuOptions := "ys w160 -VScroll" ; +Disabled
	, _menuStyles := "s" . _sMenu.getAttribute("font-size") . " c" . _sMenu.color, _sMenu.getAttribute("font-family")
	_autocomplete := _GUI.add("Autocomplete", _editOptions, _editContent, _menuOptions, _menuStyles)
	, _autocomplete.appendHapax := true
	, _autocomplete.onSelect := Func("Keypad_Autocomplete_1_menuOnSelect")
	, _autocomplete.minSize.h := 38
	, _autocomplete.onSize := Func("Keypad_Autocomplete_1_onSize")

	_detectHiddenWindows := A_DetectHiddenWindows
	DetectHiddenWindows, On
		_GUI.show("hide", "Keypad"), _GUI.setTransparency(0)
		; _GUI := this.backgroundLayer := new GUI("+ToolWindow +AlwaysOnTop -Caption +E0x20") ; WS_EX_CLICKTHROUGH
		; _GUI.setColor("000000")
		; _GUI.show("hide x-50 w" . A_ScreenWidth+100 . " y-50 h" . A_ScreenHeight+100), _GUI.setTransparency(0)
	DetectHiddenWindows % _detectHiddenWindows
	; this.backgroundLayer.show()
	this.GUI.show()

}
Keypad_setActivationContext(this, _type, _title) {

	_baseContext := Hotkey.baseContext, _ty := _baseContext.type, _ti := _baseContext.title
	try Hotkey.setContext(_type, _title)
	catch
		return false

		this.activationContext.type := _type, this.activationContext.title := _title
		Hotkey.setContext(_ty, _ti)
		return true

}
Keypad_setHotkeys(this, _keyboard:=true, _joystick:=true) {

static _ := (Hotkey.setGroup("Keypad_keyboard"), Hotkey.setGroup("Keypad_joystick"), Hotkey.setGroup())
static _o := {Left: [ "columns", -1 ], Up: [ "rows", -1 ], Right: [ "columns", 1 ], Down: [ "rows", 1 ]}
static _bs
static _b := (_bs:=new JSONData.DataTypes.Object).isBackSpace := true

	_settings := Keypad.settings, _hotkeys := _settings.data.hotkeys
	_activationContext := this.activationContext, _ty := _activationContext.type, _ti := _activationContext.title

	_autocomplete := this.GUI.controls["Autocomplete_1"]

	if (_keyboard) {

		try {

		Hotkey.deleteAll("Keypad_keyboard"), Hotkey.setGroup("Keypad_keyboard"), _khk := _hotkeys.keyboard

		Hotkey.setContext(_ty, _ti)
			new Hotkey(_khk.displayEvent, ObjBindMethod(this, "__display"))
		Hotkey.setContext("IfWinActive", this.GUI.AHKID)
			for _direction, _oDirection in _o
				new Hotkey(_direction, ObjBindMethod(this, "_keyboardButtonsShiftFocus", _oDirection*))
			new Hotkey("Enter", ObjBindMethod(this, "__keyPress"))
			, new Hotkey(_khk.submitEvent, ObjBindMethod(this, "__submit", this.noHideOnSubmit, true))
			, new Hotkey(_khk.inputShiftCaretPosition_L, ObjBindMethod(_autocomplete, "shiftCaretPosition", -1))
			, new Hotkey(_khk.inputShiftCaretPosition_R, ObjBindMethod(_autocomplete, "shiftCaretPosition", 1))
			, new Hotkey(_khk.autocompleteMenuSet_U, ObjBindMethod(_autocomplete, "menuSetSelection", -1))
			, new Hotkey(_khk.autocompleteMenuSet_D, ObjBindMethod(_autocomplete, "menuSetSelection", 1))
			, new Hotkey(_khk.autocompleteAutocompletion, ObjBindMethod(_autocomplete, "menuGetSelection"))
			, new Hotkey("BackSpace", ObjBindMethod(this, "__keyPress", _bs))
			, new Hotkey("Space", ObjBindMethod(this, "__keyPress", A_Space))

		} catch {
			return false, ErrorLevel:=-1
		} finally Hotkey.setGroup(), Hotkey.clearContext()

	}

	if (_joystick) {

		if (_jInput:=this.jInput)
			_jInput.dispose()
		_jInput := this.jInput := new Joystick()
		(this.jInputOnConnection && _jInput.onConnection(this.jInputOnConnection))
		(this.jInputOnDisconnected && _jInput.onDisconnected(this.jInputOnDisconnected))

		_n := 0
		if (_gamepad:=_jInput.connect(_settings.data.joystick.port)) {
			_jInput.thumbsticks.L.EventMonitor := this._jInputThumbstickLEventMonitor.bind(this)
			if not (_jInput.buttons.length() >= 12)
				_n += 0x10
			if (_jInput.hasPOV) {
				_jInput.dPad.EventMonitor := this._jInputDPadEventMonitor.bind(this)
			} else _n += 0x01
			if (_jInput.hasZRAxis) {
				_jInput.thumbsticks.R.EventMonitor := this._jInputThumbstickREventMonitor.bind(this)
			} else _n += 0x02
		}
		if (_gamepad) {

			try {

			Hotkey.deleteAll("Keypad_joystick"), Hotkey.setGroup("Keypad_joystick"), _jhk := _hotkeys.joystick
			Hotkey.setContext("IfWinActive", this.GUI.AHKID)
				(new Hotkey(_jhk.keyPressEvent, ObjBindMethod(this, "__keyPress"))).ITERATOR_DELAY := 550
				new Hotkey(_jhk.submitEvent, ObjBindMethod(this, "__submit", this.noHideOnSubmit, true))
				, new Hotkey(_jhk.inputShiftCaretPosition_L, ObjBindMethod(_autocomplete, "shiftCaretPosition", -1))
				, new Hotkey(_jhk.inputShiftCaretPosition_R, ObjBindMethod(_autocomplete, "shiftCaretPosition", 1))
				, new Hotkey(_jhk.autocompleteMenuSet_U, ObjBindMethod(_autocomplete, "menuSetSelection", -1))
				, new Hotkey(_jhk.autocompleteMenuSet_D, ObjBindMethod(_autocomplete, "menuSetSelection", 1))
				, new Hotkey(_jhk.autocompleteAutocompletion, ObjBindMethod(_autocomplete, "menuGetSelection"))
				, new Hotkey(_jhk.inputSendBackSpace, ObjBindMethod(this, "__keyPress", _bs))
				, new Hotkey(_jhk.inputSendSpace, ObjBindMethod(this, "__keyPress", A_Space))
			Hotkey.setContext(_ty, _ti)
				new Hotkey(_jhk.displayEvent, ObjBindMethod(this, "__display"))

			} catch {
				return false, ErrorLevel:=-1
			} finally Hotkey.setGroup(), Hotkey.clearContext()

		} else Hotkey.disableAll("Keypad_joystick")

	ErrorLevel := _n
	}

}
Keypad_displayEvent(this, _boolean:="") {

	_isVisible := this.GUI.visible

	if ((_boolean <> _isVisible)) {

		if not (_isVisible) {

			ControlGetFocus, _focusedControl, A
			ControlGet, _ID, Hwnd,, % _focusedControl, A
			ControlGet, _lineCount, LineCount,,, % (_AHKID:="ahk_id " . _ID)
			this.lastFoundControl.HWND := (_lineCount) ? _ID : ""
			this.GUI.setTransparency(this.GUITransparency) ; , this.backgroundLayer.setTransparency(this.backgroundLayerTransparency)
			this.GUI.activate()
			_jInput := this.jInput
			_jInput.thumbsticks.L.watch(12), (_jInput.hasPOV && _jInput.dPad.watch(110)), (_jInput.hasZRAxis && _jInput.thumbsticks.R.watch(55))

		} else {
			_jInput := this.jInput
			for _axis, _thumbstick in _jInput.thumbsticks
				_thumbstick.watch("Off")
			(_jInput.hasPOV && _jInput.dPad.watch("Off"))
			this.GUI.deactivate()
			this.GUI.setTransparency(0) ; , this.backgroundLayer.setTransparency(0)
		}
		(this.onDisplay && this.onDisplay.call(this, this.GUI.visible))

	return true
	}
	return false

}
Keypad_keyPressEvent(this, _key:="") {

	_keyboard := this.keyboard, _autocomplete := this.GUI.controls["Autocomplete_1"]
	if (_key = "")
		_grid := _keyboard.grid, _key := ((((_keyboard.keymaps)[ _keyboard.layout ])[ _keyboard.layer ])[ _grid.rows.current ])[ _grid.columns.current ]

		if (IsObject(_key)) {

			if (_key.hasOwnProperty("value")) {
				_keyboard.sendParam := 0
				ControlSend,, % _key.value, % _autocomplete.AHKID
			} else if (_key.hasOwnProperty("isBackSpace")) {
				if (_key.isBackSpace) {
					if (_autocomplete.get() <> "") {
						_autocomplete.set("focus")
						ControlSend,, {BackSpace}, % _autocomplete.AHKID
					} else this.__submit(false, false)
				}
			} else if (_key.hasOwnProperty("sendParam")) {
				_keyboard.sendParam := _key.sendParam
			} else if (_key.hasOwnProperty("send")) {
				try _key := (_key.send)[_keyboard.sendParam], _keyboard.sendParam := 0
				ControlSend,, % _key, % _autocomplete.AHKID
			} else if (_key.hasOwnProperty("setCaretPos")) {
				(_key.setCaretPos && _autocomplete.shiftCaretPosition(_key.setCaretPos))
			} else if (_key.hasOwnProperty("toLayer")) {
				this.keyboard.setLayer(_key.toLayer)
			} else if (_key.hasOwnProperty("submit")) {
				if (_key.submit)
					this.__submit(this.noHideOnSubmit, true)
			}

		} else {
			_keyboard.sendParam := 0
			ControlSend,, % _key, % _autocomplete.AHKID
		}
		(this.onKeyPress && this.onKeyPress.call(this, _autocomplete, _key))

}
Keypad_submitEvent(this, _nohide:=false, _prm:=true) {

	if not (this.GUI.visible)
		return
	_autocomplete := this.GUI.controls["Autocomplete_1"]
	_v := _autocomplete.get(), _autocomplete.set(), _autocomplete.menu.set("", this.GUI.delimiter)
	if not (_nohide)
		this.__display()

	if (_prm && this.onSubmit) {
		this.onSubmit.call(this, _v, this.lastFoundControl.HWND)
	}

}
Keypad_setLayout(this, _layout) {

	static _l := ""

	_keyboard := this.keyboard
	if not (_v:=_keyboard.setLayout(_layout))
		return false, ErrorLevel:=(_v < 0)

	_columns := _keyboard.grid.columns, _rows := _keyboard.grid.rows

	_GUI := this.GUI, _controls := _GUI.controls, _autocomplete := _controls["Autocomplete_1"], _AXC := _controls["InternetExplorerServer_1"]

	(Autocomplete.sources.hasKey(_layout) || Autocomplete.addSourceFromFile(_layout, Keypad.WORKING_DIRECTORY . "\Autocompletion\" . _layout))
	((_l <> "") && Autocomplete.sources.remove(_l)), _autocomplete.menu.set("", _GUI.delimiter), _autocomplete.setSource(_layout), _l := _layout

		_w := _keyboard.buttons.wDesired * (_columns.maxIndex + 1), _h := _keyboard.buttons.hDesired * (_rows.maxIndex + 1)
		, _AXC.set("move", "w" . _w . " h" . _h)
		_autocomplete.minSize.w := _autocomplete.maxSize.w := _w
		GuiControlGet, _pos, Pos, % _autocomplete.HWND
		_autocomplete.onSize(_GUI, _controls, _w, _posh, _x:=_posx + _w, _y:=_posy + _posh)
		, _autocomplete.resizer.set("moveDraw", "x" . _x - 7 . " y" . _y - 7)
		sleep, 100
		_controls["Text_1"].set("move", "w" . _GUI.getPos().w - 5)

	WinSet, Redraw,, % this.AHKID
	_autocomplete.set()

return true
}
Keypad_setLayer(_layer) {
return this.keyboard.setLayer(_layer)
}

Keypad_destroy(this) {

	this.onDisplay := this.onKeyPress := this.onSubmit := ""
	Hotkey.deleteAll("Keypad_keyboard"), Hotkey.deleteAll("Keypad_joystick")
	this.jInput.dispose()
	; GUI.destroy(this.backgroundLayer)
	GUI.destroy(this.GUI)

}

Keypad_updateSettings() {
Keypad.settings.updateData()
}

Keypad_keyboardButtonsShiftFocus(this, _axis, _δ) {
this.keyboard.buttonsShiftFocus(_axis, _δ)
}


Keypad_GUI_Text_1() {
PostMessage, 0xA1, 2,,, A ; WM_NCLBUTTONDOWN, HTCAPTION
}
Keypad_Autocomplete_1_onSize(_autocomplete, _GUI, _controls, _w, _h, _mousex, _mousey) {
_autocomplete.set("move", "w" . _w . " h" . _h)
_controls["InternetExplorerServer_1"].set("move", "y" . 21 + _h + 3 * _GUI.margin.v . " w" . _w - 2 * _GUI.margin.h)
ControlGetPos,, _y,, _h,, % "ahk_id " . _controls["InternetExplorerServer_1"].HWND
_autocomplete.menu.set("move", "x" . _w + 4 * _GUI.margin.h . " h" . _y + _h)
_GUI.show("AutoSize")
}

Keypad_jInputThumbstickLEventMonitor(this, _jInput, _δX, _δY) {
SetMouseDelay, -1
MouseMove, % _δX, % _δY, 0, R
}
Keypad_jInputDPadEventMonitor(this, _jInput, _direction) {
static _o := {Left: [ "columns", -1 ], Up: [ "rows", -1 ], Right: [ "columns", 1 ], Down: [ "rows", 1 ]}
	if (WinActive(this.GUI.AHKID))
		_e := _o[_direction], this._keyboardButtonsShiftFocus(_e.1, _e.2)
}
Keypad_jInputThumbstickREventMonitor(this, _jInput, _δX, _δY) {

static _o := {"Left": [ "x", -1 ], "Up": [ "y", -1 ], "Right": [ "x", 1 ], "Down": [ "y", 1 ]}

	SetWinDelay, -1

	_GUI := this.GUI
	if (_δX) {
		WinGetPos, _x, _y,,, % _GUI.AHKID
		_v := (_w:=_o[_δX > 0 ? "Right" : "Left"]).1, _%_v% += 40*_w.2, _GUI.show("restore x" . _x " y" . _y)
	}
	if (_δY) {
		WinGetPos, _x, _y,,, % _GUI.AHKID
		_v:=(_w:=_o[_δY > 0 ? "Down" : "Up"]).1, _%_v% += 40*_w.2, _GUI.show("restore x" . _x " y" . _y)
	}

}

Keypad_Autocomplete_1_menuOnSelect(_autocomplete, _input, _selection) {
_s := _autocomplete.getSelection(), _l := SubStr(_input, 1, _s), _r := SubStr(_input, _s + 1)
ControlSetText,, % StrReplace(RegExReplace(_l, "^(.*\s)?\K[^\s]*", _selection), "`n", "`r`n") . _r, % _autocomplete.AHKID
sleep, 50
SendMessage, 0xB1, 0, -1,, % _autocomplete.AHKID ; EM_SETSEL (https://msdn.microsoft.com/en-us/library/windows/desktop/bb761661(v=vs.85).aspx)
_autocomplete.shiftCaretPosition()
}

Keypad_GUI_GUICloseEvent() {
return -1
}

; ---------------------------------------------

Autocomplete() {
static _ := Autocomplete()
GUI.customControlTypes.Autocomplete := Autocomplete
}
Class Autocomplete extends GUI.Control {

	static sources := []

	source := ""
	, appendHapax := false
	, onSelect := ""

	__New(_GUI, _options, _text, _extra*) {

		_options := RegExReplace(_options, "i)\s\K\+?Resize", "", _resize), base.__New(_GUI, "Edit", _options, _text)

		if (_resize) {
			GuiControlGet, _pos, Pos, % this.HWND
			(this.resizer:=_GUI.add("Text", "0x12 w11 h11 x" . _posx + _posw - 7 . " y" . _posy + _posh - 7, Chr(9698))).onEvent := this.__resize.bind(this)
			this.minSize := {w: 21, h: 21}, this.maxSize := {w: A_ScreenWidth, h: A_ScreenHeight}, this.onSize := ""
		}
		this.AHKID := "ahk_id " . this.HWND
		this.onEvent := this.suggestWordList.bind(this)
		Gui, % _GUI.HWND . ":Font", % StrReplace(_extra.2, "c#", "c"), % StrReplace(_extra.3, "c#", "c")
		(this.menu:=_GUI.add("ListBox", _extra[1])).AHKID := "ahk_id " . _GUI.lastFoundControl.HWND
		_GUI.setFont(_GUI.font.options, _GUI.font.fontname)

		this.disabled := false, this.startAt := 2, this.endChar := A_Space
		this.selectedItem := 1

	}
	__resize(_GUI, _resizer) {

		if not (this.onSize)
			return

		_coordModeMouse := A_CoordModeMouse
		CoordMode, Mouse, Client

		GuiControlGet, _pos, Pos, % this.HWND
		_x := _posx, _y := _posy, _minSz := this.minSize, _maxSz := this.maxSize

		while (GetKeyState("LButton", "P")) {
			MouseGetPos, _mousex, _mousey
			_w := _mousex - _x, _h := _mousey - _y
			if (_w <= _minSz.w)
				_w := _minSz.w
			else if (_w >= _maxSz.w)
				_w := _maxSz.w
			if (_h <= _minSz.h)
				_h := _minSz.h
			else if (_h >= _maxSz.h)
				_h := _maxSz.h
			this.onSize.call(this, _GUI, _GUI.controls, _w, _h, _mousex, _mousey)
			GuiControlGet, _pos, Pos, % this.HWND
			_resizer.set("moveDraw", "x" . _posx + _posw - 7 . " y" . _posy + _posh - 7)
		sleep, 15
		}
		CoordMode, Mouse, % _coordModeMouse

	}
	addSourceFromFile(_source, _fileFullPath) {
		_list := (_f:=FileOpen(_fileFullPath, 4+0, "UTF-8")).read()
		if (A_LastError)
			return !ErrorLevel:=1, _f.close()
			this.addSource(_source, _list, _fileFullPath)
		return !ErrorLevel:=0, _f.close()
	}
	addSource(_source, _list, _fileFullPath:="") {

		_sources := Autocomplete.sources
		(_sources.hasKey(_source) || _sources[_source] := {path: _fileFullPath})

		_list := "`n" . _list . "`n"
		Sort, _list, D`n U
		ErrorLevel := 0
		_list := _sources[_source].list := LTrim(_list, "`n")


		while ((_letter:=SubStr(_list, 1, 1)) && _pos:=RegExMatch(_list, "Psi)\Q" . _letter . "\E.*\n\Q" . _letter . "\E.+?\n", _len)) {
			_sources[_source][_letter] := SubStr(_list, 1, _pos + _len - 1), _list := SubStr(_list, _pos + _len)
		}

	}
	setSource(_source) {
	if (Autocomplete.sources.hasKey(_source))
		return !ErrorLevel:=0, this.source := _source
	return !ErrorLevel:=1
	}
	suggestWordList(_GUI, _control) {

		if (this.disabled)
			return
		_delimiter := ""
		if (this.delimiter <> (_match:="`n"))
			_delimiter := this.delimiter, _GUI.setOptions("+Delimiter`n")
		_lastInput := this.lastInput[_isWord, _isSuggested]
		if (_lastInput) {
			_letter := SubStr(_lastInput, 1, 1)
			if not (_isWord) {
				if (_str:=this.sources[ this.source ][_letter]) {
					if (InStr(_lastInput, "*") && (_parts:=StrSplit(_lastInput, "*")).length() = 2) {
						_match .= RegExReplace(_str, "`am)^(?!" _parts.1 ".*" _parts.2 ").*\R") ; many thanks to AlphaBravo for this regex
					} else RegExMatch("$`n" . _str, "i)\n\Q" . _lastInput . "\E.*\n\Q" . _lastInput . "\E.+?(?=\n)", _match)
				}
			} else if (this.appendHapax && (StrLen(_lastInput) > 3) && !InStr(_lastInput, "*") && !_isSuggested) {
				this.__hapax(_letter, _lastInput)
			}
		}
		this.menu.set("", _match), this.menu.set("choose", this.selectedItem:=1), ((_delimiter <> "") && _GUI.setOptions("+Delimiter" . _delimiter))

	}
	__hapax(_letter, _value) {

		if ((_source:=this.sources[ this.source ]).hasKey(_letter))
			_source.list := StrReplace(_source.list, _source[_letter], "")
		else _source[_letter] := ""
		_v := _source[_letter] . Trim(_value, "`n") . "`n"
		Sort, _v, D`n U
		_source.list .= (_source[_letter]:=_v)
		if (_source.path <> "") {
			(_f:=FileOpen(_source.path, "w", "UTF-8")).write(LTrim(_source.list, "`n")), _f.close()
		}

	}
	menuSetSelection(_prm) {

		if (this.disabled or !Round(_prm)+0)
	return
		if (_prm > 0) {
			_menu := this.menu
			SendMessage, 0x18B, 0, 0,, % _menu.AHKID ; LB_GETCOUNT
			_menu.set("choose", (this.selectedItem < ErrorLevel) ? ++this.selectedItem : ErrorLevel)
		} else this.menu.set("choose", (this.selectedItem - 1 > 0) ? --this.selectedItem : 1)

	}
	menuGetSelection() {
	if (!this.disabled && this.hasSuggestions)
		(this.onSelect && this.onSelect.call(this, this.get(), this.menu.get()))
	}

	dispose() {
	this.onSize := "", this.onSelect := "", base.dispose()
	}

	disabled {
		set {
		this._enabled := !value
		}
		get {
		return !this._enabled
		}
	}
	startAt {
		set {
		return this._startAt := (value > 1) ? value : 1
		}
		get {
		return this._startAt
		}
	}
	endChar {
		set {
		return this._endChar := (StrLen(value) = 1) ? value : A_Space
		}
		get {
		return this._endChar
		}
	}

	lastInput[ ByRef _isWord:="", ByRef _isSuggested:="" ] {
		get {
			_input := this.get(), _s := this.getSelection()
			if ((StrReplace(SubStr(_input, _s, 1), "`n", "") <> "") && (StrReplace(SubStr(_input, _s + 1, 1), A_Space, "") = "")) {
				_leftSide := SubStr(_input, 1, _s)
				_start := RegExMatch(_leftSide, "P)^(.*\s)?\K.*\s$", _lastInputLength)
				if (_isWord:=(_lastInputLength > this.startAt)) {
					_match := SubStr(_input, _start, _lastInputLength - 1)
					ControlGet, _choice, Choice,,, % this.menu.AHKID
					_isSuggested := (_match = _choice)
				return _match
				}
				RegExMatch(_leftSide, "^(.*\s)?\K.{" . this.startAt . ",}", _match)
			return _match
			}
		}
	}
	hasSuggestions {
		get {
			ControlGet, _list, List,,, % this.menu.AHKID
		return (_list <> "")
		}
	}

}

Autocomplete_shiftCaretPosition(this, _prm:=0) {
this.getSelection(, _pos), _pos += _prm
this.set("focus")
SendMessage, 0xB1, %_pos%, %_pos%,, % this.AHKID ; EM_SETSEL (https://msdn.microsoft.com/en-us/library/windows/desktop/bb761661(v=vs.85).aspx)
}
Autocomplete_getSelectionRange(this, ByRef _startSel:="", ByRef _endSel:="") { ; cf. also: https://github.com/dufferzafar/Autohotkey-Scripts/blob/master/lib/Edit.ahk
	_id := this.AHKID, VarSetCapacity(_startPos, 4, 0), VarSetCapacity(_endPos, 4, 0)
    SendMessage 0xB0, &_startPos, &_endPos,, % _id ; EM_GETSEL
    _startSel := NumGet(_startPos), _endSel := NumGet(_endPos)
	StrReplace(SubStr(this.get(), 1, _endSel), "`n",, _count)
return _endSel - _count
}
