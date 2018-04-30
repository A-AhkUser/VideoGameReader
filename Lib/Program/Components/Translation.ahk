global Translation :=
(LTrim Join C
	{
		WORKING_DIRECTORY: A_ScriptDir . "\__Translation",
		GUI: new GUI(),
		dictionaries: [],
		dictionary: "",
		setDictionary: "Translation_setDictionary",
		setDicSysName: "Translation_setDicSysName",
		getArticle: "Translation_getArticle",
		getArticleMessageMonitor: "Translation_messageMonitor",
		dispose: "Translation_dispose",
		Init: "Translation_Init"
	}
)
Translation_Init() {

static _init := 0
IfNotEqual _init, 0, return _init

	if not Translation.entities := new JSONData(Translation.WORKING_DIRECTORY . "\entities.json")
		return 0, ErrorLevel:=-4

	_dictionaryObject :=
	(LTrim Join C
		{
			getName: "",
			rootUrl: "",
			languages: "",
			source: "",
			target: "",
			getDicSysName: "",
			getUrl: "",
			match: "",
			replace: "",
			HTML: {
				sourcePath: "",
				documentContainerSelector: ""
			},
			onMatch: ""
		}
	)
	try {
		_dictionaries := Translation.dictionaries
		if (_manifest:=Translation.manifest:=new JSONData(Translation.WORKING_DIRECTORY . "\manifest.json")) {
			for _dictionary, _settings in new JSONData.Enumerator(_manifest.data) {
				_o := _dictionaries[_dictionary] := new _dictionaryObject
					for _k, _v in new JSONData.Enumerator(_settings) {
						_o[_k] := _v
					}
			}
		} else return 0, ErrorLevel:=-3
	} catch {
	return 0, ErrorLevel:=-2
	}
	if !(NumGet(&_dictionaries, 4 * A_PtrSize))
		return 0, ErrorLevel:=-1
	_component := Translation.GUI.add("ShellEmbedded", "vShellEmbedded_1").component, ComObjConnect(_component, new EventHandler)

return Translation, _init:=!_init
}
Translation_setDictionary(_dictionary) {

	try _sourcePath := Translation.dictionaries[_dictionary].HTML.sourcePath
	_control := Translation.GUI.controls["ShellEmbedded_1"]
	_control.updateURI("file:///" . RegExReplace(_sourcePath, "\.{3}(?=\\)", Translation.WORKING_DIRECTORY))
	if (ErrorLevel)
		return false, ErrorLevel

	_oDictionary := Translation.dictionaries[_dictionary]

	if (Translation.__SetDictionary && !ObjBindMethod(Translation, "__SetDictionary", _oDictionary).())
		return false, ErrorLevel:=2

	Translation.dictionary := _oDictionary
	_oDictionary._languages := _oDictionary.languages.join(",")
	_oDictionary._container := _control.component.document.querySelector(_oDictionary.HTML.documentContainerSelector)

return true
}
Translation_setDicSysName(_src, _trgt) {

	_dictionary := Translation.dictionary, _languages := _dictionary._languages

	if (_v:=((_src <> _trgt) and In(_languages, _src) and In(_languages, _trgt))) {
		_oLanguages := Translation.entities.data.languages
		_dictionary.source := _oLanguages[_src], _dictionary.target := _oLanguages[_trgt]
	}
	(Translation.__SetDicSysName && Translation.__SetDicSysName.call(Translation, !_v))

}
Translation_getArticle(_word, _json:=true) {

	if not (StrLen(Trim(_word)))
		return false

	_dictionary := Translation.dictionary
	_parentWindow := Translation.GUI.controls["ShellEmbedded_1"].component.document.parentWindow

	_url := _parentWindow[_dictionary.getUrl].bind(Translation, _dictionary, _word).call()
	if not (request(_url, _data)) {
		Translation.getArticleMessageMonitor.call(Translation, "ERR_CONNECTION")
	return true
	}
	_responseText := _data.ResponseText

		if (_l:=_dictionary.match.length) {

			_match := _parentWindow[_dictionary.match], _replace := _dictionary.replace
			Loop % _l {

				if (RegExMatch(_responseText, _match[ a_index - 1 ](), _responseText)) {
					Loop % (_e:=_replace[ a_index - 1 ]).length {
					_ee := _e[ a_index - 1 ]
					, _responseText := RegExReplace(_responseText, _ee.NeedleRegEx, _ee.Replacement,, _ee.Limit, _ee.StartingPosition)
					}
					break
				}

			}
			Translation.getArticleMessageMonitor.call(Translation, "NOT_FOUND")
			return true

		}

	if (_json) {

		try JSONData.parse(_responseText, _outputObject), Translation.dictionary.initialState := _outputObject
		catch {
			Translation.dictionary.initialState := new JSONData.DataTypes.Object()
			, Translation.getArticleMessageMonitor.call(Translation, "ERR_PARSE_ERROR")
		return true
		}

	}

	_onMatch := _dictionary.onMatch
	Loop % _dictionary.onMatch.length {
		_msg := _parentWindow[_onMatch[ a_index - 1 ]].bind(Translation, _dictionary, a_index-1).call()
		, Translation.getArticleMessageMonitor.call(Translation, _msg)
	}
	return true

}
Translation_messageMonitor(_msg) {
return _msg
}

Translation_dispose() {
Translation.__SetDictionary := Translation.__SetDicSysName := Translation.getArticleMessageMonitor := ""
}

Class EventHandler {

	DocumentComplete(_wb) {
		static _doc
		ComObjConnect(_doc:=_wb.document, new EventHandler)
	}
	OnKeyPress(_doc) {
	static _keys := {1:"selectall", 3:"copy", 22:"paste", 24:"cut"}
		if (_keys.HasKey(_keyCode:=_doc.parentWindow.event.keyCode))
			_doc.ExecCommand(_keys[_keyCode])
	}

} ; cf. https://autohotkey.com/board/topic/76777-help-with-copy-and-pasting-with-shellexplorer/?p=488306