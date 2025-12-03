/************************************************************************/
/*  Archivo:                utilizacion.sp                              */
/*  Stored procedure:       sp_utilizacion                              */
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
/*  SP GENERADO POR EXTRACCION DE LA BB.DD. cob_credito                 */
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  23/04/19          Jose Ortiz       Emision Inicial                  */
/*  28/12/21          William Lopez    ORI-S575137-GFI                  */
/*  16/01/21          Paulina Quezada  Inclusión multimoneda            */
/*  05/08/22          Paulina Quezada  Reversiones de Cartera no afectan*/
/*                                     el saldo de lineas de crédito    */
/* **********************************************************************/
use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_utilizacion' and type = 'P')
   drop proc sp_utilizacion
go


create proc sp_utilizacion(
   @s_ssn              int      = null,
   @s_user             login    = null,
   @s_sesn             int    = null,
   @s_term             descripcion = null,
   @s_date             datetime = null,
   @s_srv              varchar(30) = null,
   @s_lsrv             varchar(30) = null,
   @s_rol              smallint = null,
   @s_ofi              smallint  = null,
   @s_org              char(1) = null,
   @t_trn              smallint = null,
   @t_debug            char(1)  = 'N',
   @t_file             varchar(14) = null,
   @t_from             varchar(30) = null,
   @i_tipo             char(1) = null,
   @i_linea            int = null,
   @i_linea_banco      cuenta = null,
   @i_producto         char(4) = null,
   @i_toperacion       catalogo = null,
   @i_moneda           tinyint = null,
   @i_monto            money = null,
   @i_tramite          int = null,
   @i_cliente          int = null,
   @i_moneda_linea     tinyint = null,
   @i_opcion           char(1) = null,   -- P=Pasiva, A=Activa
   @i_valida_sobrepasa char(1) = 'N',
   @i_modo_sobrepasa   tinyint = 0,
   @i_tipo_tramite     char(1) = null,
   @i_opecca          int      = null,
   @i_fecha_valor      datetime = null,         --SBU: 27/sep/99
   @i_secuencial       int      = 0,
   @i_modo             tinyint  = null,      --SBU:  CD00005
   @i_monto_cex        money = null,      --SBU interfaces
   @i_numoper_cex      cuenta = null,
   @i_valida           tinyint = null,
   @i_batch            char(1) = 'N',
   @i_tramite_unif     int         = null,
   @i_tipo_tram_unif   char(1)     = null
)
as
declare
   @w_today                   datetime,       -- FECHA DEL DIA
   @w_sp_name                 varchar(32),    -- NOMBRE STORED PROC
   @w_error                   int,
   @w_monto_local             money,          -- CALCULO TEMPORAL
   @w_def_moneda              tinyint,        -- moneda LOCAL
   @w_monto_reservado         money,          -- MONTO EN TRAMITE
   @w_tipo_tramite            char(1),        -- TIPO DE TRAMITE
   @w_monto_renovaciones      money,       -- DIFERENCIA EN MONTO PARA RENOVACIONES
   @w_tramite                 int,
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
   @w_gru_cliente             int,
   @w_sectoreco               catalogo,
   @w_max_ries_grupo          money,
   @w_ries_grupo            money,
   @w_ries_reservado_grupo    money,
   @w_ries_disp_grupo         money,
   @w_max_ries_sector         money,
   @w_ries_sector           money,
   @w_ries_reservado_sector   money,
   @w_ries_disp_sector        money,
   @w_operacion                char(1),
   @w_cliente                 int,
   @w_est_tramite           char(1),
   @w_max_ries_cliente        money,
   @w_ries_cliente             money,
   @w_ries_reservado_cliente  money,
   @w_ries_disp_cliente       money,
   @w_riesgo_actual            money,
   @w_producto                varchar(3),
   @w_plazo                   int,
   @w_tmp_plazo               char(10),
   @w_fecha_fin                datetime,
   @w_fecha_ini                datetime,
   @w_entramite_grupo         money,
   @w_entramite_sector        money,
   @w_entramite_rcliente      money,
   @w_local_utiliz             money,     --SBU Interfaces
   @w_local_reserv             money,
   @w_ries_utiliz           money,
   @w_ries_reserv           money,
   @w_fac_conres            char(1),
   @w_monto_reno              money,
   @w_monto_aux               money,
   @w_cotiza                  float,
   @w_tipo_pasiva             char(1),
   @w_paramcem                char(1),
   @w_rowcount                int,
   @w_cant_util               smallint,
   @w_primera                 char(1),
   @w_monto                   money,
   @w_li_numero               INT,
   @w_monto_linea             money,
   @w_utiliz_linea            money,
   @w_monto_sublinea          money,
   @w_utiliz_sublinea         money,
   @w_monto_otras_sublineas   money,
   @w_utiliz_otras_sublineas  money,
   @w_om_rotativa             char(1),
   --INI WLO_S575137
   @w_grupo                   int,
   @w_fecha_aprob             datetime, -- fecha de aprob de linea
   @w_fecha_vence             datetime, -- fecha venc. de linea
   @w_moneda_linea            tinyint,  -- moneda de la linea
   @w_rotativa                char(1),  -- dato de la linea
   @w_contabiliza             char(1),
   @w_valor                   money,
   @w_moneda_sublinea         tinyint, --PQU conversión moneda
   @w_monto_mon_linea         money, --PQU conversión moneda
   @w_monto_mon_sublinea      money --PQU conversión moneda
   --FIN WLO_S575137

   --PQU la moneda puede ser otra distinta a la nacional select @i_moneda = 0 --Toda utilizacion es en pesos
      
