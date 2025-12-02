/******************************************************************************/
/*      Archivo:                interfaz_odp.sp                               */
/*      Stored procedure:       sp_interfaz_odp                               */
/*      Base de datos:          cob_cartera                                   */
/*      Producto:               Cartera                                       */
/*      Disenado por:           Juan Carlos Miranda                           */
/*      Fecha de escritura:     Nov. 2021                                     */
/******************************************************************************/
/*                                 IMPORTANTE                                 */
/* Este programa es parte de los paquetes bancarios propiedad de COBISCorp.   */
/* Su uso no autorizado queda expresamente prohibido asi como cualquier       */
/* alteracion o agregado hecho por alguno de usuarios sin el debido           */
/* consentimiento por escrito de la Presidencia Ejecutiva de COBISCorp        */
/* o su representante.                                                        */
/******************************************************************************/
/*                              PROPOSITO                                     */
/* Realizar un programa que permita validar forma de desembolso tipo 'ORPA',  */
/* consultar y reversar las mismas                                            */
/*                                                                            */
/******************************************************************************/
/*                              MODIFICACIONES                                */
/*  FECHA       VERSION        AUTOR                 RAZON                    */
/*  10/11/2021          Juan Carlos Miranda      Version Inicial              */
/*  29/11/2021          Guisela Fernández        Ingreso de validaciones para */
/*                                               errores                      */
/*  02/12/2021          Guisela Fernandez        Actualización de nombre de   */
/*                                               para WS                      */
/* 07/12/2021           J. Hernandez       Ingreso de parametro de nombre     */
/*                                         de catalogo. Se modifica nombre    */
/*                                         Para que sea generico              */
/* 23/06/2022           Kevin Rodríguez    Manejo Atomicidad                  */
/* 25/07/2022           Guisela Fernandez  Ampliación de tamaño de parametro  */
/*                                         de salida de nombre_cliente        */
/******************************************************************************/

use cob_cartera
go
if exists (select * from sysobjects where name = 'sp_interfaz_odp')
        drop proc sp_interfaz_odp
go
create proc sp_interfaz_odp
        @t_show_version         bit         = 0,    -- show the version of the stored procedure     
        @s_user                 login,
        @s_term                 varchar(30) = null,
		@s_date                 datetime    = NULL,
		@s_ssn                  int         = null,
		@s_sesn                 int         = null,		
		@i_llave                varchar(255),         --LLAVE DE SEGURIDAD
        @i_pin_odp              int,                  --NUMERO DE PIN DE ODP
        @i_fecha                varchar(30)   = null, --Fecha del pago
        @i_hora                 varchar(30)   = null, --Hora del pago
        @i_nombre_agente        varchar(30)   = null, --Nombre del agente comercial Iniciales
        @i_cod_sucursal_agente  varchar(30)   = null, --codigo del agente comercial	
        @i_usuario_operador     varchar(30)   = null, --Usuario operador		
        @i_num_trn_bco          varchar(10) ,         --CODIGO TRAN BCO CORRESPONSAL
        @i_ced_ruc              varchar(30),          --IDENTIFICACION DEL CLIENTE        
        @i_fecha_nacimiento     VARCHAR(10) = null,   --FECHA DE NACIMIENTO DEL CLIENTE
        @i_nacionalidad         varchar(64) = null,   --NACIONALIDAD DEL CLIENTE
		@i_monto_pago           money       = null,   --monto de pago
        @i_operacion_bcor       char(1)     = null,   --OPCION DE ACTIVIDAD
		@i_auto_rever           varchar(10) = null,   --Autorizacion a revertir
		@i_nom_catalogo         varchar(400)  ,       -- Nombre del Catalogo
		@o_monto                money       = null   out,   --MONTO DE DESEMBOLSO
		@o_nombre_cliente       varchar(255) = null   out,  --NOMBRE DE CLIENTE
		@o_error                int         = null   out,   --CODIGO DE ERROR DE COBIS
		@o_mensaje              varchar(255) = null  out    --MENSAJE DE ERROR	
