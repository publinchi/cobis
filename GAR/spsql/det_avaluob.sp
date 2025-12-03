/*************************************************************************/
/*   Archivo:              det_avaluob.sp                                */
/*   Stored procedure:     sp_det_avaluo_bien                            */
/*   Base de datos:        cob_custodia                                  */
/*   Producto:             Garantias                                     */
/*   Disenado por:                                                       */
/*   Fecha de escritura:   Marzo 2019                                    */
/*************************************************************************/
/*                                  IMPORTANTE                           */
/*   Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*   de MACOSA S.A.                                                      */
/*   Su uso no autorizado queda expresamente prohibido asi como          */
/*   cualquier alteracion o agregado hecho por alguno de sus             */
/*   usuarios sin el debido consentimiento por escrito de MACOSA         */
/*   Este programa esta protegido por la ley de derechos de autor        */
/*   y por las  convenciones  internacionales de  propiedad inte-        */
/*   lectual.  Su uso no  autorizado dara  derecho a  MACOSA para        */
/*   obtener  ordenes de  secuestro o retencion y  para perseguir        */
/*   penalmente a los autores de cualquier infraccion.                   */
/*************************************************************************/
/*                                   PROPOSITO                           */
/*    Creacion de objetos de la base. Comprende: tablas, indices,sp      */
/*    tipos de datos, claves primarias y foraneas                        */
/*                                                                       */
/*			                                                             */
/*************************************************************************/
/*                             MODIFICACION                              */
/*    FECHA                   AUTOR                 RAZON                */
/*    Marzo/2019                                      emision inicial    */
/*                                                                       */
/*************************************************************************/
USE cob_custodia
go
IF OBJECT_ID('dbo.sp_det_avaluo_bien') IS NOT NULL
    DROP PROCEDURE dbo.sp_det_avaluo_bien
go
create proc sp_det_avaluo_bien
(
		@s_ssn                  int = null,
		@s_user                 login = null,
		@s_term                 varchar(30) = null,
		@s_date                 datetime = null,
		@s_srv                  varchar(30) = null,
		@s_lsrv                 varchar(30) = null,
		@s_ofi        	        smallint = null,
		@s_rol			smallint = NULL,
		@s_org_err		char(1) = NULL,
		@s_error		int = NULL,
		@s_sev			tinyint = NULL,
		@s_org			char(1) = NULL,
		@t_debug        	char(1) = 'N',
		@t_file         	varchar(10) = null,
		@t_trn			smallint ,
		@i_filial               tinyint  = null,
                @i_sucursal             smallint  = null,
		@i_operacion        	char(1),
		@i_tipo			char(1) = null,
     	        @i_codigo		varchar(10) = null,
    	        @i_fecha    		datetime =null,
		@i_secuencial		int		=null,
		@i_cod_gar   		int		=null,
		@i_tramite   		int		=null,
		@i_tipo_cus             varchar(64) =null ,
		@i_valor_terreno 	money =null,
		@i_num_terreno		money   =null,
		@i_v_comercial		money =null,
	        @i_v_areas	    	money =null,
		@i_num_cons             money =null,
		@i_total_cuadrado       money =null,
		@i_valor_cuadrado       money =null,
		@i_valor_catastral      money =null,
		@i_vivienda             catalogo = null,
		@i_garantia_bien        catalogo = null,
		@i_anio_const           int = null,
		@i_tipo_const           catalogo = null,
		@i_agua_potable         catalogo = null,
		@i_energia		catalogo  = null,
		@i_alcantarillado       catalogo = null,
                @i_vias                 catalogo = null,
		@i_num_habitaciones     int = null,
		@i_num_banios           int   = null,
                @i_valor_realizacion    money = null,
		@i_credito              catalogo = null

)
as
declare @w_today        	datetime,
	@w_sp_name      	varchar(32),
	@w_return		int,
	@w_cod_gar		int,
	@w_secuencial		int,
	@w_secuencial_det	int,
	@w_tipo_cus             catalogo, 
	@w_fecha                datetime,
	@w_vivienda             char(1),
	@w_hora                 varchar(20),
	@w_codigo_externo       varchar(64),
	@w_valor                varchar(64),
	@w_garantia             varchar(255)	
	
	
