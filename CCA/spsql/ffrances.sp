/************************************************************************/
/*  Archivo:                        ffrances.sp                         */
/*  Stored procedure:               sp_formula_francesa                 */
/*  Base de datos:                  cob_cartera                         */
/*  Producto:                       Cartera                             */
/*  Disenado por:                   R Garces                            */
/*  Fecha de escritura: Jul.1997                                        */
/************************************************************************/
/*                               IMPORTANTE                             */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'Cobiscorp', representantes exclusivos para el Ecuador de la    */
/*      'NCR CORPORATION'.                                              */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de Cobiscorp o su representante.          */
/************************************************************************/  
/*                                  PROPOSITO                           */
/*  Determina la primera aproximacion de la cuota fija por formula      */
/************************************************************************/ 
/*                          MODIFICACIONES                              */                      
/*  FECHA          AUTOR                CAMBIO                          */
/*  26/Jul/2017    Sandra Echeverri R.  CGS_S126738 Redondeo superior   */
/*                                      cuota por formula francesa      */
/*  04/Jul/2017                         Refactorizacion                 */ 
/*  11/Abr/209     Lorena Regalado      Validar incorporar o no el IVA  */
/*                                      en la formula                   */
/************************************************************************/ 
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_formula_francesa')
    drop proc sp_formula_francesa
go

create proc sp_formula_francesa
    @i_operacionca            int,
    @i_monto_cap              money = 0,
    @i_tasa_int               float,
    @i_dias_anio              smallint = 360,
    @i_gracia_cap             smallint = 0,
    @i_num_dec                tinyint = 0,
    @i_dias_cap               int = 0,
    @i_adicionales            money = 0,
    @i_num_dividendos         smallint = 0,
    @i_periodo_crecimiento    smallint = 0,
    @i_tasa_crecimiento       float = 0,
    @o_cuota                  float out
as
declare @w_sp_name            descripcion,
    @w_return                 int,
    @w_error                  int,
    @w_dias_cap               int,
    @w_adicionales            float,
    @w_factor                 float,
    @w_tasa_cuota             float,
    @w_num_dividendos         int

select @w_sp_name = 'sp_formula_francesa'


select @w_tasa_cuota = (@i_dias_cap * @i_tasa_int) / (100.00 * @i_dias_anio) 
select @w_factor     = power(1+@w_tasa_cuota,@i_num_dividendos)

/* TASA DE INTERES 0 o CUOTA CON CRECIMIENTO PERIODICO */
if @w_tasa_cuota = 0 or @i_tasa_crecimiento != 0 
   select @o_cuota = (@i_monto_cap-@i_adicionales) / (@i_num_dividendos)
else
   select @o_cuota = (@w_tasa_cuota*@w_factor*(@i_monto_cap-@i_adicionales))/(@w_factor-1)

return 0

ERROR:

return @w_error
go
