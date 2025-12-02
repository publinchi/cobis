/*************************************************************************/
/*   Archivo:              pasa_cliengar_mig.sp                          */
/*   Stored procedure:     sp_pasa_cliengar_mig                          */
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
IF OBJECT_ID('dbo.sp_pasa_cliengar_mig') IS NOT NULL
    DROP PROCEDURE dbo.sp_pasa_cliengar_mig
go
create procedure dbo.sp_pasa_cliengar_mig 
@w_cu_migrada1     varchar(64),
@w_codigo_externo  varchar(64),
@w_custodia	   int
as
declare
	@w_cg_filial                      int,
	@w_cg_migrada                     varchar(64),     
	@w_cg_sucursal                    smallint,
	@w_cg_tipo_cust                   descripcion,
	@w_cg_custodia                    int,
	@w_ente                           int,
	@w_cg_principal                   char(1),      
	@w_cg_codigo_externo              varchar(64),     
	@w_cg_oficial                     int,
	@w_cg_nombre                      descripcion,
	@w_estado                         varchar(1),
	@w_error			  int,
	@w_msg			          varchar(65) 

	declare fcursor cursor for
	select cg_filial,cg_migrada,cg_sucursal,cg_tipo_cust,cg_custodia,cg_ente,cg_principal,cg_codigo_externo,cg_oficial,cg_nombre,estado
	from cu_cliente_garantia_mig
	where cg_migrada=@w_cu_migrada1
	and estado = null
        for update of estado



	open fcursor

        fetch fcursor into
	@w_cg_filial,@w_cg_migrada,@w_cg_sucursal,@w_cg_tipo_cust,@w_cg_custodia,@w_ente,@w_cg_principal,      
	@w_cg_codigo_externo,@w_cg_oficial,@w_cg_nombre,@w_estado
 	
	while @@FETCH_STATUS != -1
	begin 

		
		insert into cu_cliente_garantia
		values
		(@w_cg_filial,@w_cg_sucursal,@w_cg_tipo_cust,
		 @w_custodia,@w_ente,@w_cg_principal,      
	 	 @w_codigo_externo,@w_cg_oficial,
		 null, 
		 @w_cg_nombre)   
		--Se agrega null para el campo agregado cg_tipo_garante
		
		if @@error != 0
	        begin
        	       select @w_error = 10
               	       select @w_msg = 'ERROR AL INSERTAR REGISTRO'
               	       goto ERROR
            	end
            	else        
	                update cu_cliente_garantia_mig
        	        set estado = 'S'

             		where current of fcursor
        
	        goto SIGUIENTE
	
                ERROR:
                insert into cu_errores_mig values (@w_cu_migrada1,@w_error,@w_msg)
                update cu_cliente_garantia_mig
                set estado = 'E'

                where current of fcursor

		
          SIGUIENTE:

	


	        fetch fcursor into
		@w_cg_filial,@w_cg_migrada,@w_cg_sucursal,@w_cg_tipo_cust,@w_cg_custodia,@w_ente,@w_cg_principal,      
		@w_cg_codigo_externo,@w_cg_oficial,@w_cg_nombre,@w_estado 	 	
	
	end
	close fcursor
	deallocate fcursor
return 0
go