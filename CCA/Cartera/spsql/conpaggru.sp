/************************************************************************/
/*  NOMBRE LOGICO:        conpaggru.sp                                  */
/*  NOMBRE FISICO:        sp_consulta_pago_grupal                       */
/*  BASE DE DATOS:        cob_cartera                                   */
/*  PRODUCTO:             CARTERA                                       */
/*  DISENADO POR:         Guisela Fernandez                             */
/*  FECHA DE ESCRITURA:   20/Abr/2023                                   */
/************************************************************************/
/*                      IMPORTANTE                                      */
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
/*                        PROPOSITO                                     */
/*  Este programa realiza la consulta de los pagos grupales realizados  */
/*  a los prestamos grupales                                            */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*  FECHA         AUTOR             RAZON                               */
/*  20/Abr/2023  Guisela Fernandez  S785497 Emisión Inicial             */
/*  04/Jul/2023  Guisela Fernandez  Se aumenta parametro t_timeout      */
/*  12/Jul/2023  Guisela Fernandez  Ordena las operaciones por sec.     */
/************************************************************************/
use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_consulta_pago_grupal')
   drop procedure sp_consulta_pago_grupal
go

create procedure sp_consulta_pago_grupal(
   @t_trn                     int          = null,
   @i_operacion               char(1)      = 'S',
   @i_banco_grupal            cuenta       = null, 
   @i_externo                 char(1)      = 'N',
   @t_timeout                 INT          = null
)
as declare
@w_sp_name                varchar(24),
@w_error                  int,
@w_operacion_cca          int

select @w_sp_name = 'sp_consulta_pago_grupal'

select @w_operacion_cca = op_operacion 
from ca_operacion
where op_banco = @i_banco_grupal

if @@error != 0 or @@rowcount = 0
begin
   select @w_error  = 701049 --No existe Operación
   goto ERROR
end

If @i_operacion = 'S'
begin

   select 'Fecha_pago'      = convert(varchar,ab_fecha_pag, 103), 
          'Secuencial_pago' = ab_secuencial_ing,
          'Forma_pago'      = abd_concepto, 
          'Monto'           = abd_monto_mop,
          'Moneda'          = (select mo_descripcion from cobis..cl_moneda where mo_moneda = abd_moneda),		  
          'Banco'           = abd_cod_banco +' - '+ (select ba_nombre from cob_bancos..ba_banco where ba_codigo = abd_cod_banco),
          'Numero_cuenta'   = abd_cuenta, 
          'Referencia'      = abd_beneficiario
   from ca_abono,ca_abono_det
   where ab_secuencial_ing = abd_secuencial_ing
   and ab_operacion = abd_operacion
   and ab_operacion= @w_operacion_cca
   and ab_estado   = 'A'
   order by ab_secuencial_ing
   
end

return 0


ERROR:
exec cobis..sp_cerror
     @t_debug = 'N',
     @t_file  = '',
     @t_from  = @w_sp_name,
     @i_num   = @w_error

return @w_error

go
