/************************************************************************/
/*  Archivo:            pago_grup.sp                                    */
/*  Stored procedure:   sp_pago_grupal                                  */
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
/* Este programa consulta los pagos de un grupo                         */
/************************************************************************/  
/* Julio 2017       T. Baidal            Emision Inicial                */
/************************************************************************/  
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_pago_grupal')
	drop proc sp_pago_grupal
go

create proc sp_pago_grupal
(
   @s_sesn      int          = NULL,
   @s_user      login        = NULL,
   @s_term      varchar (30) = NULL,
   @s_date      datetime     = NULL,
   @s_ofi       smallint     = NULL,
   @s_ssn       int,
   @s_srv       varchar(30),
   @s_lsrv      varchar(30)  = NULL,
   @i_grupo     int,
   @i_operacion char(1)      = NULL,
   @i_monto     money        = NULL,
   @i_fecha_control datetime     = NULL,
   @i_batch    char(1)       = 'N'
   
)
as

declare 
@w_sp_name          varchar(15),
@w_num_ciclo        int,
@w_banco            cuenta,
@w_total_garantia   money,
@w_est_vigente      tinyint,
@w_est_vencido      tinyint,
@w_est_cancelado    tinyint,
@w_est_novigente    tinyint,
@w_error            int,
@w_fecha_proceso    datetime,
@w_return           int,
@w_nombre_grp       varchar(150),
@w_secuencial_ing   int,
@w_fpago            varchar(10),
@w_ente             int,
@w_moneda           int,
@w_pago             money,
@w_total_exigible   money,
@w_total_prestamo   money,
@w_proporcion_deuda float,
@w_operacionca      cuenta,
@w_proporcion       float,
@w_num_dec          int,
@w_beneficiario     varchar(200),
@w_monto_pago       money,
@w_msg              varchar(150),
@w_commit           char(1),
@w_diferencia       money,
@w_max_sec          int,
@w_max_op           cuenta,
@w_gar_descuadre    varchar(64),
@w_op_descuadre     cuenta,
@w_dif_pago         money,
@w_total_pagar      money,
@w_max_gar          cuenta,
@w_tramite          int,
@w_codigo_externo   cuenta


select @w_sp_name = 'sp_pago_grupal', @w_commit = 'N'

select @w_fecha_proceso = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7

if  @i_fecha_control is null  select @i_fecha_control = @w_fecha_proceso 



--- ESTADOS DE CARTERA 
exec @w_error     = sp_estados_cca
@o_est_vigente    = @w_est_vigente   out,
@o_est_vencido    = @w_est_vencido   out,
@o_est_cancelado  = @w_est_cancelado out,
@o_est_novigente  = @w_est_novigente out

--DETERMINAR PRESTAMOS ACTIVOS DEL GRUPO --NUMERO DE CICLO
select @w_num_ciclo  = isnull(max(dc_ciclo),0) 
from ca_operacion, ca_det_ciclo
where dc_operacion = op_operacion 
and   op_estado in (@w_est_vigente,@w_est_vencido)
and   dc_grupo  =  @i_grupo

if @w_num_ciclo = 0
begin
   select
   @w_msg     = 'GRUPO NO TIENE PRESTAMOS ACTIVOS', 
   @w_error   = 724605 --Grupo no tiene operaciones activas 
   goto ERROR
end

--REFERENCIA GRUPAL
select @w_banco   = ci_prestamo,
       @w_tramite = ci_tramite 
from cob_cartera..ca_ciclo
where ci_grupo = @i_grupo
and ci_ciclo = @w_num_ciclo

create table #valores_grupo
(
   vg_tramite_grupal    cuenta,
   vg_operacion         int,
   vg_ente              int,
   vg_banco             cuenta,
   vg_moneda            smallint,
   vg_cliente_nom       varchar(250),
   vg_rol_id            char(1),
   vg_rol_desc          varchar(150),
   vg_cuotas_ven        int,
   vg_monto_exigible    money,
   vg_saldo_gar         money,
   vg_monto_pres        money,
   vg_proporcion        float,
   vg_garantia          varchar(64),
   vg_monto_pagar       money,
   vg_estado            char(1),
   vg_fecha_ult_proceso datetime,
   vg_tramite           int
)


insert into #valores_grupo (vg_tramite_grupal, vg_ente, vg_operacion)
select @w_banco, dc_cliente, dc_operacion
from cob_cartera..ca_det_ciclo
where dc_grupo = @i_grupo
and dc_ciclo_grupo = @w_num_ciclo



--DATOS CLIENTES
update #valores_grupo
set vg_cliente_nom = en_nomlar
from cobis..cl_ente
where vg_tramite_grupal = @w_banco
and en_ente  = vg_ente

