/************************************************************************/
/*      Archivo:                redesint.sp                             */
/*      Stored procedure:       sp_redescuento_int                      */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Diego Aguilar                           */
/*      Fecha de escritura:     May. 1999                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA".                                               */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Maneja las operaciones de redescuento y sus operaciones asocia_ */
/*      das                                                             */
/************************************************************************/  

use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_redescuento_int')
    drop proc sp_redescuento_int
go

create proc sp_redescuento_int
   @s_user                   login = null,
   @s_term                   varchar(30)  = null,
   @s_date                   datetime     = null,
   @s_sesn                   int          = null,
   @s_ofi                    smallint     = null,
   @i_operacion              char(1),     
   @i_pasiva                 cuenta       = null,
   @i_activa                 cuenta       = null,
   @i_moneda                 tinyint      = null,
   @i_tipo_op                char(1)      = null,
   @i_hereda                 char(1)      = 'N',
   @i_credito                char(1)      = 'N',
   @i_porcentaje_act         float        = null,
   @i_porcentaje_pas         float        = null,
   @i_llave_redes            cuenta       = null
                             
as                           
                             
declare                      
   @w_sp_name                descripcion,
   @w_return                 int,
   @w_error                  int,
   @w_activa                 int,
   @w_pasiva                 int,
   @w_toperacion_act         descripcion, 
   @w_toperacion_pas         descripcion,
   @w_fecha_ult_proc         datetime,
   @w_saldo_act              money,
   @w_saldo_pas              money,
   @w_vrelacion              money,
   @w_vdisponible            money,
   @w_sum_prtje              float,
   @w_total_prtje            float,
   @w_paso                   int,
   @w_fecha_1                datetime,
   @w_moneda_act             int,
   @w_moneda_pas             int,
   @w_saldo_vpas             money,
   @w_saldo_vact             money,
   @w_vrelacion_ant          money,
 --@i_porcentaje_act         float,
 --@i_porcentaje_pas         float,
   @w_op_tplazo              catalogo,  
   @w_op_plazo               smallint,
   @w_op_tdividendo          catalogo,
   @w_op_periodo_cap         smallint,
   @w_op_periodo_int         smallint,
   @w_dias_gracia            smallint,
   @w_fecha_fin              varchar(10),
   @w_cuota                  money,
   @w_suma_actual_pasiva     money,
   @w_suma_actual_activa     money,
   @w_saldo_actual_pasiva    money,
   @w_op_reajustable         char(1),
   @w_codigo_externo         cuenta,
   @w_llave_redescuento      cuenta,
   @w_op_fecha_ini           datetime,
   @w_op_gracia_cap          smallint,
   @w_op_gracia_int          smallint,
   @w_sec_activa             int,
   @w_sec_pasiva             int,
   @w_llave_redescuento_ant  cuenta,
   @w_fecha_ult_proceso      datetime,
   @w_op_cuota               money,
   @w_op_periodo_reajuste    smallint,
   @w_op_reajuste_especial   char(1),
   @w_op_dias_anio           smallint,
   @w_op_tipo_amortizacion   varchar(10),
   @w_op_dist_gracia         char(1),
   @w_op_dia_fijo            tinyint,
   @w_op_evitar_feriados     char(1),
   @w_op_mes_gracia          tinyint,
   @w_op_base_calculo        char(1),
   @w_op_recalcular_plazo    char(1),
   @w_op_fecha_fin           datetime,
   @w_op_opcion_cap          char(1),
   @w_op_tasa_cap            float,
   @w_op_dividendo_cap       smallint,
   @w_op_fecha_pri_cuot      datetime,
   @w_op_ult_dia_habil       char(1),
   @w_op_tipo_redondeo       tinyint,
   @w_op_convierte_tasa      char(1),
   @w_tipo_crecimiento       char(1)
                             


/*
print '..@i_llave_redes...%1!',@i_llave_redes
print '..@i_tipo_op...%1!',@i_tipo_op
print '..@i_operacion.%1!',@i_operacion
print '..@i_pasiva   .%1!',@i_pasiva
print '..@i_activa   .%1!',@i_activa
print '..@i_moneda   .%1!',@i_moneda
print '..@i_hereda   .%1!',@i_hereda
print '..@i_credito  .%1!',@i_credito
*/



/* CARGAR VALORES INICIALES */
select @w_sp_name = 'sp_redescuento'


