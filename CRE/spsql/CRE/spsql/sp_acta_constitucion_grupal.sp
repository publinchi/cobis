/********************************************************************/
/*   NOMBRE LOGICO:         sp_acta_constitucion_grupal             */
/*   NOMBRE FISICO:         sp_acta_constitucion_grupal.sp          */
/*   BASE DE DATOS:         cob_credito                             */
/*   PRODUCTO:              CREDITO                                 */
/*   DISENADO POR:          Dilan Morales                           */
/*   FECHA DE ESCRITURA:    07-Feb-2023                             */
/********************************************************************/
/*                     IMPORTANTE                                   */
/*   Este programa es parte de los paquetes bancarios que son       */
/*   comercializados por empresas del Grupo Empresarial TOPAZ,      */
/*   representantes exclusivos para comercializar los productos y   */
/*   licencias de TOPAZ TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las         */
/*   correspondientes de la Unión Europea. Su copia, reproducción,  */
/*   alteración en cualquier sentido, ingeniería reversa,           */
/*   almacenamiento o cualquier uso no autorizado por cualquiera    */
/*   de los usuarios o personas que hayan accedido al presente      */
/*   sitio, queda expresamente prohibido; sin el debido             */
/*   consentimiento por escrito, de parte de los representantes de  */
/*   TOPAZ TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la  */
/*   propiedad intelectual y la confidencialidad de la información  */
/*   tratada; y por lo tanto, derivará en acciones legales civiles  */
/*   y penales en contra del infractor según corresponda.”.         */
/********************************************************************/
/*                     PROPOSITO                                    */
/*   Texto descriptivo                                              */
/********************************************************************/
/*                     MODIFICACIONES                               */
/*   FECHA              AUTOR              RAZON                    */
/*   07-Feb-2023        D. Morales.       Emision Inicial           */
/*   16-Nov-2023        B. Duenas.       R219497:Se agrega apellido */
/*   10-Abr-2025        GRO              R264287-Fecha Actualizacion*/
/*                                               Junta Directiva    */
/********************************************************************/
use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_acta_constitucion_grupal')
   drop proc sp_acta_constitucion_grupal
go

CREATE proc sp_acta_constitucion_grupal (
    @s_ssn                  int             = null,
    @s_sesn                 int             = null,
    @s_culture              varchar(10)     = null,
    @s_user                 login           = null,
    @s_term                 varchar(30)     = null,
    @s_date                 datetime        = null,
    @s_srv                  varchar(30)     = null,
    @s_lsrv                 varchar(30)     = null,
    @s_ofi                  smallint        = null,
    @s_rol                  smallint        = NULL,
    @s_org_err              char(1)         = NULL,
    @s_error                int             = NULL,
    @s_sev                  tinyint         = NULL,
    @s_msg                  descripcion     = NULL,
    @s_org                  char(1)         = NULL,
    @t_show_version         bit             = 0,
    @t_debug                char(1)         = 'N',
    @t_file                 varchar(10)     = null,
    @t_from                 varchar(32)     = null,
    @t_trn                  int             = null,
	@i_tramite              int             = null,
    @i_operacion            char(1),                -- Opcion con que se ejecuta el programa  
    @i_tipo                 char(1),    
    @i_id_ente              int             = null
)
as
declare @w_sp_name              varchar(32),
        @w_sp_msg               varchar(132),
        @w_error                int,
        @w_trn                  int,
        @w_grupo                int,
        @w_ente_filial          int
        
        
declare @w_tabla_usuarios as table(
                                  nombre_completo      varchar(255),
                                  rol                  char(1),
                                  orden                int default 0)
        
select @w_sp_name = 'sp_acta_constitucion_grupal',
       @w_trn     = isnull(@t_trn,21866)
       
---- VERSIONAMIENTO DEL PROGRAMA -------------------------------------------
if @t_show_version = 1
begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.2')
  print  @w_sp_msg
  return 0
end
       
