#Persistent
#SingleInstance force

;Created ver 00
; on Wed Feb 3 2016 at 07:41:38
; by https://www.reddit.com/user/Xeno234
; at https://www.reddit.com/r/ClickerHeroes/comments/43su2t/guys_seriously_make_hard_copies_of_your_save_on/
;Updated ver 01
; on Wed Feb 3
; by GlassWalkerTheurge
; //Updated HZE listview to increase width (added 3 spaces on either side of HZE title)
;Updated ver 02
; on Wed Feb 3
; by GlassWalkerTheurge
; //Changed sort order in listview to sortdesc (sort descending) on date prior to gui, show
; //Added version history
; //Replaced ToolTip with TrayTip
;Updated ver 03
; on Fri Feb 5
; by GlassWalkerTheurge
; //added "ini" to script file
; //added option for toast notifications
; //added option for number of files to save 
; ** fixed problem with if statemenst as per throwaway_ye at https://www.reddit.com/r/AutoHotkey/comments/44derr/checkbox_returns_value_listbox_does_not_ahk/

;Future Possible Updates
; Scientific Notation for HZE? (would need to greatly increase width) and Immortal damage (columns would no longer be integer[if longer 14 places])
; add morgulis level to stats listed in the game save data
; add iris level to stats listed in game save data
; XX add options to gui (max save count)
; XX add options to gui (date based retention) 
; XX switch from ToolTip to TrayTip

;GlobalVariables
global booToast := 1
global chkToast := 1
global intSaveCount := 4
global lbxSaves := 4
global maxSaveCount := 60
;Read options
gosub, OptRead
menu, tray, add ; separator
menu, tray, add, View_Saves
menu, tray, Default, View_Saves
Chars = ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/
StringCaseSense On
return

OptRead:
	;//GetSettings
	;UserInterface
	IniRead, booToast, %A_ScriptName%, UserInterface, Toast1
	;Saves
	IniRead, intSaveCount, %A_ScriptName%, Saves, Local1
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

	;MsgBox, 0, test, Toast = %booToast%`nintSave = %intSaveCount%`nmaxSave = %maxSaveCount%
return

OptWrite:
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
		
	;MsgBox, 0, test, ToastchkToast = %chkToast%`nToast = %booToast%`nlbxSavesSave = %lbxSaves%`nintSave = %intSaveCount%`nMaxSave = %maxSaveCount%
return

View_Saves:
	;load options
	gosub, OptRead
	;Check for existance of info.txt create if not there
	IfNotExist info.txt
		populateInfo()
	compareInfo()
	; Generated using SmartGUI Creator for SciTE
	Gui, Add, Tab2, x2 y1 w480 h380 , Saves|Options
	; create the ListView with column names seperated by |s
	Gui, Add, ListView, x2 y19 w480 h360 gMyListView, Filename|   HZE   |Immortal Damage|Solomon|Rubies|%A_Space%

	; Files Tab
	; gather a list of file names from a folder and put them into the ListView
	Loop, read, info.txt
	{
		Loop, parse, A_LoopReadLine, %A_Tab%
			field%A_Index% := A_LoopField
		LV_Add("", field1, field2, Dec2Sci(field3,14), field4, field5)
	}	
	LV_ModifyCol(1)  ; auto-sizes column 1
	LV_ModifyCol(2, "Integer")  ; for sorting purposes, indicate that column 2-5 are integers (-3)
	LV_ModifyCol(3, "Float") ; immortal damage can be too big for integer, but float is slower
	LV_ModifyCol(4, "Integer")
	LV_ModifyCol(5, "Integer")
	LV_ModifyCol(6, "0") ; dont display empty column
	LV_ModifyCol(1, "SortDesc") ;  Sort in descending order
	Sort:=1

	;Options Tab
	Gui, Tab, Options
	Gui, Add, CheckBox, x12 y30 w160 h30 vchkToast Checked%booToast%, Enable Toast Message
	Gui, Add, Text, x12 y60 w160 h30 , Number of files to save
	Gui, Add, ListBox, x182 y60 w110 h20 vlbxSaves choose%intSaveCount%, 10|20|30|60|80|120
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

