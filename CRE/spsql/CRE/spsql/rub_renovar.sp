/************************************************************************/
/*  Archivo:                rub_renovar.sp                              */
/*  Stored procedure:       sp_rub_renovar                              */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Geovanny Guaman                             */
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
/*  23/04/19          gguaman        Emision Inicial                    */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_rub_renovar')
    drop proc sp_rub_renovar
go


create proc sp_rub_renovar(
   @s_ssn                 int = null,
   @s_user                login = null,
   @s_sesn                int = null,
   @s_term                varchar(30) = null,
   @s_date                datetime = null,
   @s_srv                 varchar(30) = null,
   @s_lsrv                varchar(30) = null,
   @s_rol                 smallint = null,
   @s_ofi                 smallint = null,
   @s_org_err             char(1) = null,
   @s_error               int = null,
   @s_sev                 tinyint = null,
   @s_msg                 descripcion = null,
   @s_org                 char(1) = null,
   @t_debug               char(1) = 'N',
   @t_file                varchar(10) = null,
   @t_from                varchar(32) = null,
   @t_trn                 smallint = null,
   @i_operacion           char(1) = null,
   @i_banco               cuenta = null,
   @i_concepto            catalogo = null,
   @i_renovar             char(1)  = null,
   @i_tramite_re          int = null, 
   @i_estado              catalogo = null,
   @i_estado_cuota        catalogo = null,
   /* campos cca 353 alianzas bancamia --AAMG*/
   @i_crea_ext          char(1)       = null,
   @o_msg_msv           varchar(255)  = null out
)
as
declare
   @w_sp_name             varchar(25),
   @w_banco               cuenta,
   @w_concepto             catalogo,
   @w_renovar             char(1),
   @w_tramite_re          int,
   @w_desc_concepto       descripcion,
   @w_tabla               smallint,
   @w_tramite             int,
   @w_tramite_ant         int,
   @w_tramite_val         int,
   @w_estado_cuota        tinyint,
   @w_estado              tinyint,
   @w_return              int

select @w_sp_name = 'sp_rub_renovar'

select @w_tramite = op_tramite  
from   cob_cartera..ca_operacion
where  op_banco   = @i_banco

if @i_estado is not null
begin
   select @w_estado = es_codigo
   from   cob_cartera..ca_estado
   where  es_descripcion = @i_estado
end

if @i_estado_cuota is not null
begin
   select @w_estado_cuota = es_codigo
   from   cob_cartera..ca_estado
   where  es_descripcion = @i_estado_cuota
end

/* TRAE EL TRAMITE CON EL OP_BANCO DE CARTERA */
if @i_banco is null and @i_operacion <> 'U'
begin
   if @i_crea_ext is null
   begin
      exec cobis..sp_cerror 
           @t_debug= @t_debug,
           @t_file = @t_file,
           @t_from = @w_sp_name,
           @i_num  = 2101001  
      return 1
   end
   else
   begin
      select @o_msg_msv = 'Campos Not NULL con valors Nulos, ' + @w_sp_name
      select @w_return  = 2101001
      return @w_return
   end
end

--- INSERT 
if @i_operacion = 'I'
begin
   if @t_trn = 21771  
   begin
      if ((@i_banco is null) and (@i_concepto is null) and (@i_renovar is null)) 
      begin
         if @i_crea_ext is null
         begin
            exec cobis..sp_cerror 
                 @t_debug= @t_debug,
                 @t_file = @t_file,
                 @t_from = @w_sp_name,
                 @i_num  = 2101001  
            return 1
         end
         else
         begin
            select @o_msg_msv = 'Campos Not NULL con valors Nulos, ' + @w_sp_name
            select @w_return  = 2101001
            return @w_return
         end
      end
      
      -- VERIFICAR QUE NO SE REPITA
      if exists ( select 1 
                  from   cr_rub_renovar
                  where  rr_tramite      = @w_tramite
                  and    rr_concepto     = @i_concepto
                  and    rr_tramite_re  in (-@w_tramite, @i_tramite_re)
                  and    rr_estado       = @w_estado
                  and    rr_estado_cuota = @w_estado_cuota)
        return 0
      
      select @i_tramite_re = isnull(@i_tramite_re, -@w_tramite)
      
      -- INSERTAR LOS DATOS DE ENTRADA
      insert into cr_rub_renovar
            (rr_tramite,      rr_concepto,   rr_renovar,
             rr_tramite_re,   rr_estado,     rr_estado_cuota)
      values(@w_tramite,      @i_concepto,   @i_renovar,
             @i_tramite_re,   @w_estado,     @w_estado_cuota)
      
      -- SI NO SE PUEDE INSERTAR ENTONCES ERROR
      if @@error <> 0
      begin
         if @i_crea_ext is null
         begin
            exec cobis..sp_cerror
                 @t_debug    = @t_debug,
                 @t_file     = @t_file,
                 @t_from     = @w_sp_name,
                 @i_num      = 2103001
                 -- ERROR EN CREACION DE RUB_RENOVAR
            return 1
         end
         else
         begin
            select @o_msg_msv = 'ERROR EN CREACION DE RUB_RENOVAR, TRAMITE: ' + @w_tramite + ', ' + @w_sp_name
            select @w_return  = 2103001
            return @w_return
         end
      end
      
      return 0
   end
   ELSE
   begin
      if @i_crea_ext is null
      begin
         exec cobis..sp_cerror
              @t_debug    = @t_debug,
              @t_file    = @t_file,
              @t_from    = @w_sp_name,
              @i_num    = 2101006
              -- NO CORRESPONDE CODIGO DE TRANSACCION
         return 1
      end
      else
      begin
         select @o_msg_msv = 'NO CORRESPONDE CODIGO DE TRANSACCION, ' + @w_sp_name
         select @w_return  = 2101006
         return @w_return
      end
   end
