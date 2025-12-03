/************************************************************************/
/*   Archivo:                 datcabop.sp                               */
/*   Stored procedure:        sp_datocab_operacion                      */
/*   Base de Datos:           cob_cartera                               */
/*   Producto:                Cartera                                   */
/*   Disenado por:            DFu                                       */
/*   Fecha de Documentacion:  Oct. 2016                                 */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier autorizacion o agregado hecho por alguno de sus          */
/*   usuario sin el debido consentimiento por escrito de la             */
/*   Presidencia Ejecutiva de MACOSA o su representante                 */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Consulta  datos de cabecera de una operacion especifica            */
/************************************************************************/
/*                          MODIFICACIONES                              */
/*  FECHA        AUTOR             RAZON                                */
/*  20/oct/2016  DFu               Emision inicial                      */
/*  10/May/2019  AGi               Inclusion Operaciones Grupales       */
/*  01/Ago/2019  PQU               Cambio Cabecera Operaciones Grupales */
/*  02/Sep/2019  AGI               Cambio para Prorrogas                */
/*  21/Ene/2021  LPO               CDIG Operaciones Pasivas             */
/*  05/May/2021  G. Fernandez     Obtener estado de operaciones grupales*/
/*  20/May/2022  C. Tiguaque       Retornar cod_op_oficial para cabecera*/
/************************************************************************/

use cob_cartera
go

if exists(select * from sysobjects where name = 'sp_datocab_operacion')
   drop proc sp_datocab_operacion
go

create proc sp_datocab_operacion (
    @s_user                  varchar(14),
    @s_term                  varchar(30),
    @s_date                  datetime,
    @s_ofi                   smallint,
    @i_banco                 cuenta,
    @i_formato_fecha         smallint = 101,
    @i_operacion             char(1) = null
)
as

declare
@w_operacionca    int,
@w_error          int,
@w_msg            varchar(255),
@w_min_dividendo  int,
@w_max_dividendo  int,
@w_return         int,
@w_est_novigente  smallint,
@w_est_vigente    smallint,
@w_est_vencido    smallint,
@w_est_cancelado  smallint,
@w_est_castigado  smallint,
@w_est_diferido   smallint,
@w_est_anulado    smallint,
@w_est_condonado  smallint,
@w_est_suspenso   smallint,
@w_est_credito    smallint,

@w_op_fecha_ult_proceso datetime,
@w_valor_exigible       money,
@w_valor_proxima_cuota  money,
@w_max_fecha_ven        datetime,
@w_fecha_fin            datetime,
@w_estado               tinyint,
@w_estado_desc          descripcion,
@w_fmax_prorroga        DATETIME,            --AGC 02SEP
@w_saldo_capital        MONEY,

@w_grupal               CHAR (2),     --variable para verificacion de Grupal
@w_ref_grupal           varchar(25)   --variabla de referencia grupal 


exec @w_error = sp_estados_cca
@o_est_novigente  = @w_est_novigente out,
@o_est_vigente    = @w_est_vigente   out,
@o_est_vencido    = @w_est_vencido   out,
@o_est_cancelado  = @w_est_cancelado out,
@o_est_castigado  = @w_est_castigado out,
@o_est_diferido   = @w_est_diferido  out,
@o_est_anulado    = @w_est_anulado   out,
@o_est_condonado  = @w_est_condonado out,
@o_est_suspenso   = @w_est_suspenso  out,
@o_est_credito    = @w_est_credito   out

if @w_error <> 0 goto ERROR


/*
exec @w_return = sp_qr_operacion
@s_term = @s_term ,
@s_user = @s_user,
@s_date = @s_date,
@s_ofi  =  @s_ofi,
@i_formato_fecha = @i_formato_fecha,
@i_operacion = @i_operacion,
@i_banco =@i_banco

if @w_return <> 0
   begin
        goto ERROR
   end*/


select
@w_operacionca          = op_operacion,
@w_op_fecha_ult_proceso = op_fecha_ult_proceso,
@w_fecha_fin            = op_fecha_fin,
@w_grupal               = op_grupal,     -- Si la operacion es grupal es S
@w_ref_grupal           = op_ref_grupal  -- Si es una operacion padre Null
from  ca_operacion
where op_banco = @i_banco

if @@rowcount = 0
begin
    select @w_error = 710201 ,
           @w_msg   = 'PRESTAMO: ' + @i_banco
    goto ERROR
end

--PQU quitar esto, ya que la grupal se administra
/*
if exists (select 1 from ca_ciclo where ci_prestamo = @i_banco) 
begin
    
    exec sp_actualiza_grupal
    @i_banco             = @i_banco,
    @i_desde_cca         = 'N'
   
    
    --AGI. 09MAY19. LIQUIDACION OP. GRUPALES que no se administran como individual
    if exists (select 1 from ca_operacion, ca_default_toperacion
               where op_banco = @i_banco  
               and op_grupal  = 'S'
               and op_toperacion = dt_toperacion
               and dt_admin_individual = 'S')
               
        select @w_estado = min(op_estado)
        from   ca_operacion, ca_det_ciclo
        where  op_operacion = dc_operacion
        and    dc_referencia_grupal = @i_banco 
    else
       select @w_estado = min(op_estado)
        from   ca_operacion
        where  op_banco  = @i_banco 
end 
else 
begin
*/

