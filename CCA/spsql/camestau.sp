 /***********************************************************************/
/*Archivo               :     camestau.sp                               */
/*Stored procedure      :     sp_cambio_estado_automatico               */
/*Base de datos         :     cob_cartera                               */
/*Producto              :     Credito y Cartera                         */
/*Disenado por          :     Fabian de la Torre                        */
/*Fecha de escritura    :     31/08/1999                                */
/************************************************************************/
/* IMPORTANTE                                                           */
/* Este programa es parte de los paquetes bancarios propiedad de        */
/* COBISCORP S.A.representantes exclusivos para el Ecuador de la        */
/* AT&T                                                                 */
/* Su uso no autorizado queda expresamente prohibido asi como           */
/* cualquier autorizacion o agregado hecho por alguno de sus            */
/* usuario sin el debido consentimiento por escrito de la               */
/* Presidencia Ejecutiva de COBISCORP o su representante                */
/************************************************************************/
/*                                PROPOSITO                             */
/*Maneja los cambios de estado automaticos para las operaciones         */
/************************************************************************/
/*                                CAMBIOS                               */
/************************************************************************/
/*                              CAMBIOS                                 */
/*      FECHA          AUTOR            CAMBIO                          */
/*      DIC-07-2016    Raul Altamirano  Emision Inicial - Version MX    */
/*      AGO-06-2019    Adriana Giler    Cambio estado a vencido Grupal  */
/*  DIC/21/2020   P. Narvaez Añadir cambio de estado Judicial y Suspenso*/
/*  DIC/28/2021   G. Fernandez          Cambio a estado vencido a       */
/*                                      vencido-prorroga                */
/*  JUN/30/2021   K. Rodriguez          Est. Castigado no cambia a nin- */
/*                                      gun otro estado                 */    
/*  JUL/05/2023   G. Fernandez          Act. cambio de estado a vencidos*/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_cambio_estado_automatico')
drop proc sp_cambio_estado_automatico
go

create proc sp_cambio_estado_automatico(
   @s_user            login,
   @s_term            varchar(30),
   @s_date            datetime,
   @s_ofi             smallint,
   @i_toperacion      catalogo,
   @i_oficina         smallint,
   @i_banco           cuenta,
   @i_operacionca     int,
   @i_moneda          tinyint,
   @i_fecha_proceso   datetime,
   @i_en_linea        char(1),    
   @i_gerente         smallint,
   @i_estado_ini      tinyint,
   @i_moneda_nac      smallint,
   @i_cotizacion      float,
   @i_tcotizacion     char(1) = 'N',
   @i_num_dec         tinyint,
   @o_msg             varchar(100) = null out

) 

as 
declare
@w_sp_name               descripcion,
@w_return                int,
@w_di_dividendo          smallint,
@w_di_fecha_ven          datetime,
@w_est_vigente           tinyint,
@w_est_vencido           tinyint,
@w_est_novigente         tinyint,
@w_est_castigado         tinyint,
@w_num_dias              int,
@w_secuencia             int,
@w_max_dividendo         int,
@w_tipo_cambio           char(1),
@w_estado_ini            tinyint,
@w_estado_fin            tinyint,
@w_trn                   catalogo,
@w_min_dividendo_ven     smallint,     
@w_est_suspenso          tinyint,
@w_op_fecha_ult_proceo   datetime,
@w_es_grupal             char(1),
@w_ref_grupal            cuenta,
@w_ciudad_nacional       int,
@w_fecha_sgte_mes        datetime,
@w_cambia                char(1),
@w_base_calculo          char(1),
@w_est_judicial          tinyint,
@w_est_vencido_prorroga  tinyint  --GFP 28/12/2021

--- CARGAR VARIABLES DE TRABAJO 
select
@w_sp_name       = 'sp_cambio_estado_automatico',
@w_trn           = 'EST',  --EST (CAMBIO DE ESTADO AUTOMATICO)
@w_di_dividendo  = 0,
@w_num_dias      = 0,
@w_tipo_cambio   = 'A',
@w_est_judicial  = 5


