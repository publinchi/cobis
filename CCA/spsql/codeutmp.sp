/*codeutmp.sp************************************************************/
/*   Archivo:              codeutmp.sp                                  */
/*   Stored procedure:     sp_codeudor_tmp                              */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Credito Y Cartera                            */
/*   Disenado por:         Sandra Ortiz                                 */
/*   Fecha de escritura:   02-Jul-1994                                  */
/************************************************************************/
/*   IMPORTANTE                                                         */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*   PROPOSITO                                                          */
/*   Este programa registra a los codeudores de una operacion           */
/************************************************************************/
/*   MODIFICACIONES                                                     */
/*   FECHA        AUTOR             RAZON                               */
/*   02-Jul-1994  S.Ortiz           Emision Inicial                     */
/*   10/10/1994   Peter Espinosa    Manejo de codeudores para           */
/*                                  solicitudes                         */
/*   Mar 2006     Fabian Quintero   Defecto 6153                        */
/*   Abr 2006     Elcira Pelaez     Defecto 6171                        */
/*   May 2006     Elcira Pelaez     Defecto 6487                        */
/*   2008-03-31   Miguel Roa        Cobro Central de Riesgo             */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_codeudor_tmp')
   drop proc sp_codeudor_tmp
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

create proc sp_codeudor_tmp
   @s_sesn           int = null,
   @s_user           login = null,
   @t_trn            INT   = NULL,
   @i_operacion      cuenta,
   @i_codeudor       int,
   @i_ced_ruc        numero,
   @i_titular        int,
   @i_rol            catalogo,
   @i_borrar         char(1) = 'N',
   @i_secuencial     int,
   @i_externo        char(1) = 'S',
   @i_banco          cuenta  =  null,
   @i_desde_cre      char(1) = 'N',
   @i_central_riesgo char(1) = 'N'
as
declare
   @w_sp_name     varchar(30),
   @w_max_sec     int,
   @w_operacion   int,
   @w_estado      smallint,
   @w_op_tipo     char(1),
   @w_cliente     int,
   @w_tramite     int,
   @w_ced         numero,
   @w_msg         varchar(200),
   @w_error       int

/* VARIABLES DE TRABAJO */
select   
@w_sp_name = 'sp_codeudor_tmp',
@w_error   = 0,
@w_msg     = ''


/* DATOS DE LA OPERACION DE CARTERA */
select 
@w_estado    = opt_estado,
@w_operacion = opt_operacion,
@w_tramite   = opt_tramite,
@w_op_tipo   = isnull(opt_tipo, 'R')
from   ca_operacion_tmp
where  opt_banco = @i_banco
      
if @@rowcount = 0 begin

   select
   @w_estado    = op_estado,
   @w_operacion = op_operacion,
   @w_op_tipo   = isnull(op_tipo, 'R')
   from ca_operacion
   where op_banco = @i_banco
         
   if @@rowcount = 0 and @i_operacion != 'A' begin
      select 
      @w_msg   = 'Error consultado datos basicos de la obligacion'+ @i_banco +' ('+ @i_operacion+')',
      @w_error = 701049      
      goto ERROR
   end
end


/* ENTRAR BORRANDO AL ENVIAR EL PRIMER DEUDOR */
if @i_borrar = 'S'  begin

   delete   ca_cliente_tmp
   where    clt_user   = @s_user
   and      clt_sesion = @s_sesn

   if @@error <> 0 begin
      select
      @w_msg   = 'Error al limpiar la tabla ca_cliente_tmp',
      @w_error = 710003
      goto ERROR
   end


   /* LOS REGISTROS EN CA_DEUDORES_TMP SOLO SE CREAN CUANDO LA OPERACION SE DA DE ALTA EN CARTERA */
   if @i_desde_cre <> 'S' begin

      if @w_estado <> 0 begin

         delete ca_deudores_tmp
         where dt_banco = @i_banco

         if @@error <> 0 begin
            select
            @w_msg   = 'Error al limpiar la tabla ca_deudores_tmp (1)',
            @w_error = 710003
            goto ERROR
         end
      end
      
      if @w_estado = 0 begin

         delete ca_deudores_tmp
         where dt_operacion = @w_operacion

         if @@error <> 0 begin
            select
            @w_msg   = 'Error al limpiar la tabla ca_deudores_tmp (2)',
            @w_error = 710003
            goto ERROR
         end
      end
   end

