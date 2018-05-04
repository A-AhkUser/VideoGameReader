Class Hotkey {

	static keyboard := {IfWinActive: {}, IfWinNotActive: {}, IfWinExist: {}, IfWinNotExist: {}, If: {}}
		, joystick := {IfWinActive: {}, IfWinNotActive: {}, IfWinExist: {}, IfWinNotExist: {}, If: {}}
		, baseContext := {type: "IfWinActive", title: "A"}

	portNumber := ""
	, buttonNumber := ""
	, ITERATOR_DELAY := ""
	, ITERATOR_PERIOD := ""

	__New(_keyName, _params*) {

	static _ := Hotkey.setContext()

	_listLines := A_ListLines
	ListLines, Off

		if not (StrLen(_keyName:=Trim(_keyName)))
			throw ErrorLevel := 2

		for _index, _param in _params, _state := true {

			if not (Bound.Func._isCallableObject(_param)) {

				if not (_index = _params.length())
					throw ErrorLevel := 1
				_state := !!_params.pop()

			} else this.callbacks.push(_param)

		}

		if ((this.device:=Hotkey._inputDevices[ !!InStr(_keyName, "Joy") + 1 ]) = "joystick") {

			if not (this._joyKeyValidator(_keyName, _portNumber, _buttonNumber, _isKeyUp))
				throw ErrorLevel := 2

			_keyName := this.keyName := (this.portNumber:=_portNumber) . "Joy" . (this.buttonNumber:=_buttonNumber), this._isKeyUp := _isKeyUp
			Hotkey._createContext(this, _hotkeys, _context)

				if not (this._isDualHotkey:=(_context.hasKey(_keyName) && (this._isKeyUp <> _context[_keyName]._isKeyUp))) {

					this.ITERATOR_PERIOD := 95, this.ITERATOR_DELAY := 300, this._boundIterators := {}
					this._boundIterators.joyDelay := new Bound.Func.Iterator(this, "_joyDelay")

					if (_isKeyUp) {
						_f := this._joyButtonW.bind(this)
						this._boundIterators.joyWait := new Bound.Func.Iterator(this, "_joyWait")
					} else {
						_f := this._joyButtonR.bind(this)
						this._boundIterators.joyRepeat := new Bound.Func.Iterator(this, "_joyRepeat")
						, this.shouldIterate := true
					}

				} else {

					this := _context[_keyName]
					this.__press := this._callCallbackChain.bind({"callbacks": this.callbacks})
					, this.__released := this._callCallbackChain.bind({"callbacks": _params})

					_f := this._joyButtonR.bind(this)
					this._boundIterators.joyRepeat.delete(), this._boundIterators.joyRepeat := new Bound.Func.Iterator(this, "_joyRepeat2")
					, this.shouldIterate := true

				}
				if not (this._apply(_f))
					throw ErrorLevel

		} else {
			if ((this.keyName:=Hotkey._normalize(_keyName)) = "")
				throw ErrorLevel
			Hotkey._createContext(this, _hotkeys)
			if not (this._apply(this._callCallbackChain.bind(this)))
				throw ErrorLevel
		}
		this._enable(_state)

		ListLines % _listLines ? "On" : "Off"

	return _hotkeys[ this.context.type, this.context.title, this.keyName ] := this
	}

	delete() {

	static _junkFunc := Func("WinActive")

		if (this.disable()) {
		Hotkey.setContext(this.context.type, this.context.title)
			if (this._apply(_junkFunc)) {
				return this._remove(), Hotkey.setContext(Hotkey.baseContext.type, Hotkey.baseContext.title)
			}
		}
		Hotkey.setContext(Hotkey.baseContext.type, Hotkey.baseContext.title)
		return 0

	}
	enable(_boolean:=true) {

	Hotkey.setContext(this.context.type, this.context.title)

		if (this._apply(_boolean ? "On" : "Off")) {
			Hotkey.setContext(Hotkey.baseContext.type, Hotkey.baseContext.title)
		return true, this.enabled:=_boolean
		}
		return false, Hotkey.setContext(Hotkey.baseContext.type, Hotkey.baseContext.title)

	}
	disable() {

	Hotkey.setContext(this.context.type, this.context.title)

		if (this._apply("Off")) {
			Hotkey.setContext(Hotkey.baseContext.type, Hotkey.baseContext.title)
		return true, this.enabled:=false
		}
		return false, Hotkey.setContext(Hotkey.baseContext.type, Hotkey.baseContext.title)

	}

	onReleased(_callbacks*) {
		if (this.device = "joystick" && !this._isKeyUp)
			return new Hotkey(this.keyName . " Up", _callbacks*)
		throw Exception(-2)
	}

	; ===== CALLED VIA BASE OBJECT /=====

	disableAll(_group:="") {
	Hotkey._callAll("_disable", _group)
	}
	enableAll(_group:="") {
	Hotkey._callAll("_enable", _group)
	}
	deleteAll(_group:="") {
	Hotkey._callAll("_delete", _group)
	}

	setGroup(_group:="") {

		if (StrLen(_group)) {
			if not (Hotkey.hasKey(_group:=Hotkey._group:="G_" . _group)) {
				Hotkey[_group] := { keyboard: {IfWinActive: {}, IfWinNotActive: {}, IfWinExist: {}, IfWinNotExist: {}, If: {}}
									, joystick: {IfWinActive: {}, IfWinNotActive: {}, IfWinExist: {}, IfWinNotExist: {}, If: {}} }
			}
		} else Hotkey._group := ""

	}

	setContext(_type:="IfWinActive", _winTitle:="A") {

		if not (Trim(_type) ~= "^(IfWinActive|IfWinNotActive|IfWinExist|IfWinNotExist|If)$")
			throw Exception(-3)

		Hotkey.baseContext.title:=_winTitle
		Hotkey, % Hotkey.baseContext.type:=_type, % _winTitle

	}
	clearContext() {
	Hotkey.setContext()
	}

	; =====/ CALLED VIA BASE OBJECT =====
	; ===== PRIVATE /=====

	static _inputDevices := ["keyboard", "joystick"]
		, _group := ""

		callbacks := []
		, _boundIterators := {}

	_createContext(_instance, ByRef _hotkeys:="", ByRef _context:="") {

		_hotkeys := (StrLen(_instance.group:=Hotkey._group)) ? Hotkey[ _instance.group ][_instance.device] : Hotkey[_instance.device]
		, _baseContext := Hotkey.baseContext, _bType := _baseContext.type, _bTitle := _baseContext.title, _instance.context := {}

		if ((_context:=_hotkeys[ _bType ]).hasKey(_bTitle) and !(_context:=_context[ _bTitle]).hasKey(this.keyName)) {
			_instance.context.type := _bType, _instance.context.title := _bTitle
		} else _context := _hotkeys[ _instance.context.type:=_bType, _instance.context.title:=_bTitle ] := {}

	}

	_apply(_func) {
		Hotkey, % this.keyName, % _func, UseErrorLevel
		(ErrorLevel = 2 && ErrorLevel := 0)
	return !ErrorLevel
	}

	_callCallbackChain() {
	for _each, _callback in this.callbacks
		_callback.call()
	}

	_remove() {

		this.callbacks := "", this.__press := this.__released := ""
		for _method, _boundIterator in this._boundIterators
			_boundIterator.delete()

		_hotkeys := (this.group) ? Hotkey[ this.group ][ this.device ] : Hotkey[ this.device ]
		if not ((_context:=_hotkeys[_type:=this.context.type, _title:=this.context.title]).hasKey(this.keyName))
			return -1
		_context.remove(this.keyName), _l := NumGet(&_context, 4 * A_PtrSize)
		if not (--_l)
			_hotkeys[_type].remove(_title)
		return 1

	}
	_delete() {

	static _junkFunc := Func("WinActive")

		if (this._disable())
			if (this._apply(_junkFunc))
				return 1
		return 0

	}
	_enable(_boolean:=true) {
	return (this._apply((this.enabled:=_boolean) ? "On" : "Off"))
	}
	_disable() {
	return (this._apply("Off"))
	}

	_callAll(_method, _group) {

		_type := Hotkey.baseContext.type, _title := Hotkey.baseContext.title

		if (StrLen(_group)) {
			if not (Hotkey.hasKey(_group:="G_" . _group))
				throw Exception(-1)
			for _hkDevice, _obj1 in Hotkey[_group], _instances := [] {
				for _hkType, _obj2 in _obj1 {
					for _hkTitle, _obj3 in _obj2 {
						Hotkey.setContext(_hkType, _hkTitle)
							for _, _hotkey in _obj3 {
								_instances.push(_hotkey), _hotkey[_method].call(_hotkey)
							}
					}
				}
			}
		} else {
			for _index, _device in Hotkey._inputDevices, _instances := [] {
				for _hkType, _obj1 in Hotkey[_device] {
					for _hkTitle, _obj2 in _obj1 {
						Hotkey.setContext(_hkType, _hkTitle)
							for _, _hotkey in _obj2 {
								_instances.push(_hotkey), _hotkey[_method].call(_hotkey)
							}
					}
				}
			}
		}
		Hotkey.setContext(_type, _title)

		if (_method = "_delete")
			for _index, _hotkey in _instances
				_hotkey._remove()

	}

	_joyButtonR() {
	(this._isDualHotkey) ? this.__press.call() : this._callCallbackChain.bind(this).call()
	, this._boundIterators.joyDelay.setPeriod(-this.ITERATOR_DELAY)
	}
	_joyDelay() {
	if (this.shouldIterate && GetKeyState(this.keyName))
		this._boundIterators.joyRepeat.setPeriod(this.ITERATOR_PERIOD), this.shouldIterate := false
	else if (this._isDualHotkey)
		this.__released.call()
	}
	_joyRepeat() {
	GetKeyState(this.keyName) ? this._callCallbackChain.bind(this).call()
						 : (this._boundIterators.joyRepeat.setPeriod("Off"), this.shouldIterate := true)
	}
	_joyRepeat2() {
	GetKeyState(this.keyName) ? this.__press.call()
						 : (this._boundIterators.joyRepeat.setPeriod("Off"), this.__released.call(), this.shouldIterate := true)
	}
	_joyButtonW() {
	this._boundIterators.joyWait.setPeriod(25)
	}
	_joyWait() {
	(GetKeyState(this.keyName)) ? this._boundIterators.joyWait.setPeriod(25)
						 : (this._boundIterators.joyWait.setPeriod("Off"), this._callCallbackChain.bind(this).call())
	}

	_normalize(_hotkey, ByRef _useHook:="", ByRef _hasTilde:="") { ; cf. https://github.com/Lexikos/xHotkey.ahk/blob/master/Lib/HotkeyNormalize.ahk

	static _allMods := StrSplit("* <^ <! <+ <# >^ >! >+ ># ^ ! + #", " ")

		if (_p:=InStr(_hotkey, " & "))
			return Hotkey._normalize(RTrim(SubStr(_hotkey, 1, _p))) . " & " . Hotkey._normalize(LTrim(SubStr(_hotkey, _p+3)))

		_hotkey := RegExReplace(_hotkey, "i)[ `t]Up$", "", _isKeyUp, 1)

		if not (_p:=RegExMatch(_hotkey, "^[~$*<>^!+#]*\K(\w+|.)$"))
			return "", ErrorLevel:=2

		_mods := SubStr(_hotkey, 1, _p-1)

		if (_useHook:=InStr(_mods, "$") != 0)
			_mods := StrReplace(_mods, "$")
		if (_hasTilde:=InStr(_mods, "~") != 0)
			_mods := StrReplace(_mods, "~")

		_sortedMods := ""
		if (_mods)
			for _each, _aMod in _allMods
				if (InStr(_mods, _aMod))
					_sortedMods .= _aMod, _mods := StrReplace(_mods, _aMod)

		_key := SubStr(_hotkey, _p)
		if (_key ~= "i)^(.$|vk|sc)")
			_key := Format("{:L}", _key)
		else if (_n:=GetKeyName(_key))
			_key := _n
		else return "", ErrorLevel:=2

	return _sortedMods . _key . (_isKeyUp ? " Up" : "")
	}

	_joyKeyValidator(_joyKeyName, ByRef _portNumber:="", ByRef _buttonNumber:="", ByRef _isKeyUp:="") {

		if (RegExMatch(Trim(_joyKeyName), "Oi)^(?P<joystickPort>\d{1,2})?Joy((?P<buttonNumber>\d{1,2})(\s+(?P<isKeyUp>Up))?)$", _match)) {

			if ((_portNumber:=_match.value("joystickPort")) = "") {
				Loop 16 {
					if (GetKeyState((_portNumber:=a_index) . "JoyName"))
				break
				}
				_portNumber := 1
			} else if _portNumber not between 1 and 16
				return false

			_buttonNumber := _match.value("buttonNumber"), _isKeyUp := !!_match.value("isKeyUp")

			if _buttonNumber not between 1 and 32
				return false

		return true
		}
		return false

	}

	; =====/ PRIVATE =====

}
