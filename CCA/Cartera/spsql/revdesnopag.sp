/************************************************************************/
/*      Archivo:                revdesnopag.sp                          */
/*      Stored procedure:       sp_revdesnoapag                         */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Ricardo Reyes                           */
/*      Fecha de escritura:     Marzo 2009                              */
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
/*      Reversa los desembolsos no pagados en el día desde Serv.Banc    */
/************************************************************************/  
/*                           MODIFICACIONES                             */
/*      FECHA           AUTOR             RAZON                         */
/************************************************************************/  
use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_revdesnoapag')
   drop proc sp_revdesnoapag
go

create proc sp_revdesnoapag

as declare
   @w_sp_name            varchar(30),
   @w_return             int,
   @w_error              int,
   @w_rowcount           int,
   @w_pa_cheger          varchar(10),
   @w_pa_cheotr          varchar(10),
   @w_operacion          int,
   @w_secuencial         int,
   @w_banco              cuenta,
   @w_secuencial_pag     int,
   @w_banco_pag          cuenta,
   @w_trancount          int,
   @w_commit             char(1),
   @w_fecha_cartera      datetime,
   @w_operacion_pag      int,
   @w_tramite            int,
   @w_forma_pago         varchar(20)
    
select @w_sp_name        = 'sp_revdesnoapag',
       @w_commit         = 'N'

/* Fecha de Proceso de Cartera */
select @w_fecha_cartera = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7  -- 7 pertence a Cartera

/* LECTURA DEL PARAMETRO CHEQUE DE GERENCIA */
select @w_pa_cheger = pa_char
from   cobis..cl_parametro
where  pa_producto    = 'CCA'
and    pa_nemonico    = 'CHEGER'

if @w_rowcount = 0 begin
   select @w_error = 701012 --No existe parametro cheque de gerencia
   goto ERROR
end

/* LECTURA DEL PARAMETRO CHEQUE LOCAL (Otros Bancos) */
select @w_pa_cheotr = pa_char
from   cobis..cl_parametro
where  pa_producto    = 'CCA'
and    pa_nemonico    = 'CHELOC'

if @w_rowcount = 0 begin
   select @w_error = 701012 --No existe parametro cheque de Otros Bancos
   goto ERROR
end



/* DETERMINAR LA FORMA DE PAGO DE RENOVACION */
select @w_forma_pago = pa_char 
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'FDESRE'

if @@rowcount = 0 select @w_forma_pago = 'RENOVACION'

select @w_tramite = 0

while 1 = 1 begin   

   select @w_operacion = 0, @w_secuencial = 0, @w_operacion_pag = 0
   set rowcount 1

   select @w_operacion  = dm_operacion, 
          @w_secuencial = dm_secuencial,
          @w_banco      = op_banco,
          @w_tramite    = op_tramite
   from ca_desembolso, ca_operacion
   where (dm_pagado   = 'N' or dm_pagado is null)
   and   dm_estado    = 'A'
   and   dm_producto  in (@w_pa_cheger, @w_pa_cheotr)
   and   dm_fecha     = @w_fecha_cartera
   and   dm_operacion = op_operacion
   and   op_tramite > @w_tramite
   order by op_tramite
   
   if @@rowcount = 0 begin
      set rowcount 0
      break
   end     
   
   set rowcount 0

  
   if exists  (select 1 from ca_desembolso, ca_operacion 
               where op_operacion = dm_operacion
               and   dm_operacion = @w_operacion
               and   dm_secuencial = @w_secuencial
               and   dm_producto not in (@w_pa_cheger, @w_pa_cheotr, @w_forma_pago)   
             )
      goto SIGUIENTE

   if @@trancount = 0 begin
      select @w_commit = 'S'
      BEGIN TRAN
   end   

   /* Reversa pagos por Renovacion */
   while 1=1 begin

      set rowcount 1
      select @w_secuencial_pag = 0

      select 
      @w_secuencial_pag = ab_secuencial_pag, 
      @w_banco_pag      = op_banco,
      @w_operacion_pag  = op_operacion
      from cob_cartera..ca_abono, cob_cartera..ca_abono_det, cob_credito..cr_op_renovar, cob_cartera..ca_operacion
      where ab_operacion = abd_operacion
      and   ab_secuencial_ing = abd_secuencial_ing
      and   ab_estado = 'A'
      and   abd_concepto = 'RENOVACION'
      and   or_num_operacion = op_banco
      and   or_tramite  = @w_tramite
      and   op_operacion = ab_operacion
      and   op_operacion > @w_operacion_pag
      order by op_operacion

      if @@rowcount = 0 begin
         set rowcount 0
         break
      end

      set rowcount 0

      if @w_secuencial_pag > 0 begin
         exec @w_return = sp_fecha_valor
         @s_user            = 'batch', 
         @i_banco           = @w_banco_pag,
         @i_secuencial      = @w_secuencial_pag,
         @i_operacion       = 'R',
         @i_observacion     = 'DESEMBOLSO NO PAGADO',
         @i_en_linea        = 'N'
      
         if @w_return <> 0 begin
            select @w_error = @w_return
            goto ERROR
         end
      end

   end

   begin
      exec @w_return = sp_fecha_valor 
      @s_user            = 'batch', 
      @i_banco           = @w_banco,
      @i_secuencial      = @w_secuencial,
      @i_operacion       = 'R',
      @i_observacion     = 'DESEMBOLSO NO PAGADO',
      @i_en_linea        = 'N'
      
      if @w_return <> 0 begin
         select @w_error = @w_return
         goto ERROR
      end
   end

   if @w_commit = 'S' begin
      COMMIT TRAN                                       
      select @w_commit = 'N'
   end

   goto SIGUIENTE
   
   ERROR:

   if @w_commit = 'S' begin
      ROLLBACK TRAN
      select @w_commit = 'N'
   end

   exec sp_errorlog 
   @i_fecha     = @w_fecha_cartera,
   @i_error     = @w_error,
   @i_usuario   = 'batch',
   @i_tran      = 7999,
   @i_tran_name = @w_sp_name,
   @i_cuenta    = @w_banco,
   @i_rollback  = 'S'
   
   while @@trancount > 0 rollback tran
   goto SALIR 
   
   SIGUIENTE:      
end
SALIR:
return 0

go