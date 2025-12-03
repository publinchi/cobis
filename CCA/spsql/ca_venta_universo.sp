/************************************************************************/
/*      Archivo:                ca_venta_universo.sp                    */
/*      Stored procedure:       sp_venta_universo                       */
/*      Base de datos:          cob_conta_super                         */
/*      Producto:               Cartera                                 */
/*      Fecha de escritura:     Noviembre 2013                          */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'                                                        */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/* Crea universo de operaciones castigadas para venta de cartera        */ 
/*                                                                      */
/************************************************************************/
/*                              CAMBIOS                                 */
/*  FECHA     AUTOR             RAZON                                   */
/*  21-11-13  L.Guzman          Emisión Inicial - Req: Venta Cartera    */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_venta_universo')
   drop proc sp_venta_universo
go

create proc sp_venta_universo
@i_param1   varchar(255),
@i_param2   char(1)  ------- (A)-Carga Venta desde Archivi  - (U)-Carga un universo propio  (No peude ser null)

as
declare
@w_fecha_corte   datetime,
@w_sp_name       varchar(32),
@w_error         int,
@w_msg           varchar(255),
@w_fecha_proceso datetime,
@w_tipo_proceso  char(1),
@w_path          varchar(255),
@w_comando       varchar(1000),
@w_s_app         varchar(255),
@w_errores       varchar(255)

set nocount on

select @w_sp_name   = 'sp_venta_universo'

select @w_fecha_corte = @i_param1

select @w_tipo_proceso = @i_param2

if @w_fecha_corte is null
begin
  select @w_msg = 'Error, no se encuentra la fecha de ejecucion',
         @w_error = 801085
  goto ERROR
end

-- OBTIENE FECHA DE PROCESO
select @w_fecha_proceso = fc_fecha_cierre 
from cobis..ba_fecha_cierre
where fc_producto = 7

if @@rowcount = 0
begin
   select @w_msg = 'Error al leer fecha de proceso de cartera',
          @w_error = 801085
   goto ERROR
end

/*********OBTIENE LA RUTA DONDE SE CARGA EL ARCHIVO PLANO********/
select @w_path =pp_path_destino
from   cobis..ba_path_pro
where  pp_producto = 7
if @@rowcount = 0
begin
   select @w_error = 103115,
   @w_msg = 'NO SE ENCONTRO LA RUTA DONDE SE CARGA EL ARCHIVO PLANO. '
   goto ERROR
end

select @w_s_app = pa_char
from cobis..cl_parametro
where pa_producto = 'ADM'
and   pa_nemonico = 'S_APP'
if @@rowcount = 0
begin
   select @w_error = 103115,
   @w_msg = 'NO SE ENCONTRO LA RUTA DE S_APP '
   goto ERROR
end

select @w_errores  = @w_path + 'venta_archivo.err'

if @w_tipo_proceso = 'A' 
begin
   -- Realizar carga de operaciones desde archivo plano a tabla temporal 
   -- El banco deberá entregar un archivo plano con estructura de un solo campo

   if not exists (select 1 from sysobjects where name = 'venta_archivo' and type = 'U') begin
      create table venta_archivo (obligacion varchar(20))
   end

   -- Desarrollar seccion de 'BCP in' para leer archivo plano 'Venta_Cartera.txt ' y cargar a la tabla temporal venta_archivo 
   truncate table venta_archivo

   select @w_comando  = @w_s_app + 's_app bcp cob_cartera..venta_archivo in '
   select @w_comando  = @w_comando + @w_path + 'Venta_Cartera.txt  -b5000 -c -e' + @w_errores + ' -auto -login ' + '-config ' + @w_s_app + 's_app.ini'

   select @w_error = 0
   
   exec @w_error = xp_cmdshell @w_comando
   if @w_error <> 0 begin
      print 'Error cargando Archivo: ' 
      print @w_comando
   end
end

create table #Discr (ult_fecha datetime, banco varchar(24), codigo_cliente int)

if @w_tipo_proceso = 'A' begin  -- Venta por medio de archivo plano
   insert into #Discr
   select MAX(do_fecha),
          do_banco,
          do_codigo_cliente
   from cob_conta_super..sb_dato_operacion with(nolock), cob_cartera..ca_operacion with(nolock), venta_archivo
   where do_estado_cartera = 4
   and   do_aplicativo     = 7
   and   do_fecha_castigo <= @w_fecha_corte
   and   do_estado_cartera = op_estado
   and   do_banco          = op_banco
   and   do_banco          = obligacion --> Tamado desde el archivo plano
   group by do_banco,do_codigo_cliente 

   if @@rowcount = 0
   begin
      select @w_msg = 'Error al leer operaciones castigadas desde archivo',
             @w_error = 708154
      goto ERROR
   end
