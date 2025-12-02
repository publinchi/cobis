/************************************************************************/
/*   Archivo:              ingdetab.sp                                  */
/*   Stored procedure:     sp_ing_detabono                              */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         R. Garces                                    */
/*   Fecha de escritura:   Feb. 1995                                    */
/************************************************************************/
/*                           IMPORTANTE                                 */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   "COBISCORP S.A.".                                                  */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBISCORP S.A. o su representante.        */
/*                                 PROPOSITO                            */
/*   Ingresar los detalles de abonos temporales                         */
/************************************************************************/
/*                               MODIFICACIONES                         */
/************************************************************************/
/*   FECHA            AUTOR              RAZON                          */
/*  23/Jun/2021    	Aldair Fortiche		se agrega variable de salida	*/
/*										para obtener un	secuencial		*/
/*  10/Ago/2022     G. Fernandez        R191162 Ingreso de parametro de */
/*                                      descripción                     */
/************************************************************************/


use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_ing_detabono')
   drop proc sp_ing_detabono
go
---LS-36266 partiendo de la version 3
create proc sp_ing_detabono
         @s_user               login      = null,
         @s_date               datetime   = null,
         @s_sesn               int        = null,
         @s_term               descripcion = null, 
	     @s_ssn                int         = null,
         @t_trn                INT         = NULL, --LPO CDIG Cambio de Servicios a Blis               
         @i_accion             char(1),
         @i_encerar            char(1),
         @i_tipo               char(3)     = null,    
         @i_concepto           catalogo,
         @i_cuenta             cuenta      = '',
         @i_moneda             int         = null,
         @i_beneficiario       descripcion = '',
         @i_monto_mpg          money       = null,    
         @i_monto_mop          money       = null,    
         @i_monto_mn           money       = null, 
         @i_cotizacion_mpg     money       = null,
         @i_cotizacion_mop     money       = null,  
         @i_tcotizacion_mpg    char(1)     = null,
         @i_tcotizacion_mop    char(1)     = null,
         @i_no_cheque          int         = null,
         @i_cod_banco          catalogo    = null,
         @i_inscripcion        int         = null,
         @i_carga              int         = null,
         @i_banco              cuenta      = null,
         @i_factura            char(16)    = null,
         @i_porcentaje         float       = null,
         @i_crear_alterna      char(1)     = 'N',
         @i_fecha_vig          datetime    = NULL,
		 @i_descripcion        varchar(50) = null,
		 @o_secuencial_ing       int       = NULL out
         
as declare
   @w_sp_name      descripcion,
   @w_fecha_hoy    datetime,
   @w_error        int,
   @w_return       int


begin tran

exec @w_return =  sp_ing_detabono_int
@s_user            = @s_user,
@s_date            = @s_date,
@s_sesn            = @s_sesn,
@s_term            = @s_term,
@i_accion          = @i_accion,
@i_encerar         = @i_encerar,
@i_tipo            = @i_tipo,    
@i_concepto        = @i_concepto,
@i_cuenta          = @i_cuenta,
@i_moneda          = @i_moneda,
@i_beneficiario    = @i_beneficiario,
@i_monto_mpg       = @i_monto_mpg,    
@i_monto_mop       = @i_monto_mop,    
@i_monto_mn        = @i_monto_mn, 
@i_cotizacion_mpg  = @i_cotizacion_mpg,
@i_cotizacion_mop  = @i_cotizacion_mop,  
@i_tcotizacion_mpg = @i_tcotizacion_mpg,
@i_tcotizacion_mop = @i_tcotizacion_mop,
@i_no_cheque       = @i_no_cheque,
@i_cod_banco       = @i_cod_banco,
@i_inscripcion     = @i_inscripcion,
@i_carga           = @i_carga,
@i_banco           = @i_banco,       
@i_factura         = @i_factura,
@i_porcentaje      = @i_porcentaje,
@i_crear_alterna   = @i_crear_alterna,
@i_fecha_vig       = @i_fecha_vig,
@i_descripcion     = @i_descripcion,
@o_secuencial_ing  = @o_secuencial_ing out

if @w_return <> 0 begin
   select @w_error = @w_return
   goto ERROR
end    

commit tran

return 0

ERROR:
exec cobis..sp_cerror
@t_debug='N',    
@t_file=null,
@t_from=@w_sp_name,   
@i_num = @w_error

return @w_error    

go
