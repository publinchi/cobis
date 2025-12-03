/************************************************************************/
/*  Archivo:                ases_upd.sp                                 */
/*  Stored procedure:       sp_asesor_upd                               */
/*  Base de datos:          cobis                                       */
/*  Producto:               Clientes                                    */
/*  Disenado por:           ALD                                         */
/*  Fecha de escritura:     30-Abril-2019                               */
/************************************************************************/
/*                                  IMPORTANTE                          */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*  de COBISCorp.                                                       */
/*  Su uso no    autorizado queda  expresamente   prohibido asi como    */
/*  cualquier    alteracion o  agregado  hecho por    alguno  de sus    */
/*  usuarios sin el debido consentimiento por   escrito de COBISCorp.   */
/*  Este programa esta protegido por la ley de   derechos de autor      */
/*  y por las    convenciones  internacionales   de  propiedad inte-    */
/*  lectual.    Su uso no  autorizado dara  derecho a    COBISCorp para */
/*  obtener ordenes  de secuestro o  retencion y para  perseguir        */
/*  penalmente a los autores de cualquier   infraccion.                 */
/************************************************************************/
/*                            PROPOSITO                                 */
/************************************************************************/
/*                            MODIFICACIONES                            */
/*    FECHA             AUTOR         RAZON                             */
/* 30/Abril/2019        ALD           Versión Inicial Te Creemos        */
/* 16/Junio/2020        FSAP          Estandarizacion de Clientes       */
/************************************************************************/
use [cobis]
go

set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO

if exists (select 1
           from   sysobjects
           where  name = 'sp_asesor_upd')
  drop proc sp_asesor_upd
go

create proc sp_asesor_upd
(
  @s_ssn          int = null,
  @s_user         login = null,
  @s_term         varchar(30) = null,
  @s_date         datetime = null,
  @s_srv          varchar(30) = null,
  @s_lsrv         varchar(30) = null,
  @s_ofi          smallint = null,
  @s_rol          smallint = null,
  @s_org_err      char(1) = null,
  @s_error        int = null,
  @s_sev          tinyint = null,
  @s_msg          descripcion = null,
  @s_org          char(1) = null,
  @t_debug        char(1) = 'N',
  @t_file         varchar(10) = null,
  @t_from         varchar(32) = null,
  @t_trn          int = null,
  @t_show_version bit = 0,
  @i_operacion    char(1),
  @i_ente         int = null,
  @i_tipo_cli     char(1) = null,
  @i_filial       tinyint = null,
  @i_oficina      smallint = null,
  @i_oficial      smallint = null,
  @o_dif_oficial  tinyint = null out,
  @i_oficial_sup  smallint = null,
  @i_alterno      int = null,
  @i_linea        char(1) = 'S',
  @i_crea_ext     char(1) = null
)
as
  declare
    @w_today           datetime,
    @w_sp_name         varchar(32),
    @w_sp_msg          varchar(132),
    @w_return          int,
    @w_siguiente       int,
    @w_codigo          int,
    @w_tipo_cli        char(1),
    @w_filial          int,
    @w_fecha_asig      datetime,
    @w_cg_cliente      int,
    @w_oficina         smallint,
    @ww_oficial        varchar(64),
    @vw_oficial        varchar(64),
    @w_oficiald        smallint,
    @w_oficial         smallint,
    @v_oficial         smallint,
    @v_oficial_ant     smallint,
    @w_oficial_sup     smallint,
    @v_oficial_sup     smallint,
    @v_oficial_sup_ant smallint,
    @w_banca           catalogo,
    @v_banca           catalogo

  select
    @w_sp_name = 'sp_asesor_upd'

---- VERSIONAMIENTO DEL PROGRAMA -------------------------------------------
if @t_show_version = 1
begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end

select
  @w_today = @s_date /* getdate() */

/* Update */

