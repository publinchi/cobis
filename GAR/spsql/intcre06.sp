/*************************************************************************/
/*   Archivo:              intcre06.sp                                   */
/*   Stored procedure:     sp_intcre06                                   */
/*   Base de datos:        cob_custodia                                  */
/*   Producto:             Garantias                                     */
/*   Disenado por:                                                       */
/*   Fecha de escritura:   Marzo 2019                                    */
/*************************************************************************/
/*                                  IMPORTANTE                           */
/*   Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*   de MACOSA S.A.                                                      */
/*   Su uso no autorizado queda expresamente prohibido asi como          */
/*   cualquier alteracion o agregado hecho por alguno de sus             */
/*   usuarios sin el debido consentimiento por escrito de MACOSA         */
/*   Este programa esta protegido por la ley de derechos de autor        */
/*   y por las  convenciones  internacionales de  propiedad inte-        */
/*   lectual.  Su uso no  autorizado dara  derecho a  MACOSA para        */
/*   obtener  ordenes de  secuestro o retencion y  para perseguir        */
/*   penalmente a los autores de cualquier infraccion.                   */
/*************************************************************************/
/*                                   PROPOSITO                           */
/*    Creacion de objetos de la base. Comprende: tablas, indices,sp      */
/*    tipos de datos, claves primarias y foraneas                        */
/*                                                                       */
/*			                                                             */
/*************************************************************************/
/*                             MODIFICACION                              */
/*    FECHA                   AUTOR                 RAZON                */
/*    Marzo/2019                                      emision inicial    */
/*                                                                       */
/*************************************************************************/
USE cob_custodia
go
IF OBJECT_ID('dbo.sp_intcre06') IS NOT NULL
    DROP PROCEDURE dbo.sp_intcre06
go
create proc sp_intcre06  (
   @s_ssn                int      = null,
   @s_date               datetime = null,
   @s_user               login    = null,
   @s_term               varchar(64) = null,
   @s_corr               char(1)  = null,
   @s_ssn_corr           int      = null,
   @s_ofi                smallint  = null,
   @t_rty                char(1)  = null,
   @t_trn                smallint = null,
   @t_debug              char(1)  = 'N',
   @t_file               varchar(14) = null,
   @t_from               varchar(30) = null,
   @i_operacion          char(1)  = null,
   @i_producto           char(64) = null,
   @i_modo               smallint = null,
   @i_cliente            int = null,
   @i_filial 		 tinyint = null,
   @i_sucursal		 smallint = null,
   @i_tipo_cust		 varchar(64) = null,
   @i_custodia 		 int = null,
   @i_codigo_compuesto   varchar(64) = null,
   @i_garantia           varchar(64) = null,
   @i_operac             cuenta   = null,
   @o_opcion             money    = null out,
   @i_tipo_ctz		 char(1)  = "B"      -- C credito  B contabililidad

)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_error              int,
   @w_contador           tinyint,
   @w_est_no_vigente	 tinyint, -- estado de cartera no vigente
   @w_est_vigente	 tinyint, -- estado de cartera vigente
   @w_est_vencido	 tinyint, -- estado de cartera vencido
   @w_est_cancelado      tinyint, -- estado de cartera cancelado
   @w_est_credito	 tinyint, -- cuando trÂ mite esta en CRE no liquidado
   @w_def_moneda	 tinyint	-- Moneda Default

select @w_today = isnull(@s_date,getdate()) 

select @w_sp_name = 'sp_intcre06'

/***********************************************************/
/* Codigos de Transacciones                                */

if (@t_trn <> 19544 and @i_operacion = 'S') 
     
begin
/* tipo de transaccion no corresponde */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file, 
    @t_from  = @w_sp_name,
    @i_num   = 1901006
    return 1 

end

if @i_operacion = 'S'
begin

-- *** Tabla temporal de cotizaciones *****

-- Seleccion de codigo de moneda local
SELECT @w_def_moneda = pa_tinyint  
    FROM cobis..cl_parametro  
   WHERE pa_nemonico = 'MLOCR'   

if @@rowcount = 0
begin
    /*Registro no existe */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 2101005
	return 1
end

CREATE TABLE #cr_cotiz
(	moneda			tinyint null,
	cotizacion		money null
)

if @i_tipo_ctz = 'C'   -- cotizacion de credito
   insert into #cr_cotiz
   (moneda, cotizacion)
   select	
   a.cz_moneda, a.cz_valor
   from   cob_credito..cr_cotizacion a
   where  cz_fecha = (select max(b.cz_fecha)
	       	      from cob_credito..cr_cotizacion b
		      where b.cz_moneda = a.cz_moneda
	       	      and   b.cz_fecha <= @w_today)
else   -- cotizacion de la conta
   insert into #cr_cotiz
   (moneda, cotizacion)
   select	
   a.ct_moneda, a.ct_compra
   from   cob_conta..cb_cotizacion a
   where    ct_fecha = (select max(b.ct_fecha)
                        from cob_conta..cb_cotizacion b
                        where b.ct_moneda = a.ct_moneda
                        and b.ct_fecha <= @w_today)



