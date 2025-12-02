/************************************************************************/
/*      Archivo:                conabocuo.sp                            */
/*      Stored procedure:       sp_consulta_abonos_cuota                */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Juan B. Quinche                         */
/*      Fecha de escritura:     Mayo 2008                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.	                                                */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Presenta la relacion de pagos y su afectacion por cuotas        */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_consulta_abonos_cuota')
   drop proc sp_consulta_abonos_cuota
go

create proc sp_consulta_abonos_cuota
    @s_user           login     = null,
    @t_trn            smallint  = null,
    @i_formato_fecha  int       = 103,
    @t_debug          char(1)   = 'N',
    @i_banco          cuenta    = null,
    @i_operacion      char(1)   = null,
    @i_reg_ini        int       = 0

as

declare @w_sp_name            varchar(32),
        @w_return             int,
        @w_error              int,
        @w_operacionca        int,
        @w_banco              cuenta,
        @w_tramite            int,
        @w_tipo               char(1),
        @w_tipo_amortizacion  catalogo,
        @w_dias_div           int,
        @w_tdividendo         catalogo,
        @w_fecha_ult_proceso  datetime,
        @w_toperacion         catalogo,
        @w_moneda             int,
        @w_dias_anio          int,
        @w_sector             catalogo,
        @w_oficina            int,
        @w_fecha_liq          datetime,
        @w_fecha_ini          datetime,
        @w_clausula           catalogo,
        @w_base_calculo       catalogo,
        @w_causacion          catalogo,
        @w_gerente            int,
        @w_fecha_causacion    datetime,
        @w_op_direccion       tinyint,
        @w_op_cliente         int,
        @w_op_estado          tinyint,
        @w_op_monto           money,
        @w_dtr_dividendo      int,
        @w_dtr_concepto       catalogo,
        @w_dtr_estado         char(20),
        @w_dtr_cuenta         cuenta,
        @w_dtr_moneda         char(20),
        @w_dtr_monto          money,
        @w_dtr_monto_mn       money,
	    @w_am_cuota_cap	      money,
        @w_ente               int,
        @w_ab_operacion       int,
        @w_ab_fecha_ing       datetime,
        @w_ab_fecha_pag       datetime,
        @w_ab_tipo_reduccion  char(1),
        @w_ab_estado          char(3),
        @w_ab_secuencial_ing  int,
        @w_tr_secuencial_ref  int,
        @w_ab_secuencial_rpa  int,
        @w_ab_secuencial_pag  int,
        @w_ab_tipo_cobro      char(1),
        @w_abd_concepto       catalogo,
        @w_abd_monto_mpg      money,
        @w_abd_cuenta         cuenta,
        @w_pa_nemonico        catalogo,
        @w_pa_categoria       catalogo,
        @w_est_cancelado      tinyint,
        @w_saldo_capital      money,
        @w_dtr_monto_cap      money,
        @w_dtr_monto_int      money,
        @w_dtr_monto_imo      money,
        @w_dtr_monto_seg      money,
        @w_dtr_monto_mip      money,
        @w_dtr_monto_iva      money,
        @w_dtr_monto_con      money,
        @w_dtr_monto_otr      money,
        @w_saldo_cap          money,
	    @w_tr_operacion       int,
        @w_dtr_afectacion     char(1),
        @w_op_monto_saldo     money,
        @w_est_aplicado       char(1)

        
/* ESTADO DEL DIVIDENDO */
select @w_est_cancelado = es_codigo
from   ca_estado
where  ltrim(rtrim(es_descripcion)) = 'CANCELADO'


/* ESTADO DE LOS PAGOS A GENERAR EN LA CONSULTA */
select @w_est_aplicado = b.codigo
from cobis..cl_tabla a,
     cobis..cl_catalogo b
where a.tabla = 'ca_estado_pago'
and   b.tabla = a.codigo
and   valor   = 'APLICADO'
AND   estado  = 'V'


