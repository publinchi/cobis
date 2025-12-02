/************************************************************************/  
/*      Archivo:                creapas.sp                              */  
/*      Stored procedure:       sp_crea_pasiva                          */  
/*      Base de datos:          cob_cartera                             */  
/*      Producto:               Cartera                                 */  
/*      Disenado por:           Christian De la Cruz 	                */  
/*      Fecha de escritura:     Mar. 1998                               */  
/************************************************************************/  
/*                              IMPORTANTE                              */  
/*      Este programa es parte de los paquetes bancarios propiedad de   */  
/*      "MACOSA".							*/  
/*      Su uso no autorizado queda expresamente prohibido asi como      */  
/*      cualquier alteracion o agregado hecho por alguno de sus         */  
/*      usuarios sin el debido consentimiento por escrito de la         */  
/*      Presidencia Ejecutiva de MACOSA o su representante.             */  
/************************************************************************/  
/*                              PROPOSITO                               */  
/*      Creacion de operacion pasiva automaticamente al crear la        */  
/*      operacion activa de redescuento                                 */
/************************************************************************/  
/*	Oct.23/98	NydiaVelasco NVR	cambio tipo dato	*/
/************************************************************************/  
use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_crea_pasiva')
	drop proc sp_crea_pasiva
go
create proc sp_crea_pasiva(
@s_sesn			 int      = null,	--tinyint por int NVR
@s_user			 login        = null,
@s_date	 	         datetime     = null,
@s_ofi                   int,
@s_term			 varchar(30)  = null,
@i_cliente_pasiva	 int          = null,
@i_nombre_cliente_pasiva descripcion  = null,
@i_banco_activa		 cuenta       = null,
@i_tipo_redescuento	 catalogo     = null,
@i_operacion             char(1),
@i_modo                  char(1)      = '0',
@o_banco_pasiva		 cuenta       = null output)
as

declare 
@w_sp_name              descripcion,
@w_return               int,
@w_error                int,
@w_operacion_pasiva	int,
@w_toperacion		catalogo,
@w_oficina		smallint,
@w_moneda		tinyint,
@w_operacion_activa	int,
@w_valor		money,
@w_banco_pasiva		cuenta

select @w_sp_name = 'sp_crea_pasiva'


/*TOMA DATOS DE LA OPERACION ACTIVA DE CA_OPERACION_TMP*/

select  
@w_operacion_activa     = opt_operacion,
@w_toperacion 		= opt_toperacion,		
@w_oficina 		= opt_oficina,
@w_moneda 		= opt_moneda
from ca_operacion_tmp
where opt_banco = @i_banco_activa

/* CREACION DE LA OPERACION PASIVA PARA UNA ACTIVA*/
if @i_operacion = 'C' begin
   /*AUMENTADO*/
   /*TOMAR EL MARGEN DE REDESCUENTO POR TIPO DE OPERACION DE REDESCUENTO*/
   if not exists ( select 1 from ca_rubro
                   where ru_toperacion = @i_tipo_redescuento
                   and   ru_tipo_rubro = 'C') begin
      select @w_error = 710117 
      goto ERROR
   end      

   /*MODIFICADO 03/11/98*/
   select @w_valor = sum(rot_valor)
   from ca_rubro_op_tmp
   where rot_operacion = @w_operacion_activa
   and   rot_tipo_rubro = 'C' 

   select @w_valor = (@w_valor * ru_redescuento )/100 
   from ca_rubro
   where ru_toperacion = @i_tipo_redescuento
   and   ru_tipo_rubro = 'C'
   and   ru_moneda     = @w_moneda

   begin tran

   /*CREAR OPERACION PASIVA */
   exec @w_return = sp_crear_operacion_pas
   @s_user              = @s_user,                  
   @s_sesn              = @s_sesn,                  
   @s_ofi               = @s_ofi,                   
   @s_date              = @s_date,                  
   @s_term              = @s_term,                  
   @i_tramite           = null,
   @i_cliente	        = @i_cliente_pasiva,               
   @i_nombre            = @i_nombre_cliente_pasiva,                
   @i_toperacion_pasiva   = @i_tipo_redescuento,            
   @i_oficina           = @w_oficina,               
   @i_monto             = @w_valor,
   @i_monto_aprobado    = @w_valor,
   @i_no_banco          = 'S',
   @i_salida	        = 'N',
   @i_crear_pasiva      = 'S',
   @i_toperacion_activa = @w_toperacion,
   @i_operacion_activa  = @w_operacion_activa,
   @o_banco               = @w_banco_pasiva output        

   if @w_return != 0  begin
      select @w_error = @w_return 
      goto ERROR
   end  
 
   /*ASOCIAR OPERACION PASIVA A OPERACION ACTIVA*/

   select @w_operacion_pasiva = opt_operacion 
   from ca_operacion_tmp
   where opt_banco = @w_banco_pasiva

   insert into ca_relacion_ptmo_tmp(rpt_activa,rpt_pasiva) 
   values(@w_operacion_activa,@w_operacion_pasiva)

   if @@error <> 0 begin
      select @w_error = 710001
      goto ERROR
   end

   select @o_banco_pasiva = @w_banco_pasiva

   commit tran

end


/*CONSULTA DE LA OPERACION PASIVA DE UNA ACTIVA*/
if @i_operacion = 'Q' begin
  if exists(select * from ca_relacion_ptmo
          where rp_pasiva = @w_operacion_activa) begin
        select @w_error = 710095     
        goto ERROR                   
  end
   
  if exists(select * from ca_relacion_ptmo
          where rp_activa = @w_operacion_activa) begin
      select
      op_toperacion,
      C.valor,
      op_banco,
      op_cliente,
      op_nombre
      from 
      ca_relacion_ptmo,
      ca_operacion,
      cobis..cl_tabla T with (nolock),
      cobis..cl_catalogo C with (nolock)
      where rp_activa = @w_operacion_activa
      and   rp_pasiva = op_operacion
      and   T.tabla    = 'ca_toperacion'
      and   T.codigo   = C.tabla
      and   C.codigo   = op_toperacion
   end 
   else begin
      select
      opt_toperacion,
      C.valor,
      opt_banco,
      opt_cliente,
      opt_nombre
      from 
      ca_relacion_ptmo_tmp,
      ca_operacion_tmp,
      cobis..cl_tabla T with (nolock),
      cobis..cl_catalogo C with (nolock)
      where rpt_activa = @w_operacion_activa
      and   rpt_pasiva = opt_operacion
      and   T.tabla    = 'ca_toperacion'
      and   T.codigo   = C.tabla
      and   C.codigo   = opt_toperacion
   end

end 

return 0

ERROR:

exec cobis..sp_cerror
@t_debug='N',         
@t_file   = null,
@t_from   =@w_sp_name,   
@i_num    = @w_error
--@i_cuenta = ' '

return @w_error
                                               
go
