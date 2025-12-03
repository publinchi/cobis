/************************************************************************/
/*   NOMBRE LOGICO:      datosop.sp                                     */
/*   NOMBRE FISICO:      sp_datos_operacion                             */
/*   BASE DE DATOS:      cob_cartera                                    */
/*   PRODUCTO:           Cartera                                        */
/*   DISENADO POR:       Francisco Yacelga                              */
/*   FECHA DE ESCRITURA: 25/Nov./1997                                   */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada; y por lo tanto, derivará en acciones legales civiles      */
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/
/*                            PROPOSITO                                 */
/*   Consulta de los datos de una operacion                             */
/************************************************************************/
/*                            MODIFICACIONES                            */
/*   FECHA               AUTOR       CAMBIO                             */
/*   JUN-09-2010    Elcira Pelaez    Quitar Codigo Causacion Pasivas    */
/*   ENE-18-2012    Luis C. Moreno   RQ293 Consulta valor por amortizar */
/*                                   pago por reconocimiento            */
/*   JUN-12-2019    Jonathan Tomala  Implementacion Operaciones H(Hijas)*/
/*                                   Y(Interciclas)                     */
/*   JUN-26-2019    Adriana Giler    Cambios en proceso Abono           */
/*   JUN-27-2019    Jonathan Tomala  Implementacion Operacion W(SEGUROS)*/
/*                                   Y B(BENEFICIARIOS)                 */
/*   JUL-01-2019    Jonathan Tomala  cambio de so_plazo a so_fecha_fin  */
/*   17/Nov/2020    EMP-JJEC         Rubros Finanaciados                */
/*  09/Nov/2020    P. Narvaez Reestructura desde Cartera de operaciones */
/*  06/May/2021    G. Fernandez   Sumatoria de cuotas operaciones hijas */
/*  12/Mar/2024    K. Rodriguez   R221782- Ajustes consulta abn-grupal  */
/************************************************************************/

use cob_cartera
go

set ansi_nulls off
go

if exists (select 1 from sysobjects where name = 'sp_datos_operacion')
   drop proc sp_datos_operacion
go
---Inc 88842 pariendo de la Ver. 20
create proc sp_datos_operacion (
   @s_ssn               int              = null,
   @s_date              datetime         = null,
   @s_user              login            = null,
   @s_term              descripcion      = null,
   @s_corr              char(1)          = null,
   @s_ssn_corr          int              = null,
   @s_ofi               smallint         = null,
   @t_rty               char(1)          = null,
   @t_debug             char(1)          = 'N',
   @t_file              varchar(14)      = null,
   @t_trn               smallint         = null,
   @i_banco             cuenta           = null,
   @i_operacion         char(1)          = null,
   @i_formato_fecha     int              = 101,
   @i_secuencial_ing    int              = null,
   @i_toperacion        catalogo         = null,
   @i_moneda            int              = null,
   @i_siguiente         int              = null,
   @i_dividendo         int              = null,
   @i_numero            int              = null,
   @i_sucursal          int              = null,
   @i_filial            int              = null,
   @i_oficina           smallint         = null,
   @i_concepto          catalogo         = '',
   @i_fecha_abono       datetime         = null,
   @i_opcion            tinyint          = null,
   @i_tramite           int              = null,
   @i_sec_detpago       int              = 0,
   @i_poliza            varchar(20)      = null,
   @i_aseguradora       varchar(20)      = null


)

as
declare
   @w_sp_name             varchar(32),
   @w_return              int,
   @w_error               int,
   @w_operacionca         int,
   @w_det_producto        int,
   @w_tipo                char(1),
   @w_tramite             int,
   @w_count               int,
   @w_filas               int,
   @w_filas_rubros        int,
   @w_primer_des          int,
   @w_bytes_env           int,
   @w_buffer              int,
   @w_secuencial_apl      int,
   @w_fecha_u_proceso     datetime,
   @w_moneda              int,
   @w_moneda_nacional     tinyint,
   @w_cotizacion          money,
   @w_op_moneda           tinyint,
   @w_contador            int,
   @w_dtr_dividendo       int,
   @w_dtr_concepto        catalogo,
   @w_dtr_estado          char(20),
   @w_dtr_cuenta          cuenta,
   @w_dtr_moneda          char(20),
   @w_dtr_monto           money,
   @w_dtr_monto_mn        money,
   @w_op_operacion        int,
   @w_op_migrada          varchar(20),
   @w_total_reg           int,
   @w_dist_gracia         char(1),                                   -- REQ 175: PEQUENA EMPRESA
   @w_gracia_int          smallint,                                  -- REQ 175: PEQUENA EMPRESA
   @w_tabla_cod           smallint,   --JTO 27/06/2019 - CONSULTA DE BENEFICIARIOS DE SEGUROS DE OPERACION
   @w_vlr_x_amort         money --REQ 293 - LCM


