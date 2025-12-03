/************************************************************************/
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Archivo:                ca_revdd.sp                             */
/*      Procedimiento:          sp_reversos_dd                          */
/*      Disenado por:           Elcira Pelaez                           */
/*      Fecha de escritura:     octubre 2005                            */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'COBISCORP'.                                                    */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de COBISCORP o su representante.          */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Procesos para reversar movimientos y estados de Documentos      */
/*      descontados este sp se ejecuta del fechaval.sp                  */
/************************************************************************/
/*                              CAMBIOS                                 */
/*      FECHA          AUTOR          CAMBIO                            */
/*    01/06+/2022     Guisela Fernandez     Se comenta prints           */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_reversos_dd')
   drop proc sp_reversos_dd 
go

create proc sp_reversos_dd
(  
   @i_tramite          int,
   @i_tran             char(3),
   @i_operacionca      int,
   @i_sec_rev          int  = 0          
)
as

declare
   @w_return               int,
   @w_sp_name              varchar(32),
   @w_error                int,
   @w_grupo                int,
   @w_num_negocio          varchar(64),
   @w_num_doc              varchar(16),
   @w_proveedor            int,
   @w_modo                 smallint,
   @w_opcion               char(1),
   @w_dividendo            int



select @w_error = 0

if @i_tran =  'DES'
begin
    select @w_modo = 1,
           @w_opcion = 'R'
end


if @i_tran =  'PAG'
begin
    select @w_modo = 2,
           @w_opcion = 'D'   
           
    --dividendo pagado
   select  @w_dividendo     = ab_dividendo
   from   ca_abono
   where  ab_operacion      = @i_operacionca
   and    ab_secuencial_pag = @i_sec_rev         
   
end

begin
 if @i_tran = 'PAG'
  begin  
    
    declare facturas  cursor 
      for
      select fa_grupo,
             fa_num_negocio,
             fa_referencia,
             fa_proveedor
      from cob_credito..cr_facturas,
           cob_cartera..ca_facturas
      where fa_tramite = @i_tramite
      and   fac_operacion = @i_operacionca
      and   fac_nro_factura = fa_referencia
      and   fac_nro_dividendo  = fa_dividendo
      and   fac_estado_factura = 3  
      and   fa_dividendo  = @w_dividendo 
   end
   else
   begin
      
      declare facturas  cursor 
      for
      select fa_grupo,
             fa_num_negocio,
             fa_referencia,
             fa_proveedor
      from cob_credito..cr_facturas
      where fa_tramite = @i_tramite
      order by fa_fecfin_neg
   end      
   open facturas
   
   fetch facturas 
   into
   @w_grupo,
   @w_num_negocio,
   @w_num_doc,
   @w_proveedor

   --while @@fetch_status not in (-1,0)
   while @@fetch_status = 0
   begin

      exec @w_return  = cob_custodia..sp_cambio_estado_doc
      @i_operacion    = 'I',
      @i_modo         = @w_modo,
      @i_opcion       = @w_opcion,
      @i_tramite      = @i_tramite,
      @i_grupo        = @w_grupo,
      @i_num_negocio  = @w_num_negocio,
      @i_num_doc      = @w_num_doc,
      @i_proveedor    = @w_proveedor

      if @w_return != 0
       begin
	     --GFP se suprime print
         --PRINT 'ca_revdd.sp salio de cob_custodia..sp_cambio_estado_doc'
         select @w_error = @w_return
         goto ERROR
      end  
      
      if @i_tran = 'PAG'
      begin
         update cob_cartera..ca_facturas
         set fac_estado_factura = 1
         where fac_operacion = @i_operacionca
         and   fac_nro_factura = @w_num_doc
         and   fac_nro_dividendo = @w_dividendo
      end
      

      fetch facturas into
      @w_grupo,
      @w_num_negocio,
      @w_num_doc,
      @w_proveedor 
   end

   close facturas
   deallocate facturas
end                          

ERROR:

return @w_error
go

