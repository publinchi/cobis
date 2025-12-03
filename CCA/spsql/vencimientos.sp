/************************************************************************/
/*      NOMBRE LOGICO:          vencimientos.sp                         */
/*      NOMBRE FISICO:          sp_vencimientos                         */
/*      BasE DE DATOS:          cob_cartera                             */
/*      PRODUCTO:               Cartera                                 */
/*      DISENADO POR:           Kevin Rodríguez                         */
/*      FECHA DE ESCRITURA:     Junio 2023                              */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada; y por lo tanto, derivará en acciones legales civiles      */
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/
/*              PROPOSITO                                               */
/*  Consulta de cuotas no pagadas hasta el día actual                   */
/*                                                                      */
/************************************************************************/
/*                          MODIFICACIONES                              */
/*  FECHA          AUTOR          RAZON                                 */
/*  13/Jun/2023    K. Rodríguez   Emisión inicial                       */
/*  04/Jul/2023    K. Rodríguez   S857600 Rep.Operaciones con Cap impago*/
/*  15/Nov/2023    E. Medina      R219361 No Castigadas en Riesgo y Mor.*/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_vencimientos')
    drop proc sp_vencimientos
go

create proc sp_vencimientos (
@s_user             varchar(14)  = null,
@s_date             datetime     = null,
@s_ofi              smallint     = null,
@s_term             varchar (30) = null,
@t_timeout          int          = null,
@i_operacion        char(1)      = 'H',
@i_oficina          smallint,
@i_oficial          smallint,
@i_tipo_cli_grp     char(1)      = null,  -- C: Cliente, G: Grupo
@i_cod_cli_grp      int          = null, -- id de cliente o grupo
@i_en_linea         char(1)      = 'S'
)
as

declare
@w_sp_name       varchar(32),
@w_error         int,
@w_est_novigente tinyint,
@w_est_vigente   tinyint,
@w_est_cancelado tinyint,
@w_est_castigado tinyint,
@w_est_vencido   tinyint,
@w_est_credito   tinyint,
@w_est_anulado   tinyint,
@w_fecha_limite  datetime,
@w_grupo         varchar(160),
@w_nom_oficial   varchar(64),
@w_cap           money,
@w_int           money,
@w_otros         money,
@w_oficina_desc  varchar(160),
@w_tot_hoy       money,
@w_dividendo     smallint,
@w_cliente_in    int,
@w_grupo_in      int,
@w_dias_mora     smallint,
@w_max_fecha_ven datetime

-- Variables iniciales
select @w_sp_name = 'sp_vencimientos'

-- ESTADOS DE CARTERA
exec @w_error = sp_estados_cca
@o_est_novigente  = @w_est_novigente out,
@o_est_vigente    = @w_est_vigente   out,
@o_est_cancelado  = @w_est_cancelado out,
@o_est_castigado  = @w_est_castigado out,
@o_est_vencido    = @w_est_vencido   out,
@o_est_anulado    = @w_est_anulado   out,
@o_est_credito    = @w_est_credito   out

if @@error <> 0
begin
    set @w_error = 710251 -- Error en consulta de tabla cob_cartera..ca_estado
    goto ERROR
end

select @w_fecha_limite = fp_fecha 
from cobis..ba_fecha_proceso

