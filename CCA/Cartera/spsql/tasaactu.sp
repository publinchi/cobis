/************************************************************************/
/*   Archivo             : tasaactu.sp                                  */
/*   Stored procedure    : sp_tasas_actuales                            */
/*   Base de datos       : cob_cartera                                  */
/*   Producto            : Cartera                                      */
/*   Disenado por        : Elcira Pelaez Burbano                        */
/*   Fecha de escritura  : AGO/05/2001                                  */
/************************************************************************/
/*   IMPORTANTE                                                         */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBISCORP'.                                                       */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBISCORP o su representante.             */
/************************************************************************/  
/*   PROPOSITO                                                          */
/*   Retorna la tasa actual de una operacion  Efectiva y  Nominal       */
/* Segun la combinaionde de tipo de puntos y tipo de tasa               */
/************************************************************************/ 
/*   CAMBIOS                                                            */
/*   FECHA           AUTOR               MODIFICACION                   */
/*   11/02/2002   Luis Alfonso Mayorga     Gap Pequeños prouctores      */
/*   11/18/2005   ElciraPelaez           Manejo para temporales         */
/*   May 2007     Fabian Quintero        Defecto 8236                   */
/*   03-ABR-2020  Luis Ponce            CDIG No manejar tasa equivalente*/
/*   01-Jun-2022  Guisela Fernandez     Se comenta prints               */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_tasas_actuales')
   drop proc sp_tasas_actuales
go

create proc sp_tasas_actuales
   @i_operacionca       int       = null,
   @i_referencia        catalogo  = null,
   @i_concepto          catalogo  = null,
   @i_fecha_proceso     datetime  = null,
   @i_dias_recalcular   int       = null,
   @i_reajuste          char(1)   = 'N',
   @i_intant            char(1)   = 'N',
   @i_temporales        char(1)   = 'N',
   @o_tasa_nom          float     = null output,
   @o_tasa_efa          float     = null output,
   @o_valor_tasa_ref    float     = null output,
   @o_fecha_tasa_ref    datetime  = null output,
   @o_ts_tasa_ref       catalogo  = null output
as
declare   
   @w_error              int,
   @w_tasa_int           float,
   @w_num_periodo_d      smallint,
   @w_periodo_d          catalogo,
   @w_forma_pago         char(1),
   @w_concepto           catalogo,
   @w_sector             catalogo,
   @w_modalidad_o        char(1),
   @w_modalidad_efa      char(1),
   @w_periodicidad_o     char(1),
   @w_periodicidad_efa   char(1),
   @w_modalidad_d        char(1),
   @w_tipopuntos         char(1),
   @w_tipopuntos_o       char(1),
   @w_tipotasa_o         char(1),
   @w_base_calculo       char(1),
   @w_factor             float,
   @w_tasa_nom           float,
   @w_tasa_aux           float,
   @w_tasa_efa           float,
   @w_tipo_amortizacion  varchar(10),
   @w_dias_anio          smallint,
   @w_moneda             tinyint,
   @w_num_dec            tinyint,
   @w_num_dec_tapl       tinyint,
   @w_convierte_tasa     char(1),
   @w_nombre_tasa        catalogo,
   @w_ro_tipo_puntos     char(1),
   @w_signo              char(1),
   @w_tipo               char(1),
   @w_tramite            int,
   @w_cliente             int,      --LAMH
   @w_peq_productor      varchar(24), --LAMH
   @w_fec_mes_anterior   datetime,   --LAMH
   @w_fec_inicial        datetime,   --LAMH
   @w_encontro             tinyint,   --LAMH
   @w_dia                tinyint,   --LAMH
   @w_contador             integer,   --LAMH
   @w_fecha_ini          datetime,
   @w_bandera            char(1),
   @w_fecha              datetime,
   @w_op_migrada         cuenta

-- PERIODICIDAD ANUAL
select  @w_periodicidad_efa = pa_char
from    cobis..cl_parametro
where   pa_nemonico = 'PAN' --PERIODICIDAD ANUAL
and     pa_producto = 'CCA'
set transaction isolation level read uncommitted

select @w_modalidad_efa = 'V' --VENCIDA

--- DATOS DE LA OPERACION 

