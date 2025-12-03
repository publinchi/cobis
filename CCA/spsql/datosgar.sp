/************************************************************************/
/*	Archivo:              datosgar.sp                                    */
/*	Stored procedure:     sp_datos_garantia_cca                          */
/*	Base de datos:        cob_cartera                                    */
/*	Producto: 	          Cartera                                        */
/*	Disenado por:  	    Elcira Pelaez Burbano                          */
/*	Fecha de escritura:   Dic/03/2002                                    */
/************************************************************************/
/*	                         IMPORTANTE                                  */
/*	Este programa es parte de los paquetes bancarios propiedad de        */
/*	"MACOSA".                                                            */
/*	Su uso no autorizado queda expresamente prohibido asi como           */
/*	cualquier alteracion o agregado hecho por alguno de sus              */
/*	usuarios sin el debido consentimiento por escrito de la              */
/*	Presidencia Ejecutiva de MACOSA o su representante.                  */
/************************************************************************/  
/*	                          PROPOSITO                                  */
/*	Retorna datos referente a la garantia de un tramite enviado          */
/* como parametro                                                       */
/************************************************************************/  
/*		                MODIFICACIONES                                    */
/*    FECHA          AUTOR             MODIFICACION                     */
/*    May 2005       Elcira Pelaez     % cobertura Garantia def. 2237   */
/*    Abr 2006       Elcira Pelaez     def. 6276 garantias clase O      */
/************************************************************************/  
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_datos_garantia_cca')
	drop proc sp_datos_garantia_cca
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

create proc sp_datos_garantia_cca(
        @s_user                   login,
        @i_cliente                int          = null
)
as
declare	
@w_sp_name                descripcion,
@w_return 	              int,
@w_garantia               varchar(64),   
@w_tipo_garantia          varchar(64), 
@w_des_tipo_garantia      varchar(64),
@w_clase_garantia         char(1),
@w_des_clase_garantia     varchar(64),
@w_valor_garantia         money,     
@w_valor_cobertura        money,     
@w_cobertura_garantia     float,
@w_ente_propietario_gar   int,
@w_des_tipo_bien          varchar(64),
@w_tipo_bien              catalogo,
@w_determinada_indeter    char(1),
@w_abierta_cerrada        char(1),
@w_descripcion_garantia   varchar(64),
@w_fecha_avaluo           datetime,
@w_valor_actual           money,
@w_error                  int,
@w_propietario_gar	     char(2),
@w_detalle_ac		        varchar(15),
@w_detalle_id		        varchar(15),
@w_detalle_garantia	     varchar(64),
@w_defecto_garantia       money,
@w_producto	              tinyint,
@w_cobertura_garantias    money,
@w_porcentaje_cobertura   float,
@w_estado		           catalogo,
@w_tipo_deudor		        catalogo,
@w_filial		           smallint,
@w_tramite		           int,
@w_sucursal		           smallint,
@w_tipo			           varchar(64),
@w_localizacion		     catalogo,
@w_rol			           catalogo,
@w_operacion              int,
@w_contador_gar           int,
@w_dias_vencidos_op       int,
@w_numero_cuotas_vencidas int,
@w_fecha_mora_desde       datetime,
@w_tipogar_hipo           catalogo,
@w_tipo_superior          catalogo,
@w_meses_ven              int,
@w_fec_ult_proceso        datetime,
@w_dg_monto_distribuido   money,
@w_dg_valor_resp          money


-- Captura nombre de Stored Procedure  
select	@w_sp_name = 'sp_datos_garantia_cca'
select   @w_contador_gar           = 0,
         @w_dias_vencidos_op       = 0,
         @w_numero_cuotas_vencidas = 0,
         @w_meses_ven              = 0

select @w_producto = pd_producto 
from cobis..cl_producto
where pd_abreviatura = 'CCA'
set transaction isolation level read uncommitted

--PARAMETRO TIPO GARANTIA HIPOTECARIA
select @w_tipogar_hipo = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'GARHIP'
set transaction isolation level read uncommitted


--- SE ELIMINAN LOS DATOS  DEL USUARIO  QUE ESTA REALIZANDO LA OPERACION
delete ca_detalles_garantia_deudor
where dg_user = @s_user
and   dg_cliente = @i_cliente  


declare cursor_garantias cursor  

