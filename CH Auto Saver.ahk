#Persistent
#SingleInstance force

;Created ver 00
; on Wed Feb 3 2016 at 07:41:38
; by https://www.reddit.com/user/Xeno234
; at https://www.reddit.com/r/ClickerHeroes/comments/43su2t/guys_seriously_make_hard_copies_of_your_save_on/
;
;Updated ver 01
; on Wed Feb 3
; by GlassWalkerTheurge
; //Updated HZE listview to increase width (added 3 spaces on either side of HZE title)
;
;Updated ver 02
; on Wed Feb 3 2016
; by GlassWalkerTheurge
; //Changed sort order in listview to sortdesc (sort descending) on date prior to gui, show
; //Added version history
; //Replaced ToolTip with TrayTip
;
;Updated ver 03
; on Fri Feb 5 2016
; by GlassWalkerTheurge
; //added "ini" to script file
; //added option for toast notifications
; //added option for number of files to save 
; ** fixed problem with if statemenst as per throwaway_ye at https://www.reddit.com/r/AutoHotkey/comments/44derr/checkbox_returns_value_listbox_does_not_ahk/
;
;Updated ver 04
; on Sun Feb 6 2016
; by GlassWalkerTheurge
; //added morgulis
; //added option for scientific notation Auto|Always|Never
; //added save button
; //added variable for file name
;
;Updated ver 05
; on Mon Feb 8 2016
; //add mercenary {name[first 6 char pad if shorter]}:{level[pad to 3 characters]} (total length of field 10 characters)
; --name mercenaries.mercenaries.0.name [TrimFill(strString, 6, "-")]
; --level mercenaries.mercenaries.0.level [TrimFill(strString, 3, "0")]
; --add loop for mercenaries loop (0-4) to check for highest level merc or return none:000
; //changed font to fixedwidth for better viewing
;
;Future Possible Updates
; add iris level to stats listed in game save data (don't think this is needed)
; add total clicks? totalClicks
; have 4 "modes" to listview Idle | Hybrid | Active | Brief
; --Idle would be current display {Filename|   HZE   |Immortal Damage|  Solomon  |  Morgulis  | Mercenary |Rubies}
; --Hybrid would display {Filename|   HZE   |Immortal Damage|  Solomon  |  Juggernaut  | Morgulis |Rubies}
; --Active would display {Filename|   HZE   |Immortal Damage|  Solomon  |  Juggernaut  | Fragsworth |Rubies}
; --Brief would display {Filename|   HZE   |Immortal Damage|Rubies}

;Set working directory
SetWorkingDir %A_ScriptDir% 

;GlobalVariables
global filSavesList := "CH Auto Saver05.txt" ; To prevent errors this needs to be changed everytime the file format is changed
global booToast := 1
global chkToast := 1
global intSaveCount := 4
global maxSaveCount := 60
global lbxSaves := 4
global intSaves := 4
global lbxSciNot := 1
global intSciNot := 1
global booTest := false

;Read options
gosub, OptRead
menu, tray, add ; separator
menu, tray, add, View_Saves
menu, tray, Default, View_Saves
Chars = ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/
StringCaseSense On

return

View_Saves:
	;load options
	gosub, OptRead
	;Check for existance of %filSavesList% create if not there
	IfNotExist %filSavesList%
		populateInfo()
	compareInfo()
	; Set to better font
	Gui Font,, Lucida Console
	; Generated using SmartGUI Creator for SciTE
	Gui, Add, Tab2, x2 y-1 w720 h430 , Saves|Options
	; create the ListView with column names seperated by |s
	Gui, Add, ListView, x2 y19 w720 h430 gMyListView, Filename|   HZE   |Immortal Damage|  Solomon  |  Morgulis  | Mercenary |Rubies|%A_Space%

	; Files Tab
	; gather a list of file names from a folder and put them into the ListView
	Loop, read, %filSavesList%
	{
		Loop, parse, A_LoopReadLine, %A_Tab%
			field%A_Index% := A_LoopField
		;        (filename)       (HZE)          (immortal)       (sol)        (mor)          (mercs)  (rubies)
		LV_Add("", field1, Dec2Sci(field2,10), Dec2Sci(field3,14),field4, Dec2Sci(field5,10), field6, field7)
	}	
	LV_ModifyCol(1)  ; auto-sizes column 1
	LV_ModifyCol(2, "Integer")  ; for sorting purposes, indicate that column 2-5 are integers (-3)
	LV_ModifyCol(3, "Float") ; immortal damage can be too big for integer, but float is slower
	LV_ModifyCol(4, "Integer")
	LV_ModifyCol(5, "Integer")
	LV_ModifyCol(6, "Integer")
	LV_ModifyCol(7, "Integer")
	LV_ModifyCol(8, "0") ; dont display empty column
	LV_ModifyCol(1, "SortDesc") ;  Sort in descending order
	Sort:=1

	;Options Tab
	Gui, Tab, Options
	Gui, Add, CheckBox, x12 y25 w160 h30 vchkToast Checked%booToast%, Enable Toast Message
	Gui, Add, Text, x12 y60 w160 h30 , Number of files to save
	Gui, Add, ListBox, x182 y60 w110 h20 vlbxSaves choose%intSaveCount%, 10|20|30|60|80|120
	Gui, Add, Text, x12 y90 w160 h30 , Use Scientific Notation
	Gui, Add, ListBox, x182 y90 w110 h20 vlbxSciNot AltSubmit choose%intSciNot%, Auto|Always|Never
	Gui, Add, Button, x250 y410 w100 h30 vSave, Save
	Gui, Show
return

MyListView:
	if A_GuiEvent = DoubleClick
	{
		LV_GetText(RowText, A_EventInfo)  ; Get the text from the row's first field.
		FileRead, codedSave, %RowText%
		if ErrorLevel
			;Tooltip Error copying %RowText% to clipboard
			TrayTip CHAutoSaver, Error copying %RowText% to clipboard
		else
			;ToolTip Copied %RowText% to clipboard
			TrayTip CHAutoSaver, Copied %RowText% to clipboard
		clipboard := codedSave
		sleep 2000
		;ToolTip
		TrayTip
	}
return

OptRead:

	If (booTest) {
		MsgBox, 0, test read 1, Toast	= %booToast% / %chkToast%`nSciNot	= %intSciNot% / %lbxSciNot%`nSave	= %intSaveCount% / %lbxSaves% / %maxSaveCount%
	}

	;//GetSettings
	;UserInterface
	IniRead, booToast, %A_ScriptName%, UserInterface, Toast1
	;Scientific Notation
	IniRead, intSciNot, %A_ScriptName%, UserInterface, SciNot1
	;Saves
	IniRead, intSaveCount, %A_ScriptName%, Saves, Local1
	
	;Convert saved option for number of saves to variable for later processing
	;IE the option in the ini (1-6) to a variable for number of files to save
	If (intSaveCount = 1) 
		maxSaveCount = 10
	
	Else If (intSaveCount = 2)
		maxSaveCount = 20 
	
	Else If (intSaveCount = 3) 
		maxSaveCount = 30
	
	Else If (intSaveCount = 4) 
		maxSaveCount = 60

	Else If (intSaveCount = 5) 
		maxSaveCount = 80
	
	Else If (intSaveCount = 6) 
		maxSaveCount = 120

	lbxSaves := %maxSaveCount%
	
	if(booTest) {
		MsgBox, 0, test read 2, Toast	= %booToast% / %chkToast%`nSciNot	= %intSciNot% / %lbxSciNot%`nSave	= %intSaveCount% / %lbxSaves% / %maxSaveCount%
	}

return

ButtonSave:

	;SubmitVariables
	Gui, Submit, NoHide

	;For Testing purposes
	If(booTest) {
		MsgBox, 0, test write 1, Toast	= %booToast% / %chkToast%`nSciNot	= %intSciNot% / %lbxSciNot%`nSave	= %intSaveCount% / %lbxSaves% / %maxSaveCount%
	}
	
	;Read Variables
	GuiControlGet, lbxSciNot
	GuiControlGet, lbxSaves
	GuiControlGet, chkToast

	;Scientific Notation
	intSciNot := lbxSciNot
	IniWrite, %lbxSciNot%, %A_ScriptName%, UserInterface, SciNot1
	;Toast Messages
	IniWrite, %chkToast%, %A_ScriptName%, UserInterface, Toast1
	booToast = %chkToast%
	;Files to save
	maxSaveCount = %lbxSaves%
	
	If (maxSaveCount = 10)
		intSaveCount = 1
	
	Else If (maxSaveCount = 20) 
		intSaveCount = 2
	
	Else If (maxSaveCount = 30) 
		intSaveCount = 3
	
	Else If (maxSaveCount = 60) 
		intSaveCount = 4
	
	Else If (maxSaveCount = 80) 
		intSaveCount = 5
	
	Else (maxSaveCount = 120)
		intSaveCount = 6
		
	IniWrite, %intSaveCount%, %A_ScriptName%, Saves, Local1

	If(booTest) {
		MsgBox, 0, test write 2, Toast	= %booToast% / %chkToast%`nSciNot	= %intSciNot% / %lbxSciNot%`nSave	= %intSaveCount% / %lbxSaves% / %maxSaveCount%
	}

return

GuiClose:

	Gui, Destroy

return

OnClipboardChange:
	if (A_EventInfo != 1)
		return
	codedSave := Clipboard
	if (not InStr(codedSave, "Fe12NAfA3R6z4k0z"))
		return
	decodedsave := decodeSave(codedSave)
	immortalDamage := json(decodedsave, "titanDamage")
	if not immortalDamage
		return
	IfExist %filSavesList%
	{
		compareInfo()
		infoCount := 0
		Loop, read, %filSavesList%
		{
			infoCount++
			Loop, parse, A_LoopReadLine, %A_Tab%
				field%A_Index% := A_LoopField
			if (field3 = immortalDamage)
				return
		}
		if (infoCount >= maxSaveCount)
			deleteOldestSave(infoCount + 1 - maxSaveCount)
	}
	filename := "CHSave" . A_Now . ".txt"
	;tooltip Clipboard copied to %filename%
	If (booToast = "1") {
		TrayTip CHAutoSave, Clipboard copied to %filename%
	}
	FileAppend, %codedsave%, %filename%
	HZE := json(decodedsave, "highestFinishedZonePersist")
	solomon := json(decodedsave, "ancients.ancients.3.level")
	morgulis := json(decodedSave, "ancients.ancients.16.level")
	;We have to hunt for mercs -- these slimy guys and gals are sometimes hiding
	;if the highest one dies or multiples the slot 0 could be empty or you might 
	;not have hired any of these shifty guys yet.
	Loop 5 {
		intscanmerc := A_Index - 1
		mercnameS := json(decodedSave, "mercenaries.mercenaries." . intscanmerc . ".name")
		merclvlS := json(decodedSave, "mercenaries.mercenaries." intscanmerc ".level")
		
		if (merclvlS > merclvl) {
			mercname := mercnameS
			merclvl := merclvlS
		}

	}
	If (mercname = "") {
		mercname := "-none-"
		merclevel := "999"
	}
	merc := TrimFill(mercname, 6, "-")":"TrimFill(merclvl, 3, "0")
	rubies := json(decodedsave, "rubies")
	FileAppend %filename%%A_Tab%%HZE%%A_Tab%%immortalDamage%%A_Tab%%solomon%%A_Tab%%morgulis%%A_Tab%%merc%%A_Tab%%rubies%`n, %filSavesList%
	sleep 2500
	;tooltip
	TrayTip
return


deleteOldestSave(num)
{
	FileRead, contents, %filSavesList%
	if not ErrorLevel  ; Successfully loaded.
	{
		Sort, contents
		deleteCount := 0
		Loop, parse, contents, `n, `r
		{
			if (num < A_Index)
				break
			filename := SubStr(A_LoopField, 1, 24)
			fileDelete %filename%
			deleteCount++
			deleteLine%deleteCount% := filename
		}
		if deleteCount
		{
			file := ""
			loop read, %filSavesList%
			{
				bDelete := 0
				filename := SubStr(A_LoopReadLine, 1, 24)
				loop % deleteCount
				{
					if (deleteLine%A_Index% = filename)
					{
						bDelete := 1
						break
					}
				}
				if not bDelete
					file .= A_LoopReadLine . "`n"
			}
			fileDelete %filSavesList%
			fileAppend, %file%, %filSavesList%
		}
	}
}


