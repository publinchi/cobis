/************************************************************************/
/*	Archivo:		defectiv.sp				*/
/*	Stored procedure:	sp_datos_efectiva                       */
/*	Base de datos:		cob_cartera				*/
/*	Producto: 		Credito y Cartera			*/
/*	Disenado por:  	        Rodrigo Garces	                        */
/*	Fecha de escritura:	07/14/1997				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	"MACOSA"							*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/************************************************************************/  
/*				PROPOSITO				*/
/*      Devolver al front-end la informacion necesaria par que pueda    */
/*      determinar la tasa efectiva de una operacion                    */
/************************************************************************/
/*				MODIFICACIONES				*/
/*	FECHA		AUTOR		RAZON				*/
/*	07/14/1997	Rodrigo Garces  Emision inicial			*/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_datos_efectiva')
    drop proc sp_datos_efectiva
go

create proc sp_datos_efectiva (

/* PARAMETROS DEL KERNEL */

@t_debug	 char(1)     = 'N',
@t_file		 varchar(14) = null,
@t_from		 descripcion = null,

/* PARAMETROS DEL PROGRAMA */

@i_en_linea	 char(1)   = 'S',
@i_simulacion	 char(1),
@i_operacion     int       = null,
@i_banco         cuenta    = null,
@i_toperacion    catalogo  = null,
@i_moneda        tinyint   = null,
@i_temporal      char(1)   = null,
@i_opcion        char(1)
)
as

declare

/* VARIABLES GENERALES */

/* @w_today	datetime,  ELIMINADO Mar 3/1999 */
@w_return	int,     
@w_sp_name	varchar(32),
@w_error	int,		 

/* VARIABLES DEL PROGRAMA */

@w_valor_actual money,
@w_factor       int,
@w_nueva_dif    money,
@w_monto_neto   money,
@w_tasa         float,
@w_dias_anio    smallint,
@w_toperacion   catalogo,
@w_moneda       tinyint,
@w_operacion    int

select @w_sp_name = 'sp_datos_efectiva'

if @i_simulacion = 'S'begin
   select @w_dias_anio  = dt_dias_anio
   from   ca_default_toperacion
   where  dt_toperacion = @i_toperacion
   and    dt_moneda     = @i_moneda
      
   select @w_tasa = sum(rot_porcentaje)
   from   ca_rubro,ca_rubro_op_tmp,ca_operacion_tmp
   where  rot_operacion    = @i_operacion
   and    rot_tipo_rubro   = 'I' 
   and    rot_fpago        = 'P' 
   and    rot_concepto     = ru_concepto       
   and    opt_operacion    = @i_operacion
   and    opt_toperacion   = ru_toperacion
   and    opt_moneda       = ru_moneda  
   
   select @w_dias_anio,null,isnull(@w_tasa,0)

   select datediff(dd,dit_fecha_ini,dit_fecha_ven)
   from   ca_dividendo_tmp
   where  dit_operacion = @i_operacion
   order  by dit_dividendo 

   select sum(amt_cuota)
   from   ca_amortizacion_tmp,ca_rubro
   where  amt_operacion    = @i_operacion
   and    ru_toperacion   = @i_toperacion
   and    ru_moneda       = @i_moneda
   and    amt_concepto     = ru_concepto   
   group  by amt_dividendo
   order  by amt_dividendo
end
else begin
   /* TOMAR LOS DATOS DEL PRESTAMO DE LAS TABLAS DEFINITIVAS */

   select @w_monto_neto = op_monto,
          @w_dias_anio  = op_dias_anio,
          @w_toperacion = op_toperacion,
          @w_operacion  = op_operacion,
          @w_moneda     = op_moneda
   from   ca_operacion
   where  op_banco = @i_banco

   /* AL MONTO HAY QUE DESCONTAR LAS COMISIONES ANTICIPADAS DEL BANCO  */

   select @w_monto_neto = @w_monto_neto - isnull(sum(ro_valor),0)
   from   ca_rubro,ca_rubro_op,ca_operacion
   where  ro_operacion    = @w_operacion
   and    ro_fpago        = 'A' 
   and    ru_concepto     = ro_concepto
   and    op_operacion    = @w_operacion
   and    op_toperacion   = ru_toperacion
   and    op_moneda       = ru_moneda      

   select @w_tasa = sum(ro_porcentaje)
   from   ca_rubro,ca_rubro_op,ca_operacion
   where  ro_operacion    = @w_operacion
   and    ro_tipo_rubro   = 'I' 
   and    ro_fpago        = 'P' 
   and    ro_concepto     = ru_concepto       
   and    op_operacion    = @w_operacion
   and    op_toperacion   = ru_toperacion
   and    op_moneda       = ru_moneda 

   select @w_dias_anio,@w_monto_neto,isnull(@w_tasa,0)

   if @i_temporal = 'S'     
   begin
      select datediff(dd,dit_fecha_ini,dit_fecha_ven)
      from   ca_dividendo_tmp
      where  dit_operacion = @w_operacion
      order  by dit_dividendo 

      select sum(amt_cuota)
      from   ca_amortizacion_tmp,ca_rubro
      where  amt_operacion    = @w_operacion
      and    ru_toperacion   = @w_toperacion
      and    ru_moneda       = @w_moneda
      and    amt_concepto     = ru_concepto  
      group  by amt_dividendo
      order  by amt_dividendo
   end
   else
   begin
      select datediff(dd,di_fecha_ini,di_fecha_ven)
      from   ca_dividendo
      where  di_operacion = @w_operacion
      order  by di_dividendo 

      select sum(am_cuota)
      from   ca_amortizacion,ca_rubro
      where  am_operacion    = @w_operacion
      and    ru_toperacion   = @w_toperacion
      and    ru_moneda       = @w_moneda
      and    ru_tipo_rubro  in ('C','I')
      and    am_concepto     = ru_concepto  
      group  by am_dividendo
      order  by am_dividendo
   end
end

return 0

/* MANEJADOR DE ERRORES */
ERROR:
if @i_en_linea = 'S'
   exec cobis..sp_cerror 
   @t_debug = @t_debug,
   @t_file  = @t_file,
   @t_from  = @w_sp_name,   
   @i_num   = @w_error

return @w_error        

go
