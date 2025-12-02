/***********************************************************************/
/*  Archivo:            busoperh.sp                    */
/*  Stored procedure:       sp_buscar_operaciones_his      */
/*  Base de Datos:          cob_cartera_his                */
/*  Producto:           Cartera                        */
/*  Disenado por:           Fabian de la Torre             */
/*  Fecha de Documentacion:     Ene. 98                        */
/***********************************************************************/
/*          IMPORTANTE                         */
/*  Este programa es parte de los paquetes bancarios propiedad de  */   
/*  'MACOSA'.                              */
/*  Su uso no autorizado queda expresamente prohibido asi como     */
/*  cualquier autorizacion o agregado hecho por alguno de sus      */
/*  usuario sin el debido consentimiento por escrito de la         */
/*  Presidencia Ejecutiva de MACOSA o su representante         */
/***********************************************************************/  
/*          PROPOSITO                      */
/*  Buscar operaciones deacuerdo a criterio                        */   
/***********************************************************************/

use cob_cartera_his
go

if exists(select 1 from sysobjects where name = 'sp_buscar_operaciones_his')
    drop proc sp_buscar_operaciones_his
go

create proc sp_buscar_operaciones_his (
    @s_user         varchar (14)= null,
    @i_banco        varchar (64)= null,
    @i_tramite      int         = null,
    @i_cliente      int         = null,
    @i_oficina      smallint    = null,
    @i_moneda       tinyint     = null,
    @i_oficial      smallint    = null,
    @i_fecha_ini        datetime    = null,
    @i_toperacion       varchar (64)= null,
    @i_lin_credito      varchar (64)= null,
    @i_estado       varchar (64)    = null,
        @i_migrada              varchar (64)    = null,
        @i_fecha_reajuste       datetime    = null,
    @i_siguiente        int         = 0,
        @i_formato_fecha        int         = null,
        @i_condicion_est        tinyint     = null,
        @i_fecha_a_reajustar    datetime    = null,
        @i_tipo_op              char(1)     = null,
        @i_ref_red              varchar(24) = null,
        @i_find_inst_op         char(1)     = null,
        @i_ref_exterior         varchar (64)= null, 
        @i_num_deuda_ext        varchar (64)= null, 
        @i_comex                varchar (64)= null  
)
as
declare
    @w_sp_name  varchar(32),    
    @w_opcion   int,
        @w_error        int,
        @w_estado       int,
        @w_redbusca     int,
        @w_truta        tinyint,
        @w_oficina_matriz  int
/*    

/*  Captura nombre de Stored Procedure  */
select @w_sp_name = 'sp_buscar_operaciones'

select @w_oficina_matriz = 900

if @i_siguiente <> 0
   goto SIGUIENTE

/* LIMPIAR TABLA TEMPORAL */
delete cob_cartera..ca_buscar_operaciones_tmp
where  bot_usuario = @s_user

/* BUSCAR OPCION DE BUSQUEDA */
select @w_opcion = 1000


if @i_banco is not null 
   select @w_opcion = 1
else
   if @i_tramite is not null
      select @w_opcion = 2
   else
      if @i_cliente is not null
         select @w_opcion = 3
      else
         if @i_oficial is not null
            select @w_opcion = 4
         else
            if @i_oficina is not null
               select @w_opcion = 5
            else
               if @i_num_deuda_ext is not null
                  select @w_opcion = 6
               else
                  if @i_comex is not null
                     select @w_opcion = 7

if @i_tipo_op = 'R' select @w_redbusca = 1
if @i_tipo_op = 'X' select @w_redbusca = 2
if @i_tipo_op is null select @w_redbusca = 3

if @w_opcion > 7 begin --Esto es para que siempre haya un campo primario 
   select @w_error  = 708199
   goto ERROR
end

/* CONVERTIR EL ESTADO DESCRIPCION A ESTADO NUMERO */
if @i_estado is not null
   select @w_estado = es_codigo
   from cob_cartera..ca_estado
   where es_descripcion = @i_estado


/* BUSQUEDAS DE NUMERO DE OPERACIONES */

