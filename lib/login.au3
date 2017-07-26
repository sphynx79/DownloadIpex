
sleep(500)

WinWait("[REGEXPTITLE:(DesktopDefault)]", "", 10)

WinActivate("[REGEXPTITLE:(DesktopDefault)]")
Send("{DOWN}")
Send("{ENTER}")
WinWait("IDProtect Verifica", "", 10)
WinActivate("IDProtect Verifica")
Send("58781164")
Send("{ENTER}")



