/************************************************************************/
/*  Archivo:                cr_util0.sp                                 */
/*  Stored procedure:       sp_utiliz0                                  */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jose Ortiz                                  */
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
/*  SP contabilizacion lineas de credito                                */
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  23/04/19          Jose Ortiz       Emision Inicial                  */
/* **********************************************************************/
use cob_credito
go

IF OBJECT_ID ('dbo.sp_utiliz0') IS NOT NULL
	DROP PROCEDURE dbo.sp_utiliz0
GO

create proc sp_utiliz0(
   @s_ssn              int         = null,
   @s_user             login       = null,
   @s_sesn             int         = null,
   @s_term             descripcion = null,
   @s_date             datetime    = null,
   @s_srv              varchar(30) = null,
   @s_lsrv             varchar(30) = null,
   @s_rol              smallint    = null,
   @s_ofi              smallint    = null,
   @t_trn              smallint    = null,
   @t_debug            char(1)     = 'N',
   @t_file             varchar(14) = null,
   @t_from             varchar(30) = null,
   -- [D]ESEMBOLSO [R]ECUPERACION [C]ONTROL
   -- [Y]REVERSO PAGO, [X]REVERSO DESEMBOLSO
   @i_tipo             char(1)     = null,
   @i_linea            int         = null,
   @i_linea_banco      cuenta      = null,
   @i_producto         char(4)     = null,
   @i_toperacion       catalogo    = null,
   @i_moneda           tinyint     = null,
   @i_monto            money       = null,
   @i_tramite          int         = null,
   @i_cliente          int         = null,
   @i_moneda_linea     tinyint     = null,
   -- Incluir financiamientos
   @i_opcion           char(1)     = null,   -- P=Pasiva, A=Activa
   @i_valida_sobrepasa char(1)     = 'N',
   @i_valida           tinyint     = null,
   @i_modo_sobrepasa   tinyint     = 0,
   @i_tipo_tramite     char(1)     = null,
   @i_opecca           int         = null,
   @i_fecha_valor      datetime    = null,
   @i_secuencial       int         = 0,
   @i_modo             tinyint     = null,
   @i_monto_cex        money       = null,
   @i_numoper_cex      cuenta      = null,
   @i_batch            char(1)     = 'N',
   @i_tramite_unif     int         = null,  -- JAR REQ 215. Paquete2. Cupos
   @i_tipo_tram_unif   char(1)     = null   -- JAR REQ 215. Paquete2. Cupos
)
as
declare
   @w_today                   datetime,       -- FECHA DEL DIA
   @w_sp_name                 varchar(32),    -- NOMBRE STORED PROC
   @w_fecha_aprob             datetime,       -- FECHA DE APROB DE LINEA
   @w_fecha_vence             datetime,       -- FECHA VENC. DE LINEA
   @w_moneda_linea            tinyint,        -- ct_moneda DE LA LINEA
   @w_rotativa                char(1),        -- DATO DE LA LINEA
   @w_monto_linea             money,          -- MONTO DE LA LINEA
   @w_utilizado_linea         money,          -- UTILIZADO DE LA LINEA
   @w_reservado_linea         money,          -- UTILIZADO DE LA LINEA
   @w_disponible_linea        money,          -- DISPONIBLE DE LA LINEA
   @w_monto_local             money,          -- CALCULO TEMPORAL
   @w_def_moneda              tinyint,        -- moneda LOCAL
   @w_monto_reservado         money,          -- MONTO EN TRAMITE
   @w_tipo_tramite            char(1),        -- TIPO DE TRAMITE
   @w_monto_renovaciones      money,    -- DIFERENCIA EN MONTO PARA RENOVACIONES
   @w_grupo                   int,
   @w_monto_toperacion        money,
   @w_utilizado_toperacion    money,
   @w_reservado_toperacion    money,
   @w_disponible_toperacion   money,
   @w_monto_cliente           money,
   @w_utilizado_cliente       money,
   @w_reservado_cliente       money,
   @w_disponible_cliente      money,
   @w_tramite                 int,
   @w_monto_cont              money,
   @w_contabilizado           char(1),
   @w_contabilizado_des       char(1),
   @w_moneda_des              tinyint,   -- ct_moneda del desembolso
   @w_return                  int,
   @w_opcion                  tinyint,
   @w_psob                    float,     -- Porcentaje de sobrepasamiento
   @w_msob                    money,     -- Monto maximo de sobrepasamiento
   @w_montoc_psob             money,
   @w_montoc_falta            money,
   @w_montol_psob             money,
   @w_montol_falta            money,
   @w_sobrepasa               char(1),
   @w_estado                  char(1),
   @w_monto_otros             money,
   @w_utilizado_otros         money,
   @w_reservado_otros         money,
   @w_gru_cliente     int,
   @w_sectoreco               catalogo,
   @w_max_ries_grupo          money,
   @w_ries_grupo              money,
   @w_ries_reservado_grupo    money,
   @w_ries_disp_grupo         money,
   @w_max_ries_sector         money,
   @w_ries_sector             money,
   @w_ries_reservado_sector   money,
   @w_ries_disp_sector        money,
   @w_operacion               char(1),
   @w_cliente                 int,
   @w_est_tramite             char(1),
   @w_max_ries_cliente        money,
   @w_ries_cliente            money,
   @w_ries_reservado_cliente  money,
   @w_ries_disp_cliente       money,
   @w_riesgo_actual           money,
   @w_producto                varchar(3),
   @w_plazo                   int,
   @w_tmp_plazo               char(10),
   @w_fecha_fin               datetime,
   @w_fecha_ini               datetime,
   @w_entramite_cliente       money,
   @w_entramite_grupo         money,
   @w_entramite_sector        money,
   @w_entramite_rcliente      money,
   @w_tipo_linea              char(1),
   @w_toperacion_cex          catalogo,
   @w_moneda_cex              tinyint,
   @w_monto_cex               money,
   @w_producto_cex            varchar(3),
   @w_local_utiliz            money,
   @w_local_reserv            money,
   @w_toper_utiliz            money,
   @w_toper_reserv            money,
   @w_ries_utiliz             money,
   @w_ries_reserv             money,
   @w_num_cupo                int,
   @w_paramcem                char(1),
   @w_i_producto              catalogo,
   @w_monto_tram_dis          money,
   @w_tramite_dis             int,
   @w_toperacion_dis          cuenta,
   @w_rowcount                int,
   @w_estado_operacion        int,
   @w_vigente                 char(1),
   @w_error                   int,
   @w_commit                  char(1),
   @w_min_ca_secuencial       INT
   



select
@w_sp_name = 'sp_utiliz0',
@w_commit  = 'N'

select @w_contabilizado_des = 'N'

select @w_i_producto = @i_producto

if @i_fecha_valor = '01/01/1900'
   select @i_fecha_valor = @s_date

--- OBTENCION DE DATOS INICIALES
--SELECCION DE CODIGO DE ct_moneda LOCAL

select @w_def_moneda = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'CRE'
and    pa_nemonico = 'MLOCR'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0
begin
   select @w_error = 2101005
   goto ERROR
end

select  @w_paramcem = pa_char
from    cobis..cl_parametro
where   pa_producto = 'CRE'
and     pa_nemonico  = 'CEM'
set transaction isolation level read uncommitted

