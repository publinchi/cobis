/************************************************************************/
/*	Nombre Fisico:		contasie.sp										*/
/*	Nombre Logico:		sp_caconta_asie									*/
/*	Base de datos:		cob_cartera										*/
/*	Producto: 			Cartera											*/
/*	Disenado por:  		Ricardo Reyes Betr n							*/
/*	Fecha de escritura:	Abr. 2002										*/
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios que son       	*/
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  	*/
/*   representantes exclusivos para comercializar los productos y   	*/
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida 	*/
/*   y regida por las Leyes de la República de España y las         	*/
/*   correspondientes de la Unión Europea. Su copia, reproducción,  	*/
/*   alteración en cualquier sentido, ingeniería reversa,           	*/
/*   almacenamiento o cualquier uso no autorizado por cualquiera    	*/
/*   de los usuarios o personas que hayan accedido al presente      	*/
/*   sitio, queda expresamente prohibido; sin el debido             	*/
/*   consentimiento por escrito, de parte de los representantes de  	*/
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  	*/
/*   en el presente texto, causará violaciones relacionadas con la  	*/
/*   propiedad intelectual y la confidencialidad de la información  	*/
/*   tratada; y por lo tanto, derivará en acciones legales civiles  	*/
/*   y penales en contra del infractor según corresponda. 				*/
/************************************************************************/  
/*				PROPOSITO												*/
/*	Contabiliza las provisiones (calculo diario de interes) para    	*/
/*      cuando se requiera Minuta y Cadicona							*/
/************************************************************************/
/*                            MODIFICACIONES                            */
/*   FECHA                  AUTOR                  RAZON                */
/*    06/06/2023	 M. Cordova		  Cambio variable @w_op_calificacion*/
/*									  de char(1) a catalogo				*/
/************************************************************************/
  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_caconta_asie')
	drop proc sp_caconta_asie
go

create proc sp_caconta_asie
	@s_user		login    = null,
    	@i_filial       int      = 1,
	@i_fecha        datetime = null,
	@i_tipo_trn    	catalogo = null,
	@i_operacion 	int      = null,
	@i_debug	char(1)  = 'N',
        @i_actualizar   char(1)  = 'N'

as declare 
        @w_error          	int,
        @w_return         	int,
        @w_sp_name        	descripcion,
        @w_money          	money,
        @w_banco          	cuenta,
	@w_asiento		int,
	@w_cuenta_final		varchar(60),
	@w_dp_debcred		char(1),
	@w_tipo_doc  		char(1),
	@w_dp_cuenta		varchar(60),
	@w_dp_constante		varchar(20),
	@w_cuenta_aux		varchar(60),
	@w_pos			int,
	@w_trama		varchar(60),
	@w_ascii 		int,
	@w_contenido_trama	int,
	@w_resultado		varchar(60),
	@w_dtr_concepto		catalogo,
	@w_dtr_moneda		int,
	@w_dtr_monto		money,
	@w_dtr_monto_mn		money,
	@w_dtr_cotizacion	money,
	@w_dtr_estado		tinyint,
	@w_debito		money,
	@w_credito		money,
	@w_debito_me		money, 
	@w_credito_me		money,
	@w_tot_debito		money,
	@w_tot_credito		money,
	@w_tot_credito_me	money,
	@w_tot_debito_me	money,
	@w_re_ofconta		int,
	@w_moneda_cont		char(1),
	@w_moneda_nacional 	tinyint,
	@w_comprobante		int,
	@w_debcred		int,
	@w_debcred_s		char(1),
	@w_debcred_m		char(1),
	@w_of_destino		int,
	@w_of_origen		int,
	@w_ar_destino		varchar(10),
	@w_ar_origen		int,
	@w_posicion		char(1), 
	@w_mensaje		varchar(255),
	@w_tr_toperacion	catalogo,
	@w_tr_operacion		int,
	@w_perfil		catalogo,
	@w_tr_tran		catalogo,
	@w_descripcion     	varchar(255),
	@w_descripcion_aux     	varchar(255),
	@w_tr_secuencial        int,
	@w_tr_secuencial_ref    int,
	@w_evitar_asiento       char(1), 
	@w_decimales            char(1), 
        @w_num_dec_mn           int,
	@w_rollback             int,
        @w_edad                 catalogo, 
        @w_clase                char(1), 
        @w_fondo                catalogo, 
        @w_linea                catalogo, 
        @w_moneda               catalogo, 
        @w_linmon               catalogo, 
        @w_moncl                catalogo, 
        @w_focla                catalogo, 
        @w_clave                catalogo,
        @w_origen_dest          char(1),
	@w_ipc			tinyint,
	@w_fondos_propios	char(1),
	@w_tipo_empresa		catalogo,
	@w_validacion		catalogo,
	@w_cupo_credito		cuenta, 
	@w_ente			int,
	@w_concepto_iva		catalogo,
	@w_concepto_timbre	catalogo,
	@w_con_iva		catalogo,
	@w_con_rete		catalogo,
	@w_valor_iva		money,	 
	@w_valor_rete		money, 	 
	@w_valor_base		money,	 
	@w_reversa		tinyint,	
	@w_trm			float,
	@w_tr_usuario		varchar(15),
        @w_tr_fecha_mov         datetime,
        @w_desc_tran            varchar(64),
	@w_nat_juridica		char(1),
	@w_tipo_compania	catalogo,
        @w_tr_gerente           smallint, 
        @w_re_area		int,
	@w_tipogar		char(1),
	@w_normal		char(1),
	@w_categoria		char(1),
	@w_naturaleza		char(1),
	@w_tipo_linea		varchar(10),
	@w_monto_mn		money,
	@w_utiliza_valor	char(1),
        @w_oficina		int,
	@w_dtr_codvalor		int,
        @w_msg_conta		varchar(255),
	@w_cod_gar		char(1),
	@w_cod_res		char(1),
	@w_monto_mc	     	money,
   	@w_cotizacion_mc  	money,
   	@w_monto_mn_mc    	money,
        @w_mon_op		smallint,
	@w_es_extranjera	char(1),
	@w_anexo		varchar(255),
	@w_tr_moneda		int,
        @w_num_reg		int,
        @w_tr_estado		char(3),
	@w_tr_comprobante	int,
	@w_tr_fecha_cont	datetime,
	@w_ofconta		int,
	@w_dummy		int,
	@w_reestructurado       char(1),
	@w_calificacion		catalogo,	--RRB Circular 50 03/19/2002
	@w_cla_vivi		char(1),	--RRB Circular 50 03/19/2002
	@w_cla_micr		char(1),	--RRB Circular 50 03/19/2002
	@w_cla_cons		char(1),	--RRB Circular 50 03/19/2002
	@w_cla_come		char(1),	--RRB Circular 50 03/19/2002
	@w_estado_op		int, -- TEMPORAL
	@w_tran_minuta		int,
	@w_codvalor		int,
	@w_cod_sus		char(1),
	@w_parte1		varchar(4),
	@w_parte2		varchar(5),
	@w_tr_banco		cuenta,	--MPO Ref. 012 02/04/2002
	@w_num_dec_moneda	smallint, --MPO Ref. 024 02/20/2002
	@w_rowcount             int



