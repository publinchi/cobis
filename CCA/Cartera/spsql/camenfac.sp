/************************************************************************/
/*	Archivo            :	cofagext.sp	                        */
/*	Stored procedure   :	sp_mensajes_facturacion                 */
/*	Base de datos      :	cob_cartera	                        */
/*	Producto           : 	Credito y Cartera	                */
/*	Disenado por       :  	ELcira Pelaez/Xavier Maldonado          */
/*	Fecha de escritura :	Jul-2005 			        */
/************************************************************************/
/*				            IMPORTANTE                  */
/*	Este programa es parte de los paquetes bancarios propiedad de   */
/*	"MACOSA"	                                                */
/*	Su uso no autorizado queda expresamente prohibido asi como      */
/*	cualquier alteracion o agregado hecho por alguno de sus         */
/*	usuarios sin el debido consentimiento por escrito de la         */
/*	Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*	                     PROPOSITO                                  */
/*	Da mantenimiento a la forma FMEN_EXT.FRM  mensaje para          */
/*      facturacion Periodica                                           */
/************************************************************************/  
/*	                     ACTUALIZACIONES                            */
/*      FECHA        AUTOR                  CAMBIO                      */
/************************************************************************/  
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_mensajes_facturacion')
	drop proc sp_mensajes_facturacion
go

create proc sp_mensajes_facturacion
   @s_user	    		login       	= Null,
   @s_term	    		varchar(30) 	= Null,
   @s_date	    		datetime	= Null,
   @s_ofi	    		smallint	= Null,
   @i_fecha_proceso 		datetime 	= null,
   @i_msg           		varchar(255) 	= null,
   @i_fecha_ini 		datetime   	= null,
   @i_fecha_fin 		datetime   	= null,
   @i_sujeto_credito            catalogo 	= null,
   @i_tipo_productor            varchar(24) 	= null,
   @i_tipo_banca                catalogo 	= null,
   @i_mercado                   catalogo 	= null,
   @i_mercado_objetivo          catalogo 	= null,
   @i_cod_linea                 catalogo 	= null,
   @i_destino_economico         catalogo 	= null,
   @i_oficina                   catalogo	= null,
   @i_zona                      catalogo	= null,  
   @i_regional                  catalogo	= null,
   @i_estado_op                 tinyint 	= null,   
   @i_operacion  		char(1) 	= null,
   @i_modo       		char(1) 	= null,
   @i_opcion     		char(1) 	= null,
   @i_codigo                    catalogo        = null,
   @i_identificador             char(3)         = null,
   @i_estado                    tinyint         = null



as declare 
   @w_error               	int,
   @w_sp_name             	varchar(30),
   @w_fpago_rfag          	catalogo,
   @w_ab_operacion        	int,
   @w_op_banco            	cuenta,
   @w_abd_monto_mn        	money,
   @w_ab_fecha_pag        	datetime,
   @w_abd_concepto        	catalogo,
   @w_ab_secuencial_pag   	int,
   @w_campo_identificador 	char(3),
   @w_fc_fecha_cierre     	datetime,
   @w_fecha_ini           	datetime,
   @w_fecha_fin           	datetime,
   @w_sujeto_credito		catalogo,
   @w_tipo_productor		varchar(24),
   @w_destino_economico		catalogo,
   @w_regional			smallint,
   @w_zona			smallint,
   @w_mercado_objetivo		catalogo,	
   @w_mercado			catalogo,
   @w_estado			tinyint,
   @w_oficina			smallint,	
   @w_linea_credito		catalogo,
   @w_tipo_banca		catalogo,
   @w_destino_economico_desc	descripcion,
   @w_regional_desc		descripcion,                                                                                                                 
   @w_zona_desc			descripcion,
   @w_mercado_objetivo_desc	descripcion,
   @w_mercado_desc		descripcion,
   @w_tipo_productor_desc	descripcion,
   @w_estado_desc		descripcion,
   @w_mensaje_desc		descripcion,
   @w_oficina_desc		descripcion,
   @w_linea_desc		descripcion,
   @w_banca_desc		descripcion,
   @w_sujeto_credito_desc	descripcion,
   @w_fecha_i			varchar(10),
   @w_fecha_f                   varchar(10)   
   
select @w_sp_name = 'sp_mensajes_facturacion'


select @w_fc_fecha_cierre = convert(varchar(10),fc_fecha_cierre,101) 
from   cobis..ba_fecha_cierre
where  fc_producto = 7

