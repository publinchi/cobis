/************************************************************************/
/*  Nombre Fisico:          caevalua.sp                                	*/
/*  Nombre Logico:       	sp_evaluacion_cartera                      	*/
/*  Base de Datos:          cob_cartera                                	*/
/*  Producto:               Cartera	                                   	*/
/*  Disenado por:           Elcira Pelaez                              	*/
/*  Fecha de Documentacion: Dic-2002                                   	*/
/************************************************************************/
/*                           IMPORTANTE                                	*/
/*  Este programa es parte de los paquetes bancarios que son       		*/
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  	*/
/*   representantes exclusivos para comercializar los productos y   	*/
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida 	*/
/*   y regida por las Leyes de la República de España y las         	*/
/*   correspondientes de la Unión Europea. Su copia, reproducción,  	*/
/*   alteración en cualquier sentido, ingeniería reversa,           	*/
/*   almacenamiento o cualquier uso no autorizado por cualquiera    	*/
/*   de los usuarios o personas que hayan accedido al presente      	*/
/*   sitio, queda expresamente prohibido; sin el debido             	*/
/*   consentimiento por escrito, de parte de los representantes de  	*/
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  	*/
/*   en el presente texto, causará violaciones relacionadas con la  	*/
/*   propiedad intelectual y la confidencialidad de la información  	*/
/*   tratada; y por lo tanto, derivará en acciones legales civiles  	*/
/*   y penales en contra del infractor según corresponda. 				*/
/************************************************************************/  
/*                           PROPOSITO                                 	*/
/*  Generar la informacion necesaria para el                           	*/
/*  formato de evaluacion de las operaciones del cliente               	*/
/*                        MODIFICACIONES                               	*/
/*  FECHA         AUTOR                 RAZON                          	*/
/*    06/06/2023	 M. Cordova		 Cambio variable @w_op_calificacion */
/*									 de char(1) a catalogo				*/
/************************************************************************/

use cob_cartera
go 

if exists(select 1 from cob_cartera..sysobjects where name = 'sp_evaluacion_cartera')
   drop proc sp_evaluacion_cartera
go

create proc sp_evaluacion_cartera
   @i_opcion          char(1) = '3',
   @s_user            login
as declare 
   @w_situacion              varchar(10),
   @w_sp_name                varchar(20),
   @w_regional               descripcion,
   @w_zona                   descripcion,
   @w_municipio              descripcion,
   @w_garantia               varchar(64),   
   @w_tipo_garantia          varchar(64), 
   @w_des_tipo_garantia      descripcion,
   @w_op_nombre              descripcion,
   @w_descripcion_reest      descripcion,
   @w_descripcion_garantia   descripcion,
   @w_fecha_avaluo           datetime,
   @w_fecha_fin_min_div_ven  datetime,
   @w_fecha_proceso          datetime,
   @w_cliente_desde          datetime,
   @w_valor_avaluo           money, 
   @w_defecto_garantia       money,
   @w_op_oficina             int,     
   @w_op_banco               cuenta,
   @w_op_calificacion        catalogo,
   @w_op_reestructuracion    char(1),
   @w_tr_subtipo             char(1),
   @w_deudas_castigadas      char(2),
   @w_riesgo_superior        char(2),
   @w_acreencias_nlegales    char(2),
   @w_error                  int,
   @w_return                 int,
   @w_op_numero_reest        int,
   @w_op_operacion           int,
   @w_op_tramite             int,
   @w_op_cliente             int,
   @w_dias_vencidos_op       int,
   @w_producto               int,
   @w_oficina_contable       int,
   @w_codregional            smallint,             
   @w_codzona                int,             
   @w_codmunicipio           int,             
   @w_ced_ruc                numero,
   @w_op_divcap_original     int
   
select @w_sp_name = 'sp_evaluacion_cartera'

truncate table ca_inf_general_evaluacion
truncate table ca_inf_codeu_evaluacion

if @i_opcion = '1' begin ---Reestructuradas con mora
   declare cursor_operaciones_evaluacion cursor  
   for select
   op_oficina,
   op_nombre,
   op_banco,
   op_operacion,
   op_calificacion,
   op_reestructuracion,
   op_numero_reest,
   op_tramite,
   op_cliente,
   op_fecha_ult_proceso,
   op_divcap_original
   from ca_operacion,ca_estado
   where op_numero_reest > 0
   and op_edad > 1
   and op_naturaleza = 'A'
   and op_estado     = es_codigo
   and es_procesa    = 'S'

   for read only

end --- Fin Reestructuradas con mora

