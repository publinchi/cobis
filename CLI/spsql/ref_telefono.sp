/************************************************************************/
/*  Archivo:                         ref_telefono.sp                    */
/*  Stored procedure:                sp_ref_telefono                    */
/*  Base de datos:                   cobis                              */
/*  Producto:                        Clientes                           */
/*  Disenado por:                    ACA                                */
/*  Fecha de escritura:              06-08-2021                         */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada; y por lo tanto, derivará en acciones legales civiles      */
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/
/*                          PROPOSITO                                   */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*      FECHA           AUTOR           RAZON                           */
/*      06/08/21        ACA           Emision Inicial                   */
/*      25/05/23        BDU           Ordenar telefonos por secuencial  */
/*      09/09/23        BDU           R214440-Sincronizacion automatica */
/*      22/01/24        BDU           R224055-Validar oficina app       */
/************************************************************************/
use cobis
go

set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1 from sysobjects where name = 'sp_ref_telefono')
   drop proc sp_ref_telefono
go
CREATE PROCEDURE sp_ref_telefono (
        @s_ssn                  int         = null,
        @s_user                 login       = null,
        @s_term                 varchar(32) = null,
        @s_sesn                 int         = null,
        @s_culture              varchar(10) = null,
        @s_date                 datetime    = null,
        @s_srv                  varchar(30) = null,
        @s_lsrv                 varchar(30) = null,
        @s_rol                  smallint    = NULL,
        @s_org_err              char(1)     = NULL,
        @s_error                int         = NULL,
        @s_sev                  tinyint     = NULL,
        @s_msg                  descripcion = NULL,
        @s_org                  char(1)     = NULL,
        @s_ofi                  smallint    = NULL,
        @t_debug                char(1)     = 'N',
        @t_file                 varchar(14) = null,
        @t_from                 varchar(30) = null,
        @t_trn                  int         = null,
        @t_show_version         bit         = 0,     -- Mostrar la version del programa
        @i_operacion            char        = null,  -- Valor de la operacion a realizar
        @i_ente                 int         = NULL,  -- Código del cliente
        @i_referencia           char(1)     = NULL,  -- Tipo de Referencia (L,P)
        @i_tipo_telefono        char(1)     = NULL,  -- Tipo de teléfono (C,F)
        @i_pais                 varchar(10) = NULL,  -- Prefijo del país
        @i_area                 varchar(10) = NULL,  -- Área del País
        @i_numero_tel           varchar(16) = NULL,  -- Número de teléfono
        @i_secuencial           tinyint     = NULL,  -- secuencial del registro
        @i_sec_ref              tinyint     = NULL,  -- secuencial de la Referencia
        @o_secuencial            tinyint     = NULL output  -- secuencial de salida
        )
as
declare 
        @w_sp_name          varchar(32),
        @w_return           int,
        @w_cp               smallint, --Parámetro código de país
        @w_respuesta        tinyint,   --Respuesta para función valida teléfono
        @w_longitud         tinyint,  --longitud de la cadena valor de teléfono
        @w_valida_long      tinyint,  --Valor de Parámetro de validación de longitud
        @w_error            int,
        @w_secuencial       smallint,
        @w_num              int,
        @w_param            int, 
        @w_diff             int,
        @w_date             datetime,
        @w_bloqueo          char(1),
        -- R214440-Sincronizacion automatica
        @w_sincroniza      char(1),
        @w_ofi_app         smallint
        
select @w_sp_name = 'sp_ref_telefono'
       
if @i_operacion in ('I', 'U', 'D')
begin
   /* VALIDACIONES LISTAS NEGRAS PARA EL CLIENTE */
   if @i_ente is not null and @i_ente <> 0
   begin
      select @w_bloqueo = en_estado from cobis..cl_ente where en_ente = @i_ente
      if @w_bloqueo = 'S'
      begin
         exec sp_cerror
         @t_debug  = @t_debug,
         @t_file   = @t_file,
         @t_from   = @w_sp_name,
         @i_num    = 1720604
         return 1720604
      end
   end 
end 
if @i_operacion in ('I','U') begin
   select @w_cp = pa_smallint from cobis..cl_parametro where pa_nemonico = 'PPD' and pa_producto = 'CLI'
   
   if @i_pais = @w_cp
   begin
      select @w_longitud = LEN(@i_numero_tel) --longitud de valor de telefono
      if  @i_tipo_telefono = 'C' --Celular
      begin
         select @w_valida_long = pa_smallint from cl_parametro where pa_nemonico = 'DCEL' and pa_producto = 'CLI'
   if @w_longitud <> @w_valida_long
         begin
            select @w_error = 1720539 -- 'El Celular no es valido'
            goto ERROR_FIN 
         end
      end
      if @i_tipo_telefono = 'D' --fijo
      begin
         select @w_valida_long = pa_smallint from cl_parametro where pa_nemonico = 'DTELF' and pa_producto = 'CLI'
   if @w_longitud <> @w_valida_long
         begin
            select @w_error = 1720537 -- 'El teléfono no es valido'
            goto ERROR_FIN 
         end
      end 
      
   end
   /*Validar dígitos consecutivos*/
   select @w_respuesta = cobis.dbo.fn_valida_telefono(@i_numero_tel)
   
   if @w_respuesta <> 0
   begin
      select @w_error = 1720536 -- 'El teléfono no es valido'
      goto ERROR_FIN 
   end
       
