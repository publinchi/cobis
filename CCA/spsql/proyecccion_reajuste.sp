/************************************************************************/
/*	Archivo:		proyecccion_reajuste.sp	                */
/*	Stored procedure:	sp_proyecccion_reajuste           	*/
/*	Base de datos:		cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		EMP-JJEC                                */
/*	Fecha de escritura:	Nov. 2020 				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	"MACOSA", representantes exclusivos para el Ecuador de la 	*/
/*	"NCR CORPORATION".						*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/************************************************************************/  
/*				PROPOSITO				*/
/*	Generar la proyección de un reajuste de un credito              */
/************************************************************************/  
/*      FECHA              AUTOR             CAMBIOS                    */
/*   14/11/2020          EMP-JJEC         Emision Inicial               */
/*  DIC-15-2020  Patricio Narvaez Incluir rubro FECI                    */
/************************************************************************/  
use cob_cartera
go

if exists (select 1 from sysobjects where name like 'sp_proyecccion_reajuste')
        drop proc sp_proyecccion_reajuste
go

create proc sp_proyecccion_reajuste(
        @s_user                 varchar(14) = NULL,
        @s_term                 varchar(30) = NULL,
        @s_date                 datetime    = NULL,
        @s_ofi                  smallint    = NULL,
        @i_banco                cuenta,
        @i_tipo                 char(1) = NULL,
        @i_fecha_reajuste       datetime = NULL,
        @i_porcentaje           float   = NULL,
        @i_debug                char(1) = 'N'
)as

declare @w_return             int,
        @w_estado             tinyint,
        @w_tdividendo         catalogo,
        @w_reajuste_periodo   int,
        @w_reajuste_fecha     datetime,
        @w_periodo_int        int,
        @w_fecha_ini          datetime,
        @w_fecha_fin          datetime,
        @w_operacionca        int,
        @w_error              int,
        @w_sp_name            descripcion,
        @w_fecha_ult_proceso  datetime,
        @w_reajuste_especial  char(1),
        @w_secuencial         int,
        @w_sector             catalogo,
        @w_reajustable        char(1),
        @w_concepto_int       catalogo,
        @w_dias_proyeccion    tinyint,
        @w_op_oficina         smallint,
        @w_desagio            char(1)

-- INICIALIZAR VARIABLES
select @w_sp_name = 'sp_proyecccion_reajuste',
       --@s_user    = isnull(@s_user, suser_name()),
       @s_user    = isnull(@s_user, 'sa'),       
       @s_term    = isnull(@s_term, 'BATCH_CARTERA'),
       @s_date    = convert(varchar(10),fc_fecha_cierre,101)
                    from   cobis..ba_fecha_cierre with (nolock)
                    where  fc_producto = 7

-- CODIGO DEL CONCEPTO INTERES
select @w_concepto_int = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'INT'

if @w_concepto_int is null
   select @w_concepto_int = 'INT'

-- MAXIMO DE DIAS PARA PROYECCION
select @w_dias_proyeccion = pa_tinyint
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'DIPROY'

if @w_dias_proyeccion is null
   select @w_dias_proyeccion = 90
   
  
-- INFORMACION DE LA OPERACION 
select 
@w_operacionca      = op_operacion,
@w_tdividendo       = op_tdividendo,
@w_reajuste_periodo = op_periodo_reajuste,
@w_reajuste_fecha   = op_fecha_reajuste,
@w_periodo_int      = op_periodo_int,
@w_fecha_ini        = op_fecha_ini,
@w_fecha_fin        = op_fecha_fin,
@w_estado           = op_estado,
@w_fecha_ult_proceso= op_fecha_ult_proceso,
@w_reajuste_especial= op_reajuste_especial,
@w_sector           = op_sector,
@w_reajustable      = op_reajustable,
@w_op_oficina       = op_oficina
from ca_operacion
where op_banco = @i_banco

if @s_ofi is null 
   select @s_ofi = @w_op_oficina

