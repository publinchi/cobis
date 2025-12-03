/************************************************************************/
/*      Archivo:                act_estcliente.sp                       */
/*      Stored procedure:       sp_act_estcliente                       */
/*      Base de datos:          cobis                                   */
/*      Producto:               Clientes                                */
/*      Disenado por:           D. Villagomez                           */
/*      Fecha de escritura:     06-Ene-2020                             */
/************************************************************************/
/*                             IMPORTANTE                               */
/*  Este programa es propiedad de "COBISCORP". Ha sido desarrollado     */
/*  bajo el ambiente operativo COBIS-sistema desarrollado por           */
/*  "COBISCORP S.A."-Ecuador                                            */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado hecho por alguno de sus             */
/*  usuarios sin el debido consentimiento por escrito de la             */
/*  Gerencia General de COBISCORP o su representante.                   */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Este programa realiza la actualizacion del estado del cliente   */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR           RAZON                           */
/*      06/01/20        D. Villagomez   Emision inicial                 */
/*      30/07/20        MBA             Estandarizacion sp y seguridades*/
/************************************************************************/
use cobis
go

set ANSI_NULLS on
go

set QUOTED_IDENTIFIER on
go

if exists (select * 
             from sysobjects
            where type = 'P'
              and name = 'sp_act_estcliente')
  drop proc sp_act_estcliente
go

create procedure sp_act_estcliente
(
        @t_show_version   bit        = 0,
        @t_debug          char(1)    = 'N',
		@t_trn            int        = null,
		@t_file           varchar(10)= null,
		@i_operacion      char(1)    = 'U',
        @i_cli            int,
        @i_estcli         varchar(1),
        @i_is_batch       char(1)    = 'N'
)
as
declare @w_return         int,
        @w_sp_name        varchar(30),
        @w_rollback       char(1),
        @w_error          int,
        @w_poserr         int,
		@w_sp_msg         varchar(132)

/* captura nombre de stored procedure  */
select @w_sp_name = 'sp_act_estcliente'
select @w_sp_msg = ''
select @w_rollback = 'N'

/*--VERSIONAMIENTO--*/
if @t_show_version = 1
begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end
/*--FIN DE VERSIONAMIENTO--*/ 


-- VALIDACION DE TRANSACCIONES
if (@t_trn <> 172117)
begin
   exec cobis..sp_cerror
    @t_debug  = @t_debug,
    @t_file   = @t_file,
    @t_from   = @w_sp_name,
    @i_num    = 1720075                  
    --NO CORRESPONDE CODIGO DE TRANSACCION
   return 1720075
end

if @i_operacion = 'U'
begin
   if @@trancount = 0
   begin
       begin  tran
       select @w_rollback = 'S'
   end
   
   update cobis..cl_ente
   set    en_cliente = @i_estcli
   where  en_ente    = @i_cli
   
   if @@error <> 0
   begin
       select @w_error  = 1720368 --ERROR AL ACTUALIZAR EL ESTADO DEL CLIENTE
             ,@w_poserr = 90
       goto   ERROR
   end
   
   if @@trancount > 0 and @w_rollback = 'S'  -- 06/ENE/2020 D. VILLAGOMEZ OPEN API DE APERTURA
       commit tran
   return 0
   
   ERROR:
   if @w_error > 0
   begin
       if @t_debug = 'S'
       begin
           print '@w_rollback '  + cast(@w_rollback as varchar)
           print '@w_poserr '    + cast(@w_poserr as varchar)   +  ' @w_error ' + cast(@w_error as varchar)
           print '@i_is_batch '  + cast(@i_is_batch as varchar)
       end
       -- SI SE HIZO BEGIN TRAN HACEMOS EL ROLLBACK
       if @w_rollback = 'S'
       begin
           rollback
       end
       -- SI ES BATCH SOLO DEVUELVE EL NRO DE ERROR
       -- CASO CONTRARIO DISPARA EL SP_CERROR
       if @i_is_batch = 'N'
       begin
           exec cobis..sp_cerror
                @t_debug = null
               ,@t_file  = null
               ,@t_from  = @w_sp_name
               ,@i_num   = @w_error
       end
       -- AL FINAL SIEMPRE DEVUELVE EL ERROR
       return @w_error
   end
end   
go

