#Persistent
#SingleInstance force

maxSaveCount := 60

menu, tray, add ; separator
menu, tray, add, View_Saves
menu, tray, Default, View_Saves
Chars = ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/
StringCaseSense On
return

View_Saves:
	IfNotExist info.txt
		populateInfo()
	compareInfo()
	; create the ListView with column names seperated by |s
	Gui, Add, ListView, r60 w400 gMyListView, Filename|   HZE   |Immortal Damage|Solomon|Rubies|%A_Space%
	; gather a list of file names from a folder and put them into the ListView
	Loop, read, info.txt
	{
		Loop, parse, A_LoopReadLine, %A_Tab%
			field%A_Index% := A_LoopField
		LV_Add("", field1, field2, field3, field4, field5)
	}	
	LV_ModifyCol(1)  ; auto-sizes column 1
	LV_ModifyCol(2, "Integer")  ; for sorting purposes, indicate that column 2-5 are integers (-3)
	LV_ModifyCol(3, "Float") ; immortal damage can be too big for integer, but float is slower
	LV_ModifyCol(4, "Integer")
	LV_ModifyCol(5, "Integer")
	LV_ModifyCol(6, "0") ; dont display empty column
	LV_ModifyCol(1, "SortDesc") ;  Sort in descending order
	Sort:=1
	Gui, Show
return


MyListView:
	if A_GuiEvent = DoubleClick
	{
		LV_GetText(RowText, A_EventInfo)  ; Get the text from the row's first field.
		FileRead, codedSave, %RowText%
		if ErrorLevel
			Tooltip Error copying %RowText% to clipboard
		else
			ToolTip Copied %RowText% to clipboard
		clipboard := codedSave
		sleep 2000
		ToolTip
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
	tooltip Clipboard copied to %filename%
	FileAppend, %codedsave%, %filename%
	HZE := json(decodedsave, "highestFinishedZonePersist")
	solomon := json(decodedsave, "ancients.ancients.3.level")
	rubies := json(decodedsave, "rubies")
	FileAppend %filename%%A_Tab%%HZE%%A_Tab%%immortalDamage%%A_Tab%%solomon%%A_Tab%%rubies%`n, info.txt
	sleep 2500
	tooltip
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
		tooltip Adding missing CHSave to info.txt
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
		tooltip Removing entries from info.txt for nonexistant CHSave files
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
		tooltip
	}
}


populateInfo() ; gets called when there's no info.txt
{
	Loop, CHSave*.*
	{
		FileRead, contents, %A_LoopFileName%
		if not ErrorLevel  ; Successfully loaded.
		{
			tooltip Populating info.txt... Decoding CHSave#%A_Index%
			decodedSave := decodeSave(contents) ; by far the slowest operation
			HZE := json(decodedSave, "highestFinishedZonePersist")
			immortalDamage := json(decodedSave, "titanDamage")
			solomon := json(decodedSave, "ancients.ancients.3.level")
			rubies := json(decodedSave, "rubies")
			FileAppend %A_LoopFileName%%A_Tab%%HZE%%A_Tab%%immortalDamage%%A_Tab%%solomon%%A_Tab%%rubies%`n, info.txt
		}
		else
		{
			tooltip
			msgbox,,, error reading %A_LoopFileName%, 5
		}
	}
	tooltip
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
