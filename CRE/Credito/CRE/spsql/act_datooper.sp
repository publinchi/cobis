/************************************************************************/
/*  Archivo:                act_datooper.sp                             */
/*  Stored procedure:       sp_act_datooper                             */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jose Ortiz                                  */
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
/*  23/04/19          Jose Ortiz       Emision Inicial                  */
/* **********************************************************************/
use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_act_datooper' and type = 'P')
   drop proc sp_act_datooper
go



create proc sp_act_datooper(
   @i_fecha			 datetime,	
   @i_numero_operacion           int,
   @i_numero_operacion_banco     varchar(24),
   @i_codigo_producto            tinyint,
   @i_tasa                       float = 0, 	--SBU  cambios consolidador
   @i_periodicidad               smallint,
   @i_fecha_vencimiento          datetime,
   @i_dias_vto_div               int = 0,
   @i_fecha_vto_div              datetime = null,
   @i_reestructuracion		 char(1) = 'N',
   @i_fecha_reest                datetime = null,
   @i_num_cuota_reest		 smallint = 0,
   @i_no_renovacion              int = 0,
   @i_fecha_prox_vto             datetime = null,
   @i_saldo_prox_vto             money = null,
   @i_saldo_cap         	 money = null,
   @i_saldo_int         	 money = null,
   @i_saldo_otros       	 money = null,
   @i_saldo_int_contingente      money = null,
   @i_estado_contable            tinyint = null,
   @i_estado_terminos            char(1) = ' ',
   @i_calificacion		 varchar(10) = null,
   @i_periodicidad_cuota         smallint    = null,   
   @i_edad_mora                  int         = null,  
   @i_valor_mora                 money       = null,  
   @i_fecha_pago                 datetime    = null,  
   @i_valor_cuota                money       = null,  
   @i_cuotas_pag                 smallint    = null,  
   @i_estado_cartera             tinyint     = null,  
   @i_dias_plazo                 int         = 0,
   @i_num_cuotaven		 smallint    = null,	--SBU  20/mar/2001
   @i_saldo_cuotaven 		 money       = null,
   @i_admisible                  char(1)     = null,   --PGA 18abr2001
   @i_num_cuotas                 smallint    = null,
   @i_tipo_bloqueo		 char(1) = null,
   @i_fecha_bloqueo		 datetime = null,
   @i_valor_ult_pago		 money = null, 
   @i_tipo_operacion             varchar(10) = null,	--SBU 19/dic/2001
   @i_codigo_cliente             int = null,
   @i_oficina                    smallint = null,
   @i_moneda                     tinyint = null,
   @i_monto                      money = null,
   @i_modalidad                  char(1) = ' ',
   @i_fecha_concesion            datetime = null,
   @i_codigo_destino             varchar(10) = null,--CEX no tiene 
   @i_clase_cartera              varchar(10) = null,--CEX no tiene
   @i_codigo_geografico          int = null,
   @i_estado_desembolso          char(1) = ' ',
   @i_linea_credito		 varchar(24) = null,	--SBU: 02/jul/2000
   @i_gerente			 smallint    = null,	--ZR
   @i_fecha_castigo		 datetime  = null,    --SBU 20/feb/2002 circular 50
   @i_num_acta			 varchar(24) = null,	
   @i_gracia_cap		 smallint = null,
   @i_gracia_int		 smallint = null,
   @i_probabilidad_default	 float       = null,
   @i_nat_reest			 catalogo    = null,
   @i_num_reest			 tinyint     = null,
   @i_acta_cas			 catalogo    = null,
   @i_capsusxcor                 money       = null,
   @i_intsusxcor                 money       = null
)
as

