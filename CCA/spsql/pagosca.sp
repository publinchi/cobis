/************************************************************************/
/*   Archivo:             pagosca.sp                                    */
/*   Stored procedure:    sp_pagosca                                    */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Credito y Cartera                             */
/*   Disenado por:        Fabian de la Torre                            */
/************************************************************************/
/*                              IMPORTANTE                              */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                              PROPOSITO                               */
/*   Reporte de pagos de Cartera en un rango de fechas.                 */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  22/01/21          P.Narvaez        optimizado para mysql            */
/* **********************************************************************/

use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_pagosca')
   drop proc sp_pagosca
go

---INC 112890 MAY.29.2013

CREATE proc sp_pagosca
@i_param1 varchar(255),   --FECHA DESDE
@i_param2 varchar(255),   --FECHA HASTA
@i_param3 varchar(255)    --PROCESO
as
declare 
@w_fecha_desde     datetime,
@w_fecha_hasta     datetime,
@w_fecha_proceso   datetime,
@w_msg             varchar(255),
@w_sp_name         varchar(30),
@w_error           int,

/* VARIABLES BCP */

@w_sp_name_batch   varchar(30),
@w_s_app           varchar(30),
@w_path            varchar(255),
@w_path_adminfo    varchar(255),      --MAL03282011 REQ.248
@w_nom_plano_adminfo varchar(255),    --MAL03282011 REQ.248
@w_fecha_arch      varchar(10),
@w_hora_arch       varchar(4),
@w_comando         varchar(1000),
@w_nombre_plano    varchar(200),
@w_plano_errores   varchar(200),
@w_cmd             varchar(300),
@w_sp              varchar(40),
@w_cabecera        varchar(400),
@w_fecha_pro_txt   varchar(10),
@w_col_id          int,
@w_columna         varchar(50),
/* VARIABLES BCP */
@w_oficina         int,
@w_proceso         char(1)

set nocount on
set ANSI_WARNINGS OFF

/* VALIDAR PARAMETROS DE ENTRADA */

if @i_param1 is null or @i_param2 is null or @i_param3 is null begin
   select @w_msg = 'ERROR, PARAMETROS DE ENTRADA SIN VALOR O CON VALOR NULO'
   goto ERRORFIN
end

select 
@w_fecha_desde = @i_param1,
@w_fecha_hasta = @i_param2,
@w_proceso     = @i_param3


