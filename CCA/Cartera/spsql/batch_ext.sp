/************************************************************************/
/*      Archivo:                batch_ext.sp                            */
/*      Stored procedure:       sp_batch_extractos                      */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Johan Ardila                            */
/*      Fecha de escritura:     Ene 2011                                */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Carga Archivo de Paramteros                                     */
/*      Genera informacion de extractos                                 */
/*      Genera Archivo Plano                                            */
/************************************************************************/
use cob_cartera
go

set ansi_warnings off
go

if object_id ('sp_batch_extractos') is not null
   drop proc sp_batch_extractos
go

create proc sp_batch_extractos   
as

declare 
   @w_sp_name            varchar(32),
   @w_error              int,
   @w_est_vigente        tinyint,
   @w_est_novigente      tinyint,
   @w_est_cancelado      tinyint,
   @w_est_credito        tinyint,
   @w_est_vencido        tinyint,
   @w_file               varchar(20),
   @w_fecha_proceso      datetime,
   @w_path_s_app         varchar(100),
   @w_s_app              varchar(250),
   @w_sqr                varchar(100),
   @w_cmd                varchar(250),
   @w_bd                 varchar(30),
   @w_tabla              varchar(50),
   @w_path               varchar(250),
   @w_fuente             varchar(200),
   @w_comando            varchar(500),
   @w_errores            varchar(255),
   @w_destino            varchar(255),
   @w_tipo_pro           char(1),
   @w_corte              int,
   @w_banca              catalogo,         
   @w_ciudad             int,
   @w_oficina            int,
   @w_banco              cuenta,
   @w_fecha_desde        datetime,
   @w_fecha_hasta        datetime,
   @w_mensaje            varchar(255),
   @w_fecha_carga        datetime,
   @w_tipo_proceso       char(1),
   @w_dia_desde          int,
   @w_dia_hasta          int,
   @w_form_fecha         int,
   @w_op_operacion       int,
   @w_fecha_ven          datetime,
   @w_vlr_proximo        money,
   @w_fecha_pago         varchar(10),
   @w_ind                char(1),
   @w_proy               char(1),
   @w_saldo              money

/**********************************/
--  Carga Archivo de Parámetros  --
/**********************************/
select @w_form_fecha = 103,  --dd/mm/yyyy
       @w_ind        = 'S'

select @w_fecha_proceso = fc_fecha_cierre 
  from cobis..ba_fecha_cierre
 where fc_producto = 7

---------------------------
/* Variables para el BCP */
---------------------------
select @w_path_s_app = pa_char
  from cobis..cl_parametro
 where pa_nemonico = 'S_APP'

select
   @w_sqr   = 'cob_cartera..sp_batch_extractos',
   @w_file  = 'archivo_extracto',
   @w_s_app = @w_path_s_app + 's_app',   
   @w_bd    = 'cob_cartera',
   @w_tabla = 'ca_carga_extractos_aux'   

select @w_path = rtrim(ltrim(ba_path_destino))
  from cobis..ba_batch
 where ba_arch_fuente = @w_sqr

select @w_cmd = @w_s_app + ' bcp -auto -login '

/* cargar archivo plano con parametros de ejecucion -- Archivo entregado por el banco */
truncate table ca_carga_extractos_aux

select @w_fuente  = @w_path + @w_file + '.txt',
       @w_errores = @w_path + @w_file + '.err'

select @w_comando = @w_cmd + @w_bd + '..' + @w_tabla + ' in ' + @w_fuente + 
                    ' -b5000 -c -t'' + char(167) + '' -e '+ @w_errores + ' -config ' + @w_s_app + '.ini'
                    
exec @w_error = xp_cmdshell @w_comando

if @w_error <> 0 
begin
   print 'Error Carga Archivo Parametros Revisar Estructura y Ubicacion'
   print @w_comando 
   return @w_error
end

