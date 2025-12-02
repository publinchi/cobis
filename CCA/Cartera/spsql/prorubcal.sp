/************************************************************************/
/*   Archivo             :       prorubcal.sp                           */
/*   Stored procedure    :       sp_procesa_rubros_calculados           */
/*   Base de datos       :       cob_cartera                            */
/*   Producto            :       Cartera                                */
/*   Disenado por        :       Kevin Rodríguez                        */
/*   Fecha de escritura  :       Diciembre 2021                         */
/************************************************************************/
/*                                IMPORTANTE                            */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBISCORP'.                                                       */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBISCORP o su representante.             */
/************************************************************************/
/*                                 PROPOSITO                            */
/*   Este programa realiza el procesamiento de rubros calculados        */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*  Autor             Fecha          Comentario                         */
/*  Kevin Rodríguez   21/Dic/2021    Emisión inicial                    */
/*  Kevin Rodríguez   07/Abr/2022    Actualización info monto autorizado*/
/*  Kevin Rodríguez   06/May/2022    Ajuste nro integrantes Grupal Padre*/
/*  Guisela Fernandez 01/Jun/2022    Se comenta prints                  */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_procesa_rubros_calculados')
   drop proc sp_procesa_rubros_calculados
go

create proc sp_procesa_rubros_calculados
   @s_date             datetime     = null,
   @s_user             login        = null,
   @s_term             varchar(30)  = null,
   @s_ssn              int          = null,
   @s_ofi              smallint     = null,
   @i_usar_tmp         char(1)     = 'S',
   @i_rubro            catalogo,
   @i_operacionca      int,
   @o_valor_rubro      money       = 0 out  
   
 
as declare
   @w_sp_name            varchar(30),
   @w_error              int, 
   @w_banco              cuenta,
   @w_es_grupal_aux      varchar(10),  
   @w_tramite_grp        int,
   @w_total_rubs_calc    money,
   
   @w_tramite            int,        
   @w_dias_frecuencia    smallint,
   @w_plazo              smallint,   
   @w_frecuencia_cuotas  catalogo,   
   @w_tipo_amortizacion  varchar(10),
   @w_es_grupal          varchar(10),
   @w_monto_solicitado   money,      
   @w_monto_autorizado   money,      
   @w_monto_financiado   money,
   @w_producto           catalogo,   
   @w_tasa               float,
   @w_tasa_IVA           float,
   @w_oficina            smallint,   
   @w_fecha_desembolso   datetime,
   @w_tipo_persona       char(1),    
   @w_fecha_nac          datetime,   
   @w_destino            catalogo,
   @w_clase_cartera      catalogo,
   @w_nro_deudores       smallint, 
   @w_nro_codeudores     smallint,
   @w_nro_fiadores       smallint,
   @w_pertenece_linea    char(1),
   @w_aprobado_linea     money,
   @w_disponible_linea   money,
   @w_tipo_solicitud     char(1),
   @w_moneda             tinyint,   
   @w_fecha_ven          datetime,  
   @w_nro_integrantes    smallint
   
 
-- Variables iniciales
select @w_sp_name   = 'sp_procesa_rubros_calculados',
       @w_es_grupal = 'N' 


