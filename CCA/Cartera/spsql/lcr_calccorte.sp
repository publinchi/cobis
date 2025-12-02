
/************************************************************************/
/*  archivo:                lcr_calccorte.sp                           */
/*  stored procedure:       sp_lcr_calc_corte                          */
/*  base de datos:          cob_cartera                                 */
/*  producto:               credito                                     */
/*  disenado por:           Andy Gonzalez                               */
/*  fecha de documentacion: Noviembre 2018                              */
/************************************************************************/
/*          importante                                                  */
/*  este programa es parte de los paquetes bancarios propiedad de       */
/*  "macosa",representantes exclusivos para el ecuador de la            */
/*  at&t                                                                */
/*  su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  presidencia ejecutiva de macosa o su representante                  */
/************************************************************************/
/*          proposito                                                   */
/*             CALCULA CORTE LCR DADO LA OPERACION                      */
/************************************************************************/

use cob_cartera 
go

if exists(select 1 from sysobjects where name ='sp_lcr_calc_corte')
	drop proc sp_lcr_calc_corte
go

create proc sp_lcr_calc_corte(
@i_operacionca        int,
@i_fecha_proceso      datetime, --
@i_debug              char(1) = 'N',
@o_fecha_corte        datetime        =null out 
)
as 
declare 
@w_periodo_int     int,
@w_plazo           int,
@w_tdividendo      catalogo,
@w_evitar_feriados char(1),
@w_ciudad_nacional int,
@w_msg             varchar(255),
@w_fecha_ini       datetime,
@w_dd              int,
@w_fecha_corte     datetime,
@w_factor          int,
@w_dia_pago        int,
@w_error           int,
@w_dias_gracia     int,
@w_cont            int,  
@w_fecha_piv       datetime      
 
 
--DIAS DE GRACIA
select @w_dias_gracia = pa_int
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'LCRGRA'
and    pa_producto = 'CCA'
set transaction isolation level read uncommitted


select @w_dias_gracia     = isnull(@w_dias_gracia, 7)

--INICIALIZACION DE CUOTA MINIMA 


select @w_ciudad_nacional = pa_int
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'CIUN'
and    pa_producto = 'ADM'
set transaction isolation level read uncommitted
/* CONTROLAR DIA MINIMO DEL MES PARA FECHAS DE VENCIMIENTO */

select 
@w_periodo_int       = op_periodo_int,
@w_plazo             = op_plazo,
@w_tdividendo        = op_tdividendo,
@w_evitar_feriados   = op_evitar_feriados,
@w_dia_pago          = op_dia_fijo
from   ca_operacion
where  op_operacion = @i_operacionca


select @w_fecha_ini = min(tr_fecha_ref) 
from ca_transaccion 
where tr_tran= 'DES'
and tr_estado <> 'RV'
and tr_secuencial >0
and tr_operacion =@i_operacionca


select @w_fecha_ini = isnull( @w_fecha_ini, @i_fecha_proceso )
 


select @w_factor  = td_factor
from   ca_tdividendo 
where  td_tdividendo = @w_tdividendo



if @i_debug  = 'S' print '1.-Fecha Proceso: '+convert(varchar, @i_fecha_proceso)+' '+' Fecha ini: '+convert(varchar, @w_fecha_ini)+' Periodo int: '+convert(varchar, @w_periodo_int)+' '+' Factor: '+convert(varchar, @w_factor)+' '+' Dia de pago: '+convert(varchar, @w_dia_pago)

