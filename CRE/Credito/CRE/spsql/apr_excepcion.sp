/************************************************************************/
/*  Archivo:                apr_excepcion.sp                            */
/*  Stored procedure:       sp_apr_excepcion                            */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jose Ortiz                                  */
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
/*  23/04/19          Jose Ortiz       Emision Inicial                  */
/* **********************************************************************/
use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_apr_excepcion' and type = 'P')
   drop proc sp_apr_excepcion
go


create proc sp_apr_excepcion(
   @s_ssn           int          = null,
   @s_user          login        = null,
   @s_sesn          int          = null,
   @s_term          descripcion  = null,
   @s_date          datetime     = null,
   @s_srv           varchar(30)  = null,
   @s_lsrv          varchar(30)  = null,
   @s_rol           smallint     = null,
   @s_ofi           smallint     = null,
   @s_org_err       char(1)      = null,
   @s_error         int          = null,
   @s_sev           tinyint      = null,
   @s_msg           descripcion  = null,
   @s_org           char(1)      = null,
   @t_rty           char(1)      = null,
   @t_trn           smallint     = null,
   @t_debug         char(1)      = 'N',
   @t_file          varchar(14)  = null,
   @t_from          varchar(30)  = null,
   @i_modo          tinyint      = null,
   @i_tramite       int          = null,
   @i_numero        tinyint      = null,
   @i_clase         char(1)      = null,
   @i_fecha_tope    datetime     = null,
   @i_observaciones varchar(255) = null,
   @i_aprob_por     login        = null,
   @i_riesgo_i      money        = null,
   @i_riesgo_g      money        = null,
   @i_comite        catalogo     = null,
   @i_acta          cuenta       = null,
   @i_respuesta     varchar(255) = null,        --ZR
   @i_ruteo_paso_def varchar(1)  = 'S'
)
as

declare
   @w_return         int,          /* PARA LLAMAR OTROS SP */
   @w_today          datetime,     /* FECHA DEL DIA */ 
   @w_sp_name        varchar(32),  /* NOMBRE DEL STORED PROC */
   @w_existe         tinyint,      /* EXISTE EL REGISTRO */
   @w_tipo           char(1),
   @w_nivel          tinyint,
   @w_numero_bco     cuenta,
   @w_toperacion     catalogo,
   @w_producto       catalogo,
   @w_monto          money,
   @w_moneda         tinyint,
   @w_periodo        catalogo,
   @w_num_periodos   smallint,
   @w_tramite        int,
   @w_estado         char(255),
   @w_fecha_apr      datetime,
   @w_fecha_venc     datetime,
   @w_fecha_liq      datetime,
   @w_cliente        int,
   @w_max_historia   int,
   @w_usuario        login,
   @w_linea          int,
   @w_cli_tram       int,   --SBU  CD00054
   @w_gru_cliente    int,
   @w_monto_local    money,
   @w_reservado      money,
   @w_linea_credito  int,
   @w_sectoreco      catalogo,
   @w_rtoperacion    catalogo,
   @w_rproducto      catalogo,
   @w_rmoneda        tinyint,
   @w_li_tipo        char(1),
   @w_monto_tram_dis money,
   @w_tramite_dis    int,
   @w_toperacion_dis cuenta

select @w_today = @s_date
select @w_sp_name = 'sp_apr_excepcion'


