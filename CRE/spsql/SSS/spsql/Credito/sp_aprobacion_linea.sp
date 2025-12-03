/************************************************************************/
/*  Archivo:                sp_aprobacion_linea.sp                      */
/*  Stored procedure:       sp_aprobacion_linea                         */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jose Ortiz                                  */
/*  Fecha de Documentacion: 23/Abr/2019                                 */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP S.A.representantes exclusivos para el Ecuador de la       */
/*  AT&T                                                                */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante               */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  SP GENERADO POR EXTRACCION DE LA BB.DD. cob_credito                 */
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  23/04/19          Jose Ortiz       Emision Inicial                  */
/* **********************************************************************/
use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_aprobacion_linea' and type = 'P')
   drop proc sp_aprobacion_linea
go

CREATE PROCEDURE sp_aprobacion_linea (
    @s_ssn           int          = null, 
    @s_user          varchar(30)  = null,
    @s_sesn          int          = null,
    @s_ofi           smallint     = NULL,
    @s_term          varchar(30)  = null,
    @s_date          datetime     = null,
    @t_debug         char(1)      = 'N',
    @t_file          varchar(10)  = null,
    @i_tramite       int          = null,
    @o_banco         cuenta       = null OUTPUT
)
as
declare
   @w_sp_name           varchar(32),
   @w_return            int,
   @w_numero_bco        cuenta
   
select @w_sp_name = 'sp_aprobacion_linea'

-- Si tramite es linea de credito si va a etapa final o termino ruta
-- asigna numero de linea de credito, antes no
exec cob_credito..sp_general4
    @s_ssn                = @s_ssn,
   	@s_date               = @s_date,
   	@s_user               = @s_user,
   	@s_term               = @s_term,
   	@s_ofi                = @s_ofi,	 
   	@t_trn                = 21823,
   	@t_debug              = @t_debug,
   	@t_file               = @t_file,   
   	@i_modo		 	      = 4, 
   	@i_tramite		      = @i_tramite,
   	@o_numero_bco	      = @w_numero_bco OUTPUT /* numero de banco para L. Credito */



if @w_return <> 0
   return @w_return 

UPDATE cr_linea
   SET li_num_banco   = @w_numero_bco,
       li_fecha_aprob = @s_date,
       li_estado      = 'VIG'
 WHERE li_tramite     = @i_tramite   

if @@error <> 0 
begin
   --Error en actualizacion de registro
   exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = 2105001
   return 1 
end

if(@w_numero_bco is not null)
begin
   select 'Linea de Credito Aprobada:', @w_numero_bco
   select @o_banco = @w_numero_bco
end
return 0

go

