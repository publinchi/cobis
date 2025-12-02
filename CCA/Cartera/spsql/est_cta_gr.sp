/***********************************************************************/
/*	Archivo:			est_cta_gr.sp                                  */
/*	Stored procedure:		sp_estado_cta_grupal                       */
/*	Base de Datos:			cob_cartera                                */
/*	Producto:			Cartera	                                       */
/*	Disenado por:			LPO                                        */
/*	Fecha de Documentacion: 	Mar. 05                                */
/***********************************************************************/
/* IMPORTANTE                                                          */
/* Este programa es parte de los paquetes bancarios propiedad de       */
/* COBISCORP S.A.representantes exclusivos para el Ecuador de la       */
/* AT&T                                                                */
/* Su uso no autorizado queda expresamente prohibido asi como          */
/* cualquier autorizacion o agregado hecho por alguno de sus           */
/* usuario sin el debido consentimiento por escrito de la              */
/* Presidencia Ejecutiva de COBISCORP o su representante               */
/***********************************************************************/  
/*			PROPOSITO				                                   */
/*	Mostrar el estado de cuenta del grupo                              */
/***********************************************************************/
use cob_cartera
go
if exists(select * from sysobjects where name = 'sp_estado_cta_grupal')
	drop proc sp_estado_cta_grupal
go
create proc sp_estado_cta_grupal (
@i_banco		cuenta   = null,
@i_opcion               char(1)  = null,
@s_date                 datetime = null
)
as
declare
 	@w_sp_name	    varchar(32),	
	@w_opcion	    int,
        @w_error            int,
        @w_estado           int,
        @w_concepto_segdes  varchar(10),
        @w_concepto_seghos  varchar(10),
        @w_concepto_solca   varchar(10),
        @w_concepto_asisadm varchar(10),
        @w_formato_fecha    int,
        @w_asistencia_adm   money,
        @w_seguro_desgrav   money,
        @w_intxcobrar       money,
        @w_fecha_liq        varchar(10),
        @w_monto_financiado money,
		@w_grupo            int,
        @w_nombre_grupo     varchar(30),
        @w_ciclos           int,
        @w_filial           varchar(30),
        @w_fecha            varchar(10),
        @w_oficina          int,
        @w_nombre_oficina   varchar(30),
        @w_monto_solicitado money,
        @w_tasa             money,
        @w_operacionca      int,
        @w_banco_emisor     varchar(30),
        @w_cuenta           varchar(30),
        @w_total            money,
        @w_fondo                varchar(10),
        @w_nombre_fondo         varchar(25),
        @w_toperacion           varchar(10),
        @w_desc_toperacion      varchar(30),
        @w_dia_reunion          tinyint,
        @w_frecuencia_reunion   smallint,
        @w_hora_reunion         varchar(5),
        @w_lugar_reunion        varchar(64),
        @w_grupal               char(1),
        @w_referencia_grupal    varchar(20),
        @w_tasa_iva             money,
        @w_concepto_asoc        varchar(10),
        @w_solca                money,
        @w_moneda               tinyint,
        @w_asumido              char(1),
        @w_cliente              int,
        @w_ruc_banco            varchar(15),
        @w_garantia             varchar(20),
        @w_nombre               varchar(40),
        @w_banco                varchar(15),
        @w_ced_ruc              varchar(15),
        @w_tramite              int,
        @w_ciudad               int,
        @w_desc_ciudad          varchar(30),
        @w_dd_hoy               tinyint,
        @w_mm_hoy               tinyint,
        @w_yy_hoy               smallint,
        @w_subsegmento          varchar(30),
        @w_sector               varchar(10),
        @w_direccion            varchar(45),
        @w_tir                  money,
        @w_tea                  money,
        @w_fecha_fin            varchar(30),
        @w_tasador              varchar(35),
        @w_p_apellido           varchar(25),
        @w_p_nombre             varchar(25),
        @w_tipo_cta             varchar(10),
        @w_dias_plazo           int,
        @w_desc_dias_plazo      varchar(20),
        @w_plazo                varchar(20),
        @w_periodicidad         varchar(20),
        @w_tasa_mora            money,
        @w_seguro_hospit        money,
        @w_tipo_amortizacion    varchar(10),
        @w_porcentaje_garantia float,
        @w_destino                  varchar(2),
        @w_desc_destino          varchar(64),
        @w_reunion                  varchar(255),
        @w_supervisor              int,
        @w_oficial                    int,
        @w_nombre_oficial        varchar(35),
        @w_est_vigente          tinyint,
        @w_est_novigente        tinyint,
        @w_est_vencido          tinyint,
        @w_est_cancelado        tinyint,
        @w_moneda_op            smallint,
        @w_num_dec              tinyint,
        @w_return               int,
        @w_pagos_exceso         char(1),
        @w_saldo_ini            money,
        @w_migrada              varchar(20),
        @w_pagado_cap           money,
        @w_vencido              money,
        @w_tienevencido         varchar(1),
		@w_abrev_moneda         varchar(10)
        
        
        
        

