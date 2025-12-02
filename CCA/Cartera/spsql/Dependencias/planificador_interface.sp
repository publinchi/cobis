/************************************************************************/
/*      Archivo:                planificador_interface.sp               */
/*      Stored procedure:       sp_planificador_interfase               */
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
if exists (select 1 from sysobjects where name = 'sp_planificador_interfase')
   drop proc sp_planificador_interfase 
go

create proc sp_planificador_interfase(
    @i_pp_cuenta_sidac        int,
    @i_pp_cuenta_sidac_aux    int,
    @o_saldo_cxp_a            money out,
    @o_saldo_cxp_aux          money out
)
as
declare @w_error int, 
		@w_sp_name varchar(100),
		@w_msg     varchar(256)
        
select @w_sp_name      =  'sp_planificador_interfase'

if exists(select 1 from cobis..cl_producto where pd_producto = 100)
begin
    select @o_saldo_cxp_a  = sum(isnull(rp_saldo,0))
    from cob_sidac..sid_registros_padre 
    where rp_consecutivo  =  @i_pp_cuenta_sidac
    and rp_submodulo = 'CP'                
    
    select @o_saldo_cxp_aux  = sum(isnull(rp_saldo,0))
    from cob_sidac..sid_registros_padre 
    where rp_consecutivo  =  @i_pp_cuenta_sidac_aux
    and rp_submodulo = 'CP'         
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


