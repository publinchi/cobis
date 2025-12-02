/************************************************************************/
/*   Archivo:             sp_desm_finagro.sp                             */
/*   Stored procedure:    sp_desm_finagro                                */
/*   Base de datos:       cob_cartera                                    */
/*   Producto:            Creditos Finagro                               */
/*   Disenado por:        Pedro A. Rojas                                 */
/*   Fecha de escritura:  Nov. 2014.                                     */
/*************************************************************************/
/*                              IMPORTANTE                               */
/*   Este  programa  es parte  de los  paquetes  bancarios  propiedad de */
/*   'MACOSA'.  El uso no autorizado de este programa queda expresamente */
/*   prohibido así como cualquier alteración o agregado hecho por alguno */
/*   alguno  de sus usuarios sin el debido consentimiento por escrito de */
/*   la Presidencia Ejecutiva de MACOSA o su representante.              */
/*************************************************************************/
/*                              PROPOSITO                                */
/*   Generar de forma automatica un archivo que contiene la informacion  */
/*   necesaria para comparar lo enviado por FINAGRO Vs COBIS, desde batch*/
/*************************************************************************/
use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_desm_finagro')
   drop proc sp_desm_finagro
go


create proc sp_desm_finagro
   @i_param1  datetime
as

declare

   @w_error                int,
   @w_sp_name              varchar(64),
   @w_msg                  varchar(255),
   @w_s_app                varchar(50),
   @w_comando			   varchar(255),
   @w_fecha                datetime,
   @w_nombre_archivo 	   varchar(255),   
   @w_path                 varchar(60),
   @w_concepto             varchar(20),
   @w_porcentaje_garantia  float,
   @w_tramite              int,
   @w_cabecera             varchar(50)
    
   --CARGA DE VARIABLES DE TRABAJO
   
   select @w_sp_name = 'sp_desm_finagro'
   
   select @w_fecha = @i_param1

   select @w_nombre_archivo = pa_char
   from cobis..cl_parametro
   where pa_nemonico = 'FNGRAR'
   
   if @@rowcount = 0 begin
      select 
      @w_error = 214941,
      @w_msg = 'ERROR AL OBTENER EL PARAMETRO DE NOMBRE DEL ARCHIVO'
      goto ERROR_FIN
   end

   select @w_s_app = pa_char
   from   cobis..cl_parametro
   where  pa_nemonico = 'S_APP'

   if @@rowcount = 0 begin
      select 
      @w_error = 214942,  
      @w_msg = 'ERROR AL OBTENER EL PARAMETRO: S_APP'
      goto ERROR_FIN
   end
    
   select @w_path = pp_path_destino
   from  cobis..ba_path_pro
   where pp_producto = 7
   
   if @@rowcount = 0 begin
      select 
      @w_error = 214943,
      @w_msg = 'ERROR AL OBTENER EL PARAMETRO PATH DESTINO DE FINAGRO'
      goto ERROR_FIN
   end

   select @w_concepto = pa_char
   from cobis..cl_parametro
   where pa_nemonico = 'CMFAGD'
   
   if @@rowcount = 0 begin
      select 
      @w_error = 214944,
      @w_msg = 'ERROR AL OBTENER EL PARAMETRO DE CONCEPTO DEL CREDITO'
      goto ERROR_FIN
   end
   
   /* CREA LA TABLA TEMPORAL DONDE SE EXPORTARA PARA EL ARCHIVO
      DATOS DE AHORROS */
      
   create table #info_finagro(
         id_cliente        varchar(16) ,nom_cliente       varchar(50) ,fec_desembolso    datetime,
         val_desembolso    money       ,porcentaje_comis  float       ,porcentaje_garantias float,
         tramite           int         ,val_comision      money       ,num_obligacion    varchar(20)
   )
   
   insert into #info_finagro
   select en_ced_ruc    ,op_nombre     ,op_fecha_liq,
          op_monto      ,ro_porcentaje ,0.00,
          op_tramite    ,ro_valor      ,op_banco      
   from   cob_cartera..ca_rubro_op, cob_cartera..ca_operacion, cob_cartera..ca_estado, cobis..cl_ente
   where  op_estado = es_codigo
   and    op_fecha_liq = @w_fecha
   and    es_procesa   = 'S'
   and    op_toperacion in(select c.codigo from cob_credito..cr_corresp_sib s, cobis..cl_tabla t, cobis..cl_catalogo c  
                           where s.descripcion_sib = t.tabla
                           and t.codigo            = c.tabla
                           and s.tabla             = 'T301'
                           and c.estado            = 'V')
   and    ro_operacion = op_operacion
   and    ro_concepto = @w_concepto
   and    en_ente = op_cliente

   if @@rowcount = 0
   begin
      goto NOREG
   end
   
   --Extrae el tipo y el porcentaje de la garantia
   select porcentaje_garantia = gp_porcentaje,
          tramite             = gp_tramite
   into #garfag
   from cob_custodia..cu_custodia,cob_credito..cr_gar_propuesta, cob_custodia..cu_tipo_custodia
   where cu_codigo_externo = gp_garantia
   and tc_tipo             = cu_tipo
   and tc_tipo_superior    = 2100
   and gp_tramite          in (select tramite from #info_finagro)
      
   --Actualizando tabla temporal con el porcentaje de la garantia
   update #info_finagro
   set porcentaje_garantias = a.porcentaje_garantia
   from #garfag a, #info_finagro b
   where b.tramite = a.tramite

   --ELIMINA SI EXISTE LA TABLA TEMPORAL LA CUAL CONTENDRA LA INFOMACION A EXPORTAR
   if exists (select 1 from sysobjects where name = 'info_finagro_archivo')
      drop table info_finagro_archivo
	  
   --CREA LA TABLA QUE CONTENDRA LA INFORMACION A EXPORTAR 
   create table info_finagro_archivo(
      finagro_descripcion   varchar(2000)
   )
   
   --INSERTA EL ENCABEZADO DEL ARCHIVO
   insert into info_finagro_archivo
   select 'IDENTIFICACION DEL CLIENTE|NOMBRE DEL CLIENTE|FECHA DE DESEMBOLSO|VALOR DESEMBOLSADO|PORCENTAJE DE COMISION|PORCENTAJE DE COBERTURA DE LA GARANTIA|VALOR DE LA COMISION|No DE LA OBLIGACION'
   
   --INSERTA EL DETALLE DEL ARCHIVO
   insert into info_finagro_archivo
   select convert(varchar,id_cliente)          + '|' +
          convert(varchar,nom_cliente)         + '|' +
          convert(varchar,fec_desembolso,103)  + '|' +
          convert(varchar,val_desembolso)      + '|' +
          convert(varchar,porcentaje_comis)    + '|' +
          convert(varchar,porcentaje_garantias)+ '|' +
          convert(varchar,val_comision)        + '|' +
          rtrim(convert(varchar,num_obligacion))
   from   #info_finagro

   --CREA EL NOMBRE DEL ARCHIVO
   select @w_nombre_archivo = @w_nombre_archivo + '_' + convert(varchar(2), day(@w_fecha)) + '-' + convert(varchar(2), month(@w_fecha)) + '-' + convert(varchar(4), year(@w_fecha)) + '.txt'
             
   --CREA EL COMANDO PARA EXPORTAR LA TABLA TEMPORAL
   select @w_comando = @w_s_app + 's_app'+ ' bcp -auto -login cob_cartera..info_finagro_archivo out ' + 
                       @w_path  + @w_nombre_archivo +
                       ' -c -e'+'ERROR_AL_GENERAR_EL_ARCHIVO.err' + ' -t"|" ' + '-config ' + @w_s_app + 's_app.ini'
         
   --EJECUTAR CON CMDSHELL
   exec @w_error = xp_cmdshell @w_comando
         
   --CONTROL DE ERROR
   if @w_error <> 0 begin
      select 
      @w_error = 214945,  
      @w_msg = 'ERROR AL CREAR EL ARCHIVO PARA: ' + @w_nombre_archivo
      goto ERROR_FIN
   end
   
   return 0
  
  NOREG:
   -----------------------------------------------------------------------------------------------------
   --SE GENERA EL ARCHIVO .lis CUANDO NO EXISTEN REGISTROS PARA PROCESAR
   -----------------------------------------------------------------------------------------------------		   	     								   
   select @w_nombre_archivo = @w_nombre_archivo + '_' + convert(varchar(2), day(@w_fecha)) + '-' + convert(varchar(2), month(@w_fecha)) + '-' + convert(varchar(4), year(@w_fecha)) + '.lis'
   
   select @w_cabecera = 'No existen registros para procesar'       
   
   --Escribir Cabecera
   select @w_comando = 'echo ' + @w_cabecera + ' > ' + @w_path  + @w_nombre_archivo

   exec @w_error = xp_cmdshell @w_comando

   if @w_error <> 0 
   begin
      select @w_error    = 2902797, 
             @w_msg  = 'EJECUCION comando bcp FALLIDA. REVISAR ARCHIVOS DE LOG GENERADOS.'
      goto ERROR_FIN
   end
   return 0  --FIN NOREG
 
   ERROR_FIN:
   print @w_error
   exec cob_credito..sp_errorlog
   @i_fecha      = @w_fecha,
   @i_error      = @w_error,
   @i_usuario    = 'opbatch',
   @i_tran       = 21494,
   @i_tran_name  = @w_sp_name,
   @i_rollback   = 'N'

go