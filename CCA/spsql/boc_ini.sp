/*boc_ini.sp*************************************************************/
/*   Stored procedure:     sp_boc_ini                                   */
/*   Base de datos:        cob_cartera                                  */
/************************************************************************/
/*                                  IMPORTANTE                          */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                            PROPOSITO                                 */
/*   BOC de doble via.                                                  */
/************************************************************************/
 
use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_boc_ini')
   drop proc sp_boc_ini
go
 
create proc sp_boc_ini
    @i_empresa     tinyint,
    @i_fecha       datetime,
    @o_msg         varchar(50)    out

as
 
declare 
    @w_fecha_fm      datetime,
    @w_fecha_ay      datetime,
    @w_corte         int,
    @w_periodo       int,
    @w_corte_ayer    int,
    @w_periodo_ayer  int,   
    @w_corte_hoy     int,
    @w_periodo_hoy   smallint,
    @w_cuenta        cuenta,
    @w_fecha         datetime,
    @w_producto      int,
    @w_oficina       smallint,
    @w_tercero       char(1)
  
select 
@w_fecha_fm = dateadd(dd, -1*datepart(dd,@i_fecha), @i_fecha),
@w_fecha_ay = dateadd(dd, -1, @i_fecha),
@w_producto = 7


/* DETERMINAR CORTE Y PERIODO DEL FIN DE MES */
select 
@w_corte    = co_corte,
@w_periodo  = co_periodo
from cob_conta..cb_corte
where co_fecha_ini = @w_fecha_fm
and   co_empresa   = @i_empresa

/* DETERMINAR CORTE Y PERIODO DEL DIA ANTERIOR */
select 
@w_corte_ayer   = co_corte,
@w_periodo_ayer = co_periodo
from cob_conta..cb_corte
where co_fecha_ini = @w_fecha_ay
and   co_empresa   = @i_empresa

/* DETERMINAR CORTE Y PERIODO DE LA FECHA DEL BOC */
select 
@w_corte_hoy    = co_corte,
@w_periodo_hoy  = co_periodo
from cob_conta..cb_corte
where co_fecha_ini = @i_fecha
and   co_empresa   = @i_empresa


/* DETERMINAR EL INVENTARIO DE CUENTAS A CONTROLAR */
select distinct cuenta = re_substring 
into #cuentas
from cob_conta..cb_det_perfil, cob_conta..cb_relparam
where dp_perfil = 'BOC_ACT'
and   dp_cuenta = re_parametro

/*DETERMINAR EL INVENTARIO DE OFICINAS A CONTROLAR */
select distinct oficina = op_oficina
into #oficinas
from ca_operacion


select 
cliente = sa_ente, 
saldo   = sa_debito - sa_credito
into #saldos
from cob_conta_tercero..ct_sasiento
where 1=2


select @w_cuenta = ''

