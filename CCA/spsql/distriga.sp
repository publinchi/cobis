/************************************************************************/
/*      Archivo:                distriga.sp                             */
/*      Stored procedure:       sp_distr_seguros_gar_cca                */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Elcira Pelaez                           */
/*      Fecha de escritura:     Ene. 2003                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA".							*/
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Recalculo de seguros por distribucion de garantia se lee de     */
/*      de la tabla ca_seguros_base_garantia cargada por Garantias      */
/************************************************************************/
/*                                CAMBIOS                               */
/* AGO-27-2007             JJRO        Optimizacion OPT_224             */
/************************************************************************/  
use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_distr_seguros_gar_cca')
   drop proc sp_distr_seguros_gar_cca
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

create proc sp_distr_seguros_gar_cca (
@s_user                  login,
@i_fecha_proceso         datetime,
@i_tramite               int,
@i_op_operacion          int,
@i_moneda                smallint,
@i_op_banco              cuenta
)

as
declare
@w_error                   int,
@w_tipo_garantia_antes     varchar(64),
@w_nro_garantia_antes      varchar(64),
@w_parametro_item          char(64),
@w_tipogar_hipo            catalogo,
@w_det_val_construccion    char(20),
@w_valor_construccion      money,
@w_sg_tipo_garantia        catalogo,
@w_dg_valor_resp_garantia  money,
@w_cu_valor_inicial        money,
@w_nro_garantia            char(64),
@w_item                    tinyint,
@w_concepto                catalogo,         	
@w_porcentaje              float,	
@w_concepto_asociado       catalogo,       
@w_iva_siempre             char(1),
@w_categoria               char(10),
@w_valor_seguro            money,
@w_valor_base              money,
@w_proceso_vehicular       char(1),
@w_div_vigente             int,
@w_dias_div                int,
@w_num_dec                 smallint,
@w_cu_clase_vehiculo       catalogo,
@w_ro_fpago                char(1),
@w_otra_tasa_rubro         float,
@w_modalidad_d             char(1),
@w_return                  int,
@w_tasa_nom                float,
@w_base_calculo            char(1),
@w_dias_anio               smallint,
@w_num_dec_tapl            smallint,
@w_tabla_tasa              char(30),
@w_fpago                   char(1),
@w_anexo                   varchar(255),
@w_descripcion             varchar(255),
@w_tipo_superior           char(64),
@w_ro_tipo_rubro           char(1)
 
--- INICIALIZACION VARIABLES 

if exists(select 1
          from   ca_operacion
          where  op_operacion = @i_op_operacion
          and    op_estado    = 4)
   return 0

declare cursor_general cursor for
select
sg_tipo_garantia
from ca_seguros_base_garantia
where sg_tramite = @i_tramite
and   sg_fecha_reg = @i_fecha_proceso
group by sg_tramite,sg_tipo_garantia
for read only

open cursor_general

fetch cursor_general into 
@w_sg_tipo_garantia  

