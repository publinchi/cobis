/************************************************************************/
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Elcira Pelaez                           */
/*      Fecha de escritura:     Febrero 2004                            */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA"                                                        */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/*                              PROPOSITO                               */
/*      Retorna el valor  base para el calculo de seguros segun el      */
/*      porcentaje que le coresponda despues del prorrateo con las      */
/*      operaciones                                                     */
/*      PARA OBLIGACIONES EN UVR se Busca la cotizacion de la fecha     */
/*      EN QUE SE DESEMBOLSO                                            */
/************************************************************************/
/*                              CAMBIOS                                 */
/*      FECHA                   AUTOR           CAMBIO                  */
/*     DIC-11-2006             Elcira Pelaez    DEF-7583                */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_prorrateo_seguros')
   drop proc sp_prorrateo_seguros
go

create proc sp_prorrateo_seguros (
   @i_tramite            int,
   @i_operacion          int,
   @i_tipo_garantia      varchar(10),
   @i_garantia_vehicular varchar(64) = null,
   @i_item               tinyint     = 0,
   @i_cotizacion         float  = 1,
   @o_base_calculo_seg   float  = 0  out     
)
as
declare
   @w_tramite     int,
   @w_garantia    varchar(64),
   @w_mensaje     varchar(64),
   @w_valor_gar   float,
   @w_valor       float,
   @w_valor_res   float,
   @w_valor_op    float,
   @w_valor_tot   float,
   @w_operacion   int,
   @w_op_moneda   int,
   @w_estado_op   int,
   @w_op_fecha    datetime,
   @w_cotizacion  float,
   @w_op_fecha_ult_proceso datetime


select @w_valor_op  = 0
select @w_valor_tot = 0
select @w_valor_gar = 0
select @w_valor_res = 0
select @w_valor     = 0

if @i_item > 0 ---FUE LLAMADO PARA  SEGURO DE VIVIENDA
begin
    declare cur_tra_gar cursor
        for select  ic_codigo_externo,
                    convert(money,isnull(ic_valor_item,'0'))
            from cob_custodia..cu_item_custodia,
                 cob_custodia..cu_tipo_custodia,
                 cob_credito..cr_gar_propuesta g
            where  ic_item     = @i_item    
            and ic_tipo_cust   =  tc_tipo
            and tc_tipo_superior = @i_tipo_garantia --tiposuperior de hipotecarias
            and gp_garantia    = ic_codigo_externo 
            and gp_tramite     = @i_tramite 
            and gp_est_garantia  <> 'C'
            and ic_secuencial = (select max(ic_secuencial)
                                 from   cob_custodia..cu_item_custodia,
                                        cob_custodia..cu_tipo_custodia
                                 where  ic_item           = @i_item   
                                 and    ic_tipo_cust      =  tc_tipo
                                 and    tc_tipo_superior  = @i_tipo_garantia
                                 and    ic_codigo_externo = g.gp_garantia )   
            for read only         
end
ELSE --FUE LLAMADO PARA GARANTIAS  VEHICULARES O MAQUINARIA 
begin  
   if @i_garantia_vehicular is null
   begin
      declare cur_tra_gar cursor
          for select gp_garantia, 
                     cu_valor_inicial
              from   cob_credito..cr_gar_propuesta,
                     cob_custodia..cu_custodia
              where  gp_tramite  = @i_tramite
              and    gp_garantia = cu_codigo_externo 
              and    cu_tipo     = @i_tipo_garantia
              and    cu_estado   in ('V', 'X', 'F')
              and    cu_clase_custodia <> 'O' --- Otras garantias  I Idoneas
              for read only
   end
   ELSE --PARA GARANTIAS VEHUCILAR SEHACE UNA POR UNA POR QUE CADA UNA DE ESTAS MANEJA DIFERENTE CLASE DE VEHICULO
   begin
      declare cur_tra_gar cursor
          for select gp_garantia, 
                     cu_valor_inicial
              from   cob_credito..cr_gar_propuesta,
                     cob_custodia..cu_custodia
              where  gp_tramite  = @i_tramite
              and    gp_garantia = cu_codigo_externo
              and    cu_codigo_externo =   @i_garantia_vehicular
              and    cu_tipo     = @i_tipo_garantia
              and    cu_estado    in ('V','X','F')
              and    cu_clase_custodia <> 'O' --- Otras 
              for read only
   end
end

open cur_tra_gar

fetch cur_tra_gar
into  @w_garantia,
      @w_valor_gar

