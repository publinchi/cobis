/***********************************************************************/
/*    Archivo:            cr_gar_a.sp                    */
/*    Stored procedure:        sp_gar_anteriores              */
/*    Base de Datos:            cob_credito                    */
/*    Producto:            Credito                           */
/*    Disenado por:            Myriam Davila                  */
/*    Fecha de Documentacion:     14/Ago/95                      */
/***********************************************************************/
/*            IMPORTANTE                              */
/*    Este programa es parte de los paquetes bancarios propiedad de  */
/*    'MACOSA',representantes exclusivos para el Ecuador de la       */
/*    AT&T                                   */
/*    Su uso no autorizado queda expresamente prohibido asi como     */
/*    cualquier autorizacion o agregado hecho por alguno de sus      */
/*    usuario sin el debido consentimiento por escrito de la         */
/*    Presidencia Ejecutiva de MACOSA o su representante           */
/***********************************************************************/
/*            PROPOSITO                       */
/*    Este stored procedure permite realizar operaciones DML           */
/*    Insert, Update, Delete y Search en la tabla cr_gar_anteriores  */
/*                                       */
/***********************************************************************/
/*            MODIFICACIONES                       */
/*    FECHA        AUTOR            RAZON               */
/*    14/Ago/95    Ivonne Ordonez        Emision Inicial           */
/*      22/Oct/96       Erick Ca?as M.          Campos efecto y valor  */
/*    18/Oct/96    Isaac Parra        Actualizacion de campos*/
/*    29/Sep/15    Adriana Chiluisa        Operacion R para reporte*/
/***********************************************************************/
USE cob_credito
go

IF OBJECT_ID ('dbo.sp_gar_anteriores') IS NOT NULL
	DROP PROCEDURE dbo.sp_gar_anteriores
GO

create proc sp_gar_anteriores (
    @s_ssn                int      = null,
    @s_user               login    = null,
    @s_sesn               int    = null,
    @s_term               descripcion = null,
    @s_date               datetime = null,
    @s_srv                varchar(30) = null,
    @s_lsrv               varchar(30) = null,
    @s_rol                smallint = null,
    @s_ofi                smallint  = null,
    @s_org_err            char(1) = null,
    @s_error              int = null,
    @s_sev                tinyint = null,
    @s_msg                descripcion = null,
    @s_org                char(1) = null,
    @t_show_version       bit = 0, -- Mostrar la version del programa
    @t_rty                char(1)  = null,
    @t_trn                smallint = null,
    @t_debug              char(1)  = 'N',
    @t_file               varchar(14) = null,
    @t_from               varchar(30) = null,
    @i_tramite            int  = null,
    @i_gar_anterior       varchar(64)  = null,
    @i_gar_nueva          varchar(64)  = null,
    @i_num_operacion      cuenta = null,
    @i_operacion          char(1)  = NULL,
    @i_modo               char(1) = NULL,
    @i_proposito          char(3) = NULL,
    @i_clase              char(1) = NULL,
    @i_porcentaje         float = null,
    @i_saldo              money = null
)
as
declare
    @w_today              datetime,     /* fecha del dia */
    @w_return             int,          /* valor que retorna */
    @w_sp_name            varchar(32),  /* nombre stored proc*/
    @w_existe             tinyint,      /* existe el registro*/
    @w_tramite            int,
    @w_gar_anterior       varchar(64),
    @w_val_nueva          money,
    @w_val_anterior       money,
    @w_des_nueva          descripcion,
    @w_des_anterior       descripcion,
    @w_est_nueva          char(1),
    @w_est_anterior       char(1),
    @w_gar_nueva          varchar(64),
    @w_num_operacion      cuenta,
    @w_numero             smallint,
    @w_proposito          catalogo,
    @w_porcentaje         float,
    @w_valor_cobertura    money,
	@w_inmueble           varchar(30),
	@w_vehiculo           varchar(30),
	@w_prendaria          varchar(30),
	@w_personal           varchar(30),
	@w_mixta              varchar(30),
	@w_tramite_ant        int,
	@w_ope_base           varchar(24),
    @w_spid               smallint

select @w_today = @s_date
select @w_sp_name = 'sp_gar_anteriores'

