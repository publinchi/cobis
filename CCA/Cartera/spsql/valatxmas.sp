/************************************************************************/
/*   Archivo:              valatxmas.sp                                 */
/*   Stored procedure:     sp_valor_atx_mas                             */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Sandra De La Cruz/Jonnatan Peña              */
/*   Fecha de escritura:   Jun. 2009                                    */
/************************************************************************/
/*                             IMPORTANTE                               */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   "MACOSA".                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/*                             PROPOSITO                                */
/*   Generación masiva y por operación de los valores para el Atx       */
/************************************************************************/  
/*                              MODIFICACIONES                          */
/*      FECHA             AUTOR             RAZON                       */
/*      23/01/2020        Luis Ponce        Deja en 0 saldo Op.Cancelada*/
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_valor_atx_mas')
   drop proc sp_valor_atx_mas
go

----INC. 61540 MAy.16.2012

create proc sp_valor_atx_mas
   @s_user                login        = null,
   @s_term                varchar(30)  = null,
   @s_date                datetime     = null,
   @s_sesn                int          = null,
   @s_ofi                 smallint     = null,
   @t_debug               char(1)      = 'N',
   @t_file                varchar(20)  = null,
   @i_banco               varchar(24)  = null
   
    
as declare
   @w_return              int,   
   @w_est_vigente         tinyint,
   @w_est_novigente       tinyint,
   @w_est_vencido         tinyint,
   @w_est_castigado       tinyint,
   @w_est_cancelado       tinyint,
   @w_est_suspenso        tinyint,
   @w_debug               char(1),
   @w_iniciar_replica     char(1),
   @w_error               int,
   @w_fecha_hoy           datetime,
   @w_estado_op           smallint

   
--INICIALIZACION DE VARIABLES
select 
@w_est_vigente     = 1,
@w_est_novigente   = 0,
@w_est_vencido     = 2,
@w_est_cancelado   = 3,
@w_est_castigado   = 4,
@w_est_suspenso    = 9,
@w_debug           = 'N',
@w_iniciar_replica = 'N'



--CREACION ESTRUCTURA TABLA TEMPORAL TEMPORAL
select 
*,
vx_operacion         = convert(int,0),
vx_cliente           = convert(int,0),
vx_fecha_ult_proceso = convert(datetime, '01/01/1900')
into #ca_valor_axt_masiva
from ca_valor_atx
where 1 = 2

        
--LECTURA DATOS DE LA OPERACION
if @i_banco is not null  begin

   select @w_fecha_hoy = fc_fecha_cierre
   from cobis..ba_fecha_cierre
   where fc_producto = 7
   
   insert into #ca_valor_axt_masiva
   select 
   vx_oficina           = op_oficina,
   vx_banco             = op_banco,
   vx_ced_ruc           = '',
   vx_nombre            = op_nombre,
   vx_monto             = 0,
   vx_monto_max         = 0,
   vx_moneda            = op_moneda,
   vx_valor_vencido     = 0,
   vx_migrada           = isnull(op_migrada,op_banco),
   vx_estado_cobranza   = op_estado_cobranza,
   vx_monto_total       = op_monto,
   vx_cuotas            = op_plazo,
   vx_ven_vigente       = null,
   vx_dias_mora         = 0,
   vx_cuotas_ven        = 0,
   vx_estado            = op_estado,
   vx_nota              = 0,
   vx_operacion         = op_operacion,
   vx_cliente           = op_cliente,
   vx_fecha_ult_proceso = op_fecha_ult_proceso
   from ca_operacion
   where op_banco      = @i_banco
   and  ((op_estado in (@w_est_vigente, @w_est_vencido, @w_est_castigado, @w_est_suspenso)) or (op_estado = @w_est_cancelado and op_fecha_ult_proceso = @w_fecha_hoy))
   and   op_naturaleza = 'A' 
   
   if @@rowcount = 0 begin
   
      delete ca_valor_atx
      where vx_banco = @i_banco 
   
      if @@error <> 0  begin
         select @w_error = 710003
         goto ERROR
      end
      
      return 0  -- la operacion no debe estar reportada en cajas.
      
   end
   
   select @w_estado_op = op_estado
   from ca_operacion
   where op_banco = @i_banco
   ---No vuelve a cargar
   if @w_estado_op = @w_est_cancelado
   BEGIN
      if @i_banco is not null  begin  
         
         delete ca_valor_atx         --LPO TEC Se elimina para que no muestre valor en Saldo a la Fecha, en pantalla, despues de cancelar una operación
         where vx_banco = @i_banco
            
         if @@error <> 0  begin
            select @w_error = 710003  
            goto ERROR   
         end   
      end
      return 0     
   END
end else begin
   
   insert into #ca_valor_axt_masiva
   select 
   vx_oficina           = op_oficina,
   vx_banco             = op_banco,
   vx_ced_ruc           = '',
   vx_nombre            = op_nombre,
   vx_monto             = 0,
   vx_monto_max         = 0,
   vx_moneda            = op_moneda,
   vx_valor_vencido     = 0,
   vx_migrada           = isnull(op_migrada,op_banco),
   vx_estado_cobranza   = op_estado_cobranza,
   vx_monto_total       = op_monto,
   vx_cuotas            = op_plazo,
   vx_ven_vigente       = null,
   vx_dias_mora         = 0,
   vx_cuotas_ven        = 0,
   vx_estado            = op_estado,
   vx_nota              = 0,
   vx_operacion         = op_operacion,
   vx_cliente           = op_cliente,
   vx_fecha_ult_proceso = op_fecha_ult_proceso
   from ca_operacion
   where op_estado in (@w_est_vigente, @w_est_vencido, @w_est_castigado, @w_est_suspenso) 
   and   op_naturaleza = 'A' 
   
   if @@error <> 0  begin
      select @w_error = 710001
      goto ERROR
   end

   
