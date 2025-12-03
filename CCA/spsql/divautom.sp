/************************************************************************/
/*      Archivo:                divautom.sp                             */
/*      Stored procedure:       sp_op_divisas_automatica                */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           LCA                                     */
/*      Fecha de escritura:     Jun. 2020                               */
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
/*      Obtiene las cotizaciones en la moneda de la transaccion         */
/*      Genera la posici+¦n en moneda de la transaccion                  */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR           RAZON                           */
/*    05/Jun/2020       Luis Castellanos  Emision Inicial               */
/*    19/Jun/2020       Luis Ponce        CDIG Multimoneda Ajustes      */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_op_divisas_automatica')
           drop proc sp_op_divisas_automatica
go

create proc sp_op_divisas_automatica(                  
   @s_date                  datetime,                  -- Fecha del sistema                                                         
   @s_user                  login,                     -- Usuario del sistema                                                       
   @s_ssn                   int,                       -- Secuencial unico COBIS  
   @s_ssn_branch            int          = null,       -- Secuencial del Branch
   @s_term                  descripcion  = null,
   @t_show_version          tinyint      = 0,          -- Versionamiento del SP  
   @i_oficina               smallint,                  -- Oficina donde debe ser registrada la transaccion.  Afectara contablemente 
   @i_cliente               int          = null,       -- Codigo del cliente a nombre de quien se realiza la operacion de divisas   
   @i_modulo                char(3),                   -- Nemonico del modulo COBIS que origina la operacion de divisas             
   @i_concepto              catalogo     = null,       -- Concepto de la negociacion.  Valor del catalogo sb_divisas_modulos.  Se   
                                                       -- utilizara para identificar el perfil contable                             
   @i_operacion             estado,                    -- C - Consulta, E - Ejecucion normal , R - Reversar una operacion anterior  
   @i_cot_contable          estado       = 'N',        -- Se usa solo en @i_operacion = 'C' para tomar cotizaciones contables       
   @i_secuencial            int          = null,       -- SSN de la operacion normal.  Usado para reversos                          
   @i_moneda_origen         tinyint      = null,       -- Moneda en la cual esta expresado el monto a convertir                     
   @i_valor                 money        = 0,          -- Monto a convertir                                                         
   @i_moneda_destino        tinyint      = null,       -- Moneda en la cual se expresara el monto                                   
   @i_valor_destino         money        = 0,          -- Monto destino a convertir al equivalente en moneda de origen              
   @i_contabiliza           estado       = 'N'  out,   -- S para que la operacion sea contabilizada en SBancarios                   
   @i_cot_usd               float        = null,       -- Cotizacion del dolar respecto a la moneda nacional                        
   @i_factor                float        = null,       -- Factor de relacion de la moneda respecto al dolar                         
   @o_valor_convertido      money        = null out,   -- Monto equivalente en la moneda destino                                    
   @o_valor_conver_orig     money        = null out,   -- Monto equivalente en la moneda origen                                     
   @o_cot_usd               float        = null out,   -- Cotizacion del dolar utilizada en la negociacion (Tesoreria/Contabilidad) 
   @o_factor                float        = null out,   -- Factor de relacion de la moneda respecto al dolar(Tesoreria/Contabilidad) 
   @o_msg_error             varchar(255) = null out,   -- Mensaje de retorno del sp en caso de error                                
   @o_cotizacion            float        = null out,   -- Cotizacion de la Moneda respecto a la moneda nacional                     
   @o_tipo_op               estado       = null out,   -- Tipo de Operacion: Compra, Venta o Arbitraje                                
   @o_gen_factura_cv        char(1)      = 'N'  out,
   @o_factura_cv            int          = 0    out,
   @o_sec_fact_cv           int          = 0    out,
   @i_batch                 char(1)      = 'N',
   @t_rty                   char(1)      = 'N',        -- (S/N)
   @i_atm_server            char(1)      = 'N',        -- (S/N)
   @i_origen_divisas        catalogo     = null,        -- Origen de divisas  --> Compra implicitas                                 
   @i_destino_divisas       catalogo     = null,        -- Destino de divisas --> Venta implicitas                                   
   @i_alterno               int          = 1,          -- Codigo alterno   
   @i_empresa               tinyint      = 1,
   @i_num_operacion         char(30)     = null,
   @i_masivo                char(1)      = 'L',    	  -- MASIVO (M), LINEA (L)
   @i_canal                 smallint     = null       -- Codigo del Canal
)
as
  
declare 
   @w_sp_name      varchar(32),      -- Nombre del sp
   @w_numdec       int,              -- Numero de decimales para montos
   @w_numdec_cot   int,              -- Numero de decimales para cotizaciones
   @w_return       int,              -- Retorno de la ejecucion
   @w_producto     tinyint,          -- Codigo de producto COBIS
   @w_sec          int,              -- Sec. para consulta y reversos
   @w_moneda       tinyint,          -- Moneda usada en reversos
  
   @w_tipo_op      estado,           -- Tipo de Operacion: Compra, Venta o Arbitraje
   @w_monto        money,            -- Monto a convertir
   @w_monto_mn     money,            -- Monto equivalente en moneda local 
   @w_monto_me     money,            -- Monto equivalente en moneda extranjera 
   @w_monto_usd    money,            -- Monto equivalente en dolares americanos
   @w_monto_c      money,            -- Monto equivalente en la moneda de compra --> Arbitraje
   @w_monto_v      money,            -- Monto equivalente en la moneda de venta  --> Arbitraje
   @w_cotaux       float,            -- Cotizacion aplicable en arbitraje de divisas (paso intermedio por dolares en operaciones de colones y otras monedas duras distintas al dolar)
                                      
   @w_moneda_o     tinyint,          -- Moneda origen
   @w_moneda_d     tinyint,          -- Moneda destino
   
   /* Variables de parametros generales */      
   @w_int_tesoreria estado,          -- Interface con Tesoreria
   @w_divisas_dolar estado,          -- Las monedas duras se expresan en relacion al dolar
   @w_codmn         tinyint,         -- Codigo de la moneda nacional
   @w_codusd        tinyint,         -- Codigo del dolar americano
   @w_divdol        estado,          -- Parametro que indica paso obligatorio por dolares para negociacion de divisas
   
   /* Variables para la Tesoreria */
   @w_sucursal     smallint,         -- Sucursal de la Tesoreria a la cual corresponde la oficina
   @w_dolar_c      float,            -- Cotizacion dolar compra
   @w_dolar_v      float,            -- Cotizacion dolar venta
   @w_rel_m1       float,            -- Relacion de la moneda1 respecto al dolar
   @w_rel_m2       float,            -- Relacion de la moneda2 respecto al dolar
   @w_costo_1      float,            -- Costo interno moneda1
   @w_costo_2      float,            -- Costo interno moneda2
   @w_mon1_c       float,            -- Cotizacion de compra moneda 1
   @w_mon1_v       float,            -- Cotizacion de venta moneda 1
   @w_mon2_c       float,            -- Cotizacion de compra moneda 2
   @w_mon2_v       float,            -- Cotizacion de venta moneda 2
   @w_mercado      tinyint,          -- Mercado de divisas al que pertenece la oficina
   @w_cambio_of    float,            -- Cambio oficial del dolar
   @w_cambio_ofm1  float,            -- Cambio oficial moneda 1
   @w_cambio_ofm2  float,            -- Cambio oficial moneda 2
   @w_forma_pagcob descripcion,      -- Forma de pago/cobro de las divisas
   @w_id_cliente   varchar(30),      -- Id. del cliente
   @w_nom_cliente  descripcion,      -- Nombre del cliente

   @w_rd_operador  char(1),          -- Operador para control de cotizacion. mon1
   @w_rd_cot_comp  float,            -- Cotizacion Compra
   @w_rd_cot_vent  float,            -- Cotizacion Venta
   @w_rd_operador2 char(1),          -- Operador para control de cotizacion. mon2
   @w_rel_dolm1    float,            -- Relacion dolarizada moneda 1
   @w_rel_dolm2    float,            -- Relacion dolarizada moneda 2
   @w_rd_ope_aux   char(1),          -- Operador Auxiliar 
   @w_rd_cot_inv   float,            
   @w_fecha        datetime,         -- Fecha para Reverso de Operacion 
   @w_desorg_div   catalogo,         -- Origen/Destino divisas 
   @w_usadeci      char(1),
   @w_monto_dest   float,
   @w_moneda_1     tinyint,
   @w_moneda_2     tinyint,
   @w_monav        tinyint,
   @w_monufv       tinyint,
   @w_afec_ofic_cent char(1),
   @w_ci_nit       varchar(20),
   @w_retencion    char(1),
   @w_sub_tipo     char(1),
   @w_valor_imp_me money,
   @w_valor_imp_ml money,
   @w_moneda_imp   tinyint,
   @w_pjuridica    char(10),
   @w_ced_ruc      char(25),
   @w_cotiz_imp    float,
   @w_tipo_fact    char(1),
   @w_alt          int,
   @w_secuencial   int
        
/* Variables para Servicios Bancarios */   
select @w_sp_name  = 'sp_op_divisas_automatica',
       @w_moneda_o = @i_moneda_origen,
       @w_moneda_d = @i_moneda_destino, 
       @w_monto_c  = 0,
       @w_monto_v  = 0,
       @w_cotaux   = 1
   
if @i_valor_destino = 0 --TCA Inci_25573
   select @w_monto = @i_valor
else
   select @w_monto = @i_valor_destino
         
/**************************************************/
/* 1. LECTURA DE PARAMETROS GENERALES             */
/**************************************************/

--Origen de divisas
select @i_origen_divisas = pa_char 
from cobis..cl_parametro 
where pa_nemonico  = 'ODCOMP'
  and pa_producto = 'BVI' 

--Destino de divisas
select @i_destino_divisas = pa_char 
from cobis..cl_parametro 
where pa_nemonico  = 'ODVENT'
  and pa_producto = 'BVI' 

-- Parametro de Tesoreria disponible
select @w_int_tesoreria = 'S'
  
-- Afecta Posicion de Moneda en la Oficina Centralizadora de la Tesoreria
select @w_afec_ofic_cent = 'N'
      
-- Codigo de moneda local
select @w_codmn = pa_tinyint
from cobis..cl_parametro
where pa_producto = 'ADM'
  and pa_nemonico = 'MLO' --'CMNAC'   
  
-- Codigo de moneda base para tipos de cambio (DOLAR)
select @w_codusd = pa_tinyint
from cobis..cl_parametro
where pa_producto = 'ADM'
  and pa_nemonico = 'CDOLAR'

--Encuentra parametro de decimales
select @w_usadeci = mo_decimales
from cobis..cl_moneda
where mo_moneda = @i_moneda_origen

