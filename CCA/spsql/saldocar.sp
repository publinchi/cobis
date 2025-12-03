/************************************************************************/
/*   Archivo:              saldocca.sp                                  */
/*   Stored procedure:     sp_saldo_cca                                 */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Fabian de la Torre                           */
/*   Fecha de escritura:   Ene. 1998                                    */
/************************************************************************/
/*                              IMPORTANTE                              */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                                   PROPOSITO                          */
/*   Calcula el saldo actual de un prestamo (en valor acumulado)        */
/************************************************************************/
/*                              MODIFICACIONES                          */
/* Fecha           Nombre         Proposito                             */
/* 05/Feb/2003   Luis Mayorga    Ingreso tipo de pago en el             */
/*                               procedimiento sp_calcula_saldo         */
/* 30/Abr/2007   Elcira Pelaez   NR-537-498                             */
/* 13/Jul/2007   Elcira Pelaez   Def. 8444y 8482  quitar error 721701   */
/* 09/04/2013    A. Munoz        Req. 0353 Alianzas Comerciales         */
/************************************************************************/

use cob_cartera
go

SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

if exists (select 1 from sysobjects where name = 'sp_saldo_cca')
   drop proc sp_saldo_cca
go
---Inc. 38922 partiendo de la ver 4 nov-29-2011
create proc sp_saldo_cca (
   @s_user          login,
   @i_banco         cuenta  = null,
   @i_modo          tinyint = 0,  -- POR DEFAULT PARA TODOS LOS CASOS EXCEPTO CANCELA = 'S' OTROS RUBROS ='N'
   @i_formato_fecha int     = 103,
   @i_tramite_re    int     = null,
   @i_cca           char(1) = 'N',
   @i_origen        char(1) = 'F', -- [F]RONTEND / [B]ACKEND
   /* campos cca 353 alianzas bancamia --AAMG*/
   @i_crea_ext      char(1)      = null,
   @i_tipo_tramite  char(1)  = null,     -- Req. 436 Normalizacion 01/10/2014
   @o_msg_msv       varchar(255) = null out
)
as
declare 
   @w_est_cancelado    tinyint, 
   @w_est_vencido      tinyint,
   @w_operacionca      int,
   @w_est_vigente      tinyint,
   @w_op_toperacion    catalogo,
   @w_op_moneda        smallint,
   @w_op_fecha_liq     datetime,
   @w_saldo_total      money,
   @w_op_monto         money,
   @w_op_banco         cuenta,
   @w_op_tramite       int,
   @w_sp_name          varchar(30),
   @w_error            int,
   @w_or_aplicar       char(1),
   @w_saldo_renovar    money,
   @w_saldo_mora       money, -- Req. 436 Normalizacion 01/10/2014
   @w_cto_imo          catalogo,
   @w_tdividendo       catalogo,
   @w_tplazo           catalogo,
   @w_plazo            smallint,
   @w_clase            catalogo,
   @w_fuente_recurso   varchar(10),
   @w_destino          catalogo,
   @w_concepto_cred    catalogo,
   @w_ciudad_destino   int


