/************************************************************************/
/*   Nombre Fisico:                  extclint.sp                       	*/
/*   Nombre Logico:                  sp_extracto_linea_int             	*/
/*   Base de Datos:                  cob_cartera                       	*/
/*   Producto:                       Cartera                           	*/
/*   Disenado por:                   Elcira Pelaez                     	*/
/*   Fecha de Documentacion:         Dic-2002                          	*/
/************************************************************************/
/*                                 IMPORTANTE                          	*/
/*   Este programa es parte de los paquetes bancarios que son       	*/
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  	*/
/*   representantes exclusivos para comercializar los productos y   	*/
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida 	*/
/*   y regida por las Leyes de la República de España y las         	*/
/*   correspondientes de la Unión Europea. Su copia, reproducción,  	*/
/*   alteración en cualquier sentido, ingeniería reversa,           	*/
/*   almacenamiento o cualquier uso no autorizado por cualquiera    	*/
/*   de los usuarios o personas que hayan accedido al presente      	*/
/*   sitio, queda expresamente prohibido; sin el debido             	*/
/*   consentimiento por escrito, de parte de los representantes de  	*/
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  	*/
/*   en el presente texto, causará violaciones relacionadas con la  	*/
/*   propiedad intelectual y la confidencialidad de la información  	*/
/*   tratada; y por lo tanto, derivará en acciones legales civiles  	*/
/*   y penales en contra del infractor según corresponda. 				*/
/************************************************************************/  
/*                                 PROPOSITO                           	*/
/*   Generar la informacion necesaria para el                          	*/
/*      extracto en linea del cliente                                  	*/
/**********************************************************************	*/  
/*                         MODIFICACIONES                              	*/
/*  FECHA            AUTOR           RAZON                             	*/
/*  17/Ene/2003      Luis Mayorga    Dar funcionalidad procedimiento   	*/
/*  07/Jun/2005      Elcira Pelaez   defecto 3673 BAC                  	*/
/*  16/Jun/2005      Elcira Pelaez   defecto 3817 BAC                  	*/
/*  FEB 17 2006      Elcira Pelaez   CXCINTES  NR 379                  	*/ 
/*  29/Mar/2006      Elcira Pelaez   defecto 3212 BAC                  	*/
/*  19/Abr/2006      Elcira Pelaez   defecto 6359 BAC                  	*/
/*  04/May/2006      Elcira Pelaez   NR-296                            	*/
/*  18/May/2006      Elcira Pelaez   DEF. 6212                         	*/
/*  27/sep/06        SLievano -SLI   adicion fecha_ini_mora            	*/
/*  JUL 30 2007      Elcira Pelaez   DEF-8525 dias mora                	*/
/*  FEB-18-2021      K. Rodríguez    Se comenta uso de concepto CXCINTES*/
/*    06/06/2023	 M. Cordova		 Cambio variable @w_op_calificacion */
/*									 de char(1) a catalogo				*/
/************************************************************************/

use cob_cartera
go 

if exists(select 1 from cob_cartera..sysobjects where name = 'sp_extracto_linea_int')
   drop proc sp_extracto_linea_int
go