if @i_opcion = 'W'
   return 0 
   
    /*VALIDAR SI ES PRIMERA UTILIZACION*/
if @i_opcion = 'U'
begin
   select
   @w_cant_util = isnull(count(op_operacion), 0)
   from cr_linea, cob_cartera..ca_operacion
   where li_num_banco = @i_linea_banco
   and li_num_banco  = op_lin_credito
   and op_estado in (1, 2, 3, 4, 9)
   and op_tramite>li_tramite --VALIDACION PARA UTILIZACION SOBRE AMPLIACION DE CUPO

   if @w_cant_util = 0
      select @w_primera = 'S'
   else
      select @w_primera = 'N'

   select @w_primera

   return 0
end

select  @w_paramcem = pa_char
from    cobis..cl_parametro
where   pa_producto = 'CRE'
and     pa_nemonico = 'CEM'
set transaction isolation level read uncommitted

if @i_tramite is not null   --Las operaciones pasivas de redescuento no son riesgo del cliente
begin
   select   @w_tipo_pasiva    = dt_tipo
   from  cob_cartera..ca_default_toperacion
   where    dt_toperacion     =  (select tr_toperacion
                from cr_tramite
                where tr_tramite = @i_tramite)
       if @w_tipo_pasiva  = 'R'
          return 0
end

/* VALIDACION DE CAMPOS NULOS */
/******************************/

if (@i_tipo is null)
or (@i_linea is null and @i_linea_banco is null and @i_modo = 0)   --SBU: CD00005
or (@i_monto is null)
or (@i_moneda is null)
begin
   if @i_batch <> 'S'
   exec cobis..sp_cerror
   @t_debug = @t_debug,
   @t_file  = @t_file,
   @t_from  = @w_sp_name,
   @i_num   = 2101001

   return 2101001
end

select @w_sp_name = 'sp_utilizacion'


if @i_fecha_valor = '01/01/1900'
   select @i_fecha_valor = @s_date


if @i_linea_banco = ' '
   select @i_linea_banco = null


if (@i_linea_banco is not null)
   select @i_modo = 1


if @i_tramite is null --control de operaciones sin responsabilidad
begin

   if exists (select 1
      from   cob_cartera..ca_default_toperacion
      where  dt_toperacion = @i_toperacion
      and    dt_tipo_linea = '65'
      and    dt_tipo = 'D')
      return 0
end

if @i_tramite is not null   --Control de operaciones sin responsabilidad
begin

   select distinct @w_fac_conres = fa_con_respon
   from cr_facturas
   where fa_tramite = @i_tramite

   if @w_fac_conres = 'N'   --Sale sin procesar   SBU  01/dic/2001
      return 0
end


-- Verificar si se trata de lineas Activas o Pasivas  JSB 99-04-03
if (@i_opcion <> 'P' or @i_opcion is NULL) and (@i_modo = 0)   --SBU  CD00005
begin

   exec @w_return = sp_utiliz0
   @s_ssn               = @s_ssn,
   @s_user              = @s_user,
   @s_sesn              = @s_sesn,
   @s_term              = @s_term,
   @s_date              = @s_date,
   @s_srv               = @s_srv,
   @s_lsrv              = @s_lsrv,
   @s_rol               = @s_rol,
   @s_ofi               = @s_ofi,
   @t_debug             = @t_debug,
   @t_file              = @t_file,
   @t_from              = @t_from,
   @i_tipo              = @i_tipo,
   @i_linea             = @i_linea,
   @i_linea_banco       = @i_linea_banco,
   @i_producto          = @i_producto,
   @i_toperacion        = @i_toperacion,
   @i_moneda            = @i_moneda,
   @i_monto             = @i_monto,
   @i_tramite           = @i_tramite,
   @i_cliente           = @i_cliente,
   @i_moneda_linea      = @i_moneda_linea,
   @i_opcion            = @i_opcion,   -- P=Pasiva, A=Activa
   @i_valida_sobrepasa  = @i_valida_sobrepasa,
   @i_modo_sobrepasa    = @i_modo_sobrepasa,
   @i_tipo_tramite      = @i_tipo_tramite,
   @i_opecca           = @i_opecca,
   @i_fecha_valor       = @i_fecha_valor,
   @i_secuencial        = @i_secuencial,
   @i_modo              = 0,
   @i_monto_cex         = @i_monto_cex,      --SBU interfaces
   @i_valida            = @i_valida,  --pga 15nov01
   @i_numoper_cex       = @i_numoper_cex,
   @i_batch             = @i_batch,
   @i_tramite_unif      = @i_tramite_unif,  -- JAR REQ 218 Paquete2. Cupos.
   @i_tipo_tram_unif    = @i_tipo_tram_unif -- JAR REQ 218 Paquete2. Cupos.

   if @w_return != 0
      return @w_return

end


