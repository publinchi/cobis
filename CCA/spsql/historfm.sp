/************************************************************************/
/*   Nombre Fisico:       historfm.sp                                   */
/*   Nombre Logico:       sp_historicos_fin_mes                         */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        Epelaez                                       */
/*   Fecha de escritura:  Ene. 2002                                     */
/************************************************************************/
/*            IMPORTANTE                                                */
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
/*                      PROPOSITO                                       */
/*   Genera historico de las operaciones  tan pronto se hace el         */
/*      cruce de fin de mes                                             */
/************************************************************************/  
/*                       CAMBIOS                                        */
/*      FECHA         AUTOR             CAMBIOS                         */
/*   FEB-14-2002      RRB         Agregar campos al insert              */
/*                                en ca_transaccion                     */
/*   OCT-24-2005      EPB         Transaccion para pasivas si historia  */
/*                                HFP= Historico Fin Mes Pasivas        */
/*   SEP-05-2006  ELcira Pelaez   def. 7119 calificacion en null        */
/*    06/06/2023	 M. Cordova		 Cambio variable @w_calificacion,   */
/*									 de char(1) a catalogo 				*/
/************************************************************************/ 

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_historicos_fin_mes')
   drop proc sp_historicos_fin_mes
go

create proc sp_historicos_fin_mes
   @s_user                login,
   @s_date                datetime,
   @s_ofi                 smallint,
   @s_term                varchar(30),
   @i_operacionca         int,
   @i_fecha_proceso       datetime,
   @i_moneda_nacional     tinyint,
   @i_parametro_int       catalogo,
   @i_cotizacion          float,
   @i_concepto_cap        catalogo, -- FQ PARA PASAR A CALCULO DIARIO DE INTERESES
   @i_num_dec             smallint, -- FQ PARA PASAR A CALCULO DIARIO DE INTERESES
   @i_causacion           char(1), -- FQ PARA PASAR A CALCULO DIARIO DE INTERESES
   @i_fecultpro           datetime, -- FQ PARA PASAR A CALCULO DIARIO DE INTERESES
   @i_gar_admisible       char(1), -- FQ PARA PASAR A CALCULO DIARIO DE INTERESES
   @i_reestructuracion    char(1), -- FQ PARA PASAR A CALCULO DIARIO DE INTERESES
   @i_calificacion        catalogo -- FQ PARA PASAR A CALCULO DIARIO DE INTERESES

as
declare 
   @w_return            int,
   @w_banco             cuenta,
   @w_toperacion        catalogo,
   @w_oficina           smallint,
   @w_moneda            smallint,
   @w_gerente           int,
   @w_secuencial        int,
   @w_tipo              catalogo,
   @w_tipo_amortizacion catalogo,
   @w_dias_div          int,
   @w_tdividendo        catalogo,
   @w_fecha_ult_proceso datetime,
   @w_dias_anio         int,
   @w_sector            catalogo,
   @w_fecha_liq         datetime,
   @w_fecha_ini         datetime,
   @w_clausula          catalogo,
   @w_base_calculo      catalogo,
   @w_causacion         catalogo,
   @w_fecha_a_causar    datetime,
   @w_op_naturaleza     char(1),
   @w_op_fecha_ult_proceso datetime


-- DATOS DE LA OPERACION
select @w_banco               = op_banco,
       @w_toperacion          = op_toperacion,
       @w_oficina             = op_oficina,
       @w_moneda              = op_moneda,
       @w_gerente             = op_oficial,
       @w_tipo                = op_tipo,
       @w_tipo_amortizacion   = op_tipo_amortizacion,
       @w_dias_div            = op_periodo_int,
       @w_tdividendo          = op_tdividendo,
       @w_fecha_ult_proceso   = op_fecha_ult_proceso,
       @w_dias_anio           = op_dias_anio,
       @w_sector              = op_sector,
       @w_oficina             = op_oficina,
       @w_fecha_liq           = op_fecha_liq,
       @w_fecha_ini           = op_fecha_ini,
       @w_clausula            = op_clausula_aplicada,
       @w_base_calculo        = op_base_calculo,
       @w_causacion           = op_causacion,
       @w_op_naturaleza       = op_naturaleza
from   ca_operacion
where  op_operacion = @i_operacionca


exec  @w_secuencial =  sp_gen_sec
      @i_operacion  =  @i_operacionca

-- CAUSACION PASIVAS
if @w_op_naturaleza = 'P' -- PASIVAS
begin

  select @w_op_fecha_ult_proceso = op_fecha_ult_proceso
  from ca_operacion
  where op_operacion = @i_operacionca
  
  
  
   insert into ca_transaccion
         (tr_secuencial,     tr_fecha_mov,         tr_toperacion,
          tr_moneda,         tr_operacion,         tr_tran,
          tr_en_linea,       tr_banco,             tr_dias_calc,
          tr_ofi_oper,       tr_ofi_usu,
          tr_usuario,        tr_terminal,          tr_fecha_ref,
          tr_secuencial_ref, tr_estado,            tr_gerente,      
          tr_gar_admisible,  tr_reestructuracion,                   
          tr_calificacion,
          tr_observacion,    tr_fecha_cont,        tr_comprobante)  
   values(@w_secuencial,     @s_date,              @w_toperacion,
          @w_moneda,         @i_operacionca,       'HFP',
          'N',               @w_banco,             0,
          @w_oficina,        @s_ofi,
          @s_user,           @s_term,              @i_fecha_proceso,
          0,                 'NCO',                @w_gerente,         
          isnull(@i_gar_admisible,''),  
          isnull(@i_reestructuracion,''),         
          isnull(@i_calificacion,''),                                
          'HFP - HISTORICO FIN DE MES PASIVAS',    @i_fecha_proceso,
           0)
   
   if @@error !=0
      return 710001     
      
end
ELSE 
begin 
   
   exec @w_return = sp_historial
        @i_operacionca = @i_operacionca,
        @i_secuencial  = @w_secuencial
   
   if @w_return != 0
      return @w_return
   
   insert into ca_transaccion
         (tr_secuencial,     tr_fecha_mov,         tr_toperacion,
          tr_moneda,         tr_operacion,         tr_tran,
          tr_en_linea,       tr_banco,             tr_dias_calc,
          tr_ofi_oper,       tr_ofi_usu,
          tr_usuario,        tr_terminal,          tr_fecha_ref,
          tr_secuencial_ref, tr_estado,            tr_gerente,      
          tr_gar_admisible,  tr_reestructuracion,                   
          tr_calificacion,
          tr_observacion,    tr_fecha_cont,        tr_comprobante)  
   values(@w_secuencial,     @s_date,              @w_toperacion,
          @w_moneda,         @i_operacionca,       'HFM',
          'N',               @w_banco,             0,
          @w_oficina,        @s_ofi,
          @s_user,           @s_term,              @i_fecha_proceso,
          0,                 'NCO',                @w_gerente,         
          isnull(@i_gar_admisible,''),  
          isnull(@i_reestructuracion,''),         
          isnull(@i_calificacion,''),
          'HFA - HISTORICO FIN DE MES ACTIVAS',    @i_fecha_proceso,
          0)
   
   if @@error !=0
      return 710001  
end 


return 0

go