if @i_opcion = '2' begin ---Reestructuradas Todas
   declare cursor_operaciones_evaluacion cursor  
   for select
   op_oficina,
   op_nombre,
   op_banco,
   op_operacion,
   op_calificacion,
   op_reestructuracion,
   op_numero_reest,
   op_tramite,
   op_cliente,
   op_fecha_ult_proceso,
   op_divcap_original
   from ca_operacion,ca_estado
   where op_numero_reest > 0 
   and op_naturaleza = 'A'
   and op_estado     = es_codigo
   and es_procesa    = 'S'

   for read only

end --- Todas Reestructuradas

if @i_opcion = '3' begin ---Toda la cartera comercial
   declare cursor_operaciones_evaluacion cursor  
   for select
   op_oficina,
   op_nombre,
   op_banco,
   op_operacion,
   isnull(op_calificacion,'A'),
   op_reestructuracion,
   op_numero_reest,
   op_tramite,
   op_cliente,
   op_fecha_ult_proceso,
   op_divcap_original
   from ca_operacion,ca_estado
   where op_clase    = '1'
   and op_naturaleza = 'A'
   and op_estado     = es_codigo
   and es_procesa    = 'S'

   for read only

end --- Toda la cartera comercial

open cursor_operaciones_evaluacion
fetch cursor_operaciones_evaluacion
into
   @w_op_oficina,
   @w_op_nombre,
   @w_op_banco,
   @w_op_operacion,
   @w_op_calificacion,
   @w_op_reestructuracion,
   @w_op_numero_reest,
   @w_op_tramite,
   @w_op_cliente,
   @w_fecha_proceso,
   @w_op_divcap_original
        
