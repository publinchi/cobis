/************************************************************************/
/*   Archivo:              cargandc.sp                                  */
/*   Stored procedure:     sp_cargar_tabla_notas_dc                     */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Elcira Pelaez Burbano                        */
/*   Fecha de escritura:   Febrero-2002                                 */
/************************************************************************/
/*                        IMPORTANTE                                    */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   "MACOSA".                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                        PROPOSITO                                     */
/*   Procedimiento para cargar la tabla ca_interfaz_ndc                 */
/*   para una fecha dada, si existe ya esta fecha elimina               */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*      FECHA          AUTOR          CAMBIO                            */
/*      NOV-2005       Elcira Pelaez  Cambios para el BAC               */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_cargar_tabla_notas_dc')
   drop proc sp_cargar_tabla_notas_dc
go


create proc sp_cargar_tabla_notas_dc
   @i_fecha_proceso     datetime ,
   @s_user              login = null
as
declare
   @w_sp_name      varchar(30),
   @w_return      int,
   @w_ab_secuencial_ing   int, 
   @w_ab_operacion      int,
   @w_ab_cuota_completa   char(1),
   @w_ab_tipo_cobro   char(1),
   @w_abd_concepto      catalogo, 
   @w_abd_cuenta      cuenta, 
   @w_abd_monto_mn      money,
   @w_abd_moneda      tinyint,
   @w_op_cliente      int,
   @w_op_banco      cuenta,
   @w_op_moneda      smallint,
   @w_op_nombre      descripcion,
   @w_abd_monto_mpg   money,
   @w_abd_cotizacion_mpg   money,
   @w_abd_tcotizacion_mpg  char(1),
   @w_commit               char(1),
   @w_error                int,
   @w_abd_monto_mop        money,
   @w_abd_cotizacion_mop   money,
   @w_cp_afectacion        char(1)


-- INICIALIZAR VARIABLES
select @w_sp_name    = 'sp_cargar_tabla_notas_dc'



-- ELIMINAR INFORMACION PARA LA FECHA
delete ca_interfaz_ndc
where  in_fecha_proceso = @i_fecha_proceso
and    in_estado = 'I'


-- CARGAR LA INFORMACION DE ABONOS
declare cursor_abonos cursor
   for select ab_secuencial_ing,    ab_operacion,
              abd_concepto,         abd_cuenta,          abd_monto_mn,
              abd_moneda,           ab_cuota_completa,   ab_tipo_cobro,
              abd_monto_mpg,        abd_monto_mop,       abd_cotizacion_mpg,
              abd_cotizacion_mop,   abd_tcotizacion_mpg, cp_afectacion
       from   ca_abono, ca_abono_det, ca_producto
       where  ab_fecha_ing      = @i_fecha_proceso
       and    ab_operacion      = abd_operacion
       and    ab_secuencial_ing = abd_secuencial_ing
       and    abd_concepto      = cp_producto
       and    ( (cp_pcobis        = 3 ) or (cp_pcobis      = 4)  )
       and    ab_estado         in ('ING')
       for read only

open cursor_abonos

fetch cursor_abonos
into  @w_ab_secuencial_ing,   @w_ab_operacion,
      @w_abd_concepto,        @w_abd_cuenta,          @w_abd_monto_mn,
      @w_abd_moneda,          @w_ab_cuota_completa,   @w_ab_tipo_cobro,
      @w_abd_monto_mpg,       @w_abd_monto_mop,       @w_abd_cotizacion_mpg,
      @w_abd_cotizacion_mop,  @w_abd_tcotizacion_mpg, @w_cp_afectacion

--while (@@fetch_status not in (-1,0))
while (@@fetch_status = 0)
begin
   -- INFORMACION DE OPERACION
   select @w_op_cliente = op_cliente,
          @w_op_nombre  = op_nombre,
          @w_op_banco   = op_banco,
          @w_op_moneda  = op_moneda
   from   ca_operacion
   where  op_operacion   = @w_ab_operacion
   
   -- INSERTAR INFORMACION EN TABLA DE INTERFAZ
   
   BEGIN TRAN --ATOMICIDAD POR REGISTRO
   
   insert ca_interfaz_ndc
         (in_secuencial,         in_operacion,     in_producto,
          in_banco,              in_moneda_op,     in_fecha_proceso,
          in_cliente,            in_nombre,        in_forma_pago,
          in_cuenta,             in_tipo_trn,      in_moneda_pago,
          in_cotizacion,         in_monto_mop,     in_monto_aplicar,
          in_monto_aplicado,     in_estado)
   values(@w_ab_secuencial_ing,  @w_ab_operacion,  7,
          @w_op_banco,           @w_op_moneda,     @i_fecha_proceso,
          @w_op_cliente,         @w_op_nombre,     @w_abd_concepto,
          @w_abd_cuenta,         @w_cp_afectacion, @w_abd_moneda,
          @w_abd_cotizacion_mpg, @w_abd_monto_mop, @w_abd_monto_mpg,
          0.00,                  'I')
   
   if @@error != 0
   begin
      select @w_error = 710354
      goto ERROR
   end 
   else
   begin
      --cargadas paso numero 1 roceso notasdau.sp
      update ca_opercaion_ndaut
      set ona_proceso = 'cargandc.sp',
          ona_numero_indicador  = 2     
      where ona_operacion = @w_ab_operacion
      and   ona_fecha_proceso = @i_fecha_proceso
   end
 
   
   
   COMMIT TRAN     ---FIN DE LA TRANSACCION
   
   goto SIGUIENTE
   
   ERROR:
   
   ROLLBACK
   
   BEGIN TRAN
   
   exec sp_errorlog
        @i_fecha       = @i_fecha_proceso,
        @i_error       = @w_error,
        @i_usuario     = 'sa',
        @i_tran        = 7000, 
        @i_tran_name   = @w_sp_name,
        @i_rollback    = 'N',  
        @i_cuenta      = @w_op_banco,
        @i_descripcion = 'CARGANDO PAGOS NOTAS DEBITO'

   COMMIT TRAN
   
   SIGUIENTE:
   fetch cursor_abonos
   into  @w_ab_secuencial_ing,   @w_ab_operacion,
         @w_abd_concepto,        @w_abd_cuenta,          @w_abd_monto_mn,
         @w_abd_moneda,          @w_ab_cuota_completa,   @w_ab_tipo_cobro,
         @w_abd_monto_mpg,       @w_abd_monto_mop,       @w_abd_cotizacion_mpg,
         @w_abd_cotizacion_mop,  @w_abd_tcotizacion_mpg, @w_cp_afectacion
end

close cursor_abonos
deallocate cursor_abonos

return 0
go