if @t_show_version = 1
begin
    print 'Stored procedure sp_gar_anteriores, Version 4.0.0.2'
    return 0
end

/* Debug */
/*********/
if @t_debug = 'S'
begin
    exec cobis..sp_begin_debug @t_file = @t_file
        select '/** Stored Procedure **/ ' = @w_sp_name,
        s_ssn              = @s_ssn,
        s_user              = @s_user,
        s_sesn              = @s_sesn,
        s_term              = @s_term,
        s_date              = @s_date,
        s_srv              = @s_srv,
        s_lsrv              = @s_lsrv,
        s_rol              = @s_rol,
        s_ofi              = @s_ofi,
        s_org_err          = @s_org_err,
        s_error              = @s_error,
        s_sev              = @s_sev,
        s_msg              = @s_msg,
        s_org              = @s_org,
        t_trn              = @t_trn,
        t_file              = @t_file,
        t_from              = @t_from,
        i_num_operacion          = @i_num_operacion,
        i_tramite          = @i_tramite,
        i_gar_anterior          = @i_gar_anterior,
        i_gar_nueva          = @i_gar_nueva,
        i_proposito               = @i_proposito
    exec cobis..sp_end_debug
end
/***********************************************************/
/* Codigos de Transacciones                                */
if (@t_trn <> 21029 and @i_operacion = 'I') or
   (@t_trn <> 21129 and @i_operacion = 'U') or
   (@t_trn <> 21229 and @i_operacion = 'D') or
   (@t_trn <> 21429 and @i_operacion = 'S') or
   (@t_trn <> 21429 and @i_operacion = 'R')
begin
/* tipo de transaccion no corresponde */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file,
    @t_from  = @w_sp_name,
    @i_num   = 2101006
    return 1
end
/* Chequeo de Existencias */
/**************************/
if @i_operacion <> 'S'
begin
   if @i_proposito = 'CNP' or @i_proposito = 'REV'
   begin
      select @w_tramite =  ga_tramite
      from cr_gar_anteriores
      where ga_tramite  = @i_tramite
      if @@rowcount > 0
         select @w_existe = 1
      else
         select @w_existe = 0
   end
   else
   begin
      select @w_proposito = tr_proposito
      from   cr_tramite
      where  tr_tramite = @i_tramite

      if @i_num_operacion is NULL
      BEGIN
            select @w_tramite = ga_tramite,
                   @w_gar_anterior = ga_gar_anterior,
                   @w_gar_nueva=ga_gar_nueva,
                   @w_num_operacion=ga_operacion,
                   @w_porcentaje =  ga_porcentaje,
                   @w_valor_cobertura = ga_valor_resp_garantia
            from   cob_credito..cr_gar_anteriores
            where  ga_tramite = @i_tramite
              and  (ga_gar_anterior = @i_gar_anterior OR @i_gar_anterior IS null)
              and  (ga_gar_nueva = @i_gar_nueva OR @i_gar_nueva IS null)    
      END    
      else
       begin
          if @w_proposito = 'CJE'
             select @w_tramite = ga_tramite,
                    @w_gar_anterior = ga_gar_anterior,
                    @w_gar_nueva=ga_gar_nueva,
                    @w_num_operacion=ga_operacion
             from cob_credito..cr_gar_anteriores
             where ga_tramite = @i_tramite
              and  (ga_gar_anterior = @i_gar_anterior OR @i_gar_anterior IS null)
              and  (ga_gar_nueva = @i_gar_nueva OR @i_gar_nueva IS null)    
             and   ga_operacion = @i_num_operacion
        else
            select @w_tramite = ga_tramite,
                    @w_gar_anterior = ga_gar_anterior,
                    @w_gar_nueva=ga_gar_nueva,
                    @w_num_operacion=ga_operacion
             from cob_credito..cr_gar_anteriores
             where ga_tramite = @i_tramite
              and  (ga_gar_anterior = @i_gar_anterior OR @i_gar_anterior IS null)
              and  (ga_gar_nueva = @i_gar_nueva OR @i_gar_nueva IS null)    
             and   ga_operacion = @i_num_operacion

      end
      if @@rowcount > 0
            select @w_existe = 1
      else
            select @w_existe = 0
   end
