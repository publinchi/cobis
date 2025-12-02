/************************************************************************/
/*  Archivo:            aplipagsol.sp                                   */
/*  Stored procedure:   sp_aplica_pag_sol                               */
/*  Base de datos:      cob_cartera                                     */
/*  Producto:           Cartera                                         */
/*  Disenado por:                                                       */
/*  Fecha de escritura:                                                 */
/************************************************************************/
/*                             IMPORTANTE                               */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  "Cobiscorp".                                                        */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado hecho por alguno de sus             */
/*  usuarios sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de Cobiscorp o su representante.              */
/************************************************************************/  
/*                              PROPOSITO                               */
/* Este programa ingresa pagos solidarios a estructuras previas que     */
/* serán consultadas para generar notas de débito                       */
/************************************************************************/  
/* Agosto 2017       T. Baidal            Emision Inicial               */
/************************************************************************/
use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_aplica_pag_sol')
drop proc sp_aplica_pag_sol
go

create proc sp_aplica_pag_sol
(
@s_user          varchar(14),
@s_ssn           int,
@s_sesn          int,
@s_date          datetime,
@t_debug         char(1)      = 'N',
@t_file          varchar(10)  = null,
@i_operacion     char(1),
@i_grupo         int,
@i_afecta_ahorro char(1),
@i_monto_total   money,
@i_lista_pagos   varchar(8000)
)
as
declare
@w_sp_name        varchar(30),
@w_error          int,
@w_fecha  datetime,
@w_ciclo_act      int,
@w_prestamo_gr    cuenta,
@w_monto_detalle  money,
@w_total_exigible money,
@w_est_vencido    int,
@w_est_vigente    int,
@w_operacionca    int,
@w_cliente        int,
@w_monto_dif      money,
@w_secuencial_cad int,
@w_commit         char(1),
@w_dif_total      money,
@w_num_dec        int,
@w_est_cancelado  int

select @w_sp_name = 'sp_aplica_pag_sol'

exec @w_error = sp_decimales
@i_moneda       = 0, --moneda nacional
@o_decimales    = @w_num_dec out

if @w_error <> 0  goto ERROR


create table #cadena(
secuencial int, 
valor1     varchar(100),
valor2     varchar(100))

create table #descuadre (
cliente   int,
operacion int,
monto_dif money)

create table #registros_actualizados(
cliente   int,
operacion int
)


/* ESTADOS DE CARTERA */
exec @w_error    = sp_estados_cca
@o_est_vigente   = @w_est_vigente   out,
@o_est_vencido   = @w_est_vencido   out,
@o_est_cancelado = @w_est_cancelado out

