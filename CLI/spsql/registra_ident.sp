/************************************************************************/
/*  Archivo:            registra_ident.sp                               */
/*  Stored procedure:   sp_registra_ident                               */
/*  Base de datos:      cobis                                           */
/*  Producto:           Clientes                                        */
/*  Disenado por:       JMEG                                            */
/*  Fecha de escritura: 30-Abril-19                                     */
/************************************************************************/
/*                              IMPORTANTE                              */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*  de COBISCorp.                                                       */
/*  Su uso no    autorizado queda  expresamente   prohibido asi como    */
/*  cualquier    alteracion o  agregado  hecho por    alguno  de sus    */
/*  usuarios sin el debido consentimiento por   escrito de COBISCorp.   */
/*  Este programa esta protegido por la ley de   derechos de autor      */
/*  y por las    convenciones  internacionales   de  propiedad inte-    */
/*  lectual.   Su uso no  autorizado dara  derecho a    COBISCorp para  */
/*  obtener ordenes  de secuestro o  retencion y para  perseguir        */
/*  penalmente a los autores de cualquier   infraccion.                 */
/************************************************************************/
/*              PROPOSITO                                               */
/*  Registrar historicamente los cambios de identificaci¢n de clientes  */
/************************************************************************/
/*                    MODIFICACIONES                                    */
/*  FECHA            AUTOR           RAZON                              */
/*  30/04/19         JMEG         Emision Inicial                       */
/*  12/06/20         FSAP         Estandarizacion de Clientes           */
/*  15/10/20         MBA          Uso de la variable @s_culture         */
/************************************************************************/
use cobis
go
if exists (select * from sysobjects where name = 'sp_registra_ident')
   drop proc sp_registra_ident
go
set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go
   
create proc sp_registra_ident (  
       @s_ssn             int         = null,             
       @s_user            login       = null,
       @s_sesn            int         = null,
       @s_term            varchar(32) = null,
       @s_date            datetime    = null,
       @s_srv             varchar(30) = null,
       @s_lsrv            varchar(30) = null,
       @s_rol             smallint    = null,
       @s_ofi             smallint    = null,
       @s_org_err         char(1)     = null,
       @s_error           int         = null,
       @s_sev             tinyint     = null,
       @s_msg             descripcion = null,
       @s_org             char(1)     = null,
	   @s_culture         varchar(10) = 'NEUTRAL',	   
       @t_debug           char(1)     = 'N',
       @t_file            varchar(14) = null,
       @t_from            varchar(32) = null,
       @t_trn             int         = null,
       @t_show_version    bit         = 0,      --Versionamiento
       -----------------------------------------
       @i_operacion       char(1)     = null,   --Operacion: (I) Insert (S) Search 
       @i_modo            int         = null,
       @i_ente            int         = null,
       @i_ente_sec        int         = null,
       @i_tipo_iden       char(4)     = null,
       @i_identificacion  numero      = null,
       @i_fecha_ini       datetime    = null,
       @i_fecha_fin       datetime    = null,
       @i_formato_fecha   int         = 103
)
as
declare 
       @w_sp_name         varchar(32),
       @w_sp_msg          varchar(132),
       @w_error           int,
       @w_fecha           datetime,
       @w_hora            datetime,      
       @w_nom_user        varchar(80),
       @w_nombre          varchar(150),
       @w_tablas          varchar(250),
       @w_columnas        varchar(5000),
       @w_criterio        varchar(3000),
       @w_ordenamiento    varchar(250),
       @w_and             varchar(10),
       @w_fecha_hoy       datetime
          
select @w_sp_name   = 'sp_registra_ident'

--* VERSIONAMIENTO 
--VERSIONAMIENTO DE SP
if @t_show_version = 1
begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end

---- EJECUTAR SP DE LA CULTURA ---------------------------------------  
exec cobis..sp_ad_establece_cultura
        @o_culture = @s_culture out


 --* INSERTA EN EL REGISTRO
