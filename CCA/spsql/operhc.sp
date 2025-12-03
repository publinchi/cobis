/************************************************************************/
/*   Archivo:              operhc.sp                                    */
/*   Stored procedure:     sp_operacion_hc                              */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Credito y Cartera                            */
/*   Disenado por:         Fabian Quintero                              */
/*   Fecha de escritura:   Ene. 1998                                    */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   "MACOSA".                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Guarda la informacion basica de las obligaciones a fin de mes      */
/*                            MODIFICACIONES                            */
/*                                                                      */
/************************************************************************/

use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_operacion_hc')
   drop proc sp_operacion_hc
go

create proc sp_operacion_hc
@i_fecha      datetime
as
declare
   @w_siguiente_habil   datetime,
   @w_siguiente_dia     datetime,
   @w_ciudad_nacional   int,
   @w_error             int,
   @w_rowcount          int
   
select @w_ciudad_nacional = pa_int
from   cobis..cl_parametro
where  pa_nemonico = 'CIUN'
and    pa_producto = 'ADM'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0
begin
   select @w_error = 101024
   goto ERROR_HC
end

begin
   select @w_siguiente_dia = dateadd(dd, 1, @i_fecha)
   
   exec sp_dia_habil
        @i_fecha  = @w_siguiente_dia,
        @i_ciudad = @w_ciudad_nacional,
        @o_fecha  = @w_siguiente_habil out
   
   if datepart(mm, @i_fecha) != datepart(mm, @w_siguiente_habil)
   or datepart(mm, @i_fecha) != datepart(mm, @w_siguiente_dia) -- FIN DE MES
   begin
      if datepart(mm, @i_fecha) = datepart(mm, @w_siguiente_dia)
      begin
         select @w_siguiente_habil = @i_fecha
         while datepart(mm, @i_fecha) = datepart(mm, @w_siguiente_habil)
            select @i_fecha = dateadd(dd, 1, @i_fecha)
         
         select @i_fecha = dateadd(dd, -1, @i_fecha)
      end
      
      select @i_fecha
      
      begin tran
      delete ca_operacion_hc
      where  oh_fecha = @i_fecha
      commit
      
      begin tran
      
      insert into ca_operacion_hc
            (oh_fecha,           oh_banco,      oh_operacion,
             oh_oficina,         oh_toperacion, oh_moneda,
             oh_clase,           oh_destino,    oh_calificacion,
             oh_gar_admisible,   oh_tipo_linea, oh_estado)
      select @i_fecha,           op_banco,      op_operacion,
             op_oficina,         op_toperacion, op_moneda,
             op_clase,           op_destino,    isnull(op_calificacion, 'A'),
             isnull(op_gar_admisible, 'N'),   op_tipo_linea, op_estado
      from   ca_operacion noholdlock
      where  op_estado not in (99, 0, 3)
      
      commit
   end
   ELSE
      print 'no copia'
   return 0
end

ERROR_HC:
while @@trancount > 0 rollback

exec cobis..sp_cerror 
     @t_debug = 'N',
     @t_file  = null,
     @t_from  = 'sp_operacion_hc',
     @i_num   = @w_error,
     @i_msg   = ''
return @w_error

go
