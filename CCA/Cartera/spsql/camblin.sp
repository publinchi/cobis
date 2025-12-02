/************************************************************************/
/*   Nombre Fisico:       camblin.sp                                    */
/*   Nombre Logico:    	  sp_cambio_linea                               */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        Xma                                           */
/*   Fecha de escritura:  Feb. 2003                                     */
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
/*                                PROPOSITO                             */
/*   Cambio del tipo de linea de credito (op_toperacion)                */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*      FECHA          AUTOR          CAMBIO                            */
/*      NOV-2005       Elcira Pelaez  Cambios para el BAC  def. 5215    */
/*      MAR-2006       Elcira Pelaez  Cambios para el BAC  def. 6191    */
/*      ABR-2023    Guisela Fernandez S807925 Ingreso de campo de       */
/*                                    reestructuracion                  */
/*    06/06/2023	 M. Cordova		  Cambio variable @w_calificacion   */
/*									  de char(1) a catalogo				*/
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_cambio_linea')
   drop proc sp_cambio_linea
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

create proc sp_cambio_linea
   @s_user         login,
   @s_term         varchar(30),
   @s_date         datetime,
   @s_ofi         smallint,
   @s_sesn            int      = null,
   @i_operacionca     int,
   @i_toperacion      catalogo

as declare 
   @w_est_cancelado    tinyint, 
   @w_banco            cuenta,
   @w_secuencial       int,
   @w_return           int,
   @w_dt_naturaleza    char(1),
   @w_moneda           smallint,
   @w_moneda_nac       smallint,
   @w_oficina_op       smallint,
   @w_dt_tipo          char(1),
   @w_dt_tipo_linea    catalogo,
   @w_fecha_proceso    datetime,
   @w_gerente          smallint,
   @w_dt_subtipo_linea catalogo,
   @w_calificacion     catalogo,
   @w_gar_admisible    char(1),
   @w_op_estado        tinyint,
   @w_op_pasiva        int,
   @w_ro_concepto      catalogo,
   @w_ro_tipo_rubro    char(1),
   @w_am_estado        tinyint,
   @w_num_dec          tinyint,
   @w_num_dec_mn       tinyint,
   @w_dividendo        smallint,
   @w_error            int,
   @w_am_periodo       tinyint,
   @w_monto            money,
   @w_codvalor         int,
   @w_monto_mn         money,
   @w_cot_mn           money,
   @w_toperacion_ant   catalogo,
   @w_observacion      char(62),
   @w_li_numero        int,
   @w_op_lin_credito   cuenta,
   @w_op_tipo          char(1),
   @w_reestructuracion     char(1)


   

--- VARIABLES DE TRABAJO 
select @w_est_cancelado  = 3

-- DATOS DE LA OPERACION 
select 
@w_banco             = op_banco,
@w_moneda            = op_moneda,
@w_oficina_op        = op_oficina,
@w_fecha_proceso     = op_fecha_ult_proceso,
@w_gerente           = op_oficial,
@w_gar_admisible     = op_gar_admisible,
@w_calificacion      = op_calificacion,
@w_toperacion_ant    = op_toperacion,
@w_op_lin_credito    = op_lin_credito,
@w_op_tipo           = op_tipo,
@w_reestructuracion  = isnull(op_reestructuracion, 'N')
from ca_operacion 
where op_operacion  = @i_operacionca

if @@rowcount = 0 
return 701025

--- VERIFICAR DE QUE NO EXISTAN OP.PASIVAS SIN CANCELAR 


declare op_pasivas_canceladas cursor for 
 select rp_pasiva
   from ca_relacion_ptmo
  where rp_activa = @i_operacionca
  and   @w_op_tipo = 'C'
    for read only

  open op_pasivas_canceladas

  fetch op_pasivas_canceladas into 
  @w_op_pasiva

  while @@fetch_status = 0 
  begin -- WHILE CURSOR RUBROS 

     if (@@fetch_status = -1) return 710004

     select 
     @w_op_estado       = op_estado
     from ca_operacion 
     where op_operacion = @i_operacionca


     if @w_op_estado = @w_est_cancelado
        begin
           update ca_operacion
           set op_margen_redescuento = 0
           where op_operacion = @w_op_pasiva

        end


     if @w_op_estado <> @w_est_cancelado
        begin
           print 'camlin.sp  ....operacion pasiva debe estar cancelada'
           return 701025
        end

     fetch op_pasivas_canceladas into 
     @w_op_pasiva

  end --- WHILE RUBROS 

close op_pasivas_canceladas
deallocate op_pasivas_canceladas

--VALIDACION QUE EL CUPO PERTENEZCA A LA LINEA

if @w_op_lin_credito is not null and @w_op_lin_credito <> ''
begin
      select @w_li_numero = li_numero
      from   cob_credito..cr_linea --(index cr_linea_BKey)
      where   li_num_banco = @w_op_lin_credito


   if not exists (select  1  from cob_credito..cr_lin_ope_moneda
                  where om_linea =  @w_li_numero
                  and om_toperacion = @i_toperacion
                  and om_producto = 'CCA'
                  and om_moneda = 0 )
                  return 2101120
 
   
end


--- OBTENER RESPALDO ANTES DEL CAMBIO DE ESTADO 
exec @w_secuencial = sp_gen_sec
@i_operacion       = @i_operacionca

exec @w_return    = sp_historial
@i_operacionca    = @i_operacionca,
@i_secuencial     = @w_secuencial
if @w_return != 0 
   return @w_return

-- SELECCION DE LOS DATOS DE LA LINEA DE CREDITO
select 
@w_dt_naturaleza    = dt_naturaleza, 
@w_dt_tipo          = dt_tipo,       
@w_dt_tipo_linea    = dt_tipo_linea, 
@w_dt_subtipo_linea = dt_subtipo_linea 
from ca_default_toperacion
where dt_toperacion = @i_toperacion



--- ACTUALIZACION DE LOS DATOS DE LA OPERACION

update ca_operacion
set
op_toperacion         = @i_toperacion,
op_tipo               = @w_dt_tipo,
op_tipo_linea         = @w_dt_tipo_linea,
op_subtipo_linea      = @w_dt_subtipo_linea,
op_naturaleza         = @w_dt_naturaleza,
op_codigo_externo     = null,
op_margen_redescuento = 100
where op_operacion = @i_operacionca


select @w_observacion = 'CABIO DE LA LINEA ' +  @w_toperacion_ant + '  por ' + @i_toperacion

-- PARTE CONTABLE 
insert into ca_transaccion (
       tr_secuencial,       tr_fecha_mov,       tr_toperacion,
       tr_moneda,           tr_operacion,       tr_tran,
       tr_en_linea,         tr_banco,           tr_dias_calc,
       tr_ofi_oper,         tr_ofi_usu,         tr_usuario,
       tr_terminal,         tr_fecha_ref,       tr_secuencial_ref,
       tr_estado,           tr_observacion,     tr_gerente,
       tr_comprobante,      tr_fecha_cont,      tr_gar_admisible,
       tr_reestructuracion, tr_calificacion)
values (
       @w_secuencial,       @s_date,            @i_toperacion,
       @w_moneda,           @i_operacionca,     'CLI',  
       'N',                 @w_banco,           1,
       @w_oficina_op,       @s_ofi,             @s_user,
       @s_term,             @w_fecha_proceso,   0,
       'NCO',               @w_observacion,     @w_gerente,
       0,                   '',                isnull(@w_gar_admisible,''),
       @w_reestructuracion, isnull(@w_calificacion,''))



return 0

go
 