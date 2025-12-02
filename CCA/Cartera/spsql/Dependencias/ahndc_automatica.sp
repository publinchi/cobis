/************************************************************************/
/*      Archivo:                ahndc_automatica.sp                     */
/*      Stored procedure:       sp_ahndc_automatica                     */
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
/* JUN 27/2019             AGi              FORMATO FECHA ELIMINO HORA  */     
/* DIC 19/2019             Luis Ponce       Control Fondos Insuficientes*/
/* DIC 26/2019             Luis Ponce       Control para No cortar Batch*/
/* Mar 17/2020             Luis Ponce   CDIG AJUSTE EN BATCH POR CONTROL*/
/*                                      DE COMMIT EN SPS'S DE AHORROS   */
/************************************************************************/
use cob_interface
go
if exists (select 1 from sysobjects where name = 'sp_ahndc_automatica')
   drop proc sp_ahndc_automatica
go

create proc sp_ahndc_automatica  ( 
    @s_ssn         int         = null,   
    @s_srv         varchar(30) = null,
    @s_ofi         smallint    = null,
    @s_user        varchar(30) = null,
    @t_trn         int         = null,
    @i_cta         cuenta      = null,
    @i_val         money       = null,  
    @i_cau         varchar(20) = null,
    @i_mon         smallint    = null, 
    @i_fecha       datetime    = null,
    @t_ssn_corr    int         = null,      --secuencial (@s_ssn) de la transacción a reversar.
    @t_corr        char(1)     = null,          --S/N dependiendo si es una reversa o no.                     
    @i_alt         int         = null,
    @i_inmovi      varchar(3)  = null,
    @i_activar_cta varchar(3)  = null,
    @i_is_batch    varchar(3)  = null
)
as
declare @w_error int, 
		@w_sp_name varchar(100),
		@w_msg     varchar(256)

select @w_sp_name      =  'sp_ahndc_automatica'
if exists(select * from cobis..cl_producto where pd_producto = 4)
begin

    select @i_fecha = convert(datetime,convert(varchar, @i_fecha, 101))

    exec @w_error   = cob_ahorros..sp_ahndc_automatica 
    @s_ssn          = @s_ssn,        
    @s_srv          = @s_srv,       
    @s_ofi          = @s_ofi,
    @s_user         = @s_user,
    @t_trn          = @t_trn,        
    @i_cta          = @i_cta,        
    @i_val          = @i_val,        
    @i_cau          = @i_cau,        
    @i_mon          = @i_mon,        
    @i_fecha        = @i_fecha,      
    @t_ssn_corr     = @t_ssn_corr,   
    @t_corr         = @t_corr,       
    @i_alt          = @i_alt,        
    @i_inmovi       = @i_inmovi,     
    @i_tran_ext     = 'S',
    @i_activar_cta  = @i_activar_cta,
    @i_is_batch     = @i_is_batch   
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

/*   exec cobis..sp_cerror
   @t_debug  = 'N',          
   @t_file = null,
   @t_from   = @w_sp_name,   
   @i_num = @w_error,
   @i_msg = @w_msg
   return @w_error
   */

IF @i_is_batch = 'N' --LPO TEC Se adiciona manejo de En linea o batch
BEGIN
   exec cobis..sp_cerror
   @t_debug  = 'N',          
   @t_file = null,
   @t_from   = @w_sp_name,   
   @i_num = @w_error,
   @i_msg = @w_msg
   return @w_error
END
ELSE
BEGIN
   --LPO CDIG AJUSTE EN BATCH POR CONTROL DE COMMIT EN SPS'S DE AHORROS, se vuelve a habilirar el return @w_error (INICIO)
   /*
   --return @w_error --LPO TEC EN batch no se debe cortar todo el proceso, debe continuar a la siguiente operacion
   RETURN 0 --LPO TEC EN batch no se debe cortar todo el proceso, debe continuar a la siguiente operacion
   */
   --LPO CDIG AJUSTE EN BATCH POR CONTROL DE COMMIT EN SPS'S DE AHORROS, se vuelve a habilirar el return @w_error (FIN)
   
   --LPO CDIG AJUSTE EN BATCH POR CONTROL DE COMMIT EN SPS'S DE AHORROS, se vuelve a habilirar el return @w_error (INICIO)
   return @w_error
   --LPO CDIG AJUSTE EN BATCH POR CONTROL DE COMMIT EN SPS'S DE AHORROS, se vuelve a habilirar el return @w_error (FIN)
   
END


GO