select @w_fecha_ini = convert(varchar(10),@i_fecha_ini,101)
select @w_fecha_fin = convert(varchar(10),@i_fecha_fin,101)


if @i_modo = '0'
begin       
   if @i_operacion  = 'I'
   begin
      --VALIDACION DE LOS CODIGOS DE CATALOGO DE LA TABLA CON EL ENVIADO POR EL USUARIO 
      if @i_codigo = '012'
         select @w_campo_identificador = null
      else
         select @w_campo_identificador = @i_identificador
      

      select @i_sujeto_credito = '100'   -------NO ESTA DEFINIDO!!!!!!!!

      if not exists (select 1 from ca_mensaje_facturacion 
                     where mf_fecha_ini_facturacion = @i_fecha_ini
                     and mf_fecha_fin_facturacion   = @i_fecha_fin)
      begin                
         insert into ca_mensaje_facturacion     
         (mf_usuario,  			mf_fecha,             		mf_fecha_ini_facturacion,  
          mf_fecha_fin_facturacion,     mf_sujeto_credito,    		mf_tipo_productor,    
          mf_tipo_banca,                mf_mercado,           		mf_mercado_objetivo,  
          mf_cod_linea,                 mf_destino_economico, 		mf_oficina,           
          mf_zona,                      mf_regional,          		mf_estado_op,         
          mf_mensaje)  
         values
         (@s_user,                      @w_fc_fecha_cierre,   		@i_fecha_ini,
          @i_fecha_fin,                 @i_sujeto_credito,    		@i_tipo_productor,    
          @i_tipo_banca,                @i_mercado,           		@i_mercado_objetivo,  
          @i_cod_linea,                 @i_destino_economico, 		convert(smallint,@i_oficina),           
          convert(smallint,@i_zona),    convert(smallint,@i_regional),  @i_estado_op,                                 
          @i_msg)   
          if @@error <> 0
         begin
            select @w_error = 710566
            goto ERROR
         end           
      end  
      else
      begin
         select @w_error =  710565
         goto ERROR
      end

      select @i_operacion = 'S'
   end          


   if @i_operacion = 'Q'
   begin
      ---select * from   ca_mensaje_facturacion

      select @w_fecha_i           = convert(varchar(10),mf_fecha_ini_facturacion,101),
             @w_fecha_f           = convert(varchar(10),mf_fecha_fin_facturacion,101),
             @w_sujeto_credito    = mf_sujeto_credito,
	     @w_tipo_productor    = mf_tipo_productor,
	     @w_tipo_banca        = mf_tipo_banca,
	     @w_mercado           = mf_mercado,
	     @w_mercado_objetivo  = mf_mercado_objetivo,
             @w_linea_credito     = mf_cod_linea,
	     @w_destino_economico = mf_destino_economico,
	     @w_oficina           = mf_oficina,
	     @w_zona              = mf_zona,
	     @w_regional          = mf_regional,
             @w_estado            = mf_estado_op,
             @w_mensaje_desc      = mf_mensaje
      from ca_mensaje_facturacion
      where  mf_fecha_ini_facturacion = @w_fecha_ini
      and    mf_fecha_fin_facturacion = @w_fecha_fin


      select @w_destino_economico_desc = convert(varchar(48),valor)
      from cobis..cl_catalogo A, cobis..cl_tabla B

      where A.tabla = B.codigo

      and B.tabla  = 'cr_destino' 

      and A.estado = 'V'

      and A.codigo = @w_destino_economico

      set transaction isolation level read uncommitted

      select @w_regional_desc = descripcion_sib
      from cob_credito..cr_corresp_sib
      where tabla = 'T21'
      and   codigo = convert(char(10),@w_regional)
      set transaction isolation level read uncommitted


      select  @w_zona_desc = of_nombre
      from cobis..cl_oficina
      where of_filial = 1
      and of_subtipo = 'Z'
      and of_oficina = @w_zona
      set transaction isolation level read uncommitted

      select @w_mercado_objetivo_desc = convert(varchar(48),valor)

      from cobis..cl_catalogo A, cobis..cl_tabla B

      where A.tabla = B.codigo

      and B.tabla  = 'cl_mercado_objetivo'

      and A.estado = 'V'

      and A.codigo = @w_mercado_objetivo

      set transaction isolation level read uncommitted


      select @w_mercado_desc = convert(varchar(48),valor)

      from cobis..cl_catalogo A, cobis..cl_tabla B

      where A.tabla = B.codigo

      and B.tabla  = 'cl_mercado_objetivo'

      and A.estado = 'V'

      and A.codigo = @w_mercado
      set transaction isolation level read uncommitted


      select @w_tipo_productor_desc = convert(varchar(48),valor)

      from cobis..cl_catalogo A, cobis..cl_tabla B

      where A.tabla = B.codigo

      and B.tabla  = 'cl_tipo_productor'

      and A.estado = 'V'

      and A.codigo = @w_tipo_productor

      set transaction isolation level read uncommitted

      select @w_estado_desc = es_descripcion 
      from ca_estado
      where es_codigo = @w_estado
      set transaction isolation level read uncommitted

      select @w_oficina_desc = convert(varchar(48),valor)
      from cobis..cl_catalogo A, cobis..cl_tabla B

      where A.tabla = B.codigo

      and B.tabla  = 'cl_oficina' 

      and A.estado = 'V'

      and A.codigo = convert(char(10),@w_oficina)
      set transaction isolation level read uncommitted


      select @w_linea_desc = convert(varchar(48),valor)
      from cobis..cl_catalogo A, cobis..cl_tabla B

      where A.tabla = B.codigo

      and B.tabla  = 'ca_toperacion' 

      and A.estado = 'V'

      and A.codigo = @w_linea_credito

      set transaction isolation level read uncommitted

      select @w_banca_desc = convert(varchar(48),valor)
      from cobis..cl_catalogo A, cobis..cl_tabla B

      where A.tabla = B.codigo

      and B.tabla  = 'cl_banca_cliente' 

      and A.estado = 'V'

      and A.codigo = @w_tipo_banca

      set transaction isolation level read uncommitted

      select @w_sujeto_credito_desc = 'NOOOOOOOOO  ESTA DEFINIDO'

      /***...POR DEFINIR
      select @w_linea_desc = convert(varchar(48),valor)

      from cl_catalogo, cl_tabla

      where cl_catalogo.tabla = cl_tabla.codigo

      and cl_tabla.tabla  = ...falta tabla....'cl_sujeto_credito' 

      and cl_catalogo.estado = 'V'

      and cl_catalogo.codigo = @w_sujeto_credito


      ********/

      select @w_fecha_i,
	     @w_fecha_f,

	     @w_regional,
	     @w_regional_desc,

	     @w_zona,
	     @w_zona_desc,

	     @w_oficina,
	     @w_oficina_desc,

	     @w_mercado,
             @w_mercado_desc,                     ---10

	     @w_mercado_objetivo,
             @w_mercado_objetivo_desc,

	     @w_tipo_productor,
	     @w_tipo_productor_desc,              ---14

	     @w_destino_economico,
	     @w_destino_economico_desc,	

	     @w_sujeto_credito,
             @w_sujeto_credito_desc,              ---18
	
	     @w_tipo_banca,
             @w_banca_desc,

             @w_linea_credito,
             @w_linea_desc,                       ---22

             @w_estado,                           ---23
	     @w_estado_desc,                      ---24

             @w_mensaje_desc                      ---25
   end



   if @i_operacion = 'D'
   begin
      delete ca_mensaje_facturacion
      where  mf_fecha_ini_facturacion = @i_fecha_ini
      and    mf_fecha_fin_facturacion = @i_fecha_fin
      if @@error <> 0
      begin
         select @w_error = 710567
         goto ERROR
      end   

      select @i_operacion = 'S'
   end 


   if @i_operacion = 'U'
   begin
      --Actualizar el mensaje del registro
      update ca_mensaje_facturacion
      set mf_mensaje = @i_msg
      where mf_fecha_ini_facturacion = @i_fecha_ini
      and mf_fecha_fin_facturacion   = @i_fecha_fin
         
      if @@error <> 0
      begin
         select @w_error = 710568
         goto ERROR
      end   

      select @i_operacion = 'S'
   end  


   if @i_operacion = 'S'
   begin

      select 'USUARIO' = mf_usuario,
             'FECHA_INICIO'      = convert(varchar(10),mf_fecha_ini_facturacion,101),
	     'FECHA_FIN'         = convert(varchar(10),mf_fecha_fin_facturacion,101),
   	     'SUJETO_CREDITO'    = mf_sujeto_credito,
             'TIPO PRODUCTOR'    = mf_tipo_productor,
	     'TIPO BANCA'        = mf_tipo_banca,
	     'MERCADO'           = mf_mercado,
	     'MERCADO OBJETIVO'  = mf_mercado_objetivo,
             'LINEA CREDITO'     = mf_cod_linea,
             'DESTINO ECONOMICO' = mf_destino_economico,
	     'OFICINA'	         = mf_oficina,
	     'ZONA'              = mf_zona,
             'REGIONAL'          = mf_regional,
             'ESTADO'            = mf_estado_op,
             'MENSAJE'           = mf_mensaje
      from ca_mensaje_facturacion
   end  --Operacion S

