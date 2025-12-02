use cob_cartera
go

/************************************************************************/
/*   Archivo:              ropsolwf.sp                                  */
/*   Stored procedure:     sp_ruteo_oper_sol_wf                         */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Raul Altamirano Mendez                       */
/*   Fecha de escritura:   Ene-18-2017                                  */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                                PROPOSITO                             */
/************************************************************************/
/*                               CAMBIOS                                */
/*      FECHA          AUTOR            CAMBIO                          */
/*      ENE-18-2017    Raul Altamirano  Emision Inicial - Version MX    */
/************************************************************************/

if exists (select 1 from sysobjects where name = 'sp_ruteo_oper_sol_wf')
    drop proc sp_ruteo_oper_sol_wf
go

create proc sp_ruteo_oper_sol_wf(
   @s_srv            varchar(30),
   @s_lsrv           varchar(30),
   @s_ssn            int,
   @s_user           login,
   @s_term           varchar(30),
   @s_date           datetime,
   @s_sesn           int,
   @s_ofi            smallint,
   ---------------------------------------
   @t_trn            int          = null,
   ---------------------------------------
   @i_operacion      varchar(1)   = null,
   @i_banco          cuenta       = null,
   @i_tramite        int          = null,
   @i_en_linea       varchar(1)   = 'S',
   @i_externo        varchar(1)   = 'S',
   @i_desde_web      varchar(1)   = 'S',
   ---------------------------------------
   @o_banco          cuenta = null out,
   @o_operacion      int = null out,
   @o_tramite        int = null out,
   @o_msg            varchar(100) = null out
)as 

declare
   @w_sp_name            varchar(64),
   @w_return             int,
   @w_error              int,   
   @w_commit             char(1),
   @w_fecha_proceso      datetime,
   @w_operacion          int,
   @w_banco              cuenta,
   @w_tramite            int
   

   
select @w_sp_name  = 'sp_ruteo_oper_sol_wf',
       @w_commit   = 'N'


PRINT 'CONSULTAR FECHA DE PROCESO'
select @w_fecha_proceso = fc_fecha_cierre
from   cobis..ba_fecha_cierre
where  fc_producto = 7


if @i_tramite is null 
begin
   select @w_operacion    = opt_operacion,
		  @i_tramite      = opt_tramite
   from   ca_operacion_tmp
   where  opt_banco = @i_banco
end
else 
begin
   select @i_banco        = opt_banco,
          @w_operacion    = opt_operacion
   from   ca_operacion_tmp
   where  opt_tramite = @i_tramite
end

if @@rowcount = 0
begin
   select @w_error = 708153
   goto ERROR_PROCESO
end


select @w_tramite = @i_tramite,
       @w_banco   = @i_banco


if @@trancount = 0
begin
   begin tran
   select @w_commit = 'S'
end


if not exists (select 1 from cob_credito..cr_tramite 
               where tr_tramite = @w_tramite 
			   and tr_numero_op = @w_operacion)
begin
   select @w_error = 701187
   goto ERROR_PROCESO
end

if not exists (select 1 from ca_operacion 
               where op_banco = @w_banco
			   and op_tramite = @w_tramite)
begin
   select @w_error = 701187
   goto ERROR_PROCESO
end


--PRINT 'TRASLADO DE INFORMACION DESDE LAS TMP A DEFINITIVAS'
exec @w_return = sp_pasodef
@i_banco           = @w_banco,
@i_operacionca     = 'S',
@i_dividendo       = 'S',
@i_amortizacion    = 'S',
@i_cuota_adicional = 'S',
@i_rubro_op        = 'S',
@i_relacion_ptmo   = 'S',
@i_operacion_ext   = 'S'

if @w_return != 0
begin 
   select @w_error = @w_return
   goto ERROR_PROCESO
end

--PRINT 'ELIMINACION DE LA INFORMACION EN TEMPORALES'
exec @w_return = sp_borrar_tmp
@s_sesn   = @s_sesn,
@s_user   = @s_user,
@s_term   = @s_term,
@i_banco  = @w_banco

if @w_return != 0
begin 
   select @w_error = @w_return
   goto ERROR_PROCESO
end

   
--PRINT 'ENVIO DE LOS NUMEROS DE OPERACION Y TRAMITE GENERADOS'
select 
@o_banco     = @w_banco,
@o_operacion = @w_operacion,
@o_tramite   = @w_tramite
---------------------------------------------

if @w_commit = 'S' begin 
   commit tran
   select @w_commit = 'N'
end

return 0


ERROR_PROCESO:
PRINT 'ERROR NUMERO ' + CONVERT(VARCHAR, @w_error)
if @w_commit = 'S'
   rollback tran
   
return @w_error

go

