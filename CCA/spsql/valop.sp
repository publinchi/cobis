/***********************************************************************/
/*  Archivo:            valop.sp                                       */
/*  Stored procedure:   SP_NOTA                                        */
/*  Base de Datos:      cob_cartera                                    */
/*  Producto:           Cartera                                        */
/*  Disenado por:       Geoconda Yánez                                 */
/***********************************************************************/
/*      IMPORTANTE                                                     */
/*  Este programa es parte de los paquetes bancarios propiedad de      */
/*  "MACOSA",representantes exclusivos para el Ecuador de la           */
/*  AT&T                                                               */
/*  Su uso no autorizado queda expresamente prohibido asi como         */
/*  cualquier autorizacion o agregado hecho por alguno de sus          */
/*  usuario sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de MACOSA o su representante                 */
/***********************************************************************/
/*      PROPOSITO                                                      */
/*  Procedimiento para realizar validaciones de notas y porcentajes    */
/***********************************************************************/
/*      MODIFICACIONES                                                 */
/*  FECHA            AUTOR                RAZON                        */
/*  21/Ene/10       Geoconda Yánez        Emision Inicial              */
/*  06/Oct/10       Johan Ardila          Req 151 - Contraofertas      */
/***********************************************************************/

use cob_cartera
go


if exists (select 1 from sysobjects where name='sp_valop')
   drop procedure sp_valop
go


