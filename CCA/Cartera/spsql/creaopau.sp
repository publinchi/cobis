/************************************************************************/
/*      Archivo:                creaopau.sp                             */
/*      Stored procedure:       sp_crear_op_automatica                  */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Zoila Bedon/Luis Guachamin              */
/*      Fecha de escritura:     Nov. 1998                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.							*/
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Crea una operacion de Cartera de forma automatica desde otro    */
/*      modulo                                                          */
/*                              MODIFICACION                            */
/*                              		                        */
/*      MPO001                        		                        */
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_crear_op_automatica')
	drop proc sp_crear_op_automatica
go
create proc sp_crear_op_automatica
   @s_ssn               int         = null,
   @s_sesn              int         = null,
   @s_date              datetime    = null,
   @s_ofi               smallint    = null,
   @s_user              login       = null,
   @s_term              varchar(30) = null,
   @s_srv               varchar(30) = null,
   @s_lsrv              varchar(30) = null,
   @i_modi_par_general  char(1)     = 'N',  -- 'S' modifica param. generales.
   @i_modi_par_tabla    char(1)     = 'N',  -- 'S' modifica tabla de Amortiz.
   @i_modi_par_rubro    char(1)     = 'N',  -- 'S' modifica los rubros.
   @i_pasiva            char(1)     = 'S',  -- 'N' calcula el # de Tramite
   @i_tipo              char(1)     = 'N',  -- 'S' reversa la OP. 
                                            -- 'A' lista los Prd COBIS
   @i_modo              tinyint     = null, -- Consulta los productos COBIS
   @i_pd_producto       int         = null, -- Consulta Prd COBIS (codigo)
   @i_ref_exterior      cuenta      = null, -- Numero de Referencia del Exterior
   @i_sujeta_nego       char(1)     = 'N',  -- 'S':negociar la OP antes desemb
   @i_num_operacion_cex cuenta      = null, -- Numero de operacion de CEX
   @i_banco             cuenta      = null, -- No banco, en caso de reversar
   @i_tramite           int         = null, -- Numero de Tramite
   @i_cliente           int         = null, -- Deudor
   @i_codeudor          int         = null, -- Codedudor
   @i_num_renovacion    int         = null, -- Num de renovac
   @i_anterior          cuenta      = null, -- banco anterior de renovacion.
   @i_migrada           cuenta      = null, -- operacion sistema anterior
   @i_sector            catalogo    = null, -- sector del deudor
   @i_toperacion        catalogo    = null, -- Tipo de OP.
   @i_oficina           smallint    = null, -- Oficina donde se realiza la OP.
   @i_moneda            tinyint     = null, -- moneda de la OP.
   @i_comentario        varchar(255)= null, -- Comentario
   @i_oficial           smallint    = null, -- oficial que crea la OP.
   @i_fecha_ini         datetime    = null, -- Fecha de creacion de la OP.
   @i_monto             money       = null, -- Monto a desembolsar
   @i_monto_aprobado    money       = null, -- Monto aprobado para la OP.
   @i_destino           catalogo    = null, -- destino del dinero de la OP.
   @i_lin_credito       cuenta      = null, -- Linea de credito del Cliente
   @i_ciudad            int         = null, -- Ciudad destino del credito
   @i_forma_pago        catalogo    = null, -- Forma de pago de la OP.
   @i_cuenta            cuenta      = null, -- Cuenta asociada a forma de pago
   @i_formato_fecha     int         = 103,  -- Formato de fecha del FrontEnd
   @i_clase_cartera     catalogo    = null, -- Clase de la cartera
   @i_origen_fondos     catalogo    = null, -- Origen de fondos 
   /* Parametros para cuando modifica la Tabla de Amortizacion */
   @i_tipo_amortizacion varchar(10) = null, -- 'FRANCESA', 'ALEMANA','MANUAL'
   @i_gracia_cap        int         = null, -- gracia de Capital
   @i_gracia_int        int         = null, -- gracia de interes
   @i_tplazo            catalogo    = null, -- unidad de medida de tiempo
   @i_plazo             int         = null, -- tiempo respecto a TPLAZO
   @i_tdividendo        catalogo    = null, -- Tipo de dividendo
   @i_periodo_cap       int         = null, -- Periodicidad de capital
   @i_periodo_int       int         = null, -- Periodicidad de interes
   @i_fecha_fija        char(1)     = null, -- Vencimientos en un dia fijo
   @i_evitar_feriados   char(1)     = null, -- evitar feriados
   @i_dia_fijo          int         = null, -- Dia fijo de pago
   @i_dias_gracia       smallint    = null, -- D¡as de gracia de mora
   @i_mes_gracia        tinyint     = null, -- Mes de gracia capital e intres
   /* Parametro Generales */
   @i_reajustable       char(1)     = null, -- operacion reajustable?
   @i_periodo_reajuste  smallint    = null,
   @i_reajuste_especial  char(1)    = null, -- mantener: [S]cuota, [N]tiempo
   @i_renovacion         char(1)    = null, -- operacion es renovable o no
   @i_precancelacion     char(1)    = null, -- operacion permite precancel o no
   @i_tipo_aplicacion    char(1)    = null, -- pago por cuotas o rubros
   @i_cuota_completa     char(1)    = null, -- pagos de cuota completa?
   @i_tipo_cobro         char(1)    = null, -- pagos acum. proy. o valpres
   @i_tipo_reduccion     char(1)    = null, -- pagos tiempo cuota o normal
   @i_aceptar_anticipos  char(1)    = null, -- pagos aceptar anticipos?
   /* Interes */
   @i_concepto_int     catalogo     = null, -- Siglas del rubro interes
   @i_porcentaje_int   float        = null, -- Porcentaje del rubro interes
   /**************************************/ -- MPO001
   @i_referencial      catalogo     = null,
   @i_factor	       float        = null,
   @i_signo            char(1)      = null,
   @i_prd_cobis	       int	    = null,
   /**************************************/ -- MPO001
   /* Mora */
   @i_concepto_mor     catalogo     = null,
   @i_porcentaje_mor   float        = null,
   @i_fondos_propios   char(1)      = null,
   @i_convierte_tasa   char(1)      = null,
   @i_tasa_equivalente char(1)      = null,
   /**************************************/
   @i_fec_embarque     datetime     = null,
   @i_fec_dex          datetime     = null,
   @i_comex            cuenta       = null,
   /**************************************/
   @i_reestructuracion char(1)	    = null,
   @i_tipo_cambio      char(1)      = null,

   /* Salida */
   @o_tramite          int          = null output, 
   @o_banco            cuenta       = null output, 
   @o_operacion        int          = null output  
