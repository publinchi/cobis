/************************************************************************/
/*Archivo               :    inserror.sp                                */
/*Stored procedure      :    sp_insertar_error                          */
/*Base de datos         :    cob_cartera                                */
/*Producto              :    Cartera                                    */
/*Disenado por          :    Fabian Quintero                            */
/*Fecha de escritura    :    mar 2007                                   */
/************************************************************************/
/* IMPORTANTE                                                           */
/* Este programa es parte de los paquetes bancarios propiedad de        */
/* 'MACOSA'.                                                            */
/* Su uso no autorizado queda expresamente prohibido asi como           */
/* cualquier alteracion o agregado hecho por alguno de sus              */
/* usuarios sin el debido consentimiento por escrito de la              */
/* Presidencia Ejecutiva de MACOSA o su representante.                  */
/*                                                                      */
/* PROPOSITO                                                            */
/* Poblar la tabla para extractos de créditos rotativos                 */
/* MODIFICACIONES                                                       */
/* FECHA        AUTOR           RAZON                                   */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'ca_errores_ts')
   drop table ca_errores_ts
go

create table ca_errores_ts
(er_numero      int,
 er_severidad   int,
 er_mensaje     varchar(255),
 er_fecha_hora  datetime)
go

--- SECCION:SP no quitar esta seccion
--- SP: sp_insertar_error
--- NRO: 1
--- PREFIJOERRORES: 7201
--- FINSECCION:SP no quitar esta seccion

if exists (select 1 from sysobjects where name = 'sp_insertar_error')
   drop proc sp_insertar_error
go

create proc sp_insertar_error
   @i_numero         int,
   @i_severidad      smallint,
   @i_mensaje        varchar(132)
as
declare
   @w_fecha_hora     datetime
begin
   select @w_fecha_hora = getdate()
   
   BEGIN TRAN
   
   if exists(select 1 from cobis..cl_errores where numero = @i_numero)
   begin
      insert into ca_errores_ts
            (er_numero, er_severidad, er_mensaje, er_fecha_hora)
      select numero,    severidad,    mensaje,    @w_fecha_hora
      from   cobis..cl_errores
      where  numero = @i_numero
      
      delete cobis..cl_errores where numero = @i_numero
      
      --print 'MENSAJE ,  REEMPLAZADO'+ @i_numero + @w_fecha_hora
   end
   
   insert into cobis..cl_errores
         (numero, severidad, mensaje)
   values(@i_numero, @i_severidad, @i_mensaje)
   
   if @@error != 0
   begin
      while @@trancount > 0 ROLLBACK
      print 'NO SE PUDO REGISTRAR EL MENSAJE CON CODIGO'+ cast(@i_numero as varchar)
      return 720101
   end
   ELSE
   begin
      COMMIT
   end
   return
end
go