if @i_temporales = 'N'
begin
   select @w_num_periodo_d     = op_periodo_int,
          @w_periodo_d         = op_tdividendo,
          @w_sector            = op_sector,
          @w_tipo_amortizacion = op_tipo_amortizacion,
          @w_dias_anio         = op_dias_anio,
          @w_base_calculo      = op_base_calculo,
          @w_moneda            = op_moneda,
          @w_tipo              = op_tipo,
          @w_tramite           = op_tramite,
          @w_convierte_tasa    = op_convierte_tasa,
          @w_cliente            = op_cliente,   -- LAMH
          @w_fecha_ini         = op_fecha_ini,
          @w_bandera           = isnull(op_pproductor,'N'),  --Para sacr tasa especial para pequeños productores
          @w_op_migrada        = op_migrada
   from   ca_operacion
   where  op_operacion   = @i_operacionca
end
ELSE
begin
   select @w_num_periodo_d     = opt_periodo_int,
          @w_periodo_d         = opt_tdividendo,
          @w_sector            = opt_sector,
          @w_tipo_amortizacion = opt_tipo_amortizacion,
          @w_dias_anio         = opt_dias_anio,
          @w_base_calculo      = opt_base_calculo,
          @w_moneda            = opt_moneda,
          @w_tipo              = opt_tipo,
          @w_tramite           = opt_tramite,
          @w_convierte_tasa    = opt_convierte_tasa,
          @w_cliente           = opt_cliente,   -- LAMH
          @w_fecha_ini         = opt_fecha_ini,
          @w_bandera           = isnull(opt_pproductor,'N'),  --Para sacr tasa especial para pequeños productores
          @w_op_migrada        = opt_migrada
   from   ca_operacion_tmp
   where  opt_operacion   = @i_operacionca
end

-- DECIMALES
exec @w_error = sp_decimales
     @i_moneda      = @w_moneda,
     @o_decimales   = @w_num_dec out

if @w_error <> 0
   return @w_error

-- DATOS DEL CONCEPTO ENVIADO
if @i_reajuste = 'N'
begin
    if @i_temporales = 'N'
    begin
        select @w_forma_pago      = ro_fpago,
               @w_num_dec_tapl    = ro_num_dec,
               @w_tipopuntos      = ro_tipo_puntos,
               @w_signo           = isnull(ro_signo,'+'),
               @w_factor          = isnull(ro_factor,0)
        from   ca_rubro_op
        where  ro_operacion  = @i_operacionca
        and    ro_concepto   = @i_concepto
        and    ro_referencial is not null  --SOLO SI TIENE UN VALOR A APLICAR
      
        if @@rowcount = 0
           return 0
    end
    ELSE
    begin
        select @w_forma_pago      = rot_fpago,
               @w_num_dec_tapl    = rot_num_dec,
               @w_tipopuntos      = rot_tipo_puntos,
               @w_signo           = isnull(rot_signo,'+'),
               @w_factor          = isnull(rot_factor,0)
        from  ca_rubro_op_tmp
        where rot_operacion  = @i_operacionca
        and   rot_concepto   = @i_concepto
        and   rot_referencial is not null  --SOLO SI TIENE UN VALOR A APLICAR
     
        if @@rowcount = 0
        begin
		    --GFP se suprime print
            --PRINT 'No existe concepto en ca_rubro_op_tmp' + cast(@i_concepto as varchar)
            return 0
        end
    end
end
ELSE
begin
    select @w_signo      = red_signo,
           @w_factor     = red_factor,
           @w_forma_pago = ro_fpago,
           @w_tipopuntos = re_desagio   ---Negociados en el reajuste
    from   ca_rubro_op, ca_reajuste, ca_reajuste_det
    where  re_operacion = ro_operacion
    and    red_operacion = ro_operacion
    and    red_operacion  = re_operacion
    and    red_concepto = ro_concepto
    and    red_referencial = @i_referencia
    and    ro_operacion = @i_operacionca
    and    re_fecha     = @i_fecha_proceso --FECHA DE REAJUSTE
    and    re_secuencial= red_secuencial
    and    red_concepto = @i_concepto
end

if @w_factor >= 0
   if @w_tipopuntos not in ('N','E','B')
      select @w_tipopuntos = 'B'

 
select @w_modalidad_o         = tv_modalidad,          --modalidad tasa referencial
       @w_periodicidad_o      = tv_periodicidad ,      --periodicidad tasa referencial
       @w_tipotasa_o          = tv_tipo_tasa,          --tipo (efectiva, nominal)tasa referencial 
       @w_nombre_tasa         = ltrim(rtrim(tv_nombre_tasa)),        -- tasa referencial
       @w_num_dec_tapl        = vd_num_dec             --Decimales para redondeo
from   ca_valor_det, ca_tasa_valor
where  vd_tipo       = @i_referencia
and    vd_sector     = @w_sector
and    vd_referencia = tv_nombre_tasa