if(@i_operacion = 'Q')
begin 
    if(@i_tramite is null)
    begin
        select @w_error = 2110400
        goto ERROR
    end

    

    if not exists (select 1 from cob_credito..cr_tramite where tr_tramite = @i_tramite)
    begin
        select @w_error = 2110152
        goto ERROR
    end 
    
    if(@i_tipo = 'F')
    begin
    
        select @w_ente_filial   = pa_int    from cobis..cl_parametro  where pa_nemonico = 'CCFILI' and pa_producto = 'ADM'
        select @w_grupo         = tg_grupo  from cob_credito..cr_tramite_grupal where tg_tramite = @i_tramite

        
        SET LANGUAGE Spanish
        select 
        'DIA REUNION'           = datename(weekday , gr_fecha_modificacion)  + '-' +datename(day , gr_fecha_modificacion) ,
        'HORA REUNION'          = Format(gr_hora_reunion, 'hh:mm tt' , 'en-US'),
        'MES REUNION'           = datename(month, gr_fecha_modificacion),
        'ANIO REUNION'          = datename(year , gr_fecha_modificacion),
        'DIRECCION REUNION'     = gr_dir_reunion, 
        'MUNICIPIO'             = (select top 1  C.valor from cobis..cl_catalogo C with(nolock) inner join cobis..cl_tabla  T with(nolock)
                                    on C.tabla = T.codigo  where T.tabla = 'cl_oficina' and C.codigo = gr_sucursal ),
        'NOMBRE GRUPO'          = gr_nombre,
        'NOMBRE PRESIDENTE'     = (select isnull(en_nombre + ' ','') + isnull(p_s_nombre + ' ','') + isnull(p_p_apellido + ' ','') + isnull(p_s_apellido + ' ','') + isnull(trim(p_c_apellido), '')
                                    from cobis..cl_cliente_grupo inner join cobis..cl_ente on cg_ente = en_ente where cg_grupo = gr_grupo and cg_rol = 'P'),
        'NOMBRE TESORERO'       = (select isnull(en_nombre + ' ','') + isnull(p_s_nombre + ' ','') + isnull(p_p_apellido + ' ','') + isnull(p_s_apellido + ' ','') + isnull(trim(p_c_apellido), '')
                                    from cobis..cl_cliente_grupo inner join cobis..cl_ente on cg_ente = en_ente where cg_grupo = gr_grupo and cg_rol = 'T'),
        'NOMBRE SECRETARIO'     = (select isnull(en_nombre + ' ','') + isnull(p_s_nombre + ' ','') + isnull(p_p_apellido + ' ','') + isnull(p_s_apellido + ' ','') + isnull(trim(p_c_apellido), '')
                                    from cobis..cl_cliente_grupo inner join cobis..cl_ente on cg_ente = en_ente where cg_grupo = gr_grupo and cg_rol = 'S'),
        'TELEFONO FILIAL'       = (select top 1 te_valor from cobis..cl_direccion inner join cobis..cl_telefono on di_ente = te_ente
                                    where di_ente = @w_ente_filial  and di_direccion  = 1),
        'NOMBRE FILIAL'         = (select top 1 fi_nombre from cobis..cl_filial where fi_filial = 1)
        from cobis..cl_grupo where gr_grupo = @w_grupo 
    end
    
    if(@i_tipo = 'I')
    begin
        insert into @w_tabla_usuarios
        (nombre_completo,               
        rol)
        select 
        isnull(trim(en_nombre) + ' ' , '')  + isnull(trim(p_s_nombre)  + ' ', '') + isnull(trim(p_p_apellido) + ' ', '')  + isnull(trim(p_s_apellido) + ' ', '') + isnull(trim(p_c_apellido), ''),
        (select cg_rol from cobis..cl_cliente_grupo where  cg_ente = en_ente and cg_grupo = tg_grupo)
        from cobis..cl_ente,
        cob_credito..cr_tramite_grupal  
        where  tg_tramite = @i_tramite 
        and en_ente = tg_cliente
        
        
        update @w_tabla_usuarios
        set orden = 1
        where rol = 'P'
        
        update @w_tabla_usuarios
        set orden = 2
        where rol = 'T'
        
         update @w_tabla_usuarios
        set orden = 3
        where rol = 'S'
        
        update @w_tabla_usuarios
        set orden = 4
        where rol not in ('P' , 'S' , 'T')
        
        select 'NOMBRE COMPLETO' = nombre_completo from @w_tabla_usuarios order by orden asc 
    end
end

return 0

ERROR:
    exec cobis..sp_cerror
     @t_debug = @t_debug,
     @t_file  = @t_file,
     @t_from  = @w_sp_name,
     @i_num   = @w_error
    return @w_error
go
