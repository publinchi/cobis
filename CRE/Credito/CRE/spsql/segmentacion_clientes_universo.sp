/************************************************************************/
/*   Archivo:             segmentacion_clientes_universo.sp             */
/*   Stored procedure:    segmentacion_clientes_universo                */
/*   Base de datos:       cob_credito                                   */
/*   Producto:            Credito                                       */
/*   Disenado por:        Bruno Duenas                                  */
/*   Fecha de escritura:  14/Septiembre/2023                            */
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
/*   sitio, queda expresamente prohibido sin el debido                  */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada y por lo tanto, derivará en acciones legales civiles       */
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/
/*                     PROPOSITO                                        */
/*   Se genera el universo para la segmentacion de clientes             */
/************************************************************************/
/*                          MODIFICACIONES                              */
/* FECHA                    AUTOR                       RAZON           */
/* 10/Octubre/2023          BDU                Emision Inicial          */
/* 17/Octubre/2023          BDU                Correccion de campos     */
/* 19/Octubre/2023          BDU                Correccion updates campos*/
/* 17/Noviembre/2023        BDU                R219551-Agregar top 1    */
/************************************************************************/

use cob_credito
go
set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1 
           from sysobjects 
           where name = 'segmentacion_clientes_universo')
begin
   drop proc segmentacion_clientes_universo
end   
go

create procedure segmentacion_clientes_universo
as
declare @w_tiempo                   int,
        @w_sarta                    int,
        @w_batch                    int,
        @w_producto                 catalogo,
        @w_fecha_actual             datetime,
        @w_error                    int,    
        @w_variables                varchar(64),
        @w_return_variable          varchar(25),
        @w_return_results           varchar(25),
        @w_last_condition_parent    varchar(10),
        @w_return_results_rule      varchar(25),
        @w_id                       int,
        @w_mensaje                  varchar(250),
        @w_retorno_ej               int,
        @w_termina                  bit,
        @w_num_ciclos               int,
        @w_ingreso                  money,
        @w_resultado_segmento       catalogo,
        @w_resultado_subsegmento    catalogo,
        @w_resultado_rango          catalogo,
        @w_riesgo_zona_negocio      catalogo,
        @w_riesgo_zona_domicilio    catalogo,
        @w_parroquia_neg            catalogo,
        @w_parroquia_dom            catalogo,
        @w_tipo_negocio             catalogo,
        @w_categoria                catalogo,
        @w_puntaje                  int,
        @w_nivel                    catalogo,
        @w_ipp                      int,
        @w_hilos                    tinyint,
        @w_num_registros            int,
        @w_num_registros_max        int,
        @w_num_registros_min        int,
        @w_tamanio_lote             int,
        @w_count_hilos              int
        
        
-- Información proceso batch

select @w_termina = 0

select @w_sarta = lo_sarta,
       @w_batch = lo_batch
from cobis..ba_log,
     cobis..ba_batch
where ba_arch_fuente like '%cob_credito..segmentacion_clientes_universo%'
and   lo_batch   = ba_batch
and   lo_estatus = 'E'
if @@rowcount = 0
begin
   select @w_termina = 1
   select @w_error  = 808071 
   goto ERROR
end
/*
select @w_sarta = 8008,
       @w_batch = 21006
 */
--Parametros
select @w_tiempo = isnull(pa_int, 1)
from cobis..cl_parametro
where pa_nemonico = 'DBHS'
and pa_producto   = 'CLI'



select @w_fecha_actual = getdate()
--Limpieza de la tabla solo registros del dia actual
delete from cr_segmentacion_cliente
where convert(date, sc_fecha) = convert(date, @w_fecha_actual)

--Limpieza de la tabla segun tiempo de validez
delete from cr_segmentacion_cliente
where sc_fecha < dateadd(day, @w_tiempo * -1, @w_fecha_actual)

--Dejar en 0 las tablas 
select  @w_count_hilos       = 0,
        @w_num_registros_max = 0,
        @w_num_registros_min = 1,
        @w_tamanio_lote      = 0


truncate table cr_universo_segmentacion
truncate table cr_hilos_segmentacion

