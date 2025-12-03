/************************************************************************/
/*      Archivo:                capitaliza.sp                           */
/*      Stored procedure:       sp_parametros_capitalizacion            */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Christian De la Cruz 			*/
/*      Fecha de escritura:     Jul. 1998                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA"							*/
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/* Parametrizacion de la Forma de capitalizacion de una Operacion       */
/************************************************************************/  
/*                              MODIFICACIONES                          */
/*      FECHA     AUTOR                        RAZON                    */
/*                                     PERSONALIZACION B.ESTADO         */
/************************************************************************/ 
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_parametros_capitalizacion')
	drop proc sp_parametros_capitalizacion
go
create proc sp_parametros_capitalizacion
@s_user            login    = null,  
@s_sesn            int      = null,  
@s_date            datetime = null,  
@s_term            varchar(30)= null,
@s_ofi             smallint = null,       
@i_opcion_cap	   char(1) = null,
@i_valor_inicial   money   = null,
@i_tasa_cap        float = null,
@i_dividendo_cap   smallint = null,
@i_banco           cuenta,
@i_operacion       char(1)

as
declare 
@w_sp_name		descripcion,
@w_operacionca          int,
@w_rubro_capt           varchar(30),
@w_porcentaje_intc      float,
@w_porcentaje_intc_aux  float,
@w_porcentaje_intc_efa  float,
@w_porcentaje           float,
@w_porcentaje_aux       float,
@w_porcentaje_efa       float,
@w_error                int,
@w_return               int


/* CARGAR VALORES INICIALES */
select @w_sp_name = 'sp_parametros_capitalizacion'

select @w_operacionca = opt_operacion
from ca_operacion_tmp
where opt_banco = @i_banco

begin tran
if @i_operacion = 'I' begin
   /* PORCENTAJE DE CAPITALIZACION Y UNA CUOTA DE INICIO */
   if @i_opcion_cap = 'D'  begin
      exec @w_return      = sp_modificar_operacion_int
      @s_user             = @s_user,
      @s_sesn             = @s_sesn,  
      @s_date             = @s_date,  
      @s_term             = @s_term,
      @s_ofi              = @s_ofi,       
      @i_banco            = @i_banco,
      @i_opcion_cap       = @i_opcion_cap,   --D
      @i_tasa_cap         = @i_tasa_cap,
      @i_dividendo_cap    = @i_dividendo_cap

     if @w_return != 0 begin 
         select @w_error = @w_return 
         goto ERROR                                                         
      end                                                                    
   end 

   /*DADO UN VALOR INICIAL DE CUOTA*/
   if @i_opcion_cap = 'C'  begin 
      exec @w_return      = sp_modificar_operacion_int
      @s_user             = @s_user,
      @s_sesn             = @s_sesn,  
      @s_date             = @s_date,  
      @s_term             = @s_term,
      @s_ofi              = @s_ofi,       
      @i_banco            = @i_banco,
      @i_opcion_cap       = @i_opcion_cap,  --C
      @i_tasa_cap         = @i_tasa_cap,    --null
      @i_dividendo_cap    = @i_dividendo_cap --null
                                                
      if @w_return != 0                               
      begin                                           
         select @w_error = @w_return                  
         goto ERROR                                   
      end                                             
   end

   /* NO APLICAR CAPITALIZACION */
   if @i_opcion_cap = 'N' begin
      update ca_operacion_tmp set 
      opt_opcion_cap     = @i_opcion_cap,
      opt_tasa_cap       = null,
      opt_dividendo_cap  = null
      where opt_operacion = @w_operacionca

      if @@error != 0 begin                                                 
         select @w_error = 710002
         goto ERROR                                                         
      end

   
     if @@error != 0 
     begin                                                 
        select @w_error = 710002
        goto ERROR                                                         
     end
   end

end

if @i_operacion = 'Q' begin
   select                                
   opt_opcion_cap,                        
   opt_tasa_cap,
   opt_dividendo_cap
   from                                  
   ca_operacion_tmp                     
   where opt_operacion = @w_operacionca
end

commit tran   

return 0

ERROR:                                    
exec cobis..sp_cerror    
   @t_debug = 'N',       
   @t_from  = @w_sp_name,
   @i_num   = @w_error   

return @w_error                           
                                          
go
