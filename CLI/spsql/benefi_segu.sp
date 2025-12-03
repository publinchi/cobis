/********************************************************************/
/*    NOMBRE LOGICO:        sp_beneficiario_seguro                  */
/*    NOMBRE FISICO:        benefi_segu.sp                          */
/*    PRODUCTO:             CLIENTES                                */
/*    Disenado por:         ALD                                     */
/*    Fecha de escritura:   30/Abril019                             */
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
/*   y penales en contra del infractor según corresponda.”.         */
/********************************************************************/
/*                              PROPOSITO                           */
/*    Programa que consulta, inserta y borrar registros de la tabla */
/*    cl_beneficiario_seguro                                        */
/********************************************************************/
/*                          MODIFICACIONES                          */
/*  FECHA           AUTOR                 RAZON                     */
/*  30/Abril/2019   ALD        Versión Inicial Te Creemos           */
/*  07/Junio/2019   JES        Parametrp para la APP Movil          */
/*  07/Junio/2019   RIGG       Agregar parámetro @i_tramite         */
/*  28/Junio/2019   FBO        Validacion de origen                 */
/*  24/Julio/2019   RIGG       Agregar validación de existen benef  */
/*  08/Agost/2019   JFES       Localidades de beneficiarios         */
/*  28/Agost/2019   JTO        Cambio de num operacion por tranmite */
/*                             para el origen O y M                 */
/*  30/Agost/2019   JTO        Insert bs_nro_operacion=(tramite -1) */
/*  18/Oct/2019     RIGG       Agregar validacion de fecha min y max*/
/*  09/Ene/2020     EJS        Benef CTA, CCA Y CRE CLI-B308077-TEC */
/*  26/Jun/2020     FSAP       Estandarizacion clientes             */
/*  04/Ago/2021     JMV        Beneficiarios por seguro             */
/*  18/Feb/2022     pmoreno    Ajuste consulta % total seguros      */
/*  19/Abr/2023     EBA        Ajuste consulta beneficiarios        */
/*  07/09/2023      BDU        R214440-Sincronizacion automatica    */
/*  22/01/2024      BDU        R224055-Validar oficina app          */
/********************************************************************/

use cobis
go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

if exists (select * from sysobjects where name = 'sp_beneficiario_seguro')
   drop proc sp_beneficiario_seguro
go

create proc sp_beneficiario_seguro(
        @s_user                 login          = NULL,
        @s_term                 char(20)       = NULL,
        @s_date                 datetime       = NULL,
        @s_ofi                  smallint       = NULL,
        @t_debug                char(1)        = 'N',
        @t_file                 varchar(10)    = NULL,
        @t_trn                  int            = 172081,                           --26/MAR/2019 A ORBES VERSION CLOUD
        @t_show_version         bit            = 0,
        @i_operacion            char(1)        = NULL,
        @i_nro_operacion        int            = NULL,
        @i_producto             smallint       = 1,
        @i_tipo_id              varchar(10)    = NULL,
        @i_ced_ruc              varchar(32)    = NULL,
        @i_nombres              varchar(100)   = NULL,
        @i_apellido_p           varchar(60)    = NULL,
        @i_apellido_m           varchar(60)    = NULL,
        @i_porcentaje           float          = 0.00,
        @i_parentesco           varchar(10)    = NULL,
        @i_secuencia            smallint       = NULL,
        @i_ente                 int            = NULL,
        @i_fecha_nac            datetime       = NULL,
        @i_telefono             varchar(20)    = NULL,
        @i_direccion            varchar(70)    = NULL,
        @i_provincia            smallint       = NULL,
        @i_ciudad               smallint       = NULL,
        @i_parroquia            int            = NULL,
        @i_modo                 tinyint        = NULL,
        @i_siguiente            int            = NULL,
        @i_banco                cuenta         = NULL,
        @i_siguiente1           int            = NULL,
        @i_debugger             varchar(20)    = NULL,
        @i_formato_fecha        smallint       = NULL,
        @i_codpostal            char(5)        = NULL,
        @i_apertura             char(1)        = 'N',       --CBE S es apertura N no es apertura
        @i_ambos_seguros        varchar(1)     = NULL,
        @i_localidad            varchar(20)    = null,
        @i_origen               char(1)        = NULL,      -- O:ORIGINADOR, M:APP_MOVIL, R:REPORTE(ORIGINADOR,CARTERA)
        @o_secuencial           smallint       = NULL out,
        @i_tramite              int            = NULL,
        @i_seguro               catalogo       =   null,
        @i_modulo               char(3)        = 'AHO'
)
as
declare @w_sp_name              varchar(32),
        @w_sp_msg               varchar(132),
        @w_return               int,
        @w_operacionca          int,
        @w_error                int,
        @w_extra                char(1),
        @w_fecha_aux            datetime,
        @w_provincia            smallint,
        @w_ciudad               smallint,
        @w_parroquia            int,
        @w_fecha_proceso        datetime,
        @w_porcentaje           float,
        @w_secuencial           smallint,
        @w_producto             smallint,
        @w_msg                  varchar(1000),
        @w_tabla_cod            smallint,
        @w_unir                 char(1),
        @w_total                float,
        @w_fecha_nac            int,
        @w_fech_max             int,
        @w_fech_min             int,
        -- R214440-Sincronizacion automatica
        @w_sincroniza      char(1),
        @w_ente_sinc       int,
        @w_ofi_app         smallint

