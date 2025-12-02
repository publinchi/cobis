/************************************************************************/
/*   Archivo:                camesdo.sp                                 */
/*   Stored procedure:       sp_cambio_estado_doc                       */ 
/*   Base de datos:          cob_custodia                               */
/*   Producto:               garantias                                  */
/*   Disenado por:           Patricia Garzon                            */
/*   Programado por:         Patricia Garzon                            */
/*   Fecha de escritura:     Septiembre 2000                            */
/************************************************************************/
/*                        IMPORTANTE                                    */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   "MACOSA",                                                          */                               
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                         PROPOSITO                                    */
/*   Este programa se encargara  de manejar los cambios de              */
/*      estados de los documentos - factoring  (cu_documentos).         */
/*      No genera transacciones contables.                              */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*      FECHA          AUTOR          CAMBIO                            */
/*      OCT-2005       Elcira Pelaez  Cambios para el BAC               */
/************************************************************************/

use cob_custodia
go

if exists (select 1 from sysobjects where name = 'sp_cambio_estado_doc')
   drop proc sp_cambio_estado_doc
go
create proc sp_cambio_estado_doc(
   @s_date               datetime    = null,
   @s_user               login       = null,
   @s_ofi                 smallint    = null,
   @s_term               login       = null,
   @t_debug              char(1)  = 'N',
   @t_file               varchar(14) = null,
   @t_from               varchar(30) = null,
   @i_usuario            login       = null,
   @i_terminal           login       = null,
   @i_tramite            int        = null,
   @i_operacion          char(1)     = null,
   @i_filial             tinyint     = null,
   @i_sucursal           smallint    = null,
   @i_tipo_doc           varchar(64) = null,
   @i_num_doc            varchar(16) = null,
   @i_num_negocio        varchar(64) = null,
   @i_proveedor          int         = null,
   @i_grupo              int         = null,
   @i_modo               smallint    = null,
   @i_opcion             char(1)     = null,
   @i_banderafe          char(1)     = 'S',
   @i_documento          varchar(16) = null
)
as

declare
   @w_sp_name            varchar(32), 
   @w_error              int,   
   @w_estado_ant         char(1)


select @w_sp_name = 'sp_cambio_estado_doc',
       @w_error   = 0

