/************************************************************************/
/*      Archivo:                ca_venta_pago.sp                        */
/*      Stored procedure:       sp_venta_pago                           */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Fecha de escritura:     Noviembre 2013                          */
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
/* Realiza condonación masiva de la venta de cartera de las obligaciones*/ 
/* castigadas usando la tabla cob_cartera..ca_venta_universo            */
/* creada en el proceso sp_venta_universo                               */
/************************************************************************/
/*                              CAMBIOS                                 */
/*  FECHA     AUTOR             RAZON                                   */
/*  21-11-13  L.Guzman          Emisión Inicial - Req: Venta Cartera    */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_venta_pago')
   drop proc sp_venta_pago
go

create proc sp_venta_pago
   @i_param1            varchar(255)  = null, 
   @i_param2            varchar(255)  = null, 
   @i_param3            varchar(255)  = null, 
   @i_param4            varchar(255)  = null, 
   @i_param5            varchar(255)  = null,
   @i_param6            varchar(255)  = null,
   @s_user              login         = 'sp_venta_pago',
   @i_debug             char(1)       = 'N'  

as
declare
@w_banco           cuenta,
@w_operacionca     int,
@w_banca           catalogo,
@w_pago            money,
@w_secuencial_ing  int,
@w_secuencial      int,
@w_secuencial_ven  int,
@w_secuencial_vig  int,
@w_secuencial_nvig int,
@w_sp_name         varchar(32),
@w_error           int,
@w_msg             varchar(255),
@w_fecha_proceso   datetime,
@w_ano_castigo     int,
@w_oficina         int,
@w_rol             int,
@w_est_castigado   tinyint,
@w_est_cancelado   tinyint,
@w_est_vencido     tinyint,
@w_est_vigente     tinyint,
@w_est_novigente   tinyint,
@w_concepto        varchar(10),
@w_porcentaje      float,
@w_valor           money,
@w_estado          int,
@w_crea_pago       char(1),
@w_sec_generado    int,
@w_hijo            varchar(2),
@w_sarta           int       , 
@w_batch           int       , 
@w_opcion          char(1)   , 
@w_bloque          int,
@w_cont            int,
@w_saldo_final     money  ,
@w_est_op          smallint,
@w_tipo            char(1) 

set nocount on

select @w_sp_name   = 'sp_venta_pago'

--INICIALIZA VARIABLES
select 
@w_secuencial_ven  = 0,
@w_secuencial_vig  = 0,
@w_secuencial_nvig = 0,
@w_hijo            = convert(varchar(2), rtrim(ltrim(@i_param1))),
@w_sarta           = convert(int       , rtrim(ltrim(@i_param2))),
@w_batch           = convert(int       , rtrim(ltrim(@i_param3))),
@w_opcion          = convert(char(1)   , rtrim(ltrim(@i_param4))),
@w_bloque          = convert(int       , rtrim(ltrim(@i_param5))),
@w_rol             = convert(int       , rtrim(ltrim(@i_param6)))

-- OBTIENE FECHA DE PROCESO
select @w_fecha_proceso = fc_fecha_cierre 
from cobis..ba_fecha_cierre
where fc_producto = 7

if @@rowcount = 0
begin
   select @w_msg = 'Error al leer fecha de proceso de cartera',
          @w_error = 801085
   goto ERROR
end


if @w_opcion = 'G' begin  -- generar universo

   truncate table ca_universo_venta
      
   insert into ca_universo_venta with (rowlock)
   select
   operacion_interna,   'N',            0
   from cob_cartera..ca_venta_universo with (nolock)
   where  Estado_Venta = 'I'

   if @@error <> 0 begin
      select 
      @w_msg = ' ERROR AL INSERTAR EN UNIVERSO VENTA ' ,
      @w_error   = 710001
      goto ERROR
   end   
   
   delete cobis..ba_ctrl_ciclico 
   where ctc_sarta = @w_sarta
   
   insert into cobis..ba_ctrl_ciclico with (rowlock)
   select sb_sarta,sb_batch, sb_secuencial, 'S', 'P'
   from cobis..ba_sarta_batch with (nolock)
   where sb_sarta = @w_sarta
   and   sb_batch = @w_batch
  
   return 0
   
end

