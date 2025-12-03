/************************************************************************/
/*   Archivo:                telefono.sp                                */
/*   Stored procedure:       sp_telefono                                */
/*   Base de datos:          cobis                                      */
/*   Producto:               Clientes                                   */
/*   Disenado por:           JMEG                                       */
/*   Fecha de escritura:     30-Abril-19                                */
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
/*   y penales en contra del infractor según corresponda.”.             */
/************************************************************************/
/*                           PROPOSITO                                  */
/*   Este programa procesa las transacciones del stored procedure       */
/*   Busqueda de telefono                                               */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*      FECHA           AUTOR           RAZON                           */
/*      30/04/19        JMEG         Emision Inicial                    */
/*      06/12/19        AMG          Agregar parametro @i_pefijo        */
/*      16/06/20        FSAP         Estandarizacion de Clientes        */
/*      15/10/20        MBA          Uso de la variable @s_culture      */
/*      03/08/21        ACA          Se add campo prefijo en consulta   */
/*      04/08/21        ACA          Validaciones Nro telefonicos       */
/*      16/03/22        PJA          Se agrega operacion [Q]            */ 
/*      11/08/22        BDU          Se agrega filtro direccion         */ 
/*      09/09/23        BDU          R214440-Sincronizacion automatica  */
/*      20/10/23        BDU          R217831-Ajuste validacion error    */
/*      22/01/24        BDU          R224055-Validar oficina app        */
/************************************************************************/
use cobis
go

set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO

if exists (select * from sysobjects where name = 'sp_telefono')
   drop proc sp_telefono
go

create procedure sp_telefono (
   @s_ssn              int         = null,
   @s_user             login       = null,
   @s_term             varchar(32) = null,
   @s_sesn             int         = null,
   @s_date             datetime    = null,
   @s_srv              varchar(30) = null,
   @s_lsrv             varchar(30) = null,
   @s_ofi              int         = null,
   @s_rol              int         = null,
   @s_org_err          char(1)     = null,
   @s_error            int         = null,
   @s_sev              tinyint     = null,
   @s_msg              descripcion = null,
   @s_org              char(1)     = null,
   @s_culture          varchar(10) = 'NEUTRAL',
   @p_alterno          tinyint     = null,
   @t_debug            char(1)     = 'N',
   @t_file             varchar(10) = null,
   @t_from             varchar(32) = null,
   @t_trn              int         = null,
   @t_show_version     bit         = 0,      -- Mostrar la versión del programa   
   @i_operacion        char(1),
   @i_ente             int         = null,  -- Codigo del ente al cual se le asocia un telefono
   @i_direccion        tinyint     = null,  -- Codigo de la direccion a la cual se asocia un telefono
   @i_secuencial       tinyint     = null,  -- Numero que indica la cantidad de telefonos que tiene el cliente
   @i_valor            varchar(16) = null,  -- Numero de telefono
   @i_tipo_telefono    char(2)     = null,  -- Tipo de telefono
   @i_te_telf_cobro    char(1)     = 'N',   -- Especifica si es telefono para gestion de cobro //DVE
   @i_tborrado         char(1)     = 'D',   -- 'D' - Unicamente se va a eliminar el telefono seleccionado
   @i_ejecutar         char(1)     = 'N',   -- MALDAZ 06/25/2012 HSBC CLI-0565  
   @i_verificado       char(1)     = null,
   @i_formato_fecha    int         = 111,
   @i_cod_area         varchar(10) = null,  -- req27122
   @i_prefijo          varchar(10) = null,  -- AMG: Se agrega parámetro de prefijo
   @o_siguiente        int         = null out
   
   -- 'T' - Se van a eliminar TODAS los telefonos asociados a la dir.
)
as
declare
   @w_sp_name          varchar(32),
   @w_sp_msg           varchar(132),
   @w_error            int,
   @w_valor            varchar(16),
   @w_tipo_telefono    char(2),
   @w_secuencial       varchar(3),
   @w_di_telefono      tinyint,
   @w_cp               smallint, --Parámetro código de país
   @w_respuesta        tinyint,   --Respuesta para función valida teléfono
   @w_longitud         tinyint,  --longitud de la cadena valor de teléfono
   @w_valida_long      tinyint,   --Valor de Parámetro de validación de longitud
   @w_num              int,
   @w_param            int, 
   @w_diff             int,
   @w_date             datetime,
   @w_bloqueo          char(1),
   -- R214440-Sincronizacion automatica
   @w_sincroniza      char(1),
   @w_ofi_app         smallint
   
