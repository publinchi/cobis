/************************************************************************/
/*   Archivo:              abonotot.sp                                  */
/*   Stored procedure:     sp_abonos_total                              */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Credito y Cartera                            */
/*   Disenado por:         Elcira Pelaez                                */
/*   Fecha de escritura:   Oct 2001                                     */
/************************************************************************/
/*                                  IMPORTANTE                          */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                                   PROPOSITO                          */
/*   Procedimiento que realiza la Aplicacion de Abonos Automaticos      */
/*   correspondientes a la fecha de proceso                             */
/*   Depuración proceso batch                                           */
/*                          MODIFICACIONES                              */
/*      FECHA                AUTOR                    RAZON             */
/*      07/31/2003     Julio C Quintero   Fecha Efectiva a Abonos       */
/*                                        Masivos de Convivencia        */
/*      05/11/2005     ELcira Pelaez      EPB:11MAY2005                 */
/*     ABR-2006        Elcira Pelaez      NR.  296                      */
/*     MAR-2006        Elcira Pelaez      DEF-7998                      */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_abonos_total')
   drop proc sp_abonos_total
go

create proc sp_abonos_total
   @s_sesn           int      = NULL,
   @s_user           login    = NULL,
   @s_term           varchar(30),
   @s_date           datetime,
   @s_ofi            smallint,
   @i_fecha_proceso  datetime,
   @i_en_linea       char(1)  = 'N',
   @i_proceso        int      = null


as

declare 
   @w_error              int,
   @w_sp_name            descripcion,
   @w_ab_secuencial_ing  int,
   @w_ab_dias_retencion  int,
   @w_ab_estado          catalogo,
   @w_abd_concepto       catalogo,
   @w_op_operacion       int, 
   @w_op_banco           cuenta,
   @w_cp_categoria       catalogo,
   @w_ab_fecha_ing       datetime,
   @w_abd_beneficiario   varchar(50),
   @w_fecha_ult_proceso  datetime,
   @w_abd_cotizacion_mpg money,
   @w_ab_fecha_pag       datetime,
   @w_descripcion        descripcion,
   @w_ms                 datetime,
   @w_ms_abo             datetime,
   @w_tipo               char(1),
   @w_oficina            smallint,
   @w_ab_fecha_fv        datetime,
   @w_ciudad_nal         int,
   @w_monto_mn           money,
   @w_estado_op          int,
   @w_procesa            char(1),

-- VARIABLES PROCESO PARALELISMO
   @p_operacion_ini  int, 
   @p_operacion_fin  int, 
   @p_proceso        int, 
   @p_programa       catalogo,
   @p_total_oper     int, 
   @p_estado         char(1), 
   @p_ult_update     datetime,
   @p_cont_operacion int, 
   @p_tiempo_update  int 
 
select @p_programa      = 'abonotot',
       @p_proceso       = @i_proceso,
       @p_ult_update    = getdate(),
       @p_tiempo_update = 15


if @p_proceso is not null
begin
   select @p_operacion_ini  = operacion_ini,
          @p_operacion_fin  = operacion_fin,
          @p_estado         = estado,
          @p_cont_operacion = isnull(procesados, @p_operacion_fin - @p_operacion_ini)
   from   ca_paralelo_tmp
   where  programa = @p_programa
   and    proceso  = @p_proceso
end

select @w_ciudad_nal = pa_int
from   cobis..cl_parametro
where  pa_nemonico = 'CIUN'
and    pa_producto = 'ADM'
set transaction isolation level read uncommitted


select ab_secuencial_ing, ab_dias_retencion,    ab_estado,
       op_operacion,      op_banco,             ab_fecha_ing,
       ab_fecha_pag,      op_fecha_ult_proceso, ab_cuota_completa,
       ab_oficina
into   #pagos
from   ca_abono, ca_operacion
where  ab_operacion   = op_operacion
and    1=2

-- CARGADO DE VARIABLES DE TRABAJO
select @w_sp_name = 'sp_abonos_total'

-- SELECCIONAR LOS REGISTROS A PROCESAR
if @p_proceso is not null
begin
   insert into #pagos
   select ab_secuencial_ing, ab_dias_retencion,    ab_estado,
          op_operacion,      op_banco,             ab_fecha_ing,
          ab_fecha_pag,      op_fecha_ult_proceso, ab_cuota_completa,
          ab_oficina
   from   ca_abono, ca_operacion
   where  ab_operacion between @p_operacion_ini and @p_operacion_fin
   and    ab_operacion   = op_operacion
   and    ab_fecha_ing  <= @i_fecha_proceso
   and    ab_estado     in ('ING', 'P', 'NA')
   and    op_estado     in (select es_codigo from ca_estado where es_acepta_pago = 'S')
   order  by ab_operacion, ab_fecha_pag, ab_cuota_completa