--Validacion para operaciones grupales padres
if (@w_grupal = 'S' and @w_ref_grupal IS NULL)
begin
    --Obtengo el estado de la operacion padre deacuerdo al estado de las hijas
	EXEC cob_cartera..sp_consulta_estado_grupal
	@i_operacion = @w_operacionca ,
	@o_estado_grupo = @w_estado  OUTPUT
end
else
begin
    select @w_estado = op_estado 
    from   ca_operacion 
    where  op_banco = @i_banco
end
--end

/*CALCULO DE FECHA VENCIMIENTO DE PROXIMA CUOTA*/
select @w_max_fecha_ven = isnull(max(di_fecha_ven),@w_fecha_fin)
from ca_dividendo where di_operacion = @w_operacionca and di_estado = @w_est_vigente  

/*CALCULO DE VALOR EXIGIBLE DEL PRESTAMO*/
select
@w_min_dividendo = isnull(min(di_dividendo),0),
@w_max_dividendo = isnull(max(di_dividendo),0)
from   ca_dividendo
where  di_operacion = @w_operacionca
and   (di_estado    = @w_est_vencido or (di_estado = @w_est_vigente and di_fecha_ven <= @w_op_fecha_ult_proceso))

SELECT @w_valor_exigible = isnull(sum((am_cuota + am_gracia) - am_pagado),0)
FROM   ca_amortizacion
WHERE  am_operacion   = @w_operacionca
and    am_dividendo   between @w_min_dividendo and @w_max_dividendo

/*CALCULO PROXIMA CUOTA*/
select
@w_min_dividendo = isnull(min(di_dividendo),0),
@w_max_dividendo = isnull(max(di_dividendo),0)
from   ca_dividendo
where  di_operacion = @w_operacionca
and    di_estado    = @w_est_vigente

SELECT @w_valor_proxima_cuota = isnull(sum((am_cuota + am_gracia) - am_pagado),0)
FROM   ca_amortizacion
WHERE  am_operacion = @w_operacionca
and    am_dividendo between @w_min_dividendo and @w_max_dividendo

select @w_estado_desc = es_descripcion 
from   ca_estado 
where  es_codigo = @w_estado

--AGI. Obtener la fecha de vencimiento del primer dividendo no vigente
select @w_fmax_prorroga =  dateadd(dd,-1,di_fecha_ven)
from ca_dividendo
where  di_operacion = @w_operacionca
and    di_dividendo = @w_min_dividendo + 1
--FIN AGI

--Saldo de Capital
SELECT @w_saldo_capital = isnull(sum((am_cuota + am_gracia) - am_pagado),0)
FROM   ca_amortizacion
WHERE  am_operacion = @w_operacionca
and    am_concepto = 'CAP'


    
if not exists (select 1 from ca_ciclo where ci_prestamo = @i_banco) 
begin

    select 'op_toperacion'    = isnull(op_toperacion,'Tipo Pr‚stamo'),
/*       'linea'            = (select c.valor
                             from   cobis..cl_tabla t, cobis..cl_catalogo c
                             where  t.codigo = c.tabla
                             and    t.tabla  = 'ca_toperacion'
                             and    c.codigo = o.op_toperacion),
*/
        'linea'           = CASE op_naturaleza WHEN 'A' THEN (select valor  --LPO Operaciones Pasivas
                                                               from   cobis..cl_catalogo y, cobis..cl_tabla t
                                                               where  t.tabla = 'ca_toperacion'
                                                               and    y.tabla   = t.codigo
                                                               and    y.codigo  = o.op_toperacion)
                                                WHEN 'P' THEN (select valor
                                                               from   cobis..cl_catalogo y, cobis..cl_tabla t
                                                               where  t.tabla = 'ca_toperacion_pas'
                                                               and    y.tabla   = t.codigo
                                                               and    y.codigo  = o.op_toperacion)
                            END,                             
       'op_oficina'       = op_oficina,
       'oficina'          = (select isnull(of_nombre,'') from cobis..cl_oficina where of_oficina = o.op_oficina),
       'op_banco'         = op_banco,
       'op_operacion'     = op_operacion,
       'moneda'           = (select mo_descripcion from cobis..cl_moneda WHERE mo_moneda = convert(char(10),o.op_moneda)), --(select mo_nemonico from cobis..cl_moneda where mo_moneda = convert(char(10),o.op_moneda)),
       'op_oficial'       = (select f.fu_nombre
                             from   cobis..cc_oficial ofi, cobis..cl_funcionario f
                             where  ofi.oc_funcionario = f.fu_funcionario and
                                    ofi.oc_oficial     = o.op_oficial),
       'op_monto'         = op_monto,
       'op_cliente'       = op_cliente,
       'op_nombre'        = op_nombre,
       'en_tipo_ced'      = (select isnull(en_tipo_ced,'') from cobis..cl_ente where en_ente = o.op_cliente),
       'en_ced_ruc'       = (select isnull(en_ced_ruc,'')  from cobis..cl_ente where en_ente = o.op_cliente),
       'op_estado'        = @w_estado,
       'es_descripcion'   = @w_estado_desc,
       'fecha_ini'        = op_fecha_ini,
       'fecha_venc'       = op_fecha_fin,
       'fecha_venc_cuota' = @w_max_fecha_ven,
       'cod_op_oficial'   = op_oficial,
       'proxima_cuota'    = @w_valor_proxima_cuota,
       'tasa_efec_anual'  = (select sum(ro_porcentaje_efa)
                             from   ca_rubro_op
                             where  ro_operacion  = o.op_operacion
                             and    ro_tipo_rubro = 'I'),
       'Fec.Maxima Prorroga' = @w_fmax_prorroga,
       'Fecha ultimo Proceso' = op_fecha_ult_proceso,
       'Saldo Capital'        = @w_saldo_capital,
       'Naturaleza'           = op_naturaleza
   from   ca_operacion o
   where  op_banco      = @i_banco
