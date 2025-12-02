/************************************************************************/
/*      Archivo              :   prorroga.sp                            */
/*      Stored procedure     :   sp_prorroga_cuota                      */
/*      Base de datos        :   cob_cartera                            */
/*      Producto             :   Cartera                                */
/*      Disenado por         :   Xavier Maldonado                       */
/*      Fecha de escritura   :   Febrero 2001                           */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA"                                                        */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Ingreso, Actualizacion,Eliminaci¢n(Reversa), Fecha valor para   */
/*      cuotas prorrogadas.                                             */
/************************************************************************/
/*                              ACTUALIZACIONES                         */
/*   FECHA        AUTOR           CAMBIO                                */
/*   Mayo-2006    Elcira Pelaez   def. 6603 BAC                         */
/*   22-Ago-2019  Sandro Vallejo  Prorroga Grupal e Interciclos         */
/*   26-Ago-2019  Luis Ponce      Ajustes Prorroga Grupal e Interciclos */
/************************************************************************/

use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_prorroga_cuota')
   drop proc sp_prorroga_cuota
go

create proc sp_prorroga_cuota
@s_sesn                 int          = NULL,
@s_user                 login        = NULL,
@s_term                 varchar (30) = NULL,
@s_date                 datetime     = NULL,
@s_ofi                  smallint     = NULL,
@s_ssn                  int          = null,
@s_srv                  varchar (30) = null,
@s_lsrv                 varchar (30) = null,
@s_org                  char(1)      = null,
@t_trn                  int          = null,
@i_operacion            char(1)      = null,
@i_modo                 char(1)      = null,
@i_banco                cuenta       = null,
@i_fecha                datetime     = null,
@i_formato_fecha        smallint     = null,
@i_cuota                smallint     = null,
@i_valor_calculado      money        = null,
@i_fecha_vencimiento    datetime     = null,
@i_fecha_max_prorroga   datetime     = null,
@i_fecha_prorroga       datetime     = null,
@i_concepto             char(3)      = null,
@i_valor                money        = null,
@i_estado_div           varchar(30)  = null,
@i_externo              char(1)      = 'S', --LPO TEC Prorroga Grupal
@o_secuencial_prorroga  int          = null out,  --LPO TEC Prorroga Grupal
@o_secuencial_tran      int          = null out  --LPO TEC Prorroga Grupal
as
declare
@w_sp_name               descripcion,
@w_return                int,
@w_error                 int,
@w_banco                 cuenta,
@w_operacionca           int,
@w_monto_mop             money,
@w_moneda_op             smallint,
@w_moneda_mn             smallint,
@w_tipo                  char(1),
@w_tipo_cobro            char(1),
@w_tipo_aplicacion       char(1),
@w_tipo_reduccion        char(1),
@w_toperacion            catalogo,
@w_monto_sobrante        money,
@w_dias_anio             smallint,
@w_base_calculo          char(1),
@w_aceptar_anticipos     char(1),
@w_fpago                 catalogo,
@w_cuenta                cuenta,
@w_tipo_tabla            catalogo,
@w_cliente               int,
@w_tasa_prepago          float,
@w_fecha_ult_proceso     datetime,
@w_num_dias              int,
@o_valor_cuota           money,
@w_fecha_maxima          datetime,
@w_pago_cap              money,
@w_intant                catalogo,
@w_interes               catalogo,
@w_dividendo_vig         int,
@w_est_cancelado         tinyint,
@w_est_novigente         tinyint,
@w_est_vigente           tinyint,
@w_est_vencido           tinyint,
@w_dividendo_max         smallint,
@w_dividendo_max_ven     smallint,
@w_dividendo             smallint,
@w_dividendo_f           smallint,
@w_di_dividendo          smallint,
@w_fechaini              datetime,
@w_pago_int              money,
@w_pago_otr              money,
@w_pagot                 money,
@w_di_fecha_ven          datetime,
@w_estado                descripcion,
@w_di_estado             tinyint,
@w_op_estado             tinyint,
@w_tipo_grupal           char(1),  --LPO TEC Prorroga Grupal
@w_secuencial_prorroga   int,      --LPO TEC Prorroga Grupal
@w_secuencial_tran       int       --LPO TEC Prorroga Grupal

--- CARGADO DE LOS PARAMETROS DE CARTERA 
select 
@w_sp_name        = 'sp_prorroga_cuota',
@s_term           = isnull(@s_term, 'consola'),
@w_est_cancelado  = 3,
@w_est_novigente  = 0,
@w_est_vigente    = 1,
@w_est_vencido    = 2


--- CODIGO PARA INTERES ANTICIPADO
select @w_intant = pa_char  
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'INTANT'


--- CODIGO PARA INTERES CORRIENTE
select @w_interes = pa_char  
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'INT'



