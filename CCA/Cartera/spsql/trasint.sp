/************************************************************************/
/* Archivo:             trasint.sp                                      */
/* Stored procedure:    sp_traslado_interes                             */
/* Base de datos:       cob_cartera                                     */
/* Producto:            Cartera                                         */
/* Disenado por:        Ivan Jimenez                                    */
/* Fecha de escritura:  09-Nov-2005                                     */
/************************************************************************/
/*                         IMPORTANTE                                   */
/* Este programa es parte de los paquetes bancarios propiedad de        */
/* 'MACOSA', representantes exclusivos para el Ecuador de la            */
/* 'NCR CORPORATION'.                                                   */
/* Su uso no autorizado queda expresamente prohibido asi como           */
/* cualquier alteracion o agregado hecho por alguno de sus              */
/* usuarios sin el debido consentimiento por escrito de la              */
/* Presidencia Ejecutiva de MACOSA o su representante.                  */
/*                         PROPOSITO                                    */
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                      MODIFICACIONES                                  */
/* FECHA          AUTOR       RAZON                                     */
/* 09/Nov/2005    I.Jimenez   Emision Inicial                           */
/************************************************************************/

use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_traslado_interes')
        drop proc sp_traslado_interes
go

create proc sp_traslado_interes(
   @s_user           login = null,
   @s_date           datetime,
   @s_term           varchar(30) = null,
   @i_banco          cuenta,
   @i_cuota_orig     smallint = 0,
   @i_cuota_dest     smallint = 0,
   @i_accion         char(1),
   @i_formato_fecha  smallint = 101       --    ESTE VIENE DEL FRONT END 
                                          --    SEGÚN LAS PREFERENCIAS DEL USUARIO
) as

declare
   @w_sp_name              varchar(30),
   @w_op_operacion         int,
   @w_op_fecha_ult_proceso datetime,
   @w_di_dividendo         smallint,
   @w_di_fecha_ven         datetime,
   @w_ti_cuota_orig       smallint,
   @w_ti_cuota_dest       smallint,
   @w_ti_usuario          varchar(30),
   @w_ti_fecha_ingreso    datetime,
   @w_ti_terminal         varchar(30),
   @w_ti_estado           char(1), 
   @w_ti_monto            money, 
   @w_valor               money,
   @w_error               int

--  Inicializacion de Variables  
select  @w_sp_name = 'sp_traslado_interes'

--- CONSULTA 
if @i_accion = 'C'
begin
   -- DEVOLVER EL CLIENTE LAS SIGUIENTES CONSULTAS 
   if not exists(select 1 from ca_operacion where op_banco = @i_banco)
   begin
      select @w_error = 711000
      goto ERROR
   end
   
   -- Para la cabecera
   select es_descripcion, 
          convert(varchar,op_fecha_ult_proceso,@i_formato_fecha),
          di_dividendo, 
          convert(varchar,di_fecha_ven,@i_formato_fecha)
   from   ca_operacion, 
          ca_dividendo, 
          ca_estado
   where  op_banco     = @i_banco
   and    di_operacion = op_operacion
   and    di_estado    = 1
   and    es_codigo    = op_estado
   
   -- MAXIMA CANTIDAD DE DIVIDENDOS
   select max(di_dividendo)
   from  ca_dividendo, 
         ca_operacion
   where op_banco     = @i_banco
   and   di_operacion = op_operacion
   and   di_estado    = 0
   group by di_operacion
   
   -- PARA LA GRILLA
   select 'Cuota Origen' = ti_cuota_orig,
          'Cuota Destino'= ti_cuota_dest,
          'Validacion'   = 'Validacion',
          'Estado'       = ti_estado
   from   ca_operacion, 
          ca_traslado_interes
   where  op_banco     = @i_banco
   and    ti_operacion = op_operacion
end

--- VALIDACION 
if @i_accion = 'V'
begin
   select @w_op_operacion         =  op_operacion,
          @w_op_fecha_ult_proceso =  op_fecha_ult_proceso
   from   ca_operacion 
   where  op_banco = @i_banco
   
   select @w_di_dividendo = di_dividendo,
          @w_di_fecha_ven = di_fecha_ven
   from   ca_dividendo
   where  di_operacion = @w_op_operacion
   and    di_estado    = 1
   
   if @w_op_fecha_ult_proceso = @w_di_fecha_ven
   begin
      select @w_error = 711001
      goto ERROR      
   end
   
   if @i_cuota_orig >= @i_cuota_dest
   begin
      select @w_error = 711003
      goto ERROR
   end
end

