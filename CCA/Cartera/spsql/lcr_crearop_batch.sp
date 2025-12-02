/************************************************************************/
/*  archivo:                sp_lcr_crearop_batch                          */
/*  stored procedure:       sp_lcr_crearop_batch                          */
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

if exists(select 1 from sysobjects where name ='sp_lcr_crearop_batch')
	drop proc sp_lcr_crearop_batch
go



create proc sp_lcr_crearop_batch(

    @i_param1           int             ,  --Cliente 
   @i_param2           char(2)         , -- Periodicidad ( W, BW , M)
   @i_param3           datetime,          --fecha valor
   @o_banco            cuenta = null output
  
    
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
@w_error             int,
@w_cont              int,
@w_fecha_valor       datetime,
@w_banco             cuenta,
@w_bd            	 varchar(200),
@w_tabla             varchar(200),
@w_path_sapp         varchar(200),
@w_sapp              varchar(200),
@w_path              varchar(200),
@w_hora              char(6),
@w_destino           varchar(200),
@w_errores           varchar(200),
@w_fecha_arch        varchar(10),
@w_return            int,
@w_comando           varchar(2000),
@w_promo             char(1),
@w_sep               varchar(1),
@w_fecha             datetime,
@w_cuenta            cuenta ,
@w_descripcion       varchar(255) 

   

select @w_fecha_valor = fp_fecha 
from cobis..ba_fecha_proceso 

select @w_fecha_valor = isnull(@i_param3,@w_fecha_valor)


--INICIALIZACION DE VARIABLES
select  @s_ssn  = convert(int,rand()*10000)

select 
@s_user             ='usrbatch',
@s_srv              ='CTSSRV',
@s_term             ='batch-crearop',
@s_rol              =3,
@s_lsrv             ='CTSSRV',
@w_sp_name          = 'sp_lcr_crearop_batch',
@s_sesn             = @s_ssn,
@s_date             = @w_fecha_valor



EXEC @w_error = sp_lcr_crear
@s_ssn              = @s_ssn,
@s_ofi              = 3354,
@s_user             = 'jjmondragon',
@s_sesn             = @s_ssn,
@s_term             = 'crearoplcr',
@s_date             = @w_fecha_valor,
@i_cliente          = @i_param1,     
@i_periodicidad     = @i_param2,
@i_fecha_valor      = @w_fecha_valor,
@o_banco            = @w_banco out  

if @w_error <> 0 begin 
    select @w_msg = 'ERROR NO EXISTE LA 	EJECUCION DEL SP DE UTILIZACION' 
    goto ERROR_FIN

end 



select 
@w_cuenta = op_cuenta 
from ca_operacion 
where op_banco = @w_banco


select 
@w_cuenta      = isnull(@w_cuenta, 'NO EXISTE CUENTA'),
@w_descripcion = @w_banco+char(9)+convert(varchar,@i_param1)+char(9)+@w_cuenta


insert into ca_errorlog (er_fecha_proc, er_error, er_usuario, er_tran, er_cuenta, er_descripcion, er_anexo)  
values(getdate(),0,'crearbatch',7001, @w_banco,@w_descripcion ,'')  


select @o_banco = @w_banco

return 0


ERROR_FIN:

exec sp_errorlog 
@i_fecha     = @s_date,
@i_error     = @w_error,
@i_usuario   = 'sp_lcr_crearop_batch',
@i_tran      = 7999,
@i_tran_name = @w_sp_name,
@i_cuenta    = @w_banco,
@i_rollback  = 'N'

go