-- Manejo de lineas pasivas de Comext @i_opcion = 'P' JSB 99-04-03
if @i_opcion = 'P'
begin
   if (@i_tipo is not NULL) and (@i_linea_banco is not null)
   begin
      if @i_tipo in  ('D', 'Y')    -- Se trata de un desembolso, reversa de desembolso  SBU: 27/sep/99
      begin
         select @w_opcion = 4
      end
      else
      begin
         if @i_tipo in ('R', 'X')  -- Se trata de una recuperacion, reversa de recuperacion  SBU: 27/sep/99
            select @w_opcion = 5
      end
   end
end


if (@i_opcion <> 'P' or @i_opcion is NULL) and (@i_modo = 1)
begin


/* OBTENCION DE DATOS INICIALES */
/********************************/
--SELECCION DE CODIGO DE ct_moneda LOCAL
select @w_def_moneda = pa_tinyint
from cobis..cl_parametro
where pa_producto = 'CRE'
and pa_nemonico = 'MLOCR'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0
begin
   if @i_batch <> 'S'
      exec cobis..sp_cerror
      @t_from  = @w_sp_name,
      @i_num   = 2101005
   return 2101005
end


if @i_tramite is not null
begin

  --JSB 2000-02-04 Obtener el codigo de cliente
  if @i_opcion = 'A'
  BEGIN
    
      
      select @w_cliente = tr_cliente
      from cr_tramite
      where tr_tramite = @i_tramite

      if @w_cliente is not  null
         select @i_cliente = @w_cliente
      else
      begin

         if @i_batch <> 'S'
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = 2101001

         return 2101001
      end
  end
  --JSB

  select @w_producto = tr_producto,
         @w_est_tramite = tr_estado,
         @w_fecha_ini = tr_fecha_crea,
         @w_tipo_tramite = tr_tipo,
         @w_sobrepasa    = tr_sobrepasa
  from cr_tramite
  where tr_tramite = @i_tramite

  if @@rowcount = 0
  begin
     if @i_batch <> 'S'
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = 2101005

     return 2101005
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

      if @i_batch <> 'S'
      exec cobis..sp_cerror
      @t_from  = @w_sp_name,
      @i_num   = 2101003

      return 2101003
   end
end
else
   select @w_monto_local = @i_monto
   

/* Monto de Riesgo Actual */
select @w_riesgo_actual = @w_monto_local  -- DBA: 16/NOV/99

if @i_tipo in ('D', 'X')
begin
   if @w_producto = 'CEX'
         select @w_local_utiliz = 0,
                @w_ries_utiliz  = 0,
                @w_local_reserv = -1 * @w_monto_local,
           @w_ries_reserv  = -1 * @w_riesgo_actual

   if @w_producto = 'CCA'
         select @w_local_utiliz = @w_monto_local,
                @w_ries_utiliz  = @w_riesgo_actual,
                @w_local_reserv = @w_monto_local,
           @w_ries_reserv  = @w_riesgo_actual

   if @w_producto not in ('CCA','CEX')
         select @w_local_utiliz = @w_monto_local,
                @w_ries_utiliz  = @w_riesgo_actual,
                @w_local_reserv = 0,
           @w_ries_reserv  = 0
end

if @i_tipo in ('Y', 'R')
begin
   if @w_producto = 'CEX'
         select @w_local_utiliz = 0,
                @w_ries_utiliz   = 0,
                @w_local_reserv = @w_monto_local,
           @w_ries_reserv  = @w_riesgo_actual
   else
         select @w_local_utiliz = @w_monto_local,
                @w_ries_utiliz   = @w_riesgo_actual,
                @w_local_reserv = 0,
           @w_ries_reserv  = 0
end

if @i_tipo = 'A'
begin
   select @w_local_utiliz = 0,
          @w_ries_utiliz   = 0,
          @w_local_reserv = @w_monto_local,
          @w_ries_reserv  = @w_riesgo_actual
end

--INI WLO_S575137
if (@i_opcion <> 'P' or @i_opcion is null)
begin

   select @w_grupo = null

   if @i_linea is null
   begin
      select @i_linea           = li_numero,
             @w_fecha_aprob     = li_fecha_aprob,
             @w_fecha_vence     = li_fecha_vto,
             @w_monto_linea     = isnull(li_monto,0),
             @w_utiliz_linea    = isnull(li_utilizado,0),
             @w_moneda_linea    = li_moneda,
             @w_rotativa        = li_rotativa,
             @w_grupo           = li_grupo,
             @w_contabiliza     = 'S',
             @w_estado          = li_estado,
             @w_tramite         = li_tramite
      from   cr_linea
      where  li_num_banco = @i_linea_banco
      
      if @@rowcount = 0
      begin
        /*Registro no existe */
        exec cobis..sp_cerror
        @t_debug  =  @t_debug,
        @t_file   =  @t_file,
        @t_from   =  @w_sp_name,
        @i_num    =  2101005
        return 1
      end
   end
   else
   begin
      select @i_linea_banco     = li_num_banco,
             @w_fecha_aprob     = li_fecha_aprob,
             @w_fecha_vence     = li_fecha_vto,
             @w_monto_linea     = isnull(li_monto,0),
             @w_utiliz_linea    = isnull(li_utilizado,0),
             @w_moneda_linea    = li_moneda,
             @w_rotativa        = li_rotativa,
             @w_grupo           = li_grupo,
             @w_contabiliza     = 'S',
             @w_estado          = li_estado,
             @w_tramite         = li_tramite
      from   cr_linea
      where  li_numero = @i_linea

      if @@rowcount = 0
      begin
        /*Registro no existe */
        exec cobis..sp_cerror
        @t_debug  =  @t_debug,
        @t_file   =  @t_file,
        @t_from   =  @w_sp_name,
        @i_num    =  2101005
        return 1
      end
   end
