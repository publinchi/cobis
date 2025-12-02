/****************************************************************/
/* ARCHIVO:              riesgos2.sp                            */
/* Stored procedure:	 sp_riesgos2	          	            */
/* BASE DE DATOS:        cob_custodia 					        */
/* PRODUCTO:             GARANTIAS              	            */
/****************************************************************/
/*                         IMPORTANTE                           */
/* Esta aplicacion es parte de los paquetes bancarios propiedad */
/* de MACOSA S.A.						                        */
/* Su uso no  autorizado queda  expresamente prohibido asi como */
/* cualquier  alteracion  o agregado  hecho por  alguno  de sus */
/* usuarios sin el debido consentimiento por escrito de MACOSA. */
/* Este programa esta protegido por la ley de derechos de autor */
/* y por las  convenciones  internacionales de  propiedad inte- */
/* lectual.  Su uso no  autorizado dara  derecho a  MACOSA para */
/* obtener  ordenes de  secuestro o retencion y  para perseguir */
/* penalmente a los autores de cualquier infraccion.            */
/****************************************************************/
/*                      MODIFICACIONES                          */
/* FECHA               AUTOR                         RAZON      */
/* 28/Mar/2019       Luis  Ramirez  	        Emision Inicial */
/****************************************************************/

USE cob_custodia
go

IF OBJECT_ID('dbo.sp_riesgos2') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.sp_riesgos2
END
GO

create proc sp_riesgos2  (
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
   @o_opcion             money    = null out

)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_error              int,
   @w_contador           tinyint,
   @w_est_cancelado      tinyint,
   @w_est_precancelado   tinyint,
   @w_est_anulado        tinyint,
   @w_fecha_fin          datetime,
   @w_monto              money,
   @w_riesgo             money,
   @w_sum_riesgos        money,
   @w_deudor             int,
   @w_moneda             tinyint,
   @w_tramite            int,
   @w_toperacion         catalogo,
   @w_cotizacion         money,
   @w_producto           catalogo,
   @w_num_op_banco    varchar(15)

select @w_today = convert(varchar(10),getdate(),101)
select @w_sp_name = 'sp_riesgos2'

/***********************************************************/
/* Codigos de Transacciones                                */
if (@t_trn <> 19614 and @i_operacion = 'Q') 
begin
    /* tipo de transaccion no corresponde */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file, 
    @t_from  = @w_sp_name,
    @i_num   = 1901006
    return 1 
end
else
begin
   create table #temporal (moneda money, cotizacion money)
   insert into #temporal (moneda,cotizacion)
   select ct_moneda,ct_compra
   from cob_conta..cb_cotizacion a
   where    ct_fecha = (select max(b.ct_fecha)
			from cob_conta..cb_cotizacion b
			where b.ct_moneda = a.ct_moneda
			  and b.ct_fecha <= @w_today)
			  
end

if @i_operacion = 'S'
begin
      select @w_est_cancelado = es_codigo
      from cob_cartera..ca_estado
      where es_codigo = 3

      select @w_est_precancelado = es_codigo
      from cob_cartera..ca_estado
      where es_codigo = 5

      select @w_est_anulado = es_codigo
      from cob_cartera..ca_estado
      where es_codigo = 6

      create table #cu_operacion_cerrada (
             oc_producto         char(3)  null,
             oc_operacion        varchar(24)   null,
             oc_moneda           tinyint  null,
             oc_valor_inicial    money    null,
             oc_valor_actual     money    null,
             oc_fecha_venc       datetime null,
             oc_deudor           int      null)
     if exists (select * from cob_credito..cr_gar_propuesta
                 where gp_garantia = @i_garantia)
				 
     begin

--        declare cursor_consulta insensitive cursor for /* HHO Mayo/2012    Migracion SYBASE 15 */
        declare cursor_consulta cursor for /* HHO Mayo/2012    Migracion SYBASE 15 */
        select distinct tr_tramite, tr_producto, tr_numero_op_banco, tr_moneda,
               tr_toperacion,de_cliente
        from cob_credito..cr_gar_propuesta,
             cob_credito..cr_tramite,cob_credito..cr_deudores
        where gp_garantia       = @i_garantia
          and gp_tramite        = tr_tramite
          and tr_tipo          in ('O','R','E','F') 
