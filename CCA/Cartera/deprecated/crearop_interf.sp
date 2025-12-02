/******************************************************************/
/*  Archivo:            crearop_interf.sp                         */
/*  Stored procedure:   sp_interf_crear_operacion_srv             */
/*  Base de datos:      cob_cartera                               */
/*  Producto:           Cartera                                   */
/*  Disenado por:       Lorena Regalado                           */
/*  Fecha de escritura: 12-Jun-2019                               */
/******************************************************************/
/*                        IMPORTANTE                              */
/*  Este programa es parte de los paquetes bancarios propiedad de */
/*  'COBISCORP', representantes exclusivos para el Ecuador de la  */
/*  'NCR CORPORATION'.                                            */
/*  Su uso no autorizado queda expresamente prohibido asi como    */
/*  cualquier alteracion o agregado hecho por alguno de sus       */
/*  usuarios sin el debido consentimiento por escrito de la       */
/*  Presidencia Ejecutiva de MACOSA o su representante.           */
/******************************************************************/
/*                                 PROPOSITO                      */
/*   Este programa permite:                                       */
/*   - Interface de Creacion de Operaciones                       */
/******************************************************************/
/*                        MODIFICACIONES                          */
/*  FECHA              AUTOR            RAZON                     */
/*  12/Jun/19        Lorena Regalado    Valida y crea operacion   */
/*                                      grupal                    */
/*  22/Jul/19        Adriana Giler      Validacion Incentivos     */
/*  06/Ago/19        Lorena Regalado    Se descomenta control     */
/*  27/10/19         Jose Calvillo      Rol desertor se valida    */
/******************************************************************/
use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_interf_crear_operacion_srv')
   drop proc sp_interf_crear_operacion_srv
go

create proc sp_interf_crear_operacion_srv
   @s_srv              varchar(30)    = null,
   @s_lsrv             varchar(30)    = null,
   @s_ssn              int            ,
   @s_rol              int            = null,
   @s_org              char(1)        = null,
   @s_user             login  ,
   @s_term             varchar(30)    = null,
   @s_date             datetime  ,
   @s_ofi              smallint ,
   @t_trn              int            = 7468,
   @t_debug            char(1)        = null,
   @t_file             varchar(30)    = null,
   @i_secuencial       int,             --Secuencial de referencia con el que se grabo la informacion en tablas temporales
   @o_banco            cuenta         out,
   @o_error            int            out,
   @o_mensaje_error    varchar(500)   out

as declare
   @w_sp_name              varchar(30),
   @w_error                int,
   @w_return               int,
   @w_tipo_operacion       varchar(10),
   @w_oficina              smallint,
   @w_toperacion           varchar(10),
   @w_destino              varchar(10),
   @w_fecha_desemb         datetime,
   @w_moneda               tinyint,
   @w_monto                money,
   @w_plazo                smallint,
   @w_frecuencia           varchar(10),
   @w_tasa                 float,
   @w_fecha_primer_pago    datetime,
   @w_fecha_ppago          datetime,
   @w_otros                varchar(255),
   @w_grupo                int,
   @w_monto_ahorro         money,
   @w_codeudor             int,
   @w_oficial              smallint,
   @w_monto_hijas          money,
   @w_operacion            int,
   @w_banco                cuenta,
   @w_banco_gr             cuenta,
   @w_tramite              int,
   @w_ciclo                int,
   @w_msg                  varchar(64),
   @w_mensaje              varchar(500),
   @w_fecha_creacion       VARCHAR(10),
   @w_commit               char(1),
   @w_presi_grp            int,
   @w_cuenta_gr            cuenta,
   @w_tipo                 char(1),
   @w_subtipo              char(1),
   @w_cliente              int,
   @w_cliente_op           int, 
   @w_tdividendo           catalogo,
   @w_forma_pago           catalogo,
   @w_es_interciclo        char(1),
   @w_operacion_grp        int,
   @w_monto_odp            money,
   @w_tretiro_odp          catalogo,
   @w_banco_odp            catalogo,
   @w_lote_odp             int,
   @w_odp_generada         varchar(20),
   @w_convenio             varchar(10),    
   @w_fecha_odp            datetime,          
   @w_secuencia_odp        int,
   @s_sesn                 int,
   @w_fecha_vig            datetime,
   @w_clase_car            catalogo,   
   @w_mensaje_err          varchar(500),
   @w_ciudad               int,
   @w_cuenta               cuenta,
   @w_grupal               char(1)
    


