/*********************************************************************/
/*   Archivo:              conci_fn.sp                               */
/*   Stored procedure:     sp_datos_finagro                          */
/*   Base de datos:        cob_cartera                               */
/*   Producto:             Credito y Cartera                         */
/*   Disenado por:         Xavier Maldonado                          */
/*   Fecha de escritura:   Feb.2005                                  */
/*********************************************************************/
/*                          IMPORTANTE                               */
/*   Este programa es parte de los paquetes bancarios propiedad de   */
/*   "MACOSA".                                                       */
/*   Su uso no autorizado queda expresamente prohibido asi como      */
/*   cualquier alteracion o agregado hecho por alguno de sus         */
/*   usuarios sin el debido consentimiento por escrito de la         */
/*   Presidencia Ejecutiva de MACOSA o su representante.             */
/*********************************************************************/
/*                           PROPOSITO                               */
/*   Genera Obligaciones  que son REPORTADAS AL BANCO y que          */
/*      COBIS no genera                                              */
/*   Actualiza la tabla   ca_plano_mensual         en campo          */
/*      pm_mz = 'S'                                                  */
/*********************************************************************/
/*                              MODIFICACIONES                       */
/*      Fecha           Nombre         Proposito                     */
/*   03/Mar/2003   Luis Mayorga  Dar funcionalidad procedimiento     */
/*   02/Dic/2004  Johan Ardila - JAR  Optimizacion. Creacion de indice*/
/*                                    solo para lectura de datos en el*/
/*                                    sp y no afectar el cargue       */
/*   29/06/2006   ELcira Pelaez       quitar el 0 a la izquierda a las*/
/*                                    llaves de 19 digitos            */
/**********************************************************************/ 

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'ca_llave_finagro')
   drop table ca_llave_finagro
go

create table ca_llave_finagro
(ca_llave      cuenta,
 ca_identificacion     cuenta,
 ca_linea_norlegal   varchar(4),
 ca_valor_saldo_redes   money,
 ca_modalidad           char(1), 
 ca_tasa_nom      float
)
go

if exists (select 1 from sysobjects where name = 'sp_datos_finagro')
   drop proc sp_datos_finagro
go

create proc sp_datos_finagro
@i_fecha_proceso        datetime
as

declare 
@w_error              int,
@w_return             int


   truncate table ca_llave_finagro

   /* CREACION DE INDICE PARA OPTIMIZAR LECTURA JAR 2/Dic 2004 */
   if exists (select * from sysindexes where id=OBJECT_ID('ca_llave_finagro') 
              and name ='ca_llave_finagro_key')
      drop index ca_llave_finagro.ca_llave_finagro_key

   ---PROCESO DE CREACION DE LA LLAVE DE REDESCUENTO COMPLETA

   insert into ca_llave_finagro
   select '0' + (ltrim(rtrim(convert(char(4),pm_sucursal)))) + (ltrim(rtrim(pm_linea_norlegal))) + (ltrim(rtrim(pm_oper_llave_redes))),
          substring(convert(varchar,(convert(float,pm_identificacion))),1,datalength(convert(varchar,(convert(float,pm_identificacion))))-2),  -- I.Jimenez 05/Oct/2005 
          pm_linea_norlegal,
          pm_valor_saldo_redes,
          pm_modalidad,
          pm_tasa_nom
   from cob_cartera..ca_plano_mensual


      create index ca_llave_finagro_key ON ca_llave_finagro(
      ca_llave,
      ca_identificacion 
      )

      -- defecto 6503 actualizar las llaves que tengan 19 digitos por que estas llaves deben ser de 18
      --              se quita el cero de la izquierda
      update  ca_llave_finagro
      set ca_llave = substring(ca_llave,2,18)
      where datalength(ca_llave) > 18

return 0

go



