/************************************************************************/
/*      Archivo:                pasodef.sp                              */
/*      Stored procedure:       sp_pasodef                              */
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
/*      Copia los datos de una operacion de sus tablas temporales       */
/*      a sus tablas definitivas                                        */
/************************************************************************/  
/*                             CAMBIOS                                  */
/*  FECHA          AUTOR              CAMBIO                            */
/*  AGO-24-2006   Elcira Pelaez       RFP-126                           */
/*  AGO-15-2014   Fabián Quintero     REQ-392                           */
/*  ENE-05-2017   Lorena Regalado     Incluir tabla de parametros CCA   */
/*  ENE-06-2022   Guisela Fernandez   Ingreso de datos en la tabla      */
/*                                    ca_operacion_datos_adicionales    */
/*  AGO-03-2022   Guisela Fernandez   Validación para borrar tabla      */
/*                                    ca_operacion_datos_adicionales    */
/*  AGO-17/2022  Kevin Rodriguez      R-191711 Valida existencia de regs*/
/*                                    en tablas temporales              */
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_pasodef')
   drop proc sp_pasodef
go

create proc sp_pasodef
   @i_banco             cuenta  = null,
   @i_operacionca       char(1) = null,
   @i_dividendo         char(1) = null,
   @i_amortizacion      char(1) = null,
   @i_cuota_adicional   char(1) = null,
   @i_rubro_op          char(1) = null,
   @i_relacion_ptmo     char(1) = null,
   @i_nomina            char(1) = null,
   @i_acciones          char(1) = 'N',
   @i_valores           char(1) = 'N',
   @i_operacion_ext     char(1) = null     --LRE 05/ENE/2017

as
declare 
   @w_operacionca          int ,
   @w_error                int ,
   @w_rc                   int ,
   @w_sp_name              descripcion,
   @w_tipo_amortizacion    catalogo,
   @w_tipo                 char(1),
   @w_moneda               int,
   @w_toperacion           catalogo,
   @w_gracia_cap           smallint,
   @w_gracia_int           smallint,
   @w_periodo_cap          smallint,
   @w_periodo_int          smallint,
   @w_div_mod              smallint,
   @w_op_pasiva            int,
   @w_moneda_uvr           int,
   @w_moneda_oper          int,
   @w_tramite              int,
   @w_oficina              int,
   @w_op_naturaleza        char(1),
   @w_rubros_basicos       int

set rowcount 0

select @w_operacionca       = opt_operacion,
       @w_tipo_amortizacion = opt_tipo_amortizacion,
       @w_tramite           = opt_tramite,
       @w_oficina           = opt_oficina,
       @w_moneda            = opt_moneda,
       @w_toperacion        = opt_toperacion,
       @w_gracia_cap        = opt_gracia_cap,
       @w_gracia_int        = opt_gracia_int,
       @w_periodo_cap       = opt_periodo_cap,
       @w_periodo_int       = opt_periodo_int,
       @w_tipo              = opt_tipo,
       @w_op_naturaleza     = opt_naturaleza
from   ca_operacion_tmp with (nolock)
where  opt_banco = @i_banco 


--VALIDACION DE LOS RUBROS ANTES DE PASAR A DEFINITIVAS

select @w_rubros_basicos = 0

-- Programa que verifica la existencia de registros en Temporales antes de pasarlas a las Definitivas.
exec @w_error = sp_verifica_tmps_defs
@i_banco		= @i_banco ,  
@i_operacionca	= @i_operacionca, 
@i_dividendo	= @i_dividendo,
@i_amortizacion	= @i_amortizacion,
@i_rubro_op		= @i_rubro_op,  
@i_opcion       = 'T'              -- Comprueba la existencia de registros en tablas temporales

if @w_error <> 0
begin
   select @w_error = @w_error
   goto ERROR
end 

