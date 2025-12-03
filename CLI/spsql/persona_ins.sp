/********************************************************************/
/*    NOMBRE LOGICO: sp_persona_ins                                 */
/*    NOMBRE FISICO: persona_ins.sp                                 */
/*    PRODUCTO:      Clientes                                       */
/*    Disenado por:  JMEG                                           */
/*    Fecha de escritura: Jun 2020                                  */
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
/*   sitio, queda expresamente prohibido sin el debido              */
/*   consentimiento por escrito, de parte de los representantes de  */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  */
/*   en el presente texto, causará violaciones relacionadas con la  */
/*   propiedad intelectual y la confidencialidad de la información  */
/*   tratada y por lo tanto, derivará en acciones legales civiles   */
/*   y penales en contra del infractor según corresponda.           */
/********************************************************************/
/*                           PROPOSITO                              */
/*  Crear persona natural (prospecto)                               */
/********************************************************************/
/*                        MODIFICACIONES                            */
/*  FECHA              AUTOR              RAZON                     */
/* 30/04/19      JMEG       Emision Inicial                         */
/* 22/05/20      MBA        Cambio nombre y compilacion BDD cobis   */
/* 09/06/20      MBA        Estandarizacion sp y seguridades        */
/* 06/07/20      FSAP       Renombre sp_persona_no_ruc a persona_ins*/
/* 07/07/20      AMGE       Renombre sp_crear_p_natural-persona_ins */
/* 21/08/20      AHU        Agregando variable @i_entidad_act       */
/* 24/08/20      AHU        Agregando variable @i_other_project     */
/* 26/08/20      AHU        Asignar valor por defecto a en_nivel    */
/* 28/08/20      AHU        Validación de Numero de Identificacion  */
/* 15/10/20      MBA        Uso de la variable @s_culture           */
/* 24/11/20      EGL        Agregando variable @i_genero            */
/* 11/12/20      EGL        Se agrega Validación PEP                */
/* 12/01/21      IYU        Actualizacion Tipos Identificacion      */
/* 05/03/21      JOR        Cambio Pais por defecto                 */
/* 11/03/21      JOR        Correciones documento para GFI          */
/* 17/01/23      BDU        S762873: Se agregan nuevos campos       */
/* 11-Ene-2023   P. Jarrin. S779052 - Se agregan nuevos parametros. */
/* 09-Mar-2023   E. Gaviria.S763654 - Creación de prospectos desde  */ 
/*                                    la APP                        */
/* 23/03/22     BDU         S801301 Se quita campo obligatorio      */
/* 28/03/23     BDU         Agregar pseudonimo                      */
/* 25/04/2023   PJA         Validar dígito verificador DUI-S784528  */
/* 30/06/2023   EBA         S849151 se realiza la conversión de los */
/*                          tipos de documento principal y          */
/*                          tributario que vienen desde la app en   */
/*                          base a la máscara parametrizada.        */
/* 28/Junio/23  BDU         S849165 Se quita 'DE' del apellido      */
/* 09/09/23     BDU        R214440-Sincronizacion automatica        */
/* 05/10/23     BDU        R214440-Ajuste campo lugar doc           */
/* 20/10/23     BDU        R217831-Ajuste validacion error          */
/* 22/12/23     BDU        R221783-Validar provincia 0              */
/* 22/01/24     BDU        R224055-Validar oficina app              */
/* 06/03/24     BDU        R228486: Se corrige validación DUI       */
/* 12/12/2024   GRO        R248888:campos conozca su cliente        */ 
/********************************************************************/
use cobis
go

set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO

if exists ( select 1 from sysobjects where name ='sp_persona_ins') 
    drop procedure sp_persona_ins
go

