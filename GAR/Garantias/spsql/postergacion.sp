/*************************************************************************/
/*   Archivo:              postergacion.sp                               */
/*   Stored procedure:     sp_postergacion                               */
/*   Base de datos:        cob_custodia                                  */
/*   Producto:             Garantias                                     */
/*   Disenado por:                                                       */
/*   Fecha de escritura:   Marzo 2019                                    */
/*************************************************************************/
/*                                  IMPORTANTE                           */
/*   Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*   de MACOSA S.A.                                                      */
/*   Su uso no autorizado queda expresamente prohibido asi como          */
/*   cualquier alteracion o agregado hecho por alguno de sus             */
/*   usuarios sin el debido consentimiento por escrito de MACOSA         */
/*   Este programa esta protegido por la ley de derechos de autor        */
/*   y por las  convenciones  internacionales de  propiedad inte-        */
/*   lectual.  Su uso no  autorizado dara  derecho a  MACOSA para        */
/*   obtener  ordenes de  secuestro o retencion y  para perseguir        */
/*   penalmente a los autores de cualquier infraccion.                   */
/*************************************************************************/
/*                                   PROPOSITO                           */
/*    Creacion de objetos de la base. Comprende: tablas, indices,sp      */
/*    tipos de datos, claves primarias y foraneas                        */
/*                                                                       */
/*			                                                             */
/*************************************************************************/
/*                             MODIFICACION                              */
/*    FECHA                   AUTOR                 RAZON                */
/*    Marzo/2019                                      emision inicial    */
/*                                                                       */
/*************************************************************************/
USE cob_custodia
go
IF OBJECT_ID('dbo.sp_postergacion') IS NOT NULL
    DROP PROCEDURE dbo.sp_postergacion
go
create proc sp_postergacion (
   @s_ssn                int      = null,
   @s_date               datetime = null,
   @s_user               login    = null,
   @s_term               descripcion = null,
   @s_corr               char(1)  = null,
   @s_ssn_corr           int      = null,
   @s_ofi                smallint  = null,
   @t_rty                char(1)  = null,
   @t_trn                smallint = null,
   @t_debug              char(1)  = 'N',
   @t_file               varchar(14) = null,
   @t_from               varchar(30) = null,
   @i_operacion          char(1)  = null,
   @i_modo               smallint = null,
   @i_garantia           varchar(64) = null,
   @i_vencimiento        smallint = null,   
   @i_fecha_prorroga     datetime = null,
   @i_secuencial         tinyint = null,
   @i_documento          varchar(20) = null,
   @i_comentario         varchar(255) = null,
   @i_formato_fecha      int     = null 
)

as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_fecha_fin          datetime,
   @w_fecha_ant          datetime,
   @w_secuencial         tinyint,
   @w_fecha_emision      datetime,
   @w_fecha_vencimiento  datetime,
   @w_opebanco           varchar(24)


select @w_today = convert(varchar(10),getdate(),101),
       @w_sp_name = 'sp_postergacion',
       @w_fecha_fin = null,
       @w_opebanco = null

/***********************************************************/
/* Codigos de Transacciones                                */


if (@t_trn <> 19763 and @i_operacion = 'I') or
   (@t_trn <> 19764 and @i_operacion = 'Q')   
begin
/* tipo de transaccion no corresponde */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file, 
    @t_from  = @w_sp_name,
    @i_num   = 1901006
    return 1 
end

---OBTENER DATOS DE LA OPERACION
---------------------------------
select @w_fecha_fin = op_fecha_fin,
       @w_opebanco  = op_banco          
    from cob_cartera..ca_operacion,
         cob_credito..cr_gar_propuesta
   where op_tramite = gp_tramite
     and gp_garantia = @i_garantia
     and op_estado not in (11,3)


