/************************************************************************/
/*Archivo:                  pagopint.sp                                 */
/*Stored procedure:         sp_genera_pago_pasiva_int                   */
/*Base de datos:            cob_cartera                                 */
/*Producto:                 Cartera                                     */
/*Disenado por:             Elcira Pelaez Burbano                       */
/*Fecha de escritura:       Feb-2003                                    */
/************************************************************************/
/*                              IMPORTANTE                              */
/*Este programa es parte de los paquetes bancarios propiedad de         */
/*"MACOSA".                                                             */
/*Su uso no autorizado queda expresamente prohibido asi como            */
/*cualquier alteracion o agregado hecho por alguno de sus               */
/*usuarios sin el debido consentimiento por escrito de la               */
/*Presidencia Ejecutiva de MACOSA o su representante.                   */
/************************************************************************/  
/*                                 PROPOSITO                            */
/*Procedimiento que realiza la insercion de registros para              */
/*realizar abonos de la cartera Pasiva, este sp es ejecutado            */ 
/*      por sp_genera_pago_pasiva                                       */
/*                               CAMBIOS                                */
/*    FECHA         AUTOR                     CAMBIO                    */
/*   20/10/2021   G. Fernandez       Ingreso de nuevo campo de          */
/*                                       solidario en ca_abono_det      */
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_genera_pago_pasiva_int')
   drop proc sp_genera_pago_pasiva_int
go

create proc sp_genera_pago_pasiva_int
@s_user                 login,
@s_term                 varchar(30),
@s_ofi                  smallint,
@s_date                 datetime,
@i_operacionca          int,
@i_cd_dividendo         int,
@i_aceptar_anticipos    char(1) = null,
@i_tipo_reduccion       char(1) = null,
@i_tipo_cobro           char(1) = null,
@i_tipo_aplicacion      char(1) = null,
@i_oficina              smallint = null,
@i_forma_pago           catalogo = null,
@i_cuenta               cuenta   = null,
@i_retencion            smallint = null,
@i_moneda_pag           smallint = null, 
@i_banco                cuenta   = null,
@i_fecha_proceso        datetime = null,
@i_cheque               int         = null,
@i_cod_banco            catalogo    = null ,
@i_cotizacion           float       = null,
@i_cd_abono_capital     money       = null,
@i_cd_abono_interes     money       = null

as
declare 
@w_secuencial           int,
@w_error                int,
@w_return               int,
@w_sp_name              descripcion,
@w_concepto             catalogo,
@w_prioridad            int,
@w_monto                money,
@w_op_moneda            smallint,
@w_num_dec              smallint,
@w_abd_monto_mpg        money,
@w_moneda_n             smallint,
@w_abd_cotizacion_mpg   money,
@w_abd_monto_mn         money,
@w_num_dec_n            smallint,
@w_cotizacion_mop       float,
@w_moneda_nacional      smallint,
@w_op_fecha_ult_proceso  datetime,
@w_monto_mop             money



-- CARGADO DE VARIABLES DE TRABAJO 
select 
@w_sp_name = 'sp_genera_pago_pasiva_int', 
@w_monto_mop         = 0


-- INFORMACION DE OPERACION 
select 
@w_op_moneda            = op_moneda,
@w_op_fecha_ult_proceso = op_fecha_ult_proceso
from  ca_operacion
where op_operacion   = @i_operacionca

select @w_moneda_nacional = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'
set transaction isolation level read uncommitted
       
--- LECTURA DE DECIMALES 
exec @w_return = sp_decimales
@i_moneda       = @w_op_moneda,
@o_decimales    = @w_num_dec out,
@o_mon_nacional = @w_moneda_n out,
@o_dec_nacional = @w_num_dec_n out
if @w_return != 0 
  return  @w_return


