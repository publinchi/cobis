/************************************************************************/
/*   Stored procedure:     sp_reporte_pagos_reest                       */
/*   Base de datos:        cob_cartera                                  */
/************************************************************************/
/*                                  IMPORTANTE                          */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                            PROPOSITO                                 */
/************************************************************************/
 
use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_reporte_pagos_reest')
   drop proc sp_reporte_pagos_reest
go

create proc sp_reporte_pagos_reest(   
   @i_param1            datetime,    -- Fecha Inicio reestructuración
   @i_param2            datetime,     -- Fecha Inicio   
   @i_param3            datetime     -- Fecha Fin   
)

as                         
declare
   @w_sp_name            varchar(32),   
   @i_fecha_ini_rees     datetime,
   @i_fecha_ini          datetime,
   @i_fecha_fin          datetime,
   
--variable para bcp
   @w_path_destino      varchar(100),
   @w_s_app             varchar(50),
   @w_cmd               varchar(255),   
   @w_comando           varchar(255),
   @w_mensaje           varchar(500),
   @w_nombre_archivo    varchar(255),
   @w_error             int,
--variables de trabajao
   @w_anio              varchar(4),
   @w_mes               varchar(2),
   @w_dia               varchar(2),
   @w_cabecera          varchar(255)
   

set ansi_warnings off   

select @w_sp_name           = 'sp_reporte_pagos_reest',       
       @i_fecha_ini_rees    = @i_param1,
       @i_fecha_ini         = @i_param2,
       @i_fecha_fin         = @i_param3

/****VALIDAR QUE LA FECHA INICIO DE PAGO SEA MAYOR A LA FECHA FIN DE PAGO***/
if @i_fecha_ini > @i_fecha_fin begin
   select  @w_mensaje    = 'Fecha Inicio de Pagos es superior a la Fecha Fin'
   select  @w_mensaje
   select  @w_error      = 101
   goto ERROR
end

       
/****VALIDAR QUE EL RANGO DE FECHAS NO SUPERE 31 DIAS ***/
if datediff(dd, @i_fecha_ini, @i_fecha_fin) > 30 begin
   select  @w_mensaje    = 'Número de días a consultar supera los 30 dias'
   select  @w_mensaje
   select  @w_error  = 100
   goto ERROR
end

if @i_fecha_ini_rees > @i_fecha_ini begin
   select  @w_mensaje    = 'Fecha Inicio de Pagos es superior a la Fecha Inicio de las Reestructuraciones'
   select  @w_mensaje
   select  @w_error  = 101
   goto ERROR
end

/******INICIALIZA TABLA ****/   
truncate table ca_rep_pagos_reest

---> FORMATEO DE FECHA
   select @w_anio    = datepart(yy, @i_fecha_fin)                                                                                                                                                                                                                 
   select @w_mes     = datepart(mm, @i_fecha_fin)                                                                                                                                                                                                               
   select @w_dia     = datepart(dd, @i_fecha_fin)

/***************PROCESANDO PAGOS DE REESTRUCTURACIONES ***********/

select 'secuencial' = tr_secuencial,'fecha_mov' = tr_fecha_ref,op_operacion,op_banco,op_cliente,op_toperacion,op_oficina       
into #ope_reest
from cob_cartera..ca_transaccion (nolock),
     cob_cartera..ca_operacion (nolock)       
where tr_tran       =  'RES'
and   tr_estado     <>  'RV'
and   tr_secuencial > 0
and   tr_fecha_mov  >= @i_fecha_ini_rees 
and   tr_operacion  = op_operacion
if @@rowcount = 0 Begin
   select  @w_mensaje    = 'NO EXISTEN REESTRUCTURACIONES PARA LA FECHA INGRESADA'
   return 0
End 


/***EXTRAER LOS PAGOS REALIZADOS A LAS OPERACIONES REESTRUCTURADAS ***/
select 'fecha_pag'= tr_fecha_ref ,'sec_pag' = tr_secuencial,op_operacion,
       op_banco,op_cliente,op_toperacion,op_oficina,'valor_pag' = convert(money,0)     
into #ope_pag
from cob_cartera..ca_transaccion (nolock),
     #ope_reest   
where tr_tran       =  'PAG'
and   tr_estado     <>  'RV'
and   tr_secuencial > 0
and   tr_fecha_mov >= @i_fecha_ini 
and   tr_fecha_mov <= @i_fecha_fin
and   tr_operacion  = op_operacion
if @@rowcount = 0 Begin
   select  @w_mensaje    = 'NO EXISTEN PAGOS PARA OBLIGACIONES REESTRUCTURACIONES PARA LA FECHAS INGRESADO'    
   return 0
End 

/*****ACTUALIZAR EL VALOR DEL PAGO ***/
select ab_operacion,ab_secuencial_pag,
       'abd_monto_mn' = sum(abd_monto_mn)
into #total_pag
from #ope_pag,
     cob_cartera..ca_abono,
     cob_cartera..ca_abono_det