if  @w_op_naturaleza = 'A'
begin
   select @w_rubros_basicos = isnull(count(1),0)
   from ca_rubro_op_tmp
   where rot_operacion = @w_operacionca
   and rot_tipo_rubro in ('C','I','M')
   
   if @w_rubros_basicos < 3 
      begin
         select @w_error = 710562
         goto ERROR
      end
end

if  @w_op_naturaleza = 'P'
begin
   select @w_rubros_basicos = isnull(count(1),0)
   from ca_rubro_op_tmp
   where rot_operacion = @w_operacionca
   and rot_tipo_rubro in ('C','I')
   
   if @w_rubros_basicos < 2 
      begin
         select @w_error = 710562
         goto ERROR
      end
end



if @i_acciones = 'S' 
begin  
   delete ca_acciones with (rowlock)
   where ac_operacion = @w_operacionca
   
   if @@error != 0 
   begin
      select @w_error = 710003
      goto ERROR
   end
   
   insert into ca_acciones  with (rowlock)
   select * from ca_acciones_tmp with (nolock)
   where  act_operacion = @w_operacionca
   
   if @@error != 0  
   begin
      --print 'No se pudo actualizar la información de acciones'
      select @w_error = 710001
      goto ERROR
   end
   
   if @w_tipo = 'C'
   begin
      declare seleccion_pasiva cursor
         for select rpt_pasiva 
             from   ca_relacion_ptmo_tmp
             where  rpt_activa = @w_operacionca
             for read only

      open seleccion_pasiva
      
      fetch seleccion_pasiva
      into  @w_op_pasiva 
      
      while   @@fetch_status = 0 
      begin 
         if (@@fetch_status = -1)  
         begin
--            PRINT 'acciones.sp  error en lectura del cursor seleccion_pasiva'
            return 710004
         end
         
         delete ca_acciones with (rowlock)
         where ac_operacion = @w_op_pasiva
         
         if @@error != 0 
         begin
            select @w_error = 710003
            goto ERROR
         end
         
         insert into ca_acciones  with (rowlock)
         select * from ca_acciones_tmp with (nolock)
         where  act_operacion = @w_op_pasiva
         
         if @@error <> 0 
         begin
            --print 'No se pudo actualizar la información de acciones (2)'
            select @w_error = 710001
            goto ERROR
         end
         
         fetch seleccion_pasiva
         into  @w_op_pasiva
      end
      
      close seleccion_pasiva
      deallocate seleccion_pasiva
   end
end

if @i_valores = 'S'
begin
   delete ca_valores with (rowlock)
   where va_operacion = @w_operacionca
   
   if @@error != 0
   begin
      select @w_error = 710003
      goto ERROR
   end
   
   insert into ca_valores  with (rowlock)
   select * from ca_valores_tmp  with (nolock)
   where  vat_operacion = @w_operacionca

   if @@error != 0
   begin
      --print 'No se pudo actualizar la información de otros valores'
      select @w_error = 710001
      goto ERROR
   end
end

select @w_tipo = dt_tipo
from   ca_default_toperacion
where  dt_toperacion = @w_toperacion
and    dt_moneda     = @w_moneda

