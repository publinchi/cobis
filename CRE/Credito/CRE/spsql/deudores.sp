/************************************************************************/
/*  Archivo:                deudores.sp                                 */
/*  Stored procedure:       sp_deudores                                 */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jonatan Rueda                               */
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
/*  23/04/19          LOGIN_DESA       Emision Inicial                  */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_deudores')
    drop proc sp_deudores
go

create proc sp_deudores(
   @s_ssn             int      = null,
   @s_date            datetime = null,
   @s_user            login    = null,
   @s_term            descripcion = null,
   @s_ofi             smallint  = null,
   @s_srv             varchar(30) = null,
   @s_lsrv            varchar(30) = null,
   @s_sesn            int = null,
   @t_rty             char(1)  = null,
   @t_trn             smallint = null,
   @t_debug           char(1)  = 'N',
   @t_file            varchar(14) = null,
   @t_from            varchar(30) = null,
   @i_operacion       char(1)  = null,
   @i_tramite         int  = null,
   @i_cliente         int  = null,
   @i_rol             catalogo  = null,
   @i_ced_ruc        numero = null,
   @i_titular         int = null,
   @i_operacion_cca   cuenta = null,
   @i_secuencial      tinyint = null,
   @i_cartera         char(1) = 'N',
   @i_cobro_cen       char(1) = null,
   @i_banco           varchar(24) = null,
   /* campos cca 353 alianzas bancamia --AAMG*/
   @i_crea_ext        char(1) = null,
   @i_opcion          char(1) = null,   
   @o_msg_msv         varchar(255) = null out
)
as

declare
   @w_today           datetime,     /* FECHA DEL DIA      */
   @w_return          int,          /* VALOR QUE RETORNA  */
   @w_sp_name         varchar(32),  /* NOMBRE STORED PROC */
   @w_existe          tinyint,      /* EXISTE EL REGISTRO */
   @w_tramite         int,
   @w_cliente         int,
   @w_rol             catalogo,
   @w_nom_cliente     descripcion,
   @w_tramite_act     char (1),    /*VERIFICAR SI CLIENTE TIENE TRAMITE VIGENTE*/
   @w_cobro_cen       char(1),
   @w_ejecutivo       int,         /*EJECUTIVO DE CUENTA DE LA OPERACION DEL CLIENTE*/
   @w_est_vig         tinyint,
   @w_cobro_cen_org   char(1),
   @w_tipo_tram       char(1)

select @w_today = @s_date
select @w_sp_name = 'sp_deudores'


/* CODIGOS DE TRANSACCIONES         */
/************************************/

if (@t_trn <> 21013 and @i_operacion = 'I') or
   (@t_trn <> 21113 and @i_operacion = 'U') or
   (@t_trn <> 21213 and @i_operacion = 'D') or
   (@t_trn <> 21413 and @i_operacion = 'S') or
   (@t_trn <> 21513 and @i_operacion = 'Q') or
   (@t_trn <> 21613 and @i_operacion = 'C') or
   (@t_trn <> 22110 and @i_operacion = 'L')
begin
   /* DISTINCION DE ROL */
   select  @w_rol = de_rol
   from    cob_credito..cr_deudores
   where   de_tramite = @i_tramite
   and     de_cliente = @i_cliente
   
   if @i_crea_ext is null
   begin
      /* TIPO DE TRANSACCION NO CORRESPONDE */
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file,
      @t_from  = @w_sp_name,
      @i_num   = 2101006
      return 1
   end
   else
   begin
      select @o_msg_msv = 'TIPO DE TRANSACCION NO CORRESPONDE, ' + @w_sp_name
      select @w_return  = 2101006
      return @w_return  
   end
end