update #valores_grupo
set vg_rol_id = cg_rol
from cobis..cl_cliente_grupo
where vg_ente = cg_ente
and cg_grupo = @i_grupo

update #valores_grupo
set vg_rol_desc = b.valor
from cobis..cl_tabla a, cobis..cl_catalogo b
where vg_tramite_grupal = @w_banco
and a.codigo = b.tabla
and a.tabla = 'cl_rol_grupo'
and b.codigo = vg_rol_id

--DIVIDENDOS Y MONTOS
update #valores_grupo
set vg_cuotas_ven = (select count(di_dividendo)
from cob_cartera..ca_dividendo
where di_operacion = vg_operacion
and (di_estado = @w_est_vencido  or (di_estado = @w_est_vigente  and di_fecha_ven <= @i_fecha_control)))

update #valores_grupo
set vg_monto_exigible = (select isnull(sum(am_cuota-am_pagado), 0)
from cob_cartera..ca_dividendo, cob_cartera..ca_amortizacion
where di_operacion = vg_operacion
and am_operacion = di_operacion
and am_dividendo = di_dividendo
and (di_estado = @w_est_vencido  or (di_estado = @w_est_vigente  and di_fecha_ven <= @i_fecha_control)))

if @@rowcount = 0
begin
   select @w_error = 708111 --No existen Dividendos para las operaciones
   goto ERROR
end

--DATOS OPERACION
update #valores_grupo set 
vg_banco             = op_banco,
vg_moneda            = op_moneda,
vg_monto_pres        = op_monto,
vg_estado            = op_estado,
vg_fecha_ult_proceso = op_fecha_ult_proceso,
vg_tramite           = op_tramite
from cob_cartera..ca_operacion
where vg_tramite_grupal = @w_banco
and   op_operacion      = vg_operacion

--GARANTIAS --
update #valores_grupo set 
vg_saldo_gar  = cu_valor_actual,
vg_garantia   = cu_codigo_externo
from cob_credito..cr_gar_propuesta, cob_custodia..cu_custodia
where vg_tramite_grupal = @w_banco
and   gp_tramite        = vg_tramite
and   cu_codigo_externo = gp_garantia
and   cu_estado         = 'V'

if @@rowcount = 0
begin
   select @w_error = 722214 --LA OBLIGACION NO TIENE UNA GARANTIA COLATERAL VALIDA ASOCIADA
   goto ERROR
end


if @i_operacion = 'S'
begin
   select vg_cliente_nom,vg_rol_desc,vg_banco,vg_cuotas_ven,vg_monto_exigible,isnull(vg_saldo_gar,0)
   from #valores_grupo
   where vg_tramite_grupal = @w_banco
   
   if @@rowcount = 0
   begin
      select @w_error = 724617 --No existen datos para las operaciones
      goto ERROR
   end
   
   return 0
end

if @i_operacion = 'G'
begin
   select @w_nombre_grp = gr_nombre 
   from cobis..cl_grupo
   where gr_grupo = @i_grupo
   
   if @@rowcount = 0
   begin
      select @w_error = 724605 --No existe Grupo
      goto ERROR
   end
   
   select @w_nombre_grp,sum(vg_monto_exigible),sum(vg_saldo_gar)
   from #valores_grupo
   where vg_tramite_grupal = @w_banco
      return 0
end