if @i_tramite is not null and @i_fecha_valor is not null and @i_tipo = 'D'
begin

   select @w_num_cupo = tr_linea_credito
   from  cr_tramite
   where tr_tramite = @i_tramite

   if exists ( select 1 from cr_tramite
               where tr_tramite    in (select li_tramite  from cob_credito..cr_linea
                                       where  li_numero  = @w_num_cupo )
                                       and   tr_asociativo =  'S' )
   BEGIN
   
      select @w_min_ca_secuencial = min(ca_secuencial) from cr_ctrl_cupo_asoc
                             where ca_num_cupo = @w_num_cupo
                             and   ca_fecha_desembolso is NULL
                                   
      update cr_ctrl_cupo_asoc
      set ca_fecha_desembolso = @i_fecha_valor
      where ca_num_cupo   = @w_num_cupo
/*      and   ca_secuencial = (select min(ca_secuencial) from cr_ctrl_cupo_asoc
                             where ca_num_cupo = @w_num_cupo
                             and   ca_fecha_desembolso is null)*/ --LPO CDIG MySql no soporta abrir la misma tabla en una misma sentencia
        AND ca_secuencial = @w_min_ca_secuencial  --LPO CDIG MySql no soporta abrir la misma tabla en una misma sentencia
        
   end
end

if @i_tramite is not null  and @i_tipo = 'X'
begin

   select @w_num_cupo = tr_linea_credito
   from  cr_tramite
   where tr_tramite = @i_tramite

   if exists ( select 1 from cr_tramite
                 where tr_tramite in (select li_tramite  from cob_credito..cr_linea
                               where  li_numero  = @w_num_cupo )
                and   tr_asociativo = 'S')
   BEGIN

      select @w_min_ca_secuencial = (select max(ca_secuencial) from cr_ctrl_cupo_asoc
                          where ca_num_cupo = @w_num_cupo
                             and   ca_fecha_desembolso is not null)   

      update cr_ctrl_cupo_asoc
      set ca_fecha_desembolso = null
      where ca_num_cupo   = @w_num_cupo
/*      and   ca_secuencial = (select max(ca_secuencial) from cr_ctrl_cupo_asoc
                          where ca_num_cupo = @w_num_cupo
                             and   ca_fecha_desembolso is not null)*/ --LPO CDIG MySql no soporta abrir la misma tabla en una misma sentencia
      and   ca_secuencial = @w_min_ca_secuencial  --LPO CDIG MySql no soporta abrir la misma tabla en una misma sentencia
                             
   end
end

if @i_tramite is not null
begin

   select 
   @w_cliente      = tr_cliente,
   @w_producto     = tr_producto,
   @w_est_tramite  = tr_estado,
   @w_fecha_ini    = tr_fecha_crea,
   @w_tipo_tramite = tr_tipo,
   @w_sobrepasa    = tr_sobrepasa
   from cr_tramite
   where tr_tramite = @i_tramite
   
   if @@rowcount = 0
   begin
      select @w_error = 2101005
      goto ERROR
   end

   if @i_opcion = 'A'
   begin

      if @w_cliente is not null
         select @i_cliente = @w_cliente
      else
      begin
         select @w_error = 2101001
         goto ERROR
      end
   end


  select @w_toperacion_cex = null

  if (@w_tipo_tramite = 'F') and (@i_numoper_cex is not null)
  begin

     if @i_linea is null
        select @i_linea = li_numero
        from cr_linea
        where li_num_banco = @i_linea_banco

     select @w_toperacion_cex = tr_toperacion,
     @w_moneda_cex   = tr_moneda,
     @w_producto_cex = tr_producto
     from cr_tramite
     where tr_linea_credito = @i_linea
     and tr_numero_op_banco = @i_numoper_cex

     if @@rowcount = 0
     begin
        select @w_error = 2101005
        goto ERROR
     end
  end
end

--- OBTENER EL NUMERO DE LA LINEA Y DATOS DE LA LINEA
--- SI MANDA COMO PARAMETRO EL NUM. BANCO
if @i_linea is null
begin
   select
   @i_linea           = li_numero
   from cr_tramite, cr_linea
   where tr_tramite   = li_tramite
   and   li_num_banco = @i_linea_banco   

   select
   @i_linea           = li_numero,
   @w_fecha_aprob     = li_fecha_aprob,
   @w_fecha_vence     = li_fecha_vto,
   @w_monto_linea     = isnull(li_monto,0),
   @w_utilizado_linea = isnull(li_utilizado,0),
   @w_moneda_linea    = li_moneda,
   @w_rotativa        = li_rotativa,
   @w_tramite         = li_tramite,
   @w_contabilizado   = tr_contabilizado,
   @w_estado          = li_estado,
   @w_grupo           = li_grupo,
   @w_reservado_linea = isnull(li_reservado,0),
   @w_tipo_linea      = li_tipo
   from cr_tramite,cr_linea
   where tr_tramite   = li_tramite
   and   li_num_banco = @i_linea_banco

   if @@rowcount = 0
   begin
      select @w_error = 2101005
      goto ERROR
   end
end
else
begin
   select
   @i_linea_banco     = li_num_banco,
   @w_fecha_aprob     = li_fecha_aprob,
   @w_fecha_vence     = li_fecha_vto,
   @w_monto_linea     = isnull(li_monto,0),
   @w_utilizado_linea = isnull(li_utilizado,0),
   @w_moneda_linea    = li_moneda,
   @w_rotativa        = li_rotativa,
   @w_tramite         = li_tramite,
   @w_contabilizado   = tr_contabilizado,
   @w_estado          = li_estado,
   @w_grupo           = li_grupo,
   @w_reservado_linea = isnull(li_reservado,0),
   @w_tipo_linea      = li_tipo
   from   cr_tramite, cr_linea
   where  tr_tramite   = li_tramite
   and  li_numero      = @i_linea

   if @@rowcount = 0
   begin
      select @w_error = 2101005
      goto ERROR
   end
end

--- DATOS DEL CLIENTE SI EL CUPO ES DE GRUPO
if @w_grupo is not null
begin
   select
   @w_monto_cliente = lg_monto,
   @w_utilizado_cliente = isnull(lg_utilizado,0),
   @w_reservado_cliente = isnull(lg_reservado,0)
   from cr_lin_grupo
   where lg_linea = @i_linea
   and lg_cliente = @i_cliente

   if @@rowcount = 0
   begin
      select @w_error = 2101065
      goto ERROR
   end
end

--- SELECCION DE DATOS DEL CLIENTE
if @i_cliente is not null
begin
   select
   @w_gru_cliente = en_grupo,
   @w_sectoreco = en_sector,
   @w_max_ries_cliente = isnull(en_max_riesgo, 0),
   @w_ries_cliente = isnull(en_riesgo, 0),
   @w_ries_reservado_cliente = isnull(en_reservado, 0)
   from cobis..cl_ente
   where en_ente = @i_cliente
   set transaction isolation level read uncommitted

   select @w_ries_disp_cliente       =  isnull(@w_ries_disp_cliente,0)
   select @w_max_ries_cliente        =  isnull(@w_max_ries_cliente,0)
   select @w_ries_cliente            =  isnull(@w_ries_cliente,0)
   select @w_ries_reservado_cliente  =  isnull(@w_ries_reservado_cliente,0)
   select @w_ries_disp_cliente       =  @w_max_ries_cliente - @w_ries_cliente - @w_ries_reservado_cliente
end

if @w_gru_cliente is not null
begin
    select
    @w_max_ries_grupo = isnull(gr_max_riesgo, 0),
    @w_ries_grupo = isnull(gr_riesgo, 0),
    @w_ries_reservado_grupo = isnull(gr_reservado, 0)
    from cobis..cl_grupo
    where gr_grupo = @w_gru_cliente
    set transaction isolation level read uncommitted

    select @w_ries_disp_grupo = @w_max_ries_grupo - @w_ries_grupo - @w_ries_reservado_grupo
