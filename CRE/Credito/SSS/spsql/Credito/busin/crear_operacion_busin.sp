/************************************************************************/
/*  Archivo:                crear_operacion_busin.sp                    */
/*  Stored procedure:       sp_crear_operacion_busin                    */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jonatan Rueda                               */
/*  Fecha de Documentacion: 23/Abr/2019                                 */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP S.A.representantes exclusivos para el Ecuador de la       */
/*  AT&T                                                                */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante               */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  SP GENERADO POR EXTRACCION DE LA BB.DD. cob_credito                 */
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  23/04/19          LOGIN_DESA       Emision Inicial                  */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_crear_operacion_busin')
    drop proc sp_crear_operacion_busin
go

create proc sp_crear_operacion_busin(
        @s_user              login        = NULL,
        @s_sesn              int          = NULL,
        @s_ofi               int          = NULL,
        @s_date              datetime     = NULL,
        @s_term              varchar(30)  = NULL,
        @i_anterior          cuenta       = NULL,
        @i_migrada           cuenta       = NULL,
        @i_tramite           int          = NULL,
        @i_cliente           int          = NULL,
        @i_nombre            descripcion  = NULL,
        @i_sector            catalogo     = NULL,
        @i_toperacion        catalogo     = NULL,
        @i_oficina           smallint     = NULL,
        @i_moneda            tinyint      = NULL,
        @i_comentario        varchar(255) = NULL,
        @i_oficial           smallint     = NULL,
        @i_fecha_ini         datetime     = NULL,
        @i_monto             money        = NULL,
        @i_monto_aprobado    money        = NULL,
        @i_destino           catalogo     = NULL,
        @i_lin_credito       cuenta       = NULL,
        @i_ciudad            smallint     = NULL,
        @i_parroquia         catalogo     = NULL,    -- ITO:13/12/2011
        @i_forma_pago        catalogo     = NULL,
        @i_cuenta            cuenta       = NULL,
        @i_formato_fecha     int          = 101,
        @i_no_banco          char(1)      = 'N',
        @i_num_renovacion    int          = NULL,
        @i_alicuota	     varchar(10)  = null, 
        @i_alicuota_aho      varchar(10)  = null, 
        @i_doble_alicuota    char(1)      = null, 
        @i_cta_ahorro        cuenta       = null,
        @i_cta_certificado   cuenta       = null,
        @i_actividad_destino catalogo     = null,  -- SPO  Campo actividad economica
        @i_compania          int          = null,  -- LGU compania del cliente 26.03.2002
        @i_tipo_cca          catalogo     = null,  -- LGU compania del cliente 09.04.2002
	@i_seg_cre           catalogo     = null,  -- SRA Campo segmento credito
        @i_es_interno        char(1)      = 'N',   --N = No es un programa interno, 'S'= es un llamada desde otro sp
        @i_prodbanc_aho      smallint     = NULL,  --PRON:14NOV07 prod bancario para simulacion
        @i_prodbanc_cer      smallint     = NULL,  --PRON:14NOV07 prod bancario para simulacion       
        @i_val_act            char(1)     = 'S',
        @i_activa_TirTea     char(1)      = 'S',
		@i_toperacion_ori	 catalogo 	  = null, --Policia Nacional: Se incrementa por tema de interceptor   
	    @i_plazo             smallint     = null,	--Parámetro para crear la operación con el plazo ingresado desde la Originación
	    @i_tplazo            catalogo     = null,	--Parámetro para crear la operación con el tipo de plazo ingresado desde la Originación
        @o_banco             cuenta       = NULL output
		)