--- TRANSMITIR
if @i_accion = 'T'
begin
   select @w_op_operacion         = op_operacion,
          @w_op_fecha_ult_proceso = op_fecha_ult_proceso
   from  ca_operacion
   where op_banco = @i_banco
   
   select @w_valor    = sum(am_cuota - am_pagado)
   from   ca_amortizacion, 
          ca_rubro_op
   where  ro_operacion  = @w_op_operacion
   and    ro_tipo_rubro = 'I'
   and    ro_fpago      = 'P'
   and    am_operacion  = ro_operacion
   and    am_dividendo  = @i_cuota_orig
   and    am_concepto   = ro_concepto
   group  by ro_concepto
   
   if @w_valor > 0
   begin
      select @w_di_dividendo = di_dividendo,
             @w_di_fecha_ven = di_fecha_ven
      from  ca_dividendo
      where di_operacion = @w_op_operacion 
      and   di_estado = 1
      
      if exists (select 1 from ca_traslado_interes
                 where  ti_operacion = @w_op_operacion
                 and    ti_cuota_orig = @i_cuota_orig
                 and    ti_cuota_dest = @i_cuota_dest)
         return 0
      
      if exists (select 1 from ca_traslado_interes
                 where  ti_operacion = @w_op_operacion
                 and    ti_cuota_orig = @i_cuota_orig
                 and    ti_estado = 'P')
      begin
         exec cobis..sp_cerror
              @t_debug = 'N',
              @t_file  = null,
              @t_from = @w_sp_name,
              @i_num  = 711004
         return 711004
      end
      
      if exists (select 1 from ca_traslado_interes
                 where ti_operacion = @w_op_operacion
                 and   ti_cuota_orig = @i_cuota_orig)
      begin
         -- GRABAR EL REGISTRO EXISTENTE EN LA TABLA DE TRANSACCIONES DE SERVICIO
         select @w_ti_cuota_orig    = ti_cuota_orig,
                @w_ti_cuota_dest    = ti_cuota_dest,
                @w_ti_usuario       = ti_usuario,
                @w_ti_fecha_ingreso = ti_fecha_ingreso,
                @w_ti_terminal      = ti_terminal,
                @w_ti_estado        = ti_estado,
                @w_ti_monto         = ti_monto
         from  ca_traslado_interes 
         where ti_operacion = @w_op_operacion
         and   ti_cuota_orig = @i_cuota_orig
         
         insert into ca_traslado_interes_ts
               (tis_fecha_real,     tis_usuario_ts,   tis_operacion,      tis_cuota_orig, 
                tis_cuota_dest,     tis_usuario,      tis_fecha_ingreso,  tis_terminal, 
                tis_estado,         tis_monto)        
         values(getdate(),          @s_user,          @w_op_operacion,     @w_ti_cuota_orig, 
                @w_ti_cuota_dest,   @w_ti_usuario,    @w_ti_fecha_ingreso, @w_ti_terminal, 
                @w_ti_estado,       @w_ti_monto)        
         
         -- BORRAR EL REGISTRO EXISTENTE
         delete from ca_traslado_interes
         where  ti_operacion = @w_op_operacion
         and    ti_cuota_orig = @i_cuota_orig
      end
      
      insert into ca_traslado_interes 
            (ti_operacion,    ti_cuota_orig,    ti_cuota_dest, 
             ti_usuario,      ti_fecha_ingreso, ti_terminal,
             ti_estado,       ti_monto)
      values(@w_op_operacion, @i_cuota_orig,    @i_cuota_dest, 
             @s_user,         @s_date,          @s_term,
             'T',             @w_valor)
   end -- FIN @w_valor > 0
end

if @i_accion = 'I'
begin
   select @w_op_operacion         =  op_operacion,
          @w_op_fecha_ult_proceso = op_fecha_ult_proceso
   from   ca_operacion
   where  op_banco = @i_banco
   
   update ca_traslado_interes
   set    ti_estado = 'I'
   where  ti_operacion = @w_op_operacion
   and    ti_estado    = 'T'
end

--- ELIMINACION 
if @i_accion = 'D'
begin
   select @w_op_operacion = op_operacion
   from   ca_operacion 
   where  op_banco = @i_banco
   
   if exists (select 1 from ca_traslado_interes
              where  ti_operacion  = @w_op_operacion
              and    ti_cuota_orig = @i_cuota_orig
              and    ti_estado     = 'I')
   begin
      -- GRABAR EL REGISTRO EXISTENTE EN LA TABLA DE TRANSACCIONES DE SERVICIO
      select @w_ti_cuota_orig    = ti_cuota_orig,
             @w_ti_cuota_dest    = ti_cuota_dest,
             @w_ti_usuario       = ti_usuario,
             @w_ti_fecha_ingreso = ti_fecha_ingreso,
             @w_ti_terminal      = ti_terminal,
             @w_ti_estado        = ti_estado,
             @w_ti_monto         = ti_monto
      from  ca_traslado_interes 
      where ti_operacion = @w_op_operacion
      and   ti_cuota_orig = @i_cuota_orig 
      
      insert into ca_traslado_interes_ts
            (tis_fecha_real,  tis_usuario_ts,  tis_operacion,      tis_cuota_orig,
             tis_cuota_dest,  tis_usuario,     tis_fecha_ingreso,  tis_terminal,
             tis_estado,      tis_monto)
      values(getdate(),        @s_user,        @w_op_operacion,     @w_ti_cuota_orig, 
             @w_ti_cuota_dest, @w_ti_usuario,  @w_ti_fecha_ingreso, @w_ti_terminal, 
             @w_ti_estado,     @w_ti_monto)
      
      -- Borrar el registro existente
      delete from ca_traslado_interes 
      where ti_operacion = @w_op_operacion 
      and ti_cuota_orig = @i_cuota_orig
   end
end

return 0

ERROR:

exec cobis..sp_cerror
     @t_debug  ='N',
     @t_file   = null,
     @t_from   = @w_sp_name,
     @i_num    = @w_error

return  @w_error
go