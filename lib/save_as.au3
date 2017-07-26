WinWait("Salva con nome")

WinActivate("Salva con nome")

;ControlFocus("Salva con nome","","[CLASS:Edit;INSTANCE:1]")

;Send($CmdLine[1])
ControlSetText("Salva con nome", "", "[CLASS:Edit; INSTANCE:1]", $CmdLine[1])


ControlClick("Salva con nome","","[CLASS:Button; INSTANCE:1]")


; wait till the download completes
;Local $sAttribute = FileGetAttrib($CmdLine[1]);
;while $sAttribute = ""
;sleep(500)
;$sAttribute = FileGetAttrib($CmdLine[1])
;wend
;sleep(500)
