/************************************************************************/
/*   Archivo:             buscolat.sp                                  */
/*   Stored procedure:    sp_bus_colateral                              */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            cartera						               	*/
/*   Disenado por:        Luis Carlos Moreno C.			                */
/*   Fecha de escritura:  Diciembre/2011                                */
/************************************************************************/
/*                           IMPORTANTE                                 */
/*  Este programa es parte de los paquetes bancarios	                */
/*	propiedad de 'MACOSA', representantes exclusivos para	            */
/*  el Ecuador de 'NCR'.                      			                */
/*  Su uso no autorizado queda expresamente prohibido asi como  		*/
/*  cualquier alteracion o agregado hecho por alguno de sus    			*/
/*  usuarios sin el debido consentimiento por escrito de la    			*/
/*  Presidencia Ejecutiva de MACOSA o su representante.    			    */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  Realizar la busqueda de la garantia de tipo colateral USAID y FNG   */
/*  asociada a la operacion que se recibe por parametro                 */
/************************************************************************/
/*                          MODIFICACIONES                              */
/*  FECHA     AUTOR             RAZON                                   */
/*  02-12-11  L.Moreno          Emisión Inicial - Req: 293              */
/*  20-20-14  Igmar Berganza    Req 397 Reportes FGA                    */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_bus_colateral')
   drop proc sp_bus_colateral
go

create procedure sp_bus_colateral(
	   @s_user               login        = null,
	   @s_term               varchar(30)  = null,
	   @s_date               datetime     = null,
	   @s_ssn                int          = null,
	   @s_srv                varchar(30)  = null, 
	   @s_sesn               int          = null,
	   @s_ofi                smallint     = null,
	   @s_rol		         smallint     = null,
       @i_llamado            char(1)      = 'B',
       @i_tipo               char(1)      = null,
       @i_banco              cuenta       = null,
       @o_porcentaje         float        = null out,
       @o_tipo_sup           varchar(30)  = null out,
       @o_tipo_gar           varchar(30)  = null out,
       @o_tipo               varchar(30)  = null out,
       @o_subtipo_gar        varchar(30)  = null out,
       @o_3nivel_gar         varchar(255) = null out,
       @o_for_pago           varchar(30)  = null out
)

as

Declare @w_sp_name           descripcion,
        @w_error             int,
        @w_fecha_proceso     datetime,
        @w_cod_gar_esp       varchar(30),
        @w_codigo_externo    varchar(64)
        
select @w_sp_name = 'sp_bus_colateral'

/* CALCULA FECHA DE PROCESO */
select @w_fecha_proceso = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7


select @o_porcentaje = 0

/* OBTIENE CODIGO GARANTIAS ESPECIALES */
select @w_cod_gar_esp = pa_char
from cobis..cl_parametro with (nolock)
where pa_producto = 'GAR'
and   pa_nemonico = 'GARESP'

-- Insertar en tabla temporal #tipo_gar Req. 397
if exists (select 1 from sysobjects where name = '#tipo_gar')
   drop table #tipo_gar

select tipo_superior=tc_tipo_superior, tipo=tc_tipo, tipo_gar='E', subtipo_gar=substring(descripcion_sib,1,30), ter_nivel_gar=tc_descripcion
into  #tipo_gar
from cob_credito..cr_corresp_sib,cob_custodia..cu_tipo_custodia
where tabla = 'T65'
and   codigo = tc_tipo