/*  Captura nombre de Stored Procedure  */
select @w_sp_name = 'sp_estado_cta_grupal',
        @w_formato_fecha = 103,
        @w_est_novigente = 0,
        @w_est_vigente   = 1,
        @w_est_vencido   = 2,
        @w_est_cancelado = 3,
        --@w_titulo        = 'ESTADO DE CUENTA GRUPAL',
        @w_pagos_exceso  = 'N',
        @w_tienevencido  = 'N'
       

   select @w_concepto_segdes = pa_char
     from cobis..cl_parametro
    where pa_producto = 'CCA'
      and pa_nemonico = 'RSDG'

   select @w_concepto_solca = pa_char
     from cobis..cl_parametro
    where pa_producto = 'CCA'
      and pa_nemonico = 'SOLCA'

   select @w_concepto_asisadm = pa_char
     from cobis..cl_parametro
    where pa_producto = 'CCA'
      and pa_nemonico = 'RAAD'

   select @w_concepto_seghos = pa_char
     from cobis..cl_parametro
    where pa_producto = 'CCA'
      and pa_nemonico = 'RSDH'

   select @w_grupal = 'N'

select @w_grupal            = tg_grupal,
       @w_referencia_grupal = tg_referencia_grupal,
       @w_operacionca       = op_operacion,
       @w_toperacion        = op_toperacion,
       @w_moneda            = op_moneda,
       @w_fecha_fin         = convert(varchar(10),op_fecha_fin,103),
       @w_plazo             = convert(varchar(10),p.td_factor*op_plazo) + ' dias',
       @w_periodicidad      = (select substring(td_descripcion,1,25) from ca_tdividendo where td_factor = f.td_factor*o.op_periodo_int),
       @w_destino            = op_destino,
       @w_desc_destino     = ( select valor
                                        from cobis..cl_catalogo a, cobis..cl_tabla b
                                        where a.tabla        = b.codigo
                                           and b.tabla        = 'cr_objeto'
                                           and a.codigo       = o.op_destino),
       @w_oficial               = op_oficial
  from ca_operacion o , ca_tdividendo p, ca_tdividendo f, cob_credito..cr_tramite_grupal
 where op_banco = @i_banco
 --  and op_banco = tg_prestamo  
   and op_banco = tg_referencia_grupal  
   and p.td_tdividendo = op_tplazo
   and f.td_tdividendo = op_tdividendo

if @@rowcount = 0 begin
   exec cobis..sp_cerror
       @t_debug  = 'N',
       @t_file   = null,
       @t_from   = @w_sp_name,   
       @i_num    = 701025
   return 701025
end


-- MANEJO DE DECIMALES 
exec @w_return    = sp_decimales
     @i_moneda    = @w_moneda,
     @o_decimales = @w_num_dec out

if @w_return != 0 begin
   select @w_error = @w_return
   return @w_error
end         