/* CHEQUEO DE EXISTENCIAS */
/**************************/
if @i_operacion <> 'S'
begin
   
   if @w_rol <> 'G'  
   begin
       select  @w_tramite = de_tramite,
       @w_cliente = de_cliente,
       @w_nom_cliente = rtrim(en_nomlar),
       @w_rol = de_rol,
       @w_cobro_cen = de_cobro_cen
       from    cob_credito..cr_deudores,
       cobis..cl_ente
       where   de_tramite = @i_tramite
       and     de_cliente = @i_cliente
       and     de_cliente = en_ente
       and     en_ente    > 0
       and     de_tramite > 0
       and     de_cliente > 0

       if @@rowcount > 0
            select @w_existe = 1
        else  --se busca por tramites grupales
            select @w_existe = 0
    end
    else --G = grupales
        select  @w_tramite = de_tramite,
                @w_cliente = de_cliente,
                @w_nom_cliente = gr_nombre,
                @w_rol = de_rol,
                @w_cobro_cen = de_cobro_cen
        from    cob_credito..cr_deudores,
                cobis..cl_grupo
        where   de_tramite = @i_tramite
        and     de_cliente = @i_cliente
        and     de_cliente = gr_grupo
        and     gr_grupo   > 0
        and     de_tramite > 0
        and     de_cliente > 0

    /*VALIDAR SI CLIENTE TIENE CREDITO ACTIVO*/

    select
    @w_tramite   = op_tramite
    from   cob_cartera..ca_operacion
    where  op_estado <> 99
      and  op_cliente = @i_cliente

    if @@rowcount > 0 begin
       select @w_tramite_act = 'S'

       /*OBTENER CODIGO DE ESTADO VIGENTE*/
       select @w_est_vig = pa_tinyint
       from cobis..cl_parametro
       where pa_nemonico = 'ESTVG'
       and pa_producto = 'CRE'

       /*OBTENER CODIGO DE EJECUTIVO DEL CREDITO VIGENTE*/
       select
       @w_tramite   = op_tramite,
       @w_ejecutivo = op_oficial
       from   cob_cartera..ca_operacion
       where  op_estado  = @w_est_vig
       and    op_cliente = @i_cliente

    end
    else
       select @w_tramite_act = 'N'

end

/* VALIDACION DE CAMPOS NULOS */
/******************************/
if @i_operacion = 'I' or @i_operacion = 'U'
begin
    if @i_tramite is NULL or @i_cliente is NULL or @i_rol is NULL or @i_ced_ruc is NULL
    begin
       if @i_crea_ext is null
       begin
          /* CAMPOS NOT NULL CON VALORES NULOS */
          exec cobis..sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 2101001
          return 1
       end
       else
       begin
          select @o_msg_msv = 'CAMPOS NOT NULL CON VALORES NULOS, ' + @w_sp_name
          select @w_return  = 2101001
          return @w_return  
       end
    end
end

/* INSERCION DEL REGISTRO */
/**************************/

