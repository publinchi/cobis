/************************************************************************/
/*  Archivo:        				cargamas.sp				            */
/*  Stored procedure:   			sp_cargar_pagos_masivos         	*/
/*  Base de datos:      			cob_cartera             			*/
/*  Producto:       			    Cartera                 		    */
/*  Disenado por:       			Elcira Pelaez Burbano           	*/
/*  Fecha de escritura:     		abril -2001             			*/
/************************************************************************/
/*              					IMPORTANTE              			*/
/*  Este programa es parte de los paquetes bancarios propiedad de   	*/
/*  "MACOSA"                            								*/
/*  Su uso no autorizado queda expresamente prohibido asi como  		*/
/*  cualquier alteracion o agregado hecho por alguno de sus     		*/
/*  usuarios sin el debido consentimiento por escrito de la     		*/
/*  Presidencia Ejecutiva de MACOSA o su representante.     			*/
/************************************************************************/  
/*              					PROPOSITO               			*/
/*  Cargar Informacion de pagos masivos  a tablas  temporales       	*/
/*  e historicas de manejo de pagos masivos para convenios          	*/
/*      LAS OPERACIONES MANEJADAS SON:                                  */
/*      'D'     Elimina las tablas temporales de procesos de abonos Mas */
/*                    ca_abono_masivo           						*/
/*                    ca_abono_masivo_det       						*/
/*                    ca_abono_masivo_prioridad         				*/
/*                    ca_abonos_masivos_his_d           				*/
/*      'I'     Inserta en las tablas ca_abono_masivo           		*/
/*                    ca_abono_masivo_det       						*/
/*                    ca_abono_masivo_prioridad         				*/
/*                    ca_abonos_masivos_his_d           				*/
/*              Validando que el cliente pertenezca a la compania       */
/*              enviada desde front-end                                 */
/*      'H'     Envia a front-end los lotes almacenados en la cabecera  */
/*              como ayuda F5 ca_abonos_masivos_his                 	*/
/*      'Q'     Valida la existencia de lotes en la tabla temporal de   */
/*              pagos masivos ca_abono_masivo                           */
/*      'S'     @i_subtipo 1  Genera el secuencial de lotes             */
/*              @i_subtipo 2  Inserta la cabecera de pagos masivos para */
/*          end ca_abonos_masivos_his               					*/
/*      'U'     Subtipo = '0' Recibe los datos si hay modificaciones    */
/*              en la grilla actualiza las tablas temporales y las      */
/*          historicas de  Pagos Masivos                				*/
/*              Subtipo = '1' Actualiza las operaciones colocandoles    */
/*          canceladas                      							*/
/*              Subtipo = '2' Pasa a definitivas el abono Masivo        */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR              RAZON                        */
/*      20/10/2021      G. Fernandez     Ingreso de nuevo campo de      */
/*                                       solidario en ca_abono_det      */
/************************************************************************/

use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_cargar_pagos_masivos')
   drop proc sp_cargar_pagos_masivos
go