create procedure sp_persona_ins(
       @s_ssn                                  int           = null,
       @s_user                                 login         = null,
       @s_term                                 varchar (32)  = null,
       @s_ofi                                  int           = null,
       @s_date                                 datetime      = null,
       @s_srv                                  varchar(30)   = null,
       @s_lsrv                                 varchar(30)   = null,
       @s_culture                              varchar(10)   = 'NEUTRAL',
       @t_trn                                  int           = null,
       @t_show_version                         bit           = 0,     -- mostrar la version del programa
       @i_nombre                               descripcion   = null,  -- primer nombre del cliente
       @i_p_apellido                           descripcion   = null,  -- primer apellido del cliente
       @i_s_apellido                           descripcion   = null,  -- segundo apellido del cliente
       @i_filial                               tinyint       = null,  -- codigo de la filial
       @i_oficina                              smallint      = null,  -- codigo de la oficina
       @i_tipo_ced                             char(4)       = null,  -- tipo del documento de identificacion / tipo identificacion personal
       @i_tipo_tributario                      char(4)       = null,  -- tipo identificacion tributario
       @i_cedula                               varchar(30)   = null,  -- numero del documento de identificacion // corrige el error del instalador de la cob_pac
       @i_oficial                              smallint      = 0,     -- codigo del oficial asignado al cliente
       @i_c_apellido                           varchar(30)   = null,  -- apellido casada
       @i_segnombre                            varchar(50)   = null,  -- segundo nombre
       @i_nit                                  varchar(30)   = null,  -- numero de identificacion tributaria del cliente
       @i_depart_doc                           smallint      = null,  -- codigo del departamento del documento
       @i_numord                               char(4)       = null,  -- codigo de orden cv
       @i_ciudad_nac                           int           = null,  -- codigo del municipio de nacimiento
       @i_provincia_nac                        int           = null,
       @i_pais_nac                             varchar(10)   = null,
       @i_lugar_doc                            int           = null,  -- codigo del lugar del documento (pais o municipio)
       @i_fecha_emision                        datetime      = null,  -- fecha de emision del pasaporte
       @i_fecha_expira                         datetime      = null,  -- fecha de vencimiento del pasaporte
       @i_fecha_nac                            datetime      = null,  -- fecha de nacimiento jli
       @i_cod_otro_pais                        char (5)      = null,  -- codigo de otro pais centroamericano cvi
       @i_pasaporte                            varchar(20)   = null,  -- numero de pasaporte del ente utilizado con cr , jli
       @i_sexo                                 varchar(10)   = null,  -- codigo del sexo de la persona enviado dalvarez gap mi00028
       @i_genero                               varchar(10)   = null,  -- codigo del genero de la persona enviado 
       @i_ingre                                varchar(10)   = null,  -- codigo de ingreso de la persona dalvarez gap mi00028
       @i_digito                               char(2)       = null,  -- contiene el digito verificador
       @i_bloquear                             char(1)       = null,
       @i_tipo                                 catalogo      = null,
       @i_tipo_vinculacion                     catalogo      = null,  -- codigo del tipo de vinculacion de quien presento al cliente
       @i_tipo_vivienda                        catalogo      = null,
       @i_situacion_cliente                    catalogo      = null,  -- situacion actual del cliente
       @i_retencion                            char(1)       = 'N',   -- Indicador si el ente es sujeto a impuestos
       @i_estado_civil                         varchar(10)   = null,  
       @i_sector                               catalogo      = null,  -- no se utiliza
       @i_actividad                            catalogo      = null,  -- codigo de la actividad del ente
       @i_categoria                            catalogo      = null,  -- cva abr-24-07
       @i_estado                               catalogo      = null,
       @i_cliente_casual                       char(1)       = null,  -- gc cliente casual
       @i_suc_gestion                          smallint      = null,
       @i_menor                                char(1)       = null,
       @i_nacionalidad                         int           = null,
       @i_ejecutivo_con                        int           = null,
       @i_calificacion                         catalogo      = null,
       @i_calif_cliente                        catalogo      = null,
       @i_comentario                           varchar(254)  = null,
       @i_ea_observacion_aut                   varchar(254)  = null,
       @i_ea_contrato_firmado                  char(1)       = null,
       @i_ea_menor_edad                        char(1)       = null,
       @i_ea_conocido_como                     varchar(254)  = null,
       @i_ea_cliente_planilla                  char(1)       = null,
       @i_ea_cod_risk                          varchar(20)   = null,
       @i_ea_sector_eco                        catalogo      = null,
       @i_ea_actividad                         catalogo      = null,
       @i_ea_lin_neg                           catalogo      = null,
       @i_ea_seg_neg                           catalogo      = null,
       @i_ea_val_id_check                      catalogo      = null,
       @i_ea_constitucion                      smallint      = null,
       @i_ea_remp_legal                        int           = null,
       @i_ea_apoderado_legal                   int           = null,
       @i_ea_fuente_ing                        catalogo      = null,
       @i_ea_act_prin                          catalogo      = null,
       @i_ea_detalle                           varchar(255)  = null,
       @i_ea_act_dol                           money         = null,
       @i_ea_cat_aml                           catalogo      = null,
       @i_profesion                            catalogo      = null,
       @i_ced_ruc                              varchar(30)   = null,       --cliente ocacional
       @i_ea_discapacidad                      char(1)       = null,    --PRESENCIA DE DISCAPACIDAD
       @i_ea_tipo_discapacidad                 catalogo      = null,    --TIPO DE DISCAPACIDAD
       @i_ea_ced_discapacidad                  varchar(30)   = null,    --CEDULA DE DISCAPACIDAD
       @i_secuencial                           int           = null,   
       @i_egresos                              catalogo      = null,    
       @i_vinculacion                          char(1)       = 'N',        
       @i_emproblemado                         char(1)       = null,       -- manejo de emproblemados
       @i_dinero_transac                       money         = null,       -- mnt de dinero transacciona mensualmente
       @i_manejo_doc                           varchar(25)   = null,       -- manejo de documentos
       @i_pep                                  char(1)       = null,       -- s/n persona expuesta politicamente
       @i_mnt_activo                           money         = null,       -- monto de los activos del cliente
       @i_mnt_pasivo                           money         = null,       -- monto de los pasivos del cliente                           
       @i_ant_nego                             int           = null,       -- antiguedad del negicio (meses)
       @i_ventas                               money         = null,       -- ventas
       @i_ot_ingresos                          money         = null,       -- otros ingresos
       @i_ct_ventas                            money         = null,       -- costos ventas
       @i_ct_operativos                        money         = null,       -- costos operativos
       @i_ea_nro_ciclo_oi                      int           = null,       -- lpo santander --numero de ciclos en otras entidades
       @i_batch                                char(1)       = 'N'      ,
       @i_banco                                varchar(20)   = null,
       @i_naturalizado                         char(1)       = null,
       @i_forma_migratoria                     varchar(64)   = null,
       @i_nro_extranjero                       varchar(64)   = null,
       @i_calle_orig                           varchar(70)   = null,
       @i_exterior_orig                        varchar(40)   = null,
       @i_estado_orig                          varchar(40)   = null,
       @i_localidad                            varchar(20)   = null,                        
       @i_escolaridad                          catalogo      = null,
       @i_nivel_estudio                        catalogo      = null,
       @i_tipo_iden                            varchar(13)   = null,
       @i_numero_iden                          varchar(20)   = null,
       @i_num_cargas                           int           = null,
       @i_nro_ciclo                            int           = null,             
       @i_sic_asincronico                      char(1)       = 'S',
       @i_ingresoMensual                       money         = null,
       @i_actividad_desc                       varchar(50)   = null,
       @i_ocupacion                            catalogo      = null,
       @i_carg_pub                             varchar(200)  = null,
       @i_rel_carg_pub                         varchar(10)   = null,
       @i_ingreso_legal                        char(1)       = null,
       @i_actividad_legal                      char(1)       = null,
       @i_fatca                                char(1)       = null,
       @i_crs                                  char(1)       = null,
       @i_entidad_act                          catalogo      = null,
       @i_other_project                        char(1)       = 'S',
       @i_tipo_residencia                      char(2)       = null,
       @i_migrado                              varchar(30)   = null,
       @i_sp_crea                              char(1)       = 'N',
       @i_ciudad_emi                           int           = null,
       @i_ea_telef_recados                     varchar(20)   = null,
       @i_antecedentes_buro                    varchar(2)    = null,       
       @i_persona_recados                      varchar(60)   = null,
       @i_is_app                               char(1)       = 'N',
       @i_pseudonimo                           descripcion   = null, -- Pseudonimo del cliente       
       @i_lug_trab                             varchar(200)  = null, 
	   @o_ente                                 int           = null  out,  -- codigo secuencial asignado al cliente
       @o_es_pais_resitringido                 char(1)       = 'N'   out,
       @o_curp                                 varchar(32)   = null  out,
       @o_rfc                                  varchar(32)   = null  out
)

