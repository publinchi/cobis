/************************************************************************/
/*  Archivo:            rub_cal_cobro_contrato.sp                       */
/*  Stored procedure:   sp_rub_cal_cobro_contrato                       */
/*  Base de datos:      cob_cartera                                     */
/*  Producto:           Cartera                                         */
/*  Disenado por:       Guisela Fernández                               */
/*  Fecha de escritura: 26/07/2021                                      */
/************************************************************************/
/*              IMPORTANTE                                              */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBISCORP'                                                        */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBISCORP o su representante.             */
/************************************************************************/
/*              PROPOSITO                                               */
/*  Este stored procedure se utiliza para el calculo del rubro CARGO    */
/*  POR COBRO DE CONTRATO                                               */
/************************************************************************/
/*              MODIFICACIONES                                          */
/*  FECHA       AUTOR           RAZON                                   */
/*  26/07/2021  G. Fernandez    Emision inicial con valores constantes  */
/************************************************************************/

use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_rub_cal_cobro_contrato')
   drop proc sp_rub_cal_cobro_contrato
go

create proc sp_rub_cal_cobro_contrato (
	@i_operacion             int     = null,
	@o_valor_rubro           money       out
	)
	
as

select @o_valor_rubro       = 200

return 0

GO
