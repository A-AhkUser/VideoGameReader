﻿Class Joystick {
; cf. https://autohotkey.com/docs/scripts/JoystickTest.htm
; cf. https://autohotkey.com/docs/scripts/JoystickMouse.htm

	connect(_port:=0) {

		Loop % !(_port) {
			Loop 16 {
				if (GetKeyState(a_index . "JoyX")) {
					this.name := GetKeyState((_prefix:=this.prefix:=(this.port:=a_index) . "Joy") . "Name")
				break, 2
				}
			}
			return false
		}

		(_buttons:=this.buttons:=[])[ GetKeyState(_prefix . "Buttons") ] := ""
		Loop % _buttons.length()
			_buttons[ a_index ] := _prefix . a_index

		this.thumbsticks := {}, this.thumbsticks.L := new Joystick.Thumbstick(this, "X", "Y")

		_info := this.info := GetKeyState(_prefix . "Info")
		if (this.hasPOV:=(InStr(_info, "P") && InStr(_info, "D")))
			this.POV := _prefix . "POV", this.dPad := new Joystick.DPad(this)
		if (this.hasZRAxis:=(InStr(_info, "Z") && InStr(_info, "R")))
			this.thumbsticks.R := new Joystick.Thumbstick(this, "Z", "R")

	return this.connected
	}

	_isConnected := false
	connected {
		set {
		static _callbacks := {(true): "__connection", (false): "__disconnected"}
			((_f:=this[ _callbacks[ this._isConnected:=value ] ]) && _f.call(this))
		return value
		}
		get {
		return ((_state:=(GetKeyState(this.X) <> "")) <> this._isConnected) ? this.connected:=_state : _state
		}
	}
	onConnection(_callback) {
	if not (Bound.Func._isCallableObject(_callback))
		return !ErrorLevel:=1
	return !ErrorLevel:=0, this.__connection:=_callback
	}
	onDisconnected(_callback) {
	if not (Bound.Func._isCallableObject(_callback))
		return !ErrorLevel:=1
	return !ErrorLevel:=0, this.__disconnected:=_callback
	}

		dispose() {
		for _axis, _thumbstick in this.thumbsticks
			_thumbstick.dispose(), _thumbstick := ""
		this.thumbsticks := ""
		if (this.hasPOV)
			this.dPad.dispose(), this.dPad := ""
		this.__connection := this.__disconnected := ""
		}

	Class Axes {

		eventMonitor := ""

		__New(_device, _params*) {
		this.device := _device, this.watcher := new Bound.Func.Iterator(this, "_spot", _params*)
		}
		watch(_period:="Off") {
		if (this.eventMonitor)
			return true, this.watcher.setPeriod(_period)
		return false
		}
		dispose() {
		this.watch("Off"), this.watcher.delete(), this.eventMonitor := ""
		}

	}
	Class DPad extends Joystick.Axes {

		__New(_device, _invertAxis1:=false, _invertAxis2:=false) {
		base.__New(_device, _device["POV"]:=_device.prefix . "POV")
		this._keyToHoldDown := [], this.invertAxis[1] := _invertAxis1, this.invertAxis[2] := _invertAxis1
		}
		_spot(_POV) {
		_listLines := A_ListLines
		ListLines, Off
		static _keyToHoldDown

			if not (this.device.connected) {
				this.watcher.setPeriod("Off")
			return
			}
			if ((_POV:=GetKeyState(_POV)) < 0)
		return
			else if _POV between 22500 and 31500
				_keyToHoldDown := this._keyToHoldDown.1
			else if _POV between 4500 and 13500
				_keyToHoldDown := this._keyToHoldDown.2
			else if _POV between 13501 and 22500
				_keyToHoldDown := this._keyToHoldDown.3
			else _keyToHoldDown := this._keyToHoldDown.4

			ListLines % _listLines ? "On" : "Off"

			this.eventMonitor.call(this.device, _keyToHoldDown)

		}
		invertAxis[_axis:=""] {
			set {
				if (_axis = "") {
					if (value)
						this._keyToHoldDown := StrSplit("Right|Left|Up|Down", "|")
					else this._keyToHoldDown := StrSplit("Left|Right|Down|Up", "|")
				} else if (_axis = 1) {
					if (value)
						this._keyToHoldDown.1 := "Right", this._keyToHoldDown.2 := "Left"
					else this._keyToHoldDown.1 := "Left", this._keyToHoldDown.2 := "Right"
				} else if (_axis = 2) {
					if (value)
						this._keyToHoldDown.3 := "Up", this._keyToHoldDown.4 := "Down"
					else this._keyToHoldDown.3 := "Down", this._keyToHoldDown.4 := "Up"
				}
				return this["_invertAxis" . _axis] := value
			}
			get {
			return this["_invertAxis" . _axis]
			}
		}

	}
	Class Thumbstick extends Joystick.Axes {

		__New(_device, _axis1, _axis2, _threshold:=17, _multiplier:=0.30, _invertAxis1:=false, _invertAxis2:=false) {
			base.__New(_device, _device[_axis1]:=_device.prefix . _axis1, _device[_axis2]:=_device.prefix . _axis2)
			this.threshold := _threshold, this.multiplier := _multiplier
			this.invertAxis[1] := _invertAxis1, this.invertAxis[2] := _invertAxis1
		}
		_spot(_XOrZ, _YOrR) {
		_listLines := A_ListLines
		ListLines, Off
		static _δX, _δY

			if not (this.device.connected) {
				this.watcher.setPeriod("Off")
			return
			}
			_format := A_FormatFloat
			SetFormat, float, 03

			_XOrZ:=GetKeyState(_XOrZ), _YOrR:=GetKeyState(_YOrR)

			_u := this._thresholdUpper, _l := this._thresholdLower
			_boolean := false

			if (_XOrZ > _u) {
				_boolean := true, _δX := (_XOrZ - _u) * this.multiplier
			} else if (_XOrZ < _l) {
				_boolean := true, _δX := (_XOrZ - _l) * this.multiplier
			} else _δX := 0
			if (_YOrR > _u) {
				_boolean := true, _δY := (_YOrR - _u) * this.multiplier
			} else if (_YOrR < _l) {
				_boolean := true, _δY := (_YOrR - _l) * this.multiplier
			} else _δY := 0

			ListLines % _listLines ? "On" : "Off"

			if (_boolean) {
				this.eventMonitor.call(this.device, this._δXm * _δX, this._δYm * _δY)
			}
			SetFormat, float, % _format

		}
		invertAxis[_axis:=""] {
			set {
				if (_axis = "")
					this._δXm := this._δYm := (value) ? -1 : 1
				else if (_axis = 1)
					this._δXm := (value) ? -1 : 1
				else if (_axis = 2)
					this._δYm := (value) ? -1 : 1
				return this["_invertAxis" . _axis] := value
			}
			get {
			return this["_invertAxis" . _axis]
			}
		}

		threshold {
			set {
			return this._threshold := value, this._thresholdLower := 50 - value, this._thresholdUpper := 50 + value
			}
			get {
			return this._threshold
			}
		}

	}

}
