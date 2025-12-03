/************************************************************************/
/*   Archivo:              camopex.sp                                   */
/*   Stored procedure:     sp_cambio_estado_op_ext                      */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Credito y Cartera                            */
/*   Disenado por:         Fabian de la Torre                           */
/*   Fecha de escritura:   12/09/1996                                   */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Maneja los cambios de estado de las operaciones: invocado desde FE */
/************************************************************************/
/*                              CAMBIOS                                 */
/*      FECHA          AUTOR            CAMBIO                          */
/*      DIC-07-2016    Raul Altamirano  Emision Inicial - Version MX    */
/*  DIC/21/2020   P. Narvaez Añadir cambio de estado Judicial y Suspenso*/
/*  DIC/29/2021   G.Fernandez Se modifica la fecha de proceso que se    */
/*                            envia al cambio de estado                 */
/*  21-Ago-2024   K. Rodríguez R240260 Ajustes para cambio estado anulad*/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_cambio_estado_op_ext')
   drop proc sp_cambio_estado_op_ext
go

create proc sp_cambio_estado_op_ext
(  @s_user        varchar(14),
   @s_term        varchar(30),
   @s_date        datetime,
   @s_ofi         smallint,
   @s_ssn         int      = null,
   @s_sesn        int    = null,
   @s_srv         varchar(30) = null,
   @s_lsrv        varchar(30) = null,
   @s_rol         smallint = null,
   @s_org         char(1) = null,
   @i_banco       cuenta,
   --@i_estado_fin  descripcion --solo para tipo de cambio manual
   @i_estado_fin  INT --LPO CDIG Cambio por APIs
)

as declare 
   @w_sp_name           descripcion,
   @w_error             int,
   @w_operacionca       int,
   @w_banco             cuenta,
   @w_estado_ini        int,
   @w_estado_fin        int,
   @w_est_anulado       int,
   @w_tipo_cambio       char(1),
   @w_tramite           int,
   @w_tipo_tramite      char(1),
   @w_msg               varchar(100),
   @w_op_fecha_ult_proceso datetime,
   @w_grupal            char(1),
   @w_ref_grupal        cuenta      

--CARGAR VARIABLES DE TRABAJO
select @w_sp_name        = 'sp_cambio_estado_op_ext',
       @w_tipo_cambio    = 'M'

	   
exec @w_error  = sp_estados_cca
@o_est_anulado = @w_est_anulado out	   


select @w_banco                = op_banco,
       @w_operacionca          = op_operacion,
       @w_estado_ini           = op_estado,
	   @w_tramite              = isnull(op_tramite, 0),
	   @w_op_fecha_ult_proceso = op_fecha_ult_proceso, --GFP 29/12/2021
	   @w_grupal               = op_grupal,
	   @w_ref_grupal           = op_ref_grupal
from   ca_operacion
where  op_banco = @i_banco


begin tran

--LPO CDIG Cambio por APIs INICIO
/*
select @w_estado_fin = es_codigo
from   ca_estado
where  es_descripcion = @i_estado_fin
*/
--LPO CDIG Cambio por APIs FIN


exec @w_error = sp_cambio_estado_op
	@s_user          = @s_user,
	@s_term          = @s_term,
	@s_date          = @s_date,
	@s_ofi           = @s_ofi,
	@i_banco         = @i_banco,
	@i_fecha_proceso = @w_op_fecha_ult_proceso, --GFP 29/12/2021
	@i_estado_ini    = @w_estado_ini,
	@i_estado_fin    = @i_estado_fin, --@w_estado_fin, --LPO CDIG Cambio por APIs
	@i_tipo_cambio   = @w_tipo_cambio,
	@i_front_end     = 'S',
	@i_en_linea      = 'S',
   @o_msg           = @w_msg out

if @w_error != 0
begin
  select @w_error = @w_error
  goto ERROR
end


select @w_estado_fin = op_estado
from   ca_operacion
where  op_operacion = @w_operacionca

if @@rowcount = 0
begin
   select @w_error = 701025
   goto ERROR
end


if @w_estado_fin = @w_est_anulado 
begin 
   if @w_tramite <> 0
   begin
      select @w_tipo_tramite = tr_tipo
      from   cob_credito..cr_tramite
      where  tr_tramite = @w_tramite
      
      exec @w_error = cob_credito..sp_rechazo
           @s_ofi           = @s_ofi,
           @s_ssn           = @s_ssn,
           @s_user          = @s_user,
           @s_term          = @s_term,
           @s_date          = @s_date,
           @i_tramite       = @w_tramite,
           @i_tipo_tramite  = @w_tipo_tramite,
           @i_producto      = 'CCA',
           @i_tipo_causal   = 'X',
		   @i_observaciones = 'Desde cambio estado anulado Cartera'
       
      if @w_error != 0
      begin
         select @w_error = @w_error
         goto ERROR
      end

       
      if exists (select 1 from cob_credito..cr_op_renovar
                 where or_tramite = @w_tramite)
      begin
         update cob_credito..cr_op_renovar
         set   or_finalizo_renovacion = 'Z'
         where or_tramite = @w_tramite
		 
         if @@error != 0
         begin
           select @w_error = 705075 -- Error al actualizar el estado de la operacion de renovacion
           goto ERROR
         end		 
		 
      end
	  
	  if @w_grupal = 'S' and @w_ref_grupal is null -- Marcar trámites Hijos
	  begin
	  
         update cob_credito..cr_tramite 
         set tr_estado = 'X',
		     tr_fecha_apr = @s_date
         from ca_operacion
	     where op_tramite = tr_tramite 
	     and op_ref_grupal = @w_banco
		  
         if @@error != 0
         begin
           select @w_error = 705075 -- Error al actualizar el estado de la operacion de renovacion
           goto ERROR
         end 
		  
         update cob_credito..cr_op_renovar 
         set or_finalizo_renovacion = 'Z'
         from ca_operacion
	     where op_tramite = or_tramite 
	     and op_ref_grupal = @w_banco
		  
         if @@error != 0
         begin
           select @w_error = 705075 -- Error al actualizar el estado de la operacion de renovacion
           goto ERROR
         end
		  
	  end
	  
   end
end


commit tran

return 0

ERROR:
   rollback tran
   exec cobis..sp_cerror
        @t_debug  = 'N',
        @t_file   = null,
        @t_from   = @w_sp_name,
        @i_num    = @w_error,
        @i_msg    = @w_msg
   
   return @w_error

go
