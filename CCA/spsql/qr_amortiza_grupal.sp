/************************************************************************/
/*   NOMBRE LOGICO:      qr_amortiza_grupal.sp                          */
/*   NOMBRE FISICO:      sp_qr_table_amortiza_grupal                    */
/*   BASE DE DATOS:      cob_cartera                                    */
/*   PRODUCTO:           Cartera                                        */
/*   DISENADO POR:       Juan Carlos Guzmán                             */
/*   FECHA DE ESCRITURA: 20/Ene/2023                                    */
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
/*                                PROPOSITO                             */
/*  Consulta de la tabla de amortizacion de una operacion grupal de     */
/*  cartera para la pantalla de Datos del Prestamo                      */
/************************************************************************/
/*                              MODifICACIONES                          */ 
/*  FECHA          AUTOR         RAZON                                  */ 
/*  20/Ene/2023    J. Guzman     Versión inicial                        */
/*  28/Feb/2023    K. Rodriguez  S787837 Ajustes por tablas de préstamos*/
/*                               hijos con diferimientos o reestructuras*/
/*  01/Nov/2023    K. Rodriguez  R220700 Excluir OPs en estado anulado  */
/************************************************************************/

use cob_cartera
go

if object_id ('sp_qr_table_amortiza_grupal') is not null
    drop procedure sp_qr_table_amortiza_grupal
go

create proc sp_qr_table_amortiza_grupal
(
    @s_date   datetime = null,
    @i_banco  cuenta  -- Número de préstamo 
)
as

declare @w_sp_name         varchar(25),
        @w_i               int,
        @w_j               int,
        @w_num_cuota       int,
        @w_saldo_cap       money,
        @w_error           int,
        @w_div_vigente     int,
        @w_operacion_valor money,
        @w_est_dividendo   smallint,
        @w_min_fecha       datetime,
        @w_max_fecha       datetime,
        @w_est_cancelado   tinyint,
        @w_est_novigente   tinyint,
        @w_est_vigente     tinyint,
        @w_est_vencido     tinyint,
		@w_est_anulado     tinyint,
        @w_count_estados   int,
        @w_value_estados   int,
        @w_val_all_divs    int,
        @w_entra_est_divs  char(1)

select @w_sp_name        = 'sp_qr_table_amortiza_grupal',
       @w_div_vigente    = 0,
       @w_val_all_divs   = -1,
       @w_entra_est_divs = 'S'
       
       
/* Obtener estados de cartera */
exec @w_error = sp_estados_cca
   @o_est_vigente    = @w_est_vigente   out,
   @o_est_cancelado  = @w_est_cancelado out,
   @o_est_novigente  = @w_est_novigente out,
   @o_est_vencido    = @w_est_vencido   out,
   @o_est_anulado    = @w_est_anulado   out

delete ca_qr_rubro_tmp
where  qrt_pid = @@spid

if @@error != 0 
begin
   /* Error en eliminacion tabla ca_qr_rubro_tmp */
   select @w_error = 707085
   
   goto ERROR
end

delete ca_qr_amortiza_tmp
where  qat_pid = @@spid

if @@error != 0 
begin
   /* Error en eliminacion tabla ca_qr_amortiza_tmp */
   select @w_error = 707086
   
   goto ERROR
end

/* Tabla temporal para almacenar rubros que están en la ca_amortizacion de las operaciones hijas */
if exists (select 1 from sysobjects where name = '#rubros_enamortiz')
   drop table #rubros_enamortiz
   
create table #rubros_enamortiz (
   rubro   catalogo 
)


insert into #rubros_enamortiz
select distinct am_concepto
from ca_amortizacion, 
     ca_operacion
where am_operacion  = op_operacion
and   op_grupal     = 'S'
and   op_ref_grupal = @i_banco
and   op_estado not in (@w_est_anulado)

if @@error != 0 
begin
   /* Error en insercion tabla #rubros_enamortiz */
   select @w_error = 703131
   
   goto ERROR
end


insert into ca_qr_rubro_tmp (qrt_pid, qrt_rubro)
select distinct @@spid, ro_concepto
from ca_rubro_op with (nolock),
     ca_operacion with (nolock)
where ro_operacion  = op_operacion
and   op_grupal     = 'S'
and   op_ref_grupal = @i_banco
and   op_estado not in (@w_est_anulado)
and   ro_fpago      <> 'L'  --solo los rubros que se descuentan en el desembolso no se añaden a la tabla de amortizacion
and   ro_concepto   in (select rubro from #rubros_enamortiz)
order by ro_concepto

if @@error != 0 
begin
   /* Error en insercion tabla ca_qr_rubro_tmp */
   select @w_error = 703132
   
   goto ERROR
end


/* Tabla temporal para guardar los distintos estados de las operaciones hijas */
if object_id('tempdb..#ca_estados_ope_hijas', 'U') is not null  
   drop table #ca_estados_ope_hijas
   
create table #ca_estados_ope_hijas (
   eoh_estado  int 
)

