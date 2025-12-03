/************************************************************************/
/*   Nombre Fisico       :       desembolpar.sp                         */
/*   Nombre Logico       :       sp_desembolso_parcial                  */
/*   Base de datos       :       cob_cartera                            */
/*   Producto            :       Cartera                                */
/*   Disenado por        :       Elcira Pelaez                          */
/*   Fecha de escritura  :       Jul 95                                 */
/************************************************************************/
/*                                IMPORTANTE                            */
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
/*                                 PROPOSITO                            */
/*   Este programa da mantenimiento a la tabla de desembolsos de        */
/*   una operacion de Cartera despues de estar vigente desembolsos par- */
/*   ciales                                                             */
/*   I: Insercion del desembolso                                        */
/*   D: Eliminacion del desembolso                                      */
/*   S: Search del desembolso                                           */
/************************************************************************/
/*                              MODIFICACIONES                          */
/* ULT:ACT:03AGO2006                                                    */
/*  FECHA          AUTOR             RAZON                              */
/*  23/abr/2010  Fdo Carvajal    Interfaz Ahorros-CCA                   */
/*  25-09-20     Sandro Vallejo  Considerar API                         */
/*  06-11-20     EMP-JJEC        Desembolsos Parciales                  */
/*    06/06/2023	 M. Cordova		  Cambio variable @w_calificacion   */
/*									  de char(1) a catalogo				*/
/************************************************************************/
use cob_cartera
go

set ansi_nulls off
go


if exists (select 1 from sysobjects where name = 'sp_desembolso_parcial')
   drop proc sp_desembolso_parcial
go

create proc sp_desembolso_parcial
   @s_culture           varchar(10)  = 'NEUTRAL',  --Internacionalizacion
   @s_ssn               int          = null,
   @s_srv               varchar (30) = null,
   @s_lsrv              varchar (30) = null,
   @s_rol               tinyint      = null,
   @s_sesn              int          = null,
   @s_date              datetime,
   @s_user              login        = null,
   @s_term              varchar(30)  = null,
   @s_ofi               smallint     = null,
   @s_org               char(1)      = null,
   @i_operacion         char(1),
   @i_banco_real        cuenta,
   @i_banco_ficticio    cuenta,
   @i_secuencial        int          = null,
   @i_desembolso        tinyint      = null,
   @i_producto          catalogo     = '',
   @i_cuenta            cuenta       = '',
   @i_oficina_chg       int          = 0,
   @i_beneficiario      descripcion  = '',
   @i_monto_ds          money        = null,
   @i_moneda_ds         smallint     = null,
   @i_cotiz_ds          money        = null,
   @i_tcotiz_ds         char(1)      = null,
   @i_moneda_op         tinyint      = null,
   @i_cotiz_op          money        = null,
   @i_tcotiz_op         char(1)      = null,
   @i_pasar_tmp         char(1)      = null,
   @i_formato_fecha     int          = 101,
   @i_consulta          char(1)      = null,
   @i_capitalizacion    char(1)      = 'N',
   @i_operacion_ach     char(1)      = null,
   @i_nom_producto      char(3)      = null,
   @i_cod_banco_ach     int          = null,
   @i_desde_cre         char(1)      = null,
   @i_cheque            int          = null,
   @i_prenotificacion   int          = null,
   @i_carga             int          = null,
   @i_concepto          varchar(255) = null,
   @i_fecha_liq         datetime     = null, 
   @i_fecha_proceso     datetime     = null, -- SVA Considerara API
   @i_parcial           char(1)      = 'S',
   @o_respuesta         char(1)      = null out,
   @o_secuencial        descripcion  = null out
as
declare   
   @w_sp_name           varchar(30),
   @w_error             int,
   @w_operacionca       int,
   @w_secuencial        int,
   @w_desembolso        int,
   @w_num_dec_mn        tinyint,
   @w_num_dec_op        tinyint,
   @w_num_dec_ds        tinyint,
   @w_op_monto          float,
   @w_monto_op          money,
   @w_monto_mn          money,
   @w_dividendo         smallint,
   @w_fecha_proceso     datetime,
   @w_instrucciones     char(1),
   @w_tramite           int,
   @w_fecha_ini_oper    datetime,
   @w_moneda_local      smallint, 
   @w_convertir_valor   char(1),
   @w_moneda            int,
   @w_op_monto_aprobado money,
   @w_cotizacion        float,
   @w_aceptable         float,
   @w_op_naturaleza        char(1),
   @w_op_tipo              char(1),
   @w_op_estado            smallint,
   @w_prod_cobis           int,
   @w_dm_producto          catalogo,
   @w_dm_cuenta            cuenta,
   @w_dm_beneficiario      descripcion,
   @w_moneda_n             tinyint,
   @w_dm_moneda            tinyint,
   @w_dm_desembolso        int,
   @w_dm_monto_mds         money,
   @w_dm_cotizacion_mds    float,
   @w_dm_tcotizacion_mds   char(1),
   @w_dm_cotizacion_mop    float,
   @w_dm_tcotizacion_mop   char(1),
   @w_dm_monto_mn          money,
   @w_dm_monto_mop         money,
   @w_reestructuracion     char(1),
   @w_calificacion         catalogo,
   @w_lin_credito          varchar(24),
   @w_tipo_oficina_ifase   char(1),
   @w_oficina_ifase        int,
   @w_fecha_liq            datetime,
   @w_cliente              int,
   @w_monto_des            money,
   @w_toperacion           catalogo,
   @w_codvalor             int,
   @w_categoria            catalogo,
   @w_moneda_uvr           tinyint,
   @w_oficina              int,
   @w_oficial              int,
   @w_gar_admisible        char(1),
   @w_num_renovacion       int,
   @w_concepto_cap         catalogo,
   @w_codvalor_cap         int,
   @w_saldo_cap            money,
   @w_canceladas           int,
   @w_op_tdividendo        char(1),
   @w_dividendo_ven        int,
   @w_li_fecha_vto         datetime,
   @w_op_plazo             int,
   @w_op_tplazo            catalogo,
   @w_op_periodo_int       smallint,
   @w_dias_di              int,
   @w_dias_op              int,
   @w_num_cuotas           smallint,
   @w_tot_cuotas           smallint,
   @w_op_dia_fijo          smallint,
   @w_op_fecha_liq         datetime,
   @w_rowcount             int,
   @w_monto_cap            money,
   @w_num_orden            int,
   @w_operacion_tmp        int,
   @w_dividendo_vig        int,
   @w_est_cancelado        tinyint,
   @w_banco_tmp            cuenta,
   @w_monto_trn            money,
   @w_dit_fecha_ven        datetime,
   @w_rot_concepto         catalogo,
   @w_rot_valor            money,
   @w_rubro_previo         catalogo,
   @w_nrows                int
   

