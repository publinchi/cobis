/************************************************************************/
/*  archivo:                lcr_desembolsar.sp                          */
/*  stored procedure:       sp_lcr_desembolsar                          */
/*  base de datos:          cob_cartera                                 */
/*  producto:               credito                                     */
/*  disenado por:           Andy Gonzalez                               */
/*  fecha de documentacion: Noviembre 2018                              */
/************************************************************************/
/*          importante                                                  */
/*  este programa es parte de los paquetes bancarios propiedad de       */
/*  "macosa",representantes exclusivos para el ecuador de la            */
/*  at&t                                                                */
/*  su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  presidencia ejecutiva de macosa o su representante                  */
/************************************************************************/
/*          proposito                                                   */
/*             Desembolso de la LCR                                     */
/************************************************************************/
/*                             MODIFICACION                             */
/*    FECHA                 AUTOR                 RAZON                 */
/*    14/Nov/2018           AGO              Emision Inicial            */
/************************************************************************/

use cob_cartera 
go

if exists(select 1 from sysobjects where name ='sp_lcr_desembolsar_batch')
	drop proc sp_lcr_desembolsar_batch
go



create proc sp_lcr_desembolsar_batch(

    @i_param1           cuenta        ,  --Banco 
   @i_param2           money,            --monto a desembolsar
   @i_fecha_valor      datetime = null
)as 
declare
@s_ssn               int,
@s_user              login,
@s_date              datetime ,
@s_srv               descripcion,
@s_term              descripcion,
@s_rol               int,
@s_lsrv              descripcion ,
@s_ofi               int,
@s_sesn              int,
@w_sp_name           varchar(500) ,
@w_msg               descripcion,
@w_error             int   


--INICIALIZACION DE VARIABLES
select  @s_ssn  = convert(int,rand()*10000)

select 
@s_user             ='usrbatch',
@s_srv              ='CTSSRV',
@s_term             ='batch-utilizacion',
@s_rol              =3,
@s_lsrv             ='CTSSRV',
@w_sp_name          = 'sp_lcr_desembolsar_batch',
@s_sesn             = @s_ssn,
@s_date             = fp_fecha 
from cobis..ba_fecha_proceso 




select @s_ofi     = op_oficina 
from ca_operacion 
where op_banco = @i_param1

if @@rowcount =0 begin 
   select @w_msg = 'ERROR NO EXISTE LA OPERACION ' 
   goto ERROR_FIN
end


exec @w_error= sp_lcr_desembolsar 
@s_ssn              = @s_ssn,
@s_ofi              = @s_ofi,
@s_user             = @s_user,
@s_sesn             = @s_ssn,
@s_term             = @s_term,
@s_srv              = @s_srv,
@s_date             = @s_date,
@i_banco            = @i_param1,
@i_monto            = @i_param2,
@i_fecha_valor      = @i_fecha_valor
  
if @w_error <> 0 begin 
    select 
	@w_msg   = 'ERROR EN LA EJECUCION DEL SP DE UTILIZACION' ,
	@w_error =  @w_error 
	   
   goto ERROR_FIN

end 


return 0
ERROR_FIN:

exec sp_errorlog 
@i_fecha     = @s_date,
@i_error     = @w_error,
@i_usuario   = 'sp_lcr_desembolsar_batch',
@i_tran      = 7999,
@i_tran_name = @w_sp_name,
@i_cuenta    = @i_param1,
@i_rollback  = 'N',
@i_descripcion = @w_msg  

return @w_error
go