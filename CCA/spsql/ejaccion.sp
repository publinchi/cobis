/************************************************************************/
/*     Nombre Fisico:            ejaccion.sp                            */
/*     Nombre Logico:         	 sp_ejecutar_acciones                   */
/*     Base de datos:            cob_cartera                            */
/*     Producto:                 Cartera                                */
/*     Fecha de escritura:       Agosto-2005                            */
/************************************************************************/
/*                              IMPORTANTE                              */
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
/*                               PROPOSITO                              */
/*     Este  programa  permite  capitlaizar el rubro INTERES CORRIENTE  */
/*     en el rubro capital segun porcentajes definidos por el usuario   */
/************************************************************************/
/*                             MODIFICACIONES                           */
/*     FECHA            AUTOR               RAZON                       */
/*      08/AGO/2005    Elcira Pelaez    Programa Inicial                */
/*      10/OCT/2005    FDO CARVAJAL     DIFERIDOS REQ 389               */
/*      10/DIC/2005    IVAN JIMENZ      NR 433                          */
/*      14/FEB/2006    Fabian Quintero  Defecto 5965                    */
/*      20/ABR/2006    Elcira pelaez    NR  433                         */
/*      09/JUN/2010    Elcira Pelaez    Quitar Codigo Causacion Pasivas */
/*      04/Nov/2010    Elcira Pelaez B. Nr-059 Datos Diferidos          */
/*    	06/06/2023	   M. Cordova	  Cambio variable @w_calificacion   */
/*									  de char(1) a catalogo				*/
/************************************************************************/

use cob_cartera
go

if object_id('sp_ejecutar_acciones') is not null
   drop proc sp_ejecutar_acciones
go

create proc sp_ejecutar_acciones
   @t_trn               int         = null,
   @t_debug             char(1)     = 'N',
   @t_file              varchar(24) = null,
   @t_from              descripcion = null,
   @i_operacionca       int,
   @i_toperacion        catalogo,
   @i_moneda            tinyint,
   @i_en_linea          char(1),
   @i_banco             cuenta,
   @i_oficina           smallint,
   @i_fecha_proceso     datetime,
   @s_date              datetime,
   @s_ofi               smallint,
   @s_user              login       = null,
   @s_term              descripcion = null,
   @i_tipo_amortizacion catalogo    = null,
   @i_cotizacion        float       = 1
  
