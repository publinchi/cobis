/***************************************************************************/
/*    NOMBRE LOGICO: sp_crear_persona                                      */
/*    NOMBRE FISICO: crear_persona.sp                                      */
/*    PRODUCTO:      Clientes                                              */
/*    Disenado por:  JMEG                                                  */
/*    Fecha de escritura: 30-Abril-19                                      */
/***************************************************************************/
/*                     IMPORTANTE                                          */
/*   Este programa es parte de los paquetes bancarios que son              */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,         */
/*   representantes exclusivos para comercializar los productos y          */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida        */
/*   y regida por las Leyes de la República de España y las                */
/*   correspondientes de la Unión Europea. Su copia, reproducción,         */
/*   alteración en cualquier sentido, ingeniería reversa,                  */
/*   almacenamiento o cualquier uso no autorizado por cualquiera           */
/*   de los usuarios o personas que hayan accedido al presente             */
/*   sitio, queda expresamente prohibido; sin el debido                    */
/*   consentimiento por escrito, de parte de los representantes de         */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto         */
/*   en el presente texto, causará violaciones relacionadas con la         */
/*   propiedad intelectual y la confidencialidad de la información         */
/*   tratada; y por lo tanto, derivará en acciones legales civiles         */
/*   y penales en contra del infractor según corresponda.”.                */
/***************************************************************************/
/*                           PROPOSITO                                     */
/*   Este programa procesa las transacciones                               */
/*   DML de direcciones                                                    */
/***************************************************************************/
/*                        MODIFICACIONES                                   */
/*  FECHA              AUTOR              RAZON                            */
/*  30/04/19         JMEG         Emision Inicial                          */
/*  18/05/20         MBA          Cambio nombre y compilacion BDD cobis    */
/*  09/06/20         MBA          Estandarizacion sp y seguridades         */
/*  21/08/20         AHU          Agregando variable @i_entidad_act        */
/*  24/08/20         AHU          Agregando variable @i_other_project      */
/*  15/10/20         MBA          Uso de la variable @s_culture            */
/*  24/11/20         EGL          Agregando variable @i_genero             */
/*  09/12/20         IYU          Ajustes Grabar Conyugue                  */
/*  09/12/20         IYU          Actualizar localidad conyugue existe     */
/*  12/01/21         IYU          Actualizacion Tipos Identificacion       */
/*  17/01/23         BDU          S762873: Se agregan nuevos campos        */
/*  09-Mar-2023      E. Gaviria.  S763654 - Creación de prospectos         */
/*                                          desde la APP                   */
/*  27-Jun-2023      O. Guaño     S851475: Consulta de catalogo estado     */ 
/*                                         civil, cuando es SO             */  
/*  07-Sep-2023      O. Guaño     S896481: Validación para crear           */ 
/*                                         cliente offline APP             */  
/*  27-Sep-2023      J. Tabares   B895660: Crear prospecto modo            */ 
/*                                         cliente offline APP             */
/*  15/11/2023       O. Guaño     R219376: Se asocia la oficina del oficial*/
/*  12/12/2024       GRO          R248888:campos conozca su cliente        */  
/***************************************************************************/
use cobis
go

set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO

if exists (select 1 from sysobjects where name = 'sp_crear_persona')
   drop proc sp_crear_persona
go