if @w_usadeci = 'S'
begin   
  -- Numero de decimales para montos
  select @w_numdec = pa_tinyint
  from cobis..cl_parametro
  where pa_producto = 'ADM'
  and pa_nemonico = 'DECME'
end
else
  select @w_numdec = 0
  
-- Numero de decimales para cotizaciones
select @w_numdec_cot = pa_tinyint
from cobis..cl_parametro
where pa_producto = 'TES'
  and pa_nemonico = 'DECTAS'     
  
-- Paso obligatorio por dolares en compra / venta de moneda extranjera
select @w_divdol = 'S'

-- Busca monedas de MV
select @w_monav = pa_tinyint 
  from cobis..cl_parametro 
 where pa_nemonico = 'MOMANV' 
   and pa_producto = 'CON'
 
select @w_monufv = pa_tinyint 
  from cobis..cl_parametro 
 where pa_nemonico = 'MONUFV' 
   and pa_producto = 'CON'  



-- Consulta informacion Cliente
if @i_operacion <> 'C'
begin
   select @w_id_cliente  = en_ced_ruc,
          @w_nom_cliente = en_nomlar
   from cobis..cl_ente
   where en_ente = @i_cliente
   
   -- Verificacion de existencia del cliente en COBIS
   if @@rowcount = 0
   begin 
      select @o_msg_error = '[' + @w_sp_name + '] ' + 'NO SE ENCUENTRA LA INFORMACION DEL CLIENTE PROPIO'
      return 2902837      
   end  
end   


-- Lectura del producto COBIS
select @w_producto = pd_producto
from cobis..cl_producto
where pd_abreviatura = @i_modulo   

if @w_producto is null  
begin 
   select @o_msg_error = '[' + @w_sp_name + '] ' + 'NO SE ENCUENTRA INFORMACION DEL PRODUCTO COBIS'
   return 2902838        
end 
  
-- Verificacion de existencia de parametros generales
if @w_int_tesoreria is null or @w_codmn is null or @w_codusd is null or @w_numdec is null or @w_numdec_cot is null or @w_divdol is null -- LPO No usar estas monedas or @w_monav is null or @w_monufv is null 
   or @w_afec_ofic_cent is null
begin 
   select @o_msg_error = '[' + @w_sp_name + '] ' + 'ERROR AL LEER LOS PARAMETROS GENERALES'
   return 2902839         
end   
  
-- Verificacion de monedas
if @w_moneda_o = @w_moneda_d and @i_operacion <> 'R'
begin 
   --LPO CDIG Multimoneda INICIO
   IF @w_moneda_o = @w_codmn
   BEGIN
      select @o_cotizacion = 1.0
      select @o_tipo_op = 'N'      
      SELECT @o_valor_convertido = @i_valor
      RETURN 0
   END
/*   ELSE
   BEGIN
      SELECT @i_cot_contable = 'S'
   END
*/   
   --LPO CDIG Multimoneda FIN
   
   --select @o_msg_error = '[' + @w_sp_name + '] ' + 'LAS MONEDAS DE ORIGEN Y DESTINO SON IGUALES.  NO REQUIERE UNA OPERACION DE DIVISAS IMPLICITA' --LPO CDIG Multimoneda
   --return 2902841 --LPO CDIG Multimoneda
end

-- Validar que la conversion de Moneda Indexada solo se puede realizar con relacion a la Moneda Local
if (@w_moneda_o in (@w_monav, @w_monufv) and @w_moneda_d <> @w_codmn) or (@w_moneda_d in (@w_monav, @w_monufv) and @w_moneda_o <> @w_codmn)
begin
	if @w_int_tesoreria = 'S'
	begin
		select @o_msg_error = '[' + @w_sp_name + '] ' + 'NO ESTA PERMITIDO REALIZAR CONVERSION'
		return 2902913
	end
end

if @w_moneda_o <> @w_codmn and @w_moneda_d <> @w_codmn and @i_operacion <> 'R'  -- Si ambas monedas son ME
begin
   if @w_int_tesoreria = 'S'
   begin
      if @w_moneda_o <> @w_codusd and @w_moneda_d <> @w_codusd -- y ninguna es dolar americano ==> retornar error
      begin
         select @o_msg_error = '' --LPO CDIG Multimoneda --'[' + @w_sp_name + '] ' + 'PARA NEGOCIAR MONEDAS DURAS, UNA DE ELLAS DEBE SER EL DOLAR AMERICANO'
         --return 2902842 --LPO CDIG Multimoneda
      end
   end
   else -- Para SBA solo se habilitan compras o ventas no se maneja arbitraje de divisas
   begin
      select @o_msg_error = '[' + @w_sp_name + '] ' + 'LAS MONEDAS DE ORIGEN Y DESTINO SON EXTRANJERAS.  NO SE PUEDE REALIZAR LA OPERACION DE DIVISAS'
      return 2902843
   end
end

-- Verificacion de Valor cuando @i_operacion = 'E'
if @w_monto = 0 and @i_operacion = 'E'
begin
      select @o_msg_error = '[' + @w_sp_name + '] ' + 'PARA LA EJECUCION DE LA NEGOCIACION DE DIVISAS EN NECESARIO INGRESAR UN VALOR MAYOR A CERO'
      return 2902844
end


-- Validar que preexistencias con el mismo @s_ssn
if @i_operacion = 'E'
begin
   if @w_int_tesoreria = 'S'
   begin
      if exists (select 1 from ca_ope_divisas where od_cod_operacion = @s_ssn and od_modulo = @w_producto and @w_producto not in (3,4)
      and od_estado  = 'N' and od_cod_alterno = @i_alterno)
      begin
         select @o_msg_error = '[' + @w_sp_name + '] ' + 'YA EXISTE UNA OPERACION DE DIVISAS CON EL SECUENCIAL UNICO COBIS'
         return 2902845
      end      
   end
   else
   begin
      if exists (select 1 from sb_operacion
                where op_ssn = @s_ssn)
      begin
         select @o_msg_error = '[' + @w_sp_name + '] ' + 'YA EXISTE UNA OPERACION DE DIVISAS CON EL SECUENCIAL UNICO COBIS'
         return 2902845
      end         
   end
end

-- Verificacion de datos obligatorios para la opcion de Ejecucion
if @i_operacion = 'E' and @i_concepto is null
begin 
   select @o_msg_error = '[' + @w_sp_name + '] ' + 'DEBE REGISTRAR EL CONCEPTO DE LA TRANSACCION'
   return 2902846
end   

-- Verificacion de existencia del cliente en COBIS
if @i_operacion <> 'C'
begin 
   if not exists (select 1 from cobis..cl_ente where en_ente = @i_cliente)
   begin
      select @o_msg_error = '[' + @w_sp_name + '] ' + 'NO SE ENCUENTRA LA INFORMACION DEL CLIENTE PROPIO'
      return 2902847        
   end
end      
   
/**************************************************/
/* 2. SETEO DEL TIPO DE OPERACION A REALIZAR      */
/**************************************************/

-- Determinar si es compra/venta o arbitraje
if @w_divdol = 'S'
begin
   -- La compra y venta sera siempre entre dolares y moneda nacional, si fuera otra moneda dura se requiere generar la operacion de compra/venta de dolares y el arbitraje entre el dolar y la moneda dura
   if (@w_moneda_o = @w_codusd and @w_moneda_d = @w_codmn) or (@w_moneda_o in (@w_monav, @w_monufv) and @w_moneda_d = @w_codmn) --LPO
      select @w_tipo_op = 'C'  -- Compra
   else if (@w_moneda_o = @w_codmn and @w_moneda_d = @w_codusd) or (@w_moneda_d in (@w_monav, @w_monufv) and @w_moneda_o = @w_codmn) --LPO
      select @w_tipo_op = 'V'  -- Venta
   else
      select @w_tipo_op = 'A'  -- Arbitraje
end
else
begin
   -- Arbitraje se aplica cuando la negociacion es entre dos monedas extranjeras
   if @w_moneda_o <> @w_codmn 
      select @w_tipo_op = 'C'  -- Compra
   else 
      select @w_tipo_op = 'V'  -- Venta
end

--LPO CDIG Multimoneda INICIO:
IF @i_moneda_origen = @i_moneda_destino and @i_moneda_origen <> @w_codmn AND @i_concepto = 'DES'
BEGIN
   --SELECT @i_cot_contable = 'S'
   SELECT @w_tipo_op = 'C'
END

IF @i_moneda_origen = @i_moneda_destino and @i_moneda_origen <> @w_codmn AND @i_concepto = 'PAG'
BEGIN
   --SELECT @i_cot_contable = 'S'
   SELECT @w_tipo_op = 'V'
END
--LPO CDIG Multimoneda FIN


select @o_tipo_op = @w_tipo_op