end
/* VALIDACION DE CAMPOS NULOS */
/******************************/
if @i_operacion = 'I' or @i_operacion = 'U'
begin
    if  @i_tramite is NULL or
       (@i_gar_anterior is NULL AND @i_operacion is NULL AND @i_gar_nueva is NULL)
    begin
    /* Campos NOT NULL con valores nulos */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = 2101001
        return 1
    end
end
/* Insercion del registro */
/**************************/
if @i_operacion = 'I'
begin
    if @w_existe = 1
    begin
    /* Registro ya existe */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = 2101002
        return 1
    end
    select @w_proposito = tr_proposito
    from   cr_tramite
    where  tr_tramite = @i_tramite

    begin tran
    if (@w_proposito = 'LEV') or
       (@w_proposito = 'ABG') or
       (@w_proposito = 'CJE')
    begin
         insert into cr_gar_anteriores(
              ga_tramite,
              ga_gar_anterior,
              ga_gar_nueva,
              ga_operacion,
              ga_porcentaje,
              ga_valor_resp_garantia)
         values (
              @i_tramite,
              @i_gar_anterior,
              @i_gar_nueva,
              @i_num_operacion,
              @i_porcentaje,
              @i_saldo)
         if @@error <> 0
         begin
         /* Error en insercion de registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file,
             @t_from  = @w_sp_name,
             @i_num   = 2103001
             return 1
         end
         /* Transaccion de Servicio */
         /***************************/
         insert into ts_gar_anteriores
         values (@s_ssn,@t_trn,'N',@s_date,@s_user,@s_term,@s_ofi,'cr_gar_anteriores',@s_lsrv,@s_srv,
         @i_tramite,
     convert(char(40),@i_gar_nueva),
     convert(char(40),@i_gar_anterior),
     @i_num_operacion,0,0)
         if @@error <> 0
         begin
         /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file,
             @t_from  = @w_sp_name,
             @i_num   = 2103003
             return 1
         end
    end
    else
    begin
        if exists (select 1
                   from  cob_credito..cr_gar_propuesta , cob_custodia..cu_custodia
                   where gp_garantia = cu_codigo_externo
                   and   gp_garantia = @i_gar_nueva
                   and   cu_abierta_cerrada = 'C' )
        begin
            /* La Garantia es Cerrada y esta amparando otro prestamo */
            exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file,
            @t_from  = @w_sp_name,
            @i_num   = 2107010
            return 1
        end

       insert into cr_gar_anteriores
              (ga_tramite, ga_gar_anterior, ga_gar_nueva, ga_operacion,     ga_porcentaje)
       values (@i_tramite, @i_gar_anterior, @i_gar_nueva, @i_num_operacion, @i_porcentaje)
       if @@error <> 0
       begin
         /* Error en insercion de registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file,
             @t_from  = @w_sp_name,
             @i_num   = 2103001
             return 1
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
        /* Registro a actualizar no existe */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = 2105002
        return 1
    end
    begin tran
        if @i_modo='G'
        begin
            update cob_credito..cr_gar_anteriores
            set ga_gar_nueva = @i_gar_nueva,
            ga_porcentaje = @i_porcentaje
            where ga_tramite = @i_tramite and
            (ga_gar_anterior = @i_gar_anterior) and
            ((ga_operacion = @i_num_operacion and @i_num_operacion is not null) or ga_operacion is null)
            if @@error != 0
            begin
                /* Error en actualizacion de registro */
                exec cobis..sp_cerror
                @t_debug = @t_debug,
                @t_file  = @t_file,
                @t_from  = @w_sp_name,
                @i_num   = 2105001
                return 1
            end
        end
        if @i_modo='O'
        begin
            update cob_credito..cr_gar_anteriores
            set ga_operacion = @i_num_operacion
            where
            ga_tramite = @i_tramite and
            (ga_gar_anterior = @i_gar_anterior AND ga_gar_nueva = @i_gar_nueva)
            if @@error != 0
            begin
                /* Error en actualizacion de registro */
                exec cobis..sp_cerror
                @t_debug = @t_debug,
                @t_file  = @t_file,
                @t_from  = @w_sp_name,
                @i_num   = 2105001
                return 1
            end
        end

        /* Transaccion de Servicio */
        /***************************/
        insert into ts_gar_anteriores
        values (@s_ssn,@t_trn,'P',@s_date,@s_user,@s_term,@s_ofi,'cr_gar_anteriores',@s_lsrv,@s_srv,
                @w_tramite,
                convert(char(40),@w_gar_nueva),
                convert(char(40),@w_gar_anterior),
                @w_num_operacion, 0, 0)
        if @@error <> 0
        begin
            /* Error en insercion de transaccion de servicio */
            exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file,
            @t_from  = @w_sp_name,
           @i_num   = 2103003
            return 1
        end

        /* Transaccion de Servicio */
        /***************************/
        insert into ts_gar_anteriores
        values (@s_ssn,@t_trn,'A',@s_date,@s_user,@s_term,@s_ofi,'cr_gar_anteriores',@s_lsrv,@s_srv,
                @i_tramite,
                convert(char(40),@i_gar_nueva),
                convert(char(40),@i_gar_anterior),
                @i_num_operacion,0,0)

        if @@error <> 0
        begin
            /* Error en insercion de transaccion de servicio */
            exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file,
            @t_from  = @w_sp_name,
            @i_num   = 2103003
            return 1
        end
    commit tran
