/************************************************************************/
/*   Archivo:             tabproc.sp                                    */
/*   Stored procedure:    sp_tabla_procesos                             */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Credito y Cartera                             */
/*   Disenado por:        Fabian Quintero                               */
/*   Fecha de escritura:  Sep. 2003                                     */
/************************************************************************/
/*                              IMPORTANTE                              */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                              PROPOSITO                               */
/*   Reailzar la insercion de procesos por rango de obligaciones por    */
/*   un tipo que identifica el proceso que se va a ejecutar             */
/************************************************************************/
/*                              CAMBIOS                                 */
/*      FECHA              AUTOR             CAMBIOS                    */
/*      FEB-2006           Elcira P.    Correccion def. 5093 BAC        */
/*                                      el maestro se carga de la       */
/*                                      table ca_operacion_total        */
/*                                      donde opt_maestro = 'I'         */
/*      FEB-2006           Elcira P.    Paralelismo pagosanudef.6036    */
/*      MAY-2007           Fabian Q.    Paralelismo hcpasivas           */
/*      ABR-2008           John J.R.    Optimizacion                    */
/*      Jun-2008           MZA          Optimizacion                    */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_tabla_procesos')
   drop proc sp_tabla_procesos
go


create proc sp_tabla_procesos
@i_nro_procesos    int,
@i_tipo            varchar(10),
@i_opcion          char(1) = 'S',  ---Para MAESTRO con S genera solo activas y con N genera Activas y Pasivas
@i_fecha_proceso   datetime = null -- ALGUNOS PROCESOS PUEDEN SELECCIONAR MEJOR CON LA FECHA
as
declare
   @w_operacion_min  int,
   @w_operacion_max  int,
   @w_operacion      int,
   @w_tamano_proceso int,
   @w_proceso        int,
   @w_total          int,
   @w_particion      int,
   @w_oper_ini       int,
   @w_oper_fin       int,
   @w_total_oper     int,
   @w_contador       int,
   @w_sqlstatus      int,
   @w_nuevo_paralelismo char,
   
   @w_fecha_trc      datetime
   