/*******************************************************************/
/* 3. CONSULTA DE MONTO EQUIVALENTE TOMANDO LA COTIZACION CONTABLE */
/*******************************************************************/
if @i_operacion = 'C' and @i_cot_contable = 'S'
begin
   -- Lectura de cotizaciones contables del dolar y de las monedas de compra y venta
   select @w_cambio_of = ct_valor
   from cob_conta..cb_cotizacion
   where ct_empresa = 1
     and ct_moneda  = @w_codusd
     and ct_fecha = (select max(ct_fecha) from cob_conta..cb_cotizacion 
		                where ct_empresa = 1 
						  and ct_moneda  = @w_codusd
						  and ct_fecha   <= @s_date
		                )
   
   if @w_cambio_of is null
   begin 
      select @o_msg_error = '[' + @w_sp_name + '] ' + 'ERROR AL LEER LA COTIZACION CONTABLE DEL DOLAR'
      return 2902848         
   end
   
   -- Mon. Origen  
   if @w_moneda_o = @w_codmn 
      select @w_cambio_ofm1 = 1
   else
   begin
      select @w_cambio_ofm1 = ct_valor
      from cob_conta..cb_cotizacion
      where ct_empresa = 1
        and ct_moneda  = @w_moneda_o
        and ct_fecha = (select max(ct_fecha) from cob_conta..cb_cotizacion
		                   where ct_empresa = 1 
						     and ct_moneda  = @w_moneda_o
							 and ct_fecha   <= @s_date
						  )
        
      if @w_cambio_ofm1 is null
      begin 
         select @o_msg_error = '[' + @w_sp_name + '] ' + 'ERROR AL LEER LA COTIZACION CONTABLE DE LA MONEDA ORIGEN'
         return 2902849         
      end
   end      
   
   -- Mon. Destino
   if @w_moneda_d = @w_codmn 
      select @w_cambio_ofm2 = 1
   else
   begin
      select @w_cambio_ofm2 = ct_valor
      from cob_conta..cb_cotizacion
      where ct_empresa = 1
        and ct_moneda  = @w_moneda_d
        and ct_fecha = (select max(ct_fecha) from cob_conta..cb_cotizacion
		                   where ct_empresa = 1 
						     and ct_moneda  = @w_moneda_d
							 and ct_fecha   <= @s_date
					      )
        
      if @w_cambio_ofm2 is null
      begin 
         select @o_msg_error = '[' + @w_sp_name + '] ' + 'ERROR AL LEER LA COTIZACION CONTABLE DE LA MONEDA DESTINO'
         return 2902850
      end            
   end
     
   -- Calculo de la relacion con respecto al dolar de las monedas de origen y destino
   if @w_moneda_o = @w_codmn
      select @w_rel_m1 = 1
   else
      select @w_rel_m1 = round(@w_cambio_ofm1 / @w_cambio_of, @w_numdec_cot)
      
   if @w_moneda_d = @w_codmn
      select @w_rel_m2 = 1
   else
      select @w_rel_m2 = round(@w_cambio_ofm2 / @w_cambio_of, @w_numdec_cot)

         
   -- Calculo del monto convertido: Venta
   if @w_tipo_op = 'V'
   begin
      select @w_cotaux   = @w_cambio_of
      
      select @w_monto_mn = @w_monto,
             --@w_monto_me =  round(@w_monto * (@w_rel_m2 * @w_cotaux), @w_numdec)
             @w_monto_me =  round(@w_monto / (@w_rel_m2 * @w_cotaux), @w_numdec) --LPO 
             
      select @o_valor_convertido = @w_monto_me,
             @o_cot_usd = @w_cotaux,
             @o_factor  = @w_rel_m2,
             @o_cotizacion = @w_cambio_ofm2 
   end


   -- Calculo del monto convertido: Compra
   if @w_tipo_op = 'C'
   begin
      select @w_cotaux   = @w_cambio_of         
   
      select @w_monto_me = @w_monto,
             @w_monto_mn = round(@w_monto * @w_rel_m1 * @w_cotaux, @w_numdec)
             
      select @o_valor_convertido = @w_monto_mn,
             @o_cot_usd = @w_cotaux,
             @o_factor  = @w_rel_m1,
             @o_cotizacion = @w_cambio_ofm1 
   end

         
   -- Calculo del monto convertido: Arbitraje
   if @w_tipo_op = 'A'
   begin
      -- La moneda de origen y destino son moneda extranjera y una de ellas es dolares.  Regulatoriamente en CR toda operacion de divisas debe realizarse con el dolar americano
      if @w_moneda_o <> @w_codmn and @w_moneda_d <> @w_codmn
      begin
         select @w_cotaux = @w_cambio_of  -- Aplica cotizacion contable
      
         select @w_monto_c  = @w_monto,
                @w_monto_mn = round(@w_monto * @w_rel_m1 * @w_cotaux, @w_numdec)
         
         select @w_monto_v = round(@w_monto_mn / (@w_rel_m2 * @w_cotaux), @w_numdec)
         
         select @o_valor_convertido = @w_monto_v,
                @o_cot_usd = @w_cotaux
         if @w_moneda_o = @w_codusd
            select @o_factor  = @w_rel_m2,
                   @o_cotizacion = @w_cambio_ofm2
         else
            select @o_factor  = @w_rel_m1,
                   @o_cotizacion = @w_cambio_ofm1
         
      end
                     

      -- Si la moneda destino es ME ==> Venta de dolares, y arbitraje dolar vs. moneda extranjera (compra dolar - venta ME)
      if @w_moneda_d <> @w_codmn and @w_moneda_o = @w_codmn
      begin
         select @w_cotaux = @w_cambio_of  -- Aplica cotizacion contable
                       
         select @w_monto_mn  = @w_monto,
                @w_monto_usd = round(@w_monto / @w_cotaux, @w_numdec),
                @w_monto_v   = round(@w_monto / (@w_rel_m2 * @w_cotaux), @w_numdec)
         
         select @o_valor_convertido = @w_monto_v,
                @o_cot_usd = @w_cotaux,
                @o_factor  = @w_rel_m2,
                @o_cotizacion = @w_cambio_ofm2
      end
      
      -- Si la moneda origen es ME ==> Arbitraje moneda extranjera vs. dolar (compra ME - venta dolar), y compra dolar 
      if @w_moneda_o <> @w_codmn and @w_moneda_d = @w_codmn
      begin
         select @w_cotaux = @w_cambio_of  -- Aplica cotizacion contable
                       
         select @w_monto_c   = @w_monto,
                @w_monto_mn  = round(@w_monto * @w_rel_m1 * @w_cotaux, @w_numdec),
                @w_monto_usd = round(@w_monto * @w_rel_m1, @w_numdec)
         
         select @o_valor_convertido = @w_monto_mn,
                @o_cot_usd = @w_cotaux,
                @o_factor  = @w_rel_m1,
                @o_cotizacion = @w_cambio_ofm1
      end 
      
   end  -- FIN: if @w_tipo_op = 'A'

   -- Termina la ejecucion
   IF @i_moneda_origen = @i_moneda_destino --LPO CDIG Multimoneda
      SELECT @o_tipo_op = 'N'
   
   return 0
   
end      

/**************************************************/
/* 4. MANEJO DE DIVISAS EN TESORERIA              */
/**************************************************/
if @w_int_tesoreria = 'S'
begin
   ----------------------------------------------------------------- 
   -- CONSULTA DE MONTO EQUIVALENTE CON LA COTIZACION DE PIZARRA  --
   -----------------------------------------------------------------
   if @i_operacion = 'C'
   begin
	  if @w_afec_ofic_cent = 'S'
	  begin
		  -- Busqueda de sucursal asociada a la oficina
		  select @w_sucursal = st_sucursal
		  from   cob_tesoreria..te_sucursal_tesoreria
		  where  st_cod_oficina =  @i_oficina
		  
		  if @w_sucursal is null
		  begin 
			 select @o_msg_error = '[' + @w_sp_name + '] ' + 'NO SE ENCUENTRA LA PARAMETRIZACION DE LA SUCURSAL ASOCIADA EN TESORERIA'
			 return 2902855        
		  end
	  end
	  else
		  select @w_sucursal = @i_oficina
            
      -- Busqueda de cotizaciones de pizarra
      if @w_tipo_op = 'V'
         SELECT @w_moneda_o = @w_moneda_d,
                @w_moneda_d = null
	  
	  if @w_tipo_op in ('V','C')
	     SELECT @w_moneda_1 = @w_moneda_o,
				@w_moneda_2 = @w_moneda_d
				
	  if @w_tipo_op = 'A' 
	  begin
	     if @w_moneda_o <> @w_codmn and @w_moneda_d = @w_codmn
			select @w_moneda_1 = @w_moneda_o,
				   @w_moneda_2 = null
		 else
			if @w_moneda_o = @w_codmn and @w_moneda_d <> @w_codmn
				select @w_moneda_1 = @w_moneda_d,
					   @w_moneda_2 = null
			else 
			   	select @w_moneda_1 = @w_moneda_o,
					   @w_moneda_2 = @w_moneda_d
	  end

      exec @w_return = cob_tesoreria..sp_buscar_posicion_arbitraje
           @t_trn          = 1640073,
           @i_suctes       = @w_sucursal,
           @i_fecha        = @s_date,
           @i_coddolar     = @w_codusd,                /* codigo del dolar           */
           @i_codmn        = @w_codmn,                 /* codigo de la moneda local  */
           @i_moneda1      = @w_moneda_1,              /* moneda origen              */
           @i_moneda2      = @w_moneda_2,              /* moneda destino             */
           @o_dolar_c      = @w_dolar_c       out,     /* cotizacion dolar compra    */
           @o_dolar_v      = @w_dolar_v       out,     /* cotizacion dolar venta     */
           @o_rel_m1       = @w_rel_m1        out,     /* relacion dolar - moneda1   */
           @o_rel_m2       = @w_rel_m2        out,     /* relacion dolar - moneda2   */
           @o_costo_1      = @w_costo_1       out,     /* costo posicion compra      */
           @o_costo_2      = @w_costo_2       out,     /* costo posicion venta       */
           @o_mon1_c       = @w_mon1_c        out,     /* cotizacion compra moneda 1 */
           @o_mon1_v       = @w_mon1_v        out,     /* cotizacion venta moneda 1  */
           @o_mon2_c       = @w_mon2_c        out,     /* cotizacion compra moneda 2 */
           @o_mon2_v       = @w_mon2_v        out,     /* cotizacion venta moneda 2  */
           @o_cambio_of    = @w_cambio_of     out,     /* cotizacion oficial dolar   */
           @o_cambio_ofm1  = @w_cambio_ofm1   out,     /* cotizacion oficial mon 1   */
           @o_cambio_ofm2  = @w_cambio_ofm2   out,     /* cotizacion oficial mon 2   */
           @o_rd_operador  = @w_rd_operador   out,     /* Operador para control de cotizacion mon 1 */
           @o_rd_cot_comp  = @w_rd_cot_comp   out,     /* Cotizacion Compra          */
           @o_rd_cot_vent  = @w_rd_cot_vent   out,     /* Cotizacion Venta           */
           @o_rd_operador2 = @w_rd_operador2  out,     /* Operador para control de cotizacion mon 2 */
           @o_rel_dolm1    = @w_rel_dolm1     out,     /* Relacion dolarizada moneda 1 */
           @o_rel_dolm2    = @w_rel_dolm2     out      /* Relacion dolarizada moneda 2 */ 
			  
      if @w_return <> 0 -- or ((@w_rel_dolm1 = 0 and @w_moneda_o != @w_codusd) or (@w_rel_dolm2 = 0 and @w_moneda_d != @w_codusd)) -- TCA Inci_32315
      begin		    
         select @o_msg_error = '[' + @w_sp_name + '] ' + 'ERROR AL OBTENER LAS COTIZACIONES DE LA PIZARRA'
         return 2902856
      end
      

      ---------------------------------------------------------------------------------
      -- Calculo de valores dolarizados, cuando es C o V siempre se envia solo MONEDA1
      ---------------------------------------------------------------------------------
	  if @w_tipo_op in ('C', 'V')
	  begin
		if @w_tipo_op = 'C'
			select @o_cotizacion = @w_mon1_c, 
				   @o_cot_usd = @w_dolar_c, 
				   @o_factor = @w_rel_dolm1
		else
			select @o_cotizacion = @w_mon1_v, 
				   @o_cot_usd = @w_dolar_v, 
				   @o_factor = @w_rel_dolm1
		
		 if @w_moneda_o in (@w_monav, @w_monufv) or @w_moneda_d in (@w_monav, @w_monufv)
		 begin
            if @i_valor_destino = 0 --TCA Inci_25573
            begin
				select @w_monto_me = @w_monto,
					   @w_monto_mn = round(@w_monto * @o_cotizacion, @w_numdec)
				select @o_valor_convertido = @w_monto_mn                       --Convertido a moneda Nacional
			end
			else
			begin
				select @w_monto_mn = @w_monto,
					   @w_monto_me = round(@w_monto / (@o_cotizacion), @w_numdec)
				select @o_valor_conver_orig = @w_monto_me                      --Convertido a moneda Extranjera
			end
		 end
		 ELSE IF @i_moneda_origen = @w_codmn --LPO CDIG
		 begin
            if @i_valor_destino = 0 --TCA Inci_25573
		    begin
				select @w_monto_mn = @w_monto,
					   @w_monto_me = round(@w_monto / (@w_rel_dolm1 * @o_cotizacion), @w_numdec)
				select @o_valor_convertido = @w_monto_me --select @o_valor_conver_orig = @w_monto_me --Convertido a moneda Extranjera --LPO
