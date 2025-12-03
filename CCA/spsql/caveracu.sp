/************************************************************************/
/*      Archivo:                caveracu.sp                             */
/*      Stored procedure:       sp_verifica_acuerdo                     */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Fabian de la Torre                      */
/*      Fecha de escritura:     Octubre 2010                            */
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
/*      Verifica el cumplimiento de un acuerdo de pago                  */
/*                                                                      */
/************************************************************************/
/*                           MODIFICACIONES                             */
/*      FECHA           AUTOR             RAZON                         */
/*      04/Nov/2010     J. Loyo           Creacion Inicial              */
/************************************************************************/
use cob_cartera
go

if object_id('sp_verifica_acuerdo') is not null
   drop proc sp_verifica_acuerdo
go

create proc sp_verifica_acuerdo
@s_user          login       = null,
@s_srv           varchar(30) = null,
@s_term          varchar(30) = null, 
@s_date          datetime    = null,
@s_ofi           smallint    = null,
@i_debug         char(1)     = 'N',
@i_banco         cuenta,
@i_fecha         datetime
as

declare
@w_sp_name              varchar(30),
@w_return               int,
@w_error                int,
@w_rowcount             int,
@w_operacion            int,
@w_cliente              int,
@w_oficial              smallint,
@w_tramite              int,
@w_acuerdo              int,
@w_valor                money,
@w_fecha_ing            datetime, 
@w_fecha_cuota          datetime,
@w_fecha_max            datetime,
@w_fecha_anterior       datetime,
@w_fecha                datetime,        
@w_oficina              smallint,
@w_pagos                money,
@w_sec_trn              int,
@w_sec_ing              int,
@w_cuota                money,
@w_dias_gracias         smallint,
@w_estado               varchar(1),
@w_sec_rpa              int,
@w_tipo_cobro           char(1),
@w_cumplido             char(1),
@w_tacuerdo             char(1),
@w_fecha_ult_proceso    datetime,
@w_cuotas_ant           money

      
/* INICIALIZACION VARIABLES */
select 
@w_sp_name  = 'sp_verifica_acuerdo',
@w_fecha    = @i_fecha,
@w_cumplido = 'N'

/*** Validamos que la operacion exista ****/
select 
@w_operacion         = op_operacion,
@w_oficina           = op_oficina
from cob_cartera..ca_operacion
where op_banco =  @i_banco

if @@rowcount = 0
   return 701013 /***  No existe operacion activa de cartera ***/

/*** Validamos que la operacion tenga un acuerdo ****/
select top 1
@w_acuerdo    = ac_acuerdo, 
@w_tacuerdo   = ac_tacuerdo,
@w_fecha_ing  = ac_fecha_ingreso,
@w_sec_rpa    = ac_secuencial_rpa,
@w_tipo_cobro = ac_tipo_cobro_org
from cob_credito..cr_acuerdo (nolock)
where ac_banco         = @i_banco
and   ac_estado        = 'V'
--and   @w_fecha   between ac_fecha_ingreso and ac_fecha_proy
order by ac_fecha_ingreso desc

if @@rowcount = 0
   return 0 /***  OJO RETORNA POR QUE NO HAY ACUERDOS  ***/

/*** Revisamos el valor para la cuota por Vencer o incumplida mas cerca al dia *******/
select top 1 
@w_fecha_cuota  = av_fecha,
@w_cuota        = av_monto,
@w_dias_gracias = av_gracia,
@w_fecha_max    = dateadd(dd, av_gracia, av_fecha ),
@w_estado       = av_estado
from cob_credito..cr_acuerdo_vencimiento
where av_acuerdo =  @w_acuerdo
and   av_estado <> 'OK'
order by av_fecha ASC

if @@rowcount = 0
begin
   return 0  /***  OJO Retorno porque no hay cuotas pendientes ***/
end

/*****************************************************************************************************************/
/*** Si estoy Dentro del rango de fechas valido si el pago ya esta completo y actualizo, sino sigo pendiente   ***/   
/*****************************************************************************************************************/ 
if @w_fecha >=  @w_fecha_cuota  and  @w_fecha <= @w_fecha_max
begin 
   /****************************************************************************************************************/ 
   /** Se buscan los pagos realizados entre la fecha de la cuota anterior y la cuota maxima de pago de la cuota ****/
   select tr_secuencial
   into #pagos
   from ca_transaccion
   where tr_operacion       = @w_operacion
   and   tr_fecha_ref between @w_fecha_ing and @w_fecha
   and   tr_tran            = 'RPA'       
   and   tr_estado         <> 'RV'   
   and   tr_secuencial      > 0
        
   select @w_pagos = isnull(sum (dtr_monto),0)
   from ca_det_trn, #pagos
   where dtr_operacion  = @w_operacion
   and   dtr_secuencial = tr_secuencial
   and   dtr_concepto   = 'VAC0'
   
   select @w_cuotas_ant = isnull(sum(av_monto), 0)
   from cob_credito..cr_acuerdo_vencimiento 
   where av_acuerdo = @w_acuerdo
   and   av_fecha   < @w_fecha_cuota
   
   /*****************************************************************************************************************/ 
   /****    Si el Monto de los pagos es mayor a la cuota actualizo el registro de cuotas del acuerdo              ***/ 
   if @w_pagos - @w_cuotas_ant >= @w_cuota 
   begin     
      update cob_credito..cr_acuerdo_vencimiento set 
      av_estado       = 'OK',  
      av_fecha_estado = @w_fecha
      where av_acuerdo = @w_acuerdo
      and   av_fecha   = @w_fecha_cuota
      
      if @@error <> 0
      begin
         select @w_error = 710568 -- Error en la Actualizacion del registro!!! 
         return @w_error 
      end
      
      select @w_cumplido = 'S'
   end  /*****************************************************************/ 
