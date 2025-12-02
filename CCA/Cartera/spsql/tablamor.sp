/************************************************************************/
/*      Archivo:                tablamor.sp                             */
/*      Stored procedure:       sp_tabla_amortiza                       */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */      
/*      Fecha de escritura:     dic  2004                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Genera la tabla de amortizacion proyectada para los creditos    */
/*      de vivienda, despues de generar el UVR para un a§o si Çste no   */
/*        hab°a sido generado ya.                                       */
/************************************************************************/  
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR           RAZON                           */
/*      FEB:2005        Elcira Pelaez   Actualizacion para el ABC       */
/*      20/Feb/2007     Elcira Pelaez B.  defecto Nro. 7848 06:53pm     */
/*      23/Feb/2007     Elcira Pelaez B.  defecto Nro. 7937             */
/*  22/01/21          P.Narvaez        optimizado para mysql            */
/************************************************************************/ 

use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_tabla_amortiza')
   drop proc sp_tabla_amortiza
go
create proc sp_tabla_amortiza
            (@s_user                  varchar(14),
             @i_fecha_inicial         datetime,
             @i_oficina               smallint = 0,
             @i_banco                 cuenta   = null)

as
declare 
   @w_error                    int,
   @w_sp_name                  descripcion,
   @w_moneda_uvr               int,
   @w_est_anulado              int,
   @w_ano                      int,
   @w_up_cotizacion            float,
   @w_ipc                      float,
   @w_i                        smallint,
   @w_date_ipc                 datetime,
   @w_anoipc                   int,
   @w_mes                      int,
   @w_numdias                  float,
   @w_uvr_inicial              float,
   @w_fecha_uvr                datetime,
   @w_fecha_final              datetime,
   @w_t                        float,
   @w_expo                     float,
   @w_parcial                  float,
   @w_valor_final              float,
   @w_op_banco                 cuenta,
   @w_op_operacion             int,
   @w_op_toperacion            catalogo,
   @w_op_moneda                int,
   @w_op_moneda_anterior       int,
   @w_op_cliente               int,
   @w_op_nombre                descripcion,
   @w_op_dividendo             int,
   @w_op_dias_cuota            int,
   @w_op_fecha_ven             datetime,
   @w_op_concepto              catalogo,
   @w_op_cuota_total           float,
   @w_op_dividendo_anterior    int,
   @w_val1                     float,
   @w_val2                     float,
   @w_val3                     float,
   @w_val4                     float,
   @w_val5                     float,
   @w_val6                     float,
   @w_val7                     float,
   @w_cotiz                    float,
   @w_fecha_dividendo          datetime,
   @w_suma                     float,
   @w_cu_operacion_anterior   int,
   @w_hay_valor         catalogo,
   @w_dadiff         int,
   @w_fecha_max         datetime,
   @w_tasa_uvr_ini                 float,
   @w_rubro_cap                    catalogo,
   @w_rubro_int                    catalogo,
   @w_rubro_imo                    catalogo,
   @w_rubro_ivasegtrvi             catalogo,
   @w_op_direccion         tinyint,
   @w_op_oficina         smallint,
   @w_op_fecha_liq         datetime,
   @w_cu_dividendo_anterior   int,
   @w_op_monto         money,
   @w_toperacion_desc      descripcion,
   @w_op_plazo         smallint,
   @w_op_tplazo         catalogo,
   @w_op_fecha_fin         datetime,
    @w_op_tdividendo      catalogo,
   @w_op_tipo_amortizacion      descripcion,
   @w_op_sector         catalogo,
   @w_op_fecha_ult_proceso      datetime,
   @w_moneda_desc         descripcion,   
   @w_tplazo         descripcion,
   @w_tdividendo         descripcion,
   @w_tasa            float,
   @w_tasa_referencial      catalogo,
   @w_tasa_ef_anual      float,
   @w_signo_spread         char(1),
   @w_valor_spread         float,
   @w_tasa_base         varchar(10),
   @w_modalidad         char(10),
   @w_valor_referencial      float,
   @w_fecha         datetime,
   @w_fecha_ult_proceso      datetime,
   @w_secuencial_ref      int,
   @w_valor_base         float,
   @w_ced_ruc         varchar(30),
   @w_nombre         descripcion,
   @w_telefono         varchar(16),
   @w_direccion         descripcion,
   @w_di_dividendo         int,
   @w_di_dias_cuota      smallint,
   @w_di_fecha_ven         datetime,
   @w_ro_concepto         catalogo,
   @w_ro_tipo_rubro      char(1),
   @w_cu_cuota_total      money,
   @w_cu_moneda_anterior      smallint,
   @w_monto_cap         money,
   @w_monto_total_cap      money,
   @w_saldo_cap_div       money,
   @w_ro_porcentaje       float,
   @w_di_estado           tinyint,
   @w_estado_des          descripcion,
   @w_des_cuota           catalogo,
   @w_cotizacion_monto    float,
   @w_ca_monto_mn         money,
   @w_plazo_credito       int,
   @w_plazo_final         varchar(20),
   @w_fecha_limited       datetime,
   @w_fecha_inid          datetime,
   @w_monto_cap_a_restar  money,
   @w_dividendo_min       int,
   @w_moneda_nacional     smallint,
   @w_cod_ciudad          int,
   @w_ie_ciudad           descripcion,
   @w_provincia           smallint,
   @w_ie_dpto             descripcion,
   @w_secuencial_ipc      int,
   @w_rowcount            int



