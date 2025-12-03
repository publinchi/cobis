/************************************************************************/
/*   Archivo:              liquida_nc_grupal.sp                         */
/*   Stored procedure:     sp_liquida_nc_grupal                         */
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
/*   Liquida los préstamos grupales hijos con forma de pago Nota de     */
/*   crédito a cuenta de ahorros                                        */
/*                                                                      */
/************************************************************************/
/*                            CAMBIOS                                   */
/************************************************************************/
/*   FECHA        AUTOR                    RAZON                        */
/* 24/Jun/2021   Kevin Rodríguez      Version inicial                   */
/* 15/Jun/2022   Juan C. Guzman       Se añade validacion para llamado  */
/*                                    de sp_tran_general                */
/* 04/07/2022    Kevin Rodríguez      Nuevo @i_modo = 'ODP'             */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_liquida_nc_grupal')
   drop proc sp_liquida_nc_grupal
go

create proc sp_liquida_nc_grupal (
@s_ofi                  SMALLINT     = null,
@s_user                 login        = null,
@s_date                 DATETIME     = null,
@s_term                 descripcion  = null,
@s_ssn                  INT          = null,
@s_rol                  smallint     = null,
@s_sesn                 int          = null,
@s_srv                  varchar(30)  = null, 
@i_tramite              INT,                   -- tramite grupal padre
@i_modo                 varchar(12)  = null
)

as declare
@w_sp_name           varchar(30),
@w_error             INT,
@w_msg_error         varchar(132),
@w_fdesliq_ncah      catalogo,
@w_prod_des_hijas    catalogo,
@w_banco_padre       cuenta,
@w_banco_hijo        cuenta,
@w_operacion_padre   INT,
@w_operacion_hijo    INT,
@w_estado_padre      TINYINT,
@w_estado_hijo       TINYINT,
@w_monto_padre       MONEY,
@w_monto_hijo        MONEY,
@w_oficina_padre     smallint,
@w_oficina_hijo      smallint,
@w_tramite_hijo      INT,
@w_est_novigente     smallint,
@w_est_credito       SMALLINT,
@w_est_cancelado     SMALLINT,
@w_cont              int,
@w_desc_modo         varchar(20),
@w_prod_des          varchar(20)


-- VARIABLES DE TRABAJO  
select @w_sp_name  = 'sp_liquida_nc_grupal'


-- OBTENER ESTADOS DE CARTERA
exec @w_error = sp_estados_cca 
@o_est_novigente  = @w_est_novigente out,
@o_est_credito    = @w_est_credito   OUT,
@o_est_cancelado  = @w_est_cancelado out

if @w_error <> 0 GOTO ERROR


-- Datos de la operación Padre
select 
@w_operacion_padre = op_operacion,
@w_banco_padre     = op_banco,
@w_estado_padre    = op_estado,
@w_oficina_padre   = op_oficina
from  ca_operacion
where op_tramite = @i_tramite

if @@rowcount = 0
BEGIN
   select @w_error = 710022 -- No existe la operacion
   goto ERROR  
end

-- Forma desembolso para liquidación con Nota de credito cuenta de ahorros
select @w_fdesliq_ncah = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'LIQNCA' and
       pa_producto = 'CCA'


IF @w_estado_padre NOT IN (@w_est_novigente)
BEGIN
   select @w_error = 710505 -- Error, La Operacion Activa no esta en estado de desembolso (NO VIGENTE)
   goto ERROR   
END

-- Verificar que las op hijas tengan una unica forma de desembolso NCAH-0   
/*SELECT  @w_prod_des_hijas = dm_producto FROM ca_desembolso, cob_credito..cr_tramite_grupal 
    WHERE tg_tramite = (select op_tramite from ca_operacion where op_banco = @w_banco_padre)
    and tg_operacion = dm_operacion
    GROUP BY dm_producto

IF @@ROWCOUNT <> 1
BEGIN
   goto SALIR 
END
ELSE
BEGIN
   IF @w_prod_des_hijas <> @w_fdesliq_ncah
   BEGIN
      goto SALIR 
   END
end*/

