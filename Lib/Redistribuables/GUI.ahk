Class GUI {
; cf https://github.com/Run1e/Vibrancer/blob/master/lib/Class%20GUI.ahk

	static instances := []
		, customControlTypes := {InternetExplorerServer: GUI.InternetExplorerServer, ShellEmbedded: GUI.ShellEmbedded}

	hidden := true
	, transparency := 255
	, margin := {h: 10, v: 6}
	, controls := []
	, delimiter := "|"
	, color := {}
	, font := {}

	__New(_options:="", _title:="") {

		local _ID
		GUI, New, % "-DPIScale +LabelGUI_on +hwnd_ID " . _options, % _title
		this.AHKID := "ahk_id " . (this.HWND:=_ID)
		this.onSize := [], this.onClose := []

	return GUI.instances[_ID] := this
	}

	add(_controlType, _options:="", _text:="", _extra*) {

	local _v, _subClass, _control

		if (RegExMatch(A_Space . _options, "\s+v\K\w+", _v))
			this.lastControlV := _v
		if (IsObject(_text))
			try _text := (_text.controls)[_v]
			catch {
				_text := ""
			}

		if not (GUI.customControlTypes.hasKey(_controlType)) {
			_control := new GUI.Control(this, _controlType, _options, _text)
			return this.controls[ (_v <> "") ? _v : this.lastControlV:=_control.HWND ] := _control
		} else {
			_subClass := GUI.customControlTypes[_controlType]
			_control := new _subClass(this, _options, _text, _extra*)
		return this.controls[ (_v <> "") ? _v : this.lastControlV:=_control.HWND ] := _control
		}

	}
	lastFoundControl {
		get {
		return this.controls[ this.lastControlV ]
		}
	}
	focusedControl {
		get {
			GuiControlGet, _v, % this.HWND . ":Focus"
		return _v
		}
	}
	focusedControlV {
		get {
			GuiControlGet, _v, % this.HWND . ":FocusV"
		return _v
		}
	}

	setDefault() {
	GUI, % this.HWND . ":Default"
	}
	setOptions(_options) {
	GUI, % this.HWND . ":" _options
		if (_pos:=InStr(_options, "+Delimiter", false)) {
			this.delimiter := SubStr(_options, _pos + 10, 1)
		}
	}

	show(_options:="", _title:="") {
	if (_title <> "") {
		GUI, % this.HWND . ":Show", % _options, % _title
	} else GUI, % this.HWND . ":Show", % "NA " . _options
	this.hidden := !!InStr(_options, "Hide", false)
	}
	restore() {
	this.show("restore")
	}
	activate() {
	if not (this.hidden)
		WinActivate % this.AHKID
	}
	deactivate() {
	if (WinActive(this.AHKID))
		; SendInput, {Alt Down}{Esc}{ALt Up}
		SendInput, !{Esc}
	}
	hide() {
	GUI, % this.HWND . ":Hide"
	this.hidden := true
	}
		visible {
			get {
			return this.transparency && !this.hidden
			}
		}

	close(_prm:=false) {
	if not (WinExist(this.AHKID))
        return false, ErrorLevel:=-1
		if not (_prm)
			return !ErrorLevel:=!this.hidden:=DllCall("User32.dll\PostMessageW", "Ptr", this.HWND, "UInt", "0x0002", "Ptr", 0, "Ptr", 0)
		else SendMessage, 0x112, 0xF060,,, % this.AHKID
	}

	getPos() { ; cf. https://github.com/flipeador/AutoHotkey/blob/master/Lib/window/GetWindowPos.ahk

	static _o := {x: "", y: "", w: "", h: ""}

		VarSetCapacity(_rect, 16, 0)
		if not (DllCall("User32.dll\GetWindowRect", "Ptr", this.HWND, "UPtr", &_rect))
			return false

		_x := _o.x := NumGet(&_rect, "Int"), _y := _o.y := NumGet(&_rect + 4, "Int")
		, _o.w := NumGet(&_rect + 8, "Int") - _x
		, _o.h := NumGet(&_rect + 12, "Int") - _y
		return _o

	}
	setPos(_x:="", _y:="", _w:="", _h:="") { ; cf. https://github.com/flipeador/AutoHotkey/blob/master/Lib/window/SetWindowPos.ahk

	if not (_oPos:=this.getPos())
		return false

		for _psSz, _value in _oPos
			((_%_psSz% + 0 <> "") || _%_psSz%:=_value)
		return (DllCall("User32.dll\SetWindowPos", "Ptr", this.HWND, "Ptr", 0, "Int", _x, "Int", _y, "Int", _w, "Int", _h, "UInt", "0x221C"))

	}

	disable() {
	GUI, % this.HWND . ":+Disabled"
	}
	enable() {
	GUI, % this.HWND . ":-Disabled"
	}

	submit(_hide:=false) {
		if not (_hide)
			GUI, % this.HWND . ":Submit", NoHide
		else {
			GUI, % this.HWND . ":Submit"
			this.hidden := true
		}
	}

	setMargin(_hMargin:="", _vMargin:="") {
		GUI, % this.HWND . ":Margin", % _hMargin ? (this.margin.h:=_hMargin) : this.margin.h, % _vMargin ? (this.margin.v:=_vMargin) : this.margin.v
	}
	setColor(_backgroundColor:="Default", _controlColor:="Default") {
		GUI, % this.HWND . ":Color", % this.color.background:=LTrim(_backgroundColor, "#"), % this.color.control:=LTrim(_controlColor, "#")
	}
	setFont(_options:="s9 norm cDefault", _font:="Segoe UI") {
		GUI, % this.HWND . ":Font", % StrReplace(this.font.options:=_options, "c#", "c"), % this.font.fontname:=_font
	}

	setTransparency(_t) {

	static _signs := {"-": -1, "+": 1}

		if (_signs.hasKey(_s:=SubStr(Trim(_t), 1, 1))) {
			_t := _signs[_s] * LTrim(_t, _s)
			if not (_t+0 <> "")
		return false, ErrorLevel:=-2
			if ((_t < 0 and this.transparency = 0) or (_t > 0 and this.transparency = 255))
		return false, ErrorLevel:=-1
			this.transparency += _t
			WinSet, Transparent, % this.transparency, % this.AHKID
		return true, ErrorLevel:=0
		}
		else if _t between 0 and 255
			WinSet, Transparent, % this.transparency:=_t, % this.AHKID
		else if (_t = -1 || _t = "Off")
			WinSet, Transparent, % this.transparency:="Off", % this.AHKID
		else return false, ErrorLevel:=1

	return true, ErrorLevel:=0
	}

	destroy(_GUI) {

	_ID := _GUI.HWND

		for _index, _control in _GUI.controls
			_control.dispose()
		_GUI.onSize := _GUI.onClose := ""

		GUI.instances.delete(_ID)
		try GUI, % _ID . ":Destroy"
		catch {
			return !ErrorLevel:=1
		}
		return !ErrorLevel:=0

	}

		Class BaseControl {

			set(_command:="", _controlParams:="") {
				GuiControl, % _command, % this.HWND, % _controlParams
			}
			get(_command:="", _param:="") {
				GuiControlGet, _outputVar, % _command, % this.HWND, % _param ; -pos,focus,focusV
			return _outputVar
			}
			disable(_boolean:=1) {
			this.set("enable" . !_boolean)
			}
			enable(_boolean:=1) {
			this.set("disable" . !_boolean)
			}

				dispose() {
				this.onEvent := ""
				}

					onEvent {
						set {
							if ((this.eventHandler:=value) <> "")
								this.set("+g", this.controlEvent.bind(this))
							else this.set("-g")
						}
					}

		}
			Class Control extends GUI.BaseControl {

				__New(_GUI, _controlType, _options:="", _text:="") {
				local _ID
					GUI, % (this.parent:=_GUI.HWND) . ":Add", % _controlType, % _options . " hwnd_ID", % _text
					this.HWND := _ID, this.v := _GUI.lastControlV
				}

					controlEvent(_ctrlHwnd, _guiEvent, _eventInfo, _errorLevel:="") {
						this.eventHandler.call(GUI.instances[ A_GUI ], this, _guiEvent, _eventInfo, _errorLevel)
					}

			}
			Class ActiveX extends GUI.BaseControl {
				doc {
					get {
					return this.component.document
					}
				}
			}
				Class ShellEmbedded extends GUI.ActiveX {

					__New(_GUI, _options, _text, _extra*) {

					local _ID, _v

						GUI, % (this.parent:=_GUI.HWND) . ":Add", ActiveX, % _options . " hwnd_ID", Shell.Explorer
						this.HWND := _ID
						if (_v:=this.v:=_GUI.lastControlV)
							(this.component:=%_v%).Silent := false, this.updateURI()

					return (ErrorLevel) ? false : this
					}
					updateURI(_param:="about:<!DOCTYPE HTML><meta http-equiv='x-ua-compatible' content='IE=Edge'>") {

						if ((SubStr(_param, 1, 8) = "file:///") and not FileExist(LTrim(_param, "file:///")))
					return false, ErrorLevel:=-1

						this.component.Navigate(_param)

						Loop {
						sleep, 100
						} Until ((_boolean:=(a_index > 100)) or !this.component.busy or this.component.readyState = 4)

						if (ErrorLevel:=_boolean)
							this.component.Stop()

					return !ErrorLevel
					}
					canOpenPDFFiles {
						get {
							Loop, Reg, HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, R
							{
								if (A_LoopRegName == "DisplayName") {
								RegRead, _v
									if (_v == "Foxit Reader") {
										RegRead, _selectedTasks, HKLM\%A_LoopRegSubKey%, Inno Setup: Selected Tasks
									return (InStr(_selectedTasks, "displayinbrowser"))
									}
								}
							}
							return false
						}
					}

				}
				Class InternetExplorerServer extends GUI.ActiveX {

					__New(_GUI, _options, _text, _extra*) {

					local _ID, _v

						GUI, % (this.parent:=_GUI.HWND) . ":Add", ActiveX, % _options . " hwnd_ID"
						, about:<!DOCTYPE html><meta http-equiv="X-UA-Compatible" content="IE=edge">
						this.HWND := _ID

						if (_v:=this.v:=_GUI.lastControlV)
							this.component := %_v%

					}
					docWrite(_html) {
					_doc := this.doc, _doc.open(), _doc.write(_html), _doc.close()
					}

				}

}
GUI_onSize(_hwnd, _eventInfo, _width, _height) {
(_instance:=GUI.instances[_hwnd]).onSize.call(_instance, _eventInfo, _width, _height)
}
GUI_onClose(_hwnd) {
if ((_instance:=GUI.instances[_hwnd]).onClose.call(_instance) = -1)
	return 1
}