end
--FIN WLO_S575137

--PQU por manejo de multimoneda

if (@i_tipo = 'D' or @i_tipo = 'R' or  @i_tipo = 'Y' or @i_tipo = 'X')
begin 
   if @i_linea is null
   begin
      select @w_li_numero = li_numero
      from   cob_credito..cr_linea
      where  li_num_banco = @i_linea_banco
   end
   else
      select @w_li_numero = @i_linea 

   select @w_rotativa = li_rotativa
   from   cr_linea
   where  li_numero = @w_li_numero

   select @w_om_rotativa = @w_rotativa

   select @w_contabiliza = 'S'

   --Control de sublimite
   select @w_monto_linea = 0
   select @w_utiliz_linea = 0
   
   select @w_monto_linea  = isnull(li_monto,0),
          @w_utiliz_linea = isnull(li_utilizado,0),
          @w_moneda_linea = li_moneda  --PQU 
   from   cob_credito..cr_linea
   where  li_numero = @w_li_numero

   select @w_monto_sublinea  = 0
   select @w_utiliz_sublinea = 0

   select @w_monto_sublinea  = isnull(om_monto,0),
          @w_utiliz_sublinea = isnull(om_utilizado,0),
          @w_moneda_sublinea = om_moneda  --PQU 
   from   cob_credito..cr_lin_ope_moneda
   where  om_linea      = @w_li_numero
   and    om_toperacion = @i_toperacion
   and    om_producto   = 'CCA'
   and    om_moneda     = @i_moneda
   --PQU la moneda puede ser distinta de 0 and    om_moneda = 0     

   exec @w_return = cob_credito..sp_conversion_moneda
        @s_date             = @s_date,
        @i_fecha_proceso    = @s_date,
        @i_moneda_monto     = @i_moneda,              --moneda las cuotas
        @i_moneda_resultado = @w_moneda_linea,        --moneda de la linea
        @i_monto            = @i_monto,               --monto entrada
        @o_monto_resultado  = @w_monto_mon_linea out, --resultado de la conversion
        @o_monto_mn_resul   = null

   if @w_return != 0
   begin
      select @w_error = @w_return
      goto ERROR
   end

   exec @w_return = cob_credito..sp_conversion_moneda
        @s_date             = @s_date,
        @i_fecha_proceso    = @s_date,
        @i_moneda_monto     = @i_moneda,                 --moneda las cuotas
        @i_moneda_resultado = @w_moneda_sublinea,        --moneda de la linea
        @i_monto            = @i_monto,                  --monto entrada
        @o_monto_resultado  = @w_monto_mon_sublinea out, --resultado de la conversion
        @o_monto_mn_resul   = null

   if @w_return != 0
   begin
      select @w_error = @w_return
      goto ERROR
   end
end 

