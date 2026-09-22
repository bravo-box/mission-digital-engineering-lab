$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$release = $env:MATLAB_RELEASE
$products = @($env:MATLAB_PRODUCTS -split '\s+' | Where-Object { $_ })
$sourceLocation = $env:MATLAB_SOURCE_LOCATION
$installDirectory = Join-Path $env:ProgramFiles "MATLAB\$release"
$mpmPath = Join-Path $env:TEMP 'mpm.exe'
$mpmLogPath = Join-Path $env:TEMP "mathworks_$env:USERNAME.log"

if ($release -notmatch '^R20\d{2}[ab]$') {
    throw "Invalid MATLAB release: $release"
}

if ($products.Count -eq 0) {
    throw 'MATLAB_PRODUCTS must contain at least one product.'
}

try {
    Write-Output 'Downloading the MathWorks package manager.'
    Invoke-WebRequest -Uri 'https://www.mathworks.com/mpm/win64/mpm' -OutFile $mpmPath

    $arguments = @(
        'install'
        "--release=$release"
        "--destination=$installDirectory"
        '--products'
    ) + $products

    if ($sourceLocation) {
        $arguments += "--source=$sourceLocation"
    }

    Write-Output "Installing MATLAB $release products: $($products -join ', ')"
    & $mpmPath @arguments
    if ($LASTEXITCODE -ne 0) {
        throw "MathWorks package manager exited with code $LASTEXITCODE."
    }

    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $matlabBin = Join-Path $installDirectory 'bin'
    if (($machinePath -split ';') -notcontains $matlabBin) {
        [Environment]::SetEnvironmentVariable('Path', "$machinePath;$matlabBin", 'Machine')
    }

    Set-ItemProperty `
        -Path 'HKLM:\SOFTWARE\Microsoft\ServerManager' `
        -Name 'DoNotOpenServerManagerAtLogon' `
        -Type DWord `
        -Value 1

    Write-Output "MATLAB $release installed in $installDirectory."
}
catch {
    if (Test-Path $mpmLogPath) {
        Get-Content $mpmLogPath
    }
    throw
}
finally {
    Remove-Item $mpmPath, $mpmLogPath -Force -ErrorAction SilentlyContinue
}