select @w_commit = 'N',
       @w_es_interciclo = 'N',
       @s_sesn          = @s_ssn



--Consultar los datos de la operacion temporal
select @w_tipo_operacion = iot_tipo_operacion,
       @w_oficina        = iot_oficina,
       @w_toperacion     = iot_toperacion,
       @w_clase_car      = (select dt_clase_sector from cob_cartera..ca_default_toperacion
                            where dt_toperacion = x.iot_toperacion and dt_moneda = x.iot_moneda),
       @w_destino        = iot_destino,
       @w_fecha_desemb   = iot_fecha_desemb,
       @w_moneda         = iot_moneda,
       @w_monto          = iot_monto,
       @w_plazo          = iot_plazo,
       @w_frecuencia     = iot_frecuencia,
       @w_tasa           = iot_tasa,
       @w_fecha_primer_pago = iot_fecha_primer_pago,
       @w_otros          = iot_otros,
       @w_grupo          = iot_grupo,
       @w_monto_ahorro   = iot_monto_ahorro,
       @w_codeudor       = iot_codeudor,
       @w_oficial        = iot_oficial,
       @w_banco          = iot_banco,    --Interciclo
       @w_cliente        = iot_cliente,   --Interciclo
       @w_operacion_grp  = (select op_operacion from cob_cartera..ca_operacion where op_banco = x.iot_banco)
from cob_cartera..ca_interf_op_tmp x
where iot_sesn = @i_secuencial

if @@rowcount = 0
begin
       select @w_error = 725002
       goto ERROR
end

select @s_ofi = @w_oficina

-----------------------------------------------------
--Verificar el rol
-----------------------------------------------------

 if exists (select 1 from cobis..cl_cliente_grupo
              where  @w_grupo = cg_grupo
		      and    @w_cliente =cg_ente
              and    cg_rol='D')

   begin
       		select @w_mensaje = 'Error, no se puede crear una operacion con miembro desertor'
       		select @w_error = 725030
       		goto ERROR
	end 

-----------------------------------------------------
--CONTROLAR QUE NO SE CREE LA OPERACION BAJO CIERTOS
-----------------------------------------------------

if exists (select 1 from cob_cartera..ca_interf_op_tmp
           where iot_fecha_proceso = @s_date
            and  iot_fecha_desemb  = @w_fecha_desemb 
            and  iot_grupo         = @w_grupo
            and  iot_operacion is not null)
begin



	if exists (select 1 from cob_cartera..ca_operacion x
           where op_grupal         = 'S'
            and  op_admin_individual = 'N'
            and  op_fecha_ini      = @w_fecha_desemb 
            and  op_grupo          = @w_grupo
            and  op_monto          = @w_monto
            and  op_estado not in (6)  --Anulada
            and  op_ref_grupal     is null)
	begin
       		print 'Error, ya existe una operacion creada con los datos ingresados de Fecha de Proceso/Fecha de desembolso/Grupo'
       		select @w_mensaje = 'Error, ya existe una operacion creada con los datos ingresados de Fecha de Proceso/Fecha de desembolso/Grupo'
       		select @w_error = 725029
       		goto ERROR
	end 

end

--Para operaciones de Interciclo	
if (@w_banco is not NULL and @w_cliente is not null )  
begin

   select @w_es_interciclo = 'S'
   
   --Obtiene el plazo y grupo de la operacion grupal (padre)
   select @w_frecuencia = op_tdividendo,
          @w_grupo      = op_grupo,
          @w_cuenta     = op_cuenta,
          @w_ciudad     = op_ciudad
   from cob_cartera..ca_operacion 
   where op_banco = @w_banco
   
   if @@rowcount = 0
   begin
       --print 'Operacion Grupal no esta activa o no Existe'
       select @w_error = 710022
       goto ERROR
   end
   
   --select  @w_grupal  = 'N'
   