--- DATOS DE CA_OPERACION  
select 
@w_tipo_cobro        = op_tipo_cobro,
@w_operacionca       = op_operacion,
@w_fecha_maxima      = op_fecha_fin,
@w_fecha_ult_proceso = op_fecha_ult_proceso,
@w_op_estado         = op_estado
from ca_operacion 
where op_banco = @i_banco

if @@rowcount = 0
begin   
   select @w_error =  701025
   goto ERROR
end      
   
if @w_op_estado <> 1
begin
   select @w_error =  710526
   goto ERROR
end   

--LPO TEC INICIO Prorroga Grupal
/* DETERMINAR SI LA OPERACION CORRESPONDE A INTERCICLO - GRUPAL - INDIVIDUAL */
exec @w_error = sp_tipo_operacion
@i_banco      = @i_banco,
@o_tipo       = @w_tipo_grupal out

if @w_error <> 0 goto ERROR

/* SI LA OPERACION ES DE INTERCICLO Y ES EXTERNA; GENERAR ERROR */

if @i_externo = 'S' and @w_tipo_grupal = 'I'
begin

   select @w_error = 77537 -- /* OPERACION INTERCICLO NO PUEDE PRORROGARSE SOLA */
   goto ERROR
end   
--LPO TEC FIN Prorroga Grupal
  

