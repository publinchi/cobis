/************************************************************************/
/*      Archivo:                conaborub.sp                            */
/*      Stored procedure:       sp_consulta_abonos_rubros               */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Miguel Roa                              */
/*      Fecha de escritura:     Abr. 2008                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA".                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Presenta la relacion de pagos y su afectacion por rubros        */
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_consulta_abonos_rubros')
   drop proc sp_consulta_abonos_rubros
go

create proc sp_consulta_abonos_rubros
    @s_user          login     = null,
    @t_trn           smallint  = null,
    @t_debug         char(1)   = 'N',
    @i_formato_fecha int       = 103,
    @i_banco         cuenta    = null,
    @i_operacion     char(1)   = null,
    @i_reg_ini       int       = 0

as

declare @w_sp_name            varchar(32),
        @w_return             int,
        @w_error              int,
        @w_operacionca        int,
        @w_banco              cuenta,
        @w_fecha_causacion    datetime,
        @w_op_direccion       tinyint,
        @w_op_cliente         int,
        @w_op_estado          tinyint,
        @w_op_monto           money,
        @w_ente               int,
        @w_ab_operacion       int,
        @w_ab_fecha_ing       datetime,
        @w_ab_fecha_pag       datetime,
        @w_ab_tipo_reduccion  char(1),
        @w_ab_estado          char(3),
        @w_ab_secuencial_ing  int,
        @w_tr_secuencial_ref  int,
        @w_ab_secuencial_rpa  int,
        @w_ab_secuencial_pag  int,
        @w_ab_tipo_cobro      char(1),
        @w_abd_concepto       catalogo,
        @w_abd_monto_mpg      money,	
        @w_abd_cuenta         cuenta,
        @w_pa_nemonico        catalogo,
        @w_pa_categoria       catalogo,
        @w_est_cancelado      tinyint,
        @w_saldo_capital      money,
        @w_saldo_cap          money,
        @w_tr_operacion       int,
        @w_dtr_afectacion     char(1),
        @w_secuencial_pag     int,
        @w_monto_pagado       money,
        @w_monto_op           money


/* ESTADO DEL DIVIDENDO */
select @w_est_cancelado = es_codigo
from   ca_estado 
where  ltrim(rtrim(es_descripcion)) = 'CANCELADO'


/*SELECCIONA LA OPERACION */
select @w_operacionca       = op_operacion,
       @w_banco             = op_banco,
       @w_op_monto          = op_monto,
       @w_op_direccion      = op_direccion,
       @w_op_cliente        = op_cliente,
       @w_op_estado         = op_estado
from   ca_operacion
where  op_banco             = @i_banco

if @@rowcount = 0
begin
   select @w_error = 710022
   goto ERROR
end  

select @w_monto_op = sum(am_acumulado)
from ca_amortizacion 
where am_operacion  = @w_operacionca