/* VARIABLES DE TRABAJO */
select 
@w_sp_name         = 'contasie.sp',
@w_mensaje         = '',
@w_anexo	   = ''

/* MONEDA NACIONAL */
select @w_moneda_nacional = pa_tinyint
from cobis..cl_parametro
where pa_producto = 'ADM'
and   pa_nemonico = 'MLO'
set transaction isolation level read uncommitted

/* CODIGO DE CONCEPTO IVA  */
select @w_concepto_iva = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'PIVA'
set transaction isolation level read uncommitted

/* CODIGO DE CONCEPTO TIMBRE */
select @w_concepto_timbre = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'TIMBRE'
set transaction isolation level read uncommitted

/* MANEJO DE MONEDA IPC  (XSA 05/05/1999) */
select @w_ipc = pa_tinyint
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'IPC'
set transaction isolation level read uncommitted

/** MANEJO DE DECIMALES **/
exec @w_return = sp_decimales
@i_moneda    = @w_moneda_nacional,
@o_decimales = @w_num_dec_mn out

/* MANEJO DE CLASES DE CARTERA */

select @w_cla_vivi = pa_char from cobis..cl_parametro
where pa_producto = 'CRE'
and pa_nemonico = 'CVIV'
set transaction isolation level read uncommitted

select @w_cla_micr = pa_char from cobis..cl_parametro
where pa_producto = 'CRE'
and pa_nemonico = 'CMIC'
set transaction isolation level read uncommitted

select @w_cla_cons = pa_char from cobis..cl_parametro
where pa_producto = 'CRE'
and pa_nemonico = 'CCON'
set transaction isolation level read uncommitted

select @w_cla_come = pa_char from cobis..cl_parametro
where pa_producto = 'CRE'
and pa_nemonico = 'CCOM'
set transaction isolation level read uncommitted

/** TABLA TEMPORAL PARA ALMACENAR LOS ASIENTOS **/
create table #asiento_prv (
asiento		int,
cuenta		varchar(24),
oficina_dest	smallint,
area_dest	int,
credito		money,
debito		money,
concepto	varchar(10),
credito_me	money,
debito_me	money,
moneda		int, 
cotizacion	float,
debcred		char(1),
moneda_cont     char(1),
ente		int		null,	
operacion	varchar(24)	null,	
con_iva		varchar(10)	null,	
valor_iva	money		null,	
con_rete	varchar(10)	null,	
valor_rete	money		null,	
base		money		null	
)

/* CURSOR PRINCIPAL DE TRANSACCIONES */
declare cursor_tran_prv cursor for 
select
tr_ofi_usu,       tr_ofi_oper,   tr_toperacion,  
tr_tran,          tr_secuencial, tr_operacion, 
tr_secuencial_ref,tr_usuario,    tr_gerente,
tr_fecha_mov,	  tr_moneda,	 tr_estado, 
tr_comprobante,	  tr_fecha_cont, isnull(tr_gar_admisible,'N'),
isnull(tr_reestructuracion,'N'), isnull(tr_calificacion,'A')
from ca_transaccion
where (tr_fecha_mov = @i_fecha or tr_fecha_cont = @i_fecha )
and tr_tran        = @i_tipo_trn
and tr_estado in ('ING','CON','RV')
and tr_operacion   = @i_operacion
and tr_tran != 'MIG'
for read only

open cursor_tran_prv

fetch cursor_tran_prv into
@w_of_origen,         @w_of_destino,     @w_tr_toperacion, 
@w_tr_tran,           @w_tr_secuencial,  @w_tr_operacion,
@w_tr_secuencial_ref, @w_tr_usuario,     @w_tr_gerente,
@w_tr_fecha_mov,      @w_tr_moneda,	 @w_tr_estado,
@w_tr_comprobante,    @w_tr_fecha_cont,	 @w_tipogar,
@w_reestructurado,    @w_calificacion

while @@fetch_status = 0 begin 

   delete #asiento_prv

