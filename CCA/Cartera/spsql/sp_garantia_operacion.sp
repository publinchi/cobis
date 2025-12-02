use cob_cartera
go

/************************************************************************/
/*   Archivo:              sp_garantia_operacion.sp                     */
/*   Stored procedure:     sp_garantia_operacion                        */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:                                                      */
/*   Fecha de escritura:   May-31-2017                                  */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                                PROPOSITO                             */
/************************************************************************/
/*                               CAMBIOS                                */
/*      FECHA          AUTOR            CAMBIO                          */
/*      MAY-31-2017    Jorge Salazar    Emision Inicial - Version MX    */
/************************************************************************/

if exists (select 1 from sysobjects where name = 'sp_garantia_operacion')
    drop proc sp_garantia_operacion
go

create procedure sp_garantia_operacion
(
   @i_garantia   cuenta
)
as

select 
convert(varchar(15), OP.op_operacion),
upper(en_nomlar),
OP.op_fecha_ini, 
convert(varchar,op_monto),
(select es_descripcion 
 from cob_cartera..ca_estado
 where es_codigo = OP.op_estado)
from cob_cartera..ca_operacion OP, cobis..cl_ente
where op_cliente = en_ente
and op_banco = @i_garantia 
union
select 
tg_prestamo,
upper(en_nomlar), 
OP.op_fecha_ini,
convert(varchar,tg_monto),
(select es_descripcion 
 from cob_cartera..ca_estado
 where es_codigo = OP.op_estado)
from cob_credito..cr_tramite_grupal, cob_cartera..ca_operacion OP, cobis..cl_ente
where tg_tramite = OP.op_tramite
and tg_cliente  = en_ente
and op_banco = @i_garantia

return 0
go