as
declare @w_sp_name           descripcion,
        @w_return            int,
        @w_error             int,
        @w_operacionca       int,
        @w_banco             cuenta,
        @w_anterior          cuenta ,
        @w_migrada           cuenta,
        @w_tramite           int,
        @w_cliente           int,
        @w_nombre            descripcion,
        @w_sector            catalogo,
        @w_toperacion        catalogo,
        @w_oficina           smallint,
        @w_comentario        varchar(255),
        @w_oficial           smallint,
        @w_fecha_ini         datetime,
        @w_fecha_f           varchar(10),
        @w_fecha_fin         datetime,
        @w_fecha_ult_proceso datetime,
        @w_fecha_liq         datetime,
        @w_fecha_reajuste    datetime,
        @w_monto             money,
        @w_monto_aprobado    money,
        @w_destino           catalogo,
        @w_lin_credito       cuenta,
        @w_ciudad            smallint,
        @w_estado            tinyint,
        @w_periodo_reajuste  smallint,
        @w_reajuste_especial char(1),
      @w_tipo              char(1),
        @w_forma_pago        catalogo,
        @w_cuenta            cuenta,
        @w_dias_anio         smallint,
        @w_tipo_amortizacion varchar(30),
        @w_cuota_completa    char(1),
        @w_tipo_cobro        char(1),
        @w_tipo_reduccion    char(1),
        @w_aceptar_anticipos char(1),
        @w_precancelacion    char(1),
        @w_num_dec           tinyint,
        @w_tplazo            catalogo,
        @w_plazo             smallint,
        @w_tdividendo        catalogo,
        @w_periodo_cap       smallint,
        @w_periodo_int       smallint,
        @w_gracia_cap        smallint,
        @w_gracia_int        smallint,
        @w_dist_gracia       char(1),
        @w_fecha_fija        char(1), 
        @w_dia_pago          tinyint,
        @w_cuota_fija        char(1),
        @w_evitar_feriados   char(1),
        @w_tipo_producto     char(1),
        @w_renovacion        char(1),
        @w_mes_gracia        tinyint,
        @w_tipo_aplicacion   char(1),
        @w_reajustable       char(1),
        @w_est_novigente     tinyint,
        @w_est_credito       tinyint,
        @w_fijo_desde        smallint,  --JG Y BP
        @w_fijo_hasta        smallint,   --JG Y BP
	@w_tipo_bloqueo	     char(1),
	@w_clase_bloqueo     char(1),
	@w_cta_ahorro	     varchar(24),
	@w_cta_certificado   varchar(24),
        @w_valor_alicuota     float,
        @w_valor_alicuota_aho float,
        @w_bloq_encaje_cert   money,
        @w_bloq_encaje_aho    money,
        @w_disp_ahorro        money,
        @w_disp_certificado   money ,
        @w_consulta           char(1),
        @w_monto_min          money,
        @w_monto_max          money,
        @w_reaj_diario        char(1),
        @w_valida_bloqueos    char(1),
        @w_judicial           char(1),
        @w_clase              catalogo,
        @w_programa           varchar(40),
        @w_valor_minimo       money,
        @w_valor_maximo       money,
        @w_tipo_cca           catalogo,
        @w_tea                float,
        @w_base_dias_int      char(1),
        @w_des_est_novigente  varchar(20),
        @w_grupo_financiero   varchar(10), --cll REQ-956 Obligaciones Financieras
        @w_pcuota             money,
        @w_disponible         money,
        @w_forma_pago_obl     catalogo,
        @w_actividad_sujeto   catalogo,
        @w_dias_gracia        smallint, --CLLL REQ#2717
        @w_calcooperativa     varchar(10),
        @w_calcliente         varchar(10),
        @w_base_calculo       CHAR(1)  --LGU

-- INICIALIZACION DE VARIABLES
select @w_sp_name = 'sp_crear_operacion_busin',
       @w_est_novigente = 0,
       @w_est_credito   = 99,
       @w_judicial      = 'N',
       @i_activa_TirTea = isnull(@i_activa_TirTea, 'S')   -- SPRINT 6 320:Parametrizacion de mensajes de Credito, PBE

--No es llamado de otro programa
if @i_es_interno = 'N'
begin   
  --crea tabla para calculo de TIR
  create table #dividendos_tea (
  operacion       int,
  dividendo       smallint,
  dias            int,
  cuota           money,
  amortiza        money,
  saldo_bloq_aho  money,
  saldo_bloq_cer  money 
  )  
end

-- CLASE DE CARTERA NORMAL
select @w_clase = isnull(pa_char,'N')
from   cobis..cl_parametro
where  pa_nemonico = 'CLANOR'
and    pa_producto = 'CCA'


