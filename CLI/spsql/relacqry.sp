/************************************************************************/
/*  Archivo:                relacqry.sp                                 */
/*  Stored procedure:       sp_relacion_qry                             */
/*  Base de datos:          cobis                                       */
/*  Producto:               Clientes                                    */
/*  Disenado por:           JMEG                                        */
/*  Fecha de escritura:     30-Abril-19                                 */
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
/*  Este stored procedure procesa las siguientes consultas:             */
/*  Dada una relacion, las instancias de esa relacion                   */
/*  Dado un cliente y relacion la instancias en la que figura           */
/*  Dado un cliente las relaciones que tiene                            */
/*  Dado dos clientes, las relaciones que tiene                         */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*  FECHA           AUTOR        RAZON                                  */
/*  30/04/19        JMEG         Emision Inicial                        */
/*  26/06/20        FSAP         Estandarizacion de Clientes            */
/************************************************************************/
use cobis
go
set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1 
             from sysobjects 
            where name = 'sp_relacion_qry')
   drop proc sp_relacion_qry 
go

create proc sp_relacion_qry
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
  @t_debug        char (1) = 'N',
  @t_file         varchar (14) = null,
  @t_from         varchar (30) = null,
  @t_trn          int = null,
  @t_show_version bit = 0,
  @i_operacion    char (1),
  @i_modo         tinyint = null,
  @i_relacion     int = null,
  @i_izquierda    int = null,
  @i_derecha      int = null
)
as
  declare @w_sp_name     varchar (30),
          @w_sp_msg      varchar(130)

/*  Captura nombre de Stored Procedure  */
select
  @w_sp_name = 'sp_relacion_qry'

---- VERSIONAMIENTO DEL PROGRAMA -------------------------------------------
if @t_show_version = 1
begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end

/* todos los datos se entregan de 20 en 20 */
set rowcount 20

if @i_operacion = 'S'
/* Dada una relacion, despliega las instancias de esta relacion de 20 en 20 */
begin
  if @t_trn = 172073
  begin
    if @i_modo = 0
      select
        'Cod. Cli. I.' = in_ente_i,
        'Cliente Izq' = substring(convert (char(64), a.en_nomlar),
                                  1,
                                  25),
        'Relacion' = substring(convert (char(64), re_izquierda),
                               1,
                               25),
        'Cod. Cli. D.' = in_ente_d,
        'Cliente Der' = substring(convert (char(64), b.en_nomlar),
                                  1,
                                  25)
      from   cl_relacion,
             cl_instancia,
             cl_ente a,
             cl_ente b
      where  re_relacion = @i_relacion
         and in_relacion = @i_relacion
         and in_relacion = re_relacion
         and in_ente_i   = a.en_ente
         and in_ente_d   = b.en_ente
         and in_lado     = 'I'
      order  by in_ente_i,
                in_ente_d
    if @i_modo = 1
    begin
      select
        'Cod. Cli. I.' = in_ente_i,
        'Cliente Izq' = substring(convert (char(64), a.en_nomlar),
                                  1,
                                  25),
        'Relacion' = substring(convert (char(64), re_izquierda),
                               1,
                               25),
        'Cod. Cli. D.' = in_ente_d,
        'Cliente Der' = substring(convert (char(64), b.en_nomlar),
                                  1,
                                  25)
      from   cl_relacion,
             cl_instancia,
             cl_ente a,
             cl_ente b
      where  re_relacion = @i_relacion
         and in_relacion = @i_relacion
         and in_relacion = re_relacion
         and in_ente_i   = a.en_ente
         and in_ente_d   = b.en_ente
         and in_lado     = 'I'
         and ((in_ente_i > @i_izquierda)
               or (in_ente_i   = @i_izquierda
                   and in_ente_d   > @i_derecha))
      order  by in_ente_i,
                in_ente_d
      if @@rowcount = 0
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720304
        /* 'No existe dato solicitado'*/
        return 1
      end
    end
    return 0

  end
  else
  begin
    exec sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file,
      @t_from  = @w_sp_name,
      @i_num   = 1720305
    /*  'No corresponde codigo de transaccion' */
    return 1
  end
end

if @i_operacion = 'Q'
begin
  if @t_trn = 172070
  begin
    /* Dado un cliente y la relacion, despliega las instancias en la que figura el
      cliente  de 20 en 20*/
    if @i_modo = 0
    begin
      select
        'Rel. Izq.' = substring(convert (char(64), re_izquierda),
                                1,
                                25),
        'Rel. Der.' = substring(convert (char(64), re_derecha),
                                1,
                                25),
        'Lado' = in_lado,
        'Cod. Cli.' = in_ente_d,
        'Cliente' = substring(convert (char(64), en_nomlar),
                              1,
                              25)
      from   cl_relacion,
             cl_instancia,
             cl_ente
      where  re_relacion = @i_relacion
         and in_relacion = @i_relacion
         and in_ente_i   = @i_izquierda
         and in_relacion = re_relacion
         and in_ente_d   = en_ente
      order  by in_ente_d
    end
    if @i_modo = 1
    begin
      select
        'Rel. Izq.' = substring(convert (char(64), re_izquierda),
                                1,
                                25),
        'Rel. Der.' = substring(convert (char(64), re_derecha),
                                1,
                                25),
        'Lado' = in_lado,
        'Cod. Cli.' = in_ente_d,
        'Cliente' = substring(convert (char(64), en_nomlar),
                              1,
                              25)
      from   cl_relacion,
             cl_instancia,
             cl_ente
      where  re_relacion = @i_relacion
         and in_relacion = @i_relacion
         and in_ente_i   = @i_izquierda
         and in_relacion = re_relacion
         and in_ente_d   = en_ente
         and in_ente_d   > @i_derecha
      order  by in_ente_d
      if @@rowcount = 0
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720304
        /* 'No existe dato solicitado'*/
        return 1
      end
    end
    return 0

  end
  else
  begin
    exec sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file,
      @t_from  = @w_sp_name,
      @i_num   = 1720305
    /*  'No corresponde codigo de transaccion' */
    return 1
  end

