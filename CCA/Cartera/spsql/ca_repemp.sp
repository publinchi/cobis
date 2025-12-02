/*ca_repemp.sp***********************************************************/
/*  Archivo:                         ca_repemp.sp                       */
/*  Stored procedure:                sp_reporte_empleado                */
/*  Base de datos:                   cob_credito                        */
/*  Producto:                        Credito                            */
/*  Disenado por:                    Luis Ponce                         */
/*  Fecha de escritura:              02-02-2011                         */
/************************************************************************/
/*              IMPORTANTE                                              */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  'MACOSA', representantes exclusivos para el Ecuador de NCR          */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado hecho por alguno de sus             */
/*  usuarios sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de MACOSA o su representante.                 */
/************************************************************************/
/*              PROPOSITO                                               */
/*  Generar REPORTE USAID                                               */
/************************************************************************/
/*              MODIFICACIONES                                          */
/*  FECHA       AUTOR                    RAZON                          */
/*  02/02/2011  Alfredo Zuluaga          Emision Inicial                */
/************************************************************************/

use cob_cartera
go

if exists(select 1 from cob_cartera..sysobjects where name = 'ca_reporte_temporal')
   drop table ca_reporte_temporal
go

if exists (SELECT 1 from sysobjects WHERE name = 'sp_reporte_empleado')
   drop proc sp_reporte_empleado
go

create proc sp_reporte_empleado(
@i_param1            varchar(255)     --Fecha de Proceso

)
as
declare
@i_fecha              datetime,
@w_tdn                varchar(10), 
@w_fecha              datetime,
@w_sp_name            varchar(20),
@w_s_app              varchar(50),
@w_path               varchar(50),
@w_nombre             varchar(16),
@w_nombre_cab         varchar(26),
@w_cmd                varchar(2000),
@w_destino            varchar(2000),
@w_errores            varchar(1000),
@w_error              int,
@w_comando            varchar(2000),
@w_nombre_plano       varchar(1000),
@w_mensaje            varchar(255),
@w_msg                varchar(255),
@w_col_id             int,
@w_columna            varchar(200),
@w_cabecera           varchar(1000),
@w_fecha_descuento    varchar(10),
@w_numero_registros   int,
@w_total_descuentos   money,
@w_linea_cobis        cuenta,     
@w_linea_pepnt        cuenta, 
@w_identificacion     varchar(20), 
@w_contador           int,
@w_linea_cobis_ant    cuenta, 
@w_identificacion_ant varchar(20), 
@w_banco              cuenta,
@w_cifras             varchar(1000)

set ansi_warnings off

select 
@i_fecha         = convert(datetime, @i_param1),
@w_sp_name       = 'sp_reporte_empleado'

select @w_s_app = pa_char
from cobis..cl_parametro
where pa_producto = 'ADM'
and   pa_nemonico = 'S_APP'

select @w_path = ba_path_destino
from cobis..ba_batch
where ba_batch = 7041

if exists(select 1 from cob_cartera..sysobjects where name = 'ca_reporte_temporal')
   drop table ca_reporte_temporal

if exists(select 1 from cob_cartera..sysobjects where name = 'ca_reporte_temporal_cifras')
   drop table ca_reporte_temporal_cifras

select @w_nombre = 'INTNOMDES_' 
--select @w_nombre = @w_nombre + case when datepart(dd,@i_fecha) <= 9 then '0' + convert(varchar(2), datepart(dd,@i_fecha)) else convert(varchar(2), datepart(dd,@i_fecha)) end
if datepart(dd,@i_fecha) <= 9
   select @w_nombre = @w_nombre + '0' + convert(varchar(2), datepart(dd,@i_fecha))
else
   select @w_nombre = @w_nombre + convert(varchar(2), datepart(dd,@i_fecha))
   
--select @w_nombre = @w_nombre + case when datepart(mm,@i_fecha) <= 9 then '0' + convert(varchar(2), datepart(mm,@i_fecha)) else convert(varchar(2), datepart(mm,@i_fecha)) end
if datepart(mm,@i_fecha) <= 9
   select @w_nombre = @w_nombre + '0' + convert(varchar(2), datepart(mm,@i_fecha))