end
else
begin
    select 'op_toperacion'    = isnull(op_toperacion,'Tipo Pr‚stamo'),
/*       'linea'            = (select c.valor
                             from   cobis..cl_tabla t, cobis..cl_catalogo c
                             where  t.codigo = c.tabla
                             and    t.tabla  = 'ca_toperacion'
                             and    c.codigo = o.op_toperacion),
*/
        'linea'           = CASE op_naturaleza WHEN 'A' THEN (select valor  --LPO Operaciones Pasivas
                                                               from   cobis..cl_catalogo y, cobis..cl_tabla t
                                                               where  t.tabla = 'ca_toperacion'
                                                               and    y.tabla   = t.codigo
                                                               and    y.codigo  = o.op_toperacion)
                                                WHEN 'P' THEN (select valor
                                                               from   cobis..cl_catalogo y, cobis..cl_tabla t
                                                               where  t.tabla = 'ca_toperacion_pas'
                                                               and    y.tabla   = t.codigo
                                                               and    y.codigo  = o.op_toperacion)
                            END,                             
                             
       'op_oficina'       = op_oficina,
       'oficina'          = (select isnull(of_nombre,'') from cobis..cl_oficina where of_oficina = o.op_oficina),
       'op_banco'         = op_banco,
       'op_operacion'     = op_operacion,
       'moneda'           = (select mo_descripcion from cobis..cl_moneda WHERE mo_moneda = convert(char(10),o.op_moneda)), --(select mo_nemonico from cobis..cl_moneda where mo_moneda = convert(char(10),o.op_moneda)),
       'op_oficial'       = (select f.fu_nombre
                             from   cobis..cc_oficial ofi, cobis..cl_funcionario f
                             where  ofi.oc_funcionario = f.fu_funcionario and
                                    ofi.oc_oficial     = o.op_oficial),
       'op_monto'         = op_monto,
       'op_cliente'       = op_cliente, 
       'op_nombre'        = op_nombre,
       'en_tipo_ced'      = ' ', --(select isnull(en_tipo_ced,'') from cobis..cl_ente where en_ente = o.op_cliente),
       'en_ced_ruc'       = ' ', --(select isnull(en_ced_ruc,'')  from cobis..cl_ente where en_ente = o.op_cliente),
       'op_estado'        = @w_estado,
       'es_descripcion'   = @w_estado_desc,
       'fecha_ini'        = op_fecha_ini,
       'fecha_venc'       = op_fecha_fin,
       'fecha_venc_cuota' = @w_max_fecha_ven,	
       'cod_op_oficial'   = op_oficial,
       'proxima_cuota'    = @w_valor_proxima_cuota,
       'tasa_efec_anual'  = (select sum(ro_porcentaje_efa)
                             from   ca_rubro_op
                             where  ro_operacion  = o.op_operacion
                             and    ro_tipo_rubro = 'I'),
       'Fec.Maxima Prorroga' = @w_fmax_prorroga,
       'Fecha ultimo Proceso' = op_fecha_ult_proceso,
       'Saldo Capital'        = @w_saldo_capital,
       'Naturaleza'           = op_naturaleza       
   from   ca_operacion o
   where  op_banco      = @i_banco

end 

if @@rowcount = 0
begin
    select @w_error = 710201
    goto ERROR
end


return 0

ERROR:
exec cobis..sp_cerror
@t_debug = 'N',
@t_file = null,
@t_from = 'sp_datocab_operacion',
@i_num  = @w_error
return @w_error



GO
