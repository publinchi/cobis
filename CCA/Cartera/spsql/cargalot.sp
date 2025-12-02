/************************************************************************/
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Archivo:                cargalot.sp                             */
/*      Procedimiento:          sp_cargar_lote 	                        */
/*      Disenado por:           Elcira Pelaez Burbano			*/
/*      Fecha de escritura:     25 de Abril del 2001                    */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA".		                                        */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/*                              PROPOSITO                               */
/*      Envia a front-end informacion por lote de pagos masivos 	*/
/*      almacenados en temporales                                       */
/*      Operacion 'L'							*/
/*      subtipo = 0     selecciona todas las operaciones relacionandolas*/
/*                      con la tabla ca_abono_masivo para un lote dado  */
/*      subtipo = 1     selecciona solo las operaciones ING las cuales  */
/*			van a ser pasadas a las tablas definitivas  de  */
/*			abonos en  cartera	para convenios		*/
/*			Los campos 1-2 son para crear lote              */
/*      subtipo = 2     selecciona todas las operaciones de la tabla his*/
/*			torica ca_abonos_masivos_his  para un lote dado */
/*			este subtipo es para modificar lote existente   */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_cargar_lote')
   drop proc sp_cargar_lote
go

if exists (select 1 from sysobjects where name = 'ca_clientes_tmp')
      drop table ca_clientes_tmp
go

create table ca_clientes_tmp (
       secuencial	  int null,
       estado             varchar(10),
       empleado	          varchar(20) null,
       operacionca	  int null,
       num_oper	          cuenta,
       moneda   	  smallint null,
       toperacion	  catalogo null,
       saldo_op	          money null,
       saldo_capital	  money null,
       saldo_interes	  money null,
       saldo_mora	  money null,
       saldo_seguros	  money null,
       saldo_otros_cargos money null,
       saldo_pagar 	  money null,
       fecha_pago         datetime null,
       num_cuotas 	  smallint
)

go 


create procedure sp_cargar_lote (
	@i_lote 	 int     = null,
	@i_secuencial 	 int     = 0,	
        @i_operacion     char(1) = null,
        @i_subtipo       char(1) = null,
	@i_fecha         datetime = null,
	@i_siguiente 	 cuenta   = '0',
        @i_formato_fecha int      = 101
)
as 
declare @w_error 		int, 
	@w_sp_name 		descripcion,
	@w_empleado 		int,
	@w_num_oper 		cuenta,
	@w_operacionca 		int,
	@w_toperacion 		catalogo,
	@w_moneda 		tinyint,
	@w_saldo_operacion 	money,
	@w_saldo_capital 	money,
	@w_saldo_interes 	money,
	@w_saldo_mora 		money,
	@w_saldo_seguros 	money,
	@w_saldo_otros_cargos 	money,
	@w_saldo_pagar 		money,
	@w_num_cuotas 		smallint,
	@w_secuencial 		int,
        @w_dia_de_pago          char(2),
        @w_mes_pago             char(2),
        @w_long                 smallint,
        @w_anio_pago            char(4),
	@w_fecha_pago           datetime,
        @w_total_registros      int,
        @w_max_dividendo	int,
	@w_dividendo_vig	int,
  	@w_dividendo_ven	int



select @w_sp_name = 'sp_cargar_lote',
       @w_secuencial = 0


---PRINT 'llega a cargalot.sp @i_operacion %1! + @i_subtipo %2! + @i_siguiente %3!' + @i_operacion + @i_subtipo + @i_siguiente

   delete  ca_clientes_tmp WHERE secuencial >= 0
   

set rowcount 30

