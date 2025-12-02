/***********************************************************************/
/*      Archivo:                        grupo_castigo.sp               */
/*      Stored procedure:               sp_grupo_castigo               */
/*      Base de Datos:                  cob_credito                    */
/*      Producto:                       Credito                        */
/*      Disenado por:                   Jose Escobar                   */
/***********************************************************************/
/*        IMPORTANTE                                                   */
/*  Este programa es parte de los paquetes bancarios propiedad de      */
/*  "COBISCORP", representantes exclusivos para el Ecuador de la       */
/*  "COBISCORP CORPORATION".                                           */
/*  Su uso no autorizado queda expresamente prohibido asi como         */
/*  cualquier alteracion o agregado hecho por alguno de sus            */
/*  usuarios sin el debido consentimiento por escrito de la            */
/*  Presidencia Ejecutiva de COBISCORP o su representante.             */
/***********************************************************************/
/*                      PROPOSITO                                      */
/*  Mantenimiento a la tabla cr_grupo_castigo que tiene la cabecera    */
/*  con los paquetes de operaciones para proceso de Castigo            */
/*                                                                     */
/***********************************************************************/
/*                      MODIFICACIONES                                 */
/*      FECHA           AUTOR                   RAZON                  */
/*      05/Ago/2015     Jose Escobar            Emision Inicial        */
/*                                                                     */
/***********************************************************************/
use cob_credito
go
if exists(select 1 from sysobjects where name ='sp_grupo_castigo')
    drop proc sp_grupo_castigo
go

create proc sp_grupo_castigo (
    @s_ssn                  int         = null,
    @s_srv                  varchar(30) = null,
    @s_lsrv                 varchar(30) = null,
    @s_rol                  smallint    = null,
    @s_org                  char(1)     = null,
    @s_user                 login       = null,
    @s_sesn                 int         = null,
    @s_ofi                  int         = null,
    @s_date                 datetime    = null,
    @s_term                 varchar(30) = null,
    @s_culture              varchar(10) = null,
    @t_trn                  smallint    = null,
    @t_debug                char(1)     = 'N',
    @t_file                 varchar(14) = null,
    @t_from                 varchar(30) = null,
    @i_ssn                  int         = null,
    @i_operacion            char(1)     = null,
    @i_grupo                int         = null,
    @i_padre                int         = null,
    @i_fecha_corte          datetime    = null,
    @i_tipo                 char(2)     = null,
    @i_etapa                smallint    = null,
    @i_coherencia           varchar(255)= null,
    @i_comentario           varchar(255)= null,
    @i_sindico1             varchar(64) = null,
    @i_sindico2             varchar(64) = null,
    @o_grupo                int         = null out,
    @o_instancia_proceso    int         = null out
)
as
declare @w_sp_name              varchar(32),
        @w_error                int,
        @w_grupo                int,
        @w_padre                int,
        @w_estado               char(1),
        @w_emplazamiento        catalogo,
        @w_fecha_corte          datetime,
        @w_tipo_etapa_anterior  char(2),
        @w_etapa                int,
        @w_retorno              int,
        @w_fecha                varchar(10),
        @w_nemonicoflujocastigo catalogo,
        @w_codigoflujocastigo   smallint,
		@w_check                char(1),
		@w_paramMassive  	    char(2)

set @w_sp_name = 'sp_grupo_castigo'

if (@t_trn <> 22310 and @i_operacion = 'I') or
   (@t_trn <> 22311 and @i_operacion = 'U') or
   (@t_trn <> 22312 and @i_operacion = 'C') or
   (@t_trn <> 22313 and @i_operacion = 'Q') or
   (@t_trn <> 22313 and @i_operacion = 'R') or
   (@t_trn <> 22311 and @i_operacion = 'A') or
   (@t_trn <> 22313 and @i_operacion = 'B')

begin --Tipo de transaccion no corresponde
   select @w_error = 2101006
   goto ERROR
end

select @w_paramMassive = pa_char
  from cobis..cl_parametro
  where pa_nemonico = 'CASOMA'
    and pa_tipo = 'C'
    and pa_producto = 'CCA'
if(@w_paramMassive is not null and @w_paramMassive ='S')
	select @w_check = 'S'
else
    select @w_check = 'N'

