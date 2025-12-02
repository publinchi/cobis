/************************************************************************/
/*  Archivo:                borratin.sp                                 */
/*  Stored procedure:       sp_borrar_tmp_int                           */
/*  Base de datos:          cob_cartera                                 */
/*  Producto:               Cartera                                     */
/*  Disenado por:           R Garces                                    */
/*  Fecha de escritura:     Jul. 1997                                   */
/************************************************************************/
/*              IMPORTANTE                                              */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*  de COBISCorp.                                                       */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado hecho por alguno de sus             */
/*  usuarios sin el debido consentimiento por escrito de COBISCorp.     */
/*  Este programa esta protegido por la ley de derechos de autor        */
/*  y por las convenciones internacionales de propiedad inte-           */
/*  lectual. Su uso no autorizado dara derecho a COBISCorp para         */
/*  obtener ordenes de secuestro o retencion y para perseguir           */
/*  penalmente a los autores de cualquier infraccion.                   */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Eliminar las tablas temporales de una operacion                 */
/*                        MODIFICACIONES                                */
/*  FECHA         AUTOR           RAZON                                 */
/*  10/01/2022   G. Fernandez    Ingreso de nueva tabla                 */
/*                               ca_operacion_datos_adicionales_tmp     */
/*  06/07/2022   J. Guzman       Se agregan algunos controles de error  */
/*  13/10/2022   K. Rodriguez    R194789 No bloq. tabla with nolock     */
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_borrar_tmp_int')
    drop proc sp_borrar_tmp_int
go
create proc sp_borrar_tmp_int
   @s_user                 login       = null,
   @s_sesn                 int         = null,
   @s_term                 varchar(30) = null, 
   @i_banco                cuenta      = null,
   @i_operacionca          int         = null 
as
declare @w_operacionca     int,
   @w_error                int,
   @w_sp_name              descripcion,
   @w_tipo                 char(1),
   @w_moneda               int,
   @w_toperacion           catalogo,
   @w_tramite_ficticio     int,
   @w_grupo_fact           int,
   @w_op_pasiva            int,
   @w_cliente              int,
   @w_nombre               descripcion,
   @w_op_relacionada       int

select @w_sp_name = 'sp_borrar_tmp_int'

if @i_operacionca is null
   select @w_operacionca = opt_operacion
   from   ca_operacion_tmp with (nolock)
   where  opt_banco = @i_banco 
else
   select @w_operacionca = @i_operacionca
   

select @w_moneda = opt_moneda,
       @w_toperacion = opt_toperacion,
       @w_tramite_ficticio = opt_tramite_ficticio,
       @w_grupo_fact       = opt_grupo_fact
  from ca_operacion_tmp with (nolock)
 where opt_operacion = @w_operacionca 


select @w_tipo = dt_tipo 
  from ca_default_toperacion
 where dt_toperacion = @w_toperacion
   and dt_moneda     = @w_moneda


if @w_tipo = 'D' begin
   if not exists(select 1 from ca_operacion WITH (nolock) where op_operacion = @w_operacionca) begin
      if @w_grupo_fact is not null
         update cob_credito..cr_facturas with (rowlock)
         set fa_usada = 'N'
         where fa_tramite = @w_tramite_ficticio
         and   fa_grupo   = @w_grupo_fact

         if @@error <> 0 
            return 710002
   end
end


delete ca_operacion_tmp with (rowlock)
where  opt_operacion = @w_operacionca

if @@error <> 0 return 710003

--GFP 10/01/2022
delete ca_operacion_datos_adicionales_tmp with (rowlock)
where  odt_operacion = @w_operacionca

if @@error <> 0 return 710003
    
delete ca_dividendo_tmp  with (rowlock)
where  dit_operacion = @w_operacionca

if @@error <> 0 return 710003

delete ca_dividendo_original_tmp with (rowlock)
where  dot_operacion = @w_operacionca

if @@error <> 0 return 710003
                      
delete ca_amortizacion_tmp with (rowlock)
where  amt_operacion = @w_operacionca

if @@error <> 0 return 710003

-- Se aniade rowcount porque no borraba todos
set rowcount 0

delete ca_rubro_op_tmp with (rowlock)
where  rot_operacion = @w_operacionca
                    
if @@error <> 0 return 710003

delete ca_cuota_adicional_tmp  with (rowlock)
where  cat_operacion = @w_operacionca

if @@error <> 0 return 710003

delete ca_cliente_tmp  with (rowlock)
where clt_user = @s_user
and   clt_sesion = @s_sesn

if @@error <> 0 return 710003

delete ca_deudores_tmp with (rowlock)
where dt_operacion  = 0

if @@error <> 0 return 710003

-- CCA 403
delete ca_seguros_det with (rowlock)
from ca_operacion
where op_operacion  = @w_operacionca
and   op_operacion  = sed_operacion
and   op_estado     = 0