--print 'contasie.sp c1 @w_tr_secuencial' +  @w_tr_secuencial
  
   /* SI SE TRATA DE UNA TRANSACCION REVERSADA */
   /* DETERMINAR EL TIPO DE TRANSACCION DE LA ORIGEN */
   select @w_reversa = 0

   if @w_tr_tran = 'REV' begin
      select @w_tr_tran = tr_tran
      from   ca_transaccion
      where  tr_secuencial = @w_tr_secuencial_ref  
      and    tr_operacion  = @w_tr_operacion 

      select @w_reversa = 1,
      @w_desc_tran = 'REVERSA DE'
   end else
      select @w_desc_tran = ''

   select @w_desc_tran = @w_desc_tran + ' ' + tt_descripcion
   from ca_tipo_trn
   where tt_codigo = @w_tr_tran

   /* VARIABLES INICIALES */
   select 
   @w_cuenta_final   = '',
   @w_re_ofconta     = 0,
   @w_re_area        = 0,
   @w_credito        = 0,
   @w_debito         = 0,
   @w_dtr_concepto   = '',
   @w_credito_me     = 0,
   @w_debito_me      = 0,
   @w_dtr_moneda     = 0,
   @w_dtr_cotizacion = 0,
   @w_debcred_s      = '',
   @w_moneda_cont    = '',
   @w_ente           = 0, 
   @w_banco          = '',
   @w_con_iva        = '',
   @w_valor_iva      = 0,
   @w_con_rete	     ='',
   @w_valor_base     = 0,
   @w_valor_rete     = 0,
   @w_oficina        = 0,
   @w_dtr_codvalor   = 0,
   @w_asiento        = 0,
   @w_tot_credito    = 0,
   @w_tot_debito     = 0,
   @w_tot_credito_me = 0,
   @w_tot_debito_me  = 0,
   @w_rollback       = 0,
   @w_mensaje        = '',
   @w_ente           = 0,
   @w_banco          = '',
   @w_edad           = '',
   @w_clase          = '',
   @w_fondo          = '',
   @w_fondos_propios = '',
   @w_moneda         = '',
   @w_linmon         = '',
   @w_moncl          = '',
   @w_focla          = '',
   @w_tipo_empresa   = '',
   @w_validacion     = '',
   @w_cupo_credito   = '',
   @w_perfil 	     = '',
   @w_descripcion    = '',
   @w_normal	     = '',
   @w_tipo_linea     = '',
   @w_linea          = '',
   @w_categoria      = '',
   @w_monto_mc	     = 0,
   @w_cotizacion_mc  = 0,
   @w_monto_mn_mc    = 0,
   @w_anexo	     = ''

   /* DETERMINAR PERFIL CONTABLE */
   select @w_perfil = to_perfil
   from ca_trn_oper
   where to_toperacion = @w_tr_toperacion
   and   to_tipo_trn =  @w_tr_tran

   if @w_perfil = '' begin
      select @w_error = 710338
      select @w_rollback = 2
      select @w_anexo = 'sp_caconta_asie, Error No existe relaci½n perfil ' + @w_banco + '-' + @w_tr_tran
      goto ERROR1
   end

   /** VALIDAR QUE EL PERFIL EXISTA EN CONTABILIDAD **/
   if not exists(select 1 from cob_conta..cb_perfil
   where pe_empresa  = 1
   and   pe_producto = 7
   and   pe_perfil = @w_perfil) begin
      select @w_error = 710346
      select @w_rollback = 2
      select @w_anexo = 'sp_caconta_asie, Error No existe relaci½n perfil ' + @w_banco + '-' + @w_tr_tran
      goto ERROR1      
   end

   if @i_debug = 'S' print 'TIPO OP.-->' + @w_tr_toperacion + 'TRN.-->' + @w_tr_tran + 'PERFIL-->' + @w_perfil 

   /* CODIGO DE LA TRANSACCION EQUIVALENTE EN MINUTA COBIS */
   select @w_tran_minuta = tn_trn_code
   from cobis..cl_ttransaccion
   where tn_nemonico = @w_tr_tran
   set transaction isolation level read uncommitted

   /* DESCRIPCION DEL COMPROBANTE A GENERAR */

   select 
   @w_ente    = op_cliente,
   @w_banco   = op_banco,
   @w_edad    = convert(varchar(10),op_edad),
   @w_clase   = rtrim(ltrim(op_clase)),
   @w_moneda  = convert(varchar(10),op_moneda),
   @w_tipogar = isnull(op_gar_admisible,'N'),
   @w_reestructurado  = isnull(op_reestructuracion,'N'),
   @w_linea   = op_toperacion,
   @w_tipo_linea = op_tipo_linea,
   @w_oficina = op_oficina,
   @w_mon_op  = op_moneda,
   @w_calificacion = op_calificacion,
   @w_estado_op = op_estado
   from ca_operacion
   where op_operacion = @w_tr_operacion

   if @@rowcount = 0 begin
      select @w_error = 710318
      select @w_rollback = 2
      goto ERROR1
   end
   /*******
   /** DETERMINAR SI ES MONEDA EXTRANJERA **/
   if @w_mon_op != @w_moneda_nacional begin
      if @w_mon_op != @w_tr_moneda 
         select @w_es_extranjera = 'S'
      else
         select @w_es_extranjera = 'N'
   end
   *******/
   /** SELECCION DE LA NATURALEZA JURIDICA DE CLIENTE **/
   select @w_tipo_compania = isnull(c_tipo_compania,'PA')
   from cobis..cl_ente
   where en_ente = @w_ente
   set transaction isolation level read uncommitted

   select @w_nat_juridica = nj_tipo
   from cobis..cl_nat_jur
   where nj_codigo = @w_tipo_compania
   set transaction isolation level read uncommitted

   select @w_nat_juridica = isnull(@w_nat_juridica, 'P')
   
   select @w_descripcion = 
   rtrim(@w_desc_tran)+': '+rtrim(@w_tr_toperacion)+' '+
   rtrim(@w_banco)+' '+ rtrim(@w_perfil) +'  Tr.No: ' +
   convert(varchar,@w_tr_secuencial)

   /** SELECCION CATEGORIA DE LINEA DE CREDITO **/
   select @w_categoria = dt_categoria,
   @w_naturaleza = dt_naturaleza
   from   ca_default_toperacion
   where  dt_toperacion = @w_linea
   and    dt_moneda = convert(tinyint,@w_moneda)

   /** SELECCION TIPO DE GARANTIA **/
   if @w_tipogar = 'S' --Admisible
      select @w_tipogar = 'I'
   else
      select @w_tipogar = 'O'

   /** VERIFICACION DE LA CALIFICACION **/
   if @w_calificacion not in 
      (select codigo
       from cobis..cl_catalogo
       where tabla = (select codigo from cobis..cl_tabla where tabla =  'cr_calificacion' )
      )
      or @w_calificacion is null
      select @w_calificacion = 'A'

   /** SELECCION ORIGEN **/
   if @w_reestructurado = 'S' --Reestructurada
      select @w_normal = 'R'
   else
      select @w_normal = 'N'

   select @w_dtr_monto = dtr_monto,
	  @w_dtr_concepto = dtr_concepto,
	  @w_dtr_cotizacion = dtr_cotizacion
   from ca_det_trn
   where dtr_operacion = @w_tr_operacion
   and dtr_secuencial = @w_tr_secuencial

   select @w_dummy = @w_tr_operacion
   from ca_det_trn, cob_conta..cb_det_perfil noholdlock
   where dtr_operacion = @w_tr_operacion
   and dtr_secuencial = @w_tr_secuencial
   and dp_empresa     = @i_filial
   and dp_producto    = 7 
   and dp_perfil      = @w_perfil
   and dp_codval      = dtr_codvalor   

      if @@rowcount = 0 begin
	 /*print '@w_tr_operacion %1! - @w_tr_secuencial %2! - @w_perfil %3! - @i_filial %4!'+ */
       	 /*       @w_tr_operacion + @w_tr_secuencial + @w_perfil + @i_filial*/
         select @w_error = 710319
         select @w_rollback = 2
         select @w_anexo = 'sp_caconta_asie, Error No existe relaci¢n perfil ' + @w_banco + '-' + @w_tr_tran
         goto ERROR1
      end

   /** CURSOR PARA OBTENER LOS DETALLES DEL PERFIL RESPECTIVO **/
   declare cursor_perfil_cca_prv cursor for select
   dtr_concepto,   dtr_moneda,       dtr_cotizacion,
   dp_cuenta,      dp_debcred,       dp_constante,
   dp_area,        dtr_monto,        dtr_monto_mn,
   dp_origen_dest, dtr_estado,	     dtr_codvalor
   from ca_det_trn, cob_conta..cb_det_perfil noholdlock
   where dtr_secuencial = @w_tr_secuencial
   and dtr_operacion  = @w_tr_operacion
   and dtr_secuencial = @w_tr_secuencial
   and dp_empresa     = @i_filial
   and dp_producto    = 7 
   and dp_perfil      = @w_perfil
   and dp_codval      = dtr_codvalor   
   for read only

   open cursor_perfil_cca_prv

   fetch cursor_perfil_cca_prv into
   @w_dtr_concepto, @w_dtr_moneda,   @w_dtr_cotizacion,
   @w_dp_cuenta,    @w_dp_debcred,   @w_dp_constante,   
   @w_ar_destino,   @w_dtr_monto,    @w_dtr_monto_mn,
   @w_origen_dest,  @w_dtr_estado,   @w_dtr_codvalor

   while @@fetch_status = 0 begin 