insert into #ca_estados_ope_hijas
select distinct op_estado
from ca_operacion with (nolock)
where op_grupal     = 'S'
and   op_ref_grupal = @i_banco
and   op_estado not in (@w_est_anulado)

if @@error != 0 
begin
   /* Error en insercion tabla #ca_estados_ope_hijas */
   select @w_error = 703136
   
   goto ERROR
end


/* Se valida si todas las operaciones tienen el mismo estado y estos son NO VIGENTE O CANCELADO
   con esto, ese mismo estado los tomará todos los dividendos y no será necesario hacer el 
   proceso de mas adelante, de validación y asignación de estados a los dividendos */
   
select @w_count_estados = count(1)
from #ca_estados_ope_hijas

if @w_count_estados = 1
begin
   select @w_value_estados = eoh_estado
   from #ca_estados_ope_hijas

   if @w_value_estados = @w_est_novigente
   begin
      select @w_val_all_divs   = @w_est_novigente,
             @w_entra_est_divs = 'N'
   end
   
   if @w_value_estados = @w_est_cancelado
   begin
      select @w_val_all_divs   = @w_est_cancelado,
             @w_entra_est_divs = 'N'
   end
end

if @w_val_all_divs = -1
   select @w_val_all_divs = @w_est_novigente


/* Inserción de datos para mostrar en la tabla de amortización en el Frontend */
insert into ca_qr_amortiza_tmp (
   qat_pid,         qat_dividendo,   qat_fecha_ven,  qat_fecha_ini,
   qat_dias_cuota,  qat_cuota,       
   qat_estado,      
   qat_porroga )
select 
   @@spid,          di_dividendo,    di_fecha_ven,    di_fecha_ini,
   di_dias_cuota,   sum(am_cuota + am_gracia), 
   substring(es_descripcion,1,20),
   di_prorroga
from ca_operacion with (nolock),
     ca_amortizacion,
     ca_dividendo,
     ca_estado
where am_operacion  = op_operacion
and   am_operacion  = di_operacion
and   am_dividendo  = di_dividendo
and   op_grupal     = 'S'
and   op_ref_grupal = @i_banco
and   op_estado not in (@w_est_anulado)
and   es_codigo     = @w_val_all_divs
group by di_dividendo,di_fecha_ven, di_fecha_ini, di_dias_cuota, di_prorroga, es_descripcion

if @@error != 0 
begin
   /* Error en insercion tabla ca_qr_amortiza_tmp */
   select @w_error = 703133
   
   goto ERROR
end

/* Si en las validaciones anteriores de todos los estados de las ope. hijas, se modifica la variable
   @w_entra_est_divs = 'N', entonces no es necesario entrar a realizar todo este proceso */

