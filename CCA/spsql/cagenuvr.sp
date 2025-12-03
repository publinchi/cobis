/************************************************************************/
/*      Archivo:                Cagenuvr.sp                             */
/*      Stored procedure:       sp_generacion_uvr                       */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */      
/*      Fecha de escritura:     Ene  2003                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.							                                    */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Generar el valor UVR para todos los dias de un periodo dado     */
/*      							                                             */
/************************************************************************/  
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR           RAZON                           */
/*      22/Ene/2003     M. Mari¤o         			                     */
/*      11/Mar/2003     Julio C Quintero  Ajuste Par metros y F¢rmula   */
/*      06/Feb/2007     Elcira Pelaez B.  defecto Nro. 7848             */
/************************************************************************/ 

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_generacion_uvr')
	drop proc sp_generacion_uvr
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

create proc sp_generacion_uvr (
         @s_user                varchar(14),
	 @i_fecha_inicial		datetime)

as
declare 
@w_error			int,
@w_sp_name			descripcion,
@w_vipc				float,
@w_mes				int,
@w_ano				int,
@w_dia				int,
@w_numdias			float,
@w_uvr_inicial			float,
@w_existe_valor			float,
@w_ejecutar			int,
@w_mes_anterior			int,
@w_anoipc			int,
@w_date				varchar(10),
@w_fecha_uvr			datetime,
@w_fecha_final			varchar(10),
@w_mes_siguiente		int,
@w_ano_fechafinal		int,
@w_t				float,
@w_expo				float,
@w_parcial			float,
@w_valor_final			float,
@w_moneda_uvr                   tinyint,
@w_variacion_ipc                catalogo
	

/*  NOMBRE DEL SP  */
select  @w_sp_name = 'sp_generacion_uvr' 

return 0

---Los procesos de este programa los ejecuta el programa tablamor.sp
--Por este motivo se inactiva el desarrollo siguiente

select @w_mes = datepart(mm,@i_fecha_inicial)
select @w_ano = datepart(yy,@i_fecha_inicial)
select @w_dia = datepart(dd,@i_fecha_inicial)

select @w_mes_anterior = datepart(mm,dateadd(mm,-1,@i_fecha_inicial)) --mes de donde se toma el IPC
select @w_anoipc = datepart(yy,dateadd(mm,-1,@i_fecha_inicial)) -- a¤o de donde se toma IPC
								-- por lo general es el de la fecha inicial 
								-- a menos de que el mes sea 1

/* MONEDA UVR */

select  @w_moneda_uvr = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'MUVR'
set transaction isolation level read uncommitted

/* VARIACION IPC */

select  @w_variacion_ipc = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'VIPC'
set transaction isolation level read uncommitted

if @w_dia > 15 begin 
   select @w_existe_valor = isnull(ct_valor,0)       -- mira si ya esta calculado el uvr para la fecha inicial
   from   cob_conta..cb_cotizacion
   where  ct_fecha = @i_fecha_inicial
   and    ct_moneda = @w_moneda_uvr --uvr
   set transaction isolation level read uncommitted

   if @w_existe_valor = 0 or @w_existe_valor is null  -- sino esta calculado lo calcula
      select @w_ejecutar = 1
   else 
      select @w_ejecutar = 0

end
else -- @w_dia < 15 
begin
   select @w_existe_valor = isnull(ct_valor,0)	     --si el dia de la fecha inicial es menor que 15
   from   cob_conta..cb_cotizacion		     --revisa si ya existe valor uvr para algun dia despues 
   where  ct_fecha = dateadd(dd,15,@i_fecha_inicial) --del 15 del mismo mes
   and    ct_moneda = @w_moneda_uvr  --uvr	
   set transaction isolation level read uncommitted

   if @w_existe_valor = 0 or @w_existe_valor is null
      select @w_ejecutar = 1
   else 
      select @w_ejecutar = 0
end

