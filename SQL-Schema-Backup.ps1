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

if (-not (Test-Path -LiteralPath $tablePath)) {
    
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
    
    try {
        New-Item -Path $storedProcedurePath -ItemType Directory -ErrorAction Stop | Out-Null #-Force
    }
    catch {
        Write-Error -Message "Unable to create directory '$storedProcedurePath'. Error was: $_" -ErrorAction Stop
    }
    "Successfully created directory '$storedProcedurePath'."

}
else {
    "'$storedProcedurePath' already existed"
}

if (-not (Test-Path -LiteralPath $viewPath)) {
    
    try {
        New-Item -Path $viewPath -ItemType Directory -ErrorAction Stop | Out-Null #-Force
    }
    catch {
        Write-Error -Message "Unable to create directory '$viewPath'. Error was: $_" -ErrorAction Stop
    }
    "Successfully created directory '$viewPath'."

}
else {
    "'$viewPath' already exists"
}

Write-Host "Script starting" -ForegroundColor Green

try 
{
    Get-DbaDbTable -SqlInstance $server -Database $database | ForEach-Object { Export-DbaScript -InputObject $_ -FilePath (Join-Path $tablePath -ChildPath "$($_.Name).sql") -ScriptingOptionsObject $options }
}
catch
{

}

try 
{
    Get-DbaDbStoredProcedure -SqlInstance $server -Database $database -ExcludeSystemSp | ForEach-Object { Export-DbaScript -InputObject $_ -FilePath (Join-Path $storedProcedurePath -ChildPath "$($_.Name).sql") -ScriptingOptionsObject $options }
}
catch
{

}

try 
{
    Get-DbaDbView -SqlInstance $server -Database $database -ExcludeSystemView | ForEach-Object { Export-DbaScript -InputObject $_ -FilePath (Join-Path $viewPath -ChildPath "$($_.Name).sql") -ScriptingOptionsObject $options }
}
catch
{

}
