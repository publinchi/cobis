USE [cob_sincroniza]
GO

/************************************************************************/
/*    Archivo:              sinc_arch_xml.sp                            */
/*    Stored procedure:     sp_sinc_arch_xml                            */
/*    Base de datos:        cobis                                       */
/*      Producto:               Clientes                                */
/*      Disenado por:           COB                                     */
/*      Fecha de escritura:     16-Marzo-21                             */
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
/*                              PROPOSITO                               */
/*             Ejecutar inserciones, consultas, eliminaciones           */
/*           y actualizaciones de datos adicionales con cliente         */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*      FECHA           AUTOR           RAZON                           */
/*     16/03/21          COB         Emision Inicial                    */
/************************************************************************/

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

if exists (select 1
           from   sysobjects
           where  name = 'sp_sinc_arch_xml')
   drop proc sp_sinc_arch_xml
go

create proc [dbo].[sp_sinc_arch_xml] (
   @t_file       varchar(14) = null,
   @t_debug      char(1)     = 'N',
   @i_opcion     char(1)     = 'I',
   @i_cliente    int         = null
)
as
declare
   @w_cod_entidad         varchar(10),
   @w_max_si_sincroniza   int,
   @w_fech_proc           datetime,
   @w_des_entidad         varchar(64),
   @w_xml                 varchar(5000),
   @w_accion              varchar(255),
   @w_observacion         varchar(5000),
   @w_error               int,
   @w_sp_name             varchar(32),
   @w_msg                 varchar(100),
   @w_user                login,
   @w_userId              int
   
select @w_sp_name = 'sp_sinc_arch_xml'

   --Datos de la Entidad -- Individual
    select @w_cod_entidad = 1      -- Catalogo si_sincroniza
    select @w_cod_entidad = codigo,
           @w_des_entidad = valor
    from cobis..cl_catalogo
    where tabla = ( select codigo  from cobis..cl_tabla
                    where tabla = 'si_sincroniza') and codigo = @w_cod_entidad

    --Fecha de Proceso
    select @w_fech_proc = fp_fecha from cobis..ba_fecha_proceso

   -- Comentarios
    select @w_accion = 'ACTUALIZAR'
   -- Observacion
   select @w_observacion = isnull(@w_observacion,'ACTUALIZAR INFORMACION')
   
   -- Usuario al que se rutea al sincronizar_clientes_xml
   select @w_user   = fu_login, 
         @w_userId = en_oficial
   from cobis..cl_ente en inner join cobis..cl_funcionario fu on fu.fu_funcionario = en.en_oficial
   where en_ente = @i_cliente


/* CREACION DE TABLA TEMPORAL CON REGISTROS DE INFORMACION DEL CLIENTE*/

if (OBJECT_ID('tempdb.dbo.#tmp_customer_information','U')) is not null
begin
   drop table #tmp_customer_information
end

create table #tmp_customer_information (
   nombreTabla       varchar(20)   null,
   en_ente           int           null,
   en_nombre         varchar(64)   null,
   p_s_nombre        varchar(20)   null,
   p_p_apellido      varchar(16)   null,
   p_s_apellido      varchar(16)   null,
   p_sexo            char(1)       null,
   p_fecha_nac       datetime      null,
   en_nac_aux        int           null,
   p_pais_emi        smallint      null,
   en_otringr        varchar(10)   null,
   p_estado_civil    varchar(10)   null,
   en_ced_ruc        varchar(30)   null,
   en_rfc            varchar(30)   null,
   
   di_calle          varchar(70)   null,
   di_nro            int           null,
   di_nro_interno    int           null,
   di_localidad      varchar(20)   null,
   di_parroquia      int           null,
   di_provincia      smallint      null,
   di_ciudad         int           null,
   di_codpostal      varchar(30)   null,
   di_pais           smallint      null,
   di_tiempo_reside  int           null,
   di_tipo_prop      char(10)      null,
   di_nro_residentes int           null
   
   -- FBO: Continuar con mas campos en tabla temporal
   
)
insert into #tmp_customer_information (nombreTabla,    en_ente,        en_nombre,
                                       p_s_nombre,     p_p_apellido,   p_s_apellido,   
                                       p_sexo,         p_fecha_nac,    en_nac_aux,
                                       p_pais_emi,     en_otringr,     p_estado_civil,   
                                       en_ced_ruc,     en_rfc)
   
                                select 'generalData',  en_ente,        en_nombre,      
                                       p_s_nombre,     p_p_apellido,   p_s_apellido,   
                                       p_sexo,         p_fecha_nac,    en_nac_aux,      
                                       p_pais_emi,     en_otringr,     p_estado_civil,   
                                       en_ced_ruc,     en_rfc
   from cobis..cl_ente
   where en_ente = @i_cliente