create procedure sp_crear_persona (
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
       @i_nombre                           descripcion   = null,  -- primer nombre del cliente
       @i_papellido                        descripcion   = null,  -- primer apellido del cliente
       @i_sapellido                        descripcion   = null,  -- segundo apellido del cliente
       @i_filial                           tinyint       = null,  -- codigo de la filial
       @i_oficina                          smallint      = null,  -- codigo de la oficina
       @i_tipo_ced                         char(4)       = null,  -- tipo del documento de identificacion
       @i_tipo_tributario                  char(4)       = null,  -- tipo identificacion tributario
       @i_cedula                           varchar(30)   = null,  -- numero del documento de identificacion
       @i_login_oficial                    varchar(20)   = null,  -- codigo del oficial asignado al cliente
       @i_c_apellido                       varchar(30)   = null,  -- apellido casada
       @i_segnombre                        varchar(50)   = null,  -- segundo nombre
       @i_sector                           catalogo      = null,  -- sector economico del cliente
       @i_sexo                             varchar(10)   = null,  -- codigo del sexo del cliente
       @i_genero                           varchar(10)   = null,  -- codigo del genero del cliente
       @i_est_civil                        varchar(10)   = null,  -- estado civil del cliente
       @i_ea_estado                        catalogo      = null,  -- estado cliente
       @i_dir_virtual                      varchar(50)   = null,    -- email del cliente
       @i_dir_virtual_v                    char(1)       = 'N',   -- email del cliente esta verificado?
       @i_fecha_expira                     datetime      = null,
       @i_fecha_nac                        datetime      = null,
       @i_profesion                        catalogo      = null,  -- carrera profesional
       @i_ocupacion                        catalogo      = null,
       @i_tipo_vivienda                    catalogo      = null,
       @i_nombre_c                         descripcion   = null,  -- primer nombre del c=nyuge
       @i_papellido_c                      descripcion   = null,  -- primer apellido del c=nyuge
       @i_sapellido_c                      descripcion   = null,  -- segundo apellido del c=nyuge
       @i_tipo_ced_c                       char(4)       = 'SD',  -- tipo del documento de identificacion c=nyuge 248888 SD Sin identificación
       @i_tipo_tributario_c                char(4)       = null,  -- tipo del documento de identificacion tributario c=nyuge
       @i_cedula_c                         varchar(30)   = null,  -- numero del documento de identificacion c=nyuge
       @i_segnombre_c                      varchar(50)   = null,  -- segundo nombre c=nyuge
       @i_sexo_c                           varchar(10)   = null,  -- codigo del sexo del c=nyuge
       @i_genero_c                         varchar(10)   = null,  -- codigo del genero del conyuge
       @i_est_civil_c                      varchar(10)   = null,  -- estado civil del c=nyuge
       @i_ea_estado_c                      catalogo      = null,  -- estado del c=nyuge
       @i_c_apellido_c                     varchar(30)   = null,  -- Apellido de casada del conyuge
       @i_fecha_expira_c                   datetime     = null,
       @i_fecha_nac_c                      datetime        = null,
       @i_profesion_c                      catalogo      = null,
       @i_sector_c                         catalogo      = null,
       @i_calif_cliente                    catalogo      = null,
       @i_vinculacion                      char(1)       = null,
       @i_tipo_vinculacion                 varchar(10)   = null,
       @i_emproblemado                     char(1)       = null,  -- manejo de emproblemados
       @i_dinero_transac                   money         = null,  -- mnt de dinero transacciona mensualmente
       @i_manejo_doc                       varchar(25)   = null,  -- manejo de documentos
       @i_pep                              char(1)       = null,  -- s/n persona expuesta politicamente
       @i_mnt_activo                       money         = null,  -- monto de los activos del cliente
       @i_mnt_pasivo                       money         = null,  -- monto de los pasivos del cliente
       @i_tiempo_reside                    int           = null,  -- tiempo de residencia (meses)
       @i_ant_nego                         int           = null,  -- antiguedad del negicio (meses)
       @i_ventas                           money         = null,  -- ventas
       @i_ot_ingresos                      money         = null,  -- otros ingresos
       @i_ct_ventas                        money         = null,  -- costos ventas
       @i_ct_operativos                    money         = null,  -- costos operativos
       @i_ciudad_nac                       int           = null,  -- lgu santander: calculo de curp y rfc
       @i_ciudad_nac_c                     int           = null,  -- lgu santander: calculo de curp y rfc
       @i_operacion                        char(1),
       @i_ea_nro_ciclo_oi                  int           = null,  -- lpo santander --numero de ciclos en otras entidades
       @i_comentario                       varchar(254)  = null,
       @i_batch                            char(1)       = 'N'      , -- lgu: sp que se dispara desde fe o batch
       @i_num_ciclos                       int            = null,
       @i_banco                            varchar(20)   = null,
       @i_pais_nac                         varchar(20)   = null,
       @i_nacionalidad                     int           = null,
       @i_provincia_nac                    int             = null,
       @i_naturalizado                     char(1)         = null,
       @i_forma_migratoria                 varchar(64)   = null,
       @i_nro_extranjero                   varchar(64)   = null,
       @i_calle_orig                       varchar(70)   = null,
       @i_exterior_orig                    varchar(40)   = null,
       @i_estado_orig                      varchar(40)   = null,
       @i_escolaridad                      catalogo      = null,
       @i_nivel_estudio                    catalogo      = null,
       @i_actividad                        catalogo      = null,
       @i_retencion                        char(1)       = 'N',
       @i_ea_fuente_ing                    catalogo      = null,
       @i_ea_discapacidad                  char(1)       = null,    --PRESENCIA DE DISCAPACIDAD
       @i_ea_tipo_discapacidad             catalogo      = null,    --TIPO DE DISCAPACIDAD
       @i_ea_ced_discapacidad              varchar(30)   = null,    --CEDULA DE DISCAPACIDAD
       @i_pais_nac_c                       varchar(20)   = null,
       @i_nacionalidad_c                   int           = null,
       @i_provincia_nac_c                  int           = null,
       @i_naturalizado_c                   char(1)         = null,
       @i_forma_mig_c                      varchar(10)   = null,
       @i_numero_ext_c                     varchar(64)   = null,
       @i_tipo_iden_c                      varchar(13)   = null,
       @i_numero_iden_c                    varchar(32)   = null,
       @i_localidad                       varchar(20)   = null,
       @i_calle_orig_c                     varchar(70)   = null,
       @i_exterior_orig_c                  varchar(40)   = null,
       @i_estado_orig_c                    varchar(40)   = null,
       @i_escolaridad_c                    catalogo      = null,
       @i_nivel_estudio_c                  catalogo      = null,
       @i_ocupacion_c                      catalogo      = null,
       @i_actividad_c                      catalogo      = null,
       @i_ident_tipo_c                     varchar(10)   = null,
       @i_ident_num_c                      varchar(30)  = null,
       @i_email_c                          varchar(50)   = null,
       @i_email_c_v                        char(1)       = null, --email del conyuge está verificado
       @i_nro_ciclo                        int           = null,
       @i_ingre                            varchar(10)   = null,  -- codigo de ingreso de la persona
       @i_oficial                          int           = null,
       @i_tipo_iden                        varchar(13)   = null,
       @i_numero_iden                      varchar(20)   = null,
       @i_num_cargas                       int           = null,
       @i_sic_asincronico                  char(1)       = 's',
       @i_estado_afiliacion                catalogo      = null,
       @i_ingresoMensual                   money         = null,
       @i_actividad_desc                   varchar(50)   = null,
       @i_egresos                          catalogo      = null,
       @i_carg_pub                         varchar(200)  = null,
       @i_rel_carg_pub                     varchar(10)   = null,
       @i_nit                              varchar(30)   = null,  -- numero de identificacion tributaria del cliente
       @i_nit_c                            varchar(30)   = null,  -- numero de identificacion tributaria del conyugue
       @i_ingreso_legal                    char(1)       = null,
       @i_actividad_legal                  char(1)       = null,
       @i_fatca                            char(1)       = null,
       @i_crs                              char(1)       = null,
       @i_entidad_act                      catalogo      = null,
       @i_other_project                    char(1)       = 'N',  -- agregado para proyecto TRF MX
       @i_tipo_residencia                  char(2)       = null, -- Tipo Residencia Conyugue
       @i_tipo_residencia_c                char(2)       = null, -- Tipo Residencia Conyugue
       @i_migrado                          varchar(30)   = null,
       @i_existente                        varchar(5)    = 'false',
       @i_ea_con_como                      varchar(255)  = null,
       @i_ea_con_como_c                    varchar(255)  = null,
       @i_ciudad_emi                       int           = null,
       @i_ciudad_emi_c                     int           = null,
       @i_fecha_emi                        datetime      = null,
       @i_fecha_emi_c                      datetime      = null,
       @i_ea_telef_recados                 varchar(20)   = null,
       @i_ea_telef_recados_c               varchar(20)   = null,
       @i_antecedentes_buro                varchar(2)    = null,
       @i_persona_recados                  varchar(60)   = null,
       @i_is_app                           char(1)       = 'N',
       @i_pseudonimo                       descripcion   = null, -- Pseudonimo del cliente
	   @i_lug_trab_c                       varchar(200)  = null, -- 248888 lugar de trabajo cye
       @o_ente                             int           = null  out,
       @o_dire                             int           = null  out,
       @o_ente_c                           int           = null  out,
       @o_curp                             varchar(32)   = null  out, -- lgu: calculo de rfc y curp
       @o_rfc                              varchar(32)   = null  out, -- lgu: calculo de rfc y curp
       @o_curp_c                           varchar(32)   = null  out, -- lgu: calculo de rfc y curp
       @o_rfc_c                            varchar(32)   = null  out -- lgu: calculo de rfc y curp
)
as
declare @w_sp_name               varchar(30),
        @w_sp_msg                varchar(132),
        @w_relacion              int,
        @w_oficial               int,
        @w_estado_prospecto      char(1),
        @w_lado_relacion         char(1),
        @w_ente_c                int,
        @w_trn_dir               int,
        @w_error                 int,
        @w_operacion             char(1),
        @w_existente             bit,
		@w_login                 varchar(14),   --R219376: Se asocia la oficina del oficial
		@w_lug_trab              varchar(200),
		@w_apellido_casado       varchar(30)