if @i_operacion = 'I'
begin
   if @w_existe = 1
   begin
      if @i_crea_ext is null
      begin
         /* REGISTRO YA EXISTE */
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = 2101002
         return 1
      end
      else
      begin
         select @o_msg_msv = 'REGISTRO YA EXISTE, ' + @w_sp_name
         select @w_return  = 2101002
         return @w_return  
      end
   end
   
   --solicitus iniciada por el workflow 
   select @w_rol = io_campo_7
   from cob_workflow..wf_inst_proceso
   where io_campo_3 = @i_tramite
   
   if @w_rol = 'G' --solicitus tramite grupal
      select @i_rol = @w_rol
   
   begin tran
   insert into cr_deudores
   (de_tramite,   de_cliente, de_rol,  de_ced_ruc,
   de_cobro_cen )
   values
   (@i_tramite,   @i_cliente, @i_rol,  @i_ced_ruc,
   @i_cobro_cen)
   
   if @@error <> 0
   begin
      if @i_crea_ext is null
      begin
         /* ERROR EN INSERCION DE REGISTRO */
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = 2103001
         return 1
      end
      else
      begin
         select @o_msg_msv = 'ERROR EN INSERCION DE REGISTRO, ' + @w_sp_name
         select @w_return  = 2103001
         return @w_return  
      end
   end

   /* Transaccion de Servicio */
   /***************************/

   insert into ts_deudores
   values ( @s_ssn,  @t_trn,  'N',     @s_date,
   @s_user,@s_term,@s_ofi,    'cr_deudores',
   @s_lsrv,@s_srv,   @i_tramite, @i_cliente, @i_rol,
   @i_cobro_cen)
   
   if @@error <> 0
   begin
      if @i_crea_ext is null
      begin
         /* ERROR EN INSERCION DE TRANSACCION DE SERVICIO */
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = 2103003
         return 1
      end
      else
      begin
         select @o_msg_msv = 'ERROR EN INSERCION DE TRANSACCION DE SERVICIO , ' + @w_sp_name
         select @w_return  = 2103003
         return @w_return  
      end
   end

   /* CONTROLES ADICIONALES PARA OPERACIONES DE CARTERA */
   if @i_cartera = 'S'
   begin

      -- ACTUALIZACION DE TABLA CA_OPERACION
      if @i_rol = 'D'
      begin
         -- ENCONTRAR EL NOMBRE DEL CLIENTE
         select @w_nom_cliente = rtrim(en_nomlar)
         from   cobis..cl_ente
         where  en_ente        = @i_cliente
         set transaction isolation level read uncommitted

         update cob_cartera..ca_operacion
         set    op_cliente     = @i_cliente,
                op_nombre      = @w_nom_cliente
         where  op_tramite     = @i_tramite

         if @@rowcount <> 1
         begin
            if @i_crea_ext is null
            begin
               /* ERROR EN INSERCION DE REGISTRO */
               exec cobis..sp_cerror
               @t_debug = @t_debug,
               @t_file  = @t_file,
               @t_from  = @w_sp_name,
               @i_num   = 2110257
               return 1
            end
            else
            begin
               select @o_msg_msv = 'Error al Actualizar Cliente en Cartera, ' + @w_sp_name
               select @w_return  = 2110257
               return @w_return  
            end
         end
      end

   end

   commit tran
end

/* Actualizacion del registro */
/******************************/

if @i_operacion = 'U'
begin
   if @w_existe = 0
   begin
      if @i_crea_ext is null
      begin
         /* REGISTRO A ACTUALIZAR NO EXISTE */
         exec cobis..sp_cerror
         @t_from  = @w_sp_name,
         @i_num   = 2105002
         return 1
      end
      else
      begin
         select @o_msg_msv = 'REGISTRO A ACTUALIZAR NO EXISTE, ' + @w_sp_name
         select @w_return  = 2105002
         return @w_return  
      end
   end
   
   select @w_cobro_cen_org = @i_cobro_cen       -- INC 13899 - 03/ENE/2010

   /* SI YA SE PAGO EL ESTUDIO DE CREDITO, NO IMPORTA EN QUE VIENE LA MARCA LA DEJO EN 'N' */
   if exists(select 1
             from  cr_tramite_cajas
             where tc_tramite    = @i_tramite
             and   tc_pago_cobro = 'C'
             and   tc_estado     = 'E'
             ) and @i_rol = 'D'
   
      select @i_cobro_cen = 'N'
   else
      select @i_cobro_cen = 'S'
   
   -- INI - INC 13899 - 03/ENE/2010 - SI ES UN TRAMITE DE UTILIZACION SE RESPETA LA MARCA DE COBRO
   select @w_tipo_tram = tr_tipo
   from cr_tramite
   where tr_tramite = @i_tramite
   
   if @w_tipo_tram = 'T'
      select @i_cobro_cen = @w_cobro_cen_org   
   -- FIN - INC 13899 - 03/ENE/2010
   
   begin tran
   
   update cob_credito..cr_deudores set
   de_rol       = @i_rol,
   de_cobro_cen = @i_cobro_cen
   where  de_tramite = @i_tramite
   and    de_cliente = @i_cliente

   if @@error <> 0
   begin
      if @i_crea_ext is null
      begin
         /* ERROR EN ACTUALIZACION DE REGISTRO */
         exec cobis..sp_cerror
         @t_from  = @w_sp_name,
         @i_num   = 2105001
         return 1
      end
      else
      begin
         select @o_msg_msv = 'ERROR EN ACTUALIZACION DE REGISTRO, ' + @w_sp_name
         select @w_return  = 2105001
         return @w_return
      end
   end

   /* TRANSACCION DE SERVICIO */
   /***************************/

   insert into ts_deudores
   values (@s_ssn,@t_trn,'P',
   @s_date,@s_user,@s_term,
   @s_ofi,'cr_deudores',@s_lsrv,
   @s_srv,@i_tramite,@w_cliente,
   @w_rol, @w_cobro_cen)

   if @@error <> 0
   begin
      if @i_crea_ext is null
      begin
         /* ERROR EN INSERCION DE TRANSACCION DE SERVICIO */
         exec cobis..sp_cerror
         @t_from  = @w_sp_name,
         @i_num   = 2103003
         return 1
      end
      else
      begin
         select @o_msg_msv = 'ERROR EN INSERCION DE TRANSACCION DE SERVICIO, ' + @w_sp_name
         select @w_return  = 2103003
         return @w_return
      end
   end

   /* TRANSACCION DE SERVICIO */
   /***************************/

   insert into ts_deudores
   values (@s_ssn,@t_trn,'A',
   @s_date,@s_user,@s_term,
   @s_ofi,'cr_deudores',@s_lsrv,
   @s_srv,@i_tramite,@i_cliente,
   @i_rol,@i_cobro_cen)

   if @@error <> 0
   begin
      if @i_crea_ext is null
      begin
         /* ERROR EN INSERCION DE TRANSACCION DE SERVICIO */
         exec cobis..sp_cerror
         @t_from  = @w_sp_name,
         @i_num   = 2103003
         return 1
      end
      else
      begin
         select @o_msg_msv = 'ERROR EN INSERCION DE TRANSACCION DE SERVICIO, ' + @w_sp_name
         select @w_return  = 2103003
         return @w_return
      end
   end
   commit tran