if @i_opcion = 'C' begin
   if @w_grupal = 'S' begin
      select @w_fecha_liq        = convert(varchar(10),op_fecha_liq,@w_formato_fecha),
             @w_monto_financiado = op_monto,
             @w_grupo            = gr_grupo,
             @w_nombre_grupo     = substring(gr_nombre,1,30),
             @w_ciclos           = gr_num_ciclo,
             @w_reunion        = ((select valor
                                        from cobis..cl_catalogo a, cobis..cl_tabla b
                                        where a.tabla        = b.codigo
                                           and b.tabla        = 'ad_dia_semana'
                                           and a.codigo       = gr_dia_reunion) + ' ' + convert(varchar,gr_hora_reunion,108) + ' ' + gr_dir_reunion),             
             @w_filial           = substring(fi_nombre,1,30),
             @w_fecha            = convert(varchar(10),@s_date,@w_formato_fecha),
             @w_oficina          = op_oficina,
             @w_nombre_oficina   = substring(of_nombre,1,30),
             @w_monto_solicitado = op_monto,
             @w_tasa             = round(ro_porcentaje,4),
             @w_operacionca      = op_operacion,
             @w_tipo_amortizacion= op_tipo_amortizacion,
             @w_abrev_moneda     = (select mo_simbolo from cobis..cl_moneda where mo_moneda = OP.op_moneda)
        from ca_operacion OP, cobis..cl_grupo, cobis..cl_filial, cobis..cl_oficina, ca_rubro_op, cob_credito..cr_tramite_grupal
       where op_banco  = @i_banco
         and op_banco  = tg_referencia_grupal --tg_prestamo
         and tg_grupal = 'S'
         and tg_grupo  = gr_grupo
         and fi_filial = 1
         and of_oficina = op_oficina
         and ro_operacion = op_operacion
         and ro_concepto  = 'INT'

      select @w_tasa_mora = ro_porcentaje
        from ca_rubro_op
       where ro_operacion = @w_operacionca
         and ro_concepto  = 'IMO'

      if @w_tasa_mora = 1.1 select @w_tasa_mora = @w_tasa_mora * @w_tasa

      select @w_supervisor        = oc_ofi_nsuperior,
              @w_nombre_oficial    = fu_nombre
     from cobis..cl_funcionario, cobis..cc_oficial
     where oc_oficial = @w_oficial
        and oc_funcionario = fu_funcionario


   end else begin
      select @w_fecha_liq        = convert(varchar(10),op_fecha_liq,@w_formato_fecha),
             @w_monto_financiado = op_monto,
             @w_grupo            = op_cliente,
             @w_nombre_grupo     = substring(op_nombre,1,30),
             @w_ciclos           = en_nro_ciclo,
             @w_filial           = substring(fi_nombre,1,30),
             @w_fecha            = convert(varchar(10),@s_date,@w_formato_fecha),
             @w_oficina          = op_oficina,
             @w_nombre_oficina   = substring(of_nombre,1,30),
             @w_monto_solicitado = op_monto,
             @w_tasa             = round(ro_porcentaje,4),
             @w_operacionca      = op_operacion,
             @w_tipo_amortizacion= op_tipo_amortizacion,
			 @w_abrev_moneda     = (select mo_simbolo from cobis..cl_moneda where mo_moneda = OP.op_moneda)			 
        from ca_operacion OP, cobis..cl_ente, cobis..cl_filial, cobis..cl_oficina, ca_rubro_op
       where op_banco  = @i_banco
         and en_ente   = op_cliente
         and fi_filial = 1
         and of_oficina = op_oficina
         and ro_operacion = op_operacion
         and ro_concepto  = 'INT'

      select @w_tasa_mora = ro_porcentaje
        from ca_rubro_op
       where ro_operacion = @w_operacionca
         and ro_concepto  = 'IMO'

      if @w_tasa_mora = 1.1 select @w_tasa_mora = @w_tasa_mora * @w_tasa

   end


     select @w_grupo,
              @w_nombre_grupo,
              @w_oficina,
              @w_nombre_oficina,
              @w_nombre_oficial,
              @w_destino,            
              @w_desc_destino,
              @w_reunion,
              @w_ciclos,
              @w_monto_financiado,
              @w_plazo,   
              (@w_tasa/100),              
              @w_fecha_liq,   
              @w_fecha_fin,              
              @w_fecha,
              @w_grupal,
              @w_periodicidad,
              @w_tasa_mora,
			  @w_abrev_moneda
             
end

