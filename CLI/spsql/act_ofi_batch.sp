/************************************************************************/
/*   Archivo:            act_ofi_batch.sp                               */
/*   Stored procedure:   sp_act_ofi_batch                               */
/*   Base de datos:      cobis                                          */
/*   Producto:           Clientes                                       */
/*   Disenado por:       BDU                                            */
/*   Fecha de escritura: 18-Junio-24                                    */
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
/*               PROPOSITO                                              */
/*   Este programa se ejecuta en un procedimiento batch                 */
/*   que traslada clientes/grupos de un oficial a otro                  */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*      FECHA           AUTOR           RAZON                           */
/*      18/06/24         BDU       R235692 - Emision Inicial            */
/************************************************************************/
use cobis

go

set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO

if exists (select 1 from sysobjects where name = 'sp_act_ofi_batch')
   drop proc sp_act_ofi_batch
go

create proc sp_act_ofi_batch

as 
declare @w_sarta                    int,
        @w_batch                    int,
        @w_fecha_actual             datetime,
        @w_error                    int,
        @w_retorno_ej               int,
        @w_id                       int,
        @w_mensaje                  varchar(300),
        @w_tabla                    varchar(100),
        @w_termina                  int,
        @w_tiempo                   int
        
        
-- Información proceso batch

select @w_termina = 0,
       @w_fecha_actual = getdate()


select @w_sarta = lo_sarta,
       @w_batch = lo_batch
from cobis..ba_log,
     cobis..ba_batch
where ba_arch_fuente like '%cobis..sp_act_ofi_batch%'
and   lo_batch   = ba_batch
and   lo_estatus = 'E'
if @@rowcount = 0
begin
   select @w_termina = 1
   select @w_error  = 808071 
   goto ERROR
end

--Tiempo de validez
select @w_tiempo = pa_int
from cobis..cl_parametro
where pa_nemonico = 'DBHCO'
and pa_producto = 'CLI'
--Borrar registros
if @w_tiempo is not null
begin
   delete from cobis..cl_act_ofi_batch
   where ob_fecha_act is not null
   and ob_fecha_act < DATEADD(DAY, -@w_tiempo, @w_fecha_actual)
end


if exists(select 1 from cobis..cl_act_ofi_batch where ob_fecha_act is null)
begin
   begin try
      BEGIN TRAN
         
         print('Actualizando clientes')
         set @w_tabla = 'cl_ente'
         update cobis..cl_ente
         set en_oficial = ob_ofi_nuevo
         from cl_act_ofi_batch
         where ob_codigo = en_ente
         and ob_tipo = 0
         and ob_fecha_act is null
         
         print('Actualizando grupos')
         set @w_tabla = 'cl_grupo'
         update cobis..cl_grupo
         set gr_oficial = ob_ofi_nuevo
         from cl_act_ofi_batch
         where ob_codigo = gr_grupo
         and ob_tipo = 1
         and ob_fecha_act is null
         
         print('Actualizando miembros')
         set @w_tabla = 'cl_cliente_grupo'
         update cobis..cl_cliente_grupo
         set cg_oficial = ob_ofi_nuevo
         from cl_act_ofi_batch
         inner join cobis.dbo.cl_cliente_grupo cg on cg_grupo = ob_codigo and cg_estado = 'V'
         where cg_ente = cg.cg_ente
         and ob_tipo = 1
         and ob_fecha_act is null
         
         set @w_tabla = 'cl_ente'
         update cobis..cl_ente
         set en_oficial = ob_ofi_nuevo
         from cl_act_ofi_batch
         inner join cobis.dbo.cl_cliente_grupo on cg_grupo = ob_codigo and cg_estado = 'V'
         where cg_ente = en_ente
         and ob_tipo = 1
         and ob_fecha_act is null
         
         print('Seteando fecha de actualizacion')
         set @w_tabla = 'cl_act_ofi_batch'
         update cl_act_ofi_batch
         set ob_fecha_act = @w_fecha_actual
         where ob_fecha_act is null
         
      COMMIT TRAN
   end try
   begin catch
      IF @@TRANCOUNT > 0
      begin
         ROLLBACK TRAN
      end
      select @w_mensaje =  '[' + ERROR_PROCEDURE() + '] <' + @w_tabla + '> ' + convert(varchar, ERROR_NUMBER()) + ' - ' +  ERROR_MESSAGE(),
             @w_error = 1647266
      goto ERROR
   end catch
end

print 'Termina proceso a las ' + convert(varchar, getdate(), 121)


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