--- Captura nombre de Stored Procedure
select
@w_sp_name = 'sp_datos_operacion',
@w_buffer  = 2500   --TAMANIO MAXIMO DEL BUFFER DE RED


-- CODIGO DE LA MONEDA LOCAL
select @w_moneda_nacional = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'
set transaction isolation level read uncommitted

--- DETERMINAR ULTIMO TRAMITE DE LA OPERACION
select @w_tramite = max(tr_tramite)
from cob_credito..cr_tramite
where tr_numero_op_banco = @i_banco
and   tr_estado <> 'Z'
and   tr_tipo = 'E'

--- CHEQUEO QUE EXISTA LA OPERACION

select
@w_operacionca        = op_operacion,
@w_tramite            = isnull( @w_tramite, op_tramite ),
@w_op_migrada         = op_migrada,
@w_tipo               = op_tipo,
@w_fecha_u_proceso    = op_fecha_ult_proceso,
@w_moneda             = op_moneda,
@w_dist_gracia        = op_dist_gracia,
@w_gracia_int         = op_gracia_int
from   ca_operacion
where  op_banco = @i_banco

if @@rowcount = 0
begin
   select @w_error = 710022
   goto ERROR
end

--- DETERMINAR EL VALOR DE COTIZACION DEL DIA
if @w_moneda = @w_moneda_nacional
   select @w_cotizacion = 1.0
else
begin
   exec sp_buscar_cotizacion
   @i_moneda     = @w_moneda,
   @i_fecha      = @w_fecha_u_proceso,
   @o_cotizacion = @w_cotizacion output
end

--- CONSULTAR ABONOS
if @i_operacion='A' begin

   exec @w_error = sp_prorrateo_pago_grp
   @s_user               = @s_user,
   @s_date               = @s_date,
   @i_operacionca        = @w_operacionca,
   @i_banco              = @i_banco,
   @i_formato_fecha      = @i_formato_fecha,
   @i_secuencial_ing     = @i_secuencial_ing,
   @i_operacion          = @i_operacion,
   @i_sec_detpago        = @i_sec_detpago
   
   if @w_error <> 0
      goto ERROR
   
end

--- CONSULTA DEL DETALLE DEL ABONO
if @i_operacion = 'D'
begin

   exec @w_error = sp_prorrateo_pago_grp
   @s_user               = @s_user,
   @s_date               = @s_date,
   @i_operacionca        = @w_operacionca,
   @i_banco              = @i_banco,
   @i_formato_fecha      = @i_formato_fecha,
   @i_secuencial_ing     = @i_secuencial_ing,
   @i_operacion          = @i_operacion,
   @i_sec_detpago        = @i_sec_detpago
   
   if @w_error <> 0
      goto ERROR
   
end --- operacion D

if @i_operacion = 'X'
begin
   delete from ca_consulta_rec_pago_tmp
   where usuario = @s_user
end

--- CONDICIONES DE PAGO
if @i_operacion='P'
begin
   select op_tipo_cobro,
          op_aceptar_anticipos,
          op_tipo_reduccion,
          op_tipo_aplicacion,
          op_cuota_completa,
          op_fecha_fin,
          op_pago_caja,
          op_calcula_devolucion
   from ca_operacion,
        ca_estado
   where op_operacion = @w_operacionca
   and   es_codigo     = op_estado
end

--- CONSULTA TASAS

if @i_operacion='T'
begin
   select @i_siguiente = isnull(@i_siguiente,0)

   --set rowcount 20
   select 'Secuencial'             = ts_secuencial,
          'Fecha Mod.'             = convert(varchar(12),ts_fecha,@i_formato_fecha),
          'No.Cuota'               = ts_dividendo,
          'Rubro'                  = ts_concepto,
          'Valor Aplicar'          = ts_referencial,
          'Signo Aplicar'          = ts_signo,
          'Spread Aplicar'         = convert(varchar(25), ts_factor),
          'Tasa Actual'            = ts_porcentaje,
          'Tasa Efectiva Anual'    = ts_porcentaje_efa,
          'Tasa Referencial'       = ts_tasa_ref,
          'Fecha Tasa Referencial' = convert(varchar(12),ts_fecha_referencial,@i_formato_fecha),
          'Valor Tasa Referencial' = ts_valor_referencial
   from  ca_tasas --X
   where ts_operacion  = @w_operacionca
   and   ts_dividendo > @i_siguiente
   order by ts_fecha, ts_dividendo, ts_secuencial