while  @@fetch_status = 0 ---While CURSOR No. 1
begin    ---Si hay datos en el cursor
   if @@fetch_status = -1 
    begin
       close cursor_general
       deallocate cursor_general
       return 0
    end

  ---PRINT 'distriga.sp entro cursor No.1 con tipo  %1!  tramite %2!',@w_sg_tipo_garantia,@i_tramite
  
   ---PARAMETRO TIPO SUPERIOR DE LA GARANTIA
   select @w_tipo_superior = tc_tipo_superior
   from cob_custodia..cu_tipo_custodia
   where tc_tipo = @w_sg_tipo_garantia


   select @w_div_vigente = di_dividendo
   from ca_dividendo
   where di_operacion =  @i_op_operacion
   and   di_estado    = 1
   
   if @@rowcount = 0
       begin
       close cursor_general
       deallocate cursor_general
       return 0
    end

   
  ---MANEJO DE DECIMALES
   exec @w_return = sp_decimales
        @i_moneda       = @i_moneda,
        @o_decimales    = @w_num_dec out

  
   if (select count(1) from ca_rubro_op,ca_concepto,cob_custodia..cu_tipo_custodia
      where ro_operacion = @i_op_operacion
      and   ro_concepto  = co_concepto
      and   ro_tipo_garantia = tc_tipo 
      and   tc_tipo_superior =  @w_tipo_superior
      and   co_categoria     = 'S' ) > 0
   begin ---EXISTE UN TIPO DE GARANTIA  PARA UN SEGURO
         ---------------------------------------------
      
      ---CURSOR POR LOS RUBROS DEL TRAMITE  TIPO S= SEGUROS y TIPO A= IVAS
      declare
         rubros cursor 
         for select  ro_concepto,	   	      ro_porcentaje,
                     ro_concepto_asociado,     ro_iva_siempre,
                     co_categoria,             ro_tabla,
                     ro_fpago,                 ro_tipo_rubro
             from  ca_rubro_op,ca_concepto,cob_custodia..cu_tipo_custodia
             where ro_operacion      = @i_op_operacion
             and   ro_concepto       = co_concepto
             and   ro_tipo_garantia = tc_tipo 
             and   tc_tipo_superior =  @w_tipo_superior 
             and   co_categoria  = 'S' ---SEGUROS
             and   ro_valor_garantia = 'S'
             union  --PARA SACAR EL IVA
             select  ro_concepto,	   	       ro_porcentaje,
                     ro_concepto_asociado,     ro_iva_siempre,
                     co_categoria,             ro_tabla,
                     ro_fpago,                 ro_tipo_rubro
             from  ca_rubro_op, ca_concepto
             where ro_operacion      = @i_op_operacion
             and   co_concepto = ro_concepto
             and   ro_concepto_asociado in (
                   select  ro_concepto
                   from ca_rubro_op,ca_concepto,cob_custodia..cu_tipo_custodia
                   where ro_operacion      = @i_op_operacion
                   and   ro_concepto       = co_concepto
                   and   ro_tipo_garantia = tc_tipo 
                   and   tc_tipo_superior =  @w_tipo_superior
                   and   co_categoria  = 'S' --SEGUROS
                   and   ro_valor_garantia = 'S')
         
         order by ro_tipo_rubro desc     --para que calcule primero los rubros tipo seguro, y luego el iva de los seguros
      for read only

      open rubros

      fetch rubros into 
            @w_concepto,         	    @w_porcentaje,	
            @w_concepto_asociado,       @w_iva_siempre, 
            @w_categoria,               @w_tabla_tasa,
            @w_fpago,                   @w_ro_tipo_rubro

       while  @@fetch_status = 0  ---While CURSOR No. 2
       begin    ---Si hay datos en el cursor


          if @@fetch_status = -1 
          begin
              ---Cerrar los cursores
              close rubros
              deallocate rubros
               
              close cursor_general
              deallocate cursor_general
              PRINT 'distriga.sp No hay datos apra procesar'
              return 0
           end

 

         if @w_num_dec is null
            select @w_num_dec = 0
            

         ---SEGUROS
         select @w_valor_seguro = 0
         if @w_categoria = 'S' 
         begin
               exec @w_return           = sp_rubro_calculado
               @i_tipo                  = 'Q',
               @i_monto                 = 0,
               @i_concepto              = @w_concepto,
               @i_operacion             = @i_op_operacion,
               @i_porcentaje            = @w_porcentaje,
               @i_usar_tmp              = 'N',
               @i_valor_garantia        = 'S',
               @i_tipo_garantia         = @w_sg_tipo_garantia,
               @i_tabla_tasa            = @w_tabla_tasa,
               @i_categoria_rubro       = 'S',
               @i_fpago                 = @w_fpago,
	            @o_tasa_calculo          = @w_porcentaje out,
               @o_nro_garantia          = @w_nro_garantia out,
               @o_base_calculo          = @w_valor_base out,
               @o_valor_rubro           = @w_valor_seguro out
            
               if @w_return != 0 begin
                  close rubros
                  deallocate rubros
                  select @w_error =  @w_return
                  goto ERROR_RG
               end

              ---PRINT 'distriga.sp salio  de sp_rubro_calculado   @w_valor_seguro %1!  @w_valor_base %2! @w_nro_garantia %3!',@w_valor_seguro,@w_valor_base,@w_nro_garantia

               select @w_valor_seguro = round(@w_valor_seguro,@w_num_dec)
               if   @w_valor_seguro <= 0
                 begin
                     ---SI EL SEGURO DA CERO SE ENVIA UN MENSAJE INFORATIVO A LA ERRORLOG PARA QUE SE REVICE
                     ---SI ESTE ES CORRECTO
                     if @w_categoria = 'S'
                     begin
                        select @w_error =  710493
                        select @w_anexo = 'TRAMITE = ' + convert(char(10),@i_tramite) + 'TIPO GARANTIA = ' + @w_sg_tipo_garantia + 'RUBRO = ' +  @w_concepto 
                        select @w_descripcion = 'REVISAR EL VALOR DEL SEGURO SE REGENERO EN CERO 0 POR DISTRIBUCION DE GARANTIAS'
                        insert into ca_errorlog
                                  (er_fecha_proc,   er_error,      er_usuario,
                                  er_tran,          er_cuenta,     er_descripcion,
                                  er_anexo)
                        values(@i_fecha_proceso, @w_error,      @s_user,
                                  7525,             @i_op_banco,   @w_descripcion,
                                  @w_anexo)
                        end
                     goto SIGUIENTE_RUBRO
                 end
                    
   
               if   @w_valor_seguro > 0 and @w_categoria = 'S'
               begin
                 update cob_cartera..ca_rubro_op
                 set ro_base_calculo   = @w_valor_base,
                     ro_valor          = @w_valor_seguro,
                     ro_nro_garantia   = @w_nro_garantia,
                     ro_porcentaje     = @w_porcentaje,
                     ro_porcentaje_aux = @w_porcentaje,
                     ro_tipo_garantia  = @w_sg_tipo_garantia
                 where ro_operacion   = @i_op_operacion
                 and   ro_concepto    = @w_concepto
        
                  --- ACTUALIZAR TABLA DE AMORTIZACION 
         
                  update ca_amortizacion
                  set  am_cuota     = @w_valor_seguro,
                       am_acumulado = @w_valor_seguro
                  from   ca_amortizacion
                  where  am_operacion = @i_op_operacion
                  and    am_dividendo > @w_div_vigente
                  and    am_concepto  = @w_concepto
                  and    am_pagado    =  0
                  
               end    ---Valor del seguro > 0
           end  --- Categoria S
                              ---IVAS SOBRE LOS SEGUROS
            if @w_categoria = 'A'  and @w_concepto_asociado is not null  and @w_iva_siempre = 'S'
               begin

                  select @w_valor_base = ro_valor
                  from ca_rubro_op
                  where ro_operacion  = @i_op_operacion
                  and ro_concepto     = @w_concepto_asociado
             
    
                  select @w_valor_seguro = @w_valor_base * (@w_porcentaje/100.0) 
                  select @w_valor_seguro = round ( @w_valor_seguro,@w_num_dec)
   
                  update cob_cartera..ca_rubro_op
                  set ro_base_calculo  = @w_valor_base,
                      ro_valor         = @w_valor_seguro
                  where ro_operacion   = @i_op_operacion
                  and   ro_concepto    = @w_concepto

                 update ca_amortizacion
                  set  am_cuota     = @w_valor_seguro,
                       am_acumulado = @w_valor_seguro
                  where  am_operacion = @i_op_operacion
                  and    am_dividendo > @w_div_vigente
                  and    am_concepto  = @w_concepto
                  and    am_pagado    =  0
               end
 
               --ANTES DE SALIR DEL CONCEPTO ACTUALIZAR EL TIPO DE GARANTIA Y LA 
               --GARANTIA POR SI HAY CAMBIO
               
         SIGUIENTE_RUBRO:
         ---SIGUIENTE CONCEPTO
         fetch rubros into 
            @w_concepto,         	    @w_porcentaje,		      	
            @w_concepto_asociado,       @w_iva_siempre,
            @w_categoria,               @w_tabla_tasa,
            @w_fpago,                   @w_ro_tipo_rubro

      end -- While CURSOR No. 2
      close rubros
      deallocate rubros

   end ---EXISTE UN TIPO DE GARANTIA  PARA UN SEGURO
       --------------------------------------------
   else
     PRINT 'distriga.sp ........Continuar'

   ---Al finalizar el proceso se actualiza la tabla para el tramite y el tipo de garantia respectivo
 
    
   goto SIGUIENTE_RG

   ERROR_RG:
   
   select @w_anexo = 'TRAMITE = ' + convert(char(10),@i_tramite) + 'TIPO GARANTIA = ' + @w_sg_tipo_garantia + 'RUBRO = ' +  @w_concepto 
   select @w_descripcion = 'REGENERANDO LOS SEGUROS POR DISTRIBUCION DE GARANTIAS'
   insert into ca_errorlog
          (er_fecha_proc,   er_error,      er_usuario,
          er_tran,          er_cuenta,     er_descripcion,
          er_anexo)
   values(@i_fecha_proceso, @w_error,      @s_user,
          7525,             @i_op_banco,   @w_descripcion,
          @w_anexo)

  --SIGUIENTE TIPO GARANTIA
  SIGUIENTE_RG:
  fetch   cursor_general into
    @w_sg_tipo_garantia

end --While CURSOR No. 1
close cursor_general
deallocate cursor_general

return 0

go

