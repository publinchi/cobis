/********************************************************************/
/*   NOMBRE LOGICO:         sp_direccion_dml                        */
/*   NOMBRE FISICO:         direccion_dml.sp                        */
/*   BASE DE DATOS:         cobis                                   */
/*   PRODUCTO:              Clientes                                */
/*   DISENADO POR:          RIGG                                    */
/*   FECHA DE ESCRITURA:    30-Abr-2019                             */
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
/*    Este programa procesa las transacciones DML de direcciones    */
/********************************************************************/
/*                     MODIFICACIONES                               */
/*   FECHA        AUTOR      RAZON                                  */
/*   30-Mar-2019  RIGG       Versión Inicial Te Creemos             */
/*   18-May-2020  MBA        Cambio nombre y compilacion BDD cobis  */
/*   22-Jun-2020  FSAP       Estandarizacion de Clientes            */
/*   30-Jun-2020  WAVB       Refactor a procesos del sp             */
/*   15-Oct-2020  MBA        Uso de la variable @s_culture          */
/*   22-Dic-2020  IYU        Agregar Campos direccion - CLI-S412684 */
/*   13-Ago-2021  COB        Se elimina validacion direccion-negocio*/
/*   20-Ago-2021  ACU        Se agrega operacion N para asociar     */
/*                           direcciones existentes a un negocio    */
/*   14-Sep-2022  P. Jarrin. Se mejora eliminacion telefonos R192910*/
/*   29-May-2023  P. Jarrin. BM Sincronización de medios - S832369  */
/*   21-Jul-2023  BDU        Fix validacion negocio                 */
/*   10-Ago-2023  BDU        R213025 Agregar condicion              */
/*   09-Sep-2023  BDU        R214440-Sincronizacion automatica      */
/*   22-Ene-2024  BDU        R224055-Validar oficina app            */
/*   08-May-2025  GRO        R268869 Eliminar caracteres \n \t      */
/********************************************************************/

use cobis
go
set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO

if exists (select 1 
             from sysobjects 
            where name = 'sp_direccion_dml')
   drop proc sp_direccion_dml 
go

create proc sp_direccion_dml (
   @s_ssn                int,
   @s_user               login        = null,
   @s_sesn               int          = null,
   @s_term               varchar(32)  = null,
   @s_date               datetime,
   @s_srv                varchar(30)  = null,
   @s_lsrv               varchar(30)  = null,
   @s_ofi                smallint     = NULL,
   @s_rol                smallint     = NULL,
   @s_org_err            char(1)      = NULL,
   @s_error              int          = NULL,
   @s_sev                tinyint      = NULL,
   @s_msg                descripcion  = NULL,
   @s_org                char(1)      = NULL,
   @s_culture            varchar(10)  = 'NEUTRAL',
   @t_debug              char(1)      = 'N',
   @t_file               varchar(10)  = null,
   @t_from               varchar(32)  = null,
   @t_trn                int          = null,
   @t_show_version       bit          = 0,    -- Mostrar la versi+Ýn del programa
   @i_operacion          char(1),             -- Opcion con la que se ejecuta el programa
   @i_ente               int          = null, -- Codigo secuencial del cliente
   @i_direccion          tinyint      = null, -- Numero de la direccion que se asigna al Cliente
   @i_descripcion        varchar(254) = null, -- Descripcion de la direccion
   @i_tipo               catalogo     = null, -- Tipo de direccion
   @i_sector             catalogo     = null, -- En el caso de direccion extranjera, se almacena el pais
   @i_parroquia          int          = null, -- Codigo de la parroquia de la direccion
   @i_barrio             char(40)     = null, -- Codigo del barrio
   @i_zona               catalogo     = null, -- Codigo de la zona postal 
   @i_ciudad             int          = null, -- Codigo del municipio / ito de int a smallint
   @i_oficina            smallint     = null, -- Codigo de la oficina
   @i_verificado         char(1)      = 'N',  -- Indicador si esta verificado
   @i_fecha_ver          datetime     = null, -- Fecha de verificacion
   @i_principal          char(1)      = 'N',  -- Indicador si la direccion es principal
   @i_provincia          int          = null, -- Codigo del departamento
   @i_codpostal          char(5)      = null, -- Codigo Postal
   @i_define             char(1)      = 'N',  -- Indicador de validacion cuando las direcciones no son ni mail,web, extranjera   
   @i_calle              varchar(70)  = null, -- Indica la Calle      -- TVI 05/31/2011   INC 2124
   @i_cliente_casual     char(1)      = null, -- GC Cliente Casual
   @i_tiempo_reside      int          = null, -- Tiempo de residencia
   @i_pais               smallint     = null,
   @i_canton             int          = null,
   @i_codbarrio          int          = null,
   @i_distrito           int          = null,
   @i_correspondencia    char(1)      = null,
   @i_alquilada          char(1)      = null,
   @i_cobro              char(1)      = null,
   @i_otrasenas          varchar(254) = null,
   @i_montoalquiler      money        = null,   
   @i_rural_urbano       char(1)      = null,
   @i_departamento       varchar(10)  = null,
   @i_fact_serv_pu       char(1)      = 'N',
   @i_tipo_prop          char(10)     = null,
   @i_ejecutar           char(1)      ='N',        --MALDAZ 06/25/2012 HSBC CLI-0565
   @i_co_igual_so        char(1)      = null,
   @i_nombre_agencia     varchar(20)  = null,
   @i_fuente_verif       varchar(10)  = NULL,
   @i_nro                varchar(40)  = NULL,     --numero de la calle
   @i_nro_residentes     INT          = NULL,     --Numero de residentes en el domicilio
   @i_nro_interno        varchar(40)  = NULL,     --numero de la calle
   @i_negocio            int          = NULL,     --Negocio
   @i_batch              char(1)      = 'N'      , -- LGU: sp que se dispara desde FE o BATCH
   @i_ci_poblacion       varchar(30)  = null  , --ciudad Poblacion
   @i_referencias_dom    varchar(256) = null,              --se agregan nuevos parametros
   @i_otro_tipo          varchar(30)  = null,               --se agregan nuevos parametros
   @i_localidad          varchar(30)  = null,                --se agregan nuevos parametros
   @i_conjunto           varchar(40)  = null,
   @i_piso               varchar(40)  = null,
   @i_numero_casa        varchar(40)  = null,
   @i_desasociar_dir     char(1)      = 'N',
   @o_dire               int          = null out,
   @o_pais               smallint     = null out,
   @o_canton             int          = null out,
   @o_codbarrio          int          = null out,
   @o_correspondencia    char(1)      = null out,
   @o_alquilada          char(1)      = null out,
   @o_cobro              char(1)      = null out
)
as
declare
   @w_sp_name              varchar(32),   
   @w_sp_msg               varchar(132),
   @w_codigo               int,
   @w_error                int,
   @w_return               int,
   @w_descripcion          varchar(254),
   @w_tipo                 catalogo,
   @w_sector               catalogo, 
   @w_zona                 catalogo,
   @w_parroquia            int,
   @w_barrio               char(40),
   @w_ciudad               int, -- de int a smallint
   @w_oficina              smallint,
   @w_verificado           char(1),
   @w_vigencia             char(1),
   @w_principal            char(1),             
   @w_casa                 varchar(40),  
   @w_calle                varchar(70),
   @w_provincia            int,
   @w_direccion            varchar(3),
   @w_pais                 smallint, 
   @w_canton               int,
   @w_codbarrio            int,
   @w_distrito             int,
   @w_estado_campo         char(1),      --Miguel Aldaz  06/26/2012 Doble autorizaci+Ýn CLI-0565 HSBC
   @w_co_igual_so          char(1),
   @w_iguales              char(1),
   @w_subtipo              char(1),
   @w_negocio_actual       smallint,
   @w_direccion_dc         tinyint,
   @w_direccion_anterior   smallint,
   @o_siguiente            int,
   @w_num                  int,
   @w_param                int, 
   @w_diff                 int,
   @w_date                 datetime,
   @w_bloqueo              char(1),
   @w_te_secuencial        int,
   @w_correo_a             varchar(254),
   @w_correo_d             varchar(254),
   @w_linked_s             varchar(32),
   @w_sp_local_name        varchar(30),
   @w_bdd                  varchar(32),
   @w_sp_linked_s          varchar(255),
   -- R214440-Sincronizacion automatica
   @w_sincroniza      char(1),
   @w_ofi_app         smallint