declare 
   @w_sp_name       	varchar(15),
   @w_error         	int,
   @w_return            int,
   @w_mensaje           varchar(200),
   @w_saldo 		money,
   @w_tipo_operacion	varchar(10),	--SBU cambios consolidador 
   @w_codigo_cliente    int,
   @w_oficina           smallint,
   @w_sucursal		smallint,
   @w_regional		smallint,
   @w_moneda		tinyint,
   @w_monto		money,
   @w_modalidad		char(1),
   @w_fecha_concesion	datetime,
   @w_codigo_destino	varchar(10),
   @w_clase_cartera	varchar(10),
   @w_codigo_geografico int,
   @w_departamento	smallint,
   @w_tipo_garantias	varchar(10),
   @w_valor_garantias	money,
   @w_estado_desembolso char(1),
   @w_calif_reest	catalogo,
   @w_reportado		char(1),
   @w_linea_credito	varchar(24),
   @w_fecha_reest	datetime,
   @w_freest_ant	datetime,
   @w_gerente		smallint,
   @w_tipo_tarjeta	char(1),
   @w_clase_tarjeta	varchar(6),
   @w_fecha_cambio	datetime,
   @w_ciclo_fact	datetime,
   @w_cod_suspenso	tinyint,
   @w_suspenso		char(1),
   @w_suspenso_ant	char(1),
   @w_def_moneda	tinyint,
   @w_estado_operacion  tinyint,
   @w_situacion_cliente catalogo,
   @w_prov_cap		money,
   @w_prov_int		money,
   @w_prov_cxc		money,
   @w_califica          varchar(30),
   @w_anulado		tinyint, 
   @w_existe		tinyint,
   @w_admisible		char(1),
   @w_cobranza          varchar(10),
   @w_tab_clase         smallint,
   @w_resp              tinyint,
   @w_clase_ant		catalogo,
   @w_cliente_ant	int,
   @w_numoper_ant	int,
   @w_reest_ant		char(1),
   @w_subtipo		char(1),
   @w_sit_castigo	catalogo,
   @w_sit_cliente 	catalogo,
   @w_cancelado         tinyint, --emg compilacion
   @w_castigado		tinyint,
   @w_rowcount          int


select @w_sp_name = 'sp_act_datooper'

select @w_califica = pa_char
from cobis..cl_parametro
where pa_nemonico = 'CALIF'
and pa_producto = 'CRE'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0
begin
   /* No existe valor de parametro */
   exec cobis..sp_cerror
   @t_from  = @w_sp_name,
   @i_num   = 2110278
   return 2110278
end


if @w_califica = 'I'
begin
   select @w_error = 2101129
   goto ERROR
end   

-- Estados de operaciones
select @w_anulado = 5,
       @w_cancelado = 4,
       @w_castigado = 3

--Codigos de estado de suspension en Cartera      
select @w_cod_suspenso = pa_tinyint
from cobis..cl_parametro 
where pa_nemonico = 'ESTRES' 
and pa_producto = 'CRE'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0
begin
   /* No existe valor de parametro */
   exec cobis..sp_cerror
   @t_from  = @w_sp_name,
   @i_num   = 2110279
   return 2110279
end


--Codigo de la moneda local
select @w_def_moneda = pa_tinyint
from cobis..cl_parametro 
where pa_nemonico = 'MLOCR' 
and pa_producto = 'CRE'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted


if @w_rowcount = 0
begin
   /* No existe valor de parametro */
   exec cobis..sp_cerror
   @t_from  = @w_sp_name,
   @i_num   = 2110280
   return 2110280
end

--Situacion de castigo
select @w_sit_castigo = pa_char
from cobis..cl_parametro 
where pa_nemonico = 'SITCS' 
and pa_producto = 'CRE'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted


if @w_rowcount = 0
begin
   /* No existe valor de parametro */
   exec cobis..sp_cerror
   @t_from  = @w_sp_name,
   @i_num   = 2110281
   return 2110281
end

select @w_saldo = @i_saldo_cap + @i_saldo_int + @i_saldo_otros + @i_saldo_int_contingente