if @i_operacion = 'I' 
begin
  --* AUTORIZACION
  if (@t_trn <> 172006) 
  begin
    exec cobis..sp_cerror
      @t_debug  = 'N',         
      @t_file   = null,
      @t_from   = @w_sp_name,  
      @i_num    = 1720075 --Transaccion no permitida--                         
      return 1           
  end 

  ------------------------------------------------------------------------------
  --* :: P e r s o n a s   n a t u r a l e s   o   J u r ¡ d i c a s
  ------------------------------------------------------------------------------
  --* Obtengo el nombre del usuario
  
  select @w_nom_user = fu_nombre 
    from cl_funcionario
  where fu_login = @s_user
  
  if @@rowcount = 0
  begin
    exec cobis..sp_cerror
      @t_debug  = 'N',         
      @t_file   = null,
      @t_from   = @w_sp_name,  
      @i_num    = 1720071, --No existe funcionario--
      @i_cuenta = ' '
    return 1
  end
  
  --* Bitacoriza
  begin tran
    
    select @w_fecha = getdate()
    select @w_fecha_hoy =  fp_fecha 
      from cobis..ba_fecha_proceso
  
    insert into cl_registro_identificacion(
                ri_ente,              ri_tipo_iden,              ri_identificacion,
                ri_fecha_act,         ri_hora_act,               ri_usuario,
                ri_nom_usuario)
        values  (
                @i_ente,              @i_tipo_iden,              @i_identificacion,
                @w_fecha_hoy,         @w_fecha,                  @s_user,
                @w_nom_user)
          --* Verificamos el error
    if @@error <> 0
      begin
        rollback tran
          exec cobis..sp_cerror
            @t_debug = 'N',         
            @t_file  = null,
            @t_from  = @w_sp_name,  
            @i_num   =  1720072,--Error al insertar en la tabla de registro de identificaciones--
            @i_cuenta= ' '
          return 1
        end
      
  commit tran                                      
                        
end
 
