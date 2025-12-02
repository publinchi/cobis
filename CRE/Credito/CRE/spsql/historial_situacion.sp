/************************************************************************/
/*  Archivo:                historial_situacion.sp                      */
/*  Stored procedure:       sp_historial_situacion                      */
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
/*  Este stored procedure nos permitir  dar mantenimiento a la          */
/*  cr_historial_situacion                                              */
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  10/Ago/05	Angela Milena Tovar	   Emision Inicial                  */
/*  23/04/19          jfescobar        Emision Inicial                  */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_historial_situacion')
    drop proc sp_historial_situacion
go

create proc sp_historial_situacion
(
   @s_date              	datetime    = null,
   @s_user              	login       = null,
   @i_operacion         	char(1),
   @t_trn                       smallint = null,
   @t_debug                     char(1)  = 'N',
   @t_file                      varchar(14) = null,
   @t_from                      varchar(30) = null,
   @i_cliente           	int,
   @i_situacion         	catalogo  = null,
   @i_causal            	catalogo  = null
 )

as

declare
   @w_return            int,           /* VALOR QUE RETORNA */
   @w_sp_name           varchar(32),   /* NOMBRE STORED PROCEDURE */
   @w_existe            tinyint,
   @w_cliente		int,
   @w_situacion		catalogo,
   @w_causal		catalogo,
   @w_fecha		datetime,
   @w_usuario		login,
   @w_sitpc		varchar(30),
   @w_descripcion	descripcion,
   @w_nombre		varchar(254),
   @w_desc_causal       descripcion,
   @w_desc_situacion	descripcion,
   @w_sitc		catalogo,
   @w_today     datetime,
   @w_rowcount          int


select @w_today = getdate()




/* NOMBRE DEL SP */
select @w_sp_name = 'sp_historial_situacion'

/***********************************************************/
/* Codigos de Transacciones                                */
/***********************************************************/
if (@t_trn <> 21299 and @i_operacion = 'I') or
   (@t_trn <> 21300 and @i_operacion = 'S') or
   (@t_trn <> 21311 and @i_operacion = 'V')
begin
/* tipo de transaccion no corresponde */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file,
    @t_from  = @w_sp_name,
    @i_num   = 1901006
    return 1
end

/* SELECCION DE PARAMETROS */
select @w_sitc = pa_char
from cobis..cl_parametro
where pa_nemonico = 'SITC'
and pa_producto = 'CRE'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0
begin
   /* No existe valor de parametro */
   exec cobis..sp_cerror
   @t_from  = @w_sp_name,
   @i_num   = 2101084
   return 1
end



/* SELECCION DE PARAMETROS */
select @w_sitpc = pa_char
from cobis..cl_parametro
where pa_nemonico = 'SITPC'
and pa_producto = 'CRE'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0
begin
   /* No existe valor de parametro */
   exec cobis..sp_cerror
   @t_from  = @w_sp_name,
   @i_num   = 2101084
   return 1
end





/*************************************/
/*INSERT TABLA cr_historial_situacion*/
/*************************************/

if @i_operacion = 'I'
begin
   insert into cr_historial_situacion
      values (
      @i_cliente,             @i_situacion,    @i_causal,
      @w_today,        	      @s_user)

      if @@error <> 0
      begin
           /* ERROR AL INSERTAR REGISTRO */
           exec cobis..sp_cerror
           @t_from  = @w_sp_name,
           @i_num   = 2103001
           return 1
      end
end

/*************************/
/* CONSULTA OPCION QUERY cr_historial_situacion*/
/*************************/

if @i_operacion = 'S'
begin
          set rowcount 0
	  select
		"CLIENTE"      = hs_cliente,
	        "SITUACION"    = hs_situacion,
	   	"DESCRIPCION SITUACION"  = (select a.valor
				from cobis..cl_tabla b,cobis..cl_catalogo a
		 		where  b.tabla = 'cl_situacion_cliente'
				and a.codigo = h.hs_situacion
				and a.tabla = b.codigo),
		"CAUSAL"       = hs_causal,
		"DESCRIPCION CAUSAL"   = (select a.valor
				from cobis..cl_tabla b,cobis..cl_catalogo a
  		 		where  b.tabla = 'cr_causal_situacion'
				and a.codigo = h.hs_causal
				and a.tabla = b.codigo),
		"FECHA"        = convert (varchar(10),hs_fecha,101),
	   	"USUARIO"      = hs_user
	   from cr_historial_situacion h
           where hs_cliente = @i_cliente


end


/******************************************/
/* ULTIMO CAUSAL DE PRECASTIGO DEL CLIENTE*/
/******************************************/

if @i_operacion = 'V'
begin


select @w_fecha = max(hs_fecha)
from cob_credito..cr_historial_situacion
where hs_cliente = @i_cliente
and hs_situacion in (@w_sitc, @w_sitpc)




	/* SELECCION DEL CAUSAL DE PRE-CASTIGO*/
	select "Causal" 	= hs_causal,
	       "Descripcion"    = (select  a.valor
                                   from cobis..cl_catalogo a
                                   where a.tabla = (select b.codigo
                                                    from cobis..cl_tabla b
                                                    where b.tabla = 'cr_causal_situacion')
                                   and a.codigo = h.hs_causal)

	from cr_historial_situacion h
	where hs_cliente = @i_cliente --Cliente consulta
	and hs_fecha	 = @w_fecha



end
return 0
go
