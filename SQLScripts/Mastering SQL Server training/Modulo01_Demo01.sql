/****************************************************************************************
*****************************************************************************************
			
		***		Treinamento: SQL23 - SQL Server 2012: Mastering the Database Engine		***

	Autor: Luciano Caixeta Moreira
	E-mail: luciano.moreira@srnimbus.com.br
	Blog: http://luticm.blogspot.com
	Twitter: @luticm
	
	Título: Modulo 01 - Demo 01 - Disk Partitioning Alignment
	Descrição: 
		
	* Copyright (C) 2012 Sr. Nimbus Prestação de Serviços em Tecnologia LTDA 
	* http://www.srnimbus.com.br

*****************************************************************************************	
****************************************************************************************/

/*
	Alinhamento de disco
*/

/*
CMD AS ADMIN
DISKPART
LIST DISK
SELECT DISK 1
DETAIL DISK
(notar volumes e partições, tipo disco, LUN, crash-dump disk, read-only, etc.)
LIST PARTITION
(mostra partições e uma é do OEM = Original Equipment Manufacturer)
SELECT PARTITION 1 
DETAIL PARTITION (mostra offset já atrapalhado – 63 setores, mesmo assim a próxima poderia ser corrigida)

Como saber o cluster size?

fsutil fsinfo ntfsinfo e:
fsutil fsinfo ntfsinfo c:
*/