if @w_opcion = 'B' begin  --procesos batch

   select @w_cont = isnull(count(*),0)
   from ca_universo_venta with (nolock)
   where ub_estado   = @w_hijo
   
   select @w_cont = @w_bloque - @w_cont
   
   if @w_cont > 0 begin
   
      set rowcount @w_cont
      
      update ca_universo_venta with (rowlock) set
      ub_estado = @w_hijo
      where ub_estado    = 'N'
      
      if @@error <> 0 return 710001
      
      set rowcount 0
      
   end
   
   /* CONTROL DE TERMINACION DE PROCESO */
   if not exists(select 1 from ca_universo_venta with (nolock)
   where ub_estado = @w_hijo) begin
     
      update cobis..ba_ctrl_ciclico with (rowlock) set
      ctc_procesar = 'N'
      where ctc_sarta      = @w_sarta
      and   ctc_batch      = @w_batch
      and   ctc_secuencial = @w_hijo
      
      if @@error <> 0 return 710002  

   end
end


/* ESTADOS DE CARTERA */
exec @w_error = sp_estados_cca
@o_est_castigado  = @w_est_castigado out,
@o_est_cancelado  = @w_est_cancelado out,
@o_est_vigente    = @w_est_vigente   out,
@o_est_vencido    = @w_est_vencido   out,
@o_est_novigente  = @w_est_novigente out

if @@error <> 0
begin
   select @w_msg = 'No existen estados de cartera',
          @w_error = 710217
   goto ERROR
end

-- ELIMINA OPERACIONES QUE TENGAN CONDONACIONES EN CURSO
delete cob_cartera..ca_condonacion
from cob_cartera..ca_venta_universo, cob_cartera..ca_operacion
where op_operacion = operacion_interna
and   Estado_Venta = 'I'
and   op_operacion = co_operacion

if @@error <> 0
begin
   select @w_msg   = 'Error al eliminar operaciones en proceso de condonacion - ca_condonacion',
          @w_error = 708155
   goto ERROR
end

-- TABLA TEMPORAL QUE GUARDARA LOS CONCEPTOS CON EL DETALLE DE LA CONDONACION
create table #rubrocondonar1(   
descr          descripcion  not null,
valor          money            null,
porcentaje     float            null,
valcond        money            null,
saldo          money            null,
estado         tinyint,
estado_pro     char(1)               )     

-- GUARDA CADA NUEVO SECUENCIAL GENERADO
create table #aplicar_secuenciales(
banco        cuenta,
secuencial   int,
estado_op    int,
sec_estado   char(1)    
)