as

declare 
   @w_sp_name              descripcion,
   @w_return               int,
   @w_error                int,
   @w_nombre               descripcion, 
   @w_banco                cuenta,      
   @w_tramite              int,      
   @w_ced_ruc              numero,   
   @w_ced_ruc_codeudor     numero,   
   @w_estado               tinyint,
   @w_operacionca          int,
   @w_provisiona           char(1),
   @w_prioridad	           tinyint,
   @w_referencial          catalogo,
   @w_valor_referencial	   float,
   @w_referencial_reaj	   catalogo,
   @w_signo_reaj           char(1),
   @w_valor_reaj           float,
   @w_modalidad            char(1),
   @w_periodicidad         char(1),
   @w_factor1              float,
   @w_signo1               char(1),
   @w_linea_num_banco      cuenta,
   @w_linea_numero	   int,		--SBU  15/ene/2002
   @w_prd_cobis            smallint,
   @w_tipo                 char(1) ,
   @w_descripcion_operacion descripcion,
   --@w_linea_numbanco       cuenta,
   @w_num_dec_tapl	   tinyint


/* Cargar valores iniciales */

select @w_sp_name = 'sp_crear_op_automatica'

/**
if @i_prd_cobis = 9 begin

 PRINT 	'HOLA LLAMAR A MARCELO
	Tipo Plazo %1!
       	Tipo Cuota %2!	
       	Plazo %3!
       	Cuota Cap %4!
       	Cuota Int %5!
	Tasa %6!
	Factor %7!
	Signo %8!
	Cobis %9!',@i_tplazo, @i_tdividendo, @i_plazo,
	@i_periodo_cap, @i_periodo_int, @i_referencial,
	@i_factor, @i_signo, @i_prd_cobis
end
**/

