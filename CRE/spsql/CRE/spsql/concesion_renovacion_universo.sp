/********************************************************************/
/*   NOMBRE LOGICO:         concesion_renovacion_universo                    */
/*   NOMBRE FISICO:         concesion_renovacion_universo.sp                 */
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
/*   09-Nov-2023        D. Morales.        R219021:Se cambia condición*/
/*                                         para dividendos vencidos */
/********************************************************************/

use cob_credito
go
set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1 
           from sysobjects 
           where name = 'concesion_renovacion_universo')
begin
   drop proc concesion_renovacion_universo
end   
go

create procedure concesion_renovacion_universo
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
        @w_id                       int,
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
        @w_saldo_capital            money,
        @w_hilos                    tinyint,
        @w_num_registros            int,
        @w_num_registros_max        int,
        @w_num_registros_min        int,
        @w_tamanio_lote             int,
        @w_count_hilos              int
        
-- Información proceso batch

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
where ba_arch_fuente like '%cob_credito..concesion_renovacion_universo%'
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
       @w_batch = 21013
       */
--Parametros
select @w_tiempo = isnull(pa_int, 1)
from cobis..cl_parametro
where pa_nemonico = 'DBHCA'
and pa_producto   = 'CRE'

select @w_hilos = isnull(pa_int, 1)
from cobis..cl_parametro 
where pa_nemonico = 'PART' 
and pa_producto = 'CON'
select @w_fecha_actual = getdate()


--Limpieza de la tabla segun tiempo de validez
delete from cr_clientes_renovacion
where cr_fecha < dateadd(day, @w_tiempo * -1, @w_fecha_actual) 
or convert(date, cr_fecha) = convert(date, @w_fecha_actual)

--Creacion tabla temporal
/* CREACION DE TABLA TEMPORAL CON REGISTROS DE INFORMACION DEL CLIENTE*/
if (OBJECT_ID('tempdb.dbo.#tmp_clients','U')) is not null
begin
   drop table #tmp_clients
end

create table #tmp_clients (
   id_cliente       int         null,
   tramite          int         null,
   num_operacion    int         null,
   num_op_banco     varchar(24) null,
   toperacion       varchar(10) null,
   grupo            int         null,
   ref_op_padre     varchar(24) null,
   id_oficial       int         null
   
)
create nonclustered index idx_id_cliente
on #tmp_clients (id_cliente)

create nonclustered index idx_ref_op_padre
on #tmp_clients (ref_op_padre)



Print 'Generando universo inicial'
insert into #tmp_clients 
(id_cliente,    tramite,        num_operacion,  num_op_banco,   toperacion,     grupo,      ref_op_padre,   id_oficial)
select 
op_cliente,     op_tramite,     op_operacion,   op_banco,       op_toperacion,  op_grupo,   op_ref_grupal,  op_oficial
from cob_cartera..ca_operacion with (NOLOCK)
where op_estado not in (0, 99, 3, 6)
and  (op_grupal = 'N' or (op_grupal = 'S' and op_ref_grupal is not null))
and op_operacion not in ( select am_operacion
						  from  cob_cartera..ca_dividendo,cob_cartera..ca_amortizacion 
						  where di_estado = 2 
						  and am_operacion = di_operacion 
						  and am_dividendo = di_dividendo 
						  and am_concepto  = 'CAP' 
						  and (am_cuota - am_pagado + am_gracia) > 0)

Print 'Filtrando universo'
-- SE VERIFICA QUE LOS PARTICIPANTES NO ESTEN EN MORA
delete cl
from #tmp_clients cl
inner join cob_cartera..ca_operacion on op_ref_grupal = cl.ref_op_padre and op_ref_grupal is not null
where op_estado not in (0, 99, 3, 6)
and op_operacion in ( select am_operacion
					  from  cob_cartera..ca_dividendo,cob_cartera..ca_amortizacion 
					  where di_estado = 2 
					  and am_operacion = di_operacion 
					  and am_dividendo = di_dividendo 
					  and am_concepto  = 'CAP' 
					  and (am_cuota - am_pagado + am_gracia) > 0)