select @w_fecha_proceso = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7
   
   
if @w_proceso = 'C' begin -- Carga de datos a tabla temporal para luego generar archivos planos


   if @w_fecha_desde > @w_fecha_hasta begin
      select @w_msg = 'ERROR, FECHA DESDE ES MAYOR QUE FECHA HASTA'
      goto ERRORFIN
   end

      if datediff(dd, @w_fecha_desde,@w_fecha_hasta) > 31 begin
      select @w_msg = 'ERROR, NO SE PERMITE UNA CONSULTA DE UN RANGO DE FECHAS MAYOR A UN MES'
      goto ERRORFIN

   end

   truncate table ca_pagosca_v_tmp	
   truncate table ca_pagosca_h_tmp

   select 
   oficina_tran   = tr_ofi_usu, 
   oficina_oper   = tr_ofi_oper, 
   fecha_ing      = convert(varchar(10),tr_fecha_mov,103), 
   secuencial_rpa = convert(int, tr_secuencial_ref),
   fecha_valor    = convert(varchar(10),tr_fecha_ref,103), 
   banco          = tr_banco,
   operacion      = tr_operacion,  
   t_prestamo     = tr_toperacion, 
   secuencial_apl = tr_secuencial,
   forma_pago     = convert(varchar(10),'NO APLICA'),
   tipo_reverso   = case when tr_estado = 'RV' then 'A' else '' end
   into #pagos_pag
   from ca_transaccion with (index = ca_transaccion_3 nolock)
   where tr_tran       = 'PAG'
   and   tr_fecha_mov  >= @w_fecha_desde and tr_fecha_mov <= @w_fecha_hasta 
   create index idx1 on #pagos_pag (operacion, secuencial_apl)

   select 
   operacion_t      = operacion,
   secuencial_apl_t = secuencial_apl,
   cuota_t          = dtr_dividendo,
   concepto_t       = case when dtr_codvalor % 10 = 7 then 'COND_' + dtr_concepto else dtr_concepto end,
   ref_contable_t   = dtr_codvalor,
   monto_t          = case when secuencial_apl  < 0     then dtr_monto * -1         else dtr_monto    end
   into #pagos_tr
   from ca_det_trn with (index = ca_det_trn_1 nolock) , #pagos_pag
   where dtr_operacion = operacion
   and   dtr_secuencial = secuencial_apl
   and   dtr_codvalor   > 1000
   and   dtr_estado <> 8 ---No incluir los diferidos 
   

   select 
   oficina_tran, 
   oficina_oper, 
   fecha_ing ,
   secuencial_rpa ,
   fecha_valor ,
   banco ,
   operacion  ,
   t_prestamo ,
   secuencial_apl ,
   cuota        = cuota_t  ,
   concepto     = concepto_t,
   ref_contable = ref_contable_t ,
   monto        = monto_t,        
   forma_pago  ,
   tipo_reverso
   into #pagos
   from #pagos_tr, #pagos_pag
   where operacion      = operacion_t
   and   secuencial_apl = secuencial_apl_t

   create index idx1 on #pagos (operacion, secuencial_apl)
   create index idx2 on #pagos (secuencial_rpa)
  
   /* RECONOCER LOS PAGOS CON TRANSACCION DE REVERSO */
   update #pagos set
   tipo_reverso = 'R'
   from ca_transaccion with (nolock, index (ca_transaccion_1))
   where tr_operacion  = operacion
   and   tr_secuencial = secuencial_apl * -1
   and   tipo_reverso  = 'A'

   /* EVITAR REPORTAR LOS PAGOS ANULADOS (REVERSADOS EL MISMO DIA) */

   delete #pagos where tipo_reverso = 'A'
   /* DETERMINAR EL SECUENCIAL RPA DE LAS OPERACIONES REVERSADAS */
   update #pagos set
   secuencial_rpa = tr_secuencial_ref
   from ca_transaccion with (nolock, index (ca_transaccion_1))
   where tr_operacion   = operacion
   and   tr_secuencial  = secuencial_apl * -1
   and   secuencial_apl < 0

   /*DETERMINAR LA FORMA DE PAGO Y LA FECHA DEL PAGO AL SISTEMA */

   update #pagos set
   fecha_valor    = convert(varchar(10),ab_fecha_ing,103),
   forma_pago     = abd_concepto
   from ca_abono, ca_abono_det
   where  ab_operacion       = operacion
   and    ab_secuencial_rpa  = secuencial_rpa
   and    abd_operacion      = ab_operacion
   and    abd_secuencial_ing = ab_secuencial_ing
   and    abd_tipo           = 'PAG'
 
   /* CARGAR LOS RESULTADOS OBTENIDOS A LA TABLA DE REPORTE FINAL */

   insert into ca_pagosca_v_tmp
   select
   oficina_tran,    oficina_oper,      fecha_ing, 
   secuencial_rpa,  fecha_valor,       banco,
   operacion,       t_prestamo,        secuencial_apl,    
   cuota,           concepto,          ref_contable,      
   monto,           forma_pago
   from #pagos

   if @@error <> 0 begin
      select @w_msg = 'ERROR AL GENERAR EL INFORME EN LA TABLA ca_pagosca_v_tmp '
      goto ERRORFIN
   end

    

   /* GENERAR EL FORMATO HORIZONTAL DEL REPORTE DE PAGOS */

   insert into ca_pagosca_h_tmp
   select 
   banco,
   operacion,
   fecha_ing,
   fecha_valor,
   t_prestamo,
   forma_pago,
   secuencial_apl, 
   capital           = sum(case when concepto = 'CAP'        then monto else 0 end),
   interes           = sum(case when concepto = 'INT'        then monto else 0 end),
   mora              = sum(case when concepto = 'IMO'        then monto else 0 end),
   mipymes           = sum(case when concepto = 'MIPYMES'    then monto else 0 end),
   iva_mipymes       = sum(case when concepto = 'IVAMIPYMES' then monto else 0 end),
   seguro            = sum(case when concepto in ('SEGDEUVEN','SEGDEUEM','MICROSEG','EXEQUIAL') then monto else 0 end),
   otros             = sum(case when concepto not like 'COND_%' and concepto not in ('HONABO','IVAHONOABO','CAP','INT', 'IMO','MIPYMES','IVAMIPYMES', 'SEGDEUVEN','SEGDEUEM','MICROSEG','EXEQUIAL') then monto else 0 end),
   monto_condonado   = sum(case when concepto like 'COND_%'  then monto*-1 else 0 end),
   subtotal          = sum(case when concepto not like 'COND_%' and concepto not in ('HONABO','IVAHONOABO') then monto else 0 end) -
                       sum(case when concepto like 'COND_%'  then monto else 0 end),
   honorario         = sum(case when concepto = 'HONABO'     then monto else 0 end),
   iva_honorario     = sum(case when concepto = 'IVAHONOABO' then monto else 0 end),
   total             = sum(monto) - sum(case when concepto like 'COND_%'  then 2*monto else 0 end),
   abogado           = case when secuencial_apl < 0 then 'REVERSO' else '' end,
   estado            = 'NO',
   porc_honorarios   = 0.00,
   sobrantes         = sum(case when forma_pago = 'SOB' then monto else 0 end),
   pago_total        = sum(case when concepto not like 'COND_%' then monto else 0 end),
   pago_sin_hon_cond = sum(case when concepto not like 'COND_%' and concepto not in ('HONABO','IVAHONOABO') then monto else 0 end), 
   cod_abogado       = 0,
   iden_abogado      = convert(varchar(30),''),
   regimen_abogado   = convert(varchar(4),''),
   calificacion      = ' ',
   oficina_tramite   = 0,
   est_cartera_act   = 0,
   est_cartera_ant   = 0
   from ca_pagosca_v_tmp
   group by banco, operacion, fecha_ing, fecha_valor, t_prestamo, forma_pago,secuencial_apl

   if @@error <> 0 begin
      select @w_msg = 'ERROR AL GENERAR EL INFORME EN LA TABLA ca_pagosca_h_tmp '
      goto ERRORFIN
   end
   
   ---INC. 23810 Quitar las formas de pago queno deben ser freflejadas en el reporte
	delete ca_pagosca_h_tmp 
	from cob_credito..cr_corresp_sib,ca_pagosca_h_tmp,cob_cartera..ca_abono,cob_cartera..ca_abono_det
	where tabla = 'T123'
	and  t_prestamo = codigo_sib
	and ab_operacion = operacion
	and ab_secuencial_pag = secuencial_apl
	and ab_operacion = abd_operacion
	and ab_secuencial_ing = abd_secuencial_ing
	and abd_concepto = codigo

   -- Estado Cobranza y Estado anterior cartera
   update ca_pagosca_h_tmp set
   estado          = isnull(oph_estado_cobranza, 'NO'),
   est_cartera_ant = oph_estado
   from ca_operacion_his
   where oph_operacion  = operacion
   and   oph_secuencial = secuencial_apl

   if @@error <> 0 begin
      select @w_msg = 'ERROR AL CONSULTAR EL ESTADO DE LA COBRANZA'
      goto ERRORFIN
   end

   -- Estado Cobranza
   update ca_pagosca_h_tmp set
   abogado         = isnull('('+ab_tipo+') '+ ab_nombre, ''),
   cod_abogado     = ab_abogado,
   iden_abogado    = ab_id_abogado,
   porc_honorarios = round(((honorario + iva_honorario) * 100) / pago_total ,2)
   from cob_credito..cr_operacion_cobranza, cob_credito..cr_cobranza, cob_credito..cr_abogado
   where oc_cobranza      = co_cobranza
   and   co_abogado       = ab_abogado
   and   oc_codprod       = 7
   and   oc_num_operacion = banco

   -- Estado actual cartera -- Tramite

   update ca_pagosca_h_tmp set
   est_cartera_act = op_estado,
   oficina_tramite = op_oficina,
   calificacion    = isnull(op_calificacion, 'A')
   from ca_operacion
   where op_operacion  = operacion

   if @@error <> 0 begin
      select @w_msg = 'ERROR AL CONSULTAR EL NOMBRE DEL ABOGADO'
      goto ERRORFIN
   end
   -- Regimen fiscal
   update ca_pagosca_h_tmp set
   regimen_abogado = rf_codigo
   from cobis..cl_ente, cob_conta..cb_regimen_fiscal, cob_credito..cr_abogado
   where cod_abogado  = en_ente
   and   en_asosciada = rf_codigo