create proc sp_cargar_pagos_masivos (
   @s_ssn               int         = null,
   @s_date              datetime    = null,
   @s_user              login       = null,
   @s_term              descripcion = null,
   @s_ofi               smallint    = null,
   @t_debug             char(1)     = 'N',
   @t_file          	varchar(14) = null,
   @t_trn       		smallint    = null,     
   @i_banco     		cuenta      = null,
   @i_operacion     	char(1)     = null,
   @i_subtipo       	char(1)     = null,
   @i_tipo      		char(1)     = null,
   @i_cliente       	int         = null,
   @i_compania          int         = 0,
   @i_lote              int         = 0,
   @i_cuotas            int         = null,
   @i_forma_pago        varchar(10) = null,
   @i_cedula            varchar(20) = null,
   @i_referencia        cuenta      = null,
   @i_valor             money       = null,
   @i_fecha_ing         datetime    = null,
   @i_cambio_fecha      char(1)     = null,
   @i_cambio_valor      char(1)     = null,
   @i_moneda            smallint    = null,
   @i_retencion         smallint    = 0,  
   @i_total_pago        money       = null,
   @i_estado            catalogo    = null,
   @i_cheque            int         = null,
   @i_cod_banco         catalogo    = null,
   @i_opcion            char(1)     = null,
   @i_fecha_desde       datetime    = null,
   @i_fecha_hasta       datetime    = null,
   @o_respuesta         int         = null out,
   @o_lote_gen          int         = null out

)
as
declare
  @w_sp_name          			varchar(32),
  @w_return               		int,
  @w_error                		int,
  @w_operacionca                int,
  @w_secuencial                 int,
  @w_cuota_completa             char(1),
  @w_aceptar_anticipos          char(1),
  @w_tipo_reduccion             char(1),
  @w_tipo_cobro                 char(1),          
  @w_tipo_aplicacion            char(1),
  @w_moneda                     int,
  @w_moneda_nacional            tinyint,
  @w_moneda_op                  tinyint,
  @w_pcobis                     tinyint,
  @w_numero_recibo              int,
  @w_monto_mpg                  money,
  @w_monto_mop                  money,
  @w_monto_mn                   money,
  @w_cot_moneda                 float,
  @w_cotizacion_mpg             float,
  @w_cotizacion_mop             float,
  @w_tcot_moneda                char(1),
  @w_tcotizacion_mpg            char(1),
  @w_concepto                   varchar(30),
  @w_prioridad                  int,
  @w_lote                       int,
  @w_lote_existe                int,
  @w_cliente                    int,
  @w_relacion         			char(1),
  @w_valor_relacion       		smallint,
  @w_empresa                    int,
  @w_nombre_empresa       		descripcion,
  @w_estado_historico           catalogo,
  @w_ba_fecha_cierre            datetime,
  @w_rowcount                   int

 
/*  Captura nombre de Stored Procedure  */

select  @w_sp_name = 'sp_cargar_pagos_masivos'
select  @w_relacion = 'N'

select @w_ba_fecha_cierre = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7

if @i_operacion = 'D'
begin
   select @w_estado_historico = amh_estado
   from  ca_abonos_masivos_his
   where amh_lote = @i_lote

   if @w_estado_historico <> 'ING'
   begin
      delete ca_abono_masivo_prioridad
      from ca_abono_masivo_prioridad,
           ca_abono_masivo
      where amp_secuencial_ing = abm_secuencial_ing
      and amp_operacion  = abm_operacion
      and abm_lote = @i_lote
      if @@error != 0
      begin
         select @w_error = 710237
         goto ERROR
      end  

      delete ca_abono_masivo_det
      from ca_abono_masivo_det,
           ca_abono_masivo
      where abmd_secuencial_ing = abm_secuencial_ing
      and abmd_operacion  = abm_operacion
      and abm_lote = @i_lote
      if @@error != 0
      begin
         select @w_error = 710237
         goto ERROR
      end  

      delete ca_abono_masivo
      where abm_lote = @i_lote
      if @@error != 0
      begin
         select @w_error = 710235
         goto ERROR
      end  

   end  /*estado procesado <> ING */

   if @i_subtipo = '0'
   begin
      delete ca_abonos_masivos_his_d 
      where amhd_lote = @i_lote
      if @@error != 0
      begin
         select @w_error = 710242
         goto ERROR
      end   

      delete ca_abonos_masivos_his
      where amh_lote = @i_lote

   end /* subtipo '0' */

   if @i_subtipo = '2'
   begin
      /*ELIMINA EL LOTE TOTALMENTE*/

      if @i_compania = 0
      begin
         select @i_lote = amh_lote
         from  ca_abonos_masivos_his
         where amh_empresa = 0
      end


      delete ca_abono_masivo_prioridad
      from ca_abono_masivo_prioridad,
           ca_abono_masivo
      where amp_secuencial_ing = abm_secuencial_ing
      and amp_operacion  = abm_operacion
      and abm_lote = @i_lote
      if @@error != 0
      begin
         select @w_error = 710237
         goto ERROR
      end  

      delete ca_abono_masivo_det
      from ca_abono_masivo_det,
           ca_abono_masivo
      where abmd_secuencial_ing = abm_secuencial_ing
      and abmd_operacion  = abm_operacion
      and abm_lote = @i_lote
      if @@error != 0
      begin
         select @w_error = 710237
         goto ERROR
      end  

      delete ca_abono_masivo
      where abm_lote = @i_lote
      if @@error != 0
      begin
         select @w_error = 710235
         goto ERROR
      end  


      if exists (select 1 from  ca_abonos_masivos_his
                 where amh_lote = @i_lote
                 and   amh_estado  = 'ING')
      begin
         delete ca_abonos_masivos_his
         where amh_lote = @i_lote

         delete ca_abonos_masivos_his_d 
         where amhd_lote = @i_lote
         if @@error != 0
         begin
            select @w_error = 710242
            goto ERROR
         end   
      end
   end /* subtipo '2' */
