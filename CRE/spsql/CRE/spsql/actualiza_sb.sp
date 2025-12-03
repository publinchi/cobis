/************************************************************************/
/*  Archivo:                actualiza_sb.sp                             */
/*  Stored procedure:       sp_actualiza_sb                             */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jose Ortiz                                  */
/*  Fecha de Documentacion: 23/Abr/2019                                 */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP S.A.representantes exclusivos para el Ecuador de la       */
/*  AT&T                                                                */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante               */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  SP GENERADO POR EXTRACCION DE LA BB.DD. cob_credito                 */
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  23/04/19          Jose Ortiz       Emision Inicial                  */
/* **********************************************************************/
use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_actualiza_sb' and type = 'P')
   drop proc sp_actualiza_sb
go



create proc sp_actualiza_sb (
   @i_param1    varchar(255),
   @i_param2    varchar(255)
)

as 

declare
@w_sp_name              descripcion,
@w_mensaje              varchar(250),
@w_error                int,
@w_tipo_reg             char(1),
@i_fecha                datetime,
@i_fin_mes              char(1),
@w_fecha                datetime,
@w_usuario              login

select 
@w_sp_name   = 'sp_actualiza_sb', 
@w_error     = 21003,
@w_usuario   = 'crebatch',
@i_fecha     = convert(datetime, @i_param1),
@i_fin_mes   = convert(char(1), @i_param2)


if @i_fin_mes = 'S'  begin

   /* ACTUALIZACION TEMPORALIDAD EN DATO_OPERACION */
   update cob_credito..cr_dato_operacion set
   do_edad_mora    = ct_codigo 
   from   cob_credito..cr_param_cont_temp
   where  ct_clase             =  do_clase_cartera 
   and    do_dias_vto_div/30.0 >  ct_desde
   and    do_dias_vto_div/30.0 <= ct_hasta
   and    do_tipo_reg          = 'M'
   
   if @@error <> 0 begin
      select @w_mensaje = 'Error Actualizando edad_mora (1)  '
      goto ERRORFIN      
   end

   update cob_credito..cr_dato_operacion set
   do_edad_mora    = ct_codigo
   from   cob_credito..cr_param_cont_temp
   where  ct_clase             =  do_clase_cartera
   and    do_dias_vto_div/30.0 >= ct_desde
   and    do_dias_vto_div/30.0 <= ct_hasta
   and    do_dias_vto_div      =  0
   and    do_tipo_reg          = 'M'

   if @@error <> 0 begin
      select @w_mensaje = 'Error Actualizando edad_mora (2)  '
      goto ERRORFIN      
   end

end 


return 0


ERRORFIN:

while @@trancount > 0 rollback tran

select @w_mensaje = @w_sp_name + ' --> ' + @w_mensaje
    
insert into cr_errorlog
values (@i_fecha, @w_error, @w_usuario, 21000, 'CONSOLIDADOR', @w_mensaje)

return 1


GO
