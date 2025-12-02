/************************************************************************/
/*   Archivo:             cacampoerr.sp                                 */
/*   Stored procedure:    sp_batch1                                     */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera - convenios                           */
/*   Disenado por:                                                      */
/*   Fecha de escritura:  JUL. 08.                                      */
/************************************************************************/
/*                              IMPORTANTE                              */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                              PROPOSITO                               */
/*   Procedimiento que realiza la ejecucion del fin de dia de           */
/*   cartera.                                                           */
/************************************************************************/
/*                              CAMBIOS                                 */
/*      FECHA              AUTOR             CAMBIOS                    */
/*     05-DIC-08          JUAN B. QUINCHE   SE ELIMINA LA BD RECHAZOS   */
/************************************************************************/
USE cob_cartera
GO
/****** Objeto:  StoredProcedure [dbo].[sp_campo_errado]    Fecha de la secuencia de comandos: 03/13/2009 14:35:52 ******/

if exists (select 1 from sysobjects where name = 'sp_campo_errado')
   drop proc sp_campo_errado
go
create  procedure [dbo].[sp_campo_errado]
@i_nombre_bd           varchar(32),
@i_nombre_tabla        varchar(32),
@i_dato_llave1         varchar(50),
@i_dato_llave2         varchar(50) = NULL,
@i_dato_llave3         varchar(50) = NULL,
@i_dato_llave4         varchar(50) = NULL,
@i_dato_llave5         varchar(50) = NULL,
@i_dato_llave6         varchar(50) = NULL,
@i_dato_llave7         varchar(50) = NULL,
@i_posicion            smallint,
@i_codigo_error        int,
@i_descripcion_error   varchar(150) = NULL,
@i_tipo_transaccion    int
as
   if @i_descripcion_error is null
   begin
      select @i_descripcion_error = mensaje
      from   cobis..cl_errores
      where  numero = @i_codigo_error
      
      if @@rowcount != 1
         return @i_codigo_error
   end

   insert into ca_campos_errados
         (ce_nombre_bd,        ce_nombre_tabla, ce_dato_llave1,   ce_dato_llave2,
          ce_dato_llave3,      ce_dato_llave4,  ce_dato_llave5,   ce_dato_llave6,
          ce_dato_llave7,      ce_posicion,     ce_codigo_error,  ce_descripcion_error,
          ce_tipo_transaccion)
   values(@i_nombre_bd,        @i_nombre_tabla, @i_dato_llave1,   @i_dato_llave2,
          @i_dato_llave3,      @i_dato_llave4,  @i_dato_llave5,   @i_dato_llave6,
          @i_dato_llave7,      @i_posicion,     @i_codigo_error,  @i_descripcion_error,
          @i_tipo_transaccion)
   
   if @@error != 0
      return @i_codigo_error
   
return 0
