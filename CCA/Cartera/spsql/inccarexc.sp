/************************************************************************/
/*   Archivo:              inccarexc.sp                                 */
/*   Stored procedure:     sp_incentivos_carga_excepciones              */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Juan Carlos Guzmán                           */
/*   Fecha de escritura:   07/12/2022                                   */
/************************************************************************/
/*                        IMPORTANTE                                    */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad de     */
/*  COBISCORP.                                                          */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado  hecho por alguno de sus            */
/*  usuarios sin el debido consentimiento por escrito de COBISCORP.     */
/*  Este programa esta protegido por la ley de derechos de autor        */
/*  y por las convenciones  internacionales   de  propiedad inte-       */
/*  lectual.    Su uso no  autorizado dara  derecho a COBISCORP para    */
/*  obtener ordenes  de secuestro o retencion y para  perseguir         */
/*  penalmente a los autores de cualquier infraccion.                   */
/************************************************************************/
/*                              PROPOSITO                               */
/* Proceso batch que realizará BCP IN para cargar excepciones para el   */
/* cálculo de incentivos                                                */
/************************************************************************/
/*                               CAMBIOS                                */
/* FECHA          AUTOR           RAZÓN                                 */
/* 07/12/2022     J. Guzman       Versión inicial                       */
/************************************************************************/

use cob_cartera
go

if exists(select 1 from sysobjects where name ='sp_incentivos_carga_excepciones')
   drop proc sp_incentivos_carga_excepciones
go

create procedure sp_incentivos_carga_excepciones
(
   @t_debug        char(1)      = 'N',
   @s_culture      varchar(10)  = 'NEUTRAL',
   @i_param1       smallint,    -- Año
   @i_param2       tinyint,     -- Mes
   @i_param3       char(1)      -- Tipo de Excepción
)
as 

declare @w_sp_name            descripcion,
        @w_anio               smallint,
        @w_mes                tinyint,
        @w_tipo_excepcion     char(1),
        @w_sarta              int,
        @w_batch              int,
        @w_retorno_ej         int,
        @w_error              int,
        @w_mensaje            varchar(200),
        @w_fecha_proc         datetime,
        @w_fecha_proc_resta   datetime,
        @w_anio_fecproc       smallint,
        @w_mes_fecproc        tinyint,
        @w_cod_prod_cca       smallint,
        @w_sql                varchar(255),
        @w_tipo_bcp           varchar(10), 
        @w_separador          varchar(1),
        @w_nombre_arch        varchar(255),
        @w_return             int,
        @w_oficial            smallint,
        @w_monto              money,
        @w_comentario         varchar(255)
        
select @w_sp_name        = 'sp_incentivos_carga_excepciones',
       @w_anio           = @i_param1,
       @w_mes            = @i_param2,
       @w_tipo_excepcion = @i_param3
       
-- CULTURA
exec cobis..sp_ad_establece_cultura                                                                                                                                                                                                                         
   @o_culture = @s_culture out
   
-- Código de producto CCA
select @w_cod_prod_cca = pd_producto
from cobis..cl_producto
where pd_abreviatura = 'CCA'
       
-- Información proceso batch
select @w_sarta = lo_sarta,
       @w_batch = lo_batch
from cobis..ba_log,
     cobis..ba_batch
where ba_arch_fuente like '%cob_cartera..sp_incentivos_carga_excepciones%'
and   lo_batch   = ba_batch
and   lo_estatus = 'E'

-- Fecha de Proceso
select @w_fecha_proc = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = @w_cod_prod_cca

select @w_fecha_proc_resta = dateadd(mm, -1, @w_fecha_proc)

/* Validación de rango de meses */
if (@w_mes < 1 or @w_mes > 12)
begin
   /* El mes ingresado no corresponde a un valor correcto, favor revisar los parámetros de entrada */
   select @w_error  = 725208 
   
   goto ERROR
end

/* Validaciones de año y mes */
if (year(@w_fecha_proc_resta) = @w_anio and month(@w_fecha_proc_resta) > @w_mes) or
   (year(@w_fecha_proc_resta) > @w_anio) or
   (month(@w_fecha_proc) = 1 and (@w_anio < year(@w_fecha_proc_resta))) or
   (month(@w_fecha_proc) = 1 and (@w_anio = year(@w_fecha_proc_resta) and @w_mes != 12))
begin
   /* Año y mes de procesamiento no pueden ser menores que el del último proceso de Incentivos */
   select @w_error  = 725206 
   
   goto ERROR
end



/* Tabla temporal para BCP IN */
if exists (select 1 from sysobjects where name = '##ca_incentivos_excepciones_tmp')
   drop table ##ca_incentivos_excepciones_tmp
   
if @@error != 0
begin
   /* Error al eliminar tabla temporal #ca_incentivos_excepciones_tmp */
   select @w_error  = 725201 
   
   goto ERROR
end