end

---  UPDATE 
if @i_operacion = 'U'
begin
   if @t_trn = 21772
   begin
      if (select count(distinct or_tramite)
          from   cr_op_renovar,
                 cr_tramite,
                 cob_cartera..ca_operacion
          where  or_tramite       = tr_tramite
          and    tr_tramite       = op_tramite
          and    tr_tipo          in ('R','E')
          and    tr_estado        not in ('Z','X','R','S')
          and    op_estado         in (99,0)
          and    or_num_operacion in (select   or_num_operacion 
                                      from     cr_op_renovar, 
                                               cr_tramite,
                                               cob_cartera..ca_operacion
                                      where  or_tramite       = tr_tramite
                                      and    tr_tramite       = op_tramite
                                      and    tr_tipo          in ('R','E')
                                      and    tr_estado        not in ('Z','X','R','S')
                                      and    or_tramite       = @i_tramite_re
                                      and    op_estado   in (99,0))
         ) > 1
      begin
         if @i_crea_ext is null
         begin
            exec cobis..sp_cerror
                 @t_from    = @w_sp_name,
                 @i_num    = 2101097
                 /* Ya existe un tramite con esa operacion */
            return 1
         end
         else
         begin
            select @o_msg_msv = 'Ya existe un tramite con esa operacion, TRAMITE: ' + @i_tramite_re + ', ' + @w_sp_name
            select @w_return  = 2101006
            return @w_return
         end
      end
        
      if @i_tramite_re is null
      begin
         if @i_crea_ext is null
         begin
            print 'cr_rubreno.sp Error llego vacio el NRo. de tramite a renovar @i_tramite_re %1!' + cast (@i_tramite_re as varchar)
            return 1
         end
         else
         begin
            select @o_msg_msv = 'Error llego vacio el NRo. de tramite a renovar, ' + @w_sp_name
            select @w_return  = 710391
            return @w_return
         end
      end        
      
      update cr_rub_renovar
      set    rr_tramite_re = @i_tramite_re
      from   cob_cartera..ca_operacion, cr_op_renovar
      where  rr_tramite    = op_tramite
      and    op_banco    = or_num_operacion
      and    or_tramite  = @i_tramite_re
      and    op_banco    > '0'
      and rr_concepto > ''

      if @@error <> 0
      begin
         if @i_crea_ext is null
         begin
            exec cobis..sp_cerror
                 @t_debug  = @t_debug,
                 @t_file   = @t_file,
                 @t_from   = @w_sp_name,
                 @i_num    = 2005001
                 /* ERROR EN ACTUALIZACION DE RUB_RENOVAR*/
            return 1
         end
         else
         begin
            select @o_msg_msv = 'ERROR EN ACTUALIZACION DE RUB_RENOVAR, TRAMITE: ' + @i_tramite_re + ', ' + @w_sp_name
            select @w_return  = 2005001
            return @w_return
         end
      end
      return 0            
   end              
   else
   begin
      if @i_crea_ext is null
      begin
         exec cobis..sp_cerror
              @t_debug    = @t_debug,
              @t_file    = @t_file,
              @t_from    = @w_sp_name,
              @i_num    = 2101006
              /* Tipo de transaccion no corresponde*/
         return 1
      end
      else
      begin
         select @o_msg_msv = 'Tipo de transaccion no corresponde, ' + @w_sp_name
         select @w_return  = 2101006
         return @w_return
      end
   end   
