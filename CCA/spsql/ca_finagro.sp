/************************************************************************/
/*      Archivo:                ca_finagro.sp                           */
/*      Stored procedure:       sp_finagro                              */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Liana Coto                              */
/*      Fecha de escritura:     NOV/2014                                */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.							                            */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*				         PROPOSITO				                        */
/*	  GENERACION DE REPORTE PLANO PARA DESEMBOLSOS CORRESPONDIENTES     */
/*    LINEAS DE CREDITO FINAGRO                                         */
/************************************************************************/
/*                         ACTUALIZACIONES                              */
/*    FECHA              AUTOR                     CAMBIO               */
/*    NOV/2014         L. Coto        REQ 477 FINAGRO (Emision Inicial) */
/*    AGO/2015         Elcira Pelaez  REQ 500 Bancamia                  */
/*    SEP/2015         Acelis         Inc471                            */
/************************************************************************/

use 
cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_finagro')
   drop proc sp_finagro 
go

create proc sp_finagro (
@i_fecha     datetime = null,   --FECHA DE PROCESO
@i_banco     varchar(20),       --OPERACION DESEMBOLSADA / REVERSADA
@i_operacion char(1)            --(D)desembolso (R)reversa (L) Cambio de Linea FINAGRO a FINAGRO
)

as 
declare
@w_sp_name            varchar(30),
@w_error              int,
@w_maxreg             int,
@w_sec                int,
@w_mensaje            descripcion,
@w_toperacion         catalogo,
@w_tipo_produtor      varchar(10),
@w_par_fag_des        varchar(12),
@w_par_fag_uni        varchar(12),
@w_linea_destino      catalogo,
@w_codlinea_anterior  catalogo,
@w_linea_anterior     catalogo,
@w_saldo_cap          money,
@w_div_cambio_linea   smallint,
@w_operacionca        int,
@w_tramite            int,
@w_tipo_prod          int


select @w_sp_name    = 'sp_finagro'
       
