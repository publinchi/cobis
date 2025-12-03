/************************************************************************/
/*  Archivo:                seguros_tramite.sp                          */
/*  Stored procedure:       sp_seguros_tramite                          */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Geovanny Guaman                             */
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
/*  23/04/19          gguaman        Emision Inicial                    */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_seguros_tramite')
    drop proc sp_seguros_tramite
go


create proc sp_seguros_tramite
(
@s_term                  varchar(20)    = null,
@s_date                  datetime       = null,
@s_user                  login          = null,
@s_ofi                   int            = null,
@s_culture               varchar(10)    = 'NEUTRAL',
@t_trn                   smallint       = null,
@t_debug                 char(1)        = 'N',    
@t_file                  varchar(14)    = null,
@t_from                  varchar(30)    = null,
@i_operacion             char(1),
@i_modo                  int            = null,
--cr_seguros_tramite
@i_secuencial_seguro     int            = null,
@i_tipo_seguro           int            = null,
@i_tramite               int            = null,
@i_vendedor              int            = null,
@i_cupo                  char(1)        = null,
@i_fecha_ini_cobertura   datetime       = null,
@i_fecha_fin_cobertura   datetime       = null,
--cr_asegurados
@i_sec_asegurado         int            = null,
@i_tipo_aseg             int            = null,
@i_apellidos             varchar(255)   = null,
@i_nombres               varchar(255)   = null,
@i_tipo_ced              catalogo       = null,
@i_ced_ruc               varchar(30)    = null,
@i_lugar_exp             int            = null,
@i_fecha_exp             datetime       = null,
@i_ciudad_nac            int            = null,
@i_fecha_nac             datetime       = null,
@i_sexo                  varchar(1)     = null,
@i_estado_civil          catalogo       = null,
@i_parentesco            catalogo       = null,
@i_ocupacion             catalogo       = null,
@i_direccion             varchar(255)   = null,
@i_telefono              varchar(16)    = null,
@i_ciudad                int            = null,
@i_correo_elec           varchar(255)   = null,
@i_celular               varchar(16)    = null,
@i_correspondencia       varchar(255)   = null,
@i_plan                  int            = null,
@i_fecha_modif           datetime       = null,
@i_usuario_modif         login          = null,
@i_observaciones         varchar(255)   = null,
@i_act_economica         catalogo       = null,
@i_ente                  char(1)        = null,
@i_formato_fecha         int            = null,
@i_tflexible             char(1)        = 'N'
)

as 
declare
@w_return                int,          /* VALOR QUE RETORNA  */
@w_sp_name               varchar(60),  /* NOMBRE STORED PROC */
@w_existe                int,          /* EXISTE EL REGISTRO */
@w_msg                   varchar(100),
@w_error                 int,
@w_secuencial_seguro     int,
@w_tipo_seguro           int,
@w_tramite               int,
@w_vendedor              int,
@w_cupo                  char(1),
@w_fecha_ini_cobertura   datetime,
@w_fecha_fin_cobertura   datetime,
--cr_asegurados
@w_sec_asegurado         int,
@w_tipo_aseg             int,
@w_apellidos             varchar(255),
@w_nombres               varchar(255),
@w_tipo_ced              catalogo,
@w_ced_ruc               varchar(30),
@w_lugar_exp             int,
@w_fecha_exp             datetime,
@w_ciudad_nac            int,
@w_fecha_nac             datetime,
@w_sexo                  varchar(1),
@w_estado_civil          catalogo,
@w_parentesco            catalogo,
@w_ocupacion             catalogo,
@w_direccion             varchar(255),
@w_telefono              varchar(16),
@w_ciudad                int,
@w_correo_elec           varchar(255),
@w_celular               varchar(16),
@w_correspondencia       catalogo,
@w_plan                  int,
@w_fecha_modif           datetime,
@w_usuario_modif         login,
@w_observaciones         varchar(255),
@w_act_economica         catalogo,
@w_des_sexo              varchar(255),
@w_des_tipo_seguro       varchar(255),
@w_des_vendedor          varchar(255),
@w_des_tipo_ced          varchar(255),
@w_des_lugar_exp         varchar(255),
@w_des_ciudad_nac        varchar(255),
@w_des_estado_civil      varchar(255),
@w_des_depto     varchar(255),
@w_des_ciudad            varchar(255),
@w_des_plan              varchar(255),
@w_des_act_economica     varchar(255),
@w_des_parentesco        varchar(255),
@w_des_ocupacion         varchar(255),
@w_depto                 int,
@w_vlr_tipo_seg          money,
@w_valor_plan            money,
@w_total                 money,
@w_ente                  char(1),
@w_cliente               int,
@w_dir_email             varchar(10),
@w_tipo_dir              varchar(10),
@w_dir_corresp           varchar(10),
@w_dir_res               varchar(10),
@w_dir_neg               varchar(10),
@w_pareja                varchar(30),
@w_edad_clant            int,
@w_edad_clnue            int,
@w_edad                  int,
@w_edad_may              tinyint,
@w_indicador             tinyint,
@w_seguro_vig            tinyint,
@w_clave1                varchar(20),
@w_clave2                varchar(20),
@w_plazo_cobertura_cre   int,
@w_plazo_cred            int,
--@w_tasa_efa              float,           -- CCA 391 Cambio Politica - Tasa seguro Vs Tasa Microcrédito
--@w_int_cartera           float,           -- CCA 391 Cambio Politica - Tasa seguro Vs Tasa Microcrédito
@w_porc_max              float,
@w_valor_max             money,
@w_valor_seguros         money,
@w_monto                 money,
@w_monto_sin_seg         money,
@w_plazo_mes             int,
@w_num_dias              int,
@w_tplazo                varchar(10),
@w_ced_ruc_tr            varchar(14),
@w_max_aseg_ex           int,
@w_num_aseg              int,
@w_num_aseg_pad          int,
@w_num_aseg_asp          int,
@w_num_aseg_con          int,
@w_valor_total           money,
@w_tabla                 varchar(24),
@w_desc_tipo_seguro      varchar(30),
@w_valor                 int,
@w_tipo_tramite          char(1),
@w_fecha_fin_renov       datetime,
@w_tiene_seguro          int,
@w_cedula                varchar(30),      
@w_tipo_cedula           catalogo,
@w_plazo_mes_ant         int,
@w_valor_seguros_ant     money,
@w_tr_cliente            int,
@w_aseg_princip          char(1),
@w_fecha_fin_op_nueva    datetime,
@w_fecha_ini_op_nueva    datetime,
@w_numero_dias           int,
@w_tipo_plazo            varchar(10),
@w_plazo                 int,
@w_habilita_benef        char(1),
@w_cedula_deudor         varchar(30), ---REQ 00404 
@w_tabla_edad_perm       varchar(5), ---tabla de edades -permanencia a consultar REQ 00404
@w_param_dias            int, --parametro para calculo de vigencia de antiguedad para REQ 00404 
@w_fecha_ini_pri_per     datetime, --Fecha inicio cobertura asegurado principal REQ 00404
@w_fecha_fin_pri_per     datetime, --Fecha fin cobertura asegurado principal REQ 00404  
@w_fecha_max             datetime  -- CCA 419, Fecha Maxima Vigente en Polilzas 
    
    
    
select @w_sp_name       = 'sp_seguros_tramite',
       @s_date          = getdate(),
       @i_usuario_modif = @s_user,
       @i_fecha_modif   = getdate(),
       @w_valor         = 0

if (@t_trn <> 22924 and @i_operacion = 'I') or
   (@t_trn <> 22926 and @i_operacion = 'D') or
   (@t_trn <> 22927 and @i_operacion = 'S')
begin
   /* tipo de transaccion no corresponde */
   select
   @w_error = 1901006
   goto ERROR
end

select @i_formato_fecha       = 101
select @i_fecha_ini_cobertura = null
select @i_fecha_fin_cobertura = null

if @i_operacion in ('A', 'P', 'B')
   create table #seguros_cli( --Tabla Temporal para guardar los distintos tipos de seguro que pudiera tener un cliente en las operaciones anteriores.
   tipo_seg      int null,
   sec_seguro    int null,
   sec_asegurado int null,
   ced_ruc       varchar(30),
   tipo_ced      varchar(10),  
   fecha_ini_cob datetime null, 
   fecha_fin_cob datetime null
   )
   
   
/** Insert/Update **/
if @i_operacion = 'I'
begin
   if @t_trn = 22924
   begin
   
     if @i_secuencial_seguro is null   --insertar cr_secuencial_tramite
     begin

        exec @w_return = cobis..sp_cseqnos
        @t_debug     = @t_debug,
        @t_file      = @t_file,
        @t_from      = @w_sp_name,
        @i_tabla     = 'cr_seguros_tramite',
        @o_siguiente = @i_secuencial_seguro out

        if @w_return <> 0
        begin
           select                                                                                                                                                                                                                                                 
           @w_error = @w_return
           goto ERROR
        end
		
        if exists(select 1 from cr_tramite where tr_tramite = @i_tramite and tr_tipo = 'C')
        select @i_cupo = 'S'
                                                         
        insert into cr_seguros_tramite (
        st_secuencial_seguro,    st_tipo_seguro,       st_tramite,
        st_vendedor,             st_cupo
        )
        values (
        @i_secuencial_seguro,    @i_tipo_seguro,       @i_tramite,
        @i_vendedor,             @i_cupo
        )
        
        if @@error <> 0 
        begin
           select                                                                                                                                                                                                                                                 
           @w_error = 2110354
           goto ERROR
        end
        
        select @w_clave1 = convert(varchar, @i_secuencial_seguro)
        exec @w_error = sp_tran_servicio
        @s_date     = @s_date,
        @s_user     = @s_user,
        @s_ofi      = @s_ofi,
        @s_term     = @s_term,
        @i_tabla    = 'cr_micro_seguro',
        @i_borrado  = 'N',
        @i_clave1   = @w_clave1

        if @w_error <> 0 
        begin
           select
           @w_error = @w_error              
           goto ERROR
        end
        
     end
     
     if (@i_sec_asegurado is null) or (@i_sec_asegurado = 0)   --insertar cr_asegurados
     begin

           select @i_sec_asegurado = as_sec_asegurado + 1,
                  @w_plan          = as_plan
           from cr_asegurados with (nolock)
           where as_secuencial_seguro = @i_secuencial_seguro

           select @w_cliente = en_ente
           from cobis..cl_ente with (nolock)
           where en_ced_ruc  = @i_ced_ruc
           and   en_tipo_ced = @i_tipo_ced

           if exists(select 1 from cr_tramite with (nolock) where tr_tramite = @i_tramite and tr_cliente = @w_cliente)
              select @i_tipo_aseg = 1
           else
              select @i_tipo_aseg = 2

           if (@i_sec_asegurado is null) or (@i_sec_asegurado = 0)
              select @i_sec_asegurado = 1

           select @i_ente = 'N'
           if @w_cliente is not null
              select @i_ente = 'S'

           /* Si es primera perdida y el plan ingresado para el segundo asegurado es diferente del primer asegurado 
              rechaza el ingreso del nuevo asegurado */
           if @i_tipo_seguro = 2
           begin
              if @i_plan <> @w_plan and @w_plan is not null
              begin
                 select @w_error = 2110355
                 goto ERROR
              end
           end
                            
                     
              
           
           insert into cr_asegurados (
           as_secuencial_seguro,       as_sec_asegurado,       as_tipo_aseg,
           as_apellidos,               as_nombres,             as_tipo_ced,
           as_ced_ruc,                 as_lugar_exp,           as_fecha_exp,
           as_ciudad_nac,              as_fecha_nac,           as_sexo,
           as_estado_civil,            as_parentesco,          as_ocupacion,
           as_direccion,               as_telefono,            as_ciudad,
           as_correo_elec,             as_celular,             as_correspondencia,
           as_plan,                    as_fecha_modif,         as_usuario_modif,
           as_observaciones,           as_act_economica,       as_ente,
           as_fecha_ini_cobertura,     as_fecha_fin_cobertura
           )
           values (
           @i_secuencial_seguro,       @i_sec_asegurado,       @i_tipo_aseg,
           @i_apellidos,               @i_nombres,             @i_tipo_ced,
           @i_ced_ruc,                 @i_lugar_exp,           @i_fecha_exp,
           @i_ciudad_nac,              @i_fecha_nac,           @i_sexo,
           @i_estado_civil,            @i_parentesco,          @i_ocupacion,
           @i_direccion,               @i_telefono,            @i_ciudad,
           @i_correo_elec,             @i_celular,             @i_correspondencia,
           @i_plan,                    @i_fecha_modif,         @i_usuario_modif,
           @i_observaciones,           @i_act_economica,       @i_ente,
           @i_fecha_ini_cobertura,     @i_fecha_fin_cobertura
           )
  
           if @@error <> 0 
           begin
              select                                                                                                                                                                                                                                                 
              @w_error = 2103001
              goto ERROR
           end

           select @w_clave1 = convert(varchar, @i_secuencial_seguro)
           select @w_clave2 = convert(varchar, @i_sec_asegurado)
           exec @w_error = sp_tran_servicio
           @s_date     = @s_date,
           @s_user     = @s_user,
           @s_ofi      = @s_ofi,
           @s_term     = @s_term,
           @i_tabla    = 'cr_aseg_microseguro',
           @i_borrado  = 'N',
           @i_clave1   = @w_clave1,
           @i_clave2   = @w_clave2

           if @w_error <> 0 
           begin
              select
              @w_error = @w_error               
              goto ERROR
           end
           
    end
    else  --update cr_asegurados
    begin

    
          update cr_asegurados set
          as_apellidos         = @i_apellidos,
          as_nombres           = @i_nombres,             
          as_lugar_exp         = @i_lugar_exp,           
          as_fecha_exp         = @i_fecha_exp,
          as_ciudad_nac        = @i_ciudad_nac,              
          as_fecha_nac         = @i_fecha_nac,           
          as_sexo              = @i_sexo,
          as_estado_civil      = @i_estado_civil,            
          as_parentesco        = @i_parentesco,          
          as_ocupacion         = @i_ocupacion,
          as_direccion         = @i_direccion,               
          as_telefono          = @i_telefono,            
          as_ciudad            = @i_ciudad,
          as_correo_elec       = @i_correo_elec,             
          as_celular           = @i_celular,             
          as_correspondencia   = @i_correspondencia,
          as_plan              = @i_plan,                    
          as_fecha_modif       = @i_fecha_modif,         
          as_usuario_modif     = @i_usuario_modif,
          as_observaciones     = @i_observaciones,
          as_act_economica     = @i_act_economica
          where as_secuencial_seguro = @i_secuencial_seguro
          and   as_sec_asegurado     = @i_sec_asegurado

          if @@error <> 0 
          begin
             select                                                                                                                                                                                                                                                 
             @w_error = 2110356
             goto ERROR
          end

          select @w_clave1 = convert(varchar, @i_secuencial_seguro)
          select @w_clave2 = convert(varchar, @i_sec_asegurado)
          exec @w_error = sp_tran_servicio
          @s_date     = @s_date,
          @s_user     = @s_user,
          @s_ofi      = @s_ofi,
          @s_term     = @s_term,
          @i_tabla    = 'cr_aseg_microseguro',
          @i_borrado  = 'N',
          @i_clave1   = @w_clave1,
          @i_clave2   = @w_clave2

        if @w_error <> 0 
        begin
           select
           @w_error = @w_error               
           goto ERROR
        end

    end
    
     exec @w_error = cob_credito..sp_seguros_tramite 
          @i_tramite    = @i_tramite,
          @i_operacion  = 'P',
          @i_tflexible  = @i_tflexible
          
     if @w_error <> 0 
     begin
       select                                                                                                                                                                                                                                                 
       @w_error = @w_error
       goto ERROR
     end    
    
  end
