/************************************************************************/
/*      Archivo:                cargaext.sp                             */
/*      Stored procedure:       sp_envio_datos_ext                      */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Elcira Pelaez                           */
/*      Fecha de escritura:     Dic-2002                                */
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
/*      Envia informacion para impresionde extracto                     */
/************************************************************************/  
/*                              MODIFICACIONES                          */
/*      Fecha           Nombre          Proposito                       */
/*      20/Ene/2003 Luis Mayorga    Dar funcionalidad procedimiento     */
/*      17/Mar/2005  ELcira Pelaez   Paz y Salvo Deudas INDIRECTAS      */
/*      20/Ene/2006 Elcira Pelaez   --DEF5780                           */
/*      MAY-2006          EPB            NR-296                         */
/*      SEP-20-2006       EPB            def-7205 BAC                   */
/*      27/sep/06      SLievano -SLI   adicion fecha_ini_mora           */
/*      28/Ene/2011    J. Ardila       REQ 175. Pequena Empresa         */
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_envio_datos_ext')
    drop proc sp_envio_datos_ext 
go
create proc sp_envio_datos_ext
   @s_user              login,
   @s_date              datetime    = null,
   @i_cliente           int           = 0,
   @i_operacion         char(1)     = null,
   @i_siguiente         cuenta      = '',
   @i_secuencial_gar    int         = 0,
   @i_opcion            char(1)     = null,
   @i_oficina           int         = null,
   @i_extracto          char(1)     = 'N',
   @i_formato_fecha     int         = null

      
as declare 
   @w_sp_name               descripcion,
   @w_return                int,
   @w_error                 int,
   @w_cod_ciudad            int,
   @w_des_ciudad            varchar(100),
   @w_banco                 cuenta,
   @w_operacion_cartera     int,
   @w_secuencial            tinyint,
   @w_maximo                tinyint,
   @w_saldo_operacion_total money,
   @w_cobranza              catalogo,
   @w_moneda                tinyint,
   @w_num_dec               tinyint,
   @w_max_fecha_reportada   datetime,
   @w_est_vigente           tinyint,
   @w_est_vencido           tinyint,
   @w_est_cancelado         tinyint,
   @w_est_castigado         tinyint,
   @w_est_suspenso          tinyint,
   @w_est_credito           tinyint,
   @w_est_anulado           tinyint,
   @w_est_novigente         tinyint
   
--- CARGAR VALORES INICIALES 
select @w_sp_name       = 'sp_envio_datos_ext',
       @i_formato_fecha = 103   --dd/mm/yyyy por default

/* ESTADOS DE CARTERA */
exec @w_error = sp_estados_cca
@o_est_vigente    = @w_est_vigente    out,
@o_est_novigente  = @w_est_novigente  out,
@o_est_vencido    = @w_est_vencido    out,
@o_est_cancelado  = @w_est_cancelado  out,
@o_est_castigado  = @w_est_castigado  out,
@o_est_suspenso   = @w_est_suspenso   out,
@o_est_credito    = @w_est_credito    out,
@o_est_anulado    = @w_est_anulado    out

if @w_error <> 0 return @w_error