if @i_tipo_op = 'R' begin  --REDESCUENTO

   select 
   @w_pasiva            = op_operacion,
   @w_toperacion_pas    = op_toperacion,
   @w_moneda_pas        = op_moneda,
   @w_llave_redescuento = op_codigo_externo
   from ca_operacion
   where op_banco    = @i_pasiva

   if @@rowcount = 0
      select 
      @w_pasiva            = opt_operacion,
      @w_toperacion_pas    = opt_toperacion,
      @w_moneda_pas        = opt_moneda,
      @w_llave_redescuento = opt_codigo_externo
      from ca_operacion_tmp
      where opt_banco   = @i_pasiva

   select 
   @w_activa         = op_operacion,
   @w_toperacion_act = op_toperacion,
   @w_moneda_act     = op_moneda,
   @w_op_reajustable = op_reajustable
   from ca_operacion 
   where op_banco    = @i_activa
end
else 
begin
   select 
   @w_activa            = op_operacion,
   @w_toperacion_act    = op_toperacion,
   @w_moneda_act        = op_moneda,
   @w_op_reajustable    = op_reajustable
   from ca_operacion
   where op_banco    = @i_activa

   if @@rowcount = 0
      select 
      @w_activa            = opt_operacion,
      @w_toperacion_act    = opt_toperacion,
      @w_moneda_act        = opt_moneda,
      @w_op_reajustable    = opt_reajustable
      from ca_operacion_tmp
      where opt_banco   = @i_activa


   select 
   @w_pasiva            = op_operacion,
   @w_toperacion_pas    = op_toperacion,
   @w_moneda_pas        = op_moneda,
   @w_llave_redescuento = op_codigo_externo
   from ca_operacion 
   where op_banco  = @i_pasiva

end



select 
@w_paso          = 0,
@w_saldo_vpas    = 0,
@w_vrelacion_ant = 0,
@w_saldo_vact    = 0


/* ELIMINAR SI EXISTE OEPRACIONES ANTES DEL INSERT  EN TEMPORALES*/

if @i_operacion in ('U','D') 
begin
   
   insert into ca_relacion_ptmo_ts
   select @s_date, getdate(), @s_user, @s_ofi, @s_term,@i_operacion, *
   from   ca_relacion_ptmo
   where  rp_activa = @w_activa
   and    rp_pasiva = @w_pasiva
   
   if @@error != 0 begin
      select @w_error = 703116
      goto ERROR
   end
  
end


delete  ca_relacion_ptmo_pago_temp
where rp_activa = @w_activa   

delete  ca_relacion_ptmo_pago_temp
where rp_pasiva = @w_pasiva   


/*ELIMINAR OPERACIONES ASOCIADAS*/
if @i_operacion = 'D' and @i_credito = 'N' 
begin

   delete ca_relacion_ptmo
   where  rp_activa = @w_activa
   and    rp_pasiva = @w_pasiva


   delete ca_relacion_ptmo_tmp
   where  rpt_activa = @w_activa
   and    rpt_pasiva = @w_pasiva


   update ca_operacion_tmp
   set opt_codigo_externo = ''
   where opt_operacion = @w_activa


   select @i_operacion = 'S'

end


if @i_operacion = 'D' and @i_credito = 'S' 
begin
   delete ca_relacion_ptmo
   where  rp_activa = @w_activa
   and    rp_pasiva = @w_pasiva
   and    rp_fecha_fin is null

   if @@error != 0 begin
      select @w_error = 710033
      goto ERROR
   end 

   update ca_operacion_tmp
   set opt_codigo_externo = ''
   where opt_operacion = @w_activa
end




/* SOLO DESDE EL MODULO DE CREDITO */

