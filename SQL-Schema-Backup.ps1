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
    $logDirectory,
    [Parameter(Mandatory=$True, Position=4, ValueFromPipeline=$false)]
    [System.Boolean]
    $pushToGit
)

$logName = 'SQL-Schema-Export-'
$logFileName = $logName + (Get-Date -f yyyy-MM-dd-HH-mm) + ".log"
$logFullPath =  Join-Path $logDirectory $logFileName
$logFileLimit = (Get-Date).AddDays(-15)
$svr = Connect-dbaInstance -SqlInstance $server

if(-Not(Test-Path -Path $logFullPath -PathType Leaf))
{
    try 
    {
        $null =  New-Item -ItemType File -Path $logFullPath -Force -ErrorAction Stop
        Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - The log file '$logFileName' has been created"
    }
    catch 
    {
        Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Unable to log file in '$logFullPath'. The Error was: $error"
    }
}

try {
    Add-Content -Path $logFullPath -Value "$(Get-Date -f "yyyy-MM-dd-HH-mm") - Attempting to delete old log files"
    Get-ChildItem -Path $logFullPath -Recurse -Force | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $logFileLimit } | Remove-Item -Force
    Add-Content -Path $logFullPath -Value "$(Get-Date -f "yyyy-MM-dd-HH-mm") - Old log files deleted"

}
catch {
    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Unable to delete old log files from '$logFullPath'. The Error was: $error"
}

Write-Host -Message "$(Get-Date -f yyyy-MM-dd-HH-mm) - Script starting" -ForegroundColor Gray
Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Script starting" 

$SourceControlDirectory = $SourceControlDirectory + '\'
$tablePath = $SourceControlDirectory + 'Tables'
$storedProcedurePath = $SourceControlDirectory + 'StoredProcedures'
$viewPath = $SourceControlDirectory + 'Views'
$schemaPath = $SourceControlDirectory + 'Schemas'
$constraintPath = $SourceControlDirectory + 'Constraints'

if(Get-Module -ListAvailable -name dbatools)
{
    Import-Module -Name dbatools
} else 
{
    try 
    {
        Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Attempting to install dbatools as it is not present on this system."
        Install-Module dbatools -Confirm $false
        Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - DbaTools has now been installed."
    }
    catch {
        Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Unable to install dbatools. The Error was: $error"
    }
}

if (-not (Test-Path -LiteralPath $tablePath) -and (Get-DbaDbTable -SqlInstance $svr -Database $database | Measure-Object).Count -gt 0)
{
    Add-Content -Path $logFullPath -Value  "$(Get-Date -f yyyy-MM-dd-HH-mm) - Directory '$tablePath' doesn't exist, attempting to create." 
    
    try 
    {
        New-Item -Path $tablePath -ItemType Directory -ErrorAction Stop | Out-Null
    }
    catch 
    {
        Write-Error -Message "Unable to create directory '$tablePath'. Error was: $error" -ErrorAction Stop
        Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Unable to create directory '$tablePath'. Error was: $error"
    }

    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Successfully created directory '$tablePath'."
}
else 
{
    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - '$tablePath' already existed"
}

if (-not (Test-Path -LiteralPath $schemaPath) -and (Get-DbaDbStoredProcedure -SqlInstance $svr -Database $database -ExcludeSystemSp | Measure-Object).Count -gt 0) 
{    
    Add-Content -Path $logFullPath -Value  "$(Get-Date -f yyyy-MM-dd-HH-mm) - Directory '$schemaPath' doesn't exist, attempting to create." 

    try 
    {
        New-Item -Path $schemaPath -ItemType Directory -ErrorAction Stop | Out-Null #-Force
    }
    catch 
    {
        Write-Error -Message "Unable to create directory '$schemaPath'. Error was: $error" -ErrorAction Stop
        Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Unable to create directory '$schemaPath'. Error was: $error" -ErrorAction Stop
    }
    
    Add-Content -Path $logFullPath -Value "Successfully created directory '$schemaPath'."
}
else 
{
    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - '$schemaPath' already existed"
}

if (-not (Test-Path -LiteralPath $storedProcedurePath) -and (Get-DbaDbStoredProcedure -SqlInstance $svr -Database $database -ExcludeSystemSp | Measure-Object).Count -gt 0) 
{    
    Add-Content -Path $logFullPath -Value  "$(Get-Date -f yyyy-MM-dd-HH-mm) - Directory '$storedProcedurePath' doesn't exist, attempting to create." 

    try 
    {
        New-Item -Path $storedProcedurePath -ItemType Directory -ErrorAction Stop | Out-Null #-Force
    }
    catch 
    {
        Write-Error -Message "Unable to create directory '$storedProcedurePath'. Error was: $error" -ErrorAction Stop
        Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Unable to create directory '$storedProcedurePath'. Error was: $error" -ErrorAction Stop
    }
    
    Add-Content -Path $logFullPath -Value "Successfully created directory '$storedProcedurePath'."
}
else 
{
    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - '$storedProcedurePath' already existed"
}

if (-not (Test-Path -LiteralPath $viewPath) -and (Get-DbaDbView -SqlInstance $svr -Database $database -ExcludeSystemView | Measure-Object).Count -gt 0) 
{    
    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Directory '$viewPath' doesn't exist, attempting to create."

    try 
    {
        New-Item -Path $viewPath -ItemType Directory -ErrorAction Stop | Out-Null #-Force
    }
    catch 
    {
        Write-Error -Message "Unable to create directory '$viewPath'. Error was: $error" -ErrorAction Stop
        Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Unable to create directory '$viewPath'. Error was: $error"
    }

    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Successfully created directory '$viewPath'."
}
else 
{
    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - '$viewPath' already existed"
}