if @i_tramite is not null
begin

   if not exists(select 1
                from cob_credito..cr_facturas  
                 where fa_tramite    = @i_tramite
                 and fa_grupo       = @i_grupo
                 and fa_num_negocio = @i_num_negocio
                 and fa_referencia  = @i_num_doc
                 and fa_proveedor   = @i_proveedor)
    return 0 
  

   
   if @i_operacion = 'I'
   begin

      if @i_modo = 1
      begin 
         if @i_opcion = 'L'  ---Liquidacion paso de F a V 
         begin
            
            ---PRINT 'camesdo.sp llego con @i_grupo %1!  @i_num_negocio %2! @i_num_doc %3! prov %4!',@i_grupo,@i_num_negocio,@i_num_doc,@i_proveedor
            
            select @w_estado_ant = do_estado
            from   cob_custodia..cu_documentos
            where  do_grupo         = @i_grupo
               and do_num_negocio   = @i_num_negocio
               and do_num_doc       = @i_num_doc
               and do_proveedor     = @i_proveedor

            if @@rowcount = 0
            begin
               
               select @w_error  = 1901005
               goto ERROR 
            end 

           ---PRINT 'camesdo.sp @w_estado_ant %1!',@w_estado_ant
            
            if @w_estado_ant <> 'F'
            begin
                
               select @w_error   = 1910001
               goto ERROR 
            end

            update cob_custodia..cu_documentos
            set do_estado = 'V'
            where  do_grupo         = @i_grupo
               and do_num_negocio   = @i_num_negocio
                 and do_num_doc       = @i_num_doc
               and do_proveedor     = @i_proveedor

            if @@error <> 0 
            begin

               select @w_error  = 1905001
               goto ERROR 
            end
         end

         if @i_opcion = 'R' --- reversa de liquidacion regresa a F 
         begin 
            select @w_estado_ant = do_estado
            from   cob_custodia..cu_documentos
            where  do_grupo         = @i_grupo
               and do_num_negocio   = @i_num_negocio
               and do_num_doc       = @i_num_doc
               and do_proveedor     = @i_proveedor
       
            if @@rowcount = 0
            begin
               select @w_error   = 1901005
               goto ERROR
            end 

            if @w_estado_ant <> 'V'
            begin
               select @w_error   =1910001
               goto ERROR 
            end

            update cob_custodia..cu_documentos
            set do_estado = 'F'
            where  do_grupo         = @i_grupo
               and do_num_negocio   = @i_num_negocio
               and do_num_doc       = @i_num_doc
               and do_proveedor     = @i_proveedor

            if @@error <> 0 
            begin
               select @w_error   = 1905001
               goto ERROR 
            end
         end  
      end

      if @i_modo = 2   --CANCELACION
      begin

         if @i_opcion = 'C'  --PAGO paso a vigente por cancelar
         begin

            --emg dic-1-01 
            select @w_estado_ant = do_estado
            from   cob_custodia..cu_documentos      
            where  do_grupo         = @i_grupo
               and do_num_negocio   = @i_num_negocio
               and do_num_doc       = @i_num_doc
               and do_proveedor     = @i_proveedor
 
            if @@rowcount = 0
            begin
               select @w_error   = 1901005
               goto ERROR 
            end 

            if @w_estado_ant <> 'V'
            begin
               select @w_error   = 1910001
               goto ERROR 
            end

            update cob_custodia..cu_documentos
            set do_estado = 'X'
            where  do_grupo         = @i_grupo
               and do_num_negocio   = @i_num_negocio
               and do_num_doc    = @i_num_doc
               and do_proveedor     = @i_proveedor

            if @@error <> 0 
            begin
               select @w_error   = 1905001
               goto ERROR
            end
         end

         if @i_opcion = 'D'   --REVERSA DE PAGO
         begin

            select @w_estado_ant = do_estado
            from   cob_custodia..cu_documentos
            where  do_grupo         = @i_grupo
               and do_num_negocio   = @i_num_negocio
               and do_num_doc       = @i_num_doc
               and do_proveedor     = @i_proveedor

            if @@rowcount = 0
            begin
               select @w_error   = 1901005
               goto ERROR 
            end 

            if @w_estado_ant <> 'X'
            begin
               select @w_error   = 1910001
               goto ERROR 
            end

            update cob_custodia..cu_documentos
            set do_estado = 'V'
            where  do_grupo         = @i_grupo
               and do_num_negocio   = @i_num_negocio
               and do_num_doc       = @i_num_doc
               and do_proveedor     = @i_proveedor

            if @@error <> 0 
            begin
               select @w_error =  1905001
               goto ERROR
            end    
            
         end
      end  --modo = 2
   end  --Operacion 'I'
end  --Tramite not null
 
if @i_operacion = 'C'
begin
   if @i_modo = 0
   begin
      update cob_custodia..cu_documentos
      set do_estado = 'C'
      where   do_num_doc = @i_documento
      and     do_proveedor   = @i_proveedor

      if @@error <> 0 
      begin
         select @w_error =  1905001
         goto ERROR
      end    
   end
end


return 0

ERROR:

---PRINT 'camesdo.sp @i_banderafe %1! @w_error %2!',@i_banderafe,@w_error

if @i_banderafe = 'S'
begin

   exec cobis..sp_cerror
   @t_debug = @t_debug,
   @t_file  = @t_file, 
   @t_from  = @w_sp_name,           
   @i_num   = @w_error
   return 1    
   
end
else
 return @w_error
go