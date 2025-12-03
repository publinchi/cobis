/************************************************************************/
/*  Archivo:                cr_clipref.sp                               */
/*  Stored procedure:       sp_cliente_pref                             */
/*  Base de datos:          cob_credito                                 */
/*  Producto:               CREDITO                                     */
/*  Disenado por:           Johan F. Ardila R.                          */
/*  Fecha de escritura:     Septiembre 2010                             */
/************************************************************************/
/*                               IMPORTANTE                             */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  'MACOSA', representantes exclusivos para el Ecuador de la           */
/*  'NCR CORPORATION'.                                                  */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado hecho por alguno de sus             */
/*  usuarios sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de MACOSA o su representante.                 */
/*              PROPOSITO                                               */
/*  Permite el registro de clientes preferenciales. Campaña o Especiales*/
/*              MODIFICACIONES                                          */
/*  FECHA       AUTOR        RAZON                                      */
/*  10/Sep/10   J. Ardila    Emision Inicial                            */
/*  10/Feb/12   J. Zamora    Contraofertas                              */
/*  18/Feb/15   Acelis       Req 499 Carga de Clientes Especiales       */
/************************************************************************/
use cob_credito
go

if object_id ('sp_cliente_pref') is not null
begin
    drop proc sp_cliente_pref
end
go

create proc sp_cliente_pref(
   @s_ssn                  int         = NULL,
   @s_date                 datetime    = NULL,
   @s_user                 login       = NULL,
   @s_term                 descripcion = NULL,
   @s_corr                 char(1)     = NULL,
   @s_ssn_corr             int         = NULL,
   @s_ofi                  smallint    = NULL,
   @s_sesn                 int         = NULL,
   @s_srv                  varchar(30) = NULL,
   @s_lsrv                 varchar(30) = NULL,
   @t_rty                  char(1)     = NULL,
   @t_trn                  smallint    = NULL,
   @t_debug                char(1)     = 'N',
   @t_file                 varchar(14) = NULL,
   @i_cliente              int         = null,
   @i_campana              int         = null,
   @i_tipo_id              char(2)     = null,
   @i_no_id                catalogo    = null,
   @i_tipo_pref            catalogo,
   @i_fecha                datetime,
   @i_org_carga            char(3),     -- CCA Cartera o CAM Campañas   
   @i_oficina              int,
   @i_desde                varchar(50) = 'evaluar_cliente',
   @o_msg                  descripcion = null out
)
as
declare
   @w_sp_name       varchar(30),
   @w_tipo_campana  int,
   @w_campana       int,
   @w_inserta       char(1),
   @w_cliente       int,
   @w_msg           varchar(250),
   @w_msg_e         varchar(250),
   @w_tipo_pref     catalogo,
   @w_clientesc     varchar(10),
   @w_estado        char(1),
   @w_fecha_proceso datetime,
   @w_fecha_fin     datetime,
   @w_error         int,
   @w_asignado_a    varchar(60),
   @w_dias_bloq     int,
   @w_fecha_camp    datetime,
   @w_fecha_tot     datetime,
   @w_fecha_cierre  datetime,
   @w_cam_normali   int       --REQ499 Parametro tipo campaña de normalización
 
   
select 
   @w_sp_name   = 'sp_cliente_pref', 
   @w_inserta   = 'N',
   @w_campana   = @i_campana,
   @w_tipo_pref = @i_tipo_pref  
   
select @w_fecha_proceso = fp_fecha from cobis..ba_fecha_proceso

-- Se fija parametro tipo de campaña normalizacion 
select @w_cam_normali = 3


return 0

RESPUESTA:
select @o_msg = @w_msg


ERROR:   
select @o_msg = @w_msg
insert into cr_carga_campana_log 
   (cl_oficina,     cl_campana,  cl_cliente,
    cl_id,          cl_tipo_id,  cl_fecha_carga,
    cl_descripcion, cl_origen)
values 
   (@i_oficina,     @w_campana,  @w_cliente,
    @i_no_id,       @i_tipo_id,  @i_fecha,
    @w_msg,         @i_org_carga)

if @@error <> 0
begin

   select @w_msg_e = 'Error al Insertar Registro cr_carga_campana_log'
end

if @i_org_carga = 'CCA'
begin
   return 0
end

return 1
go