--- EJECUCION DE CADA PROCESO
--- SI OPERACION ES D (DESEMBOLSO)
if (@i_tipo = 'D')
begin
   if @i_batch <> 'S'
   begin tran 
    
	   /*PQU
	   select @w_li_numero    = li_numero
       from cob_credito..cr_linea
       where li_num_banco = @i_linea_banco */
            
	   if exists (select 1
				  from   cob_credito..cr_lin_ope_moneda
				  where  om_linea = @w_li_numero
				  and    om_toperacion = @i_toperacion
				  and    om_producto = 'CCA'
				  and    om_moneda     = @i_moneda)
				  --PQU en la moneda que corresponda and    om_moneda = 0)
	    begin
		
                                  
        /*PQU esto no se está usando en este sp
		select @w_monto_otras_sublineas = 0                      
        select @w_monto_otras_sublineas  = isnull(sum(om_monto),0),
               @w_utiliz_otras_sublineas = isnull(sum(om_utilizado),0)
        from   cob_credito..cr_lin_ope_moneda
        where  om_linea = @w_li_numero
        and    om_toperacion <> @i_toperacion
        and    om_producto = 'CCA'
        and    om_moneda = 0   	    
		*/
      
        --Control del disponible total de la linea
        IF (@w_monto_linea - @w_utiliz_linea) < @w_monto_mon_linea --PQU conversion moneda @i_monto
        begin
			select @w_error = 2101027 --El Cupo no tiene disponible para este desembolso
			goto ERROR
		end  
		      
		  --Control del disponible de la linea
		IF (@w_monto_sublinea - @w_utiliz_sublinea) < @w_monto_mon_sublinea --PQU conversion moneda @i_monto
        begin
			select @w_error = 2101066 --El Cupo no tiene Disponible para el Desembolso de esta Linea de credito
			goto ERROR
		  end
      
		  -- ACTUALIZACION EN CR_LIN_OPE_moneda
		  update cob_credito..cr_lin_ope_moneda set
                 om_utilizado = isnull(om_utilizado, 0) + @w_monto_mon_linea --PQU conversion moneda @i_monto
		  where  om_linea      = @w_li_numero
          and    om_toperacion = @i_toperacion
          and    om_producto   = 'CCA'
		  and    om_moneda     = @i_moneda
          --PQU la moneda puede ser distinta de 0 and    om_moneda     = 0
        
		  if @@error <> 0
        begin
		  	select @w_error = 2105013
		  	goto ERROR
		  end
      
		   --LPO DEMO DISMINUIR EL CUPO DE LA LINEA
		   -- ACTUALIZAR LA TABLA CR_LINEA, CAMPOS LI_UTILIZADO, LI_RESERVADO
		   update cob_credito..cr_linea
		   set   li_utilizado = isnull(li_utilizado, 0) + @w_monto_mon_sublinea --PQU conversion moneda @i_monto 
		   where li_numero = @w_li_numero
         
		   if @@error <> 0
		   begin
		   	select @w_error = 2105012
		   	goto ERROR
		   end      
	    end

       --INI WLO_S575137
       --LLama a sp_transacciones_linea con i_opcion = 'D'
       if @w_contabiliza = 'S'--PQU esto siempre entrará por acá and (@w_rotativa = 'S' or (@w_rotativa != 'S' and @i_tipo = 'D'))
       begin
          select @w_valor = round(@i_monto,2)

          if @w_valor > 0
          begin
            exec @w_return = sp_transacciones_linea
                 @s_user        = @s_user,
                 @s_date        = @s_date,
                 @s_ofi         = @s_ofi,
                 @s_term        = @s_term,
                 @t_trn         = 21449,
                 @i_transaccion = 'D',
                 @i_linea       = @i_linea,
                 @i_operacion   = @i_opecca,
                 @i_valor_ref   = @w_monto_linea,
                 @i_valor       = @w_valor,
                 @i_moneda      = @w_moneda_linea,
                 @i_estado      = 'I'

            if @w_return != 0
            begin
               return @w_return
            end

            exec @w_return = sp_transacciones_linea
                 @s_user        = @s_user,
                 @s_date        = @s_date,
                 @s_term        = @s_term,
                 @s_ofi         = @s_ofi,
                 @t_trn         = 21469,
                 @i_transaccion = 'E',
                 @i_linea       = @i_linea,
                 @i_valor       = @w_valor,
                 @i_valor_ref   = @w_monto_linea,
                 @i_moneda      = @w_moneda_linea

            if @w_return != 0
            begin
               return @w_return
            end
          end

       end
       --FIN WLO_S575137

   if @i_batch <> 'S'
   commit tran  
end

if (@i_tipo = 'R')
begin
     
   /* PQU
    select @w_li_numero    = li_numero
   	from cob_credito..cr_linea
   	where li_num_banco =  @i_linea_banco
     
   --PQU el rotativo se obtiene de la línea
   select @w_om_rotativa = om_rotativa
    from   cob_credito..cr_lin_ope_moneda
    where  om_linea = @w_li_numero
    and    om_toperacion = @i_toperacion
    and    om_producto = 'CCA'
    and    om_moneda = 0 */
      
   IF @w_om_rotativa = 'S'
   begin
         
      update cob_credito..cr_linea
      set   li_utilizado = isnull(li_utilizado, 0) - @w_monto_mon_linea --PQU @i_monto
      WHERE li_numero = @w_li_numero
      
      if @@error <> 0
      begin
         select @w_error = 2105012
         RETURN @w_error
      end
         
      if exists (select 1
              from   cob_credito..cr_lin_ope_moneda
              where  om_linea = @w_li_numero
              and    om_toperacion = @i_toperacion
              and    om_producto = 'CCA'
			  and    om_moneda     = @i_moneda)
              --PQU la moneda puede ser distinta de 0 and    om_moneda = 0)
      begin
         -- ACTUALIZACION EN CR_LIN_OPE_moneda
         update cob_credito..cr_lin_ope_moneda set
         om_utilizado = isnull(om_utilizado, 0) - @w_monto_mon_sublinea --PQU @i_monto
         where  om_linea      = @w_li_numero
         and    om_toperacion = @i_toperacion
         and    om_producto   = 'CCA'
		 and    om_moneda     = @i_moneda
         --PQU la moneda puede ser distinta de 0 and    om_moneda     = 0
         
         if @@error <> 0
         begin
            select @w_error = 2105013
            RETURN @w_error
         end
      end
   END --IF @w_om_rotativa = 'S'

   --INI WLO_S575137
   --LLama a sp_transacciones_linea con i_opcion = 'R'
   if @w_contabiliza = 'S' and (@w_rotativa = 'S' or (@w_rotativa != 'S' and @i_tipo = 'R'))
   begin
      select @w_valor = round(@i_monto,2)

      if @w_valor > 0
      begin
         exec @w_return = sp_transacciones_linea
              @s_user        = @s_user,
              @s_date        = @s_date,
              @s_ofi         = @s_ofi,
              @s_term        = @s_term,
              @t_trn         = 21448,
              @i_transaccion = 'A',
              @i_linea       = @i_linea,
              @i_operacion   = @i_opecca,
              @i_valor_ref   = @w_monto_linea,
              @i_valor       = @w_valor,
              @i_moneda      = @w_moneda_linea,
              @i_estado      = 'I'

         if @w_return != 0
         begin
            return @w_return
         end

         exec @w_return      = sp_transacciones_linea
              @s_user        = @s_user,
              @s_date        = @s_date,
              @s_term        = @s_term,
              @s_ofi         = @s_ofi,
              @t_trn         = 21469,
              @i_transaccion = 'E',
              @i_linea       = @i_linea,
              @i_valor       = @w_valor,
              @i_valor_ref   = @w_monto_linea,
              @i_moneda      = @w_moneda_linea

         if @w_return != 0
         begin
            return @w_return
         end
      end
   end
   --FIN WLO_S575137