if @w_opcion = 1 

   insert into cob_cartera..ca_buscar_operaciones_tmp
   select @s_user,
   op_operacion,   op_moneda,  op_fecha_ini,
   op_lin_credito, op_estado,  op_migrada,
   op_toperacion , op_oficina, op_oficial,
   op_cliente    , op_tramite, op_banco,
   op_fecha_reajuste, op_tipo, op_reajuste_especial,
   op_reajustable, op_monto,   op_monto_aprobado,
   op_anterior,    op_fecha_ult_proceso, op_nro_red,
   op_ref_exterior,(select convert(varchar(10),tr_truta) from cob_credito..cr_tramite where tr_tramite = cob_cartera_his..ca_operacion.op_tramite),
   op_num_comex,
   op_tipo_linea,  op_nombre,  op_fecha_fin
   from cob_cartera_his..ca_operacion 
   where op_banco = @i_banco
     and ((op_tipo = @i_tipo_op and @w_redbusca = 1) or
         (op_tipo != 'R' and @w_redbusca = 2) or
         (op_tipo is not null and @w_redbusca = 3)) 
     
        


if @w_opcion = 2 begin 

   insert into cob_cartera..ca_buscar_operaciones_tmp
   select @s_user,
   op_operacion,   op_moneda,  op_fecha_ini,
   op_lin_credito, op_estado,  op_migrada,
   op_toperacion , op_oficina, op_oficial,
   op_cliente    , op_tramite, op_banco,
   op_fecha_reajuste, op_tipo, op_reajuste_especial,
   op_reajustable, op_monto,   op_monto_aprobado,
   op_anterior,    op_fecha_ult_proceso, op_nro_red,
   op_ref_exterior,(select convert(varchar(10),tr_truta) from cob_credito..cr_tramite where tr_tramite = cob_cartera_his..ca_operacion.op_tramite),
   op_num_comex,
   op_tipo_linea,  op_nombre,  op_fecha_fin
   from cob_cartera_his..ca_operacion
   where op_tramite = @i_tramite
     and ((op_tipo = @i_tipo_op and @w_redbusca = 1) or
         (op_tipo != 'R' and @w_redbusca = 2) or
         (op_tipo is not null and @w_redbusca = 3)) 

end

if @w_opcion = 3 

   insert into cob_cartera..ca_buscar_operaciones_tmp
   select @s_user,
   op_operacion,   op_moneda,  op_fecha_ini,
   op_lin_credito, op_estado,  op_migrada,
   op_toperacion , op_oficina, op_oficial,
   op_cliente    , op_tramite, op_banco,
   op_fecha_reajuste, op_tipo, op_reajuste_especial,
   op_reajustable, op_monto,   op_monto_aprobado,
   op_anterior,    op_fecha_ult_proceso, op_nro_red,
   op_ref_exterior,(select convert(varchar(10),tr_truta) from cob_credito..cr_tramite where tr_tramite = cob_cartera_his..ca_operacion.op_tramite),
   op_num_comex,
   op_tipo_linea,  op_nombre,  op_fecha_fin
   from cob_cartera_his..ca_operacion
   where op_cliente = @i_cliente
     and ((op_tipo = @i_tipo_op and @w_redbusca = 1) or
         (op_tipo != 'R' and @w_redbusca = 2) or
         (op_tipo is not null and @w_redbusca = 3)) 


if @w_opcion = 4

   insert into cob_cartera..ca_buscar_operaciones_tmp
   select @s_user,
   op_operacion,   op_moneda,  op_fecha_ini,
   op_lin_credito, op_estado,  op_migrada,
   op_toperacion , op_oficina, op_oficial,
   op_cliente    , op_tramite, op_banco,
   op_fecha_reajuste,op_tipo,  op_reajuste_especial,
   op_reajustable, op_monto,   op_monto_aprobado,
   op_anterior,    op_fecha_ult_proceso, op_nro_red,
   op_ref_exterior,(select convert(varchar(10),tr_truta) from cob_credito..cr_tramite where tr_tramite = cob_cartera_his..ca_operacion.op_tramite),
   op_num_comex,
   op_tipo_linea,  op_nombre,  op_fecha_fin
   from cob_cartera_his..ca_operacion
   where op_oficial = @i_oficial
     and ((op_tipo = @i_tipo_op and @w_redbusca = 1) or
         (op_tipo != 'R' and @w_redbusca = 2) or
         (op_tipo is not null and @w_redbusca = 3)) 


