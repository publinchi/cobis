/************************************************************************/
/*  NOMBRE LOGICO:        fechavalgrupal.sp                             */
/*  NOMBRE FISICO:        sp_fecha_valor_grupal                         */
/*  BASE DE DATOS:        cob_cartera                                   */
/*  PRODUCTO:             CARTERA                                       */
/*  DISENADO POR:         Guisela Fernandez                             */
/*  FECHA DE ESCRITURA:   26/Jun/2023                                   */
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
/*                        PROPOSITO                                     */
/*  Este programa realiza los reversos de los pagos de operaciones hijas*/
/*  y grupal en prestamos grupales                                      */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*  FECHA         AUTOR              RAZON                              */
/*  26/06/2023   Guisela Fernandez        Emisión Inicial               */
/*  04/07/2023   Guisela Fernandez   Se aumenta parametro t_timeout     */
/*  12/07/2023   Guisela Fernandez   B864019 Se envia parametro para    */
/*                                   de tran. en caso de errores        */
/*  11/09/2023   Guisela Fernandez   R215030 Se Cambia proceso de consu-*/
/*                                   ta de ope. hijas para fecha valor  */
/************************************************************************/
use cob_cartera
go

if exists(select 1 from sysobjects where name ='sp_fecha_valor_grupal')
   drop proc sp_fecha_valor_grupal 
go

create procedure sp_fecha_valor_grupal 
(
   @s_ssn                   int         = null,
   @s_user                  login       = null,
   @s_rol                   tinyint     = 3,
   @s_term                  varchar(30) = null,
   @s_date                  datetime    = null,
   @s_sesn                  int         = null,
   @s_ofi                   smallint    = null,
   @s_srv                   varchar(30) = null,
   @t_trn                   INT         = null,
   @t_timeout               INT         = null,
   @s_lsrv                  varchar(30) = null,
   @s_org                   char(1)     = null,   
   @i_operacion             char(1)     = null,
   @i_banco_grupal          cuenta      = null,
   @i_externo               char(1)     = 'N',
   @i_fecha_valor           datetime    = null
)
as
declare
@w_sp_name                descripcion,
@w_error                  int,
@w_fecha_proceso          datetime,
@w_operacionca            int,  
@w_operacionca_grupal     int, 
@w_secuencial_retro       int,
@w_num_fechas_ult_proceso int,
@w_fecha_ult_proceso      datetime,
@w_banco                  cuenta,
@w_migrada                char,
@w_fecha_migrada          datetime,
@w_est_novigente          smallint,
@w_est_credito            smallint,
@w_est_cancelado          smallint,
@w_est_anulado            smallint


select @w_sp_name          = 'sp_pago_grupal_reverso',
       @w_secuencial_retro = 0
	   
--Estados de Cartera
exec  sp_estados_cca 
   @o_est_novigente = @w_est_novigente out, --0
   @o_est_cancelado = @w_est_cancelado out, --3
   @o_est_credito   = @w_est_credito   out, --99
   @o_est_anulado   = @w_est_anulado   out  --6

-- BUSQUEDA DE OPERACIONES HIJAS
if @i_operacion = 'S' 
begin
   
   -- Tabla temporal de información de operaciones hijas
   if exists (select 1 from sysobjects where name = '#ca_fecha_valor_grupal')
      drop table #ca_fecha_valor_grupal
      
   
   create table #ca_fecha_valor_grupal(
      fvg_banco              cuenta       not null,
      fvg_cliente            int          not null,
      fvg_nombre             descripcion  not null,
      fvg_fecha_ult_proceso  datetime     not null,
      fvg_estado             descripcion  not null,
      fvg_migrada            varchar(10)  not null,
      fvg_fecha_migrada      datetime,
      fvg_fecha_liq          datetime     not null
   )

   select op_banco
   into #ca_op_hijas
   from ca_operacion
   where op_grupal = 'S'
   and op_ref_grupal = @i_banco_grupal
   and op_estado not in (@w_est_novigente,@w_est_cancelado,@w_est_anulado,@w_est_credito)
   
   if @@rowcount = 0
   begin
      -- Error, la operación padre no tiene operaciones hijas asociadas
      select @w_error  = 711095
      goto ERROR
   end
   
   select @w_banco = min(op_banco)
   from #ca_op_hijas
   
   while @w_banco is not NULL
   begin
      select @w_operacionca = op_operacion
	  from ca_operacion
      where op_banco  = @w_banco
	  
	  if exists (select 1 from ca_transaccion where tr_operacion =  @w_operacionca and tr_tran = 'MIG')
	     select @w_migrada       = 'S',
                @w_fecha_migrada = tr_fecha_mov 
		 from ca_transaccion 
		 where tr_operacion = @w_operacionca and tr_tran = 'MIG'
      
      --Se inserta los datos de cada una de las operaciones hijas	  
      insert into #ca_fecha_valor_grupal
      select op_banco,
             op_cliente,
             op_nombre,
             op_fecha_ult_proceso,
             (select es_descripcion from ca_estado WHERE es_codigo = op_estado),
             (CASE when @w_migrada = 'S' then 'SI' else 'NO' end),
             @w_fecha_migrada,
             op_fecha_liq
      from ca_operacion
      where op_banco = @w_banco
	  
	  select @w_banco = min(op_banco)
      from #ca_op_hijas
	  where op_banco > @w_banco
   end
   
   --Query de devuelve las operaciones hijas
   select fvg_banco,
          fvg_cliente,
          fvg_nombre,
          fvg_fecha_ult_proceso,
          fvg_estado,
          fvg_migrada,
          fvg_fecha_migrada,
          fvg_fecha_liq
   from #ca_fecha_valor_grupal