--PRINT '1'				
		    END
			else
			begin
				select @w_monto_me = @w_monto,
					   @w_monto_mn = round(@w_monto * @w_rel_dolm1 * @o_cotizacion, @w_numdec)
				select @o_valor_conver_orig = @w_monto_mn --select @o_valor_convertido = @w_monto_mn --Convertido a moneda Nacional --LPO
			end		   
         END
         ELSE
         BEGIN
            if @i_valor_destino = 0 --TCA Inci_25573
		    begin
				select @w_monto_mn = @w_monto,
					   @w_monto_me = round(@w_monto * (@w_rel_dolm1 * @o_cotizacion), @w_numdec)
				select @o_valor_convertido = @w_monto_me --select @o_valor_conver_orig = @w_monto_me --Convertido a moneda Extranjera
		    END
			else
			begin
				select @w_monto_me = @w_monto,
					   @w_monto_mn = round(@w_monto / @w_rel_dolm1 * @o_cotizacion, @w_numdec)
				select @o_valor_conver_orig = @w_monto_mn --select @o_valor_convertido = @w_monto_mn --Convertido a moneda Nacional

			end		            
         END
      end
      
	  
      -- Arbitraje o Monedas Duras
      if @w_tipo_op = 'A'
      begin
         -- La moneda de origen y destino son moneda extranjera y una de ellas es dolares.  Regulatoriamente en CR toda operacion de divisas debe realizarse con el dolar americano
         if @w_moneda_o <> @w_codmn and @w_moneda_d <> @w_codmn
         begin
		 
            if @w_moneda_o = @w_codusd
            begin
	
               select @w_cotaux = @w_dolar_v  -- Aplica cotizacion dolar venta
               
               select @w_rd_ope_aux = @w_rd_operador2

               if @w_rd_operador2 = '*'
                  select @w_rd_cot_inv = @w_rel_dolm2
               else
                  select @w_rd_cot_inv = round(1/@w_rel_dolm2,@w_numdec_cot)

               select @o_cot_usd = @w_cotaux,
                      @o_factor  = @w_rel_dolm2,
                      @o_cotizacion = round(@w_cotaux * @w_rd_cot_inv,@w_numdec_cot)   

            end
            else
            begin
               select @w_cotaux = @w_dolar_c  -- Aplica cotizacion dolar compra

               select @w_rd_ope_aux = @w_rd_operador                  

               if @w_rd_operador = '*'
                  select @w_rd_cot_inv = @w_rel_dolm1
               else
                  select @w_rd_cot_inv = round(1/@w_rel_dolm1,@w_numdec_cot)
               
               select @o_cot_usd = @w_cotaux,
                      @o_factor  = @w_rel_dolm1,
                      @o_cotizacion = round(@w_cotaux * @w_rd_cot_inv,@w_numdec_cot) 


            end
            
            
            select @w_monto_c  = @w_monto
            if @w_rd_ope_aux = '*'
            begin
               select @w_monto_mn = round(@w_monto * @w_rel_dolm1 * @w_cotaux, @w_numdec)
               select @w_monto_v = round(@w_monto_mn / (@w_rel_dolm2 * @w_cotaux), @w_numdec)
            end
            else
            begin 
               select @w_monto_mn = round((@w_monto * @w_cotaux) / @w_rel_m1, @w_numdec)
               select @w_monto_v = round((@w_monto_mn * @w_rel_dolm2) / @w_cotaux, @w_numdec)
            end
            
            select @o_valor_convertido = @w_monto_v
                                                 
         end
         
         -- Si la moneda destino es ME ==> Venta de dolares, y arbitraje dolar vs. moneda extranjera (compra dolar - venta ME)
         if @w_moneda_d <> @w_codmn and @w_moneda_o = @w_codmn
         begin
            -- if isnull(@w_rel_dolm1, 0) = 0 or isnull(@w_dolar_v, 0) = 0
            -- begin 
            --    select @o_msg_error = '[' + @w_sp_name + '] ' + 'ERROR AL LEER LA COTIZACION CONTABLE DE LA MONEDA DESTINO'
            --    return 1         
            -- end  				
			
            select @w_cotaux = @w_dolar_v  -- Aplica cotizacion dolar venta
            
			if @i_valor_destino = 0
			begin
                if @w_rd_operador2 = '*'
                    select @w_monto_v    = round(@w_monto / (@w_rel_dolm1 * @w_cotaux), @w_numdec),
                           @w_rd_cot_inv = round(@w_rel_dolm1,@w_numdec_cot)
                else               
                    select @w_monto_v    = round((@w_monto * @w_rel_dolm1) / @w_cotaux, @w_numdec), 
                           @w_rd_cot_inv = round(1/@w_rel_dolm1,@w_numdec_cot)
            
			    select @w_monto_mn  = @w_monto,
                       @w_monto_usd = round(@w_monto / @w_cotaux, @w_numdec)
						   
                select @o_valor_convertido = @w_monto_v
            end
			else
		    begin
			    if @w_rd_operador2 = '*'
				   select @w_monto_dest = round(@w_monto * @w_rel_dolm1 * @w_cotaux, @w_numdec),
						  @w_rd_cot_inv = round(@w_rel_dolm1,@w_numdec_cot)
				else               
				   select @w_monto_dest = round((@w_monto / @w_rel_dolm1) * @w_cotaux, @w_numdec), 
						  @w_rd_cot_inv = round(1/@w_rel_dolm1,@w_numdec_cot)

				select @w_monto_mn  = @w_monto_dest,
				       @w_monto_v   = @w_monto,
                       @w_monto_usd = round(@w_monto_dest/ @w_cotaux, @w_numdec) 
					   
				select @o_valor_conver_orig = @w_monto_dest
			end

            select @o_cot_usd = @w_cotaux,
                   @o_factor  = @w_rel_dolm1,
                   @o_cotizacion = round(@w_cotaux * @w_rd_cot_inv,@w_numdec_cot)                 
         end
         
         
         -- Si la moneda origen es ME ==> Arbitraje moneda extranjera vs. dolar (compra ME - venta dolar), y compra dolar 
         if @w_moneda_o <> @w_codmn and @w_moneda_d = @w_codmn
         begin
			
            -- if isnull(@w_rel_dolm1, 0) = 0 or isnull(@w_dolar_c, 0) = 0
            -- begin 
            --    select @o_msg_error = '[' + @w_sp_name + '] ' + 'ERROR AL LEER LA COTIZACION CONTABLE DE LA MONEDA DESTINO'
            --    return 1         
            -- end  	
			
            select @w_cotaux = @w_dolar_c  -- Aplica cotizacion dolar compra
                          
			if @i_valor_destino = 0
			begin 
                if @w_rd_operador = '*'
                    select @w_monto_mn   = round(@w_monto * @w_rel_dolm1 * @w_cotaux, @w_numdec),
                           @w_monto_usd  = round(@w_monto * @w_rel_dolm1, @w_numdec),
                           @w_rd_cot_inv = round(@w_rel_dolm1,@w_numdec_cot) 
                else
                    select @w_monto_mn   = round((@w_monto * @w_cotaux) / @w_rel_dolm1, @w_numdec),
                           @w_monto_usd  = round(@w_monto / @w_rel_dolm1, @w_numdec), 
                           @w_rd_cot_inv = round(1/@w_rel_dolm1,@w_numdec_cot) 
                
				select @w_monto_c   = @w_monto
                select @o_valor_convertido = @w_monto_mn            
            end
			else
            begin
				if @w_rd_operador = '*'
				begin
				    select @w_monto_dest  = round(@w_monto / (@w_rel_dolm1 * @w_cotaux), @w_numdec)
					select @w_monto_usd   = round(@w_monto_dest * @w_rel_dolm1, @w_numdec),
						   @w_rd_cot_inv  = round(@w_rel_dolm1,@w_numdec_cot) 
				end
				else
				begin
				    select @w_monto_dest  = round((@w_monto / @w_cotaux) * @w_rel_dolm1, @w_numdec)
				    select @w_monto_usd   = round(@w_monto_dest / @w_rel_dolm1, @w_numdec), 
						   @w_rd_cot_inv  = round(1/@w_rel_dolm1,@w_numdec_cot) 
				end
				
				select @w_monto_mn = @w_monto,
				       @w_monto_c  = @w_monto_dest
					   
				select @o_valor_conver_orig = @w_monto_dest 
			end
 			
            select @o_cot_usd = @w_cotaux,
                   @o_factor  = @w_rel_dolm1,
                   @o_cotizacion = round(@w_cotaux * @w_rd_cot_inv,@w_numdec_cot)
         end 
      end  -- FIN: if @w_tipo_op = 'A'
               
   end -- FIN: if @i_operacion = 'C'
      
   ---------------------------------------------------- 
   -- EJECUCION DE OPERACION DE DIVISAS Y POSICION   --
   ----------------------------------------------------       
   if @i_operacion = 'E'
   begin
      -- Datos requeridos por la Tesoreria
      select @w_forma_pagcob = ''
      
      select @w_forma_pagcob = @i_concepto
      
		 if @i_valor_destino = 0 --TCA Inci_25573
      select @w_monto = @i_valor
		 else
		 select @w_monto = @i_valor_destino
      
	  if @w_afec_ofic_cent = 'S'
	  begin
		  -- Busqueda de sucursal asociada a la oficina
		  select @w_sucursal = st_sucursal
		  from   cob_tesoreria..te_sucursal_tesoreria
		  where  st_cod_oficina =  @i_oficina
		  
		  if @w_sucursal is null
		  begin 
			 select @o_msg_error = '[' + @w_sp_name + '] ' + 'NO SE ENCUENTRA LA PARAMETRIZACION DE LA SUCURSAL ASOCIADA EN TESORERIA'
			 return 2902855
		  END
	  end
	  else
	      select @w_sucursal = @i_oficina
               
      -- Busqueda de cotizaciones de pizarra
      if @w_tipo_op = 'V'
         SELECT @w_moneda_o = @w_moneda_d,
                @w_moneda_d = null
	  
	  if @w_tipo_op in ('V','C')
	     SELECT @w_moneda_1 = @w_moneda_o,
				@w_moneda_2 = @w_moneda_d
	  
	  if @w_tipo_op = 'A' 
	  begin
	     if @w_moneda_o <> @w_codmn and @w_moneda_d = @w_codmn
			select @w_moneda_1 = @w_moneda_o,
				   @w_moneda_2 = null
		 else
			if @w_moneda_o = @w_codmn and @w_moneda_d <> @w_codmn
				select @w_moneda_1 = @w_moneda_d,
					   @w_moneda_2 = null
			else 
			   	select @w_moneda_1 = @w_moneda_o,
					   @w_moneda_2 = @w_moneda_d
	  end
      
      exec @w_return = cob_tesoreria..sp_buscar_posicion_arbitraje
           @t_trn          = 1640073,
           @i_suctes       = @w_sucursal,
           @i_fecha        = @s_date,
           @i_coddolar     = @w_codusd,                /* codigo del dolar           */
           @i_codmn        = @w_codmn,                 /* codigo de la moneda local  */
           @i_moneda1      = @w_moneda_1,              /* moneda origen              */
           @i_moneda2      = @w_moneda_2,              /* moneda destino             */
           @o_dolar_c      = @w_dolar_c       out,     /* cotizacion dolar compra    */
           @o_dolar_v      = @w_dolar_v       out,     /* cotizacion dolar venta     */
           @o_rel_m1       = @w_rel_m1        out,     /* relacion dolar - moneda1   */
           @o_rel_m2       = @w_rel_m2        out,     /* relacion dolar - moneda2   */
           @o_costo_1      = @w_costo_1       out,     /* costo posicion compra      */
           @o_costo_2      = @w_costo_2       out,     /* costo posicion venta       */
           @o_mon1_c       = @w_mon1_c        out,     /* cotizacion compra moneda 1 */
           @o_mon1_v       = @w_mon1_v        out,     /* cotizacion venta moneda 1  */
           @o_mon2_c       = @w_mon2_c        out,     /* cotizacion compra moneda 2 */
           @o_mon2_v       = @w_mon2_v        out,     /* cotizacion venta moneda 2  */
           @o_cambio_of    = @w_cambio_of     out,     /* cotizacion oficial         */
           @o_cambio_ofm1  = @w_cambio_ofm1   out,     /* cotizacion oficial mon 1   */
           @o_cambio_ofm2  = @w_cambio_ofm2   out,     /* cotizacion oficial mon 2   */
           @o_rd_operador  = @w_rd_operador   out,     /* Operador para control de cotizacion mon 1 */
           @o_rd_cot_comp  = @w_rd_cot_comp   out,     /* Cotizacion Compra          */
           @o_rd_cot_vent  = @w_rd_cot_vent   out,     /* Cotizacion Venta           */
           @o_rd_operador2 = @w_rd_operador2  out,     /* Operador para control de cotizacion mon 2 */
           @o_rel_dolm1    = @w_rel_dolm1     out,     /* Relacion dolarizada moneda 1 */
           @o_rel_dolm2    = @w_rel_dolm2     out      /* Relacion dolarizada moneda 2 */ 
           
      if @w_return <> 0
      begin
         select @o_msg_error = '[' + @w_sp_name + '] ' + 'ERROR AL OBTENER LAS COTIZACIONES DE LA PIZARRA'
         return 2902856
      end
      
      -- Actualizo la cotizacion y factor con los parametros enviados
      if @i_cot_usd is not null and @i_factor is not null
      begin
         select @w_dolar_v   = @i_cot_usd,
                @w_dolar_c   = @i_cot_usd
         
         if @w_tipo_op in ('V','C')
            select @w_rel_dolm1 = @i_factor,
                   @w_rel_dolm2 = @i_factor
      end  
      
      -------------------------------------------------------------------         
      -- Asignacion de valores para grabar nuevas operaciones de divisas
      -------------------------------------------------------------------
      if @w_tipo_op in ('C', 'V')
      begin
         if @w_tipo_op = 'C'
            select @o_cotizacion = @w_mon1_c, 
                   @o_cot_usd = @w_dolar_c, 
                   @o_factor = @w_rel_dolm1,
				   @w_cotaux  = @w_mon1_c
         else
            select @o_cotizacion = @w_mon1_v, 
                   @o_cot_usd = @w_dolar_v, 
                   @o_factor = @w_rel_dolm1,
				   @w_cotaux  = @w_mon1_v
         
		 if @w_moneda_o in (@w_monav, @w_monufv) or @w_moneda_d in (@w_monav, @w_monufv)
		 begin
			if @i_valor_destino = 0 --TCA Inci_25573
			begin
				select @w_monto_me = @w_monto,
					   @w_monto_mn = round(@w_monto * @o_cotizacion, @w_numdec)
				select @o_valor_convertido = @w_monto_mn                       --Convertido a moneda Nacional
			end
			else
			begin
				select @w_monto_mn = @w_monto,
					   @w_monto_me = round(@w_monto / (@o_cotizacion), @w_numdec)
				select @o_valor_conver_orig = @w_monto_me                      --Convertido a moneda Extranjera
			end
		 end
		 ELSE IF @i_moneda_origen = @w_codmn --LPO CDIG
		 begin
            if @i_valor_destino = 0 --TCA Inci_25573
		    begin
				select @w_monto_mn = @w_monto,
					   @w_monto_me = round(@w_monto / (@w_rel_dolm1 * @o_cotizacion), @w_numdec)
				select @o_valor_convertido = @w_monto_me --select @o_valor_conver_orig = @w_monto_me --Convertido a moneda Extranjera --LPO
