/****************************************************************/
/* ARCHIVO:              riesgos1.sp                            */
/* Stored procedure:	 sp_riesgos1	          	            */
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

IF OBJECT_ID('dbo.sp_riesgos1') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.sp_riesgos1
END
go

create proc sp_riesgos1 (
   @s_ssn                int      = null,
   @s_date               datetime = null,
   @s_user               login    = null,
   @s_term               descripcion = null,
   @s_corr               char(1)  = null,
   @s_ssn_corr           int      = null,
   @s_ofi                smallint  = null,
   @t_rty                char(1)  = null,
   @t_trn                smallint = null,
   @t_debug              char(1)  = 'N',
   @t_file               varchar(14) = null,
   @t_from               varchar(30) = null,
   @i_operacion          char(1)  = null,
   @i_modo               smallint = null,
   @i_codigo_externo     varchar(64) = null,
   @i_cliente            int         = null,
   @i_producto           varchar(15) = null,
   @i_tramite		 int         = null,
   @i_filial 		 tinyint     = null,
   @i_sucursal		 smallint    = null,
   @i_tipo_cust		 varchar(64) = null,
   @i_custodia 		 int         = null,
   @i_codigo_compuesto   varchar(64) = null,
   @i_garantia           varchar(64) = null,
   @i_operac             cuenta      = null,
   @o_riesgos            char(1)     = null out
)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_retorno            int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_error		 int,
   @w_codigo_externo     varchar(64),
   @w_otras_op           money,
   @w_ayer               datetime,
   @w_cliente            int,
   @w_abierta_cerrada    char(1),
   @w_riesgo             money,
   @w_producto		 varchar(4),
   @w_operacion		 varchar(24),
   @w_tipo	 	 descripcion,
   @w_estado		 varchar(30),
   @w_est_vencido	 tinyint,
   @w_est_cancelado	 tinyint,
   @w_est_precancelado	 tinyint,
   @w_est_anulado	 tinyint,
   @w_def_estado	 varchar(30),
   @w_cartera_pv         money,
   @w_cartera_v	         money,
   @w_cartera_pve	 money,
   @w_cartera_ve	 money,
   @w_def_moneda	 tinyint,
   @w_moneda		 int,
   @w_num_op		 int,
   @w_num_op_banco       varchar(20),
   @w_desc_moneda	 varchar(30),
   @w_cot_moneda	 money,
   @w_fecha_pago	 datetime,
   @w_fecha_neg		 datetime,
   @w_plazo		 char(1),
   @w_valor		 money,
   @w_sum_riesgos        money,
   @w_total              money,
   @w_sw		 tinyint,
   @w_fecha_actual	 datetime,
   @w_fecha_ant		 datetime,
   @w_dia		 tinyint,
   @w_cot		 money,  
   @w_ciudad		 smallint,
   @w_df_fecha		 datetime,
   @w_tipo_op		 char(1),
   @w_contador           tinyint,
   @w_situacion          char(1),
   @w_tramite            int

select @w_today   = convert(varchar(10),getdate(),101)
select @w_sp_name = 'sp_riesgos1'
select @w_ayer    = dateadd(dd,-1,getdate())

/***********************************************************/
/* Codigos de Transacciones                                */
if (@t_trn <> 19604 and @i_operacion = 'Q') 
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
			  /*ya estaba*/
  --from cob_conta..cb_cotizacion
  --group by ct_moneda
  --having ct_fecha = max(ct_fecha)
  print 'pendiente'
end


if @i_operacion = 'Q'
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

      if exists (select 1 from cob_credito..cr_gar_propuesta
                 where gp_garantia = @i_codigo_externo)
      begin
--           declare cursor_consulta insensitive cursor for /* HHO Mayo/2012    Migracion SYBASE 15 */
           declare cursor_consulta cursor for /* HHO Mayo/2012    Migracion SYBASE 15 */
           select distinct tr_tramite, tr_producto, tr_numero_op_banco,
                  tr_moneda
           from cob_credito..cr_gar_propuesta,cob_credito..cr_tramite
           where gp_garantia = @i_codigo_externo
             and gp_tramite  = tr_tramite
             and tr_tipo in ('O','R') 
             and tr_numero_op is not null        
           order by tr_tramite

           open cursor_consulta
           fetch cursor_consulta into @w_tramite, @w_producto, 
                                      @w_num_op_banco,@w_moneda

           if (@@FETCH_STATUS = 1)  -- ERROR DEL CURSOR
           begin
               exec cobis..sp_cerror
                 @t_debug = @t_debug,
                 @t_file  = @t_file, 
                 @t_from  = @w_sp_name,
                 @i_num   = 1909001 
               return 1 
           end

           if @@FETCH_STATUS = 2
           begin
               close cursor_consulta
               return 0
           end
           
           select @w_sum_riesgos = 0

           while @@FETCH_STATUS = 0
           begin
               select @w_riesgo = 0
               
               if @w_producto = 'CCA'
               begin 
                   select @w_riesgo = sum(am_acumulado - am_pagado /*- am_exponencial*/)
                   from cob_cartera..ca_operacion,cob_cartera..ca_amortizacion
                   where op_banco      = @w_num_op_banco 
                     and op_operacion  = am_operacion
                     and am_concepto   = 'CAP'
                     and op_estado     <> @w_est_cancelado
                     and op_estado     <> @w_est_precancelado
                     and op_estado     <> @w_est_anulado
                   group by op_banco
                   order by op_banco

               select @w_riesgo=isnull(isnull(@w_riesgo,0)*isnull(cotizacion,1),0)
               from #temporal 
               where moneda = @w_moneda

               select @w_sum_riesgos = @w_sum_riesgos + isnull(@w_riesgo,0)
           end 
		   /*ya estaba*/
           
       /*    if @w_producto = 'CEX'
           begin 
              select @w_riesgo = op_saldo
              from cob_credito..cr_tramite,
                   cob_comext..ce_operacion
              where tr_numero_op_banco = @w_num_op_banco
                and tr_numero_op       = op_operacion
                and tr_producto        = @w_producto
                and op_etapa      not in ('40','41','50')

              select @w_riesgo=isnull(isnull(@w_riesgo,0)*isnull(cotizacion,1),0)
              from #temporal 
              where moneda = @w_moneda

              select @w_sum_riesgos = @w_sum_riesgos + isnull(@w_riesgo,0)
           end
*/
           fetch cursor_consulta into @w_tramite, @w_producto, @w_num_op_banco,
                                      @w_moneda
           end -- While
           if @w_sum_riesgos > 0
              select @o_riesgos = 'S'
           else
              select @o_riesgos = 'N'
           close cursor_consulta
           deallocate cursor_consulta
           end -- Fin del If exists
           else  -- No existen tramites asociados a la garantia
              select @o_riesgos = 'N'
select @o_riesgos

end
--go
--EXEC sp_procxmode 'dbo.sp_riesgos1', 'unchained'
go