--print 'contasie.sp c2 @w_tr_secuencial'+ @w_tr_secuencial
      select @w_evitar_asiento = 'N' 

      if @i_debug = 'S' print 'CONCEPTO-->  CUENTA-->' + @w_dtr_concepto + @w_dp_cuenta

      select @w_con_iva = '',
      @w_valor_base = 0,
      @w_valor_iva = 0,
      @w_con_rete = '',
      @w_valor_rete = 0

      --MPO Ref. 024 02/20/2002 
      /** DECIMALES MONEDA **/
      exec @w_return = sp_decimales
      @i_moneda    = @w_dtr_moneda,
      @o_decimales = @w_num_dec_moneda out

      /** REDONDEO A MONEDA **/
      select @w_dtr_monto_mn = round(@w_dtr_monto_mn, @w_num_dec_mn)
      select @w_dtr_monto    = round(@w_dtr_monto,    @w_num_dec_moneda)
      --MPO Ref. 024 02/20/2002

      /** SELECCION ORIGEN **/
      if @w_reestructurado = 'S' --Reestructurada
         select @w_normal = 'R'
      else
         select @w_normal = 'N'


      /** PARA INTERFAZ MESA DE CAMBIO **/
      select @w_monto_mc = @w_monto_mc + @w_dtr_monto,
      @w_cotizacion_mc   = @w_cotizacion_mc + @w_dtr_cotizacion,
      @w_monto_mn_mc     = @w_monto_mn_mc + @w_dtr_monto_mn


      /** SELECCION DE AREA **/
      select @w_utiliza_valor = ta_utiliza_valor,
      @w_re_area = ta_area
      from   cob_conta..cb_tipo_area
      where  ta_empresa = @i_filial
      and    ta_producto = 7
      and    ta_tiparea = @w_ar_destino
      select @w_rowcount = @@rowcount
      set transaction isolation level read uncommitted

      if @w_rowcount = 0 begin
         select @w_error = 710319
         select @w_rollback = 2
         select @w_anexo = 'Area: ' + @w_ar_destino
         close cursor_perfil_cca_prv
         deallocate cursor_perfil_cca_prv
         goto ERROR1
      end
      
      if @w_ar_destino = 'G' begin  -- Area del Gerente
         if @w_utiliza_valor = 'N' begin
            select @w_re_area = re_area 
	    from cob_conta..cb_relarea
            where re_gerente = @w_tr_gerente

            if @@rowcount = 0 begin
               select @w_error = 710320
               select @w_rollback = 2
               select @w_anexo = 'Gerente: ' + convert(varchar(10), @w_tr_gerente)
               close cursor_perfil_cca_prv
               deallocate cursor_perfil_cca_prv         
               goto ERROR1
            end
         end   
      end 

      /** SELECCION DE OFICINA **/
      if @w_origen_dest = 'O' --Oficina origen
         select @w_ofconta = @w_of_origen
      else 
         if @w_origen_dest = 'D' --Oficina destino
            select @w_ofconta = @w_of_destino
         else
            if @w_origen_dest = 'C' --Oficina central
               select @w_re_ofconta = 99 
	     
      if @w_dp_constante = 'L' 
         select @w_moneda_cont = 'L'
      else
         select @w_moneda_cont = 'T'

      select @w_debcred      = convert(int,@w_dp_debcred)
      select @w_cuenta_final = ''

      /** RESOLUCION DE LA CUENTA DINAMICA **/
      select @w_cuenta_aux = @w_dp_cuenta
      select @w_pos = charindex('.',@w_cuenta_aux)

      while 0 = 0 begin