--PRINT '1'				
		    END
			else
			BEGIN
				select @w_monto_me = @w_monto,
					   @w_monto_mn = round(@w_monto * @w_rel_dolm1 * @o_cotizacion, @w_numdec)
				select @o_valor_conver_orig = @w_monto_mn --select @o_valor_convertido = @w_monto_mn --Convertido a moneda Nacional --LPO				
			end		   
         END
         ELSE
         BEGIN
            if @i_valor_destino = 0 --TCA Inci_25573
		    begin
				select @w_monto_mn = @w_monto,
					   @w_monto_me = round(@w_monto * (@w_rel_dolm1 * @o_cotizacion), @w_numdec)
				select @o_valor_convertido = @w_monto_me --select @o_valor_conver_orig = @w_monto_me --Convertido a moneda Extranjera				
		    END
			else
			begin
				select @w_monto_me = @w_monto,
					   @w_monto_mn = round(@w_monto / @w_rel_dolm1 * @o_cotizacion, @w_numdec)
				select @o_valor_conver_orig = @w_monto_mn --select @o_valor_convertido = @w_monto_mn --Convertido a moneda Nacional
			end		            
         END
	  end
	  
      -- Venta
      if @w_tipo_op in ('V', 'C')
      begin          
		    
         -- TCA Inci_20221 begin tran --> INICIO TRANSACCION
         
         -- Registro de la Venta
         insert into ca_ope_divisas
            (od_cod_operacion,   od_fecha,         od_estado,            od_tipo_operacion,    od_moneda,     od_concepto,
             od_monto_me,        od_cotizacion,    od_cotizacion_usd,    od_monto_mn,          od_modulo,     od_oficina,  
             od_operador,        od_contabiliza,   od_cod_alterno,       od_ssn_branch,        od_canal)
         values
            (@s_ssn,             @s_date,          'N',                  @w_tipo_op,           @w_moneda_o,   @i_concepto,
             @w_monto_me,        @w_cotaux,        @w_cotaux,            @w_monto_mn,          @w_producto,   @i_oficina,  
             @w_rd_operador,     @i_contabiliza,   @i_alterno,           isnull(@s_ssn_branch,@s_ssn),@i_canal)
             
         if @@error <> 0
         begin
            --TCA Inci_20221 rollback tran
            select @o_msg_error = '[' + @w_sp_name + '] ' + 'ERROR AL GUARDAR LOS DATOS DE LA OPERACION DE DIVISAS'
            return 2902857
         end
         
         select @w_sec = max(od_cod_operacion) --max(od_secuencial)
           from ca_ope_divisas
          where od_cod_operacion = @s_ssn
            and od_modulo = @w_producto
        
         -- Actualizacion de la posicion por venta de divisas
         exec @w_return          = cob_tesoreria..sp_actualizar_posicion_me
              @i_sucursal        = @w_sucursal,       --> Sucursal de Tesoreria                                                                    
              @i_oficina         = @i_oficina,        --> Oficina de ejecucion                                                                    
              @i_tipo_oper       = @w_tipo_op,        --> Tipo de Operacion 'C' o 'V'
              @i_moneda_compra   = @w_moneda_o,       --> Moneda de origen
              @i_moneda_venta    = @w_moneda_o, --@w_moneda_d,--@w_moneda_o,       --> Moneda destino --LPO***
              @i_monto_oper      = @w_monto_me,       --> Monto de la negociacion en ME
              @i_total_ME        = @w_monto_me,       --> Monto de la negociacion en ME
              @i_total_MN        = @w_monto_mn,       --> Monto de la negociacion en MN
              @i_fecha_val       = @s_date,           --> Fecha de la ejecucion                                                                    
              -- Datos adicionales para manejar la posicion por operacion                                               
              @i_producto        = @w_producto,       --> Codigo de producto COBIS                                                                         
              @i_cod_operacion   = @w_sec,            --> Secuencial de Operacion                                       
              @i_cod_cliente     = @i_cliente,        --> Codigo de Cliente                                         
              @i_id_cliente      = @w_id_cliente,                                                                   
              @i_nom_cliente     = @w_nom_cliente,
	          @i_cotiz1          = @w_cotaux,         --> Cotizacion de Negociacion  -- DVI 75138
              @i_origen_divisas  = @i_origen_divisas, --> Se enviara un default para registrar el origen de las divisas.
              @i_batch           = @i_batch           --  TCA Inci_20221

         if @w_return <> 0  
         begin
            --TCA Inci_20221 rollback tran
            select @o_msg_error = '[1 ' + @w_sp_name + '] ' + 'ERROR AL ACTUALIZAR LA POSICION DE MONEDA EXTRANJERA EN TESORERIA'
            return @w_return
         end             

