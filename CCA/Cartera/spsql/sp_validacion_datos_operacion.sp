/********************************************************************/
/*   NOMBRE LOGICO:      sp_validacion_datos_operacion              */
/*   NOMBRE FISICO:      sp_validacion_datos_operacion.sp           */
/*   BASE DE DATOS:      cob_cartera                                */
/*   PRODUCTO:           Cartera                                    */
/*   DISENADO POR:       Erwing Medina                              */
/*   FECHA DE ESCRITURA: 14-Jul-2023                                */
/********************************************************************/
/*                     IMPORTANTE                                   */
/*   Este programa es parte de los paquetes bancarios que son       */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  */
/*   representantes exclusivos para comercializar los productos y   */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida */
/*   y regida por las Leyes de la República de España y las         */
/*   correspondientes de la Unión Europea. Su copia, reproducción,  */
/*   alteración en cualquier sentido, ingeniería reversa,           */
/*   almacenamiento o cualquier uso no autorizado por cualquiera    */
/*   de los usuarios o personas que hayan accedido al presente      */
/*   sitio, queda expresamente prohibido; sin el debido             */
/*   consentimiento por escrito, de parte de los representantes de  */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  */
/*   en el presente texto, causará violaciones relacionadas con la  */
/*   propiedad intelectual y la confidencialidad de la información  */
/*   tratada; y por lo tanto, derivará en acciones legales civiles  */
/*   y penales en contra del infractor según corresponda.           */
/********************************************************************/
/*                     PROPOSITO                                    */
/*   Este programa genera un log de errores de cartera              */
/********************************************************************/
/*                     MODIFICACIONES                               */
/*   FECHA              AUTOR              RAZON                    */
/*   14-Jul-2023        Emedina            Emision Inicial          */
/*   10-Ago-2023        Emedina            Fix sp de error          */
/********************************************************************/
USE cob_cartera
GO

IF EXISTS(SELECT 1 FROM sysobjects WHERE NAME = 'sp_validacion_datos_operacion' AND TYPE = 'P')
    DROP PROCEDURE sp_validacion_datos_operacion
GO

CREATE PROCEDURE sp_validacion_datos_operacion
(
    @s_ssn      int          = NULL, 
    @s_date     datetime     = NULL, 
    @s_srv      varchar(30)  = NULL, 
    @s_lsrv     varchar(30)  = NULL, 
    @s_user     login        = NULL, 
    @s_term     descripcion  = NULL, 
    @s_corr     char(1)      = NULL, 
    @s_ssn_corr int          = NULL, 
    @s_ofi      smallint     = NULL, 
    @t_rty      char(1)      = NULL, 
    @t_trn      int          = NULL,  
    @t_from     varchar(30)  = NULL,
    @s_culture  varchar(10)  = 'NEUTRAL',
    @t_debug    char(1)      = 'N', 
    @t_file     varchar(14)  = NULL,
	@i_param1	int          , --Empresa
	@i_param2	datetime     , --Fecha
	@i_param3   CHAR(1)        --Modo_Ejecucion	 – (D) =DIARIO, (G) = GENERAL

) AS

DECLARE
    @w_sp_name               varchar(30),
    @w_mensaje               varchar(200),
    @w_today                 datetime, /*  fecha del dia  */ 
    @w_error                 int,
    @w_return                int,
    @w_fecha_proceso         datetime,
    @w_num_validacion 		 int ,
    @w_mensaje_val           varchar(255),--Campos de Operación
    @w_op_operacion          int, 
    @w_op_banco              cuenta,  
    @w_op_fecha_ult_proceso  datetime,-- Campos Dividendo
    @w_total_div             int,
    @w_coincidencias_div     int 

    

select @w_sp_name      = 'sp_validacion_datos_operacion'

select @w_fecha_proceso = fp_fecha
from cobis..ba_fecha_proceso

if @i_param3 not in('D' , 'G')
begin 
      	select @w_return = 725297 -- 'Error, opciones de Modo solo (D, G)'
      	goto ERROR	
end



if @i_param3 = 'D'
    begin
		declare cu_operacion cursor for
      	      select 
      	            op_operacion, op_banco, op_fecha_ult_proceso
      	      from  cob_cartera..ca_operacion
			  where op_estado not in (0,99,3)
			  and   op_operacion not in ( select bv_operacion
                   from cob_cartera..ca_batch_validaciones
                   where bv_fecha = @i_param2)
			  and op_banco in (
			    select tr_banco from cob_cartera..ca_transaccion
			    where tr_fecha_mov = @i_param2)   
    end
    
    