-- Liquidación de los préstamos hijos con forma de pago Nota de crédito a cuenta de ahorros (NCAH-0)
set rowcount 100
select ca_operacion.* into #op_hijas FROM ca_operacion, cob_credito..cr_tramite_grupal 
   WHERE tg_tramite = @i_tramite
   AND tg_operacion = op_operacion
   and tg_participa_ciclo = 'S'

if @@rowcount = 0
BEGIN
   select @w_error = 711095 -- Error, la operación padre no tiene operaciones hijas asociadas
   goto ERROR  
end

select @w_cont = count(1) from #op_hijas


while  @w_cont > 0
begin
    
    -- Datos de la operación Hija
    SELECT TOP 1
        @w_banco_hijo     = op_banco,
        @w_operacion_hijo = op_operacion,
        @w_tramite_hijo   = op_tramite,
        @w_estado_hijo    = op_estado,
        @w_oficina_hijo   = op_oficina
    from #op_hijas

    IF @w_estado_hijo NOT IN (@w_est_novigente)
    BEGIN
       select @w_error = 710505
       goto ERROR  
    END
   
   
   if @i_modo = 'LIQNCAH'
   begin
      exec @w_error = sp_desliq_xsell 
      @s_ofi     = @s_ofi,
      @s_user    = @s_user,           
      @s_date    = @s_date,           
      @s_term    = @s_term, 
      @s_ssn     = @s_ssn,   
      @s_rol     = @s_rol,  
      @s_sesn    = @s_sesn, 
      @s_srv     = @s_srv,  
      @t_trn     = 77546,    
      @i_tramite = @w_tramite_hijo,   
      @i_modo    = 'LIQNCAH'
      
      if @w_error <> 0 
      begin
         goto ERROR
      end 
   end
   
   if @i_modo = 'CHEQUES'
   begin
      exec @w_error = sp_desliq_xsell 
      @s_ofi     = @s_ofi,
      @s_user    = @s_user,           
      @s_date    = @s_date,           
      @s_term    = @s_term, 
      @s_ssn     = @s_ssn,   
      @s_rol     = @s_rol,  
      @s_sesn    = @s_sesn, 
      @s_srv     = @s_srv,  
      @t_trn     = 77546,    
      @i_tramite = @w_tramite_hijo,   
      @i_modo    = 'CHEQUES'
      
      if @w_error <> 0 
      begin
         goto ERROR
      end
   end
   
   if @i_modo = 'ODP'
   begin
      exec @w_error = sp_desliq_xsell 
      @s_ofi     = @s_ofi,
      @s_user    = @s_user,           
      @s_date    = @s_date,           
      @s_term    = @s_term, 
      @s_ssn     = @s_ssn,   
      @s_rol     = @s_rol,  
      @s_sesn    = @s_sesn, 
      @s_srv     = @s_srv,  
      @t_trn     = 77546,    
      @i_tramite = @w_tramite_hijo,   
      @i_modo    = 'ODP'
      
      if @w_error <> 0 
      begin
         goto ERROR
      end 
   end
   
    delete #op_hijas where op_operacion=@w_operacion_hijo
    set @w_cont = (select count(1) from #op_hijas)
END

DROP TABLE #op_hijas

-- Cambio de estado del Padre a cancelado
/*update ca_operacion
    set op_estado       = @w_est_cancelado
    where op_operacion  = @w_operacion_padre

if @@error <> 0 
begin
   select @w_error = 705036 -- Error en actualizacion de Estado
   goto ERROR
end*/

SALIR:
return 0

ERROR:

IF OBJECT_ID ('dbo.#op_hijas') IS NOT NULL
   DROP TABLE dbo.#op_hijas

exec cobis..sp_cerror
@t_debug   = 'N',
@t_file    = null,
@t_from    = @w_sp_name,
@i_num     = @w_error

return @w_error
GO

