/************************************************************************/
/*  Archivo:                customer_infor_matriz.sp                    */
/*  Stored procedure:       sp_customer_infor_matriz                    */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jonatan Rueda                               */
/*  Fecha de Documentacion: 23/Abr/2019                                 */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP S.A.representantes exclusivos para el Ecuador de la       */
/*  AT&T                                                                */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante               */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  SP GENERADO POR EXTRACCION DE LA BB.DD. cob_credito                 */
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  23/04/19          LOGIN_DESA       Emision Inicial                  */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_customer_infor_matriz')
    drop proc sp_customer_infor_matriz
go

CREATE PROCEDURE sp_customer_infor_matriz (	
	@t_debug                     char(1) 	   = 'N',
	@t_file                      varchar(14)   = null,
	@t_from                      varchar(32)   = null,
	@t_show_version              bit           = 0,
	@s_rol                       smallint      = null,
	@i_operacion                 char(1)       = null,
	@i_ente              	     int           = null,
	@i_variable                  VARCHAR(25)   = NULL,
    @i_modo                      tinyint       = null, -- Modo de Insersion
	@i_nivel_obtenido            varchar(30)   = NULL,
	@i_puntaje_regla             INT           = NULL, 
    @i_suma_puntaje_total        INT           = NULL,
    @i_resultado_riesgo          VARCHAR(50)   = NULL,
    @i_resul_numero_env          varchar(30)   = NULL, 
    @i_resul_numero_rec          varchar(30)   = NULL, 
    @i_resul_monto_env           varchar(30)   = NULL, 
    @i_resul_monto_rec           varchar(30)   = NULL, 
    @i_resul_numero_dep_efec     varchar(30)   = NULL, 
    @i_resul_numero_dep_noefec   varchar(30)   = NULL, 
    @i_resul_monto_dep_efec      varchar(30)   = NULL, 
    @i_resul_monto_dep_noefec    varchar(30)   = NULL,
	@o_error_mens                varchar(255)  = null out
)
as 

DECLARE
    @w_sp_name           		varchar(32),
    @w_codigo            		int,
    @w_num_error         		int,
    @w_catalogo_cre_des_riesgo  int,
    @w_actividad_economica      varchar(200),
    @w_provincia                smallint,
    @w_cuidad                   int,
    @w_nacionalidad             varchar(64),
	@w_valor_variable_regla     varchar(250),
    @w_segmento                 varchar(10),
    @w_pep                      char(1),
    @w_origen_recursos_var      varchar(10),
    @w_origen_recursos          varchar(64),
    @w_destino_credito_var      varchar(10),
    @w_destino_credito          varchar(64),
    @w_producto                 varchar(64),
	@w_sub_producto             varchar(64),
	@w_trans_internacionales     varchar(250),
	@w_trans_internacionales_sum varchar(250),
    @w_trans_nacionales          varchar(250),
	@w_trans_nacionales_sum      varchar(250),
    @w_deposito	                 varchar(250),
	@w_deposito_sum              varchar(250),	
    @w_retiro	                 varchar(250),
	@w_retiro_sum                varchar(250),
    @w_cv_divisas                varchar(120),
    @w_cv_divisas_sum            varchar(120),
	@w_transaccionalidad_sum     varchar(120),
    @w_mensaje_fallo_regla       varchar(100),
	@w_ejecutar_regla            char(1) = 'S',
    @w_variables                 varchar(255),
    @w_result_values             varchar(255),
    @w_error                     int,
    @w_parent                    int,
    @w_nivel_obtenido            varchar(30),
    @w_resultado_riesgo          varchar(30),
	@w_resul_niv_riesgo          varchar(30),
	@w_resul_rango_calif         int,
	@w_resul_numero_env          varchar(30), 
    @w_resul_numero_rec          varchar(30), 
    @w_resul_monto_env           varchar(30), 
    @w_resul_monto_rec           varchar(30), 
    @w_resul_numero_dep_efec     varchar(30), 
    @w_resul_numero_dep_noefec   varchar(30), 
    @w_resul_monto_dep_efec      varchar(30), 
    @w_resul_monto_dep_noefec    varchar(30),
    @w_es_pep                    varchar(10) ,
    @w_puesto                    varchar(200),
    @w_msm_advertencia           varchar(200),
	@w_cli_a3ccc                 varchar(30),
    @w_cli_a3bloq				 varchar(30),
    @w_cli_condicionado          varchar(30),
	@w_msm_ea_nivel_riesgo       varchar(50)
    