-- Direcciones Físicas
insert into #tmp_customer_information (nombreTabla,       di_calle,           di_nro,
                                       di_nro_interno,    di_localidad,       di_parroquia,
                                       di_provincia,      di_ciudad,          di_codpostal,
                                       di_pais,           di_tiempo_reside,   di_tipo_prop,
                                       di_nro_residentes)
                                select 'physicalAddress', di_calle,           di_nro,
                                       di_nro_interno,    di_localidad,       di_parroquia,
                                       di_provincia,      di_ciudad,          di_codpostal,
                                       di_pais,           di_tiempo_reside,   di_tipo_prop,   
                                       di_nro_residentes
   from cobis..cl_direccion
   where di_ente = @i_cliente
   and di_principal = 'S'
   and di_tipo = 'RE'

-- FBO: Continuar con insert en la tabla temporal de todas las secciones de Mantenimiento de Cliente


/* CONVERSION A XML*/ 
-- Inicio XML
select @w_xml = (
   SELECT tag, parent,
      [customerInformationSynchronizedData!1!valor],    --1
      [customerInformation!2!valor],                    --2
      [generalData!3!valor],                            --3
      [generalData!3!customerId!ELEMENT],               --4
      [generalData!3!nombre!ELEMENT],                   --5
      [generalData!3!nombreS!ELEMENT],                  --6
      [generalData!3!apellidoP!ELEMENT],                --7
      [generalData!3!apellidoS!ELEMENT],                --8
      [generalData!3!sexo!ELEMENT],                     --9
      [generalData!3!fechaNacimiento!ELEMENT],          --10
      [generalData!3!nacionalidad!ELEMENT],             --11
      [generalData!3!paisNacimiento!ELEMENT],           --12
      [generalData!3!nacionalizado!ELEMENT],            --13
      [generalData!3!estadoCivil!ELEMENT],              --14
      [generalData!3!curp!ELEMENT],                     --15
      [generalData!3!rfc!ELEMENT],                      --16
      [phyisicalData!4!valor],                          --17
      [phyisicalData!4!calle!ELEMENT],                  --18
      [phyisicalData!4!numero!ELEMENT],                 --19
      [phyisicalData!4!numeroI!ELEMENT],                --20
      [phyisicalData!4!localidad!ELEMENT],              --21
      [phyisicalData!4!departamento!ELEMENT],           --22
      [phyisicalData!4!estado!ELEMENT],                 --23
      [phyisicalData!4!municipio!ELEMENT],              --24
      [phyisicalData!4!codigoPostal!ELEMENT],           --25
      [phyisicalData!4!pais!ELEMENT],                   --26
      [phyisicalData!4!tiempoResidencia!ELEMENT],       --27
      [phyisicalData!4!tipoPropiedad!ELEMENT],          --28
      [phyisicalData!4!nroResidentes!ELEMENT]           --29
      -- FBO: Aumentar tag 5, 6, etc con nuevos campos
         
   FROM
   (
   SELECT 1 AS tag,
   NULL AS parent,
   NULL AS [customerInformationSynchronizedData!1!valor],  --1
   NULL AS [customerInformation!2!valor],                  --2
   NULL AS [generalData!3!valor],                          --3
   NULL AS [generalData!3!customerId!ELEMENT],             --4
   NULL AS [generalData!3!nombre!ELEMENT],                 --5
   NULL AS [generalData!3!nombreS!ELEMENT],                --6
   NULL AS [generalData!3!apellidoP!ELEMENT],              --7
   NULL AS [generalData!3!apellidoS!ELEMENT],              --8
   NULL AS [generalData!3!sexo!ELEMENT],                   --9
   NULL AS [generalData!3!fechaNacimiento!ELEMENT],        --10
   NULL AS [generalData!3!nacionalidad!ELEMENT],           --11
   NULL AS [generalData!3!paisNacimiento!ELEMENT],         --12
   NULL AS [generalData!3!nacionalizado!ELEMENT],          --13
   NULL AS [generalData!3!estadoCivil!ELEMENT],            --14
   NULL AS [generalData!3!curp!ELEMENT],                   --15
   NULL AS [generalData!3!rfc!ELEMENT],                    --16
   NULL AS [phyisicalData!4!valor],                        --17      
   NULL AS [phyisicalData!4!calle!ELEMENT],                --18      
   NULL AS [phyisicalData!4!numero!ELEMENT],               --19      
   NULL AS [phyisicalData!4!numeroI!ELEMENT],              --20      
   NULL AS [phyisicalData!4!localidad!ELEMENT],            --21      
   NULL AS [phyisicalData!4!departamento!ELEMENT],         --22      
   NULL AS [phyisicalData!4!estado!ELEMENT],               --23      
   NULL AS [phyisicalData!4!municipio!ELEMENT],            --24      
   NULL AS [phyisicalData!4!codigoPostal!ELEMENT],         --25      
   NULL AS [phyisicalData!4!pais!ELEMENT],                 --26      
   NULL AS [phyisicalData!4!tiempoResidencia!ELEMENT],     --27      
   NULL AS [phyisicalData!4!tipoPropiedad!ELEMENT],        --28      
   NULL AS [phyisicalData!4!nroResidentes!ELEMENT]         --29   
   -- FBO: Aumentar tag 5, 6, etc con nuevos campos   
         
   
   UNION ALL
   SELECT 2 AS tag,
   1 AS parent,
   NULL,   --1
   NULL,
   NULL,
   NULL,
   NULL,   --5
   NULL,
   NULL,
   NULL,
   NULL,
   NULL,   --10
   NULL,
   NULL,
   NULL,
   NULL,
   NULL,   --15
   NULL,
   NULL,
   NULL,
   NULL,
   NULL,   --20
   NULL,
   NULL,
   NULL,
   NULL,
   NULL,   --25
   NULL,
   NULL,
   NULL,
   NULL
   -- FBO: Aumentar campor NULL de acuerdo a número de campos de cabecera

   UNION ALL
   SELECT 3 AS tag,
   2 AS parent,
   NULL,--1
   NULL,
   NULL,--3
   'customerId'       = en_ente,
   'nombre'            = en_nombre,
   'nombreS'           = p_s_nombre,
   'apellidoP'         = p_p_apellido,
   'apellidoS'         = p_s_apellido,
   'sexo'              = p_sexo,
   'fechaNacimiento'   = p_fecha_nac,         --10
   'nacionalidad'      = en_nac_aux,
   'paisNacimiento'    = p_pais_emi,
   'nacionalizado'     = en_otringr,
   'estadoCivil'       = p_estado_civil,
   'curp'              = en_ced_ruc,
   'rfc'               = en_rfc,
   NULL,
   'calle'             = di_calle,
   'numero'            = di_nro,
   'numeroI'           = di_nro_interno,      --20
   'localidad'         = di_localidad,
   'departamento'      = di_parroquia,
   'estado'            = di_provincia,
   'municipio'         = di_ciudad,
   'codigoPostal'      = di_codpostal,
   'pais'              = di_pais,
   'tiempoResidencia'  = di_tiempo_reside,
   'tipoPropiedad'     = di_tipo_prop,
   'nroResidentes'     = di_nro_residentes
   -- FBO: Aumentar campor de acuerdo a número de campos de cabecera
   FROM #tmp_customer_information
   WHERE nombreTabla = 'generalData'
   
   UNION ALL
   SELECT 4 AS tag,
   2 AS parent,
   NULL,--1
   NULL,
   NULL,--3
   'customerId'      = en_ente,
   'nombre'            = en_nombre,
   'nombreS'           = p_s_nombre,
   'apellidoP'         = p_p_apellido,
   'apellidoS'         = p_s_apellido,
   'sexo'              = p_sexo,
   'fechaNacimiento'   = p_fecha_nac,         --10
   'nacionalidad'      = en_nac_aux,
   'paisNacimiento'    = p_pais_emi,
   'nacionalizado'     = en_otringr,
   'estadoCivil'       = p_estado_civil,
   'curp'              = en_ced_ruc,
   'rfc'               = en_rfc,
   NULL,
   'calle'             = di_calle,
   'numero'            = di_nro,
   'numeroI'           = di_nro_interno,      --20
   'localidad'         = di_localidad,
   'departamento'      = di_parroquia,
   'estado'            = di_provincia,
   'municipio'         = di_ciudad,
   'codigoPostal'      = di_codpostal,
   'pais'              = di_pais,
   'tiempoResidencia'  = di_tiempo_reside,
   'tipoPropiedad'     = rtrim(di_tipo_prop),
   'nroResidentes'     = di_nro_residentes
   -- FBO: Aumentar campor de acuerdo a número de campos de cabecera
   from #tmp_customer_information
   where nombreTabla = 'physicalAddress'   

   -- FBO: Aumentar otro UNION ALL por cada nuevo tag 

    ) as A for XML EXPLICIT )