select @w_sp_name = 'sp_direccion_dml'
   
-------------- VERSIONAMIENTO DEL PROGRAMA -------------------------------------------
if @t_show_version = 1
begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.2')
  print  @w_sp_msg
  return 0
end
--------------------------------------------------------------------------------------

---- EJECUTAR SP DE LA CULTURA ---------------------------------------  
exec cobis..sp_ad_establece_cultura
        @o_culture = @s_culture out
        
        
select @w_estado_campo = null
select @w_iguales = 'S'

if @i_calle is not null
  select @i_calle = replace(replace(replace(@i_calle,' ','<>'),'><',''),'<>',' ') --MTA

if @i_descripcion is not null
  select @i_descripcion = replace(replace(replace(@i_descripcion,CHAR(9),''),CHAR(10),''),CHAR(13),' ') --GRO
  
-- MTA INICIO 
--PARA LA VERSION BASE DE PRODUCTO SE SETEA VALORES POR DEFECTO
if (@i_oficina is null) 
  select @i_oficina = @s_ofi 
   

if (@i_rural_urbano is null)
  select @i_rural_urbano = 'N'


--EVALUACION DEL TIPO DE TRANSACCION 
if (@t_trn <> 172016 and @i_operacion = 'I') or
   (@t_trn <> 172019 and @i_operacion = 'U') or
   (@t_trn <> 172021 and @i_operacion = 'D')
begin 
   select @w_error = 1720121
   goto ERROR_FIN
end
if @i_operacion in ('I', 'U', 'D')
begin
   /* VALIDACIONES LISTAS NEGRAS PARA EL CLIENTE */
   set @o_siguiente = 0
   select @o_dire = @o_siguiente
   select @o_siguiente
   if @i_ente is not null and @i_ente <> 0
   begin
      select @w_bloqueo = en_estado from cobis..cl_ente where en_ente = @i_ente
      if @w_bloqueo = 'S'
      begin
         select @w_error = 1720604
         goto ERROR_FIN
      end
   end 