-- insertar un registro para la moneda local
if not exists (select * from #cr_cotiz
	       where moneda = @w_def_moneda)
   insert into #cr_cotiz (moneda, cotizacion)
   values (@w_def_moneda, 1)



-- Estados de Cartera
   SELECT @w_est_no_vigente = pa_tinyint
   FROM cobis..cl_parametro
   WHERE pa_nemonico = 'ESTNVG'

   SELECT @w_est_vigente = pa_tinyint
   FROM cobis..cl_parametro
   WHERE pa_nemonico = 'ESTVG'

   SELECT @w_est_vencido = pa_tinyint
   FROM cobis..cl_parametro
   WHERE pa_nemonico = 'ESTVEN'

   SELECT @w_est_cancelado = pa_tinyint
   FROM cobis..cl_parametro
   WHERE pa_nemonico = 'ESTCAN'

   SELECT @w_est_credito = pa_tinyint
   FROM cobis..cl_parametro
   WHERE pa_nemonico = 'ESTCRE'


      create table #cu_operacion_cerrada1 (
             oc_producto         char(3),
             oc_operacion        varchar(24),
             oc_moneda           tinyint,
             oc_valor_inicial    money,
             oc_valor_actual     money,
             oc_fecha_venc       datetime)

      insert into #cu_operacion_cerrada1
      select  'CCA',  
              op_banco,
              op_moneda,
              op_monto,
              sum(isnull(am_cuota,0) + isnull(am_gracia,0) - isnull(am_pagado,0)), -- - isnull(am_exponencial,0)
              op_fecha_fin
       from cu_custodia,cob_credito..cr_gar_propuesta,
            cob_cartera..ca_operacion,
	    cob_cartera..ca_rubro_op, 
	    cob_cartera..ca_amortizacion
      where cu_codigo_externo  = @i_garantia
        and cu_abierta_cerrada = 'C'  -- Garantia Cerrada
        and cu_estado         not in ('A')
        and gp_garantia        = cu_codigo_externo
        and gp_tramite         = op_tramite
	and op_estado	       IN (@w_est_vigente,@w_est_no_vigente,@w_est_vencido)
        and ro_operacion       = op_operacion
        and ro_tipo_rubro      = 'C' -- (C)apital
        and ro_fpago           = 'P' -- (P)eriodica
	and am_operacion       = ro_operacion
        and am_concepto        = ro_concepto
      group by op_banco,op_moneda, op_monto, op_fecha_fin
      /*order by op_banco*/
      
      /*insert into #cu_operacion_cerrada1
      select  tr_producto,  
              op_operacion_banco,
              op_moneda,
              op_importe,                 
              op_saldo,          
              op_fecha_expir
       from cu_custodia,cob_credito..cr_gar_propuesta,cob_credito..cr_tramite,
            cob_comext..ce_operacion
      where cu_codigo_externo  = @i_garantia
        and cu_abierta_cerrada = 'C'  -- Garantia Cerrada
        and cu_codigo_externo  = gp_garantia
        and cu_estado          not in ('A')
        and gp_tramite         = tr_tramite
        and tr_tipo            in ('O','R') 
        and tr_numero_op       <> null       
        and tr_numero_op       = op_operacion
        and tr_producto        = 'CEX'
        and op_etapa           not in ('40','41','50')*/

   if @i_producto is null -- PRIMEROS 20 REGISTROS
   begin
      set rowcount  20 
      select distinct "PRODUCTO"        = oc_producto,
             "OPERACION"       = oc_operacion,
             "MONEDA"          = oc_moneda,
             "VALOR INICIAL"   = oc_valor_inicial,
             "VALOR ACTUAL"    = oc_valor_actual,
             "FECHA VENCIM"    = convert(char(10),oc_fecha_venc,103)
      from #cu_operacion_cerrada1
      order by oc_producto,oc_operacion
      set rowcount  0

      --if @@rowcount = 0

        -- print "No existen operaciones para esta garantia"
 
   end else               -- 20 SIGUIENTES
   begin
       set rowcount  20 
       select distinct "PRODUCTO"        = oc_producto,
              "OPERACION"       = oc_operacion,
              "MONEDA"          = oc_moneda,
              "VALOR INICIAL"   = oc_valor_inicial,
              "VALOR ACTUAL"    = oc_valor_actual,
              "FECHA VENCIM"    = convert(char(10),oc_fecha_venc,103)
       from #cu_operacion_cerrada1
       where (oc_producto > @i_producto 
             or (oc_producto = @i_producto and oc_operacion > @i_operac))
       order by oc_producto,oc_operacion 
       set rowcount  0

       --if @@rowcount = 20
         -- print "No existen mas operaciones para esta garantia"
   end
   select @o_opcion=isnull(sum(isnull(oc_valor_actual,0)*isnull(cotizacion,1)),0)
   from   #cu_operacion_cerrada1
   left join #cr_cotiz on oc_moneda = moneda

end
go