/*  PARA LISTAR LAS OPERACIONES QUE SON DE COMEXT */
if @i_tipo = 'C' begin


   /* OPERACIONES ACTIVAS Y PASIVAS  */
   if isnull(@i_modo,0) = 0 begin
       select distinct c.codigo, c.valor
       from cobis..cl_tabla t, cobis..cl_catalogo c, ca_default_toperacion
       where t.tabla = 'ca_toperacion'
       and   t.codigo = c.tabla
       and   c.estado = 'V'
       and   c.codigo = dt_toperacion
       and   (dt_prd_cobis = @i_prd_cobis or @i_prd_cobis is null)
       order by c.codigo
       
       return 0
   end


   if @i_modo = 1 begin -- OPERACIONES DE REDESCUENTO O PASIVAS
       select distinct c.codigo, c.valor
       from cobis..cl_tabla t, cobis..cl_catalogo c, ca_default_toperacion
       where t.tabla = 'ca_toperacion'
       and   t.codigo = c.tabla
       and   c.estado = 'V'
       and   c.codigo = dt_toperacion
       and   (dt_prd_cobis = @i_prd_cobis or @i_prd_cobis is null)
       and   dt_tipo      = 'R'
       order by c.codigo

       return 0
   end

   if @i_modo = 2 begin -- OPERACIONES NORMALES O ACTIVAS
       select distinct c.codigo, c.valor
       from cobis..cl_tabla t, cobis..cl_catalogo c, ca_default_toperacion
       where t.tabla = 'ca_toperacion'
       and   t.codigo = c.tabla
       and   c.estado = 'V'
       and   c.codigo = dt_toperacion
       and   dt_prd_cobis = 9
       and   dt_tipo      = 'N'
       order by c.codigo

       return 0
   end

  return 710003 
end 

/* PARA RECUPERAR LA DESCRIPCION DE LAS OPERACIONES DE COMEXT */
if @i_tipo = 'D' begin
   if @i_modo = 1 begin -- OPERACIONES DE REDESCUENTO O PASIVAS
       select distinct c.valor
       from cobis..cl_tabla t, cobis..cl_catalogo c, ca_default_toperacion
       where t.tabla = 'ca_toperacion'
       and   t.codigo = c.tabla
       and   c.estado = 'V'
       and   c.codigo = dt_toperacion
       and   dt_prd_cobis = 9
       and   dt_tipo      = 'R'
       and   c.codigo     = @i_toperacion
       order by c.valor

       select @w_descripcion_operacion
       return 0
   end

   if @i_modo = 2 begin -- OPERACIONES NORMALES O ACTIVAS
       select distinct c.valor
       from cobis..cl_tabla t, cobis..cl_catalogo c, ca_default_toperacion
       where t.tabla = 'ca_toperacion'
       and   t.codigo = c.tabla
       and   c.estado = 'V'
       and   c.codigo = dt_toperacion
       and   dt_prd_cobis = 9
       and   dt_tipo      = 'N'
       and   c.codigo     = @i_toperacion
       order by c.valor

       select @w_descripcion_operacion
       return 0
   end

  return 710003 
end

/*  PARA SABER EL TIPO DE OPERACION   */
if @i_tipo = 'Q' begin

   select 
   @w_tipo      = dt_tipo,
   @w_prd_cobis = dt_prd_cobis
   from cob_cartera..ca_default_toperacion
   where dt_toperacion = @i_toperacion
   and   dt_moneda     = @i_moneda  

   select @w_tipo, @w_prd_cobis 

   return 0 
