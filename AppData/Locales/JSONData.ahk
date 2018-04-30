Loop, Files, % A_ScriptDir . "\*.json"
{
J := new JSONData(A_LoopFilePath)
MsgBox % ErrorLevel
J.updateData()
}
Class JSONData {

	Init() {
	static _init := 0
	static _ := JSONData.Init()
	IfNotEqual, _init, 0, return _init
	_HTMLFile =
	(Ltrim Join C
	<!DOCTYPE html>
	<html>
		<head>
		<meta http-equiv="X-UA-Compatible" content="IE=edge"><meta charset="utf-8" />
		<title>HTMLFile</title>
			<script>
				var _null = null;
				function _delete(_o, _k) {
					delete _o[_k];
				}
			</script>
		</head>
	<body></body>
	</html>
	)
	(JSONData.oHTML:=ComObjCreate("HTMLFile")).write(_HTMLFile), JSONData.oHTML.parentWindow.JSONData := new JSONData.DataTypes.Array()
	return 1
	}

	__New(_fileFullPath) {

	static _i := -1
	static SYSTEM_ERROR_CODES := {0x2: "ERROR_FILE_NOT_FOUND", 0x3: "ERROR_PATH_NOT_FOUND"} ; https://msdn.microsoft.com/fr-fr/library/windows/desktop/ms681382(v=vs.85).aspx

		if not (_f:=FileOpen(this.fileFullPath:=_fileFullPath, "r", "utf-8"))
	return false, ErrorLevel := (SYSTEM_ERROR_CODES.hasKey(A_LastError)) ? SYSTEM_ERROR_CODES[ A_LastError ] : A_LastError

		try {
		JSONData.parse(this.raw:=_f.read(), _obj)
		(JSONData.oHTML.parentWindow.JSONData)[ this.index:=++_i ] := _obj
		} catch {
			_f.close()
		return false, ErrorLevel:="ERROR_PARSE_ERROR"
		}
		_f.close()

	return this
	}

		Class Enumerator {

			i := -1

			__New(_collection) {
			this.count := (this.keys:=JSONData.oHTML.parentWindow.Object.keys(this.collection:=_collection).slice()).length
			return this
			}
			_NewEnum() {
			return this
			}
			next(ByRef _k:="", ByRef _v:="") {

				if (++this.i < this.count) {
					_k := (this.keys)[ this.i ], _v := (this.collection)[_k]
				return true
				} return false, this.i:=-1

			}

		}

		stringify(_obj, _space:="", ByRef _str:="") {
		_str := JSONData.oHTML.parentWindow.JSON.stringify(_obj,, _space)
		}
		parse(_str, ByRef _obj) {
		_obj := JSONData.oHTML.parentWindow.JSON.parse(_str)
		}

			delete(_o, _k) {
			JSONData.oHTML.parentWindow._delete(_o, _k)
			}

		; ___________________________________________

		Class DataTypes {
		static null := JSONData.oHTML.parentWindow._null
		Class String {
		__New() {
		return JSONData.oHTML.parentWindow.String()
		}
		}
		Class Number {
		__New() {
		return JSONData.oHTML.parentWindow.Number()
		}
		}
		Class Object {
		__New() {
		return JSONData.oHTML.parentWindow.Object()
		}
		}
		Class Array {
		__New() {
		return JSONData.oHTML.parentWindow.Array()
		}
		}
		}

		; ___________________________________________

		restore() {
		JSONData.parse(this.raw, _obj), (JSONData.oHTML.parentWindow.JSONData)[ this.index ] := _obj
		}
		updateData(_space:=4) {
		JSONData.stringify(this.data, _space, _str), (_f:=FileOpen(this.fileFullPath, "w", "utf-8")).write(this.raw:=_str), _f.close()
		}

			data {
				get {
				return (JSONData.oHTML.parentWindow.JSONData)[ this.index ]
				}
				set {
				(JSONData.oHTML.parentWindow.JSONData)[ this.index ] := value
				}
			}

}