as

declare @w_sp_name                             descripcion,
        @w_sp_msg                              varchar(132),
        @w_return                              int,
        @w_nombre_completo                     varchar (254),
        @w_sexo                                char(10),
        @w_estado_civil                        varchar(10),
        @w_ptipo                               char(10),
        @w_actividad                           char(10),
        @w_sectoreco                           char(10),
        @w_tipo_vivienda                       char(10),
        @w_bloquear                            char(1),
        @w_mala_referencia                     char(1),
        @w_nemocda                             char(3),
        @w_nemomed                             char(3),
        @w_vu_banco                            catalogo,
        @w_vu_pais                             catalogo,
        @w_estado                              char(1),
        @w_estado_referencia                   catalogo,
        @w_estado_ref_pais                     catalogo,
        @w_ea_ced_ruc                          varchar(30),
        @w_catalogo                            catalogo,
        @w_nat_jur_hogar                       catalogo,
        @w_msg                                 varchar(100),
        @w_curp                                varchar(30), 
        @w_rfc                                 varchar(30), 
        @w_ofi_mobil                           int,         
        @w_edad_max                            smallint,    
        @w_edad_min                            smallint,    
        @w_anios_edad                          smallint,
        @w_error                               int,
        @w_pais_local                          int,
        @w_mexico                              int, 
        @w_trn_pep                             int,
        @w_es_pep                              varchar(10),
        @w_dependencia                         varchar(200),
        @w_puesto                              varchar(200),
        @w_nacionalidad                        varchar(10),
        @w_longitud                            int,
        @w_valida_long                         int,
        @w_respuesta                           int,
        @w_pseudonimo_par                      tinyint,
        @w_mascara                             varchar(30),
        @w_doc_prin_mascara                    varchar(30),
        @w_doc_trib_mascara                    varchar(30),
        -- R214440-Sincronizacion automatica
        @w_sincroniza      char(1),
        @w_ofi_app         smallint



/* INICIAR VARIABLES DE TRABAJO  */
select 
@w_sp_name           = 'sp_persona_ins',
@w_sp_msg            = '',
@w_estado_referencia = @i_estado,
@w_mala_referencia   = 'N',
@w_trn_pep           = 172055 -- TRN para ejecutar cobis..sp_validacion_pep EGL


            
/* VERSIONAMIENTO */
if @t_show_version = 1 begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end


---- EJECUTAR SP DE LA CULTURA ---------------------------------------  
exec cobis..sp_ad_establece_cultura
        @o_culture = @s_culture out
        
        

-- PARA TEMAS QUE SOLO APLICAN PARA MX
select @w_mexico =  codigo 
from  cobis..cl_catalogo
where tabla = (select top 1 codigo from cobis..cl_tabla where tabla = 'cl_pais'  ) 
and   valor like '%MEXICO%'

/* LECTURA DE PARAMETROS GENERALES */
select @w_edad_min        = pa_tinyint  from cobis..cl_parametro where pa_nemonico = 'MDE'   and pa_producto = 'ADM'  -- EDAD MINIMA PARA SER REGISTRADO
select @w_edad_max        = pa_tinyint  from cobis..cl_parametro where pa_nemonico = 'EMAX'  and pa_producto = 'ADM'  -- EDAD MAXIMA PARA SER REGISTRADO
select @w_nemocda         = pa_char     from cobis..cl_parametro where pa_nemonico = 'CDA'   and pa_producto = 'CLI'  -- CASADO
select @w_nemomed         = pa_char     from cobis..cl_parametro where pa_nemonico = 'MED'   and pa_producto = 'CLI'  -- MENOR DE EDAD
select @w_estado_ref_pais = pa_char     from cobis..cl_parametro where pa_nemonico = 'EVPR'  and pa_producto = 'CLI'  -- ESTADO VALIDACION PAISES REESTRINGIDOS
select @w_ofi_mobil       = pa_int      from cobis..cl_parametro where pa_nemonico = 'MOBOFF'and pa_producto = 'ADM'  -- OFICINA BANCA MOVIL EMPLEADOS
select @w_pais_local      = pa_smallint from cobis..cl_parametro where pa_nemonico = 'CP'    and pa_producto = 'CLI'  -- PAIS DONDE ESTÁ EL BANCO


--en sql cts convierte en null las cadenas vacías, por esta razón se envía un * que se debe reemplazar por cadena vacía
if @i_s_apellido = '*' select @i_s_apellido = ''
if @i_segnombre  = '*' select @i_segnombre  = ''

--se pone los numeros de identificacion en uppercase
select @i_cedula      = upper(@i_cedula)
select @i_nit         = upper(@i_nit)
select @i_numero_iden = upper(@i_numero_iden)

-- Tipos de identificacion de personas nacionales
if @i_tipo_ced in ('CI','CID','CIEE','CPN','ND','RUN') begin
   select @w_nat_jur_hogar = pa_char
   from cobis..cl_parametro
   where pa_nemonico ='NAJUHO'
   and   pa_producto ='CLI'
end
-- Tipos de identificacion de personas extranjeras
if @i_tipo_ced in ('CIE','DCC','DCD','DCO','DCR','PAS','DE') begin
   select @w_nat_jur_hogar =pa_char
   from cobis..cl_parametro
   where pa_nemonico ='NAJUHE'
   and   pa_producto ='CLI'
end


/* SI NO ESTA DADO, SE ASUME QUE LA PERSONA ES SOLTERA */
/*if isnull(@i_estado_civil,'') not in ('CA','UN') select @i_estado_civil = 'SO'*/

   
/* NOMBRE COMPLETO DE LA PERSONA NATURAL */
select @w_nombre_completo = concat(@i_nombre, ' ', @i_segnombre, ' ', @i_p_apellido, ' ', @i_s_apellido)

