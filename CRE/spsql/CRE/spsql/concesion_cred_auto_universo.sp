/************************************************************************/
/*   Archivo:             concesion_cred_auto_universo.sp               */
/*   Stored procedure:    concesion_cred_auto_universo                  */
/*   Base de datos:       cob_credito                                   */
/*   Producto:            Credito                                       */
/*   Disenado por:        Dilan Morales                                 */
/*   Fecha de escritura:  11-Septiembre-2023                            */
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
/*   Se registran los clientes que aplican a un credito automatico      */
/************************************************************************/
/*                          MODIFICACIONES                              */
/* FECHA                    AUTOR                       RAZON           */
/* 11/Sep/2023              DMO               Emision Inicial           */
/* 09/Nov/2023              DMO              R219021:Se cambia condición*/
/*                                           para dividendos vencidos   */
/************************************************************************/

use cob_credito
go
set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1 
           from sysobjects 
           where name = 'concesion_cred_auto_universo')
begin
   drop proc concesion_cred_auto_universo
end   
go

create procedure concesion_cred_auto_universo
as
declare @w_tiempo                   int,
        @w_sarta                    int,
        @w_batch                    int,
        @w_producto                 catalogo,
        @w_fecha_actual             date,
        @w_error                    int,    
        @w_num_ciclos               int,
        @w_creditos_activos         int,
        @w_creditos_auto            int,
        @w_mensaje                  varchar(250),
        @w_retorno_ej               int,
        @w_termina                  bit,
        @w_hilos                    tinyint,
        @w_num_registros            int,
        @w_num_registros_max        int,
        @w_num_registros_min        int,
        @w_tamanio_lote             int,
        @w_count_hilos              int
        
        
-- Informacion proceso batch
print 'INICIO PROCESO concesion_cred_auto_universo: '  + convert(varchar, getdate(),120)
select @w_termina = 0
select @w_sarta = lo_sarta,
       @w_batch = lo_batch
from cobis..ba_log,
     cobis..ba_batch
where ba_arch_fuente like '%cob_credito..concesion_cred_auto_universo%'
and   lo_batch   = ba_batch
and   lo_estatus = 'E'
if @@rowcount = 0
begin
   select @w_termina = 1
   select @w_error  = 808071 
   goto ERROR
end

--Parametros
select @w_producto = pa_char
from cobis..cl_parametro
where pa_nemonico = 'PRCREA'
and pa_producto   = 'CRE'
if @w_producto is NULL
begin
   select @w_termina = 1
   select @w_error  = 725108 
   goto ERROR
end

select @w_tiempo = isnull(pa_int, 1)
from cobis..cl_parametro
where pa_nemonico = 'DBHCA'
and pa_producto   = 'CRE'

select @w_hilos = isnull(pa_int , 1)
from cobis..cl_parametro 
where pa_nemonico = 'PART' 
and pa_producto = 'CON'

select @w_fecha_actual = getdate()

--Limpieza de la tabla segun tiempo de validez
delete from cr_clientes_credautomatico
where cc_fecha < dateadd(day, @w_tiempo * -1, @w_fecha_actual) or convert(date, cc_fecha) = @w_fecha_actual

create table #tmp_clients (
   idCliente       int   null,
   idOficial       int   null,
   numCiclos       int   null,
   credActivos     int   null,
   credAutomica    int   null
)

create nonclustered index ix_idcliente
on #tmp_clients (idCliente)

create nonclustered index ix_idoficial
on #tmp_clients (idOficial)

print 'INICIO INSERT #tmp_clients: '  + convert(varchar, getdate(),120)
insert into #tmp_clients (idCliente)
select DISTINCT op_cliente
from cob_cartera..ca_operacion
where op_estado not in (0, 99, 3, 6)
and  (op_grupal = 'N' or (op_grupal = 'S' and op_ref_grupal is not null))
and op_operacion not in ( select am_operacion
						  from  cob_cartera..ca_dividendo,cob_cartera..ca_amortizacion 
						  where di_estado = 2 
						  and am_operacion = di_operacion 
						  and am_dividendo = di_dividendo 
						  and am_concepto  = 'CAP' 
						  and (am_cuota - am_pagado + am_gracia) > 0)
						  

