/*****************************************************************************/
/*  ARCHIVO:         carep444.sp                                             */
/*  NOMBRE LOGICO:   sp_reporte_for444                                       */
/*  PRODUCTO:        Cartera                                                 */
/*****************************************************************************/
/*                            IMPORTANTE                                     */
/* Esta aplicacion es parte de los paquetes bancarios propiedad de COBISCorp */
/* Su uso no autorizado queda  expresamente  prohibido asi como cualquier    */
/* alteracion o agregado hecho  por alguno de sus usuarios sin el debido     */
/* consentimiento por escrito de COBISCorp. Este programa esta protegido por */
/* la ley de derechos de autor y por las convenciones internacionales de     */
/* propiedad intelectual.  Su uso  no  autorizado dara derecho a COBISCORP   */
/* para obtener ordenes  de secuestro o  retencion  y  para  perseguir       */
/* penalmente a  los autores de cualquier infraccion.                        */
/*****************************************************************************/
/*                               PROPOSITO                                   */
/* Reporte de Pagos para la revisión del formato 444.                        */
/*****************************************************************************/
use cob_cartera
go

if exists ( select name from sysobjects where type = 'P' and name = 'sp_reporte_for444')
   drop proc sp_reporte_for444
go

create proc sp_reporte_for444(
   @i_param1          datetime,   -- Fecha Inicio
   @i_param2          datetime    -- Fecha Fin
)
as

declare
  @i_fecha_ini         datetime,
  @i_fecha_fin         datetime,

  @w_error               int,
  @w_msg                 descripcion,
  @w_fecha_proc          datetime,
  @w_fecha_ini           datetime,
  @w_ciudad              int,
  @w_sig_habil           datetime,
  @w_fin_mes             char(1),
  @w_sp_name             varchar(155),
  @w_proceso             int,
  @w_fecha_fin           varchar(10),
 
--variables para bcp   
  @w_path_destino        Varchar(100),
  @w_s_app               Varchar(50),
  @w_cmd                 Varchar(255),   
  @w_comando             Varchar(255),
  @w_nombre_archivo      Varchar(255),  
  @w_anio                varchar(4),
  @w_mes                 varchar(2),
  @w_dia                 varchar(2)

select @w_sp_name      = 'sp_reporte_for444',
       @w_proceso      = 7115,       
       @i_fecha_ini    = @i_param1,
       @i_fecha_fin    = @i_param2

--ELIMINAR TABLAS TEMPORALES
if exists(select 1 from sysobjects where name = 'tmp_transacciones')
   drop table tmp_transacciones

if exists(select 1 from sysobjects where name = 'tmp_plano_car')
   drop table tmp_plano_car

create table tmp_plano_car (orden int not null, cadena varchar(2000) not null)

--EXTRAER DATOS DE TRANSACCIONES

select tr_secuencial,tr_estado,tr_operacion
into #trans
from ca_transaccion     
where tr_tran       = 'RPA'
and   tr_estado in ('CON')
and   tr_secuencial > 0
and   tr_fecha_mov  >= @i_fecha_ini
and   tr_fecha_mov  <= @i_fecha_fin

insert into #trans
select tr_secuencial,'RV',tr_operacion
from ca_transaccion     
where tr_tran       = 'RPA'
and   tr_estado in ('CON')
and   tr_secuencial < 0
and   tr_fecha_mov  >= @i_fecha_ini
and   tr_fecha_mov  <= @i_fecha_fin

select 
'Mes'           = DATENAME (month, @i_fecha_fin),
'Producto'      = '7',
'Trans'         = 'PAG',
'Cod_forma_pag' = dtr_concepto,
'Des_forma_pag' = (select cp_descripcion from cob_cartera..ca_producto where cp_producto = dt.dtr_concepto ),
'Num_registro'  = count(1),
'Valor'         = sum(dtr_monto),
'Estado'        = case tr_estado when 'RV' then 'R' else 'A' end
into tmp_transacciones
from ca_det_trn dt,
     #trans          
where dtr_operacion = tr_operacion
and   tr_secuencial = dtr_secuencial
and   dtr_dividendo <> 0
group by dtr_concepto,tr_estado
if @@rowcount = 0 begin
   select 
   @w_error = 724504, 
   @w_msg = 'No existen datos para la Fecha : ' + cast(@i_fecha_fin as varchar)   
   return 0
end

select @w_anio = convert(varchar(4),datepart(yyyy,@i_fecha_fin)),
       @w_mes = convert(varchar(2),datepart(mm,@i_fecha_fin)), 
       @w_dia = convert(varchar(2),datepart(dd,@i_fecha_fin))  

select @w_fecha_fin  = (@w_anio + right('00' + @w_mes,2) + right('00'+ @w_dia,2))

/* GENERACION ARCHIVO PLANO */
Print '--> Path Archivo Resultante'

Select @w_path_destino = ba_path_destino
from cobis..ba_batch
where ba_batch = @w_proceso
if @@rowcount = 0 Begin
   select
   @w_error = 720004,
   @w_msg = 'No Existe path_destino para el proceso : ' +  cast(@w_proceso as varchar)
   GOTO ERROR
End 

select @w_s_app = pa_char
from cobis..cl_parametro
where pa_producto = 'ADM'
and   pa_nemonico = 'S_APP'
if @@rowcount = 0 Begin
      select
   @w_error = 720014,
   @w_msg = 'NO EXISTE RUTA DEL S_APP'
   GOTO ERROR   
End 

-- Arma Nombre del Archivo
print 'Generar el archivo plano TRANS_CARTERA_AAAAMMDD.txt !!!!! ' 
insert into tmp_plano_car (orden, cadena) values (0,'Mes | Producto | Tipo_Tran | Codigo_Tran | Descrip_Tran | Num_registros | Valor |Estado')


insert into tmp_plano_car (orden, cadena)
select
row_number() over (order by Trans),
Mes  +      
'|' + Producto +
'|' + Trans +
'|' + Cod_forma_pag +
'|' + Des_forma_pag +
'|' + convert(varchar,Num_registro) +
'|' + convert(varchar,Valor) +
'|' + Estado
from tmp_transacciones
order by Trans

select @w_nombre_archivo = @w_path_destino + 'TRANS_CARTERA_' + @w_fecha_fin + '.txt' 
Print @w_nombre_archivo

select @w_cmd       =  'bcp "select cadena from cob_cartera..tmp_plano_car order by orden " queryout ' 
select @w_comando   = @w_cmd + @w_nombre_archivo + ' -b5000 -c -t"|" -T -S'+ @@servername + ' -eFNG.err' 
PRINT @w_comando
exec @w_error = xp_cmdshell @w_comando

If @w_error <> 0 Begin
   select @w_msg = 'Error Generando BCP' + @w_comando
   Goto ERROR 
End   

return 0

ERROR:

exec sp_errorlog 
@i_fecha     = @i_fecha_fin,
@i_error     = @w_error, 
@i_usuario   = 'sa', 
@i_tran      = 7999,
@i_tran_name = @w_sp_name,
@i_cuenta    = 'Masivo',
@i_anexo     = @w_msg,
@i_rollback  = 'S'

return @w_error

go