end
/* Eliminacion de registros */
/****************************/
if @i_operacion = 'D'
begin
	set @i_modo = isnull(@i_modo,'0')
    if @i_modo <> '3' and @i_modo <> '5' and @i_modo <> '6'
    BEGIN
        --PRINT 'Existe ' + convert(VARCHAR, @w_existe)
        if @w_existe = 0
        begin
            /* Registro a eliminar no existe */
            exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file,
            @t_from  = @w_sp_name,
            @i_num   = 2107002
            return 1
        end
 
        select @w_proposito = tr_proposito
        from cr_tramite
        where tr_tramite = @i_tramite
        
        --PRINT 'Proposito' + convert(VARCHAR,@w_proposito)

        begin TRAN
            if @w_proposito is NULL OR ltrim(rtrim(@w_proposito)) = '' -- se añade proposito = NULL
            BEGIN
                --PRINT 'Va a borrar'
                if @i_gar_nueva is not null and ltrim(rtrim(@i_gar_nueva)) <> ''
                begin
	                delete from cob_credito..cr_gar_anteriores
	                where  ga_tramite = @i_tramite
	                and    ga_gar_nueva = @i_gar_nueva
	           	end
	           	if @i_gar_anterior is not null and ltrim(rtrim(@i_gar_anterior)) <> ''
                begin
	                delete from cob_credito..cr_gar_anteriores
	                where  ga_tramite = @i_tramite
	                and    ga_gar_anterior = @i_gar_anterior
	           	end   
            end
            if @w_proposito = 'ABG'
            begin
                delete from cob_credito..cr_gar_anteriores
                where  ga_tramite = @i_tramite
                and    ga_gar_nueva = @i_gar_nueva
                and    ga_operacion = @i_num_operacion
            end
            if @w_proposito = 'CJE'
            begin
                delete from cob_credito..cr_gar_anteriores
                where  ga_tramite = @i_tramite
                and    ga_gar_nueva = @i_gar_nueva
                and    ga_gar_anterior = @i_gar_anterior
            end
            if @w_proposito = 'CNP'
            begin
                delete from cob_credito..cr_gar_anteriores
                where  ga_tramite = @i_tramite
            end
            if @w_proposito = 'REV'
            begin
                delete from cob_credito..cr_gar_anteriores
                where  ga_tramite = @i_tramite
            end
            if @w_proposito = 'LEV'
            begin
                delete from cob_credito..cr_gar_anteriores
                where  ga_tramite = @i_tramite
                and    ga_gar_anterior = @i_gar_anterior
            end

            if @@error != 0
            begin
                /* Error en eliminacion de registro */
                exec cobis..sp_cerror
                @t_debug = @t_debug,
                @t_file  = @t_file,
                @t_from  = @w_sp_name,
                @i_num   = 2107001
                return 1
            end
            /* Transaccion de Servicio */
            /***************************/
            insert into ts_gar_anteriores
            values (@s_ssn,@t_trn,'B',@s_date,@s_user,@s_term,@s_ofi,'cr_gar_anteriores',@s_lsrv,@s_srv,
                    @w_tramite,
                    convert(char(40),@w_gar_nueva),
                    convert(char(40),@w_gar_anterior),
                    @w_num_operacion,0,0)
            if @@error <> 0
            begin
                /* Error en insercion de transaccion de servicio */
                exec cobis..sp_cerror
                @t_debug = @t_debug,
                @t_file  = @t_file,
                @t_from  = @w_sp_name,
                @i_num   = 2103003
                return 1
            end
        commit tran
    end

    if @i_modo='1' or @i_modo='3'
    begin
        begin tran
            delete cr_gar_anteriores
            where ga_tramite=@i_tramite
   if @@error != 0
            begin
                /* Error en eliminacion de registro */
                exec cobis..sp_cerror
                @t_debug = @t_debug,
                @t_file  = @t_file,
                @t_from  = @w_sp_name,
                @i_num   = 2107001
                return 1
            end
        commit tran
    end

    if @i_modo='2' or @i_modo = '3'
    begin
        begin tran
            delete cr_instrucciones
            where in_tramite=@i_tramite
            if @@error != 0
            begin
                /* Error en eliminacion de registro */
                exec cobis..sp_cerror
                @t_debug = @t_debug,
                @t_file  = @t_file,
                @t_from  = @w_sp_name,
                @i_num   = 2107001
                return 1
            end
        commit tran
    end


    if @i_modo='5'
    begin
        delete from cob_credito..cr_gar_anteriores
        where  ga_tramite      = @i_tramite
        and    ga_gar_nueva    = @i_gar_nueva
        and    ga_gar_anterior = @i_gar_anterior
        if @@error != 0
        begin
            /* Error en eliminacion de registro */
            exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file,
            @t_from  = @w_sp_name,
            @i_num   = 2107001
            return 2107001
        end
    end
    if @i_modo='6'
    begin
        delete from cob_credito..cr_gar_anteriores
        where  ga_tramite      = @i_tramite
        and    ga_gar_anterior = @i_gar_anterior
        if @@error != 0
        begin
            /* Error en eliminacion de registro */
            exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file,
            @t_from  = @w_sp_name,
            @i_num   = 2107001
            return 2107001
        end
    end

