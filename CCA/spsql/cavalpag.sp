/************************************************************************/
/*      Archivo:                cavalpag.sp                             */
/*      Stored procedure:       sp_valores_pag                          */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Tania Suarez                            */
/*      Fecha de escritura:     Febrero 1999                            */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'                                                        */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Consulta datos pagados de intereses corriente y de mora durante */
/*      el año y el saldo capital de la operacion a fin de año.         */
/************************************************************************/
/*                              CAMBIOS                                 */
/* FECHA              AUTOR                  CAMBIOS                    */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_valores_pag')
   drop proc sp_valores_pag
go

---LLS 53696 MAR.26.2012
create proc sp_valores_pag(
       @i_fecha           datetime
)   
as
declare @w_sp_name        varchar(64),
        @w_periodo        int,
        @w_periodo_real   int,
        @w_inicio_periodo datetime,
        @w_fin_periodo    datetime,
        @w_inicio_mes     datetime,
        @w_desc_err       varchar(64),
        @w_fecha_max      datetime
        
create table #tmp_interes
(
op_operacion    int      null,
op_banco        cuenta   null, 
op_toperacion   catalogo null, 
op_cliente      int      null, 
op_oficina      int      null, 
ar_interes      money    null,
ar_existe       char(1)  null
)
create index idx1 on #tmp_interes (op_cliente, op_banco)

-- CARGA DE LOS PARAMETROS DE CARTERA
select @w_sp_name = 'sp_valores_pag'
select @w_periodo = datepart(yy, @i_fecha)
select @w_periodo_real = datepart(yy, getdate())

