/******************************************************************************************/
/* Este programa Revisa que los reajustes tengan su detalle   FEB-23-2005                 */
/******************************************************************************************/

use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_revisa_detalle_reaj')
   drop proc sp_revisa_detalle_reaj
go

create proc sp_revisa_detalle_reaj 

as
declare
@w_migrada         cuenta,
@w_banco           cuenta,
@w_operacion       int,   
@w_registros       int,
@w_hora            datetime,
@w_error           int,
@w_fecha_cierre    datetime,
@w_fecha_ref        datetime,
@w_tran             catalogo,
@w_fecha_rej        datetime,
@w_sec_rej          int,
@w_red_secuencial  int,
@w_red_operacion   int,
@w_red_concepto    catalogo,
@w_red_referencial catalogo,
@w_red_signo       char(1),
@w_red_factor      float,
@w_red_porcentaje  float,
@w_fecha_ult_proceso datetime,
@w_max_sec           int,
@w_modalidad             char(1),
@w_concepto_int          catalogo



select @w_registros   = 0,
       @w_sec_rej     = 0,
       @w_max_sec     = 0
 
select @w_hora = convert(char(10), getdate(),8)

--print 'carevisahc.sp A procesar = %1!'+ cast (@w_hora as varchar)

select @w_fecha_cierre = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7


select 
   op_operacion,
   op_banco,
   op_fecha_ult_proceso
into #revisa_rej
from ca_operacion,ca_sin_detalle_rej
where op_operacion = operacion
and   op_estado in (1,2,4,9)

-- CURSOR DE OPERACIONES A ANALIZAR
declare cursor_operacion cursor
for select 
         op_operacion,
         op_banco,
         op_fecha_ult_proceso
from #revisa_rej

open cursor_operacion

fetch cursor_operacion
into  @w_operacion,
      @w_banco,
      @w_fecha_ult_proceso
      

while @@fetch_status = 0
begin
   select @w_registros = @w_registros +1
   
   if exists (select 1 from ca_reajuste
   where re_operacion   =   @w_operacion
   and   re_secuencial = 1)
   begin
      
      if not exists (select 1 from ca_reajuste_det
                     where red_operacion = @w_operacion
                     and red_secuencial = 1)
      begin               
         ---SE INSERTA EL DETALLE DEL SEC 1
         
         select @w_max_sec = isnull(max(red_secuencial),0)
         from ca_reajuste_det
         where red_operacion = @w_operacion
         
         if @w_max_sec > 0
         begin
            select 
                  @w_red_concepto    = red_concepto,
                  @w_red_referencial = red_referencial,
                  @w_red_signo       = red_signo,
                  @w_red_factor      = red_factor,
                  @w_red_porcentaje  = red_porcentaje
            from ca_reajuste_det
            where red_operacion = @w_operacion
            and red_secuencial = @w_max_sec
            
            insert into ca_reajuste_det (
            red_secuencial,red_operacion,red_concepto,red_referencial,
            red_signo,red_factor,red_porcentaje)
            values (
            1,            @w_operacion,@w_red_concepto,@w_red_referencial,
            @w_red_signo,@w_red_factor,isnull(@w_red_porcentaje,0))
            
            --REVIASR SI HAY QUE MODIFICAR LA FECHA DEL REAJSUTE PARA QUE ACTUALICE
             select  @w_fecha_rej = re_fecha
             from ca_reajuste
             where re_operacion   = @w_operacion
             and   re_secuencial = 1
             
             if exists (select 1 from ca_dividendo
                        where di_operacion = @w_operacion
                        and   di_fecha_ini = @w_fecha_rej
                        and   di_estado = 1
                        and   di_fecha_ven != @w_fecha_cierre
                        )
             begin
               --actualizar la fecha para que el reajuste se haga en este momento
               
               PRINT 'actualizo fecha reajuste banco ' + cast (@w_banco as varchar)
               
               select @w_modalidad    = ro_fpago,
                      @w_concepto_int = ro_concepto
               from   ca_rubro_op
               where  ro_operacion  = @w_operacion
               and    ro_tipo_rubro   = 'I'
               and    ro_provisiona   = 'S'
               
                begin tran 
                 exec @w_error = sp_reajuste
                    @s_user          = 'script',
                    @s_term          = 'CONSOLA',
                    @s_date          = @w_fecha_cierre,
                    @s_ofi           = 9000,
                    @i_en_linea      = 'N',
                    @i_fecha_proceso = @w_fecha_rej,
                    @i_operacionca   = @w_operacion,
                    @i_modalidad     = @w_modalidad,
                    @i_cotizacion    = 1,
                    @i_num_dec       = 2,
                    @i_concepto_int  = @w_concepto_int,
                    @i_concepto_cap  = 'CAP',
                    @i_moneda_uvr    = 2,
                    @i_moneda_local  = 0
                   if @w_error != 0
                   begin
                      insert into ca_errorlog
                             (er_fecha_proc,      er_error,      er_usuario,
                              er_tran,            er_cuenta,     er_descripcion,
                              er_anexo)
                      values(@w_fecha_cierre,     @w_error,      'script',
                              7269,               @w_banco,
                              'carevisareajuste.sp REAJSUTANDO CUOTA VIGENTE POR script',
                              null) 
                   end
              commit tran     
               
               
             end
      
         end
      end --sec 1 ca_reajuste_det
   end --sec 1 ca_reajuste
           

   fetch cursor_operacion
   into  @w_operacion,
         @w_banco,
         @w_fecha_ult_proceso

end --while @@fetch_status = 0

close cursor_operacion
deallocate cursor_operacion

select @w_hora = convert(char(10), getdate(),8)

--print 'castigos_seg Finalizo  = %1! %2!'+ cast (@w_registros as varchar ) + cast (@w_hora as varchar)

return 0