if @i_operacion = 'Q'
begin

   delete ca_detalle
   where de_operacion = @w_operacionca
   

   --CALCULAR TIPO DE PERIODICIDAD (Vencida o Anticpada) 

   if exists (select 1 from ca_rubro_op where ro_concepto = @w_intant)
      select @w_fpago     = ro_fpago
      from ca_rubro_op
      where ro_operacion  = @w_operacionca
      and   ro_tipo_rubro = 'I'
      and   ro_concepto   = @w_intant
      group by ro_fpago
   else
      select @w_fpago     = ro_fpago
      from ca_rubro_op
      where ro_operacion  = @w_operacionca
      and   ro_tipo_rubro = 'I'
      and   ro_concepto   = @w_interes
      group by ro_fpago


   --MAXIMO DIVIDENDO
   select @w_dividendo_max = max(di_dividendo)
   from   ca_dividendo
   where  di_operacion = @w_operacionca

   -- BUSCAR DIVIDENDO VIGENTE 
   select @w_dividendo_vig = max(di_dividendo)
   from   ca_dividendo
   where  di_operacion = @w_operacionca
   and    di_estado    = @w_est_vigente


   select @w_dividendo_max_ven = isnull(max(di_dividendo),0)
   from ca_dividendo
   where di_operacion = @w_operacionca
   and   di_estado    = @w_est_vencido 



   if @w_dividendo_max > 1 
   begin

      if @w_dividendo_max = @w_dividendo_vig 
      begin
         select @w_error = 710529
         goto ERROR
      end
      else
      begin
         if @w_dividendo_vig = 1 
         begin
            select @w_dividendo   = @w_dividendo_vig
            select @w_dividendo_f = @w_dividendo_vig + 1
         end
         else 
         begin 
            select @w_dividendo   = @w_dividendo_vig - 1
            select @w_dividendo_f = @w_dividendo_vig + 1
         end
      end


      if @w_dividendo_max = @w_dividendo_max_ven 
      begin
         select @w_error = 710530
         goto ERROR
      end


      declare cursor_dividendo cursor for
      select
      di_dividendo, 
      di_fecha_ini, 
      di_fecha_ven, 
      di_estado
      from   ca_dividendo
      where  di_operacion  =  @w_operacionca
      and    di_dividendo  >=  @w_dividendo
      and    di_dividendo  <=  @w_dividendo_f
      and    di_estado in (@w_est_vigente,@w_est_vencido,@w_est_novigente)
      for read only

      open    cursor_dividendo
      fetch   cursor_dividendo into
      @w_di_dividendo, 
      @w_fechaini, 
      @w_di_fecha_ven, 
      @w_di_estado

      while   @@fetch_status = 0 
      begin 

         if (@@fetch_status = -1) 
         begin
            select @w_error = 708999
            goto ERROR
         end 

         if @w_fpago <> 'A' 
         begin --PARA INTERES NORMAL
            select @w_pago_cap = isnull(sum(am_cuota + am_gracia - am_pagado ),0)
            from ca_amortizacion,ca_rubro_op
            where am_operacion  = ro_operacion
            and   am_operacion  = @w_operacionca
            and   am_concepto   = ro_concepto
            and   am_dividendo  = @w_di_dividendo
            and   ro_tipo_rubro = 'C'

            select @w_pago_int = isnull(sum(am_cuota + am_gracia - am_pagado ),0)
            from ca_amortizacion,ca_rubro_op
            where am_operacion  = ro_operacion
            and   am_operacion  = @w_operacionca
            and   am_concepto   = ro_concepto
            and   am_dividendo  = @w_di_dividendo
            and   am_concepto   = @w_interes
            and   ro_tipo_rubro = 'I'

            select @w_pago_otr = isnull(sum(am_cuota + am_gracia - am_pagado ),0)
            from ca_amortizacion,ca_rubro_op
            where am_operacion  = ro_operacion
            and   am_operacion  = @w_operacionca
            and   am_concepto   = ro_concepto
            and   am_dividendo  = @w_di_dividendo
            and   ro_tipo_rubro not in ('C','I')

            select @w_pagot = isnull(sum(@w_pago_cap + @w_pago_int + @w_pago_otr),0)

         end 
         else 
         begin

            select @w_pago_cap = isnull(sum(am_cuota + am_gracia - am_pagado ),0)
            from ca_amortizacion,ca_rubro_op
            where am_operacion  = ro_operacion
            and   am_operacion  = @w_operacionca
            and   am_concepto   = ro_concepto
            and   am_dividendo  = @w_di_dividendo
            and   ro_tipo_rubro = 'C'

            select @w_pago_int = isnull(sum(am_cuota + am_gracia - am_pagado ),0)
            from ca_amortizacion,ca_rubro_op
            where am_operacion  = ro_operacion
            and   am_operacion  = @w_operacionca
            and   am_concepto   = ro_concepto
            and   am_dividendo  = @w_di_dividendo 
            and   am_concepto   = @w_intant
            and   ro_tipo_rubro = 'I'
            and   ro_fpago      = 'A'

            select @w_pago_otr = isnull(sum(am_cuota + am_gracia - am_pagado ),0)
            from ca_amortizacion,ca_rubro_op
            where am_operacion  = ro_operacion
            and   am_operacion  = @w_operacionca
            and   am_concepto   = ro_concepto
            and   am_dividendo  = @w_di_dividendo
            and   ro_fpago     <> 'A'
            and   ro_tipo_rubro not in ('C','I')

            select @w_pagot = isnull(sum(@w_pago_cap + @w_pago_int + @w_pago_otr),0)
         end

         select @w_estado = es_descripcion
         from ca_estado
         where es_codigo = @w_di_estado



         if @w_pagot > 0
         begin
            insert into ca_detalle (
            de_operacion,
            de_dividendo,   de_fechaini,      de_fecha,
            de_pago_cap,    de_pago_int,      de_pago_otr,
            de_pago,        de_estado,        de_max_pago)
            values(
            @w_operacionca,
            @w_di_dividendo,@w_fechaini,      @w_di_fecha_ven,
            @w_pago_cap,    @w_pago_int,      @w_pago_otr,
            @w_pagot,       @w_estado,        0)
         
           if @@error != 0
           begin
              select @w_error = 708154
              goto ERROR
           end
            
         end
         
       
         fetch   cursor_dividendo into
         @w_di_dividendo, 
         @w_fechaini, 
         @w_di_fecha_ven, 
         @w_di_estado
         
      end

      close cursor_dividendo
      deallocate cursor_dividendo

      select 
      'No. CUOTA'         = de_dividendo,
      'FECHA INICIO'      = convert(varchar(10),de_fechaini,@i_formato_fecha),      
      'FECHA VENCIMIENTO' = convert(varchar(10),de_fecha,@i_formato_fecha), 
      'PAGO CAPITAL'      = convert(money, de_pago_cap),     
      'PAGO INTERES'      = convert(money, de_pago_int),     
      'PAGO OTROS'        = convert(money, de_pago_otr),     
      'PAGO TOTAL'        = convert(money, de_pago),     
      'ESTADO'            = de_estado
      from ca_detalle
      where de_operacion = @w_operacionca
   end 


end


if @i_operacion = 'I'
begin

   select @w_num_dias = datediff(dd,@i_fecha_prorroga,@w_fecha_maxima)

   if @w_num_dias < 0
   begin
      select @w_error =  708217
      goto ERROR
   end   

   select @w_num_dias = datediff(dd,@i_fecha_max_prorroga,@i_fecha_prorroga)
   if @w_num_dias > 0
      begin
         select @w_error = 708217
         goto ERROR
      end    

   select @w_num_dias = datediff(dd,@i_fecha_vencimiento,@i_fecha_prorroga) 
   if @w_num_dias < 0
      begin
          select @w_error = 708218
          goto ERROR
      end            


   select @w_num_dias = datediff(dd,@w_fecha_ult_proceso,@i_fecha_prorroga) 

   if @w_num_dias < 0
      begin
          select @w_error = 708219
          goto ERROR
      end   
    
   
   begin tran 

