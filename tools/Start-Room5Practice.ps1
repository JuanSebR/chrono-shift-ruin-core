param(
    [string]$GodotPath = 'C:\Godot\godot.exe.exe',
    [switch]$NoWait
)

$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if (-not (Test-Path -LiteralPath $GodotPath -PathType Leaf)) {
    throw 'C.O.R.E.-9: Godot no aparece. Esta vez no es culpa del Guardian.'
}
if ([string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
    throw 'C.O.R.E.-9: Falta LOCALAPPDATA. Sin aislamiento no hay experimento.'
}

# A fresh directory per process also isolates simultaneous practice sessions.
$sessionRoot = Join-Path $env:LOCALAPPDATA ('ChronoShiftDev\Room5\' + [guid]::NewGuid().ToString('N'))
$roamingRoot = Join-Path $sessionRoot 'Roaming'
$profileRoot = Join-Path $roamingRoot 'Godot\app_userdata\ChronoShift_RuinCore'
[IO.Directory]::CreateDirectory($profileRoot) | Out-Null

$startInfo = New-Object System.Diagnostics.ProcessStartInfo
$startInfo.FileName = $GodotPath
$startInfo.WorkingDirectory = $projectRoot
$startInfo.UseShellExecute = $false
$startInfo.CreateNoWindow = $true
$startInfo.EnvironmentVariables['APPDATA'] = $roamingRoot
$startInfo.EnvironmentVariables['CHRONOSHIFT_ROOM5_PROFILE'] = $profileRoot
$startInfo.Arguments = '--path "{0}" --resolution 1280x720 --log-file "{1}" res://tools/dev/Room5Practice.tscn' -f $projectRoot, (Join-Path $sessionRoot 'godot.log')
$gameProcess = [Diagnostics.Process]::Start($startInfo)
if ($NoWait) {
    [pscustomobject]@{ ProcessId = $gameProcess.Id; SessionRoot = $sessionRoot; ProfileRoot = $profileRoot }
    return
}
Write-Host 'C.O.R.E.-9: Sala 5 de pruebas. F9 reinicia; tu victoria real conserva su ego.'
$gameProcess.WaitForExit()
exit $gameProcess.ExitCode
