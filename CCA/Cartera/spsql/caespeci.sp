/************************************************************************/
/*      Archivo:             caespeci.sp                                */
/*      Stored procedure:    sp_reporte_oper_especiales                 */
/*      Base de datos:       cob_cartera                                */
/*      Producto:            Cartera                                    */
/*      Disenado por:        EPB                                        */
/*      Fecha de escritura:  Julio 2004                                 */
/************************************************************************/
/*                            IMPORTANTE                                */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                                 PROPOSITO                            */
/*Almacena informacion para el reprote de obligaciones que nacen por    */
/*el pago de un reconocimiento de garnatias                             */
/************************************************************************/
/*                            MODIFICACIONES                            */
/*      FECHA           AUTOR             RAZON                         */
/*      May-2006         Ivan Jimenez IFJ   REQ 455 - Control de Pagos  */
/*                                          Operaciones Alternas        */
/*      MAr-2007         Elcira Pelaez B    REQ 455 almacenar new campos*/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_reporte_oper_especiales')
   drop proc sp_reporte_oper_especiales
go

create proc sp_reporte_oper_especiales
@i_fecha_proceso  datetime,
@i_opcion         int  = 0
as
declare 
 @w_sp_name             varchar(32),
 @w_op_oficina          smallint,
 @w_op_fecha_liq        datetime,
 @w_op_banco            cuenta,
 @w_op_toperacion       catalogo,
 @w_op_monto            money,
 @w_op_nombre           descripcion,
 @w_op_operacion        int,
 @w_op_cliente          int,
 @w_en_ced_ruc          numero,
 @w_sec                 int,
 @w_op_estado           tinyint,
 @w_fpago_nueva         catalogo,
 @w_fecha_pago          datetime,
 @w_valor_pago          money,
 @w_error               int,
 @w_fpago               catalogo,
 @w_fecha_cartera       datetime,
 @w_valorpag_cap        money,
 @w_valorpag_int        money,
  @w_rep_num_oper_original     cuenta,
 @w_oa_operacion_original   int,
 @w_oa_garantia             descripcion,
 @w_oa_fpago                catalogo,
 @w_oa_monto_alterna        money
 
