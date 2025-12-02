/************************************************************************/
/*   NOMBRE LOGICO:      sp_consulta_abono_atx                          */
/*   NOMBRE FISICO:      conaboatx.sp                                   */
/*   BASE DE DATOS:      cob_cartera                                    */
/*   PRODUCTO:           Cartera                                        */
/*   DISENADO POR:       Erika A. Alvarez                               */
/*   FECHA DE ESCRITURA: Marzo 2009                                     */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada; y por lo tanto, derivará en acciones legales civiles      */
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Consulta la aplicacion de un abono realizado por ATX            */
/************************************************************************/
/*                              CAMBIOS                                 */
/* FECHA              AUTOR                  CAMBIOS                    */
/* 02/jun/2009     Jonnatan Peña       Envio de parametros al timbre de */
/*  				       pago                                         */
/* 27/feb/2012     Luis Carlos Moreno  Adicion vlr rec a recibo de pago */
/* 15/mar/2023     Kevin Rodríguez     S795163 Consulta de un abono para*/
/*                                     un pago grupal                   */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_consulta_abono_atx')
   drop proc sp_consulta_abono_atx
go

---Cambiado ult.oct-27-2008 manjose sobrante
create proc sp_consulta_abono_atx
   @s_sesn                    int          = NULL,
   @s_ssn                     int          = null,
   @s_user                    login        = NULL,
   @s_date                    datetime     = NULL,
   @s_ofi                     smallint     = NULL,
   @s_term                    varchar (30) = NULL,
   @s_srv                     varchar (30) = '',
   @s_lsrv                    varchar (30) = null,
   @i_secuencial_ing          int,                     -- En abono grupal, este es el secuencial de registro OP Padre.
   @i_operacionca             int,
   @i_en_linea                char(1)      = 'S',
   @i_total                   money        = null,
   @o_monto_cap               money        = null out,
   @o_monto_int               money        = null out,
   @o_monto_iva               money        = null out,
   @o_monto_mpy               money        = null out,
   @o_monto_imo               money        = null out,
   @o_monto_sgd               money        = null out,
   @o_monto_otr               money        = null out,
   @o_numcuotas_can           smallint     = null out,
   @o_numtot_cuotas           smallint     = null out,
   @o_tramite                 int          = null out,
   @o_oficial                 varchar(12)  = null out,
   @o_cedula                  varchar(60)  = null out,
   @o_des_fuente              varchar(20)  = null out,
   @o_oficina                 smallint     = null out
     
as
declare
   @w_error                   int,
   @w_banco                   cuenta,
   @w_cliente                 int,
   @w_cedruc                  varchar(15),
   @w_sec_pag                 int,
   @w_monto_cap               money,
   @w_monto_int               money,
   @w_monto_iva               money,
   @w_monto_mpy               money,
   @w_monto_imo               money,
   @w_monto_sgd               money,
   @w_monto_otr               money,
   @w_numcuotas_can           smallint,
   @w_numtot_cuotas           smallint,
   @w_tramite                 int,
   @w_nombre                  varchar(60),
   @w_fuente                  varchar(10),
   @w_des_fuente              varchar(20),
   @w_oficina                 smallint,
   @w_oficial                 varchar(12),
   @w_cadena                  varchar(250),
   @w_lon_cadena              smallint,
   @w_contador                smallint,
   @w_letra                   char(1),
   @w_pmipymes                catalogo,
   @w_ivamipymes              catalogo,
   @w_segdeven                catalogo,
   @w_sobrante                money,
   @w_otros                   money,  
   @w_fecha_pag        		  datetime, 
   @w_secuencial_pag   		  int,
   @w_monto_cap_rec           money, -- LCM - 293
   @w_tipo_grupal             char(1)

  
select @w_pmipymes = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'MIPYME'

select @w_ivamipymes = pa_char
from   cobis..cl_parametro  with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'IVAMIP'

select @w_segdeven = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'SEDEVE'

select @w_banco = op_banco from ca_operacion
where op_operacion = @i_operacionca 

-- TIPO DE OPERACIÓN -- Grupal Padre(G), Grupal Hija(H), Individual(N)
exec @w_error = sp_tipo_operacion
     @i_banco  = @w_banco,
     @o_tipo   = @w_tipo_grupal out

if @w_error <> 0
   return @w_error
   