for select gp_garantia, de_rol,gp_tramite,op_operacion
      from cob_credito..cr_gar_propuesta, 
           cob_cartera..ca_operacion,
           cob_credito..cr_deudores, 
           cob_custodia..cu_custodia 
      where gp_tramite = de_tramite 
      and   gp_garantia = cu_codigo_externo
      and   cu_estado    in ('V','X','F')
      and   de_cliente = @i_cliente
      and   op_tramite  = gp_tramite
      and   cu_valor_actual > 0
      and   op_estado not in(0,3,99,98,6)
      and cu_tipo != '6100'

    open cursor_garantias
    fetch cursor_garantias into @w_garantia, @w_rol,@w_tramite,@w_operacion

    while (@@fetch_status = 0) 
    begin
         if (@@fetch_status = -1) 
         begin
	    print 'Error en Cursor garantias sp_datos_garantia_cca' 
            select @w_error = 710395 -- Crear error
            return @w_error
         end 

         select @w_tipo_garantia        = cu_tipo,
                @w_valor_garantia       = cu_valor_inicial,
                @w_cobertura_garantia   = '',--cu_porcentaje_cobertura,  AGI. 22ABR19.  Se comenta porque no existe el campo                
                @w_valor_cobertura      = cu_valor_actual, 
                @w_clase_garantia       = '',--cu_clase_custodia, AGI. 22ABR19.  Se comenta porque no existe el campo
                @w_determinada_indeter  = '', --cu_cuantia, --I o  D  AGI. 22ABR19.  Se comenta porque no existe el campo
                @w_abierta_cerrada      = cu_abierta_cerrada,
                @w_descripcion_garantia = cu_descripcion,
                @w_valor_actual         = cu_valor_actual,
	             @w_estado	             = cu_estado,
	            @w_localizacion         = ''--cu_ubicacion  AGI. 22ABR19.  Se comenta porque no existe el campo
         from   cob_custodia..cu_custodia
         where  cu_codigo_externo = @w_garantia

         if @w_valor_cobertura = 0
            select @w_valor_cobertura = @w_valor_actual


         
        select @w_cobertura_garantias   = 0
        select @w_porcentaje_cobertura  = 0
        
        
        select @w_dg_monto_distribuido = isnull(dg_monto_distribuido,0),
               @w_dg_valor_resp        = isnull(dg_valor_resp,0)
        from cob_credito..cr_dato_garantia
        where dg_garantia =  @w_garantia
        and   dg_producto = 7
        and   dg_operacion =  @w_operacion
        
        if @w_dg_monto_distribuido > 0 and @w_dg_valor_resp > 0
        begin
           select @w_porcentaje_cobertura =  round(@w_dg_monto_distribuido / @w_dg_valor_resp,2)
           select @w_porcentaje_cobertura = @w_porcentaje_cobertura * 100
        end   


	    if @w_porcentaje_cobertura < 0
	       select @w_porcentaje_cobertura = 0

           
        
        select @w_cobertura_garantias   = isnull(dg_valor_resp,0)
        from cob_credito..cr_dato_garantia
        where dg_garantia =  @w_garantia
        and   dg_producto = 7
        and   dg_operacion =  @w_operacion

	if @w_cobertura_garantias < 0
	   select @w_cobertura_garantias = 0


   --EL PORCENTAJE DE COBERTURA DEBE SALIR DE UN TABLA DE PARAMETRIZACION
   --LLAMADA  cob_credito.cr_param_gar
   
      -- DIAS VENCIDOS OPERACION
      --------------------------
      
      -- FECHA FIN MINIMA DE DIVIDENDOS VENCIDOS
      select @w_fecha_mora_desde = min(di_fecha_ven)
      from   ca_dividendo
      where  di_operacion = @w_operacion
      and    di_estado = 2         

    -- NUMERO CUOTAS VENCIDAS
      select @w_numero_cuotas_vencidas = count(1) 
      from   ca_dividendo
      where  di_operacion = @w_operacion
      and    di_estado = 2 
      set transaction isolation level read uncommitted
            
      if @w_numero_cuotas_vencidas > 0 
      begin
         select @w_fec_ult_proceso = op_fecha_ult_proceso
         from ca_operacion
         where op_operacion = @w_operacion
         
         select @w_dias_vencidos_op = isnull(datediff(dd,@w_fecha_mora_desde,@w_fec_ult_proceso),0)  
      end
      else
        select @w_dias_vencidos_op = 0

      select @w_meses_ven = @w_dias_vencidos_op / 30

      if @w_meses_ven < 0
         select @w_meses_ven = 0
         
         

        
        --- DESCRIPCION TIPO GARANTIA 

         select @w_des_tipo_garantia = null

         select @w_des_tipo_garantia = tc_descripcion,
                @w_tipo_bien         = ''--tc_tipo_bien  AGI. 22ABR19.  Se comenta porque no existe el campo
         from   cob_custodia..cu_tipo_custodia
         where  tc_tipo = @w_tipo_garantia
 
         ---DESCRIPCION TIPO BIEN 

         if @w_tipo_bien is not null begin 
 
            select @w_des_tipo_bien = null
            select @w_des_tipo_bien = valor 
            from   cobis..cl_catalogo
            where  tabla in (select codigo
                   from cobis..cl_tabla
                   where tabla = 'cu_tipo_bien')
            and codigo = @w_tipo_bien
            set transaction isolation level read uncommitted
         end

         ---DESCRIPCION CLASE GARANTIA  
         select @w_des_clase_garantia = null

         select @w_des_clase_garantia = valor 
         from cobis..cl_catalogo
         where tabla in (select codigo
                         from cobis..cl_tabla
                        where tabla = 'cu_clase_custodia')
         and codigo = @w_clase_garantia
         set transaction isolation level read uncommitted

         --- CLIENTE PROPIETARIO DE LA GARANTIA 

         select @w_tipo_deudor = de_rol 
     	   from cob_credito..cr_deudores
    	   where de_cliente = @i_cliente
         and   de_tramite = @w_tramite

         select @w_ente_propietario_gar = cg_ente
         from   cob_custodia..cu_cliente_garantia
         where  cg_codigo_externo = @w_garantia
         and    cg_principal = 'D'

         --- FECHA AVALUO 
         select @w_fecha_avaluo  = max(in_fecha_insp)
         from   cob_custodia..cu_inspeccion 
         where  in_codigo_externo = @w_garantia
 

      select @w_propietario_gar = ''
      if @w_ente_propietario_gar = @i_cliente
	      select @w_propietario_gar = 'Si'
      else
         select @w_propietario_gar = 'No'

      select @w_detalle_ac  = ''
      if @w_abierta_cerrada = 'A'
         select @w_detalle_ac = 'ABIERTA'
      else
         select @w_detalle_ac = 'CERRADA'

      select @w_detalle_id  = ''
      if @w_determinada_indeter  = 'I'
         select @w_detalle_id = 'INDETERMINADA'
      else
         select @w_detalle_id = 'DETERMINADA'

      select @w_des_clase_garantia = rtrim(ltrim(@w_des_clase_garantia))
      select @w_detalle_garantia = @w_detalle_ac + ' ' +  @w_detalle_id + ' ' +  @w_des_clase_garantia

      --- DEFECTO GARANTIA 
      select @w_defecto_garantia = 0

      select @w_defecto_garantia = isnull(go_saldo,0) - isnull(go_cubierto,0)  
      from   cob_credito..cr_peso_rubro
      where  go_operacion = @w_operacion

      if @w_defecto_garantia < 0
         select @w_defecto_garantia = 0

       

      if @w_garantia is not null      
      begin

        ---INSERTAR INFORMACION DE GARANTIAS 
        select @w_tipo_garantia = @w_tipo_garantia +'-'+@w_des_tipo_garantia
        select @w_contador_gar = @w_contador_gar + 1
        insert into ca_detalles_garantia_deudor(
           dg_user,		             dg_cliente,		           dg_no_garantia,
           dg_tipo_garantia,         dg_propia,		              dg_valor,
           dg_valor_cobertura,	    dg_detalle,		           dg_defecto_garantia,
           dg_desc_tipo_garantia,    dg_desc_clase_garantia,     dg_desc_garantia,
           dg_fecha_avaluo,          dg_tramite, 		           dg_cobertura_garantias,  
           dg_porcentaje_cobertura,  dg_tipo_deudor,		        dg_estado,
	        dg_localizacion,          dg_secuencial)
        values(
           @s_user,		            @i_cliente,    		       ltrim(rtrim(@w_rol)) + '-' + @w_garantia,
           @w_tipo_garantia,	      @w_propietario_gar,	   	 @w_valor_garantia,
           @w_valor_cobertura,      @w_detalle_garantia,	       @w_defecto_garantia,
           @w_des_tipo_garantia,    @w_des_clase_garantia,  	 @w_descripcion_garantia,
           @w_fecha_avaluo,         @w_tramite,			          @w_cobertura_garantias,  
    	     @w_porcentaje_cobertura, @w_tipo_deudor,		       @w_estado,
	        @w_localizacion,         @w_contador_gar)

        if @@error <> 0 begin
	        select @w_error = 710397 
           return @w_error
         end
      end 
      fetch cursor_garantias into @w_garantia, @w_rol,@w_tramite,@w_operacion
    end

    close cursor_garantias
    deallocate cursor_garantias
 
return 0
go
     