GuiClose:
	Gui, Submit, NoHide
	gosub, OptWrite
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
	IfExist info.txt
	{
		compareInfo()
		infoCount := 0
		Loop, read, info.txt
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
	rubies := json(decodedsave, "rubies")
	FileAppend %filename%%A_Tab%%HZE%%A_Tab%%immortalDamage%%A_Tab%%solomon%%A_Tab%%rubies%`n, info.txt
	sleep 2500
	;tooltip
	TrayTip
return


deleteOldestSave(num)
{
	FileRead, contents, info.txt
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
			loop read, info.txt
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
			fileDelete info.txt
			fileAppend, %file%, info.txt
		}
	}
}


compareInfo() ; gets called by View_Saves and OnClipboardChange
{
	saveCount := 0, infoCount := 0
	Loop, CHSave*.*
		saveCount++
	Loop, read, info.txt
		infoCount++
	if saveCount = infoCount
		return
	if (saveCount > infoCount) ; more CHSave<date>s then what's in info.txt
	{
		;tooltip Adding missing CHSave to info.txt
		If (booToast = "1") {
			TrayTip CHAutoSave, Adding missing CHSave to info.txt
		}
		difference := saveCount - infoCount
		Loop, CHSave*.*
		{
			saveFilename := A_LoopFileName
			found := 0
			Loop, read, info.txt
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
				rubies := json(decodedsave, "rubies")
				FileAppend %A_LoopFileName%%A_Tab%%HZE%%A_Tab%%immortalDamage%%A_Tab%%solomon%%A_Tab%%rubies%`n, info.txt
				difference--
				if not difference
					break
			}
		}
		tooltip
		if difference
			msgbox,,, Error adding missing CHSave to info.txt, 4
	}
	else if (saveCount < infoCount)
	{
		;tooltip Removing entries from info.txt for nonexistant CHSave files
		If (booToast = "1") {
			TrayTip CHAutoSave, Removing entries from info.txt for nonexistant CHSave files
		}
		difference := infoCount - saveCount
		missingCount := 0
		Loop, read, info.txt
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
			loop read, info.txt
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
			fileDelete info.txt
			fileAppend, %file%, info.txt
		}
		;tooltip
		TrayTip
	}
}


populateInfo() ; gets called when there's no info.txt
{
	Loop, CHSave*.*
	{
		FileRead, contents, %A_LoopFileName%
		if not ErrorLevel  ; Successfully loaded.
		{
			;tooltip Populating info.txt... Decoding CHSave#%A_Index%
			If (booToast = "1") {
				TrayTip CHAutoSave, Populating info.txt... Decoding CHSave#%A_Index%
			}
			decodedSave := decodeSave(contents) ; by far the slowest operation
			HZE := json(decodedSave, "highestFinishedZonePersist")
			immortalDamage := json(decodedSave, "titanDamage")
			solomon := json(decodedSave, "ancients.ancients.3.level")
			rubies := json(decodedSave, "rubies")
			FileAppend %A_LoopFileName%%A_Tab%%HZE%%A_Tab%%immortalDamage%%A_Tab%%solomon%%A_Tab%%rubies%`n, info.txt
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
	stringlen, intLength, MyNumber
	if (intLength >= Places) {
		if !MyNumber
			;return, "0*E0"
			return, "0E0"
		factor := 1	, Exponent := 0
		while (Abs(MyNumber)*factor >= 10) && Abs(MyNumber) > 1
			factor /= 10 , Exponent++
		while (Abs(MyNumber)*factor <= 1) && Abs(MyNumber) < 1
			factor *= 10 , Exponent--
		return RegExReplace(MyNumber*factor, "0*$") .  "*E"Exponent
		}
		
	Else {
		return MyNumber
	}
}

/*
[UserInterface]
Toast1=1
[Saves]
Local1=6
*/