if @i_operacion = 'H' -- Vencimientos Hoy
begin

   if object_id('tempdb..#ops_cuotas_no_pag') is not null
      drop table #ops_cuotas_no_pag
	  
   if @i_tipo_cli_grp = 'C' -- Cliente
      select @w_cliente_in = @i_cod_cli_grp,
             @w_grupo_in   = null
			 
   if @i_tipo_cli_grp = 'G' -- Cliente
      select @w_grupo_in   = @i_cod_cli_grp,
             @w_cliente_in = null
	  
   -- Universo de operaciones      
   select op_oficial     as 'oficial',
          @w_nom_oficial as 'nom_oficial',
          op_cliente     as 'cliente',
          op_nombre      as 'nom_cli',
          op_grupo       as 'grupo',
          @w_grupo       as 'nom_grupo', 
          op_toperacion  as 'toperacion', 
          op_operacion   as 'operacion',
          op_tipo_cobro  as 'tipo_cobro',
          di_dividendo   as 'dividendo',
		  op_monto       as 'monto',
          op_cuota       as 'cuota',
          @w_cap         as 'saldo_cap', 
          @w_int         as 'saldo_int', 
          @w_otros       as 'saldo_otros', 
          @w_tot_hoy     as 'total_dia' 
   into #ops_cuotas_no_pag
   from ca_operacion with (nolock), ca_dividendo with (nolock)
   where op_estado in (@w_est_vigente, @w_est_vencido)
   and (op_grupal = 'N' 
       or (op_grupal = 'S' and op_ref_grupal is not null))
   and op_operacion = di_operacion
   and (op_grupo = @w_grupo_in or @w_grupo_in is null) 
   and ((op_cliente = @w_cliente_in and op_grupal <> 'S') or @w_cliente_in is null)
   and di_fecha_ven = @w_fecha_limite
   and di_estado <> @w_est_cancelado
   and op_oficina = @i_oficina
   and op_oficial = @i_oficial

   -- Actualización de descripción de grupo
   update #ops_cuotas_no_pag 
   set nom_grupo = gr_nombre
   from cobis..cl_grupo
   where gr_grupo = grupo
   and grupo > 0

   -- Actualización de nombre del oficial 
   update #ops_cuotas_no_pag 
   set nom_oficial = fu_nombre,
       nom_cli     = '*'+nom_cli
   from cobis..cc_oficial, cobis..cl_funcionario
   where oc_funcionario = fu_funcionario
   and oc_oficial = oficial
   
   -- Saldo Capital
   update #ops_cuotas_no_pag 
   set saldo_cap = (select isnull(sum(am_acumulado + am_gracia - am_pagado), 0) 
                    from ca_amortizacion with (nolock), ca_concepto
                    where am_operacion = operacion 
                    and am_dividendo = dividendo 
                    and am_concepto = co_concepto
                    and co_categoria = 'C')

   -- Saldo Interés
   update #ops_cuotas_no_pag 
   set saldo_int = (select isnull(sum(am_acumulado + am_gracia - am_pagado), 0) 
                    from ca_amortizacion with (nolock), ca_concepto
                    where am_operacion = operacion 
                    and am_dividendo = dividendo 
                    and am_concepto = co_concepto
                    and co_categoria = 'I')  
   
   -- Saldo Otros
   update #ops_cuotas_no_pag 
   set saldo_otros = (select isnull(sum(am_acumulado + am_gracia - am_pagado), 0) 
                      from ca_amortizacion with (nolock), ca_concepto
                      where am_operacion = operacion 
                      and am_dividendo = dividendo 
                      and am_concepto = co_concepto
                      and co_categoria not in ('C','I','M'))
   
   -- Total Día
   update #ops_cuotas_no_pag 
   set total_dia = saldo_cap + saldo_int + saldo_otros
   
   -- Descripción de oficina
   select @w_oficina_desc = of_nombre 
   from cobis..cl_oficina 
   where of_oficina = @i_oficina
   
   if object_id('tempdb..#vencimientos_hoy') is not null
      drop table #vencimientos_hoy
	  
   create table #vencimientos_hoy(
   asesor_id       smallint     null,
   asesor          varchar(64)  null,
   cli_grp_id      int          null,
   cli_gr_nom      varchar(160) null,
   tipo_operacion  varchar(10)  null,
   total_prestamos smallint     null,
   monto_otorgado  money        null,  
   cuota           money        null,
   capital         money        null,
   interes         money        null,
   otros           money        null,
   total_hoy       money        null)
	
   insert into #vencimientos_hoy
   select oficial,      nom_oficial,  cliente,         nom_cli,         toperacion,        count(1),
          sum (monto),  sum(cuota),   sum(saldo_cap),  sum(saldo_int),  sum(saldo_otros),  sum(total_dia) 
   from #ops_cuotas_no_pag 
   where grupo in(null,0)
   group by oficial, nom_oficial, cliente, nom_cli, toperacion
   union
   select oficial,      nom_oficial,  grupo,           nom_grupo,       toperacion,        count(1), 
          sum (monto),  sum(cuota),   sum(saldo_cap),  sum(saldo_int),  sum(saldo_otros),  sum(total_dia) 
   from #ops_cuotas_no_pag 
   where grupo > 0
   group by oficial, nom_oficial, grupo, nom_grupo, toperacion


   select 
   'COD_OFI'        = @i_oficina,
   'OFICINA'        = @w_oficina_desc,
   'FECHA_LIMITE'   = substring(convert(varchar, isnull(@w_fecha_limite, '01/01/1900'), 103),1,15),
   'HORA_ACTUAL'    = substring(convert(varchar,getdate(),22), 10, 11)
   
   if not exists(select 1 from #vencimientos_hoy)
      insert into #vencimientos_hoy values (0,'NO SE ENCONTRARON DATOS',0,'N/A','N/A',0,0.0,0.0,0.0,0.0,0.0,0.0)
      
   select
   'COD_asESOR'      = asesor_id,     
   'NOMBRE_asESOR'   = asesor,     
   'COD_CLI_GRP'     = cli_grp_id,
   'CLI_GRP_NOM'     = cli_gr_nom,
   'TIPO_OPERACION'  = tipo_operacion,
   'TOTAL_OPERACION' = total_prestamos,
   'MONTO_OTORGADO'  = monto_otorgado,
   'CUOTA'           = cuota,
   'CAPITAL'         = capital,
   'INTERES'         = interes,
   'OTROS'           = otros,
   'TOTAL_HOY'       = total_hoy      
    from #vencimientos_hoy
	order by asesor_id, cli_grp_id, tipo_operacion

   if object_id('tempdb..#ops_cuotas_no_pag') is not null
      drop table #ops_cuotas_no_pag
	  
   if object_id('tempdb..#vencimientos_hoy') is not null
      drop table #vencimientos_hoy
    
end

if @i_operacion = 'R' -- Riesgo y Mora (Capital impago en dividendos vencidos)
begin

   if object_id('tempdb..##ops_cuotas_cap_impago_cab') is not null
      drop table ##ops_cuotas_cap_impago_cab
	  
   if object_id('tempdb..##ops_cuotas_cap_impago') is not null
      drop table ##ops_cuotas_cap_impago
	  
   if @i_tipo_cli_grp = 'C' -- Cliente
      select @w_cliente_in = @i_cod_cli_grp,
             @w_grupo_in   = null
			 
   if @i_tipo_cli_grp = 'G' -- Cliente
      select @w_grupo_in   = @i_cod_cli_grp,
             @w_cliente_in = null
			 
   -- Descripción de oficina
   select @w_oficina_desc = of_nombre 
   from cobis..cl_oficina 
   where of_oficina = @i_oficina
			 
   select @i_oficina as 'oficina', 
          @w_oficina_desc as 'desc_oficina',
		  isnull(@w_fecha_limite, '01/01/1900') as 'fecha_limite',
		  getdate() as 'fecha_actual'
   into ##ops_cuotas_cap_impago_cab

   -- Universo de operaciones (Que tangan capital impago en cuotas vencidas)      
   select op_operacion     as 'operacion',
          op_oficina       as 'oficina',
		  @w_oficina_desc  as 'desc_oficina',
          op_oficial       as 'oficial',
          @w_nom_oficial   as 'nom_oficial',
		  op_toperacion    as 'toperacion',
		  op_grupo         as 'grupo',	  
          op_cliente       as 'cliente',
          op_nombre        as 'nom_cli',
		  op_fecha_ini     as 'fecha_ini',
		  op_fecha_fin     as 'fecha_ven',
          op_monto         as 'monto',
          @w_cap           as 'saldo_cap', 
          @w_int           as 'valor_riesgo', 
          @w_otros         as 'valor_mora', 
          @w_max_fecha_ven as 'max_ven',
		  @w_dias_mora     as 'dias_mora'
   into ##ops_cuotas_cap_impago
   from ca_operacion with (nolock), ca_dividendo with (nolock), ca_amortizacion, ca_concepto
   where op_estado not in (@w_est_novigente, @w_est_cancelado, @w_est_castigado, @w_est_credito, @w_est_anulado)
   and (op_grupal = 'N' 
       or (op_grupal = 'S' and op_ref_grupal is not null))
   and op_operacion = di_operacion
   and op_operacion = am_operacion
   and (op_grupo = @w_grupo_in or @w_grupo_in is null) 
   and (op_cliente = @w_cliente_in or @w_cliente_in is null)
   and di_fecha_ven < @w_fecha_limite
   and di_estado = @w_est_vencido
   and am_dividendo = di_dividendo
   and am_pagado < am_acumulado
   and am_concepto  = co_concepto
   and co_categoria = 'C'
   and (op_oficina = @i_oficina or @i_oficina is null) 
   and (op_oficial = @i_oficial or @i_oficial is null)
   group by op_operacion, op_oficina, op_oficial, op_toperacion, op_grupo, op_cliente, op_nombre, op_fecha_ini, op_fecha_fin, op_monto
   
   -- Actualización de nombre del oficial 
   update ##ops_cuotas_cap_impago 
   set nom_oficial = fu_nombre
   from cobis..cc_oficial, cobis..cl_funcionario
   where oc_funcionario = fu_funcionario
   and oc_oficial = oficial
   
   -- Actualización de descripción de la oficina
   update ##ops_cuotas_cap_impago
   set desc_oficina = of_nombre
   from cobis..cl_oficina
   where of_oficina = oficina
   
   -- Actualización cuota más vencida y días mora.
   update ##ops_cuotas_cap_impago
   set max_ven   = d.fecha_ven_min,
       dias_mora = d.mora_dias
   from (select di_operacion as operac, 
                min(di_fecha_ven) as fecha_ven_min, 
				datediff(dd, min(di_fecha_ven), @w_fecha_limite) as mora_dias 
         from ca_dividendo 
		 where di_estado = @w_est_vencido 
		 group by di_operacion) d  
   where d.operac = operacion
   
   -- Actualización de Saldo Capital y Valor riesgo
   update ##ops_cuotas_cap_impago
   set saldo_cap    = a.cap_saldo,
       valor_riesgo = a.cap_saldo 
   from (select am_operacion as operac,
                isnull(sum(am_acumulado + am_gracia - am_pagado), 0) as cap_saldo
         from ca_amortizacion with (nolock), ca_concepto
         where am_concepto = co_concepto
         and  co_categoria = 'C'
		 group by am_operacion) a
   where a.operac = operacion
   
   -- Saldo en Mora
   update ##ops_cuotas_cap_impago
   set valor_mora = (select isnull(sum(am_acumulado + am_gracia - am_pagado), 0) 
                      from ca_amortizacion with (nolock), ca_dividendo with (nolock)
                      where am_operacion = operacion
					  and di_operacion   = operacion
					  and am_dividendo   = di_dividendo
					  and di_estado      = @w_est_vencido)
   
end

return 0
	  
ERROR:

if object_id('tempdb..#vencimientos_hoy') is not null
   drop table #vencimientos_hoy
   
if object_id('tempdb..#ops_cuotas_no_pag') is not null
   drop table #ops_cuotas_no_pag
   
if object_id('tempdb..##ops_cuotas_cap_impago') is not null
   drop table ##ops_cuotas_cap_impago
   
if object_id('tempdb..##ops_cuotas_cap_impago_cab') is not null
   drop table ##ops_cuotas_cap_impago_cab

if @i_en_linea = 'S'
   exec cobis..sp_cerror
   @t_debug='N',
   @t_file='',
   @t_from=@w_sp_name,
   @i_num = @w_error
   
return @w_error

go