select @w_tipo_operacion    = do_tipo_operacion,
       @w_codigo_cliente    = do_codigo_cliente,
       @w_oficina           = do_oficina,
       @w_sucursal	    = do_sucursal,
       @w_regional	    = convert(int,do_regional),
       @w_moneda	    = do_moneda,
       @w_monto		    = do_monto,
       @w_modalidad	    = do_modalidad,
       @w_fecha_concesion   = do_fecha_concesion,
       @w_fecha_reest	    = do_fecha_reest,
       @w_codigo_destino    = do_codigo_destino,
       @w_clase_cartera     = do_clase_cartera,
       @w_codigo_geografico = do_codigo_geografico,
       @w_departamento	    = do_departamento,
       @w_tipo_garantias    = do_tipo_garantias,
       @w_valor_garantias   = do_valor_garantias,
       @w_estado_desembolso = do_estado_desembolso,
       @w_calif_reest	    = do_calif_reest,
       @w_reportado	    = do_reportado,
       @w_linea_credito	    = do_linea_credito,
       @w_suspenso_ant	    = do_suspenso,
       @w_freest_ant	    = do_freest_ant,
       @w_gerente	    = do_gerente,
       @w_tipo_tarjeta	    = do_tipo_tarjeta,
       @w_clase_tarjeta	    = do_clase_tarjeta,
       @w_fecha_cambio	    = do_fecha_cambio,
       @w_ciclo_fact	    = do_ciclo_fact
from cr_dato_operacion
where do_numero_operacion = @i_numero_operacion
and  do_codigo_producto = @i_codigo_producto
and do_fecha = @i_fecha
and do_tipo_reg = 'M'

if @@rowcount = 0 
begin
   select @w_existe = 0
end
else
begin
   select @w_existe = 1
end