end

if @i_operacion = 'F' begin

   -- Se valida que la fecha valor no sea mayor a la fecha de proceso
   select @w_fecha_proceso = fp_fecha from cobis..ba_fecha_proceso
   
   if(@i_fecha_valor > @w_fecha_proceso  )
   begin
      select @w_error  = 701192
      goto ERROR
   end
   
   --Se valida que la fecha de ultimo proceso de la operaciones hijas sean iguales
   select @w_num_fechas_ult_proceso = count(distinct op_fecha_ult_proceso)
   from ca_operacion with (nolock)
   where op_grupal='S'
   and op_ref_grupal = @i_banco_grupal
   and op_estado not in (@w_est_novigente,@w_est_cancelado,@w_est_anulado,@w_est_credito)
   
   if @w_num_fechas_ult_proceso > 1
   begin 
      select @w_error  = 725294
      goto ERROR
   end
   
   select @w_operacionca_grupal = op_operacion 
   from ca_operacion
   where op_banco = @i_banco_grupal

   if @i_externo = 'S'
      begin tran

   -- Bucle para reverso de cada una de los operaciones hijas
   select op_operacion
   into #ca_op_hijas_fecha_val
   from ca_operacion
   where op_grupal='S'
   and op_ref_grupal = @i_banco_grupal
   and op_estado not in (@w_est_novigente,@w_est_cancelado,@w_est_anulado,@w_est_credito)
   
   select @w_operacionca = min(op_operacion)
   from  #ca_op_hijas_fecha_val

   while @w_operacionca is not null 
   begin
      
      select @w_banco     = op_banco
      from ca_operacion
      where op_operacion = @w_operacionca
	
      --Proceso de Fecha valor 
      exec  @w_error  = sp_fecha_valor
         @s_srv          = @s_srv,
         @s_user         = @s_user,
         @s_term         = @s_term,
         @s_ofi          = @s_ofi,
         @s_rol          = @s_rol,
         @s_ssn          = @s_ssn,
         @s_lsrv         = @s_lsrv,
         @s_date         = @s_date,
         @s_sesn         = @s_sesn,
         @s_org          = @s_org,
         @t_trn          = 7049,
         @i_banco        = @w_banco,
         @i_operacion    = 'F',
         @i_fecha_valor  = @i_fecha_valor,
		 @i_en_linea          = 'N'

      if @@error != 0 or  @w_error <> 0
      begin
      goto ERROR
      end
       
      --Recorre a la siguiente operacion hija 
	  select @w_operacionca = min(op_operacion)
      from  #ca_op_hijas_fecha_val
      where  op_operacion > @w_operacionca
	
   end

   if @i_externo = 'S'
      commit tran
   
   -- EVITAR QUE CONSULTA DE OPERACIONES LLEVE EL PRESTAMO A LA FECHA DE PROCESO EN CASO DE FECHA VALOR 
   delete ca_en_fecha_valor_grupal
   where  fvg_operacion = @w_operacionca_grupal
   
   if @@error <> 0 begin
      select @w_error = 710003
      goto ERROR
   end

   ---LOG fecha valor antes de cambiar la @w_fecha_valor
   if @w_secuencial_retro  is null select @w_secuencial_retro = 0
     
   insert ca_log_fecha_valor_grupal values (
   @w_operacionca_grupal,  @w_secuencial_retro, 'F', 
   @i_fecha_valor,         'N',                 @s_user, 
   getdate() )
   
   if @@error != 0 
   begin
       select @w_error = 710001
       goto ERROR
   end
   
   --Para que en reversas regrese la operacion a la fecha de proceso actual y no marque la operacion como en fecha valor     
   if @i_fecha_valor < @w_fecha_proceso 
   begin   
      
      -- INSERTAR REGISTRO SOLO SI LA FECHA VALOR ES MENOR A LA FECHA DE PROCESO
      insert into ca_en_fecha_valor_grupal(
      fvg_operacion,   fvg_banco,   fvg_fecha_valor, 
      fvg_user)
      values(
      @w_operacionca_grupal, @i_banco_grupal,   @i_fecha_valor,  
      @s_user)
      
      if @@error <> 0 begin
         select @w_error = 710001
         goto ERROR
      end
      
   end

end

return 0

ERROR:
if @i_externo = 'S' begin
while @@TRANCOUNT > 0 rollback tran

exec cobis..sp_cerror
@t_debug = 'N',
@t_file = '',
@t_from = @w_sp_name,
@i_num = @w_error

   return @w_error
end
else
return @w_error

go
