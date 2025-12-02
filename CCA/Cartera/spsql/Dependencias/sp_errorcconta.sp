
use cob_interface
go
if exists (select 1 from sysobjects where name = 'sp_errorcconta')
   drop proc sp_errorcconta 
go

create proc sp_errorcconta(
   @t_trn            int          = null,
   @i_empresa        tinyint      = null,
   @i_cuenta         cuenta       = null,
   @i_pcobis         int          = null,
   @i_operacion      char         = null,
   @i_fecha          datetime     = null,
   @i_producto       tinyint      = null,
   @i_instrumento    int          = null,
   @i_tran_modulo    int          = null,
   @i_asiento        int          = null,
   @i_fecha_conta    datetime     = null,
   @i_numerror       int          = null,
   @i_mensaje        varchar(255) = null,
   @i_perfil         varchar(10)  = null,
   @i_oficina        int          = null,
   @o_ah_cuenta      int          = null out,
   @o_ah_disponible  money        = null out,
   @o_cat_ahorro     char(1)      = null out,
   @o_tipocta        char(1)      = null out,
   @o_rolente        char(1)      = null out,
   @o_tipo_def       char(1)      = null out,
   @o_prod_banc      smallint     = null out,
   @o_producto       char(1)      = null out,
   @o_moneda         tinyint      = null out,
   @o_estado         char(1)      = null out,
   @o_cuenta_int     int          = null out,
   @o_subtipo        int          = null out
   
)
as
declare @w_error int, 
		@w_sp_name varchar(100),
		@w_msg     varchar(256)
        
select @w_sp_name      =  'sp_errorcconta'

return 0


go