-- Lectura de Datos Cargados del Archivo
select @w_corte        = cex_corte,
       @w_banca        = cex_banca,
       @w_ciudad       = cex_ciudad,
       @w_oficina      = cex_oficina,
       @w_banco        = cex_banco,
       @w_fecha_desde  = cex_fecha_desde,
       @w_fecha_hasta  = cex_fecha_hasta,
       @w_mensaje      = cex_mensaje,
       @w_tipo_proceso = cex_tipo_proceso
  from ca_carga_extractos_aux 
 
if @w_corte is null 
begin
   print 'Error Carga Archivo Parametros - Corte sin dato'       
   select @w_ind = 'N'
   goto ERR_ARCHIVO
end

if @w_fecha_desde is null or @w_fecha_hasta is null
begin
   print 'Error Carga Archivo Parametros - Fechas de Rangos sin datos'
   select @w_ind = 'N'
   goto ERR_ARCHIVO
end

if @w_tipo_proceso is null or @w_tipo_proceso not in ('G','P')
begin
   print 'Error Carga Archivo Parametros - Tipo de Proceso incorrecto'
   select @w_ind = 'N'
   goto ERR_ARCHIVO
end
 
if @w_fecha_desde < @w_fecha_proceso
begin
   print 'Error Carga Archivo Parametros - Fecha Desde Menor a la de Proceso'       
   select @w_ind = 'N'
   goto ERR_ARCHIVO
end

if @w_fecha_desde > @w_fecha_hasta
begin
   print 'Error Carga Archivo Parametros - Fecha Desde Mayor a Fecha Hasta'       
   select @w_ind = 'N'
   goto ERR_ARCHIVO
end

ERR_ARCHIVO:

select @w_fecha_carga = @w_fecha_proceso
select @w_fecha_carga = dateadd(hh, datepart(hh,getdate()), @w_fecha_carga)
select @w_fecha_carga = dateadd(mi, datepart(mi,getdate()), @w_fecha_carga)
select @w_fecha_carga = dateadd(ss, datepart(ss,getdate()), @w_fecha_carga)

insert into ca_carga_extractos
values
   (@w_corte,         @w_banca,        @w_ciudad,
    @w_oficina,       @w_banco,        @w_fecha_desde,
    @w_fecha_hasta,   @w_mensaje,      @w_fecha_carga,
    @w_tipo_proceso,  @w_ind)

if @w_ind = 'N'
begin
   return 1
end    