select @w_sp_name = 'sp_telefono'

---- VERSIONAMIENTO DEL PROGRAMA -------------------------------------------
if @t_show_version = 1 begin
   select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
   select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
   print  @w_sp_msg
   return 0
end

---- EJECUTAR SP DE LA CULTURA ---------------------------------------  
exec cobis..sp_ad_establece_cultura
        @o_culture = @s_culture out

if @i_operacion in ('I', 'U', 'D')
begin
   /* VALIDACIONES LISTAS NEGRAS PARA EL CLIENTE */
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
if @i_operacion in ('I','U') begin
   if @i_ejecutar = 'N' begin
      -- Verificacion de claves foraneas 
      if not exists (select di_ente from   cl_direccion
                     where  di_ente      = @i_ente
                     and    di_direccion = @i_direccion ) begin
         select @w_error = 1720074 -- 'No existe direccion'
         goto ERROR_FIN   
      end
      
     if not exists ( select codigo from   cl_catalogo
                      where  codigo = @i_tipo_telefono
                      and    tabla  = (select codigo from   cl_tabla where  tabla = 'cl_ttelefono')) and @i_tipo_telefono is not null begin
         select @w_error = 1720151 -- 'No existe tipo de telefono'
         goto ERROR_FIN   
      end
   end --if @i_ejecutar = 'N'
   
   select @w_cp = pa_smallint from cobis..cl_parametro where pa_nemonico = 'PPD' and pa_producto = 'CLI'

   if @i_prefijo = @w_cp
   begin
      select @w_longitud = LEN(@i_valor) --longitud de valor de telefono
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
   select @w_respuesta = cobis.dbo.fn_valida_telefono(@i_valor)

   if @w_respuesta <> 0
   begin
      select @w_error = 1720536 -- 'El teléfono no es valido'
      goto ERROR_FIN 
   end


end


