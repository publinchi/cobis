/********************************************************************/
/*   NOMBRE LOGICO:      tanqueo_fact_cartera.sp                    */
/*   NOMBRE FISICO:      sp_tanqueo_fact_cartera                    */
/*   BASE DE DATOS:      cob_cartera                                */
/*   PRODUCTO:           Cartera                                    */
/*   DISENADO POR:       Kevin Rodríguez                            */
/*   FECHA DE ESCRITURA: Mayo 2023                                  */
/********************************************************************/
/*                     IMPORTANTE                                   */
/*   Este programa es parte de los paquetes bancarios que son       */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  */
/*   representantes exclusivos para comercializar los productos y   */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida */
/*   y regida por las Leyes de la República de España y las         */
/*   correspondientes de la Unión Europea. Su copia, reproducción,  */
/*   alteración en cualquier sentido, ingeniería reversa,           */
/*   almacenamiento o cualquier uso no autorizado por cualquiera    */
/*   de los usuarios o personas que hayan accedido al presente      */
/*   sitio, queda expresamente prohibido; sin el debido             */
/*   consentimiento por escrito, de parte de los representantes de  */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  */
/*   en el presente texto, causará violaciones relacionadas con la  */
/*   propiedad intelectual y la confidencialidad de la información  */
/*   tratada; y por lo tanto, derivará en acciones legales civiles  */
/*   y penales en contra del infractor según corresponda.”.         */
/********************************************************************/
/*                           PROPOSITO                              */
/*   Programa que realiza la transacción de pago grupal desde el    */ 
/*   canal cartera                                                  */
/********************************************************************/
/*                        MODIFICACIONES                            */
/*  FECHA              AUTOR              RAZON                     */
/*  24-May-2023    K. Rodríguez  (S787160)Emision Inicial           */
/*  05-Sep-2023    G. Fernandez  R214869 Se aumenta parametro de ma-*/
/*                               manejo de transaccion para tanqueo */
/*  17-Nov-2023    K. Rodríguez  R217688 Se agrega Apéndice Sobrante*/
/********************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_tanqueo_fact_cartera')
   drop proc sp_tanqueo_fact_cartera
go

create proc sp_tanqueo_fact_cartera
@s_user             login,
@s_date             datetime,
@s_rol              smallint,
@s_term             varchar(30),
@s_ofi              smallint,
@s_ssn              int,
@t_corr             char(1)     = 'N',
@t_ssn_corr         int         = null,
@t_fecha_ssn_corr   datetime    = null, 
@i_ope_banco        varchar(24),
@i_secuencial_ing   int         = null,
@i_tipo_operacion   char(1)     = null,     -- N= Individual, G=Grupal
@i_saldo_anterior   money       = null,
@i_fecha_ing        datetime    = null,     -- Fecha de ingreso(pago)
@i_externo          char(1)     = 'N',
@i_tipo_tran        char(10),               -- PAG, etc
@i_operacion        char(1),                -- I= Ingreso, R= Reverso  
@o_guid             varchar(36) = null out,
@o_fecha_registro   varchar(10) = null out,
@o_ssn              int         = null out,
@o_orquestador_fact char(1)     = null out

as
declare 
@w_sp_name           descripcion,
@w_error             int,
@w_tanqueo_fact      char(1),
@w_orquestador_fact  char(1),
@w_ejecutar_orq      char(1),
@w_operacionca       int,
@w_grupo             int,
@w_fecha_ult_proceso datetime,
@w_cliente           int,
@w_toperacion        catalogo,
@w_moneda_op         tinyint,
@w_tipo_cobro        char(1),
@w_tipo_reduccion    char(1),
@w_secuencial        int,
@w_porcentaje_int    float,
@w_saldo_actual      money,
@w_oficina_pago      varchar(160),
@w_fecha_ult_pago    datetime,
@w_sobrante_aut     money,
@w_moneda_simbolo    varchar(10),
@w_tipo_doc_fiscal   varchar(2),		     
@w_concepto_fact     varchar(10),
@w_monto_fact        money,
@w_categoria_fact    varchar(10),
@w_cat_desc_fact     varchar(160),
@w_num_ape           tinyint,
@w_cont_pag          tinyint,
@w_order_count       tinyint,
@w_fecha_registro    datetime,
@w_descripcion_det   varchar(100),
@w_precio_unit       varchar(15),
@w_monto_iva         varchar(15),
@w_venta_no_suj      varchar(15),
@w_venta_exenta      varchar(15),
@w_venta_gravada     varchar(15),
@w_venta_no_grav     varchar(15),
@w_num_det           tinyint,
@w_fpago_sob         varchar(30),
@w_det_registro      varchar(1100),
@w_det_registro1     varchar(1100),
@w_det_registro2     varchar(1100),
@w_det_registro3     varchar(1100),
@w_det_registro4     varchar(1100),
@w_det_registro5     varchar(1100),
@w_det_registro6     varchar(1100),
@w_det_registro7     varchar(1100),
@w_det_registro8     varchar(1100),
@w_det_registro9     varchar(1100),
@w_det_registro10    varchar(1100),
@w_det_registro11    varchar(1100),
@w_det_registro12    varchar(1100),
@w_det_registro13    varchar(1100),
@w_det_registro14    varchar(1100),
@w_det_registro15    varchar(1100),
@w_ape_registro      varchar(255),			     
@w_ape_registro1     varchar(255),
@w_ape_registro2     varchar(255),
@w_ape_registro3     varchar(255),
@w_ape_registro4     varchar(255),
@w_ape_registro5     varchar(255),
@w_ape_registro6     varchar(255),
@w_ape_registro7     varchar(255),
@w_ape_registro8     varchar(255),
@w_ape_registro9     varchar(255),
@w_ape_registro10    varchar(255)

declare 
@apendice table (id_col tinyint,
                 field  varchar(25), -- Campo(identificativo)
                 label  varchar(50), -- Etiqueta
				 valuee varchar(50)) -- Valor
declare
@detalles table (id_col      tinyint,
                 code        varchar(25),   -- Código interno
                 descr       varchar(1000), -- Descripción ítem
                 unitPr      varchar(15),   -- Precio unitario sin iva
                 ivaAmo      varchar(15),   -- Monto IVA del item
                 saleNoSub   varchar(15),   -- Venta no Sujeta
                 exemptSale  varchar(15),   -- Venta exenta (intereses)
                 taxedSale   varchar(15),   -- Venta gravada
                 untaxedSale varchar(15))   -- Venta no gravada (Otros valores CAP, SEG, etc)


-- Establecimiento de variables locales iniciales
select @w_sp_name     = 'sp_tanqueo_fact_cartera',
       @w_error       = 0

-- Parámetro de Forma de Pago para Sobrante Automático
select @w_fpago_sob = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'SOBAUT'
set transaction isolation level read uncommitted

-- Parámetro habilitar/deshabilitar tanqueo de facturación electrónica
select @w_tanqueo_fact = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'TANFAC'
and    pa_producto = 'CCA'
set transaction isolation level read uncommitted

-- Parámetro habilitar/deshabilitar orquestador de facturación electrónica
select @w_orquestador_fact = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'ORQFAC'
and    pa_producto = 'CCA'
set transaction isolation level read uncommitted

select @w_tanqueo_fact     = isnull(@w_tanqueo_fact, 'N'),
       @w_orquestador_fact = isnull(@w_orquestador_fact, 'N')

if @w_tanqueo_fact = 'N'
begin
   select @o_orquestador_fact = 'N'
   goto SALIR
end


-- Datos de la operación
select @w_operacionca       = op_operacion,
       @w_grupo             = op_grupo,
	   @w_cliente           = op_cliente,
	   @w_toperacion        = op_toperacion,
	   @w_fecha_ult_proceso = op_fecha_ult_proceso,
	   @w_moneda_op         = op_moneda,
	   @w_tipo_cobro        = op_tipo_cobro,
	   @w_tipo_reduccion    = op_tipo_reduccion
from ca_operacion
where op_banco = @i_ope_banco 

if @@rowcount = 0
begin
   select @w_error = 701013 -- No existe operación activa de cartera
   goto ERROR  
end

-- Tipo de documento fiscal (FCF[Factura consumidor final], CCF[Comprobante de crédito fiscal])
select @w_tipo_doc_fiscal = isnull((case oda_tipo_documento_fiscal when 'FCF' then '01' 
                                                           when 'CCF' then '03' end), '01')
from ca_operacion_datos_adicionales
where oda_operacion = @w_operacionca
	 
if @i_tipo_operacion is null
begin
   exec @w_error = sp_tipo_operacion
   @i_banco  = @i_ope_banco ,
   @o_tipo   = @i_tipo_operacion out

   if @w_error <> 0
      goto ERROR
end


if @i_externo = 'S'
   begin tran

if @i_operacion = 'I'
begin
		    
   if @i_tipo_tran = 'PAG' 
   begin
   
      if object_id ('tempdb..#det_pago_factura', 'U') is not null
         drop table #det_pago_factura
		 
      create table #det_pago_factura(
	  concepto  varchar(10),
	  monto     money,
	  categoria varchar(10),
	  cat_desc  varchar(160))
	  
	  select @w_fpago_sob = isnull(@w_fpago_sob, '')
		 
      -- Agencia que aplicó el pago
      select @w_oficina_pago = of_nombre 
      from cobis..cl_oficina 
      where of_oficina = @s_ofi
	  
      -- Signo de moneda   
      select @w_moneda_simbolo = isnull(mo_simbolo, '')
      from cobis..cl_moneda 
      where mo_moneda = @w_moneda_op
	  
      -- Tasa de interés
      select @w_porcentaje_int = ro_porcentaje
      from ca_rubro_op with (nolock)
      where ro_operacion = @w_operacionca
      and ro_tipo_rubro = 'I'
   
      if @i_tipo_operacion in ('N', 'H') -- Préstamo Individual
	  begin
	  
         -- Valor sobrante
         select @w_sobrante_aut = isnull(sum(abd_monto_mpg), 0)
         from   ca_abono_det
         where  abd_secuencial_ing = @i_secuencial_ing
         and    abd_operacion      = @w_operacionca
         and    abd_tipo           = 'SOB'
         and    abd_concepto       = @w_fpago_sob

         select @w_secuencial = tr_secuencial
         from ca_transaccion, ca_abono
         where ab_operacion    = @w_operacionca 
         and ab_secuencial_ing = @i_secuencial_ing
         and tr_operacion      = ab_operacion
         and tr_secuencial     = ab_secuencial_pag 
         
         -- Fecha último pago
         select @w_fecha_ult_pago = isnull(max(tr_fecha_mov), '01/01/1900')
         from ca_transaccion with (nolock)
         where tr_operacion = @w_operacionca
         and tr_secuencial <> @w_secuencial 
         and tr_tran = 'PAG'
         and tr_estado <> 'RV'

         -- Saldo actual
         exec @w_error     = sp_calcula_saldo
         @i_operacion      = @w_operacionca,
         @i_tipo_pago      = @w_tipo_cobro,
         @i_tipo_reduccion = @w_tipo_reduccion,
         @o_saldo          = @w_saldo_actual out
         
         if @@error <> 0
         begin
            select @w_error = 708201 -- ERROR. Retorno de ejecucion de Stored Procedure
            goto ERROR
         end 
		 
		 -- Información del detalles de pago Individual
		 insert into #det_pago_factura (concepto, monto, categoria, cat_desc)
         select distinct(dtr_concepto) as 'concepto', 
                sum(dtr_monto)         as 'monto', 
                co_categoria           as 'categoria',
                co_descripcion         as 'cat_desc' 
         from ca_det_trn with (nolock), ca_concepto 
         where dtr_operacion = @w_operacionca 
         and dtr_secuencial  = @w_secuencial
         and dtr_concepto    = co_concepto
         group by dtr_concepto, co_categoria, co_descripcion
		 
      end	

      if @i_tipo_operacion = 'G' -- Préstamo Grupal Padre
      begin
	  
         -- Valor sobrante (Sumatoria sobrantes préstamos hijos)
         select @w_sobrante_aut = isnull(sum(abd_monto_mpg), 0)
         from   ca_operacion with (nolock), ca_abono with (nolock), ca_abono_det
         where op_ref_grupal = @i_ope_banco
         and   op_operacion = ab_operacion
         and   ab_secuencial_ing_abono_grupal = @i_secuencial_ing
         and   ab_operacion      = abd_operacion
		 and   ab_secuencial_ing = abd_secuencial_ing
         and   abd_tipo           = 'SOB'
         and   abd_concepto       = @w_fpago_sob
		 
         -- Fecha último pago
         select @w_fecha_ult_pago = isnull(max(tr_fecha_mov), '01/01/1900')
         from ca_operacion with (nolock), ca_abono with (nolock), ca_transaccion
         where op_ref_grupal = @i_ope_banco
         and op_operacion = ab_operacion
         and ab_secuencial_ing_abono_grupal is not null
		 and ab_secuencial_ing_abono_grupal <> @i_secuencial_ing
         and ab_operacion = tr_operacion
         and ab_secuencial_pag = tr_secuencial
		 and tr_tran = 'PAG'
         and tr_estado <> 'RV'
		 
         -- Saldo actual
         exec @w_error = sp_pago_grupal_consulta_montos
         @i_canal          = '1', -- Cartera
         @i_banco          = @i_ope_banco, 
         @i_operacion      = 'R',
         @o_total_liquidar = @w_saldo_actual out
		
         if @w_error <> 0
         begin
            select @w_error = @w_error
            goto ERROR
         end
		 
         -- Información del detalles de pago Individual
         insert into #det_pago_factura (concepto, monto, categoria, cat_desc)
         select distinct(dtr_concepto) as 'concepto', 
                sum(dtr_monto)         as 'monto', 
                co_categoria           as 'categoria',
                co_descripcion         as 'cat_desc' 
         from ca_operacion with (nolock), ca_abono with (nolock), ca_det_trn with (nolock), ca_concepto 
         where op_ref_grupal = @i_ope_banco
         and op_operacion = ab_operacion
         and ab_secuencial_ing_abono_grupal = @i_secuencial_ing
         and ab_operacion = dtr_operacion
         and ab_secuencial_pag = dtr_secuencial
         and dtr_concepto    = co_concepto
         group by dtr_concepto, co_categoria, co_descripcion
		 
      end	

      -- Definición de apéndice de Pagos
      insert into @apendice (id_col, field, label, valuee)
      values (1, 'SOBAU', 'Sobrante',             convert(varchar, isnull(@w_sobrante_aut, 0))),
             (2, 'FECUP', 'Fecha de Último pago', substring(convert(varchar, @w_fecha_ult_pago, 103),1,15)),
		     (3, 'FECVA', 'Fecha Valor aplicado', substring(convert(varchar, isnull(@i_fecha_ing, @w_fecha_ult_proceso), 103),1,15)),
		     (4, 'AGENC', 'Ag. Que Aplicó',       @w_oficina_pago),
		     (5, 'OPERA', 'N° de Préstamo',       @i_ope_banco),
		     (6, 'PRODU', 'Tipo del Producto',    @w_toperacion),
		     (7, 'TINTE', 'Tasa de Interés(N)',   convert(varchar(10), isnull(@w_porcentaje_int, 0.0))+'%'),
		     (8, 'SANTE', 'Saldo Anterior',       @w_moneda_simbolo + ' ' + convert(varchar(15), isnull(@i_saldo_anterior, 0))),
		     (9, 'SACTU', 'Saldo Actual',         @w_moneda_simbolo + ' ' + convert(varchar(15), isnull(@w_saldo_actual, 0)))
			
			
      -- Definición de detalles de Pagos
      select @w_cont_pag    = count(1), 
             @w_order_count = 1 
      from #det_pago_factura  

      while @w_cont_pag > 0 
      begin 
      
         select top 1
            @w_concepto_fact  = concepto, 
            @w_monto_fact     = isnull(monto, 0),
            @w_categoria_fact = categoria,
            @w_cat_desc_fact  = cat_desc
         from #det_pago_factura
         
         if @w_categoria_fact not in ('I', 'M')  -- Capital y otros
         begin	
            select @w_descripcion_det = 'Abono a ' + case when @w_categoria_fact = 'C' then 'capital' else @w_cat_desc_fact end + ' de préstamo',
                   @w_precio_unit   = convert(varchar(15), isnull(@w_monto_fact, 0)),
				   @w_monto_iva     = '0',
				   @w_venta_no_suj  = '0',
				   @w_venta_exenta  = '0',
				   @w_venta_gravada = '0',
				   @w_venta_no_grav = convert(varchar(15), isnull(@w_monto_fact, 0))
         end
            
         if @w_categoria_fact in ('I', 'M') -- Interés corriente e Interés Mora
         begin	
            select @w_descripcion_det = 'Abono a interés ' + case when @w_categoria_fact = 'M' then 'moratorio ' else '' end + 'de préstamo',
                   @w_precio_unit   = convert(varchar(15), isnull(@w_monto_fact, 0)),
				   @w_monto_iva     = '0',
				   @w_venta_no_suj  = '0',
				   @w_venta_exenta  = convert(varchar(15), isnull(@w_monto_fact, 0)),
				   @w_venta_gravada = '0',
				   @w_venta_no_grav = '0'
         end
         
         insert into @detalles (id_col, code, descr, unitPr, ivaAmo, saleNoSub, exemptSale, taxedSale, untaxedSale)
         values (@w_order_count, @w_concepto_fact, @w_descripcion_det, @w_precio_unit, @w_monto_iva, @w_venta_no_suj, @w_venta_exenta, @w_venta_gravada, @w_venta_no_grav)
      
         select @w_order_count = @w_order_count + 1
      
         delete #det_pago_factura where concepto = @w_concepto_fact 
         set @w_cont_pag = (select count(1) from #det_pago_factura) 
         
      end
      
      drop table #det_pago_factura
	  
   end

   -- ESTABLECIMIENTO DE APÉNDICES
   select @w_num_ape = count(1) from @apendice
   
   while @w_num_ape > 0
   begin
   
      select @w_ape_registro = field + '|' + label + '|' + valuee from @apendice where id_col = @w_num_ape
      
	  if @w_num_ape = 1
	     select @w_ape_registro1 = @w_ape_registro
	  if @w_num_ape = 2
	     select @w_ape_registro2 = @w_ape_registro
	  if @w_num_ape = 3
	     select @w_ape_registro3 = @w_ape_registro
	  if @w_num_ape = 4
	     select @w_ape_registro4 = @w_ape_registro
	  if @w_num_ape = 5
	     select @w_ape_registro5 = @w_ape_registro
	  if @w_num_ape = 6
	     select @w_ape_registro6 = @w_ape_registro
	  if @w_num_ape = 7
	     select @w_ape_registro7 = @w_ape_registro
	  if @w_num_ape = 8
	     select @w_ape_registro8 = @w_ape_registro
	  if @w_num_ape = 9
	     select @w_ape_registro9 = @w_ape_registro
	  if @w_num_ape = 10
	     select @w_ape_registro10 = @w_ape_registro

      select @w_num_ape = @w_num_ape - 1
   end
		 
   -- ESTABLECIMIENTO DE DETALLES
   select @w_num_det = count(1) from @detalles
   
   while @w_num_det > 0
   begin
   
      select @w_det_registro = code+'|'+ descr+'|'+unitPr+'|'+ivaAmo+'|'+saleNoSub+'|'+exemptSale+'|'+taxedSale+'|'+untaxedSale 
	  from @detalles 
	  where id_col = @w_num_det
      
      if @w_num_det = 1
         select @w_det_registro1 = @w_det_registro
      if @w_num_det = 2
         select @w_det_registro2 = @w_det_registro
      if @w_num_det = 3
         select @w_det_registro3 = @w_det_registro
      if @w_num_det = 4
         select @w_det_registro4 = @w_det_registro
      if @w_num_det = 5
         select @w_det_registro5 = @w_det_registro
      if @w_num_det = 6
         select @w_det_registro6 = @w_det_registro
      if @w_num_det = 7
         select @w_det_registro7 = @w_det_registro
      if @w_num_det = 8
         select @w_det_registro8 = @w_det_registro
      if @w_num_det = 9
         select @w_det_registro9 = @w_det_registro
      if @w_num_det = 10
         select @w_det_registro10 = @w_det_registro
      if @w_num_det = 11
         select @w_det_registro11 = @w_det_registro
      if @w_num_det = 12
         select @w_det_registro12 = @w_det_registro
      if @w_num_det = 13
         select @w_det_registro13 = @w_det_registro
      if @w_num_det = 14
         select @w_det_registro14 = @w_det_registro
      if @w_num_det = 15
         select @w_det_registro15 = @w_det_registro

      select @w_num_det = @w_num_det - 1
   end
    
end

if @i_operacion = 'R'
begin

   if (@t_corr is null or @t_corr <> 'S')
       or @t_ssn_corr is null
       or @t_fecha_ssn_corr is null
   begin
      select @w_error = 708150 -- Campo requerido esta con valor nulo
      goto ERROR
   end

end

-- Ejecuciíon de proceso de tanqueo
exec @w_error = cob_externos..sp_tanqueo_fact_elec
@i_operacion      = 'I',
@i_ide_tipo_dte   = @w_tipo_doc_fiscal, 
@i_rec_ente       = @w_cliente,
@i_det_registro1  = @w_det_registro1,
@i_det_registro2  = @w_det_registro2,
@i_det_registro3  = @w_det_registro3,
@i_det_registro4  = @w_det_registro4,
@i_det_registro5  = @w_det_registro5,
@i_det_registro6  = @w_det_registro6,
@i_det_registro7  = @w_det_registro7,
@i_det_registro8  = @w_det_registro8,
@i_det_registro9  = @w_det_registro9,
@i_det_registro10 = @w_det_registro10,
@i_det_registro11 = @w_det_registro11,
@i_det_registro12 = @w_det_registro12,
@i_det_registro13 = @w_det_registro13,
@i_det_registro14 = @w_det_registro14,
@i_det_registro15 = @w_det_registro15,
@i_ven_tercero    = 'S',
@i_ape_registro1  = @w_ape_registro1,
@i_ape_registro2  = @w_ape_registro2, 
@i_ape_registro3  = @w_ape_registro3, 
@i_ape_registro4  = @w_ape_registro4, 
@i_ape_registro5  = @w_ape_registro5, 
@i_ape_registro6  = @w_ape_registro6, 
@i_ape_registro7  = @w_ape_registro7, 
@i_ape_registro8  = @w_ape_registro8, 
@i_ape_registro9  = @w_ape_registro9, 
@t_corr           = @t_corr,
@t_ssn_corr       = @t_ssn_corr,
@t_fecha_ssn_corr = @t_fecha_ssn_corr,
@t_trn            = 172230,
@s_user           = @s_user,
@s_date           = @s_date,
@s_rol            = @s_rol, 
@s_term           = @s_term,
@s_ofi            = @s_ofi,
@s_ssn            = @s_ssn, 
@i_ope_banco      = @i_ope_banco ,
@i_prd_cobis      = 7, 
@i_externo        = 'N',
@o_guid           = @o_guid out,
@o_fecha_registro = @w_fecha_registro out,
@o_ssn            = @o_ssn out,
@o_ejecutar_orq   = @w_ejecutar_orq out       

if @w_error <> 0
begin
   if @w_error <> 1720647 -- IGNORA ERROR TANQUEO, YA QUE ESTE ERROR REPRESENTA RV A NIVEL DE COBIS 
      goto ERROR
end	
      
select @o_orquestador_fact = case when @w_ejecutar_orq = 'S' then @w_orquestador_fact else 'N' end,
       @o_fecha_registro   = substring(convert(varchar,@w_fecha_registro, 103),1,15)
   
-- Acciones después del proceso de tanqueo
if @i_operacion = 'I'
begin
   if @i_tipo_tran = 'PAG'
   begin   
      -- Actualización de registros de sesión e id único para factura
      update ca_abono 
      set ab_ssn      = @o_ssn,
          ab_guid_dte = @o_guid
      where ab_operacion      = @w_operacionca
      and   ab_secuencial_ing = @i_secuencial_ing
        
      if @@error != 0 return 710002 -- Error en la actualizacion del registro
   end   
end

if @i_externo = 'S'
   commit tran
   
SALIR: 

return 0

ERROR:
if @i_externo = 'S'
begin 

if object_id ('tempdb..#det_pago_factura', 'U') is not null
   drop table #det_pago_factura
	  
   rollback tran
   exec cobis..sp_cerror
   @t_debug = 'N',    
   @t_file  = null,
   @t_from  = @w_sp_name,   
   @i_num   = @w_error
   
end

return @w_error
go