end


/* ELIMINACION DE REGISTROS */
/****************************/

if @i_operacion = 'D'
begin
    if @w_existe = 0
    begin
       if @i_crea_ext is null
       begin
          /* REGISTRO A ELIMINAR NO EXISTE */
          exec cobis..sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 2107002
          return 1
       end
       else
       begin
          select @o_msg_msv = 'REGISTRO A ELIMINAR NO EXISTE, ' + @w_sp_name
          select @w_return  = 2107002
          return @w_return
       end
    end

    begin tran
    
    delete cob_credito..cr_deudores
    where  de_tramite = @i_tramite
    and    de_cliente = @i_cliente

    if @@error <> 0
    begin
       if @i_crea_ext is null
       begin
          /* ERROR EN ELIMINACION DE REGISTRO */
          exec cobis..sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 2107001
          return 1
       end
       else
       begin
          select @o_msg_msv = 'REGISTRO A ELIMINAR NO EXISTE, ' + @w_sp_name
          select @w_return  = 2107002
          return @w_return
       end
    end

    /* TRANSACCION DE SERVICIO */
    /***************************/

    insert into ts_deudores
    values (@s_ssn,@t_trn,'B',
    @s_date,@s_user,@s_term,
    @s_ofi,'cr_deudores',@s_lsrv,
    @s_srv,@i_tramite, @w_cliente,
    @w_rol,@w_cobro_cen)

    if @@error <> 0
    begin
       if @i_crea_ext is null
       begin
          /* ERROR EN INSERCION DE TRANSACCION DE SERVICIO */
          exec cobis..sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 2103003
          return 1
       end
       else
       begin
          select @o_msg_msv = 'ERROR EN INSERCION DE TRANSACCION DE SERVICIO, ' + @w_sp_name
          select @w_return  = 2103003
          return @w_return
       end
    end

    commit tran
end

/**** SEARCH ****/
/****************/

