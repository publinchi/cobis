/************************************************************************/
/*   Archivo            :      cofagint.sp                              */
/*   Stored procedure   :      sp_creaop_reconoc_fag_int                */
/*   Base de datos      :      cob_cartera                              */
/*   Producto           :      Credito y Cartera                        */
/*   Disenado por       :      Luis Alfonso Mayorga                     */
/*   Fecha de escritura :      Dic 2002                                 */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBISCORP'                                                        */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBISCORP o su representante.             */
/************************************************************************/
/*                           PROPOSITO                                  */
/*   Crear una  operacion por efecto del reconocimiento del FAG  que    */
/*   nace de un pago                                                    */
/*                        ACTUALIZACIONES                               */
/*      jun-2004         Elcira Pelaez      linea por cada  forma de    */
/*                                          pago por reconocimeinto de  */
/*                                          Garantias especiales        */
/*      Feb-2006         Elcira Pelaez      defecto 5999 Op.UVR         */
/*      Mar-2006         Fabian Quintero    defecto 5156 Op. FNG UVR    */
/*      May-2006         Ivan Jimenez IFJ   REQ 455 - Control de Pagos  */
/*                                          Operaciones Alternas        */
/*      MAr-2007         Elcira Pelaez B    REQ 455 almacenar new campos*/
/*  24/Jun/2021          KDR               Nuevo parámetro sp_liquida   */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_creaop_reconoc_fag_int')
   drop proc sp_creaop_reconoc_fag_int
go

create proc sp_creaop_reconoc_fag_int
   @s_sesn           int          = Null,
   @s_ssn            int          = null,
   @s_user           login        = Null,
   @s_term           varchar(30)  = Null,
   @s_date           datetime     = Null,
   @s_ofi            smallint     = Null,
   @i_fecha_proceso  datetime,
   @i_monto_mn       money,
   @i_operacionca    int,
   @i_abd_concepto   catalogo
   

as declare 
   @w_toperacion_especial  catalogo,
   @w_origen_fondos        catalogo,
   @w_cliente              int,
   @w_nombre_completo      descripcion,
   @w_sector               catalogo,
   @w_oficina_oper         smallint,
   @w_do_moneda            tinyint,
   @w_comentario           varchar(255),
   @w_oficial              smallint,
   @w_ciudad               int,
   @w_destino              catalogo,
   @w_op_banco             cuenta,
   @w_error                int,
   @w_operacion_anterior   cuenta,
   @w_fecha                datetime,
   @w_cot_moneda           money,
   @w_tcotizacion_mpg      char(1),
   @w_tcot_moneda          char(1),
   @w_identificacion       numero,
   @w_sp_name              descripcion,
   @w_clase_cartera        catalogo,
   @w_ro_signo             char(1),
   @w_ro_factor            float,
   @w_ro_referencial       catalogo,
   @w_ro_porcentaje        float,
   @w_ro_porcentaje_aux    float,
   @w_ro_porcentaje_efa    float,
   @w_ts_porcentaje        float,
   @w_ts_porcentaje_efa    float,
   @w_ts_referencial       catalogo,
   @w_ts_signo             char(1),
   @w_ts_factor            float,
   @w_max_sec_tasa         int,
   @w_operacion_nueva      int,
   @w_rubro_int            catalogo,
   @w_moneda_des           smallint,
   @w_monto_des            money,
   -- Inicio IFJ 455
   @w_dias_anio            smallint,      
   @w_base_calculo         char(1),
   @w_num_dec_tapl         smallint,
   @w_tasa_efa             float,
   @w_tasa_nominal         float,
   @w_monto_original       money,
   @w_monto_alterna        money,
   @w_tramite_oper_original   int,
   @w_garantia_especial    varchar(64)
   -- Fin IFJ 455
   