--PARA EL EXTRACTO
if @i_opcion  = '0'
begin
   if @i_operacion = 'D' begin ---Directas

      select @i_siguiente = isnull(@i_siguiente,'')
     
      set rowcount 10
      
      if @i_extracto = 'N' begin  -- JAR REQ 175      
         select 'OBLIGACION'     = exl_obligacion,
          'LINEA'                = exl_linea,
          'REESTRUCTURADO'       = exl_clase_car,
		  'TASA'                 = exl_tasa_pactada,
          'CALIFICACION'         = exl_calificacion,
          'FECHA DES'            = convert(varchar(10),exl_fecha_desembolso,101),
          'VALOR DES'            = exl_valor_desembolso,
          'SALDO CAP'            = round(exl_saldo_cap,0),--JJMD no se requiere el saldo capital sino el saldo actual
          'SALDO INT'            = exl_saldo_int,
          'SALDO MORA'           = exl_saldo_int_imo,        --10
          'TOTAL CXC'            = (exl_saldo_int + exl_saldo_int_imo),
          'SALDO INT CGT'        = exl_saldo_int_ctg,
          'SALDO MORA CGT'       = exl_saldo_ctg_imo_int,
          'TOTAL CTGE'           = (exl_saldo_int_ctg + exl_saldo_ctg_imo_int),
          'OTROS SALDOS'         = exl_saldo_otros,
          'PROV.CAP'             = exl_prov_cap,
          'PROV.INT'             = exl_prov_int,
          'PROV.OTROS'           = exl_prov_otros,
          'DIAS VENC'            = exl_dias_vencimiento,
          'FECHA LIQ'            = exl_nom_codeudor,        --20
          'ID. CODEUDOR'         = exl_iden_codeudor,
          'IDENTIFICACION'       = en_ced_ruc,
          'OFICINA'              = of_nombre, 
          'CLIENTE'              = @i_cliente,
          'DISPONIBLE'           = exl_disponible,
          'FECHA INICIO MORA'    = convert(varchar(10),exl_fecha_ini_mora,101), --SLI  26/sep/06 adicion campo
		  'TIPO CARTERA'         = exl_tipo_cartera,
		  'SUBTIPO CARTERA'      = exl_subtipo_cartera

         from  ca_extracto_linea_tmp,
               ca_operacion,
               cobis..cl_ente with (nolock), 
               cobis..cl_oficina with (nolock)
         where exl_cliente    = en_ente
         and   exl_obligacion = op_banco
         and   op_oficina     = of_oficina
         and   op_cliente     = exl_cliente
         and   exl_user       = @s_user
         and   exl_cliente    = @i_cliente
         and   exl_tipo_deuda = 'DIRECTA'
         and   exl_obligacion > @i_siguiente
         order by exl_obligacion
      end  -- if @i_extracto = 'N'
      
      -- INI JAR REQ 175
      if @i_extracto = 'S' begin      
         select          
         'CORTE'          = el_corte,                                                    -- 1
         'FECHA DESDE'    = convert(varchar(10),el_fecha_desde,@i_formato_fecha),        -- 2
         'FECHA HASTA'    = convert(varchar(10),el_fecha_hasta,@i_formato_fecha),        -- 3
         'OPERACION'      = el_banco,                                                    -- 4
         'OFICINA'        = el_oficina,                                                  -- 5
         'FECHA INI'      = convert(varchar(10),el_fecha_ini_op,@i_formato_fecha),       -- 6
         'FECHA FIN'      = convert(varchar(10),el_fecha_fin_op,@i_formato_fecha),       -- 7
         'MONTO APR'      = el_monto_apr_op,                                             -- 8
         'F.PAG.INT'      = convert(varchar(10),el_fpago_int,@i_formato_fecha),          -- 9
         'TOPERACION'     = el_toperacion,                                               -- 10
         'TASA NOMINAL'   = el_tasa_nominal,                                             -- 11
         'PERIODO'        = el_periodo,                                                  -- 12
         'TASA E.A.'      = el_tasa_efa,                                                 -- 13
         'TASA MORA'      = el_tasa_mora,                                                -- 14
         'VLR PROXIMO'    = el_vlr_prox_couta,                                           -- 15
         'SALDO'          = el_vlr_saldo,                                                -- 16
         'FECHA PROX.'    = convert(varchar(10),el_fecha_prox_cuota,@i_formato_fecha),   -- 17
         'FECHA PAGO'     = el_fecha_pago,                                               -- 18
         'FECHA TASA APL' = convert(varchar(10),el_fecha_tasa_apl,@i_formato_fecha),     -- 19
         'TASA APL'       = el_tasa_apl,                                                 -- 20
         'FECHA TASA MAX' = convert(varchar(10),el_fecha_tasa_max,@i_formato_fecha),     -- 21
         'TASA MAX. MORA' = el_tasa_max_mora,                                            -- 22
         'TASA USURA'     = el_tasa_max_usura,                                           -- 23
         'MENSAJE'        = el_mensaje,                                                  -- 24
         'BANCA'          = (select C.valor from cobis..cl_tabla T, cobis..cl_catalogo C -- 25
                              where T.tabla  = 'cl_banca_cliente'
                                and T.codigo = C.tabla
                                and C.codigo = B.el_banca)
         from  ca_extracto_linea_tmp,
               ca_extracto_linea_bat B with (nolock)
         where exl_user       = @s_user
         and   exl_cliente    = @i_cliente
         and   exl_obligacion = el_banco
         and   exl_tipo_deuda = 'DIRECTA'
         and   exl_obligacion > @i_siguiente
         order by exl_obligacion
      end -- if @i_extracto = 'S''
        
      set rowcount 0
      
      -- FIN JAR REQ 175
   end  --- if @i_operacion = 'D' begin ---Directas
      
      
   if @i_operacion = 'U' begin ---Directas UVR
      
      select @i_siguiente = isnull(@i_siguiente,'')      
      
      set rowcount 10
      
      if @i_extracto = 'N' begin  -- JAR REQ 175      
         select 'OBLIGACION'     = exl_obligacion,
          'LINEA'                = exl_linea,
          'REESTRUCTURADO'       = exl_clase_car,
          'COTIZACION'           = exl_tasa_pactada,
          'CALIFICACION'         = exl_calificacion,
          'FECHA DES'            = convert(varchar(10),exl_fecha_desembolso,101),
          'VALOR DES'            = exl_valor_desembolso,
          'SALDO CAP'            = round(exl_saldo_cap,0),
          'SALDO INT'            = exl_saldo_int,
          'SALDO MORA'           = exl_saldo_int_imo,
          'TOTAL CXC'            = (exl_saldo_int + exl_saldo_int_imo),
          'SALDO INT CGT'        = exl_saldo_int_ctg,
          'SALDO MORA CGT'       = exl_saldo_ctg_imo_int,
          'TOTAL CGT'            = (exl_saldo_int_ctg + exl_saldo_ctg_imo_int),
          'OTROS SALDOS'         = exl_saldo_otros,
          'FECHA LIQ'            = exl_nom_codeudor,
          'IDENTIFICACION'       = en_ced_ruc,
          'OFICINA'              = of_nombre, 
          'CLIENTE'              = @i_cliente,
          'DISPONIBLE'           = exl_disponible,
		  'TIPO CARTERA'         = exl_tipo_cartera,
		  'SUBTIPO CARTERA'      = exl_subtipo_cartera
         from  ca_extracto_linea_tmp,
               ca_operacion,
               cobis..cl_ente with (nolock), 
               cobis..cl_oficina with (nolock)               
         where exl_cliente    = en_ente
         and   exl_obligacion = op_banco
         and   op_oficina     = of_oficina
         and   op_cliente     = exl_cliente
         and   exl_user       = @s_user
         and   exl_cliente    = @i_cliente
         and   exl_tipo_deuda = 'DIRECTAUVR'
         and   exl_obligacion > @i_siguiente
         order by exl_obligacion
      end -- if @i_extracto = 'N'
      
      -- INI JAR REQ 175      
      if @i_extracto = 'S' begin  
         select          
         'CORTE'          = el_corte,                                                    -- 1
         'FECHA DESDE'    = convert(varchar(10),el_fecha_desde,@i_formato_fecha),        -- 2
         'FECHA HASTA'    = convert(varchar(10),el_fecha_hasta,@i_formato_fecha),        -- 3
         'OPERACION'      = el_banco,                                                    -- 4
         'OFICINA'        = el_oficina,                                                  -- 5
         'FECHA INI'      = convert(varchar(10),el_fecha_ini_op,@i_formato_fecha),       -- 6
         'FECHA FIN'      = convert(varchar(10),el_fecha_fin_op,@i_formato_fecha),       -- 7
         'MONTO APR'      = el_monto_apr_op,                                             -- 8
         'F.PAG.INT'      = convert(varchar(10),el_fpago_int,@i_formato_fecha),          -- 9
         'TOPERACION'     = el_toperacion,                                               -- 10
         'TASA NOMINAL'   = el_tasa_nominal,                                             -- 11
         'PERIODO'        = el_periodo,                                                  -- 12
         'TASA E.A.'      = el_tasa_efa,                                                 -- 13
         'TASA MORA'      = el_tasa_mora,                                                -- 14
         'VLR PROXIMO'    = el_vlr_prox_couta,                                           -- 15
         'SALDO'          = el_vlr_saldo,                                                -- 16
         'FECHA PROX.'    = convert(varchar(10),el_fecha_prox_cuota,@i_formato_fecha),   -- 17
         'FECHA PAGO'     = el_fecha_pago,                                               -- 18
         'FECHA TASA APL' = convert(varchar(10),el_fecha_tasa_apl,@i_formato_fecha),     -- 19
         'TASA APL'       = el_tasa_apl,                                                 -- 20
         'FECHA TASA MAX' = convert(varchar(10),el_fecha_tasa_max,@i_formato_fecha),     -- 21
         'TASA MAX. MORA' = el_tasa_max_mora,                                            -- 22
         'TASA USURA'     = el_tasa_max_usura,                                           -- 23
         'MENSAJE'        = el_mensaje,                                                  -- 24
         'BANCA'          = (select C.valor from cobis..cl_tabla T, cobis..cl_catalogo C -- 25
                              where T.tabla  = 'cl_banca_cliente'
                                and T.codigo = C.tabla
                                and C.codigo = B.el_banca)
         from  ca_extracto_linea_tmp,
               ca_extracto_linea_bat B with (nolock) -- JAR REQ 175
         where exl_user       = @s_user
         and   exl_cliente    = @i_cliente
         and   exl_tipo_deuda = 'DIRECTAUVR'
         and   exl_obligacion = el_banco
         and   exl_obligacion > @i_siguiente
         order by exl_obligacion
      end -- if @i_extracto = 'S'
      -- FINJAR REQ 175 
      
      set rowcount 0
   end  ---Operacion
      
      
   if @i_operacion = 'I' begin ---Indirectas
   
      if @i_extracto = 'N' begin -- JAR REQ 175
         select 'OBLIGACION'    = exl_obligacion,
          'ID. INDIRECTAS'      = exl_iden_indirectas,
          'CALIFICACION'        = exl_calificacion,
          'NOMBRE'              = exl_nom_indirectas,
          'VALOR DESEM.'        = exl_valor_desembolso,
          'SALDO CAP.'          = round(exl_saldo_cap,0),
          'SALDO INT'           = exl_saldo_int,
          'SALDO MORA'          = exl_saldo_int_imo,
          'TOTAL CXC'           = (exl_saldo_int + exl_saldo_int_imo),
          'SALDO INT CGT'       = exl_saldo_int_ctg,
          'SALDO MORA CGT'      = exl_saldo_ctg_imo_int,
          'TOTAL CGT'           = (exl_saldo_int_ctg + exl_saldo_ctg_imo_int),
          'SALDOS OTROS'        = exl_saldo_otros,
          'PROV.CAP'            = exl_prov_cap,
          'PROV.INT'            = exl_prov_int,
          'PROV.OTROS'          = exl_prov_otros,
          'DIAS VENCIMIENTO'    = exl_dias_vencimiento,
          'IDENTIFICACION'      = en_ced_ruc,
          'OFICINA'             = of_nombre, 
          'CLIENTE'             = @i_cliente,
          'DISPONIBLE'          = exl_disponible,
          'FECHA INICIO MORA'    = convert(varchar(10),exl_fecha_ini_mora,101), --SLI  26/sep/06 adicion campo
		  'TIPO CARTERA'         = exl_tipo_cartera,
		  'SUBTIPO CARTERA'      = exl_subtipo_cartera
         from  ca_extracto_linea_tmp, 
               ca_operacion,
               cobis..cl_ente with (nolock), 
               cobis..cl_oficina with (nolock)
         where exl_cliente = en_ente
         and   exl_obligacion = op_banco
         and   op_oficina     = of_oficina
         and   op_naturaleza  = 'A'
         and     exl_user     = @s_user
         and   exl_cliente    = @i_cliente
         and   exl_tipo_deuda = 'INDIRECTA'
      end --if @i_extracto = 'N'
      
      -- INI JAR REQ 175
      if @i_extracto = 'S' begin
         select          
         'CORTE'          = el_corte,                                                    -- 1
         'FECHA DESDE'    = convert(varchar(10),el_fecha_desde,@i_formato_fecha),        -- 2
         'FECHA HASTA'    = convert(varchar(10),el_fecha_hasta,@i_formato_fecha),        -- 3
         'OPERACION'      = el_banco,                                                    -- 4
         'OFICINA'        = el_oficina,                                                  -- 5
         'FECHA INI'      = convert(varchar(10),el_fecha_ini_op,@i_formato_fecha),       -- 6
         'FECHA FIN'      = convert(varchar(10),el_fecha_fin_op,@i_formato_fecha),       -- 7
         'MONTO APR'      = el_monto_apr_op,                                             -- 8
         'F.PAG.INT'      = convert(varchar(10),el_fpago_int,@i_formato_fecha),          -- 9
         'TOPERACION'     = el_toperacion,                                               -- 10
         'TASA NOMINAL'   = el_tasa_nominal,                                             -- 11
         'PERIODO'        = el_periodo,                                                  -- 12
         'TASA E.A.'      = el_tasa_efa,                                                 -- 13
         'TASA MORA'      = el_tasa_mora,                                                -- 14
         'VLR PROXIMO'    = el_vlr_prox_couta,                                           -- 15
         'SALDO'          = el_vlr_saldo,                                                -- 16
         'FECHA PROX.'    = convert(varchar(10),el_fecha_prox_cuota,@i_formato_fecha),   -- 17
         'FECHA PAGO'     = el_fecha_pago,                                               -- 18
         'FECHA TASA APL' = convert(varchar(10),el_fecha_tasa_apl,@i_formato_fecha),     -- 19
         'TASA APL'       = el_tasa_apl,                                                 -- 20
         'FECHA TASA MAX' = convert(varchar(10),el_fecha_tasa_max,@i_formato_fecha),     -- 21
         'TASA MAX. MORA' = el_tasa_max_mora,                                            -- 22
         'TASA USURA'     = el_tasa_max_usura,                                           -- 23
         'MENSAJE'        = el_mensaje,                                                  -- 24
         'BANCA'          = (select C.valor from cobis..cl_tabla T, cobis..cl_catalogo C -- 25
                              where T.tabla  = 'cl_banca_cliente'
                                and T.codigo = C.tabla
                                and C.codigo = B.el_banca)
         from  ca_extracto_linea_tmp,                
               ca_extracto_linea_bat B with (nolock) -- JAR REQ 175
         where exl_user       = @s_user
         and   exl_cliente    = @i_cliente
         and   exl_tipo_deuda = 'INDIRECTA'
         and   exl_obligacion = el_banco
      end --if @i_extracto = 'S'
      -- FIN JAR REQ 175
      
   end  ---Operacion I
      
      
      if @i_operacion = 'G' 
      begin ---Garantias
         --LLENAR LA TABLA DE GARANTIAS PARA EL CLIENTE
       set rowcount 10   
      
        if @i_secuencial_gar = 0
        begin
         exec  sp_datos_garantia_cca
         @s_user                   = @s_user,
         @i_cliente                = @i_cliente
        end  
         
         select 'No.GARANTIA' = dg_no_garantia,
          'TIPO GARANTIA'     = substring(dg_tipo_garantia,1,16),
          'PROPIA'            = dg_propia,
          'VALOR'             = dg_valor,
          'COBERTURA'         = dg_valor_cobertura,
          'DETALLE'           = dg_detalle,   
          'DEFECTO GAR'       = dg_defecto_garantia,
          'VALOR REPALDO'     = dg_cobertura_garantias, 
          'PORCENTAJE RESP'   = dg_porcentaje_cobertura,
          'ESTADO'            = dg_estado,
          'LOCALIZACION'      = dg_localizacion,
          'TRAMITE'           = dg_tramite,
          'SEC.'              = dg_secuencial
         from  ca_detalles_garantia_deudor
         where dg_user = @s_user
         and   dg_cliente = @i_cliente
         and   dg_secuencial > @i_secuencial_gar
         order by dg_secuencial
         set rowcount 0
      end  ---G
      
      
      if @i_operacion = 'C' begin ---CxC 
         select 'REFERENCIA'  = cc_referencia,
                'VALOR'       = cc_valor,
                'CLIENTE'      = @i_cliente,
                'DESCRIPCION' = cc_descripcion
         from  ca_cxc_no_cartera
         where cc_user = @s_user
         and   cc_cliente = @i_cliente
      end 
