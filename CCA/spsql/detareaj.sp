/************************************************************************/
/*      Archivo:                detareaj.sp                             */
/*      Stored procedure:       sp_detalle_reajuste                     */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           P. Narvaez                              */
/*      Fecha de escritura:     17/12/1997                              */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA".							                                    */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Mantenimiento de Detalles de Reajueste para una opercion        */
/************************************************************************/
/*      Modificado por:		Luis Alfonso Mayorga LAMH                    */
/*      Fecha:			      Noviembre 19 de 2002                         */
/*      Descripci¢n:		   Controlar que los puntos negativos no        */
/*                   		sean mayor al valor de la tasa               */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_detalle_reajuste')
	drop proc sp_detalle_reajuste
go

create proc sp_detalle_reajuste(
   @s_user                 login,
   @s_date                 datetime,
   @s_ofi                  smallint,
   @s_term                 varchar(30),
   @i_operacion            char(1),
   @i_secuencial           int,
   @i_concepto             catalogo = null,
   @i_referencial          catalogo = null,
   @i_signo                char(1)  = null,
   @i_factor               float    = null,
   @i_porcentaje           float    = null,
   @i_banco                cuenta

)as

declare 
   @w_error             int ,
   @w_return            int ,
   @w_operacionca       int ,
   @w_sp_name           descripcion,
   @w_clave1            varchar(255),
   @w_clave2            varchar(255),
   @w_clave3            varchar(255),
   @w_VlrDefault	float,		--LAMH
   @w_sector            catalogo,
   @w_tasa_referencial     catalogo,
   @w_op_fecha_ult_proceso datetime,
   @w_fecha_tr             datetime,
   @w_valor_tasa_ref       float


-- VARIABLES INICIALES
select @w_sp_name = 'sp_detalle_reajuste'

select @w_operacionca = op_operacion,
       @w_sector      = op_sector,
       @w_op_fecha_ult_proceso = op_fecha_ult_proceso
from ca_operacion
where op_banco = @i_banco

-- MODIFICACION DE DETALLE DE REAJUSTES
if @i_operacion = 'U'
begin  
   -- CHEQUEAR EXISTENCIA DE REFERENCIAL
   if @i_referencial is not null
   begin
      if not exists(select 1
                    from ca_valor_det
                    where vd_tipo  = @i_referencial)
      begin
         select @w_error = 701085
         goto ERROR
      end
   end
   
   begin tran

   select @w_clave1 = convert(varchar(255), @w_operacionca)
   select @w_clave2 = convert(varchar(255), @i_secuencial)
   select @w_clave3 = convert(varchar(255), @i_concepto)
   
   exec @w_return = sp_tran_servicio
        @s_user    = @s_user,
        @s_date    = @s_date,
        @s_ofi     = @s_ofi,
        @s_term    = @s_term,
        @i_tabla   = 'ca_reajuste_det',
        @i_clave1  = @w_clave1,
        @i_clave2  = @w_clave2,
        @i_clave3  = @w_clave3
   
   if @w_return != 0
   begin
      select @w_error = @w_return
      goto ERROR
   end
   
   
   select @w_VlrDefault = vd_valor_default,
          @w_tasa_referencial = vd_referencia
   from   ca_valor_det
   where  vd_tipo  = @i_referencial
   and    vd_sector = @w_sector
   

   if ltrim(rtrim(@i_signo)) = '-' 
   begin
        ---sacar la tasa base

      select @w_fecha_tr = max(vr_fecha_vig)
      from ca_valor_referencial
      where vr_tipo = @w_tasa_referencial
      and vr_fecha_vig  <= @w_op_fecha_ult_proceso
            
       select @w_valor_tasa_ref = vr_valor
      from   ca_valor_referencial
      where  vr_tipo    = @w_tasa_referencial
      and    vr_secuencial = (select max(vr_secuencial)
                              from ca_valor_referencial
                              where vr_tipo     = @w_tasa_referencial
                              and vr_fecha_vig  = @w_fecha_tr)
      if @@rowcount = 0
      begin      
         PRINT 'detreaj.sp  Atención signo enviado ' + @i_signo + ' puntos ' + cast(@i_factor as varchar) + ' y no existe base para restar estos puntos ' 
         select @w_error = 710402
         goto ERROR
        
      end
      
      if @i_factor > @w_valor_tasa_ref   
      begin
         PRINT 'detreaj.sp  Atención signo enviado ' + @i_signo + ' puntos ' + cast(@i_factor as varchar) + ' valor referencial ' + cast(@w_valor_tasa_ref as varchar)
         select @w_error = 710402
         goto ERROR
      end   
   end
   
   update ca_reajuste_det
   set    red_referencial      = isnull(@i_referencial,null),
          red_signo            = isnull(@i_signo,null),
          red_factor           = isnull(@i_factor,null),
          red_porcentaje       = isnull(@i_porcentaje,null)
   where  red_secuencial = @i_secuencial
   and    red_operacion  = @w_operacionca
   and    red_concepto   = @i_concepto
   
   if @@error <> 0
   begin
      select @w_error = 710044
      goto ERROR
   end
   
   if  @i_referencial is null
   begin
      update ca_reajuste
      set    re_desagio	     = null	
      where  re_operacion  = @w_operacionca
      and    re_secuencial = @i_secuencial
      
      if @@error <> 0
      begin
         select @w_error = 710041
         goto ERROR
      end
   end
   
   commit tran
   
   select @i_operacion = 'S'