if @i_operacion = 'Z' and @i_credito = 'S'   ----SOLO DESDE CREDITO
begin

   if @i_tipo_op = 'R'
   begin

      /* SELECCIONO EL VALOR CODIGO EXTERNO GRABADO EN CA_OPERACION  OP PASIVA*/
      if @i_llave_redes is null
      begin
         select @w_error = 710458   ---Error, C½digo Externo Nulo en Operacion Pasiva
         goto ERROR
      end


      /*CONSULTA DE LA LLAVE DE REDESCUENTO DE LA OP PASIVA*/
      select @w_llave_redescuento_ant = opt_codigo_externo,
             @w_fecha_ult_proceso     = opt_fecha_ult_proceso
      from ca_operacion_tmp
      where opt_operacion = @w_pasiva
      if @@rowcount = 0
         select @w_llave_redescuento_ant = op_codigo_externo,
                @w_fecha_ult_proceso     = op_fecha_ult_proceso
         from ca_operacion
         where op_operacion = @w_pasiva


      if exists (select 1 from ca_relacion_ptmo where rp_pasiva = @w_pasiva)
      begin
         select @w_activa = rp_activa 
         from ca_relacion_ptmo
         where rp_pasiva = @w_pasiva
      end



      -- LA LLAVE DE REDESCUENTO DE LA OP.PASIVA = A LA LLAVE DE REDESCUENTO OP.PASIVA 
      update ca_operacion
      set op_codigo_externo = @i_llave_redes
      where op_operacion    = @w_activa

      update ca_operacion_his
      set oph_codigo_externo = @i_llave_redes
      where oph_operacion    = @w_activa


      update ca_operacion
      set op_codigo_externo = @i_llave_redes
      where op_operacion    = @w_pasiva

   
      update ca_operacion_his
      set oph_codigo_externo = @i_llave_redes
      where oph_operacion    = @w_pasiva

  
   end



   if @i_tipo_op = 'C'
   begin

      /* SELECCIONO EL VALOR CODIGO EXTERNO GRABADO EN CA_OPERACION  OP PASIVA*/
      if @i_llave_redes is null
      begin
         select @w_error = 710459   ---Error, C½digo Externo Nulo en Operacion Activa
         goto ERROR
      end


      /*CONSULTA DE LA LLAVE DE REDESCUENTO DE LA OP PASIVA*/
      select @w_llave_redescuento_ant = opt_codigo_externo,
             @w_fecha_ult_proceso     = opt_fecha_ult_proceso
      from ca_operacion_tmp
      where opt_operacion = @w_activa
      if @@rowcount = 0
         select @w_llave_redescuento_ant = op_codigo_externo,
                @w_fecha_ult_proceso     = op_fecha_ult_proceso
         from ca_operacion
         where op_operacion = @w_activa


      if exists (select 1 from ca_relacion_ptmo where rp_pasiva = @w_activa)
      begin
         select @w_activa = rp_activa 
         from ca_relacion_ptmo
         where rp_pasiva = @w_activa
      end



      /* LA LLAVE DE REDESCUENTO DE LA OP.PASIVA = A LA LLAVE DE REDESCUENTO OP.PASIVA */
      update ca_operacion
      set op_codigo_externo = @i_llave_redes
      where op_operacion    = @w_activa

      update ca_operacion_his
      set oph_codigo_externo = @i_llave_redes
      where oph_operacion    = @w_activa

   
      update ca_operacion
      set op_codigo_externo = @i_llave_redes
      where op_operacion    = @w_pasiva

      update ca_operacion_his
      set oph_codigo_externo = @i_llave_redes
      where oph_operacion    = @w_pasiva

   end
end



