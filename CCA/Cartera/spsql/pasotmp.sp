/************************************************************************/
/*      Archivo:                pasotmp.sp                              */
/*      Stored procedure:       sp_pasotmp                              */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           R Garces                                */
/*      Fecha de escritura:     Jul. 1997                               */
/************************************************************************/
/*                                  IMPORTANTE                          */
/*   Esta aplicacion es parte de los paquetes bancarios propiedad       */
/*   de COBISCORP.                                                      */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de COBISCORP.    */
/*   Este programa esta protegido por la ley de derechos de autor       */
/*   y por las convenciones  internacionales de propiedad intectual     */
/*   Su uso no autorizado dara derecho a COBISCORP para                 */
/*   obtener ordenes de secuestro o retencion y para perseguir          */
/*   penalmente a los autores de cualquier infraccion.                  */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Copia los datos de una operacion de sus tablas definitivas      */
/*      a sus tablas temporales                                         */
/************************************************************************/  
/*                              MODIFICACIONES                          */
/*      EMP-JJEC            04/Nov/2020    Control de errores para web  */
/*      Kevin Rodriguez     10/Jun/2021    Control de borrado de tem-   */
/*                                         porales por mismo usuario    */
/*      G. Fernandez        06/Ene/2022    Ingreso para nueva tabla     */
/*                                   ca_operacion_datos_adicionales_tmp */
/*      Dilan Morales       12/Ago/2022    R191571-Se envia fecha       */
/*                                         en_terminal                  */
/*      Kevin Rodriguez     18/Ago/2021    R-191711 Valida existencia de*/
/*                                         regs en tablas definitivas   */
/************************************************************************/ 

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_pasotmp')
	drop proc sp_pasotmp
go
create proc sp_pasotmp
@s_user                 login,
@s_term                 varchar(30) = null,
@i_banco		cuenta  = null,
@i_operacionca		char(1) = null,
@i_dividendo		char(1) = null,
@i_amortizacion		char(1) = null,
@i_cuota_adicional	char(1) = null,
@i_rubro_op		char(1) = null,
@i_relacion_ptmo        char(1) = null,
@i_nomina               char(1) = null,
@i_acciones             char(1) = 'N',  
@i_valores              char(1) = 'N'   

as
declare 
@w_operacionca		int ,
@w_error		int ,
@w_sp_name		descripcion,
@w_tipo                 char(1),
@w_moneda               int,
@w_toperacion           catalogo,
@w_rubros_def           int,
@w_rubros_tmp           int

if @i_dividendo = ''  select @i_dividendo	= null
  
if  @i_amortizacion = ''  select @i_amortizacion	= null

if @i_cuota_adicional	= '' select @i_cuota_adicional = null

if @i_rubro_op	= ''  select @i_rubro_op	= null

if @i_relacion_ptmo = '' select @i_relacion_ptmo = null

-- Se aniade rowcount porque no creaba todos
set rowcount 0

select 
@w_operacionca = op_operacion,
@w_moneda      = op_moneda,
@w_toperacion  = op_toperacion
from   ca_operacion
where  op_banco = @i_banco 

/* CONTROL PARA EVITAR QUE DOS USUARIOS EDITEN UNA MISMA OPERACION */
-- KDR 10Jun2021 Validación cuando el usuario carga en temporales una operación.
if exists(select 1 from ca_operacion_tmp
where opt_operacion = @w_operacionca)
BEGIN
   if (@s_user is not null and @s_user <> '') and (@s_term is not null and @s_term <> '') and @w_operacionca is not null 
   begin 
      IF EXISTS (SELECT 1 FROM ca_en_temporales 
                  WHERE en_usuario = @s_user 
                  -- AND en_terminal = @s_term   -- KDR 18/06/21 Se comenta temporalmente or pruebas en ambiente certificación
                  AND en_operacion = @w_operacionca)
      BEGIN
         exec @w_error = sp_borrar_tmp
         @i_banco  = @i_banco,
         @s_term   = @s_user,
         @s_user   = @s_user
		
		if @w_error <> 0
		begin
		   select @w_error = @w_error
		   goto ERROR
		end 
		
      END
      ELSE
      BEGIN
         select @w_error = 710018
         goto ERROR
      end 
   END
   ELSE
   BEGIN
     select @w_error = 710469
     goto ERROR
   END