end
if @i_operacion in ('I','U') 
begin
   if @i_negocio = 0 
   begin
      select @i_negocio = null
   end
   
   if(@i_tipo <> 'CE') begin
      if(@i_tipo_prop = 'OTR') begin
         if (@i_otro_tipo is null) begin
            select @w_error = 1720257
            goto ERROR_FIN
         end
         if (@i_referencias_dom is null) begin
            select @w_error = 1720258
            goto ERROR_FIN
         end 
       end

      if len(@i_otro_tipo) > 20 begin
         select @w_error = 1720259
         goto ERROR_FIN
      end

      if len(@i_localidad) > 20 begin
         select @w_error = 1720260
         goto ERROR_FIN
      end

      if len(@i_referencias_dom) > 255 begin
         select @w_error = 1720261
         goto ERROR_FIN
      end
   end
   
   if @i_define = 'S' and @i_cliente_casual <> 'S' begin
      if not exists ( select   pv_provincia from   cobis..cl_provincia where   pv_provincia = @i_provincia) and  @i_provincia is not null begin
         select @w_error = 1720110
         goto ERROR_FIN
      end 

      --VALIDA SI EXISTE PAIS
      if not exists (select 1 from cobis..cl_pais where pa_pais = @i_pais) and  @i_pais is not null begin
         select @w_error = 1720027
         goto ERROR_FIN
      end
      --FIN VALIDA PAIS

      -- VALIDA SI EXISTE CIUDAD-PROVINCIA --
      if not exists (select 1 from cobis..cl_ciudad, cobis..cl_provincia
                     where ci_provincia = pv_provincia  and   ci_ciudad    = @i_ciudad and   pv_provincia = @i_provincia) and  @i_ciudad is not null and  @i_provincia is not null begin
         select @w_error = 1720262
         goto ERROR_FIN
      end
      -- FIN VALIDA CIUDAD-PROVINCIA
    
      -- VALIDA SI EXISTE DEPARTAMENTO PARA PAIS --
      if not exists (select 1 from cobis..cl_depart_pais where dp_departamento = @i_departamento) and  @i_departamento is not null begin
         select @w_error = 1720110
         goto ERROR_FIN
      end
      -- FIN VALIDA DEPARTAMENTO

      -- VALIDA TIPO DE PROPIEDAD --                  
      if not exists (select 1 from cobis..cl_tabla t, cobis..cl_catalogo c 
                     where t.codigo = c.tabla and t.tabla = 'cl_tpropiedad' and c.codigo in (@i_tipo_prop)) and  @i_tipo_prop is not null begin
         select @w_error = 1720263 
         goto ERROR_FIN
      end
      -- FIN VALIDA TIPO DE PROPIEDAD

      -- VALIDA TIPO DE AREA RURAL/URBANO
      if not exists (select 1 from cobis..cl_tabla t, cobis..cl_catalogo c 
                     where t.codigo = c.tabla and  t.tabla = 'cl_sector' and   c.codigo in (@i_sector)) and  @i_sector is not null begin
         select @w_error = 1720264
         goto ERROR_FIN
      end
      -- FIN VALIDA TIPO AREA RURAL/URBANO

      -- VALIDA SI EXISTE DE CANTON
      if not exists (select 1 from cobis..cl_canton where ca_canton = @i_canton)  and  @i_canton is not null begin
         select @w_error = 1720265 
         goto ERROR_FIN
      end    
      -- FIN VALIDA CANTON
   end
   
    if not exists (select   of_oficina
                     from   cobis..cl_oficina
                    where   of_oficina = @i_oficina) and @i_oficina <> null
    begin
      select @w_error = 1720112
      goto ERROR_FIN
   end

   if (@i_tipo <> 'CE' and @i_tipo is not null) begin
      exec @w_return = cobis..sp_catalogo
      @t_debug       = @t_debug,
      @t_file        = @t_file,
      @t_from        = @w_sp_name,
      @i_tabla       = 'cl_tdireccion',
      @i_operacion   = 'E',
      @i_codigo      = @i_tipo

      if @w_return <> 0 begin
         select @w_error = 1720113
         goto ERROR_FIN
      end
   end
end

