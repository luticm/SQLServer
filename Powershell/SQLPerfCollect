#Requires -Version 3
<#
	.DESCRIPTION
		Starts logman sessions to collect important metric to troubleshooting SQL Server issues.
		
		HISTORY
			
			v1.0 - Lot of enhacements and rewrite - Rodrigo Ribeiro Gomes
			
				- Documentation
					- Changed to powershell documentation syntax
					- Changed to english
					- Added history
				- Change lot of way script works
					- Rewrite some validations
					- Add parameters (to allow non interactive)
					- Add logging
					- Add other process to collect
					- Add control over generated files (logman fail in some aspects) (maxsize, maximum amount of time)
					
				author: Rodrigo Ribeiro Gomes
				github: @rrg92
				Twitter: @rod_rrg
			
			
			v0.9 - Ready for production
			
				Author: Luciano Caixeta Moreira
				http://luticm.blogspot.com
				Twitter: @luticm
				Blog: http://luticm.blogspot.com
				E-mail: luciano.moreira@srnimbus.com.br
				
				
	#todo:
		- Enhace loggign
		- add more control options on size and time.
		- documentation
		- enhance functions to check data collector logman state
			
#>
[CmdLetBinding()]
param(

	#Output directory. This is where we will configure data collector to store perflogs, logs and other things that this script will collect.
		$DirectoryPath
		
	,#SQL instances which counters will be included in collect.
	 #Default is all running instances. 
		[string[]]$SqlInstance = @()
		
	,#no check for sql server instance
		[switch]$NoSqlInstances
	
		
	,#Alternate data collect name. By default use name of this script + '_' $directory name.
		$DataCollectorName = $null
		
	,#No include Operating System counters. By default is included.
		[switch]$NoSOCounters
		
	,#Include some additional sql server counters like erros, etc.
		[switch]$IncludeAdditionalCounters
		
	,#Include service broker counters 
		[switch]$IncludeBrokerCounters
		
	,#Include counters related to sql server replication 
		[switch]$IncludeReplicationCounters
		
	,#Include counters related to database mirroring and alawayson
		[switch]$IncludeHadrCounters
		
	,#No show notepad with all counters that will be colected.
	 #If not using console host (powershell.exe) not will be show...
		[switch]$NoShowConfig
		
	,#Default maximum size to directories that store some collect.
	 #If this maximum is reached, script take action determined by -OnMax parameter.
		$MaxCollectSize 	= 2GB
		
	,#Default maximum amount of time to keep.
	 #Script will attempt keep this time of data. It will use the Last Modified date of generated files...
		$MaxCollectTime	= $null 
		
	,#Maximum size a single file generated can be.
	 #This will be used to setup directly in data colletor set (parameter -max of logman tool)
		$PerCounterFileMaxSize = 5MB	
		
	,#This is maximum time that this script will allow data collector run.
	 #After this time, this script will stop current collector, if running, and start again.
	 #based on this value, the script will set data collector to run a maximum amount of time (twice this time).
	 #If this script end unexpectdelly, thanks to this max time set on data collector, it will not runing indefinedly, avoiding consuming all disk space...
	 #Thus, this renew time helps powershell keep control on logman execution.
		$RenewFrequency 	= 300
		
	,#This is the frequency that script will check while waiting the renew time...
	 #Every this frequecncy, script will do some important checks like validating max size, collect time, etc.
		$CheckFrequency	= 1
		
	,#Action to take when a max limit is reached. This controls actions to take specified by parameters start with "-Max".
		
		#oldremove 	- Remove oldest files up to get value bellow the respective extrapoled setting.
		#error		- Throw errrors
		
		[ValidateSet('oldremove','error')] #TODO: oldmove,error,zip,copyold,logonly
		$OnMax = "oldremove"
		
	,#If specifified, enables process collect.
	 #This is result of Get-Process cmdlet with important data about process resource usage like cpu and memory.
	 #This parameters control the frequency of this collects. FOr example, 5s for collect every 5 seconds. The real time can vary a litlle.
		$ProcessLogFrequency
	
	,#Maximum time to keep process info collects.
	 #By default, keeps all
		$MaxProcessTime 

	
)

