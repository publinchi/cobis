/************************************************************************/
/*		Nombre Fisico:			sadetconi.sp							*/
/*		Nombre Logico:			sp_saldos_det_conta_int					*/
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Marcelo Poveda		                	*/
/*      Fecha de escritura:     Septiembre 2001                         */
/************************************************************************/
/*                              IMPORTANTE                              */
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
/*                              PROPOSITO                               */
/*      Consulta los saldos diarios de las obligaciones de Cartera y	*/
/*      los presenta en sus cuentas contables							*/
/************************************************************************/
/*                            MODIFICACIONES                            */
/*   FECHA                  AUTOR                  RAZON                */
/*    06/06/2023	 M. Cordova		  Cambio variable @w_calificacion	*/
/*									  de char(1) a catalogo				*/
/************************************************************************/


/*
drop table ca_saldos_contables_tmp
go*/

/*
create table ca_saldos_contables_tmp(
sc_fecha_proceso	datetime	null,
sc_operacion		int		null,
sc_banco		cuenta		null,
sc_toperacion		catalogo	null,
sc_moneda		smallint	null,
sc_cliente		int		null,
sc_oficina		int		null,
sc_sector		char(1)		null,
sc_gerente		int		null,
sc_nombre		descripcion	null,
sc_concepto		catalogo	null,
sc_estado		tinyint		null,
sc_periodo		tinyint		null,
sc_cuenta		cuenta		null,
sc_afectacion		tinyint		null,
sc_monto		money		null,
sc_debito		money		null,
sc_credito		money		null,
sc_area			smallint	null
)*/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_saldos_det_conta_int')
   drop proc sp_saldos_det_conta_int
go

create proc sp_saldos_det_conta_int
@i_filial		smallint = 1,
@i_fecha		datetime = null,
@i_debug		char(1)  = 'N',
@i_operacion		int
as
declare
@w_return		int,
@w_error		int,
@w_mensaje		descripcion,
@w_sp_name		varchar(30),
@w_fecha_proceso	datetime,
@w_op_operacion		int,
@w_op_banco		cuenta,
@w_op_toperacion	catalogo,
@w_op_moneda		int,
@w_op_cliente		int,
@w_op_oficina		int,
@w_op_sector		char(1),
@w_op_oficial		int,
@w_op_nombre		descripcion,
@w_op_clase		char(1),
@w_op_tipo_gar		char(1),
@w_op_reestructuracion	char(1),
@w_op_tipo_linea	varchar(10),
@w_am_concepto		catalogo,
@w_am_estado		tinyint,
@w_am_periodo		tinyint,
@w_am_acumulado		money,
@w_am_pagado		money,
@w_cuenta		varchar(60),
@w_afectacion		char(1),
@w_monto		money,
@w_area			int,
@w_est_novigente	tinyint,
@w_est_cancelado	tinyint,
@w_moneda_nacional	int,
@w_num_dec_mn		tinyint,
@w_di_fecha_ven		datetime,
@w_saldo		money,
@w_codigo_rubro		int,
@w_codvalor		int,
@w_dp_cuenta		varchar(60),
@w_dp_area		char(1),
@w_dp_constante		char(1),
@w_dp_debcred		char(1),
@w_dp_origen_dest	char(1),
@w_moneda_cont		char(1),
@w_debcred		int,
@w_cuenta_final		varchar(60),
@w_cuenta_aux		varchar(60),
@w_pos			tinyint,
@w_trama		varchar(30),
@w_ascii		int,
@w_resultado		varchar(60),
@w_clave		varchar(30),
@w_dt_categoria		catalogo,
@w_nat_juridica		char(1),
@w_tipo_compania	catalogo,
@w_debito		money,
@w_credito		money,
@w_monto_mn		money,
@w_tipo_cambio_mn	money,
@w_dtr_estado		tinyint,
@w_perfil		catalogo,
@w_forma_pago		char(1),
@w_calificacion		catalogo,	--RRB Circular 50 03/19/2002
@w_cla_vivi		char(1),	--RRB Circular 50 03/19/2002
@w_cla_micr		char(1),	--RRB Circular 50 03/19/2002
@w_cla_cons		char(1),	--RRB Circular 50 03/19/2002
@w_cla_come		char(1),	--RRB Circular 50 03/19/2002
@w_reestructurado	char(1),
@w_DESPRV		int,
@w_acumulado 		money,
@w_cuota		money,
@w_rowcount             int



