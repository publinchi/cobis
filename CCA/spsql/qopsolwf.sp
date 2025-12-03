use cob_cartera
go

/************************************************************************/
/*   Archivo:              qopsolwf.sp                                  */
/*   Stored procedure:     sp_qry_oper_sol_wf                           */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Raul Altamirano Mendez                       */
/*   Fecha de escritura:   Ene-05-2017                                  */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                                PROPOSITO                             */
/************************************************************************/
/*                               CAMBIOS                                */
/*      FECHA          AUTOR            CAMBIO                          */
/*      ENE-05-2017    Raul Altamirano  Emision Inicial - Version MX    */
/*      ABR-10-2017    Luis Ponce       Cambios Santander Credito Grupal*/
/*      ABR-19-2017    Milton Custode   Tramites grupales grupos new    */
/************************************************************************/

if exists (select 1 from sysobjects where name = 'sp_qry_oper_sol_wf')
drop proc sp_qry_oper_sol_wf
go

create proc sp_qry_oper_sol_wf (
   @t_show_version        bit          = 0,
@t_debug               varchar(1)   = 'N',
@t_file                varchar(14)  = null,
@t_from                varchar(30)  = null,
@t_trn                 int          = null,
@i_tramite             int          = null,
   @i_operacion           char(1)      = null,
   @i_formato_fecha       int          = 103
)
as
declare @w_tramite            int,
@w_tipo               char(1),
@w_desc_tipo          descripcion,
@w_oficina_tr         int,
@w_desc_oficina       descripcion,
@w_usuario_tr         login,
@w_fecha_crea         datetime,
@w_oficial            int,
@w_sector             catalogo,
@w_ciudad             int,
@w_estado             char(1),
@w_numero_op          int,
@w_numero_op_banco    cuenta,
@w_razon              catalogo,
@w_txt_razon          varchar(255),
@w_efecto             catalogo,
@w_cliente            int,
@w_grupo              int,
@w_fecha_inicio       datetime,
@w_num_dias           int,
@w_per_revision       catalogo,
@w_condicion_especial varchar(255),
@w_linea_credito      int,
@w_toperacion         catalogo,
@w_producto           catalogo,
@w_monto              money,
@w_moneda             int,
@w_periodo            catalogo,
@w_num_periodos       int,
@w_destino            catalogo,
@w_ciudad_destino     int,
@w_renovacion         int,
--variables para datos adicionales de operaciones de cartera
@w_monto_desembolso   money,
@w_tdividendo         catalogo,
@w_desc_tdividendo    descripcion,
@w_motivo_uno         varchar(255),
@w_motivo_dos         varchar(255),
@w_motivo_rechazo     catalogo,
--variables para completar datos del registro de un tramite
@w_des_oficial        descripcion,
@w_des_toperacion     descripcion,
@w_des_moneda        descripcion,
@w_des_periodo        descripcion,
@w_li_num_banco       cuenta,
@w_numero_operacion   int,
--variables para operacion a reestructurar
@w_banco_rest         cuenta,               --numero de banco
@w_operacion_rest     int,                  --secuencial
@w_saldo_rest         money,                --saldo capital
@w_op_banco           varchar(24),
@w_op_vinculado       char(1),              --Datos Vinculacion
@w_op_cliente         int,
@w_op_tipo_vinc       catalogo,
@w_tipo_vinc_desc     descripcion,
@w_fecha_liq          datetime,
@w_fecha_venc         datetime,
@w_tipo_credito       char(1),
@w_simbolo_moneda     varchar(10),
@w_provincia          int,
@w_fecha_venci        datetime,
@w_dias_anio          smallint,
@w_monto_aprobado     money,
@w_comentario         varchar(255),
@w_error              int,
@w_tr_grupal          char(1),
@w_acepta_ren         char(1),   --LPO Santander
        @w_no_acepta            varchar(1000),--LPO Santander
@w_garantia           float,
@w_sum_mont_grupal    money,      -- suma de montos grupal
        @w_sum_mont_grupal_sol  money, 
     -- suma de montos grupal
@w_numero_ciclo       int,
@w_numero_grupo       int,
@w_plazo              int,        -- Santander
@w_tplazo             catalogo,   -- Santander 
        @w_tplazo_descrip       varchar(64),-- Santander,
        @w_monto_max_tr         money,
