/************************************************************************/
/*   Archivo:                 tabamort.sp                               */
/*   Stored procedure:        sp_tablas_amortizacion_srv                */
/*   Base de Datos:           cob_cartera                               */
/*   Producto:                Cartera                                   */
/*   Disenado por:            Edison Cajas M.                           */
/*   Fecha de Documentacion:  Junio. 2019                               */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier autorizacion o agregado hecho por alguno de sus          */
/*   usuario sin el debido consentimiento por escrito de la             */
/*   Presidencia Ejecutiva de MACOSA o su representante                 */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Entregar las tablas de amortización de las operaciones grupales e */
/*   hijas.                                                             */
/************************************************************************/ 
/*                              MODIFICACIONES                          */ 
/*      FECHA           AUTOR           RAZON                           */
/*   18/Jun/2019   Edison Cajas. Emision Inicial                        */ 
/*   25/Jun/2019   Edison Cajas. Actualizar sp_actualiza_hija           */
/*   05/Jul/2019   Edison Cajas. Agregar el ordenamiento de las tablas  */ 
/*                               tipo select y ajutar el sum            */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_tablas_amortizacion_srv')
    drop proc sp_tablas_amortizacion_srv
go

create proc sp_tablas_amortizacion_srv
(
    @i_interfaz  NCHAR(1) = null,
    @i_creditoId VARCHAR(25),
	@t_trn       int    = null
)
as 

declare
    @w_sp_name     descripcion
	,@w_return     int
	,@w_ref_grupal cuenta
	,@w_tciclo     char(1)

declare @w_operaciones table (nro_operacion int, nro_banco varchar(24), grupal char(1), tipo char(1), administracion char(1), ref_grupal cuenta,nro_cliente int, toperacion varchar(24))

    SELECT @w_sp_name = 'sp_tablas_amortizacion_srv'
	
	if @t_trn <> 77520 
    begin
       print 'Transaccion no permitida'	
       return 151051
    end

   insert @w_operaciones
   select op_operacion,op_banco,op_grupal
          ,null
          ,op_admin_individual
	      ,op_ref_grupal
	      ,op_cliente
	      ,op_toperacion
     FROM ca_operacion
    WHERE op_banco = @i_creditoId

    if @@rowcount = 0
    begin 
       print 'ERROR: No existe la operacion.'
       return 710022
    end


--validar el tipo de la operacion
if exists (select 1 from @w_operaciones where grupal = 'S' and  ref_grupal is null and nro_banco = @i_creditoId)
begin

	update @w_operaciones 
	   set tipo = 'G' 
	 where nro_banco = @i_creditoId

	 if exists(select 1 from @w_operaciones where administracion = 'S' and grupal = 'S' and tipo = 'G' and nro_banco = @i_creditoId)
	 begin
        print 'sp_actualiza_grupal' 
			 
        exec @w_return     = sp_actualiza_grupal
             @i_banco      = @i_creditoId,
             @i_desde_cca  = 'N'

        if @w_return != 0
        begin
            print 'ERROR: ACTUALIZANDO DATOS DE OPERACIONES GRUPALES'
            return 70206
        end
	 end 

	 insert @w_operaciones
	 select 
         dc_operacion
		 ,op_banco
		 ,'N'
		 ,dc_tciclo
		 ,op_admin_individual
		 ,op_ref_grupal
		 ,op_cliente
		 ,op_toperacion
	 from ca_det_ciclo, ca_operacion
	 where dc_operacion = op_operacion 
	 and dc_referencia_grupal = @i_creditoId

end else begin
    
	 select @w_tciclo = dc_tciclo 
	   from ca_det_ciclo 
	  where dc_operacion = (
	     select nro_operacion 
		 from @w_operaciones 
		 where nro_banco = @i_creditoId) 

    if (@w_tciclo is null) --INDIVIDUAL
	begin	   
	  update @w_operaciones 
	  set tipo = 'D' 
	  where nro_banco = @i_creditoId

	end else begin	    
		update @w_operaciones 
	    set tipo = @w_tciclo 
	    where nro_banco = @i_creditoId

		 if exists(select 1 from @w_operaciones where administracion = 'N' and grupal = 'S' and tipo = 'N' and nro_banco = @i_creditoId)
	     begin		     
	     
            print 'sp_actualiza_hijas'

            select @w_ref_grupal = ref_grupal 
              from @w_operaciones 
             where nro_banco = @i_creditoId
			 
			if @w_ref_grupal is null
			begin
			    print 'ERROR: OPERACION HIJA NO TIENE REFERENCIA CON EL PADRE'
				RETURN 725051
			end			 

            exec @w_return     = sp_actualiza_hijas
                 @i_banco      = @w_ref_grupal

            if @w_return != 0
            begin
                print 'ERROR: ACTUALIZANDO DATOS DE OPERACIONES HIJAS'
                return 70207
            end
		  
	     end 
	end
end

--OPERACIONES
select 
    'es_grupal'   = tipo
    ,'clienteId'  = nro_cliente
    ,'nro_banco'  = nro_banco
    ,'toperacion' = toperacion
from @w_operaciones

--TIPO SELECT CUOTAS
SELECT 
    'nro_banco'    = nro_banco
	,'nro_cuota'   = di_dividendo
	,'fecha_venc'  = di_fecha_ven
	,'monto_cuota' = sum(am_cuota - am_pagado + am_gracia)
	,'estado'      = (select es_descripcion from ca_estado where es_codigo = di_estado)
 FROM @w_operaciones, ca_dividendo, ca_amortizacion
WHERE nro_operacion = di_operacion
  and nro_operacion = am_operacion
  and di_dividendo  = am_dividendo
group by nro_banco,di_dividendo,di_fecha_ven,di_estado,nro_operacion
order by nro_banco,di_dividendo

--TIPO SELECT RUBROS
SELECT 
    'nro_banco'     = nro_banco
	,'nro_cuota'    = am_dividendo
	,'codigo_rubro' = am_concepto
	,'monto_rubro'  = sum(am_cuota - am_pagado + am_gracia)
 FROM @w_operaciones, ca_amortizacion
WHERE nro_operacion = am_operacion
group by nro_banco,am_dividendo,am_concepto
order by nro_banco,am_dividendo


return 0

go

