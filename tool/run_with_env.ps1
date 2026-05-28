#!/usr/bin/env pwsh
<#
  .SYNOPSIS
    Reads .env and launches `flutter run` with all variables injected as --dart-define flags.
  .DESCRIPTION
    Place your secrets in .env at the project root. This script converts every
    KEY=VALUE line into a --dart-define=KEY=VALUE flag so that Dart's
    String.fromEnvironment / int.fromEnvironment / bool.fromEnvironment
    can pick them up at compile time.
  .EXAMPLE
    .\tool\run_with_env.ps1                 # default flutter run
    .\tool\run_with_env.ps1 -d chrome       # run on Chrome
    .\tool\run_with_env.ps1 build apk       # build APK
#>
param(
    [Parameter(ValueFromRemainingArguments)]
    [string[]]$ExtraArgs
)

$envFile = Join-Path $PSScriptRoot '..\\.env'
if (-not (Test-Path $envFile)) {
    Write-Error ".env file not found at $envFile. Copy .env.example to .env and fill in your values."
    exit 1
}

$dartDefines = @()
Get-Content $envFile | ForEach-Object {
    $line = $_.Trim()
    # Skip empty lines and comments
    if ($line -and -not $line.StartsWith('#')) {
        $eqIndex = $line.IndexOf('=')
        if ($eqIndex -gt 0) {
            $key = $line.Substring(0, $eqIndex).Trim()
            $value = $line.Substring($eqIndex + 1).Trim()
            if ($value) {
                $dartDefines += "--dart-define=$key=$value"
            }
        }
    }
}

$command = 'run'
if ($ExtraArgs.Count -gt 0 -and $ExtraArgs[0] -match '^(run|build|test)$') {
    $command = $ExtraArgs[0]
    $ExtraArgs = $ExtraArgs[1..($ExtraArgs.Count - 1)]
}

Write-Host "🚀 flutter $command with $($dartDefines.Count) env variable(s) injected" -ForegroundColor Cyan
flutter $command @dartDefines @ExtraArgs
