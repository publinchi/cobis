/************************************************************************/
/*  Archivo:                diario_operaciones.sp                       */
/*  Stored procedure:       sp_diario_operaciones                       */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jonatan Rueda                               */
/*  Fecha de Documentacion: 23/Abr/2019                                 */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP S.A.representantes exclusivos para el Ecuador de la       */
/*  AT&T                                                                */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante               */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  SP GENERADO POR EXTRACCION DE LA BB.DD. cob_credito                 */
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  23/04/19          LOGIN_DESA       Emision Inicial                  */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_diario_operaciones')
    drop proc sp_diario_operaciones
go

create proc sp_diario_operaciones(
@i_fecha        datetime
)
as

DECLARE
@w_contador               int,
@w_retorno                int,
@w_sp_name                varchar(30),
@w_return                 int,
@w_fecha                  datetime,
@w_operacion              int,
@w_banco                  varchar(24),
@w_toperacion             varchar(10),
@w_aplicativo_cr          tinyint,
@w_aplicativo_ca          tinyint, 
@w_destino_economico      varchar(10),
@w_clase_cartera          varchar(10),
@w_cliente                int,
@w_documento_tipo         varchar(2),
@w_documento_numero       varchar(24),
@w_oficina                int,
@w_moneda                 tinyint,
@w_monto                  money,
@w_tasa                   float,
@w_modalidad              char(1),
@w_plazo_dias             int,
@w_fecha_desembolso       datetime,
@w_fecha_vencimiento      datetime,
@w_edad_mora              int,
@w_reestructuracion       char(1),
@w_fecha_reest            datetime,
@w_nat_reest              varchar(10),
@w_num_reest              tinyint,
@w_num_renovaciones       int,
@w_estado                 tinyint,
@w_cupo_credito           varchar(24),
@w_num_cuotas             smallint,
@w_periodicidad_cuota     smallint,
@w_valor_cuota            money,
@w_cuotas_pag             smallint,
@w_cuotas_ven             smallint,
@w_saldo_ven              money,
@w_fecha_prox_vto         datetime,
@w_fecha_ult_pago         datetime,
@w_valor_ult_pago         money,
@w_fecha_castigo          datetime,
@w_num_acta               varchar(24),
@w_clausula               char(1),
--Datos Adicionales
@w_est_vencido            int,
@w_calificacion           char(1),
@w_admisible              char(1),
@w_regional               int,
@w_sucursal               int,
@w_departamento           int,
@w_tipo_gar               varchar(1),
@w_valor_gar              money,
@w_fecha_ven              datetime,
@w_ciudad                 int,
@w_saldo                  money,
@w_saldo_cap              money,
@w_saldo_int              money,
@w_saldo_otr              money,
@w_saldo_int_cont         money,
@w_saldo_cap_sus          money,
@w_estado_contable        int,
@w_gerente                int,
@w_probabilidad           float,
@w_prov_cap               money,
@w_prov_int               money,
@w_prov_otr               money,
@w_situacion_cliente      varchar(10),
@w_anulado                int,
@w_mensaje                varchar(250),
@w_error                  int,
@w_usuario                login,
@w_fecha_ant              datetime


select @w_contador      = 0,       
       @w_sp_name       = 'sp_diario_operaciones',
       @w_est_vencido   = 2,
       @w_anulado       = 7,
       @w_aplicativo_cr = 21,
       @w_aplicativo_ca = 7,
       @w_usuario       = 'crebatch',
       @w_error         = 21001


--Eliminacion de registros a ser procesados Diarios
delete cob_credito..cr_dato_operacion 
from cob_credito..cr_dato_operacion with (index = cr_dato_operacion_Akey1)
where do_tipo_reg         = 'D'

if @@error <> 0 begin
   select @w_mensaje = 'Error Eliminando cob_credito..cr_dato_operacion Diario Credito/Cartera '
   goto ERRORFIN
end