end 
else begin                  -- Venta por medio por universo generado
   insert into #Discr
   select MAX(do_fecha),
          do_banco,
          do_codigo_cliente
   from cob_conta_super..sb_dato_operacion   with(nolock), cob_cartera..ca_operacion  with(nolock)
   where do_estado_cartera = 4
   and   do_aplicativo     = 7
   and   do_fecha_castigo <= @w_fecha_corte
   and   do_estado_cartera = op_estado
   and   do_banco          = op_banco
   group by do_banco,do_codigo_cliente 

   if @@rowcount = 0
   begin
      select @w_msg = 'Error al leer operaciones castigadas',
             @w_error = 708154
      goto ERROR
   end
   
end

create unique index idx1 on #Discr(banco, codigo_cliente)

if @w_tipo_proceso = 'U' begin -- Venta por medio por universo generado
   delete #Discr
   from  cob_cartera..ca_operacion_alterna, #Discr, cob_cartera..ca_operacion
   where oa_operacion_original = op_operacion 
   and   op_banco              = banco
   and   oa_operacion_alterna in
   (
   select op_operacion from #Discr, cob_cartera..ca_operacion
   where op_banco = banco
   and   op_toperacion = 'ALT_FNG'
   )

   if @@error <> 0
   begin
      select @w_msg   = 'Error al eliminar operaciones ALT_FNG desde ca_operacion_alterna',
             @w_error = 708155
      goto ERROR
   end

   delete #Discr
   from #Discr, cob_cartera..ca_operacion
   where op_banco = banco
   and   op_toperacion = 'ALT_FNG'

   if @@error <> 0
   begin
      select @w_msg   = 'Error al eliminar operaciones ALT_FNG desde ca_operacion',
             @w_error = 708155
      goto ERROR
   end
end

select
'Id_cliente'             = en_ced_ruc,
'Nombre_Cliente'         = en_nomlar,
'Tipo_Identificacion'    = en_tipo_ced,
'Segmento'               = (select valor from cobis..cl_catalogo where codigo = mo_segmento and tabla = 2523),
'Ciudad_Desembolso'      = (select valor from cobis..cl_catalogo where codigo = of_ciudad and tabla = 14),
'Tipo_Producto'          = op_toperacion, --Tipo de Producto (Libre inversión, tarjeta de crédito, sobregiro, libranza, etc)
'Saldo_capital'          = do_saldo_cap,
'Intereses'              = (do_saldo_int + do_saldo_int_contingente),
'Otros_cargos'           = do_saldo_otros,
'Saldo_deuda_total'      = do_saldo,
'Saldo_Mora'             = isnull(do_saldo_total_Vencido,0),
'Fecha_desembolso'       = convert(varchar(10),do_fecha_concesion,103),
'Valor_desembolso'       = do_monto,
'Plazo_credito'          = do_num_cuotas,
'Fecha_Mora'             = convert(varchar(10),GETDATE(),103),
'Fecha_Castigo'          = convert(varchar(10),do_fecha_castigo,103),
'Edad_Mora'              = 0,                                 -- REPORTE CENTRALES DE RIESGO
'Numero_Obli_o_Crd'      = do_banco,
'Existencia_acuerdo_pag' = do_reestructuracion,
'Estado_Cobranza'        = (select top 1 valor from cobis..cl_catalogo where codigo = do_estado_cobranza and tabla = 374),
'Ciudad_Cred'            = (select top 1 valor from cobis..cl_catalogo where codigo = of_ciudad and tabla = 14),
'Valor_pagado'           = CONVERT(money,0),--Valores cancelados a la obligación en los últimos 12 meses ( incluyendo el desglose por rubro como se muestra en las otras variables. )
'Fecha_Ult_pago'         = convert(varchar(10),do_fecha_ult_pago,103),--Fecha pago: Fechas pagos últimos 12 meses
'Capital_Pagado'         = (do_monto - do_saldo_cap),-- pagado - acumulado)
'Intereses_pagados'      = CONVERT(money,0),
'Otros_concep_pag'       = do_saldo_otros,--do_saldo_otr,
'Direccion_Cliente'      = (select top 1 di_descripcion from cobis..cl_direccion where di_principal = 'S' and di_ente = en_ente),
'Ciudad'                 = (select top 1 valor from cobis..cl_catalogo where codigo = of_ciudad and tabla = 14),
'Telefono'               = (select top 1 te_prefijo + te_valor from cobis..cl_telefono where te_ente = en_ente),
'Fecha_Nacimiento'       = convert(varchar(10),p_fecha_nac,103),
'Ingresos'               = p_nivel_ing,
'Egresos'                = p_nivel_egr,
'Estrato'                = en_estrato,
'Nivel_Estudio'          = (select top 1 valor from cobis..cl_catalogo where codigo = p_nivel_estudio and tabla = 2194),
'Profesion'              = (select top 1 valor from cobis..cl_catalogo where codigo = p_profesion and tabla = 2193),
'Nota_Interna_Bmia'      = (select top 1 ci_nota from cob_credito..cr_califica_int_mod where ci_cliente = op_cliente),
'Calificacion_Op'        = isnull(op_calificacion,'A'),                     -- REPORTE CENTRALES DE RIESGO
'operacion_interna'      = op_operacion,
'Banca'                  = op_banca,
'Oficina'                = op_oficina,
'Cod_CIIU'               = en_actividad,                                    -- REPORTES REC
'Fecha_Venta'            = GETDATE(),
'Secuencial_Ing_Ven'     = 0,                                               -- se actualiza con el proceso sp_venta_pago
'Secuencial_Ing_Vig'     = 0,                                               -- se actualiza con el proceso sp_venta_pago
'Secuencial_Ing_Nvig'    = 0,                                               -- se actualiza con el proceso sp_venta_pago
'Estado_Venta'           = convert(char(1),'I')                             -- se actualiza con el proceso sp_venta_pago
into #universo
from cob_conta_super..sb_dato_operacion with(nolock),cobis..cl_oficina with(nolock),
   cob_cartera..ca_operacion with(nolock),cobis..cl_producto with(nolock), cobis..cl_ente with(nolock),
   cobis..cl_mercado_objetivo_cliente with(nolock),#Discr D
