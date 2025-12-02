/************************************************************************/
/*      Archivo:                cuotaspas.sp                    		*/
/*      Stored procedure:       sp_cuotaspas                            */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Jonnatan Peña                           */
/*      Fecha de escritura:     Abr. 2009                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "COBISCORP".                                                    */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de COBISCORP o su representante.          */
/************************************************************************/  
/*                              PROPOSITO                               */
/*     La presente consulta con opción de impresión en formato Crystal  */
/*     Report, genera los próximos vencimientos según un rango de       */
/*     fechas seleccionado                                              */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_cuotaspas ')
   drop proc sp_cuotaspas 
go

create proc sp_cuotaspas  (  
   @i_fecha_ini    datetime = null,
   @i_fecha_fin    datetime = null,
   @i_modo         smallint = null,
   @i_consecutivo  int 		= null
)
as

declare 
   @w_sp_name         varchar(32),
   @w_return          int,
   @w_error           int, 
   @w_msg             varchar(100)

                        
if @i_modo = 0
begin   

IF exists (SELECT  1 FROM sysobjects WHERE name = 'operaciones_cartera')
   drop table operaciones_cartera 

      
CREATE TABLE operaciones_cartera (
consecutivo     smallint    not null,             
operacion       varchar(24) not null,   
fecha_ven       varchar(10) null,
entidad         varchar(100)null,
numero_cred     varchar(24) null,
numero_entidad  varchar(24) null,
numero_cuota    smallint    null,
concepto        varchar(64) null,
valor_monto     money       null 
)


   insert into operaciones_cartera    
   select ROW_NUMBER() OVER (ORDER BY di_operacion) AS 'RowNumber',
   'OPERACION' 			 = di_operacion, 
   'FECHA DE VENCIMIENTO'= convert(varchar(10),di_fecha_ven,101), 
   'ENTIDAD PRESTAMISTA' =(select c.valor from cobis..cl_catalogo c,
                           cobis..cl_tabla t 
                           where c.tabla = t.codigo 
                           and t.tabla = 'ca_tipo_linea'
                           and c.codigo = X.op_tipo_linea),    
   'NUMERO DE CREDITO'   = op_banco, 
   'NUMERO DE LA ENTIDAD'= op_codigo_externo,
   'NUMERO DE CUOTA' 	  = di_dividendo,
   'CONCEPTO'            = am_concepto, 
   'VALOR DEL MONTO'     = case when am_concepto  = 'CAP' then (select sum(am_cuota - am_pagado) from ca_amortizacion where am_operacion = op_operacion and am_concepto = 'CAP' and am_dividendo = di_dividendo)
            				     when am_concepto  = 'INT' then (select sum(am_cuota - am_pagado) from ca_amortizacion where am_operacion = op_operacion and am_concepto = 'INT' and am_dividendo = di_dividendo)  
             				     when am_concepto  not in ('CAP','INT') then  am_cuota - am_pagado end
   from cob_cartera..ca_dividendo,
   cob_cartera..ca_operacion X,
   cob_cartera..ca_amortizacion
   where di_fecha_ven between @i_fecha_ini and  @i_fecha_fin
   and   di_operacion = op_operacion
   and   di_operacion = am_operacion
   and   am_operacion = op_operacion
   and   di_dividendo = am_dividendo
   and   di_estado in (1,0)
   and   op_naturaleza = 'P'
   
   set rowcount 20   
   select * from operaciones_cartera
        		
   
   if @@error <> 0 begin                                                                   
      select                                                                         		 
      @w_error = 703007,                                                            		 
      @w_msg   = 'ERROR AL INSERTAR LA INFORMACION EN TABLA TEMPORAL'		 
      goto ERROR                                                                     		 
   end                                                                               
end
else
begin
   set rowcount 20
         
   select * from operaciones_cartera
   where consecutivo > @i_consecutivo
         		 
   if @@error <> 0 begin                                                                   
      select                                                                         		 
      @w_error = 703007,                                                            		 
      @w_msg   = 'ERROR AL INSERTAR LA INFORMACION EN TABLA TEMPORAL'		 
      goto ERROR                                                                     		 
   end                                                                               

end             		 		 
return 0  
		 
ERROR:

Exec cobis..sp_cerror
@t_debug = 'N',
@t_file  = null, 
@t_from  = @w_sp_name,
@i_num   = @w_error,
@i_msg   = @w_msg

return @w_error   
go
          