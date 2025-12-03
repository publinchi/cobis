/************************************************************************/
/*  Archivo:                        montopagr.sp                        */
/*  Stored procedure:               sp_montos_pago_grupal               */
/*  Base de datos:                  cob_cartera                         */
/*  Producto:                       Cartera                             */
/************************************************************************/
/*                              IMPORTANTE                              */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                                  PROPOSITO                           */
/*  Obtiene Montos Vencido y Vigente de Operacion Grupal e Interciclos  */
/************************************************************************/  
/*                              MODIFICACIONES                          */
/*      FECHA               AUTOR                RAZON                  */
/*      01/07/2019          Luis Ponce           Emision Inicial        */
/*      22/07/2019          Luis Ponce           Cuota a debitar Batch. */
/*      01/08/2019          Luis Ponce           Nombre Presidente Grupo*/
/*      03/12/2019          Luis Ponce Cobro Indiv Acumulado,Grupal Proy*/
/*      01/06/2021          Johan Hernandez      Se realiza modificacion*/
/*												 para que no suceda     */
/*                                               table scan / se deja   */
/*                                               pago grupal acumulado  */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_montos_pago_grupal')
    drop proc sp_montos_pago_grupal
go

create proc sp_montos_pago_grupal
   @i_banco                 cuenta,                   --cuenta grupal padre
   @i_batch                 char(1)      = 'N',       --Se procesa en batch   
   @o_codigo_grupo          INT          = NULL OUT,
   @o_nombre_grupo          varchar(255) = NULL OUT,
   @o_nom_cliente           varchar(64)  = NULL OUT,
   @o_cta_banco             cuenta       = NULL OUT,
   @o_estado                varchar(64)  = NULL OUT,
   @o_cuota_ven             MONEY        = 0    OUT,
   @o_cuota_vig             MONEY        = 0    OUT,
   @o_total_pag             MONEY        = 0    OUT,
   @o_liquidar              MONEY        = 0    OUT,
   @o_tipo_credito          varchar(64)  = NULL OUT,
   @o_tipo_cartera          varchar(64)  = NULL OUT,
   @o_cuota_ven_interc      MONEY        = 0    OUT,
   @o_cuota_vig_interc      MONEY        = 0    OUT,
   @o_total_pag_interc      MONEY        = 0    OUT,
   @o_liquidar_interc       MONEY        = 0    OUT,
   @o_tipo_op_grupal        CHAR(1)      = NULL OUT,
   @o_toperacion            catalogo     = NULL OUT,
   @o_monto_cuota           MONEY        = 0    OUT --Cuota a debitar por batch
as

declare @w_sp_name                   descripcion,
        @w_error                     int,
        @w_operacionca               int,
        @w_moneda_op                 int,
        @w_estado                    tinyint,
        @w_fecha_liq                 datetime,
        @w_fecha_ult_proceso         datetime,
        @w_tipo_cobro                char(1),
        @w_est_vigente               tinyint,
        @w_est_vencido               tinyint,
        @w_est_cancelado             tinyint,
        @w_est_novigente             tinyint,
        @w_vencido_grupal            money,
        @w_vencido_interciclo        money,
        @w_vigente_grupal            money,
        @w_vigente_interciclo        money,
        @w_monto_aplicar             money,
        @w_total_exigible            money,
        @w_hasta_div_vigente         money,
        @w_div_novigentes            money,
        @w_total_precancelar         money,
        @w_grupo                     int,
        @w_nombre_grupo              varchar(255),
        @w_novigente_grupal          MONEY,
        @w_novigente_interciclo      MONEY,
        @w_toperacion                catalogo,
        --Variables para Teller
        @w_nom_cliente               varchar(64),
        @w_cta_banco                 cuenta,
        @w_desc_estado               varchar(64),
        @w_tipo_grupal               CHAR(1),
        @w_op_ref_grupal             cuenta,
        @w_sector                    catalogo,
        @w_cod_presid_grp             INT,
        @w_presidente_grp            varchar(64),
        @w_vigente_grupal_precan     MONEY,
        @w_vigente_interciclo_precan MONEY,
        @w_fecha_proceso        datetime --JH se agrega variable fecha del sistema
        

    