end



/* PARA DESPLEGAR LOS PRODUCTOS COBIS */
if @i_tipo = 'A' begin

   set rowcount 20

   if @i_modo = 0 select @i_pd_producto = -999

   select 
   'Codigo'      = pd_producto, 
   'Descripcion' = pd_descripcion 
   from cobis..cl_producto
   where pd_estado   = 'V'
   and   pd_producto > @i_pd_producto
   order by pd_producto
   set transaction isolation level read uncommitted

   set rowcount 0

   return 0
end


/* REVERSAR (ELIMINAR) LA OPERACION CREADA */
if @i_tipo = 'R' begin

   select 
   @w_estado      = op_estado,
   @w_operacionca = op_operacion
   from  ca_operacion
   where op_banco = @i_banco

   if @w_estado != 0 return 705007

   delete ca_amortizacion
   where am_operacion = @w_operacionca
   if @@error <> 0 return 710003

   delete ca_rubro_op
   where ro_operacion = @w_operacionca 
   if @@error <> 0 return 710003

   delete ca_dividendo
   where di_operacion = @w_operacionca 
   if @@error <> 0 return 710003

   delete ca_cuota_adicional
   where ca_operacion = @w_operacionca 
   if @@error <> 0 return 710003

   delete ca_tasas
   where ts_operacion = @w_operacionca 
   if @@error <> 0 return 710003

   delete ca_reajuste_det
   where red_operacion = @w_operacionca

   if @@error <> 0 return 710003

   delete ca_reajuste
   where re_operacion = @w_operacionca 
   if @@error <> 0 return 710003



   delete ca_operacion
   where op_operacion = @w_operacionca
   if @@error <> 0 return 710003

   delete ca_det_trn
   where dtr_operacion = @w_operacionca
   if @@error <> 0 return 710003

   delete ca_transaccion
   where tr_operacion = @w_operacionca
   if @@error <> 0 return 710003

   delete ca_desembolso
   where dm_operacion = @w_operacionca
   if @@error <> 0 return 710003

   return 0 

end  /* i_tipo = R */


/* Buscar nombre,cedula/ruc del deudor */
select 
@w_ced_ruc = en_ced_ruc,
@w_nombre  = rtrim(p_p_apellido)+' '+rtrim(p_s_apellido)+' '+rtrim(en_nombre)
from  cobis..cl_ente
where en_ente = @i_cliente
set transaction isolation level read uncommitted

/* Ingresar Deudor */
exec @w_return = sp_codeudor_tmp
@s_sesn        = @s_sesn,
@s_user        = @s_user,
@i_borrar      = 'S',
@i_secuencial  = 1,
@i_titular     = @i_cliente,
@i_operacion   = 'A',
@i_codeudor    = @i_cliente,
@i_ced_ruc     = @w_ced_ruc,
@i_rol         = 'D',
@i_externo     = 'N'

if @w_return <> 0 return @w_return

if @i_codeudor is not null begin

   /* Buscar cedula/ruc del codeudor */
   select @w_ced_ruc_codeudor = en_ced_ruc
   from cobis..cl_ente
   where  en_ente = @i_codeudor
   set transaction isolation level read uncommitted

   /* Ingresar CoDeudor */
   exec @w_return      = sp_codeudor_tmp
   @s_sesn        = @s_sesn,
   @s_user        = @s_user,
   @i_borrar      = 'S',
   @i_secuencial  = 2,
   @i_titular     = @i_codeudor,
   @i_operacion   = '0',
   @i_codeudor    = @i_codeudor,
   @i_ced_ruc     = @w_ced_ruc_codeudor,
   @i_rol         = 'C',
   @i_externo     = 'N'

   if @w_return != 0 return @w_return

end