create proc sp_extracto_linea_int(
        @s_user            login,
        @s_date            datetime,
        @i_operacion       char(1),
        @i_cliente         int = null
)
as declare @w_sp_name                           varchar(20),
           @w_tasa_mercado                       varchar(10),
           @w_puntos_c                          varchar(10),
           @w_tipo_garantia                    varchar(30),
           @w_des_tipo_garantia                 varchar(64),
           @w_des_clase_garantia               varchar(64),         
           @w_des_tipo_bien                     varchar(64),
           @w_tasa_pactada                       varchar(20),
           @w_detalle_ac                       varchar(15),
           @w_detalle_id                       varchar(15),
           @w_detalle_garantia                 varchar(64),
           @w_nombre_codeudor                    varchar(35),
           @w_clase_garantia                    char(1),         
           @w_op_calificacion                    catalogo,
           @w_signo                              char(1),
           @w_fpago                             char(1),
           @w_determinada_indeter              char(1),
           @w_abierta_cerrada                  char(1),
           @w_modalidad                          char(1),
           @w_propietario_gar                    char(2),
           @w_fec_ult_proceso                    datetime,
           @w_fecha_fin_min_div_ven             datetime,
           @w_fecha_maestro                    varchar(10),
           @w_op_fecha_ini                       datetime,
           @w_op_toperacion                    catalogo,
           @w_op_tdividendo                    catalogo,
           @w_op_sector                          catalogo,
           @w_referencial                       catalogo,   
           @w_op_clase                          catalogo,
           @w_est_novigente                    tinyint,
           @w_est_cancelado                    tinyint,
           @w_est_credito                       tinyint,
           @w_est_comext                       tinyint,
           @w_est_anulado                       tinyint,
           @w_op_nombre_cliente                 descripcion,
           @w_op_banco                          cuenta,
           @w_op_numero_identificacion           cuenta,
           @w_cedula_codeudor                    numero,
           @w_op_cliente                       int,
           @w_op_tramite                       int,
           @w_op_operacion                       int,
           @w_dias_vencidos_op                 int,
           @w_error                              int,
           @w_ente_propietario_gar             int,
           @w_tasa                             float,
           @w_puntos                             float,
           @w_cobertura_garantia               float,
           @w_monto_desembolso                   money,
           @w_saldo_capital                    money,
           @w_saldo_int                          money,
            @w_saldo_int_mora                    money,
           @w_saldo_int_ctg                    money,
           @w_saldo_int_imo_ctg                 money,
           @w_provision_cap                    money,
           @w_provision_int                    money,
           @w_provision_otros                    money,
           @w_defecto_garantia                 money,
           @w_saldo_otros                       money,
           @w_valor_garantia                     money,
           @w_valor_cobertura                    money,
           @w_saldo_ctg                          money,
           @w_producto                          tinyint,
           @w_op_dias_vencido_op                 smallint,
           @w_op_numero_operacion              int,
           @w_moneda                             tinyint,
           @w_return                             int,
           @w_op_estado                        tinyint,
           @w_op_reestructuracion              char(1),
           @w_monto_desembolso_uvr              money,
           @w_saldo_int_uvr                    money,
           @w_saldo_capital_uvr                 money,
           @w_saldo_int_mora_uvr                 money,
           @w_saldo_int_imo_ctg_uvr              money,
           @w_saldo_int_ctg_uvr                 money,
           @w_saldo_otros_uvr                    money,
           @w_cotizacion                       money,
           @w_numero_identificacion              numero,
           @w_op_fecha_liq                       datetime,
           @w_op_base_calculo                  char(1),
           @w_fecha_mora_desde                 datetime,
           @w_numero_cuotas_vencidas           int,
           @w_op_tipo                          char(1),
           @w_op_dia_fijo                      int,
           @w_saldo_cxcintes                   money,
           @w_op_divcap_original               int,
           @w_parametro_cxcintes               catalogo,     ---NR 379
           @w_concepto_traslado                catalogo,     ---NR 379
           @w_op_monto_aprobado                money,        ---NR 296
           @w_disponible                       money,
           @w_min_div_ven                   smallint,
           @w_fecha_ini_mora                datetime,
           @w_rowcount                      int



select @w_sp_name                  = 'sp_extracto_linea_int',
       @w_numero_cuotas_vencidas   = 0


select @w_parametro_cxcintes = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'CXCINT'
set transaction isolation level read uncommitted

/*  -- KDR Sección no aplica para la versión de Finca
select @w_concepto_traslado  = co_concepto
from ca_concepto
where co_concepto = @w_parametro_cxcintes

if @@rowcount = 0 
   return 711017
*/ -- FIN KDR
 
