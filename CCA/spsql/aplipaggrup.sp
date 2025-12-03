/************************************************************************/
/*   Archivo:                 aplipaggrup.sp                            */
/*   Stored procedure:        sp_aplica_pago_grupal                     */
/*   Base de Datos:           cob_cartera                               */
/*   Producto:                Cartera                                   */
/*   Disenado por:            Edison Cajas M.                           */
/*   Fecha de Documentacion:  Julio. 2019                               */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier autorizacion o agregado hecho por alguno de sus          */
/*   usuario sin el debido consentimiento por escrito de la             */
/*   Presidencia Ejecutiva de MACOSA o su representante                 */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Ejecuta el pago de una operacion grupal y sus interciclos          */
/************************************************************************/ 
/*                              MODIFICACIONES                          */ 
/*      FECHA           AUTOR           RAZON                           */
/*   03/Jul/2019   Edison Cajas. Emision Inicial                        */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_aplica_pago_grupal')
    drop proc sp_aplica_pago_grupal
go

create proc sp_aplica_pago_grupal
(
    @s_user          login        = null,
    @s_term          varchar(30)  = null,
    @s_srv           varchar(30)  = null,
    @s_date          datetime     = null,
    @s_sesn          int          = null,
	@s_ssn           int          = null,
    @s_ofi           smallint     = null,
    @s_rol           smallint     = null,
	@t_trn           int,
    @i_banco         cuenta,      --cuenta grupal padre
    @i_monto_pago    money,       --monto de pago a aplicar
    @i_forma_pago    catalogo,    --forma de pago a aplicar
    @i_moneda_pago   smallint,    --moneda de pago a aplicar
    @i_fecha_pago    datetime,    --fecha de pago a aplicar
    @i_referencia    descripcion,  --detalle de pago a aplicar
	@i_operacion     char(1)      = null
)
as
declare 
    @w_sp_name           descripcion   ,@w_error         int        ,@w_return             int
	,@w_est_vigente      tinyint       ,@w_est_vencido   tinyint    ,@w_est_cancelado      tinyint
	,@w_est_novigente    tinyint       ,@w_operaciongp   int        ,@w_fecha_ult_proceso  datetime
	,@w_di_fecha_ven     datetime
		
				

select @w_sp_name = 'sp_aplica_pago_grupal'

if @t_trn <> 77509
begin
    select @w_error = 151051
    goto ERROR
end


/* ESTADOS DE CARTERA */
exec @w_error         = sp_estados_cca
     @o_est_vigente   = @w_est_vigente   out,
     @o_est_vencido   = @w_est_vencido   out,
     @o_est_cancelado = @w_est_cancelado out,
     @o_est_novigente = @w_est_novigente out

if @w_error <> 0 return 708201


IF @i_operacion = 'F' --Fecha Vencimiento de Dividendo Vigente
BEGIN
    SELECT @w_operaciongp       = op_operacion,
           @w_fecha_ult_proceso = op_fecha_ult_proceso
      FROM ca_operacion
	 where op_banco = @i_banco    
   
    SELECT @w_di_fecha_ven = di_fecha_ven 
      FROM ca_dividendo
     WHERE di_operacion = @w_operaciongp
       and di_estado    = @w_est_vigente
     
    SELECT @w_di_fecha_ven, @w_fecha_ult_proceso
	
    RETURN 0   
END

exec @w_return       = sp_prorratea_pago_grupal
     @s_user         = @s_user,
     @s_term         = @s_term,
     @s_srv          = @s_srv,  
     @s_date         = @s_date,
     @s_sesn         = @s_sesn,
     @s_ssn          = @s_ssn,
     @s_ofi          = @s_ofi,
     @s_rol		     = @s_rol,
     @i_banco        = @i_banco,
     @i_monto_pago   = @i_monto_pago,
     @i_forma_pago   = @i_forma_pago,
     @i_moneda_pago  = @i_moneda_pago, 
     @i_fecha_pago   = @i_fecha_pago,
     @i_referencia   = @i_referencia
         
if @w_return != 0
begin
    select @w_error = @w_return
    goto ERROR
end

return 0

ERROR:
      exec cobis..sp_cerror
      @t_debug = 'N',
      @t_file  = null, 
      @t_from  = @w_sp_name,
      @i_num   = @w_error,
	  @i_sev   = 0
	  
return 1
go