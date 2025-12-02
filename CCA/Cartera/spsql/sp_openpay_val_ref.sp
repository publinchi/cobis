/***************************************************************************/
/*    Base de datos:            cob_cartera                                */
/*      Producto:               Cartera                                    */
/*      Disenado por:           Sonia Rojas                                */
/*      Fecha de escritura:     13/09/2018                                 */
/***************************************************************************/
/*                              IMPORTANTE                                 */
/*      Este programa es parte de los paquetes bancarios propiedad de      */
/*      'MACOSA'.                                                          */
/*      Su uso no autorizado queda expresamente prohibido asi como         */
/*      cualquier alteracion o agregado hecho por alguno de sus            */
/*      usuarios sin el debido consentimiento por escrito de la            */
/*      Presidencia Ejecutiva de MACOSA o su representante.                */
/***************************************************************************/  
/*                         PROPOSITO                                       */
/*      Tiene como propósito procesar los pagos de los corresponsales      */
/*                        MOFICACIONES                                     */
/* 24/07/2018         SRO                  Validaciones referencias openpay*/
/***************************************************************************/  
use cob_cartera
go


if exists(select 1 from sysobjects where name ='sp_openpay_val_ref')
	drop proc sp_openpay_val_ref
GO


CREATE proc sp_openpay_val_ref(
    @s_ssn              int                = null,
    @s_user             login              = null,
    @s_sesn             int                = null,
    @s_term             varchar(30)        = null,
    @s_date             datetime           = null,
    @s_srv              varchar(30)        = null,
    @s_lsrv             varchar(30)        = null,
    @s_ofi              smallint           = null,
    @s_servicio         int                = null,
    @s_cliente          int                = null,
    @s_rol              smallint           = null,
    @s_culture          varchar(10)        = null,
    @s_org              char(1)            = null,
    @i_referencia       varchar(255)       = null, -- Obligatorio 
	@i_fecha_pago       varchar(8)         = null, -- Fecha de Pago
    @i_monto_pago       varchar(14)        = null, -- Monto de Pago
    @i_archivo_pago     varchar(255),              -- Archivo de Pago, opcional
	@o_tipo             char(2)            out,    -- Tipo de transacción (G,C,P)
    @o_codigo_interno   varchar(10)        out,    -- Código interno
    @o_fecha_pago       datetime           out,    -- Fecha de pago
    @o_monto_pago       money              out,     -- Monto de pago
    @o_tipo_tran        char(2)            = null   out
)
as
declare 
@w_sp_name                 varchar(30),
@w_codigo_int              int,
@w_error                   int,
@w_msg                     varchar(255),
@w_cadena                  varchar(64),
@w_cadena_proce            varchar(64),
@w_tipo_tran               char(2)

select @w_sp_name  = 'sp_openpay_val_ref'

select @w_tipo_tran = substring(@i_referencia,1,2)

if len (@i_referencia) <> 29
begin
   select @w_error=70204
end

if  @w_tipo_tran <> 'GL'
and @w_tipo_tran <> 'PG'
and @w_tipo_tran <> 'PI'
and @w_tipo_tran <> 'PR'
and @w_tipo_tran <> 'CG'
and @w_tipo_tran <> 'CI' begin
   select @w_error = 70204,
          @w_msg   = 'ERROR: TIPO DE TRANSACCIÓN NO VÁLIDA'
   goto ERROR_FIN
end

select @o_tipo_tran = @w_tipo_tran

if isdate(substring(@i_fecha_pago,1,2) + '/'+ substring(@i_fecha_pago,3,2)+'/'+substring(@i_fecha_pago,5,4))=0
begin
    select @w_error = 70177,
           @w_msg   = 'ERROR: EL FORMATO DE LA FECHA DE PAGO ES INCORRECTO. ' +
                      'FECHA DE PAGO: ' + substring(@i_fecha_pago,1,2) + '/'+ substring(@i_fecha_pago,3,2)+'/'+substring(@i_fecha_pago,5,4)
    goto ERROR_FIN

end

select @o_fecha_pago = convert(datetime, substring(@i_fecha_pago,1,2) + '/'+ substring(@i_fecha_pago,3,2)+'/'+substring(@i_fecha_pago,5,4))

      
select @w_cadena = substring(rtrim(ltrim(@i_referencia))   ,1,   len(rtrim(ltrim(@i_referencia))) - 1)
select @w_cadena_proce = dbo.CalcularDigitoVerificadorOpenPay(@w_cadena) 

if @w_cadena_proce != @i_referencia BEGIN
   select @w_msg = 'DIGITO VERIFICADOR DE LA REFERENCIA NO CORRESPONDE'  + convert(varchar, @i_referencia)
   goto ERROR_FIN
end

select @o_tipo           = substring(@i_referencia,14,1)
select @o_codigo_interno = convert(INT,substring(@i_referencia,7,7))
select @o_monto_pago     = isnull(convert(money,(convert(int, @i_monto_pago)/100.0)), convert(MONEY,substring(@w_cadena,21,6) + '.' + substring(@w_cadena,27,2)))

return 0


ERROR_FIN:
   return @w_error

go