-- VARIABLES INICIALES
select   @w_sp_name    = 'sp_desembolso_parcial'

select @w_monto_op   = 0,
       @w_op_monto_aprobado = 0

/* ESTADOS DE CARTERA */
exec @w_error = sp_estados_cca
@o_est_cancelado  = @w_est_cancelado out
   
-- CODIGO DEL MONEDA UVR
select @w_moneda_uvr = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'MUVR'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0
begin
   select @w_error = 710120
   goto ERROR
end 

select @w_fecha_ini_oper       = op_fecha_ult_proceso,
       @w_tramite              = op_tramite,
       @w_moneda               = op_moneda,
       @w_op_monto             = op_monto,
       @w_operacionca          = op_operacion,
       @w_op_monto_aprobado    = op_monto_aprobado,
       @w_op_naturaleza        = op_naturaleza,
       @w_op_tipo              = op_tipo,
       @w_op_estado            = op_estado,
       @w_toperacion           = op_toperacion,
       @w_reestructuracion     = isnull(op_reestructuracion,''),
       @w_calificacion         = isnull(op_calificacion,''),
       @w_oficial              = op_oficial,
       @w_gar_admisible        = isnull(op_gar_admisible,''),
       @w_oficina              = op_oficina,
       @w_lin_credito          = op_lin_credito,
       @w_cliente              = op_cliente,
       @w_op_tdividendo        = op_tdividendo,
       @w_op_plazo             = op_plazo,
       @w_op_tplazo            = op_tplazo,
       @w_op_periodo_int       = op_periodo_int,
       @w_op_dia_fijo          = op_dia_fijo,
       @w_op_fecha_liq         = op_fecha_liq
from   ca_operacion
where  op_banco = @i_banco_real

-- DECIMALES DE LA MONEDA DEL DESEMBOLSO 
exec @w_error = sp_decimales
     @i_moneda       = @i_moneda_op,
     @o_decimales    = @w_num_dec_op out,
     @o_dec_nacional = @w_num_dec_mn out

if @w_error <> 0
begin
   select @w_error = @w_error
   goto ERROR
end
    
-- SVA Considerar API   
if @i_fecha_proceso is null
   select @w_fecha_proceso = fc_fecha_cierre
   from   cobis..ba_fecha_cierre
   where  fc_producto = 7      
else   
   select @w_fecha_proceso = @i_fecha_proceso
   
if @i_fecha_liq is null
   select @i_fecha_liq = @w_fecha_proceso

-- CONSULTA CODIGO DE MONEDA LOCAL
select  @w_moneda_local = pa_tinyint
from    cobis..cl_parametro
where   pa_nemonico = 'MLO'
and     pa_producto = 'ADM'
set transaction isolation level read uncommitted

select @w_concepto_cap  = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'CAP'
set transaction isolation level read uncommitted

select @w_saldo_cap = sum(am_acumulado  + am_gracia - am_pagado)
from ca_amortizacion
where am_operacion = @w_operacionca
and am_concepto = @w_concepto_cap

if @i_operacion = 'Q'
begin
  select op_toperacion,
          B.valor,
          op_moneda,
          mo_descripcion,
          convert(float, op_monto),
          convert(float, op_monto_aprobado),
          convert(varchar(10),op_fecha_ult_proceso, @i_formato_fecha),
          of_nombre,
          convert(float, 0),
          convert(float, op_monto - 0),
          op_cliente ,
          op_prd_cobis,
          op_tipo,
          op_sujeta_nego,
          op_tipo_cambio,
          op_nombre,
          'N',
          CT.valor clase_cartera, 
          es_descripcion desc_estado,
          of_oficina,
          op_tramite ,
          op_estado,
          @w_saldo_cap
   from   ca_operacion,
          cobis..cl_moneda,
          cobis..cl_oficina,
          cobis..cl_tabla A,
          cobis..cl_catalogo B,
          cobis..cl_tabla CC,
          cobis..cl_catalogo CT,
          ca_estado
   where  op_operacion = @w_operacionca
   and    op_moneda    = mo_moneda
   and    op_oficina   = of_oficina
   and    A.codigo      = B.tabla
   and    A.tabla       = 'ca_toperacion'
   and    B.codigo      = op_toperacion
   and    CC.tabla      = 'cr_clase_cartera' 
   and    CC.codigo     = CT.tabla
   and    CT.codigo     = op_clase
   and    es_codigo     = op_estado
   
   if @i_consulta is null    
      select @i_operacion = 'S'
end



