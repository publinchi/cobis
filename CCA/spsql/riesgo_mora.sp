/************************************************************************/
/*      NOMBRE LOGICO:          riesgo_mora.sp                          */
/*      NOMBRE FISICO:          sp_riesgo_mora                          */
/*      BasE DE DATOS:          cob_cartera                             */
/*      PRODUCTO:               Cartera                                 */
/*      DISENADO POR:           Kevin Rodríguez                         */
/*      FECHA DE ESCRITURA:     Julio 2023                              */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada; y por lo tanto, derivará en acciones legales civiles      */
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/
/*              PROPOSITO                                               */
/* Consulta de préstamos con capital impago en cuotas vencidas (Riesgo  */
/* y Mora)                                                              */
/************************************************************************/
/*                          MODIFICACIONES                              */
/*  FECHA          AUTOR           RAZON                                */
/*  03/Jul/2023    K. Rodríguez    Emisión inicial                      */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_riesgo_mora')
    drop proc sp_riesgo_mora
go

create proc sp_riesgo_mora (
@s_user             varchar(14)  = null,
@s_date             datetime     = null,
@s_ofi              smallint     = null,
@s_term             varchar (30) = null,
@t_timeout          int          = null,
@i_oficina          smallint,
@i_oficial          smallint,
@i_tipo_cli_grp     char(1)      = null,  -- C: Cliente, G: Grupo
@i_cod_cli_grp      int          = null   -- id de cliente o grupo
)
as

declare
@w_sp_name       varchar(32),
@w_error         int,
@w_est_vigente   tinyint,
@w_est_cancelado tinyint,
@w_est_vencido   tinyint,
@w_fecha_limite  datetime,
@w_grupo         varchar(160),
@w_nom_oficial   varchar(64),
@w_cap           money,
@w_int           money,
@w_otros         money,
@w_oficina_desc  varchar(160),
@w_tot_hoy       money,
@w_dividendo     smallint,
@w_cliente_in    int,
@w_grupo_in      int

-- Variables iniciales
select @w_sp_name = 'sp_vencimientos'

exec @w_error = sp_vencimientos
@i_operacion    = 'R', --Riesgo y mora
@i_oficina      = @i_oficina,
@i_oficial      = @i_oficial,
@i_tipo_cli_grp = @i_tipo_cli_grp,
@i_cod_cli_grp  = @i_cod_cli_grp

if @w_error <> 0
   goto ERROR
   
if not exists(select 1 from ##ops_cuotas_cap_impago)
   insert into ##ops_cuotas_cap_impago values (0,0,'N/A',0,'NO SE ENCONTRARON DATOS','N/A',0,0,'N/A','01/01/1900','01/01/1900',0.0, 0.0,0.0,0.0,'01/01/1900',0)
  
select 
'COD_ASESOR'      = oficial,
'NOMBRE_ASESOR'   = nom_oficial,
'TIPO_OPERACION'  = toperacion,
'COD_GRUPO'       = grupo,	  
'COD_CLIENTE'     = cliente,
'NOM_CLIENTE'     = nom_cli,
'FECHA_INICIO'    = substring(convert(varchar, fecha_ini, 103),1, 15),
'FECHA_VEN'       = substring(convert(varchar, fecha_ven, 103),1, 15),
'MONTO_OTORGADO'  = monto,
'SALDO_CAPITAL'   = saldo_cap, 
'VALOR_RIESGO'    = valor_riesgo, 
'VALOR_MORA'      = valor_mora, 
'MAX_VENCIMIENTO' = substring(convert(varchar, max_ven, 103),1, 15),
'DIAS_MORA'       = dias_mora 
from ##ops_cuotas_cap_impago
order by oficina, oficial, toperacion

select 
'COD_OFI'        = oficina,
'OFICINA'        = desc_oficina,
'FECHA_LIMITE'   = substring(convert(varchar, fecha_limite, 103),1, 15),
'FECHA_ACTUAL'   = substring(convert(varchar, fecha_actual, 103),1, 15)
from ##ops_cuotas_cap_impago_cab

return 0
	  
ERROR:

exec cobis..sp_cerror
@t_debug='N',
@t_file='',
@t_from=@w_sp_name,
@i_num = @w_error
return @w_error

go