end
ELSE  --SIN PARALELISMO
begin
   select @p_estado = 'P'
   insert into #pagos
   select ab_secuencial_ing, ab_dias_retencion,    ab_estado,
          op_operacion,      op_banco,             ab_fecha_ing,
          ab_fecha_pag,      op_fecha_ult_proceso, ab_cuota_completa,
          ab_oficina
   from   ca_abono, ca_operacion
   where  ab_operacion   = op_operacion
   and    ab_fecha_ing  <= @i_fecha_proceso
   and    ab_estado     in ('ING', 'P', 'NA')
   and    op_estado     in (select es_codigo from ca_estado 
                            where es_acepta_pago = 'S')
   order  by ab_operacion, ab_fecha_pag, ab_cuota_completa
end

select @p_cont_operacion = @@rowcount

-- CURSOR PARA LEER ABONOS
if @p_proceso is not null 
begin
   begin tran
   
   update ca_paralelo_tmp
   set    estado     = 'P',
          spid       = @@spid,
          hora       = getdate(),
          hostprocess = master..sysprocesses.hostprocess,
          procesados  = @p_cont_operacion
   from   master..sysprocesses
   where  programa = @p_programa
   and    proceso  = @p_proceso
   and    master..sysprocesses.spid = @@spid
   
   commit
end

declare
   cursor_abonos cursor
   for select ab_secuencial_ing, ab_dias_retencion,    ab_estado,
              op_operacion,      op_banco,             ab_fecha_ing,
              ab_fecha_pag,      op_fecha_ult_proceso, ab_oficina
       from   #pagos
       order by op_operacion, ab_secuencial_ing, ab_cuota_completa
       for read only

open cursor_abonos
fetch cursor_abonos
into  @w_ab_secuencial_ing, @w_ab_dias_retencion,   @w_ab_estado,
      @w_op_operacion,      @w_op_banco,            @w_ab_fecha_ing,
      @w_ab_fecha_pag,      @w_fecha_ult_proceso,   @w_oficina

