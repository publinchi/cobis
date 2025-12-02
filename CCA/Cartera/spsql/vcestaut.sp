/************************************************************************/
/*   Archivo:              vcestaut.sp                                  */
/*   Stored procedure:     sp_veri_cambio_est_automatico                */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Credito y Cartera                            */
/*   Disenado por:         Raul Altamirano Mendez                       */
/*   Fecha de escritura:   Dic-19-2016                                  */
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
/*   Realiza verificaciones necesarias para efectuar cambios de estado  */
/*   automaticos de vigente a vencido y viceversa                       */
/************************************************************************/
/*                               CAMBIOS                                */
/*      FECHA          AUTOR            CAMBIO                          */
/*      DIC-19-2016    Raul Altamirano  Emision Inicial - Version MX    */
/*      AGO-06-2019    Adriana Giler    Cambio de estado a vencido      */
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_veri_cambio_est_automatico')
   drop proc sp_veri_cambio_est_automatico
go

SET ANSI_NULLS ON
GO


create proc sp_veri_cambio_est_automatico(
   @s_user                login,
   @s_term                varchar(30),
   @s_date                datetime,
   @s_ofi                 smallint,
   @i_operacionca         int,
   @i_debug               char(1) = 'N',
   @o_msg                 varchar(100) = null out) 

as 
declare
@w_return                int,
@w_sp_name               varchar(30),
@w_error                 int,
@w_estado                int,
@w_est_cancelado         tinyint,
@w_est_vigente           tinyint,
@w_est_vencido           tinyint,
@w_est_castigado         tinyint,
@w_fecha_ult_proceso     datetime,
@w_banco                 cuenta,
@w_operacionca           int,
@w_min_di_fecha_ven      datetime,
@w_dias_mora             smallint,
@w_dmora_pven_cuo_unica  tinyint,
@w_dmora_pven_cuo_normal tinyint,
@w_dmora_castigo         tinyint,
@w_dmora_paso_vencido    tinyint,
@w_ciudad_nacional       int,
@w_cambio_estado         char(1),
@w_verifica_mora         smallint,
@w_estado_ini            tinyint,
@w_estado_fin            tinyint,
@w_commit                char(1),
@w_fecha_sgte_mes        datetime,
@w_ref_grupal            cuenta,
@w_es_grupal             char(1)

select @w_commit = 'N'


---NUMERO DE DIAS DE MORA PARA REALIZAR EL PASO AUTOMATICO A VENCIDO - OPER. CUOTA UNICA
select @w_dmora_pven_cuo_unica = pa_tinyint
from  cobis..cl_parametro with (nolock)
where pa_producto = 'CCA'
and   pa_nemonico = 'DMOVCU'

if @@rowcount = 0 begin
   select @w_error = 710256
   goto ERROR
end

---NUMERO DE DIAS DE MORA PARA REALIZAR EL PASO AUTOMATICO A VENCIDO - OPER. NORMALES
select @w_dmora_pven_cuo_normal = pa_tinyint
from  cobis..cl_parametro with (nolock)
where pa_producto = 'CCA'
and   pa_nemonico = 'DMOVCN'

if @@rowcount = 0 begin
   select @w_error = 710256
   goto ERROR
end

---NUMERO DE DIAS DE MORA PARA REALIZAR EL PASO AUTOMATICO A CASTIGADO
select @w_dmora_castigo = pa_tinyint
from  cobis..cl_parametro with (nolock)
where pa_producto = 'CCA'
and   pa_nemonico = 'DMOCAS'

if @@rowcount = 0 begin
   select @w_error = 710256
   goto ERROR
end



--PARAMETRO CODIGO CIUDAD FERIADOS NACIONALES
select @w_ciudad_nacional = pa_int
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'CIUN'
and    pa_producto = 'ADM'

if @@rowcount = 0 begin
   select @w_error = 101024
   goto ERROR
end


--- ESTADOS DE CARTERA 
exec @w_error = sp_estados_cca
@o_est_cancelado  = @w_est_cancelado out,
@o_est_vigente    = @w_est_vigente   out,
@o_est_vencido    = @w_est_vencido   out,
@o_est_castigado  = @w_est_castigado out

if @@error <> 0  begin
   select @w_error = 710001, @o_msg = 'NO ENCONTRARON ESTADOS PARA CARTERA'
   goto ERROR
end

select 
@w_fecha_ult_proceso = op_fecha_ult_proceso,
@w_banco             = op_banco,
@w_estado            = op_estado,
@w_operacionca       = op_operacion,
@w_ref_grupal        = isnull(op_ref_grupal, ''),
@w_es_grupal         = isnull(op_grupal, 'N')
from   ca_operacion
where  op_operacion = @i_operacionca