--PARAMETRO CODIGO CIUDAD FERIADOS NACIONALES
select @w_ciudad_nacional = pa_int
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'CIUN'
and    pa_producto = 'ADM'

if @@rowcount = 0 begin
   select @o_msg = 'Error no existe parametro  [CIUN]'
   return 708201
end

--- CARGAR ESTADOS 
exec @w_return    = sp_estados_cca
@o_est_suspenso            = @w_est_suspenso  out,
@o_est_vigente             = @w_est_vigente   out,
@o_est_novigente           = @w_est_novigente out,
@o_est_vencido             = @w_est_vencido   out,
@o_est_castigado           = @w_est_castigado out,
@o_est_vencido_prorroga    = @w_est_vencido_prorroga   out --GFP 28/12/2021

if @w_return <> 0 return @w_return

-- DATOS DE LA OPERACION 
select
@w_estado_ini          = op_estado,
@w_op_fecha_ult_proceo = op_fecha_ult_proceso,
@w_ref_grupal         = isnull(op_ref_grupal, ''),
@w_es_grupal          = isnull(op_grupal, 'N'),
@w_base_calculo       = op_base_calculo
from ca_operacion
where op_operacion = @i_operacionca

select @w_num_dias = 0

---BUSCAR EL DIVIDENDO MAS VENCIDO, SI NO EXISTES DEBE PASAR A VIGENTE

select @w_min_dividendo_ven = isnull(min(di_dividendo), 0)
from   ca_dividendo
where  di_operacion  = @i_operacionca
and    di_estado     = @w_est_vencido

if @w_min_dividendo_ven = 0
   select @w_estado_fin = @w_est_vigente
else
begin
   select @w_di_fecha_ven = di_fecha_ven
   from   ca_dividendo
   where  di_operacion    = @i_operacionca
   and    di_dividendo    = @w_min_dividendo_ven

   --Numero de dias con base de calculo comercial
   if @w_base_calculo = 'E' 
   begin
      exec @w_return = sp_dias_cuota_360
      @i_fecha_ini   = @w_di_fecha_ven,
      @i_fecha_fin   = @i_fecha_proceso,
      @o_dias        = @w_num_dias out

      if @w_return <> 0 return @w_return

      select @w_num_dias = @w_num_dias + 1
     
   end
   else --base de calculo real
      select @w_num_dias = isnull(datediff(dd,@w_di_fecha_ven, @i_fecha_proceso),0) + 1

   --INI AGI 08AGO19 --Si es una interciclo y su padre esta en castigo se castiga automaticamente
   if @w_ref_grupal > ''
   begin
      if exists (select 1 from ca_det_ciclo where dc_operacion = @i_operacionca and dc_tciclo = 'I' )
      begin
         if exists (select 1 from ca_operacion where op_banco = @w_ref_grupal and op_estado = @w_est_castigado)
            select @w_estado_fin = @w_est_castigado,
                   @w_num_dias  = 9999,
                   @w_es_grupal = 'N'
       end
   end
   --FIN AGI

   --- SELECCIONAR EL NUEVO ESTADO DE LA OBLIGACION 
   select @w_estado_fin  = max(em_estado_fin)
   from   ca_estados_man
   where  em_toperacion  = @i_toperacion
   and    em_tipo_cambio = @w_tipo_cambio
   and    em_estado_ini  = @w_estado_ini
   and    em_dias_cont  <= @w_num_dias
   and    em_dias_fin   >= @w_num_dias   

   if @@rowcount = 0
      return 0
end

--- CONDICION DE SALIDA 
if @w_estado_fin is null 
   return 0

if @w_estado_ini = @w_estado_fin   
   return 0

--El estado judicial es manual, no se lo cambia por aqui.
if @w_estado_ini = @w_est_judicial
   return 0

if @w_estado_ini = @w_est_castigado -- KDR No se cambia un estado Castigado [El siguiente estado solo puede ser Cancelado]
   return 0

