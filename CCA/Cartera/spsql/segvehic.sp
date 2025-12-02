/************************************************************************/
/*      Archivo:                segvehic.sp                             */
/*      Stored procedure:       sp_seguros_vehiculares                  */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Elcira PElaez                           */
/*      Fecha de escritura:     Dic. 2003                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.							                                    */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Recalculo de seguros de vehiculo por distribucion de garantia   */
/*      vehicular                                                       */
/************************************************************************/
/*                              CAMBIOS                                 */
/*      FECHA              AUTOR             CAMBIOS                    */
/*      MAR-2006           Elcira P.         def 6218                   */
/************************************************************************/

use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_seguros_vehiculares')
   drop proc sp_seguros_vehiculares
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

create proc sp_seguros_vehiculares
@i_tramite	    int,
@i_tipo_garantia    char(64),
@i_operacionca      int,
@i_concepto         catalogo,
@i_op_tdividendo    catalogo,
@i_op_periodo_int   smallint,
@i_moneda           tinyint = 0,
@i_op_base_calculo  char(1),
@i_dias_anio        smallint,
@i_categoria_rubro  char(1) = 'S',
@i_fpago            char(1) = 'A',
@o_valor_rubro      money     = 0 out,
@o_tasa_calculo     float     = 0 out,
@o_nro_garantia     char(64)  = null out,
@o_base_calculo     money     = null out
as

declare
@w_sp_name		   varchar(30),
@w_error                   int,
@w_return                  int,
@w_cu_codigo_externo       char(64),
@w_valor_resp_garantia  money,
@w_cu_clase_vehiculo       catalogo,
@w_garantia                char(64),
@w_contador                smallint,
@w_codigo_seg              catalogo,
@w_dias_div                int,
@w_num_dec_op              smallint,
@w_porcentaje              float,
@w_modalidad_d             char(1),
@w_valor_seguro            money,
@w_tasa_calculo            float,
@w_valor_rubro             money,
@w_valor                   money,
@w_base                    money,
@w_tasa                    float,
@w_contador_gar            int,
@w_tipo_superior           char(64),
@w_parametro_superior      catalogo,
@w_tipo                    char(64)  --def 6218

--- INICIALIZACION VARIABLES 

select @w_sp_name          = 'sp_seguros_vehiculares'
select @w_contador_gar     = 0

---CODIGO DEL RUBRO ASEGURADORA 
select @w_codigo_seg = pa_char
from cobis..cl_parametro
where pa_nemonico = 'ASEG'
and   pa_producto = 'CCA'
set transaction isolation level read uncommitted


--- NUMERO DE DIAS POR DIVIDENDO 
select @w_dias_div = td_factor * @i_op_periodo_int
from   ca_tdividendo
where  td_tdividendo = @i_op_tdividendo


---def 6218
select @w_parametro_superior = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'SUVEH'
set transaction isolation level read uncommitted


---def 6218
---PARAMETRO TIPO SUPERIOR DE LA GARANTIA
select @w_tipo_superior = tc_tipo_superior
from cob_custodia..cu_tipo_custodia
where tc_tipo = @i_tipo_garantia


If @w_tipo_superior <>  @w_parametro_superior
return 0


--- LECTURA DE DECIMALES
exec  sp_decimales
@i_moneda       = @i_moneda,
@o_decimales    = @w_num_dec_op out


select @w_contador = 0
select @w_valor    = 0
select @w_base     = 0
select @w_tasa     = 0
select @w_valor_resp_garantia = 0

