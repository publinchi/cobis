/************************************************************************/
/*   Archivo:             reptblambcsi.sp                               */
/*   Stored procedure:    sp_reporte_tamortizacion                      */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        Walther Toledo Qu.                            */
/*   Fecha de escritura:  30/Agosto/2019                                */
/************************************************************************/
/*                           IMPORTANTE                                 */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Consulta para los Reporte Tabla de amortizacion BC SI y BC 52      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*   FECHA           AUTOR          RAZON                               */
/*   30/Agosto/2019  WTO            Emision Inicial                     */
/*   26/Sept/2019    PQU            Correcciones                        */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_reporte_tamortizacion ')
   drop proc sp_reporte_tamortizacion 
go

create proc sp_reporte_tamortizacion  (
   @s_ssn               int         = null,
   @s_date              datetime    = null,
   @s_user              varchar(14)       = null,
   @s_term              varchar(64) = null,
   @s_corr              char(1)     = null,
   @s_ssn_corr          int         = null,
   @s_ofi               smallint    = null,
   @t_show_version      bit         = 0,
   @t_rty               char(1)     = null,
   @t_debug             char(1)     = 'N',
   @t_file              varchar(14) = null,
   @t_trn               int    = null,
   @i_operacion         char(1)     = null,
   @i_banco             varchar(24)      = null,
   @i_nemonico          varchar(10)     = null,
   @i_formato_fecha     int         = null
)as
declare
   @w_sp_name           varchar(24),
   @w_op_banco         varchar(24),
   @w_cliente           int,
   @w_paytel            money,
   @w_walmar            money,
   @w_tipo_oper         catalogo,
   @w_monto_cred        money,
   @w_gasto_apert       money,
   @w_monto_bruto       money,
   @w_tasa              float,
   @w_fecha             varchar(10),
   @w_plazo             smallint,
   @w_periodo           varchar(64),
   @w_nom_cli           varchar(64),
   @w_direcc            varchar(254),
   @w_colonia           varchar(64),
   @w_ciudad            varchar(64),
   @w_delegacion        varchar(64),
   @w_estado            varchar(64),
   @w_nom_presi         varchar(96),
   @w_nom_secre         varchar(96),
   @w_nom_tesor         varchar(96),
   @w_num_reca          varchar(60),
   --
   @w_error             int,
   @w_return            int,
   @w_grupo             int,
   @w_id_rubro          varchar(64),
   @w_operacion         int,
   @w_por_rubro         money,
   @w_referencial       catalogo,
   @w_tplazo            catalogo,
   @w_id_dir            tinyint,
   @w_tot_pagar         money,
   @w_tot_depo          money,
   @w_id_moneda         tinyint,
   @w_simb_moneda       varchar(10),
   @w_msg               varchar(1000),
   @w_concepto_int      catalogo,
   @w_concepto_cap      catalogo,
   @w_concepto_iva      catalogo


select @w_sp_name = 'sp_reporte_tamortizacion'

--Versionamiento del Programa
if @t_show_version = 1
begin
  print 'Stored Procedure=' + @w_sp_name + ' Version=' + '1.0.0.0'
  return 0
end

if @t_trn <> 77534
begin        
   select @w_error = 151023
   goto ERROR
end

select @w_id_rubro = pa_char 
from cobis..cl_parametro 
where pa_producto = 'CCA' 
and pa_nemonico = 'RUGAAP'

select @w_concepto_int = pa_char 
from cobis..cl_parametro 
where pa_producto = 'CCA' 
and pa_nemonico = 'INT'

select @w_concepto_cap = pa_char 
from cobis..cl_parametro 
where pa_producto = 'CCA' 
and pa_nemonico = 'CAP'

select @w_concepto_iva = pa_char 
from cobis..cl_parametro 
where pa_producto = 'CCA' 
and pa_nemonico = 'RUIGCO'

select @w_operacion = op_operacion,
       @w_grupo = op_grupo,
       @w_fecha = convert(varchar,op_fecha_ini,103),
       @w_tipo_oper = op_toperacion,
       @w_plazo = op_plazo,
       @w_tplazo = op_tplazo,
       @w_nom_cli = op_nombre,
       @w_id_moneda = op_moneda