if @i_usar_tmp = 'S'
begin

   -- Información operación
   select  
   @w_tramite           = opt_tramite,
   @w_dias_frecuencia   = opt_periodo_int * td.td_factor,
   @w_plazo             = opt_plazo,
   @w_frecuencia_cuotas = c.valor,                
   @w_tipo_amortizacion = opt_tipo_amortizacion,
   @w_monto_financiado  = opt_monto,
   @w_producto          = opt_toperacion, 
   @w_oficina           = opt_oficina,
   @w_fecha_desembolso  = opt_fecha_liq,
   @w_tipo_persona      = en_subtipo,
   @w_fecha_nac         = case en_subtipo when 'P' then p_fecha_nac else null end,
   @w_destino           = opt_destino,
   @w_clase_cartera     = opt_clase,
   @w_pertenece_linea   = case when opt_lin_credito is  null then 'N' else 'S' end,
   @w_moneda            = opt_moneda,
   @w_fecha_ven         = opt_fecha_fin,
   @w_banco             = opt_banco
   from ca_operacion_tmp, ca_tdividendo td, cobis..cl_ente, cobis..cl_tabla t, cobis..cl_catalogo c
   where opt_operacion  = @i_operacionca
   and   opt_tplazo     = td.td_tdividendo
   and   en_ente        = opt_cliente
   and   t.tabla        = 'ca_tdividendo'
   and   t.codigo       = c.tabla
   and   opt_tdividendo = c.codigo
   
   
   -- Tipo de préstamo (GRUPAL o INDIVIDUAL)
   /* -- KDR Se comenta sección ya que XSell aun no llena las tablas ca_ciclo y ca_det_ciclo en la asociación de rubros al préstamo.
   --Operacion Grupal
   if exists(select 1
      from ca_operacion_tmp, ca_ciclo
      where opt_operacion = ci_operacion
      and opt_grupal = 'S'
      and opt_ref_grupal is null
      and opt_banco = @w_banco)
   begin
       Select @w_es_grupal = 'G'
   end 
   
      --Operacion Interciclo
   if exists(select 1
      from ca_operacion_tmp, ca_det_ciclo
      where opt_operacion = dc_operacion
      and opt_banco = @w_banco
      and (opt_grupal = 'N' or opt_grupal is null)
      and opt_ref_grupal is not null
      and dc_tciclo = 'I')
   begin
       Select @w_es_grupal = 'I'
   end
      
      --Operacion Individual
   if exists(select 1
      from ca_operacion_tmp
      where opt_banco = @w_banco	   
      and (opt_grupal = 'N' or opt_grupal is null)
      and opt_operacion not in (select dc_operacion from ca_det_ciclo))
   begin
       Select @w_es_grupal = 'N'
   end
      
   --Operacion Hija
   if exists(select 1
     from ca_operacion_tmp, ca_det_ciclo
    where opt_operacion = dc_operacion
      and opt_banco = @w_banco
      and opt_grupal = 'S'
      and opt_ref_grupal is not null
      and dc_tciclo = 'N')
   begin
       Select @w_es_grupal = 'H'
   end*/
   
   
   --Operacion Grupal Hija
   if exists(select 1
      from cob_credito..cr_tramite_grupal, ca_operacion_tmp
      where tg_operacion = @i_operacionca
      and tg_operacion   = opt_operacion
      and opt_grupal = 'S'
      and opt_ref_grupal is not null)
   begin
      select @w_es_grupal = 'H'
   end 
   
   --Operacion Grupal Padre
   if exists(select 1
      from cob_credito..cr_tramite, cob_credito..cr_tramite_grupal, ca_operacion_tmp
      where tr_tramite = @w_tramite
      and tr_tramite   = tg_tramite
      and tr_tramite = opt_tramite
      and opt_grupal = 'S'
	  and opt_ref_grupal is null)
   begin
      select @w_es_grupal = 'G'
   end
   
   --Operacion Individual  
   if exists(select 1
	  from ca_operacion_tmp o
	  where o.opt_banco = @w_banco		   
	  and (o.opt_grupal = 'N' or o.opt_grupal is null))
	        and not exists (select 1 from cob_credito..cr_tramite_grupal where tg_operacion = @i_operacionca) 
	begin
	    select @w_es_grupal = 'N'
	end
   
    -- Tasa de interés nominal anual 
    select @w_tasa = rot_porcentaje
    from ca_rubro_op_tmp
    where rot_operacion  = @i_operacionca
    and   rot_concepto   = 'INT'
   
    -- Sumatoria de monto de rubros financiados
    select @w_total_rubs_calc = sum(isnull(rot_valor, 0)) 
	from ca_rubro_op_tmp
    where rot_operacion = @i_operacionca
    and rot_financiado = 'S'
       
