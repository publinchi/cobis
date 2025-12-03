/* **********************************************************************/
/*      Archivo:                rechdesmas.sp                           */
/*      Stored procedure:       sp_rech_des_mas                         */
/*      Producto:               CARTERA                                 */
/*      Disenado por:           Jonnatan Peña                           */
/*      Fecha de escritura:     27-04-2009                              */
/* **********************************************************************/
/*                            IMPORTANTE                                */
/*    Este programa es parte de los paquetes bancarios propiedad de     */
/*    'COBISCORP'                                                       */
/*    Su  uso no autorizado  queda expresamente  prohibido asi como     */
/*    cualquier   alteracion  o  agregado  hecho por  alguno de sus     */
/*    usuarios   sin el debido  consentimiento  por  escrito  de la     */
/*    Presidencia Ejecutiva de COBISCORP o su representante.            */
/* **********************************************************************/
/*                             PROPOSITO                                */
/* sp para ejecutar diarimente en el proceso batch  para el reverso de  */
/* desembolsos que no tuvieron movimientos despues de la aprobacion     */
/************************************************************************/
/*                            MODIFICACIONES                            */
/* FECHA      AUTOR           RAZON                                     */
/* 																		*/
/************************************************************************/

use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_rech_des_mas')
    drop proc sp_rech_des_mas
go

create proc sp_rech_des_mas(
   @s_date        datetime,
   @s_user        login,
   @s_ssn         int         = null,
   @s_srv         varchar(30) = null,
   @s_term        varchar(30) = null,
   @s_ofi         smallint    = null, 
   @s_rol         smallint    = null, 
   @t_rty         char(1)     = NULL,   
   @i_debug       char(1)     = 'N'             
)
as

declare 
   @w_error            int,
   @w_sp_name          varchar(30),
   @w_operacionca      int,
   @w_secuencial       int,
   @w_banco            varchar(30),
   @w_orden_pago       int,
   @w_registros        int         
  
 
select @w_sp_name = 'sp_rech_des_mas'   
             
declare reversa_masiva cursor 
for select max(dm_secuencial),
		   dm_operacion,
		   dm_orden_caja
    from ca_desembolso
	where dm_pagado = 'I'
	and   dm_producto  = 'EFMN'   	   
	group by dm_secuencial, dm_operacion, dm_orden_caja
	
for read only
open reversa_masiva
fetch reversa_masiva 
into @w_secuencial, @w_operacionca, @w_orden_pago

    
while @@fetch_status = 0
begin 
   
   select @w_registros = count(tr_secuencial)
   from ca_transaccion  
   where tr_operacion = @w_operacionca
   and tr_estado = 'ING'   	
   
   if @w_registros = 1
   begin
   
      select  @w_banco = op_banco             
      from cob_cartera..ca_operacion 
      where op_operacion = @w_operacionca 
      
      
      if @w_secuencial <> 0 
      begin
         exec @w_error    = sp_fecha_valor 
         @s_ssn           = @s_ssn,
         @s_srv           = @s_srv,
         @t_rty           = @t_rty,
         @s_user          = @s_user,
         @s_term          = @s_term,
         @s_date          = @s_date,
         @s_ofi           = @s_ofi,
         @i_banco         = @w_banco,
         @i_secuencial    = @w_secuencial,
         @i_operacion     = 'R'
                             
         if @@error != 0 or  @w_error <> 0
         begin                        
            goto ERROR
         end 
         
         exec cob_interface..sp_genera_orden
         @s_date        = @s_date,
         @s_user        = @s_user,
         @i_operacion   = 'A',
         @i_idorden     = @w_orden_pago
         
         if @@error != 0 or  @w_error <> 0
         begin                        
            goto ERROR
         end 
         
         ERROR:
         exec sp_errorlog 
         @i_fecha     = @s_date,
         @i_error     = @w_error, 
         @i_usuario   = @s_user, 
         @i_tran      = 7999,
         @i_tran_name = @w_sp_name,
         @i_cuenta    = @w_banco,
         @i_rollback  = 'S'
                                                   
      end
   end
   fetch reversa_masiva into @w_secuencial, @w_operacionca, @w_orden_pago 
end

close reversa_masiva
deallocate reversa_masiva


return 0
go

