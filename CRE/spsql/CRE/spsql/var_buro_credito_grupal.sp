/************************************************************************/
/*  Archivo:                var_buro_credito_grupal.sp                  */
/*  Stored procedure:       sp_var_buro_credito_grupal                  */
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

if exists (select 1 from sysobjects where name = 'sp_var_buro_credito_grupal' and type = 'P')
   drop proc sp_var_buro_credito_grupal
go


CREATE PROC sp_var_buro_credito_grupal(
   @i_grupo         int = null,
   @i_cliente       int = null,
   @o_resultado     VARCHAR(255) = NULL OUTPUT
)
AS
DECLARE @w_sp_name          varchar(32),
        @w_return           INT,
        @w_error            INT,
        @w_msg              VARCHAR(255),
        ---var variables    
        @w_valor_nuevo      varchar(255),
        @w_ente             int,
        @w_calif_buro       char(255),
        @w_grupo            INT,
        @w_tipo_operacion   INT,
        @w_nro_ciclo_grupal INT,
        @w_cg_ente          int,
        @w_cg_grupo         int,
        @w_cg_estado        CHAR(1),
        @w_cg_nro_ciclo     int,
        @w_cg_calif_buro    varchar(64),
        @w_nro_ciclo        INT,
        @w_fecha_ult_consulta DATETIME,
        @w_resultado        varchar(64),
        @w_valor_ant        varchar(255),
        @w_resp_buro        varchar(500), 
        @w_integrantes      varchar(500),
        @w_grupos_ante      int

     
SELECT 
@w_sp_name ='sp_var_buro_credito_grupal',
@w_cg_calif_buro = 'BUENO',
@w_resultado  = 'BUENO'

SELECT @i_grupo, '----', @i_cliente

PRINT 'NUMERO CICLO GRUPAL: ' + convert(VARCHAR,@w_nro_ciclo_grupal)

exec sp_var_calif_buro_cred_int
@i_ente = @i_cliente,
@o_resultado = @o_resultado out

ACTUALIZAR:
--print '@w_resultado: ' + convert(varchar, @w_resultado)      
--select @o_resultado = convert(varchar,@w_cg_calif_buro)
select @o_resultado
PRINT '------------->>>>GRUPAL-RESULTADO:'+CONVERT(VARCHAR(30),@o_resultado) + '--CLIENTE:'+CONVERT(VARCHAR(30),@i_cliente)        
return 0

ERROR:
EXEC @w_error= cobis..sp_cerror
@t_debug  = 'N',
@t_file   = '',
@t_from   = @w_sp_name,
@i_num    = @w_error

return @w_error

GO