-- SE VERIFICA QUE FIADORES NO ESTAN EN MORA
delete cl 
from #tmp_clients cl
inner join cob_credito..cr_gar_propuesta on gp_tramite = cl.tramite  
inner join cob_custodia..cu_custodia on cu_codigo_externo = gp_garantia 
where cu_garante is not null
and exists (
select 1
from cob_cartera..ca_operacion
where op_cliente = cu_garante
and op_estado not in (0, 99, 3, 6) -- no vigente, vencido, cancelado, anulado
and (op_grupal = 'N' or (op_grupal = 'S' and op_ref_grupal is not null))
and op_operacion in ( select am_operacion
					  from  cob_cartera..ca_dividendo,cob_cartera..ca_amortizacion 
					  where di_estado = 2 
					  and am_operacion = di_operacion 
					  and am_dividendo = di_dividendo 
					  and am_concepto  = 'CAP' 
					  and (am_cuota - am_pagado + am_gracia) > 0))
-- SE VERIFICA QUE CODEUDORES NO ESTAN EN MORA   
delete cl
from #tmp_clients cl
inner join cob_credito..cr_deudores  on de_tramite  = cl.tramite  and de_rol != 'D'
inner join cob_cartera..ca_operacion on op_cliente  = de_cliente
where cl.ref_op_padre is null 
and  (op_grupal = 'N' or (op_grupal = 'S' and op_ref_grupal is not null)
and op_operacion in ( select am_operacion
					  from  cob_cartera..ca_dividendo,cob_cartera..ca_amortizacion 
					  where di_estado = 2 
					  and am_operacion = di_operacion 
					  and am_dividendo = di_dividendo 
					  and am_concepto  = 'CAP' 
					  and (am_cuota - am_pagado + am_gracia) > 0))
-- SE VERIFICA QUE GARANTIAS CON DUEÑOS  NO ESTAN EN MORA
delete #tmp_clients
from #tmp_clients tmp
inner join cob_credito..cr_gar_propuesta on gp_tramite = tmp.tramite  
inner join cob_custodia..cu_cliente_garantia on cg_codigo_externo = gp_garantia
inner join cob_cartera..ca_operacion on op_cliente  = cg_ente
where  tmp.id_cliente != cg_ente
and  (op_grupal = 'N' or (op_grupal = 'S' and op_ref_grupal is not null)
and op_operacion in ( select am_operacion
					  from  cob_cartera..ca_dividendo,cob_cartera..ca_amortizacion 
					  where di_estado = 2 
					  and am_operacion = di_operacion 
					  and am_dividendo = di_dividendo 
					  and am_concepto  = 'CAP' 
					  and (am_cuota - am_pagado + am_gracia) > 0))


select  @w_count_hilos       = 0,
        @w_num_registros_max = 0,
        @w_num_registros_min = 1,
        @w_tamanio_lote      = 0


truncate table cr_universo_renovacion
truncate table cr_hilos_renovacion

insert into cr_universo_renovacion
(ur_ente,   ur_oficial, ur_tramite, ur_num_operacion, ur_num_op_banco, ur_toperacion, ur_grupo, ur_ref_op_padre)
select       
id_cliente, id_oficial, tramite, num_operacion,num_op_banco, toperacion, grupo, ref_op_padre 
from   #tmp_clients  


--CREACION HILOS
select @w_num_registros = count(1) from cr_universo_renovacion
select @w_tamanio_lote = ceiling(@w_num_registros * 1.0 / @w_hilos)

if(@w_tamanio_lote = 1 )
begin
    select @w_tamanio_lote = 2
end 

select @w_num_registros_max = @w_num_registros_min + @w_tamanio_lote
while @w_count_hilos < @w_hilos
begin
    select @w_count_hilos  = @w_count_hilos + 1
     
    if (@w_count_hilos = @w_hilos) or (@w_num_registros_max  = @w_num_registros)
    begin
        insert into cr_hilos_renovacion
        (hr_hilo, hr_inicio, hr_fin, hr_estado)
        values
        (@w_count_hilos, @w_num_registros_min  , @w_num_registros, 'I')
        break
    end
    else
    begin
        insert into cr_hilos_renovacion
        (hr_hilo, hr_inicio, hr_fin, hr_estado)
        values
        (@w_count_hilos, @w_num_registros_min , @w_num_registros_max , 'I')
    end
    
    select  @w_num_registros_min = @w_num_registros_max + 1,
            @w_num_registros_max = @w_num_registros_max + @w_tamanio_lote
end

select @w_termina = 1
return 0

ERROR:
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
   if @w_retorno_ej > 0
   begin
      return @w_retorno_ej
   end
   else
   begin
      return @w_error
   end

go