if @w_existe = 0 
begin

   if exists (select 1
              from cr_dato_operacion
	      where do_numero_operacion = @i_numero_operacion
	      and  do_codigo_producto = @i_codigo_producto
	      and do_fecha < @i_fecha
              and do_tipo_reg = 'M')
   begin
      return 0
   end
   else
   begin
      if (@i_tipo_operacion is NULL or
          @i_codigo_cliente is NULL or
          @i_oficina is NULL or
          @i_moneda is NULL or
          @i_monto is NULL or
          @i_modalidad is NULL or
          @i_fecha_concesion is NULL)
      begin
         /* CAMPOS NOT NULL CON VALORES NULOS */
         select @w_error = 2101001,
                @w_mensaje = null

         goto ERROR
      end

      select @w_tipo_operacion    = @i_tipo_operacion,
             @w_codigo_cliente    = @i_codigo_cliente,
             @w_oficina           = @i_oficina,
             @w_moneda	          = @i_moneda,
             @w_monto	          = @i_monto,
             @w_modalidad	  = @i_modalidad,
             @w_fecha_concesion   = @i_fecha_concesion,
             @w_codigo_destino    = @i_codigo_destino,
             @w_clase_cartera     = @i_clase_cartera,
             @w_codigo_geografico = @i_codigo_geografico,
             @w_estado_desembolso = @i_estado_desembolso,
             @w_linea_credito     = @i_linea_credito,
             @w_gerente	          = @i_gerente,
             @w_calif_reest       = null,
             @w_reportado	  = null,
             @w_suspenso_ant      = null,
             @w_freest_ant	  = null,
             @w_tipo_tarjeta      = null,
             @w_clase_tarjeta     = null,
             @w_fecha_cambio      = null,
             @w_ciclo_fact	  = null,
             @w_fecha_reest       = null

      if @w_codigo_destino is null
      begin
         select @w_codigo_destino = tr_destino
         from cr_tramite 
         where tr_numero_op_banco = @i_numero_operacion_banco
      end

      if @w_codigo_geografico is null
      begin
         select @w_codigo_geografico = tr_ciudad_destino 
         from cr_tramite 
         where tr_numero_op_banco = @i_numero_operacion_banco
      end

      if @w_clase_cartera is null
      begin
         select tr_clase 
         from cr_tramite 
         where tr_numero_op_banco = @i_numero_operacion_banco
      end

      if @w_clase_cartera is null
      begin
	   exec @w_return = cob_credito..sp_clasif_cartera
	   @i_toperacion = @w_tipo_operacion,
	   @i_moneda = @w_moneda,
	   @i_salida = 'S',
	   @i_monto = @w_monto,
	   @i_tipo = 'O',
	   @o_clase_cartera = @w_clase_cartera out

	   if @w_return <> 0
	     return @w_return
      end

      select @w_tab_clase = codigo
      from cobis..cl_tabla
      where tabla = 'cr_clase_cartera'
      set transaction isolation level read uncommitted

      select @w_resp = 1
      from cobis..cl_catalogo
      where tabla = @w_tab_clase
      and codigo = @w_clase_cartera
      select @w_rowcount = @@rowcount
      set transaction isolation level read uncommitted

      if @w_rowcount = 0
      begin
         select @w_mensaje = 'Error, clase de cartera no existe => No.Operacion: ' + @i_numero_operacion_banco +
                ' Producto: ' + convert(varchar(10),@i_codigo_producto) + ' Clase: ' +  @w_clase_cartera

         select @w_error = 2101159,
                @w_mensaje = @w_mensaje

         goto ERROR
      end

      select @w_codigo_destino = isnull(@w_codigo_destino, ' '),
             @w_estado_desembolso = isnull(@w_estado_desembolso, 'N')

      select
         @w_regional = isnull(b.of_regional, 1),  --XSA Oficina Matriz
         @w_sucursal = isnull(a.of_sucursal, a.of_oficina),
         @w_codigo_geografico = isnull(@w_codigo_geografico,a.of_ciudad)
      from cobis..cl_oficina a, cobis..cl_oficina b
      where a.of_oficina = @w_oficina
      and   b.of_oficina = isnull(a.of_sucursal, a.of_oficina)
      set transaction isolation level read uncommitted

      if @w_sucursal is null
      begin
         select @w_mensaje = 'Error, No existe oficina => No.Operacion: ' + @i_numero_operacion_banco +
                ' Producto: ' + convert(varchar(10),@i_codigo_producto) + ' Oficina: ' + 
                convert(varchar(10),@w_oficina)

         select @w_error = 2101005,
                @w_mensaje = @w_mensaje

         goto ERROR         
      end

      select @w_departamento = ci_provincia
      from   cobis..cl_ciudad
      where  ci_ciudad = @w_codigo_geografico
      set transaction isolation level read uncommitted

      if @w_departamento is null 
      begin
         select @w_mensaje = 'Error, No existe ciudad => No.Operacion: ' + @i_numero_operacion_banco +
                ' Producto: ' + convert(varchar(10),@i_codigo_producto) + ' Ciudad: ' +
                convert(varchar(10),@w_codigo_geografico)

         select @w_error = 2101005,
                @w_mensaje = @w_mensaje

         goto ERROR         
      end

      if @i_linea_credito = ' '
         select @i_linea_credito = null

      if @i_linea_credito is not null
      begin     
         select @w_resp = 1
         from cr_linea
         where li_num_banco = @i_linea_credito
         and  (li_estado <> 'A' and li_estado is not null)

         if @@rowcount = 0
         begin
            select @w_mensaje = 'Error, No existe cupo de credito => No.Operacion: ' + @i_numero_operacion_banco +
                   ' Producto: ' + convert(varchar(10),@i_codigo_producto) + ' Cupo: ' +
                   @i_linea_credito

            select @w_error = 2101010,
                   @w_mensaje = @w_mensaje

            goto ERROR         
         end
      end

      exec @w_return = cob_custodia..sp_gar_admisible
           @i_banco = @i_numero_operacion_banco,
           @o_admisible = @w_admisible  out,
           @o_valor = @w_valor_garantias  out

      if @w_return <> 0
         return @w_return

      select @w_valor_garantias = isnull(@w_valor_garantias,0)
 
      if @w_admisible = 'S'
         select @w_tipo_garantias = 'I'		--SBU 20/feb/2002   circular 50
      else
         select @w_tipo_garantias = 'O'
   end
end


select @w_suspenso  =  null,
       @w_cobranza  =  null

-- Operaciones de Cartera en moneda extranjera
if  (@i_codigo_producto = 7)   and   (@w_moneda   <>  @w_def_moneda)
begin          
    select  @w_estado_operacion  = op_estado                      
    from   cob_cartera..ca_operacion
    where  op_banco  =  @i_numero_operacion_banco           

    if  @w_estado_operacion  =  @w_cod_suspenso
       select   @w_suspenso  =  'S'