select  @w_sp_name       = 'sp_reporte_oper_especiales',
         @w_fpago_nueva   = '',
         @w_fecha_pago    = null,
         @w_valor_pago    = 0

         
  ---INICIALIZA TABLA DE REPORTES
  delete tmp_gar_esp_reporte where spid = @@spid
  truncate table ca_reporte_oper_especiales
  
  select @w_fecha_cartera = fc_fecha_cierre
  from cobis..ba_fecha_cierre
  where fc_producto = 7
  
 
  
   --LAS OBLIGACIONES QUE ESTEN PARAMETRIZADDAS EN LA TABLA DE ca_especiales de cl_talba
   --ESTAS SON LAS CREADAS AUTOMATICAMENTE POR batch
   
   declare operacionse_g  cursor for
     select op_oficina,
            op_fecha_liq,
            op_banco,
            op_toperacion,
            op_monto,
            op_nombre,
            op_operacion,
            op_cliente,
            op_estado
   from cobis..cl_catalogo,
   cob_cartera..ca_operacion
   where tabla = (select codigo from cobis..cl_tabla
                   where tabla = 'ca_especiales')
   and  valor = op_toperacion
   and op_estado not in (0,6,99,98)
   for read only

   open operacionse_g
   fetch operacionse_g into
   
    @w_op_oficina,
    @w_op_fecha_liq,
    @w_op_banco,
    @w_op_toperacion,
    @w_op_monto,
    @w_op_nombre,
    @w_op_operacion,
    @w_op_cliente,
    @w_op_estado

      while (@@fetch_status = 0 )
      begin
         ---DATOS GENERALES
         
               select @w_valorpag_cap =  isnull(sum(dtr_monto_mn),0)
               from  ca_transaccion,
                     ca_det_trn
               where tr_operacion   = @w_op_operacion
               and   tr_fecha_mov   <= @i_fecha_proceso
               and   tr_tran        = 'PAG'
               and   tr_estado     != 'RV'
               and   dtr_concepto   = 'CAP'
               and    dtr_codvalor != 10099                                   
               and    dtr_codvalor != 10019                                   
               and    dtr_codvalor != 10370                                   
               and    dtr_codvalor != 10990                                   
               and    dtr_codvalor != 21370                                   
               and    dtr_codvalor != 19370  --ENE-24-2007-EPB DEF-BAC NRO 778
               and    dtr_codvalor != 52370 --ENE-24-2007-EPB DEF-BAC NRO 7784
   
   
               select @w_valorpag_int =  isnull(sum(dtr_monto_mn),0)
               from  ca_transaccion,
                     ca_det_trn
               where tr_operacion  = @w_op_operacion
               and   tr_fecha_mov  <= @i_fecha_proceso
               and   tr_tran       = 'PAG'
               and   tr_estado    != 'RV'
               and   dtr_concepto  = 'INT'
   
   
   
               --CEDULA DEL CLIENTE
               select @w_en_ced_ruc = en_ced_ruc
               from cobis..cl_ente
               where en_ente = @w_op_cliente
               
               select @w_sec = isnull(max(ar_secuencial),0)
               from ca_abono_rubro
               where ar_operacion = @w_op_operacion
               and   ar_fecha_pag  <= @w_fecha_cartera
               
               if @w_sec > 0
               begin
                  select @w_fpago_nueva = ar_concepto,
                         @w_fecha_pago  = ar_fecha_pag,
                         @w_valor_pago  = ar_monto_mn
                  from ca_abono_rubro,ca_producto
                  where ar_operacion =  @w_op_operacion
                  and   ar_secuencial  = @w_sec
                  and   cp_producto    = ar_concepto
               end
               else
               begin
                  select  @w_fpago_nueva   = '',
                          @w_fecha_pago    = null,
                          @w_valor_pago    = 0
               end
         
         
            ---FIN DATOS GENERALES
            
            
            
             declare operacionse_alt  cursor for
             select isnull(oa_operacion_original,0),
                    isnull(oa_garantia,'NO TIENE'),
                    isnull(oa_fpago, 'NO TIENE'),---con la que se creo la alterna
                    oa_monto_alterna
            
             from  ca_operacion_alterna 
             where oa_operacion_alterna = @w_op_operacion
             order by oa_fpago
             for read only
            
            
               open operacionse_alt
               fetch operacionse_alt into
               
               @w_oa_operacion_original,
               @w_oa_garantia,
               @w_oa_fpago,
               @w_oa_monto_alterna
               
               while @@fetch_status   not in (-1,0)
               begin
            
                  select @w_rep_num_oper_original = op_banco
                  from ca_operacion
                  where op_operacion = @w_oa_operacion_original
                  
                  if @@rowcount = 0
                     select @w_rep_num_oper_original = 'NO SE TIENE'
                  
                                 
                  insert into ca_reporte_oper_especiales  (   
                     rep_operacion,
                     rep_toperacion,            rep_oficina,            rep_banco,
                     rep_ced_ruc,               rep_nombre,             rep_forma_pago,
                     rep_fecha_liq,             rep_monto,              rep_forma_pago_nueva,
                     rep_fecha_pago,            rep_valor_pago,         rep_estado,
                     rep_num_oper_original,     rep_valor_capital_pag,             
                     rep_valor_int_pag,         rep_numero_cer_gar               
                     )
                  values
                     (
                     @w_op_operacion,
                     @w_op_toperacion,             @w_op_oficina,       @w_op_banco,
                     @w_en_ced_ruc,                @w_op_nombre,        @w_oa_fpago,
                     @w_op_fecha_liq,              @w_op_monto,         @w_fpago_nueva,
                     @w_fecha_pago,                @w_valor_pago,       @w_op_estado,
                     @w_rep_num_oper_original,     @w_valorpag_cap,   
                     @w_valorpag_int,              @w_oa_garantia  
                     )

            
                  fetch operacionse_alt into
                  
                      @w_oa_operacion_original,
                      @w_oa_garantia,
                      @w_oa_fpago,
                      @w_oa_monto_alterna
                  
               end
               
               close operacionse_alt
               deallocate operacionse_alt
        


  fetch operacionse_g into
    @w_op_oficina,
    @w_op_fecha_liq,
    @w_op_banco,
    @w_op_toperacion,
    @w_op_monto,
    @w_op_nombre,
    @w_op_operacion,
    @w_op_cliente,
    @w_op_estado

end

close operacionse_g
deallocate operacionse_g

PRINT 'caespeci.sp ...Fin del proceso'

return 0
go