-- NUEVO DESEMBOLSO 
if @i_operacion = 'I'
begin

   if @i_parcial = 'S'
   begin
      select @w_dividendo = di_dividendo
      from ca_dividendo
      where di_operacion = @w_operacionca
      and di_estado = 1
      
      if @@rowcount = 0
      begin
         select @w_error = 701179
         goto ERROR
      end
      
      select @w_dividendo_ven = isnull(di_dividendo,0)
      from ca_dividendo
      where di_operacion = @w_operacionca
      and di_estado = 2
      
      if @w_dividendo_ven > 0
      begin
         select @w_error = 711054
         goto ERROR
      end   
      
      if @i_monto_ds <= 0
      begin
         select @w_error = 710556
         goto ERROR
      end 
   
      if exists (select 1
                    from cob_credito..cr_corresp_sib
                    where codigo = @w_toperacion
                    and tabla = 'T45'
                    and convert(money,codigo_sib) > @i_monto_ds
                   )
      begin
         select @w_error = 710304
         goto ERROR
      end 
   
      if @w_op_tipo = 'O' and @w_lin_credito is null
      begin
        select @w_error = 701065
        goto ERROR 
      end 
   end
   else
      select @w_dividendo = 1
   
   -- DETERMINAR EL VALOR DE COTIZACION DEL DIA
   if @w_moneda = @w_moneda_local
      select @w_cotizacion = 1.0
   else
   begin
      exec sp_buscar_cotizacion
           @i_moneda     = @w_moneda,
           @i_fecha      = @w_fecha_ini_oper,
           @o_cotizacion = @w_cotizacion output
   end
   
   select @w_aceptable = 1.0 / @w_cotizacion
   
   ---CALCULAR MONTO OP Y MONTO MN 
   if @i_moneda_ds = @i_moneda_op
   begin
      if @i_moneda_op = @w_moneda_local
         select @w_convertir_valor = 'N'
      else
         select @w_convertir_valor = 'S'
   end
   ELSE
   begin
      select @w_convertir_valor = 'S'
   end
   
   if @w_convertir_valor = 'S'
   begin
      select @i_monto_ds  = round(@i_monto_ds,@w_num_dec_mn)
      select @w_monto_mn  = @i_monto_ds * @i_cotiz_ds
      select @w_monto_mn  = round(@w_monto_mn,@w_num_dec_mn)
      select @w_monto_op  = round(convert(float,@w_monto_mn) / convert(float,@i_cotiz_op), @w_num_dec_op)
   end
   else
   begin
      select @w_monto_mn = round(@i_monto_ds,@w_num_dec_op)
      select @w_monto_op = round(@i_monto_ds,@w_num_dec_op)
   end

   --- Secuencial
   if @i_secuencial is null
   begin 
      exec @w_secuencial = sp_gen_sec 
           @i_operacion  = @w_operacionca
   end
   else
      select @w_secuencial = @i_secuencial
   
   --- CALCULAR NUMERO DE LINEA 
   select @w_desembolso = max(dm_desembolso) + 1
   from   ca_desembolso
   where  dm_operacion  = @w_operacionca
   and    dm_estado     in ('A','NA')
   
   if @w_desembolso is null 
      select @w_desembolso = 1
   
   insert into ca_desembolso
         (dm_secuencial,      dm_operacion,      dm_desembolso,
          dm_producto,        dm_cuenta,         dm_beneficiario,
          dm_oficina_chg,     dm_usuario,        dm_oficina,
          dm_terminal,        dm_dividendo,      dm_moneda,
          dm_monto_mds,       dm_monto_mop,      dm_monto_mn,
          dm_cotizacion_mds,  dm_cotizacion_mop, dm_tcotizacion_mds,
          dm_tcotizacion_mop, dm_estado,         dm_cod_banco,
          dm_cheque,          dm_fecha,          dm_prenotificacion,
          dm_carga,           dm_concepto,       dm_valor)
   values(@w_secuencial,      @w_operacionca,       @w_desembolso,
          @i_producto,        @i_cuenta,            @i_beneficiario, 
          @i_oficina_chg,     @s_user,              @s_ofi,
          @s_term,            @w_dividendo,         @i_moneda_ds,
          @i_monto_ds,        @w_monto_op,          @w_monto_mn,
          @i_cotiz_ds,        @i_cotiz_op,          @i_tcotiz_ds,
          @i_tcotiz_op,       'NA',                 @i_cod_banco_ach,
          @i_cheque,          @w_fecha_proceso,     @i_prenotificacion,
          @i_carga,           @i_concepto,          0)
   
   if @@error <> 0
   begin
      select @w_error = 710001
      goto ERROR
   end

      select @w_desembolso
      select @o_secuencial = convert(varchar(20),@w_secuencial)
      select @o_secuencial
      select @i_operacion = 'S'

end

-- ELIMINAR REGISTRO DESEMBOLSO
if @i_operacion = 'D'
begin
   
   delete ca_desembolso
   where dm_secuencial = @i_secuencial
   and   dm_operacion  = @w_operacionca
   
   if @@error <> 0
   begin
      select @w_error = 710003
      goto ERROR
   end


   if @i_consulta is null    
      select @i_operacion = 'S'
         
end

-- SEARCH 
if @i_operacion = 'S'
begin
 
select 'No.'                    = dm_desembolso,
          'Forma'                  = dm_producto,
          'Mon.'                   = dm_moneda,
          'Moneda'                 = substring((select mo_descripcion from cobis..cl_moneda
                                                where mo_moneda = x.dm_moneda),1,10),
          'Valor             '     = convert(float, dm_monto_mds),
          'TC.  '                  = 'COT',
          'Cotiz.        '         = convert(float, dm_cotizacion_mds),
          'Valor OP          '     = convert(float, dm_monto_mop),
          'Cotiz OP      '         = convert(float,dm_cotizacion_mop),
          'Valor MN          '     = convert(float, dm_monto_mn),
          'Referencia'             = substring(dm_cuenta,1,16),
          'Beneficiario.'          = substring(dm_beneficiario,1,30),
          'Cod.Oficina'            = dm_oficina_chg, 
          'Oficina '               = isnull(substring((select of_nombre from cobis..cl_oficina
                                                where of_oficina = x.dm_oficina_chg),1,20),''),
          'Secuencial'             = dm_secuencial,
          'Categoria '             = cp_categoria,
          'Ins. ACH '              = dm_prenotificacion,
          'Concepto General'       = dm_concepto
   from   ca_desembolso x, ca_producto
   where  dm_estado = 'NA'
   and    dm_operacion  = @w_operacionca
   and    dm_desembolso  >= 0
   and    dm_producto = cp_producto

   