--print 'contasie.sp w1 @w_tr_secuencial' + @w_tr_secuencial

         /* ELIMINAR PUNTOS INICIALES */
         while @w_pos = 1 begin
            select @w_cuenta_aux = 
            substring (@w_cuenta_aux, 2, datalength(@w_cuenta_aux) - 1)
            select @w_pos = charindex('.',@w_cuenta_aux)
         end

         /* AISLAR SIGUIENTE PARAMETRO DEL RESTO DE LA CUENTA */
         if @w_pos > 0 begin --existe al menos un parametro
            select @w_trama = substring (@w_cuenta_aux,1,@w_pos-1)
            select @w_cuenta_aux = substring (@w_cuenta_aux,@w_pos+1, datalength(@w_cuenta_aux)-@w_pos)
            select @w_pos = charindex('.',@w_cuenta_aux)
         end else begin
            select @w_trama = @w_cuenta_aux
            select @w_cuenta_aux = ''
         end

         /* CONDICION DE SALIDA DEL LAZO */
         if @w_trama = '' 
            break

         /* VERIFICAR SI LA TRAMA ES PARTE FIJA O PARAMETRO */
         select @w_ascii = ascii(substring(@w_trama,1,1))

         if @w_ascii >= 48 and @w_ascii <= 57 begin --NUMERICO,PARTE FIJA
            select @w_cuenta_final = @w_cuenta_final + @w_trama 
         end else begin  --LETRA, LA TRAMA ES UN PARAMETRO
            select 
            @w_resultado = '',
            @w_clave     = ''

            if @w_tr_tran = 'CGR' begin
               select @w_cod_gar = substring(convert(varchar(5),@w_dtr_codvalor),5,5)
               if @w_cod_gar = '2'
                  select @w_tipogar = 'I'
               else
                  select @w_tipogar = 'O'
            end
            
	    if @w_tr_tran = 'RES' begin
               select @w_cod_res = substring(convert(varchar(5),@w_dtr_codvalor),5,5)
               if @w_cod_res = '4'
                  select @w_normal = 'R'
               else
                  select @w_normal = 'N'
            end

            if charindex('CTE'  ,@w_trama)=1 select @w_clave=@w_clase + '.' + @w_tipogar + '.' + convert(varchar(10),@w_dtr_estado)
            if charindex('MON'  ,@w_trama)=1 select @w_clave=convert(varchar(10), @w_dtr_moneda)
            if charindex('COR'  ,@w_trama)=1 select @w_clave=convert(varchar(10), @w_ente)
            if charindex('TLI'  ,@w_trama)=1 select @w_clave=@w_tipo_linea
            if charindex('TLE'  ,@w_trama)=1 select @w_clave=@w_tipo_linea
            if charindex('CAT'  ,@w_trama)=1 select @w_clave=@w_categoria		
            if charindex('EOR'  ,@w_trama)=1 select @w_clave=@w_nat_juridica+'.'+@w_normal
            if charindex('TGE'  ,@w_trama)=1 select @w_clave=@w_tipogar+'.'+convert(varchar(10),@w_dtr_estado)
            if charindex('EST'  ,@w_trama)=1 select @w_clave=convert(varchar(10),@w_dtr_estado)
            if charindex('CLC'  ,@w_trama)=1 select @w_clave=@w_clase
            if charindex('MGE'  ,@w_trama)=1 select @w_clave=convert(varchar(10), @w_dtr_moneda) + '.' + @w_tipogar + '.' + convert(varchar(10),@w_dtr_estado)
            if charindex('CTP'  ,@w_trama)=1 select @w_clave=@w_categoria
            if charindex('CCI'  ,@w_trama)=1 select @w_clave=@w_clase + '.' + @w_categoria
	    if charindex('CCS'  ,@w_trama)=1 select @w_clave=@w_clase

	    /** CIRCULAR 50 **/

    	    if charindex('CGA'  ,@w_trama)=1 select @w_clave=@w_clase + '.' + @w_tipogar
	    if charindex('CMO'  ,@w_trama)=1 select @w_clave=@w_clase + '.' + convert(varchar(10), @w_dtr_moneda)
	    if charindex('GEO'  ,@w_trama)=1 select @w_clave=@w_tipogar + '.' + rtrim(@w_tipo_compania) + '.' + @w_reestructurado

	    if @w_clase in (@w_cla_cons,@w_cla_vivi) and
	       charindex('RCE'  ,@w_trama)=1 select @w_clave=@w_calificacion + '.' + @w_clase

	    if charindex('RCI'  ,@w_trama)=1 select @w_clave=@w_calificacion + '.' + @w_clase
	    if charindex('RCL'  ,@w_trama)=1 select @w_clave=@w_calificacion + '.' + @w_clase
            if charindex('RGC'  ,@w_trama)=1 select @w_clave=@w_calificacion + '.' + @w_tipogar + '.' + @w_clase
	    if charindex('RIE'  ,@w_trama)=1 select @w_clave=@w_calificacion
	    if charindex('CES'  ,@w_trama)=1 select @w_clave=@w_clase + '.' + convert(varchar(10),@w_dtr_estado)
	    if charindex('CESC'  ,@w_trama)=1 select @w_clave=@w_clase + '.' + convert(varchar(10),@w_dtr_estado)
	    if charindex('CESI'  ,@w_trama)=1 select @w_clave=@w_clase + '.' + convert(varchar(10),@w_dtr_estado)