end
/**** Search ****/
/****************/
if @i_operacion = 'S'
begin
    set rowcount 40
    if @i_proposito = 'ABG' or @i_proposito = 'CJE'
    begin
        SELECT
            'Operacion' = ga_operacion,
            'Garantia anterior' = isnull(ga_gar_anterior,'') ,
            'Garantia nueva'    = isnull(ga_gar_nueva, ''),
            'Porcentaje'        = convert(money, str(ga_porcentaje, 6,2)),
            'Valor Operacion'   = ga_valor_resp_garantia
        FROM cr_gar_anteriores
        WHERE ga_tramite = @i_tramite
    end
    else
    begin
        select @w_spid = @@spid
        delete from cr_cotiz3_tmp
        where spid = @w_spid
        insert into  cr_cotiz3_tmp ( spid, moneda,cotizacion)
        select  DISTINCT @w_spid, ct_moneda,0  --PQU integracion
        from    cob_credito..cb_cotizaciones
        
        UPDATE cr_cotiz3_tmp 
        SET    cotizacion = (SELECT ct_valor FROM cob_credito..cb_cotizaciones WHERE ct_moneda = moneda AND ct_fecha =(
                             SELECT max(ct_fecha) FROM cob_credito..cb_cotizaciones WHERE ct_moneda = moneda        ))
        WHERE  spid = @w_spid
        --ORDER BY ct_fecha desc
        
        --SELECT * FROM cr_cotiz3_tmp WHERE spid = @w_spid
        

        if @i_gar_anterior is null
        BEGIN
            --PRINT 'Tramite ' + convert(VARCHAR, @i_tramite)
            --PRINT 'Spid ' + convert(VARCHAR, @w_spid)
            
            SELECT
                'Operacion'         = GA.ga_operacion,
                'Garantia anterior' = isnull(GA.ga_gar_anterior,''),
                'Garantia nueva'    = isnull(GA.ga_gar_nueva,''),
                'Porcentaje'        = convert( money, str(isnull(GA.ga_porcentaje,0) ,6,2)),
                'Valor Operacion'   = isnull(GA.ga_valor_resp_garantia,0),
                'Tipo'              = CU.cu_tipo,
                'Clase'             = CU.cu_abierta_cerrada,
                'Descripcion'       = substring( TC.tc_descripcion, 1, 50),
                'ValorInicial'      = CU.cu_valor_inicial,
                'FechaAvaluo'       = CU.cu_fecha_insp,
                'ValorDisponible'   = convert( money, str(isnull(CU.cu_valor_actual,0) * X.cotizacion, 16, 2)),                
                'Estado'            = substring(CE.valor,1,25)
            FROM cr_gar_anteriores GA,
                 cob_custodia..cu_custodia CU LEFT OUTER JOIN cob_custodia..cu_tipo_custodia TC ON CU.cu_tipo = TC.tc_tipo,
                 --cob_custodia..cu_custodia CU,
                 --cob_custodia..cu_tipo_custodia TC,
                 cr_cotiz3_tmp X,
                 cobis..cl_tabla TE,
                 cobis..cl_catalogo CE
            WHERE GA.ga_tramite   = @i_tramite
            and   GA.ga_gar_nueva = CU.cu_codigo_externo
            --AND   CU.cu_tipo      = TC.tc_tipo
            and   CU.cu_moneda    = X.moneda
            and   X.spid          = @w_spid
            and   TE.tabla        = 'cu_est_custodia'
            and   TE.codigo       = CE.tabla
            and   CE.codigo       = CU.cu_estado
            and   GA.ga_gar_nueva IS not null
           UNION
            SELECT
                'Operacion'         = GA.ga_operacion,
                'Garantia anterior' = isnull(GA.ga_gar_anterior,''),
                'Garantia nueva'    = isnull(GA.ga_gar_nueva,''),
                'Porcentaje'        = convert( money, str(GA.ga_porcentaje ,6,2)),
                'Valor Operacion'   = GA.ga_valor_resp_garantia,
                'Tipo'              = '',
                'Clase'             = '',
                'Descripcion'       = '',
                'ValorInicial'      = 0,
                'FechaAvaluo'       = null,
                'ValorDisponible'   = 0,
                'Estado'            = ''
            FROM  cr_gar_anteriores GA
            WHERE GA.ga_tramite   = @i_tramite
            and   GA.ga_gar_nueva is null
        end
        else
        BEGIN
            SELECT
                'Operacion' = ga_operacion,
                'Garantia anterior' = isnull(ga_gar_anterior,''),
                'Garantia nueva'    = isnull(ga_gar_nueva,''),
                'Porcentaje' =     convert( money, str(ga_porcentaje ,6,2)),
                'Valor Operacion' = ga_valor_resp_garantia,
                'Tipo'              = CU.cu_tipo,
                'Clase'             = CU.cu_abierta_cerrada,
                'Descripcion'       = substring( TC.tc_descripcion, 1, 50),
                'ValorInicial'      = CU.cu_valor_inicial,
                'FechaAvaluo'       = CU.cu_fecha_insp,
                'ValorDisponible'   = convert( money, str(isnull(CU.cu_valor_actual,0) * X.cotizacion, 16, 2)),
                'Estado'            = substring(CE.valor,1,25)
            FROM cr_gar_anteriores GA,
                 cob_custodia..cu_custodia CU LEFT OUTER JOIN cob_custodia..cu_tipo_custodia TC ON CU.cu_tipo = TC.tc_tipo,
                 cr_cotiz3_tmp X,
                 cobis..cl_tabla TE,
                 cobis..cl_catalogo CE
            WHERE GA.ga_tramite      = @i_tramite
            and   GA.ga_gar_anterior = @i_gar_anterior
            and   GA.ga_gar_nueva   IS not null
            and   GA.ga_gar_nueva = CU.cu_codigo_externo
            and   CU.cu_moneda    = X.moneda
            and   X.spid          = @w_spid
            and   TE.tabla        = 'cu_est_custodia'
            and   TE.codigo       = CE.tabla
            and   CE.codigo       = CU.cu_estado
            
      
        end
    end
    set rowcount 0