--  NOMBRE DEL SP  
select  @w_sp_name = 'sp_tabla_amortiza' 
select  @w_suma = 0
select  @w_cotiz = 1.0
select @w_plazo_credito = 0



-- CODIGO DE LA MONEDA LOCAL
select @w_moneda_nacional = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0
begin
   select @w_error = 708174
   goto ERROR1
end



--  BORRAR TABLA  
truncate table ca_amortizacion_proyectada


-- SELECCI‡N DEL CODIGO DE LA MONEDA
select @w_moneda_uvr = pa_tinyint 
from cobis..cl_parametro    
where pa_producto = 'CCA'
and   pa_nemonico = 'MUVR'
set transaction isolation level read uncommitted
   

--SELECCI‡N DEL CODIGO DE LA TASA UVR INICIAL
select @w_uvr_inicial = pa_float
from cobis..cl_parametro    
where pa_producto = 'CCA'
and   pa_nemonico = 'TUVR'
set transaction isolation level read uncommitted


/* CODIGO DEL RUBRO CAPITAL */
select @w_rubro_cap = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'CAP'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0 
begin
 select @w_error =  710076
 goto ERROR1
end


--- CODIGO DEL RUBRO INTERES 
select @w_rubro_int = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'INT'
select @w_rowcount = @@rowcount 
set transaction isolation level read uncommitted

if @w_rowcount = 0  
begin
 select @w_error =  710256
 goto ERROR1
end


/* CODIGO DEL RUBRO MORA */
select @w_rubro_imo = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'IMO'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @@rowcount = 0  
begin
 select @w_error =  710256
 goto ERROR1
end


---  DATOS DE FECHA 
select @w_ano = datepart(yy,@i_fecha_inicial)
select @w_fecha_limited = dateadd(yy,1,@i_fecha_inicial)
select @w_fecha_inid = dateadd(yy,-1,@i_fecha_inicial)


select @w_up_cotizacion = 0


truncate table ca_cabecera


