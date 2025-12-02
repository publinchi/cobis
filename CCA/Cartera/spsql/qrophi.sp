/************************************************************************/
/*   Archivo:             qrophi.sp                                     */
/*   Stored procedure:    sp_qr_operaciones_hijas                       */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        Francisco Schnabel                            */
/*   Fecha de escritura:  10/26/2017                                    */
/************************************************************************/
/*                           IMPORTANTE                                 */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/  
/*                           PROPOSITO                                  */  
/*  Procedimiento para consultar operaciones hijas                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA              AUTOR               RAZON                        */
/* Octubre 20 de 2017 Francisco Schnabel  Procedimiento para consultar  */
/*                                        operaciones hijas             */ 
/* Julio 17 de 2019   Felipe Borja        Operacion S para consultar    */
/*                                        oper. hijas sin interciclos   */ 
/************************************************************************/  
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_qr_operaciones_hijas')
   drop proc sp_qr_operaciones_hijas
go
--ORS 000353 Partiendo de la Ver. 33  FEB.22.2012
--Inc. 26883 Partiendo de la Ver. 28 Jul-27-2011

create proc sp_qr_operaciones_hijas (
@s_user                  varchar(14),
@s_term                  varchar(30),
@s_date                  datetime,
@s_ofi                   smallint,
@i_banco                cuenta  = null,
@i_formato_fecha        int     = null,
@i_operacion            char(1) = null
)
as
declare @w_sp_name varchar(32)

select @w_sp_name        = 'sp_qr_operaciones_hijas'

if @i_operacion = 'Q'
begin
        select op_tramite,
               op_banco, 
               op_nombre, 
               op_monto_aprobado,
               es_descripcion
          from cob_credito..cr_tramite_grupal
    inner join cob_cartera..ca_operacion on op_operacion = tg_operacion and op_banco = tg_prestamo
    inner join cob_cartera..ca_estado on es_codigo = op_estado
         where tg_referencia_grupal = @i_banco
end

if @i_operacion = 'S'
begin
        select op_tramite,
               op_banco, 
               op_nombre, 
               op_monto_aprobado,
               es_descripcion
          from cob_credito..cr_tramite_grupal
    inner join cob_cartera..ca_operacion on op_operacion = tg_operacion and op_banco = tg_prestamo
    inner join cob_cartera..ca_estado on es_codigo = op_estado
         where tg_referencia_grupal = @i_banco
           and op_grupal = 'S'
end

return 0
go
