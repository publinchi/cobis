/********************************************************************/
/*   NOMBRE LOGICO:         concesion_renovacion                    */
/*   NOMBRE FISICO:         concesion_renovacion.sp                 */
/*   BASE DE DATOS:         cob_credito                             */
/*   PRODUCTO:              Credito                                 */
/*   DISENADO POR:          D. Morales.                             */
/*   FECHA DE ESCRITURA:    03-Mar-2023                             */
/********************************************************************/
/*                     IMPORTANTE                                   */
/*   Este programa es parte de los paquetes bancarios que son       */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  */
/*   representantes exclusivos para comercializar los productos y   */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida */
/*   y regida por las Leyes de la República de España y las         */
/*   correspondientes de la Unión Europea. Su copia, reproducción,  */
/*   alteración en cualquier sentido, ingeniería reversa,           */
/*   almacenamiento o cualquier uso no autorizado por cualquiera    */
/*   de los usuarios o personas que hayan accedido al presente      */
/*   sitio, queda expresamente prohibido; sin el debido             */
/*   consentimiento por escrito, de parte de los representantes de  */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  */
/*   en el presente texto, causará violaciones relacionadas con la  */
/*   propiedad intelectual y la confidencialidad de la información  */
/*   tratada; y por lo tanto, derivará en acciones legales civiles  */
/*   y penales en contra del infractor según corresponda.           */
/********************************************************************/
/*                     PROPOSITO                                    */
/*   Se registran los clientes que aplican a una renovacion en sus  */
/*   creditos.                                                      */
/********************************************************************/
/*                     MODIFICACIONES                               */
/*   FECHA              AUTOR              RAZON                    */
/*   03-Mar-2023        D. Morales.        Emision Inicial          */
/*   23-Mar-2023        D. Morales.        Se añade correo de jefe  */
/*   24-Abr-2023        P. Jarrin.         S809618- SMS Proceso Ren.*/
/*   03-May-2023        D. Morales.        Eliminacion de registros */
/*                                         ingresados el mismo dia  */
/*   23-May-2023        D. Morales.        Se añade nuevos campos   */
/*                                         fecha_ven, saldo_capital */
/********************************************************************/

use cob_credito
go
set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1 
           from sysobjects 
           where name = 'concesion_renovacion')
begin
   drop proc concesion_renovacion
end   
go

create procedure concesion_renovacion(
 @i_param1       int        null
)
as
declare @w_tiempo                   int,
        @w_sarta                    int,
        @w_batch                    int,
        @w_fecha_actual             date,
        @w_error                    int,    
        @w_variables                varchar(64),
        @w_return_variable          varchar(25),
        @w_return_results           varchar(25),
        @w_last_condition_parent    varchar(10),
        @w_return_results_rule      varchar(25),
        @w_id_ente                  int,
        @w_id                       int,
        @w_id_max                   int,
        @w_id_cliente               int,
        @w_tramite                  int,
        @w_num_operacion            int,
        @w_num_op_banco             varchar(24),
        @w_toperacion               varchar(10),
        @w_grupo                    int,
        @w_nombre_grupo             varchar(254),
        @w_ref_op_padre             varchar(24),
        @w_id_oficial               int,
        @w_promedio_mora            int,
        @w_porcentaje_pag           int,
        @w_monto_total              money,
        @w_capital_pag              money,
        @w_mensaje                  varchar(250),
        @w_retorno_ej               int,
        @w_termina                  bit,
        @w_correo_oficial           varchar(200),
        @w_correo_jefe              varchar(200),
        @w_path                     varchar(254),
        @w_nom_ofi                  varchar(254),
        @w_ente                     int,    
        @w_tope                     varchar(10),
        @w_texto_msg                varchar(500),
        @w_desctope                 varchar(64),
        @w_telefono                 varchar(64),
        @w_fecha_ven                date,
        @w_saldo_capital            money

-- Informacion proceso batch
print 'INICIO PROCESO concesion_renovacion: '  + convert(varchar, getdate(),120)

print 'VALIDACION DE REGISTROS DEL HILO: '
if not exists(select 1
              from cr_hilos_renovacion
              where hr_hilo = @i_param1)
begin
   update cr_hilos_renovacion
   set hr_estado = 'P'
   where hr_hilo = @i_param1
   
   return 0