declare cursor_seguros_vehiculares cursor for 
   select
   cu_codigo_externo,
   cu_clase_vehiculo,
   cu_tipo
   from cob_credito..cr_gar_propuesta,
   cob_custodia..cu_custodia,
   cob_custodia..cu_tipo_custodia
   where  gp_tramite = @i_tramite
   and cu_codigo_externo = gp_garantia
   and (cu_tipo      =  @i_tipo_garantia  or tc_tipo_superior = @w_parametro_superior)
   and cu_clase_custodia <> 'O' --- Otras garantias  I Idoneas
   and cu_tipo = tc_tipo
   for read only

   open cursor_seguros_vehiculares

   fetch cursor_seguros_vehiculares into
   @w_cu_codigo_externo,
   @w_cu_clase_vehiculo,
   @w_tipo

   if (@@fetch_status != 0) 
      begin
         select @w_error = 710490
         close cursor_seguros_vehiculares
         goto ERROR 
      end

   --while   @@fetch_status not in (-1,0)  
   while   @@fetch_status = 0
   begin 

      if @w_cu_clase_vehiculo is null
        begin
          close cursor_seguros_vehiculares
          deallocate cursor_seguros_vehiculares
          select @w_error = 710489
          goto ERROR
        end
        
             ---PRINT 'segvehic.sp va para  sp_prorrateo_seguros  %1! @w_cu_codigo_externo%2! @i_tipo_garantia %3!',@i_tramite,@w_cu_codigo_externo,@i_tipo_garantia
             
             exec sp_prorrateo_seguros 
             @i_tramite            = @i_tramite,
             @i_operacion          = @i_operacionca,
             @i_tipo_garantia      = @w_tipo,
             @i_garantia_vehicular = @w_cu_codigo_externo,
             @o_base_calculo_seg  = @w_valor_resp_garantia  output
            
            ---PRINT 'segvehic.sp sale de sp_prorrate  @w_valor_resp_garantia %1!',@w_valor_resp_garantia
            
            ---SACAR LA TASA Y EL CALCULO POR TIPO DE VEHICULO
            if @w_valor_resp_garantia > 0
            begin
               
                select @w_porcentaje = isnull(ot_valor,0)
                from   cob_cartera..ca_otras_tasas
                where  ot_codigo          = @w_cu_clase_vehiculo
                and    ot_categoria_rubro = @i_categoria_rubro
                if @@rowcount =  0 
                   begin  
                     close cursor_seguros_vehiculares
                     deallocate cursor_seguros_vehiculares
                     select @w_error = 710386
                     goto ERROR
                  end

                select @w_valor_resp_garantia  = round(@w_valor_resp_garantia,@w_num_dec_op)                  
                
                select @w_valor_seguro = @w_valor_resp_garantia  * @w_dias_div * (@w_porcentaje/100) / 360
                select @w_valor_seguro = round (@w_valor_seguro,@w_num_dec_op)
   
                --PRINT 'segvehi.sp Garantia %1! _valor_seguro %2! tasa %3! base %4!',@w_cu_codigo_externo,@w_valor_seguro,@w_porcentaje,@w_valor_resp_garantia
            end --Tiene valor base    > 0                
            
                select @w_contador_gar = @w_contador_gar + 1
                select  @w_valor    = @w_valor +  isnull(@w_valor_seguro,0),
                        @w_garantia = '(' + convert(char(2),@w_contador_gar) + ')' + '-' + ltrim(rtrim(@w_cu_codigo_externo)),
                        @w_base     = @w_base + isnull(@w_valor_resp_garantia,0),
                        @w_tasa     = @w_porcentaje
                     

  
             --PRINT 'segvehic.sp 1  @w_garantia %1!  @w_base %2!  @w_valor %3!',@w_garantia,@w_base,@w_valor                     

    ---SIGUIENTE GARANTIA
    fetch cursor_seguros_vehiculares into
    @w_cu_codigo_externo,
    @w_cu_clase_vehiculo,
    @w_tipo

   end ---While

   close cursor_seguros_vehiculares
   deallocate cursor_seguros_vehiculares

   --RETORNO DE VALORES
   --PRINT 'segvehic.sp 2 @w_garantia %1!  @w_base %2!  @w_valor %3!',@w_garantia,@w_base,@w_valor
             
select @o_valor_rubro        = @w_valor
select @o_nro_garantia       = @w_garantia
select @o_tasa_calculo       = @w_tasa
select @o_base_calculo       = @w_base


return 0

ERROR:
      return @w_error

go
   