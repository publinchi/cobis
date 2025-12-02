/************************************************************************/
/*      Archivo:                imprimir_lotes.sp                       */
/*      Stored procedure:       sp_imprimir_lotes                       */
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
if exists (select 1 from sysobjects where name = 'sp_imprimir_lotes')
   drop proc sp_imprimir_lotes 
go

create proc sp_imprimir_lotes  ( 
    @t_trn              int          = null,
    @s_ssn              int          = null,
    @s_date             datetime     = null,
    @s_user             login        = null,
    @s_term             varchar(30)  = null,
    @s_ofi              smallint     = null,
    @s_lsrv             varchar(30)  = null,
    @s_srv              varchar(30)  = null,
    @i_estado           varchar(5)   = null,
    @i_oficina_origen   smallint     = null,
    @i_ofi_destino      smallint     = null,
    @i_area_origen      smallint     = null,
    @i_fecha_solicitud  datetime     = null,
    @i_producto         int          = null,
    @i_instrumento      int          = null,
    @i_subtipo          int          = null,
    @i_valor            money        = null,
    @i_beneficiario     descripcion  = null,
    @i_referencia       int          = null,
    @i_tipo_benef       catalogo     = null,
    @i_campo1           varchar(254) = null,
    @i_campo2           varchar(254) = null,
    @i_campo3           varchar(254) = null,
    @i_campo4           varchar(254) = null,
    @i_campo5           cuenta       = null,
    @i_campo6           varchar(30)  = null,
    @i_campo7           descripcion  = null,
    @i_campo21          varchar(5)   = null,
    @i_campo22          varchar(5)   = null,
    @i_campo40          char(1)      = null,
    @o_secuencial       int          = null out
    
)
as
declare @w_error int, 
		@w_sp_name varchar(100),
		@w_msg     varchar(256)

select @w_sp_name      =  'sp_imprimir_lotes'
/*
if exists(select * from cobis..cl_producto where pd_producto = 10) --cob_sbancarios? preguntar
begin
     exec @w_error = cob_sbancarios..sp_imprimir_lotes
         @t_trn              = @t_trn             
         ,@s_ssn              = @s_ssn             
         ,@s_date             = @s_date            
         ,@s_user             = @s_user            
         ,@s_term             = @s_term            
         ,@s_ofi              = @s_ofi             
         ,@s_lsrv             = @s_lsrv            
         ,@s_srv              = @s_srv             
         ,@i_estado           = @i_estado          
         ,@i_oficina_origen   = @i_oficina_origen  
         ,@i_ofi_destino      = @i_ofi_destino     
         ,@i_area_origen      = @i_area_origen     
         ,@i_fecha_solicitud  = @i_fecha_solicitud 
         ,@i_producto         = @i_producto        
         ,@i_instrumento      = @i_instrumento     
         ,@i_subtipo          = @i_subtipo         
         ,@i_valor            = @i_valor           
         ,@i_beneficiario     = @i_beneficiario    
         ,@i_referencia       = @i_referencia      
         ,@i_tipo_benef       = @i_tipo_benef      
         ,@i_campo1           = @i_campo1          
         ,@i_campo2           = @i_campo2          
         ,@i_campo3           = @i_campo3          
         ,@i_campo4           = @i_campo4          
         ,@i_campo5           = @i_campo5          
         ,@i_campo6           = @i_campo6          
         ,@i_campo7           = @i_campo7          
         ,@i_campo21          = @i_campo21         
         ,@i_campo22          = @i_campo22         
         ,@i_campo40          = @i_campo40         
         ,@o_secuencial       = @o_secuencial out   
    if @w_error <> 0
		GOTO ERROR
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

