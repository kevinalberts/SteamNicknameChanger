#RequireAdmin
#Include <Console.au3>
#Include <NtProcess2.au3>

Global $scanBaseAddy, $findBaseAddy, $foundBaseAddy, $dwBaseAddy, $strSelectedNickname
Global $Steam = "Steam.exe"
Global $Steamclient = "Steamclient.dll"


Cout("")
_SetConsoleTitle("Steam Nickname Changer")

CoutStyle2()

$pHandle = OpenProcess(0x1F0FFF, 0, ProcessExists($Steam))
$pmHandle = _MemoryModuleGetBaseAddress(ProcessExists($Steam),$Steamclient)

Cout(@CRLF)

While 1
	CoutStyle3("Your command: ")
	Local $command
	Cin($command)
	If $command = "get nickname" Then
		CoutStyle1("Your nickname: " & GetName())
		Cout(@CRLF)
	ElseIf StringLeft($command,13) = "set nickname " Then
		$strSelectedNickname = StringTrimLeft($command,13)
		CoutStyle1("Nickname '" & $strSelectedNickname & "' has been set.")
		Cout(@CRLF)
		SetName($strSelectedNickname)
	EndIf
WEnd

Func _SetConsoleTitle($cTitle)
    DllCall("Kernel32.dll", "BOOL", "SetConsoleTitle", "str", $cTitle)
EndFunc

Func Find() ;This probably gonna need an update with next steam update!
	$scanBaseAddy = FindPattern($pHandle, "8B15........8B0D........433BD97C8C",false,$pmHandle) ; 8B 15 ?? ?? ?? ?? 8B 0D ?? ?? ?? ?? 43 3B D9 7C 8C
	$findBaseAddy = "0x" & Hex($scanBaseAddy + 0x2,8)
	$foundBaseAddy = "0x" & Hex(NtReadVirtualMemory($pHandle,$findBaseAddy,"dword"),8)
	$dwBaseAddy = "0x" & Hex(Execute($foundBaseAddy - $pmHandle),8)
	Return $dwBaseAddy
EndFunc

Func GetName() ;This one is also probably gonna need an update with next steam update!
	$Level1Ptr = NtReadVirtualMemory($pHandle, $pmHandle + Find(),"int")
	$Level2Ptr = NtReadVirtualMemory($pHandle, $Level1Ptr + 0x61C,"int") ;old offset was 4FC, 52C, 55C ... now it's 61C
	$Level3Ptr = NtReadVirtualMemory($pHandle, $Level2Ptr + 0x0,"int")
	$Level4Ptr = NtReadVirtualMemory($pHandle, $Level3Ptr + 0x28,"int")
	$FinalLevelPtr = NtReadVirtualMemory($pHandle, $Level4Ptr + 0x0,"char[200]")
	Return $FinalLevelPtr
EndFunc

Func SetName($_StrName) ;This one is also probably gonna need an update with next steam update!
	$Level1Ptr = NtReadVirtualMemory($pHandle, $pmHandle + Find(),"int")
	$Level2Ptr = NtReadVirtualMemory($pHandle, $Level1Ptr + 0x61C,"int") ;old offset was 4FC, 52C, 55C ... now it's 61C
	$Level3Ptr = NtReadVirtualMemory($pHandle, $Level2Ptr + 0x0,"int")
	$Level4Ptr = NtReadVirtualMemory($pHandle, $Level3Ptr + 0x28,"int")
	NtWriteVirtualMemory($pHandle, $Level4Ptr + 0x0, $_StrName,"char[200]")
EndFunc

Func CoutStyle1($___Str)
Cout("[>] ", 0x1)
Cout($___Str & @CRLF, 0xD)
EndFunc

Func CoutStyle2()
Cout("[>]                   Commands:                  [<]" & @CRLF, 0x4)
Cout("[>]                 get nickname                 [<]" & @CRLF, 0xC)
Cout("[>]       set nickname [any nick you want]       [<]" & @CRLF, 0xC)
Cout("[>]                    Example                   [<]" & @CRLF, 0x4)
Cout("[>]                 get nickname                 [<]" & @CRLF, 0xC)
Cout("[>]        set nickname Nevergonnacatchme        [<]" & @CRLF, 0xC)
Cout("[>]                   Have fun!                  [<]" & @CRLF, 0x4)
EndFunc

Func CoutStyle3($___Str)
Cout("[>] ", 0x1)
Cout($___Str, 0xD)
EndFunc

Func  _MemoryModuleGetBaseAddress($iPID , $sModule)
    If  Not  ProcessExists ($iPID) Then  Return  SetError (1 , 0 , 0)

    If  Not  IsString ($sModule) Then  Return  SetError (2 , 0 , 0)

    Local    $PSAPI=DllOpen ("psapi.dll")

    ;Get Process Handle
    Local    $hProcess
    Local    $PERMISSION=BitOR (0x0002, 0x0400, 0x0008, 0x0010, 0x0020) ; CREATE_THREAD, QUERY_INFORMATION, VM_OPERATION, VM_READ, VM_WRITE

    If  $iPID>0 Then
        Local  $hProcess=DllCall ("kernel32.dll" , "ptr" , "OpenProcess" , "dword" , $PERMISSION , "int" , 0 , "dword" , $iPID)
        If  $hProcess [ 0 ] Then
            $hProcess=$hProcess [ 0 ]
        EndIf
    EndIf

    ;EnumProcessModules
    Local    $Modules=DllStructCreate ("ptr[1024]")
    Local    $aCall=DllCall ($PSAPI , "int" , "EnumProcessModules" , "ptr" , $hProcess , "ptr" , DllStructGetPtr ($Modules), "dword" , DllStructGetSize ($Modules), "dword*" , 0)
    If  $aCall [ 4 ]>0 Then
        Local    $iModnum=$aCall [ 4 ] / 4
        Local    $aTemp
        For  $i=1 To  $iModnum
            $aTemp= DllCall ($PSAPI , "dword" , "GetModuleBaseNameW" , "ptr" , $hProcess , "ptr" , Ptr(DllStructGetData ($Modules , 1 , $i)) , "wstr" , "" , "dword" , 260)
            If  $aTemp [ 3 ]=$sModule Then
                DllClose ($PSAPI)
                Return  Ptr(DllStructGetData ($Modules , 1 , $i))
            EndIf
        Next
    EndIf

    DllClose ($PSAPI)
    Return  SetError (-1 , 0 , 0)

EndFunc
