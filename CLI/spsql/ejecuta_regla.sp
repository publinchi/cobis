/************************************************************************/
/*  Archivo:                ejecuta_regla.sp                            */
/*  Stored procedure:       sp_ejecuta_regla                            */
/*  Base de datos:          cobis                                       */
/*  Producto:               Clientes                                    */
/*  Disenado por:                                                       */
/*  Fecha de escritura:                                                 */
/************************************************************************/
/*                            IMPORTANTE                                */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  "MACOSA", representantes exclusivos para el Ecuador de la           */
/*  "NCR CORPORATION".                                                  */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado hecho por alguno de sus             */
/*  usuarios sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de MACOSA o su representante.                 */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  Ejecuta regla por el acronimo                                       */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*  FECHA                 AUTOR             RAZON                       */
/*  21-Sep-2020           MBA               Emision inicial             */
/************************************************************************/
use cobis
go

set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO

if exists (select * from sysobjects where name = 'sp_ejecuta_regla')
   drop procedure sp_ejecuta_regla
go
create procedure sp_ejecuta_regla (
		@i_param1                              datetime
)                                              
											   
as                                             
											   
declare @w_sp_name                             descripcion,
        @w_rule                                int,
        @w_rule_version                        int,
        @w_process_id                          int,
        @w_var_pro_id                          int,
        @w_variable_id                         int,
        @w_retorno_id                          int,
        @w_retorno_val                         varchar(255),
        @w_abreviature                         varchar(10),
        @w_variables                           varchar(255), 
        @w_result_values                       varchar(255),
        @w_result                              int,
        @w_delimitador                         char(1),
        @w_posicion                            smallint,
        @w_campo                               varchar(100),
        @w_valor                               varchar(100),
		@w_tipo_persona                        char(1),
		@w_primer_nombre                       varchar(64),
		@w_apellido_paterno                    varchar(16),
		@w_genero                              char(1),
		@w_fecha_nac                           datetime,
		@w_pais                                smallint,
		@w_depa_nac                            smallint,
		@w_estado_civil                        catalogo,
		@w_ced_ruc                             numero,
		@w_rfc                                 varchar(30),
		@w_tipo_iden                           varchar(13),
		@w_numero_iden                         varchar(20),
		@w_num_doc_dig                         int,
		@w_doc_dig                             varchar(2),
		@w_actividad                           catalogo,
		@w_ingre                               varchar(10),
		@w_inf_laboral                         varchar(200),
		@w_tipo_operacion                      varchar(10),
		@w_lugar_act                           varchar(100),
		@w_ingreso_legal                       char(2),
		@w_actividad_legal                     char(2),
		@w_otra_cuenta_banc                    char(2),
        @w_rv_id	                           int,
        @w_system                              varchar(15),
        @w_nivel                               varchar(10),
        @w_ente		                           int,
		@w_ente_end	                           int,
		@w_variable                            varchar(1000),
		@w_last_condition_parent               varchar(1000),
		@w_provincia_res                       smallint

/* INICIAR VARIABLES DE TRABAJO  */
select 
@w_sp_name = 'sp_ejecuta_regla'                         

 
-- PASAR LOS DATOS DE CLIENTE
select @w_ente = 0

select @w_ente_end  = max(en_ente)   
  from cobis..cl_ente
	  