if @i_operacion = 'I' or @i_operacion = 'Q'
begin
--tomando la fecha de corte
	if @i_grupo is not null
		begin
			select @w_fecha_corte = gc_fecha_corte
			from   cr_grupo_castigo
			where  gc_codigo      = @i_grupo
		end
		else
		begin
			set @w_fecha_corte = @i_fecha_corte
			if @w_fecha_corte is null
			begin
				select @w_fecha_corte = max(ca_fecha_corte)
				from   cr_tr_castigo
			end
		end
--si existe o no un grupo con la fecha de corte actual
if(@i_tipo <> 'IN')
begin
	if exists(select 1 from cob_credito..cr_grupo_castigo where gc_fecha_corte=@w_fecha_corte and gc_tipo<>'IN')
		set @i_tipo = 'AC'
end
    if @i_tipo = 'JA' --JEFE AGENCIA
    begin
        set @w_emplazamiento = convert(varchar(10),@s_ofi)
    end
    if @i_tipo = 'AC' --ANALISTA DE CREDITO
    begin
        set @w_tipo_etapa_anterior = 'JA'--GR
        set @w_emplazamiento = convert(varchar(10),@s_ofi)
    end
    if @i_tipo = 'IN' --INBOX
    begin
        set @w_emplazamiento = convert(varchar(10),@i_etapa)
        set @w_tipo_etapa_anterior = 'AC'
        if(@i_operacion = 'Q')
        begin
            if(@i_etapa=2)
            begin
                set @i_etapa = 1
            end
            if(@i_etapa>=3)
            begin
                set @w_tipo_etapa_anterior = 'IN'
                if not exists ( select 1
                                from   cr_grupo_castigo
                                where  gc_tipo          = @i_tipo
                                and    gc_emplazamiento = convert(varchar(10),@i_etapa-1)
                                and    gc_fecha_corte   = @i_fecha_corte
                                and    gc_padre         = @i_padre )
                begin
                    set @w_tipo_etapa_anterior = 'AC'
                    set @i_etapa = 1
                end
            end
        end
    end
end


if @i_operacion = 'I'
begin
    exec cobis..sp_cseqnos
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_tabla = 'cr_grupo_castigo',
         @o_siguiente = @o_grupo out
    if @o_grupo is NULL
    begin
           select @w_error = 2101007
           goto ERROR
    end
    set @i_grupo = @o_grupo

    BEGIN TRAN
        insert into  cr_grupo_castigo
              ( gc_codigo , gc_fecha_corte , gc_login , gc_tipo , gc_emplazamiento , gc_estado , gc_padre )
        values( @i_grupo  , @i_fecha_corte , @s_user  , @i_tipo , @w_emplazamiento , 'I'       , isnull(@i_padre,0))
        if @@error <> 0
        begin
            ROLLBACK TRAN
            select @w_error = 2103001
            goto ERROR
        end

        insert into cr_grupo_tran_castigo
             ( gt_grupo , gt_tran_castigo  , gt_estado , gt_recomendada )
        select @i_grupo , gtm_tran_castigo ,       'I' , gtm_recomendada
        from   cr_grupo_tran_castigo_tmp
        where  gtm_grupo = @i_ssn
        if @@error <> 0
        begin
            ROLLBACK TRAN
            select @w_error = 2103001
            goto ERROR
        end

        insert into cr_observacion_castigo
             ( oc_grupo , oc_tran_castigo  , oc_observacion )
        select @i_grupo , oct_tran_castigo , oct_observacion
        from   cr_observacion_castigo_tmp
        where  oct_grupo = @i_ssn
        if @@error <> 0
        begin
            ROLLBACK TRAN
            select @w_error = 2103001
            goto ERROR
        end

        delete cr_grupo_tran_castigo_tmp
        where  gtm_grupo = @i_ssn

        delete cr_observacion_castigo_tmp
        where  oct_grupo = @i_ssn

    COMMIT tran
    return 0
end --FIN - @i_operacion = 'I'

