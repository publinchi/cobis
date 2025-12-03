/************************************************************************/
/*      Archivo:                ejecuta_operaciones.sp                  */
/*      Stored procedure:       sp_ejecuta_operaciones                  */
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
/* DIC 28/2016             JBA              DESACOPLAMIENTO             */     
/************************************************************************/

use cob_interface
go
if exists (select 1 from sysobjects where name = 'sp_ejecutacion_operaciones')
   drop proc sp_ejecutacion_operaciones 
go

create proc sp_ejecutacion_operaciones(
    @i_tabla varchar(100) = null,
    @i_sql varchar(max) = null,
    @i_operacion char(1) = null,
    @i_producto varchar(10) = null,
    
    @i_param_var1 varchar(50) = null,
    @i_param_var2 varchar(50) = null,
    @i_param_var3 varchar(50) = null,
    @i_param_var4 varchar(50) = null,
    @i_param_var5 varchar(50) = null,
    
    @i_param_int1 int = null,
    @i_param_int2 int = null,
    @i_param_int3 int = null,
    @i_param_int4 int = null,
    @i_param_int5 int = null,
    
    @i_param_date1 datetime = null,
    @i_param_date2 datetime = null,
    @i_param_date3 datetime = null,
    @i_param_date4 datetime = null,
    @i_param_date5 datetime = null    
)as 
declare @w_error int, 
		@w_sp_name varchar(100),
        @w_sql varchar(max),
		@w_msg     varchar(256)
select @w_sp_name      =  'sp_ejecutacion_operaciones'
if exists(select * from cobis..cl_producto where pd_abreviatura = @i_producto)
begin
    if @i_operacion = 'I'
    begin
        select 1
    end
    
    if @i_operacion = 'U'
    begin
        select 2
    end
    
    if @i_operacion = 'D'
    begin
        select 3
    end
    
    if @i_operacion = 'S'
    begin
        select 4
    end    
    else
    begin
        select 5
    end
    
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