/* INICIAR VARIABLES DE TRABAJO  */
select
@w_sp_name          = 'cobis..sp_crear_persona',
@w_sp_msg           = '',
@w_estado_prospecto = 'P',
@w_oficial          = @i_oficial,
@w_operacion        = ''

if @i_existente <> '2' 
   select @w_existente = @i_existente


/* VERSIONAMIENTO */
if @t_show_version = 1 begin
  select @w_sp_msg = concat('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = concat(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end

---- EJECUTAR SP DE LA CULTURA ---------------------------------------
exec cobis..sp_ad_establece_cultura
        @o_culture = @s_culture out


if LEN(@i_pais_nac)   > 10 begin select @w_error = 1720000 goto ERROR_FIN end
if LEN(@i_pais_nac_c) > 10 begin select @w_error = 1720001 goto ERROR_FIN end

/*VERIFICACION USUARIO*/
if @s_user is null begin select @s_user = ' ' end


/* VALIDACIONES GENERALES TANTO PARA EL CLIENTE COMO SU CONYUGE */
if @w_oficial is null and @i_login_oficial is not null begin
  select @w_oficial  = oc_oficial
  from  cobis..cc_oficial, cobis..cl_funcionario
  where  fu_login         = @i_login_oficial
  and    fu_funcionario   = oc_funcionario
end


if @i_is_app = 'S' begin
   if @w_oficial is null --Validación S896481 toma valor del parámetro creación offline APP
   begin
      select @w_oficial  = oc_oficial
       from  cobis..cc_oficial, cobis..cl_funcionario
      where  fu_login       = @s_user
        and  fu_funcionario = oc_funcionario
   end
   
   select @i_oficina = fu_oficina,                    --R219376: Se asocia la oficina del oficial
          @w_login   = fu_login
     from cobis..cc_oficial, cobis..cl_funcionario
    where oc_oficial = @w_oficial
      and fu_funcionario = oc_funcionario
    
   select @i_filial = us_filial  
     from cobis..ad_usuario 
    where us_login = @w_login
      and us_oficina = @i_oficina

   if @i_genero is null --Validación S896481 toma valor del parámetro creación offline APP
   begin
      select @i_genero = @i_sexo
   end
end

if @w_oficial is null begin
  select @w_error = 1720009
  goto ERROR_FIN
end


/* CREAR PERSONAS NATURALES O FISICAS */
if @i_operacion = 'I' begin

   if @t_trn <> 172000 begin
      select @w_error = 1720075
      goto ERROR_FIN
   end
   
   if @i_is_app = 'S'
   begin
      if @i_est_civil is null or @i_est_civil = 'SO'
      begin	  
         select @i_est_civil = c.codigo 
           from cobis..cl_tabla t, cobis..cl_catalogo c 
          where t.codigo = c.tabla
            and t.tabla = 'cl_ecivil'
            and c.valor like 'SO%'
	  end
	  
	  if @i_actividad is null or @i_actividad = '000'
	  begin
	     select @i_actividad = c.codigo 
	       from cobis..cl_tabla t, cobis..cl_catalogo c 
          where t.codigo = c.tabla
            and t.tabla = 'cl_actividad_ec'
            and c.valor like 'Actividades por definir%'
      end
   end
   
   if (@i_est_civil='C' or @i_est_civil='A') and @i_cedula= null 	
    begin
		select @i_tipo_ced='SD',
		       @w_lug_trab=@i_lug_trab_c		       
	end	
   else
    begin
        select @w_lug_trab=null
    end
   begin tran


   exec @w_error = sp_persona_ins
   @s_ssn                  = @s_ssn,
   @s_user                 = @s_user,
   @s_term                 = @s_term,
   @s_date                 = @s_date,
   @s_srv                  = @s_srv,
   @s_lsrv                 = @s_lsrv,
   @s_ofi                  = @s_ofi,
   @t_trn                  = @t_trn,
   @t_show_version         = @t_show_version,
   @i_batch                = @i_batch,
   @i_nombre               = @i_nombre,
   @i_p_apellido           = @i_papellido,
   @i_s_apellido           = @i_sapellido,
   @i_filial               = @i_filial,
   @i_oficina              = @i_oficina,
   @i_tipo_ced             = @i_tipo_ced,
   @i_tipo_tributario      = @i_tipo_tributario,
   @i_cedula               = @i_cedula,
   @i_oficial              = @w_oficial,
   @i_segnombre            = @i_segnombre,
   @i_fecha_nac            = @i_fecha_nac,
   @i_sector               = @i_sector,
   @i_sexo                 = @i_sexo,
   @i_genero               = @i_genero,
   @i_estado_civil         = @i_est_civil,
   @i_c_apellido           = @i_c_apellido,
   @i_estado               = @w_estado_prospecto,
   @i_nacionalidad         = @i_nacionalidad,
   @i_secuencial           = 1,
   @i_sp_crea              = 'S',
   @i_vinculacion          = @i_vinculacion,
   @i_tipo_vinculacion     = @i_tipo_vinculacion,
   @i_emproblemado         = @i_emproblemado,
   @i_dinero_transac       = @i_dinero_transac,
   @i_manejo_doc           = @i_manejo_doc,
   @i_pep                  = @i_pep,
   @i_mnt_activo           = @i_mnt_activo,
   @i_mnt_pasivo           = @i_mnt_pasivo,
   @i_ant_nego             = @i_ant_nego,
   @i_ventas               = @i_ventas,
   @i_ot_ingresos          = @i_ot_ingresos,
   @i_ct_ventas            = @i_ct_ventas,
   @i_ct_operativos        = @i_ct_operativos,
   @i_ciudad_nac           = @i_ciudad_nac,
   @i_ea_nro_ciclo_oi      = @i_ea_nro_ciclo_oi,
   @i_banco                = @i_banco,
   @i_pais_nac             = @i_pais_nac,
   @i_provincia_nac        = @i_provincia_nac,
   @i_naturalizado         = @i_naturalizado,
   @i_forma_migratoria     = @i_forma_migratoria,
   @i_nro_extranjero       = @i_nro_extranjero,
   @i_calle_orig           = @i_calle_orig,
   @i_exterior_orig        = @i_exterior_orig,
   @i_estado_orig          = @i_estado_orig,
   @i_tipo_iden            = @i_tipo_iden,
   @i_numero_iden          = @i_numero_iden,
   @i_nro_ciclo            = @i_nro_ciclo,
   @i_num_cargas           = @i_num_cargas,
   @i_sic_asincronico      = 'S',
   @i_situacion_cliente    = @i_estado_afiliacion,
   @i_ingresoMensual       = @i_ingresoMensual,
   @i_actividad_desc       = @i_actividad_desc,
   @i_nivel_estudio        = @i_nivel_estudio,
   @i_escolaridad          = @i_escolaridad,
   @i_profesion            = @i_profesion,
   @i_tipo_vivienda        = @i_tipo_vivienda,
   @i_actividad            = @i_actividad,
   @i_retencion            = @i_retencion,
   @i_calif_cliente        = @i_calif_cliente,
   @i_comentario           = @i_comentario,
   @i_ea_fuente_ing        = @i_ea_fuente_ing,
   @i_ea_discapacidad      = @i_ea_discapacidad,
   @i_ea_tipo_discapacidad = @i_ea_tipo_discapacidad,
   @i_ea_ced_discapacidad  = @i_ea_ced_discapacidad,
   @i_egresos              = @i_egresos,
   @i_localidad            = @i_localidad,
   @i_ocupacion            = @i_ocupacion,
   @i_ingre                = @i_ingre,
   @i_carg_pub             = @i_carg_pub,
   @i_rel_carg_pub         = @i_rel_carg_pub,
   @i_nit                  = @i_nit,
   @i_ingreso_legal        = @i_ingreso_legal,
   @i_actividad_legal      = @i_actividad_legal,
   @i_fatca                = @i_fatca,
   @i_crs                  = @i_crs,
   @i_entidad_act          = @i_entidad_act,
   @i_other_project        = @i_other_project,
   @i_tipo_residencia      = @i_tipo_residencia,
   @i_ea_conocido_como     = @i_ea_con_como,
   @i_ciudad_emi           = @i_ciudad_emi,
   @i_fecha_emision        = @i_fecha_emi,
   @i_fecha_expira         = @i_fecha_expira,
   @i_ea_telef_recados     = @i_ea_telef_recados,
   @i_migrado              = @i_migrado,
   @i_antecedentes_buro    = @i_antecedentes_buro,
   @i_persona_recados      = @i_persona_recados, 
   @i_is_app               = @i_is_app,
   @i_pseudonimo           = @i_pseudonimo,
   @i_lug_trab             = @w_lug_trab,  
   @o_curp                 = @o_curp out,
   @o_rfc                  = @o_rfc  out,
   @o_ente                 = @o_ente out


   if @w_error <> 0 or @o_ente is null
   begin
      if @w_error = 1720482
      begin
         if @i_existente = '2'
            select @w_error = 1720520
         else
            select @w_error = 1720519
      end
      
      if @w_error = 1720605 and @i_existente = '2'
            select @w_error = 1720608

         if @w_error = 1720606 and @i_existente = '2'
            select @w_error = 1720529

         if @w_error = 1720607 and @i_existente = '2'
            select @w_error = 1720610


      if @w_error = 1720483
         select @w_error = 1720521

      if @w_error = 1720484
         select @w_error = 1720523

      goto ERROR_FIN
   end

   if isnull(@i_dir_virtual,'') != ''  begin

      exec @w_error = cobis..sp_direccion_dml
      @s_srv            = @s_srv,
      @s_user           = @s_user,
      @s_term           = @s_term,
      @s_ofi            = @s_ofi,
      @s_rol            = @s_rol,
      @s_ssn            = @s_ssn,
      @s_lsrv           = @s_lsrv,
      @s_date           = @s_date,
      @s_org            = @s_org,
      @t_trn            = 172016,
      @i_ente           = @o_ente,
      @i_descripcion    = @i_dir_virtual,
      @i_tipo           = 'CE',
      @i_operacion      = @i_operacion,
      @i_verificado     = @i_dir_virtual_v,
      @i_tiempo_reside  = @i_tiempo_reside,
      @i_localidad      = @i_localidad,
      @o_dire           = @o_dire out

      if @w_error <> 0 or @o_dire is null begin
         select @w_error = 1720011
         goto ERROR_FIN
      end

   end

   if @i_est_civil in (select c.codigo
                       from cl_catalogo c, cl_tabla t
                       where t.tabla  = 'cl_ecivil_conyuge'
                       and c.tabla = t.codigo)
   and @i_existente <> '2'
   and isnull(@i_nombre_c,'') <> '' select @w_operacion = 'C'

end


/* CREAR EL CONYUGE DE LA PERSONA NATURAL */
if @w_operacion = 'C' and @i_nombre_c != ''
begin
   select @w_lado_relacion = 'I'

   select @w_relacion = pa_tinyint
   from cobis..cl_parametro
   where pa_nemonico = 'CONY' --Relacion Conyuge
   and   pa_producto = 'CLI'

   if @w_relacion is null begin
      select @w_error = 1720013
      goto ERROR_FIN
   end


   select
   @w_ente_c          = 0,
   @i_operacion       = 'I',
   @w_trn_dir         = 172016,
   @i_sic_asincronico = 'S',
   @i_tipo_ced_c      = 'SD' 

   select @w_ente_c = in_ente_i
   from cobis..cl_instancia
   where in_ente_d   = @o_ente
   and   in_relacion = @w_relacion

   if @w_ente_c = 0
   begin
        
	  if (@i_nombre_c != null and @i_nombre_c != '' and @w_existente = 1)     
           
                select @w_ente_c     = en_ente,
                   @i_localidad  = en_direccion
                from cobis..cl_ente
                where en_subtipo    = 'P'
                and   en_nombre     = @i_nombre_c
                and   p_p_apellido  = @i_papellido_c				            
       
	  
   end

   if @w_ente_c > 0 select @i_operacion = 'U', @w_trn_dir = 172019, @i_sic_asincronico = 'N'
select @i_cedula_c= convert (varchar(30),@o_ente+1) --248888
   if @w_ente_c = 0 begin   
     
      exec @w_error = sp_persona_ins
      @s_srv              = @s_srv,
      @s_user             = @s_user,
      @s_term             = @s_term,
      @s_ofi              = @s_ofi,
      @s_ssn              = @s_ssn,
      @s_lsrv             = @s_lsrv,
      @s_date             = @s_date,
      @t_trn              = @t_trn,
      @i_batch            = @i_batch,	 
	  @i_lug_trab         = @i_lug_trab_c,  
      @i_nombre           = @i_nombre_c,	
      @i_p_apellido       = @i_papellido_c,
      @i_s_apellido       = @i_sapellido_c,
      @i_filial           = @i_filial,
      @i_oficina          = @i_oficina,
      @i_tipo_ced         = @i_tipo_ced_c, 
      @i_tipo_tributario  = @i_tipo_tributario_c,
      @i_cedula           = @i_cedula_c,   
      @i_oficial          = @w_oficial,
      @i_segnombre        = @i_segnombre_c,
      @i_fecha_nac        = @i_fecha_nac_c,
      @i_sector           = @i_sector_c,
      @i_sexo             = @i_sexo_c,
      @i_genero           = @i_genero_c,
      @i_estado_civil     = @i_est_civil, 
      @i_c_apellido       = @i_c_apellido_c,
      @i_estado           = @w_estado_prospecto,
      @i_nacionalidad     = @i_nacionalidad_c,
      @i_secuencial       = 3,
      @i_ciudad_nac       = @i_ciudad_nac_c ,
      @i_banco            = @i_banco,
      @i_pais_nac         = @i_pais_nac_c,
      @i_provincia_nac    = @i_provincia_nac_c,
      @i_naturalizado     = @i_naturalizado_c,
      @i_forma_migratoria = @i_forma_mig_c,
      @i_nro_extranjero   = @i_numero_ext_c,
      @i_calle_orig       = @i_calle_orig_c,
      @i_exterior_orig    = @i_exterior_orig_c,
      @i_estado_orig      = @i_estado_orig_c,
      @i_tipo_iden        = @i_tipo_iden_c,
      @i_numero_iden      = @i_numero_iden_c,
      @i_num_cargas       = @i_num_cargas,
      @i_sic_asincronico  = @i_sic_asincronico,
      @i_ingresoMensual   = @i_ingresoMensual ,
      @i_actividad_desc   = @i_actividad_desc,
      @i_nivel_estudio    = @i_nivel_estudio_c,
      @i_escolaridad      = @i_escolaridad_c,
      @i_profesion        = @i_profesion_c,
      @i_ocupacion        = @i_ocupacion_c,
      @i_tipo_vivienda    = @i_tipo_vivienda, 
      @i_actividad        = @i_actividad_c,
      @i_retencion        = @i_retencion,     
      @i_calif_cliente    = @i_calif_cliente, 
      @i_comentario       = @i_comentario,
      @i_localidad        = @i_localidad,
      @i_ingre            = @i_ingre,
      @i_carg_pub         = @i_carg_pub,
      @i_rel_carg_pub     = @i_rel_carg_pub,
      @i_nit              = @i_nit_c,
      @i_fatca            = @i_fatca,
      @i_crs              = @i_crs,
      @i_sp_crea          = 'S',
      @i_other_project    = @i_other_project,
      @i_tipo_residencia  = @i_tipo_residencia_c,
      @i_ea_conocido_como = @i_ea_con_como_c,
      @i_ciudad_emi       = @i_ciudad_emi_c,
      @i_fecha_emision    = @i_fecha_emi_c,
      @i_fecha_expira     = @i_fecha_expira_c,
      @i_ea_telef_recados = @i_ea_telef_recados_c,
      @o_curp             = @o_curp_c          out,
      @o_rfc              = @o_rfc_c           out,
      @o_ente             = @o_ente_c          out

      if @w_error <> 0 or @o_ente_c is null
      begin
         if @w_error = 1720482
            select @w_error = 1720520

         if @w_error = 1720483
            select @w_error = 1720522

         if @w_error = 1720484
            select @w_error = 1720524
            
         if @w_error = 1720605
            select @w_error = 1720608

         if @w_error = 1720606
            select @w_error = 1720529

         if @w_error = 1720607
            select @w_error = 1720610

         goto ERROR_FIN
      end
   end else begin
   --print 'Actualiza ' + convert(varchar,@w_ente_c)
   
		if (@i_nombre_c != null or @i_nombre_c != '' )
		begin 
			select @w_apellido_casado = @i_papellido
		end
		else 
		begin
			select @w_apellido_casado = @i_c_apellido_c
		 
		 end		 
		
      exec @w_error = sp_persona_upd
      @s_srv              = @s_srv,
      @s_user             = @s_user,
      @s_term             = @s_term,
      @s_ofi              = @s_ofi,
      --@s_rol            = @s_rol,
      @s_ssn              = @s_ssn,
      @s_lsrv             = @s_lsrv,
      @s_date             = @s_date,
      --@s_org            = @s_org,
      @t_trn              = 172003 ,	 
	  @i_lug_trab         = @i_lug_trab_c,  --248888
      @i_batch            = @i_batch,
      @i_persona          = @w_ente_c,
      @i_nombre           = @i_nombre_c,
      @i_p_apellido       = @i_papellido_c,
      @i_s_apellido       = @i_sapellido_c,
      @i_filial           = @i_filial,
      @i_oficina          = @i_oficina,
      @i_tipo_ced         = @i_tipo_ced_c, --24888 llegará SD(SIN IDENTIF)
      @i_tipo_tributario  = @i_tipo_tributario_c,
      @i_cedula           = @i_cedula_c, --248888 cod ente -clave cl_ente_Key2
      @i_oficial          = @w_oficial,
      @i_segnombre        = @i_segnombre_c,
      @i_fecha_nac        = @i_fecha_nac_c,
      @i_sector           = @i_sector_c,
      @i_sexo             = @i_sexo_c,
      @i_genero           = @i_genero_c,
      @i_estado_civil     = @i_est_civil, --248888 mismo q el cli principal
      @i_c_apellido       = @w_apellido_casado,
      @i_operacion        = @i_operacion,
      @i_ocupacion        = @i_ocupacion_c,
      @i_nacionalidad     = @i_nacionalidad_c,
      --@i_secuencial     = 3,
      @i_ciudad_nac       = @i_ciudad_nac_c ,
      @i_banco            = @i_banco,
      @i_pais_nac         = @i_pais_nac_c,
      @i_provincia_nac    = @i_provincia_nac_c,
      @i_naturalizado     = @i_naturalizado_c,
      @i_forma_migratoria = @i_forma_mig_c,
      @i_nro_extranjero   = @i_numero_ext_c,
      @i_calle_orig       = @i_calle_orig_c,
      @i_exterior_orig    = @i_exterior_orig_c,
      @i_estado_orig      = @i_estado_orig_c,
      @i_tipo_iden        = @i_tipo_iden_c,
      @i_nit              = @i_nit_c,
      @i_numero_iden      = @i_numero_iden_c,
      @i_tipo_residencia  = @i_tipo_residencia_c,
      --@i_email_c        = @i_email_c,
      @i_num_cargas       = @i_num_cargas,
      @i_telefono_recados = @i_ea_telef_recados_c

      --@i_sic_asincronico   = @i_sic_asincronico,
      --@i_ingresoMensual    = @i_ingresoMensual ,
      --@i_actividad_desc    = @i_actividad_desc,
      --@i_nivel_estudio     = @i_nivel_estudio_c,
      --@i_escolaridad       = @i_escolaridad_c,
      --@i_profesion         = @i_profesion_c,
      --@i_tipo_vivienda     = @i_tipo_vivienda, -- la misma que el conyuge
      --@i_actividad         = @i_actividad_c,
      --@i_retencion         = @i_retencion,     -- la misma que el conyuge
      --@i_calif_cliente     = @i_calif_cliente, -- la misma que el conyuge
      --@i_comentario        = @i_comentario,
      --@i_fatca             = @i_fatca,
      --@i_crs               = @i_crs,
      --@o_curp              = @o_curp_c          out,
      --@o_rfc               = @o_rfc_c           out,
      --@o_ente            = @o_ente_c          out
   end

--print '@o_ente: -' + convert(varchar,@o_ente)+'-'
--print '@o_ente_c: -' + convert(varchar,@o_ente_c)+'-'
    if @o_ente_c  = 0
    begin
        select @o_ente_c = @w_ente_c
    end



    exec @w_error = cobis..sp_instancia
      @s_srv          = @s_srv,
      @s_user         = @s_user,
      @s_term         = @s_term,
      @s_ofi          = @s_ofi,
      @s_rol          = @s_rol,
      @s_ssn          = @s_ssn,
      @s_lsrv         = @s_lsrv,
      @s_date         = @s_date,
      @s_org          = @s_org,
      @t_trn          = 172029,
      @i_relacion   = @w_relacion,
      @i_derecha      = @o_ente,
      @i_izquierda  = @o_ente_c,
      @i_lado         = @w_lado_relacion,
      @i_operacion  = 'I'

      if @w_error <> 0  begin
         goto ERROR_FIN
      end


   if isnull(@i_email_c,'') != ''
   begin
      select @i_localidad = 0

       select @i_localidad = di_direccion from cobis..cl_direccion where di_ente = @o_ente_c and di_descripcion = @i_email_c

       if @i_localidad = 0
       begin
            select @i_operacion = 'I'
       end

      --se guarda el correo del conyuge
      exec @w_error = cobis..sp_direccion_dml
      @s_srv           = @s_srv,
      @s_user          = @s_user,
      @s_term          = @s_term,
      @s_ofi           = @s_ofi,
      @s_rol           = @s_rol,
      @s_ssn           = @s_ssn,
      @s_lsrv          = @s_lsrv,
      @s_date          = @s_date,
      @s_org           = @s_org,
      @t_trn           = @w_trn_dir,
      @i_ente          = @o_ente_c,
      @i_descripcion   = @i_email_c,
      @i_tipo          = 'CE',
      @i_operacion     = @i_operacion,
      @i_verificado    = @i_email_c_v,
      @i_tiempo_reside = 0,
      @i_direccion     = @i_localidad,
      @o_dire          = @o_dire out

      if @w_error <> 0 or @o_dire is null begin
         select @w_error = 1720015
         goto ERROR_FIN
      end

   end

end
commit tran
return 0

ERROR_FIN:

while @@trancount > 0 rollback

if @i_batch = 'N' begin
   exec cobis..sp_cerror
   @t_debug   = @t_debug,
   @t_file    = @t_file,
   @t_from    = @w_sp_name,
   @i_num     = @w_error,
   @s_culture = @s_culture
end
return @w_error
go