/* Captura nombre de Stored Procedure  */
select   @w_sp_name = 'sp_beneficiario_seguro'

/*--VERSIONAMIENTO--*/
if @t_show_version = 1
begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end

/* Se lee fecha de proceso */
select @w_fecha_proceso = fp_fecha from ba_fecha_proceso


if @i_operacion = 'I'
begin

      if @i_origen = 'M' -- EL MOVIL ESTA ENVIANDO LA INSTANCIA DE PROCESO EN EL CAMPO @i_nro_operacion
      begin
         select @i_tramite       = io_campo_3,
                @i_nro_operacion = 0   -- JTO 28/08/2019 SE USA EL TRAMITE Y EL NUMERO DE OPERACION PASA A SER 0
         from   cob_workflow..wf_inst_proceso
         where  io_id_inst_proc  = @i_nro_operacion
      end

      if @i_origen in ('M','O')
      begin
          if exists (select 1 from cl_beneficiario_seguro
                      where bs_tramite = @i_tramite   -- JTO 28/08/2019 SE USA EL NUMERO DE TRAMITE
                        and bs_producto = @i_producto)
             select @w_secuencial = max(bs_secuencia)
               from cl_beneficiario_seguro
              where bs_tramite = @i_tramite   -- JTO 28/08/2019 SE USA EL NUMERO DE TRAMITE
                and bs_producto = @i_producto
          else
             select @w_secuencial = 0
      end
      else
      begin
          if exists (select 1 from cl_beneficiario_seguro
                      where bs_nro_operacion = @i_nro_operacion
                        and bs_producto = @i_producto)
             select @w_secuencial = max(bs_secuencia)
               from cl_beneficiario_seguro
              where bs_nro_operacion = @i_nro_operacion
                and bs_producto = @i_producto
          else
             select @w_secuencial = 0
      end
      set @w_secuencial = @w_secuencial + 1

      if @i_provincia is not null
      begin
         if not exists (select
                        pv_provincia
                        from   cl_provincia
                        where  pv_provincia = @i_provincia)
         begin
               select
                 @w_return = 1720110
                 goto ERROR_FIN
               /* 'No existe provincia'*/
         end
      end

      if @i_ciudad is not null
      begin
          if not exists (select
                         ci_ciudad
                         from   cl_ciudad
                         where  ci_ciudad = @i_ciudad)
          begin
               select
                 @w_return = 1720028
               goto ERROR_FIN
               /* 'No existe ciudad'*/
          end
      end

      if @i_parroquia is not null
      begin
          if not exists (select
                         pq_parroquia
                         from   cl_parroquia
                         where  pq_parroquia = @i_parroquia)
          begin
               select
                 @w_return = 1720312
               goto ERROR_FIN
             /* 'No existe parroquia'*/
          end
      end

      if isnull(@i_fecha_nac, '01/01/1900') > @w_fecha_proceso
      begin
            select
              @w_return = 1720313
            goto ERROR_FIN
            /* Fecha de nacimiento invalida*/
      end

      set @w_porcentaje = round(@i_porcentaje, 2)
      if @w_porcentaje > convert(float,100.0)
      begin
            select
              @w_return = 1720314

            goto ERROR_FIN
            /* Porcentaje invalido */
      end

      if @w_secuencial > 1
      begin
          if @i_origen in ('M','O')
          begin
                select @w_total = sum(bs_porcentaje)
                  from cl_beneficiario_seguro
                 where bs_tramite = @i_tramite --JTO 30/08/2019 USO DEL NUMERO DE TRAMITE EN LUGAR DEL DE OPERACION
                   and bs_producto = @i_producto
                   and bs_seguro = @i_seguro
          end
          else
          begin
                select @w_total = sum(bs_porcentaje)
                  from cl_beneficiario_seguro
                 where bs_nro_operacion = @i_nro_operacion
                   and bs_producto = @i_producto
                   and bs_tramite is null
          end
          select @w_total = @w_total + @i_porcentaje
          if @w_total > convert(float,100.0)
          begin
                   select
                      @w_return = 1720314

                   goto ERROR_FIN
                   /* Porcentaje invalido */
          end
      end

      if @i_ente is not null
      begin
           if not exists(select en_ente
                            from cl_ente
                            where en_ente = @i_ente)
           begin
                    select
                    @w_return = 1720315
                    goto ERROR_FIN
                    /* 'No existe ente'*/
           end
      end

       if @i_parentesco is not null
       begin
             exec @w_return = cobis..sp_catalogo
                  @t_debug     = @t_debug,
                  @t_file      = @t_file,
                  @t_from      = @w_sp_name,
                  @i_tabla     = 'cl_parentesco_beneficiario',
                  @i_operacion = 'E',
                  @i_codigo    = @i_parentesco
             if @w_return <> 0
             begin
                   select
                      @w_return = 1720316
                   goto ERROR_FIN
             end
       end

       if exists(select 1 from cobis..cl_beneficiario_seguro
                           where bs_nombres = trim(@i_nombres)
                           and bs_apellido_paterno = trim(@i_apellido_p)
                           and bs_apellido_materno = trim(@i_apellido_m)
                           and bs_fecha_nac = @i_fecha_nac
                           --and bs_nro_operacion = @i_nro_operacion
                           and (CASE when (@i_nro_operacion = 0 and bs_tramite = @i_tramite) then 1
                                when bs_nro_operacion = @i_nro_operacion then 1
                                else 0 end) = 1   -- JTO 28/08/2019 SI @i_nro_operacion = 0 y si existe el tramite o si existe el numero de operacion da respuesta 1 correcto caso contrario 0 no correcto
                           and bs_producto = @i_producto
                           and bs_ente = @i_ente )
       begin
            exec cobis..sp_cerror
              @t_debug = @t_debug,
              @t_file  = @t_file,
              @t_from  = @w_sp_name,
              @i_num   = 1720317
            return 1720317
       end

       if @i_seguro is not null
       begin
           if not exists(select codigo from cobis..cl_catalogo where tabla in (select codigo from cobis..cl_tabla where tabla = 'cr_tipos_seguro')and valor = @i_seguro)
                                                                
            begin
                exec cobis..sp_cerror
                  @t_debug = @t_debug,
                  @t_file  = @t_file,
                  @t_from  = @w_sp_name,
                  @i_num   = 1720318
                return 1720318
            end
       end

       if @i_fecha_nac is not null
       begin
            select @w_fecha_nac =  DATEDIFF(yy, @i_fecha_nac, getdate());

            select @w_fech_min =  pa_int
              from cobis..cl_parametro 
             where pa_producto = 'CLI'    --FSAP complementa query
               and pa_nemonico in ('MINBEN')

            select @w_fech_max =  pa_int
              from cobis..cl_parametro 
             where pa_producto = 'CLI'     --FSAP complementa query
               and pa_nemonico in ('MAXBEN')

            if (@w_fecha_nac < @w_fech_min or @w_fecha_nac > @w_fech_max)
            begin
                  exec cobis..sp_cerror
                  @t_debug = @t_debug,
                  @t_file  = @t_file,
                  @t_from  = @w_sp_name,
                  @i_num   = 1720319     ------NO SE CONTINUA EL PROCESO PORQUE LA EDAD NO CORRESPONDE
                  return 1720319
            end
       end

       begin tran

       insert into cl_beneficiario_seguro (
                   bs_nro_operacion, bs_producto, bs_tipo_id,
                   bs_ced_ruc, bs_nombres, bs_apellido_paterno,
                   bs_apellido_materno, bs_porcentaje, bs_parentesco,
                   bs_secuencia, bs_ente, bs_fecha_mod,
                   bs_fecha_nac, bs_telefono, bs_direccion,
                   bs_provincia, bs_ciudad, bs_parroquia, bs_codpostal, bs_ambos_seguros,bs_localidad,bs_tramite,bs_seguro)
              values ((case when @i_nro_operacion = 0 or @i_nro_operacion is null then (@i_tramite * -1) else @i_nro_operacion end), @i_producto, @i_tipo_id,   -- JTO 30/08/2019 PARA EVITAR EL CONSTRAINT POR INGRESAR OPERACION EN 0 SE INGRESARA EL NEGATIVO DEL TRAMITE
                   @i_ced_ruc, @i_nombres, @i_apellido_p,
                   @i_apellido_m, @w_porcentaje, @i_parentesco,
                   @w_secuencial, @i_ente, @w_fecha_proceso,
                   @i_fecha_nac,  @i_telefono, @i_direccion,
                   @i_provincia, @i_ciudad, @i_parroquia, @i_codpostal, @i_ambos_seguros,@i_localidad,@i_tramite,@i_seguro)  -- JTO 30/08/2019 USO DE TRAMITE EN LUGAR DE OPERACION

       if @@error <> 0
       begin
           select
             @w_return = 1720320
           goto ERROR_FIN
           /* 'Error en creacion de registro'*/
       end

       set @o_secuencial = @w_secuencial

       commit tran