end

-- ELIMINACION DE UN DETALLE DE REAJUSTE
if @i_operacion = 'D' --7664
begin
   begin tran
   
   select @w_clave1 = convert(varchar(255), @w_operacionca)
   select @w_clave2 = convert(varchar(255), @i_secuencial)
   select @w_clave3 = convert(varchar(255), @i_concepto)
   
   exec @w_return = sp_tran_servicio
        @s_user    = @s_user,
        @s_date    = @s_date,
        @s_ofi     = @s_ofi,
        @s_term    = @s_term,
        @i_tabla   = 'ca_reajuste',
        @i_clave1  = @w_clave1,
        @i_clave2  = @w_clave2
   
   if @w_return != 0
   begin
      select @w_error = @w_return
      goto ERROR
   end
   
   delete ca_reajuste
   where  re_operacion  = @w_operacionca
   and    re_secuencial = @i_secuencial
   
   if @@error <> 0
   begin
      select @w_error = 710042
      goto ERROR
   end
   
   exec @w_return = sp_tran_servicio
        @s_user    = @s_user,
        @s_date    = @s_date,
        @s_ofi     = @s_ofi,
        @s_term    = @s_term,
        @i_tabla   = 'ca_reajuste_det',
        @i_clave1  = @w_clave1,
        @i_clave2  = @w_clave2,
        @i_clave3  = @w_clave3
   
   if @w_return != 0
   begin
      select @w_error = @w_return
      goto ERROR
   end
   
   delete ca_reajuste_det
   where red_secuencial = @i_secuencial
   and   red_operacion  = @w_operacionca
   and   red_concepto   = @i_concepto

   if @@error <> 0
   begin
      select @w_error = 710043
      goto ERROR
   end
   
   commit tran
   
   select @i_operacion = 'S'
end

-- BUSQUEDA DE DETALLE DE RAJUESTES
if @i_operacion = 'S'
begin 
   select 'CONCEPTO'    = red_concepto,
          'REFERENCIAL' = red_referencial,
          'SIGNO'       = red_signo,
          'FACTOR'      = red_factor,
          'PORCENTAJE'  = red_porcentaje
   from   ca_reajuste_det
   where  red_secuencial = @i_secuencial
   and    red_operacion  = @w_operacionca
end

return 0

ERROR:

exec cobis..sp_cerror
     @t_debug  = 'N',
     @t_file   = null,
     @t_from   = @w_sp_name,
     @i_num    = @w_error
--     @i_cuenta = ' '

return @w_error

go

