/*************************************************************************/
/*   Archivo:              pasa_custodia_mig.s                           */
/*   Stored procedure:     sp_pasa_custodia_mig                          */
/*   Base de datos:        cob_custodia                                  */
/*   Producto:             Garantias                                     */
/*   Disenado por:                                                       */
/*   Fecha de escritura:   Marzo 2019                                    */
/*************************************************************************/
/*                                  IMPORTANTE                           */
/*   Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*   de MACOSA S.A.                                                      */
/*   Su uso no autorizado queda expresamente prohibido asi como          */
/*   cualquier alteracion o agregado hecho por alguno de sus             */
/*   usuarios sin el debido consentimiento por escrito de MACOSA         */
/*   Este programa esta protegido por la ley de derechos de autor        */
/*   y por las  convenciones  internacionales de  propiedad inte-        */
/*   lectual.  Su uso no  autorizado dara  derecho a  MACOSA para        */
/*   obtener  ordenes de  secuestro o retencion y  para perseguir        */
/*   penalmente a los autores de cualquier infraccion.                   */
/*************************************************************************/
/*                                   PROPOSITO                           */
/*    Creacion de objetos de la base. Comprende: tablas, indices,sp      */
/*    tipos de datos, claves primarias y foraneas                        */
/*                                                                       */
/*			                                                             */
/*************************************************************************/
/*                             MODIFICACION                              */
/*    FECHA                   AUTOR                 RAZON                */
/*    Marzo/2019                                      emision inicial    */
/*                                                                       */
/*************************************************************************/
USE cob_custodia
go
IF OBJECT_ID('dbo.sp_pasa_custodia_mig') IS NOT NULL
    DROP PROCEDURE dbo.sp_pasa_custodia_mig
go
create procedure dbo.sp_pasa_custodia_mig as
declare