-- VERIFICAR QUE EXISTAN LOS RUBROS NECESARIOS
if exists (select 1 from cob_cartera..ca_rubro
            where ru_toperacion    = @i_toperacion
              and ru_moneda        = @i_moneda
              and ru_tipo_rubro    = 'C'
              and ru_crear_siempre = 'S'
              and ru_estado        = 'V') AND
   exists (select 1 from cob_cartera..ca_rubro
            where ru_toperacion    = @i_toperacion
              and ru_moneda        = @i_moneda
              and ru_tipo_rubro    = 'I'
              and ru_crear_siempre = 'S'
              and ru_estado        = 'V') 
/*AND Se quita por obligaciones financieras
   exists (select 1 from cob_cartera..ca_rubro
            where ru_toperacion = @i_toperacion
              and ru_moneda        = @i_moneda
              and ru_tipo_rubro    in ('M','B')
              and ru_crear_siempre = 'S'
              and ru_estado        = 'V')*/
   goto NEXT
else
 begin
   select @w_error = 710016
   goto ERROR
 end

-- DETERMINAR LOS VALORES POR DEFECTO PARA EL TIPO DE OPERACION
NEXT:
select @w_periodo_reajuste     = dt_periodo_reaj,
       @w_reajuste_especial    = dt_reajuste_especial,
       @w_precancelacion       = dt_precancelacion,
       @w_tipo                 = dt_tipo,
       @w_cuota_completa       = dt_cuota_completa,
       @w_tipo_reduccion       = dt_tipo_reduccion,
       @w_aceptar_anticipos    = dt_aceptar_anticipos,
       @w_tipo_reduccion       = dt_tipo_reduccion,
       @w_tplazo               = isnull(@i_tplazo, dt_tplazo),
       @w_plazo                = isnull(@i_plazo, dt_plazo),
       @w_tdividendo           = dt_tdividendo,
       @w_periodo_cap          = dt_periodo_cap,
       @w_periodo_int          = dt_periodo_int,
       @w_gracia_cap           = dt_gracia_cap,
       @w_gracia_int           = dt_gracia_int,
       @w_dist_gracia          = dt_dist_gracia,
       @w_dias_anio            = dt_dias_anio,  
       @w_tipo_amortizacion    = dt_tipo_amortizacion,
       @w_fecha_fija           = dt_fecha_fija,
       @w_dia_pago             = dt_dia_pago,
       @w_cuota_fija           = dt_cuota_fija,
       @w_evitar_feriados      = dt_evitar_feriados,
       @w_renovacion           = dt_renovacion,
       @w_mes_gracia           = dt_mes_gracia,
       @w_tipo_aplicacion      = dt_tipo_aplicacion,
       @w_tipo_cobro           = dt_tipo_cobro,
       @w_reajustable          = dt_reajustable,
      -- @w_fijo_desde           = dt_desde, --JG Y BP
       --@w_fijo_hasta           = dt_hasta,
       @w_monto_min            = dt_monto_min,
       @w_monto_max            = dt_monto_max,
       --@w_reaj_diario          = dt_reaj_diario,
      -- @w_tipo_bloqueo         = dt_tipo_bloqueo,
      -- @w_clase_bloqueo        = isnull(dt_clase_bloqueo,'N'),   --PRON:28AGO06
       --@w_base_dias_int	       = isnull(dt_base_dias_int,'R'),    --PRON:9JUL08
       --@w_grupo_financiero     = dt_grupo_financiero, --cll REQ-956 Obligaciones Financieras
       @w_dias_gracia          = dt_dias_gracia,       --CLLL REQ#2717
       @w_base_calculo         = dt_base_calculo -- LGU
from  cob_cartera..ca_default_toperacion
where dt_toperacion = @i_toperacion
and   dt_moneda     = @i_moneda

if @@rowcount = 0 begin
   select @w_error = 710072 
   goto ERROR
end