/* CREACION DE LA OPERACION */
exec @w_return = cob_cartera..sp_crear_operacion
@s_ssn            = @s_ssn,
@s_user           = @s_user,
@s_sesn           = @s_sesn,
@s_term           = @s_term,
@s_date           = @s_date,
@i_anterior       = @i_anterior,
@i_comentario     = @i_comentario,
@i_oficial        = @i_oficial,
@i_destino        = @i_destino,
@i_monto_aprobado = @i_monto_aprobado,
@i_fondos_propios = @i_fondos_propios,
@i_ciudad         = @i_ciudad,
@i_cliente        = @i_cliente,
@i_nombre         = @w_nombre,
@i_sector         = @i_sector,
@i_oficina        = @i_oficina,
@i_toperacion     = @i_toperacion,
@i_monto          = @i_monto,
@i_moneda         = @i_moneda,
@i_fecha_ini      = @i_fecha_ini,
@i_lin_credito    = @i_lin_credito,
@i_migrada        = @i_migrada,
@i_formato_fecha  = @i_formato_fecha,
@i_forma_pago     = @i_forma_pago,
@i_cuenta         = @i_cuenta,
@i_clase_cartera  = @i_clase_cartera,
@i_origen_fondos  = @i_origen_fondos,
@i_sujeta_nego    = @i_sujeta_nego,   -- sujeta a negociacion
@i_ref_exterior   = @i_ref_exterior,  -- numero de referencia exterior
@i_convierte_tasa = @i_convierte_tasa,  
@i_tasa_equivalente = @i_tasa_equivalente,  
@i_fec_embarque   = @i_fec_embarque,
@i_num_comex      = @i_num_operacion_cex,
@i_num_deuda_ext  = @i_comex,
@i_reestructuracion = @i_reestructuracion,
@i_tipo_cambio    = @i_tipo_cambio,
@o_banco          = @w_banco output

if @w_return != 0 return @w_return


/* Obtengo el numero de la Operacion */
select 
@o_operacion    = opt_operacion,
@w_prd_cobis    = opt_prd_cobis
from   ca_operacion_tmp
where  opt_banco = @w_banco


