/************************************************************************/
/*      Archivo:                num_pagare.sp                    		*/
/*      Stored procedure:       sp_num_pagare                           */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Jonnatan Peña                           */
/*      Fecha de escritura:     Abr. 2009                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "COBISCORP".                                                    */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de COBISCORP o su representante.          */
/************************************************************************/  
/*                              PROPOSITO                               */
/*     La presente consulta con opción de impresión en formato Crystal  */
/*     Report, genera los próximos vencimientos según un rango de       */
/*     fechas seleccionado                                              */
/************************************************************************/
/*                            MODIFICACIONES                            */
/*     JSA  22/11/2016        Migracion Cobis Cloud                     */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_num_pagare ')
   drop proc sp_num_pagare 
go

create proc sp_num_pagare  (  
   @i_banco    varchar(24) = null,
   @i_web      char(1)     = 'N'
)
as

declare 
   @w_sp_name         varchar(32),
   @w_return          int,
   @w_error           int, 
   @w_msg             varchar(100), 
   @w_oficina		  smallint,
   @w_cedula		  varchar(20),
   @w_fecha_liq       datetime,
   @w_fi_nombre       descripcion,
   @w_nombre_banco    descripcion


select 
@w_oficina = op_oficina, 
@w_cedula  = en_ced_ruc,
@w_fecha_liq = fp_fecha
from cobis..cl_ente, ca_operacion, cobis..ba_fecha_proceso
where en_ente = op_cliente
and op_banco = @i_banco

if @@rowcount = 0 
begin
	select @w_error = 710022
    goto ERROR
end    

if @i_web = 'S'
begin
   select @w_fi_nombre = fi_nombre
     from cobis..cl_filial
    where fi_filial = 1
   
   select @w_nombre_banco = pa_char
     from cobis..cl_parametro
    where pa_producto = 'CRE'
      and pa_nemonico = 'BANCO'
   
   if @@rowcount = 0
   begin
       select @w_error = 101085
       goto ERROR
   end
end

if @i_web = 'N'
   select cast (@w_oficina as varchar(10)) + ' - ' + cast (@w_cedula as varchar(20)), --@i_banco , 
          convert(varchar(10), @w_fecha_liq, 103)
else
   select cast (@w_oficina as varchar(10)) + ' - ' + cast (@w_cedula as varchar(20)),
          convert(varchar(10), @w_fecha_liq, 103),
          @w_nombre_banco,
          @w_fi_nombre
            		 		 
return 0  

ERROR:

exec cobis..sp_cerror
@t_debug = 'N',
@t_file  = null, 
@t_from  = @w_sp_name,
@i_num   = @w_error,
@i_msg   = @w_msg

return @w_error   
go