end --@i_operacion = 'I'

if @i_operacion = 'A'
begin
      select @w_tabla_cod = b.codigo
        from cl_catalogo a, cl_tabla b
       where b.tabla = 'cl_parentesco_beneficiario'
         and a.tabla = b.codigo
        group by b.codigo

      if (@i_formato_fecha is null OR @i_formato_fecha = 0)
      begin
        select @i_formato_fecha = pa_int 
        from cobis..cl_parametro 
        where pa_nemonico = ('FFEC') and pa_producto = 'PAM'
      end
      
      if @i_origen in ('M','R') -- EL MOVIL y LOS REPORTES(ORIGINACION y CARTERA) ESTA ENVIANDO LA INSTANCIA DE PROCESO EN EL CAMPO @i_nro_operacion
      begin
         select @i_tramite = io_campo_3  -- JTO 29/08/2019 SE USA EL NUMERO DE TRAMITE
         from   cob_workflow..wf_inst_proceso
         where  io_id_inst_proc  = @i_nro_operacion
      end

      if @i_origen in ('M','O','R')
      begin
          select
             'OPERACION'   = bs_nro_operacion,
             'PRODUCTO'    = bs_producto,
             'SECUENCIA'   = bs_secuencia,
             'TIPO ID.'    = bs_tipo_id,
             'ID.'         = bs_ced_ruc,
             'NOMBRE'      = bs_nombres + ' ' + bs_apellido_paterno +  ' ' + bs_apellido_materno,
             'PORCENTAJE'  = bs_porcentaje,
             'PARENTESCO'  = bs_parentesco + ' - ' + valor,
             'ENTE'        = ISNULL(bs_ente,0),
             'FECHA NAC.'  = convert(varchar(10),bs_fecha_nac,@i_formato_fecha),
             'TELEFONO'    = bs_telefono,
             'DIRECCION'   = bs_direccion + ' ' + pq_descripcion + ' ' + ci_descripcion + ' ' + pv_descripcion + ' CP ' + isnull(bs_codpostal, '-'),
             'CNOMBRE'      = bs_nombres,
             'CAPELLIDOP'   = bs_apellido_paterno,
             'CAPELLIDOS'   = bs_apellido_materno,
             'CPARENTESCO'  = bs_parentesco,
             'CDIRECCION'   = bs_direccion,
             'CCODPOSTAL'   = bs_codpostal,
             'CPROVINCIA'   = bs_provincia,
             'CCIUDAD'      = bs_ciudad,
             'CPARROQUIA'   = bs_parroquia,
             'AMBOS SEGUROS'= bs_ambos_seguros,
             'TRAMITE'      = bs_tramite,
             'SEGURO'       = bs_seguro,
             'SEGURO'       = null,
             'LOCALIDAD'    = bs_localidad
          from cl_beneficiario_seguro a
          INNER JOIN cl_catalogo e ON e.codigo = a.bs_parentesco AND e.tabla = @w_tabla_cod
          LEFT JOIN cl_provincia b ON b.pv_provincia = a.bs_provincia
          LEFT JOIN cl_ciudad c ON c.ci_ciudad = bs_ciudad
          LEFT JOIN cl_parroquia d ON d.pq_parroquia = bs_parroquia
          where bs_tramite  = @i_tramite     -- JTO 28/08/2019 SE USA EL NUMERO DE TRAMITE
          and   bs_producto = @i_producto
          and   bs_seguro   = @i_seguro
          order by bs_secuencia
      end
      else
      begin
          select
             'OPERACION'   = bs_nro_operacion,
             'PRODUCTO'    = bs_producto,
             'SECUENCIA'   = bs_secuencia,
             'TIPO ID.'    = bs_tipo_id,
             'ID.'         = bs_ced_ruc,
             'NOMBRE'      = bs_nombres + ' ' + bs_apellido_paterno +  ' ' + bs_apellido_materno,
             'PORCENTAJE'  = bs_porcentaje,
             'PARENTESCO'  = bs_parentesco + ' - ' + valor,
             'ENTE'        = ISNULL(bs_ente,0),
             'FECHA NAC.'  = convert(varchar(10),bs_fecha_nac,@i_formato_fecha),
             'TELEFONO'    = bs_telefono,
             'DIRECCION'   = bs_direccion + ' ' + pq_descripcion + ' ' + ci_descripcion + ' ' + pv_descripcion + ' CP ' + isnull(bs_codpostal, '-'),
             'CNOMBRE'      = bs_nombres,
             'CAPELLIDOP'   = bs_apellido_paterno,
             'CAPELLIDOS'   = bs_apellido_materno,
             'CPARENTESCO'  = bs_parentesco,
             'CDIRECCION'   = bs_direccion,
             'CCODPOSTAL'   = bs_codpostal,
             'CPROVINCIA'   = bs_provincia,
             'CCIUDAD'      = bs_ciudad,
             'CPARROQUIA'   = bs_parroquia,
             'AMBOS SEGUROS'= bs_ambos_seguros,
             'TRAMITE'      = bs_tramite,
             'SEGURO'       = bs_seguro,
             'SEGURO'       = null,
             'LOCALIDAD'    = bs_localidad
          from cl_beneficiario_seguro a
          INNER JOIN cl_catalogo e ON e.codigo = a.bs_parentesco AND e.tabla = @w_tabla_cod
          LEFT JOIN cl_provincia b ON b.pv_provincia = a.bs_provincia
          LEFT JOIN cl_ciudad c ON c.ci_ciudad = bs_ciudad
          LEFT JOIN cl_parroquia d ON d.pq_parroquia = bs_parroquia
          where bs_nro_operacion  = @i_nro_operacion
          and   bs_producto = @i_producto
          and  (bs_seguro is null or bs_seguro = @i_seguro)
          and   bs_tramite is null
          order by bs_secuencia
      end
      if @@rowcount = 0
      begin
          if @i_apertura = 'N'
          begin
              exec sp_cerror
              @t_debug      = @t_debug,
              @t_file       = @t_file,
              @t_from       = @w_sp_name,
              @i_num        = 1720081
              --NO EXISTEN REGISTROS
              return 1720081
          end
      end
      return 0