if @i_operacion = 'U'
begin
    if @i_grupo is NULL
    begin
           select @w_error = 708150
           goto ERROR
    end

    BEGIN TRAN
        delete cr_grupo_tran_castigo
        where  gt_grupo = @i_grupo

        delete cr_observacion_castigo
        where  oc_grupo = @i_grupo

        insert into cr_grupo_tran_castigo
             ( gt_grupo , gt_tran_castigo  , gt_estado , gt_recomendada )
        select @i_grupo , gtm_tran_castigo ,       'I' , gtm_recomendada
        from   cr_grupo_tran_castigo_tmp
        where  gtm_grupo = @i_ssn
        if @@error <> 0
        begin
            ROLLBACK TRAN
            select @w_error = 2103001
            goto ERROR
        end

        insert into cr_observacion_castigo
             ( oc_grupo , oc_tran_castigo  , oc_observacion )
        select @i_grupo , oct_tran_castigo , oct_observacion
        from   cr_observacion_castigo_tmp
        where  oct_grupo = @i_ssn
        if @@error <> 0
        begin
            ROLLBACK TRAN
            select @w_error = 2103001
            goto ERROR
        end

        delete cr_grupo_tran_castigo_tmp
        where  gtm_grupo = @i_ssn

        delete cr_observacion_castigo_tmp
        where  oct_grupo = @i_ssn

    COMMIT tran
    return 0
end --FIN  - @i_operacion = 'U'

if @i_operacion = 'C'
begin
    select @w_fecha_corte = gc_fecha_corte
    from   cr_grupo_castigo
    where  gc_codigo      = @i_grupo

    if @i_tipo = 'AC' --ANALISTA DE CREDITO -> Crea Nuevo flujo 'CONSOLIDACION DE CASTIGO'
    begin
        set @w_fecha = convert(varchar(10),@w_fecha_corte,101)
        select @w_nemonicoflujocastigo = pa_char from cobis..cl_parametro where pa_nemonico = 'CAFLUA'
        select @w_codigoflujocastigo = pr_codigo_proceso from cob_workflow..wf_proceso where pr_nemonico = @w_nemonicoflujocastigo
        if @@rowcount  = 0
        begin
            select @w_error = 2103025 --No se pudo encontrar el flujo de CONSOLIDACION DE CASTIGO, revise que el nemónico coincida con el parámetro CAFLUA
            goto ERROR
        end
    end
print 'w_codigoflujocastigo '+ convert(varchar,@w_codigoflujocastigo)
    BEGIN TRAN
        if @i_tipo = 'AC' --ANALISTA DE CREDITO -> Crea Nuevo flujo 'CONSOLIDACION DE CASTIGO'
        begin
            exec @w_retorno = cob_workflow..sp_inicia_proceso_wf
            @i_login =@s_user,
            @i_id_proceso=@w_codigoflujocastigo,
            @i_campo_1=0,
            @i_campo_2=null,
            @i_campo_3=@i_grupo,
            @i_campo_4=@w_fecha,
            @i_id_empresa=1,
            @t_trn=73506,
            @s_srv=@s_srv,
            @s_user=@s_user,
            @s_term=@s_term,
            @s_ofi=@s_ofi,
            @s_rol=@s_rol,
            @s_ssn=@s_ssn,
            @s_lsrv=@s_lsrv,
            @s_date=@s_date,
            @s_sesn=@s_sesn,
            @s_org=@s_org,
            @s_culture=@s_culture,
            @o_siguiente=@o_instancia_proceso out
            if @w_retorno <> 0
            begin
                ROLLBACK TRAN
                select @w_error = @w_retorno
                goto ERROR
            end
        end

        update cr_grupo_castigo
        set    gc_estado     = 'P',
               gc_coherencia = @i_coherencia,
               gc_comentario = @i_comentario
        where  gc_codigo     = @i_grupo
        if @@error <> 0
        begin
            ROLLBACK TRAN
            select @w_error = 2105001
            goto ERROR
        end

        update cr_grupo_tran_castigo
        set    gt_estado = 'P'
        where  gt_grupo = @i_grupo
        if @@error <> 0
        begin
            ROLLBACK TRAN
            select @w_error = 2105001
            goto ERROR
        end

        update cr_tr_castigo
        set    ca_estado = case when gt_recomendada = 'S' then 'G' else 'D' end
        from   cr_grupo_tran_castigo
        where  gt_grupo       = @i_grupo
        and    ca_int_proceso = gt_tran_castigo
        and    ca_fecha_corte = @w_fecha_corte
        if @@error <> 0
        begin
            ROLLBACK TRAN
            select @w_error = 2105001
            goto ERROR
        end

    COMMIT tran
    return 0
