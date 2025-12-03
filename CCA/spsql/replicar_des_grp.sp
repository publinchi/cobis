/************************************************************************/
/*   Archivo:              replicar_des_grp.sp                          */
/*   Stored procedure:     sp_replicar_desembolsos_grupales 			*/
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Kevin Rodríguez                              */
/*   Fecha de escritura:   24/Junio/2021                                */
/************************************************************************/
/*                                  IMPORTANTE                          */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBIS'.                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBIS o su representante legal.           */
/************************************************************************/
/*                                   PROPOSITO                          */
/*   Replicar las formas de desembolso de la operación grupal padre     */
/*   a las operaciones grupales hijas                                   */
/*                                                                      */
/************************************************************************/
/*                            CAMBIOS                                   */
/************************************************************************/
/*   FECHA        AUTOR                    RAZON                        */
/* 24/Jun/2021   Kevin Rodríguez      Version inicial					*/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_replicar_desembolsos_grupales')
   drop proc sp_replicar_desembolsos_grupales
go

create proc sp_replicar_desembolsos_grupales (

@s_ofi                  SMALLINT     = NULL,
@s_user                 login        = NULL,
@s_date                 DATETIME     = NULL,
@s_term                 descripcion  = NULL,
@s_ssn                  INT          = null,
@i_tramite              INT						-- Tramite grupal (Padre)
)

AS DECLARE
   @w_sp_name           varchar(32),
   @w_error             int,
   @w_est_vigente       tinyint,
   @w_est_novigente     tinyint,
   @w_est_credito       tinyint,
   @w_banco_padre       cuenta,
   @w_banco_hijo        cuenta,
   @w_operacion_padre   INT,
   @w_operacion_hijo    INT,
   @w_estado_padre      TINYINT,
   @w_estado_hijo       TINYINT,
   @w_monto_padre       MONEY,
   @w_monto_hijo        MONEY,
   @w_fecha_liq_hijo    datetime,
   @w_forma_pago		catalogo,
   @w_monto_mds         MONEY,
   @w_monto_acum_des    MONEY,
   @w_sec_des           INT,         -- Secuencial de la operacion en desembolso
   @w_num_desembolso    TINYINT,     -- Secuencial de desembolso
   @w_beneficiario_h    varchar(64),
   @w_cliente_h         INT,
   @w_monto_hijo_des    MONEY,
   @w_por_montofp       float, 
   @w_cont              INT,
   @w_cont_des          int

SELECT @w_sp_name = 'sp_replicar_desembolsos_grupales'

-- OBTENER ESTADOS DE CARTERA
exec @w_error = sp_estados_cca 
@o_est_vigente    = @w_est_vigente   out,
@o_est_novigente  = @w_est_novigente out,
@o_est_credito    = @w_est_credito   out

if @w_error <> 0 GOTO ERROR

-- OBTENER INFORMACIÓN OPERACIÓN PADRE
SELECT
    @w_banco_padre     = op_banco,
    @w_operacion_padre = op_operacion,
    @w_estado_padre    = op_estado,
    @w_monto_padre     = op_monto
from  ca_operacion
where op_tramite = @i_tramite

if @@rowcount = 0
BEGIN
   select @w_error = 710022 -- No existe la operacion
   goto ERROR  
end

-- Verificar que la operación padre tenga forma de desembolso registrada
-- para replicar a sus operaciones hijas
IF NOT EXISTS (SELECT 1 FROM ca_desembolso
                        WHERE dm_operacion = @w_operacion_padre)
BEGIN
   select @w_error = 701121  -- No existe Desembolso
   goto ERROR
END

IF @w_estado_padre NOT IN (@w_est_novigente)
BEGIN
   select @w_error = 710505 -- Error, La Operacion Activa no esta en estado de desembolso (NO VIGENTE)
   goto ERROR   
END

-- Verificar que operaciones hijas no tengan formas de desembolsos.
IF EXISTS (SELECT 1 FROM ca_desembolso, ca_operacion
                    WHERE dm_operacion = op_operacion 
                    AND op_ref_grupal = @w_banco_padre)
BEGIN
   select @w_error = 711092 -- Ya existe al menos una forma de desembolso registrada
   goto ERROR
END

-- Tabla temporal con operaciones hijas

select * into #op_hijas FROM ca_operacion 
   WHERE op_ref_grupal in (select op_banco
                                from ca_operacion
                                where op_operacion = @w_operacion_padre)

if @@rowcount = 0
BEGIN
   select @w_error = 711095 -- Error, la operación padre no tiene operaciones hijas asociadas
   goto ERROR  
END

select @w_cont = count(1) from #op_hijas
  
