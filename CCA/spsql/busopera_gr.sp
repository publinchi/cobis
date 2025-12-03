/************************************************************************/
/*   Archivo:                 busopera_gr.sp                            */
/*   Stored procedure:        sp_buscar_operaciones_grupales            */
/*   Base de Datos:           cob_cartera                               */
/*   Producto:                Cartera                                   */
/*   Disenado por:            Ma. Jose Taco                             */
/*   Fecha de Documentacion:  Noviembre 2017                            */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier autorizacion o agregado hecho por alguno de sus          */
/*   usuario sin el debido consentimiento por escrito de la             */
/*   Presidencia Ejecutiva de MACOSA o su representante                 */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Buscar operaciones grupales deacuerdo a criterio                   */
/************************************************************************/
/*                             ACTUALIZACIONES                          */
/*                                                                      */
/*     FECHA           AUTOR              CAMBIO                        */
/* 07-Nov-2017         Ma. Jose Taco      Emision inicial               */
/************************************************************************/
use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_buscar_operaciones_grupales')
   drop proc sp_buscar_operaciones_grupales
go

create proc sp_buscar_operaciones_grupales
   @s_user              login       = null,
   @i_banco             cuenta      = null,
   @i_tramite           int         = null,
   @i_grupo             int         = null,
   @i_fecha_ini         varchar(10)    = null,
   @i_oficina           smallint    = null,
   @i_oficial           int         = null,
   @i_siguiente         int         = 0,
   @i_formato_fecha     int         = 101,
   @i_grupal            char(1)     = "N"
as
declare
   @w_sp_name        varchar(32),
   @w_opcion         int,
   @w_error          int,
   @w_redbusca       int,
   @w_oficina_matriz int,
   @w_msg            varchar(100),
   @w_fecha_ini      date

