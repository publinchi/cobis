/************************************************************************/
/*	Archivo: 		imptabla.sp				*/
/*	Stored procedure: 	sp_imp_tabla_amort_acum			*/
/*	Base de datos:  	cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Ramiro Buitron (GrupoCONTEXT)		*/
/*	Fecha de escritura: 	08/Jun/1999				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	'MACOSA'.							*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/************************************************************************/  
/*				PROPOSITO				*/
/*	Consulta para imprimir la tabla de amortizacion con interes     */
/*	acumulado                                                       */
/************************************************************************/

use cob_cartera
go
 
set ansi_nulls off
go

if exists (select 1 from sysobjects where name = 'sp_imp_tabla_amort_acum')
   drop proc sp_imp_tabla_amort_acum
go

create proc sp_imp_tabla_amort_acum (
   @s_ssn               int         = null,
   @s_date              datetime    = null,
   @s_user              login       = null,
   @s_term              descripcion = null,
   @s_corr              char(1)     = null,
   @s_ssn_corr          int         = null,
   @s_ofi               smallint    = null,
   @t_rty               char(1)     = null,
   @t_debug          	char(1)     = 'N',
   @t_file         	varchar(14) = null,
   @t_trn		smallint    = null,  
   @i_operacion         char(1)     = null,
   @i_banco		cuenta      = null,
   @i_formato_fecha	int         = null,
   @i_dividendo         int         = null
)
as
declare	@w_sp_name			varchar(32),
       	@w_return			int,
	      @w_error        		int,
        @w_operacionca                  int,
        @w_tamanio                      int,
	     @w_tipo                         char(1),
        @w_det_producto			int,
        @w_cliente                      int,
        @w_nombre                       varchar(60),
        @w_direccion                    varchar(100),
        @w_ced_ruc                      varchar(15),
        @w_telefono                     varchar(15),  
        @w_toperacion_desc              varchar(100),
        @w_moneda                       tinyint,
        @w_moneda_desc                  varchar(30),
        @w_monto                        money,
        @w_plazo                        smallint,
        @w_tplazo                       varchar(30),
        @w_tipo_amortizacion            varchar(10),
        @w_tdividendo                   varchar(30),
        @w_periodo_cap                  smallint,
        @w_periodo_int                  smallint,
        @w_gracia                       smallint,
        @w_gracia_cap                   smallint,
        @w_gracia_int                   smallint,
        @w_cuota                        money,
        @w_acumulado                    money,
        @w_tasa                         float,
        @w_mes_gracia                   tinyint,
        @w_rejustable                   char(1),
        @w_periodo_reaj                 int,
	     @w_primer_des			          int,
        @w_tasa_ef_anual                float,
        @w_periodicidad_o               char(1),
        @w_modalidad_o                  char(1),
        @w_fecha_fin                    varchar(10), 
        @w_dias_anio                    int,
        @w_base_calculo                 char(1),
        @w_tasa_referencial             varchar(12), 
        @w_signo_spread                 char(1),
        @w_valor_spread                 float,
        @w_modalidad                    char(1),
        @w_valor_referencial            float,
        @w_sector                       char(1),
        @w_op_direccion                 tinyint,
        @w_rowcount                     int
          
/* Captura nombre de Stored Procedure  */
select	@w_sp_name = 'sp_imp_tabla_amort_acum'