/* SI NO EXISTE COTIZACION GENERA LA PROYECCION DE LAS COTIZACIONES */
/********************************************************************/
if @w_up_cotizacion = 0 or @w_up_cotizacion is null
begin
   if @w_uvr_inicial = 0 or @w_uvr_inicial is null
   begin
      select @w_error = 710390
      goto ERROR1
   end   

   truncate table ca_uvr_proyectado   

   select @w_date_ipc    = convert(datetime,'01/01/' + convert(varchar(4),@w_ano))
   select @w_fecha_uvr   = '01/16/' + convert(varchar(4),@w_ano)
   select @w_fecha_final = '02/15/' + convert(varchar(4),@w_ano)


   select @w_i = 1
   while  @w_i <= 12
   begin   
      select @w_ipc = null
      --- SE OBTIENE LA TASA REFERENCIAL DE LA IPC PROYECTADA PARA EL A•O EN CURSO 
      select @w_secuencial_ipc = isnull(max(pi_cod_pizarra), 0)
      from   cobis..te_tpizarra
      where  pi_referencia = 'IPCP'
      and    pi_fecha_inicio  <= @w_date_ipc

            
      select @w_ipc = isnull(pi_valor,0)
      from   cobis..te_tpizarra
      where  pi_referencia = 'IPCP'
      and    pi_cod_pizarra = @w_secuencial_ipc
      
      if @w_ipc is null
      begin
         select @w_error = 710388
         goto ERROR1
      end 
      
      select @w_ipc = (@w_ipc / 100.0)
      
      select @w_mes = @w_i      
      
      
      if @w_mes = 2
      begin 
        if (@w_ano % 4) = 0
            select @w_numdias = 29
         else
            select @w_numdias = 28      
      end
      ELSE
        --select @w_numdias = case
        --                    when @w_mes in (1, 3, 5, 7, 8, 10, 12) then 31.0
        --                    else 30.0
        --                    end
        if @w_mes in (1, 3, 5, 7, 8, 10, 12)
		   select @w_numdias = 31.0
		else
		   select @w_numdias = 30.0
		   
		   
      select @w_t = 1
      select @w_valor_final = 0,
             @w_expo        = 0,
             @w_parcial     = 0
      
      while @w_fecha_uvr <= @w_fecha_final
      begin
         select @w_valor_final = @w_uvr_inicial * (1.0 + @w_ipc * @w_t / @w_numdias)
         select @w_valor_final = round(@w_valor_final,4)
         
         /*print 'dia' + @w_t + 'numdias' + @w_numdias + 'ipc'+ @w_ipc + 'inicial' + @w_uvr_inicial + 'fecha' + @w_fecha_uvr +  'final' + @w_fecha_final + '->' + @w_valor_final*/
                
         
         insert into ca_uvr_proyectado
         values (@w_fecha_uvr,@w_valor_final)
         
         select @w_t = @w_t + 1       
         
         select @w_expo        = 0,
                @w_parcial     = 0
         
         select @w_fecha_uvr = dateadd(dd,1,@w_fecha_uvr)
      end -- while datediff(dd,conv...
      
      select @w_uvr_inicial = @w_valor_final
      
      select @w_date_ipc = dateadd(mm, 1, @w_date_ipc)
      select @w_fecha_final = dateadd(mm, 1, @w_fecha_final)

      select @w_i = @w_i + 1

   end -- while @w_i < 13
end --if @w_up_cotizacion = 0 or @w_up_cotizacion is null

--SE SELECCIONA TODAS LAS OPERACI‡NES QUE ESTEN EN MONEDA UVR Y CLASE VIVIENDA 
--******************************************************************************
if @i_oficina = 0  ---TODAS LAS OFICINAS
begin
        PRINT 'tabamor.sp entro 1'
        declare cursor_operacion cursor for
        select  op_operacion,   op_banco,           op_toperacion,      op_moneda,       op_cliente,   
        op_nombre,      op_direccion,       op_oficina,         op_fecha_liq,    op_monto,
        op_plazo,       op_tplazo,          op_fecha_fin,       op_tdividendo,   op_tipo_amortizacion,
        op_sector,      op_fecha_ult_proceso
        from   ca_operacion
        where  op_clase   = '3'   --VIVIENDA
        and    op_fecha_fin > @i_fecha_inicial     --POR QUE SON PROYECCIONES
        and    op_estado <> 3

        order by op_cliente
        for read only
end
ELSE
      if @i_oficina > 0 and @i_banco is null   ---UNA SOLA OFICINA 
      begin
PRINT 'tabamor.sp entro 2'

         if not exists (select 1 from cobis..cl_oficina
                        where of_oficina = @i_oficina)
                begin
                  PRINT 'Error La oficina digitada No existe'
                  goto ERROR1
                end
          
         declare cursor_operacion cursor for  
         
         select  op_operacion,   op_banco,            op_toperacion,      op_moneda,       op_cliente,   
                 op_nombre,      op_direccion,        op_oficina,         op_fecha_liq,    op_monto,
                 op_plazo,       op_tplazo,           op_fecha_fin,       op_tdividendo,   op_tipo_amortizacion,
                 op_sector,      op_fecha_ult_proceso
         from   ca_operacion
         where op_oficina = @i_oficina
         and    op_clase   = '3'   --VIVIENDA
         and    op_fecha_fin > @i_fecha_inicial     --POR QUE SON PROYECCIONES
         and    op_estado <> 3
         order by op_cliente

         for read only
       
      end
   ELSE
      if @i_banco is not null   ---UNA SOLA OPERACION
         begin
            PRINT 'tabamor.sp entro 3'
           if not exists (select 1 from cob_cartera..ca_operacion
                  where op_banco = @i_banco
                  and   op_fecha_fin > @i_fecha_inicial)
                   begin
                     PRINT 'Error el No. de Obligacion digitado no existe o ya esta vencido'
                     goto ERROR1
                   end
            declare cursor_operacion cursor for  
            select  op_operacion,   op_banco,            op_toperacion,      op_moneda,       op_cliente,   
                    op_nombre,      op_direccion,        op_oficina,         op_fecha_liq,    op_monto,
                    op_plazo,       op_tplazo,           op_fecha_fin,       op_tdividendo,   op_tipo_amortizacion,
                    op_sector,      op_fecha_ult_proceso
            from   ca_operacion
            where op_banco = @i_banco
            and    op_clase   = '3'   --VIVIENDA
            and    op_fecha_fin > @i_fecha_inicial     --POR QUE SON PROYECCIONES
            and    op_estado <> 3
            for read only
         end      

open cursor_operacion

fetch cursor_operacion into
@w_op_operacion,   @w_op_banco,    @w_op_toperacion,   @w_op_moneda,       @w_op_cliente,    
@w_op_nombre,      @w_op_direccion,@w_op_oficina,      @w_op_fecha_liq,    @w_op_monto,
@w_op_plazo,       @w_op_tplazo,   @w_op_fecha_fin,    @w_op_tdividendo,   @w_op_tipo_amortizacion,
@w_op_sector,      @w_op_fecha_ult_proceso


   
--while @@fetch_status not in (-1,0)
while @@fetch_status = 0
begin
   select @w_cu_dividendo_anterior = -1 

   select @w_toperacion_desc   = A.valor,
          @w_moneda_desc       = mo_descripcion
   from ca_operacion, cobis..cl_catalogo A, cobis..cl_moneda
   where op_banco    = @w_op_banco
   and op_toperacion = A.codigo
   and op_moneda     = mo_moneda
   
   select @w_tplazo   = td_descripcion 
   from ca_tdividendo
   where td_tdividendo = @w_op_tplazo
   
   if @@rowcount = 0 
   begin
      print '19'
      select @w_error = 701112
      goto ERROR
   end
   
   select @w_tdividendo= td_descripcion 
   from  ca_tdividendo
   where td_tdividendo = @w_op_tdividendo
   
   if @@rowcount = 0 
   begin
      print '18'
      select @w_error = 701112
      goto ERROR
   end
  
   select @w_tasa_referencial  = ro_referencial,
          @w_signo_spread      = ro_signo,
          @w_valor_spread      = ro_factor,
          @w_modalidad         = ro_fpago,
          @w_valor_referencial = ro_porcentaje_aux,
          @w_tasa              = ro_porcentaje,
          @w_tasa_ef_anual     = ro_porcentaje_efa
   from ca_rubro_op
   where ro_operacion  =  @w_op_operacion
   and   ro_tipo_rubro =  'I'
   and   ro_fpago      in ('P','A')
   
   if @@rowcount = 0 
   begin
      print '16'
      select @w_error = 710037
      goto ERROR
   end
   
   if @w_tasa_referencial is not null 
   begin
      select  @w_tasa_base  = vd_referencia
      from  ca_valor, ca_valor_det,ca_tasa_valor
      where va_tipo        = @w_tasa_referencial
      and   vd_tipo        = @w_tasa_referencial
      and   tv_nombre_tasa = vd_referencia
      and   vd_sector      = @w_op_sector
      
      if @@rowcount = 0 
      begin
         print '15'
         select @w_error = 710076
         goto ERROR
      end
      
      if @w_tasa_base != 'TCERO'
      begin
         select @w_fecha = max(pi_fecha_inicio)
         from   cobis..te_tpizarra
         where  pi_referencia     = @w_tasa_base 
         and  pi_fecha_inicio  <= @w_op_fecha_ult_proceso 
         
         if @@rowcount = 0 
         begin
            print '14'
            select @w_error = 710076
            goto ERROR
         end
    
         select @w_secuencial_ref = max(pi_cod_pizarra)
         from   cobis..te_tpizarra
         where   pi_referencia     = @w_tasa_base 
         and  pi_fecha_inicio   = @w_fecha
         
         if @@rowcount = 0 
         begin
            select @w_error = 710076
            goto ERROR
         end
         
         -- TASA BASICA REFERENCIAL 
         select @w_valor_base = isnull(pi_valor,0)
         from   cobis..te_tpizarra
         where  pi_referencia       = @w_tasa_base 
         and    pi_cod_pizarra = @w_secuencial_ref
         
         if @@rowcount = 0 
         begin
            print '13'
            select @w_error = 710076
            goto ERROR
         end
      end
      ELSE
         select @w_valor_base = 0
   end
   ELSE
      select @w_valor_base = 0
   
   select @w_ced_ruc    = isnull(en_ced_ruc,p_pasaporte), 
          @w_nombre     = en_nomlar,
          @w_telefono   = (select isnull(te_valor,'') from cobis..cl_telefono where te_ente = CL.en_ente and te_direccion = @w_op_direccion ),
          @w_direccion  = (select isnull(di_descripcion,'') from cobis..cl_direccion where di_ente = CL.en_ente and di_direccion = @w_op_direccion),
          @w_cod_ciudad = (select di_ciudad from cobis..cl_direccion where di_ente = CL.en_ente and di_direccion = @w_op_direccion)
   from  cobis..cl_ente CL        
   where en_ente    = @w_op_cliente  
   
   if @@rowcount = 0 
   begin
      print 'tablamor.sp Error en clientes'
      select @w_error = 710200
      goto ERROR
   end


   if @w_direccion is null or @w_direccion = ''
   begin
      select @w_direccion    = di_descripcion,
             @w_cod_ciudad   = di_ciudad
      from cobis..cl_direccion  
      WHERE di_ente = @w_op_cliente
      and di_direccion = 1
   end

   select @w_ie_ciudad = ci_descripcion,
          @w_provincia = ci_provincia
   from cobis..cl_ciudad 
   where ci_ciudad = @w_cod_ciudad
   set transaction isolation level read uncommitted


   select @w_ie_dpto = pv_descripcion 
   from cobis..cl_provincia
   where  pv_provincia = @w_provincia
   set transaction isolation level read uncommitted
   
   -- INSERCION DE LA CABECERA DE LA TABLA DE AMORTIZACION 
   
   select @w_des_cuota = substring(td_descripcion,1,9)
   from ca_tdividendo
   where td_tdividendo = @w_op_tdividendo

   if ltrim(rtrim(@w_op_tipo_amortizacion)) = 'ALEMANA'
      select @w_op_tipo_amortizacion = 'CAPITAL FIJO'
   ELSE
   begin
      if ltrim(rtrim(@w_op_tipo_amortizacion)) = 'FRANCESA'
         select @w_op_tipo_amortizacion = 'CUOTA FIJA'
      else
         select @w_op_tipo_amortizacion = 'PERSONALIZADA' 
   end
   
   if @w_modalidad = 'P'
      select @w_modalidad = 'VENCIDA'
   else
      select @w_modalidad = 'ANTICIPADA'
   
   select @w_cotizacion_monto = 1
   
   if @w_op_moneda <> 0
   begin
      exec sp_buscar_cotizacion
           @i_moneda      = @w_op_moneda,
           @i_fecha       = @w_op_fecha_liq,
           @o_cotizacion  = @w_cotizacion_monto out
   end
   else
      select @w_cotizacion_monto = 1
   
   select @w_ca_monto_mn = round(@w_op_monto * @w_cotizacion_monto,0)
   
   select @w_plazo_credito = count(1)
   from ca_dividendo
   where di_operacion = @w_op_operacion
   

   select @w_plazo_final  = convert(char(5),@w_plazo_credito) + '' + @w_des_cuota

   BEGIN TRAN
   
   insert into ca_cabecera
         (ca_operacion,             ca_cliente,            ca_nombre,      
          ca_direccion,             ca_nit,                ca_telefono,      
          ca_oficina,               ca_banco,              ca_fecha_desembol,   
          ca_monto,                 ca_plazo,              ca_descripcion_plazo,   
          ca_tipo_amortizacion,     ca_cuota,              ca_fecha_vencimiento,   
          ca_modalidad,             ca_toperacion,         ca_tasa_efa,      
          ca_moneda,                ca_tasa_ref,           ca_fecha_tasa_ref,   
          ca_signo,                 ca_valor_ref,          ca_spread,      
          ca_monedac,               ca_monto_mn,            ca_ciudad,
          ca_departamento
          )
   values(
          @w_op_operacion,          @w_op_cliente,         @w_nombre,
          @w_direccion,             @w_ced_ruc,            @w_telefono,
          @w_op_oficina,            @w_op_banco,           convert(varchar(10),@w_op_fecha_liq,101),
          @w_op_monto,              @w_plazo_final,        @w_des_cuota,
          @w_op_tipo_amortizacion,  @w_des_cuota,          convert(varchar(10),@w_op_fecha_fin,101),
          @w_modalidad,             @w_toperacion_desc,    @w_tasa_ef_anual,
          @w_moneda_desc,           @w_tasa_referencial,   convert(varchar(10),@w_fecha,101),
          @w_signo_spread,          @w_valor_base,         @w_valor_spread,   
          @w_op_moneda,             @w_ca_monto_mn,        @w_ie_ciudad,
          @w_ie_dpto)
   
   if @@error != 0
   begin
      print 'tablamor.sp ERROR EN CABECERA'
      select @w_error = 710200
      goto ERROR
   end
   
  
   delete cx_amortizacion
   where di_dividendo >= 0

   if @w_op_moneda = @w_moneda_nacional
   begin
      insert into cx_amortizacion
      select di_dividendo,    di_estado,          di_dias_cuota,     convert(varchar(10),di_fecha_ven,101),  
             ro_concepto,     ro_tipo_rubro,      convert(float,isnull(sum(am_cuota + am_gracia),0)) 
      from   ca_rubro_op, ca_dividendo, ca_amortizacion
      where  ro_operacion = @w_op_operacion
      and    ro_operacion = di_operacion
      and    ro_operacion = am_operacion
      and    ro_concepto  = am_concepto
      and    di_dividendo = am_dividendo
      and    di_fecha_ven  between @w_fecha_inid and  @w_fecha_limited  --UN A—O aNTES Y UN A—O DESPUES DE LA FECHA DIGITADA
      group by di_dividendo,di_estado,di_dias_cuota,di_fecha_ven,ro_concepto, ro_tipo_rubro
   end   
   else
   begin
      insert into cx_amortizacion
      select di_dividendo,    di_estado,          di_dias_cuota,     convert(varchar(10),di_fecha_ven,101),  
             ro_concepto,     ro_tipo_rubro,      convert(float,isnull(sum(am_cuota + am_gracia),0)) 
      from   ca_rubro_op, ca_dividendo, ca_amortizacion
      where  ro_operacion = @w_op_operacion
      and    ro_operacion = di_operacion
      and    ro_operacion = am_operacion
      and    ro_concepto  = am_concepto
      and    di_dividendo = am_dividendo
      and    di_fecha_ven  between @w_fecha_inid and  @w_fecha_limited  --UN A—O aNTES Y UN A—O DESPUES DE LA FECHA DIGITADA
      group by di_dividendo,di_estado,di_dias_cuota,di_fecha_ven,ro_concepto, ro_tipo_rubro
   end

   select @w_monto_total_cap = 0,
          @w_dividendo_min = 0,
          @w_monto_cap_a_restar = 0

   select @w_monto_total_cap =  isnull(sum(am_cuota),0)
   from ca_amortizacion
   where am_concepto = 'CAP'
   and   am_operacion  = @w_op_operacion


   /* DIVIDENDO A PARTIR DEL CUAL SE GENERA LA TABLA DE AMORTIZACION */
   /******************************************************************/
   select @w_dividendo_min = min(di_dividendo )
   from cx_amortizacion
   where ro_tipo_rubro  = 'C'


   /* VALOR DE CAPITAL A RESTAR DEL SALDO DE CAPITAL */
   /**************************************************/
   select @w_monto_cap_a_restar =  isnull(sum(am_cuota),0)
   from ca_amortizacion
   where am_concepto = 'CAP' 
   and   am_operacion  = @w_op_operacion
   and   am_dividendo < @w_dividendo_min



   select @w_monto_total_cap = isnull(sum(@w_monto_total_cap - @w_monto_cap_a_restar),0)

   
   -- CURSOR POR OPERACION
   
   declare
      cursor_rubros cursor
      for select    di_dividendo,       di_estado,      di_dias_cuota,     di_fecha_ven,  
                    ro_concepto,        ro_tipo_rubro,      cuota_total
      from cx_amortizacion
      for read only
   
   open cursor_rubros
    
   fetch cursor_rubros
   into  @w_di_dividendo,       @w_di_estado,       @w_di_dias_cuota,    @w_di_fecha_ven, 
         @w_ro_concepto,        @w_ro_tipo_rubro,   @w_cu_cuota_total
   
   while @@fetch_status = 0 
   begin   
      if @@fetch_status = -1 
      begin    
         select @w_error = 708999
         goto  ERROR
      end   

      if @w_cu_dividendo_anterior != @w_di_dividendo
      begin   
         --AL CAMBIAR DE DIVIDENDO HACE EL C†LCULO DE LA CUOTA TOTAL Y DE LA CONVERSION A MONEDA NACIONAL
         if @w_cu_dividendo_anterior != -1 
         begin
            select @w_val1  = 0,
                   @w_val2  = 0,
                   @w_monto_cap = 0,
                   @w_saldo_cap_div = 0,
                   @w_fecha_dividendo = '',
                   @w_estado_des  = ''                   
            
            select @w_estado_des = es_descripcion
            from ca_estado
            where es_codigo = @w_di_estado
            
            --TOTAL OTROS
            select @w_val1  = isnull(sum(cuota_total),0)
            from cx_amortizacion
            where di_dividendo     = @w_cu_dividendo_anterior
            and   ro_tipo_rubro  not in ('C','I','M')

       --TOTAL CAPITAL,INTERES,MORA
            select @w_val2  = isnull(sum(cuota_total),0)
            from cx_amortizacion
            where di_dividendo    = @w_cu_dividendo_anterior
            and   ro_tipo_rubro  in ('C','I','M')



            select @w_monto_cap =  isnull(sum(cuota_total),0)
            from cx_amortizacion
            where ro_tipo_rubro  = 'C'
            and   di_dividendo  <= @w_cu_dividendo_anterior - 1

            
            select @w_saldo_cap_div = isnull(sum(@w_monto_total_cap - @w_monto_cap),0)
            
            update ca_amortizacion_proyectada 
            set ap_concepto4         = 'OTROS',
                ap_concepto4_val     = isnull(@w_val1,0)
            where ap_operacion       = @w_cu_operacion_anterior 
            and ap_cuota             = @w_cu_dividendo_anterior
            
            if @w_cu_dividendo_anterior = 1
            begin
               select @w_saldo_cap_div = @w_monto_total_cap
            end


            update ca_amortizacion_proyectada 
            set ap_concepto5         = 'SALDO_CAP',
                ap_concepto5_val     = isnull(@w_saldo_cap_div,0)
            where ap_operacion       = @w_cu_operacion_anterior 
            and ap_cuota             = @w_cu_dividendo_anterior

            select @w_fecha_dividendo = ap_fecha_vencimiento
            from ca_amortizacion_proyectada
            where ap_operacion = @w_cu_operacion_anterior 
            and   ap_cuota     = @w_cu_dividendo_anterior

            select @w_suma = 0
            select @w_cotiz = 1.0
            select @w_suma = round((@w_val1+@w_val2),4)
   
            if @w_cu_moneda_anterior = @w_moneda_uvr
            begin
               select @w_cotiz = up_cotizacion 
               from ca_uvr_proyectado
               where up_fecha = @w_fecha_dividendo   
               
               if @@rowcount = 0
               begin
                  exec sp_buscar_cotizacion
                       @i_moneda      = @w_moneda_uvr,
                       @i_fecha       = @w_fecha_dividendo,
                       @o_cotizacion  = @w_cotiz out
               end
            end
            ELSE 
            begin
               select @w_cotiz  = 1.0
            end
            
            update ca_amortizacion_proyectada 
            set ap_valor_cuota = @w_suma,
                ap_valor_mn        = @w_suma * @w_cotiz
            where ap_operacion = @w_cu_operacion_anterior 
            and   ap_cuota     = @w_cu_dividendo_anterior   

            update ca_amortizacion_proyectada 
            set ap_concepto7         = 'VALOR_UVR',
                ap_concepto7_val     = isnull(@w_cotiz,0)
            where ap_operacion       = @w_cu_operacion_anterior 
            and ap_cuota             = @w_cu_dividendo_anterior   
         end
         
         if  @w_ro_concepto = @w_rubro_cap
         begin
            insert into ca_amortizacion_proyectada 
            (ap_operacion,   ap_cuota,   ap_dias_calculo,   ap_fecha_vencimiento,
            ap_capital,   ap_capital_val)
            values 
            (@w_op_operacion,   @w_di_dividendo,@w_di_dias_cuota,   convert(varchar(10),@w_di_fecha_ven,101),
            @w_ro_concepto,   @w_cu_cuota_total)
         end 
         ELSE
         if @w_ro_concepto = @w_rubro_int
         begin
            insert into ca_amortizacion_proyectada 
            (ap_operacion,   ap_cuota,   ap_dias_calculo,   ap_fecha_vencimiento,
             ap_capital,   ap_capital_val)
            values 
            (@w_op_operacion,   @w_di_dividendo,@w_di_dias_cuota,   convert(varchar(10),@w_di_fecha_ven,101),
            @w_ro_concepto,   @w_cu_cuota_total)
         end
         ELSE
         if @w_ro_concepto = @w_rubro_imo               
         begin
            insert into ca_amortizacion_proyectada 
            (ap_operacion,   ap_cuota,   ap_dias_calculo,   ap_fecha_vencimiento,
             ap_capital,   ap_capital_val)
            values 
            (@w_op_operacion,   @w_di_dividendo,@w_di_dias_cuota,   convert(varchar(10),@w_di_fecha_ven,101),
            @w_ro_concepto,   @w_cu_cuota_total)
         end
         
         if @w_ro_tipo_rubro not in ('C','I','M')               
         begin
            insert into ca_amortizacion_proyectada 
            (ap_operacion,   ap_cuota,   ap_dias_calculo,   ap_fecha_vencimiento,
             ap_capital,   ap_capital_val)
            values 
            (@w_op_operacion,   @w_di_dividendo,@w_di_dias_cuota,   convert(varchar(10),@w_di_fecha_ven,101),
             @w_ro_concepto,   @w_cu_cuota_total)
         end
      end --if @w_cu_dividendo_anterior != @w_di_dividendo
      ELSE
      begin
         if  @w_ro_concepto = @w_rubro_cap
         begin
            update ca_amortizacion_proyectada 
            set ap_capital     = @w_ro_concepto,
            ap_capital_val     = @w_cu_cuota_total 
            where ap_operacion = @w_op_operacion
            and   ap_cuota     = @w_di_dividendo
         end 
         ELSE
         begin
            if @w_ro_concepto = @w_rubro_int
            begin
               update ca_amortizacion_proyectada 
               set ap_interes     = @w_ro_concepto,
               ap_interes_val     = @w_cu_cuota_total 
               where ap_operacion = @w_op_operacion
               and   ap_cuota     = @w_di_dividendo
            end
            ELSE
            begin
               if @w_ro_concepto = @w_rubro_imo
               begin
                  update ca_amortizacion_proyectada 
                  set ap_mora        = @w_ro_concepto,
                  ap_mora_val        = @w_cu_cuota_total 
                  where ap_operacion = @w_op_operacion
                  and   ap_cuota     = @w_di_dividendo
               end
            end
         end
      end
      
      select @w_cu_dividendo_anterior = @w_di_dividendo
      select @w_cu_operacion_anterior = @w_op_operacion
      select @w_cu_moneda_anterior    = @w_op_moneda
      
      fetch cursor_rubros
      into  @w_di_dividendo,    @w_di_estado,      @w_di_dias_cuota,    @w_di_fecha_ven, 
            @w_ro_concepto,   @w_ro_tipo_rubro,   @w_cu_cuota_total
   end ----while @@fetch_status = 0 cursor: cursor_rubros
   
   close cursor_rubros
   deallocate cursor_rubros



   if exists (select 1 from ca_rubro_op 
              where ro_operacion = @w_cu_operacion_anterior 
              and ro_tipo_rubro not in  ('C','I','M'))
   begin


      if @w_cu_dividendo_anterior != -1 
      begin

         select @w_val1  = 0,
                 @w_val2  = 0,
                 @w_monto_cap = 0,
                 @w_saldo_cap_div = 0,
                 @w_fecha_dividendo = ''
         

         --TOTAL OTROS
         select @w_val1  = isnull(sum(cuota_total),0)
         from cx_amortizacion
         where di_dividendo     = @w_cu_dividendo_anterior
         and   ro_tipo_rubro  not in ('C','I','M')


         --TOTAL CAPITAL,INTERES,MORA
         select @w_val2  = isnull(sum(cuota_total),0)
         from cx_amortizacion
         where di_dividendo    = @w_cu_dividendo_anterior
         and   ro_tipo_rubro  in ('C','I','M')
         
         select @w_monto_total_cap = 0,
                @w_dividendo_min = 0,
                @w_monto_cap_a_restar = 0


         /*VALOR SALDO CAPITAL*/
         /*********************/
         select @w_monto_total_cap =  sum(am_cuota)
         from ca_amortizacion
         where am_concepto = 'CAP'
         and   am_operacion  = @w_op_operacion

         /* DIVIDENDO A PARTIR DEL CUAL SE GENERA LA TABLA DE AMORTIZACION */
         /******************************************************************/
         select @w_dividendo_min = max(di_dividendo )
         from cx_amortizacion
         where ro_tipo_rubro  = 'C'

         /* VALOR DE CAPITAL A RESTAR DEL SALDO DE CAPITAL */
         /**************************************************/
         select @w_monto_cap_a_restar =  sum(am_cuota)
         from ca_amortizacion
         where am_concepto = 'CAP' 
         and   am_operacion  = @w_op_operacion
         and   am_dividendo < @w_dividendo_min


         select @w_saldo_cap_div = isnull(sum(@w_monto_total_cap - @w_monto_cap_a_restar),0)


         update ca_amortizacion_proyectada 
         set ap_concepto4         = 'OTROS',
             ap_concepto4_val     = isnull(@w_val1,0)
         where ap_operacion       = @w_cu_operacion_anterior 
         and ap_cuota             = @w_cu_dividendo_anterior


         update ca_amortizacion_proyectada 
         set ap_concepto5         = 'SALDO_CAP',
             ap_concepto5_val     = isnull(@w_saldo_cap_div,0)
         where ap_operacion       = @w_cu_operacion_anterior 
         and ap_cuota             = @w_cu_dividendo_anterior

         select @w_fecha_dividendo = ap_fecha_vencimiento
         from ca_amortizacion_proyectada
         where ap_operacion = @w_cu_operacion_anterior 
         and   ap_cuota     = @w_cu_dividendo_anterior

         select @w_suma = 0
         select @w_cotiz = 1.0
         select @w_suma = round((@w_val1+@w_val2),4)

         if @w_cu_moneda_anterior = @w_moneda_uvr
         begin
            select @w_cotiz = up_cotizacion 
            from ca_uvr_proyectado
            where up_fecha = @w_fecha_dividendo
            if @@rowcount = 0
            begin
               exec sp_buscar_cotizacion
                    @i_moneda      = @w_moneda_uvr,
                    @i_fecha       = @w_fecha_dividendo,
                    @o_cotizacion  = @w_cotiz out
            end
         end
         ELSE 
         begin
            select @w_cotiz  = 1.0
         end
        

         update ca_amortizacion_proyectada 
         set ap_valor_cuota = @w_suma,
                ap_valor_mn        = @w_suma * @w_cotiz
         where ap_operacion = @w_cu_operacion_anterior 
         and   ap_cuota     = @w_cu_dividendo_anterior      

         update ca_amortizacion_proyectada 
         set ap_concepto7         = 'VALOR_UVR',
             ap_concepto7_val     = isnull(@w_cotiz,0)
         where ap_operacion       = @w_cu_operacion_anterior 
         and ap_cuota             = @w_cu_dividendo_anterior

         update ca_amortizacion_proyectada 
         set ap_concepto6         = 'TASA_NOM',
             ap_concepto6_val     = isnull(@w_tasa,0)
         where ap_operacion       = @w_cu_operacion_anterior 
      end
   end
   
   update ca_amortizacion_proyectada 
   set   ap_estado = es_descripcion
   from  ca_dividendo, ca_estado
   where di_operacion = @w_cu_operacion_anterior 
   and   ap_operacion = @w_cu_operacion_anterior 
   and   ap_cuota     = di_dividendo
   and   di_estado    = es_codigo
   
 COMMIT TRAN
   
   goto SIGUIENTE
   
   ERROR:
   begin
      
      while @@trancount > 0 ROLLBACK TRAN
      
      exec sp_errorlog 
           @i_fecha     = @i_fecha_inicial,
           @i_error     = @w_error, 
           @i_usuario   = @s_user, 
           @i_tran      = 7999,
           @i_tran_name = @w_sp_name,
           @i_cuenta    = @w_op_banco,
           @i_rollback  = 'S'
      while @@trancount > 0 COMMIT TRAN
      goto SIGUIENTE
   end


   SIGUIENTE:
   begin
      fetch cursor_operacion into
      @w_op_operacion,   @w_op_banco,   @w_op_toperacion,   @w_op_moneda,       @w_op_cliente,    
      @w_op_nombre,   @w_op_direccion,@w_op_oficina,      @w_op_fecha_liq,   @w_op_monto,
      @w_op_plazo,      @w_op_tplazo,   @w_op_fecha_fin,   @w_op_tdividendo,   @w_op_tipo_amortizacion,
      @w_op_sector,   @w_op_fecha_ult_proceso
   end

end --while @@fetch_status = 0 cursor: cursor_operacion 
close cursor_operacion
deallocate cursor_operacion 


return 0



ERROR1:
PRINT 'tablamor.sp ATENCION!!! Revisar los errores, proceso no Existoso' + cast(@w_error as varchar)
insert into ca_errorlog
      (er_fecha_proc,      er_error,      er_usuario,
       er_tran,            er_cuenta,     er_descripcion,
       er_anexo)
values(@i_fecha_inicial,   @w_error,      @s_user,
       0,                  '',             'ERROR GENERANDO LA TABLA DE AMORTIZACION  UVR-PROYECTADA POR BATCH',
       'ERROR EN PARAMETROS'
       ) 
       
return 0

go