end



--- DEUDORES Y CODEUDORES DE UNA OPERACION*
if @i_operacion = 'E'
begin
    ---Mroa: NUEVA RUTINA PARA TRAER LOS DEUDORES DE LA OPERACION
    select 'Codigo'      = de_cliente,
           'CE./NIT.'    = en_ced_ruc,
           'Rol'         = de_rol,
           'Nombre'      = en_nomlar,
           'Telefono'    = isnull((select top 1 te_valor
                                   from cobis..cl_telefono
                                   where te_ente = de_cliente
                                   and te_direccion = (select max(di_direccion)
                                                       from cobis..cl_direccion
                                                       where di_ente = A.de_cliente
                                                       and di_tipo != 'CE')),'SIN TELEFONO'),
           'Direccion'   = isnull((select top 1 di_descripcion
                                   from cobis..cl_direccion
                                   where di_ente = de_cliente
                                   and di_tipo != 'CE'
                                   and di_direccion = (select max(di_direccion)
                                                       from cobis..cl_direccion
                                                       where di_ente = A.de_cliente
                                                       and di_tipo != 'CE')),'SIN DIRECCION'),
           'Cob/Central' = de_cobro_cen
    from   cob_credito..cr_deudores A,
           cobis..cl_ente
    where  de_tramite    = @w_tramite
    and    en_ente       = de_cliente
    order by de_rol desc

end


--- ESTADO ACTUAL
if @i_operacion = 'S'
begin
   ---SOLO PARA LA PRIMERA TRANSMISION
   if @i_dividendo = 0
   begin
      --- RUBROS QUE PARTICIPAN EN LA TABLA
      select ro_concepto, co_descripcion, ro_tipo_rubro,ro_porcentaje
      from ca_rubro_op, ca_concepto
      where ro_operacion = @w_operacionca
      and   ro_fpago    in ('P','A','M','T')
      and   ro_concepto = co_concepto
      order by ro_concepto

      select @w_filas_rubros = @@rowcount


      if @w_filas_rubros <= 10
         select @w_filas_rubros = @w_filas_rubros + 2

      select @w_bytes_env    = @w_filas_rubros * 90  --83  --BYTES ENVIADOS

      select @w_primer_des = isnull(min(dm_secuencial),0)
      from   ca_desembolso
      where  dm_operacion  = @w_operacionca

      select dtr_dividendo, sum(isnull(dtr_monto,0)),'D' ---DESEMBOLSOS PARCIALES
      from   ca_det_trn, ca_transaccion, ca_rubro_op
      where  tr_banco      = @i_banco
      and    tr_secuencial = dtr_secuencial
      and    tr_operacion  = dtr_operacion
      and    dtr_secuencial <> @w_primer_des
      and    ro_operacion = @w_operacionca
      and    ro_tipo_rubro= 'C'
      and    tr_tran    = 'DES'
      and    tr_estado    in ('ING','CON')
      and    ro_concepto  = dtr_concepto
      group by dtr_dividendo
      union
      select dtr_dividendo, sum(isnull(dtr_monto,0)),'R'       ---REESTRUCTURACION
      from ca_det_trn, ca_transaccion, ca_rubro_op
      where  tr_banco      = @i_banco
      and   ro_operacion = @w_operacionca
      and   ro_concepto  = dtr_concepto
      and   ro_tipo_rubro= 'C'
      and   tr_tran      = 'RES'
      and   tr_estado    in ('ING','CON')
      and   tr_secuencial = dtr_secuencial
      and   tr_operacion  = dtr_operacion
      group by dtr_dividendo

      select @w_filas_rubros = @@rowcount

      select @w_bytes_env    = @w_bytes_env + (@w_filas_rubros * 13)

      select di_dias_cuota
      from ca_dividendo
      where di_operacion = @w_operacionca
      and   di_dividendo > @i_dividendo
      order by di_dividendo

      select @w_filas = @@rowcount

      select @w_bytes_env  = @w_bytes_env + (@w_filas * 4) --1)

   end

   if @i_opcion = 0
   begin

      if @i_dividendo = 0
         select @w_count = (@w_buffer - @w_bytes_env) / 38
      else
         select @w_count = @w_buffer / 38


      set rowcount @w_count

      --- FECHAS DE VENCIMIENTOS DE DIVIDENDOS Y ESTADOS
      select
      convert(varchar(10),di_fecha_ven,@i_formato_fecha),
      substring(es_descripcion,1,20),
      0,
      di_prorroga
      from ca_dividendo, ca_estado
      where di_operacion = @w_operacionca
      and   di_dividendo > @i_dividendo
      and   di_estado    = es_codigo
      order by di_dividendo

      select @w_filas = @@rowcount
      select @w_bytes_env    =  (@w_filas * 38)

      select @w_count
   end
   else
   begin
      select
      @w_filas = 0,
      @w_count = 1,
      @w_bytes_env = 0
   end

   if @w_filas < @w_count
   begin
      select @w_total_reg = count(distinct convert(varchar, di_dividendo) + ro_concepto)
      from ca_rubro_op
      inner join ca_dividendo
      on   (   di_dividendo > @i_dividendo
            or (di_dividendo = @i_dividendo and ro_concepto > @i_concepto))
      and  ro_operacion  = @w_operacionca
      and  ro_fpago     in ('P','A','M','T')
      and  di_operacion  = @w_operacionca
      left outer join ca_amortizacion
      on   ro_concepto   = am_concepto
      and  di_dividendo  = am_dividendo
      and  am_operacion  = @w_operacionca

      select @w_count = (@w_buffer - @w_bytes_env) / 21  -- Esta linea antes era 21, se cambio a 21
                                                         -- Para corregir una consulta puntual  def.5043

      if @i_dividendo > 0 and @i_opcion = 0
         select @i_dividendo = 0

      set rowcount @w_count

      select
      di_dividendo,
      ro_concepto,
      convert(float, isnull(sum(isnull(am_cuota,0) + isnull(am_gracia,0)),0))
      from ca_rubro_op
      inner join ca_dividendo
      on   (   di_dividendo > @i_dividendo
            or (di_dividendo = @i_dividendo and ro_concepto > @i_concepto))
      and  ro_operacion  = @w_operacionca
      and  ro_fpago     in ('P','A','M','T')
      and  di_operacion  = @w_operacionca
      left outer join ca_amortizacion
      on   ro_concepto   = am_concepto
      and  di_dividendo  = am_dividendo
      and  am_operacion  = @w_operacionca
      group by di_dividendo, ro_concepto
      order by di_dividendo, ro_concepto


      --if @w_total_reg = @w_count
      --   select @w_count = @w_count + 1

      select @w_count
   end

   exec @w_error = sp_pagxreco --RQ 293 - LCM
        @i_tipo_oper   = 'V',
        @i_operacionca = @w_operacionca,
        @o_vlr_x_amort = @w_vlr_x_amort  out

   select isnull(@w_vlr_x_amort,0)
