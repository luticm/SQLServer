#****************************************************************************************
#****************************************************************************************
#	Autor: Luciano Caixeta Moreira
#	E-mail: luciano.moreira@srnimbus.com.br
#	LinkedIn: http://www.linkedin.com/in/luticm
#	Blog: http://luticm.blogspot.com
#	Twitter: @luticm
#
#    v0.9 -> Considerada estável para ambientes de produção.
#
#****************************************************************************************
#****************************************************************************************

# Funçao auxiliar para validar entradas do tipo (Y/N)
Function ValidaYN 
{ 
    Param(
        [String]
        $entrada
    )

    process {
	    if ($valordefault.length -eq 0) {
            $valordefault = 'Y'
        }
	
	    if($entrada.length -eq 0){
            $entrada = $valordefault;        
	    }

	    if( @("Y","N") -Contains $entrada ){
		    return $entrada;
	    } else {
		    throw "Opção inválida: $entrada"
	    }
    }
}

# Para o script caso encontre qualquer exceção 
$ErrorActionPreference = "Stop";

#Alias para facilitar
Set-Alias wh Write-Host

@(
'********************************************************************************************'
'       Script auxiliar para criar Data Collector Set'
''
'    	Autor: Luciano Caixeta Moreira'
'    	E-mail: luciano.moreira@srnimbus.com.br'
'    	LinkedIn: http://www.linkedin.com/in/luticm'
'    	Blog: http://luticm.blogspot.com'
'    	Twitter: @luticm'
'********************************************************************************************'
) | %{ wh $_ }

# Define variáveis utilizadas pelo script
$VARS = @{
	
	# Diretorio raiz para armazenar arquivos
	filepath = $null
	
	# Define nome do data collector
	dcname = $null
	
	# Armazena o arquivo de configuração
	cfg = @()
	
	# Lista de instâncias ativas na máquina
	instList = @()
}

$VARS.filepath = Read-Host -Prompt 'Caminho para arquivos do perfmon (<Enter> para "C:\Perflogs\")'
if ($VARS.filepath.Length -eq 0)
{
    $VARS.filepath = 'C:\PerfLogs\'
}

$VARS.dcname = Read-Host -Prompt 'Nome do data collector (<Enter> para "Baseline_SQLServer")'
if ($VARS.dcname.Length -eq 0)
{
    $VARS.dcname = 'Baseline_SQLServer'
}

# Armazena conteúdo do arquivos de configuração
$cfg = ''
# Lista das instâncias ativas na máquina
$instList = @()

# Contadores básicos do SO
$answer = ValidaYN((Read-Host -Prompt 'Incluir contadores do SO (Y/N - <Enter> para "Y")?').ToUpper())
if ($answer.ToUpper() -eq 'Y')
{
    $VARS.cfg +=  @(
		'\LogicalDisk(*)\*'
		'\Network Interface(*)\*'
		'\Memory(*)\*'
		'\Paging file(*)\*'
		'\PhysicalDisk(*)\*'
		'\Processor Information(*)\*'
		'\System(*)\*'
	) 
}


# Lista os processos em execução relacionados ao SQL Server e inclui os contadores destes
$procs = Get-Process "sql*"
$prochash = @{ 'sqlservr' = 0; 'SQLAgent' = 0 }

# Lista os contadores disponíveis, substituindo o * que não é usado por um bug
# Ref: https://social.technet.microsoft.com/Forums/en-US/cc5a3a9b-9517-4346-a114-aa5d23c1cf92/bug-user-defined-perfmon-data-collector-set-cannot-capture-data-just-from-one-process-object?forum=perfmon
$c = New-Object System.Diagnostics.PerformanceCounterCategory("Process")

foreach ($p in $procs)
{
    if ($p.Name -eq 'sqlservr' -or $p.Name -eq 'SQLAgent')
    {
        # Caso exista mais de um processo do SQL Server rodando, a nomenclatura utilizada pelo
        # Perfmon é <processo>#N, onde N é um valor incremental (ex.: sqlservr#1)
        if ($prochash[$p.Name] -gt 0)
        {
            if($c.InstanceExists($p.Name))
            {
	            $allCounters = $c.GetCounters($p.Name)
	            $AllCounters | %{
                    $VARS.cfg += "\Process($($p.Name)#$($prochash[$p.Name]))\$($_.CounterName)"
	            }
            }
        }
        else
        {
            if($c.InstanceExists($p.Name))
            {
	            $allCounters = $c.GetCounters($p.Name)
	            $AllCounters | %{
                    $VARS.cfg += "\Process($($p.Name))\$($_.CounterName)"
	            }
            }
        }

        # Contabiliza o número de processos, para definir corretamente os contadores de coleta
        $prochash[$p.Name] += 1
    }
}

# Lista instâncias do SQL Server ativas
$svcs = Get-Service
foreach ($s in $svcs)
{
    # Lista instâncias do SQL Server ativas
    if ($s.DisplayName -like '*SQL Server (*' -and $s.Status -eq 'Running')
    {
        if ($s.ServiceName.IndexOf('$') -eq -1)
        {
            $VARS.instList += 'SQLServer'
        }
        else
        {
            $VARS.instList += ($s.ServiceName)
        }
    }
}