end

-- Programa que verifica la existencia de registros en Definitivas antes de pasarlas a las Temporales.
exec @w_error = sp_verifica_tmps_defs
@i_banco		= @i_banco ,  
@i_operacionca	= @i_operacionca, 
@i_dividendo	= @i_dividendo,
@i_amortizacion	= @i_amortizacion,
@i_rubro_op		= @i_rubro_op,  
@i_opcion       = 'D'              -- Comprueba la existencia de registros en tablas definitivas

if @w_error <> 0
begin
   select @w_error = @w_error
   goto ERROR
end 


if @i_acciones = 'S'
begin
  delete ca_acciones_tmp
  where act_operacion = @w_operacionca

  if @@error !=0 begin
     select @w_error = 710003
     goto ERROR
  end

  insert into ca_acciones_tmp
  select * from ca_acciones
  where  ac_operacion = @w_operacionca

  if @@error != 0 begin
     select @w_error = 710001
     goto ERROR
  end
end

if @i_valores = 'S' begin
   delete ca_valores_tmp
   where vat_operacion = @w_operacionca

   if @@error != 0 begin
      select @w_error = 710003
      goto ERROR
   end

   insert into ca_valores_tmp
   select * from ca_valores  with (rowlock)
   where  va_operacion = @w_operacionca

   if @@error != 0 begin
      select @w_error = 710001
      goto ERROR
   end

end



select @w_tipo = dt_tipo from ca_default_toperacion
where dt_toperacion = @w_toperacion
and   dt_moneda     = @w_moneda


if @i_operacionca = 'S' begin

   delete ca_operacion_tmp
   where  opt_operacion = @w_operacionca

   if @@error != 0 begin
      select @w_error = 710003
      goto ERROR
   end 
   
   insert into ca_operacion_tmp
   select * from ca_operacion
   where  op_operacion = @w_operacionca

   if @@error != 0 begin
      select @w_error = 710001
      goto ERROR
   end
   
   --GFP 06/Ene/2022 paso a temporales de tabla de datos adicionales
   delete ca_operacion_datos_adicionales_tmp
   where  odt_operacion = @w_operacionca

   if @@error != 0 begin
      select @w_error = 710003
      goto ERROR
   end 
   
   insert into ca_operacion_datos_adicionales_tmp
   select * from ca_operacion_datos_adicionales
   where  oda_operacion = @w_operacionca

   if @@error != 0 begin
      select @w_error = 710001
      goto ERROR
   end
   --Fin GFP

end


if @i_dividendo = 'S' begin

   delete ca_dividendo_tmp
   where  dit_operacion = @w_operacionca

   if @@error != 0 begin
      select @w_error = 710003
      goto ERROR
   end        
                      
   insert into ca_dividendo_tmp
   select * from ca_dividendo
   where  di_operacion = @w_operacionca
   
   if @@error != 0
   begin
      select @w_error = 710001
      goto ERROR
   end

   /*DIVIDENDOS ORIGINALES PARA TABLAS DE AMORTIZACION MANUAL */
   delete ca_dividendo_original_tmp
   where  dot_operacion = @w_operacionca

   if @@error != 0 begin
      select @w_error = 710003
      goto ERROR
   end

   insert into ca_dividendo_original_tmp
   select * from ca_dividendo_original
   where  do_operacion = @w_operacionca

   if @@error != 0
   begin
      select @w_error = 710001
      goto ERROR
   end

end

if @i_amortizacion = 'S'
begin
   delete ca_amortizacion_tmp
   where  amt_operacion = @w_operacionca

   if @@error != 0
   begin
      select @w_error = 710003
      goto ERROR
   end        
                      
   insert into ca_amortizacion_tmp
   select * from ca_amortizacion
   where  am_operacion = @w_operacionca

   if @@error != 0
   begin
      select @w_error = 710001
      goto ERROR
   end
