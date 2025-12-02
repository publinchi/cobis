/************************************************************************/
/*  Archivo:                cons_linea_grupo.sp                         */
/*  Stored procedure:       sp_cons_linea_grupo                         */
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

if exists (select 1 from sysobjects where name = 'sp_cons_linea_grupo' and type = 'P')
   drop proc sp_cons_linea_grupo
go


create proc sp_cons_linea_grupo (
   @s_date		datetime = null,
   @i_grupo		int = null
)
as

declare
   @w_today             datetime,     /* fecha del dia */ 
   @w_return            int,          /* valor que retorna */
   @w_sp_name           varchar(32),  /* nombre stored proc*/
   @w_monto		money,
   @w_utilizado		money,
   @w_fecha_vto		varchar(10),
   @w_def_moneda	tinyint,
   @w_moneda		tinyint,
   @w_moneda_cliente	tinyint,
   @w_banco		varchar(24),
   @w_cliente           int,
   @w_monto_cliente     money,
   @w_utilizado_cliente money,
   @w_monto_cliente_lin money,
   @w_utilizado_cliente_lin money,
   @w_nombre                varchar(40),
   @w_conexion          int,
   @w_rowcount          int

select @w_sp_name = 'sp_cons_linea_grupo'
select @w_today = @s_date

/* VALIDACION DE CAMPOS NULOS */
/******************************/
if 
    @i_grupo is NULL 
begin
/* Campos NOT NULL con valores nulos */
	exec cobis..sp_cerror
        @t_debug = 'N',
        @t_from  = @w_sp_name,
        @i_num   = 2101001
        return 1 
end

/* Seleccion de codigo de moneda local */
SELECT @w_def_moneda = pa_tinyint  
   FROM cobis..cl_parametro  
   WHERE pa_producto = 'CRE'
     and pa_nemonico = 'MLOCR'
     select @w_rowcount = @@rowcount
   set transaction isolation level read uncommitted

if @w_rowcount = 0
begin

/*Registro no existe */
        exec cobis..sp_cerror
        @t_debug = 'N',
        @t_from  = @w_sp_name,
        @i_num   = 2101005
	return 0
end

select @w_conexion = @@spid

delete cr_linea_tmpp1
where sesion = @w_conexion

/*
create table #cr_linea_tmp (
num_banco           cuenta       null,
monto               money        null,
estado              varchar(15)  null,  --pga2 5jul2001
disponible          money        null,  --pga2 5jul2001
fecha_vto           datetime     null ,
tramite		    int          null,
tipo                char(1)      null
)
*/

/* INICIO CAMBIO DBA: 19/OCT/99 */

-- lineas del grupo
insert into cr_linea_tmpp1 (
sesion,num_banco,monto,estado, disponible,
fecha_vto, tramite)
SELECT  @w_conexion,
        li_num_banco,
	round((li_monto * cv_valor),2),
        substring(b.valor,1,30),                         
        round((li_monto - (isnull(li_utilizado,0) + isnull(li_reservado,0)))* cv_valor,2),
	li_fecha_vto,
	li_tramite
FROM cr_linea x, cob_conta..cb_vcotizacion,
     cobis..cl_tabla a, cobis..cl_catalogo b
WHERE   li_grupo = @i_grupo 
and 	li_moneda = cv_moneda
and 	(li_estado is not null or li_estado <> 'A')   --pga25jul2001
and     li_tipo <> 'C' -- EXCEPTO CUPOS DE CONVENIOS  pga25jul2001
and     cv_fecha = (select max(cv_fecha)
                    from   cob_conta..cb_vcotizacion
                    where  cv_moneda = x.li_moneda
                    and cv_fecha <= @s_date)
and   a.tabla = 'cr_estado_cupo'
and   a.codigo = b.tabla
and   b.codigo = li_estado 


insert into cr_linea_tmpp1 (
sesion,num_banco,monto,estado, disponible,
fecha_vto, tramite)
SELECT  @w_conexion,
        li_num_banco,
	round((li_monto * cv_valor),2),
        'EN TRAMITE',                         
        round((li_monto - (isnull(li_utilizado,0) + isnull(li_reservado,0)))* cv_valor,2),
	li_fecha_vto,
	li_tramite
FROM cr_linea x, cob_conta..cb_vcotizacion
WHERE   li_grupo = @i_grupo 
and 	li_moneda = cv_moneda
and 	li_estado is null   --pga25jul2001
and     li_tipo <> 'C' -- EXCEPTO CUPOS DE CONVENIOS  pga25jul2001
and     cv_fecha = (select max(cv_fecha)
                    from   cob_conta..cb_vcotizacion
                    where  cv_moneda = x.li_moneda
                    and cv_fecha <= @s_date)

update cr_linea_tmpp1
set num_banco = convert(varchar(24), tramite), 
    tipo = 'T'
where sesion = @w_conexion
  and estado = 'EN TRAMITE'

update cr_linea_tmpp1
set tipo = 'C'
where sesion = @w_conexion
  and tipo is null

SELECT  num_banco,
	monto,
        estado,
	disponible,
	convert(char(10),fecha_vto,103),
	tramite
FROM cr_linea_tmpp1
where sesion = @w_conexion
order by tipo, num_banco

/* FIN CAMBIO DBA: 19/OCT/99 */

/*
-- CREAR UNA TABLA TEMPORAL CON LOS CLIENTES MIEMBROS DE UN GRUPO
create table #cr_clig (
cliente         int     null,
nombre          varchar(100) null
) 

-- LLENAR LA TABLA TEMPORAL
insert into #cr_clig (cliente, nombre)
select en_ente, rtrim(en_nomlar)
from cobis..cl_ente
where en_grupo = @i_grupo 
*/
--emg sep-28-01
/*select
	'Cliente'= li_cliente,
	'Nombre'= nombre,
	'Monto' = sum(li_monto * cv_valor),
	'Utilizado'= sum(li_utilizado * cv_valor)
FROM	cr_linea x, cob_conta..cb_vcotizacion, #cr_clig
WHERE   li_cliente = cliente
and	cv_moneda = li_moneda
and 	(li_estado is null or li_estado = 'V')
and     cv_fecha = (select max(cv_fecha)
                    from   cob_conta..cb_vcotizacion
                    where  cv_moneda = x.li_moneda
                    and cv_fecha <= @s_date)
GROUP BY li_cliente, nombre*/
/*
select
	'Cliente'= en_ente,
	'Nombre'= nombre,
	'Monto' = en_max_riesgo ,
	'Utilizado'= en_riesgo 
FROM	cobis..cl_ente, #cr_clig
WHERE   en_ente = cliente
GROUP BY en_ente, nombre
*/
return 0

GO