exec @w_secuencial = sp_gen_sec 
@i_operacion  = @i_operacionca

  
 select @w_monto = isnull(@i_cd_abono_capital,0) + isnull(@i_cd_abono_interes,0)


 if @w_monto > 0 
 begin  ---2

         --CONVERSION DEL MONTO CALCULADO A LA MONEDA DE PAGO Y OPERACION **
         select @w_abd_cotizacion_mpg = 1.0              
         

         if @w_op_moneda  =  @w_moneda_nacional  
         begin    
              -- DETERMINAR EL VALOR DE COTIZACION DEL DIA
              select @w_abd_monto_mpg = @w_monto
              select @w_abd_monto_mn  = @w_monto
              select @w_cotizacion_mop = 1.0
              select @w_monto_mop     = @w_monto 
         end   

         else

         begin
            select @w_cotizacion_mop = @i_cotizacion
            select @w_abd_monto_mpg = round(@w_monto ,@w_num_dec_n)   
            select @w_abd_monto_mn  = round(@w_monto ,@w_num_dec_n)       
            select @w_monto_mop     = @w_monto / @i_cotizacion
            
         end
           
           
           insert ca_abono ( 
           ab_secuencial_ing, ab_secuencial_rpa,     ab_secuencial_pag, 
           ab_operacion,      ab_fecha_ing,          ab_fecha_pag,  
           ab_cuota_completa, ab_aceptar_anticipos,  ab_tipo_reduccion, 
           ab_tipo_cobro,     ab_dias_retencion_ini, ab_dias_retencion, 
           ab_estado,         ab_usuario,            ab_oficina,
           ab_terminal,       ab_tipo,               ab_tipo_aplicacion,
           ab_nro_recibo )
           values (
           @w_secuencial,     0,                     0,
           @i_operacionca,    @i_fecha_proceso,      @i_fecha_proceso,
           'N',               @i_aceptar_anticipos,  @i_tipo_reduccion,
           @i_tipo_cobro,     @i_retencion,          @i_retencion,
           'ING',             @s_user,               @s_ofi,
           @s_term,           'PAG',                 @i_tipo_aplicacion,
           0)

           if @@error != 0  return 710294

    
           insert into ca_abono_det (
           abd_secuencial_ing,    abd_operacion,       abd_tipo,
           abd_concepto,
           abd_cuenta,            abd_beneficiario,    abd_moneda,
           abd_monto_mpg,         abd_monto_mop,       abd_monto_mn,
           abd_cotizacion_mpg,    abd_cotizacion_mop,  abd_tcotizacion_mpg,
           abd_tcotizacion_mop,   abd_cheque,          abd_cod_banco,
		   abd_solidario)                                                   --GFP 19/10/2021 Ingreso de nuevo campo para identificacion de pago solidario
           values (
           @w_secuencial,         @i_operacionca,     'PAG',
           @i_forma_pago,
           @i_cuenta,             'PAGO AUTOMATICO PASIVAS', @i_moneda_pag,
           @w_abd_monto_mpg,      @w_monto_mop,              @w_abd_monto_mn,
           @w_abd_cotizacion_mpg, @w_cotizacion_mop,   'N',
           'N',   @i_cheque,           @i_cod_banco,
		   'N') 

           if @@error != 0 return 710295

           select @w_concepto = ' '
 

           while 1=1 
           begin --3
      set rowcount 1

     select
     @w_concepto  = ro_concepto,
     @w_prioridad = ro_prioridad
     from ca_rubro_op
     where ro_operacion = @i_operacionca
     and   ro_fpago not in ('L','B')
     and   ro_concepto > @w_concepto
     order by ro_concepto
  
     if @@rowcount = 0 begin
       set rowcount 0
       break
        end
     
    set rowcount 0

    insert into ca_abono_prioridad (
    ap_secuencial_ing, ap_operacion,     ap_concepto, 
            ap_prioridad) 
    values (
    @w_secuencial,     @i_operacionca,   @w_concepto,
            @w_prioridad)
    
            if @@error != 0 return 710225
     end --3
     end  --2

return 0

go
