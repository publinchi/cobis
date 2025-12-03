/************************************************************************/
/*	Archivo: 		ac_estad.sp				*/
/*	Stored procedure: 	sp_actualiza_estado			*/
/*	Base de datos:  	cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Catalina Espinel			*/
/*				Yomar Pazmino				*/
/*	Fecha de escritura: 	Abril 1996				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	'MACOSA'.							*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/************************************************************************/  
/*				PROPOSITO				*/
/*	Este programa realiza el mantenimiento de los tipos de estados.	*/
/*									*/
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_actualiza_estado')
    drop proc sp_actualiza_estado
go
create proc sp_actualiza_estado(
   @s_user           login = null,
   @s_term           varchar(30)  = null,
   @s_date           datetime     = null,
   @s_sesn           int          = null,
   @s_ofi             smallint     = null,
   @i_operacion          char(1),
   @i_concepto		 descripcion,
   @i_procesa		 char(1) = null,
   @i_acepta_pago	 char(1) = null,
   @i_toperacion         catalogo = null           
)

as declare
   @w_return             int,
   @w_estado             tinyint,
   @w_sp_name            varchar(32),
   @w_error              int,
   @w_tipo_op            char(1)

select @w_sp_name = 'sp_actualiza_estado'


select @w_estado=es_codigo
from ca_estado
where es_descripcion=@i_concepto

if @i_operacion in ('U','D') 
begin
   
   insert into ca_estado_ts
   select @s_date, getdate(), @s_user, @s_ofi, @s_term,@i_operacion, *
   from   ca_estado
   where es_codigo = @w_estado
   
   if @@error != 0 begin
      select @w_error = 705036
      goto ERROR
   end
  
end


if @i_operacion = 'U' begin
   update ca_estado set  
   es_procesa = @i_procesa,
   es_acepta_pago = @i_acepta_pago
   where es_codigo = @w_estado
                 
   if @@error <> 0  begin 
      select @w_error = 710002 
      goto ERROR 
   end
end

if @i_operacion = 'I' begin

   if exists (select * 
              from   ca_estado 
              where  es_descripcion = @i_concepto)   begin 
      select @w_error = 710078
      goto ERROR 
   end
   

   select @w_estado = max(es_codigo)+1
   from   ca_estado
    
   if @w_estado < 11 select @w_estado = 11

   insert into ca_estado (es_codigo,es_descripcion,es_procesa,es_acepta_pago)
   values (@w_estado,@i_concepto,@i_procesa,@i_acepta_pago)

   if @@error <> 0 begin 
      select @w_error = 710001 
      goto ERROR 
   end
end 

if @i_operacion = 'D' begin

   if @w_estado < 11 begin
      select @w_error = 710077
      goto ERROR
   end

   delete ca_estado 
   where es_codigo = @w_estado

   if @@error <> 0 begin
      select @w_error = 710001
      goto ERROR
   end
end 



if @i_operacion = 'A' begin


select @w_tipo_op = dt_tipo
from ca_default_toperacion
where dt_toperacion = @i_toperacion

select @w_tipo_op
end 



return 0

ERROR:
      exec cobis..sp_cerror
      @t_debug = 'N',
      @t_file  = null, 
      @t_from  = @w_sp_name,
      @i_num   = @w_error
      return 1 

go