if @i_operacion = 'L'  begin  /*Consulta por lote y envia los datos actualizados de saldos a excepcion del pago ya ingresado*/

   if @i_subtipo = '0' begin
     insert into ca_clientes_tmp
      select distinct 
       'secuencial'         = 0, 
       'estado'             = abm_estado,
       'empleado'           = en_ced_ruc,
       'operacionca'        = op_operacion,
       'num_oper'           = op_banco,
       'moneda'             = op_moneda,
       'toperacion'         = op_toperacion,
       'saldo_op'           = 0,
       'saldo_capital'      = 0,
       'saldo_interes'      = 0,
       'saldo_mora'         = 0,
       'saldo_seguros'      = 0,
       'saldo_otros_cargos' = 0,
       'saldo_pagar'        = 0,
       'fecha_pago'         = abm_fecha_pag,
       'num_cuotas'         = 0
      from ca_operacion,
      cobis..cl_ente noholdlock,
      ca_abono_masivo,
      ca_abono_masivo_det
      where en_ente          = op_cliente
      and abm_operacion      = abmd_operacion
      and abm_secuencial_ing = abmd_secuencial_ing
      and abm_operacion      = op_operacion
      and abmd_operacion     = op_operacion
      and abm_lote           = @i_lote
      and op_banco  > @i_siguiente
      order by op_banco

      if @@rowcount = 0 begin 
         print 'Entro a Error Pelado de lo Viejo ' +  convert(varchar, @@rowcount) + ' ' + convert(varchar, @w_total_registros)
         select @w_error = 710244
         goto ERROR
      end 
   end
   if @i_subtipo = '1' begin
     insert into ca_clientes_tmp
      select distinct 
      'secuencial'     = 0, 
      'estado'         = abm_estado,
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
      'fecha_pago'     = abm_fecha_pag,
      'num_cuotas'     = 0
      from ca_operacion,
      cobis..cl_ente noholdlock,
      ca_abono_masivo,
      ca_abono_masivo_det
      where en_ente = op_cliente
      and abm_operacion = abmd_operacion
      and abm_secuencial_ing = abmd_secuencial_ing
      and abm_operacion = op_operacion
      and abmd_operacion = op_operacion
      and abm_lote = @i_lote
      and abm_estado = 'ING'
      and op_banco  > @i_siguiente
      order by op_banco
      if @@rowcount = 0 begin 
         select @w_error = 710244
         goto ERROR
      end 

   end

   if @i_subtipo = '2' begin
     insert into ca_clientes_tmp
      select distinct 
      'secuencial'     = 0, 
      'estado'         = 'ING',
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
      'saldo_pagar'    = amhd_valor_pag,
      'fecha_pago'     = amhd_fecha_ing,
      'num_cuotas'     = 0
      from ca_operacion,
      cobis..cl_ente noholdlock,
      ca_abonos_masivos_his,
      ca_abonos_masivos_his_d
      where en_ente = op_cliente
      and amh_lote = amhd_lote
      and amhd_banco = op_banco
      and amh_lote = @i_lote
      and op_banco  > @i_siguiente
      order by op_banco
      if @@rowcount = 0 begin 
         select @w_error = 710244
         goto ERROR
      end 

   end


   /*Cursor para cada uno de los registros obtenidos*/
   /*************************************************/
   declare cursor_empleado_operacion cursor for
   select operacionca, moneda, toperacion 
   from ca_clientes_tmp
   for read only

   open cursor_empleado_operacion
   fetch cursor_empleado_operacion into @w_operacionca, @w_moneda, @w_toperacion
   while   @@fetch_status = 0 begin
      if (@@fetch_status = -1) begin
         select @w_error = 710004
         goto ERROR
      end


      /*MAXIMO DIVIDENDO*/
      /******************/
      select @w_max_dividendo = max(di_dividendo) 
      from ca_dividendo
      where di_operacion = @w_operacionca


      /*DIVIDENDO  VIGENTE*/
      /********************/
      select @w_dividendo_vig = max(di_dividendo) 
      from ca_dividendo
      where di_operacion = @w_operacionca
      and   di_estado    = 1
      if @@rowcount = 0 begin
         select @w_dividendo_ven = max(di_dividendo) 
         from ca_dividendo
         where di_operacion = @w_operacionca
         and   di_estado    = 2
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
      and ru_moneda = @w_moneda
 

      ---PRINT 'cargalot.sp @w_operacionca %1!' + @w_operacionca

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
      /***************/   
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
      /******************/   
      
      if @w_max_dividendo = @w_dividendo_vig
      begin
         select @w_saldo_seguros = 0   --por pago anticipado
      end
      
      if @w_max_dividendo = @w_dividendo_ven
      begin
         select @w_saldo_seguros = isnull(sum(am_cuota + am_gracia - am_pagado ),0)  
         from ca_dividendo, ca_amortizacion, ca_concepto 
         where am_dividendo = di_dividendo 
         and co_concepto = am_concepto 
         and co_categoria in ('S','V') ---Seguro fijo y varible
         and di_estado = 2
         and am_operacion = di_operacion
         and am_operacion = @w_operacionca   
      end

      if @w_dividendo_vig < @w_max_dividendo
      begin
         select @w_saldo_seguros = isnull(sum(am_cuota + am_gracia - am_pagado ),0)  
         from ca_dividendo, ca_amortizacion, ca_concepto 
         where am_dividendo = di_dividendo 
         and am_dividendo <= @w_dividendo_vig + 1
         and di_dividendo <= @w_dividendo_vig + 1
         and co_concepto = am_concepto 
         and co_categoria in ('S','V') ---Seguro fijo y varible
         and am_operacion = di_operacion
         and am_operacion = @w_operacionca   
      end



      /*SALDO DE OTROS CONCEPTOS*/
      /*************************/   

      select @w_saldo_otros_cargos = isnull(sum(am_cuota + am_gracia - am_pagado),0)  
      from ca_dividendo, ca_amortizacion, ca_concepto 
      where am_dividendo = di_dividendo  
      and co_concepto = am_concepto 
      and co_categoria NOT IN ('S','M','I','C','V')
      and di_estado in (1,2)
      and am_operacion = di_operacion
      and am_operacion = @w_operacionca 

      /*SALDO A PAGAR*/
      /***************/
	Select @w_saldo_pagar  =  sum(abmd_monto_mn)
	from ca_abono_masivo,
             ca_abono_masivo_det
	where abm_operacion       = abmd_operacion  
          and abmd_operacion      = @w_operacionca
	  and abmd_secuencial_ing = abm_secuencial_ing
          and abm_lote            = @i_lote
	  and abmd_tipo in ('PAG')

      /*Numero de cuotas a pagar*/
      /**************************/

       select @w_num_cuotas = count(*)
       from ca_dividendo
       where di_estado in (1, 2)
       and di_operacion = @w_operacionca

      /* SECUENCIAL*/
      /*************/
      select @w_secuencial = @w_secuencial + 1


      /****
      /* FECHA DEPAGO */
      /****************/
       select @w_dia_de_pago = '01'

       select @w_dia_de_pago = convert(char(2),op_dia_fijo)
       from ca_operacion
       where op_operacion = @w_operacionca

       
       select @w_mes_pago = convert(char(2),datepart(mm,di_fecha_ven))
       from ca_dividendo
       where di_operacion = @w_operacionca
       and di_estado = 1   ---VENCIMIENTO CUOTA VIGENTE


       select @w_long = char_length(@w_mes_pago)

       if @w_long = 1
          select @w_mes_pago = '0' + @w_mes_pago


       if @w_mes_pago = '02'   --- si el mes de pago es Febrero
          begin
             select @w_dia_de_pago = convert(char(2),datepart(dd,di_fecha_ven))
             from ca_dividendo
             where di_operacion = @w_operacionca
             and di_estado = 1   ---VENCIMIENTO CUOTA VIGENTE

             print 'Mes Febrero...' + @w_dia_de_pago
          end

       select @w_anio_pago = convert(char(4),datepart(yy,di_fecha_ven))
       from ca_dividendo
       where di_operacion = @w_operacionca
       and di_estado = 1   ---VENCIMIENTO CUOTA VIGENTE



       if @w_mes_pago = '02'   --- si el mes de pago es Febrero
       begin
          if @w_dia_de_pago <= '29'      
             select @w_fecha_pago =  @w_mes_pago + '/'    + @w_dia_de_pago + '/' + @w_anio_pago
          else
             select @w_fecha_pago =  @w_mes_pago + '/'    + '28'           + '/' + @w_anio_pago
       end
       else
       select @w_fecha_pago       =  @w_mes_pago + '/'    + @w_dia_de_pago + '/' + @w_anio_pago

       *******/

      /* FIN FECHA PAGO */

      if @i_subtipo in ('0','1') begin

       UPDATE ca_clientes_tmp
       SET 
       secuencial         = @w_secuencial,
       saldo_op           = @w_saldo_operacion,
       saldo_capital      = @w_saldo_capital,
       saldo_interes      = @w_saldo_interes,
       saldo_mora         = @w_saldo_mora,
       saldo_seguros      = @w_saldo_seguros,
       saldo_otros_cargos = @w_saldo_otros_cargos,
       saldo_pagar        = @w_saldo_pagar,
       num_cuotas         = @w_num_cuotas
       WHERE operacionca  = @w_operacionca 
     end
     else if @i_subtipo = '2' begin
       UPDATE ca_clientes_tmp
       SET 
       secuencial         = @w_secuencial,
       saldo_op           = @w_saldo_operacion,
       saldo_capital      = @w_saldo_capital,
       saldo_interes      = @w_saldo_interes,
       saldo_mora         = @w_saldo_mora,
       saldo_seguros      = @w_saldo_seguros,
       saldo_otros_cargos = @w_saldo_otros_cargos,
       num_cuotas         = @w_num_cuotas,
       fecha_pago         = @w_fecha_pago
       WHERE operacionca  = @w_operacionca 
    end

      fetch cursor_empleado_operacion into @w_operacionca, @w_moneda, @w_toperacion
   
   end
   close cursor_empleado_operacion
   deallocate cursor_empleado_operacion

end  /*operacion L */


select 
empleado,
num_oper,
saldo_op,
saldo_capital,
saldo_interes,
saldo_mora,
saldo_seguros,
saldo_otros_cargos,
saldo_pagar,
fecha_pago,              
num_cuotas,
estado
from ca_clientes_tmp
where estado <> 'CAN'
and num_oper > @i_siguiente
    
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

