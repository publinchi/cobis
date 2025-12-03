/************************************************************************/
/*	Archivo:		datconsouvr.sp				*/
/*	Stored procedure:	sp_consolidador_uvr                     */
/*	Base de datos:		cob_cartera				*/
/*	Producto: 		Cartera	                  		*/
/*	Disenado por:  		Fabian de la Torre                      */
/*	Fecha de escritura:	Mar 1999. 				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	'MACOSA'							*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/*				PROPOSITO				*/
/*	Procedimiento valores de la correccion monetaria                */
/*  									*/
/*				CAMBIOS					*/
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_consolidador_uvr')
   drop proc sp_consolidador_uvr
go

create proc sp_consolidador_uvr
@i_modo              char(1)  = null,
@i_operacionca       int      = null,
@i_banco             cuenta   = null,
@i_div_cancelado     smallint = null,
@o_cap_contingente   money    = null out,
@o_correc_cap_vig    money    = null out,
@o_int_contingente   money    = null out,
@o_correc_int_vig    money    = null out,
@o_imo_contingente   money    = null out,
@o_correc_imo_vig    money    = null out


as 
declare 
@w_error                int,          
@w_return               int,    
@w_sp_name              descripcion,  
@w_correc_imo_vig       money,
@w_imo_contingente      money,
@w_correc_int_vig       money,
@w_int_contingente      money,
@w_correc_cap_vig       money,
@w_cap_contingente      money,
@w_concepto_cap         catalogo,
@w_concepto_int         catalogo,
@w_concepto_imo         catalogo,
@w_est_castigado        int,
@w_est_suspenso         int


select                                  
@w_sp_name        = 'sp_consolidador_vr' 


select @w_concepto_cap = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'CAP'
and    pa_producto = 'CCA'
set transaction isolation level read uncommitted


select @w_concepto_int = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'INT'
and    pa_producto = 'CCA'
set transaction isolation level read uncommitted


select @w_concepto_imo = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'IMO'
and    pa_producto = 'CCA'
set transaction isolation level read uncommitted


select @w_est_castigado  = isnull(es_codigo, 255)
from ca_estado
where rtrim(ltrim(es_descripcion)) = 'CASTIGADO'

select @w_est_suspenso   = isnull(es_codigo, 255)
from ca_estado
where rtrim(ltrim(es_descripcion)) = 'SUSPENSO'



/***********************/
/* CAPITAL CONTINGENTE */
/***********************/

select   
@w_cap_contingente = sum(isnull(co_correccion_sus_mn, 0) - isnull(co_correc_pag_sus_mn, 0)),
@w_correc_cap_vig  = sum(isnull(co_correccion_mn, 0))
from   ca_correccion 
where  co_operacion  = @i_operacionca
and    co_concepto   = @w_concepto_cap
and    co_dividendo >= @i_div_cancelado
     
select @o_cap_contingente = isnull(@w_cap_contingente, 0) 
select @o_correc_cap_vig  = isnull(@w_correc_cap_vig, 0)  


/* INTERES CONTINGENTE */
/***********************/
select   
@w_int_contingente = sum(isnull(co_correccion_sus_mn, 0) - isnull(co_correc_pag_sus_mn, 0)),
@w_correc_int_vig  = sum(isnull(co_correccion_mn, 0))
from   ca_correccion 
where  co_operacion  = @i_operacionca
and    co_concepto   = @w_concepto_int 
and    co_dividendo >= @i_div_cancelado

select @o_int_contingente = isnull(@w_int_contingente,0) 
select @o_correc_int_vig  = isnull(@w_correc_int_vig,0)


/* INTERES EN MORA */
/*******************/

select   
@w_imo_contingente = sum(isnull(co_correccion_sus_mn, 0) - isnull(co_correc_pag_sus_mn, 0)),
@w_correc_imo_vig  = sum(isnull(co_correccion_mn, 0))
from   ca_correccion 
where  co_operacion  = @i_operacionca
and    co_concepto   = @w_concepto_imo
and    co_dividendo >= @i_div_cancelado

select @o_imo_contingente = isnull(@w_imo_contingente, 0) 
select @o_correc_imo_vig  = isnull(@w_correc_imo_vig  , 0)

return 0

go