if @w_entra_est_divs = 'S'
begin
   /* Tabla temporal con información necesaria para obtener los estados de las cuotas (Vigente, No Vigente, etc.) */
   if object_id('tempdb..#ca_estados_cuotas_tmp', 'U') is not null  
      drop table #ca_estados_cuotas_tmp
      
   create table #ca_estados_cuotas_tmp (
      ect_dividendo  int        null,
      ect_fecha_ini  datetime   null,
      ect_fecha_ven  datetime   null,
      ect_pagado     money      null
   )
   
   insert into #ca_estados_cuotas_tmp
   select di_dividendo, di_fecha_ini, di_fecha_ven, sum(am_pagado)
   from cob_cartera..ca_operacion with (nolock),
        cob_cartera..ca_amortizacion,
        cob_cartera..ca_dividendo
   where am_operacion  = op_operacion
   and   am_operacion  = di_operacion
   and   am_dividendo  = di_dividendo
   and   op_grupal     = 'S'
   and   op_ref_grupal = @i_banco
   and   op_estado not in (@w_est_anulado)
   group by di_dividendo, di_fecha_ini, di_fecha_ven
   
   if @@error != 0 
   begin
      /* Error en insercion tabla #ca_estados_cuotas_tmp */
      select @w_error = 703134
      
      goto ERROR
   end
   
   -- Obtener el dividendo que sea vigente de acuerdo a las fechas de inicio y vencimiento
   select @w_div_vigente = ect_dividendo
   from #ca_estados_cuotas_tmp
   where (@s_date > ect_fecha_ini and @s_date <= ect_fecha_ven)
   
   if @w_div_vigente = 0
   begin
      select @w_min_fecha = min(ect_fecha_ini),
             @w_max_fecha = max(ect_fecha_ven)
      from #ca_estados_cuotas_tmp
      
      if @w_min_fecha = @s_date
      begin
         select @w_div_vigente = 1
      end
      else if @s_date > @w_max_fecha
      begin
         /* Si la fecha de proceso es mayor a la maxima fecha de vencimiento de los dividendos
            entonces se debe recorrer todos los dividendos para buscar los que estén vencidos y
            cancelados, para el dividendo vigente va a ser el conteo de todos y se le suma uno
            para la validación que se tiene mas adelante, con esto ya recorremos toda la tabla */
         select @w_div_vigente = count(1)
      from #ca_estados_cuotas_tmp
      
      select @w_div_vigente = @w_div_vigente + 1 
      
      goto WHILE_DIVS
      end
   end
   
   --Se actualiza el estado del dividendo Vigente
   update ca_qr_amortiza_tmp
   set qat_estado = substring(es_descripcion,1,20)
   from ca_estado
   where qat_dividendo = @w_div_vigente
   and   qat_pid       = @@spid
   and   es_codigo     = @w_est_vigente
   
   if @@error != 0 
   begin
      /* Error en actualizacion en tabla ca_qr_amortiza_tmp */
      select @w_error = 705080
      
      goto ERROR
   end
   
   WHILE_DIVS:
   -- Se actualizan los estados de los dividendos anteriores al actual
   select @w_i = 1
   
   while(@w_i < @w_div_vigente)
   begin
      select @w_operacion_valor = (qat_cuota - ect_pagado)
      from ca_qr_amortiza_tmp,
           #ca_estados_cuotas_tmp
      where qat_dividendo = ect_dividendo
      and   qat_dividendo = @w_i
      and   qat_pid       = @@spid
      
      if @w_operacion_valor = 0
         select @w_est_dividendo = @w_est_cancelado
      else 
         select @w_est_dividendo = @w_est_vencido
      
      update ca_qr_amortiza_tmp
      set qat_estado = substring(es_descripcion,1,20)
      from ca_estado
      where qat_dividendo = @w_i
      and   qat_pid       = @@spid
      and   es_codigo     = @w_est_dividendo
      
      if @@error != 0 
      begin
         /* Error en actualizacion en tabla ca_qr_amortiza_tmp */
         select @w_error = 705080
         
         goto ERROR
      end
      
      select @w_i = @w_i + 1
   end
end


/* Tabla temporal para guardar valores de rubros */
if object_id('tempdb..#tmp_dividendo', 'U') is not null  
   drop table #tmp_dividendo

create table #tmp_dividendo (
   d_operacion    int    null,
   d_dividendo    int    null,
   d_fecha_ini    datetime    null,
   d_fecha_ven    datetime    null,
   d_qrt_id       int    null,
   d_qat_pid      int    null,
   d_saldo_cuota  money  null
)

/* Actualización de valor de cada rubro */
select @w_j = min(qrt_id)
from ca_qr_rubro_tmp
where qrt_pid = @@spid

select @w_i = @w_j