as
declare 
   @w_secuencial            int,
   @w_div_vigente           int,
   @w_rubro                 varchar(10),
   @w_divf_ini              int,
   @w_divf_fin              int,
   @w_rubrof                varchar(10),
   @w_valorc                money,
   @w_valor_fijo            money,
   @w_porcentaje            float,
   @aux_1                   int,
   @aux_2                   int,
   @w_est_vigente           tinyint,
   @w_error                 int,
   @w_num_dec               tinyint,
   @w_gar_admisible         char(1),
   @w_regenerar_tabla       char(1),
   @w_reestructuracion      char(1), 
   @w_calificacion          catalogo,
   @w_fecha_u_proceso       datetime,
   @w_tipo                  catalogo,
   @w_gerente               int,
   @w_concepto_int          catalogo,
   @w_int_ant               catalogo,
   @w_moneda_nacional       tinyint,
   @w_op_moneda             tinyint,
   @w_op_estado             int,
   @w_concepto_cap          catalogo,
   @w_saldo_capitalizar     float,
   @w_total_cap             float,
   @w_di_dividendo          int,
   @w_saldo_sec_1           float,
   @w_saldo_sec_2           float,
   @w_estado_sec_1          int,
   @w_estado_sec_2          int,
   @w_valor_cuota           float,
   @w_cont                  int,
   @w_tot_div               int,
   @w_total_valorc          float,
   @w_porcentaje_util       float,
   @w_acciones_van          int,
   @w_max_sec_int           int,
   @w_nro_acciones          int,
   @w_totporcentajes        float,
   @w_monto_cap_normal      float,
   @w_monto_cap_sus         float,
   @w_monto_cap_control     float,
   @w_total_capital         float,
   @w_total_capitalizado    float,
   @w_peso_total_cap        float,
   @w_peso_rubro_cap        float,
   -- IFJ 10/DIC/2005 - REQ 433
   @w_parametro_fag         varchar(30), 
   -- EPB 20/ABR/2006 - NR 433
   @w_rubro_cap             catalogo,
   @w_agotada               char(1),
   @w_contabiliza           char(1),
   @w_tipo_gar              varchar(64),
   @w_abierta_cerrada       char(1),
   @w_estado                char(1),
   @w_monto_gar_mn          money,
   @w_monto_gar             money,
   @w_tramite               int,
   @w_saldo_cap_gar         money,
   @w_rowcount              int,
   @w_cuota_desde_cap       smallint,           -- REQ 175: PEQUEÑA EMPRESA
   @w_di_de_capital         smallint,           -- REQ 175: PEQUEÑA EMPRESA
   @w_fecha_fin             datetime,           -- REQ 175: PEQUEÑA EMPRESA
   @w_num_dividendos        smallint,           -- REQ 175: PEQUEÑA EMPRESA
   @w_di_fecha_ini          datetime,           -- REQ 175: PEQUEÑA EMPRESA
   @w_periodo_int           smallint,           -- REQ 175: PEQUEÑA EMPRESA
   @w_plazo_operacion       smallint,           -- REQ 175: PEQUEÑA EMPRESA
   @w_divini_reg            smallint,           -- REQ 175: PEQUEÑA EMPRESA
   @w_divs_reg              smallint,           -- REQ 175: PEQUEÑA EMPRESA
   @w_di_fecha_ven          datetime,           -- REQ 175: PEQUEÑA EMPRESA
   @w_est_cancelado         tinyint,            -- REQ 175: PEQUEÑA EMPRESA
   @w_saldo_cap             money               -- REQ 175: PEQUEÑA EMPRESA
   
   
