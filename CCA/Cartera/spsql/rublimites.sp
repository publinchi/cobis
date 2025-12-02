/***********************************************************************/
/*	Archivo:			           rublimites.sp                             */
/*	Stored procedure:		     sp_rubros_limites_de_rangos               */
/*	Base de Datos:		 	     cob_cartera                               */
/*	Producto:			        Cartera	                                */
/*	Disenado por:			     Elcira Pelaez Burbano                     */
/***********************************************************************/
/*                           IMPORTANTE                                */
/*	Este programa es parte de los paquetes bancarios propiedad de       */ 	 
/*	"MACOSA"	                                                           */
/*	Su uso no autorizado queda expresamente prohibido asi como          */
/*	cualquier autorizacion o agregado hecho por alguno de sus           */
/*	usuario sin el debido consentimiento por escrito de la              */
/*	Presidencia Ejecutiva de MACOSA o su representante                  */
/***********************************************************************/  
/*                            PROPOSITO                                */
/*	Este stored procedure permite calcular los valores para rubros      */
/* calculados con una tasa que es objeto de validacion entre variables */
/* definidas en ca_tablas_dos_rangos                                   */
/* NOTA IMPORTANTE: Este so retona valores para los rubros que cumplan */
/* Las mismas condiciones de los programados hasta el momento          */
/* COMISIONFAG :varibales plazo en meses y gracia capital en meses     */
/*                        tipo de productor del tramite con estas tres */
/*                        variables retorna una tasa y un valor de     */
/*                        rubro calculdo sobre el valor inicial de la  */
/*                        garantia por el % de cobertura de esta       */
/*                        este rubro esta  paarmetrizado en dos rangos */
/* COMISIONFNG :varibales plazo en meses y % de cobertura              */
/*                        tipo de garantia asociada al tramite con estas*/
/*                        variables retorna una tasa y un valor de     */
/*                        rubro calculdo sobre monto desembolsado      */
/*                        este rubro esta  paarmetrizado en dos rangos */
/*TIMBRE:Variables monto aprobado debe superar el rango minimo parame  */
/*                 trizado en tablas de un rango                       */
/***********************************************************************/
/*                           MODIFICACIONES                            */
/*	     FECHA		AUTOR			RAZON                                    */
/*                                                                     */
/***********************************************************************/
use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_rubros_limites_de_rangos')
   drop proc sp_rubros_limites_de_rangos
go

---VERSION 1.0  JUNIO 13 2007

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

create proc sp_rubros_limites_de_rangos (
@i_monto_desembolsado    money       = 0,
@i_concepto              catalogo    = null,
@i_tramite               int         = 0,
@i_dias_div              int         = 0,
@i_plazo_en_meses        int         = 0,
@i_porcentaje_cobertura  char(1)     = 'N',
@i_valor_garantia        char(1)     = 'N',
@i_gracia_cap_meses      int         = 0,
@i_tipo_garantia         varchar(64) = null,
@i_num_dec               tinyint     = 0,
@i_op_monto_aprobado     money       = 0,
@i_cotizacion            float       = 1,
@i_tasa                  float       = 0,
@i_parametro_timbre      catalogo    = null,
@i_fecha_ini             datetime    = null,
@o_valor_rubro           money       = 0 out,
@o_tasa_calculo          float       = 0 out,
@o_nro_garantia          varchar(64) = null out,
@o_base_calculo          money       = null out

)
as
declare
   @w_sp_name		             varchar(32),	
   @w_return		             int,
   @w_valor_inicial_garantia   money,
   @w_parametro_fng            catalogo,
   @w_parametro_fag            catalogo,
   @w_numero_deudores          int,
   @w_fecha_proceso            datetime,
   @w_cu_tipo                  catalogo,
   @w_tipodato1                catalogo,
   @w_tipodato2                catalogo,
   @w_porcen_cobertura         float,
   @w_tasa_comision            float,
   @w_nro_garantia             varchar(64),
   @w_base_calculo             money,
   @w_tipo_productor           catalogo,
   @w_rango                    tinyint,
   @w_monto_timbre             money,
   @w_rango_min                money,
   @w_rango_max                money,
   @w_tipo_superior            char(10),
   @w_fecha_tasa               datetime

   
select	
@w_sp_name            = 'sp_rubros_limites_de_rangos'