end /*operacion D */

if @i_operacion = 'I' 
begin
   ---PRINT 'cargamas.sp @i_cedula %1!',@i_cedula

   select @w_cliente = en_ente
   from cobis..cl_ente
   where en_ced_ruc = @i_cedula
   set transaction isolation level read uncommitted

   select @w_moneda_nacional = pa_tinyint
   from cobis..cl_parametro
   where pa_producto = 'ADM'
   and   pa_nemonico = 'MLO'
   set transaction isolation level read uncommitted
  
   select @w_valor_relacion = pa_smallint
   from cobis..cl_parametro
   where pa_nemonico = 'R-CONV'
   and pa_producto = 'CCA'
   select @w_rowcount = @@rowcount
   set transaction isolation level read uncommitted

   if @w_rowcount =  0
   begin
      select @w_error = 710222
      goto  ERROR
   end
   
   /* FORMA DE PAGO POR DEFAULT */

   if @i_forma_pago is null
      select @i_forma_pago = cp_producto
      from ca_producto
      where cp_categoria = 'NDAH' /*Nota debito a ahorros*/

   /* CUENTA POR DEFAULT */
   if @i_referencia is null
      select @i_referencia = '000000000000'


   /* QUE LA OPERACION PERTENEZCA A LA COMPANIA DIGITADA */
   if @i_compania > 0
   begin   
      if not exists (select 1 from cobis..cl_instancia
                     where in_relacion = @w_valor_relacion
                     and   in_ente_i = @i_compania
                     and   in_ente_d = @w_cliente
                     and   in_lado   = 'D' )
      begin
         select @w_error = 710105
         goto ERROR
      end

      select
      @w_operacionca        = op_operacion,
      @w_cuota_completa     = op_cuota_completa,
      @w_aceptar_anticipos  = op_aceptar_anticipos,
      @w_tipo_reduccion     = op_tipo_reduccion,
      @w_tipo_cobro         = op_tipo_cobro,
      @w_tipo_aplicacion    = op_tipo_aplicacion ,
      @w_moneda_op          = op_moneda 
      from ca_operacion
      where  op_banco   = @i_banco
      and    op_cliente = @w_cliente
      and    op_tipo = 'V'
      and    op_estado <> 0

      if @@rowcount = 0 begin
          select @w_error = 710025
          goto ERROR
      end  

   end /*compania > 0*/
   else
   begin
      select
      @w_operacionca        = op_operacion,
      @w_cuota_completa     = op_cuota_completa, 
      @w_aceptar_anticipos  = op_aceptar_anticipos,
      @w_tipo_reduccion     = op_tipo_reduccion,
      @w_tipo_cobro         = op_tipo_cobro,
      @w_tipo_aplicacion    = op_tipo_aplicacion ,
      @w_moneda_op          = op_moneda 
      from ca_operacion
      where  op_banco   = @i_banco
      and    op_cliente = @w_cliente
      and    op_tipo <> 'V'
      and    op_estado <> 0

      if @@rowcount = 0
      begin
         select @w_error = 710025
         goto ERROR
      end  
   end


   /* CLIENTE */      
   if not exists (select 1 from cobis..cl_ente where en_ente = @w_cliente) begin
      select @w_error = 101042
      goto ERROR
   end

   begin tran

      exec @w_secuencial = sp_gen_sec 
      @i_operacion  = @w_operacionca
           
      /** GENERACION DEL NUMERO DE RECIBO **/
      exec @w_return = sp_numero_recibo
      @i_tipo    = 'P',
      @i_oficina = @s_ofi,
      @o_numero  = @w_numero_recibo out

      if @w_return != 0 begin
         select @w_error = @w_return
         goto ERROR
      end

      /* INSERCION EN CA_ABONO */

      insert into ca_abono_masivo (
      abm_lote,
      abm_operacion,      abm_fecha_ing,          abm_fecha_pag,
      abm_cuota_completa, abm_aceptar_anticipos,  abm_tipo_reduccion,
      abm_tipo_cobro,     abm_dias_retencion_ini, abm_dias_retencion,
      abm_estado,         abm_secuencial_ing,     abm_secuencial_rpa,
      abm_secuencial_pag, abm_usuario,            abm_terminal,
      abm_tipo,           abm_oficina,            abm_tipo_aplicacion,
      abm_nro_recibo,     abm_tasa_prepago,       abm_dividendo,
      abm_calcula_devolucion)

      values (
      @i_lote,
      @w_operacionca,    @w_ba_fecha_cierre,      @i_fecha_ing,
      'N',               @w_aceptar_anticipos,    @w_tipo_reduccion,
      @w_tipo_cobro,     0,                       @i_retencion,
      'ING',             @w_secuencial,           0,
      0,                 @s_user,                 @s_term,
      'PAG',             @s_ofi,                  @w_tipo_aplicacion,
      @w_numero_recibo,  0.00,                    @i_cuotas,
      'N')

      if @@error != 0 begin
         select @w_error = 710223
         goto ERROR
      end  


      select @w_concepto = ' '
      while 1=1
      begin
         set rowcount 1
         select
         @w_concepto  = ro_concepto,
         @w_prioridad = ro_prioridad
         from ca_rubro_op
         where ro_operacion = @w_operacionca
         and   ro_fpago    not in ('L','B')
         and   ro_concepto > @w_concepto
         order by ro_concepto  
         if @@rowcount = 0
         begin
            set rowcount 0
            break
         end
     
         set rowcount 0
         insert into ca_abono_masivo_prioridad (
         amp_secuencial_ing, amp_operacion,amp_concepto, amp_prioridad) 
         values (
         @w_secuencial,@w_operacionca,@w_concepto,@w_prioridad)
         
         if @@error != 0 begin
            select @w_error = 710225
            goto ERROR
         end  
      end



      exec @w_return = sp_conversion_moneda
      @s_date             = @s_date,
      @i_opcion           = 'L',
      @i_moneda_monto     = @w_moneda_op, 
      @i_moneda_resultado = @w_moneda_nacional, 
      @i_monto            = @i_valor,
      @o_monto_resultado  = @w_monto_mn out,  
      @o_tipo_cambio      = @w_cot_moneda out 

      if @w_return <> 0 begin
          select @w_error = 710001
          goto ERROR
      end


      exec @w_return = sp_conversion_moneda
      @s_date             = @s_date,
      @i_opcion           = 'L',
      @i_moneda_monto     = @w_moneda_nacional, 
      @i_moneda_resultado = @w_moneda_op, 
      @i_monto            = @w_monto_mn,
      @o_monto_resultado  = @w_monto_mop out, 
      @o_tipo_cambio      = @w_cotizacion_mop out

      if @w_return <> 0 begin
          select @w_error = 710001
          goto ERROR
      end


      /* INSERCION DE CA_ABONO_DET */

      insert into ca_abono_masivo_det (
      abmd_secuencial_ing,  abmd_operacion,    abmd_tipo,
      abmd_concepto,
      abmd_cuenta,          abmd_beneficiario, abmd_monto_mpg,
      abmd_monto_mop,       abmd_monto_mn,     abmd_cotizacion_mpg,
      abmd_cotizacion_mop,  abmd_moneda,       abmd_tcotizacion_mpg,
      abmd_tcotizacion_mop, abmd_cheque,       abmd_cod_banco )
      values (
      @w_secuencial,     @w_operacionca,      'PAG',
      @i_forma_pago,
      @i_referencia,     'PAGO MASIVO' + '_' + convert(varchar(20),@w_cliente),
      @i_valor,
      @w_monto_mop,       @w_monto_mn,       @w_cot_moneda,
      @w_cotizacion_mop,  @w_moneda_op,     'C',
      'C',            @i_cheque,         @i_cod_banco)

      if @@error != 0 begin
         select @w_error = 710224
         goto ERROR
      end  

      /*CARGAR DETALLE DE HISTORICO DE LOS  PAGOS MASIVOS */

      insert into ca_abonos_masivos_his_d (
      amhd_lote,      amhd_banco,     amhd_valor_pag,
      amhd_fecha_ing, amhd_fecha_mod, amhd_usuario )
      values (
      @i_lote,        @i_banco,   @i_valor,
      @w_ba_fecha_cierre,@w_ba_fecha_cierre,    @s_user)
      if @@error != 0 begin
         select @w_error = 710227
         goto ERROR
      end  

   commit tran    