if @i_sexo = 'F' and @i_estado_civil = @w_nemocda and @i_c_apellido is not null  -- mujer casada que usa apellido del esposo
   select @w_nombre_completo = concat(@w_nombre_completo, ' ', @i_c_apellido)

if @i_estado_civil = @w_nemomed
   select @w_nombre_completo = concat(@w_nombre_completo, ' (MENOR)')
   
   
   
/* MANEJO DEL PAIS DE NACIMIENTO Y LA NACIONALIDAD*/
select @i_pais_nac     = isnull(@i_pais_nac,     @w_pais_local)
select @i_nacionalidad = isnull(@i_nacionalidad, @i_pais_nac  )

if @i_nacionalidad <> @w_pais_local
begin
   select @w_nacionalidad = 'E'
end
else
begin
   select @w_nacionalidad = 'N'
end
-- VALIDACIONES DE CATALOGOS 
if @i_is_app = 'N' 
begin          
   exec @w_error = sp_validar_catalogo  @i_tabla = 'cl_relacion_banco',   @i_valor = @i_tipo_vinculacion if @w_error <> 0 goto ERROR_FIN
   exec @w_error = sp_validar_catalogo  @i_tabla = 'cl_profesion',        @i_valor = @i_profesion        if @w_error <> 0 goto ERROR_FIN
   exec @w_error = sp_validar_catalogo  @i_tabla = 'cl_sector_economico', @i_valor = @i_sector           if @w_error <> 0 goto ERROR_FIN
   exec @w_error = sp_validar_catalogo  @i_tabla = 'cl_actividad_ec',     @i_valor = @i_actividad        if @w_error <> 0 goto ERROR_FIN
   exec @w_error = sp_validar_catalogo  @i_tabla = 'cl_pais',             @i_valor = @i_pais_nac         if @w_error <> 0 goto ERROR_FIN
   exec @w_error = sp_validar_catalogo  @i_tabla = 'cl_pais',             @i_valor = @i_nacionalidad     if @w_error <> 0 goto ERROR_FIN
   exec @w_error = sp_validar_catalogo  @i_tabla = 'cl_ingresos',         @i_valor = @i_ingre            if @w_error <> 0 goto ERROR_FIN
   exec @w_error = sp_validar_catalogo  @i_tabla = 'cl_provincia',        @i_valor = @i_entidad_act      if @w_error <> 0 goto ERROR_FIN


   /*Validacion celular recados*/
   if(@i_ea_telef_recados != null and @i_ea_telef_recados != '')
   begin
      select @w_longitud = LEN(@i_ea_telef_recados) --longitud de valor de telefono
      select @w_valida_long = pa_smallint from cl_parametro where pa_nemonico = 'DCEL' and pa_producto = 'CLI'
      if @w_longitud <> @w_valida_long
      begin
         select @w_error = 1720539 -- 'El Celular no es valido'
         goto ERROR_FIN 
      end
   /*Validar dígitos consecutivos*/
      select @w_respuesta = cobis.dbo.fn_valida_telefono(@i_ea_telef_recados)
      if @w_respuesta <> 0
      begin
      select @w_error = 1720536 -- 'El teléfono no es valido'
         goto ERROR_FIN 
      end
   end

   /*VALIDACIONES CAMPOS OBLIGATORIOS*/
   if @i_estado_civil <> 'C' and @i_estado_civil <> 'A' and (@i_ciudad_emi is null or @i_fecha_emision is null or @i_fecha_expira is null)
   begin
      print 'DATOS: {CIU: '+ CONVERT(VARCHAR, @i_ciudad_emi) + ' CON: ' + CONVERT(VARCHAR, @i_ea_conocido_como) + 'FEC EMI: ' + CONVERT(VARCHAR, @i_fecha_emision) + '' +'}'
      select @w_error = 1720294
      goto ERROR_FIN
   end
   --Validar cudad emision
   exec @w_error = sp_validar_catalogo  @i_tabla = 'cl_ciudad',           @i_valor = @i_ciudad_emi       if @w_error <> 0 goto ERROR_FIN

   -- Validacion de Paises Restringidos  (PRMR CLI-0571)
   if exists(select 1 from cobis..cl_catalogo a, cobis..cl_tabla b
   where b.tabla  = 'cl_paises_restringidos'
   and   a.tabla  = b.codigo
   and   a.estado = 'V'
   and   a.codigo = convert(varchar(10),@i_nacionalidad))
   begin
   
      select  
      @w_estado_referencia    = @w_estado_ref_pais,  -- El estado de cliente sera de M - Mala Referencia
      @o_es_pais_resitringido = 'S'
   
      if not exists(select 1 from cobis..cl_catalogo a, cobis..cl_tabla b
      where    b.tabla = 'cl_estados_ente'
      and   a.tabla  = b.codigo
      and   a.estado = 'V'
      and   a.codigo = @w_estado_ref_pais)
      begin
         select @w_error = 1720039
         goto ERROR_FIN
      end
      
   end
end

-- SI ESTA INDICADO, VALIDAR QUE EL OFICIAL EXISTA
if isnull(@i_oficial,0) <> 0 begin
   if not exists (select 1 from cobis..cc_oficial where oc_oficial = @i_oficial) begin
      select @w_error = 1720040
      goto ERROR_FIN
   end
end


-- SI EXISTEN REFERENCIAS INHIBITORIAS, RECHAZAR A LA PERSONA   
if exists(select 1 from  cobis..cl_refinh where in_ced_ruc = @i_cedula) begin
   select @w_error = 1720038
   goto ERROR_FIN
end

-- SI SOLO EXISTEN MALAS REFERENCIAS, SOLO MARCAR LA NOVEDAD
if exists(select 1 from  cobis..cl_mercado where me_ced_ruc like @i_cedula) select @w_mala_referencia = 'S'


-- Validacion de Edad
if @i_cliente_casual <> 'S' begin

   select @w_anios_edad = datediff(mm, @i_fecha_nac, fp_fecha) / 12
  from cobis..ba_fecha_proceso
  
   if @w_anios_edad < @w_edad_min or @w_anios_edad > @w_edad_max
   begin
      select @w_error = 1720044
      goto ERROR_FIN
   end
   