end -- @i_operacion = 'A'

if @i_operacion = 'D'
begin
      if @i_seguro is not null
      begin
            if not exists( select codigo from cobis..cl_catalogo where tabla in (select codigo from cobis..cl_tabla where tabla = 'cr_tipos_seguro')and valor = @i_seguro)    
            
            begin
                exec cobis..sp_cerror
                    @t_debug = @t_debug,
                    @t_file  = @t_file,
                    @t_from  = @w_sp_name,
                    @i_num   = 1720318
                return 1720318
            end
      end

      if @i_origen = 'M' -- EL MOVIL ESTA ENVIANDO LA INSTANCIA DE PROCESO EN EL CAMPO @i_nro_operacion
      begin
          select @i_tramite = io_campo_3   -- JTO 28/08/2019 SE USA EL NUMERO DE TRAMITE
          from   cob_workflow..wf_inst_proceso
          where  io_id_inst_proc  = @i_nro_operacion
      end

      if (@i_secuencia is null OR @i_nro_operacion is null OR @i_producto is null)
      begin
            select
              @w_return = 1720321
            goto ERROR_FIN
            /* 'Parametros invalidos'*/
      end

    begin tran

      /* Eliminacion de registro en cl_beneficiario_seguro */
      if @i_origen in ('M','O')
      begin
          delete from cl_beneficiario_seguro
           where bs_tramite = @i_tramite   -- JTO 28/08/2019 USO DE LA VARIABLE DE TRAMITE
             and bs_producto = @i_producto
             and bs_secuencia = @i_secuencia
             and (bs_seguro is null or bs_seguro = @i_seguro)
      end
      else
      begin
          delete from cl_beneficiario_seguro
           where bs_nro_operacion = @i_nro_operacion
             and bs_producto = @i_producto
             and bs_secuencia = @i_secuencia
             and (bs_seguro is null or bs_seguro = @i_seguro)
      end

      if @@error <> 0
      begin
            exec sp_cerror
              @t_debug = @t_debug,
              @t_file  = @t_file,
              @t_from  = @w_sp_name,
              @i_num   = 1720322
            /* 'Error en eliminacion de beneficiario'*/
            return 1720322
      end
      commit tran