end      

select @i_fecha_reest = isnull(@i_fecha_reest, @w_fecha_reest)

if @i_reestructuracion = 'S'
     if (datediff(dd, @i_fecha_reest,@w_freest_ant) > 0 ) or (@w_freest_ant is null)
        select @w_calif_reest = @i_calificacion,
               @w_freest_ant  = @i_fecha_reest

--SBU 25/ene/2002
select @w_cobranza = co_cobranza
from cr_cobranza
where co_cliente = @w_codigo_cliente


begin tran
   if @w_existe = 1
   begin
      select @w_clase_ant = null,
             @w_cliente_ant = null,
             @w_reest_ant = null

      select @w_clase_ant = do_clase_cartera,
	     @w_cliente_ant = do_codigo_cliente,
             @w_reest_ant = do_reestructuracion
      from cr_dato_operacion
      where do_tipo_reg = 'M'
      and do_numero_operacion = @i_numero_operacion
      and do_codigo_producto = @i_codigo_producto

      select @w_clase_ant = isnull(@w_clase_ant,' ')

      if (@w_clase_ant <> @w_clase_cartera) and (@w_clase_ant <> ' ')
      begin
         select @w_mensaje = 'Error, Clase de cartera distinta => No.Operacion: ' + @i_numero_operacion_banco +
                ' Producto: ' + convert(varchar(10),@i_codigo_producto) + ' Clase.Ant: ' +
                @w_clase_ant + ' Clase.Act: ' + @w_clase_cartera

         select @w_error = 2101158,
                @w_mensaje = @w_mensaje

         goto ERROR         
      end


      if (@w_reest_ant = 'S') and (@w_reest_ant <> @i_reestructuracion)
      begin
         select @w_mensaje = 'Error, Estaba marcada como reestructurada => No.Operacion: ' + @i_numero_operacion_banco +
                ' Producto: ' + convert(varchar(10),@i_codigo_producto) 

         select @w_error = 2101162,
                @w_mensaje = @w_mensaje

         goto ERROR         
      end


      if (@w_cliente_ant <> @w_codigo_cliente) and (@w_cliente_ant is not null)
      begin
         select @w_resp = 1

         if @i_codigo_producto = 7
         begin
            select @w_subtipo = tr_subtipo
            from cr_tramite, cob_cartera..ca_operacion
            where tr_tramite = op_tramite
            and  tr_numero_op_banco = @i_numero_operacion_banco
    
            if @w_subtipo = 'F'
               select @w_resp = 0        
         end   

         if @w_resp = 1
         begin        
            select @w_mensaje = 'Error, Cliente distinto => No.Operacion: ' + @i_numero_operacion_banco +
                   ' Producto: ' + convert(varchar(10),@i_codigo_producto) + ' Cliente.Ant: ' +
                   convert(varchar(10),@w_cliente_ant) + ' Cliente.Act: ' + convert(varchar(10),@w_codigo_cliente)

            select @w_error = 2101155,
                   @w_mensaje = @w_mensaje

            goto ERROR         
         end
      end


      delete cr_dato_operacion
      where do_numero_operacion = @i_numero_operacion
      and   do_codigo_producto = @i_codigo_producto
      and  do_fecha = @i_fecha
      and  do_tipo_reg = 'M'

      if @@error != 0 
      begin
         select @w_error = 2107001,
                @w_mensaje = null

         goto ERROR
      end
   end

   select @w_sit_cliente = en_situacion_cliente
   from cobis..cl_ente
   where en_ente = @w_codigo_cliente
   set transaction isolation level read uncommitted

   if (@w_sit_cliente <> @w_sit_castigo) and (@i_estado_contable = @w_castigado)
   begin
      select @w_error = 2101165,
             @w_mensaje = null

      goto ERROR
   end

   select 	@i_acta_cas      = cn_acta_cas,
	        @i_fecha_castigo = cn_fecha_cas
   from 	cr_concordato
   where 	cn_cliente = @i_codigo_cliente 


   if (@i_estado_contable = @w_castigado) and (@i_fecha_castigo is null)
   begin
      select @w_error = 2101168,
             @w_mensaje = null

      goto ERROR
   end


   if (@i_estado_contable = @w_cancelado) and (@w_saldo > 0)
   begin
      select @w_error = 2101167,
             @w_mensaje = null

      goto ERROR         
   end

   if exists (select 1 
              from cr_calificacion_provision
              where cp_operacion = @i_numero_operacion
              and cp_producto = @i_codigo_producto)
   begin
      select @w_resp = 1

      if @i_estado_contable = @w_anulado
      begin
         select @i_saldo_prox_vto = 0,
                @i_saldo_cap = 0,
                @i_saldo_int = 0,
                @i_saldo_otros = 0,
                @i_saldo_int_contingente = 0,
                @w_saldo = 0,
                @i_valor_mora = 0,
                @i_estado_contable = 4

         insert into cr_tmp_concepto
         select @i_fecha, cp_producto, cp_operacion, 
                cp_num_banco, cp_concepto,0
         from cr_calificacion_provision
         where cp_operacion = @i_numero_operacion
         and cp_producto = @i_codigo_producto

         if @@error != 0 
         begin
            select @w_error = 2103001,
                   @w_mensaje = 'Error en insercion de conceptos operacion anulada'

            goto ERROR
         end
      end
   end
   else
      select @w_resp = 0


   if (@i_estado_contable <> @w_anulado) or (@w_resp = 1)
   begin
      insert into cr_dato_operacion (
      do_fecha,  do_tipo_reg,  do_numero_operacion,  do_numero_operacion_banco,
      do_tipo_operacion,  do_codigo_producto,  do_codigo_cliente,  do_oficina,
      do_sucursal,  do_regional,  do_moneda,  do_monto,
      do_tasa,  do_periodicidad,  do_modalidad,   do_fecha_concesion, 
      do_fecha_vencimiento, do_dias_vto_div, do_fecha_vto_div, do_reestructuracion,
      do_fecha_reest,   do_num_cuota_reest,   do_no_renovacion,   do_codigo_destino,
      do_clase_cartera,  do_codigo_geografico,  do_departamento,   do_tipo_garantias,
      do_valor_garantias,  do_fecha_prox_vto,  do_saldo_prox_vto,   do_saldo_cap,
      do_saldo_int,  do_saldo_otros,  do_saldo_int_contingente,  do_saldo,
      do_estado_contable,  do_estado_desembolso,  do_estado_terminos,  do_calificacion,
      do_calif_reest,  do_reportado,   do_linea_credito,   do_suspenso,
      do_suspenso_ant,   do_periodicidad_cuota,   do_edad_mora,   do_valor_mora,
      do_fecha_pago,   do_valor_cuota,  do_cuotas_pag,  do_estado_cartera,
      do_plazo_dias,  do_freest_ant,  do_gerente,  do_num_cuotaven,
      do_saldo_cuotaven,  do_admisible,  do_num_cuotas,   do_tipo_tarjeta,
      do_clase_tarjeta,  do_tipo_bloqueo,  do_fecha_bloqueo,  do_fecha_cambio,
      do_ciclo_fact,   do_valor_ult_pago,  do_fecha_castigo,  do_num_acta,    --SBU 20/feb/2002 circular 50
      do_gracia_cap,   do_gracia_int, do_probabilidad_default, do_nat_reest,
      do_num_reest, do_acta_cas, do_capsusxcor,do_intsusxcor,
      do_moneda_op)
      values (
      @i_fecha,  'M',  @i_numero_operacion,  @i_numero_operacion_banco,
      @w_tipo_operacion,  @i_codigo_producto,  @w_codigo_cliente,  @w_oficina,
      @w_sucursal,  convert(varchar(10),@w_regional),  @w_moneda,  @w_monto,
      @i_tasa,  @i_periodicidad,  @w_modalidad,   @w_fecha_concesion, 
      @i_fecha_vencimiento, @i_dias_vto_div, @i_fecha_vto_div, @i_reestructuracion,
      @i_fecha_reest,   @i_num_cuota_reest,   @i_no_renovacion,   @w_codigo_destino,
      @w_clase_cartera,  @w_codigo_geografico,  @w_departamento,   @w_tipo_garantias,
      @w_valor_garantias,  @i_fecha_prox_vto,  @i_saldo_prox_vto,   @i_saldo_cap,
      @i_saldo_int,  @i_saldo_otros,  @i_saldo_int_contingente,  @w_saldo,
      @i_estado_contable,  @w_estado_desembolso,  @i_estado_terminos,  @i_calificacion,
      @w_calif_reest,  @w_reportado,   @w_linea_credito,   @w_suspenso,
      @w_suspenso_ant,   @i_periodicidad_cuota,   @i_edad_mora,   @i_valor_mora,
      @i_fecha_pago,   @i_valor_cuota,  @i_cuotas_pag,  @i_estado_cartera,
      @i_dias_plazo,  @w_freest_ant,  @w_gerente,  @i_num_cuotaven,
      @i_saldo_cuotaven,  @i_admisible,  @i_num_cuotas,   @w_tipo_tarjeta,
      @w_clase_tarjeta,  @i_tipo_bloqueo,  @i_fecha_bloqueo,  @w_fecha_cambio,
      @w_ciclo_fact,   @i_valor_ult_pago,  @i_fecha_castigo,  @i_num_acta,
      @i_gracia_cap,   @i_gracia_int, @i_probabilidad_default, @i_nat_reest,
      @i_num_reest, @i_acta_cas, @i_capsusxcor, @i_intsusxcor,
      @w_moneda)

      if @@error != 0 
      begin
         select @w_error = 2103018,
                @w_mensaje = null

         goto ERROR
      end

   end
   else
   begin
      if exists (select 1
                 from cob_compensacion..cr_dato_operacion_rep
                 where do_numero_operacion = @i_numero_operacion
                 and  do_codigo_producto = @i_codigo_producto
                 and do_fecha = @i_fecha
		 and do_tipo_reg = 'D')
      begin
         delete cob_compensacion..cr_dato_operacion_rep
         where do_numero_operacion = @i_numero_operacion
         and  do_codigo_producto = @i_codigo_producto
         and do_fecha = @i_fecha
         and do_tipo_reg = 'D'

         if @@error != 0 
	 begin
            select @w_error = 2107019,
                   @w_mensaje = null

            goto ERROR
         end
      end               


      if @w_cobranza is not null
      begin 
         if exists (select 1
                    from cr_operacion_cobranza
                    where oc_num_operacion = @i_numero_operacion_banco
                    and  oc_codprod = @i_codigo_producto
                    and  oc_cobranza = @w_cobranza)

         begin
            delete cr_operacion_cobranza
            where oc_num_operacion = @i_numero_operacion_banco
            and  oc_codprod = @i_codigo_producto
            and oc_cobranza = @w_cobranza

            if @@error != 0 
	    begin
               select @w_error = 2107022,
                      @w_mensaje = null

               goto ERROR
            end
         end

         if exists (select 1
                    from cr_asignacion_cob
                    where ac_num_obligacion = @i_numero_operacion
                    and  ac_producto = @i_codigo_producto
                    and  ac_cod_cobranza = @w_cobranza)

         begin
            delete cr_asignacion_cob
            where ac_num_obligacion = @i_numero_operacion
            and  ac_producto = @i_codigo_producto
            and ac_cod_cobranza = @w_cobranza

            if @@error != 0 
	    begin
               select @w_error = 2107023,
                      @w_mensaje = null

               goto ERROR
            end
         end
      end               
   end

commit tran
 
return 0
ERROR:    /* RUTINA QUE DISPARA sp_cerror DADO EL CODIGO DEL ERROR */
   while @@trancount > 0 rollback
   exec cobis..sp_cerror             
   @t_from  = @w_sp_name, 
   @i_num   = @w_error
   return @w_error 

GO