end



--- SI OPERACION ES Y (REVERSA DE PAGO)
if @i_tipo = 'Y'     --SBU: 27/sep/99
BEGIN
   
   if @i_batch <> 'S'
   begin TRAN
   
       --- Actualizar el maximo riesgo del grupo si el cliente  pertenece
       --- a algun grupo economico, y de igual manera al sector economico
    /*PQU select @w_li_numero    = li_numero
   	from cob_credito..cr_linea
   	where li_num_banco =  @i_linea_banco
     
    select @w_om_rotativa = om_rotativa
    from   cob_credito..cr_lin_ope_moneda
    where  om_linea = @w_li_numero
    and    om_toperacion = @i_toperacion
    and    om_producto = 'CCA'
    and    om_moneda = 0
   */
    
   IF @w_om_rotativa = 'S'
   begin
         
      update cob_credito..cr_linea
      set   li_utilizado = isnull(li_utilizado, 0) + @w_monto_mon_linea --PQU @i_monto
      WHERE li_numero = @w_li_numero
      
      if @@error <> 0
      begin
         select @w_error = 2105012
         RETURN @w_error
      end
         
      if exists (select 1
              from   cob_credito..cr_lin_ope_moneda
              where  om_linea = @w_li_numero
              and    om_toperacion = @i_toperacion
              and    om_producto = 'CCA'
			  and    om_moneda     = @i_moneda)
              --PQU la moneda puede ser distinta de 0 and    om_moneda = 0)
      begin
         -- ACTUALIZACION EN CR_LIN_OPE_moneda
         update cob_credito..cr_lin_ope_moneda set
         om_utilizado = isnull(om_utilizado, 0) + @w_monto_mon_sublinea --PQU @i_monto
         where  om_linea      = @w_li_numero
         and    om_toperacion = @i_toperacion
         and    om_producto   = 'CCA'
		 and    om_moneda     = @i_moneda
        --PQU la moneda puede ser distinta de 0 and    om_moneda     = 0
         
         if @@error <> 0
         begin
            select @w_error = 2105013
            RETURN @w_error
         end
      end
   END --IF @w_om_rotativa = 'S'
   
   if @w_contabiliza = 'S'  --PQU
       begin
          select @w_valor = round(@w_monto_mon_linea,2)

          if @w_valor > 0
          begin
            exec @w_return = sp_transacciones_linea
                 @s_user        = @s_user,
                 @s_date        = @s_date,
                 @s_ofi         = @s_ofi,
                 @s_term        = @s_term,
                 @t_trn         = 21449,
                 @i_transaccion = 'D',
                 @i_linea       = @i_linea,
                 @i_operacion   = @i_opecca,
                 @i_valor_ref   = @w_monto_linea,
                 @i_valor       = @w_valor,
                 @i_moneda      = @w_moneda_linea,
                 @i_estado      = 'I'

            if @w_return != 0
            begin
               return @w_return
            end
			
			exec @w_return = sp_transacciones_linea
                 @s_user        = @s_user,
                 @s_date        = @s_date,
                 @s_term        = @s_term,
                 @s_ofi         = @s_ofi,
                 @t_trn         = 21469,
                 @i_transaccion = 'E',
                 @i_linea       = @i_linea,
                 @i_valor       = @w_valor,
                 @i_valor_ref   = @w_monto_linea,
                 @i_moneda      = @w_moneda_linea

            if @w_return != 0
            begin
               return @w_return
            end
			
       end --fin contabiliza

   END --IF @w_om_rotativa = 'S'

   if @i_batch <> 'S'
   commit tran
end