end --FIN  - @i_operacion = 'C'


if @i_operacion = 'Q'
begin
    create table #operaciones (
        Codigo        int,
        Banco         varchar(24),
        Observacion   varchar(255) null,
        Recomendada   char(1) default 'S',
        Cliente       int,
        SaldoCapFecha money default 0 null,
        SaldoIntFecha money default 0 null,
        OpCodigo      int null,
        OpTipoCobro   char(1) null,--op_monto
        Oficina       int null,
        EstadoOperacion tinyint null,
        MontoDesembolso money default 0,
        EstadoCastigo   char(1) default 'R'
    )

    if @i_grupo is not null
    begin
        select @w_padre       = gc_padre,
               @w_estado      = gc_estado,
               @w_fecha_corte = gc_fecha_corte
        from   cr_grupo_castigo
        where  gc_codigo      = @i_grupo
    end
    else
    begin
        set @w_fecha_corte = @i_fecha_corte
        if @w_fecha_corte is null
        begin
            select @w_fecha_corte = max(ca_fecha_corte)
            from   cr_tr_castigo
        end

        --DATOS CABECERA
        select @i_grupo  = gc_codigo,
               @w_padre  = gc_padre,
               @w_estado = gc_estado
        from   cr_grupo_castigo
        where  gc_tipo          = @i_tipo
        and    gc_emplazamiento = @w_emplazamiento
        and    gc_fecha_corte   = @w_fecha_corte
    end

    --INFORMACION DE GRUPOS CERRADOS (estado P)
    if @i_grupo is not null  and  @w_estado = 'P'
    begin
            insert into #operaciones (Codigo,Banco,Cliente)
            select 'Codigo'       = ca_int_proceso,
                   'Banco'        = ca_banco,
                   'Cliente'      = ca_cliente
            from   cr_grupo_castigo G
            inner join cr_grupo_tran_castigo C on G.gc_codigo = C.gt_grupo
            inner join cr_tr_castigo T on T.ca_int_proceso = C.gt_tran_castigo
            where  G.gc_codigo    = @i_grupo
            and    G.gc_tipo      = @i_tipo
            and    G.gc_estado    = 'P'
    end
    else
    begin
		if @i_tipo = 'JA' --JEFE AGENCIA
		begin
			insert into #operaciones (Codigo,Banco,Cliente,EstadoCastigo)
			select 'Codigo'        = T.ca_int_proceso,
				   'Banco'         = T.ca_banco,
				   'Cliente'       = T.ca_cliente,
				   'EstadoCastigo' = T.ca_estado
			from   cr_tr_castigo T , cob_cartera..ca_operacion O
			where  O.op_banco      = T.ca_banco
			--and    O.op_oficina    = @s_ofi-- JRU la consulta de estos procesos son para todas las oficinas
			and    T.ca_fecha_corte= @w_fecha_corte
			and    T.ca_estado    != 'D'
		end

        if @i_tipo = 'AC' --ANALISTA DE CREDITO
        begin--cuando no se ha recomendado
			if not exists(select 1 from cr_grupo_castigo where gc_estado='P' and gc_fecha_corte = @w_fecha_corte)
			begin
				insert into #operaciones (Codigo,Banco,Cliente,EstadoCastigo)
				select 'Codigo'        = T.ca_int_proceso,
					   'Banco'         = T.ca_banco,
					   'Cliente'       = T.ca_cliente,
					   'EstadoCastigo' = T.ca_estado
				from   cr_tr_castigo T , cob_cartera..ca_operacion O
				where  O.op_banco      = T.ca_banco
				--and    O.op_oficina    = @s_ofi-- JRU la consulta de estos procesos son para todas las oficinas
				and    T.ca_fecha_corte= @w_fecha_corte
				and    T.ca_estado    != 'D'
			end
			else
			begin
				insert into #operaciones (Codigo,Banco,Cliente)
				select 'Codigo'       = ca_int_proceso,
					   'Banco'        = ca_banco,
					   'Cliente'      = ca_cliente
				from   cr_grupo_castigo G
				inner join cr_grupo_tran_castigo  C on G.gc_codigo = C.gt_grupo and C.gt_recomendada = 'S'
				inner join cr_tr_castigo T on T.ca_int_proceso = C.gt_tran_castigo
				where  G.gc_fecha_corte = @w_fecha_corte
				and    G.gc_tipo        = @w_tipo_etapa_anterior
				and    G.gc_estado      = 'P'
			end
        end
        if @i_tipo = 'IN' --DESDE EL INBOX
        begin
            if(@i_etapa=1)
            begin
                insert into #operaciones (Codigo,Banco,Cliente)
                select 'Codigo'         = ca_int_proceso,
                       'Banco'          = ca_banco,
                       'Cliente'        = ca_cliente
                from   cr_grupo_castigo G
                inner join cr_grupo_tran_castigo  C on G.gc_codigo = C.gt_grupo and C.gt_recomendada = 'S'
                inner join cr_tr_castigo T on T.ca_int_proceso = C.gt_tran_castigo
                where  G.gc_codigo      = @i_padre
                --where  G.gc_fecha_corte = @w_fecha_corte
                --and    G.gc_tipo        = @w_tipo_etapa_anterior --'AC'
                --and    G.gc_estado      = 'P'
            end
            else
            begin
                insert into #operaciones (Codigo,Banco,Cliente)
                select 'Codigo'         = ca_int_proceso,
                       'Banco'          = ca_banco,
                       'Cliente'        = ca_cliente
                from   cr_grupo_castigo G
                inner join cr_grupo_tran_castigo  C on G.gc_codigo = C.gt_grupo and C.gt_recomendada = 'S'
                inner join cr_tr_castigo T on T.ca_int_proceso = C.gt_tran_castigo
                where  G.gc_fecha_corte = @w_fecha_corte
                and    G.gc_tipo        = @w_tipo_etapa_anterior --'IN'
                and    G.gc_emplazamiento = convert(varchar(10),@i_etapa-1) --SI NO TIENE DATOS => CONSULTA DEL EMPLAZAMIENTO(etapa) ANTERIOR
                and    G.gc_estado      = 'P'
            end
        end
    end

    --ACTUALIZA RECOMENDADA
    update #operaciones
    set    Recomendada     = gt_recomendada
    from   cr_grupo_tran_castigo
    where  gt_grupo        = @i_grupo
    and    gt_tran_castigo = Codigo

    --ACTUALIZA OBSERVACION
    update #operaciones
    set    Observacion = oc_observacion
    from   cr_observacion_castigo
    where  Codigo = oc_tran_castigo
    and    oc_grupo   = @i_grupo

    --ACTUALIZA CAPITAL E INTERES A LA FECHA
    update #operaciones
    set    OpCodigo    = op_operacion,
           OpTipoCobro = op_tipo_cobro,
           Oficina     = op_oficina,
           EstadoOperacion = op_estado,
           MontoDesembolso = op_monto
    from   cob_cartera..ca_operacion
    where  Banco       = op_banco

    --CAPITAL A LA FECHA
    update #operaciones
    set    SaldoCapFecha = (select sum(am_cuota - am_pagado) --CAPITAL A LA FECHA
                            from    cob_cartera..ca_amortizacion, cob_cartera..ca_rubro_op
                            where   am_operacion   = OP.OpCodigo
                            and     am_operacion   = ro_operacion
                            and     am_concepto    = ro_concepto
                            and     ro_tipo_rubro  = 'C' )
    from   #operaciones OP

    --INTERES A LA FECHA
    update #operaciones
    set    SaldoIntFecha = (select sum(((am_cuota+am_gracia)+abs(am_cuota+am_gracia))/2 -am_pagado-am_exponencial)
                            from   cob_cartera..ca_amortizacion, cob_cartera..ca_rubro_op, cob_cartera..ca_dividendo
                            where  am_operacion  =  OP.OpCodigo
                            and    ro_operacion  =  OP.OpCodigo
                            and    di_operacion  =  OP.OpCodigo
                            and    am_concepto   =  ro_concepto
                            and    am_dividendo  =  di_dividendo
                            and    di_estado    in (1,2)  --Vigente y Vencido
                            and    ro_tipo_rubro =  'I' )
    from   #operaciones OP
    where  OP.OpTipoCobro = 'P'

    update #operaciones
    set    SaldoIntFecha = (select sum(am_acumulado -am_pagado -am_exponencial)
                            from   cob_cartera..ca_amortizacion, cob_cartera..ca_rubro_op, cob_cartera..ca_dividendo
                            where  am_operacion  =  OP.OpCodigo
                            and    ro_operacion  =  OP.OpCodigo
                            and    di_operacion  =  OP.OpCodigo
                            and    am_concepto   =  ro_concepto
                            and    am_dividendo  =  di_dividendo
                            and    ro_tipo_rubro =  'I' )
    from   #operaciones OP
    where  OP.OpTipoCobro <> 'P'

    --RESULT SET
    select 'GRUPO'  = isnull(@i_grupo,0),
           'PADRE'  = isnull(@w_padre,0),
           'ESTADO' = isnull(@w_estado,'X'),
           'FECHA'  = @w_fecha_corte

    select 'Codigo'       = OP.Codigo,
           'Banco'        = OP.Banco,
           'Observacion'  = isnull(OP.Observacion,''),
           'Recomendada'  = OP.Recomendada,
           'SaldoCap'     = CC.cc_saldo_cap,
           'SaldoInt'     = CC.cc_saldo_int,
           'Moneda'       = CC.cc_moneda_op,
           'Cliente'      = EN.en_nomlar,
           'CapFecha'     = isnull(OP.SaldoCapFecha,0),
           'IntFecha'     = isnull(OP.SaldoIntFecha,0),
           'Oficina'      = OP.Oficina,
           'EstadoOperacion' = OP.EstadoOperacion,
           'MontoDesembolso' = OP.MontoDesembolso,
           'EstadoCastigo'   = OP.EstadoCastigo,
           'RO'              = case when isnull(OP.MontoDesembolso,0)!=0 then isnull(OP.SaldoCapFecha,0)/OP.MontoDesembolso else 0 end
    from   #operaciones OP
    inner join cob_cartera..ca_candidata_castigo CC on CC.cc_fecha_corte = @w_fecha_corte AND CC.cc_banco = OP.Banco
	       AND (OP.Banco in (select ca_banco from cob_credito..cr_tr_castigo
		                      where ca_fecha_corte = @w_fecha_corte
                              and ca_estado in ('R', 'G')) and (cc_check = @w_check or (cc_check is null and @w_check = 'N') ))
    inner join cobis..cl_ente EN on EN.en_ente = OP.Cliente

    select 'Oficina'       = OP.Oficina,
           'Moneda'        = CC.cc_moneda_op,
           'TotalCap'      = sum( isnull(CC.cc_saldo_cap,0) ),
           'TotalCapFecha' = sum( isnull(OP.SaldoCapFecha,0) )
           from   #operaciones OP
    inner join cob_cartera..ca_candidata_castigo CC on CC.cc_fecha_corte = @w_fecha_corte AND CC.cc_banco = OP.Banco
	       AND (OP.Banco in (select ca_banco from cob_credito..cr_tr_castigo
		                      where ca_fecha_corte = @w_fecha_corte
                               and ca_estado in ('R', 'G')) and (cc_check = @w_check or (cc_check is null and @w_check = 'N') ))
    group by OP.Oficina, CC.cc_moneda_op
	order by Oficina asc

    return 0
