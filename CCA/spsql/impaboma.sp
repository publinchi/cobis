/************************************************************************/
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Archivo:                impaboma.sp                             */
/*      Procedimiento:          sp_imprimir_abonos_masivos              */
/*      Disenado por:           Elcira Pelaez Burbano                   */
/*      Fecha de escritura:     15 de Mayo del 2001                     */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/*                              PROPOSITO                               */
/*      Envia a front-end informacion  para generar el archivo          */
/*      plano por empresa                                               */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_imprimir_abonos_masivos')
   drop proc sp_imprimir_abonos_masivos
go


create procedure sp_imprimir_abonos_masivos (
    @i_empresa   int         = null,
    @i_oficina  smallint     = null,
    @i_oficial  smallint     = null,
   @i_linea        catalogo     = null,
    @i_siguiente    cuenta       = '1',
   @i_formato_fecha int         = 101



)
as 
declare @w_error              int, 
    @w_sp_name                descripcion,
    @w_empleado               int,
    @w_num_oper               cuenta,
    @w_operacionca            int,
    @w_toperacion             catalogo,
    @w_moneda                 tinyint,
    @w_saldo_operacion        money,
    @w_saldo_capital          money,
    @w_saldo_interes          money,
    @w_saldo_mora             money,
    @w_saldo_seguros          money,
    @w_saldo_otros_cargos     money,
    @w_saldo_pagar            money,
    @w_num_cuotas             smallint,
    @w_secuencial             int,
    @w_relacion               smallint,
    @w_fecha_pago             datetime,
    @w_dia_de_pago            char(2),
    @w_mes_pago               char(2),
    @w_long                   smallint,
    @w_anio_pago              char(4),
    @w_estado                 smallint,
    @w_max_dividendo          int,
    @w_dividendo_vig          int,
    @w_dividendo_ven          int,
    @w_rowcount               int

select @w_sp_name = 'sp_imprimir_abonos_masivos',
       @w_secuencial = 0


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