if @i_operacion = 'I'
begin
   
   
   if exists(select 1 from #valores_grupo where vg_fecha_ult_proceso <> @w_fecha_proceso and vg_estado not in (@w_est_novigente, @w_est_cancelado))
   begin
      select @w_error =  724618  -- Una o varias operaciones no se encuentran en la fecha proceso
	  goto ERROR
	 
   end

   create table #detalle_pagos(
   dp_secuencial int identity,
   dp_operacion  int,
   dp_garantia   varchar(64),
   dp_cliente_gar int, 
   dp_monto      money )
   
   select @w_fpago = 'GAR_DEB'
   
   select 
   @w_total_prestamo = sum(vg_monto_pres), 
   @w_total_exigible = sum(vg_monto_exigible),
   @w_total_garantia = sum(vg_saldo_gar)
   from #valores_grupo
      
   
   if @i_monto is null 
   begin
      --select @i_monto = case when @w_total_garantia > @w_total_exigible then @w_total_exigible else @w_total_garantia end 
      if @w_total_garantia > @w_total_exigible 
         select @i_monto = @w_total_exigible
      else
	 select @i_monto = @w_total_garantia
   end
 
  if @i_monto <= 0
   begin
      select @w_error = 724621 -- El prestamo no tiene saldo exigible a cancelar
	  goto ERROR
   end

  if @w_total_exigible <= 0
   begin
      select @w_error = 724619 -- El prestamo no tiene saldo exigible a cancelar
	  goto ERROR
   end
   
   if @w_total_garantia < = 0
   begin
       select @w_error = 724620 --Prestamo no tiene saldo de garantía
	   goto ERROR
   end
   
   exec @w_error = sp_decimales
   @i_moneda       = 0, --moneda nacional
   @o_decimales    = @w_num_dec out
   
   if @w_error <> 0  goto ERROR
   
   select @w_proporcion_deuda = convert(float,@i_monto) / convert(float,@w_total_exigible)
   
   update #valores_grupo
   set vg_proporcion  = convert(float,vg_saldo_gar) / convert(float,@w_total_garantia),
       vg_monto_pagar = round(vg_monto_exigible * @w_proporcion_deuda, @w_num_dec)
	   
   select @w_total_pagar = sum(vg_monto_pagar)
   from #valores_grupo
   
   select top 1 
   @w_max_op  = vg_operacion,
   @w_max_gar = vg_garantia
   from #valores_grupo
   where vg_estado not in (@w_est_novigente, @w_est_cancelado)
   and   vg_monto_exigible > 0
   order by vg_monto_pres desc
   
   --SI MONTO A PAGAR INGRESADO POR PANTALLA ES DIFERENTE DE LA SUMA DE LOS PAGOS CALCULADOS, SE ACTUALIZA UNO DE LOS VENCIMIENTOS PARA QUE CUADRE
   if @i_monto <> @w_total_pagar
   begin
      select @w_dif_pago = @i_monto - @w_total_pagar
	  
      update #valores_grupo
      set vg_monto_pagar = vg_monto_pagar + @w_dif_pago
      where vg_operacion = @w_max_op
   end
   
   --CURSOR QUE RECORRE CADA PAGO Y CALCULA EL MONTO DE PAGO PROPORCIONAL POR CADA INTEGRANTE
   declare cur_pagos cursor
   for select vg_ente, vg_cliente_nom,  vg_banco, vg_operacion, vg_monto_pagar, vg_moneda
   from #valores_grupo
   where vg_monto_exigible > 0
   
   open  cur_pagos
   fetch cur_pagos
   into  @w_ente, @w_beneficiario, @w_banco, @w_operacionca, @w_pago, @w_moneda

   while @@fetch_status = 0
   begin
      insert into #detalle_pagos
      select @w_operacionca, vg_garantia, vg_ente, round(convert(money,convert(float,@w_pago) * vg_proporcion), @w_num_dec)
      from #valores_grupo
      where vg_garantia is not null
      and vg_saldo_gar > 0
      order by vg_monto_pres
	  
      fetch cur_pagos
      into  @w_ente, @w_beneficiario, @w_banco, @w_operacionca, @w_pago, @w_moneda
   end

   close cur_pagos
   deallocate cur_pagos
   

   ------ **** MANEJO DE DESCUADRES POR REDONDEO DE DECIMALES ***
   create table #descuadre
   (
   de_garantia   varchar(64),
   de_operacion  int,
   de_saldo      money,
   de_monto      money,
   de_diferencia money
   )
   
   --------Tabla para control de la ca_garantia_liquida 
   create table #afectacion_total
   (
   cliente      int,
   monto        money
   )
   
   --SI SE CANCELA CON EL TOTAL DE LA GARANTÍA SE CONSULTA SI HAY DESCUADRES ENTRE EL SALDO DE CADA GARANTÍA Y LA SUMA DE LOS DESCUENTOS A LA GARANTÍA RESPECTIVA
   if @i_monto = @w_total_garantia
   begin
      insert into #descuadre (de_garantia, de_saldo, de_monto, de_diferencia)
      select vg_garantia, vg_saldo_gar, sum(dp_monto), vg_saldo_gar - sum(dp_monto)
      from #valores_grupo, #detalle_pagos
      where vg_garantia = dp_garantia
      group by vg_garantia, vg_saldo_gar
      having sum(dp_monto) <> vg_saldo_gar
   end
   
   --SI SE CANCELA EL TOTAL DEL PRESTAMO SE CONSULTA SI HAY DESCUADRES ENTRE EL EXIGIBLE DE CADA PRESTAMO Y LA SUMA DE LOS PAGOS DE CADA PRESTAMO
   if @i_monto = @w_total_exigible
   begin   
      insert into #descuadre (de_operacion, de_saldo, de_monto, de_diferencia)
      select vg_operacion, vg_monto_pagar, sum(dp_monto), vg_monto_pagar - sum(dp_monto)
      from #valores_grupo, #detalle_pagos
      where vg_operacion = dp_operacion
      group by vg_operacion, vg_monto_pagar
      having sum(dp_monto) <> vg_monto_pagar
   end
      
   --SI HAY DESCUADRE DEBIDO AL REDONDEO SE ACTUALIZA UNO DE LOS REGISTROS PARA QUE CUADREN LOS VALORES
   declare cur_descuadre cursor
   for select de_garantia, de_operacion, de_diferencia
   from #descuadre
   
   open cur_descuadre
   fetch cur_descuadre
   into @w_gar_descuadre, @w_op_descuadre, @w_diferencia
   
   while @@fetch_status = 0
   begin
       if @w_gar_descuadre is not null
	   begin
	      update #detalle_pagos
          set dp_monto = dp_monto+isnull(@w_diferencia, 0)
          where dp_operacion = @w_max_op
          and dp_garantia = @w_gar_descuadre
	   end
	   else if @w_op_descuadre is not null
	   begin
	      update #detalle_pagos
          set dp_monto = dp_monto+isnull(@w_diferencia, 0)
          where dp_operacion = @w_op_descuadre
          and   dp_garantia  = @w_max_gar
	   end
       
       fetch cur_descuadre
       into @w_gar_descuadre, @w_op_descuadre, @w_diferencia
   end
   
   close cur_descuadre
   deallocate cur_descuadre
    
   declare cur_pagos cursor
   for select vg_ente, vg_cliente_nom,  vg_banco, vg_operacion, vg_monto_pagar, vg_moneda,vg_garantia
   from #valores_grupo
   where vg_monto_exigible > 0
   
   open  cur_pagos
   fetch cur_pagos
   into  @w_ente, @w_beneficiario, @w_banco, @w_operacionca, @w_pago, @w_moneda, @w_codigo_externo

   while @@fetch_status = 0
   begin
	  if @@trancount = 0
	  begin
	     select @w_commit = 'S'
		 begin tran
	  end	  
	   
	  
     exec @w_error = sp_pago_cartera
      @s_user           = @s_user,
      @s_term           = @s_term,
      @s_date           = @w_fecha_proceso,
      @s_sesn           = @s_sesn,
      @s_ofi            = @s_ofi ,
      @s_ssn            = @s_ssn,
      @s_srv            = @s_srv,
      @i_banco          = @w_banco,
      @i_beneficiario   = @w_beneficiario,
      @i_fecha_vig      = @w_fecha_proceso, 
      @i_ejecutar       = 'S',
      @i_en_linea       = 'S',
      @i_producto       = @w_fpago, 
      @i_monto_mpg      = @w_monto_pago,
      @i_moneda         = @w_moneda,
	  @i_pago_gar_grupal = 'S',
	  @i_cuenta          = @w_codigo_externo,
      @o_secuencial_ing = @w_secuencial_ing out

      if @w_error <> 0 
      begin
         select 
         @w_msg = 'ERROR EN APLICACION DE PAGO (sp_pago_cartera)'
		 close cur_pagos
         deallocate cur_pagos
         goto ERROR
      end   
     
	  truncate table #afectacion_total
	  
	  insert into #afectacion_total
	  select dp_cliente_gar, sum(dp_monto) 
	  from #detalle_pagos
	  where dp_operacion = @w_operacionca
	  group by dp_cliente_gar
	  
	  if @@error <> 0 begin 
	     select 
		 @w_error = 710001,
		 @w_msg   = 'ERROR AL DETERMINAR AFECTACION TOTAL'
		 close cur_pagos
         deallocate cur_pagos
         goto ERROR
	  
	  end
	  

	  if @w_commit = 'S'
	  begin
	     select @w_commit = 'N'
	     commit tran
	  end
      fetch cur_pagos
      into  @w_ente, @w_beneficiario, @w_banco, @w_operacionca, @w_pago, @w_moneda,@w_codigo_externo
   end

   close cur_pagos
   deallocate cur_pagos
   
   return 0
end



ERROR:
if @w_commit = 'S'
begin
   select @w_commit = 'N'
   rollback tran
end
   
if @i_batch = 'S' 
begin 

  exec cob_cartera..sp_errorlog 
    @i_fecha       = @w_fecha_proceso,
    @i_error       = @w_error,
    @i_usuario     = 'usrbatch',
    @i_tran        = 7999,
    @i_tran_name   = @w_sp_name,
    @i_cuenta      = '',
    @i_descripcion = @w_msg,
    @i_rollback    = 'N'
 
end else begin 
    exec cobis..sp_cerror 
    @t_from = @w_sp_name, 
    @i_num = @w_error, 
    @i_msg = @w_msg
end 


return @w_error
 
go

