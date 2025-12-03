/************************************************************************/
/*  Archivo:                tmp_datooper.sp                             */
/*  Stored procedure:       sp_tmp_datooper                             */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Geovanny Guaman                             */
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
/*  23/04/19          gguaman        Emision Inicial                    */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_tmp_datooper')
    drop proc sp_tmp_datooper
go

create proc sp_tmp_datooper(
   @i_numero_operacion           int		= null,
   @i_numero_operacion_banco     varchar(24)	= null,
   @i_tipo_operacion             varchar(10)	= null,
   @i_codigo_producto            tinyint	= null,
   @i_codigo_cliente             int		= null,
   @i_oficina                    smallint	= null,
   @i_moneda                     tinyint	= null,
   @i_monto                      money		= null,
   @i_tasa                       float 		= 0, --CEX no tiene
   @i_periodicidad               smallint 	= null,
   @i_modalidad                  char(1) 	= ' ',
   @i_fecha_concesion            datetime	= null,
   @i_fecha_vencimiento          datetime	= null,
   @i_dias_vto_div               int 		= 0,
   @i_fecha_vto_div              datetime 	= null,
   @i_reestructuracion		 char(1) 	= 'N',
   @i_fecha_reest                datetime 	= null,
   @i_num_cuota_reest		 smallint 	= 0,
   @i_no_renovacion              int 		= 0,
   @i_codigo_destino             varchar(10) 	= null,--CEX no tiene 
   @i_clase_cartera              varchar(10) 	= null,--CEX no tiene
   @i_codigo_geografico          int 		= null,
   @i_fecha_prox_vto             datetime 	= null,
   @i_saldo_prox_vto             money 		= null,
   @i_saldo_cap                  money		= null,
   @i_saldo_int                  money		= null,
   @i_saldo_otros                money		= null,
   @i_saldo_int_contingente      money		= null,
   @i_estado_contable            tinyint	= null,
   @i_estado_desembolso          char(1) 	= 'N',
   @i_estado_terminos            char(1) 	= 'N',
-- IOR declaracion de variables faltantes
   @i_calificacion		 varchar(10) 	= null,
   @i_linea_credito		 varchar(24) 	= null,	--SBU: 02/jul/2000
   @i_periodicidad_cuota         smallint    	= null,    --SBU: 21/ago/2000
   @i_edad_mora                  int         	= 0,  
   @i_valor_mora                 money       	= 0,  
   @i_fecha_pago                 datetime    	= null,  
   @i_valor_cuota                money       	= null,  
   @i_cuotas_pag                 smallint    	= null,  
   @i_estado_cartera             tinyint     	= null,  
   @i_dias_plazo                 int         	= 0,
   @i_gerente			 smallint    	= null,	--ZR
   @i_num_cuotaven		 smallint    	= null,	--SBU  20/mar/2001
   @i_saldo_cuotaven 		 money       	= 0,
   @i_admisible                  char(1)     	= 'N',   --PGA 18abr2001
   @i_num_cuotas                 smallint    	= null,
   @i_valor_ult_pago		 money	     	= 0,	--SBU Interfaces
   @i_fecha_castigo		 datetime    	= null,	--SBU cambios consolidador
   @i_num_acta			 varchar(24) 	= null,	--SBU 20/feb/2002  circular 50
   @i_gracia_cap		 smallint    	= null,
   @i_gracia_int		 smallint    	= null,
   @i_probabilidad_default	 float       	= null,
   @i_nat_reest			 catalogo    	= null,
   @i_num_reest			 tinyint     	= null,
   @i_acta_cas			 catalogo    	= null,
   @i_capsusxcor                 money          = null,
   @i_intsusxcor                 money          = null,
   @i_ccon			 catalogo        = null,
   @i_sit_castigo		 char(3)         = null,
   @i_fecha                      datetime       = null,
   @i_clausula                   char(1)        = null    --NR 354
   

)
as

