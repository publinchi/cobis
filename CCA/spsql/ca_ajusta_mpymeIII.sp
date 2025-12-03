/************************************************************************/
/*   Archivo:              ca_ajusta_mpymeII.sp                         */
/*   Stored procedure:     sp_ajusta_mpyme                              */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         XMA                                          */
/************************************************************************/
/*                                  IMPORTANTE                          */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                                   PROPOSITO                          */
/*   Procesa y recalcula cada uno de los rubos MPYME, IVAMPYME de las   */
/*   obligaciones cargadas en el universo (sp_tabla_mpyme).             */
/************************************************************************/
/*                                 MODIFICACIONES                       */
/*   FECHA           AUTOR             RAZON                            */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_ajusta_mpymeIII')
   drop proc sp_ajusta_mpymeIII
go

create proc sp_ajusta_mpymeIII
as 

declare 
@w_sp_name          varchar(50),
@w_tasa             float,
@w_tasa1            float,
@w_tasa2            float,
@w_operacion        int,
@w_cliente          int,
@w_factor_ant       float,
@w_error            int,
@w_banco            cuenta,
@w_count_pag        int,
@w_count_ven        int,
@w_monto_desembolso money,   
@w_op_plazo         smallint,
@w_op_tplazo        catalogo,
@w_plazo_meses      smallint,
@w_en_ced_ruc       varchar(30),
@w_contador         int,
@w_fecha_hoy        datetime


  
--tasa 0  cambia a 7.82
select @w_tasa = 7.82
               
               
set rowcount 0       

select @w_fecha_hoy = getdate(),
       @w_sp_name   = 'sp_ajusta_mpymeIII'
               
               
               
select distinct OPERACION as op, TASA_OR as porcentaje 
into #operac
from cob_cartera..ca_recalculo_mipymes_datos_III
               
select @w_operacion = 0, @w_tasa = 0, @w_contador = 0
               
while 1 = 1 
begin
   set rowcount 1
               
   select 
   @w_operacion   = op,
   @w_factor_ant  = porcentaje 
   from #operac
   where op > @w_operacion
   order by op
               
   if @@rowcount = 0 
   begin
      set rowcount 0
      select * from cob_cartera..ca_recalculo_mipymes_datos_III order by OPERACION, DIVIDENDO 
      break
   end
               
   set rowcount 0
                     
   --PRINT ' Obligacion  a Procesar: ' +  cast (@w_operacion as varchar)
                     
   
   select @w_contador = @w_contador + 1

   PRINT 'Operaciones Procesadas : ' +  cast (@w_contador as varchar)

   --PRINT ' Tasa Original : ' +  cast (@w_factor_ant as varchar)
   --PRINT ' Tasa Nueva: ' +  cast (@w_tasa as varchar)
             
   begin tran           
   exec  @w_error = sp_recalculo_mipymesIII
   @i_operacion   = @w_operacion,
   @i_factor      = @w_tasa,
   @i_factor_ant  = @w_factor_ant 
   if @w_error <> 0
   begin
      PRINT 'Error ' + cast (@w_error as varchar) + ' banco ' +  cast (@w_operacion as varchar)
      goto SALIR
   end
   ELSE
   begin
      ---Poner la tasa al rubro
      ---PRINT 'Despues de sp_recalculo_mipymes_III'
      update ca_rubro_op set 
      ro_porcentaje      = @w_tasa,
      ro_porcentaje_efa  = @w_tasa,
      ro_porcentaje_aux  = @w_tasa
      where ro_operacion = @w_operacion
      and ro_concepto = 'MIPYMES'
      if @@error <> 0
      begin
         PRINT 'Error  EN ACTUALIZACION DE ca_rubro_op 1'
         select @w_error = 705006 
         goto SALIR
      end

  
      /*CONSULTA DATOS*/
       --DESEMBOLSO
      select 
      @w_monto_desembolso = isnull(dm_monto_mn,0)   
      from cob_cartera..ca_desembolso
      where dm_operacion  = @w_operacion
      and   dm_estado     = 'A'
      
      select @w_count_pag = COUNT(1)
      from cob_cartera..ca_dividendo
      where di_operacion = @w_operacion 
      and   di_estado = 3
      
      select @w_count_ven = COUNT(1)
      from cob_cartera..ca_dividendo
      where di_operacion = @w_operacion 
      and   di_estado = 2
      
      select @w_op_plazo = op_plazo,
             @w_op_tplazo = op_tplazo,
             @w_cliente   = op_cliente
      from cob_cartera..ca_operacion
      where op_operacion  = @w_operacion


      select @w_en_ced_ruc = en_ced_ruc
      from cobis..cl_ente
      where en_ente  = @w_cliente
       
      --PLAZO EN MESES
      select @w_plazo_meses = @w_op_plazo * (select td_factor from ca_tdividendo where td_tdividendo = @w_op_tplazo)/30   
            
      update ca_recalculo_mipymes_datos_III set 
      CEDULA           = @w_en_ced_ruc,
      VALOR_DESEMBOLSO = isnull(@w_monto_desembolso,0),
      PLAZO            = isnull(@w_plazo_meses,0),
      CUOTAS_PAGADAS   = isnull(@w_count_pag,0),
      CUOTAS_VENCIDAS  = isnull(@w_count_ven,0)
      where OPERACION  = @w_operacion
      and   CONCEPTO  in ('MIPYMES','IVAMIPYMES')
      if @@error <> 0
      begin
         PRINT 'Error  EN ACTUALIZACION DE ca_recalculo_mipymes_datos_III'
         select @w_error = 708152
         goto SALIR
      end
     
   end

   commit tran

   SALIR:
   if @@trancount > 0 begin
      
      select @w_banco =  convert(varchar,@w_operacion)
      
      exec cob_cartera..sp_errorlog 
      @i_fecha     = @w_fecha_hoy ,
      @i_error     = @w_error, 
      @i_usuario   = 'user_batch', 
      @i_tran      = 708152,
      @i_tran_name = @w_sp_name,
      @i_cuenta    = @w_banco,
      @i_rollback  = 'S'
   end

--Fin Proceso
end

return 0 

go