select @w_sp_name = 'sp_montos_pago_grupal'
 
/* ESTADOS DE CARTERA */
exec @w_error         = sp_estados_cca
     @o_est_vigente   = @w_est_vigente   out,
     @o_est_vencido   = @w_est_vencido   out,
     @o_est_cancelado = @w_est_cancelado out,
     @o_est_novigente = @w_est_novigente out
 
if @w_error <> 0 return 708201


/* VALIDACIONES */

/* VERIFICAR EXISTENCIA DE OPERACION GRUPAL */
select @w_operacionca       = op_operacion,
       @w_moneda_op         = op_moneda,
       @w_estado            = op_estado,
       @w_fecha_liq         = op_fecha_liq,
       @w_fecha_ult_proceso = op_fecha_ult_proceso,
       @w_tipo_cobro        = op_tipo_cobro,
       @w_toperacion        = op_toperacion,
       @w_grupo             = op_grupo,
       @w_nombre_grupo      = (select gr_nombre from cobis..cl_grupo where gr_grupo = OP.op_grupo),
       @w_nom_cliente       = op_nombre,
       @w_cod_presid_grp    = op_cliente,
       @w_cta_banco         = op_cuenta,
       @w_desc_estado       = (SELECT es_descripcion FROM ca_estado WHERE es_codigo = OP.op_estado),
       @w_sector            = op_sector
              
from   ca_operacion OP
where  op_banco = @i_banco

if @@rowcount = 0 return 701049


/*DETERMINA EL TIPO DE OPERACION ((G)rupal, (I)nterciclo, I(N)dividual)*/
EXEC @w_error = sp_tipo_operacion
     @i_banco  = @i_banco,
     @o_tipo   = @w_tipo_grupal out

IF @w_error <> 0
BEGIN
   RETURN @w_error
END


/*DETERMINAR EL TIPO DE COBRO DEL PRODUCTO*/
/*SELECT @w_tipo_cobro = dt_tipo_cobro  --LPO TEC Se deja el tipo de cobro desde la Operacion, no desde el Producto
from ca_default_toperacion
WHERE dt_toperacion = @w_toperacion
*/

/* CREAR TABLAS TEMPORALES */                                                                                                                                                                                                                                              

/* CREAR TABLA DE OPERACIONES INTERCICLOS */
create table #TMP_operaciones (
       operacion     int,
       banco         cuenta,
       monto         money,
       fecha_proceso datetime,
       fecha_liq     datetime)
	   
/* JH OBTIENE FECHA DEL SISTEMA*/ 
select @w_fecha_proceso = fp_fecha 
    from cobis..ba_fecha_proceso

/* DETERMINAR LAS OPERACIONES INTERCICLOS RELACIONADAS CON EL GRUPO*/
IF @w_tipo_grupal = 'G'
BEGIN
   insert into #TMP_operaciones
   select op_operacion, op_banco, op_monto, op_fecha_ult_proceso, op_fecha_liq
   from   ca_operacion, ca_estado                                                                                                                                                                                                                                    
   where op_estado = es_codigo
     AND es_procesa = 'S'
     AND op_operacion in (select dc_operacion from ca_det_ciclo where dc_referencia_grupal = @i_banco and  dc_tciclo = 'I')
   order by op_operacion
END   

/* DETERMINAR UNA OPERACION INTERCICLO O UNA INDIVIDUAL QUE SE CONSULTAN POR SEPARADO DESDE FRONT END */
IF @w_tipo_grupal IN ('I', 'N')
BEGIN
   insert into #TMP_operaciones
   select op_operacion, op_banco, op_monto, op_fecha_ult_proceso, op_fecha_liq
   from   ca_operacion, ca_estado                                                                                                                                                                                                                                    
   where op_estado = es_codigo
     AND es_procesa = 'S'
     AND op_banco   = @i_banco --OP. INTERCICLO O INDIVIDUAL
   order by op_operacion
END


/* DETERMINAR EL MONTO VENCIDO DE LA OPERACION GRUPAL */

select @w_vencido_grupal = (sum(am_cuota + am_gracia - am_pagado) + abs(sum(am_cuota + am_gracia - am_pagado)))/2
from cob_credito..cr_tramite_grupal,
     ca_amortizacion,
     ca_dividendo