--RETURN 1232      

         
         --TCA Inci_20221 commit tran --> FIN TRANSACCION   
         
      end  -- if @w_tipo_op in 'V', 'C'
                           
      -- Arbitraje o Monedas Duras
      if @w_tipo_op = 'A'
      begin
         -- La moneda de origen y destino son moneda extranjera y una de ellas es dolares.  Regulatoriamente en CR toda operacion de divisas debe realizarse con el dolar americano
         if @w_moneda_o <> @w_codmn and @w_moneda_d <> @w_codmn
         begin

            if @w_moneda_o = @w_codusd
            begin
               select @w_cotaux = @w_dolar_v,  -- Aplica cotizacion dolar venta
                      @w_desorg_div = @i_destino_divisas

               if @i_factor is not null
                  select @w_rel_dolm2 = @i_factor

               select @w_rd_ope_aux = @w_rd_operador2  

               if @w_rd_operador2 = '*'
                  select @w_rd_cot_inv = @w_rel_dolm2
               else
                  select @w_rd_cot_inv = round(1/@w_rel_dolm2,@w_numdec_cot)

               select @o_cot_usd = @w_cotaux,
                      @o_factor  = @w_rel_dolm2,
                      @o_cotizacion = round(@w_cotaux * @w_rd_cot_inv,@w_numdec_cot)               

            end
            else
            begin
               select @w_cotaux = @w_dolar_c,  -- Aplica cotizacion dolar compra
                      @w_desorg_div = @i_origen_divisas

               if @i_factor is not null
                  select @w_rel_dolm1 = @i_factor

               select @w_rd_ope_aux = @w_rd_operador            

               if @w_rd_operador = '*'
                  select @w_rd_cot_inv = @w_rel_dolm1
               else
                  select @w_rd_cot_inv = round(1/@w_rel_dolm1,@w_numdec_cot)

               select @o_cot_usd = @w_cotaux,
                      @o_factor  = @w_rel_dolm1,
                      @o_cotizacion = round(@w_cotaux * @w_rd_cot_inv,@w_numdec_cot)            
            end
                        
            select @w_monto_c  = @w_monto

            if @w_rd_ope_aux = '*'
            begin
               select @w_monto_mn = round(@w_monto * @w_rel_dolm1 * @w_cotaux, @w_numdec)
               select @w_monto_v = round(@w_monto_mn / (@w_rel_dolm2 * @w_cotaux), @w_numdec)
            end
            else
            begin 
               select @w_monto_mn = round((@w_monto * @w_cotaux) / @w_rel_m1, @w_numdec)
               select @w_monto_v = round((@w_monto_mn * @w_rel_dolm2) / @w_cotaux, @w_numdec)
            end              

            select @o_valor_convertido = @w_monto_v
            
            --TCA Inci_20221 begin tran --> INICIO TRANSACCION
            
            -- Compra moneda origen y Venta moneda destino
            insert into ca_ope_divisas
               (od_cod_operacion,     od_fecha,            od_estado,        od_tipo_operacion,    od_cotizacion_usd,  
                od_monto_mn,          od_moneda_compra,    od_moneda_venta,  od_monto_compra,      od_monto_venta,     
                od_rel_dolar_compra,  od_rel_dolar_venta,  od_modulo,        od_oficina,           od_concepto,
                od_operador,          od_contabiliza,      od_cod_alterno,   od_ssn_branch,        od_canal)                            
            values
               (@s_ssn,               @s_date,             'N',              @w_tipo_op,           @w_cotaux,  
                @w_monto_mn,          @w_moneda_o,         @w_moneda_d,      @w_monto_c,           @w_monto_v,     
                @w_rel_dolm1,         @w_rel_dolm2,        @w_producto,      @i_oficina,           @i_concepto,
                @w_rd_ope_aux,        @i_contabiliza,      @i_alterno,       isnull(@s_ssn_branch,@s_ssn),@i_canal)
                
            if @@error <> 0
            begin
               --TCA Inci_20221 rollback tran
               select @o_msg_error = '[' + @w_sp_name + '] ' + 'ERROR AL GUARDAR LOS DATOS DE LA OPERACION DE DIVISAS'
               return 2902857
            end

            select @w_sec = max(od_cod_operacion) --max(od_secuencial)
            from ca_ope_divisas
            where od_cod_operacion = @s_ssn
            and od_modulo = @w_producto
            
            -- Actualizacion de la posicion como arbitraje, compra moneda de origen venta moneda destino
            exec @w_return          = cob_tesoreria..sp_actualizar_posicion_me
                 @i_sucursal        = @w_sucursal,       --> Sucursal de Tesoreria                                                                    
                 @i_oficina         = @i_oficina,        --> Oficina de ejecucion                                                                    
                 @i_tipo_oper       = @w_tipo_op,        --> 'A'
                 @i_moneda_compra   = @w_moneda_o,       --> Moneda de origen
                 @i_moneda_venta    = @w_moneda_d,       --> Moneda destino
                 @i_monto_oper      = @w_monto_c,        --> Monto de la negociacion en moneda de compra
                 @i_total_ME        = @w_monto_v,        --> Monto de la negociacion en moneda de venta
                 @i_total_MN        = @w_monto_mn,       --> Monto de la negociacion en MN
                 @i_fecha_val       = @s_date,           --> Fecha de la ejecucion                                                                    
                 -- Datos adicionales para manejar la posicion por operacion                                               
                 @i_producto        = @w_producto,       --> Codigo de producto COBIS                                                                         
                 @i_cod_operacion   = @w_sec,            --> Secuencial de Operacion                                       
                 @i_cod_cliente     = @i_cliente,        --> Codigo de Cliente                                         
                 @i_id_cliente      = @w_id_cliente,                                                                   
                 @i_nom_cliente     = @w_nom_cliente,
		         @i_cotiz1          = @w_cotaux,         --> Cotizacion de la Operacion -- DVI 75138
                 @i_origen_divisas  = @w_desorg_div,     --> Se enviara un default para registrar el origen de las divisas.
                 @i_batch           = @i_batch,          --> TCA Inci_20221
                 @i_cotiz_dol       = @o_factor          --> TCA Inci_31163
                  
            if @w_return <> 0  
            begin
               --TCA Inci_20221 rollback tran
               select @o_msg_error = '[2 ' + @w_sp_name + '] ' + 'ERROR AL ACTUALIZAR LA POSICION DE MONEDA EXTRANJERA EN TESORERIA'
               return @w_return
            end

--RETURN 1232      


            --TCA Inci_20221 commit tran --> FIN TRANSACCION                
         end  -- FIN Arbitraje Normal
            
         -- Si la moneda destino es ME ==> Venta de dolares, y arbitraje dolar vs. moneda extranjera (compra dolar - venta ME)
         if @w_moneda_d <> @w_codmn and @w_moneda_o = @w_codmn
         begin
            select @w_cotaux = @w_dolar_v  -- Aplica cotizacion dolar venta
            
            if @i_factor is not null
               select @w_rel_dolm1 = @i_factor
			
			if @i_valor_destino = 0
            begin				   
                if @w_rd_operador2 = '*'
                    select @w_monto_v    = round(@w_monto / (@w_rel_dolm2 * @w_cotaux), @w_numdec),
                           @w_rd_cot_inv = round(@w_rel_dolm1,@w_numdec_cot)
                else               
                    select @w_monto_v    = round((@w_monto * @w_rel_dolm1) / @w_cotaux, @w_numdec),
                           @w_rd_cot_inv = round(1/@w_rel_dolm1,@w_numdec_cot)
                
				select @w_monto_mn  = @w_monto,
                       @w_monto_usd = round(@w_monto / @w_cotaux, @w_numdec)            
					   
                select @o_valor_convertido = @w_monto_v
            end
			else
		    begin
			    if @w_rd_operador2 = '*'
				   select @w_monto_dest = round(@w_monto * @w_rel_dolm1 * @w_cotaux, @w_numdec),
						  @w_rd_cot_inv = round(@w_rel_dolm1,@w_numdec_cot)
				else               
				   select @w_monto_dest = round((@w_monto / @w_rel_dolm1) * @w_cotaux, @w_numdec), 
						  @w_rd_cot_inv = round(1/@w_rel_dolm1,@w_numdec_cot)
                
				select @w_monto_mn  = @w_monto_dest,
				       @w_monto_v   = @w_monto,
                       @w_monto_usd = round(@w_monto_dest/ @w_cotaux, @w_numdec) 
						  
				select @o_valor_conver_orig = @w_monto_dest
			end

            select @o_cot_usd = @w_cotaux,
                   @o_factor  = @w_rel_dolm1,
                   @o_cotizacion = round(@w_cotaux * @w_rd_cot_inv,@w_numdec_cot)                       
            
            --TCA Inci_20221 begin tran --> INICIO TRANSACCION
            
            -- 1. Venta de dolares
            insert into ca_ope_divisas
               (od_cod_operacion,   od_fecha,         od_estado,            od_tipo_operacion,    od_moneda,     od_concepto,
                od_monto_me,        od_cotizacion,    od_cotizacion_usd,    od_monto_mn,          od_modulo,     od_oficina,
                od_operador,        od_contabiliza,   od_cod_alterno,       od_ssn_branch,        od_canal)
            values
               (@s_ssn,             @s_date,          'N',                  'V',                  @w_codusd,     @i_concepto,
                @w_monto_usd,       @w_cotaux,        @w_cotaux,            @w_monto_mn,          @w_producto,   @i_oficina,
                null,               @i_contabiliza,   @i_alterno,           isnull(@s_ssn_branch,@s_ssn),@i_canal)
                
            if @@error <> 0
            begin
               --TCA Inci_20221 rollback tran
               select @o_msg_error = '[' + @w_sp_name + '] ' + 'ERROR AL GUARDAR LOS DATOS DE LA OPERACION DE DIVISAS'
               return 2902857
            end        
            
            select @w_sec = max(od_cod_operacion) --max(od_secuencial)
            from ca_ope_divisas
            where od_cod_operacion = @s_ssn
            and od_modulo = @w_producto
                
            -- Actualizacion de la posicion: venta de dolares
            exec @w_return          = cob_tesoreria..sp_actualizar_posicion_me
                 @i_sucursal        = @w_sucursal,       --> Sucursal de Tesoreria                                                                    
                 @i_oficina         = @i_oficina,        --> Oficina de ejecucion                                                                    
                 @i_tipo_oper       = 'V',               --> Venta
                 @i_moneda_compra   = @w_codusd,         --> USD (en compra o venta de divisas, la ME va en este parametro siempre)
                 @i_moneda_venta    = @w_codusd,         --> USD
                 @i_monto_oper      = @w_monto_usd,      --> Monto de la negociacion en ME
                 @i_total_ME        = @w_monto_usd,      --> Monto de la negociacion en ME
                 @i_total_MN        = @w_monto_mn,       --> Monto de la negociacion en MN
                 @i_fecha_val       = @s_date,           --> Fecha de la ejecucion                                                                    
                 -- Datos adicionales para manejar la posicion por operacion                                               
                 @i_producto        = @w_producto,       --> Codigo de producto COBIS                                                                         
                 @i_cod_operacion   = @w_sec,            --> Secuencial de Operacion                                       
                 @i_cod_cliente     = @i_cliente,        --> Codigo de Cliente                                            
                 @i_id_cliente      = @w_id_cliente,                                                                   
                 @i_nom_cliente     = @w_nom_cliente,
		         @i_cotiz1          = @w_cotaux,         --> Cotizacion de Negociacion -- DVI 75138
                 @i_origen_divisas  = @i_destino_divisas,--> Se enviara un default para registrar el origen de las divisas.
                 @i_batch           = @i_batch           --> TCA Inci_20221				  
                 
            if @w_return <> 0  
            begin
               --TCA Inci_20221 rollback tran
               select @o_msg_error = '[3 ' + @w_sp_name + '] ' + 'ERROR AL ACTUALIZAR LA POSICION DE MONEDA EXTRANJERA EN TESORERIA'
               return @w_return
            end                                          