Select @w_fecha_proceso = fc_fecha_cierre
from  cobis..ba_fecha_cierre
where fc_producto = 7


--CODIGO DEL RUBRO SEGVIDA
select @w_parametro_fng = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'COMFNG'
set transaction isolation level read uncommitted

---CODIGO DEL RUBRO COMISION FAG 
select @w_parametro_fag = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'COMFAG'
set transaction isolation level read uncommitted

---PRINT 'rublimite @i_concepto' + @i_concepto

---PARAMETRO TIPO SUPERIOR DE LA GARANTIA

if @i_tipo_garantia is not null
begin
   select @w_tipo_superior = tc_tipo_superior
   from cob_custodia..cu_tipo_custodia
   where tc_tipo = @i_tipo_garantia
   
   if @@rowcount = 0
      return 721609
end

--DATOS PARA IDENTIFICAR EL RANGO y EL TIPO DE DATO

--NR-293
select @w_rango     = ct_nro_rangos,
       @w_tipodato1 = substring(ct_tipodato1,1,2),
       @w_tipodato2 = isnull(substring(ct_tipodato2, 1,2),'NA')
from ca_campos_tablas_rubros
where ct_concepto  = @i_concepto      

if @w_rango is null
 return 721607

---PRINT 'rublimite.sp tipogar'+ @i_tipo_garantia + 'tsuperior' + @w_tipo_superior + '@i_tramite' + @i_tramite

if @i_porcentaje_cobertura  = 'S' or  @i_valor_garantia = 'S'
begin

      select @w_porcen_cobertura       = isnull(cu_porcentaje_cobertura,0.0),
             @w_nro_garantia           = gp_garantia,
             @w_valor_inicial_garantia = isnull(cu_valor_inicial,0),
             @w_cu_tipo                = cu_tipo
      from cob_credito..cr_gar_propuesta,
      cob_custodia..cu_custodia,
      cob_custodia..cu_tipo_custodia
      where  gp_tramite = @i_tramite
      and cu_codigo_externo = gp_garantia
      and (cu_tipo  =  @i_tipo_garantia  or tc_tipo_superior = @w_tipo_superior)
      and    cu_estado   in ('V', 'X', 'F')
      and cu_tipo = tc_tipo
      
      if @@rowcount = 0
         return 721602
      
      if @@rowcount > 1
         return 721610          

end