/* Insert */
if @i_operacion = 'I' begin

   if @t_trn <> 172031 begin
      select @w_error = 1720075 --'No corresponde codigo de transaccion'
      goto ERROR_FIN
   end
   
   begin tran
   
   update cl_direccion
   set    di_telefono  = isnull(di_telefono,0) + 1
   where  di_ente      = @i_ente
   and    di_direccion = @i_direccion
         
   if @@error != 0 begin
      select @w_error = 1720206 --'Error en incremento de telefono'
      goto ERROR_FIN   
   end

   select @o_siguiente = isnull(max(te_secuencial), 0) + 1
   from cl_telefono 
   where te_ente      = @i_ente 
   and   te_direccion = @i_direccion
   
   if @o_siguiente is null
      select @o_siguiente = 1
   /* Se valida el numero de telefono para no insertar numeros
   repetidos.  M. Silva .  01/21/98.  Bco. Estado */

   -- XOL: Estamos dentro de la @i_operacion = 'I', no es necesario esto 
   --if @i_operacion <>'U'   -- valida que este proceso no ocurra cuando exista una actualizaciï¿½n de los telefonos.
   --begin   
   
   if exists ( select te_valor from   cl_telefono
               where  te_valor         = @i_valor
               and    te_ente          = @i_ente
               and    te_tipo_telefono = @i_tipo_telefono 
               and    te_direccion     = @i_direccion
               and    te_telf_cobro    = @i_te_telf_cobro) 
   begin
      select @w_error = 1720209 --'El telefono ya esta asociado a esta direccion'
      goto ERROR_FIN
   end   
   
   insert into cl_telefono (
   te_ente,           te_direccion,        te_secuencial,
   te_valor,          te_tipo_telefono,    te_telf_cobro,--DVE
   te_funcionario,    te_verificado,       te_fecha_registro,
   te_area,           te_prefijo)  --req-27122
   values (
   @i_ente,           @i_direccion,        @o_siguiente,
   @i_valor,          @i_tipo_telefono,    @i_te_telf_cobro,--DVE
   @s_user,           'N',                 @s_date,           
   @i_cod_area,       @i_prefijo)

   if @@error <> 0 begin
      --print 'en %1! dir %2! sig %3! val %4! tt %5! tc %6!',@i_ente,@i_direccion,@o_siguiente,@i_valor,@i_tipo_telefono , @i_te_telf_cobro -- JLi 22-07-2003
      select @w_error = 1720207 --'Error en creacion de telefono'
      goto ERROR_FIN
   end

   insert into ts_telefono(
   secuencial,          tipo_transaccion,    clase,
   fecha,               usuario,             terminal,
   srv,                 lsrv,                ente,
   direccion,           telefono,            valor,
   tipo,                codarea,             oficina,
   prefijo
   )
   values(
   @s_ssn,              @t_trn,              'N',
   getdate(),           @s_user,             @s_term,
   @s_srv,              @s_lsrv,             @i_ente,
   @i_direccion,        @o_siguiente,        @i_valor,
   @i_tipo_telefono,    @i_cod_area,         @s_ofi,
   @i_prefijo)
   
   --ERROR EN CREACION DE TRANSACCION DE SERVICIO
   if @@error <> 0 begin
      select @w_error = 1720049
      goto ERROR_FIN
   end

   commit tran
   select @o_siguiente

end

/* Update */
if @i_operacion = 'U' begin

   if @t_trn <> 172032 begin
      select @w_error = 1720075 --'No corresponde codigo de transaccion'
      goto ERROR_FIN
   end

   if exists ( select te_valor
               from   cl_telefono
               where  te_valor          = @i_valor
               and    te_ente           = @i_ente
               and    te_tipo_telefono  = @i_tipo_telefono
               and    te_telf_cobro     = @i_te_telf_cobro 
               and    te_direccion      = @i_direccion
               and    te_secuencial    <> @i_secuencial) or @i_verificado != null 
   begin
      select @w_error = 1720209 --'El telefono ya esta asociado a esta direccion'
      goto ERROR_FIN
   end 
  
   begin tran
   
   --Registro antes del cambio
   insert into ts_telefono(
   secuencial,          tipo_transaccion,    clase,
   fecha,               usuario,             terminal,
   srv,                 lsrv,                ente,
   direccion,           telefono,            valor,
   tipo,                codarea,             oficina,
   prefijo
   )
   select
   @s_ssn,              @t_trn,              'A',
   getdate(),           @s_user,             @s_term,
   @s_srv,              @s_lsrv,             @i_ente,
   @i_direccion,        @i_secuencial,       te_valor,
   te_tipo_telefono,    te_area,             @s_ofi,
   te_prefijo
   from cl_telefono
   where  te_ente           =  @i_ente
   and    te_direccion      =  @i_direccion
   and    te_secuencial     =  @i_secuencial

   --ERROR EN CREACION DE TRANSACCION DE SERVICIO
   if @@error <> 0 begin
      select @w_error = 1720049
      goto ERROR_FIN
   end

   update cl_telefono set
   te_valor                 =  isnull(@i_valor,te_valor),
   te_tipo_telefono         =  isnull(@i_tipo_telefono,te_tipo_telefono),
   te_telf_cobro            =  isnull(@i_te_telf_cobro,te_telf_cobro), --DVE
   te_funcionario           =  @s_user,
   te_verificado            =  isnull(@i_verificado, 'N'),
   te_fecha_ver             =  case @i_verificado when 'S' then @s_date else null end,
   te_fecha_modificacion    =  @s_date,
   te_area                  =  isnull(@i_cod_area,te_area),
   te_prefijo               =  isnull(@i_prefijo, te_prefijo)
   where  te_ente           =  @i_ente
   and    te_direccion      =  @i_direccion
   and    te_secuencial     =  @i_secuencial
      
   if @@error <> 0 begin
      select @w_error = 1720206 --'Error en actualizacion de telefono'
      goto ERROR_FIN
   end

   --Registro despues del cambio
   insert into ts_telefono(
   secuencial,          tipo_transaccion,    clase,
   fecha,               usuario,             terminal,
   srv,                 lsrv,                ente,
   direccion,           telefono,            valor,
   tipo,                codarea,             oficina,
   prefijo
   )
   select
   @s_ssn,              @t_trn,              'D',
   getdate(),           @s_user,             @s_term,
   @s_srv,              @s_lsrv,             @i_ente,
   @i_direccion,        @i_secuencial,       te_valor,
   te_tipo_telefono,    te_area,             @s_ofi,
   te_prefijo
   from cl_telefono
   where  te_ente           =  @i_ente
   and    te_direccion      =  @i_direccion
   and    te_secuencial     =  @i_secuencial

   --ERROR EN CREACION DE TRANSACCION DE SERVICIO
   if @@error <> 0 begin
      select @w_error = 1720049
      goto ERROR_FIN
   end

   commit tran


