/******************************************************************/
/*  Archivo:            ccndc_automatica_batch.sp                 */
/*  Stored procedure:   sp_ccndc_automatica_batch                 */
/*  Base de datos:      cob_interface                             */
/*  Producto:           Cuentas                                   */
/*  Disenado por:                                                 */
/*  Fecha de escritura: 18-Oct-2016                               */
/******************************************************************/
/*                        IMPORTANTE                              */
/*  Este programa es parte de los paquetes bancarios propiedad de */
/*  'MACOSA', representantes exclusivos para el Ecuador de la     */
/*  'NCR CORPORATION'.                                            */
/*  Su uso no autorizado queda expresamente prohibido asi como    */
/*  cualquier alteracion o agregado hecho por alguno de sus       */
/*  usuarios sin el debido consentimiento por escrito de la       */
/*  Presidencia Ejecutiva de MACOSA o su representante.           */
/******************************************************************/
/*                          PROPOSITO                             */
/******************************************************************/
/*                        MODIFICACIONES                          */
/*  FECHA              AUTOR            RAZON                     */
/*  18-Oct-2016        Jorge Salazar    Sp dummy como dependencia */
/******************************************************************/
use cob_interface
go
if exists (select 1 from sysobjects where name = 'sp_ccndc_automatica_batch')
   drop proc sp_ccndc_automatica_batch
go

create proc sp_ccndc_automatica_batch
(
    @s_srv             varchar(30),
    @s_ofi             smallint,
    @s_ssn             int,
    @s_ssn_branch      int = null,
    @s_user            varchar(24) = 'CTE',
    @s_org             char(1)     = 'L',
    @s_lsrv            varchar(30) = null,
    @s_term            varchar(10) = 'consola',
    @s_date            datetime    = null,
    @t_trn             int,
    @t_ssn_corr        int         = null,
	@t_ejec            char(1)     = null,
	@i_cta             cuenta,
    @i_val             money       = null,
    @i_cau             varchar(3),
    @i_mon             tinyint,
    @i_dep             tinyint     = 1,
    @i_alt             int = 0,
    @i_fecha           datetime,
    @i_interes         money       = null,
    @i_comision        money       = 0,
    @i_solca           money       = null,
    @i_mora            money       = 0,
    @i_tinteres        real        = null,
    @i_tcomision       real        = null,
    @i_tsolca          real        = null,
    @i_tmora           real        = null,
    @i_reverso         char(1)     = null,
    @i_changeofi       char(1)     = 'N',
    @i_nchq            int         = null,
    @i_valch           money       = null,
    @i_cobsus          char(1)     = 'N',
    @i_inmovi          char(1)     = 'N',
    @i_cobiva          char(1)     = 'N', 
    @i_corr            char(1)     = 'N',
    @i_ind             int         = 1,
    @i_canal           tinyint     = null,
    @i_bloq_cta        char(1)     = 'N',
    @i_afecta_minimo   char(1)     = 'N',
    @i_accion          char(1)     = 'E',
    @i_impues_trans    smallint    = null,
    @i_modulo          smallint    = null, 
    @i_enlinea         char(1)	   = 'S',
    @i_bloq_no         char(1)     = null,
    @i_bloq_sob        char(1)     = null,
    @i_sin_cobro_imp   char(1)     = 'N',
    @i_concepto        varchar(64) = null,
    @i_pit             char(1)     = 'N',
    @i_iva             money       = null,
    @i_trn_cenit       int         = 0, 
    @i_origen          char(1)     = null,
    @o_clase_clte      char(1)     = null out,
    @o_prod_banc       tinyint     = null out,
    @o_valiva          money       = null out,
    @o_valnxmil        money       = null out,
    @o_tipo_cobro      char(1)     = 'N' out
)
as

return 0
go

