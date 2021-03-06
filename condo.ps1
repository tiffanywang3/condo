#requires -version 4

# find the script path
$RootPath = $PSScriptRoot

# setup well-known paths
$CondoScriptPath = Join-Path $RootPath "condo-local.ps1"
$TemplatePath = Join-Path $RootPath "template"
$CondoTemplatePath = Join-Path $TemplatePath "condo.ps1"

# determine if condo-local.ps1 already exists and delete it if it does
if (Test-Path $CondoScriptPath) {
    Remove-Item -Force $CondoScriptPath
}

# copy the template to the local path
Copy-Item $CondoTemplatePath $CondoScriptPath > $null

# run condo using local build
try {
    # change to the root path
    Push-Location $RootPath

    # execute the local script
    & $CondoScriptPath -Reset -Local @args
}
finally {
    # change back to the current path
    Pop-Location

    # remove the local condo script
    Remove-Item -Force $CondoScriptPath -ErrorAction SilentlyContinue
}