if @i_operacion = 'D' -- Opcion -D- desembolso
begin
   --PARAMETRO DE LA GARANTIA DE FAG PERIODICA / ANUAL
   select @w_par_fag_des = pa_char
   from cobis..cl_parametro with (nolock)
   where pa_producto = 'CCA'
   and pa_nemonico   = 'CMFAGD'
   
   if @@ERROR <> 0
   begin
      --print 'NO EXISTE EL PARAMETRO DE GARANTIA FAG PERIODICA ANUAL'
      return 723909
   end

   --PARAMETRO DE LA GARANTIA DE FAG PERIODICA UNICA
   select @w_par_fag_uni = pa_char
   from cobis..cl_parametro with (nolock)
   where pa_producto = 'CCA'
   and pa_nemonico   = 'COMUNI'   
   
   if @@ERROR <> 0
   begin
      --print 'NO EXISTE EL PARAMETRO DE GARANTIA FAG PERIODICA UNICA'
      return 723909
   end
   
   --OBTENIENDO DATOS DEL DÍA PARA REPORTE
   select * into #ca_operacion
   from ca_operacion
   where op_banco     = @i_banco   
   and   op_fecha_ini = @i_fecha 
   and   op_banco     not in (select of_pagare from cob_cartera..ca_opera_finagro where of_procesado in ('P', 'L'))
   
   if @@ERROR <> 0
   begin
      --print 'ERROR AL INSERTAR EN TABLA #ca_operacion'
      return 723909
   end   

   --OBTENIENDO DATOS BASICOS DEL CLIENTE Y OPERACION CAMPOS 2,5,6 y 7 
   insert into cob_cartera..ca_opera_finagro (
          of_ente,   of_iden_cli,    of_tipo_iden , of_raz_social,
          of_pagare, of_procesado,  of_indicativo_fag )
   select 
        en_ente,   en_ced_ruc,   case en_tipo_ced when 'CC' then 2 when 'N' then 1 else ' ' end, 
		(p_p_apellido + ' ' + p_s_apellido + ' ' + en_nombre),
        op_banco, 'I',  'N' 
   from  #ca_operacion,  cobis..cl_ente
   where op_cliente = en_ente
   and   op_banco   = @i_banco

   if @@ERROR <> 0
   begin
      --print 'ERROR AL INSERTAR DATOS BASICOS -- FINAGRO'
      return 723909
   end
   
   --TASA DE INTERES CAMPO 19
   update cob_cartera..ca_opera_finagro
   set of_calc_tasa_tot = ro_porcentaje_efa
   from  cob_cartera..ca_rubro_op, cob_cartera..ca_opera_finagro, 
         #ca_operacion
   where op_operacion = ro_operacion
   and   op_banco     = of_pagare
   and   ro_concepto  = 'INT'
   and   op_cliente   = of_ente   
      
   --OBTENIENDO LINEA FINAGRO CAMPO 1 REQ 479 
   update cob_cartera..ca_opera_finagro
   set of_lincre = convert(int,s.codigo)
   from cob_credito..cr_corresp_sib s, #ca_operacion ca, cobis..cl_tabla t, cobis..cl_catalogo c  
   where s.descripcion_sib = t.tabla
   and t.codigo            = c.tabla
   and s.tabla             = 'T301'
   and c.codigo            = ca.op_toperacion
   and of_pagare           = ca.op_banco
   and c.estado            = 'V'
   and s.limite_inf        in (select convert(int,tr_tipo_productor)  
                               from cob_credito..cr_tramite
                               where ca.op_banco   = @i_banco
                               and   tr_tramite    = ca.op_tramite)
      
   if @@ERROR <> 0
   begin
      --print 'ERROR AL ACTUALIZAR LINEA DE CREDITO -- FINAGRO'
      return 723909
   end   
   
   --OBTENIENDO VALOR DE ACTIVOS DE BALANCE CAMPOS 8 Y 27
   select 'valor'    = SUM(if_total),
           'banco_v' = op_banco
   into #activo
   from cob_credito..cr_inf_financiera, #ca_operacion
   where if_nivel1   = 'ACT'
   and   op_tramite  = if_tramite 
   and if_nivel2     is null
   group by op_banco
   
   if @@ERROR <> 0
   begin
      --print 'ERROR AL INSERTAR EN LA TABLA  #activo'
      return 723909
   end
   
   update cob_cartera..ca_opera_finagro
   set   of_monto_act     = valor ,
         of_val_act       = valor 
   from #activo, cob_cartera..ca_opera_finagro, #ca_operacion
   where op_banco  = banco_v 
   and   of_pagare = op_banco
   
   if @@ERROR <> 0
   begin
      --print 'ERROR AL ACTUALIZAR MONTO ACTIVO -- FINAGRO'
      return 723909
   end
   
   --OBTENIENDO FECHA DE BALANCE Y FECHA DE ACTIVOS CAMPOS 28 Y 29
   select 'fecha' = MAX(convert(varchar(10),ba_fecha_reg,103)),
          'banco_f' = op_banco
   into #fecha
   from cob_credito..cr_det_inf_financiera, 
        cob_credito..cr_inf_financiera , #ca_operacion, cobis..cl_balance
   where op_tramite    = if_tramite 
   and if_microempresa = dif_microempresa
   and if_codigo       = dif_inf_fin
   and if_nivel1       = 'ACT'
   and ba_cliente      = op_cliente 
   group by op_banco
   
   if @@ERROR <> 0
   begin
      --print 'ERROR AL INSERTAR EN LA TABLA  #fecha'
      return 723909
   end
   
   update cob_cartera..ca_opera_finagro
   set   of_fecha_balance = fecha,
         of_fecha_act     = fecha
   from #fecha, cob_cartera..ca_opera_finagro, #ca_operacion
   where op_banco  = banco_f 
   and   of_pagare = op_banco
   
   if @@ERROR <> 0
   begin
      --print 'ERROR AL ACTUALIZAR FECHA DE BALANCE -- FINAGRO'
      return 723909
   end
   
   --OBTENIENDO DIRECCION DEL CLIENTE DE RESIDENCIA CAMPO 9
   update cob_cartera..ca_opera_finagro
   set   of_dir_cli = di_descripcion      --P9
   from #ca_operacion, cob_cartera..ca_opera_finagro, 
        cobis..cl_direccion
   where op_cliente        = di_ente
   and   of_ente           = op_cliente
   and   di_tipo           = '002'  -- De la casa
   and   op_banco          = of_pagare  

   if @@ERROR <> 0
   begin
      --print 'ERROR AL ACTUALIZAR DIRECCION DE RESIDENCIA -- FINAGRO'
      return 723909
   end

   --OBTENIENDO DIRECCION DEL CLIENTE Y CODIGO DE CUIDAD NEGOCIO -- CAMPOS 4 y 30
   update cob_cartera..ca_opera_finagro
   set   of_ciudad        = di_ciudad,      --P4
         of_dir_inversion = di_descripcion  --P30
   from #ca_operacion, cob_cartera..ca_opera_finagro, 
        cobis..cl_direccion
   where op_cliente    = di_ente
   and   of_ente       = op_cliente
   and   di_tipo       = '011' -- de negocio
   and   op_banco      = of_pagare 

   if @@ERROR <> 0
   begin
      --print 'ERROR AL ACTUALIZAR DIRECCION DE NEGOCIO Y CODIGO DE CIUDAD --  FINAGRO'
      return 723909
   end

   --OBTENIENDO CAPITAL OTORGADO CAMPOS 18 y 23, OFICINA ORIGEN DEL CREDITO CAMPO 31, PLAZO CAMPO 10 , FECHA DE VENCIMIENTO CAMPO 12, PERIODICIDAD CAP/INT CAMPOS 13 Y 16 
   update cob_cartera..ca_opera_finagro
   set   of_cap_total        = op_monto,                                      --P18
         of_inv_rubro        = op_monto,                                      --P23
         of_cod_oficina      = op_oficina,                                    --P31
         of_plazo            = ((td_factor / 30) * op_plazo),                 --P10 (en meses)
         of_frec_cap         = ((td_factor / 30) * op_periodo_cap),           --P13 (en meses)
         of_frec_int         = ((td_factor / 30) * op_periodo_int),           --P16 (en meses)
         of_fecha_ven_final  = convert(varchar(10),op_fecha_fin,103)          --P12 
   from  #ca_operacion,  cob_cartera..ca_opera_finagro, cob_cartera..ca_tdividendo
   where op_cliente  = of_ente
   and   op_banco    = of_pagare 
   and   op_tplazo   = td_tdividendo

   if @@ERROR <> 0
   begin
      --print 'ERROR AL ACTUALIZAR CAPITAL DESEMBOLSO -- FINAGRO'
      return 723909
   end
   
   --OBTENIENDO FECHA DE PRIMER VENCIMIENTO CAMPO 11
   update cob_cartera..ca_opera_finagro
   set   of_fecha_pri_ven    = convert(varchar(10),di_fecha_ven ,103)     --P11
   from  #ca_operacion, ca_dividendo, ca_opera_finagro
   where op_cliente      = of_ente
   and   di_operacion    = op_operacion
   and   di_dividendo    = 1
   and   op_banco        = of_pagare

   if @@ERROR <> 0
   begin
      --print 'ERROR AL ACTUALIZAR FECHA DE PRIMER VENCIMIENTO -- FINAGRO'
      return 723909
   end  

   --OBTENIENDO CANTIDAD DE ABONOS A CAPITAL CAMPO 14
   select 'capital'   = count(1),
          'op_banco'  = op_banco,
          'cliente'   = op_cliente
   into #cant_cap
   from #ca_operacion, cob_cartera..ca_dividendo
   where op_operacion = di_operacion
   and   di_de_capital   =  'S'
   group by op_banco,op_cliente

   if @@ERROR <> 0
   begin
      --print 'ERROR AL INSERTAR EN TABLA #cant_cap'
      return 723909
   end

   update cob_cartera..ca_opera_finagro
   set   of_abono_cap  = b.capital
   from #ca_operacion a, #cant_cap b, 
        cob_cartera..ca_opera_finagro
   where a.op_banco       = b.op_banco 
   and   of_pagare        = a.op_banco
   and   a.op_cliente     = b.cliente 
   and   of_ente          = a.op_cliente
	
   if @@ERROR <> 0
   begin
      --print 'ERROR AL ACTUALIZAR CANTIDAD DE ABONOS A CAPITAL --FINAGRO'
      return 723909
   end

   --OBTENIENDO CANTIDAD CUOTAS DE GRACIA DE CAPITAL CAMPO 15
   select 'capital'   = count(1),
          'op_banco'  = op_banco,
          'cliente'   = op_cliente
   into #cant_gracia_cap
   from #ca_operacion, cob_cartera..ca_dividendo
   where op_operacion   = di_operacion
   and   di_de_capital  = 'N'
   group by op_banco,op_cliente

   if @@ERROR <> 0
   begin
      --print 'ERROR AL INSERTAR EN TABLA #cant_gracia_cap'
      return 723909
   end

   update cob_cartera..ca_opera_finagro
   set   of_abono_cap  = b.capital
   from #ca_operacion a, #cant_gracia_cap b, 
        cob_cartera..ca_opera_finagro
   where a.op_banco       = b.op_banco 
   and   of_pagare        = a.op_banco
   and   a.op_cliente     = b.cliente 
   and   of_ente          = a.op_cliente
	
   if @@ERROR <> 0
   begin
      --print 'ERROR AL ACTUALIZAR CANTIDAD DE CAPITAL CON PERIODO DE GRACIA -- FINAGRO'
      return 723909
   end

   --OBTENIENDO CANTIDAD DE ABONOS A INTERESES CAMPO 17
   select 'interes'   = count(1),
          'op_banco'  = op_banco,
          'cliente'   = op_cliente
   into #cant_int
   from #ca_operacion, cob_cartera..ca_dividendo
   where op_operacion  = di_operacion
   and   di_de_interes = 'S'
   group by op_banco,op_cliente

   if @@ERROR <> 0
   begin
      --print 'ERROR AL INSERTAR EN TABLA #cant_int'
      return 723909
   end

   update cob_cartera..ca_opera_finagro
   set   of_abono_int  = b.interes
   from #ca_operacion a, #cant_int b, 
        cob_cartera..ca_opera_finagro
   where a.op_banco       = b.op_banco 
   and   of_pagare        = a.op_banco
   and   a.op_cliente     = b.cliente 
   and   of_ente          = a.op_cliente
	
   if @@ERROR <> 0
   begin
      --print 'ERROR AL ACTUALIZAR CANTIDAD DE ABONO A INTERES -- FINAGRO'
      return 723909
   end

   --OBTENIENDO FECHA DE INICIO DE LA OBLIGACIÓN CAMPO 3 Y VALOR DE PRIMERA CUOTA CAMPO 22
   update cob_cartera..ca_opera_finagro
   set   of_ini_ope          = convert(varchar(10),op_fecha_liq,103),
         of_valor_prim_cuota =  ISNULL(am_cuota,0)
   from  #ca_operacion ,  cob_cartera..ca_opera_finagro,
         cob_cartera..ca_amortizacion
   where op_cliente       = of_ente
   and   op_fecha_liq     = op_fecha_ini
   and   op_operacion     = am_operacion
   and   am_concepto      = 'CAP'
   and   am_dividendo     = 1

   if @@ERROR <> 0
   begin
      --print 'ERROR AL ACTUALIZAR VALOR PRIMERA CUOTA  Y FECHA DE DESEMBOLSO -- FINAGRO'
      return 723909
   end

   --OBTENIENDO PORCENTAJE FAG E INDICATIVO FAG CAMPO 24 Y 25
   update cob_cartera..ca_opera_finagro
   set   of_porcentaje_fag  = isnull(gp_porcentaje,0),
         of_indicativo_fag  = 'S'
   from cob_custodia..cu_custodia, cob_credito..cr_gar_propuesta,
        #ca_operacion, cob_cartera..ca_opera_finagro
   where cu_codigo_externo = gp_garantia
   and   op_tramite        = gp_tramite
   and   op_cliente        = gp_deudor
   and   cu_estado         = 'V'
   and   cu_tipo           = 2105 --FAG
   and   of_pagare         = op_banco
   
   if @@ERROR <> 0
   begin
      --print 'ERROR AL ACTUALIZAR PORCENTAJE FAG -- FINAGRO'
      return 723909
   end

   --OBTENIENDO COMISIÓN CAMPO 26
   select 'comision' = case ro_concepto_asociado when @w_par_fag_des then 'A' 
                            when @w_par_fag_uni then 'U' else ' ' end,
          'banco'    = op_banco
   into #comision 
   from cob_cartera..ca_rubro_op , #ca_operacion
   where ro_operacion         = op_operacion 
   and  ro_concepto_asociado in ('COMFAGDES', 'COMFAGUNI')
   and  ro_valor             <> 0
      
   if @@ERROR <> 0
   begin
      --print 'ERROR AL INSERTAR EN LA TABLA #comision'
      return 723909
   end
   
   update cob_cartera..ca_opera_finagro
   set of_tipo_comision = comision
   from #comision,  #ca_operacion, cob_cartera..ca_opera_finagro
   where op_banco          = banco
   and   of_pagare         = op_banco
   and   op_cliente        = of_ente 
   
   if @@ERROR <> 0
   begin
      --print 'ERROR AL ACTUALIZAR COMISION -- FINAGRO'
      return 723909
   end
   
   select ch_operacion = op_operacion,
          ch_max1_div = (max(am_dividendo) - 1),
          ch_max2_div = MAX(am_dividendo)
   into #cuota_hst   
   from #ca_operacion, cob_cartera..ca_opera_finagro, cob_cartera..ca_amortizacion
   where op_cliente = of_ente
     and am_concepto = 'CAP'
     and am_operacion = op_operacion
   GROUP BY op_operacion
   
   if @@ERROR <> 0
   begin
      --print 'ERROR AL INSERTAR EN LA TABLA -- #cuota_hst'
      return 723909
   end
   
   select operacion   = am_operacion,
          cuota_max   = am_cuota,
          dividendo_1 = am_dividendo
   into #cuota_f1
   from cob_cartera..ca_operacion,  cob_cartera..ca_opera_finagro, cob_cartera..ca_amortizacion,#cuota_hst
   where op_cliente   = of_ente
     and am_concepto  = 'CAP'
     and am_operacion = op_operacion
     and am_dividendo = ch_max1_div
     and am_operacion = ch_operacion
     and op_operacion = ch_operacion		
   
   if @@ERROR <> 0
   begin
      --print 'ERROR AL INSERTAR EN LA TABLA -- #cuota_f'
      return 723909
   end
   
   select operacion   = am_operacion,
          cuota_max   = am_cuota,
          dividendo_1 = am_dividendo
   into #cuota_f2
   from cob_cartera..ca_operacion,  cob_cartera..ca_opera_finagro, cob_cartera..ca_amortizacion,#cuota_hst
   where op_cliente   = of_ente
     and am_concepto  = 'CAP'
     and am_operacion = op_operacion
     and am_dividendo = ch_max2_div
     and am_operacion = ch_operacion
     and op_operacion = ch_operacion
   
   if @@ERROR <> 0
   begin
      --print 'ERROR AL INSERTAR EN LA TABLA -- #cuota_f'
      return 723909
   end
         
   --OBTENIENDO PRIMERA Y SEGUNDA CUOTA DESDE; PRIMERA Y SEGUNDA CUOTA HASTA CAMPOS 20,21,33,34
   update cob_cartera..ca_opera_finagro
   set   of_prim_cuota_dsd = 1,
         of_prim_cuota_hst = dividendo_1
   from #ca_operacion,  cob_cartera..ca_opera_finagro,#cuota_f1
   where op_cliente = of_ente
     and operacion  = op_operacion

   if @@ERROR <> 0
   begin
      --print 'ERROR AL ACTUALIZAR NUMERO DE CUOTAS LINEALES'
      return 723909
   end
   
   update cob_cartera..ca_opera_finagro
   set of_seg_cuota_dsd  = dividendo_1,
       of_seg_cuota_hst  = dividendo_1
   from #ca_operacion,  cob_cartera..ca_opera_finagro,#cuota_f2
   where op_cliente = of_ente
     and operacion  = op_operacion
   
   if @@ERROR <> 0
   begin
      --print 'ERROR AL ACTUALIZAR NUMERO DE CUOTAS LINEALES'
      return 723909
   end
   
   --OBTENIENDO VALOR DE LA SEGUNDA CUOTA CAMPO 35
   update cob_cartera..ca_opera_finagro
   set   of_valor_seg_cuota =  ISNULL(cuota_max,0)
   from  #ca_operacion a,  cob_cartera..ca_opera_finagro,
         #cuota_f2
   where a.op_cliente     = of_ente
   and   op_operacion     = operacion

   if @@ERROR <> 0
   begin
      --print 'ERROR AL ACTUALIZAR VALOR DE SEGUNDA CUOTA -- FINAGRO'
      return 723909
   end

   --OBTENIENDO NUMERO DE TELEFONO FIJO  CAMPO 32 
   update cob_cartera..ca_opera_finagro
   set  of_telf_cli = isnull(te_prefijo,'') + isnull(te_valor,'')
   from #ca_operacion,  cobis..cl_telefono,    
        cob_cartera..ca_opera_finagro
   where te_ente           = of_ente
   and   op_cliente        = te_ente
   and   te_tipo_telefono  = 'D' -- Telefono Fijo

   if @@ERROR <> 0
   begin
      --print 'ERROR AL ACTUALIZAR TELEFONO DE CLIENTE -- FINAGRO'
      return 723909
   end

   --OBTENIENDO NUMERO DE TELEFONO CELULAR CAMPO 36
   update cob_cartera..ca_opera_finagro
   set  of_telf_cel_cli = isnull(te_prefijo,'') + isnull(te_valor,'') 
   from #ca_operacion, cobis..cl_telefono,   
        cob_cartera..ca_opera_finagro
   where te_ente           = of_ente
   and   op_cliente        = te_ente
   and   te_tipo_telefono  = 'C' -- Celular

   if @@ERROR <> 0
   begin
      --print 'ERROR AL ACTUALIZAR TELEFONO CELULAR -- FINAGRO'
      return 723909
   end