/*INSERTAR OPERACIONES ACTIVAS ASOCIADAS A PASIVAS*/
if @i_operacion = 'I' 
begin


   /*CONTROL COMENTADO POR PETICION DEL BANCO AGRARIO*/
   --if @w_moneda_act != @w_moneda_pas 
   --begin
   --   select @w_error = 710144
   --   goto ERROR
   --end

   if exists(select 1 from ca_relacion_ptmo_tmp 
             where rpt_activa = @w_activa and
             rpt_pasiva = @w_pasiva and
             rpt_fecha_fin is null) 
   begin
         --ESTO ES PORQUE YA EXISTE LA RELACION Y QUIERE HACERLA NUEVAMENTE 
         --SIN HABER TERMINADO LA ANTERIOR
      select @w_error = 710135
      goto ERROR
   end


   if exists(select 1 from ca_relacion_ptmo
             where  rp_pasiva = @w_pasiva) 
   begin
      --ESTO ES PARA VALIDAR EL SALDO DE LA PASIVA PARA VER SI AUN SOBRA PARA HACER OTRA RELACION
      
      select @w_suma_actual_pasiva  = sum(isnull( op_monto,0))
      from ca_operacion
      where op_operacion = @w_pasiva


      select @w_suma_actual_activa  = sum(isnull( rp_saldo_act,0))
      from ca_relacion_ptmo
      where rp_pasiva = @w_pasiva

      select @w_saldo_actual_pasiva = isnull(@w_suma_actual_pasiva - @w_suma_actual_activa,0)

      if @w_saldo_actual_pasiva <= 0 begin
         select @w_error = 708228
         goto ERROR
      end
   end


   if @i_credito = 'S'   ---cuando es ejecutado desde credito
   begin 

      select @w_saldo_act = sum(am_acumulado + am_gracia - am_pagado)
      from ca_amortizacion
      where am_operacion = @w_activa
      and am_concepto = 'CAP'


      select @w_saldo_pas = sum(am_acumulado + am_gracia - am_pagado )
      from ca_amortizacion
      where am_operacion = @w_pasiva
      and am_concepto = 'CAP'

      if @w_saldo_act > 0 and @w_saldo_pas > 0 
      begin
         insert into ca_relacion_ptmo
        (rp_activa,          rp_pasiva,          rp_lin_activa,
         rp_lin_pasiva,      rp_fecha_ini,       rp_fecha_fin,
         rp_porcentaje_act,  rp_porcentaje_pas,  rp_saldo_act,
         rp_saldo_pas,       rp_fecha_grb,       rp_usuario_grb, 
         rp_hora_grb)
         values
        (@w_activa,          @w_pasiva,          @w_toperacion_act,
         @w_toperacion_pas,  @s_date,            null,
         0,                  0,                  @w_saldo_act,
         @w_saldo_pas,       @s_date,            @s_user,
         convert(varchar(10),getdate(),108))
 
         if @@error <> 0 begin
            select @w_error = 710001  --710032
            goto ERROR
         end
      end 

      /* ACTUALIZACION DE LLAVE DE REDESCUENTO */
      if @i_llave_redes is not null
      begin

         update ca_operacion
         set op_codigo_externo = @i_llave_redes
         where op_operacion = @w_activa

         update ca_operacion
         set op_codigo_externo = @i_llave_redes
         where op_operacion = @w_pasiva
      end
   end
   else
   begin
      if @i_tipo_op != 'R' 
      begin
         select @w_saldo_act = sum(amt_acumulado + amt_gracia - amt_pagado)
         from ca_amortizacion_tmp
         where amt_operacion = @w_activa
         and amt_concepto = 'CAP'

         select @w_saldo_pas = sum(am_acumulado + am_gracia - am_pagado )
         from ca_amortizacion
         where am_operacion = @w_pasiva
         and am_concepto = 'CAP'

      end 
      else 
      begin
         select @w_saldo_act = sum(am_acumulado + am_gracia - am_pagado )
         from ca_amortizacion
         where am_operacion = @w_activa
         and am_concepto = 'CAP'

         select @w_saldo_pas = sum(amt_acumulado + amt_gracia - amt_pagado)
         from ca_amortizacion_tmp
         where amt_operacion = @w_pasiva
         and amt_concepto = 'CAP'
      end

      if @w_saldo_act > 0 and @w_saldo_pas > 0 begin
         insert into ca_relacion_ptmo_tmp
        (rpt_activa,          rpt_pasiva,          rpt_lin_activa,
         rpt_lin_pasiva,      rpt_fecha_ini,       rpt_fecha_fin,
         rpt_porcentaje_act,  rpt_porcentaje_pas,  rpt_saldo_act,
         rpt_saldo_pas,       rpt_fecha_grb,       rpt_usuario_grb, 
         rpt_hora_grb)
         values
        (@w_activa,           @w_pasiva,           @w_toperacion_act,
         @w_toperacion_pas,   @s_date,             null,
         0,                   0,                   @w_saldo_act,
         @w_saldo_pas,       @s_date,              @s_user,
         convert(varchar(10),getdate(),108))
 
         if @@error <> 0 begin
            select @w_error = 710001  --710032
            goto ERROR
         end
      end 

      select @i_operacion = 'S'

      update ca_operacion_tmp
      set opt_codigo_externo = @w_llave_redescuento
      where opt_operacion = @w_activa

   end
end



