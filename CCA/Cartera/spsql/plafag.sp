/************************************************************************/
/*      Archivo:                plafag.sp                               */
/*      Stored procedure:       sp_planilla_fag                         */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Fernando Carvajal                       */
/*      Fecha de escritura:     22/Agosto2005                           */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA", representantes exclusivos para el Ecuador de la       */
/*      "NCR CORPORATION".                                              */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/*                              PROPOSITO                               */
/*      Llenar la tabla para el reporte de las planillas Flag           */
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR           RAZON                           */
/*      22/Ago/05       Fdo.Carvajal    Emision Inicial                 */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'vw_planilla_fag')
   drop view vw_planilla_fag
go

create view vw_planilla_fag
as
select df_certificado,
       df_llave_redescuento,
       en_nomlar,
       en_ced_ruc,
       df_pagare,
       df_plazo,
       df_gracia_cap,
       convert(varchar, df_fecha_ini,101) df_fecha_ini,
       df_valor_credito,
       df_porc_cobertura,
       df_valor_garantia,
       df_porc_comision,
       df_valor_comision,
       df_valor_iva,
       df_valor_comision + df_valor_iva dt_total,
       df_oficina,
       codigo_sib
from ca_desembolso_fag_tmp, cobis..cl_ente, cob_credito..cr_corresp_sib
where en_ente = df_cliente
and   tabla = 'T21'
and   codigo = convert(varchar, df_regional)
go

if exists (select 1 from sysobjects where name = 'sp_planilla_fag')
   drop proc sp_planilla_fag
go

create proc sp_planilla_fag (
@s_user         varchar(14),
@s_date         datetime,
@i_fecha_ini    datetime, 
@i_fecha_fin    datetime, 
@i_cto_fag      catalogo = NULL, 
@i_iteraciones  smallint = 100
) as declare 
@w_sp_name      varchar(32),
@w_return       int,
@w_error        int,
@w_cto_fag      catalogo, 
@w_op_ini       int, 
@w_op_fin       int, 
@w_intervalo    int, 
@w_min_op       int, 
@w_cuenta       varchar(64),
@w_rowcount     int

select 
@w_sp_name     = 'sp_planilla_fag', 
@w_cto_fag     = @i_cto_fag

/** PARAMETROS GENERALES **/
if @w_cto_fag is null 
begin
   select @w_cto_fag = pa_char
   from   cobis..cl_parametro
   where  pa_nemonico = 'COMFAG'
   and    pa_producto = 'CCA'
   select @w_rowcount = @@rowcount
   set transaction isolation level read uncommitted
   
   if @w_rowcount = 0
   begin
      select @w_error = 710370
      goto ERROR
   end
end

--- Truncamiento 
truncate table ca_desembolso_fag_tmp

--- Definicion de Rangos de busqueda *
select @w_min_op    = min(op_operacion),
       @w_op_fin    = max(op_operacion)
from   ca_operacion
where  op_estado in (1,2,3,9,4)
and    op_fecha_ini between @i_fecha_ini and @i_fecha_fin
and    op_tipo      in ('C', 'N')

select @w_intervalo =(@w_op_fin - @w_min_op) / (@i_iteraciones - 1)
select @w_op_ini    = @w_op_fin - @w_intervalo 

--declare @w_cont smallint, @w_cant int select @w_cont = 1, @w_cant = 0 --FCP PRUEBA