end

--si es null se setea el tipo de persona
if @i_tipo is null begin
   select @i_tipo = pa_char 
  from cobis..cl_parametro
   where pa_producto ='CLI'
   and   pa_nemonico ='VGTPNA'
end


/* insertar los parametros de entrada */
select @w_estado_civil = ltrim(rtrim(@i_estado_civil))

if ltrim(rtrim(@i_nombre))='MA.' begin

   if ltrim(rtrim(@i_segnombre))='' or ltrim(rtrim(@i_segnombre))=' ' or @i_segnombre is null 
   begin
      select @w_error = 1720045
      goto ERROR_FIN
   end
   
end


-- VALIDACIONES QUE SOLO APLICAN PARA MX
if @w_pais_local = @w_mexico begin

   if @i_pais_nac = @w_mexico begin
   
      if @i_provincia_nac is null  begin
         select @w_error = 1720002
         goto ERROR_FIN
      end

      if @i_other_project = 'N' begin
         if @i_tipo_iden     is null   
         or @i_numero_iden   is null begin
            select @w_error = 1720004
            goto ERROR_FIN
         end
      end

      select 
      @i_naturalizado     = null,
      @i_forma_migratoria = null,
      @i_nro_extranjero   = null,
      @i_calle_orig       = null,
      @i_exterior_orig    = null,
      @i_estado_orig      = null
     
   end else begin  -- la persona no nacio en Mx
   
      if @i_naturalizado = 'N'begin
         
         if @i_forma_migratoria  is null 
         or @i_nro_extranjero    is null 
         or @i_tipo_iden         is null 
         or @i_numero_iden       is null begin
            select @w_error = 1720005
            goto ERROR_FIN
         end
                     
         select @i_localidad = null --si está naturalizada no puede estar localizada

      end 
   
   end
   
  
   

   select @w_msg = @i_nombre + ' ' + isnull(@i_segnombre,'')
    
  
   exec @w_error = cobis..sp_generar_curp
   @i_primer_apellido       = @i_p_apellido,
   @i_segundo_apellido      = @i_s_apellido,
   @i_nombres               = @w_msg,
   @i_sexo                  = @i_sexo,
   @i_fecha_nacimiento      = @i_fecha_nac,
   @i_entidad_nacimiento    = @i_provincia_nac,
   @o_mensaje               = @w_msg  out,
   @o_curp                  = @w_curp out,
   @o_rfc                   = @w_rfc  out

   if @w_error <> 0 goto ERROR_FIN

      if isnull(@i_cedula,'') = '' 
     begin
       select @i_cedula = @w_curp
     end
    else
      if @i_cedula <> @w_curp
        begin
          select @w_error = 1720394
          goto ERROR_FIN
        end

    if isnull(@i_nit,'')    = '' 
     begin
       select @i_nit    = @w_rfc
     end
   else
     if @i_nit <> @w_rfc
       begin
          select @w_error = 1720395
          goto ERROR_FIN
       end
 
    select @i_tipo_ced = 'CURP'
end  -- Solo para MX
else begin
  /* EL TIPO DE DOCUMENTO DE IDENTIDAD ES OBLIGATORIO*/
  if @i_tipo_ced is null and @i_estado_civil <> 'C' and @i_estado_civil <> 'A' begin
    select @w_error = 1720147
    goto ERROR_FIN
  end
end
if @i_other_project = 'N' and @i_numero_iden is not null and @i_tipo_iden is not null 
begin
   --VALIDACION DE ESTADO DE TIPO DE IDENTIFICACION ADICIONAL
   if(select ti_estado from cl_tipo_identificacion 
      where ti_codigo         = @i_tipo_iden 
      and   ti_tipo_documento = 'O' 
      and   ti_nacionalidad   = @w_nacionalidad 
      and   ti_tipo_cliente   = 'P') != 'V'
   begin
      select @w_error = 1720606
      goto ERROR_FIN
   end
   if exists(select 1 from cobis..cl_ente
   where en_subtipo     = 'P'
   and   en_numero_iden = @i_numero_iden
   and   en_tipo_iden   = @i_tipo_iden)
   begin
      select @w_error = 1720483   
      goto ERROR_FIN   
   end
end

--VALIDACION DE ESTADO DE TIPO DE IDENTIFICACION
if(select ti_estado from cl_tipo_identificacion
   where ti_codigo         = @i_tipo_ced 
   and   ti_tipo_documento = 'P' 
   and   ti_nacionalidad   = @w_nacionalidad 
   and   ti_tipo_cliente   = 'P') != 'V'
begin
   select @w_error = 1720605
   goto ERROR_FIN
end

if((@i_nit is not null or @i_nit = '') and 
(@i_tipo_tributario is not null or @i_tipo_tributario = ''))
begin
   --VALIDACION DE ESTADO DE TIPO DE IDENTIFICACION TRIBUTARIA
   if(select ti_estado from cl_tipo_identificacion 
      where ti_codigo         = @i_tipo_tributario 
      and   ti_tipo_documento = 'T' 
      and   ti_nacionalidad   = @w_nacionalidad 
      and   ti_tipo_cliente   = 'P') != 'V'
   begin
      select @w_error = 1720607
      goto ERROR_FIN
   end
   if exists(select 1 from cl_ente 
   where en_subtipo    = 'P' and
   en_nit = @i_nit 
   and en_tipo_doc_tributario = @i_tipo_tributario)
   begin
      select @w_error = 1720484
      goto ERROR_FIN
   end
end