end --FIN  - @i_operacion = 'Q'

-- Opcion para reporte de declaracion juramentada
if @i_operacion = 'R'
begin
    if @i_grupo is not null
    begin
        declare @codigo int,
                @moneda int,
                @cotizUSD    float,
                @w_MLO int,
                @USD tinyint,
                @cotizMLO float

        CREATE TABLE #cotizacion_tmp (
            ct_moneda  tinyint null,
            ct_valor   money null
            )

        select @codigo = codigo
          from cobis..cl_tabla
         where tabla = 'cl_regional'

        select codigo, valor
        into #regional
        from cobis..cl_catalogo
        where tabla = @codigo

        select @w_MLO = pa_tinyint
          from cobis..cl_parametro
         where pa_producto = 'ADM' and pa_nemonico = 'MLO'

        insert into #cotizacion_tmp
        (ct_moneda,ct_valor )
        select ct_moneda,ct_valor
        from cob_cartera..cotizacion cot
        where ct_fecha = (select max(ct_fecha) from cob_cartera..cotizacion
                          where ct_moneda = cot.ct_moneda)

        select @cotizMLO = ct_valor
          from #cotizacion_tmp
         where ct_moneda = @w_MLO

        select @USD = mo_moneda
          from cobis..cl_moneda
         where mo_simbolo = 'USD'

        select @cotizUSD = ct_valor
          from #cotizacion_tmp
         where ct_moneda = @USD

        --Mapeo de campos para el front end
        select  'REGIONAL'     = (select valor from #regional where codigo = cs.ca_regional),
                'AGENCIA'         = (select of_nombre from cobis..cl_oficina where of_oficina = cs.ca_agencia),
                'NRO_CREDITO'     = ca_banco,
                'SALDO_BS'        = isnull((CASE when @w_MLO = op.op_moneda then
                                           (select sum (isnull(cc_saldo_cap,0) + isnull(cc_saldo_int,0) + isnull(cc_saldo_mora,0) + isnull(cc_saldo_otros,0))
                                            from cob_cartera..ca_candidata_castigo where cc_banco = cs.ca_banco) end),0),
                                     -- se comenta porq no es necesario convertir
                                     -- else ((select sum(cc_saldo_cap + cc_saldo_int + cc_saldo_mora + cc_saldo_otros ) from cob_cartera..ca_candidata_castigo where cc_banco = tr.ca_banco) * @cotizMLO) end),
                'SALDO_US'       = isnull((CASE when @w_MLO != op.op_moneda then
                                          (select sum(isnull(cc_saldo_cap,0) + isnull(cc_saldo_int,0) + isnull(cc_saldo_mora,0) + isnull(cc_saldo_otros,0))
                                           from cob_cartera..ca_candidata_castigo where cc_banco = cs.ca_banco) end),0),
                                    -- se comenta porq no es necesario convertir
                                    -- else ((select ROUND(sum(cc_saldo_cap + cc_saldo_int + cc_saldo_mora + cc_saldo_otros ),1) from cob_cartera..ca_candidata_castigo where cc_banco = tr.ca_banco) / @cotizUSD) end)
                'COD_DEUDOR' = op.op_cliente,
                'NOMBRE_DEUDOR' = op.op_nombre,
                'NUM_PROCESO' = cs.ca_int_proceso,
                'NU_TRAMITE' = cs.ca_tramite,
                'NU_OFICINA' = op.op_oficina
        from cob_credito..cr_tr_castigo cs,
             cob_credito..cr_grupo_castigo gc,
             cob_credito..cr_grupo_tran_castigo gtc,
             cob_cartera..ca_operacion op
        where gc.gc_codigo = gtc.gt_grupo
          and gtc.gt_tran_castigo = cs.ca_int_proceso
          and op_banco = cs.ca_banco
          and gc.gc_codigo = @i_grupo
        group by ca_regional, ca_agencia, ca_banco, op.op_moneda, op_cliente, op_nombre, ca_int_proceso, ca_tramite

    end

end --FIN  - @i_operacion = 'R'

-- Opcion para actualizar sindicos del grupo
if @i_operacion = 'A'
begin

    if @i_grupo is NULL
    begin
           select @w_error = 708150
           goto ERROR
    end

    BEGIN TRAN
        update cr_grupo_castigo
        set    gc_sindico1  = @i_sindico1,
               gc_sindico2     = @i_sindico2
        where  gc_codigo    = @i_grupo
        if @@error <> 0
        begin
            ROLLBACK TRAN
            select @w_error = 2105001
            goto ERROR
        end

    COMMIT tran
    return 0
end --FIN  - @i_operacion = 'A'

-- OPCION DE BUSQUEDA DE SINDICOS
if @i_operacion = 'B'
begin
    if @i_grupo is not null
    begin
        select     gc_fecha_corte,
                   gc_sindico1,
                   gc_sindico2
          from    cr_grupo_castigo
         where    gc_codigo  = @i_grupo
    end
    else
    begin
        select @w_error = 708150
        goto ERROR
    end
end    -- FIN BUSQUEDA DE SINDICOS


return 0

ERROR:
    exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = @w_error
    return @w_error


go
