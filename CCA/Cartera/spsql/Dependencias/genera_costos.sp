/************************************************************************/
/*      Archivo:                genera_costos.sp                        */
/*      Stored procedure:       sp_genera_costos                        */
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
if exists (select 1 from sysobjects where name = 'sp_genera_costos')
   drop proc sp_genera_costos 
go

create proc sp_genera_costos  ( 
    @i_categoria    char(1)  = null,
    @i_tipo_ente    char(1)  = null,
    @i_rol_ente     char(1)  = null,
    @i_tipo_def     char(1)  = null,
    @i_prod_banc    smallint = null,
    @i_producto     char(1)  = null,
    @i_moneda       tinyint  = null,
    @i_tipo         char(5)  = null,
    @i_codigo       int      = null,
    @i_servicio     char(5)  = null,
    @i_rubro        char(5)  = null,
    @i_disponible   money    = null,
    @i_contable     money    = null,
    @i_promedio     money    = null,
    @i_personaliza  char(5)  = null,
    @i_filial       int      = null,
    @i_oficina      int      = null,
    @i_fecha        datetime = null,
    @o_valor_total  money    = null out
)
as
declare @w_error int, 
		@w_sp_name varchar(100),
		@w_msg     varchar(256)
select @w_sp_name      =  'sp_ahndc_automatica'
if exists(select * from cobis..cl_producto where pd_producto = 10)
begin
     exec @w_error = cob_remesas..sp_genera_costos 
         @i_categoria    = @i_categoria,   
         @i_tipo_ente    = @i_tipo_ente,  
         @i_rol_ente     = @i_rol_ente,    
         @i_tipo_def     = @i_tipo_def,    
         @i_prod_banc    = @i_prod_banc,   
         @i_producto     = @i_producto,    
         @i_moneda       = @i_moneda,      
         @i_tipo         = @i_tipo,        
         @i_codigo       = @i_codigo,      
         @i_servicio     = @i_servicio,    
         @i_rubro        = @i_rubro,       
         @i_disponible   = @i_disponible,  
         @i_contable     = @i_contable,    
         @i_promedio     = @i_promedio,    
         @i_personaliza  = @i_personaliza, 
         @i_filial       = @i_filial,      
         @i_oficina      = @i_oficina,     
         @i_fecha        = @i_fecha,       
         @o_valor_total  = @o_valor_total  out
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