end  --- modo 0



--Este modo retorna los selects para la busqueda de los F5 necesarios en la forma
if @i_modo = '1'
begin

   if @i_opcion = 'R'  ---Regionales
   begin
      select 'Codigo' = codigo,
             'Descripcion'= descripcion_sib
      from cob_credito..cr_corresp_sib
      where tabla = 'T21'
      set transaction isolation level read uncommitted      
   end 

   if @i_opcion = 'Z' --Zonas
   begin
      select  'Codigo'      = of_oficina,
	      'Descripcion' = of_nombre
        from cobis..cl_oficina
       where of_filial = 1
	    and of_subtipo = 'Z'
       order by of_oficina
   end  

   if @i_opcion = 'H' --Mercado Objetivo
   begin
      select 'CODIGO' = A.codigo, 
             'DESCRIPCION' = convert(varchar(48),valor)

      from cobis..cl_catalogo A, cobis..cl_tabla B

      where A.tabla = B.codigo

      and B.tabla  = 'cl_mercado_objetivo'

      and A.estado = 'V'

      and A.codigo >  isnull(@i_codigo,' ')
      set transaction isolation level read uncommitted

   end

   if @i_opcion = 'J' --Tipo Productor
   begin
      select 'CODIGO' = A.codigo, 
             'DESCRIPCION' = convert(varchar(48),valor)

      from cobis..cl_catalogo A, cobis..cl_tabla B

      where A.tabla = B.codigo

      and B.tabla  = 'cl_tipo_productor'

      and A.estado = 'V'

      and A.codigo > isnull(@i_codigo,' ')
      set transaction isolation level read uncommitted
   end
 
   if @i_opcion = 'E' -- Estados
   begin
      select 'Codigo'      = es_codigo, 
             'Descripcion' = es_descripcion 
      from ca_estado
      where es_codigo in (1,2,9)
      set transaction isolation level read uncommitted
   end  