end -- 'U'


/* Search */
If @i_operacion = 'S' begin

   if @t_trn <> 172033 begin
      select @w_error = 1720075 --'No corresponde codigo de transaccion'
      goto ERROR_FIN
   end
   
   select 'Codigo'      = te_secuencial,
          'Telefono'    = te_valor,
          'Tipo'        = te_tipo_telefono,
          'Descripcion' = substring(i.re_valor, 1, 10), 
          'Telf. Cobro' = isnull(te_telf_cobro, 'N'), --DVE
          'Funcionario' = te_funcionario, --PRA
          'Verificado'  = te_verificado, --PRA
          'Fec. Ver.'   = convert(varchar(10),te_fecha_ver,@i_formato_fecha), --PRA
          'Fec. Reg.'   = convert(varchar(10),te_fecha_registro,@i_formato_fecha), --PRA
          'Fec. Mod.'   = convert(varchar(10),te_fecha_modificacion,@i_formato_fecha), --PRA
          'Cod. Area'   = te_area,
          'prefijo'     = te_prefijo
   from   cl_telefono, cl_catalogo a, cl_tabla m, cobis..ad_catalogo_i18n i
   where  te_ente       = @i_ente
   and    te_direccion    = @i_direccion
   and    a.codigo        = te_tipo_telefono
   and    a.tabla         = m.codigo
   and    m.tabla         = 'cl_ttelefono'
   and i.re_cultura       = @s_culture 
   and i.pc_codigo        = a.codigo 
   and i.pc_identificador = m.tabla 

      
   if @@error <> 0 begin
      select @w_error = 1720074 -- 'No existe dato solicitado'
      goto ERROR_FIN
   end
      


end -- 'S'

/* Consulta */
if @i_operacion = 'Q'
begin
   if @t_trn <> 172033 begin
      select @w_error = 1720075 --'No corresponde codigo de transaccion'
      goto ERROR_FIN
   end
   
   select 
      'Cliente'          = te_ente,
      'Id Direccion'     = te_direccion,
      'Numero'           = te_valor,
      'Tipo Telefono'    = te_tipo_telefono,
      'Area'             = te_area,
      'Prefijo'          = te_prefijo,
      'Secuencial'       = te_secuencial
   from cl_telefono
   where te_ente          =   @i_ente
   and   te_direccion     =   @i_direccion

   if @@error <> 0 begin
      select @w_error = 1720074 -- 'No existe dato solicitado'
      goto ERROR_FIN
   end
   
 