/*   MODIFICAR LOS RUBROS   */
if @i_modi_par_rubro = 'S' begin

   -- MPO101  
   select  
   @w_num_dec_tapl  = vd_num_dec
   from    ca_valor,ca_valor_det
   where   va_tipo   = @i_referencial 
   and     vd_tipo   = @i_referencial
   and     vd_sector = @i_sector 
   -- MPO101
   
   /* rubro INTERES*/
   /* Obtengo los demas datos del rubro de la op temporal */

   if not @i_concepto_int is null begin

      exec @w_return = sp_rubro_tmp
      @i_operacion         = 'Q',
      @s_ofi               = @s_ofi,
      @i_banco             = @w_banco,
      @i_concepto          = @i_concepto_int,
      @i_toperacion        = @i_toperacion,  
      @o_provisiona        = @w_provisiona        out ,
      @o_prioridad         = @w_prioridad         out ,
      @o_valor_referencial = @w_valor_referencial out ,
      @o_signo_reaj        = @w_signo_reaj        out ,
      @o_valor_reaj        = @w_valor_reaj        out ,
      @o_referencial       = @w_referencial       out ,
      @o_referencial_reaj  = @w_referencial_reaj  out ,
      @o_modalidad         = @w_modalidad         out ,
      @o_periodicidad      = @w_periodicidad      out 

      if @w_return <> 0 return @w_return

      -- CALCULO DEL SIGNO Y FACTOR DEL PORCENTAJE
      select @w_factor1 = @i_porcentaje_int - @w_valor_referencial

      if @w_factor1 >= 0 
         select @w_signo1 = '+'
      else begin
         select @w_signo1 = '-'
         select @w_factor1 = @w_factor1 * -1 
      end

      --MPO001
      if @i_prd_cobis = 9 --COMEXT  
         select @w_signo1 = @i_signo,
         @w_factor1       = @i_factor
       
      --MPO001

      exec @w_return = cob_cartera..sp_rubro_tmp
      @s_user                 = @s_user,
      @s_term                 = @s_term,
      @s_date                 = @s_date,
      @s_ofi                  = @s_ofi,
      @i_banco                = @w_banco,
      @i_concepto             = @i_concepto_int,
      @i_prioridad            = @w_prioridad,
      @i_provisiona           = @w_provisiona,
      @i_referencial	      = @i_referencial, --MPO001
      @i_signo                = @w_signo1 ,
      @i_factor               = @w_factor1 ,
      @i_signo_reajuste       = @w_signo_reaj,
      @i_factor_reajuste      = @w_valor_reaj,
      @i_porcentaje           = @i_porcentaje_int,
      @i_valor                = 0,
      --@i_referencial          = @w_referencial,
      @i_referencial_reajuste = @i_referencial, --MPO101
      @i_operacion            = 'U',
      @i_modalidad_o          = @w_modalidad,
      @i_periodo_o            = @w_periodicidad,
      @i_num_dec_tapl         = @w_num_dec_tapl	 --MPO101
   
      if @w_return != 0 return @w_return

   end

   /* rubro MORA */
   /* Obtengo los demas datos del rubro de la op temporal */

   if not @i_concepto_mor is null begin

      exec @w_return = sp_rubro_tmp 
      @i_operacion         = 'Q',
      @s_ofi               = @s_ofi,
      @i_banco             = @w_banco,
      @i_concepto          = @i_concepto_int,
      @i_toperacion        = @i_toperacion,  
      @o_provisiona        = @w_provisiona        out ,
      @o_prioridad         = @w_prioridad         out ,
      @o_valor_referencial = @w_valor_referencial out ,
      @o_signo_reaj        = @w_signo_reaj        out ,
      @o_valor_reaj        = @w_valor_reaj        out ,
      @o_referencial       = @w_referencial       out ,
      @o_referencial_reaj  = @w_referencial_reaj  out ,
      @o_modalidad         = @w_modalidad         out ,
      @o_periodicidad      = @w_periodicidad      out 

      if @w_return <> 0 return @w_return

      -- CALCULO DEL SIGNO Y FACTOR DEL PORCENTAJE
      select @w_factor1 = @i_porcentaje_mor - @w_valor_referencial

      if @w_factor1 >= 0 
         select @w_signo1 = '+'
      else 
         select 
         @w_signo1 = '-',
         @w_factor1 = @w_factor1 * -1 

      exec @w_return = cob_cartera..sp_rubro_tmp
      @s_user            = @s_user,
      @s_term            = @s_term,
      @s_date            = @s_date,
      @s_ofi             = @s_ofi,
      @i_banco           = @w_banco,
      @i_concepto        = @i_concepto_mor,
      @i_prioridad       = @w_prioridad,
      @i_provisiona      = @w_provisiona,
      @i_signo           = @w_signo1 ,
      @i_factor          = @w_factor1 ,
      @i_signo_reajuste  = @w_signo_reaj,
      @i_factor_reajuste = @w_valor_reaj,
      @i_porcentaje      = @i_porcentaje_mor,
      @i_valor           = 0,
      @i_referencial     = @w_referencial,
      @i_referencial_reajuste = @w_referencial_reaj,
      @i_operacion       = 'U',
      @i_modalidad_o     = @w_modalidad,
      @i_periodo_o       =  @w_periodicidad,
      @i_num_dec_tapl    = @w_num_dec_tapl --MPO101	

      if @w_return <> 0 return @w_return

   end

   /* Modifico la operacion */
   exec @w_return = cob_cartera..sp_modificar_operacion
   @s_user           = @s_user,
   @s_term           = @s_term,
   @s_date           = @s_date,
   @s_ofi            = @s_ofi,
   @i_banco          = @w_banco,
   @i_calcular_tabla = 'S',
   @i_formato_fecha  = @i_formato_fecha ,
   @i_cuota          = 0,
   @i_tasa           = 'S',
   @i_sujeta_nego    = @i_sujeta_nego,
   @i_ref_exterior   = @i_ref_exterior,
   @i_fec_embarque   = @i_fec_embarque,
   @i_fec_dex        = @i_fec_dex,
   @i_comex          = @i_comex

   if @w_return != 0 return @w_return