if @i_operacion = 'U'
begin
  if @t_trn = 172024
  begin
    /* seleccionar los datos anteriores del cliente */
    if @i_tipo_cli <> 'G'
    begin
      select
        @w_oficial = en_oficial,
        @w_oficial_sup = en_oficial_sup
      from   cl_ente
      where  en_ente    = @i_ente
         and en_subtipo = @i_tipo_cli
    end
    else
    begin
      select
        @w_oficial = gr_oficial
      from   cl_grupo
      where  gr_grupo = @i_ente
    end

    if @@rowcount = 0
    begin
      if @i_linea = 'S'
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720138
      /*  'No existe cliente indicado'*/
      end
      return 1720138
    end

    /* Verificar que exista el oficial indicado */
    select
      @w_codigo = oc_oficial
    from   cc_oficial
    where  oc_oficial = @i_oficial

    if @@rowcount = 0
       and @i_oficial is not null
    begin
      if @i_linea = 'S'
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720040
      /* 'No existe oficial'*/
      end
      return 1720040

    end

    if @w_oficial is not null
    begin
      select
        @v_oficial = @w_oficial
      /* capturar los datos que han cambiado */
      select
        @v_oficial_ant = @w_oficial,
        @v_oficial_sup_ant = @w_oficial_sup
    end

    if @i_crea_ext is null
      begin tran
    /******* actualizacion de asesor **********/
    if @i_tipo_cli <> 'G'
    begin
      update cl_ente
      set    en_oficial = @i_oficial,
             en_oficial_sup = @i_oficial_sup
      where  en_ente    = @i_ente
         and en_subtipo = @i_tipo_cli
    end
    else
    begin
      update cl_grupo
      set    gr_oficial = @i_oficial
      where  gr_grupo = @i_ente
    end
    if @@error <> 0
    begin
      if @i_linea = 'S'
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720131
      /* CAMBIAR CODIGO ERROR */
      /* 'Error en actualizacion de Cliente'*/
      end
      return 1720131

    end
    if @i_tipo_cli <> 'G'
    begin
      if exists (select
                   cg_ente
                 from   cl_cliente_grupo
                 where  cg_ente = @i_ente)
      begin
        update cl_cliente_grupo
        set    cg_oficial = @i_oficial
        where  cg_ente = @i_ente

        if @@error <> 0
        begin
          if @i_linea = 'S'
          begin
            exec sp_cerror
              @t_debug = @t_debug,
              @t_file  = @t_file,
              @t_from  = @w_sp_name,
              @i_num   = 1720139
          /* 'Error en actualizacion '*/
          end
          return 1720139

        end
      end

      select
        @vw_oficial = convert(varchar(64), @v_oficial)
      select
        @ww_oficial = convert(varchar(64), @i_oficial)

      if @vw_oficial <> @ww_oficial
      begin
        insert into cl_actualiza
                    (ac_ente,ac_fecha,ac_tabla,ac_campo,ac_valor_ant,
                     ac_valor_nue,ac_transaccion,ac_secuencial1,ac_secuencial2
        )
        values      (@i_ente,getdate(),'cl_ente','en_oficial',@vw_oficial,
                     @ww_oficial,'U',null,null)
        if @@error <> 0
        begin
          if @i_linea = 'S'
          begin
            exec sp_cerror
              @t_debug = @t_debug,
              @t_file  = @t_file,
              @t_from  = @w_sp_name,
              @i_num   = 1720140
          end
          return 1720140
        /*'Error en creacion de cliente'*/
        end
      end
    end

    if @w_oficial is not null
    begin
    /***** actualizacion de asesor en las tablas huella *******/
      /**** actualizamos la tabla de cl_his_ejecutivo ****/
      select
        @w_fecha_asig = ej_fecha_asig
      from   cl_ejecutivo
      where  ej_ente     = @i_ente
         and ej_toficial = @i_tipo_cli

      if @w_fecha_asig is null
      begin
        select
          @w_fecha_asig = getdate()
      end

      if not exists (select
                       '1'
                     from   cobis..cl_his_ejecutivo
                     where  ej_ente           = @i_ente
                        and ej_funcionario    = @v_oficial_ant
                        and ej_fecha_registro = getdate())
      begin
        insert into cl_his_ejecutivo
                    (ej_ente,ej_funcionario,ej_toficial,ej_fecha_asig,
                     ej_fecha_registro)
        values      (@i_ente,@v_oficial_ant,@i_tipo_cli,@w_fecha_asig,getdate(
                     ))

        if @@error <> 0
        begin
          if @i_linea = 'S'
          begin
            exec sp_cerror
              @t_debug = @t_debug,
              @t_file  = @t_file,
              @t_from  = @w_sp_name,
              @i_num   = 1720064
          /* 'Error en insercion a historico'*/
          /* 'de ejecutivo'*/
          end
          return 1720064
        end
      end

      /*** actualizar la tabla de cl_ejecutivo ****/
      update cl_ejecutivo
      set    ej_funcionario = @i_oficial,
             ej_fecha_asig = getdate()
      where  ej_ente     = @i_ente
         and ej_toficial = @i_tipo_cli

      if @@error <> 0
      begin
        if @i_linea = 'S'
        begin
          exec sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file,
            @t_from  = @w_sp_name,
            @i_num   = 1720141
        /* 'Error en insercion de ejecutivo del ente'*/
        end
        return 1720141

      end

      /* transaccion de servicio - datos previos */
      insert into ts_persona
                  (secuencial,tipo_transaccion,clase,fecha,usuario,
                   terminal,srv,lsrv,persona,filial,
                   oficina,oficial)
      values      (@s_ssn,@t_trn,@i_tipo_cli,getdate(),@s_user,
                   @s_term,@s_srv,@s_lsrv,@i_ente,@w_filial,
                   @w_oficina,@v_oficial)

      if @@error <> 0
      begin
        if @i_linea = 'S'
        begin
          exec sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file,
            @t_from  = @w_sp_name,
            @i_num   = 1720049
        /*'Error en creacion transaccion de servicio'*/
        end
        return 1720049

      end

      /* transaccion de servicio - datos anteriores  */
      insert into ts_persona
                  (secuencial,tipo_transaccion,clase,fecha,usuario,
                   terminal,srv,lsrv,persona,filial,
                   oficina,oficial,alterno)
      values      (@s_ssn,@t_trn,'A',@w_fecha_asig,@s_user,
                   @s_term,@s_srv,@s_lsrv,@i_ente,@w_filial,
                   @w_oficina,@w_oficial,@i_alterno)

      if @@error <> 0
      begin
        if @i_linea = 'S'
        begin
          exec sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file,
            @t_from  = @w_sp_name,
            @i_num   = 1720049
        /*'Error creacion de transaccion de servicio'*/
        end
        return 1720049
      end
    end
    else
    begin
      insert into cl_ejecutivo
                  (ej_ente,ej_funcionario,ej_toficial,ej_fecha_asig)
      values      ( @i_ente,@i_oficial,@i_tipo_cli,getdate())

      if @@error <> 0
      begin
        if @i_linea = 'S'
        begin
          exec sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file,
            @t_from  = @w_sp_name,
            @i_num   = 1720141
        /* 'Error en insercion de ejecutivo del ente'*/
        end
        return 1720141

      end
    end

    if @i_crea_ext is null
      commit tran
    return 0
  end
  else
  begin
    if @i_linea = 'S'
    begin
      exec sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = 1720075
    /*  'No corresponde */
    end
    return 1720075

  end
end

go