--INSERT
if @i_operacion = 'I' begin

   if @t_trn <> 172016 begin
       select @w_error = 1720075
       goto ERROR_FIN
   end

   --print N'VALIDACION VERIFICAR QUE NO EXISTA MAS DE UNA DIRECCION COMO PRINCIPAL NVR'
   --VERIFICAR QUE NO EXISTA MAS DE UNA DIRECCION COMO PRINCIPAL NVR
   if @i_principal = 'S' begin
      if exists (select di_ente from cobis..cl_direccion where  di_ente = @i_ente and di_principal = 'S') begin
         update cobis..cl_direccion
         set di_principal = 'N'
         where  di_ente      = @i_ente 
         and    di_principal = 'S' 
      end
   end
    
   -- VERIFICAR SI ES PERSONA NATURAL O JURIDICA
   --print N'VALIDACION VERIFICAR SI ES PERSONA NATURAL O JURIDICA'
   select @w_subtipo = en_subtipo from cobis..cl_ente where en_ente = @i_ente

   if @i_correspondencia ='S' begin
      if exists(select 1 from cobis..cl_direccion where di_ente=@i_ente and di_correspondencia='S')begin
         select @w_error = 1720266
         goto ERROR_FIN
      end
   end             

   if @i_negocio > 0 and exists(select 1 
                                from cobis..cl_direccion 
                                where di_ente = @i_ente 
                                and di_tipo = 'AE' 
                                and di_negocio = @i_negocio )
   begin
      select @w_error = 1720267 --'Error ya existe una direccion para este negocio'
      goto ERROR_FIN
   end

   begin tran
   --print N'SE ACTUALIZA CL_ENTE'
   update cobis..cl_ente
   set en_direccion = isnull(en_direccion,0) + 1
   where en_ente = @i_ente

   if @@error <> 0  begin
      select @w_error = 1720080
      goto ERROR_FIN
   end

   --print N'SE PASA AL SIGUIENTE'
   select @o_siguiente = (select isnull(max(di_direccion), 0) + 1 from cobis..cl_direccion
                           where di_ente = @i_ente)
    
   --print N'SE INSERTA LA DIRECCION'
   insert into cobis..cl_direccion(
   di_ente,                di_direccion,         di_descripcion,        di_parroquia,
   di_ciudad,              di_tipo,              di_telefono,           di_sector,
   di_zona,                di_oficina,           di_fecha_registro,     di_fecha_modificacion,
   di_vigencia,            di_verificado,        di_funcionario,        di_fecha_ver,
   di_principal,           di_barrio,            di_provincia,          di_codpostal, 
   di_casa,                di_calle,             di_pais,               di_codbarrio,
   di_correspondencia,     di_alquilada,         di_cobro,              di_otrasenas, 
   di_canton,              di_distrito,          di_montoalquiler,      di_so_igu_co,
   di_rural_urbano,        di_departamento,      di_fact_serv_pu,       di_tipo_prop,
   di_nombre_agencia,      di_tiempo_reside,     di_edificio,           di_nro_residentes,
   di_negocio,             di_poblacion,         di_referencias_dom,    di_otro_tipo,
   di_localidad,           di_conjunto,          di_piso,               di_numero_casa)
   values( 
   @i_ente,                @o_siguiente,         @i_descripcion,        @i_parroquia,
   @i_ciudad ,             @i_tipo,              0,                     @i_sector,
   @i_zona,                @i_oficina,           @s_date,               @s_date,
   'S',                    'N',                  @s_user,               null,
   @i_principal,           @i_barrio,            @i_provincia,          @i_codpostal, 
   @i_nro,                 @i_calle,             @i_pais,               @i_codbarrio,
   @i_correspondencia,     @i_alquilada,         @i_cobro,              @i_otrasenas, 
   @i_canton,              @i_distrito,          @i_montoalquiler,      @i_co_igual_so,
   @i_rural_urbano,        @i_departamento,      @i_fact_serv_pu,       @i_tipo_prop,
   @i_nombre_agencia,      @i_tiempo_reside,     @i_nro_interno,        @i_nro_residentes,
   @i_negocio,             @i_ci_poblacion,      @i_referencias_dom,    @i_otro_tipo,
   @i_localidad,           @i_conjunto,          @i_piso,               @i_numero_casa) 

   if @@error <> 0 begin
      select @w_error = 1720119
      goto ERROR_FIN
   end

   --Registro de la transaccion
   insert into cobis..ts_direccion (
   secuencial,         tipo_operacion,         clase,               fecha,
   usuario,            terminal,               srv,                 lsrv,
   ente,               direccion,              descripcion,         sector,  
   zona,               vigencia,               parroquia,           ciudad,
   tipo,               oficina,                verificado,          barrio, 
   provincia,          codpostal,              casa,                calle,
   pais,               correspondencia,        alquilada,           cobro,
   edificio,           departamento,           rural_urbano,        fact_serv_pu,
   tipo_prop,          nombre_agencia,         fuente_verif,        fecha_ver,
   hora,               reside,                 negocio,             referencias_dom,
   otro_tipo,          localidad,              tipo_transaccion)
   values
   (@s_ssn,            @i_operacion,           'N',                 @s_date,
   @s_user,            @s_term,                @s_srv,              @s_lsrv,
   @i_ente,            @o_siguiente,           @i_descripcion,      @i_sector,
   @i_zona,            'S',                    @i_parroquia,        @i_ciudad,
   @i_tipo,            @i_oficina,             'N',                 @i_barrio,
   @i_provincia,       @i_codpostal,           @i_nro,              @i_calle,
   @i_pais,            @i_correspondencia,     @i_alquilada,        @i_cobro,
   @i_nro_interno,     @i_departamento,        @i_rural_urbano,     @i_fact_serv_pu,
   @i_tipo_prop,       @i_nombre_agencia,      null,                null,
   getdate(),          @i_tiempo_reside,       @i_negocio,          @i_referencias_dom,
   @i_otro_tipo,       @i_localidad,           @t_trn)

   --ERROR EN CREACION DE TRANSACCION DE SERVICIO
   if @@error <> 0 begin
      select @w_error = 1720049
      goto ERROR_FIN
   end

   -- Actualizacion Automatica de Prospecto a Cliente
   if(@i_tipo <> 'CE')begin -- SI ES DIFERENTE A CORREO ELECTRONICO
      exec cobis..sp_seccion_validar
      @i_ente           = @i_ente,
      @i_operacion  = 'V',
      @i_seccion        = '3', --3 es Direcciones 
      @i_completado     = 'S'
   end

   --VERIFICAR SI EL CLIENTE TIENE TELEFONOS POR ASOCIAR A DIRECCION PRINCIPAL (PROCESO DE BURO)
   if @i_principal = 'S' begin
      update cobis..cl_telefono
      set   te_direccion = @i_direccion
      where te_ente      = @i_ente
      and   te_direccion = 0          --PROCESO BURO DEJA TELEFONOS CON DIRECCION 0

      if @@error <> 0 begin
         select @w_error = 1720206
         goto ERROR_FIN
      end
   end
   commit tran  

   select @o_dire = @o_siguiente
   select @o_siguiente

