/************************************************************************/
/*   Archivo:             scoring_clientes_universo.sp                  */
/*   Stored procedure:    scoring_clientes_universo                     */
/*   Base de datos:       cob_credito                                   */
/*   Producto:            Credito                                       */
/*   Disenado por:        Bruno Duenas                                  */
/*   Fecha de escritura:  02-Marzo-2023                                 */
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
/*   Se registra el universo para el proceso posterior de scoring       */
/************************************************************************/
/*                          MODIFICACIONES                              */
/* FECHA                    AUTOR                       RAZON           */
/* 10/Octubre/2023          BDU                Emision Inicial          */
/************************************************************************/

use cob_credito
go
set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1 
           from sysobjects 
           where name = 'scoring_clientes_universo')
begin
   drop proc scoring_clientes_universo
end   
go

create procedure scoring_clientes_universo
as
declare @w_tiempo                   int,
        @w_sarta                    int,
        @w_batch                    int,
        @w_producto                 catalogo,
        @w_fecha_actual             datetime,
        @w_error                    int,
        @w_id                       int,
        @w_mensaje                  varchar(250),
        @w_retorno_ej               int,
        @w_termina                  bit,
        @w_return                   int, 
        @w_valor_z                  float,
        @w_calculo                  float,
        @w_puntaje                  float,
        @w_tipo_cli                 char(1),
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
where ba_arch_fuente like '%cob_credito..scoring_clientes_universo%'
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
       @w_batch = 21015 
       */
--Parametros
select @w_tiempo = isnull(pa_int, 1)
from cobis..cl_parametro
where pa_nemonico = 'DBRSCO'
and pa_producto   = 'CLI'

select @w_fecha_actual = getdate()
--Limpieza de la tabla segun tiempo de validez y dia actual
delete from cob_cartera.dbo.ca_cliente_calificacion
where ca_fecha_calif < dateadd(day, @w_tiempo * -1, @w_fecha_actual)
or convert(date, ca_fecha_calif) = convert(date, @w_fecha_actual)


--Dejar en 0 las tablas 
select  @w_count_hilos       = 0,
        @w_num_registros_max = 0,
        @w_num_registros_min = 1,
        @w_tamanio_lote      = 0


truncate table cr_universo_scoring
truncate table cr_hilos_scoring

--Insercion de datos
insert into cr_universo_scoring
--Clientes con creditos activos
select DISTINCT op_cliente, en_subtipo
from cob_cartera.dbo.ca_operacion with (NOLOCK)
inner join cobis..cl_ente on en_ente = op_cliente
where op_estado not in (0, 99, 3, 6) --No vigente, vencido, cancelado, anulado
and  (op_grupal = 'N' or (op_grupal = 'S' and op_ref_grupal is not null))

print 'Inicia generacion hilos'
--CREACION HILOS

select @w_hilos = 15


select @w_num_registros = count(1) from cr_universo_scoring
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
        insert into cr_hilos_scoring
        (hs_hilo, hs_inicio, hs_fin, hs_estado)
        values
        (@w_count_hilos, @w_num_registros_min  , @w_num_registros, 'I')
        break
    end
    else
    begin
        insert into cr_hilos_scoring
        (hs_hilo, hs_inicio, hs_fin, hs_estado)
        values
        (@w_count_hilos, @w_num_registros_min , @w_num_registros_max , 'I')
    end
    
    select  @w_num_registros_min = @w_num_registros_max + 1,
            @w_num_registros_max = @w_num_registros_max + @w_tamanio_lote
end
print 'Termina generacion hilos'


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
