/****************************************************************/
/*   ARCHIVO:         	sp_dias_atraso_grupal.sp                */
/*   NOMBRE LOGICO:   	sp_dias_atraso_grupal     	        */
/*   PRODUCTO:        		CARTERA                         */
/****************************************************************/
/*                     IMPORTANTE                           	*/
/*   Esta aplicacion es parte de los  paquetes bancarios    	*/
/*   propiedad de MACOSA S.A.                               	*/
/*   Su uso no autorizado queda  expresamente  prohibido    	*/
/*   asi como cualquier alteracion o agregado hecho  por    	*/
/*   alguno de sus usuarios sin el debido consentimiento    	*/
/*   por escrito de MACOSA.                                 	*/
/*   Este programa esta protegido por la ley de derechos    	*/
/*   de autor y por las convenciones  internacionales de    	*/
/*   propiedad intelectual.  Su uso  no  autorizado dara    	*/
/*   derecho a MACOSA para obtener ordenes  de secuestro    	*/
/*   o  retencion  y  para  perseguir  penalmente a  los    	*/
/*   autores de cualquier infraccion.                       	*/
/****************************************************************/
/*                     PROPOSITO                            	*/
/*   Este procedimiento permite obtener la el numero de ciclo   */
/*   de un cliente                                              */
/****************************************************************/
/*                     MODIFICACIONES                       	*/
/*   FECHA         AUTOR               RAZON                	*/
/*   11-May-2017   Sonia Rojas  Emision Inicial.     	        */
/*   May/2020      ACH          Caso: 139932                    */
/*   01-May-2020   ACH          Caso: 139932-doble desplazam    */
/*   08-Jul-2020   ACH          Caso:139932 dias_360 calcul+1dia*/
/****************************************************************/

use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_dias_atraso_grupal')
   DROP proc sp_dias_atraso_grupal
go

create proc sp_dias_atraso_grupal(
	@t_debug       		char(1)     = 'N',
	@t_file        		varchar(14) = null,
	@t_from        		varchar(30) = null,
    @i_grupo			int,
	@i_ciclos_ant		int,
	@i_es_ciclo_ant     char,
	@o_resultado    	int  out
)
as
declare	@w_sp_name 					varchar(64),
		@w_error					int,
		@w_grupo					int,
		@w_num_prestamos			int,
		@w_estado					int,
		@w_nro_ciclo_grupal_ant	    int,
		@w_nro_ciclo_grupal_act		int,
		@w_codigo_estado			int,
		@w_plazo					int,
		@w_max_diff					int,
		@w_total_retraso			int,
		@w_dividendo           		int,
		@w_rowcount            		int,
		@w_num_operaciones          int,
		@w_min_operacion            int,
		@w_max_cuotas_vencidas	  	int,
		@w_fecha_proceso            datetime,
		@w_existe_feriado           char,
		@w_ciudad_nacional          int,
		@w_fecha_ven                DATETIME,
		@w_max_diff_act				int,
		@w_max_cuotas_vencidas_act  int,
		@w_spid                     int

select @w_spid = @@spid
		
		
select @w_sp_name = 'sp_dias_retraso_grupal'

select @w_nro_ciclo_grupal_ant = (gr_num_ciclo + 1 ) - @i_ciclos_ant,
	   @w_nro_ciclo_grupal_act = gr_num_ciclo + 1
  from cobis..cl_grupo
 where gr_grupo = @i_grupo
 
 
print '@w_nro_ciclo_grupal_ant retraso: '+ convert(varchar, @w_nro_ciclo_grupal_ant)
print '@w_nro_ciclo_grupal_act retraso: '+ convert(varchar, @w_nro_ciclo_grupal_act)

--Encuentro la fecha de proceso
SELECT @w_fecha_proceso=fp_fecha FROM cobis..ba_fecha_proceso 

select @w_ciudad_nacional = pa_int
from   cobis..cl_parametro 
where  pa_nemonico = 'CIUN'
and    pa_producto = 'ADM'

if @i_es_ciclo_ant = 'N' and (@w_nro_ciclo_grupal_act = 1 or @w_nro_ciclo_grupal_act = 2)
begin	
	select @o_resultado = 0
	return 0
end

if @i_es_ciclo_ant = 'S' and @w_nro_ciclo_grupal_act = 1 
begin    
	select @o_resultado = 0
	return 0
end
	

if @w_nro_ciclo_grupal_ant = -1
begin    
	select @o_resultado = 0
	return 0
