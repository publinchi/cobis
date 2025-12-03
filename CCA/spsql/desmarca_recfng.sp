-- Pagos reconocimiento FNG

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_des_recfng_mas') drop proc sp_des_recfng_mas
go

---LLS50490 MAR.30.2012 partiendo de la version 2

create proc sp_des_recfng_mas
as declare 
   @w_operacion      int,
   @w_banco          cuenta,
   @w_vlr_pago       money,
   @w_fecha_pago     datetime,
   @w_sec_ing        int,
   @w_cliente        int,
   @w_cedula         cuenta,
   @w_fecha_pag      datetime,
   @w_return         int,
   @w_oficina        int,
   @w_tramite        int,
   @w_codigo_externo varchar(25),
   @w_gar_fng       catalogo,
   @w_concepto_fng  catalogo,
   @w_parametro_iva_fng catalogo
   
        
-- CARGA DEL ARCHIVO ENTREGADO POR BANCA MIA

select @w_operacion = 0

select @w_fecha_pago = fc_fecha_cierre 
from cobis..ba_fecha_cierre
where fc_producto = 7

--Parametros generales
select @w_gar_fng  = pa_char
from   cobis..cl_parametro
where  pa_producto = 'GAR'
and    pa_nemonico = 'CODFNG'
set transaction isolation level read uncommitted

select @w_concepto_fng = pa_char   
 from cobis..cl_parametro
where pa_nemonico = 'COMFNG'
and pa_producto = 'CCA'  
set transaction isolation level read uncommitted
  
select @w_parametro_iva_fng = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'IVAFNG' 
set transaction isolation level read uncommitted

while 1 = 1 begin

   set rowcount 1

   select @w_cliente     = op_cliente,
          @w_banco       = cf_banco,
          @w_vlr_pago    = cf_pago,
          @w_operacion   = op_operacion,
          @w_oficina     = op_oficina,
          @w_tramite     = op_tramite
   from ca_recfng_mas, ca_operacion, cobis..cl_ente
   where op_operacion > @w_operacion
   and   op_banco     = cf_banco
   and   en_ente      = op_cliente
   order by op_operacion

   if @@rowcount = 0 begin
      set rowcount 0
      break
   end

   set rowcount 0
      
   begin tran
   
   select @w_codigo_externo = cu_codigo_externo
   from cob_custodia..cu_custodia, 
         cob_credito..cr_gar_propuesta, 
         cob_credito..cr_tramite,
         cob_custodia..cu_tipo_custodia                  
   where gp_tramite  = @w_tramite
     and gp_garantia = cu_codigo_externo 
     and cu_estado   = 'V'
     and tr_tramite  = gp_tramite
     and cu_tipo     = tc_tipo
     and tc_tipo_superior  = @w_gar_fng     
     
   if  @w_codigo_externo is not null begin
      exec @w_return         = cob_custodia..sp_cambios_estado
           @s_user           = 'sa',
           @s_date           = @w_fecha_pago,
           @s_term           = 'Term1',
           @s_ofi            = @w_oficina,
           @i_operacion      = 'I',
           @i_estado_ini     = 'V',
           @i_estado_fin     = 'C',
           @i_codigo_externo = @w_codigo_externo,
           @i_banderafe      = 'N', 
           @i_banderabe      = 'S'
           
           if @w_return <> 0 begin
              Print 'Error al Desmarcar Garantia ' + cast(@w_banco as varchar)
              rollback
              goto ERROR        
           end
   end     
   
   update   ca_rubro_op
   set      ro_prioridad = 90
   where    ro_operacion = @w_operacion
   and      ro_concepto  = 'CAP'

   if @@rowcount = 0 begin
      Print 'Error actualizando ca_rubro_op' + cast(@w_banco as varchar)
      rollback
      goto ERROR
   end

   ---Poner en 0 la comision para las cuotas futuras que 
	---auno la tiene calculada y contabilizada
	update ca_amortizacion
	set am_cuota = 0
	from  ca_amortizacion
	where am_operacion =  @w_operacion
	and am_concepto in (@w_concepto_fng,@w_parametro_iva_fng)
	and am_acumulado = 0
    and am_cuota > 0
    and am_estado <> 3	

	if @@error <> 0 begin
      Print 'Error actualizando ca_amortizacion :  ' + cast(@w_banco as varchar)
      rollback
      goto ERROR        
     end	
   
   commit tran

   
   
      ERROR:   

   select 'Cliente: ', @w_cliente , ' - ' , 'Operacion: ', @w_banco, 'Garantia: ',  @w_codigo_externo , 'Tramite: ',  @w_tramite     
     
end

return 0
go

/*

exec sp_recfng_mas
@i_param = '20101111'

*/