end

if @i_operacion = 'L'
begin

   ---Validacion de los montos  a desembolsar contra el monto aprobado
   
   -- TEMPORAL DESEMBOLSO PARCIAL
   select @w_operacion_tmp = opt_operacion,
          @w_banco_tmp     = opt_banco
   from ca_operacion_tmp 
   where opt_anterior = @i_banco_real
     
   if @@rowcount = 0
   begin
      select @w_error = 701050
      goto ERROR
   end        

   select @w_monto_cap = rot_valor
   from ca_rubro_op_tmp
   where rot_operacion = @w_operacion_tmp
     and rot_concepto  = @w_concepto_cap
   
/*
   select @w_monto_des = isnull(sum(dm_monto_mn),0)
   from ca_desembolso
   where dm_operacion = @w_operacionca
   and   dm_estado = 'NA'
   
   if @w_monto_cap <> @w_monto_des
   begin
      select @w_error = 708215
      goto ERROR
   end

   if (@w_monto_des + @w_saldo_cap)  >  @w_op_monto_aprobado
   begin
      select @w_error = 711068
      goto ERROR
   end
*/

  select @w_fecha_liq = fc_fecha_cierre
  from cobis..ba_fecha_cierre
  where fc_producto = 7
  
   -- DETERMINAR EL SECUENCIAL DE DESEMBOLSO A APLICAR
   select @w_secuencial = min(dm_secuencial)
   from   ca_desembolso
   where  dm_operacion  = @w_operacionca
   and    dm_estado     = 'NA'
   
   if @w_secuencial <= 0 or @w_secuencial is null
   begin
      select @w_error = 701121
      goto ERROR
   end

   select @w_li_fecha_vto = li_fecha_vto
   from cob_credito..cr_linea
   where li_num_banco  = @w_lin_credito

   if @w_fecha_liq > @w_li_fecha_vto
   begin
      select @w_error = 711055
      goto ERROR
   end

  if @w_fecha_liq = @w_li_fecha_vto
     PRINT 'MENSAJE INFORMATIVO --> ULTIMA UTILIZACION ... HOY VENCE EL CUPO'

   ---Inicio de la transaccion
   ---------------------------
   BEGIN TRAN 

   -- GENERACION DE RESPALDO PARA REVERSAS
   exec @w_error = sp_historial    
        @i_operacionca = @w_operacionca,
        @i_secuencial  = @w_secuencial 
   
   if @w_error <> 0
   begin
      select @w_error = @w_error
      goto ERROR
   end

   if @w_op_tipo <> 'O' 
   begin
      exec @w_error = sp_liquidacion_parcial
            @s_culture         =  @s_culture,  --Internacionalizacion
            @s_user            =  @s_user,
            @s_date            =  @s_date, 
            @s_ofi             =  @s_ofi,  
            @s_term            =  @s_term, 
            ---@i_opcion          =  0,
            @i_banco           =  @i_banco_real,           
            @i_monto_des       =  @w_monto_cap,
            @i_num_dec         =  @w_num_dec_op,
            @i_en_linea        =  'S',
            @i_fecha_proceso   =  @w_fecha_liq,
            @i_concepto_cap    =  @w_concepto_cap,
            @i_operacionca     =  @w_operacionca,
            @i_sec_trn         =  @w_secuencial
   
      if @w_error <> 0 
      begin  
         select @w_error = @w_error
         goto ERROR
      end 
   end
   else
   begin
      ---Rotativos
               --enviar el plazo para la distribucion de las cuotas siempre al este numero de cuotas
         select @w_dias_op = @w_op_plazo * td_factor
         from   ca_tdividendo
         where  td_tdividendo = @w_op_tplazo
         
         select @w_dias_di = @w_op_periodo_int * td_factor
         from   ca_tdividendo
         where  td_tdividendo = @w_op_tdividendo
         
         select @w_num_cuotas = round(@w_dias_op / @w_dias_di,0)
         
         select @w_tot_cuotas = count(1)
         from ca_dividendo
         where di_operacion = @w_operacionca
         and   di_estado    in(0, 1)
         
         ---PRINT 'desembolpar.sp @w_tot_cuotas %1! @w_num_cuotas %2!',@w_tot_cuotas,@w_num_cuotas
         
      select @w_canceladas = isnull(count(1),0)
        from ca_dividendo
       where di_operacion = @w_operacionca
         and   di_estado = 3
         
      if ( @w_op_tipo = 'O' and   @w_canceladas  = 0 ) or (@w_op_tipo = 'O' and @w_tot_cuotas = @w_num_cuotas ) 
      begin
               ---PRINT 'MENSAJE INFORMATIVO ... DISTRIBUCION DE UTILIZACION EN EL MISMO TIEMPO'
               
               exec @w_error = sp_liquidacion_parcial
               @s_culture         =  @s_culture,  --Internacionalizacion
               @s_user            =  @s_user,
               @s_date            =  @s_date, 
               @s_ofi             =  @s_ofi,  
               @s_term            =  @s_term, 
               --@i_opcion          =  0,
               @i_banco           =  @i_banco_real,           
               @i_monto_des       =  @w_monto_cap,
               @i_num_dec         =  @w_num_dec_op,
               @i_en_linea        =  'S',
               @i_fecha_proceso   =  @w_fecha_liq,
               @i_concepto_cap    =  @w_concepto_cap,
               @i_operacionca     =  @w_operacionca,
               @i_sec_trn         =  @w_secuencial
      
         if @w_error <> 0 
         begin  
            select @w_error = @w_error
            goto ERROR
         end 

      end
      else
      begin
         --Este proceso hace la distribucion del plazo y recoge las
         --canceladas en la cuota Nro.1

         ---PRINT 'MENSAJE INFORMATIVO ... NUEVA DISTRIBUCION DE UTILIZACION '
         
         if @w_op_dia_fijo = 0
             select @w_op_dia_fijo = datepart(dd,@w_op_fecha_liq)
             
         exec @w_error      = sp_dparcial_rotativos
         @s_user            = @s_user,
         @i_operacionca     = @w_operacionca,
         @i_dias_di         = @w_dias_di,
         @i_num_cuotas      = @w_num_cuotas,
         @i_dia_fijo        = @w_op_dia_fijo
   
         if @w_error <> 0 
         begin  
            select @w_error = @w_error
            goto ERROR
         end          

         exec @w_error = sp_liquidacion_parcial
               @s_culture         =  @s_culture,  --Internacionalizacion
               @s_user            =  @s_user,
               @s_date            =  @s_date, 
               @s_ofi             =  @s_ofi,  
               @s_term            =  @s_term, 
               --@i_opcion          =  1,
               @i_banco           =  @i_banco_real,           
               @i_monto_des       =  @w_monto_cap,
               @i_num_dec         =  @w_num_dec_op,
               @i_en_linea        =  'S',
               @i_fecha_proceso   =  @w_fecha_liq,
               @i_concepto_cap    =  @w_concepto_cap,
               @i_operacionca     =  @w_operacionca,
               @i_sec_trn         =  @w_secuencial
      
         if @w_error <> 0 
         begin  
            select @w_error = @w_error
            goto ERROR
         end 
      end         
   end

   --GENERACION TRANSACCION
   insert into ca_transaccion
         (tr_secuencial,        tr_fecha_mov,        tr_toperacion,
          tr_moneda,            tr_operacion,        tr_tran, 
          tr_en_linea,          tr_banco,            tr_dias_calc,
          tr_ofi_oper,          tr_ofi_usu,          tr_usuario,
          tr_terminal,          tr_fecha_ref,        tr_secuencial_ref,
          tr_estado,            tr_gerente,          tr_gar_admisible,
          tr_reestructuracion,  tr_calificacion,
          tr_observacion,       tr_fecha_cont,       tr_comprobante)
   values(@w_secuencial,        @s_date,             @w_toperacion,
          @w_moneda,            @w_operacionca,      'DES',
          'S',                  @i_banco_real,       0,
          @w_oficina,           @s_ofi,              @s_user,
          @s_term,              @w_fecha_liq,        0,
          'ING',                @w_oficial,          isnull(@w_gar_admisible,''),
          isnull(@w_reestructuracion,''),            isnull(@w_calificacion,''),
          'DESEMBOLSO PARCIAL', @s_date,             0)
   
   if @@error <>0 
   begin
         select @w_error = 710001
      goto ERROR
   end
      
   -- INSERCION DEL RUBRO CAPITAL
   select @w_codvalor_cap = co_codigo * 1000  + 10  + 0 --@w_tipo_garantia
   from   ca_concepto
   where  co_concepto = @w_concepto_cap

   -- OBTENCION DE LA COTIZACION Y TIPO DE COTIZACION DE LA OPERACION 
   select @w_dm_cotizacion_mop  = dm_cotizacion_mop,
          @w_dm_tcotizacion_mop = dm_tcotizacion_mop,
          @w_dm_desembolso      = dm_dividendo
   from   ca_desembolso
   where  dm_operacion    = @w_operacionca
   and    dm_secuencial   = @w_secuencial

   -- INSERCION DEL DETALLE DE LA TRANSACCION
   insert ca_det_trn
         (dtr_secuencial,    dtr_operacion,        dtr_dividendo,
          dtr_concepto,      dtr_estado,           dtr_periodo,
          dtr_codvalor,      dtr_monto,            dtr_monto_mn,
          dtr_moneda,        dtr_cotizacion,       dtr_tcotizacion,
          dtr_afectacion,    dtr_cuenta,           dtr_beneficiario,
          dtr_monto_cont)
   values(@w_secuencial,     @w_operacionca,       @w_dm_desembolso,
          @w_concepto_cap,    1,                   0, 
          @w_codvalor_cap,   @w_monto_cap,         round(@w_monto_cap*@w_dm_cotizacion_mop,@w_num_dec_mn),
          @w_moneda,         @w_dm_cotizacion_mop, @w_dm_tcotizacion_mop,
          'D',               '',                   '',
          0)
   
      if @@error <>0
      begin
         select @w_error = 710001  
         goto ERROR
      end    

   -- INSERCION DEL DETALLE CONTABLE PARA LAS FORMAS DE PAGO
   declare cursor_desembolso cursor
   for select dm_desembolso,    dm_producto,          dm_cuenta,
              dm_beneficiario,  dm_monto_mds,
              dm_moneda,        dm_cotizacion_mds,    dm_tcotizacion_mds,
              dm_monto_mn,      dm_cotizacion_mop,    dm_tcotizacion_mop,
              dm_monto_mop
       from   ca_desembolso
       where  dm_secuencial = @w_secuencial
       and    dm_operacion  = @w_operacionca
       order  by dm_desembolso
       for read only
   
   open cursor_desembolso
   
   fetch cursor_desembolso
   into  @w_dm_desembolso,   @w_dm_producto,       @w_dm_cuenta,
         @w_dm_beneficiario, @w_dm_monto_mds,
         @w_dm_moneda,       @w_dm_cotizacion_mds, @w_dm_tcotizacion_mds,
         @w_dm_monto_mn,     @w_dm_cotizacion_mop, @w_dm_tcotizacion_mop,
         @w_dm_monto_mop
      
   --while @@fetch_status not in (-1,0)
   while @@fetch_status = 0
   begin
      
      select @w_prod_cobis = isnull(cp_pcobis,0),  
             @w_categoria      = cp_categoria,
             @w_codvalor       = cp_codvalor
      from   ca_producto
      where  cp_producto = @w_dm_producto
      
      if @@rowcount = 0
      begin
         select @w_error = 701150
         goto ERROR
      end
      
      if @w_dm_moneda = @w_moneda
         select @w_monto_trn = @w_dm_monto_mds
      else
         select @w_monto_trn = @w_dm_monto_mop
      
      -- INSERCION DEL DETALLE DE LA TRANSACCION
      insert ca_det_trn
            (dtr_secuencial,    dtr_operacion,        dtr_dividendo,
             dtr_concepto,      dtr_estado,           dtr_periodo,
             dtr_codvalor,      dtr_monto,            dtr_monto_mn,
             dtr_moneda,        dtr_cotizacion,       dtr_tcotizacion,
             dtr_afectacion,    dtr_cuenta,           dtr_beneficiario,
             dtr_monto_cont)
      values(@w_secuencial,     @w_operacionca,       @w_dm_desembolso,
             @w_dm_producto,    1,                    0, 
             @w_codvalor,       @w_monto_trn,         @w_dm_monto_mn,
             @w_dm_moneda,      @w_dm_cotizacion_mds, @w_dm_tcotizacion_mds,
             'C',               isnull(@w_dm_cuenta,''),   @w_dm_beneficiario,
             0)
      
         if @@error <>0
         begin
            select @w_error = 710001  
            goto ERROR
         end 

         if  @w_prod_cobis > 0 
         begin
            select @w_oficina_ifase = @s_ofi
            
            select @w_tipo_oficina_ifase = dp_origen_dest
            from   ca_trn_oper, cob_conta..cb_det_perfil
            where  to_tipo_trn = 'DES'
            and    to_toperacion = @w_toperacion
            and    dp_empresa    = 1
            and    dp_producto   = 7
            and    dp_perfil     = to_perfil
            and    dp_codval     = @w_codvalor
            
            if @@rowcount = 0
            begin
               select @w_error = 710446
               goto ERROR
            end
            
            if @w_tipo_oficina_ifase = 'C'
            begin
               select @w_oficina_ifase = pa_int
               from   cobis..cl_parametro
               where  pa_nemonico = 'OFC'
               and    pa_producto = 'CON'
               set transaction isolation level read uncommitted
            end
            
            if @w_tipo_oficina_ifase = 'D'
            begin
               select @w_oficina_ifase = @w_oficina
            end
            
            -- AFECTACION A OTROS PRODUCTOS
            exec @w_error = sp_afect_prod_cobis
            @s_user               = @s_user,
            @s_date               = @s_date,
            @s_ssn                = @s_ssn,
            @s_sesn               = @s_sesn,
            @s_term               = @s_term,
            @s_srv                = @s_srv,
            @s_ofi                = @w_oficina_ifase,
            @i_fecha              = @w_fecha_liq,
            @i_cuenta             = @w_dm_cuenta,
            @i_producto           = @w_dm_producto,
            @i_monto              = @w_dm_monto_mn,
            @i_mon                = @w_dm_moneda,  
            @i_beneficiario       = @w_dm_beneficiario,
            @i_monto_mpg          = @w_dm_monto_mds,
            @i_monto_mop          = @w_dm_monto_mop,
            @i_monto_mn           = @w_dm_monto_mn,
            @i_cotizacion_mop     = @w_dm_cotizacion_mop,
            @i_tcotizacion_mop    = @w_dm_tcotizacion_mop,
            @i_cotizacion_mpg     = @w_dm_cotizacion_mds,
            @i_tcotizacion_mpg    = @w_dm_tcotizacion_mds,
            @i_operacion_renovada = 0,
            @i_alt                = @w_operacionca,
            @i_sec_tran_cca       = @w_secuencial, -- FCP Interfaz Ahorros
            @o_num_renovacion     = @w_num_renovacion out
            
            if @w_error <> 0
            begin
               select @w_error = @w_error
               goto ERROR
            end
         end
         
         -- INTERFAZ PARA SIPLA
         if @w_op_naturaleza = 'A' and @w_dm_producto <> 'CARTERA'
         begin 
            exec @w_error = sp_interfaz_otros_modulos
                 @s_user       = @s_user,
                 @i_cliente    = @w_cliente,
                 @i_modulo     = 'CCA',
                 @i_interfaz   = 'S',
                 @i_modo       = 'I',
                 @i_obligacion = @i_banco_real,
                 @i_moneda     = @w_dm_moneda,
                 @i_sec_trn    = @w_secuencial,
                 @i_fecha_trn  = @w_fecha_liq,
                 @i_desc_trn   = 'DESEMBOLSO PARCIAL DE CARTERA',
                 @i_monto_trn  = @w_dm_monto_mop,
                 @i_monto_des  = @w_dm_monto_mds,
                 @i_gerente    = @s_user,
                 @i_oficina    = @s_ofi,
                 @i_cotizacion = @w_dm_cotizacion_mop,
                 @i_forma_pago = @w_dm_producto,
                 @i_categoria  = @w_categoria,
                 @i_moneda_uvr = @w_moneda_uvr
            
            if @w_error <> 0
            begin
               PRINT 'salio con error de sp_interfaz_otros_modulos '
               select @w_error = @w_error 
               goto ERROR
            end
        end
        
        --LGBC - Comentar para pruebas en base en el proceso de renovacion
        if @w_dm_producto LIKE 'EF%' --= 'EFMN' begin --LPO CDIG Multimoneda LIKE 'EF%'
        BEGIN
           exec @w_error   = cob_interface..sp_genera_orden
           @s_date         = @s_date,             --> Fecha de proceso
           @s_user         = @s_user,             --> Usuario
           @i_ofi          = @s_ofi,
           @i_operacion    = 'I',                 --> Operacion ('I' -> Insercion, 'A' Anulación)
           @i_causa        = '003',               --> Causal de Egreso(cc_causa_oe)
           @i_ente         = @w_cliente,          --> Cod ente,
           @i_valor        = @w_dm_monto_mn,
           @i_tipo         = 'P',
           @i_idorden      = null,                --> Cód Orden cuando operación 'A',
           @i_ref1         = 0,                   --> Ref. Númerica no oblicatoria
           @i_ref2         = 0 ,                  --> Ref. Númerica no oblicatoria
           @i_ref3         = @i_banco_real,            --> Ref. AlfaNúmerica no oblicatoria
           @i_interfaz     ='N',                  --> 'N' - Invoca sp_cerror, 'S' - Solo devuelve cód error
           @o_idorden      = @w_num_orden out     --> Devuelve cód orden de pago/cobro generada - Operación 'I'
        
           if @w_error <> 0 begin
              select @w_error = @w_error
              goto ERROR
           end else
        
           update ca_desembolso with (rowlock)
           set dm_pagado = 'I',
               dm_orden_caja  = @w_num_orden
           where dm_operacion = @w_operacionca
           and   dm_producto  LIKE @w_dm_producto --LPO CDIG Multimoneda 'EFMN'
        
           if @@error <> 0 
           begin
              select @w_error = 710305
              goto ERROR
           end
        end      
      
      fetch cursor_desembolso
      into  @w_dm_desembolso,   @w_dm_producto,       @w_dm_cuenta,
            @w_dm_beneficiario, @w_dm_monto_mds,
            @w_dm_moneda,       @w_dm_cotizacion_mds, @w_dm_tcotizacion_mds,
            @w_dm_monto_mn,     @w_dm_cotizacion_mop, @w_dm_tcotizacion_mop,
            @w_dm_monto_mop
   end
   
   close cursor_desembolso
   deallocate cursor_desembolso

   -- SE INSERTA NUEVOS RUBROS GENERADOS Y QUE SE COBRAN EN LA LIQUIDACION
   if exists (select 1
             from ca_rubro_op_tmp
            where rot_operacion  = @w_operacion_tmp
              and rot_fpago      = 'L'
              and rot_valor      > 0)
   begin
      -- INSERCION DEL DETALLE DE LA TRANSACCION
      insert ca_det_trn
            (dtr_secuencial,    dtr_operacion,       dtr_dividendo,        dtr_concepto,
             dtr_estado,        dtr_periodo,         dtr_codvalor,         dtr_monto,
             dtr_monto_mn,      dtr_moneda,          dtr_cotizacion,       dtr_tcotizacion,
             dtr_afectacion,    dtr_cuenta,          dtr_beneficiario,     dtr_monto_cont)
      select @w_secuencial,         @w_operacionca,       @w_dm_desembolso,
             rot_concepto,          1,                    0,
             co_codigo*1000+10+0,   rot_valor,            round(rot_valor*@w_dm_cotizacion_mop,@w_num_dec_mn),
             @w_moneda,             @w_dm_cotizacion_mop, @w_dm_tcotizacion_mop,
            'C',                    '',                   'REGISTRO RUBRO LIQUIDACION',
             0
      from   ca_concepto ,ca_rubro_op_tmp
      where  rot_concepto  = co_concepto
      and    rot_operacion = @w_operacion_tmp
      and    rot_fpago     = 'L'
      and    rot_valor      > 0
      
      if @@error <>0
      begin
         select @w_error = 710001
         goto ERROR
      end
   end
   
   -- Si existen rubros anticipados se insertan para contabilización
   if exists (select 1
                from ca_amortizacion_tmp,ca_rubro_op_tmp
               where amt_operacion  = @w_operacion_tmp
                 and amt_dividendo  = 1
                 and rot_operacion  = @w_operacion_tmp
                 and rot_concepto   = amt_concepto
                 and rot_fpago      = 'A'
                 and amt_cuota      > 0)
   begin
 
      --- INSERCION DE LOS DETALLES CORRESPONDIENTES A LOS INTERESES PERIODICOS ANTICIPADOS
      insert into ca_det_trn
            (dtr_secuencial,        dtr_operacion,        dtr_dividendo,
             dtr_concepto,          dtr_estado,           dtr_periodo,
             dtr_codvalor,          dtr_monto,            dtr_monto_mn,
             dtr_moneda,            dtr_cotizacion,       dtr_tcotizacion,
             dtr_afectacion,        dtr_cuenta,           dtr_beneficiario,
             dtr_monto_cont)
      select @w_secuencial,         @w_operacionca,       amt_dividendo,
             amt_concepto,          1,                    0,
             co_codigo*1000+10+0,   amt_cuota,            round(amt_cuota*@w_dm_cotizacion_mop,@w_num_dec_mn),
             @w_moneda,             @w_dm_cotizacion_mop, @w_dm_tcotizacion_mop,
            'C',                    '',                   'REGISTRO RUBRO ANTICIPADOS',
             0
      from   ca_amortizacion_tmp, ca_concepto ,ca_rubro_op_tmp
      where  amt_operacion = @w_operacion_tmp
      and    amt_dividendo = 1
      and    amt_concepto  = co_concepto
      and    rot_operacion = @w_operacion_tmp
      and    rot_concepto  = amt_concepto
      and    rot_fpago     = 'A'
      and    amt_cuota      > 0
   
      if @@error <> 0
      begin
         select @w_error = 710001
         goto ERROR
      end
      
      -- Dividendo a Afectar
      select @w_dit_fecha_ven = dit_fecha_ven
      from ca_dividendo_tmp
      where dit_operacion = @w_operacion_tmp
        and dit_dividendo = 1
      
      -- Dividendo Vigente
      select @w_dividendo_vig = di_dividendo
      from ca_dividendo
      where  di_operacion = @w_operacionca
      and    di_fecha_ven = @w_dit_fecha_ven
   
      if @@rowcount = 0
      begin
         select @w_error = 701179  -- NO EXISTE DIVIDENDO VIGENTE
         goto ERROR
      end

      select @w_nrows = 1, 
             @w_rubro_previo = ''
      
      while (@w_nrows > 0) 
      begin 
         select top 1
            @w_rot_concepto             = amt_concepto,
            @w_rot_valor                = amt_cuota,
            @w_rubro_previo             = rot_concepto
         from ca_amortizacion_tmp,ca_rubro_op_tmp
        where amt_operacion  = @w_operacion_tmp
          and amt_dividendo  = 1
          and rot_operacion  = @w_operacion_tmp
          and rot_concepto   = amt_concepto
          and rot_fpago      = 'A'
          and amt_cuota      > 0
          and rot_concepto   > @w_rubro_previo
          order by rot_concepto
            
         if @@rowcount = 0 break 

         update ca_amortizacion with (rowlock)
         set    am_pagado    = @w_rot_valor,
                am_acumulado = @w_rot_valor
         where  am_operacion = @w_operacionca
         and    am_dividendo = @w_dividendo_vig
         and    am_concepto  = @w_rot_concepto
         
         if @@error <> 0
         begin
            select @w_error = 7100210
            goto ERROR
         end
      end -- While
   end                    
   --FIN GENERACION TRANSACCION

    -- AFECTACION A LA LINEA EN CREDITO
    if @w_lin_credito is not null and @w_tramite > 0 and @w_tramite is not null
    begin
       exec @w_error = cob_credito..sp_utilizacion
            @s_ofi         = @s_ofi,
            @s_ssn         = @s_ssn,
            @s_sesn        = @s_sesn,
            @s_user        = @s_user,
            @s_term        = @s_term,
            @s_date        = @s_date,
            @s_srv         = @s_srv,
            @s_lsrv        = @s_lsrv,
            @s_rol         = @s_rol,
            @s_org         = @s_org,
            @t_trn         = 21888,
            @i_linea_banco = @w_lin_credito,
            @i_producto    = 'CCA',
            @i_toperacion  = @w_toperacion,
            @i_tipo        = 'D',
            @i_moneda      = @w_moneda,
            @i_monto       = @w_monto_cap,
            @i_cliente     = @w_cliente,
            @i_secuencial  = @w_secuencial,
            @i_tramite     = @w_tramite,
            @i_opcion      = 'A', --Activa
            @i_opecca      = @w_operacionca,
            @i_fecha_valor = @i_fecha_liq,
            @i_modo        = 0,
            @i_monto_cex   = 0,
            @i_numoper_cex = ''
    
       if @@error <> 0 or @@trancount = 0
       begin
          select @w_error = 710522
          goto ERROR
       end
       
       if @w_error <> 0
       begin
          select @w_error = @w_error
          goto ERROR
       end

    end

   ---MARCAR EL DESEMBOLSO COMO APLICADO
   update ca_desembolso 
   set    dm_estado          = 'A'
   where  dm_secuencial = @w_secuencial
   and    dm_operacion  = @w_operacionca
   and    dm_estado     <> 'I'
   

   --ACTUALIZACION DEL SALDO DEL FONDO POR DESEMBOLSO APLICADO
   exec @w_error  = cob_cartera..sp_fuen_recur
   @s_user        = @s_user,
   @s_term        = @s_term,
   @s_ofi         = @s_ofi,
   @s_ssn         = @s_ssn,
   @s_date        = @s_date,
   @i_operacion   = 'F',
   @i_monto       = @w_monto_cap,
   @i_opcion      = 'D',
   @i_reverso     = 'N',
   @i_operacionca = @w_operacionca,
   @i_secuencial  = @w_secuencial,
   @i_dividendo   = 1,
   @i_fecha_proc  = @i_fecha_liq

   if @w_error <> 0 begin
       select @w_error = @w_error
       goto ERROR
   end


   COMMIT TRAN
   
   exec @w_error = sp_borrar_tmp_int
      @s_user            = @s_user,
      @s_term            = @s_term,
      @s_sesn            = @s_sesn,
      @i_banco           = @i_banco_real
   
   if @w_error <> 0 begin
       select @w_error = @w_error
       goto ERROR
   end

   exec @w_error = sp_borrar_tmp_int
      @s_user            = @s_user,
      @s_term            = @s_term,
      @s_sesn            = @s_sesn,
      @i_banco           = @w_banco_tmp
   
   if @w_error <> 0 begin
       select @w_error = @w_error
       goto ERROR
   end