--* CONSULTA 
if @i_operacion = 'S' 
begin
  set rowcount 20 
  --* AUTORIZACION
  if (@t_trn <> 172007) 
  begin
    exec cobis..sp_cerror
      @t_debug = 'N',         
      @t_file  = null,
      @t_from  = @w_sp_name,  
      @i_num   = 1720075 --Transaccion no permitida--                         
    return 1           
  end 

  select @w_fecha = getdate()
  --* Validaciones de fechas
  if @i_fecha_ini is not null and @i_fecha_fin is null 
     select @i_fecha_fin = @i_fecha_ini
  if @i_fecha_fin is not null and @i_fecha_ini is null 
     select @i_fecha_ini = @i_fecha_fin
  if (@i_fecha_fin is not null and @i_fecha_ini is not null)
  begin
    if (@i_fecha_fin < @i_fecha_ini or @i_fecha_ini > @i_fecha_fin) 
    begin
      exec cobis..sp_cerror
        @t_debug = 'N',         
        @t_file  = null,
        @t_from  = @w_sp_name,  
        @i_num   =  1720073 --Fechas incongruentes--                         
      return 1           
    end
  end

  if @i_modo = 0 --* Trae los primeros 20 registros
  begin
    select @w_columnas = "select 'No.' = ri_ente,
                                 'Tipo Ident.' = ri_tipo_iden,
                                 'Ident.'      = ri_identificacion,
                                  'Fecha Act.'  = convert(char(12), ri_fecha_act,@i_formato_fecha),
                                 'Hora Act.'   = convert(char(12), ri_hora_act,108),
                                 'Usuario'     = ri_usuario,
                                 'Nombre Usua' = ri_nom_usuario
                            from cl_registro_identificacion "
    --* Where
    if (@i_ente is not null or @i_identificacion is not null or 
       (@i_fecha_ini is not null and @i_fecha_fin is not null))
    select @w_columnas = @w_columnas + " where "
 
    --* Verifica si el ente es nulo
    if @i_ente is not null 
    begin         
        select @w_columnas = @w_columnas + @w_and + " " + "ri_ente = "+ convert(varchar(10),@i_ente) 
        select @w_and = " and "
    end

    --* Verifica si la identificacion es nula
    if @i_identificacion is not null 
    begin         
      select @w_columnas = @w_columnas + @w_and + " " + " ri_identificacion ='" + @i_identificacion + "'"
      select @w_and = " and "
    end

    --* Verifica el rango de fechas
    if (@i_fecha_ini is not null and @i_fecha_fin is not null)
    begin         
      --select @w_columnas = @w_columnas + @w_and + " " + " convert(varchar(12),ri_fecha_act,@i_formato_fecha) >= '" + convert(varchar(12),@i_fecha_ini,@i_formato_fecha) +"'"
      --select @w_columnas = @w_columnas + " and " + " convert(varchar(12),ri_fecha_act,@i_formato_fecha) <= '" + convert(varchar(12),@i_fecha_fin,@i_formato_fecha) +"'"
      select @w_columnas = @w_columnas + @w_and + " " + " ri_fecha_act >= '" + convert(varchar(12),@i_fecha_ini) +"'"
      select @w_columnas = @w_columnas + " and " + " ri_fecha_act <= '" + convert(varchar(12),@i_fecha_fin) +"'"
    end

    --* Ordena por id de ente
    select @w_columnas = @w_columnas + " order by ri_ente"
    goto BUSQUEDA
  end   

  if @i_modo = 1 --* Trae los siguientes 20 registros
  begin
    select @w_columnas = "select 'No.' = ri_ente,
                                 'Tipo Ident.' = ri_tipo_iden,
                                 'Ident.'      = ri_identificacion,
                                 'Fecha Act.'  = convert(char(12), ri_fecha_act,@i_formato_fecha),
                                 'Hora Act.'   = convert(char(12), ri_hora_act,108),
                                 'Usuario'     = ri_usuario,
                                 'Nombre Usua' = ri_nom_usuario
                            from cl_registro_identificacion "
    --* Where
    select @w_columnas = @w_columnas + " where "
    select @w_columnas = @w_columnas + "ri_ente > "+ convert(varchar(10),@i_ente_sec) 
 
    --* Verifica el rango de fechas
    if (@i_fecha_ini is not null and @i_fecha_fin is not null)
    begin    
      select @w_and = " and "        
      --select @w_columnas = @w_columnas + @w_and + " " + " convert(varchar(12),ri_fecha_act,@i_formato_fecha) >= '" + convert(varchar(12),@i_fecha_ini,@i_formato_fecha) +"'"
      --select @w_columnas = @w_columnas + " and " + " convert(varchar(12),ri_fecha_act,@i_formato_fecha) <= '" + convert(varchar(12),@i_fecha_fin,@i_formato_fecha) +"'"
      select @w_columnas = @w_columnas + @w_and + " " + " ri_fecha_act >= '" + convert(varchar(12),@i_fecha_ini) +"'"
      select @w_columnas = @w_columnas + " and " + " ri_fecha_act <= '" + convert(varchar(12),@i_fecha_fin) +"'"
    end

    --* Ordena por id de ente
    select @w_columnas = @w_columnas + " order by ri_ente"
    goto BUSQUEDA
  end   
end   

return 0

-----------------------------------------------------
--********** E R R O R ****************************--
-----------------------------------------------------
BUSQUEDA:
  execute (@w_columnas)

  if @@rowcount = 0
  begin
    exec sp_cerror
      @t_debug    = @t_debug,
      @t_file     = @t_file,
      @t_from     = @w_sp_name,
      @i_num      = 1720074,
      @s_culture  = @s_culture
      /* 'No existe dato solicitado'*/
    return 1
  end
go
