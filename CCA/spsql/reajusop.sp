/************************************************************************/
/*      Archivo:                reajusop.sp                             */
/*      Stored procedure:       sp_reajuste_operacion                   */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           P. Narvaez                              */
/*      Fecha de escritura:     17/12/1997                              */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA".	                                                      */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Mantenimiento de Reajueste por operacion                        */
/************************************************************************/
/*              MODIFICACIONES                                          */
/*  FECHA       AUTOR            RAZON                                  */
/*  09/11/2016  Pedro Montenegro Parámetro i_web para devolver sp_error */
/*                               en lugar de print                      */
/*  01/25/2021  P.Narvaez       Paginacion en reajustes                 */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_reajuste_operacion')
	drop proc sp_reajuste_operacion
go
---TIKET 167070 Mayo 2015
create proc sp_reajuste_operacion(
   @s_user                 login     = null,
   @s_term                 varchar(30) = null,
   @s_date                 datetime  = null,
   @s_ofi                  smallint  = null,
   @i_operacion            char(1),
   @i_banco                cuenta    = null,
   @i_secuencial           int       = null,
   @i_especial             char(1)   = null,
   @i_fecha_reajuste       datetime  = null,
   @i_formato_fecha        int       = null,
   @i_siguiente            int       = 0,
   @i_desagio              char(1)   = 'N',
   @i_web                  char(1)   = 'N'
)as

declare 
   @w_error             int ,
   @w_return            int ,
   @w_operacionca       int ,
   @w_sp_name           descripcion,
   @w_secuencial        int,
   @w_clave1            varchar(255),
   @w_clave2            varchar(255),
   @w_clave3            varchar(255),
   @w_fecha_ult_proceso datetime,
   @w_estado_op         smallint

-- VARIABLES INICIALES
select @w_sp_name = 'sp_reajuste_operacion'

-- DATOS GENERALES DEL PRESTAMO
select @w_operacionca       = op_operacion,
       @w_fecha_ult_proceso = op_fecha_ult_proceso,
       @w_estado_op         = op_estado
from   ca_operacion
where  op_banco = @i_banco 

if @i_fecha_reajuste < @w_fecha_ult_proceso 
begin   
   print 'ERROR!!!!...La Fecha de reajuste es menor a la fecha de proceso de la operación..' + cast(@w_fecha_ult_proceso as varchar)
   if (@i_web = 'S')
   begin
      select @w_error = 724576
      goto ERROR
   end
   select @i_operacion = 'S'
end

-- MODIFICACION DE REAJUSTES
if @i_operacion = 'U'
begin
   if @w_estado_op = 4
   begin
      PRINT 'ATENCION Operación en estado CASTIGADO no puede actualizar su reajuste de tasa'
      if (@i_web = 'S')
      begin
         select @w_error = 701010
         goto ERROR
      end
      return 701010
   end 

   begin tran
   
   select @w_clave1 = convert(varchar(255), @w_operacionca)
   select @w_clave2 = convert(varchar(255), @i_secuencial)
   
   exec @w_return = sp_tran_servicio
        @s_user    = @s_user,
        @s_date    = @s_date,
        @s_ofi     = @s_ofi,
        @s_term    = @s_term,
        @i_tabla   = 'ca_reajuste',
        @i_clave1  = @w_clave1,
        @i_clave2  = @w_clave2
   
   if @w_return <> 0
   begin
      select @w_error = @w_return
      goto ERROR
   end
   
   update ca_reajuste
   set    re_fecha             = @i_fecha_reajuste,
          re_reajuste_especial = @i_especial,
          re_desagio	          = @i_desagio	
   where  re_operacion  = @w_operacionca
   and    re_secuencial = @i_secuencial
   
   if @@error <> 0
   begin
      select @w_error = 710041
      goto ERROR
   end
   
   commit tran
   
   select @i_operacion = 'S'
end

-- ELIMINACION DE REAJUSTES Y SUS RESPECTIVOS DETALLES
if @i_operacion = 'D'
begin
   begin tran
   
   select @w_clave1 = convert(varchar(255),@w_operacionca)
   select @w_clave2 = convert(varchar(255),@i_secuencial)
   
   exec @w_return = sp_tran_servicio
        @s_user    = @s_user,
        @s_date    = @s_date,
        @s_ofi     = @s_ofi,
        @s_term    = @s_term,
        @i_tabla   = 'ca_reajuste',
        @i_clave1  = @w_clave1,
        @i_clave2  = @w_clave2
   
   if @w_return <> 0
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
   
   delete ca_reajuste_det
   where  red_secuencial  = @i_secuencial
   and    red_operacion   = @w_operacionca
   
   if @@error <> 0
   begin
      select @w_error = 710043
      goto ERROR
   end
   
   commit tran

   select @i_operacion = 'S'
end

-- BUSQUEDA DE RAJUESTES
if @i_operacion = 'S'
begin
   --Paginacion para 10 registros
   set rowcount 10
   select 'FECHA'         = convert(varchar(10), re_fecha, @i_formato_fecha),
          'MANT.CUOTA'    = re_reajuste_especial,
          'SECUENCIAL'    = re_secuencial,
          'TIPO / PUNTOS' = re_desagio	
   from   ca_reajuste
   where  re_operacion = @w_operacionca
   and    re_secuencial > @i_siguiente
   order by re_secuencial 
   set rowcount 0
end

return 0

ERROR:

exec cobis..sp_cerror
@t_debug  = 'N',          @t_file = null,
@t_from   = @w_sp_name,   @i_num = @w_error
--@i_cuenta = ' '

return @w_error

go

