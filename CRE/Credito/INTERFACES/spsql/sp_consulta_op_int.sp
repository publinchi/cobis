/***********************************************************************/
/*     Base de Datos:           cob_credito                            */
/*     Stored procedure:        sp_consulta_op_int                     */
/*     Producto:                Credito                                */
/*     Disenado por:                                                   */
/*     Fecha de Documentacion:  18/Jul/22                              */
/***********************************************************************/
/*                            IMPORTANTE                               */
/*     Este programa es parte de los paquetes bancarios propiedad de   */
/*     'COBISCORP S.A.'.                                               */
/*     Su uso no autorizado queda expresamente prohibido asi como      */
/*     cualquier autorizacion o agregado hecho por alguno de sus       */
/*     usuario sin el debido consentimiento por escrito de la          */
/*     Presidencia Ejecutiva de COBISCORP S.A. o su representante      */
/***********************************************************************/
/*                            PROPOSITO                                */
/*     Obtener datos de operacion de cartera en base a datos           */
/*      del tramite                                                    */
/***********************************************************************/
/*                           MODIFICACIONES                            */
/*   FECHA              AUTOR                     RAZON                */
/*   18/JUL/2022        DMO                 Emision Inicial            */
/***********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_consulta_op_int')
   drop procedure sp_consulta_op_int
GO

CREATE PROCEDURE  sp_consulta_op_int   (
   @t_debug          char(1)       = 'N',
   @t_file           varchar(14)   = null,
   @t_show_version   bit           = 0,     -- Mostrar la version del programa
   @s_ssn            int           = null,
   @s_sesn           int           = null,
   @s_term           descripcion   = null,
   @s_ofi            smallint      = null,
   @s_user           login         = null,
   @s_date           datetime      = null,
   @s_srv            varchar(30)   = null,
   @s_lsrv           varchar(30)   = null,
   @s_rol            smallint      = null,
   @s_org_err        char(1)       = null,
   @s_error          int           = null,
   @s_sev            tinyint       = null,
   @s_msg            descripcion   = null,
   @s_org            char(1)       = null,
   @s_culture        varchar(10)   = null,
   @t_rty            char(1)       = null,
   @t_from           varchar(32)   = null,
   @t_trn            int           = null,
   @i_operacion      char(1)       = null,
   @i_tramite        int           = null,
   @i_cliente        int           = null
)
as

--print 'Declaracion de Variables'
declare     @w_sp_name               varchar(32),
            @w_error                 int,
            @w_op_banco              cuenta,
            @w_op_ref_grupal         cuenta

--Versionamiento
if @t_show_version = 1
begin
      print 'Stored procedure sp_consulta_op_int, Version 4.0.0.1'
      return 0
end

if(@i_tramite is null)
begin
    select @w_error = 2110400 --El trámite no existe
    goto ERROR
end

if(@i_cliente is null)
begin
    select @w_error = 250037 --Debe enviar número de trámite.
    goto ERROR
end

if not exists(select 1 from cobis..cl_ente where en_ente =@i_cliente )
begin
    select @w_error = 2110208 --El cliente no existe.
    goto ERROR
end


if(@i_operacion = 'Q')
begin
    
    select @w_op_banco = op_banco from cob_cartera..ca_operacion 
    where op_grupal = 'N' and 
    op_tramite = @i_tramite and 
    op_cliente = @i_cliente and   
    op_estado != 6
    
    if (@w_op_banco is null ) --Es grupal
    begin
       select @w_op_ref_grupal = op_banco
       from   cob_cartera..ca_operacion
       where  op_tramite = @i_tramite
       and    op_estado != 6

       select @w_op_banco = op_banco
       from   cob_cartera..ca_operacion 
       where op_grupal = 'S' and op_cliente = @i_cliente 
       and op_ref_grupal = @w_op_ref_grupal
       and    op_estado != 6
    end 
    
    if (@w_op_banco is null)
    begin
        select @w_error = 2110185 --La operación no existe
        goto ERROR
    end
    
    select 'OP_BANCO' = @w_op_banco

end


return 0
ERROR:
   exec cobis..sp_cerror
   @t_debug = 'N',
   @t_file  = '',
   @t_from  = @w_sp_name,
   @i_num   = @w_error
   return @w_error


GO