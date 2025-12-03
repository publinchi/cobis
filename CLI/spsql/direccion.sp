/************************************************************************/
/*   Archivo:               direccion.sp                                */
/*   Stored procedure:      sp_direccion                                */
/*   Base de datos:         cobis                                       */
/*   Producto:              Clientes                                    */
/*   Disenado por:          JMEG                                        */
/*   Fecha de escritura:    30-Abril-19                                 */
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
/*               PROPOSITO                                              */
/*   Este programa procesa las transacciones                            */
/*   DML de direcciones                                                 */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*      FECHA           AUTOR           RAZON                           */
/*      30/04/19         JMEG         Emision Inicial                   */
/*      23/06/20         FSAP         Estandarizacion Clientes          */
/************************************************************************/
use cobis
go
set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1
           from   sysobjects
           where  name = 'sp_direccion')
           drop proc sp_direccion
go
create proc sp_direccion
(
  @s_ssn           int,
  @s_user          varchar(14) = null,
  @s_term          varchar(30) = null,
  @s_date          datetime,
  @s_srv           varchar(30) = null,
  @s_ofi           smallint = null,
  @s_rol           smallint = null,
  @t_debug         char(1) = 'N',
  @t_file          varchar(10) = null,
  @t_from          varchar(32) = null,
  @t_trn           int = null,
  @t_show_version  bit = 0,
  @i_modo          smallint = null,
  @i_operacion     char(1),
  @i_provincia     smallint = null,
  @i_ciudad        int = null,
  @i_direccion     varchar(40) = null,
  @i_tipo          varchar(3) = null,
  @i_valor         varchar(64) = null,
  --nuevo parametro de localidad 24-04-2019
  @i_localidad     varchar(20) = null
)
as
  declare
    @w_transaccion int,
    @w_sp_name     varchar(32),
    @w_sp_msg      varchar(132),
    @w_codigo      int,
    @w_error       int,
    @w_return      int

  select
    @w_sp_name = 'sp_direccion'


---- VERSIONAMIENTO DEL PROGRAMA -------------------------------------------
if @t_show_version = 1
begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end

if (@t_trn = 172053 and @i_operacion != 'Q') or
   (@t_trn = 172052 and @i_operacion != 'L')
   begin
      exec sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = 1720075
      /*  'No corresponde codigo de transaccion' */
      return 1
   end
   
  /** Query **/

  if @t_trn = 172053
  begin
    if @i_operacion = 'Q'
    begin
      set rowcount 20
      if @i_modo = 0
      begin
        select
          'NOMBRE' = substring(en_nomlar,
                               1,
                                                50),
          'IDENTIFICACION' = substring(en_ced_ruc,
                                       1,
                                       15),
          'DIRECCION' = substring(di_descripcion,
                                  1,
                                  30),
          'TIPO' = substring(x.valor,
                             1,
                             15),
          'AREA DIR.' = di_rural_urb
        from   cl_ente,
               cl_direccion,
               cl_catalogo x,
               cl_tabla y
        where  di_descripcion like @i_valor
           and en_ente      = di_ente
           and di_provincia = @i_provincia
           and di_ciudad    = @i_ciudad
           and y.tabla      = 'cl_tdireccion'
           and x.tabla      = y.codigo
           and di_tipo      = x.codigo
           and (di_tipo      = @i_tipo
                 or @i_tipo is null)
        order  by di_descripcion

        if @@rowcount = 0
        begin
          exec sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file,
            @t_from  = @w_sp_name,
            @i_num   = 1720074
          /* 'No existe dato solicitado'*/
          set rowcount 0
          return 1
        end
        set rowcount 0
      end
      if @i_modo = 1
      begin
        select
          'NOMBRE' = substring(en_nomlar,
                               1,
                               50),
          'IDENTIFICACION' = substring(en_ced_ruc,
                                       1,
                                       15),
          'DIRECCION' = substring(di_descripcion,
                                  1,
                                  30),
          'TIPO' = substring(x.valor,
                             1,
                             15),
          'AREA DIR.' = di_rural_urb
        from   cl_ente,
               cl_direccion,
               cl_catalogo x,
               cl_tabla y
        where  substring(di_descripcion,
                         1,
                         40) > @i_direccion
           and di_descripcion like @i_valor
           and en_ente                        = di_ente
           and di_provincia                   = @i_provincia
           and di_ciudad                      = @i_ciudad
           and y.tabla                        = 'cl_tdireccion'
           and x.tabla                        = y.codigo
           and di_tipo                        = x.codigo
           and (di_tipo                        = @i_tipo
                 or @i_tipo is null)
        order  by di_descripcion

        if @@rowcount = 0
        begin
          exec sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file,
            @t_from  = @w_sp_name,
            @i_num   = 1720074
          /* 'No existe dato solicitado'*/
          set rowcount 0
          return 1
        end
        set rowcount 0
      end
      return 0
    end
    --else 
    
    /*
    else
    begin
      exec sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = 1720075
      -- 'No corresponde codigo de transaccion' 
      return 1
    end
    */
  end
  
  
  if @i_operacion = 'L'
    begin

      if @i_ciudad is not null and @i_localidad is null
      begin
        select  lo_localidad,lo_desc_localidad
        from cobis..cl_localidad
        where  lo_ciudad = @i_ciudad 
    order by lo_desc_localidad
      end
    else if @i_ciudad is not null and @i_localidad is not null
      begin
        select  lo_localidad,lo_desc_localidad
        from cobis..cl_localidad
        where  lo_ciudad = @i_ciudad and upper(lo_desc_localidad) like '%'+upper(@i_localidad)+'%'
    order by lo_desc_localidad
      end
      else 
      begin
      exec cobis..sp_cerror
               @t_debug    = 'N',
               @t_file     = null,
               @t_from     = @w_sp_name,
               @i_num      = 1720274
      end

    end
  
  
  return 0

go