/***********************************/
---   Generacion de Informacion   --- 
/***************************-*******/
if @w_tipo_proceso = 'G'
begin
   /* ESTADOS DE CARTERA */
   exec @w_error = sp_estados_cca
      @o_est_novigente = @w_est_novigente out,
      @o_est_vigente   = @w_est_vigente   out,
      @o_est_vencido   = @w_est_vencido   out,
      @o_est_cancelado = @w_est_cancelado out,      
      @o_est_credito   = @w_est_credito   out
      
   if @w_error <> 0
   begin
      print 'Error ejecucion sp_estados_cca'
      return @w_error
   end

   select @w_dia_desde = datepart(dd,@w_fecha_desde),
          @w_dia_hasta = datepart(dd,@w_fecha_hasta)                   
          
   /* Operaciones Vigentes */
   select op_banco,      op_operacion,  op_cliente,
          op_clase,      op_monto,      op_toperacion,
          op_fecha_ini,  op_fecha_fin,  op_ciudad,
          op_tdividendo, op_oficina,    fecha_ven = di_fecha_ven,  
          fecha_pago = convert(varchar(10),di_fecha_ven,@w_form_fecha),
          (select ro_referencial from ca_rubro_op with(index = ca_rubro_op_1)
            where ro_operacion  = O.op_operacion
              and ro_tipo_rubro = 'I') + op_clase tasa_aplicada,
          fecha_tasa_apl = cast(null as datetime),
          exp_tasa_apl = cast(null as char(2)),
          'TMM' + op_clase tasa_maxmora,          
          (select max(vr_fecha_vig) from ca_valor_referencial
           where vr_tipo = 'TMM' + O.op_clase)  fecha_tasa_maxmora,
          'TLU' + op_clase tasa_maxusura,
          (select max(vr_fecha_vig) from ca_valor_referencial
           where vr_tipo = 'TLU' + O.op_clase) fecha_tasa_maxusura,
          vlr_proximo = cast(0.00 as money),
          vlr_saldo   = cast(0.00 as money),
          op_banca
     into #dat_op
     from ca_operacion O with(index = ca_operacion_1), ca_dividendo with(index = ca_dividendo_1)
    where di_fecha_ven >= @w_fecha_desde
      and di_fecha_ven <= @w_fecha_hasta      
      and op_estado     = @w_est_vigente
      and di_estado     = @w_est_vigente
      and di_operacion  = op_operacion
      and op_ciudad     = isnull(@w_ciudad, op_ciudad)
      and op_oficina    = isnull(@w_oficina, op_oficina)
      and op_banco      = isnull(@w_banco, op_banco)
      and op_banca      = isnull(@w_banca, op_banca)
      
   if @@error <> 0
   begin
      print 'Error Insertando en #dat_op'
      return 1
   end
      
   create index ix_1 on #dat_op (op_operacion)
    
   /* Operaciones que no están No Vigentes,  */
   /* Vigentes Cancelado o en Credito        */
   insert into #dat_op   
   select op_banco,      op_operacion,  op_cliente,
          op_clase,      op_monto,      op_toperacion,
          op_fecha_ini,  op_fecha_fin,  op_ciudad,
          op_tdividendo, op_oficina,    di_fecha_ven, 
          'INMEDIATO',
          (select ro_referencial from ca_rubro_op with(index = ca_rubro_op_1)
            where ro_operacion  = O.op_operacion
              and ro_tipo_rubro = 'I') + op_clase,
          null,          null,
          'TMM' + op_clase tasa_maxmora,
          (select max(vr_fecha_vig) from ca_valor_referencial
            where vr_tipo = 'TMM' + O.op_clase),
          'TLU' + op_clase,
          (select max(vr_fecha_vig) from ca_valor_referencial
            where vr_tipo = 'TLU' + O.op_clase),
          0.00,           0.00,
          op_banca
     from ca_operacion O with(index = ca_operacion_1), ca_dividendo with(index = ca_dividendo_1)
    where op_dia_fijo   >= @w_dia_desde
      and op_dia_fijo   <= @w_dia_hasta      
      and op_estado not in (@w_est_novigente, @w_est_vigente, @w_est_cancelado, @w_est_credito)
      and di_operacion   = op_operacion
      and op_ciudad      = isnull(@w_ciudad, op_ciudad)
      and op_oficina     = isnull(@w_oficina, op_oficina)
      and op_banco       = isnull(@w_banco, op_banco)
      and op_banca       = isnull(@w_banca, op_banca)
      and di_dividendo   = (select max(di_dividendo) from ca_dividendo
                             where di_operacion = O.op_operacion
                               and di_estado   in (@w_est_vencido,@w_est_vigente))
                               
   if @@error <> 0
   begin
      print 'Error Insertando en #dat_op. 2'
      return 1
   end

   /* Actualizar Fecha de Tasa Aplicada */
   update #dat_op set
      fecha_tasa_apl = (select max(vr_fecha_vig) from ca_valor_referencial
                         where vr_tipo = substring(D.tasa_aplicada,1,10)),
      exp_tasa_apl   = op_tdividendo + (select tv_modalidad from ca_tasa_valor 
                                         where tv_nombre_tasa = substring(D.tasa_aplicada,1,10))
     from #dat_op D

   if @@error <> 0
   begin
      print 'Error Actualizando en #dat_op'
      return 1
   end
            
   select @w_op_operacion = 0
   /* Recorrer todas las operaciones para */
   /* conocer el valor proximo a pagar    */
   while 1=1
   begin
      select @w_saldo       = 0,
             @w_vlr_proximo = 0
             
      select top 1
             @w_op_operacion = op_operacion,
             @w_banco        = op_banco,
             @w_fecha_ven    = fecha_ven,
             @w_fecha_pago   = fecha_pago             
        from #dat_op
       where op_operacion > @w_op_operacion
       order by op_operacion
       
      if @@rowcount = 0
      begin
         break
      end
      
      select @w_proy = 'S'
      
      if @w_fecha_pago = 'INMEDIATO'
      begin
         select @w_proy = 'N'
      end
      
      select @w_fecha_ven = dateadd(day, -1, @w_fecha_ven)
             
      exec @w_error = sp_proyeccion_cuota
         @i_banco      = @w_banco,
         @i_fecha      = @w_fecha_ven,
         @i_dias_vence = 1,
         @i_extracto   = 'S',
         @i_proy       = @w_proy,
         @o_saldo      = @w_saldo        out,
         @o_saldo_prox = @w_vlr_proximo  out
         
      if @w_error <> 0
      begin
         print 'Error al ejecutar sp_proyeccion_cuota Op: ' + @w_banco
         return @w_error
      end      

      update #dat_op set
         vlr_proximo = @w_vlr_proximo,
         vlr_saldo   = @w_saldo
       where op_operacion = @w_op_operacion
       
      if @@error <> 0
      begin
         print 'Error al actualizar #dat_op Op: ' + @w_banco
         return 1
      end       
   end  -- while 1=1
   
   -- Datos de Extracto a tabla definitiva
   delete ca_extracto_linea_bat
    where el_corte = @w_corte   
     
   insert into ca_extracto_linea_bat
   select @w_fecha_proceso,     @w_corte,      @w_fecha_desde,
          @w_fecha_hasta,       op_cliente,
          (select top 1 di_descripcion from cobis..cl_direccion
            where di_ente      = D.op_cliente
              and di_principal = 'S'),
          (select top 1 di_ciudad from cobis..cl_direccion
            where di_ente      = D.op_cliente
              and di_principal = 'S'),
          op_banco,             op_oficina,    op_fecha_ini,
          op_fecha_fin,         op_monto,
          (select ro_fpago from ca_rubro_op with(index = ca_rubro_op_1)
            where ro_operacion  = D.op_operacion
              and ro_tipo_rubro = 'I'),
          op_toperacion,
          (select ro_porcentaje from ca_rubro_op with(index = ca_rubro_op_1)
            where ro_operacion  = D.op_operacion
              and ro_tipo_rubro = 'I'),
          (select ro_porcentaje_efa from ca_rubro_op with(index = ca_rubro_op_1)
            where ro_operacion  = D.op_operacion
              and ro_tipo_rubro = 'I'),
          (select ro_porcentaje from ca_rubro_op with(index = ca_rubro_op_1)
            where ro_operacion  = D.op_operacion
              and ro_tipo_rubro = 'M'),
          vlr_proximo,          vlr_saldo,     fecha_ven,
          fecha_pago,

         -- Faltan Campos movimiento Periodo

          fecha_tasa_apl,       exp_tasa_apl,
          (select vr_valor from ca_valor_referencial R
            where vr_tipo       = D.tasa_aplicada
              and vr_fecha_vig  = D.fecha_tasa_apl
              and vr_secuencial = (select max(vr_secuencial) from ca_valor_referencial
                                    where vr_tipo      = R.vr_tipo
                                      and vr_fecha_vig = R.vr_fecha_vig)),
          case
             when fecha_tasa_maxmora < fecha_tasa_maxusura then fecha_tasa_maxmora
             else fecha_tasa_maxusura
          end,
          (select vr_valor from ca_valor_referencial R
            where vr_tipo       = D.tasa_maxmora
              and vr_fecha_vig  = D.fecha_tasa_maxmora
              and vr_secuencial = (select max(vr_secuencial) from ca_valor_referencial
                                    where vr_tipo      = R.vr_tipo
                                      and vr_fecha_vig = R.vr_fecha_vig)),
          (select vr_valor from ca_valor_referencial R
            where vr_tipo       = D.tasa_maxusura
              and vr_fecha_vig  = D.fecha_tasa_maxusura
              and vr_secuencial = (select max(vr_secuencial) from ca_valor_referencial
                                    where vr_tipo      = R.vr_tipo
                                      and vr_fecha_vig = R.vr_fecha_vig)),
          @w_mensaje,           op_banca
     from #dat_op D    
   
   if @@error <> 0
   begin
      print 'Error de insercion en ca_extracto_linea_bat'
      return 1 
   end      