end--Fin validaciones 
    
if @i_operacion = 'I' --Insertar
begin
   --Control de existencia
   if exists (select 1 from cl_ref_telefono 
              where rt_ente     = @i_ente 
              and rt_referencia = @i_referencia 
              and rt_pais       = @i_pais 
              and rt_area       = @i_area
              and rt_tipo_tel   = @i_tipo_telefono
              and rt_numero_tel = @i_numero_tel
           and rt_sec_ref    = @i_sec_ref)
   begin
      select @w_error = 1720540 -- 'El teléfono no es valido'
      goto ERROR_FIN 
   end
   
   select @w_secuencial = MAX(rt_secuencial) from cl_ref_telefono
         where rt_ente       = @i_ente
           and rt_referencia = @i_referencia 
           and rt_sec_ref    = @i_sec_ref

   if @w_secuencial is null 
   begin
      select @o_secuencial = 1
   end
   else
   begin
      select @o_secuencial = @w_secuencial + 1
   end

   begin tran

   insert into  cl_ref_telefono(
       rt_ente,        rt_referencia,        rt_tipo_tel,
       rt_pais,        rt_area,              rt_numero_tel,
        rt_secuencial,  rt_sec_ref)
      values(
       @i_ente,        @i_referencia,        @i_tipo_telefono,
       @i_pais,        @i_area,              @i_numero_tel,
        @o_secuencial,  @i_sec_ref)

   if @@error <> 0 begin
      select @w_error = 17202541 --'Error en creacion de telefono'
      goto ERROR_FIN
   end


   insert into ts_telefono_ref(
   secuencial,         tipo_transaccion,     clase,
   fecha,              usuario,              terminal,                               
   srv,                lsrv,                 ente,                                   
   referencia,         tipo_tel,             pais,                                   
   area,               num_telefono,         telefono,                               
   sec_ref
   )
   values(
   @s_ssn,              @t_trn,              'I',
   getdate(),           @s_user,             @s_term,
   @s_srv,              @s_lsrv,             @i_ente,
   @i_referencia,       @i_tipo_telefono,    @i_pais,
   @i_area,             @i_numero_tel,       @o_secuencial,
   @i_sec_ref)
   --ERROR EN CREACION DE TRANSACCION DE SERVICIO
   if @@error <> 0 begin
      select @w_error = 1720049
      goto ERROR_FIN
   end

   commit tran


end-- Fin insertar
    
if @i_operacion = 'Q' --Consulta
begin
   --Control de existencia
   select 
      'Cliente'          = rt_ente,
      'Tipo Referencia'  = rt_referencia,
      'Tipo telefono'    = rt_tipo_tel,
      'Prefijo'          = rt_pais,
      'Area'             = rt_area,
      'Número'           = rt_numero_tel,
      'secuencial'       = rt_secuencial,
     'secRef'           = rt_sec_ref
   from cl_ref_telefono
   where rt_ente         = @i_ente
   and   rt_referencia   = @i_referencia
   and   rt_sec_ref      = @i_sec_ref
   order by rt_secuencial asc
end --Fin consulta

