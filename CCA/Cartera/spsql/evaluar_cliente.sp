/************************************************************************/
/*      Archivo:                evaluar_cliente.sp                       */
/*      Stored procedure:       sp_evaluar_cliente                       */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Credito y Cartera                       */
/*      Disenado por:           Daniel Nieto                            */
/*      Fecha de escritura:     11/2011                                 */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA".                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/************************************************************************/


use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_evaluar_cliente')
   drop proc sp_evaluar_cliente
go


create proc [dbo].[sp_evaluar_cliente] (
@s_date                       datetime = null,
@s_user                       login    = null,
@s_ofi                        int      = null,
@i_evento                     catalogo  ,
@i_operacionca                int       ,
@i_secuencial                 int      = 0,
@o_msg                        descripcion = null out,
@o_msg_matriz                 descripcion = null out)
as
declare
@w_error                      int         ,
@w_msg                        varchar(255),
@w_sp_name                    varchar(30) ,
@w_operacion                  char(1)     ,
@w_cliente                    int         ,
@w_banca                      catalogo    ,
@w_segmento                   catalogo    ,
@w_banco                      cuenta      ,
@w_porc_pago_sobre_desembolso float       ,
@w_porcentaje_cuota_cancelada float       ,
@w_resultado_matriz           float       ,
@w_matriz_calculo             catalogo    ,
@w_evento                     int         ,
@w_op_monto                   int         ,
@w_descripcion_estado         int         ,
@w_nota                       int         ,
@w_resultado                  float       ,
@w_resultado1                 float       ,
@w_resultado2                 float       ,
@w_porcentaje_prospecto       int         ,
@w_est_vigente                tinyint     ,
@w_est_vencido                tinyint     ,
@w_est_cancelado              tinyint     ,
@w_est_castigado              tinyint     ,
@w_est_suspenso               tinyint     ,
@w_est_diferido               tinyint     ,
@w_tipo_pref                  char(1)     ,
@w_monto_pago                 float       ,
@w_oficina                    int         ,
@w_fecha_proceso              datetime    
	

select 
@w_sp_name = 'sp_evaluar_cliente',
@w_porc_pago_sobre_desembolso = 0

exec @w_error = sp_estados_cca
@o_est_vigente    = @w_est_vigente   out,
@o_est_vencido    = @w_est_vencido   out,
@o_est_cancelado  = @w_est_cancelado out,
@o_est_castigado  = @w_est_castigado out,
@o_est_suspenso   = @w_est_suspenso  out,
@o_est_diferido   = @w_est_diferido  out

if @w_error <> 0 begin
   select @o_msg = 'ERROR AL EJECUTAR sp_estados_cca'
   return @w_error
end

/*DETERMINAR LA FECHA DE PROCESO*/
select @w_fecha_proceso = fp_fecha from cobis..ba_fecha_proceso

select 
@w_cliente  = op_cliente,
@w_op_monto = op_monto,
@w_oficina  = op_oficina
from ca_operacion 
where op_operacion = @i_operacionca

select @w_banca = en_banca 
from cobis..cl_ente 
where en_ente = @w_cliente

select @w_segmento = mo_segmento 
from cobis..cl_mercado_objetivo_cliente 
where mo_ente = @w_cliente

exec @w_error = cob_credito..sp_calif_interna_cliente
@i_cliente      = @w_cliente,
@o_calificacion = @w_nota out, 
@o_msg          = @o_msg  out

if @w_error <> 0
   return @w_error

/* DETERMINAR  EL PORCENTAJE DE PAGO RESPECTO AL MONTO DEL DESEMBOLSO*/
--if @i_secuencial <> 0 begin

select @w_monto_pago = isnull(sum(am_pagado),0)
from   cob_cartera..ca_amortizacion
where  am_operacion = @i_operacionca
and    am_concepto  = 'CAP'

if  @w_monto_pago is null
   select @w_monto_pago = 0

select @w_porc_pago_sobre_desembolso = (@w_monto_pago/@w_op_monto)*100