from ca_operacion
where op_banco = @i_banco
if @@rowcount = 0
begin
   select @w_error = 710022,
          @w_msg = 'No existe operacion: ' + @i_banco
   goto ERROR
end

select @w_simb_moneda = mo_simbolo
from cobis..cl_moneda 
where mo_moneda = @w_id_moneda
if @@rowcount = 0
begin
   select @w_error = 101045,
          @w_msg = 'No se ha configurado moneda: ' + @w_id_moneda
   goto ERROR
end
   
if @i_operacion = 'C'
begin
   select @w_op_banco = @i_banco

   select top 1 @w_num_reca = id_dato
   from cob_credito..cr_imp_documento 
   WHERE id_toperacion LIKE @w_tipo_oper
   AND id_mnemonico IN ('TBLAMTBCSI', 'TBLAMTBC52')

   select @w_periodo = td_descripcion
   from ca_tdividendo
   where td_tdividendo = @w_tplazo

/* PQU
   select @w_por_rubro = ro_valor
   from ca_rubro_op , ca_rubro
   where ru_concepto = ro_concepto 
   and ru_referencial = ro_referencial
   and ru_toperacion  = @w_tipo_oper
   and ro_concepto    = @w_id_rubro
   and ro_referencial = @w_referencial
   and ro_operacion   = @w_operacion*/
   
  select @w_gasto_apert = sum(am_cuota)
   from   ca_amortizacion 
   where  am_operacion = @w_operacion
     and  am_concepto = @w_id_rubro
	 
   select @w_gasto_apert = isnull(@w_gasto_apert,0)

   select @w_monto_cred = op_monto,
          @w_monto_bruto = op_monto + @w_gasto_apert
   from ca_operacion
   where op_operacion = @w_operacion

   --fin PQU
   
   
   select @w_cliente = en_ente,
          @w_nom_presi = isnull(en_nombre + ' ','') + isnull(p_p_apellido + ' ','') + isnull(p_s_apellido + ' ','')
   from cobis..cl_ente, cobis..cl_cliente_grupo
   where en_ente = cg_ente
   and cg_rol = 'P'
   and cg_grupo = @w_grupo
   
   select @w_nom_secre = isnull(en_nombre + ' ','') + isnull(p_p_apellido + ' ','') + isnull(p_s_apellido + ' ','')
   from cobis..cl_ente, cobis..cl_cliente_grupo
   where en_ente = cg_ente
   and cg_rol = 'S'
   and cg_grupo = @w_grupo
   
   select @w_nom_secre = isnull(en_nombre + ' ','') + isnull(p_p_apellido + ' ','') + isnull(p_s_apellido + ' ','')
   from cobis..cl_ente, cobis..cl_cliente_grupo
   where en_ente = cg_ente
   and cg_rol = 'T'
   and cg_grupo = @w_grupo
   
   select @w_direcc = di_descripcion,          @w_colonia = pq_descripcion,
          @w_ciudad = ci_descripcion,          @w_estado = pv_descripcion
   from cobis..cl_direccion left join cobis..cl_parroquia on di_parroquia = pq_parroquia
   left join cobis..cl_ciudad on di_ciudad = ci_ciudad
   left join cobis..cl_provincia on di_provincia = pv_provincia
   where di_ente = @w_cliente
   and di_principal = 'S'

   select @w_tasa = ro_porcentaje
   from ca_rubro_op
   where ro_operacion  = @w_operacion
   and   ro_concepto   = @w_concepto_int

   select @w_tot_pagar = sum(am_cuota)
   from ca_amortizacion, ca_dividendo
   where  di_operacion = am_operacion
   and    di_dividendo = am_dividendo
   and di_operacion = @w_operacion
   
   select @w_tot_depo = 0

   select   
      @w_op_banco  ,    @w_cliente    ,   @w_paytel     ,   @w_walmar     ,   @w_tipo_oper  ,
      @w_monto_cred,    @w_gasto_apert ,  @w_monto_bruto,   @w_tasa       ,   @w_fecha,
      @w_plazo      ,   @w_periodo    ,   @w_nom_cli    ,   @w_direcc     ,   @w_colonia    ,
      @w_ciudad     ,   @w_delegacion ,   @w_estado     ,   @w_nom_presi  ,   @w_nom_secre  ,
      @w_nom_tesor  ,   @w_num_reca    ,  @w_tot_pagar  ,   @w_tot_depo   ,   @w_simb_moneda

