/************************************************************************/
/*  Archivo:        imp_ofic.sp                                         */
/*  Stored procedure:   sp_imprimir_oficina                             */
/*  Base de datos:      cob_cartera                                     */
/*  Producto:       Cartera                                             */
/*  Disenado por:       Francisco Yacelga                               */
/*  Fecha de escritura:     03/Dic./1997                                */
/************************************************************************/
/*              IMPORTANTE                                              */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  "MACOSA".                                                           */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado hecho por alguno de sus             */
/*  usuarios sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de MACOSA o su representante.                 */
/************************************************************************/  
/*              PROPOSITO                                               */
/*  Consulta para imprimir la oficina que emite al Impresion del Doc    */
/************************************************************************/

use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_imprimir_oficina')
   drop proc sp_imprimir_oficina
go

create proc sp_imprimir_oficina(
@s_ssn               int         = null,
@s_date              datetime    = null,
@s_user              login       = null,
@s_term              descripcion = null,
@s_corr              char(1)     = null,
@s_ssn_corr          int         = null,
@s_ofi               smallint    = null,
@t_rty               char(1)     = null,
@t_debug             char(1)     = 'N',
@t_file              varchar(14) = null,
@t_trn               smallint    = null,
@i_banco             cuenta      = null,
@i_operacion         char(1)     = null       
)
as
declare @w_sp_name   varchar(32),
        @w_return    int,
        @w_error     int

/* Captura nombre de Stored Procedure  */
select  @w_sp_name = 'sp_imprimir_oficina'


select 
'Filia'        = fi_filial,
'No. Ruc'      = fi_ruc,
'Nombre Banco' = substring(fi_nombre,1,30), 
'Direccion '   = substring(of_direccion,1,60),             --substring(fi_direccion,1,60),
'Oficina'      = of_oficina, 
'Nombre Ofic.' = substring(of_nombre,1,30),
'Ciudad'       = substring(ci_descripcion,1,30),
'Telefono'     = (select to_valor from cobis..cl_telefono_of with(nolock) 
                   where to_secuencial = A.of_telefono 
                     and to_oficina    = A.of_oficina),    --of_telefono,
'Terminal'     = @s_term,
'Usuario'      = @s_user,
'Recibo'       = '11111111'
from cobis..cl_filial B,cobis..cl_oficina A,
cobis..cl_ciudad
where  fi_filial = 1
and fi_filial  = of_filial 
and of_oficina = @s_ofi
and ci_ciudad = of_ciudad
set transaction isolation level read uncommitted

return 0

ERROR:

exec cobis..sp_cerror
@t_debug = 'N',
@t_from  = @w_sp_name,
@i_num   = @w_error

return @w_error

go