if @i_operacion = 'U'
begin
   if not exists (select 1 from cl_ref_telefono 
                  where rt_ente     = @i_ente 
                  and rt_referencia = @i_referencia
                  and rt_sec_ref    = @i_sec_ref
                  and rt_secuencial = @i_secuencial)
   begin
      select @w_error = 1720543 -- 'El teléfono no existe'
      goto ERROR_FIN 
   end

    --Control de existencia
    if exists (select 1 from cl_ref_telefono 
               where rt_ente     = @i_ente 
               and rt_referencia = @i_referencia 
               and rt_pais       = @i_pais 
               and rt_area       = @i_area
               and rt_tipo_tel   = @i_tipo_telefono
               and rt_numero_tel = @i_numero_tel
              and rt_sec_ref    = @i_sec_ref
              and rt_secuencial <> @i_secuencial)
    begin
       select @w_error = 1720540 -- 'El teléfono no es valido'
       goto ERROR_FIN 
    end

   begin tran

   insert into ts_telefono_ref(
   secuencial,         tipo_transaccion,     clase,
   fecha,              usuario,              terminal,                               
   srv,                lsrv,                 ente,                                   
   referencia,         tipo_tel,             pais,                                   
   area,               num_telefono,         telefono,                               
   sec_ref
   )
   select
   @s_ssn,              @t_trn,              'A',
   getdate(),           @s_user,             @s_term,
   @s_srv,              @s_lsrv,             @i_ente,
   rt_referencia,       rt_tipo_tel,         rt_pais,
   rt_area,             rt_numero_tel,       rt_secuencial,
   @i_sec_ref
   from cl_ref_telefono
   where rt_ente          = @i_ente 
    and   rt_referencia    = @i_referencia
   and   rt_sec_ref       = @i_sec_ref
   and   rt_secuencial    = @i_secuencial

   --ERROR EN CREACION DE TRANSACCION DE SERVICIO
   if @@error <> 0 begin
      select @w_error = 1720049
      goto ERROR_FIN
   end
    
   update cl_ref_telefono
   set rt_ente       = isnull(@i_ente,rt_ente),
        rt_referencia = isnull(@i_referencia,rt_referencia),
        rt_pais       = isnull(@i_pais,rt_pais),
        rt_area       = isnull(@i_area,rt_area),
        rt_tipo_tel   = isnull(@i_tipo_telefono,rt_tipo_tel),
        rt_numero_tel = isnull(@i_numero_tel,rt_numero_tel),
        rt_secuencial = isnull(@i_secuencial,rt_secuencial)
   where rt_ente           = @i_ente 
         and rt_referencia  = @i_referencia
        and rt_sec_ref     = @i_sec_ref
        and rt_secuencial  = @i_secuencial
            
   if @@error <> 0 begin
      select @w_error = 17202542 --'Error en actualización de teléfono'
      goto ERROR_FIN
   end

   insert into ts_telefono_ref(
   secuencial,         tipo_transaccion,     clase,
   fecha,              usuario,              terminal,                               
   srv,                lsrv,                 ente,                                   
   referencia,         tipo_tel,             pais,                                   
   area,               num_telefono,         telefono,                               
   sec_ref
   )
   select
   @s_ssn,              @t_trn,              'D',
   getdate(),           @s_user,             @s_term,
   @s_srv,              @s_lsrv,             @i_ente,
   rt_referencia,       rt_tipo_tel,         rt_pais,
   rt_area,             rt_numero_tel,       rt_secuencial,
   @i_sec_ref
   from cl_ref_telefono
   where rt_ente          = @i_ente 
    and   rt_referencia    = @i_referencia
   and   rt_sec_ref       = @i_sec_ref
   and   rt_secuencial    = @i_secuencial

   commit tran
      
end --End Update

if @i_operacion = 'D' begin
   if not exists (select 1 from cl_ref_telefono 
                where rt_ente     = @i_ente 
                and rt_referencia = @i_referencia
                and rt_sec_ref    = @i_sec_ref
                and rt_secuencial = @i_secuencial)
   begin
      select @w_error = 1720543 -- 'El teléfono no existe'
      goto ERROR_FIN 
   end

   begin tran

   insert into ts_telefono_ref(
   secuencial,         tipo_transaccion,     clase,
   fecha,              usuario,              terminal,                               
   srv,                lsrv,                 ente,                                   
   referencia,         tipo_tel,             pais,                                   
   area,               num_telefono,         telefono,                               
   sec_ref
   )
   select
   @s_ssn,              @t_trn,              'E',
   getdate(),           @s_user,             @s_term,
   @s_srv,              @s_lsrv,             @i_ente,
   rt_referencia,       rt_tipo_tel,         rt_pais,
   rt_area,             rt_numero_tel,       rt_secuencial,
   @i_sec_ref
   from cl_ref_telefono
   where rt_ente          = @i_ente 
    and   rt_referencia    = @i_referencia
   and   rt_sec_ref       = @i_sec_ref
   and   rt_secuencial    = @i_secuencial

   if @@error <> 0 begin
      select @w_error = 17202542 --'Error en actualización de teléfono'
      goto ERROR_FIN
   end
   
   delete from cl_ref_telefono
   where rt_ente       = @i_ente 
      and rt_referencia = @i_referencia
     and rt_secuencial = @i_secuencial
     and rt_sec_ref    = @i_sec_ref
     
   if @@error <> 0 begin
      select @w_error = 1720544 --'Error en eliminación de teléfono'
      goto ERROR_FIN
   end

   commit tran
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
if @i_operacion in ('I', 'U', 'D') and @i_ente is not null and @i_ente <> 0 and @w_sincroniza = 'S' and @w_ofi_app <> @s_ofi
begin
   exec @w_error = cob_sincroniza..sp_sinc_arch_json
      @i_opcion     = 'I',
      @i_cliente    = @i_ente,
      @t_debug      = @t_debug
end

return 0
ERROR_FIN:

while @@trancount > 0 rollback

exec cobis..sp_cerror
@t_debug    = @t_debug,
@t_file     = @t_file,
@t_from     = @w_sp_name,               
@i_num      = @w_error,
@s_culture  = @s_culture 
return @w_error

go