end
select @w_termina      = 0,
       @w_ente         = 0,
       @w_tope         = '',
       @w_texto_msg    = '',
       @w_desctope     = '',
       @w_telefono     = ''


select @w_sarta = lo_sarta,
       @w_batch = lo_batch
from cobis..ba_log,
     cobis..ba_batch
where ba_arch_fuente like '%cob_credito..concesion_renovacion'
and   lo_batch   = ba_batch
and   lo_estatus = 'E'
if @@rowcount = 0
begin
   select @w_termina = 1
   select @w_error  = 808071 
   goto ERROR
end

/*
select @w_sarta = 21000,
       @w_batch = 21004
*/

if not exists(select 1
              from cob_pac..bpl_rule BPL, cob_pac..bpl_rule_version RV
              where rl_acronym = 'VACRRE' 
              and rv_status = 'PRO'
              and BPL.rl_id = RV.rl_id)
begin
   select @w_termina = 1
   select @w_error  = 725109 
   goto ERROR
end
select @w_fecha_actual = getdate()

print 'INICIO DE BUCLE PARA EJECUCIÓN DE REGLA: '  + convert(varchar, getdate(),120)
select @w_id = hr_inicio 
from cr_hilos_renovacion
where hr_hilo = @i_param1

select @w_id_max = hr_fin 
from cr_hilos_renovacion
where hr_hilo = @i_param1

print 'Generando tablas temporales '
if (OBJECT_ID('tempdb.dbo.#tmp_dividendos','U')) is not null
begin
    drop table #tmp_dividendos
end

create table #tmp_dividendos (
dividendo       smallint        null,
fecha_ven       smalldatetime   null,
fecha_pag       smalldatetime   null,
num_operacion   int             null
)

create nonclustered index idx_dividendo
on #tmp_dividendos (dividendo)

create nonclustered index idx_num_operacion
on #tmp_dividendos (num_operacion)

if (OBJECT_ID('tempdb.dbo.#tmp_valores','U')) is not null
begin
    drop table #tmp_valores
end

create table #tmp_valores (
id               int             null,
ente             int             null,
tipo             varchar(10)     null,
saldo_capital    money           null,
fecha_ven        datetime        null,
grupo            int             null,
nombre_grupo     varchar(200)    null,
monto_total      money           null,
porcentaje       float           null,
num_operacion    int             null,
num_op_banco     varchar(24)     null,
id_oficial       int             null,
prom_mora        float           null
)

create nonclustered index idx_num_operacion
on #tmp_valores (num_operacion)


insert into #tmp_dividendos
(dividendo,     fecha_ven,      fecha_pag,  num_operacion)
select
di_dividendo,   di_fecha_ven,   null,       di_operacion
from cob_cartera..ca_dividendo 
inner join cob_credito.dbo.cr_universo_renovacion re on re.ur_num_operacion =  di_operacion
where di_estado = 3 --CANCELADO 
and re.ur_id between @w_id and @w_id_max --rangos

update #tmp_dividendos
set fecha_pag = (select max(tr_fecha_mov)
from cob_cartera..ca_transaccion
inner join cob_cartera..ca_det_trn on dtr_operacion = tr_operacion
where tr_tran = 'PAG'
and dtr_dividendo = dividendo
and tr_operacion = num_operacion
and tr_estado != 'REV')

insert into #tmp_valores
(id, ente, num_op_banco, tipo, saldo_capital, monto_total, grupo, nombre_grupo, fecha_ven, num_operacion, id_oficial)
select ur_id, ur_ente, ur_num_op_banco, ur_toperacion, (case when ur_ref_op_padre is not null then (select sum(am_pagado) from cob_cartera..ca_operacion 
                            inner join cob_cartera..ca_amortizacion on am_operacion  = op_operacion 
                            where op_ref_grupal = ur_ref_op_padre and am_concepto = 'CAP' ) 
                            else (select sum(am_pagado) 
                                  from cob_cartera..ca_amortizacion 
                                  where am_operacion = ren.ur_num_operacion 
                                  and am_concepto = 'CAP') end),
(case when ur_ref_op_padre is not null then (select op_monto from cob_cartera..ca_operacion where op_banco = ur_ref_op_padre) 
                            else (select op_monto from cob_cartera..ca_operacion where op_operacion = ren.ur_num_operacion) end),
