/************************************************************************/
/*Archivo                       :  capagopp.sp                          */
/*Stored procedure              :  sp_ppas_aplicados_reporte            */
/*Base de datos                 :  cob_cartera                          */
/*Producto                      :  Cartera                              */
/*Disenado por                  :  Elcira Pelaez                        */
/*Fecha de escritura            :  Enero 2002                           */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*Este programa es parte de los paquetes bancarios propiedad de         */
/*"MACOSA" Su uso no autorizado queda expresamente prohibido asi como   */
/*cualquier alteracion o agregado hecho por alguno de sus               */
/*usuarios sin el debido consentimiento por escrito de la               */
/*Presidencia Ejecutiva de MACOSA o su representante.                   */
/************************************************************************/
/*                             PROPOSITO                                */
/*Carga tabla para reporte de prepagos  aplicados                       */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*                                                                      */
/************************************************************************/     

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'ca_pprepgospas_aplicados')
   DROP TABLE ca_pprepgospas_aplicados
go

CREATE TABLE ca_pprepgospas_aplicados ( pap_bsegundo_piso       catalogo null,
                                        pap_banco               cuenta   null,
                                        pap_operacion           int      null,
                                        pap_secuencial          int      null,
                                        pap_identificacion      numero   null,
                                        pap_llave_redescuento   cuenta   null,
                                        pap_fecha_cont          datetime null,
                                        pap_fecha_mov           datetime null,
                                        pap_concepto            catalogo null,
                                        pap_estado              catalogo null,
                                        pap_toperacion          catalogo null,
                                        pap_ofi_oper            int      null,
                                        pap_ofi_usu             int      null,
                                        pap_usuario             login    null,
                                        pap_monto_cap           money    null,
                                        pap_monto_int           money    null)
go


if exists (select * from sysobjects where name = 'sp_ppas_aplicados_reporte')
drop proc sp_ppas_aplicados_reporte
go

create proc sp_ppas_aplicados_reporte (
   @i_fecha_ini         datetime,
   @i_fecha_fin         datetime
)

as declare 

@w_return            int,
@w_sp_name           varchar(30),
@w_secuencial        int,  
@w_operacion         int, 
@w_fecha_cont        datetime,
@w_fecha_mov         datetime,
@w_concepto          catalogo,
@w_estado            catalogo,
@w_toperacion        catalogo,
@w_ofi_oper          int,
@w_ofi_usu           int,
@w_usuario           char(14),
@w_monto_mn          money,
@w_identificacion    numero,
@w_llave_redescuento cuenta,
@w_banco             cuenta,
@w_concepto_int      catalogo,
@w_concepto_cap      catalogo,
@w_cliente           int,
@w_forma_pago        catalogo,
@w_ab_secuencial_rpa int,
@w_bsegundo_piso     catalogo

   

select @w_sp_name    = 'sp_ppas_aplicados_reporte'

truncate table ca_pprepgospas_aplicados

declare cursor_operacion 
 cursor for

 select tr_secuencial,
       tr_operacion,
       dtr_concepto,
       sum(dtr_monto_mn)
from   ca_transaccion,
       ca_det_trn
where tr_tran = 'PAG'
and tr_fecha_mov >= @i_fecha_ini
and tr_fecha_mov <= @i_fecha_fin
and dtr_afectacion = 'C'
and tr_operacion = dtr_operacion
and tr_secuencial = dtr_secuencial
and tr_observacion like 'PREPAGO PASIVA%'
and dtr_monto_mn > 0
and dtr_codvalor <> 21018
group by tr_secuencial,tr_operacion,dtr_concepto
order by tr_operacion,tr_secuencial

for read only

open  cursor_operacion

fetch cursor_operacion 
into @w_secuencial,       
     @w_operacion,        
     @w_concepto,         
     @w_monto_mn         

while @@fetch_status =0 
begin   

   if @@fetch_status = -1 
   begin    
      PRINT '(capagopp.sp)  ERROR!!! en lectura del cursor del reporte'
       return 0
   end   

   select @w_concepto_int = ro_concepto
   from ca_rubro_op
   where ro_operacion  = @w_operacion
   and   ro_tipo_rubro = 'I'
   if @@rowcount = 0
   begin
       fetch cursor_operacion
         into  @w_secuencial,       
               @w_operacion,        
               @w_concepto,         
               @w_monto_mn         
        CONTINUE
   end


   select @w_concepto_cap = ro_concepto
   from ca_rubro_op
   where ro_operacion  = @w_operacion
   and   ro_tipo_rubro = 'C'
   if @@rowcount = 0
   begin
       fetch cursor_operacion
         into  @w_secuencial,       
               @w_operacion,        
               @w_concepto,         
               @w_monto_mn         
         CONTINUE
   end

   select @w_fecha_cont  = tr_fecha_cont,       
          @w_fecha_mov   = tr_fecha_mov,
          @w_estado      = tr_estado,      
          @w_toperacion  = tr_toperacion,      
          @w_ofi_oper    = tr_ofi_oper,      
          @w_ofi_usu     = tr_ofi_usu,
          @w_usuario     = tr_usuario      
  from ca_transaccion
  where tr_operacion = @w_operacion
  and  tr_secuencial = @w_secuencial        
  
      
  select @w_cliente           = op_cliente,
         @w_llave_redescuento = op_codigo_externo,
         @w_banco             = op_banco,
         @w_bsegundo_piso     = op_tipo_linea
  from   ca_operacion    
  where op_operacion = @w_operacion
  
  select @w_identificacion = en_ced_ruc
  from cobis..cl_ente
  where en_ente = @w_cliente
  
  select @w_ab_secuencial_rpa = ab_secuencial_rpa
  from ca_abono
  where ab_operacion = @w_operacion
  and ab_secuencial_pag =  @w_secuencial


   select @w_forma_pago = dtr_concepto
   from ca_det_trn
   where dtr_operacion = @w_operacion
   and dtr_secuencial = @w_ab_secuencial_rpa
   and dtr_afectacion = 'C'
   

  if @w_concepto = @w_concepto_cap 
  begin
     insert into ca_pprepgospas_aplicados (   pap_bsegundo_piso,  pap_banco,           pap_operacion,  
                                              pap_secuencial,     pap_identificacion,  pap_llave_redescuento,   
                                              pap_fecha_cont,     pap_fecha_mov,       pap_concepto,          
                                              pap_estado,         pap_toperacion,      pap_ofi_oper,            
                                              pap_ofi_usu,        pap_usuario,         pap_monto_cap,
                                              pap_monto_int
                                           )
                                              
      values                                 (@w_bsegundo_piso,   @w_banco,             @w_operacion,  
                                              @w_secuencial,      @w_identificacion,    @w_llave_redescuento,   
                                              @w_fecha_cont,      @w_fecha_mov,         @w_forma_pago,
                                              @w_estado,          @w_toperacion,        @w_ofi_oper,            
                                              @w_ofi_usu,         @w_usuario,           @w_monto_mn,
                                              0
                                           )
                                              
  end ---CAP

 if @w_concepto =   @w_concepto_int
 begin
     update  ca_pprepgospas_aplicados
     set     pap_monto_int = @w_monto_mn
     where   pap_operacion  = @w_operacion
     and     pap_secuencial = @w_secuencial                   
 end
                                        
 fetch cursor_operacion into                     
   @w_secuencial,       
   @w_operacion,        
   @w_concepto,         
   @w_monto_mn         
end 
close cursor_operacion
deallocate cursor_operacion

return 0

go