declare 
   @w_sp_name       	varchar(15),
   @w_error         	int,
   @w_sucursal      	smallint,
   @w_regional      	smallint,
   @w_saldo         	money,
   @w_departamento  	smallint,
   @w_return	    	int,
   @w_clase_cartera 	varchar(10),
   @w_tipo_garantias	varchar(1),
   @w_valor_garantias	money,
   @w_admisible		char(1),
   @w_linea_credito	varchar(24),	--SBU: 02/jul/2000
   @w_fecha		datetime,
   @w_mensaje		varchar(255),
   @w_tab_clase         smallint,
   @w_resp              tinyint,
   @w_ccon 		varchar(30),
   @w_sit_cliente	catalogo,
   @w_sit_castigo	varchar(30),
   @w_cancelado		tinyint,
   @w_castigado		tinyint,
   @w_vigente           tinyint,   --- gsr 10/30/2003 Hablar Pablo
   @w_hora_base		datetime,
   @w_ms                datetime,
   @w_mc                datetime,
   @w_temporal          int,
   @w_max               int,
   @w_contador          int,
   @w_rowcount          int

select @w_max = 0, @w_contador = 0

--exec cob_cartera..sp_reloj 2.1, @w_ms, @w_ms out, @w_max

select @w_sp_name = 'sp_tmp_datooper'
select @w_hora_base = getdate()

if @i_fecha is null
   select @w_fecha = fp_fecha
   from cobis..ba_fecha_proceso
else
   select @w_fecha = @i_fecha



if @i_ccon is null begin

   select @w_ccon = pa_char
   from cobis..cl_parametro 
   where pa_nemonico = 'CCON' 
   and pa_producto = 'CRE'
   select @w_rowcount = @@rowcount
   set transaction isolation level read uncommitted

   if @w_rowcount = 0
   begin
      /* No existe valor de parametro */
      exec cobis..sp_cerror
      @t_from  = @w_sp_name,
      @i_num   = 2110384
      return 2110384
   end
end else
   select @w_ccon = @i_ccon 


--Situacion de castigo
if @i_sit_castigo is null begin

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
      @i_num   = 2110301
      return 1 
   end
end else
   select @w_ccon = @i_ccon,
          @w_sit_castigo = @i_sit_castigo

select @w_cancelado = 4,  
       @w_castigado = 3,
       @w_vigente   = 2   


/* VERIFICACION ESTADO CONTABLE */
if @i_estado_contable not in (1,2,3,4,5)
begin
   select @w_mensaje = 'Error, Estado contable no permitido ' + 
          @i_numero_operacion_banco + ' Producto: ' + convert(varchar(10),@i_codigo_producto) +
          ' Estado: ' + convert(varchar(10),@i_estado_contable),
          @w_error = 2101160

   print @w_mensaje

   goto FIN
end

/* VERIFICACION VALORES NEGATIVOS */
if (isnull(@i_saldo_prox_vto,0) < 0 ) or
   (isnull(@i_saldo_cap,0) < 0 ) or
   (isnull(@i_saldo_int,0) < 0 ) or
   (isnull(@i_saldo_otros,0) < 0 ) or
   (isnull(@i_saldo_int_contingente,0) < 0 ) or
   (isnull(@i_valor_mora,0) < 0 ) or
   (isnull(@i_valor_cuota,0) < 0 ) or
   (isnull(@i_saldo_cuotaven,0) < 0 ) or
   (isnull(@i_valor_ult_pago,0) < 0 ) or
   (isnull(@i_monto,0) < 0 ) 
begin
   /* SALDO NO PUEDE SER NEGATIVO */

   select @w_mensaje = 'Error, Saldo o Monto no puede ser negativo => No.Operacion: ' + 
          @i_numero_operacion_banco + ' Producto: ' + convert(varchar(10),@i_codigo_producto),
          @w_error = 2101145

   print @w_mensaje

   goto FIN
end


--INICIALIZAR PARAMETROS QUE PUEDAN ESTAR NULOS
select @i_no_renovacion   = isnull(@i_no_renovacion, 0)

-- IOR CEX no tiene codigo de estino en op pero si en tramite
if @i_codigo_destino is null
begin
   select @i_codigo_destino = tr_destino
   from cob_cartera..ca_operacion,cr_tramite 
   where op_tramite = tr_tramite 
   and   op_banco = @i_numero_operacion_banco
