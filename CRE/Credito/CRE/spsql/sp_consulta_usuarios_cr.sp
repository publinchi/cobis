/**************************************************************************/
/*  Archivo:                    sp_consulta_usuarios_cr.sp                */
/*  Stored procedure:           sp_consulta_usuarios_cr                   */
/*  Base de Datos:              cob_credito                               */
/*  Producto:                   Credito                                   */
/**************************************************************************/
/*                     IMPORTANTE                                         */
/*   Este programa es parte de los paquetes bancarios que son             */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,        */
/*   representantes exclusivos para comercializar los productos y         */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida       */
/*   y regida por las Leyes de la República de España y las               */
/*   correspondientes de la Unión Europea. Su copia, reproducción,        */
/*   alteración en cualquier sentido, ingeniería reversa,                 */
/*   almacenamiento o cualquier uso no autorizado por cualquiera          */
/*   de los usuarios o personas que hayan accedido al presente            */
/*   sitio, queda expresamente prohibido; sin el debido                   */
/*   consentimiento por escrito, de parte de los representantes de        */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto        */
/*   en el presente texto, causará violaciones relacionadas con la        */
/*   propiedad intelectual y la confidencialidad de la información        */
/*   tratada; y por lo tanto, derivará en acciones legales civiles        */
/*   y penales en contra del infractor según corresponda.”.               */
/**************************************************************************/
/*                          PROPOSITO                                     */
/*  Este stored procedure permite obtener participantes de una solicitud  */
/*                                                                        */
/**************************************************************************/
/*                        MODIFICACIONES                                  */
/*  FECHA          AUTOR                            RAZON                 */
/*  09/Nov/2021   Dilan Morales         implementacion                    */
/*  23/Dic/2021   Dilan Morales         Cambios para controlar            */
/*                                      consultas repetidas               */
/*  25/Abr/2022   Dilan Morales         Se añade validacion -1            */
/*  25/Abr/2022   Dilan Morales         Se corrige espacios en nombres    */
/*                                      y apellidos                       */
/*  31/May/2022   Dilan Morales         Se quita insert de representante  */
/*                                      legal en gruapales y se valida    */
/*                                      usuario                           */
/*  17/Jun/2022   Dilan Morales         Se corrige obtencion del @s_user  */
/*  06/Sep/2022   Dilan Morales         Se elimina else if para admita    */
/*                                      otro tipo de solicitudes          */
/*  17/Nov/2022   Dilan Morales         S735105:Se comenta inserts para   */
/*                                      consulta de participantes         */
/*  24/Nov/2022   Dilan Morales         S736966: Se adapta consulta para  */
/*                                      grupales                          */
/*  20/Jun/2023  Dilan Morales          Se valida sin instancia proceso   */
/*  23/Jun/2023  Dilan Morales          Se copia registro para nueva      */
/*                                      instancia proceso                 */
/*  18/Jul/2023  Bruno Dueñas           Se limita registros en insert     */
/*  27/Jul/2023  Dilan Morales          Mejoras para evitar deadlocks     */
/*  02/Ago/2023  Dilan Morales          Se corrige logica para que        */
/*                                      primero valide datos del ente     */
/*  09/Nov/2023  Dilan/Bruno            R219120 Se valida duplicidad LN   */
/*  13/Nov/2023  Dilan/Bruno            R219120 Validacion duplicidad     */
/*  14/Nov/2023  Dilan/Bruno            R219332 Generar ID unico en copia */
/*  17/Nov/2023  Dilan/Bruno            R219332 limita top 1 para         */
/*                                      coindencias < 0                   */
/*  29/May/2024  Dilan Morales          R233137: Se corrige validaciones  */
/**************************************************************************/
use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_consulta_usuarios_cr' and type = 'P')
    drop proc sp_consulta_usuarios_cr
go

create proc sp_consulta_usuarios_cr
(
  @s_ssn                int         = null,
  @s_user               varchar(30) = null,
  @s_sesn               int         = null,
  @s_term               varchar(30) = null,
  @s_date               datetime    = null,
  @s_srv                varchar(30) = null,
  @s_lsrv               varchar(30) = null,
  @s_rol                smallint    = null,
  @s_ofi                smallint    = null,
  @s_org_err            char(1)     = null,
  @s_error              int         = null,
  @s_sev                tinyint     = null,
  @s_msg                descripcion = null,
  @s_org                char(1)     = null,
  @t_rty                char(1)     = null,
  @t_trn                int         = null,
  @t_debug              char(1)     = 'N',
  @t_file               varchar(14) = null,
  @t_from               varchar(30) = null,
  @i_id_inst_proc       int               ,     -- codigo de instancia del proceso
  @i_operacion          char(1)     = null

)
as

