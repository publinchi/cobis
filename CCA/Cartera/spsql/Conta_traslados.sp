/************************************************************************/
/* Archivo            :    conta_traslados.sp                           */
/* Stored procedure   :    sp_conta_traslados                           */
/* Base de datos      :    cob_cartera                                  */
/* Producto           :    Cartera                                      */
/* Disenado por       :    RRB                                          */
/* Fecha de escritura :    2010-03-17                                   */
/************************************************************************/
/*                              IMPORTANTE                              */
/* Este programa es parte de los paquetes bancarios propiedad de        */
/* 'MACOSA', representantes exclusivos para el Ecuador de               */
/* AT&T GIS.                                                            */
/* Su uso no autorizado queda expresamente prohibido asi como           */
/* cualquier alteracion o agregado hecho por alguno de sus              */
/* usuarios sin el debido consentimiento por escrito de la              */
/* Presidencia Ejecutiva de MACOSA o su representante.                  */
/************************************************************************/
/*                               PROPOSITO                              */
/* Contabilidad de traslados de saldos entre clientes                   */
/************************************************************************/
/*                            MODIFICACIONES                            */
/* FECHA       AUTOR                   RAZON                            */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_conta_traslados')
  drop procedure sp_conta_traslados
go

create proc sp_conta_traslados(
  @s_user           login       = null,
  @i_cliente_viejo  int         = null,
  @i_cliente_nuevo  int         = null,
  @i_empresa        smallint    = 1
)
as declare 
@w_cod_producto  int,
@w_asiento       int ,      
@w_debito        money,
@w_credito       money,
@w_fecha_proceso datetime,
@w_corte         smallint,
@w_periodo       smallint,
@w_fecha_fm      datetime,
@w_comprobante   int,
@w_fecha         datetime,
@w_error         int,
@w_mensaje       varchar(100),
@w_oficina       smallint,
@w_area          smallint,
@w_ar_origen     smallint,
@w_re_ofconta    smallint,
@w_sp_name       varchar(20),
@w_msg           varchar(255)

select 
@w_cod_producto  = 7,
@w_debito        = 0,
@w_credito       = 0,
@w_sp_name       = 'sp_conta_traslados',
@w_error         = 0

select @w_fecha_proceso = fp_fecha
from cobis..ba_fecha_proceso

select @w_fecha_fm = dateadd(dd, -1*datepart(dd,@w_fecha_proceso), @w_fecha_proceso)

select 
@w_corte    = co_corte,
@w_periodo  = co_periodo
from cob_conta..cb_corte
where co_fecha_ini = @w_fecha_fm
and   co_empresa   = @i_empresa

--print 'Conta_traslados.sp ' + cast(@w_corte as varchar) + ' - ' + cast(@w_periodo as varchar)

select 
cuenta  = st_cuenta,
oficina = st_oficina,
area    = st_area,
cliente = st_ente, 
saldo   = sum(isnull(st_saldo, 0))
into #saldo_fm
from cob_conta_tercero..ct_saldo_tercero
where st_corte   = @w_corte
and   st_periodo = @w_periodo
and   st_ente    = @i_cliente_viejo
and   st_saldo   <> 0
group by st_cuenta, st_oficina, st_area, st_ente

if @@error != 0 begin
   select @w_msg = 'ERROR AL INSERTAR SALDOS EN TABLA TEMPORAL #saldo_fm - Nohay datos para corte periodo ',
   @w_error   = 710001
   goto ERROR1
end

insert into #saldo_fm
select 
cuenta  = sa_cuenta,
oficina = sa_oficina_dest,
area    = sa_area_dest,
cliente = sa_ente, 
saldo   = isnull(sa_debito,0) - isnull(sa_credito,0)
from cob_conta_tercero..ct_sasiento,  cob_conta_tercero..ct_scomprobante
where sa_fecha_tran   > @w_fecha_fm
and   sa_comprobante  = sc_comprobante
and   sa_fecha_tran   = sc_fecha_tran
and   sa_producto     = sc_producto
and   sa_empresa      = sc_empresa
and   sc_empresa      = @i_empresa
and   sa_ente         = @i_cliente_viejo
and   sc_estado       <> 'A'
and   isnull(sa_debito,0) - isnull(sa_credito,0) <> 0