if @i_operacion = 'D'  begin ---Deudas Directas (La Informacion sale directamente de tablas originales)
   select @w_producto = pd_producto from cobis..cl_producto
   where pd_abreviatura = 'CCA'
   set transaction isolation level read uncommitted

   declare cursor_deudas_directas cursor  
   for   select op_cliente,
                op_banco,
                op_fecha_ini,
                op_clase,
                op_tramite,
                op_operacion,
                op_toperacion,
                op_tdividendo,
                op_sector,
                op_fecha_ult_proceso,
                op_moneda,
                isnull(op_calificacion,'A'),
                op_monto,
                isnull(op_reestructuracion,'N'),
                op_fecha_liq,
                op_base_calculo,
                op_tipo,
                op_dia_fijo,
                op_divcap_original,
                op_monto_aprobado
         from  ca_operacion
         where op_cliente = @i_cliente
         and   op_estado not in(0,3,99,98,6)
         and   op_tipo <> 'R'
         for read only

   open cursor_deudas_directas 
   fetch cursor_deudas_directas into
         @w_op_cliente,
         @w_op_banco,
         @w_op_fecha_ini,
         @w_op_clase,
         @w_op_tramite,
         @w_op_operacion,
         @w_op_toperacion,
         @w_op_tdividendo,
         @w_op_sector,
         @w_fec_ult_proceso,
         @w_moneda,
         @w_op_calificacion,
         @w_monto_desembolso,
         @w_op_reestructuracion,
         @w_op_fecha_liq,
         @w_op_base_calculo,
         @w_op_tipo,
         @w_op_dia_fijo,
         @w_op_divcap_original,
         @w_op_monto_aprobado

   while (@@fetch_status = 0) 
   begin
   

      --- MONTO DESEMBOLSO
      if @w_monto_desembolso <= 0
         select @w_monto_desembolso = 0

      ---TASA
      select @w_tasa = 0

      select @w_tasa = isnull(ro_porcentaje,0)
      from ca_rubro_op
      where ro_tipo_rubro = 'I'
      and ro_operacion = @w_op_operacion

      select @w_referencial = ro_referencial,
             @w_signo       = ro_signo,
             @w_puntos      = ro_factor,
             @w_fpago       = ro_fpago
      from  ca_rubro_op,ca_operacion
      where ro_operacion = @w_op_operacion
      and   ro_concepto = 'INT'
      and   ro_operacion = op_operacion

      select @w_tasa_mercado = vd_referencia
      from  ca_valor_det
      where vd_tipo = @w_referencial --ro_referencial
      and   vd_sector = @w_op_sector  ---op_Sector

      select @w_modalidad = 'V'  ---Por defecto
      if @w_fpago = 'P'
         select @w_modalidad = 'V'

      if @w_fpago = 'A'
    select @w_modalidad = 'A'

      ---Convertir los puntos a char
       select @w_puntos_c  = convert(varchar(5),round(convert(money,@w_puntos),3))

      ---Concatenar la tasa para mostrar segun solicitud

      select @w_tasa_pactada = @w_tasa_mercado + '' + @w_signo + '' + @w_puntos_c 

      select @w_fecha_fin_min_div_ven = (min(di_fecha_ven))
      from  ca_dividendo
      where di_operacion = @w_op_operacion
      and   di_estado = 2 --Vencido

      
      -- DIAS VENCIDOS OPERACION
      -- FECHA FIN MINIMA DE DIVIDENDOS VENCIDOS
      
      select @w_fecha_mora_desde = min(di_fecha_ven)
      from   ca_dividendo
      where  di_operacion = @w_op_operacion
      and    di_estado = 2         

    -- NUMERO CUOTAS VENCIDAS
      select @w_numero_cuotas_vencidas = count(1) 
      from   ca_dividendo
      where  di_operacion = @w_op_operacion
      and    di_estado = 2 
      set transaction isolation level read uncommitted

    --FECHA INICIO MORA       --SLI 26-sep-06 insercion campo fecha_ini_mora
       select @w_min_div_ven = min(di_dividendo)
       from    cob_cartera..ca_dividendo 
       where   di_operacion = @w_op_operacion
       and     di_estado = 2

       select  @w_fecha_ini_mora = min(isnull(di_fecha_ven, '')) 
       from    cob_cartera..ca_dividendo 
       where   di_operacion = @w_op_operacion
       and     di_dividendo = @w_min_div_ven 
       and     di_estado    = 2
     --FIN FECHA INICIO MORA
                  
      if @w_numero_cuotas_vencidas > 0 
      begin

         if @w_op_base_calculo = 'R'
            select @w_dias_vencidos_op = isnull(datediff(dd,@w_fecha_mora_desde,@w_fec_ult_proceso),0)  
         else 
         begin
            
        if @w_op_dia_fijo is null or @w_op_dia_fijo = 0
           select @w_op_dia_fijo = datepart(dd, @w_fecha_mora_desde)
            
            ---DEF 8525 PENDIENTE ANALIZAR CUANDO UNA OBLIGACION VENCE EL ULTIMO DIA DE FEBRERO
            exec @w_return     = sp_dias_causar_360
                 @i_fecha_ini  = @w_fecha_mora_desde,
                 @i_fecha_fin  = @w_fec_ult_proceso,
                 @o_dias       = @w_dias_vencidos_op out
   
        end 

       end else
       select @w_dias_vencidos_op = 0
      

       select @w_dias_vencidos_op = @w_dias_vencidos_op +  isnull(@w_op_divcap_original, 0)  ---XMA CARTERIZACION SOBREGIROS

   if @w_dias_vencidos_op < 0
      select @w_dias_vencidos_op = 0
     
      -- SALDO_CAPITAL 
      select @w_saldo_capital = 0
      select @w_saldo_capital = isnull(sum(am_acumulado + am_gracia - am_pagado), 0)
      from   ca_rubro_op, ca_amortizacion
      where  ro_operacion  = @w_op_operacion
      and    ro_tipo_rubro = 'C'
      and    ro_fpago in ('P', 'A')
      and    am_operacion  = ro_operacion
      and    am_concepto   = ro_concepto
      and    am_estado != 3

      if @w_saldo_capital <= 0
         select @w_saldo_capital = 0

      -- SALDO_INTERES
      select @w_saldo_int = 0
      select @w_saldo_int = isnull(sum(am_acumulado + am_gracia - am_pagado), 0)
      from   ca_rubro_op, ca_amortizacion
      where  ro_operacion  = @w_op_operacion
      and    ro_tipo_rubro = 'I'
      and    ro_fpago in ('P', 'A')
      and    am_operacion  = ro_operacion
      and    am_concepto   = ro_concepto
      and    am_estado  not in (0,3,4,44,9)
      if @w_saldo_int <= 0
          select @w_saldo_int = 0

      
      -- SALDO_INTERES CXCINTES
      select @w_saldo_cxcintes = 0
      select @w_saldo_cxcintes = isnull(sum(am_acumulado + am_gracia - am_pagado), 0)
      from    ca_amortizacion
      where  am_operacion  = @w_op_operacion
      and    am_concepto   = @w_concepto_traslado
      and    am_estado  !=3
      
      if @w_saldo_cxcintes <= 0
         select @w_saldo_cxcintes = 0

      select @w_saldo_int = @w_saldo_int + @w_saldo_cxcintes
      
      -- MORA VENCIDA
      select @w_saldo_int_mora = 0
      select @w_saldo_int_mora = isnull(sum(am_acumulado + am_gracia - am_pagado), 0)
      from   ca_rubro_op, ca_amortizacion
      where  ro_operacion  = @w_op_operacion
      and    ro_tipo_rubro = 'M'
      and    am_operacion  = ro_operacion
      and    am_concepto   = ro_concepto
      and    am_estado  not in (0,3,4,44,9)

      if @w_saldo_int_mora <= 0
    select @w_saldo_int_mora = 0

      -- SALDO INTERES CONTINGENTE
      select @w_saldo_int_ctg = isnull(sum(am_acumulado + am_gracia - am_pagado), 0)
      from   ca_rubro_op, ca_amortizacion
      where  ro_operacion  = @w_op_operacion
      and    ro_tipo_rubro = 'I'
      and    ro_fpago in ('P', 'A')
      and    am_operacion  = ro_operacion
      and    am_concepto   = ro_concepto
      and    am_estado     in (4,44,9)

      if @w_saldo_int_ctg <= 0
    select @w_saldo_int_ctg = 0


      -- SALDO MORA CONTINGENTE
      select @w_saldo_int_imo_ctg = isnull(sum(am_acumulado + am_gracia - am_pagado), 0)
      from   ca_rubro_op, ca_amortizacion
      where  ro_operacion  = @w_op_operacion
      and    ro_tipo_rubro = 'M'
      and    am_operacion  = ro_operacion
      and    am_concepto   = ro_concepto
      and    am_estado     in (4,44,9)  

      if @w_saldo_int_imo_ctg <= 0
    select @w_saldo_int_imo_ctg = 0

      ---SALDO_OTROS 2
      select @w_saldo_otros = 0

      select @w_saldo_otros = isnull(sum(am_acumulado + am_gracia - am_pagado), 0)
      from   ca_rubro_op, ca_amortizacion
      where  ro_operacion  = @w_op_operacion
      and    ro_tipo_rubro not in ('C','I','M')
      and    ro_fpago in ('P', 'A','M')
      and    am_operacion  = ro_operacion
      and    am_concepto   = ro_concepto
      and    am_estado not in (0, 3, 9)
      and    am_concepto <>  @w_concepto_traslado --def 6359

      if @w_saldo_otros <= 0
    select @w_saldo_otros = 0

      --NR 296
      if @w_op_tipo = 'O' --ROTATIVO
         select @w_disponible =   @w_op_monto_aprobado - @w_saldo_capital
      else
         select @w_disponible = 0

      --- NR 296
 
      if @w_moneda = 2
      begin
         select @w_cotizacion = ct_valor
         from   cob_conta..cb_cotizacion
         where  ct_moneda = @w_moneda
         and    ct_fecha  = @w_fec_ult_proceso
         select @w_rowcount = @@rowcount
         set transaction isolation level read uncommitted

         if @w_rowcount = 0
         begin
            select @w_cotizacion = ct_valor
            from   cob_conta..cb_cotizacion noholdlock
            where  ct_moneda = @w_moneda
            and    ct_fecha  = (select max(ct_fecha) 
                                from   cob_conta..cb_cotizacion noholdlock
                                where  ct_moneda = @w_moneda
                                and    ct_fecha <= @w_fec_ult_proceso)
         end

         select @w_monto_desembolso_uvr = @w_monto_desembolso
         select @w_monto_desembolso = @w_monto_desembolso * @w_cotizacion

         select @w_saldo_capital_uvr = @w_saldo_capital
         select @w_saldo_capital = @w_saldo_capital * @w_cotizacion

         select @w_saldo_int_uvr = @w_saldo_int
         select @w_saldo_int = @w_saldo_int * @w_cotizacion

         select @w_saldo_int_mora_uvr = @w_saldo_int_mora
         select @w_saldo_int_mora = @w_saldo_int_mora * @w_cotizacion

         select @w_saldo_int_ctg_uvr = @w_saldo_int_ctg
         select @w_saldo_int_ctg = @w_saldo_int_ctg * @w_cotizacion

         select @w_saldo_int_imo_ctg_uvr = @w_saldo_int_imo_ctg
         select @w_saldo_int_imo_ctg = @w_saldo_int_imo_ctg * @w_cotizacion

         select @w_saldo_otros_uvr = @w_saldo_otros
         select @w_saldo_otros = @w_saldo_otros * @w_cotizacion
         
         -- NR 296 Disponible en pesos
         select @w_disponible = @w_disponible * @w_cotizacion
      end
      
      

      --- PROVISION CAP 
      select @w_provision_cap = 0
      select @w_provision_cap = isnull((cp_prov + cp_provc + cp_prova),0)
      from cob_credito..cr_calificacion_provision
      where cp_operacion     = @w_op_operacion
      and   cp_producto      = @w_producto
      and   cp_concepto      = '1'

      --- PROVISION INT 
      select @w_provision_int = 0

      select @w_provision_int = isnull((cp_prov + cp_provc + cp_prova),0)
      from cob_credito..cr_calificacion_provision
      where cp_operacion     = @w_op_operacion
      and   cp_producto      = @w_producto
      and   cp_concepto      = '2'

      --- PROVISION OTROS 
      select @w_provision_otros = 0

      select @w_provision_otros = isnull((cp_prov + cp_provc + cp_prova),0)
      from cob_credito..cr_calificacion_provision
      where cp_operacion     = @w_op_operacion
      and   cp_producto      = @w_producto
      and   cp_concepto      not in ( '1','2')
      
      --- DEFECTO GARANTIA 
      select @w_defecto_garantia = 0

      select @w_defecto_garantia = isnull((co_xprov_cap + co_xprov_int + co_xprov_ctasxcob ),0)
      from cob_credito..cr_calificacion_op--(INDEX cr_calificacion_op_Key)
      where co_producto      = @w_producto
      and   co_operacion     = @w_op_operacion

      --- ENVIO DE UN CODEUDOR  
      set rowcount 1
      select @w_cedula_codeudor = de_ced_ruc,
             @w_nombre_codeudor = en_nomlar
      from   cob_credito..cr_deudores,
             cobis..cl_ente noholdlock
      where  de_tramite= @w_op_tramite
      and    de_cliente = en_ente
      and    de_rol in ('C','A')
      set rowcount 0
      
      if @w_op_tipo = 'G'  --OPERACIONES ALTERNAS
         select @w_op_calificacion = null
      
      insert into ca_extracto_linea_tmp(
             exl_user,              exl_obligacion,                              exl_cliente,
             exl_tipo_deuda,      exl_nom_indirectas,                           exl_iden_indirectas,
             exl_linea,             exl_clase_car,                              exl_tasa_pactada,
             exl_calificacion,      exl_fecha_desembolso,                        exl_valor_desembolso,
             exl_saldo_cap,         exl_saldo_int,                              exl_saldo_int_imo,       
             exl_saldo_int_ctg,      exl_saldo_ctg_imo_int,                       exl_saldo_otros,   
             exl_prov_cap,         exl_prov_int,                              exl_prov_otros,    
             exl_dias_vencimiento, exl_nom_codeudor,                            exl_iden_codeudor,
             exl_disponible,       exl_fecha_ini_mora)
      values(
             @s_user,              @w_op_banco,                                  @i_cliente,   
             'DIRECTA',            null,                                      null,
             @w_op_toperacion,     @w_op_reestructuracion,                       @w_tasa_pactada,
             @w_op_calificacion,   @w_op_fecha_liq,                              @w_monto_desembolso,
             @w_saldo_capital,     @w_saldo_int,                               @w_saldo_int_mora,        
             @w_saldo_int_ctg,      @w_saldo_int_imo_ctg,                        @w_saldo_otros,       
             @w_provision_cap,     @w_provision_int,                           @w_provision_otros,     
             @w_dias_vencidos_op,  convert(varchar(10),@w_fec_ult_proceso,101),  @w_cedula_codeudor,
             @w_disponible,        @w_fecha_ini_mora)
      if @@error <> 0 
      begin
         select @w_error = 710396 --Crear error   
         return @w_error
      end

      if @w_moneda = 2
      begin

        insert into ca_extracto_linea_tmp(
                exl_user,                exl_obligacion,         exl_cliente,
                exl_tipo_deuda,            exl_nom_indirectas,         exl_iden_indirectas,
                exl_linea,               exl_clase_car,         exl_tasa_pactada,
                exl_calificacion,        exl_fecha_desembolso,   exl_valor_desembolso,
                exl_saldo_cap,            exl_saldo_int,         exl_saldo_int_imo,      
                exl_saldo_int_ctg,      exl_saldo_ctg_imo_int,   exl_saldo_otros,  
                exl_nom_codeudor)
         values(
               @s_user,              @w_op_banco,              @i_cliente,   
               'DIRECTAUVR',           null,                   null,
               @w_op_toperacion,       @w_op_reestructuracion,   @w_cotizacion,
               @w_op_calificacion,     @w_op_fecha_liq,          @w_monto_desembolso_uvr,
               @w_saldo_capital_uvr,   @w_saldo_int_uvr,        @w_saldo_int_mora_uvr, 
               @w_saldo_int_ctg_uvr,   @w_saldo_int_imo_ctg_uvr, @w_saldo_otros_uvr,   
               convert(varchar(10),@w_fec_ult_proceso,101))

         if @@error <> 0 
         begin
            select @w_error = 710396 --Crear error   
             return @w_error
         end
      end

      fetch cursor_deudas_directas into
            @w_op_cliente,
            @w_op_banco,
            @w_op_fecha_ini,
            @w_op_clase,
            @w_op_tramite,
            @w_op_operacion,
            @w_op_toperacion,
            @w_op_tdividendo,
            @w_op_sector,
            @w_fec_ult_proceso,
            @w_moneda,
            @w_op_calificacion,
            @w_monto_desembolso,
            @w_op_reestructuracion,
            @w_op_fecha_liq,
            @w_op_base_calculo,
            @w_op_tipo,
            @w_op_dia_fijo,
            @w_op_divcap_original,
            @w_op_monto_aprobado
   end
   close cursor_deudas_directas
   deallocate cursor_deudas_directas