if @i_operacion = 'I'
begin

   if @i_monto_total = 0 
   BEGIN 
      select @w_error = 724621 
	  goto ERROR
   END
   
   
   select @w_fecha = max(cdt_fecha)
   from ca_cobranza_det_tmp
   where cdt_grupo = @i_grupo
      
   if @w_fecha is null
   begin
      select @w_error = 70127
	  goto ERROR
   end
   
   select 
   @w_total_exigible = isnull(sum(cdt_monto_exigible),0)
   from ca_cobranza_det_tmp
   where cdt_grupo = @i_grupo
   and   cdt_fecha = @w_fecha

   if @i_monto_total <> @w_total_exigible
   begin
      select @w_error   = 724657 -- El monto total del Pago solidario no coincide con el monto vencido de la operacion
	  goto ERROR
   end  
   
   
   --DATOS DEL PRESTAMO GRUPAL
   select @w_ciclo_act = max(ci_ciclo) 
   from cob_cartera..ca_ciclo
   where ci_grupo = @i_grupo
   
   if @w_ciclo_act is null
   begin
      select @w_error = 724605 --ERROR AL CONSULTAR DATOS DEL GRUPO
	  goto ERROR
   end

   select @w_prestamo_gr = ci_prestamo
   from cob_cartera..ca_ciclo
   where ci_grupo = @i_grupo
   and   ci_ciclo = @w_ciclo_act

   if @w_prestamo_gr is null
   begin
      select @w_error = 724605 --ERROR AL CONSULTAR DATOS DEL GRUPO
	  goto ERROR
   end

   if @@trancount = 0 begin
      begin tran
      select @w_commit = 'S'
   end
   
    delete ca_pago_solidario_det 
	where psd_grupo = @i_grupo 
	and psd_fecha   = @w_fecha
	if @@error <> 0 begin 
	   select 
	   @w_error = 710003
	   goto  ERROR 	   
	end 
   
   --DIVISIÓN DE CADENA QUE CONCATENA EL DETALLE DE PAGOS
   exec @w_error = sp_division_cadena 
   @i_cadena     = @i_lista_pagos, 
   @o_secuencial = @w_secuencial_cad out
   
   if @w_error <> 0 goto ERROR
   
   if exists (select 1 from #cadena where secuencial = @w_secuencial_cad and (valor1 = '' or valor2 = ''))
   begin
      select @w_error = 70125 -- CAMPO REQUERIDO ESTÁ CON VALOR NULO
      goto ERROR
   end
   
   if exists (select 1 from #cadena where valor1 not in (select tg_cliente from cob_credito..cr_tramite_grupal where tg_referencia_grupal = @w_prestamo_gr))
   begin
      select @w_error = 70128 -- NO SE ENCONTRÓ CLIENTE EN TRÁMITE GRUPAL
      goto ERROR
   end
   
   --INSERCIÓN DEL DETALLE DE PAGOS
   insert into ca_pago_solidario_tmp (
   pst_grupo,  pst_fecha,       pst_cliente,
   pst_monto)
   select 
   @i_grupo,  @w_fecha, convert(int,valor1),
   convert(money,valor2)
   from #cadena 
   where secuencial = @w_secuencial_cad
   and convert(money,valor2) > 0
   
   if @@error <> 0
   begin
      select @w_error = 70129 -- ERROR AL INSERTAR REGISTRO
      goto ERROR
   end
   
   --VALIDACION DE MONTO SOLIDARIO Y TOTAL MONTO DEL DETALLE
   select @w_monto_detalle = sum(pst_monto)
   from ca_pago_solidario_tmp
   where pst_grupo = @i_grupo
   and   pst_fecha = @w_fecha 
   
   if @i_monto_total <> @w_monto_detalle
   begin
      select @w_error = 724656 --Total de valores del detalle no coincide con el monto total del Pago solidario
	  goto ERROR
   end
    
   if (@i_afecta_ahorro = 'S') begin	
      update ca_pago_solidario_tmp set
      pst_cuenta = op_cuenta
      from cob_credito..cr_tramite_grupal, ca_operacion
      where tg_referencia_grupal = @w_prestamo_gr
      and tg_cliente             = pst_cliente
      and pst_grupo              = @i_grupo
      and pst_fecha              = @w_fecha
      and op_banco               = tg_prestamo 
   end 
	 
   update ca_pago_solidario_tmp
   set pst_proporcion = convert(float,pst_monto) / convert(float,@w_monto_detalle)
   where pst_grupo = @i_grupo
   and   pst_fecha = @w_fecha
   
   --INSERCIÓN DE MONTOS A PAGAR POR CADA CLIENTE A CADA PRESTAMO VENCIDO
   --SE CALCULA DE ACUERDO AL VALOR PROCIONAL DE PAGO DE CADA CLIENTE
   insert into ca_pago_solidario_det (
   psd_grupo,                                 psd_fecha,         psd_cliente,
   psd_monto,                                 psd_cuenta,        psd_operacion, 
   psd_banco)
   select 
   @i_grupo,                                   @w_fecha,         pst_cliente,
   round(cdt_monto_exigible*pst_proporcion,@w_num_dec), pst_cuenta,       cdt_operacion,
   cdt_banco
   from ca_pago_solidario_tmp, ca_cobranza_det_tmp
   where pst_grupo = cdt_grupo
   and   pst_fecha = cdt_fecha
   and   pst_grupo = @i_grupo
   and   pst_fecha = @w_fecha
   and   round(cdt_monto_exigible*pst_proporcion,@w_num_dec) >0
   order by    pst_cliente
   
   if @@error <> 0
   begin
      select @w_error = 70129 -- ERROR AL INSERTAR REGISTRO
      goto ERROR
   end
   
   --MANEJO DE DESCUADRE DE LOS VALORES CALCULADOS A CADA CLIENTE COMPARADO CON LO QUE CADA CLIENTE APORTA
   insert into #descuadre (cliente, monto_dif)
   select psd_cliente, pst_monto - sum (psd_monto)
   from ca_pago_solidario_det, ca_pago_solidario_tmp
   where psd_grupo      = @i_grupo
   and   psd_fecha      = @w_fecha
   and   pst_grupo      = psd_grupo
   and   pst_fecha      = psd_fecha
   and   psd_cliente    = pst_cliente
   group by psd_cliente, pst_monto
   having sum (psd_monto) <> pst_monto
   order by psd_cliente
   
   declare  cur_descuadre cursor
   for select cliente, monto_dif
   from #descuadre
   
   open cur_descuadre
   
   fetch cur_descuadre
   into @w_cliente, @w_monto_dif
   
   while @@fetch_status = 0
   begin
   
      select top 1 @w_operacionca = psd_operacion
      from ca_pago_solidario_det, cob_cartera..ca_cobranza_det_tmp
      where psd_grupo     = @i_grupo
	  and   psd_fecha     = @w_fecha
	  and   cdt_grupo     = psd_grupo
	  and   cdt_fecha     = psd_fecha
      and   cdt_operacion = psd_operacion
      group by psd_operacion, cdt_operacion, cdt_monto_exigible
	  having cdt_monto_exigible - sum(psd_monto) = @w_monto_dif
	  order by psd_operacion
	  
	  if @@rowcount = 0
	  begin
	     select top 1 @w_operacionca = psd_operacion
		 from ca_pago_solidario_det
		 where psd_grupo = @i_grupo
		 and   psd_fecha = @w_fecha
		 and psd_operacion not in (select operacion from #registros_actualizados)
	  end
	  	  
	  update ca_pago_solidario_det
	  set psd_monto       = psd_monto + @w_monto_dif
	  where psd_grupo     = @i_grupo
	  and   psd_fecha     = @w_fecha
	  and   psd_cliente   = @w_cliente
	  and   psd_operacion = @w_operacionca
		  
	  insert into #registros_actualizados(operacion, cliente) values (@w_operacionca, @w_cliente)
	  	  
      fetch cur_descuadre
      into @w_cliente, @w_monto_dif
   end
   

   close cur_descuadre
   deallocate cur_descuadre
   
   delete ca_cobranza_det_tmp
   where cdt_grupo = @i_grupo
   and   cdt_fecha = @w_fecha
   
   delete ca_pago_solidario_tmp
   where pst_grupo = @i_grupo
   and   pst_fecha = @w_fecha
   
   --CONTROL PARA EVITAR PRESTAMOS YA CANCELADOS
   delete ca_pago_solidario_det 
   from ca_operacion
   where op_operacion = psd_operacion 
   and   op_estado = @w_est_cancelado
   if @@error <> 0 begin 
	   select 
	   @w_error = 710003
	   goto  ERROR 	   
   end 
      
   if @w_commit = 'S' begin
      commit tran
      select @w_commit = 'N'
   end
   
   return 0
end

return 0

ERROR:
if @w_commit = 'S' 
begin
   rollback tran
   select @w_commit = 'N'
end

exec cobis..sp_cerror
@t_debug = 'N',    
@t_file  = null,
@t_from  = @w_sp_name,
@i_num   = @w_error


return @w_error
go