compareInfo() ; gets called by View_Saves and OnClipboardChange
{
	saveCount := 0, infoCount := 0
	Loop, CHSave*.*
		saveCount++
	Loop, read, %filSavesList%
		infoCount++
	if saveCount = infoCount
		return
	if (saveCount > infoCount) ; more CHSave<date>s then what's in %filSavesList%
	{
		;tooltip Adding missing CHSave to %filSavesList%
		If (booToast = "1") {
			TrayTip CHAutoSave, Adding missing CHSave to %filSavesList%
		}
		difference := saveCount - infoCount
		Loop, CHSave*.*
		{
			saveFilename := A_LoopFileName
			found := 0
			Loop, read, %filSavesList%
			{
				if (saveFilename = SubStr(A_LoopReadLine, 1, 24))
				{
					found := 1
					break
				}
			}
			if not found
			{
				FileRead, contents, %A_LoopFileName%
				decodedsave := decodeSave(contents)
				immortalDamage := json(decodedsave, "titanDamage")
				HZE := json(decodedsave, "highestFinishedZonePersist")
				solomon := json(decodedsave, "ancients.ancients.3.level")
				morgulis := json(decodedSave, "ancients.ancients.16.level")
				;We have to hunt for mercs -- these slimy guys and gals are sometimes hiding
				;if the highest one dies or multiples the slot 0 could be empty or you might 
				;not have hired any of these shifty guys yet.
				Loop 5 {
					intscanmerc := A_Index - 1
					mercnameS := json(decodedSave, "mercenaries.mercenaries." . intscanmerc . ".name")
					merclvlS := json(decodedSave, "mercenaries.mercenaries." intscanmerc ".level")
					
					if (merclvlS > merclvl) {
						mercname := mercnameS
						merclvl := merclvlS
					}

				}
				If (mercname = "") {
					mercname := "-none-"
					merclevel := "999"
				}
				merc := TrimFill(mercname, 6, "-")":"TrimFill(merclvl, 3, "0")
				rubies := json(decodedsave, "rubies")
				FileAppend %A_LoopFileName%%A_Tab%%HZE%%A_Tab%%immortalDamage%%A_Tab%%solomon%%A_Tab%%morgulis%%A_Tab%%merc%%A_Tab%%rubies%`n, %filSavesList%
				difference--
				if not difference
					break
			}
		}
		tooltip
		if difference
			msgbox,,, Error adding missing CHSave to %filSavesList%, 4
	}
	else if (saveCount < infoCount)
	{
		;tooltip Removing entries from %filSavesList% for nonexistant CHSave files
		If (booToast = "1") {
			TrayTip CHAutoSave, Removing entries from %filSavesList% for nonexistant CHSave files
		}
		difference := infoCount - saveCount
		missingCount := 0
		Loop, read, %filSavesList%
		{
			infoFilename := SubStr(A_LoopReadLine, 1, 24)
			found := 0
			Loop, CHSave*.*
			{
				if (infoFilename = A_LoopFileName)
				{
					found := 1
					break
				}
			}
			if not found
			{
				missingCount++
				missingLine%missingCount% := A_Index
				difference--
			}
			if not difference
				break
		}
		if missingCount
		{
			file := ""
			loop read, %filSavesList%
			{
				currentLine := A_Index
				hasSave := 1
				loop % missingCount
				{
					if (missingLine%A_Index% = currentLine)
					{
						hasSave := 0
						break
					}
				}
				if hasSave
					file .= A_LoopReadLine . "`n"
			}
			fileDelete %filSavesList%
			fileAppend, %file%, %filSavesList%
		}
		;tooltip
		TrayTip
	}
}