end ---Operacion 'D' 
    

if @i_operacion = 'I'  begin ---Deudas Indirectas

   select @w_dias_vencidos_op = 0
   
   select @w_est_novigente = es_codigo
   from  ca_estado
   where rtrim(ltrim(es_descripcion)) = 'NO VIGENTE'

   select @w_est_cancelado  = es_codigo
   from  ca_estado
   where rtrim(ltrim(es_descripcion)) = 'CANCELADO'

   select @w_est_credito  = es_codigo
   from  ca_estado
   where rtrim(ltrim(es_descripcion)) = 'CREDITO'

   select @w_est_comext = es_codigo
   from  ca_estado
   where rtrim(ltrim(es_descripcion)) = 'COMEXT'

   select @w_est_anulado = es_codigo
   from  ca_estado
   where rtrim(ltrim(es_descripcion)) = 'ANULADO'

   

   declare cursor_deudas_indirectas cursor 
   for  select de_tramite 
   
       from cob_credito..cr_deudores,ca_operacion 
       where de_cliente =  @i_cliente
       and   de_rol  != 'D'
       and   op_tramite = de_tramite
       and   op_estado not in (0, 3,99,98,6)
       and   op_naturaleza = 'A'

    open cursor_deudas_indirectas 
   fetch cursor_deudas_indirectas into
   @w_op_tramite      

   while (@@fetch_status = 0) begin
      if (@@fetch_status = -1) begin
         select @w_error = 710398 -- Crear error
         return @w_error
      end 



     
      select @w_op_operacion      = op_operacion,
             @w_op_clase          = op_clase,
             @w_moneda             = op_moneda,
             @w_op_toperacion     = op_toperacion,
             @w_op_fecha_ini      = op_fecha_ini,
             @w_op_sector         = op_sector,
             @w_op_calificacion   = op_calificacion,
             @w_fec_ult_proceso   = op_fecha_ult_proceso,
             @w_op_estado         = op_estado,
             @w_op_banco          = op_banco,
             @w_op_nombre_cliente = op_nombre,
             @w_op_base_calculo   = op_base_calculo,
             @w_op_tipo           = op_tipo,
             @w_op_dia_fijo       = op_dia_fijo,
             @w_monto_desembolso  = op_monto,
                  @w_op_divcap_original = op_divcap_original
      from   ca_operacion
      where  op_tramite = @w_op_tramite
      and    op_naturaleza = 'A'
      and    op_estado not in (@w_est_novigente, @w_est_cancelado, @w_est_credito,@w_est_comext, @w_est_anulado)

      if @w_op_estado <> 3
      begin

         select @w_referencial = ro_referencial,
                @w_signo       = ro_signo,
                @w_puntos      = ro_factor,
                @w_fpago       = ro_fpago
         from  ca_rubro_op,ca_operacion
         where ro_operacion = @w_op_operacion
         and   ro_concepto = 'INT'
         and   ro_operacion = op_operacion

         select @w_tasa_mercado = vd_referencia
         from  ca_valor_det
         where vd_tipo = @w_referencial --ro_referencial
         and   vd_sector = @w_op_sector  ---op_Sector

         select @w_modalidad = 'V'  ---Por defecto
         if @w_fpago = 'P'
            select @w_modalidad = 'V'

         if @w_fpago = 'A'
         select @w_modalidad = 'A'

         ---Convertir los puntos a char
          select @w_puntos_c  = convert(varchar(5),round(convert(money,@w_puntos),3))


         ---Concatenar la tasa para mostrar segun solicitud
         select @w_tasa_pactada = @w_tasa_mercado + '' + @w_signo + '' + @w_puntos_c 


         select @w_numero_identificacion = en_ced_ruc
         from   cobis..cl_ente
          where  en_ente = @w_op_cliente

     -- SALDO CAPITAL
    select @w_saldo_capital = isnull(sum(am_acumulado + am_gracia - am_pagado), 0)
    from   ca_rubro_op, ca_amortizacion
     where  ro_operacion  = @w_op_operacion
    and    ro_tipo_rubro = 'C'
    and    ro_fpago in ('P', 'A')
    and    am_operacion  = ro_operacion
    and    am_concepto   = ro_concepto
    and    am_estado != 3

         if @w_saldo_capital <= 0
       select @w_saldo_capital = 0

     -- INTERES CORRIENTE
    select @w_saldo_int = isnull(sum(am_acumulado + am_gracia - am_pagado), 0)
    from   ca_rubro_op, ca_amortizacion
     where  ro_operacion  = @w_op_operacion
    and    ro_tipo_rubro = 'I'
    and    ro_fpago in ('P', 'A')
    and    am_operacion  = ro_operacion
    and    am_concepto   = ro_concepto
    and    am_estado not in (0,3,4,44,9)

    if @w_saldo_int <= 0
    select @w_saldo_int = 0

   -- SALDO_INTERES CXCINTES
   select @w_saldo_cxcintes = 0
   select @w_saldo_cxcintes = isnull(sum(am_acumulado + am_gracia - am_pagado), 0)
   from    ca_amortizacion
   where  am_operacion  = @w_op_operacion
   and    am_concepto   = @w_concepto_traslado
   and    am_estado  !=3
   
   if @w_saldo_cxcintes <= 0
      select @w_saldo_cxcintes = 0

  ---PRINT 'extclint.sp @w_saldo_cxcintes %1! @w_op_operacion %2!',@w_saldo_cxcintes,@w_op_operacion
  
   select @w_saldo_int = @w_saldo_int + @w_saldo_cxcintes


    -- MORA VENCIDA
    select @w_saldo_int_mora = isnull(sum(am_acumulado + am_gracia - am_pagado), 0)
    from   ca_rubro_op, ca_amortizacion
    where  ro_operacion  = @w_op_operacion
    and    ro_tipo_rubro = 'M'
    and    am_operacion  = ro_operacion
    and    am_concepto   = ro_concepto
    and    am_estado not in (0,3,4,44,9)

         if @w_saldo_int_mora <= 0
       select @w_saldo_int_mora = 0

    -- INTERES CONTINGENTE
    select @w_saldo_int_ctg = isnull(sum(am_acumulado + am_gracia - am_pagado), 0)
     from   ca_rubro_op, ca_amortizacion
    where  ro_operacion  = @w_op_operacion
    and    ro_tipo_rubro = 'I'
    and    ro_fpago in ('P', 'A')
    and    am_operacion  = ro_operacion
    and    am_concepto   = ro_concepto
    and    am_estado     in ( 9,4,44)

         if @w_saldo_int_ctg <= 0
       select @w_saldo_int_ctg = 0

         -- MORA CONTINGENTE
    select @w_saldo_int_imo_ctg = isnull(sum(am_acumulado + am_gracia - am_pagado), 0)
    from   ca_rubro_op, ca_amortizacion
    where  ro_operacion  = @w_op_operacion
    and    ro_tipo_rubro = 'M'
    and    am_operacion  = ro_operacion
    and    am_concepto   = ro_concepto
    and    am_estado     in (9,4,44)

         if @w_saldo_int_imo_ctg <= 0
       select @w_saldo_int_imo_ctg = 0

         -- SALDO_OTROS 1
         select @w_saldo_otros = 0

         select @w_saldo_otros = isnull(sum(am_acumulado + am_gracia - am_pagado), 0)
         from   ca_rubro_op, ca_amortizacion
         where  ro_operacion  = @w_op_operacion
         and    ro_tipo_rubro not in ('C','I','M')
         and    ro_fpago in ('P', 'A','M')
         and    am_operacion  = ro_operacion
         and    am_concepto   = ro_concepto
         and    am_estado not in (0, 3, 9)
         and    am_concepto <>  @w_concepto_traslado --def 6359
 
         if @w_saldo_otros <= 0
       select @w_saldo_otros = 0

         if @w_moneda = 2
         begin
            select @w_cotizacion = ct_valor
            from   cob_conta..cb_cotizacion
            where  ct_moneda = @w_moneda
            and    ct_fecha  = @w_fec_ult_proceso
            select @w_rowcount = @@rowcount
            set transaction isolation level read uncommitted

            if @w_rowcount = 0
            begin
               select @w_cotizacion = ct_valor
               from   cob_conta..cb_cotizacion noholdlock
               where  ct_moneda = @w_moneda
               and    ct_fecha  = (select max(ct_fecha) 
                                   from   cob_conta..cb_cotizacion noholdlock
                                   where  ct_moneda = @w_moneda
                                   and    ct_fecha <= @w_fec_ult_proceso)
            end

            select @w_monto_desembolso = @w_monto_desembolso * @w_cotizacion
            select @w_saldo_capital = @w_saldo_capital * @w_cotizacion
            select @w_saldo_int = @w_saldo_int * @w_cotizacion
            select @w_saldo_int_mora = @w_saldo_int_mora * @w_cotizacion
            select @w_saldo_int_ctg = @w_saldo_int_ctg * @w_cotizacion
            select @w_saldo_int_imo_ctg = @w_saldo_int_imo_ctg * @w_cotizacion
            select @w_saldo_otros = @w_saldo_otros * @w_cotizacion
         end

         --  PROVISION CAP 
         select @w_provision_cap = 0
         select @w_provision_cap = isnull((cp_prov + cp_prova),0)
         from cob_credito..cr_calificacion_provision
         where cp_operacion     = @w_op_operacion
         and   cp_producto      = @w_producto
         and   cp_concepto      = '1'

         if @w_provision_cap = 0
          select @w_provision_cap = 0


         --- PROVISION INT 
         select @w_provision_int = 0
         select @w_provision_int = isnull((cp_prov + cp_prova),0)
         from cob_credito..cr_calificacion_provision
         where cp_operacion     = @w_op_operacion
         and   cp_producto      = @w_producto
         and   cp_concepto      = '2'

         if @w_provision_int = 0
          select @w_provision_int = 0


         --- PROVISION OTROS 
         select @w_provision_otros = 0 
         select @w_provision_otros = isnull((cp_prov + cp_prova),0)
         from cob_credito..cr_calificacion_provision
         where cp_operacion     = @w_op_operacion
         and   cp_producto      = @w_producto
         and   cp_concepto      = '5'
 
         if @w_provision_otros = 0
          select @w_provision_otros = 0
          
          


          ---EPB

               -- DIAS VENCIDOS OPERACION
               -- FECHA FIN MINIMA DE DIVIDENDOS VENCIDOS
               
               select @w_fecha_mora_desde = min(di_fecha_ven)
               from   ca_dividendo
               where  di_operacion = @w_op_operacion
               and    di_estado = 2    
                         
              -- NUMERO CUOTAS VENCIDAS
               select @w_numero_cuotas_vencidas = count(1) 
               from   ca_dividendo
               where  di_operacion = @w_op_operacion
               and    di_estado = 2 
               set transaction isolation level read uncommitted
                     
               if @w_numero_cuotas_vencidas > 0 
               begin
         
                  if @w_op_base_calculo = 'R'
                     select @w_dias_vencidos_op = isnull(datediff(dd,@w_fecha_mora_desde,@w_fec_ult_proceso),0)  
                  else 
                  begin
                     
                 if @w_op_dia_fijo is null or @w_op_dia_fijo = 0
                    select @w_op_dia_fijo = datepart(dd, @w_fecha_mora_desde)
                     
                     ---DEF 8525 PENDIENTE ANALIZAR CUANDO UNA OBLIGACION VENCE EL ULTIMO DIA DE FEBRERO
                     exec @w_return = sp_dias_causar_360
                          @i_fecha_ini   = @w_fecha_mora_desde,
                          @i_fecha_fin   = @w_fec_ult_proceso,
                          @o_dias        = @w_dias_vencidos_op out
            
                 end 
         
                end else
                select @w_dias_vencidos_op = 0
               ----------------------------

                select @w_dias_vencidos_op = @w_dias_vencidos_op +  isnull(@w_op_divcap_original, 0)   ---XMA CARTERIZACION SOBREGIROS

          ---EPB          

          --FECHA INICIO MORA 
            select @w_min_div_ven = min(di_dividendo)
            from    cob_cartera..ca_dividendo 
            where   di_operacion = @w_op_operacion
            and     di_estado = 2
            
            select  @w_fecha_ini_mora = min(isnull(di_fecha_ven, '')) 
            from    cob_cartera..ca_dividendo 
            where   di_operacion = @w_op_operacion
            and     di_dividendo = @w_min_div_ven 
            and     di_estado    = 2
          --FIN FECHA INICIO MORA 
          
         --INSERTAR INFORMACION DEUDAS INDIRECTAS
         if @w_op_banco is not null
         begin
            insert into ca_extracto_linea_tmp 
                    (exl_user,             exl_obligacion,        exl_cliente,
                    exl_tipo_deuda,        exl_nom_indirectas,    exl_iden_indirectas,
                    exl_linea,             exl_clase_car,         exl_tasa_pactada,
                    exl_calificacion,      exl_fecha_desembolso,  exl_valor_desembolso,
                    exl_saldo_cap,         exl_saldo_int,         exl_saldo_int_imo,
                    exl_saldo_int_ctg,     exl_saldo_ctg_imo_int, exl_saldo_otros,
                    exl_prov_cap,          exl_prov_int,          exl_prov_otros,
                    exl_dias_vencimiento,  exl_nom_codeudor,      exl_iden_codeudor,
                    exl_disponible,        exl_fecha_ini_mora )
            values
                    (@s_user,              @w_op_banco,            @i_cliente,   
                    'INDIRECTA',           @w_op_nombre_cliente,   @w_op_numero_identificacion,
                    @w_op_toperacion,      @w_op_clase,            @w_tasa_pactada,
                    @w_op_calificacion,    @w_op_fecha_ini,        @w_monto_desembolso,
                    @w_saldo_capital,      @w_saldo_int,           @w_saldo_int_mora,  
                    @w_saldo_int_ctg,      @w_saldo_int_imo_ctg,   @w_saldo_otros,
                    @w_provision_cap,      @w_provision_int,       @w_provision_otros, 
                    @w_dias_vencidos_op,   null,                null,
                    0,                     @w_fecha_ini_mora )

            if @@error <> 0 
            begin
               select @w_error = 710399 --Crear errro   
               return @w_error
            end
         end  
      end   
     
      fetch cursor_deudas_indirectas into
      @w_op_tramite
   end
   close cursor_deudas_indirectas
   deallocate cursor_deudas_indirectas

end ---Operacion 'I'

return 0  
go             