@w_cu_filial                      tinyint,
@w_cu_migrada                     varchar(64), 
@w_cu_sucursal                    smallint,
@w_cu_tipo                        descripcion, 
@w_cu_tipo1                       descripcion, 
@w_cu_custodia                    int,
@w_cu_propuesta                   int,
@w_cu_estado                      catalogo,
@w_cu_fecha_ingreso               datetime,
@w_cu_valor_inicial               money,
@w_cu_valor_actual                money,
@w_cu_moneda                      tinyint,
@w_cu_garante                     int,
@w_cu_instruccion                 varchar(255),
@w_cu_descripcion                 varchar(255),
@w_cu_poliza                      varchar(20), 
@w_cu_inspeccionar                char(1),  
@w_cu_motivo_noinsp               catalogo,
@w_cu_suficiencia_legal           char(1),  
@w_cu_fuente_valor                catalogo,
@w_cu_situacion                   char(1),  
@w_cu_almacenera                  smallint,
@w_cu_aseguradora                 varchar(20), 
@w_cu_cta_inspeccion              ctacliente,
@w_cu_tipo_cta                    varchar(8),  
@w_cu_direccion_prenda            descripcion, 
@w_cu_ciudad_prenda               descripcion,
@w_cu_telefono_prenda             varchar(20), 
@w_cu_mex_prx_inspec              tinyint,
@w_cu_fecha_modif                 datetime,
@w_cu_fecha_const                 datetime,
@w_cu_porcentaje_valor            float,
@w_cu_periodicidad                catalogo,
@w_cu_depositario                 varchar(255),
@w_cu_posee_poliza                char(1),  
@w_cu_nro_inspecciones            tinyint,
@w_cu_intervalo                   tinyint, 
@w_cu_cobranza_judicial           char(1),  
@w_cu_fecha_retiro                datetime,
@w_cu_fecha_devolucion            datetime,
@w_cu_fecha_modificacion          datetime,
@w_cu_usuario_crea                descripcion,
@w_cu_usuario_modifica            descripcion,
@w_cu_estado_poliza               char(1),  
@w_cu_cobrar_comision             char(1),  
@w_cu_cuenta_dpf                  varchar(30), 
@w_cu_codigo_externo              varchar(64), 
@w_cu_fecha_insp                  datetime,  
@w_cu_abierta_cerrada             char(1),
@w_cu_adecuada_noadec             char(1),
@w_cu_propietario                 varchar(64), 
@w_cu_plazo_fijo                  varchar(30), 
@w_cu_monto_pfijo                  money,
@w_cu_oficina                     smallint,
@w_cu_oficina_contabiliza         smallint,
@w_cu_compartida                  char(1),
@w_cu_valor_compartida            money,
@w_cu_fecha_reg                   datetime,
@w_cu_fecha_prox_insp             datetime,
@w_estado                         varchar,
@w_codigo_externo		  varchar(64),
@w_codigo_externo1		  varchar(64),
@w_error			  int,
@w_msg			          varchar(65),
@contador			  int,
@w_custodia	                  int,
@cliente			  int

	select @contador=0
	
	truncate table cu_custodia
	truncate table cu_cliente_garantia
	truncate table cu_seqnos

	declare fcursor cursor for
	select cu_filial,cu_migrada,cu_sucursal,cu_tipo,cu_custodia,cu_propuesta,
	       cu_estado,cu_fecha_ingreso,cu_valor_inicial,cu_valor_actual,
	       cu_moneda,cu_garante,cu_instruccion,cu_descripcion,cu_poliza,  
	       cu_inspeccionar,cu_motivo_noinsp,cu_suficiencia_legal,cu_fuente_valor,
	       cu_situacion,cu_almacenera,cu_aseguradora,cu_cta_inspeccion,cu_tipo_cta,
	       cu_direccion_prenda,cu_ciudad_prenda,cu_telefono_prenda,cu_mex_prx_inspec,
	       cu_fecha_modif,cu_fecha_const,cu_porcentaje_valor,cu_periodicidad,
	       cu_depositario,cu_posee_poliza,cu_nro_inspecciones,cu_intervalo,
	       cu_cobranza_judicial,cu_fecha_retiro,cu_fecha_devolucion,cu_fecha_modificacion,
	       cu_usuario_crea,cu_usuario_modifica,cu_estado_poliza,cu_cobrar_comision,
	       cu_cuenta_dpf,cu_codigo_externo,cu_fecha_insp,cu_abierta_cerrada,
	       cu_adecuada_noadec,cu_propietario,cu_plazo_fijo,cu_monto_pfijo,
	       cu_oficina,cu_oficina_contabiliza,cu_compartida,cu_valor_compartida,
	       cu_fecha_reg,cu_fecha_prox_insp,estado
	from cu_custodia_mig
	where estado = null
	open fcursor

	
        fetch fcursor into
	       @w_cu_filial,@w_cu_migrada,@w_cu_sucursal,@w_cu_tipo,@w_cu_custodia,@w_cu_propuesta,
	       @w_cu_estado,@w_cu_fecha_ingreso,@w_cu_valor_inicial,@w_cu_valor_actual,
	       @w_cu_moneda,@w_cu_garante,@w_cu_instruccion,@w_cu_descripcion,@w_cu_poliza,  
	       @w_cu_inspeccionar,@w_cu_motivo_noinsp,@w_cu_suficiencia_legal,@w_cu_fuente_valor,
	       @w_cu_situacion,@w_cu_almacenera,@w_cu_aseguradora,@w_cu_cta_inspeccion,@w_cu_tipo_cta,
	       @w_cu_direccion_prenda,@w_cu_ciudad_prenda,@w_cu_telefono_prenda,@w_cu_mex_prx_inspec,
	       @w_cu_fecha_modif,@w_cu_fecha_const,@w_cu_porcentaje_valor,@w_cu_periodicidad,
	       @w_cu_depositario,@w_cu_posee_poliza,@w_cu_nro_inspecciones,@w_cu_intervalo,
	       @w_cu_cobranza_judicial,@w_cu_fecha_retiro,@w_cu_fecha_devolucion,@w_cu_fecha_modificacion,
	       @w_cu_usuario_crea,@w_cu_usuario_modifica,@w_cu_estado_poliza,@w_cu_cobrar_comision,
	       @w_cu_cuenta_dpf,@w_cu_codigo_externo,@w_cu_fecha_insp,@w_cu_abierta_cerrada,
	       @w_cu_adecuada_noadec,@w_cu_propietario,@w_cu_plazo_fijo,@w_cu_monto_pfijo,
	       @w_cu_oficina,@w_cu_oficina_contabiliza,@w_cu_compartida,@w_cu_valor_compartida,
	       @w_cu_fecha_reg,@w_cu_fecha_prox_insp,@w_estado
 	
	while @@FETCH_STATUS != -1
	begin 


		if not exists (select of_oficina from cobis..cl_oficina where of_oficina=@w_cu_sucursal) 		
		begin
	                 select @w_error = 01
        	  --       select @w_msg = 'LA GARANTIA'+'  '+@w_cu_migrada+'POSEE LA OFICINA'+' '+convert(varchar(4),@w_cu_sucursal)+' '+'QUE NO REGISTRA EN LA BASE DE DATOS'
                	 goto ERROR
		end	
 		
		
		if not exists (select tc_tipo from cu_tipo_custodia where tc_tipo=@w_cu_tipo) 		
		begin
	                 select @w_error = 02
        	  --       select @w_msg = 'LA GARANTIA'+'  '+@w_cu_migrada+' '+'POSEE EL TIPO'+@w_cu_tipo+' '+'QUE NO REGISTRA EN LA BASE DE DATOS'
                	 goto ERROR
		end	
		
	
		select @cliente=cg_ente from cu_cliente_garantia_mig
		where cg_migrada=@w_cu_migrada

		if not exists (select en_ente from cobis..cl_ente where en_ente=@cliente) 		
		begin
	                 select @w_error = 03
        	         select @w_msg = 'LA GARANTIA'+' '+@w_cu_migrada+' '+'NO CONTIENE PROPIETARIO'+' '+@w_cu_propietario+' '+'QUE NO REGISTRA EN LA BASE DE CLIENTES CODIGO#'+' '+convert(varchar(10),@cliente)
                	 goto ERROR
		end	

                select @w_custodia = null
	        select @w_custodia = se_actual+1 
                from cu_seqnos
	        where se_filial =  @w_cu_filial
                and se_sucursal =  @w_cu_sucursal     
                and se_tipo_cust = @w_cu_tipo    

	        if @w_custodia is null
        	begin
            		insert into cu_seqnos 
		        values (@w_cu_filial,@w_cu_sucursal,@w_cu_tipo,1)
	                select @w_custodia = 1
	        end 
                else
	            update cu_seqnos
        	    set se_actual = se_actual + 1
	            where se_filial = @w_cu_filial
       	            and se_sucursal = @w_cu_sucursal
	            and se_tipo_cust = @w_cu_tipo     

        	 exec sp_externo 
                 @i_filial   = 1,
                 @i_sucursal = @w_cu_sucursal,
                 @i_tipo     = @w_cu_tipo,
                 @i_custodia = @w_custodia,
                 @o_compuesto= @w_cu_codigo_externo out



		 select @contador=@contador+1

 	
		insert into cu_custodia 
		(cu_filial,cu_sucursal,cu_tipo,cu_custodia,cu_propuesta,
		cu_estado,cu_fecha_ingreso,cu_valor_inicial,cu_valor_actual,
		cu_moneda,cu_garante,cu_instruccion,cu_descripcion,cu_poliza,
		cu_inspeccionar,cu_motivo_noinsp,cu_suficiencia_legal,cu_fuente_valor,          
		cu_situacion,cu_almacenera,cu_aseguradora,cu_cta_inspeccion,cu_tipo_cta,
		cu_direccion_prenda,cu_ciudad_prenda,cu_telefono_prenda,cu_mex_prx_inspec,
		cu_fecha_modif,cu_fecha_const,cu_porcentaje_valor,cu_periodicidad,
		cu_depositario,cu_posee_poliza,cu_nro_inspecciones,cu_intervalo,
		cu_cobranza_judicial,cu_fecha_retiro,cu_fecha_devolucion,cu_fecha_modificacion,
		cu_usuario_crea,cu_usuario_modifica,cu_estado_poliza,cu_cobrar_comision,cu_cuenta_dpf,
		cu_codigo_externo,cu_fecha_insp,cu_abierta_cerrada,cu_adecuada_noadec,cu_propietario,
		cu_plazo_fijo,cu_monto_pfijo,cu_oficina,cu_oficina_contabiliza,cu_compartida,
		cu_valor_compartida,cu_fecha_reg,cu_fecha_prox_insp)


		values
	       (@w_cu_filial,@w_cu_sucursal,@w_cu_tipo,@w_custodia,@w_cu_propuesta,
	       @w_cu_estado,@w_cu_fecha_ingreso,@w_cu_valor_inicial,@w_cu_valor_actual,
	       @w_cu_moneda,@w_cu_garante,@w_cu_instruccion,@w_cu_descripcion,@w_cu_poliza,  
	       @w_cu_inspeccionar,@w_cu_motivo_noinsp,@w_cu_suficiencia_legal,@w_cu_fuente_valor,
	       @w_cu_situacion,@w_cu_almacenera,@w_cu_aseguradora,@w_cu_cta_inspeccion,@w_cu_tipo_cta,
	       @w_cu_direccion_prenda,@w_cu_ciudad_prenda,@w_cu_telefono_prenda,@w_cu_mex_prx_inspec,
	       @w_cu_fecha_modif,@w_cu_fecha_const,@w_cu_porcentaje_valor,@w_cu_periodicidad,
	       @w_cu_depositario,@w_cu_posee_poliza,@w_cu_nro_inspecciones,@w_cu_intervalo,
	       @w_cu_cobranza_judicial,@w_cu_fecha_retiro,@w_cu_fecha_devolucion,@w_cu_fecha_modificacion,
	       @w_cu_usuario_crea,@w_cu_usuario_modifica,@w_cu_estado_poliza,@w_cu_cobrar_comision,@w_cu_cuenta_dpf,
	       @w_cu_codigo_externo,@w_cu_fecha_insp,'A',
	       @w_cu_adecuada_noadec,@w_cu_propietario,@w_cu_plazo_fijo,@w_cu_monto_pfijo,
	       @w_cu_oficina,@w_cu_oficina_contabiliza,@w_cu_compartida,@w_cu_valor_compartida,
	       @w_cu_fecha_reg,@w_cu_fecha_prox_insp)
	
              if @@error != 0
              begin
                 select @w_error = 10
                 select @w_msg = 'ERROR AL INSERTAR REGISTRO'
                 goto ERROR
              end
              else        
	      begin
                 update cu_custodia_mig
                 set estado = 'S',
	             cu_codigo_externo=@w_cu_codigo_externo

                 where current of fcursor
         	 exec sp_pasa_cliengar_mig @w_cu_migrada,@w_cu_codigo_externo,@w_custodia
	      end
	      goto SIGUIENTE
	
              ERROR:

              insert into cu_errores_mig values (@w_cu_migrada,@w_error,@w_msg)
              update cu_custodia_mig
              set estado = 'E'

              where current of fcursor

		
          SIGUIENTE:

	

	        fetch fcursor into
	       @w_cu_filial,@w_cu_migrada,@w_cu_sucursal,@w_cu_tipo,@w_cu_custodia,@w_cu_propuesta,
	       @w_cu_estado,@w_cu_fecha_ingreso,@w_cu_valor_inicial,@w_cu_valor_actual,
	       @w_cu_moneda,@w_cu_garante,@w_cu_instruccion,@w_cu_descripcion,@w_cu_poliza,  
	       @w_cu_inspeccionar,@w_cu_motivo_noinsp,@w_cu_suficiencia_legal,@w_cu_fuente_valor,
	       @w_cu_situacion,@w_cu_almacenera,@w_cu_aseguradora,@w_cu_cta_inspeccion,@w_cu_tipo_cta,
	       @w_cu_direccion_prenda,@w_cu_ciudad_prenda,@w_cu_telefono_prenda,@w_cu_mex_prx_inspec,
	       @w_cu_fecha_modif,@w_cu_fecha_const,@w_cu_porcentaje_valor,@w_cu_periodicidad,
	       @w_cu_depositario,@w_cu_posee_poliza,@w_cu_nro_inspecciones,@w_cu_intervalo,
	       @w_cu_cobranza_judicial,@w_cu_fecha_retiro,@w_cu_fecha_devolucion,@w_cu_fecha_modificacion,
	       @w_cu_usuario_crea,@w_cu_usuario_modifica,@w_cu_estado_poliza,@w_cu_cobrar_comision,
	       @w_cu_cuenta_dpf,@w_cu_codigo_externo,@w_cu_fecha_insp,@w_cu_abierta_cerrada,
	       @w_cu_adecuada_noadec,@w_cu_propietario,@w_cu_plazo_fijo,@w_cu_monto_pfijo,
	       @w_cu_oficina,@w_cu_oficina_contabiliza,@w_cu_compartida,@w_cu_valor_compartida,
	       @w_cu_fecha_reg,@w_cu_fecha_prox_insp,@w_estado
	
	end
	close fcursor
	deallocate fcursor

return 0
go