/** PARCHADO HASTA CUANDO SE DECIDA UTILIZAR - JCQ - 10/07/2002 **/
/**
            if charindex('ORI' ,@w_trama)=1 begin
                exec @w_return = cob_comext..sp_datos_linea_credito
                        @s_ssn      = @w_tr_secuencial,
                        @s_sesn      = @w_tr_secuencial,
                        @s_term     = 'CONSOLA',
                        @s_date     = @i_fecha,
                        @s_org      = 'L',
                        @i_codlc    = @w_cupo_credito,
                        @o_paisori  = @w_clave out  

                if @w_return !=0 begin
                        select @w_error = @w_return
                        select @w_mensaje = 'ERROR:(CONTABILIDAD) AL EJECUTAR EL SP_DATOS_LINEA_CREDITO'
                        select @w_rollback = 2
                        close cursor_perfil_cca_prv
                        deallocate cursor_perfil_cca_prv
                        goto ERROR1
                end
            end
**/

            if @w_clave != ''  begin 
               
               
               select @w_resultado = re_substring
               from cob_conta..cb_relparam 
               where re_empresa   = @i_filial
               and   re_parametro = @w_trama
               and   re_clave     = @w_clave
               select @w_rowcount = @@rowcount
	       set transaction isolation level read uncommitted

               if @w_rowcount = 0 select @w_evitar_asiento = 'S'

               if @i_debug = 'S' 
               print 'TRAMA-->' + @w_trama + 'CLAVE-->' + @w_clave + 'RESULTADO-->' + @w_resultado            end 

            select @w_cuenta_final = @w_cuenta_final + @w_resultado

         end

      end --fin while 0=0

      select @w_cuenta_final = rtrim( ltrim(@w_cuenta_final) )

      if @w_evitar_asiento = 'N' and @w_cuenta_final <> '' begin
         select @w_asiento = @w_asiento + 1

         /* CAMBIAR CREDITOS Y DEBITOS EN CASO DE NEGATIVOS */
         if @w_dtr_monto < 0 begin
            if @w_debcred = 2 
		select @w_debcred = 1
            else 
		select @w_debcred = 2

            select @w_dtr_monto_mn = -1 * @w_dtr_monto_mn
            select @w_dtr_monto    = -1 * @w_dtr_monto
         end 

	 if @w_reversa = 1 begin
            if @w_debcred = 2 
		select @w_debcred = 1
            else 
		select @w_debcred = 2

            select @w_dtr_monto_mn = @w_dtr_monto_mn
            select @w_dtr_monto    = @w_dtr_monto
	 end

print '@w_dtr_monto_mn' + cast(@w_dtr_monto_mn as varchar)
         
         select
         @w_debito_me      = @w_dtr_monto*(2-@w_debcred),
         @w_credito_me     = @w_dtr_monto*(@w_debcred-1),
         @w_debito         = @w_dtr_monto_mn*(2-@w_debcred),
         @w_credito        = @w_dtr_monto_mn*(@w_debcred-1)

print '@w_credito' + cast(@w_credito as varchar)

         if @w_moneda_cont = 'T' and @w_dtr_moneda <> @w_moneda_nacional begin
            select
            @w_tot_debito_me  = @w_tot_debito_me  + @w_debito_me,
            @w_tot_credito_me = @w_tot_credito_me + @w_credito_me
         end


         if @w_debcred = 2 begin
            select @w_debcred_s = '2' 
            select @w_debcred_m = 'C' 
         end 
         else begin
            select @w_debcred_s = '1'
            select @w_debcred_m = 'D' 
         end

         if @w_origen_dest != 'C' begin
            select @w_re_ofconta = re_ofconta
            from   cob_conta..cb_relofi
            where  re_filial  = @i_filial
            and    re_empresa = @i_filial
            and    re_ofadmin = @w_ofconta
         end

         insert #asiento_prv values (
         @w_asiento,        @w_cuenta_final,     @w_re_ofconta,
         @w_re_area,        @w_credito,          @w_debito,  
         @w_dtr_concepto,   @w_credito_me,       @w_debito_me,
         @w_dtr_moneda,     @w_dtr_cotizacion,   @w_debcred_s,
         @w_moneda_cont,    @w_ente,		 @w_banco,
	 @w_con_iva,	    @w_valor_iva,	 @w_con_rete,
	 @w_valor_rete,	    @w_valor_base) 

         if @@error != 0 begin
            select @w_error = 710330
            select @w_rollback = 2
            close cursor_perfil_cca_prv
            deallocate cursor_perfil_cca_prv  
            goto ERROR1
         end

         /** INSERTAR EN TABLA FISICA **/

	 if not exists (select 1 from ca_asiento_contable where comprobante = @w_tr_comprobante
			and asiento = @w_asiento and @w_banco = operacion)
	 begin
         	insert ca_asiento_contable values (
	         @w_asiento,        @w_cuenta_final,     @w_re_ofconta, 
	         @w_re_area,        isnull(@w_credito,0),          isnull(@w_debito,0), 
	         @w_dtr_concepto,   isnull(@w_credito_me,0),       isnull(@w_debito_me,0),
	         @w_dtr_moneda,     @w_dtr_cotizacion,   @w_debcred_s,
	         @w_moneda_cont,    @w_ente,		 @w_banco,
		 @w_con_iva,	    @w_valor_iva,	 @w_con_rete,
		 @w_valor_rete,	    @w_valor_base,	 @w_tr_tran,
	         @w_tr_fecha_mov,   @w_tr_secuencial,	 @w_oficina,
		 @w_dtr_codvalor,   @w_tr_estado,	 @w_tr_comprobante,
		 @w_tr_fecha_cont) 

	         if @@error != 0 begin
	            select @w_error = 710322
	            select @w_rollback = 2
	            close cursor_perfil_cca_prv
	            deallocate cursor_perfil_cca_prv
	            goto ERROR1
	         end

		 /*** INSERTAR EN LA TABLA PARA COBIS MINUTA ***/
