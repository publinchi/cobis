/************************************************************************/
/*  Archivo:            actconpr.sp                                     */
/*  Stored procedure    sp_actualiza_conceptos_pr                       */
/*	Base de datos:  	cob_cartera                                     */
/*	Producto:           Cartera                                         */
/*	Disenado por:  		Elcira Pelaez Burbano                           */
/*	Fecha de escritura: 	Julio-04-2001                               */
/************************************************************************/
/*				IMPORTANTE                                              */
/*	Este programa es parte de los paquetes bancarios propiedad de       */
/*	'MACOSA'.                                                           */
/*	Su uso no autorizado queda expresamente prohibido asi como          */
/*	cualquier alteracion o agregado hecho por alguno de sus             */
/*	usuarios sin el debido consentimiento por escrito de la             */
/*	Presidencia Ejecutiva de MACOSA o su representante.                 */
/************************************************************************/  
/*				PROPOSITO                                               */
/*	Procedimiento para actualizar los rubros en credito para las        */
/*  Provisiones                                                         */
/************************************************************************/  
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_actualiza_conceptos_pr')
	drop proc sp_actualiza_conceptos_pr
go

create proc sp_actualiza_conceptos_pr(
	    @i_operacionca       int,
        @i_operacion         char(1),
        @i_banco             cuenta,
	    @i_fecha             datetime,
        @i_concepto          catalogo = null,
        @i_valor             money    = null,
        @i_opcion            char(1)  = null

)
as
declare	
@w_sp_name        descripcion,
@w_return 	  int,
@w_concepto       catalogo,
@w_valor          money,
@w_concepto_cre   catalogo,
@w_operacion      char(1)	

/* Captura nombre de Stored Procedure  */
select	@w_sp_name = 'sp_actualiza_conceptos_pr'

if @i_operacion = 'I'
begin

 declare rubros_op cursor for
 select
 ro_concepto,
 ro_valor
 from  ca_rubro_op
 where ro_operacion  = @i_operacionca
 order by ro_concepto
 for read only

 open rubros_op

 fetch rubros_op into 
 @w_concepto,
 @w_valor


 while (@@fetch_status = 0)
 begin 

     if (@@fetch_status != 0)
     begin
       close rubros_op
       deallocate rubros_op
       return 710124
     end


    select @w_concepto_cre = codigo_sib
    from  cob_credito..cr_corresp_sib
    where tabla = 'T13'
    and codigo = @w_concepto

    if @@rowcount <> 0  and @w_valor > 0
    begin
        exec @w_return =  cob_credito..sp_tmp_concepto
             @i_fecha			=  @i_fecha,
             @i_codigo_producto		=  7,
             @i_numero_operacion     	=  @i_operacionca,
             @i_numero_operacion_banco	=  @i_banco,
             @i_concepto 			=  @w_concepto_cre,
             @i_saldo			=  @w_valor,
             @i_operacion			=  @i_operacion
         if @w_return != 0
         begin
             close rubros_op
              deallocate rubros_op
             return @w_return
         end         
            
    end                

 fetch rubros_op into 
 @w_concepto,
 @w_valor

end

 close rubros_op
 deallocate rubros_op
end /* operacion I */


/* INGRESO DE OTROS CARGOS y ACTUALIZACIONES*/

if @i_operacion = 'O' begin

   if @i_opcion = '0' 
      select @w_operacion = 'U'
   else
      select @w_operacion = 'I'
  
       select @w_concepto_cre = codigo_sib
       from  cob_credito..cr_corresp_sib
       where tabla = 'T13'
       and codigo = @i_concepto
       if @@rowcount <> 0  and @i_valor > 0 begin
	 exec @w_return =  cob_credito..sp_tmp_concepto
	 @i_fecha			=  @i_fecha,
	 @i_codigo_producto		=  7,
	 @i_numero_operacion     	=  @i_operacionca,
	 @i_numero_operacion_banco	=  @i_banco,
	 @i_concepto 			=  @w_concepto_cre,
	 @i_saldo			=  @i_valor,
	 @i_operacion			=  @w_operacion
         if @w_return != 0 
            return @w_return
       end                



end /* operacion O */
/*  FIN INGRESO DE OTROS CARGOS*/


return 0

go
     