end


--- ESTADO ACTUAL DETALLE
if @i_operacion = 'L'
 begin
   select 'Rubro'              = am_concepto,
          'Estado'             = (SELECT es_descripcion FROM ca_estado WHERE es_codigo = am.am_estado),
          'Periodo'            = am_periodo,
          'Cuota            '  = convert(float, am_cuota),
          'Gracia           '  = convert(float, am_gracia),
          'Pagado           '  = convert(float, am_pagado),
          'Acumulado        '  = convert(float, am_acumulado),
          'Secuencia   '       = am_secuencia
   from ca_amortizacion am,
        ca_dividendo di
       -- ca_estado
   where am_operacion = di_operacion
   and am_dividendo	 = di_dividendo
   and am_operacion = @w_operacionca
   and   am_dividendo = @i_dividendo

end

--- INSTRUCCIONES OPERATIVAS

if @i_operacion = 'I'
begin
   select @i_numero = isnull(@i_numero , 0)

   set rowcount 8
   select  'Numero'          = in_numero,
           'Tipo'            = in_codigo,
           'Instruccion'     = ti_descripcion,
           'Descripcion'     = in_texto,
           'Estado'          = in_estado,
           'Aprobado Por'    = fu_nombre,
           'Fecha Ejecucion' = convert(char(10), in_fecha_eje, 103),
           'Ejecutado Por'   = in_login_eje
            from cob_credito..cr_instrucciones
                 inner join cob_credito..cr_tinstruccion on
                           in_tramite = @w_tramite
                           and ti_codigo = in_codigo
                           and in_numero > @i_numero
                                   left outer join  cobis..cl_funcionario noholdlock on
                                   in_login_aprob = fu_login

   set rowcount 0
end


--- GARANTIAS

if @i_operacion = 'G' begin
   if @i_sucursal is null
      select @i_sucursal = of_sucursal
      from cobis..cl_oficina
      where of_oficina = @i_oficina
      set transaction isolation level read uncommitted

