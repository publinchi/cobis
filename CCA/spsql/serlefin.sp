/************************************************************************/
/*   Archivo:                 serlefin.sp                               */
/*   Stored procedure:        sp_obligacion_serlefin                    */ 
/*   Base de Datos:           cob_cartera                               */ 
/*   Producto:                Cartera                                   */ 
/*   Disenado por:            Luis Alfonso Mayorga                      */
/*   Fecha de Documentacion:  Agosto 2004                               */
/************************************************************************/
/*         IMPORTANTE                                                   */
/*   Este programa es parte de los paquetes bancarios propiedad de      */    
/*   "MACOSA".                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier autorizacion o agregado hecho por alguno de sus          */
/*   usuario sin el debido consentimiento por escrito de la             */
/*   Presidencia Ejecutiva de MACOSA o su representante                 */
/************************************************************************/  
/*                         PROPOSITO                                    */
/*   Generar la informacion necesaria de obligaciones para SERLEFIN     */
/************************************************************************/  
/*                         MODIFICACIONES                               */
/*  FECHA            AUTOR             RAZON                            */
/*  ene-20-2005      Elcira Pelaez     Actaulizaciones para el BAC      */
/*                                     ULT-ACT:20ENE2005 05:pm          */
/*  feb-27-1006      Ivan Jimenez      REQ 434                          */
/************************************************************************/

use cob_cartera
go 

set ansi_nulls off
go

if exists(select 1 from cob_cartera..sysobjects where name = 'sp_obligacion_serlefin')
   drop proc sp_obligacion_serlefin
go

create proc sp_obligacion_serlefin(
@i_dias_inicial               int,
@i_dias_final                 int
)
as declare 
@w_concepto_cap               varchar(30),
@w_os_operacion               int,
@w_os_banco                   cuenta,
@w_os_cliente                 int,
@w_nro_cliente                int,
@w_os_nombre                  varchar(64),
@w_nombre_codeudor            varchar(64),
@w_os_identificacion          numero,
@w_cedula_codeudor            numero,
@w_os_oficina                 smallint,
@w_os_reestructurado          char(1),
@w_os_fecha_ult_proceso       datetime,
@w_os_direccion               tinyint,
@w_dir_codeudor               varchar(254),
@w_os_tdividendo              char(1),
@w_os_tramite                 int,
@w_identificacion             numero,
@w_saldo_capital              money,
@w_fecha_mora_desde           datetime,
@w_dias_vencidos_op           int,
@w_modalidad_cobro            varchar(1),
@w_modalidad_cobro_int        varchar(2),
@w_fecha_prox_vencimiento     datetime,
@w_tipo_deudor                catalogo,
@w_telefono                   varchar(16),
@w_tel_codeudor               varchar(16),
@w_os_nom_direccion           varchar(254),
@w_ciudad                     varchar(64),
@w_nombre_oficina             varchar(64),
@w_regional                   smallint,
@w_nom_regional               varchar(64),
@w_zona                       smallint,
@w_nom_zona                   varchar(64),
@w_departamento               varchar(64),
@w_tiempo                     varchar(30),
@w_numero_cuotas_vencidas     int,
@w_os_base_calculo            char(1),
@w_return                     int,
@w_dividendo_vigente          smallint,
@w_contador                   int,
@w_dir_cod                    tinyint,
@w_div_vigente                smallint,
@w_est_vigente                tinyint,
@w_est_vencido                tinyint,
@w_est_cancelado              tinyint,
@w_vencido                    money,
@w_cotizacion                 money,
@w_moneda_uvr                 tinyint,
@w_os_moneda                  tinyint,
@w_os_divcap_original         int ,
@w_toperacion                 catalogo,  -- IFJ REQ 434 27/Feb/2006 
@w_valor_cuota                money      -- IFJ REQ 434 27/Feb/2006 

if @i_dias_inicial > 0 
begin
   if @i_dias_final > 0
   begin
      if @i_dias_final < @i_dias_inicial
      begin
         print 'Rango no corresponde vencimiento mayor < vencimiento menor'
         return 1 
      end
   end
   else
   begin
      print 'Par metro de d¡as final no corresponde'
      return 1 
   end 
end
else
begin
   print 'Par metro de d¡as inicial no corresponde'
   return 1 
end   

begin tran

