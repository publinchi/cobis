/************************************************************************/
/*      Archivo:                redescue.sp                             */
/*      Stored procedure:       sp_redescuento                          */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Fabian de la Torre, Rodrigo Garces      */
/*      Fecha de escritura:     Ene. 1998                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA".		                                        */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Maneja las operaciones de redescuento y sus operaciones asocia_ */
/*      das                                                             */
/************************************************************************/  

use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_redescuento')
	drop proc sp_redescuento
go
create proc sp_redescuento
   @s_user           login = null,
   @s_term           varchar(30)  = null,
   @s_date           datetime     = null,
   @s_sesn           int          = null,
   @s_ofi             smallint     = null,
   @i_operacion 	   char(1),
   @i_pasiva               cuenta      = null,
   @i_activa               cuenta      = null,
   @i_moneda               tinyint     = null,
   @i_tipo_op              char(1)     = null,
   @i_hereda               char(1)     = 'N',
   @i_porcentaje_act       money       = 0,
   @i_porcentaje_pas       money       = 0,
   @i_credito              char(1)     = 'N'
	  
as

declare 
   @w_sp_name           descripcion,
   @w_return            int,
   @w_error             int,
   @w_activa            int,
   @w_pasiva            int,
   @w_toperacion_act    descripcion, 
   @w_toperacion_pas    descripcion,
   @w_saldo_act         money,
   @w_saldo_pas         money,
   @w_vrelacion         money,
   @w_sum_prtje         money,
   @w_total_prtje       money,
   @w_paso              int,
   @w_fecha_1           datetime

/* CARGAR VALORES INICIALES */

select @w_sp_name = 'sp_redescuento'



begin tran

   exec @w_return = sp_redescuento_int
   @s_user           = @s_user,   
   @s_term           = @s_term,   
   @s_date           = @s_date,   
   @s_sesn           = @s_sesn,   
   @s_ofi            = @s_ofi ,   
   @i_operacion	      = @i_operacion,
   @i_pasiva          = @i_pasiva ,
   @i_activa          = @i_activa,
   @i_moneda          = @i_moneda,
   @i_tipo_op         = @i_tipo_op,
   @i_hereda          = @i_hereda,
   @i_porcentaje_act  = @i_porcentaje_act,
   @i_porcentaje_pas  = @i_porcentaje_pas,
   @i_credito         = @i_credito

   if @w_return <> 0 begin
      select @w_error = @w_return
      goto ERROR
   end

commit tran

return 0

ERROR:

rollback tran

return @w_error

go