end /*operacion I */


if @i_operacion = 'H' 
begin
   if @i_tipo = '1' 
   begin
      if @i_opcion = '1'
      begin
         select 'lote'          = amh_lote,
         'Empresa'       = amh_empresa,
         'Nombre'        = substring(en_nombre,1,50),
         'Valor Cargado' = amh_valor_total,
         'Fecha'         = amh_fecha_ing,
         'Estado'        = amh_estado
         from ca_abonos_masivos_his,
         cobis..cl_ente noholdlock
         where en_ente     = amh_empresa
         and   amh_fecha_ing >=  @i_fecha_desde 
         and   amh_fecha_ing <=  @i_fecha_hasta
         and   amh_lote      > @i_lote
         order by amh_lote
      
         if @@rowcount = 0 
         begin
            select @w_error = 710228
            goto ERROR
      	 end  
   	  end

      if @i_opcion = '0'
      begin
         select 
         'No. Lote'      = mc_lote,
         'Fecha Cargue'  = mc_fecha_archivo,
         'Tot.Registros' = mc_total_registros,
         'Valor Total'   = mc_monto_total,
         'Sec. Oficina'  = mc_secuencial,
         'Estado Lote'   = mc_estado,
         'Errores en la carga' = mc_errores
         from ca_abonos_masivos_cabecera
         where mc_fecha_archivo >= @i_fecha_desde
         and   mc_fecha_archivo <= @i_fecha_hasta
         and   mc_lote > @i_lote
         order by mc_lote
         
         if @@rowcount = 0 
         begin
            select @w_error = 710228
            goto ERROR
         end  
      end
   end /*tipo 1*/

   if @i_tipo = '2'
   begin

      select 'lote'          = amh_lote,
      'Fecha Ingreso' = amh_fecha_ing
      from ca_abonos_masivos_his
      where amh_estado    =  @i_estado
      order by amh_lote
      
      if @@rowcount = 0 begin
         select @w_error = 710228
         goto ERROR
      end  
   end /*tipo 2*/

   if @i_tipo = '3' 
   begin
      select @w_empresa = amh_empresa,
      @w_nombre_empresa  = substring(en_nombre,1,50)
      from ca_abonos_masivos_his,
      cobis..cl_ente noholdlock
      where en_ente     = amh_empresa
      and amh_lote = @i_lote
      and amh_estado    =  'P'
     
      if @@rowcount = 0 
      begin
         select @w_error = 710228
         goto ERROR
      end  
   end /*tipo 3*/