end  -- if @w_tipo_pro = 'C'


/********************************/
--        Archivo Plano        -- 
/********************************/
if @w_tipo_proceso = 'P'
begin
   if object_id ('ca_extracto_linea_bat_bcp') is not null
   begin
      drop table ca_extracto_linea_bat_bcp
   end

   select fpro=convert(varchar(10),el_fecha_proceso,@w_form_fecha),      el_corte,         fdesde=convert(varchar(10),el_fecha_desde,@w_form_fecha),
          fhasta=convert(varchar(10),el_fecha_hasta,@w_form_fecha),      el_cliente,       el_direccion,
          el_ciudad,                                                     el_banco,         el_oficina,
          fini=convert(varchar(10),el_fecha_ini_op,@w_form_fecha),       el_monto_apr_op,  ffin=convert(varchar(10),el_fecha_fin_op,@w_form_fecha),
          el_fpago_int,                                                  el_toperacion,    el_tasa_nominal,
          el_tasa_efa,                                                   el_tasa_mora,     el_vlr_prox_couta,
          el_vlr_saldo,
          fprox=convert(varchar(10),el_fecha_prox_cuota,@w_form_fecha),  el_fecha_pago,
          
          -- Faltan Campos movimiento Periodo
          
          ftasa=convert(varchar(10),el_fecha_tasa_apl,@w_form_fecha),    el_periodo,       el_tasa_apl,
          fmax=convert(varchar(10),el_fecha_tasa_max,@w_form_fecha),     el_tasa_max_mora,
          el_tasa_max_usura,                                             el_mensaje
     into ca_extracto_linea_bat_bcp
     from ca_extracto_linea_bat
    where el_corte       = @w_corte
      and el_fecha_desde = @w_fecha_desde
      and el_fecha_hasta = @w_fecha_hasta
      and el_banco       = isnull(@w_banco, el_banco)
      and el_banca       = isnull(@w_banca, el_banca)
      and el_ciudad      = isnull(@w_ciudad, el_ciudad)
      and el_oficina     = isnull(@w_oficina, el_oficina)
     
   if @@error <> 0
   begin
      print 'Error de insercion en ca_extracto_linea_bat_bcp'
      return 1
   end
   
   /* Generacion archivo plano con parametros de ejecucion -- Archivo entregado por el banco */
   select    
      @w_file  = 'Extracto_Corte' + '_' + cast(@w_corte as varchar),      
      @w_bd    = 'cob_cartera',
      @w_tabla = 'ca_extracto_linea_bat_bcp'
   
   select @w_fuente  = @w_path + @w_file + '.txt',
          @w_errores = @w_path + @w_file + '.err'

   select @w_comando = @w_cmd + @w_bd + '..' + @w_tabla + ' out ' + @w_fuente + 
                       ' -c -t'' + char(167) + '' -e '+ @w_errores + ' -config ' + @w_s_app + '.ini'
   
   exec @w_error = xp_cmdshell @w_comando
   
   if @w_error <> 0 
   begin
      print 'Error Generacion Archivo Planio'
      print @w_comando 
      return @w_error
   end    
end -- if @w_tipo_pro = 'P'

return 0

go

