/************************************************************************/
/*   Archivo:              conci_mz.sp                                  */
/*   Stored procedure:     sp_conciliacion_men_z                        */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Credito y Cartera                            */
/*   Disenado por:         Elcira Pelaez                                */
/*   Fecha de escritura:   Feb.2003                                     */
/************************************************************************/
/*   IMPORTANTE                                                         */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   "MACOSA".                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*   PROPOSITO                                                          */
/*   Genera Obligaciones  que son REPORTADAS AL BANCO y que             */
/*      COBIS no genera                                                 */
/*   Actualiza la tabla   ca_plano_mensual         en campo             */
/*      pm_mz = 'S'                                                     */
/************************************************************************/
/*   MODIFICACIONES                                                     */
/*      Fecha           Nombre         Proposito                        */
/*   03/Mar/2003   Luis Mayorga  Dar funcionalidad procedimiento        */
/*   02/Dic/2004  Johan Ardila - JAR  Optimizacion. Creacion de indice  */
/*                                    solo para lectura de datos en el  */
/*                                    sp y no afectar el cargue         */
/*   may-24-2006  Elcira Pelaez       def. 6503 cruzar unicamente con   */
/*                                    llave de redescuento              */
/************************************************************************/ 

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'ca_finagro')
   drop table ca_finagro
go

create table ca_finagro
(ca_llave      cuenta   null,
)
go

if exists (select 1 from sysobjects where name = 'ca_nexisten_cobis')
   drop table ca_nexisten_cobis
go

create table ca_nexisten_cobis     ----SE INSERTAN OBLIGACIONES QUE EXISTE EN FINAGRO Y NO EN COBIS
(ca_llave      cuenta null,
 ca_identificacion      cuenta null
)
go

if exists (select 1 from sysobjects where name = 'sp_conciliacion_men_z')
   drop proc sp_conciliacion_men_z
go

create proc sp_conciliacion_men_z
@i_fecha_proceso        datetime
as

declare 
   @w_llave_segundo_p      char(18),
   @w_pm_identificacion    cuenta
begin
   truncate table ca_finagro
   truncate table ca_nexisten_cobis
   -- CREACION DE INDICE PARA OPTIMIZAR LECTURA
   if exists (select 1 from sysindexes where id=OBJECT_ID('ca_nexisten_cobis') 
              and name ='ca_nexisten_cobis_key')
      drop index ca_nexisten_cobis.ca_nexisten_cobis_key
   
   -- CURSOR PARA LEER LOS VENCIMIENTOS DEL BAC
   declare
      cursor_leer_vtos_dia_finagro cursor
      for select ca_llave, ca_identificacion
          from ca_llave_finagro
      for read only
   
   open cursor_leer_vtos_dia_finagro
   
   fetch cursor_leer_vtos_dia_finagro
   into  @w_llave_segundo_p,  @w_pm_identificacion    --(...son tipo cuenta)
   
   while @@fetch_status = 0 
   begin
      if @@fetch_status = -1 
      begin    
        PRINT 'concilZ2.sp error en lectura del cursor conciliacion diaria Z2'
      end   
      
      -- DATOS TABLA COBIS
      if not exists (select 1
                     from   ca_conciliacion_mensual
                     where  cm_llave_redescuento   = @w_llave_segundo_p
                     )
      begin
         insert into ca_nexisten_cobis
         values(@w_llave_segundo_p, @w_pm_identificacion)
      end 
      
      -- TOTAL DE OBLIGACIONES PROCESADAS
      
      insert into ca_finagro
      values(@w_llave_segundo_p)
      
      fetch cursor_leer_vtos_dia_finagro
      into  @w_llave_segundo_p, @w_pm_identificacion
   end -- cursor_leer_vtos_dia_finagro
   
   close cursor_leer_vtos_dia_finagro
   deallocate cursor_leer_vtos_dia_finagro
   
   create index ca_nexisten_cobis_key
      on ca_nexisten_cobis ( ca_llave,   ca_identificacion )
end
return 0

go