create table ##ca_incentivos_excepciones_tmp (
   iet_oficial              smallint       not null,
   iet_monto                money          not null
)

if @@error != 0
begin
   /* Error al crear tabla temporal #ca_incentivos_excepciones_tmp */
   select @w_error  = 725202
   
   goto ERROR
end

if @w_tipo_excepcion = '3'
begin
   alter table ##ca_incentivos_excepciones_tmp
   add iet_comentarios_ajuste varchar(255)
end


/* Seteo variables para BCP IN */

select @w_sql       = '##ca_incentivos_excepciones_tmp',
       @w_tipo_bcp  = 'in',
       @w_separador = ';'

select @w_nombre_arch = ba_path_fuente 
from cobis..ba_batch
where ba_producto     = @w_cod_prod_cca
and   ba_arch_fuente  = 'cob_cartera..sp_incentivos_carga_excepciones'

select @w_nombre_arch = case @w_tipo_excepcion
                           when '1' then @w_nombre_arch + 'INCENTIVOS-EXCEPCIONES-MONTOS-CASTIGOS-REALES.csv'
                           when '2' then @w_nombre_arch + 'INCENTIVOS-EXCEPCIONES-MONTOS-MORA-REAL-OFICIAL.csv'
                           when '3' then @w_nombre_arch + 'INCENTIVOS-EXCEPCIONES-AJUSTES-MONTO-INCENTIVO.csv'
                        end


exec @w_return          = cobis..sp_bcp_archivos
     @i_sql             = @w_sql,           --select o nombre de tabla para generar archivo plano
     @i_tipo_bcp        = @w_tipo_bcp,      --tipo de bcp in,out,queryout
     @i_rut_nom_arch    = @w_nombre_arch,   --ruta y nombre de archivo
     @i_separador       = @w_separador      --separador

if @w_return != 0
begin
   /* Error en proceso BCP IN de carga de excepciones para incentivos */
   select @w_error = 725203
  
   goto ERROR
end

begin tran

delete from ca_incentivos_excepciones
where ie_anio           = @w_anio
and   ie_mes            = @w_mes
and   ie_tipo_excepcion = @w_tipo_excepcion

if @@error != 0 
begin
   /* Error en eliminacion tabla ca_incentivos_excepciones */
   select @w_error = 707083
   
   rollback tran
   
   goto ERROR
end

declare cur_carga_excepciones cursor for 
select iet_oficial, iet_monto
from ##ca_incentivos_excepciones_tmp
    
open cur_carga_excepciones
   
fetch next from cur_carga_excepciones into
@w_oficial, @w_monto

while (@@fetch_status = 0)
begin
   if (@@fetch_status = -1)
   begin
      select @w_error  = 710004

      close cur_carga_excepciones    
      deallocate cur_carga_excepciones
      
      rollback tran

      goto ERROR
   end
   
   /* Validación del Oficial */
   if not exists(select 1 
                 from cobis..cc_oficial
                 where oc_oficial = @w_oficial)
   begin
      /* Se detectaron códigos de oficiales en el archivo de carga inexistentes en Cobis, 
         favor revisar su contenido */
      select @w_error = 725204
      
      close cur_carga_excepciones    
      deallocate cur_carga_excepciones
      
      rollback tran
      
      goto ERROR
   end
   
   if @w_tipo_excepcion = '3'
   begin
      select @w_comentario = iet_comentarios_ajuste
      from ##ca_incentivos_excepciones_tmp
      where iet_oficial = @w_oficial
      and   iet_monto   = @w_monto
   end
   
   insert into ca_incentivos_excepciones(
      ie_oficial,        ie_anio,   ie_mes,
      ie_tipo_excepcion, ie_monto,  ie_comentarios_ajuste)
   values(
      @w_oficial,        @w_anio,   @w_mes,
      @w_tipo_excepcion, @w_monto,  @w_comentario)
      
   if @@error != 0 
   begin
      /* Error al insertar registro de excepción en tabla ca_incentivos_excepciones */
      select @w_error = 725205
      
      close cur_carga_excepciones
      deallocate cur_carga_excepciones
      
      rollback tran
      
      goto ERROR
   end 
   
   fetch next from cur_carga_excepciones into
   @w_oficial, @w_monto
   
end -- end while

commit tran

close cur_carga_excepciones    
deallocate cur_carga_excepciones


return 0


ERROR:
   select @w_mensaje = re_valor
   from cobis..cl_errores inner join cobis..ad_error_i18n on (numero = pc_codigo_int
      and re_cultura like '%'+@s_culture+'%')
   where numero = @w_error

   exec @w_retorno_ej = cobis..sp_ba_error_log
      @i_sarta   = @w_sarta,
      @i_batch   = @w_batch,
      @i_error   = @w_error,
      @i_detalle = @w_mensaje

   if @w_retorno_ej > 0
   begin
      return @w_retorno_ej
   end
   else
   begin
      return @w_error
   end

go