end


if @i_operacion = 'D'
begin

   select @w_monto_cred = op_monto
   from ca_operacion
   where op_operacion = @w_operacion

   -- (1)DIVIDENDO, (2)FECHA INI, (3)FECHA VENC, (4)CUOTA
   select da_operacion = di_operacion, da_dividendo = di_dividendo,
   da_fecha_ini = di_fecha_ini, da_fecha_ven = di_fecha_ven, da_cuota = sum(am_cuota)
   into #divs_amort
   from ca_amortizacion, ca_dividendo
   where  di_operacion = am_operacion
   and    di_dividendo = am_dividendo
   and    di_operacion = @w_operacion
   group by di_operacion, di_dividendo, di_fecha_ini, di_fecha_ven

   -- (5)CAPITAL,(8)SALDO CAPITAL
   select dc_operacion = am_operacion, dc_dividendo = am_dividendo, dc_cap_liquida = sum(am_cuota),
   dc_saldo_cap=@w_monto_cred --PQU sum(isnull(am_cuota,0)-isnull(am_pagado,0)+isnull(am_gracia,0))
   into #divs_capital
   from ca_amortizacion
   where am_operacion = @w_operacion
   and   am_concepto = @w_concepto_cap --PQU
   group by am_operacion, am_dividendo
   
   --PQU Actualizar el saldo de capital
   update #divs_capital 
   set    dc_saldo_cap = dc_saldo_cap - ( select sum(c.dc_cap_liquida)
                          from   ca_operacion b, #divs_capital c
						  where  b.op_operacion = c.dc_operacion and
						         c.dc_dividendo <= #divs_capital.dc_dividendo)
   

   -- (6)COMISION GASTOS DE CONTRATA
   select  dg_operacion = am_operacion, dg_dividendo = am_dividendo, dg_gast_comi = sum(am_cuota)
   into #divs_gastos_comi
   from ca_amortizacion   
   where am_operacion = @w_operacion
   and   am_concepto = @w_id_rubro
   group by am_operacion, am_dividendo
   
   -- (7)IVA
   select  dv_operacion = am_operacion, dv_dividendo = am_dividendo, dv_iva_liquida = sum(am_cuota)
   into  #divs_iva
   from ca_amortizacion   
   where am_operacion = @w_operacion
   and   am_concepto = @w_concepto_iva
   group by am_operacion, am_dividendo
   
   
   if @w_tipo_oper = 'B52COMUNAL'
   begin
      update #divs_iva set dv_iva_liquida = null
   end

   select
      da_dividendo, 
      convert(varchar,da_fecha_ini,103) da_fecha_in, 
      convert(varchar,da_fecha_ven,103) da_fecha_in, 
      da_cuota, 
      dc_cap_liquida, 
      dg_gast_comi, 
      dv_iva_liquida, 
      dc_saldo_cap,
      @w_simb_moneda dc_simb_moneda
   from #divs_amort, #divs_capital, #divs_gastos_comi, #divs_iva
   where da_operacion = dc_operacion
   and dc_operacion = dg_operacion
   and dg_operacion = dv_operacion
   and da_dividendo = dc_dividendo
   and dc_dividendo = dg_dividendo
   and dg_dividendo = dv_dividendo
   and da_operacion = @w_operacion

end


return 0

ERROR:
exec @w_return = cobis..sp_cerror
@t_debug  = @t_debug,
@t_file   = @t_file,
@t_from   = @w_sp_name,
@i_num    = @w_error,
@i_msg    = @w_msg

return @w_error


go