while @w_op_fin >= @w_min_op
begin 
   --- Insercion 
   SET FORCEPLAN ON
   insert into ca_desembolso_fag_tmp (
   df_llave_redescuento, df_cliente,     df_fecha_ini,      df_oficina,        df_porc_comision, 
   df_pagare,            df_certificado, df_porc_cobertura, df_valor_garantia, df_plazo,               
   df_gracia_cap,        df_regional,    df_valor_credito,  df_valor_comision, df_valor_iva)
   select 
   isnull(op_codigo_externo,''), op_cliente, op_fecha_ini,  op_oficina,        ro_porcentaje,  
   gar = isnull((select re_num_pagare from cob_credito..cr_archivo_redescuento where re_llave_redescuento = O.op_codigo_externo), ''), 
   dct = isnull((select cu_num_dcto              from cob_custodia..cu_custodia where cu_codigo_externo = R.ro_nro_garantia), ''),  
   pcb = isnull((select cu_porcentaje_cobertura  from cob_custodia..cu_custodia where cu_codigo_externo = R.ro_nro_garantia), 0.00), 
   cob = isnull((select cu_valor_actual          from cob_custodia..cu_custodia where cu_codigo_externo = R.ro_nro_garantia), 0.00),
   plz = isnull((( ceiling(((charindex(op_tplazo, 'D') + charindex(op_tipo_amortizacion, 'MANUAL'))/2.00))) * (floor(1.0 * datediff(dd, op_fecha_ini, op_fecha_fin)/30.0))                                                                                             + (1-ceiling(((charindex(op_tplazo, 'D') + charindex(op_tipo_amortizacion, 'MANUAL'))/2.00))) * (floor(1.0 * op_plazo                                          *(select td_factor from ca_tdividendo where td_tdividendo = O.op_tplazo     )/30.0))), 0),
   grk = case
         when op_tipo_amortizacion = 'MANUAL' or op_tplazo = 'D'
              then case
                    when exists(select 1
                                from   ca_amortizacion
                                where  am_operacion = O.op_operacion
                                and    am_dividendo = 1
                                and    am_concepto = 'CAP'
                                and    am_cuota = 0)
                       then isnull(floor(datediff(dd, op_fecha_ini, (select min(di_fecha_ven)
                                                                     from   ca_amortizacion, ca_dividendo
                                                                     where  am_operacion = O.op_operacion
                                                                     and    am_dividendo > 1
                                                                     and    am_concepto = 'CAP'
                                                                     and    am_cuota > 0
                                                                     and    di_operacion = am_operacion
                                                                     and    di_dividendo = am_dividendo))/30.0), 0)
                   else 0
                   end
         else
            case
               when op_gracia_cap = 0 then 0
               else (select floor((O.op_gracia_cap * O.op_periodo_cap + O.op_periodo_cap) * td_factor/30.0)
                     from   ca_tdividendo
                     where  td_tdividendo = O.op_tdividendo)
            end
         end
   ,
   reg = isnull((select of_regional from cobis..cl_oficina where of_oficina = O.op_oficina), 0),
   mon = isnull((select sum(dtr_monto_mn) from ca_det_trn              where dtr_operacion = O.op_operacion and dtr_concepto = 'CAP'       and dtr_codvalor != 10990                                                and dtr_secuencial = (select min(tr_secuencial) from ca_transaccion where tr_banco = O.op_banco and tr_tran = 'DES' and tr_estado != 'RV')), 0.00), 
   com = isnull((select sum(dtr_monto_mn) from ca_det_trn              where dtr_operacion = O.op_operacion and dtr_concepto = @w_cto_fag                                                                           and dtr_secuencial = (select min(tr_secuencial) from ca_transaccion where tr_banco = O.op_banco and tr_tran = 'DES' and tr_estado != 'RV')), 0.00), 
   iva = isnull((select sum(dtr_monto_mn) from ca_det_trn, ca_rubro_op where dtr_operacion = O.op_operacion and dtr_concepto = ro_concepto and ro_operacion = O.op_operacion and ro_concepto_asociado = @w_cto_fag  and dtr_secuencial = (select min(tr_secuencial) from ca_transaccion where tr_banco = O.op_banco and tr_tran = 'DES' and tr_estado != 'RV')), 0.00)
   from  ca_operacion O, ca_rubro_op R --(index ca_rubro_op_1)
   where op_operacion between @w_op_ini and @w_op_fin
   and   op_operacion  = ro_operacion 
   and   op_tipo      in ('C', 'N')
   and   op_fecha_ini between @i_fecha_ini and @i_fecha_fin
   and   op_estado    in (1,2,3,9,4)
   and   ro_concepto   = @w_cto_fag
   order by reg, op_oficina
   
   if @@error != 0
   begin 
      select @w_error = 708189,
             @w_cuenta = convert(varchar, @w_op_ini) + '-' + convert(varchar, @w_op_fin)
      
      exec sp_errorlog 
           @i_fecha     = @s_date,
           @i_error     = @w_error, 
           @i_usuario   = @s_user, 
           @i_tran      = 7667,
           @i_tran_name = @w_sp_name,
           @i_cuenta    = @w_cuenta,
           @i_rollback  = 'N'  
   end
  
   select @w_op_fin = @w_op_ini, 
          @w_op_ini = @w_op_ini - @w_intervalo  
end


return 0

ERROR:
exec sp_errorlog 
@i_fecha     = @s_date,
@i_error     = @w_error, 
@i_usuario   = @s_user, 
@i_tran      = 7667,
@i_tran_name = @w_sp_name,
@i_cuenta    = '',
@i_rollback  = 'N'

return @w_error
go