if @i_operacionca = 'S'
begin
   delete ca_operacion with (rowlock)
   where  op_operacion = @w_operacionca
   
   if @@error != 0
   begin
      select @w_error = 710003
      goto ERROR
   end
      
   insert into ca_operacion with (rowlock)
   select * from ca_operacion_tmp with (nolock)
   where  opt_operacion = @w_operacionca
   
   if @@error != 0 or @@rowcount = 0
   begin
      select @w_error = 705076
      goto ERROR
   end
   
   --GFP ENE-06-2022 Ingreso en tabla de datos adicionales
   if exists(select 1 from ca_operacion_datos_adicionales_tmp
              where  odt_operacion = @w_operacionca)
   begin
      delete ca_operacion_datos_adicionales with (rowlock)
      where  oda_operacion = @w_operacionca
   
      if @@error != 0
      begin
         select @w_error = 710003
         goto ERROR
      end
	  
      insert into ca_operacion_datos_adicionales with (rowlock)
      select * from ca_operacion_datos_adicionales_tmp with (nolock)
      where  odt_operacion = @w_operacionca
      
      if @@error != 0 or @@rowcount = 0
      begin
         select @w_error = 725135 --Error al insertar registro en ca_operacion_datos_adicionales
         goto ERROR
      end
	  
   end
      

   --fin GFP
   
   if @w_tramite is not null and @w_tramite > 0
   begin
      update cob_credito..cr_tramite   with (rowlock)
      set    tr_oficina =  @w_oficina
      where  tr_tramite =  @w_tramite 
   END
   
   delete ca_datos_adicionales_pasivas
   where dap_operacion = @w_operacionca
   
   if @@error <> 0
   begin
      select @w_error = 705076
      goto ERROR
   END
   
   insert into ca_datos_adicionales_pasivas
   SELECT * FROM ca_datos_adicionales_pasivas_t
   WHERE dat_operacion = @w_operacionca
   
   if @@error <> 0
   begin
      select @w_error = 705076
      goto ERROR
   END
   
end

if @i_dividendo = 'S'
begin
   delete ca_dividendo    with (rowlock)
   where  di_operacion = @w_operacionca
   
   if @@error != 0
   begin
      select @w_error = 710003
      goto ERROR
   end
   
   -- ACTUALIZACION DE CAMPOS di_de_cap - di_de_int
   -- PARA LOS DIVIDENDO QUE TIENEN GRACIA
   
   if @w_gracia_cap > 0 and  @w_periodo_cap <> @w_periodo_int
   begin
      select @w_div_mod = (@w_periodo_cap * @w_gracia_cap ) + @w_periodo_cap
      
      update ca_dividendo_tmp  with (rowlock)
      set    dit_de_capital = 'N'
      where  dit_operacion = @w_operacionca
      and    dit_dividendo < @w_div_mod
   end
   ELSE
   begin
      if @w_gracia_cap > 0 and  @w_periodo_cap = @w_periodo_int
      begin
         update ca_dividendo_tmp with (rowlock)
         set    dit_de_capital = 'N'
         where  dit_operacion = @w_operacionca
         and    dit_dividendo <= @w_gracia_cap
      end
   end
   
   if @w_gracia_int > 0 and  @w_periodo_cap <> @w_periodo_int
   begin
      select @w_div_mod = (@w_periodo_int * @w_gracia_int ) + @w_periodo_int
      
      update ca_dividendo_tmp  with (rowlock)
      set    dit_de_interes = 'N'
      where  dit_operacion = @w_operacionca
      and    dit_dividendo < @w_div_mod
   end
   ELSE
   begin
      if @w_gracia_int > 0 and  @w_periodo_cap = @w_periodo_int
      begin
         update ca_dividendo_tmp with (rowlock)
         set  dit_de_interes = 'N'
         where dit_operacion = @w_operacionca
         and dit_dividendo <= @w_gracia_int
      end
   end
   
   -- FIN DE ACTUALIZACION ca_dividendo_tmp
   insert into ca_dividendo  with (rowlock)
   select * from ca_dividendo_tmp with (nolock)
   where  dit_operacion = @w_operacionca
   select @w_error = @@error,
          @w_rc = @@ROWCOUNT

   if @w_error != 0  or @w_rc = 0
   begin
      --print 'No se pudo actualizar la información de fechas de vencimiento de cuotas ' + convert(varchar, @w_error)
      --+ ' rc=' + convert(varchar, @w_rc)
      select @w_error = 710001
      goto ERROR
   end
   
   delete ca_dividendo_original with (rowlock)
   where  do_operacion = @w_operacionca
   
   if @@error != 0
   begin
      select @w_error = 710003
      goto ERROR
   end
   
   insert into ca_dividendo_original  with (rowlock)
   select * from ca_dividendo_original_tmp with (nolock)
   where  dot_operacion = @w_operacionca
   
   if @@error != 0  
   begin
      --print 'No se pudo actualizar la información de fechas de vencimiento (O)'
      select @w_error = 710001
      goto ERROR
   end
