/************************************************************************/
/*      Archivo:                val_tra_bancamia.sp                     */
/*      Stored procedure:       sp_valida_operaciones_bancamia          */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Miguel Roa                              */
/*      Fecha de escritura:     Mayo 2008                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.	                                                */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Valida transacciones de bancamia                                */
/************************************************************************/

use cob_cartera
go

set ansi_nulls off
go

if exists (select 1 from sysobjects where name = 'sp_valida_operaciones_bancamia')
   drop proc sp_valida_operaciones_bancamia
go

create proc sp_valida_operaciones_bancamia
as

declare 
@w_op_ced_ruc          varchar(10),
@w_op_tipo_doc         varchar(5),
@w_op_clase            varchar(10),
@w_op_estado           tinyint,
@w_op_sector           varchar(26),
@w_op_banco            varchar(26),
@w_msg_er              varchar(255),
@w_es_error            char(1),
@w_ente                int,
@w_contador            int,
@w_min_fecha           datetime,
@w_commit              char(1),
@w_fecha_proceso       smalldatetime,
@w_comodin             int,
@w_comodin_ced_ruc     varchar(10),
@w_cliente_cuantias    int,
@w_tr_fecha_mov        smalldatetime 

select 
@w_contador = 0,
@w_commit   = 'N'


/* DETERMINAR EL CODIGO DEL CLIENTE COMODIN */
select @w_comodin         = en_ente,
       @w_comodin_ced_ruc = en_ced_ruc
from cobis..cl_ente
where en_nomlar like 'BANCAMIA%'
and   en_subtipo = 'C'


select @w_cliente_cuantias = en_ente
from cobis..cl_ente
where en_nomlar like 'CUANTIAS%'
and   en_subtipo = 'C'


select @w_fecha_proceso =  fc_fecha_cierre
from cobis..ba_fecha_cierre
where  fc_producto = 7


/* LIMPIAR OBSERVACIONES PARA REPROCESO */
update ca_operacion_bancamia_tmp set op_obs = ''

if @@error <> 0 begin
   print 'Error en insercion ca_operacion_bancamia'
   return 0
end

delete ca_errorlog where er_error = 7200

delete from cob_ccontable..cco_error_conaut
where ec_producto = 200


truncate table ca_operacion_bancamia

select op_ced_ruc, op_tipo_doc, op_clase, op_estado, op_sector, op_banco
into   #ca_op_tmp
from  ca_operacion_bancamia_tmp


/* CURSOR PARA DETERMINAR TODAS LAS OPERACIONES A RELACIONAR */
declare cursor_operaciones cursor for select 
op_ced_ruc, op_tipo_doc, op_clase, op_estado, op_sector, op_banco
from  #ca_op_tmp
for read only

open  cursor_operaciones

fetch cursor_operaciones
into  @w_op_ced_ruc, @w_op_tipo_doc, @w_op_clase, @w_op_estado, @w_op_sector, @w_op_banco