end

if @w_sectoreco is not null
begin
    select
    @w_max_ries_sector = isnull(se_max_riesgo, 0),
    @w_ries_sector = isnull(se_riesgo, 0),
    @w_ries_reservado_sector = isnull(se_reservado, 0)
    from cobis..cl_sectoreco
    where se_sector = @w_sectoreco

    select @w_ries_disp_sector = @w_max_ries_sector - @w_ries_sector - @w_ries_reservado_sector
end

--- VALIDACIONES SOBRE LA LINEA COMPROBAR QUE LA LINEA ESTE APROBADA
if @w_fecha_aprob is NULL
begin
   select @w_error = 2101025
   goto ERROR
end

--- COMPROBAR QUE LA LINEA NO ESTE VENCIDA
if (@w_fecha_vence is NULL or @w_fecha_vence < @s_date) and
   (@i_tipo not in ('R','Y')) and
   (@w_tipo_tramite <> 'F')   and
   (@w_tipo_linea <> 'O')
begin
   select @w_error = 2101026
   goto ERROR
end

--- COMPROBAR QUE LA LINEA NO ESTE BLOQUEADA
if (@w_estado = 'B') and (@i_tipo not in ('Y','X','R'))  and
   (@w_tipo_tramite <> 'F')
begin
   select @w_error = 2101117
   goto ERROR
end

--- INCIALIZACION DE MONTOS
select
@w_monto_toperacion       = isnull(@w_monto_toperacion,0),
@w_utilizado_toperacion   = isnull(@w_utilizado_toperacion,0),
@w_reservado_toperacion   = isnull(@w_reservado_toperacion,0),
@w_monto_cliente          = isnull(@w_monto_cliente, 0),
@w_utilizado_cliente      = isnull(@w_utilizado_cliente, 0),
@w_reservado_cliente      = isnull(@w_reservado_cliente,0)

-- TRANSFORMAR A ct_moneda LOCAL DATOS DE LA LINEA
if @w_moneda_linea <> @w_def_moneda
begin
   select
   @w_monto_linea       = isnull(@w_monto_linea * cv_valor,0),
   @w_utilizado_linea   =  isnull(@w_utilizado_linea * cv_valor,0),
   @w_reservado_linea   =  isnull(@w_reservado_linea * cv_valor,0)
   from cob_conta..cb_vcotizacion
   where cv_moneda = @w_moneda_linea
   and cv_fecha = (select max(cv_fecha)
                   from   cob_conta..cb_vcotizacion
                   where  cv_moneda = @w_moneda_linea
                   and cv_fecha <= isnull(@i_fecha_valor, @s_date))

   if @w_monto_linea is null
   begin
      select @w_error = 2101003
      goto ERROR
   end
end

-- TRANSFORMAR A ct_moneda LOCAL LOS DATOS DE LA OPERACION
if @i_moneda <> @w_def_moneda
begin
   select
   @w_monto_local =  isnull(@i_monto * cv_valor,0)
   from cob_conta..cb_vcotizacion
   where cv_moneda = @i_moneda
   and cv_fecha = (select max(cv_fecha)
                   from   cob_conta..cb_vcotizacion
                   where  cv_moneda = @i_moneda
                   and cv_fecha <= isnull(@i_fecha_valor, @s_date))

   if @w_monto_local is null
   begin
      select @w_error = 2101003
      goto ERROR
   end

   select
   @w_monto_toperacion     =  isnull(@w_monto_toperacion * cv_valor, 0),
   @w_utilizado_toperacion = isnull(@w_utilizado_toperacion * cv_valor, 0),
   @w_reservado_toperacion = isnull(@w_reservado_toperacion * cv_valor, 0)
   from cob_conta..cb_vcotizacion
   where cv_moneda = @i_moneda
   and cv_fecha = (select max(cv_fecha)
                   from   cob_conta..cb_vcotizacion
                   where  cv_moneda = @i_moneda
                   and cv_fecha <= isnull(@i_fecha_valor, @s_date))

   if @w_monto_toperacion is null
   begin
      select @w_error = 2101003
      goto ERROR
   end

end
else
   select @w_monto_local = @i_monto

--- Monto de Riesgo Actual
select @w_riesgo_actual = @w_monto_local

-- TRANSFORMAR A ct_moneda LOCAL LOS DATOS DEL CLIENTE
if @w_moneda_linea <> @w_def_moneda
begin
   select
   @w_monto_cliente      =  isnull(@w_monto_cliente * cv_valor, 0),
   @w_utilizado_cliente  =  isnull(@w_utilizado_cliente * cv_valor, 0),
   @w_reservado_cliente  =  isnull(@w_reservado_cliente * cv_valor, 0)   --SBU  CD00054
   from cob_conta..cb_vcotizacion
   where cv_moneda = @w_moneda_linea
   and cv_fecha = (select max(cv_fecha)
                   from   cob_conta..cb_vcotizacion
                   where  cv_moneda = @w_moneda_linea
                   and cv_fecha <= isnull(@i_fecha_valor, @s_date))

   if @w_monto_cliente is null
   begin
      select @w_error = 2101003
      goto ERROR
   end
end

if (@i_tipo in ('D','R', 'X', 'Y')) and (@w_tipo_linea <> 'S')
begin
   --- BUSCAR INDICADOR DE CONTABILIZADO DE TRAMITE DE DESEMBOLSO
   if @i_tramite is not null
   begin
      select
      @w_contabilizado_des = tr_contabilizado,
      @w_moneda_des        = tr_moneda,
      @w_est_tramite       = tr_estado
      from cr_tramite
      where tr_tramite = @i_tramite

      if @@rowcount = 0
      begin
         select @w_error = 2101005
         goto ERROR
      end
   end
   else
      select @w_contabilizado_des = 'N',
             @w_moneda_des = @i_moneda

   select @w_monto_cont = @w_monto_local

   if (@w_moneda_des <> @w_def_moneda) and (@i_tipo in ('D','Y'))
   begin
      select
      @w_monto_cont =  isnull(@w_monto_cont / cv_valor, 0)
      from cob_conta..cb_vcotizacion
      where cv_moneda = @w_moneda_des
      and cv_fecha = (select max(cv_fecha)
                      from   cob_conta..cb_vcotizacion
                      where  cv_moneda = @w_moneda_des
                      and cv_fecha <= isnull(@i_fecha_valor, @s_date))
   end

   -- TRANSFORMAR A ct_moneda DE LA LINEA
   if @w_moneda_linea <> @w_def_moneda and @i_tipo in ('R', 'X')
   begin
      select
      @w_monto_cont =  isnull(@w_monto_cont / cv_valor, 0)
      from cob_conta..cb_vcotizacion
      where cv_moneda = @w_moneda_linea
      and cv_fecha = (select max(cv_fecha)
                      from   cob_conta..cb_vcotizacion
                      where  cv_moneda = @w_moneda_linea
                      and cv_fecha <= isnull(@i_fecha_valor, @s_date))
   end

   -- TRANSFORMAR A ct_moneda DE LA LINEA
   if @w_moneda_linea <> @w_def_moneda
   begin
      select
      @w_monto_local = isnull(@w_monto_local/cv_valor, 0)
      from   cob_conta..cb_vcotizacion
      where  cv_moneda = @w_moneda_linea
      and cv_fecha = (select max(cv_fecha)
                      from   cob_conta..cb_vcotizacion
                      where  cv_moneda = @w_moneda_linea
                      and cv_fecha <= isnull(@i_fecha_valor, @s_date))
   end

   if @i_tipo in ('D', 'X')
   begin
      if @w_producto = 'CEX'
         select @w_local_utiliz = 0,
                @w_toper_utiliz = 0,
                @w_ries_utiliz  = 0,
                @w_local_reserv = -1 * @w_monto_local,
                @w_toper_reserv = -1 * @i_monto,
                @w_ries_reserv  = -1 * @w_riesgo_actual

      if @w_producto = 'CCA'
         select @w_local_utiliz = @w_monto_local,
                @w_toper_utiliz = @i_monto,
                @w_ries_utiliz  = @w_riesgo_actual,
                @w_local_reserv = @w_monto_local,
                @w_toper_reserv = @i_monto,
                @w_ries_reserv  = @w_riesgo_actual

      if @w_producto not in ('CCA','CEX')
         select @w_local_utiliz = @w_monto_local,
                @w_toper_utiliz = @i_monto,
                @w_ries_utiliz  = @w_riesgo_actual,
                @w_local_reserv = 0,
                @w_toper_reserv = 0,
                @w_ries_reserv  = 0

   end

   if @i_tipo in ('Y', 'R')
   begin
      if @w_producto = 'CEX'
         select @w_local_utiliz = 0,
                @w_toper_utiliz = 0,
                @w_ries_utiliz   = 0,
                @w_local_reserv = @w_monto_local,
                @w_toper_reserv = @i_monto,
                @w_ries_reserv  = @w_riesgo_actual
      else
         select @w_local_utiliz = @w_monto_local,
                @w_toper_utiliz = @i_monto,
                @w_ries_utiliz   = @w_riesgo_actual,
                @w_local_reserv = 0,
                @w_toper_reserv = 0,
                @w_ries_reserv  = 0
   end
