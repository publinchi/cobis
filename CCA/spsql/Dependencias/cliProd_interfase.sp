/************************************************************************/
/*      Archivo:                cliProd_interface.sp                    */
/*      Stored procedure:       sp_cliProd_interfase                    */
/*      Producto:               cob_interface                           */
/*      Disenado por:           Jorge Baque H                           */
/*      Fecha de escritura:     ENE 04 2017                             */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'COBISCORP'.                                                    */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de COBISCORP o su representante.          */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      SP interface DE DESACOPLAMIENTO                                 */
/************************************************************************/
/*   FECHA                 AUTOR                RAZON                   */
/* ENE 04/2017             JBA              DESACOPLAMIENTO             */     
/************************************************************************/
use cob_interface
go
if exists (select 1 from sysobjects where name = 'sp_cliProd_interfase')
   drop proc sp_cliProd_interfase 
go

create proc sp_cliProd_interfase
as
declare @w_error int, 
		@w_sp_name varchar(100),
		@w_msg     varchar(256)
        
select @w_sp_name      =  'sp_cliProd_interfase'

if exists(select 1 from cobis..cl_producto where pd_producto = 10)
begin
    PRINT ''
    PRINT 'update a la tabla ca_query_clientes_Plano Ahorros prod_banc '
    ---NOMBRE CATEGORIA DE AHORROS

    update cob_cartera..ca_query_clientes_Plano
    set DES_CATEGORIA = pb_descripcion
    from cob_remesas..pe_pro_bancario
    where CATEGORIA_AHO = convert(char(10),pb_pro_bancario)
end
else
begin
	select @w_error = 404000, @w_msg = 'PRODUCTO NO INSTALADO'
    GOTO ERROR
end
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