if @w_tipo = 'R'
begin
  select @w_pcuota = 0

  --cll REQ-956 Obligaciones Financieras inicio 
 /* exec @w_return = cob_cartera..sp_grupo_financiero
       @t_trn         = 7865,
       @i_operacion   = 'T',
       @i_grupo       = @w_grupo_financiero,
       @o_disponible  = @w_disponible out
  
  if @w_return != 0 begin
     select @w_error = @w_return
     goto ERROR
  end  
   */ 

  if @i_monto > @w_disponible
  begin
     select @w_error = 707095
     goto ERROR
  end    

  --Forma de pagoa automatica para Obligaciones financieras
  select @w_forma_pago_obl = pa_char
  from   cobis..cl_parametro
  where  pa_producto = 'CCA'
  and    pa_nemonico = 'DEBOBL'

  select @i_forma_pago = @w_forma_pago_obl,
         @i_cuenta = ' '
  
   --Destino Economico para Obligaciones Financieras

   if isnull(@i_destino,' ') = ' ' 
   begin
      set rowcount 1
      select @i_destino = y.codigo
      from   cobis..cl_catalogo y, cobis..cl_tabla t
      where  t.tabla  = 'cr_destino'
      and    y.tabla  = t.codigo
      and    y.estado = 'V'
      set rowcount 0
   end

end
else
begin
  if not exists (select * from cob_credito..cr_corresp_sib
                          where codigo = @i_toperacion_ori
                          and tabla = 'T12')
  begin
     print 'El Tipo de Operacion [%1!] no tiene Equivalente en la tabla de la SIB' + @i_toperacion_ori
     select @w_error = 710072 
     goto ERROR
  end
end


-- VALIDACION DEL MONTO APROBADO
if isnull(@w_monto_min,0) > 0 or isnull(@w_monto_max,0) > 0
begin
  if @i_monto_aprobado < @w_monto_min or @i_monto_aprobado > @w_monto_max 
  begin
     print 'SRO 1: 710124'
     select @w_error = 710124
     goto ERROR
   end
end

begin tran

-- CALCULAR SECUENCIAL Y NUMERO DE BANCO
if @i_no_banco = 'S'      --Simulacion
begin
   exec @w_operacionca = cob_cartera..sp_gen_sec
        @i_operacion   = -1,
        @i_modo        = 'C'

   select @w_banco = convert(varchar(20),@w_operacionca)
end 
else 
begin  
   exec @w_return = cob_cartera..sp_numero_oper
        @i_oficina   = @i_oficina,
        @i_tramite   = @i_tramite,
        @o_operacion = @w_operacionca out,
        @o_num_banco = @w_banco out

   if @w_return != 0 begin
     select @w_error = @w_return
     goto ERROR
   end
end

if @i_tramite IS NULL 
  select @w_estado = @w_est_novigente
else 
  select @w_estado = @w_est_credito


-- PRON:28AGO06:Valida Obligatoriedad de los bloqueos
select @w_valida_bloqueos = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'VBLO'

select @w_valida_bloqueos = isnull(@w_valida_bloqueos,'S')

if @w_valida_bloqueos = 'S' and @i_no_banco = 'N'
begin
   --Si la  clase de bloqueo por defecto es distinta a NO APLICA
   -- Verifica si el bloqueo por operacion esta como No aplica
   if @w_clase_bloqueo <> 'N' and @i_doble_alicuota = 'E' 
   begin
      select @w_error =710130
      goto ERROR
   end
end

if @i_doble_alicuota = 'S' 
   select @w_clase_bloqueo = 'D'

if @i_doble_alicuota = 'E' 
   select @i_alicuota = null,
          @i_alicuota_aho = null

/* PRON:12MAY06 */
if @i_doble_alicuota = 'N' and (@w_clase_bloqueo <> 'A' and @w_clase_bloqueo <> 'C')
begin
   select @w_error =710125
   goto ERROR
end