if @w_opcion = 5 and @i_oficina = @w_oficina_matriz begin



   insert into cob_cartera..ca_buscar_operaciones_tmp
   select @s_user,
   op_operacion,   op_moneda,  op_fecha_ini,
   op_lin_credito, op_estado,  op_migrada,
   op_toperacion , op_oficina, op_oficial,
   op_cliente    , op_tramite, op_banco,
   op_fecha_reajuste,op_tipo,  op_reajuste_especial,
   op_reajustable, op_monto,   op_monto_aprobado,
   op_anterior,    op_fecha_ult_proceso, op_nro_red,
   op_ref_exterior,(select convert(varchar(10),tr_truta) from cob_credito..cr_tramite where tr_tramite = cob_cartera_his..ca_operacion.op_tramite),
   op_num_comex,
   op_tipo_linea,  op_nombre,  op_fecha_fin
   from cob_cartera_his..ca_operacion
   where ((op_tipo = @i_tipo_op and @w_redbusca = 1) or
         (op_tipo != 'R' and @w_redbusca = 2) or
         (op_tipo is not null and @w_redbusca = 3))

end else begin
   if @w_opcion = 5 and @i_oficina != @w_oficina_matriz

      insert into cob_cartera..ca_buscar_operaciones_tmp
      select @s_user,
      op_operacion,   op_moneda,  op_fecha_ini,
      op_lin_credito, op_estado,  op_migrada,
      op_toperacion , op_oficina, op_oficial,
      op_cliente    , op_tramite, op_banco,
      op_fecha_reajuste,op_tipo,  op_reajuste_especial,
      op_reajustable, op_monto,   op_monto_aprobado,
      op_anterior,    op_fecha_ult_proceso, op_nro_red,
      op_ref_exterior,(select convert(varchar(10),tr_truta) from cob_credito..cr_tramite where tr_tramite = cob_cartera_his..ca_operacion.op_tramite),
      op_num_comex,
      op_tipo_linea,  op_nombre,  op_fecha_fin 
      from cob_cartera_his..ca_operacion
      where op_oficina = @i_oficina
       and ((op_tipo = @i_tipo_op and @w_redbusca = 1) or
           (op_tipo != 'R' and @w_redbusca = 2) or
           (op_tipo is not null and @w_redbusca = 3))

end


if @w_opcion = 6
begin
   if @i_fecha_ini is not null
   begin

      select @w_truta = convert(tinyint, @i_num_deuda_ext)
      if exists(select 1 from cob_credito..cr_truta where ru_truta = @w_truta)

      insert into cob_cartera..ca_buscar_operaciones_tmp
      select @s_user,
             op_operacion,   op_moneda,  op_fecha_liq,
             op_lin_credito, op_estado,  op_migrada,
             op_toperacion , op_oficina, op_oficial,
             op_cliente    , op_tramite, op_banco,
             op_fecha_reajuste, op_tipo, op_reajuste_especial,
             op_reajustable, op_monto,   op_monto_aprobado,
             op_anterior,    op_fecha_ult_proceso, op_codigo_externo,
             op_ref_exterior,convert(varchar(10),tr_truta),
             op_num_comex,
             op_tipo_linea,  op_nombre,  op_fecha_fin
      from   cob_cartera_his..ca_operacion,
             cob_credito..cr_tramite
      where op_tramite = tr_tramite
      and   tr_truta   = @w_truta
      and   op_fecha_liq  = @i_fecha_ini
      and   (   (op_tipo = @i_tipo_op and @w_redbusca = 1)
             or (op_tipo != 'R' and @w_redbusca = 2)
             or (op_tipo is not null and @w_redbusca = 3)
            )
   end
   else
   begin
      select @w_error = 7
      goto ERROR
   end
end

if @w_opcion = 7

   insert into cob_cartera..ca_buscar_operaciones_tmp
   select @s_user,
   op_operacion,   op_moneda,  op_fecha_ini,
   op_lin_credito, op_estado,  op_migrada,
   op_toperacion , op_oficina, op_oficial,
   op_cliente    , op_tramite, op_banco,
   op_fecha_reajuste,op_tipo,  op_reajuste_especial,
   op_reajustable, op_monto,   op_monto_aprobado,
   op_anterior,    op_fecha_ult_proceso, op_nro_red,
   op_ref_exterior,(select convert(varchar(10),tr_truta) from cob_credito..cr_tramite where tr_tramite = cob_cartera_his..ca_operacion.op_tramite),
   op_num_comex,
   op_tipo_linea,  op_nombre,  op_fecha_fin
   from cob_cartera_his..ca_operacion
   where op_num_comex = @i_comex
     and ((op_tipo = @i_tipo_op and @w_redbusca = 1) or
         (op_tipo != 'R' and @w_redbusca = 2) or
         (op_tipo is not null and @w_redbusca = 3)) 

