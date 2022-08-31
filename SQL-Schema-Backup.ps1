#[CmdletBinding()]
#Param(
#    [Parameter(Mandatory = $True)]
#    [String] $database,
#    [String] $server,
#    [String] $SourceControlDirectory)

$database = 'OffTheSprue'
$server = 'localhost'
$SourceControlDirectory = 'C:\Temp\'

$tablePath = $SourceControlDirectory + 'Tables'
$storedProcedurePath = $SourceControlDirectory + 'StoredProcedures'
$viewPath = $SourceControlDirectory + 'Views'

if(!Get-Module -ListAvailable -name dbatools)
{
    Install-Module dbatools -Confirm $false
} else {
    Import-Module -Name dbatools
}

if (-not (Test-Path -LiteralPath $tablePath)) {

    Write-Host "Directory '$tablePath' doesn't exist, attempting to create." -ForegroundColor Yellow
    
    try {
        New-Item -Path $tablePath -ItemType Directory -ErrorAction Stop | Out-Null #-Force
    }
    catch {
        Write-Error -Message "Unable to create directory '$tablePath'. Error was: $_" -ErrorAction Stop
    }

    "Successfully created directory '$tablePath'."
}
else {
    "'$tablePath' already existed"
}

if (-not (Test-Path -LiteralPath $storedProcedurePath)) {
    
    Write-Host "Directory '$storedProcedurePath' doesn't exist, attempting to create." -ForegroundColor Yellow

    try {
        New-Item -Path $storedProcedurePath -ItemType Directory -ErrorAction Stop | Out-Null #-Force
    }
    catch {
        Write-Error -Message "Unable to create directory '$storedProcedurePath'. Error was: $_" -ErrorAction Stop
    }
    
    Write-Host "Successfully created directory '$storedProcedurePath'." -ForegroundColor Green

}

if (-not (Test-Path -LiteralPath $viewPath)) {
    
    Write-Host "Directory '$viewPath' doesn't exist, attempting to create." -ForegroundColor Yellow

    try {
        New-Item -Path $viewPath -ItemType Directory -ErrorAction Stop | Out-Null #-Force
    }
    catch {

        Write-Error -Message "Unable to create directory '$viewPath'. Error was: $_" -ErrorAction Stop
    }
    "Successfully created directory '$viewPath'."

}

Write-Host "Script starting" -ForegroundColor Yellow

try 
{

    Write-Host "Attempting to export Table objects to '$tablePath' for instance '$server' from database '$database'" -ForegroundColor Yellow

    Get-DbaDbTable -SqlInstance $server -Database $database | ForEach-Object { Export-DbaScript -InputObject $_ -FilePath (Join-Path $tablePath -ChildPath "$($_.Name).sql") -ScriptingOptionsObject $options }
}
catch {
    Write-Error -Message "Unable to create directory '$viewPath'. Error was: $_" -ErrorAction Stop
}

try 
{
    Write-Host "Attempting to export Stored Procedures to '$tablePath' for instance '$server' from database '$database'" -ForegroundColor Yellow

    Get-DbaDbStoredProcedure -SqlInstance $server -Database $database -ExcludeSystemSp | ForEach-Object { Export-DbaScript -InputObject $_ -FilePath (Join-Path $storedProcedurePath -ChildPath "$($_.Name).sql") -ScriptingOptionsObject $options }
}
catch {
    Write-Error -Message "Unable to create directory '$viewPath'. Error was: $_" -ErrorAction Stop
}

try 
{
    Write-Host "Attempting to export Views to '$viewPath' for instance '$server' from database '$database'" -ForegroundColor Yellow

    Get-DbaDbView -SqlInstance $server -Database $database -ExcludeSystemView | ForEach-Object { Export-DbaScript -InputObject $_ -FilePath (Join-Path $viewPath -ChildPath "$($_.Name).sql") -ScriptingOptionsObject $options }
}
catch {
    Write-Error -Message "Unable to create directory '$viewPath'. Error was: $_" -ErrorAction Stop
}
