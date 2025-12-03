/**************************************************************************/
/*   Archivo:             flujocj.sp                                      */
/*   Stored procedure:    sp_flujocaja                                    */
/*   Base de datos:       cob_cartera                                     */
/*   Producto:            Credito y Cartera                               */
/*   Disenado por:        Silvia Portilla S.                              */
/*   Fecha de escritura:  Febrero 2010                                    */
/**************************************************************************/
/*                              IMPORTANTE                                */
/*   Este  programa  es parte  de los  paquetes  bancarios  propiedad de  */
/*   'MACOSA'.  El uso no autorizado de este programa queda expresamente  */
/*   prohibido as­ como cualquier alteraci½n o agregado hecho por alguno  */
/*   alguno  de sus usuarios sin el debido consentimiento por escrito de  */
/*   la Presidencia Ejecutiva de MACOSA o su representante.               */
/**************************************************************************/
/*                              PROPOSITO                                 */
/*   Permite obtener los datos del flujo de caja del banco                */
/**************************************************************************/
/*                             MODIFICACIONES                             */
/*      FECHA                 AUTOR                PROPOSITO              */
/*   8-Febrero-2010       Silvia Portilla S.      Emision Inicial         */
/**************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_flujocaja')
   drop proc sp_flujocaja
go

create proc sp_flujocaja
(
   @i_param1   varchar(255) = null
   
)
as
declare
   @w_sp_name         varchar(255),
   @w_oficina         smallint,
   @w_max_of          smallint,
   @w_saldo           money,
   @w_mdes            money,
   @w_mdesch          money,
   @w_mdesef          money,
   @w_mpdes           money,
   @w_mnew            money,
   @w_mren            money,
   @w_cont            int,
   @w_cliente         int,
   @w_recar           money,   
   @w_proyr           money,
   @w_monto           money,
   @w_fecha           datetime,
   @w_bandera         int,
   @w_return          int,
   @i_fecha           datetime,
   @w_error           int

select @i_fecha = convert(datetime, @i_param1)

select @w_oficina        = 0,
       @w_bandera        = 0,
       @w_fecha          = @i_fecha

set rowcount 0

while  (@w_bandera = 0)
begin
   select @w_fecha = dateadd (dd,1,@w_fecha)
if exists (select 1 from cobis..cl_dias_feriados
			where df_fecha = @w_fecha
			and  df_ciudad in
			(select pa_int from cobis..cl_parametro
			where pa_producto = 'CON'
			and   pa_nemonico = 'CIUDAD')
			)
select @w_bandera = 0
else
select @w_bandera = 1
end

truncate table ca_cdes_tmp
--TABLAS TEMPORALES
--Datos para desembolsos
create table #ca_cdes_tmp
(
   ctm_valor       money,
   ctm_concepto    char(10),
   ctm_oficina     smallint,
   ctm_cliente     int
)

--create index #ca_cdes_tmp_akey on #ca_cdes_tmp(ctm_oficina)
create index ca_cdes_tmp_akey on #ca_cdes_tmp(ctm_oficina)


--Datos para pagos
create table #ca_pdes_tmp
(
   ptm_valor      money,
   ptm_oficina    smallint
)

--create index #ca_pdes_tmp_akey on #ca_pdes_tmp(ptm_oficina)
create index ca_pdes_tmp_akey on #ca_pdes_tmp(ptm_oficina)


--Datos para proyeccion de pagos
create table #ca_prdes_tmp
(
   ptm_valor      money,
   ptm_oficina    smallint
)

--create index #ca_prdes_tmp_akey on #ca_prdes_tmp(ptm_oficina)
create index ca_prdes_tmp_akey on #ca_prdes_tmp(ptm_oficina)


insert into #ca_cdes_tmp(
ctm_valor,    ctm_concepto,   ctm_oficina,
ctm_cliente )
select 
dtr_monto_mn, dtr_concepto,   op_oficina, 
op_cliente
from cob_cartera..ca_transaccion, cob_cartera..ca_det_trn, cob_cartera..ca_operacion
where tr_operacion = dtr_operacion
and tr_operacion   = op_operacion 
and dtr_operacion  = op_operacion 
and tr_secuencial  = dtr_secuencial
and tr_tran        = 'DES'
and tr_fecha_ref   = @i_fecha
and tr_estado in ('ING','CON')
and dtr_concepto in (select cp_producto 
                     from cob_cartera..ca_producto 
                     where cp_desembolso = 'S' and cp_categoria <> 'OTRO')

insert into #ca_pdes_tmp
(ptm_valor, ptm_oficina)
select 
abd_monto_mn, op_oficina  
from cob_cartera..ca_abono, cob_cartera..ca_abono_det, cob_cartera..ca_operacion
where ab_operacion    = abd_operacion 
and ab_secuencial_ing = abd_secuencial_ing
and  ab_fecha_pag     = @i_fecha
and op_operacion      = ab_operacion
and op_operacion      = abd_operacion

insert into #ca_prdes_tmp
(ptm_valor, ptm_oficina) 
select 
(am_cuota + am_gracia - am_pagado), op_oficina 
from cob_cartera..ca_dividendo, cob_cartera..ca_amortizacion, cob_cartera..ca_operacion
where di_operacion = am_operacion 
and di_dividendo   = am_dividendo 
and di_operacion = op_operacion
and am_operacion = op_operacion
and di_estado not in (0,3,99)
and di_fecha_ven = @w_fecha

select @w_max_of  = max( ctm_oficina)
from #ca_cdes_tmp

while @w_oficina < @w_max_of
begin
   set rowcount 1
   select @w_oficina = ctm_oficina
   from #ca_cdes_tmp
   where ctm_oficina > @w_oficina  
   order by ctm_oficina
   
   select @w_saldo  = 0,
          @w_mdes   = 0,
          @w_mdesch = 0,
          @w_mdesef = 0,
          @w_mpdes  = 0,
          @w_mnew   = 0,
          @w_mren   = 0,
          @w_recar  = 0,     
          @w_proyr  = 0
         
   set rowcount 0
   
   --SALDO DE CAJA AL CIERRE POR OFICINA
   
   /*select @w_saldo = sum(sc_saldo)
   from cob_remesas..re_saldos_caja
   where  sc_moneda = 0
   and sc_oficina   = @w_oficina*/
   
   exec cob_interface..sp_flujocaja_interfase
       @i_oficina = @w_oficina,
       @o_saldo   = @w_saldo out
          
   --MONTO TOTAL DE DESEMBOLSOS EN CHEQUES        
   select @w_mdesch = sum(ctm_valor)                
   from #ca_cdes_tmp
   where ctm_oficina = @w_oficina
   and ctm_concepto in (select cp_producto 
                        from cob_cartera..ca_producto 
                        where cp_categoria in ('CHLO', 'CHGE'))
                        
   --MONTO TOTAL DE DESEMBOLSOS EN EFECTIVO                      
   select @w_mdesef = sum(ctm_valor)                
   from #ca_cdes_tmp
   where ctm_oficina = @w_oficina
   and ctm_concepto in (select cp_producto 
                        from cob_cartera..ca_producto 
                        where cp_categoria in ('EFEC'))
                        
   --MONTO TOTAL PENDIENTE DE DESEMBOLSO                     
   
   select @w_mpdes = sum(op_monto)
   from cob_cartera..ca_operacion
   where op_oficina = @w_oficina
   and op_estado    = 0
   
   --MONTOS DESEMBOLSADOS NUEVOS Y RENOVADOS
   declare cur_ope cursor for select 
   distinct ctm_cliente 
   from #ca_cdes_tmp
   where ctm_oficina = @w_oficina
   for read only
   
   open cur_ope
   fetch cur_ope into @w_cliente
   
   while @@fetch_status = 0 
   begin
      select @w_cont  = 0,
             @w_monto = 0
      
      select @w_cont  = count(1)
      from cob_cartera..ca_operacion
      where op_cliente = @w_cliente
      and op_estado not in (0,99)

      select @w_monto = sum(ctm_valor)
      from #ca_cdes_tmp
      where ctm_cliente = @w_cliente

      select @w_monto = isnull(@w_monto,0) 
   
      if @w_cont = 1
         select @w_mnew = @w_mnew + @w_monto
      else
         select @w_mren = @w_mren + @w_monto  
     
      fetch cur_ope into @w_cliente
   end
   close cur_ope
   deallocate cur_ope 

   select @w_recar = sum(ptm_valor)
   from #ca_pdes_tmp
   where ptm_oficina = @w_oficina


   select @w_proyr = sum(ptm_valor)
   from #ca_prdes_tmp
   where ptm_oficina = @w_oficina

   select @w_saldo  = isnull(@w_saldo ,0),
          @w_mdes   = isnull(@w_mdes  ,0),
          @w_mdesch = isnull(@w_mdesch,0),
          @w_mdesef = isnull(@w_mdesef,0),
          @w_mpdes  = isnull(@w_mpdes ,0),
          @w_mnew   = isnull(@w_mnew  ,0),
          @w_mren   = isnull(@w_mren  ,0),
          @w_recar  = isnull(@w_recar ,0),
          @w_proyr  = isnull(@w_proyr ,0)

  
   --MONTO TOTAL DE DESEMBOLSOS
   select @w_mdes = @w_mdesch + @w_mdesef  --+ @w_mnew + @w_mren

   insert into ca_cdes_tmp(
   ctm_saldo_caj,  ctm_des_dia,  ctm_des_ch,
   ctm_des_ef,     ctm_des_new,  ctm_des_ren,
   ctm_des_pen,    ctm_rec_car,  ctm_proy_rec,
   ctm_oficina)
   values(
   @w_saldo,       @w_mdes,      @w_mdesch,
   @w_mdesef,      @w_mnew,      @w_mren,
   @w_mpdes,       @w_recar,     @w_proyr,
   @w_oficina   
   )
   set rowcount 0
end

return 0
go
                                                