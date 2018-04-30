global Program
Program_Init() {

static _init := 0
static _ := Program_Init()
IfNotEqual _init, 0, return _init

	Program :=
	(LTrim Join C
		{
			PID: DllCall("GetCurrentProcessId"),
			arguments: {},
			APPDATA_DIRECTORY: A_ScriptDir . "\AppData",
			Localization: {
				localizations: {},
				locales: "",
				locale: ""
			},
			Debug: {
				debugMode: false,
				exceptionHandler: Func("Object").bind("exception"),
				exceptionMonitor: "Program_Debug_exceptionMonitor",
				onException: "Program_Debug_onException",
				logFile: "",
				log: "Program_Debug_log"
			},
			dispose: "Program_dispose",
			exit: "Program_exit"
		}
	)

	_dir := Program.APPDATA_DIRECTORY, _localizations := Program.Localization.localizations, _locales := _localizations.locales
	Loop, Files, % _dir . "\Locales\*.json"
	{
		SplitPath % A_LoopFileName,,,, _languageCode
		if (_data:=new JSONData(A_LoopFilePath)) {
			try {
				_oLanguage := _data.data.language
				if not ((_oLanguage.name <> "") && ((_lNativeName:=_oLanguage.nativeName) <> "") && (_languageCode = _oLanguage.code))
					continue
				_locales .= _lNativeName . ","
			}
			_localizations[_lNativeName] := _data
		}
	}
	if not _localizations.hasKey("english")
		ExitApp
	_locales := RTrim(_locales, ",")

	VarSetCapacity(_buffer, 500, 0)
	if (DllCall("Version.dll\VerLanguageNameW", "UInt", DllCall("GetUserDefaultLCID"), "UPtr", &_buffer, "UInt", 250)) { ; https://msdn.microsoft.com/en-us/library/windows/desktop/ms647463(v=vs.85).aspx
		_locale := RegExReplace(StrGet(&_buffer, "UTF-16"), "\s.*", "")
		_stringCaseSense := A_StringCaseSense
		StringCaseSense, Off
		if _locale in %_locales%
		{
			Program.Localization.locale := Format("{:L}", _locale)
		} else Program.Localization.locale := "english"
	} else Program.Localization.locale := "english"

	if not (FileExist(_dir . "\Debug")) {
		FileCreateDir % _dir . "\Debug"
		if (ErrorLevel)
			ExitApp
	}
	Program.Debug.logFile := _dir . "\Debug\debug.log"

	IniRead, _defArgs, % _dir . "\manifest", cmd, DEF_ARGS
	IniRead, _config, % _dir . "\manifest", program
	if (_defArgs == "ERROR" || _config == "ERROR")
		ExitApp

	StrReplace(_defArgs:="debugMode," . _defArgs, ",",, _count), Program.ARG_MAX := _count + 1

	for _j, _k in A_Args {
		_v := StrSplit(_k, "="), _arg := _v.1
		if _arg in %_defArgs%
			Program.arguments[_arg] := _v.2
	}
	StringCaseSense % _stringCaseSense

	for _k, _v in Object(StrSplit(_config, ["=", "`n"])*)
		Program[_k] := (SubStr(_v, 1, 4) = "...\") ? RegExReplace(_v, "^\.{3}(?=\\)", _dir) : _v

	if (Program.Debug.debugMode := (Program.arguments.hasKey("debugMode") ? Program.arguments.debugMode : !A_IsCompiled)) {
		Menu, Tray, Icon
		if (A_IsCompiled)
			Menu, Tray, MainWindow
	} else ListLines, Off

return _init:=1
}
Program_Debug_exceptionMonitor(_exception) {

	if (Program.Debug.exceptionHandler.call(_exception)) {
		Program.Debug.log(_exception)
	ExitApp
	}
	return true

}
Program_Debug_onException(_callback) {
Program.Debug.exceptionHandler := (Bound.Func._isCallableObject(_callback)) ? _callback : Func("Object").bind("exception")
}
Program_Debug_log(_exception) {

_what := _exception.what, _message := _exception.message
FileAppend, [%A_DD%%A_MM%/%A_Hour%%A_Min%%A_Sec%:exception:%_what% (%_message%)]`r`n, % Program.Debug.logFile, UTF-8

	if (Program.Debug.debugMode) {
	ListLines
	WinWait % "ahk_id " . A_ScriptHwnd
	WinWaitClose
	}

}
Program_exit() {
ExitApp
}
Program_dispose() {
Program.Debug.exceptionHandler := ""
}