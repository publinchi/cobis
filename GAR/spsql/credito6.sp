/*************************************************************************/
/*   Archivo:              credito6.sp                                   */
/*   Stored procedure:     sp_credito6                                   */
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
IF OBJECT_ID('dbo.sp_credito6') IS NOT NULL
    DROP PROCEDURE dbo.sp_credito6
go
create proc dbo.sp_credito6  (
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
   @i_codigo_compuesto   varchar(64) = null

)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_error              int,
   @w_contador           tinyint

select @w_today = getdate()
select @w_sp_name = 'sp_credito6'

/***********************************************************/
/* Codigos de Transacciones                                */

if (@t_trn <> 19404 and @i_operacion = 'S') 
     
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

      create table #cu_operacion_cliente (
             oc_producto         char(3),
             oc_operacion        varchar(24),
             oc_moneda           tinyint,
             oc_valor_inicial    money,
             oc_valor_actual     money,
             oc_fecha_venc       datetime)

      insert into #cu_operacion_cliente
      select  tr_producto,  
              op_banco,
              op_moneda,
              sum(am_acumulado),
              sum(am_acumulado - am_pagado),-- - am_exponencial
              --sum(ro_acumulado),
              --sum(ro_acumulado - ro_adelantado - ro_pagado),
              op_fecha_fin
       from cu_custodia,cob_credito..cr_gar_propuesta,cob_credito..cr_tramite,
            cob_cartera..ca_operacion,cob_cartera..ca_amortizacion
            --cob_cartera..ca_rubro_op
      where cu_garante        = @i_cliente
        and cu_codigo_externo = gp_garantia
        and cu_estado         not in ('A')
        and gp_tramite        = tr_tramite
        and tr_numero_op      = op_operacion
        and tr_producto       = 'CCA' 
        and am_operacion      = op_operacion
        and am_concepto       = 'CAP' -- (C)apital
      group by op_banco, tr_producto, op_moneda, op_fecha_fin
      order by op_banco /* HHO Mayo/2012    Migracion SYBASE 15 */
      /*  PGA: order by innecesario */
      /*  order by op_banco*/   

/*      insert into #cu_operacion_cliente
      select  tr_producto,  
              op_operacion_banco,
              op_moneda,
              op_importe,                 
              op_saldo,          
              op_fecha_expir
       from cu_custodia,cob_credito..cr_gar_propuesta,cob_credito..cr_tramite,
            cob_comext..ce_operacion
      where cu_garante        = @i_cliente
        and cu_codigo_externo = gp_garantia
        and cu_estado         not in ('A')
        and gp_tramite        = tr_tramite
        and tr_numero_op      = op_operacion
        and tr_producto       = 'CEX'*/

   if @i_producto is null -- PRIMEROS 20 REGISTROS
   begin
      set rowcount  20 
      select 'PRODUCTO'        = oc_producto,
             'OPERACION'       = oc_operacion,
             'MONEDA'          = oc_moneda,
             'VALOR INICIAL'   = oc_valor_inicial,
             'VALOR ACTUAL'    = oc_valor_actual,
             'FECHA VENCIM'    = oc_fecha_venc
      from #cu_operacion_cliente
      order by oc_producto,oc_operacion

      if @@rowcount = 0
         print 'No existen operaciones para este cliente'
 
   end else               -- 20 SIGUIENTES
   begin
       set rowcount  20 
       select 'PRODUCTO'        = oc_producto,
              'OPERACION'       = oc_operacion,
              'MONEDA'          = oc_moneda,
              'VALOR INICIAL'   = oc_valor_inicial,
              'VALOR ACTUAL'    = oc_valor_actual,
              'FECHA VENCIM'    = oc_fecha_venc
       from #cu_operacion_cliente
       where (oc_producto > @i_producto 
             or (oc_producto = @i_producto and oc_operacion > @i_operacion))
       order by oc_producto,oc_operacion 

       if @@rowcount = 20
          print 'No existen mas operaciones para este cliente'
   end
end
go