--RETURN 1232      
                   
            -- 2. Compra dolares venta moneda dura
            insert into ca_ope_divisas
                       (od_cod_operacion,     od_fecha,            od_estado,        od_tipo_operacion,    od_cotizacion_usd,  
                        od_monto_mn,          od_moneda_compra,    od_moneda_venta,  od_monto_compra,      od_monto_venta,     
                        od_rel_dolar_compra,  od_rel_dolar_venta,  od_modulo,        od_oficina,           od_concepto,
                        od_operador,          od_contabiliza,      od_cotizacion,    od_cod_alterno,       od_ssn_branch,        od_canal)                            
                values (@s_ssn,               @s_date,             'N',              @w_tipo_op,           @w_cotaux,  
                        @w_monto_mn,          @w_codusd,           @w_moneda_d,      @w_monto_usd,         @w_monto_v,     
                        1,                    @w_rel_dolm1,        @w_producto,      @i_oficina,           @i_concepto,
                        @w_rd_operador2,      @i_contabiliza,      @o_cotizacion,    @i_alterno,           isnull(@s_ssn_branch,@s_ssn),@i_canal)   
                   
            if @@error <> 0
            begin
               --TCA Inci_20221 rollback tran
               select @o_msg_error = '[' + @w_sp_name + '] ' + 'ERROR AL GUARDAR LOS DATOS DE LA OPERACION DE DIVISAS'
               return 2902857
            end          
            
            select @w_sec = max(od_cod_operacion) --max(od_secuencial)
            from ca_ope_divisas
            where od_cod_operacion = @s_ssn
            and od_modulo = @w_producto
            
            -- Actualizacion de la posicion como arbitraje, compra de dolares y venta moneda destino
            exec @w_return          = cob_tesoreria..sp_actualizar_posicion_me
                 @i_sucursal        = @w_sucursal,       --> Sucursal de Tesoreria                                                                    
                 @i_oficina         = @i_oficina,        --> Oficina de ejecucion                                                                    
                 @i_tipo_oper       = @w_tipo_op,        --> 'A'
                 @i_moneda_compra   = @w_codusd,         --> Moneda de origen
                 @i_moneda_venta    = @w_moneda_d,       --> Moneda destino
                 @i_monto_oper      = @w_monto_usd,      --> Monto de la negociacion en moneda de compra
                 @i_total_ME        = @w_monto_v,        --> Monto de la negociacion en moneda de venta
                 @i_total_MN        = @w_monto_mn,       --> Monto de la negociacion en MN
                 @i_fecha_val       = @s_date,           --> Fecha de la ejecucion                                                                    
                 -- Datos adicionales para manejar la posicion por operacion                                               
                 @i_producto        = @w_producto,       --> Codigo de producto COBIS                                                                         
                 @i_cod_operacion   = @w_sec,            --> Secuencial de Operacion                                       
                 @i_cod_cliente     = @i_cliente,        --> Codigo de Cliente                                         
                 @i_id_cliente      = @w_id_cliente,                                                                   
                 @i_nom_cliente     = @w_nom_cliente,
		         @i_cotiz1          = @w_cotaux,         --> Cotizacion de Negociacion -- DVI 75138
                 @i_origen_divisas  = @i_destino_divisas,--> Se enviara un default para registrar el origen de las divisas.
                 @i_batch           = @i_batch,          --> TCA Inci_20221
                 @i_cotiz_dol       = @o_factor          --> TCA Inci_31163
				 
            if @w_return <> 0  
            begin
               --TCA Inci_20221 rollback tran
               select @o_msg_error = '[4 ' + @w_sp_name + '] ' + 'ERROR AL ACTUALIZAR LA POSICION DE MONEDA EXTRANJERA EN TESORERIA'
               return @w_return
            end   

--RETURN 1232      
               
            --TCA Inci_20221 commit tran --> FIN TRANSACCION                  
                                  
         end -- FIN: Si la moneda destino es ME
            
         -- Si la moneda origen es ME ==> Arbitraje moneda extranjera vs. dolar (compra ME - venta dolar), y compra dolar 
         if @w_moneda_o <> @w_codmn and @w_moneda_d = @w_codmn
         begin
            select @w_cotaux = @w_dolar_c  -- Aplica cotizacion dolar compra

            if @i_factor is not null
               select @w_rel_dolm1 = @i_factor

			if @i_valor_destino = 0
			begin
                if @w_rd_operador = '*'
                    select @w_monto_mn  = round(@w_monto * @w_rel_dolm1 * @w_cotaux, @w_numdec),
                           @w_monto_usd = round(@w_monto * @w_rel_dolm1, @w_numdec),
                           @w_rd_cot_inv = round(@w_rel_dolm1,@w_numdec_cot) 
                else
                    select @w_monto_mn  = round((@w_monto * @w_cotaux) / @w_rel_dolm1, @w_numdec),
                           @w_monto_usd = round(@w_monto / @w_rel_dolm1, @w_numdec),
                           @w_rd_cot_inv = round(1/@w_rel_dolm1,@w_numdec_cot)

			    select @w_monto_c   = @w_monto
                select @o_valor_convertido = @w_monto_mn     
            end
            else
			begin
			    if @w_rd_operador = '*'
				begin
				    select @w_monto_dest = round(@w_monto / (@w_rel_dolm1 * @w_cotaux), @w_numdec)
					select @w_monto_usd  = round(@w_monto_dest * @w_rel_dolm1, @w_numdec),
						   @w_rd_cot_inv = round(@w_rel_dolm1,@w_numdec_cot) 
				end
				else
				begin
				    select @w_monto_dest = round((@w_monto / @w_cotaux) * @w_rel_dolm1, @w_numdec)
				    select @w_monto_usd  = round(@w_monto_dest / @w_rel_dolm1, @w_numdec), 
						   @w_rd_cot_inv = round(1/@w_rel_dolm1,@w_numdec_cot) 
				end
				
				select @w_monto_mn = @w_monto,
				       @w_monto_c  = @w_monto_dest
				select @o_valor_conver_orig = @w_monto_dest 
			end
			
            select @o_cot_usd = @w_cotaux,
                   @o_factor  = @w_rel_dolm1,
                   @o_cotizacion = round(@w_cotaux * @w_rd_cot_inv,@w_numdec_cot)    
            
            --TCA Inci_20221 begin tran --> INICIO TRANSACCION
            
            -- 1. Compra de dolares
            insert into ca_ope_divisas
               (od_cod_operacion,   od_fecha,         od_estado,            od_tipo_operacion,    od_moneda,     od_concepto,
                od_monto_me,        od_cotizacion,    od_cotizacion_usd,    od_monto_mn,          od_modulo,     od_oficina,
                od_operador,        od_contabiliza,   od_cod_alterno,       od_ssn_branch,        od_canal)
            values
               (@s_ssn,             @s_date,          'N',                  'C',                  @w_codusd,     @i_concepto,
                @w_monto_usd,       @w_cotaux,        @w_cotaux,            @w_monto_mn,          @w_producto,   @i_oficina,
                null,               @i_contabiliza,   @i_alterno,           isnull(@s_ssn_branch,@s_ssn),@i_canal)
                
            if @@error <> 0
            begin
               --TCA Inci_20221 rollback tran
               select @o_msg_error = '[5 ' + @w_sp_name + '] ' + 'ERROR AL GUARDAR LOS DATOS DE LA OPERACION DE DIVISAS'
               return @w_return
            end        

            select @w_sec = max(od_cod_operacion) --max(od_secuencial)
            from ca_ope_divisas
            where od_cod_operacion = @s_ssn
            and od_modulo = @w_producto               
                
            -- Actualizacion de la posicion: compra moneda dolares
            exec @w_return          = cob_tesoreria..sp_actualizar_posicion_me
                 @i_sucursal        = @w_sucursal,       --> Sucursal de Tesoreria                                                                    
                 @i_oficina         = @i_oficina,        --> Oficina de ejecucion                                                                    
                 @i_tipo_oper       = 'C',               --> Compra
                 @i_moneda_compra   = @w_codusd,         --> USD (en compra o venta de divisas, la ME va en este parametro siempre)
                 @i_moneda_venta    = @w_codusd,         --> USD
                 @i_monto_oper      = @w_monto_usd,      --> Monto de la negociacion en ME
                 @i_total_ME        = @w_monto_usd,      --> Monto de la negociacion en ME
                 @i_total_MN        = @w_monto_mn,       --> Monto de la negociacion en MN
                 @i_fecha_val       = @s_date,           --> Fecha de la ejecucion                                                                    
                 -- Datos adicionales para manejar la posicion por operacion                                               
                 @i_producto        = @w_producto,       --> Codigo de producto COBIS                                                                         
                 @i_cod_operacion   = @w_sec,            --> Secuencial de Operacion                                       
                 @i_cod_cliente     = @i_cliente,        --> Codigo de Cliente                                            
                 @i_id_cliente      = @w_id_cliente,                                                                   
                 @i_nom_cliente     = @w_nom_cliente,
		         @i_cotiz1          = @w_cotaux,         --> Cotizacion de Negociacion -- DVI 75138
                 @i_origen_divisas  = @i_origen_divisas, --> Se enviara un default para registrar el origen de las divisas.
                 @i_batch           = @i_batch           --> TCA Inci_20221		  
                 
            if @w_return <> 0  
            begin
               --TCA Inci_20221 rollback tran
               select @o_msg_error = '[6 ' + @w_sp_name + '] ' + 'ERROR AL ACTUALIZAR LA POSICION DE MONEDA EXTRANJERA EN TESORERIA'
               return @w_return
            end   

