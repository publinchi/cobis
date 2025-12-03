use cob_cartera
go

if exists (select 1 from sysobjects where name = 'ca_operacion_timbre')
   DROP TABLE ca_operacion_timbre
go

CREATE TABLE ca_operacion_timbre(
ot_regional         int            NULL,
ot_oficina          smallint       NULL,
ot_banco            cuenta         NULL,
ot_dm_beneficiario  descripcion    NULL,
ot_dm_fecha         datetime       NULL,
ot_dm_monto_mn      money          NULL,
ot_concepto_timbre  catalogo       NULL,
ot_monto_timbre     money          NULL,
ot_descripcion      descripcion    NULL,
ot_destino          catalogo       NULL
)
go


if exists (select 1 from sysobjects where name = 'sp_operacion_timbre')
   drop proc sp_operacion_timbre
go

create proc sp_operacion_timbre
   @i_fecha_desde       datetime = null,
   @i_fecha_hasta       datetime = null,
   @i_timbre            catalogo = null
as

declare 
@w_dm_secuencial	int, 
@w_operacion		int, 
@w_dm_beneficiario	descripcion, 
@w_dm_oficina		smallint, 
@w_dm_monto_mn		money,
@w_dm_fecha		datetime,
@w_error                int,
@w_clase                catalogo,
@w_nombre               descripcion,
@w_tipo_hipo            catalogo,
@w_tramite              int,
@w_banco                cuenta,
@w_gp_garantia          descripcion,
@w_oficina_oper         smallint,
@w_regional             smallint,
@w_concepto_timbre      catalogo,
@w_monto_timbre         money,
@w_name                 descripcion,
@w_destino              catalogo

select @w_name = 'sp_operacion_timbre'

select @w_tipo_hipo = pa_char from cobis..cl_parametro where pa_producto = 'CCA'
and pa_nemonico = 'GARHIP'



if @i_timbre is null
   select @i_timbre = 'IMPTIMBRE'


declare cursor_operacion cursor
for select  tr_operacion, tr_ofi_oper, dtr_concepto,  dtr_monto_mn
   from ca_transaccion, ca_det_trn
   where tr_operacion  = dtr_operacion
   and   tr_secuencial = dtr_secuencial
   and   tr_estado in ('ING','CON')
   and   tr_tran = 'DES'
   and   tr_moneda = 0
   and   tr_fecha_mov  between @i_fecha_desde and @i_fecha_hasta
   and   dtr_monto_mn > 0
   and   dtr_concepto = @i_timbre   
   for read only

open  cursor_operacion

fetch cursor_operacion 
into  
  @w_operacion, @w_oficina_oper, @w_concepto_timbre, @w_monto_timbre


while @@fetch_status = 0 
begin   
   if @@fetch_status = -1 
   begin    
      select @w_error = 70666
      
   end   
   
   select @w_clase   = op_clase,
          @w_nombre  = op_nombre,
          @w_tramite = op_tramite,
          @w_banco   = op_banco,
          @w_destino = op_destino
   from ca_operacion
   where op_operacion = @w_operacion


   select @w_gp_garantia = isnull(gp_garantia, 'TIMBRE OK')
   from cob_credito..cr_gar_propuesta,cob_custodia..cu_custodia,cob_custodia..cu_tipo_custodia
   where gp_tramite = @w_tramite
   and   gp_garantia = cu_codigo_externo
   and   tc_tipo_superior = @w_tipo_hipo  ---'1100'
   and   tc_tipo = cu_tipo
   and   cu_estado = 'V'
 


   select @w_regional = of_regional 
   from cobis..cl_oficina
   where  of_oficina = @w_oficina_oper



   select @w_dm_monto_mn = dm_monto_mn,
          @w_dm_fecha    = dm_fecha
   from ca_desembolso
   where dm_operacion  = @w_operacion
          


   insert into ca_operacion_timbre 
	  (ot_regional,		ot_oficina,		ot_banco,		ot_dm_beneficiario,	ot_dm_fecha,
	   ot_dm_monto_mn,	ot_concepto_timbre,	ot_monto_timbre,	ot_descripcion,		ot_destino)
   values(@w_regional,		@w_oficina_oper,	@w_banco,		@w_nombre,		@w_dm_fecha,   
	  @w_dm_monto_mn,	@w_concepto_timbre,	@w_monto_timbre,	@w_gp_garantia,		@w_destino)
  



fetch cursor_operacion into
  @w_operacion, @w_oficina_oper, @w_concepto_timbre, @w_monto_timbre


end -- CURSOR DE OBLIGACIONES

close cursor_operacion
deallocate cursor_operacion

return 0
go