if @w_tipo_grupal = 'G' -- Obtiene valores sumarizados de sus OPs hijas.
begin

   select @w_monto_cap = sum(ar_monto) 
   from ca_operacion, ca_abono_rubro, ca_abono, ca_concepto
   where op_ref_grupal                = @w_banco
   and ab_operacion                   = op_operacion
   and ab_secuencial_ing_abono_grupal = @i_secuencial_ing
   and ab_operacion                   = ar_operacion
   and ab_secuencial_pag              = ar_secuencial
   and ar_dividendo                   <> -1
   and ar_concepto                    = co_concepto
   and co_categoria                   = 'C'

   select @w_monto_int = sum(ar_monto) 
   from ca_operacion, ca_abono_rubro, ca_abono, ca_concepto
   where op_ref_grupal                = @w_banco
   and ab_operacion                   = op_operacion
   and ab_secuencial_ing_abono_grupal = @i_secuencial_ing
   and ab_operacion                   = ar_operacion
   and ab_secuencial_pag              = ar_secuencial
   and ar_dividendo                   <> -1
   and ar_concepto                    = co_concepto
   and co_categoria                   = 'I'

   select @w_monto_imo = sum(ar_monto) 
   from ca_operacion, ca_abono_rubro, ca_abono, ca_concepto
   where op_ref_grupal                = @w_banco
   and ab_operacion                   = op_operacion
   and ab_secuencial_ing_abono_grupal = @i_secuencial_ing
   and ab_operacion                   = ar_operacion
   and ab_secuencial_pag              = ar_secuencial
   and ar_dividendo                   <> -1
   and ar_concepto                    = co_concepto
   and co_categoria                   = 'M' 
   
   select @w_otros = sum(ar_monto) 
   from ca_operacion, ca_abono_rubro, ca_abono, ca_concepto
   where op_ref_grupal                = @w_banco
   and ab_operacion                   = op_operacion
   and ab_secuencial_ing_abono_grupal = @i_secuencial_ing
   and ab_operacion                   = ar_operacion
   and ab_secuencial_pag              = ar_secuencial
   and ar_dividendo                   <> -1
   and ar_concepto                    = co_concepto
   and co_categoria                   not in ('C','I','M') 
   
   select @w_sobrante = sum(abd_monto_mpg) 
   from ca_operacion, ca_abono, ca_abono_det
   where op_ref_grupal                = @w_banco
   and ab_operacion                   = op_operacion
   and ab_secuencial_ing_abono_grupal = @i_secuencial_ing
   and ab_operacion                   = abd_operacion
   and ab_secuencial_ing              = abd_secuencial_ing
   and abd_tipo                       = 'SOB'

   if @@rowcount = 0
      select @w_sobrante = 0

end
else
begin

   select @w_sec_pag = ab_secuencial_pag   
   from   ca_abono
   where  ab_operacion = @i_operacionca
   and    ab_secuencial_ing = @i_secuencial_ing
   
   select @w_monto_cap     = sum(ar_monto)
   from   ca_abono_rubro 
   where  ar_operacion  = @i_operacionca
   and    ar_secuencial = @w_sec_pag 
   and    ar_concepto = 'CAP'
   and    ar_dividendo  <> -1
   
   /* LCM - 293 - OBTIENE EL VALOR ABONADO A CAPITAL DEL RECONOCIMIENTO EN CASO QUE EXISTA */
   /* BUSCA EN LA TABLA DE CORRESPONDENCIA LOS CODIGOS VALOR ASOCIADOS A RECONOCIMIENTO */
   select @w_monto_cap_rec = 0
   select @w_monto_cap_rec = sum(dtr_monto)
   from ca_det_trn with (nolock)
   where dtr_operacion = @i_operacionca
   and   dtr_secuencial = @w_sec_pag
   and   dtr_concepto = 'CAP'
   and   dtr_codvalor in (select limite_sup
                          from cob_credito..cr_corresp_sib with (nolock)
                          where tabla = 'T143')
						  
   if @w_monto_cap_rec is not null
      select @w_monto_cap = @w_monto_cap + @w_monto_cap_rec
						  					  
   select @w_monto_int     = sum(ar_monto)
   from   ca_abono_rubro 
   where  ar_operacion  = @i_operacionca
   and    ar_secuencial = @w_sec_pag 
   and    ar_concepto   = 'INT'
   and    ar_dividendo  <> -1
   
   select @w_monto_iva     = sum(ar_monto)
   from   ca_abono_rubro 
   where  ar_operacion  = @i_operacionca
   and    ar_secuencial = @w_sec_pag 
   and    ar_concepto   = @w_ivamipymes
   and    ar_dividendo  <> -1
   
   select @w_monto_mpy     = sum(ar_monto)
   from   ca_abono_rubro 
   where  ar_operacion  = @i_operacionca
   and    ar_secuencial = @w_sec_pag 
   and    ar_concepto   = @w_pmipymes
   and    ar_dividendo  <> -1
   
   select @w_monto_imo     = sum(ar_monto)
   from   ca_abono_rubro 
   where  ar_operacion  = @i_operacionca
   and    ar_secuencial = @w_sec_pag 
   and    ar_concepto = 'IMO'
   and    ar_dividendo  <> -1
   
   select @w_monto_sgd     = sum(ar_monto)
   from   ca_abono_rubro 
   where  ar_operacion  = @i_operacionca
   and    ar_secuencial = @w_sec_pag 
   and    ar_concepto = @w_segdeven
   and    ar_dividendo  <> -1
   
   select @w_otros     = sum(ar_monto)
   from   ca_abono_rubro 
   where  ar_operacion  = @i_operacionca
   and    ar_secuencial = @w_sec_pag 
   and    ar_concepto not in(@w_pmipymes, @w_ivamipymes, @w_segdeven, 'INT', 'CAP', 'IMO')
   and    ar_dividendo  <> -1
   
   select @w_sobrante = abd_monto_mpg
   from ca_abono, ca_abono_det
   where ab_secuencial_ing = abd_secuencial_ing 
   and abd_operacion = ab_operacion 
   and abd_operacion = @i_operacionca
   and ab_secuencial_pag = @w_sec_pag
   and abd_tipo  = 'SOB'

   if @@rowcount = 0
      select @w_sobrante = 0
   
