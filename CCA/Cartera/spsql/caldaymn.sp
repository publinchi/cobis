/************************************************************************/
/*  Archivo:             caldaymn.sp                                    */
/*  Stored procedure:    sp_calculo_dias_tabla_manual                   */
/*  Base de datos:       cob_cartera                                    */
/*  Producto:            Cartera                                        */
/*  Disenado por:        Diego Aguilar                                  */
/*  Fecha de escritura:  Dic. 1999                                      */
/************************************************************************/
/*                             IMPORTANTE                               */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*  de 'COBISCorp'.                                                     */
/*  Su uso no    autorizado queda  expresamente   prohibido asi como    */
/*  cualquier    alteracion o  agregado  hecho por    alguno  de sus    */
/*  usuarios sin el debido consentimiento por   escrito de COBISCorp.   */
/*  Este programa esta protegido por la ley de   derechos de autor      */
/*  y por las    convenciones  internacionales   de  propiedad inte-    */
/*  lectual.    Su uso no  autorizado dara  derecho a    COBISCorp para */
/*  obtener ordenes  de secuestro o  retencion y para  perseguir        */
/*  penalmente a los autores de cualquier   infraccion.                 */
/************************************************************************/  
/*                                PROPOSITO                             */
/*  Calculo el numero de dias de cada cada cuota cuando es una tabla    */
/* manual                                                               */
/************************************************************************/  
/*                            MODIFICACIONES                            */    
/*       FECHA           AUTOR                    RAZON                 */   
/*      DIC-21-2005    EPB                   correccion calculo dias 360*/
/*      Abr-12-2022    CTI                   Ajuste feriados nacionales */ 
/************************************************************************/  
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_calculo_dias_tabla_manual')
    drop proc sp_calculo_dias_tabla_manual
go

create proc sp_calculo_dias_tabla_manual
   @s_user                         login,
   @s_sesn                         int,
   @i_operacionca                  int,
   @i_formato_fecha                int     = 101,
   @i_dias_anio            int     = 360,
   @i_evitar_feriados              char(1) = 'S',
   @i_base_calculo                 char(1) = 'R',
   @i_recalcular                   char(1) = 'N',
   @i_ult_dia_habil                char(1) = 'N',
   @i_actualiza_tasa               char(1) = 'N'
as
declare 
   @w_sp_name                      descripcion,
   @w_return                       int,
   @w_oficina                      smallint,
   @w_error                        int,
   @w_num_dividendos               int,
   @w_dividendo                    int,
   @w_dias_cuota                   int, --DAG
   @w_est_no_vigente               tinyint,
   @w_est_vigente                  tinyint,
   @w_di_fecha_ini                 datetime,
   @w_di_fecha_ven                 datetime,
   @w_di_fecha_ven_aux             datetime,
   @w_fecha_inicio_aux             datetime,
   @w_aux                      smallint,
   @w_offset                       int,
   @w_dia                          int,
   @w_mes                          int,
   @w_anio                         smallint,
   @w_num_dividendos_tmp           int,  
   @w_di_fecha_ini_tmp             datetime,
   @w_di_fecha_ven_tmp             datetime,
   @w_fecha_pri_cuot           datetime,
   @w_dia_fijo             tinyint,
   @w_dias_di_aux           int,
   @w_periodo_int            int,
   @w_tdividendo           catalogo,
   @w_ciudad_nacional      int,
   @w_ciudad_oficina       int

/* CARGA DE VARIABLES INICIALES */
select @w_sp_name = 'sp_calculo_dias_tabla_manual'


select 
@w_est_no_vigente = 0,
@w_est_vigente    = 1

select @w_offset = 0

-- PARAMETRO CODIGO CIUDAD FERIADOS NACIONALES
select @w_ciudad_nacional = pa_int
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'CIUN'
and    pa_producto = 'ADM'

select 
@w_oficina        = opt_oficina,
@w_fecha_pri_cuot = opt_fecha_pri_cuot,
@w_dia_fijo       = opt_dia_fijo,
@w_tdividendo     = opt_tdividendo,
@w_periodo_int    = opt_periodo_int
from ca_operacion_tmp
where opt_operacion = @i_operacionca


select @w_dias_di_aux = @w_periodo_int * td_factor
from   ca_tdividendo
where  td_tdividendo = @w_tdividendo

if @w_dias_di_aux = 0
begin
   select @w_error = 710007
   goto ERROR
end

if @i_actualiza_tasa = 'S' 
begin
   exec @w_return = sp_actualiza_rubros
   @i_operacionca = @i_operacionca

   if @w_return != 0 return @w_return
end


select sum(rot_porcentaje) --tasa de interes total
from ca_rubro_op_tmp
where rot_operacion  = @i_operacionca
and   rot_fpago      in ('P','A')
and   rot_tipo_rubro = 'I'


select @w_di_fecha_ini     = dia_fecha_ini,
       @w_di_fecha_ven     = dia_fecha_fin,
       @w_di_fecha_ini_tmp = dia_fecha_ini
from ca_diastablamanual
where dia_operacion = @i_operacionca
and dia_num_cuota = 1


select @w_dividendo    = 0,
       @w_aux          = 0


select @w_num_dividendos = max(dia_num_cuota) 
from ca_diastablamanual
where dia_operacion = @i_operacionca


