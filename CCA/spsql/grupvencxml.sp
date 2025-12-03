/************************************************************************/
/*   Archivo:              grupvencxml.sp                               */
/*   Stored procedure:     sp_grupos_vencidos_xml                       */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Fecha de escritura:   Julio 2017                                   */
/************************************************************************/
/*                                  IMPORTANTE                          */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBIS'.                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBIS o su representante legal.           */
/************************************************************************/
/*                                   PROPOSITO                          */
/*   Genera archivo xml de cartera grupal vencida                       */
/*                              CAMBIOS                                 */
/*  FECHA       AUTOR                   RAZON                           */
/*07/Jun/2018  P. Ortiz              Corregir validacion para NO DATA   */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_grupos_vencidos_xml')
   drop proc sp_grupos_vencidos_xml
go

create proc sp_grupos_vencidos_xml
(
    
    @i_tipo_rep varchar(10),
    @o_msg      varchar(255) = null out
)
as 

declare 
        @w_error            int,
        @w_mensaje          varchar(150),
        @w_sql              varchar(5000),
        @w_sql_bcp          varchar(5000),
        @w_ruta_xml         varchar(255),
        @w_archivo_xml      varchar(30),
        @w_sp_name          varchar(30),
        @w_msg              varchar(255)

declare
		@w_fecha_respaldo  varchar(32)

SELECT
		@w_fecha_respaldo  = replace(
		convert(VARCHAR, getdate(),112) +'_' + 	substring(format(getdate(), 'yyyy-MM-ddTHH:mm:ss:ms'), 12,32)
		, ':', '')


select @w_sp_name = 'sp_genera_xml'
declare @resultadobcp table (linea varchar(max))

select @w_ruta_xml = ba_path_destino
    from cobis..ba_batch 
    where ba_batch = 7075

if (@@error != 0 or @@rowcount != 1 or isnull(@w_ruta_xml, '') = '')
begin
   select @w_error = 724623
    goto ERROR_PROCESO
end


truncate table gerentesxml
truncate table coordinadoresxml
truncate table asesoresxml

if @i_tipo_rep = 'PFGVG'
begin
    insert into gerentesxml (gv_gerente_id,gv_gerente_name,gv_gerente_email)
    select distinct
    gv_gerente_id,
    convert(varchar(64), gv_gerente_name)  as gv_gerente_name,
    convert(varchar(255),gv_gerente_email) as gv_gerente_email
    from cob_cartera..ca_grupos_vencidos 
end

insert into coordinadoresxml (gv_coord_id,gv_coord_name,gv_coord_email)
select distinct
gv_coord_id,
convert(varchar(64), gv_coord_name)  as gv_coord_name,
convert(varchar(255),gv_coord_email) as gv_coord_email
from cob_cartera..ca_grupos_vencidos 

insert into asesoresxml (gv_asesor_id, gv_asesor_name)
select distinct  
gv_asesor_id,
convert(VARCHAR(255),gv_asesor_name)  as gv_asesor_name
from cob_cartera..ca_grupos_vencidos


if @i_tipo_rep = 'PFGVG'
    select @w_archivo_xml = 'gruposvencigerent.xml'
if (@i_tipo_rep = 'PFGVC')
    select @w_archivo_xml = 'gruposvencicoord.xml'

/* SACAR RESPALDO AL ARCHIVO Y PONERLO EN LA CARPETA HISTORICA */
SELECT @w_sql_bcp = 'copy ' + @w_ruta_xml + @w_archivo_xml + ' ' + @w_ruta_xml + 'history\' +
                    substring(@w_archivo_xml,1,charindex('.', @w_archivo_xml)-1) + '_' + @w_fecha_respaldo + '.xml'

PRINT ' SQL 1 ' + @w_sql_bcp

delete from @resultadobcp
insert into @resultadobcp
EXEC xp_cmdshell @w_sql_bcp;

/*  BORRAR EL ARCHIVO */
select	@w_sql_bcp = 'del ' + @w_ruta_xml + @w_archivo_xml
delete from @resultadobcp
insert into @resultadobcp
EXEC xp_cmdshell @w_sql_bcp;

PRINT ' SQL 2 ' + @w_sql_bcp


-- LGU generar archivo con NO_DATA para que no se caiga el Notificador
/*if (NOT exists (select 1 from ca_grupos_vencidos))
BEGIN
	GOTO NO_DATOS
END */