end   --modo 1       


if @i_modo = '2'
begin

   if @i_opcion = 'R'  ---Regionales
   begin
      select descripcion_sib
      from cob_credito..cr_corresp_sib
      where tabla = 'T21'
      and   codigo = @i_codigo
      set transaction isolation level read uncommitted      
   end 

   if @i_opcion = 'Z' --Zonas
   begin
      select  of_nombre
      from cobis..cl_oficina
      where of_filial = 1
      and of_subtipo = 'Z'
      and of_oficina = convert(smallint,@i_codigo)
   end  

   if @i_opcion = 'H' --Mercado Objetivo
   begin
      select convert(varchar(48),valor)

      from cobis..cl_catalogo A, cobis..cl_tabla B

      where A.tabla = B.codigo

      and B.tabla  = 'cl_mercado_objetivo'

      and A.estado = 'V'

      and A.codigo = isnull(@i_codigo,' ')
      set transaction isolation level read uncommitted

   end

   if @i_opcion = 'J' --Tipo Productor
   begin
      select convert(varchar(48),valor)

      from cobis..cl_catalogo A, cobis..cl_tabla B

      where A.tabla = B.codigo

      and B.tabla  = 'cl_tipo_productor'

      and A.estado = 'V'

      and A.codigo = isnull(@i_codigo,' ')
      set transaction isolation level read uncommitted
   end
 
   if @i_opcion = 'E' -- Estados
   begin
      select es_descripcion 
      from ca_estado
      where es_codigo = @i_estado
   end  

end   --modo 2       

            
return 0   

ERROR:
   exec cobis..sp_cerror
   @t_debug = 'N',    
   @t_file  = null,
   @t_from  = @w_sp_name,   
   @i_num   = @w_error

   return @w_error 
            
go          
            
            