where tg_tramite = (SELECT op_tramite
                    FROM ca_operacion
                    WHERE op_banco = @i_banco)
AND   tg_operacion = di_operacion
AND   di_operacion = am_operacion
and   di_dividendo = am_dividendo
and   di_estado = @w_est_vencido
and   am_estado <>  @w_est_cancelado



/* DETERMINAR EL MONTO VENCIDO DE INTERCICLOS DE UNA GRUPAL, O DE UNA INTERCICLO O DE UNA INDIVIDUAL*/
select @w_vencido_interciclo = (sum(am_cuota + am_gracia - am_pagado) + abs(sum(am_cuota + am_gracia - am_pagado)))/2
from   ca_amortizacion, ca_dividendo
where  di_operacion  = am_operacion
and    di_dividendo  = am_dividendo
and    di_operacion in (select operacion from #TMP_operaciones) --AQUI #TMP_porcentajes
and    di_estado     = @w_est_vencido
and    am_estado     <> @w_est_cancelado
 

/* DETERMINAR EL MONTO VIGENTE DE LA OPERACION GRUPAL */
if @w_tipo_cobro = 'P' -- Paga los interes proyectados
   select @w_vigente_grupal = (sum(am_cuota + am_gracia - am_pagado) + abs(sum(am_cuota + am_gracia - am_pagado)))/2
   from cob_credito..cr_tramite_grupal,
        ca_amortizacion,
        ca_dividendo
   where tg_tramite = (SELECT op_tramite
                       FROM ca_operacion
                       WHERE op_banco = @i_banco)
   AND   tg_operacion = di_operacion
   AND   di_operacion = am_operacion
   and   di_dividendo = am_dividendo
   and   di_estado = @w_est_vigente
   and   am_estado <>  @w_est_cancelado
--   AND    @w_fecha_ult_proceso >= di_fecha_ini --LPO TEC toma solo el saldo vigente exigible a la fecha de proceso,
--   AND    @w_fecha_ult_proceso <= di_fecha_ven --No del dividendo vigente mayor a la fecha de ultimo proceso.
else -- Paga los interes acumulados
   select @w_vigente_grupal = (sum(am_acumulado + am_gracia - am_pagado) + abs(sum(am_acumulado + am_gracia - am_pagado)))/2
   from cob_credito..cr_tramite_grupal,
        ca_amortizacion,
        ca_dividendo
   where tg_tramite = (SELECT op_tramite
                       FROM ca_operacion
                       WHERE op_banco = @i_banco)
   AND   tg_operacion = di_operacion
   AND   di_operacion = am_operacion
   and   di_dividendo = am_dividendo
   and   di_estado = @w_est_vigente
   and   am_estado <>  @w_est_cancelado
--   AND    @w_fecha_ult_proceso  >= di_fecha_ini --LPO TEC toma solo el saldo vigente exigible a la fecha de proceso,
--   AND    @w_fecha_ult_proceso  <= di_fecha_ven --No del dividendo vigente mayor a la fecha de ultimo proceso.
   


/* DETERMINAR EL MONTO VIGENTE DE INTERCICLOS */
if @w_tipo_cobro = 'P' -- Paga los interes proyectados
   select @w_vigente_interciclo = (sum(am_cuota + am_gracia - am_pagado) + abs(sum(am_cuota + am_gracia - am_pagado)))/2
   from   ca_amortizacion, ca_dividendo
   where  di_operacion  = am_operacion
   and    di_dividendo  = am_dividendo
   and    di_operacion in (select operacion from #TMP_operaciones)
   and    di_estado     = @w_est_vigente
   and    am_estado    <> @w_est_cancelado
else -- Paga los interes acumulados
   select @w_vigente_interciclo = (sum(am_acumulado + am_gracia - am_pagado) + abs(sum(am_acumulado + am_gracia - am_pagado)))/2
   from   ca_amortizacion, ca_dividendo
   where  di_operacion  = am_operacion
   and    di_dividendo  = am_dividendo
   and    di_operacion in (select operacion from #TMP_operaciones)
   and    di_estado     = @w_est_vigente
   and    am_estado    <> @w_est_cancelado
 

/* CONTROLAR MONTOS DE PAGO */
select @w_vencido_grupal     = isnull(@w_vencido_grupal, 0)
select @w_vigente_grupal     = isnull(@w_vigente_grupal, 0)
select @w_vencido_interciclo = isnull(@w_vencido_interciclo, 0)
select @w_vigente_interciclo = isnull(@w_vigente_interciclo, 0)

/* MONTO TOTAL EXIGIBLE */
select @w_total_exigible = @w_vencido_grupal + @w_vigente_grupal + @w_vencido_interciclo + @w_vigente_interciclo

/* MONTO TOTAL PRECANCELAR */
/* MONTO NO VIGENTE GRUPAL*/
select @w_novigente_grupal = (sum(am_acumulado + am_gracia - am_pagado) + abs(sum(am_acumulado + am_gracia - am_pagado)))/2
from   ca_amortizacion, ca_dividendo, ca_rubro_op, cob_credito..cr_tramite_grupal
where tg_tramite = (SELECT op_tramite
                    FROM ca_operacion
                    WHERE op_banco = @i_banco)
AND    tg_operacion = di_operacion
and    di_operacion = am_operacion
and    di_dividendo = am_dividendo
and    di_estado    = @w_est_novigente
and    am_estado   <> @w_est_cancelado
and    di_operacion = ro_operacion
and    am_operacion = ro_operacion
and    ro_concepto  = am_concepto
and    ro_tipo_rubro = 'C'


/* MONTO NO VIGENTE DE INTERCICLOS DE UNA GRUPAL, O DE UNA INTERCICLO O DE UNA INDIVIDUAL*/
select @w_novigente_interciclo = (sum(am_acumulado + am_gracia - am_pagado) + abs(sum(am_acumulado + am_gracia - am_pagado)))/2
   from   ca_amortizacion, ca_dividendo, ca_rubro_op
   where  di_operacion  = am_operacion
   and    di_dividendo  = am_dividendo
   and    di_operacion  IN (select operacion from #TMP_operaciones)
   and    di_estado     = @w_est_novigente
   and    am_estado     <> @w_est_cancelado
   and    di_operacion = ro_operacion
   and    am_operacion = ro_operacion
   and    ro_concepto  = am_concepto
   and    ro_tipo_rubro = 'C'
   

select @w_novigente_grupal  = isnull(@w_novigente_grupal,0)
select @w_novigente_interciclo = isnull(@w_novigente_interciclo,0)

--select @w_total_precancelar = @w_total_exigible + @w_novigente_grupal + @w_novigente_interciclo

--LPO TEC NUEVA DEFINCION, PARA GRUPAL SIEMPRE DEBE SER PROYECTADO, Y PARA INDIVIDUAL SIEMPRE ACUMULADO
select @w_vigente_grupal_precan = 0
select @w_vigente_interciclo_precan = 0

/*IF @w_tipo_cobro = 'P'
   select @w_vigente_grupal_precan = (sum(am_cuota + am_gracia - am_pagado) + abs(sum(am_cuota + am_gracia - am_pagado)))/2
   from cob_credito..cr_tramite_grupal,
        ca_amortizacion,
        ca_dividendo
   where tg_tramite = (SELECT op_tramite
                       FROM ca_operacion
                       WHERE op_banco = @i_banco)
   AND   tg_operacion = di_operacion
   AND   di_operacion = am_operacion
   and   di_dividendo = am_dividendo
   and   di_estado =   @w_est_vigente
   and   am_estado <>  @w_est_cancelado
--   AND    di_fecha_ven <= @w_fecha_ult_proceso --Si la fecha de proceso de la grupal no ha llegado a la fecha de vencimiento del dividendo vigente no se debe debitar por lo que ese saldo No se toma en cuenta.
else -- Paga los interes acumulados 
*/
   select @w_vigente_grupal_precan = (sum(am_acumulado + am_gracia - am_pagado) + abs(sum(am_acumulado + am_gracia - am_pagado)))/2
   from cob_credito..cr_tramite_grupal,
        ca_amortizacion,
        ca_dividendo
   where tg_tramite = (SELECT op_tramite
                       FROM ca_operacion
                       WHERE op_banco = @i_banco)
   AND   tg_operacion = di_operacion
   AND   di_operacion = am_operacion
   and   di_dividendo = am_dividendo
   and   di_estado =   @w_est_vigente
   and   am_estado <>  @w_est_cancelado
--   AND    di_fecha_ven <= @w_fecha_ult_proceso --Si la fecha de proceso de la grupal no ha llegado a la fecha de vencimiento del dividendo vigente no se debe debitar por lo que ese saldo No se toma en cuenta.
--print '@w_vigente_grupal_precan: ' + convert (varchar,@w_vigente_grupal_precan) --JH

IF @w_tipo_grupal = 'G'
   select @w_vigente_interciclo_precan = (sum(am_cuota + am_gracia - am_pagado) + abs(sum(am_cuota + am_gracia - am_pagado)))/2
   from   ca_amortizacion, ca_dividendo
   where  di_operacion  = am_operacion
   and    di_dividendo  = am_dividendo
   and    di_operacion in (select operacion from #TMP_operaciones)
   and    di_estado     = @w_est_vigente
   and    am_estado    <> @w_est_cancelado
else -- Paga los interes acumulados
   select @w_vigente_interciclo_precan = (sum(am_acumulado + am_gracia - am_pagado) + abs(sum(am_acumulado + am_gracia - am_pagado)))/2
   from   ca_amortizacion, ca_dividendo
   where  di_operacion  = am_operacion
   and    di_dividendo  = am_dividendo
   and    di_operacion in (select operacion from #TMP_operaciones)
   and    di_estado     = @w_est_vigente
   and    am_estado    <> @w_est_cancelado

select @w_vigente_grupal_precan = isnull(@w_vigente_grupal_precan, 0)
select @w_vigente_interciclo_precan = isnull(@w_vigente_interciclo_precan, 0)

select @w_total_precancelar = @w_vencido_grupal + @w_vigente_grupal_precan + @w_vencido_interciclo + @w_vigente_interciclo_precan + @w_novigente_grupal + @w_novigente_interciclo

--LPO TEC FIN NUEVA DEFINCION, PARA GRUPAL SIEMPRE DEBE SER PROYECTADO, Y PARA INDIVIDUAL SIEMPRE ACUMULADO




/*DETERMINAR CODIGO Y NOMBRE DEL PRESIDENTE DEL GRUPO*/

SELECT @w_presidente_grp = @w_nom_cliente


select @w_grupo,
       @w_nombre_grupo,
       @w_vencido_grupal,
       @w_vencido_interciclo,
       @w_vigente_grupal,
       @w_vigente_interciclo,
       @w_total_exigible,
       @w_total_precancelar,
       @w_cod_presid_grp,
       @w_presidente_grp
       

--TELLER:
SELECT @o_nom_cliente      = @w_nom_cliente,
       @o_cta_banco        = @w_cta_banco,
       @o_estado           = @w_desc_estado,
       @o_toperacion       = @w_toperacion,
       @o_tipo_credito     = (select b.valor
                              from cobis..cl_tabla a, cobis..cl_catalogo b
                              where a.tabla = 'ca_toperacion' and a.codigo = b.tabla and b.codigo = @w_toperacion),
       @o_tipo_cartera     = (select b.valor
                              from cobis..cl_tabla a, cobis..cl_catalogo b
                              where a.tabla = 'cc_sector' and a.codigo = b.tabla and b.codigo = @w_sector),
       @o_tipo_op_grupal   = @w_tipo_grupal

--JH
if exists (SELECT 1   
    FROM cob_credito..cr_tramite_grupal, cob_cartera..ca_operacion
	where tg_tramite =(SELECT op_tramite
                    FROM ca_operacion
                    WHERE op_banco = @i_banco) ----tramite grupal creado
	AND tg_operacion = op_operacion
	AND   op_fecha_ult_proceso <> @w_fecha_proceso) 
begin
	select @w_error = 711098
	goto ERROR
end
       
        
IF @w_tipo_grupal = 'G'
BEGIN
   SELECT @o_codigo_grupo     = @w_grupo                                                       --Es el codigo del grupo
   SELECT @o_nombre_grupo     = @w_nombre_grupo                                                --Es el nombre del grupo
   SELECT @o_cuota_ven        = @w_vencido_grupal                                              --Es el vencido de la grupal
   SELECT @o_cuota_vig        = @w_vigente_grupal                                              --Es el vigente de la grupal
   SELECT @o_total_pag        = @w_vencido_grupal + @w_vigente_grupal                          --Es el total exigible de la grupal
   --SELECT @o_liquidar         = @o_total_pag + @w_novigente_grupal                             --Es el total para Precancelacion de la grupal
   SELECT @o_liquidar         = @w_vencido_grupal + @w_vigente_grupal_precan                   --Es el total para Precancelacion de la grupal    
                                + @w_novigente_grupal                                          
   SELECT @o_cuota_ven_interc = @w_vencido_interciclo                                          --Es el vencido de todos los interciclos de la Grupal
   SELECT @o_cuota_vig_interc = @w_vigente_interciclo                                          --Es el vigente de todos los interciclos de la Grupal
   SELECT @o_total_pag_interc = @w_vencido_interciclo + @w_vigente_interciclo                  --Es el total exigible de todas las interciclos
   --SELECT @o_liquidar_interc  = @o_total_pag_interc + @w_novigente_interciclo                  --Es el total para Precancelacion de todas las interciclos
   SELECT @o_liquidar_interc  = @w_vencido_interciclo + @w_vigente_interciclo_precan           --Es el total para Precancelacion de todas las interciclos
                                + @w_novigente_interciclo                                      
END
IF @w_tipo_grupal IN ('I', 'N')
BEGIN
   IF @w_tipo_grupal = 'I'
   BEGIN
      SELECT @w_op_ref_grupal = op_ref_grupal
      FROM ca_operacion where op_banco = @i_banco

      SELECT @w_grupo         = op_grupo,
             @w_nombre_grupo  = gr_nombre
      FROM cobis..cl_grupo, ca_operacion
      WHERE op_banco = @w_op_ref_grupal
        AND gr_grupo = op_grupo
      
      SELECT @o_codigo_grupo  = @w_grupo                                             --Es el codigo del grupo
      SELECT @o_nombre_grupo  = @w_nombre_grupo                                      --Es el nombre del grupo
   END
   IF @w_tipo_grupal = 'N'
   BEGIN
      SELECT @o_codigo_grupo  = ''                                                   --Es el codigo del grupo
      SELECT @o_nombre_grupo  = ''                                                   --Es el nombre del grupo      
   END
   
   SELECT @o_cuota_ven        = @w_vencido_interciclo                                --Es el vencido de UNA Interciclo o de UNA Individual
   SELECT @o_cuota_vig        = @w_vigente_interciclo                                --Es el vigente de UNA Interciclo o de UNA Individual
   SELECT @o_total_pag        = @w_vencido_interciclo + @w_vigente_interciclo        --Es el total exigible de UNA Interciclo o de UNA Individual
   --SELECT @o_liquidar         = @o_total_pag + @w_novigente_interciclo                --Es el total para Precancelacion de UNA Interciclo o de UNA Individual
   SELECT @o_liquidar         = @w_vencido_interciclo + @w_vigente_interciclo_precan --Es el total para Precancelacion de UNA Interciclo o de UNA Individual
                                + @w_novigente_interciclo                            
   SELECT @o_cuota_ven_interc = 0                                                    --Es el vencido de todos los interciclos de la Grupal
   SELECT @o_cuota_vig_interc = 0                                                    --Es el vigente de todos los interciclos de la Grupal
   SELECT @o_total_pag_interc = 0                                                    --Es el total exigible de todas las interciclos
   SELECT @o_liquidar_interc  = 0                                                    --Es el total para Precancelacion de todas las interciclos
END

IF @i_batch = 'S' --Para el Batch se requiere el saldo de la cuota (vencido + vigente) pero el Vigente s�lo hasta la fecha de ultimo proceso de la operacion grupal.
BEGIN             --Si el dividendo vigente tiene fecha de inicio mayor a la fecha de ultimo proceso de la op grupal ese saldo No se toma en cuenta.

   /* DETERMINAR EL MONTO VIGENTE DE LA OPERACION GRUPAL */
  if @w_tipo_cobro = 'P' -- Paga los interes proyectados
     select @w_vigente_grupal = (sum(am_cuota + am_gracia - am_pagado) + abs(sum(am_cuota + am_gracia - am_pagado)))/2
      from   ca_amortizacion, ca_dividendo
      where  di_operacion = am_operacion
      and    di_dividendo = am_dividendo
      and    di_operacion = @w_operacionca
      and    di_estado    = @w_est_vigente
      and    am_estado    <> @w_est_cancelado
      AND    di_fecha_ven <= @w_fecha_ult_proceso --Si la fecha de proceso de la grupal no ha llegado a la fecha de vencimiento del dividendo vigente no se debe debitar por lo que ese saldo No se toma en cuenta.
   else -- Paga los interes acumulados
      select @w_vigente_grupal = (sum(am_acumulado + am_gracia - am_pagado) + abs(sum(am_acumulado + am_gracia - am_pagado)))/2
      from   ca_amortizacion, ca_dividendo
      where  di_operacion = am_operacion
      and    di_dividendo = am_dividendo
      and    di_operacion = @w_operacionca
      and    di_estado    = @w_est_vigente
      and    am_estado    <> @w_est_cancelado
      AND    di_fecha_ven <= @w_fecha_ult_proceso --Si la fecha de proceso de la grupal no ha llegado a la fecha de vencimiento del dividendo vigente no se debe debitar por lo que ese saldo No se toma en cuenta.
      
      
   /* DETERMINAR EL MONTO VIGENTE DE INTERCICLOS */
   if @w_tipo_cobro = 'P' -- Paga los interes proyectados
      select @w_vigente_interciclo = (sum(am_cuota + am_gracia - am_pagado) + abs(sum(am_cuota + am_gracia - am_pagado)))/2
      from   ca_amortizacion, ca_dividendo
      where  di_operacion  = am_operacion
      and    di_dividendo  = am_dividendo
      and    di_operacion in (select operacion from #TMP_operaciones)
      and    di_estado     = @w_est_vigente
      and    am_estado    <> @w_est_cancelado
      AND    di_fecha_ven <= @w_fecha_ult_proceso --Si la fecha de proceso de la grupal no ha llegado a la fecha de vencimiento del dividendo vigente no se debe debitar por lo que ese saldo No se toma en cuenta.
   else -- Paga los interes acumulados
      select @w_vigente_interciclo = (sum(am_acumulado + am_gracia - am_pagado) + abs(sum(am_acumulado + am_gracia - am_pagado)))/2
      from   ca_amortizacion, ca_dividendo
      where  di_operacion  = am_operacion
      and    di_dividendo  = am_dividendo
      and    di_operacion in (select operacion from #TMP_operaciones)
      and    di_estado     = @w_est_vigente
      and    am_estado    <> @w_est_cancelado
      AND    di_fecha_ven <= @w_fecha_ult_proceso --Si la fecha de proceso de la grupal no ha llegado a la fecha de vencimiento del dividendo vigente no se debe debitar por lo que ese saldo No se toma en cuenta.
      
--PRINT '@w_fecha_ult_proceso MONTO PAGO' + CAST(@w_fecha_ult_proceso AS VARCHAR)

--SELECT * FROM #TMP_operaciones --LPO QUITAR

      
   /* CONTROLAR MONTOS DE PAGO */
   select @w_vencido_grupal     = isnull(@w_vencido_grupal, 0)
   select @w_vigente_grupal     = isnull(@w_vigente_grupal, 0)
   select @w_vencido_interciclo = isnull(@w_vencido_interciclo, 0)
   select @w_vigente_interciclo = isnull(@w_vigente_interciclo, 0)
   
   SELECT @o_monto_cuota = @w_vencido_grupal + @w_vencido_interciclo + @w_vigente_grupal + @w_vigente_interciclo
       
END
ELSE
   SELECT @o_monto_cuota = @w_total_exigible --Total Cuota, considerando lo vigente aunque la fecha de ultimo proceso de la op grupal sea menor que la de inicio del dividendo vigente.

return 0

ERROR:
exec cobis..sp_cerror
@t_debug='N',    
@t_file=null,
@t_from=@w_sp_name,   
@i_num = @w_error


go