goto SIGUIENTE

/* RETORNAR DATOS A FRONT END */

SIGUIENTE:
   if @w_error = 7         
      print 'Para busqueda por ruta ingresar la fecha desembolso'

  if @i_oficina = @w_oficina_matriz
     select @i_oficina = null

  select --distinct 
  'Lin.Credito    '         = substring(bot_toperacion,1,30),
  'Moneda'              = bot_moneda,
  'No.Operacion'        = bot_banco,
  'Monto Operacion'         = convert(float, bot_monto),
  'Cliente'             = substring(bot_nombre,1,30),
  'Desembolso'          = convert(varchar(16),bot_fecha_ini, @i_formato_fecha),
  'Vencimiento'         = convert(varchar(10),bot_fecha_fin, @i_formato_fecha),
  'Oficial'             = bot_oficial,
  'Oficina'             = bot_oficina,
  'Cup.Credito'         = bot_lin_credito,
  'Op.Migrada'          = substring(bot_migrada,1,20),
  'Op.Anterior'         = substring(bot_anterior,1,20),
  'Estado'              = substring(es_descripcion,1,20), 
  'Trÿmite'             = convert(varchar(13),bot_tramite),
  'Cod.Cli'             = bot_cliente,
  'Secuencial'          = bot_operacion,
  'Reaj.Especial'       = bot_reajuste_especial,
  'Ref.Redescont'       = bot_nro_red,
  'Clase Oper.'         = bot_tipo      
  from cob_cartera..ca_buscar_operaciones_tmp, cob_cartera..ca_estado
  where bot_usuario = @s_user
  and   (bot_moneda         = @i_moneda         or @i_moneda         is null)
  and   (bot_fecha_reajuste = @i_fecha_reajuste or @i_fecha_reajuste is null)
  and   (bot_fecha_ini      = @i_fecha_ini      or @i_fecha_ini      is null)
  and   (bot_lin_credito    = @i_lin_credito    or @i_lin_credito    is null)
  and   (bot_estado         = @w_estado         or @w_estado         is null)
  and   (bot_migrada        = @i_migrada        or @i_migrada        is null)
  and   (bot_ref_exterior   = @i_ref_exterior   or @i_ref_exterior   is null)
  and   (bot_toperacion     = @i_toperacion     or @i_toperacion     is null)
  and   (bot_oficina        = @i_oficina        or @i_oficina        is null)
  and   (bot_oficial        = @i_oficial        or @i_oficial        is null)
  and   (bot_cliente        = @i_cliente        or @i_cliente        is null)
  and   (bot_tramite        = @i_tramite        or @i_tramite        is null)
  and   (bot_banco          = @i_banco          or @i_banco          is null) 
  and   (bot_nro_red        = @i_ref_red        or @i_ref_red        is null)
  and   (bot_num_comex      = @i_comex          or @i_comex          is null)
  and   (bot_num_deuda_ext  = @i_num_deuda_ext  or @i_num_deuda_ext  is null)
  and   (bot_estado  = 0 and bot_estado not in (3,10) or @i_condicion_est != 1)
  and   (bot_estado  not in (0,10) or  @i_condicion_est <> 2  ) 
  and   ((bot_reajustable = 'S' and @i_fecha_a_reajustar >= bot_fecha_ult_proceso and bot_estado != 10) or @i_condicion_est <> 4) 
  and   (((bot_monto < bot_monto_aprobado or bot_tipo = 'O') and bot_estado not in(3,4,10)) or @i_condicion_est <> 5)    
  and   ((bot_anterior is not null and bot_estado = 0) or @i_condicion_est <> 6)
  and   (bot_estado not in (0,3,10)  or @i_condicion_est <> 7  ) 
  and   bot_estado = es_codigo
  and   es_codigo not in (98,99) -- Menos Operaciones de Credito y Comext
  and   bot_operacion > @i_siguiente
  order by bot_operacion

  if @@rowcount = 0 begin
   select @w_error = 1
   goto ERROR
  end
*/
return 0
/*
ERROR:
if @w_error = 1 
   print 'No existen mas operaciones'
else 
   print 'Ingrese al menos un criterio de busqueda principal'
return 1 
*/
go


