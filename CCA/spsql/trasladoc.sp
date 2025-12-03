/************************************************************************/
/*   Nombre Fisico:        trasladoc.sp                                 */
/*   Nombre Logico:        sp_trasladador_convivencia                   */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Credito y Cartera                            */
/*   Disenado por:         Elcira Pelaez Burbano                        */
/*   Fecha de escritura:   28/08/2003                                   */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios que son       	*/
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  	*/
/*   representantes exclusivos para comercializar los productos y   	*/
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida 	*/
/*   y regida por las Leyes de la República de España y las         	*/
/*   correspondientes de la Unión Europea. Su copia, reproducción,  	*/
/*   alteración en cualquier sentido, ingeniería reversa,           	*/
/*   almacenamiento o cualquier uso no autorizado por cualquiera    	*/
/*   de los usuarios o personas que hayan accedido al presente      	*/
/*   sitio, queda expresamente prohibido; sin el debido             	*/
/*   consentimiento por escrito, de parte de los representantes de  	*/
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  	*/
/*   en el presente texto, causará violaciones relacionadas con la  	*/
/*   propiedad intelectual y la confidencialidad de la información  	*/
/*   tratada; y por lo tanto, derivará en acciones legales civiles  	*/
/*   y penales en contra del infractor según corresponda. 				*/
/************************************************************************/
/*                                PROPOSITO                             */
/*   Traslada saldos por operacion y transaccion recibidos como         */
/*      parametros  de entrada                                          */
/************************************************************************/
/*                               CAMBIOS                                */
/*		Fecha			Autor					Razon					*/
/*    06/06/2023	 M. Cordova		 Cambio variable @w_calificacion,   */
/*									 de char(1) a catalogo 				*/
/*    07/11/2023     K. Rodriguez     Actualiza valor despreciab        */  
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_trasladador_convivencia')
   drop proc sp_trasladador_convivencia
go

create proc sp_trasladador_convivencia
   @s_user              login,
   @s_term              varchar(30),
   @s_date              datetime,
   @s_ofi               smallint,
   @i_trn               catalogo,
   @i_toperacion        catalogo,
   @i_oficina           smallint,
   @i_banco             cuenta,
   @i_moneda            tinyint,
   @i_fecha_proceso     datetime,
   @i_moneda_nac        smallint,
   @i_garantia          char(1)  = '',
   @i_reestructuracion  char(1)  = '',
   @i_cuenta_final      char(20) = '',
   @i_cuenta_antes      char(20) = '',
   @i_estado_final      int      = null,
   @i_calificacion      catalogo  = '',
   @i_secuencial        int

as 
declare
   @w_concepto             catalogo,
   @w_monto_vigente        money,
   @w_monto_suspenso       money,
   @w_monto_castigado      money,
   @w_monto_mn             money,
   @w_cot_mn               money,
   @w_observacion          varchar(255),
   @w_am_estado            tinyint,
   @w_categoria            catalogo,
   @w_codvalor_final       int,
   @w_codvalor_antes       int,
   @w_codvalor_trc         int,
   @w_codvalor             int,
   @w_co_codigo            int,
   @w_ro_fpago             char(1),
   @w_moneda_uvr           tinyint,
   @w_est_suspenso         int,
   @w_co_monto             money,
   @w_co_concepto          catalogo,
   @w_estado               int,
   @w_moneda               int,
   @w_capitalizado_sus     money,
   @w_vlr_despreciable     float,
   @w_num_dec              int,
   @w_moneda_n             int,
   @w_num_dec_n            int,
   @w_error                int,
   @w_fecha_ult_proceso    datetime,
   @w_tiene_diferidos      char(1),
   @w_dividendo            int,
   @w_est_vigente          int,
   @w_est_castigado        int,
   @w_rowcount             int,
   @w_ced_ruc              varchar(10),
   @w_tipo_doc             varchar(5),
   @w_cliente              int, 
   @w_clase                varchar(10)  

