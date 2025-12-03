/******************************************************************/
/*  Archivo:            CASTIGOS.sp                               */
/*  Stored procedure:   sp_cascara_castigo                        */
/*  Base de datos:      cob_cartera                               */
/*  Producto:           Cartera                                   */
/*  Disenado por:       Xavier Maldonado                          */
/*  Fecha de escritura: 22/Abr/2009                               */
/******************************************************************/
/*                          IMPORTANTE                            */
/*  Este programa es parte de los paquetes bancarios propiedad de */
/*  'MACOSA'                                                      */
/*  Su uso no autorizado queda expresamente prohibido asi como    */
/*  cualquier alteracion o agregado hecho por alguno de sus       */
/*  usuarios sin el debido consentimiento por escrito de la       */
/*  Presidencia Ejecutiva de MACOSA o su representante.           */
/******************************************************************/
/*                          PROPOSITO                             */
/*  Reemplazar al cacasmas.sqr en funciones sirviendo de          */
/*  procedimiento cáscara en invocacion del SP                    */
/*  cob_cartera..sp_castigo_masivo                                */
/******************************************************************/

use cob_cartera
go
set ansi_warnings off
go

if object_id('sp_cascara_castigo') is not null
   drop proc sp_cascara_castigo
go
---INC. 112725 MAY.07.2013
create proc sp_cascara_castigo
   @i_param1   varchar(255) = null
as

declare 
   @w_return         int,
   @w_fecha_proceso  datetime,
   @w_fecha_castigo  datetime,
   @w_reg            int
   
select @w_fecha_proceso = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7
   
exec @w_return = cob_cartera..sp_castigo_masivo 
@s_user   = 'batch',
@s_term   = 'consola',
@s_date   = @w_fecha_proceso

if  @w_return <> 0 
begin
	select  @w_fecha_castigo = max(cm_fecha_castigo)
	from  ca_castigo_masivo
     
	select @w_reg = 0

	select @w_reg = count(1)
	from ca_castigo_masivo
	where cm_estado = 'I'
	and   cm_fecha_castigo = @w_fecha_castigo

 	if @w_reg > 0
 	begin
 	  PRINT ''
 	  PRINT 'ATENCION REVISAR POR QUE QUEDARON ESTAS OPERACIONES SIN CASTIGAR: ' + cast ( @w_reg as varchar)
 	  return 1
 	end
end
ELSE
begin
 PRINT ''
 PRINT 'Fin PRoceso CAStigos Todo Ok'
 return 0
end
go
