/***********************************************************************/
/*  Archivo:                   fuerecur.sp                             */
/*  Stored procedure:          sp_fuentes_recursos                     */
/*  Base de Datos:             cob_cartera                             */
/*  Producto:                  Cartera                                 */
/*  Disenado por:              Juan Quinche                            */
/*  Fecha de Documentacion:    20/Jun/08                               */
/***********************************************************************/
/*          IMPORTANTE                                                 */
/*  Este programa es parte de los paquetes bancarios propiedad de      */
/*  "MACOSA",representantes exclusivos para el Ecuador de la           */
/*  AT&T                                                               */
/*  Su uso no autorizado queda expresamente prohibido asi como         */
/*  cualquier autorizacion o agregado hecho por alguno de sus          */
/*  usuario sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de MACOSA o su representante                 */
/***********************************************************************/
/*          PROPOSITO                                                  */
/*  Este stored procedure permite realizar las siguientes              */ 
/*  operaciones: Reporte de fuentes de recursos, con descripciones     */
/*                                                                     */
/***********************************************************************/
/*          MODIFICACIONES                                             */
/*  FECHA       AUTOR           RAZON                                  */
/*  20/jun     Juan B. Quinche  Emision Inicial                        */
/***********************************************************************/
use cob_cartera
go

if exists (select 1 from cob_cartera..sysobjects where name = 'sp_fuente_recursos' and xtype = 'P')
    drop proc sp_fuente_recursos
go

create procedure sp_fuente_recursos
   @s_ssn                int         = null,
   @s_date               datetime    = null,
   @s_user               login       = null,
   @s_term               descripcion = null,
   @s_ofi                smallint    = null,
   @s_srv                varchar(30) = null,     
   @t_trn                smallint    = null,
   @t_debug              char(1)     = 'N'
   
as
declare @w_sp_name   varchar(24)
declare @w_sp_file   varchar(24)
select @w_sp_name   = 'sp_fuente_recursos'
select @w_sp_file   = 'fuerecur.sp'


select   fr_codigo_fuente,
         valor, 
         fr_monto,              
         fr_saldo,          
         fr_utilizado ,
         fr_estado
from     cobis..cl_tabla  t 
inner join cobis..cl_catalogo c
on (c.tabla = t.codigo)
inner join cob_credito..cr_fuente_recurso
on  ( c.codigo = fr_fuente  )
where  t.tabla  = 'cr_fuente_recurso'

return 0
go

