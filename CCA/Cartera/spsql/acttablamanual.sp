/************************************************************************/
/*      Archivo:                gentabla.sp                             */
/*      Stored procedure:       sp_actualiza_tabla_manual               */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Elcira Pelaez Burbano                   */
/*      Fecha de escritura:     May. 2005                               */
/************************************************************************/
/* IMPORTANTE                                                           */
/* Este programa es parte de los paquetes bancarios propiedad de        */
/* COBISCORP S.A.representantes exclusivos para el Ecuador de la        */
/* AT&T                                                                 */
/* Su uso no autorizado queda expresamente prohibido asi como           */
/* cualquier autorizacion o agregado hecho por alguno de sus            */
/* usuario sin el debido consentimiento por escrito de la               */
/* Presidencia Ejecutiva de COBISCORP o su representante                */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Actualiza todos los rubros de la tabla de amortizacion          */
/*      menos capital                                                   */
/*  MODIFICACIONES                                                      */
/*  FQ Mar 6 2006     NR 461                                            */
/*  MAY/18/2022       Kevin Rodríguez  Se comenta recálculo de Seguro   */
/************************************************************************/  

use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_actualiza_tabla_manual')
   drop proc sp_actualiza_tabla_manual
go

create proc sp_actualiza_tabla_manual
@s_user                 login    = null,
@s_sesn                 int      = null,
@s_date                 datetime = null,
@s_term                 varchar(30)= null,
@s_ofi                  smallint = null,
@i_operacionca          int,
@i_crear_op             char(1)  = 'N',
@i_control_tasa         char(1)  = 'S',
@i_en_linea             char(1)  = 'N'
     
as
declare 
   @w_sp_name                      descripcion,
   @w_return                       int,
   @w_error                        int,
   @w_tasa_int                     float,
   @w_tipo                         catalogo,
   @w_fecha_proceso                datetime,
   @w_banco                        cuenta
   
   

-- CARGAR VALORES INICIALES
select @w_sp_name = 'sp_actualiza_tabla_manual'
   
select @w_tipo          =   opt_tipo,
       @w_banco         =   opt_banco, 
       @w_fecha_proceso =   opt_fecha_ult_proceso
from ca_operacion_tmp
where opt_operacion = @i_operacionca
  
exec @w_return = sp_actualiza_rubros
     @i_operacionca = @i_operacionca,
     @i_crear_op    = @i_crear_op --Esta variable hace que actualice la tasa referencial

if @w_return != 0
begin
   PRINT 'gentabla Error ejecutando sp_actualiza_rubros'
   return @w_return
end




-- VERIFICAR QUE LA TASA TOTAL NO HAYA SUPERADO EL 1.5 DEL IBC
if @i_control_tasa = 'S'
begin  
   exec @w_return = sp_control_tasa
        @i_operacionca = @i_operacionca,
        @i_temporales  = 'S',
        @i_ibc         = 'S'
   
   if @w_return != 0
      return @w_return
end


---TASA DE INTERES
select @w_tasa_int = 0

select @w_tasa_int = sum(rot_porcentaje) --TASA DE INTERES TOTAL
from   ca_rubro_op_tmp
where  rot_operacion  = @i_operacionca
and    rot_fpago      in ('P', 'A')
and    rot_tipo_rubro = 'I'


---LINEAS DE CONVENIO
if @w_tipo  =  'V'
begin  
   
   -- CALCULO DEL SEGURO DE VIDA
   exec @w_return = sp_calculo_seguro_vida 
        @i_operacion = @i_operacionca,
        @i_tasa_int  = @w_tasa_int
   
   if @w_return != 0
      return @w_return
--LINEAS DE CONVENIO
end
ELSE
begin
   -- CALCULO DEL SEGURO DE VIDA
   exec @w_return = sp_rubros_periodos_diferentes
        @i_operacion = @i_operacionca
   
   if @w_return != 0
      return @w_return
   
   /* KDR 18/05/2022 Se comenta ya que no aplica a versión Finca
   -- CALCULO DEL SEGURO DE VIDA SOBRE VALOR INSOLUTO
   exec @w_return = sp_calculo_seguros_sinsol
        @i_operacion = @i_operacionca
   
   if @w_return != 0
      return @w_return
   -- CALCULO DEL SEGURO DE VIDA SOBRE VALOR INSOLUTO
   -- CALCULO DE RUBROS CATALOGO
   exec @w_return =  sp_rubros_catalogo
        @i_operacion = @i_operacionca
   
   if @w_return != 0
      return @w_return
   -- CALCULO DE RUBROS CATALOGO -- FIN KDR*/
end


return 0

go