create table #ca_serlefin_tmp (
os_operacion                       int, 
os_banco                           cuenta, 
os_base_calculo                    char(1),             
os_cliente                         int,
os_nombre                          varchar(64),
os_oficina                         smallint,
os_reestructurado                  char(1),        
os_fecha_ult_proceso               datetime,       
os_tdividendo                      char(1),
os_tramite                         int               NULL,
os_identificacion                  numero            NULL,
os_direccion                       tinyint           NULL,
os_saldo_capital                   money             NULL,                 
os_fecha_mora                      datetime          NULL,   
os_dias_vencidos                   int               NULL,   
os_saldo_vencido                   money             NULL,
os_modalidad_cobro                 varchar(12)       NULL,      
os_prox_vencimiento                datetime          NULL, 
os_dividendo_vigente               smallint          NULL,
os_tipo_deudor                     catalogo          NULL,             
os_telefonovar                     char(16)          NULL,
os_nom_direccionvar                char(254)         NULL, 
os_ciudadvar                       char(64)          NULL,       
os_nom_oficina                     varchar(64)       NULL,
os_regional                        smallint          NULL,
os_nom_regional                    varchar(64)       NULL,
os_zona                            smallint          NULL,
os_nom_zona                        varchar(64)       NULL,
os_departamento                    varchar(64)       NULL,
os_moneda                          tinyint           NULL,
os_divcap_original                 int               NULL,
os_toperacion                      catalogo          NULL,  -- IFJ REQ 434 27/Feb/2006
os_valor_cuota                     money             NULL   -- IFJ REQ 434 27/Feb/2006

)

commit tran 


select @w_concepto_cap  = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'CAP'
set transaction isolation level read uncommitted

--- CONSULTA CODIGO DE MONEDA UVR 
select  @w_moneda_uvr = pa_tinyint
from  cobis..cl_parametro
where pa_nemonico = 'MUVR'
and   pa_producto = 'CCA'
set transaction isolation level read uncommitted

insert into #ca_serlefin_tmp (os_operacion, os_banco, os_base_calculo, os_cliente, os_nombre, os_oficina, os_reestructurado, os_fecha_ult_proceso, os_direccion, os_tdividendo, os_tramite, os_moneda,os_divcap_original,os_toperacion)
select op_operacion,
       op_banco,
       op_base_calculo,
       op_cliente, 
       op_nombre,
       op_oficina, 
       op_reestructuracion, 
       op_fecha_ult_proceso, 
       isnull(op_direccion,1),
       op_tdividendo,
       op_tramite,
       op_moneda,
       op_divcap_original,
       op_toperacion       -- IFJ REQ 434 27/Feb/2006
from   cob_cartera..ca_operacion
where  op_naturaleza = 'A'
and    op_estado in (1,2,4,9)

update #ca_serlefin_tmp set
os_nom_oficina = of_nombre,
os_regional    = of_regional,
os_zona        = of_zona
from  cobis..cl_oficina
where of_oficina = os_oficina

update #ca_serlefin_tmp set
os_nom_regional = of_nombre
from  cobis..cl_oficina
where of_oficina = os_regional

update #ca_serlefin_tmp set
os_nom_zona = of_nombre
from  cobis..cl_oficina
where of_oficina = os_zona

update #ca_serlefin_tmp set
os_tipo_deudor = de_rol
from  cob_credito..cr_deudores
where de_cliente = os_cliente
and   de_rol = 'D'

update #ca_serlefin_tmp set
os_modalidad_cobro = ro_fpago
from  ca_rubro_op --(index ca_rubro_op_2)
where ro_operacion  = os_operacion
and   ro_tipo_rubro = 'I'

update #ca_serlefin_tmp set
os_prox_vencimiento  = di_fecha_ven,
os_dividendo_vigente = di_dividendo
from  ca_dividendo --(index ca_dividendo_2)
where di_operacion = os_operacion
and   di_estado    = 1 

update #ca_serlefin_tmp set
os_identificacion = en_ced_ruc
from  cobis..cl_ente --(index cl_ente_Key)
where en_ente = os_cliente

