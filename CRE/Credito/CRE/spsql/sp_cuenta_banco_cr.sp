/**************************************************************************/
/*  Archivo:                    sp_cuenta_banco_cr.sp                     */
/*  Stored procedure:           sp_cuenta_banco_cr                        */
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
/*  Este stored procedure permite obtener cuentas de la tabla			  */
/*    cob_bancos..ba_cuenta                                               */
/**************************************************************************/
/*                        MODIFICACIONES                                  */
/*  FECHA          AUTOR                            RAZON                 */
/*  27/Jul/2021   Dilan Morales           implementacion                  */
/**************************************************************************/
use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_cuenta_banco_cr')
    drop proc sp_cuenta_banco_cr
go


create proc sp_cuenta_banco_cr (
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
@i_operacion               	char(1)      	= null,
@i_banco         			smallint      	= null,
@i_moneda					smallint      	= null		
)
as
declare
   	@w_sp_name                 	descripcion,
  	@w_count 					int, 
  	@w_operacion   				int,
  	@w_validar					int,
   	@w_error					int

	select   	@w_sp_name = 'sp_cuenta_banco_cr'
	
	if @i_operacion = 'Q'
	BEGIN
	if @i_banco is null
	begin
		EXEC cobis..sp_cerror 
                @t_debug = @t_debug, 
                @t_file = @t_file, 
                @t_from = @w_sp_name, 
                @i_num = 171003
	end
	
	if @i_moneda is null
	begin
		EXEC cobis..sp_cerror 
                @t_debug = @t_debug, 
                @t_file = @t_file, 
                @t_from = @w_sp_name, 
                @i_num = 2902608 
	end
	
	select cu_cta_banco , cu_nombre 
		from cob_bancos..ba_cuenta 
		where cu_banco = @i_banco   and cu_estado = 'A' and cu_moneda = @i_moneda
	END
	
   
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