end

if @i_rubro_op = 'S'
begin
   
   
   delete ca_rubro_op  with (rowlock)
   where  ro_operacion = @w_operacionca
   
   if @@error != 0
   begin
      select @w_error = 710003
      goto ERROR
   end
   
   insert into ca_rubro_op  with (rowlock)
   select * from ca_rubro_op_tmp with (nolock)
   where  rot_operacion = @w_operacionca
   
   if @@error != 0  or @@rowcount = 0
   begin
      select @w_error = 703112
      goto ERROR
   end
end


if @i_amortizacion = 'S'
and exists(select 1
           from   ca_amortizacion_tmp
           where  amt_operacion = @w_operacionca)
begin

  
   delete ca_amortizacion with (rowlock)
   where  am_operacion = @w_operacionca
   
   if @@error != 0
   begin
      select @w_error = 710003
      goto ERROR
   end
   
   insert into ca_amortizacion  with (rowlock)
   select * from ca_amortizacion_tmp with (nolock)
   where  amt_operacion = @w_operacionca
   
   if @@error != 0  or @@rowcount = 0
   begin
      --print 'No se pudo actualizar la información de valores de conceptos'
      select @w_error = 710001
      goto ERROR
   end
   
      
   -- SELECCIàN DEL CODIGO DE LA MONEDA
   select @w_moneda_uvr = pa_tinyint from cobis..cl_parametro    
   where  pa_producto = 'CCA'
   and    pa_nemonico = 'MUVR'    
   set transaction isolation level read uncommitted
   
   select @w_moneda_oper = op_moneda,
          @w_op_naturaleza  = op_naturaleza
   from   ca_operacion
   where  op_operacion = @w_operacionca
   
   if @w_moneda_oper = @w_moneda_uvr and @w_op_naturaleza <> 'P'
   begin
      delete ca_correccion with (rowlock)
      where co_operacion = @w_operacionca
      
      insert into ca_correccion with (rowlock)
            (co_operacion,      co_dividendo,      co_concepto,   co_correccion_mn,
             co_correccion_sus_mn,   co_correc_pag_sus_mn,   co_liquida_mn)
      select am_operacion,      am_dividendo,      am_concepto,   0,
             0,         0,         0
      from   ca_rubro_op, ca_amortizacion
      where  ro_operacion   = am_operacion
      and    ro_operacion   = @w_operacionca
      and    am_operacion   = @w_operacionca
      and    ro_concepto    = am_concepto
      and    ro_tipo_rubro in ('C', 'I', 'M')     -- CAPITAL o INTERESES o INTERES DE MORA

      if @@error != 0  or @@rowcount = 0
      begin
         --print 'No se pudo actualizar la información de valores de conceptos (corr. mon).'
         select @w_error = 710001
         goto ERROR
      end

   end
   else 
   begin
      if @w_tipo <> 'D'  --Para factorign no se ingresa este registro
      begin
         delete ca_correccion with (rowlock)
         where co_operacion = @w_operacionca
         
         insert into ca_correccion  with (rowlock)
               (co_operacion,      co_dividendo,      co_concepto,   co_correccion_mn,
                co_correccion_sus_mn,   co_correc_pag_sus_mn,   co_liquida_mn)
         select am_operacion,      am_dividendo,      am_concepto,   0,
                0,         0,         0
         from   ca_rubro_op, ca_amortizacion
         where  ro_operacion   = am_operacion
         and    ro_operacion   = @w_operacionca
         and    am_operacion   = @w_operacionca
         and    ro_concepto    = am_concepto
         and    ro_tipo_rubro in ('C', 'I')     -- CAPITAL o INTERESES 
      
         if @@error != 0  or @@rowcount = 0
         begin
            --print 'No se pudo actualizar la información de valores de conceptos (corr. mon. 2)'
            select @w_error = 710001
            goto ERROR
         end
      end --tipo <> D
   end