end -- @w_proceso = 'C'

if @w_proceso = 'D' begin -- Carga de datos a tabla temporal para luego generar archivos planos
   
   delete cob_cartera..ca_pagosca_v_tmp
   where fecha_ing = convert(varchar(10), @w_fecha_proceso, 103)

   delete cob_cartera..ca_pagosca_h_tmp
   where fecha_ing = convert(varchar(10), @w_fecha_proceso, 103)
     
   select 
   oficina_tran   = tr_ofi_usu, 
   oficina_oper   = tr_ofi_oper, 
   fecha_ing      = convert(varchar(10),tr_fecha_mov,103), 
   secuencial_rpa = convert(int, tr_secuencial_ref),
   fecha_valor    = convert(varchar(10),tr_fecha_ref,103), 
   banco          = tr_banco,
   operacion      = tr_operacion,  
   t_prestamo     = tr_toperacion, 
   secuencial_apl = tr_secuencial,
   forma_pago     = convert(varchar(10),'NO APLICA'),
   tipo_reverso   = case when tr_estado = 'RV' then 'A' else '' end
   into #pagos_pag1
   from ca_transaccion with (index (ca_transaccion_3) nolock)
   where tr_tran       = 'PAG'
   and   tr_fecha_mov  = @w_fecha_proceso

   create index idx1 on #pagos_pag1 (operacion, secuencial_apl)

   print @w_fecha_proceso
   select * from #pagos_pag1
   
   select 
   operacion_t      = operacion,
   secuencial_apl_t = secuencial_apl,
   cuota_t          = dtr_dividendo,
   concepto_t       = case when dtr_codvalor % 10 = 7 then 'COND_' + dtr_concepto else dtr_concepto end,
   ref_contable_t   = dtr_codvalor,
   monto_t          = case when secuencial_apl  < 0     then dtr_monto * -1         else dtr_monto    end
   into #pagos_tr1
   from ca_det_trn with (index (ca_det_trn_1) nolock) , #pagos_pag1
   where dtr_operacion = operacion
   and   dtr_secuencial = secuencial_apl
   and   dtr_codvalor   > 1000
   and   dtr_estado <> 8
   
   select 
   oficina_tran, 
   oficina_oper, 
   fecha_ing ,
   secuencial_rpa ,
   fecha_valor ,
   banco ,
   operacion  ,
   t_prestamo ,
   secuencial_apl ,
   cuota        = cuota_t  ,
   concepto     = concepto_t,
   ref_contable = ref_contable_t ,
   monto        = monto_t,
   forma_pago  ,
   tipo_reverso
   into #pagos1
   from #pagos_tr1, #pagos_pag1
   where operacion      = operacion_t
   and   secuencial_apl = secuencial_apl_t

   create index idx1 on #pagos1 (operacion, secuencial_apl)
   create index idx2 on #pagos1 (secuencial_rpa)
  
   /* RECONOCER LOS PAGOS CON TRANSACCION DE REVERSO */
   update #pagos1 set
   tipo_reverso = 'R'
   from ca_transaccion with (nolock, index (ca_transaccion_1))
   where tr_operacion  = operacion
   and   tr_secuencial = secuencial_apl * -1
   and   tipo_reverso  = 'A'

   /* EVITAR REPORTAR LOS PAGOS ANULADOS (REVERSADOS EL MISMO DIA) */

   delete #pagos1 where tipo_reverso = 'A'
   /* DETERMINAR EL SECUENCIAL RPA DE LAS OPERACIONES REVERSADAS */
   update #pagos1 set
   secuencial_rpa = tr_secuencial_ref
   from ca_transaccion with (nolock, index (ca_transaccion_1))
   where tr_operacion   = operacion
   and   tr_secuencial  = secuencial_apl * -1
   and   secuencial_apl < 0

   /*DETERMINAR LA FORMA DE PAGO Y LA FECHA DEL PAGO AL SISTEMA */

   update #pagos1 set
   fecha_valor      = convert(varchar(10),ab_fecha_ing,103),
   forma_pago       = abd_concepto
   from ca_abono, ca_abono_det
   where  ab_operacion       = operacion
   and    ab_secuencial_rpa  = secuencial_rpa
   and    abd_operacion      = ab_operacion
   and    abd_secuencial_ing = ab_secuencial_ing
   and    abd_tipo           = 'PAG'
 
   /* CARGAR LOS RESULTADOS OBTENIDOS A LA TABLA DE REPORTE FINAL */

   insert into ca_pagosca_v_tmp
   select
   oficina_tran,    oficina_oper,      fecha_ing, 
   secuencial_rpa,  fecha_valor,       banco,
   operacion,       t_prestamo,        secuencial_apl,
   cuota,           concepto,          ref_contable,
   monto,           forma_pago
   from #pagos1

   if @@error <> 0 begin
      select @w_msg = 'ERROR AL GENERAR EL INFORME EN LA TABLA ca_pagosca_v_tmp '
      goto ERRORFIN
   end
   
   /* GENERAR EL FORMATO HORIZONTAL DEL REPORTE DE PAGOS */

   insert into ca_pagosca_h_tmp
   select 
   banco,
   operacion,
   fecha_ing,
   fecha_valor,
   t_prestamo,
   forma_pago,
   secuencial_apl, 
   capital           = sum(case when concepto = 'CAP'        then monto else 0 end),
   interes           = sum(case when concepto = 'INT'        then monto else 0 end),
   mora              = sum(case when concepto = 'IMO'        then monto else 0 end),
   mipymes           = sum(case when concepto = 'MIPYMES'    then monto else 0 end),
   iva_mipymes       = sum(case when concepto = 'IVAMIPYMES' then monto else 0 end),
   seguro            = sum(case when concepto in ('SEGDEUVEN','SEGDEUEM','MICROSEG','EXEQUIAL') then monto else 0 end),
   otros             = sum(case when concepto not like 'COND_%' and concepto not in ('HONABO','IVAHONOABO','CAP','INT', 'IMO','MIPYMES','IVAMIPYMES', 'SEGDEUVEN','SEGDEUEM','MICROSEG','EXEQUIAL') then monto else 0 end),
   monto_condonado   = sum(case when concepto like 'COND_%'  then monto*-1 else 0 end),
   subtotal          = sum(case when concepto not like 'COND_%' and concepto not in ('HONABO','IVAHONOABO') then monto else 0 end) -
                       sum(case when concepto like 'COND_%'  then monto else 0 end),
   honorario         = sum(case when concepto = 'HONABO'     then monto else 0 end),
   iva_honorario     = sum(case when concepto = 'IVAHONOABO' then monto else 0 end),
   total             = sum(monto) - sum(case when concepto like 'COND_%'  then 2*monto else 0 end),
   abogado           = case when secuencial_apl < 0 then 'REVERSO' else '' end,
   estado            = 'NO',
   porc_honorarios   = 0.00,
   sobrantes         = sum(case when forma_pago = 'SOB' then monto else 0 end),
   pago_total        = sum(case when concepto not like 'COND_%' then monto else 0 end),
   pago_sin_hon_cond = sum(case when concepto not like 'COND_%' and concepto not in ('HONABO','IVAHONOABO') then monto else 0 end), 
   cod_abogado       = 0,
   iden_abogado      = convert(varchar(30),''),
   regimen_abogado   = convert(varchar(4),''),
   calificacion      = ' ',
   oficina_tramite   = 0,
   est_cartera_act   = 0,
   est_cartera_ant   = 0
   from ca_pagosca_v_tmp
   where fecha_ing = convert(varchar(10), @w_fecha_proceso, 103)
   group by banco, operacion, fecha_ing, fecha_valor, t_prestamo, forma_pago,secuencial_apl

   if @@error <> 0 begin
      select @w_msg = 'ERROR AL GENERAR EL INFORME EN LA TABLA ca_pagosca_h_tmp '
      goto ERRORFIN
   end
   
   ---INC. 23810 Quitar las formas de pago queno deben ser freflejadas en el reporte
	delete ca_pagosca_h_tmp 
	from cob_credito..cr_corresp_sib,ca_pagosca_h_tmp,cob_cartera..ca_abono,cob_cartera..ca_abono_det
	where tabla           = 'T123'
	and  t_prestamo       = codigo_sib
	and ab_operacion      = operacion
	and ab_secuencial_pag = secuencial_apl
	and ab_operacion      = abd_operacion
	and ab_secuencial_ing = abd_secuencial_ing
	and abd_concepto      = codigo

   -- Estado Cobranza y Estado anterior cartera
   update ca_pagosca_h_tmp set
   estado          = isnull(oph_estado_cobranza, 'NO'),
   est_cartera_ant = oph_estado
   from ca_operacion_his
   where oph_operacion  = operacion
   and   oph_secuencial = secuencial_apl

   if @@error <> 0 begin
      select @w_msg = 'ERROR AL CONSULTAR EL ESTADO DE LA COBRANZA'
      goto ERRORFIN
   end

   -- Estado Cobranza
   update ca_pagosca_h_tmp set
   abogado         = isnull('('+ab_tipo+') '+ ab_nombre, ''),
   cod_abogado     = ab_abogado,
   iden_abogado    = ab_id_abogado,
   porc_honorarios = round(((honorario + iva_honorario) * 100) / pago_total ,2)
   from cob_credito..cr_operacion_cobranza, cob_credito..cr_cobranza, cob_credito..cr_abogado
   where oc_cobranza      = co_cobranza
   and   co_abogado       = ab_abogado
   and   oc_codprod       = 7
   and   oc_num_operacion = banco

   -- Estado actual cartera -- Tramite

   update ca_pagosca_h_tmp set
   est_cartera_act = op_estado,
   oficina_tramite = op_oficina,
   calificacion    = isnull(op_calificacion, 'A')
   from ca_operacion
   where op_operacion  = operacion

   if @@error <> 0 begin
      select @w_msg = 'ERROR AL CONSULTAR EL NOMBRE DEL ABOGADO'
      goto ERRORFIN
   end
   -- Regimen fiscal
   update ca_pagosca_h_tmp set
   regimen_abogado = rf_codigo
   from cobis..cl_ente, cob_conta..cb_regimen_fiscal, cob_credito..cr_abogado
   where cod_abogado  = en_ente
   and   en_asosciada = rf_codigo