if @w_porc_pago_sobre_desembolso > 100
begin
   select @w_porc_pago_sobre_desembolso = 100
end

--end

if @i_evento = 'BAT' begin 
   select @w_resultado1 =  count(1)
   from ca_dividendo
   where di_fecha_ven < dateadd(day,30,@s_date)
   and   di_operacion = @i_operacionca
end 
else begin
   select @w_resultado1 =  count(1)
   from ca_dividendo
   where di_estado    = @w_est_cancelado
   and   di_operacion = @i_operacionca
end 

   
select @w_resultado2 =  count(1)
from ca_dividendo
where  di_operacion = @i_operacionca

select @w_porcentaje_cuota_cancelada = (@w_resultado1/@w_resultado2)*100


select @w_matriz_calculo = ma_matriz                  
from ca_matriz    
where ma_matriz = 'POL_CTROFE' 


/*se ejecuta el procedimiento sp_matriz_valor para que retorne el valor si es cliente especial o no*/

exec @w_error = sp_matriz_valor
@i_matriz         = @w_matriz_calculo,
@i_fecha_vig      = @w_fecha_proceso,
@i_eje1           = @w_banca,
@i_eje2           = @w_segmento,
@i_eje3           = @i_evento,
@i_eje4           = @w_nota,
@i_eje5           = @w_porc_pago_sobre_desembolso,
@i_eje6           = @w_porcentaje_cuota_cancelada,
@o_valor          = @w_resultado_matriz out,
@o_msg            = @o_msg out

if @w_error <>0 return @w_error
--select @w_matriz_calculo,@w_fecha_proceso,@w_banca,@w_segmento,@i_evento,@w_nota,@w_porc_pago_sobre_desembolso,@w_porcentaje_cuota_cancelada,@w_resultado_matriz


 /*cuando el evento no es bat y el resultado de la matriz es cliente preferencial = 1 */
 
 if @w_resultado_matriz = 1 begin
   if  @i_evento <>  'BAT' begin
      select @w_tipo_pref = case 
                            when @i_evento = 'CAN' then 'C'
                            when @i_evento in ('EXT','PAG') then 'A'
                            when @i_evento = 'CON' then 'P'
                            else'X'
                            end
      if not exists(select 1 from cob_credito..cr_cliente_campana, cob_credito..cr_campana 
                    where cc_campana= ca_codigo and ca_clientesc='ESPECIAL' and ca_estado='V' and cc_cliente= @w_cliente)
      begin  
      
      exec @w_error = cob_credito..sp_cliente_pref
      @i_cliente     = @w_cliente,
      @i_tipo_pref   = @w_tipo_pref,                                                                                                                                                     
      @i_fecha       = @w_fecha_proceso,                                                                                                                                                
      @i_org_carga   = 'CCA',
      @i_oficina     = @w_oficina,
      @o_msg         = @w_msg out
      
      
      if @w_error <> 0 begin
         select @o_msg = 'ERROR AL EJECUTAR sp_cliente_pref'
         return @w_error
      end
      
 
      exec @w_error = sp_mensaje_contraoferta
      @i_banca       = @w_banca,
      @i_evento      = @i_evento,
      @i_fecha       = @w_fecha_proceso,
      @o_mensaje_mat = @o_msg_matriz output,
      @o_msg         = @o_msg output
           
      if @w_error <>0 begin 
         select @o_msg
         return @w_error
      end
   end
   else begin
      exec @w_error  = cob_credito..sp_registro_prospecto
      @i_cliente     = @w_cliente,
      @i_operacionca = @i_operacionca,
      @i_fecha       = @w_fecha_proceso,
      @o_msg         = @o_msg
      
      if @w_error <>0 begin 
         select @o_msg
         return @w_error
      end
   end
   end
end 
/*
if @w_resultado_matriz = 1 begin
   print 'Este Cliente es ESPECIAL  Mensaje: ' + @o_msg_matriz
end
else begin
   print 'Este Cliente NO es ESPECIAL'
end*/


return 0

go