while 1 = 1
  begin
      set rowcount 1
	
	  select @w_ente             = en_ente,
	         @w_tipo_persona     = en_subtipo,
	         @w_primer_nombre    = isnull(en_nombre,'NULO'),
	         @w_apellido_paterno = isnull(p_p_apellido,'NULO'), 
	         @w_genero           = isnull(p_sexo,'NULO'),
	         @w_fecha_nac        = isnull(p_fecha_nac,'01/01/1900'),
	         @w_pais             = isnull(en_nacionalidad,0),
	         @w_depa_nac         = isnull(p_depa_nac,0),
	         @w_estado_civil     = isnull(p_estado_civil,'NULO'),
	         @w_ced_ruc          = isnull(en_ced_ruc,'NULO'),
	         @w_rfc              = isnull(en_rfc,'NULO'),
	         @w_tipo_iden        = isnull(en_tipo_iden,'NULO'),
	         @w_numero_iden      = isnull(en_numero_iden,'NULO'),
	         @w_actividad        = isnull(en_actividad,'NULO'),
	         @w_ingre            = isnull(en_ingre,'NULO'),
	         @w_inf_laboral      = isnull(en_inf_laboral,'NULO'),
	         @w_tipo_operacion   = isnull(en_tipo_operacion,'NULO'),
	         @w_lugar_act        = isnull(en_provincia_act,isnull(en_lugar_act,'NULO'))
        from cobis..cl_ente
       where en_ente > @w_ente and en_ente <= @w_ente_end
    order by en_ente
	

    if @@rowcount = 0
      begin
        set rowcount 0
        break
      end
	
      set rowcount 0  

      -----------------------------------------------------------------------------------------------------
      --VARIABLES
      -----------------------------------------------------------------------------------------------------    
      select   @w_ingreso_legal    = isnull(ea_ingreso_legal,'NO'),
               @w_actividad_legal  = isnull(ea_actividad_legal,'NO'),
               @w_otra_cuenta_banc = isnull(ea_otra_cuenta_banc,'NO'),
			   @w_provincia_res    = isnull(ea_provincia_res, 0)			   
        from cl_ente_aux 
       where ea_ente = @w_ente
    	
      --Inserta la variable TIPO PERSONA del proceso de la regla a evaluar         
      select @w_variable = @w_tipo_persona           
                
      --Inserta la variable PRIMER NOMBRE del proceso de la regla a evaluar
      select @w_variable = @w_variable + '|' + @w_primer_nombre	
    
      --Inserta la variable APELLIDO PATERNO del proceso de la regla a evaluar   
      select @w_variable = @w_variable + '|' + @w_apellido_paterno
	  
      --Inserta la variable GENERO del proceso de la regla a evaluar    
	  select @w_variable = @w_variable + '|' + @w_genero           
    
      --Inserta la variable FECHA NACIMIENTO del proceso de la regla a evaluar
      select @w_variable = @w_variable + '|' + convert(varchar(10),@w_fecha_nac,103)
        
      --Inserta la variable NACIONALIDAD del proceso de la regla a evaluar    
	  select @w_variable = @w_variable + '|' +  convert(varchar,@w_pais)
        
      --Inserta la variable ENTIDAD DE NACIMIENTO del proceso de la regla a evaluar    
	  select @w_variable = @w_variable + '|' +  convert(varchar,@w_depa_nac)
            
      --Inserta la variable ESTADO CIVIL del proceso de la regla a evaluar    
	  select @w_variable = @w_variable + '|' +  @w_estado_civil
        
      --Inserta la variable CURP del proceso de la regla a evaluar
      select @w_variable = @w_variable + '|' +  @w_ced_ruc
        
      --Inserta la variable RFC del proceso de la regla a evaluar
      select @w_variable = @w_variable + '|' +  @w_rfc        
    
      --Inserta la variable TIPO DE IDENTIFICACION del proceso de la regla a evaluar
      select @w_variable = @w_variable + '|' +  @w_tipo_iden
            
      --Inserta la variable IDENTIFICACION del proceso de la regla a evaluar
      select @w_variable = @w_variable + '|' +  @w_numero_iden
        
      --Inserta la variable DOCUMENTO DE IDENTIFICACION del proceso de la regla a evaluar     
      select @w_num_doc_dig = count(*)
        from cl_documento_digitalizado 
       where dd_cliente = @w_ente 
         and dd_producto = 'CLIENTE' 
         and (dd_codigo = '001' or dd_codigo = '002')
       
      if (@w_num_doc_dig = 2)
        begin
          select @w_doc_dig = 'SI'
        end 
        else
          select @w_doc_dig = 'NO'
       	  
          select @w_variable = @w_variable + '|' +  @w_doc_dig
            
      --Inserta la variable ACTIVIDAD ECONOMICA del proceso de la regla a evaluar
      select @w_variable = @w_variable + '|' +  @w_actividad        
    
      --Inserta la variable INGRESOS MENSUALES del proceso de la regla a evaluar
      select @w_variable = @w_variable + '|' +  @w_ingre
   
      --Inserta la variable NEGOCIO O INSTITUCION DONDE LABORA del proceso de la regla a evaluar
      select @w_variable = @w_variable + '|' +  @w_inf_laboral
    
      --Inserta la variable OPERACION del proceso de la regla a evaluar
      select @w_variable = @w_variable + '|' +  @w_tipo_operacion
    
      --Inserta la variable LUGAR PRINCIPAL DE ACTIVIDAD del proceso de la regla a evaluar
      select @w_variable = @w_variable + '|' +  @w_lugar_act       		

      --Inserta la variable INGRESOS FUENTE LEGAL del proceso de la regla a evaluar         
      if (@w_ingreso_legal = 'N' or (isnull(@w_ingreso_legal,'') = ''))
         select @w_ingreso_legal = 'NO'
      else
         if (@w_ingreso_legal = 'S')
         select @w_ingreso_legal = 'SI'
     
         select @w_variable = @w_variable + '|' +  @w_ingreso_legal


      --Inserta la variable LIBRE DE CONEXION CON REDES del proceso de la regla a evaluar    
      if (@w_actividad_legal = 'N' or (isnull(@w_actividad_legal,'') = ''))
         select @w_actividad_legal = 'NO'
      else
         if (@w_actividad_legal = 'S')
         select @w_actividad_legal = 'SI'
       
         select @w_variable = @w_variable + '|' +  @w_actividad_legal

            
      --Inserta la variable OTRA CUENTA SISTEMA MEXICANO del proceso de la regla a evaluar    
      if (@w_otra_cuenta_banc = 'N' or (isnull(@w_otra_cuenta_banc,'')=''))
         select @w_otra_cuenta_banc = 'NO'
      else
         if (@w_otra_cuenta_banc = 'S')
         select @w_otra_cuenta_banc = 'SI'
     
         select @w_variable = @w_variable + '|' +  @w_otra_cuenta_banc      

      --Inserta la variable ENTIDAD FEDERATIVA PRINCIPAL DE ACTIVIDAD del proceso de la regla a evaluar    
	  select @w_variable = @w_variable + '|' +  convert(varchar,@w_provincia_res)	

      select @w_variables = null, 
	         @w_result_values = null,
			 @w_last_condition_parent = null
        
     --Ejecuta la regla 		
	 exec @w_result = cob_pac..sp_rules_param_run
     @i_rule_mnemonic         = 'NV',
     @i_var_values            = @w_variable,
     @i_var_separator         = '|',
     @o_return_variable       = @w_variables  out,
     @o_return_results        = @w_result_values   out,
     @o_last_condition_parent = @w_last_condition_parent out
 
          
     --Resultados 
     select @w_delimitador = '|'
     if @w_result_values is not null
       begin                             
         select @w_result_values = ltrim(rtrim(@w_result_values))
         select @w_posicion   = charindex(@w_delimitador, @w_result_values, 1)
         if @w_posicion > 0
           begin
             select @w_nivel = substring(@w_result_values, 1, @w_posicion-1)         
           end
		   
           update cl_ente 
           set en_nivel = @w_nivel
           where en_ente = @w_ente
		   
         end
         else
         begin
    	    delete from cl_error_log where er_fecha_proc is not null
            insert into cl_error_log (
                    er_fecha_proc,   er_error,   er_usuario,                er_tran,  er_cuenta,  er_descripcion)
            values(      
                    @i_param1,       1720371,   convert(varchar,@w_ente),  null,     null,       'ERROR EN LA GENERACION DE LA REGLA')
       end	    

end                          

return 0
go