if @@rowcount = 0 or @w_tipotasa_o = 'E' 
begin
    select @w_periodicidad_o = @w_periodicidad_efa, 
           @w_modalidad_o    = @w_modalidad_efa 
end

if @w_num_dec_tapl is null
   select @w_num_dec_tapl = 6

--ARREGLO QUE DEBE SER UNICAMENTE PARA LAS OPERACIONES MIGRADAS Y PASIVAS
if @w_op_migrada is not null and @w_nombre_tasa = 'DTFTA' and @w_tipo = 'R'
   select @w_tipopuntos = 'E'


if @w_bandera = 'S' and @w_op_migrada is not null
begin
    select @w_fec_mes_anterior = dateadd(mm,-1,@i_fecha_proceso)
   
    select @w_fec_inicial = convert(varchar(2),datepart(mm,@w_fec_mes_anterior)) + '/' + convert(varchar(4),datepart(yy,@w_fec_mes_anterior)) + '/01'   
   
    while  1 = 1
    begin 
        select @w_dia = datepart(dw,@w_fec_inicial) 
      
        if @w_dia <> 2  --(2 = lunes)
        begin
            select @w_fec_inicial = dateadd(dd,1,@w_fec_inicial)  -- incompleta 
        end
        ELSE
        begin
            break     --completa
        end
    end
   
    select @w_fec_inicial = dateadd(dd,7,@w_fec_inicial)
   
    while @w_contador = 0 
    begin
        select @w_contador = count(*) 
        from   cobis..cl_dias_feriados
        where  df_ciudad = 11001
        and    df_fecha = @w_fec_inicial
        set transaction isolation level read uncommitted
      
       if @w_contador <> 0 
       begin
           select @w_fec_inicial = dateadd(dd,1,@w_fec_inicial)
       end        
    end

    select @w_fecha = max(vr_fecha_vig)
    from   ca_valor_referencial
    where  vr_tipo = @w_nombre_tasa
    and    vr_fecha_vig  <= @w_fec_inicial
   
    select @w_tasa_int = vr_valor
    from   ca_valor_referencial
    where  vr_tipo    = @w_nombre_tasa
    and    vr_secuencial = (select max(vr_secuencial)
                            from ca_valor_referencial
                            where vr_tipo     = @w_nombre_tasa
                            and vr_fecha_vig  = @w_fecha)
end
ELSE
begin
   
    select @w_fecha = max(vr_fecha_vig)
    from   ca_valor_referencial
    where  vr_tipo = @w_nombre_tasa
    and    vr_fecha_vig  <= @i_fecha_proceso
 
   
    
       
    if @w_fecha is null 
    begin
	    --GFP se suprime print
        --PRINT 'tasaactu.sp No esxite tasa para la fecha: ' + cast(@i_fecha_proceso as varchar) + ' refe ' + cast(@w_nombre_tasa as varchar)
        return 701177 
    end
   
    select @w_tasa_int = vr_valor
    from   ca_valor_referencial
    where  vr_tipo = @w_nombre_tasa
    and vr_secuencial = (select max(vr_secuencial)
                         from ca_valor_referencial
                         where vr_tipo = @w_nombre_tasa
                         and   vr_fecha_vig  = @w_fecha)
   
   if @w_tasa_int  is null 
    begin
	  ----GFP se suprime print
      --PRINT 'tasaactu.sp No esxite tasa para @w_fecha , refe ' + cast(@w_fecha as varchar) + cast(@w_nombre_tasa as varchar)
      return 701177 
   end
   
   ---PRINT 'tasaactu.sp @w_tasa_int ' + CAST(@w_tasa_int AS VARCHAR) + ' @w_fecha ' + CAST(@w_fecha AS VARCHAR)
   
end 

if @w_forma_pago = 'P'
   select @w_modalidad_d = 'V' --VENCIDO
ELSE
begin
   if @w_forma_pago = 'A'
      select @w_modalidad_d = 'A' --ANTICIPADO
end

if @i_reajuste = 'N' and @i_intant = 'S'
begin
   select @w_num_periodo_d = @i_dias_recalcular,
          @w_periodo_d     = 'D'
end