if @@error <> 0
begin
   --print 'ERROR AL ELIMINAR REGISTRO EN ca_seguros_det'
   return 710003
end


delete ca_seguros with (rowlock)
from ca_operacion
where op_operacion  = @w_operacionca
and   op_operacion  = se_operacion
and   op_estado     = 0

if @@error <> 0
begin
   --print 'ERROR AL ELIMINAR REGISTRO EN ca_seguros'
   return 710003
end


if @w_tipo = 'R' begin
   delete ca_relacion_ptmo_tmp  with (rowlock)
   where  rpt_pasiva = @w_operacionca

   if @@error <> 0 return 710003
end 
else begin
   delete ca_relacion_ptmo_tmp  with (rowlock)
   where  rpt_activa = @w_operacionca

   if @@error <> 0 return 710003
end

/* ELIMINACION DEL REGISTRO DE TENENCIA DE OPERACION EN ca_en temporales */
delete ca_en_temporales with (rowlock)
where  en_operacion = @w_operacionca

if @@error <> 0 return 710003


if exists(select 1 from ca_reajuste_tmp 
                   where re_operacion = @w_operacionca) begin
   delete ca_reajuste_det with (rowlock)
   where red_operacion = @w_operacionca
   
   if @@error <> 0
   begin
      --print 'ERROR AL ELIMINAR OPERACION DE ca_reajuste_det'
      return 710003
   end

   delete ca_reajuste with (rowlock)
   where re_operacion = @w_operacionca

   if @@error <> 0
   begin
      --print 'ERROR AL ELIMINAR OPERACION DE ca_reajuste'
      return 710003
   end


   insert into ca_reajuste with (rowlock)
   select re_secuencial, re_operacion, re_fecha, re_reajuste_especial, re_desagio, re_sec_aviso
   from ca_reajuste_tmp
   where  re_operacion = @w_operacionca

   if @@error <> 0
   begin
      --print 'ERROR AL INSERTAR REGISTRO EN ca_reajuste'
      return 710001
   end


   insert into ca_reajuste_det  with (rowlock)
   select ca_reajuste_det_tmp.*
   from ca_reajuste_tmp,ca_reajuste_det_tmp
   where re_operacion = @w_operacionca
  and re_secuencial = red_secuencial 

   if @@error <> 0
   begin
      --print 'ERROR AL INSERTAR REGISTRO EN ca_reajuste_det'
      return 710001
   end


end


delete ca_reajuste_det_tmp with (rowlock)
 from ca_reajuste_tmp,ca_reajuste_det_tmp
where re_operacion  = @w_operacionca
  and re_secuencial = red_secuencial 

if @@error <> 0 return 710003

delete ca_reajuste_tmp with (rowlock)
where re_operacion = @w_operacionca

if @@error <> 0 return 710003

delete ca_acciones_tmp with (rowlock)
where act_operacion = @w_operacionca

if @@error <> 0 return 710003

if @w_tipo = 'C'  --si es redescuento
begin
   declare seleccion_pasiva cursor for
   select rpt_pasiva 
   from ca_relacion_ptmo_tmp
   where rpt_activa = @w_operacionca
   for read only

   open seleccion_pasiva
   fetch seleccion_pasiva into
   @w_op_pasiva

   while   @@fetch_status = 0 
   begin 

      if (@@fetch_status = -1)  
      begin
         --PRINT 'acciones.sp  error en lectura del cursor seleccion_pasiva'
         return 710004
      end

      delete ca_acciones_tmp with (rowlock)
       where act_operacion  = @w_op_pasiva

      if @@error <> 0 
         return 710003

      fetch seleccion_pasiva into
      @w_op_pasiva 
   end
   close seleccion_pasiva
   deallocate seleccion_pasiva
end


select @w_cliente   = op_cliente,
       @w_nombre    = op_nombre
  from ca_operacion
 where op_operacion = @w_operacionca 


if @w_tipo in ('C','R') 
begin
   if @w_tipo = 'C'
   begin
      if exists (select 1  from ca_relacion_ptmo
                  where rp_activa = @w_operacionca)
      begin
         select @w_op_relacionada = rp_pasiva 
           from ca_relacion_ptmo
          where rp_activa = @w_operacionca

         update ca_operacion with (rowlock)
         set op_cliente = @w_cliente,
             op_nombre  = @w_nombre
         where op_operacion = @w_op_relacionada

         if @@error <> 0 
            return 710002
      end
   end


   if @w_tipo = 'R'
   begin
      if exists (select 1  from ca_relacion_ptmo
                  where rp_pasiva = @w_operacionca)
      begin
         select @w_op_relacionada = rp_activa
         from ca_relacion_ptmo
         where rp_pasiva = @w_operacionca

         update ca_operacion with (rowlock)
         set op_cliente = @w_cliente,
             op_nombre  = @w_nombre
         where op_operacion = @w_op_relacionada

         if @@error <> 0 
            return 710002
      end
   end
end


return 0

go
