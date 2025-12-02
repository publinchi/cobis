 /***********************************************************************/
/*	Archivo:		traslado.sp				*/
/*	Stored procedure:	sp_llave_redescuento    	        */
/*	Base de datos:		cob_cartera				*/
/*	Producto: 		Cartera                                 */
/*	Disenado por:  		Julio Cesar Quintero 			*/
/*	Fecha de escritura:	16/05/2003				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	"MACOSA".							*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la		*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/************************************************************************/
/*				PROPOSITO				*/
/*	Revisa las operaciones con redescuento (op_tipo='R') y le actua-*/
/*      liza la llave de redescuento (op_codigo_externo) a sus operacio-*/
/*      ciones activas relacionadas                                     */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'ca_llave_redescuento')
	drop table ca_llave_redescuento
go
   
create table ca_llave_redescuento
(operacion int,
 pasiva    int null,
 activa    int null,
 codigo    cuenta null,
 fecha     datetime)
go 



if exists (select 1 from sysobjects where name = 'sp_llave_redescuento')
	drop proc sp_llave_redescuento
go

create proc sp_llave_redescuento(
   @i_fecha_proceso     datetime

) 

as 
declare
   @w_sp_name         descripcion,
   @w_return          int,
   @w_operacion       int,
   @w_activa          int,
   @w_pasiva          int,
   @w_banco           cuenta,
   @w_codigo_externo  cuenta,
   @w_max_fecha       datetime


/* CARGAR VARIABLES DE TRABAJO */
select
@w_sp_name       = 'sp_llave_redescuento'


/* GENERAR CURSOR PRINCIPAL DE OPERACIONES DE REDESCUENTO */
declare redescuento cursor for select
op_operacion,
op_banco,
op_codigo_externo
from   ca_operacion  
where  op_estado not in (0,99,10)
and    op_tipo = 'R'                
for read only

open redescuento 

fetch redescuento into @w_operacion, 
                       @w_banco,
                       @w_codigo_externo

while   @@fetch_status = 0 begin

   if (@@fetch_status = -1)  begin
       PRINT 'llaveredes.sp  no hay datos en el cursor redescuento'
   end

   /* BUSCAR OPERACION EN ca_relacion_ptmo */
     
     print 'Procesando Operacion ' + @w_banco       

     select @w_pasiva = null, @w_activa = null, @w_codigo_externo = null

     select @w_pasiva=rp_pasiva, 
            @w_activa=rp_activa, 
            @w_max_fecha = max(rp_fecha_ini)
     from ca_relacion_ptmo
     where rp_pasiva = @w_operacion
     group by rp_pasiva,rp_activa

     if @@rowcount = 0 begin
       select @w_pasiva = null, @w_activa = null, @w_codigo_externo = null
     end
     else begin
          if @w_codigo_externo is null
            select @w_codigo_externo = substring(@w_banco,13,3)
     end

     begin tran

      if @w_pasiva is not null begin
        update ca_operacion
           set op_codigo_externo = @w_codigo_externo
         where @w_operacion = @w_activa
      end

   /*print '@w_pasiva ' + @w_pasiva
     print '@w_activa ' + @w_activa*/

      insert into ca_llave_redescuento 
             (operacion,          pasiva,            activa,
              codigo,             fecha) 
      values (@w_operacion,       @w_pasiva,         @w_activa, 
              @w_codigo_externo,  @i_fecha_proceso)


     commit tran


     fetch redescuento into @w_operacion, 
                            @w_banco,
                            @w_codigo_externo

end /*WHILE CURSOR */
close redescuento              
deallocate redescuento              

/* ACTUALIZACION PASIVA */
begin tran

  update ca_operacion
     set op_codigo_externo = codigo
  from  ca_llave_redescuento
  where op_operacion = pasiva
  and   codigo is not null  

/* ACTUALIZACION ACTIVA */

  update ca_operacion
     set op_codigo_externo = codigo
  from  ca_llave_redescuento
  where op_operacion = activa
  and   codigo is not null  

commit tran

return 0

go