end


/** Search **/
if @i_operacion = 'D'
begin
   if @t_trn = 22926
   begin

     if exists(select 1 
               from cr_beneficiarios with (nolock)
               where be_secuencial_seguro  = @i_secuencial_seguro
               and   be_sec_asegurado      = @i_sec_asegurado)
     begin
       select                                                                                                                                                                                                                        
       @w_error = 2110357
       goto ERROR
     end

     delete cr_asegurados
     where as_secuencial_seguro = @i_secuencial_seguro
     and   as_sec_asegurado     = @i_sec_asegurado

     if @@error <> 0 
     begin
       select                                                                                                                                                                                                                                                 
       @w_error = 2110358
       goto ERROR
     end

     select @w_valor = count(1)
     from cr_asegurados with (nolock)
     where as_secuencial_seguro = @i_secuencial_seguro

     if @w_valor = 0
     begin

        delete cr_seguros_tramite
        where st_secuencial_seguro = @i_secuencial_seguro

        if @@error <> 0 
        begin
          select                                                                                                                                                                                                                                                 
          @w_error = 2110359
          goto ERROR
        end
      end
   end
end


/** Query **/
if @i_operacion = 'S'
begin
   if @t_trn = 22927
   begin

     if @i_modo = 0
     begin

        --mapea grid1 tipos de seguros
        select
        'Secuencial Seguro'    = st_secuencial_seguro,
        'Tipo Seguro'          = st_tipo_seguro,
        'Desc. Tipo Seguro'    = (select top 1 se_descripcion
                                  from cr_tipo_seguro_vs  with (nolock)
                                  where se_tipo_seguro = X.st_tipo_seguro),
        'Tramite'              = st_tramite,
        'Vendedor'             = st_vendedor,
        'Desc. Vendedor'       = (select convert(varchar(50),fu_nombre)
                                  from cobis..cc_oficial with (nolock), cobis..cl_funcionario with (nolock)
                                  where oc_oficial     = X.st_vendedor
                                  and   oc_funcionario = fu_funcionario),
        'Cupo'                 = st_cupo,
        'Fecha Ini. Cobertura' = null, --convert(varchar(10), as_fecha_ini_cobertura, @i_formato_fecha),
        'Fecha Fin Cobertura'  = null  --convert(varchar(10), as_fecha_fin_cobertura, @i_formato_fecha)
        from cr_seguros_tramite X with (nolock) 
        where st_tramite   = @i_tramite
     end

     if @i_modo = 1
     begin
                        
        select @w_valor_total = 0
        
        -- Calcula el valor total del seguro, incluyendo tipos de seguros antiguos o totalmente nuevos
        select @w_valor_total = isnull(sum(isnull(ps_valor_mensual,0) * isnull(datediff(mm,as_fecha_ini_cobertura,as_fecha_fin_cobertura),0)),0)
        from cr_seguros_tramite with (nolock),
   cr_asegurados      with (nolock),
             cr_plan_seguros_vs with (nolock)             
        where st_tramite           = @i_tramite
        and   st_secuencial_seguro = as_secuencial_seguro
        and   as_plan              = ps_codigo_plan
        and   st_tipo_seguro       = ps_tipo_seguro
        and   ps_estado            = 'V'
        and   ps_tipo_seguro       = @i_tipo_seguro        
        and   as_tipo_aseg         = (case when ps_tipo_seguro in(2,3,4) then 1 else as_tipo_aseg end)        
        
        --mapea grid2 asegurados por tipo de seguro
        select 
        'Secuencial Asegurado' = as_sec_asegurado,
        'Tipo Asegurado'       = as_tipo_aseg,
        'Apellidos'            = as_apellidos,
        'Nombres'              = as_nombres,
        'Tipo Identificacion'  = as_tipo_ced,
        'Desc. Tipo Identif.'  = (select B.valor
                                  from cobis..cl_tabla A, cobis..cl_catalogo B
                                  where A.tabla  = 'cl_tipo_documento'
                                  and   A.codigo = B.tabla
                                  and   B.codigo = X.as_tipo_ced),
        'Identificacion'       = as_ced_ruc,
        'Lugar Expedicion'     = as_lugar_exp,
        'Desc.Lugar Expedic.'  = (select ci_descripcion
                                  from cobis..cl_ciudad with (nolock)
                                  where ci_ciudad = X.as_lugar_exp),
        'Fecha Expedicion'     = convert(varchar(10), as_fecha_exp, @i_formato_fecha),
        'Ciudad Nacimiento'    = as_ciudad_nac,
        'Desc. Ciudad Nac'     = (select ci_descripcion
                                  from cobis..cl_ciudad with (nolock)
                                  where ci_ciudad = X.as_ciudad_nac),
        'Fecha Nacimiento'     = convert(varchar(10), as_fecha_nac, @i_formato_fecha),
        'Genero'               = as_sexo,
        'Desc. Genero'         = (select B.valor
                                  from cobis..cl_tabla A, cobis..cl_catalogo B
                                  where A.tabla  = 'cl_sexo'
                                  and   A.codigo = B.tabla
                                  and   B.codigo = X.as_sexo),
        'Estado Civil'         = as_estado_civil,
        'Desc. Estado Civil'   = (select B.valor
                                  from cobis..cl_tabla A, cobis..cl_catalogo B
                                  where A.tabla  = 'cl_ecivil'
                                  and   A.codigo = B.tabla
                                  and   B.codigo = X.as_estado_civil),
        'Parentesco'           = as_parentesco,
        'Desc. Parentesco'     = case when @i_tipo_seguro = 2 then
                                         (select B.valor
                                          from cobis..cl_tabla A, cobis..cl_catalogo B
                                          where A.tabla  = 'cr_tipo_asegurado'
                                          and   A.codigo = B.tabla
                                          and   B.codigo = X.as_parentesco)
                                     when @i_tipo_seguro = 3 then
                                         (select B.valor
                                          from cobis..cl_tabla A, cobis..cl_catalogo B
                                          where A.tabla  = 'cr_parentesco_seg'
                                          and   A.codigo = B.tabla
                                          and   B.codigo = X.as_parentesco)
                                 end,
        'Ocupacion'            = as_ocupacion,
        'Desc.Ocupacion'       = (select B.valor
                                  from cobis..cl_tabla A, cobis..cl_catalogo B
                                  where A.tabla  = 'cl_tipo_empleo'
                                  and   A.codigo = B.tabla
                                  and   B.codigo = X.as_ocupacion),
        'Direccion'   = as_direccion,
        'Departamento'         = (select ci_provincia
                                  from cobis..cl_ciudad with (nolock)
                                  where ci_ciudad = X.as_ciudad),
        'Desc. Departamento'   = (select pv_descripcion
                                  from cobis..cl_ciudad with (nolock), cobis..cl_provincia with (nolock)
                                  where ci_ciudad    = X.as_ciudad
                                  and   ci_provincia = pv_provincia),
        'Ciudad'               = as_ciudad,
        'Desc. Ciudad'         = (select ci_descripcion
                                  from cobis..cl_ciudad with (nolock)
                                  where ci_ciudad = X.as_ciudad),
        'Telefono Fijo'        = as_telefono,
        'Celular'              = as_celular,
        'Correo Electronico'   = as_correo_elec,
        'Correspondencia'      = as_correspondencia,
        'Plan'                 = as_plan,
        'Desc. Plan'           = (select top 1 ps_descripcion 
                                  from cr_plan_seguros_vs with (nolock)
                                  where ps_codigo_plan  = X.as_plan
                                  and   ps_tipo_seguro  = Y.st_tipo_seguro),
        'Valor Plan'           = (select top 1 ps_valor_mensual
                                  from cr_plan_seguros_vs with (nolock)
                                  where ps_codigo_plan  = X.as_plan
                                  and   ps_tipo_seguro  = Y.st_tipo_seguro),
        'Observaciones'        = as_observaciones,
        'Act. Economica'       = as_act_economica,
        'Des. Act. Economica'  = (select B.valor
                                  from cobis..cl_tabla A, cobis..cl_catalogo B
                                  where A.tabla  = 'cl_actividad'
                                  and   A.codigo = B.tabla
                                  and   B.codigo = X.as_act_economica),
        'Ente'                 = as_ente,
        'Fecha Modifica'       = convert(varchar(10), as_fecha_modif, @i_formato_fecha),
        'Usuario Modifica'     = as_usuario_modif,
        'Fecha Inicio Cob'     = convert(varchar(10), as_fecha_ini_cobertura, @i_formato_fecha),
        'Fecha Fin Cob'        = convert(varchar(10), as_fecha_fin_cobertura, @i_formato_fecha)
        from cr_asegurados X with (nolock), cr_seguros_tramite Y with (nolock)
        where as_secuencial_seguro = @i_secuencial_seguro
        and  st_secuencial_seguro  = as_secuencial_seguro
        and  st_tramite            = @i_tramite

        select @w_valor_total
     end
   end
