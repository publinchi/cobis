/************************************************************************/
/*      Archivo:                upd_totales.sp                          */
/*      Stored procedure:       sp_upd_totales                          */
/*      Producto:               cob_interface                           */
/*      Disenado por:           Jorge Baque H                           */
/*      Fecha de escritura:     DIC 27 2016                             */
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
/* DIC 27/2016             JBA              DESACOPLAMIENTO             */     
/************************************************************************/
use cob_interface
go
if exists (select 1 from sysobjects where name = 'sp_upd_totales')
   drop proc sp_upd_totales 
go

create proc sp_upd_totales  ( 
    @i_ofi             smallint     = null, 
    @i_rol             smallint     = null, 
    @i_user            login        = null,
    @i_mon             tinyint      = null,
    @i_trn             smallint     = null, 
    @i_nodo            varchar(30)  = null,
    @i_tipo            varchar(5)   = null,
    @i_corr            char(1)      = null,
    @i_efectivo        money        = null,
    @i_cheque          int          = null,
    @i_chq_locales     money        = null,
    @i_chq_ot_plaza    int          = null,
    @i_ssn             int          = null,
    @i_filial          smallint     = null, 
    @i_idcaja          int          = null,
    @i_idcierre        int          = null,
    @i_saldo_caja      money        = null
    
)
as
declare @w_error int, 
		@w_sp_name varchar(100),
		@w_msg     varchar(256)
select @w_sp_name      =  'sp_upd_totales'
if exists(select * from cobis..cl_producto where pd_producto = 10)
begin
    exec @w_error      = cob_remesas..sp_upd_totales
       @i_ofi             = @i_ofi          
      ,@i_rol             = @i_rol          
      ,@i_user            = @i_user         
      ,@i_mon             = @i_mon          
      ,@i_trn             = @i_trn          
      ,@i_nodo            = @i_nodo         
      ,@i_tipo            = @i_tipo         
      ,@i_corr            = @i_corr         
      ,@i_efectivo        = @i_efectivo     
      ,@i_cheque          = @i_cheque       
      ,@i_chq_locales     = @i_chq_locales  
      ,@i_chq_ot_plaza    = @i_chq_ot_plaza 
      ,@i_ssn             = @i_ssn          
      ,@i_filial          = @i_filial       
      ,@i_idcaja          = @i_idcaja       
      ,@i_idcierre        = @i_idcierre     
      ,@i_saldo_caja      = @i_saldo_caja   
    if @w_error <> 0
		GOTO ERROR
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