/** INICIALIZACION DE VARIABLES **/
select @w_sp_name = 'sp_saldos_det_conta_int'

select @w_est_novigente = 0,
@w_est_cancelado = 3

/** SELECCIONAR FECHA DE PROCESO **/
if @i_fecha is null
   select @i_fecha = fc_fecha_cierre
   from   cobis..ba_fecha_cierre
   where  fc_producto = 7

/** MONEDA NACIONAL **/
select @w_moneda_nacional = pa_tinyint
from cobis..cl_parametro
where pa_producto = 'ADM'
and   pa_nemonico = 'MLO'
set transaction isolation level read uncommitted

/** MANEJO DE DECIMALES MONEDA NACIONAL**/
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

/** DATOS DE OPERACION **/
declare cursor_operacion cursor for
select 
op_operacion, op_banco,    op_toperacion,
op_moneda,    op_cliente,  op_oficina,
op_sector,    op_oficial,  op_nombre,
op_clase,     isnull(op_gar_admisible,'N'),
isnull(op_reestructuracion,'N'),op_tipo_linea,
op_calificacion
from ca_operacion
where op_estado not in (0,3,4,6,98,99)
and   op_fecha_ult_proceso <= @i_fecha
--and   op_fecha_liq < @i_fecha -- ES TEMPORAL.
--and   op_validacion is null
and op_operacion = @i_operacion
for read only

open cursor_operacion

fetch cursor_operacion into
@w_op_operacion, @w_op_banco,    @w_op_toperacion,
@w_op_moneda,    @w_op_cliente,  @w_op_oficina,
@w_op_sector,    @w_op_oficial,  @w_op_nombre,
@w_op_clase,     @w_op_tipo_gar, @w_op_reestructuracion,
@w_op_tipo_linea, @w_calificacion


