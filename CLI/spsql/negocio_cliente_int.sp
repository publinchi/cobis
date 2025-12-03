/************************************************************************/
/*   Archivo:            negocio_cliente_int.sp                         */
/*   Stored procedure:   sp_negocio_cliente_int                         */
/*   Base de datos:      cobis                                          */
/*   Producto:           Clientes                                       */
/*   Disenado por:       ACA                                            */
/*   Fecha de escritura: 31-Agosto-21                                   */
/************************************************************************/
/*                              IMPORTANTE                              */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*  de COBISCorp.                                                       */
/*  Su uso no    autorizado queda  expresamente   prohibido asi como    */
/*  cualquier    alteracion o  agregado  hecho por    alguno  de sus    */
/*  usuarios sin el debido consentimiento por   escrito de COBISCorp.   */
/*  Este programa esta protegido por la ley de   derechos de autor      */
/*  y por las    convenciones  internacionales   de  propiedad inte-    */
/*  lectual.   Su uso no  autorizado dara  derecho a    COBISCorp para  */
/*  obtener ordenes  de secuestro o  retencion y para  perseguir        */
/*  penalmente a los autores de cualquier   infraccion.                 */
/************************************************************************/
/*               PROPOSITO                                              */
/*   Este programa es un sp cascara para manejo de validaciones usadas  */
/*   en el servicio rest del sp_negocio_cliente                         */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*      FECHA           AUTOR           RAZON                           */
/*      31/08/21         ACA       Emision Inicial                      */
/*      21/03/22         PJA       Se agrega control parametro employees*/
/*      01/04/22         PJA       Se agrega operacion D                */
/************************************************************************/

use cob_interface
go

set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO

if exists (select 1 from sysobjects where name = 'sp_negocio_cliente_int')
   drop proc sp_negocio_cliente_int
go

create procedure sp_negocio_cliente_int (
       @s_ssn                              int,
       @s_sesn                             int           = null,
       @s_user                             login         = null,
       @s_term                             varchar(32)   = null,
       @s_date                             datetime,
       @s_srv                              varchar(30)   = null,
       @s_lsrv                             varchar(30)   = null,
       @s_ofi                              smallint      = null,
       @s_rol                              smallint      = null,
       @s_org_err                          char(1)       = null,
       @s_error                            int           = null,
       @s_sev                              tinyint       = null,
       @s_msg                              descripcion   = null,
       @s_org                              char(1)       = null,
       @s_culture                          varchar(10)   = 'NEUTRAL',
       @t_debug                            char(1)       = 'n',
       @t_file                             varchar(10)   = null,
       @t_from                             varchar(32)   = null,
       @t_trn                              int           = null,
       @t_show_version                     bit           = 0,     -- versionamiento
       @i_operacion                        char(1),     
       @i_codigo                           int           = null,
       @i_ente                             int           = null,
       @i_nc_tipo_id                       char(4)       = null,  -- Tipo identificación tributaria
       @i_nc_num_id                        varchar(30)   = null,  -- Número de identificación tributaria
       @i_nombre                           varchar(60)   = null,
       @i_giro                             varchar(10)   = null,
       @i_fecha_apertura                   datetime      = null,
       @i_calle                            varchar(80)   = null,
       @i_nro                              varchar(40)   = null,
       @i_colonia                          varchar(10)   = null,
       @i_localidad                        varchar(20)   = null,
       @i_municipio                        varchar(10)   = null,
       @i_estado                           varchar(10)   = null,
       @i_codpostal                        varchar(30)   = null,
       @i_pais                             varchar(10)   = null,
       @i_telefono                         varchar(20)   = null,
       @i_actividad_ec                     varchar(10)   = null,
       @i_tiempo_activida                  int           = null,
       @i_tiempo_dom_neg                   int           = null,
       @i_emprendedor                      char(1)       = null,
       @i_recurso                          varchar(10)   = null,
       @i_ingreso_mensual                  money         = null,
       @i_tipo_local                       varchar(10)   = null,
       @i_estado_reg                       char(10)      = null,
       @i_destino_credito                  varchar(10)   = null,
       @o_codigo                           int           = null  output,
       @o_telefono_id                      int           = null  output,
       @i_sector                           catalogo      = null,
       @i_subsector                        catalogo      = null,
       @i_misma_dir                        char(1)       = null,
       @i_nro_interno                      varchar(40)   = null,
       @i_referencia_neg                   varchar(225)  = null,
       @i_rfc_neg                          varchar(15)   = null,
       @i_dias_neg                         varchar(20)   = null,
       @i_hora_ini                         varchar(10)   = null,
       @i_hora_fin                         varchar(10)   = null,
       @i_atiende                          varchar(40)   = null,
       @i_empleados                        smallint      = null,
       @i_actividad_neg                    varchar(70)   = null,
       @i_sector_region                    varchar(10)   = null,
       @i_zona                             varchar(10)   = null,
       @i_desasociar_dir                   char(1)       = 'N',
       @i_direccion                        tinyint       = null
)
as
declare @w_sp_name               varchar(30),
        @w_sp_msg                varchar(132),
        @w_mask                  varchar(20),
        @w_oficial               int,
        @w_operacion             char(1),
        @w_error                 int,
        @w_tipo_cliente          char(1),
        @w_valor_campo           varchar(30),
        @w_rows                  smallint
        
        
        
    /* INICIAR VARIABLES DE TRABAJO  */