declare
    @w_sp_name          varchar (30),
    @w_error             int,
    @w_tramite          int,
    @w_relacion         tinyint,
    @w_tipo_solicitud   char(1),
    @w_porcentaje       tinyint,
    @w_pais             varchar(50),
    @w_tiempo_validez   int,
    @w_id_inst_act      int,
    @w_id_destinatario  int,
    @w_id               int,
    @w_primer_nombre    varchar(50),
    @w_segundo_nombre   varchar(50),
    @w_primer_apellido  varchar(50),
    @w_segundo_apellido varchar(50),
    @w_apellido_casado  varchar(50),
    @w_tipo_documento   varchar(50),
    @w_numero_documento varchar(50),
    @w_tipo_cliente     varchar(50),
    @w_nombres_1        varchar(255),
    @w_apellidos_1      varchar(255),
    @w_id_2             int,
    @w_nombres_2        varchar(255),
    @w_apellidos_2      varchar(255),
    @w_tipo_documento_2 varchar(50),
    @w_numero_documento_2   varchar(50),
    @w_min_fecha        smalldatetime ,
    @w_id_verificacion  varchar(51),
    @w_coincidencia     int,
    @w_fecha_consulta   datetime,
    @w_id_cobis         varchar(51)
    
set @w_sp_name = 'sp_consulta_usuarios_cr'   
declare @w_tabla_usuarios as table(id               int,
                                  primer_nombre     varchar(50),
                                  segundo_nombre    varchar(50),
                                  primer_apellido   varchar(50),
                                  segundo_apellido  varchar(50),
                                  apellido_casado   varchar(50),
                                  fecha_nacimiento  varchar(10),
                                  tipo_documento    varchar(50),
                                  numero_documento  varchar(50),
                                  user_name         varchar(50),
                                  accuracy          tinyint,
                                  country           varchar(50),
                                  tipo_cliente      char(1),
                                  representante     int,
                                  estado            char(1) default 'S')
                                 
select @w_relacion = pa_tinyint
from cobis..cl_parametro
where pa_nemonico   = 'CONY' --Relacion Conyuge
and pa_producto     = 'CLI'

select @w_porcentaje = pa_tinyint
from cobis..cl_parametro
where pa_nemonico   = 'PCLN' --PORCENTAJE COINCIDENCIA LISTAS NEGRAS
and pa_producto     = 'CLI'

select @w_pais = pa_char
from cobis..cl_parametro
where pa_nemonico   = 'ABPAIS' --PAIS
and pa_producto     = 'ADM'

select @w_tiempo_validez = pa_int 
from cobis..cl_parametro 
where pa_nemonico = 'MVROC'     --DIAS VALIDEZ RESOLUCION OFICIAL CUMP
and pa_producto = 'CLI'

select @s_date = getdate() --fecha de proceso

select @w_tramite   = io_campo_3
from cob_workflow..wf_inst_proceso where  io_id_inst_proc = @i_id_inst_proc
       

SELECT TOP 1  @w_id_inst_act = ia_id_inst_act from cob_workflow..wf_inst_actividad 
where ia_id_inst_proc = @i_id_inst_proc and ia_estado in ('ACT' , 'INA' , 'PEN') 
order by ia_id_inst_act desc

SELECT TOP 1 @w_id_destinatario  = aa_id_destinatario from cob_workflow..wf_asig_actividad 
WHERE aa_id_inst_act =@w_id_inst_act and aa_estado = 'PEN'

SELECT TOP 1 @s_user = us_login FROM cob_workflow..wf_usuario 
WHERE us_id_usuario = @w_id_destinatario


select @w_tipo_solicitud = tr_tipo from cob_credito..cr_tramite where tr_tramite = @w_tramite