while @@fetch_status = 0 begin

   select @w_perfil = null
   
   /** SELECCION TIPO DE GARANTIA **/
   if @w_op_tipo_gar = 'S' --Admisible
      select @w_op_tipo_gar = 'I'
   else
      select @w_op_tipo_gar = 'O'


   /** SELECCION REESTRUCTURADO 				--- RRB **/
   if @w_op_reestructuracion is null 
      select @w_op_reestructuracion = 'N'

   if @w_op_reestructuracion = 'S' 
      select @w_reestructurado = 'R'
   else
      select @w_reestructurado = 'N'

   /** SELECCION CATEGORIA DE LINEA DE CREDITO **/
   select @w_dt_categoria = dt_categoria
   from   ca_default_toperacion
   where  dt_toperacion = @w_op_toperacion
   and    dt_moneda = @w_op_moneda

   /** SELECCION DE LA NATURALEZA JURIDICA DE CLIENTE **/
   select @w_tipo_compania = isnull(c_tipo_compania,'PA')
   from cobis..cl_ente
   where en_ente = @w_op_cliente
   set transaction isolation level read uncommitted

   select @w_nat_juridica = nj_tipo
   from cobis..cl_nat_jur
   where nj_codigo = @w_tipo_compania
   set transaction isolation level read uncommitted

   /** VERIFICACION DE LA CALIFICACION **/
   if @w_calificacion not in 
      (select codigo
       from cobis..cl_catalogo
       where tabla = (select codigo from cobis..cl_tabla where tabla =  'cr_calificacion' )
      )
      or @w_calificacion is null
      select @w_calificacion = 'A'

   select @w_nat_juridica = isnull(@w_nat_juridica, 'P')

   /** CURSOR DE DATOS DE LA TABLA DE AMORTIZACION **/

   declare cursor_amortizacion cursor for  
   select am_concepto, am_estado, am_acumulado, am_cuota,
          (abs(sum(am_cuota - am_acumulado)) + sum(am_cuota - am_acumulado))/2
   from   ca_amortizacion
   where  am_operacion = @w_op_operacion
   and    ((am_estado not in (0) and am_concepto in  ('INTANT', 'INTDES') ) )
   group by am_concepto, am_estado, am_acumulado, am_cuota
   order by am_concepto, am_estado, am_acumulado, am_cuota
   for read only

   open cursor_amortizacion
   
   fetch cursor_amortizacion into
   @w_am_concepto, @w_am_estado, @w_acumulado, @w_cuota, @w_saldo

   while @@fetch_status = 0 begin
   select @w_DESPRV = 1
    while 0 = 0
    begin    
      select 
	@w_dp_cuenta = '',
      	@w_dp_debcred = '',
      	@w_dp_constante = '',
      	@w_dp_area = '',
      	@w_dp_origen_dest = ''


      /* DETERMINAR PERFIL CONTABLE */

      if @w_am_concepto = 'INTANT'
      begin
         select @w_perfil = to_perfil
         from ca_trn_oper
         where to_toperacion = @w_op_toperacion
         and   to_tipo_trn = 'PRV'
	 select @w_DESPRV = 3
      end
      if @w_am_concepto = 'INTDES'      
      begin
         if @w_DESPRV = 1
         begin
           select @w_perfil = to_perfil
           from ca_trn_oper
           where to_toperacion = @w_op_toperacion
           and   to_tipo_trn = 'DES'
           select @w_saldo = @w_cuota * -1
	   select @w_DESPRV = 2
	 end
         else
         begin
           select @w_perfil = to_perfil
           from ca_trn_oper
           where to_toperacion = @w_op_toperacion
           and   to_tipo_trn = 'PRV'
           select @w_saldo = @w_acumulado
	   select @w_DESPRV = 3
         end
      end
      if @w_perfil is null
      begin
        select @w_mensaje = @w_op_toperacion + ' no tiene perfil asociado para SCO'
        select @w_error = 9999
        goto ERROR2
      end

      if @i_debug = 'S' print 'TIPO OP.-->' +  @w_op_toperacion + 'PERFIL-->' + @w_perfil + 'OPERACION-->' + @w_op_banco + 'CONCEPTO-->' + @w_am_concepto

      
      /** GENERACION DE CODIGO VALOR **/
      select @w_codigo_rubro = co_codigo
      from   ca_concepto
      where  co_concepto = @w_am_concepto
      
      select @w_codvalor = @w_codigo_rubro * 1000 + @w_am_estado * 10 

      /** SELECCION DE LA CUENTA CONTABLE **/
      declare cursor_perfil_cca cursor for
      select
      dp_cuenta,
      dp_debcred,
      dp_constante,
      dp_area,
      dp_origen_dest
      from cob_conta..cb_det_perfil 
      where dp_empresa     = @i_filial
      and   dp_producto    = 7 
      and   dp_perfil      = @w_perfil
      and   dp_codval      = @w_codvalor
      and   dp_tipo_tran   = 'S'
      for read only

      open cursor_perfil_cca

      fetch cursor_perfil_cca into
      @w_dp_cuenta, 	@w_dp_debcred, 	@w_dp_constante,
      @w_dp_area,	@w_dp_origen_dest

      while @@fetch_status = 0 begin 

      /** ENCONTRAR AREA **/  -- Modificar de acuerdo al estandar establecido en Cartera
      select @w_area = ta_area
      from   cob_conta..cb_tipo_area
      where  ta_tiparea = @w_dp_area
      and    ta_utiliza_valor = 'S'
      and    ta_producto = 7 
      set transaction isolation level read uncommitted

      if @w_dp_constante = 'L' 
         select @w_moneda_cont = 'L'
      else
         select @w_moneda_cont = 'T'

      select @w_debcred      = convert(int,@w_dp_debcred)
      select @w_cuenta_final = ''

      if @i_debug = 'S' print 'CONCEPTO--> %1! CUENTA-->' + @w_am_concepto + @w_dp_cuenta

      /** RESOLUCION DE LA CUENTA DINAMICA **/
      select @w_cuenta_aux = @w_dp_cuenta
      select @w_pos = charindex('.',@w_cuenta_aux)

      while 0 = 0 begin
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
            select @w_cuenta_aux = ""
         end

         /* CONDICION DE SALIDA DEL LAZO */
         if @w_trama = "" 
            break

         /* VERIFICAR SI LA TRAMA ES PARTE FIJA O PARAMETRO */
         select @w_ascii = ascii(substring(@w_trama,1,1))

         if @w_ascii >= 48 and @w_ascii <= 57 begin --NUMERICO,PARTE FIJA
            select @w_cuenta_final = @w_cuenta_final + @w_trama 
         end else begin  --LETRA, LA TRAMA ES UN PARAMETRO
            select 
            @w_resultado = "",
            @w_clave     = ""
            
            if charindex('CTE'  ,@w_trama)=1 select @w_clave=@w_op_clase + "." + @w_op_tipo_gar + "." + convert(varchar(10),@w_am_estado)
            if charindex('MON'  ,@w_trama)=1 select @w_clave=convert(varchar(10), @w_op_moneda)
            if charindex('COR'  ,@w_trama)=1 select @w_clave=convert(varchar(10), @w_op_cliente)
            if charindex('TLI'  ,@w_trama)=1 select @w_clave=@w_op_tipo_linea
            if charindex('TLE'  ,@w_trama)=1 select @w_clave=@w_op_tipo_linea
            if charindex('CAT'  ,@w_trama)=1 select @w_clave=@w_dt_categoria		
            if charindex('EOR'  ,@w_trama)=1 select @w_clave=@w_nat_juridica+"."+@w_reestructurado
            if charindex('TGE'  ,@w_trama)=1 select @w_clave=@w_op_tipo_gar+"."+convert(varchar(10),@w_am_estado)
            if charindex('EST'  ,@w_trama)=1 select @w_clave=convert(varchar(10),@w_am_estado)
            if charindex('CLC'  ,@w_trama)=1 select @w_clave=@w_op_clase
            if charindex('MGE'  ,@w_trama)=1 select @w_clave=convert(varchar(10), @w_op_moneda) + "." + @w_op_tipo_gar + "." + convert(varchar(10),@w_am_estado)
            if charindex('CTP'  ,@w_trama)=1 select @w_clave=@w_dt_categoria
            if charindex('CCI'  ,@w_trama)=1 select @w_clave=@w_op_clase + "." + @w_dt_categoria
	    if charindex('CCS'  ,@w_trama)=1 select @w_clave=@w_op_clase         

	    /** CIRCULAR 50 **/

    	    if charindex('CGA'  ,@w_trama)=1 select @w_clave=@w_op_clase + "." + @w_op_tipo_gar
	    if charindex('CMO'  ,@w_trama)=1 select @w_clave=@w_op_clase + "." + convert(varchar(10), @w_op_moneda)
	    if charindex('GEO'  ,@w_trama)=1 select @w_clave=@w_op_tipo_gar + "." + rtrim(@w_tipo_compania) + "." + @w_op_reestructuracion

	    if @w_op_clase in (@w_cla_cons,@w_cla_vivi) and
	       charindex('RCE'  ,@w_trama)=1 select @w_clave=@w_calificacion + "." + @w_op_clase

	    if charindex('RCI'  ,@w_trama)=1 select @w_clave=@w_calificacion + "." + @w_op_clase
	    if charindex('RCL'  ,@w_trama)=1 select @w_clave=@w_calificacion + "." + @w_op_clase
            if charindex('RGC'  ,@w_trama)=1 select @w_clave=@w_calificacion + "." + @w_op_tipo_gar + "." + @w_op_clase
	    if charindex('RIE'  ,@w_trama)=1 select @w_clave=@w_calificacion
	    if charindex('CES'  ,@w_trama)=1 select @w_clave=@w_op_clase + "." + convert(varchar(10),@w_am_estado)
	    if charindex('CESC'  ,@w_trama)=1 select @w_clave=@w_op_clase + "." + convert(varchar(10),@w_am_estado)
	    if charindex('CESI'  ,@w_trama)=1 select @w_clave=@w_op_clase + "." + convert(varchar(10),@w_am_estado)

            if @w_clave != ""  begin 
            
               select @w_resultado = re_substring
               from cob_conta..cb_relparam 
               where re_empresa   = @i_filial
               and   re_parametro = @w_trama
               and   re_clave     = @w_clave
               select @w_rowcount = @@rowcount
	       set transaction isolation level read uncommitted

               if @w_rowcount = 0 begin
                  select @w_error =  799999
                  select @w_mensaje = 'ERR: NO EXIS.CTA PARTE VAR: ' + @w_op_banco + ' ' +  @w_trama + ' ' + @w_clave
                  goto ERROR1
               end
               
               if @i_debug = 'S' 
               print 'TRAMA-->' + @w_trama + 'CLAVE-->' + @w_clave + 'RESULTADO-->'+ @w_resultado

            end 

            select @w_cuenta_final = @w_cuenta_final + @w_resultado

         end

      end --fin while 0=0

      select @w_cuenta_final = rtrim( ltrim(@w_cuenta_final) )

      select
      @w_debito         = @w_saldo*(2-@w_debcred),
      @w_credito        = @w_saldo*(@w_debcred-1)

      if @w_moneda_cont = 'L' begin 
         exec sp_conversion_moneda
         @s_date                 = @i_fecha,
         @i_opcion               = 'L',
         @i_moneda_monto	 = @w_op_moneda,
         @i_moneda_resultado	 = @w_moneda_nacional,
         @i_monto		 = @w_saldo,
         @i_fecha                = @i_fecha, --@w_tr_fecha_mov, 
         @o_monto_resultado	 = @w_monto_mn out,
         @o_tipo_cambio          = @w_tipo_cambio_mn out

         select 
         @w_debito  = round(@w_monto_mn*(2-@w_debcred),@w_num_dec_mn),
         @w_credito = round(@w_monto_mn*(@w_debcred-1),@w_num_dec_mn)
      end

      /** INSERTAR EN TABLA FISICA **/
      insert ca_saldos_contables_tmp 
      values (
      @i_fecha,         @w_op_operacion, @w_op_banco,
      @w_op_toperacion, @w_op_moneda,    @w_op_cliente,
      @w_op_oficina,    @w_dp_origen_dest,    @w_op_oficial,
      @w_op_nombre,     @w_am_concepto,  @w_am_estado,
      @w_am_periodo,    @w_cuenta_final, @w_debcred,
      @w_saldo,		@w_debito,	 @w_credito,
      @w_area)

      goto SIGUIENTE

      ERROR1:
      exec sp_errorlog 
      @i_fecha = @i_fecha, 
      @i_error = @w_error, 
      @i_usuario='CARTERA',
      @i_tran=7000, 
      @i_tran_name = @w_sp_name, 
      @i_rollback = 'N',
      @i_cuenta= @w_op_banco, 
      @i_descripcion = @w_mensaje 

      SIGUIENTE: 

      fetch cursor_perfil_cca into
      @w_dp_cuenta, 	@w_dp_debcred, 	@w_dp_constante,
      @w_dp_area,	@w_dp_origen_dest

      end

      close cursor_perfil_cca
      deallocate cursor_perfil_cca

      if @w_DESPRV = 3
         break
      end -- while

      fetch cursor_amortizacion into
      @w_am_concepto, @w_am_estado, @w_acumulado, @w_cuota, @w_saldo
   end
   close cursor_amortizacion
   deallocate cursor_amortizacion
   goto  SIGUIENTE2 

      ERROR2:
      exec sp_errorlog 
      @i_fecha = @i_fecha, 
      @i_error = @w_error, 
      @i_usuario='CARTERA',
      @i_tran=7000, 
      @i_tran_name = @w_sp_name, 
      @i_rollback = 'N',
      @i_cuenta= @w_op_banco, 
      @i_descripcion = @w_mensaje 

   SIGUIENTE2:   
   fetch cursor_operacion into
   @w_op_operacion, @w_op_banco,    @w_op_toperacion,
   @w_op_moneda,    @w_op_cliente,  @w_op_oficina,
   @w_op_sector,    @w_op_oficial,  @w_op_nombre,
   @w_op_clase,     @w_op_tipo_gar, @w_op_reestructuracion,
   @w_op_tipo_linea, @w_calificacion
end

close cursor_operacion
deallocate cursor_operacion

return 0

ERROR:
exec sp_errorlog
@i_fecha 	= @i_fecha,
@i_error 	= @w_error, 
@i_usuario	= 'CARTERA',
@i_tran		= 7000, 
@i_tran_name 	= @w_sp_name, 
@i_rollback 	= 'N',
@i_cuenta	= 'CONTABILIDAD', 
@i_descripcion  = @w_mensaje

return 1
go