select @w_hora = convert(varchar(20),getdate(),108)
select @w_today = convert(varchar(10),getdate(),101)
select @w_sp_name = 'sp_det_avaluo_bien'

/* Codigos de Transacciones                                */
if (@t_trn <> 19679 and @i_operacion in ('I','U','S','C','Q'))
begin
    /* tipo de transaccion no corresponde */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file, 
    @t_from  = @w_sp_name,
    @i_num   = 1901006
    return 1 
end


if @i_operacion = 'I'
begin
      --obtener el numero externo de la garantia que esta enviando a grabar el avaluo
	  select @w_codigo_externo  = cu_codigo_externo
		from cob_custodia..cu_custodia x
                where cu_filial = @i_filial 
		  and cu_sucursal = @i_sucursal 
		  and cu_tipo = @i_tipo_cus 
		  and cu_custodia = @i_cod_gar 
		  
		  if @i_vivienda='S'
				begin
				print 'Confirme que posea la Declaraci+Ýn Juramentada por parte del Perito'
				end
		  
	  if isnull(@i_tramite,0) <> 0
	      begin

--                    declare cursor_1 insensitive cursor for  			 
                    declare cursor_1 cursor for  			 
		     select  gp_garantia
		       from cob_credito..cr_gar_propuesta 
		      where gp_tramite = @i_tramite
			  
		 open cursor_1
                 fetch cursor_1 into @w_garantia
	
            while   @@FETCH_STATUS != -1
            begin
               if (@@FETCH_STATUS = -2) 
			   begin    
  			     return 71000
			   end 

		        select @w_vivienda=av_vivienda_unica from cob_custodia..cu_det_avaluo_bien where av_garantia =@w_garantia

			     if  @w_vivienda = 'N' and @i_vivienda = 'S'
					 begin
					    close cursor_1
						deallocate cursor_1
					   exec cobis..sp_cerror
						@t_debug        = @t_debug,
						@t_file         = @t_file,
						@t_from         = @w_sp_name,
						@i_num          = 1909019  
					    return 1	
				    end
				     			   
			     if  @w_vivienda = 'S' and @i_vivienda = 'S'
					 begin
					    close cursor_1
						deallocate cursor_1
					   	exec cobis..sp_cerror
							 @t_debug      = @t_debug,
							 @t_file       = @t_file,
							 @t_from       = @w_sp_name,
							 @i_num        = 1909019
						return 1
					 end
					 fetch cursor_1 into  @w_garantia
			  end
			  
			  close cursor_1
                          deallocate cursor_1
	        end
         		
				
		     select @w_secuencial = isnull(max(av_secuencial),0) + 1  from cu_det_avaluo_bien
				where       av_garantia				= @w_codigo_externo
				   and 	    av_tipo_cus             = @i_tipo_cus
						
						
				insert into cu_det_avaluo_bien
				(
						av_secuencial,
						av_fecha,
						av_hora,
						av_cod_garantia,
						av_garantia,
						av_tipo_cus,
						av_valor_terreno,
						av_num_terreno,
						av_valor_comercial,
						av_fecha_avaluo,
						av_valor_areas,
						av_num_mconstruccion,
						av_total_mcuadrados,
						av_valor_mcuadrados,
						av_valor_catastral,
						av_vivienda_unica,
						av_garantia_bien,
						av_anio_construccion,
						av_tipo_construccion,
						av_agua_potable,
						av_energia_elec,
						av_alcantarillado,
						av_vias_acceso,
						av_num_habitacion,
						av_num_banios,
						av_valor_realizacion,
						av_destino_cr
				)
				values
				(
						@w_secuencial   ,
						@w_today		,
						@w_hora			,
						@i_cod_gar		,
						@w_codigo_externo	,
						@i_tipo_cus        ,
						@i_valor_terreno 	,
						@i_num_terreno		,
						@i_v_comercial		,
						@s_date		        ,
						@i_v_areas	       ,
						@i_num_cons        ,
						@i_total_cuadrado   ,
						@i_valor_cuadrado   ,
						@i_valor_catastral  ,
						@i_vivienda        ,
						@i_garantia_bien   ,
						@i_anio_const      ,
						@i_tipo_const      ,
						@i_agua_potable    ,
						@i_energia		,
						@i_alcantarillado   ,
						@i_vias         ,
						@i_num_habitaciones ,
						@i_num_banios        ,
						@i_valor_realizacion,
						@i_credito			
				)
	     	 
			   if @@error <> 0 
				 begin
					 /* Error en insercion de registro */
					 exec cobis..sp_cerror
					 @t_debug = @t_debug,
					 @t_file  = @t_file, 
					 @t_from  = @w_sp_name,
					 @i_num   = 1903001
					 return 1 
				 end