while  (@@fetch_status = 0 and (@p_estado = 'P') )-- WHILE CURSOR PRINCIPAL
begin
   while @@trancount>0 rollback tran
   
   if (@@fetch_status = -1)
   begin
      select @w_error  = 708999
      goto ERROR
   end
   
   if @p_proceso is not null
   begin
      -- ACTUALIZAR EL NUMERO DE REGISTROS PROCESADOS
      select @p_cont_operacion = @p_cont_operacion - 1
      
      -- ACTUALIZAR EL PROCESO CADA MINUTO
      if datediff(ss, @p_ult_update, getdate()) > @p_tiempo_update
      begin
         select @p_ult_update = getdate()
         begin tran
         
         update ca_paralelo_tmp
         set    hora   = getdate(),
                procesados = @p_cont_operacion
         where  programa = @p_programa
         and    proceso = @p_proceso
         
         -- AVERIGUAR EL ESTADO DEL PROCESO
         select @p_estado = estado
         from   ca_paralelo_tmp
         where  programa = @p_programa
         and    proceso = @p_proceso
         
         commit
      end
   end
   
   select @w_error = 0
   
   -- VALIDAR SI ES NOTA DE DEBITO
   select @w_abd_concepto        = abd_concepto,
          @w_abd_beneficiario    = abd_beneficiario,
          @w_abd_cotizacion_mpg  = abd_cotizacion_mpg,
          @w_monto_mn            = abd_monto_mn
   from   ca_abono_det
   where  abd_operacion      = @w_op_operacion
   and    abd_secuencial_ing = @w_ab_secuencial_ing
   and    abd_tipo           = 'PAG' 
   
   select @w_cp_categoria = cp_categoria 
   from   ca_producto
   where  cp_producto = @w_abd_concepto 
   
   if @@rowcount = 0
   begin
      select @w_error =  701119 
      goto ERROR
   end
   
   if @w_cp_categoria in ('NDAH','NDCC') or @w_monto_mn <= 0
      goto SIGUIENTE
   
   if @w_ab_dias_retencion <= 0
   begin
      select @w_fecha_ult_proceso = op_fecha_ult_proceso,
             @w_tipo              = op_tipo,
             @w_estado_op         = op_estado
      from   ca_operacion
      where  op_banco = @w_op_banco
      
      exec sp_dia_habil
           @i_fecha    = @w_ab_fecha_pag,
           @i_ciudad   = @w_ciudad_nal,
           @o_fecha    = @w_ab_fecha_pag out
      
      --SI EL ESTADO DE LA OBLIGACION NO PROCESA NO DEBE HACER FECHA VALOR, SOLO
      --APLICAR EL PAGO A LA FECHA QUE ESTE
      select @w_procesa = 'S'
      
      select @w_procesa = es_procesa
      from ca_estado
      where es_codigo = @w_estado_op
      
      if @w_fecha_ult_proceso <> @w_ab_fecha_pag  and  @w_tipo not in ('O') and  @w_procesa = 'S'
      begin
         ---EPB:11MAY2005RECUPERAR HISTORIAS PARA EFECTOS DE FECHA VALOR
         exec  sp_restaurar
	      @i_banco		= @w_op_banco,
	      @i_en_linea  = 'N'
	
         exec @w_error = sp_fecha_valor
              @s_date              = @s_date,
              @s_lsrv	     	     = 'CONSOLA',
              @s_ofi               = @s_ofi,
              @s_rol		           = 0,
              @s_sesn              = @s_sesn,
              @s_ssn               = 10,
              @s_term              = @s_term,
              @s_user              = @s_user,
              @i_fecha_valor       = @w_ab_fecha_pag, 
              @i_banco             = @w_op_banco,
              @i_operacion         = 'F',
              @i_en_linea          = 'N',
              @i_con_abonos        = 'N'
         
         if @w_error != 0
         begin
            goto ERROR
         end
         
         if exists (select 1 from ca_abono
                     where ab_operacion = @w_op_operacion
                     and ab_secuencial_ing = @w_ab_secuencial_ing
                     and ab_estado = 'A')
            goto SIGUIENTE
         
         select @w_fecha_ult_proceso = op_fecha_ult_proceso
         from   ca_operacion
         where  op_banco = @w_op_banco

         if @w_ab_fecha_pag <> @w_fecha_ult_proceso
         begin 
            select @w_error = 710069
            goto ERROR
         end
      end
   end

   begin tran
   
   if exists (select 1 from ca_abono
                     where ab_operacion = @w_op_operacion
                     and ab_secuencial_ing = @w_ab_secuencial_ing
                     and ab_estado in('ING', 'P')
   and  @w_ab_dias_retencion <= 0)  --- NR 296
   begin
      exec @w_error =  sp_registro_abono -- RPA
           @s_user           = @s_user,
           @s_term           = @s_term,
           @s_date           = @s_date,
           @s_ofi            = @w_oficina,
           @i_secuencial_ing = @w_ab_secuencial_ing,
           @i_en_linea       = 'N',
           @i_operacionca    = @w_op_operacion,
           @i_fecha_proceso  = @i_fecha_proceso,
           @i_cotizacion     = @w_abd_cotizacion_mpg
           
      
      if @w_error != 0
      begin
         goto ERROR
      end
   end
   
   -- APLICACION DEL PAGO
   if @w_ab_dias_retencion <= 0
   and exists (select 1 from ca_abono
                     where ab_operacion = @w_op_operacion
                     and ab_secuencial_ing = @w_ab_secuencial_ing
                     and ab_estado in ('ING', 'P', 'NA') )
   begin
      exec @w_error = sp_cartera_abono
           @s_sesn           = @s_sesn,
           @s_user           = @s_user,
           @s_term           = @s_term,
           @s_date           = @s_date,
           @s_ofi            = @w_oficina,
           @i_secuencial_ing = @w_ab_secuencial_ing,
           @i_en_linea       = 'N',
           @i_operacionca    = @w_op_operacion,
           @i_fecha_proceso  = @w_ab_fecha_pag,  ---@i_fecha_proceso,
           @i_cotizacion     = @w_abd_cotizacion_mpg
      
      if @w_error != 0
      begin
         goto ERROR
      end 
   end
   
   
   COMMIT TRAN     ---Fin de la transaccion 
   
   goto SIGUIENTE
   
   ERROR:
   if @w_error <> 0
   begin
      exec sp_errorlog 
           @i_fecha      = @s_date,
           @i_error      = @w_error, 
           @i_usuario    = @s_user,
           @i_tran       = 7999,
           @i_tran_name  = @w_sp_name,
           @i_cuenta     = @w_op_banco,
           @i_rollback   = 'S'
      
      while @@trancount > 0 rollback
   end
   
   SIGUIENTE:
   fetch cursor_abonos
   into  @w_ab_secuencial_ing, @w_ab_dias_retencion, @w_ab_estado,
         @w_op_operacion,      @w_op_banco,          @w_ab_fecha_ing,
         @w_ab_fecha_pag,      @w_fecha_ult_proceso, @w_oficina
end -- WHILE CURSOR RUBROS

close cursor_abonos
deallocate cursor_abonos

if @p_proceso is not null
begin
    begin tran
      
    update ca_paralelo_tmp
    set    estado = 'T',
           procesados = @p_cont_operacion
    where  programa = @p_programa
    and    proceso = @p_proceso
      
    commit
end

return 0

go