/*CONSULTAR ABONOS */
if @i_operacion = 'Q'
begin
   select ab_operacion,
          ab_secuencial_pag,
          abd_concepto, 
          abd_tipo,
          convert(varchar(10),ab_fecha_pag,103) as ab_fecha_pag, 
          convert(varchar(10),ab_fecha_ing,103) as ab_fecha_ing, 
          abd_monto_mn,
          cap    = sum(case ar_concepto when 'CAP'        then ar_monto_mn else 0 end),
          int    = sum(case ar_concepto when 'INT'        then ar_monto_mn else 0 end),
          imo    = sum(case ar_concepto when 'IMO'        then ar_monto_mn else 0 end),
          seg    = sum(case when ar_concepto in ('SEGDEUVEN','SEGDEUEM')  then ar_monto_mn else 0 end),
          honabo = sum(case ar_concepto when 'HONABO'     then ar_monto_mn else 0 end),
          iva    = sum(case when ar_concepto in ('IVAHONOABO','IVACOMIFNG','IVAMIPYMES' ) then ar_monto_mn else 0 end),
          condonacion = 0,
          otros  = sum(case when ar_concepto not in('CAP','INT','IMO','SEGDEUVEN','SEGDEUEM','HONABO') then ar_monto_mn else 0 end),
          saldo_cap = 0,
          ab_nro_recibo,
          tipo_reduccion = case when ab_tipo_reduccion   = 'N'   THEN 'NORMAL'   
                                  when ab_tipo_reduccion = 'C'   THEN 'REDUCCION CUOTA'  
                                  when ab_tipo_reduccion = 'T'   THEN 'REDUCCION TIEMPO' else 'NINGUNA' end,
          estado         = case when ab_estado           = 'A'   THEN 'APLICADO' 
                                  when ab_estado         = 'NA'  THEN 'NO APLICADO' 
                                  when ab_estado         = 'ING' THEN 'INGRESADO'        
                                  when ab_estado         = 'RV'  THEN 'REVERSADO' else 'NINGUNA' end   into  #pagos
   from ca_abono, ca_abono_det, ca_abono_rubro
   where ab_operacion      = abd_operacion
   and   ab_secuencial_ing = abd_secuencial_ing
   and   ab_operacion      = ar_operacion
   and   ab_secuencial_pag = ar_secuencial
   and   ab_estado         = 'A'
   and   ar_dividendo      <> -1
   and   ab_operacion      = @w_operacionca  --3136 --222 --219
   group by 
          ab_operacion,        ab_secuencial_pag,  abd_concepto,       abd_tipo,
          ab_fecha_pag,        ab_fecha_ing,       abd_monto_mn,       ar_concepto,        ar_monto_mn,         
          ab_nro_recibo,       ab_tipo_reduccion,  ab_estado
   order by ab_fecha_pag
   
   select ab_operacion,
          ab_secuencial_pag,
          abd_tipo,
          abd_concepto, 
          convert(varchar(10),ab_fecha_pag, 103) as ab_fecha_pag,
          convert(varchar(10),ab_fecha_ing, 103) as ab_fecha_ing,
          abd_monto_mn,
          'cap'         = sum(cap),
          'int'         = sum(int),
          'imo'         = sum(imo),
          'seg'         = sum(seg),
          'honabo'      = sum(honabo),
          'iva'         = sum(iva),
          'condonacion' = sum(condonacion),
          'otros'       = sum(otros),
           saldo_cap,
           ab_nro_recibo, 
           tipo_reduccion, 
           estado,
           sec_reg = 0   into #pagos_consolidados
    from #pagos
   where abd_tipo = 'PAG'
   group by ab_operacion, ab_secuencial_pag, abd_concepto,  abd_tipo, 
            ab_fecha_pag, ab_fecha_ing,abd_monto_mn,      ab_nro_recibo, tipo_reduccion, saldo_cap,
            estado
            
   /*VALORES CONDONADOS*/         
   select ab_operacion      as operacion,
          ab_secuencial_pag as secuencial, 
          ab_fecha_pag      as fecha_pag, 
          abd_monto_mn      as monto 
          into #condonacion
    from #pagos_consolidados
   where abd_tipo = 'CON'
   group by ab_operacion, ab_secuencial_pag, ab_fecha_pag, abd_monto_mn
   
   
   update #pagos_consolidados
   set condonacion = abd_monto_mn
   from #condonacion
   where ab_operacion      = operacion
   and   ab_secuencial_pag = secuencial
  
   
   /*GENERACION SALDO DE CAPITAL DESPUES DE CADA PAGO*/
   select @w_secuencial_pag = 0
   while 1 = 1
   begin
      set rowcount 1
      select @w_secuencial_pag = isnull(ab_secuencial_pag, 0)
      from #pagos_consolidados
      where ab_operacion = @w_operacionca
      and   ab_secuencial_pag > @w_secuencial_pag
      if @@rowcount = 0 or @w_secuencial_pag = 0
         break
     
      select @w_monto_pagado  =  sum(abd_monto_mn)
        from #pagos_consolidados
       where ab_operacion = @w_operacionca
         and ab_secuencial_pag <= @w_secuencial_pag 
        
      update #pagos_consolidados
      set saldo_cap = @w_monto_op -  @w_monto_pagado
      where ab_operacion = @w_operacionca
      and   ab_secuencial_pag  = @w_secuencial_pag 
   end
   set rowcount 0   
end
 
   declare @w_contador int
   set @w_contador = 0
   update #pagos_consolidados
   set @w_contador = sec_reg = @w_contador +1

   select abd_concepto, 
          ab_fecha_pag,
          ab_fecha_ing,
          abd_monto_mn,
          cap,
          int,
          imo,
          seg,
          honabo,
          iva,
          condonacion,
          otros,
          saldo_cap,
          ab_nro_recibo, 
          tipo_reduccion, 
          estado,
          sec_reg 
    from #pagos_consolidados
    where sec_reg >= @i_reg_ini
           
            
              

return 0

ERROR:
exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_error
   
return @w_error
                        
go