/*CREACION DE TABLA TEMPORAL DEFINITIVA */
create table #pagos
   (
   tmp_operacion       int      not null, --Numero de la operacion consultada
   tmp_secuencial_rpa  int      not null, --Numero secuencial de cada pago
   tmp_estado          char(3)  not null, --Estado del pago
   tmp_tipo_reduccion  char(1)  not null, --Tipo de aplicacion (Normal, Cuota ext. red. plazo, Cuota ext. red. cuota)
   tmp_forma           catalogo not null, --Forma de pago utilizada
   tmp_fecha_ing       datetime not null, --Fecha en que se ingreso el pago
   tmp_fecha_pag       datetime not null, --Fecha real de aplicación del pago
   tmp_secuencial_ing  int      not null, --Numero secuencial de ingreso
   tmp_secuencial_pag  int      not null, --Numero secuencial del pago
   tmp_cuenta          char(24) not null, --Numero del recibo de pago
   tmp_tipo_cobro      char(1)  not null, --Tipo de cobro (Proyectado, Acumulado, Valor presente)
   tmp_monto_mpg       money    not null, --Valor total del pago aplicado
   tmp_dividendo       int      not null, --Numero del dividendo afectado por el pago
   tmp_concepto        catalogo not null, --Concepto que afectó el pago en cada dividendo
   tmp_monto_con       money    not null, --Valor que afecto el concepto en cada dividendo
   tmp_afectacion      char(1)  not null, --Tipo afectacion (Debito o Credito)
   tmp_saldo_cap       money    not null, --Saldo calculado de capital
   tmp_pago_cap       money
)


/*SELECCIONA LA OPERACION */
select 
@w_operacionca       = op_operacion,
@w_banco             = op_banco,
@w_tramite           = op_tramite,
@w_tipo              = op_tipo,
@w_tipo_amortizacion = op_tipo_amortizacion,
@w_dias_div          = op_periodo_int,
@w_tdividendo        = op_tdividendo,
@w_fecha_ult_proceso = op_fecha_ult_proceso,
@w_toperacion        = op_toperacion,
@w_moneda            = op_moneda,
@w_op_monto          = op_monto,
@w_dias_anio         = op_dias_anio,
@w_sector            = op_sector,
@w_oficina           = op_oficina,
@w_fecha_liq         = op_fecha_liq,
@w_fecha_ini         = op_fecha_ini,
@w_clausula          = op_clausula_aplicada,
@w_base_calculo      = op_base_calculo,
@w_causacion         = op_causacion,
@w_gerente           = op_oficial,
@w_fecha_causacion   = op_fecha_ult_causacion,
@w_op_direccion      = op_direccion,
@w_op_cliente        = op_cliente,
@w_op_estado         = op_estado
from   ca_operacion
where  op_banco             = @i_banco

if @@rowcount = 0
begin
   select @w_error = 710022
   goto ERROR
end


select @w_op_monto_saldo = @w_op_monto 	--Inicializa esta variable con el valor del desembolso de la operacion
select @w_saldo_cap      = @w_op_monto 	--Inicializa esta variable con el valor del desembolso de la operacion