end  -- if modificar RUBROS

/* MODIFICAR TABLA DE AMORTIZACION */
if @i_modi_par_tabla = 'S' begin

   exec @w_return = sp_modificar_operacion
   @s_user        = @s_user,
   @s_term            = @s_term,
   @s_date            = @s_date,
   @s_ofi             = @s_ofi,
   @i_tipo_amortizacion = @i_tipo_amortizacion,
   @i_gracia_cap      = @i_gracia_cap,
   @i_gracia_int      = @i_gracia_int,
   @i_banco           = @w_banco,
   @i_fecha_ini       = @i_fecha_ini,
   @i_tplazo          = @i_tplazo,
   @i_plazo           = @i_plazo,
   @i_tdividendo      = @i_tdividendo,
   @i_periodo_cap     = @i_periodo_cap,
   @i_periodo_int     = @i_periodo_int,
   @i_fecha_fija      = @i_fecha_fija,
   @i_cuota           = 0,   
   @i_evitar_feriados = @i_evitar_feriados,
   @i_dia_fijo        = @i_dia_fijo,
   @i_toperacion      = @i_toperacion,
   @i_calcular_tabla  = 'S',
   @i_formato_fecha   = @i_formato_fecha,
   @i_moneda          = @i_moneda,
   @i_dias_gracia     = @i_dias_gracia,
   @i_mes_gracia      = @i_mes_gracia,
   @i_sujeta_nego    = @i_sujeta_nego,
   @i_ref_exterior   = @i_ref_exterior,
   @i_fec_embarque   = @i_fec_embarque,
   @i_fec_dex        = @i_fec_dex,
   @i_comex          = @i_comex


   if @w_return != 0 return @w_return

end -- if modificar TABLA DE AMORTIZACION

/* MODIFICAR PARAMETROS GENERALES */
if @i_modi_par_general = 'S' begin

   exec @w_return = sp_modificar_operacion
   @s_user              = @s_user,
   @s_term              = @s_term,
   @s_date              = @s_date,
   @s_ofi               = @s_ofi,
   @i_calcular_tabla    = 'N',
   @i_forma_pago        = @i_forma_pago,
   @i_reajustable       = @i_reajustable,
   @i_periodo_reajuste  = @i_periodo_reajuste,
   @i_reajuste_especial = @i_reajuste_especial,
   @i_renovacion        = @i_renovacion,
   @i_precancelacion    = @i_precancelacion,
   @i_tipo_aplicacion   = @i_tipo_aplicacion,
   @i_cuota_completa    = @i_cuota_completa,
   @i_tipo_cobro        = @i_tipo_cobro,
   @i_tipo_reduccion    = @i_tipo_reduccion,
   @i_aceptar_anticipos = @i_aceptar_anticipos,
   @i_banco             = @w_banco,
   @i_sujeta_nego       = @i_sujeta_nego,
   @i_ref_exterior      = @i_ref_exterior,
   @i_fec_embarque   = @i_fec_embarque,
   @i_fec_dex        = @i_fec_dex,
   @i_comex          = @i_comex


   if @w_return != 0 return @w_return

end  -- if modificar PARAMETROS GENERALES