if @i_tipo_rep = 'PFGVG'
begin
    select @w_archivo_xml = 'gruposvencigerent.xml'

    if not exists (select 1
            from  cob_cartera..gerentesxml as Gerente, 
            cob_cartera..coordinadoresxml  as Coordinador, 
            cob_cartera..asesoresxml       as Asesor, 
            cob_cartera..ca_grupos_vencidos    as Grupo  
            where Grupo.gv_gerente_id = Gerente.gv_gerente_id 
            and   Grupo.gv_coord_id   = Coordinador.gv_coord_id 
            and   Grupo.gv_asesor_id  = Asesor.gv_asesor_id 
            and   gv_cuotas_vencidas >= 4 )
    begin
        GOTO NO_DATOS
    end
    
    select  @w_sql = 'select Gerente.gv_gerente_id,' +
          'Gerente.gv_gerente_name,' +
          'Gerente.gv_gerente_email,' +
          'Coordinador.gv_coord_id,' +
          'Coordinador.gv_coord_name,' +
          'Asesor.gv_asesor_id, ' +
          'Asesor.gv_asesor_name,' +
          'gv_grupo_id, ' +
          'gv_grupo_name,' +
          'gv_cuotas_vencidas,' +
          'gv_saldo_exigible, ' +
          'gv_cuota_actual ' + 
          'from  cob_cartera..gerentesxml as Gerente, ' +
          'cob_cartera..coordinadoresxml  as Coordinador, '  +
          'cob_cartera..asesoresxml       as Asesor, ' +
          'cob_cartera..ca_grupos_vencidos    as Grupo  ' +
          'where Grupo.gv_gerente_id = Gerente.gv_gerente_id ' +
          'and   Grupo.gv_coord_id   = Coordinador.gv_coord_id ' +
          'and   Grupo.gv_asesor_id  = Asesor.gv_asesor_id ' +
          'and   gv_cuotas_vencidas >= 4 ' +
          'order by Gerente.gv_gerente_id, Coordinador.gv_coord_id, Asesor.gv_asesor_id ' + 
          'for xml auto, root (' + char(39) +  'grupos_vencidos_gerent' + char(39) + '), elements  '
end
else if (@i_tipo_rep = 'PFGVC')
begin
    select @w_archivo_xml = 'gruposvencicoord.xml'
    
    if not exists (select 1
            from  cob_cartera..coordinadoresxml as Coordinador,  
            cob_cartera..asesoresxml      as Asesor,  
            cob_cartera..ca_grupos_vencidos    as Grupo  
            where Grupo.gv_coord_id   = Coordinador.gv_coord_id  
            and   Grupo.gv_asesor_id  = Asesor.gv_asesor_id   
            and   gv_cuotas_vencidas >= 2 )
    begin  
        GOTO NO_DATOS
    end
    
    select @w_sql = 'select Coordinador.gv_coord_id,' + 
          'Coordinador.gv_coord_name,' + 
          'Coordinador.gv_coord_email,' + 
          'Asesor.gv_asesor_id, ' + 
          'Asesor.gv_asesor_name,' + 
          'gv_grupo_id, ' + 
          'gv_grupo_name,' + 
          'gv_cuotas_vencidas,' + 
          'gv_saldo_exigible, ' + 
          'gv_cuota_actual ' + 
          'from  cob_cartera..coordinadoresxml as Coordinador, ' + 
          'cob_cartera..asesoresxml      as Asesor, ' + 
          'cob_cartera..ca_grupos_vencidos    as Grupo ' + 
          'where Grupo.gv_coord_id   = Coordinador.gv_coord_id ' + 
          'and   Grupo.gv_asesor_id  = Asesor.gv_asesor_id  ' + 
          'and   gv_cuotas_vencidas >= 2 ' + 
          'order by Coordinador.gv_coord_id, Asesor.gv_asesor_id ' + 
          'for xml auto, root (' + char(39) + 'grupos_vencidos_coord' + char(39) + '), elements '
end

select  @w_sql_bcp = 'bcp "' + @w_sql + '" queryout "' + @w_ruta_xml + @w_archivo_xml + '" -c -r -t\t -T'

delete from @resultadobcp
insert into @resultadobcp
EXEC xp_cmdshell @w_sql_bcp;

select * from @resultadobcp

--SELECCIONA CON %ERROR% SI NO ENCUENTRA EN EL FORMATO: ERROR = 
if @w_mensaje is null
    select top 1 @w_mensaje =  linea 
        from @resultadobcp 
        where upper(linea) LIKE upper('%Error%')

if @w_mensaje is not null
begin
    select @w_error = 724625
    goto ERROR_PROCESO
end

return 0
   
ERROR_PROCESO:
    select @w_msg = mensaje
        from cobis..cl_errores with (nolock)
        where numero = @w_error
        set transaction isolation level read uncommitted
      
   select @w_msg = isnull(@w_msg, @w_mensaje)
      
   select @o_msg = ltrim(rtrim(@w_msg))
   select @o_msg
   return @w_error

-- LGU
NO_DATOS:
		SELECT @w_sql_bcp = 'echo NO_DATA> ' + @w_ruta_xml + @w_archivo_xml

		delete from @resultadobcp
		insert into @resultadobcp
		EXEC xp_cmdshell @w_sql_bcp

		RETURN 0


go


