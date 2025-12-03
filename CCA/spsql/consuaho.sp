/************************************************************************/
/*   Archivo:              consuaho.sp                                  */
/*   Stored procedure:     sp_consulta_ahorro                           */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Ignacio Yupa                                 */
/*   Fecha de escritura:   13-Jun-2017                                  */
/************************************************************************/
/*   IMPORTANTE                                                         */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'COBISCORP'.                                                    */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de COBISCORP o su representante.          */
/************************************************************************/
/*  Consulta de ahorro individual                                       */
/*                                                                      */
/*   MODIFICACIONES                                                     */
/************************************************************************/

use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_consulta_ahorro')
   drop proc sp_consulta_ahorro
go

create proc sp_consulta_ahorro (
@t_show_version         bit             = 0,  -- show the version of the stored procedure
@s_ssn                  int             = null,
@s_user                 login           = null,
@s_sesn                 int             = null,
@s_term                 varchar(30)     = null,
@s_date                 datetime        = null,
@s_srv                  varchar(30)     = null,
@s_lsrv                 varchar(30)     = null,
@s_rol                  smallint        = NULL,
@s_ofi                  smallint        = NULL,
@s_org_err              char(1)         = NULL,
@s_error                int             = NULL,
@s_sev                  tinyint         = NULL,
@s_msg                  descripcion     = NULL,
@s_org                  char(1)         = NULL,
@t_rty                  char(1)         = null,
@t_trn                  int        = null,
@t_debug                char(1)         = 'N',
@t_file                 varchar(14)     = null,
@t_from                 varchar(30)     = null,
@i_cta_grupo            cuenta             = null
)

as

declare @w_sp_name varchar(60)

select @w_sp_name = 'sp_consulta_ahorro'

	SELECT 'OPERACION'         = ai_operacion,
          'CLIENTE'           = ai_cliente,
          'NOMBRE CLIENTE'    = en_nomlar,
          'AHORRO INDIVIDUAL' = ai_saldo_individual,
          'INCENTIVO'         = ai_incentivo,
          'GANANCIAS'         = ai_ganancia
   from cob_ahorros..ah_ahorro_individual, cobis..cl_ente
	WHERE en_ente = ai_cliente
   and ai_cta_grupal = @i_cta_grupo
   
   if @@ROWCOUNT = 0 
   begin         
         exec cobis..sp_cerror 
         @t_debug = 'N',
         @t_file  = null,
         @t_from  = @w_sp_name,  
         @i_msg   = 'NO EXISTE REGISTROS PARA LA CUENTA GRUPAL',
         @i_num   = 71002
         return 71002
   end

return 0  -- para que el batch 1 no registre dos veces el mismo error

GO