end -- Opcion -D- desembolso

if @i_operacion = 'R' -- Opcion -R- reversa de desembolso
begin
   delete cob_cartera..ca_opera_finagro
   where of_pagare = @i_banco 
   
   if @@ERROR <> 0
   begin
      --print 'ERROR AL ELIMINAR DATOS DE REVERSA -- FINAGRO'
      return 723909
   end
end -- Opcion -R- reversa de desembolso

if @i_operacion = 'L'  ---CAmbio de Liena FINAGRO A FINAGRO
begin
   ---NUEVA LINEA
   select @w_toperacion  = op_toperacion,
          @w_operacionca  = op_operacion,
          @w_tramite     = op_tramite
   from cob_cartera..ca_operacion
   where op_banco = @i_banco
   
   
   select @w_tipo_prod = convert(int,tr_tipo_productor)
   from   cob_credito..cr_tramite
   where  tr_tramite  = @w_tramite
   
   
   select @w_linea_destino = s.codigo
   from cob_credito..cr_corresp_sib s, 
   cobis..cl_tabla t, 
   cobis..cl_catalogo c  
   where s.descripcion_sib = t.tabla
   and t.codigo            = c.tabla
   and s.tabla             = 'T301'
   and s.codigo_sib        = 'A'
   and c.codigo            = @w_toperacion
   and c.estado            = 'V' 
   and s.limite_inf        = @w_tipo_prod
   

   select @w_div_cambio_linea = min(di_dividendo)
   from cob_cartera..ca_dividendo
   where di_operacion = @w_operacionca
   and di_estado in (1,2)
   
   select @w_saldo_cap = sum(am_acumulado - am_pagado)
   from cob_cartera..ca_amortizacion
   where am_operacion =  @w_operacionca
   and  am_concepto = 'CAP'
   
   select @w_linea_anterior =  cl_linea_origen
   from cob_cartera..ca_oper_cambio_linea_x_mora
   where cl_banco = @i_banco
   
   select @w_codlinea_anterior = s.codigo
   from cob_credito..cr_corresp_sib s, 
   cobis..cl_tabla t, 
   cobis..cl_catalogo c  
   where s.descripcion_sib = t.tabla
   and t.codigo            = c.tabla
   and s.tabla             = 'T301'
   and s.codigo_sib        = 'S'  ---579
   and c.codigo            = @w_linea_anterior
   and c.estado            = 'V'    
   and s.limite_inf        = @w_tipo_prod

   update cob_cartera..ca_opera_finagro
   set of_lincre           = @w_linea_destino,
       of_linea_ant        = @w_codlinea_anterior
   where of_pagare = @i_banco 
   
   if @@ERROR <> 0
   begin
      --print 'ERROR AL MODIFICAR DATOS POR CAMBIO DE LINEA -- FINAGRO'
      return 723909
   end
   
end
  
return 0

go