end  -- if @i_borrar = 'S'

   
if @i_secuencial = 99 begin  --ESTO ES SOLO PARA PASIVAS DAG
   select @w_max_sec = isnull(max(clt_secuencial),0)
   from   ca_cliente_tmp
   where  clt_user   = @s_user
   and    clt_sesion = @s_sesn
      
   select @w_max_sec = @w_max_sec + 1
      
   if @w_max_sec < 99 select @w_max_sec = @i_secuencial
end

   
/* PARA SIMULACIONES */
if @i_titular is null select @i_titular = 0
if @i_rol     is null select @i_rol = 'D'

if @i_ced_ruc is null begin
   select @i_ced_ruc = en_ced_ruc
   from   cobis..cl_ente
   where  en_ente = @i_codeudor
end


/* DEF 6153, PARA EVITAR LLAVES DUPLICADAS */
delete ca_cliente_tmp
where  clt_user         = @s_user
and    clt_sesion       = @s_sesn
and    clt_secuencial   = @i_secuencial

if @@error <> 0 begin
   select
   @w_msg   = 'Error al limpiar la tabla ca_cliente_tmp (control duplicados 1)',
   @w_error = 710003
   goto ERROR
end
   
/* DEF 6153, PARA EVITAR LLAVES DUPLICADAS */
delete ca_cliente_tmp
where  clt_operacion = @i_operacion
and    clt_cliente   = @i_codeudor
and    clt_user      = @s_user

if @@error <> 0 begin
   select
   @w_msg   = 'Error al limpiar la tabla ca_cliente_tmp (control duplicados 2)',
   @w_error = 710003
   goto ERROR
end


/* REGISTRAR EL CLIENTE EN LA TABLA TEMPORAL */
insert into ca_cliente_tmp(
clt_user,     clt_sesion,    clt_operacion,
clt_cliente,  clt_rol,       clt_ced_ruc,
clt_titular,  clt_secuencial,clt_central_riesgo)
values(
@s_user,      @s_sesn,       @i_operacion,
@i_codeudor,  @i_rol,        @i_ced_ruc,
@i_titular,   @i_secuencial, @i_central_riesgo )
   
if @@error != 0 begin
   select
   @w_error = 703023,
   @w_msg   = 'Error al registrar cliente en ca_cliente_tmp. Cli:'+ convert(varchar,@i_codeudor) + 
              'User:' + @s_user + 'Sesn:' + convert(varchar,@s_sesn) + 'Sec:' + convert(varchar,@i_secuencial)
   select @w_msg = @w_msg + 'operacion cliente' + @i_operacion + @i_codeudor
   goto ERROR
end


/* REGISTRO DEL CLIENTE EN LA TABLA CA_DEUDORES_TMP */
if @i_desde_cre <> 'S' and @w_op_tipo not in ('R','',null) begin
      
   /* LOS REGISTROS EN CA_DEUDORES_TMP SOLO SE CREAN CUANDO LA OPERACION SE DA DE ALTA EN CARTERA */
   delete ca_deudores_tmp
   where  dt_deudor    = @i_codeudor
   and    dt_operacion = @w_operacion
      
   insert into ca_deudores_tmp values(
   @s_user,  @s_sesn,     @w_operacion,
   @i_banco, @i_codeudor, @i_rol,
  'S')
      
   if @@error != 0 begin
      select
      @w_msg   = 'Error al limpiar la tabla ca_deudores_tmp (3)',
      @w_error = 703023
      goto ERROR
   end

end

return 0

ERROR:

if @i_externo = 'S' begin
   exec cobis..sp_cerror
   @t_debug = 'N',
   @t_file  = null,
   @t_from  = @w_sp_name,
   @i_num   = @w_error,
   @i_msg   = @w_msg
end

return @w_error

go