--- SI OPERACION ES X (REVERSA DE DESEMBOLSO)
if (@i_tipo = 'X')   --SBU: 27/sep/99
begin
   if @i_batch <> 'S'
   begin tran
         --- Actualizo el maximo riesgo  del grupo  si el cliente pertenece
         --- a algun grupo economico, y de igual manera al sector economico
            
    /*PQU
	select @w_li_numero    = li_numero
   	from cob_credito..cr_linea
   	where li_num_banco =  @i_linea_banco
     
    select @w_om_rotativa = om_rotativa
    from   cob_credito..cr_lin_ope_moneda
    where  om_linea = @w_li_numero
    and    om_toperacion = @i_toperacion
    and    om_producto = 'CCA'
    and    om_moneda = 0
   */
    
    update cob_credito..cr_linea
    set   li_utilizado = isnull(li_utilizado, 0) - @w_monto_mon_linea --PQU @i_monto
    WHERE li_numero = @w_li_numero
      
    if @@error <> 0
    begin
        select @w_error = 2105012
        RETURN @w_error
    end
         
    if exists (select 1
              from   cob_credito..cr_lin_ope_moneda
              where  om_linea = @w_li_numero
              and    om_toperacion = @i_toperacion
              and    om_producto = 'CCA'
			  and    om_moneda     = @i_moneda)
              --PQU la moneda puede ser distinta de 0 and    om_moneda = 0)
     begin
         -- ACTUALIZACION EN CR_LIN_OPE_moneda
          update cob_credito..cr_lin_ope_moneda set
          om_utilizado = isnull(om_utilizado, 0) - @w_monto_mon_sublinea --PQU @i_monto
          where  om_linea      = @w_li_numero
          and    om_toperacion = @i_toperacion
          and    om_producto   = 'CCA'
		  and    om_moneda     = @i_moneda
          --PQU la moneda puede ser distinta de 0 and    om_moneda     = 0
         
          if @@error <> 0
          begin
            select @w_error = 2105013
            RETURN @w_error
         end
     end
	 
	 if @w_contabiliza = 'S'
       begin
          select @w_valor = round(@w_monto_mon_linea,2)

          if @w_valor > 0
          begin
      
	          exec @w_return = sp_transacciones_linea
              @s_user        = @s_user,
              @s_date        = @s_date,
              @s_ofi         = @s_ofi,
              @s_term        = @s_term,
              @t_trn         = 21448,
              @i_transaccion = 'A',
              @i_linea       = @i_linea,
              @i_operacion   = @i_opecca,
              @i_valor_ref   = @w_monto_linea,
              @i_valor       = @w_valor,
              @i_moneda      = @w_moneda_linea,
              @i_estado      = 'I'

              if @w_return != 0
              begin
                  return @w_return
              end

             exec @w_return      = sp_transacciones_linea
              @s_user        = @s_user,
              @s_date        = @s_date,
              @s_term        = @s_term,
              @s_ofi         = @s_ofi,
              @t_trn         = 21469,
              @i_transaccion = 'E',
              @i_linea       = @i_linea,
              @i_valor       = @w_valor,
              @i_valor_ref   = @w_monto_linea,
              @i_moneda      = @w_moneda_linea

              if @w_return != 0
               begin
                return @w_return
              end
        end 
	 end 


   if @i_batch <> 'S'
      commit tran
end

--- SI OPERACION ES R (RECUPERACION)

if @i_tipo in ('R', 'A') --SBU: 27/sep/99
begin
   if @i_batch <> 'S'
   begin tran
         --- Actualizo el maximo riesgo  del grupo  si el cliente pertenece
         --- a algun grupo economico, y de igual manera al sector economico

         /*
         if @w_gru_cliente is not null and @w_paramcem = 'S'
         begin
            update cobis..cl_grupo
            set gr_riesgo = isnull(gr_riesgo, 0) - @w_ries_utiliz,
                gr_reservado = isnull(gr_reservado, 0) - @w_ries_reserv   --SBU   CD00054
            where gr_grupo = @w_gru_cliente

            if @@error <> 0
            begin
               if @i_batch <> 'S'
               exec cobis..sp_cerror
               @t_debug = @t_debug,
               @t_file  = @t_file,
               @t_from  = @w_sp_name,
               @i_num   = 2105001
               return 2105001
            end
         end -- Fin de grupo is not null

         if @w_sectoreco is not null and @w_paramcem = 'S'
         begin

            update cobis..cl_sectoreco
            set se_riesgo = isnull(se_riesgo, 0) -  @w_ries_utiliz,
      se_reservado = isnull(se_reservado, 0) - @w_ries_reserv  --SBU  CD00054
            where se_sector = @w_sectoreco

            if @@error <> 0
            begin
                 if @i_batch <> 'S'
                 exec cobis..sp_cerror
                 @t_debug = @t_debug,
                 @t_file  = @t_file,
                 @t_from  = @w_sp_name,
                 @i_num   = 2105001
                 return 2105001
            end
         end  -- Fin de sectoreco is not null

         if @i_cliente is not null     and @w_paramcem = 'S'
         begin

            update cobis..cl_ente
            set en_riesgo = isnull(en_riesgo, 0) -  @w_ries_utiliz,
              en_reservado = isnull(en_reservado, 0) - @w_ries_reserv
            where en_ente = @i_cliente

            if @@error <> 0
            begin
                 if @i_batch <> 'S'
                 exec cobis..sp_cerror
                 @t_debug = @t_debug,
                 @t_file  = @t_file,
                 @t_from  = @w_sp_name,
                 @i_num   = 2105001
                 return 2105001
            end
         end  -- Fin de cliente is not null
         */

   if @i_batch <> 'S'
   commit tran
end