end

-- IOR CEX no tiene codigo geografico en op pero si en tramite
if @i_codigo_geografico is null
begin
   select @i_codigo_geografico = tr_ciudad_destino 
   from cob_cartera..ca_operacion,cr_tramite 
   where op_tramite = tr_tramite 
   and   op_banco = @i_numero_operacion_banco
end

--exec cob_cartera..sp_reloj 2.2, @w_ms, @w_ms out, @w_max

if @i_clase_cartera is null
begin
	exec @w_return = cob_credito..sp_clasif_cartera
	@i_toperacion = @i_tipo_operacion,
	@i_moneda = @i_moneda,
	@i_salida = 'S',
	@i_monto = @i_monto,
--	@i_tipo = 'O',
	@o_clase_cartera = @w_clase_cartera out

	if @w_return <> 0
	  return @w_return

	select @i_clase_cartera = @w_clase_cartera
end


--exec cob_cartera..sp_reloj 2.3, @w_ms, @w_ms out, @w_max
--PGA 12feb2001
if @i_codigo_producto = 58
   select @i_clase_cartera = @w_ccon

select @w_tab_clase = codigo
from cobis..cl_tabla
where tabla = 'cr_clase_cartera'
set transaction isolation level read uncommitted

select @w_resp = 1
from cobis..cl_catalogo
where tabla = @w_tab_clase
and codigo = @i_clase_cartera
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0
begin
   select @w_mensaje = 'Error, clase de cartera no existe => No.Operacion: ' + 
          @i_numero_operacion_banco + ' Producto: ' + @i_clase_cartera,
          @w_error = 2101159

   print @w_mensaje

   goto FIN
end


--exec cob_cartera..sp_reloj 2.4, @w_ms, @w_ms out, @w_max
/* VALIDACIONES CUPO DE CREDITO */
if @i_linea_credito = ' '
   select @i_linea_credito = null

if @i_codigo_producto in (9, 57, 60) begin  	--SBU: 02/jul/2000
     select   @w_linea_credito = li_num_banco
     from     cr_linea, cr_tramite
     where    li_numero =  tr_linea_credito
     and      tr_numero_op_banco  = @i_numero_operacion_banco
     and      tr_producto =  'CEX'
end 
else
begin
     if @i_linea_credito is not null
     begin     
        select @w_resp = 1
        from cr_linea
        where li_num_banco = @i_linea_credito
        and  (li_estado <> 'A' and li_estado is not null)

     end
select  @w_linea_credito  =  @i_linea_credito
end


--exec cob_cartera..sp_reloj 2.5, @w_ms, @w_ms out, @w_max
select @i_codigo_destino = isnull(@i_codigo_destino, '39')

--CALCULAR VALORES VARIABLES DE TRABAJO
select
@w_regional = b.of_regional,  --XSA Oficina Matriz
@w_sucursal = isnull(a.of_sucursal, a.of_oficina),
@i_codigo_geografico = isnull(@i_codigo_geografico,a.of_ciudad)
from cobis..cl_oficina a, cobis..cl_oficina b
where a.of_oficina = @i_oficina
and   b.of_oficina = isnull(a.of_sucursal, a.of_oficina)
set transaction isolation level read uncommitted

select @w_regional = isnull(@w_regional,1)

if @w_sucursal is null
begin
   select @w_mensaje = 'Error, No existe oficina => No.Operacion: ' + @i_numero_operacion_banco +
          ' Producto: ' + convert(varchar(10),@i_codigo_producto) + ' Oficina: ' + 
          convert(varchar(10),@i_oficina),
          @w_error = 2101157

   print @w_mensaje

   goto FIN
end


--SBU interfaces
select @w_saldo = @i_saldo_cap + @i_saldo_int + @i_saldo_otros + @i_saldo_int_contingente

if (@i_estado_contable = @w_cancelado) and (@w_saldo > 0)
begin
   select @w_mensaje = 'Operacion cancelada no puede tener saldos mayores a cero => No.Operacion: ' + @i_numero_operacion_banco +
          ' Producto: ' + convert(varchar(10),@i_codigo_producto),
          @w_error = 2101167

   print @w_mensaje

   goto FIN
