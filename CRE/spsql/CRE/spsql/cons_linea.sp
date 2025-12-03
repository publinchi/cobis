/************************************************************************/
/*  Archivo:                cons_linea.sp                               */
/*  Stored procedure:       sp_cons_linea                               */
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

if exists (select 1 from sysobjects where name = 'sp_cons_linea' and type = 'P')
   drop proc sp_cons_linea
go


create proc sp_cons_linea (
   @s_date               datetime = null,
   @i_cliente            int 	  = null
)
as
declare
   @w_return             int,          
   @w_sp_name            varchar(32),  
   @w_monto              money,
   @w_utilizado          money,
   @w_fecha_vto          varchar(10),
   @w_moneda             tinyint,
   @w_banco              varchar(24),
   @w_conexion           int


select @w_sp_name 	= 'sp_cons_linea'

if @i_cliente is NULL 
begin
   exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = 2101001
   return 1 
end

select @w_conexion = @@spid

delete 	cr_linea_tmpp
where 	sesion 	= @w_conexion

insert into cr_linea_tmpp 
(
sesion,					num_banco, 				monto, 				
estado, 				disponible, 	
fecha_vto, 				tramite)
select
@w_conexion,				li_num_banco,				round(li_monto ,2),	
'EN TRAMITE',           		round((li_monto-(isnull(li_utilizado,0)+isnull(li_reservado,0))),2),
li_fecha_vto,				li_tramite
from 	cr_linea,
	cr_tramite
where 	li_cliente 	= @i_cliente
and	li_tramite 	= tr_tramite
and	tr_estado 	in ('A','N','D','P')
and   	li_estado 	is null
and   	li_tipo 	in ('S','N','O')
union
select
@w_conexion,				li_num_banco,				round(li_monto,2),		
(select substring(C.valor,1,30) 
 from 	cobis..cl_tabla T,
	cobis..cl_catalogo C
 where	T.codigo = C.tabla
 and	T.tabla  = 'cr_estado_cupo'
 and	C.codigo = cr_linea.li_estado
 ),					round((li_monto - (isnull(li_utilizado,0) + isnull(li_reservado,0))),2),
li_fecha_vto,				li_tramite
from 	cr_linea,
	cr_tramite
where 	li_cliente 	= @i_cliente
and	li_tramite 	= tr_tramite
and   	li_estado 	is not null 
and	li_estado 	in ('V','B','D')
and   	li_tipo 	in ('O')
and	tr_estado 	in ('A','N','D','P')
union
select
@w_conexion,				li_num_banco,				round(li_monto,2),		
(select substring(C.valor,1,30)
 from 	cobis..cl_tabla T,
	cobis..cl_catalogo C
 where	T.codigo = C.tabla
 and	T.tabla  = 'cr_estado_cupo'
 and	C.codigo = cr_linea.li_estado
 ),					round((li_monto - (isnull(li_utilizado,0))),2),
li_fecha_vto,				li_tramite
from 	cr_linea,
	cr_tramite
where 	li_cliente 	= @i_cliente
and	li_tramite 	= tr_tramite
and   	li_estado 	is not null 
and	li_estado 	in ('V','B','D')
and   	li_tipo 	in ('S','N')
and	tr_estado 	in ('A','N','D','P')

update	cr_linea_tmpp
set 	num_banco = convert(varchar(24), tramite), 
    	tipo 	  = 'T'
where 	sesion    = @w_conexion
and 	estado    = 'EN TRAMITE'

update 	cr_linea_tmpp
set 	tipo = 'C'
where 	sesion = @w_conexion
and 	tipo is null

select	num_banco,
	monto,
	disponible,
	estado,
	convert(char(10),fecha_vto,103),
	tramite
from 	cr_linea_tmpp
where 	sesion 	= @w_conexion
order 	by tipo, num_banco

return 0

GO
