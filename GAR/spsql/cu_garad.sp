/***********************************************************************/
/*	Archivo:			cu_garad.sp                    */
/*	Stored procedure:		sp_gar_admisible               */
/*	Base de Datos:			cob_custodia                   */
/*	Disenado por:			M. D vila                      */
/*	Producto:			CONSOLIDADOR	               */
/*	Fecha de Documentacion: 	28/Jul/1998                    */
/***********************************************************************/
/*			IMPORTANTE		       		       */
/*	Este programa es parte de los paquetes bancarios propiedad de  */
/*	'MACOSA',representantes exclusivos para el Ecuador de la       */
/*	AT&T							       */
/*	Su uso no autorizado queda expresamente prohibido asi como     */
/*	cualquier autorizacion o agregado hecho por alguno de sus      */
/*	usuario sin el debido consentimiento por escrito de la         */
/*	Presidencia Ejecutiva de MACOSA o su representante	       */
/***********************************************************************/
/*			PROPOSITO				       */
/*  El store procedure generar  los datos do_tipo_garantias y          */
/*  do_valor_admisibles						       */
/***********************************************************************/
/*			MODIFICACIONES				       */
/*	FECHA		AUTOR			RAZON		       */
/*	13/Oct/98       MVI               Emision Inicial	       */
/***********************************************************************/
use cob_custodia
go

if exists (select 1 from sysobjects where name = 'sp_gar_admisible')
    drop proc sp_gar_admisible
go
create proc sp_gar_admisible (
   @s_date              datetime = null,
   @s_user              login = null,
   @s_ssn               int      = null,
   @s_term              catalogo = null,
   @i_banco             varchar(24) = null,
   @i_tramite           int = null,
   @o_admisible         char(1) = null OUTPUT,
   @o_valor             money = null OUTPUT
)

as
declare
  
   @w_sp_name           varchar(32),   /* NOMBRE STORED PROCEDURE */
   @w_def_moneda        tinyint,
   @w_admisible         char(1),
   @w_valor             money,
   @w_return		int,
   @w_trm               money,
   @w_hora_base		datetime,
   @w_ms		datetime,
   @w_mc                datetime,
   @w_temporal          int,
   @w_max		int,
   @w_contador          int,
   @w_rowcount          int

select @w_max = 4

--exec sp_reloj  17.71, @w_ms, @w_ms out, @w_max

   
/* NOMBRE DEL SP */
select @w_sp_name = 'sp_gar_admisible'
select @w_hora_base = getdate()

if @s_date is null
   select @s_date = fp_fecha
   from cobis..ba_fecha_proceso


/* SELECCION DE CODIGO DE MONEDA LOCAL */
select @w_def_moneda = pa_tinyint  
from cobis..cl_parametro  
where pa_nemonico = 'MLOCR'  
and pa_producto  = 'CRE'
select @w_rowcount = @@rowcount 
set transaction isolation level read uncommitted


if @w_rowcount = 0
begin
   /*REGISTRO NO EXISTE */
   exec cobis..sp_cerror
   @t_from  = @w_sp_name,
   @i_num   = 2101005
   return 1
end

if not exists (	select 	1 
		from 	cu_cotizacion_moneda
		where   fecha = @s_date)
begin
   insert into cu_cotizacion_moneda
   (
   moneda, 	cotizacion, 	fecha)               
   select
   cv_moneda, 	cv_valor, 	@s_date
   from cob_conta..cb_vcotizacion a 
   where cv_fecha =(	select 	max(cv_fecha)
                 	from 	cob_conta..cb_vcotizacion b 
                 	where 	a.cv_moneda = b.cv_moneda)
   and   cv_fecha <= @s_date
end




-- Dado el n£mero de tr mite o n£mero de banco encontrar 
-- el valor de las garantias admisibles y retornarlo 


delete cu_tmp_gar_adm
where sesion = @@spid

if @i_tramite is not null begin
   insert into cu_tmp_gar_adm (garantia,admisible,valor,sesion)
   select gp_garantia, 
          cu_clase_custodia,
         (cu_valor_inicial * cotizacion),
         @@spid
   from cob_credito..cr_gar_propuesta, 
        cob_custodia..cu_custodia x, 
        cu_cotizacion_moneda
   where gp_tramite = @i_tramite
   and gp_garantia  = cu_codigo_externo
   and cu_estado in ('F','V')
   and cu_moneda = moneda
   and fecha     = @s_date
end else begin
   select @i_tramite = tr_tramite
   from   cob_cartera..ca_operacion,cob_credito..cr_tramite

   where  op_tramite = tr_tramite

   and    op_banco = @i_banco


   insert into cu_tmp_gar_adm (garantia,admisible,valor,sesion)
   select gp_garantia,
          cu_clase_custodia,
          (cu_valor_inicial * cotizacion),
          @@spid
   from cob_credito..cr_gar_propuesta, 
        cob_custodia..cu_custodia x, 
        cu_cotizacion_moneda
   where gp_tramite = @i_tramite
   and   gp_garantia = cu_codigo_externo
   and   cu_estado in ('F','V')
   and   cu_moneda = moneda
   and fecha     = @s_date

end
select @w_valor = sum(valor)
from cu_tmp_gar_adm
--where admisible = 'A' emg feb-16-02
where admisible = 'I'
and sesion = @@spid

if @w_valor is null
begin
   select @w_valor = sum(valor)
   from cu_tmp_gar_adm 
   where admisible = 'O'
   and sesion = @@spid

   select @w_admisible = 'N' --'O'

   select @o_admisible = @w_admisible,
          @o_valor = @w_valor
end
else
begin
   select @w_admisible = 'S' --'A'

   select @o_admisible = @w_admisible,
          @o_valor = @w_valor
end

--exec sp_reloj  17.74, @w_ms, @w_ms out, @w_max          
return 0
go