end



--PARA EL PAZ Y SALVO O CERTIFICACION
if @i_opcion = '1' begin
  
   DECLARE @tv_extracto_linea TABLE (
     tv_secuencial INT IDENTITY (1,1),
     tv_obligacion cuenta
    )
    
     
   if @i_siguiente = '0' begin
   
      delete ca_extracto_linea_tmp
      where exl_user = @s_user
      and   exl_cliente = @i_cliente
      
      select 
      banco = do_banco, fecha = max(do_fecha)
      into #operaciones
      from cob_conta_super..sb_dato_deudores, 
           cob_conta_super..sb_dato_operacion,
           cob_cartera..ca_operacion
      where de_banco = do_banco 
      and   de_cliente = @i_cliente
      and   do_banco   = op_banco 
      and   op_estado not in (@w_est_cancelado, @w_est_credito, @w_est_anulado, @w_est_novigente ) -- Las cacneladas se leen directamente desde cartera
      group by do_banco
      
      --DEUDAS DIRECTAS

      insert into ca_extracto_linea_tmp
      select
      @s_user,
      do_banco,
      @i_cliente,
      'DIRECTAS',
      '',
      pd_descripcion,
      '',
      '',
      '',
      do_calificacion,
      do_fecha_concesion,
      0,
      0   , --JJMD Se cambia el saldo de capital por el saldo total de la deuda.
      0,0,0,
      0,
      0,0,0,0,
      do_edad_mora,
      of_nombre,
      case do_estado_cartera when 1 then 'VIGENTE' when 2 then 'VENCIDO' when 4 then 'CASTIGADO' when 9 then 'SUSPENSO' else 'CANCELADO' end, 
      0,'',
	  cop_sector,
	  cop_subtipo_linea
      from cob_conta_super..sb_dato_operacion , #operaciones,
      cobis..cl_oficina,
      cob_credito..cr_deudores,
      cob_cartera..ca_operacion,
      cobis..cl_producto
      where de_cliente  = @i_cliente
      and do_banco      = op_banco
      and de_tramite    = op_tramite
      and do_oficina    = of_oficina 
      and do_fecha      = fecha
      and de_rol        = 'D'       
      and do_aplicativo = 7
      and do_aplicativo = pd_producto      
      and do_banco      = banco    
                                                                  
      insert into ca_extracto_linea_tmp
     
      select
      @s_user,
      do_banco,
      @i_cliente,
      'INDIRECTAS',
      '',
      'IND-' + pd_descripcion,
      '',
      '',
      '',
      do_calificacion,
      do_fecha_concesion,
      0,
      0   , --JJMD Se cambia el saldo de capital por el saldo total de la deuda.
      0,0,0,
      0,
      0,0,0,0,
      do_edad_mora,
      of_nombre,
      case do_estado_cartera when 1 then 'VIGENTE' when 2 then 'VENCIDO' when 4 then 'CASTIGADO' when 9 then 'SUSPENSO' else 'CANCELADO' end, 
      0,'',
	  cop_sector,
	  cop_subtipo_linea
      from cob_conta_super..sb_dato_operacion , #operaciones,
      cobis..cl_oficina,
      cob_credito..cr_deudores,
      cob_cartera..ca_operacion,
      cobis..cl_producto
      where de_cliente = @i_cliente
      and do_banco = op_banco
      and de_tramite = op_tramite
      and do_oficina = of_oficina 
      and do_fecha = fecha
      and de_rol   != 'D'       
      and do_aplicativo = 7
      and do_aplicativo = pd_producto     
      and do_banco      = banco    

      --JJMD Inicio: Se requiere obtener en lugar del saldo de capital, el saldo total de la deuda para este reporte.
      insert into @tv_extracto_linea (tv_obligacion)
      select
      exl_obligacion
      from ca_extracto_linea_tmp
      where exl_user  = @s_user
      and   exl_cliente = @i_cliente

      select @w_secuencial = 1

      select @w_maximo = max(tv_secuencial) from @tv_extracto_linea

      while @w_secuencial <= @w_maximo
      begin
          
          select @w_banco = tv_obligacion from @tv_extracto_linea where tv_secuencial = @w_secuencial
          
          select @w_cobranza          = op_estado_cobranza, 
                 @w_operacion_cartera = op_operacion,
                 @w_moneda            = op_moneda
          from ca_operacion with(nolock) 
          where op_banco = @w_banco
          
          exec @w_return = sp_decimales
          @i_moneda      = @w_moneda,
          @o_decimales   = @w_num_dec out
             if @w_return <> 0 
                goto ERROR        
          
          if @w_cobranza in ('CP', 'CJ')  ---si la cobranza esta en estado cobro prejuridico, cobro juridico
          begin
             /* INCLUIR CALCULO DE SALDO DE HONORARIOS */
             exec @w_return    = sp_saldo_honorarios
             @i_banco          = @w_banco,
             @i_num_dec        = @w_num_dec,
             @o_saldo_tot      = @w_saldo_operacion_total out
             
             if @w_return <> 0 
                goto ERROR
          end 
          else
          begin
             /** SALDO TOTAL DE LA OPERACION   **/
             exec @w_return   = sp_calcula_saldo
             @i_operacion     = @w_operacion_cartera,
             @i_tipo_pago     = 'A', --@w_anticipado_int,
             @o_saldo         = @w_saldo_operacion_total out
             
             if @w_return <> 0 
                goto ERROR
          end
          select @w_saldo_operacion_total = isnull(@w_saldo_operacion_total, 0)
          
          update ca_extracto_linea_tmp set exl_saldo_cap = @w_saldo_operacion_total
          where exl_user  = @s_user
          and exl_obligacion = @w_banco
          and   exl_cliente = @i_cliente
      
          select @w_secuencial = @w_secuencial + 1 
      end
      --JJMD FIN
      
      --actualizar cotizacion para moneda 2 def 7205

      /*insert datos historicos*/
      insert into ca_extracto_linea_tmp
      select  
      @s_user,
      op_banco,
      @i_cliente,
      'HISTORICAS',
      '',
      'CARTERA',
      '',
      '',
      '',
      op_calificacion,
      op_fecha_ini,
      0,
      0, 
      0,0,0,0,0,0,0,0,
      0,
      of_nombre,
      'CANCELADO',
      0, '' , null, null --JCA     
      from cob_cartera_his..ca_operacion, 
      cobis..cl_oficina
      where op_cliente = @i_cliente
      and op_operacion > 0
      and op_estado = 3
      and op_oficina = of_oficina
      
      /*insert datos canceladas*/
      insert into ca_extracto_linea_tmp
      select  
      @s_user,
      op_banco,
      @i_cliente,
      'CANCELADA',
      '',
      'CARTERA',
      '',
      '',
      '',
      op_calificacion,
      op_fecha_ini,
      0,
      0, 
      0,0,0,0,0,0,0,0,
      0,
      of_nombre,
      'CANCELADO',
      0, '', null, null  --JCA      
      from cob_cartera..ca_operacion, cob_credito..cr_deudores,
      cobis..cl_oficina
      where de_cliente = @i_cliente
      and de_tramite =  op_tramite
      and op_operacion > 0
      and op_estado = 3
      and op_oficina = of_oficina
        
   end                     
   
   set rowcount 10
   select 
   'OBLIGACION'     = exl_obligacion,
   'OFICINA'        = exl_nom_codeudor,
   'PRODUCTO'       = exl_iden_indirectas,
   'SALDO TOTAL'      = exl_saldo_cap,
   'ESTADO'         = exl_iden_codeudor,
   'DIAS VENC'      = exl_dias_vencimiento,           
   'CALIFICACION'   = exl_calificacion
   from  ca_extracto_linea_tmp
   where  exl_user       = @s_user
   and   exl_cliente    = @i_cliente   
   and   exl_obligacion > @i_siguiente                  
   order by exl_obligacion
   
   if @@rowcount = 0 and @i_siguiente = ''
   begin
      PRINT 'MENSAJE INFORMATIVO:  El cliente consultado no tiene deudas con la Entidad'

      select 
      'OBLIGACION'      = '',
      'OFICINA'          = '',
      'PRODUCTO'         = '',
      'SALDO TOTAL'        = 0,
      'ESTADO'           = '',
      'DIAS VENC'        = 0,
      'CALIFICACION'     = ''
   end 
   set rowcount 0            
         
   select @w_cod_ciudad  = of_ciudad 
   from cobis..cl_oficina
   where of_oficina = @i_oficina

   select @w_des_ciudad = ci_descripcion 
   from cobis..cl_ciudad
   where ci_ciudad = @w_cod_ciudad
   
   select @w_des_ciudad
          
end

return 0

ERROR:
   exec cobis..sp_cerror
        @t_debug  = 'N',
        @t_file   = null,
        @t_from   = @w_sp_name,
        @i_num    = @w_return,
        @i_sev    = 0,
        @i_msg    = 'Error en la ejecucion de SP'
   return @w_return  
   
go


