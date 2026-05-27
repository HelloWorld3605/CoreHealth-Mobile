param(
  [string]$DeviceId = '',
  [string]$ApiBaseUrl = 'http://10.0.2.2:8080/api'
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$flutter = 'C:\src\flutter\bin\flutter.bat'
$apiKey = [Environment]::GetEnvironmentVariable('BEEKNOEE_API_KEY', 'User')

if ([string]::IsNullOrWhiteSpace($apiKey)) {
  throw 'Missing user environment variable BEEKNOEE_API_KEY.'
}

$args = @(
  'run',
  "--dart-define=BEEKNOEE_API_KEY=$apiKey",
  "--dart-define=COREHEALTH_API_BASE_URL=$ApiBaseUrl"
)

if (-not [string]::IsNullOrWhiteSpace($DeviceId)) {
  $args += @('-d', $DeviceId)
}

Set-Location $repoRoot
& $flutter @args