if @i_operacion = 'S'
begin
   set rowcount 20
   if @w_rol <> 'G'
   begin
       select @i_cliente = isnull(@i_cliente , 0)

       select    
       'Rol'           = de_rol,
       'Cliente'       = de_cliente,
       'Nombre'        = substring(rtrim(en_nomlar), 1, 85) + '                                       ',
       'DI/NIT'        = de_ced_ruc,
       'Cobro Central' = de_cobro_cen
       from  cr_deudores,   cobis..cl_ente
       where de_cliente = en_ente
       and   de_tramite = @i_tramite
       and   de_cliente > @i_cliente
       order by de_rol desc
    end
    else    --credito grupales
    begin
       select    
       'Rol'           = de_rol,
       'Cliente'       = de_cliente,
       'Nombre'        = substring(rtrim(gr_nombre), 1, 85) + '                                       ',
       'DI/NIT'        = de_ced_ruc,
       'Cobro Central' = de_cobro_cen
       from  cr_deudores,   cobis..cl_grupo
       where de_cliente = gr_grupo
       and   de_tramite = @i_tramite
       and   de_cliente > @i_cliente
       order by de_rol desc
    end
    
   set rowcount 0
end


if @i_operacion = 'L'
begin
set rowcount 20
   if @i_crea_ext is null and @w_rol <> 'G'
   begin
      select 'Rol'           = de_rol,
             'Cliente'       = de_cliente,
             'Nombre'        = substring(rtrim(en_nomlar), 1, 60),
             'DI/NIT'        = de_ced_ruc,
             'Cobro Central' = de_cobro_cen
      from cr_linea, cr_deudores, cobis..cl_ente
      where de_cliente   = en_ente
      and   li_tramite   = de_tramite
      and   li_num_banco = @i_banco
      order by de_rol desc
   end
   else  --credito grupales
   begin
      select 'Rol'           = de_rol,
             'Cliente'       = de_cliente,
             'Nombre'        = substring(rtrim(gr_nombre), 1, 60),
             'DI/NIT'        = de_ced_ruc,
             'Cobro Central' = de_cobro_cen
      from cr_linea, cr_deudores, cobis..cl_grupo
      where de_cliente   = gr_grupo
      and   li_tramite   = de_tramite
      and   li_num_banco = @i_banco
      order by de_rol desc
   end
   set rowcount 0
end
/* CONSULTA OPCION QUERY */
/*************************/

if @i_operacion = 'Q'
begin
    if @w_existe = 1 and @i_crea_ext is null
      select  @i_tramite, @w_cliente, @w_nom_cliente, @w_rol, @w_cobro_cen
    else
    begin
       if @i_crea_ext is null
       begin
          /* REGISTRO NO EXISTE */
          exec cobis..sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 2101005
          return 1
       end
       else
       begin
          select @o_msg_msv = 'REGISTRO NO EXISTE, ' + @w_sp_name
          select @w_return  = 2101005
          return @w_return
       end
    end
end

if @i_operacion = 'C'
begin
   if @i_crea_ext is null and @w_rol <> 'G'
   begin
      select distinct
           'Cliente' = de_cliente,
           'Nombre' = substring(en_nomlar,1, 60),
           'Rol' = de_rol
      
      from   cr_deudores,
        cobis..cl_ente
      where  de_rol     in ('C','S')
      and    en_ente = de_cliente
      and    de_cliente > 0
      and    en_ente    > 0
      and    de_tramite > 0
      and    de_tramite in (select  de_tramite
             from     cr_deudores
                            where    de_cliente = @i_cliente
             and     de_tramite > 0)
   end
   else --credito grupales
   begin
    select distinct
           'Cliente' = de_cliente,
           'Nombre' = substring(gr_nombre,1, 60),
           'Rol' = de_rol
    from   cr_deudores,
        cobis..cl_grupo
      where  de_rol     in ('G')
      and    gr_grupo   = de_cliente
      and    de_cliente = @i_cliente
   end
end

if @i_crea_ext is null
begin
   /*ENVIO A FRONT-END DE LA VARIABLE QUE INDICA SI CLIENTE TIENE CREDITO ACTIVO ARA 09-04-08 BANCAMIA*/
   select @w_tramite_act

   select @w_ejecutivo
end

return 0




GO

