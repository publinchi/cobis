/************************************************************************/
/*   Archivo:              rep_reg_fga.sp                               */
/*   Stored procedure:     sp_rep_registro_fga                          */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Fecha de escritura:   26/Mar/2014                                  */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Carga de garantias FGA                                             */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      Fecha           Nombre            Proposito                     */
/*  13/Mar/2014         Igmar Berganza    Emision Inicial               */
/************************************************************************/

use cob_cartera
go

SET ANSI_NULLS OFF
GO

if exists (select 1 from sysobjects where name = 'sp_rep_registro_fga')
   drop proc sp_rep_registro_fga
go

create proc sp_rep_registro_fga
@i_param1   varchar(10)   = null

as
declare
   @w_sp_name            varchar(32),
   @w_msg                descripcion,
   @w_error              int,
   @w_fecha              datetime,
   @w_s_app              varchar(50),
   @w_path               varchar(50),
   @w_destino            varchar(50),
   @w_comando            varchar(500),
   @w_fecha_proc         datetime,
   @w_mensaje            varchar(30),
   @w_en_ced_ruc         varchar(20),
   @w_cod_gar_fag        varchar(30),
   @w_en_nit             varchar(20),
   @w_mes                char(2),
   @w_anio               char(4),
   @w_proceso            int
   
   select @w_sp_name = 'sp_rep_cartera_fga'
   select @w_fecha_proc = fp_fecha
   from cobis..ba_fecha_proceso
   
   select @w_proceso = ba_batch
   from   cobis..ba_batch 
   where  ba_arch_fuente = 'cob_cartera..' + @w_sp_name

   /*CREACION TABLA TEMPORAL*/

   if exists (select 1 from sysobjects where name = 'ca_rep_registro_fga')
      drop table ca_rep_registro_fga

   create table ca_rep_registro_fga
   ( 
      nit_intermediario varchar(20)  NULL,
      sucursal          int          NULL,
      nombres_deudor    varchar(254) NULL,
      tipo_id_deudor    char(2)      NULL,
      doc_deudor        varchar(20)  NULL,
      genero            int          NULL,
      direccion         varchar(254) NULL,
      municipio         int          NULL,
      telefono1         varchar(16)  NULL,
      telefono2         varchar(16)  NULL,
      fax               varchar(16)  NULL,
      ciiu              varchar(4)   NULL,
      referencia        varchar(24)  NULL,
      pagare            varchar(24)  NULL,
      codigo_moneda     varchar(3)   NULL,
      valor_desembolso  money        NULL,
      fecha_desembolso  varchar(10)  NULL,
      plazo             int          NULL,
      fecha_vencimiento varchar(10)  NULL,
      periodo_gracia    int          NULL,
      tipo_cartera      int          NULL,
      destino_credito   int          NULL,
      tipo_recursos     char(1)      NULL,
      valor_redescuento money        NULL,
      porcentaje_redesc float        NULL,
      nit_en_redesc     varchar(30)  NULL,
      convenio          int          NULL,
      cod_prod_garant   int          NULL,
      funcionario       varchar(254) NULL,
      desc_garant		varchar(254) NULL,
      doc_codeudor1     varchar(30)  NULL,
      tipo_id_codeudor  char(2)      NULL,
      nom_codeudor      varchar(254) NULL,
      dir_codeudor      varchar(254) NULL,
      municipio_codeu   int          NULL,
      tel_codeudor1     varchar(16)  NULL,
      tel_codeudor2     varchar(16)  NULL,
      pagare_anterior   varchar(24)  NULL
   )
   
   -- Obteniendo cedula y nit del cliente Bancamia 
   select @w_en_ced_ruc  = en_ced_ruc, 
          @w_en_nit      = en_nit
   from cobis..cl_ente 
   where en_ente = 345785
   
   if @@rowcount = 0 
   begin
      select 
      @w_error = 141050, 
      @w_msg = 'No existe Ente'
      goto ERROR
   end
   
   /* OBTIENE CODIGO GARANTIAS ESPECIALES */
   select @w_cod_gar_fag = pa_char
   from cobis..cl_parametro with (nolock)
   where pa_producto = 'GAR'
   and   pa_nemonico = 'CODFGA'
   
   if @@rowcount = 0 
   begin
      select 
      @w_error = 701063, 
      @w_msg = 'No existe Codigo de Garante'
      goto ERROR
   end
   
   -- Extrayendo informacion del deudor
   select banco             = do_banco, 
          desembolso        = do_monto,
          fecha_consecion   = do_fecha_concesion,
          plazo             = do_num_cuotas, 
          fecha_vencimiento = do_fecha_vencimiento,
          en_nomlar_d       = en_nomlar,
          en_tipo_ced_d     = en_tipo_ced,
          en_ced_ruc_d      = en_ced_ruc,
          en_ente_d         = en_ente
   into #ca_rep_registro_fga_d
   from cob_conta_super..sb_dato_operacion, cob_credito..cr_gar_propuesta, 
        cob_custodia..cu_custodia, cob_custodia..cu_tipo_custodia, cob_cartera..ca_operacion,
        cobis..cl_cliente, cobis..cl_ente
   where do_tramite       = gp_tramite
   and   gp_garantia      = cu_codigo_externo
   and   cu_tipo          = tc_tipo
   and   op_banco         = do_banco
   and   cl_det_producto  = op_operacion
   and   en_ente          = cl_cliente
   and   cl_rol           = 'D'
   and   do_aplicativo    = 7
   and   tc_tipo_superior = @w_cod_gar_fag
   and   do_fecha         = @i_param1
   
   if @@rowcount = 0 
   begin
      select 
      @w_error = 701063, 
      @w_msg = 'No existe Codigo de Garante'
      goto ERROR
   end
   
   select di_descripcion_d = di_descripcion, di_ente_d = di_ente
   into #cl_direccion_d
   from cobis..cl_direccion, #ca_rep_registro_fga_tmp
   where di_ente = en_ente_d
   and (di_tipo in ('011','002') or di_principal = 'S')
   and  di_descripcion is not null
   
   if @@rowcount = 0 
   begin
      select 
      @w_error = 101059, 
      @w_msg = 'No existe direccion'
      goto ERROR
   end
   
   select te_valor_d = te_valor, te_ente_d = te_ente
   into #cl_telefono_d
   from cobis..cl_telefono, #ca_rep_registro_fga_tmp
   where te_ente        = en_ente_d
   and te_tipo_telefono = 'D' 
   
   if @@rowcount = 0 
   begin
      select 
      @w_error = 101029, 
      @w_msg = 'No existe telefono'
      goto ERROR
   end
   
   -- Extrayendo informacion del codeudor
   select en_nomlar_c       = en_nomlar,
          en_tipo_ced_c     = en_tipo_ced,
          en_ced_ruc_c      = en_ced_ruc,
          en_ente_c         = en_ente
   into #ca_rep_registro_fga_c     
   from cob_conta_super..sb_dato_operacion, cob_credito..cr_gar_propuesta, 
        cob_custodia..cu_custodia, cob_custodia..cu_tipo_custodia, cob_cartera..ca_operacion,
        cobis..cl_cliente, cobis..cl_ente
   where do_tramite       = gp_tramite
   and   gp_garantia      = cu_codigo_externo
   and   cu_tipo          = tc_tipo
   and   op_banco         = do_banco
   and   cl_det_producto  = op_operacion
   and   en_ente          = cl_cliente
   and   cl_rol           = 'C'
   and   tc_tipo_superior = @w_cod_gar_fag
   and   do_fecha         = @i_param1
   
   select di_descripcion_c = di_descripcion, di_ente_c = di_ente
   into #cl_direccion_c
   from cobis..cl_direccion, #ca_rep_registro_fga_c
   where di_ente = en_ente_c
   and (di_tipo in ('011','002') or di_principal = 'S')
   and  di_descripcion is not null
   
   if @@rowcount = 0 
   begin
      select 
      @w_error = 101059, 
      @w_msg = 'No existe direccion'
      goto ERROR
   end
   
   select te_valor_d  = te_valor, te_ente_c = te_ente
   into #cl_telefono_c
   from cobis..cl_telefono, #ca_rep_registro_fga_c
   where te_ente        = en_ente_c
   and te_tipo_telefono = 'D' 
   
   if @@rowcount = 0 
   begin
      select 
      @w_error = 101029, 
      @w_msg = 'No existe telefono'
      goto ERROR
   end
   
   insert into ca_rep_registro_fga
   select nit_intermediario = @w_en_nit,
          sucursal          = 0,
          nombres_deudor    = en_nomlar_d,
          tipo_id_deudor    = en_tipo_ced_d,
          doc_deudor        = en_ced_ruc_d,
          genero            = 0,
          direccion         = di_descripcion_d,
          municipio         = 0,
          telefono1         = te_valor_d,
          telefono2         = te_valor_d,
          fax               = te_valor_d,
          ciiu              = '',
          referencia        = banco,
          pagare            = banco,
          codigo_moneda     = 'COP',
          valor_desembolso  = desembolso,
          fecha_desembolso  = fecha_consecion,
          plazo             = plazo,
          fecha_vencimiento = fecha_vencimiento,
          periodo_gracia    = 0,
          tipo_cartera      = 0,
          destino_credito   = 0,
          tipo_recursos     = '',
          valor_redescuento = 0,
          porcentaje_redesc = 0,
          nit_en_redesc     = '',
          convenio          = 0,
          cod_prod_garant   = 0,
          funcionario       = '',
          desc_garant		= '',
          doc_codeudor1     = en_ced_ruc_c,
          tipo_id_codeudor  = en_tipo_ced_c,
          nom_codeudor      = en_nomlar_c,
          dir_codeudor      = di_descripcion_c,
          municipio_codeu   = 0,
          tel_codeudor1     = te_valor_c,
          tel_codeudor2     = te_valor_c,
          pagare_anterior   = 0
   from #ca_rep_registro_fga_d, #cl_direccion_d, #cl_telefono_d, 
        #ca_rep_registro_fga_c, #cl_direccion_c, #cl_telefono_c
   where en_ente_d = di_ente_d
   and   di_ente_d = te_ente_d
   and   en_ente_c = di_ente_c
   and   di_ente_c = te_ente_c
        
          
   /*** GENERAR BCP ***/
   select @w_s_app = pa_char
   from   cobis..cl_parametro
   where  pa_producto = 'ADM'
   and    pa_nemonico = 'S_APP'
   
   if @@rowcount = 0 
   begin
      select 
      @w_error = 2101084, 
      @w_msg = 'ERROR AL OBTENER EL PARAMETRO GENERAL S_APP DE ADM'
      goto ERROR
   end

   select @w_path = pp_path_destino
   from   cobis..ba_path_pro
   where  pp_producto = 7
   
   if @@rowcount = 0 
   begin
      select  
      @w_error = 2101084,
      @w_msg = 'ERROR EN LA BUSQUEDA DEL PATH EN LA TABLA ba_batch'
   end
   
   select @w_mes = SUBSTRING(@i_param1,4,2)
   
   select @w_anio = SUBSTRING(@i_param1,7,4)
   
   --Ejecucion para Generar Archivo Datos
   select @w_comando = @w_s_app + 's_app bcp -auto -login cob_cartera..ca_rep_registro_fga out '
   
   select @w_destino  = @w_path + 'G_' + isnull(@w_en_nit,'') + '_1_' + @w_mes + @w_anio + '.txt'

   select @w_comando = @w_comando + @w_destino + ' -b5000 -c -t"|" ' + '-config '+ @w_s_app + 's_app.ini'

   exec @w_error = xp_cmdshell @w_comando

   if @w_error <> 0 begin
      select @w_msg = 'Error Generando Archivo' 
      goto ERROR
   end
   
return 0

ERROR:

set @w_mensaje = @w_sp_name + ' ---> ' + @w_mensaje 

set @w_fecha = getdate()

exec sp_errorlog 
   @i_fecha       = @w_fecha,
   @i_error       = @w_error, 
   @i_usuario     = @w_sp_name, 
   @i_tran        = @w_proceso,
   @i_tran_name   = @w_sp_name,
   @i_descripcion = @w_msg,
   @i_cuenta      = 'Masivo',
   @i_rollback    = 'N'

return @w_error
go