begin
   --- VARIABLES DE TRABAJO 
   select @w_est_cancelado  = 3,
          @w_est_vencido    = 2,
          @w_est_vigente    = 1,
          @w_sp_name        = 'sp_saldo_cca'
          
    select @w_cto_imo = pa_char
    from   cobis..cl_parametro
    where  pa_producto = 'CCA'
    and    pa_nemonico = 'IMO' 
   
   select @w_operacionca = op_operacion,
          @w_op_toperacion = op_toperacion,
          @w_op_moneda     = op_moneda,
          @w_op_fecha_liq  = op_fecha_liq,
          @w_op_monto      = op_monto, 
          @w_op_banco      = op_banco,
          @w_op_tramite    = op_tramite,
          @w_tdividendo    = op_tdividendo,
          @w_tplazo        = op_tplazo,
          @w_plazo         = op_plazo,
          @w_clase         = op_clase
   from   ca_operacion
   where  op_banco = @i_banco

   select @w_fuente_recurso = tr_fuente_recurso,
          @w_destino        = tr_destino,
          @w_concepto_cred  = tr_concepto_credito,
          @w_ciudad_destino = tr_ciudad_destino
   from cob_credito..cr_tramite
   where tr_tramite = @w_op_tramite
   
   if @i_modo = 0
   begin
      
      exec @w_error = sp_saldo_operacion
           @i_operacion = @w_operacionca
      
      if @w_error <> 0
         goto ERROR
      
      select @w_saldo_total = isnull(sum(sot_saldo_mn), 0)
      from   ca_saldo_operacion_tmp
      where  sot_operacion = @w_operacionca
      
      -- Req. 436 Normalizacion 01/10/2014
      if @i_tipo_tramite = 'M'  
      begin 
         select 
         operacion     = op_operacion,
         num_credito   = op_banco,         
         saldo_mora    = CONVERT(money,0.00)
         into #saldo_mora
         from cob_cartera..ca_operacion
         where op_banco = @i_banco
         and op_estado <> 3    
         
         update #saldo_mora
         set    saldo_mora = (select isnull(sum(am_acumulado - am_pagado), 0)
                              from   ca_dividendo, ca_amortizacion
                              where  di_operacion = operacion
                              and    di_estado = 2
                              and    am_operacion = operacion
                              and    am_dividendo = di_dividendo
                              and    am_concepto  = @w_cto_imo)
              
         
         select do_banco banco, MAX(do_fecha) fecha_max
         into #max_fecha 
         from #saldo_mora, cob_conta_super..sb_dato_operacion with (nolock)
         where do_banco = num_credito
         group by do_banco
   
        
         select @w_saldo_mora = saldo_mora 
         from #saldo_mora
         
         if @i_crea_ext is null  
         begin  
            select 'Nro. Operacion'    = @w_op_banco,  
                'Linea '            = @w_op_toperacion,  
                'Monto Original'    = @w_op_monto,  
                'Saldo Obligacion'              = isnull(@w_saldo_total,@w_op_monto),  
                'Total credito reestructurado'  = isnull(@w_saldo_total - @w_saldo_mora,0),
                'Total a pagar otros conceptos' = isnull(@w_saldo_mora,0),
                'Moneda Op'         = @w_op_moneda,
                'Fecha Liquidacion' = convert(varchar, @w_op_fecha_liq, 103),  
                'Producto'          = 'CCA',  
                'Tipo Seleccion'    = '0',  
                'Total Renovar'     = isnull(@w_saldo_total,0),
                'Periodicidad'      = @w_tdividendo,
                'Tipo Plazo'        = @w_tplazo,
                'Plazo'             = isnull(@w_plazo,0),
                'Clase'             = @w_clase,
                'Fuente Recursos'   = @w_fuente_recurso,
                'Destino'           = @w_destino,
                'Ciudad Destino'    = isnull(@w_ciudad_destino,0)
         end  
      end
      else
      begin
         if @i_crea_ext is null  
         begin  
            select 'Nro. Operacion'    = @w_op_banco,  
                'Linea '            = @w_op_toperacion,  
                'Monto Original'    = @w_op_monto,  
                'Saldo Total'       = @w_saldo_total,  
                'Moneda Op'         = @w_op_moneda,
                'Fecha Liquidacion' = convert(varchar, @w_op_fecha_liq, @i_formato_fecha),  
                'Producto'          = 'CCA',  
                'Tipo Seleccion'    = '0',  
                'Total Renovar'     = 0  
         end  
      end
   end
   
   if @i_modo = 1
   begin
      delete ca_saldos_rubros_tmp
      where  tmp_op_tramite = @w_op_tramite
      and    tmp_user = @s_user
      
      exec @w_error = sp_saldo_operacion
           @i_operacion = @w_operacionca
      
      if @w_error <> 0
         goto ERROR
      
      insert into ca_saldos_rubros_tmp
            (tmp_op_tramite,  tmp_di_estado, tmp_di_es_estado,
             tmp_am_concepto, tmp_am_estado, tmp_am_es_estado,
             tmp_saldo,       tmp_user)
      select tmp_op_tramite   = @w_op_tramite,
             tmp_di_estado    = sot_estado_dividendo,
             tmp_di_es_estado = substring(di.es_descripcion, 1, 10),
             tmp_am_concepto  = sot_concepto,
             tmp_am_estado    = case
                                when sot_concepto = 'CAP' then 1
                                else sot_estado_concepto
                                end,
             tmp_am_es_estado = substring(ru.es_descripcion,1,10),
             tmp_saldo        = sot_saldo_mn,
             @s_user
      from   ca_saldo_operacion_tmp,
             ca_estado ru,
             ca_estado di
      where  sot_operacion = @w_operacionca
      and    sot_saldo_mn > 0
      and    ru.es_codigo = case
                            when sot_concepto = 'CAP' then 1
                            else sot_estado_concepto
                            end
      and    di.es_codigo = sot_estado_dividendo
      --
      order  by sot_estado_dividendo desc
      
      if @i_origen = 'F' and @i_crea_ext is null
      begin
         select tmp_di_es_estado,
                tmp_am_concepto,
                tmp_am_es_estado,
                tmp_saldo,
                (case 
                when  exists (select 1 
                              from   cob_credito..cr_rub_renovar
                              where  rr_tramite      = tmp.tmp_op_tramite
                              and    rr_concepto     = tmp.tmp_am_concepto
                              and    rr_tramite_re  in (null, @i_tramite_re)
                              and    rr_estado       = tmp.tmp_am_estado
                              and    rr_estado_cuota = tmp.tmp_di_estado) then 'S'
                 else 'N'
                 end)
         from   ca_saldos_rubros_tmp tmp
         where  tmp_op_tramite = @w_op_tramite
         and    tmp_user       = @s_user
      end
   end
   
   if @i_modo = 2
   begin
      --Req. 436 Normalizacion para eliminar las operaciones temporales en base al tramite
      if @i_tipo_tramite <> 'M'
      begin
         delete ca_saldos_op_renovar_tmp
         where  tmpr_user       = @s_user
         and    tmpr_tramite_re = @i_tramite_re
      end
      else
      begin 
         delete ca_saldos_op_renovar_tmp
         where  tmpr_tramite_re = @i_tramite_re
      end
      
      declare
         cursor_renovar cursor 
         for select or_num_operacion,          or_toperacion,          or_aplicar, --TIPO SELECCION PARA LOS RUBROS
                    op_operacion,          op_moneda,          op_fecha_liq,
                    op_monto,            op_tramite
             from   cob_credito..cr_op_renovar,
                    cob_cartera..ca_operacion
             where  or_tramite = @i_tramite_re --Nuevo
             and    or_num_operacion = op_banco
         for read only
      
      open  cursor_renovar 
      
      fetch cursor_renovar
      into  @w_op_banco,       @w_op_toperacion,       @w_or_aplicar,
            @w_operacionca,       @w_op_moneda,       @w_op_fecha_liq,
            @w_op_monto,       @w_op_tramite
      
      while @@fetch_status = 0 
      begin
         exec @w_error = sp_saldo_operacion
              @i_operacion = @w_operacionca
         
         if @w_error <> 0
         begin
            close cursor_renovar
            deallocate cursor_renovar
            goto ERROR
         end
         
         select @w_saldo_total = isnull(sum(sot_saldo_mn), 0)
         from   ca_saldo_operacion_tmp
         where  sot_operacion = @w_operacionca
         
         --------------------- moneda operacion
         select @w_saldo_renovar = isnull(sum(sot_saldo_acumulado), 0)
         from   ca_saldo_operacion_tmp, cob_credito..cr_rub_renovar
         where  sot_operacion = @w_operacionca
         and    rr_tramite    = @w_op_tramite
         and    rr_tramite_re = @i_tramite_re
         and    rr_concepto   = sot_concepto
         and    rr_estado     = case
                                when rr_concepto = 'CAP' then 1
                                else sot_estado_concepto
                                end
         and    rr_estado_cuota = sot_estado_dividendo
         
         
         insert into ca_saldos_op_renovar_tmp
         values(@s_user,          @i_tramite_re,   @w_op_banco,  @w_op_toperacion,  @w_op_monto,  
                @w_saldo_total,   @w_op_fecha_liq, @w_op_moneda, 'CCA',             @w_or_aplicar,
                @w_saldo_renovar)
         
         fetch cursor_renovar
         into  @w_op_banco,      @w_op_toperacion, @w_or_aplicar,
               @w_operacionca,   @w_op_moneda,     @w_op_fecha_liq,
               @w_op_monto,      @w_op_tramite
      end
      
      close cursor_renovar
      deallocate cursor_renovar 
      
      -- Req. 436 Normalizacion 01/10/2014
      if @i_tipo_tramite = 'M' begin
	  
         select 
         sm_operacion      = op_operacion,
         sm_num_credito    = op_banco,         
         sm_saldo_mora     = CONVERT(money,0.00),
         sm_tdividendo     = op_tdividendo,
         sm_tplazo         = op_tplazo,
         sm_plazo          = isnull(op_plazo,0),
         sm_clase          = op_clase,
         sm_fuente_recurso = tr_fuente_recurso,
         sm_destino        = tr_destino,
         sm_ciudad_destino = isnull(tr_ciudad_destino,0), tr_tramite
         into #saldo_mora2
         from  cob_credito..cr_tramite, cob_credito..cr_op_renovar, cob_cartera..ca_operacion
         where op_tramite = tr_tramite
         and   op_banco   = or_num_operacion
         and   or_tramite = @i_tramite_re
         and   op_estado <> 3	 
         
         update #saldo_mora2
         set    sm_saldo_mora = (select isnull(sum(am_acumulado - am_pagado), 0)
                                 from   ca_dividendo, ca_amortizacion
                                 where  di_operacion = sm_operacion
                                 and    di_estado = 2
                                 and    am_operacion = sm_operacion
                                 and    am_dividendo = di_dividendo
                                 and    am_concepto  = @w_cto_imo)
         
         if @i_crea_ext is null begin              
            select distinct
            'Nro. Operacion'    = tmpr_banco,  
            'Linea '            = tmpr_linea,  
            'Monto Original'    = tmpr_monto_des,  
            'Saldo Obligacion'              = isnull(tmpr_saldo_hoy,tmpr_monto_des),  
            'Total credito reestructurado'  = isnull(tmpr_saldo_hoy - sm_saldo_mora,0),
            'Total a pagar otros conceptos' = isnull(sm_saldo_mora,0),
            'Moneda Op'         = tmpr_moneda,
            'Fecha Liquidacion' = convert(varchar,tmpr_fecha_liq,@i_formato_fecha),
            'Producto'          = tmpr_producto,  
            'Tipo Seleccion'    = tmpr_tipo_seleccion,  
            'Total Renovar'     = isnull(tmpr_saldo_hoy,0),
				   
            'Periodicidad'      = sm_tdividendo,
            'Tipo Plazo'        = sm_tplazo,
            'Plazo'             = isnull(sm_plazo,0),
            'Clase'             = sm_clase,
            'Fuente Recursos'   = sm_fuente_recurso,
            'Destino'           = sm_destino,
            'Ciudad Destino'    = isnull(sm_ciudad_destino,0)				
            from #saldo_mora2, ca_saldos_op_renovar_tmp
            where sm_num_credito  = tmpr_banco
            and   tmpr_tramite_re = @i_tramite_re
         end  
      end
      else
      begin  
         ---ENVIO DE DATOS AL  FRONT-END DE TRAMITSE PARA CUANDO EXISTE YA UN TRAMITE EN RUTA  
         if @i_cca = 'N' and @i_crea_ext is null  
         begin  
            select   
               'Nro. Operacion'    = tmpr_banco,  
               'Linea '            = tmpr_linea,  
               'Monto Original'    = tmpr_monto_des,  
               'Saldo Total'       = tmpr_saldo_hoy,  
               'Moneda Op'         = tmpr_moneda,  
               'Fecha Liquidacion' = convert(varchar,tmpr_fecha_liq,@i_formato_fecha),  
               'Producto'          = tmpr_producto,  
               'Tipo Seleccion'    = tmpr_tipo_seleccion,  
               'Total Renovar'     = tmpr_saldo_renovar  
            from ca_saldos_op_renovar_tmp  
            where tmpr_user       = @s_user  
            and tmpr_tramite_re   = @i_tramite_re  
          end           
      end         
   end
   
   return 0
end

ERROR:
if @i_crea_ext is null
begin
   exec cobis..sp_cerror
        @t_debug = 'N',
        @t_file  = null,
        @t_from  = @w_sp_name,
        @i_num   = @w_error
end
else
begin
   select @o_msg_msv = mensaje
   from   cobis..cl_errores
   where  numero     = @w_error
   
   if @@rowcount = 0
      select @o_msg_msv = 'ERROR: EN EJECUCION, ' + @w_sp_name
   else
      select @o_msg_msv = @o_msg_msv + ', ' + @w_sp_name
end
return @w_error
go