--LPO TEC INICIO Prorroga Grupal
   /* SI LA OPCION ES DE EJECUCION Y */
   /* SI LA OPERACION ES GRUPAL VERIFICAR LA EJECUCION DE LAS INTECICLOS */  
   if @w_tipo_grupal in ('I','G')  and @i_modo = 'B'
   begin
      /* GENERAR SECUENCIAL DE PRORROGA */
      exec @w_secuencial_prorroga = sp_gen_sec
      @i_operacion                = @w_operacionca      
   end
--LPO TEC FIN Prorroga Grupal

   exec @w_return = sp_prorroga_cuota_ing
        @s_sesn                = @s_sesn,
        @s_user                = @s_user,
        @s_term                = @s_term,
        @s_date                = @s_date,
        @s_ofi                 = @s_ofi,
        @s_ssn                 = @s_ssn,
        @s_srv                 = @s_srv,
        @s_lsrv                = @s_lsrv,
        @s_org                 = @s_org,
        @t_trn                 = @t_trn,        
        @i_operacion           = @i_operacion,
        @i_banco               = @i_banco,
        @i_formato_fecha       = @i_formato_fecha,
        @i_cuota               = @i_cuota,
        @i_valor_calculado     = @i_valor_calculado,
        @i_fecha_vencimiento   = @i_fecha_vencimiento,  
        @i_fecha_max_prorroga  = @i_fecha_max_prorroga,  
        @i_fecha_prorroga      = @i_fecha_prorroga,  
        @i_modo                = @i_modo,
        @o_valor_cuota         = @o_valor_cuota out,
        @o_secuencial_prorroga = @w_secuencial_tran out  --LPO TEC Prorroga Grupal
        
        if @w_return != 0  or  @@error != 0
        begin
           select @w_error = @w_return 
           goto ERROR
        end
        
        select @o_secuencial_prorroga = @w_secuencial_prorroga,
               @o_secuencial_tran     = @w_secuencial_tran
               
        --LPO TEC INICIO Prorroga Grupal
        /* SI LA OPCION ES DE EJECUCION Y */
        /* SI LA OPERACION ES GRUPAL VERIFICAR LA EJECUCION DE LAS INTECICLOS */
        if @w_tipo_grupal = 'G' and @i_modo = 'B'
        begin
           exec @w_return         = sp_prorroga_grupal
           @s_sesn                = @s_sesn,
           @s_user                = @s_user,
           @s_term                = @s_term,
           @s_date                = @s_date,
           @s_ofi                 = @s_ofi,
           @s_ssn                 = @s_ssn,
           @s_srv                 = @s_srv,
           @s_lsrv                = @s_lsrv,
           @s_org                 = @s_org,
           @t_trn                 = @t_trn,        
           @i_operacion           = @i_operacion,
           @i_banco               = @i_banco,
           @i_formato_fecha       = @i_formato_fecha,
           @i_cuota               = @i_cuota,
           @i_valor_calculado     = @i_valor_calculado,
           @i_fecha_vencimiento   = @i_fecha_vencimiento,  
           @i_fecha_max_prorroga  = @i_fecha_max_prorroga,  
           @i_fecha_prorroga      = @i_fecha_prorroga,  
           @i_modo                = @i_modo,
           @i_secuencial_prorroga = @w_secuencial_prorroga,
           @i_secuencial_tran     = @w_secuencial_tran 
           
           if @w_return != 0 
           begin
              select @w_error = @w_return 
              goto ERROR
           end
        end
        --LPO TEC FIN Prorroga Grupal
    
    commit tran  
 
end


if @i_operacion in ('R','A')
begin
   
   exec  @w_return      = sp_act_amortiza
   @s_sesn               = @s_sesn,
   @s_user               = @s_user,
   @s_term               = @s_term,
   @s_date               = @s_date,
   @s_ofi               = @s_ofi,
   @s_ssn               = @s_ssn,
   @s_srv               = @s_srv,
   @s_lsrv              = @s_lsrv,
   @t_trn               = @t_trn,
   @i_operacion         = @i_operacion,
   @i_dividendo         = @i_cuota,
   @i_concepto          = @i_concepto,
   @i_valor             = @i_valor,
   @i_banco             = @i_banco,
   @i_estado_div        = @i_estado_div,
   @i_formato_fecha     = @i_formato_fecha 

   if @w_return != 0 or  @@error != 0
   begin
      select @w_error =  @w_return 
      goto ERROR
   end
   
end

if not exists (select 1 from ca_dividendo
                  where di_operacion = @w_operacionca
                  and   di_estado in (1,2,3) 
               )
 begin
   select @w_error = 710577
   goto ERROR
 end

return 0

ERROR:

while @@trancount > 0 rollback ---- DESHACE TODA LA TRANSACCION (INCLUSO SI COMENZO EXTERNA)

exec cobis..sp_cerror
      @t_debug = 'N',
      @t_file  = null,
      @t_from  = @w_sp_name,
      @i_num   = @w_error
return @w_error    
go