declare cursor_operaciones cursor for
select  os_operacion,
        os_banco,
        os_base_calculo,               
        os_cliente,
        os_nombre,
        os_identificacion,
        os_oficina,
        os_reestructurado,
        os_fecha_ult_proceso,
        os_nom_oficina,
        os_regional,
        os_nom_regional,
        os_zona,
        os_nom_zona,
        os_modalidad_cobro,
        os_prox_vencimiento,
        os_tipo_deudor,
        os_dividendo_vigente,
        os_tdividendo,
        os_tramite,
        os_moneda,
        os_divcap_original,
        os_toperacion   -- IFJ REQ 434 27/Feb/2006
from  #ca_serlefin_tmp
for read only

open  cursor_operaciones
fetch cursor_operaciones 
into  @w_os_operacion,
      @w_os_banco,
      @w_os_base_calculo,
      @w_os_cliente,
      @w_os_nombre,
      @w_os_identificacion,
      @w_os_oficina,
      @w_os_reestructurado,
      @w_os_fecha_ult_proceso,
      @w_nombre_oficina,
      @w_regional,
      @w_nom_regional,
      @w_zona,
      @w_nom_zona,
      @w_modalidad_cobro,
      @w_fecha_prox_vencimiento,
      @w_tipo_deudor,
      @w_dividendo_vigente,
      @w_os_tdividendo,
      @w_os_tramite,
      @w_os_moneda,
      @w_os_divcap_original,
      @w_toperacion  -- IFJ REQ 434 27/Feb/2006