/*INSERTAR OPERACIONES ACTIVAS ASOCIADAS A PASIVAS*/
if @i_operacion = 'P' begin --CUANDO SE HACE UN PAGO o SE ELIMINA UNA RELACION

   if @i_tipo_op != 'R' 
   begin
      select @w_fecha_ult_proc = op_fecha_ult_proceso
      from ca_operacion
      where op_operacion = @w_activa

      insert into ca_relacion_ptmo_pago_temp
      select * from ca_relacion_ptmo
      where rp_activa = @w_activa   
      and rp_fecha_fin is null     

      declare cursor_ptmo cursor for 
      select rp_activa,rp_pasiva,rp_lin_activa,rp_lin_pasiva,rp_porcentaje_act,
      rp_porcentaje_pas
      from ca_relacion_ptmo_pago_temp
      where rp_activa = @w_activa   
      and rp_fecha_fin is null
      for read only
   end
   else 
   begin
      select @w_fecha_ult_proc = op_fecha_ult_proceso
      from ca_operacion
      where op_operacion = @w_pasiva

      insert into ca_relacion_ptmo_pago_temp
      select * from ca_relacion_ptmo
      where rp_pasiva = @w_pasiva   
      and rp_fecha_fin is null

      declare cursor_ptmo cursor for 
      select rp_activa,rp_pasiva,rp_lin_activa,rp_lin_pasiva,rp_porcentaje_act,
      rp_porcentaje_pas
      from ca_relacion_ptmo_pago_temp
      where rp_pasiva = @w_pasiva   
      and rp_fecha_fin is null
      for read only
   end


   open cursor_ptmo

   fetch cursor_ptmo into
   @w_activa,@w_pasiva,@w_toperacion_act,@w_toperacion_pas,@i_porcentaje_act,@i_porcentaje_pas

   while @@fetch_status = 0 begin 

      if (@@fetch_status = -1) begin
         select @w_error = 708999
         goto ERROR
      end  

      select @w_saldo_act = sum(am_acumulado + am_gracia - am_pagado )
      from ca_amortizacion
      where am_operacion = @w_activa
      and am_concepto = 'CAP'

      select @w_saldo_pas = sum(am_acumulado + am_gracia - am_pagado )
      from ca_amortizacion
      where am_operacion = @w_pasiva
      and am_concepto = 'CAP'

-- JCQ 06/17/2003 Se comenta debido a que genera inconsistencia con la Consulta en FrontEnd donde la fecha debe ser nula 

/*      update ca_relacion_ptmo set
      rp_fecha_fin      = @w_fecha_ult_proc,
      rp_fecha_upd      = @w_fecha_ult_proc,
      rp_usuario_upd    = @s_user,
      rp_hora_upd       = convert(varchar(10),getdate(),108)
      where rp_activa = @w_activa
      and rp_pasiva = @w_pasiva
      and rp_fecha_fin is null

      if @@error != 0 begin
         select @w_error = 710032
         goto ERROR
      end 

      select @w_fecha_1 = dateadd(dd,1,@w_fecha_ult_proc) */

   
      if @w_saldo_act > 0 and @w_saldo_pas > 0 begin
         insert into ca_relacion_ptmo(rp_activa,rp_pasiva,
         rp_lin_activa,rp_lin_pasiva,rp_fecha_ini,
         rp_porcentaje_act,rp_porcentaje_pas,rp_saldo_act,
         rp_saldo_pas,rp_fecha_grb,rp_usuario_grb,rp_hora_grb)
         values(@w_activa,@w_pasiva,@w_toperacion_act,
         @w_toperacion_pas,@w_fecha_ult_proc,@i_porcentaje_act,
         @i_porcentaje_pas,@w_saldo_act,@w_saldo_pas,
         @w_fecha_ult_proc,@s_user,
         convert(varchar(10),getdate(),108))

         if @@error <> 0 begin
            select @w_error = 710001  --710032
            goto ERROR
         end
      end 

      fetch cursor_ptmo into
      @w_activa,@w_pasiva,@w_toperacion_act,@w_toperacion_pas,
      @i_porcentaje_act,@i_porcentaje_pas

   end --fin cursor

   close cursor_ptmo
   deallocate cursor_ptmo

   if @w_paso = 1
      select @i_operacion = 'S'
end




