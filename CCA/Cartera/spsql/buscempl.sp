/************************************************************************/
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Archivo:                buscempl.sp                             */
/*      Procedimiento:          sp_buscar_empleados 	                */
/*      Disenado por:           Juan Sarzosa/Elcira Pelaez              */
/*      Fecha de escritura:     16 de Abril del 2001                    */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.		                                        */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/*                              PROPOSITO                               */
/*      Consulta las operaciones de una empresa para un cliente 	*/
/*      para un oficial o para una oficina o de los tres en conjunto.   */
/*      Se usa en la pantalla para pagos masivos de convenios y         */
/*      Generales, si @i_espresa > 0 es para convenios			*/
/*      	      @i_espresa = 0 es para Genereales			*/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'ca_consulta_pag_mas_tmp')
      drop table ca_consulta_pag_mas_tmp
go

create table ca_consulta_pag_mas_tmp (
	secuencial	     int null,
    estado           varchar(10),
	empleado	     varchar(20) null,
	operacionca	     int null,
	num_oper	     cuenta,
	moneda   	     smallint null,
	toperacion	     catalogo null,
	saldo_op	     money null,
	saldo_capital	 money null,
	saldo_interes	 money null,
	saldo_mora	     money null,
	saldo_seguros	 money null,
	saldo_otros_cargos money null,
	saldo_pagar 	 money null,
    fecha_pago       datetime null,
	num_cuotas 	     smallint null,
    tramite          int null
)

go



if exists (select * from sysobjects where name = 'sp_buscar_empleados')
   drop proc sp_buscar_empleados 
go
create procedure sp_buscar_empleados (
    @s_ssn          int          = null,
    @s_date         datetime     = null,
    @s_user         login        = null,
    @s_term         descripcion  = null,
    @s_ofi          smallint     = null,
    @t_debug       	char(1)      = 'N',
    @t_file        	varchar(14)  = null,
    @t_trn		    smallint     = null,     
	@i_empresa 	    int          = 0,
	@i_lote 	    int          = 0,
	@i_cliente 	    int          = null,
	@i_oficina	    smallint     = null,
	@i_oficial	    smallint     = null,
    @i_banco        cuenta       = null,
    @i_linea        catalogo     = null,
	@i_siguiente	cuenta       = '0',
    @i_formato_fecha int         = 101,
    @i_cheque       int         = null,
    @i_cod_banco    catalogo    = null 

     

)
as

declare @w_error 		int, 
	@w_sp_name 		descripcion,
	@w_relacion 		smallint,
	@w_num_oper 		cuenta,
	@w_operacionca  	int,
	@w_lote         	int,
	@w_toperacion 		catalogo,
	@w_forma_pago           catalogo,
	@w_concepto             catalogo,
	@w_moneda_op 		tinyint,
    @w_moneda_nacional      tinyint,
	@w_saldo_operacion      money,
	@w_saldo_capital        money,
	@w_saldo_interes        money,
	@w_saldo_mora 	        money,
	@w_saldo_seguros        money,
	@w_saldo_otros_cargos   money,
	@w_saldo_pagar   	money,
	@w_num_cuotas 		smallint,
    @w_tcot_moneda          char(1),
	@w_secuencial 		int,
    @w_fecha_pago   	datetime,
    @w_numero_recibo  	int,
    @w_cuota_completa       char(1),
	@w_aceptar_anticipos    char(1),
    @w_referencia           cuenta,
    @w_tipo_reduccion       char(1),
    @w_tipo_cobro           char(1),          
    @w_tipo_aplicacion      char(1),
    @w_prioridad	        int,
    @w_monto_mop            money,
    @w_cotizacion_mop       float,
    @w_cot_moneda           float,
	@w_return               int,
    @w_monto_mn             money,
    @w_rowcount             int

select @w_sp_name = 'sp_buscar_empleados'

select @w_relacion = pa_smallint 
from  cobis..cl_parametro , cobis..cl_producto
where pa_nemonico = 'R-CONV'
and pa_producto = pd_abreviatura
and pa_producto = 'CCA'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0 begin
   select @w_error = 710222
   goto ERROR
end



select @w_moneda_nacional = pa_tinyint
from cobis..cl_parametro
where pa_producto = 'ADM'
and   pa_nemonico = 'MLO'
set transaction isolation level read uncommitted