end  --Operacion L



-- H
if @i_operacion = 'H'
begin
    /* SE MODIFICO POR QUE EN VARIOS DESEMBOLSOS NO SE GENERA REGISTRO EN ca_det_trn
     select 'Sec'=tr_secuencial,
            'Usuario'= substring(tr_usuario,1,10),
            'FechaDes'=convert(char(12),tr_fecha_mov,109),
            'FormaDes'=dtr_concepto,
             'DESCRIPCION' = substring(cp_descripcion,1,50),
             'Valor MN' = dtr_monto_mn,
             'Valor Mop' = dtr_monto,
             'Cotizacion'=dtr_cotizacion,
             'Est'= tr_estado
     from ca_transaccion,
          ca_det_trn,
          ca_producto
     where tr_banco = @i_banco_real
     and tr_tran = 'DES'
     and tr_estado <> 'RV'
     and tr_operacion = dtr_operacion
     and tr_secuencial = dtr_secuencial
     and dtr_concepto = cp_producto
     and cp_desembolso = 'S'
     order by tr_secuencial
    */
    select 'Secuencial'       = tr_secuencial,
           'Usuario'          = substring(tr_usuario,1,10),
           'Fecha Desembolso' = convert(char(12),dm_fecha,103),
           'Forma Desembolso' = dm_producto,
           'Descripcion'      = substring(cp_descripcion,1,50),
           'Valor MN'         = dm_monto_mn,
           'Valor MOP'        = dm_monto_mop,
           'Cotizacion'       = dm_cotizacion_mop,
           'Estado'           = tr_estado
    from ca_transaccion,
         ca_desembolso,
         ca_producto
    where tr_banco = @i_banco_real
    and   dm_operacion  = tr_operacion
    and   dm_operacion  = tr_operacion
    and   dm_secuencial = tr_secuencial
    and   cp_producto   = dm_producto
    order by tr_secuencial

end

return 0

ERROR:

exec cobis..sp_cerror
     @t_debug   = 'N',
     @t_file    = null,
     @t_from    = @w_sp_name,
     @i_num     = @w_error
--     @i_cuenta  = @i_banco_real
   
   return @w_error
go

