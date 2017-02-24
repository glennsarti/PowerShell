param(
  [String] $dockerfileURL = 'https://raw.githubusercontent.com/dotnet/dotnet-docker-nightly/master/2.0/nanoserver/sdk/Dockerfile'

  ,[Switch] $Clean
)
$ErrorActionPreference = 'Stop'

$thisFolder = $PSScriptRoot

$dotnetZip = [System.IO.Path]::GetTempFileName()
$dotnetLocation = "$env:LocalAppData\Microsoft\dotnet"

Write-Output "Cleaning downloads..."
if (Test-Path -Path $dotnetZip) { Remove-Item -Path $dotnetZip -Force -Confirm:$false | Out-Null }

# Detecting powershell version and downloading the zip...
Write-Output "Downloading dockerfile..."
$dockerFile = Invoke-WebRequest -URI $dockerfileURL -UseBasicParsing

Write-Output "Parsing dockerfile for download url..."
$dotNetSDKVersion = ''
$dotNetSDKURL = ''
($dockerFile.Content.Replace("`r","") -split "`n") | % {
  if ($_ -match '^ENV DOTNET_SDK_VERSION (.+)$') {
    $dotNetSDKVersion = $matches[1]
  }
  if ($_ -match '^ENV DOTNET_SDK_DOWNLOAD_URL (.+)$') {
    $dotNetSDKURL = $matches[1]
  }
}

if ($dotNetSDKVersion -eq '') { Throw "Could not detect DOTNET_SDK_VERSION in the dockerfile" }
if ($dotNetSDKURL -eq '') { Throw "Could not detect DOTNET_SDK_DOWNLOAD_URL in the dockerfile" }

$dotNetSDKURL = $dotNetSDKURL.Replace("`$DOTNET_SDK_VERSION",$dotNetSDKVersion)

Write-Output "DotNet SDK Version is $dotNetSDKVersion"
Write-Output "DotNet SDK URL is $dotNetSDKURL"

# Download and extract
Write-Output "Downloading dotnet SDK"
$resp = Invoke-WebRequest -URI $dotNetSDKURL -UseBasicParsing -OutFile $dotnetZip

Write-Output "Extracting dotnet SDK"
Add-Type -Assembly System.IO.Compression.FileSystem | Out-Null

Write-Output "Extracting zipfile..."
[System.IO.Compression.ZipFile]::ExtractToDirectory($dotnetZip, $dotnetLocation)

Write-Output "Cleaning downloads..."
if (Test-Path -Path $dotnetZip) { Remove-Item -Path $dotnetZip -Force -Confirm:$false | Out-Null }