ren.ur_grupo, (select gr_nombre from cobis..cl_grupo where gr_grupo = ren.ur_grupo ),
(select op_fecha_fin from cob_cartera..ca_operacion where op_operacion = ren.ur_num_operacion), ren.ur_num_operacion,
ren.ur_oficial
from cob_credito.dbo.cr_universo_renovacion ren
where ren.ur_id between @w_id and @w_id_max --rangos

update #tmp_valores
set prom_mora = (select isnull(avg(datediff(day ,fecha_ven, fecha_pag)),0)
                 from #tmp_dividendos div
                 where div.num_operacion = #tmp_valores.num_operacion)


update #tmp_valores
set porcentaje = convert(int, round((saldo_capital  * 100)/ monto_total, 0))


while @w_id <= @w_id_max
begin
    print 'Procesando registro ' + convert(varchar, @w_id)
    --SE BORRA DATA DE VARIABLES
    select 
    @w_id_cliente       = null,
    @w_toperacion       = null,
    @w_tramite          = null,
    @w_num_op_banco     = null,
    @w_ref_op_padre     = null,
    @w_grupo            = null,
    @w_id_oficial       = null,
    @w_capital_pag      = null,
    @w_monto_total      = null,
    @w_porcentaje_pag   = null,
    @w_nombre_grupo     = null,
    @w_saldo_capital    = 0,
    @w_fecha_ven        = null
    
    
    --OBTENER OPERACION
    select 
    @w_toperacion       = tipo,
    @w_porcentaje_pag   = porcentaje,
    @w_promedio_mora    = prom_mora
    from #tmp_valores 
    where id = @w_id


   select @w_variables = null , @w_return_results_rule = null, @w_return_results =null
   
   
   select @w_variables =  @w_toperacion + '|' + convert(varchar(10),@w_porcentaje_pag)+ '|'+  convert(varchar(10),@w_promedio_mora) 
    print 'Variables regla ' + @w_variables
   exec @w_error               = cob_pac..sp_rules_param_run
        @s_rol                   = 3,
        @i_rule_mnemonic         = 'VACRRE',
        @i_var_values            = @w_variables,
        @i_var_separator         = '|',
        @o_return_variable       = @w_return_variable  OUT,
        @o_return_results        = @w_return_results OUT,
        @o_last_condition_parent = @w_last_condition_parent out

   select @w_return_results_rule = replace(@w_return_results,'|','')
   if @w_error <> 0
   begin
      print 'Error en la regla'
   end
   
   print 'Resultado regla ' + isnull(@w_return_results_rule, 'Vacio')
   
   if(@w_return_results_rule = '0')
   begin  
        insert into cr_clientes_renovacion
        (cr_fecha,          cr_ente,        cr_num_banco,   cr_toperacion,  cr_grupo,   cr_nombre_grupo,    cr_saldo_capital,   cr_fecha_venc,      cr_oficial)
        select 
        @w_fecha_actual,    ente,           num_op_banco,   tipo,           grupo,      nombre_grupo,       saldo_capital,       fecha_ven,          id_oficial
        from #tmp_valores
        where id = @w_id
   end

   NEXT_LINE:
      set @w_id = @w_id + 1
end
print 'Termina' 
select @w_termina = 1
update cr_hilos_renovacion
set hr_estado = 'P'
where hr_hilo = @i_param1
return 0

ERROR:
   update cr_hilos_renovacion
   set hr_estado = 'E'
   where hr_hilo = @i_param1
   
   if @w_mensaje is null
   begin
      select @w_mensaje = mensaje
      from cobis..cl_errores 
      where numero = @w_error
   end
   
   if(@w_sarta is not null or @w_batch is not null)
   begin
      exec @w_retorno_ej = cobis..sp_ba_error_log
         @i_sarta   = @w_sarta,
         @i_batch   = @w_batch,
         @i_error   = @w_error,
         @i_detalle = @w_mensaje
   end
   if @w_termina = 0
   begin
      goto NEXT_LINE
   end
   if @w_retorno_ej > 0
   begin
      return @w_retorno_ej
   end
   else
   begin
      return @w_error
   end

go
