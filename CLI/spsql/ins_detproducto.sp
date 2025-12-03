/************************************************************************/
/*      Archivo:                insdetprod.sp                           */
/*      Stored procedure:       sp_ins_detproducto                      */
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
/*  Este programa realiza la insercion de un registro en la tabla       */
/*  cl_det_producto.                                                    */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*  FECHA           AUTOR           RAZON                               */
/*  06/01/20       D. Villagomez   Emision inicial                      */
/*  27/03/20       JZA             Cambios para Open API                */
/*  08/04/20       JZA             Estandarizacion API                  */
/*  07/06/20       Viviana Arias   Actualiza estado de la cta. S350628  */
/*  30/07/20       MBA             Estandarizacion sp y seguridades     */
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
              and name = 'sp_ins_detproducto')
  drop proc sp_ins_detproducto
go

create proc sp_ins_detproducto
(
    @s_ssn             int,
    @s_ofi             smallint,
    @s_date            datetime,
    @s_culture         varchar(10)     = 'NEUTRAL',
    @t_show_version    bit             = 0,
    @t_debug           char(1)         = 'N',
    @t_trn             int        = null,
	@t_file            varchar(10)= null,
    @i_is_batch        char(1)         = 'N',
    @i_det_producto    int,
    @i_filial          tinyint,
    @i_producto        tinyint,
    @i_mon             tinyint,
    @i_comentario      varchar(64),
    @i_valor           money,
    @i_cta_banco       varchar(24),
    @i_autorizante     smallint,
    @i_ofl             smallint,
    @i_cli             int,
    @i_direc           tinyint         = null,
    @i_descdir_ec      varchar(120),
    @i_estado          char(1)         = null,   --Vivi, 
    @i_operacion       char(1)         = 'I'
)
as
declare
    @w_return          int,
    @w_sp_name         varchar(30),
    @w_rollback        char(1),
    @w_error           int,
    @w_poserr          int,
	@w_sp_msg          varchar(132)


/* captura nombre de stored procedure  */
select @w_sp_name = 'sp_ins_detproducto'
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

---- INTERNACIONALIZACION ----
if @s_culture = 'NEUTRAL'  --Vivi 
   exec cobis..sp_ad_establece_cultura
        @o_culture = @s_culture out

if @@trancount = 0
begin
   begin tran
   select @w_rollback = 'S'
end

-- VALIDACION DE TRANSACCIONES
if (@t_trn <> 172118 and @i_operacion = 'I') or
   (@t_trn <> 172119 and @i_operacion = 'U')
begin
   exec sp_cerror
    @t_debug  = @t_debug,
    @t_file   = @t_file,
    @t_from   = @w_sp_name,
    @i_num    = 1720075                  
    --NO CORRESPONDE CODIGO DE TRANSACCION
   return 1720075
end

if @i_operacion = 'U'
  begin
    update cobis..cl_det_producto
	set    dp_oficial_cta    = isnull( @i_ofl, dp_oficial_cta),            
           dp_direccion_ec   = isnull( @i_direc, dp_direccion_ec),         
           dp_descripcion_ec = isnull( @i_descdir_ec, dp_descripcion_ec),             
           dp_monto          = isnull( @i_valor, dp_monto),	               
           dp_estado_ser     = isnull( @i_estado, dp_estado_ser)           
    where  dp_cuenta         = @i_cta_banco
    and    dp_producto       = @i_producto
    
    if @@rowcount <> 1
      begin
        select @w_error = 1720369, @w_poserr = 110 -- ERROR EN ACTUALIZACION DE DETALLE DE PRODUCTO
        goto   ERROR
      end
  end


if @i_operacion = 'I'
  begin
    insert into cobis..cl_det_producto (
    dp_det_producto,     dp_filial,         dp_oficina,         dp_producto,        dp_tipo,
    dp_moneda,           dp_fecha,          dp_comentario,      dp_monto,           dp_tiempo,
    dp_cuenta,           dp_estado_ser,     dp_autorizante,     dp_oficial_cta,     dp_cliente_ec,
    dp_direccion_ec,     dp_descripcion_ec)                                         
    values (                                                                           
    @i_det_producto,     @i_filial,         @s_ofi,             @i_producto,        'R',
    @i_mon,              @s_date,           @i_comentario,      @i_valor,           null,
    @i_cta_banco,        'V',               @i_autorizante,     @i_ofl,             @i_cli,
    @i_direc,            @i_descdir_ec)
	   
    if @@error <> 0
      begin
        select @w_error = 1720370, -- ERROR EN CREACION DE REGISTRO EN CL_DET_PRODUCTO
               @w_poserr = 130
        goto   ERROR
      end
  end


if @@trancount > 0 and @w_rollback = 'S' 
   commit tran
return 0

ERROR:
if @w_error > 0
  begin
    if @t_debug = 'S'
      begin
          print '@w_rollback ' + cast(@w_rollback as varchar)
          print '@w_poserr '   + cast(@w_poserr as varchar)   +  ' @w_error ' + cast(@w_error as varchar)
          print '@i_is_batch ' + cast(@i_is_batch as varchar)
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
               @t_debug   = @t_debug
              ,@t_file    = null
              ,@t_from    = @w_sp_name
              ,@i_num     = @w_error
              ,@s_culture = @s_culture
      end
      -- AL FINAL SIEMPRE DEVUELVE EL ERROR
      return @w_error
  end

go