while @w_i <= (@w_j + 14)
begin
   
   insert into #tmp_dividendo(
      d_operacion,   d_dividendo,   d_qrt_id, 
      d_qat_pid,     d_saldo_cuota, 
      d_fecha_ini,   d_fecha_ven )
   select 
      0,             di_dividendo,  qrt_id, 
      qat_pid,       sum(am_cuota + am_gracia),
      qat_fecha_ini,  qat_fecha_ven
   from ca_dividendo    with (nolock), 
        ca_amortizacion with (nolock), 
        ca_qr_rubro_tmp with (nolock),
        ca_qr_amortiza_tmp with (nolock),
        ca_operacion with (nolock)
   where di_operacion = op_operacion
   and am_operacion = di_operacion 
   and am_dividendo = di_dividendo 
   and qat_dividendo = di_dividendo
   AND qat_fecha_ini = di_fecha_ini
   AND qat_fecha_ven = di_fecha_ven
   and am_concepto = qrt_rubro 
   and qrt_id = @w_i
   and qat_pid = @@spid 
   and qat_pid = qrt_pid
   and op_grupal = 'S'
   and op_ref_grupal = @i_banco
   and op_estado not in (@w_est_anulado)
   group by di_dividendo, qat_fecha_ini, qat_fecha_ven, qrt_id, qat_pid
   
   if @@error != 0 
   begin
      /* Error en insercion tabla #tmp_dividendo */
      select @w_error = 703135
      
      goto ERROR
   end
   
   
   if ((@w_i + 1 - @w_j) = 1)
      update ca_qr_amortiza_tmp set qat_rubro1 = d_saldo_cuota
      from #tmp_dividendo where qat_dividendo = d_dividendo and d_qrt_id = @w_i and qat_pid = @@spid and qat_fecha_ini = d_fecha_ini and qat_fecha_ven = d_fecha_ven

   if ((@w_i + 1 - @w_j) = 2)
      update ca_qr_amortiza_tmp set qat_rubro2 = d_saldo_cuota
      from #tmp_dividendo where qat_dividendo = d_dividendo and d_qrt_id = @w_i and qat_pid = @@spid and qat_fecha_ini = d_fecha_ini and qat_fecha_ven = d_fecha_ven

   if ((@w_i + 1 - @w_j) = 3)
      update ca_qr_amortiza_tmp set qat_rubro3 = d_saldo_cuota
      from #tmp_dividendo where qat_dividendo = d_dividendo and d_qrt_id = @w_i and qat_pid = @@spid and qat_fecha_ini = d_fecha_ini and qat_fecha_ven = d_fecha_ven

   if ((@w_i + 1 - @w_j) = 4)
      update ca_qr_amortiza_tmp set qat_rubro4 = d_saldo_cuota
      from #tmp_dividendo where qat_dividendo = d_dividendo and d_qrt_id = @w_i and qat_pid = @@spid and qat_fecha_ini = d_fecha_ini and qat_fecha_ven = d_fecha_ven

   if ((@w_i + 1 - @w_j) = 5)
      update ca_qr_amortiza_tmp set qat_rubro5 = d_saldo_cuota
      from #tmp_dividendo where qat_dividendo = d_dividendo and d_qrt_id = @w_i and qat_pid = @@spid and qat_fecha_ini = d_fecha_ini and qat_fecha_ven = d_fecha_ven

   if ((@w_i + 1 - @w_j) = 6)
      update ca_qr_amortiza_tmp set qat_rubro6 = d_saldo_cuota
      from #tmp_dividendo where qat_dividendo = d_dividendo and d_qrt_id = @w_i and qat_pid = @@spid and qat_fecha_ini = d_fecha_ini and qat_fecha_ven = d_fecha_ven

   if ((@w_i + 1 - @w_j) = 7)
      update ca_qr_amortiza_tmp set qat_rubro7 = d_saldo_cuota
      from #tmp_dividendo where qat_dividendo = d_dividendo and d_qrt_id = @w_i and qat_pid = @@spid and qat_fecha_ini = d_fecha_ini and qat_fecha_ven = d_fecha_ven

   if ((@w_i + 1 - @w_j) = 8)
      update ca_qr_amortiza_tmp set qat_rubro8 = d_saldo_cuota
      from #tmp_dividendo where qat_dividendo = d_dividendo and d_qrt_id = @w_i and qat_pid = @@spid and qat_fecha_ini = d_fecha_ini and qat_fecha_ven = d_fecha_ven

   if ((@w_i + 1 - @w_j) = 9)
      update ca_qr_amortiza_tmp set qat_rubro9 = d_saldo_cuota
      from #tmp_dividendo where qat_dividendo = d_dividendo and d_qrt_id = @w_i and qat_pid = @@spid and qat_fecha_ini = d_fecha_ini and qat_fecha_ven = d_fecha_ven

   if ((@w_i + 1 - @w_j) = 10)
      update ca_qr_amortiza_tmp set qat_rubro10 = d_saldo_cuota
      from #tmp_dividendo where qat_dividendo = d_dividendo and d_qrt_id = @w_i and qat_pid = @@spid and qat_fecha_ini = d_fecha_ini and qat_fecha_ven = d_fecha_ven

   if ((@w_i + 1 - @w_j) = 11)
      update ca_qr_amortiza_tmp set qat_rubro11 = d_saldo_cuota
      from #tmp_dividendo where qat_dividendo = d_dividendo and d_qrt_id = @w_i and qat_pid = @@spid and qat_fecha_ini = d_fecha_ini and qat_fecha_ven = d_fecha_ven

   if ((@w_i + 1 - @w_j) = 12)
      update ca_qr_amortiza_tmp set qat_rubro12 = d_saldo_cuota
      from #tmp_dividendo where qat_dividendo = d_dividendo and d_qrt_id = @w_i and qat_pid = @@spid and qat_fecha_ini = d_fecha_ini and qat_fecha_ven = d_fecha_ven

   if ((@w_i + 1 - @w_j) = 13)
      update ca_qr_amortiza_tmp set qat_rubro13 = d_saldo_cuota
      from #tmp_dividendo where qat_dividendo = d_dividendo and d_qrt_id = @w_i and qat_pid = @@spid and qat_fecha_ini = d_fecha_ini and qat_fecha_ven = d_fecha_ven

   if ((@w_i + 1 - @w_j) = 14)
      update ca_qr_amortiza_tmp set qat_rubro14 = d_saldo_cuota
      from #tmp_dividendo where qat_dividendo = d_dividendo and d_qrt_id = @w_i and qat_pid = @@spid and qat_fecha_ini = d_fecha_ini and qat_fecha_ven = d_fecha_ven

   if ((@w_i + 1 - @w_j) = 15)
      update ca_qr_amortiza_tmp set qat_rubro15 = d_saldo_cuota
      from #tmp_dividendo where qat_dividendo = d_dividendo and d_qrt_id = @w_i and qat_pid = @@spid and qat_fecha_ini = d_fecha_ini and qat_fecha_ven = d_fecha_ven           
      
   select @w_i = @w_i + 1
   