/*
-- CAPTURA NOMBRE DE STORED PROCEDURE
select @w_sp_name = 'sp_buscar_operaciones_grupales',
       @w_oficina_matriz = 900,
	   @w_fecha_ini= convert(date, @i_fecha_ini,103)

if @i_fecha_ini = ''
    select @i_fecha_ini = null

if @i_siguiente <> 0
   goto SIGUIENTE

-- LIMPIAR TABLA TEMPORAL
delete ca_buscar_operaciones_tmp
 where bot_usuario = @s_user

-- BUSCAR OPCION DE BUSQUEDA
select @w_opcion = 1000
if @i_banco is not null 
   select @w_opcion = 1
else
   if @i_tramite is not null
      select @w_opcion = 2
   else
      if @i_grupo  is not null
         select @w_opcion = 3
      else
         if @i_oficial is not null
            select @w_opcion = 4
         else
            if @i_oficina is not null
               select @w_opcion = 5
--print '@w_opcion: '+ convert(varchar, @w_opcion)
if @w_opcion > 6 --ESTO ES PARA QUE SIEMPRE HAYA UN CAMPO PRIMARIO 
begin
   select @w_error  = 708199
   goto ERROR
end

-- BUSQUEDAS DE NUMERO DE OPERACIONES
if(@i_grupal = 'S')
BEGIN

if @w_opcion = 1 -- NRO PRESTAMO
BEGIN

        insert into ca_buscar_operaciones_tmp
        select  @s_user,
                op_operacion,       op_moneda,              op_fecha_liq,
                op_lin_credito,     op_estado,              op_migrada,
                op_toperacion,      op_oficina,             op_oficial,
                op_cliente,         op_tramite,             op_banco,
                op_fecha_reajuste,  op_tipo,                op_reajuste_especial,
                op_reajustable,     op_monto,               op_monto_aprobado,
                op_anterior,        op_fecha_ult_proceso,   op_codigo_externo,
                op_ref_exterior,    '',
                op_num_comex,
                op_tipo_linea,      op_nombre,              op_fecha_fin
        from   ca_operacion, 
               cob_credito..cr_tramite_grupal
        where tg_referencia_grupal = @i_banco
          and tg_referencia_grupal = op_banco
          and op_estado = 3 --operaciones papa que se han desembolsado
end

if @w_opcion = 2 -- TRAMITE
BEGIN
        insert into ca_buscar_operaciones_tmp
        select  @s_user,
                op_operacion,       op_moneda,              op_fecha_liq,
                op_lin_credito,     op_estado,              op_migrada,
                op_toperacion,      op_oficina,             op_oficial,
                op_cliente,         op_tramite,             op_banco,
                op_fecha_reajuste,  op_tipo,                op_reajuste_especial,
                op_reajustable,     op_monto,               op_monto_aprobado,
                op_anterior,        op_fecha_ult_proceso,   op_codigo_externo,
                op_ref_exterior,    '',
                op_num_comex,
                op_tipo_linea,      op_nombre,              op_fecha_fin
        from   ca_operacion, --(index ca_operacion_3)
               cob_credito..cr_tramite_grupal
        where tg_tramite = @i_tramite
          and tg_referencia_grupal = op_banco
          and op_estado = 3 --operaciones papa que se han desembolsado
end

if @w_opcion = 3 --GRUPO
begin
       --print '@i_cliente: '+ convert(varchar, @i_cliente)
        insert into ca_buscar_operaciones_tmp
        select  @s_user,
                op_operacion,       op_moneda,              op_fecha_liq,
                op_lin_credito,     op_estado,              op_migrada,
                op_toperacion,      op_oficina,             op_oficial,
                op_cliente,         op_tramite,             op_banco,
                op_fecha_reajuste,  op_tipo,                op_reajuste_especial,
                op_reajustable,     op_monto,               op_monto_aprobado,
                op_anterior,        op_fecha_ult_proceso,   op_codigo_externo,
                op_ref_exterior,    '',
                op_num_comex,
                op_tipo_linea,      op_nombre,              op_fecha_fin
        from   ca_operacion, 
               cob_credito..cr_tramite_grupal
        where tg_grupo = @i_grupo
		  and tg_grupo = op_cliente
          and tg_referencia_grupal = op_banco
          and op_estado = 3 --operaciones papa que se han desembolsado
end

if @w_opcion = 4 --OFICIAL Y FECHA
BEGIN
   if @i_fecha_ini is not null
   begin
            insert into ca_buscar_operaciones_tmp
            SELECT  @s_user,
                    op_operacion,       op_moneda,              op_fecha_liq,
                    op_lin_credito,     op_estado,              op_migrada,
                    op_toperacion,      op_oficina,             op_oficial,
                    op_cliente,         op_tramite,             op_banco,
                    op_fecha_reajuste,  op_tipo,                op_reajuste_especial,
                    op_reajustable,     op_monto,               op_monto_aprobado,
                    op_anterior,        op_fecha_ult_proceso,   op_codigo_externo,
                    op_ref_exterior,    '',
                    op_num_comex,
                    op_tipo_linea,      op_nombre,              op_fecha_fin
            from  ca_operacion,
                  cob_credito..cr_tramite_grupal,
                  cobis..cc_oficial
            where tg_referencia_grupal = op_banco
              and op_oficial    = oc_oficial
			--  and op_oficina    = @i_oficina
              and op_oficial    = @i_oficial
			  and op_fecha_liq  = @w_fecha_ini
              and op_estado = 3 --operaciones papa que se han desembolsado
   end
   else
   begin
      select @w_error = 3
	  SELECT @w_msg = 'Para búsqueda por oficial ingresar (fecha de inicio)'
      goto ERROR
   end 
end  

if @w_opcion = 5 --OFICINA Y FECHA
BEGIN   
      if @i_fecha_ini is not null
      begin
            insert into ca_buscar_operaciones_tmp
            select  @s_user,
                    op_operacion,       op_moneda,              op_fecha_liq,
                    op_lin_credito,     op_estado,              op_migrada,
                    op_toperacion,      op_oficina,             op_oficial,
                    op_cliente,         op_tramite,             op_banco,
                    op_fecha_reajuste,  op_tipo,                op_reajuste_especial,
                    op_reajustable,     op_monto,               op_monto_aprobado,
                    op_anterior,        op_fecha_ult_proceso,   op_codigo_externo,
                    op_ref_exterior,    '',
                    op_num_comex,
                    op_tipo_linea,      op_nombre,              op_fecha_fin
            from  ca_operacion,
                  cob_credito..cr_tramite_grupal
            where tg_referencia_grupal   = op_banco
              and op_oficina    = @i_oficina
              and op_fecha_liq  = @w_fecha_ini
              and op_estado = 3 --operaciones papa que se han desembolsado
      end
      else
      begin
        select @w_error = 2
		SELECT @w_msg =  'Para búsqueda por oficina ingresar (fecha de inicio)'
        goto ERROR
      end
end

END

-- RETORNAR DATOS A FRONT END
SIGUIENTE:

if @i_oficina = @w_oficina_matriz
   select @i_oficina = null
select distinct( bot_banco) as 'Num Préstamo Grupal',
       'Nombre Grupo'        = substring(bot_nombre,1,30),
       'Monto Préstamo'      = convert(float, bot_monto),
       'Fecha de inicio'     = convert(varchar(16),bot_fecha_ini, @i_formato_fecha)       
from   ca_buscar_operaciones_tmp
where  bot_usuario = @s_user
and    (bot_fecha_ini      = @w_fecha_ini or @w_fecha_ini is null)
and    (bot_oficina        = @i_oficina   or @i_oficina   is null)
and    (bot_cliente        = @i_grupo     or @i_grupo     is null)
and    (bot_oficial        = @i_oficial   or @i_oficial   is null)
and    (@i_grupal = 'S')
and    (bot_tramite        = @i_tramite   or @i_tramite   is null)
and    (bot_banco          = @i_banco     or @i_banco     is null)
--and    (bot_monto < bot_monto_aprobado or bot_tipo = 'O')
and    bot_operacion > @i_siguiente
--order  by bot_operacion

if @@rowcount = 0
begin
   select @w_error = 1
   select @w_msg= 'No existen mas operaciones'
   goto ERROR
end

set rowcount 0*/
return 0
/*
ERROR:
set rowcount 0

if @w_error = 1 
begin   
       exec cobis..sp_cerror 
                  @t_debug = 'N', 
                  @t_file = null,
                  @t_from = 'sp_buscar_operaciones_grupales',
                  @i_num  = 701221,
                  @i_msg = @w_msg
                  return @w_error   
end
else
   begin
   if @w_error = 2
   begin
      
	  exec cobis..sp_cerror 
                  @t_debug = 'N', 
                  @t_file = null,
                  @t_from = 'sp_buscar_operaciones_grupales',
                  @i_num  = 701222,
                  @i_msg = @w_msg
                  return @w_error
   end
   else 
      if @w_error = 3
	  begin
		 exec cobis..sp_cerror 
                  @t_debug = 'N', 
                  @t_file = null,
                  @t_from = 'sp_buscar_operaciones_grupales',
                  @i_num  = 701223,
                  @i_msg = @w_msg
                  return @w_error
	  end
      else
      begin  
         if @w_error = 7         
            print 'Para búsqueda por ruta ingresar la fecha de inicio'
         else
		 begin
            SELECT @w_msg = 'Ingrese al menos un criterio de busqueda principal'
			 exec cobis..sp_cerror 
                  @t_debug = 'N', 
                  @t_file = null,
                  @t_from = 'sp_buscar_operaciones_grupales',
                  @i_num  = 701224,
                  @i_msg = @w_msg
                  return @w_error
        end
      end
    end
return 1*/
/*
if @w_error = 1 
  BEGIN
    --  PRINT 'No existen préstamo'
      exec cobis..sp_cerror 
      @t_debug = 'N', 
      @t_file = null,
      @t_from = 'sp_buscar_operaciones_grupales',
      @i_num  = 701221,
      @i_msg = @w_msg
      return @w_error 
  END
  ELSE
  BEGIN
     
       if @w_error = 2
       BEGIN
        --     PRINT 'Para búsqueda por oficina ingresar (línea de credito y/o fecha de desembolso) u operación migrada'
            exec cobis..sp_cerror 
             @t_debug = 'N', 
             @t_file = null,
             @t_from = 'sp_buscar_operaciones_grupales',
             @i_num  = 701222,
             @i_msg = @w_msg
            return @w_error 
       END
       ELSE
       BEGIN
               if @w_error = 3
               BEGIN
              --  PRINT 'Para búsqueda por regional ingresar (fecha desembolso y opcionalmente línea de credito)'
                  exec cobis..sp_cerror 
                  @t_debug = 'N', 
                  @t_file = null,
                  @t_from = 'sp_buscar_operaciones_grupales',
                  @i_num  = 701223,
                  @i_msg = @w_msg
                   return @w_error 
                END                
       END
   END 
   */
   
GO