while (@@fetch_status = 0) begin
   if (@@fetch_status = -1) begin
      close cursor_operaciones_evaluacion
      deallocate cursor_operaciones_evaluacion
      select @w_error = 710004 
      return @w_error
   end 
    
   /*DIAS VENCIDOS OPERACION*/
   select @w_fecha_fin_min_div_ven = (min(di_fecha_ven))
   from ca_dividendo
   where di_operacion = @w_op_operacion
   and di_estado = 2 --Vencido

   /*DIAS VENCIDOS OPERACION*/
   select @w_dias_vencidos_op = 0
   select @w_dias_vencidos_op = isnull(datediff(dd,@w_fecha_fin_min_div_ven,@w_fecha_proceso),0) 

   select @w_dias_vencidos_op = @w_dias_vencidos_op +  isnull(@w_op_divcap_original, 0)   ---XMA CARTERIZACION 

   /* CUBRE SUFICIENTEMENTE LA TOTALIDAD DE ACREENCIAS SEGUN NORMAS LEGALES */

   select @w_producto = pd_producto
   from cobis..cl_producto
   where pd_abreviatura = 'CCA' 
   set transaction isolation level read uncommitted 

   select @w_defecto_garantia = 0

   select @w_defecto_garantia = isnull((co_xprov_cap + co_xprov_int + co_xprov_ctasxcob ),0)
   from cob_credito..cr_calificacion_op --(INDEX cr_calificacion_op_Key)
   where co_producto      = @w_producto
   and   co_operacion     = @w_op_operacion

   select @w_acreencias_nlegales = 'SI'
   if @w_defecto_garantia > 0
      select @w_acreencias_nlegales = 'NO'

   
   /*REGIONAL ZONA Y MUNICIPIO*/

   ---Pendiente mientras  se define en ADMIN

   select 
   @w_codzona      = of_oficina,
   @w_codregional  = of_regional,
   @w_codmunicipio = of_ciudad
   from  cobis..cl_oficina
   where of_oficina = @w_op_oficina  
   set transaction isolation level read uncommitted
 
   select @w_municipio = ci_descripcion 
   from  cobis..cl_ciudad
   where ci_ciudad = @w_codmunicipio  
   set transaction isolation level read uncommitted

   select @w_zona = nombre         
   from  cobis..cl_sucursal
   where sucursal  = @w_codzona
   set transaction isolation level read uncommitted

   ---REGIONAL
   select @w_regional = nombre
   from   cobis..cl_sucursal
   where  sucursal = @w_codregional
   set transaction isolation level read uncommitted

   /*CLIENTE DEL BANCO DESDE y IDENTIFICACION*/ 

   select  
   @w_ced_ruc       =  en_ced_ruc,
   @w_cliente_desde =  en_fecha_crea,
   @w_situacion     =  en_situacion_cliente
   from cobis..cl_ente
   where en_ente = @w_op_cliente
   set transaction isolation level read uncommitted

   select  @w_deudas_castigadas = 'NO'
   if @w_situacion = 'CAS'
      select @w_deudas_castigadas = 'SI'


   /*OPERACIONES EN RIESGO SUPERIOR A ESTE*/

   select @w_riesgo_superior = 'NO'     
   if exists(select 1 from ca_operacion
             where op_calificacion > @w_op_calificacion
             and op_cliente = @w_op_cliente)
      select @w_riesgo_superior = 'SI'


   /*MOTIVO DE LA REESTRUCTURACION*/

   select @w_tr_subtipo = tr_subtipo
   from cob_credito..cr_tramite
   where tr_tramite = @w_op_tramite


   /*DESCRIPCION*/

   select @w_descripcion_reest = null

   select @w_descripcion_reest = valor 
   from cobis..cl_catalogo noholdlock
   where tabla = (select codigo
                  from cobis..cl_tabla noholdlock
                  where tabla = 'cr_subtipo_tramite')
   and codigo = @w_tr_subtipo


   /* DATOS DE LA GARANTIA EN GENERAL */
   
   exec @w_return   =  cob_cartera..sp_datos_garantia_cca
        @s_user     = @s_user,
        @i_cliente  = @w_op_cliente
        

   if @w_return <> 0 
   begin
       close cursor_operaciones_evaluacion
       deallocate cursor_operaciones_evaluacion
       select @w_error = @w_return
       return @w_error
   end

   select @w_garantia              = dg_no_garantia,
          @w_des_tipo_garantia     = dg_desc_tipo_garantia,         
          @w_descripcion_garantia  = dg_desc_garantia,
          @w_fecha_avaluo          = dg_fecha_avaluo,
          @w_valor_avaluo          = dg_valor
   from  ca_detalles_garantia_deudor
   where dg_user    = @s_user
   and   dg_tramite = @w_op_tramite

   select @w_oficina_contable = re_ofconta
   from cob_conta..cb_relofi
   where re_ofadmin = @w_op_oficina

   insert ca_inf_general_evaluacion (
          ev_regional,               ev_zona,                   ev_oficina, 
          ev_codigo_contable,        ev_nombre_cliente,         ev_numero_obligacion,
          ev_fecha_cliente_desde,    ev_municipio,              ev_identificacion, 
          ev_calif_superiores,       ev_num_reestructuraciones, ev_motivo_reestructuracion,
          ev_dias_mora,              ev_tipo_garantia,          ev_descripcion_garantia,
          ev_cubre_acreencias,       ev_fecha_avaluo,           ev_valor_avaluo,
          ev_deudas_castigadas)
   values( 
          @w_regional,               @w_zona,                   @w_op_oficina,    
          @w_oficina_contable,       @w_op_nombre,              @w_op_banco,
          @w_cliente_desde,          @w_municipio,              @w_ced_ruc,
          @w_riesgo_superior,        @w_op_numero_reest,        @w_descripcion_reest,
          @w_dias_vencidos_op,       @w_des_tipo_garantia,      @w_descripcion_garantia,
          @w_acreencias_nlegales,    @w_fecha_avaluo,           @w_valor_avaluo,
          @w_deudas_castigadas)

   if @@error <> 0 
   begin
       close cursor_operaciones_evaluacion
       deallocate cursor_operaciones_evaluacion
       select @w_error = 710030                 
       return @w_error
   end

   /* ENVIO DE LOS CODEUDORES  */
   insert into ca_inf_codeu_evaluacion
   select @w_op_banco,
          de_rol,
          substring(rtrim(en_nombre) + ' ' + rtrim(p_p_apellido) + ' ' + rtrim(p_s_apellido),1,35),
          de_ced_ruc
   from cob_credito..cr_deudores,
        cobis..cl_ente noholdlock
   where de_tramite = @w_op_tramite
   and   de_cliente = en_ente
   and   de_rol  not in ('D','I')  ---Ingresa todos los codeudores existentes para este tramite

   if @@error <> 0 
   begin
       close cursor_operaciones_evaluacion
       deallocate cursor_operaciones_evaluacion
       select @w_error = 710030               
       return @w_error
   end

   fetch cursor_operaciones_evaluacion
   into
       @w_op_oficina,
       @w_op_nombre,
       @w_op_banco,
       @w_op_operacion,
       @w_op_calificacion,
       @w_op_reestructuracion,
       @w_op_numero_reest,
       @w_op_tramite,
       @w_op_cliente,
       @w_fecha_proceso,
       @w_op_divcap_original
 
end
close cursor_operaciones_evaluacion
deallocate cursor_operaciones_evaluacion

return 0  
go             