/* CABECERA DE LA IMPRESION  EN TABLAS DEFINITIVAS*/
if @i_operacion = 'C'
begin
   select 
   @w_operacionca       = op_operacion ,
   @w_cliente           = op_cliente, 
   @w_toperacion_desc   = A.valor,
   @w_moneda            = op_moneda,
   @w_moneda_desc       = mo_descripcion,
   @w_monto             = op_monto,
   @w_plazo             = op_plazo,
   @w_tplazo            = op_tplazo,
   @w_tipo_amortizacion = op_tipo_amortizacion,
   @w_tdividendo        = op_tdividendo,
   @w_periodo_cap       = op_periodo_cap,
   @w_periodo_int       = op_periodo_int,   
   @w_gracia_cap        = op_gracia_cap,
   @w_gracia_int        = op_gracia_int,
   @w_cuota             = op_cuota,
   @w_mes_gracia        = op_mes_gracia,
   @w_rejustable        = op_reajustable,
   @w_periodo_reaj      = isnull(op_periodo_reajuste,0),
   @w_fecha_fin         = convert(varchar(10),op_fecha_fin,101),
   @w_dias_anio         = op_dias_anio,
   @w_base_calculo      = op_base_calculo,
   @w_sector            = op_sector,
   @w_op_direccion      = op_direccion
   from ca_operacion, cobis..cl_catalogo A, cobis..cl_moneda   
   where op_banco    = @i_banco
   and op_toperacion = A.codigo
   and op_moneda     = mo_moneda   

   if @@rowcount = 0
   begin
      select @w_error = 710026
      goto ERROR
   end  

   select @w_gracia    = isnull(di_gracia,0)
   from   ca_dividendo
   where  di_operacion = @w_operacionca 
   and    di_estado    = 1

   select @w_tplazo   = td_descripcion 
   from   ca_tdividendo
   where  td_tdividendo = @w_tplazo

   select @w_tdividendo= td_descripcion 
   from   ca_tdividendo
   where  td_tdividendo = @w_tdividendo

   select @w_tasa = isnull(sum(ro_porcentaje),0)
   from ca_rubro_op
   where ro_operacion  =  @w_operacionca
   and   ro_tipo_rubro =  'I'
   and   ro_fpago      in ('P','A')

   select @w_tasa_referencial = ro_referencial,  
          @w_signo_spread = ro_signo,       
          @w_valor_spread = ro_factor,              
          @w_modalidad    = ro_fpago,       
          @w_valor_referencial = ro_porcentaje_aux 
   from ca_rubro_op
   where ro_operacion  =  @w_operacionca
   and   ro_tipo_rubro =  'I'
   and   ro_fpago      in ('P','A')

   select @w_tasa_referencial = vd_referencia from ca_valor_det
   where vd_tipo = @w_tasa_referencial
   and vd_sector = @w_sector

   /*  Encuentra el Producto  */
   select @w_tipo = pd_tipo
   from cobis..cl_producto
   where pd_producto = 7
   set transaction isolation level read uncommitted

   /*  Encuentra el Detalle de Producto  */
   select 
   @w_det_producto = dp_det_producto
   from	cobis..cl_det_producto
   where dp_producto = 7
   and	dp_tipo   = @w_tipo
   and	dp_moneda = @w_moneda
   and	dp_cuenta = @i_banco
   select @w_rowcount = @@rowcount
   set transaction isolation level read uncommitted

   if @w_rowcount = 0 
   begin
       select @w_error = 710023
       goto ERROR
   end

   /*Realizar la consulta de Informacion General de Cliente*/

   select 
   @w_ced_ruc  = isnull(cl_ced_ruc,p_pasaporte), 
   @w_nombre   = ltrim(substring(rtrim(p_p_apellido) + ' ' + rtrim(p_s_apellido) + ' ' 
                 + rtrim(en_nombre),1,60)),
   @w_telefono  = (select isnull(te_valor,'') from cobis..cl_telefono where te_ente = CL.en_ente and te_direccion = @w_op_direccion ),
   @w_direccion = (select isnull(di_descripcion,'') from cobis..cl_direccion where di_ente = CL.en_ente and di_direccion  = @w_op_direccion )
   from cobis..cl_cliente,
   cobis..cl_ente  CL
   where cl_det_producto   = @w_det_producto
   and cl_rol              = 'D'
   and en_ente             = cl_cliente                                         
   and cl_cliente          = @w_cliente      
   set transaction isolation level read uncommitted

   exec @w_return = sp_control_tasa
   @i_operacionca = @w_operacionca,
   @i_temporales  = 'N',
   @i_ibc         = 'N',
   @o_tasa_total_efe = @w_tasa_ef_anual  output

   if @w_return <> 0 return @w_return

   select
   @w_cliente,    @w_nombre ,           @w_ced_ruc,
   @w_direccion,  @w_telefono,          @w_toperacion_desc, 
   @w_monto,      @w_moneda_desc,       @w_plazo, 
   @w_tplazo,     @w_tipo_amortizacion, @w_tdividendo,
   @w_tasa,       @w_periodo_cap,       @w_periodo_int, 
   @w_mes_gracia, @w_gracia,            @w_gracia_cap, 
   @w_gracia_int, @w_tasa_ef_anual,     @w_fecha_fin,
   @w_dias_anio , @w_base_calculo,      @w_tasa_referencial,
   @w_valor_referencial, @w_valor_spread,@w_signo_spread,
   @w_modalidad     

end

/* DETALLE DE LA TABLA DE AMORTIZACION EN TABLAS DEFINITIVAS */

