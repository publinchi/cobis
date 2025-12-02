/************************************************************************/
/*  Archivo:                asegupmensu.sp                              */
/*  Stored procedure:       sp_asegupmensu                              */
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

if exists (select 1 from sysobjects where name = 'sp_asegupmensu' and type = 'P')
   drop proc sp_asegupmensu
go



create proc sp_asegupmensu 
--(   @i_fecha datetime
--)
as
declare  @w_fecha        datetime,     
         @w_sp_name      varchar(32),
         @w_obli         varchar(20),
         @w_id           int,
       @w_apell          varchar(50),
       @w_nom            varchar(50),
       @w_fec_naci       datetime,
       @w_fec_ocredi     datetime,
       @w_monto          money,
       @w_saldo          money
         
select @w_sp_name = 'sp_asegupmensu'

declare @cr_asegura table 
(  obli        varchar(20),
   id          int,
   apell       varchar(50),
   nom         varchar(50),
   fec_naci    datetime,
   fec_ocredi  datetime,
   monto       money,
   saldo       money
)
insert @cr_asegura
select op_banco, op_cliente, p_p_apellido, en_nombre, p_fecha_nac, op_fecha_liq, op_monto, sum(am_cuota + am_gracia - am_pagado)
from   cobis..cl_ente,
       cob_cartera..ca_operacion,                                         
       cob_cartera..ca_dividendo,
       cob_cartera..ca_amortizacion
where  op_cliente = en_ente
and    op_estado in (1,2,4,9)
and    op_naturaleza  = 'A'
and    di_operacion = op_operacion
and    am_operacion = di_operacion
and    am_dividendo = di_dividendo
and    am_concepto  = 'CAP'
group by op_banco, op_cliente, p_p_apellido, en_nombre, p_fecha_nac, op_fecha_liq, op_monto
--select * from @cr_asegura
insert into cob_credito..cr_asegura_tmp
select   obli,
         id,
         apell,
         nom,
         fec_naci,
         fec_ocredi,
         monto,
         saldo
from @cr_asegura

GO
