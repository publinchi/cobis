/************************************************************************/
/*	Archivo: 		        catasref.sp		 		*/
/*	Stored procedure: 	    sp_copia_tasas_de_admin		        */
/*	Base de datos:  	    cob_cartera				*/
/*	Producto: 		        Cartera					*/
/*	Disenado por:  		    Marcelo Poveda (MACOSA)		     	*/
/*	Fecha de escritura: 	Marzo 2001				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	"MACOSA".							*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/************************************************************************/  
/*				PROPOSITO				*/
/*	Obtener la informaci¢n de tablas de tasas referenciales del     */
/*      ADMIN para cargar estructuras actuales de CARTERA               */
/*      ca_tasa_valor y  ca_valor_referencial       	                */
/************************************************************************/ 
use cob_cartera
go

set ansi_warnings off
go

if exists (select 1 from sysobjects where name = 'sp_copia_tasas_de_admin')
   drop proc sp_copia_tasas_de_admin
go

create proc sp_copia_tasas_de_admin
---INC. 112524 ABR.22.2013
as
declare
@w_return		        int,
@w_sp_name		        descripcion,
@w_tr_tasa		        catalogo,
@w_tr_descripcion	    descripcion,
@w_tr_estado		    catalogo,
@w_secuencial           int,
@w_td_dividendo		    catalogo,
@w_pi_cod_pizarra       int,
@w_pi_valor             float,
@w_pi_fecha_inicio      datetime,
@w_pi_referencia        catalogo,
@w_ca_modalidad         char(1),
@w_tipo_tasa            char(1),
@w_registros_adm        int,
@w_registros_car        int,
@w_error                int

/*
--- INICIALIZACION DE VARIABLES 
select @w_registros_adm  = 0,
       @w_registros_car  = 0


---LIMPIAR LAS TABLAS
delete  cob_cartera..ca_tasa_valor
delete  cob_cartera..ca_valor_referencial


---CURSOR PARA INSERTAR EN cob_cartera..ca_tasa_valor 

declare cursor_tasas_valor cursor for
select 
tr_tasa,
tr_descripcion,
ca_modalidad,
tr_estado
from cobis..te_tasas_referenciales,
     cobis..te_caracteristicas_tasa
where ca_tasa = tr_tasa
for read only

open cursor_tasas_valor

fetch cursor_tasas_valor into 
@w_tr_tasa, 
@w_tr_descripcion, 
@w_ca_modalidad,
@w_tr_estado

while @@fetch_status = 0
begin
   if (@@fetch_status = -1)
   begin
      select @w_error =  708999 
      goto ERROR
   end
       /* AGI  COMENTADO TERMPORAL HASTA CORDINAR CON TESORERIA EL CAMPO PI_CARACTERISTICA   
	   select @w_tipo_tasa = max(pi_caracteristica)
	   from cobis..te_pizarra
	   where pi_referencia = @w_tr_tasa
	   set transaction isolation level read uncommitted
        */
   if @w_tipo_tasa is null
         select @w_tipo_tasa = 'E'
 
    insert cob_cartera..ca_tasa_valor
    values(@w_tr_tasa, @w_tr_descripcion, @w_ca_modalidad, 'A', @w_tr_estado, @w_tipo_tasa)

    if @@error <> 0   begin
     PRINT 'error insertando  cob_cartera..ca_tasa_valor  Tasa Referencial' + CAST(@w_tr_tasa AS VARCHAR)
     goto SIGUIENTE
    end

   SIGUIENTE:
   fetch cursor_tasas_valor into 
   @w_tr_tasa, 
   @w_tr_descripcion, 
   @w_ca_modalidad,
   @w_tr_estado

end
close cursor_tasas_valor
deallocate cursor_tasas_valor

select  @w_registros_adm = count(1)
from cobis..te_tasas_referenciales,
     cobis..te_caracteristicas_tasa
where ca_tasa = tr_tasa

select  @w_registros_car = count(1)
from cob_cartera..ca_tasa_valor

PRINT 'respalta.sp resultados  hay en cobis  ' + CAST(@w_registros_adm AS VARCHAR) + ' en ca_tasa_valor : ' + CAST(@w_registros_car AS VARCHAR)

---CURSOR PARA INSERTAR EN cob_cartera..ca_valor_referencial 

declare cursor_valor_referencial cursor for
select 
pi_cod_pizarra,
pi_valor,
pi_fecha_inicio,
pi_referencia
from cobis..te_pizarra  
order by pi_cod_pizarra
for read only

open cursor_valor_referencial

fetch cursor_valor_referencial into 
@w_pi_cod_pizarra,
@w_pi_valor,
@w_pi_fecha_inicio,
@w_pi_referencia

while @@fetch_status = 0
begin
   if (@@fetch_status = -1)
   begin
      select @w_error = 708999
      goto ERROR 
   end

       --- SECUENCIAL PARA CAMPO  vr_secuencial 
       exec @w_secuencial = sp_gen_sec
       @i_operacion  = -1

   
       insert cob_cartera..ca_valor_referencial values
       (@w_pi_referencia,@w_pi_valor,@w_pi_fecha_inicio,@w_secuencial)
       if @@error <> 0   begin
       PRINT 'error insertando  cob_cartera..ca_valor_referencial  Tasa fecha ' + CAST(@w_pi_referencia AS VARCHAR) + ' ' + CAST(@w_pi_fecha_inicio AS VARCHAR)
       goto SIGUIENTE1
      end

 
   SIGUIENTE1:
   fetch cursor_valor_referencial into 
   @w_pi_cod_pizarra,
   @w_pi_valor,
   @w_pi_fecha_inicio,
   @w_pi_referencia

end
close cursor_valor_referencial
deallocate cursor_valor_referencial

select @w_registros_adm = 0,
       @w_registros_car = 0

select  @w_registros_adm = count(1)
from cobis..te_pizarra

select  @w_registros_car = count(1)
from cob_cartera..ca_valor_referencial


PRINT 'respalta.sp resultados  hay en pizarra  ' + CAST(@w_registros_adm AS VARCHAR) + ' en ca_valor_referencial : ' + CAST(@w_registros_car AS VARCHAR)

return 0

ERROR:
   insert into ca_errorlog
   (er_fecha_proc,     er_error,      er_usuario,
   er_tran,            er_cuenta,     er_descripcion,
   er_anexo)
   values(getdate(),     @w_error,      'operador',
   7269,               'BATCH7961',   'ERROR EN CURSON DE COPIA DE TASAS',
   'COPIANDO DE PIZARRA A CARTERA' ) 
*/
return 0
go