end -- 'Q'


/* Delete */
if @i_operacion = 'D' begin

   if @t_trn <> 172034 begin
      select @w_error = 1720075 --'No corresponde codigo de transaccion'
      goto ERROR_FIN
   end
   
   select te_secuencial 
   from cobis..cl_telefono 
   where te_ente          =   @i_ente
   and   te_direccion     =   @i_direccion
   and   te_secuencial    =   @i_secuencial
   
   if @@rowcount = 0 begin
      select @w_error = 1720379 -- No se encontro telefono
      goto ERROR_FIN
   end
   
   /* Verificacion de claves foraneas */
   if not exists ( select di_ente from  cl_direccion
                   where di_ente = @i_ente
                   and  di_direccion = @i_direccion ) begin
      select @w_error = 1720074 -- 'No existe direccion'
      goto ERROR_FIN
   end

   /* Valores para transaccion de  servicios */
   select @w_valor = te_valor,
          @w_tipo_telefono = te_tipo_telefono
   from   cl_telefono
   where  te_ente       = @i_ente
   and    te_direccion  = @i_direccion
   and    te_secuencial = @i_secuencial
      
   /* OHF: Control eliminacion de telefonos:
   - Si se trata de la eliminacion de un solo telefono, se controla que minimo quede un telefono asociado a la dir.
   - Si se trata de la eliminacion de una direccion se deben eliminar todos los telefonos asociados.
   */
   if @i_tborrado <> 'T' begin
      select @w_di_telefono = count(*) 
      from   cl_telefono
      where  te_ente = @i_ente
      and    te_direccion = @i_direccion

      if @w_di_telefono = 1 begin
         select @w_error = 1720210 -- 'No se pueden eliminar todos los numeros telefonicos'
         goto ERROR_FIN   
      end
   end
   
   begin tran
   
   --Registro de la transaccion
   insert into ts_telefono(
   secuencial,          tipo_transaccion,    clase,
   fecha,               usuario,             terminal,
   srv,                 lsrv,                ente,
   direccion,           telefono,            valor,
   tipo,                codarea,             oficina,
   prefijo
   )
   select
   @s_ssn,              @t_trn,              'E',
   getdate(),           @s_user,             @s_term,
   @s_srv,              @s_lsrv,             @i_ente,
   @i_direccion,        @i_secuencial,       te_valor,
   te_tipo_telefono,    te_area,             @s_ofi,
   te_prefijo
   from cl_telefono
   where  te_ente           =  @i_ente
   and    te_direccion      =  @i_direccion
   and    te_secuencial     =  @i_secuencial

   --ERROR EN CREACION DE TRANSACCION DE SERVICIO
   if @@error <> 0 begin
      select @w_error = 1720049
      goto ERROR_FIN
   end

   update cl_direccion
   set    di_telefono = di_telefono - 1
   --     set di_telefono = di_telefono 
   where  di_ente      = @i_ente
   and    di_direccion = @i_direccion

   if @@error <> 0 begin
      select @w_error = 1720211 -- 'Error en disminucion de telefono'
      goto ERROR_FIN
   end

   delete from cl_telefono
   where  te_ente       = @i_ente
   and    te_direccion  = @i_direccion
   and    te_secuencial = @i_secuencial

   if @@error <> 0 begin
      select @w_error = 1720211 --'Error en eliminacion de telefono'
      goto ERROR_FIN
   end
         
   if @@error <> 0 begin
      select @w_error = 1720211 -- 'Error en eliminacion de telefono'
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
      
   if @w_error <> 0 and @w_error is not null
   begin
      goto ERROR_FIN
   end
      
end

return 0

ERROR_FIN:
exec cobis..sp_cerror
@t_debug    = @t_debug,
@t_file     = @t_file,
@t_from     = @w_sp_name,
@i_num      = @w_error,
@s_culture  = @s_culture 
return @w_error
 
go