end


if @i_operacion = 'V'    --Opcion para F5 del FE (tipo de seguro)
begin
   if @t_trn = 22925
   begin

      select
      'Tipo Seguro'  = se_tipo_seguro,
      'Descripcion'  = se_descripcion
      from cr_tipo_seguro_vs  with (nolock)
      where se_estado = 'V'
      order by se_tipo_seguro
   end
end
                                                                                                                                                                                                                                                           
if @i_operacion = 'Q'    --Opcion para F5 del FE (tipo de seguro)
begin
   if @t_trn = 22925
   begin

      select top 1
      'Tipo Seguro'  = se_tipo_seguro,
      'Descripcion'  = se_descripcion
      from cr_tipo_seguro_vs with (nolock)
      where se_tipo_seguro = @i_tipo_seguro
      and   se_estado      = 'V'
   end
end

if @i_operacion = 'X'    --Opcion para F5 del FE (plan)
begin
   if @t_trn = 22925
   begin

      select
      'Codigo Plan'  = ps_codigo_plan,
      'Descripcion'  = ps_descripcion,
      'Valor Plan'   = ps_valor_mensual
      from cr_plan_seguros_vs with (nolock)
      where ps_tipo_seguro = @i_tipo_seguro
      and   ps_estado      = 'V'

   end
end

if @i_operacion = 'Y' --Opcion para F5 del FE (plan)
begin
   if @t_trn = 22925
   begin

      select top 1
      'Codigo Plan'  = ps_codigo_plan,
      'Descripcion'  = ps_descripcion,
      'Valor Plan'   = ps_valor_mensual
      from cr_plan_seguros_vs with (nolock)
      where ps_tipo_seguro = @i_tipo_seguro
      and   ps_codigo_plan = @i_plan
      and   ps_estado      = 'V'
   end
end

if @i_operacion = 'T'    --Opcion para F5 del FE (parentesco asegurados)
begin
   if @t_trn = 22925
   begin

      if @i_tipo_seguro = 2  --Primera Perdida
         select @w_tabla = 'cr_tipo_asegurado'   

      if @i_tipo_seguro = 3  --Exequias
         select @w_tabla = 'cr_parentesco_seg'

      select
      'Codigo'       = B.codigo,
      'Descripcion'  = B.valor
      from cobis..cl_tabla A, cobis..cl_catalogo B
      where A.tabla   = @w_tabla
      and   A.codigo  = B.tabla
   end
end

if @i_operacion = 'U'    --Opcion para F5 del FE (parentesco asegurados)
begin
   if @t_trn = 22925
   begin

      if @i_tipo_seguro = 2  --Primera Perdida
         select @w_tabla = 'cr_tipo_asegurado'   

      if @i_tipo_seguro = 3  --Exequias
         select @w_tabla = 'cr_parentesco_seg'

      select top 1
      'Codigo'       = B.codigo,
      'Descripcion'  = B.valor
      from cobis..cl_tabla A, cobis..cl_catalogo B
      where A.tabla   = @w_tabla
      and   A.codigo  = B.tabla
      and   B.codigo  = @i_parentesco
   end
end


if @i_operacion = 'H'    --Opcion para F5 del FE
begin
   if @t_trn = 22925
   begin

      select 
      @w_apellidos        = isnull(p_p_apellido,'') + ' ' + isnull(p_s_apellido,''),
      @w_nombres          = en_nombre,
      @w_lugar_exp        = p_lugar_doc,
      @w_des_lugar_exp    = (select ci_descripcion
                             from cobis..cl_ciudad with (nolock)
                             where ci_ciudad = X.p_lugar_doc),
      @w_fecha_exp        = convert(varchar(10), p_fecha_emision, @i_formato_fecha),
      @w_ciudad_nac       = p_ciudad_nac,
      @w_des_ciudad_nac   = (select ci_descripcion
                             from cobis..cl_ciudad with (nolock)
                             where ci_ciudad = X.p_ciudad_nac),
      @w_fecha_nac        = convert(varchar(10), p_fecha_nac, @i_formato_fecha),
      @w_sexo             = p_sexo,
      @w_des_sexo         = (select B.valor
                             from cobis..cl_tabla A, cobis..cl_catalogo B
                             where A.tabla  = 'cl_sexo'
                             and   A.codigo = B.tabla
                             and   B.codigo = X.p_sexo),
      @w_estado_civil     = p_estado_civil,
      @w_des_estado_civil = (select B.valor
                             from cobis..cl_tabla A, cobis..cl_catalogo B
                             where A.tabla  = 'cl_ecivil'
                             and   A.codigo = B.tabla
                             and   B.codigo = X.p_estado_civil),
      @w_ocupacion         = en_concordato,
      @w_des_ocupacion     = (select B.valor
                             from cobis..cl_tabla A, cobis..cl_catalogo B
                             where A.tabla  = 'cl_tipo_empleo'
                             and   A.codigo = B.tabla
                             and   B.codigo = X.en_concordato),
      @w_act_economica     = en_actividad,
      @w_des_act_economica = (select B.valor
                             from cobis..cl_tabla A, cobis..cl_catalogo B
                             where A.tabla  = 'cl_actividad'
                             and   A.codigo = B.tabla
                             and   B.codigo = X.en_actividad),
      @w_tr_cliente        = (select tr_cliente from cob_credito..cr_tramite where tr_tramite = @i_tramite and tr_cliente = X.en_ente)
      from cobis..cl_ente X with (nolock)
      where en_tipo_ced = @i_tipo_ced
      and   en_ced_ruc  = @i_ced_ruc

      select @w_dir_email = pa_char 
from cobis..cl_parametro with (nolock)
      where pa_nemonico = 'TDW'

      select @w_dir_corresp = pa_char 
      from cobis..cl_parametro with (nolock)
      where pa_nemonico = 'TDA'

      select @w_dir_res = pa_char 
      from cobis..cl_parametro with (nolock)
      where pa_nemonico = 'TDR'

      select @w_dir_neg = pa_char 
      from cobis..cl_parametro with (nolock)
      where pa_nemonico = 'TDN'

      select @w_tipo_dir  = di_tipo
      from cobis..cl_ente with (nolock), cobis..cl_direccion X with (nolock)
      where en_tipo_ced  = @i_tipo_ced
      and   en_ced_ruc   = @i_ced_ruc
      and   en_ente      = di_ente
      and   di_principal = 'S'

      select 
      @w_correo_elec = di_descripcion             
      from cobis..cl_ente with (nolock), cobis..cl_direccion with (nolock)
      where en_tipo_ced = @i_tipo_ced
      and   en_ced_ruc  = @i_ced_ruc
      and   en_ente     = di_ente
      and   di_tipo     = @w_dir_email

      select @w_correspondencia = di_descripcion
      from cobis..cl_ente with (nolock), cobis..cl_direccion with (nolock)
      where en_tipo_ced = @i_tipo_ced
      and   en_ced_ruc  = @i_ced_ruc
      and   en_ente     = di_ente
      and   di_tipo     = @w_dir_corresp 

      if @i_tipo_seguro = 4
      begin
         select @w_dir_res = @w_dir_neg
      end else begin
         if @w_tipo_dir = @w_dir_neg
            select @w_dir_res = @w_dir_neg
      end

      select @w_direccion  = di_descripcion,
             @w_depto      = di_provincia,
             @w_des_depto  = (select pv_descripcion from cobis..cl_provincia with (nolock) where pv_provincia = X.di_provincia),
             @w_ciudad     = di_ciudad,
             @w_des_ciudad = (select ci_descripcion from cobis..cl_ciudad with (nolock) where ci_ciudad = X.di_ciudad)
      from cobis..cl_ente with (nolock), cobis..cl_direccion X with (nolock)
      where en_tipo_ced = @i_tipo_ced
      and   en_ced_ruc  = @i_ced_ruc
      and   en_ente     = di_ente
      and   di_tipo     = @w_dir_res

      select @w_telefono  = isnull(te_prefijo,'') + isnull(te_valor,'')
      from cobis..cl_ente with (nolock), cobis..cl_direccion with (nolock), cobis..cl_telefono with (nolock)
      where en_tipo_ced      = @i_tipo_ced
      and   en_ced_ruc       = @i_ced_ruc
      and   en_ente          = di_ente
      and   di_tipo          = @w_dir_res
      and   di_ente          = te_ente
      and   di_direccion     = te_direccion
      and   te_tipo_telefono = 'D'

      select @w_celular  = isnull(te_prefijo,'') + isnull(te_valor,'')
      from cobis..cl_ente with (nolock), cobis..cl_direccion with (nolock), cobis..cl_telefono with (nolock)
      where en_tipo_ced      = @i_tipo_ced
      and   en_ced_ruc       = @i_ced_ruc
      and   en_ente          = di_ente
      and   di_tipo          = @w_dir_res
      and   di_ente          = te_ente
      and   di_direccion     = te_direccion
      and   te_tipo_telefono = 'C'
      
      if @i_tipo_seguro = 3
      begin
         if @w_tr_cliente is not null 
            select @w_aseg_princip = 'S'
         else
            select @w_aseg_princip = 'N'
      end
      
      select 
      @w_apellidos,        --1
      @w_nombres,
      @w_lugar_exp,
      @w_des_lugar_exp,
      convert(varchar(10), @w_fecha_exp, @i_formato_fecha),        --5
      @w_ciudad_nac,
      @w_des_ciudad_nac,
      convert(varchar(10), @w_fecha_nac, @i_formato_fecha),
      @w_sexo,
      @w_des_sexo,         --10 
      @w_estado_civil,
      @w_des_estado_civil,
      @w_parentesco,
      @w_des_parentesco,
      @w_ocupacion,        --15
      @w_des_ocupacion,
      @w_direccion,
      @w_depto,
      @w_des_depto,
      @w_ciudad,           --20
      @w_des_ciudad,
      @w_telefono,
      @w_celular,
      @w_correo_elec,
      @w_correspondencia,  --25
      @w_act_economica,
      @w_des_act_economica,
      @w_aseg_princip
 
   end
end