end        

if @w_otros is null
   select  @w_otros  = 0
   
if @w_sobrante is null
   select  @w_sobrante  = 0
 
--Maximo dividendo cancelado -- jpe
select 
@w_fecha_pag = max(ab_fecha_pag)
from ca_abono
where ab_operacion = @i_operacionca
and   ab_estado    = 'A'

select 
@w_secuencial_pag = max(ab_secuencial_pag)
from ca_abono
where ab_operacion = @i_operacionca
and  ab_fecha_pag = @w_fecha_pag  

select 
@w_numcuotas_can  = count(1)
from  ca_dividendo
where di_operacion  = @i_operacionca
and   di_estado     = 3

if @w_numcuotas_can is null
   select @w_numcuotas_can  = 0
 
select 
@w_numtot_cuotas  = count(1)
from  ca_dividendo
where di_operacion  = @i_operacionca
   
select 
@w_cliente     = op_cliente,
@w_tramite     = op_tramite,
@w_oficial     = fu_login,
@w_oficina     = op_oficina
from cob_cartera..ca_operacion, cobis..cl_funcionario,
cobis..cc_oficial
where op_operacion = @i_operacionca
and   oc_funcionario = fu_funcionario
and   oc_oficial = op_oficial

select 
@w_cedruc      = en_ced_ruc
from cobis..cl_ente
where en_ente = @w_cliente


 
select 
@w_fuente = tr_fuente_recurso
from cob_credito..cr_tramite
where tr_tramite = @w_tramite 

if @@rowcount <> 0
begin
select 
@w_des_fuente = valor
from cobis..cl_tabla a, cobis..cl_catalogo b
where a.tabla = 'cr_fuente_recurso'
and   a.codigo = b.tabla
and   b.codigo = @w_fuente
end
else
   select @w_des_fuente = 'NA'
   
select @w_monto_otr = (@w_otros + @w_sobrante)

select 
@o_monto_cap     = isnull(@w_monto_cap, 0),
@o_monto_int     = isnull(@w_monto_int, 0),
@o_monto_iva     = isnull(@w_monto_iva, 0),
@o_monto_mpy     = isnull(@w_monto_mpy, 0),
@o_monto_imo     = isnull(@w_monto_imo, 0),
@o_monto_sgd     = isnull(@w_monto_sgd, 0),
@o_monto_otr     = isnull(@w_monto_otr, 0),
@o_numcuotas_can = @w_numcuotas_can,
@o_numtot_cuotas = @w_numtot_cuotas,
@o_tramite       = @w_tramite,
@o_oficial       = @w_oficial,
@o_cedula        = @w_cedruc,
@o_des_fuente    = @w_des_fuente,
@o_oficina       = @w_oficina       

return 0

go