select @w_fecha_pago = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7


   begin tran

   delete ca_consulta_pag_mas_tmp WHERE secuencial >= 0

   set rowcount 30
   select @w_secuencial = 0


   if @i_empresa > 0 begin

       
      insert into ca_consulta_pag_mas_tmp
      select distinct 
      'secuencial'     = 0, 
      'Estado'         = 'ING',
      'empleado'       = en_ced_ruc,
      'operacionca'    = op_operacion,
      'num_oper'       = op_banco,
      'moneda'         = op_moneda,
      'toperacion'     = op_toperacion,
      'saldo_op'       = 0,
      'saldo_capital'  = 0,
      'saldo_interes'  = 0,
      'saldo_mora'     = 0,
      'saldo_seguros'  = 0,
      'saldo_otros_cargos' = 0,
      'saldo_pagar'    = 0,
      'fecha_pago'     = @w_fecha_pago,
      'num_cuotas'     = 0,
      'tramite'        = null

      from cobis..cl_instancia with (nolock), 
           ca_operacion,
           cobis..cl_ente with (nolock)
      where in_relacion = @w_relacion
      and in_ente_i = @i_empresa
      and in_lado = 'D'
      and in_ente_d = op_cliente
      and op_cliente = en_ente
      and (op_banco   = @i_banco   or @i_banco   is null)      
      and (op_cliente = @i_cliente or @i_cliente is null)
      and (op_oficina = @i_oficina or @i_oficina is null) 
      and (op_oficial = @i_oficial or @i_oficial is null)
      and op_estado not in (0,3,6,98,99) --NO VIGENTES, CANCELADAS, COMEXT, CREDITO
      and op_banco > @i_siguiente
      and convert(int,op_entidad_convenio)  = @i_empresa
      order by op_banco
	
	if @@rowcount = 0 begin
	   select @w_error = 710238
	   goto ERROR
	end
   end  /*empresa > 0*/
   else
   if @i_empresa = 0 begin
      insert into ca_consulta_pag_mas_tmp
      select distinct 
      'secuencial'     = 0, 
      'Estado'         = 'ING',
      'empleado'       = en_ced_ruc,
      'operacionca'    = op_operacion,
      'num_oper'       = op_banco,
      'moneda'         = op_moneda,
      'toperacion'     = op_toperacion,
      'saldo_op'       = 0,
      'saldo_capital'  = 0,
      'saldo_interes'  = 0,
      'saldo_mora'     = 0,
      'saldo_seguros'  = 0,
      'saldo_otros_cargos' = 0,
      'saldo_pagar'    = 0,
      'fecha_pago'     = @w_fecha_pago,
      'num_cuotas'     = 0,
      'tramite'        = null

      from  ca_operacion,
           cobis..cl_ente with (nolock)
      where op_cliente = en_ente
      and (op_banco   = @i_banco   or @i_banco   is null)      
      and (op_cliente = @i_cliente or @i_cliente is null)
      and (op_oficina = @i_oficina or @i_oficina is null) 
      and (op_oficial = @i_oficial or @i_oficial is null)
      and (op_toperacion = @i_linea or @i_linea is null)
      and op_estado not in (0,3,98,99) --NO VIGENTES, CANCELADAS, COMEXT, CREDITO
      and op_tipo <> 'V'        --DIFERENTES DE CONVENIO
      and op_banco > @i_siguiente
      order by op_banco
	
	if @@rowcount = 0 begin
	   select @w_error = 710238
	   goto ERROR
	end

    end /*empresa = 0*/

   /*Cursor para cada uno de los registros obtenidos*/
   /*************************************************/
   declare cursor_empleado_operacion cursor for
   select operacionca,
          moneda,
          toperacion,
          num_oper
   from ca_consulta_pag_mas_tmp
   for read only

   open cursor_empleado_operacion

   fetch cursor_empleado_operacion into 
   @w_operacionca,
   @w_moneda_op,
   @w_toperacion,
   @w_num_oper
   
   while   @@fetch_status = 0 begin
      if (@@fetch_status = -1) begin
         select @w_error = 710004
         goto ERROR
      end

       /*VALIDAR QUE EN LA TABLA TEMPORAL DE ABONOS MASIVOS  NO EXISTA EL MISMO */
       /* CLIENTE */

       if exists (select 1 from ca_abono_masivo
        where abm_operacion = @w_operacionca) begin
             goto SIGUIENTE
       end 

      /*SALDO DE LA OPERACION*/
      /***********************/   
      select @w_saldo_operacion = isnull(sum(am_cuota + am_gracia - am_pagado),0)
      from ca_amortizacion, ca_rubro_op, ca_rubro 
      where am_operacion = @w_operacionca
      and ro_operacion = @w_operacionca
      and ro_tipo_rubro= 'C'
      and ro_concepto  = am_concepto
      and ru_tipo_rubro = 'C'

      and ru_concepto = ro_concepto 
      and ru_toperacion = @w_toperacion 
      and ru_moneda = @w_moneda_op
 

      /*SALDO DE CAPITAL*/
      /***********************/   

      select @w_saldo_capital = isnull(sum(am_cuota + am_gracia - am_pagado),0)
      from ca_amortizacion, ca_dividendo, ca_rubro_op
      where di_operacion = @w_operacionca
      and ro_operacion = di_operacion
      and am_operacion = di_operacion
      and am_operacion = ro_operacion
      and di_dividendo = am_dividendo
      and ro_tipo_rubro = 'C'
      and ro_concepto = am_concepto
      and di_estado in (1,2)

      /*SALDO DE INTERES*/
      /***********************/   
 
      select @w_saldo_interes = isnull(sum(am_cuota + am_gracia - am_pagado),0)
      from ca_amortizacion, ca_dividendo, ca_rubro_op
      where di_operacion = @w_operacionca
      and ro_operacion = di_operacion
      and am_operacion = di_operacion
      and am_operacion = ro_operacion
      and di_dividendo = am_dividendo
      and ro_tipo_rubro = 'I'
      and ro_concepto = am_concepto
      and di_estado in (1,2)


      /*SALDO DE MORA*/
      /***********************/   
      select @w_saldo_mora = isnull(sum(am_cuota + am_gracia - am_pagado),0)
      from ca_amortizacion, ca_dividendo, ca_rubro_op
      where di_operacion = @w_operacionca
      and ro_operacion = di_operacion
      and am_operacion = di_operacion
      and am_operacion = ro_operacion
      and di_dividendo = am_dividendo
      and ro_tipo_rubro = 'M'
      and ro_concepto = am_concepto
      and di_estado =2

      /*SALDO DE SEGUROS*/
      /***********************/   

      select @w_saldo_seguros = isnull(sum(am_cuota + am_gracia - am_pagado),0)  
      from ca_dividendo, ca_amortizacion, ca_concepto 
      where am_dividendo = di_dividendo 
      and co_concepto = am_concepto 
      and co_categoria = 'S'
      and di_estado in (1,2)
      and am_operacion = di_operacion
      and am_operacion = @w_operacionca   

      /*SALDO DE OTROS CONCEPTOS*/
      /*************************/   

      select @w_saldo_otros_cargos = isnull(sum(am_cuota + am_gracia - am_pagado),0)  
      from ca_dividendo, ca_amortizacion, ca_concepto 
      where am_dividendo = di_dividendo  
      and co_concepto = am_concepto 
      and co_categoria NOT IN ('S','M','I','C')
      and di_estado in (1,2)
      and am_operacion = di_operacion
      and am_operacion = @w_operacionca 

      /*SALDO A PAGAR*/
      /***************/
      select @w_saldo_pagar = isnull(sum(am_cuota + am_gracia - am_pagado),0)
      from ca_amortizacion, ca_dividendo
      where di_operacion = @w_operacionca
      and di_estado in (1,2)
      and am_operacion = @w_operacionca
      and di_operacion = @w_operacionca
      and di_dividendo = am_dividendo

      /*Numero de cuotas a pagar*/
      /**************************/

       select @w_num_cuotas = count(*)
       from ca_dividendo
       where di_estado in (1, 2)
       and di_operacion = @w_operacionca

      /* SECUENCIAL*/
      /*************/
      select @w_secuencial = @w_secuencial + 1

       select @w_fecha_pago = convert(varchar(10),di_fecha_ven,101)
       from ca_dividendo
       where di_operacion = @w_operacionca
       and di_estado = 1   ---VENCIMIENTO CUOTA VIGENTE


      UPDATE ca_consulta_pag_mas_tmp
      SET 
      secuencial = @w_secuencial,
      saldo_op = @w_saldo_operacion,
      saldo_capital = @w_saldo_capital,
      saldo_interes = @w_saldo_interes,
      saldo_mora = @w_saldo_mora,
      saldo_seguros = @w_saldo_seguros,
      saldo_otros_cargos = @w_saldo_otros_cargos,
      saldo_pagar = @w_saldo_pagar,
      num_cuotas = @w_num_cuotas,
      fecha_pago = @w_fecha_pago
      WHERE operacionca = @w_operacionca 



       /* INICIO DE SACAR InSERTAR LOS DATOS A A¥ADIR */



	select @w_moneda_nacional = pa_tinyint
	from cobis..cl_parametro
	where pa_producto = 'ADM'
	and   pa_nemonico = 'MLO'
  	set transaction isolation level read uncommitted

  
	/* FORMA DE PAGO POR DEFAULT */

           select @w_forma_pago = cp_producto
	   from ca_producto
	   where cp_categoria = 'NDAH' /*Nota debito a ahorros*/

	 /* CUENTA POR DEFAULT */
	    select @w_referencia = '000000000000'


	

	exec @w_secuencial = sp_gen_sec 
	     @i_operacion  = @w_operacionca
  

	   select
	   @w_cuota_completa     = op_cuota_completa,
	   @w_aceptar_anticipos  = op_aceptar_anticipos,
	   @w_tipo_reduccion     = op_tipo_reduccion,
	   @w_tipo_cobro         = op_tipo_cobro,
	   @w_tipo_aplicacion    = op_tipo_aplicacion ,
	   @w_moneda_op          = op_moneda 
	   from ca_operacion
	   where  op_operacion   = @w_operacionca
	   and    op_estado <> 0

	   if @@rowcount = 0 begin
	       select @w_error = 710025
	       goto ERROR
	   end  

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
	   abm_nro_recibo,     abm_dividendo)

	   values (
	   @i_lote,
	   @w_operacionca,    @w_fecha_pago,        @w_fecha_pago,
	   @w_cuota_completa, @w_aceptar_anticipos, @w_tipo_reduccion,
	   @w_tipo_cobro,     0,                    0,
	   'ING',             @w_secuencial,        0,
	   0,                 @s_user,              @s_term,
	   'PAG',             @s_ofi,               @w_tipo_aplicacion,
	   @w_numero_recibo,  @w_num_cuotas)

           if @@error != 0 begin
	       select @w_error = 710223
	       goto ERROR
	   end  


	   select @w_concepto = ' '
	   while 1=1 begin
	      set rowcount 1
	      select
	      @w_concepto  = ro_concepto,
	      @w_prioridad = ro_prioridad
	      from ca_rubro_op
	      where ro_operacion = @w_operacionca
	      and   ro_fpago    not in ('L','B')
	      and   ro_concepto > @w_concepto
	      order by ro_concepto  
	      if @@rowcount = 0 begin
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
	   @i_monto            = @w_saldo_pagar,
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
	   @w_forma_pago,
	   @w_referencia,     'PAGO MASIVO' + '_' + convert(varchar(20),@i_empresa),
	   @w_saldo_pagar,
	   @w_monto_mop,       @w_monto_mn,       @w_cot_moneda,
	   @w_cotizacion_mop,  @w_moneda_op,     'C',
	   'C',                @i_cheque,        @i_cod_banco)

	   if @@error != 0 begin
	       select @w_error = 710224
	       goto ERROR
	   end  

	/* CARGAR DETALLE DE HISTORICO DE LOS  PAGOS MASIVOS */

	   insert into ca_abonos_masivos_his_d (
	   amhd_lote,      amhd_banco,     amhd_valor_pag,
	   amhd_fecha_ing, amhd_fecha_mod, amhd_usuario )
	   values (
	   @i_lote,        @w_num_oper,  @w_saldo_pagar,
	   @s_date,        @s_date,    @s_user)
	   if @@error != 0 begin
	       select @w_error = 710227
	       goto ERROR
	   end  

       
      SIGUIENTE:
      fetch cursor_empleado_operacion into 
      @w_operacionca,
      @w_moneda_op,
      @w_toperacion,
      @w_num_oper
   
   end
   close cursor_empleado_operacion
   deallocate cursor_empleado_operacion


       /* INSETAR CABECERA  HISTORICA DE PAGO MASIVO */
    if exists (select 1 from ca_abonos_masivos_his_d
               where amhd_lote = @i_lote) begin
     if not exists (select 1 from  ca_abonos_masivos_his
        where amh_lote = @i_lote) begin
        insert into ca_abonos_masivos_his (
        amh_lote,    amh_empresa, amh_fecha_ing, amh_valor_total,amh_estado)
        values (
        @i_lote,        @i_empresa,   @s_date, 0,'ING')
        if @@error != 0 begin
           select @w_error = 710227
           goto ERROR
        end  
     end 
    end

   commit tran    

select 
'Cliente' 	  = empleado,
'Operacion' 	  = num_oper,
'Saldo Operacion' = saldo_op,
'Saldo Cap.'      = saldo_capital,
'Saldo Int.'      = saldo_interes,
'Saldo Mora'      = saldo_mora,
'Saldo Seg.'      = saldo_seguros,
'Saldo Otros'     = saldo_otros_cargos,
'Saldo pagar'     = saldo_pagar,
'Fecha de pago'   = convert(varchar(10),fecha_pago,@i_formato_fecha), --Formato mm/dd/yyyy
'Num. Cuotas'     = num_cuotas,
'Estado'          = estado
from ca_consulta_pag_mas_tmp
where num_oper > @i_siguiente 
order by num_oper
    
if @@rowcount = 0 begin
   print 'NO EXISTEN MAS REGISTROS'
   return 0
end

set rowcount 0

return 0

ERROR:
  Exec cobis..sp_cerror
  @t_debug = 'N',
  @t_file  = null, 
  @t_from  = @w_sp_name,
  @i_num   = @w_error
  
go