end /**** Finaliza el bloque dentro del rango permitido para pago   ***/

/**********************************************************************************************/
/*** Si la fecha actual es mayor al rango de pago coloco como vencido y devuelvo los pagos ****/
/**********************************************************************************************/   
if @w_fecha = @w_fecha_max and @w_cumplido = 'N'
begin
   /* SE MARCA EL ACUERDO COMO INCUMPLIDO */
   exec @w_error = cob_credito..sp_acuerdo
   @s_user      = @s_user,
   @s_ofi       = @s_ofi,
   @s_date      = @s_date,
   @i_modo      = 'U',
   @i_acuerdo   = @w_acuerdo,
   @i_estado_ac = 'I'
   
   if @@error <> 0 
      return @w_error
      
   /*****************************************************/
   /*** Generamos fecha valor para el Dia del Acuerdo ***/
   exec @w_error = sp_fecha_valor 
   @s_user              = @s_user,             
   @s_term              = @s_term, 
   @s_date              = @s_date,
   @i_debug             = @i_debug,           --> Fecha de proceso del modulo cartera
   @i_fecha_valor       = @w_fecha_ing,       --> Fecha desde cuando se inicia el acuerdo.
   @i_banco             = @i_banco,           --> Operacion a la cual se le aplica la fecha valor
   @i_operacion         = 'F',
   @i_en_linea          = 'S',
   @i_control_fecha     = 'N'

   if @@error <> 0 
        return @w_error

   update cob_credito..cr_acuerdo_vencimiento set 
   av_estado       = 'VE',  
   av_fecha_estado = @w_fecha
   where av_acuerdo = @w_acuerdo
   and   av_fecha   = @w_fecha_cuota
   
   if @@error <> 0
   begin
      print ' Error al actualizar el estado de la cuota vencida'
      return 1
   end  
      
   if @w_sec_rpa is not null
   begin
      /***************************************************************************/
      /***  buscar el secuencial de ingreso del pago con el secuencial del rpa  **/     
     
      select @w_sec_ing = ab_secuencial_ing
      from ca_abono
      where ab_operacion      = @w_operacion  -- Sec interno de la operacion desde ca_operacion.op_operacion
      and   ab_secuencial_rpa = @w_sec_rpa    -- Sec Rpa del acuerdo.
      
      if @@rowcount <> 1 
      begin
         select @w_error = 710023   --    No existen Pagos
         return @w_error
      end          
      
      delete ca_abono_det
      where abd_operacion      = @w_operacion
      and   abd_secuencial_ing = @w_sec_ing
      and   abd_tipo           = 'CON'
      
      if @@error <> 0
         return 710003
         
      if @w_tacuerdo = 'P'
      begin
         update ca_abono
         set ab_tipo_cobro = @w_tipo_cobro
         where ab_operacion  = @w_operacion
         and   ab_estado     = 'NA'
         and   ab_fecha_pag >= @w_fecha_ing
         
         if @@error <> 0  
            return 710002
      end
   end
   
   if @w_tacuerdo = 'P'
   begin
      -- CUANDO ES ACUERDO DE PRECANCELACION SE DEVUELVE
      -- LA MODALIDAD DE APLICACION DE LOS PAGOS ORIGINAL
      update ca_operacion
      set op_tipo_cobro = @w_tipo_cobro
      where op_banco = @i_banco
      
      if @@error <> 0
      begin
         print 'ERROR AL MODIFICAR TIPO DE COBRO'
         return 705007
      end
   end
      
   /*****************************************************/
   /*** Generamos fecha valor para el Dia actual -    ***/
   /*** reaplicando los pagos levantados              ***/
   
   exec @w_error = sp_fecha_valor 
   @s_user              = @s_user,        
   @s_term              = @s_term, 
   @s_date              = @s_date,           --> Fecha de proceso del m¾dulo cartera
   @i_debug             = @i_debug,
   @i_fecha_valor       = @w_fecha,       --> Fecha desde cuando se inicia el acuerdo.
   @i_banco             = @i_banco,           --> Operacion a la cual se le aplica la fecha valor
   @i_operacion         = 'F',
   @i_en_linea          = 'S',
   @i_control_fecha     = 'N'

   if @@error <> 0 
      return @w_error
               
end

return 0
go