end


if @i_cuota_adicional = 'S'
begin
   delete ca_cuota_adicional  with (rowlock)
   where  ca_operacion = @w_operacionca
   
   if @@error != 0
   begin
      select @w_error = 710003
      goto ERROR
   end
   
   insert into ca_cuota_adicional  with (rowlock)
   select * from ca_cuota_adicional_tmp with (nolock)
   where  cat_operacion = @w_operacionca
   
   if @@error != 0  
   begin
      --print 'No se pudo actualizar la información de valores de adicionales de capital'
      select @w_error = 710001
      goto ERROR
   end
end

if @i_nomina = 'S'
begin
   delete ca_nomina  with (rowlock)
   where  no_operacion = @w_operacionca
   
   if @@error != 0
   begin
      select @w_error = 710101
      goto ERROR
   end          
   
   delete ca_definicion_nomina with (rowlock)
   where  dn_operacion = @w_operacionca
   
   if @@error != 0
   begin
      select @w_error = 710101
      goto ERROR
   end
   
   insert into ca_definicion_nomina  with (rowlock)
   select * from ca_definicion_nomina_tmp with (nolock)
   where  dnt_operacion = @w_operacionca
   
   if @@error != 0
   begin
      select @w_error = 710091
      goto ERROR
   end
   
   insert into ca_nomina  with (rowlock)
   select * from ca_nomina_tmp with (nolock)
   where  not_operacion = @w_operacionca
   
   if @@error != 0
   begin
      select @w_error = 710091
      goto ERROR
   end           
end                   

if @i_relacion_ptmo = 'S'
begin
   if @w_tipo = 'R'
   begin
      delete ca_relacion_ptmo  with (rowlock)
      where  rp_pasiva = @w_operacionca
      
      if @@error != 0
      begin
         select @w_error = 710003
         goto ERROR
      end
      
      insert into ca_relacion_ptmo  with (rowlock)
      select * from ca_relacion_ptmo_tmp with (nolock)
      where  rpt_pasiva = @w_operacionca
      
      if @@error != 0
      begin
         --print 'No se pudo actualizar la información de prestamos relacionados'
         select @w_error = 710001
         goto ERROR
      end
   end
   ELSE
   begin
      delete ca_relacion_ptmo  with (rowlock)
      where  rp_activa = @w_operacionca
      
      if @@error != 0
      begin
         select @w_error = 710003
         goto ERROR
      end
      
      insert into ca_relacion_ptmo  with (rowlock)
      select * from ca_relacion_ptmo_tmp with (nolock)
      where  rpt_activa = @w_operacionca
      
      if @@error != 0
      begin
      --print 'No se pudo actualizar la información de valores de prestamos relacionados 82)'
         select @w_error = 710001
         goto ERROR
      end
   end
end   

--LRE 05/ENE/2017
if @i_operacion_ext = 'S'
begin
 
--print 'traslado de temporal a definitiva de tabla de parametros'     
   delete ca_operacion_ext  with (rowlock)
   where  oe_operacion = @w_operacionca
   
   if @@error != 0
   begin
      select @w_error = 724603
      goto ERROR
   end
   
   insert into ca_operacion_ext  with (rowlock)
   select * from ca_operacion_ext_tmp with (nolock)
   where  oet_operacion = @w_operacionca
   
   if @@error != 0  
   begin
      select @w_error = 724599
      goto ERROR
   end
end





return 0

ERROR:
   --print 'Error pasodef.sp ' + convert(varchar, @w_error) 
   return @w_error
go
