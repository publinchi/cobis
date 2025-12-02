/********************************************************************/
/*   NOMBRE LOGICO:      sp_rep_finiquito                           */
/*   NOMBRE FISICO:      sp_rep_finiquito.sp                        */
/*   BASE DE DATOS:      cob_cartera                                */
/*   PRODUCTO:           Cartera                                    */
/*   DISENADO POR:       Erwing Medina                              */
/*   FECHA DE ESCRITURA: 23-May-2023                                */
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
/*   Este programa procesa las transacciones del stored procedure   */ 
/*   Busqueda de parroquia                                          */
/********************************************************************/
/*                     MODIFICACIONES                               */
/*   FECHA              AUTOR              RAZON                    */
/*   23/May/2023        E.Medina           Emision Inicial          */
/********************************************************************/

use cob_cartera
go

if exists(select * from sysobjects where name = 'sp_rep_finiquito')
   drop proc sp_rep_finiquito
go

create proc sp_rep_finiquito (
   @s_ssn              int         = null,
   @s_date             datetime    = null,
   @s_srv              varchar(30) = null,
   @s_lsrv             varchar(30) = null,
   @s_user             login       = null,
   @s_term             descripcion = null,
   @s_corr             char(1)     = null,
   @s_ssn_corr         int         = null,
   @s_ofi              smallint    = null,
   @s_culture          varchar(10) = 'NEUTRAL',
   @t_rty              char(1)     = null,
   @t_trn              int         = null,
   @t_debug            char(1)     = 'N', 
   @t_file             varchar(14) = null,
   @i_banco            varchar(24),
   @i_formato_fecha    smallint    = 103
)
as
declare 
@w_error          int,
@w_msg            varchar(255),
@w_sp_name        varchar(30),
@w_fecha_canc     datetime,
@w_day            varchar(64),
@w_month          varchar(64),
@w_year           varchar(64),
@w_fecha          varchar(64),
@w_ciudad         varchar(160),
@w_mensaje_err    varchar(255),
@w_return         int

select @w_sp_name     = 'sp_rep_finiquito',
       @w_error       = 0,
       @w_return      = 0
       
--Internacionalizacion 
exec cobis..sp_ad_establece_cultura
   @o_culture = @s_culture out

/*Validaciones*/
--Debe ser operacion hija o individual
if exists (select 1 from ca_operacion 
where op_banco  =  @i_banco
and   op_grupal = 'S' and op_ref_grupal is null
)
begin
    select @w_error   =  2110173, --Debe enviar una operación valida
           @w_msg = 'Debe enviar una operación válida'
     goto ERROR
end

--Debe exitir un pago 
if not exists (select 1 from ca_transaccion 
where tr_banco = @i_banco
and   tr_estado <> 'RV' and tr_tran = 'PAG'
)
begin
    select @w_error   =  710023, --No existen Pagos
           @w_msg = 'No existen Pagos'
     goto ERROR
end

--Debe ser op_estado = 3
if not exists (select 1 from ca_operacion 
where op_banco = @i_banco
and   op_estado = 3
)
begin
    select @w_error   =  710023, --No existen Pagos
           @w_msg = 'No existen Pagos'
     goto ERROR
end

--Fecha de Cancelacion
select @w_fecha_canc = tr_fecha_mov
from ca_transaccion ct
where  tr_banco = @i_banco
and    tr_estado <> 'RV'
and    tr_tran = 'PAG'
and    tr_secuencial = (select max(tr_secuencial)
    from  ca_transaccion
    where tr_banco = @i_banco
    and   tr_estado <> 'RV'
    and   tr_tran  = 'PAG')
-- Ciudad de la Oficina de Conexion 
select @w_ciudad = ci_descripcion
from cobis..cl_ciudad
inner join cobis..cl_oficina
on ci_ciudad = of_ciudad
where of_oficina = @s_ofi

--Formato de Fecha 
/*Extraccion de la Fecha*/

select @s_date = CONVERT(datetime,@s_date,@i_formato_fecha)

set @w_day   =         convert( varchar    ,format(@s_date, 'dd'))
set @w_month =   upper(convert( varchar ,format(@s_date, 'MMMM','es-es')))
set @w_year  =         convert( varchar    ,format(@s_date, 'yyyy'))

set @w_fecha =   concat('el ',@w_day,' del mes de ',@w_month, ' del ', @w_year)

select
'op_nombre'  = op_nombre,
'fecha_canc' = convert(varchar, @w_fecha_canc,103),
'op_banco'   = convert(varchar, op_banco),
'ciudad'     = @w_ciudad,
'fecha_imp'  = @w_fecha
from ca_operacion
where op_banco = @i_banco
   
    
return 0

ERROR:

   select @w_mensaje_err = re_valor
   from   cobis..cl_errores inner join cobis..ad_error_i18n
                            on (numero = pc_codigo_int
                            and re_cultura like '%'+@s_culture+'%')
   where  numero = @w_error

   select @w_msg = isnull(@w_mensaje_err,@w_msg)


   exec cobis..sp_cerror
      @t_debug = 'N',
      @t_file  = null,
      @t_from  = @w_sp_name,
      @i_msg   = @w_msg,
      @i_num   = @w_error

   return @w_error
go 