end

--UPDATE
if @i_operacion = 'U' begin
   if @t_trn <> 172019 begin
       select @w_error = 1720075
       goto ERROR_FIN
   end

   if not exists (select 1
                    from cl_direccion
                   where di_ente      = @i_ente
                     and di_direccion = @i_direccion) begin
      select @w_error = 1720115
      goto ERROR_FIN
   end

   if @i_ejecutar = 'N' begin
      --VERIFICAR QUE NO EXISTA MAS DE UNA DIRECCION COMO PRINCIPAL NVR
      if @i_principal = 'S' begin
         update cobis..cl_direccion
         set di_principal = 'N'
         where  di_ente      = @i_ente 
         and    di_principal = 'S'
         and    di_direccion <> @i_direccion
      end
      
      if @i_oficina is null
         select @i_oficina = @s_ofi

      if @i_correspondencia ='S' begin
         select @w_direccion_dc = di_direccion from cobis..cl_direccion where di_ente=@i_ente and di_correspondencia='S'
         if @@rowcount <>0
            if @w_direccion_dc <> @i_direccion begin
               select @w_error = 1720266
               goto ERROR_FIN
            end
      end
      
      --VALIDA QUE EXISTA SOLO UNA DIRECCION PRINCIPAL
      if @i_principal = 'S' begin
         if exists (select di_ente from cobis..cl_direccion 
                     where  di_ente      = @i_ente 
                     and    di_principal = 'S'
                     and    di_direccion != @i_direccion) begin
            update cobis..cl_direccion
            set di_principal = 'N'
            where  di_ente      = @i_ente 
            and    di_principal = 'S'
            and    di_direccion != @i_direccion
          end
      end
          
      if @t_trn = 172020 begin
         if @i_verificado <> 'S' and isnull(@i_verificado, 'N') <> 'N' begin
            select @w_error = 1720024
            goto ERROR_FIN
         end
      end      
   end         

   begin tran

   --Transaccion antes del cambio
   insert into cobis..ts_direccion (
   secuencial,         tipo_operacion,         clase,               fecha,
   usuario,            terminal,               srv,                 lsrv,
   ente,               direccion,              descripcion,         sector,  
   zona,               vigencia,               parroquia,           ciudad,
   tipo,               oficina,                verificado,          barrio, 
   provincia,          codpostal,              casa,                calle,
   pais,               correspondencia,        alquilada,           cobro,
   edificio,           departamento,           rural_urbano,        fact_serv_pu,
   tipo_prop,          nombre_agencia,         fuente_verif,        hora,               
   reside,             negocio,                referencias_dom,     otro_tipo,          
   localidad,          tipo_transaccion)
   select   
   @s_ssn,             @i_operacion,           'A',                 @s_date,
   @s_user,            @s_term,                @s_srv,              @s_lsrv,
   @i_ente,            @i_direccion,           di_descripcion,      di_sector,
   di_zona,            di_vigencia,            di_parroquia,        di_ciudad,
   di_tipo,            @s_ofi,                 di_verificado,       di_barrio,
   di_provincia,       di_codpostal,           di_casa,             di_calle,
   di_pais,            di_correspondencia,     di_alquilada,        di_cobro,
   di_edificio,        di_departamento,        di_rural_urbano,     di_fact_serv_pu,
   di_tipo_prop,       di_nombre_agencia,      di_fuente_verif,     getdate(),
   di_tiempo_reside,   di_negocio,             di_referencias_dom,  di_otro_tipo,
   di_localidad,       @t_trn
   from  cl_direccion
   where di_ente    =   @i_ente
   and di_direccion =   @i_direccion

   --ERROR EN CREACION DE TRANSACCION DE SERVICIO
   if @@error <> 0 begin
      select @w_error = 1720049
      goto ERROR_FIN
   end

   -- BM Sincronización de medios
   select @w_correo_a = isnull(di_descripcion,'') 
     from cobis..cl_direccion 
    where di_ente      = @i_ente
      and di_direccion = @i_direccion 
      and di_tipo      = 'CE'  

   --inicia la actualizacion
   update  cobis..cl_direccion  set  
   di_verificado         = isnull(@i_verificado, 'N' ),
   di_fecha_ver          = case @i_verificado when 'S' then @s_date else null end,  
   di_funcionario        = @s_user, 
   di_descripcion        = @i_descripcion,
   di_tipo               = isnull(@i_tipo, di_tipo),
   di_parroquia          = isnull(@i_parroquia,  di_parroquia),
   di_barrio             = isnull(@i_barrio, di_barrio),
   di_canton             = isnull(@i_canton,di_canton ),
   di_sector             = @i_sector,
   di_principal          = isnull(@i_principal,di_principal ),
   di_vigencia           = 'S',
   di_oficina            = isnull(@i_oficina, di_oficina),
   di_zona               = isnull(@i_zona, di_zona),
   di_provincia          = isnull(@i_provincia, di_provincia),
   di_codpostal          = @i_codpostal,
   di_calle              = isnull(@i_calle, di_calle),
   di_casa               = isnull(@i_nro,di_casa ),
   di_pais               = isnull(@i_pais,  di_pais),
   di_codbarrio          = isnull(@i_codbarrio, di_codbarrio),
   di_correspondencia    = isnull(@i_correspondencia,  di_correspondencia),
   di_alquilada          = isnull(@i_alquilada, di_alquilada ),
   di_cobro              = isnull(@i_cobro, di_cobro),
   di_otrasenas          = isnull(@i_otrasenas, di_otrasenas),
   di_distrito           = isnull(@i_distrito, di_distrito),
   di_montoalquiler      = isnull(@i_montoalquiler, di_montoalquiler),
   di_edificio           = isnull(@i_nro_interno, ' '),
   di_ciudad             = isnull(@i_ciudad, di_ciudad),
   di_so_igu_co          = isnull(@i_co_igual_so, di_so_igu_co),
   di_rural_urbano       = isnull(@i_rural_urbano, di_rural_urbano),
   di_departamento       = isnull(@i_departamento, di_departamento),
   di_fact_serv_pu       = isnull(@i_fact_serv_pu, di_fact_serv_pu),
   di_tipo_prop          = isnull(@i_tipo_prop, di_tipo_prop),
   di_nombre_agencia     = isnull(@i_nombre_agencia,di_nombre_agencia),
   di_fuente_verif       = isnull(@i_fuente_verif,di_fuente_verif),
   di_fecha_modificacion = @s_date,
   di_tiempo_reside      = isnull(@i_tiempo_reside,di_tiempo_reside),
   di_nro_residentes     = isnull(@i_nro_residentes,di_nro_residentes),
   di_negocio            = isnull(@i_negocio,di_negocio),
   di_poblacion          = isnull(@i_ci_poblacion,di_poblacion),
   di_referencias_dom    = isnull(@i_referencias_dom,di_referencias_dom),
   di_otro_tipo          = isnull(@i_otro_tipo,di_otro_tipo),
   di_localidad          = @i_localidad,
   di_conjunto           = @i_conjunto,
   di_piso               = @i_piso,
   di_numero_casa        = @i_numero_casa
   where di_ente         = @i_ente
   and   di_direccion    = @i_direccion

   if @@error <> 0 begin
      select @w_error = 1720080
      goto ERROR_FIN
   end
                                            
   --VERIFICAR SI EL CLIENTE TIENE TELEFONOS POR ASOCIAR A DIRECCION PRINCIPAL (PROCESO DE BURO)
   if @i_principal = 'S' begin
      update cobis..cl_telefono
      set   te_direccion = @i_direccion
      where te_ente      = @i_ente
      and   te_direccion = 0              --Proceso BURO deja telefonos con direccion 0

      if @@error <> 0 begin
         select @w_error = 1720206
         goto ERROR_FIN
      end
   end
   
   --Transaccion despues del cambio
   insert into cobis..ts_direccion (
   secuencial,         tipo_operacion,         clase,               fecha,
   usuario,            terminal,               srv,                 lsrv,
   ente,               direccion,              descripcion,         sector,  
   zona,               vigencia,               parroquia,           ciudad,
   tipo,               oficina,                verificado,          barrio, 
   provincia,          codpostal,              casa,                calle,
   pais,               correspondencia,        alquilada,           cobro,
   edificio,           departamento,           rural_urbano,        fact_serv_pu,
   tipo_prop,          nombre_agencia,         fuente_verif,        hora,               
   reside,             negocio,                referencias_dom,     otro_tipo,          
   localidad,          tipo_transaccion)
   select   
   @s_ssn,             @i_operacion,           'D',                 @s_date,
   @s_user,            @s_term,                @s_srv,              @s_lsrv,
   @i_ente,            @i_direccion,           di_descripcion,      di_sector,
   di_zona,            di_vigencia,            di_parroquia,        di_ciudad,
   di_tipo,            @s_ofi,                 di_verificado,       di_barrio,
   di_provincia,       di_codpostal,           di_casa,             di_calle,
   di_pais,            di_correspondencia,     di_alquilada,        di_cobro,
   di_edificio,        di_departamento,        di_rural_urbano,     di_fact_serv_pu,
   di_tipo_prop,       di_nombre_agencia,      di_fuente_verif,     getdate(),
   di_tiempo_reside,   di_negocio,             di_referencias_dom,  di_otro_tipo,
   di_localidad,       @t_trn
   from  cl_direccion
   where di_ente    =   @i_ente
   and di_direccion =   @i_direccion

   --ERROR EN CREACION DE TRANSACCION DE SERVICIO
   if @@error <> 0 begin
      select @w_error = 1720049
      goto ERROR_FIN
   end

   commit tran

   -- BM Sincronización de medios
   select @w_correo_d = isnull(di_descripcion,'')
     from cobis..cl_direccion 
    where di_ente      = @i_ente
      and di_direccion = @i_direccion 
      and di_tipo      = 'CE'

    if (@w_correo_a  <> @w_correo_d)
    begin 
        select @w_sp_local_name = 'sp_itf_act_menvio',
               @w_bdd           = 'cob_bvirtual'
        select @w_linked_s      = pa_char from cobis..cl_parametro where pa_nemonico = 'SRVL' and pa_producto = 'BVI'
        select @w_sp_linked_s   = '[' + @w_linked_s + '].[' + @w_bdd + '].[dbo].[' + @w_sp_local_name + ']'        
        
        exec @w_sp_linked_s
             @t_trn      = 18580,
             @i_ente_mis = @i_ente,
             @i_modo     = 'CE',
             @i_mail     = @i_descripcion,
             @i_celular  = '',
             @i_origen   = 'CLI',
             @s_srv      = @s_srv,
             @s_user     = @s_user ,
             @s_term     = @s_term,
             @s_ofi      = @s_ofi,
             @s_ssn      = @s_ssn,
             @s_lsrv     = @s_lsrv,
             @s_date     = @s_date,
             @s_sesn     = @s_ssn
    end  
      