where ab_operacion      = op_operacion 
and   ab_secuencial_pag = sec_pag
and   abd_operacion     = ab_operacion
and   ab_secuencial_ing = abd_secuencial_ing
and   ab_estado        <>  'RV'
group by ab_operacion,ab_secuencial_pag

update #ope_pag set 
valor_pag  = abd_monto_mn
from #ope_pag,
     #total_pag
where ab_operacion      = op_operacion 
and   ab_secuencial_pag = sec_pag


/***EXTRAER DETALLE DE LOS PAGOS REALIZADOS A LAS OPERACIONES REESTRUCTURADAS ***/
select fecha_pag,sec_pag,op_operacion,op_banco,op_cliente,op_toperacion,
       op_oficina ,dtr_concepto,dtr_estado,dtr_monto_mn,valor_pag
into #detalle_pag
from #ope_pag,
     cob_cartera..ca_det_trn
where dtr_secuencial = sec_pag
and   dtr_operacion  = op_operacion
and   dtr_concepto  <> 'VAC0'

insert into ca_rep_pagos_reest(
rp_fecha_pag    ,rp_nombre_cli  ,rp_tipo_ide  ,
rp_numero_ide   ,rp_obligacion  ,rp_toperacion,
rp_oficina      ,rp_valor_pag   ,rp_conceptos ,
rp_estado_concepto,rp_valor_concepto)
select fecha_pag,(select en_nomlar from cobis..cl_ente where en_ente = pg.op_cliente),(select en_tipo_ced from cobis..cl_ente where en_ente = pg.op_cliente),
(select en_ced_ruc from cobis..cl_ente where en_ente = pg.op_cliente),op_banco,op_toperacion,
op_oficina,valor_pag,dtr_concepto,
(select es_descripcion from ca_estado where es_codigo = pg.dtr_estado),
dtr_monto_mn
from #detalle_pag pg

/****GENERACION DE BCP ****/
---> PATH DESTINO ARCHIVO 
Select @w_path_destino = ba_path_destino
from cobis..ba_batch
where ba_batch = 7113
if @@rowcount = 0 Begin
   select  @w_mensaje    = 'NO EXISTE RUTA DE LISTADOS PARA EL BATCH 7113'
   select  @w_error  = 105
   goto ERROR
End 

---> FORMATEO DE S_APP
select @w_s_app = pa_char
from cobis..cl_parametro
where pa_producto = 'ADM'
and   pa_nemonico = 'S_APP'
if @@rowcount = 0 Begin
   select  @w_mensaje    = 'NO EXISTE RUTA DEL S_APP'
   select  @w_error  = 106
   goto ERROR
End 

/************GENERANDO ARCHIVO PLANO ***/
if exists (select 1 from sysobjects where name = 'tmp_archivo')
   drop table tmp_archivo

create table tmp_archivo(
registro     varchar(700))

select @w_cabecera = 'Fecha_pago|Nombre_cliente|Tipo_IDE|Numero_IDE|Obligacion|Tipo_producto|Oficina|Valor_Pago|Concepto|Estado_concepto|Valor_concepto'

/********** INSERTANDO DETALLE DEL ARCHIVO ***/
insert into tmp_archivo(registro)
values (@w_cabecera)

insert into tmp_archivo(registro)
select convert(varchar(10),rp_fecha_pag,103) + '|' + rp_nombre_cli + '|' + rp_tipo_ide + '|' + rp_numero_ide  
         + '|' + rp_obligacion + '|' + rp_toperacion + '|' + cast(rp_oficina as varchar) + '|' + cast(rp_valor_pag  as varchar) + '|' + rp_conceptos 
         + '|' + rp_estado_concepto + '|' + cast(rp_valor_concepto as varchar)
from ca_rep_pagos_reest
order by rp_fecha_pag,rp_obligacion
if @@rowcount = 0 begin 
   select  @w_mensaje    = 'No Existen Datos para Generar Detalle' 
   return 0
end 


--*******************************************--
print '---> GENERAR BCP'
--*******************************************--
select @w_nombre_archivo = @w_path_destino + 'PAGOSREES_' + @w_mes + @w_dia + @w_anio + '.txt'

select @w_cmd     = @w_s_app + 's_app bcp -auto -login cob_cartera..tmp_archivo out ' 
select @w_comando = @w_cmd + @w_nombre_archivo + ' -b5000 -c -e' + 'PAGOSREES.err' + ' -config '+ @w_s_app + 's_app.ini'
exec @w_error = xp_cmdshell @w_comando

if @w_error != 0 begin
   select  @w_mensaje    = 'ERROR GENERANDO BCP ' + @w_comando
   select  @w_error  = 107
   goto ERROR 
End

return 0

ERROR:

exec sp_errorlog 
@i_fecha     = @i_fecha_fin,
@i_error     = @w_error, 
@i_usuario   = 'sa', 
@i_tran      = 7999,
@i_tran_name = @w_sp_name,
@i_cuenta    = 'PAGOSREES',
@i_anexo     = @w_mensaje,
@i_rollback  = 'S'

return @w_error

go


