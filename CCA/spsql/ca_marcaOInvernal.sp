/************************************************************************/
/*   Archivo:             ca_marcaOInvernal.sp                          */
/*   Stored procedure:    sp_marcar_Ola_Invernal                        */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        Elcira Pelaez Burbano                          */
/*   Fecha de escritura:  Dic.-2011                                     */
/************************************************************************/
/*                              IMPORTANTE                              */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*  Marcación como reestructurada, incremento en el conteo de           */
/*  reestructuraciones, causal de 'ola invernal', fecha                 */
/*  de reestructuración = fecha de desembolso, calificación             */
/*  de reestructuración ='A', si el cliente no ha sido marcado como     */
/*  afectado por 'Ola invernal' debe ser marcado (02)                   */
/*  ORS.000284 Bancamia                                                 */             
/************************************************************************/
/*                             ACTUALIZACIONES                          */
/*                                                                      */
/*     FECHA              AUTOR            CAMBIO                       */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_marcar_Ola_Invernal')
   drop proc sp_marcar_Ola_Invernal
go
create proc sp_marcar_Ola_Invernal
@i_param1     varchar(255) --codigo del proceso batch

as declare

@w_s_app                        varchar(255),
@w_path                         varchar(255),
@w_destino                      varchar(255),
@w_errores                      varchar(255),
@w_cmd                          varchar(500),
@w_comando                      varchar(5000),
@w_batch                        int,
@w_error                        int,
@w_fecha_hoy                    datetime,
@w_hora_arch     		        varchar(4),
@w_fecha_iniMarca                datetime,
@w_ol_operacion                  int,
@w_ol_cliente                    int,
@w_ol_fecha_rees                 datetime,
@w_ol_calificacion               char(1),
@w_ol_casilla_def                varchar(24)  ,
@w_secuencial                    int,
@w_inicio_mes                    datetime,
@w_fecha_ini                     datetime,
@w_fecha_mov                     datetime


---RESPALDAR LAS PROCESADAS

insert into ca_marcarPor_ola_invernal_his
select * from ca_marcarPor_ola_invernal_tmp

truncate table ca_marcarPor_ola_invernal_tmp

select @w_fecha_hoy   = fc_fecha_cierre 
from cobis..ba_fecha_cierre 
where fc_producto = 7


---Esta fecha me indics ual es el cierre inmediatamente anterior
---para que todas las RES que se hacen durante el mes en curso quedarancon la fecha de 
---desembolso las viejas quedan con la fecha de proceso
select @w_inicio_mes  	= dateadd(dd,-(datepart(dd,@w_fecha_hoy )),@w_fecha_hoy)

select @w_batch = convert(int,@i_param1)

select @w_fecha_iniMarca = pa_datetime
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'FMRES'
if @@rowcount = 0 
begin
   PRINT 'Error No se ha creado el parametro general FMRES'
   return 708153
end 

insert into ca_marcarPor_ola_invernal_tmp
select op_banco,op_operacion, op_cliente, op_toperacion,op_fecha_ini,'A', '002', getdate(),@w_batch
from ca_operacion o with (nolock)
where op_toperacion in ( select codigo from cobis..cl_catalogo  with (nolock)
                         where tabla = (select codigo from cobis..cl_tabla 
                                        where tabla = 'ca_lineas_ola_invernal')
                       )
and op_estado in (1,9)
and op_fecha_ini >  @w_fecha_iniMarca
and not exists (select 1 from ca_transaccion  with (nolock)
                where tr_operacion = o.op_operacion
                and   tr_tran = 'RES' 
                and   tr_estado <> 'RV'
                and   tr_secuencial >= 0)
 
declare  cursor_marcaOInvernal cursor for
select ol_operacion,  
       ol_cliente
    
from   ca_marcarPor_ola_invernal_tmp
for read only

open    cursor_marcaOInvernal

fetch   cursor_marcaOInvernal into
@w_ol_operacion,
@w_ol_cliente

while   @@fetch_status = 0 
begin 

	 exec @w_secuencial = sp_gen_sec
	 @i_operacion       = @w_ol_operacion

	 -- OBTENER RESPALDO ANTES DE LA REESTRUCTURACION FICTICIA
	 exec sp_historial
	 @i_operacionca = @w_ol_operacion,
	 @i_secuencial  = @w_secuencial

     update ca_operacion
	 set op_numero_reest = 1,
	     op_calificacion = 'A'
	 where op_operacion = @w_ol_operacion
	 
	 update cobis..cl_ente
	 set en_casilla_def = '002'
	 where en_ente = @w_ol_cliente

	-- TRANSACCION INFORMATIVA ES NECESARIA POR SI EXISTEN REPORTES QUE LEEN DE ESTA TABLA
	-- PARA VERIFICAR QUE LA OPERACION TENGA REESTRUCTURACIONES 
	---print 'oper ' + cast(@w_ol_operacion as varchar) 
	
	select @w_fecha_ini = op_fecha_ini
	from ca_operacion
	where op_operacion = @w_ol_operacion
	
	if @w_fecha_ini > @w_inicio_mes
	   select @w_fecha_mov = @w_fecha_ini
	else
	   select @w_fecha_mov = @w_fecha_hoy
	
	
	insert into ca_transaccion (
	tr_secuencial,      tr_fecha_mov,         tr_toperacion,
	tr_moneda,          tr_operacion,         tr_tran,
	tr_en_linea,        tr_banco,             tr_dias_calc,
	tr_ofi_oper,        tr_ofi_usu,           tr_usuario,
	tr_terminal,        tr_fecha_ref,         tr_secuencial_ref,
	tr_estado,          tr_gerente,           tr_calificacion,
	tr_gar_admisible,   tr_observacion,       tr_comprobante,
	tr_fecha_cont,      tr_reestructuracion)
	select 
	@w_secuencial,      @w_fecha_mov,         op_toperacion,
	op_moneda,          op_operacion,         'RES',
	'S',                op_banco,             0,
	op_oficina,         1,                    'sa',
	'Consola',          @w_fecha_mov,         0,
	'NCO',              op_oficial,          isnull(op_calificacion,'A'),
	isnull(op_gar_admisible, 'O'), 'REESTRUCTURACION-BACTH-MARCA-MANUAL-Pro7123',   0,
	'',                 'S'
	from ca_operacion
	where op_operacion = @w_ol_operacion
	if @@error <> 0 begin
	   PRINT 'Error Insertando trannccion Informativa de Reestructuracion'
	   return  708165
	end

	 ---Actualizar la fecha enla tabal que quedara como respaldo
	 update ca_marcarPor_ola_invernal_tmp
	 set ol_fecha_rees = @w_fecha_mov
	 where  ol_operacion = @w_ol_operacion
	 
   fetch   cursor_marcaOInvernal into
	@w_ol_operacion,
	@w_ol_cliente

end ---fin cursor

close cursor_marcaOInvernal
deallocate cursor_marcaOInvernal

PRINT 'Fin Del Proceso'
select  ol_banco from ca_marcarPor_ola_invernal_tmp
            
return 0
go

