use cob_cartera
go

if object_id ('sp_qr_amortiza_tmp_web') is not null
	drop procedure sp_qr_amortiza_tmp_web
go


create proc sp_qr_amortiza_tmp_web
(
    @i_banco  cuenta,  --Numero de prestamo
    @i_opcion char(1) = 'T' -- T: Todo, R: Rubros, I: Items
)
as
declare @w_operacionca int,
        @w_num_cuota   int,
        @w_saldo_cap   money,
        @w_i           int,
        @w_j           int,
        @w_query       varchar(400)

    select @w_operacionca = opt_operacion
    from   ca_operacion_tmp
    where  opt_banco = @i_banco

    delete cob_pac..ca_qr_rubro_tmp
    where  qrt_pid = @@spid

    delete cob_pac..ca_qr_amortiza_tmp
    where  qat_pid = @@spid

    insert into cob_pac..ca_qr_rubro_tmp (qrt_pid, qrt_rubro)
    select distinct @@spid, amt_concepto
    from  ca_amortizacion_tmp, ca_rubro_op_tmp
    where amt_operacion = @w_operacionca
    and   rot_operacion = amt_operacion
    and   amt_concepto = rot_concepto
    and   rot_tipo_rubro = 'C'

    insert into cob_pac..ca_qr_rubro_tmp (qrt_pid, qrt_rubro)
    select distinct @@spid, amt_concepto
    from ca_amortizacion_tmp, ca_rubro_op_tmp
    where amt_operacion = @w_operacionca
    and   rot_operacion = amt_operacion
    and   amt_concepto = rot_concepto
    and   rot_tipo_rubro = 'I'

    insert into cob_pac..ca_qr_rubro_tmp (qrt_pid, qrt_rubro)
    select distinct @@spid, amt_concepto
    from  ca_amortizacion_tmp, ca_rubro_op_tmp
    where amt_operacion = @w_operacionca
    and   rot_operacion = amt_operacion
    and   amt_concepto = rot_concepto
    and   rot_tipo_rubro not in ('C','I')

    --Rubros
    if @i_opcion = 'R' or @i_opcion = 'T'
    begin
        select co_descripcion, co_concepto
        from cob_pac..ca_qr_rubro_tmp, ca_concepto
        where qrt_pid = @@spid
        and qrt_rubro = co_concepto
        order by qrt_id
    end


    if @i_opcion = 'I' or @i_opcion = 'T'
    begin
        --INSERT DE CUOTA
        insert into cob_pac..ca_qr_amortiza_tmp (qat_pid, qat_dividendo, qat_fecha_ven, qat_cuota)
        select @@spid, dit_dividendo, dit_fecha_ven, sum(amt_cuota + amt_gracia)
        from ca_dividendo_tmp,ca_amortizacion_tmp
        where dit_operacion = @w_operacionca
        and   amt_operacion = dit_operacion
        and   amt_dividendo = dit_dividendo
        group by dit_operacion, dit_dividendo, dit_fecha_ven

        --ACTUALIZAR VALORES DE CADA RUBRO
        select @w_j = min(qrt_id)
        from   cob_pac..ca_qr_rubro_tmp
        where  qrt_pid = @@spid

        select @w_i = @w_j
        while @w_i <= @w_j + 12
        begin
            select @w_query = 'update cob_pac..ca_qr_amortiza_tmp set qat_rubro' + convert (varchar, @w_i + 1 - @w_j) + ' = amt_cuota + amt_gracia ' + char(13) +
            'from ca_dividendo_tmp, ca_amortizacion_tmp, cob_pac..ca_qr_rubro_tmp where dit_operacion = ' + convert(varchar,@w_operacionca) + char(13) +
            'and amt_operacion = dit_operacion and amt_dividendo = dit_dividendo and qat_dividendo = dit_dividendo ' + char(13) +
            'and amt_concepto = qrt_rubro and qrt_id = ' + convert(varchar, @w_i) + ' and qat_pid = ' + convert(varchar,@@spid) + char(13) +
            'and qat_pid = qrt_pid'

            execute (@w_query)

            select @w_i = @w_i + 1
        end

        --ACTUALIZACION DE VALORES DE RUBROS NEGATIVOS A CERO
        select @w_i = 1
        while @w_i <= 13
        begin
            select @w_query = 'update cob_pac..ca_qr_amortiza_tmp set qat_rubro' + convert (varchar, @w_i) + ' = 0 where qat_rubro' + convert (varchar, @w_i) + ' <0 ' +
            'and qat_pid = ' +  convert(varchar,@@spid)

            execute (@w_query)
            select @w_i = @w_i + 1
        end

        --ACTUALIZACION DE VALORES DE CUOTA NEGATIVA A CERO
        update cob_pac..ca_qr_amortiza_tmp
        set    qat_cuota = 0
        where  qat_cuota <0
        and    qat_pid = @@spid

        --ACTUALIZACION DE COLUMNA SALDO DE CAPITAL
        select @w_num_cuota = 1
        while 1 = 1
        begin
            select @w_saldo_cap = 0

            select @w_saldo_cap = sum(qat_rubro1)
            from   cob_pac..ca_qr_amortiza_tmp
            where  qat_dividendo >= @w_num_cuota
            and    qat_pid = @@spid

            if isnull(@w_saldo_cap, 0) = 0
            break

            update cob_pac..ca_qr_amortiza_tmp
            set    qat_saldo_cap = @w_saldo_cap
            where  qat_dividendo = @w_num_cuota
            and    qat_pid = @@spid

            select @w_num_cuota = @w_num_cuota + 1
        end

        select qat_dividendo,
               qat_fecha_ven,
               qat_saldo_cap,
               qat_rubro1,
               qat_rubro2,
               qat_rubro3,
               qat_rubro4,
               qat_rubro5,
               qat_rubro6,
               qat_rubro7,
               qat_rubro8,
               qat_rubro9,
               qat_rubro10,
               qat_rubro11,
               qat_rubro12,
               qat_rubro13,
               qat_cuota
        from   cob_pac..ca_qr_amortiza_tmp
        where  qat_pid = @@spid
        order by qat_dividendo
    end

    return 0


GO