/*  Inicializacion de Variables  */
select @w_sp_name = 'sp_customer_infor_matriz'

select @w_cli_a3ccc        = pa_char FROM cobis..cl_parametro WHERE pa_nemonico ='CA3CCC' AND pa_producto='CLI'
select @w_cli_a3bloq       = pa_char FROM cobis..cl_parametro WHERE pa_nemonico ='CA3BLO' AND pa_producto='CLI'
select @w_cli_condicionado = pa_char FROM cobis..cl_parametro WHERE pa_nemonico ='CLICON' AND pa_producto='CLI'

if @i_operacion = 'I'
BEGIN
    IF @i_modo ='1'
    BEGIN
    insert into cob_credito..cr_matriz_riesgo_cli ( mr_cliente, mr_variable, mr_nivel,mr_puntaje)
    values ( @i_ente, @i_variable,@i_nivel_obtenido, @i_puntaje_regla)
    END
    
    IF @i_modo ='2'
    BEGIN
        update cobis..cl_ente_aux
    	set    ea_nivel_riesgo   = @i_resultado_riesgo,
    	       ea_puntaje_riesgo = @i_suma_puntaje_total
        where  ea_ente = @i_ente
        
        --Verifico si el Cliente es un Cliente Condicionado por Matriz de Riesgo
        select @w_msm_ea_nivel_riesgo=ea_nivel_riesgo from cobis..cl_ente_aux where  ea_ente = @i_ente
        
        if(replace(@w_msm_ea_nivel_riesgo,' ','')=replace(@w_cli_a3ccc,' ','') or replace(@w_msm_ea_nivel_riesgo,' ','')=replace(@w_cli_a3bloq,' ',''))
            begin
		    exec cobis..sp_cliente_condicionado
		    @i_ente       =@i_ente
        
            end
        
        if exists(select 1 from cob_credito..cr_monto_num_riesgo where mnr_ente = @i_ente)
    	begin
    	    delete cob_credito..cr_monto_num_riesgo where mnr_ente = @i_ente
    	end
	    
	    insert into cob_credito..cr_monto_num_riesgo 
    	values (@i_ente,                    @i_resul_numero_env,                @i_resul_monto_env,                 @i_resul_numero_rec,
    	        @i_resul_monto_rec,         @i_resul_numero_dep_efec,           @i_resul_monto_dep_efec,	        @i_resul_numero_dep_noefec,
    	        @i_resul_monto_dep_noefec)
	
	    
    END
    
