/************************************************************************/
/*   Archivo            :        trnocontacon.sp                        */
/*   Stored procedure   :        sp_trano_conta_cons                    */
/*   Base de datos      :        cob_cartera                            */
/*   Producto           :        Cartera                                */
/*   Disenado por                Ivan Jimenez                           */
/*   Fecha de escritura :        Noviembre 09 de 2006                   */
/************************************************************************/
/*                              IMPORTANTE                              */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   "MACOSA".                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                             PROPOSITO                                */
/*   Programa para consulta resumida de transacciones no contabilizadas */
/************************************************************************/
/*                            MODIFICACIONES                            */
/*       Ago/14/2006    Ivan Jimenez      Emision inicial               */
/*   26/Mar/2007        Elcira Pelaez   def.Pruebas BAC                 */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_trano_conta_cons')
   drop proc sp_trano_conta_cons
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

create proc sp_trano_conta_cons(
   @s_ssn           int        = null,
   @s_date          datetime   = null,
   @s_user          login      = null,
   @s_term          varchar(64)= null,
   @s_ofi           smallint   = null,
   @t_trn           smallint   = null,
   @i_formato_fecha int        = null,
   @i_contador      int        = 0
)
as
   if @i_formato_fecha is null
      select @i_formato_fecha = 113

   if not exists (select 1
      from ca_tran_no_conta)
       PRINT 'NO HAY DATOS --> CONFIRMAR LA EJECUCION DEL PROCESO --> CARGA TABLA CONSULTA RESUMIDA TRANSACCIONES'
   ELSE   
   begin
      set rowcount 20
      select 'Sec'                = tnc_secuencial,
             'Estado'             = tnc_estado,
             'Fecha Movimiento '  = convert(varchar(10),tnc_fecha_mov,@i_formato_fecha),
             'Tipo Transaccion '  = tnc_tipo_tran,
             'Perfil       '  = tnc_perfil,
             'Total'  = tnc_num_tran
      from  ca_tran_no_conta
      where tnc_secuencial > @i_contador
      set rowcount 0
   end
return 0
go