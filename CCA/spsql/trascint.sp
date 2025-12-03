/************************************************************************/
/*  Nombre Fisico:       trascint.sp                                    */
/*  Nombre Logico:       sp_traslada_cartera_int                        */
/*  Base de datos:       cob_cartera                                    */
/*  Producto:            Cartera                                        */
/*  Disenado por:        Julio Cesar Quintero D.                        */
/*  Fecha de escritura:  18/Diciembre/2002                              */
/************************************************************************/
/*                        IMPORTANTE                                    */
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
/*                        PROPOSITO                                     */
/*  Traslada una operacion hacia una nueva oficina. Para ello modifica  */
/*  la nueva oficina y realiza el movimiento contable.                  */
/*                                                                      */
/************************************************************************/  
/*    FECHA            AUTOR                 COMENTARIOS                */
/*    06/06/2023	 M. Cordova		  Cambio variable @w_calificacion   */
/*									  de char(1) a catalogo				*/
/************************************************************************/

use cob_cartera
go 
if exists (select 1 from sysobjects where name = 'sp_traslada_cartera_int')
   drop proc sp_traslada_cartera_int
go

create proc  sp_traslada_cartera_int(
   @s_user              login,      
   @s_term              varchar(30),
   @s_date              datetime,   
   @s_ofi               int,
   @i_cliente           int,    
   @i_operacionca       int,
   @i_fecha_proceso     datetime,
   @i_oficina_origen    int, 
   @i_oficina_destino   int,
   @i_secuencial_trn    int,
   @i_oficial_destino   smallint
)
as declare
   @w_sp_name              varchar(32),
   @w_return               int,
   @w_error                int,
   @w_operacionca          int,
   @w_dividendo            int,
   @w_toperacion           catalogo,
   @w_moneda               smallint, 
   @w_moneda_nac           smallint, 
   @w_gerente              smallint, 
   @w_oficina_or           smallint,
   @w_est_suspenso         int,
   @w_estado_op            int,
   @w_calificacion         catalogo,
   @w_garantia             char(1),
   @w_reestructuracion     char(1),
   @w_est_novigente        tinyint,
   @w_est_cancelado        tinyint,
   @w_est_credito          tinyint,
   @w_est_castigado        tinyint,
   @w_est_anulado          tinyint,
   @w_banco                cuenta,
   @w_ciudad               int,
   @w_oficina_antes        varchar(20),
   @w_oficina_despues      varchar(20)

/* Captura nombre de Stored Procedure  */
select	
@w_sp_name       = 'sp_traslada_cartera_int'

/* ESTADOS DE CARTERA */
exec @w_error = sp_estados_cca
@o_est_novigente  = @w_est_novigente out,
@o_est_cancelado  = @w_est_cancelado out,
@o_est_castigado  = @w_est_castigado out,
@o_est_anulado    = @w_est_anulado   out,
@o_est_credito    = @w_est_credito   out

select @w_oficina_antes = convert(varchar(20),@i_oficina_origen)
select @w_oficina_despues = convert(varchar(20),@i_oficina_destino)

/*** PARAMETRO DE MONEDA NACIONAL */
select @w_moneda_nac = pa_tinyint
from cobis..cl_parametro
where pa_producto = 'ADM'
and pa_nemonico = 'MLO'
set transaction isolation level read uncommitted

select 
@w_operacionca      = op_operacion, 
@w_banco            = op_banco,
@w_moneda           = op_moneda,
@w_toperacion       = op_toperacion, 
@w_oficina_or       = op_oficina,
@w_estado_op        = op_estado,
@w_calificacion     = op_calificacion,
@w_gerente          = op_oficial,
@w_garantia         = op_gar_admisible,
@w_reestructuracion = op_reestructuracion
from  ca_operacion
where op_operacion = @i_operacionca

--- TRANSACCION CONTABLE PARA ESTADO DIF A: 9, 0, 3, 6, 4, novedades y comext no existen en ca_estado
--- if @w_estado_op not in (@w_est_credito,@w_est_novigente,@w_est_cancelado,@w_est_anulado,@w_est_castigado) begin
    if @w_estado_op not in (@w_est_credito,@w_est_novigente,@w_est_cancelado,@w_est_anulado) begin
   exec @w_return              = sp_traslado_ofic
        @s_user		           = @s_user,
        @s_term		           = @s_term,
        @s_date		           = @s_date,
        @s_ofi		           = @s_ofi,
        @i_trn                 = 'TCO',
        @i_toperacion          = @w_toperacion,
        @i_oficina             = @w_oficina_or,
        @i_banco               = @w_banco,
        @i_operacionca         = @w_operacionca,
        @i_moneda              = @w_moneda,
        @i_fecha_proceso       = @i_fecha_proceso,
        @i_gerente             = @w_gerente,
        @i_moneda_nac	       = @w_moneda_nac,
        @i_garantia            = @w_garantia,
        @i_reestructuracion    = @w_reestructuracion,
        @i_cuenta_final        = @w_oficina_despues,
        @i_cuenta_antes        = @w_oficina_antes,
        @i_calificacion        = @w_calificacion,
        @i_estado_actual       = @w_estado_op,
        @i_secuencial          = @i_secuencial_trn

   if @w_return != 0  
      return @w_return

   --- GENERACION DE HISTORICOS ANTES DE HACER LOS CAMBIOS 
   exec @w_return = sp_historial
   @i_operacionca = @w_operacionca,
   @i_secuencial  = @i_secuencial_trn

   if @w_return != 0  
      return @w_return
end

--- SELECCIONO LA CIUDAD A LA QUE PERTENECE LA OFICINA 
select @w_ciudad = of_ciudad
from   cobis..cl_oficina
where  of_filial  = 1
and    of_oficina = @i_oficina_destino
set transaction isolation level read uncommitted

--- ACTUALIZACION OFICINA TABLA BASICA 
update ca_operacion set
op_oficina  = @i_oficina_destino,
op_oficial  = @i_oficial_destino,
op_ciudad   = @w_ciudad
where op_operacion = @w_operacionca

if @@error != 0 begin
   PRINT 'trasint.sp EN ca_operacion @i_oficina_destino ' + cast(@i_oficina_destino as varchar) + ', @w_ciudad '  + cast(@w_ciudad as varchar)
   return 710002
end

return 0
go

