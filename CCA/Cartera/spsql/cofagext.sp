/************************************************************************/
/*   Archivo            :     cofagext.sp                               */
/*   Stored procedure   :     sp_creaop_reconoc_fag_ext                 */
/*   Base de datos      :     cob_cartera                               */
/*   Producto           :     Credito y Cartera                         */
/*   Disenado por       :     Luis Alfonso Mayorga                      */
/*   Fecha de escritura :     Dic 2002                                  */
/************************************************************************/
/*                        IMPORTANTE                                    */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                        PROPOSITO                                     */
/*   Disparar el proceso  interno para crear la  operaci¢n              */
/************************************************************************/
/*                        ACTUALIZACIONES                               */
/* jun-2004      Elcira Pelaez      linea por cada  forma de            */
/*                                  pago por reconocimeinto de          */
/*                                  Garantias especiales                */
/* nov-2005      Elcira Pelaez      defecto 5217 alternas FNG           */
/* Feb-2006      Elcira Pelaez      defecto 5999 Op.UVR                 */
/* Mar-2006      Fabian Quintero    defecto 5156 Op. FNG UVR            */
/* May-2006      Ivan Jimenez IFJ   REQ 455 - Control de Pagos          */
/*                                  Operaciones Alternas                */
/* AGO-27-2007    EPB               OPT-234- manejo de tabla para crear */
/*                                  LAs Op.alternas                     */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_creaop_reconoc_fag_ext')
   drop proc sp_creaop_reconoc_fag_ext
go

create proc sp_creaop_reconoc_fag_ext
   @s_user           login       = Null,
   @s_term           varchar(30) = Null,
   @s_date           datetime    = Null,
   @s_ofi            smallint    = Null,
   @i_fecha_proceso  datetime
as
declare 
   @w_error                   int,
   @w_sp_name                 varchar(30),
   @w_ab_operacion            int,
   @w_op_banco                cuenta,
   @w_abd_monto_mn            money,
   @w_ab_fecha_pag            datetime,
   @w_abd_concepto            catalogo,
   @w_ab_secuencial_pag       int,
   @w_moneda_pag              smallint,
   @w_moneda_origen           smallint,
   @w_monto_mon_origen        money,
   @w_cot_moneda              float,
   @w_monto_oper              money,
   @w_abd_monto_mpg           money,
   @w_registros_procesar      int,
   @w_procesados              int,
   @w_estado                  catalogo,
   @w_oficina                 smallint

select @w_sp_name = 'sp_creaop_reconoc_fag_ext'

select @w_procesados = 0

select @w_registros_procesar = isnull(count(1),0)
from ca_alternas_tmp
where alt_estado = 'I'

while @w_registros_procesar > @w_procesados
begin
   set rowcount 1
  
   select 
   @w_ab_operacion       = alt_operacion,      
   @w_op_banco           = alt_banco,          
   @w_abd_monto_mn       = alt_monto_mn,       
   @w_ab_fecha_pag       = alt_fecha_pag,      
   @w_abd_concepto       = alt_concepto,       
   @w_ab_secuencial_pag  = alt_secuencial_pag, 
   @w_moneda_pag         = alt_moneda,         
   @w_abd_monto_mpg      = alt_monto_mpg      
   from   ca_alternas_tmp
   where  alt_estado = 'I'
    
   set rowcount 0   
   select @w_estado = ab_estado
   from   ca_abono
   where  ab_operacion      = @w_ab_operacion
   and    ab_secuencial_pag = @w_ab_secuencial_pag
      
   select 
   @w_moneda_origen = op_moneda,
   @w_oficina       = op_oficina
   from   ca_operacion
   where  op_operacion = @w_ab_operacion
   
   select @w_monto_oper = @w_abd_monto_mpg
   
   if @w_moneda_origen != @w_moneda_pag
   begin -- CONVERTIR EL MONTO DE LA MONEDA DEL PAGO A LA MONEDA ORIGEN
      exec @w_error = sp_conversion_moneda
      @s_date             = 'jan 1 1971',
      @i_opcion           = 'L',
      @i_fecha            = @w_ab_fecha_pag,
      @i_moneda_monto     = @w_moneda_pag,
      @i_moneda_resultado = @w_moneda_origen,
      @i_monto            = @w_abd_monto_mn,
      @o_monto_resultado  = @w_monto_mon_origen out,
      @o_tipo_cambio      = @w_cot_moneda out 
      
      if @w_error <> 0
      begin
         exec sp_errorlog 
         @i_fecha      = @s_date,
         @i_error      = @w_error, 
         @i_usuario    = @s_user,
         @i_tran       = 7999,
         @i_tran_name  = @w_sp_name,
         @i_cuenta     = @w_op_banco,
         @i_anexo      = 'CREANDO OPERACIONES ALTERNAS AUTOMATICAMENTE',
         @i_rollback   = 'S'
      end
         select @w_monto_oper = @w_monto_mon_origen
   end
   ELSE
   select @w_monto_oper = @w_abd_monto_mn
  
   if @w_estado = 'A'
   begin
       --begin TRAN
      exec @w_error = sp_creaop_reconoc_fag_int
      @s_user              = @s_user,
      @s_date              = @i_fecha_proceso,
      @s_term              = @s_term,
      @s_ofi               = @w_oficina,
      @i_operacionca       = @w_ab_operacion,
      @i_monto_mn          = @w_monto_oper,
      @i_fecha_proceso     = @w_ab_fecha_pag,
      @i_abd_concepto      = @w_abd_concepto
     
      if @w_error <> 0 
      begin
         exec sp_errorlog 
         @i_fecha      = @s_date,
         @i_error      = @w_error, 
         @i_usuario    = @s_user,
         @i_tran       = 7999,
         @i_tran_name  = @w_sp_name,
         @i_cuenta     = @w_op_banco,
         @i_anexo      = 'CREANDO OPERACIONES ALTERNAS AUTOMATICAMENTE',
         @i_rollback   = 'S'
      
         update ca_alternas_tmp
         set   alt_estado = 'E'
         where alt_operacion = @w_ab_operacion
         and   alt_secuencial_pag = @w_ab_secuencial_pag   
         if @@error <> 0
            return 710002 
         
         GOTO SIGUIENTE
      end
      ELSE
      begin
         --MARCAR EL ABONO COMO YA ¨PROCESADO PARA  LA CREACION DE LA ALTERNA         
         update ca_alternas_tmp
         set   alt_estado = 'P'   ---PROCESADO
         where alt_operacion      = @w_ab_operacion
         and   alt_secuencial_pag = @w_ab_secuencial_pag     
         if @@error <> 0
            return 710002                 
         GOTO SIGUIENTE
      end                 
      --COMMIT TRAN
   end      
   ELSE
   begin
      ---BORRARLO POR QUE YA NO SE REQUIERE FUE REVERASDO      
      update ca_alternas_tmp
      set   alt_estado = 'E'   ---PROCESADO
      where alt_operacion      = @w_ab_operacion
      and   alt_secuencial_pag = @w_ab_secuencial_pag  
      if @@error <> 0
         return 710002
      GOTO SIGUIENTE
   end     
   SIGUIENTE:   
   select @w_procesados =   @w_procesados + 1  
end ---while

return 0

go