--Validación para guardar identificación principal y tributaria con máscara definida
if @i_is_app = 'S'
begin
    if @i_tipo_ced = 'DUI'  and charindex('-', @i_cedula) = 0
    begin
        --Tipo de identificación Principal
        select @w_mascara = ti_mascara
        from  cobis..cl_tipo_identificacion
        where ti_codigo = @i_tipo_ced
        and   ti_tipo_cliente = 'P'
        and   ti_tipo_documento = 'P'
        and   ti_nacionalidad   = @w_nacionalidad
        and   ti_estado = 'V'
        
        select @w_doc_prin_mascara = cobis.dbo.fn_parsea_identificacion (@i_cedula, @w_mascara)
        select @i_cedula = @w_doc_prin_mascara
    end
    
    if @i_tipo_tributario = 'NIT' and (@i_nit is not null and @i_nit <> '')
    begin
        --Tipo de identificación Tributaria
        select @w_mascara = ti_mascara
        from  cobis..cl_tipo_identificacion
        where ti_codigo = @i_tipo_tributario
        and   ti_tipo_cliente = 'P'
        and   ti_tipo_documento = 'T'
        and   ti_nacionalidad   = @w_nacionalidad
        and   ti_estado = 'V'
        
        select @w_doc_trib_mascara = cobis.dbo.fn_parsea_identificacion (@i_nit, @w_mascara)
        select @i_nit = @w_doc_trib_mascara
    end
end

if @i_cedula is not null
begin
   if exists(select 1 from cobis..cl_ente
   where en_subtipo     = 'P'
   and   en_tipo_ced = @i_tipo_ced
   and   en_ced_ruc  = @i_cedula)
   begin
     select @w_error = 1720482   
     goto ERROR_FIN   
   end
end 

--Validar dígito verificador del DUI
if (@i_tipo_ced = 'DUI')
begin
  select @w_respuesta = cobis.dbo.fn_digito_verif_dui(@i_cedula)
  if @w_respuesta <> 0
  begin
     select @w_error = 1720664 -- 'NO SE CUMPLE CON LA VALIDACIÓN DEL DÍGITO VERIFICADOR DEL DUI'
     goto ERROR_FIN 
  end
end 

if @i_num_cargas = null
   select @i_num_cargas = 0

if @i_provincia_nac = 0
begin
   select @i_provincia_nac = null
end

if @i_ciudad_nac = 0
begin
   select @i_ciudad_nac = null
end

select
@o_curp = @i_cedula,
@o_rfc  = @i_nit

exec cobis..sp_cseqnos
@t_debug     = 'N',
@t_file      = '',
@t_from      = @w_sp_name,
@i_tabla     = 'cl_ente',
@o_siguiente = @o_ente out

if (@w_estado_civil='C'or @w_estado_civil='A') and @i_cedula= null 
begin
 select @i_cedula= convert (varchar(30),@o_ente+1) --248888
end

insert into cobis..cl_ente( 
en_ente,                       en_subtipo,                en_nombre,                    p_p_apellido,                 p_s_apellido,
p_sexo,                        en_tipo_ced,               en_ced_ruc,                   p_pasaporte,                  en_pais,
p_profesion,                   p_estado_civil,            p_num_cargas,                 p_nivel_ing,                  p_nivel_egr,
p_tipo_persona,                en_fecha_crea,             en_fecha_mod,                 en_filial,                    en_oficina,
en_direccion,                  en_referencia,             p_personal,                   p_propiedad,                  p_trabajo,
en_casilla,                    en_casilla_def,            en_tipo_dp,                   p_fecha_nac,                  en_balance,
en_grupo,                      en_retencion,              en_mala_referencia,           en_comentario,                en_actividad,
en_oficial,                    p_fecha_emision,           p_fecha_expira,               en_asosciada,                 en_referido,
en_sector,                     en_nit,                    p_depa_nac,                   p_lugar_doc,                  
p_nivel_estudio,
p_tipo_vivienda,               p_calif_cliente,           en_doc_validado,              en_rep_superban,              en_nomlar,
en_situacion_cliente,          p_dep_doc,                 p_c_apellido,                 p_s_nombre,                   p_numord,
en_cod_otro_pais,              en_ingre,                  en_estado,                    en_digito,                    en_concordato,
en_nacionalidad,               c_funcionario,             en_tipo_vinculacion,          c_tipo_compania,              en_emproblemado,
en_dinero_transac,             en_manejo_doc,             en_persona_pep,               c_activo,                     c_pasivo,
en_vinculacion,                en_tipo_iden,              en_numero_iden,               en_rfc,                       en_banco,                        
en_pais_nac,                   en_provincia_nac,          en_naturalizado,              en_forma_migratoria,          en_nro_extranjero,
en_calle_orig,                 en_exterior_orig,          en_estado_orig,               en_localidad,                 en_nro_ciclo,                  
en_actividad_desc,             en_calificacion,           p_ciudad_nac,                 p_ocupacion,                  p_carg_pub,
p_rel_carg_pub,                en_provincia_act,          en_nivel,                     p_genero,                     en_tipo_doc_tributario,
en_tipo_residencia,            en_ente_migrado,           en_ciudad_emision,            en_inf_laboral)                                                                                                    
values (
@o_ente,                       'P',                       @i_nombre,                    @i_p_apellido,                @i_s_apellido,
@i_sexo,                       @i_tipo_ced,               @i_cedula,                    @i_pasaporte,                 null,
@i_profesion,                  @w_estado_civil,           @i_num_cargas,                0,                            0,
@i_tipo,                       @s_date,                   @s_date,                      @i_filial,                    @i_oficina,
0,                             0,                         0,                            0,                            0,
0,                             null,                      null,                         @i_fecha_nac,                 0,
null,                          @i_retencion,              @w_mala_referencia,           @i_comentario,                @i_actividad,
@i_oficial,                    @i_fecha_emision,          @i_fecha_expira,              null,                         null,
@i_sector,                     @i_nit,                    @i_provincia_nac,             (case when @i_lugar_doc is null then @i_ciudad_emi else @i_lugar_doc end),                 
@i_nivel_estudio,
@i_tipo_vivienda,              @i_calif_cliente,          'N',                          'N',                          @w_nombre_completo,
@i_situacion_cliente,          @i_depart_doc,             @i_c_apellido,                @i_segnombre,                 @i_numord,
@i_cod_otro_pais,              @i_ingre,                  @i_bloquear,                  @i_digito,                    @i_categoria,
@i_nacionalidad,               @s_user,                   @i_tipo_vinculacion,          @w_nat_jur_hogar,             @i_emproblemado,
@i_dinero_transac,             @i_manejo_doc,             @i_pep,                       @i_mnt_activo,                @i_mnt_pasivo,                        
@i_vinculacion,                @i_tipo_iden,              @i_numero_iden,               @i_nit,                       @i_banco,                        
@i_pais_nac,                   @i_provincia_nac,          @i_naturalizado,              @i_forma_migratoria,          @i_nro_extranjero,
@i_calle_orig,                 @i_exterior_orig,          @i_estado_orig,               @i_localidad,                 @i_nro_ciclo,                                     
@i_actividad_desc,             @i_calificacion,           @i_ciudad_nac,                @i_ocupacion,                 @i_carg_pub,
@i_rel_carg_pub,               @i_entidad_act,            '1',                          @i_genero,                    @i_tipo_tributario,
@i_tipo_residencia,            @i_migrado,                @i_ciudad_emi,                @i_lug_trab)