set rowcount 20

   select
      distinct  gp_garantia as GARANTIA,
                cu_estado as ESTADO_GAR,
                substring(cu_tipo,1,15)+'   '+substring(tc_descripcion,1,20) as DESCRIPCION,
                cg_ente as COD_CLIENTE,
                substring(cg_nombre,1,25) as NOMBRE_CLIENTE,
                convert(float,cu_valor_inicial) as VALOR_ACTUAL,
                cu_moneda as MON,
                convert(varchar(10),cu_fecha_ingreso,@i_formato_fecha) as F_INGRESO
   from cob_custodia..cu_custodia,
        cob_custodia..cu_cliente_garantia,
        cob_custodia..cu_tipo_custodia,
        cob_credito..cr_gar_propuesta,
        cob_cartera..ca_operacion
   where ((op_banco = @i_banco ) or (op_tramite = @i_tramite))
   and op_tramite           = gp_tramite
   and cu_codigo_externo    = gp_garantia
   and cu_codigo_externo    = cg_codigo_externo
   and cu_tipo              = tc_tipo
   and cu_estado in ('V','F','P')
   and cg_principal  in ('D','S' )
   and cu_garante is null 
   order by GARANTIA,
            ESTADO_GAR,
            DESCRIPCION,
            COD_CLIENTE,
            NOMBRE_CLIENTE,
            VALOR_ACTUAL,
            MON,
            F_INGRESO
end


--- GARANTES, AVALISTAS, FIADORES

if @i_operacion = 'F' begin
   if @i_sucursal is null
      select @i_sucursal = of_sucursal
      from cobis..cl_oficina
      where of_oficina = @i_oficina
      set transaction isolation level read uncommitted

set rowcount 20

   select
      distinct  gp_garantia as GARANTIA,
                cu_estado as ESTADO_GAR,
                substring(cu_tipo,1,15)+'   '+substring(tc_descripcion,1,20) as DESCRIPCION,
                cg_ente as COD_CLIENTE,
                substring(cg_nombre,1,25) as NOMBRE_CLIENTE,
                convert(float,cu_valor_inicial) as VALOR_ACTUAL,
                cu_moneda as MON,
                convert(varchar(10),cu_fecha_ingreso,@i_formato_fecha) as F_INGRESO
   from cob_custodia..cu_custodia,
        cob_custodia..cu_cliente_garantia,
        cob_custodia..cu_tipo_custodia,
        cob_credito..cr_gar_propuesta,
        cob_cartera..ca_operacion
   where ((op_banco = @i_banco ) or (op_tramite = @i_tramite))
   and op_tramite           = gp_tramite
   and cu_codigo_externo    = gp_garantia
   and cu_codigo_externo    = cg_codigo_externo
   and cu_tipo              = tc_tipo
   and cu_estado in ('V','F','P')
   and cg_principal  in ('D','S' )
   and cu_garante is not null
   order by GARANTIA,
            ESTADO_GAR,
            DESCRIPCION,
            COD_CLIENTE,
            NOMBRE_CLIENTE,
            VALOR_ACTUAL,
            MON,
            F_INGRESO
end

--- GARANTIAS - POLIZAS

if @i_operacion = 'J' begin

set rowcount 20

         select 'ASEGURADORA' = po_aseguradora, 
				'POLIZA' = po_poliza,
                'GARANTIA' = po_codigo_externo,
                'FECHA VIGENCIA' = convert(varchar(10),po_fvigencia_inicio,@i_formato_fecha),
                'FECHA VENCIMIENTO' = convert(varchar(10),po_fvigencia_fin,@i_formato_fecha),
                'MONTO' = po_monto_poliza,
				'MONTO_ENDOSO' = po_monto_endozo,
                'FECHA ENDOSO' = convert(varchar(10),po_fecha_endozo,@i_formato_fecha),
				'FECHA FIN ENDOSO' = convert(varchar(10),po_fendozo_fin,@i_formato_fecha),
				'COBERTURA' = po_cobertura,
				'ESTADO' = po_estado_poliza
         from cu_poliza with(1) 
        where ((po_aseguradora > @i_aseguradora) or
              (po_poliza > @i_poliza and po_aseguradora = @i_aseguradora))
		  and po_poliza > isnull(@i_poliza,'')  
      
end


