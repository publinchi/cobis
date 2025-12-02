/************************************************************************/
/*      Archivo:                consulfac.sp                            */
/*      Stored procedure:       sp_qamortmp_fac                         */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA"							*/
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Consulta una tabla de amortizacion temporal                     */
/************************************************************************/  
/*                              MODIFICACIONES                          */
/************************************************************************/

use cob_cartera
go

set ansi_nulls off
go

if exists (select 1 from sysobjects where name = 'sp_qamortmp_fac')
	drop proc sp_qamortmp_fac
go
create proc sp_qamortmp_fac
	@i_banco		cuenta,
	@i_operacion		int,
        @i_dividendo            int  = 0,
        @i_formato_fecha        int  = null, -- VB MIGSYB11.9.3
        @i_grupo_fact           int  = null,
        @i_tramite_ficticio     int  = null,
        @i_opcion               int  = 0,
        @i_tipo_rubro           char(1) = null,
        @i_concepto             catalogo  = null
as
declare 
	@w_error		int ,
	@w_return		int ,
        @w_operacionca          int ,
	@w_sp_name		descripcion,
        @w_count                int,
        @w_filas                int,
 	@w_tipo_amortizacion    catalogo,
        @w_filas_rubros         int,
        @w_primer_des           int,
        @w_opcion_cap           char(1),
        @w_num_bytes            smallint,
        @w_buffer               int,
        @w_secuencial           int,
        @w_valor                money,
        @w_moneda               tinyint,
        @w_fecha_ini            datetime,
        @w_fecha_fin            datetime,
        @w_usada                char(1),
        @w_dias                 int,
	@w_num_cuotas           int

/* VARIABLES INICIALES */
select 
@w_sp_name = 'sp_qamortmp_fac',
@w_buffer  = 2500    --TAMANIO DE BYTES MAXIMOS QUE SOPORTA EL BUFFER

/* DATOS GENERALES DEL PRESTAMO */
select 
@w_operacionca       = opt_operacion,
@w_tipo_amortizacion = opt_tipo_amortizacion,
@w_opcion_cap        = opt_opcion_cap
from   ca_operacion_tmp
where  opt_operacion = @i_operacion 