-- Variable para la extraccion del dia habil
        @w_aux_monto            money,
        @w_aux_monto_aprobado   money,
        @w_est_novigente        int,
        @w_est_anulado          int,
        @w_est_credito          INT,
        @w_dia_pago             TINYINT,     --PQU Finca
        @w_origen_fondos	    catalogo     --PQU Finca 

if @t_show_version = 1
begin
    print 'Stored procedure sp_qry_oper_sol_wf, Version 1.0.0.0'
    return 0
end
/* Estados */
exec cob_cartera..sp_estados_cca @o_est_novigente = @w_est_novigente out,
                                  @o_est_anulado   = @w_est_anulado out,
                                 @o_est_credito   = @w_est_credito out

--Verificacion de Existencias
SELECT @w_tramite            = tr_tramite,
@w_tipo = tr_tipo,
@w_oficina_tr = tr_oficina,
@w_usuario_tr = tr_usuario,
@w_fecha_crea = tr_fecha_crea,
@w_oficial = tr_oficial,
@w_sector = tr_sector,
@w_ciudad = tr_ciudad,
@w_estado = tr_estado,
@w_numero_op = tr_numero_op,
@w_numero_op_banco = tr_numero_op_banco,
@w_razon = tr_razon,
@w_txt_razon = rtrim(tr_txt_razon),
@w_efecto = tr_efecto,
@w_cliente = tr_cliente, /*lineas*/
@w_grupo = tr_grupo,
@w_fecha_inicio = tr_fecha_inicio,
@w_num_dias = tr_num_dias,
@w_per_revision = tr_per_revision,
@w_condicion_especial = tr_condicion_especial,
@w_linea_credito = tr_linea_credito,  /*renov. y operaciones*/
@w_toperacion = tr_toperacion,
@w_producto = tr_producto,
@w_monto = tr_monto,
@w_moneda = tr_moneda,
@w_periodo = tr_periodo,
@w_num_periodos = tr_num_periodos,
@w_destino = tr_destino,
@w_ciudad_destino = tr_ciudad_destino,
@w_renovacion = tr_renovacion,
       @w_tr_grupal          = isnull(tr_grupal,'N'),
@w_garantia          = tr_porc_garantia,
@w_plazo             = tr_plazo,
       @w_tplazo             = tr_tplazo,
       @w_monto_max_tr       = tr_monto_max,
       @w_origen_fondos      = tr_origen_fondos
FROM cob_credito..cr_tramite
WHERE tr_tramite = @i_tramite
if @@rowcount = 0
begin
    set @w_error = 2101005
goto ERROR_PROCESO
end

--descripcion del tipo de tramite
select @w_desc_tipo = tt_descripcion
from cob_credito..cr_tipo_tramite
where tt_tipo = @w_tipo

--descripcion de la oficina
select @w_desc_oficina = of_nombre
from cobis..cl_oficina
where of_oficina = @w_oficina_tr

--numero de banco de la linea de credito
select @w_li_num_banco = li_num_banco
from cob_credito..cr_linea
where li_numero = @w_linea_credito

--nombre del oficial
select @w_des_oficial = substring(fu_nombre,1,30)
from cobis..cc_oficial, cobis..cl_funcionario
where oc_oficial = @w_oficial
and oc_funcionario = fu_funcionario

--nombre del cliente
if @w_tipo in ('O', 'R', 'E')
begin
select @w_cliente = de_cliente
from   cob_credito..cr_deudores
where  de_tramite = @i_tramite
and    de_rol = 'D'
end

--tipo de operacion
if @w_toperacion is not null
begin
select @w_des_toperacion = to_descripcion
from cob_credito..cr_toperacion
where to_toperacion =@w_toperacion
and to_producto = @w_producto
end

--moneda
if @w_moneda is not null
begin
select @w_des_moneda = mo_descripcion,
@w_simbolo_moneda = mo_simbolo
from cobis..cl_moneda
where mo_moneda = @w_moneda
end

--ciudad destino
if @w_ciudad_destino is not null
begin
    select @w_provincia  = ci_provincia