end

/**** Search para reporte ****/
/****************/
if @i_operacion = 'R'
begin
    if @i_modo = '1'
     begin
	    create table #gar1(
	    codigoGar cuenta null,
	    tipoCustodia varchar(64) null,
	    descripcion varchar(255) null,
	    tipo varchar(1) null,
	    cg_ente INT,
		duenoGarantia varchar(255) null
		)

	    insert into #gar1
	    select distinct gran.ga_gar_nueva, cu.cu_tipo, ticu.tc_descripcion , 'N',cg_ente,cg_nombre-- Para Adicionar
	    from   cob_credito..cr_gar_anteriores gran, cob_custodia..cu_tipo_custodia ticu, cob_custodia..cu_custodia cu,
	   	cob_custodia..cu_cliente_garantia WHERE cg_codigo_externo = gran.ga_gar_nueva
	    and gran.ga_tramite = @i_tramite and gran.ga_gar_nueva IS not null and cu_codigo_externo = ga_gar_nueva
		and cu.cu_tipo = ticu.tc_tipo

	    insert into #gar1
	    select distinct gran.ga_gar_anterior , cu.cu_tipo, ticu.tc_descripcion, 'E',cg_ente,cg_nombre-- Para Eliminar
	    from   cob_credito..cr_gar_anteriores gran, cob_custodia..cu_tipo_custodia ticu, cob_custodia..cu_custodia cu,
	    cob_custodia..cu_cliente_garantia WHERE cg_codigo_externo = gran.ga_gar_anterior
	    and gran.ga_tramite = @i_tramite and gran.ga_gar_anterior  IS NOT null and cu_codigo_externo = ga_gar_anterior
        and cu.cu_tipo = ticu.tc_tipo

	    insert into #gar1
	    select distinct gran.gp_garantia , cu.cu_tipo, ticu.tc_descripcion, 'A',cg_ente,cg_nombre-- Para Actual
	    from cob_credito..cr_gar_propuesta gran, cob_custodia..cu_tipo_custodia ticu, cob_custodia..cu_custodia cu,
	    cob_custodia..cu_cliente_garantia WHERE cg_codigo_externo = gran.gp_garantia
	    and gran.gp_tramite = @i_tramite and cu_codigo_externo = gran.gp_garantia
		and cu.cu_tipo = ticu.tc_tipo

        select "codigoGarantia" = codigoGar, 
		       "tipoCustodia" = tipoCustodia, 
			   "descripcion" = descripcion,
			   "tipo" = tipo,
			   "cg_ente" = cg_ente,
			   "duenoGarantia"= duenoGarantia
	    from #gar1
	  end

     if @i_modo = '2' -- similar con el modo 1
     begin
	 		select 'codigoGarantia' = gp_garantia, 
			       'tipoGarantia' = cu_tipo, 
			       'descripcionGarantia' = tc_descripcion,
			       'tipo'='',
			       'idDuenoGarantia' = cg_ente, 
			       'duenoGarantia' = cg_nombre
           from cob_credito..cr_tr_castigo, cob_cartera..ca_operacion, cob_credito..cr_gar_propuesta, cob_custodia..cu_custodia,
           cob_custodia..cu_cliente_garantia, cob_custodia..cu_tipo_custodia
           where ca_tramite = @i_tramite
           and op_banco = ca_banco
           and op_tramite = gp_tramite
           and gp_garantia = cu_codigo_externo
           and cu_codigo_externo = cg_codigo_externo
           and cu_tipo = tc_tipo
	  end

    if @i_modo = '3'
	begin

		select @w_ope_base = tr_numero_op_banco from cob_credito..cr_tramite where tr_tramite = @i_tramite
        select distinct @w_tramite_ant = op_tramite from cob_cartera..ca_operacion
		where op_banco = @w_ope_base

		select 'operacion' = @w_ope_base,
		       'tramiteAntes' = @w_tramite_ant
	end

end
return 0

GO