begin
   select @w_nuevo_paralelismo = 'N'
   
   select @w_operacion     = 0
   
   select @w_oper_ini   = 0,
          @w_oper_fin   = 0,
          @w_total_oper = 0,
          @w_contador   = 1,
          @w_proceso    = 0
   
   begin tran
   create table #oper (op_operacion  int)
   while @@trancount > 0 commit
   
   BEGIN TRAN
   
   delete ca_paralelo_tmp
   where  programa = @i_tipo
   
   while @@trancount > 0 commit
   
   if @i_tipo = 'castimas'
   begin
      select @w_nuevo_paralelismo = 'S'
      
      insert into #oper
      select op_operacion
      from   ca_operacion, ca_castigo_masivo
      where  cm_estado = 'I'
      and    op_banco = cm_banco
      and    op_estado    != 4
      order  by op_operacion
      
      select @w_total_oper = @@rowcount
   end
   
   if @i_tipo = 'maestro'
   begin
      select @w_nuevo_paralelismo = 'S'
      
      if @i_opcion = 'N'
         insert into #oper
         select op_operacion
         from   ca_operacion
         where  op_estado    != 99
         and   (op_validacion is null or op_validacion not like '%M%')
         order  by op_operacion
      else
         insert into #oper
         select op_operacion
         from   ca_operacion
         where  op_estado    != 99
         and   (op_validacion is null or op_validacion not like '%M%')
         and    op_tipo != 'R'
         order  by op_operacion
      
      select @w_total_oper = @@rowcount
   end
   
   if @i_tipo = 'caconta'
   begin
      select @w_nuevo_paralelismo = 'S'

      if @i_opcion = 'N'
      begin      
         insert into #oper
         select distinct tr_operacion
         from   cob_cartera..ca_transaccion --(index ca_transaccion_4)
         where  tr_fecha_mov  <= @i_fecha_proceso
         and    tr_estado    = 'ING'
         and    tr_tran  not in ('PRV','CMO')
         order  by tr_operacion
         
         select @w_total_oper = @@rowcount
      end
      
      if @i_opcion = 'S'
      begin      
         insert into #oper
         select distinct tr_operacion
         from   cob_cartera..ca_transaccion --(index ca_transaccion_4)
         where  tr_fecha_mov  <= @i_fecha_proceso
         and    tr_estado    = 'ING'
         order  by tr_operacion
         
         select @w_total_oper = @@rowcount
      end
      
      if @i_opcion = 'T'
      begin      
         set rowcount 1
         select @w_fecha_trc = do_fecha
         from   cob_credito..cr_dato_operacion
         where  do_tipo_reg = 'M'
         and    do_codigo_producto = 7

         set rowcount 0       
         insert into #oper
         select op_operacion = cc_operacion
         from   cob_cartera..ca_cambio_calificacion --(index ca_cambio_calificacion_1)
         where  cc_fecha = @w_fecha_trc
	 order by cc_operacion         

         select @w_total_oper = 1
      end
   end
   
   -- saldoshc
   if @i_tipo = 'saldoshc'
   begin
      select @w_nuevo_paralelismo = 'S'
      if exists(select 1
                from ca_saldos_cartera)
      begin
         insert into #oper
         select op_operacion
         from   ca_operacion a
         where  not exists (select 1 from ca_saldos_cartera
                 where sc_operacion = a.op_operacion)
         and    op_estado in (1, 2, 4, 9, 10)
         order by op_operacion
      end
      ELSE
      begin
         insert into #oper
         select op_operacion
         from   ca_operacion a
         where  op_estado in (1, 2, 4, 9, 10)
         order  by op_operacion
      end
            
      select @w_total_oper = @@rowcount
   end
   
   -- cacontac
   if @i_tipo = 'cacontac'
   begin
      select @w_nuevo_paralelismo = 'S'
      
      insert into #oper
      select distinct sc_operacion
      from   cob_cartera..ca_saldos_cartera
      order  by sc_operacion
      
      select @w_total_oper = @@rowcount
   end
   
   -- actatx
   if @i_tipo = 'actatx'
   begin
      select @w_nuevo_paralelismo = 'S'
      
      insert into #oper
      select op_operacion
      from   cob_cartera..ca_operacion
      where  op_estado   in (1, 2, 4, 9, 10)
      and    isnull(op_pago_caja, 'S') = 'S'
      and    op_naturaleza  = 'A' -- ACTIVAS
      order  by op_operacion
      
      select @w_total_oper = @@rowcount
   end
   
   -- datconso
   if @i_tipo = 'datconso'
   begin
      select @w_nuevo_paralelismo = 'S'
      
      if @i_fecha_proceso is null
      begin
         select @i_fecha_proceso = fc_fecha_cierre
         from   cobis..ba_fecha_cierre
         where  fc_producto = 7
      end
      
      -- SELECCION DE LOS REGISTROS A DISTRIBUIR EN PROCESOS
      insert into #oper
      select op_operacion
      from   ca_operacion o
      where (op_estado in (1, 2,4, 9, 10)
             or (    op_estado in (3, 6)
                  and substring(convert(varchar, @i_fecha_proceso, 111), 1, 7) = substring(convert(varchar, isnull(op_fecha_ult_mov, op_fecha_ult_proceso), 111), 1, 7)
                 )
             )
      and    op_naturaleza = 'A'
      and    not exists(select 1
                        from   cob_credito..cr_tmp_datooper
                        where  dot_codigo_producto = 7
                        and    dot_numero_operacion_banco = o.op_banco
                        and    (dot_saldo_cap > 0  and dot_estado_cartera in (1, 2, 9, 4, 10) or dot_estado_cartera = 3)
                       )
      and    (op_estado = 3
              or exists(select 1
                    from   ca_saldos_cartera
                    where  sc_operacion = o.op_operacion
                    and    sc_perfil    = 'BOC_OA')   -- ESTE PERFIL ES PARA LAS OBLIGACIONES ACTIVAS
             )
      order  by op_operacion
      
      select @w_total_oper = @@rowcount
   end
   
   -- abonotot
   if @i_tipo = 'abonotot'
   begin
      select @w_nuevo_paralelismo = 'S'
      
      insert into #oper
      select distinct ab_operacion  
      from   ca_abono,ca_operacion
      where  ab_fecha_ing  <= @i_fecha_proceso
      and    ab_estado     in ('ING', 'P', 'NA')
      and    op_operacion = ab_operacion
      and    op_estado     in (select es_codigo from ca_estado where es_acepta_pago = 'S')
      order  by ab_operacion
      
      select @w_total_oper = @@rowcount
   end
   
   -- findia
   if @i_tipo = 'findia'
   begin
      select @w_nuevo_paralelismo = 'S'
      
      insert into #oper
      select op_operacion
      from   ca_operacion, ca_estado
      where  es_procesa = 'S'
      and    op_estado  = es_codigo
      and    op_fecha_ult_proceso <= @i_fecha_proceso
      and   (op_validacion = null or op_validacion in ('TRC','RES'))
      order  by op_operacion
      
      select @w_total_oper = @@rowcount
   end
   
   -- CREACION DE LOS REGISTROS DEL NUEVO PARALELISMO
   if @w_nuevo_paralelismo = 'S'
   begin
      while @@trancount > 0  rollback
      
      if @w_total_oper >= 10
      begin
         select @w_total_oper = (@w_total_oper / @i_nro_procesos) + 1
         
         -- EL NUMERO MINIMO DE OBLIGACIONES EN CADA PROCESO
         if @w_total_oper < 5
            select @w_total_oper = 5
      end
      else
         select @w_total_oper = 1
      
      declare
         cur_oper cursor
         for select op_operacion
             from   #oper
             order  by op_operacion
             for read only
      
      open cur_oper
      
      fetch cur_oper
      into  @w_oper_ini
      
      select @w_sqlstatus = @@fetch_status
      
      select @w_oper_fin = @w_oper_ini,
             @w_contador = 1
      
      while (@w_sqlstatus not in(1,2))
      begin
         --
         if @w_contador = @w_total_oper
         begin
            select @w_proceso = @w_proceso + 1
            
            begin tran
            
            insert into ca_paralelo_tmp
                  (programa, proceso,    estado, operacion_ini, operacion_fin)
            values(@i_tipo,  @w_proceso, 'C',    @w_oper_ini,   @w_oper_fin)
            
            commit
            
            select @w_contador = 0
         end
         --
         fetch cur_oper
         into  @w_oper_fin
         
         select @w_sqlstatus = @@fetch_status
         
         if @w_contador = 0 -- PUDO LEER
            select  @w_oper_ini = @w_oper_fin
         
         if @w_sqlstatus = 0 -- PUDO LEER
            select @w_contador = @w_contador + 1
      end
      
      select @w_proceso = @w_proceso + 1
      
      begin tran
      
      insert into ca_paralelo_tmp
            (programa, proceso,    estado, operacion_ini, operacion_fin)
      select @i_tipo,  @w_proceso, 'C',    @w_oper_ini,   @w_oper_fin
      where  @w_oper_ini < @w_oper_fin and @w_contador > 0
      
      commit
      
      close cur_oper
      deallocate cur_oper
      
      return 0
   end
   -- FIN NUEVO PARALELISMO
   
   -- RUTINAS DE METODO VIEJO
   
   if @i_tipo = 'BUSERROR'
   begin
      truncate table ca_procesos_buserror_tmp

      select @w_operacion_min = min(op_operacion),
             @w_operacion_max = max(op_operacion),
             @w_total         = count(1)
      from   ca_operacion
      where  op_estado not in (0,99) 
   end
   
   if @w_operacion_min is null or @w_operacion_max is null
      return 0
   
   select @w_tamano_proceso = (@w_total / @i_nro_procesos) + 1
   
   if @w_tamano_proceso < 1
      select @w_tamano_proceso = 1
   
   select @w_particion      = @w_tamano_proceso
   
   select @w_proceso = 1
   
   BEGIN TRAN
   /*
   while @w_proceso < @i_nro_procesos and @w_operacion_min < @w_operacion_max
   begin
      if @i_tipo = 'BUSERROR'
      begin
         set rowcount @w_particion
         
         select @w_operacion = op_operacion
         from   ca_operacion
         where  op_estado not in (0, 99)
         order by op_operacion
         
         set rowcount 0
      end
      
      if @i_tipo = 'BUSERROR'
      begin
         insert into ca_procesos_buserror_tmp
               (proceso,    estado, operacion_ini,    operacion_fin)
         values(@w_proceso, 'C',    @w_operacion_min, @w_operacion)
      end

      select @w_particion      = @w_particion + @w_tamano_proceso
      select @w_operacion_min = @w_operacion + 1
      select @w_proceso = @w_proceso + 1
   end
   
   if @i_tipo = 'BUSERROR'
   begin
      insert into ca_procesos_buserror_tmp
            (proceso,    estado, operacion_ini,    operacion_fin)
      values(@w_proceso, 'C',    @w_operacion_min, @w_operacion_max)
   end
   */
   COMMIT TRAN
end
return 0

go