--INSERCION
-----------
if @i_operacion = 'I'
begin

  if (@s_date > @i_fecha_prorroga)
  begin   
    exec cobis..sp_cerror
     @t_debug = @t_debug,
     @t_file  = @t_file, 
     @t_from  = @w_sp_name,
     @i_num   = 1903013
    return 1 
  end

  select @w_fecha_emision = ve_fecha_emision,
         @w_fecha_vencimiento = ve_fecha
    from cu_vencimiento
   where ve_codigo_externo = @i_garantia
     and ve_vencimiento = @i_vencimiento

  if (@i_fecha_prorroga < @w_fecha_vencimiento) or
     (@i_fecha_prorroga < @w_fecha_emision)
  begin   
    exec cobis..sp_cerror
     @t_debug = @t_debug,
     @t_file  = @t_file, 
     @t_from  = @w_sp_name,
     @i_num   = 1901024
    return 1 
  end

  if exists (select 1
               from cu_vencimiento
              where ve_codigo_externo = @i_garantia
                and ve_vencimiento = @i_vencimiento
                and ve_fecha_tolerancia = @i_fecha_prorroga)
  begin   
    exec cobis..sp_cerror
     @t_debug = @t_debug,
     @t_file  = @t_file, 
     @t_from  = @w_sp_name,
     @i_num   = 1901024
    return 1 
  end


  ---Validar contra F.Vcto de la Operacion 
  ----------------------------------------
  if (@w_fecha_fin <> null) and (@i_fecha_prorroga > @w_fecha_fin)
  begin   
    exec cobis..sp_cerror
     @t_debug = @t_debug,
     @t_file  = @t_file, 
     @t_from  = @w_sp_name,
     @i_num   = 1901024
    return 1 
  end


  select @w_fecha_ant = ve_fecha_tolerancia
    from cu_vencimiento
   where ve_codigo_externo = @i_garantia
     and ve_vencimiento = @i_vencimiento

  select @w_secuencial = max(po_secuencial)
    from cu_postergacion  
   where po_garantia = @i_garantia
     and po_vencimiento = @i_vencimiento

  select @w_secuencial = isnull(@w_secuencial,0) + 1
    
  begin tran

  insert into cu_postergacion (
    po_garantia, po_vencimiento, po_secuencial,
    po_num_factura, po_fecha_reg, po_fecha_anterior,
    po_fecha_prorroga, po_comentario )
  values (
    @i_garantia, @i_vencimiento, @w_secuencial,
    @i_documento, @s_date, @w_fecha_ant,
    @i_fecha_prorroga, @i_comentario)

  if @@error <> 0 
  begin
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1903001
   return 1 
  end   


  ---Transaccion de Servicio
  insert into ts_postergacion values
  (@s_ssn, @t_trn, 'N', @s_date,
   @s_user,@s_term, @s_ofi,'cu_postergacion',
   @i_garantia, @i_vencimiento, @w_secuencial,
   @i_documento, @s_date, @w_fecha_ant,
   @i_fecha_prorroga, @i_comentario)

  if @@error <> 0 
  begin
    /*Error en insercion de transaccion de servicio*/ 
    exec cobis..sp_cerror
     @t_debug = @t_debug,
     @t_file  = @t_file, 
     @t_from  = @w_sp_name,
     @i_num   = 1903003
    return 1 
  end 

  ---ACTUALIZAR MAESTRO DE DOCUMENTOS

  update cu_vencimiento
     set ve_fecha_tolerancia = @i_fecha_prorroga
   where ve_codigo_externo = @i_garantia
     and ve_vencimiento = @i_vencimiento

  if @@error <> 0 
  begin
    exec cobis..sp_cerror
     @t_debug = @t_debug,
     @t_file  = @t_file, 
     @t_from  = @w_sp_name,
     @i_num   = 1905001
    return 1 
  end 

  commit tran

end


--BUSQUEDA
-----------
if @i_operacion = 'Q'
begin

  set rowcount 20

  select 'DOCUMENTO' = po_num_factura,
         'NRO.POST.' = po_secuencial,
         'OPERACION' = @w_opebanco,
         'F.REGISTRO' = convert(varchar(10),po_fecha_reg,@i_formato_fecha),
         'F.ANTERIOR' = convert(varchar(10),po_fecha_anterior,@i_formato_fecha),
         'F.NUEVA' = convert(varchar(10),po_fecha_prorroga,@i_formato_fecha),
         'COMENTARIO' = po_comentario
    from cu_postergacion
   where po_garantia = @i_garantia
     and po_vencimiento = @i_vencimiento
     and (po_secuencial > @i_secuencial or @i_secuencial = null)
    order by po_secuencial

  set rowcount 0


end

return 0
go