/*CONSULTAR ABONOS */
if @i_operacion = 'Q'
begin
    /* CURSOR PARA DETERMINAR TODOS LOS PAGOS DE LA OPERACION */
    declare
    cursor_abonos cursor
    for select
          abd_concepto,         ab_fecha_pag,         ab_fecha_ing,          abd_monto_mpg,        abd_cuenta,
          ab_tipo_reduccion,    ab_estado,            ab_operacion,          ab_secuencial_ing,    ab_secuencial_rpa,
          ab_secuencial_pag,    ab_tipo_cobro
    from  ca_abono, ca_abono_det
    where ab_operacion        = @w_operacionca
    and   ab_operacion        = abd_operacion
    and   ab_secuencial_ing   = abd_secuencial_ing
    and   ab_estado           = @w_est_aplicado
    order by ab_operacion, ab_secuencial_rpa

    for read only

    open  cursor_abonos
    fetch cursor_abonos
    into  @w_abd_concepto,      @w_ab_fecha_pag,       @w_ab_fecha_ing,       @w_abd_monto_mpg,      @w_abd_cuenta,
          @w_ab_tipo_reduccion, @w_ab_estado,          @w_ab_operacion,       @w_ab_secuencial_ing,  @w_ab_secuencial_rpa,
          @w_ab_secuencial_pag, @w_ab_tipo_cobro

    while   @@fetch_status = 0
    begin
        if (@@fetch_status = -1)
           return 710004

        /* CURSOR DETALLE DE LOS PAGOS DE LA OPERACION */
        declare
        cursor_detalle cursor
        for select tr_operacion, tr_secuencial_ref, dtr_dividendo, dtr_afectacion, dtr_concepto, dtr_monto= sum(dtr_monto)
        from ca_transaccion, ca_det_trn
        where tr_operacion      = @w_operacionca
        and   tr_secuencial_ref = @w_ab_secuencial_rpa
        and   dtr_operacion     = tr_operacion
        and   dtr_secuencial    = tr_secuencial
        and   dtr_dividendo     > 0
        group by tr_operacion, tr_secuencial_ref, dtr_dividendo, dtr_afectacion, dtr_concepto
        order by dtr_concepto


        for read only

        open  cursor_detalle
        fetch cursor_detalle
        into  @w_tr_operacion, @w_tr_secuencial_ref, @w_dtr_dividendo, @w_dtr_afectacion, @w_dtr_concepto, @w_dtr_monto

        while   @@fetch_status = 0
        begin
            if (@@fetch_status = -1) return 710004

               if exists (select 1
                       from #pagos
                       where tmp_operacion      = @w_ab_operacion
                       and   tmp_secuencial_rpa = @w_ab_secuencial_rpa
                       and   tmp_forma          = @w_abd_concepto
                       and   tmp_concepto       = @w_dtr_concepto
                       and   tmp_dividendo      = @w_dtr_dividendo)
	            begin
        	        if @w_dtr_concepto = 'CAP' --print 'update CAP ' 
                    	update #pagos
                    	set tmp_monto_con       = @w_dtr_monto,
        		    tmp_saldo_cap               = @w_op_monto_saldo
	                where tmp_operacion         = @w_ab_operacion
                	and   tmp_secuencial_rpa    = @w_ab_secuencial_rpa
	                and   tmp_forma             = @w_abd_concepto
        	        and   tmp_concepto          = @w_dtr_concepto
                	and   tmp_dividendo         = @w_dtr_dividendo
	            end                             
            else
	            begin
		 	 if (@w_dtr_concepto= 'CAP')
			 	select @w_am_cuota_cap = am_cuota
                         	from ca_amortizacion
                         	where am_operacion = @w_ab_operacion
                         	and am_dividendo   = @w_dtr_dividendo
                         	and am_concepto    = @w_dtr_concepto
		 	  else
			         select @w_am_cuota_cap =0

	            	  insert into #pagos
        		       (tmp_operacion,     tmp_secuencial_rpa,     tmp_estado,            tmp_tipo_reduccion,    tmp_forma,
		                tmp_fecha_ing,     tmp_fecha_pag,          tmp_secuencial_ing,    tmp_secuencial_pag,    tmp_cuenta,
                	    tmp_tipo_cobro,    tmp_monto_mpg,          tmp_dividendo,         tmp_concepto,          tmp_monto_con,
		                tmp_afectacion,    tmp_saldo_cap,          tmp_pago_cap)
 	                   values (
		                @w_ab_operacion,   @w_ab_secuencial_rpa,   @w_ab_estado,          @w_ab_tipo_reduccion,  @w_abd_concepto,
        	       	        @w_ab_fecha_ing,   @w_ab_fecha_pag,        @w_ab_secuencial_ing,  @w_ab_secuencial_pag,  @w_abd_cuenta,
		                @w_ab_tipo_cobro,  @w_abd_monto_mpg,       @w_dtr_dividendo,      @w_dtr_concepto,       @w_dtr_monto,
		                @w_dtr_afectacion, @w_op_monto_saldo,      @w_am_cuota_cap)
	    end

            /* CURSOR PARA DETERMINAR TODOS LOS RUBROS DE LA OPERACION */
           /* declare cursor_rubros cursor for   
               select co_concepto, co_categoria   
               from  ca_rubro_op, ca_concepto, ca_categoria_rubro
               where co_concepto  = ro_concepto
               and   cr_codigo    = co_categoria
               and   ro_operacion = @w_operacionca
               order by co_concepto

            for read only

            open  cursor_rubros
            fetch cursor_rubros
            into  @w_pa_nemonico, @w_pa_categoria  

            while   @@fetch_status = 0
            begin
                if (@@fetch_status = -1) return 710004
                if not exists (select 1
                               from #pagos
                               where tmp_operacion      = @w_ab_operacion
                               and   tmp_secuencial_rpa = @w_ab_secuencial_rpa
                               and   tmp_forma          = @w_abd_concepto
                               and   tmp_concepto       = @w_pa_nemonico
                               and   tmp_dividendo      = @w_dtr_dividendo)
                begin
                    insert into #pagos
                    (tmp_operacion,     tmp_secuencial_rpa,     tmp_estado,            tmp_tipo_reduccion,    tmp_forma,
                     tmp_fecha_ing,     tmp_fecha_pag,          tmp_secuencial_ing,    tmp_secuencial_pag,    tmp_cuenta,
                     tmp_tipo_cobro,    tmp_monto_mpg,          tmp_dividendo,         tmp_concepto,          tmp_monto_con,
                     tmp_afectacion,    tmp_saldo_cap,           tmp_pago_cap)
                    values (
                     @w_ab_operacion,   @w_ab_secuencial_rpa,   @w_ab_estado,          @w_ab_tipo_reduccion,  @w_abd_concepto,
                     @w_ab_fecha_ing,   @w_ab_fecha_pag,        @w_ab_secuencial_ing,  @w_ab_secuencial_pag,  @w_abd_cuenta,
                     @w_ab_tipo_cobro,  @w_abd_monto_mpg,       @w_dtr_dividendo,      @w_pa_nemonico,        0,
                     @w_dtr_afectacion, @w_op_monto_saldo,      @w_am_cuota_cap)
                end

                fetch cursor_rubros
                into  @w_pa_nemonico, @w_pa_categoria  
            end -- end while cursor rubros
            close cursor_rubros
            deallocate cursor_rubros*/

            fetch cursor_detalle
            into  @w_tr_operacion, @w_tr_secuencial_ref, @w_dtr_dividendo, @w_dtr_afectacion, @w_dtr_concepto, @w_dtr_monto
        end --end while cursor detalle
        close cursor_detalle
        deallocate cursor_detalle

        fetch cursor_abonos
        into  @w_abd_concepto,      @w_ab_fecha_pag,       @w_ab_fecha_ing,       @w_abd_monto_mpg,      @w_abd_cuenta,
              @w_ab_tipo_reduccion, @w_ab_estado,          @w_ab_operacion,       @w_ab_secuencial_ing,  @w_ab_secuencial_rpa,
              @w_ab_secuencial_pag, @w_ab_tipo_cobro
    end --end while cursor abonos
    close cursor_abonos
    deallocate cursor_abonos