end

select @w_departamento = ci_provincia
from   cobis..cl_ciudad
where  ci_ciudad = @i_codigo_geografico
set transaction isolation level read uncommitted

if @w_departamento is null
begin
   select @w_mensaje = 'Error, No existe ciudad => No.Operacion: ' + @i_numero_operacion_banco +
          ' Producto: ' + convert(varchar(10),@i_codigo_producto) + ' Ciudad: ' +
          convert(varchar(10),@i_codigo_geografico),
          @w_error = 2101161

   print @w_mensaje

   goto FIN
end

--exec cob_cartera..sp_reloj 2.6, @w_ms, @w_ms out, @w_max

exec @w_return = cob_custodia..sp_gar_admisible
@i_banco = @i_numero_operacion_banco,
@o_admisible = @w_admisible  out,
@o_valor = @w_valor_garantias  out

if @w_return <> 0
begin
   select  @w_mensaje =  'Error ejecutando cob_custodia..sp_gar_admisible',
           @w_error    = @w_return
   goto FIN 
end   

select @w_valor_garantias = isnull(@w_valor_garantias,0)

if @w_admisible = 'S'
   select @w_tipo_garantias = 'I'	--SBU 20/feb/2002  circular 50  
else
   select @w_tipo_garantias = 'O'


select @w_sit_cliente = en_situacion_cliente
from cobis..cl_ente
where en_ente = @i_codigo_cliente
set transaction isolation level read uncommitted

select 	@i_acta_cas      = cn_acta_cas,
	@i_fecha_castigo = cn_fecha_cas
from 	cr_concordato
where 	cn_cliente = @i_codigo_cliente


if (@w_sit_cliente <> @w_sit_castigo) and (@i_estado_contable = @w_castigado)
begin
   select @w_mensaje = 'Error, Cliente no esta castigado => No.Operacion: ' + @i_numero_operacion_banco +
          ' Producto: ' + convert(varchar(10),@i_codigo_producto) + ' Fecha castigo: ' +
          convert(varchar(10),@i_fecha_castigo,103),
          @w_error = 2101165

--   print @w_mensaje

   goto FIN
end



if (@i_estado_contable = @w_castigado) and (@i_fecha_castigo is null)
begin
   select @w_mensaje = 'Operacion esta castigada  => No.Operacion: ' + @i_numero_operacion_banco +
          ' Producto: ' + convert(varchar(10),@i_codigo_producto) + ' Fecha castigo: ' +
          convert(varchar(10),@i_fecha_castigo,103),
          @w_error = 2101168

   print @w_mensaje

   goto FIN
end


if @i_gerente is null
begin
   select @w_mensaje = 'No existe gerente para operacion: ' + @i_numero_operacion_banco ,
          @w_error = 2101153

   print @w_mensaje

   goto FIN
end