--- RUBROS
if @i_operacion = 'R'
begin
   select 'Rubro'                     = ro_concepto,
          'Descripcion'               = substring(co_descripcion,1,30),
          'Tipo Rubro'                = ro_tipo_rubro,
          'F. de Pago'                = ro_fpago ,
          --GFP Obtener la sumatoria de las cuotas, primero consultas las operaciones hijas si no exite suma las cuotas de la operacion grupal
          'Valor'                     = isnull(isnull((SELECT sum(am_cuota) FROM ca_amortizacion, ca_operacion WHERE am_operacion = op_operacion AND op_grupal='S' AND op_ref_grupal = @i_banco AND am_concepto = co.co_concepto),
                                        (SELECT sum(am_cuota) FROM ca_amortizacion WHERE am_operacion = @w_operacionca AND am_concepto = co.co_concepto)),ro_valor),
          'Prioridad'                 = ro_prioridad,
          'Paga Mora'                 = ro_paga_mora,
          'Causa'                     = ro_provisiona,
          'Referencia'                = ro_referencial,
          'Signo'                     = ro_signo ,
          'Valor/Puntos'              = round(ro_factor,2),
          'Tipo/Puntos'               = ro_tipo_puntos,
          'Valor/Tasa Total'          = ro_porcentaje,
          'Tasa Negociada'            = ro_porcentaje_aux,
          'Tasa Ef.Anual'             = ro_porcentaje_efa,
          'Signo reaj.'               = ro_signo_reajuste ,
          'Valor/Puntos de Reaj.'     = ro_factor_reajuste,
          'Referencia de Reaj.'       = substring(ro_referencial_reajuste,1,10),
          'Gracia'                    = ro_gracia,
          'Base de calculo'           = ro_base_calculo,
          'Por./Cobrar/TIMBRE'        = ro_porcentaje_cobrar,
          'Tipo Garantia'             = ro_tipo_garantia,
          'Nro. Garantia'             = ro_nro_garantia,
          '%Cobertura Gar.'           = ro_porcentaje_cobertura,
          'Valor Garantia'            = ro_valor_garantia,
          'Tipo Dividendo'            = ro_tperiodo,
          'No. Periodos Int.'         = ro_periodo,
          'Tabla Otras Tasas'         = ro_tabla,
          'Financiado'                = ro_financiado,
          'Tasa Máxima'               = ro_tasa_maxima,
          'Tasa Mínima'               = ro_tasa_minima
   from ca_rubro_op ro,
        ca_concepto co
   where ro_operacion   = @w_operacionca
   and   ro_concepto=co_concepto
   and   ro_concepto > isnull(@i_concepto,'')
   order by ro_concepto

end

--- OPERACIONES RENOVADAS
if @i_operacion = 'N'
begin
   --El tramite de la reestructura, no se actualiza en el tramite de la operacion final
   select tramite = or_tramite
   into #reestructuras
   from cob_credito..cr_op_renovar
   where or_num_operacion = @i_banco

   select
      'Tramite'            = or_tramite,
      'Tipo'               = tr_tipo, 
      'Operacion'          = or_num_operacion,
      'Monto Original'     = or_monto_original,
      'Saldo Renovado'     = or_saldo_original,
      'Tipo Credito'       = or_toperacion,
      'Funcionario'        = or_login
   from ca_operacion, cob_credito..cr_op_renovar, cob_credito..cr_tramite
   where op_operacion           = @w_operacionca
   and   or_tramite             = op_tramite
   and   or_finalizo_renovacion = 'S'
   and   or_tramite             = tr_tramite
   union
   select
      'Tramite'            = or_tramite,
      'Tipo'               = tr_tipo, 
      'Operacion'          = or_num_operacion,
      'Monto Original'     = or_monto_original,
      'Saldo Renovado'     = or_saldo_original,
      'Tipo Credito'       = or_toperacion,
      'Funcionario'        = or_login
   from #reestructuras, cob_credito..cr_op_renovar, cob_credito..cr_tramite
   where tramite = or_tramite
   and   or_finalizo_renovacion = 'S'
   and   or_tramite             = tr_tramite

   order by 'Operacion' --or_num_operacion
end

-- INI - REQ 175: PEQUENA EMPRESA
-- CAPITALIZADO
if @i_operacion = 'C'
begin
   if @w_dist_gracia = 'C' and @w_gracia_int > 0
   begin
      select top 50
      dtr_dividendo,
      sum(isnull(dtr_monto,0))
      from ca_transaccion, ca_det_trn
      where tr_operacion   = @w_operacionca
      and   tr_tran        = 'CRC'
      and   tr_estado     <> 'RV'
      and   dtr_operacion  = tr_operacion
      and   dtr_secuencial = tr_secuencial
      and   dtr_concepto   = 'INT'
      and   dtr_dividendo  < @i_dividendo
      group by dtr_dividendo
      order by dtr_dividendo desc
   end
