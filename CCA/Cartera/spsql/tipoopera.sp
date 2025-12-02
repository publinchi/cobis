/************************************************************************/
/*   Archivo:                 tipoopera.sp                              */
/*   Stored procedure:        sp_tipo_operacion                         */
/*   Base de Datos:           cob_cartera                               */
/*   Producto:                Cartera                                   */
/*   Disenado por:            Edison Cajas M.                           */
/*   Fecha de Documentacion:  Julio. 2019                               */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier autorizacion o agregado hecho por alguno de sus          */
/*   usuario sin el debido consentimiento por escrito de la             */
/*   Presidencia Ejecutiva de MACOSA o su representante                 */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Programa que indica si una operación es Grupal, Interciclo, Hija o */
/*   Individual.                                                        */
/************************************************************************/ 
/*                              MODIFICACIONES                          */ 
/*      FECHA           AUTOR           RAZON                           */
/*   09/Jul/2019   Edison Cajas. Emision Inicial                        */
/*   19/Mar/2025   Oscar Diaz    Error #262345                          */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_tipo_operacion')
    drop proc sp_tipo_operacion
go

create proc sp_tipo_operacion
( 
    @i_banco    varchar(20),
	@i_en_linea char(1)    = 'S',
	@t_show_version        bit            = 0,
	@o_tipo     char(1)     out 
)
as

declare 
    @w_sp_name   descripcion,
	@w_error     int

    select @w_sp_name = 'sp_tipo_operacion'
	select @o_tipo = ''

    if @t_show_version = 1
    begin
      print 'Stored Procedure ' + @w_sp_name + ' Version 1.0.0.1'
      return 0
    end

    --Operacion Grupal
    if exists(select 1
	  from ca_operacion,ca_ciclo
	 where op_operacion = ci_operacion
	   and op_grupal = 'S'
	   and op_ref_grupal is null
	   and op_banco = @i_banco)
	begin
	    Select @o_tipo = 'G'
	end 
	else --Error #262345
	if exists(select 1              --ODI_#262345 
	  from ca_operacion
	 where op_grupal = 'S'
	   and op_ref_grupal is null
	   and op_banco = @i_banco)
	begin
	    Select @o_tipo = 'G'
	end --FIN-Error #262345
	

    --Operacion Interciclo
    if exists(select 1
	  from ca_operacion,ca_det_ciclo
	 where op_operacion = dc_operacion
	   and op_banco = @i_banco
	   and (op_grupal = 'N' or op_grupal is null)
	   and op_ref_grupal is not null
	   and dc_tciclo = 'I')
	begin
	    Select @o_tipo = 'I'
	end
	   
    --Operacion Individual
	if exists(select 1
	  from ca_operacion
	 where op_banco = @i_banco	   
	   and (op_grupal = 'N' or op_grupal is null)
	   and op_operacion not in (select dc_operacion from ca_det_ciclo))
	begin
	    Select @o_tipo = 'N'
	end
	   
    --Operacion Hija
	if exists(select 1
	  from ca_operacion,ca_det_ciclo
	 where op_operacion = dc_operacion
	   and op_banco = @i_banco
	   and op_grupal = 'S'
	   and op_ref_grupal is not null
	   and dc_tciclo = 'N')
	begin
	    Select @o_tipo = 'H'
	end
    else
	if exists(select 1                    --ODI_#262345
	  from ca_operacion
	 where op_banco = @i_banco
	   and op_grupal = 'S'
	   and op_ref_grupal is not null)
	begin
	   Select @o_tipo = 'H'
	end
	
	
	
	
	if @o_tipo = ''
	begin
	   --print 'No existe la operacion' 
	   select @w_error = 725054
       goto ERROR
	end 	 

return 0

ERROR:
if @i_en_linea  = 'S'
begin
    exec cobis..sp_cerror
         @t_debug = 'N',
         @t_file  = null, 
         @t_from  = @w_sp_name,
         @i_num   = @w_error
    return 1 		 
end
else
    return @w_error

go