begin
   -- VARIABLES GENERALES
   select @w_regenerar_tabla     = 'N',
          @w_secuencial          = 0,
          @w_saldo_capitalizar   = 0.0,
          @w_total_cap           = 0.0,
          @w_total_valorc        = 0.0,
          @w_saldo_sec_1         = 0.0,
          @w_saldo_sec_2         = 0.0,
          @w_monto_cap_control   = 0.0,
          @w_total_capital       = 0.0,
          @w_total_capitalizado  = 0.0
   
   /* ESTADOS DE CARTERA */
   exec @w_error = sp_estados_cca
   @o_est_vigente    = @w_est_vigente   out,
   @o_est_cancelado  = @w_est_cancelado out
          
   exec @w_error = sp_decimales
        @i_moneda       = @i_moneda,
        @o_decimales    = @w_num_dec out,
        @o_mon_nacional = @aux_1  out,
        @o_dec_nacional = @aux_2 out
   
   if @w_error != 0
      return @w_error
   
   select @w_concepto_int = pa_char
   from   cobis..cl_parametro
   where  pa_producto = 'CCA'
   and    pa_nemonico = 'INT'
   set transaction isolation level read uncommitted
   
   -- CODIGO DEL INTERES ANTICIPADO
   select @w_int_ant = pa_char
   from   cobis..cl_parametro
   where  pa_producto = 'CCA'
   and    pa_nemonico = 'INTANT'
   select @w_rowcount = @@rowcount
   set transaction isolation level read uncommitted
   
   if @w_rowcount = 0
      return  710256
   
   -- CODIGO DE LA MONEDA LOCAL
   select @w_moneda_nacional = pa_tinyint
   from   cobis..cl_parametro
   where  pa_producto = 'ADM'
   and    pa_nemonico = 'MLO'
   set transaction isolation level read uncommitted
   
   select @w_div_vigente = di_dividendo
   from   ca_dividendo
   where  di_operacion = @i_operacionca
   and    di_estado    = @w_est_vigente
   
   if @@rowcount = 0
      return 0
   
   select @w_concepto_cap = ro_concepto
   from   ca_rubro_op
   where  ro_operacion = @i_operacionca
   and    ro_tipo_rubro = 'C'
   
   if @@rowcount = 0
      return 0
   
   --VERIFICAR EXISTENCIA DE DIVIDENDO PARA CAPITALIZACION E LA TABLA DE ACCIONES
   if exists(select 1
             from   ca_acciones
             where  ac_operacion = @i_operacionca
             and    ac_div_ini  <= @w_div_vigente
             and    ac_div_fin  >= @w_div_vigente)
   begin
      --DATOS DEL PRESTAMO
      select 
      @w_fecha_u_proceso   = op_fecha_ult_proceso,
      @w_tipo              = op_tipo,
      @w_op_moneda         = op_moneda,
      @w_gerente           = op_oficial,
      @w_op_estado         = op_estado,
      @w_gar_admisible     = op_gar_admisible,
      @w_reestructuracion  = op_reestructuracion,
      @w_calificacion      = op_calificacion,
      @w_tramite           = op_tramite,
      @w_periodo_int       = op_periodo_int                                  -- REQ 175: PEQUEÑA EMPRESA
      from   ca_operacion
      where  op_operacion = @i_operacionca
      
     
      exec @w_secuencial = sp_gen_sec
           @i_operacion  = @i_operacionca
      
      exec @w_error    = sp_historial
           @i_operacionca = @i_operacionca,
           @i_secuencial  = @w_secuencial
      
      if @w_error != 0
         return @w_error
      
   end
   ELSE
      return 0
   
   select @w_totporcentajes = sum(ac_porcentaje)
   from   ca_acciones
   where  ac_operacion = @i_operacionca
   and    @w_div_vigente between ac_div_ini and ac_div_fin
   
   if  @w_totporcentajes > 100.0
   begin
      insert into ca_errorlog
            (er_fecha_proc,      er_error,      er_usuario,
             er_tran,            er_cuenta,     er_descripcion,
             er_anexo)
      values(@i_fecha_proceso,   710403,         @s_user,
             7269,               @i_banco,      'ERROR EN CAPITALIZACION POR PORCENTAJE MAYOR A 100',
             '')
      return 0
   end
   
   --CANTIDAD DIVIDENDOS A CAPITALIZAR
   select @w_nro_acciones = count(1)
   from   ca_acciones
   where  ac_operacion = @i_operacionca
   and    @w_div_vigente between ac_div_ini and ac_div_fin
   
   -- VERIFICAR SECUENCIAS DEL RUBRO  INTERES
   
   select @w_max_sec_int = isnull(max(am_secuencia), 0)
   from   ca_amortizacion
   where  am_operacion = @i_operacionca
   and    am_dividendo = @w_div_vigente
   and    am_concepto  in ( @w_int_ant , @w_concepto_int)
   
   ---SACAR ELVALOR DE CAPITAL PARA ACTUALIZACION DE LA RUBRO OP  Y LA OPERACION
   
   select @w_total_capital = sum(am_cuota)
   from   ca_amortizacion
   where  am_operacion = @i_operacionca
   and    am_concepto  = @w_concepto_cap
   
   --SALDO A CAPITALIZAR
   
   select @w_saldo_sec_1 = 0.0
   
   select @w_saldo_sec_1 = am_acumulado - am_pagado,
          @w_estado_sec_1 = am_estado
   from   ca_amortizacion, ca_rubro_op
   where  am_operacion  =  @i_operacionca
   and    am_dividendo  = @w_div_vigente
   and    am_concepto   = ro_concepto
   and    am_operacion  = ro_operacion
   and    ro_tipo_rubro = 'I'
   and    am_secuencia  = 1
   
   if  @w_max_sec_int  = 2
   begin    
      select @w_saldo_sec_2 = 0.0
      
      select @w_saldo_sec_2 = am_acumulado - am_pagado,
             @w_estado_sec_2 = am_estado
      from ca_amortizacion, ca_rubro_op
      where am_operacion =  @i_operacionca
      and am_dividendo   = @w_div_vigente
      and am_concepto    = ro_concepto
      and am_operacion   = ro_operacion
      and ro_tipo_rubro  = 'I'
      and am_secuencia   = 2
   end
   
   select @w_saldo_capitalizar = @w_saldo_sec_1 + @w_saldo_sec_2
   
   if @w_saldo_capitalizar <= 0
      return 0
   
   select @w_saldo_sec_1 = round(@w_saldo_sec_1 * @w_totporcentajes/100.0, @w_num_dec)
   select @w_saldo_sec_2 = round(@w_saldo_sec_2 * @w_totporcentajes/100.0, @w_num_dec)
   
   if @w_saldo_capitalizar <= @w_saldo_sec_1 + @w_saldo_sec_2
      select @w_saldo_capitalizar = @w_saldo_sec_1 + @w_saldo_sec_2
   
   select @w_acciones_van = 0
   select @w_cont = 0
   
   declare
      cursor_acciones CURSOR
      for select ac_rubro,   ac_divf_ini,   ac_divf_fin,
                 ac_rubrof,  ac_valor,      ac_porcentaje
          from   ca_acciones
          where  ac_operacion = @i_operacionca
          and    ac_div_ini  <= @w_div_vigente
          and    ac_div_fin  >= @w_div_vigente
      for read only
   
   open cursor_acciones
   
   fetch cursor_acciones
   into  @w_rubro,   @w_divf_ini,   @w_divf_fin,
         @w_rubrof,  @w_valor_fijo, @w_porcentaje
   
   while @@fetch_status = 0 
   begin
      if exists(select 1
                from   ca_rubro_op
                where  ro_operacion   = @i_operacionca
                and    ro_concepto    = @w_rubrof
                and    ro_tipo_rubro  = 'C')
         select @w_regenerar_tabla = 'S'
      
      select @w_acciones_van = @w_acciones_van + 1
      
      select @w_porcentaje_util = @w_porcentaje / @w_totporcentajes
      
      -----QUE MONTO SE VA A CAPITALIZAR
      if @w_acciones_van < @w_nro_acciones 
      begin   
         select @w_valorc = @w_saldo_capitalizar * @w_porcentaje_util
      end
      ELSE
      begin
         select @w_valorc = @w_saldo_capitalizar - @w_total_valorc
      end
      
      if @w_valorc > 0
         select @w_valorc = round(@w_valorc, @w_num_dec)
      
      select @w_total_valorc = @w_total_valorc + @w_valorc
      
      select @w_tot_div        = count(1),
             @w_peso_total_cap = sum(am_cuota)
      from   ca_amortizacion
      where  am_operacion = @i_operacionca
      and    am_dividendo between  @w_divf_ini and   @w_divf_fin
      and    am_concepto  = @w_concepto_cap
      and    am_cuota     > 0
      and    am_secuencia = 1
      
      if @w_tot_div = 0
      begin
         insert into ca_errorlog
                 (er_fecha_proc,      er_error,      er_usuario,
                  er_tran,            er_cuenta,     er_descripcion,
                  er_anexo)
           values(@i_fecha_proceso,   710006,         @s_user,
                   7269,               @i_banco,      'ERROR EN CAPITALIZACION LA CUOTA NO TIENE VALOR CAP',
                  '')
         return 710006
      end
      
      select @w_valor_cuota =  round(@w_valorc /  @w_tot_div, @w_num_dec)
      select @w_cont = 0,
             @w_total_cap = 0
      
      declare
         cursor_dividendos cursor
         for select am_dividendo, am_cuota
             from   ca_amortizacion
             where  am_operacion = @i_operacionca
             and    am_dividendo between  @w_divf_ini and   @w_divf_fin
             and    am_concepto = @w_concepto_cap
             and    am_cuota > 0
             and    am_secuencia = 1
         for read only
      
      open  cursor_dividendos
      
      fetch cursor_dividendos
      into  @w_di_dividendo, @w_peso_rubro_cap
      
      --while @@fetch_status not in (-1,0)
      while @@fetch_status = 0
      begin 
         select @w_cont = @w_cont + 1
         
         if @w_cont = @w_tot_div -- ULTIMO LUGAR DONDE CAPITALIZAR
            select @w_valor_cuota = @w_valorc - @w_total_cap
         else
         begin -- RUBRO PROPORCIONAL
            select @w_valor_cuota =  round(@w_valorc * @w_peso_rubro_cap / @w_peso_total_cap, @w_num_dec)
         end
         
         select @w_total_cap = @w_total_cap + @w_valor_cuota,
                @w_total_capitalizado  = @w_total_capitalizado + @w_valor_cuota
         
         if  @w_valor_cuota > 0
         begin
            if  @w_monto_cap_control <= @w_saldo_sec_1
            and (@w_monto_cap_control + @w_valor_cuota) > @w_saldo_sec_1 -- SE DEBE PARTIR EN 2
            begin
               select @w_monto_cap_normal = @w_saldo_sec_1 - @w_monto_cap_control
               select @w_monto_cap_sus = @w_valor_cuota - @w_monto_cap_normal
            end
            
            if  (@w_monto_cap_control + @w_valor_cuota) <= @w_saldo_sec_1 -- SOLO SECUENCIAL 1
            begin
               select @w_monto_cap_normal = @w_valor_cuota
               select @w_monto_cap_sus = 0
            end
            
            if  @w_monto_cap_control > @w_saldo_sec_1  -- SOLO SECUENCIAL 2
            begin
               select @w_monto_cap_normal = 0
               select @w_monto_cap_sus = @w_valor_cuota
            end
            
            select @w_monto_cap_control = @w_monto_cap_control +  @w_valor_cuota
                        
            exec @w_error = sp_realiza_capitalizacion
                 @i_operacion           = @i_operacionca,
                 @i_moneda              = @w_op_moneda,
                 @i_fecha_proc          = @w_fecha_u_proceso,
                 @i_dividendo_ori       = @w_div_vigente,
                 @i_concepto_ori        = @w_rubro,
                 @i_cotizacion          = @i_cotizacion,
                 @i_dividendo_fin       = @w_di_dividendo,
                 @i_concepto_fin        = @w_concepto_cap,
                 @i_estado_sec_1        = @w_estado_sec_1,
                 @i_estado_sec_2        = @w_estado_sec_2,
                 
                 @i_monto_cap_normal    = @w_monto_cap_normal,
                 @i_monto_cap_sus       = @w_monto_cap_sus,
                 
                 @i_secuencial          = @w_secuencial,
                 @i_fecha_proceso       = @i_fecha_proceso,
                 @i_moneda_nac          = @w_moneda_nacional,
                 @i_num_dec             = @w_num_dec
            
            if @w_error != 0
               return @w_error
         end
         
         fetch cursor_dividendos
         into  @w_di_dividendo, @w_peso_rubro_cap
      end -- WHILE CURSOR_DIVIDENDOS DONDE SE CAPITALIZA
      
      close cursor_dividendos
      deallocate cursor_dividendos
      
      fetch cursor_acciones
      into  @w_rubro,  @w_divf_ini,   @w_divf_fin,
            @w_rubrof, @w_valor_fijo, @w_porcentaje
   end -- WHILE CURSOR_ACCIONES
   
   close cursor_acciones
   deallocate cursor_acciones
   
   if isnull(@w_total_capitalizado, 0) > 0
   begin
      update ca_rubro_op set
      ro_valor        = @w_total_capital + @w_total_capitalizado,
      ro_base_calculo = isnull(ro_base_calculo, 0) + @w_total_capitalizado             -- REQ 175: PEQUEÑA EMPRESA
      where  ro_operacion = @i_operacionca
      and    ro_tipo_rubro = 'C'
      and    ro_concepto   = @w_concepto_cap
      
      if @@error <> 0
         return 710002
      
      update ca_operacion
      set    op_monto =   @w_total_capital + @w_total_capitalizado
      where  op_operacion = @i_operacionca
      
      --CANCELACION DEL RUBRO ORIGEN
      update ca_amortizacion
      set am_estado = @w_est_cancelado
      from   ca_amortizacion, ca_dividendo
      where  di_operacion = @i_operacionca
      and    di_dividendo = @w_div_vigente
      and    di_operacion = am_operacion
      and    di_dividendo = am_dividendo
      and    am_acumulado = am_pagado
      and    am_estado   != @w_est_cancelado
   end
   
   if @w_regenerar_tabla = 'S' 
   begin
      /*
      exec @w_error = sp_recalcula_interes
           @i_operacionca   = @i_operacionca,
           @i_fecha_proceso = @i_fecha_proceso,
           @i_num_dec       = @w_num_dec
      
      if @w_error != 0
         return @w_error*/
         
      -- INI - REQ 175: PEQUEÑA EMPRESA - REGENERACION DE LA TABLA
      -- SALDO DE CAPITAL
      select 
      am_concepto               as concepto,
      sum(am_cuota - am_pagado) as saldo
      into #saldo_cap
      from ca_amortizacion, ca_rubro_op
      where am_operacion  = @i_operacionca
      and   am_estado    <> @w_est_cancelado
      and   ro_operacion  = am_operacion
      and   ro_concepto   = am_concepto
      and   ro_tipo_rubro = 'C'
      group by am_concepto
      
      select @w_saldo_cap = sum(saldo)
      from #saldo_cap      

      select @w_divini_reg = @w_div_vigente + 1
      
      select @w_num_dividendos = count(1)
      from   ca_dividendo
      where  di_operacion  = @i_operacionca
      and    di_dividendo >= @w_divini_reg
      
      select @w_plazo_operacion = @w_periodo_int * @w_num_dividendos
      
      select 
      @w_di_fecha_ini = di_fecha_ini,
      @w_di_fecha_ven = di_fecha_ven
      from   ca_dividendo
      where  di_operacion = @i_operacionca
      and    di_dividendo = @w_divini_reg
      
      select @w_di_de_capital = min(di_dividendo)
      from   ca_dividendo
      where  di_operacion  = @i_operacionca
      and    di_dividendo >= @w_divini_reg
      and    di_de_capital = 'S'
      
      select @w_cuota_desde_cap = @w_di_de_capital - @w_divini_reg + 1
      
      -- PASO DE LA OPERACION A TEMPORALES
      exec @w_error = sp_pasotmp
      @s_user            = @s_user,
      @s_term            = @s_term,
      @i_banco           = @i_banco,
      @i_operacionca     = 'S',
      @i_dividendo       = 'N',
      @i_amortizacion    = 'N',
      @i_cuota_adicional = 'S',
      @i_rubro_op        = 'S',
      @i_valores         = 'S', 
      @i_acciones        = 'N'  
      
      if @w_error != 0
         return @w_error
      
      update ca_operacion_tmp set 
      opt_cuota          = 0,
      opt_plazo          = @w_plazo_operacion,
      opt_fecha_ini      = @w_di_fecha_ini,
      opt_monto          = @w_saldo_cap
      where opt_operacion = @i_operacionca
      
      if @@error <> 0
         return 710002      
      
      update ca_rubro_op_tmp
      set rot_valor = saldo
      from #saldo_cap
      where rot_operacion  = @i_operacionca
      and   rot_concepto   = concepto
      
      if @@error <> 0
         return 710002

      exec @w_error = sp_gentabla
      @i_operacionca     = @i_operacionca,
      @i_tabla_nueva     = 'S',
      @i_accion          = 'S',
      @i_cuota_accion    = @w_divini_reg,
      @i_cuota_desde_cap = @w_cuota_desde_cap,
      @o_fecha_fin       = @w_fecha_fin out
 
      if @w_error != 0
         return @w_error

      update ca_amortizacion set
      am_cuota     = amt_cuota,
      am_acumulado = amt_acumulado
      from ca_amortizacion_tmp, ca_rubro_op_tmp
      where amt_operacion   = @i_operacionca
      and   am_operacion    = amt_operacion
      and   am_dividendo    = amt_dividendo + @w_divini_reg - 1
      and   am_concepto     = amt_concepto
      and   am_estado      <> 3
      and   rot_operacion   = amt_operacion
      and   rot_concepto    = amt_concepto
      and   rot_tipo_rubro  = 'C'
      
      if @@error <> 0
         return 705050
      
      update ca_amortizacion set
      am_cuota  = amt_cuota,
      am_gracia = amt_gracia
      from ca_amortizacion_tmp, ca_rubro_op_tmp
      where amt_operacion   = @i_operacionca
      and   am_operacion    = amt_operacion
      and   am_dividendo    = amt_dividendo + @w_divini_reg - 1
      and   am_concepto     = amt_concepto
      and   am_estado      <> 3
      and   rot_operacion   = amt_operacion
      and   rot_concepto    = amt_concepto
      and   rot_tipo_rubro <> 'C'
      
      if @@error <> 0
         return 705050
         
      select @w_divs_reg = count(1)
      from ca_dividendo_tmp
      where dit_operacion = @i_operacionca
      
      -- SI HAY MAS DIVIDENDOS EN LA TEMPORAL GENRADA QUE EN LA ORIGINAL SE INSERTAN ESTOS NUEVOS DIVIDENDO
      if @w_divs_reg > @w_num_dividendos
      begin      
         -- ACTUALIZACION DE LAS NUEVAS CUOTAS TANTO DE CAPITAL COMO DE INTERES
         insert into ca_dividendo(
         di_operacion,        di_dividendo,           
         di_fecha_ini,        di_fecha_ven,           di_de_capital,
         di_de_interes,       di_gracia,              di_gracia_disp,
         di_estado,           di_dias_cuota,          di_prorroga,
         di_intento,          di_fecha_can)
         select 
         dit_operacion,       dit_dividendo + @w_divini_reg - 1,
         dit_fecha_ini,       dit_fecha_ven,          dit_de_capital,         
         dit_de_interes,      dit_gracia,             dit_gracia_disp,
         dit_estado,          dit_dias_cuota,         dit_prorroga,
         dit_intento,         dit_fecha_can
         from   ca_dividendo_tmp
         where  dit_operacion = @i_operacionca
         and    dit_dividendo > @w_num_dividendos
         
         if @@error <> 0 
            return 710001
         
         insert into ca_amortizacion(
         am_operacion,        am_dividendo,           
         am_concepto,         am_estado,              am_periodo,             
         am_cuota,            am_gracia,              am_pagado,              
         am_acumulado,        am_secuencia)
         select 
         amt_operacion,       amt_dividendo + @w_divini_reg - 1,
         amt_concepto,        amt_estado,             amt_periodo,            
         amt_cuota,           amt_gracia,             amt_pagado,             
         amt_acumulado,       amt_secuencia
         from   ca_amortizacion_tmp
         where  amt_operacion = @i_operacionca
         and    amt_dividendo > @w_num_dividendos
         
         if @@error <> 0
            return 710001
   
      end -- FIN DE HAY MAS DIVIDENDO PARA INSERTAR A LA TABLA DEFINITIVA

      -- ELIMINACION DE LOS DIVIDENDOS SI EL PLAZO ES MENOR
      if @w_divs_reg < @w_num_dividendos
      begin
         delete ca_dividendo
         where  di_operacion = @i_operacionca
         and    di_dividendo > @w_divs_reg + @w_divini_reg - 1
         
         if @@error != 0 return 710003
         
         delete ca_cuota_adicional
         where  ca_operacion = @i_operacionca
         and    ca_dividendo > @w_divs_reg + @w_divini_reg - 1
         
         if @@error != 0 return 710003
         
         delete ca_amortizacion
         where  am_operacion = @i_operacionca
         and    am_dividendo > @w_divs_reg + @w_divini_reg - 1
         
         if @@error != 0 return 710003
         
      end --FIN NUMERO DE CUOTAS > 1
      
      -- ELIMINACION DE LAS TABLAS TEMPORALES
      exec @w_error = sp_borrar_tmp_int
      @i_operacionca = @i_operacionca
      
      if @w_error != 0
         return @w_error

      -- FIN - REQ 175: PEQUEÑA EMPRESA
   end
   
   if @w_secuencial <> 0
   begin
      insert into ca_transaccion
            (tr_secuencial,                  tr_fecha_mov,              tr_toperacion,
             tr_moneda,                      tr_operacion,              tr_tran,
             tr_en_linea,                    tr_banco,                  tr_dias_calc,
             tr_ofi_oper,                    tr_ofi_usu,                tr_usuario,
             tr_terminal,                    tr_fecha_ref,              tr_secuencial_ref,
             tr_estado,                      tr_gerente,                tr_gar_admisible,
             tr_reestructuracion,            tr_calificacion,
             tr_observacion,                 tr_fecha_cont,             tr_comprobante)
      values(@w_secuencial,                  @s_date,                   @i_toperacion,
             @i_moneda,                      @i_operacionca,            'CRC',
             @i_en_linea,                    @i_banco,                  1,
             @i_oficina,                     @s_ofi,                    @s_user,
             @s_term,                        @i_fecha_proceso,          0,
             'ING',                          @w_gerente,                 isnull(@w_gar_admisible,''),
             isnull(@w_reestructuracion,''), isnull(@w_calificacion,''),
             '',                             @s_date,                    0)
      
      if @@error != 0
         return 708165
   end
   
   
   --- INICIO IFJ 09/DIC/2005  - REQ 433
   select @w_parametro_fag = pa_char
   from  cobis..cl_parametro
   where pa_producto = 'CCA'
   and   pa_nemonico = 'COMFAG'
   set transaction isolation level read uncommitted
   
   if  @w_tipo not in ( 'D','R','G','V','N','O') and @w_op_moneda = @w_moneda_nacional
   begin
      if exists (select 1 from ca_amortizacion
                 where am_operacion = @i_operacionca
                 and   am_concepto  = @w_parametro_fag
                 and   am_estado   != 3 )
      begin
         --NR433
         -- CODIGO DEL RUBRO CAPITAL
         select @w_rubro_cap = pa_char
         from   cobis..cl_parametro
         where  pa_producto = 'CCA'
         and    pa_nemonico = 'CAP'
         select @w_rowcount = @@rowcount
         set transaction isolation level read uncommitted
         
         if @w_rowcount = 0
            return 710076
         
         --PARA ACTUALIZAR VALORES EN GARANTIAS 
         if exists (select 1
                    from   ca_det_trn 
                    where  dtr_secuencial = @w_secuencial
                    and    dtr_operacion  = @i_operacionca
                    and    dtr_concepto   = @w_rubro_cap) 
         begin
            select @w_saldo_cap_gar = @i_cotizacion * (sum(am_cuota + am_gracia - am_pagado))
            from   ca_amortizacion, ca_rubro_op
            where  ro_operacion  = @i_operacionca
            and    ro_tipo_rubro = 'C'
            and    am_operacion  = @i_operacionca
            and    am_estado <> 3
            and    am_concepto   = ro_concepto
            
            select @w_estado          = cu_estado,
                   @w_agotada         = cu_agotada,
                   @w_abierta_cerrada = cu_abierta_cerrada,
                   @w_tipo_gar        = cu_tipo
            from   cob_custodia..cu_custodia,
                   cob_credito..cr_gar_propuesta
            where  gp_garantia = cu_codigo_externo 
            and    cu_agotada = 'S'
            and    gp_tramite = @w_tramite
            
            select @w_contabiliza = tc_contabilizar
            from   cob_custodia..cu_tipo_custodia
            where  tc_tipo = @w_tipo_gar
            
            if (@w_estado = 'V' and @w_agotada = 'S' and @w_abierta_cerrada = 'C' and @w_contabiliza = 'S')
            begin
               --NOTA SOLO IMPORTA EL VALOR DEL CAPITAL DESPUES DE CAPITALIZAR
               exec @w_error = cob_custodia..sp_agotada 
                    @s_ssn             = 1,
                    @s_date            = @s_date,
                    @s_user            = @s_user,
                    @s_term            = @s_term,
                    @s_ofi             = @s_ofi,
                    @t_trn             = 19911,
                    @t_debug           = 'N',
                    @t_file            = NULL,
                    @t_from            = NULL,
                    @i_operacion       = 'P',
                    @i_monto           = 0, 
                    @i_monto_mn        = 0, 
                    @i_moneda          = @w_moneda_nacional, 
                    @i_saldo_cap_gar   = @w_saldo_cap_gar,
                    @i_tramite         = @w_tramite,    -- TRAMITE
                    @i_capitaliza      = 'S'
               
               if @@error != 0 or @w_error != 0
                  return @w_error 
            end
         end
      end
   end
   --- FIN  REQ 433
end
return 0
go