if @i_ruteo_paso_def != 'S'  --RAL 19-Ene-2017 inconsistencia con orquestacion en el flujo
BEGIN

    /* SI LA APROBACION SE DA EN COMITE, APRUEBA EL PRESIDENTE DEL COMITE */
    if @i_comite is null
       select @w_usuario = @s_user
    else
    begin
       /* Inicio cambio DBA: 13/NOV/99  */
       select @w_usuario = @i_comite
      /* select @w_usuario = es_usuario
       from   cr_estacion
       where  es_comite = @i_comite  COMENTARIADO  */
       /* Fin cambio DBA: 13/NOV/99  */
    end

    /* VALIDACION DE CAMPOS NULOS */
    /******************************/
    if @i_modo = 0
    begin
       if @i_tramite is NULL or @i_numero is NULL or @i_clase is NULL 
       begin
          /* CAMPOS NOT NULL CON VALORES NULOS */
          exec cobis..sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file, 
          @t_from  = @w_sp_name,
          @i_num   = 2101001
          return 1 
       end
    end
    else
    if @i_modo = 1 or @i_modo = 2
    begin
       if @i_tramite is NULL
       begin
          /* CAMPOS NOT NULL CON VALORES NULOS */
          exec cobis..sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file, 
          @t_from  = @w_sp_name,
          @i_num   = 2101001
          return 1 
       end
    end


    /* EN APROBACION DE COMITE, USUARIO QUE APRUEBA ES EL COMITE */

    /* APROBACION DE EXCEPCIONES */
    if @i_modo = 0
    begin
       update cr_excepciones set
       ex_clase = @i_clase,   
       ex_estado = 'A',   
       ex_fecha_tope = @i_fecha_tope,   
       ex_fecha_aprob = @s_date,   
       ex_login_aprob = @w_usuario,
       ex_aprob_por = @i_aprob_por,
       ex_comite = @i_comite,
       ex_acta = @i_acta
       where ( cr_excepciones.ex_tramite = @i_tramite ) 
       and   ( cr_excepciones.ex_numero = @i_numero )   

       if @@error <> 0 
       begin
          /* ERROR EN ACTUALIZACION DE REGISTRO */
          exec cobis..sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file, 
          @t_from  = @w_sp_name,
          @i_num   = 2105001
          return 1 
       end
    end

    /* APROBACION DE INSTRUCCIONES */
    if @i_modo = 1
    begin
       update cr_instrucciones set
       in_estado = 'A',   
       in_fecha_aprob = @s_date,   
       in_login_aprob = @w_usuario,
       in_aprob_por = @i_aprob_por,
       in_comite = @i_comite,
       in_acta = @i_acta,
       in_respuesta = @i_respuesta      --ZR
       where ( in_tramite = @i_tramite ) 
       and   ( in_numero = @i_numero )   
     
      if @@error <> 0 
       begin
          /* EEROR EN ACTUALIZACION DE REGISTRO */
          exec cobis..sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file, 
          @t_from  = @w_sp_name,
          @i_num   = 2105001
          return 1 
       end
    end


    /* APROBACION DE TRAMITES */
    if @i_modo = 2
    begin
       /* SELECCION DE DATOS DEL TRAMITE PARA EL HISTORICO */
       select  
       @w_tipo = tr_tipo,
       @w_toperacion = cr_tramite.tr_toperacion,   
       @w_producto = cr_tramite.tr_producto,   
       @w_monto = cr_tramite.tr_monto,   
       @w_moneda = cr_tramite.tr_moneda,   
       @w_periodo = cr_tramite.tr_periodo,   
       @w_num_periodos = cr_tramite.tr_num_periodos,   
       @w_tramite = cr_tramite.tr_tramite, 
       @w_cliente = isnull(tr_cliente, tr_grupo)
       from cr_tramite
       where tr_tramite = @i_tramite

       if @@rowcount = 0
       begin
          /* REGISTRO NO EXISTE */
          exec cobis..sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file, 
          @t_from  = @w_sp_name,
          @i_num   = 2101005
          return 1 
       end

       begin tran
          update cr_tramite set
          tr_fecha_apr = @s_date,   
          tr_usuario_apr = @w_usuario,   
          tr_estado = 'A',
          tr_riesgo = @i_riesgo_i + @i_riesgo_g,
          tr_comite = @i_comite,
          tr_acta   = @i_acta
          where cr_tramite.tr_tramite = @i_tramite   

          if @@error <> 0 
          begin
             /* ERROR EN ACTUALIZACION DE REGISTRO */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 2105001
             return 1 
          end

        update  cr_ctrl_cupo_asoc
        set     ca_acta     = @i_acta
        where   ca_num_cupo in (select  li_numero   
                    from    cr_linea
                    where   li_tramite = @i_tramite)


          

          /*  SI ES CUPO DE CREDITO ACTUALIZAMOS LA FECHA DE INICIO, VTO  DEL CUPO */
          /*  LA VIGENCIA DEL CUPO EMPIEZA DESDE EL MOMENTO DE LA APROBACION */

          if @w_tipo = 'C'
          begin
             update cr_linea set
             li_fecha_inicio = @s_date,
             li_fecha_vto    = dateadd(dd,li_dias,@s_date),
             li_fecha_aprob = @s_date
             where cr_linea.li_tramite = @i_tramite


             --emg Ab-16-03 Ejecucion contable para cupos Normales y de Sobregiro  

             select @w_li_tipo = li_tipo
             from   cr_linea
             where  li_tramite = @i_tramite

             if @w_li_tipo = 'N' or  @w_li_tipo = 'S' or  @w_li_tipo = 'O'
             begin
                update cr_tramite set
                tr_contabilizado = 'S'
                WHERE tr_tramite = @i_tramite
             end

          end

          /* INSERCION EN EL HISTORICO */
          exec @w_return = sp_hist_credito
          @i_tramite   = @i_tramite,
          @i_operacion = 'A'            --APROBADO
          if @w_return != 0
             return @w_return

       commit tran
    end

    /* ZR: 15/ENE/2001 RECHAZO DE APROBACIONES */
    if @i_modo = 3
    begin
       update cr_instrucciones set
       in_estado = 'R',   
       in_fecha_aprob = @s_date,   
       in_login_aprob = @w_usuario,
       in_aprob_por = @i_aprob_por,
       in_comite = @i_comite,
       in_acta = @i_acta,
       in_respuesta = @i_respuesta      
       where ( in_tramite = @i_tramite ) 
       and   ( in_numero = @i_numero )   
       if @@error <> 0 
       begin
          /* EEROR EN ACTUALIZACION DE REGISTRO */
          exec cobis..sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file, 
          @t_from  = @w_sp_name,
          @i_num   = 2105001
          return 1 
       end
    end


    /* ACTUALIZACION DEL RESERVADO */
    if @i_modo = 4
    begin
       select @w_tipo = tr_tipo,
              @w_cli_tram = tr_cliente,
              @w_linea_credito = tr_linea_credito,
              @w_toperacion = tr_toperacion,
              @w_producto = tr_producto,
              @w_moneda = tr_moneda
       from cr_tramite
       where tr_tramite = @i_tramite   

       begin tran
          
          if (@w_tipo in ('O','R')) and (@w_cli_tram is not null)   --SBU  CD00054
          begin
             select @w_monto_local = isnull(lr_reservado * cv_valor,0),
                    @w_reservado   = lr_reservado
         from cr_lin_reservado x, cob_conta..cb_vcotizacion             
         where lr_tramite = @i_tramite
             and   lr_moneda = cv_moneda
             and  cv_fecha = (select max(cv_fecha)
                              from   cob_conta..cb_vcotizacion
                              where  cv_moneda = x.lr_moneda
                              and cv_fecha <= @s_date)

             select @w_gru_cliente = en_grupo,
                @w_sectoreco = en_sector
             from cobis..cl_ente
             where en_ente = @w_cli_tram
         set transaction isolation level read uncommitted



         delete cr_lin_reservado
         where lr_tramite = @i_tramite

             if @@error <> 0
             begin
                /*ERROR EN ELIMINACION DE RESERVADO*/
                  exec cobis..sp_cerror
                  @t_debug = @t_debug,
                  @t_file  = @t_file, 
                  @t_from  = @w_sp_name,
                  @i_num   = 2103001
                  return 1 
             end


                 if @w_linea_credito is not null
                 begin
            update  cr_linea
            set     li_reservado    = (
                           select   isnull(sum(case tr_moneda 
                           when 0 then tr_monto
                           else
                           tr_montop
                           end),0)
                           from     cr_tramite,
                           cob_cartera..ca_operacion
                            where   tr_linea_credito = L.li_numero
                            and     tr_tramite   <> @i_tramite
                            and op_tramite   = tr_tramite
                            and op_estado    in(0,99)
                               and tr_estado    not in ('Z','X','R','S')               
                               and tr_tipo       in ('O')
                               and op_naturaleza    = 'A'
                           ) + @w_monto_local
            
                    from    cr_linea L
            where   li_numero   = @w_linea_credito



            update  cr_lin_ope_moneda
            set     om_reservado    = (
                           select   isnull(sum(case tr_moneda 
                           when 0 then tr_monto
                           else
                           tr_montop
                           end),0) + @w_monto_local
                           from     cr_tramite,
                           cob_cartera..ca_operacion
                            where   tr_linea_credito = L.om_linea
                                                    and     op_toperacion    = L.om_toperacion
                            and     tr_tramite   <> @i_tramite
                            and op_tramite   = tr_tramite
                            and op_estado    in(0,99)
                               and tr_estado    not in ('Z','X','R','S')               
                               and tr_tipo       in ('O')
                               and op_naturaleza    = 'A'
                           )
                    from    cr_lin_ope_moneda L
            where   om_linea        = @w_linea_credito
                 end

          end

          if (@w_tipo = 'C') and (@w_cli_tram is not null)  --SBU  CD00054
          begin
         select @w_linea_credito = li_numero,
                    @w_li_tipo = li_tipo
             from cr_linea 
             where li_tramite = @i_tramite

             if exists (select 1
                from cr_lin_reservado
                where lr_tramite = @i_tramite)
             begin
                select @w_monto_local = isnull(lr_reservado * cv_valor,0),
                       @w_reservado   = lr_reservado,
                       @w_rtoperacion = lr_toperacion,
                       @w_rproducto   = lr_producto,
                       @w_rmoneda     = lr_moneda
            from cr_lin_reservado x, cob_conta..cb_vcotizacion             
            where lr_tramite = @i_tramite
                and   lr_moneda = cv_moneda
                and  cv_fecha = (select max(cv_fecha)
                                 from   cob_conta..cb_vcotizacion
                                 where  cv_moneda = x.lr_moneda
                                 and cv_fecha <= @s_date)

                select @w_gru_cliente = en_grupo,
                   @w_sectoreco = en_sector
                from cobis..cl_ente
                where en_ente = @w_cli_tram

            update cobis..cl_ente
            set en_reservado = isnull(en_reservado,0) + isnull(@w_monto_local,0)
            where en_ente = @w_cli_tram

                if @@error <> 0
                begin
                 /*ERROR EN ACTUALIZACION DE CLIENTE*/
                   exec cobis..sp_cerror
                   @t_debug = @t_debug,
                   @t_file  = @t_file, 
                   @t_from  = @w_sp_name,
                   @i_num   = 2105001
                   return 1 
                end

                if @w_gru_cliente is not null
                begin
                   update cobis..cl_grupo
                   set gr_reservado = isnull(gr_reservado, 0) + isnull(@w_monto_local,0)
                   where gr_grupo = @w_gru_cliente

                   if @@error <> 0
                   begin
                      /*ERROR EN ACTUALIZACION DE GRUPOS ECONOMICOS*/
                      exec cobis..sp_cerror
                      @t_debug = @t_debug,
                      @t_file  = @t_file, 
                      @t_from  = @w_sp_name,
                      @i_num   = 2105001
                      return 1 
                   end
                end

                if @w_sectoreco is not null
                begin
                   update  cobis..cl_sectoreco
               set se_reservado = isnull(se_reservado, 0) + isnull(@w_monto_local,0)
                   where se_sector = @w_sectoreco

                   if @@error <> 0
                   begin
                      /*ERROR EN ACTUALIZACION DE SECTOR ECONOMICO*/
                      exec cobis..sp_cerror
                      @t_debug = @t_debug,
                      @t_file  = @t_file, 
                      @t_from  = @w_sp_name,
                      @i_num   = 2105001
                      return 1 
                   end
            end

                select @w_monto_local = @w_monto_local / cv_valor
                from cr_linea x, cob_conta..cb_vcotizacion
                where li_numero = @w_linea_credito
                and  li_moneda = cv_moneda
                and  cv_fecha = (select max(cv_fecha)
                                 from   cob_conta..cb_vcotizacion
                                 where  cv_moneda = x.li_moneda
                                 and cv_fecha <= @s_date)
                
            update cr_linea
            set li_reservado = isnull(li_reservado,0) + @w_monto_local
                where li_numero = @w_linea_credito

                if @@error <> 0
                begin
                   /*ERROR EN ACTUALIZACION DE UTILIZACION DE LINEA */
                   exec cobis..sp_cerror
                   @t_from  = @w_sp_name,
                   @i_num   = 2105012
                   return 1
                end

                if exists (select 1 
                           from  cr_lin_grupo
                           where lg_linea = @w_linea_credito
                           and   lg_cliente = @w_cli_tram)
                begin
                   update cr_lin_grupo set
                   lg_reservado = isnull(lg_reservado, 0) + @w_monto_local  
                   where  lg_linea = @w_linea_credito
                   and    lg_cliente = @w_cli_tram

                   if @@error <> 0
                   begin
                      /*ERROR EN ACTUALIZACION DE CUPO POR CLIENTE */
                      exec cobis..sp_cerror
                      @t_from  = @w_sp_name,
                      @i_num   = 2105017
                      return 1
                   end
                end

                if exists (select 1 
                           from   cr_lin_ope_moneda
                           where  om_linea = @w_linea_credito
                           and    om_toperacion = @w_rtoperacion
                           and    om_producto = @w_rproducto
                           and    om_moneda = @w_rmoneda)
                begin
                   -- ACTUALIZACION EN CR_LIN_OPE_moneda
                   update cr_lin_ope_moneda set 
                   om_reservado = isnull(om_reservado, 0) + @w_reservado
                   where  om_linea = @w_linea_credito
                   and om_toperacion = @w_rtoperacion
                   and om_producto = @w_rproducto
                   and om_moneda = @w_rmoneda
      
                   if @@error <> 0
                   begin
                      /*ERROR EN ACTUALIZACION DE UTILIZACION DE LINEA POR PRODUCTO */
                      exec cobis..sp_cerror
                      @t_from  = @w_sp_name,
                      @i_num   = 2105013
                      return 1
                   end
                end

            delete cr_lin_reservado
            where lr_tramite = @i_tramite

                if @@error <> 0
                begin
                   /*ERROR EN ELIMINACION DE RESERVADO*/
                   exec cobis..sp_cerror
                   @t_debug = @t_debug,
                   @t_file  = @t_file, 
                   @t_from  = @w_sp_name,
                   @i_num   = 2103001
                   return 1 
                end
             end
          end
       commit tran
    end

END                          --RAL 19-Ene-2017 inconsistencia con orquestacion en el flujo

return 0

GO