populateInfo() ; gets called when there's no %filSavesList%
{
	Loop, CHSave*.*
	{
		FileRead, contents, %A_LoopFileName%
		if not ErrorLevel  ; Successfully loaded.
		{
			;tooltip Populating %filSavesList%... Decoding CHSave#%A_Index%
			If (booToast = "1") {
				TrayTip CHAutoSave, Populating %filSavesList%... Decoding CHSave#%A_Index%
			}
			decodedSave := decodeSave(contents) ; by far the slowest operation
			HZE := json(decodedSave, "highestFinishedZonePersist")
			immortalDamage := json(decodedSave, "titanDamage")
			solomon := json(decodedSave, "ancients.ancients.3.level")
			morgulis := json(decodedSave, "ancients.ancients.16.level")
			;We have to hunt for mercs -- these slimy guys and gals are sometimes hiding
			;if the highest one dies or multiples the slot 0 could be empty or you might 
			;not have hired any of these shifty guys yet.
			Loop 5 {
				intscanmerc := A_Index - 1
				mercnameS := json(decodedSave, "mercenaries.mercenaries." . intscanmerc . ".name")
				merclvlS := json(decodedSave, "mercenaries.mercenaries." intscanmerc ".level")
				
				if (merclvlS > merclvl) {
					mercname := mercnameS
					merclvl := merclvlS
				}

			}
			If (mercname = "") {
				mercname := "-none-"
				merclevel := "999"
			}
			merc := TrimFill(mercname, 6, "-")":"TrimFill(merclvl, 3, "0")
			rubies := json(decodedSave, "rubies")
			FileAppend %A_LoopFileName%%A_Tab%%HZE%%A_Tab%%immortalDamage%%A_Tab%%solomon%%A_Tab%%morgulis%%A_Tab%%merc%%A_Tab%%rubies%`n, %filSavesList%
		}
		else
		{
			;tooltip
			TrayTip
			msgbox,,, error reading %A_LoopFileName%, 5
		}
	}
	;tooltip
	TrayTip
}

decodeSave(codedSave)
{
	StringLeft, codedSaveLeft, codedSave, InStr(codedSave, "Fe12NAfA3R6z4k0z")
	StringSplit, pseudoArray, codedSaveLeft
	length := StrLen(codedSaveLeft) - 1
	loop % length
	{
		if (mod(A_Index, 2) = 0)
			continue
		string .= pseudoArray%A_Index%
	}
	return InvBase64(string)
}

; http://www.autohotkey.com/board/topic/5545-base64-coderdecoder/
InvBase64(code)
{
   StringReplace code, code, =,,All
   Loop Parse, code
   {
      If Mod(A_Index,4) = 1
         buffer := DeCode(A_LoopField) << 18
      Else If Mod(A_Index,4) = 2
         buffer += DeCode(A_LoopField) << 12
      Else If Mod(A_Index,4) = 3
         buffer += DeCode(A_LoopField) << 6
      Else {
         buffer += DeCode(A_LoopField)
         out := out . Chr(buffer>>16) . Chr(255 & buffer>>8) . Chr(255 & buffer)
      }
   }
   If Mod(StrLen(code),4) = 0
      Return out
   If Mod(StrLen(code),4) = 2
      Return out . Chr(buffer>>16)
   Return out . Chr(buffer>>16) . Chr(255 & buffer>>8)
}

DeCode(c)   ; c = a char in Chars ==> position [0,63]
{
   Global Chars
   Return InStr(Chars,c,1) - 1
}

; http://www.autohotkey.com/board/topic/31619-json-readwrite-parser/
; https://github.com/polyethene/AutoHotkey-Scripts/blob/master/json.ahk
json(ByRef js, s, v = "") {
	j = %js%
	Loop, Parse, s, .
	{
		p = 2
		RegExMatch(A_LoopField, "([+\-]?)([^[]+)((?:\[\d+\])*)", q)
		Loop {
			If (!p := RegExMatch(j, "(?<!\\)(""|')([^\1]+?)(?<!\\)(?-1)\s*:\s*((\{(?:[^{}]++|(?-1))*\})|(\[(?:[^[\]]++|(?-1))*\])|"
				. "(?<!\\)(""|')[^\7]*?(?<!\\)(?-1)|[+\-]?\d+(?:\.\d*)?|true|false|null?)\s*(?:,|$|\})", x, p))
				Return
			Else If (x2 == q2 or q2 == "*") {
				j = %x3%
				z += p + StrLen(x2) - 2
				If (q3 != "" and InStr(j, "[") == 1) {
					StringTrimRight, q3, q3, 1
					Loop, Parse, q3, ], [
					{
						z += 1 + RegExMatch(SubStr(j, 2, -1), "^(?:\s*((\[(?:[^[\]]++|(?-1))*\])|(\{(?:[^{\}]++|(?-1))*\})|[^,]*?)\s*(?:,|$)){" . SubStr(A_LoopField, 1) + 1 . "}", x)
						j = %x1%
					}
				}
				Break
			}
			Else p += StrLen(x)
		}
	}
	If v !=
	{
		vs = " ;" just to fix my text editor coloring
		If (RegExMatch(v, "^\s*(?:""|')*\s*([+\-]?\d+(?:\.\d*)?|true|false|null?)\s*(?:""|')*\s*$", vx)
			and (vx1 + 0 or vx1 == 0 or vx1 == "true" or vx1 == "false" or vx1 == "null" or vx1 == "nul"))
			vs := "", v := vx1
		StringReplace, v, v, ", \", All
		js := SubStr(js, 1, z := RegExMatch(js, ":\s*", zx, z) + StrLen(zx) - 1) . vs . v . vs . SubStr(js, z + StrLen(x3) + 1)
	}
	Return, j == "false" ? 0 : j == "true" ? 1 : j == "null" or j == "nul"
		? "" : SubStr(j, 1, 1) == """" ? SubStr(j, 2, -1) : j
}

Dec2Sci(MyNumber,Places){
	;From post https://autohotkey.com/board/topic/93902-decimal-to-scientific-notation-converter/
	; \\ Added places to allow custimizable scientific
	;MyNumber is number to be converted to ScientificNotation
	;Places is number of places must be in number before it is converted to scientific notation
	;Options  Auto|Always|Never
	stringlen, intLength, MyNumber
	
	if (intSciNot = 2) {
		Places = 0
	}
	
	if (intSciNot = 3) {
		return MyNumber
	}
	
	if (intLength >= Places) {
		if !MyNumber
			;return, "0*E0"
			return, "0E0"
		factor := 1	, Exponent := 0
		while (Abs(MyNumber)*factor >= 10) && Abs(MyNumber) > 1
			factor /= 10 , Exponent++
		while (Abs(MyNumber)*factor <= 1) && Abs(MyNumber) < 1
			factor *= 10 , Exponent--
		return RegExReplace(MyNumber*factor, "0.000*$") .  "*E"Exponent
		}
		
	Else {
		return MyNumber
	}
}

TrimFill(string,length,fill="") {
	
    if (StrLen(string)=length)
        return %string%
    else if (StrLen(string)>length)
        return SubStr(string,1,length)
    else if (StrLen(string)<length) {
        Loop % (length-StrLen(string))
            v.=fill
        return v.=string
    }
}

/*
[UserInterface]
Toast1=1
SciNot1=1
[Saves]
Local1=6
*/