end


/* CURSOR PARA ACTUALIZAR SALDO DE CAPITAL */
declare
cursor_pagos cursor
for select
      tmp_operacion,     tmp_secuencial_rpa,     tmp_estado,            tmp_tipo_reduccion,    tmp_forma,
      tmp_fecha_ing,     tmp_fecha_pag,          tmp_secuencial_ing,    tmp_secuencial_pag,    tmp_cuenta,
      tmp_tipo_cobro,    tmp_monto_mpg,          tmp_dividendo,         tmp_concepto,          tmp_monto_con,
      tmp_afectacion,    tmp_saldo_cap
from  #pagos
order by tmp_secuencial_rpa, tmp_dividendo

for update

open  cursor_pagos
fetch cursor_pagos
into  @w_ab_operacion,   @w_ab_secuencial_rpa,   @w_ab_estado,          @w_ab_tipo_reduccion,  @w_abd_concepto,
      @w_ab_fecha_ing,   @w_ab_fecha_pag,        @w_ab_secuencial_ing,  @w_ab_secuencial_pag,  @w_abd_cuenta,
      @w_ab_tipo_cobro,  @w_abd_monto_mpg,       @w_dtr_dividendo,      @w_dtr_concepto,       @w_dtr_monto,
      @w_dtr_afectacion, @w_op_monto_saldo

while   @@fetch_status = 0
begin
    if (@@fetch_status = -1)
       return 710004

    if @w_dtr_concepto = 'CAP'
        begin
            select @w_saldo_cap = @w_saldo_cap - @w_dtr_monto
            update #pagos
            set   tmp_saldo_cap = @w_saldo_cap
            where tmp_operacion      = @w_ab_operacion
            and   tmp_secuencial_rpa = @w_ab_secuencial_rpa
            and   tmp_concepto       = 'CAP '
        end
    else
        begin
            update #pagos
            set   tmp_saldo_cap = @w_saldo_cap
            where tmp_operacion      = @w_ab_operacion
            and   tmp_secuencial_rpa = @w_ab_secuencial_rpa
            and   tmp_concepto       <> 'CAP '
        end

    fetch cursor_pagos
    into  @w_ab_operacion,   @w_ab_secuencial_rpa,   @w_ab_estado,          @w_ab_tipo_reduccion,  @w_abd_concepto,
          @w_ab_fecha_ing,   @w_ab_fecha_pag,        @w_ab_secuencial_ing,  @w_ab_secuencial_pag,  @w_abd_cuenta,
          @w_ab_tipo_cobro,  @w_abd_monto_mpg,       @w_dtr_dividendo,      @w_dtr_concepto,       @w_dtr_monto,
          @w_dtr_afectacion, @w_op_monto_saldo
