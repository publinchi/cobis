/************************************************************************/
/*  Nombre Fisico:                   calificacion_cliente.sp            */
/*  Nombre Logico:                	 sp_calif_cliente_cca               */
/*  Base de datos:                   cob_cartera                        */
/*  Producto:                        CARTERA                            */
/*  Fecha de escritura:              19/05/2021                         */
/************************************************************************/
/*              IMPORTANTE                                              */
/*  Este programa es parte de los paquetes bancarios que son       		*/
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  	*/
/*   representantes exclusivos para comercializar los productos y   	*/
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida 	*/
/*   y regida por las Leyes de la República de España y las         	*/
/*   correspondientes de la Unión Europea. Su copia, reproducción,  	*/
/*   alteración en cualquier sentido, ingeniería reversa,           	*/
/*   almacenamiento o cualquier uso no autorizado por cualquiera    	*/
/*   de los usuarios o personas que hayan accedido al presente      	*/
/*   sitio, queda expresamente prohibido; sin el debido             	*/
/*   consentimiento por escrito, de parte de los representantes de  	*/
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  	*/
/*   en el presente texto, causará violaciones relacionadas con la  	*/
/*   propiedad intelectual y la confidencialidad de la información  	*/
/*   tratada; y por lo tanto, derivará en acciones legales civiles  	*/
/*   y penales en contra del infractor según corresponda. 				*/
/************************************************************************/
/*              PROPOSITO                                               */
/*  Calculo de la calificación de cliente                               */
/************************************************************************/
/*                       MODIFICACIONES                                 */
/*  FECHA        AUTOR        RAZON                                     */
/*  19-May-21    K.Rodríguez  Emision Inicial                           */
/*    06/06/2023	 M. Cordova		  Cambio variable @w_peorf_calif y  */
/*									  @w_peor_calif_tmp de char(1) a 	*/
/*									  catalogo							*/
/*    14/09/2023	 G. Fernandez	  R215286 Se elimina comentario     */
/*    21/08/2024	 K. Rodriguez	  R242371 Optimizacion proceso      */
/************************************************************************/

use cob_cartera
go

SET ANSI_NULLS OFF
go

SET QUOTED_IDENTIFIER OFF
go

if exists ( select 1 from sysobjects where name = 'sp_calif_cliente_cca')
   drop proc sp_calif_cliente_cca
go

create proc sp_calif_cliente_cca
(  
   @i_param1  int      = null, -- Sarta
   @i_param2  int      = null, -- Batch
   @i_param3  int      = null, -- Secuencial
   @i_param4  int      = null, -- Corrida  
   @i_param5  datetime = null  -- Fecha proceso
)
as declare
   @w_mensaje            varchar(100),
   @w_error              int,     
   @w_fec_proceso        datetime,
   @w_fecha_sgte_mes     datetime,
   @w_procesa            char(1),
   @w_ciudad_nacional    int,
   @w_nombre             varchar(50),
   @w_est_cancelado      tinyint,
   @w_est_suspenso       tinyint,
   @w_est_diferido       tinyint,
   @w_est_vigente        tinyint,
   @w_est_vencido        tinyint,
   @w_est_novigente      tinyint,
   @w_est_credito        tinyint,
   @w_cliente            int,
   @w_max_cliente        int,
   @w_peor_calif         catalogo,
   @w_peor_calif_tmp     catalogo,
   @w_oper_cli           int,
   @w_max_oper_cli       int


-- OBTENER FECHA PROCESO
if @i_param5 is not null and @i_param5 <> ''
begin
	select @w_fec_proceso = convert (Datetime, @i_param5)
end
else
begin
   select @w_fec_proceso = fp_fecha
   from cobis..ba_fecha_proceso
end  
 
 -- ESTADOS DE CARTERA
exec @w_error =sp_estados_cca
@o_est_cancelado  = @w_est_cancelado out,
@o_est_suspenso   = @w_est_suspenso  out,
@o_est_diferido   = @w_est_diferido  out,
@o_est_vigente    = @w_est_vigente   out,
@o_est_vencido    = @w_est_vencido   out,
@o_est_novigente  = @w_est_novigente out,
@o_est_credito    = @w_est_credito   OUT

if @w_error <> 0 goto ERROR 
   
 --PARAMETRO CÓDIGO CIUDAD FERIADOS NACIONALES
select @w_ciudad_nacional = pa_int
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'CIUN'
and    pa_producto = 'ADM'
   
/* VALIDAR FIN DE MES */
select @w_procesa = 'N'

