/************************************************************************/
/*   Archivo:              conci_my.sp                                  */
/*   Stored procedure:     sp_conciliacion_men_y                        */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Credito y Cartera                            */
/*   Disenado por:         Elcira Pelaez                                */
/*   Fecha de escritura:   Feb.2003                                     */
/************************************************************************/
/*   IMPORTANTE                                                         */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*   PROPOSITO                                                          */
/*   Genera obligaciones que reporta COBIS y no son reportados          */
/*      por BANCO DE SEGUNDO PISO                                       */
/*   Actualiza la tabla   ca_conciliacion_mensual campo    cm_my        */
/************************************************************************/
/*   MODIFICACIONES                                                     */
/*      Fecha           Nombre         Proposito                        */
/*      03/Mar/2003   Luis Mayorga  Dar funcionalidad procedimiento     */
/*   02/Dic/2004  Johan Ardila - JAR  Optimizacion. Creacion de indice  */
/*                                    solo para lectura de datos en el  */
/*                                    sp y no afectar el cargue         */
/*   may-24-2006  Elcira Pelaez       def. 6503 cruzar unicamente con   */
/*                                    llave de redescuento              */
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'ca_cobis')
   drop table ca_cobis
go

create table ca_cobis
(ca_llave      cuenta   null)
go

if exists (select 1 from sysobjects where name = 'ca_nexisten_finagro')
   drop table ca_nexisten_finagro
go

create table ca_nexisten_finagro     ----SE INSERTAN OBLIGACIONES QUE EXISTE EN COBIS Y NO EN FINAGRO
(ca_llave      cuenta   null,
 ca_identificacion      cuenta   null
)
go

if exists (select * from sysobjects where name = 'sp_conciliacion_men_y')
   drop proc sp_conciliacion_men_y
go

create proc sp_conciliacion_men_y
   @i_fecha_proceso        datetime = null,
   @i_operacion      char(1)
as
declare 
   @w_cd_llave_redescuento cuenta,
   @w_ident                varchar(15)

if @i_operacion = 'U' 
begin  
   truncate table ca_cobis
   truncate table ca_nexisten_finagro
   
   -- CREACION DE INDICE PARA OPTIMIZAR LECTURA
   if exists (select * from sysindexes where id=OBJECT_ID('ca_nexisten_finagro') 
              and name ='ca_nexisten_finagro_key')
      drop index ca_nexisten_finagro.ca_nexisten_finagro_key
   
   -- CURSOR PARA LEER LOS VENCIMIENTOS DEL BAC
   declare
      cursor_leer_vtos_dia cursor
      for select cm_llave_redescuento,       ---tipo cuenta
                 cm_identificacion           ---tipo cuenta
          from   cob_cartera..ca_conciliacion_mensual 
          where  cm_fecha_proceso  =  @i_fecha_proceso
          and    cm_banco_sdo_piso = '224'   --Banco Finagro
      for read only
   
   open  cursor_leer_vtos_dia
   
   fetch cursor_leer_vtos_dia
   into  @w_cd_llave_redescuento, @w_ident
   
   while @@fetch_status = 0 
   begin
      if @@fetch_status = -1 
      begin    
         PRINT 'concilZ1.sp error en lectura del cursor conciliacion diariaZ1'
      end   
      
      -- DATOS ARCHIVO FINAGRO
      
      if not exists (select 1 from ca_llave_finagro
                     where ca_llave           = @w_cd_llave_redescuento
                     ) 
      begin
         insert into ca_nexisten_finagro
         values(@w_cd_llave_redescuento, @w_ident)
      end
      
      -- TOTAL DE OBLIGACIONES PROCESADAS
      insert into ca_cobis
      values(@w_cd_llave_redescuento)
      
      fetch cursor_leer_vtos_dia
      into  @w_cd_llave_redescuento, @w_ident  -- JAR 2/Dic/2004
   end -- CURSOR_LEER_VTOS_DIA
   
   close cursor_leer_vtos_dia
   deallocate cursor_leer_vtos_dia
   
   create index ca_nexisten_finagro_key
    on ca_nexisten_finagro(ca_llave, ca_identificacion)
end 

if @i_operacion = 'A'
begin
   begin tran
   update ca_plano_mensual
   set pm_fecha_redes = substring(pm_fecha_redes,1,2) + '/' + substring(pm_fecha_redes,3,2) + '/' + substring(pm_fecha_redes,5,2),
       pm_fecha_proceso = getdate()
   WHERE pm_sucursal >= 0       
   commit tran
end

return 0

go