from cobis..cl_ciudad
where ci_ciudad = @w_ciudad_destino
end

--CONSULTAR LA INFORMACION ADICIONAL
if @w_producto = 'CCA'
begin
--CONSULTAR INFORMACION CONSIDERANDO EL ENVIO DE NUMERO DE TRAMITE
select @w_numero_operacion = op_operacion,
@w_monto_desembolso      = op_monto,
@w_fecha_inicio          = op_fecha_ini,
@w_periodo               = op_tplazo,
@w_des_periodo           = td_descripcion,
@w_tdividendo            = op_tdividendo, --DMO
@w_num_periodos          = op_plazo,
@w_op_banco           = op_banco,
@w_op_cliente         = op_cliente,
@w_dias_anio          = op_dias_anio,
@w_monto_aprobado     = op_monto_aprobado,
@w_comentario         = op_comentario,
@w_acepta_ren         = op_acepta_ren,    --LPO Santander
@w_no_acepta          = op_no_acepta,     --LPO Santander
           @w_dia_pago           = op_dia_fijo       --PQU Finca
    from  cob_cartera..ca_operacion op
    inner join cob_cartera..ca_tdividendo on td_tdividendo = op_tplazo
where op_tramite = @i_tramite
 
select @w_op_vinculado = isnull(en_vinculacion, 'N')
from cobis..cl_ente
where en_ente = @w_op_cliente
if @w_op_vinculado is null
begin
        set @w_op_vinculado = 'N'
end

--DATOS DE VINCULACION
if @w_op_vinculado <>'N'
begin
    select @w_op_tipo_vinc = en_tipo_vinculacion
    from   cobis..cl_ente
    where  en_ente = @w_op_cliente

    select @w_tipo_vinc_desc = rtrim(b.valor)
    from   cobis..cl_tabla a, cobis..cl_catalogo b
    where  a.tabla  = 'cl_tipo_vinculacion'
    and    b.tabla  = a.codigo
    and    b.codigo = @w_op_tipo_vinc

        set @w_tipo_vinc_desc  =  rtrim(@w_op_tipo_vinc) + '-' +  rtrim(@w_tipo_vinc_desc)
end

    set @w_numero_op_banco = isnull(@w_numero_op_banco,@w_op_banco)

select @w_desc_tdividendo = td_descripcion
from cob_cartera..ca_tdividendo
where td_tdividendo = @w_tdividendo

--Fecha de Vencimiento de una operaci+Ýn
select @w_fecha_venci = di_fecha_ven
from   cob_cartera..ca_dividendo
where  di_operacion = @w_numero_operacion and di_dividendo = 1

select @w_fecha_liq  = op_fecha_liq,
@w_fecha_venc = op_fecha_fin
from cob_cartera..ca_operacion
where op_operacion = @w_numero_operacion

--datos de la operacion a reestructurar
if @w_tipo = 'E'
begin
--obtener el numero de banco de la operacion
select @w_banco_rest = or_num_operacion
from   cob_credito..cr_op_renovar
where  or_tramite = @i_tramite
--obtener los datos de la operacion
        select @w_operacion_rest  = op_operacion
from  cob_cartera..ca_operacion
where op_banco = @w_banco_rest

--obtener el saldo de capital
--select @w_saldo_rest = sum(isnull(am_cuota,0) + isnull(am_gracia,0) - isnull(am_pagado,0) - isnull(am_exponencial,0))
select @w_saldo_rest = sum(isnull(am_cuota,0) + isnull(am_gracia,0) - isnull(am_pagado,0))
from   cob_cartera..ca_amortizacion, cob_cartera..ca_rubro_op
where  ro_operacion = @w_operacion_rest
and    ro_tipo_rubro in ('C')    -- tipo de rubro capital
and    am_operacion = ro_operacion
and    am_concepto  = ro_concepto
end

end -- @w_producto = 'CCA'

-- Informacion de Datos Adicionales: Rechazo, motivo y justificacion
select @w_motivo_rechazo = null,
@w_motivo_uno = null,
@w_motivo_dos = null

-- Suma de montos
select @w_sum_mont_grupal     = sum(tg_monto),
       @w_sum_mont_grupal_sol = sum(tg_monto_aprobado)