end

BEGIN TRAN

select @w_commit = 'S'

-----------------------------------   
--EJECUCION DE PROCESOS VALIDADORES
-----------------------------------

execute @w_error = sp_valida_datos
@i_secuencial = @i_secuencial,
@s_sesn       = @s_sesn,     
@s_ssn        = @s_ssn,
@s_user       = @s_user,
@s_term       = @s_term,
@s_date       = @s_date,
@i_banco      = @w_banco,
@i_es_interciclo = @w_es_interciclo,
@o_fecha_primer_pago = @w_fecha_ppago out,  --solo para operaciones de interciclo   
@o_mensaje_error     = @w_mensaje_err out 



if @w_error <> 0 
begin
   --select @w_mensaje = 'Error, en los procesos validadores de la informacion en temporales'   
   select @w_mensaje = @w_mensaje_err  
   goto ERROR
end




-- Operaciones de Interciclo	
if @w_es_interciclo = 'S' 
begin

   if @w_fecha_ppago is NULL
    begin

      select @w_error = 725051
      select @w_mensaje = 'Error, No se pudo encontrar Fecha de Primer Pago para Operacion Interciclo'   
      goto ERROR
   end 

   --print 'Operacion Interciclo Cliente: ' + cast(@w_cliente as varchar) + 'Op. Grupal: ' + @w_banco
   select @w_cliente_op        = @w_cliente,
          @w_fecha_primer_pago = @w_fecha_ppago
end
else
begin

--print 'Para operaciones grupales'

     --Consulta de Datos del Presidente del Grupo
     select @w_presi_grp = cg_ente
     from cobis..cl_grupo, cobis..cl_cliente_grupo 
     where gr_grupo = @w_grupo
      and   gr_tipo  = 'S'
      and   gr_grupo = cg_grupo
      and   cg_rol = 'P'

     if @@rowcount = 0
     begin
        select @w_error = 725028
        select @w_mensaje = 'Error, al consultar al Cliente con rol de Presidente'   
        goto ERROR
     end
	 
	 select @w_cliente_op = @w_presi_grp
end


------------------------------------
--ENVIAR A CREAR OPERACION GRUPAL
------------------------------------


--BEGIN TRAN

--select @w_commit = 'S'

if @w_tipo_operacion = 'IN'
   select @w_tipo = 'O'
else
   if @w_tipo_operacion in ('RE')
      select @w_tipo = 'R',
	         @w_subtipo = 'N' 
	else
	if @w_tipo_operacion in ('RF')
      select @w_tipo = 'R',
	         @w_subtipo = 'F' 
			 


exec @w_return = sp_crear_oper_sol_wf    
     @s_srv              = @s_srv,    
     @s_ssn              = @s_ssn, 
     @s_lsrv             = @s_lsrv,      
     @s_user             = @s_user,     
     @s_term             = @s_term,     
     @s_date             = @s_date,     
     @s_sesn             = @s_sesn,     
     @s_ofi              = @s_ofi,      
     @t_debug            = 'N',    
     @i_cliente          = @w_cliente_op,    
     @i_toperacion       = @w_toperacion, 
     @i_oficina          = @w_oficina,    
     @i_moneda           = @w_moneda,         
     @i_oficial          = @w_oficial,     
     @i_fecha_ini        = @w_fecha_desemb, 
     @i_monto            = @w_monto, 
     @i_monto_aprobado   = @w_monto,     
     @i_destino          = @w_destino, 
     @i_ciudad           = @w_oficina,            
     @i_clase_cartera    = @w_clase_car,         
     @i_fondos_propios   = 'S',    
     @i_grupal           = 'S', 
     @i_es_grupal        = 'S', 	 
     @i_plazo            = @w_plazo,    
     @i_tplazo           = @w_frecuencia,     
     @i_tdividendo       = @w_frecuencia,    
     @i_grupo            = @w_grupo,           
     @i_fecha_ven_pc     = @w_fecha_primer_pago, 
     @i_tasa_grupal      = @w_tasa,          
     @i_en_linea         = 'N', 
     @i_tipo             = @w_tipo,
     @i_subtipo          = @w_subtipo, 
     @i_es_interciclo    = @w_es_interciclo,
     @i_ref_grupal       = @w_banco,         --Numero Banco que viene de la interface asociado a la Operacion de Interciclo
     @o_banco            = @w_banco_gr  out, --Nuevo Numero Banco que genera el proceso    
     @o_operacion        = @w_operacion out,    
     @o_tramite          = @w_tramite   out,    
     @o_oficina          = @w_oficina   out,    
     @o_msg              = @w_msg       out,    
     @o_ciclo            = @w_ciclo     out,    
     @o_fecha_creacion   = @w_fecha_creacion   OUT