/* SOLO PARA LA PRIMERA TRANSMISION */
if @i_dividendo = 0 begin

   /* RUBROS QUE PARTICIPAN EN LA TABLA */
   select rot_concepto, co_descripcion, rot_tipo_rubro,rot_porcentaje
   from ca_rubro_op_tmp, ca_concepto
   where rot_operacion = @w_operacionca
   and rot_fpago in ('P','A', 'M','T')  
   and   rot_concepto = co_concepto
   and   rot_tipo_rubro <> @i_tipo_rubro 
   order by rot_concepto

   select @w_filas_rubros = @@rowcount

   /*DIVIDENDOS EN LOS QUE SE HA HECHO DESEMBOLSO*/
   select @w_primer_des = min(dm_secuencial)
   from   ca_desembolso
   where  dm_operacion  = @w_operacionca


   select dtr_dividendo, convert(float, sum(dtr_monto)),'D' 
   from   ca_det_trn, ca_transaccion, ca_rubro_op_tmp
   where  tr_banco      = @i_banco
   and    tr_secuencial = dtr_secuencial
   and    tr_operacion  = dtr_operacion
   and    dtr_secuencial <> @w_primer_des
   and    rot_operacion = @w_operacionca
   and    rot_tipo_rubro= 'C'
   and    tr_tran      = 'DES'
   and    tr_estado    in ('ING','CON')
   and    rot_concepto  = dtr_concepto
   group by dtr_dividendo
   union
   select dtr_dividendo, convert(float, sum(dtr_monto)),'R' /*REESTRUCTURACION*/
   from ca_det_trn, ca_transaccion, ca_rubro_op_tmp
   where  tr_banco      = @i_banco
   and   tr_secuencial = dtr_secuencial
   and   tr_operacion  = dtr_operacion
   and   rot_operacion = @w_operacionca
   and   rot_concepto  = dtr_concepto
   and   rot_tipo_rubro= 'C'
   and   tr_tran      = 'RES'
   and   tr_estado    in ('ING','CON')
   group by dtr_dividendo

   select @w_filas_rubros = @w_filas_rubros + @@rowcount

   create table #cr_facturas
   (secuencial  int,
    valor       money,
    moneda      tinyint,
    fecha_ini   datetime,
    fecha_fin   datetime,
    usada       char(1))

    select @w_secuencial = 0   

    declare facturas cursor for
    select fa_valor, fa_moneda, fa_fecini_neg,
           fa_fecfin_neg, fa_usada
      from cob_credito..cr_facturas
     where fa_tramite = @i_tramite_ficticio 
       and fa_grupo   = @i_grupo_fact
       for read only
 
    open facturas
 
    fetch facturas into
    @w_valor,@w_moneda,@w_fecha_ini,@w_fecha_fin,
    @w_usada 
    
    if (@@fetch_status = -1) begin
         select @w_error = 703006
         goto ERROR
      end

    while (@@fetch_status = 0 )  begin      

     select @w_secuencial = @w_secuencial + 1

     insert into #cr_facturas values(
     @w_secuencial,
     @w_valor,
     @w_moneda,
     @w_fecha_ini,
     @w_fecha_fin,
     @w_usada)

     fetch facturas into
     @w_valor,@w_moneda,@w_fecha_ini,@w_fecha_fin,
     @w_usada
       
    end

   close facturas
  deallocate facturas

   select @w_num_cuotas = count(1)
   from #cr_facturas
   where secuencial > @i_dividendo 

 
  select @w_dias = datediff(dd,fecha_ini,fecha_fin)
   from #cr_facturas
   where secuencial > @i_dividendo 
   order by secuencial

  
   select @w_num_bytes = @w_num_bytes + (@w_num_cuotas * 4)  
   select @w_num_bytes = isnull(@w_num_bytes,0)

end

if @i_opcion = 0 begin   /*LAZO CON EL FRONT-END SOLO PARA DIVIDENDOS*/
   if @i_dividendo = 0   begin
       select @w_count = (@w_buffer - (@w_filas_rubros*93+@w_num_bytes)) / 18
   end
   else 
      select @w_count = @w_buffer / 18

   if @w_count > 0
      set rowcount @w_count
   else
      set rowcount 0


   /* FECHAS DE VENCIMIENTOS DE DIVIDENDOS */
   select convert(varchar(10),fecha_fin,@i_formato_fecha), 
          convert(float, 0)
   from #cr_facturas
   where secuencial > @i_dividendo 
   order by secuencial


   select @w_filas = @@rowcount

   select @w_count

end
else select @w_filas = 0,
            @w_count = 1

if @w_filas < @w_count  begin

   /*TAMANIO EN BYTES PARA MAPEAR EL BUFFER*/ 
   select @w_count = (@w_buffer - @w_filas * 18)/20

   if @i_dividendo > 0 and @i_opcion = 0
      select @i_dividendo = 0
   
   if @w_count > 0
      set rowcount @w_count
   else
      set rowcount 0

 
   select secuencial,
          'CAP',
          convert(float, isnull(sum(valor),0))
   from ca_amortizacion_tmp, ca_rubro_op_tmp,#cr_facturas 
   where amt_operacion = @w_operacionca
   and   (secuencial > @i_dividendo ) -- or 
   and   rot_operacion = @w_operacionca
   and   rot_concepto  = amt_concepto
   and   rot_fpago    in ('P','A', 'M','T') 
   group by secuencial, rot_concepto 
   order by secuencial, rot_concepto 


   select @w_count 
end

return 0

ERROR:

exec cobis..sp_cerror
@t_debug='N',         
@t_file   = null,
@t_from   = @w_sp_name,   
@i_num    = @w_error
--@i_cuenta = ' '

return @w_error

go