select @w_tiene_diferidos = 'N'

-- LECTURA DE DECIMALES
exec @w_error         =  sp_decimales
     @i_moneda        =  @i_moneda,
     @o_decimales     =  @w_num_dec   out,
     @o_mon_nacional  =  @w_moneda_n  out,
     @o_dec_nacional  =  @w_num_dec_n out

if @w_error != 0 
   return @w_error

select @w_num_dec  = isnull(@w_num_dec,0)

select @w_vlr_despreciable = 1.0 / power(10, (@w_num_dec + 2))
   
-- CARGAR VARIABLES DE TRABAJO
select @w_observacion   = 'TRASLADO DE SALDOS POR ' + cast(@i_trn as varchar)

select @w_est_vigente = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'VIGENTE'

select @w_est_suspenso  = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'SUSPENSO'

select @w_est_castigado  = isnull(es_codigo, 255)
from   cob_cartera..ca_estado
where  rtrim(ltrim(es_descripcion)) = 'CASTIGADO'


-- GENERAR DETALLE CON TODOS LOS CONCEPTOS
declare cursor_rubros_general cursor for
select dr_concepto, round(dr_valor_vigente,@w_num_dec), round(dr_valor_suspenso, @w_num_dec), round(dr_valor_castigado, @w_num_dec), co_codigo
from   cob_credito..cr_dato_operacion_rubro,
       cob_cartera..ca_concepto
where  dr_fecha    = @i_fecha_proceso
and    dr_banco    = @i_banco
and    co_concepto = dr_concepto
and   (round(dr_valor_vigente,@w_num_dec) > @w_vlr_despreciable or round(dr_valor_suspenso, @w_num_dec) > @w_vlr_despreciable or round(dr_valor_castigado, @w_num_dec) > @w_vlr_despreciable)
for read only

open  cursor_rubros_general
fetch cursor_rubros_general
into  @w_concepto, @w_monto_vigente, @w_monto_suspenso, @w_monto_castigado, @w_codvalor