where do_banco          = op_banco
and   op_banco          = banco
and   ult_fecha         = do_fecha
and   en_ente           = codigo_cliente
and   do_codigo_cliente = codigo_cliente
and   do_codigo_cliente = en_ente
and   do_codigo_cliente = op_cliente
and   do_codigo_cliente = mo_ente
and   en_ente           = mo_ente
and   do_estado_cartera = 4
and   do_oficina        = of_oficina       
and   do_aplicativo     = 7
and   do_aplicativo     = pd_producto 

if @@rowcount = 0
begin
   select @w_msg = 'Error al crear universo de operaciones castigadas',
          @w_error = 708154
   goto ERROR
end

create unique index idx1 on #universo(operacion_interna)
drop table #Discr

-- crear tabla ca_venta_universo
if not exists (select 1 from sysobjects where name = 'ca_venta_universo')
   select * into cob_cartera..ca_venta_universo from #universo where 1 = 2

--intereses pagados
select 
'vpagado'    = sum(am_pagado),
'operacion'  = operacion_interna
into #uno
from cob_cartera..ca_amortizacion with(nolock),cob_cartera..ca_dividendo with(nolock),#universo
where di_operacion = operacion_interna
and   di_operacion = am_operacion
and   di_dividendo = am_dividendo
and   di_estado     = 3
and   am_estado     = 3
and   am_concepto   = 'INT'
and   am_operacion  = operacion_interna
group by operacion_interna

if @@error <> 0
begin
   select @w_msg = 'Error al crear tabla de intereses pagados',
          @w_error = 708154
   goto ERROR
end

create unique index idx1 on #uno(operacion)

update #universo set 
Intereses_pagados = vpagado
from #uno 
where operacion_interna = operacion

if @@error <> 0
begin
   select @w_msg = 'Error al actualizar registros tabla #universo interes pagado',
          @w_error = 708152
   goto ERROR
end

drop table #uno

--int  valor pagado
select 
'VpagadoT'  = SUM(am_pagado),
'operacion' = operacion_interna
into #dos
from cob_cartera..ca_amortizacion with(nolock),cob_cartera..ca_dividendo with(nolock),#universo
where di_operacion = operacion_interna
and   di_operacion = am_operacion
and   di_dividendo = am_dividendo
and   di_estado     = 3
and   am_estado     = 3
and   am_operacion  = operacion_interna
group by operacion_interna