if @i_param3 = 'G'
	begin 
		declare cu_operacion cursor for
      	      select 
      	             op_operacion, op_banco, op_fecha_ult_proceso
      	      from cob_cartera..ca_operacion
			  where op_estado not in (0,99,3)
			  and   op_operacion not in ( select bv_operacion
                    from cob_cartera..ca_batch_validaciones
                    where bv_fecha = @i_param2)
	    
	end
	
	open cu_operacion
	fetch cu_operacion into
	        @w_op_operacion,
	        @w_op_banco,
	        @w_op_fecha_ult_proceso
	        	
	        
	while @@FETCH_STATUS = 0
	    begin
		    begin tran
		    
		    --Validación 1 
		    /*
		     * Si la fecha proceso del préstamo .op_fecha_ult_proceso
		     *  es diferente a la fecha proceso del sistema 
		     * */
		    if (@w_op_fecha_ult_proceso <> @w_fecha_proceso)
		    begin 
			     select @w_mensaje =  concat('ALERTA, FECHA PROCESO DE LA OPERACIÓN DISTINTA A LA FECHA PROCESO DEL SISTEMA: ' , convert(varchar , @w_op_fecha_ult_proceso,103)) 	       
		    	 exec @w_return = cob_conta..sp_errorcconta
		          @t_trn          = 60011,
		          @i_operacion    = 'I',
		          @i_empresa      = @i_param1,
		          @i_fecha        = @i_param2,
		          @i_producto     = 7, -- CARTERA
		          @i_tran_modulo  = @w_op_banco,
		          @i_asiento      = 0,
		          @i_fecha_conta  = @i_param2,
		          @i_numerror     = 1,
		          @i_mensaje      = @w_mensaje,
		          @i_perfil       = 0,
		          @i_valor        = 0,
		          @i_oficina      = 255,
		          @i_area         = 255
		          
		          if @w_return !=0
		          BEGIN 
		          	select @w_return = 1887629 -- No se pudo insertar el mensaje
		          	goto ERROR
		          END

		    end
		    		    
		    --Validación 2
		    /* Si la operación tiene dividendo con estado VIGENTE (ca_operacion.ca_dividendo where di_operacion = <operación del cursor> and di_estado = 1) 
             * entonces validar que la fecha proceso del sistema esté dentro del rango de las fechas del dividendo 
		     * */		    
		    if exists (
		    select 1 
		    from cob_cartera..ca_dividendo 
		    WHERE di_operacion = @w_op_operacion
		    and di_estado = 1
		    and @w_fecha_proceso not between di_fecha_ini and di_fecha_ven)
		    begin 
		    	
			    exec @w_return = cob_conta..sp_errorcconta
		          @t_trn          = 60011,
		          @i_operacion    = 'I',
		          @i_empresa      = @i_param1,
		          @i_fecha        = @i_param2,
		          @i_producto     = 7, -- CARTERA
		          @i_tran_modulo  = @w_op_banco,
		          @i_asiento      = 0,
		          @i_fecha_conta  = @i_param2,
		          @i_numerror     = 2,
		          @i_mensaje      = 'FECHA DE PROCESO DEL SISTEMA POR FUERA DEL DIVIDENDO VIGENTE',
		          @i_perfil       = 0,
		          @i_valor        = 0,
		          @i_oficina      = 255,
		          @i_area         = 255
		          
		          if @w_return !=0
		          BEGIN 
		          	select @w_return = 1887629 -- No se pudo insertar el mensaje
		          	goto ERROR
		          END			    
		    end
		    
            --Validación 3
		    /*
		     * Validar que las fechas de inicio y fechas fin de todos los dividendos del préstamo 
		     * (ca_dividendo.di_fecha_ini, ca_dividendo.di_fecha_ven) estén todas correctamente encadenadas
		     * */
		    select  @w_total_div = count(*)
                  from   cob_cartera..ca_dividendo
                  where  di_operacion = @w_op_operacion
               
            select  @w_coincidencias_div  = count(*)
                  from cob_cartera..ca_dividendo di1,
                       cob_cartera..ca_dividendo di2
                   where    di1.di_operacion = @w_op_operacion
                   and      di2.di_operacion = @w_op_operacion
                   and      di1.di_fecha_ven = di2.di_fecha_ini

            if @w_total_div != @w_coincidencias_div + 2
            begin 
			    exec @w_return = cob_conta..sp_errorcconta
		          @t_trn          = 60011,
		          @i_operacion    = 'I',
		          @i_empresa      = @i_param1,
		          @i_fecha        = @i_param2,
		          @i_producto     = 7, -- CARTERA
		          @i_tran_modulo  = @w_op_banco,
		          @i_asiento      = 0,
		          @i_fecha_conta  = @i_param2,
		          @i_numerror     = 3,
		          @i_mensaje      = 'ERROR, NO HAY CONSISTENCIA ENTRE LAS FECHAS INICIAL Y FINAL',
		          @i_perfil       = 0,
		          @i_valor        = 0,
		          @i_oficina      = 255,
		          @i_area         = 255
		          
		          if @w_return !=0
		          BEGIN 
		          	select @w_return = 1887629 -- No se pudo insertar el mensaje
		          	goto ERROR
		          END	            	
            end
            
    
		   insert into cob_cartera..ca_batch_validaciones
		   values (@i_param2 , @w_op_operacion )
		    
		    commit tran 

	    	fetch cu_operacion into
	    	@w_op_operacion,
	    	@w_op_banco,
	        @w_op_fecha_ult_proceso
	    end
	    
	close       cu_operacion
	deallocate  cu_operacion

print 'FIN'
return 0        

ERROR:
   exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = @w_return
   return @w_return