# Para o script caso encontre qualquer exceção 
$ErrorActionPreference = "Stop";

#Here is critical importnat part: Logging
#If this fail, the script can fail and no log will be generated (this is bad if running non interactive mode)
#SO, we will create logging functions, setup script log file... If all of this fail, then we will write to appplication log.
#Also, we will alwayson throw the error, in case user using powershell.exe to get what happening!

try {

	
	#important variables used by log function!
	if($VerbosePreference -ne 'SilentlyContinue'){
		$IsVerboseEnabled = $true
	} else {
		$IsVerboseEnabled = $false;
	}

	if($host.Name -eq 'consolehost'){
		$IsConsole = $true
	} else {
		$IsConsole = $false;
	}
	
	#The most importnat function of this script!
	function log {
		param(
			[switch]$Verbose
		)
		
		$ts    	= (Get-date).toString("yyyy-MM-dd HH:mm:ss.fff");
		$IsError = $Args[0] -is [System.Management.Automation.ErrorRecord] -or $Args[0] -is [System.Exception];
		
		if($IsError){
			$Error 	= $Args[0];
			$LogMsg = "$ts ERROR:$Error"
		} else {
			$LogMsg = "$ts "+($Args -Join " ");
		}

		#Check if write to screen...
		if($Verbose -and $IsVerboseEnabled -and $IsConsole){
			write-verbose $LogMsg;
		}
		elseif(!$Verbose -and $IsConsole) {
			write-host $LogMsg
		}
		
		
		if($ScriptLogFile){
			if($Verbose){
				$LogMsg = "$ts [VERBOSE]$LogMsg"
			}
			
			$MustLog = !$Verbose -or ($Verbose -and $IsVerboseEnabled)
			
			if($MustLog){
				$LogMsg >> $ScriptLogFile;
			}
		}
		
		if($IsError){
			throw $Error;
		}	
	}

	log "Script started...";

	if(!$DirectoryPath){
		throw "Must specify -DirectoryPath parameter"
	}
	
	#Create if not exists...
	$DirectoryItem = mkdir -f $DirectoryPath;

	$ScriptLogFile = "$DirectoryPath\log.log";
	if(Test-Path $ScriptLogFile){
		remove-item $ScriptLogFile;
	}
	log "Start logging to file at $ScriptLogFile"
} catch {
	$Original = $_;
	$LogMsg = "Script $PSCommandPath failed to initiate logging. Run in powershell.exe to get more details. Error was: $_. "
	try {
		Write-EventLog -LogName Application -Source Application -Message $LogMsg -EventId 1 -EntryType Error
	} finally {
		#if fails writelog, throws original exceptions back  (in case runing powershell.exe)
		throw $Original;
	}
}