end

if @i_tipo = 'A'
begin
   select @w_local_utiliz = 0,
          @w_toper_utiliz = 0,
          @w_ries_utiliz   = 0,
          @w_local_reserv = @w_monto_local,
          @w_toper_reserv = @i_monto,
          @w_ries_reserv  = @w_riesgo_actual
end

---- EJECUCION DE CADA PROCESO, SI OPERACION ES D (DESEMBOLSO)
if (@i_tipo = 'D')
begin
   if @i_batch <> 'S' and @@trancount = 0 begin
      begin tran
      select @w_commit = 'S'
   end

   -- ACTUALIZAR LA TABLA CR_LINEA, CAMPOS LI_UTILIZADO, LI_RESERVADO
   update cr_linea set
   li_utilizado = isnull(li_utilizado, 0) + @w_local_utiliz,
   li_reservado = isnull(li_reservado, 0) - @w_local_utiliz
   where  li_numero = @i_linea

   if @@error <> 0
   begin
      select @w_error = 2105012
      goto ERROR
   end


   if exists (select 1
              from   cr_lin_ope_moneda
              where  om_linea = @i_linea
              and    om_toperacion = @i_toperacion
              and    om_producto = @w_i_producto
              and    om_moneda = @i_moneda)
   begin
      -- ACTUALIZACION EN CR_LIN_OPE_moneda
      update cr_lin_ope_moneda set
      om_utilizado = isnull(om_utilizado, 0) + @w_toper_utiliz,
      om_reservado = isnull(om_reservado, 0) - @w_toper_utiliz
      where  om_linea      = @i_linea
      and    om_toperacion = @i_toperacion
      and    om_producto   = @w_i_producto
      and    om_moneda     = @i_moneda

      if @@error <> 0
      begin
         select @w_error = 2105013
         goto ERROR
      end
   end

   -- ACTUALIZAR LA TABLA CR_LIN_GRUPO
   if @w_grupo is not null
   begin
      if exists (select 1
                 from  cr_lin_grupo
                 where lg_linea = @i_linea
                 and   lg_cliente = @i_cliente)
      begin
         update cr_lin_grupo set
         lg_utilizado = isnull(lg_utilizado, 0) + @w_local_utiliz
         where  lg_linea = @i_linea
         and    lg_cliente = @i_cliente

         if @@error <> 0
         begin
            select @w_error = 2105017
            goto ERROR
         end
      end
   end --GRUPO NO ES NULO

   -- VERIFICAR EXISTENCIA DE REGISTRO EN CR_LIN_OPE_moneda PARA ACTUALIZAR UTILIZACION POR PRODUCTOS

   if @w_commit = 'S' begin
      commit tran
      select @w_commit = 'N'
   end
end --TIPO = D (DESEMBOLSO)


--- SI OPERACION ES Y (REVERSA DE PAGO)
if @i_tipo = 'Y'
begin
   if @i_batch <> 'S' and @@trancount = 0 begin
      begin tran
      select @w_commit = 'S'
   end

   -- SI ES ROTATIVA SE RESTA EL MONTO DE RECUPERACION AL UTILIZADO Y SE ACTUALIZA EL REGISTRO
   if @w_rotativa = 'S'
   begin
      -- ACTUALIZAR LA TABLA CR_LINEA, CAMPOS LI_UTILIZADO, LI_RESERVADO
      update cr_linea set
      li_utilizado = isnull(li_utilizado, 0) + @w_local_utiliz
      --li_reservado = isnull(li_reservado, 0) + @w_local_reserv
      where  li_numero = @i_linea

      if @@error <> 0
      begin
         select @w_error = 2105012
         goto ERROR
      end

      -- ACTUALIZAR LA TABLA CR_LIN_GRUPO
      if @w_grupo is not null
      begin
         if exists (select 1
                    from  cr_lin_grupo
                    where lg_linea = @i_linea
                    and   lg_cliente = @i_cliente)
         begin
            update cr_lin_grupo set
            lg_utilizado = isnull(lg_utilizado, 0) + @w_local_utiliz,
            lg_reservado = isnull(lg_reservado, 0) + @w_local_reserv    --SBU  CD00054
            where  lg_linea = @i_linea
            and    lg_cliente = @i_cliente

            if @@error <> 0
            begin
               select @w_error = 2105017
               goto ERROR
            end
         end
      end

      -- VERIFICAR EXISTENCIA DE REGISTRO EN CR_LIN_OPE_moneda  PARA ACTUALIZAR UTILIZACION POR PRODUCTOS
      if exists (select 1
                 from   cr_lin_ope_moneda
                 where  om_linea = @i_linea
                 and    om_toperacion = @i_toperacion
                 and    om_producto = @w_i_producto
                 and    om_moneda = @i_moneda)
      begin
         -- ACTUALIZACION EN CR_LIN_OPE_moneda         
         update cr_lin_ope_moneda set
         om_utilizado = isnull(om_utilizado, 0) + @w_toper_utiliz         
         --om_reservado = isnull(om_reservado, 0) + @w_toper_reserv
         where  om_linea = @i_linea
         and om_toperacion = @i_toperacion
         and om_producto = @w_i_producto
         and om_moneda = @i_moneda

         if @@error <> 0
         begin
            select @w_error = 2105013
            goto ERROR
         end
      end

      if (@w_contabilizado_des = 'S')
      begin
         select @w_monto_cont = @w_monto_cont * (-1),
              @w_operacion = 'R'

         exec @w_return  = sp_cont_tramite
         @s_user        = @s_user,
         @s_date        = @s_date,
         @s_term        = @s_term,
         @s_ofi         = @s_ofi,
         @i_tramite     = @i_tramite,
         @i_operacion   = @w_operacion,
         @i_monto       = @w_monto_cont,
         @i_fecha_valor  = @i_fecha_valor,
         @i_secuencial   = @i_secuencial,
         @i_origen       = 'D'

         if @w_return != 0
            return @w_return

      end
   end --ROTATIVA

   --- Actualizar el maximo riesgo del grupo si el cliente  pertenece
   --- a alg+n grupo economico, y de igual manera al sector economico
   if (@w_gru_cliente is not null and @i_valida is null) and @w_paramcem = 'S'
   begin
      update cobis..cl_grupo
      set gr_riesgo = isnull(gr_riesgo,0) + isnull(@w_ries_utiliz,0),
      gr_reservado = isnull(gr_reservado,0) + isnull(@w_ries_reserv,0)
      where gr_grupo = @w_gru_cliente

      if @@error <> 0
      begin
         select @w_error = 2105001
         goto ERROR
      end
   end -- Fin de grupo is not null

   if (@w_sectoreco is not null and @i_valida is null) and @w_paramcem = 'S'
   begin
      update cobis..cl_sectoreco
      set se_riesgo = isnull(se_riesgo,0) + isnull(@w_ries_utiliz,0),
      se_reservado = isnull(se_reservado, 0) + isnull(@w_ries_reserv,0)
      where se_sector = @w_sectoreco

      if @@error <> 0
      begin
         select @w_error = 2105001
         goto ERROR
      end
   end  -- Fin de sectoreco is not null

   if (@i_cliente is not null and @i_valida is null)      and @w_paramcem = 'S'
   begin
      update cobis..cl_ente
      set en_riesgo = isnull(en_riesgo,0) + isnull(@w_ries_utiliz,0),
          en_reservado = isnull(en_reservado, 0) + isnull(@w_ries_reserv,0)
      where en_ente = @i_cliente

      if @@error <> 0
      begin
         select @w_error = 2105001
         goto ERROR
      end
   end  -- Fin de cliente is not null
   if @w_commit = 'S' begin
      commit tran
      select @w_commit = 'N'
   end
