/* ********************************************************************** */
/*       Archivo:                conta_custodia.sp                        */
/*       Stored procedure:       sp_conta_custodia                        */
/*       Base de datos:          cobis                                    */
/*       Producto:               Garantia                                  */
/*       Disenado por:           Guisela Fernandez                        */
/*       Fecha de escritura:     10/Feb/2022                              */
/* ********************************************************************** */
/*                           IMPORTANTE                                   */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad          */
/*  de COBISCorp.                                                         */
/*  Su uso no autorizado queda expresamente prohibido asi como            */
/*  cualquier alteracion o agregado hecho por alguno de sus               */
/*  usuarios sin el debido consentimiento por escrito de COBISCorp.       */
/*  Este programa esta protegido por la ley de derechos de autor          */
/*  y por las convenciones internacionales de propiedad inte-             */
/*  lectual. Su uso no autorizado dara derecho a COBISCorp para           */
/*  obtener ordenes de secuestro o retencion y para perseguir             */
/*  penalmente a los autores de cualquier infraccion.                     */
/* ********************************************************************** */
/*                               PROPOSITO                                */
/*  Claves de tipo de garantia y moneda para mostrar en la asignacion de  */
/*  cuentas a parámetros de contabilidad de garantias                     */
/* ********************************************************************** */
/*                               MODIFICACIONES                           */
/*  FECHA        AUTOR              RAZON                                 */
/*  10/02/2022   G. Fernandez      Version base                           */
/* ********************************************************************** */
use cobis
go

if exists(select 1 from sysobjects where name = 'sp_conta_custodia')
   drop procedure sp_conta_custodia
go

create procedure sp_conta_custodia(
   @t_trn   int = null
)
as

-- Retorna datos
select   "CODIGO"      = tc_tipo + '.0', 
         "DESCRIPCION" = tc_descripcion
from     cob_custodia..cu_tipo_custodia
WHERE tc_tipo_superior IS NOT null

return 0
go