end
-- FIN - REQ 175: PEQUENA EMPRESA
-- INI - JTO - 12/06/2019 IMPLEMENTACION OPERACION H PARA LAS OPERACIONES HIJAS
if @i_operacion = 'H'
begin
SELECT
   'Lin.Credito    '  = substring(a.op_toperacion,1,30),
   'Moneda'            = a.op_moneda,
   'No.Operacion'     = a.op_banco,
   'Monto Operacion'  = convert(float, a.op_monto),
   'Cliente'           = substring(a.op_nombre,1,30),
   'Desembolso'        = convert(varchar(16),a.op_fecha_ini, @i_formato_fecha),
   'Vencimiento'       = convert(varchar(10),a.op_fecha_fin, @i_formato_fecha),
   'Reg/Oficial'       = a.op_oficial,
   'Oficina'           = a.op_oficina,
   'Cup.Credito'      = a.op_lin_credito,
   'Op.Migrada'        = substring(a.op_migrada,1,20),
   'Op.Anterior'       = substring(a.op_anterior,1,20),
   'Estado'            = substring(b.es_descripcion,1,20),
   'Tramite'          = convert(varchar(13),a.op_tramite),
   'Cod.Cli'           = a.op_cliente,
   'Secuencial'        = a.op_operacion,
   'Reaj.Especial'     = a.op_reajuste_especial,
   'Ref.Redescont'     = a.op_nro_red,
   'Clase Oper.'       = a.op_tipo,
   'Grupal'            = '',
   'Categoria'         = ''
FROM ca_operacion a
INNER JOIN ca_estado b ON b.es_codigo = a.op_estado
INNER JOIN ca_det_ciclo c ON c.dc_operacion = a.op_operacion AND c.dc_tciclo = 'N'
WHERE a.op_ref_grupal = @i_banco
end
-- FIN - JTO - 12/06/2019 IMPLEMENTACION OPERACION H PARA LAS OPERACIONES HIJAS
-- INI - JTO - 12/06/2019 IMPLEMENTACION OPERACION Y PARA LAS OPERACIONES INTERCICLAS
if @i_operacion = 'Y'
begin
SELECT
   'Lin.Credito    '  = substring(a.op_toperacion,1,30),
   'Moneda'            = a.op_moneda,
   'No.Operacion'     = a.op_banco,
   'Monto Operacion'  = convert(float, a.op_monto),
   'Cliente'           = substring(a.op_nombre,1,30),
   'Desembolso'        = convert(varchar(16),a.op_fecha_ini, @i_formato_fecha),
   'Vencimiento'       = convert(varchar(10),a.op_fecha_fin, @i_formato_fecha),
   'Reg/Oficial'       = a.op_oficial,
   'Oficina'           = a.op_oficina,
   'Cup.Credito'      = a.op_lin_credito,
   'Op.Migrada'        = substring(a.op_migrada,1,20),
   'Op.Anterior'       = substring(a.op_anterior,1,20),
   'Estado'            = substring(b.es_descripcion,1,20),
   'Tramite'          = convert(varchar(13),a.op_tramite),
   'Cod.Cli'           = a.op_cliente,
   'Secuencial'        = a.op_operacion,
   'Reaj.Especial'     = a.op_reajuste_especial,
   'Ref.Redescont'     = a.op_nro_red,
   'Clase Oper.'       = a.op_tipo,
   'Grupal'            = '',
   'Categoria'         = ''