end


/* Se actualizan valores de rubros que sean negativos a cero (0) */
select @w_i = 1

while @w_i <= 15
begin
   if @w_i = 1
      update ca_qr_amortiza_tmp set qat_rubro1 = 0 where qat_rubro1 < 0
      and qat_pid = @@spid
   
   if @w_i = 2
      update ca_qr_amortiza_tmp set qat_rubro2 = 0 where qat_rubro2 < 0
      and qat_pid = @@spid

   if @w_i = 3
      update ca_qr_amortiza_tmp set qat_rubro3 = 0 where qat_rubro3 < 0
      and qat_pid = @@spid

   if @w_i = 4
      update ca_qr_amortiza_tmp set qat_rubro4 = 0 where qat_rubro4 < 0
      and qat_pid = @@spid

   if @w_i = 5
      update ca_qr_amortiza_tmp set qat_rubro5 = 0 where qat_rubro5 < 0
      and qat_pid = @@spid
   
   if @w_i = 6
      update ca_qr_amortiza_tmp set qat_rubro6 = 0 where qat_rubro6 < 0
      and qat_pid = @@spid

   if @w_i = 7
      update ca_qr_amortiza_tmp set qat_rubro7 = 0 where qat_rubro7 < 0
      and qat_pid = @@spid

   if @w_i = 8
      update ca_qr_amortiza_tmp set qat_rubro8 = 0 where qat_rubro8 < 0
      and qat_pid = @@spid

   if @w_i = 9
      update ca_qr_amortiza_tmp set qat_rubro9 = 0 where qat_rubro9 < 0
      and qat_pid = @@spid

   if @w_i = 10
      update ca_qr_amortiza_tmp set qat_rubro10 = 0 where qat_rubro10 < 0
      and qat_pid = @@spid

   if @w_i = 11
      update ca_qr_amortiza_tmp set qat_rubro11 = 0 where qat_rubro11 < 0
      and qat_pid = @@spid

   if @w_i = 12
      update ca_qr_amortiza_tmp set qat_rubro12 = 0 where qat_rubro12 < 0
      and qat_pid = @@spid

   if @w_i = 13
      update ca_qr_amortiza_tmp set qat_rubro13 = 0 where qat_rubro13 < 0
      and qat_pid = @@spid

   if @w_i = 14
      update ca_qr_amortiza_tmp set qat_rubro14 = 0 where qat_rubro14 < 0
      and qat_pid = @@spid

   if @w_i = 15
      update ca_qr_amortiza_tmp set qat_rubro15 = 0 where qat_rubro15 < 0
      and qat_pid = @@spid

   select @w_i = @w_i + 1
end


/* Actualización de valores de cuotas en negativo a cero (0) */
update ca_qr_amortiza_tmp
set qat_cuota = 0
where qat_cuota < 0
and   qat_pid   = @@spid


/* Actualización de columna de Saldo de Capital */
select @w_num_cuota = 1

while 1 = 1
begin
    select @w_saldo_cap = 0

    select @w_saldo_cap = sum(qat_rubro1)
    from   ca_qr_amortiza_tmp
    where  qat_dividendo >= @w_num_cuota
    and    qat_pid = @@spid

    if isnull(@w_saldo_cap, 0) = 0
    break

    update ca_qr_amortiza_tmp
    set qat_saldo_cap = @w_saldo_cap
    where qat_dividendo = @w_num_cuota
    and   qat_pid       = @@spid

    select @w_num_cuota = @w_num_cuota + 1
end


return 0


ERROR:

exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_error

return @w_error

go