--- SI OPERACION ES C (CONTROL DE DISPONIBILIDAD)
if (@i_tipo = 'C')
begin
   if @i_tramite is null
      select @w_tipo_tramite = @i_tipo_tramite

   --Incluir financiamientos  JSB 99-04-03
   if @w_tipo_tramite <> 'O' and @w_tipo_tramite <> 'R' and  @w_tipo_tramite <> 'T' and  @w_tipo_tramite <> 'U'
      -- SALIR SIN PROCESAR
      return 0

      -- OBTENGO LA DIFERENCIA EN MONTO PARA ESTE TRAMITE
      if @w_tipo_tramite = 'R'
      begin
         --emg optimizacion may-31-02
         select @w_monto_reno = isnull(x.tr_monto * a.cv_ult_valor,0),
                @w_cotiza = isnull(a.cv_ult_valor,0),
                @w_monto_aux = isnull(x.tr_monto,0)
         from   cr_tramite x, cob_conta..cb_ult_fecha_cotiz_mon a
         where  x.tr_tramite = @i_tramite
         and    a.cv_moneda = x.tr_moneda

		 select @w_monto = isnull(sum(y.or_monto_original * b.cv_ult_valor), 0)
          from  cr_op_renovar y, cob_conta..cb_ult_fecha_cotiz_mon b
          where  y.or_tramite = @i_tramite
          and  b.cv_moneda = y.or_moneda_original
          group by y.or_tramite
          having isnull(sum(y.or_monto_original * b.cv_ult_valor), 0)  < @w_monto_reno
		  
		 select @w_monto_renovaciones = isnull(@w_monto_aux * @w_cotiza, 0) - @w_monto

		  /*
         select @w_monto_renovaciones =
          isnull(@w_monto_aux * @w_cotiza, 0) -
          (select isnull(sum(y.or_monto_original * b.cv_ult_valor), 0)
          from  cr_op_renovar y, cob_conta..cb_ult_fecha_cotiz_mon b
          where  y.or_tramite = @i_tramite
          and  b.cv_moneda = y.or_moneda_original
          group by y.or_tramite
          having isnull(sum(y.or_monto_original * b.cv_ult_valor), 0)  < @w_monto_reno )
*/
          select @w_monto_renovaciones = isnull(@w_monto_renovaciones,0)
          select @w_riesgo_actual = @w_monto_renovaciones
      end

      if (@i_cliente is not null and @i_valida is null)
      begin
         select @w_entramite_rcliente = sum(lr_reservado * cv_ult_valor)
         from   cr_tramite , cr_lin_reservado x,
      cob_conta..cb_ult_fecha_cotiz_mon
         where  lr_cliente    = @i_cliente
    and    lr_tramite >= 0
         and    lr_tramite <> @i_tramite    -- EXCLUYO EL TRAMITE
    and    tr_tramite = lr_tramite
         and    tr_estado not in ('Z','X','R','S')            -- NO RECHAZADOS DEFINITIVAMENTE
    and    cv_moneda = x.lr_moneda

    select @w_entramite_rcliente = isnull(@w_entramite_rcliente, 0)

         select @w_ries_disp_cliente = @w_ries_disp_cliente - @w_entramite_rcliente

          if ((@w_ries_disp_cliente < @w_riesgo_actual) and @w_paramcem = 'S')
          begin
             if @i_batch <> 'S'
             exec cobis..sp_cerror
             @t_debug   = @t_debug,
             @t_file    = @t_file,
             @t_from    = @w_sp_name,
             @i_num     = 2101115
             return 2101115
          end
      end

      if (@w_gru_cliente is not null and @i_valida is null)
      begin
         select @w_entramite_grupo = sum(lr_reservado * cv_ult_valor)
         from   cr_tramite , cr_lin_reservado x, cobis..cl_ente,
      cob_conta..cb_ult_fecha_cotiz_mon
         where  lr_tramite <> @i_tramite
         and    tr_tramite = lr_tramite
         and    tr_estado not in ('Z','X','R','S')          -- NO RECHAZADOS DEFINITIVAMENTE
         and    en_ente = lr_cliente
         and    en_grupo   = @w_gru_cliente
    and    cv_moneda = x.lr_moneda

    select @w_entramite_grupo = isnull(@w_entramite_grupo, 0)

         select @w_ries_disp_grupo = @w_ries_disp_grupo - @w_entramite_grupo

         if ((@w_ries_disp_grupo < @w_riesgo_actual)  and @w_paramcem = 'S')
         begin
             if @i_batch <> 'S'
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file,
             @t_from  = @w_sp_name,
             @i_num   = 2101137
             return 2101137
         end
      end -- Fin de grupo is not null

      if (@w_sectoreco is not null and @i_valida is null and @w_paramcem = 'S')
      begin
         select @w_entramite_sector = sum(lr_reservado * cv_ult_valor)
         from   cr_tramite , cr_lin_reservado x, cobis..cl_ente,
      cob_conta..cb_ult_fecha_cotiz_mon
         where  lr_tramite <> @i_tramite
         and    tr_tramite = lr_tramite
         and    tr_estado not in ('Z','X','R','S')       -- NO RECHAZADOS DEFINITIVAMENTE
         and    en_ente = lr_cliente
         and    en_sector  = @w_sectoreco
         and    lr_moneda = cv_moneda
    and    cv_moneda = x.lr_moneda

    select @w_entramite_sector = isnull(@w_entramite_sector, 0)

         select @w_ries_disp_sector = @w_ries_disp_sector - @w_entramite_sector

         if ((@w_ries_disp_sector < @w_riesgo_actual) and @w_paramcem = 'S')
            print 'Sobrepasa maximo riesgo de sector economico'

      end  -- Fin de sectoreco is not null

end

end   -- (@i_opcion <> 'P' or @i_opcion = NULL) and (@i_modo = 1)

return 0
ERROR:
if @i_batch <> 'S' begin
   exec cobis..sp_cerror
   @t_from    = @w_sp_name,
   @i_num     = @w_error
   return @w_error
end


GO