end

--- SI OPERACION ES X (REVERSA DE DESEMBOLSO)
if (@i_tipo = 'X')
begin
   if @i_batch <> 'S' and @@trancount = 0 begin
      begin tran
      select @w_commit = 'S'
   end

   -- ACTUALIZAR LA TABLA CR_LINEA, CAMPOS LI_UTILIZADO, LI_RESERVADO
   update cr_linea set
   li_utilizado = isnull(li_utilizado, 0) - @w_local_utiliz,
   li_reservado = isnull(li_reservado, 0) + @w_local_reserv
   where  li_numero = @i_linea

   if @@error <> 0
   begin
      select @w_error = 2105012
      goto ERROR
   end

   if @w_grupo is not null
   begin
      -- ACTUALIZAR LA TABLA CR_LIN_GRUPO
      update cr_lin_grupo set
      lg_utilizado = isnull(lg_utilizado, 0) - @w_local_utiliz,
      lg_reservado = isnull(lg_reservado, 0) + @w_local_reserv
      where  lg_linea = @i_linea
      and    lg_cliente = @i_cliente

      if @@error <> 0
      begin
         select @w_error = 2105017
         goto ERROR
      end
   end

   -- ACTUALIZAR LA TABLA CR_LIN_OPE_moneda
   if exists (select 1
              from   cr_lin_ope_moneda
              where  om_linea = @i_linea
              and    om_toperacion = @i_toperacion
              and    om_producto = @w_i_producto
              and    om_moneda = @i_moneda)
   begin
      update cr_lin_ope_moneda set
      om_utilizado = om_utilizado - @w_toper_utiliz
      where  om_linea = @i_linea
      and om_toperacion = @i_toperacion
      and om_producto = @w_i_producto
      and om_moneda = @i_moneda

      if @@error  <>  0
      begin
         select @w_error = 2105013
         goto ERROR
      end
   end

   --- ACTUALIZAR EL RESERVADO
   if (@w_tipo_tramite = 'F') and (@w_toperacion_cex is not null)
   begin
      if exists (select 1
               from   cr_lin_ope_moneda
               where  om_linea = @i_linea
               and    om_toperacion = @w_toperacion_cex
               and    om_producto = @w_producto_cex
               and    om_moneda = @w_moneda_cex)
      begin
         -- ACTUALIZACION EN CR_LIN_OPE_moneda
         update cr_lin_ope_moneda set
         om_reservado = isnull(om_reservado, 0) + @i_monto_cex
         where  om_linea = @i_linea
         and om_toperacion = @w_toperacion_cex
         and om_producto = @w_producto_cex
         and om_moneda = @w_moneda_cex

         if @@error <> 0
         begin
            select @w_error = 2105013
            goto ERROR
         end
      end
   end
   else
   begin
      if exists (select 1
               from   cr_lin_ope_moneda
               where  om_linea = @i_linea
               and    om_toperacion = @i_toperacion
               and    om_producto = @w_i_producto
               and    om_moneda = @i_moneda)
      begin
         -- ACTUALIZACION EN CR_LIN_OPE_moneda
         update cr_lin_ope_moneda set
         om_reservado = isnull(om_reservado, 0) + @w_toper_reserv
         where  om_linea = @i_linea
         and om_toperacion = @i_toperacion
         and om_producto = @w_i_producto
         and om_moneda = @i_moneda

         if @@error <> 0
         begin
            select @w_error = 2105013
            goto ERROR
         end
      end
   end

   if (@w_contabilizado_des = 'S' and @w_contabilizado = 'S') or (@w_tipo_linea = 'S')
   begin
      select @w_monto_cont = @w_monto_cont * (-1),
      @w_operacion = 'R'

      exec @w_return = sp_cont_tramite
      @s_user        = @s_user,
      @s_date        = @s_date,
      @s_term        = @s_term,
      @s_ofi         = @s_ofi,
      @i_tramite     = @i_tramite,
      @i_operacion   = @w_operacion,
      @i_monto       = @w_monto_cont,
      @i_fecha_valor = @i_fecha_valor,
      @i_secuencial  = @i_secuencial,
      @i_origen        = 'P'

      if @w_return != 0
      return @w_return
   end
   --- Actualizo el maximo riesgo  del grupo  si el cliente pertenece
   --- a alg+n grupo economico, y de igual manera al sector economico
   if (@w_gru_cliente is not null and @i_valida is null) and @w_paramcem = 'S'
   begin
      update cobis..cl_grupo
      set gr_riesgo = isnull(gr_riesgo, 0) - @w_ries_utiliz,
      gr_reservado = isnull(gr_reservado, 0) + @w_ries_reserv
      where gr_grupo = @w_gru_cliente

      if @@error <> 0
      begin
         select @w_error = 2105001
         goto ERROR
      end
   end -- Fin de grupo is not null

   if (@w_sectoreco is not null and @i_valida is null) and @w_paramcem = 'S'
   begin
      update cobis..cl_sectoreco
      set se_riesgo = isnull(se_riesgo, 0) -  @w_ries_utiliz,
      se_reservado = isnull(se_reservado, 0) + @w_ries_reserv
      where se_sector = @w_sectoreco

      if @@error <> 0
      begin
         select @w_error = 2105001
         goto ERROR
      end
   end  -- Fin de sectoreco is not null

   if (@i_cliente is not null and @i_valida is null) and @w_paramcem = 'S'
   begin
      update cobis..cl_ente
      set en_riesgo = isnull(en_riesgo, 0) -  @w_ries_utiliz,
      en_reservado = isnull(en_reservado, 0) + @w_ries_reserv
      where en_ente = @i_cliente

      if @@error <> 0
      begin
         select @w_error = 2105001
         goto ERROR
      end
   end  -- Fin de cliente is not null
   if @w_commit = 'S' begin
      commit tran
      select @w_commit = 'N'
   end
