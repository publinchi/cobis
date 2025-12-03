/* **********************************************************************/
/*      Archivo:                recaudes.sp                             */
/*      Stored procedure:       sp_causa_des                            */
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
/*Interfaz cartera - Cajas  para el reverso de desembolsos desde caja   */
/************************************************************************/
/*                            MODIFICACIONES                            */
/* FECHA      AUTOR           RAZON                                     */
/* 																		*/
/************************************************************************/

use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_causa_des')
    drop proc sp_causa_des
go

create proc sp_causa_des(
   @s_date        datetime,
   @s_user        login,
   @s_ssn         int         = null,
   @s_srv         varchar(30) = null,
   @s_term        varchar(30) = null,
   @s_ofi         smallint    = null, 
   @s_rol         smallint    = null, 
   @t_rty         char(1)     = NULL,
   @t_user        login       = null,
   @t_term        varchar(30) = null,
   @t_srv         varchar(30) = null,
   @t_ofi         smallint    = null,
   @t_rol         smallint    = null,
   @i_debug       char(1)     = 'N',
   @i_interfaz    char(1)     = 'N',
   @i_idorden     int         =  0, 
   @i_ref1        int         =  0,
   @i_ref2        int         =  0,
   @i_ref3        varchar(30) =  '',   
   @i_operacion   char(1)               
   
)
as

declare 
   @w_error            int,
   @w_secuencial_des   int,
   @w_banco            varchar(30),
   @w_operacionca      int
   
-- Determinar si la transaccion es ejecutada por el REENTRY del SAIP 
if @t_user is not null begin
   select
   @s_user = @t_user,
   @s_term = @t_term,
   @s_srv  = @t_srv,
   @s_ofi  = @t_ofi,
   @s_rol  = @t_rol
end 

select @w_banco = @i_ref3
                
select @w_operacionca = op_operacion 
from cob_cartera..ca_operacion 
where op_banco = @w_banco
   

if @i_operacion = 'E'
begin   
   update ca_desembolso
   set dm_pagado = 'E'   --E Ejecutado o ingresado / A:APLICADO /R:reversa transaccion orden de pago en caja.'el desembolso queda desconfirmado'
   where dm_operacion = @w_operacionca
   and   dm_producto  = 'EFMN'
   and   dm_orden_caja  = @i_idorden 
   if @@error <> 0
   begin     
      select @w_error = 710305
      goto ERROR
   end
      
   return 0
end

if @i_operacion = 'A'
begin
                                                   	   
   select @w_secuencial_des = max(dm_secuencial)
   from ca_desembolso
   where dm_estado = 'A'
   and dm_operacion = @w_operacionca
   
                     
   if @w_secuencial_des <> 0 
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
      @i_secuencial    = @w_secuencial_des,
      @i_operacion     = 'R'
                          
      if @@error != 0 or  @w_error <> 0
      begin                        
         goto ERROR
      end                                 
   end
end

if @i_operacion = 'R'
begin   
   update ca_desembolso
   set dm_pagado = 'R'   --E Ejecutado o ingresado / A:APLICADO /R:reversa transaccion orden de pago en caja.'el desembolso queda desconfirmado'
   where dm_operacion = @w_operacionca
   and   dm_producto  = 'EFMN'
   and   dm_orden_caja  = @i_idorden 
   if @@error <> 0
   begin     
      select @w_error = 710305
      goto ERROR
   end
      
   return 0
end

      
return 0

ERROR:
return @w_error

go