select
@w_sp_name          = 'cob_interface..sp_negocio_cliente_int',
@w_operacion        = '',
@w_error            = 1720548,--Campos requeridos
@w_tipo_cliente     = null


select @w_tipo_cliente = en_subtipo from cobis..cl_ente where en_ente = @i_ente --Tipo de cliente
if @i_operacion in ('I','U','D')
begin

   /*Campos requeridos*/
   if isnull(@i_ente,'') = '' and @i_ente <> 0
   begin
      select @w_valor_campo = 'personSequential'
      goto VALIDAR_ERROR  
   end

   if not exists (select 1 from cobis..cl_ente where en_ente = @i_ente)
   begin
      select @w_error = 1720411
      goto ERROR_FIN
   end

   if @i_operacion in ('U','D')
   begin
   
      if isnull(@i_codigo,'') = '' and @i_codigo <> 0
	  begin
          select @w_valor_campo = 'code'
          goto VALIDAR_ERROR  
	  end
 
      if not exists (select 1 from cobis..cl_negocio_cliente where nc_ente = @i_ente and nc_codigo = @i_codigo and nc_estado_reg = 'V')
      begin
          select @w_error = 1720285
          goto ERROR_FIN
      end	  
   end
     
   if @i_operacion in ('I','U')
   begin
       if isnull(@i_nombre,'') = ''
       begin
          select @w_valor_campo = 'name'
          goto VALIDAR_ERROR  
       end
       
       if isnull(@i_sector,'') = ''
       begin
          select @w_valor_campo = 'sector'
          goto VALIDAR_ERROR  
       end
       
       if isnull(@i_subsector,'') = ''
       begin
          select @w_valor_campo = 'subsector'
          goto VALIDAR_ERROR  
       end
       
       if isnull(@i_actividad_ec,'') = ''
       begin
          select @w_valor_campo = 'economicActivity'
          goto VALIDAR_ERROR  
       end
       
       if isnull(@i_misma_dir,'') = ''
       begin
          select @w_valor_campo = 'sameDirection'
          goto VALIDAR_ERROR  
       end
       
       if isnull(@i_nc_tipo_id,'') = '' and @w_tipo_cliente != 'P'
       begin
          select @w_valor_campo = 'taxIdentificationType'
          goto VALIDAR_ERROR  
       end
       
       if isnull(@i_nc_num_id,'') = '' and @w_tipo_cliente != 'P'
       begin
          select @w_valor_campo = 'taxIdentificationNumber'
          goto VALIDAR_ERROR  
       end
       
       if isnull(@i_tiempo_activida,'') = ''
       begin
          select @w_valor_campo = 'timeActivity'
          goto VALIDAR_ERROR  
       end
       
       if isnull(@i_tipo_local,'') = ''
       begin
          select @w_valor_campo = 'typePremises'
          goto VALIDAR_ERROR  
       end
       
       if isnull(@i_dias_neg,'') = ''
       begin
          select @w_valor_campo = 'dayOfCare'
          goto VALIDAR_ERROR  
       end
       
       if isnull(@i_hora_ini,'') = ''
       begin
          select @w_valor_campo = 'startTime'
          goto VALIDAR_ERROR  
       end
       
       if isnull(@i_hora_fin,'') = ''
       begin
          select @w_valor_campo = 'endTime'
          goto VALIDAR_ERROR  
       end
       
       if isnull(@i_atiende,'') = ''
       begin
          select @w_valor_campo = 'attends'
          goto VALIDAR_ERROR  
       end
       
       if (isnull(@i_empleados,'') = '' and @i_empleados <> 0)   
       begin
          select @w_valor_campo = 'employees'
          goto VALIDAR_ERROR  
       end
       
       if isnull(@i_tiempo_dom_neg,'') = ''
       begin
          select @w_valor_campo = 'timeRooting'
          goto VALIDAR_ERROR  
       end
       
       if isnull(@i_actividad_neg,'') = ''
       begin
          select @w_valor_campo = 'businessActivity'
          goto VALIDAR_ERROR  
       end
       
       if isnull(@i_direccion,'') = ''
       begin
          select @w_valor_campo = 'address'
          goto VALIDAR_ERROR  
       end


       /*Validaciones */
       /*1. Exista el sector*/
       exec @w_error = cobis..sp_validar_catalogo  
          @i_tabla = 'cl_sector_economico', 
          @i_valor = @i_sector         

       if @w_error <> 0 and @w_error != 1720018 goto ERROR_FIN 
       else if @w_error = 1720018 -- mensaje por defecto que retorna el SP: No existe en catálogo
       begin 
          select @w_valor_campo = @i_sector 
          select @w_error = 1720552 -- mensaje genérico: 
          goto VALIDAR_ERROR 
       end
       /*2. Exista el subsector*/
       if not exists(select 1
          from cobis..cl_subsector_ec a, cobis..cl_sector_economico b
          where a.se_codSector = @i_sector
          and b.se_codigo      = @i_sector
          and a.se_codigo      = @i_subsector)
       begin
           select @w_error  = 1720278 --No existe subsector
           goto ERROR_FIN
       end
    /*3. Exista la actividad*/
       if not exists(select 1
           from cobis..cl_actividad_ec,cobis..cl_subsector_ec
           where ac_codSubsector = @i_subsector
           and se_codigo         = @i_subsector
           and ac_codigo         = @i_actividad_ec)
       begin
          select @w_error = 1720135 --no existe actividad
          goto ERROR_FIN
       end
       /*4. validar tipo de identificación tributaria y 5. la mascára*/
       

       if((@i_nc_tipo_id is not null and @i_nc_tipo_id != '') and 
           (@i_nc_num_id is not null and @i_nc_num_id != ''))
       begin
          if exists (select 1 from cobis..cl_tipo_identificacion where ti_codigo = @i_nc_tipo_id and ti_tipo_cliente = @w_tipo_cliente and ti_tipo_documento = 'T')
          begin
             select @w_mask = (select ti_mascara from cobis..cl_tipo_identificacion where ti_codigo = @i_nc_tipo_id and ti_tipo_cliente = @w_tipo_cliente and ti_tipo_documento = 'T')
          
             /* VALIDAR MASCARA DE DOCUMENTO */ 
          
             if len(@w_mask) <> len(@i_nc_num_id)
             begin
                select @w_error = 1720550
                goto ERROR_FIN 
             end
          end
          else
          begin
             select @w_error = 1720549
             goto ERROR_FIN 
          end
       end
       /*6. Validar tiempo desempeñando actividad*/
       exec @w_error = cobis..sp_validar_catalogo  
            @i_tabla = 'cl_referencia_tiempo', 
            @i_valor = @i_tiempo_activida         
     
       if @w_error <> 0 and @w_error != 1720018 goto ERROR_FIN 
       else if @w_error = 1720018 -- mensaje por defecto que retorna el SP: No existe en catálogo
       begin 
          select @w_valor_campo = @i_tiempo_activida 
          select @w_error = 1720552 -- mensaje genérico: No existe en el catálogo un valor asociado a...
          goto VALIDAR_ERROR 
       end
       
       /*7. Validar el tipo de establecimiento*/
       exec @w_error = cobis..sp_validar_catalogo  
           @i_tabla = 'cr_tipo_local', 
           @i_valor = @i_tipo_local         
           
       if @w_error <> 0 and @w_error != 1720018 goto ERROR_FIN 
       else if @w_error = 1720018 -- mensaje por defecto que retorna el SP: No existe en catálogo
       begin 
          select @w_valor_campo = @i_tipo_local 
          select @w_error = 1720552 -- mensaje genérico: No existe en el catálogo un valor asociado a...
          goto VALIDAR_ERROR 
       end
       
       /*8. Validar hora de inicio*/
       exec @w_error = cobis..sp_validar_catalogo  
            @i_tabla = 'cl_atencion_clientes', 
            @i_valor = @i_hora_ini         
           
       if @w_error <> 0 and @w_error != 1720018 goto ERROR_FIN 
       else if @w_error = 1720018 -- mensaje por defecto que retorna el SP: No existe en catálogo
       begin 
          select @w_valor_campo = @i_hora_ini 
          select @w_error = 1720552 -- mensaje genérico: No existe en el catálogo un valor asociado a...
          goto VALIDAR_ERROR 
       end
       
       /*9. Validar hora de salida*/
       exec @w_error = cobis..sp_validar_catalogo  
           @i_tabla = 'cl_atencion_clientes', 
          @i_valor = @i_hora_fin         
          
       if @w_error <> 0 and @w_error != 1720018 goto ERROR_FIN 
       else if @w_error = 1720018 -- mensaje por defecto que retorna el SP: No existe en catálogo
       begin 
          select @w_valor_campo = @i_hora_fin 
          select @w_error = 1720552 -- mensaje genérico: No existe en el catálogo un valor asociado a...
          goto VALIDAR_ERROR 
       end  
       
       /*10. Validar quien atiende el negocio*/
       exec @w_error = cobis..sp_validar_catalogo  
             @i_tabla = 'cl_atencion_negocio', 
             @i_valor = @i_atiende         
             
       if @w_error <> 0 and @w_error != 1720018 goto ERROR_FIN 
       else if @w_error = 1720018 -- mensaje por defecto que retorna el SP: No existe en catálogo
       begin 
          select @w_valor_campo = @i_atiende 
          select @w_error = 1720552 -- mensaje genérico: No existe en el catálogo un valor asociado a...
          goto VALIDAR_ERROR 
       end
       
       /*11. Validar tiempo de arraigo*/
       exec @w_error = cobis..sp_validar_catalogo  
             @i_tabla = 'cl_referencia_tiempo', 
             @i_valor = @i_tiempo_dom_neg         
             
       if @w_error <> 0 and @w_error != 1720018 goto ERROR_FIN 
       else if @w_error = 1720018 -- mensaje por defecto que retorna el SP: No existe en catálogo
       begin 
          select @w_valor_campo = @i_tiempo_dom_neg 
          select @w_error = 1720552 -- mensaje genérico: No existe en el catálogo un valor asociado a...
          goto VALIDAR_ERROR 
       end
       
       /*12. validar dirección*/
       if(isnull(@i_direccion,'') <> '')
       begin
          if not exists(select 1 from cobis..cl_direccion where di_ente = @i_ente and di_direccion = @i_direccion and di_tipo in ('AE','RE'))
          begin
             select @w_error = 1720115
             goto ERROR_FIN
          end
       end

       /*Validar si es la misma dirección de domicilio*/
       if(@i_misma_dir not in ('S','N'))
       begin
          select @w_valor_campo = @i_misma_dir 
          select @w_error = 1720552 -- mensaje genérico: No existe en el catálogo un valor asociado a...
          goto VALIDAR_ERROR 
       end
       
       set @i_nombre        = upper(@i_nombre)
       set @i_actividad_neg = upper(@i_actividad_neg)
       
       if(@i_fecha_apertura is null)
       begin
          select @i_fecha_apertura = getDate()
       end
   end -- Fin operacion I, U
   
   if(@i_operacion = 'I')
   begin
      select @t_trn = 172060
   end

   if(@i_operacion = 'U')
   begin
      select @t_trn = 172061
   end
   
   if(@i_operacion = 'D')
   begin
      select @t_trn = 172062
   end
   
   select @w_error = 0
   
   exec @w_error = cobis..sp_negocio_cliente
      @s_ssn            =  @s_ssn,           
      @s_sesn           =  @s_sesn,           
      @s_user           =  @s_user,           
      @s_term           =  @s_term,           
      @s_date           =  @s_date,           
      @s_srv            =  @s_srv,            
      @s_lsrv           =  @s_lsrv,           
      @s_ofi            =  @s_ofi,            
      @s_rol            =  @s_rol,            
      @s_org_err        =  @s_org_err,        
      @s_error          =  @s_error,          
      @s_sev            =  @s_sev,            
      @s_msg            =  @s_msg,            
      @s_org            =  @s_org,            
      @s_culture        =  @s_culture,        
      @t_debug          =  @t_debug,          
      @t_file           =  @t_file,           
      @t_from           =  @t_from,           
      @t_trn            =  @t_trn,            
      @t_show_version   =  @t_show_version,   
      @i_operacion      =  @i_operacion,      
      @i_codigo         =  @i_codigo,         
      @i_ente           =  @i_ente,           
      @i_nc_tipo_id     =  @i_nc_tipo_id,     
      @i_nc_num_id      =  @i_nc_num_id,      
      @i_nombre         =  @i_nombre,         
      @i_giro           =  @i_giro,           
      @i_fecha_apertura =  @i_fecha_apertura,
      @i_calle          =  @i_calle,
      @i_nro            =  @i_nro,         
      @i_colonia        =  @i_colonia,
      @i_localidad      =  @i_localidad,
      @i_municipio      =  @i_municipio,    
      @i_estado         =  @i_estado,     
      @i_codpostal      =  @i_codpostal,
      @i_pais           =  @i_pais,    
      @i_telefono       =  @i_telefono,
      @i_actividad_ec   =  @i_actividad_ec,
      @i_tiempo_activida=  @i_tiempo_activida,
      @i_tiempo_dom_neg =  @i_tiempo_dom_neg,
      @i_emprendedor    =  @i_emprendedor,
      @i_recurso        =  @i_recurso,   
      @i_ingreso_mensual=  @i_ingreso_mensual,
      @i_tipo_local     =  @i_tipo_local,
      @i_estado_reg     =  @i_estado_reg,
      @i_destino_credito=  @i_destino_credito,
      @o_codigo         =  @o_codigo out,
      @o_telefono_id    =  @o_telefono_id,
      @i_sector         =  @i_sector,
      @i_subsector      =  @i_subsector,
      @i_misma_dir      =  @i_misma_dir,
      @i_nro_interno    =  @i_nro_interno,
      @i_referencia_neg =  @i_referencia_neg,
      @i_rfc_neg        =  @i_rfc_neg,
      @i_dias_neg       =  @i_dias_neg,
      @i_hora_ini       =  @i_hora_ini,
      @i_hora_fin       =  @i_hora_fin,
      @i_atiende        =  @i_atiende,
      @i_empleados      =  @i_empleados,
      @i_actividad_neg  =  @i_actividad_neg,
      @i_sector_region  =  @i_sector_region,
      @i_zona           =  @i_zona,
      @i_desasociar_dir =  @i_desasociar_dir,
      @i_direccion      =  @i_direccion

   if @w_error <> 0 begin
      return @w_error
   end
   