if @w_tipopuntos = 'N' and @w_tipotasa_o = 'E' 
begin
   exec @w_error    =  sp_conversion_tasas_int
        @i_base_calculo   = @w_base_calculo,
        @i_dias_anio      = @w_dias_anio,
        @i_periodo_o      = 'A',
        @i_num_periodo_o  = 1, 
        @i_modalidad_o    = 'V',
        @i_tasa_o         = @w_tasa_int,
        @i_periodo_d      = @w_periodo_d,
        @i_num_periodo_d  = @w_num_periodo_d,
        @i_modalidad_d    = @w_modalidad_d, ---'A',
        @i_num_dec        = @w_num_dec_tapl,
        @o_tasa_d         = @w_tasa_nom output  -- NOMINAL DE TASA REFERENCIAL
   
   
   if @w_error <> 0
   begin
       return @w_error
   end
 
   if @w_signo = '+'
      select @w_tasa_nom = @w_tasa_nom + @w_factor
   if @w_signo = '-'
      select @w_tasa_nom = @w_tasa_nom - @w_factor
   if @w_signo = '*'
      select @w_tasa_nom = @w_tasa_nom * @w_factor
   if @w_signo = '/'
      select @w_tasa_nom = @w_tasa_nom / @w_factor
   
   exec @w_error =  sp_conversion_tasas_int
        @i_base_calculo   = @w_base_calculo,
        @i_dias_anio      = @w_dias_anio,
        @i_periodo_o      = @w_periodo_d,
        @i_num_periodo_o  = @w_num_periodo_d,
        @i_modalidad_o    = @w_modalidad_d,
        @i_tasa_o         = @w_tasa_nom,
        @i_periodo_d      = 'A',
        @i_num_periodo_d  = 1,
        @i_modalidad_d    = 'V',
        @i_num_dec        = @w_num_dec_tapl,
        @o_tasa_d         = @w_tasa_efa output
   
   if @w_error <> 0
      return @w_error
end ---PUNTOS NOMINALES 

if @w_tipopuntos = 'E' and  @w_tipotasa_o = 'N' 
begin
   exec @w_error =  sp_conversion_tasas_int
        @i_base_calculo   = @w_base_calculo,
        @i_dias_anio      = @w_dias_anio,
        @i_periodo_o      = @w_periodicidad_o,
        @i_num_periodo_o  = 1, 
        @i_modalidad_o    = @w_modalidad_o,    
        @i_tasa_o         = @w_tasa_int,
        @i_periodo_d      = 'A',
        @i_num_periodo_d  = 1,
        @i_modalidad_d    = 'V',
        @i_num_dec        = @w_num_dec_tapl,
        @o_tasa_d         = @w_tasa_efa output
   
   if @w_error <> 0
      return @w_error
   
   if @w_signo = '+'
      select @w_tasa_aux = @w_tasa_efa + @w_factor
   if @w_signo = '-'
      select @w_tasa_aux = @w_tasa_efa - @w_factor
   if @w_signo = '*'
      select @w_tasa_aux = @w_tasa_efa * @w_factor
   if @w_signo = '/'
      select @w_tasa_aux = @w_tasa_efa / @w_factor
   
   select @w_tasa_efa = @w_tasa_aux
                
   exec @w_error =  sp_conversion_tasas_int
        @i_base_calculo   = @w_base_calculo,
        @i_dias_anio      = @w_dias_anio,
        @i_periodo_o      = 'A',
        @i_num_periodo_o  = 1, 
        @i_modalidad_o    = 'V',
        @i_tasa_o         = @w_tasa_aux,
        @i_periodo_d      = @w_periodo_d,
        @i_num_periodo_d  = @w_num_periodo_d,
        @i_modalidad_d    = @w_modalidad_d,
        @i_num_dec        = @w_num_dec_tapl,
        @o_tasa_d         = @w_tasa_nom output
   
   if @w_error <> 0
      return @w_error
end

---EPB: MAR-10-2002
if (  @w_tipotasa_o = 'E' and @w_tipopuntos = 'B') 
begin
   if @w_signo = '+'
      select @w_tasa_efa = @w_tasa_int + @w_factor
   if @w_signo = '-'
      select @w_tasa_efa = @w_tasa_int - @w_factor
   if @w_signo = '*'
      select @w_tasa_efa = @w_tasa_int * @w_factor
   if @w_signo = '/'
      select @w_tasa_efa = @w_tasa_int / @w_factor
   
   exec @w_error    =  sp_conversion_tasas_int
        @i_base_calculo   = @w_base_calculo,
        @i_dias_anio      = @w_dias_anio,
        @i_periodo_o      = 'A',
        @i_num_periodo_o  = 1, 
        @i_modalidad_o    = 'V',
        @i_tasa_o         = @w_tasa_efa,
        @i_periodo_d      = @w_periodo_d,
        @i_num_periodo_d  = @w_num_periodo_d,
        @i_modalidad_d    = @w_modalidad_d, 
        @i_num_dec        = @w_num_dec_tapl,
        @o_tasa_d         = @w_tasa_nom output  -- NOMINAL DE TASA REFERENCIAL EFECTIVA + PUNTOS
   
   if @w_error <> 0
      return @w_error
  
