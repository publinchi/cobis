/************************************************************************/
/*	Archivo: 		rubcomg.sp		 		*/
/*	Stored procedure: 	sp_rubro_comision 			*/
/*	Base de datos:  	cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		X. Maldonado 		                */
/*	Fecha de escritura: 	Feb 2003				*/
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
/*	Da mantenimiento a la tabla ca_rubro_op_tmp                     */
/*                              CAMBIOS                                 */
/*       FECHA                  AUTOR          CAMBIO			*/
/************************************************************************/  
use cob_cartera
go



create  table #ca_garantias_op(
	cu_codigo_externo		varchar(64),
	cu_porcentaje_cobertura		float,
	cu_valor_actual			float,
	cu_clase_vehiculo		varchar(10),
	cu_tipo				varchar(64)
	)
go


if exists (select 1 from sysobjects where name = 'sp_rubro_comision')
	drop proc sp_rubro_comision
go
create proc sp_rubro_comision (
      @i_banco                        cuenta      = null

)
as

declare	@w_sp_name                      descripcion,
       	@w_return 	                int,
	@w_parametro_fag		varchar(30),
	@w_codigo_seg			char(10),
	@w_dias_div			smallint,
	@w_tramite			int,
	@w_error			int,
	@w_operacionca			int,
	@w_categoria_rubro		char(1),
	@w_tipo_garantia_new		char(1),
	@w_otra_tasa_rubro		float,
	@w_fpago			char(1),
	@w_modalidad_d			char(1),
	@w_base_calculo			char(1),
	@w_tasa_nom			float,
	@w_porcentaje			float,
	@w_porcentaje_new		float,
	@w_valor_garantia		char(1),
	@w_tipo_productor		varchar(24),
	@w_dias_plazo			smallint,
	@w_plazo			smallint,
	@w_gracia_en_meses		int,
	@w_gracia_cap			int,
	@w_tasa_comision		float,
	@w_valor_actual			money,
	@w_concepto			catalogo,
	@w_codigo_externo		cuenta,
        @w_tplazo			catalogo,
	@w_tdividendo			catalogo,
        @w_cliente                      int,
        @w_porcentaje_cobertura		char(1),
	@w_porcen_cobertura		float,
        @w_clase_vehiculo		varchar(10),
        @w_plazo_en_meses		int,
        @w_tipo_garantia		descripcion,
        @w_tipo				descripcion,
	@w_valor_rubro			money,
	@w_num_periodo_d		smallint,
	@w_periodo_d			char(1),
	@w_dias_anio			int,
	@w_num_dec_tapl			smallint,
	@w_contador			smallint,
        @w_concepto_asociado            catalogo,
        @w_num_dec                      smallint,
        @w_iva_siempre                  char(1),
        @w_tipo_rubro                   char(1),
        @w_rowcount                     int


   /*CODIGO DEL RUBRO COMISION FAG */
   select @w_parametro_fag = pa_char
   from cobis..cl_parametro
   where pa_producto = 'CCA'
   and   pa_nemonico = 'COMFAG'
   select @w_rowcount = @@rowcount
   set transaction isolation level read uncommitted

   if @w_rowcount = 0
   begin
      select @w_error = 710370
   end 


   /*CODIGO DEL RUBRO ASEGURADORA */
   select @w_codigo_seg = pa_char
   from cobis..cl_parametro
   where pa_nemonico = 'ASEG'
   and   pa_producto = 'CCA'
   set transaction isolation level read uncommitted


   select 
   @w_operacionca    = op_operacion,
   @w_tramite        = op_tramite,
   @w_tplazo         = op_tplazo,
   @w_plazo          = op_plazo,
   @w_tdividendo     = op_tdividendo,
   @w_gracia_cap     = op_gracia_cap,
   @w_cliente        = op_cliente,
   @w_num_periodo_d  = op_periodo_int,
   @w_periodo_d      = op_tdividendo,
   @w_dias_anio      = op_dias_anio,
   @w_base_calculo   = op_base_calculo
   from ca_operacion
   where op_banco = @i_banco


   /*CUANTOS DIAS TIENE UNA CUOTA DE INTERES*/
   select @w_dias_div = td_factor * 1
   from   ca_tdividendo
   where  td_tdividendo = @w_tdividendo


   /* CREACION TABLA DE GARANTIAS DE UNA OPERACION*/

   insert into #ca_garantias_op
   select cu_codigo_externo,        
          cu_porcentaje_cobertura,       
          cu_valor_actual, 	
          cu_clase_vehiculo, 	    
          cu_tipo  
   from cob_custodia..cu_custodia, cob_credito..cr_gar_propuesta, cob_custodia..cu_poliza 
   where gp_tramite       = @w_tramite 
   and gp_garantia        = cu_codigo_externo
   and gp_garantia        = po_codigo_externo
   and po_aseguradora     = cu_aseguradora
   and po_aseguradora     = @w_codigo_seg
   and gp_est_garantia    in ('V','X','F')
   and po_estado_poliza   = 'VIG'


   declare garantias cursor for
   select cu_codigo_externo, cu_porcentaje_cobertura, sum(cu_valor_actual),  cu_clase_vehiculo,cu_tipo                                                       
   from #ca_garantias_op
   group by cu_codigo_externo,cu_porcentaje_cobertura, cu_clase_vehiculo,cu_tipo
   for read only

   open garantias 

   fetch garantias into 
   @w_codigo_externo,
   @w_porcen_cobertura,
   @w_valor_actual,
   @w_clase_vehiculo,               
   @w_tipo


   if (@@fetch_status != 0)
      begin
         close garantias
         deallocate garantias
         goto SALIR      
      end

   while (@@fetch_status = 0 ) 
   begin 


      if exists ( select 1 from cob_custodia..cu_clase_vehiculo 
                  where cv_tipo = @w_tipo)
         select @w_tipo_garantia_new = 'V'   ---vehicular
      else
         select @w_tipo_garantia_new = 'O'   ---otras


      /** INSERCION DE LOS RUBROS DE LA OPERACION PARA RUBROS QUE NO TIENEN (RUBRO_ASOCIADO)**/
      declare rubros cursor for
      select  ro_concepto,	   	ro_porcentaje,   	ro_tipo_garantia,	
	      ro_porcentaje_cobertura,	ro_valor_garantia,	ro_fpago,          
              ro_concepto_asociado,     ro_iva_siempre,         ro_tipo_rubro,
              ro_num_dec
      from ca_rubro_op
      where ro_operacion       = @w_operacionca
      order by ro_tipo_rubro desc        --para que calcule primero los rubros tipo seguro, y luego el iva de los seguros
      for read only 

      open rubros

      fetch rubros into 
            @w_concepto,         	@w_porcentaje,		@w_tipo_garantia,      	
 	    @w_porcentaje_cobertura,    @w_valor_garantia,     	@w_fpago,
            @w_concepto_asociado,       @w_iva_siempre,		@w_tipo_rubro,
            @w_num_dec
   
      if (@@fetch_status != 0)
      begin
         select @w_error = 710004
         close rubros
         goto ERROR 
      end


      while (@@fetch_status = 0 ) 
      begin 


         /* SI LA GARANTIA ES TIPO VEHICULO */
         select @w_categoria_rubro = co_concepto
         from ca_concepto
         where co_concepto = @w_concepto


         /*SI EL RUBRO ES DE CATEGORIA SEGURO Y SE CALCULA EN BASE A UNA GARANTIA, POR VALOR O POR COBERTURA*/
         if @w_categoria_rubro = 'S' and (@w_valor_garantia = 'S' or @w_porcentaje_cobertura = 'S')  and @w_concepto_asociado = null
         begin

            if @w_valor_garantia = 'S' and @w_porcentaje_cobertura = 'N'
            begin

               /* SI EL RUBRO TIENE PARAMETRIZADA UNA  GARANTIA DE TIPO VEHICULAR...SE CALCULA EL VALOR DEL RUBRO*/

               if @w_tipo_garantia_new = 'V'   --Garantia nueva de tipo vehicular
               begin
                  select @w_otra_tasa_rubro = isnull(ot_valor,0)
                  from cob_cartera..ca_otras_tasas
                  where ot_codigo        = @w_clase_vehiculo
                  and ot_categoria_rubro = @w_categoria_rubro

                  if @w_otra_tasa_rubro > 0 
                  begin

                     if @w_fpago = 'P'
  	                select @w_modalidad_d = 'V' --VENCIDO
  	             else 
	                if @w_fpago = 'A'
	                select @w_modalidad_d = 'A' --ANTICIPADO


                     exec @w_return    = sp_conversion_tasas_int
	             @i_base_calculo   = @w_base_calculo,
	             @i_dias_anio      = @w_dias_anio,
   	             @i_periodo_o      = 'A',
	             @i_num_periodo_o  = 1, 
   	             @i_modalidad_o    = 'V',
	             @i_tasa_o         = @w_otra_tasa_rubro,
	             @i_periodo_d      = @w_periodo_d,
	             @i_num_periodo_d  = @w_num_periodo_d,
   	             @i_modalidad_d    = @w_modalidad_d, ---'A',
	             @i_num_dec        = @w_num_dec_tapl,
	             @o_tasa_d         = @w_tasa_nom output  -- NOMINAL

                     if @w_return != 0 return @w_return
       
                     select  @w_porcentaje_new = @w_tasa_nom 
                  end
               end     ---fin @w_tipo_garantia_new
               else
               begin   ---tasa para garantias no vehiculares
                  select @w_porcentaje_new = @w_porcentaje
               end
            end        ---fin @w_valor_garantia = 'S' and @w_porcentaje_cobertura = 'N'


            /* PARA COMISION FAG*/
            if @w_valor_garantia = 'N' and @w_porcentaje_cobertura = 'S' and (@w_concepto = @w_parametro_fag )
            begin

               select @w_valor_actual  = isnull((@w_valor_actual * @w_porcen_cobertura)/100,0)

               select @w_tipo_productor = en_casilla_def
               from cobis..cl_ente
               where en_ente = @w_cliente
               select @w_rowcount = @@rowcount 
               set transaction isolation level read uncommitted

               if @w_rowcount =  0 
               begin  
        	  select @w_error = 710373
	          return @w_error
	       end

               /*CUANTOS MESSES TIENE EL PLAZO DEFINIDO PARA EL CREDITO */
       	       select @w_dias_plazo = td_factor 
  	       from   ca_tdividendo
	       where  td_tdividendo = @w_tplazo
	
               select @w_plazo_en_meses = isnull((@w_plazo * @w_dias_plazo)/30,0)

               select @w_gracia_en_meses = 0

               if @w_gracia_cap > 0
                  select @w_gracia_en_meses = isnull((@w_dias_div * @w_gracia_cap) / 30,0)


               /*SACAR EL VALOR DE LA TABLA ca_tablas_dos_rangos*/

   	       select @w_tasa_comision = isnull(tdr_tasa,0)
	       from ca_tablas_dos_rangos
               where tdr_concepto = @w_parametro_fag
  	       and   tdr_variable = @w_tipo_productor
	       and @w_plazo_en_meses  between tdr_valor1_min    and  tdr_valor1_max ---Plazo
	       and @w_gracia_en_meses between tdr_valor2_min    and  tdr_valor2_max  ---Gracia

               if @@rowcount = 0 begin
                  PRINT 'rubrocal.sp no tiene comision FAG'
                  return 0
               end

               select @w_porcentaje_new =  @w_tasa_comision
            end   ---/* PARA COMISION FAG*/

         end      ---if @w_categoria_rubro = 'S' 


         select @w_valor_rubro        = (@w_valor_actual * @w_dias_div * (@w_porcentaje_new/1000)) /360


         /* CALCULO PARA RUBROS  PORCENTAJE SOBRE RUBROS ASOCIADOS*/
         if @w_concepto_asociado <> null and @w_tipo_rubro = 'O'  and @w_iva_siempre = 'S'
         begin

            select @w_valor_actual = ro_valor
            from ca_rubro_op
            where ro_operacion  = @w_operacionca
            and ro_concepto     = @w_concepto_asociado

            if @w_num_dec is null
               select @w_num_dec = 2

            select @w_porcentaje_new = @w_porcentaje

            select @w_valor_rubro = (@w_porcentaje_new * @w_valor_actual)/100.0 

            select @w_valor_rubro = round(@w_valor_rubro,@w_num_dec)
         end


         update cob_cartera..ca_rubro_op
         set ro_base_calculo  = @w_valor_actual,
         ro_valor             = @w_valor_rubro,
         ro_porcentaje        = @w_porcentaje_new,
         ro_tipo_garantia     = @w_tipo         ---codigo de la nueva garantia
         where ro_operacion   = @w_operacionca
         and   ro_concepto    = @w_concepto

         fetch rubros into 
         @w_concepto,         	   @w_porcentaje,		@w_tipo_garantia,      	
         @w_porcentaje_cobertura,  @w_valor_garantia,     	@w_fpago
      end
      close rubros
      deallocate rubros

   fetch garantias into 
   @w_codigo_externo,
   @w_porcen_cobertura,
   @w_valor_actual,
   @w_clase_vehiculo,
   @w_tipo
end

close garantias
deallocate garantias


SALIR:

return 0

ERROR:

return @w_error

go     