select @w_fecha_pago = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7


   delete ca_consulta_pag_mas_tmp WHERE secuencial >= 0

   select @w_secuencial = 0
   set rowcount 30

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
      'Tramite'        = op_tramite

      from cobis..cl_instancia, 
           ca_operacion,
           cobis..cl_ente
      where in_relacion = @w_relacion
      and in_ente_i = @i_empresa
      and in_lado = 'D'
      and in_ente_d = op_cliente
      and op_cliente = en_ente
      and op_estado not in (0,3,6,98,99) --NO VIGENTES, CANCELADAS, COMEXT, CREDITO
      and op_tipo = 'V'
      and convert(int,op_entidad_convenio)  = @i_empresa
      and op_banco >  @i_siguiente
      order by op_banco 
    if @@rowcount = 0 begin
       select @w_error = 710238
       goto ERROR
    end
     end
     else begin  ---GENERALES

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
      'Tramite'        = op_tramite

      from ca_operacion,
           cobis..cl_ente noholdlock
      where op_cliente = en_ente
      and op_estado not in (0,3,6,98,99) ---NO VIGENTES, CANCELADAS, COMEXT, CREDITO
      and (op_oficina    = @i_oficina or @i_oficina is null) 
      and (op_oficial    = @i_oficial or @i_oficial is null)
      and (op_toperacion = @i_linea or @i_linea is null)
      and op_tipo_linea <> 'V'        ---No INCLUYE CONVENIOS
      and op_banco >  @i_siguiente
      order by op_banco 
    if @@rowcount = 0 begin
       select @w_error = 710238
       goto ERROR
    end

     end


   /*Cursor para cada uno de los registros obtenidos*/
   /*************************************************/
   declare cursor_empleado_operacion cursor for
   select operacionca, moneda, toperacion 
   from ca_consulta_pag_mas_tmp
   for read only

   open cursor_empleado_operacion
   fetch cursor_empleado_operacion into @w_operacionca, @w_moneda, @w_toperacion
   while   @@fetch_status = 0 begin
      if (@@fetch_status = -1) begin
         select @w_error = 710004
         goto ERROR
      end


      select @w_secuencial         = 0,
             @w_saldo_operacion    = 0,
             @w_saldo_capital      = 0,
             @w_saldo_interes      = 0,
             @w_saldo_mora         = 0,
             @w_saldo_seguros      = 0,
             @w_saldo_otros_cargos = 0,
             @w_saldo_pagar        = 0,
             @w_num_cuotas         = 0,
             @w_fecha_pago         = ''


      /*MAXIMO DIVIDENDO*/
      select @w_max_dividendo = max(di_dividendo) 
      from ca_dividendo
      where di_operacion = @w_operacionca


      /*DIVIDENDO  VIGENTE*/
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
      select @w_saldo_operacion = isnull(sum(am_cuota + am_gracia - am_pagado ),0)
      from ca_amortizacion, ca_rubro_op, ca_rubro 
      where am_operacion = @w_operacionca
      and ro_operacion = @w_operacionca
      and ro_tipo_rubro= 'C'
      and ro_concepto  = am_concepto
      and ru_tipo_rubro = 'C'
      and ru_concepto = ro_concepto 
      and ru_toperacion = @w_toperacion 
      and ru_moneda = @w_moneda
 

      /*SALDO DE CAPITAL*/
      /***********************/   

      select @w_saldo_capital = isnull(sum(am_cuota + am_gracia - am_pagado ),0)
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
 
      select @w_saldo_interes = isnull(sum(am_cuota + am_gracia - am_pagado ),0)
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
      select @w_saldo_mora = isnull(sum(am_cuota + am_gracia - am_pagado ),0)
      from ca_amortizacion, ca_dividendo, ca_rubro_op
      where di_operacion = @w_operacionca
      and ro_operacion = di_operacion
      and am_operacion = di_operacion
      and am_operacion = ro_operacion
      and di_dividendo = am_dividendo
      and ro_tipo_rubro = 'M'
      and ro_concepto = am_concepto
      and di_estado =2



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

      select @w_saldo_otros_cargos = isnull(sum(am_cuota + am_gracia - am_pagado ),0)  
      from ca_dividendo, ca_amortizacion, ca_concepto 
      where am_dividendo = di_dividendo  
      and co_concepto = am_concepto 
      and co_categoria NOT IN ('S','M','I','C','V')
      and di_estado in (1,2)
      and am_operacion = di_operacion
      and am_operacion = @w_operacionca 

      /*SALDO A PAGAR*/
      /***************/
      select @w_saldo_pagar = isnull(sum(am_cuota + am_gracia - am_pagado ),0)
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


     
      /* FECHA DEPAGO */

      select @w_estado = di_estado
      from ca_dividendo
      where di_operacion  = @w_operacionca 
      and di_estado = 1
      if @@rowcount  = 0
          select @w_estado = 2
       
       

       select @w_dia_de_pago = convert(char(2),dt_dia_pago)
       from ca_default_toperacion
       where dt_toperacion = @w_toperacion

       select @w_dia_de_pago = isnull(@w_dia_de_pago,'0')


       if @w_dia_de_pago = '0' begin
           select @w_dia_de_pago = convert(char(2),datepart(dd,di_fecha_ven))
           from ca_dividendo
           where di_operacion = @w_operacionca
           and di_estado = @w_estado   ---VENCIMIENTO CUOTA VIGENTE
            select @w_dia_de_pago = isnull(@w_dia_de_pago,'0')
            if @w_dia_de_pago = '0'  begin
           PRINT 'operacion no tiene dividendo Vigente' + cast(@w_operacionca as varchar)
           goto SIGUIENTE
              end
               
       end


       select @w_mes_pago = convert(char(2),datepart(mm,di_fecha_ven))
       from ca_dividendo
       where di_operacion = @w_operacionca
       and di_estado = @w_estado   ---VENCIMIENTO CUOTA VIGENTE

       select @w_anio_pago = convert(char(4),datepart(yy,di_fecha_ven))
       from ca_dividendo
       where di_operacion = @w_operacionca
       and di_estado = @w_estado   ---VENCIMIENTO CUOTA VIGENTE

      
       select @w_long = len(@w_mes_pago)

       if @w_long = 1
          select @w_mes_pago = '0' + @w_mes_pago


       ---PRINT 'impaboma.sp @w_operacionca %1! @w_estado  %2! @w_mes_pago %3!',@w_operacionca,@w_estado,@w_mes_pago

       ---EPB:feb-18-2002
          if @w_mes_pago = '02' or @w_mes_pago = '2' begin

           select @w_dia_de_pago = convert(char(2),datepart(dd,di_fecha_ven))
           from ca_dividendo
           where di_operacion = @w_operacionca
           and di_estado = @w_estado   ---VENCIMIENTO CUOTA VIGENTE
            select @w_dia_de_pago = isnull(@w_dia_de_pago,'0')
            if @w_dia_de_pago = '0'  begin
           PRINT 'operacion no tiene dividendo Vigente' + cast(@w_operacionca as varchar)
           goto SIGUIENTE
              end

       ---PRINT 'impaboma.sp @w_operacionca  %1!,@w_dia_de_pago %2!',@w_dia_de_pago,@w_dia_de_pago
 
          end
       ---EPB:feb-18-2002


        
       select @w_fecha_pago =    @w_mes_pago + '/' +   @w_dia_de_pago + '/' + @w_anio_pago

       ---PRINT '@w_operacionca 2 %1!',@w_operacionca       


      /* FIN FECHA PAGO */


      UPDATE ca_consulta_pag_mas_tmp
      SET 
      secuencial         = @w_secuencial,
      saldo_op           = @w_saldo_operacion,
      saldo_capital      = @w_saldo_capital,
      saldo_interes      = @w_saldo_interes,
      saldo_mora         = @w_saldo_mora,
      saldo_seguros      = @w_saldo_seguros,
      saldo_otros_cargos = @w_saldo_otros_cargos,
      saldo_pagar        = @w_saldo_pagar,
      num_cuotas         = @w_num_cuotas,
      fecha_pago         = @w_fecha_pago
      WHERE operacionca = @w_operacionca 

 
SIGUIENTE:

      fetch cursor_empleado_operacion into @w_operacionca, @w_moneda, @w_toperacion
   
   end
   close cursor_empleado_operacion
   deallocate cursor_empleado_operacion


select 
'Cedula'      = empleado,
'Operacion'       = num_oper,
'Saldo Operacion' = saldo_op,
'Saldo Cap.'      = saldo_capital,
'Saldo Int.'      = saldo_interes,
'Saldo Mora'      = saldo_mora,
'Saldo Seg.'      = saldo_seguros,
'Saldo Otros'     = saldo_otros_cargos,
'Saldo pagar'     = saldo_pagar,
'Fecha de pago'   = convert(varchar(10),fecha_pago,@i_formato_fecha), --Formato mm/dd/yyyy
'Num. Cuotas'     = num_cuotas,
'No.Tramite'      = tramite

from ca_consulta_pag_mas_tmp
where num_oper > @i_siguiente 
order by num_oper
    
if @@rowcount = 0 begin
   print 'FINAL  DE LA CONSULTA'
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