FROM ca_operacion a
INNER JOIN ca_estado b ON b.es_codigo = a.op_estado
INNER JOIN ca_det_ciclo c ON c.dc_operacion = a.op_operacion AND c.dc_tciclo = 'I'
WHERE a.op_ref_grupal = @i_banco
end
-- FIN - JTO - 12/06/2019 IMPLEMENTACION OPERACION Y PARA LAS OPERACIONES INTERCICLAS
-- INI - JTO - 27/06/2019 IMPLEMENTACION OPERACION W PARA LA CONSULTA DE SEGUROS DE LA OPERACION
if @i_operacion = 'W'
begin
   SELECT 
       'GRUPO'       = a.op_grupo
      ,'OPERACION'   = a.op_operacion
      ,'NO.OPERACION'= a.op_banco
      ,'CLIENTEID'   = d.en_ente
      ,'CLIENTE'     = d.p_p_apellido + ' ' + d.p_s_apellido + ' ' + d.en_nombre
      ,'TIPO SEG ID' = e.so_tipo_seguro
      ,'TIPO SEG DES'= e.so_tipo_seguro + ' - ' + f.valor
      ,'MONTO'       = e.so_monto_seguro
      ,'FECHA INI'   = convert(varchar(10),e.so_fecha_inicial,@i_formato_fecha)
      ,'FECHA_FIN'   = convert(varchar(10),e.so_fecha_fin,@i_formato_fecha)  -- JTO 01/07/2019 - CAMBIO DE SO_PLAZO A SO_FECHA_FIN
      ,'FOLIO'       = e.so_folio
      ,'ESTADO'      = e.so_estado
   FROM cob_cartera..ca_operacion a 
      INNER JOIN cobis..cl_cliente_grupo c ON c.cg_grupo = a.op_grupo AND c.cg_ente = a.op_cliente
      INNER JOIN cobis..cl_ente d ON d.en_ente = c.cg_ente
      INNER JOIN cob_cartera..ca_seguros_op e ON e.so_operacion = a.op_operacion
      INNER JOIN cobis..cl_catalogo f ON f.tabla IN (SELECT codigo FROM cobis..cl_tabla WHERE tabla LIKE 'ca_tipo_seguro' AND estado = 'V') AND f.codigo = e.so_tipo_seguro 
   WHERE (a.op_banco = @i_banco OR a.op_ref_grupal = @i_banco)
   ORDER BY 5 -- ORDENAR POR CLIENTE
end
-- FIN - JTO - 27/06/2019 IMPLEMENTACION OPERACION W PARA LA CONSULTA DE SEGUROS DE LA OPERACION
-- INI - JTO - 27/06/2019 IMPLEMENTACION OPERACION B PARA LA CONSULTA DE BENEFICIARIOS DE SEGUROS DE LA OPERACION
if @i_operacion = 'B'
begin
   select @w_tabla_cod = b.codigo
    from cobis..cl_catalogo a
       INNER JOIN cobis..cl_tabla b ON b.codigo = a.tabla
   where b.tabla = 'cl_parentesco_beneficiario'
   group by b.codigo

   select
      'OPERACION'    = bs_nro_operacion,
      'PRODUCTO'     = bs_producto,
      'SECUENCIA'    = bs_secuencia,
      'TIPO ID.'     = bs_tipo_id,
      'ID.'          = bs_ced_ruc,
      'NOMBRE'       = bs_nombres + ' ' + bs_apellido_paterno +  ' ' + bs_apellido_materno,
      'PORCENTAJE'   = bs_porcentaje,
      'PARENTESCO'   = bs_parentesco + ' - ' + valor,
      'ENTE'         = ISNULL(bs_ente,0),
      'FECHA NAC.'   = convert(varchar(10),bs_fecha_nac,@i_formato_fecha),
      'TELEFONO'     = bs_telefono,
      'DIRECCION'    = bs_direccion + ' ' + pq_descripcion + ' ' + ci_descripcion + ' ' + pv_descripcion, -- + ' CP ' + isnull(bs_codpostal, '-'),
      'CPARENTESCO'  = bs_parentesco,
      'CCODPOSTAL'   = bs_codpostal
      --'CNOMBRE'      = bs_nombres,
      --'CAPELLIDOP'   = bs_apellido_paterno,
      --'CAPELLIDOS'   = bs_apellido_materno,
      --'CDIRECCION'   = bs_direccion,
      --'CPROVINCIA'   = bs_provincia,
      --'CCIUDAD'      = bs_ciudad,
      --'CPARROQUIA'   = bs_parroquia,
      --'AMBOS SEGUROS'= bs_ambos_seguros
   from cobis..cl_beneficiario_seguro a
      INNER JOIN cobis..cl_catalogo e ON e.codigo = a.bs_parentesco AND e.tabla = @w_tabla_cod
      LEFT JOIN cobis..cl_provincia b ON b.pv_provincia = a.bs_provincia
      LEFT JOIN cobis..cl_ciudad c ON c.ci_ciudad = bs_ciudad
      LEFT JOIN cobis..cl_parroquia d ON d.pq_parroquia = bs_parroquia
   where bs_nro_operacion  = @w_operacionca
      and   bs_producto = 7 -- siempre
   order by bs_secuencia
end
-- FIN - JTO - 27/06/2019 IMPLEMENTACION OPERACION B PARA LA CONSULTA DE BENEFICIARIOS DE SEGUROS DE LA OPERACION

return 0

ERROR:

exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_error
return @w_error

go