/** PARCHADO HASTA CUANDO SE DECIDA UTILIZAR - JCQ - 10/07/2002 **/
/**
	         if @w_debcred_s = '1' 
		  insert into cob_minuta..mp_temp_aplicativo values(
		  7, 			@w_cuenta_final, 	@w_re_ofconta, 	
		  @i_fecha, 		@w_dtr_moneda,		isnull(@w_debito,0), 	
	          'D',			isnull(@w_debito_me,0), @w_dtr_cotizacion,
		  @w_re_area,		@w_banco,		@w_tran_minuta,
		  @w_dtr_concepto,	@w_oficina,		@w_re_area,
		  @w_ente,		@w_comprobante,		@w_tr_estado,
		  'N'
		  )
	         if @w_debcred_s = '2' 
		  insert into cob_minuta..mp_temp_aplicativo values(
		  7, 			@w_cuenta_final, 	@w_re_ofconta, 	
		  @i_fecha, 		@w_dtr_moneda,		isnull(@w_credito,0), 	
	          'C',			isnull(@w_credito_me,0), @w_dtr_cotizacion,
		  @w_re_area,		@w_banco,		@w_tran_minuta,
		  @w_dtr_concepto,	@w_oficina,		@w_re_area,
		  @w_ente,		@w_comprobante,		@w_tr_estado,
		  'N'
		  )
	         if @@error != 0 begin
	            select @w_error = 710322
	            select @w_rollback = 2
	            select @w_anexo = 'sp_asiento_contable, Error Insertar mp_temp_aplicativo ' + @w_banco + '-' + @w_tr_tran
	            close cursor_perfil_cca
	            deallocate cursor_perfil_cca
	            goto ERROR1
	         end
**/
	end

         if @i_debug = 'S' begin
            print ''
            print 'CUENTA-->' + @w_cuenta_final +  'AREA-->' + @w_ar_destino  + cast(@w_re_area as varchar) + 'OFICINA-->'+ @w_origen_dest + cast(@w_re_ofconta as varchar)
            print ''
         end
       end

      fetch cursor_perfil_cca_prv into
      @w_dtr_concepto, @w_dtr_moneda,   @w_dtr_cotizacion,
      @w_dp_cuenta,    @w_dp_debcred,   @w_dp_constante,   
      @w_ar_destino,   @w_dtr_monto,    @w_dtr_monto_mn ,
      @w_origen_dest,  @w_dtr_estado,   @w_dtr_codvalor

   end
   
   close cursor_perfil_cca_prv
   deallocate cursor_perfil_cca_prv