-- Agregada lectura a la tabla temporal #tipo_gar Req. 397
select tc_tipo as tipo_sub 
into #colaterales
from cob_custodia..cu_tipo_custodia
where tc_tipo_superior = @w_cod_gar_esp
and   tc_tipo in (select distinct tipo_superior from #tipo_gar)

if @i_tipo = 'C' --Consulta Garantia
begin
    -- Agregada lectura a la tabla temporal #tipo_gar Req. 397
	if exists (select 1 from sysobjects where name = '#garantias_c')
       drop table #garantias_c
	
	select w_codigo_externo = cu_codigo_externo,
		   o_porcentaje     = gp_porcentaje,
		   o_tipo_gar       = 'ESPECIAL',
           o_tipo_sup       = tc_tipo_superior,
		   o_tipo           = tc_tipo,
		   o_subtipo_gar    = subtipo_gar, 
		   o_3nivel_gar     = ter_nivel_gar,
           o_for_pago       = convert(varchar(10),'') 
    into #garantias_c
	from cob_custodia..cu_custodia,
		 cob_credito..cr_gar_propuesta,
		 cob_cartera..ca_operacion,
		 cob_custodia..cu_tipo_custodia,
		 #colaterales, #tipo_gar
	where op_banco          = @i_banco
	and   op_tramite        = gp_tramite 
	and   gp_garantia       = cu_codigo_externo
	and   cu_tipo           = tc_tipo
	and   tc_tipo_superior  = tipo_sub
	and   tipo_sub          = tipo_superior
	and   tipo              = tc_tipo 

    update #garantias_c
	set o_for_pago = codigo_sib
	from cob_credito..cr_corresp_sib
	where tabla = 'T303'
	and   codigo = o_tipo_sup
    
    select @w_codigo_externo = w_codigo_externo,
		   @o_porcentaje     = o_porcentaje,
		   @o_tipo_gar       = o_tipo_gar,
           @o_tipo_sup       = o_tipo_sup,
		   @o_tipo           = o_tipo,
		   @o_subtipo_gar    = o_subtipo_gar, 
		   @o_3nivel_gar     = o_3nivel_gar,
           @o_for_pago       = o_for_pago
	from #garantias_c
	
	if @@rowcount <> 0 return 0
    else
    begin
       select @w_error = 722214
       goto ERROR
    end
end

if @i_tipo = 'V' --Consulta Garantia Vigente
begin
    -- Agregada lectura a la tabla temporal #tipo_gar Req. 397
	if exists (select 1 from sysobjects where name = '#garantias_v')
       drop table #garantias_v
	
	select w_codigo_externo = cu_codigo_externo,
		   o_porcentaje     = gp_porcentaje,
		   o_tipo_gar       = 'ESPECIAL',
           o_tipo_sup       = tc_tipo_superior,
		   o_tipo           = tc_tipo,
		   o_subtipo_gar    = subtipo_gar, 
		   o_3nivel_gar     = ter_nivel_gar,
           o_for_pago       = convert(varchar(10),'') 
    into #garantias_v
	from cob_custodia..cu_custodia,
		 cob_credito..cr_gar_propuesta,
		 cob_cartera..ca_operacion,
		 cob_custodia..cu_tipo_custodia,
		 #colaterales, #tipo_gar
	where op_banco          = @i_banco
	and   op_tramite        = gp_tramite 
	and   gp_garantia       = cu_codigo_externo
	and   cu_tipo           = tc_tipo
	and   cu_estado         = 'V'
	and   tc_tipo_superior  = tipo_sub
	and   tipo_sub          = tipo_superior
	and   tipo              = tc_tipo 
	
    update #garantias_v
	set o_for_pago = codigo_sib
	from cob_credito..cr_corresp_sib
	where tabla = 'T303'
	and   codigo = o_tipo_sup
    
    select @w_codigo_externo = w_codigo_externo,
		   @o_porcentaje     = o_porcentaje,
		   @o_tipo_gar       = o_tipo_gar,
           @o_tipo_sup       = o_tipo_sup,
		   @o_tipo           = o_tipo,
		   @o_subtipo_gar    = o_subtipo_gar, 
		   @o_3nivel_gar     = o_3nivel_gar,
           @o_for_pago       = o_for_pago
    from #garantias_v
    
    if @@rowcount <> 0 return 0
    else
    begin
       select @w_error = 722215
       goto ERROR
    end
end

if @i_tipo = 'D' --Cancelacion
begin
	/***** CONSULTA SI LA OPERACION TIENE GARANTIA COLATERALES *****/
	select @w_codigo_externo = cu_codigo_externo
	from cob_custodia..cu_custodia with (nolock),
		 cob_credito..cr_gar_propuesta with (nolock),
		 cob_cartera..ca_operacion with (nolock),
		 cob_custodia..cu_tipo_custodia with (nolock),
		 #colaterales
	where op_banco          = @i_banco
	and   op_tramite        = gp_tramite 
	and   gp_garantia       = cu_codigo_externo
	and   cu_tipo           = tc_tipo
	and   tc_tipo_superior  = tipo_sub

    if @@rowcount = 0
    begin
       select @w_error = 722214
       goto ERROR
    end

   /* ACTUALIZA GARANTIA PROPUESTA */
   update cob_credito..cr_gar_propuesta
   set gp_est_garantia = 'X'
   where gp_garantia = @w_codigo_externo

   if @@error <> 0
   begin
      select @w_error = 724571  
      goto ERROR
   end

   /* CANCELA GARANTIA */
   update cob_custodia..cu_custodia
   set cu_fecha_modif        = @w_fecha_proceso,
       cu_fecha_modificacion = @w_fecha_proceso,
       cu_estado             = 'X'
   where cu_codigo_externo = @w_codigo_externo

   if @@error <> 0
   begin
      select @w_error = 724573  
      goto ERROR
   end

   /* ACTUALIZA OPERACION */
   update cob_cartera..ca_operacion
   set op_gar_admisible = 'N'
   where op_banco = @i_banco
   
   if @@error <> 0
   begin
      select @w_error = 724572
      goto ERROR
   end   
end

if @i_tipo = 'R' --Reverso
begin
	/***** CONSULTA SI LA OPERACION TIENE GARANTIA COLATERALES *****/
	select @w_codigo_externo = cu_codigo_externo
	from cob_custodia..cu_custodia with (nolock),
		 cob_credito..cr_gar_propuesta with (nolock),
		 cob_cartera..ca_operacion with (nolock),
		 cob_custodia..cu_tipo_custodia with (nolock),
		 #colaterales
	where op_banco          = @i_banco
	and   op_tramite        = gp_tramite 
	and   gp_garantia       = cu_codigo_externo
	and   cu_tipo           = tc_tipo
	and   tc_tipo_superior  = tipo_sub

    if @@rowcount = 0
    begin
       select @w_error = 722214
       goto ERROR
    end

   /* ACTUALIZA GARANTIA PROPUESTA */
   update cob_credito..cr_gar_propuesta
   set gp_est_garantia = 'V'
   where gp_garantia = @w_codigo_externo

   if @@error <> 0
   begin
      select @w_error = 724571  
      goto ERROR
   end   

   /* CANCELA GARANTIA */
   update cob_custodia..cu_custodia
   set cu_fecha_modif        = @w_fecha_proceso,
       cu_fecha_modificacion = @w_fecha_proceso,
       cu_estado             = 'V'
   where cu_codigo_externo = @w_codigo_externo

   if @@error <> 0
   begin
      select @w_error = 724573  
      goto ERROR
   end   

   /* ACTUALIZA OPERACION */
   update cob_cartera..ca_operacion
   set op_gar_admisible = 'S'
   where op_banco = @i_banco

   if @@error <> 0
   begin
      select @w_error = 724572
      goto ERROR
   end   
end

return 0

ERROR:
   if @i_llamado = 'F'
   begin
      exec cobis..sp_cerror
      @t_debug = 'N',    
      @t_file  = null,
      @t_from  = @w_sp_name,   
      @i_num   = @w_error
   end

   return @w_error

go