-- VALIDACIONES QUE NO INCLUYEN SIMULACION
if @i_cliente <> -666  --No valida en simulacion
begin
 
   select @w_actividad_sujeto = en_actividad
   from   cobis..cl_ente
   where  en_ente = @i_cliente


   --CLL Sprint 9 VALIDA QUE LA ACTIVIDAD CORRESPONDA AL SEGMENTO DE CREDITO Y DESTINO
   if not exists (select 1 from cob_cartera..ca_seg_destino_bce
                     where sd_segmento = @i_seg_cre
                     and   sd_destino_bce  = @i_destino
                     and   (sd_act_economica_bce = @i_actividad_destino or sd_act_economica_bce = null)) 
                 and @w_tipo <> 'R'       
   begin
      select @w_error = 710177
      goto ERROR
   end
   
   -- VALIDA LA ACTIVIDAD ECONOMICA DEL SUJETO (DEUDOR, CODEUDORES Y GARANTES)
   if @i_val_act = 'S'
   begin
   /*   exec @w_return  = cob_cartera..sp_valida_actividad_busin
           @s_user    = @s_user,
           @s_sesn    = @s_sesn,
           @i_tramite = @i_tramite,
           @i_tipo	   = @w_tipo
         
      if @w_return != 0 
      begin
         select @w_error = @w_return
         goto ERROR
      end*/
      PRINT 'comentado SMO'
   end
      
  -- SI DOBLE ALICUOTA DIFERENTE DE 'NO APLICA' VALIDAR CUENTAS    --AOL 23FEB07
  if @i_doble_alicuota <> 'E' and @w_clase_bloqueo <> 'N' 
  begin
    if @i_cliente = 0 and @i_comentario is not null
      select @w_consulta = 'S'
    else 
    begin

      --Certificados y ambas
      if @w_clase_bloqueo = 'C' or @w_clase_bloqueo = 'D'
      begin
        if @i_cta_certificado is not null
        begin
          select @w_cta_certificado  = ah_cta_banco       --Cta de bloqueo de certificado
          from   cob_ahorros..ah_cuenta, 
                 cob_remesas..pe_pro_bancario
          where ah_cliente    = @i_cliente  
          and   ah_cta_banco  = @i_cta_certificado
          and   ah_estado     = 'A'
         -- and   ah_menor_edad = 0                     --SOLO MAYORES DE EDAD AOL
          and   pb_pro_bancario      = ah_prod_banc   --PRON:31AGO06
          --and   pb_tipo_pro_bancario = 'C'            --Producto de Cuentas Certificado
          --and   pb_aplica_encaje     = 'S'            --para encaje 

          if @@rowcount = 0 begin
             select @w_error = 701178
   goto ERROR
          end
  end
        else
        begin
          select @w_cta_certificado  = ah_cta_banco       --Cta de bloqueo de certificado
          from   cob_ahorros..ah_cuenta, 
                 cob_remesas..pe_pro_bancario
          where ah_cliente    = @i_cliente           
          and   ah_estado     = 'A'       
         -- and   ah_menor_edad = 0                     --SOLO MAYORES DE EDAD AOL
          and   pb_pro_bancario      = ah_prod_banc   --PRON:31AGO06
         -- and   pb_tipo_pro_bancario = 'C'            --Producto de Cuentas Certificado
         -- and   pb_aplica_encaje     = 'S'            --para encaje 

          if @@rowcount = 0 begin
             select @w_error = 701178
             goto ERROR
          end
        end
      end

      --Ahorros y ambas
      if @w_clase_bloqueo = 'A' or @w_clase_bloqueo = 'D'
      begin
        if @i_cta_ahorro is not null
        begin
          select @w_cta_ahorro  = ah_cta_banco         --Cta de bloqueo de ahorros
          from  cob_ahorros..ah_cuenta, 
                cob_remesas..pe_pro_bancario
          where ah_cliente    = @i_cliente 
          and   ah_cta_banco  = @i_cta_ahorro        
          and   ah_estado     = 'A'
         -- and   ah_menor_edad = 0    --SOLO MAYORES DE EDAD AOL
          and   pb_pro_bancario = ah_prod_banc   --PRON:31AGO06
          --and   pb_tipo_pro_bancario = 'A'       --Producto de Cuentas Ahorros 
          --and   pb_aplica_encaje = 'S'           --para encaje

          if @@rowcount = 0 begin
             select @w_error = 701179
             goto ERROR
          end
        end
        else
        begin
          select @w_cta_ahorro  = ah_cta_banco         --Cta de bloqueo de ahorros
          from  cob_ahorros..ah_cuenta, 
                cob_remesas..pe_pro_bancario
          where ah_cliente  = @i_cliente           
          and   ah_estado     = 'A'
      --    and   ah_menor_edad = 0    --SOLO MAYORES DE EDAD AOL
          and   pb_pro_bancario = ah_prod_banc   --PRON:31AGO06
        --  and   pb_tipo_pro_bancario = 'A'       --Producto de Cuentas Ahorros 
         -- and   pb_aplica_encaje = 'S'           --para encaje

          if @@rowcount = 0 begin
             select @w_error =701179
             goto ERROR
          end
       end
      end

      if @w_cta_ahorro = '0'
         select @w_cta_ahorro = null
    end
  end