while  @@fetch_status = 0 begin

   if @w_commit = 'N' begin
      begin tran
      select @w_commit = 'S'
   end

   select 
   @w_es_error = 'N',
   @w_msg_er   = '',
   @w_ente     = 0
    
   if exists(select 1 from ca_operacion_bancamia where op_banco = @w_op_banco) goto SIGUIENTE      


   /* CODIGO CLIENTE */
   if '*' <> substring(@w_op_banco,1,1) begin
      set rowcount 1
      select 
      @w_ente      = do_codigo_cliente,          --Valida que exista el cliente 
      @w_op_estado = case do_estado_contable when 3 then 4 when 4 then 3 else do_estado_contable end,
      @w_op_clase  = do_clase_cartera
      from cob_conta_super..sb_dato_operacion
      where do_banco    = @w_op_banco
      order by do_fecha desc
      if @@rowcount = 0 begin
         select @w_msg_er = @w_msg_er + 'NO EXISTE PRESTAMO EN CR_DATO_OPERACION (' + @w_op_banco + '), '
         select @w_es_error = 'S'
      end
      set rowcount 0

      select 
      @w_op_tipo_doc  = en_tipo_ced,
      @w_op_ced_ruc   = en_ced_ruc
      from cobis..cl_ente
      where en_ente  = @w_ente

      if @@rowcount = 0 begin
         select @w_msg_er = @w_msg_er + 'NO existe cliente  (' + convert(varchar(12),@w_ente) + '), '
         select @w_es_error = 'S'
      end

   end else begin
      if ltrim(rtrim(@w_comodin_ced_ruc)) = ltrim(rtrim(@w_op_ced_ruc)) begin
         select 
         @w_ente         = @w_comodin,
         @w_op_tipo_doc  = 'N',
         @w_op_ced_ruc   = @w_comodin_ced_ruc
         
      end else begin
      	
         select 
         @w_ente         = en_ente,
         @w_op_tipo_doc  = en_tipo_ced,
         @w_op_ced_ruc   = en_ced_ruc
         from cobis..cl_ente (nolock)
         where en_ced_ruc  = @w_op_ced_ruc
         
         if @@rowcount = 0 begin         
            if exists( select 1 from ca_det_trn_bancamia_tmp (nolock)
            where dtr_banco       = @w_op_banco
            and   dtr_concepto   in ('CO_ERR', 'CEF','TRAEG','TRASENCAJ'))
            begin
               select @w_ente = @w_comodin  --CLIENTE COMODIN BANCAMIA
            end else begin
               select @w_ente = @w_cliente_cuantias     ---348540 CLIENTE CUANTIAS MENORES
            end
         
            select 
            @w_op_tipo_doc  = en_tipo_ced,
            @w_op_ced_ruc   = en_ced_ruc
            from cobis..cl_ente (nolock)
            where en_ente  = @w_ente         
         end         
      end

      select 
      @w_op_estado = 1,
      @w_op_clase  = '4',
      @w_op_sector = '1'

   end

       
   /* VALIDAR EXISTENCIA DEL SECTOR DE LA OPERACION */       
   if not exists (select 1 from cobis..cl_tabla t, cobis..cl_catalogo c
   where t.tabla = 'cl_banca_cliente'
   and   c.tabla = t.codigo
   and   c.codigo = @w_op_sector)
   begin
      select @w_msg_er = @w_msg_er + 'NO existe Sector (' + @w_op_sector + '), '
      select @w_es_error = 'S'
   end
                       
  
   /* RUTINA DE ERROR */                          
   if @w_es_error = 'S' begin


      update ca_det_trn_bancamia_tmp set
      dtr_dividendo    = 999,
      dtr_beneficiario = substring(@w_msg_er,1,64)
      where dtr_banco  = @w_op_banco

      if @@error <> 0 begin
         select @w_msg_er = 'ERR: En actualizar ca_det_bancamia_tmp '
         goto ERROR
       end
 
      update ca_transaccion_bancamia_tmp set
      tr_operacion    = 999,
      tr_observacion  = substring(@w_msg_er,1,62)
      where tr_banco  = @w_op_banco

      if @@error <> 0 begin
         select @w_msg_er = 'ERR: En actualizar ca_transaccion_bancamia_tmp '
         goto ERROR
      end


      update ca_operacion_bancamia_tmp set
      op_obs = @w_msg_er
      from ca_operacion_bancamia_tmp  with (index= ca_op_bancamia_tmp_1)
      where  op_banco = @w_op_banco
      if @@error <> 0 begin
         select @w_msg_er = @w_msg_er + 'Error en UPDATE ca_operacion_bancamia_tmp, '
         goto ERROR
      end

      exec sp_errorlog
      @i_fecha       = @w_fecha_proceso, 
      @i_error       = 7200, 
      @i_usuario     = 'operador',
      @i_tran        = 7000, 
      @i_tran_name   = 'sp_valida_operaciones_bancamia', 
      @i_rollback    = 'N',
      @i_cuenta      = @w_op_banco, 
      @i_descripcion = @w_msg_er

   end else begin     

      
      insert into ca_operacion_bancamia (
      op_ced_ruc,    op_tipo_doc,    op_clase,    
      op_estado,     op_sector,      op_banco, 
      op_ente)
      values(
      @w_op_ced_ruc, @w_op_tipo_doc, @w_op_clase, 
      @w_op_estado,  @w_op_sector,   @w_op_banco, 
      @w_ente)

      if @@error <> 0 begin
         select @w_msg_er = @w_msg_er + 'Error en insercion ca_operacion_bancamia, '
         goto ERROR
      end

   end

   goto SIGUIENTE
        

   ERROR:
 
   exec sp_errorlog
   @i_fecha       = @w_fecha_proceso, 

   @i_error       = 7200, 
   @i_usuario     = 'operador',
   @i_tran        = 7000, 
   @i_tran_name   = 'sp_valida_operaciones_bancamia', 
   @i_rollback    = 'N',
   @i_cuenta      = @w_op_banco, 
   @i_descripcion = @w_msg_er


   SIGUIENTE:

   select @w_contador = @w_contador + 1
    
   if @w_contador = 200 begin
      commit tran
      select 
      @w_commit   = 'N',
      @w_contador = 0
   end

   fetch cursor_operaciones
   into  @w_op_ced_ruc, @w_op_tipo_doc, @w_op_clase, @w_op_estado, @w_op_sector, @w_op_banco

end -- Fin cursor cursor_operaciones

close cursor_operaciones
deallocate cursor_operaciones


if @w_commit = 'S' begin
   commit tran
   select @w_commit = 'N'
end

while @@trancount > 0  commit tran 

return 0

go