if @w_return <> 0 
begin
    --select @w_error = 725027
    select @w_error = @w_return
    select @w_mensaje = 'Error al Crear Operacion Grupal desde Interface Error:  '  + cast(@w_return as varchar)
    goto ERROR  
end

-----------------------------------------------------------------------------------------
--GENERA INFORMACION DE SEGUROS/BENEFICIARIOS/ORDEN DE PAGO PARA OPERACION DE INTERCICLO
-----------------------------------------------------------------------------------------
if @w_es_interciclo = 'S'
begin

      --GUARDA SEGUROS Y BENEFICIARIOS EN TABLAS DEFINITIVAS
       exec @w_error =  sp_seguros_grp
             @s_user              = @s_user,
             @s_sesn              = @s_sesn,
             @s_ssn               = @s_ssn,
             @s_ofi               = @s_ofi ,
             @s_date              = @s_date,
             @s_term              = @s_term,
             @i_opcion            = 'I',
             @i_cliente           = @w_cliente,       
             @i_oper_padre        = @w_operacion_grp,
             @i_oper_hija         = @w_operacion,  --Operacion interciclo
             @i_sesion            = @i_secuencial,
             @o_mensaje           = @w_mensaje out
             
        if @w_error != 0 
        begin
            select @w_mensaje = 'Error al Generar Seguros y Beneficiarios:  '  + cast(@w_error as varchar)
            --select @w_error = 725037
            goto ERROR  
        end

        select @w_monto_odp = iot_monto_desembolso,
               @w_tretiro_odp = case when iot_tipo_orden = 'I' then 'ODI'
                               else 'ODP'
                               end,
               @w_banco_odp  =  case when iot_tipo_orden = 'I' then null
                               else (select ba_codigo from cob_bancos..ba_banco
                                     where ba_codigo = iot_banco  )
                               end,       
               @w_lote_odp   = iot_lote
        from ca_interf_ordenp_tmp
        where iot_sesn      = @i_secuencial
         and  iot_cliente   = @w_cliente

        --REGISTRA LA ORDEN DE PAGO PARA LA OPERACION INTERCICLO        
        exec @w_error =  cobis..sp_dispersion_retiro
            @t_trn                    = 2213,
            @s_user                   = @s_user,
            @s_ssn                    = @s_ssn,
            @s_date                   = @s_date,
	    @s_ofi                    = @s_ofi, 
            @i_operacion              =  "I" ,               -- INSERCION DE FORMAS DE RETIRO
            @i_grupo                  = @w_grupo,            -- CODIGO DEL GRUPO SOLIDARIO
            @i_cliente                = @w_cliente,          -- CODIGO DEL CLIENTE INDIVIDUAL
            @i_car_operacion          = @w_operacion,        -- CODIGO INTERNO DE LA OPERACION DE CARTERA
            @i_forma_retiro           = @w_tretiro_odp,      -- FORMA DE RETIRO SELECCIONADA PARA EL CLIENTE. TIENE SOLO DOS OPCIONES = "ODI", "ODP"   (Retiro por Caja o por Banco corresponsal)
            @i_monto                  = @w_monto_odp,        -- MONTO DEFINIDO DEL RETIRO PARA EL CLIENTE
            @i_fecha_apl              = @s_date,             -- FECHA PROCESO
            @i_banco                  = @w_banco_odp,        -- SI LA FORMA ES "ODP" ENTONCES INDICAR EL CODIGO DEL BANCO CORRESPONSAL = cob_bancos..ba_banco.ba_codigo
            @i_lote                   = @w_lote_odp          -- CODIGO DE LOTE ENVIADO POR CAME PARA CON ESTE CODIGO CONSULTAR LUEGO LAS ODP'S)

        
        if @w_error != 0 
        begin
            select @w_mensaje = 'Error al Generar Orden de Pago:  '  + cast(@w_error as varchar)
            goto ERROR  

        end
        
     -- Insertar el tramite Grupal'
        insert cob_credito..cr_tramite_grupal
			   (tg_tramite,             tg_grupo,           tg_cliente,         tg_monto,       
                	    tg_grupal,              tg_operacion,       tg_prestamo,        tg_referencia_grupal,       
                	    tg_participa_ciclo,     tg_monto_aprobado,  tg_ahorro)
        values (                         
			    @w_tramite,         @w_grupo,           @w_cliente,         @w_monto,       
               		    'S',                @w_operacion,       @w_banco_gr,        @w_banco,                  
               		    'N',                @w_monto,           0)
			   	                   
        if @@error <> 0
        begin
            --print 'ERROR AL REGISTRAR CR_TRAMITE_GRUPAL' 
            select @w_mensaje = 'Error al Grabar en cr_tramite_grupal' 
            select @w_error =2103001
            goto ERROR  
        end


