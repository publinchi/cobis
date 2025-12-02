/************************************************************************/
/*  Archivo:              sp_credito_integrante_int.sp                  */
/*  Stored procedure:     sp_credito_integrante_int                     */
/*  Base de datos:        cob_interface                                 */
/*  Producto:             credito                                       */
/*  Disenado por:         William Lopez                                 */
/*  Fecha de escritura:   06/Sep/2021                                   */
/************************************************************************/
/*                        IMPORTANTE                                    */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad de     */
/*  COBISCORP.                                                          */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado  hecho por alguno de sus            */
/*  usuarios sin el debido consentimiento por escrito de COBISCORP.     */
/*  Este programa esta protegido por la ley de derechos de autor        */
/*  y por las convenciones  internacionales   de  propiedad inte-       */
/*  lectual.    Su uso no  autorizado dara  derecho a COBISCORP para    */
/*  obtener ordenes  de secuestro o retencion y para  perseguir         */
/*  penalmente a los autores de cualquier infraccion.                   */
/************************************************************************/
/*                        PROPOSITO                                     */
/*  sp cascara para servicio rest de operaciones por integrante por gpo */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*  FECHA         AUTOR           RAZON                                 */
/*  06/Sep/2021   William Lopez   Emision Inicial                       */
/*  25/Mar/2022   pmoreno         Se elimina modo 3 para ejecucion desde*/
/*                                servicio rest                         */
/*  27/04/2022    dmorales        Se valida actualizacion contr_estado  */  
/*  20/07/2022    bduenas        Se agrega llamado en modo 4            */        
/*  03/08/2022    bduenas        Se envia nuevo parametro               */                                  
/************************************************************************/
use cob_interface
go

if exists(select 1 from sysobjects where name = 'sp_credito_integrante_int' and type = 'P')
    drop procedure sp_credito_integrante_int
go

create procedure sp_credito_integrante_int
(
   @s_ssn                 int           = null,
   @s_sesn                int           = null,
   @s_ofi                 smallint      = null,
   @s_rol                 smallint      = null,
   @s_user                login         = null,
   @s_date                datetime      = null,
   @s_term                descripcion   = null,
   @t_debug               char(1)       = 'N',
   @t_file                varchar(10)   = null,
   @t_from                varchar(32)   = null,
   @s_srv                 varchar(30)   = null,
   @s_lsrv                varchar(30)   = null,
   @i_cheque              int           = null,
   @i_operacion           char(1),
   @i_num_integrantes     int,
   @i_grupo               int           = null,
   @i_tramite             int           = null,
   @i_ente                int           = null,
   @i_monto               money         = null,
   @i_modo                int           = 2,
   @i_participa_ciclo     char(1)       = null,
   @i_tg_monto_aprobado   money         = null,
   @i_ahorro              money         = null,
   @i_monto_max           money         = null,
   @i_bc_ln               char(10)      = null,
   @i_tr_cod_actividad    catalogo      = null,
   @i_sector              catalogo      = null, 
   @i_monto_recomendado   money         = null
)
as 
declare
   @w_sp_name           varchar(65),
   @w_return            int,
   @w_error             int,
   @w_num_integrantes   int,
   @w_estado            char(1),
   @w_banco             varchar(24)

select @w_sp_name         = 'sp_credito_integrante_int',
       @w_error           = 0,
       @w_return          = 0,
       @w_num_integrantes = null

--Validaciones
exec @w_return = cob_interface..sp_valida_integrante_int
     @i_grupo             = @i_grupo,
     @i_tramite           = @i_tramite,
     @i_ente              = @i_ente,
     @i_monto             = @i_monto,
     @i_participa_ciclo   = @i_participa_ciclo,
     @i_tg_monto_aprobado = @i_tg_monto_aprobado,
     @i_ahorro            = @i_ahorro,
     @i_monto_max         = @i_monto_max,
     @i_bc_ln             = @i_bc_ln,
     @i_tr_cod_actividad  = @i_tr_cod_actividad,
     @i_sector            = @i_sector, 
     @i_monto_recomendado = @i_monto_recomendado

select @w_error = @w_return
if @w_return != 0 or @@error != 0
begin
   select @w_return  = @w_error
   goto ERROR
end

if @i_tramite = 0 or @i_tramite is null
begin 
    select
    @w_return = 2110179
    ---@w_msg    = 'Debe enviar numero de tramite para Actualizar.'
 
    goto ERROR
end
   
select @w_estado = tr_estado from cob_credito..cr_tramite where tr_tramite = @i_tramite
-- DMO Un trámite aprobado no puede ser actualizado 
if( @w_estado  <> 'N')
begin
    select
    @w_return = 2110395
    ---@w_msg    = 'Un trámite aprobado no puede ser actualizado.'
 
    goto ERROR