while 1=1 begin  -- LAZO DE CUENTAS

   set rowcount 1

   select @w_cuenta = cuenta
   from   #cuentas
   where  cuenta > @w_cuenta
   order by cuenta

   if @@rowcount = 0 begin
      set rowcount 0
      break
   end

   set rowcount 0
   
   /* DETERMINO SI ES CUENTA DE TERCERO */
   if exists (select * from cob_conta..cb_cuenta_proceso where cp_proceso in (6003, 6095) and cp_cuenta = @w_cuenta)
      select @w_tercero = 'S'
   else
      select @w_tercero = 'N'

  
   select @w_oficina = 0
   
   while 2=2 begin -- LAZO DE OFICINAS
   
      set rowcount 1
      
      select @w_oficina = oficina
      from #oficinas
      where oficina > @w_oficina
      order by oficina
      
      if @@rowcount = 0 begin
         set rowcount 0
         break
      end
      
      set rowcount 0

      if @w_tercero = 'S' begin
      
         insert into #saldos
         select 
         cliente = st_ente, 
         saldo   = sum(isnull(st_saldo, 0))
         from cob_conta_tercero..ct_saldo_tercero
         where st_cuenta  = @w_cuenta
         and   st_corte   = @w_corte
         and   st_periodo = @w_periodo
         and   st_oficina = @w_oficina
         group by st_ente
         having sum(isnull(st_saldo, 0)) <> 0
         
         if @@error <> 0 begin
            select @o_msg = 'ERROR AL INSERTAR SALDOS EN TABLA TEMPORAL'
            return 710001
         end
         
         insert into #saldos
         select 
         cliente = sa_ente, 
         saldo   = sum(isnull(sa_debito,0) - isnull(sa_credito,0))
         from cob_conta_tercero..ct_sasiento,  cob_conta_tercero..ct_scomprobante
         where sa_cuenta       = @w_cuenta
         and   sa_oficina_dest = @w_oficina
         and   sa_fecha_tran  between dateadd(dd,1,@w_fecha_fm) and @i_fecha
         and   sc_comprobante  = sa_comprobante
         and   sc_fecha_tran   = sa_fecha_tran
         and   sc_producto     = sa_producto
         and   sc_empresa      = sa_empresa
         and   sc_estado      <> 'A'
         group by sa_ente
         having sum(isnull(sa_debito,0) - isnull(sa_credito,0)) <> 0
         
         if @@error <> 0 begin
            select @o_msg = 'ERROR AL INSERTAR MOVIMIENTOS EN TABLA TEMPORAL'
            return 710001
         end

      end else begin  --la cuenta no es de tercero

         insert into #saldos
         select 
         cliente = 0,
         saldo   = isnull(sum(hi_saldo), 0) 
         from cob_conta_his..cb_hist_saldo
         where hi_corte   = @w_corte_ayer
         and   hi_periodo = @w_periodo_ayer
         and   hi_oficina = @w_oficina 
         and   hi_cuenta  = @w_cuenta
         having isnull(sum(hi_saldo), 0) <> 0

         if @@error <> 0 begin
            select @o_msg = 'ERROR LA REGISTRAR LOS RESULTADOS EN LA TABLA DEL BOC'
            return 710001
         end
         
         insert into #saldos
         select 
            cliente  = 0,
            saldo    = sum(isnull(sa_debito,0) - isnull(sa_credito,0))
         from cob_conta_tercero..ct_sasiento, cob_conta_tercero..ct_scomprobante
         where sa_fecha_tran   = @i_fecha
         and   sa_cuenta       = @w_cuenta  
         and   sa_oficina_dest = @w_oficina
         and   sc_fecha_tran   = sa_fecha_tran
         and   sc_producto     = sa_producto
         and   sc_comprobante  = sa_comprobante      
         and   sc_empresa      = sa_empresa
         and   sc_estado       <> 'A'
         having sum(isnull(sa_debito,0) - isnull(sa_credito,0)) <> 0
         
         if @@error <> 0 begin
            select @o_msg = 'ERROR AL INSERTAR MOVIMIENTOS DE NO TERCEROS EN TABLA TEMPORAL'
            return 710001
         end
            
      end
      
      insert into cob_conta..cb_boc (
      bo_fecha,                             bo_cuenta,                 bo_oficina, 
      bo_cliente,                           bo_val_opera,              bo_val_conta, 
      bo_diferencia,                        bo_producto)
      select
      @i_fecha,                             @w_cuenta,                 @w_oficina,
      cliente,                              0,                         sum(saldo),
      sum(saldo)*-1,                        @w_producto
      from #saldos
      group by cliente
      
      if @@error <> 0 begin
         select @o_msg = 'ERROR LA REGISTRAR LOS RESULTADOS EN LA TABLA DEL BOC'
         return 710001
      end
     
      truncate table #saldos
      
   end --lazo de oficinas
   
end -- lazo de cuentas

return 0

go
