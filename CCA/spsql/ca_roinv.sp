/*ca_roinv.sp************************************************************/
/*  Archivo:                         ca_roinv.sp                        */
/*  Stored procedure:                sp_reporte_roinvacatas             */
/*  Base de datos:                   cob_credito                        */
/*  Producto:                        Credito                            */
/*  Disenado por:                    Myriam Davila                      */
/*  Fecha de escritura:              27-Jul-1998                        */
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
/*  Este programa va a pasar la calificacion sugerida a la final de     */
/*  todas las operaciones que esten en la tabla de calificacion.        */
/*  Si existe el criterio de calificacion definitiva esta sera la       */
/*  calificacion final de la obligacion                                 */
/*									*/
/************************************************************************/
/*              MODIFICACIONES                                          */
/*  FECHA       AUTOR                   RAZON                           */
/*  22/Jun/11   Alfredo Zuluaga         Emision Inicial                 */
/*  08/May/14   Luis Moreno             CCA 406 SEGDEUEM                */
/************************************************************************/

use cob_cartera
go

if exists(select 1 from cob_cartera..sysobjects where name = 'ca_reporte_temporal1')
   drop table ca_reporte_temporal1

if exists (select 1 from sysobjects where name = 'sp_reporte_roinvacatas')
   drop proc sp_reporte_roinvacatas
go

create proc sp_reporte_roinvacatas(
@i_param1           varchar(255),
@i_param2           varchar(255),
@i_param3           varchar(255)
)
as

declare 
@i_fecha_ini         datetime,
@i_fecha_fin         datetime,
@i_toperacion        varchar(30),
@w_usuario           login,
@w_sp_name           varchar(30),
@w_error             int,
@w_msg               varchar(255),
@w_s_app             varchar(50),
@w_path              varchar(50),
@w_nombre            varchar(14),
@w_nombre_cab        varchar(18),
@w_cmd               varchar(255),
@w_destino           varchar(2500),
@w_errores           varchar(1500),
@w_comando           varchar(2500),
@w_nombre_plano      varchar(1500),
@w_col_id            int,
@w_columna           varchar(30),
@w_cabecera          varchar(2500)


select 
@i_fecha_ini    = convert(datetime, @i_param1),
@i_fecha_fin    = convert(datetime, @i_param2),
@i_toperacion   = @i_param3,
@w_usuario      = 'crebatch',
@w_sp_name      = 'sp_reporte_roinvacatas'       

select @w_s_app = pa_char
from cobis..cl_parametro
where pa_producto = 'ADM'
and   pa_nemonico = 'S_APP'

select @w_path = ba_path_destino
from cobis..ba_batch
where ba_batch = 7008

if exists(select 1 from cob_cartera..sysobjects where name = 'ca_reporte_temporal1')
   drop table ca_reporte_temporal1

create table ca_reporte_temporal1 (
tipo_operacion          varchar(24)     null,
fecha_concesion         datetime        null,
nombre                  varchar(255)    null,
tipo_ced                varchar(2)      null,
cedula                  varchar(24)     null,
banco                   varchar(24)     null,
oficina                 int             null,
fecha_prox              datetime        null,
saldo_int               money           null,
saldo_segvida           money           null,
plazo                   int             null,
periodicidad            int             null,
numcuota                int             null,
numpercap               int             null
)

select 
tipo_operacion  = do_tipo_operacion,
fecha_concesion = do_fecha_concesion,
nombre          = en_nomlar,
tipo_ced        = en_tipo_ced,
cedula          = en_ced_ruc,
banco           = do_banco,
oficina         = do_oficina,
fecha_prox      = do_fecha_prox_vto,
saldo_int       = convert(money,0),
saldo_segvida   = convert(money,0),
plazo           = do_plazo_dias,
periodicidad    = do_periodicidad_cuota,
numcuota        = convert(int,0),
numpercap       = convert(int,0)
into #temporal
from cob_conta_super..sb_dato_operacion with(nolock), cobis..cl_ente with (nolock)
where do_fecha           = @i_fecha_fin
and   do_fecha_concesion >= @i_fecha_ini
and   do_fecha_concesion <= @i_fecha_fin
and   do_tipo_operacion  = @i_toperacion
and   do_codigo_cliente  = en_ente

select di_operacion = op_operacion, di_banco = op_banco, di_dividendo, op_gracia_cap
into #cartera
from cob_cartera..ca_operacion, #temporal, cob_cartera..ca_dividendo
where op_banco     = banco
and   op_operacion = di_operacion
and   di_fecha_ven = fecha_prox
and   di_estado    = 1