end /*operacion H */

if @i_operacion = 'Q' 
begin
   select @w_lote_existe = max(amh_lote)
   from  ca_abonos_masivos_his
   where amh_empresa = @i_compania
   and   amh_estado  = 'ING'
   
   if @@rowcount <> 0 
   begin
   if exists (select 1 from ca_abono_masivo
              where abm_lote = @w_lote_existe) 
              select @o_respuesta = @w_lote_existe
              select @o_respuesta    
   end
end /*operacion Q */

if @i_operacion = 'S' 
begin
   if @i_subtipo = '1' 
   begin
      exec @w_lote = sp_gen_sec 
      @i_operacion  = -2

      select @o_lote_gen = @w_lote
      select @o_lote_gen
   end /*subtipo 1 */

   if @i_subtipo = '2' 
   begin    
      /* INSETAR CABECERA  HISTORICA DE PAGO MASIVO */
      if exists (select 1 from ca_abonos_masivos_his_d
                where amhd_lote = @i_lote) begin

 
         insert into ca_abonos_masivos_his (
         amh_lote,    amh_empresa, amh_fecha_ing, amh_valor_total,amh_estado)
         values (
         @i_lote,        @i_compania,   @w_ba_fecha_cierre, 0,'ING')
         if @@error != 0 begin
            select @w_error = 710227
            goto ERROR
         end  
      end
   end /*subtipo 2 */   