end
else
begin
   
   -- Información operación
   select  
   @w_tramite           = op_tramite,
   @w_dias_frecuencia   = op_periodo_int * td.td_factor,
   @w_plazo             = op_plazo,
   @w_frecuencia_cuotas = c.valor,                
   @w_tipo_amortizacion = op_tipo_amortizacion,
   @w_monto_financiado  = op_monto,
   @w_producto          = op_toperacion, 
   @w_oficina           = op_oficina,
   @w_fecha_desembolso  = op_fecha_liq,
   @w_tipo_persona      = en_subtipo,
   @w_fecha_nac         = case en_subtipo when 'P' then p_fecha_nac else null end,
   @w_destino           = op_destino,
   @w_clase_cartera     = op_clase,
   @w_pertenece_linea   = case when op_lin_credito is  null then 'N' else 'S' end,
   @w_moneda            = op_moneda,
   @w_fecha_ven         = op_fecha_fin,
   @w_banco             = op_banco
   from ca_operacion, ca_tdividendo td, cobis..cl_ente, cobis..cl_tabla t, cobis..cl_catalogo c
   where op_operacion  = @i_operacionca
   and   op_tplazo     = td.td_tdividendo
   and   en_ente       = op_cliente
   and   t.tabla       = 'ca_tdividendo'
   and   t.codigo      = c.tabla
   and   op_tdividendo = c.codigo
   
   -- Tipo de préstamo (GRUPAL o INDIVIDUAL)
   /* -- KDR Se comenta sección ya que XSell aun no llena las tablas ca_ciclo y ca_det_ciclo en la asociación de rubros al préstamo.
   exec @w_error = sp_tipo_operacion
        @i_banco  = @w_banco,
        @o_tipo   = @w_es_grupal out
   
   if @w_error <> 0 goto ERROR*/
   
   --Operacion Grupal Hija
   if exists(select 1
      from cob_credito..cr_tramite_grupal, ca_operacion
      where tg_operacion = @i_operacionca
      and tg_operacion   = op_operacion
      and op_grupal = 'S'
      and op_ref_grupal is not null)
   begin
      select @w_es_grupal = 'H'
   end 
   
   --Operacion Grupal Padre
   if exists(select 1
      from cob_credito..cr_tramite, cob_credito..cr_tramite_grupal, ca_operacion
      where tr_tramite = @w_tramite
      and tr_tramite   = tg_tramite
      and tr_tramite = op_tramite
      and op_grupal = 'S'
	  and op_ref_grupal is null)
   begin
      select @w_es_grupal = 'G'
   end
   
   --Operacion Individual  
   if exists(select 1
	  from ca_operacion o
	  where o.op_banco = @w_banco		   
	  and (o.op_grupal = 'N' or o.op_grupal is null))
	        and not exists (select 1 from cob_credito..cr_tramite_grupal where tg_operacion = @i_operacionca) 
	begin
	    select @w_es_grupal = 'N'
	end
   
   -- Tasa de interés nominal anual 
   select @w_tasa = ro_porcentaje
   from ca_rubro_op
   where ro_operacion  = @i_operacionca
   and   ro_concepto   = 'INT'

    -- Sumatoria de monto de rubros financiados
    select @w_total_rubs_calc = sum(isnull(ro_valor, 0)) 
	from ca_rubro_op
    where ro_operacion = @i_operacionca
    and ro_financiado = 'S'  
  
end

-- Información trámite
select
@w_tramite           = tr_tramite,
@w_monto_solicitado  = tr_monto_solicitado,
@w_tipo_solicitud    = tr_tipo
from cob_credito..cr_tramite
where tr_tramite = @w_tramite
 