insert into cr_dato_operacion (
do_fecha,                  do_tipo_reg,              do_numero_operacion,
do_numero_operacion_banco, do_tipo_operacion,        do_codigo_producto,
do_codigo_cliente,         do_oficina,               do_sucursal,
do_regional,               do_moneda,                do_monto,
do_tasa,                   do_periodicidad,          do_modalidad,
do_fecha_concesion,        do_fecha_vencimiento,     do_dias_vto_div,
do_fecha_vto_div,          do_reestructuracion,      do_fecha_reest,
do_num_cuota_reest,        do_no_renovacion,         do_codigo_destino,
do_clase_cartera,          do_codigo_geografico,     do_departamento,
do_tipo_garantias,         do_valor_garantias,       do_fecha_prox_vto,
do_saldo_prox_vto,         do_saldo_cap,             do_saldo_int,
do_saldo_otros,            do_saldo_int_contingente, do_saldo,
do_estado_contable,        do_estado_desembolso,     do_estado_terminos,
do_calificacion,           do_linea_credito,         do_suspenso,
do_suspenso_ant,           do_periodicidad_cuota,    do_edad_mora,
do_valor_mora,             do_fecha_pago,            do_valor_cuota,
do_cuotas_pag,             do_estado_cartera,        do_plazo_dias,
do_gerente,                do_num_cuotaven,          do_saldo_cuotaven,
do_admisible,              do_num_cuotas,            do_tipo_tarjeta,
do_clase_tarjeta,          do_tipo_bloqueo,          do_fecha_bloqueo,
do_fecha_cambio,           do_ciclo_fact,            do_valor_ult_pago,
do_fecha_castigo,          do_num_acta,              do_gracia_cap,
do_gracia_int,             do_probabilidad_default,  do_nat_reest,
do_num_reest,              do_acta_cas,              do_capsusxcor,             
do_intsusxcor,             do_clausula,              do_moneda_op
)
select 
do_fecha,                  'D',                      isnull((select op_operacion from cob_cartera..ca_operacion where op_banco = x.do_banco),0),
do_banco,                  do_tipo_operacion,        do_aplicativo,
do_codigo_cliente,         do_oficina,               do_oficina,
(select isnull(of_regional,1) from cobis..cl_oficina where x.do_oficina = of_oficina),
                           do_moneda,                do_monto,
do_tasa,                   do_periodicidad_cuota,    do_modalidad,
do_fecha_concesion,        do_fecha_vencimiento,     do_edad_mora,
do_fecha_prox_vto,         do_reestructuracion,      do_fecha_reest,
do_num_reest,              do_no_renovacion,         do_codigo_destino,
do_clase_cartera,          
(select of_ciudad from cobis..cl_oficina where of_oficina = x.do_oficina),                        
isnull((select isnull(ci_provincia,0) from cobis..cl_ciudad, cobis..cl_oficina where of_oficina = x.do_oficina and of_ciudad = ci_ciudad),0),
do_tipo_garantias,         do_valor_garantias,       do_fecha_prox_vto,        
0,                         do_saldo_cap,             do_saldo_int,                        
do_saldo_otros,            do_saldo_int_contingente, do_saldo,
do_estado_contable,        '1',                      'N',   
do_calificacion,           do_linea_credito,         null,                     
null,                      do_periodicidad_cuota,    do_edad_cod,              
do_valor_mora,             do_fecha_ult_pago,        do_valor_cuota,           
do_cuotas_pag,             null,                     do_plazo_dias,
do_oficial,                do_num_cuotaven,          do_saldo_cuotaven,
case when do_tipo_garantias = 'O' then 'N' else 'S' end, do_num_cuotas, null,
null,                      null,                     null,
null,                      null,                     do_valor_ult_pago,
do_fecha_castigo,          do_num_acta,              null,
null,                      null,                     do_nat_reest,
null,                      do_num_acta,              null,
null,                      do_clausula,              do_moneda
from cob_conta_super..sb_dato_operacion x
where do_fecha = @i_fecha

if @@error <> 0 begin
   select @w_mensaje = 'Error Generando <cr_dato_operacion> '
   goto ERRORFIN
end


return 0


ERRORFIN:

   select @w_mensaje = @w_sp_name + ' --> ' + @w_mensaje

   insert into cr_errorlog
   values (@i_fecha, @w_error, @w_usuario, 21000, 'CONSOLIDADOR', @w_mensaje)

   return 1


GO