end 

if (@w_tipotasa_o = 'N' and  @w_tipopuntos in ('N','B') )
begin
   if @w_signo = '+'
      select @w_tasa_nom = @w_tasa_int + @w_factor
   if @w_signo = '-'
      select @w_tasa_nom = @w_tasa_int - @w_factor
   if @w_signo = '*'
      select @w_tasa_nom = @w_tasa_int * @w_factor
   if @w_signo = '/'
      select @w_tasa_nom = @w_tasa_int / @w_factor

   exec @w_error =  sp_conversion_tasas_int
        @i_base_calculo   = @w_base_calculo,
        @i_dias_anio      = @w_dias_anio,
        @i_periodo_o      = @w_periodicidad_o,
        @i_num_periodo_o  = 1,
        @i_modalidad_o    = @w_modalidad_o,
        @i_tasa_o         = @w_tasa_nom,  
        @i_periodo_d      = 'A',
        @i_num_periodo_d  = 1,
        @i_modalidad_d    = 'V',
        @i_num_dec        = @w_num_dec_tapl,
        @o_tasa_d         = @w_tasa_efa output  ---TASA EFECTIVA DE LA REFERENCIAL + PUNTOS
   
   if @w_error <> 0
      return @w_error
   
   --LPO CDIG No manejar tasa equivalente INICIO
   /*
   exec @w_error    =  sp_conversion_tasas_int
        @i_base_calculo   = @w_base_calculo,
        @i_dias_anio      = @w_dias_anio,
        @i_periodo_o      = 'A',
        @i_num_periodo_o  = 1, 
        @i_modalidad_o    = 'V',
        @i_tasa_o         = @w_tasa_efa,
        @i_periodo_d      = @w_periodo_d,
        @i_num_periodo_d  = @w_num_periodo_d,
        @i_modalidad_d    = @w_modalidad_d, 
        @i_num_dec        = @w_num_dec_tapl,
        @o_tasa_d         = @w_tasa_nom output  -- NOMINAL DE TASA REFERENCIAL EFECTIVA + PUNTOS
   
   if @w_error <> 0
      return @w_error*/
   --LPO CDIG No manejar tasa equivalente FIN      
end 


--EPB:22ABR2004
if @w_tipopuntos = 'E' and  @w_tipotasa_o = 'E' 
begin
   if @w_signo = '+'
      select @w_tasa_efa = @w_tasa_int + @w_factor
   if @w_signo = '-'
      select @w_tasa_efa = @w_tasa_int - @w_factor
   if @w_signo = '*'
      select @w_tasa_efa = @w_tasa_int * @w_factor
   if @w_signo = '/'
      select @w_tasa_efa = @w_tasa_int / @w_factor

   
   exec @w_error    =  sp_conversion_tasas_int
        @i_base_calculo   = @w_base_calculo,
        @i_dias_anio      = @w_dias_anio,
        @i_periodo_o      = 'A',
        @i_num_periodo_o  = 1, 
        @i_modalidad_o    = 'V',
        @i_tasa_o         = @w_tasa_efa,
        @i_periodo_d      = @w_periodo_d,
        @i_num_periodo_d  = @w_num_periodo_d,
        @i_modalidad_d    = @w_modalidad_d, ---'A',
        @i_num_dec        = @w_num_dec_tapl,
        @o_tasa_d         = @w_tasa_nom output  -- NOMINAL DE TASA REFERENCIAL
   
   if @w_error <> 0 
      return @w_error
end

--EPB:22ABR2004

if @w_tasa_nom is null or @w_tasa_efa is null
begin
   --GFP se suprime print
   --PRINT 'tasaactu.sp No genero tasa Nominal ni Efectiva'
   return 701177
end

select @o_tasa_nom = round(@w_tasa_nom, @w_num_dec_tapl)
select @o_tasa_efa = round(@w_tasa_efa, @w_num_dec_tapl)
select @o_valor_tasa_ref = @w_tasa_int
select @o_fecha_tasa_ref = @w_fecha
select @o_ts_tasa_ref = @w_nombre_tasa

if @o_tasa_nom < 0
   select @o_tasa_nom = 0,
          @o_tasa_efa = 0

return 0
go