end

if @i_operacion = 'U'
begin	
               /*VERIFICO SI EXISTE DETALLE DE AVALUO*/
            
		select 
		   @w_secuencial_det  = av_secuencial,
		   @w_fecha   = av_fecha, 
		   @w_garantia  =av_garantia
	       from cu_det_avaluo_bien 
              where 	  av_cod_garantia	   = @i_cod_gar
                 and 	  av_tipo_cus           = @i_tipo_cus
			     and      av_secuencial         = @i_secuencial              
            
         /*SI NO EXISTE REGISTRO, GRABO LOS DATOS DEL FIDUCIARIA*/
         if @@rowcount <> 0
         begin
                        
            /*verifica si ha cambiado algun dato*/
             
               --************************************************************************
               --*GRABA DATOS DETALLE DE AVALUO DE BIENES INMUEBLES
               --************************************************************************

		update cu_det_avaluo_bien
		set
		av_valor_terreno     =   @i_valor_terreno,
                av_num_terreno       = 	 @i_num_terreno	 ,
                av_valor_comercial   =   @i_v_comercial,
                av_valor_areas       =   @i_v_areas,
                av_num_mconstruccion =   @i_num_cons,
                av_total_mcuadrados  =   @i_total_cuadrado,
                av_valor_mcuadrados  =   @i_valor_cuadrado,
                av_valor_catastral   =   @i_valor_catastral,
                av_vivienda_unica    =   @i_vivienda,
                av_garantia_bien     =   @i_garantia_bien,
                av_anio_construccion =   @i_anio_const,
                av_tipo_construccion =   @i_tipo_const,
                av_agua_potable      =   @i_agua_potable,
                av_energia_elec      =   @i_energia,
                av_alcantarillado    =   @i_alcantarillado,
                av_vias_acceso       =   @i_vias,
                av_num_habitacion    =   @i_num_habitaciones ,
                av_num_banios        =   @i_num_banios,
                av_valor_realizacion =   @i_valor_realizacion,
                av_destino_cr        =   @i_credito				
		where     av_secuencial     =  @i_secuencial
		   and    av_cod_garantia   =  @i_cod_gar
                   and 	  av_tipo_cus       =  @i_tipo_cus
		
      if @@error <> 0 
         begin
             /* Error en insercion de registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1909002
             return 1 
         end

	
  end /*end del <> 0 */
end


