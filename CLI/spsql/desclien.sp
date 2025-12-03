/************************************************************************/
/*  Archivo           :   desclien.sp                                   */
/*  Stored procedure  :   sp_desc_cliente                               */
/*  Base de datos     :   cobis                                         */
/*   Producto:                CLIENTES                                   */
/*   Disenado por:  RIGG   				                                 */
/*   Fecha de escritura: 30-Abr-2019                                     */
/************************************************************************/
/*              IMPORTANTE                                              */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*  de 'COBISCorp'.                                                     */
/*  Su uso no    autorizado queda  expresamente   prohibido asi como    */
/*  cualquier    alteracion o  agregado  hecho por    alguno  de sus    */
/*  usuarios sin el debido consentimiento por   escrito de COBISCorp.   */
/*  Este programa esta protegido por la ley de   derechos de autor      */
/*  y por las    convenciones  internacionales   de  propiedad inte-    */
/*  lectual.    Su uso no  autorizado dara  derecho a    COBISCorp para */
/*  obtener ordenes  de secuestro o  retencion y para  perseguir        */
/*  penalmente a los autores de cualquier   infraccion.                 */
/************************************************************************/
/*              PROPOSITO                                               */
/*      Encuentra la cedula o RUC, nombre y tipo de un ente             */
/*      dado el codigo de un cliente                                    */
/************************************************************************/
/*               MODIFICACIONES                                          */
/*   FECHA       	AUTOR                RAZON                           */
/*   30/Abr/2019   	RIGG	             Versión Inicial Te Creemos      */
/************************************************************************/
use cobis
go

set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO

if exists (select
             1
           from   sysobjects
           where  name = 'sp_desc_cliente')
  drop proc sp_desc_cliente
go

create proc sp_desc_cliente
(
  @s_ssn          int = null,
  @s_user         login = null,
  @s_term         varchar(30) = null,
  @s_date         datetime = null,
  @s_srv          varchar(30) = null,
  @s_lsrv         varchar(30) = null,
  @s_rol          smallint = null,
  @s_ofi          smallint = null,
  @s_org_err      char(1) = null,
  @s_error        int = null,
  @s_sev          tinyint = null,
  @s_msg          descripcion = null,
  @s_org          char(1) = null,
  @t_debug        char(1) = 'N',
  @t_file         varchar(14) = null,
  @t_from         varchar(32) = null,
  @t_trn          smallint = null,
  @t_show_version bit = 0,
  @i_operacion    char(2),
  @i_cliente      int = null
)
as
  declare
    @w_sp_name    varchar(30),
    @w_cliente    int,
    @w_alianza    int,
    @w_desalianza varchar(255)

  /*  Inicializa Variables  */
  select
    @w_sp_name = 'sp_desc_cliente'

/**************/
/* VERSION    */
  /**************/
  if @t_show_version = 1
  begin
    print 'Stored Procedure= ' + @w_sp_name + ' Version= ' + '4.0.0.0'
    return 0
  end

  /*  Encuentra la descripcion de un cliente  */
  if @i_operacion = 'Q'
  begin
    if @t_trn = 1181
    begin
      select
        'D.I. o NIT.' = en_ced_ruc,
        'Nombre' = p_p_apellido + ' ' + p_s_apellido + ' ' + en_nombre,
        'Tipo' = en_subtipo,
        'Pasaporte' = p_pasaporte,
        'Accion Cliente' = (select
                              case codigo
                                when 'NIN' then ''
                                else valor
                              end
                            from   cobis..cl_catalogo
                            where  tabla in
                                   (select
                                      codigo
                                    from   cobis..cl_tabla
                                    where  tabla = 'cl_accion_cliente')
                                   and codigo = X.en_accion)
      from   cobis..cl_ente X
      where  en_ente = @i_cliente

      if @@rowcount = 0
      begin
        exec cobis..sp_cerror
          /*error, no existe cliente */
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 101042
        return 1
      end

      select
        @w_alianza = al_alianza,
        @w_desalianza = isnull((al_nemonico + ' - ' + al_nom_alianza),
                               '  ')
      from   cobis..cl_alianza_cliente with (nolock),
             cobis..cl_alianza with (nolock)
      where  ac_ente    = @i_cliente
         and ac_alianza = al_alianza
         and al_estado  = 'V'
         and ac_estado  = 'V'

      select
        @w_alianza

      select
        @w_desalianza

      return 0
    end
    else
    begin
      exec sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = 151051
      /*  'No corresponde codigo de transaccion' */
      return 1
    end
  end

  /* Descripcion y tipo de ente */
  if @i_operacion = 'H'
  begin
    if @t_trn = 1225
    begin
      select
        en_nombre + ' ' + p_p_apellido + ' ' + p_s_apellido,
        en_subtipo
      from   cl_ente
      where  en_ente = @i_cliente

      if @@rowcount = 0
      begin
        /*  No existe cliente  */
        exec cobis..sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 101146
        return 1
      end
    end
    else
    begin
      exec sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = 151051
      /*  'No corresponde codigo de transaccion' */
      return 1
    end
  end
  return 0

go

