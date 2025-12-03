/************************************************************************/
/*   Archivo:              fagcapital.sp                                */
/*   Stored procedure:     sp_comision_capitalizacion                   */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Elcira Pelaez                                */
/*   Fecha de escritura:   Abr. 2006                                    */
/************************************************************************/
/*                                  IMPORTANTE                          */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   "MACOSA".                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/*                                   PROPOSITO                          */
/*   Realiza el reverso de la afectacion en garantias por efecto        */
/*   de capitalizaciones en oepraciones con garantias FAG               */
/************************************************************************/
/*                                 MODIFICACIONES                       */
/*   FECHA         AUTOR            RAZON                               */
/*                                                                      */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_comision_capitalizacion')
   drop proc sp_comision_capitalizacion
go

create proc  sp_comision_capitalizacion( 
   @s_date                 datetime     = null,
   @s_ofi                  smallint     = null,
   @s_ssn                  int          = null,
   @s_term                 descripcion  = null,
   @s_user                 login        = null,
   @i_operacionca          int,
   @i_secuencial_retro     int,
   @i_tramite              int
   
)as   
   
Declare
   @w_parametro_fag         varchar(30),
   @w_agotada               char(1),
   @w_contabiliza           char(1),
   @w_tipo_gar              varchar(64),
   @w_abierta_cerrada       char(1),
   @w_estado                char(1),
   @w_monto_gar_mn          money,
   @w_monto_gar             money,
   @w_tramite               int,
   @w_saldo_cap_gar         money,
   @w_error                 int,
   @w_cotizacion            money,
   @w_secuencial            int


select @w_parametro_fag = pa_char
from  cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'COMFAG'
set transaction isolation level read uncommitted

if exists (select 1 from ca_amortizacion
              where am_operacion = @i_operacionca
              and   am_concepto  = @w_parametro_fag
              and   am_estado   != 3 )
begin 

       select @w_estado          = cu_estado,
              @w_agotada         = cu_agotada,
              @w_abierta_cerrada = cu_abierta_cerrada,
              @w_tipo_gar        = cu_tipo
      from   cob_custodia..cu_custodia,
             cob_credito..cr_gar_propuesta
      where  gp_garantia = cu_codigo_externo 
      and    cu_agotada = 'S'
      and    gp_tramite = @i_tramite
      and    cu_estado   in ('V', 'X', 'F')
      
      select @w_contabiliza = tc_contabilizar
      from   cob_custodia..cu_tipo_custodia
      where  tc_tipo = @w_tipo_gar 
            

     if (@w_estado = 'V' and @w_agotada = 'S' and @w_abierta_cerrada = 'C' and @w_contabiliza = 'S')
      begin

            declare
               cursor_rev_capitalizacion cursor
               for select tr_secuencial
                   from   ca_transaccion
                   where  tr_operacion = @i_operacionca
                   and    tr_secuencial  >= @i_secuencial_retro
                   and    tr_tran        = 'CRC'
                   and    tr_estado      != 'RV'
                   order by tr_secuencial
                   for read only
            
            open cursor_rev_capitalizacion 
            
            fetch cursor_rev_capitalizacion
            into  @w_secuencial
            
            while (@@fetch_status = 0) 
            begin
                  set rowcount 1
                  select @w_cotizacion = dtr_cotizacion
                  from ca_det_trn
                  where dtr_operacion  = @i_operacionca
                  and   dtr_secuencial = @w_secuencial
                  and   dtr_concepto   = 'CAP'
                  set rowcount 0
                  
                  ---Saldo de capital en cada historia de CRC
                  
                  select @w_saldo_cap_gar = @w_cotizacion * (sum(amh_cuota + amh_gracia - amh_pagado))
                  from   ca_amortizacion_his, 
                         ca_rubro_op_his
                  where  roh_operacion  = @i_operacionca
                  and    roh_secuencial = amh_secuencial
                  and    roh_secuencial   = @w_secuencial
                  and    amh_secuencial   = @w_secuencial
                  and    roh_tipo_rubro = 'C'
                  and    amh_operacion  = @i_operacionca
                  and    amh_estado <> 3
                  and    amh_concepto   = roh_concepto
                   
                 ---PRINT 'fagcapital.sp ca para sp_Agotada a reversar @w_saldo_cap_gar %1! @w_secuencial %2!',@w_saldo_cap_gar,@w_secuencial
                 
                  exec @w_error = cob_custodia..sp_agotada 
                       @s_ssn       = @s_ssn,
                       @s_date      = @s_date,
                       @s_user      = @s_user,
                       @s_term      = @s_term,
                       @s_ofi       = @s_ofi,
                       @t_trn       = 19911,
                       @t_debug     = 'N',
                       @t_file      = NULL,
                       @t_from      = NULL,
                       @i_operacion = 'R',
                       @i_monto     = 0,
                       @i_monto_mn  = 0,
                       @i_moneda    = 0,
                       @i_saldo_cap_gar = @w_saldo_cap_gar,
                       @i_tramite   = @i_tramite,
                       @i_capitaliza  = 'S'
                     
                     if @w_error != 0  
                     begin
                        close cursor_rev_capitalizacion
                        deallocate cursor_rev_capitalizacion
                        goto ERROR
                     end
               
                     
            
             fetch cursor_rev_capitalizacion
             into  @w_secuencial
            
            end --END WHILE
         
         close cursor_rev_capitalizacion
         deallocate cursor_rev_capitalizacion
      end -- garantia agotada

   
end --tiene fag


   
return 0

ERROR:
 return @w_error
go