while @@fetch_status = 0 
begin
   -- NUMERO CUOTAS VENCIDAS
   select @w_dias_vencidos_op = 0

   select @w_numero_cuotas_vencidas = count(1) 
   from   ca_dividendo --(index ca_dividendo_2)
   where  di_operacion = @w_os_operacion
   and    di_estado = 2 
   set transaction isolation level read uncommitted

   -- FECHA FIN MINIMA DE DIVIDENDOS VENCIDOS
   select @w_fecha_mora_desde = min(di_fecha_ven)
   from   ca_dividendo --(index ca_dividendo_2)
   where  di_operacion = @w_os_operacion
   and    di_estado = 2 
   set transaction isolation level read uncommitted

   -- DIAS VENCIDOS OPERACION
   if @w_numero_cuotas_vencidas > 0 
   begin
      if @w_os_base_calculo = 'R'
         select @w_dias_vencidos_op = isnull(datediff(dd,@w_fecha_mora_desde,@w_os_fecha_ult_proceso),0)  
      else 
      begin
         exec @w_return = sp_dias_cuota_360
         @i_fecha_ini   = @w_fecha_mora_desde,
         @i_fecha_fin   = @w_os_fecha_ult_proceso,
         @o_dias        = @w_dias_vencidos_op out
      end 
   end
   else
      select @w_dias_vencidos_op = 0

   if @w_dias_vencidos_op < 0
      select @w_dias_vencidos_op = 0

   if @w_dias_vencidos_op is null
      select @w_dias_vencidos_op = 0


   select @w_dias_vencidos_op = @w_dias_vencidos_op +  isnull(@w_os_divcap_original, 0)    ---XMA carterizacion sobregiros

   if (@w_dias_vencidos_op >= @i_dias_inicial) and (@w_dias_vencidos_op <= @i_dias_final)
   begin
      -- MODALIDAD COBRO INTERES
      if @w_modalidad_cobro = 'P'
         select @w_modalidad_cobro = 'V'
 
      select @w_modalidad_cobro_int = @w_os_tdividendo + @w_modalidad_cobro
   
      -- REESTRUCTURADA
      if @w_os_reestructurado = 'S'
         select @w_os_reestructurado = 'R'           
 
      -- FECHA_PROX_VENCIMIENTO
      if @w_fecha_prox_vencimiento is NULL
      begin   
         select @w_fecha_prox_vencimiento = max(di_fecha_ven)
         from   ca_dividendo --(index ca_dividendo_2)
         where  di_operacion = @w_os_operacion
         and    di_estado = 2 -- LA FECHA DE VENCIMIENTO TOTAL
         set transaction isolation level read uncommitted
      end 
      
      select @w_os_nom_direccion = null,
             @w_ciudad           = null,
             @w_departamento     = null,
             @w_telefono         = null

      select @w_os_nom_direccion = di_descripcion,
             @w_ciudad           = ci_descripcion,
             @w_departamento     = pv_descripcion,
             @w_telefono         = (select te_valor from cobis..cl_telefono where te_ente = DI.di_ente and te_direccion = DI.di_direccion)
      from cob_cartera..ca_operacion,
           cobis..cl_direccion DI,
           cobis..cl_provincia,
           cobis..cl_ciudad           
      where op_operacion = @w_os_operacion
      and op_cliente = di_ente
      and op_direccion = di_direccion
      and pv_provincia = di_provincia
      and ci_ciudad   = di_ciudad
      and op_naturaleza = 'A'      

      select @w_est_vigente   = 1,
             @w_est_vencido   = 2,
             @w_est_cancelado = 3

      --DATOS DE LOS DIVIDENDOS
      select @w_div_vigente  = di_dividendo
      from   ca_dividendo --(index ca_dividendo_2)
      where  di_operacion = @w_os_operacion
      and    di_estado    = @w_est_vigente
      set transaction isolation level read uncommitted

      --DIVIDENDO VIGENTE
      select @w_div_vigente = isnull(@w_div_vigente,0)

      --VALORES VENCIDOS PARA ANTES DEL VENCIMIENTO TOTAL
      if @w_div_vigente > 0
      begin
         select @w_vencido   = isnull(sum(am_cuota + am_gracia - am_pagado),0) 
         from   ca_rubro_op, ca_dividendo, ca_amortizacion
         where  ro_operacion = @w_os_operacion
         and    di_operacion = ro_operacion
         and    di_estado    = @w_est_vencido
         and    am_operacion = di_operacion
         and    am_dividendo = (di_dividendo + charindex (ro_fpago, 'A'))
         and    am_concepto  = ro_concepto
         and    am_dividendo > 0
         and    am_estado   <> @w_est_cancelado
         and    ro_concepto  > ''
         and    am_secuencia > 0
      end
      ELSE
      begin
         --SI LA OBLIGACION ESTA TOTALMENTE VENCIDA, LOS VALORES SE SACAN COMPLETAMENTE
         select @w_vencido = isnull(sum(am_cuota + am_gracia - am_pagado),0) 
         from   ca_rubro_op, ca_dividendo, ca_amortizacion
         where  ro_operacion = @w_os_operacion
         and    di_operacion = ro_operacion
         and    di_estado    = @w_est_vencido
         and    am_operacion = di_operacion
         and    am_dividendo = di_dividendo 
         and    am_concepto  = ro_concepto
         and    am_estado   <> @w_est_cancelado
         and    am_dividendo > 0
         and    ro_concepto  > ''
         and    am_secuencia > 0
      end

      select @w_saldo_capital = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
      from  ca_amortizacion, ca_rubro_op  
      where am_operacion    = ro_operacion
      and   am_concepto     = ro_concepto
      and   ro_operacion    = @w_os_operacion
      and   ro_tipo_rubro   = 'C'  --Capital

      if @w_os_moneda = @w_moneda_uvr 
      begin
         select @w_cotizacion = ct_valor
         from   cob_conta..cb_cotizacion noholdlock
         where  ct_moneda = @w_moneda_uvr
         and    ct_fecha  = (select max(ct_fecha) from cob_conta..cb_cotizacion noholdlock
                    where  ct_moneda = @w_moneda_uvr and ct_fecha <= @w_os_fecha_ult_proceso)

         select @w_saldo_capital = (@w_saldo_capital * @w_cotizacion)
         select @w_vencido = (@w_vencido * @w_cotizacion)
      end

      -- Inicio IFJ REQ 434 27/Feb/2006
      Select @w_valor_cuota = isnull(vx_valor_vencido,0)
      From   cob_cartera..ca_valor_atx
      Where  vx_banco =  @w_os_banco
      -- Fin IFJ REQ 434 27/Feb/2006


       
      insert into ca_serlefin(os_banco,os_cliente,          os_nombre,              os_identificacion,  os_oficina,
                  os_reestructurado,   os_saldo_capital,                            
                  os_dias_vencidos,    os_saldo_vencido,    os_modalidad_cobro,     os_prox_vencimiento,os_tipo_deudor,
                  os_telefono,         os_nom_direccion,    os_ciudad,              os_nom_oficina,     os_regional,
                  os_nom_regional,     os_zona,             os_nom_zona,            os_departamento,
                  os_toperacion,       os_valor_cuota ) -- IFJ REQ 434 27/Feb/2006 
                  
      values      (@w_os_banco,             @w_os_cliente,      @w_os_nombre,            @w_os_identificacion,   @w_os_oficina,
                  @w_os_reestructurado,     @w_saldo_capital,
                  @w_dias_vencidos_op,      @w_vencido,         @w_modalidad_cobro_int, convert(char(10),@w_fecha_prox_vencimiento,103),@w_tipo_deudor,
                  @w_telefono,              @w_os_nom_direccion,@w_ciudad,              @w_nombre_oficina, @w_regional,
                  @w_nom_regional,          @w_zona,            @w_nom_zona,            @w_departamento,
                  @w_toperacion ,           @w_valor_cuota) -- IFJ REQ 434 27/Feb/2006

      select de_ced_ruc, de_cliente, de_rol
      into #datos_serlefin
      from cob_credito..cr_deudores
      where de_tramite = @w_os_tramite
      and   de_cliente <> @w_os_cliente
      and   de_rol <> 'D'
      if @@rowcount > 0
      begin
         select @w_contador = count(1) from #datos_serlefin
         while @w_contador > 0 
         begin
            set rowcount 1
            select @w_cedula_codeudor = de_ced_ruc, 
                   @w_nro_cliente = de_cliente,
                   @w_tipo_deudor = de_rol
            from #datos_serlefin
            set rowcount 0
      
            select @w_nombre_codeudor = en_nombre + '' + substring(p_p_apellido,1,20) + '' +  substring(p_s_apellido,1,20),
                   @w_dir_cod = en_direccion 
            from cobis..cl_ente
            where en_ente    = @w_nro_cliente 
            and   en_ced_ruc = @w_cedula_codeudor
      
            if @w_dir_cod is null 
               select  @w_dir_cod = 1
            
            select @w_dir_codeudor = di_descripcion 
            from cobis..cl_direccion
            where di_ente      = @w_nro_cliente
            and   di_direccion = @w_dir_cod

            select @w_tel_codeudor = te_valor 
            from cobis..cl_telefono
            where te_ente      = @w_nro_cliente    
            and   te_direccion = @w_dir_cod
         
            insert into ca_serlefin(      os_banco,os_cliente, os_nombre,           os_identificacion,
                        os_oficina,       os_reestructurado,   os_saldo_capital,    os_dias_vencidos,
                        os_saldo_vencido, os_modalidad_cobro,  os_prox_vencimiento, os_tipo_deudor,
                        os_telefono,      os_nom_direccion,    os_ciudad,           os_nom_oficina,
                        os_regional,      os_nom_regional,     os_zona,             os_nom_zona,                 os_departamento,
                        os_toperacion,    os_valor_cuota) -- IFJ REQ 434 27/Feb/2006
                        
            values      (@w_os_banco,    @w_nro_cliente,                            @w_nombre_codeudor,@w_cedula_codeudor,
                         @w_os_oficina,  @w_os_reestructurado,                      @w_saldo_capital,@w_dias_vencidos_op,
                         @w_vencido,     @w_modalidad_cobro_int,convert(char(10),   @w_fecha_prox_vencimiento,103),@w_tipo_deudor,
                         @w_tel_codeudor,@w_dir_codeudor,                           @w_ciudad,           @w_nombre_oficina,
                         @w_regional,    @w_nom_regional,                           @w_zona,             @w_nom_zona,@w_departamento,
                         @w_toperacion , @w_valor_cuota) -- IFJ REQ 434 27/Feb/2006

            set rowcount 1
            delete from #datos_serlefin
            set rowcount 0

            select @w_contador = @w_contador - 1
         end 
      end
      drop table #datos_serlefin

    end 
   fetch cursor_operaciones 
   into @w_os_operacion,
        @w_os_banco,
        @w_os_base_calculo,
        @w_os_cliente,
        @w_os_nombre,
        @w_os_identificacion,
        @w_os_oficina,
        @w_os_reestructurado,
        @w_os_fecha_ult_proceso,
        @w_nombre_oficina,
        @w_regional,
        @w_nom_regional,
        @w_zona,
        @w_nom_zona,
        @w_modalidad_cobro,
        @w_fecha_prox_vencimiento,
        @w_tipo_deudor,
        @w_dividendo_vigente,
        @w_os_tdividendo,
        @w_os_tramite,
        @w_os_moneda,
        @w_os_divcap_original,
        @w_toperacion  -- IFJ REQ 434 27/Feb/2006
end
close cursor_operaciones
deallocate cursor_operaciones

return 0
go