if @i_tipo = 'P' -- PROYECCION REAJUSTES
begin  
   -- VALIDAR CONSISTENCIA DE DATOS
   if @i_fecha_reajuste is null or @i_porcentaje is null or @i_porcentaje <= 0
   begin
      select @w_error = 703074
      goto ERROR
   end
   
   -- VALIDAR QUE LA FECHA A PROYECTAR NO SEA MAYOR A 90 DIAS
   if datediff(dd,@w_fecha_ult_proceso,@i_fecha_reajuste) > @w_dias_proyeccion
   begin
      select @w_error = 710212
      goto ERROR
   end

   -- APLICAR TASA REAJUSTE
   exec @w_secuencial = sp_gen_sec
        @i_operacion  = @w_operacionca

   BEGIN TRAN
   
   if isnull(@w_reajustable,'N') = 'S'
   begin
     -- SE ACTUALIZA YA QUE LA FECHA COINCIDE CON UNA EXISTENTE DE LA TABLA DE REAJUSTE
     if exists (select 1 from ca_reajuste where re_operacion = @w_operacionca and re_fecha = @i_fecha_reajuste)
     begin
         select @w_secuencial = re_secuencial
           from ca_reajuste 
          where re_operacion = @w_operacionca 
            and re_fecha = @i_fecha_reajuste
         
         update ca_reajuste_det
            set red_referencial = null,
                red_signo       = null,
                red_factor      = null,
                red_porcentaje  = @i_porcentaje
          where red_operacion  = @w_operacionca
            and red_secuencial = @w_secuencial
            and red_concepto   = @w_concepto_int
            
          if @@error != 0 
          begin
             select @w_error = 705045
             goto ERROR
          end
     end
     else -- SE INSERTA YA QUE LA FECHA NO COINCIDE CON UNA EXISTENTE DE LA TABLA DE REAJUSTE
     begin
        
        select @w_desagio = re_desagio from ca_reajuste where re_operacion = @w_operacionca
        
        -- INSERTAR DIRECTAMENTE EL PORCENTAJE A APLICAR
        insert into ca_reajuste 
        (re_secuencial,re_operacion,re_fecha,
         re_reajuste_especial, re_desagio)
        values 
        (@w_secuencial,@w_operacionca,@i_fecha_reajuste,
         @w_reajuste_especial, isnull(@w_desagio,'N'))
        
        if @@error != 0 begin
           select @w_error = 710001
           goto ERROR
        end
        
        insert into ca_reajuste_det (
        red_secuencial,red_operacion, red_concepto,red_referencial,
        red_signo,red_factor,red_porcentaje)
        values (
        @w_secuencial,@w_operacionca, @w_concepto_int,null,
        null,null,@i_porcentaje)
        
        if @@error != 0 begin
           select @w_error = 710001
           goto ERROR
        end
     end
   end
   else -- LA OPERACION NO ES REAJUSTABLE
   begin
      -- INSERTAR DIRECTAMENTE EL PORCENTAJE A APLICAR
      insert into ca_reajuste
      (re_secuencial,re_operacion,re_fecha,
       re_reajuste_especial, re_desagio)
      values 
      (@w_secuencial,@w_operacionca,@i_fecha_reajuste,
       @w_reajuste_especial, 'N')
      
      if @@error != 0 begin
         select @w_error = 710001
         goto ERROR
      end
      
      insert into ca_reajuste_det (
      red_secuencial,red_operacion, red_concepto,red_referencial,
      red_signo,red_factor,red_porcentaje)
      values (
      @w_secuencial,@w_operacionca,@w_concepto_int,null,
      null,null,@i_porcentaje)
      
      if @@error != 0 begin
         select @w_error = 710001
         goto ERROR
      end
   end

   select @i_fecha_reajuste = dateadd(dd,1,@i_fecha_reajuste) --un dia mas para que se aplique el reajuste

   -- EJECUCION DEL BATCH HASTA LA FECHA INDICADA
   exec @w_error     = sp_batch
   @s_user           = @s_user,
   @s_term           = @s_term,
   @s_date           = @s_date,
   @s_ofi            = @s_ofi,
   @i_en_linea       = 'N',
   @i_banco          = @i_banco,
   @i_siguiente_dia  = @i_fecha_reajuste,
   @i_pry_pago       = 'S',
   @i_param1         = 0,   --LPO CDIG Ajustes exec sp_batch
   @i_param4         = 'P', --LPO CDIG Ajustes exec sp_batch
   @i_control_fecha  = 'N',  --LPO CDIG Ajustes exec sp_batch
   @i_debug          = @i_debug
   
   if @w_error != 0 
   begin
      select @w_error = @w_error
      goto ERROR
   end


   -- DESPLIEGA LOS DATOS DE LA TABLA DE AMORTIZACION
   EXEC @w_return= cob_cartera..sp_qr_table_amortiza_web 
    @i_banco   = @i_banco,
    @i_opcion  = 'T'
    
   if @w_return !=0 
   begin   
     select @w_error =  @w_return 
     goto ERROR
   end    

   -- SE DESHACE LA ATOMICIDAD DE LA TRANSACCION POR SER PROYECCION
   while @@trancount > 0 ROLLBACK TRAN
   
end -- FIN OPCION P 


ERROR:
while @@trancount > 0 ROLLBACK TRAN
--Return @w_error

if @w_error > 0
exec cobis..sp_cerror 
@t_debug = 'N',
@t_file  = null,
@t_from  = @w_sp_name,  
@i_num   = @w_error

return 0

go