while 1 = 1 begin

   set rowcount 1
   select 
         @w_banco       = Numero_Obli_o_Crd,
         @w_operacionca = operacion_interna,
         @w_banca       = Banca,
         @w_pago        = Saldo_deuda_total,
         @w_oficina     = Oficina,
         @w_ano_castigo = convert(int,SUBSTRING(Fecha_Castigo,7,10))
   from ca_venta_universo with (nolock), ca_universo_venta with (nolock)
   where operacion_interna = ub_operacion
   and   ub_estado = @w_hijo
   order by operacion_interna

   if @@rowcount = 0 begin
      set rowcount 0  
      break
   end

   set rowcount 0  

   update ca_universo_venta set   --with (rowlock) se retira para evitar lecturas sucias
   ub_estado   = 'P'
   where ub_operacion  = @w_operacionca
   and   ub_estado     = @w_hijo
   
   if @@rowcount = 0 return 0  -- tenemos dos proceso con el mismo hijo. 
   
   -- INICIA VARIABLES
   select @w_secuencial      = null,
          @w_secuencial_ven  = 0,
          @w_secuencial_vig  = 0,
          @w_secuencial_nvig = 0
        
   
   --INSERCION DE RUBROS VIGENTES
   insert into #rubrocondonar1
   select am_concepto,
   isnull(sum(am_acumulado + am_gracia - am_pagado), 0),
   0, 
   0,
   isnull(sum(am_acumulado + am_gracia - am_pagado), 0),
   @w_est_vigente,
   'I'
   from ca_dividendo with (nolock), ca_amortizacion with (nolock)
   where di_operacion = @w_operacionca
   and   di_estado    = @w_est_vigente
   and   am_operacion = di_operacion
   and   am_dividendo = di_dividendo           
   group by am_concepto
   
   --INSERCION DE RUBROS VENCIDOS
   insert into #rubrocondonar1
   select am_concepto,
   isnull(sum(am_cuota + am_gracia - am_pagado), 0),
   0, 
   0,
   isnull(sum(am_cuota + am_gracia - am_pagado), 0),
   @w_est_vencido,
   'I'
   from ca_dividendo with (nolock), ca_amortizacion with (nolock)
   where di_operacion = @w_operacionca
   and   di_estado    = @w_est_vencido
   and   am_operacion = di_operacion
   and   am_dividendo = di_dividendo           
   group by am_concepto   
      
   --INSERCION DE RUBROS NO VIGENTES
   insert into #rubrocondonar1
   select am_concepto,
   isnull(sum(am_cuota + am_gracia - am_pagado), 0),
   0, 
   0,
   isnull(sum(am_cuota + am_gracia - am_pagado), 0),
   @w_est_novigente,
   'I'
   from ca_dividendo with (nolock), ca_amortizacion with (nolock)
   where di_operacion = @w_operacionca
   and   di_estado    = @w_est_novigente
   and   am_operacion = di_operacion
   and   am_dividendo = di_dividendo           
   group by am_concepto   

   select 'pc_porcentaje' = pc_porcentaje_max,
          'pc_rubro'      = pc_rubro,
          'pc_vigentes'   = pc_valores_vigentes         
   into   #porcondona2
   from   ca_param_condona with (nolock), ca_rol_condona with (nolock)
   where  pc_codigo      = rc_condonacion
   and    pc_banca       = @w_banca
   and    pc_ano_castigo = @w_ano_castigo 
   and    rc_rol         = @w_rol
   
   update #rubrocondonar1
   set    porcentaje = pc_porcentaje
   from   #rubrocondonar1, #porcondona2
   where  descr = pc_rubro
   and    valor > 0
   
   update #rubrocondonar1
   set    valcond = (valor * porcentaje) / 100          
   from   #rubrocondonar1
   where  porcentaje <> 0
   
   update #rubrocondonar1
   set    saldo   = valor - valcond
   from   #rubrocondonar1
   where  porcentaje <> 0 and valcond > 0
   

   
   while 1 = 1                            --  CREA ABONO Y DETALLE GENERANDO SECUENCIAL DE INGRESO
   begin

      set rowcount 1
      select 
         @w_concepto   = descr,
         @w_porcentaje = porcentaje,
         @w_valor      = valor,
         @w_estado     = estado
      from #rubrocondonar1
      where estado_pro = 'I'
	  and   valor      > 0
      order by estado desc

      if @@rowcount = 0 break
   
      set rowcount 0            
            
      if @w_secuencial is not null
      begin
         select @w_crea_pago      = 'N',
                @w_secuencial_ing = @w_secuencial
      end
      else
      begin
         select @w_crea_pago      = 'S',
                @w_secuencial_ing = null                
      end
            
      exec @w_error = sp_condonaciones
      @s_user            = 'Operador',
      @s_term            = 'Term',   
      @s_ofi             = @w_oficina,
      @s_date            = @w_fecha_proceso,
      @i_fecha_proceso   = @w_fecha_proceso,
      @i_operacion       = 'I',
      @i_secuencial      = @w_secuencial_ing,
      @i_crea_pago       = @w_crea_pago,
      @i_banco           = @w_banco,
      @i_porcentaje      = @w_porcentaje,
      @i_valor           = @w_valor,
      @i_concepto        = @w_concepto,
      @i_estado_concepto = @w_estado,
      @o_secuencial      = @w_secuencial out
   
      if @@error <> 0      
      begin
         select @w_msg = 'No se pudo ejecutar sp_condonaciones con operacion I desde sp_venta_pago '+ cast(@w_error as varchar),
                @w_error = @w_error
         goto ERROR
      end            
            
      if not exists(select 1 from #aplicar_secuenciales 
                             where banco = @w_banco and secuencial = @w_secuencial and estado_op = @w_estado)
      begin
      
         insert into #aplicar_secuenciales values (@w_banco,@w_secuencial,@w_estado,'I')
         
         if @@error <> 0
         begin
            select @w_msg = 'Error al insertar secuenciales #aplicar_secuenciales',
                   @w_error = 708154
            goto ERROR
         end             

         if @w_estado = 2
            select @w_secuencial_ven = @w_secuencial  
         else if @w_estado = 1
            select @w_secuencial_vig = @w_secuencial  
         else if @w_estado = 0
            select @w_secuencial_nvig = @w_secuencial  
            
       end
                        
      update #rubrocondonar1 set      
      estado_pro       = 'P'      
      where descr      = @w_concepto
      and   estado     = @w_estado
      and   estado_pro = 'I'   
   
      if @@error <> 0
      begin
         select @w_msg = 'Error al actualizar #rubrocondonar1 para estado procesado',
                @w_error = 708152
         goto ERROR
      end

   end  -- FIN CREA ABONO Y DETALLE GENERANDO SECUENCIAL DE INGRESO
       
   while 1 = 1
   begin
      
      set rowcount 1
      
      select @w_sec_generado = secuencial
      from   #aplicar_secuenciales
      where  sec_estado = 'I'
      order by estado_op desc
      
      if @@rowcount = 0 break
      
      set rowcount 0

      exec @w_error = sp_condonaciones
           @s_user            = 'Operador',
           @s_term            = 'Term',            
           @s_date            = @w_fecha_proceso,
           @s_ofi             = @w_oficina,
           @s_ssn             = 1,
           @s_sesn            = 1,
           @s_srv             = 'Prod',                    
           @s_rol             = @w_rol,
           @i_operacion       = 'A',
           @i_fecha_proceso   = @w_fecha_proceso,
           @i_banco           = @w_banco,
           @i_secuencial      = @w_sec_generado   
       
      if @@error <> 0
      begin
         select @w_msg = 'No se pudo ejecutar sp_condonaciones con operacion A desde sp_venta_pago '+cast(@w_error as varchar),
                @w_error = @w_error
         goto ERROR
      end  
      
      update #aplicar_secuenciales set
      sec_estado = 'P'
      where secuencial = @w_sec_generado
      and   sec_estado = 'I'      

      if @@error <> 0
      begin
         select @w_msg = 'No se pudo actualizar #aplicar_secuenciales',
                @w_error = 708152
         goto ERROR
      end  
      
   end         
   
   update ca_venta_universo set      
   Estado_Venta        = 'P',
   Fecha_Venta         = @w_fecha_proceso,
   Secuencial_Ing_Ven  = @w_secuencial_ven,
   Secuencial_Ing_Vig  = @w_secuencial_vig,
   Secuencial_Ing_Nvig = @w_secuencial_nvig
   where Numero_Obli_o_Crd = @w_banco
   and   Estado_Venta = 'I'   
   
   if @@error <> 0
   begin
      select @w_msg = 'Error al actualizar archivo procesado en ca_venta_universo',
             @w_error = 708152
      goto ERROR
   end

   delete cob_cartera..ca_datos_condonaciones
   from cob_cartera..ca_venta_universo, cob_cartera..ca_datos_condonaciones, cob_cartera..ca_operacion
   where con_operacion = operacion_interna
   and  (con_fecha_div_mas_vencido is null or con_fecha_pag is null)
   and  con_saldo_cap_antes_cond = 0
   and  con_tot_CONDONAR         = 0
   and  op_operacion = con_operacion
   and  con_operacion = @w_operacionca

   if @@error <> 0
   begin
      select @w_msg = 'Error al Eliminar en ca_datos_condonaciones',
             @w_error = 708155
      goto ERROR
   end
   
   delete #rubrocondonar1
   delete #aplicar_secuenciales
   drop table #porcondona2

   select @w_est_op = op_estado,
          @w_tipo   = op_tipo
   from ca_operacion
   where op_operacion = @w_operacionca
   
   if @w_est_op <> 3
   begin
      select @w_saldo_final = 0
      select @w_saldo_final = sum(am_acumulado - am_pagado)
      from ca_amortizacion
      where am_operacion = @w_operacionca
      
      if @w_saldo_final =  0
      begin
         update  ca_amortizacion
         set am_estado = 3,
             am_pagado = am_acumulado
         where am_operacion = @w_operacionca
         and am_estado <> 3
         
         update  ca_dividendo
         set di_estado = 3
         where di_operacion = @w_operacionca
         and di_estado <> 3
         
         update ca_operacion
         set op_estado = 3
         where op_operacion = @w_operacionca

         ---ESTA PARTE LA HACE EL Aabono.sp SOO SI LA OPERACIN ESTA EN 3
         insert into ca_activas_canceladas  with (rowlock)
         (can_operacion,   can_fecha_can,   can_usuario,  can_tipo,   can_fecha_hora)
        values(@w_operacionca,  @w_fecha_proceso, 'venta',  @w_tipo,    getdate() )
                        
                  
      end
      
   end
   
end -- end wihle

if @w_opcion = 'B' begin -- Validacion para marcacion de todos los hilos como finalizados   

   update cobis..ba_ctrl_ciclico with (rowlock) set
   ctc_estado = 'F'
   where ctc_sarta      = @w_sarta
   and   ctc_batch      = @w_batch
   and   ctc_secuencial = @w_hijo
      
   if @@error <> 0 return 710002  
end

set rowcount 0

return 0

ERROR:

exec cob_cartera..sp_errorlog 
@i_fecha       = @w_fecha_proceso,
@i_error       = @w_error, 
@i_usuario     = 'OPERADOR', 
@i_tran        = null,
@i_tran_name   = @w_sp_name,
@i_cuenta      = '',
@i_rollback    = 'N',
@i_descripcion = @w_msg
print @w_msg

return @w_error
go