if @@error <> 0
begin
   select @w_msg = 'Error al crear tabla de valores totales pagados',
          @w_error = 708154
   goto ERROR
end

create unique index idx1 on #dos(operacion)

update #universo set 
Valor_pagado = VpagadoT 
from #dos
where operacion_interna = operacion

if @@error <> 0
begin
   select @w_msg = 'Error al actualizar registros tabla #universo valores totales pagados',
          @w_error = 708152
   goto ERROR
end

drop table #dos

select
FMora = CONVERT(VARCHAR(10),MIN(di_fecha_can),103),
'operacion' = operacion_interna
into #tres
from cob_cartera..ca_amortizacion with(nolock),cob_cartera..ca_dividendo with(nolock),#universo
where di_operacion = operacion_interna
and   di_operacion = am_operacion
and   di_dividendo = am_dividendo
and   di_estado     = 3
and   am_estado     = 3
and   am_operacion  = operacion_interna
and   di_fecha_ven  < di_fecha_can
group by operacion_interna

if @@error <> 0
begin
   select @w_msg = 'Error al crear tabla de fecha cancelacion',
          @w_error = 708154
   goto ERROR
end

create unique index idx1 on #tres(operacion)
 
update #universo set          
Fecha_Mora = FMora
from #tres 
where operacion_interna = operacion

if @@error <> 0
begin
   select @w_msg = 'Error al actualizar registros tabla #universo fecha cancelacion',
          @w_error = 708152
   goto ERROR
end

drop table #tres

select 'Edad_Mora_Dias' = isnull(MAX(do_edad_mora),0),
       'operacion'      = do_banco
into #cuatro
from cob_conta_super..sb_dato_operacion with(nolock), #universo
where do_banco  = Numero_Obli_o_Crd
group by do_banco

if @@error <> 0
begin
   select @w_msg = 'Error al crear tabla de Edad de Mora en Dias',
          @w_error = 708154
   goto ERROR
end

create unique index idx1 on #cuatro(operacion)

update #universo set          
Edad_Mora = Edad_Mora_Dias
from #cuatro 
where Numero_Obli_o_Crd = operacion

if @@error <> 0
begin
   select @w_msg = 'Error al actualizar registros tabla #universo Edad de Mora en Dias',
          @w_error = 708152
   goto ERROR
end

drop table #cuatro

delete from cob_cartera..ca_venta_universo
where operacion_interna in (select operacion_interna from #universo)
   
if @@error <> 0
begin
   select @w_msg   = 'Error al eliminar operaciones existentes en el universo',
          @w_error = 708155
   goto ERROR
end

insert into cob_cartera..ca_venta_universo
select Id_cliente,             Nombre_Cliente,         Tipo_Identificacion,
       Segmento,               Ciudad_Desembolso,      Tipo_Producto,          
       Saldo_capital,          Intereses,              Otros_cargos,
       Saldo_deuda_total,      Saldo_Mora,             Fecha_desembolso,       
       Valor_desembolso,       Plazo_credito,    	   Fecha_Mora,             
       Fecha_Castigo,          Edad_Mora,              Numero_Obli_o_Crd,                   
	   Existencia_acuerdo_pag, Estado_Cobranza,        Ciudad_Cred,
	   Valor_pagado,           Fecha_Ult_pago,         Capital_Pagado, 
	   Intereses_pagados,      Otros_concep_pag,       Direccion_Cliente,
	   Ciudad,                 Telefono, 	           Fecha_Nacimiento, 
	   Ingresos,               Egresos,                Estrato,   	            
	   Nivel_Estudio,    	   Profesion,	           Nota_Interna_Bmia,
	   Calificacion_Op,        operacion_interna,	   Banca,                  
	   Oficina,                Cod_CIIU,          	   Fecha_Venta,            
	   Secuencial_Ing_Ven,     Secuencial_Ing_Vig,	   Secuencial_Ing_Nvig,
	   Estado_Venta
from #universo
order by Id_cliente

if @@error <> 0
begin
   select @w_msg = 'Error al crear tabla cob_cartera..ca_venta_universo ',
          @w_error = 708154
   goto ERROR
end

return 0

ERROR:

exec cob_cartera..sp_errorlog 
@i_fecha       = @w_fecha_proceso,
@i_error       = @w_error, 
@i_usuario     = 'OPERADOR', 
@i_tran        = null,
@i_tran_name   = @w_sp_name,
@i_cuenta      = '',
@i_rollback    = 'N',
@i_descripcion = @w_msg
print @w_msg

return @w_error
go