--RETURN 1232      

            -- 2. Compra de moneda dura y Venta de dolares
            insert into ca_ope_divisas
               (od_cod_operacion,     od_fecha,            od_estado,        od_tipo_operacion,    od_cotizacion_usd,  
                od_monto_mn,          od_moneda_compra,    od_moneda_venta,  od_monto_compra,      od_monto_venta,     
                od_rel_dolar_compra,  od_rel_dolar_venta,  od_modulo,        od_oficina,           od_concepto,
                od_operador,          od_contabiliza,      od_cotizacion,    od_cod_alterno,       od_ssn_branch,        od_canal)
            values
               (@s_ssn,               @s_date,             'N',              @w_tipo_op,           @w_cotaux,  
                @w_monto_mn,          @w_moneda_o,         @w_codusd,        @w_monto_c,           @w_monto_usd,     
                @w_rel_dolm1,         1,                   @w_producto,      @i_oficina,           @i_concepto,
                @w_rd_operador,       @i_contabiliza,      @o_cotizacion,    @i_alterno,           isnull(@s_ssn_branch,@s_ssn),@i_canal)
                
            if @@error <> 0
            begin
               --TCA Inci_20221 rollback tran
               select @o_msg_error = '[' + @w_sp_name + '] ' + 'ERROR AL GUARDAR LOS DATOS DE LA OPERACION DE DIVISAS'
               return 2902857
            end        
               
            select @w_sec = max(od_cod_operacion) --max(od_secuencial)
            from ca_ope_divisas
            where od_cod_operacion = @s_ssn
            and od_modulo = @w_producto
             
            -- Actualizacion de la posicion como arbitraje, compra moneda de origen y venta dolares
            exec @w_return          = cob_tesoreria..sp_actualizar_posicion_me
                 @i_sucursal        = @w_sucursal,       --> Sucursal de Tesoreria                                                                    
                 @i_oficina         = @i_oficina,        --> Oficina de ejecucion                                                                    
                 @i_tipo_oper       = @w_tipo_op,        --> 'A'
                 @i_moneda_compra   = @w_moneda_o,       --> Moneda de origen
                 @i_moneda_venta    = @w_codusd,         --> USD
                 @i_monto_oper      = @w_monto_c,        --> Monto de la negociacion en moneda de compra
                 @i_total_ME        = @w_monto_usd,      --> Monto de la negociacion en moneda de venta
                 @i_total_MN        = @w_monto_mn,       --> Monto de la negociacion en MN
                 @i_fecha_val       = @s_date,           --> Fecha de la ejecucion                                                                    
                 -- Datos adicionales para manejar la posicion por operacion                                               
                 @i_producto        = @w_producto,       --> Codigo de producto COBIS                                                                         
                 @i_cod_operacion   = @w_sec,            --> Secuencial de Operacion                                       
                 @i_cod_cliente     = @i_cliente,        --> Codigo de Cliente                                           
                 @i_id_cliente      = @w_id_cliente,                                                                   
                 @i_nom_cliente     = @w_nom_cliente,
		         @i_cotiz1          = @w_cotaux,         --> Cotizacion de Negociacion -- DVI 75138
                 @i_origen_divisas  = @i_origen_divisas, --> Se enviara un default para registrar el origen de las divisas.
                 @i_batch           = @i_batch,          --> TCA Inci_20221
                 @i_cotiz_dol       = @o_factor          --> TCA Inci_31163
				 
            if @w_return <> 0  
            begin
               --TCA Inci_20221 rollback tran
               select @o_msg_error = '[7 ' + @w_sp_name + '] ' + 'ERROR AL ACTUALIZAR LA POSICION DE MONEDA EXTRANJERA EN TESORERIA'
               return @w_return
            end      	

--RETURN 1232      


            -- TCA Inci_20221 commit tran --> FIN TRANSACCION
         end  -- FIN: Si la moneda origen es ME
      end  -- FIN: if @w_tipo_op = 'A'
  
   end  -- FIN: if @i_operacion = 'E'
      
      
   ---------------------------------------------------- 
   -- REVERSO DE OPERACIONES DE DIVISAS Y POSICION   --
   ----------------------------------------------------      
   if @i_operacion = 'R'
   BEGIN
      -- Verificacion de existencia de los datos de la operacion original
	  if @i_canal in (1,3,4,7,9) -- 1: IB; 3,7: ATM; 9: ACH; 4: CAJAS
       select @w_secuencial = od_cod_operacion from ca_ope_divisas where od_ssn_branch = @i_secuencial and od_estado = 'N' and od_modulo = @w_producto and od_oficina = @i_oficina and od_canal = @i_canal        
        else
       select @w_secuencial = od_cod_operacion from ca_ope_divisas where od_cod_operacion = @i_secuencial and od_estado = 'N' and od_modulo = @w_producto and od_oficina = @i_oficina and od_canal is null

       if @@rowcount = 0
      begin
         select @o_msg_error = '[' + @w_sp_name + '] ' + 'NO SE ENCUENTRA LA OPERACION ORIGINAL DE DIVISAS'
         return 2902858
      end
       
	  if @w_afec_ofic_cent = 'S'
	  begin
		  -- Busqueda de sucursal asociada a la oficina
		  select @w_sucursal = st_sucursal
		  from   cob_tesoreria..te_sucursal_tesoreria
		  where  st_cod_oficina =  @i_oficina
		  
		  if @w_sucursal is null
		  begin 
			 select @o_msg_error = '[' + @w_sp_name + '] ' + 'NO SE ENCUENTRA LA PARAMETRIZACION DE LA SUCURSAL ASOCIADA EN TESORERIA'
			 return 2902855
		  end
	  end
	  else
	      select @w_sucursal = @i_oficina
      
      --TCA Inci_20221 begin tran --> INICIO TRANSACCION
      
      -- Ejecucion de reverso de la operacion
      select @w_sec = 0     

      while (1=1)
      begin

         -- Lectura de datos originales
         select top 1
                @w_sec              = od_secuencial                   ,
                @w_tipo_op          = case od_tipo_operacion when 'C' then 'V' when 'V' then 'C' else 'A' end,
                @w_moneda           = od_moneda                       ,
                @w_monto            = isnull(od_monto_me, 0)          ,
                @w_monto_mn         = od_monto_mn                     ,
                @w_moneda_o         = case od_tipo_operacion when 'A' then od_moneda_venta else od_moneda_compra end,
                @w_moneda_d         = case od_tipo_operacion when 'A' then od_moneda_compra else od_moneda_venta end,
                @w_monto_c          = case od_tipo_operacion when 'A' then isnull(od_monto_venta,  0) else isnull(od_monto_compra, 0) end,
                @w_monto_v          = case od_tipo_operacion when 'A' then isnull(od_monto_compra,  0) else isnull(od_monto_venta, 0) end,
				@w_tipo_fact        = od_tipo_operacion,
                @w_alt              = od_cod_alterno
           from ca_ope_divisas
          where od_cod_operacion = @w_secuencial
            and od_secuencial    > @w_sec
            and od_modulo        = @w_producto
          order by od_secuencial
            
         if @@rowcount = 0
            break
         
         
         -- Seteo de variables en Compra y Venta
         if @w_tipo_op in ('C', 'V')
            select @w_moneda_o = @w_moneda,
                   @w_monto_c  = @w_monto
                   
         -- Actualizacion de la posicion como arbitraje
         exec @w_return          = cob_tesoreria..sp_actualizar_posicion_me
              @i_sucursal        = @w_sucursal,       --> Sucursal de Tesoreria                                                                    
              @i_oficina         = @i_oficina,        --> Oficina de ejecucion                                                                    
              @i_tipo_oper       = @w_tipo_op,        --> 'C', 'V', 'A'
              @i_moneda_compra   = @w_moneda_o,       --> Moneda de compra
              @i_moneda_venta    = @w_moneda_d,       --> Moneda de venta
              @i_monto_oper      = @w_monto_c,        --> Monto de la negociacion en moneda de compra
              @i_total_ME        = @w_monto_v,        --> Monto de la negociacion en moneda de venta
              @i_total_MN        = @w_monto_mn,       --> Monto de la negociacion en MN
              @i_fecha_val       = @s_date,           --> Fecha de la ejecucion                                                                    
              -- Datos adicionales para manejar la posicion por operacion                                               
              @i_producto        = @w_producto,       --> Codigo de producto COBIS                                                                         
              @i_cod_operacion   = @w_secuencial,     --> Secuencial de Operacion                                       
              @i_cod_cliente     = @i_cliente,        --> Codigo de Cliente                                         
              @i_id_cliente      = @w_id_cliente,                                                                   
              @i_nom_cliente     = @w_nom_cliente,
	          @i_cotiz1          = @w_cotaux,         --> Cotizacion de Negociacion -- DVI 75138
              @i_reverso         = 'S',
              @i_origen_divisas  = '' ,               --> Se enviara un default para registrar el origen de las divisas.
              @i_batch           = @i_batch           --  TCA Inci_20221

         if @w_return <> 0  
         begin
            --TCA Inci_20221 rollback tran
            select @o_msg_error = '[8 ' + @w_sp_name + '] ' + 'ERROR AL ACTUALIZAR LA POSICION DE MONEDA EXTRANJERA EN TESORERIA'
            return 2902859
         end


--RETURN 1232      

         
      end -- FIN: while (1=1)
           
      
      -- Actualizar el estado a reversado
      update ca_ope_divisas
      set od_estado        = 'R',
          od_fecha_reverso = @s_date
      where od_cod_operacion = @w_secuencial
        and od_modulo = @w_producto
        and od_estado = 'N'
      
      if @@error <> 0
      begin
         --TCA Inci_20221 rollback tran
         select @o_msg_error = '[' + @w_sp_name + '] ' + 'NO SE PUDO REGISTRAR EL REVERSO DE LA OPERACION DE DIVISAS'
         return 2902860
      end

   end  -- FIN: if @i_operacion = 'R'                  
end     -- FIN: if @w_int_tesoreria = 'S'   

--LPO CDIG Multimoneda INICIO
IF @i_moneda_origen = @i_moneda_destino and @i_moneda_origen <> @w_codmn
BEGIN
   SELECT @o_cotizacion       = @o_cotizacion  --1.0
   SELECT @o_tipo_op          = 'N' --@o_tipo_op --'N'   
   SELECT @o_valor_convertido = @i_valor
END
--LPO CDIG Multimoneda FIN

return 0
                                                                                                                                                      
go