begin tran

      if exists (select 1 
                 from cr_tmp_datooper
                 where dot_numero_operacion_banco = @i_numero_operacion_banco
                 and   dot_codigo_producto = @i_codigo_producto)
      begin
         delete cr_tmp_datooper
         where dot_numero_operacion_banco = @i_numero_operacion_banco
         and dot_codigo_producto = @i_codigo_producto
      end

      insert into cr_tmp_datooper (
      dot_numero_operacion,dot_numero_operacion_banco,dot_tipo_operacion,
      dot_codigo_producto, dot_codigo_cliente,        dot_oficina,
      dot_sucursal,        dot_regional,              dot_moneda,
      dot_monto,           dot_tasa,                  dot_periodicidad,
      dot_modalidad,       dot_fecha_concesion,       dot_fecha_vencimiento,
      dot_dias_vto_div,    dot_fecha_vto_div,         dot_reestructuracion, --IOR cambio de nombre segun estructura
      dot_fecha_reest,     dot_num_cuota_reest,       dot_no_renovacion,         
      dot_codigo_destino,  dot_clase_cartera,         dot_codigo_geografico,     
      dot_departamento,    dot_fecha_prox_vto,        dot_saldo_prox_vto,        
      dot_saldo_cap,       dot_saldo_int,             dot_saldo_otros,           
      dot_saldo_int_contingente, 	   dot_saldo, dot_estado_contable,       
      dot_estado_desembolso,   dot_estado_terminos,   dot_calificacion,
      dot_tipo_garantias,  dot_valor_garantias,       dot_linea_credito,
      dot_periodicidad_cuota,  dot_edad_mora,	      dot_valor_mora,	--SBU: 21/ago/2000
      dot_fecha_pago,	   dot_valor_cuota,	      dot_cuotas_pag,
      dot_estado_cartera,  dot_plazo_dias,            dot_gerente, 	--ZR
      dot_num_cuotaven,	   dot_saldo_cuotaven,        dot_admisible,	--SBU  20/mar/2001
      dot_num_cuotas,	   dot_valor_ult_pago,	      dot_fecha_castigo,  --PGA 18abr2001
      dot_num_acta,	   dot_gracia_cap,	      dot_gracia_int,	 --SBU 20/feb/2002 circular 50
      dot_probabilidad_default,			      dot_nat_reest,
      dot_num_reest,	   dot_acta_cas,	      --SBU 20/feb/2002 circular 50
      dot_capsusxcor,	   dot_intsusxcor,
      dot_clausula,        dot_moneda_op                                    --NR354
      )
      values(
      @i_numero_operacion,@i_numero_operacion_banco,		@i_tipo_operacion,
      @i_codigo_producto, @i_codigo_cliente,        		@i_oficina,
      @w_sucursal,        convert(varchar(10),@w_regional),     @i_moneda,
      @i_monto,           @i_tasa,                  @i_periodicidad,
      @i_modalidad,       @i_fecha_concesion,       @i_fecha_vencimiento,
      @i_dias_vto_div,    @i_fecha_vto_div,         @i_reestructuracion,
      @i_fecha_reest,     @i_num_cuota_reest,       @i_no_renovacion,         
      @i_codigo_destino,  @i_clase_cartera,         @i_codigo_geografico,     
      @w_departamento,    @i_fecha_prox_vto,  	    @i_saldo_prox_vto,        
      @i_saldo_cap,       @i_saldo_int,       	    @i_saldo_otros,           
      @i_saldo_int_contingente,    @w_saldo,        @i_estado_contable,       
      @i_estado_desembolso,   @i_estado_terminos,   @i_calificacion,
      @w_tipo_garantias,  @w_valor_garantias,       @w_linea_credito,
      @i_periodicidad_cuota,  @i_edad_mora,	    @i_valor_mora,	--SBU: 21/ago/2000
      @i_fecha_pago,	  @i_valor_cuota,	    @i_cuotas_pag,
      @i_estado_cartera,  @i_dias_plazo,            @i_gerente,		--ZR
      @i_num_cuotaven,    @i_saldo_cuotaven,        @i_admisible,		--SBU  20/mar/2001
      @i_num_cuotas,	  @i_valor_ult_pago,        @i_fecha_castigo,  --PGA 18abr2001
      @i_num_acta,	  @i_gracia_cap,	    @i_gracia_int,
      @i_probabilidad_default,			    @i_nat_reest,
      @i_num_reest,	  @i_acta_cas,		    --SBU 20/feb/2002 circular 50
      @i_capsusxcor,      @i_intsusxcor,
      @i_clausula,        @i_moneda                                   --NR354
      )

      if @@error != 0
      begin
         print 'Error al insertar registro => No.Operacion: %1! Producto: %2!' + cast (@i_numero_operacion_banco as varchar)+ cast (@i_codigo_producto as varchar)         

         select @w_error = 2103013

         -- ERROR AL INSERTAR REGISTRO EN TABLA TEMPORAL DE OPERACIONES
   	 exec sp_error_batch        
   	 @i_fecha     = @w_fecha,
   	 @i_error     = 2103013,
   	 @i_programa  = @w_sp_name,
   	 @i_producto  = @i_codigo_producto,
         @i_operacion = @i_numero_operacion_banco
	
         goto FIN
      end

commit tran

--exec cob_cartera..sp_reloj 2.9, @w_ms, @w_ms out, @w_max
return 0

FIN:
return @w_error

GO
