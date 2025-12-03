/************************************************************************/
/*      Archivo:                codeudor_interface.sp                   */
/*      Stored procedure:       sp_codeudor_interfase                   */
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
if exists (select 1 from sysobjects where name = 'sp_codeudor_interfase')
   drop proc sp_codeudor_interfase 
go

create proc sp_codeudor_interfase(
    @i_operacion       char(1),
    @i_cliente         int
)
as
declare @w_error int, 
		@w_sp_name varchar(100),
		@w_msg     varchar(256)
        
select @w_sp_name      =  'sp_codeudor_interfase'

if exists(select 1 from cobis..cl_producto where pd_producto = 10)
begin
    if @i_operacion = 'C'
    begin
        select
        'ORIGEN'              = rp_modulo_origen,
        'CONSECUTIVO'         = rp_consecutivo,
        'CxC/CxP'             = rp_submodulo,
        'DESCRIPCION CUENTA'  = substring(rp_descripcion,1,45),
        'VALOR'               = rp_saldo,
        'CONCEPTO'            = rp_concepto, 
        'No.REFERENCIA'       = rp_numero_referencia,    
        'ESTADO'              = case rp_estado
                                when 'V' then  'VIGENTE'
                                when 'C' then  'CANCELADO'
                                when 'P' then  'PENDIENTE'
                               end
                       
         from  cob_sidac..sid_registros_padre
         where rp_empresa = 1 
         and rp_submodulo in ('CC','CP')
         and   rp_ente =  @i_cliente
         and   rp_saldo > 0
         and   rp_estado in ('V','P')     
         order by rp_modulo_origen,rp_consecutivo
    end
    if @i_operacion = 'F'
    begin
        select 
          'VALOR' =rp_saldo,
          'No.REFERENCIA' = rp_numero_referencia,
          'CONSECUTIVO' = rp_consecutivo,
          'OFICINA' = rp_oficina
                
          from cob_sidac..sid_registros_padre
          where rp_numero_referencia > ''
          and   rp_consecutivo >= 0
          and   rp_ente = @i_cliente
          and   rp_concepto in ( select codigo from cobis..cl_catalogo
                                 where tabla = ( select codigo
                                                from cobis..cl_tabla
                                                where tabla = 'ca_concepto_dpg')
                                )
          and   rp_submodulo = 'CP'
          and   rp_saldo > 0
          and   rp_estado in ( 'V','P')
          and   rp_empresa = 1
          order by rp_consecutivo 
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