--TRATAMIENTO SEMANAL -BISEMANAL
if ((@w_factor*@w_periodo_int)%7) = 0 begin 


    --ENCONTRAR EL PRIMER MARTES A PARTIR DE LA FECHA INICIO DE LA OPERACION (CONSIDERA GRACIA INICIAL)
	                          
   select @w_dd            = (@w_factor*@w_periodo_int-datepart(dw,@w_fecha_ini)) +(@w_dia_pago+1)
   select @w_fecha_piv     = dateadd(dd,@w_dd ,@w_fecha_ini)
   if @i_debug  = 'S' print '2.- SEM Fecha pivote '+convert(varchar, @w_fecha_piv)
   
   
   if datediff(dd,@w_fecha_ini,@w_fecha_piv)< @w_dias_gracia select @w_fecha_piv= dateadd(dd,@w_factor*@w_periodo_int,@w_fecha_piv)
   
   if @i_debug  = 'S' print '3.- SEM Fecha pivote '+convert(varchar, @w_fecha_piv)
   --EN CASO DE PRESTAMO ESTE "OLVIDADO"  EN EL TIEMPO SI SE REACTIVA A HOY 
   
   
   select @w_cont  = 1, @w_fecha_corte = @w_fecha_piv 
   
   while @w_fecha_corte < @i_fecha_proceso begin 
      select @w_fecha_corte = dateadd(dd,@w_factor*@w_periodo_int*@w_cont,@w_fecha_piv)
	  
	  while @w_evitar_feriados = 'S' and  exists( select 1 from cobis..cl_dias_feriados where df_ciudad = @w_ciudad_nacional  and df_fecha = @w_fecha_corte) 
         select @w_fecha_corte =dateadd(dd,1,@w_fecha_corte)
	  
      select  @w_cont =  @w_cont +1	  
   end	  
	  
    while @w_evitar_feriados = 'S' and  exists( select 1 from cobis..cl_dias_feriados where df_ciudad = @w_ciudad_nacional  and df_fecha = @w_fecha_corte) 
         select @w_fecha_corte =dateadd(dd,1,@w_fecha_corte)	  
	  
   if @i_debug  = 'S' print '4.- SEM Fecha corte '+convert(varchar, @w_fecha_corte)

end 

--TRATAMIENTO MENSUAL
if ((@w_factor*@w_periodo_int)%30) = 0 begin

   --ENCONTRAR EL PRIMER DIA DE PAGO PARTIR DE LA FECHA INICIO DE LA OPERACION (CONSIDERA GRACIA INICIAL)
    
   --select  @w_fecha_piv  = (case when datepart(dd,@w_fecha_ini) < @w_dia_pago 
   --                               then dateadd(dd,-1*datepart(dd,@w_fecha_ini)+@w_dia_pago,@w_fecha_ini) 
   --                               else dateadd(mm,1,dateadd(dd,-1*datepart(dd,@w_fecha_ini)+@w_dia_pago,@w_fecha_ini)) end) 
  
   if datepart(dd,@w_fecha_ini) < @w_dia_pago 
      select @w_fecha_piv = dateadd(dd,-1*datepart(dd,@w_fecha_ini)+@w_dia_pago,@w_fecha_ini)
   else 
      select @w_fecha_piv = dateadd(mm,1,dateadd(dd,-1*datepart(dd,@w_fecha_ini)+@w_dia_pago,@w_fecha_ini))
	 
   if @i_debug  = 'S' print '2.- MEN Fecha pivote '+convert(varchar,  @w_fecha_piv )	
   
   if datediff(dd,@w_fecha_ini,@w_fecha_piv)< @w_dias_gracia select @w_fecha_piv = dateadd(mm,1,@w_fecha_piv)
   
   if @i_debug  = 'S' print '3.- MEN Fecha pivote'+convert(varchar, @w_fecha_piv)	
   

   select @w_cont  = 1, @w_fecha_corte = @w_fecha_piv 
   
   while @w_fecha_corte < @i_fecha_proceso begin 
      select @w_fecha_corte = dateadd(mm,(@w_factor*@w_periodo_int*@w_cont)/30,@w_fecha_piv )
         
      while @w_evitar_feriados = 'S' and  exists( select 1 from cobis..cl_dias_feriados where df_ciudad = @w_ciudad_nacional  and df_fecha = @w_fecha_corte) 
         select @w_fecha_corte =dateadd(dd,1,@w_fecha_corte)  
		
     select @w_cont  = @w_cont +1		
   end 
   
     while @w_evitar_feriados = 'S' and  exists( select 1 from cobis..cl_dias_feriados where df_ciudad = @w_ciudad_nacional  and df_fecha = @w_fecha_corte) 
         select @w_fecha_corte =dateadd(dd,1,@w_fecha_corte)
   
   if @i_debug  = 'S' print '4.- MEN Fecha corte '+convert(varchar, @w_fecha_corte)	
  
    
end 




   
   
if @i_debug  = 'S' print '5.- Fecha corte '+convert(varchar, @w_fecha_corte)
	   
select    @o_fecha_corte = @w_fecha_corte
		  	 
		 			 
return 0

GO
