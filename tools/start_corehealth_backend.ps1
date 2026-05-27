$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$backendDir = Join-Path $repoRoot 'backend'
$javaHome = 'C:\Program Files\Java\jdk-21'
$maven = 'C:\Users\lenovo\.m2\wrapper\dists\apache-maven-3.9.14-bin\1cb7fhup6b5n3bed6kckbrnspv\apache-maven-3.9.14\bin\mvn.cmd'
$apiKey = [Environment]::GetEnvironmentVariable('BEEKNOEE_API_KEY', 'User')

if ([string]::IsNullOrWhiteSpace($apiKey)) {
  throw 'Missing user environment variable BEEKNOEE_API_KEY.'
}

$env:JAVA_HOME = $javaHome
$env:PATH = "$javaHome\bin;$env:PATH"
$env:BEEKNOEE_API_KEY = $apiKey

Set-Location $backendDir
& $maven spring-boot:run
