/************************************************************************/
/*  Archivo:                consulta_distr_linea_int.sp                 */
/*  Stored procedure:       sp_consulta_distr_linea_int                 */
/*  Base de Datos:          cob_interface                               */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jose Mieles                                 */
/*  Fecha de Documentacion: 04/10/2021                                  */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP                                                           */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante.              */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  SP GENERADO POR EXTRACCION DE LA BB.DD. cob_interface               */ 
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  04/10/2021       jmieles        Emision Inicial                     */
/* **********************************************************************/

use cob_interface
go

if exists(select 1 from sysobjects where name ='sp_consulta_distr_linea_int')
   drop procedure sp_consulta_distr_linea_int
go

create proc sp_consulta_distr_linea_int
(
	   @s_ssn                     int              = null,
       @s_user                    login            = null,
       @s_sesn                    int              = null,
       @s_term                    descripcion      = null,         
       @s_date                    datetime         = null,
       @s_srv                     varchar(30)      = null,
       @s_lsrv                    varchar(30)      = null,
       @s_rol                     smallint         = null,
       @s_ofi                     smallint         = null,
       @s_org_err                 char(1)          = null,
       @s_error                   int              = null,
       @s_sev                     tinyint          = null,
       @s_msg                     descripcion      = null,
       @s_org                     char(1)          = null,
       @t_rty                     char(1)          = null,
       @t_trn                     int              = null,
       @t_debug                   char(1)          = 'N',
       @t_file                    varchar(14)      = null,
       @t_from                    varchar(30)      = null,
       @t_show_version            bit              = 0,          
       @s_culture                 varchar(10)      = 'NEUTRAL',
       @i_operacion               char(1)          = null,
       @i_tramite	              int              = null
	   )
as 
declare 
	   @w_error                   int,
       @w_sp_name1                varchar(100),
	   @w_linea					   int
	   
	  
select @w_sp_name1 = 'cob_credito..sp_lin_ope_moneda',
	   @w_linea = null,
       @w_error    = 0
	   

select @w_linea   = li_numero
  from cob_credito..cr_linea
 where li_tramite = @i_tramite	
 
 if(@w_linea is null)
 begin
    select
    @w_error = 2110192
    goto ERROR
 end

if (@i_operacion <> 'S')
 begin
    select
    @w_error = 2110173
    goto ERROR
 end
 
if @i_operacion = 'S'
begin
   SELECT DISTINCT
            'Operacion' = om_toperacion,
            'Producto' = om_producto,
            'Moneda' =om_moneda,
            'Monto' = om_monto,
            'Utilizado' = isnull(om_utilizado,0),
            'Condicion Especial' = om_condicion_especial,
            'Desc_Operacion' = to_descripcion,
            'Desc_Moneda' = mo_descripcion,
            'Desc_Producto'  = pd_descripcion,
            'Riesgo' = pl_riesgo,
            'Desc_Riesgo' = cobis..cl_catalogo.valor,
            'Linea' = om_linea
      FROM  cob_credito..cr_lin_ope_moneda,            
            cobis..cl_moneda,
            cob_credito..cr_toperacion,
            cobis..cl_producto,
            cobis..cl_tabla,
            cobis..cl_catalogo,
            cob_credito..cr_productos_linea
      WHERE ( om_linea =  @w_linea) and
            ( om_toperacion = to_toperacion) and     
           (mo_moneda      = om_moneda) and         
           (pd_abreviatura = om_producto ) AND
           cobis..cl_tabla.tabla='fp_riesgos_licre' AND
           cobis..cl_tabla.codigo=cobis..cl_catalogo.tabla AND 
           cob_credito..cr_productos_linea.pl_producto=cob_credito..cr_toperacion.to_toperacion and
           cobis..cl_catalogo.codigo = cob_credito..cr_productos_linea.pl_riesgo
		
   if @w_error != 0
    begin
      goto ERROR
    end
 end		
		
return 0

ERROR:
--Devolver mensaje de Error
exec cobis..sp_cerror
       @t_debug = @t_debug,
       @t_file  = @t_file,
       @t_from  = @w_sp_name1,
       @i_num   = @w_error
return @w_error

go