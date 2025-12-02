/*************************************************************************/
/*   Archivo:              custodia_automatica.sp                        */
/*   Stored procedure:     sp_custodia_automatica                        */
/*   Base de datos:        cob_custodia                                  */
/*   Producto:             Garantias                                     */
/*   Disenado por:         TEAM SENTINEL PRIME                           */
/*   Fecha de escritura:   Marzo 2019                                    */
/*************************************************************************/
/*                                  IMPORTANTE                           */
/*   Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*   de MACOSA S.A.                                                      */
/*   Su uso no autorizado queda expresamente prohibido asi como          */
/*   cualquier alteracion o agregado hecho por alguno de sus             */
/*   usuarios sin el debido consentimiento por escrito de MACOSA         */
/*   Este programa esta protegido por la ley de derechos de autor        */
/*   y por las  convenciones  internacionales de  propiedad inte-        */
/*   lectual.  Su uso no  autorizado dara  derecho a  MACOSA para        */
/*   obtener  ordenes de  secuestro o retencion y  para perseguir        */
/*   penalmente a los autores de cualquier infraccion.                   */
/*************************************************************************/
/*                             MODIFICACION                              */
/*    FECHA               AUTOR                     RAZON                */
/*    Marzo/2019          TEAM SENTINEL PRIME       emision inicial      */
/*                                                                       */
/*************************************************************************/
use cob_custodia
go
if exists (select 1 from sysobjects where name = 'sp_custodia_automatica')
    drop proc sp_custodia_automatica
go

                                                                                                                                                                                                                                                              
create proc sp_custodia_automatica (
                                                                                                                                                                                                                          
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
                                                                                                                                                                                                               
@t_trn                  smallint        = null,
                                                                                                                                                                                                               
@t_debug                char(1)         = 'N',
                                                                                                                                                                                                                
@t_file                 varchar(14)     = null,
                                                                                                                                                                                                               
@t_from                 varchar(30)     = null,
                                                                                                                                                                                                               
@i_operacion            varchar(1)      = null,
                                                                                                                                                                                                               
@i_tipo_custodia        varchar(10)     = null,
                                                                                                                                                                                                               
@i_valor_inicial        money           = null,
                                                                                                                                                                                                               
@i_moneda               tinyint         = null,
                                                                                                                                                                                                               
@i_garante              int             = null,
                                                                                                                                                                                                               
@i_fecha_ing            datetime        = null,
                                                                                                                                                                                                               
@i_cliente              int             = null,
                                                                                                                                                                                                               
@i_clase                char(1)         = 'C',
                                                                                                                                                                                                                
@i_filial               int             = null,
                                                                                                                                                                                                               
@i_oficina              int             = null,
                                                                                                                                                                                                               
@i_ubicacion            varchar(10)     = null,
                                                                                                                                                                                                               
@i_tramite              int             = null,
                                                                                                                                                                                                               
@i_plazo_fijo           varchar(30)     = null,
                                                                                                                                                                                                               
@i_cuenta_hold          varchar(30)     = null,     
                                                                                                                                                                                                          
@i_cuenta_tipo          tinyint         = null,
                                                                                                                                                                                                               
@o_codigo_externo       varchar(64)     = null out --NUMERO DE LA GARANTIA
                                                                                                                                                                                    
)
                                                                                                                                                                                                                                                             
as
                                                                                                                                                                                                                                                            
declare
                                                                                                                                                                                                                                                       
@w_today                datetime,     /* fecha del dia */ 
                                                                                                                                                                                                    
@w_return               int,          /* valor que retorna */
                                                                                                                                                                                                 
@w_sp_name              varchar(32),  /* nombre stored proc*/
                                                                                                                                                                                                 
@w_existe               tinyint,      /* existe el registro*/
                                                                                                                                                                                                 
@w_ubicacion            varchar(10),
                                                                                                                                                                                                                          
@w_tipo_docu            varchar(10),
                                                                                                                                                                                                                          
@w_cod_externo          varchar(64),
                                                                                                                                                                                                                          
@w_tramite              int,
                                                                                                                                                                                                                                  
@w_monto                money,
                                                                                                                                                                                                                                
@w_custodia             int,
                                                                                                                                                                                                                                  
@w_gar_personal         catalogo,
                                                                                                                                                                                                                             
@w_tc_cobertura         float
                                                                                                                                                                                                                                 

                                                                                                                                                                                                                                                              
-------------------------------- VERSIONAMIENTO DEL PROGRAMA --------------------------------
                                                                                                                                                                 
if @t_show_version = 1
                                                                                                                                                                                                                                        
begin
                                                                                                                                                                                                                                                         
    print 'Stored procedure cob_custodia..sp_custodia_automatica, Version 4.0.0.0'
                                                                                                                                                                            
    return 0                                                                                                                                                                                                                                               
end                                                                                                                                                                                                                                                  
return 0                                                                                                                                         
go