-- Fin XML

/* INSERCION EN TABLAS DE SINCRONIZACION*/ 
   --Secuencial
   select @w_max_si_sincroniza = max(si_secuencial) + 1
   from   cob_sincroniza..si_sincroniza

   -- Insert en si_sincroniza
   insert into cob_sincroniza..si_sincroniza (si_secuencial,            si_cod_entidad, si_des_entidad,
                                              si_usuario,               si_estado,      si_fecha_ing,
                                              si_fecha_sin,             si_num_reg)
          values                             (@w_max_si_sincroniza,     @w_cod_entidad, @w_des_entidad,
                                              @w_user,                  'P',            @w_fech_proc,
                                              null,                     1)
   if @@error <> 0
   begin
       select @w_error = 150000 -- ERROR EN INSERCION
       goto ERROR
   end


   -- Insert en si_sincroniza_det
   insert into cob_sincroniza..si_sincroniza_det (sid_secuencial,       sid_id_entidad, sid_id_1,
                                                  sid_id_2,             sid_json,       sid_accion,
                                                  sid_observacion)
          values                                 (@w_max_si_sincroniza, @w_cod_entidad, @w_userId,
                                                  @i_cliente,           @w_xml,         @w_accion,
                                                  @w_observacion)

   if @@error <> 0
   begin
      select @w_error = 150000 -- ERROR EN INSERCION
      goto ERROR
   end
   return 0

ERROR:
   begin --Devolver mensaje de Error
      exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = @w_error,
         @i_msg   = @w_msg
      return @w_error   
   end
go