--          and tr_numero_op     is not null /*ya estaba*/       
          and tr_tramite        = de_tramite
          and de_rol            = 'D' 
        order by tr_tramite

        open cursor_consulta
        fetch cursor_consulta into @w_tramite, @w_producto, @w_num_op_banco,
                                   @w_moneda,@w_toperacion,@w_deudor

        if (@@FETCH_STATUS  = 1)  -- ERROR DEL CURSOR
        begin
           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file, 
           @t_from  = @w_sp_name,
           @i_num   = 1909001 
           return 1 
        end

        if @@FETCH_STATUS  = 2
        begin
           close cursor_consulta
           return 0
        end
        select @w_sum_riesgos = 0

        while @@FETCH_STATUS  = 0
        begin
           select @w_riesgo = 0
           if @w_producto = 'CCA'
           begin 
              select @w_fecha_fin = op_fecha_fin,
                     @w_monto  = isnull(sum(am_acumulado),0),
                     @w_riesgo = isnull(sum(am_acumulado - am_pagado /*- am_exponencial*/),0)
              from cob_cartera..ca_operacion,cob_cartera..ca_amortizacion
              where op_banco           = @w_num_op_banco
                and op_operacion       = am_operacion
                and am_concepto        = 'CAP'
                and op_estado         <> @w_est_cancelado
                and op_estado         <> @w_est_precancelado
                and op_estado         <> @w_est_anulado
              group by op_banco,op_fecha_fin
              order by op_banco

              insert into #cu_operacion_cerrada
              select distinct @w_toperacion,  
                     @w_num_op_banco,
                     @w_moneda,
                     isnull(@w_monto,0),
                     @w_riesgo, 
                     @w_fecha_fin,
                     @w_deudor 
           end -- 'CCA'
           /*if @w_producto = 'CEX'
           begin 
              select @w_monto  = op_importe,
                     @w_riesgo = op_saldo,
                     @w_fecha_fin = op_fecha_expir 
              from cob_credito..cr_gar_propuesta,
                   cob_credito..cr_tramite,
                   cob_comext..ce_operacion
              where tr_tramite         = @w_tramite       
                and tr_numero_op       = op_operacion
                and tr_producto        = @w_producto
                and op_etapa      not in ('40','41','50')

              insert into #cu_operacion_cerrada
              select distinct @w_toperacion,  
                     @w_num_op_banco,
                     @w_moneda,
                     @w_monto,
                     @w_riesgo, 
                     @w_fecha_fin,
                     @w_deudor 
           end -- 'CEX'*/

          select @w_cotizacion = cotizacion
           from #temporal
           where moneda = @w_moneda

           select @w_riesgo = isnull(@w_riesgo,0)*isnull(@w_cotizacion,1)

           select @w_sum_riesgos = @w_sum_riesgos + @w_riesgo

           fetch cursor_consulta into @w_tramite, @w_producto, @w_num_op_banco,
                                      @w_moneda,@w_toperacion,@w_deudor

        end -- While

        close cursor_consulta
        deallocate cursor_consulta

        select @o_opcion = @w_sum_riesgos
     end
		else
			select @o_opcion = 0.0

   /* Selecciona los registros */
   if @i_producto is null -- PRIMEROS 20 REGISTROS
   begin
      set rowcount  20
      select distinct 'TIPO OPERACION'  = oc_producto,
             'OPERACION'       = oc_operacion,
             'MONEDA'          = oc_moneda,
             'VALOR INICIAL'   = oc_valor_inicial,
             'VALOR ACTUA'    = oc_valor_actual,
             'FECHA VENCIM'    = convert(char(10),oc_fecha_venc,101),
             'DEUDOR'          = oc_deudor
      from #cu_operacion_cerrada
      order by oc_producto,oc_operacion
	  
   end 
   else               -- 20 SIGUIENTES                                      
   begin
       set rowcount  20
       select distinct 'TIPO OPERACION'  = oc_producto,
              'OPERACION'       = oc_operacion,
              'MONEDA'          = oc_moneda,
              'VALOR INICIAL'   = oc_valor_inicial,
              'VALOR ACTUAL'    = oc_valor_actual,
              'FECHA VENCIM'    = convert(char(10),oc_fecha_venc,103),
              'DEUDOR'          = oc_deudor
       from #cu_operacion_cerrada
       where (oc_producto > @i_producto
             or (oc_producto = @i_producto and oc_operacion > @i_operac))
       order by oc_producto,oc_operacion
	
   end    
end
--go
	--EXEC sp_procxmode 'dbo.sp_riesgos2', 'unchained'
go
