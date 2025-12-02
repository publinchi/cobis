/************************************************************/
/*   ARCHIVO:         actualizar_estado_tramite.sp          */
/*   NOMBRE LOGICO:   sp_actualizar_estado_tramite          */
/*   PRODUCTO:        COBIS CREDITO                         */
/************************************************************/
/*                     IMPORTANTE                           */
/*  Esta aplicacion es parte de los  paquetes bancarios     */
/*  propiedad de COBISCORP.                                 */
/*  Su uso no autorizado queda  expresamente  prohibido     */
/*  asi como cualquier alteracion o agregado hecho  por     */
/*  alguno de sus usuarios sin el debido consentimiento     */
/*  por escrito de COBISCORP.                               */
/*  Este programa esta protegido por la ley de derechos     */
/*  de autor y por las convenciones internacionales de      */
/*  propiedad intelectual. Su uso no autorizado dara        */
/*  derecho a COBISCORP para obtener ordenes de secuestro   */
/*  o  retencion  y  para  perseguir  penalmente a  los     */
/*  autores de cualquier infraccion.                        */
/************************************************************/
/*                     PROPOSITO                            */
/*  Se  actualiza el estado del trámite por integrante      */
/*  de un grupo.                                            */
/************************************************************/
/*                     MODIFICACIONES                       */
/*   FECHA           AUTOR               RAZON              */
/*  21-09-2021    Paul Moreno      Emision Inicial.         */
/*  05-11-2021    Patricio Mora    Migración a GFI          */
/************************************************************/
use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_actualizar_estado_tramite')
   drop procedure sp_actualizar_estado_tramite
go

create proc sp_actualizar_estado_tramite
(
    @t_trn        int,                                                                                                                                                                   
    @t_debug      char(1)       = 'N',                                                                                                                                                                                                        
    @t_file       varchar(10)   = null,                                                                                                                                                                                                       
    @t_from       varchar(32)   = null,
    @i_tramite    int           = null,
    @i_cliente    int           = null,
    @s_date       date,
    @i_operacion  char
)
as
declare
    @w_sp_name    varchar(25),
    @w_error      int
   
if @t_trn != 21834
begin --Tipo de transaccion no corresponde
   select @w_error = 2101006
     goto ERROR
end

--Aceptar excepcion
if @i_operacion = 'A'
begin
   update cob_credito..cr_tramite_grupal
      set tg_estado  = 'A'
    where tg_tramite = @i_tramite
      and tg_cliente = @i_cliente
end

--Rechazar excepcion
if @i_operacion = 'Z'
begin
   update cob_credito..cr_tramite_grupal
      set tg_estado  = 'Z'
    where tg_tramite = @i_tramite
      and tg_cliente = @i_cliente
end

--Recomendar
if @i_operacion = 'R'
begin
   update cob_credito..cr_tramite_grupal
      set tg_estado  = 'R'
    where tg_tramite = @i_tramite
      and tg_cliente = @i_cliente
end 
    
return 0

ERROR:
begin --Devolver mensaje de Error
   select @w_error
     exec cobis..sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = @w_error
   return @w_error
end

go