-- Monto autorizado
select @w_monto_autorizado =  @w_monto_financiado - isnull(@w_total_rubs_calc, 0)

-- Si el tramite esta null, se asume que el procesamiento del rubro calculado fue realizado a los rubros por defecto desde la creación de operación desde Cartera,
-- por tal motivo, el valor del Monto solicitado se lo tomará del valor del monto autorizado, además los valores que dependen del número de trámite, serán establecidos
-- según los valores por defecto (Ver apartado de Valores por Defecto).
if @w_tramite is NULL
    select @w_monto_solicitado = @w_monto_autorizado

 if @w_es_grupal = '' or @w_es_grupal is null
 begin
    --GFP se suprime print
    --print 'No existe la operacion' 
    select @w_error = 725054
    goto ERROR
 end 
 
-- Verifica si la operación es grupal o no.
select @w_es_grupal_aux = @w_es_grupal
select @w_es_grupal = case @w_es_grupal when 'G' then 'GRUPAL' when 'H' then 'GRUPAL' ELSE 'INDIVIDUAL' end 
   
-- Tasa o porcentaje IVA
select @w_tasa_IVA = pa_float 
from cobis..cl_parametro 
where pa_producto = 'ATX'
and pa_nemonico = 'IVATEL'


-- Consulta Nro deudores, codeudores y fiadores
if @w_es_grupal = 'GRUPAL'
begin
   if @w_es_grupal_aux = 'H'
   begin
      select @w_monto_solicitado = tg_monto
      from cob_credito..cr_tramite_grupal 
      where tg_tramite = @w_tramite 
      and tg_operacion = @i_operacionca
	  
	  select @w_tramite_grp = tg_tramite
      from cob_credito..cr_tramite_grupal 
      where tg_operacion       = @i_operacionca
      and   tg_participa_ciclo = 'S'	   
   end
   else
   begin
      select @w_tramite_grp = @w_tramite         -- KDR Si es grupal Padre 
   end  
   
   select @w_nro_deudores = count(distinct(tg_cliente)) 
   from cob_credito..cr_tramite_grupal 
   where tg_tramite         = @w_tramite_grp
   and   tg_participa_ciclo = 'S'
   
   select @w_nro_codeudores = 0
   
   select @w_nro_fiadores = 0
   
   select @w_nro_integrantes = count(1)
   from cobis..cl_cliente_grupo, cob_credito..cr_tramite_grupal  
   where tg_tramite = @w_tramite_grp
   and   tg_grupo   = cg_grupo
   and   cg_ente    = tg_cliente
   
end
else
begin
   select @w_nro_deudores = 1
   
   select @w_nro_codeudores = count(1) 
   from cob_credito..cr_deudores 
   where de_tramite = @w_tramite
   and   de_rol     = 'C'
   
   select @w_nro_fiadores = count(1)
   from cob_credito..cr_gar_propuesta, cob_custodia..cu_custodia, cob_custodia..cu_tipo_custodia
   where gp_tramite = @w_tramite
   AND gp_garantia = cu_codigo_externo
   AND cu_tipo = tc_tipo
   AND tc_tipo = 'GARGPE'
   
   select @w_nro_integrantes = 1
   
end


-- Información línea de crédito
if @i_usar_tmp = 'S'
begin
   select @w_aprobado_linea    = isnull(li_monto, 0),
          @w_disponible_linea  = isnull((li_monto - li_utilizado),0)
   from ca_operacion_tmp, cob_credito..cr_linea
   where opt_operacion = @i_operacionca
   and opt_lin_credito = li_num_banco
end
else
begin
   select @w_aprobado_linea    = isnull(li_monto, 0),
          @w_disponible_linea  = isnull((li_monto - li_utilizado),0)
   from ca_operacion, cob_credito..cr_linea
   where op_operacion = @i_operacionca
   and op_lin_credito = li_num_banco
end

select @w_aprobado_linea = isnull(@w_aprobado_linea, 0)
select @w_disponible_linea = isnull(@w_disponible_linea, 0)