end

   
--OBTENCION DE DATOS PARA ACTUALIZAR LA TABLA TEMPORAL
update #ca_valor_axt_masiva set
vx_ced_ruc = en_ced_ruc
from  cobis..cl_ente
where en_ente  = vx_cliente

if @@error <> 0  begin
   select @w_error = 710002  
   goto ERROR   
end 

select 
operacion     = vx_operacion,
monto         = sum(case when di_estado in(@w_est_vencido,@w_est_vigente ) then  am_cuota - am_pagado + am_gracia else 0 end),
monto_max     = sum(am_acumulado - am_pagado + am_gracia),
valor_vencido = sum(case when di_estado in(@w_est_vencido) then  am_cuota - am_pagado + am_gracia else 0 end),
cuotas        = max(di_dividendo)
into #saldos
from #ca_valor_axt_masiva, ca_dividendo, ca_amortizacion
where vx_operacion = di_operacion
and   vx_operacion = am_operacion
and   di_dividendo = am_dividendo
--and   di_estado   <> @w_est_cancelado REQ 340: COMENTADO POR CONSULTA POR DATAFONO DE OBLIGACION CANCELADA ANTES DE BATCH
--and   am_estado   <> @w_est_cancelado REQ 340: COMENTADO POR CONSULTA POR DATAFONO DE OBLIGACION CANCELADA ANTES DE BATCH
group by vx_operacion

if @@error <> 0  begin
   select @w_error = 710001  
   goto ERROR   
end 


update #ca_valor_axt_masiva set
vx_monto         =  monto,          
vx_monto_max     =  monto_max,      
vx_valor_vencido =  valor_vencido,
vx_cuotas        =  cuotas 
from #saldos
where vx_operacion = operacion

if @@error <> 0  begin
   select @w_error = 710002  
   goto ERROR   
end 


/* Fecha Vencimiento del dividendo vigente */
select operacion = vx_operacion, ven_vigente = max(di_fecha_ven)
into  #vige_div
from  ca_dividendo , #ca_valor_axt_masiva
where di_operacion = vx_operacion
group by vx_operacion

if @@rowcount = 0  begin
   select @w_error = 710002  
   goto ERROR   
end 

update #ca_valor_axt_masiva set
vx_ven_vigente = ven_vigente
from #vige_div
where vx_operacion = operacion

if @@error <> 0  begin
   select @w_error = 710002  
   goto ERROR   
end 

select operacion = vx_operacion, ven_vigente = min(di_fecha_ven)
into  #vige_div1
from  ca_dividendo, #ca_valor_axt_masiva
where di_operacion = vx_operacion
and   di_fecha_ven >= vx_fecha_ult_proceso
group by vx_operacion

if @@error <> 0  begin
   select @w_error = 710002  
   goto ERROR   
end 

update #ca_valor_axt_masiva set
vx_ven_vigente = ven_vigente
from  #vige_div1
where vx_operacion = operacion

if @@error <> 0  begin
   select @w_error = 710002  
   goto ERROR   
end 

/* Cuotas Vencidas */
select 
operacion  = vx_operacion,
vencidos   = count(di_dividendo),
dias_mora  = max(datediff(dd,di_fecha_ven, vx_fecha_ult_proceso))
into  #vencidos
from  ca_dividendo, #ca_valor_axt_masiva 
where di_operacion = vx_operacion
and   di_estado    = @w_est_vencido
group by vx_operacion

if @@error <> 0  begin
   select @w_error = 710001  
   goto ERROR   
end 

update #ca_valor_axt_masiva set
vx_cuotas_ven = vencidos,
vx_dias_mora  = dias_mora
from  #vencidos
where vx_operacion = operacion

if @@error <> 0  begin
   select @w_error = 710002  
   goto ERROR   
end 


/* Nota */
update  #ca_valor_axt_masiva set  
vx_nota = ci_nota                                   
from  cob_credito..cr_califica_int_mod
where ci_banco = vx_banco

if @@error <> 0  begin
   select @w_error = 710002  
   goto ERROR   
end 



/* PASO DE INFORMACION A TABLAS DEFINITIVAS */

if @i_banco is not null  begin  

   delete ca_valor_atx
   where vx_banco = @i_banco 
   
   if @@error <> 0  begin
      select @w_error = 710003  
      goto ERROR   
   end 
   
end else begin  

   exec master..borra_replica

   select @w_iniciar_replica = 'S'
   
   truncate table ca_valor_atx 
   
   
   if @@error <> 0  begin
      select @w_error = 710003  
      goto ERROR   
   end 
   
                     
end

-- Insertar en la tabla ca_valor_atx
insert into ca_valor_atx
select 
vx_oficina,          vx_banco,           vx_ced_ruc,   
vx_nombre,           vx_monto,           vx_monto_max,
vx_moneda,           vx_valor_vencido,   vx_migrada,
vx_estado_cobranza,  vx_monto_total,     vx_cuotas,
vx_ven_vigente,      vx_dias_mora,       vx_cuotas_ven,
vx_estado,           vx_nota
from #ca_valor_axt_masiva
   
if @@error <> 0 begin
   select @w_error = 710001
   goto ERROR
end

/* Reiniciar el esquema de Replica */
if @w_iniciar_replica = 'S' begin
   exec master..inicia_replica
   select @w_iniciar_replica = 'N'
end
   
return 0

ERROR:

if @w_iniciar_replica = 'S' begin
   exec master..inicia_replica
   select @w_iniciar_replica = 'N'
end

return @w_error

go