while @@fetch_status = 0
begin
   if (@@fetch_status = -1)
   begin
      PRINT 'traslado.sp  no hay datos en el cursor @i_banco ' + @i_banco
      return 710004
   end

   if @w_monto_vigente > @w_vlr_despreciable
   begin
      select @w_estado         = @w_est_vigente 
      select @w_codvalor_antes = @w_codvalor * 1000 + @w_estado * 10
      select @w_codvalor_final = @w_codvalor * 1000 + @w_estado * 10

      --- ANTERIOR
      insert into ca_det_trn_bancamia (
      dtr_secuencial,          dtr_banco,                  dtr_dividendo,
      dtr_concepto,            dtr_estado,                 dtr_periodo,  
      dtr_codvalor,            dtr_monto,                  dtr_monto_mn,
      dtr_moneda,              dtr_cotizacion,             dtr_tcotizacion,
      dtr_afectacion,          dtr_cuenta,                 dtr_beneficiario,
      dtr_monto_cont)          
      values (                 
      @i_secuencial,           @i_banco,                   1,
      @w_concepto,             @w_estado,                  0,
      @w_codvalor_antes,       @w_monto_vigente*-1,        @w_monto_vigente*-1,
      @i_moneda,               1.0,                        'N',
      'D',                     isnull(@i_cuenta_antes,''), '',
      0)
         
      if @@error <> 0
      begin
         PRINT 'trasladoc.sp  error insertando en ca_det_trn 1 '
         return 710001
      end

      ----NUEVA
      insert into ca_det_trn_bancamia (
      dtr_secuencial,          dtr_banco,                  dtr_dividendo,
      dtr_concepto,            dtr_estado,                 dtr_periodo,  
      dtr_codvalor,            dtr_monto,                  dtr_monto_mn,
      dtr_moneda,              dtr_cotizacion,             dtr_tcotizacion,
      dtr_afectacion,          dtr_cuenta,                 dtr_beneficiario,
      dtr_monto_cont)          
      values (                 
      @i_secuencial,           @i_banco,                   1,
      @w_concepto,             @w_estado,                  0,
      @w_codvalor_final,       @w_monto_vigente,           @w_monto_vigente,
      @i_moneda,               1.0,                        'N',
      'D',                     isnull(@i_cuenta_final,''), '',
      0)

      if @@error <> 0
      begin
         PRINT 'trasladoc.sp  error insertando en ca_det_trn 2 '
         return 710001
      end
   end
   
   if @w_monto_suspenso > @w_vlr_despreciable
   begin
      select @w_estado         = @w_est_suspenso 
      select @w_codvalor_antes = @w_codvalor * 1000 + @w_estado * 10
      select @w_codvalor_final = @w_codvalor * 1000 + @w_estado * 10

      --- ANTERIOR
      insert into ca_det_trn_bancamia (
      dtr_secuencial,          dtr_banco,                  dtr_dividendo,
      dtr_concepto,            dtr_estado,                 dtr_periodo,  
      dtr_codvalor,            dtr_monto,                  dtr_monto_mn,
      dtr_moneda,              dtr_cotizacion,             dtr_tcotizacion,
      dtr_afectacion,          dtr_cuenta,                 dtr_beneficiario,
      dtr_monto_cont)          
      values (                 
      @i_secuencial,           @i_banco,                   1,
      @w_concepto,             @w_estado,                  0,
      @w_codvalor_antes,       @w_monto_suspenso*-1,       @w_monto_suspenso*-1,
      @i_moneda,               1.0,                        'N',
      'D',                     isnull(@i_cuenta_antes,''), '',
      0)
         
      if @@error <> 0
      begin
         PRINT 'trasladoc.sp  error insertando en ca_det_trn 3 '
         return 710001
      end

      ----NUEVA
      insert into ca_det_trn_bancamia (
      dtr_secuencial,           dtr_banco,                  dtr_dividendo,
      dtr_concepto,             dtr_estado,                 dtr_periodo,  
      dtr_codvalor,             dtr_monto,                  dtr_monto_mn,
      dtr_moneda,               dtr_cotizacion,             dtr_tcotizacion,
      dtr_afectacion,           dtr_cuenta,                 dtr_beneficiario,
      dtr_monto_cont)           
      values (                  
      @i_secuencial,            @i_banco,                   1,
      @w_concepto,              @w_estado,                  0,
      @w_codvalor_final,        @w_monto_suspenso,          @w_monto_suspenso,
      @i_moneda,                1.0,                        'N',
      'D',                      isnull(@i_cuenta_final,''), '',
      0)

      if @@error <> 0
      begin
         PRINT 'trasladoc.sp  error insertando en ca_det_trn 4 '
         return 710001
      end
   end

   if @w_monto_castigado > @w_vlr_despreciable
   begin
      select @w_estado         = @w_est_castigado
      select @w_codvalor_antes = @w_codvalor * 1000 + @w_estado * 10
      select @w_codvalor_final = @w_codvalor * 1000 + @w_estado * 10

      --- ANTERIOR
      insert into ca_det_trn_bancamia (
      dtr_secuencial,        dtr_banco,                  dtr_dividendo,
      dtr_concepto,          dtr_estado,                 dtr_periodo,  
      dtr_codvalor,          dtr_monto,                  dtr_monto_mn,
      dtr_moneda,            dtr_cotizacion,             dtr_tcotizacion,
      dtr_afectacion,        dtr_cuenta,                 dtr_beneficiario,
      dtr_monto_cont)        
      values (               
      @i_secuencial,         @i_banco,                   1,
      @w_concepto,           @w_estado,                  0,
      @w_codvalor_antes,     @w_monto_castigado*-1,      @w_monto_castigado*-1,
      @i_moneda,             1.0,                        'N',
      'D',                   isnull(@i_cuenta_antes,''), '',
      0)
         
      if @@error <> 0
      begin
         PRINT 'trasladoc.sp  error insertando en ca_det_trn 5 '
         return 710001
      end

      ----NUEVA
      insert into ca_det_trn_bancamia (
      dtr_secuencial,        dtr_banco,                  dtr_dividendo,
      dtr_concepto,          dtr_estado,                 dtr_periodo,  
      dtr_codvalor,          dtr_monto,                  dtr_monto_mn,
      dtr_moneda,            dtr_cotizacion,             dtr_tcotizacion,
      dtr_afectacion,        dtr_cuenta,                 dtr_beneficiario,
      dtr_monto_cont)        
      values (               
      @i_secuencial,         @i_banco,                   1,
      @w_concepto,           @w_estado,                  0,
      @w_codvalor_final,     @w_monto_castigado,         @w_monto_castigado,
      @i_moneda,             1.0,                        'N',
      'D',                   isnull(@i_cuenta_final,''), '',
      0)

      if @@error <> 0
      begin
         PRINT 'trasladoc.sp  error insertando en ca_det_trn 6 '
         return 710001
      end
   end

   fetch cursor_rubros_general
   into  @w_concepto, @w_monto_vigente, @w_monto_suspenso, @w_monto_castigado, @w_codvalor
