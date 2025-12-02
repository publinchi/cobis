/************************************************************************/
/*   Archivo:             cargasal.sp                                   */
/*   Stored procedure:    sp_carga_saldos_anuales                       */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        Luis Alfonso Mayorga                          */
/*   Fecha de escritura:  Julio-2004                                    */
/************************************************************************/
/*                              IMPORTANTE                              */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   "MACOSA"                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/  
/*                             PROPOSITO                                */
/*   Cargar Informacion de saldos anuales para generaci¢n de certifica  */
/*   dos anuales en la tabla  ca_saldos_fin_anio                        */
/*   PARAMETROS:                                                        */
/*             @i_fecha_fin_anio Esta fecha debe ser la de cierre anual */
/*                                                                      */
/************************************************************************/  
/*                             ACTUALIZACIONES                          */
/*                                                                      */
/*     FECHA              AUTOR            CAMBIO                       */
/*      20/Ene/2006     Elcira Pelaez    def-5785                       */
/*      24/FEB/2006     Elcira P.        def.6036                       */
/************************************************************************/

use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_carga_saldos_anuales')
   drop proc sp_carga_saldos_anuales
go

create proc sp_carga_saldos_anuales
@i_fecha_fin_anio       datetime ---ejemplo '12/30/2005'

as declare 
   @w_op_operacion	   int,
   @w_saldo_capital	   money,
   @w_saldo_interes	   money,
   @w_saldo_mora	      money,
   @w_saldo_seguro	   money,
   @w_saldo_otros    	money,
   @w_moneda_local   	tinyint,
   @w_op_moneda		   tinyint,
   @w_cotizacion_hoy    money,
   @w_op_banco          cuenta,
   @w_bloque            int,
   @w_valor_inicial     int,
   @w_valor_final       int,
   @w_num_operaciones   int,
   @w_anio_anterior     datetime,
   @w_msg               descripcion,
   @w_contador          int
   
  select @w_bloque = 50000
  
  select	@w_valor_inicial = 1,
       	@w_valor_final =  @w_bloque

--VALIDACION QUE EXISTA LA INFORMACION DEL AÑO ANTERIOS       	

select @w_anio_anterior = dateadd(yy,-1,@i_fecha_fin_anio)

select @w_contador = isnull(count(1) ,0)
from   ca_saldos_fin_anio
where  sfa_fecha_proceso = @w_anio_anterior

if @w_contador = 0 
begin
   ---INSERTAR ERROR PARA QUE EL USARUO VERIFIQUE
PRINT 'capagoan.sp ATENCION!!! Revisar ERROR NRO. 710537'
select @w_msg = 'NO EXISTEN SALDOS DE FIN DE AÑO ANTERIOR A LA FECHA DE PROCESO'
insert into ca_errorlog
      (er_fecha_proc,      er_error,      er_usuario,
       er_tran,            er_cuenta,     er_descripcion,
       er_anexo)
values(@i_fecha_fin_anio,   710537,        '',
       0,                  'cargasald.sp',            @w_msg,
       @w_msg
       ) 
end
       	
       	
delete  ca_saldos_fin_anio
where sfa_fecha_proceso = @i_fecha_fin_anio
       	
select @w_num_operaciones = max(op_operacion)
from cob_cartera..ca_operacion

while @w_valor_inicial < =   @w_num_operaciones
begin
   

      insert into cob_cartera..ca_saldos_fin_anio
      select @i_fecha_fin_anio,do_numero_operacion_banco,do_saldo_cap,do_saldo_int,0,0,do_saldo_otros
       from cob_conta_super..sb_dato_operacion_rep
      where do_fecha  = @i_fecha_fin_anio
      and  do_numero_operacion   between @w_valor_inicial and @w_valor_final
      and  do_codigo_producto = 7
      and do_tipo_reg = 'M'
      and do_estado_contable  in (1,2,3)


   


   select @w_valor_inicial = @w_valor_final + 1,
          @w_valor_final = @w_valor_final + @w_bloque
             
end

PRINT 'cargasal.sp Fin del proceso' 

return 0


go             



  