as
declare 
	    @w_return            int,
		@w_odp               varchar(10),
		@w_monto             money,
		@w_cob_banco         int, 
		@w_num_cuenta        varchar(25),
		@w_llave             descripcion, 
		@w_error             int,               
		@w_mensaje           varchar(255),
		@w_num_cat           int,
	    @w_opcion            char(1),
	    @w_nombre_cliente    varchar(255),
        @w_pin_odp          int		
	    
	    
	    select @w_error = 0,
               @w_mensaje = '',
			   @w_pin_odp  = convert(int,@i_pin_odp)
	    
        
        
		select  @w_odp = pa_char from cobis..cl_parametro where pa_nemonico = 'ORPA'
		and pa_producto = 'CCA' 
					  
				  
		if not exists (select 1 from cob_credito..cr_deudores, ca_operacion, ca_desembolso, ca_pin_odp, ca_producto
				   where de_tramite = op_tramite and op_operacion = dm_operacion
				   and dm_operacion = po_operacion and dm_secuencial = po_secuencial_desembolso 
				   and dm_producto = cp_producto
				   and po_pin = @w_pin_odp
				   and cp_categoria = @w_odp
				   and de_rol = 'D'
				   and de_ced_ruc = @i_ced_ruc)
				  
		if @@rowcount = 0
		begin
		    select @w_error = 725123
		    select @w_mensaje = 'Operacion no existe con forma de desembolso parametrizada'
			GOTO ERROR
		end
		   
			
		---Se obtienen los datos del catalogo
		SELECT @w_num_cat  = codigo FROM cobis..cl_tabla WHERE tabla = @i_nom_catalogo
				
		SELECT @w_cob_banco = valor FROM cobis..cl_catalogo WHERE tabla = @w_num_cat
		       AND codigo = 'BANCO'
		       
		SELECT @w_num_cuenta = valor FROM cobis..cl_catalogo WHERE tabla = @w_num_cat
		       AND codigo = 'CTA_BANCO'
		       
		SELECT @w_llave = valor FROM cobis..cl_catalogo WHERE tabla = @w_num_cat
		       AND codigo = 'LLAVE'


        --Validacion de llave
		IF @i_llave <> @w_llave
		begin
		    select @w_error = 725117
		    select @w_mensaje = 'Llave enviada no coincide con la parametrizada'
			GOTO ERROR
		end
					
	    IF @i_operacion_bcor IS NOT NULL
	    BEGIN 
	    	IF @i_operacion_bcor IN ('1','2')
	    	BEGIN
		       SELECT @w_opcion = (CASE @i_operacion_bcor
		                    WHEN 1 THEN  'I' else  'R' END)             
			END
			ELSE
			BEGIN
				select @w_error = 725124
				GOTO ERROR
			END 
		END
		ELSE
		BEGIN 
			SELECT @w_opcion = 'Q'
		END
		   
        begin tran		   
		--Ejecucion de sp interno
		exec @w_error = sp_interfaz_odp_finca_int
        @s_user      = @s_user,
        @s_term      = @s_term,
		@s_date      = @s_date,
		@s_ssn       = @s_ssn,
		@s_sesn      = @s_sesn,           		
        @i_banco_cor = @w_cob_banco,           
        @i_cuenta    = @w_num_cuenta, 
        @i_operacion = @w_opcion,
        @i_pin       = @w_pin_odp,
        @i_ced_ruc   = @i_ced_ruc,
        @i_num_trn_bco = @i_num_trn_bco,
		@i_auto_rever  = @i_auto_rever,
		@o_monto     = @w_monto   out,  
		@o_nombre_cliente = @w_nombre_cliente out,           
		@o_error     = @w_error   out,                  
		@o_mensaje   = @w_mensaje out              	
        
		if @w_error <> 0
        begin
            rollback tran		
			GOTO ERROR
        end
		else
		  BEGIN
		    commit tran
		    select @o_error   = @w_error,
                   @o_mensaje = @w_mensaje,
                   @o_monto   = @w_monto,
                   @o_nombre_cliente = @w_nombre_cliente
		  end
		

return 0

ERROR:
select @o_error   = @w_error,
       @o_mensaje = @w_mensaje 
exec cobis..sp_cerror
@t_debug = 'N',
@t_file  = null,
@t_from  = 'sp_interfaz_odp',
@i_num   = @w_error 

return @w_error
go