-- [Valores por Defecto] Valores por defecto si alguno no es llenado con algun valor 
select @w_tramite = isnull(@w_tramite, 1)
select @w_es_grupal = isnull(@w_es_grupal, 'INDIVIDUAL')
select @w_nro_deudores =     isnull(@w_nro_deudores, 1)
select @w_nro_codeudores =   isnull(@w_nro_codeudores, 0)
select @w_nro_fiadores =     isnull(@w_nro_fiadores, 0)
select @w_tipo_solicitud = isnull(@w_tipo_solicitud, 'O')
select @w_nro_integrantes =  isnull( @w_nro_integrantes, 1)

-- Inserción de datos en tabla (Histórico)
insert into ca_proc_rubro_calculados_ts values(
@i_operacionca       ,getdate()            ,@i_rubro             ,@w_tramite       ,@w_dias_frecuencia   ,
@w_plazo             ,@w_frecuencia_cuotas ,@w_tipo_amortizacion ,@w_es_grupal     ,@w_monto_solicitado  ,
@w_monto_autorizado  ,@w_monto_financiado  ,@w_producto          ,@w_tasa          ,@w_tasa_IVA          ,
@w_oficina           ,@w_fecha_desembolso  ,@w_tipo_persona      ,@w_fecha_nac     ,@w_destino           ,
@w_clase_cartera     ,@w_nro_deudores      ,@w_nro_codeudores    ,@w_nro_fiadores  ,@w_pertenece_linea   ,
@w_aprobado_linea    ,@w_disponible_linea  ,@w_tipo_solicitud    ,@w_moneda        ,@w_fecha_ven         ,
@w_nro_integrantes 
)

if @@error <> 0 
begin
   --GFP se suprime print
   --print '[sp_procesa_rubros_calculados] Error la insertar registro en ca_proc_rubro_calculados_ts'
   select @w_error = 70129 -- ERROR AL INSERTAR REGISTRO
   goto ERROR
end

-- Programa que contiene la lógica de cálculo según rubro.
exec @w_error = cob_externos..sp_cca_interfaz_rubros_calculados 
@i_rubro             = @i_rubro,    
@i_tramite           = @w_tramite,
@i_dias_frecuencia   = @w_dias_frecuencia,
@i_plazo             = @w_plazo,
@i_frecuencia_cuotas = @w_frecuencia_cuotas,
@i_tipo_amortizacion = @w_tipo_amortizacion,
@i_es_grupal         = @w_es_grupal,
@i_monto_solicitado  = @w_monto_solicitado,
@i_monto_autorizado  = @w_monto_autorizado,
@i_monto_financiado  = @w_monto_financiado,
@i_producto          = @w_producto,
@i_tasa              = @w_tasa,
@i_tasa_IVA          = @w_tasa_IVA,
@i_oficina           = @w_oficina,
@i_fecha_desembolso  = @w_fecha_desembolso,
@i_tipo_persona      = @w_tipo_persona,
@i_fecha_nac         = @w_fecha_nac,
@i_destino           = @w_destino,
@i_clase_cartera     = @w_clase_cartera,
@i_nro_deudores      = @w_nro_deudores,
@i_nro_codeudores    = @w_nro_codeudores,
@i_nro_fiadores      = @w_nro_fiadores,
@i_pertenece_linea   = @w_pertenece_linea,
@i_aprobado_linea    = @w_aprobado_linea,
@i_disponible_linea  = @w_disponible_linea,
@i_tipo_solicitud    = @w_tipo_solicitud,
@i_moneda            = @w_moneda,
@i_fecha_ven         = @w_fecha_ven,
@i_nro_integrantes   = @w_nro_integrantes,
@o_valor_rubro       = @o_valor_rubro out

if @w_error <> 0 
    goto ERROR

return 0

ERROR:
return @w_error

GO
