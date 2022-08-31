[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True, Position=0, ValueFromPipeline=$false)]
    [System.String]
    $database,
    [Parameter(Mandatory=$True, Position=1, ValueFromPipeline=$false)]
    [System.String]
    $server,
    [Parameter(Mandatory=$True, Position=2, ValueFromPipeline=$false)]
    [System.String]
    $SourceControlDirectory,
    [Parameter(Mandatory=$True, Position=3, ValueFromPipeline=$false)]
    [System.String]
    $logDirectory
)

$logName = 'SQL-Schema-Export-'
$logFileName = $logName + (Get-Date -f yyyy-MM-dd-HH-mm) + ".log"
$logFullPath =  Join-Path $logDirectory $logFileName

if(-Not(Test-Path -Path $logFullPath -PathType Leaf))
{
    try 
    {
        $null =  New-Item -ItemType File -Path $logFullPath -Force -ErrorAction Stop
        Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - The log file '$logFileName' has been created"
    }
    catch 
    {
        Write-Error $_.Exception.Message
    }
}

$tablePath = $SourceControlDirectory + 'Tables'
$storedProcedurePath = $SourceControlDirectory + 'StoredProcedures'
$viewPath = $SourceControlDirectory + 'Views'

if(Get-Module -ListAvailable -name dbatools)
{
    Import-Module -Name dbatools
} else 
{
    Install-Module dbatools -Confirm $false
}

if (-not (Test-Path -LiteralPath $tablePath)) 
{
    Add-Content -Path $logFullPath -Value  "$(Get-Date -f yyyy-MM-dd-HH-mm) - Directory '$tablePath' doesn't exist, attempting to create." 
    
    try 
    {
        New-Item -Path $tablePath -ItemType Directory -ErrorAction Stop | Out-Null
    }
    catch 
    {
        Write-Error -Message "Unable to create directory '$tablePath'. Error was: $_" -ErrorAction Stop
        Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Unable to create directory '$tablePath'. Error was: $_"
    }

    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Successfully created directory '$tablePath'."
}
else 
{
    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - '$tablePath' already existed"
}

if (-not (Test-Path -LiteralPath $storedProcedurePath)) 
{    
    Add-Content -Path $logFullPath -Value  "$(Get-Date -f yyyy-MM-dd-HH-mm) - Directory '$storedProcedurePath' doesn't exist, attempting to create." -ForegroundColor Yellow

    try 
    {
        New-Item -Path $storedProcedurePath -ItemType Directory -ErrorAction Stop | Out-Null #-Force
    }
    catch 
    {
        Write-Error -Message "Unable to create directory '$storedProcedurePath'. Error was: $_" -ErrorAction Stop
        Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Unable to create directory '$storedProcedurePath'. Error was: $_" -ErrorAction Stop
    }
    
    Add-Content -Path $logFullPath -Value "Successfully created directory '$storedProcedurePath'."
}
else 
{
    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - '$storedProcedurePath' already existed"
}

if (-not (Test-Path -LiteralPath $viewPath)) 
{    
    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Directory '$viewPath' doesn't exist, attempting to create."

    try 
    {
        New-Item -Path $viewPath -ItemType Directory -ErrorAction Stop | Out-Null #-Force
    }
    catch 
    {
        Write-Error -Message "Unable to create directory '$viewPath'. Error was: $_" -ErrorAction Stop
        Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Unable to create directory '$viewPath'. Error was: $_"
    }

    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Successfully created directory '$viewPath'."
}
else 
{
    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - '$viewPath' already existed"
}

Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Script starting" 

try 
{
    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Attempting to export Table objects to '$tablePath' for instance '$server' from database '$database'" 

    $options = New-DbaScriptingOption
    $options.ScriptSchema = $true
    $options.IncludeDatabaseContext  = $true
    $options.IncludeHeaders = $false
    $Options.NoCommandTerminator = $false
    $Options.ScriptBatchTerminator = $true
    $options.DriAllConstraints = $true
    $Options.AnsiFile = $true

    Get-DbaDbTable -SqlInstance $server -Database $database | ForEach-Object { Export-DbaScript -InputObject $_ -FilePath (Join-Path $tablePath -ChildPath "$($_.Name).sql") -ScriptingOptionsObject $options }
}
catch 
{
    Write-Error -Message "Unable to create directory '$viewPath'. Error was: $_" -ErrorAction Stop
    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Unable to create directory '$viewPath'. Error was: $_" 
}

try 
{
    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Attempting to export Stored Procedures to '$tablePath' for instance '$server' from database '$database'" 

    Get-DbaDbStoredProcedure -SqlInstance $server -Database $database -ExcludeSystemSp | ForEach-Object { Export-DbaScript -InputObject $_ -FilePath (Join-Path $storedProcedurePath -ChildPath "$($_.Name).sql") -ScriptingOptionsObject $options }
}
catch 
{
    Write-Error -Message "Unable to create directory '$viewPath'. Error was: $_" -ErrorAction Stop
    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Unable to create directory '$viewPath'. Error was: $_" 
}

try 
{
    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Attempting to export Views to '$viewPath' for instance '$server' from database '$database'" 

    Get-DbaDbView -SqlInstance $server -Database $database -ExcludeSystemView | ForEach-Object { Export-DbaScript -InputObject $_ -FilePath (Join-Path $viewPath -ChildPath "$($_.Name).sql") -ScriptingOptionsObject $options }
}
catch 
{
    Write-Error -Message "Unable to create directory '$viewPath'. Error was: $_" -ErrorAction Stop
    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Unable to create directory '$viewPath'. Error was: $_" 
}
