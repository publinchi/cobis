/************************************************************************/
/*  Archivo:            ca_geactpro.sp                                  */
/*  Stored procedure:   sp_activos_prorroga                             */
/*  Base de datos:      cob_cartera                                     */
/*  Producto:           Cartera                                         */
/*  Disenado por:       Igmar Berganza                                  */
/*  Fecha de escritura: 10-Sep-2014                                     */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  'COBISCorp'.                                                        */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado hecho por alguno de sus             */
/*  usuarios sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de MACOSA o su representante.                 */
/************************************************************************/
/*                            PROPOSITO                                 */
/*  Stored Procedure para consultar el estado de los activos del        */
/*  cliente que se realizara normalizacion para prorroga de cuota       */
/************************************************************************/
USE cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_activos_prorroga')
   drop proc sp_activos_prorroga
go
CREATE proc sp_activos_prorroga (  
   @s_ssn                int          = null,  
   @s_date               datetime     = null,  
   @s_user               login        = null,  
   @s_term               descripcion  = null,  
   @s_ofi                smallint     = null,  
   @s_srv                varchar(30)  = null,  
   @s_lsrv               varchar(30)  = null,  
   @t_rty                char(1)      = null,  
   @t_trn                smallint     = null,  
   @t_debug              char(1)      = 'N',  
   @t_file               varchar(14)  = null,  
   @t_from               varchar(30)  = null,  
   @i_modo               tinyint      = null, /* DEFINE LA OP A REALIZAR */  
   @i_tramite            int          = null,  
   @i_cliente            int          = null,  
   @i_grupo              int          = null,  
   @i_crea_ext           char(1)      = null, -- Req. 353 Alianzas Comerciales  
   @o_msg_msv            varchar(255) = null out -- Req. 353 Alianzas Comerciales  
)  
as  
declare  
   @w_today             datetime,     /* DECHA DEL DIA      */   
   @w_error            int,          /* VALOR QUE RETORNA  */  
   @w_sp_name           varchar(32),  /* NOMBRE STORED PROC */  
   @w_grupo             int,  
   @w_codigo            int,  
   @w_saldo_suc_a       money,  
   @w_saldo_ext_c       money,  
   @w_saldop_suc_a      money,  
   @w_saldop_ext_c      money,  
   @w_moneda            tinyint,  
   @w_def_moneda        tinyint,  
   @w_cot_moneda        money,  
   @w_producto          varchar(4),  
   @w_desc_moneda       varchar(35),  
   @w_saldo             money,  
   @w_saldop            money,  
   @w_oficina           smallint,  
   @w_char_oficina      varchar(5),  
   @w_secuencial        int,  
   @w_char_secuencial   varchar(20),  
   @w_prefijo           char(2),  
   @w_truta             tinyint,  
   @w_etapa             tinyint,  
   @w_nivel             catalogo,  
   @w_monto_max         money,  
   @w_estacion_o        smallint,  
   @w_paso              tinyint,  
   @w_nombre_prod       descripcion,  
   @w_spid              int,
   @w_fecha             datetime,
   @w_cto_imo           catalogo,
   @w_operacion         int,
   @w_monto_canc        money
  
   select @w_today   = @s_date  
   select @w_sp_name = 'SP_ACTIVOS_PRORROGA'  
   select @w_prefijo = 'CC'  
   select @w_spid    = @@spid*100
 
 select @w_cto_imo = pa_char
 from   cobis..cl_parametro
 where  pa_producto = 'CCA'
 and    pa_nemonico = 'IMO' 
  
