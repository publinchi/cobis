
/************************************************************************/
/*      Archivo:                utilida01.sp                            */
/*      Stored procedure:       sp_utilidad01_crea_op                   */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Fabian de la Torre                      */
/*      Fecha de escritura:     Ene. 1998                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*     Calculo IVA IMO                                                  */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_utilidad01_crea_op')
   drop proc sp_utilidad01_crea_op
go

create proc sp_utilidad01_crea_op
(
@i_param1   datetime, -- fecha de proceso
@i_param2   int = 1,  -- cantidad de operaciones grupales
@i_param3   int = 8  -- cantidad de operaciones grupales
)
as
declare
	@w_tramite int,
	@w_fecha datetime,
	@w_contador  int,
	@w_referencia varchar(64),
	@w_num_op_grupales INT,    
	@w_sep           varchar(1),
	@w_bd            varchar(200),
	@w_tabla         varchar(200),
	@w_path_sapp     varchar(200),
	@w_sapp          varchar(200),
	@w_path          varchar(200),
	@w_hora              char(6),
	@w_destino       varchar(200),
	@w_errores       varchar(200),
	@w_fecha_arch    varchar(10),
	@w_return        int,
	@w_comando       varchar(2000),
	@w_promo         char(1)

DECLARE @w_tmp_utilidad AS TABLE (tramite int)

 
print 'ejecutando sp'


select @w_fecha = @i_param1 ---mmddaaaa
select @w_contador = 0
select @w_num_op_grupales = @i_param2

update ca_fuente_recurso 
set fr_monto          = fr_monto + @w_num_op_grupales * 3000000
where fr_fondo_id = 1

while @w_contador < @w_num_op_grupales
begin
	--IF @w_contador % 2 <> 0 
		--select @w_promo = 'S'
	--ELSE 
		select @w_promo = 'N'
/*        
    exec cob_cartera..sp_ingresa_ope_grupales
    @s_user = 'zperez',
    @s_ofi = 200,
	@s_date = @w_fecha,
    @i_integrantes = @i_param3, 

    @i_fecha_valor = @w_fecha,
    @i_nombre_proceso = 'SOLICITUD CREDITO GRUPAL SANTANDER',
    @i_mostrar_tra    = 'S',
	@i_promo          = @w_promo,
    @o_tramite = @w_tramite OUTPUT,
    @o_referencia = @w_referencia OUTPUT
*/    
    insert into @w_tmp_utilidad values (@w_tramite)

    select @w_contador = @w_contador + 1
end -- while

select 'tramite generados' , * from @w_tmp_utilidad

--/////////////////////////////////////////////////////////////
-- GENERACION DEL ARCHIVO DE RESULTADOS
--/////////////////////////////////////////////////////////////

select
      @w_bd       = 'cob_cartera',
      @w_tabla    = 'tmp_cadena',
      @w_sep      = '|' 

--Generacion del archivo
select @w_path_sapp = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'S_APP'

if @w_path_sapp is null
BEGIN
   PRINT ' no existe path del sapp'
   RETURN 7999
end

select @w_path  = pp_path_destino
from cobis..ba_path_pro
where pp_producto  = 7

select @w_sapp      = @w_path_sapp + 's_app'

select @w_fecha_arch = convert( 
varchar, @w_fecha, 112)
select @w_hora = substring(convert(varchar, getdate(), 108), 1,2)+
                 substring(convert(varchar, getdate(), 108), 4,2)+
                 substring(convert(varchar, getdate(), 108), 7,2)

select
   @w_destino  = 'UTIL_CREOPGRP' + '_' + @w_fecha_arch + '_' + @w_hora + '.txt',
   @w_errores  = 'UTIL_CREOPGRP' + '_' + @w_fecha_arch + '_' + @w_hora + '.err'


truncate table tmp_cadena

insert into tmp_cadena
select 
   'TRAMITE'    + @w_sep + 
   'ID_GRUPO'   + @w_sep + 
   'ID_CLIENTE' + @w_sep + 
   'PRESTAMO'   + @w_sep + 
   'PRESTAMO GR'  

insert into tmp_cadena
select 
   convert(varchar,tg_tramite)           + @w_sep + 
   convert(varchar,tg_grupo)             + @w_sep + 
   convert(varchar,tg_cliente)           + @w_sep + 
   convert(varchar,tg_prestamo)          + @w_sep + 
   convert(varchar,tg_referencia_grupal)  
FROM cob_credito..cr_tramite_grupal, @w_tmp_utilidad
WHERE tg_tramite = tramite


select  @w_comando = @w_sapp + ' bcp -auto -login ' + @w_bd + '..'  + @w_tabla + ' out ' + @w_path+@w_destino + ' -b5000 -c -e' + @w_path+@w_errores + ' -t"'+@w_sep + '" -config ' + @w_sapp + '.ini'

print ' COMANDO ==> '+ @w_comando

exec @w_return = xp_cmdshell @w_comando
if @w_return <> 0 
begin
   PRINT 'ERROR AL GENERAR ARCHIVO '+@w_destino+ ' '+ convert(varchar, @w_return)
   return 7998
end


RETURN 0

                                                                                                                                                                                                                                                                                                                                                                                                                        

go