end

--- SI OPERACION ES R (RECUPERACION)
if (@i_tipo = 'R')
begin

   select @w_vigente ='N'

   select @w_estado_operacion = op_estado
   from cob_cartera..ca_operacion
   where op_tramite = @i_tramite

   if exists (select * from cob_cartera..ca_operacion,cob_credito..cr_tramite
              where  op_cliente = @i_cliente
              and    op_tramite = tr_tramite
              and    op_estado  not in (99, 0, 6)
              and    tr_tipo    = 'U')

      select @w_vigente ='S'

   if @i_batch <> 'S' and @@trancount = 0 begin
      begin tran
      select @w_commit = 'S'
   end
   
   -- SI ES ROTATIVA SE RESTA EL MONTO DE RECUPERACION AL UTILIZADO Y SE ACTUALIZA EL REGISTRO
   if @w_rotativa = 'S'
   begin
      --if (@w_estado_operacion <> 3 and @w_tipo_tramite='T' and @w_vigente ='N') or (@w_tipo_tramite='U' and @w_vigente ='S' and @w_estado_operacion <> 3) begin
      if (@w_tipo_tramite='T' and @w_vigente ='N') or (@w_tipo_tramite='U' and @w_vigente ='S') or (@i_tipo_tram_unif ='U' and @w_vigente ='S') begin -- JAR

         -- ACTUALIZAR LA TABLA CR_LINEA, CAMPOS LI_UTILIZADO, LI_RESERVADO
         update cr_linea set
         li_utilizado = isnull(li_utilizado, 0) - @w_local_utiliz
         --li_reservado = isnull(li_reservado, 0) - @w_local_reserv
         where  li_numero = @i_linea

         if @@error <> 0
         begin
            select @w_error = 2105012
            goto ERROR
         end

         if @w_grupo is not null
         begin
            -- ACTUALIZAR LA TABLA CR_LIN_GRUPO
            update cr_lin_grupo set
            lg_utilizado = isnull(lg_utilizado, 0) - @w_local_utiliz,
            lg_reservado = isnull(lg_reservado, 0) - @w_local_reserv
            where  lg_linea = @i_linea
            and    lg_cliente = @i_cliente

            if @@error <> 0
            begin
               select @w_error = 2105017
               goto ERROR
            end
         end             --if @w_grupo is not null

         -- ACTUALIZAR LA TABLA CR_LIN_OPE_moneda
         if exists (select 1
         from   cr_lin_ope_moneda
         where  om_linea = @i_linea
         and    om_toperacion = @i_toperacion
         and    om_producto = @w_i_producto
         and    om_moneda = @i_moneda)
         begin            
            update cr_lin_ope_moneda set
            om_utilizado = isnull(om_utilizado, 0) - @w_toper_utiliz
            --om_reservado = om_reservado - @w_toper_reserv
            where  om_linea = @i_linea
            and om_toperacion = @i_toperacion
            and om_producto = @w_i_producto
            and om_moneda = @i_moneda

            if @@error  <>  0
            begin
               select @w_error = 2105013
               goto ERROR
            end

         end

         if (@w_contabilizado_des = 'S' and @w_contabilizado = 'S') or (@w_tipo_linea = 'S')
         begin
            select @w_monto_cont = @w_monto_cont * (-1),
            @w_operacion = 'A'

            exec @w_return = sp_cont_tramite
            @s_user        = @s_user,
            @s_date        = @s_date,
            @s_term        = @s_term,
            @s_ofi         = @s_ofi,
            @i_tramite     = @i_tramite,
            @i_operacion   = @w_operacion,
            @i_monto       = @w_monto_cont,
            @i_fecha_valor  = @i_fecha_valor,
            @i_secuencial   = @i_secuencial,
            @i_origen        = 'P'

            if @w_return != 0
            return @w_return
         end
      end
   end  -- ROTATIVA
   --- Actualizo el maximo riesgo  del grupo  si el cliente pertenece
   --- a alg+n grupo economico, y de igual manera al sector economico
   if (@w_gru_cliente is not null and @i_valida is null) and @w_paramcem = 'S'
   begin
      update cobis..cl_grupo
      set gr_riesgo = isnull(gr_riesgo, 0) - @w_ries_utiliz,
      gr_reservado = isnull(gr_reservado, 0) - @w_ries_reserv
      where gr_grupo = @w_gru_cliente

      if @@error <> 0
      begin
         select @w_error = 2105001
         goto ERROR
      end
   end -- Fin de grupo is not null

   if (@w_sectoreco is not null and @i_valida is null) and @w_paramcem = 'S'
   begin
      update cobis..cl_sectoreco
      set se_riesgo = isnull(se_riesgo, 0) -  @w_ries_utiliz,
      se_reservado = isnull(se_reservado, 0) - @w_ries_reserv
      where se_sector = @w_sectoreco

      if @@error <> 0
      begin
         select @w_error = 2105001
         goto ERROR
      end
   end  -- Fin de sectoreco is not null

   if (@i_cliente is not null and @i_valida is null) and @w_paramcem = 'S'
   begin
      update cobis..cl_ente
      set en_riesgo = isnull(en_riesgo, 0) -  @w_ries_utiliz,
      en_reservado = isnull(en_reservado, 0) - @w_ries_reserv
      where en_ente = @i_cliente

      if @@error <> 0
      begin
         select @w_error = 2105001
         goto ERROR
      end
   end  -- Fin de cliente is not null
   if @w_commit = 'S' begin
      commit tran
      select @w_commit = 'N'
   end
end