while @@fetch_status = 0
begin
   if @@fetch_status = -1
   begin
      close cur_tra_gar
      deallocate cur_tra_gar
      return 0
   end
   
   ---SI NO HAY VALOR DE GARANTIA  SE RETORNA 0

   declare cur_gar_ope cursor
       for select op_operacion,
                  op_monto,
                  op_moneda,
                  op_fecha_ini
           from   cob_cartera..ca_operacion,
                  cob_credito..cr_gar_propuesta
           where  gp_tramite  = op_tramite
           and    gp_garantia = @w_garantia
           and    op_estado  in (1,2,4,5,9,10)
           and    op_naturaleza = 'A'
           for read only

      open  cur_gar_ope
      
      fetch cur_gar_ope
      into  @w_operacion, 
            @w_valor, 
            @w_op_moneda,
            @w_op_fecha
      
      while @@fetch_status = 0
      begin
         if @@fetch_status = -1
         begin
            close cur_gar_ope
            deallocate cur_gar_ope
            goto SIGUIENTE
         end
         
         if @w_op_moneda != 0
            select @w_valor = round(ct_valor * @w_valor, 0)
            from   cob_conta..cb_cotizacion
            where  ct_moneda  = @w_op_moneda
            and    ct_fecha   = @w_op_fecha
         
         --PRINT 'caprorro.sp Otras operaciones   @w_operacion %1!  @w_valor%2!',@w_operacion,@w_valor
         
         select  @w_valor   = isnull(@w_valor,0)
         select  @w_valor_res   = @w_valor_res + @w_valor
         
         select  @w_valor     = 0
         
         fetch cur_gar_ope
         into  @w_operacion, 
               @w_valor, 
               @w_op_moneda,
               @w_op_fecha
      end   ---CURSOR RUBROS
         
      close cur_gar_ope
      deallocate cur_gar_ope
      
      --DTOS DE LA OPERACION QUE SE ESTA LIQUIDANDO o REGENERANDO EL SEGURO SI ESTA EN TRAMITE AUN
      select  @w_valor_op    = op_monto,
              @w_op_moneda   = op_moneda,
              @w_op_fecha    = op_fecha_ini,
              @w_estado_op   = op_estado
      from    cob_cartera..ca_operacion 
      where   op_operacion =  @i_operacion
      
      
      if @w_op_moneda != 0
      select @w_valor_op = round(ct_valor * @w_valor_op, 0)
      from   cob_conta..cb_cotizacion
      where  ct_moneda  = @w_op_moneda
      and    ct_fecha   = @w_op_fecha
   
      
      select  @w_valor_op   = isnull(@w_valor_op,0)
      
   
      --PRINT 'prorra.sp estado  @i_operacion %1!  estado %2! ',@i_operacion,@w_estado_op,@w_estado_op
            
      --SE CUMA AL VALOR DE TODAS LAS OBLIGACIONES EL VALOR DE LA OBLIGACION QUE SE ESTA PROCESANDO
      --ESTE VALOR NO SALE EN EL CURSOS POR QUE LA OPERACION NOESTA AUN DESEMBOLSADA
   
      if    @w_estado_op in (0,99)
            select @w_valor_res = @w_valor_res + @w_valor_op
      
   
      ---PRINT 'prorra.sp @w_valor_res %1! @w_valor_op %2! @w_valor_gar %3!',@w_valor_res,@w_valor_op,@w_valor_gar
      
      select  @w_valor_tot = @w_valor_tot + ((@w_valor_op*@w_valor_gar)/@w_valor_res)
      
      ---PRINT 'prorra.sp  @w_valor_tot %1!',@w_valor_tot
      
      
      select @w_valor_op  = 0
      select @w_valor_gar = 0
      select @w_valor_res = 0
         
   SIGUIENTE:

   fetch cur_tra_gar
   into  @w_garantia, 
         @w_valor_gar

end   --CURSOR GENERAL

close cur_tra_gar
deallocate cur_tra_gar


---PRINT 'caprorra.sp DESPUES DEL CURSOR @w_valor_tot %1!',@w_valor_tot


--DEVOLVER EL VALOR EN LA MONEDA DE LA OPERACION QUE SE ESTA PROCESANDO
select  @w_op_moneda            = op_moneda,
        @w_op_fecha             = op_fecha_ini,
        @w_op_fecha_ult_proceso = op_fecha_ult_proceso,
        @w_estado_op            = op_estado
from    cob_cartera..ca_operacion 
where   op_operacion =  @i_operacion

if @w_op_moneda = 0
   select @w_cotizacion = 1.0
else
begin
   if @w_estado_op = 0
      exec sp_buscar_cotizacion
           @i_moneda     = @w_op_moneda,
           @i_fecha      = @w_op_fecha,
           @o_cotizacion = @w_cotizacion output
   else
      exec sp_buscar_cotizacion
      @i_moneda     = @w_op_moneda,
      @i_fecha      = @w_op_fecha_ult_proceso,
      @o_cotizacion = @w_cotizacion output
        
end

--- EL REDONDEO SE HACE EN EL rubrocal.sp 
select @w_valor_tot = @w_valor_tot / @w_cotizacion

select @o_base_calculo_seg = @w_valor_tot 


return 0
go
