/************************************************************************/
/*      Archivo:                consulopgar.sp                          */
/*      Stored procedure:       sp_consulopgar                          */
/*      Base de datos:          cob_intefase                            */
/*      Producto:               Inteface                                */
/*      Disenado por:           Roxana Sánchez                          */
/*      Fecha de documentacion: 18/Enero/17                             */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA', representantes exclusivos para el Ecuador de la       */
/*      'NCR CORPORATION'.                                              */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Este script crea los procedimientos para las consultas de las   */
/*      operaciones de plazos fijos.                                    */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA      AUTOR              RAZON                             */
/*      18-Ene-17  Roxana Sánchez     Creacion                          */
/************************************************************************/

use cob_interface
go

if exists (select * from sysobjects where name = 'sp_consulopgar')
   drop proc sp_consulopgar
go

create proc sp_consulopgar (
	@s_ssn                  int             = NULL,
	@s_user                 login           = NULL,
	@s_term                 varchar(30)     = NULL,
	@s_date                 datetime        = NULL,
	@s_srv                  varchar(30)     = NULL,
	@s_lsrv                 varchar(30)     = NULL,
	@s_ofi                  smallint        = NULL,
	@s_rol                  smallint        = NULL,
	@t_debug                char(1)         = 'N',
	@t_file                 varchar(10)     = NULL,
	@t_from                 varchar(32)     = NULL,
	@t_trn                  smallint        = NULL,
	@i_num_banco            cuenta          = ' ',
	@i_codigo               varchar(30)     = '%',
	@i_accion_sgte          catalogo        = null,
	@i_accion		         catalogo	= null,	
	@i_estado1              catalogo        = 'ACT',
	@i_estado2          	catalogo        = 'VEN',
	@i_estado3          	catalogo        = null,
	@i_operacion            char(1)         = null,
	@i_ente                 int             = NULL,
     @i_modo                 char(1)         = NULL,
     @i_tasa_variable        char(1)         = '%',
     @i_aprobacion           char(1)         = 'N',
     @i_login_oficial        login           = null,
     @i_oficina		    int		     = null,
     @i_busq_x_ofi           varchar(3)      = NULL
)
as

declare @w_sp_name              descripcion,
        @w_return               tinyint

select @w_sp_name = 'sp_consulopgar'

/*----------------------------------*/
/*  Verificar codigo de transaccion */
/*----------------------------------*/
if @t_trn <> 14806 and @i_operacion = 'H'
begin
  exec cobis..sp_cerror
       @t_debug = @t_debug,
       @t_file  = @t_file,
       @t_from  = @w_sp_name,
       @i_num   = 141042
  return 1
end
/*
exec cob_pfijo..sp_consulopgar
@i_num_banco   = @i_num_banco,
@i_codigo      = @i_codigo,
@i_accion_sgte = @i_accion_sgte,
@i_estado1     = @i_estado1,
@i_estado2     = @i_estado2,
@i_estado3     = @i_estado3,
@i_operacion   = @i_operacion, 
@i_ente        = @i_ente,
@i_modo        = @i_modo,
@i_busq_x_ofi  = @i_busq_x_ofi
*/

set rowcount 0
return 0
go