---PROGRAMACION DE TODOS LOS TIPOS DE DATOS ENCONTRADOS PARA EL CONCEPTO
if @w_rango = 2 --dos Rangos
begin
   
   --sacar la maxima fecha de registro de las tasas
   
   --Plazo en meses y % Cobertura de garantia valor base monto desembolsado variabe tipo de garantia
   --------------------------------------------------------------------------------------------------
   if @w_tipodato1 = 'PL'  and  @w_tipodato2 = 'CG'
   begin

      select @w_fecha_tasa = max(tdr_fecha_carga)
      from ca_tablas_dos_rangos
      where tdr_concepto = @i_concepto
      and   tdr_variable = @w_cu_tipo
      and   tdr_fecha_carga <= @i_fecha_ini
      
      if @@rowcount = 0
         return 721608      
      
      select @w_tasa_comision = isnull(tdr_tasa,0)
      from ca_tablas_dos_rangos
      where tdr_concepto = @i_concepto
      and   tdr_variable = @w_cu_tipo
      and @i_plazo_en_meses  between tdr_valor1_min    and  tdr_valor1_max ---Plazo
      and @w_porcen_cobertura  between tdr_valor2_min    and  tdr_valor2_max  ---Gracia
      and tdr_fecha_carga = @w_fecha_tasa

      if @@rowcount = 0 
       begin
         PRINT 'rublimites.sp  revisar parametrizacion para estos rangos   i_plazo_en_meses , @w_porcen_cobertura' + @i_plazo_en_meses + @w_porcen_cobertura
         return 721601
       end
      
      ----VARIABLES DE SALIDA      
      select @o_valor_rubro = @i_monto_desembolsado * @w_tasa_comision/100
      select @o_nro_garantia       = @w_nro_garantia
      select @o_tasa_calculo       = isnull(@w_tasa_comision,0)
      select @o_base_calculo       = isnull(@i_monto_desembolsado,0)
      
   end
   
   
   --Plazo en meses  Vs. Gracia Capital en Meses  valor base Valor Inicial de garantia variable tipo productor
   --------------------------------------------------------------------------------------------------------
   if @w_tipodato1 = 'PL'  and  @w_tipodato2 = 'GC' 
   begin


      select @w_tipo_productor = isnull(tr_tipo_productor,'01')
      from cob_credito..cr_tramite
      where tr_tramite = @i_tramite

      select @w_tasa_comision = isnull(tdr_tasa,0)
      from ca_tablas_dos_rangos
      where tdr_concepto = @i_concepto
      and   tdr_variable = @w_tipo_productor
      and @i_plazo_en_meses  between tdr_valor1_min    and  tdr_valor1_max ---Plazo
      and @i_gracia_cap_meses  between tdr_valor2_min    and  tdr_valor2_max  ---Gracia capital meses
      and tdr_fecha_carga = @w_fecha_tasa

      if @@rowcount = 0 
       begin
         PRINT 'rublimites.sp  revisar parametrizacion para estos rangos   i_plazo_en_meses , @i_gracia_cap_meses ' + @i_plazo_en_meses + @i_gracia_cap_meses
         return 721603
       end
      
      select @w_base_calculo  = isnull((@w_valor_inicial_garantia * @w_porcen_cobertura)/100,0)
      
      ----VARIABLES DE SALIDA      
      select @o_valor_rubro        = @w_base_calculo * @w_tasa_comision/100
      select @o_nro_garantia       = @w_nro_garantia
      select @o_tasa_calculo       = isnull(@w_tasa_comision,0)
      select @o_base_calculo       = isnull(@w_base_calculo,0)
      
   end


   --Datos para el recalculo de fag
   --------------------------------
   if @i_concepto = @w_parametro_fag
     begin
        
        delete ca_base_garantia 
        where bg_tramite = @i_tramite
         
        if @w_porcen_cobertura = 0.0
            select @w_porcen_cobertura = 100
   
   
        insert into  ca_base_garantia
          (bg_tramite,           bg_garantia,
           bg_valor_inicial_gar, bg_porcentaje_cobertura,
           bg_base_calculo,      bg_fecha_ult_mod)
        values
          (@i_tramite,                @w_nro_garantia,
           @w_valor_inicial_garantia, @w_porcen_cobertura,
           @w_base_calculo,                  @w_fecha_proceso)
    end  ---Parametro FAG
   
    ---VALIDACION DE LO NO PROGRAMADO
    if @w_tipodato1 <> 'PL'  and  @w_tipodato2  not in ( 'CG','GC') 
    begin
      print '(rublimites.sp)  Parametrizar en Definicion de Tablas de dos Rangos y programar  el Rubro..' + @i_concepto
      return 721606
    end
end
ELSE   --Un rango
begin
 
   --Rango monto aprobado en la operacion
   if  @w_tipodato1 = 'MA'
   begin
      
      if @i_concepto =  @i_parametro_timbre
      begin
         select @w_monto_timbre = round((@i_op_monto_aprobado * @i_cotizacion),@i_num_dec)

            select
            @w_rango_min = tur_valor_min,
            @w_rango_max = tur_valor_max
            from ca_tablas_un_rango
            where tur_concepto = @i_concepto  

            if @@rowcount = 0 
               return 721604
   
   ---PRINT 'rublimite.sp llego @i_op_monto_aprobado ,  @w_rango_min' + @i_op_monto_aprobado + @w_rango_min
            
            if @w_monto_timbre >= @w_rango_min 
            begin

               select @o_valor_rubro        = @w_monto_timbre * @i_tasa/100
               select @o_nro_garantia       = @w_nro_garantia
               select @o_tasa_calculo       = isnull(@i_tasa,0)
               select @o_base_calculo       = isnull(@w_monto_timbre,0)               
               
            end
            ELSE
            begin
               select @o_valor_rubro        = 0
               select @o_nro_garantia       = @w_nro_garantia
               select @o_tasa_calculo       = isnull(@i_tasa,0)
               select @o_base_calculo       = isnull(@w_monto_timbre,0)                
            end      
         
      end
      ELSE
      begin
         --Rubros  parametrizdos con limite sobre monto desembolsado
         print '(rublimites.sp)  Parametrizar en Definicion de Tablas de un rango y programar el Rubro..' + @i_concepto
         return 721605
      end
      
   end --Monto aprobado

end



return 0 

go
