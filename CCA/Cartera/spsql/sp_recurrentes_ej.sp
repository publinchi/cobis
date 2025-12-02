/********************************************************************/
/*   NOMBRE LOGICO:          sp_recurrentes_ej                      */
/*   NOMBRE FISICO:          sp_recurrentes_ej.sp                   */
/*   Producto:               Cartera                                */
/*   Disenado por:           Bruno Dueñas                           */
/*   Fecha de escritura:     02-Enero-2024                          */
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
/*                          PROPOSITO                               */
/********************************************************************/
/*   Este programa marca clientes recurrentes                       */
/********************************************************************/
/*                        MODIFICACIONES                            */
/********************************************************************/
/*      FECHA           AUTOR           RAZON                       */
/*    02/01/2024        BDU         Emision Inicial                 */
/********************************************************************/
use cob_cartera
go
set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO

if exists (select 1 
             from sysobjects 
            where name = 'sp_recurrentes_ej')
   drop proc sp_recurrentes_ej 
go

create proc sp_recurrentes_ej
(
   @i_param1   datetime    null, --fecha cierre o fecha proceso
   @i_param2   char(1)     null  --D: DIARIO     M: MENSUAL
)as
declare 
   @w_num_error          int,
   @w_sp_name            varchar(32),
   @w_sp_msg             varchar(600),
   @w_retorno_ej         int,
   @w_error              int,
   @w_min_cli            int,
   @w_max_cli            int,
   @w_cod_cli            int,
   @w_cod_adic           int,
   @w_desc_adic          varchar(200),
   @w_fecha_cierre       datetime,
   @w_fecha_inicio       datetime,
   @w_fecha_hoy          datetime,
   @w_est_novigente      smallint,
   @w_est_cancelado      smallint,
   @w_est_credito        smallint,
   @w_est_anulado        smallint
   
select @w_sp_name = 'sp_recurrentes_ej',
       @w_sp_msg  = '',
	   @w_fecha_hoy = getdate()


print 'Inicia proceso a las ' + convert(varchar, @w_fecha_hoy, 121)

--Sacar fecha inicio y cierre
select @w_fecha_cierre = isnull(@i_param1, fc_fecha_cierre)
from cobis.dbo.ba_fecha_cierre bfc 
where bfc.fc_producto = 7


select @w_fecha_inicio =  DATEFROMPARTS(YEAR(@w_fecha_cierre),MONTH(@w_fecha_cierre),1)

-- Estado de Cartera
exec @w_error = sp_estados_cca 
@o_est_novigente = @w_est_novigente out,
@o_est_cancelado = @w_est_cancelado out,
@o_est_credito   = @w_est_credito   out,
@o_est_anulado   = @w_est_anulado   out

if @w_error <> 0 
   goto errores

--tablas temporales para rollback
if (OBJECT_ID('tempdb..#tmp_cli_recurr','U')) is not null
begin  
    drop table #tmp_cli_recurr
end    
create table #tmp_cli_recurr (
    id                         int           identity(1, 1),
    en_ente_tmp                int           NULL
)

CREATE NONCLUSTERED INDEX tmp_cli
ON #tmp_cli_recurr  ([en_ente_tmp])

 
select @w_cod_adic = pa_int
from cobis..cl_parametro with (nolock)
where pa_producto = 'CLI'
and pa_nemonico = 'CODARE'
--Validar que exista el parametro
if @@rowcount = 0
begin
   set @w_error = 1729000
   goto errores
end

--Validar que exista el dato adicional
if not exists(select 1 from cobis.dbo.cl_dato_adicion cda with (nolock) where cda.da_codigo = @w_cod_adic)
begin
   set @w_error = 1720465
   goto errores
end
else
begin
   select @w_desc_adic = da_descripcion
   from cobis.dbo.cl_dato_adicion cda  with (nolock)
   where cda.da_codigo = @w_cod_adic
end


--ACTUALIZAR / CREAR DATO ADICIONAL EN 'N'
update cobis..cl_dadicion_ente
set de_valor = 'N'
from cobis..cl_ente ce with (nolock)
where ce.en_ente = de_ente 
and de_dato = @w_cod_adic
and ce.en_subtipo = 'P'

if @@error <> 0
begin
   set @w_error = 1720473
   goto errores
end


INSERT INTO cobis.dbo.cl_dadicion_ente (de_ente, de_dato, de_descripcion, de_tipo_dato, de_valor) 
select en_ente, @w_cod_adic, @w_desc_adic, 'C', 'N'
FROM cobis..cl_ente ce with (nolock)
where ce.en_ente not in (select de_ente from cobis.dbo.cl_dadicion_ente with (nolock)
                         where de_dato = @w_cod_adic)
and ce.en_subtipo = 'P'

if @@error <> 0
begin
   set @w_error = 1720470
   goto errores
end


if @i_param2 = 'D' --diaria
begin
   insert into #tmp_cli_recurr
   SELECT DISTINCT (op_cliente)
   FROM ca_operacion op WITH (nolock)
   WHERE (op_estado NOT IN (@w_est_novigente,@w_est_cancelado,@w_est_anulado,@w_est_credito)
   OR
   (op_estado = @w_est_cancelado AND EXISTS (SELECT 1
                              FROM ca_transaccion WITH (nolock)
                              WHERE tr_banco = op.op_banco
                              AND   tr_tran  = 'PAG'
                              AND   tr_estado <> 'RV'
                              AND   (tr_fecha_mov BETWEEN @w_fecha_inicio AND @w_fecha_cierre))))
end
else if @i_param2 = 'M' --mensual
begin
   insert into #tmp_cli_recurr
   SELECT DISTINCT (op_cliente)
   FROM ca_operacion op WITH (nolock)
   WHERE (op_estado NOT IN (@w_est_novigente,@w_est_cancelado,@w_est_anulado,@w_est_credito))
end


update cobis..cl_dadicion_ente
set de_valor = 'S'
from cobis..cl_ente ce with (nolock)
inner join #tmp_cli_recurr on en_ente_tmp = en_ente
where ce.en_ente = de_ente      
and de_dato = @w_cod_adic
and ce.en_subtipo = 'P'

if @@error <> 0
begin
   set @w_error = 1720473
   goto errores
end


print 'Termina proceso a las ' + convert(varchar, getdate(), 121)


return 0

--Control errores
errores:
   exec @w_retorno_ej = sp_errorlog
        @i_fecha       = @w_fecha_cierre, 
        @i_error       = @w_error, 
        @i_usuario     = 'opebatch',
        @i_tran        = 7000, 
        @i_tran_name   = @w_sp_name, 
        @i_rollback    = 'S',
        @i_cuenta      = '999', 
        @i_descripcion = NULL
   if @w_retorno_ej > 0
   begin
      return @w_retorno_ej
   end
   else
   begin
      return @w_error
   end


GO