create proc sp_valop(
   @i_banco             cuenta   = null,     --Número de operación
   @i_cliente           int      = null,     --Número de cliente
   @i_operacion         char(1)  = null,     --Código de Operación
   @i_fecha_pro         datetime = null,     --Fecha Proceso
   @i_cuota_ant         money    = null,     --Vr. Cuota antes del pago
   @i_tipo_reduccion    char(1)  = null,     --Tipo de reducción Pago
   @i_pago_ext          char(1)  = 'N'      --Campo para validacion de pago desde CNB
   )

   as
   declare 

   /*DECLARACION DE VARIABLES*/
   @w_sp_name           varchar(32),
   @w_porcentaje        float,
   @w_porc_canc         float,
   @w_tipo_tr		    char(1),
   @w_tipo_cre          char(1),
   @w_tramite           int,
   @w_num_oper          cuenta,
   @w_cant_canc         float,
   @w_cant_cuotas       float,
   @w_nota              tinyint,
   @w_cliente           int,
   @w_minnota           tinyint,
   @w_minporc           tinyint,
   @w_ult_fecha_proceso datetime,
   -- INI JAR REQ 151
   @w_mensaje           varchar(80),
   @w_return            int,
   @w_oficina           int,
   @w_operacionca       int,
   @w_estado_op         tinyint,
   @w_fecha_pro         datetime,
   @w_tipo_pref         char(1),
   @w_cuota_new         money
   -- FIN JAR REQ 151
   
   select @w_sp_name   = 'SP_VALOP',
   @w_fecha_pro = @i_fecha_pro  -- JAR REQ 151

   -- INI JAR REQ 151
   if @w_fecha_pro is null
   begin
      select @w_fecha_pro = fp_fecha
      from   cobis..ba_fecha_proceso
   end
   -- FIN JAR REQ 151
   
   if @i_operacion = 'V'
   begin
      /*ENCONTRAR DATOS DE LA OPERACION*/
   
      select 
      @w_tramite     = op_tramite,
      @w_cliente     = op_cliente,
      -- INI JAR REQ 151
      @w_oficina     = op_oficina,
      @w_operacionca = op_operacion,
      @w_estado_op   = op_estado,
      @w_cuota_new   = op_cuota  
      -- FIN JAR REQ 151
      from cob_cartera..ca_operacion
      where op_banco = @i_banco  
   
      if @i_cliente is not null or @i_cliente <> 0
         select @w_cliente=@i_cliente	 
   
      -- BUSCAR EL TIPO DE TRAMITE
      select 
      @w_tipo_tr = tr_tipo
      from  cob_credito..cr_tramite
      where tr_tramite = @w_tramite 
   
      --ENCONTRAR PARAMETRO DE NOTA
      select 
      @w_minnota = pa_tinyint
      from  cobis..cl_parametro
      where pa_nemonico = 'MNRV'
      and   pa_producto = 'CCA'
          
      --ENCONTRAR PARAMETRO DE PORCENTAJE
      select 
      @w_minporc = pa_tinyint
      from  cobis..cl_parametro
      where pa_nemonico = 'MPRV'
      and   pa_producto = 'CCA'  
     
      if @w_tipo_tr not in ('U','T')  
      begin -- Ni Unificación , Ni utilización de cupo.
         /*BLOQUE PARA ANALIZAR LA NOTA DEL CLIENTE*/
   
         select 
         @w_nota = min(ci_nota)
         from  cob_cartera..ca_operacion, 
         cob_credito..cr_califica_int_mod
         where op_banco   = ci_banco
         and   op_cliente = @w_cliente       
         and   op_estado in (1, 2, 9, 4)
      
         select 
         @w_ult_fecha_proceso = max(op_fecha_ult_proceso)    
         from  cob_cartera..ca_operacion                         
         where op_cliente = @w_cliente                           
         and   op_estado  = 3                                  
   
         if @w_nota is null  
         begin
            select 
            @w_nota = ci_nota
            from cob_cartera..ca_operacion, 
            cob_credito..cr_califica_int_mod
            where op_banco             = ci_banco
            and   op_cliente           = @w_cliente       
            and   op_fecha_ult_proceso = @w_ult_fecha_proceso
            and   op_estado            = 3
         end
        
         if @w_nota is null  
         begin
            select 
            @w_nota = ci_nota
            from  cob_cartera_his..ca_operacion, 
            cob_credito_his..cr_califica_int_mod_his
            where op_banco             = ci_banco
            and   op_cliente           = @w_cliente       
            and   op_fecha_ult_proceso = @w_ult_fecha_proceso
            and   op_estado            = 3
         end
      
         select @w_nota = isnull(@w_nota, 0)
   
         /* BLOQUE PARA ANALIZAR EL PORCENTAJE */
          
         select @w_cant_canc = 0
         select @w_cant_cuotas = 0
           
         select 
         @w_cant_canc = count(di_dividendo) 
         from cob_cartera..ca_operacion,
         cob_cartera..ca_dividendo 
         where op_banco     = @i_banco
         and   op_operacion = di_operacion
         and   di_estado    = 3
            
         select 
         @w_cant_cuotas = count(di_dividendo) 
         from cob_cartera..ca_operacion,
         cob_cartera..ca_dividendo 
         where op_banco     = @i_banco
         and   op_operacion = di_operacion
                 
         if @w_cant_cuotas = 0 
            select @w_porc_canc = 0
         else
            select @w_porc_canc = (@w_cant_canc / @w_cant_cuotas)  * 100
            
         select @w_porcentaje = @w_porc_canc
                    
         if @w_porcentaje >= @w_minporc and @w_nota >= @w_minnota
         begin
            -- INI JAR REQ 151
            select 
            @w_mensaje ='Cliente Potencial de RENOVACION, Este Cliente debe ser remitido para Asesoria',
            @w_tipo_pref = 'P'
            goto NOVEDAD
            -- FIN JAR REQ 151
         end         
      end -- Tipo U o T
      
      -- INI JAR REQ 151
      -- Validacion Por Cancelacion Deuda
      if @w_estado_op = 3
      begin
         select 
         @w_mensaje   = 'Este Cliente debe ser remitido para Asesoria',
         @w_tipo_pref = 'C'
         goto NOVEDAD
      end
   
      -- Se comenta por decision del Banco Dic.01.2010
      -- Mientras se define por parte del Banco cómo 
      -- quieren proceder en relacion a los Abonos Extraordinarios
      
   --    -- Validacion Por Pago Adelantado
   --    if (select sum(am_pagado)
   --          from cob_cartera..ca_dividendo, cob_cartera..ca_amortizacion
   --         where di_operacion  = @w_operacionca
   --           and di_fecha_ini >= @w_fecha_pro
   --           and di_operacion  = am_operacion
   --           and di_dividendo  = am_dividendo) > 0
   --    begin
   --       select @w_mensaje   = 'Este Cliente debe ser remitido para Asesoria',
   --              @w_tipo_pref = 'A'
   --       goto NOVEDAD
   --    end
   --       
   --    -- Validación si el pago se hizo con reducción de Cuota
   --    if @i_tipo_reduccion = 'C' and @i_cuota_ant > @w_cuota_new
   --    begin
   --       select @w_mensaje   = 'Este Cliente debe ser remitido para Asesoria',
   --              @w_tipo_pref = 'A'
   --       goto NOVEDAD
   --    end
      
      -- Validacion Cliente pertence a Campaña
      if exists (select 1
      from cob_credito..cr_cliente_campana, cob_credito..cr_campana
      where cc_cliente   = @w_cliente
      and   cc_estado    = 'V'
      and   cc_campana   = ca_codigo
      and   ca_estado    = 'V'
      and   ca_clientesc = 'CAMPANA')
      begin
         select
         @w_mensaje   = 'Este Cliente debe ser remitido para Asesoria',
         @w_tipo_pref = 'X'
         goto NOVEDAD
      end
      -- FIN JAR REQ 151
      
   end -- Operacion V

   return 0
   
NOVEDAD:
   if @i_pago_ext = 'N'
      print @w_mensaje
   
   if @w_tipo_pref <> 'X'
   begin
      exec @w_return = cob_credito.. sp_cliente_pref
      @i_cliente    = @w_cliente,
      @i_tipo_pref  = @w_tipo_pref,
      @i_fecha      = @w_fecha_pro,
      @i_org_carga  = 'CCA',
      @i_oficina    = @w_oficina
         
      if @w_return <> 0
      begin   
         return @w_return
      end
   end
      
   return 0
go