if @w_estado_fin = @w_est_vencido_prorroga  --GFP 28/12/2021
begin
   exec @w_return  = sp_cambio_estado_vencido_prorroga  --GFP 28/12/2021
   @s_user         = @s_user,
   @s_term         = @s_term,
   @i_operacionca  = @i_operacionca,
   @i_cotizacion   = @i_cotizacion,
   @i_tcotizacion  = @i_tcotizacion,
   @i_num_dec      = @i_num_dec,
   @o_msg          = @o_msg out
   
   if @w_return <> 0 return @w_return
end

if @w_estado_fin = @w_est_vencido
begin
   exec @w_return  = sp_cambio_estado_vencido
   @s_user         = @s_user,
   @s_term         = @s_term,
   @i_operacionca  = @i_operacionca,
   @i_cotizacion   = @i_cotizacion,
   @i_tcotizacion  = @i_tcotizacion,
   @i_num_dec      = @i_num_dec,
   @o_msg          = @o_msg out
   
   if @w_return <> 0 return @w_return
end

if @w_estado_fin = @w_est_vigente
begin
   exec @w_return  = sp_cambio_estado_vigente
   @s_user         = @s_user,
   @s_term         = @s_term,
   @i_operacionca  = @i_operacionca,
   @i_cotizacion   = @i_cotizacion,
   @i_tcotizacion  = @i_tcotizacion,
   @i_num_dec      = @i_num_dec,
   @o_msg          = @o_msg out

   if @w_return <> 0 return @w_return
end

if @w_estado_fin = @w_est_suspenso
begin
   exec @w_return  = sp_cambio_estado_suspenso
   @s_user         = @s_user,
   @s_term         = @s_term,
   @s_date         = @s_date,
   @i_banco        = @i_banco,
   @i_operacionca  = @i_operacionca,
   @i_toperacion   = @i_toperacion,
   @i_en_linea     = @i_en_linea,
   @i_gerente      = @i_gerente,
   @i_estado_ini   = @w_estado_ini,
   @i_estado_fin   = @w_estado_fin,
   @i_cotizacion   = @i_cotizacion,
   @i_tcotizacion  = @i_tcotizacion,
   @i_num_dec      = @i_num_dec

   if @w_return <> 0 return @w_return
end

--EN VERSION COREBASE NO SE USA CAMBIO ESTADO AUTOMATICO A CASTIGADO, SOLO SE QUITA DE LA PARAMETRIZACION
--INI AGI 06AGO19 Cambio estado a vencido si es grupal
if @w_estado_fin = @w_est_castigado 
begin
    select @w_cambia = 'S'
    
    --validar si es fin de mes  cuando es grupal y no interciclo
    if @w_es_grupal = 'S' 
    begin
        select @w_cambia = 'N'
        
        select @w_fecha_sgte_mes = dateadd(dd,1,@i_fecha_proceso)
        if datepart(mm, @w_fecha_sgte_mes) = datepart(mm, @i_fecha_proceso)
        begin
            exec @w_return = sp_dia_habil 
                 @i_fecha  = @w_fecha_sgte_mes,
                 @i_ciudad = @w_ciudad_nacional,
                 @o_fecha  = @w_fecha_sgte_mes  out
             
            if @w_return <> 0 
            begin   
                select @o_msg = 'Error ejecutando sp  sp_dia_habil  @i_operacionca  ' + cast (@i_operacionca as varchar)
                return 708208 --ERROR. Retorno de ejecucion de Stored Procedure Dia Habil
            end
        end
        
        if datepart(mm, @w_fecha_sgte_mes) <> datepart(mm, @i_fecha_proceso)  
            select @w_cambia = 'S'
    end 
    
    if @w_cambia = 'S'    
    begin        
        exec @w_return   = sp_cambio_estado_castigo
        @s_user         = @s_user,
        @s_term         = @s_term,
        @i_operacionca  = @i_operacionca,
        @i_cotizacion   = @i_cotizacion,
        @i_tcotizacion  = @i_tcotizacion,
        @i_num_dec      = @i_num_dec,
        @o_msg          = @o_msg out

        if @w_return <> 0 return @w_return
    end
end


update ca_operacion set
op_edad = op_estado
where op_operacion = @i_operacionca

if @@error <> 0 
   return 705066
  
return 0

go