/*ACTUALIZAR OPERACIONES ASOCIADAS DE REDESCUENTO*/
if @i_operacion = 'U' begin

   if @w_moneda_act != @w_moneda_pas begin
      select @w_error = 710144
      goto ERROR
   end
   
   if @i_tipo_op != 'R' begin

      select @w_saldo_act = isnull(sum(amt_acumulado - amt_pagado),0)
      from ca_amortizacion_tmp
      where amt_operacion = @w_activa
      and amt_concepto = 'CAP'

      select @w_saldo_pas = isnull(sum(am_acumulado - am_pagado),0)
      from ca_amortizacion
      where am_operacion = @w_pasiva
      and am_concepto = 'CAP'

      select @w_sum_prtje = isnull(sum(rpt_porcentaje_act),0)
      from ca_relacion_ptmo_tmp
      where rpt_activa = @w_activa
      and rpt_pasiva != @w_pasiva
      and rpt_fecha_fin is null

      select @w_total_prtje = @i_porcentaje_act + @w_sum_prtje

      if @w_total_prtje > 100.00 begin
         --ERROR ESTA PASANDO EL 100% DE LO QUE PUEDE RELACIONAR 
         select @w_error = 710134
         goto ERROR
      end

      select @w_sum_prtje = 0

      select @w_sum_prtje = isnull(sum(rpt_porcentaje_pas),0)
      from ca_relacion_ptmo_tmp
      where rpt_activa = @w_activa
      and rpt_pasiva != @w_pasiva
      and rpt_fecha_fin is null

      select @w_sum_prtje = 100 - @w_sum_prtje      

      select @w_vdisponible = (@w_saldo_pas * @w_sum_prtje) / 100   

      --CALCULAR EL VALOR A RELACIONAR DE LA ACTIVA
      select @w_vrelacion = (@w_saldo_act * @i_porcentaje_act) / 100

      if @w_vdisponible < @w_vrelacion begin
         --ERROR NO HAY VALOR DISPONIBLE PARA CUBRIR EL VALOR A RELACIONAR 
         select @w_error = 710141
         goto ERROR
      end

      select @i_porcentaje_pas = round(convert(float,(@w_vrelacion * 100))/convert(float,@w_saldo_pas),6)
      
   end
   else begin

      select @w_saldo_act = sum(am_acumulado - am_pagado)
      from ca_amortizacion
      where am_operacion = @w_activa
      and am_concepto = 'CAP'

      select @w_saldo_pas = sum(amt_acumulado - amt_pagado)
      from ca_amortizacion_tmp
      where amt_operacion = @w_pasiva
      and amt_concepto = 'CAP'

      select @w_sum_prtje = isnull(sum(rpt_porcentaje_pas),0)
      from ca_relacion_ptmo_tmp
      where rpt_activa != @w_activa
      and rpt_pasiva = @w_pasiva
      and rpt_fecha_fin is null

      select @w_total_prtje = @i_porcentaje_pas + @w_sum_prtje

      if @w_total_prtje > 100.00 begin
         --ERROR ESTA PASANDO EL 100% DE LO QUE PUEDE RELACIONAR 
         select @w_error = 710134
         goto ERROR
      end
 
      select @w_sum_prtje = 0

      select @w_sum_prtje = isnull(sum(rpt_porcentaje_pas),0)
      from ca_relacion_ptmo_tmp
      where rpt_activa != @w_activa
      and rpt_pasiva = @w_pasiva
      and rpt_fecha_fin is null

      select @w_sum_prtje = 100 - @w_sum_prtje      
 
      select @w_vdisponible = (@w_saldo_pas * @w_sum_prtje) / 100   

      select @w_vrelacion = (@w_saldo_act * @i_porcentaje_act) / 100

      if @w_vdisponible < @w_vrelacion begin
         --ERROR NO HAY VALOR DISPONIBLE PARA CUBRIR EL VALOR A RELACIONAR 
         select @w_error = 710141
         goto ERROR
      end
 
      select @i_porcentaje_pas = round(convert(float,(@w_vrelacion * 100))/convert(float,@w_saldo_pas),6)
   end
   
   update ca_relacion_ptmo_tmp set
   rpt_porcentaje_act = @i_porcentaje_act,
   rpt_porcentaje_pas = @i_porcentaje_pas,
   rpt_saldo_act = @w_saldo_act,
   rpt_saldo_pas = @w_saldo_pas,
   rpt_fecha_upd      = @s_date,
   rpt_usuario_upd    = @s_user,
   rpt_hora_upd   = convert(varchar(10),getdate(),108)
   where rpt_activa = @w_activa
   and rpt_pasiva = @w_pasiva

   if @@error != 0 begin
      select @w_error = 710032
      goto ERROR
   end 


   update ca_operacion_tmp
   set opt_codigo_externo = @w_llave_redescuento
   where opt_operacion = @w_activa


   select @i_operacion = 'S'

end