while  @w_cont > 0
BEGIN

    -- OBTENER INFORMACIÓN OPERACIÓN HIJA
    select TOP 1 
        @w_operacion_hijo = op_operacion,
        @w_banco_hijo     = op_banco,
        @w_estado_hijo    = op_estado,
        @w_monto_hijo     = op_monto,
        @w_fecha_liq_hijo = op_fecha_liq,
        @w_beneficiario_h = op_nombre,
        @w_cliente_h      = op_cliente
    from #op_hijas

    IF @w_estado_hijo NOT IN (@w_est_novigente)
    BEGIN
       select @w_error = 710001 -- Error, La Operacion Activa no esta en estado de desembolso (NO VIGENTE)
       goto ERROR  
    END

    -- *****
    -- AQUI LA LOGICA DE DESEMBOLSO DE CADA OPERACION HIJAS
    
    -- Tabla temporal con formas de desembolso del padre.
    select * into #dm_des_padre FROM ca_desembolso
       WHERE dm_operacion = @w_operacion_padre
    
    select @w_cont_des = count(1) from #dm_des_padre
    
    while  @w_cont_des > 0
	BEGIN
		
	    SELECT TOP 1 
	        @w_forma_pago     = dm_producto,
	        @w_sec_des        = dm_secuencial,
	        @w_num_desembolso = dm_desembolso,
	        @w_monto_mds      = dm_monto_mds
	    FROM #dm_des_padre
	     
	    -- Porcentaje Monto de la forma de pago actual
	    SELECT @w_por_montofp = (@w_monto_mds * 100) / @w_monto_padre
	    
	    -- Monto a desembolsar del hijo segun forma de pago.
	    SELECT @w_monto_hijo_des = @w_monto_hijo * (@w_por_montofp/100)
	        
	    -- Cuadratura formas desembolso vs capital op. hijas
	    IF @w_cont_des = 1
	    BEGIN
	       SELECT @w_monto_acum_des = isnull(sum(dm_monto_mds),0) 
	          FROM ca_desembolso 
	          WHERE dm_operacion = @w_operacion_hijo
	          
	       IF @w_monto_hijo_des <> (@w_monto_hijo - @w_monto_acum_des)
	          SELECT @w_monto_hijo_des = @w_monto_hijo - @w_monto_acum_des
	          
	    END
	    
	    -- Registro forma de desembolso del préstamo hijo   
	    exec @w_error = sp_borrar_tmp
	        @s_sesn   = @s_ssn,
	        @s_user   = @s_user,
	        @s_term   = @s_term,
	        @i_banco  = @w_banco_hijo
	       
	    if @w_error <> 0  goto ERROR
	    
	    exec @w_error          = sp_pasotmp
	         @s_user            = @s_user,
	         @s_term            = @s_term,
	         @i_banco           = @w_banco_hijo,
	         @i_operacionca     = 'S',
	         @i_dividendo       = 'S',
	         @i_amortizacion    = 'S',
	         @i_cuota_adicional = 'S',
	         @i_rubro_op        = 'S',
	         @i_relacion_ptmo   = 'S',
	         @i_nomina          = 'S',
	         @i_acciones        = 'S',
	         @i_valores         = 'S'
	    
	    if @w_error <> 0  goto ERROR
	      
	    exec @w_error         = sp_desembolso
	         @s_ofi            = @s_ofi,
	         @s_term           = @s_term,
	         @s_user           = @s_user,
	         @s_date           = @w_fecha_liq_hijo,
	         @i_secuencial     = @w_sec_des,
	         @i_nom_producto   = 'CCA',
	         @i_producto       = @w_forma_pago,
	         @i_beneficiario   = @w_beneficiario_h,
	         @i_ente_benef     = @w_cliente_h,
	         @i_oficina_chg    = 1,
	         @i_banco_ficticio = @w_operacion_hijo,
	         @i_banco_real     = @w_banco_hijo,
	         @i_fecha_liq      = @w_fecha_liq_hijo,
	         @i_monto_ds       = @w_monto_hijo_des,   
	         @i_moneda_ds      = 0,
	         @i_tcotiz_ds      = 'COT',
	         @i_cotiz_ds       = 1.0,
	         @i_cotiz_op       = 1.0,
	         @i_tcotiz_op      = 'COT',
	         @i_moneda_op      = 0,
	         @i_operacion      = 'I',
	         @i_externo        = 'N'
	    
	    if @w_error <> 0  goto ERROR
	    
	    exec @w_error = sp_borrar_tmp
	         @s_sesn   = @s_ssn,
	         @s_user   = @s_user,
	         @s_term   = @s_term,
	         @i_banco  = @w_banco_hijo
	        
	    if @w_error <> 0  goto ERROR
	 	    
	    delete #dm_des_padre 
	       where dm_operacion=@w_operacion_padre
	       AND dm_secuencial = @w_sec_des
	       AND dm_desembolso = @w_num_desembolso 
	       
        set @w_cont_des = (select count(1) from #dm_des_padre)
	
	end
    -- *****
    DROP TABLE #dm_des_padre

    delete #op_hijas where op_operacion=@w_operacion_hijo
    set @w_cont = (select count(1) from #op_hijas)
END

DROP TABLE #op_hijas

return 0

ERROR:

IF OBJECT_ID ('dbo.#op_hijas') IS NOT NULL
	DROP TABLE dbo.#op_hijas

IF OBJECT_ID ('dbo.#dm_des_padre') IS NOT NULL
	DROP TABLE dbo.#dm_des_padre

exec cobis..sp_cerror
@t_debug   = 'N',
@t_file    = null,
@t_from    = @w_sp_name,
@i_num     = @w_error

return @w_error

GO