end-- Fin operacion I, U, D

if (@i_operacion = 'S') 
begin
   
   select @t_trn = 172063

   if isnull(@i_ente,'') = '' and @i_ente <> 0
   begin
      select @w_valor_campo = 'personSequential'
      goto VALIDAR_ERROR   
   end

   if not exists (select 1 from cobis..cl_ente where en_ente = @i_ente)
   begin
      select @w_error = 1720411
      goto ERROR_FIN
   end

   if not exists (select 1 from cobis..cl_negocio_cliente where nc_ente = @i_ente and nc_estado_reg = 'V')
   begin
      select @w_error = 1720289
       goto ERROR_FIN
   end

   exec @w_error = cobis..sp_negocio_cliente
        @t_trn       = @t_trn,
        @i_operacion = 'S',
        @i_ente      = @i_ente,
        @o_codigo    = 1
        
   if @w_error <> 0 begin
      return @w_error
   end

end

return 0

VALIDAR_ERROR:

select @w_sp_msg = cob_interface.dbo.fn_concatena_mensaje(@w_valor_campo, @w_error, @s_culture)
goto ERROR_FIN

ERROR_FIN:

exec cobis..sp_cerror
         @t_debug    = @t_debug,
         @t_file     = @t_file,
         @t_from     = @w_sp_name,
         @i_msg      = @w_sp_msg,
         @i_num      = @w_error
         
return @w_error

go