end




----------------------------------------------------------------
--ACTUALIZAR TABLAS TEMPORALES CON NUNERO DE OPERACION GENERADA
----------------------------------------------------------------


if (@w_banco_gr is not null and @w_operacion is not null)
begin
     --Crear Cuenta Grupal
     execute @w_return = cob_ahorros..sp_actcta_grupo
      @s_ssn      = @s_ssn,
      @s_lsrv     = @s_lsrv, 
      @s_srv      = @s_srv, 
      @s_user     = @s_user, 
      @s_date     = @s_date,
      @s_ofi      = @s_ofi,
      @s_rol      = @s_rol,
      @s_org      = @s_org,
      @t_trn      = 4187, 
      @i_grupo    = @w_grupo,
      @s_term     = 'TERM1',
      @i_cuenta   =  null, 
      @i_titular  = @w_presi_grp,  
      @i_cotitular  = null, 
      @i_beneficiario  = null, 
      @i_monto_ahorro_base = @w_monto_ahorro,  
      @o_cuenta_grupo      = @w_cuenta_gr out 

    if @w_return <> 0 
    begin
        select @w_error = @w_return --725027
        select @w_mensaje = 'Error al Crear Operacion Grupal desde Interface Error:  '  + cast(@w_return as varchar)
        goto ERROR  
    end


     update cob_cartera..ca_interf_op_tmp set iot_operacion = @w_operacion,
                                              iot_ctaho_grupal = @w_cuenta_gr
                                              
     from cob_cartera..ca_interf_op_tmp
     where iot_sesn  = @i_secuencial

     if @@error <> 0
     begin 
        select @w_error = 725026
        select @w_mensaje = 'Error al actualizar la Operacion en Tabla Temporal de Operaciones' 
        goto ERROR
     end 

     update cob_cartera..ca_interf_hijas_tmp set iht_operacion = @w_operacion
     from cob_cartera..ca_interf_hijas_tmp
     where iht_sesn  = @i_secuencial

     if @@error <> 0
     begin 
        select @w_error = 725026
        select @w_mensaje = 'Error al actualizar la Operacion en Tabla Temporal de Operaciones Hijas' 
        goto ERROR
     end


     update cob_cartera..ca_interf_seguros_tmp set ist_operacion = @w_operacion
     from cob_cartera..ca_interf_seguros_tmp
     where ist_sesn  = @i_secuencial

     if @@error <> 0
     begin 
        select @w_error = 725026
        select @w_mensaje = 'Error al actualizar la Operacion en Tabla Temporal de Seguros' 
        goto ERROR
     end


     update cob_cartera..ca_interf_benef_tmp set ibt_operacion = @w_operacion
     from cob_cartera..ca_interf_benef_tmp
     where ibt_sesn  = @i_secuencial

     if @@error <> 0
     begin 
        select @w_error = 725026
        select @w_mensaje = 'Error al actualizar la Operacion en Tabla Temporal de Beneficiarios' 
        goto ERROR
     end

     update cob_cartera..ca_interf_ordenp_tmp set iot_operacion = @w_operacion
     from cob_cartera..ca_interf_ordenp_tmp
     where iot_sesn  = @i_secuencial

     if @@error <> 0
     begin 
        select @w_error = 725026
        select @w_mensaje = 'Error al actualizar la Operacion en Tabla Temporal de Ordenes de Pago' 
        goto ERROR
     end

      --INI AGI 22JUL19 --Actualizar Incentivos Temporal
     update ca_interf_incentivo_tmp
     set  iic_operacion  = @w_operacion
     where iic_sesn  = @i_secuencial
     
     if @@error <> 0
     begin 
        select @w_error = 725026
        select @w_mensaje = 'Error al actualizar la Operacion en Tabla Temporal Incentivos' 
        goto ERROR
     end
     
     --INI AGI 22JUL19 --Insertar Incentivos en Tabla Fija
     if @w_es_interciclo = 'N'
     begin 
        exec @w_error =  sp_incentivos_grp
             @s_srv               = @s_srv,
             @s_user              = @s_user,
             @s_sesn              = @s_sesn,
             @s_ssn               = @s_ssn,
             @s_ofi               = @s_ofi ,
             @s_date              = @s_date,
             @s_term              = @s_term,
             @i_opcion            = 'I',
             @i_operacion         = @w_operacion,
             @i_sesion            = @i_secuencial,     
             @o_mensaje           = @w_mensaje out
             
        if @w_error != 0 
        begin
            --print 'ERROR INSERTANDO INCENTIVO DE CREDITO' + cast (@w_error as varchar)
            select @w_mensaje = 'Error insertando Incentivo de Credito:  '  + cast(@w_error as varchar)
            select @w_error = 725061
            goto ERROR  
        end
     end
     --FIN AGI
     
     if @w_es_interciclo = 'S'
     begin
           update cob_cartera..ca_operacion set op_estado_hijas = 'P', op_cuenta = @w_cuenta, op_admin_individual = 'S',
            op_grupal = 'N', op_ciudad = @w_ciudad
           where op_operacion = @w_operacion
     end
     else
     begin
          update cob_cartera..ca_operacion set op_cuenta = @w_cuenta_gr --op_forma_pago = @w_forma_pago
           where op_operacion = @w_operacion
     end
 

 
end 

COMMIT TRAN

    select @o_banco = @w_banco_gr,
           @o_error = @w_error,
           @o_mensaje_error  = @w_mensaje

return 0

ERROR:

   if @w_commit = 'S'
   begin
        while @@trancount > 0 ROLLBACK TRAN

    select @o_banco = @w_banco,
           @o_error = @w_error,
           @o_mensaje_error  = @w_mensaje


        exec cobis..sp_cerror
        @t_debug  ='N',
        @t_file   = null,
        @t_from   = @w_sp_name,
        @i_num    = @w_error,
        @i_msg    = @w_mensaje, --'Error en Proceso de Creacion de Operacion Interface', 
        @i_sev    = 0
   
        return @w_error

   end
   else      
   begin 

    select @o_banco = @w_banco,
           @o_error = @w_error,
           @o_mensaje_error  = @w_mensaje


    	exec cobis..sp_cerror
    	@t_debug  ='N',
    	@t_file   = null,
    	@t_from   = @w_sp_name,
    	@i_num    = @w_error,
        @i_msg    = @w_mensaje,
    	@i_sev    = 0
   
   	return @w_error
   end    
go