if @i_operacion = 'G'
   begin

      select
      @w_op_fecha_ini           =  op_fecha_ini,
      @w_op_fecha_fin           =  op_fecha_fin,
      @w_op_tplazo              =  op_tplazo,
      @w_op_plazo               =  op_plazo,
      @w_op_tdividendo          =  op_tdividendo,
      @w_op_periodo_cap         =  op_periodo_cap,
      @w_op_periodo_int         =  op_periodo_int,
      @w_op_gracia_cap          =  op_gracia_cap, 
      @w_op_gracia_int          =  op_gracia_int,
      @w_op_cuota               =  op_cuota,
      @w_op_periodo_reajuste    =  op_periodo_reajuste,
      @w_op_reajuste_especial   =  op_reajuste_especial,
      @w_op_dias_anio           =  op_dias_anio,
      @w_op_tipo_amortizacion   =  op_tipo_amortizacion,
      @w_op_dist_gracia         =  op_dist_gracia,
      @w_op_dia_fijo            =  op_dia_fijo,
      @w_op_evitar_feriados     =  op_evitar_feriados,
      @w_op_mes_gracia          =  op_mes_gracia,
      @w_op_base_calculo        =  op_base_calculo,
      @w_op_recalcular_plazo    =  op_recalcular_plazo,
      @w_op_opcion_cap          =  op_opcion_cap,
      @w_op_tasa_cap            =  op_tasa_cap,
      @w_op_dividendo_cap       =  op_dividendo_cap,
      @w_op_fecha_pri_cuot      =  op_fecha_pri_cuot,   
      @w_op_ult_dia_habil       =  op_dia_habil,       
      @w_op_tipo_redondeo   =  op_tipo_redondeo,    
      @w_tipo_crecimiento       =  op_tipo_crecimiento,     ---REUTILIZACIOND EL CAMPO, 'A' PARA CALCULO AUTOMATICO TABLA AMORTIZACION CAPITAL FIJO O CUOTA FIJA, 
                                                            ---Y 'D' DIGITADO UN VALOR DE CAPITAL O CUOTA FIJA 
      @w_op_convierte_tasa      =  isnull(op_convierte_tasa,'S')
      from cob_cartera..ca_operacion
      where op_operacion = @w_pasiva


      if @w_tipo_crecimiento in ('A','P')
         select @w_op_cuota = 0



      /*DIAS DE GRACIA CUANDO LLAMO DESDE RUBROS*/
      /******************************************/

      select @w_dias_gracia = isnull(di_gracia,0)
      from ca_dividendo
      where di_operacion = @w_pasiva
      and   di_dividendo = 1

      update ca_operacion_tmp
      set  
      opt_fecha_ini         = @w_op_fecha_ini,
      opt_fecha_fin         = @w_op_fecha_fin,
      opt_plazo             = @w_op_plazo,
      opt_tplazo            = @w_op_tplazo,
      opt_tdividendo        = @w_op_tdividendo,
      opt_periodo_cap       = @w_op_periodo_cap,
      opt_periodo_int       = @w_op_periodo_int,
      opt_cuota             = @w_op_cuota,
      opt_gracia_cap        = @w_op_gracia_cap, 
      opt_gracia_int        = @w_op_gracia_int,
      opt_periodo_reajuste  = @w_op_periodo_reajuste,
      opt_reajuste_especial = @w_op_reajuste_especial,
      opt_dias_anio         = @w_op_dias_anio,
      opt_tipo_amortizacion = @w_op_tipo_amortizacion,
      opt_dist_gracia       = @w_op_dist_gracia,
      opt_dia_fijo          = @w_op_dia_fijo,
      opt_evitar_feriados   = @w_op_evitar_feriados,
      opt_mes_gracia        = @w_op_mes_gracia,
      opt_base_calculo      = @w_op_base_calculo,      
      opt_recalcular_plazo  = @w_op_recalcular_plazo,
      opt_opcion_cap        = @w_op_opcion_cap,         
      opt_tasa_cap          = @w_op_tasa_cap,           
      opt_dividendo_cap     = @w_op_dividendo_cap,      
      opt_fecha_pri_cuot    = @w_op_fecha_pri_cuot,     
      opt_dia_habil         = @w_op_ult_dia_habil,      
      opt_tipo_redondeo     = @w_op_tipo_redondeo,  
      opt_convierte_tasa    = @w_op_convierte_tasa
      where opt_operacion   = @w_activa
      
      if @@error != 0 begin
         print 'no se realizo la actualizacion de la ca_operacion_tmp'
      end 



      ---select op_cuota, op_monto,op_plazo, op_tplazo, op_periodo_cap, op_periodo_int from ca_operacion

      exec @w_return      = sp_gentabla
      @i_operacionca      = @w_activa,
      @i_reajuste         = 'N',   --@w_op_reajustable, porque el gentabla pone en cero los valores de gracia cuando es reajustable
      @i_tabla_nueva      = 'S',
      @i_dias_gracia      = @w_dias_gracia,
      @i_actualiza_rubros = 'S',
      @i_crear_op     = 'S',
      @i_control_tasa     = 'S',
      @o_fecha_fin        = @w_fecha_fin out,
      @o_cuota            = @w_cuota     out,
      @o_plazo            = @w_op_plazo  out,
      @o_tplazo           = @w_op_tplazo out
      
      if @w_return != 0 begin
         select @w_error = @w_return
         goto ERROR
      end

      -- JCQ 07/08/2003 ACTUALIZACION FECHA DE DESEMBOLSO EN LA ACTIVA Y EN LA PASIVA

      -- DETERMINAR EL SECUENCIAL DE DESEMBOLSO A APLICAR (ACTIVA)
      select @w_sec_activa = min(dm_secuencial)
      from   ca_desembolso
      where  dm_operacion  = @w_activa
      and    dm_estado     = 'NA'

      -- ACTUALIZAR FECHA DE DESEMBOLSO (ACTIVA)

      update ca_desembolso
      set    dm_fecha      = @w_op_fecha_ini
      where  dm_secuencial = @w_sec_activa
      and    dm_operacion  = @w_activa


      -- DETERMINAR EL SECUENCIAL DE DESEMBOLSO A APLICAR (PASIVA)
      select @w_sec_pasiva = min(dm_secuencial)
      from   ca_desembolso
      where  dm_operacion  = @w_pasiva
      and    dm_estado     = 'NA'

      -- ACTUALIZAR FECHA DE DESEMBOLSO (PASIVA)

      update ca_desembolso
      set    dm_fecha      = @w_op_fecha_ini
      where  dm_secuencial = @w_sec_pasiva
      and    dm_operacion  = @w_pasiva

      select @i_operacion = 'S'