end  

--sp grupal con modo 2

if @w_error = 0
begin
--actualiza el estado de la cr_tramite_grupal
   exec @w_return = cob_credito..sp_grupal_monto 
         @s_srv               = @s_srv,
         @s_user              = @s_user,
         @s_term              = @s_term,
         @s_ofi               = @s_ofi,
         @s_rol               = @s_rol,
         @s_ssn               = @s_ssn,
         @s_lsrv              = @s_lsrv,
         @s_date              = @s_date,
         @s_sesn              = @s_sesn,
         @i_operacion         = 'U',
         @i_modo              = @i_modo, --modo 2
         @i_grupo             = @i_grupo,
         @i_tramite           = @i_tramite,
         @i_ente              = @i_ente,
         @i_cheque            = @i_cheque,
         @i_monto             = @i_monto,
         @i_participa_ciclo   = @i_participa_ciclo,
         @i_tg_monto_aprobado = @i_tg_monto_aprobado,
         @i_ahorro            = @i_ahorro,
         @i_monto_max         = @i_monto_max,
         @i_bc_ln             = @i_bc_ln,
         @i_tr_cod_actividad  = @i_tr_cod_actividad,
         @i_sector            = @i_sector,
         @i_monto_recomendado = @i_monto_recomendado

   select @w_error = @w_return
   if @w_return != 0 or @@error != 0
   begin
      select @w_return  = @w_error
      goto ERROR
   end  
   
--actualiza operacion hija
   exec @w_return = cob_credito..sp_grupal_monto 
         @s_srv               = @s_srv,
         @s_user              = @s_user,
         @s_term              = @s_term,
         @s_ofi               = @s_ofi,
         @s_rol               = @s_rol,
         @s_ssn               = @s_ssn,
         @s_lsrv              = @s_lsrv,
         @s_date              = @s_date,
         @s_sesn              = @s_sesn,
         @i_operacion         = 'U',
         @i_modo              = 4, --modo 4
         @i_grupo             = @i_grupo,
         @i_tramite           = @i_tramite,
         @i_ente              = @i_ente,
         @i_cheque            = @i_cheque,
         @i_monto             = @i_monto,
         @i_participa_ciclo   = @i_participa_ciclo,
         @i_tg_monto_aprobado = @i_tg_monto_aprobado,
         @i_ahorro            = @i_ahorro,
         @i_monto_max         = @i_monto_max,
         @i_bc_ln             = @i_bc_ln,
         @i_tr_cod_actividad  = @i_tr_cod_actividad,
         @i_sector            = @i_sector,
         @i_monto_recomendado = @i_monto_recomendado

   select @w_error = @w_return
   if @w_return != 0 or @@error != 0
   begin
      select @w_return  = @w_error
      goto ERROR
   end  
   
   --resume operacion padre
   exec @w_return = cob_credito..sp_grupal_monto 
         @s_srv               = @s_srv,
         @s_user              = @s_user,
         @s_term              = @s_term,
         @s_ofi               = @s_ofi,
         @s_rol               = @s_rol,
         @s_ssn               = @s_ssn,
         @s_lsrv              = @s_lsrv,
         @s_date              = @s_date,
         @s_sesn              = @s_sesn,
         @i_operacion         = 'U',
         @i_modo              = 3, --modo 3
         @i_grupo             = @i_grupo,
         @i_tramite           = @i_tramite,
         @i_ente              = @i_ente,
         @i_cheque            = @i_cheque,
         @i_monto             = @i_monto,
         @i_participa_ciclo   = @i_participa_ciclo,
         @i_tg_monto_aprobado = @i_tg_monto_aprobado,
         @i_ahorro            = @i_ahorro,
         @i_monto_max         = @i_monto_max,
         @i_bc_ln             = @i_bc_ln,
         @i_tr_cod_actividad  = @i_tr_cod_actividad,
         @i_sector            = @i_sector,
         @i_monto_recomendado = @i_monto_recomendado,
         @i_desde_interfaz    = 'S'

   select @w_error = @w_return
   if @w_return != 0 or @@error != 0
   begin
      select @w_return  = @w_error
      goto ERROR
   end  
   
   if exists(select 1 from cob_cartera..ca_operacion_tmp where opt_tramite = @i_tramite)
   begin
      select @w_banco = op_banco from cob_cartera..ca_operacion where op_tramite = @i_tramite
      exec @w_return = cob_cartera..sp_borrar_tmp
           @s_user       = @s_user,
           @s_term       = @s_term,
           @i_desde_cre  = 'S',
           @i_banco      = @w_banco
        
        if @w_return != 0 
        begin
            goto   ERROR
        end
   end
   
   
end

return @w_return

ERROR:
   exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = @w_return
   return @w_return
go