select @w_fecha_sgte_mes = dateadd(dd, 1, @w_fec_proceso)

if datepart(mm, @w_fecha_sgte_mes) = datepart(mm, @w_fec_proceso)
begin
    exec @w_error = sp_dia_habil 
         @i_fecha  = @w_fecha_sgte_mes,
         @i_ciudad = @w_ciudad_nacional,
         @o_fecha  = @w_fecha_sgte_mes  out
     
    if @w_error <> 0 goto ERROR
end
 
if datepart(mm, @w_fecha_sgte_mes) <> datepart(mm, @w_fec_proceso)            
    select @w_procesa = 'S'

-- Procesa solo si es fin de mes
if @w_procesa = 'S'
begin
    
    -- *************************
    if object_id('tempdb..#tmp_dato_operacion') is not null
       drop table #tmp_dato_operacion
	   
    select * 
	into #tmp_dato_operacion
    from cob_conta_super..sb_dato_operacion
    where do_estado_cartera not in (@w_est_novigente, @w_est_credito, @w_est_cancelado)
    and do_fecha      = @w_fec_proceso
	and do_aplicativo = 7
	
	create index idx1 on #tmp_dato_operacion (do_codigo_cliente)
	create index idx2 on #tmp_dato_operacion (do_operacion)
	
   
    select @w_cliente = 0
 
    select @w_max_cliente =  max (DISTINCT do_codigo_cliente)
       from #tmp_dato_operacion
       where do_estado_cartera not in (@w_est_novigente, @w_est_credito, @w_est_cancelado)
	   and do_fecha = @w_fec_proceso
	
	-- Recorrido de cada diferente cliente    
    set rowcount 5000
    while 1=1 
    BEGIN
    
       select @w_cliente =  min (DISTINCT do_codigo_cliente)
	      from #tmp_dato_operacion
	      where do_estado_cartera not in (@w_est_novigente, @w_est_credito, @w_est_cancelado)
	      and do_codigo_cliente > @w_cliente
		  and do_fecha = @w_fec_proceso
		
		
		    SELECT @w_max_oper_cli = max (do_operacion)
			   from #tmp_dato_operacion
		       where do_estado_cartera not in (@w_est_novigente, @w_est_credito, @w_est_cancelado)
		       AND do_codigo_cliente = @w_cliente
		       and do_fecha = @w_fec_proceso
		    
		    SELECT @w_peor_calif = op_calificacion 
		       FROM ca_operacion
		       WHERE op_operacion = @w_max_oper_cli 
		       
		    SELECT @w_oper_cli = 0
		
		-- Recorre las operaciones del cliente
	 	WHILE 1 = 1
	 	BEGIN
		    SELECT @w_oper_cli = min (do_operacion)
				from #tmp_dato_operacion
			    where do_estado_cartera not in (@w_est_novigente, @w_est_credito, @w_est_cancelado)
			    AND do_operacion > @w_oper_cli
			    AND do_codigo_cliente = @w_cliente
			    and do_fecha = @w_fec_proceso
			    
		    SELECT @w_peor_calif_tmp = op_calificacion 
		       FROM ca_operacion
		       WHERE op_operacion = @w_oper_cli
		    
		    
		       IF @w_peor_calif_tmp > @w_peor_calif
		          SELECT @w_peor_calif = @w_peor_calif_tmp
		    
		    IF @w_max_oper_cli = @w_oper_cli OR @w_oper_cli = 0 OR @w_oper_cli IS NULL
		    BREAK
		    
	  	END -- Fin operaciones del cliente

	  	-- *** Actualiza cobis..cl_ente.en_calificacion
	  	    UPDATE cobis..cl_ente
	  	       SET en_calificacion = @w_peor_calif
	  	       WHERE en_ente = @w_cliente
	  	       
	  	    if @@error != 0
	        begin
	            SELECT @w_mensaje = 'Error actualizando calificación en tabla cl_ente'
	            goto ERROR
	        END
		
		IF @w_max_cliente = @w_cliente OR @w_cliente = 0 OR @w_cliente IS NULL
		 BREAK

    END -- Fin recorrido diferente cliente
        
    -- *************************
end -- Fin Procesa 

return 0

ERROR:

exec sp_errorlog 
	@i_fecha        = @w_fec_proceso,
	@i_error        = @w_error,
	@i_usuario      = 'usrbatch',
	@i_tran         = 26004,
	@i_descripcion  = @w_mensaje,
	@i_tran_name    = 'sp_calif_cliente_cca',
	@i_rollback     = 'N'
    
return @w_error
GO