end

--DELETE
if @i_operacion = 'D' begin

   if @t_trn <> 172021 begin
       select @w_error = 1720075
       goto ERROR_FIN
   end

   if exists (select 1 from cobis..cl_direccion where di_ente = @i_ente and di_direccion = @i_direccion and di_negocio is not null and di_negocio <> 0)
   begin
      select @w_error = 1720547
      goto ERROR_FIN
   end
   
   --VERIFICACION DE CLAVES FORANEAS
   if not exists (select en_ente from cobis..cl_ente where en_ente = @i_ente) begin
       select @w_error = 1720109
       goto ERROR_FIN
   end
   
   if not exists (select 1
                    from cl_direccion
                   where di_ente      = @i_ente
                     and di_direccion = @i_direccion) begin
      select @w_error = 1720115
      goto ERROR_FIN
   end

   if ( select count (dp_direccion_ec)  from  cobis..cl_cliente, cobis..cl_det_producto  
        where cl_cliente      = @i_ente 
        and   cl_det_producto = dp_det_producto  
        and   dp_direccion_ec = @i_direccion) > 0 begin
      --print 'NO SE PUEDE ELIMINAR DIRECCION YA QUE SE ENCUENTRA REFERENCIADA POR UN PRODUCTO'
      select @w_error = 1720124
      goto ERROR_FIN
   end
   
   --EVITAR ELIMINAR LAS DIRECCIONES PRINCIPALES NVR
   select @w_principal = di_principal 
   from cobis..cl_direccion 
   where  di_ente      = @i_ente
   and    di_direccion = @i_direccion

   if @w_principal ='S' begin
      select @w_error = 1720624
      goto ERROR_FIN 
   end

   begin tran
   
   update cobis..cl_ente
   set   en_direccion = en_direccion - 1
   where en_ente      = @i_ente
   
   if @@error <> 0 begin
      select @w_error = 1720125
      goto ERROR_FIN
   end

   select @w_codigo = di_telefono from cobis..cl_direccion
   where di_ente = @i_ente
   and di_direccion = @i_direccion

   --ELIMINACION DE TODOS LOS TELEFONOS DE LA DIRECCION
   if @w_codigo > 0 begin   
    declare cursor_telefono cursor read_only 
    for select te_secuencial from cobis..cl_telefono 
         where te_ente          =   @i_ente
           and te_direccion     =   @i_direccion
    open cursor_telefono
    fetch next from cursor_telefono into @w_te_secuencial
    
    while @@fetch_status = 0
    begin     
      exec @w_return = cobis..sp_telefono 
      @s_ssn          =    @s_ssn, 
      @s_user         =    @s_user,
      @s_term         =    @s_term,
      @s_date         =    @s_date,
      @s_srv          =    @s_srv,
      @s_lsrv         =    @s_lsrv,
      @s_ofi          =    @s_ofi,
      @s_rol          =    @s_rol,
      @s_org_err      =    @s_org_err,
      @s_error        =    @s_error,
      @s_sev          =    @s_sev,
      @s_msg          =    @s_msg,
      @s_org          =    @s_org,
      @t_debug        =    @t_debug,
      @t_file         =    @t_file,
      @t_from         =    @t_from,
      @t_trn          =    172034,
      @p_alterno      =    @w_codigo,
      @i_operacion    =    'D', 
      @i_ente         =    @i_ente, 
      @i_direccion    =    @i_direccion, 
      @i_secuencial   =    @w_te_secuencial,
      @i_tborrado     =    'T'      -- SIGNIFICA QUE SE VAN A BORRAR TODOS LOS TELEFONOS ASOCIADOS A LA DIR.

      if @w_return <> 0 
      begin
         close cursor_telefono
         deallocate cursor_telefono
         return @w_return      
      end    
      fetch next from cursor_telefono into @w_te_secuencial
    end
    close cursor_telefono
    deallocate cursor_telefono    
   end--IF

   if exists(select 1 from cobis..cl_direccion_geo 
             where dg_ente      = @i_ente
             and   dg_direccion = @i_direccion) begin
      -- ELIMINAR REGISTROS GEOREFERENCIACION
         exec @w_return = cobis..sp_direccion_geo
         @s_ssn          = @s_ssn,
         @s_date         = @s_date,
         @i_operacion    = 'D',
         @t_trn          = 172021,
         @i_ente         = @i_ente,
         @i_direccion    = @i_direccion
         
         if @w_return <> 0 begin
            select @w_error = 1720371
            goto ERROR_FIN 
         end
   end

   --Transaccion despues del cambio
   insert into cobis..ts_direccion (
   secuencial,         tipo_operacion,         clase,               fecha,
   usuario,            terminal,               srv,                 lsrv,
   ente,               direccion,              descripcion,         sector,  
   zona,               vigencia,               parroquia,           ciudad,
   tipo,               oficina,                verificado,          barrio, 
   provincia,          codpostal,              casa,                calle,
   pais,               correspondencia,        alquilada,           cobro,
   edificio,           departamento,           rural_urbano,        fact_serv_pu,
   tipo_prop,          nombre_agencia,         fuente_verif,        hora,               
   reside,             negocio,                referencias_dom,     otro_tipo,          
   localidad,          tipo_transaccion)
   select   
   @s_ssn,             @i_operacion,           'E',                 @s_date,
   @s_user,            @s_term,                @s_srv,              @s_lsrv,
   @i_ente,            @i_direccion,           di_descripcion,      di_sector,
   di_zona,            di_vigencia,            di_parroquia,        di_ciudad,
   di_tipo,            @s_ofi,                 di_verificado,       di_barrio,
   di_provincia,       di_codpostal,           di_casa,             di_calle,
   di_pais,            di_correspondencia,     di_alquilada,        di_cobro,
   di_edificio,        di_departamento,        di_rural_urbano,     di_fact_serv_pu,
   di_tipo_prop,       di_nombre_agencia,      di_fuente_verif,     getdate(),
   di_tiempo_reside,   di_negocio,             di_referencias_dom,  di_otro_tipo,
   di_localidad,       @t_trn
   from  cl_direccion
   where di_ente    =   @i_ente
   and di_direccion =   @i_direccion

   if @@error <> 0 begin
   --ERROR EN CREACION DE TRANSACCION DE SERVICIO
      select @w_error = 1720049
      goto ERROR_FIN
   end

   --ELIMINACION DE LA DIRECCION
   delete from cobis..cl_direccion
   where di_ente      = @i_ente
   and   di_direccion = @i_direccion

   if @@error <> 0 begin
      select @w_error = 1720125
      goto ERROR_FIN 
   end

   commit tran
      
