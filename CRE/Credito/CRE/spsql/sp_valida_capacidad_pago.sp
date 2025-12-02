/************************************************************************/
/*  Archivo:                sp_valida_capacidad_pago.sp                 */
/*  Stored procedure:       sp_valida_capacidad_pago                    */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Crédito                                     */
/*  Disenado por:           Patricio Mora                               */
/*  Fecha de Documentacion: 20/Ago/2021                                 */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP.                                                          */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante.              */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  Verificar la capacidad de pago del cliente bajo una línea de        */ 
/*  crédito.                                                            */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*     FECHA        AUTOR            RAZON                              */
/*  20/08/2021      pmora        Emision Inicial                        */
/************************************************************************/
use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_valida_capacidad_pago')
    drop proc sp_valida_capacidad_pago
go

create procedure sp_valida_capacidad_pago
(
       @s_ssn                    int         = null,
       @s_user                   varchar(30) = null,
       @s_sesn                   int         = null,
       @s_term                   varchar(30) = null,
       @s_date                   datetime    = null,
       @s_srv                    varchar(30) = null,
       @s_lsrv                   varchar(30) = null,
       @s_rol                    smallint    = null,
       @s_ofi                    smallint    = null,
       @s_org_err                char(1)     = null,
       @s_error                  int         = null,
       @s_sev                    tinyint     = null,
       @s_msg                    descripcion = null,
       @s_org                    char(1)     = null,
       @t_rty                    char(1)     = null,
       @t_trn                    int         = null,
       @t_debug                  char(1)     = 'N',
       @t_file                   varchar(14) = null,
       @t_from                   varchar(30) = null,
       @i_canal                  tinyint     = 0,   -- Canal: 0=Fronend  1=Batch   2=Workflow
       @i_fecha_inicio           datetime    = null,
       @i_linea_credito          cuenta,
       @i_cliente                int,
       @i_tramite                int
)
as
declare
       @w_param_cap_pago         int,
       @w_tr_linea               int,
       @w_moneda_linea           int,
       @w_capacidad_pago         money,
       @w_operacion              int,              
       @w_moneda_op              int, 
       @w_cuota                  money, 
       @w_tdividendo             varchar(10),
       @w_cuota_resultado        money,
       @w_factor                 float,
       @w_valor_comparar         money,
       @w_cuota_actual           money,
       @w_error                  int,
       @w_sp_name                varchar(32)                 

select @w_sp_name = 'sp_valida_capacidad_pago'

select @w_param_cap_pago = pa_int
  from cobis..cl_parametro
 where pa_nemonico = 'CAPAG'

select @w_tr_linea = li_tramite 
  from cob_credito..cr_linea 
 where li_num_banco = @i_linea_credito

select @w_capacidad_pago = fpv_value
  from cob_fpm..fp_fieldsbyproductvalues
 where dc_fields_idfk  = @w_param_cap_pago
   and fpv_request     = @w_tr_linea

select @w_moneda_linea = li_moneda
  from cob_credito..cr_linea 
 where li_num_banco = @i_linea_credito

select @i_cliente = isnull(@i_cliente,0)

declare cur_operaciones cursor for
 select op_operacion, op_moneda, op_cuota, op_tdividendo
   from cob_cartera..ca_operacion
  where op_cliente = @i_cliente
    and op_estado not in (99,0,3,6) 
  union
 select op_operacion, op_moneda, op_cuota, op_tdividendo
   from cob_cartera..ca_operacion
  where op_tramite = @i_tramite
    
select @w_cuota_resultado = 0.0
select @w_valor_comparar = 0.0

open cur_operaciones
fetch next from cur_operaciones 
into @w_operacion, @w_moneda_op, @w_cuota, @w_tdividendo

while (@@fetch_status = 0)
begin
   if @w_moneda_linea <> @w_moneda_op
    begin 
       exec cob_credito..sp_conversion_moneda
           @s_date                = @i_fecha_inicio,
           @i_fecha_proceso       = @i_fecha_inicio,
           @i_moneda_monto        = @w_moneda_op,           -- moneda las cuotas
           @i_moneda_resultado    = @w_moneda_linea,        -- moneda de la linea
           @i_monto               = @w_cuota,               -- monto entrada
           @o_monto_resultado     = @w_cuota_resultado out, -- resultado de la conversion
           @o_monto_mn_resul      = null    
    end
   else
    begin
         select @w_cuota_resultado = @w_cuota
    end    
         
    if @w_tdividendo <> 'M'
     begin 
      select @w_factor = td_factor 
        from cob_cartera..ca_tdividendo
       where td_tdividendo = @w_tdividendo

      select @w_factor = @w_factor / 30 
      select @w_cuota_resultado = @w_cuota_resultado / @w_factor
     end
    else
     begin
      select @w_cuota_resultado = @w_cuota
     end
    
    select @w_valor_comparar = @w_valor_comparar + @w_cuota_resultado
    
    fetch next from cur_operaciones
    into @w_operacion, @w_moneda_op, @w_cuota, @w_tdividendo
end
close cur_operaciones
deallocate cur_operaciones

if @w_capacidad_pago < @w_valor_comparar
 begin
       select @w_error = 2110124
       goto ERROR
 end

return 0

ERROR:
   --Devolver mensaje de Error
   if @i_canal in (0,1) --Frontend o batch
     begin
      exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file,
           @t_from  = @w_sp_name,
           @i_num   = @w_error
      return @w_error
     end
   else
      return @w_error

go