/****/
   /* DETERMIAR POSICION DEL COMPROBANTE */
   if @w_tot_debito_me = @w_tot_credito_me select @w_posicion = 'N'
   if @w_tot_debito_me > @w_tot_credito_me select @w_posicion = 'N'
   if @w_tot_debito_me < @w_tot_credito_me select @w_posicion = 'N' 

   /* CAMBIAR COTIZACIONES EN CERO Y CUENTAS EN MONEDA NACIONAL */
   select @w_asiento = 0

   while (1=1) begin

      set rowcount 1

      select 
      @w_asiento         = asiento,
      @w_credito         = credito,
      @w_debito          = debito,
      @w_credito_me      = credito_me,
      @w_debito_me       = debito_me,
      @w_dtr_moneda      = moneda,
      @w_dtr_cotizacion  = cotizacion,
      @w_moneda_cont     = moneda_cont
      from #asiento_prv
      where asiento > @w_asiento    

      if @@rowcount = 0 begin
         set rowcount 0
         break
      end

      set rowcount 0

      /* TRANSACCIONES CON COTIZACION NO NEGOCIADA */
      if @w_dtr_cotizacion = 0  begin
         
         exec sp_conversion_moneda
         @s_date                 = @i_fecha,
         @i_opcion               = 'L',
         @i_moneda_monto	 = @w_dtr_moneda,
         @i_moneda_resultado	 = @w_moneda_nacional,
         @i_monto		 = 1,
         @i_fecha                = @i_fecha, --@w_tr_fecha_mov, 
         @o_monto_resultado	 = @w_monto_mn out,
         @o_tipo_cambio          = @w_dtr_cotizacion out

         select 
         @w_debito  = round(@w_debito_me  * @w_dtr_cotizacion,@w_num_dec_mn),
         @w_credito = round(@w_credito_me * @w_dtr_cotizacion,@w_num_dec_mn)

      end

      if @w_dtr_moneda = @w_moneda_nacional or @w_moneda_cont = 'L' begin
         select
         @w_debito_me = 0,
         @w_credito_me = 0,
         @w_dtr_cotizacion = 0,
         @w_dtr_moneda = @w_moneda_nacional
      end

      update #asiento_prv set
      debito     = @w_debito,
      credito    = @w_credito,
      debito_me  = @w_debito_me,
      credito_me = @w_credito_me,
      moneda     = @w_dtr_moneda,
      cotizacion = @w_dtr_cotizacion
      where asiento = @w_asiento

      if @@error != 0 begin
         select @w_error = 710331
         select @w_rollback = 2
         select @w_anexo = 'sp_caconta_asie, Error Actualizar #asiento_prv ' + @w_banco + '-' + @w_tr_tran
         close cursor_tran_prv
         deallocate cursor_tran_prv
         goto ERROR
 
      end

   end


   /* VERIFICAR CUADRE DE VALORES EN MONEDA NACIONAL */
   select 
   @w_tot_debito  = sum(debito),
   @w_tot_credito = sum(credito),
   @w_tot_debito_me  = sum(debito_me),
   @w_tot_credito_me = sum(credito_me)
   from #asiento_prv

   select @w_tot_debito    = isnull(@w_tot_debito, 0)
   select @w_tot_credito   = isnull(@w_tot_credito, 0)
   select @w_tot_debito_me = isnull(@w_tot_debito_me, 0)
   select @w_tot_debito_me = isnull(@w_tot_credito_me, 0)

   select @w_debito = @w_tot_credito - @w_tot_debito

   print '@w_tot_credito' +  cast(@w_tot_credito as varchar)

   if @w_debito <> 0 begin --Ajuste por descuadre
     print '1'
      if (@w_tr_moneda <> @w_moneda_nacional) and (abs(@w_debito) <= 100.0) begin
       print '2'
         select @w_re_ofconta = re_ofconta
         from   cob_conta..cb_relofi
         where  re_filial  = @i_filial
         and    re_empresa = @i_filial
         and    re_ofadmin = @w_oficina

         select @w_asiento = max(asiento)
         from #asiento_prv

         select @w_asiento = @w_asiento + 1

         if @w_debito > 0 
            select @w_debito = @w_debito,
            @w_credito = 0,
            @w_debcred_s = '1'        
         else 
            select @w_debito = 0,
            @w_credito = @w_debito,
	    @w_debcred_s = '2'

         insert #asiento_prv values (
         @w_asiento,        '413525000001',      @w_re_ofconta,
         1490,              @w_credito,          @w_debito,  
         'AJC',             0,       	      0,
         @w_moneda_nacional,0,   		      @w_debcred_s,
         'L',    		 @w_ente,	      @w_banco,
         'N',	 	 0,        	      'N',
         0,	 	 0) 

         if @@error != 0 begin
            select @w_error = 710321
            select @w_rollback = 3
            select @w_anexo = 'sp_caconta_asie, Error Insertar #asiento_prv ' + @w_banco + '-' + @w_tr_tran
            close cursor_perfil_cca
            deallocate cursor_perfil_cca  
            goto ERROR1
         end
 
         /** INSERTAR EN TABLA FISICA **/

	 if not exists (select 1 from ca_asiento_contable where comprobante = @w_tr_comprobante
			and asiento = @w_asiento)
	 begin

	         insert ca_asiento_contable values (
	         @w_asiento,        '413525000001',      @w_re_ofconta, 
	         1490,              isnull(@w_credito,0),          isnull(@w_debito,0), 
	         'AJC',             0,                   0,
	         @w_moneda_nacional,0,   		      @w_debcred_s,
	         'L',               @w_ente,	      @w_banco,
	         'N',	         0,	              'N',
	         0,	         0,	              @w_tr_tran,
	         @w_tr_fecha_mov,   @w_tr_secuencial,    @w_oficina,
	         99999, @w_tr_estado, @w_tr_comprobante,@w_tr_fecha_cont) 

	         if @@error != 0 begin
	            select @w_error = 710322
	            select @w_rollback = 2
                    select @w_anexo = 'sp_caconta_asie, Error Insertar ca_asiento_contable ' + @w_banco + '-' + @w_tr_tran
	            close cursor_perfil_cca
	            deallocate cursor_perfil_cca
	            goto ERROR1
        	end
	 end
      end else begin
         select @w_error = 710324
         select @w_rollback = 2
         select @w_anexo = 'Debito: ' + convert(varchar(20),@w_tot_debito) + ' Credito: ' + convert(varchar(20),@w_tot_credito)
         goto ERROR1
      end
   end

   select @w_asiento = count(*)
   from #asiento_prv
   where debito <> 0 or credito <> 0

   select @w_num_reg = count(*)
   from #asiento_prv

   select @w_asiento = isnull(@w_asiento, 0)
   select @w_num_reg = isnull(@w_num_reg,0)

   ERROR1:
   if @w_rollback = 0 
      commit tran
   else begin
      if @w_rollback = 1 
      rollback tran

      --print 'Op.' + @w_tr_operacion + 'error en contasie.sp' + @w_error'
      select @w_anexo = 'Minuta - ' + ' ' + @w_anexo 
   
      exec sp_errorlog 
      @i_fecha     = @i_fecha, 
      @i_error     = @w_error, 
      @i_usuario   = @s_user,
      @i_tran      = 7000, 
      @i_tran_name = @w_sp_name, 
      @i_rollback  = 'N',
      @i_cuenta    = @w_banco, 
      @i_anexo     = @w_anexo

      if @w_rollback < 3
      begin

	 if not exists (select 1 from ca_asiento_contable where comprobante = @w_tr_comprobante
  	 and asiento = @w_asiento and @w_banco = operacion)
	begin
	         /** INSERTAR EN TABLA FISICA **/

	         insert ca_asiento_contable values (
	         @w_asiento,        'Cta. Error ',       @w_re_ofconta, 
	         @w_re_area,        isnull(@w_credito,0),          isnull(@w_debito,0), 
	         @w_dtr_concepto,   isnull(@w_credito_me,0),       isnull(@w_debito_me,0),         @w_dtr_moneda,     @w_dtr_cotizacion,   @w_debcred_s,
	         @w_moneda_cont,    @w_ente,		 @w_banco,
		 @w_con_iva,	    @w_valor_iva,	 @w_con_rete,
		 @w_valor_rete,	    @w_valor_base,	 @w_tr_tran,
	         @w_tr_fecha_mov,   @w_tr_secuencial,	 @w_oficina,
		 @w_dtr_codvalor,   @w_tr_estado,	 @w_tr_comprobante,
	 	 @w_tr_fecha_cont)

	 	 /*** INSERTAR EN LA TABLA PARA COBIS MINUTA ***/
/** PARCHADO HASTA CUANDO SE DECIDA UTILIZAR - JCQ - 10/07/2002 **/
/**
		 insert into cob_minuta..mp_temp_aplicativo values(
		 7, 			'Cta. Error ', 	@w_re_ofconta, 	
		 @i_fecha, 		@w_dtr_moneda,		isnull(@w_debito,0), 	
	         'E',			isnull(@w_debito_me,0), @w_dtr_cotizacion,
		 @w_re_area,		@w_banco,		@w_tran_minuta,
		 @w_dtr_concepto,	@w_oficina,		@w_re_area,
		 @w_ente,		@w_comprobante,		@w_tr_estado,
		 'N'
		 )
**/
	 end
      end

   end

   fetch cursor_tran_prv into
   @w_of_origen,         @w_of_destino,     @w_tr_toperacion, 
   @w_tr_tran,           @w_tr_secuencial,  @w_tr_operacion,
   @w_tr_secuencial_ref, @w_tr_usuario,     @w_tr_gerente,
   @w_tr_fecha_mov,	 @w_tr_moneda,	    @w_tr_estado,
   @w_tr_comprobante,    @w_tr_fecha_cont,  @w_tipogar,
   @w_reestructurado,    @w_calificacion


end --end while cursor transacciones

close cursor_tran_prv
deallocate cursor_tran_prv

return 0

ERROR:
print 'Error al salir de contasie.sp -' + cast(@w_tr_operacion as varchar)
return @w_error

go