end

if @i_operacion = 'N' --asociar direccion de negocio o domicilio existentes a un negocio
begin
    --VERIFICAR SI LA DIRECCION SELECCIONADA EXISTE
    if not exists(select 1 from cl_direccion where di_ente = @i_ente and di_tipo in ('AE','RE'))
    begin
        select @w_error = 1720115 --NO EXISTE DIRECCION 
        goto ERROR_FIN
    end
    
    select @w_negocio_actual = di_negocio from cl_direccion where di_ente = @i_ente and di_tipo in ('AE','RE') and di_direccion = @i_direccion
    
    select @w_direccion_anterior = di_direccion from cl_direccion where di_ente = @i_ente and di_tipo in ('AE','RE') and di_negocio = @i_negocio
    
    --VERIFICAR SI LA DIRECCION SELECCIONADA NO HA SIDO ASIGNADA A OTRO NEGOCIO
    if exists (select 1 from cl_direccion 
               where di_ente = @i_ente 
               and di_tipo in ('AE','RE') 
               and di_direccion = @i_direccion 
               and di_negocio is not null 
               and di_negocio <> 0
               and @i_desasociar_dir <> 'S' 
               and @w_negocio_actual <> @i_negocio)
    begin
        select @w_error = 1720545 --LA DIRECCION SELECCIONADA YA HA SIDO ASIGNADA A OTRO NEGOCIO 
        goto ERROR_FIN
    end
    
    begin tran
    
    if @i_negocio is not null and @i_negocio > 0
    begin
        if @i_desasociar_dir = 'S'
        begin
            update cl_direccion
               set di_negocio = null
            where di_ente         = @i_ente
            and   di_direccion    = @w_direccion_anterior
            and   di_tipo in ('AE','RE')
            
        end
        else
        begin
            if @w_direccion_anterior <> @i_direccion
            begin
                update cl_direccion
                set di_negocio = null
                where di_ente         = @i_ente
                    and   di_direccion    = @w_direccion_anterior
                    and   di_tipo in ('AE','RE')
            end
            
            update cl_direccion
            set di_negocio = @i_negocio
            where di_ente         = @i_ente
                and   di_direccion    = @i_direccion
                and   di_tipo in ('AE','RE')
        end
        
        if @@error <> 0 begin
            select @w_error = 1720080
            goto ERROR_FIN
        end
        
        --se almacena la informacion posterior a la actualizacion
       exec @w_return    = sp_registrar_cambios
            @i_operacion = 'D',
            @i_tipo_trn  = 'U',
            @i_tabla     = 'cl_direccion',
            @i_llave1    = 'di_ente',
            @i_campo1    = @i_ente,
            @i_llave2    = 'di_direccion',
            @i_campo2    = @i_direccion
       if @w_return <> 0 begin
       --ERROR EN CREACION DE TRANSACCION DE SERVICIO
          select @w_error = 1720049
          goto ERROR_FIN
       end
    end
    commit tran
    return 0
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
if @i_operacion in ('I', 'U', 'D') and @i_ente is not null and @w_sincroniza = 'S' and @s_ofi <> @w_ofi_app
begin
   exec @w_error = cob_sincroniza..sp_sinc_arch_json
      @i_opcion     = 'I',
      @i_cliente    = @i_ente,
      @t_debug      = @t_debug
end

return 0

ERROR_FIN:
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

