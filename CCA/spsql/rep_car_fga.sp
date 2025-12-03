/************************************************************************/
/*   Archivo:              rep_car_fga.sp                               */
/*   Stored procedure:     sp_rep_cartera_fga                           */
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

if exists (select 1 from sysobjects where name = 'sp_rep_cartera_fga')
   drop proc sp_rep_cartera_fga
go

create proc sp_rep_cartera_fga
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

   if exists (select 1 from sysobjects where name = 'ca_rep_cartera_fga')
      drop table ca_rep_cartera_fga
   
   select @w_en_ced_ruc = en_ced_ruc, 
          @w_en_nit     = en_nit 
   from cobis..cl_ente 
   where en_ente = 345785
   
   if @@rowcount = 0 
   begin
      select 
      @w_error = 141050, 
      @w_msg = 'No existe Ente'
      goto ERROR
   end
   
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
   
   select banco           = do_banco, 
          saldo_cap       = do_saldo_cap, 
          saldo_cap_total = do_saldo, 
          fecha           = do_fecha, 
          num_cuotas      = do_num_cuotas, 
          fecha_ini_mora  = do_fecha_ini_mora,
          fecha_ult_pago  = do_fecha_ult_pago,
          estado = (case when do_estado_cobranza in('CJ','CP') then 'J'
                       else 
                            case when do_estado_cartera = 1 then 'V'
                                 when do_estado_cartera in (2,9) then 'M'
                                 when do_estado_cartera = 3 then 'C'
                                 when do_estado_cartera = 3 and (do_fecha_ult_pago < do_fecha_vencimiento) then 'P' 
                            end
                       end)
          into ca_rep_cartera_fga             
          from cob_conta_super..sb_dato_operacion, cob_credito..cr_gar_propuesta, 
               cob_custodia..cu_custodia, cob_custodia..cu_tipo_custodia
          where do_tramite       = gp_tramite
          and   gp_garantia      = cu_codigo_externo
          and   cu_tipo          = tc_tipo
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
   select @w_comando = @w_s_app + 's_app bcp -auto -login cob_cartera..ca_rep_cartera_fga out '
   
   select @w_destino  = @w_path + 'C_' + isnull(@w_en_nit,'') + '_1_' + @w_mes + @w_anio + '.txt'

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