end -- @w_proceso = 'C'

if @w_proceso = 'G' begin -- Generar archivos planos con el cargue de la data realizada

   /*******************************************/
   /****GENERAR LOS ARCHIVOS PLANOS POR BCP****/
   /*******************************************/
 
   select 
   @w_fecha_pro_txt = convert(varchar,@w_fecha_hasta, 101),
   @w_fecha_arch    = substring(convert(varchar(10),@w_fecha_pro_txt),1,2)+ substring(convert(varchar(10),@w_fecha_pro_txt),4,2)+substring(convert(varchar(10),@w_fecha_pro_txt),7,4),
   @w_hora_arch     = substring(convert(varchar,GetDate(),108),1,2) + substring(convert(varchar,GetDate(),108),4,2),
   @w_sp_name       = 'sp_pagosca',
   @w_sp_name_batch = 'cob_cartera..sp_pagosca'

   /* RUTA DE DESTINO DEL ARCHIVO A GENERAR */
   select @w_path = ba_path_destino
   from cobis..ba_batch
   where ba_arch_fuente = @w_sp_name_batch
   
   if @@rowcount = 0 begin
      select @w_error = 2101084, @w_msg = 'ERROR EN LA BUSQUEDA DEL PATH EN LA TABLA ba_batch'
      goto ERRORFIN
   end
   
   /* RUTA DESTINO PARA ARCHIVO DE ADMINFO */    --MAL03282011 REQ.248
   select @w_path_adminfo = ba_path_destino
   from cobis..ba_batch
   where ba_batch = 21447
   
   if @@rowcount = 0 begin
      select @w_error = 2101085, @w_msg = 'ERROR AL OBTENER EL PATH DESTINO PARA ARCHIVO DE ADMINFO'
      goto ERRORFIN
   end         

   /* OBTENIENDO EL PARAMETRO DE LA UBIACION DEL kernel\bin EN EL SERVIDOR*/
   select @w_s_app   = pa_char
   from cobis..cl_parametro
   where pa_producto = 'ADM'
   and   pa_nemonico = 'S_APP'

   if @@rowcount = 0 begin
      select @w_error = 2101084, @w_msg = 'ERROR AL OBTENER EL PARAMETRO GENERAL S_APP DE ADM'
      goto ERRORFIN
   end

   /************ PAGOSCA VERTICAL *************/
   /************   CONSOLIDADO    *************/

   select
   @w_nombre_plano  = @w_path + 'ca_pagosca_v_'+@w_fecha_arch+'_'+@w_hora_arch+'.txt',
   @w_plano_errores = @w_path + 'ca_pagosca_v_' + replace(convert(varchar, @w_hora_arch, 102), '.', '') + '_' + replace(convert(varchar, getdate(), 108), ':', '') + '.err',
   @w_cmd           = @w_s_app + 's_app bcp -auto -login cob_cartera..ca_pagosca_v_tmp out ',
   @w_comando       = @w_cmd + @w_path +'ca_pagosca_v.txt -c -e' + @w_plano_errores + ' -t"|" ' + '-config '+ @w_s_app + 's_app.ini'
   exec @w_error = xp_cmdshell @w_comando

   if @w_error <> 0 begin
      select @w_error = 2902797, @w_msg = 'EJECUCION comando bcp FALLIDA. REVIZAR ARCHIVOS DE LOG GENERADOS.'
      print @w_comando
      goto ERRORFIN
   end
   else begin
      select @w_comando = 'del ' + @w_plano_errores
      exec @w_error = xp_cmdshell @w_comando
      if @w_error <> 0 begin
         select @w_error = 2902797, @w_msg = 'EJECUCION comando Borrado FALLIDA. REVIZAR ARCHIVOS DE LOG GENERADOS.'
         print @w_comando
         goto ERRORFIN
      end
   end

   --Generar Archivo de Cabeceras  
   select @w_col_id   = 0,
          @w_columna  = '',
          @w_cabecera = ''
   while 1 = 1 begin
      set rowcount 1
      select @w_columna = c.name,
             @w_col_id  = c.colid
      from sysobjects o, syscolumns c
      where o.id    = c.id
      and   o.name  = 'ca_pagosca_v_tmp'
      and   c.colid > @w_col_id
      order by c.colid
      if @@rowcount = 0 begin
         set rowcount 0
         break
      end
      select @w_cabecera = @w_cabecera + @w_columna + '^|'
   end


   --Escribir Cabecera
   select @w_comando = 'echo ' + @w_cabecera + ' > ' + @w_nombre_plano
   exec @w_error = xp_cmdshell @w_comando
   if @w_error <> 0 begin
       select @w_error = 2902797, @w_msg = 'EJECUCION comando bcp FALLIDA. REVIZAR ARCHIVOS DE LOG GENERADOS.'
       goto ERRORFIN
   end
   
   select @w_comando = 'copy ' + @w_nombre_plano + ' + ' + @w_path + 'ca_pagosca_v.txt ' + @w_nombre_plano
   exec @w_error = xp_cmdshell @w_comando
   if @w_error <> 0 begin
       select @w_error = 2902797, @w_msg = 'EJECUCION comando bcp FALLIDA. REVIZAR ARCHIVOS DE LOG GENERADOS.'
       goto ERRORFIN
   end
         
   /************ PAGOSCA HORIZONTAL *************/
   /************    CONSOLIDADO     *************/      
   
   select
   @w_nombre_plano  = @w_path + 'ca_pagosca_h_'+@w_fecha_arch+'_'+@w_hora_arch+'.txt',
   @w_plano_errores = @w_path + 'ca_pagosca_h_' + replace(convert(varchar, @w_hora_arch, 102), '.', '') + '_' + replace(convert(varchar, getdate(), 108), ':', '') +'.err',
   @w_cmd           = @w_s_app + 's_app bcp -auto -login cob_cartera..ca_pagosca_h_tmp out ',
   @w_comando       = @w_cmd + @w_path +'ca_pagosca_h.txt -c -e' + @w_plano_errores + ' -t"|" ' + '-config '+ @w_s_app + 's_app.ini'

   exec @w_error = xp_cmdshell @w_comando
   if @w_error <> 0 begin
       select @w_error = 2902797, @w_msg = 'EJECUCION comando bcp FALLIDA. REVIZAR ARCHIVOS DE LOG GENERADOS.'
       goto ERRORFIN
   end
   else begin
      select @w_comando = 'del ' + @w_plano_errores
      exec @w_error = xp_cmdshell @w_comando
      
      if @w_error <> 0 begin
         select @w_error = 2902797, @w_msg = 'EJECUCION comando Borrado FALLIDA. REVIZAR ARCHIVOS DE LOG GENERADOS.'
         print @w_comando
         goto ERRORFIN
      end
   end

   --Generar Archivo de Cabeceras
   select @w_col_id   = 0,
          @w_columna  = '',
          @w_cabecera = ''
   while 1 = 1 begin
      set rowcount 1
      select @w_columna = c.name,
             @w_col_id  = c.colid
      from sysobjects o, syscolumns c
      where o.id    = c.id
      and   o.name  = 'ca_pagosca_h_tmp'
      and   c.colid > @w_col_id
      order by c.colid

      if @@rowcount = 0 begin
         set rowcount 0
         break
      end
      select @w_cabecera = @w_cabecera + @w_columna + '^|'
   end
   
   --Escribir Cabecera
   select @w_comando = 'echo ' + @w_cabecera + ' > ' + @w_nombre_plano
   exec @w_error = xp_cmdshell @w_comando
   
   if @w_error <> 0 begin
       select @w_error = 2902797, @w_msg = 'EJECUCION comando bcp FALLIDA. REVIZAR ARCHIVOS DE LOG GENERADOS.'
       goto ERRORFIN
   end
   
   select @w_comando = 'copy ' + @w_nombre_plano + ' + ' + @w_path + 'ca_pagosca_h.txt ' + @w_nombre_plano
   exec @w_error = xp_cmdshell @w_comando
   
   if @w_error <> 0 begin
       select @w_error = 2902797, @w_msg = 'EJECUCION comando bcp FALLIDA. REVIZAR ARCHIVOS DE LOG GENERADOS.'
       goto ERRORFIN
   end
 
   /* CREACION DE ARCHIVO ADMINFO, MAL03282011 REQ-248 */  
      
   --Creacion del nombre archivo adminfo
   --select @w_nom_plano_adminfo = @w_path_adminfo + 'adminfo\arch_envio_proceso\ca_pagosca_h_' + @w_fecha_arch + '_' + @w_hora_arch + '.txt' 
     select @w_nom_plano_adminfo = @w_path_adminfo + 'adminfo\arch_envio_proceso\ca_pagosca_h_' + @w_fecha_arch + '.txt' 
     
   --Creacion del Archivo
   select @w_comando = 'copy ' + @w_nombre_plano + ' ' + @w_nom_plano_adminfo
   exec @w_error = xp_cmdshell @w_comando
   if @w_error <> 0 begin
       select @w_error = 2101086, @w_msg = 'ERROR AL TRATSR DE COPIAR ARCHIVO DE ADMINFO'
       goto ERRORFIN
   end

   --Borrado de nombre del archivo para la creacion desde el SQR
   delete cob_cartera..ca_path_adminfo
   where pa_ruta_archivo >= ''

   --Creacion de nombre del archivo para la creacion desde el SQR   
   --insert into  cob_cartera..ca_path_adminfo values ('ca_pagosca_h_' + @w_fecha_arch + '_' + @w_hora_arch + '.txt')
   insert into  cob_cartera..ca_path_adminfo values ('ca_pagosca_h_' + @w_fecha_arch + '.txt')  
     
   if @@error <> 0 begin
      select @w_msg = 'ERROR NO SE PUDO GENERAR LA RUTA DEL ARCHIVO DEL ADMINFO'
      goto ERRORFIN
   end     
   
   -- Solamente dejar el archivo definitivo

   select @w_comando = 'del ' + @w_path +  'ca_pagosca_h.txt'
   exec @w_error = xp_cmdshell @w_comando

   if @w_error <> 0 begin
       select @w_error = 2902797, @w_msg = 'EJECUCION comando Borrado FALLIDA. REVIZAR ARCHIVOS DE LOG GENERADOS.'
       print @w_comando
       goto ERRORFIN
   end
   
   select @w_comando = 'del ' + @w_path +  'ca_pagosca_v.txt'   
   exec @w_error = xp_cmdshell @w_comando
   if @w_error <> 0 begin
       select @w_error = 2902797, @w_msg = 'EJECUCION comando Borrado FALLIDA. REVIZAR ARCHIVOS DE LOG GENERADOS.'
       print @w_comando
       goto ERRORFIN
   end

   select distinct oficina= oficina_oper , estado= 'I' into #oficinas 
   from cob_cartera..ca_pagosca_v_tmp 
   order by oficina_oper
   
   while 1 = 1 begin -- While Oficinas
      select @w_oficina = oficina
      from #oficinas 
      where estado = 'I'
      
      if @@rowcount = 0 begin
         set rowcount 0
         break
      end
      
      set rowcount 0

      truncate table cob_cartera..ca_pagosca_h_tmp_bcp 
     
      /************ PAGOSCA HORIZONTAL *************/

      /************    POR OFICINA     *************/      
     
      insert into cob_cartera..ca_pagosca_h_tmp_bcp 
      select * from cob_cartera..ca_pagosca_h_tmp
      where oficina_tramite = @w_oficina 

      select
      @w_nombre_plano  = @w_path + 'ca_pagosca_h_'+@w_fecha_arch+'_'+@w_hora_arch+'_'+convert(varchar,@w_oficina)+'.txt',
      @w_plano_errores = @w_path + 'ca_pagosca_h_' + replace(convert(varchar, @w_hora_arch, 102), '.', '') + '_' + replace(convert(varchar, getdate(), 108), ':', '') +'_'+convert(varchar,@w_oficina)+'.err',
      @w_cmd           = @w_s_app + 's_app bcp -auto -login cob_cartera..ca_pagosca_h_tmp_bcp out ',
      @w_comando       = @w_cmd + @w_path +'ca_pagosca_h.txt -c -e' + @w_plano_errores + ' -t"|" ' + '-config '+ @w_s_app + 's_app.ini'
      exec @w_error = xp_cmdshell @w_comando

      if @w_error <> 0 begin
         select @w_error = 2902797, @w_msg = 'EJECUCION comando bcp FALLIDA. REVIZAR ARCHIVOS DE LOG GENERADOS.'
         goto ERRORFIN
      end

      else begin

         select @w_comando = 'del ' + @w_plano_errores

         exec @w_error = xp_cmdshell @w_comando

         if @w_error <> 0 begin

            select @w_error = 2902797, @w_msg = 'EJECUCION comando Borrado FALLIDA. REVIZAR ARCHIVOS DE LOG GENERADOS.'

            print @w_comando

            goto ERRORFIN
         end
      end
      
      --Escribir Cabecera

      select @w_comando = 'echo ' + @w_cabecera + ' > ' + @w_nombre_plano

      exec @w_error = xp_cmdshell @w_comando

      if @w_error <> 0 begin
         select @w_error = 2902797, @w_msg = 'EJECUCION comando bcp FALLIDA. REVIZAR ARCHIVOS DE LOG GENERADOS.'
         goto ERRORFIN
      end
      
      select @w_comando = 'copy ' + @w_nombre_plano + ' + ' + @w_path + 'ca_pagosca_h.txt ' + @w_nombre_plano
      exec @w_error = xp_cmdshell @w_comando
      if @w_error <> 0 begin
         select @w_error = 2902797, @w_msg = 'EJECUCION comando bcp FALLIDA. REVIZAR ARCHIVOS DE LOG GENERADOS.'
         goto ERRORFIN
      end
      
      update #oficinas 
      set estado = 'P'
      where oficina = @w_oficina 
      and   estado = 'I'
   
   end -- while oficinas



   -- Solamente dejar el archivo definitivo



   select @w_comando = 'del ' + @w_path +  'ca_pagosca_h.txt'

   exec @w_error = xp_cmdshell @w_comando

   if @w_error <> 0 begin

      select @w_error = 2902797, @w_msg = 'EJECUCION comando Borrado FALLIDA. REVIZAR ARCHIVOS DE LOG GENERADOS.'

      print @w_comando

      goto ERRORFIN
   end

end -- @w_proceso = 'G'
   
return 0

ERRORFIN:

exec sp_errorlog 
@i_fecha       = @w_fecha_proceso,
@i_error       = 7999, 
@i_usuario     = 'OPERADOR', 
@i_tran        = 7999,
@i_tran_name   = 'sp_pagosca',
@i_cuenta      = '',
@i_rollback    = 'N',
@i_descripcion = @w_msg
print @w_msg

return 1
go