end


/*BUSCAR OPERACIONES ASOCIADAS */
if @i_operacion = 'S' begin  

   if @i_tipo_op = 'R'
      select 
      'LINEA CREDITO'   = op_toperacion,
      'MONEDA' = (select convert(varchar(2),mo_moneda) + '-' + convert(varchar(15),mo_descripcion) 
      from cobis..cl_moneda where mo_moneda = x.op_moneda),
      'OPERACION' = convert(varchar(15),op_banco),
      'FECHA INICIO' = convert(varchar(12),rpt_fecha_ini,101),
      'FECHA FIN   ' = convert(varchar(12),rpt_fecha_fin,101),
      'MONTO OP.' = op_monto,
      'COD.CLI'   = op_cliente,
      'CLIENTE'   = convert(varchar(30),op_nombre),
      'SALDO ACTIVA'  = rpt_saldo_act, 
      'SALDO PASIVA'  = rpt_saldo_pas, 
      'USR.CREADOR.'  = rpt_usuario_grb,
      'HORA.CREACION.'  = rpt_hora_grb,
      'HORA.MODIF.'  = rpt_hora_upd
      from ca_relacion_ptmo_tmp, ca_operacion x
      where rpt_activa = op_operacion
      and rpt_pasiva = @w_pasiva
      ---and rpt_fecha_fin is null
   else 
      select 
      'LINEA CREDITO'   = op_toperacion,
      'MONEDA' = (select convert(varchar(2),mo_moneda) + '-' + convert(varchar(15),mo_descripcion) 
      from cobis..cl_moneda where mo_moneda = x.op_moneda),
      'OPERACION' = convert(varchar(15),op_banco),
      'FECHA INICIO' = convert(varchar(12),rpt_fecha_ini,101),
      'FECHA FIN   ' = convert(varchar(12),rpt_fecha_fin,101),
      'MONTO OP.' = op_monto,
      'COD.CLI'   = op_cliente,
      'CLIENTE'   = convert(varchar(30),op_nombre),
      'SALDO ACTIVA'  = rpt_saldo_act, 
      'SALDO PASIVA'  = rpt_saldo_pas, 
      'USR.CREADOR.'  = rpt_usuario_grb, 
      'HORA.CREACION.'  = rpt_hora_grb,
      'HORA.MODIF.'  = rpt_hora_upd
      from ca_relacion_ptmo_tmp, ca_operacion x
      where rpt_activa = @w_activa
      and   rpt_pasiva = op_operacion
      ---and   rpt_fecha_fin is null

end
 
return 0

ERROR:


exec cobis..sp_cerror
@t_debug='N',         @t_file = null,
@t_from =@w_sp_name,   @i_num = @w_error
--@i_cuenta= ' '

return @w_error

go