end -- end while cursor pagos


close cursor_pagos
deallocate cursor_pagos


select 'sec_pag' = tmp_secuencial_rpa,
       'tmp_op'  = tmp_operacion,
       'num_div' = tmp_dividendo,
       'fec_ven' = convert(varchar(10),di_fecha_ven,103),
       'sal_cap' = tmp_saldo_cap,
/*
       'cuo_cap' = isnull((select sum(am_cuota)
                           from ca_amortizacion
                           where am_operacion = tmp_operacion
                           and am_dividendo = tmp_dividendo
                           and am_concepto = 'CAP'),0),
*/
       'cuo_cap' = isnull((select sum(dtr_monto)
                           from  ca_transaccion, ca_det_trn
                           where tr_operacion      = tmp_operacion
                           and   tr_secuencial_ref = tmp_secuencial_rpa
                           and   dtr_operacion     = tr_operacion
                           and   dtr_secuencial    = tr_secuencial
                           and   dtr_dividendo     = tmp_dividendo 
                           and   dtr_concepto      = 'CAP'
                           and   tr_tran           = 'PAG'
                           and   tr_estado         <> 'RV'),0),
/*
       'cuo_int' = isnull((select sum(am_cuota)
                           from ca_amortizacion
                           where am_operacion = tmp_operacion
                           and am_dividendo = tmp_dividendo
                           and am_concepto = 'INT'),0),
*/
       'cuo_int' = isnull((select sum(dtr_monto)
                           from  ca_transaccion, ca_det_trn
                           where tr_operacion      = tmp_operacion
                           and   tr_secuencial_ref = tmp_secuencial_rpa
                           and   dtr_operacion     = tr_operacion
                           and   dtr_secuencial    = tr_secuencial
                           and   dtr_dividendo     = tmp_dividendo 
                           and   dtr_concepto      = 'INT'
                           and   tr_tran           = 'PAG'
                           and   tr_estado         <> 'RV'),0),
/*
       'cuo_imo' = isnull((select sum(am_cuota)
                           from ca_amortizacion
                           where am_operacion = tmp_operacion
                           and am_dividendo = tmp_dividendo
                           and am_concepto = 'IMO'),0),
*/
       'cuo_imo' = isnull((select sum(dtr_monto)
                           from  ca_transaccion, ca_det_trn
                           where tr_operacion      = tmp_operacion
                           and   tr_secuencial_ref = tmp_secuencial_rpa
                           and   dtr_operacion     = tr_operacion
                           and   dtr_secuencial    = tr_secuencial
                           and   dtr_dividendo     = tmp_dividendo 
                           and   dtr_concepto      = 'IMO'
                           and   tr_tran           = 'PAG'
                           and   tr_estado         <> 'RV'),0),

       'tas_int' = isnull((select top 1 ts_porcentaje
                           from ca_tasas
                           where ts_secuencial IN (select max(ts_secuencial)
                                                   from ca_tasas 
                                                   where ts_operacion= tmp_operacion 
                                                   and ts_dividendo=tmp_dividendo 
                                                   and ts_concepto='INT')
                           and ts_operacion= tmp_operacion 
                           and ts_dividendo=tmp_dividendo 
                           and ts_concepto='INT'),0),
       'tas_imo' = isnull((select top 1 ts_porcentaje
                           from ca_tasas
                           where ts_secuencial IN (select max(ts_secuencial)
                                                   from ca_tasas
                                                   where ts_operacion= tmp_operacion 
                                                   and ts_dividendo=tmp_dividendo 
                                                   and ts_concepto='IMO')          
                           and ts_operacion= tmp_operacion 
                           and ts_dividendo=tmp_dividendo
                           and ts_concepto='IMO'),0),
