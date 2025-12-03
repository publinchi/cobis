/************************************************************************/
/*  Archivo:                boc_ini_cr_gar.sp                           */
/*  Stored procedure:       sp_boc_ini_cr_gar                           */
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
/* **********************************************************************/
use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_boc_ini_cr_gar' and type = 'P')
   drop proc sp_boc_ini_cr_gar
go

 
create proc sp_boc_ini_cr_gar
   @i_empresa     tinyint,
   @i_fecha       datetime,
   @i_producto    int,
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
   @w_periodo_hoy   int,
   @w_cuenta        cuenta,
   @w_fecha         datetime,
   @w_tercero       char(1),
   @w_producto_cre  int,
   @w_producto_gar  int,
   @w_perfil        varchar(20)
  
select 
   @w_fecha_fm = dateadd(dd, -1*datepart(dd,@i_fecha), @i_fecha),
   @w_fecha_ay = dateadd(dd, -1, @i_fecha),
   @w_producto_cre = 21,
   @w_producto_gar = 19

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

if @i_producto = @w_producto_cre
   select @w_perfil = 'BOC_CRE'
else
   select @w_perfil = 'BOC_GAR'

/* DETERMINAR EL INVENTARIO DE CUENTAS A CONTROLAR */
select distinct cuenta = re_substring 
into #cuentas
from cob_conta..cb_det_perfil, cob_conta..cb_relparam
where dp_perfil = @w_perfil
and   dp_cuenta = re_parametro

select
   cliente  = sa_ente, 
   oficina  = sa_oficina_dest,
   saldo    = sa_debito - sa_credito
into #saldos
from cob_conta_tercero..ct_sasiento
where 1=2


select @w_cuenta = ''

while 1=1
begin  -- LAZO DE CUENTAS

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

   if @w_tercero = 'S' begin
   
      insert into #saldos
      select 
         cliente  = st_ente,          
         oficina  = st_oficina,
         saldo    = isnull(sum(st_saldo), 0)
      from cob_conta_tercero..ct_saldo_tercero
      where st_cuenta  = @w_cuenta
      and   st_corte   = @w_corte
      and   st_periodo = @w_periodo
      group by st_ente, st_oficina
      having isnull(sum(st_saldo), 0) <> 0
      
      if @@error <> 0
      begin
         select @o_msg = 'ERROR AL INSERTAR SALDOS EN TABLA TEMPORAL'
         return 710001
      end
      
      insert into #saldos
      select 
         cliente  = sa_ente,
         oficina  = sa_oficina_dest,
         saldo    = sum(isnull(sa_debito,0) - isnull(sa_credito,0))
      from cob_conta_tercero..ct_sasiento,  cob_conta_tercero..ct_scomprobante
      where sa_fecha_tran   between dateadd(dd, 1, @w_fecha_fm) and @i_fecha
      and   sa_cuenta       = @w_cuenta      
      and   sc_fecha_tran   = sa_fecha_tran
      and   sc_producto     = sa_producto
      and   sc_comprobante  = sa_comprobante      
      and   sc_empresa      = sa_empresa
      and   sc_estado       <> 'A'
      group by sa_ente, sa_oficina_dest
      having sum(isnull(sa_debito, 0) - isnull(sa_credito, 0)) <> 0
      
      if @@error <> 0 begin
         select @o_msg = 'ERROR AL INSERTAR MOVIMIENTOS EN TABLA TEMPORAL'
         return 710001
      end
   
   end
   else
   begin  -- LA CUENTA NO ES DE TERCERO
   
      insert into #saldos
      select 
         cliente  = 0,
         oficina  = hi_oficina,
         saldo    = isnull(sum(hi_saldo), 0)
      from cob_conta_his..cb_hist_saldo
      where hi_corte   = @w_corte_ayer
      and   hi_periodo = @w_periodo_ayer
      and   hi_cuenta  = @w_cuenta
      group by hi_oficina
      having isnull(sum(hi_saldo), 0) <> 0
   
      if @@error <> 0
      begin
         select @o_msg = 'ERROR LA REGISTRAR LOS RESULTADOS EN LA TABLA DEL BOC'
         return 710001
      end
         
      insert into #saldos
      select 
         cliente  = 0,
         oficina  = sa_oficina_dest,
         saldo    = sum(isnull(sa_debito,0) - isnull(sa_credito,0))
      from cob_conta_tercero..ct_sasiento,  cob_conta_tercero..ct_scomprobante
      where sa_fecha_tran   = @i_fecha
      and   sa_cuenta       = @w_cuenta      
      and   sc_fecha_tran   = sa_fecha_tran
      and   sc_producto     = sa_producto
      and   sc_comprobante  = sa_comprobante      
      and   sc_empresa      = sa_empresa
      and   sc_estado       <> 'A'
      group by sa_oficina_dest
      having sum(isnull(sa_debito, 0) - isnull(sa_credito, 0)) <> 0
      
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
      @i_fecha,                             @w_cuenta,                 oficina,
      cliente,                              0,                         sum(saldo),
      sum(saldo)*-1,                        @i_producto
   from #saldos
   group by cliente, oficina
   
   if @@error <> 0
   begin
      select @o_msg = 'ERROR LA REGISTRAR LOS RESULTADOS EN LA TABLA DEL BOC'
      return 710001
   end
   
   truncate table #saldos
         
end -- LAZO DE CUENTAS

return 0


GO