if  @w_ejecutar = 1 begin
  select @w_fecha_uvr = convert(varchar(2),@w_mes) + '/16/' + convert(varchar(4),@w_ano)
  select @w_mes_siguiente = datepart(mm,dateadd(mm,1,@i_fecha_inicial)) 
  select @w_ano_fechafinal = datepart(yy,dateadd(mm,1,@i_fecha_inicial)) 

  select @w_fecha_final = convert(varchar(2),@w_mes_siguiente) + '/15/' + convert(varchar(4),@w_ano_fechafinal)


  select @w_uvr_inicial = isnull(ct_valor,0)
  from cob_conta..cb_cotizacion
  where ct_moneda = @w_moneda_uvr -- UVR 
  and ct_fecha = (select max(ct_fecha)
	          from   cob_conta..cb_cotizacion
	          where  ct_moneda = @w_moneda_uvr)	
  set transaction isolation level read uncommitted
 
  if @w_uvr_inicial = 0 or @w_uvr_inicial is null begin
     select @w_error = 710390
     goto ERROR
  end 

  select @w_date = convert(varchar(10),@w_mes_anterior) + '/1/' + convert(varchar(10),@w_anoipc)

  select @w_vipc = isnull(vr_valor,0)
  from   ca_valor_referencial
  where  vr_tipo = @w_variacion_ipc
  and    vr_fecha_vig = @w_date	

--print 'VARIACION IPC %1!'+ @w_vipc 

  if @w_vipc = 0 or @w_vipc is null begin
     select @w_error = 710388
     goto ERROR
  end 

  if @w_mes = 1
     select @w_numdias = 31
  else 
  if @w_mes = 2 begin 
     if (@w_ano % 4) = 0
       select @w_numdias = 29
     else
       select @w_numdias = 28		
  end
  else if @w_mes = 3
     select @w_numdias = 31
  else if @w_mes = 4
     select @w_numdias = 30
  else if @w_mes = 5
     select @w_numdias = 31
  else if @w_mes = 6
     select @w_numdias = 30.
  else if @w_mes = 7
     select @w_numdias = 31
  else if @w_mes = 8
     select @w_numdias = 31
  else if @w_mes = 9
     select @w_numdias = 30
  else if @w_mes = 10
     select @w_numdias = 31
  else if @w_mes = 11
     select @w_numdias = 30
  else if @w_mes = 12
     select @w_numdias = 31


  select @w_t = 1

  while datediff(dd,convert(datetime,@w_fecha_uvr), convert(datetime,@w_fecha_final)) >= 0 begin


--- FORMULA CALCULO UVR 
     select @w_expo        = round(convert(float,(@w_t / @w_numdias)),4)
     select @w_parcial     = round(convert(float,POWER(1 + @w_vipc,@w_expo)),4)
     select @w_valor_final = round(convert(float,(@w_parcial * @w_uvr_inicial)),4)

    insert into cob_conta..cb_cotizacion (ct_moneda,ct_fecha,ct_valor,ct_compra,ct_venta,ct_factor1,ct_factor2)
    values (@w_moneda_uvr,@w_fecha_uvr,@w_valor_final,@w_valor_final,@w_valor_final,1,1)
    
    select @w_t = @w_t + 1 		
    select @w_fecha_uvr = dateadd(dd,1,@w_fecha_uvr)
  end  
	
end 
                                             

return 0

ERROR:

PRINT 'cagenuvr.sp ATENCION!!! Revisar los errores, proceso no Existoso ' + cast(@w_error as varchar)
insert into ca_errorlog
      (er_fecha_proc,      er_error,      er_usuario,
       er_tran,            er_cuenta,     er_descripcion,
       er_anexo)
values(@i_fecha_inicial,   @w_error,      @s_user,
       0,                  '',             'ERROR GENERANDO LA UVR PARA EL REPORTE',
       ''
       ) 

return @w_error

go