delete  cl 
from #tmp_clients cl inner join 
(select distinct tr_cliente
from cob_credito..cr_tramite
inner join cob_credito..cr_gar_propuesta on gp_tramite = tr_tramite 
inner join cob_custodia..cu_custodia on cu_codigo_externo = gp_garantia 
where cu_garante is not null
and exists (
    select 1
    from cob_cartera..ca_operacion
	inner join (select am_operacion
                from  cob_cartera..ca_dividendo,cob_cartera..ca_amortizacion 
                where di_estado = 2 
                and am_operacion = di_operacion 
                and am_dividendo = di_dividendo 
                and am_concepto  = 'CAP' 
                and (am_cuota - am_pagado + am_gracia) > 0 )a 
	on a.am_operacion = op_operacion
    where op_cliente = cu_garante
    and op_estado not in (0, 99, 3, 6) -- no vigente, vencido, cancelado, anulado
    and (op_grupal = 'N' or (op_grupal = 'S' and op_ref_grupal is not null))
))  T on idCliente = T.tr_cliente

update #tmp_clients set idOficial = (select top 1 op_oficial
                                    from cob_cartera..ca_operacion
                                    where op_estado not in (0, 99, 3, 6)
                                    and  (op_grupal = 'N' or (op_grupal = 'S' and op_ref_grupal is not null))
                                    and op_operacion not in ( select am_operacion
															  from  cob_cartera..ca_dividendo,cob_cartera..ca_amortizacion 
															  where di_estado = 2 
															  and am_operacion = di_operacion 
															  and am_dividendo = di_dividendo 
															  and am_concepto  = 'CAP' 
															  and (am_cuota - am_pagado + am_gracia) > 0)
                                    and op_cliente = idCliente)
                                    
                                    
update #tmp_clients 
set numCiclos = (select isnull(en_nro_ciclo, 0)
                    from cobis..cl_ente
                    where en_ente = idCliente )
update #tmp_clients 
set credActivos = (select  count(1)
                    from cob_cartera..ca_operacion
                    where op_estado not in (0, 99, 3, 6) --No vigente, vencido, cancelado, anulado
                    and op_cliente    = idCliente
                    and op_toperacion <> @w_producto
                    and  (op_grupal = 'N' or (op_grupal = 'S' and op_ref_grupal is not null)))
                    
update #tmp_clients 
set credAutomica = (select count(1)
                    from cob_cartera..ca_operacion
                    where op_estado not in (0, 99, 3, 6) --No vigente, vencido, cancelado, anulado
                    and op_cliente    = idCliente
                    and op_toperacion = @w_producto
                    and  (op_grupal = 'N' or (op_grupal = 'S' and op_ref_grupal is not null)))

select  @w_count_hilos       = 0,
        @w_num_registros_max = 0,
        @w_num_registros_min = 1,
        @w_tamanio_lote      = 0


truncate table cr_universo_credautomatico
truncate table cr_hilos_credautomatico

insert into cr_universo_credautomatico
(uc_ente,   uc_oficial, uc_ciclos, uc_cred_act, uc_cred_aut)
select       
idCliente, idOficial, numCiclos, credActivos, credAutomica 
from   #tmp_clients  


--CREACION HILOS
select @w_num_registros = count(1) from cr_universo_credautomatico
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
        insert into cr_hilos_credautomatico
        (hc_hilo, hc_inicio, hc_fin, hc_estado)
        values
        (@w_count_hilos, @w_num_registros_min  , @w_num_registros, 'I')
        break
    end
    else
    begin
        insert into cr_hilos_credautomatico
        (hc_hilo, hc_inicio, hc_fin, hc_estado)
        values
        (@w_count_hilos, @w_num_registros_min , @w_num_registros_max , 'I')
    end
    
    select  @w_num_registros_min = @w_num_registros_max + 1,
            @w_num_registros_max = @w_num_registros_max + @w_tamanio_lote
end
print 'FIN PROCESO concesion_cred_auto_universo: '  + convert(varchar, getdate(),120)

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