if @@rowcount = 0                
   return 0

select 
@w_estado_ini = @w_estado,
@w_cambio_estado = 'N'

--INI AGI 08AGO19 --Si es una interciclo y su padre esta en castigo se castiga automaticamente
if ltrim(rtrim(@w_ref_grupal)) > ''
begin
    if exists (select 1 from ca_operacion where op_banco = @w_ref_grupal and op_estado = @w_est_castigado)
    begin
        select @w_estado_fin = @w_est_castigado,
               @w_cambio_estado = 'S'
    end
end
--FIN AGI

if @w_cambio_estado = 'N' and (@w_estado_ini = @w_est_vigente or @w_estado_ini = @w_est_vencido) --AGI 06AGO19 Validar si puede pasar a castigo
begin      
   if (select count(1) from ca_dividendo with (nolock)
       where  di_operacion = @w_operacionca
       and    di_estado    = @w_est_vencido) > 0        
   begin   
       select @w_min_di_fecha_ven = min(di_fecha_ven)
       from   ca_dividendo  with (nolock)
       where  di_operacion = @w_operacionca
       and    di_estado = @w_est_vencido
	   
	   exec @w_error = sp_dia_habil 
       @i_fecha  = @w_min_di_fecha_ven,
       @i_ciudad = @w_ciudad_nacional,
       @o_fecha  = @w_min_di_fecha_ven out
 
       if @w_error <> 0 goto ERROR

       select @w_dias_mora = 0

       select @w_dias_mora = isnull(datediff(dd, @w_min_di_fecha_ven, @w_fecha_ult_proceso), 0) 

	   select @w_verifica_mora = @w_dias_mora % 30  --Considerar meses de 30 dias
       
       if (select count(1) from ca_dividendo with (nolock)
           where  di_operacion = @w_operacionca) = 1        --OPERACIONES DE CUOTA UNICA
           select @w_dmora_paso_vencido = @w_dmora_pven_cuo_unica
       else if (select count(1) from ca_dividendo with (nolock)
                where  di_operacion = @w_operacionca) > 1   --OPERACIONES NORMALES
           select @w_dmora_paso_vencido = @w_dmora_pven_cuo_normal

       if @w_dias_mora >= @w_dmora_paso_vencido
            select 
            @w_estado_fin = @w_est_vencido,
            @w_cambio_estado = 'S'
        
        --AGI 06AGO19. Validar si por dias de mora pasa a castigo y es un fin de mes y es grupal
        if @w_dias_mora >= @w_dmora_castigo 
        begin
            if @w_es_grupal  = 'S'  --Operacion Grupal
            begin      
                select @w_fecha_sgte_mes = dateadd(dd,1,@w_fecha_ult_proceso)
                if datepart(mm, @w_fecha_sgte_mes) = datepart(mm, @w_fecha_ult_proceso)
                begin
                    exec @w_error = sp_dia_habil 
                         @i_fecha  = @w_fecha_sgte_mes,
                         @i_ciudad = @w_ciudad_nacional,
                         @o_fecha  = @w_fecha_sgte_mes  out
                     
                    if @w_error <> 0 goto ERROR
                end
                 
                
                if datepart(mm, @w_fecha_sgte_mes) <> datepart(mm, @w_fecha_ult_proceso)            
                    select @w_estado_fin = @w_est_castigado,
                           @w_cambio_estado = 'S'
            end 
            else --no es grupal 
                select @w_estado_fin = @w_est_castigado,
                       @w_cambio_estado = 'S'
        end
      
   end
end 
else
   if @w_cambio_estado = 'N'
       select 
       @w_estado_fin = @w_est_vigente,
       @w_cambio_estado = 'S'
   

if @@trancount = 0 begin
   begin tran    -- control de atomicidad
   select @w_commit = 'S'
end

select @w_sp_name = 'sp_cambio_estado_op'

if @i_debug = 'S' print 'Ejecutando sp: ' + @w_sp_name

if @w_cambio_estado = 'S' 
begin
   exec @w_error = sp_cambio_estado_op
   @s_user           = @s_user,
   @s_term           = @s_term,
   @s_date           = @s_date,
   @s_ofi            = @s_ofi,
   @i_banco          = @w_banco,
   @i_fecha_proceso  = @w_fecha_ult_proceso,
   @i_estado_ini     = @w_estado_ini,
   @i_estado_fin     = @w_estado_fin,
   @i_tipo_cambio    = 'A',
   @i_en_linea       = 'N'

   if @w_error <> 0 goto ERROR
end
   
if @w_commit = 'S' begin 
   commit tran
   select @w_commit = 'N'
end

return 0

ERROR:
if @w_commit = 'S'
   rollback tran

return @w_error

go