if @w_num_dividendos > 555 
begin
   select @w_error = 710147
   goto ERROR
end



while @w_dividendo < @w_num_dividendos 
begin
   select @w_dividendo = @w_dividendo + 1

   select @w_di_fecha_ini = dia_fecha_ini,
          @w_di_fecha_ven = dia_fecha_fin
   from ca_diastablamanual
   where dia_operacion = @i_operacionca
   and dia_num_cuota = @w_dividendo
         
   if @i_base_calculo = 'R' 
      if @i_evitar_feriados = 'S' begin
         select @w_di_fecha_ven_tmp = @w_di_fecha_ven

   if @i_recalcular = 'N' 
      select @w_di_fecha_ini_tmp = dot_fecha_ini,
             @w_di_fecha_ven_tmp = dot_fecha_ven
      from ca_dividendo_original_tmp
      where dot_operacion = @i_operacionca
      and dot_dividendo = @w_dividendo

   select @w_dias_cuota=datediff(dd,@w_di_fecha_ini_tmp,@w_di_fecha_ven_tmp)

   --print 'DIAS CUOTA.1...%1!',@w_dias_cuota

   select @w_di_fecha_ini_tmp = @w_di_fecha_ven
end



if @i_base_calculo = 'E' 

   if @i_evitar_feriados = 'S'  
   begin
      select @w_di_fecha_ven_tmp = @w_di_fecha_ven

      if @i_recalcular = 'N' 
         select @w_di_fecha_ini_tmp = dot_fecha_ini,
                @w_di_fecha_ven_tmp = dot_fecha_ven
         from ca_dividendo_original_tmp
         where dot_operacion = @i_operacionca
         and dot_dividendo = @w_dividendo

      --print 'DIVIDENDO...%1!',@w_dividendo
      --print '@w_di_fecha_ini_tmp...%1!',@w_di_fecha_ini_tmp
      --print '@w_di_fecha_ven_tmp...%1!',@w_di_fecha_ven_tmp

      exec @w_return = sp_dias_base_comercial 
      @i_fecha_ini = @w_di_fecha_ini_tmp,
      @i_fecha_ven = @w_di_fecha_ven_tmp,
      @i_opcion    = 'D',
      @o_dias_int  = @w_dias_cuota out 

      select @w_di_fecha_ini_tmp = @w_di_fecha_ven
   end

   select @w_ciudad_oficina = of_ciudad 
   from   cobis..cl_oficina
   where  of_oficina        = @w_oficina

   /* CONTROL PARA EVITAR DIAS FERIADOS */
   while ( @i_evitar_feriados = 'S') 
   begin
      if exists(select 1
                from  cobis..cl_dias_feriados
                where  df_fecha   = @w_di_fecha_ven
                and    df_ciudad  in (@w_ciudad_nacional, @w_ciudad_oficina))
      begin
         if @i_ult_dia_habil = 'S' --DAG
            select  @w_di_fecha_ven = dateadd(dd, -1, @w_di_fecha_ven)
         else
            select  @w_di_fecha_ven = dateadd(dd, 1, @w_di_fecha_ven)
      end 
      else
         break
   end


   if @i_base_calculo = 'R' and @i_recalcular = 'N'
      if @i_evitar_feriados = 'N' 
         select @w_dias_cuota = datediff(dd,@w_di_fecha_ini,@w_di_fecha_ven)

   if @i_base_calculo = 'R' and @i_recalcular = 'S'
      select @w_dias_cuota = datediff(dd,@w_di_fecha_ini,@w_di_fecha_ven)

   if @i_base_calculo = 'E' and @i_evitar_feriados = 'N'  
   begin

     exec @w_return = sp_dias_cuota_360
     @i_fecha_ini = @w_di_fecha_ini,
     @i_fecha_fin = @w_di_fecha_ven,
     @o_dias      = @w_dias_cuota out 
                    
      
   end


   if @i_base_calculo = 'E' and @i_recalcular = 'S' 
   begin
      --TENGO QUE OBTENER EL NUMERO DE DIAS DE LA CUOTA TOMANDO EN CUENTA
      --QUE CADA MES PUEDE TENER 30 DIAS
      exec @w_return = sp_dias_cuota_360
      @i_fecha_ini = @w_di_fecha_ini,
      @i_fecha_fin = @w_di_fecha_ven,
      @o_dias      = @w_dias_cuota out 
     
   end

   --print 'DIAS CUOTA..NN..%1!',@w_dias_cuota
   --print '@w_di_fecha_ven..%1!',@w_di_fecha_ven

   update ca_diastablamanual
   set dia_num_dias    = @w_dias_cuota,
   dia_fecha_fin       = @w_di_fecha_ven
   where dia_operacion = @i_operacionca
   and dia_num_cuota = @w_dividendo  

   if @@error <> 0 
   begin
      select @w_error = 710001
      goto ERROR
   end

   update ca_diastablamanual
   set dia_fecha_ini   = @w_di_fecha_ven
   where dia_operacion = @i_operacionca
   and dia_num_cuota   = @w_dividendo + 1

   if @@error <> 0 
   begin
      select @w_error = 710001
      goto ERROR
   end
end --Lazo de dividendos

return 0

ERROR:

return @w_error
 
go
