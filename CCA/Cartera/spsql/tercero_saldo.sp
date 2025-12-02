use cob_conta
go
 
if exists (select 1 from sysobjects where name = 'sp_saltercero')
   drop proc sp_saltercero
go
 
create proc sp_saltercero

(
    @i_empresa     tinyint,

    @i_cuenta      varchar(14),

    @i_ente        int,

    @i_fecha       datetime,

    @i_oficina     smallint,
    @i_area        smallint,

    @o_saldo_real  money   out
)
as

declare 
    @w_fecha_fm      smalldatetime,

    @w_corte         smallint,

    @w_periodo       smallint,

    @w_saldo         money,

    @w_saldo_1       money
   


select @o_saldo_real = 0

select @w_saldo      = 0

select @w_saldo_1    = 0

select @w_fecha_fm   = dateadd(dd, -1*datepart(dd,@i_fecha), @i_fecha)



select @w_saldo_1 = isnull(sum(isnull(sa_debito,0)),0) - isnull(sum(isnull(sa_credito,0)),0)

from  cob_conta_tercero..ct_sasiento --(index = ct_sasiento_AKey3)

where sa_cuenta       = @i_cuenta

and   sa_fecha_tran  <= @i_fecha
and   sa_fecha_tran   > @w_fecha_fm

and   sa_oficina_dest = @i_oficina

and   sa_area_dest    = @i_area

and   sa_ente         = @i_ente
--and   sa_mayorizado   = 'S'

    

select 
@w_corte    = co_corte,

@w_periodo  = co_periodo

from cob_conta..cb_corte

where co_fecha_ini = @w_fecha_fm

and   co_empresa   = @i_empresa



select @w_saldo = st_saldo

from cob_conta_tercero..ct_saldo_tercero --(index = ct_saldo_tercero_Key_ente)

where st_cuenta  = @i_cuenta

and   st_corte   = @w_corte

and   st_periodo = @w_periodo

and   st_ente    = @i_ente
and   st_area    = @i_area



select @o_saldo_real = isnull(@w_saldo, 0)  + isnull(@w_saldo_1, 0)


return 0


go