end -- WHILE CURSOR

close cursor_rubros_general
deallocate cursor_rubros_general

insert into ca_transaccion_bancamia
      (tr_secuencial,          tr_fecha_mov,                   tr_toperacion,
       tr_moneda,              tr_operacion,                   tr_tran,
       tr_en_linea,            tr_banco,                       tr_dias_calc,
       tr_ofi_oper,            tr_ofi_usu,                     tr_usuario,
       tr_terminal,            tr_fecha_ref,                   tr_secuencial_ref,
       tr_estado,              tr_observacion,                 tr_gerente,
       tr_gar_admisible,       tr_reestructuracion,            tr_calificacion,
       tr_fecha_cont,          tr_comprobante,             tr_fecha_real)  
values(@i_secuencial,          @s_date,                        @i_toperacion,
       @i_moneda,              0,                              @i_trn,
       'N',                    @i_banco,                       0,
       @i_oficina,             @i_oficina,                     @s_user,
       @s_term,                @i_fecha_proceso,               0,
       'ING',                  @w_observacion,                 0,
       isnull(@i_garantia,''), isnull(@i_reestructuracion,''), isnull(@i_calificacion,''),
       @i_fecha_proceso,       0,                  getdate())

if @@error != 0
begin
   PRINT 'trasladoc.sp  error insertando en ca_transaccion_bancamia'
   return 708165
end

select @w_cliente    = do_codigo_cliente,
       @w_tipo_doc   = do_clase_cartera
from   cob_credito..cr_dato_operacion
where  do_fecha                  = @i_fecha_proceso
and    do_tipo_reg               = 'M'
and    do_codigo_producto        = 7
and    do_numero_operacion_banco = @i_banco

select @w_ced_ruc  = en_ced_ruc,
       @w_tipo_doc = en_tipo_ced
from   cobis..cl_ente 
where  en_ente = @w_cliente

if not exists (select 1 from ca_operacion_bancamia
               where  op_ced_ruc  = @w_ced_ruc
               and    op_tipo_doc = @w_tipo_doc
               and    op_banco    = @i_banco)
begin
   insert into ca_operacion_bancamia
   (op_ced_ruc, op_tipo_doc, op_clase, 
    op_estado,  op_sector,   op_banco, op_ente)
   values 
   (@w_ced_ruc, @w_tipo_doc, @w_tipo_doc,
    1,'1',@i_banco,@w_cliente)

   if @@error != 0
   begin
      PRINT 'trasladoc.sp  error insertando en ca_operacion_bancamia'
      return 708165
   end
end



return 0
go

