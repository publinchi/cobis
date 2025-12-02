/************************************************************************/
/*      Archivo:                fcalcesp.sp                             */
/*      Stored procedure:       sp_calc_intereses_esp                   */
/*      Base de datos:          cobis                                   */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Juan Jose Lam                           */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA".							*/
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Funcion que realiza el calculo de los intereses                 */
/*                                                                      */
/************************************************************************/  
/*                              MODIFICACIONES                          */
/*      FECHA      AUTOR              RAZON                             */
/*      20-Feb-95  Juan Lam           Creacion                          */
/*                                                                      */
/************************************************************************/

use cob_cartera
go

if exists ( select name from sysobjects where type = 'P' and
		name = 'sp_calc_intereses_esp')
	drop proc sp_calc_intereses_esp
go
create proc sp_calc_intereses_esp
                                @operacion  int,
            		 	@tasa       float,
				@monto      float,
				@dias_anio  smallint = 360,
				@num_dias   smallint = 1,
				@intereses  float output
as
 select 
 @intereses = 
 sum(round((rot_porcentaje * @monto) / (100 * @dias_anio),2) * @num_dias)
 from ca_rubro_op_tmp
 where rot_operacion  = @operacion
 and   rot_tipo_rubro in ('I','O')
 and   rot_fpago      in ('P','A')
 
 return 0
go