end /*operacion S */


if @i_operacion = 'U' 
begin
   if @i_subtipo in ('0','1') 
   begin
      select @w_operacionca        = op_operacion
      from ca_operacion
      where  op_banco   = @i_banco
      and    op_estado <> 0
      if @@error != 0 begin
         select @w_error = 710025
         goto ERROR
      end  
   end

   begin tran

   if @i_subtipo = '0' 
   begin
      if @i_cambio_valor = 'S' 
      begin
         update ca_abono_masivo_det
         set abmd_monto_mpg = @i_valor,
         abmd_monto_mop = @i_valor,
         abmd_monto_mn  = @i_valor
         where abmd_operacion = @w_operacionca
         if @@error != 0 begin
            select @w_error = 710229
            goto ERROR
         end  
    
         update ca_abonos_masivos_his_d
         set amhd_valor_pag = @i_valor,
         amhd_fecha_mod = @w_ba_fecha_cierre,
         amhd_usuario   = @s_user
         where amhd_banco = @i_banco
         and amhd_lote  = @i_lote
         if @@error != 0 begin
            select @w_error = 710230
            goto ERROR
         end  
  	  end /*cambio valor */

      if @i_cambio_fecha  = 'S' begin
         update ca_abono_masivo
         set abm_fecha_ing = @i_fecha_ing 
         where abm_operacion = @w_operacionca
         and abm_lote      = @i_lote
         if @@error != 0 begin
            select @w_error = 710231
            goto ERROR
         end  
      
         update ca_abonos_masivos_his_d
         set amhd_fecha_mod = @w_ba_fecha_cierre,
         amhd_usuario   = @s_user
         where amhd_banco = @i_banco
         and amhd_lote  = @i_lote
         if @@error != 0 begin
            select @w_error = 710242
            goto ERROR
         end  
      end /*cambio fecha */
   end /*subtipo 0 */

   if @i_subtipo = '1' 
   begin
      update ca_abono_masivo
      set abm_estado = 'CAN'
      where abm_operacion = @w_operacionca
      and abm_lote      = @i_lote
   	  if @@error != 0 begin
   	     select @w_error = 710231
   	     goto ERROR
   	  end  

      -- BORRAR DE LA TABLA HISTORICA 

      delete ca_abonos_masivos_his_d
      where amhd_lote = @i_lote
      and   amhd_banco = @i_banco
      if @@error != 0 begin
         select @w_error = 710230
         goto ERROR
      end  
   end /*subtipo 1 */


   if @i_subtipo = '2' 
   begin
 
      --- INSERTAR EN ca_abono 
      insert into ca_abono
      (ab_secuencial_ing,            ab_secuencial_rpa,          ab_secuencial_pag,
	   ab_operacion,                 ab_fecha_ing,               ab_fecha_pag,
	   ab_cuota_completa,            ab_aceptar_anticipos,       ab_tipo_reduccion,
	   ab_tipo_cobro,                ab_dias_retencion_ini,      ab_dias_retencion,
	   ab_estado,                    ab_usuario,                 ab_oficina,
	   ab_terminal,                  ab_tipo,                    ab_tipo_aplicacion,
	   ab_nro_recibo,                ab_tasa_prepago,            ab_dividendo,
	   ab_calcula_devolucion,        ab_prepago_desde_lavigente, ab_extraordinario)
      select
      abm_secuencial_ing,            abm_secuencial_rpa,       abm_secuencial_pag,
      abm_operacion,                 abm_fecha_ing,            abm_fecha_pag,
      abm_cuota_completa,            abm_aceptar_anticipos,    abm_tipo_reduccion,
      abm_tipo_cobro,                @i_retencion,             abm_dias_retencion,
      abm_estado,                    abm_usuario,              abm_oficina,
      abm_terminal,                  abm_tipo,                 abm_tipo_aplicacion,
      abm_nro_recibo,                abm_tasa_prepago,         abm_dividendo,
      abm_calcula_devolucion,        'N',                      null
      
      from ca_abono_masivo_det,
           ca_abono_masivo
      where abmd_secuencial_ing = abm_secuencial_ing
      and abmd_operacion  = abm_operacion
      and abmd_monto_mn  > 0
      and abm_lote = @i_lote
      and abm_estado = 'ING'
      and abmd_tipo  = 'PAG'
      if @@error != 0 begin
         select @w_error = 710232
         goto ERROR
      end  


      --Inseratar en ca_abono_det 

      insert into ca_abono_det
      (abd_secuencial_ing,            abd_operacion,             abd_tipo,
	   abd_concepto,                  abd_cuenta,                abd_beneficiario,
	   abd_moneda,                    abd_monto_mpg,             abd_monto_mop,
	   abd_monto_mn,                  abd_cotizacion_mpg,        abd_cotizacion_mop,
	   abd_tcotizacion_mpg,           abd_tcotizacion_mop,       abd_cheque,
	   abd_cod_banco,                 abd_inscripcion,           abd_carga,
	   abd_solidario)                                                                 --GFP 19/10/2021 Ingreso de nuevo campo para identificacion de pago solidario
      select 
      abmd_secuencial_ing,            abmd_operacion,            abmd_tipo,
      @i_forma_pago,           		  @i_referencia,             abmd_beneficiario,
      abmd_moneda,           		  abmd_monto_mpg,            abmd_monto_mop,
      abmd_monto_mn,           		  abmd_cotizacion_mpg,       abmd_cotizacion_mop,
      abmd_tcotizacion_mpg,    		  abmd_tcotizacion_mop,      @i_cheque,   
      @i_cod_banco,                   null,              null,
      'N'	  
      from ca_abono_masivo_det,
      ca_abono_masivo
      where abmd_secuencial_ing = abm_secuencial_ing
      and abmd_operacion  = abm_operacion
      and abmd_monto_mn  > 0
      and abm_lote = @i_lote
      and abm_estado = 'ING'
      if @@error != 0 begin
         select @w_error = 710233
         goto ERROR
      end  


      /*INSERTAR EN ca_abono_prioridad*/

      insert into ca_abono_prioridad
	  (ap_secuencial_ing,                  ap_operacion,              ap_concepto,
       ap_prioridad)
      select amp_secuencial_ing,           amp_operacion,             amp_concepto,
      amp_prioridad 
      from ca_abono_masivo_prioridad,
      ca_abono_masivo
      where amp_secuencial_ing = abm_secuencial_ing
      and amp_operacion  = abm_operacion
      and abm_lote = @i_lote
      and abm_estado = 'ING'
      if @@error != 0 begin
         select @w_error = 710234
         goto ERROR
      end  



      /*El lote queda procesado o pasado a definitivas */
      update ca_abonos_masivos_his
      set amh_estado = 'P',
      amh_valor_total = @i_total_pago
      where amh_lote = @i_lote
      if @@error != 0 begin
         select @w_error = 710230
         goto ERROR
      end  
   end /* subtipo 2 */
commit tran
end /*Operacion U*/

return   0

ERROR:

insert into ca_abono_masivo_errores ( 
er_lote,   er_empresa,   er_cliente,    er_banco,
er_error,  er_proceso,   er_ioperacion, er_fecha)
values(
@i_lote,   @i_compania,  @w_cliente,    @i_banco,
@w_error,  @w_sp_name,   @i_operacion,  getdate())

exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_error
return @w_error

go