--- SI OPERACION ES A (ANULACION)
if (@i_tipo = 'A')
begin
   if @i_batch <> 'S' and @@trancount = 0 begin
      begin tran
      select @w_commit = 'S'
   end
   -- ACTUALIZAR LA TABLA CR_LINEA, CAMPOS LI_UTILIZADO, LI_RESERVADO
   update cr_linea set
   li_utilizado = isnull(li_utilizado, 0) - @w_local_utiliz,
   li_reservado = isnull(li_reservado, 0) - @w_local_reserv
   where  li_numero = @i_linea

   if @@error <> 0
   begin
      select @w_error = 2105012
      goto ERROR
   end

   if @w_grupo is not null
   begin
      -- ACTUALIZAR LA TABLA CR_LIN_GRUPO
      update cr_lin_grupo set
      lg_utilizado = isnull(lg_utilizado, 0) - @w_local_utiliz,
      lg_reservado = isnull(lg_reservado, 0) - @w_local_reserv
      where  lg_linea = @i_linea
      and    lg_cliente = @i_cliente

      if @@error <> 0
      begin
         select @w_error = 2105017
         goto ERROR
      end
   end             --if @w_grupo is not null

   -- ACTUALIZAR LA TABLA CR_LIN_OPE_moneda
   if exists (select 1
   from   cr_lin_ope_moneda
   where  om_linea = @i_linea
   and    om_toperacion = @i_toperacion
   and    om_producto = @w_i_producto
   and    om_moneda = @i_moneda)
   begin
      update cr_lin_ope_moneda set
      om_utilizado = om_utilizado - @w_toper_utiliz,
      om_reservado = om_reservado - @w_toper_reserv
      where  om_linea = @i_linea
      and om_toperacion = @i_toperacion
      and om_producto = @w_i_producto
      and om_moneda = @i_moneda

      if @@error  <>  0
      begin
         select @w_error = 2105013
         goto ERROR
      end
   end

   if (@w_contabilizado_des = 'S' and @w_contabilizado = 'S') or (@w_tipo_linea = 'S')
   begin
      select @w_monto_cont = @w_monto_cont * (-1),
      @w_operacion = 'A'

      exec @w_return = sp_cont_tramite
      @s_user        = @s_user,
      @s_date        = @s_date,
      @s_term        = @s_term,
      @s_ofi         = @s_ofi,
      @i_tramite     = @i_tramite,
      @i_operacion   = @w_operacion,
      @i_monto       = @w_monto_cont,
      @i_fecha_valor  = @i_fecha_valor,
      @i_secuencial   = @i_secuencial,
      @i_origen        = 'P'

      if @w_return != 0
         return @w_return
   end
   --- Actualizo el maximo riesgo  del grupo  si el cliente pertenece
   --- a alg+n grupo economico, y de igual manera al sector economico
   if (@w_gru_cliente is not null and @i_valida is null) and @w_paramcem = 'S'
   begin
      update cobis..cl_grupo
      set gr_riesgo = isnull(gr_riesgo, 0) - @w_ries_utiliz,
      gr_reservado = isnull(gr_reservado, 0) - @w_ries_reserv
      where gr_grupo = @w_gru_cliente

      if @@error <> 0
      begin
         select @w_error = 2105001
         goto ERROR
      end
   end -- Fin de grupo is not null

   if (@w_sectoreco is not null and @i_valida is null) and @w_paramcem = 'S'
   begin
      update cobis..cl_sectoreco
      set se_riesgo = isnull(se_riesgo, 0) -  @w_ries_utiliz,
      se_reservado = isnull(se_reservado, 0) - @w_ries_reserv
      where se_sector = @w_sectoreco

      if @@error <> 0
      begin
    select @w_error = 2105001
         goto ERROR
      end
   end  -- Fin de sectoreco is not null

   if (@i_cliente is not null and @i_valida is null)   and @w_paramcem = 'S'
   begin
      update cobis..cl_ente
      set en_riesgo = isnull(en_riesgo, 0) -  @w_ries_utiliz,
      en_reservado = isnull(en_reservado, 0) - @w_ries_reserv
      where en_ente = @i_cliente

      if @@error <> 0
      begin
         select @w_error = 2105001
         goto ERROR
      end
   end  -- Fin de cliente is not null
   if @w_commit = 'S' begin
      commit tran
      select @w_commit = 'N'
   end
end

--PARA BANCAMIA AJUSTO Y, SI EL MONTO LLEGA A 0, ELIMINO ESA DISTRIBUCION
if @i_tipo in ('D', 'R', 'Y', 'X', 'A')
begin
   -- [D]ESEMBOLSO [R]ECUPERACION [ANULACION]
   -- [Y]REVERSO PAGO, [X]REVERSO DESEMBOLSO

   delete cr_lin_ope_moneda
   where  om_linea            = @i_linea
   and    isnull(om_monto, 0) = 0

   if @@error <> 0
   begin
      select @w_error = 2105001
      goto ERROR
   end

   exec @w_error = sp_corregir_cupos
   @i_cliente =  @w_cliente
   
   if  @w_error <> 0 goto ERROR

end