end

--CLL RFD-0122
if @i_cliente = -666  --No valida en simulacion
begin

   select top 1 
          @w_calcliente	= b.codigo
   from cobis..cl_tabla a, cobis..cl_catalogo b
   where a.tabla = 'cr_calificacion'
   and   a.codigo = b.tabla
   
end

/*select @w_calcliente = en_calificacion_riesgo
from cobis..cl_ente
where en_ente = @i_cliente*/

select @w_calcooperativa = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'CALCOO'
--CLL RFD-0122
print 'sp_crear_operacion_busin ANTES DE sp_operacion_tmp tipo I'
-- CREAR LA OPERACION TEMPORAL
print'TRANSACCIONES antes cob_cartera..sp_operacion_tmp:' +convert(varchar(10),@@trancount)
exec @w_return = cob_cartera..sp_operacion_tmp
     @i_operacion         = 'I',
     @i_operacionca       = @w_operacionca,
     @i_banco             = @w_banco,
     @i_anterior          = @i_anterior,
     @i_migrada           = @i_migrada,
     @i_tramite           = @i_tramite,
     @i_cliente           = @i_cliente,
     @i_nombre            = @i_nombre,
     @i_sector            = @i_sector,
     @i_toperacion        = @i_toperacion,
     @i_oficina           = @i_oficina,
     @i_moneda            = @i_moneda, 
     @i_comentario        = @i_comentario,
     @i_oficial           = @i_oficial,
     @i_fecha_ini         = @i_fecha_ini,
     @i_fecha_fin         = @i_fecha_ini,
     @i_fecha_ult_proceso = @i_fecha_ini,
     @i_fecha_liq         = @i_fecha_ini,
     @i_fecha_reajuste    = @i_fecha_ini,
     @i_monto             = @i_monto, 
     @i_monto_aprobado    = @i_monto_aprobado,
     @i_destino           = @i_destino,
     @i_lin_credito       = @i_lin_credito,
     @i_ciudad            = @i_ciudad,
     @i_parroquia         = @i_parroquia,   -- ITO: 13/12/2011
     @i_estado    = @w_estado,
     @i_periodo_reajuste  = @w_periodo_reajuste,
     @i_reajuste_especial = @w_reajuste_especial,
     @i_tipo              = @w_tipo, --(Hipot/Redes/Normal)
     @i_forma_pago        = @i_forma_pago,
     @i_cuenta            = @i_cuenta,
     @i_dias_anio         = @w_dias_anio, 
     @i_tipo_amortizacion = @w_tipo_amortizacion,
     @i_cuota_completa    = @w_cuota_completa,
     @i_tipo_cobro        = @w_tipo_cobro,
     @i_tipo_reduccion    = @w_tipo_reduccion,
     @i_aceptar_anticipos = @w_aceptar_anticipos,
     @i_precancelacion    = @w_precancelacion,
     @i_tipo_aplicacion   = @w_tipo_aplicacion,
     @i_tplazo            = @w_tplazo,
     @i_plazo             = @w_plazo,
     @i_tdividendo        = @w_tdividendo,
     @i_periodo_cap       = @w_periodo_cap,
     @i_periodo_int       = @w_periodo_int,
     @i_dist_gracia       = @w_dist_gracia,
     @i_gracia_cap        = @w_gracia_cap,
     @i_gracia_int        = @w_gracia_int,
     @i_dia_fijo          = @w_dia_pago,
     @i_cuota             = 0,
     @i_evitar_feriados   = @w_evitar_feriados,
     @i_renovacion        = @w_renovacion,
     @i_mes_gracia        = @w_mes_gracia,
     @i_reajustable       = @w_reajustable,
     @i_num_renovacion    = @i_num_renovacion,
     @i_fijo_desde        = @w_fijo_desde, --JG Y BP
     @i_fijo_hasta        = @w_fijo_hasta,  --JG Y BP
     @i_alicuota	  = @i_alicuota,
     @i_alicuota_aho      = @i_alicuota_aho,
     @i_tipo_bloqueo	  = @w_tipo_bloqueo,
     @i_clase_bloqueo     = @w_clase_bloqueo,
     @i_cta_ahorro 	  = @w_cta_ahorro,
     @i_cta_certificado   = @w_cta_certificado,
     @i_doble_alicuota    = @i_doble_alicuota,
     @i_actividad_destino = @i_actividad_destino,  --SPO Actividad economica de destino    
     @i_compania          = @i_compania,  -- LGU 26.03.2002
     @i_tipo_cca          = @i_tipo_cca,  -- LGU 09.04.2002
     @i_reaj_diario       = @w_reaj_diario,
     @i_judicial          = @w_judicial,
     @i_clase             = @w_clase,
     @i_seg_cre	  	  = @i_seg_cre,
     @i_base_dias_int     = @w_base_dias_int,  --PRON:9JUL08
     @i_grupo_financiero  = @w_grupo_financiero, --cll REQ-956 Obligaciones Financieras
     @i_p_cuota		  = @w_pcuota,              --cll REQ-956 Obligaciones Financieras
     @i_calcliente        = @w_calcliente,
     @i_calcooperativa    = @w_calcooperativa,
     @i_base_calculo      = @w_base_calculo
   print'TRANSACCIONES despues cob_cartera..sp_operacion_tmp:' +convert(varchar(10),@@trancount)  