$answer = ValidaYN((Read-Host -Prompt 'Incluir contadores core do SQL Server (Y/N - <Enter> para "Y")').ToUpper())
if ($answer.ToUpper() -eq 'Y')
{
    foreach ($instancia in $VARS.instList)
    {
        $VARS.cfg += @(
            "\$($instancia):Access Methods(*)\*"
            "\$($instancia):Buffer Manager(*)\*"
            "\$($instancia):Buffer Node(*)\*"
            "\$($instancia):Catalog Metadata(*)\*"
            "\$($instancia):Databases(*)\*"
            "\$($instancia):Exec Statistics(*)\*"
            "\$($instancia):General Statistics(*)\*"
            "\$($instancia):Latches(*)\*"
            "\$($instancia):Locks(*)\*"
            "\$($instancia):Memory Manager(*)\*"
            "\$($instancia):Memory Node(*)\*"
            "\$($instancia):Plan Cache(*)\*"
            "\$($instancia):Resource Pool Stats(*)\*"            
            "\$($instancia):SQL Statistics(*)\*"
            "\$($instancia):Transactions(*)\*"
            "\$($instancia):Wait Statistics(*)\*"
            "\$($instancia):Workload Group Stats(*)\*"
        )
    }
}

# Contadores SQL Server adicionais
$answer = ValidaYN((Read-Host -Prompt 'Incluir contadores adicionais do SQL Server (Y/N - <Enter> para "Y")?').ToUpper())
if ($answer.ToUpper() -eq 'Y')
{
    foreach ($instancia in $VARS.instList)
    {
        $VARS.cfg += @(
            "\$($instancia):Backup Device(*)\*"
            "\$($instancia):Batch Resp Statistics(*)\*"
            "\$($instancia):CLR(*)\*"
            "\$($instancia):Cursor Manager by Type(*)\*"
            "\$($instancia):Cursor Manager Total(*)\*"
            "\$($instancia):Deprecated Features(*)\*"
            "\$($instancia):FileTable(*)\*"
            "\$($instancia):HTTP Storage(*)\*"
            "\$($instancia):Memory Broker Clerks(*)\*"
            "\$($instancia):SQL Errors(*)\*"            
        )
    }
}

# Contadores do Service Broker
$answer = ValidaYN((Read-Host -Prompt 'Incluir contadores do Service Broker (Y/N - <Enter> para "Y")?').ToUpper())
if ($answer.ToUpper() -eq 'Y')
{
    foreach ($instancia in $VARS.instList)
    {
        $VARS.cfg += @(
            "\$($instancia):Broker Activation(*)\*"
            "\$($instancia):Broker Statistics(*)\*"
            "\$($instancia):Broker TO Statistics(*)\*"
            "\$($instancia):Broker/DBM Transport(*)\*"            
        )
    }
}

# Contadores de replicação
$answer = ValidaYN((Read-Host -Prompt 'Incluir contadores de Replicação (Y/N - <Enter> para "Y")?').ToUpper())
if ($answer.ToUpper() -eq 'Y')
{
    foreach ($instancia in $VARS.instList)
    {
        $VARS.cfg += @(
            "\$($instancia):Replication Agents(*)\*"
            "\$($instancia):Replication Snapshot(*)\*"
            "\$($instancia):Replication Logreader(*)\*"
            "\$($instancia):Replication Dist.(*)\*"
            "\$($instancia):Replication Merge(*)\*"            
        )
    }
}

# Contadores de AG e Mirroring
$answer = ValidaYN((Read-Host -Prompt 'Incluir contadores de AG/Mirroring (Y/N - <Enter> para "Y")?').ToUpper())
if ($answer.ToUpper() -eq 'Y')
{
    foreach ($instancia in $VARS.instList)
    {
        $VARS.cfg += @(
            "\$($instancia):Availability Replica(*)\*"
            "\$($instancia):Database Mirroring(*)\*"
            "\$($instancia):Database Replica(*)\*"
            "\$($instancia):HADR Availability Replica(*)\*"
            "\$($instancia):HADR Database Replica(*)\*"            
        )
    }
}

$BaseName = "$($VARS.filepath)$($VARS.dcname)"
$configFile = "$BaseName.config"

wh "Config file $configFile"
wh 'Caminho do arquivo: ' $VARS.filepath
wh 'Nome do data collector: ' $VARS.dcname

$VARS.cfg | Out-File $configFile -Encoding ASCII
notepad.exe $configFile

$answer = ValidaYN((Read-Host -Prompt 'Pronto para continuar (Y/N - <Enter> para "Y")').ToUpper())
if ($answer.ToUpper() -ne 'Y') { exit 1 }

# Tenta apagar um DCS existente. Caso nenhum de mesmo nome exista, não reporta erro.
wh "`r`nApagando Data Collector Set $($VARS.dcname). Se não existir, ignore o erro."
logman delete $VARS.dcname

# Cria data colector com as seguintes configurações:
#     - Binário
#     - Intervalod de 15 segundos
#     - Armazenado no caminho definido (ex.: "C:\Perflogs\") e com nome Baseline_SQLServer, com sufixo numérico para versionamento (nnnnnn)
#     - Tamanho máximo de 250 MB ou 12 horas de coleta; 
#     - Cria um novo assim que o limite é atingido
#     - Arquivo de configuração com os contadores Ex.: 'C:\Perflogs\Baseline_SQLServer.config'

wh "Comando executado: logman create counter $($VARS.dcname) -f bin -si 10 -o $BaseName -v nnnnnn -max 250 -cf $configFile"
logman create counter $VARS.dcname -f bin -si 15 -o $BaseName -v nnnnnn -max 250 -cf $configFile -cnf 12:00:00