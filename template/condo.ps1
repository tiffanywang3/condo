#requires -version 4

<#
.SYNOPSIS
    Builds the project using the condo build system.
.DESCRIPTION
    Uses condo to build the project(s) contained within the current repository. If condo is not already present, it will
    be downloaded and restored using the provided URI or branch. If not URL or branch is provided, the latest release
    version will be downloaded.
.PARAMETER Reset
    Deletes the pre-existing locally restored copy of condo and its dependencies before redownloading and restoring.
.PARAMETER Local
    Uses the current repository to restore condo and its dependencies. This is useful for locally testing customizations
    to condo from its own repository.
.PARAMETER Uri
    The URI from which to download and restore condo.
.PARAMETER Branch
    The branch from which to download and restore condo from its default repository.
.PARAMETER Path
    The file system path from which to restore condo and its dependencies. This is useful for locally testing
    customizations to condo from a different repository.
.PARAMETER Verbosity
    The verbosity used for messaging to the standard output from both condo and the underlying MSBuild system.
.PARAMETER NoColor
    Indicates that any messaging to the standard output should not be emitted using colors. This is useful for parsing
    output by third party tools.
.EXAMPLE
    condo -Uri https://github.com/pulsebridge/condo/releases/2.0.0.zip
.EXAMPLE
    condo -Branch develop
.EXAMPLE
    condo -Reset -Verbosity Detailed
.NOTES
    The underlying build system in use is Microsoft Build for .NET Core. Any parameters beyond those supported by this
    cmdlet will be passed to the msbuild process for consideration.
.FUNCTIONALITY
    A conventional approach to automated build and test execution for .NET Core, NodeJS, Gulp, and Grunt. The build
    system is highly extensible and additional frameworks, languages, and systems will be added in the near future.
#>
[CmdletBinding(DefaultParameterSetName='ByBranch',
                PositionalBinding=$false,
                HelpUri = 'http://open.pulsebridge.com/condo')]

Param (
    [Parameter(Mandatory=$false)]
    [Alias("r")]
    [switch]
    $Reset,

    [Parameter(Mandatory=$false)]
    [Alias("l")]
    [switch]
    $Local,

    [Parameter(Mandatory=$false)]
    [Alias("nc")]
    [switch]
    $NoColor,

    [Parameter(Mandatory=$false)]
    [Alias("v")]
    [ValidateSet("Quiet", "Minimal", "Normal", "Detailed", "Diagnostic")]
    [string]
    $Verbosity = "Normal",

    [Parameter(Mandatory=$true, ParameterSetName="ByUri")]
    [Alias("u")]
    [string]
    $Uri,

    [Parameter(Mandatory=$false, ParameterSetName="ByBranch")]
    [Alias("b")]
    [string]
    $Branch = "develop",

    [Parameter(Mandatory=$true, ParameterSetName="BySource")]
    [Alias("s")]
    [string]
    $Source,

    [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
    [string[]]
    $MSBuildArgs
)

function Write-Message([string] $message, [System.ConsoleColor] $color) {
    if ($NoColor) {
        Write-Host $message
        return
    }

    Write-Host -ForegroundColor $color $message
}

function Write-Failure([string] $message) {
    Write-Message -Color Red -Message $message
}

function Write-Info([string] $message) {
    Write-Message -Color Yellow -Message $message
}

function Get-File([string] $url, [string] $path, [int] $retries = 5) {
    try {
        Invoke-WebRequest $url -OutFile $path | Out-Null
    }
    catch [System.Exception]
    {
        Write-Failure "Unable to retrieve file: '$url'"

        if ($retries -eq 0) {
            $exception = $_.Exception
            throw $exception
        }

        Write-Failure "Retrying in 10 seconds... attempts left: $retries"
        Start-Sleep -Seconds 10
        $retries--
    }
}

# find the script path
$RootPath = $PSScriptRoot

$BuildRoot = Join-Path $RootPath ".build"
$CondoRoot = Join-Path $BuildRoot "condo"
$CondoScript = Join-Path $CondoRoot "Scripts\condo.ps1"

if ($PSCmdlet.ParameterSetName -eq "ByBranch") {
    $Uri = "https://github.com/pulsebridge/condo/archive/$Branch.zip"
}

if ($Reset -and (Test-Path $BuildRoot)) {
    Write-Info "Resetting condo build system..."
    del -Recurse -Force $BuildRoot | Out-Null
}

if ($Local) {
    $Source = Join-Path $RootPath "src\PulseBridge.Condo.Build"
}

if (!(Test-Path $CondoRoot)) {
    Write-Info "Creating path for condo at $CondoRoot"
    mkdir $CondoRoot | Out-Null

    if ($Source) {
        Write-Info "Using condo build system from $Source"
        cp -Recurse "$Source\*" $CondoRoot
    } else {
        Write-Info "Using condo build system from $Uri"

        $CondoTemp = Join-Path ([System.IO.Path]::GetTempPath()) $([System.IO.Path]::GetRandomFileName())
        $CondoZip = Join-Path $CondoTemp "condo.zip"

        mkdir $CondoTemp | Out-Null

        Get-File -url $Uri -Path $CondoZip

        $CondoExtract = Join-Path $CondoTemp "extract"
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($CondoZip, $CondoExtract)

        pushd "$CondoExtract\src\PulseBridge.Condo.Build\*"
        cp -Recurse . $CondoRoot
        popd

        if (Test-Path $CondoTemp) {
            del -Recurse -Force $CondoTemp
        }
    }
}

try {
    # change to the root path
    pushd $RootPath

    # execute the underlying script
    & "$CondoScript" -Verbosity $Verbosity -NoColor:$NoColor @MSBuildArgs
}
finally {
    popd
}