if @w_tipo_solicitud = 'G'
BEGIN
    --SE AÑADE DEUDOR PRINCIPAL Y CODEUDORES
    insert into @w_tabla_usuarios
        (id,                primer_nombre,      segundo_nombre,     primer_apellido,
         segundo_apellido,  apellido_casado,    fecha_nacimiento,   tipo_documento, 
         numero_documento,  tipo_cliente,       representante)
    select 
        en_ente,            trim(en_nombre),    trim(p_s_nombre),   trim(p_p_apellido),
        trim(p_s_apellido), trim(p_c_apellido), CONVERT(VARCHAR(10), p_fecha_nac, 103),     en_tipo_ced,        
        en_ced_ruc,         en_subtipo,         c_rep_legal
        from cobis..cl_ente ,cob_credito..cr_deudores 
        where de_tramite = @w_tramite and en_ente = de_cliente
    
    --AÑADE A SUS REPRESENTANTES LEGALES
    insert into @w_tabla_usuarios
        (id,                primer_nombre,      segundo_nombre,     primer_apellido,
         segundo_apellido,  apellido_casado,    fecha_nacimiento,   tipo_documento, 
         numero_documento,  tipo_cliente,       representante)
    select 
        en_ente,            trim(en_nombre),    trim(p_s_nombre),   trim(p_p_apellido),
        trim(p_s_apellido), trim(p_c_apellido), CONVERT(VARCHAR(10), p_fecha_nac, 103),     en_tipo_ced,        
        en_ced_ruc,         en_subtipo,         c_rep_legal
        from cobis..cl_ente
        where  en_ente in(select representante from @w_tabla_usuarios
                            where tipo_cliente = 'C')
    
    --DMO-ENL-S735105: SE COMENTA YA QUE PARA EL PROYECTO ENLACE NO SE TOMA EN CUENTA A CONYUGES
    /*insert into @w_tabla_usuarios
        (id,                primer_nombre,      segundo_nombre,     primer_apellido,
         segundo_apellido,  apellido_casado,    fecha_nacimiento,   tipo_documento, 
         numero_documento,  tipo_cliente)
    select 
        en_ente,            trim(en_nombre),    trim(p_s_nombre),   trim(p_p_apellido),
        trim(p_s_apellido), trim(p_c_apellido), CONVERT(VARCHAR(10), p_fecha_nac, 103),     en_tipo_ced,        
        en_ced_ruc,         en_subtipo
        from @w_tabla_usuarios , cobis..cl_instancia ,cobis..cl_ente
        where id = in_ente_i and in_relacion = @w_relacion and in_ente_d = en_ente
    */
    
END
else if exists(select 1 from cob_credito..cr_tramite_grupal  where tg_tramite = @w_tramite)
BEGIN
    --DMO SE AÑADE INTEGRANTES DEL GRUPO
    insert into @w_tabla_usuarios
        (id,                primer_nombre,      segundo_nombre,     primer_apellido,
         segundo_apellido,  apellido_casado,    fecha_nacimiento,   tipo_documento, 
         numero_documento,  tipo_cliente,       representante)
    select 
        en_ente,            trim(en_nombre),    trim(p_s_nombre),   trim(p_p_apellido),
        trim(p_s_apellido), trim(p_c_apellido), CONVERT(VARCHAR(10), p_fecha_nac, 103),     en_tipo_ced,        
        en_ced_ruc,         en_subtipo,         c_rep_legal
        from cobis..cl_ente , cob_credito..cr_tramite_grupal  
        where tg_tramite = @w_tramite  and en_ente = tg_cliente  and tg_participa_ciclo = 'S'
    
    --DMO-ENL-S735105: SE COMENTA YA QUE PARA EL PROYECTO ENLACE NO SE TOMA EN CUENTA A CONYUGES
    /*insert into @w_tabla_usuarios
        (id,                primer_nombre,      segundo_nombre,     primer_apellido,
         segundo_apellido,  apellido_casado,    fecha_nacimiento,   tipo_documento, 
         numero_documento,  tipo_cliente)
    select 
        en_ente,            trim(en_nombre),    trim(p_s_nombre),   trim(p_p_apellido),
        trim(p_s_apellido), trim(p_c_apellido), CONVERT(VARCHAR(10), p_fecha_nac, 103),     en_tipo_ced,        
        en_ced_ruc,         en_subtipo
        from @w_tabla_usuarios , cobis..cl_instancia ,cobis..cl_ente
        where id = in_ente_i and in_relacion = @w_relacion and in_ente_d = en_ente
    */          