if @@error <> 0 begin
   select @w_error = 1720036
   goto ERROR_FIN
end

exec cobis..sp_validacion_pep
   @s_ssn             = @s_ssn,
   @s_user            = @s_user,
   @s_term            = @s_term,
   @s_date            = @s_date,
   @s_srv             = @s_srv,
   @s_lsrv            = @s_lsrv,
   @s_ofi             = @s_ofi,
   @t_trn             = @w_trn_pep,
   @i_ente            = @o_ente,
   @i_operacion       = 'S',   
   @o_es_pep          = @w_es_pep      out,
   @o_dependencia     = @w_dependencia out,
   @o_puesto          = @w_puesto      out 

if @w_es_pep = 'S'
begin
    update cobis..cl_ente
    set en_persona_pep = @w_es_pep,
        p_carg_pub     = @w_puesto,
        p_rel_carg_pub = @w_dependencia
    where en_ente = @o_ente
end


-- Actualizacion Automatica de Prospecto a Cliente
exec cobis..sp_seccion_validar
@i_ente         = @o_ente,
@i_operacion    = 'V',
@i_seccion      = '1', --1 es PROSPECTO
@i_completado   = 'S'

if @i_oficina = @w_ofi_mobil begin
   
   select 
   @i_oficial      = oc_oficial,
   @i_oficina      = fu_oficina
   from cobis..cc_oficial, cobis..cl_funcionario
   where fu_login       = @s_user
   and   fu_funcionario = oc_funcionario

   update cobis..cl_ente set 
   en_oficina      = @i_oficina,
   en_oficial      = @i_oficial
   where en_ente   = @o_ente
       
end

select @w_ea_ced_ruc = replace(@i_cedula,'-','')


insert into cobis..cl_ente_aux  (
ea_ente,                 ea_estado,                  ea_observacion_aut,        ea_contrato_firmado,        ea_menor_edad,      
ea_conocido_como,        ea_cliente_planilla,        ea_cod_risk,               ea_sector_eco,              ea_actividad,       
ea_lin_neg,              ea_seg_neg,                 ea_ejecutivo_con,          ea_suc_gestion,             ea_constitucion,
ea_remp_legal,           ea_apoderado_legal,         ea_fuente_ing,             ea_act_prin,                ea_detalle,              
ea_act_dol,              ea_cat_aml,                 ea_ced_ruc,                ea_ant_nego,                ea_ventas,
ea_ot_ingresos,          ea_ct_ventas,               ea_ct_operativo,           ea_nro_ciclo_oi,            ea_nit,
ea_discapacidad,         ea_tipo_discapacidad,       ea_ced_discapacidad,       ea_nivel_egresos,           ea_ingreso_legal,
ea_actividad_legal,      ea_fatca,                   ea_crs,                    ea_telef_recados,           ea_antecedente_buro,
ea_persona_recados)
values (
@o_ente,                 @w_estado_referencia,       @i_ea_observacion_aut,     @i_ea_contrato_firmado,     @i_menor,          
@i_ea_conocido_como,     @i_ea_cliente_planilla,     @i_ea_cod_risk,            @i_ea_sector_eco,           @i_ea_actividad,   
@i_ea_lin_neg,           @i_ea_seg_neg,              @i_ejecutivo_con,          @i_suc_gestion,             @i_ea_constitucion,
@i_ea_remp_legal,        @i_ea_apoderado_legal,      @i_ea_fuente_ing,          @i_ea_act_prin,             @i_ea_detalle,
@i_ea_act_dol,           @i_ea_cat_aml,              @w_ea_ced_ruc,             @i_ant_nego,                @i_ventas,
@i_ot_ingresos,          @i_ct_ventas,               @i_ct_operativos,          @i_ea_nro_ciclo_oi,         @i_nit,
@i_ea_discapacidad,      @i_ea_tipo_discapacidad,    @i_ea_ced_discapacidad,    @i_egresos,                 @i_ingreso_legal,
@i_actividad_legal,      @i_fatca,                   @i_crs,                    @i_ea_telef_recados,        isnull(@i_antecedentes_buro,'N'),
isnull(@i_persona_recados,'N'))

if @@error <> 0 begin
   select @w_error = 1720048
   goto ERROR_FIN
end

/* Envia datos al front-end */
select 
en_ente,       
en_nombre,      
en_ced_ruc,
en_tipo_ced,   
p_p_apellido,   
p_s_apellido,
p_s_nombre
from  cobis..cl_ente
where  en_ente = @o_ente

select @o_ente

/* transaccion de servicio - nuevo */
insert into cobis..ts_persona_prin (
secuencia,             tipo_transaccion,          clase,                     fecha,                  usuario,
terminal,              srv,                       lsrv,                      persona,                nombre,
p_apellido,            s_apellido,                sexo,                      cedula,                 tipo_ced,
pais,                  profesion,                 estado_civil,              actividad,              num_cargas,
nivel_ing,             nivel_egr,                 tipo,                      filial,                 oficina,
fecha_nac,             grupo,                     oficial,                   comentario,             retencion,
fecha_mod,             fecha_expira,              ciudad_nac,                calif_cliente,          s_nombre, 
c_apellido,            secuen_alterno,            tipo_vinculacion,          pais_nac,               provincia_nac,
naturalizado,          forma_migratoria,          nro_extranjero,            calle_orig,             exterior_orig,
estado_orig,           localidad,                 hora)
values (
@s_ssn,                @t_trn,                    'N',                       @s_date,                 @s_user,
@s_term,               @s_srv,                    @s_lsrv,                   @o_ente,                 @i_nombre,
@i_p_apellido,         @i_s_apellido,             @i_sexo,                   @i_cedula,               @i_tipo_ced,
null,                  @i_profesion,              @w_estado_civil,           @i_actividad,            null,
null,                  null,                      @i_tipo,                   @i_filial,               @i_oficina,
@i_fecha_nac,          null,                      @i_oficial,                @i_comentario,           null,
null,                  @i_fecha_expira,           @i_ciudad_nac,             @i_calif_cliente,        @i_segnombre,
@i_c_apellido,         @i_secuencial,             @i_tipo_vinculacion,       @i_pais_nac,             @i_provincia_nac,
@i_naturalizado,       @i_forma_migratoria,       @i_nro_extranjero,         @i_calle_orig,           @i_exterior_orig,
@i_estado_orig,        @i_localidad,              getdate())