else
   select @w_nombre = @w_nombre + convert(varchar(2), datepart(mm,@i_fecha))
	 
select @w_nombre = @w_nombre + convert(varchar(4), datepart(yy,@i_fecha)) 

create table ca_reporte_temporal (
ID_ORGANIZATION	        varchar(4)   null,
DT_LAST_UPDATE	        varchar(10)  null,
STD_ID_HR	            varchar(10)  null,
ID_DMD	                varchar(30)  null,
ID_DMD_COMPONENT	    varchar(30)  null,
PROJ	                int          null,
SCO_DT_ACCRUED	        varchar(10)  null,
SCO_ID_PAY_FREQUEN	    varchar(3)   null,
ID_M4_TYPE	            int          null,
SCO_VALUE	            varchar(20)  null,
SCO_ID_CURRENCY	        varchar(4)   null,
SCO_DT_EXCHANGE	        varchar(10)  null,
EX_TYPE	                varchar(10)  null,
SCO_ID_REA_CHANG	    varchar(3)   null,
ID_PRIORITY	            int          null,
SCO_COMMENT	            varchar(254) null,
ID_SECUSER	            varchar(30)  null,
ID_APPROLE	            varchar(30)  null,
V_MORA                  money        null,
D_MORA                  int          null
)

create table ca_reporte_temporal_cifras (
FECHA_DESCUENTO		    varchar(10)  null,
NUMERO_REGISTROS        int          null,
TOTAL_DESCUENTOS        money        null
)

create table #temporal (
ID_ORGANIZATION	        varchar(4)   null,
DT_LAST_UPDATE	        varchar(10)  null,
STD_ID_HR	            varchar(10)  null,
ID_DMD	                varchar(30)  null,
ID_DMD_COMPONENT	    varchar(30)  null,
PROJ	                int          null,
SCO_DT_ACCRUED	        varchar(10)  null,
SCO_ID_PAY_FREQUEN	    varchar(3)   null,
ID_M4_TYPE	            int          null,
SCO_VALUE	            varchar(20)  null,
SCO_ID_CURRENCY	        varchar(4)   null,
SCO_DT_EXCHANGE	        varchar(10)  null,
EX_TYPE	                varchar(10)  null,
SCO_ID_REA_CHANG	    varchar(3)   null,
ID_PRIORITY	            int          null,
SCO_COMMENT	            varchar(254) null,
ID_SECUSER	            varchar(30)  null,
ID_APPROLE	            varchar(30)  null,
V_MORA                  money        null,
D_MORA                  int          null
)

insert into #temporal (
ID_ORGANIZATION,     DT_LAST_UPDATE,        STD_ID_HR,
ID_DMD,              ID_DMD_COMPONENT,      PROJ,
SCO_DT_ACCRUED,      SCO_ID_PAY_FREQUEN,    ID_M4_TYPE,
SCO_VALUE,           SCO_ID_CURRENCY,       SCO_DT_EXCHANGE,
EX_TYPE,             SCO_ID_REA_CHANG,      ID_PRIORITY,
SCO_COMMENT,         ID_SECUSER,            ID_APPROLE,
V_MORA,              D_MORA
)
select 
'0085',              null,                  en_ced_ruc,
'DMD1',              op_toperacion,         1,
null,                '003',                 8,
null,                'COP',                 null,
'1',                 null,                  0,
op_banco,            'COBIS',               'COBIS',
0,                   0 
from cob_cartera..ca_operacion, cobis..cl_ente, ca_dividendo , cob_credito..cr_corresp_sib
where op_estado     in (1,2,4,9)
and   op_cliente    = en_ente
and   op_operacion  = di_operacion
and   di_estado     in ( 1,2 )
and   di_fecha_ven  = @i_fecha
and   op_toperacion = codigo
and   tabla         = 'T115'
order by op_cliente, op_toperacion

select operacion = op_operacion, fecha_pago = max(di_fecha_ven)
into #pago
from cob_cartera..ca_operacion, cob_cartera..ca_dividendo, #temporal 
where op_operacion  = di_operacion
and   di_estado     = 1
and   op_banco      = SCO_COMMENT
group by op_operacion

select banco = op_banco, fecha_pago
into #pagos
from #pago, cob_cartera..ca_operacion
where operacion = op_operacion