from   cob_credito..cr_tramite_grupal
where  tg_tramite = @i_tramite

select @w_numero_grupo        = tg_grupo
from   cob_credito..cr_tramite_grupal
where  tg_tramite = @i_tramite

select @w_numero_ciclo = gr_num_ciclo 
from   cobis..cl_grupo
where  gr_grupo = @w_numero_grupo
set @w_numero_ciclo = isnull(@w_numero_ciclo,0) + 1

if @w_tr_grupal = 'N'
begin
   /* Se extrae el plazo para individual */
   select @w_num_periodos = tr_plazo
   from   cob_credito..cr_tramite
   where  tr_tramite = @w_tramite

   /* Se reeplaza el periodo del tramite por el tipo de plazo */
   set @w_periodo = @w_tdividendo

   /* INICIO INVERTIR Se invirte el orden de las variables de monto solicitado y monto autorizado, el cambio es por conceptos */
   set @w_aux_monto = @w_monto
  set @w_aux_monto_aprobado = @w_monto_aprobado

   /* Invertir */
   set @w_monto = @w_aux_monto_aprobado
   set @w_monto_aprobado = @w_aux_monto
   /* FIN INVERTIR*/

   /* Obtener ciclo individual */
   select @w_numero_ciclo = count(1) from cob_cartera..ca_operacion
   where  op_cliente = @w_cliente
   and    op_toperacion = @w_toperacion
   and    op_tramite <> @w_tramite
   and    op_estado  not in (@w_est_novigente, @w_est_anulado, @w_est_credito)

   if @w_numero_ciclo < 0 or @w_numero_ciclo is null
   begin
      set @w_numero_ciclo = 0
   end 
   set @w_numero_ciclo = @w_numero_ciclo + 1
end

--descripcion del plazo
select @w_tplazo_descrip = td_descripcion
from   cob_cartera..ca_tdividendo
where  td_tdividendo = @w_periodo

--retorno al front-end
select @w_tramite,                   --1
@w_tipo,
       @w_desc_tipo,
@w_oficina_tr,
       @w_desc_oficina,                           --5
       @w_usuario_tr,
@w_fecha_crea,
@w_oficial,
@w_ciudad_destino,--@w_ciudad,
       @w_estado,                                 --10
       @w_numero_op_banco,
@w_razon,
@w_txt_razon,
@w_efecto,
       @w_cliente,                                --15
isnull(@w_grupo,@w_numero_grupo),
@w_fecha_inicio,
@w_num_dias,
@w_per_revision,
       @w_condicion_especial,                     --20
@w_toperacion,
       @w_producto,
@w_li_num_banco,
@w_monto,
       @w_moneda,                                 --25
@w_periodo,
       @w_num_periodos,
@w_destino,
@w_ciudad_destino,
       @w_dia_pago,                             --30  --PQU enviar aqui dia de pago
       @w_sector,
@w_des_oficial,
@w_des_toperacion,
@w_des_moneda,
       @w_saldo_rest,                             --35    
@w_periodo,
@w_moneda, --@w_moneda_solicitada,
       @w_provincia,
       @w_monto_desembolso,
       @w_num_periodos, --@w_pplazo,              --40
@w_tipo_credito,
@w_des_oficial,
@w_des_periodo, --@w_des_frec_pago,
       @w_simbolo_moneda,
       @w_numero_operacion,                       --45
       @w_numero_op_banco,
       @w_origen_fondos,--@w_motivo_uno,                             -- PQU enviar aqui el origen de fondos
@w_motivo_dos,           -- Etapa de rechazo
@w_motivo_rechazo,       -- Etapa de rechazo
       @w_linea_credito,                          --50
       @w_op_vinculado,
@w_fecha_venci,
@w_dias_anio,
@w_monto_aprobado,
       @w_comentario,                             --55
       @w_acepta_ren,
       @w_no_acepta,
       @w_garantia,
       @w_numero_ciclo,
       @w_tplazo,                                 --60
       @w_tplazo_descrip,
       @w_sum_mont_grupal,
       @w_sum_mont_grupal_sol,
       @w_monto_max_tr

return 0

ERROR_PROCESO:
return @w_error


GO