end -- @i_operacion = 'D'

if @i_operacion = 'X'
begin
      if (@i_nro_operacion is null OR @i_producto is null)
      begin
            select
              @w_return = 1720321
            goto ERROR_FIN
            /* 'Parametros invalidos'*/
      end
      begin tran

      /* Eliminacion de registro en cl_beneficiario_seguro */
      if @i_origen in ('M','O')
      begin
          delete from cl_beneficiario_seguro
           where bs_tramite = @i_tramite   -- JTO 28/08/2019 USO DE LA VARIABLE DEL TRAMITE
             and bs_producto = @i_producto
             and (bs_seguro is null or bs_seguro = @i_seguro)                                                
      end
      else
      begin
          delete from cl_beneficiario_seguro
           where bs_nro_operacion = @i_nro_operacion
             and bs_producto = @i_producto
             and (bs_seguro is null or bs_seguro = @i_seguro)                                                
      end

      if @@error <> 0
      begin
            exec sp_cerror
              @t_debug = @t_debug,
              @t_file  = @t_file,
              @t_from  = @w_sp_name,
              @i_num   = 1720322
            /* 'Error en eliminacion de beneficiario'*/
            return 1720322
      end
      commit tran
end -- @i_operacion = 'X'

select @w_sincroniza = pa_char
from cobis..cl_parametro
where pa_producto = 'CLI'
and pa_nemonico = 'HASIAU'

select @w_ofi_app = pa_smallint 
from cobis.dbo.cl_parametro cp 
where cp.pa_nemonico = 'OFIAPP'
and cp.pa_producto = 'CRE'

--Proceso de sincronizacion Clientes
if ((@i_operacion in ('I') and @i_ente is not null) or (@i_operacion in ('D') and @i_nro_operacion is not null)) and @w_sincroniza = 'S' and @w_ofi_app <> @s_ofi
begin
   select @w_ente_sinc = isnull(@i_ente, @i_nro_operacion * -1)
   exec @w_error = cob_sincroniza..sp_sinc_arch_json
      @i_opcion     = 'I',
      @i_cliente    = @w_ente_sinc,
      @t_debug      = @t_debug
end
return 0

ERROR_FIN:

      rollback tran
      exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = @w_return,
        @i_msg   = @w_msg
   
    /*  'No corresponde codigo de transaccion' */

  return @w_return
go
