/************************************************************************/
/*  Archivo:                var_porc_atra_ind_int.sp                    */
/*  Stored procedure:       sp_var_porc_atra_ind_int                    */
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

if exists (select 1 from sysobjects where name = 'sp_var_porc_atra_ind_int' and type = 'P')
   drop proc sp_var_porc_atra_ind_int
go


CREATE PROC sp_var_porc_atra_ind_int(
    @i_ente         INT = null,    
    @o_resultado    VARCHAR(255) = NULL OUT
)
as
declare @w_sp_name          varchar(64),
        @w_error               int,
        @w_return              int,
        @w_resultado           float,
        @w_cod_est_canc        int,
        @w_est_cancelado       tinyint,
        @w_operacion           int,
        @w_plazo               smallint,
        @w_diferencia_dia      FLOAT ,
        @w_diferencia_dia_op   FLOAT 
        
select @w_sp_name = 'sp_var_porc_atra_ind_int'

--///////////////////////////////////////////
exec @w_error     =   cob_cartera..sp_estados_cca
@o_est_cancelado  =   @w_est_cancelado out

select top 1 
         @w_operacion = op_operacion, 
         @w_plazo     = op_plazo
from     cob_cartera..ca_operacion, cob_credito..cr_tramite
where    op_estado    = @w_est_cancelado
and      tr_cliente   = op_cliente
and      tr_tramite   = op_tramite
and      op_cliente   = @i_ente
and      tr_grupal is null
order by op_fecha_liq DESC

         
select @w_diferencia_dia = isnull(sum(abs(datediff(dd, di_fecha_can,di_fecha_ven))),0)
from   cob_cartera..ca_dividendo
where  di_operacion = @w_operacion
and    di_estado = @w_est_cancelado
and    di_fecha_can > di_fecha_ven

SELECT @w_diferencia_dia

/*SELECT @w_diferencia_dia_op = abs(datediff ( dd,op_fecha_ini,op_fecha_fin))
FROM cob_cartera..ca_operacion
WHERE op_operacion = @w_operacion */
SELECT @w_diferencia_dia_op = max(di_dividendo)
FROM cob_cartera..ca_dividendo 
WHERE di_operacion = @w_operacion

SELECT @w_diferencia_dia_op 

select @w_resultado = (@w_diferencia_dia / @w_diferencia_dia_op )*100 

SELECT @w_resultado 


if @w_resultado is null
	select @w_resultado = 0  


select @o_resultado = convert(varchar, @w_resultado)

--///////////////////////////////

return 0



GO