if @w_return != 0 begin 
  select @w_error = @w_return
  goto ERROR
end

/*---------------------------*/
/* VALIDACION DE SEGMENTOS   */
/* PRON:11OCT2007            */
/*---------------------------*/
select @w_programa     = st_programa,
       @w_valor_minimo = st_valor_minimo,
       @w_valor_maximo = st_valor_maximo,
       @w_tipo_cca     = st_tipo_cca
from   cob_cartera..ca_segcred_tipocca
where  st_seg_cred = @i_seg_cre
and    st_tipo_cca = @i_tipo_cca

-- VALIDA QUE EL SEGMENTO DE CREDITO CORRESPONDA AL TIPO DE CARTERA
if @@rowcount = 0 and @w_tipo <> 'R'
begin
   select @w_error = 710174
   goto ERROR
end

--print 'ejecuto programa: %1!', @w_programa

if @w_programa is not null
begin
  if not exists (select 1 from cob_cartera..sysobjects where name = @w_programa)
  begin
    select @w_error = 707075
    goto ERROR
  end
  select @w_programa = 'cob_cartera..' + @w_programa
  exec @w_return      = @w_programa	
       @i_operacionca = @w_operacionca,
       @i_monto_min   = @w_valor_minimo,
       @i_monto_max   = @w_valor_maximo, 
       @i_tipo_cca    = @w_tipo_cca,     
       @i_temporal    = 'S'

  if @w_return != 0 
  begin
    select @w_error = @w_return       
    goto ERROR
  end
end

/*---------------------------*/
-- CREAR LOS RUBROS TEMPORALES DE LA OPERACION
print'TRANSACCIONES antes cob_cartera..sp_gen_rubtmp:' +convert(varchar(10),@@trancount)
exec @w_return = cob_cartera..sp_gen_rubtmp
     @s_user        = @s_user,
     @s_term        = @s_term,
     @s_date        = @s_date,
     @i_operacionca = @w_operacionca 