/* GENERAR UN TRAMITE EN CASO DE CREACION DIRECTA DESDE CARTERA */
/*
if @w_prd_cobis = 9 and @i_pasiva = 'N' and @i_num_operacion_cex <> null 
begin

   exec @w_return = cob_credito..sp_tramite_cca
   @s_ssn               = @s_ssn,
   @s_user              = @s_user,
   @s_sesn              = @s_sesn,
   @s_term              = @s_term,
   @s_date              = @s_date,
   @s_srv               = @s_srv,
   @s_lsrv              = @s_lsrv,
   @s_ofi               = @s_ofi,
   @i_oficina_tr        = @i_oficina,
   @i_fecha_crea        = @i_fecha_ini,  -- la misma de creacion de la OP
   @i_oficial           = @i_oficial,
   @i_sector            = @i_sector,
   @i_banco             = @w_banco,
   @i_linea_credito     = @i_lin_credito,
   @i_toperacion        = @i_toperacion,
   @i_producto          = 'CCA',
   @i_monto             = @i_monto,
   @i_moneda            = @i_moneda,                                       
   @i_periodo           = @i_tplazo,
   @i_num_periodos      = @i_plazo,
   @i_destino           = @i_destino,
   @i_ciudad_destino    = @i_ciudad,
   @i_renovacion        = @i_num_renovacion,
   @i_clase             = @i_clase_cartera , 
   @i_cliente           = @i_cliente,
   @i_tipo              =  'F',
   @i_numoper_cex       = @i_comex,
   @o_tramite           = @w_tramite out	--,SBU 15/ene/2002  solo existe 1 parametro de salida
   --@o_linea_numbanco    = @w_linea_numbanco out

   if @w_return <> 0 return @w_return

   if @w_tramite = 0  begin
      PRINT 'creaopau.sp error al ejecutar cob_credito..cp_tramite_cca @w_tramite %1!',@w_tramite
     return 710005 --cambiar este numero
   end



   select @w_linea_num_banco = null,
          @w_linea_numero = null

   -- OBTENCION DE LA LINEA DE CREDITO PARA TRAMITE DE CEX
   exec @w_return = cob_credito..sp_integracion_cex
   @t_trn = 21988,
   @i_modo            = 3,
   @i_numoperacion   = @i_num_operacion_cex,
   @i_monto           = @i_monto,
   @i_moneda          = @i_moneda,
   @i_toperacion      = @i_toperacion,
   @i_producto        = 'CCA',
   @i_origen          = 'CCA',
   @i_opecca          = @w_banco, /* numero interno en esta instancia **/ 
   @s_date            = @s_date ,
   @s_user         = @s_user, 
   @s_term         = @s_term, 
   @s_ofi          = @s_ofi,
   /***  ICCLuisG043 30/dic/1999 ***/
   @i_tramite      =  @w_tramite,
   /********************************/
   @o_linea_num_banco = @w_linea_num_banco out, --LINEA DE CREDITO PARA CEX
   @o_linea_numero    = @w_linea_numero  out	--SBU 15/ene/2002

   if @w_return <> 0  return 7100002

   --if @w_linea_num_banco is not null begin
   update ca_operacion_tmp set
   opt_lin_credito  = @w_linea_num_banco,
   opt_tramite = @w_tramite
   where opt_banco = @w_banco 

   if @@error <> 0 return 710002

   update cob_credito..cr_tramite set
   tr_linea_credito  = @w_linea_numero
   where tr_tramite = @w_tramite

   if @@error <> 0 return 710340
 
   --end
  

   /* Herencia de las Garantias                */
   exec @w_return  = cob_custodia..sp_heredar_gar
   @t_trn          = 19017,
   @i_numoperacion = @i_num_operacion_cex,
   @i_tramite      = @w_tramite
   if @w_return != 0
      return @w_return 
   /*******************************************/
   
end

*/

exec @w_return = sp_operacion_def
@i_banco = @w_banco,
@s_date  = @s_date,
@s_sesn  = @s_sesn,
@s_user  = @s_user,
@s_ofi   = @s_ofi

if @w_return != 0 return @w_return

/** ACTUALIZACION DE ESTADO DE OPERACION DE COMEXT **/
if @w_prd_cobis = 9 
   update ca_operacion
   set op_estado = 98
   where op_banco = @w_banco

 
exec @w_return = sp_borrar_tmp
@i_banco  = @w_banco,
@s_date   = @s_date,
@s_sesn   = @s_sesn,
@s_user   = @s_user,
@s_ofi    = @s_ofi,
@s_term   = @s_term

if @w_return != 0 return @w_return

select 
@o_banco     = @w_banco,
@o_operacion = @o_operacion,
@o_tramite   = @w_tramite

return 0

go