if @i_operacion = 'D' 
begin 
   /* CHEQUEO QUE EXISTA LA OPERACION */

   select 
   @w_operacionca = op_operacion
   from ca_operacion
   where op_banco = @i_banco

   if @@rowcount = 0
   begin
      select @w_error = 710026
     goto ERROR
   end  

   select @w_tamanio = round(2500/(6 + 6 + 6 + 6 +10+10+20),0) -1

   /* TABLA DE AMORTIZACION */
      /* CAPITAL */

   set rowcount @w_tamanio

   select am_dividendo,sum(am_cuota + am_gracia)
   from ca_amortizacion,ca_rubro_op 
   where 
   ro_operacion      = @w_operacionca
   and am_operacion  = ro_operacion
   and am_concepto   = ro_concepto
   and ro_tipo_rubro = 'C'
   and am_dividendo  < @i_dividendo
   group by am_dividendo
   order by am_dividendo desc 

      /* INTERES */

   set rowcount @w_tamanio

   /* SI NO EXISTE RUBRO TIPO INTERES RETORNA CEROS. AUMENTO Mar/11/1999 */ 
   if exists ( select ro_operacion from ca_rubro_op
               where ro_operacion = @w_operacionca
               and ro_tipo_rubro  = 'I' ) 

   Begin 
      select am_dividendo,sum(am_acumulado)
      from ca_amortizacion,ca_rubro_op 
      where ro_operacion = @w_operacionca
      and am_operacion   = ro_operacion
      and am_concepto    = ro_concepto
      and ro_tipo_rubro  = 'I'
      and am_dividendo   < @i_dividendo
      group by am_dividendo
      order by am_dividendo desc
   end

   else
   Begin 
      select am_dividendo,0
      from ca_amortizacion,ca_rubro_op 
      where ro_operacion = @w_operacionca
      and am_operacion   = ro_operacion
      and am_concepto    = ro_concepto
      and ro_tipo_rubro  = 'C'
      and am_dividendo   < @i_dividendo
      group by am_dividendo
      order by am_dividendo desc
   end

      /* OTROS */

   set rowcount @w_tamanio

   select am_dividendo,sum(am_cuota + am_gracia)
   from ca_amortizacion,ca_rubro_op 
   where ro_operacion = @w_operacionca
   and am_operacion   = ro_operacion
   and am_concepto    = ro_concepto
   and ro_tipo_rubro  not in ('C', 'I')
   and am_dividendo   < @i_dividendo
   group by am_dividendo
   order by am_dividendo desc

      /* ABONO */

   set rowcount @w_tamanio

   select  am_dividendo,sum(am_pagado)
   from ca_amortizacion,ca_rubro_op 
   where ro_operacion = @w_operacionca
   and am_operacion   = ro_operacion
   and am_concepto    = ro_concepto
   and am_dividendo   < @i_dividendo
   group by am_dividendo
   order by am_dividendo desc

      /* DESEMBOLSOS Y REESTRUCTURACIONES */

   set rowcount @w_tamanio

   select @w_primer_des = min(dm_secuencial)
   from   ca_desembolso
   where  dm_operacion  = @w_operacionca

   select dtr_dividendo, sum(dtr_monto)
   from   ca_det_trn, ca_transaccion, ca_rubro_op
   where  tr_banco        =  @i_banco
   and    tr_secuencial   =  dtr_secuencial
   and    tr_operacion    =  dtr_operacion
   and    dtr_secuencial  <> @w_primer_des
   and    ro_operacion    =  tr_operacion
   and    ro_operacion    =  dtr_operacion
   and    ro_tipo_rubro   =  'C'
   and    tr_tran         in ('DES', 'RES')
   and    tr_estado       in ('ING','CON')
   and    ro_concepto     =  dtr_concepto 
   and    dtr_dividendo   <  @i_dividendo
   group by dtr_dividendo
   order by dtr_dividendo desc
      

      /* FECHAS DE PAGO Y ESTADO */
   set rowcount @w_tamanio

   select 
   convert(varchar(10),di_fecha_ven,@i_formato_fecha),
   es_descripcion,
   di_dias_cuota         
   from ca_dividendo,ca_estado
   where 
   di_operacion     = @w_operacionca
   and di_estado    = es_codigo
   and di_dividendo < @i_dividendo
   --order by di_fecha_ven desc
   order by di_dividendo desc
   
   select @w_return = @@rowcount

   if @w_return = 0
   begin
      select 9999 
      select @w_error = 710026
      goto ERROR
   end
   else
   begin
      select @w_tamanio - @w_return     
   end

end


return 0

ERROR:

exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_error
return @w_error

go

