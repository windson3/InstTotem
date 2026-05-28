Set objShell = CreateObject("WScript.Shell")
Dim fso, scriptDir, projectDir, psPath
Set fso = CreateObject("Scripting.FileSystemObject")
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
projectDir = fso.GetParentFolderName(scriptDir)
psPath = fso.BuildPath(projectDir, "TotemAutomacao.ps1")
objShell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ & psPath & """", 0, False
