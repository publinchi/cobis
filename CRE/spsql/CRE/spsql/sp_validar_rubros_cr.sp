/**************************************************************************/
/*  Archivo:                    sp_validar_rubros_cr.sp             	  */
/*  Stored procedure:           sp_validar_rubros_cr                 	  */
/*  Base de Datos:              cob_credito                               */
/*  Producto:                   Credito                                   */
/**************************************************************************/
/*                          IMPORTANTE                                    */
/*  Este programa es parte de los paquetes bancarios propiedad de         */
/*  'COBISCORP'.                                                          */
/*  Su uso no autorizado queda expresamente prohibido asi como            */
/*  cualquier autorizacion o agregado hecho por alguno de sus             */
/*  usuario sin el debido consentimiento por escrito de la                */
/*  Presidencia Ejecutiva de COBISCORP o su representante.                */
/**************************************************************************/
/*                          PROPOSITO                                     */
/*  Este stored procedure permite validar si un grupo tiene integrantes   */
/*    y si los rubros son distintos al tramite padre                      */
/**************************************************************************/
/*                        MODIFICACIONES                                  */
/*  FECHA          AUTOR                            RAZON                 */
/*  27/Jul/2021   Dilan Morales           implementacion                  */
/**************************************************************************/
use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_validar_rubros_cr')
    drop proc sp_validar_rubros_cr
go


create proc sp_validar_rubros_cr (
@s_user                    	login        	= null,
@s_term                    	varchar(30)  	= null,
@s_date                   	datetime     	= null,
@s_ofi                     	smallint		= null,    
@s_rol                     	smallint     	= null,
@t_show_version         	bit             = 0,    -- Mostrar la version del programa
@t_debug                	char(1)         = 'N',
@t_file                 	varchar(10)     = null,
@t_from                 	varchar(32)     = null,
@t_trn                  	int        		= null,
@i_operacion_padre         	int      		= null
)
as
declare
   	@w_sp_name                 	descripcion,
  	@w_count 					int, 
  	@w_operacion   				int,
  	@w_validar					int,
   	@w_error					int
   	declare 
	@rubros_hijos table(operacion int, concepto catalogo, tipo_rubro char(1), fpago char(1), referencial catalogo)
	declare
		@rubro_padre  table(operacion int, concepto catalogo, tipo_rubro char(1), fpago char(1), referencial catalogo)
	declare
		@operaciones  table(operacion int)

	select   	@w_sp_name = 'sp_validar_rubros_cr'
	select 		@w_validar = 0
	
	
	insert into @rubros_hijos (	operacion, 		concepto , 		tipo_rubro, 	fpago, 		referencial ) 
		select 					ro_operacion, 	ro_concepto, 	ro_tipo_rubro, 	ro_fpago, 	ro_referencial  
		from cob_cartera..ca_rubro_op join  cob_cartera..ca_operacion on ro_operacion = op_operacion where op_ref_grupal = @i_operacion_padre
	insert into @rubro_padre (	operacion, 		concepto , 		tipo_rubro, 	fpago, 		referencial ) 
		select 					ro_operacion, 	ro_concepto, 	ro_tipo_rubro, 	ro_fpago, 	ro_referencial  
		from cob_cartera..ca_rubro_op where ro_operacion = @i_operacion_padre 
	insert into @operaciones (operacion) select op_operacion from cob_cartera..ca_operacion where op_ref_grupal = @i_operacion_padre 
	
	select @w_count =  count(*) from @operaciones 
	
	while @w_count > 0
	begin	
		select top 1  @w_operacion = operacion from @operaciones order by operacion
		
		if exists(
			select * from 
			(select * from @rubros_hijos where operacion =@w_operacion ) as H
			full outer join @rubro_padre as P 
				on H.concepto 		= P.concepto
				where (H.concepto is null or P.concepto is null )
		)
		begin
			select @w_validar = -1
			select @w_count = 0
		end	
		
		
		delete @operaciones where operacion = @w_operacion
		select @w_count =  count(*) from @operaciones	
	end
	
	select @w_validar
   
return 0

ERROR:
    begin --Devolver mensaje de Error
        exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file,
             @t_from  = @w_sp_name,
             @i_num   = @w_error

        return @w_error
    end


return @w_error