try {
	$ScriptName = $MyInvocation.MyCommand.Name;
	
	#### Functions area
	function GetParameters(){
		$ScriptInvocation = Get-Variable MyInvocation -Scope 1 -ValueOnly;
		$ScriptBound = Get-Variable PsBoundParameters -Scope 1 -ValueOnly;
		$ParameterList = $ScriptInvocation.MyCommand.Parameters;
		$Params = @{};
		$ParameterList.GetEnumerator() | %{
			$ParamName = $_.key;
			
			if($ScriptBound.ContainsKey($ParamName)){
				$ParamValue = $ScriptBound[$ParamName]
			} else {
				$ParamValue = Get-Variable -Name $ParamName -Scope 1 -ValueOnly -EA SilentlyContinue 
			}
			
			$Params.$ParamName = $ParamValue
		};
		
		
		
		return $Params;
	}

	function IsAdmin {
		#thanks to https://serverfault.com/questions/95431/in-a-powershell-script-how-can-i-check-if-im-running-with-administrator-privil
		$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
		$currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
	}
	
	function pslogman {
		$LogManOutput = logman @Args;
		if($LastExitCode){
			throw "LOGMAN_ERROR: $LastExitCode. Output:`r`n$LogManOutput"
		}
		
		if($Args[0] -eq 'query'){
			$Result = @();
			$InResult = $false;
			$LogManOutput | %{
				$Line = $_;
				if($Line -match '^-+$'){
					$InResult = $true;
					return;
				}
				
				
				if($InResult){
					if($Line.length -eq 0){
						$InResult = $false;
						return;
					}
					
					$Parts = $Line -split '[\s]+',4
					$Result += New-Object PsObject -Prop @{
											Name 		= $parts[0]
											Type 		= $parts[1]
											Status 		= $parts[2]
											SourceLine 	= $parts[3]
									}
				}
				
				
			}
			
			return $Result;
		} else {
			return $LogManOutput;
		}
		
		
	}

	Function Bytes2Human {
		Param ($size)
		If     ($size -gt 1TB) {[string]::Format("{0:0.00} TB", $size / 1TB)}
		ElseIf ($size -gt 1GB) {[string]::Format("{0:0.00} GB", $size / 1GB)}
		ElseIf ($size -gt 1MB) {[string]::Format("{0:0.00} MB", $size / 1MB)}
		ElseIf ($size -gt 1KB) {[string]::Format("{0:0.00} KB", $size / 1KB)}
		ElseIf ($size -gt 0)   {[string]::Format("{0:0.00} B", $size)}
	}

	Function Secs2Human {
		Param ($secs)
		If     ($size -gt 1TB) {[string]::Format("{0:0.00} TB", $size / 1TB)}
		ElseIf ($size -gt 1GB) {[string]::Format("{0:0.00} GB", $size / 1GB)}
		ElseIf ($size -gt 1MB) {[string]::Format("{0:0.00} MB", $size / 1MB)}
		ElseIf ($size -gt 1KB) {[string]::Format("{0:0.00} KB", $size / 1KB)}
		ElseIf ($size -gt 0)   {[string]::Format("{0:0.00} B", $size)}
	}
	
	Function Human2Secs {
		Param ($human)
		
		if($human -is [int]){
			return $human;
		}
		
		if(!$human){
			return;
		}
		
		$secs = @{
			y	= 31104000
			mo 	= 2592000
			w   = 604800
			d   = 86400
			h 	= 3600
			m 	= 60
			s 	= 1
		}
		
		if($human -match '(\d+)(\w+)'){
			$c = $secs[$matches[2]];
			
			if(!$c){
				throw "HUMAN2SECS_INVALID_INPUT: INVALID_UNIT $($matches[2])";
			}	
			
			$secs = ([int]$matches[1]) * $secs[$matches[2]];
			return $secs;
		} else {
			throw "HUMAN2SECS_INVALID_INPUT: $human";
		}	
		
		If     ($size -gt 1TB) {[string]::Format("{0:0.00} TB", $size / 1TB)}
		ElseIf ($size -gt 1GB) {[string]::Format("{0:0.00} GB", $size / 1GB)}
		ElseIf ($size -gt 1MB) {[string]::Format("{0:0.00} MB", $size / 1MB)}
		ElseIf ($size -gt 1KB) {[string]::Format("{0:0.00} KB", $size / 1KB)}
		ElseIf ($size -gt 0)   {[string]::Format("{0:0.00} B", $size)}
	}

	#### Validations
	if(!(IsAdmin)){
		throw "Must run as Administrator!";
	}

	

	if(!$DataCollectorName){
		$DataCollectorName = $ScriptName.replace('.ps1','')+"_"+$DirectoryItem.Name
	}


	#Here, will will put content of configuration to be used with logman'
	$CountersList = @()


	# Contadores básicos do SO
	if(!$NoSOCounters){
		$CountersList +=  @(
			'\LogicalDisk(*)\*'
			'\Network Interface(*)\*'
			'\Memory(*)\*'
			'\Paging file(*)\*'
			'\PhysicalDisk(*)\*'
			'\Processor Information(*)\*'
			'\System(*)\*'
		) 
	}

	#Get list of running instances
	$ServiceInstanceFilter = @(
		"State = 'Running'";
	)

	if($SqlInstance){
		$InstanceNameFilter = @($SqlInstance | %{
			if($_ -eq 'MSSQLSERVER')
			{
				"Name = 'MSSQLSERVER' OR Name = 'SQLSERVERAGENT'"
			} else {
				"Name = 'MSSQL`$$_' OR Name = 'SQLAGENT`$$_'"
			}
			
		}) -Join " OR "	
		$ServiceInstanceFilter += "($InstanceNameFilter)"
	} else {
		$ServiceInstanceFilter += "(Name = 'MSSQLSERVER' OR Name LIKE 'MSSQL`$%' OR Name = 'SQLSERVERAGENT' OR Name LIKE 'SQLAGENT`$%')" 
	}

	$WmiFilter = $ServiceInstanceFilter -Join " AND ";

	$SQLInstanceServices = Get-WmiObject -Class Win32_Service -Filter $WmiFilter

	$SqlServers = @{}

	if(!$SQLInstanceServices -and !$NoSqlInstances){
		throw "No sql server instance elegible"
	}

	$SQLInstanceServices | %{

		if('SQLSERVERAGENT','MSSQLSERVER' -Contains $_.Name){
			$InstanceName = $_.Name;
		} else {
			$InstanceName = $_.Name -replace '(SQLAGENT|MSSQL)\$',''
		}
		
		$InstanceSlot = $SQlServers[$InstanceName];
		
		
		if(!$InstanceSlot){
			$InstanceSlot = @{};
			$SQlServers[$InstanceName] = $InstanceSlot;
		}
		
		if($_.Name -like '*AGENT*'){
			$instanceSlot.AgentService = $_
		} else {
			$InstanceSlot.SqlServer = $_;
		}

	}


	$AllProcessIds = @($SqlInstanceServices | %{ $_.ProcessId });


	#Preparing to collect "\Process" counters...
	#We will collect one for each sqlservr and sqlagent process currenly running...
	#If there are more thant 1 process, perfmon will use \Process(ProcessName) for first, \Process(ProcesSName1) for second a so on...
		$procs = @();
		
		if($AllProcessIds){
			$procs += Get-Process -Id $AllProcessIds
		}
		
		$procs += Get-Process rhs -EA SilentlyContinue;
		
		$prochash = @{};
		$procs | select name -unique | %{ $prochash[$_.name] = 0 }; 

	# Also, for collect data for a specif process, we must specify each counter name...
	# This is because  a bug mentioned on this forum:
	# Ref: https://social.technet.microsoft.com/Forums/en-US/cc5a3a9b-9517-4346-a114-aa5d23c1cf92/bug-user-defined-perfmon-data-collector-set-cannot-capture-data-just-from-one-process-object?forum=perfmon
	# Due to this bug, we need build the list of all counters  that we want collect for each process...

	#First, lets get list off all counters in category "Process"
	$c = New-Object System.Diagnostics.PerformanceCounterCategory("Process")

	#Lets build list for specific process counters...
	foreach ($p in $procs)
	{
		log -v "Checking counters for process $($p.id)"
		# If already collected
		if ($prochash[$p.Name] -gt 0)
		{
			$CounterInstance = $p.Name+"#"+$prochash[$p.Name]
		} else {
			$CounterInstance = $p.Name
		}
		
		log -v "	Expected perfmon instance is: $CounterInstance"
		
		
		if($c.InstanceExists($CounterInstance))
		{
			$ProcessCounters = $c.GetCounters($p.Name)
			$ProcessCounters | %{
				$CountersList += "\Process($CounterInstance)\$($_.CounterName)"
			}
		}
		

		# Increments total process number...
		# This will be used for other process...
		$prochash[$p.Name] += 1
	}



	$SqlServers.GetEnumerator() | ? {$_.value.SqlServer} | %{
		
		
		$InstanceName  = $_.value.SqlServer.Name;
		

		log "Building counter list for instance $InstanceName";

		if($InstanceName -eq 'MSSQLSERVER'){
			$InstanceName = 'SQLServer'
		}

		$CountersList += @(
			"\$($InstanceName):Access Methods(*)\*"
			"\$($InstanceName):Buffer Manager(*)\*"
			"\$($InstanceName):Buffer Node(*)\*"
			"\$($InstanceName):Catalog Metadata(*)\*"
			"\$($InstanceName):Databases(*)\*"
			"\$($InstanceName):Exec Statistics(*)\*"
			"\$($InstanceName):General Statistics(*)\*"
			"\$($InstanceName):Latches(*)\*"
			"\$($InstanceName):Locks(*)\*"
			"\$($InstanceName):Memory Manager(*)\*"
			"\$($InstanceName):Memory Node(*)\*"
			"\$($InstanceName):Plan Cache(*)\*"
			"\$($InstanceName):Resource Pool Stats(*)\*"            
			"\$($InstanceName):SQL Statistics(*)\*"
			"\$($InstanceName):Transactions(*)\*"
			"\$($InstanceName):Wait Statistics(*)\*"
			"\$($InstanceName):Workload Group Stats(*)\*"
		)
		
		if($IncludeAdditionalCounters){
			$CountersList += @(
				"\$($InstanceName):Backup Device(*)\*"
				"\$($InstanceName):Batch Resp Statistics(*)\*"
				"\$($InstanceName):CLR(*)\*"
				"\$($InstanceName):Cursor Manager by Type(*)\*"
				"\$($InstanceName):Cursor Manager Total(*)\*"
				"\$($InstanceName):Deprecated Features(*)\*"
				"\$($InstanceName):FileTable(*)\*"
				"\$($InstanceName):HTTP Storage(*)\*"
				"\$($InstanceName):Memory Broker Clerks(*)\*"
				"\$($InstanceName):SQL Errors(*)\*"            
			)
		}
		
		if($IncludeBrokerCounters){
			$CountersList += @(
				"\$($InstanceName):Broker Activation(*)\*"
				"\$($InstanceName):Broker Statistics(*)\*"
				"\$($InstanceName):Broker TO Statistics(*)\*"
				"\$($InstanceName):Broker/DBM Transport(*)\*"            
			)
		}
		
		if($IncludeReplicationCounters){
			$CountersList += @(
				"\$($InstanceName):Replication Agents(*)\*"
				"\$($InstanceName):Replication Snapshot(*)\*"
				"\$($InstanceName):Replication Logreader(*)\*"
				"\$($InstanceName):Replication Dist.(*)\*"
				"\$($InstanceName):Replication Merge(*)\*"            
			)
		}
		
		if($IncludeHadrCounters){
				$CountersList += @(
					"\$($InstanceName):Availability Replica(*)\*"
					"\$($InstanceName):Database Mirroring(*)\*"
					"\$($InstanceName):Database Replica(*)\*"
					"\$($InstanceName):HADR Availability Replica(*)\*"
					"\$($InstanceName):HADR Database Replica(*)\*"            
				)
		}
	}


	$configFile 	= "$DirectoryPath\PerfmonCounters.config"
	$SettingsFile	= "$DirectoryPath\script_settings.xml"


	log 'Working Directory:' $DirectoryPath
	log 'Data collector name:' $DataCollectorName
	log "MaxLogsSize: $MaxCollectSize byte(s) | PerCounterFileMaxSize: $PerCounterFileMaxSize byte(s)"
	log "CheckFrequency: $CheckFrequency"
	log "RenewFrequency: $RenewFrequency"
	
	$RenewFrequencySeconds 	= Human2Secs $RenewFrequency
	$CheckFrequencySeconds 	= Human2Secs $CheckFrequency
	$MaxCollectTimeSeconds  = Human2Secs $MaxCollectTime
	
	
	if($ProcessLogFrequency){
		log "Process log frequency: $ProcessLogFrequency"
	}
	
	log "Writing config file $ConfigFile"
	$CountersList | Out-File $ConfigFile -Encoding ASCII

	if(!$NoShowConfig -and $IsConsole){
		$Notepad = Start-Process 'notepad.exe' -ArgumentList $configFile -PassThru;
		log "Waiting close notepadd to continue...";
		Wait-Process -Id $Notepad.id;
	}


	$ts					  	= (Get-Date).toString("yyyyMMdd_HHmmss")
	$CountersLogDirectory 	= "$DirectoryPath\log_perfcounters"
	$ProcessLogDirectory 	= "$DirectoryPath\log_process"

	if(-not(Test-Path $CountersLogDirectory)){
		$nd = mkdir $CountersLogDirectory;
	}
	
	if(-not(Test-Path $ProcessLogDirectory)){
		$nd = mkdir $ProcessLogDirectory;
	}

	#For security reasons (to prevent full log, if powershhell stops)
	#We will limit data collecto to run up to this time...
	#Powershell loop bellow will keep logman restarted and collecting, renwing this time...
	#this point is essentia because it have logic to prevent logman fill disk above the limit MaxSize...
	#If powershel stops for any reason, this limit ensures that logman will not run indefinedly...
	$MaxRunTimeString = [timespan]::FromSeconds($RenewFrequencySeconds*2).toString();
	log -v "	Data collector -rf (max runtime) will be $MaxRunTimeString";

	$NewfileName = "$CountersLogDirectory\PerfCounters.blg";


	# for data collector works auto create new file after size, we must use bin file , cnf 0 and specify max.
	$MaxSizeMB = $PerCounterFileMaxSize/1024/1024
	$PerfCounterCollectInterval = 1; #Every 1 second.
	$LogManParameters = @(
		"create","counter",$DataCollectorName
		"-f",'bin'
		'-si',$PerfCounterCollectInterval
		'-max',$MaxSizeMB
		'-cf',$ConfigFile
		'-cnf',0
		'-ow'
		'-rf',$MaxRunTimeString
		'-o',$NewfileName
	)



	$SETTINGS = @{
		ConfigFile 			= $configFile
		CounterList			= $CountersList
		SqlServers 			= $SqlServers
		Parameters 			= (GetParameters)
		MaxRunTimeString	= $MaxRunTimeString
		LogManCreateParams	= $LogManParameters 
		procs				= $procs
	}


	log -v "Writing to setting file at $SettingsFile"
	$SETTINGS | Export-CliXml $SettingsFile

	# stop current data collector...
	#	Refs:https://docs.microsoft.com/en-us/windows/win32/api/pla/nf-pla-idatacollectorset-query
	#
	$ComDc = New-Object -Com Pla.DataCollectorSet

	$CollectorExists  = $false;

	try {	
		$ComDc.Query($DataCollectorName,$null);
		$CollectorExists = $true;
	} catch {
		#if was not found error...
		
		

		#Have a hResult?
		if( $_.Exception -match 'HRESULT: 0x([^\)]+)'){
			$HResult = [convert]::ToInt32($matches[1],16);
		} else {
			log "Cannot determine HRESULT from current exception: $()";
			throw;
		}
		
		if($HResult -ne 0x80300002){
			log "DataCollector COM query failed: $_";
			throw;
		}
		
	}

	if($CollectorExists){
		$CollectorStatus = $ComDc.status;
		
		#Possible status: https://docs.microsoft.com/en-us/windows/win32/api/pla/ne-pla-datacollectorsetstatus
		if($CollectorStatus -eq 1){#Running?
			#stop it...
			log "Stopping running collector...";
			$ComDc.stop($true);
		}
		
		#Removing...
		log "Deleting existing data collector...";
		$ComDc.delete();
		log  "	Success";
	}


	log "Creating data collector via logman...";
	log "Parameters: $(@($LogManParameters -Join ' '))"
	$LogManOutput = pslogman @LogManParameters
	log "	Created..."

	#Getting again...
	log "Getting data collector instance from pla..."
	$ComDc.Query($DataCollectorName,$null);
	log "	Success!"

	#Here will implement a loop that manages the collection...
	#We create a data collector that automatically create new files when ma size is reached...
	#	but, dc dont remove old files... This can result in problem in disk... So we need this powershell loop to monitor and manage disk space...
	#	Also, thanks to this part, we can keep data collector creating new files after some confingurables time...
	#	So, with data collector configurations set and this part, we have a collector with constraints on file size, total size and time.
	#		this is not possible just with default data collector set (or constraint is size or time).
	#	In addition, we create data collector with time constraint... So this loop is responsible for renew this time...
	#		If this powershell process stops unexpectdelly,logman will stop generates files, because this powershell will not renew it...


	function CheckDirSize(){
			param($Directory,$Filters = '*',$MaxSize,$Action)
			
		
			if(!$MaxSize){
				return;
			}
			

			$AllDirs = @();
			
			$Directory | %{
				if(-not(Test-Path $_)){
					return;
				}
			
				$AllDirs += $_;
			}
			
			if(!$AllDirs){
				return;
			}

			#Validate size...
			do {
				
				
				$AllFiles 	=  $AllDirs | % { 
					log -v "Getting files from path $_";
					gci $_ -Filter * 
				} | sort CreationTime;
				
				$TotalSize 	= ($AllFiles | Measure-Object -Sum -Property Length).Sum;
				log -v "Current size of all directories: $(Bytes2Human $TotalSize) (Max: $(Bytes2Human $MaxSize))"
				
				
				
				if($TotalSize -gt $MaxSize){
					log "Total size is $(Bytes2Human $TotalSize). Max is: $(Bytes2Human $MaxSize).";
					$Sum = 0;
					$Files2Delete = @();
					$Size2Remove = $TotalSize - $MaxSize;
					
					if($Action -eq 'oldremove'){
						log "	Need remove $(Bytes2Human $Size2Remove) of files... Electing..."
						$Fi = 0;
						while($sum -lt $Size2Remove -and $fi -lt $fi -lt $AllFiles.length){
							$ElegibleFile = $AllFiles[$fi];
							$Files2Delete += $ElegibleFile;
							$fi++;
							$sum += $ElegibleFile.Length;
						}
						
						$FilesToRemoveString = @($Files2Delete | %{ "`t`t`t"+$_.Name+" ($(Bytes2Human $_.Length))" }) -Join "`r`n";
						
						log "	Following files will be removed:`r`n$FilesToRemoveString"
						$Files2Delete | Remove-Item -force;
					}
					
					if($Action -eq 'error'){
						$ComDc.stop($true); 
						throw "MAX_TOTALSIZE_REACHED: TotalSize: $(Bytes2Human $TotalSize) Max:$(Bytes2Human $MaxSize)"
					}

				}
			} while($TotalSize -gt $MaxSize)
			
	}

	function CheckCollectAge {
		param($Directory,$Filter = '*',$MaxTime,$Action)
		
		if(!$MaxTime){
			return;
		}
		
		if(-not(Test-Path $Directory)){
			return;
		}


		$DirectoryFilter = $Directory;
		if($Filter){
			$DirectoryFilter += '\'+$Filter;
		}	
		
		$ExpectedOldestTime = (Get-Date).addSeconds(-$MaxTime);
		
		log -v "Checking files older than $ExpectedOldestTime ($MaxTime sec ago) on $Directory"
		
		$OldestFiles = gci $DirectoryFilter | ? { $_.LastWriteTime -lt $ExpectedOldestTime } | sort CreationTime;
		
		if(!$OldestFiles){
			return;
		}
		
		log "There are files last modified older than $MaxTime seconds ($ExpectedOldestTime)"
		
		if($Action -eq 'error'){
			$ComDc.stop($true); 
			throw "MAX_TIME_REACHED: ExpectedOldestTime:($ExpectedOldestTime) ($MaxTime seconds ago)"
		}
		
		
		if($Action -eq 'oldremove'){
			$FilesToRemoveString = @($OldestFiles | %{ "`t`t`t"+$_.Name+" LastModified:$($_.LastWriteTime)" }) -Join "`r`n";
			
			log "	Following files will be removed:`r`n$FilesToRemoveString"
			$OldestFiles | Remove-Item -force;
		}
	}

	function CollectProcess {
		param($Directory)
		
		$ts = (Get-Date).toString("yyyyMMdd_HHmmss")
		$LogFile = "$Directory\process_$ts.csv";
		
		log -v "Running Get-Process and exporting to $LogFile";
		$p = get-process | select id,name,WorkingSet64,StartTime,PagedMemorySize64,PeakPagedMemorySize,TotalProcessorTime,UserProcessorTime,PrivilegedProcessorTime,VirtualMemorySize64,Threads,SessionId,PrivateMemorySize64,PrivateMemorySize
		$p | Export-Csv $LogFile;
		log -v "	Done!";
	}


	if($MaxProcessTime){
		$MaxProcessTimeSeconds = Human2Secs $MaxProcessTime;
	} else {
		$MaxProcessTimeSeconds = $MaxCollectTimeSeconds;
	}
	
	if($ProcessLogFrequency){
		$ProcessLogSeconds = Human2Secs $ProcessLogFrequency
		$LastProcessCollect = (Get-Date).addSeconds( -$ProcessLogSeconds - 10);
	}
	
	log "Starting collector and monitoring...";
	$i = 0;
	while($true){
		$i++;
		
		log -v "Starting collector..."
		#https://docs.microsoft.com/en-us/windows/win32/api/pla/nf-pla-idatacollectorset-start
		$ComDc.start($true);
		$Started = Get-Date;
		
		log -v "Starting check loop...";
		do {
			
			#Check size of all directories with some logging...
			CheckDirSize -Directory $CountersLogDirectory,$ProcessLogDirectory  -MaxSize $MaxCollectSize -Action $OnMax
			
			#Validating counters log directory...
			CheckCollectAge -Directory $CountersLogDirectory -Filter '*.blg' -MaxTime $MaxCollectTimeSeconds -Action $OnMax
		
			#Process collect and validation...
			if($ProcessLogSeconds){
				$Elapsed = ((Get-Date) - $LastProcessCollect).totalSeconds;
				
				
				if($Elapsed -ge $ProcessLogSeconds){
					log -v "Collecting process info..."
					CollectProcess -Directory $ProcessLogDirectory
					$LastProcessCollect = Get-Date;
				}


				CheckCollectAge -Directory $ProcessLogDirectory -Filter '*.csv' -MaxTime $MaxProcessTimeSeconds -Action $OnMax
			}
			
			
			$Elapsed = ((Get-Date) - $Started).totalSeconds;
			
			log -v "Sleeping for $CheckFrequency";
			Start-Sleep -s $CheckFrequencySeconds;
		} while( $Elapsed -lt $RenewFrequencySeconds )
		
		
		
		if($ComDc.status -eq 1){
			log -v "Stopping data collector...";
			$ComDc.stop($true);
		}	
		 
	}


} catch {
	log $_;
}