select operacion = op_operacion, valor_pago = sum(am_cuota - am_pagado)
into #cuota
from cob_cartera..ca_operacion, cob_cartera..ca_dividendo, cob_cartera..ca_amortizacion, #temporal 
where op_estado     in (1,2,4,9)
and   op_operacion  = di_operacion
and   di_estado     in (1, 2)
and   di_fecha_ven  <= @i_fecha
and   di_operacion  = am_operacion
and   di_dividendo  = am_dividendo
and   op_banco      = SCO_COMMENT
group by op_operacion

select banco = op_banco, valor_pago
into #cuotas
from #cuota, cob_cartera..ca_operacion
where operacion = op_operacion

--Actualizacion Valor mora y Dias de mora
update #temporal set 
V_MORA  = do_valor_mora,
D_MORA  = do_edad_mora
from cob_conta_super..sb_dato_operacion,#temporal
where SCO_COMMENT = do_banco

--Actualizacion de Fechas de Proceso
update #temporal set
DT_LAST_UPDATE  = convert(varchar(10), @i_fecha, 103),
SCO_DT_EXCHANGE = convert(varchar(10), @i_fecha, 103)

--Actualizacion Fecha de Proximo Pago
update #temporal set
SCO_DT_ACCRUED = convert(varchar(10), fecha_pago, 103)
from #pagos
where SCO_COMMENT = banco

--Actualizacion Valor Cuota Vigente
update #temporal set
SCO_VALUE = valor_pago
from #cuotas
where SCO_COMMENT = banco


-- Actualizar tipos de linea
                                                                                                                                                                                                                                  
select 
ID_DMD_COMPONENT, -- Tipo de Linea Cobis
STD_ID_HR,        -- Identificacion
SCO_COMMENT,      -- Numero Operacion (banco)
estado = 'I'
into #tipos_linea
from #temporal
order by STD_ID_HR, ID_DMD_COMPONENT

select @w_linea_cobis_ant    = '',
       @w_identificacion_ant = '',
       @w_contador           = 0
                                                                                                                                                                                                                                                             
while 1 = 1 begin
   set rowcount 1

   select 
   @w_linea_cobis    = ID_DMD_COMPONENT, -- Tipo de Linea Cobis
   @w_identificacion = STD_ID_HR,        -- Identificacion
   @w_banco          = SCO_COMMENT       -- Numero Operacion (banco)
   from #tipos_linea
   where estado = 'I'
   order by STD_ID_HR, ID_DMD_COMPONENT
                                                                                                                                                                                                                                                              
   if @@rowcount = 0 begin
      set rowcount 0
      break
   end 
                                                                                                                                                                                                                                                              
   if @w_linea_cobis_ant = @w_linea_cobis and @w_identificacion_ant = @w_identificacion begin 
      select @w_contador = @w_contador + 1
   end
                                                                                                                                                                                                                                                              
   if (@w_linea_cobis_ant <> @w_linea_cobis and @w_identificacion_ant <> @w_identificacion) or 
      (@w_linea_cobis_ant <> @w_linea_cobis and @w_identificacion_ant =  @w_identificacion) or
      (@w_linea_cobis_ant =  @w_linea_cobis and @w_identificacion_ant <> @w_identificacion)  
   begin 
      select @w_contador           = 1, 
             @w_linea_cobis_ant    = @w_linea_cobis,
             @w_identificacion_ant = @w_identificacion 
   end
                                                                                                                                                                                                                                                        
   update #temporal
   set ID_DMD_COMPONENT = descripcion_sib + convert(varchar,@w_contador)
   from cob_credito..cr_corresp_sib
   where SCO_COMMENT    = @w_banco
   and   @w_linea_cobis = codigo
   and   tabla = 'T115'

   update #tipos_linea
   set estado = 'P'
   where SCO_COMMENT = @w_banco

   set rowcount 0
end


insert into ca_reporte_temporal
select * from #temporal

select
@w_fecha_descuento   = DT_LAST_UPDATE,
@w_numero_registros  = count(1),
@w_total_descuentos  = sum(convert(money,SCO_VALUE))
from ca_reporte_temporal
group by DT_LAST_UPDATE

