/************************************************************************/
/*	Nombre Fisico:				cuenta.sp                              	*/
/*	Nombre Logico:				sp_cuenta                              	*/
/*	Base de Datos:				cob_cartera                            	*/
/*	Producto:					Cartera	                               	*/
/*	Disenado por:				FDLT                                   	*/
/*	Fecha de Documentacion: 	30/04/2004                             	*/
/************************************************************************/
/*                           IMPORTANTE		       		               	*/
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
/*	                      PROPOSITO				                       	*/
/*	Busca la cuenta contable en que se contabilizar¡a el rubro.        	*/
/*    06/06/2023	 M. Cordova		 Cambio variable @i_calificacion,   */
/*									 de char(1) a catalogo 				*/
/************************************************************************/


use cob_cartera
go 

if exists (select 1 from sysobjects where name = 'sp_cuenta')
   drop proc sp_cuenta
go

create proc sp_cuenta
   @i_debug           char(1)     = 'N',
   @i_parametro       varchar(10) = null,
   @i_moneda          int         = null,
   @i_sector          varchar(10) = null,
   @i_maduracion      varchar(10) = null,
   @i_producto        smallint    = null,
   @i_gar_admisible   varchar(1)  = null,
   @i_calificacion    catalogo  = null,
   @i_clase_cart      varchar(1)  = null,
   @i_clase_cust      varchar(1)  = null,
   @i_concepto        varchar(20) = null,
   @i_estado          int         = null,
   @i_categoria       varchar(2)  = null,
   @i_tipo_empresa    varchar(10) = null,
   @i_toperacion      varchar(10) = null,
   @i_cta_banco       cuenta      = null,
   @o_cuenta          varchar(24) = null  out,
   @o_evitar_asiento  char(1)     = null  out,
   @o_msg             varchar(100)= null  out

as
declare
   @w_clave           varchar(255),
   @w_stored          cuenta,
   @w_concepto2       char(1)

/* INICIO VARIABLES */
select 
@o_cuenta         = '',
@w_clave          = '',
@i_sector         = ltrim(rtrim(@i_sector)),
@i_maduracion     = ltrim(rtrim(@i_maduracion)),
@i_moneda         = isnull(@i_moneda, 0),
@i_parametro      = isnull(@i_parametro,'')


select @w_stored = pa_stored
from cob_conta..cb_parametro
where pa_empresa     = 1
and   pa_parametro   = @i_parametro
--and   pa_producto    = 7              --LAZG Campo no Existe en esta version Jul 25 2008

if @@rowcount = 0 begin
   select @o_msg = 'NO SE ENCUENTRA EL PARAMETRO:' + @i_parametro + ' EN LA TABLA cb_parametro'
   return 141009
end

if @i_debug = 'S'
begin
   print '----> cuenta.sp '
   print '----> cuenta. parametro ' + @i_parametro
   print '----> cuenta. stored ' + @w_stored
end


select @w_concepto2 = case @i_concepto
when 'CAP' then '1'
when 'INT' then '2'
else '5'
end

select @w_clave = case @w_stored
when 'sp_ca01_pf'            then @i_calificacion +'.'+ @i_clase_cust +'.'+ @i_clase_cart +'.'+convert(varchar,@i_moneda)
when 'sp_ca02_pf'            then @i_calificacion +'.'+ @i_clase_cart +'.'+convert(varchar,@i_moneda) 
when 'sp_ca03_pf'            then @i_clase_cart +'.'+convert(varchar,@i_moneda)
when 'sp_ca04_pf'            then convert(varchar,@i_moneda)
when 'sp_ca05_pf'            then @i_toperacion
when 'sp_ca06_pf'            then @i_cta_banco
when 'sp_pf_ca01'            then convert(varchar,@i_moneda)
when 'sp_pf_ca02'            then @i_clase_cart +'.' + @i_clase_cust
when 'sp_pf_ca03'            then @i_clase_cart +'.' + @i_calificacion
when 'sp_pf_ca04'            then @i_clase_cart +'.' + @i_calificacion +'.' + @i_clase_cust
when 'sp_pf_ca05'            then @i_clase_cart 
when 'sp_pf_ca06'            then @i_calificacion 
when 'sp_pf_ca07'            then @i_concepto
when 'sp_pf_ca08'            then @i_clase_cart +'.' + @i_calificacion +'.' + @i_concepto
when 'sp_pf_ca09'            then @i_clase_cust
when 'sp_pf_ca10'            then @i_clase_cart +'.' + @i_concepto
when 'sp_pf_ca11'            then @i_concepto + '.' + @i_clase_cart
when 'sp_pf_ca12'            then convert(varchar,@i_estado) +'.' + @i_concepto
when 'sp_pf_ca13'            then @i_categoria
when 'sp_pf_ca14'            then convert(varchar,@i_estado) + '.' + @i_clase_cart
when 'sp_pf_ca15'            then @i_clase_cart + '.' + convert(varchar,@i_moneda)
when 'sp_contabilidad_bco'   then @i_tipo_empresa 
when 'sp_contabilidad_ccga'  then @i_clase_cart + '.' + @i_calificacion + '.' + @i_clase_cust
when 'sp_contabilidad_ccgp'  then @i_clase_cart
when 'sp_contabilidad_cxc'   then @i_clase_cart + '.' + @i_calificacion + '.' + @w_concepto2
when 'sp_contabilidad_opro'  then @w_concepto2
when 'sp_contabilidad_ruin'  then @w_concepto2
when 'sp_contabilidad_tmp'   then @w_concepto2 + '.' +  @i_maduracion + '.' +  @i_clase_cust 
else '' 
end

select @o_cuenta = isnull(rtrim(ltrim(re_substring)), '')
from cob_conta..cb_relparam
where re_empresa             = 1
and   re_parametro           = @i_parametro
and   ltrim(rtrim(re_clave)) = @w_clave
--and   re_producto            = @i_producto    --LAZG Campo no Existe en esta version Jul 25 2008
   
if @o_cuenta = ''
   select @o_evitar_asiento = 'S'
else
   select @o_evitar_asiento = 'N'

if @i_debug = 'S'
begin
   print '   @i_parametro:      ' + @i_parametro
   print '   @w_clave:          ' + @w_clave
   print '   @w_stored:         ' + @w_stored
   print '   @o_cuenta:         ' + @o_cuenta 
   print '   @o_evitar_asiento: ' + @o_evitar_asiento
   print '--> Fin cuenta.sp '
end
	

return 0

go



/*prueba

declare 
@w_cuenta         cuenta,
@w_evitar_asiento char(1),
@w_error          int,
@w_msg            varchar(100)

exec @w_error = sp_cuenta
@i_parametro      = 'CAP_ACT',
@i_moneda         = 0,
@i_sector         = 'C',
@i_maduracion     = 'M_PV01',
@o_cuenta         = @w_cuenta out,
@o_evitar_asiento = @w_evitar_asiento out,
@o_msg            = @w_msg out

if @w_error <> 0 
begin
   print '   ERROR: ' + cast(@w_error as varchar)
   select @w_msg
end

select cta = @w_cuenta, evitar = @w_evitar_asiento

select * from cob_conta..cb_relparam
where re_tipo_area = "ALFREDO"



delete cob_conta..cb_relparam
where re_clave = 'RAFAEL'


cob_cartera..sp_texto 

*/