if @@error != 0 begin
   select @w_msg = 'ERROR AL INSERTAR MOVIMIENTOS EN TABLA TEMPORAL #saldo_fm',
   @w_error   = 710001
   goto ERROR1
end

if not exists (select 1 from #saldo_fm) begin -- Cliente no tiene saldos contables 
   print 'No existen Saldos Contables ' + cast( @i_cliente_viejo as varchar)
   return 0
end

select
cuenta   = cuenta,
oficina  = oficina,
cliente  = cliente,
area     = area,
saldo    = sum(saldo)
into #saldo_hoy
from #saldo_fm
group by cuenta, oficina, cliente, area
having sum(saldo) != 0

if @@error != 0 begin
   select @w_msg = 'ERROR AL INSERTAR MOVIMIENTOS EN TABLA TEMPORAL #saldo_hoy',
   @w_error   = 710001
   goto ERROR1
end
  
-- Detalles por operacion
select
de_area         = area,
de_oficina      = oficina,
de_cuenta       = cuenta,
de_cliente      = cliente,
de_debito       = case when saldo < 0 then abs(saldo) else 0   end,
de_credito      = case when saldo > 0 then abs(saldo) else 0   end,
de_debcred      = case when saldo < 0 then '1'        else '2' end,
identity(int, 1,1) as de_asiento
into #det_cont
from #saldo_hoy

if @@error != 0 begin
   select @w_msg = 'ERROR AL INSERTAR MOVIMIENTOS EN TABLA TEMPORAL #det_cont',
   @w_error   = 710001
   goto ERROR1
end
  
-- Detalles por operacion
insert into #det_cont
select
de_area         = area,
de_oficina      = oficina,
de_cuenta       = cuenta,
de_cliente      = @i_cliente_nuevo,
de_debito       = case when saldo > 0 then abs(saldo) else 0   end,
de_credito      = case when saldo < 0 then abs(saldo) else 0   end,
de_debcred      = case when saldo > 0 then '1'        else '2' end
from #saldo_hoy

if @@error != 0 begin
   select @w_msg = 'ERROR AL INSERTAR MOVIMIENTOS EN TABLA TEMPORAL #det_cont 2',
   @w_error   = 710001
   goto ERROR1
end

update #det_cont set
de_oficina    = re_ofconta,
@w_re_ofconta = re_ofconta,
@w_ar_origen  = de_area
from cob_conta..cb_relofi 
where  re_filial  = 1
and    re_empresa = 1
and    re_ofadmin = de_oficina

if @@error != 0 begin
   select @w_msg = 'ERROR NO EXISTEN MOVIMIENTOS EN TABLA TEMPORAL #det_cont',
   @w_error   = 710001
   goto ERROR1
end

select 
@w_asiento = count(1),
@w_debito  = sum(abs(de_debito)),
@w_credito = sum(abs(de_credito))
from #det_cont

if @w_asiento <> 0 begin

   set rowcount 1

   select 
   @w_oficina = oficina,
   @w_area    = area
   from #saldo_hoy

   set rowcount 0

   exec @w_error = cob_conta..sp_cseqcomp
   @i_tabla     = 'cb_scomprobante', 
   @i_empresa   = 1,
   @i_fecha     = @w_fecha_proceso,
   @i_modulo    = @w_cod_producto,
   @i_modo      = 0, -- Numera por EMPRESA-FECHA-PRODUCTO
   @o_siguiente = @w_comprobante out
      
   if @w_error <> 0 begin
      select 
      @w_mensaje = ' ERROR AL GENERAR NUMERO COMPROBANTE ' 
      goto ERROR1
   end

   insert into cob_conta_tercero..ct_scomprobante_tmp with (rowlock) (
   sc_producto,       sc_comprobante,   sc_empresa,
   sc_fecha_tran,     sc_oficina_orig,  sc_area_orig,
   sc_digitador,      sc_fecha_gra,     sc_descripcion,    
   sc_perfil,         sc_detalles,      sc_tot_debito,
   sc_tot_credito,    sc_tot_debito_me, sc_tot_credito_me,
   sc_automatico,     sc_reversado,     sc_estado,
   sc_mayorizado,     sc_observaciones, sc_comp_definit,
   sc_usuario_modulo, sc_tran_modulo,   sc_error)
   values (
   @w_cod_producto,   @w_comprobante,   1,
   @w_fecha_proceso,  @w_re_ofconta,    @w_ar_origen,
   @s_user,           convert(char(10),getdate(),101), 'TRASLADO SALDO ENTRE CLIENTES (sp_traslado_saldo)',       
   '',                @w_asiento,       @w_debito,
   @w_credito,        @w_debito,        @w_credito,
   @w_cod_producto,   'N',	             'I',
   'N',               null,             null,
   'sa',              -999,             'N')
   
   if @@error <> 0 begin
      select 
      @w_mensaje = 'ERROR AL INSERTAR REGISTROS EN LA TABLA ct_scomprobante_tmp ', 
      @w_error   = 710001
      goto ERROR1
   end   
  
   /* INGRESA ASIENTO */
     
   insert into cob_conta_tercero..ct_sasiento_tmp with (rowlock) (                                                                                                                                              
   sa_producto,        sa_fecha_tran,      sa_comprobante,
   sa_empresa,         sa_asiento,         sa_cuenta,
   sa_oficina_dest,    sa_area_dest,       sa_credito,
   sa_debito,          sa_credito_me,      sa_concepto,        
   sa_debito_me,       sa_cotizacion,      sa_tipo_doc,
   sa_tipo_tran,       sa_moneda,          sa_opcion,
   sa_ente,            sa_con_rete,        sa_base,
   sa_valret,          sa_con_iva,         sa_valor_iva,
   sa_iva_retenido,    sa_con_ica,         sa_valor_ica,
   sa_con_timbre,      sa_valor_timbre,    sa_con_iva_reten,
   sa_con_ivapagado,   sa_valor_ivapagado, sa_documento,
   sa_mayorizado,      sa_con_dptales,     sa_valor_dptales,
   sa_posicion,        sa_debcred,         sa_oper_banco,
   sa_cheque,          sa_doc_banco,       sa_fecha_est, 
   sa_detalle,         sa_error )
   select
   @w_cod_producto,    @w_fecha_proceso,   @w_comprobante,
   1,                  de_asiento,         de_cuenta,
   de_oficina,         de_area,            de_credito,
   de_debito,          0,                  'RECLASIFICANDO SALDOS DESDE CLIENTE ' + convert(varchar, @i_cliente_viejo) + ' AL CLIENTE ' + convert(varchar, @i_cliente_nuevo),              
   0,                  1,                  'N',
   'A',                0,                  0,
   de_cliente,         null,               0,
   null,               '',                 0,
   null,               null,               null,
   null,               null,               null,
   null,               null,               '',
   'N',                null,               null,
   'S',                de_debcred,         null,
   null,               null,               null,
   null,               'N' 
   from #det_cont
   
   if @@error <> 0 begin
      select 
      @w_mensaje = 'ERROR AL INSERTAR REGISTROS EN LA TABLA ct_sasiento_tmp ',
      @w_error   = 710001
      goto ERROR1
   end  
end

return 0

ERROR1:                    

select @w_msg = convert(varchar,@i_cliente_viejo) + ' - ' +  @w_msg                 

exec sp_errorlog                  
@i_fecha        = @w_fecha_proceso,       
@i_error        = @w_error,       
@i_usuario      = @s_user,        
@i_tran         = 7999,           
@i_tran_name    = @w_sp_name,     
@i_cuenta       = 'ERR TRASLADO CLI',  
@i_descripcion  = @w_msg,     
@i_rollback     = 'S'     

return @w_error 

go  
                          
/*

declare @w_msg varchar(100)

exec sp_conta_traslados
  @s_user           = 'sa',
  @i_cliente_viejo  = 528809,
  @i_cliente_nuevo  = 11960,
  @i_empresa        = 1,
  @w_msg            = @w_msg
  
  select @w_msg


*/        
                                     