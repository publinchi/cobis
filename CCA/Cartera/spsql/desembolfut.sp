/************************************************************************/
/*   Archivo             :       desembolfut.sp                         */
/*   Stored procedure    :       sp_desembolso_futuro                   */
/*   Base de datos       :       cob_cartera                            */
/*   Producto            :       Cartera                                */
/*   Disenado por        :       Adriana Giler                          */
/*   Fecha de escritura  :       25-Marzo-19                            */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBISCORP'                                                        */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBISCORP o su representante.             */
/************************************************************************/
/*                                 PROPOSITO                            */
/*   Este programa genera a la liquidación de desembolsos futuros que   */
/*   estan pendientes de desembolsar                                    */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*  FECHA          AUTOR             RAZON                              */
/*  16-Ene-2020    Luis Ponce        Correccion manejo de errores batch */
/*  24/Jun/2021       KDR               Nuevo parámetro sp_liquid       */
/************************************************************************/
use cob_cartera
go

set ansi_nulls off
go


if exists (select 1 from sysobjects where name = 'sp_desembolso_futuro')
   drop proc sp_desembolso_futuro
go

create proc sp_desembolso_futuro
   @i_param1              datetime    = null
as
declare   
   @s_ssn               int,
   @w_sp_name           varchar(30),
   @w_error             int,
   @w_operacionca       int,
   @w_bancoca           varchar(24),
   @w_oficina           smallint,
   @w_moneda_op         tinyint,
   @w_num_dec_mn        tinyint,
   @w_num_dec_op        tinyint,
   @w_num_dec_ds        tinyint,
   @w_fecha_proceso     datetime,
   @w_descripcion       varchar(60)


-- VARIABLES INICIALES
select   @w_sp_name    = 'sp_desembolso_futuro'

--FECHA PROCESO
select @w_fecha_proceso = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7  

select @w_operacionca = min(dm_operacion)
from ca_desembolso
where dm_fecha = @w_fecha_proceso
and   dm_estado = 'NA'  

SELECT dm_operacion,  dm_oficina, dm_moneda, op_banco
into ##desembolso_futuro
from ca_desembolso, ca_operacion
where dm_fecha = @w_fecha_proceso
and   dm_estado = 'NA'  --No aplicado
and   dm_operacion = op_operacion
and   op_estado != 3


declare cursor_desemb_fut cursor for 
SELECT dm_operacion,  dm_oficina, dm_moneda, op_banco
from ##desembolso_futuro
for read only

OPEN cursor_desemb_fut

FETCH cursor_desemb_fut into @w_operacionca, @w_oficina, @w_moneda_op , @w_bancoca

while @@fetch_status = 0  
begin
    select @s_ssn = 1
    
    exec @s_ssn       = sp_gen_sec
         @i_operacion = @w_operacionca
         
    select @s_ssn = convert(int, convert(varchar,@s_ssn) + convert(varchar,@w_operacionca))
    
    -- DECIMALES DE LA MONEDA DEL DESEMBOLSO 
    exec @w_error = sp_decimales
         @i_moneda       = @w_moneda_op,
         @o_decimales    = @w_num_dec_op out,
         @o_dec_nacional = @w_num_dec_mn out

    if @w_error <> 0
    begin
       select @w_descripcion = 'Error Obteniendo Decimales de la moneda de la operación : ' + @w_bancoca 
       goto ERROR    
    end        
    
    --AGI Se insertan temporales antes de hacer el desembolso
    exec @w_error = cob_cartera..sp_borrar_tmp
         @s_user       = 'usrbatch',
         @s_term       = 'consola',
         @i_desde_cre  = 'N',
         @i_banco      = @w_bancoca
    
    if @w_error <> 0
    begin
       select @w_descripcion = 'Error Eliminando en Temporales la operación : ' + @w_bancoca 
       goto ERROR  
    end
    
    exec @w_error      = cob_cartera..sp_pasotmp
         @s_user            = 'usrbatch',
         @s_term            = 'consola',
         @i_banco           = @w_bancoca,
         @i_operacionca     = 'S',
         @i_dividendo       = 'S',
         @i_amortizacion    = 'S',
         @i_cuota_adicional = 'S',
         @i_rubro_op        = 'S',
         @i_relacion_ptmo   = 'S',
         @i_nomina          = 'S',
         @i_acciones        = 'S',
         @i_valores         = 'S'
    
    if @w_error <> 0
    begin    
        select @w_descripcion = 'Error Pasando a Temporales la operación : ' + @w_bancoca 
        goto ERROR  
    end
    
    --LIQUIDAR DESEMBOLSO
    exec @w_error     = cob_cartera..sp_liquida
    @i_banco_ficticio = @w_operacionca,
    @i_banco_real     = @w_bancoca,
    @i_fecha_liq      = @w_fecha_proceso,
    @s_date           = @w_fecha_proceso,
    @i_futuro         = 'S',
    @s_user           = 'usrbatch',
    @s_term           = 'consola',
    @s_ofi            = @w_oficina,
    @s_ssn            = @s_ssn,
	@i_desde_cartera  = 'N',          -- KDR No es ejecutado desde Cartera[FRONT]
    @i_externo        = 'N'  --LPO TEC Correccion manejo de errores batch, para que no llame al sp_cerror en batch y evitar que el batch se caiga
    
    if @w_error != 0  begin
        select @w_descripcion = 'Error ejecutando sp_liquida por batch insertar LIQUIDACION a la operación : ' + @w_bancoca 
        goto ERROR    
    end
    
    GOTO SIGUIENTEOP
    
    ERROR:
    
      exec sp_errorlog 
      @i_fecha       = @i_param1,
      @i_error       = @w_error,
      @i_usuario     = 'usrbatch',
      @i_tran        = 7999,
      @i_tran_name   = @w_sp_name,
      @i_cuenta      = @w_bancoca,
      @i_descripcion = @w_descripcion, 
      @i_rollback    = 'S'
      
    SIGUIENTEOP:
    
    FETCH cursor_desemb_fut into @w_operacionca, @w_oficina, @w_moneda_op , @w_bancoca       
end
close cursor_desemb_fut
deallocate cursor_desemb_fut

return 0

go
