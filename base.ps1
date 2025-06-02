# base.ps1
# Utility functions for project tools

$ErrorActionPreference = 'Stop'

# Logging functions
function Write-Green {
    param (
        [Parameter(Mandatory = $true)][string]$Message
    )
    Write-Host $Message -ForegroundColor Green
}

function Write-Cyan {
    param (
        [Parameter(Mandatory = $true)][string]$Message
    )
    Write-Host $Message -ForegroundColor Cyan
}

function Write-Red {
    param (
        [Parameter(Mandatory = $true)][string]$Message
    )
    Write-Host $Message -ForegroundColor Red
}

# Push file to remote host using SCP
function Push-File {
    param (
        [Parameter(Mandatory = $true)][string]$LocalPath,
        [Parameter(Mandatory = $true)][string]$RemoteHost,
        [Parameter(Mandatory = $true)][string]$RemoteUser,
        [Parameter(Mandatory = $true)][string]$RemotePath
    )
    Write-Cyan "Pushing file $LocalPath to $RemoteUser@${RemoteHost}:$RemotePath..."
    Write-Green "Executing: scp $LocalPath $RemoteUser@${RemoteHost}:$RemotePath"
    try {
        scp $LocalPath "$RemoteUser@${RemoteHost}:$RemotePath"
    }
    catch {
        Write-Red "Error pushing file: $_"
        exit 1
    }
}

# Run binary on remote host via SSH
function Invoke-Binary {
    param (
        [Parameter(Mandatory = $true)][string]$RemoteHost,
        [Parameter(Mandatory = $true)][string]$RemoteUser,
        [Parameter(Mandatory = $true)][string]$BinaryPath,
        [Parameter(Mandatory = $false)][string]$Args = ""
    )
    Write-Cyan "Running binary $BinaryPath on $RemoteUser@$RemoteHost..."
    Write-Green "Executing: ssh $RemoteUser@$RemoteHost $BinaryPath $Args"
    try {
        ssh "$RemoteUser@$RemoteHost" "$BinaryPath $Args"
    }
    catch {
        Write-Red "Error running binary: $_"
        exit 1
    }
}

# Build Go project
function Build-Go {
    param (
        [Parameter(Mandatory = $true)][string]$SourceDir,
        [Parameter(Mandatory = $false)][string]$OutputPath = "output",
        [Parameter(Mandatory = $false)][string]$GOOS = "",
        [Parameter(Mandatory = $false)][string]$GOARCH = ""
    )
    Write-Cyan "Building $SourceDir ..."
    $envCmd = " "
    if ($GOOS) { $envCmd += "GOOS=$GOOS " }
    if ($GOARCH) { $envCmd += "GOARCH=$GOARCH " }
    Write-Green "Executing:$envCmd go build -o $OutputPath"
    try {
        if ($envCmd -ne " ") {
            $envVars = @{}
            if ($GOOS) { $envVars["GOOS"] = $GOOS }
            if ($GOARCH) { $envVars["GOARCH"] = $GOARCH }
            & { $envVars.GetEnumerator() | ForEach-Object { Set-Item -Path "env:$($_.Key)" -Value $_.Value }; go build -o $OutputPath }
        }
        else {
            go build -o $OutputPath
        }
    }
    catch {
        Write-Red "Error building: $_"
        exit 1
    }
}

function Invoke-Go {
    param (
        [Parameter(Mandatory = $true)][string]$SourceDir,
        [Parameter(Mandatory = $false)][string]$Args = ""
    )
    Write-Cyan "Running $SourceDir ..."
    Write-Green "Executing: go run $SourceDir $Args"
    try {
        & go run $SourceDir $Args
    }
    catch {
        Write-Red "Error running: $_"
        exit 1
    }
}

# Build Meson project
function Build-Meson {
    param (
        [Parameter(Mandatory = $true)][string]$SourceDir,
        [Parameter(Mandatory = $true)][string]$BuildDir,
        [Parameter(Mandatory = $false)][string]$Platform = ""
    )
    Write-Cyan "Setting up Meson project in $SourceDir with build directory $BuildDir..."
    if (-not (Test-Path $BuildDir)) {
        Write-Green "Executing: meson setup $BuildDir $SourceDir"
        try {
            meson setup $BuildDir $SourceDir
        }
        catch {
            Write-Red "Error setting up Meson: $_"
            exit 1
        }
    }
    else {
        Write-Cyan "Build directory $BuildDir already exists, skipping setup."
    }
    Write-Green "Executing: ninja -C $BuildDir"
    try {
        ninja -C $BuildDir
    }
    catch {
        Write-Red "Error building with Ninja: $_"
        exit 1
    }
}

# Placeholder for additional functions
# function Additional-Function {
#     param (
#         [Parameter(Mandatory=$true)][string]$Param
#     )
#     Write-Cyan "Running additional function with $Param..."
#     # Add logic here
# }