--print 'Generando Universo'
/* INSERCION DE REGISTROS REGISTROS DE INFORMACION DEL CLIENTE*/
insert into cr_universo_segmentacion
(us_ente, us_categoria, us_ciclos)
select  DISTINCT op_cliente, en_calificacion, isnull(en_nro_ciclo, 0)
from cob_cartera.dbo.ca_operacion with (NOLOCK)
inner join cobis..cl_ente on op_cliente = en_ente
where op_estado not in (0, 99, 3, 6) --No vigente, vencido, cancelado, anulado
and  (op_grupal = 'N' or (op_grupal = 'S' and op_ref_grupal is not null))
--print 'Ingresando ingresos'
--Ingresos
update cr_universo_segmentacion
set us_ingreso = (select case when exists (select 1
                                           from cobis.dbo.cl_analisis_negocio
                                           where an_cliente_id  = us_ente)
                  then (select top 1 (isnull(sum(an_ventas_prom_mes), 0) * 12)
                        from cobis.dbo.cl_analisis_negocio
                        where an_cliente_id  = us_ente)
                  else 0
                  end)
--print 'Ingresando Ipp'
--Ipp
update cr_universo_segmentacion
set us_ipp = (select case when exists(select 1 
                                      from cobis.dbo.cl_puntaje_ppi_ente pe
                                      where pe.ppe_ente = us_ente) 
              then (select top 1 isnull(ppe_score, 0)
                    from cobis.dbo.cl_puntaje_ppi_ente pe
                    where ppe_fecha = (select max(ppe_fecha) 
                                       from cobis.dbo.cl_puntaje_ppi_ente
                                       where ppe_ente = pe.ppe_ente)
                    and ppe_ente = us_ente)
              else 0
              end)
--print 'Ingresando Tipo negocio'
--Tipo negocio
update cr_universo_segmentacion
set us_tipo_neg = (select top 1 nc_tipo_local
                   from cobis..cl_negocio_cliente
                   inner join cobis..cl_analisis_negocio on isnull(an_negocio_codigo, 0) = nc_codigo and an_cliente_id = us_ente
                   where an_ventas_prom_mes = (select max(an_ventas_prom_mes)
                                                                      from cobis.dbo.cl_analisis_negocio
                                                                      where an_cliente_id = us_ente)
                   and nc_ente = us_ente)
--print 'Ingresando Riego zona negocio'
--Riego zona negocio
update cr_universo_segmentacion
set us_riesgo_zona_negocio = (select top 1 (case 
                                      when (select 1 from cobis..cl_catalogo cc 
                                      inner join cobis..cl_tabla ct on cc.tabla = ct.codigo 
                                      where ct.tabla = 'cl_riesgo_zona'and ct.codigo = isnull(di_parroquia, 0)) is not null 
                                      then '1'
                                      else '0' end)
                                      from cobis..cl_direccion 
                                      inner join cobis..cl_analisis_negocio on isnull(an_negocio_codigo, 0) = di_negocio and an_cliente_id = us_ente
                                      where an_ventas_prom_mes = (select max(an_ventas_prom_mes)
                                                                                         from cobis.dbo.cl_analisis_negocio
                                                                                         where an_cliente_id = us_ente)
                                      and di_ente = us_ente)
--print 'Ingresando Riesgo zona domicilio'
--Riesgo zona domicilio
update cr_universo_segmentacion
set us_riesgo_zona_domicil = (select top 1 (case 
                                            when not exists(select 1 from cobis..cl_catalogo cc 
                                            inner join cobis..cl_tabla ct on cc.tabla = ct.codigo 
                                            where ct.tabla = 'cl_riesgo_zona'and ct.codigo = isnull(di_parroquia, 0))
                                            then '1'
                                            else '0' end) as puntaje
                                    from cobis..cl_direccion
                                    where di_tipo = 'RE'
                                    and di_ente = us_ente)
/*
*/
--print 'Termina generacion universo'
--print 'Inicia generacion hilos'
--CREACION HILOS
select @w_hilos = 15

select @w_fecha_actual = getdate()


select @w_num_registros = count(1) from cr_universo_segmentacion
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
        insert into cr_hilos_segmentacion
        (hs_hilo, hs_inicio, hs_fin, hs_estado)
        values
        (@w_count_hilos, @w_num_registros_min  , @w_num_registros, 'I')
        break
    end
    else
    begin
        insert into cr_hilos_segmentacion
        (hs_hilo, hs_inicio, hs_fin, hs_estado)
        values
        (@w_count_hilos, @w_num_registros_min , @w_num_registros_max , 'I')
    end
    
    select  @w_num_registros_min = @w_num_registros_max + 1,
            @w_num_registros_max = @w_num_registros_max + @w_tamanio_lote
end
--print 'Termina generacion hilos'
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