begin

   select @w_moneda_des = 0
   select @w_sp_name = 'sp_creaop_reconoc_fag_int'
   
   select @w_comentario = 'OPERACION POR RECONOCIMIENTO DE GARANTIA' + '-' + @i_abd_concepto
   
   --HEREDAR INFORMACION DE LA OPERACION QUE VIENE
   select @w_cliente     = op_cliente,
   @w_nombre_completo    = op_nombre,
   @w_sector             = op_sector,
   @w_oficina_oper       = op_oficina,
   @w_do_moneda          = op_moneda,
   @w_oficial            = op_oficial,
   @w_ciudad             = op_ciudad,
   @w_destino            = op_destino,
   @w_clase_cartera      = op_clase,
   @w_origen_fondos      = op_origen_fondos,
   @w_operacion_anterior = op_banco
   from   ca_operacion
   where  op_operacion = @i_operacionca
   
   --SELECCIONAR LA LINEA DE CREDITO PARAMETRIZADA PARA LA FORMA DE PAGO
   --DEL RECONOCIMIENTO ESPECIAL
   if @w_do_moneda = 0
   begin
      select @w_toperacion_especial = valor 
      from cobis..cl_catalogo
      where tabla = (select codigo from cobis..cl_tabla
                     where tabla = 'ca_especiales')
      and  codigo = @i_abd_concepto
   end
   else
   begin
      select @w_toperacion_especial = valor 
      from cobis..cl_catalogo
      where tabla = (select codigo from cobis..cl_tabla
                     where tabla = 'ca_especiales_uvr')
      and  codigo = @i_abd_concepto
   end
      
   --VALIDAR LA EXISTENCIA DE LA LINEA
   if not exists(select (1)
             from   ca_default_toperacion
             where  dt_tipo         = 'G'
             and    dt_nace_vencida = 'S'
             and    dt_toperacion   = @w_toperacion_especial)
   begin
      select @w_error = 70101
      return @w_error
   end

   -- SACAR SECUENCIALES SESIONES
   exec @s_ssn = sp_gen_sec 
   @i_operacion  = -1
   
   exec @s_sesn = sp_gen_sec 
   @i_operacion  = -1

   select @w_identificacion = cl_ced_ruc
   from   cobis..cl_cliente
   where  cl_cliente        = @w_cliente
   set transaction isolation level read uncommitted
   
   --INGRESAR DEUDOR 
   
   exec @w_error  =  sp_codeudor_tmp
   @s_sesn        =  @s_sesn,
   @s_user        =  @s_user,
   @i_borrar      =  'S',
   @i_secuencial  =  1,
   @i_titular     =  @w_cliente,
   @i_operacion   =  'A',
   @i_codeudor    =  @w_cliente,
   @i_ced_ruc     =  @w_identificacion,
   @i_rol         =  'D',
   @i_externo     =  'N',
   @i_banco       =  @w_operacion_anterior
   
   if @w_error != 0
   begin 
      print 'error sp_codeudor_tmp'
      return @w_error
   end

   -- CREACION DE LA OPERACION EN TEMPORALES
   exec @w_error      = sp_crear_operacion
   @s_user            = @s_user,
   @s_date            = @i_fecha_proceso,
   @s_term            = @s_term,
   @i_cliente         = @w_cliente,
   @i_nombre          = @w_nombre_completo,
   @i_sector          = @w_sector,
   @i_toperacion      = @w_toperacion_especial,
   @i_oficina         = @w_oficina_oper,
   @i_moneda          = @w_do_moneda,
   @i_comentario      = @w_comentario,
   @i_oficial         = @w_oficial, 
   @i_fecha_ini       = @i_fecha_proceso,
   @i_monto           = @i_monto_mn,
   @i_monto_aprobado  = @i_monto_mn,
   @i_destino         = @w_destino, 
   @i_ciudad          = @w_ciudad,
   @i_formato_fecha   = 101,
   @i_fondos_propios  = 'N',
   @i_origen_fondos   = @w_origen_fondos,
   @i_batch_dd        = 'N',
   @i_clase_cartera   = @w_clase_cartera,
   @i_en_linea        = 'N',
   @i_salida          = 'N',
   @o_banco           = @w_op_banco output
   
   if @w_error != 0 
   begin
      print 'error sp_crear_operacion'
      return @w_error
   end

   exec @w_error = sp_operacion_def_int
   @s_date      = @i_fecha_proceso,
   @s_sesn      = @s_sesn,
   @s_user      = @s_user,
   @s_ofi       = @w_oficina_oper,
   @i_banco     = @w_op_banco,
   @i_claseoper = 'A'
   
   if @w_error != 0
   begin      
      return @w_error
   end
     
   
   select @w_operacion_nueva = op_operacion
   from   ca_operacion   
   where  op_banco = @w_op_banco

   
   select @w_rubro_int = ro_concepto
   from   ca_rubro_op,ca_concepto
   where  ro_operacion = @w_operacion_nueva
   and    ro_concepto = co_concepto
   and    co_categoria = 'I'

   
   --DATOS DE LA TASA INT DE LA ACTIVA ANTERIOR PARA COLOCARLOS A LA NUEVA OR PRESENTACION
   --SEGUN CONTROL DE CAMBIO X33 DE JUNIO -2003
   select @w_max_sec_tasa = max(ts_secuencial)
   from   ca_tasas
   where  ts_operacion = @i_operacionca
   and    ts_concepto  = @w_rubro_int
   
   select 
   @w_ts_porcentaje     = ts_porcentaje,
   @w_ts_porcentaje_efa = ts_porcentaje_efa,
   @w_ts_referencial    = ts_referencial,
   @w_ts_signo          = ts_signo,
   @w_ts_factor         = ts_factor
   from   ca_tasas
   where  ts_operacion  = @i_operacionca
   and    ts_concepto   = @w_rubro_int
   and    ts_secuencial = @w_max_sec_tasa
   
   
   update ca_tasas
   set ts_porcentaje     = @w_ts_porcentaje,
       ts_porcentaje_efa = @w_ts_porcentaje_efa,
       ts_referencial    = @w_ts_referencial,
       ts_signo          = @w_ts_signo,
       ts_factor         = @w_ts_factor
   where ts_operacion    = @w_operacion_nueva
   and   ts_concepto     = @w_rubro_int
   
   if @@error != 0                                                
   begin
     print 'update...'                                                       
     select @w_error = 705068                                 
     return @w_error                                          
   end                        

      
   select @w_ro_signo   = ro_signo,
   @w_ro_factor         = ro_factor,
   @w_ro_referencial    = ro_referencial,
   @w_ro_porcentaje     = ro_porcentaje,
   @w_ro_porcentaje_aux = ro_porcentaje_aux,
   @w_ro_porcentaje_efa = ro_porcentaje_efa
   from   ca_rubro_op
   where  ro_operacion = @i_operacionca
   and    ro_concepto  = @w_rubro_int
   

   select @w_dias_anio     = op_dias_anio,
          @w_base_calculo  = op_base_calculo
   from   ca_operacion
   where  op_operacion =  @w_operacion_nueva

   select @w_num_dec_tapl  = ro_num_dec
   from   ca_rubro_op
   where  ro_operacion = @w_operacion_nueva
   and    ro_tipo_rubro = 'M'
   
   select @w_tasa_efa = @w_ro_porcentaje_efa


   exec @w_error     = sp_conversion_tasas_int
   @i_dias_anio      = @w_dias_anio,
   @i_base_calculo   = @w_base_calculo,
   @i_periodo_o      = 'A',
   @i_modalidad_o    = 'V',
   @i_num_periodo_o  = 1,
   @i_tasa_o         = @w_tasa_efa,   
   @i_periodo_d      = 'D',
   @i_modalidad_d    = 'V',
   @i_num_periodo_d  = 1,
   @i_num_dec        = @w_num_dec_tapl,
   @o_tasa_d         = @w_tasa_nominal output

   if @w_error != 0
   begin
      return @w_error
   end
   
   -- Fin IFJ 455
       
   --FIN DE ACTUALIZACION DATOS TASA Y RUBRO
   select @w_fecha = fc_fecha_cierre
   from   cobis..ba_fecha_cierre
   where  fc_producto = 7 
      
   exec sp_buscar_cotizacion
   @i_moneda     = @w_do_moneda,
   @i_fecha      = @w_fecha,
   @o_cotizacion = @w_cot_moneda output
   
   select @w_tcotizacion_mpg = 'T',
          @w_tcot_moneda     = 'T'
   
   if @w_moneda_des != @w_do_moneda
   begin
      select @w_monto_des = @i_monto_mn * @w_cot_moneda
      select @w_monto_des = ceiling(@w_monto_des)
   end
   else
      select  @w_monto_des = @i_monto_mn
   

   exec @w_error     = sp_desembolso
   @s_ofi            = @s_ofi,
   @s_term           = @s_term,
   @s_user           = @s_user,
   @s_date           = @s_date,  
   @i_producto       = @i_abd_concepto,  --La misma forma de pago es la de desembolso
   @i_cuenta         = 'AUTOMATICO', 
   @i_beneficiario   = @w_nombre_completo,
   @i_oficina_chg    = @s_ofi,
   @i_banco_ficticio = @w_op_banco, 
   @i_banco_real     = @w_op_banco,
   @i_monto_ds       = @w_monto_des,
   @i_tcotiz_ds      = 'N',
   @i_cotiz_ds       = 1.0,
   @i_tcotiz_op      = 'N',
   @i_cotiz_op       = @w_cot_moneda,
   @i_moneda_op      = @w_do_moneda,
   @i_moneda_ds      = @w_moneda_des,
   @i_operacion      = 'I',
   @i_externo        = 'N'
   
   if @w_error != 0 
   begin
      print '..sp_desembolso..'
      return @w_error
   end
    
   exec @w_error = sp_liquida
   @s_ssn            = @s_ssn,
   @s_sesn           = @s_sesn,
   @s_user           = @s_user,
   @s_date           = @s_date,
   @s_ofi            = @s_ofi,
   @s_rol            = 1,
   @s_term           = @s_term,
   @i_banco_ficticio = @w_op_banco,
   @i_banco_real     = @w_op_banco,
   @i_afecta_credito = 'N',
   @i_fecha_liq      = @i_fecha_proceso,
   @i_tramite_batc   = 'N',
   @i_externo        = 'N',
   @i_desde_cartera  = 'N'          -- KDR No es ejecutado desde Cartera[FRONT]
   
   if @w_error <> 0
   begin
      return @w_error
   end
   
   update cob_cartera..ca_operacion 
   set    op_anterior  = @w_operacion_anterior
   where  op_operacion = @w_op_banco
   if @@error != 0
   begin
      print 'ingreso por actualizacion operación anterior'  
      select @w_error = 705007
      return @w_error
   end

   -- BORAR TEMPORALES
   exec @w_error = sp_borrar_tmp
   @i_banco  = @w_op_banco,
   @s_user   = @s_user
   
   if @w_error <> 0
   begin
      return @w_error
   end
   
   -- Inicio IFJ 455
   select @w_monto_original = op_monto,
          @w_tramite_oper_original = op_tramite
   from  ca_operacion
   where op_operacion = @i_operacionca

   select @w_monto_alterna = op_monto
   from  ca_operacion
   where op_operacion = @w_operacion_nueva

   select  @w_garantia_especial = gp_garantia
   from   cob_credito..cr_gar_propuesta, 
          cob_custodia..cu_custodia
   where  gp_tramite  = @w_tramite_oper_original
   and    gp_garantia = cu_codigo_externo
   and    cu_estado in ('P', 'X', 'F', 'V')
   and    cu_tipo in (select a.codigo from cobis..cl_catalogo a
                         where a. tabla = (select codigo from cobis..cl_tabla
                                           where tabla = 'ca_tgar_fpagoespeciales')
                         and   a.valor = @i_abd_concepto ) 
                         

   insert into ca_operacion_alterna(
   oa_operacion_alterna,  oa_operacion_original,  oa_monto_alterna,
   oa_monto_original,     oa_garantia,            oa_fpago)
   values(
   @w_operacion_nueva,    @i_operacionca,         @w_monto_alterna,
   @w_monto_original,     @w_garantia_especial,   @i_abd_concepto)
   
   if @@error <> 0                                           
   begin                                                       
      select @w_error = 710001                                 
      return @w_error                                          
   end                        
            
   update ca_rubro_op
   set ro_porcentaje_efa = @w_tasa_efa,
       ro_porcentaje_aux = @w_tasa_efa,
       ro_porcentaje     = @w_tasa_nominal,
       ro_referencial    = 'TFIJA',
       ro_signo          = '+',
       ro_factor         = @w_tasa_efa,
       ro_tipo_puntos    = 'B'
   where ro_operacion    = @w_operacion_nueva
   and   ro_tipo_rubro   = 'M'
   
   if @@error != 0                                                
   begin                                                       
      select @w_error = 705003                                 
      return @w_error                                         
   end                        
      
   update ca_rubro_op
   set    ro_signo          = @w_ro_signo,
          ro_factor         = @w_ro_factor,
          ro_referencial    = @w_ro_referencial,
          ro_porcentaje     = @w_ro_porcentaje,
          ro_porcentaje_aux = @w_ro_porcentaje_aux,
          ro_porcentaje_efa = @w_ro_porcentaje_efa
   where  ro_operacion = @w_operacion_nueva
   and    ro_concepto  = @w_rubro_int
   
   if @@error != 0                                                
   begin                                                       
      select @w_error = 705003                                 
      return @w_error                                         
   end
   
end
return 0
go
