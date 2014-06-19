

Run("D:\_Setups\___Premium\Console-2.00b148-Beta_32bit\Console.exe")
Local $path = GetWD()


Sleep(300)
Send("cd " & $path & "{ENTER}")
Send("node node_server.js{ENTER}")
Sleep(500)
Send("^r")
Send("Node{ENTER}")
Send("^t")
Send("cd " & $path & "{ENTER}")
Sleep(200)
Send("start chrome localhost:8000{ENTER}")



Func GetWD()
    ; Autoit v3.3.6.1
    ; thanks to Juvigy
    ; modified by Rudi
    RunWait(@ComSpec & " /c cd /d %temp%&&echo %cd%>temp.tmp", "", @SW_HIDE); create temp file to save %cd%
    $file = FileOpen(@TempDir & "\temp.tmp", 0)
    ; Check if file opened for reading OK
    If $file = -1 Then
        MsgBox(0, "Error", "cannot open " & @TempDir & "\temp.tmp to retrieve the working directory!")
        Return False
    EndIf
    ; Read in just the 1st line. (There might be an empty 2nd line)
    $WD = FileReadLine($file)
    FileClose($file)
    FileDelete(@TempDir & "\temp.tmp")
    $WD &= "\"
    If StringRight($WD, 2) == "\\" Then $WD = StringTrimRight($WD, 1) ; the main script expects trailing "\" for path strings
    Return $WD
EndFunc