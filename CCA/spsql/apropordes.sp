/************************************************************************/
/*      Archivo:                apropordes.sp                         */
/*      Stored procedure:       sp_aprobados_por_desembolsar            */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Miguel Roa                              */
/*      Fecha de escritura:     Mayo 2008                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.	                                                    */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Genera tablas interfaz PALM en proceso diario                   */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_aprobados_por_desembolsar')
   drop proc sp_aprobados_por_desembolsar
go

create proc sp_aprobados_por_desembolsar
    @s_user           login     = null,
    @t_trn            smallint  = null,
    @i_operacion      char(1)   = 'B'

as

declare @w_sp_name                      varchar(32),
        @w_return                       int,
        @w_error                        int,
        @w_rowcount 		            int,
        @w_operacionca                  int,

        @w_op_nombre                    descripcion,
		@w_op_tramite                   int,
		@w_op_monto                     money,
		@w_op_plazo                     smallint,
		@w_op_tplazo                    catalogo,
		@w_plazo_meses                  smallint,
		@w_op_cuota                     money,
        @w_microseg                     money,
		@w_cap_renovar                  money,
		@w_int_renovar                  money,
		@w_mypimes                      money,
		@w_iva_mypimes                  money,
		@w_seg_deu_ant                  money,
        @w_seg_deu_ven                  money,
		@w_seg_deu_tot                  money,
		@w_exequial                     money,
		@w_otros_rubros                 money,
		@w_neto_desemb                  money,
        @w_est_novigente                tinyint,
        @w_rubro_cap                    varchar(30),
        @w_rubro_int                    varchar(30),
        @w_rubro_imo                    varchar(30),
        @w_rubro_mip                    varchar(30),
        @w_rubro_fng					varchar(30),
        @w_rubro_hon					varchar(30),
        @w_rubro_sedean					varchar(30),
        @w_rubro_sedeve					varchar(30),
        @w_rubro_cenrie					varchar(30),
        @w_seg_deu						money,
        @w_op_operacion					int,
        @op_operacion                   int,
        @w_rubro_asociado               money


/* ESTADOS DEL DIVIDENDO */
select @w_est_novigente = es_codigo
from   ca_estado
where  ltrim(rtrim(es_descripcion)) = 'NO VIGENTE'

/* CODIGO DEL RUBRO CAPITAL */
select @w_rubro_cap = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'CAP'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0 
   return 701060

/* CODIGO DEL RUBRO INTERES */
select @w_rubro_int = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'INT'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0 
   return 701084
   
/* CODIGO DEL RUBRO MORA */
select @w_rubro_imo = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'IMO'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0 
   return 701084

/* CODIGO DEL RUBRO MIPYMES */
select @w_rubro_mip = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'MIPYME'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0 
   return 701084

/* CODIGO DEL RUBRO MICROSEGURO */
select @w_rubro_imo = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'MICSEG'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0 
   return 701084

/* CODIGO DEL RUBRO SEGURO EXEQUIAL */
select @w_rubro_imo = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'EXEQUI'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0 
   return 701084

/* CODIGO DEL RUBRO COMISION FNG */
select @w_rubro_fng = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'COMFNG'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0 
   return 701084
   
/* CODIGO DEL RUBRO HONORARO DE ABOGADO */
select @w_rubro_hon = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'HONABO'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0 
   return 701084

/* CODIGO DEL RUBRO SEGURO DEUDORES ANTICIPADO */
select @w_rubro_sedean = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'SEDEAN'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0 
   return 701084

/* CODIGO DEL RUBRO SEGURO DEUDORES VENCIDO */
select @w_rubro_sedeve = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'SEDEVE'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0 
   return 701084

/* CODIGO DEL RUBRO SEGURO COBRO CENTRAL DE RIESGO */
select @w_rubro_cenrie = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'CENRIE'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0 
   return 701084

