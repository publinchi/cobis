use cob_cartera
go

if exists (select 1 from sysobjects where name = 'ca_quitar_TP_113703')
   drop table ca_quitar_TP_113703
go
create table  ca_quitar_TP_113703 (
operacion_tp int null
)


if exists (select 1 from sysobjects where name = 'sp_quitar_TP_tmp')
   drop proc sp_quitar_TP_tmp
go

create proc sp_quitar_TP_tmp
as
declare 
   @w_fecha         datetime,
   @w_operacion     int,
   @w_banco         cuenta,
   @w_fecha_hoy    datetime,
   @w_spread        float,
   @w_signo         char(1),
   @w_error         int,
   @w_tr_fecha_ref       datetime,
   @w_secuencial         int

--tasa original = 41.995

-- SELECCIONA UNIVERSO DE OPERACIONES

select @w_fecha_hoy = fc_fecha_cierre from cobis..ba_fecha_cierre where fc_producto = 7

select 'cliente'=op_cliente
into #cliente
from cob_cartera..ca_TP_tmp,ca_operacion with (nolock)
where tramite = op_tramite
and   puntos_hoy  = 0
and spread > 0

select cliente,tot = count(1)
into #cliente_oper
from #cliente,ca_operacion with (nolock)
where cliente = op_cliente
group by cliente
having count(1) = 1

insert into  ca_quitar_TP_113703
select op_operacion
 from #cliente_oper,ca_operacion o with (nolock),ca_rubro_op with (nolock)
where cliente = op_cliente
and ro_operacion = op_operacion
and ro_concepto = 'INT'
and ro_factor > 0


select 'Operaciones a Procesar :'  select count(1)
from ca_quitar_TP_113703

   
select @w_operacion = 0

while 1 = 1 
begin
        set rowcount 1
        
		select  @w_operacion = operacion_tp,
		        @w_banco     = op_banco
		from ca_quitar_TP_113703,ca_operacion with (nolock)
		where  op_operacion = operacion_tp
		and    operacion_tp > @w_operacion
		and    op_estado <> 3
		order by operacion_tp
		
      if @@rowcount = 0 begin
         set rowcount 0
         break
      end

      set rowcount 0

           delete ca_reajuste_det
           where red_operacion = @w_operacion
           
           delete ca_reajuste
           where re_operacion = @w_operacion
           
           select @w_tr_fecha_ref  = '01/01/1900'
	       select @w_tr_fecha_ref = tr_fecha_ref
	       from ca_transaccion
	       where tr_operacion = @w_operacion
	       and   tr_tran = 'DES'
	       and   tr_estado <> 'RV'
	       and   tr_secuencial >= 0
	

	     	exec @w_error = sp_fecha_valor 
			@s_user              = 'script',        
			@i_fecha_valor       = @w_tr_fecha_ref,
			@s_term              = 'Terminal', 
			@s_date              = @w_fecha_hoy,
			@i_banco             = @w_banco,
			@i_operacion         = 'F',
			@i_en_linea          = 'N',
			@i_control_fecha     = 'N',
			@i_debug             = 'N'
			if @w_error <> 0
			begin
			  PRINT 'Error No hizo la fecha valor REVISAR   ' + CAST (@w_banco as varchar) + ' @w_tr_fecha_ref  : ' + cast (@w_tr_fecha_ref as varchar)
			end
			ELSE
			begin
    		  PRINT 'Proceso Exitosamente ' + CAST (@w_banco as varchar)
	        end


end ----WHILE
set rowcount 0
set nocount off

return 0

go