/* VALIDACION DE CAMPOS NULOS */  
/******************************/  
if @i_modo = 1 or @i_modo = 2  
begin  
   if @i_cliente is null and @i_grupo is null  
   begin  
      if @i_crea_ext is null  
      begin  
         /* CAMPOS NOT NULL CON VALORES NULOS */  
         exec cobis..sp_cerror  
           @t_debug = @t_debug,  
           @t_file  = @t_file,   
           @t_from  = @w_sp_name,  
           @i_num   = 2101001  
         return 1   
      end  
      else  
      begin  
         select @o_msg_msv = 'Campo Cliente O Campo Grupo con valor NULL, ' + @w_sp_name  
         select @w_error  = 2101001  
         return @w_error  
      end  
   end  
end  
  
  
/* CONSULTA DE SALDOS DE CUENTAS DEL CLIENTE INDIVIDUALMENTE */  
if @i_modo = 2  
begin  
   select num_credito   = op_banco,
          operacion     = op_operacion,
          num_tramite   = op_tramite,
          saldo_capital = CONVERT(money,0.00),
          tipo_garantia = CONVERT(varchar(255),' '),
          mora          = CONVERT(char(1),'N'),
          dia_mora      = CONVERT(int,0),
          saldo_mora    = CONVERT(money,0.00),
          op_estado,
          ini_mora      = convert(datetime, '01/01/1971'),
          fin_mora      = op_fecha_ult_proceso
   into  #activos_prorroga
   from  cob_cartera..ca_operacion
   where op_cliente = @i_cliente
   and   op_estado not in (3, 99, 6)

   select top 1 g_tramite = gp_tramite,
                garantia  = cu_tipo + ' - ' + tc_descripcion
   into #activos_prorroga_garantias
   from cob_credito..cr_gar_propuesta, 
        cob_credito..cr_tramite,
        cob_custodia..cu_custodia,
        cob_custodia..cu_tipo_custodia,
        #activos_prorroga
   where gp_tramite       = tr_tramite
   and   gp_garantia      = cu_codigo_externo
   and   cu_estado        <> 'C'
   and   cu_tipo          = tc_tipo
   and   (tc_tipo_superior = '2200' or tc_tipo_superior <> '1000')
   and   tr_tramite       = num_tramite

   update #activos_prorroga
   set    tipo_garantia = garantia
   from #activos_prorroga_garantias
   where g_tramite = num_tramite
  
   if @@ERROR <> 0
   begin
      print 'ERROR AL ACTUALIZAR DATOS DEL ACTIVO DE NORMALIZACION PRORROGA DE CUOTA'
      exec cobis..sp_cerror  
            @t_debug = @t_debug,  
            @t_file  = @t_file,   
            @t_from  = @w_sp_name,  
            @i_num   = 708152  
      return 1   
   end
   
   update #activos_prorroga
   set    ini_mora = (select isnull(min(di_fecha_ven), fin_mora)
                      from   ca_dividendo
                      where  di_operacion = operacion
                      and    di_estado = 2)

   update #activos_prorroga
   set    dia_mora = datediff(dd, ini_mora, fin_mora)

   update #activos_prorroga
   set    mora = 'S'
   where  dia_mora > 0

   update #activos_prorroga
   set    saldo_mora = (select isnull(sum(am_acumulado - am_pagado), 0)
                        from   ca_dividendo, ca_amortizacion
                        where  di_operacion = operacion
                        and    di_estado = 2
                        and    am_operacion = operacion
                        and    am_dividendo = di_dividendo
                        and    am_concepto  = @w_cto_imo)

   update #activos_prorroga
   set    saldo_capital = (select isnull(sum(am_acumulado - am_pagado), 0)
                           from   ca_dividendo, ca_amortizacion
                           where  di_operacion = operacion
                           and    am_operacion = operacion
                           and    am_dividendo = di_dividendo
                           and    am_concepto  = 'CAP')
   
   select 'Numero de credito'             = num_credito,
          'Saldo de capital'              = saldo_capital,
          'Tipo de Garantia'              = tipo_garantia,
          'Se encuentra al dia o en mora' = mora,
          'Dias en mora'                  = dia_mora,
          'Saldo en mora'                 = saldo_mora
   from #activos_prorroga
   
end  
  
return 0  
go