END
else
BEGIN
    --SE AÑADE DEUDOR PRINCIPAL Y CODEUDORES
    insert into @w_tabla_usuarios
        (id,                primer_nombre,      segundo_nombre,     primer_apellido,
         segundo_apellido,  apellido_casado,    fecha_nacimiento,   tipo_documento, 
         numero_documento,  tipo_cliente,       representante)
    select 
        en_ente,            trim(en_nombre),    trim(p_s_nombre),   trim(p_p_apellido),
        trim(p_s_apellido), trim(p_c_apellido), CONVERT(VARCHAR(10), p_fecha_nac, 103),     en_tipo_ced,        
        en_ced_ruc,         en_subtipo,         c_rep_legal
        from cobis..cl_ente ,cob_credito..cr_deudores 
        where de_tramite = @w_tramite and en_ente = de_cliente

    --SE AÑADE GARANTES                                     
    insert into @w_tabla_usuarios
        (id,                primer_nombre,      segundo_nombre,     primer_apellido,
         segundo_apellido,  apellido_casado,    fecha_nacimiento,   tipo_documento, 
         numero_documento,  tipo_cliente)
    select 
        en_ente,            trim(en_nombre),    trim(p_s_nombre),   trim(p_p_apellido),
        trim(p_s_apellido), trim(p_c_apellido), CONVERT(VARCHAR(10), p_fecha_nac, 103),     en_tipo_ced,        
        en_ced_ruc,         en_subtipo   
        from cob_custodia..cu_custodia  , cob_credito..cr_gar_propuesta , cobis..cl_ente where  
        cu_codigo_externo = gp_garantia and gp_tramite = @w_tramite  and cu_garante is not null
        and  en_ente = cu_garante
        
    
    --AÑADE A SUS REPRESENTANTES LEGALES
    insert into @w_tabla_usuarios
        (id,                primer_nombre,      segundo_nombre,     primer_apellido,
         segundo_apellido,  apellido_casado,    fecha_nacimiento,   tipo_documento, 
         numero_documento,  tipo_cliente,       representante)
    select 
        en_ente,            trim(en_nombre),    trim(p_s_nombre),   trim(p_p_apellido),
        trim(p_s_apellido), trim(p_c_apellido), CONVERT(VARCHAR(10), p_fecha_nac, 103),     en_tipo_ced,        
        en_ced_ruc,         en_subtipo,         c_rep_legal
        from cobis..cl_ente
        where  en_ente in(select representante from @w_tabla_usuarios
                            where tipo_cliente = 'C')
    
    
    --DMO-ENL-S735105: SE COMENTA YA QUE PARA EL PROYECTO ENLACE NO SE TOMA EN CUENTA A CONYUGES
    /*insert into @w_tabla_usuarios
        (id,                primer_nombre,      segundo_nombre,     primer_apellido,
         segundo_apellido,  apellido_casado,    fecha_nacimiento,   tipo_documento, 
         numero_documento,  tipo_cliente)
    select 
        en_ente,            trim(en_nombre),    trim(p_s_nombre),   trim(p_p_apellido),
        trim(p_s_apellido), trim(p_c_apellido), CONVERT(VARCHAR(10), p_fecha_nac, 103),     en_tipo_ced,        
        en_ced_ruc,         en_subtipo
        from @w_tabla_usuarios , cobis..cl_instancia ,cobis..cl_ente
        where id = in_ente_i and in_relacion = @w_relacion and in_ente_d = en_ente
    
      */
END

update @w_tabla_usuarios
    set user_name   = @s_user,
        accuracy    = @w_porcentaje,
        country     = @w_pais