/* CURSOR PARA PROCESAR TODAS LAS OPERACIONES PENDIENTES DE DESEMBOLSO */
declare
    cursor_operaciones cursor
    for select op_nombre, op_tramite,       op_monto,       op_plazo,    op_tplazo,      op_cuota,
               0,          0,               0,              0,           0,              0,
			   0,          0,               0
    from ca_operacion
    where op_estado = @w_est_novigente
    and   op_tramite is not null

    for read only

    open  cursor_operaciones
    fetch cursor_operaciones
    into  @w_op_nombre,    @w_op_tramite,   @w_op_monto,    @w_op_plazo, @w_op_tplazo,   @w_op_cuota,
          @w_microseg,     @w_cap_renovar,  @w_int_renovar, @w_mypimes,  @w_iva_mypimes, @w_seg_deu,
		  @w_exequial,     @w_otros_rubros, @w_neto_desemb

    while   @@fetch_status = 0
    begin
        if (@@fetch_status = -1)
           return 710004   -- Error en la lectura del cursor

        select @w_plazo_meses = @w_op_plazo * (select td_factor from ca_tdividendo where td_tdividendo = @w_op_tplazo) / 30

        select @w_microseg    = isnull((select ms_valor
                                        from cob_credito..cr_micro_seguro
							            where ms_tramite = @w_op_tramite),0)

        select @w_cap_renovar = isnull((select sum(am_cuota + am_gracia - am_pagado)
                                        from cob_credito..cr_op_renovar,
                                             cob_cartera..ca_operacion,
                                             cob_cartera..ca_amortizacion
                                        where or_tramite   = @w_op_tramite
                                        and   op_tramite   = or_tramite
                                        and   am_operacion = op_operacion
                                        and   am_concepto  = @w_rubro_cap),0)
 
        select @w_int_renovar = isnull((select sum(am_cuota + am_gracia - am_pagado)
                                        from cob_credito..cr_op_renovar,
                                             cob_cartera..ca_operacion,
                                             cob_cartera..ca_amortizacion
                                        where or_tramite   = @w_op_tramite
                                        and   op_tramite   = or_tramite
                                        and   am_operacion = op_operacion
                                        and   am_concepto  = @w_rubro_int),0)

		 select @w_mypimes     = isnull((select sum(am_cuota + am_gracia - am_pagado)
                                        from cob_cartera..ca_amortizacion
                                        where am_operacion = @w_op_operacion
                                        and   am_concepto  = @w_rubro_mip),0)

        /* VERIFICAR SI EL RUBRO MIPYMES TIENE RUBRO ASOCIADO */
        if exists (select 1
                   from   ca_rubro_op
                   where  ro_operacion          = @op_operacion
                   and    ro_concepto_asociado = @w_rubro_mip)
        begin

            select @w_rubro_asociado = ro_concepto
            from ca_rubro_op
            where  ro_operacion         = @w_op_operacion
            and    ro_concepto_asociado = @w_rubro_mip
           
            select  @w_iva_mypimes = isnull((select sum(am_cuota + am_gracia - am_pagado)
                                             from cob_cartera..ca_amortizacion
                                             where am_operacion = @w_op_operacion
                                             and   am_concepto  = @w_rubro_asociado),0)
        end

        select @w_seg_deu_ant = isnull((select ro_valor
                                 from cob_cartera..ca_rubro_op
                                 where ro_operacion = @w_op_operacion
                                 and   ro_concepto  = @w_rubro_sedean),0)

        select @w_seg_deu_ven = isnull((select sum(am_cuota + am_gracia - am_pagado)
                                 from cob_cartera..ca_amortizacion
                                 where am_operacion = @w_op_operacion
                                 and   am_concepto  = @w_rubro_sedeve),0)

        select @w_seg_deu_tot = @w_seg_deu_ant + @w_seg_deu_ven

        select @w_exequial     = isnull((select se_val_total
                                  from cob_credito..cr_seguro_exequial
	                              where se_tramite = @w_op_tramite),0)

        select @w_otros_rubros = isnull((select sum(am_cuota + am_gracia - am_pagado)
                                  from cob_cartera..ca_amortizacion
                                  where am_operacion = @w_op_operacion
                                  and   am_concepto  not in (@w_rubro_cap,
                                                             @w_rubro_int,
                                                             @w_rubro_mip,
                                                             @w_rubro_asociado,
                                                             @w_rubro_sedean)),0)

        select @w_neto_desemb = (@w_op_monto - @w_microseg - @w_cap_renovar - @w_int_renovar - @w_mypimes -
                                 @w_iva_mypimes - @w_seg_deu_ant - @w_seg_deu_ven - @w_exequial - @w_otros_rubros)
   
        insert into cob_cartera..ca_aprob_por_desemb_tmp -- TABLA TEMPORAL PARA IMPRESION DE REPORTE
                (apd_nombre,       apd_tramite,      apd_monto,        apd_plazo_meses,
                 apd_cuota,        apd_microseg,     apd_cap_renovar,  apd_int_renovar,
                 apd_mypimes,      apd_iva_mypimes,  apd_seg_deu_tot,  apd_exequial,
                 apd_otros_rubros, apd_neto_desemb)
        values  (@w_op_nombre,     @w_op_tramite,    @w_op_monto,      @w_plazo_meses,
                 @w_op_cuota,      @w_microseg,      @w_cap_renovar,   @w_int_renovar,
                 @w_mypimes,       @w_iva_mypimes,   @w_seg_deu_tot,   @w_exequial,
                 @w_otros_rubros,  @w_neto_desemb)

        fetch cursor_operaciones
        into  @w_op_nombre,    @w_op_tramite,   @w_op_monto,    @w_op_plazo, @w_op_tplazo,   @w_op_cuota,
              @w_microseg,     @w_cap_renovar,  @w_int_renovar, @w_mypimes,  @w_iva_mypimes, @w_seg_deu,
              @w_exequial,     @w_otros_rubros, @w_neto_desemb

    end -- Finaliza cursor_operaciones

    close cursor_operaciones
    deallocate cursor_operaciones


return 0
       
ERROR:  
        
exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_error
        
return @w_error
        
go