if @i_opcion = 'R'
begin		
   if isnull((select count(1) from cob_credito..cr_tramite_grupal where tg_referencia_grupal = @i_banco),0) = 0
      return 0 	 
	  
      select top 1 @w_operacionca = tg_operacion
      from cob_credito..cr_tramite_grupal, cob_cartera..ca_operacion
      where tg_referencia_grupal = @i_banco 
      and tg_tramite = op_tramite
	  and tg_monto > 0

      create table #tempConcepto_dm(       
          concepto VARCHAR(30),
          vencido  MONEY
      )    
	  -- Vencido
      insert into #tempConcepto_dm
      select am_concepto, 
	         sum(isnull(am_cuota - am_pagado + am_gracia,0))
      from   ca_dividendo, ca_amortizacion am
      where  di_operacion = @w_operacionca
      and    am_operacion = di_operacion
      and    am_dividendo = di_dividendo
      and    di_estado    = 2
      GROUP BY am_concepto,di_dividendo
   
      select am_concepto,
             co_descripcion,
             ro_prioridad,
             round(isnull(sum(am_cuota+am_gracia),0),@w_num_dec),
             round(isnull(sum(am_pagado),0),@w_num_dec),
             round(isnull(sum(am_cuota-am_pagado+am_gracia),0),@w_num_dec),
             (select vencido from #tempConcepto_dm where concepto = a.am_concepto)
        from ca_amortizacion a, ca_concepto, ca_rubro_op, cob_credito..cr_tramite_grupal B
       where tg_referencia_grupal = @i_banco
         and am_operacion = tg_operacion
         and am_concepto  = co_concepto
         and ro_operacion = tg_operacion
         and ro_concepto  = am_concepto
		 and tg_monto > 0
      group by am_concepto, co_descripcion, ro_prioridad
      union
       select ro_concepto, co_descripcion, ro_prioridad, round(isnull(ro_valor,0),@w_num_dec), 0, 0, 0
         from ca_rubro_op, ca_concepto
        where ro_operacion = @w_operacionca
          and ro_fpago    in ('L','F')
          and co_concepto  = ro_concepto
       order by ro_prioridad
end

if @i_opcion = 'D'
begin
  select  'Pago'      = A.di_dividendo,
          'Fecha'     = convert(varchar(10),A.di_fecha_ven,103),--@w_formato_fecha),
          'Capital'   = (select sum(am_cuota) -- Para couta
                           from ca_amortizacion WHERE 
                             am_operacion = @w_operacionca
                            and am_dividendo = A.di_dividendo
                            and am_concepto  = 'CAP'),       
          'Intereses' = (select sum(am_cuota) -- Para couta
                           from ca_amortizacion
                           WHERE am_operacion = @w_operacionca
                            and am_dividendo = A.di_dividendo
                            and am_concepto  = 'INT'),
          'Cargos'    = (select sum(am_cuota) -- Para couta
                           from ca_amortizacion
                           WHERE am_operacion = @w_operacionca
                            and am_dividendo = A.di_dividendo
                            and am_concepto  not in ('CAP','INT')),
          'Saldo_k'   =  CASE A.di_dividendo WHEN 1 THEN O.op_monto
          					ELSE
          					((O.op_monto) - (select sum(am_cuota)
                           from ca_amortizacion
                           WHERE am_operacion = @w_operacionca
                            and am_dividendo <= A.di_dividendo -1
                            and am_concepto  = 'CAP')) end,                            
          'Aho_volunt'=  isnull((select sum(isnull(cp_ahorro,0))
                          from cob_cartera..ca_control_pago
                          WHERE cp_operacion = @w_operacionca
                            and cp_dividendo         = A.di_dividendo),0),
          'Aho_Extra' =  isnull((select sum(isnull(cp_extras,0))
                          from cob_cartera..ca_control_pago
                          WHERE cp_operacion = @w_operacionca
                            and cp_dividendo         = A.di_dividendo),0),                            
		  'Cuota'    = 0 -- Se deja en cero porque ya se suma en el reporte
   from ca_dividendo A, ca_operacion O
   where A.di_operacion = @w_operacionca
     and A.di_operacion = O.op_operacion
   group by A.di_dividendo, A.di_fecha_ven, O.op_monto
   order by A.di_dividendo
end

return 0
go
