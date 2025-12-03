/************************************************************************/
/*   Archivo:            carga_oper_conflicto.sp                        */
/*   Stored procedure:   sp_carga_oper_conflicto                        */
/*   Base de datos:      cob_cartera                                    */
/*   Producto:           CARTERA                                        */
/*   Fecha de escritura: Sep. 2015                                      */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                          PROPOSITO                                   */
/*                                                                      */
/* Proceso que permite cargar a traves de archivos planos las           */
/* operaciones a las cuales se les debe mantener la calificacion por    */
/* conflicto o victimas de hechos violentos.                            */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA              AUTOR         RAZON                              */
/*  Sep-24-2015      Luis Guzman   Emision Inicial                      */
/************************************************************************/

use cob_cartera
go

SET ANSI_NULLS OFF
GO

set nocount on

if exists (select 1 from sysobjects where name = 'sp_carga_oper_conflicto')
   drop proc sp_carga_oper_conflicto
go

create proc sp_carga_oper_conflicto
@i_param1  datetime     = null,   -- Fecha de Proceso
@i_param2  varchar(100) = null    -- Nombre del Archivo a Cargar

as
declare
   @w_sp_name         varchar(32),
   @w_fecha_proceso   datetime,
   @w_archivo         varchar(100),
   @w_msg             descripcion,
   @w_error           int,      
   @w_s_app           varchar(50),
   @w_path            varchar(50),
   @w_comando         varchar(1000)

/*INICIALIZA VARIABLES*/
select @w_sp_name     = 'sp_carga_oper_conflicto',       
       @w_fecha_proceso = @i_param1,
       @w_archivo       = @i_param2

---VALIDA QUE EL PARAMETRO Fecha de Proceso HAYA SIDO ENVIADO
if @i_param1 is null
begin
   select
   @w_msg       = 'ERROR, FECHA NO VALIDA EN PARAMETRO 1',
   @w_error     = 801085
   goto ERRORFIN
end

---VALIDA QUE EL PARAMETRO Nombre del Archivo HAYA SIDO ENVIADO
if @i_param2 is null
begin
   select
   @w_msg       = 'ERROR, NOMBRE DE ARCHIVO NO ENVIADO EN PARAMETRO 2',   
   @w_error     = 808007    
   goto ERRORFIN  
end

--- USO DE PARAMETROS 
select @w_s_app = pa_char
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'S_APP'

if @w_s_app is null
begin
   select 
   @w_msg       = 'ERROR CARGANDO PARAMETRO BCP',   
   @w_error     = 1      
   goto ERRORFIN
end

--- PATH ORIGEN 
select @w_path = pp_path_destino 
from   cobis..ba_path_pro
where  pp_producto = 7

if @w_path is null
begin
   select 
   @w_msg       = 'ERROR CARGANDO LA RUTA BATCH DE DESTINO, REVISAR PARAMETRIZACION',   
   @w_error     = 1           
   goto ERRORFIN
end  

/*SE BORRA Y SE CREA UNA TABLA TEMPORAL DONDE CARGAR EL ARCHIVO*/
if exists (select 1 from sysobjects where name = 'ca_carga_oper_conflicto_tmp')
   drop table ca_carga_oper_conflicto_tmp

create table ca_carga_oper_conflicto_tmp(
oct_tramite int
)

/* CARGAS EN VARIABLE @W_COMANDO*/
select @w_comando = @w_s_app + 's_app'+ ' bcp -auto -login cob_cartera..ca_carga_oper_conflicto_tmp in ' +
                    @w_path + @w_archivo + 
                    ' -c -e'+' conflicto_'+convert(varchar(10),@i_param1,112)+ '.err' + ' -t"|" ' + '-config '+ @w_s_app + 's_app.ini'

/* EJECUTAR CON CMDSHELL */
exec @w_error = xp_cmdshell @w_comando

if @w_error <> 0
begin
   select 
   @w_msg        = 'ERROR CARGANDO ARCHIVO, FAVOR VALIDAR EXISTENCIA DE ARCHIVO EN RUTA ESPECIFICADA',   
   @w_error      = 1
   goto ERRORFIN
end 
else
begin

   --BORRA DATOS A LA MISMA FECHA DE PROCESO
   delete from cob_cartera..ca_carga_oper_conflicto where oc_fecha_proceso = @i_param1

   if @@ERROR <> 0
   begin   
      select @w_msg   = 'ERROR AL ELIMINAR DATOS DE cob_cartera..ca_carga_oper_conflicto',
             @w_error = 708155
      goto  ERRORFIN
   end

   /*INSERTA DATOS EN LA TABLA DEFINITIVA*/
   insert into ca_carga_oper_conflicto
   select 
   @i_param1,
   NULL,
   oct_tramite,
   NULL,
   NULL,
   'N'
   from ca_carga_oper_conflicto_tmp
   
   if @@ERROR <> 0
   begin
      select @w_msg  = 'ERROR PASANDO DATOS A TABLA DEFINITIVA...',
             @w_error = 708154
      goto ERRORFIN
   end
end

update cob_cartera..ca_operacion set
op_numero_reest     = case when isnull(op_numero_reest,0) = 0 then 0 else op_numero_reest - 1 end
from cob_cartera..ca_carga_oper_conflicto
where op_tramite = oc_tramite
and   op_estado  = 1
and   oc_marca   = 'N'

if @@ERROR <> 0
begin
   select @w_msg   = 'ERROR ACTUALIZANDO MARCA REESTRUCTURADO EN cob_cartera..ca_operacion...',
          @w_error = 708152
   goto ERRORFIN
end

/*PROCESO DE ACTUALIZACION DE LA MARCA DE PROCESADO*/
update cob_cartera..ca_carga_oper_conflicto set
oc_marca = 'S'
from cob_cartera..ca_carga_oper_conflicto, cob_cartera..ca_operacion
where oc_tramite = op_tramite
and   op_estado  = 1
and   oc_marca   = 'N'

if @@ERROR <> 0
begin
   select @w_msg = 'ERROR ACTUALIZANDO MARCA EN cob_cartera..ca_carga_oper_conflicto...',
          @w_error = 708152
   goto ERRORFIN
end

set nocount off

return 0

ERRORFIN:
   print @w_msg

return @w_error
go