/*
       'cuo_pym' = isnull((select am_cuota
                           from ca_amortizacion
                           where am_operacion = tmp_operacion
                           and am_dividendo = tmp_dividendo
                           and am_concepto = 'MIPYMES'),0),
*/
       'cuo_pym' = isnull((select sum(dtr_monto)
                           from  ca_transaccion, ca_det_trn
                           where tr_operacion      = tmp_operacion
                           and   tr_secuencial_ref = tmp_secuencial_rpa
                           and   dtr_operacion     = tr_operacion
                           and   dtr_secuencial    = tr_secuencial
                           and   dtr_dividendo     = tmp_dividendo 
                           and   dtr_concepto      = 'MIPYMES'
                           and   tr_tran           = 'PAG'
                           and   tr_estado         <> 'RV'),0),
/*
       'iva_pym' = isnull((select am_cuota
                           from ca_amortizacion
                           where am_operacion = tmp_operacion
                           and am_dividendo = tmp_dividendo
                           and am_concepto = 'IVAMIPYMES'),0),
*/
       'iva_pym' = isnull((select sum(dtr_monto)
                           from  ca_transaccion, ca_det_trn
                           where tr_operacion      = tmp_operacion
                           and   tr_secuencial_ref = tmp_secuencial_rpa
                           and   dtr_operacion     = tr_operacion
                           and   dtr_secuencial    = tr_secuencial
                           and   dtr_dividendo     = tmp_dividendo 
                           and   dtr_concepto      = 'IVAMIPYMES'
                           and   tr_tran           = 'PAG'
                           and   tr_estado         <> 'RV'),0),

	'otros' = isnull((select sum(dtr_monto)
                           from  ca_transaccion, ca_det_trn
                           where tr_operacion      = tmp_operacion
                           and   tr_secuencial_ref = tmp_secuencial_rpa
                           and   dtr_operacion     = tr_operacion
                           and   dtr_secuencial    = tr_secuencial
                           and   dtr_dividendo     = tmp_dividendo 
                           and   dtr_concepto      not in ('CAP', 'INT', 'IMO', 'MIPYMES', 'IVAMIPYMES')
                           and   tr_tran           = 'PAG'
                           and   tr_estado         <> 'RV'
			   and   dtr_dividendo > 0),0),

       'fec_ini' = convert(varchar(10),di_fecha_ini,103),
       'int_cau' = isnull((select top 1 am_acumulado
                           from ca_amortizacion
                           where am_operacion = tmp_operacion
                           and am_dividendo = tmp_dividendo
                           and am_concepto='INT'),0),
       'sen_cuo' = isnull((select case when di_estado=3 then 'SI' else 'NO' end),0),
       'dia_ret' = isnull((select case when datediff(dd, di_fecha_ven, di_fecha_can)<0
                           then 0
                           else datediff(dd, di_fecha_ven, di_fecha_can) end),0),
       'fec_pag' = convert(varchar(10),tmp_fecha_pag,103),
       'num_cue' = tmp_cuenta,
       'con_cuo' = (select case when tmp_concepto IN ('CAP','INT','IMO','MIPYMES','IVAMIPYMES')
                    then tmp_concepto 
                    else 'OTRRUB' end),
       'mon_cuo' = tmp_monto_con
into #salida2
from #pagos, ca_dividendo
where di_operacion = tmp_operacion
and   di_dividendo = tmp_dividendo
order by tmp_secuencial_rpa, tmp_dividendo, tmp_concepto

create table #conversora
	(
	cnv_concepto char(10),
	cnv_col1      int,
	cnv_col2      int,
	cnv_col3      int,
	cnv_col4      int,
	cnv_col5      int,
	cnv_col6      int,
	cnv_col7      int)

insert into #conversora
	values ('CAP'		,1,1,0,0,0,0,0)
insert into #conversora
	values ('INT'		,0,0,1,0,0,0,0)
insert into #conversora
	values ('IMO'		,0,0,0,1,0,0,0)
insert into #conversora
	values ('MIPYMES'	,0,0,0,0,1,0,0)
insert into #conversora
	values ('IVAMIPYMES'	,0,0,0,0,0,1,0)
insert into #conversora
	values ('OTRRUB'	,0,0,0,0,0,0,1)

declare @w_contador int
set @w_contador = 0