end

if @i_operacion = 'H'
begin
  if @t_trn = 172071 or @t_trn = 139
  begin
    /* Dado un cliente las relaciones en las que figura */
    if @i_modo = 0
    begin
      if @i_relacion is null or @i_relacion = 0
      begin
        select
          'Relacion.' = in_relacion,
          'Rel. Izq.' = substring(convert (char(64), re_izquierda),
                                  1,
                                  25),
          'Rel. Der.' = substring(convert (char(64), re_derecha),
                                  1,
                                  25),
          'Lado' = in_lado,
          'Cod. Cli.' = in_ente_d,
          'Cliente' = substring(convert (char(64), en_nomlar),
                                1,
                                25)
        from   cl_relacion,
               cl_instancia,
               cl_ente
        where  in_ente_i   = @i_izquierda
           and in_relacion = re_relacion
           and in_ente_d   = en_ente
        order  by in_relacion,
                  in_ente_d
      end
      else
      begin
        select
          'Relacion.' = in_relacion,
          'Rel. Izq.' = substring(convert (char(64), re_izquierda),
                                  1,
                                  25),
          'Rel. Der.' = substring(convert (char(64), re_derecha),
                                  1,
                                  25),
          'Lado' = in_lado,
          'Cod. Cli.' = in_ente_d,
          'Cliente' = substring(convert (char(64), en_nomlar),
                                1,
                                25)
        from   cl_relacion,
               cl_instancia,
               cl_ente
        where  in_ente_i   = @i_izquierda
           and in_relacion = re_relacion
           and in_relacion = @i_relacion
           and in_ente_d   = en_ente
        order  by in_relacion,
                  in_ente_d
      end
    end
    if @i_modo = 1
    begin
      select
        'Relacion.' = in_relacion,
        'Rel. Izq.' = substring(convert (char(64), re_izquierda),
                                1,
                                25),
        'Rel. Der.' = substring(convert (char(64), re_derecha),
                                1,
                                25),
        'Lado' = in_lado,
        'Cod. Cli.' = in_ente_d,
        'Cliente' = substring(convert (char(64), en_nomlar),
                              1,
                              25)
      from   cl_relacion,
             cl_instancia,
          cl_ente
      where  in_ente_i   = @i_izquierda
         and in_relacion = re_relacion
         and in_ente_d   = en_ente
         and ((in_relacion > @i_relacion)
               or (in_relacion = @i_relacion
                   and in_ente_d   > @i_derecha))
      order  by in_relacion,
                in_ente_d
      if @@rowcount = 0
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720304
        /* 'No existe dato solicitado'*/
        return 1
      end
    end
    return 0

  end
  else
  begin
    exec sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file,
      @t_from  = @w_sp_name,
      @i_num   = 1720305
    /*  'No corresponde codigo de transaccion' */
    return 1
  end

end

if @i_operacion = 'C'
begin
  if @t_trn = 172072
  begin
    /* Dados dos clientes, las relaciones en las que figuran */
    if @i_modo = 0
      select
        'Relacion.' = in_relacion,
        'Cod. Cli. I.' = in_ente_i,
        'Cliente Izq' = substring(convert (char(64), a.en_nomlar),
                                  1,
                                  25),
        'Rel. Izq.' = substring(convert (char(64), re_izquierda),
                                1,
                                25),
        'Rel. Der.' = substring(convert (char(64), re_derecha),
                                1,
                                25),
        'Lado' = in_lado,
        'Cod. Cli. D.' = in_ente_d,
        'Cliente Der' = substring(convert (char(64), b.en_nomlar),
                                  1,
                                  25)
      from   cl_relacion,
             cl_instancia,
             cl_ente a,
             cl_ente b
      where  in_ente_i   = @i_izquierda
         and in_ente_d   = @i_derecha
         and in_relacion = re_relacion
         and in_ente_i   = a.en_ente
         and in_ente_d   = b.en_ente
    if @i_modo = 1
    begin
      select
        'Relacion.' = in_relacion,
        'Cod. Cli. I.' = in_ente_i,
        'Cliente Izq' = substring(convert (char(64), a.en_nomlar),
                                  1,
                                  25),
        'Rel. Izq.' = substring(convert (char(64), re_izquierda),
                                1,
                                25),
        'Rel. Der.' = substring(convert (char(64), re_derecha),
                                1,
                                25),
        'Lado' = in_lado,
        'Cod. Cli. D.' = in_ente_d,
        'Cliente Der' = substring(convert (char(64), b.en_nomlar),
                                  1,
                                  25)
      from   cl_relacion,
             cl_instancia,
             cl_ente a,
             cl_ente b
      where  in_ente_i   = @i_izquierda
         and in_ente_d   = @i_derecha
         and in_relacion = re_relacion
         and in_ente_i   = a.en_ente
         and in_ente_d   = b.en_ente
         and in_relacion > @i_relacion
      if @@rowcount = 0
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720304
        /* 'No existe dato solicitado'*/
        return 1
      end
    end
    return 0

  end
  else
  begin
    exec sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file,
      @t_from  = @w_sp_name,
      @i_num   = 1720305
    /*  'No corresponde codigo de transaccion' */
    return 1
  end
end
set rowcount 0

go

