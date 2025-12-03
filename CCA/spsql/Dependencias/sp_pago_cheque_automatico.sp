/******************************************************************/
/*  Archivo:            sp_pago_cheque_automatico.sp              */
/*  Stored procedure:   sp_pago_cheque_automatico                 */
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
if exists (select 1 from sysobjects where name = 'sp_pago_cheque_automatico')
   drop proc sp_pago_cheque_automatico
go

create proc sp_pago_cheque_automatico
(
    @s_ssn             int,		
    @s_srv             varchar(30),
    @s_user            varchar(30),
    @s_sesn            int,
    @s_term            varchar(10),
    @s_date            datetime,
    @s_org             char(1),
    @s_ofi             smallint,    /* Localidad origen transaccion */
    @s_rol             smallint,
    @t_debug	       char(1)     = 'N',
    @t_trn             smallint,
    @t_file	           varchar(14) = null,
    @t_from	           varchar(30) = null,
    @t_corr            char(1)     = 'N',
    @t_ssn_corr        int         = null,
    @i_ofi             smallint,
    @i_cta	           varchar(24),
    @i_cheque	       int,
    @i_ctadep          varchar(24) = "999999999",
    @i_prod            char(3)     = "CTE",
    @i_valor	       money,
    @i_factor	       smallint    = 1,
    @i_fecha	       datetime,
    @i_duplicado       char(1)     = 'N'  ,
    @i_mon             tinyint     = 1,
    @i_alterno         int         = null,
    @i_canal	       int         = 4,
    @i_totales         char(1)     = 'S',
    @i_pit             char(1)     = 'N', --Parametro usado por la interface PIT
--ccr BRANCH III
    @i_sld_caja	       money       = 0,
    @i_idcierre        int         = 0,
    @i_filial          smallint    = 1,
    @i_idcaja          int         = 0,
    @i_fecha_valor_a   datetime    = null,

    @o_prod_banc       smallint    = null out,
    @o_categoria       char(3)     = null out,
    @o_tipocta         char(1)     = null out,
    @o_clase_clte      char(1)     = null out
)
as

return 0
go

