/************************************************************************/
/*	Archivo:		hmejecu.sp				*/
/*	Stored procedure:	sp_ejecutar_batch                       */
/*	Base de datos:		cob_cartera				*/
/*	Producto: 		Cartera          			*/
/*	Disenado por:  		Patricio Narvaez			*/
/*	Fecha de escritura:	2 de Abr. 1998 				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	"MACOSA".	                                                */
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/************************************************************************/  
/*				PROPOSITO				*/
/*   Procedimiento que ejecuta el batch para una operacion especifica   */
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_ejecutar_batch')
	drop proc sp_ejecutar_batch
go


create proc sp_ejecutar_batch
	@i_banco		cuenta,
        @i_dias                 int      = null,
        @i_fecha                datetime = null,
	@i_formato_fecha        int = 101
as


declare
@w_fecha_proceso datetime,
@w_banco varchar(30),
@w_nro_dias int,
@w_fecha_ult_proc datetime,
@w_fecha_proc datetime


PRINT '------->  Opcion deshabilidata'
return 0

select @w_banco         = @i_banco
select @w_nro_dias      = @i_dias 
select @w_fecha_proceso = @i_fecha

if not exists ( select 1 from ca_operacion
                where op_banco = @i_banco
                and   op_estado <> 0)
               PRINT 'NO EXISTE UNA OPERACION PARA EL NUMERO BANCO INGRESADO  O  LA OPERACION NO HA SIDO LIQUIDADA'  

if @w_nro_dias is not null begin

   while @w_nro_dias > 0 begin
   
      select @w_fecha_proceso = op_fecha_ult_proceso 
      from ca_operacion
      where op_banco = @w_banco

      exec sp_batch
      @s_user          =  'crebatch',
      @s_term          =  'BATCH_CARTERA',
      @s_date          =   @w_fecha_proceso,
      @s_ofi           =   1,
      @i_en_linea      =  'S', ---EPB_feb-21-2002 cambio de N por S
      @i_banco         =   @w_banco,
      @i_siguiente_dia =   @w_fecha_proceso, 
      @i_debug         =  'N' --activar mensajes de debug

      select @w_nro_dias = @w_nro_dias -1

   end
end
else if @w_fecha_proceso is not null begin

   exec sp_batch
   @s_user          =  'crebatch',
   @s_term          =  'BATCH_CARTERA',
   @s_date          =   @w_fecha_proceso,
   @s_ofi           =   1,
   @i_en_linea      =  'S', ---EPB_feb-21-2002 cambio de N por S
   @i_banco         =   @w_banco,
   @i_siguiente_dia =   @w_fecha_proceso,
   @i_debug         =  'N' --activar mensajes de debug

end

select @w_fecha_ult_proc = op_fecha_ult_proceso
from ca_operacion
where op_banco = @i_banco

select  convert(varchar(10),@w_fecha_ult_proc,@i_formato_fecha)

return 0

go
   
