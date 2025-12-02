/*************************************************************************/
/*  Archivo           : revpagcam.sp                                     */
/*  Stored procedure  : sp_reversa_pagos_camara                          */
/*  Base de datos     : cob_cartera                                      */
/*  Producto          : Cartera                                          */
/*  Disenado por      : Xmaldonado                                       */
/*  Fecha de escritura: Enero. 2010.                                     */
/*************************************************************************/
/*              IMPORTANTE                                               */
/*  Este programa es parte de los paquetes bancarios propiedad de        */
/*  "MACOSA".                                                            */
/*  Su uso no autorizado queda expresamente prohibido asi como           */
/*  cualquier alteracion o agregado hecho por alguno de sus              */
/*  usuarios sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de MACOSA o su representante.                  */
/*              PROPOSITO                                                */
/*  Procedimiento que realiza el reverso pagos desde camara              */
/*  Este procedimiento se va ha ejecutar desde nchqdev_file.sp           */
/*************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_reversa_pagos_camara')
   drop proc sp_reversa_pagos_camara
go 

create proc sp_reversa_pagos_camara(
@s_user             login,
@s_term             varchar(30),
@s_date             datetime,
@s_ofi              smallint,
@i_banco            cuenta,
@i_ssn_branch       int,
@o_mensaje          mensaje out
)   
as

declare 
@w_error            int,
@w_secuencial_abn   int,
@w_mensaje          mensaje,
@w_secuencial_pag   int,
@w_secuencial_ing   int,
@w_estado_pag       catalogo


select @w_secuencial_abn = 0

select @w_secuencial_abn = isnull(sa_secuencial_cca , 0)
from  cob_cartera..ca_secuencial_atx
where sa_ssn_corr        = @i_ssn_branch
and   sa_operacion       = @i_banco

if @w_secuencial_abn = 0 begin
   select @o_mensaje = 'NO ENCONTRO EL SECUENCIAL DEL PAGO POR CAJA EN CARTERA '
   return 190031
end   

select 
@w_secuencial_pag = ab_secuencial_pag,
@w_secuencial_ing = ab_secuencial_ing,
@w_estado_pag     = ab_estado
from ca_operacion, ca_abono
where op_operacion      = ab_operacion
and   ab_secuencial_ing = @w_secuencial_abn
and   op_banco          = @i_banco

if @@rowcount = 0 begin
   select @o_mensaje = 'NO ENCONTRO EL PAGO EN LA TABLA DE ABONOS DE CARTERA (ca_abono) '
   return 190031
end

if @w_estado_pag not in ('A','NA') begin
   select @o_mensaje = 'ERROR, EL PAGO ESTA REVERSADO O SOLAMENTE INGRESADO '
   return 190031
end


if @w_estado_pag = 'A' begin

   exec @w_error  = cob_cartera..sp_fecha_valor
   @s_user        = @s_user,
   @s_term        = @s_term,
   @t_trn         = 7049,     
   @i_banco       = @i_banco,
   @i_secuencial  = @w_secuencial_pag,
   @i_operacion   = 'R',
   @i_en_linea    = 'N',
   @i_observacion = 'REVERSO DESDE CAMARA'
   
   if @w_error <> 0  begin
      
	  select @o_mensaje = mensaje
	  from   cobis..cl_errores
	  where  numero = @w_error
	  
	  if @o_mensaje Is not Null
	     select @o_mensaje = @o_mensaje + ' (sp_fecha_valor)'
      else
	     select @o_mensaje = 'ERROR, AL REVERSAR EL PAGO (sp_fecha_valor) Error:' + convert(varchar,@w_error)
      
	  return @w_error   
   end
   
end else begin
   exec @w_error     = cob_cartera..sp_eliminar_pagos
   @t_trn            = 7036,
   @i_banco          = @i_banco,
   @i_operacion      = 'D',
   @i_secuencial_ing = @w_secuencial_ing,
   @i_en_linea       = 'S'
   
   if @w_error <> 0  begin
      
	  select @o_mensaje = mensaje
	  from   cobis..cl_errores
	  where  numero = @w_error
	  
	  if @o_mensaje Is not Null
	     select @o_mensaje = @o_mensaje + ' (sp_eliminar_pagos)'
	  else  
	     select @o_mensaje = 'ERROR, AL ELIMINAR EL PAGO (sp_eliminar_pagos) Error:' + convert(varchar,@w_error)
		 
	  return @w_error   
   end

end

update cob_cartera..ca_secuencial_atx
set    sa_estado = 'E'
where  sa_operacion      = @i_banco
and    sa_ssn_corr       = @i_ssn_branch

if @@error <> 0 begin
   select @o_mensaje = 'ERROR AL ACTUALIZAR ESTADO EN LA TABLA ca_secuencial_atx'
   return 710002
End

return 0
go