end


--- DELETE 
if @i_operacion = 'D'
begin
   if @t_trn = 21773
   begin
      delete cr_rub_renovar
      where  rr_tramite  = @w_tramite
      and    rr_tramite_re in (-@w_tramite, @i_tramite_re)
      
      if @@error <> 0
      begin
         if @i_crea_ext is null
         begin
            exec cobis..sp_cerror
                 @t_debug    = @t_debug,
                 @t_file     = @t_file,
                 @t_from     = @w_sp_name,
                 @i_num      = 2107001
                 /* ERROR EN ELIMINACION DE RUB_RENOVAR */
            return 1
         end
         else
         begin
            select @o_msg_msv = 'ERROR EN ELIMINACION DE RUB_RENOVAR, TRAMITE: ' + @w_tramite + ', ' + @w_sp_name
            select @w_return  = 2101006
            return @w_return
         end
      end
      return 0
   end 
   else 
   begin
      if @i_crea_ext is null
      begin
         exec cobis..sp_cerror
              @t_debug  = @t_debug,
              @t_file   = @t_file,
              @t_from   = @w_sp_name,
              @i_num    = 2101006
              /* Tipo de transaccion no corresponde*/
         return 1
      end
      else
      begin
         select @o_msg_msv = 'Tipo de transaccion no corresponde, ' + @w_sp_name
         select @w_return  = 2101006
         return @w_return
      end
   end
end

--- SEARCH 
if @i_operacion = 'S' 
begin
   if @t_trn = 21774                            
   begin   
      select 
      'Concepto'        = rr_concepto,
      'Renovar'         = rr_renovar,
      'Estado'          = rr_estado,
      'Descripcion'   = es_descripcion

      from   cob_credito..cr_rub_renovar, 
        cob_cartera..ca_operacion, 
        cob_cartera..ca_rubro_op,
             cob_cartera..ca_estado
      where  rr_tramite    = @w_tramite
      and    rr_tramite    = op_tramite
      and    op_tramite    = @w_tramite
      and    op_operacion  = ro_operacion
      and    rr_concepto   = ro_concepto
      and    ro_concepto   > '0'
      and    ro_operacion  > 0
      and    ro_fpago       <> 'L'
      and    rr_estado      = es_codigo
      return 0
   end
   else
   begin
      if @i_crea_ext is null
      begin
         exec cobis..sp_cerror
              @t_debug  = @t_debug,
              @t_file   = @t_file,
              @t_from   = @w_sp_name,
              @i_num    = 2101006
              ---  'NO CORRESPONDE CODIGO DE TRANSACCION'
         return 1
      end
      else
      begin
         select @o_msg_msv = 'Tipo de transaccion no corresponde, ' + @w_sp_name
         select @w_return  = 2101006
         return @w_return
      end
   end
end


--- QUERY 
if @i_operacion = 'Q'
begin
   if @t_trn = 21774
   begin
      select   @w_tabla = codigo 
      from    cobis..cl_tabla
      where    tabla = 'cr_concepto'
      set transaction isolation level read uncommitted

      select  
      @w_tramite_ant   = rr_tramite, 
      @w_concepto      = rr_concepto,
      @w_desc_concepto = convert(char(50),valor),
      @w_renovar       = rr_renovar,
      @w_tramite_re    = rr_tramite_re
      from cr_rub_renovar,
           cobis..cl_catalogo
      where rr_tramite  = @w_tramite
      and   rr_concepto = codigo
      and   tabla       = @w_tabla
      and   rr_concepto > '0'
      
      if @i_crea_ext is null
      begin
         select 
         @w_tramite_ant,
         @w_concepto,
         @w_desc_concepto,
         @w_renovar,
         @w_tramite_re
      end
      return 0
   end
else
   begin
      if @i_crea_ext is null
      begin
         exec cobis..sp_cerror
              @t_debug  = @t_debug,
              @t_file   = @t_file,
              @t_from   = @w_sp_name,
              @i_num    = 2101006
              ---  'NO CORRESPONDE CODIGO DE TRANSACCION'
         return 1
      end
      else
      begin
         select @o_msg_msv = 'Tipo de transaccion no corresponde, ' + @w_sp_name
         select @w_return  = 2101006
         return @w_return
      end
   end
end

GO
