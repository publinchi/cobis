/******************************************************************/
/*  Archivo:            calcula_sin_impuesto.sp                   */
/*  Stored procedure:   sp_calcula_sin_impuesto                   */
/*  Base de datos:      cob_interface                             */
/*  Producto:           Credito                                   */
/*  Disenado por:                                                 */
/*  Fecha de escritura: 18-Oct-2016                               */
/******************************************************************/
/*                        IMPORTANTE                              */
/*  Este programa es parte de los paquetes bancarios propiedad de */
/*  'MACOSA', representantes exclusivos para el Ecuador de la     */
/*  'NCR CORPORATION'.                                            */
/*  Su uso no autorizado queda expresamente prohibido asi como    */
/*  cualquier alteracion o agregado hecho por alguno de sus       */
/*  usuarios sin el debido consentimiento por escrito de la       */
/*  Presidencia Ejecutiva de MACOSA o su representante.           */
/******************************************************************/
/*                          PROPOSITO                             */
/******************************************************************/
/*                        MODIFICACIONES                          */
/*  FECHA              AUTOR            RAZON                     */
/*  18-Oct-2016       Nolberto Vite    Sp dummy como dependencia  */
/*  18-Ene-2017       Jorge Baque      Implementacion Logica      */
/******************************************************************/
use cob_interface
go
if exists (select 1 from sysobjects where name = 'sp_calcula_sin_impuesto')
   drop proc sp_calcula_sin_impuesto
go

create proc sp_calcula_sin_impuesto
(
    @s_user             login       = NULL, 
    @s_ofi              smallint, 
	@i_pit         		char(1),                   
	@i_cta_banco   		cuenta,             
	@i_tipo_cta    		tinyint,             
	@i_fecha       		datetime,               
	@i_causa       		varchar(20),              
	@i_is_batch    		char(1),
	@o_valor       		money out
)
as
declare @w_error int, 
@w_sp_name varchar(100),
		@w_msg     varchar(256)
        
select @w_sp_name      =  'sp_calcula_sin_impuesto'

/*
if exists(select 1 from cobis..cl_producto where pd_producto = @i_tipo_cta)
begin

    exec @w_error = cob_cuentas..sp_calcula_sin_impuesto
    @s_ofi         = @s_ofi,                  ---OFICINA QUE EJECUTA LA CONSULTA
    @i_pit         = @i_pit,                     ---INDICADOR PARA NO REALIZAR ROLLBACK
    @i_cta_banco   = @i_cta_banco,               ---NUMERO DE CUENTA
    @i_tipo_cta    = @i_tipo_cta,             ---PRODUCTO DE LA CUENTA
    @i_fecha       = @i_fecha,                 ---FECHA DE LA CONSULTA
    @i_causa       = @i_causa,                ---CAUSA DE DEBITO (para verificar si cobra IVA)
    @i_is_batch    = @i_is_batch,
    @o_valor       = @o_valor out  ---VALOR PARA REALIZAR LA ND
    if @w_error <> 0
    begin
       GOTO ERROR
    end
  
end
else
begin
	select @w_error = 404000, @w_msg = 'PRODUCTO NO INSTALADO'
    GOTO ERROR
end
*/
return 0
ERROR:
exec cobis..sp_cerror
@t_debug  = 'N',          
@t_file = null,
@t_from   = @w_sp_name,   
@i_num = @w_error,
@i_msg = @w_msg
return @w_error
go