end


if @i_nomina = 'S'
begin
   delete ca_nomina_tmp
   where  not_operacion = @w_operacionca

   if @@error != 0
   begin
      select @w_error = 710101
      goto ERROR
   end        

   delete ca_definicion_nomina_tmp
   where  dnt_operacion = @w_operacionca

   if @@error != 0
   begin
      select @w_error = 710101
      goto ERROR
   end


   insert into ca_definicion_nomina_tmp
   select * from ca_definicion_nomina
   where  dn_operacion = @w_operacionca

   if @@error != 0
   begin
      select @w_error = 710101
      goto ERROR
   end

   insert into ca_nomina_tmp
   select * from ca_nomina
   where  no_operacion = @w_operacionca

   if @@error != 0
   begin
      select @w_error = 710101
      goto ERROR
   end            
end              

if @i_rubro_op = 'S'
begin
   delete ca_rubro_op_tmp
   where  rot_operacion = @w_operacionca

   if @@error != 0
   begin
      select @w_error = 710003
      goto ERROR
   end          
                    
   insert into ca_rubro_op_tmp
   select * from ca_rubro_op
   where  ro_operacion = @w_operacionca

   if @@error != 0
   begin
      select @w_error = 710001
      goto ERROR
   end

end

if @i_cuota_adicional = 'S'
begin
   delete ca_cuota_adicional_tmp
   where  cat_operacion = @w_operacionca

   if @@error != 0
   begin
      select @w_error = 710003
      goto ERROR
   end          
                    
   insert into ca_cuota_adicional_tmp
   select * from ca_cuota_adicional
   where  ca_operacion = @w_operacionca

   if @@error != 0
   begin
      select @w_error = 710001
      goto ERROR
   end
end

if @i_relacion_ptmo = 'S' begin
   if @w_tipo = 'R' begin
      delete ca_relacion_ptmo_tmp
      where  rpt_pasiva = @w_operacionca

      if @@error != 0 begin
         select @w_error = 710003
         goto ERROR
      end

      insert into ca_relacion_ptmo_tmp
      select * from ca_relacion_ptmo
      where  rp_pasiva  = @w_operacionca

      if @@error != 0 begin
         select @w_error = 710001
         goto ERROR
      end
   end 
   else begin
      delete ca_relacion_ptmo_tmp
      where  rpt_activa = @w_operacionca

      if @@error != 0 begin
         select @w_error = 710003
         goto ERROR
      end

      insert into ca_relacion_ptmo_tmp
      select * from ca_relacion_ptmo
      where  rp_activa  = @w_operacionca

      if @@error != 0 begin
         select @w_error = 710001
      goto ERROR
      end
   end
end    


---VALIDACION DE LOS RUBROS PASADOS A TEMPORALES

select @w_rubros_def = count(1)
from ca_rubro_op with (nolock)
where ro_operacion = @w_operacionca

select @w_rubros_tmp = count(1)
from ca_rubro_op_tmp with (nolock)
where rot_operacion = @w_operacionca

if @w_rubros_def <> @w_rubros_tmp
begin
  select @w_error = 710561
  goto ERROR
end 




/* LLENADO DE LA TABLA ca_en_temporales CON LOS DATOS DE LA */
/* OPERACION QUE PASO A TEMPORALES                          */

/*VALIDACION QUE LOS CAMPOS NO SEAN NULOS PARA ESTA TABLA*/
--DMO SE ENVIA FECHA EN en_terminal
select @s_term = convert(varchar(10),getdate(),103) + ' ' + convert(varchar(10),getdate(),8)

if (@s_user is null or @s_user = '') or (@s_term is null or @s_term = '') or @w_operacionca is null 
begin
  select @w_error = 710469
  goto ERROR
end 

insert into ca_en_temporales values (@s_user,@s_term,@w_operacionca)



return 0

ERROR:
   exec cobis..sp_cerror
     @t_debug   = 'N',
     @t_file    = null,
     @t_from    = @w_sp_name,
     @i_num     = @w_error--,
     --@i_msg     = @w_msg
   
   return @w_error

go