update #temporal set
numcuota  = di_dividendo,
numpercap = op_gracia_cap
from #cartera
where banco = di_banco

select op_banco, am_cuota 
into #amortiza_int
from cob_cartera..ca_amortizacion, #temporal, cob_cartera..ca_operacion, #cartera
where op_banco     = banco
and   op_operacion = am_operacion
and   am_operacion = di_operacion
and   am_dividendo = di_dividendo
and   am_concepto  = 'INT'

select op_banco, am_cuota 
into #amortiza_vida
from cob_cartera..ca_amortizacion, #temporal, cob_cartera..ca_operacion, #cartera
where op_banco     = banco
and   op_operacion = am_operacion
and   am_operacion = di_operacion
and   am_dividendo = di_dividendo
and   am_concepto  in ('SEGDEUVEN','SEGDEUEM')

update #temporal set
saldo_int = am_cuota
from #amortiza_int
where op_banco = banco

update #temporal set
saldo_segvida = am_cuota
from #amortiza_vida
where op_banco = banco


insert into ca_reporte_temporal1
select * from #temporal

----------------------------------------
--Generar Archivo de Cabeceras
----------------------------------------
select @w_nombre = 'ROINVCATAS'

select 
@w_col_id       = 0,
@w_columna      = '',
@w_cabecera     = convert(varchar(2000), ''),
@w_nombre_cab   = @w_nombre + '_CAB'

select 
@w_nombre_plano = @w_path + @w_nombre_cab + '_' + convert(varchar(2), datepart(dd,@i_fecha_fin)) + '_' + convert(varchar(2), datepart(mm,@i_fecha_fin)) + '_' + convert(varchar(4), datepart(yyyy, @i_fecha_fin)) + '.txt'

while 1 = 1 begin
   set rowcount 1
   select @w_columna = c.name,
          @w_col_id  = c.colid
   from sysobjects o, syscolumns c
   where o.id    = c.id
   and   o.name  = 'ca_reporte_temporal1'
   and   c.colid > @w_col_id
   order by c.colid

   if @@rowcount = 0 begin
      set rowcount 0
      break
   end

   select @w_cabecera = @w_cabecera + @w_columna + '^|'
end

select @w_cabecera = left(@w_cabecera, datalength(@w_cabecera) - 2)

--Escribir Cabecera
select @w_comando = 'echo ' + @w_cabecera + ' > ' + @w_nombre_plano

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    select @w_error = 1, @w_msg = 'EJECUCION comando bcp FALLIDA. REVISAR ARCHIVOS DE LOG GENERADOS.'
    goto ERRORFIN
end

--Ejecucion para Generar Archivo Datos

select @w_comando = @w_s_app + 's_app bcp -auto -login cob_cartera..ca_reporte_temporal1 out '

select 
@w_destino  = @w_path + 'ca_reporte_temporal1.txt',
@w_errores  = @w_path + 'ca_reporte_temporal1.err'

select
@w_comando = @w_comando + @w_destino + ' -b5000 -c -e' + @w_errores + ' -t"|" ' + '-config '+ @w_s_app + 's_app.ini'

exec @w_error = xp_cmdshell @w_comando

if @w_error <> 0 begin
   print 'Error Generando Archivo ca_reporte_temporal1 '
   return @w_error
end


----------------------------------------
--Uni«n de archivo @w_nombre_plano con archivo ca_reporte_temporal1.txt
----------------------------------------

select @w_comando = 'copy ' + @w_nombre_plano + ' + ' + @w_path + 'ca_reporte_temporal1.txt' + ' ' + @w_nombre_plano

select @w_comando

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    select @w_error = 1, @w_msg = 'EJECUCION comando bcp FALLIDA. REVISAR ARCHIVOS DE LOG GENERADOS.'
    goto ERRORFIN
end


if exists(select 1 from cob_cartera..sysobjects where name = 'ca_reporte_temporal1')
   drop table ca_reporte_temporal1


return 0

ERRORFIN:

if exists(select 1 from cobis..sysobjects where name = 'ca_reporte_temporal1')
   drop table ca_reporte_temporal1

print @w_msg
return 1

go


/*

exec sp_reporte_roinvacatas
@i_param1 = '01/01/2008',
@i_param2 = '07/30/2011',
@i_param3 = 'SINCO'

select max(do_fecha) from cob_conta_super..sb_dato_operacion

select do_tipo_operacion, count(1) from cob_conta_super..sb_dato_operacion
where do_fecha = '07/30/2011'
group by do_tipo_operacion

*/