if @i_operacion = 'S'
begin
		select @w_valor= LOWER (RTRIM(valor))  from cobis..cl_catalogo 
				where tabla = (select codigo  
						from cobis..cl_tabla 
						where tabla ='cu_destino_bien_235') 
						and codigo = @i_tipo_cus	
			set rowcount 20
				 
		select 
			"Secuencial"=av_secuencial	,	 --1
			"Fecha" = convert(varchar(20),av_fecha,101),  --2
                        "Garantia"=av_garantia,    --3
			"Tipo Custodia" =	av_tipo_cus,    --4 			
			"Valor terreno" = av_valor_terreno,   --5
                        "Num. Terreno" = av_num_terreno,      --6
                        "Valor Comercial"  = av_valor_comercial,    --7
                        "Valor Areas" = av_valor_areas  ,          --9
                        "Num. Construccion" = av_num_mconstruccion ,         --10
                        "Total Cuadrados" = av_total_mcuadrados ,            --11
                        "Valor Cuadrados" = av_valor_mcuadrados ,            --12
                        "Valor Catastral" = av_valor_catastral ,             --13 
                        "Vivienda" = av_vivienda_unica,                      --14
			"Desc. vivienda" = (select b.valor from cobis..cl_tabla a, cobis..cl_catalogo b
				where a.tabla = 'cu_dicotomica'
				 and    b.tabla       = a.codigo
				and b.codigo = c.av_vivienda_unica),              --15
			"Garantia bien" = av_garantia_bien,                 --16
			"Desc. garantia" = (select b.valor from cobis..cl_tabla a, cobis..cl_catalogo b
				where a.tabla = 'cu_dicotomica'
				 and    b.tabla       = a.codigo
				and b.codigo = c.av_garantia_bien),                --17
                        "A+Ýo Construc" = av_anio_construccion,              --18
                        "Tipo Construc" = av_tipo_construccion,            --19
                        "Desc. Tipo Cons" = (select b.valor from cobis..cl_tabla a, cobis..cl_catalogo b
				where a.tabla = 'cu_tipo_construccion'
				 and    b.tabla       = a.codigo
				and b.codigo = c.av_tipo_construccion),   --20
                        "Agua potable"= av_agua_potable,              --21
			"Desc. agua" = (select b.valor from cobis..cl_tabla a, cobis..cl_catalogo b
				where a.tabla = 'cu_dicotomica'
				 and    b.tabla       = a.codigo
				and b.codigo = c.av_agua_potable),            --22
                        "Energia Elec." = av_energia_elec,            --23
			"Desc. energia" = (select b.valor from cobis..cl_tabla a, cobis..cl_catalogo b
				where a.tabla = 'cu_dicotomica'
				 and    b.tabla       = a.codigo
				and b.codigo = c.av_energia_elec),            --24
                        "Alcantarillado" = av_alcantarillado,             --25 
			"Desc. alcantar" = (select b.valor from cobis..cl_tabla a, cobis..cl_catalogo b
				where a.tabla = 'cu_dicotomica'
				 and    b.tabla       = a.codigo
				and b.codigo = c.av_alcantarillado),            --26
                        "Vias Acceso"  =  av_vias_acceso,                   --27
			"Desc. Vias " = (select b.valor from cobis..cl_tabla a, cobis..cl_catalogo b
				where a.tabla = 'cu_dicotomica'
				 and    b.tabla       = a.codigo
				and b.codigo = c.av_vias_acceso),               --28  
                        "Num. Habitaciones" = av_num_habitacion,            --29
                        "Num. Ba+Ýos "  = av_num_banios,                      --30   
                        "Valor Realizacion" = av_valor_realizacion,          --31    
			"Destino Credito" = av_destino_cr,                   --32   
			"Desc. Credito" = (select valor from cobis..cl_catalogo 
					   where tabla = (select codigo  
                                                           from cobis..cl_tabla 
                                                           where tabla = @w_valor)
					  	           and   codigo = c.av_destino_cr)               --33  
		from cu_det_avaluo_bien c
		where     av_cod_garantia   = @i_cod_gar
                    and   av_tipo_cus       = @i_tipo_cus
		    and   av_secuencial     > @i_secuencial
		order by av_garantia, av_tipo_cus, av_secuencial
end

if @i_operacion = 'C'
begin
     select @w_valor= LOWER (RTRIM(valor)) from cobis..cl_catalogo 
				where tabla = (select codigo  
						from cobis..cl_tabla 
						where tabla ='cu_destino_bien_235') 
	  					   and codigo = @i_tipo_cus
		
	if @i_tipo ='A'
	begin
		select "C+Ýdigo"=rtrim(codigo), "Descripci+Ýn "=convert(varchar(48),valor)  
		from cobis..cl_catalogo 
		where tabla = (select codigo  
                               from cobis..cl_tabla 
                               where tabla =@w_valor)
	end
	 
	if @i_tipo='V'
	begin
	  select valor  from cobis..cl_catalogo 
			where tabla = (select codigo  
                                       from cobis..cl_tabla 
                                       where tabla =@w_valor)
		     		        and   codigo = @i_codigo
	end
end

if @i_operacion = 'Q'
begin
     select b.codigo
	  from cobis..cl_tabla a, cobis..cl_catalogo b
	  where a.tabla ='cu_tipo_cust_vivienda'
	    and    b.tabla       = a.codigo
end

return 0
GO
