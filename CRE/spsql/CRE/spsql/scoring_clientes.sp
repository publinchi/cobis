/************************************************************************/
/*   Archivo:             scoring_clientes.sp                           */
/*   Stored procedure:    scoring_clientes                              */
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
/*   Se registra el puntaje de los clientes con creditos activos        */
/************************************************************************/
/*                          MODIFICACIONES                              */
/* FECHA                    AUTOR                       RAZON           */
/* 02/Marzo/2023            BDU                Emision Inicial          */
/* 03/Mayo/2023             BDU                Se eliminan registros del*/
/*                                             dia en que se ejecuta el */
/*                                             proceso (de existir)     */
/* 10/Octubre/2023          BDU              Ajustes redmine  - R217005 */
/************************************************************************/

use cob_credito
go
set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1 
           from sysobjects 
           where name = 'scoring_clientes')
begin
   drop proc scoring_clientes
end   
go

create procedure scoring_clientes(
    @i_param1 int null
)
as
declare @w_tiempo                   int,
        @w_sarta                    int,
        @w_batch                    int,
        @w_producto                 catalogo,
        @w_fecha_actual             datetime,
        @w_error                    int,
        @w_id                       int,
        @w_id_max                   int,
        @w_id_cli                   int,
        @w_mensaje                  varchar(250),
        @w_retorno_ej               int,
        @w_termina                  bit,
        @w_return                   int, 
        @w_valor_z                  float,
        @w_calculo                  float,
        @w_puntaje                  float,
        @w_tipo_cli                 char(1)
        
-- Información proceso batch

select @w_termina = 0
select @w_sarta = lo_sarta,
       @w_batch = lo_batch
from cobis..ba_log,
     cobis..ba_batch
where ba_arch_fuente like '%cob_credito..scoring_clientes'
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
       @w_batch = 21005	       
select @w_fecha_actual = getdate()
*/

print 'INICIO DE BUCLE: '  + convert(varchar, getdate(),120)
select @w_id = hs_inicio 
from cr_hilos_scoring
where hs_hilo = @i_param1

select @w_id_max = hs_fin 
from cr_hilos_scoring
where hs_hilo = @i_param1

while @w_id <= @w_id_max
begin
     ----print '********************** Registro ' + convert(varchar, @w_id) + ' **********************'
     select @w_tipo_cli = null,
            @w_id_cli   = null
            
     --Sacar subtipo
     select @w_tipo_cli = us_subtipo,
            @w_id_cli   = us_ente
     from cr_universo_scoring
     where us_id = @w_id
     
     --Sacar el valor de Z
     exec @w_return   = sp_scoring_cli
          @i_cliente  = @w_id_cli,
          @o_valor_z  = @w_valor_z out
     if @w_return <> 0
     begin
        select @w_error = @w_return
        goto ERROR
     end
     --Realizar calculos con el valor de Z
     select @w_calculo = EXP(@w_valor_z)/(1 + EXP(@w_valor_z))
     --Calculo del porcentaje
     select @w_puntaje = (1 - @w_calculo) * 100
	 --print 'Puntaje ' + convert(varchar, @w_puntaje)
     if @w_puntaje is not null
     begin
        --Por el momento se usa la estructura de cartera
        /*
        insert into cobis.dbo.cl_cliente_scoring(cs_fecha, cs_ente, cs_puntaje) 
        values(@w_fecha_actual, @w_id, @w_puntaje)
        */
        insert into cob_cartera.dbo.ca_cliente_calificacion(ca_ente ,ca_fecha_calif ,ca_puntos_operacion , ca_tipo_cliente)
        values(@w_id_cli, getdate(), @w_puntaje, @w_tipo_cli)
        if @@error <> 0
        begin
           select @w_mensaje = 'ERROR CALCULANDO EL PUNTAJE DEL CLIENTE ' + convert(varchar, @w_id)
           goto ERROR
        end
     end
   
   NEXT_LINE:
     select @w_id =  @w_id + 1
end
update cr_hilos_scoring
set hs_estado = 'P'
where hs_hilo = @i_param1

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