insert into ca_reporte_temporal_cifras
values (@w_fecha_descuento, @w_numero_registros, @w_total_descuentos)

----------------------------------------
--Generar Archivo de Cabeceras
----------------------------------------
select 
@w_col_id       = 0,
@w_columna      = '',
@w_cabecera     = '',
@w_nombre_cab   = @w_nombre

select 
@w_nombre_plano = @w_path + @w_nombre_cab + '.txt'

while 1 = 1 begin
   set rowcount 1
   select @w_columna = c.name,
          @w_col_id  = c.colid
   from sysobjects o, syscolumns c
   where o.id    = c.id
   and   o.name  = 'ca_reporte_temporal'
   and   c.colid > @w_col_id
   order by c.colid

   if @@rowcount = 0 begin
      set rowcount 0
      break
   end

   select @w_cabecera = @w_cabecera + @w_columna + '^|'  
end
set rowcount 0 

select @w_cabecera = left(@w_cabecera, datalength(@w_cabecera) - 1)

--Escribir Cabecera

select @w_cifras = @w_fecha_descuento + '^|' + convert(varchar,@w_numero_registros) + '^|' + convert(varchar,@w_total_descuentos) + ' > ' + @w_nombre_plano
select @w_comando = 'echo ' + @w_cifras  + ' > ' + @w_nombre_plano

exec @w_error = xp_cmdshell @w_comando

if @w_error <> 0 begin
   if exists(select 1 from cob_cartera..sysobjects where name = 'ca_reporte_temporal')
      drop table ca_reporte_temporal

    select @w_error = 2902797, @w_msg = 'EJECUCION Cifras FALLIDA. REVISAR ARCHIVOS DE LOG GENERADOS.'
    goto ERRORFIN
end

select @w_comando = 'echo ' + @w_cabecera + ' >> ' + @w_nombre_plano

exec @w_error = xp_cmdshell @w_comando

if @w_error <> 0 begin
   if exists(select 1 from cob_cartera..sysobjects where name = 'ca_reporte_temporal')
      drop table ca_reporte_temporal

    select @w_error = 2902797, @w_msg = 'EJECUCION Cabecera FALLIDA. REVISAR ARCHIVOS DE LOG GENERADOS.'
    goto ERRORFIN
end

--Ejecucion para Generar Archivo Datos

select @w_comando = @w_s_app + 's_app bcp -auto -login cob_cartera..ca_reporte_temporal out '

select 
@w_destino  = @w_path + 'ca_reporte_temporal.txt',
@w_errores  = @w_path + 'ca_reporte_temporal.err'

select @w_comando = @w_comando + @w_destino + ' -b5000 -c -e' + @w_errores + ' -t"|" ' + '-config '+ @w_s_app + 's_app.ini'

exec @w_error = xp_cmdshell @w_comando

if @w_error <> 0 begin

   if exists(select 1 from cobis..sysobjects where name = 'ca_reporte_temporal')
      drop table ca_reporte_temporal

    select @w_error = 2902797, @w_msg = 'EJECUCION comando bcp FALLIDA. (DATOS) REVISAR ARCHIVOS DE LOG GENERADOS (2).'
    goto ERRORFIN
end

----------------------------------------------------------------------
--Uni½n de archivo @w_nombre_plano con archivo ca_reporte_temporal.txt
----------------------------------------------------------------------

select @w_comando = 'copy ' + @w_nombre_plano + ' + ' + @w_path + 'ca_reporte_temporal.txt' + ' ' + @w_nombre_plano

select @w_comando

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   if exists(select 1 from cob_cartera..sysobjects where name = 'ca_reporte_temporal')
      drop table ca_reporte_temporal

   if exists(select 1 from cobis..sysobjects where name = 'ca_reporte_temporal_cifras')
      drop table ca_reporte_temporal_cifras

    select @w_error = 2902797, @w_msg = 'EJECUCION comando bcp FALLIDA. REVISAR ARCHIVOS DE LOG GENERADOS.'
    goto ERRORFIN
end

return 0

ERRORFIN: 

   select @w_mensaje = @w_sp_name + ' --> ' + @w_mensaje
   print @w_mensaje
   
   return 1

go