--- SI OPERACION EL C (CONTROL DE DISPONIBILIDAD)
if (@i_tipo = 'C')
begin
   if @i_tramite is null
      select @w_tipo_tramite = @i_tipo_tramite

   -- OBTENER EL TIPO DEL TRAMITE
   if @i_valida_sobrepasa = 'N'
   begin
      select
      @w_tipo_tramite = @w_tipo_tramite,
      @w_sobrepasa    = @w_sobrepasa
   end
   else
   begin
      select
      @w_tipo_tramite = @i_tipo_tramite,
      @w_sobrepasa    = null
   end
   --Incluir financiamientos
   if @w_tipo_tramite <> 'O' and @w_tipo_tramite <> 'R' and @w_tipo_tramite <> 'T' and @w_tipo_tramite <> 'E' and @w_tipo_tramite <> 'U'
      -- SALGO SIN PROCESAR
      return 0

   --OBTENER DISPONIBLE DE LA LINEA
   select @w_disponible_linea = @w_monto_linea - @w_utilizado_linea
                              - @w_reservado_linea

   --OBTENER DISPONIBLE DEL TIPO DE OPERACION
   select @w_disponible_toperacion = @w_monto_toperacion - @w_utilizado_toperacion
                                   - @w_reservado_toperacion

   --OBTENER DISPONIBLE DEL CLIENTE
   select @w_disponible_cliente = @w_monto_cliente - @w_utilizado_cliente
                                - @w_reservado_cliente

   -- ORIGINALES: MONTO DISPONIBLE DEBE SER MAYOR QUE EL TRAMITE Inlcuir financiamientoS
   if @w_tipo_tramite in ('O','T')
   begin

      if @i_valida_sobrepasa = 'N' and @w_sobrepasa <> 'S'
      begin
          if (@w_monto_toperacion > 0) and (@w_disponible_toperacion < @w_monto_local)
          begin
              --- EL CUPO NO TIENE DISPONIBLE PARA EL DESEMBOLSO DE ESTE TIPO DE PRESTAMO
              PRINT 'cr_utilz0.sp Error, La Linea de Credito seleccionada dispone de: %1! '+ cast (@w_disponible_toperacion as varchar)
              return 2101027
          end

          if @w_disponible_linea < @w_monto_local
          begin
             select @w_error = 2101027
             goto ERROR
          end

          if (@w_grupo is not null) and (@w_monto_cliente > 0) and (@w_disponible_cliente < @w_monto_local)
          begin
             select @w_error = 2101067
             goto ERROR
          end
      end
   end  -- if 'O'

   -- RENOVACIONES: SI EL MONTO DE LA RENOVACION ES MAYOR AL SALDO VERIFICAR
   if @w_tipo_tramite = 'R'
   begin
      -- OBTENGO LA DIFERENCIA EN MONTO PARA ESTE TRAMITE

      select
      @w_monto_renovaciones = isnull(x.tr_monto * a.cv_ult_valor, 0) -
                             (select isnull(sum(y.or_monto_original * b.cv_ult_valor), 0)
                              from   cr_op_renovar y, cob_conta..cb_ult_fecha_cotiz_mon b
                              where  x.tr_tramite = y.or_tramite  -- OPERACIONES DE LA RENOVACION
                              and    b.cv_moneda = y.or_moneda_original
                              group by y.or_tramite
                              having x.tr_monto * a.cv_ult_valor > isnull(sum(y.or_monto_original * b.cv_ult_valor), 0))
      from cr_tramite x, cob_conta..cb_ult_fecha_cotiz_mon a
      where  x.tr_tramite = @i_tramite   -- SOLO PARA EL TRAMITE
      and    a.cv_moneda = x.tr_moneda

      select @w_monto_renovaciones = isnull(@w_monto_renovaciones, 0)
      select @w_riesgo_actual = @w_monto_renovaciones

      -- LA DIFERENCIA EN MONTO DEBE TENER DISPONIBLE...
      if @w_monto_renovaciones > 0
      begin
         if @i_valida_sobrepasa = 'N' and @w_sobrepasa <> 'S'
         begin
            -- DISPONIBLE DE TIPO DE OPERACION
            if (@w_monto_toperacion > 0)  and (@w_disponible_toperacion < @w_monto_renovaciones)
            begin
               select @w_error = 2101066
               goto ERROR
            end

            --- DISPONIBLE LINEA
            if @w_disponible_linea < @w_monto_renovaciones
            begin
               select @w_error = 2101027
               goto ERROR
            end

            -- DISPONIBLE DE TIPO DEL CLIENTE
            if  (@w_grupo is not null) and (@w_monto_cliente > 0) and (@w_disponible_cliente < @w_monto_renovaciones)
            begin
               select @w_error = 2101067
               goto ERROR
            end
         end
      end

   end  -- if 'R'

   --- Verificar que no sobrepase el maximo riesgo del grupo si el cliente pertenece
   --- a alg+n grupo economico, y de igual manera al sector economico
   if (@i_cliente is not null and @i_valida is null)
   begin
      select @w_entramite_rcliente = sum(lr_reservado * cv_ult_valor)
      from   cr_tramite, cr_lin_reservado x, cob_conta..cb_ult_fecha_cotiz_mon
      where  lr_cliente = @i_cliente
      and    lr_tramite <> @i_tramite    -- EXCLUYO EL TRAMITE
      and    tr_tramite = lr_tramite
      and    tr_estado not in ('Z','X','R','S')            -- NO RECHAZADOS DEFINITIVAMENTE
      and    cv_moneda = lr_moneda

      select @w_entramite_rcliente = isnull(@w_entramite_rcliente, 0)

      select @w_ries_disp_cliente = @w_ries_disp_cliente - @w_entramite_rcliente

      if ((@w_ries_disp_cliente < @w_riesgo_actual) and @w_paramcem = 'S')
      begin
         select @w_error = 2101115
         goto ERROR
      end

   end -- Fin de cliente is not null

   if (@w_gru_cliente is not null and @i_valida is null)
   begin
      select @w_entramite_grupo = sum(lr_reservado * cv_ult_valor)
      from   cr_tramite , cr_lin_reservado x, cobis..cl_ente, cob_conta..cb_ult_fecha_cotiz_mon
      where  lr_tramite <> @i_tramite
      and    tr_tramite = lr_tramite
      and    tr_estado not in ('Z','X','R','S')            -- NO RECHAZADOS DEFINITIVAMENTE
      and    en_ente = lr_cliente
      and    en_grupo  = @w_gru_cliente
      and    cv_moneda = lr_moneda

      select @w_entramite_grupo = isnull(@w_entramite_grupo, 0)

      select @w_ries_disp_grupo = @w_ries_disp_grupo - @w_entramite_grupo

      if ((@w_ries_disp_grupo < @w_riesgo_actual) and @w_paramcem = 'S')
      begin
         select @w_error = 2101137
         goto ERROR
      end

   end -- Fin de grupo is not null

   if (@w_sectoreco is not null and @i_valida is null  and @w_paramcem = 'S')
   begin
      select @w_entramite_sector = sum(lr_reservado * cv_ult_valor)
      from   cr_tramite , cr_lin_reservado x, cobis..cl_ente, cob_conta..cb_ult_fecha_cotiz_mon
      where  lr_tramite <> @i_tramite
      and    tr_tramite = lr_tramite
      and    tr_estado not in ('Z','X','R','S')            -- NO RECHAZADOS DEFINITIVAMENTE
      and    en_ente = lr_cliente
      and    en_sector  = @w_sectoreco
      and    cv_moneda = lr_moneda

      select @w_entramite_sector = isnull(@w_entramite_sector, 0)

      select @w_ries_disp_sector = @w_ries_disp_sector - @w_entramite_sector

      if ((@w_ries_disp_sector < @w_riesgo_actual) and @w_paramcem = 'S')
         print 'Sobrepasa maximo riesgo de sector economico'

   end  -- Fin de sectoreco is not null

   select @w_monto_renovaciones = isnull(@w_monto_renovaciones,0)

      --- verificar si se trata de un sobrepasamiento
   if (@i_valida_sobrepasa = 'S') and (@i_modo_sobrepasa = 0) and (@w_monto_renovaciones >= 0)
   begin
      ---  Validacion del sobrepasamiento por linea
      if @w_monto_toperacion > 0 and @w_disponible_toperacion < @w_monto_local
      begin
           select @w_montol_falta = @w_monto_local - @w_disponible_toperacion
           PRINT 'cr_utiliz0.sp Monto excede a la Linea de Credito escogida en: %1! ' + cast (@w_montol_falta as varchar)
           select '0'
           return 1
      end
      else
      begin
         ---  Validacion del sobrepasamiento por cupo
         if @w_disponible_linea < @w_monto_local
         begin
            select @w_montoc_falta = @w_monto_local - @w_disponible_linea
            PRINT 'cr_utiliz0.sp Monto excede al Cupo de Credito escogido en: %1! ' + cast (@w_montoc_falta as varchar)
            select '0'
            return 2101027
         end
         else
         begin
            select '2'
            return 0
         end
      end
   end

   --- verificar  parametros de sobrepasamientos
   if (@i_valida_sobrepasa = 'S' and @i_modo_sobrepasa = 1)
       or @w_sobrepasa ='S'
   begin
      --- Verificar si el cupo de credito permite pasamientos
      if @w_rotativa = 'N'
      begin
         select @w_error = 2101119
         goto ERROR
      end

      --- porcentaje de sobrepasamiento
      select @w_psob = pa_float
      from cobis..cl_parametro
      where pa_producto = 'CRE'
      and pa_nemonico = 'PSOB'
      set transaction isolation level read uncommitted

      --- monto maximo de sobrepasamiento
      select @w_msob = pa_money
      from cobis..cl_parametro
      where pa_producto = 'CRE'
      and pa_nemonico = 'MSOB'
      set transaction isolation level read uncommitted

      --SBU
      -- Control de sobrepasamiento para la l¬nea de cr+dito
      select @w_montol_psob  = @w_monto_toperacion * @w_psob / 100,
             @w_montol_falta = @w_monto_local - @w_disponible_toperacion

      if @w_montol_falta  > @w_montol_psob
      begin
         select @w_error =  2101127
         goto ERROR
      end

      if @w_montol_falta > @w_msob
      begin
         select @w_error =  2101103
         goto ERROR
      end

      --- Control de sobrepasamiento para el cupo de cr+dito
      select @w_montoc_psob  = @w_monto_linea * @w_psob / 100,
             @w_montoc_falta = @w_monto_local - @w_disponible_linea

      if @w_montoc_falta  > @w_montoc_psob
      begin
         select @w_error =  2101102
         goto ERROR
      end

      if @w_montoc_falta > @w_msob
      begin
         select @w_error =  2101103
         goto ERROR
      end

      return 0         --- Salida Sobrepasamiento
   end  --- fin de modo 1

end  -- @i_tipo = 'C'

/*
if @i_linea_banco is not null
begin
   exec @w_return = sp_reservado
      @i_linea_credito = @i_linea_banco
   
   if @w_return <> 0 begin
      select @w_error = @w_return
      goto ERROR
   end
end
*/
return 0

ERROR:
   if @w_commit = 'S' begin
      rollback tran
   end
   if @i_batch <> 'S' begin
      exec cobis..sp_cerror
      @t_from    = @w_sp_name,
      @i_num     = @w_error
   end
   return @w_error


GO