print'TRANSACCIONES despues cob_cartera..sp_gen_rubtmp:' +convert(varchar(10),@@trancount)
if @w_return != 0 begin
  select @w_error = @w_return
  goto ERROR
end
--print 'sale: sp_gen_rubtmp'


-- GENERACION DE LA TABLA DE AMORTIZACION
print'TRANSACCIONES antes cob_cartera..sp_gentabla:' +convert(varchar(10),@@trancount)
exec @w_return = cob_cartera..sp_gentabla
     @i_operacionca    = @w_operacionca,
     @i_tabla_nueva    = 'S',
     @i_desde_creacion = 'S',   --PRON:21NOV2006 cambio para que recalcule los rubros cuando es desde el sp de creacion
     @i_dias_gracia    = @w_dias_gracia, --CLLL REQ#2717
     @o_fecha_fin      = @w_fecha_fin out
print'TRANSACCIONES despues cob_cartera..sp_gentabla:' +convert(varchar(10),@@trancount)   
if @w_return != 0 begin
  select @w_error = @w_return
  goto ERROR
end
--print 'sale: sp_gentabla'

/*---------------------------------*/
--PRON:23OCT2007 Llama a programa que determina el TEA, para validar que la tasa no se pase de la maxima
if @i_es_interno = 'N'
begin
--print 'entra a sp_TIR_TEA'
  /*exec @w_return = cob_cartera..sp_TIR_TEA
       @s_user                 = @s_user, --CLL SPRINT 7
       @s_date                 = @s_date,
       @s_term                 = @s_term,
       @s_ofi                  = @s_ofi,       
       @i_operacionca     = @w_operacionca,
       @i_fecha           = @i_fecha_ini,
       @i_calcula_TEA     = 'S',
       @i_valida_maxima   = 'S',
       @i_temporal        = 'S',
       @i_prodbanc_aho    = @i_prodbanc_aho,
       @i_prodbanc_cer    = @i_prodbanc_cer,
       @i_activa_TirTea   = @i_activa_TirTea,     -- SPRINT 6 320:Parametrizacion de mensajes de Credito, PBE
       @o_tea             = @w_tea out
  if @w_return != 0 begin
    select @w_error = @w_return
    goto ERROR
  end
--print 'sale sp_TIR_TEA'
*/
PRINT 'comentado SMO'
end

/*---------------------------------*/
-- ACTUALIZACION DE LA OPERACION
if isnull(@w_periodo_reajuste,0) != 0 
   select @w_fecha_reajuste = min(re_fecha)
   from   cob_cartera..ca_reajuste
   where  re_operacion = @w_operacionca
else
   select @w_fecha_reajuste = '01/01/1900'

update cob_cartera..ca_operacion_tmp 
set    opt_fecha_reajuste = isnull(@w_fecha_reajuste,'01/01/1900')
where  opt_operacion      = @w_operacionca

if @@error != 0 begin
  select @w_error = 710002
  goto ERROR
end 

--print 'luego de actaulizar op_tmp'


-- ANTES DE SALIR CALCULO LOS RUBROS ANTICIPADOS
exec @w_return = cob_cartera..sp_calcular_anticipados
   @i_operacionca = @w_operacionca,
   @i_fecha       = @i_fecha_ini

if @w_return != 0 
begin
   select @w_error = @w_return       
   goto ERROR
end

/*----------------------------------------------------*/
/* Despliega datos al Frontend de tramites y cartera  */
/*----------------------------------------------------*/
select @o_banco = @w_banco
select @w_fecha_f  = convert(varchar(10),@w_fecha_fin, @i_formato_fecha)

select @w_des_est_novigente = es_descripcion
  from cob_cartera..ca_estado 
 where es_codigo = @w_est_novigente


select @w_banco
select @w_fecha_f
select @w_des_est_novigente
select @w_tipo       
select @w_cta_certificado
select @w_cta_ahorro

commit tran

--print 'fin sp_crearop_busin'

return 0
ERROR:
exec cobis..sp_cerror
    @t_debug  = 'N',
    @t_file   = NULL,
    @t_from   = @w_sp_name,   
    @i_num    = @w_error,
    @i_cuenta = ' '

return @w_error




GO

