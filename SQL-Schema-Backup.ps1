#[CmdletBinding()]
#Param(
#    [Parameter(Mandatory = $True)]
#    [String] $database,
#    [String] $server,
#    [String] $SourceControlDirectory)

$database = 'OffTheSprue'
$server = 'localhost'
$SourceControlDirectory = 'C:\Temp\'
$logDirectory = 'C:\Temp\Logs\'
$logName = 'SQL-Schema-Export-'
$logFileName = $logName + (Get-Date -f yyyy-MM-dd-HH-mm) + ".log"
$logFullPath =  Join-Path $logDirectory $logFileName

if(-Not(Test-Path -Path $logFullPath -PathType Leaf))
{
    try {
    $null =  New-Item -ItemType File -Path $logFullPath -Force -ErrorAction Stop
    Set-Content -Path $logFullPath -Value "The log file '$logFileName' has been created"

    }
    catch {
        Write-Error $_.Exception.Message
    }
}

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

    Set-Content -Path $logFullPath -Value  "Directory '$tablePath' doesn't exist, attempting to create."
    
    try {
        New-Item -Path $tablePath -ItemType Directory -ErrorAction Stop | Out-Null
    }
    catch {
        Write-Error -Message "Unable to create directory '$tablePath'. Error was: $_" -ErrorAction Stop
        Set-Content -Path $logFullPath -Value "Unable to create directory '$tablePath'. Error was: $_"
    }

    Set-Content -Path $logFullPath -Value "Successfully created directory '$tablePath'."
}
else {
    Set-Content -Path $logFullPath -Value "'$tablePath' already existed"
}

if (-not (Test-Path -LiteralPath $storedProcedurePath)) {
    
    Set-Content -Path $logFullPath -Value  "Directory '$storedProcedurePath' doesn't exist, attempting to create." -ForegroundColor Yellow

    try {
        New-Item -Path $storedProcedurePath -ItemType Directory -ErrorAction Stop | Out-Null #-Force
    }
    catch {
        Write-Error -Message "Unable to create directory '$storedProcedurePath'. Error was: $_" -ErrorAction Stop
        Set-Content -Path $logFullPath -Value "Unable to create directory '$storedProcedurePath'. Error was: $_" -ErrorAction Stop
    }
    
    Set-Content -Path $logFullPath -Value "Successfully created directory '$storedProcedurePath'." 

}

if (-not (Test-Path -LiteralPath $viewPath)) {
    
    Set-Content -Path $logFullPath -Value  "Directory '$viewPath' doesn't exist, attempting to create."

    try {
        New-Item -Path $viewPath -ItemType Directory -ErrorAction Stop | Out-Null #-Force
    }
    catch {
        Write-Error -Message "Unable to create directory '$viewPath'. Error was: $_" -ErrorAction Stop
        Set-Content -Path $logFullPath -Value "Unable to create directory '$viewPath'. Error was: $_"
    }
    Set-Content -Path $logFullPath -Value "Successfully created directory '$viewPath'."

}

Set-Content -Path $logFullPath -Value "Script starting" 

try 
{

    Set-Content -Path $logFullPath -Value "Attempting to export Table objects to '$tablePath' for instance '$server' from database '$database'" 

    Get-DbaDbTable -SqlInstance $server -Database $database | ForEach-Object { Export-DbaScript -InputObject $_ -FilePath (Join-Path $tablePath -ChildPath "$($_.Name).sql") -ScriptingOptionsObject $options }
}
catch {
    Write-Error -Message "Unable to create directory '$viewPath'. Error was: $_" -ErrorAction Stop
    Set-Content -Path $logFullPath -Value "Unable to create directory '$viewPath'. Error was: $_" 
}

try 
{
    Set-Content -Path $logFullPath -Value  "Attempting to export Stored Procedures to '$tablePath' for instance '$server' from database '$database'" 

    Get-DbaDbStoredProcedure -SqlInstance $server -Database $database -ExcludeSystemSp | ForEach-Object { Export-DbaScript -InputObject $_ -FilePath (Join-Path $storedProcedurePath -ChildPath "$($_.Name).sql") -ScriptingOptionsObject $options }
}
catch {
    Write-Error -Message "Unable to create directory '$viewPath'. Error was: $_" -ErrorAction Stop
    Set-Content -Path $logFullPath -Value "Unable to create directory '$viewPath'. Error was: $_" 
}

try 
{
    Set-Content -Path $logFullPath -Value "Attempting to export Views to '$viewPath' for instance '$server' from database '$database'" 

    Get-DbaDbView -SqlInstance $server -Database $database -ExcludeSystemView | ForEach-Object { Export-DbaScript -InputObject $_ -FilePath (Join-Path $viewPath -ChildPath "$($_.Name).sql") -ScriptingOptionsObject $options }
}
catch {
    Write-Error -Message "Unable to create directory '$viewPath'. Error was: $_" -ErrorAction Stop
    Set-Content -Path $logFullPath -Value "Unable to create directory '$viewPath'. Error was: $_" 
}