if @i_operacion = 'A'  --Validacion Negocio por Tipo de Seguro
begin

   /**********************************/
   --TIPOS DE SEGURO
   --1. Seguro de Vida Individual
   --2. Seguro de Vida Primera Perdida
   --3. Exequias
   --4. Da¤os Materiales
   /***********************************/

   if @t_trn = 22925
   begin

      if @i_secuencial_seguro is null
      begin

         if exists(select 1 from cr_seguros_tramite with (nolock)
                   where st_tramite      = @i_tramite
                   and   st_tipo_seguro  = @i_tipo_seguro)
         begin
            select @w_desc_tipo_seguro = se_descripcion
            from cr_tipo_seguro
            where se_tipo_seguro = @i_tipo_seguro
         
            select                                                                                                                                                                                                                                                 
            @w_error = 2110360
            goto ERROR
         end
      end            

      --Validacion general
      if @i_sec_asegurado is null
      begin

         if exists(select 1 from cr_asegurados with (nolock)
                   where as_secuencial_seguro = @i_secuencial_seguro
                   and   as_ced_ruc           = @i_ced_ruc
                   and   as_tipo_ced          = @i_tipo_ced)
         begin
            select                                                                                                                                                                                                                                                 
            @w_error = 2110361
            goto ERROR
         end          
      end

      /*  -- -- CCA 391 Cambio Politica - Tasa seguro Vs Tasa Microcrédito
      --Validacion 2 --> 12.2.	Valida que la Tasa de Inter‚s del Producto de Seguro ingresada sea menor a la tasa m xima del microcr‚dito. De lo contrario, genera mensaje  
      select @w_int_cartera = isnull(ro_porcentaje_efa,0)
      from cob_cartera..ca_operacion with (nolock), cob_cartera..ca_rubro_op with (nolock)
      where op_tramite   = @i_tramite
      and   op_operacion = ro_operacion
      and   ro_concepto  = 'INT'

      if @w_tasa_efa > @w_int_cartera
      begin
         select                                                                                                                                                                                                                                                 
         @w_error = 2103001,                                                                                                                                                                                                                                         
         @w_msg   = 'El Valor de la Tasa no puede estar vacio, ni superar la maxima del microcredito'
         goto ERROR
      end
      */


     if @i_tipo_seguro = 2 --Primera Perdida
     begin

         select @w_num_aseg_asp = count(1) 
         from cr_asegurados with (nolock) 
         where as_secuencial_seguro = @i_secuencial_seguro
         and   as_ced_ruc           <> @i_ced_ruc
         and   as_parentesco        = '1'  --Asegurado Principal

         if @w_num_aseg_asp is null
            select @w_num_aseg_asp = 0

         if @i_parentesco = '1'
         begin
            if @w_num_aseg_asp + 1 > 1
            begin
               select                                                                                                                                                                                                                                                 
               @w_error = 2110362
               goto ERROR
            end
         end
      end
      
      --Calcula la edad del asegurado
      select @w_edad = datediff(yy, @i_fecha_nac, @s_date)
      
      --Validacion 3  --> 12.3.	El sistema permite la captura de UN solo TIPO de SEGURO por Tr mite de Cr‚dito (M ximo 3 tipos en este momento)
      
      --Validacion Exequiales
      if @i_tipo_seguro = 3 --Exequiales
      begin
      
         select @w_num_aseg_asp = count(1) 
         from cr_asegurados with (nolock) 
         where as_secuencial_seguro = @i_secuencial_seguro
         and   as_ced_ruc           <> @i_ced_ruc
         and   as_parentesco        = 'ASP'  --Asegurado Principal

         if @w_num_aseg_asp is null
            select @w_num_aseg_asp = 0

         if @i_parentesco = 'ASP'
         begin
            if @w_num_aseg_asp + 1 > 1
            begin
               select                                                                                                                                                                                                                                                 
               @w_error = 2110362
               goto ERROR
            end
         end

         select @w_num_aseg_pad = count(1) 
         from cr_asegurados with (nolock) 
         where as_secuencial_seguro = @i_secuencial_seguro
         and   as_ced_ruc           <> @i_ced_ruc
         and   as_parentesco        = 'PAD'  --Padres

         if @w_num_aseg_pad is null
            select @w_num_aseg_pad = 0

         if @i_parentesco = 'PAD'
         begin
            if @w_num_aseg_pad + 1 > 2
            begin
               select                                                                                                                                                                                                                                                 
               @w_error = 2110363
               goto ERROR
            end
         end

         select @w_num_aseg_con = count(1) 
         from cr_asegurados with (nolock) 
         where as_secuencial_seguro = @i_secuencial_seguro
         and   as_ced_ruc           <> @i_ced_ruc
         and   as_parentesco        = 'CCP'  --conyuge

         if @w_num_aseg_con is null
            select @w_num_aseg_con = 0

         if @i_parentesco = 'CCP'
         begin
            if @w_num_aseg_con + 1 > 1
            begin
          select                                                                                                                                                                                                                                                 
               @w_error = 2110364
               goto ERROR
            end
         end

         select @w_max_aseg_ex = pa_int
         from cobis..cl_parametro with (nolock)
         where pa_producto = 'CRE'
         and   pa_nemonico = 'MCAEX'

         select @w_num_aseg = count(1)   --Numero de asegurados adicionales (secundarios)
         from   cr_asegurados with (nolock) 
         where  as_secuencial_seguro = @i_secuencial_seguro
         and    as_ced_ruc           <> @i_ced_ruc
         and    as_tipo_aseg <> 1
       
         if @w_num_aseg is null
            select @w_num_aseg = 0
         else
            select @w_num_aseg = @w_num_aseg+ 1
         
         if ((@i_tipo_aseg > 1 or @i_tipo_aseg is null) and @i_sec_asegurado is null)
         begin
            if @w_num_aseg > @w_max_aseg_ex
            begin
               select                                                                                                                                                                                                                                                 
               @w_error = 2110365
               goto ERROR
            end
         end
         
         --Edad
         select @w_valor = 0
         select @w_valor = isnull(count(1),0)
         from cob_credito..cr_corresp_sib with (nolock)
         where tabla   = 'T210'
         and   codigo  = @i_parentesco
         and   @w_edad between limite_inf and limite_sup
         
         if @w_valor = 0
         begin
            select                                                                                                                                                                                                                                                 
            @w_error = 2110366
            goto ERROR
         end

         --Permanencia
         select @w_valor = 0
         select @w_valor = isnull(count(1),0)
         from cob_credito..cr_corresp_sib with (nolock)
         where tabla   = 'T211'
         and   codigo  = @i_parentesco
         and   @w_edad between limite_inf and limite_sup

         if @w_valor = 0
         begin
            select                                                                                                                                                                                                                                                 
            @w_error = 2110367
            goto ERROR
         end
      end
      
      --Validacion Da¤os Materiales
      if @i_tipo_seguro = 4 --Da¤os Materiales
      begin
         select @w_ced_ruc_tr = de_ced_ruc
         from cob_credito..cr_deudores with (nolock)
         where de_tramite = @i_tramite
         and   de_rol     = 'D'

         if @w_ced_ruc_tr <> @i_ced_ruc 
         begin
            select                                                                                                                                                                                                                                                 
            @w_error = 2110368
            goto ERROR
         end         
         
         if exists(select 1 from cr_seguros_tramite with (nolock) where st_tramite = @i_tramite and st_tipo_seguro = @i_tipo_seguro) 
            and @i_secuencial_seguro is null
         begin
            select                                                                                                                                                                                                                                                 
            @w_error = 2110369
            goto ERROR
         end
      end
      
      --Validaciones Anteriores de Edad para seguro Individual y Primera Perdida. 
      --No se valida edad para el tipo de poliza de Danos.
      
      if @i_tipo_seguro in (1,2)
      begin
             
         --Parametrizacion de edades cliente nuevo- viejo
         /*select @w_edad_clant = 0,
                @w_edad_clnue = 0
         
         --REQ 00404   - se cambia tabla de parametria a consultar
         select @w_edad_clant = pa_int
         from cobis..cl_parametro with (nolock)
         where pa_producto = 'CRE'
         and   pa_nemonico = 'ECAMS'
         
         select @w_edad_clnue = pa_int
         from cobis..cl_parametro with (nolock)
         where pa_producto = 'CRE'
         and   pa_nemonico = 'ECNMS'   REQ 00404*/ 
         
         select @w_edad_may = pa_tinyint
         from cobis..cl_parametro with (nolock)
         where pa_producto = 'ADM'
         and   pa_nemonico = 'MDE' 
         
 		 --REQ 404 se quita validaciones de parametria 
         /*if isnull(@w_edad_clnue,0) = 0 or isnull(@w_edad_clant,0) = 0
         begin
            select
            @w_error = 2103001,
            @w_msg   = 'NO EXISTE PARAMETRIZACION DE EDADES'
            goto ERROR
         end    REQ 00404 */ 
         
        --VALIDACIONES DE EDAD DEL ASEGURADO 
         if datepart(mm,@s_date) < datepart(mm,@i_fecha_nac)
            select @w_edad = datepart(yy,@s_date) - datepart(yy,@i_fecha_nac) -1

         if datepart(mm,@s_date) = datepart(mm,@i_fecha_nac)
            if datepart(dd,@s_date) < datepart(dd,@i_fecha_nac)
               select @w_edad = datepart(yy,@s_date) - datepart(yy,@i_fecha_nac) -1
     
         --VALIDACIONES DE CLIENTES NUEVOS --ANTIGUOS REQ 00404
         select @w_indicador = 0  --Indicador Cliente Nuevo (0)
     
         --DETERMINAR SI ES CLIENTE NUEVO O ANTIGUO SEGUN REQ 00404
         select @w_param_dias = isnull(pa_int,0)
         from cobis..cl_parametro with (nolock)
 where pa_nemonico = 'SDIAS'
                      
         --SELECCION DE ULTIMA FECHA DE CREDITO VIGENTE REQ 00404            
         --select @w_fecha_fin_cobertura = null
         
         --REGISTROS TABLAS NUEVAS  REQ 00404
         select 
		 cedula = as_ced_ruc, tipo_ced = as_tipo_ced, tramite = st_tramite, estado_car = op_estado, tipo_seg = st_tipo_seguro, fecha_ini = as_fecha_ini_cobertura, fecha_fin = as_fecha_fin_cobertura
		 into #cr_antiguedad		 
         from cob_credito..cr_asegurados with (nolock), cob_credito..cr_seguros_tramite with (nolock), cob_cartera..ca_operacion with (nolock)
         where as_secuencial_seguro = st_secuencial_seguro
         and   as_ced_ruc           = @i_ced_ruc
         and   as_tipo_ced          = @i_tipo_ced
         and   st_tramite           = op_tramite
         and   op_estado            not in (0,99,6)   
         and   st_tipo_seguro       = @i_tipo_seguro
		 and   st_tramite           <> @i_tramite

		 
		 --REGISTROS ACTIVOS TABLAS ANTIGUAS  REQ 404
         insert into #cr_antiguedad		 
		 select 
		 am_identificacion, am_tipo_iden, ms_tramite, op_estado, ms_clase, ms_fecha_ini, ms_fecha_fin		 
             from cob_credito..cr_aseg_microseguro A with (nolock), 
                  cob_credito..cr_micro_seguro with (nolock), 
                  cob_cartera..ca_operacion with (nolock),
                  cob_credito ..cr_tramite T with (nolock) 
             where ms_secuencial       = am_microseg
             and   ms_estado           <> 'A'
             and   A.am_identificacion = @i_ced_ruc
             and   A.am_tipo_iden      = @i_tipo_ced
             and   ms_tramite          = op_tramite
             and   ms_tramite          = tr_tramite 
             and   tr_estado           <> 'Z'                   
             and   op_estado           not in (0, 99, 6, 3)
             and   op_tramite          <> @i_tramite			 
             and   ms_clase            = @i_tipo_seguro
             and   @s_date             between  ms_fecha_ini and ms_fecha_fin      
             and   ms_fecha_fin        = (select MAX(ms_fecha_fin) 
                                          from cr_micro_seguro,cr_aseg_microseguro 
                                          where ms_secuencial     = am_microseg
                                          and   am_secuencial     = A.am_secuencial
                                          and   am_identificacion = A.am_identificacion
                                          and   am_tipo_iden      = A.am_tipo_iden
                                          and   ms_tramite        = T.tr_tramite
                                          and   T.tr_estado       <> 'Z')                          
		 
		 
         --SEGUROS NO ACTIVOS TABLAS ANTIGUAS   REQ 404

         insert into #cr_antiguedad		 
		 select
		 am_identificacion, am_tipo_iden, ms_tramite, op_estado, ms_clase, ms_fecha_ini, ms_fecha_fin		 
             from cob_credito..cr_aseg_microseguro A with (nolock), 
                  cob_credito..cr_micro_seguro with (nolock), 
                  cob_cartera..ca_operacion with (nolock),
                  cob_credito ..cr_tramite T with (nolock) 
             where ms_secuencial       = am_microseg
             and   ms_estado           <> 'A'
             and   A.am_identificacion = @i_ced_ruc
             and   A.am_tipo_iden      = @i_tipo_ced
             and   ms_tramite          = op_tramite
             and   ms_tramite          = tr_tramite 
             and   tr_estado           <> 'Z'                   
             and   op_estado           in (3)
             and   op_tramite          <> @i_tramite			 
             and   ms_clase            = @i_tipo_seguro
             and   ms_fecha_fin        = (select MAX(ms_fecha_fin) 
                                          from cr_micro_seguro,cr_aseg_microseguro 
                                          where ms_secuencial     = am_microseg
                                          and   am_secuencial     = A.am_secuencial
                                          and   am_identificacion = A.am_identificacion
                                          and   am_tipo_iden      = A.am_tipo_iden
                                          and   ms_tramite        = T.tr_tramite
                                          and   T.tr_estado       <> 'Z')                           
        
             delete #cr_antiguedad
             where datediff(dd,fecha_fin, @s_date) > @w_param_dias

             if exists(SELECT 1 from #cr_antiguedad)
                select @w_indicador = 1  --cliente antiguo  REQ 404
             else  
                select @w_indicador = 0  --cliente nuevo    REQ 404
 
         
         --CONSULTA TABLAS DE CORRESPONDENCIA SEGUN TIPO DE SEGURO REQ 00404   
         if @i_tipo_seguro = 1
            select @i_parentesco = 1
         
         if @i_tipo_seguro = 2 and @w_indicador = 0 -- CLIENTE NUEVO PARA PRIMERA PERDIDA REQ 00404
            select @w_tabla_edad_perm = 'T212'      -- POR LO TANTO SE VALIDA LA EDAD CON LA T212 REQ 00404

         if @i_tipo_seguro = 2 and @w_indicador = 1 -- CLIENTE ANTIGUO PARA PRIMERA PERDIDA REQ 00404
            select @w_tabla_edad_perm = 'T213'      --POR LO TANTO SE VALIDA LA PERMANENCIA CON LA TABLA 213 REQ 00404
--          
         
         if @i_tipo_seguro = 1 and @w_indicador = 0 -- CLIENTE NUEVO PARA INDIVIDUAL REQ 00404
            select @w_tabla_edad_perm = 'T214'      -- POR LO TANTO SE VALIDA LA EDAD CON LA T214 REQ 00404

         if @i_tipo_seguro = 1 and @w_indicador = 1 -- CLIENTE ANTIGUO PARA INDIVIDUAL REQ 00404
            select @w_tabla_edad_perm = 'T215'      --POR LO TANTO SE VALIDA LA PERMANENCIA CON LA TABLA 215 REQ 00404
         
         select @w_valor = 0
         select @w_valor = isnull(count(1),0)
         from cob_credito..cr_corresp_sib with (nolock)
         where tabla   = @w_tabla_edad_perm
         and   codigo  = @i_parentesco
         and   @w_edad between limite_inf and limite_sup
         
           
         if @w_valor = 0 and @w_tabla_edad_perm in('T212','T214')
         begin
            select                                                                                                                                                                                                                                                 
            @w_error = 2110366
            goto ERROR
         end

    
         if @w_valor = 0 and @w_tabla_edad_perm in('T213','T215')
         begin
            select                                                                                                                                                                                                                                                 
            @w_error = 2110367
            goto ERROR
         end

      end  
                
      -- Validacion de mayoria de edad
      if @w_edad < @w_edad_may
      begin
         select
         @w_error = 2101196
         goto ERROR
      end


      select @w_cliente = en_ente
      from cobis..cl_ente with (nolock)
      where en_ced_ruc  = @i_ced_ruc
      and   en_tipo_ced = @i_tipo_ced
 
      if exists(select 1 from cr_tramite with (nolock) where tr_tramite = @i_tramite and tr_cliente = @w_cliente and tr_estado <> 'Z')
         select @i_tipo_aseg = 1
      else
         select @i_tipo_aseg = 2

      
      --Validaciones exclusivas Primera Perdida      
      if @i_tipo_seguro = 2
      begin
           
      --VALIDA SI EL ASEGURADO PRINCIPAL ES EL MISMO DEUDOR REQ 00404
                  
         if @i_parentesco = 1
         begin
            select @w_existe = 0
         
            select @w_cliente = en_ente
            from cobis..cl_ente with (nolock)
            where en_ced_ruc  = @i_ced_ruc
            and   en_tipo_ced = @i_tipo_ced

            select @w_existe = count(1) 
            from cr_tramite with (nolock) 
            where tr_tramite = @i_tramite 
            and tr_cliente = @w_cliente
                
            if @w_existe <> 1
            begin     
               select                                                                                                                                                                                                                                                 
               @w_error = 2110370
               goto ERROR           
            end
         end    

                      
         --Validaciones de conyuge
         if @i_tipo_aseg <> convert(int,@i_parentesco) -- 1 Asegurado principal, 2 Conyuge en el catalogo cr_tipo_asegurado (Primera Perdida)
         begin
            select
            @w_error = 2110371
            goto ERROR            
         end
         
         select @w_pareja = null
         
         select 
         @w_pareja = isnull(hi_documento,0), 
         @w_cliente   = en_ente
         from  cobis..cl_ente with (nolock), cobis..cl_hijos with (nolock)
         where en_ced_ruc  = @i_ced_ruc
         and   en_tipo_ced = @i_tipo_ced
         and   hi_ente     = en_ente
         and   hi_tipo     = 'C'
            
         if @w_pareja is null and @i_tipo_aseg = 1
         begin
            select 
            @w_error = 2110372
            goto ERROR
         end
         
         select @w_pareja = null

         if @i_tipo_aseg = 2
            select @w_cliente = tr_cliente from cr_tramite with (nolock) where tr_tramite = @i_tramite

         select 
         @w_pareja = isnull(hi_documento,0)
         from  cobis..cl_hijos with (nolock)
         where hi_documento  = @i_ced_ruc
         and   hi_tipo_doc   = @i_tipo_ced
         and   hi_tipo       = 'C'
         and   hi_ente       = @w_cliente
         
         if @w_pareja is null and @i_tipo_aseg = 2
         begin
            select 
            @w_error = 2110373
            goto ERROR
         end
                  
       
      end  -- fin tipo seguro primera perdida
                  
      -- Validacion 1  -->12.1. Valida que el plazo del seguro no sea menor al permitido de acuerdo a la parametrizacion.
      select 
      @w_tipo_tramite = tr_tipo
      from cob_credito..cr_tramite with (nolock)
      where tr_tramite = @i_tramite
        
      if @w_tipo_tramite <> 'C'
      begin
         select 
         @w_plazo_mes           = op_plazo, 
         @w_tplazo              = op_tplazo, 
         @w_fecha_ini_op_nueva  = op_fecha_ini,
         @w_fecha_fin_op_nueva  = op_fecha_fin         
         from cob_cartera..ca_operacion with (nolock)
         where op_tramite = @i_tramite
      end
      else
      begin
         select          
         @w_plazo_mes          = tr_plazo, 
         @w_tplazo             = tr_tipo_plazo,
         @w_fecha_ini_op_nueva = li_fecha_inicio,
         @w_fecha_fin_op_nueva = li_fecha_vto
         from cob_credito..cr_tramite with (nolock),cob_credito..cr_linea with (nolock)
         where tr_tramite = @i_tramite
         and tr_tramite = li_tramite
      end        
        
      select @w_plazo_cobertura_cre = isnull(ps_plazo_cobertura_cre,0)
      from cob_credito..cr_plan_seguros_vs with (nolock)
      where ps_codigo_plan       = @i_plan
      and   ps_estado            = 'V'
      and   ps_tipo_seguro       = @i_tipo_seguro      
      
      select
      @w_num_dias = pe_factor
      from cr_periodo with (nolock)
      where pe_periodo = @w_tplazo

      select @w_plazo_mes = (@w_plazo_mes * @w_num_dias) / 30  --Plazo en meses

      -- Insertamos los distintos tipos de seguros que pueda tener el cliente en las operaciones anteriores (Revisando en las tablas del nuevo esquema de Seguros)
      insert into #seguros_cli select distinct B.st_tipo_seguro, B.st_secuencial_seguro, A.as_sec_asegurado,
                                               A.as_ced_ruc,     A.as_tipo_ced,          A.as_fecha_ini_cobertura, 
                                               A.as_fecha_fin_cobertura 
      from cob_credito..cr_asegurados A with (nolock), 
           cob_credito..cr_seguros_tramite B with (nolock), 
           cob_cartera..ca_operacion with (nolock),
           cob_credito..cr_tramite T with (nolock)
      where as_secuencial_seguro     = B.st_secuencial_seguro
      and   A.as_ced_ruc             = @i_ced_ruc
      and   A.as_tipo_ced            = @i_tipo_ced
      and   st_tramite               = op_tramite
      and   st_tramite               = tr_tramite
      and   tr_estado                <> 'Z'                               
      and   op_estado                not in (6)
      and   op_tramite               <> @i_tramite
      and   st_tipo_seguro           = @i_tipo_seguro
      and   A.as_fecha_fin_cobertura >= convert(varchar(10),@s_date,101)
      and   A.as_fecha_fin_cobertura = (select MAX(as_fecha_fin_cobertura) 
                                     from cr_asegurados,cr_seguros_tramite 
                                     where as_ced_ruc           = A.as_ced_ruc 
                                     and   as_tipo_ced          = A.as_tipo_ced                                     
                                     and   st_tramite           = T.tr_tramite                                     
                                     and   T.tr_estado          <> 'Z'
                                     and   st_secuencial_seguro = as_secuencial_seguro)                  
      if @@error <> 0 
      begin
         select                                                                                                                                                                                                                                                 
         @w_error = 2110374
         goto ERROR
      end
   

      -- Insertamos los distintos tipos de seguros que pueda tener el cliente en las operaciones anteriores (Revisando en las tablas del antiguo esquema de Seguros)
      insert into #seguros_cli select distinct convert(int,ms_clase), ms_secuencial, am_secuencial, am_identificacion, am_tipo_iden, 
                                                       ms_fecha_ini , ms_fecha_fin 
      from cob_credito..cr_aseg_microseguro A with (nolock), 
           cob_credito..cr_micro_seguro with (nolock), 
           cob_cartera..ca_operacion with (nolock),
           cob_credito..cr_tramite T with (nolock) 
      where ms_secuencial       = am_microseg
      and   ms_estado           <> 'A'
      and   A.am_identificacion = @i_ced_ruc
      and   A.am_tipo_iden      = @i_tipo_ced
      and   ms_tramite          = op_tramite
      and   ms_tramite          = tr_tramite 
      and   tr_estado           <> 'Z'                   
      and   op_estado           not in (6)
      and   op_tramite          <> @i_tramite
      and   ms_clase            = convert(varchar,@i_tipo_seguro)   
      and   @s_date             between  ms_fecha_ini and ms_fecha_fin      
      and   ms_fecha_fin        = (select MAX(ms_fecha_fin) 
                                  from cr_micro_seguro,cr_aseg_microseguro 
                                  where ms_secuencial     = am_microseg
                                  and   am_secuencial     = A.am_secuencial
                                  and   am_identificacion = A.am_identificacion
                                  and   am_tipo_iden      = A.am_tipo_iden
                                  and   ms_tramite        = T.tr_tramite
                                  and   T.tr_estado       <> 'Z')                          
      
      if @@error <> 0 
      begin
         select                                                                                                                                                                                                                                                 
         @w_error = 2110375
         goto ERROR
      end
      
      if exists (select 1 from #seguros_cli where tipo_seg = @i_tipo_seguro)
      begin
      
         --OBTIENE LA FECHA DE MAXIMA VIGENCIA DE LAS POLIZAS DEL CLIENTE
         select @w_fecha_max = max(fecha_fin_cob)
         from #seguros_cli
         
         delete from #seguros_cli where fecha_fin_cob <> @w_fecha_max
      
         -- Fecha Inicio Cobertura: Fecha Inicio de la Nueva Operacion.
         -- Fecha Fin Cobertura: Fecha Inicio Cobertura mas el plazo en meses de la Operacion Nueva
         update #seguros_cli 
         set fecha_ini_cob = dateadd(dd,1,fecha_fin_cob),
             fecha_fin_cob = dateadd(mm,case 
                                        when (dateadd(dd,1,fecha_fin_cob) = dateadd(dd,-1,DATEADD(mm,1,dateadd(dd, 1 - datepart(dd, dateadd(dd,1,fecha_fin_cob)),dateadd(dd,1,fecha_fin_cob))))
                                              and @w_fecha_fin_op_nueva = dateadd(dd,-1,DATEADD(mm,1,dateadd(dd, 1 - datepart(dd, @w_fecha_fin_op_nueva),@w_fecha_fin_op_nueva)))) 
                                              or datepart(dd,dateadd(dd,1,fecha_fin_cob)) <= datepart(dd,@w_fecha_fin_op_nueva)
                                        then datediff(mm,dateadd(dd,1,fecha_fin_cob),@w_fecha_fin_op_nueva)
                                        when (dateadd(dd,1,fecha_fin_cob) <> dateadd(dd,-1,DATEADD(mm,1,dateadd(dd, 1 - datepart(dd, dateadd(dd,1,fecha_fin_cob)),dateadd(dd,1,fecha_fin_cob))))
                                             or  @w_fecha_fin_op_nueva <> dateadd(dd,-1,DATEADD(mm,1,dateadd(dd, 1 - datepart(dd, @w_fecha_fin_op_nueva),@w_fecha_fin_op_nueva))))
                                             and (datepart(dd,dateadd(dd,1,fecha_fin_cob)) > datepart(dd,@w_fecha_fin_op_nueva))
                                        then datediff(mm,dateadd(dd,1,fecha_fin_cob),@w_fecha_fin_op_nueva) - 1
                                        end,dateadd(dd,1,fecha_fin_cob))
      
         where tipo_seg = @i_tipo_seguro

         if @@error <> 0 
         begin
            select                                                                                                                                                                                                                                                 
            @w_error = 2110376
            goto ERROR
         end               
                  
         select @w_plazo_mes = datediff(mm,fecha_ini_cob,fecha_fin_cob)
         from #seguros_cli
         where tipo_seg = @i_tipo_seguro
         
         print 'Mensaje Informativo: El Asegurado Tiene Vigente Un Seguro de Este Tipo'                          
         
      end
      else
      begin   
         
         select @w_plazo_mes = @w_plazo_mes
      
      end
      
      if @w_plazo_mes <= 0
      begin
         select @w_error = 2103001
         print 'El Asegurado con Documento de Identidad ' + @i_ced_ruc  + ' ya tiene asociada una poliza vigente del tipo ' + cast(@i_tipo_seguro as varchar) + ', no es posible asociar el mismo tipo de poliza con fecha de vigencia menor a la fecha fin de la poliza vigente '         
         goto ERROR
      end
      
      if @w_plazo_mes < @w_plazo_cobertura_cre 
      begin
         select @w_error = 2103001                                                                                                                                                                                                                                         
         print 'Plazo del Tipo de Seguro ' + cast(@i_tipo_seguro as varchar) + ' del Asegurado con Documento de Identidad ' + @i_ced_ruc  + ', menor al permitido. Debe ser mayor a ' + cast(@w_plazo_cobertura_cre as varchar) + ' meses '
         goto ERROR
      end   -- Fin Validacion coberturas por plazo de los tipos de seguros         
   end                                       
end


--Calcular el Monto Total de los Seguros de un Tramite
if @i_operacion = 'C' 
begin   
   if @t_trn = 22925
   begin      
      
      select @w_valor_total = 0
                          
      if exists (select 1 from cob_credito..cr_seguros_tramite,cob_credito..cr_asegurados 
                              where st_tramite = @i_tramite
                              and st_secuencial_seguro = as_secuencial_seguro
                              and ((as_fecha_ini_cobertura is null or as_fecha_fin_cobertura is null) or as_fecha_ini_cobertura < @s_date))
      begin

         exec @w_error = cob_credito..sp_seguros_tramite 
              @i_tramite   = @i_tramite,
              @i_operacion = 'P',
              @i_tflexible = @i_tflexible
          
         if @w_error <> 0 
         begin
           select                                                                                                                                                                                                                                                 
           @w_error = @w_error
           goto ERROR
         end    
            
      end
      -- Calcula el valor total del seguro, incluyendo tipos de seguros antiguos o totalmente nuevos
      select @w_valor_total = isnull(sum(isnull(ps_valor_mensual,0) * isnull(datediff(mm,as_fecha_ini_cobertura,as_fecha_fin_cobertura),0)),0)
      from cr_seguros_tramite with (nolock),
           cr_asegurados      with (nolock),
           cr_plan_seguros_vs
      where st_tramite           = @i_tramite
      and   st_secuencial_seguro = as_secuencial_seguro
      and   as_plan              = ps_codigo_plan
      and   st_tipo_seguro       = ps_tipo_seguro
      and   ps_estado            = 'V'      
      and   as_tipo_aseg         = (case when ps_tipo_seguro in(2,3,4) then 1 else as_tipo_aseg end)                                         
      
      select @w_valor_total
   end
end

--Validacion se realiza en una nueva operacion porque se usara desde cartera tambien.
if @i_operacion = 'B'
begin

   if @t_trn = 22925
   begin

      -- Se verifica que si el asegurado ya existe registrado con este tipo de seguro no se vuelva a validar el exceso en el Valor de Primas de Seguros
      if exists (select 1 from cob_credito..cr_seguros_tramite,cob_credito..cr_asegurados 
                          where as_secuencial_seguro = st_secuencial_seguro
                          and   as_ced_ruc           = @i_ced_ruc
                          and   as_tipo_ced          = @i_tipo_ced                                                    
                          and   st_tramite           = @i_tramite
                          and   st_tipo_seguro       = @i_tipo_seguro)
         return 0


      --Validacion 4  --> 12.4.	validar que la sumatoria de las Primas de Seguros a Financiar no sea mayor a este porcentaje sobre el valor del monto del cr‚dito solicitado.
      select @w_porc_max = isnull(pa_float,0)
      from cobis..cl_parametro with (nolock)
      where pa_nemonico = 'PMFPS'
      
      -- Calcula el valor total del seguro, incluyendo tipos de seguros antiguos o totalmente nuevos
      select @w_valor_seguros = isnull(sum(isnull(ps_valor_mensual,0) * isnull(datediff(mm,as_fecha_ini_cobertura,as_fecha_fin_cobertura),0)),0)
      from cr_seguros_tramite with (nolock),
           cr_asegurados      with (nolock),
           cr_plan_seguros_vs with (nolock)      
      where st_tramite           = @i_tramite
      and   st_secuencial_seguro = as_secuencial_seguro
      and   as_plan              = ps_codigo_plan
      and   st_tipo_seguro       = ps_tipo_seguro
      and   ps_estado            = 'V'      
      and   as_tipo_aseg         = (case when ps_tipo_seguro in(2,3,4) then 1 else as_tipo_aseg end)                                         
      
      select @w_monto = isnull(tr_monto_solicitado,0)  --tr_monto contiene el valor con seguros
      from cr_tramite with (nolock)
      where tr_tramite = @i_tramite
      
      select @w_monto_sin_seg = @w_monto      

      select @w_plazo_mes = op_plazo, 
             @w_tplazo = op_tplazo,
             @w_fecha_ini_op_nueva  = op_fecha_ini,
             @w_fecha_fin_op_nueva  = op_fecha_fin             
      from cob_cartera..ca_operacion with (nolock)
      where op_tramite = @i_tramite

      select
      @w_num_dias = pe_factor
      from cr_periodo with (nolock)
      where pe_periodo = @w_tplazo

      select @w_plazo_mes = (@w_plazo_mes * @w_num_dias) / 30  --Plazo en meses
      
      -- Insertamos los distintos tipos de seguros que pueda tener el cliente en las operaciones anteriores (Revisando en las tablas del nuevo esquema de Seguros)
      insert into #seguros_cli select distinct B.st_tipo_seguro, B.st_secuencial_seguro, A.as_sec_asegurado,
                                               A.as_ced_ruc,     A.as_tipo_ced,          A.as_fecha_ini_cobertura, 
                                               A.as_fecha_fin_cobertura 
      from cob_credito..cr_asegurados A with (nolock), 
           cob_credito..cr_seguros_tramite B with (nolock), 
           cob_cartera..ca_operacion with (nolock),
           cob_credito..cr_tramite T with (nolock)        
      where as_secuencial_seguro     = B.st_secuencial_seguro
      and   A.as_ced_ruc             = @i_ced_ruc
      and   A.as_tipo_ced            = @i_tipo_ced
      and   st_tramite               = op_tramite
      and   st_tramite               = tr_tramite
      and   tr_estado                <> 'Z'                               
      and   op_estado                not in (6)
      and   op_tramite               <> @i_tramite
      and   st_tipo_seguro           = @i_tipo_seguro                      
      and   A.as_fecha_fin_cobertura = (select MAX(as_fecha_fin_cobertura) 
                                     from cr_asegurados,cr_seguros_tramite 
                                     where as_ced_ruc = A.as_ced_ruc 
                                     and   as_tipo_ced = A.as_tipo_ced
                                     and   st_tramite           = T.tr_tramite                                     
                                     and   T.tr_estado          <> 'Z'
                                     and   st_secuencial_seguro = as_secuencial_seguro)                  
      if @@error <> 0 
      begin
         select                                                                                                                                                                                                                                                 
         @w_error = 2110374
         goto ERROR
      end
   

      -- Insertamos los distintos tipos de seguros que pueda tener el cliente en las operaciones anteriores (Revisando en las tablas del antiguo esquema de Seguros)
      insert into #seguros_cli select distinct convert(int,ms_clase), ms_secuencial, am_secuencial, am_identificacion, am_tipo_iden, 
                                                       ms_fecha_ini , ms_fecha_fin 
      from cob_credito..cr_aseg_microseguro A with (nolock), 
           cob_credito..cr_micro_seguro with (nolock), 
           cob_cartera..ca_operacion with (nolock),
           cob_credito..cr_tramite T with (nolock)         
      where ms_secuencial       = am_microseg
      and   ms_estado           <> 'A'
      and   A.am_identificacion = @i_ced_ruc
      and   A.am_tipo_iden      = @i_tipo_ced
      and   ms_tramite          = op_tramite                    
      and   ms_tramite          = tr_tramite
      and   tr_estado           <> 'Z'
      and   op_estado           not in (6)
      and   op_tramite          <> @i_tramite
      and   ms_clase            = convert(varchar,@i_tipo_seguro)   
      and   @s_date             between  ms_fecha_ini and ms_fecha_fin      
      and   ms_fecha_fin        = (select MAX(ms_fecha_fin) 
                                  from cr_micro_seguro,cr_aseg_microseguro 
                                  where ms_secuencial     = am_microseg
                                  and   am_secuencial     = A.am_secuencial
                                  and   am_identificacion = A.am_identificacion
                                  and   am_tipo_iden      = A.am_tipo_iden
                                  and   ms_tramite        = T.tr_tramite
                                  and   T.tr_estado       <> 'Z')                          
      
      if @@error <> 0 
      begin
         select                                                                                                                                                                                        
         @w_error = 2110375
         goto ERROR
      end
      
      if exists (select 1 from #seguros_cli where tipo_seg = @i_tipo_seguro)
      begin
      
         --OBTIENE LA FECHA DE MAXIMA VIGENCIA DE LAS POLIZAS DEL CLIENTE
         select @w_fecha_max = max(fecha_fin_cob)
         from #seguros_cli
         
         delete from #seguros_cli where fecha_fin_cob <> @w_fecha_max

         -- Fecha Inicio Cobertura: Fecha Inicio de la Nueva Operacion.
         -- Fecha Fin Cobertura: Fecha Inicio Cobertura mas el plazo en meses de la Operacion Nueva
         update #seguros_cli 
         set fecha_ini_cob = dateadd(dd,1,fecha_fin_cob),
             fecha_fin_cob = dateadd(mm,case 
                                        when (dateadd(dd,1,fecha_fin_cob) = dateadd(dd,-1,DATEADD(mm,1,dateadd(dd, 1 - datepart(dd, dateadd(dd,1,fecha_fin_cob)),dateadd(dd,1,fecha_fin_cob))))
                                              and @w_fecha_fin_op_nueva = dateadd(dd,-1,DATEADD(mm,1,dateadd(dd, 1 - datepart(dd, @w_fecha_fin_op_nueva),@w_fecha_fin_op_nueva)))) 
                                              or datepart(dd,dateadd(dd,1,fecha_fin_cob)) <= datepart(dd,@w_fecha_fin_op_nueva)
                                        then datediff(mm,dateadd(dd,1,fecha_fin_cob),@w_fecha_fin_op_nueva)
                                        when (dateadd(dd,1,fecha_fin_cob) <> dateadd(dd,-1,DATEADD(mm,1,dateadd(dd, 1 - datepart(dd, dateadd(dd,1,fecha_fin_cob)),dateadd(dd,1,fecha_fin_cob))))
                                             or  @w_fecha_fin_op_nueva <> dateadd(dd,-1,DATEADD(mm,1,dateadd(dd, 1 - datepart(dd, @w_fecha_fin_op_nueva),@w_fecha_fin_op_nueva))))
                                             and (datepart(dd,dateadd(dd,1,fecha_fin_cob)) > datepart(dd,@w_fecha_fin_op_nueva))
                                        then datediff(mm,dateadd(dd,1,fecha_fin_cob),@w_fecha_fin_op_nueva) - 1
                                        end,dateadd(dd,1,fecha_fin_cob))
      
         where tipo_seg = @i_tipo_seguro

         if @@error <> 0 
         begin
            select                                                                                                                                                                                                                                                 
            @w_error = 2110379
            goto ERROR
         end               
         
         select @w_plazo_mes = datediff(mm,fecha_ini_cob,fecha_fin_cob)
         from #seguros_cli
         where tipo_seg = @i_tipo_seguro                  
         
      end
      else
      begin   
         
         select @w_plazo_mes = @w_plazo_mes
      
      end      
      
      select @w_cliente = en_ente
      from cobis..cl_ente with (nolock)
      where en_ced_ruc  = @i_ced_ruc
      and   en_tipo_ced = @i_tipo_ced

      if exists(select 1 from cr_tramite with (nolock) where tr_tramite = @i_tramite and tr_cliente = @w_cliente)
         select @i_tipo_aseg = 1
      else
         select @i_tipo_aseg = 2      
 
      if @i_tipo_aseg = 2 and @i_tipo_seguro in (2,3)
      begin
      
         select @w_valor_seguros = @w_valor_seguros
      end
      else
      begin   
      
         select @w_valor_plan = ps_valor_mensual
         from cr_plan_seguros_vs  with (nolock)
         where ps_codigo_plan = @i_plan
         and   ps_tipo_seguro = @i_tipo_seguro
         and   ps_estado      = 'V'            
                           
         select @w_valor_seguros = (@w_valor_plan * @w_plazo_mes) + @w_valor_seguros            
      end
      
      if @w_valor_seguros > (@w_monto_sin_seg * (@w_porc_max/100))
      begin
         print 'Mensaje Informativo: Importante - Valor de Primas de Seguros excede al porcentaje maximo de financiacion'
      end     
               
   end
end 

if @i_operacion = 'F'    --Validacion para Asegurados (Boton Salir)
begin
   if @t_trn = 22925
   begin
            
      select as_secuencial_seguro, as_sec_asegurado
      into #temporal
      from cr_seguros_tramite with (nolock), cr_asegurados with (nolock)
      where st_tramite           = @i_tramite
      and   st_tipo_seguro       in (1,2)
      and   st_secuencial_seguro = as_secuencial_seguro
      
      
      insert into #temporal select as_secuencial_seguro, as_sec_asegurado 
      from cr_seguros_tramite with (nolock), cr_asegurados with (nolock)
      where st_tramite           = @i_tramite
      and   st_tipo_seguro       = 3
      and   st_secuencial_seguro = as_secuencial_seguro
      and   as_parentesco        = 'ASP'
      and   as_tipo_aseg         = 1

      delete #temporal
      from cr_beneficiarios with (nolock)
      where as_secuencial_seguro = be_secuencial_seguro
      and   as_sec_asegurado     = be_sec_asegurado

      select top 1 @w_sec_asegurado = as_sec_asegurado, @w_secuencial_seguro = as_secuencial_seguro from #temporal

      if @w_sec_asegurado is not null
      begin
         select
         @w_error = 2110380,
         @w_msg   = re_valor
         from cobis..cl_errores
         inner join cobis..ad_error_i18n
         on  (numero = pc_codigo_int
         and  re_cultura like '%'+replace(upper(@s_culture), '_', '%')+'%')
         where numero = 2110380

         select @w_msg = concat(@w_msg, ' ', cast(@w_secuencial_seguro as varchar))

         goto ERROR
      end
      
      if exists(select 1 from cr_seguros_tramite with (nolock) where st_tramite = @i_tramite and st_tipo_seguro = 3)
      begin
         select @w_valor = count(1)
         from cr_seguros_tramite with (nolock), cr_asegurados with (nolock)
         where st_tramite           = @i_tramite
         and   st_tipo_seguro       = 3 --exequial
         and   st_secuencial_seguro = as_secuencial_seguro
         and   as_parentesco        = 'ASP'
         and   as_tipo_aseg         = 1

         if @w_valor = 0
         begin
            select
            @w_error = 2110381
            goto ERROR
         end
      end
      
      --seguro primera perdida tenga los dos asegurados antes de salir
      if exists(select 1 from cr_seguros_tramite with (nolock) where st_tramite = @i_tramite and st_tipo_seguro = 2)
      begin
         select @w_valor = 0
         select @w_valor = count(1)
         from cr_seguros_tramite with (nolock), cr_asegurados with (nolock)
         where st_tramite           = @i_tramite
         and   st_tipo_seguro       = 2 --primera perdida
         and   st_secuencial_seguro = as_secuencial_seguro

         if @w_valor <> 2
         begin
            select
            @w_error = 2110382
            goto ERROR
         end
      end
   end
end

if @i_operacion = 'P'  -- Determina las fechas de inicio y fin (vigencia) de los seguros nuevos,
begin                  -- seguros cuyo tipo tambien se encuentre asociado a operaciones anteriores del Asegurado.
                       -- Ademas esta operacion determina las fechas de inicio y fin (vigencia) de los seguros nuevos,
                       -- seguros cuyo tipo NO se encuentren asociados a operaciones anteriores del Asegurado.
                       
                       -- Esta operacion es llamada luego del insert de cada asegurado.            
   
   select @w_tipo_tramite = tr_tipo
   from cob_credito..cr_tramite with (nolock)
   where tr_tramite = @i_tramite              
       
   if @w_tipo_tramite <> 'C'
   begin
      -- fecha fin de la operacion nueva
      select @w_plazo               = op_plazo, 
             @w_tipo_plazo          = op_tplazo,
             @w_fecha_ini_op_nueva  = @s_date,
             @w_fecha_fin_op_nueva  = op_fecha_fin          
      from   cob_cartera..ca_operacion with (nolock)
      where  op_tramite = @i_tramite
   end 
   else 
   begin
      select @w_plazo              = tr_plazo, 
             @w_tipo_plazo         = tr_tipo_plazo,
             @w_fecha_ini_op_nueva = li_fecha_inicio,
             @w_fecha_fin_op_nueva = li_fecha_vto
      from   cob_credito..cr_tramite with (nolock),cob_credito..cr_linea with (nolock)
      where  tr_tramite = @i_tramite
      and    tr_tramite = li_tramite
   end
   
   if @i_tflexible = 'N'
   begin
      select @w_numero_dias = pe_factor
      from   cr_periodo with (nolock)
      where  pe_periodo = @w_tipo_plazo

      select @w_plazo = (@w_plazo * @w_numero_dias) / 30  --Plazo en meses
   end
   ELSE
   begin
      select @w_fecha_fin_op_nueva = null

      select @w_fecha_fin_op_nueva = max(dt_fecha)
      from   cob_credito..cr_disponibles_tramite
      where  dt_tramite  = @i_tramite

      if @w_fecha_fin_op_nueva is null
      begin
         select @w_error = 2110383
         goto ERROR
      end

      select @w_plazo       = datediff(MONTH, @w_fecha_ini_op_nueva, @w_fecha_fin_op_nueva)
   end

   /*
   Si existe al menos un Tipo de Seguro Vigente asociado a Operaciones desembolsadas 
   de un Asegurado,se realiza el calculo de las fechas de los nuevos seguros asi:
   Fecha Inicio Cobertura: fecha de finalizacion de la cobertura de
   cada seguro de la operacion anterior, mas un dia.
   Fecha Fin Cobertura: Fecha Inicio Cobertura mas el plazo en meses 
   tomado desde la Fecha Inicio de la Cobertura hasta la fecha
   de finalizacion de la operacion nueva. Hacer esto por cada tipo de seguro.      
   */                                                                 
                               
   select st_tipo_seguro, st_secuencial_seguro, as_sec_asegurado, as_ced_ruc, as_tipo_ced 
   into #asegurados
   from cr_asegurados,cr_seguros_tramite
   where as_secuencial_seguro   = st_secuencial_seguro
   and st_tramite = @i_tramite
   
   if @w_tipo_tramite <> 'R' begin 
	   -- Insertamos los distintos tipos de seguros que pueda tener el cliente en las operaciones anteriores (Revisando en las tablas del nuevo esquema de Seguros)
	   insert into #seguros_cli select distinct B.st_tipo_seguro, B.st_secuencial_seguro               , A.as_sec_asegurado,
												   A.as_ced_ruc    , A.as_tipo_ced, A.as_fecha_ini_cobertura, A.as_fecha_fin_cobertura 
	   from cob_credito..cr_asegurados A with (nolock), 
			cob_credito..cr_seguros_tramite B with (nolock), 
			cob_cartera..ca_operacion with (nolock),
			cob_credito..cr_tramite T with (nolock),
			#asegurados C
	   where as_secuencial_seguro     = B.st_secuencial_seguro
	   and   C.as_ced_ruc             = A.as_ced_ruc
	   and   C.as_tipo_ced            = A.as_tipo_ced
	   and   st_tramite               = op_tramite                               
	   and   st_tramite               = tr_tramite
	   and   tr_estado                <> 'Z'
	   and   tr_tipo                  <> 'R'
	   and   op_estado                not in (6,3)
	   and   op_fecha_ult_proceso     >= convert(varchar(10),@s_date,101)
	   and   op_tramite               <> @i_tramite   
	   and   A.as_fecha_fin_cobertura = (select MAX(as_fecha_fin_cobertura) 
										 from cr_asegurados, cr_seguros_tramite 
										 where as_ced_ruc = A.as_ced_ruc 
										 and   as_tipo_ced = A.as_tipo_ced
										 and   st_tramite           = T.tr_tramite                                     
										 and   T.tr_estado          <> 'Z'
										 and   st_secuencial_seguro = as_secuencial_seguro)         
	   
	   if @@error <> 0 
	   begin
		  select                                                                                                                                                                                                                                                 
		  @w_error = 2110374
		  goto ERROR
	   end  
   end
   else
   begin
       -- Renovaciones
       insert into #seguros_cli select distinct B.st_tipo_seguro, B.st_secuencial_seguro               , A.as_sec_asegurado,
												   A.as_ced_ruc    , A.as_tipo_ced, A.as_fecha_ini_cobertura, A.as_fecha_fin_cobertura 
	   from cob_credito..cr_asegurados A with (nolock), 
			cob_credito..cr_seguros_tramite B with (nolock), 
			cob_cartera..ca_operacion with (nolock),
			cob_credito..cr_tramite T with (nolock),
			#asegurados C
	   where as_secuencial_seguro     = B.st_secuencial_seguro
	   and   C.as_ced_ruc             = A.as_ced_ruc
	   and   C.as_tipo_ced            = A.as_tipo_ced
	   and   st_tramite               = op_tramite                               
	   and   st_tramite               = tr_tramite
	   and   tr_estado                <> 'Z'
	   and   op_estado                not in (6,3)
	   and   op_fecha_ult_proceso     >= convert(varchar(10),@s_date,101)
	   and   convert(varchar(10),@s_date,101) between A.as_fecha_ini_cobertura and A.as_fecha_fin_cobertura
	   and   op_tramite               <> @i_tramite   
	   /*and   A.as_fecha_fin_cobertura = (select MAX(as_fecha_fin_cobertura) 
										 from cr_asegurados, cr_seguros_tramite 
										 where as_ced_ruc = A.as_ced_ruc 
										 and   as_tipo_ced = A.as_tipo_ced
										 and   st_tramite           = T.tr_tramite                                     
										 and   T.tr_estado          <> 'Z'
										 and   st_secuencial_seguro = as_secuencial_seguro)  */
	   
	   if @@error <> 0 
	   begin
		  select                                                                                                                                                                                                                                                 
		  @w_error = 2110374
		  goto ERROR
	   end
   end  
	   
   
   insert into #seguros_cli select distinct B.st_tipo_seguro, B.st_secuencial_seguro               , A.as_sec_asegurado,
                                               A.as_ced_ruc    , A.as_tipo_ced, A.as_fecha_ini_cobertura, A.as_fecha_fin_cobertura 
   from cob_credito..cr_asegurados A with (nolock), 
        cob_credito..cr_seguros_tramite B with (nolock), 
        cob_cartera..ca_operacion with (nolock),
        cob_credito..cr_tramite T with (nolock),
        #asegurados C
   where as_secuencial_seguro     = B.st_secuencial_seguro
   and   C.as_ced_ruc             = A.as_ced_ruc
   and   C.as_tipo_ced            = A.as_tipo_ced
   and   st_tramite               = op_tramite                               
   and   st_tramite               = tr_tramite
   and   tr_estado                <> 'Z'
   and   op_estado                = 3
   and   A.as_fecha_fin_cobertura >= convert(varchar(10),@s_date,101)
   and   op_tramite               <> @i_tramite   
   and   A.as_fecha_fin_cobertura = (select MAX(as_fecha_fin_cobertura) 
                                     from cr_asegurados, cr_seguros_tramite 
                                     where as_ced_ruc = A.as_ced_ruc 
                                     and   as_tipo_ced = A.as_tipo_ced
                                     and   st_tramite           = T.tr_tramite                                     
                                     and   T.tr_estado          <> 'Z'
                                     and   st_secuencial_seguro = as_secuencial_seguro)         
   
   if @@error <> 0 
   begin
      select                                                                                                                                                                                                                                                 
      @w_error = 2110374
      goto ERROR
   end             
      
   -- Insertamos los distintos tipos de seguros que pueda tener el cliente en las operaciones anteriores (Revisando en las tablas del antiguo esquema de Seguros)
   insert into #seguros_cli select distinct convert(int,ms_clase), ms_secuencial, am_secuencial, am_identificacion, am_tipo_iden, 
                                                    ms_fecha_ini , ms_fecha_fin 
   from cob_credito..cr_aseg_microseguro A with (nolock), 
        cob_credito..cr_micro_seguro with (nolock), 
        cob_cartera..ca_operacion with (nolock),
        cob_credito..cr_tramite T with (nolock),
        #asegurados
   where ms_secuencial       = am_microseg
   and   ms_estado           <> 'A'
   and   A.am_identificacion = as_ced_ruc
   and   A.am_tipo_iden      = as_tipo_ced
   and   ms_tramite          = op_tramite                    
   and   ms_tramite          = tr_tramite
   and   tr_estado           <> 'Z'
   and   op_estado           not in (6,3)
   and   op_fecha_ult_proceso >= convert(varchar(10),@s_date,101)
   and   op_tramite          <> @i_tramite
   and   @s_date             between  ms_fecha_ini and ms_fecha_fin      
   and   ms_fecha_fin        = (select MAX(ms_fecha_fin) 
                               from cr_micro_seguro,cr_aseg_microseguro 
                               where ms_secuencial     = am_microseg
                               and   am_secuencial     = A.am_secuencial
                               and   am_identificacion = A.am_identificacion
                               and   am_tipo_iden      = A.am_tipo_iden
                               and   ms_tramite        = T.tr_tramite
                               and   T.tr_estado       <> 'Z')                          
      
   if @@error <> 0 
   begin
      select                                                                                                                                                                                                                                                 
      @w_error = 2110375
      goto ERROR
   end
   
   insert into #seguros_cli select distinct convert(int,ms_clase), ms_secuencial, am_secuencial, am_identificacion, am_tipo_iden, 
                                                    ms_fecha_ini , ms_fecha_fin 
   from cob_credito..cr_aseg_microseguro A with (nolock), 
        cob_credito..cr_micro_seguro with (nolock), 
        cob_cartera..ca_operacion with (nolock),
        cob_credito..cr_tramite T with (nolock),
        #asegurados
   where ms_secuencial       = am_microseg
   and   ms_estado           <> 'A'
   and   A.am_identificacion = as_ced_ruc
   and   A.am_tipo_iden      = as_tipo_ced
   and   ms_tramite          = op_tramite                    
   and   ms_tramite          = tr_tramite
   and   tr_estado           <> 'Z'
   and   op_estado           = 3
   and   op_tramite          <> @i_tramite
   and   @s_date             between  ms_fecha_ini and ms_fecha_fin      
   and   ms_fecha_fin        = (select MAX(ms_fecha_fin) 
                               from cr_micro_seguro,cr_aseg_microseguro 
                               where ms_secuencial     = am_microseg
                               and   am_secuencial     = A.am_secuencial
                               and   am_identificacion = A.am_identificacion
                               and   am_tipo_iden      = A.am_tipo_iden
                               and   ms_tramite        = T.tr_tramite
                               and   T.tr_estado       <> 'Z')                          
      
   if @@error <> 0 
   begin
      select                                                                                                                                                                                                                                                 
      @w_error = 2110375
      goto ERROR
   end
   
   --OBTIENE LA FECHA DE MAXIMA VIGENCIA DE LAS POLIZAS DEL CLIENTE
   select tipo_seg as tipo_seg_aux, ced_ruc as ced_ruc_aux, tipo_ced as tipo_ced_aux, max(fecha_fin_cob) as fecha_fin_aux
   into #seguros_cli_aux
   from #seguros_cli group by tipo_seg, ced_ruc, tipo_ced
   
   delete #seguros_cli
   from #seguros_cli, #seguros_cli_aux
   where tipo_seg      =  tipo_seg_aux
   and   ced_ruc       =  ced_ruc_aux
   and   tipo_ced      =  tipo_ced_aux
   and   fecha_fin_cob <> fecha_fin_aux
   
   update cob_credito..cr_asegurados 
   set as_fecha_ini_cobertura = dateadd(dd,1,fecha_fin_cob),
       as_fecha_fin_cobertura = dateadd(mm,case 
                                        when (dateadd(dd,1,fecha_fin_cob) = dateadd(dd,-1,DATEADD(mm,1,dateadd(dd, 1 - datepart(dd, dateadd(dd,1,fecha_fin_cob)),dateadd(dd,1,fecha_fin_cob))))
                                              and @w_fecha_fin_op_nueva = dateadd(dd,-1,DATEADD(mm,1,dateadd(dd, 1 - datepart(dd, @w_fecha_fin_op_nueva),@w_fecha_fin_op_nueva)))) 
                                              or datepart(dd,dateadd(dd,1,fecha_fin_cob)) <= datepart(dd,@w_fecha_fin_op_nueva)
                                        then datediff(mm,dateadd(dd,1,fecha_fin_cob),@w_fecha_fin_op_nueva)
                                        when (dateadd(dd,1,fecha_fin_cob) <> dateadd(dd,-1,DATEADD(mm,1,dateadd(dd, 1 - datepart(dd, dateadd(dd,1,fecha_fin_cob)),dateadd(dd,1,fecha_fin_cob))))
                                             or  @w_fecha_fin_op_nueva <> dateadd(dd,-1,DATEADD(mm,1,dateadd(dd, 1 - datepart(dd, @w_fecha_fin_op_nueva),@w_fecha_fin_op_nueva))))
                                             and (datepart(dd,dateadd(dd,1,fecha_fin_cob)) > datepart(dd,@w_fecha_fin_op_nueva))
                                        then datediff(mm,dateadd(dd,1,fecha_fin_cob),@w_fecha_fin_op_nueva) - 1
                                        end,dateadd(dd,1,fecha_fin_cob))
   from cob_credito..cr_seguros_tramite A, cr_asegurados B, #seguros_cli C
   where A.st_secuencial_seguro = B.as_secuencial_seguro
   and A.st_tramite   = @i_tramite
   and st_tipo_seguro = tipo_seg
   and B.as_ced_ruc   = C.ced_ruc  
   and B.as_tipo_ced  = C.tipo_ced 

   if @@error <> 0 
   begin
      select                                                                                                                                                                                                                                                 
      @w_error = 2110379
      goto ERROR
   end      
     
   -- Se actualizan las fechas de inicio y fin de cobertura de los tipos de seguros que no estan asociados a operaciones anteriores del cliente.
   -- Fecha Inicio Cobertura: Fecha Inicio de la Nueva Operacion.
   -- Fecha Fin Cobertura: Fecha Inicio Cobertura mas el plazo en meses de la Operacion Nueva
      
   
   select A.st_secuencial_seguro as sec_seguro,
          B.as_sec_asegurado as sec_asegurado
   into #seguros_cli2
   from cob_credito..cr_seguros_tramite A, cr_asegurados B, #seguros_cli C
   where A.st_secuencial_seguro = B.as_secuencial_seguro
   and A.st_tramite   = @i_tramite
   and st_tipo_seguro = tipo_seg
   and B.as_ced_ruc   = C.ced_ruc  
   and B.as_tipo_ced  = C.tipo_ced 
   
   
   delete #asegurados
   from #asegurados,#seguros_cli2
   where st_secuencial_seguro = sec_seguro
   and as_sec_asegurado = sec_asegurado
   
   update cob_credito..cr_asegurados
   set as_fecha_ini_cobertura = @w_fecha_ini_op_nueva,
       as_fecha_fin_cobertura = DATEADD(MM,@w_plazo,@w_fecha_ini_op_nueva)
   from cr_asegurados B,#asegurados C
   where B.as_secuencial_seguro = C.st_secuencial_seguro
   and B.as_sec_asegurado       = C.as_sec_asegurado
   
      
   if @@error <> 0 
   begin
      select                                                                                                                                                                                                                                                 
      @w_error = 2110377
      goto ERROR
   end               
   
   --REQ 00405
  
  /*Las fechas de cobertura del asegurado dependiente deben corresponder con las del asegurado principal.REQ405*/
     
   select  @w_fecha_ini_pri_per = as_fecha_ini_cobertura,
           @w_fecha_fin_pri_per = as_fecha_fin_cobertura 
   from cob_credito..cr_seguros_tramite with (nolock), cob_credito..cr_asegurados with (nolock)
   where st_tramite         = @i_tramite
   and st_secuencial_seguro = as_secuencial_seguro
   and st_tipo_seguro       = 2                         -- SEGURO PRIMERA PERDIDA TITULAR REQ405  
   and as_tipo_aseg         = 1
   
   update cob_credito..cr_asegurados set
   as_fecha_ini_cobertura = @w_fecha_ini_pri_per,  
   as_fecha_fin_cobertura = @w_fecha_fin_pri_per  
   from cob_credito..cr_seguros_tramite, cob_credito..cr_asegurados
   where st_tramite        = @i_tramite
   and st_secuencial_seguro = as_secuencial_seguro
   and st_tipo_seguro       = 2                         -- SEGURO PRIMERA PERDIDA CONYUGE REQ405
   and as_tipo_aseg         = 2
   
   if @@error <> 0 
   begin
      select                                                                                                                                                                                                                                                 
      @w_error = 2110378
      goto ERROR
   end    
     
end

if @i_operacion = 'R'  -- Restriccion de Ingreso al Boton de Beneficiarios
begin

   if @t_trn = 22924
   begin
      if @i_tipo_seguro = 4
      begin
         print 'EL SEGURO DE DANOS NO REQUIERE BENEFICIARIOS'
         select @w_habilita_benef = 'N'
         select @w_habilita_benef
      end
      if @i_tipo_seguro = 3 and @i_parentesco <> 'ASP'
      begin
         print 'EL SEGURO EXEQUIAL SOLO REQUIERE BENEFICIARIOS PARA EL ASEGURADO PRINCIPAL'
         select @w_habilita_benef = 'N'
         select @w_habilita_benef
      end
   end
   
end

return 0

ERROR:
exec cobis..sp_cerror
@t_debug = 'N',
@t_from  = @w_sp_name,
@i_num   = @w_error,
@i_msg   = @w_msg

return @w_error

GO
