/************************************************************************/
/*	Archivo:		cavalida.sp				*/
/*	Stored procedure:	sp_valida_inf_conv_avalistas	        */
/*	Base de datos:		cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Elcira Pelaez Burbanco			*/
/*	Fecha de escritura:	feb 2002 				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	"MACOSA"							*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/************************************************************************/  
/*				PROPOSITO				*/
/*	Ejecutar el sp que valida la informacion antes de la crecion    */
/*      masica de tramites de convenios					*/
/************************************************************************/  
/*				MODIFICACIONES				*/
/*	FECHA		AUTOR	    	RAZON				*/
/*									*/
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_valida_inf_conv_avalistas')
	drop proc sp_valida_inf_conv_avalistas
go

create proc sp_valida_inf_conv_avalistas 
        @s_user           login,
        @i_fecha_proceso  datetime


as


declare @w_sp_name    		      varchar(64),
	@w_nombre_compselecto            varchar(64),
        @w_error                      int,
        @w_return                     int,
        @w_empresa                    numero,
        @w_subtipo                    char(1),
        @w_oficina_cliente            smallint,
        @w_identificacion             numero,
        @w_tipo_identificacion        numero,
        @w_linea_credito              catalogo,
        @w_oficina_oper               smallint,
        @w_oficial                    smallint,
        @w_banco                      cuenta,
	@w_cupo_linea                 cuenta,
        @w_valor_relacion             smallint,
	@w_operacionca                int,
        @w_descripcion                varchar(255),
        @w_sec_avalista               int,
        @w_tipo_cupo                  char(1),
        @w_tipo_cedula_ava            char(2),
        @w_cliente                    int,
        @w_registros                  int,
        @w_sector_cli                 char(1),
	@w_sector_ger                 char(1),
	@w_rowcount                   int
        

select @w_sp_name   = 'sp_valida_inf_conv_avalistas',
       @w_registros = 0

declare cursor_convenios cursor for
select
con_empresa,            con_subtipo,          con_oficina_cliente,   con_identificacion,
con_tipo_identificacion,con_linea_credito,    con_oficina_oper,      con_oficial,
con_cupo_linea
from ca_convenios_tmp
where con_error_tramite = 0
order by con_error_tramite
for read only

open  cursor_convenios

fetch cursor_convenios into
@w_empresa,            @w_subtipo,            @w_oficina_cliente,   @w_identificacion,
@w_tipo_identificacion,@w_linea_credito,      @w_oficina_oper,      @w_oficial,
@w_cupo_linea

while @@fetch_status =0 begin

   if @@fetch_status = -1 begin
       select @w_error = 710219
       goto  ERROR
   end  

  /***** INICIO VALIDACION ***/


 select @w_registros = @w_registros + 1


 ---Validacion Existencia del cliente

 select 1 from cobis..cl_ente
 where en_ced_ruc = @w_identificacion
 and en_tipo_ced  = @w_tipo_identificacion
 select @w_rowcount = @@rowcount
 set transaction isolation level read uncommitted

 if @w_rowcount = 0 begin
     select @w_descripcion = 'CLIENTE PARA CONVENIO NO EXISTE'
     select @w_error = 710104
     goto ERROR
  end 
  


  ---Validaciones_cupo

  select @w_cliente = en_ente
  from cobis..cl_ente
  where en_ced_ruc =  @w_empresa
  set transaction isolation level read uncommitted

  select 
  @w_tipo_cupo  = li_tipo
  from cob_credito..cr_linea
  where li_num_banco =  @w_cupo_linea
  and li_cliente = @w_cliente
  and li_estado <> 'A'

  if @w_tipo_cupo <> 'C' begin
     select @w_descripcion = 'NO EXISTE CUPO DE CONVENIO'
     select @w_error = 701074
     goto ERROR
  end 


  --- Validaciones_linea

  select 1   from cob_cartera..ca_default_toperacion
  where dt_toperacion  = @w_linea_credito
  and   dt_tipo        = 'V'
   if @@rowcount = 0 begin
      select  @w_descripcion = 'Error En Linea de Credito Enviada'
      select  @w_error = 701016
      goto ERROR
  end


  /***************************/


   goto SIGUIENTE

   ERROR:  

   update ca_convenios_tmp
   set con_error_tramite  = @w_error
   where con_identificacion = @w_identificacion
  

   exec sp_errorlog                                             
   @i_fecha       = @i_fecha_proceso,
   @i_error       = @w_error,
   @i_usuario     = @s_user,
   @i_tran        = 7000, 
   @i_tran_name   = @w_sp_name,
   @i_rollback    = 'N',  
   @i_cuenta      = @w_identificacion, 
   @i_descripcion = @w_descripcion

   goto SIGUIENTE

  SIGUIENTE: 

  fetch cursor_convenios into
  @w_empresa,            @w_subtipo,            @w_oficina_cliente,   @w_identificacion,
  @w_tipo_identificacion,@w_linea_credito,      @w_oficina_oper,      @w_oficial,
  @w_cupo_linea

end /*Cursor convenios*/


close cursor_convenios
deallocate cursor_convenios


PRINT '(cavalida.sp) fin proceso  Registros leidos '+ cast(@w_registros as varchar)


return 0

go