end

 
if @i_operacion = 'Q'
begin
    
	delete from cob_credito..cr_matriz_riesgo_cli where mr_cliente=@i_ente
    if exists (select 1 from cobis..cl_seccion_validar where sv_ente = @i_ente and sv_completado = 'N')
	begin
		select @w_ejecutar_regla = 'N'
		--select @o_error_mens = mensaje from cobis..cl_errores where numero = 103164
	end
    	select TOP 1 @w_actividad_economica = nc_actividad_ec 
        from   cobis..cl_ente, cobis..cl_negocio_cliente
        where  en_ente         = @i_ente
    	and    en_ente         = nc_ente
        and    nc_estado_reg   = 'V'
        
        
        if exists(select 1 from   cobis..cl_direccion where  di_tipo ='RE' and  di_ente = @i_ente) 
    begin
        select top 1 @w_provincia = di_provincia, 
                     @w_cuidad    = di_ciudad
        from   cobis..cl_direccion 
        where  di_tipo ='RE' 
        and    di_ente = @i_ente
     end
     else
     begin
        select top 1 @w_provincia = di_provincia, 
                     @w_cuidad    = di_ciudad
           from   cobis..cl_direccion 
           where  di_tipo ='AE' 
           and    di_ente = @i_ente
     end   
     
    select @w_sub_producto = p.pr_codigo_subproducto 
        from   cobis..cl_ente_aux e
        inner join cobis..cl_producto_santander p
        on e.ea_ente = p.pr_ente
        and e.ea_cta_banco = p.pr_numero_contrato
        and e.ea_ente = @i_ente
        
        select @w_pep = en_persona_pep 
    	from   cobis..cl_ente 
    	where  en_ente = @i_ente
    	if(@w_pep is null)
    	BEGIN
    	
            exec cob_credito..sp_valida_pep
                @i_ente=@i_ente,
                @o_es_pep = @w_es_pep OUTPUT,
                @o_puesto = @w_puesto OUTPUT
            	
                print 'Es PEP'+ convert(VARCHAR(10),@w_es_pep)
                print 'Puesto PEP'+ convert(VARCHAR(10),@w_puesto)
                
            update cobis..cl_ente set en_persona_pep=@w_es_pep, p_carg_pub=@w_puesto
            where en_ente=@i_ente
         
            SET @w_pep=@w_es_pep
    	END
    	
    	select TOP 1 @w_origen_recursos_var = nc_recurso, 
                     @w_origen_recursos   = valor 
    	from  cobis..cl_negocio_cliente, cobis..cl_tabla,cobis..cl_catalogo
        where cl_tabla.tabla in ('cl_recursos_credito') 
    	and   cl_tabla.codigo    = cl_catalogo.tabla 
    	and   cl_catalogo.codigo = nc_recurso 
        and   nc_estado_reg      = 'V' 
    	and   nc_ente            = @i_ente
    	
    	select TOP 1 @w_destino_credito_var = nc_destino_credito
        from  cobis..cl_negocio_cliente
        where nc_estado_reg      = 'V' 
    	and   nc_ente            = @i_ente 

SELECT 'Datos_Completos'=@w_ejecutar_regla,
       'Sub_Producto'=isnull(@w_sub_producto,'0025'),
       'Trans_Inter_Enviadas'='TRANSFERENCIAS INTERNACIONALES ENVIADAS|BAJO',
       'Trans_Inter_Recibidas'='TRANSFERENCIAS NACIONALES RECIBIDAS|BAJO',
       'Depositos_Efectivo'='DEPOSITOS EN EFECTIVO|BAJO',
       'Depositos_No_efectivo'='DEPOSITOS NO EFECTIVO|BAJO',
       'Activida_Economica'=@w_actividad_economica,
       'Entidad_Federativa'=convert(varchar, @w_provincia)+'|'+convert(varchar,@w_cuidad) ,
       'Nacionalidad'='MEXICANA',
       'Segmento'='INDIVIDUOS'+'|'+'PARTICULARES'+'|'+@w_sub_producto,
       'Producto'='Crédito Grupal',
       'PEP'=@w_pep,
       'Origen_Recursos'=@w_origen_recursos_var,
       'Destino_recursos'=@w_destino_credito_var,
       'Trans_Inter_Enviadas_NUMOPMES'='TRANSFERENCIAS INTERNACIONALES ENVIADAS|BAJO',
       'Trans_Inter_Recibidas_NUMOPMES'='TRANSFERENCIAS INTERNACIONALES RECIBIDAS|BAJO',
       'Trans_Nacio_Enviadas'='TRANSFERENCIAS NACIONALES ENVIADAS|BAJO',
       'Trans_Nacio_Recibidas'='TRANSFERENCIAS NACIONALES RECIBIDAS|BAJO',
       'Depositos_Efectivo_NUMOPMES'='DEPOSITOS EN EFECTIVO|BAJO',
       'Depositos_No_efectivo_NUMOPMES'='DEPOSITOS NO EFECTIVO|BAJO',
       'Retiros_Efectivo'='RETIROS EN EFECTIVO|BAJO',
       'Retiros_No_Efectivo'='RETIROS NO EFECTIVO|BAJO',
       'Compra_divisas'='COMPRA DE DIVISAS|BAJO',
       'Venta_Divisas'='VENTA DE DIVISAS|BAJO'
        FROM cobis..cl_ente 
        WHERE en_ente=@i_ente
	
	
end --Fin opcion I



return 0

ERROR:
    begin --Devolver mensaje de Error 
    exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = @w_error
    return @w_error
    end




GO