if (datediff(dd, @i_fecha, getdate())>0 and datepart(dd, @i_fecha) = 31 and datepart(mm, @i_fecha) = 12)
or @w_periodo < @w_periodo_real
begin

   -- SETERA VARIABLES PARA CONSULTAR RANGOS DE FECHAS
   select @w_inicio_periodo = convert(datetime, '01/01/' + convert(varchar, @w_periodo))
   select @w_inicio_mes     = convert(datetime, '12/01/' + convert(varchar, @w_periodo))
   select @w_fin_periodo    = convert(datetime, '12/31/' + convert(varchar, @w_periodo))
   
   ---OBTIENE LA ÚLTIMA FECHA DEL PERIODO ALMACENADA EN EL REPORISTORIO REC 
   select @w_fecha_max = max(do_fecha)
   from cob_conta_super..sb_dato_operacion
   where do_fecha >= @w_inicio_mes
   and   do_fecha <= @w_fin_periodo
   if @@rowcount > 0 begin
      select @w_fin_periodo = @w_fecha_max       
   end            

   -- SI SE TRATA DE UN REPROCESO BORRA LOS DATOS
   if exists(select 1 from ca_valores_pag where vp_periodo = @w_periodo)
   begin
      delete ca_valores_pag where vp_periodo = @w_periodo
      
      if @@error <> 0 
      begin
         select @w_desc_err = 'Error al borrar datos de ca_valores_pag'
         goto ERROR_BATCH
      end
   end

    
   -- INSERTA DATOS EN TABLA CON SALDOS DE CAPITAL
   insert into ca_valores_pag
   (vp_periodo,      vp_cliente,         vp_operacion,     vp_banco,         vp_oficina,         
    vp_toperacion,   vp_int_pag,         vp_imo_pag,       vp_saldo)

   select 
   @w_periodo,      op_cliente,         op_operacion,     do_banco,         op_oficina,
   op_toperacion,   0,                  0,                do_saldo_cap
   from cob_conta_super..sb_dato_operacion , ca_operacion
   where do_banco      = op_banco 
   and   op_tipo       <> 'R' ---PAsivas
   and   do_fecha      = @w_fin_periodo   
   
   union
   
   select 
   @w_periodo,      op_cliente,         op_operacion,     op_banco,         op_oficina,
   op_toperacion,   0,                  0,                do_saldo_cap
   from cob_conta_super..sb_dato_operacion, cob_cartera_his..ca_operacion
   where do_banco      = op_banco   
   and   op_tipo       <> 'R' ---PAsivas
   and   do_fecha      = @w_fin_periodo   
      
   if @@error <> 0 
   begin
      select @w_desc_err = 'Error al insertar datos de saldo capital en ca_valores_pag'
      goto ERROR_BATCH
   end      
   

   -- CREA VALORES DE INTERES EN TABLA TEMPORAL    
   insert into #tmp_interes
   select op_operacion,   op_banco, op_toperacion, op_cliente, op_oficina, ar_interes = sum(ar_monto_mn), ar_existe = 'N'
     from ca_abono, ca_abono_det, ca_abono_rubro, ca_operacion
    where ab_operacion               = abd_operacion
      and ab_secuencial_ing          = abd_secuencial_ing
      and abd_tipo                   = 'PAG'
      and ab_estado                  = 'A'
      and ab_fecha_pag               >= @w_inicio_periodo 
      and ab_fecha_pag               <= @w_fin_periodo 
      and abd_operacion              = ar_operacion
      and ab_secuencial_pag          = ar_secuencial
      and ar_concepto                = 'INT'
      and ab_operacion               = op_operacion
      and op_tipo                   <> 'R' ---PAsivas
   group by op_operacion, op_banco, op_toperacion, op_cliente, op_oficina   
      
   if @@error <> 0 
   begin
      select @w_desc_err = 'Error al crear datos de valores pagados de INT en tabla temporal'
      goto ERROR_BATCH
   end         
   
   insert into #tmp_interes
   select op_operacion,   op_banco, op_toperacion, op_cliente, op_oficina, ar_interes = sum(ar_monto_mn), ar_existe = 'N'
     from cob_cartera_his..ca_abono, cob_cartera_his..ca_abono_det, cob_cartera_his..ca_abono_rubro, cob_cartera_his..ca_operacion
    where ab_operacion               = abd_operacion
      and ab_secuencial_ing          = abd_secuencial_ing
      and abd_tipo                   = 'PAG'
      and ab_estado                  = 'A'
      and ab_fecha_pag               >= @w_inicio_periodo 
      and ab_fecha_pag               <= @w_fin_periodo 
      and abd_operacion              = ar_operacion
      and ab_secuencial_pag          = ar_secuencial
      and ar_concepto                = 'INT'
      and ab_operacion               = op_operacion
      and op_tipo                   <> 'R' ---PAsivas
   group by op_operacion, op_banco, op_toperacion, op_cliente, op_oficina   
   
   if @@error <> 0 
   begin
      select @w_desc_err = 'Error al crear datos de valores pagados de INT en tabla temporal desde HISTORICAS'
      goto ERROR_BATCH
   end         

   
   -- ACTUALIZA MARCA DE OPERACIONES EXISTENTES EN TABLA TEMPORAL 
   update #tmp_interes
      set ar_existe  = 'S'
     from ca_valores_pag
    where vp_periodo = @w_periodo
      and vp_cliente = op_cliente
      and vp_banco   = op_banco

   if @@error <> 0 
   begin
      select @w_desc_err = 'Error al acualizar marca de operacion en tabla temporal'
      goto ERROR_BATCH
   end         
      

   -- INSERTA OPERACIONES CON VALORES DE INTERES PAGADO
   insert into ca_valores_pag     
   (vp_periodo,        vp_cliente,         vp_operacion,     vp_banco,         vp_oficina,         
    vp_toperacion,     vp_int_pag,         vp_imo_pag,       vp_saldo)
   select @w_periodo,  op_cliente,         op_operacion,     op_banco,         op_oficina,
    op_toperacion,     0,                   0,               0
     from #tmp_interes
    where ar_existe = 'N'        
   
   if @@error <> 0 
   begin
      select @w_desc_err = 'Error al insertar datos de interes pagado en ca_valores_pag'
      goto ERROR_BATCH
   end     
    

   -- ACTUALIZA VALORES DE INTERES PAGADO
   update ca_valores_pag
      set vp_int_pag = isnull(ar_interes,0)
     from #tmp_interes 
    where vp_periodo = @w_periodo
      and vp_cliente = op_cliente
      and vp_banco   = op_banco
      
   if @@error <> 0 
   begin
      select @w_desc_err = 'Error al acualizar datos de valores pagados de INT en ca_valores_pag'
      goto ERROR_BATCH
   end            
     

   -- TRUNCA TABLA TEMPORAL PARA INGRESAR VALORES DE MORA
   truncate table #tmp_interes
   if @@error <> 0 
   begin
      select @w_desc_err = 'Error al acualizar marca de operacion en tabla temporal'
      goto ERROR_BATCH
   end       


   -- CREA VALORES DE MORA EN TABLA TEMPORAL    
   insert into #tmp_interes
   select op_operacion, op_banco, op_toperacion, op_cliente, op_oficina, ar_interes = sum(ar_monto_mn), ar_existe = 'N'
     from ca_abono, ca_abono_det, ca_abono_rubro, ca_operacion
    where ab_operacion               = abd_operacion
      and ab_secuencial_ing          = abd_secuencial_ing
      and abd_tipo                   = 'PAG'
      and ab_estado                  = 'A'
      and ab_fecha_pag               >= @w_inicio_periodo 
      and ab_fecha_pag               <= @w_fin_periodo 
      and abd_operacion              = ar_operacion
      and ab_secuencial_pag          = ar_secuencial
      and ar_concepto                = 'IMO'
      and ab_operacion               = op_operacion
      and op_tipo                   <> 'R' ---PAsivas
   group by op_operacion, op_banco, op_toperacion, op_cliente, op_oficina     

   if @@error <> 0 
   begin
      select @w_desc_err = 'Error al crear datos de valores pagados de IMO en tabla temporal'
      goto ERROR_BATCH
   end          
         
   -- ACTUALIZA MARCA DE OPERACIONES EXISTENTES EN TABLA TEMPORAL 
   update #tmp_interes
      set ar_existe  = 'S'
     from ca_valores_pag
    where vp_periodo = @w_periodo
      and vp_cliente = op_cliente
      and vp_banco   = op_banco

   if @@error <> 0 
   begin
      select @w_desc_err = 'Error al acualizar marca de operacion en tabla temporal'
      goto ERROR_BATCH
   end          

   insert into ca_valores_pag     
   (vp_periodo,        vp_cliente,         vp_operacion,     vp_banco,         vp_oficina,         
    vp_toperacion,     vp_int_pag,         vp_imo_pag,       vp_saldo)
   select @w_periodo,  op_cliente,         op_operacion,     op_banco,         op_oficina,
    op_toperacion,     0,                   0,               0
     from #tmp_interes
    where ar_existe = 'N'        

   
   if @@error <> 0 
   begin
      select @w_desc_err = 'Error al insertar datos mora pagados en ca_valores_pag'
      goto ERROR_BATCH
   end     
        

   update ca_valores_pag
      set vp_imo_pag = isnull(ar_interes,0)
     from #tmp_interes 
    where vp_periodo = @w_periodo
      and vp_cliente = op_cliente
      and vp_banco   = op_banco

   if @@error <> 0 
   begin
      select @w_desc_err = 'Error al acualizar datos de valores pagados de IMO en ca_valores_pag'
      goto ERROR_BATCH
   end         
      
      
end

ERROR_BATCH:
--while @@trancount > 0 rollback
 
exec sp_errorlog 
     @i_fecha       = @i_fecha,
     @i_error       = 0, 
     @i_usuario     = 'batch', 
     @i_tran        = 7999,
     @i_tran_name   = @w_sp_name,
     @i_cuenta      = '',
     @i_descripcion = @w_desc_err,
     @i_rollback    = 'N'

return 0
 
go

