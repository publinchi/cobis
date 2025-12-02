/************************************************************************/
/*      Archivo:                condivis.sp                             */
/*      Stored procedure:       sp_consulta_divisas                     */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           LCA                                     */
/*      Fecha de escritura:     Jun. 2020                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'                                                        */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Obtiene las cotizaciones en la moneda de la operacion           */
/*                                                                      */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR           RAZON                           */
/*    05/Jun/20       Luis Castellanos  Emision Inicial                 */
/*                                                                      */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_consulta_divisas')
           drop proc sp_consulta_divisas
go

create procedure sp_consulta_divisas
(
   @s_user                login = null,
   @s_term                descripcion=null,
   @t_debug               char(1)     = 'N',
   @t_file                varchar(14) = null,
   @t_from                varchar(32) = null,  
   @s_date  	          datetime = null,
   @s_ofi	              smallint = null,
   @s_ssn                 int = null,
   @t_trn	              int = 77541,
   @t_show_version        bit = 0, 
   @i_banco               cuenta       = null,
   @i_modulo              char(3)      = null,      
   @i_concepto            catalogo     = null,        -- Concepto de la negociaci=n.  Valor del catﬂlogo sb_divisas_modulos.  Se   */
   @i_operacion           estado       = 'C', --null,                   /* C - Consulta, E - Ejecuci=n normal , R - Reversar una operaci=n anterior  */
   @i_cot_contable        estado       = 'N',       /* Se usa solo en @i_operacion = 'C' para tomar cotizaciones contables       */
   @i_moneda_origen       tinyint       = null,                  /* Moneda en la cual estﬂ expresado el monto a convertir                     */
   @i_valor               money        = 0,         /* Monto a convertir                                                         */
   @i_moneda_destino      tinyint      = null,
   --@o_cotizacion          money        = null out,
   @o_cotizacion          float        = null out,   
   @o_valor_convertido    money        = null out,
   @o_tipo_op             char(1)      = null OUT,
   @o_cot_usd             FLOAT        = NULL OUT,
   @o_factor              FLOAT        = NULL OUT   
   
)

as

--Declaro variables de trabajo 

declare @w_valor_convertido     money,
        @w_cot_usd              float,
        @w_factor               float,
        @w_msg_error            varchar(255),
        @w_cotizacion           float,
        @w_sp_name              varchar(32),
        @w_return               int,
		@w_cliente              int,
		@w_moneda               int,
		@w_tipo_cotiza          char(1),
		@w_monto                MONEY,
		@w_error                INT

select @w_sp_name = 'sp_consulta_divisas'
select @w_valor_convertido = 0
select @w_cotizacion = 0
select @w_monto = 0

-------------------------------------
-- Obtener Datos de Cartera --
  select 
   @w_cliente           = op_cliente,
   @w_moneda            = op_moneda,
   @w_monto             = op_monto
   from   ca_operacion
   where  op_banco  = @i_banco

  if @t_trn != 77541 --7465
  begin
    exec cobis..sp_cerror
           @t_debug     = @t_debug,
           @t_file      = @t_file,
           @t_from      = @w_sp_name,
           @i_num       = 701046--codigo transaccion no corresponde
    return 1
  end
if (@i_operacion = 'C')
begin  
   exec @w_error = cob_cartera..sp_op_divisas_automatica
     @s_date     = @s_date,
     @s_user     = @s_user,
     @s_ssn      = @s_ssn,
     @i_oficina  = @s_ofi,
     @i_cliente  = @w_cliente,
     @i_modulo   = 'CCA',
     @i_concepto = @i_concepto,
     @i_operacion    = 'C', 
	 @i_cot_contable  = @i_cot_contable, --'N',
     @i_moneda_origen= @i_moneda_origen,
     @i_valor        = @i_valor,
     @i_moneda_destino = @i_moneda_destino,
     @o_valor_convertido = @w_valor_convertido out,
     @o_msg_error  = @w_msg_error out,
     @o_cotizacion = @w_cotizacion out,
	 @o_tipo_op    = @w_tipo_cotiza OUT,
     @o_cot_usd    = @o_cot_usd OUT,
     @o_factor     = @o_factor out
	 
     IF @w_error <> 0
        RETURN @w_error
/*PRINT '@w_msg_error ' + CAST(@w_msg_error AS VARCHAR)
PRINT '@w_error ' + CAST(@w_error AS VARCHAR)
PRINT '@w_cotizacion ' + CAST(@w_cotizacion AS VARCHAR)
PRINT '@w_tipo_cotiza ' + CAST(@w_tipo_cotiza AS VARCHAR)
*/

/*	select @o_cotizacion = 123.3211 --7.56
    select @o_valor_convertido = @w_monto*7.56
	select @o_tipo_op = 'C'
*/	
	select @o_cotizacion = @w_cotizacion
    select @o_valor_convertido = @w_valor_convertido
	select @o_tipo_op = @w_tipo_cotiza
   END
   
return 0
                                                                                                                                                                                                                                    
go
