/************************************************************************/
/*   Archivo:                 cancgrpint.sp                             */
/*   Stored procedure:        sp_cancela_grupal_intercic_srv            */
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
/*   Precancelacion Grupal o Interciclo                                 */
/************************************************************************/ 
/*                              MODIFICACIONES                          */ 
/*      FECHA           AUTOR           RAZON                           */
/*   18/Jul/2019   Edison Cajas.   Emision Inicial                      */
/*   30/Jul/2019   Luis Ponce      Forma de Pago Debito Cuenta Ahorros  */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_cancela_grupal_intercic_srv')
    drop proc sp_cancela_grupal_intercic_srv
go

create proc sp_cancela_grupal_intercic_srv
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
    @i_banco         cuenta,      
    @o_resultado     int          OUT,         
    @o_mensaje       varchar(200) OUT 
)
as
declare 
     @w_sp_name             descripcion   ,@w_error              int              ,@w_return                 int
	,@w_tipo_grupal         char(1)       ,@w_cuenta             cuenta           ,@w_monto_precancelacion   MONEY
	,@o_codigo_grupo        INT           ,@o_nombre_grupo       varchar(255)     ,@o_nom_cliente            varchar(64)
    ,@o_cta_banco           cuenta        ,@o_estado             varchar(64)      ,@o_cuota_ven              MONEY
	,@o_cuota_vig           MONEY         ,@o_total_pag          MONEY            ,@o_liquidar               MONEY
	,@o_tipo_credito        varchar(64)   ,@o_tipo_cartera       varchar(64)      ,@o_cuota_ven_interc       MONEY
    ,@o_cuota_vig_interc    MONEY         ,@o_total_pag_interc   MONEY            ,@o_liquidar_interc        MONEY
    ,@o_tipo_op_grupal      char(1)       ,@o_toperacion         catalogo         ,@w_secuencial_ing         int
	,@w_msg_matriz          varchar(255)  ,@w_operacion_inter    INT              ,@w_ndah_finan             catalogo
	
select @w_sp_name = 'sp_cancela_grupal_intercic_srv'

if @t_trn <> 77513
begin
    select @w_error = 151051
	select @o_mensaje = mensaje, @o_resultado = @w_error from cobis..cl_errores where numero = @w_error	
    goto ERROR
end


--LPO TEC Forma de pago Debito en Cuenta
select @w_ndah_finan = pa_char
from cobis..cl_parametro
where pa_nemonico = 'DEBCTA'
and pa_producto = 'CCA'

if @@rowcount = 0 
   RETURN 201196

--print 'numero de operacion' + convert(varchar, @i_banco)
EXEC @w_error              = cob_cartera..sp_montos_pago_grupal
     @i_banco              = @i_banco,
     @o_codigo_grupo       = @o_codigo_grupo      OUT,
     @o_nombre_grupo       = @o_nombre_grupo      OUT,
     @o_nom_cliente        = @o_nom_cliente       OUT,
     @o_cta_banco          = @o_cta_banco         OUT,
     @o_estado             = @o_estado            OUT,
     @o_cuota_ven          = @o_cuota_ven         OUT,
     @o_cuota_vig          = @o_cuota_vig         OUT,
     @o_total_pag          = @o_total_pag         OUT,
     @o_liquidar           = @o_liquidar          OUT,
     @o_tipo_credito       = @o_tipo_credito      OUT,
     @o_tipo_cartera       = @o_tipo_cartera      OUT,
     @o_cuota_ven_interc   = @o_cuota_ven_interc  OUT,
     @o_cuota_vig_interc   = @o_cuota_vig_interc  OUT,
     @o_total_pag_interc   = @o_total_pag_interc  OUT,
     @o_liquidar_interc    = @o_liquidar_interc   OUT,
     @o_tipo_op_grupal     = @o_tipo_op_grupal    OUT,
     @o_toperacion         = @o_toperacion        OUT
                   
IF @w_error <> 0
BEGIN
   select @o_mensaje = mensaje, @o_resultado = @w_error from cobis..cl_errores where numero = @w_error	
   goto ERROR
END

/*  CANCELA GRUPALES  */
IF @o_tipo_op_grupal = 'G'
BEGIN   
   
   SELECT @w_monto_precancelacion = @o_liquidar + @o_liquidar_interc
   
   SELECT @w_cuenta = op_cuenta
   FROM ca_operacion
   WHERE op_banco = @i_banco
   
   EXEC @w_error        = sp_prorratea_pago_grupal
        @s_user         = @s_user,
        @s_term         = @s_term,
        @s_srv          = @s_srv,  
        @s_date         = @s_date,
        @s_sesn         = @s_sesn,
        @s_ssn          = @s_ssn,
        @s_ofi          = @s_ofi,
        @s_rol		    = @s_rol,
        @i_banco        = @i_banco,
        @i_monto_pago   = @w_monto_precancelacion,
        @i_forma_pago   = @w_ndah_finan, --'NDAH_FINAN',
        @i_moneda_pago  = 0,
        @i_fecha_pago   = @s_date,
        @i_referencia   = @w_cuenta
         
     if @w_error <> 0
     begin  
		select @o_mensaje = mensaje, @o_resultado = @w_error from cobis..cl_errores where numero = @w_error	
        goto ERROR
     end
END

/*  CANCELA INTERCICLOS  */
IF @o_tipo_op_grupal = 'I'
BEGIN

   select @w_operacion_inter = op_operacion
     from ca_operacion
    where op_banco = @i_banco
   
   select @w_cuenta = op_cuenta
     from ca_operacion
    where op_banco = (select dc_referencia_grupal from ca_det_ciclo where dc_operacion = @w_operacion_inter)

   EXEC @w_error          = sp_pago_cartera
        @s_user           = @s_user,
        @s_term           = @s_term,
        @s_srv            = @s_srv,
        @s_date           = @s_date,
        @s_sesn           = @s_sesn,
        @s_ssn            = @s_ssn,
        @s_ofi            = @s_ofi,
        @i_banco          = @i_banco,
        @i_beneficiario   = 'DB.AUT',
        @i_cuenta         = @w_cuenta,
        @i_fecha_vig      = @s_date,
        @i_ejecutar       = 'S',
        @i_en_linea       = 'S',
        @i_producto       = @w_ndah_finan, --'NDAH_FINAN',
        @i_monto_mpg      = @o_liquidar,    --Es el total para Precancelacion de UNA Interciclo
        @i_moneda         = 0,
        @o_secuencial_ing = @w_secuencial_ing OUT,
        @o_msg_matriz     = @w_msg_matriz     OUT

   if @w_error <> 0
   begin
	  select @o_mensaje = mensaje, @o_resultado = @w_error from cobis..cl_errores where numero = @w_error	
      goto ERROR
   end
END

return 0

ERROR:
   exec cobis..sp_cerror
        @t_debug  = 'N',
        @t_file   = null, 
        @t_from   = @w_sp_name,
        @i_num    = @w_error
	  
return 1
go