if @@error <> 0  begin
   select @w_error = 1720049
   goto ERROR_FIN
end

select @i_secuencial = @i_secuencial + 1

insert into cobis..ts_persona_sec (
secuencia,                tipo_transaccion,          clase,                  fecha,                     usuario,
terminal,                 srv,                       lsrv,                   persona,                   nombre,
p_apellido,               s_apellido,                ingre,                  id_tutor,                  nombre_tutor,        
bloquear,                 menor_edad,                conocido_como,          cliente_planilla,          cod_risk,        
sector_eco,               actividad_ea,              lin_neg,                seg_neg,                   remp_legal,            
apoderado_legal,          fuente_ing,                act_prin,               detalle,                   cat_aml,               
secuen_alterno2,          hora)
values (
@s_ssn,                   @t_trn,                    'N',                     @s_date,                   @s_user,
@s_term,                  @s_srv,                    @s_lsrv,                 @o_ente,                   @i_nombre,
@i_p_apellido,            @i_s_apellido,             @i_ingre,                null,                      null,
@i_bloquear,              @i_ea_menor_edad,          @i_ea_conocido_como,     @i_ea_cliente_planilla,    @i_ea_cod_risk,
@i_ea_sector_eco,         @i_ea_actividad,           @i_ea_lin_neg,           @i_ea_seg_neg,             @i_ea_remp_legal,
@i_ea_apoderado_legal,    @i_ea_fuente_ing,          @i_ea_act_prin,          @i_ea_detalle,             @i_ea_cat_aml,
@i_secuencial,            getdate())

if @@error <> 0 begin
   select @w_error = 1720049
   goto ERROR_FIN
end


if @i_estado_civil <>'C' and 
	@i_estado_civil <> 'A' begin --248888 conyuge 
-- REALIZA EL REGISTRO DEL HISTORICO DE IDENTIFICACIONES
exec @w_error = cobis..sp_registra_ident
@s_user           = @s_user,
@t_trn            = 172006,
@i_operacion      = 'I',
@i_ente           = @o_ente,
@i_tipo_iden      = @i_tipo_ced,
@i_identificacion = @i_cedula

if @w_error <> 0 goto ERROR_FIN
end  --248888 conyuge 
-- REALIZA EL REGISTRO PARA CALIFICACION
if @i_sic_asincronico = 'S' begin

   select @w_msg = @i_nombre + ' ' + isnull(@i_segnombre,'')
   
   insert into cobis..cl_calificacion_srv (
   cs_fecha,         cs_cliente,     cs_curp,              cs_nombres,           cs_p_apellido,
   cs_s_apellido,    cs_sexo,        cs_provincia_nac,     cs_estado_calif)
   values(
   @s_date    ,      @o_ente,        @i_cedula,           @w_msg,               @i_p_apellido,     
  @i_s_apellido,    @i_sexo,        @i_provincia_nac,    'ING')
     
end

--Registro del pseudonimo
if @i_pseudonimo is not null
begin
   select @w_pseudonimo_par = pa_tinyint
   from cobis.dbo.cl_parametro
   where pa_nemonico = 'CODPSE'
   and pa_producto = 'CLI'
   
   exec @w_error = cobis..sp_dad_ente
      @s_ssn             = @s_ssn,
      @s_user            = @s_user,
      @s_term            = @s_term,
      @s_date            = @s_date,
      @s_srv             = @s_srv,
      @s_lsrv            = @s_lsrv,
      @s_ofi             = @s_ofi,
      @t_debug           = 'N',
      @t_file            = '',
      @t_from            = @w_sp_name,
      @t_trn             = 172184,
      @i_operacion       = 'I',
      @i_ente            = @o_ente,
      @i_dato            = @w_pseudonimo_par,
      @i_tipodato        = 'C',
      @i_valor           = @i_pseudonimo,
      @i_tipoente        = 'P'
      
   if @w_error <> 0 
   begin
      goto ERROR_FIN
   end
end



select @w_sincroniza = pa_char
from cobis..cl_parametro
where pa_producto = 'CLI'
and pa_nemonico = 'HASIAU'

select @w_ofi_app = pa_smallint 
from cobis.dbo.cl_parametro cp 
where cp.pa_nemonico = 'OFIAPP'
and cp.pa_producto = 'CRE'

--Proceso de sincronizacion Clientes
if @o_ente is not null and @w_sincroniza = 'S' and @i_is_app = 'N' and @s_ofi <> @w_ofi_app
begin
   exec @w_error = cob_sincroniza..sp_sinc_arch_json
      @i_opcion     = 'I',
      @i_cliente    = @o_ente,
      @t_debug      = 'N'
      
   if @w_error <> 0 and @w_error is not null
   begin
      goto ERROR_FIN
   end
end

return 0
  

ERROR_FIN:

select @o_ente = null
if @i_sp_crea = 'N' begin
   if @i_batch = 'N' begin

      exec cobis..sp_cerror
      @t_debug   = 'N',
      @t_file    = '',
      @t_from    = @w_sp_name,                
      @i_num     = @w_error,
      @i_msg     = null,
      @s_culture = @s_culture

   end else begin 
      print 'ERROR:' + convert(varchar,@w_error) + @w_sp_name
   end
end
return @w_error

go