if (-not (Test-Path -Path $constraintPath) -and (Get-DbaDbTable -SqlInstance $svr -Database $database | Measure-Object).Count -gt 0) 
{
    Add-Content -Path $logFullPath -Value  "$(Get-Date -f yyyy-MM-dd-HH-mm) - Directory '$constraintPath' doesn't exist, attempting to create." 
    
    try 
    {
        New-Item -Path $constraintPath -ItemType Directory -ErrorAction Stop | Out-Null
    }
    catch 
    {
        Write-Error -Message "Unable to create directory '$constraintPath'. Error was: $error" -ErrorAction Stop
        Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Unable to create directory '$constraintPath'. Error was: $error"
    }

    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Successfully created directory '$constraintPath'."
}
else 
{
    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - '$constraintPath' already existed"
}

try 
{
    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Attempting to export Table objects to '$tablePath' for instance '$server' from database '$database'" 

    $options = New-DbaScriptingOption
    $options.ScriptSchema = $true
    $options.IncludeDatabaseContext  = $false
    $options.IncludeHeaders = $false
    $Options.NoCommandTerminator = $false
    $options.DriPrimaryKey = $true
    $Options.ScriptBatchTerminator = $true
    $options.DriAllConstraints = $false
    $Options.AnsiFile = $true;

    try {        
        Get-DbaDbTable -SqlInstance $svr -Database $database | ForEach-Object { Export-DbaScript -InputObject $_ -FilePath (Join-Path $tablePath -ChildPath "$($_.Name).sql") -ScriptingOptionsObject $options }
    }
    catch {
        Write-Error -Message "Unable to export tables to '$tablePath'. Error was: $error" -ErrorAction Stop
        Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Unable to export tables to '$tablePath'. Error was: $error"
    }

    $options = New-DbaScriptingOption
    $options.ContinueScriptingOnError = $false
    $options.PrimaryObject = $false 
    $options.DriAllKeys = $true   
    $options.DriForeignKeys = $true
    $options.IncludeHeaders = $false
    $options.Triggers = $true;

    $allTables = Get-DbaDbTable -SqlInstance $server -Database $database
    $constraintFilePath = $constraintPath + '\constraints.sql'

    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Attempting to export constraints to $constraintFilePath" 

    try 
    {
        $allTables | Export-DbaScript -FilePath $constraintFilePath -ScriptingOptionsObject $options -EnableException -NoPrefix    
    }
    catch {
        Write-Error -Message "Unable to export constraints to '$constraintFilePath'. Error was: $error" -ErrorAction Stop
        Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Unable to export constraints to '$constraintPath'. Error was: $error"
    }
}
catch 
{
    Write-Error -Message "Unable to export table objects '$tablePath'. Error was: $error" -ErrorAction Stop
    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Unable to export table objects '$tablePath'. Error was: $error" 
}

Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Attempting to export Stored Procedures to '$tablePath' for instance '$server' from database '$database'" 

try 
{
    Get-DbaDbSchema -SqlInstance $svr -Database $database | ForEach-Object { Export-DbaScript -InputObject $_ -FilePath (Join-Path $schemaPath -ChildPath "$($_.Name).sql") }
}
catch 
{
    Write-Error -Message "Unable to export stored procedures '$schemaPath'. Error was: $error" -ErrorAction Stop
    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Unable to export stored procedures '$schemaPath'. Error was: $error" 
}

Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Attempting to export Stored Procedures to '$tablePath' for instance '$server' from database '$database'" 

try 
{
    Get-DbaDbStoredProcedure -SqlInstance $svr -Database $database -ExcludeSystemSp | ForEach-Object { Export-DbaScript -InputObject $_ -FilePath (Join-Path $storedProcedurePath -ChildPath "$($_.Name).sql") -ScriptingOptionsObject $options }
}
catch 
{
    Write-Error -Message "Unable to export stored procedures '$viewPath'. Error was: $error" -ErrorAction Stop
    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Unable to export stored procedures '$viewPath'. Error was: $error" 
}

Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Attempting to export Views to '$viewPath' for instance '$server' from database '$database'" 

try 
{
    Get-DbaDbView -SqlInstance $svr -Database $database -ExcludeSystemView | ForEach-Object { Export-DbaScript -InputObject $_ -FilePath (Join-Path $viewPath -ChildPath "$($_.Name).sql") -ScriptingOptionsObject $options }
}
catch 
{
    Write-Error -Message "Unable to export Views to '$viewPath'. Error was: $error" -ErrorAction Stop
    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Unable to export Views to '$viewPath'. Error was: $error" 
}

if($pushToGit -eq $true) {

    Set-Location $SourceControlDirectory

    Write-Host -Message "Staging all changes to git" -ForegroundColor Gray
    git add . 

    Write-Host -Message "Commiting changes to git" -ForegroundColor Gray
    git commit -m "$(Get-Date -f yyyy-MM-dd-HH-mm) backup"

    Write-Host -Message "Pushing changes to the remote git repository" -ForegroundColor Gray
    git push origin main

}

Write-Host -Message "$(Get-Date -f yyyy-MM-dd-HH-mm) - Script Complete" -ForegroundColor Gray