end
else 
begin

	select @w_dividendo = 1
	select @w_total_retraso = 0
	
	select @w_num_operaciones = count(dc_operacion),
		   @w_min_operacion   = min(dc_operacion)
	  from cob_cartera.. ca_det_ciclo,
	       cob_credito..cr_tramite_grupal
	 where dc_ciclo_grupo 	  = @w_nro_ciclo_grupal_ant
	   and dc_grupo 	      = @i_grupo
       and dc_operacion       = tg_operacion
	   and tg_monto           > 0
	
	--Se toma el plazo de una de las operaciones individuales del ciclo grupal
	select @w_plazo 	= count(di_dividendo) 
	  from cob_cartera..ca_dividendo
     where di_operacion = @w_min_operacion

		
	insert into cr_toperaciones_tmp
	select @w_spid, dc_operacion 
	     from cob_cartera.. ca_det_ciclo,
	          cob_credito..cr_tramite_grupal
	    where dc_ciclo_grupo 	= @w_nro_ciclo_grupal_ant
	      and dc_grupo 			= @i_grupo
	      and dc_operacion      = tg_operacion
	      and tg_monto          > 0
	      		  
	      SELECT  @w_max_diff_act=0
	      SELECT  @w_max_cuotas_vencidas_act=0
		  
	while @w_dividendo <= @w_plazo
	begin
	
		--PRINT'Cuota N- %1!', @w_dividendo

		select @w_max_diff = 0
		select @w_max_cuotas_vencidas=0
		
		--Encuentro la fecha de vencimiento
		
		select top 1  @w_fecha_ven=di_fecha_ven
	       from cob_cartera..ca_dividendo
		   where  di_operacion  in (select operacion from cr_toperaciones_tmp where spid = @w_spid)
		   and di_dividendo =  @w_dividendo
		   
		   --Verifico que la fecha de vencimiento no sea un dia Feriado 
		   
		select @w_existe_feriado = 'N'

           while exists(select 1 from cobis..cl_dias_feriados where df_ciudad = @w_ciudad_nacional and df_fecha = @w_fecha_ven) 
           begin
           
              select @w_fecha_ven = dateadd(dd, 1, @w_fecha_ven)
              SELECT @w_existe_feriado = 'S'
		
           end 
               
           if @w_existe_feriado ='N'
           begin
           
           	select @w_fecha_ven  AS 'Fecha de Vencimiento'
           		
           end
		
           --PRINT'4 @w_fecha_ven: %1!',@w_fecha_ven
		
		   select 	@w_max_diff              = max (case when datediff(dd, @w_fecha_ven, di_fecha_can) < 0 
		                                then 0 
						                        else datediff(dd, @w_fecha_ven, di_fecha_can)
					                            end)                
	      from cob_cartera..ca_dividendo
		 where di_operacion in (select operacion from cr_toperaciones_tmp where spid = @w_spid)
		   and di_dividendo =  @w_dividendo	
		   
		   --PRINT'@w_max_diff--> %1!', @w_max_diff
		   --PRINT'@w_max_diff_ant--> %1!', @w_max_diff_act
		     
		  IF(isnull(@w_max_diff,0)>isnull(@w_max_diff_act,0))
		   BEGIN
		   
           set @w_max_diff_act=isnull(@w_max_diff,0)
           --PRINT'Set @w_max_diff_act--> %1!', @w_max_diff_act
           
		  END

		   
		
        select @w_max_cuotas_vencidas   = max (case when datediff(dd,di_fecha_ven, @w_fecha_proceso  ) < 0 
		                                        then 0 
						                        else datediff(dd, di_fecha_ven,@w_fecha_proceso )
					                            end)                
	      from cob_cartera..ca_dividendo
		 where di_operacion in (select operacion from cr_toperaciones_tmp where spid = @w_spid)
		   and di_dividendo =  @w_dividendo				
		  and di_estado=2	
	
		   --PRINT'@w_max_cuotas_vencidas    --> %1!', @w_max_cuotas_vencidas 
		   --PRINT'@w_max_cuotas_vencidas_act--> %1!', @w_max_cuotas_vencidas_act
		     
		  IF(isnull(@w_max_cuotas_vencidas,0)>isnull(@w_max_cuotas_vencidas_act,0))
		   BEGIN
		   
           set @w_max_cuotas_vencidas_act=isnull(@w_max_cuotas_vencidas,0)
           --PRINT'Set @w_max_cuotas_vencidas_act--> %1!', @w_max_cuotas_vencidas_act
           
		  END
	
          /*if(@w_max_cuotas_vencidas is null)
          begin
          set @w_max_cuotas_vencidas=0
          end		   			
	   PRINT'@w_max_cuotas_vencidas'+  convert(VARCHAR(50), @w_max_cuotas_vencidas)
		--print '@w_dividendo: '+convert(varchar, @w_dividendo) + ', @w_max_diff: '+ convert(varchar, @w_max_diff)
		select @w_total_retraso = @w_total_retraso + @w_max_diff+@w_max_cuotas_vencidas*/
		select @w_dividendo = @w_dividendo + 1
		
	end--fin while
	
	IF(isnull(@w_max_diff_act,0)> isnull(@w_max_cuotas_vencidas_act,0))
	BEGIN
	 SET @w_total_retraso= isnull(@w_max_diff_act,0)
	 --PRINT'@w_max_diff_act es mayor --> %1!',@w_total_retraso
	END
	ELSE
	BEGIN
	 SET @w_total_retraso= isnull(@w_max_cuotas_vencidas_act,0)
	 --PRINT'@w_max_cuotas_vencidas_act es mayor o igual--> %1!',@w_total_retraso
	END
	
	select @o_resultado = isnull(@w_total_retraso,0)
    /* Se setea a 4 para validar pruebas */
 --   select @w_total_retraso = 4
 update cobis..cl_grupo
    set    gr_dias_atraso = isnull(@w_total_retraso,0)
    where gr_grupo = @i_grupo 

        IF(@w_total_retraso=0)
	BEGIN
		delete cr_toperaciones_tmp where spid = @w_spid
        print '---->> sp_dias_atraso_grupal: @o_resultado es 0: '+ convert(varchar, @o_resultado) + '-Cliente:'+convert(varchar, @i_grupo)
	select @o_resultado=0
	return 0
	END
    
	select @o_resultado = isnull(@w_total_retraso,0)
    delete cr_toperaciones_tmp where spid = @w_spid
	--print '---->> sp_dias_atraso_grupal: @o_resultado: %1! - Cliente: %2!', @o_resultado, @i_grupo
	return 0
end


	
	
if @o_resultado is null
begin
   delete cr_toperaciones_tmp where spid = @w_spid
   select @w_error = 6904007 --No existieron resultados asociados a la operacion indicada   
   exec   @w_error  = cobis..sp_cerror
          @t_debug  = 'N',
          @t_file   = '',
          @t_from   = @w_sp_name,
          @i_num    = @w_error
   return @w_error
end

delete cr_toperaciones_tmp where spid = @w_spid 
return 0

go
