/************************************************************************/
/*  Archivo:                li_negra_cliente.sp                         */
/*  Stored procedure:       sp_li_negra_cliente                         */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           JOSE ESCOBAR                                */
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
/*  23/04/19          jfescobar        Emision Inicial                  */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_li_negra_cliente')
    drop proc sp_li_negra_cliente
go

create proc sp_li_negra_cliente 
        (@s_ssn        int         = null,
         @s_ofi        SMALLINT    = null,--
         @s_user       login       = null,--
         @s_date       DATETIME    = null,--
         @s_srv        varchar(30) = null,
         @s_term       descripcion = null,
         @s_rol        smallint    = null,
         @s_lsrv       varchar(30) = null,
         @s_sesn       int         = null,
         @s_org        char(1)     = NULL,
         @s_org_err    int         = null,
         @s_error      int         = null,
         @s_sev        tinyint     = null,
         @s_msg        descripcion = null,
         @t_rty        char(1)     = null,
         @t_trn        int         = null,
         @t_debug      char(1)     = 'N',
         @t_file       varchar(14) = null,
         @t_from       varchar(30) = null,
         --variables
         @i_ente       int  ,    --codigo del cliente 
         @o_resultado  smallint    = NULL out
    
)as
declare
         @w_error                   INT,
         @w_sp_name                 VARCHAR(30),
         @w_cli_nombres             VARCHAR(100),
         @w_cli_apellidos           VARCHAR(100),
         @w_cli_fecha_nac           DATETIME,
         @w_cli_fecha_nac_char      VARCHAR(10),         
         @w_n_conicidencias         INT

SELECT @w_sp_name = 'sp_li_negra_cliente'

-- Ejecuta la validacion de listas negras del cliente

if @i_ente is null return 0

   SELECT
       @w_cli_nombres   =lower(replace(isnull(en_nombre,'')+' '+isnull( p_s_nombre,''),' ', '')),
       @w_cli_apellidos =lower(replace(isnull(p_p_apellido,'')+' '+isnull(p_s_apellido,''),' ', '')),
       @w_cli_fecha_nac =p_fecha_nac
   FROM cobis..cl_ente  WHERE en_ente=@i_ente
 
PRINT 'nombres:'  + convert(VARCHAR(30),@w_cli_nombres)
PRINT 'apellidos:'+ convert(VARCHAR(30),@w_cli_apellidos)
PRINT 'fechanac:' + convert(VARCHAR(30), @w_cli_fecha_nac)

SELECT @w_cli_fecha_nac_char  = CONVERT(VARCHAR(10), @w_cli_fecha_nac, 112)

PRINT 'fechanac-varchar:'+@w_cli_fecha_nac_char
 
SELECT @w_n_conicidencias=count(*) FROM cob_credito..cr_lista_negra 
WHERE lower(replace(ln_nombre,' ', ''))              =@w_cli_nombres
AND   lower(replace(isnull(ln_apellidos,''),' ', ''))=isnull( @w_cli_apellidos,'')

PRINT '@w_n_conicidencias:'+ convert(VARCHAR(30), @w_n_conicidencias)

IF(@w_n_conicidencias=0)
	BEGIN
		SELECT @o_resultado  = 1
		
		UPDATE cobis..cl_ente_aux set ea_lista_negra='N' WHERE ea_ente=@i_ente
		
		PRINT '@w_n_conicidencias==0:'+ convert(VARCHAR(30), @o_resultado)
	END

IF(@w_n_conicidencias=1 OR @w_n_conicidencias>1 )
	BEGIN
		SELECT @o_resultado  = 3
		
		UPDATE cobis..cl_ente_aux set ea_lista_negra='S' WHERE ea_ente=@i_ente
		
		PRINT '@w_resultado=1 o mayor que 1:'+ convert(VARCHAR(30), @o_resultado)
	end

/*IF(@w_n_conicidencias > 1)
	BEGIN
	PRINT '@w_n_conicidencias>1'
		IF EXISTS ( SELECT 1 FROM cob_credito..cr_lista_negra 
		            WHERE  lower(replace(ln_nombre,' ', '') )             =@w_cli_nombres
		            AND   lower( replace(isnull(ln_apellidos,''),' ', ''))=isnull( @w_cli_apellidos,'')
		            AND ln_fecha_nac=@w_cli_fecha_nac_char 
		            )
		     BEGIN
		     SELECT @o_resultado  = 3
		     
		     UPDATE cobis..cl_ente_aux set ea_lista_negra='S' WHERE ea_ente=@i_ente
		     
		     PRINT '@w_resultado >1 3:'+ convert(VARCHAR(30), @o_resultado)
	END 
	ELSE
		BEGIN
			PRINT '@w_n_conicidencias>1 pero no existe fecha de nacimiento'
			SELECT @o_resultado  = 1
			
			UPDATE cobis..cl_ente_aux set ea_lista_negra='N' WHERE ea_ente=@i_ente
			
			PRINT '@w_resultado >1 1:'+ convert(VARCHAR(30), @o_resultado)
		END       
	END*/
  
return 0
ERROR:
    exec cobis..sp_cerror @t_from = @w_sp_name, @i_num = @w_error
    return @w_error
go