select 
   'res_sec_pag'          = sec_pag,
   'res_div'              = num_div,
   'abo_cond'             = 0, 
	sum(sal_cap*cnv_col1) as capital,
	sum(cuo_cap*cnv_col2) as cuota_cap,
	sum(cuo_int*cnv_col3) as abo_int,
	sum(cuo_imo*cnv_col4) as abo_mor,
	sum(cuo_pym*cnv_col5) as abo_pymes,
	sum(iva_pym*cnv_col6) as abo_iva_pymes,
	sum(mon_cuo*cnv_col1) as abo_cap,
	sum(mon_cuo*cnv_col7) as abo_otrrub, 
	identity(int, 1,1) as sec_reg
into #resumen
from #salida2, #conversora
where cnv_concepto=con_cuo
group by sec_pag, num_div

/* REGISTRO DE SALIDA PARA EL FORMATO DE IMPRESION */

select distinct num_div,
                'fecha_ven' = convert(varchar,fec_ven,103), --@i_formato_fecha), 
                capital,
                cuo_cap,
                cuo_int,
                cuo_imo,
                tas_int,
                tas_imo,
                cuo_pym,
                iva_pym, 
                'fecha_ini' = convert(varchar,fec_ini,103),  --@i_formato_fecha), 
                int_cau, 
		abo_otrrub,
		sen_cuo,
                --'sum_cap' = isnull((select  sum(abo_cap) from #resumen where  res_div <= num_div and res_sec_pag <= sec_pag), 0),		
                --'sum_int' = isnull((select  sum(abo_int) from #resumen where  res_div <= num_div and sec_registro <= sec_pag ), 0),
                --'sum_imo' = isnull((select  sum(abo_mor) from #resumen where  res_div <= num_div and res_sec_pag <= sec_pag), 0),
                --'sum_con' = 0, --(select  sum(abo_otr) from #resumen where  res_div <= num_div), --por definir
                --'sum_pym' = isnull((select  sum(abo_pymes) from #resumen where  res_div <= num_div and res_sec_pag <= sec_pag), 0), 
                --'sum_iva' = isnull((select  sum(abo_iva_pymes) from #resumen where  res_div <= num_div and res_sec_pag <= sec_pag), 0), 
                dia_ret,
                'fec_pag' = convert(varchar,fec_pag,103), --@i_formato_fecha),
                num_cue,
                abo_cap,
                abo_int,
                abo_mor,
                abo_cond,
                abo_pymes,
                abo_iva_pymes,
                sec_pag,
                sec_reg,
		identity(int, 1,1) as sec_registro 
into #salida3
from #resumen, #salida2
where sec_pag  = res_sec_pag
and   num_div  = res_div 
--and   sec_reg >= @i_reg_ini
order by num_div, sec_reg

set rowcount 5

select distinct num_div,
                convert(varchar,fecha_ven,103),
                capital,
                cuo_cap,
                cuo_int,
                cuo_imo,
                tas_int,
                tas_imo,
                cuo_pym,
                iva_pym, 
                convert(varchar,fecha_ini,103),
                int_cau, 
		abo_otrrub,
		sen_cuo,
                'sum_cap' = isnull((select  sum(abo_cap) from #salida3 where  sec_registro <= A.sec_registro), 0),
                'sum_int' = isnull((select  sum(abo_int) from #salida3 where  sec_registro <= A.sec_registro), 0),
                'sum_imo' = isnull((select  sum(abo_mor) from #salida3 where  sec_registro <= A.sec_registro), 0),
                'sum_con' = 0, --(select  sum(abo_otr) from #resumen where  res_div <= num_div), --por definir
                'sum_pym' = isnull((select  sum(abo_pymes) from #salida3 where  sec_registro <= A.sec_registro), 0), 
                'sum_iva' = isnull((select  sum(abo_iva_pymes) from #salida3 where sec_registro <= A.sec_registro), 0), 
                dia_ret,
                fec_pag,
                num_cue,
                abo_cap,
                abo_int,
                abo_mor,
                abo_cond,
                abo_pymes,
                abo_iva_pymes,
		sec_pag,		
		sec_registro                                
from #salida3 A
where sec_registro >= @i_reg_ini
order by num_div, sec_registro

set rowcount 5

return 0
        
ERROR:  
        
exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_error
        
return @w_error
        
go      
        
        