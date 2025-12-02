use cob_interface
go

/************************************************************************/
/*   Archivo:              sp_qry_oper_sol_wf_int.sp                    */
/*   Stored procedure:     sp_qry_oper_sol_wf_int                       */
/*   Base de datos:        cob_interface                                */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Paul Moreno                                  */
/*   Fecha de escritura:   11 Marzo   2022                              */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBISCORP'.                                                       */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBISCORP o su representante.             */
/************************************************************************/
/*                                PROPOSITO                             */
/************************************************************************/
/*                               CAMBIOS                                */
/*      FECHA          AUTOR            CAMBIO                          */
/*      MAR-03-2022    pmoreno          Emision Inicial                 */
/************************************************************************/

if exists (select 1 from sysobjects where name = 'sp_qry_oper_sol_wf_int')
drop proc sp_qry_oper_sol_wf_int
go

create proc sp_qry_oper_sol_wf_int (
       @t_show_version        bit          = 0,
       @t_debug               varchar(1)   = 'N',
       @t_file                varchar(14)  = null,
       @t_from                varchar(30)  = null,
       @t_trn                 int          = null,
       @i_tramite             int          = null,
       @i_operacion           char(1)      = null,
	   @i_formato_fecha       int          = 103
) as
declare 
	   @w_error               int,
	   @w_sp_name             varchar(32)

if (@t_trn != 21842)
begin --Tipo de transaccion no corresponde
   select @w_error = 2101006
   goto ERROR
end

select @w_sp_name = 'sp_qry_oper_sol_wf_int'

if @t_show_version = 1
begin
    print 'Stored procedure sp_qry_oper_sol_wf_int, Version 1.0.0.0'
    return 0
end

exec @w_error =  cob_cartera..sp_qry_oper_sol_wf
	 @t_show_version  = @t_show_version,
	 @t_debug         = @t_debug,
	 @t_file          = @t_file,
	 @t_from          = @t_from,
	 @t_trn           = @t_trn,
	 @i_tramite       = @i_tramite,
     @i_operacion     = @i_operacion,
     @i_formato_fecha = @i_formato_fecha
	if @w_error != 0
    begin
       goto ERROR
    end
	
ERROR:    --Rutina que dispara sp_cerror dado el codigo de error
   exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = @w_error
   return 1
go