if (@i_operacion != 'Q')
BEGIN
    SELECT @s_date = CONVERT(date, @s_date,103)
            
    --DMO VERIFICAR EN TABLAS DE LISTAS NEGRAS
    declare cur_integrantes cursor read_only for
    select  id,                 primer_nombre,      segundo_nombre,     
            primer_apellido,    segundo_apellido,   apellido_casado,    
            tipo_documento,     numero_documento,   tipo_cliente
    from @w_tabla_usuarios
    
                
    open cur_integrantes
    fetch cur_integrantes into  @w_id   ,               @w_primer_nombre,       @w_segundo_nombre   ,
                                @w_primer_apellido,     @w_segundo_apellido ,   @w_apellido_casado  ,
                                @w_tipo_documento,      @w_numero_documento ,   @w_tipo_cliente     
                
    while(@@fetch_status = 0)
    begin

        if exists( select 1 from cobis..cl_listas_negras_log with(nolock)
                    where ln_codigo_cliente = @w_id)
        begin
            
            --DMO: SE OBTIENE DATOS ACTUALES
            if(@w_primer_nombre is not null)
                select @w_nombres_1 = trim(@w_primer_nombre)+ ' '
            if(@w_segundo_nombre is not null)
                select @w_nombres_1 = isnull(@w_nombres_1, '') + trim(@w_segundo_nombre)
            
            if(@w_primer_apellido is not null)
                select @w_apellidos_1 = trim(@w_primer_apellido)+ ' '
            if(@w_segundo_apellido is not null)
                select @w_apellidos_1 = isnull(@w_apellidos_1, '') + trim(@w_segundo_apellido) + ' '
            if(@w_apellido_casado is not null)
                select @w_apellidos_1 = isnull(@w_apellidos_1, '') + trim(@w_apellido_casado)
            
            select @w_nombres_1 = trim(@w_nombres_1)
            select @w_apellidos_1 = trim(@w_apellidos_1)
            
            
            --DMO SE OBTIENE LA ULTIMA COINCIDENCIA
            select top 1
            @w_nombres_2            =   trim(isnull(ln_nombre,'')),
            @w_apellidos_2          =   trim(isnull(ln_apellido,'')),
            @w_tipo_documento_2     =   ln_tipo_documento,          
            @w_numero_documento_2   =   ln_numero_documento,
            @w_fecha_consulta       =   ln_fecha_consulta,
            @w_id_verificacion      =   ln_id_verificacion,
            @w_coincidencia         =   ln_numero_coincidencias  
            from cobis..cl_listas_negras_log with(nolock)
                where ln_codigo_cliente = @w_id 
                order by ln_fecha_consulta DESC
            

            --DMO: SI NO OBTIENE RESULTADOS SE ENVIA A CONSULTAR.
            if @w_coincidencia < 0
            begin
                update @w_tabla_usuarios
                set estado = 'S'
                where id = @w_id
            end 
            
            --DMO: VERIFICACION PERSONA NATURAL
            else if((@w_tipo_cliente = 'P' 
                and (@w_nombres_1 != @w_nombres_2 
                     or @w_apellidos_1 != @w_apellidos_2
                     or @w_tipo_documento != @w_tipo_documento_2
                     or @w_numero_documento != @w_numero_documento_2))
            )
            begin 
                update @w_tabla_usuarios
                set estado = 'S'
                where id = @w_id
            end
            
            
            --DMO: VERIFICACION PERSONA JURIDICA
            else if (@w_tipo_cliente = 'C' 
                and (@w_nombres_1!=@w_nombres_2 
                     or @w_tipo_documento != @w_tipo_documento_2
                     or @w_numero_documento != @w_numero_documento_2 )
                )
            begin
                update @w_tabla_usuarios
                set estado = 'S'
                where id = @w_id
            end
            
            --DMO: VERIFICAR SI LA ULTIMA BUSQUEDAD TIENE ASOCIADO INSTANCIA Y ESTA DENTRO DEL TIEMPO PARAMETRIZADO
            else if exists (select 1 from cobis..cl_listas_negras_log with(nolock)
                    where ln_codigo_cliente = @w_id
                    and ln_id_verificacion  = @w_id_verificacion 
                    and ln_nro_proceso is not null
                    and DATEDIFF(day,cast(ln_fecha_consulta as date),cast(@s_date as date)) <= @w_tiempo_validez
                    and DATEDIFF(day,cast(ln_fecha_consulta as date),cast(@s_date as date)) >= 0
                    
            )
            begin
                set @w_id_cobis = 'COBIS-' + CONVERT(VARCHAR, @w_id) + '-' + convert(varchar, @s_ssn) --Id verificacion generado
                
                if not exists (select 1 from cobis..cl_listas_negras_log where ln_id_verificacion = @w_id_verificacion and ln_nro_proceso = @i_id_inst_proc and ln_codigo_cliente = @w_id)
                begin
                   update @w_tabla_usuarios
                   set estado = 'N'
                   where id = @w_id
                   
                   insert into  cobis..cl_listas_negras_log
                   (ln_fecha_consulta, ln_usuario, ln_id_verificacion, ln_numero_coincidencias, ln_nombre, ln_apellido, ln_tipo_documento, ln_numero_documento, ln_fecha_nacimiento, ln_codigo_cliente, ln_nro_proceso)
                   select top 1
                   ln_fecha_consulta, @s_user, @w_id_cobis, ln_numero_coincidencias, ln_nombre, ln_apellido, ln_tipo_documento, ln_numero_documento, ln_fecha_nacimiento, ln_codigo_cliente, @i_id_inst_proc
                   from cobis..cl_listas_negras_log
                   where ln_id_verificacion = @w_id_verificacion
                   and ln_codigo_cliente = @w_id
                   
                   if @@error != 0
                   begin
                       /* Error en insercion de registro */
                       select @w_error = 2110429
                       goto ERROR
                   end
                   
                   if not exists(select 1 from cobis..cl_listas_negras_rfe with(nolock)  where  ne_nro_proceso = @i_id_inst_proc and ne_codigo_cliente = @w_id)
                      and exists(select 1 from cobis..cl_listas_negras_rfe with(nolock)  where  ne_id_verificacion = @w_id_verificacion)
                   begin
                      insert into cobis..cl_listas_negras_rfe
                      (ne_id_verificacion, ne_coincidencia, ne_nombre, ne_apellido, ne_tipo_persona, ne_codigo_cliente, ne_nro_proceso, ne_justificacion, ne_estado_resolucion, ne_fecha_resolucion, ne_nro_aml)
                      select top 1
                      @w_id_cobis, ne_coincidencia, ne_nombre, ne_apellido, ne_tipo_persona, ne_codigo_cliente, @i_id_inst_proc, ne_justificacion, ne_estado_resolucion, ne_fecha_resolucion, ne_nro_aml
                      from cobis..cl_listas_negras_rfe
                      where ne_id_verificacion = @w_id_verificacion
                      
                      if @@error != 0
                      begin
                          /* Error en insercion de registro */
                          select @w_error = 2110430
                          goto ERROR
                      end
                   end
                end
            end
            
            --DMO SI ESTA INGRESADO EL REGISTRO CON NUMERO PROCESO NULL Y DENTRO DEL TIEMPO PARAMETRIZADO
            else if exists( select 1 from cobis..cl_listas_negras_log with(nolock)
                    where ln_codigo_cliente = @w_id 
                    and ln_nro_proceso is null
                    and ln_id_verificacion  = @w_id_verificacion 
                    and DATEDIFF(day,cast(ln_fecha_consulta as date),cast(@s_date as date)) <= @w_tiempo_validez
                    and DATEDIFF(day,cast(ln_fecha_consulta as date),cast(@s_date as date)) >= 0
            )
            begin                
                update cobis..cl_listas_negras_log set ln_nro_proceso = @i_id_inst_proc
                where  ln_id_verificacion = @w_id_verificacion
                
                if(@w_coincidencia > 0 or @w_coincidencia = -1)
                begin
                    update cobis..cl_listas_negras_rfe set ne_nro_proceso = @i_id_inst_proc
                    where  ne_id_verificacion = @w_id_verificacion
                end
                
                update @w_tabla_usuarios
                set estado = 'N'
                where id = @w_id                
            end 
        end
                
        fetch cur_integrantes into  @w_id   ,               @w_primer_nombre,       @w_segundo_nombre   ,
                                    @w_primer_apellido,     @w_segundo_apellido ,   @w_apellido_casado  ,
                                    @w_tipo_documento,      @w_numero_documento ,   @w_tipo_cliente         
                        
    end
    close cur_integrantes
    deallocate cur_integrantes

END     
                        
select  DISTINCT id,    
        primer_nombre,      
        segundo_nombre,     
        primer_apellido,
        segundo_apellido,   
        apellido_casado,    
        fecha_nacimiento,   
        tipo_documento, 
        numero_documento,
        user_name,
        accuracy,
        country,
        tipo_cliente
from @w_tabla_usuarios
where estado = 'S'

return 0

ERROR:
   exec cobis..sp_cerror
   @t_debug    ='N',
   @t_file     ='',
   @t_from     =@w_sp_name, 
   @i_num      = @w_error
   return @w_error


GO
