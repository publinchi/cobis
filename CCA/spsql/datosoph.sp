/************************************************************************/
/*  Archivo:                    datosoph.sp                             */
/*  Stored procedure:           sp_datos_operacion_his                  */
/*  Base de datos:              cob_cartera_his                         */
/*  Producto:                   Cartera                                 */
/*  Disenado por:               Francisco Yacelga                       */
/*  Fecha de escritura:         25/Nov./1997                            */
/************************************************************************/
/*                              IMPORTANTE                              */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  'MACOSA'.                                                           */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado hecho por alguno de sus             */
/*  usuarios sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de MACOSA o su representante.                 */
/************************************************************************/  
/*              PROPOSITO                                               */
/*  Consulta de los datos de una operacion                              */
/************************************************************************/
/*                            MODIFICACIONES                            */
/*  DAG 29/04/1999 (GrupoCONTEXT)  Cambios de Forma                     */
/*  RBU 29/04/1999 (GrupoCONTEXT)  Cambios de Forma                     */
/*  23-JUL-2009    Tania Suarez    Ajustes Bancamia                     */
/*  JUN-09-2010    Elcira Pelaez   Quitar Codigo Causacion Pasivas      */
/*                                 y comentarios                        */
/************************************************************************/
use cob_cartera_his
go

set ansi_nulls off
go
 
if exists (select 1 from sysobjects where name = 'sp_datos_operacion_his')
   drop proc sp_datos_operacion_his
go

create proc sp_datos_operacion_his (
   @s_ssn               int           = null,
   @s_date              datetime      = null,
   @s_user              varchar (14)  = null,
   @s_term              varchar (64)  = null,
   @s_corr              char(1)       = null,
   @s_ssn_corr          int           = null,
   @s_ofi               smallint      = null,
   @t_rty               char(1)       = null,
   @t_debug             char(1)       = 'N',
   @t_file              varchar(14)   = null,
   @t_trn               smallint      = null,  
   @i_banco             varchar (64)  = null,
   @i_operacion         char(1)       = null,
   @i_formato_fecha     int           = null,
   @i_secuencial_ing    int           = null,
   @i_toperacion        varchar (64)  = null,
   @i_moneda            int           = null,
   @i_siguiente         int           = null,
   @i_dividendo         int           = null,
   @i_numero            int           = null,
   @i_sucursal          int           = null,
   @i_filial            int           = null,
   @i_oficina           smallint      = null,
   @i_concepto          varchar (64)  = '',
   @i_fecha_abono       datetime      = null,
   @i_opcion            tinyint       = null,
   @i_tramite           int           = null,
   @i_sec_detpago       int              = 0
   --@i_fecha_inicial     smalldatetime         = null

)

as
declare @w_sp_name             varchar(32),
        @w_return              int,
        @w_error               int,
        @w_operacionca         int,
        @w_det_producto        int,
        @w_tipo                char(1),
        @w_tramite             int,
        @w_count               int,
        @w_filas               int,
        @w_filas_rubros        int,
        @w_primer_des          int,
        @w_bytes_env           int,
        @w_buffer              int,
        @w_secuencial_apl      int,
        @w_fecha_u_proceso     datetime,
        @w_moneda              int,
        @w_moneda_nacional     tinyint,
        @w_cotizacion          money,
        @w_op_moneda           tinyint,
        @w_contador            int,
        @w_dtr_dividendo       int,
        @w_dtr_concepto        catalogo,
        @w_dtr_estado          char(20),
        @w_dtr_cuenta          cuenta,
        @w_dtr_moneda          char(20),
        @w_dtr_monto           money,
        @w_dtr_monto_mn        money,
        @w_ente                int,
        @w_op_operacion        int,
        @w_op_migrada          varchar(20)

--- Captura nombre de Stored Procedure 
select  
@w_sp_name = 'sp_datos_operacion_his',
@w_buffer  = 2500   --TAMANIO MAXIMO DEL BUFFER DE RED


-- CODIGO DE LA MONEDA LOCAL
select @w_moneda_nacional = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'
set transaction isolation level read uncommitted


--- CHEQUEO QUE EXISTA LA OPERACION 

select @w_operacionca        = op_operacion,
       @w_tramite            = op_tramite,
       @w_op_migrada         = op_migrada,
       @w_tipo               = op_tipo,
       @w_fecha_u_proceso    = op_fecha_ult_proceso,
       @w_moneda             = op_moneda
from   ca_operacion
where  op_banco = @i_banco

if @@rowcount = 0 
begin
   select @w_error = 710022
   goto ERROR
end  

--- DETERMINAR EL VALOR DE COTIZACION DEL DIA 
if @w_moneda = @w_moneda_nacional
   select @w_cotizacion = 1.0
else
begin
   exec cob_cartera..sp_buscar_cotizacion
        @i_moneda     = @w_moneda,
        @i_fecha      = @w_fecha_u_proceso,
        @o_cotizacion = @w_cotizacion output
end


--- CONSULTAR ABONOS
if @i_operacion='A'  
begin

select 
   'Sec_ing      '     = ab_secuencial_ing, 
   'Sec_pag      '     = ab_secuencial_pag, 
   'Fecha_Ing   '      = substring(convert(varchar,ab_fecha_ing,@i_formato_fecha),1,15),
   'Fecha_Pag   '      = substring(convert(varchar,ab_fecha_pag,@i_formato_fecha),1,15),
   'Usuario '          = ab_usuario,
   'Regional'          = ab_oficina,
   'Retencion'         = ab_dias_retencion, 
   'Cuota_Completa'    = ab_cuota_completa,
   'Anticipos'         = ab_aceptar_anticipos,
   'Tipo_Reduccion'    = ab_tipo_reduccion, 
   'Tipo_Cobro'        = ab_tipo_cobro,
   'Clase'             = abd_tipo,
   'Forma_de_Pago'     = abd_concepto,
   'Moneda'            = abd_moneda,
   'Cuenta_Referencia' = substring(abd_cuenta,1,24),
   'Comentario'        = substring(abd_beneficiario,1,50),
   'Monto'             = abd_monto_mpg,
   'Estado'            = ab_estado,  
   'Sec_consulta'      = convert(int,row_number()over(partition by abd_operacion order by ab_secuencial_ing ))
   into #consulta_abono 
   from  ca_abono,
         ca_abono_det
   where ab_operacion = @w_operacionca
   and   ab_operacion = abd_operacion
   and   ab_secuencial_ing = abd_secuencial_ing
   --and  ab_secuencial_ing > @i_secuencial_ing
   order by ab_secuencial_ing

   set rowcount 16
   select 
   Sec_ing   , 
   Sec_pag   , 
   Fecha_Ing ,
   Fecha_Pag , 
   Usuario   ,
   Regional  ,
   Retencion ,
   Cuota_Completa,
   Anticipos,
   Tipo_Reduccion,
   Tipo_Cobro,
   Clase,
   Forma_de_Pago,
   Moneda,
   Cuenta_Referencia,
   Comentario,
   Monto,
   Estado,
   Sec_consulta   
   from  #consulta_abono
   where Sec_consulta > @i_secuencial_ing
   order by Sec_consulta

   set rowcount 0
end

--- CONSULTA DEL DETALLE DEL ABONO 
if @i_operacion = 'D' 
begin
   if @i_sec_detpago = 0 and @w_op_migrada is null
   begin

      ---Elimina todo lo del usuario para insertar nuevamente
      delete from cob_cartera..ca_consulta_rec_pago_tmp
      where usuario = @s_user

      select @w_secuencial_apl = ab_secuencial_pag
      from   ca_abono
      where  ab_secuencial_ing = @i_secuencial_ing
      and    ab_operacion = @w_operacionca
      select @w_contador = 0

      declare cursor_operacion cursor 
      for select dtr_dividendo,               
                 dtr_concepto,               
                 substring((select es_descripcion from cob_cartera..ca_estado  where es_codigo = ca_det_trn.dtr_estado),1,10),
                 rtrim(ltrim(dtr_cuenta)),      
                 substring((select convert(varchar(2),mo_moneda) + '-' + mo_descripcion from cobis..cl_moneda
                            where mo_moneda = ca_det_trn.dtr_moneda),1,10),
                 convert(float, dtr_monto),   convert(float, dtr_monto_mn)
          from  ca_det_trn
          where dtr_secuencial = @w_secuencial_apl 
          and   dtr_operacion  = @w_operacionca
          and   dtr_codvalor <> 10099

      open cursor_operacion
      fetch cursor_operacion
      into @w_dtr_dividendo,   
           @w_dtr_concepto,
           @w_dtr_estado,
           @w_dtr_cuenta,
           @w_dtr_moneda,
           @w_dtr_monto,
           @w_dtr_monto_mn

      while @@fetch_status = 0
      begin   

         select @w_contador = @w_contador + 1

         ---cargar la tabla temporal
         insert into cob_cartera..ca_consulta_rec_pago_tmp (
         identifica,     secuencial,    usuario,
         descripcion,    cuota,         dias,
         fecha_ini,      fecha_fin,     monto,
         monto_mn,       tasa,          des_moneda,
         des_estado,     operacion,     cuenta
         )
         values 
         (
         'DOP',            @w_contador,       @s_user,
         @w_dtr_concepto,  @w_dtr_dividendo,  0,
         @s_date,          @s_date,           @w_dtr_monto,
         @w_dtr_monto_mn,  0,                 @w_dtr_moneda,
         @w_dtr_estado,    @w_operacionca,    @w_dtr_cuenta
         )

         fetch cursor_operacion
         into @w_dtr_dividendo,   
              @w_dtr_concepto,
              @w_dtr_estado,
              @w_dtr_cuenta,
              @w_dtr_moneda,
              @w_dtr_monto,
              @w_dtr_monto_mn
      end
      close cursor_operacion
      deallocate cursor_operacion
 
   end --secuencial = 0 


   if @i_sec_detpago = 0 and @w_op_migrada is not null
   begin

      ---Elimina todo lo del usuario para insertar nuevamente
      delete from cob_cartera..ca_consulta_rec_pago_tmp
      where usuario = @s_user

      select @w_secuencial_apl = ab_secuencial_pag
      from   ca_abono
      where  ab_secuencial_ing = @i_secuencial_ing
      and    ab_operacion      = @w_operacionca
   
      select @w_contador = 0

      declare cursor_operacion2 cursor 
      for select case when ar_dividendo < 0 then 0 else ar_dividendo end,               
                 ar_concepto,               
                 substring((select es_descripcion from cob_cartera..ca_estado  where es_codigo = ca_abono_rubro.ar_estado),1,10),
                 substring((select convert(varchar(2),mo_moneda) + '-' + mo_descripcion from cobis..cl_moneda
                            where mo_moneda = ca_abono_rubro.ar_moneda),1,10),
                 convert(float, ar_monto),   
                 convert(float, ar_monto_mn)
          from  ca_abono_rubro
          where ar_secuencial = @w_secuencial_apl
          and   ar_operacion  = @w_operacionca

      open cursor_operacion2
      fetch cursor_operacion2
      into @w_dtr_dividendo,   
           @w_dtr_concepto,
           @w_dtr_estado,
           @w_dtr_moneda,
           @w_dtr_monto,
           @w_dtr_monto_mn

      while @@fetch_status = 0
      begin   

         select @w_contador = @w_contador + 1

         ---cargar la tabla temporal
         insert into cob_cartera..ca_consulta_rec_pago_tmp (
         identifica,     secuencial,    usuario,
         descripcion,    cuota,         dias,
         fecha_ini,      fecha_fin,     monto,
         monto_mn,       tasa,          des_moneda,
         des_estado,     operacion,     cuenta
         )
         values 
         (
         'DOP',            @w_contador,       @s_user,
         @w_dtr_concepto,  @w_dtr_dividendo,  0,
         @s_date,          @s_date,           @w_dtr_monto,
         @w_dtr_monto_mn,  0,                 @w_dtr_moneda,
         @w_dtr_estado,    @w_operacionca,    0
         )

         fetch cursor_operacion2
         into @w_dtr_dividendo,   
              @w_dtr_concepto,
              @w_dtr_estado,
              @w_dtr_moneda,
              @w_dtr_monto,
              @w_dtr_monto_mn
      end
      close cursor_operacion2
      deallocate cursor_operacion2
      
   end
 

   set rowcount 20
   select 'Dividendo'  = cuota,
          'Concepto'   = descripcion,
          'Estado'     = des_estado,
          'Cuenta'     = cuenta,
          'Moneda'       = des_moneda,
          'Monto MOP'  = convert(float, monto),
          'Monto MLE'  = convert(float, monto_mn),
          'Sec'        = secuencial
   from cob_cartera..ca_consulta_rec_pago_tmp 
   where usuario  = @s_user
   and   identifica in( 'DOP','TOTALES')
   and   operacion  = @w_operacionca
   and   secuencial > @i_sec_detpago
   set rowcount 0

end --- operacion D

if @i_operacion = 'X'
begin
   delete from cob_cartera..ca_consulta_rec_pago_tmp
   where usuario = @s_user
end

--- CONDICIONES DE PAGO 
if @i_operacion='P'
begin
   select op_tipo_cobro,
          op_aceptar_anticipos,
          op_tipo_reduccion,
          op_tipo_aplicacion,
          op_cuota_completa,
          op_fecha_fin,
          op_pago_caja,
          op_calcula_devolucion
   from ca_operacion, cob_cartera..ca_estado
   where op_operacion = @w_operacionca
   and  es_codigo     = op_estado
end


--- CONSULTA TASAS 

if @i_operacion='T' 
begin
   select @i_siguiente = isnull(@i_siguiente,0)

   set rowcount 20   
   select 'Secuencial'             = ts_secuencial,
          'Fecha Mod.'             = convert(varchar(12),ts_fecha,@i_formato_fecha),
          'No.Cuota'               = ts_dividendo,
          'Rubro'                  = ts_concepto,
          'Valor Aplicar'          = ts_referencial,
          'Signo Aplicar'          = ts_signo,
          'Spread Aplicar'         = convert(varchar(25), ts_factor),
          'Tasa Actual'            = ts_porcentaje,
          'Tasa Efectiva Anual'    = ts_porcentaje_efa,
          'Tasa Referencial'       = ts_tasa_ref,
          'Fecha Tasa Referencial' = convert(varchar(12),ts_fecha_referencial,@i_formato_fecha),
          'Valor Tasa Referencial' = ts_valor_referencial
   from  ca_tasas --X
   where ts_operacion  = @w_operacionca
   and   ts_secuencial > @i_siguiente
end



-- DEUDORES Y CODEUDORES DE UNA OPERACION*/
if @i_operacion = 'E' 
begin
    /*Mroa: NUEVA RUTINA PARA TRAER LOS DEUDORES DE LA OPERACION */
    select 'Codigo'      = de_cliente,
           'CE./NIT.'    = en_ced_ruc,
           'Rol'         = de_rol,
           'Nombre'      = en_nomlar,
           'Telefono'    = isnull((select top 1 te_valor
                                   from cobis..cl_telefono
                                   where te_ente = de_cliente),'SIN TELEFONO'),
           'Direccion'   = isnull((select top 1 di_descripcion
                                   from cobis..cl_direccion
                                   where di_direccion = de_cliente),'SIN DIRECCION'),
           'Cob/Central' = de_cobro_cen
    from   ca_operacion,
           cob_credito..cr_deudores,
           cobis..cl_ente
    where  op_banco      = @i_banco
    and    de_tramite    = op_tramite
    and    en_ente       = de_cliente
    order by de_rol desc

end



--- ESTADO ACTUAL 
if @i_operacion = 'S' 
begin
---SOLO PARA LA PRIMERA TRANSMISION 
   if @i_dividendo = 0 
   begin

       --- RUBROS QUE PARTICIPAN EN LA TABLA
      select ro_concepto, co_descripcion, ro_tipo_rubro,ro_porcentaje
      from  ca_rubro_op, cob_cartera..ca_concepto
      where ro_operacion = @w_operacionca
      and   ro_fpago    in ('P','A','M','T')
      and   ro_concepto = co_concepto
      order by ro_concepto

      select @w_filas_rubros = @@rowcount
      
      
      
      if @w_filas_rubros < 10 
         select @w_filas_rubros = @w_filas_rubros + 3

      select @w_bytes_env    = @w_filas_rubros * 90  --83  --BYTES ENVIADOS

      select @w_primer_des = min(dm_secuencial)
      from   cob_cartera..ca_desembolso
      where  dm_operacion  = @w_operacionca

      
            
      select dtr_dividendo, sum(dtr_monto),'D' /*DESEMBOLSOS PARCIALES*/ 
      from   ca_det_trn, ca_transaccion, ca_rubro_op
      where  tr_banco      = @i_banco 
      and    tr_secuencial = dtr_secuencial
      and    tr_operacion  = dtr_operacion
      and    dtr_secuencial <> @w_primer_des
      and    ro_operacion = @w_operacionca
      and    ro_tipo_rubro= 'C'
      and    tr_tran      = 'DES'
      and    tr_estado    in ('ING','CON')
      and    ro_concepto  = dtr_concepto 
      group by dtr_dividendo
      union
      select dtr_dividendo, sum(dtr_monto),'R'       /*REESTRUCTURACION*/
      from ca_det_trn, ca_transaccion, ca_rubro_op
      where  tr_banco      = @i_banco 
      and   ro_operacion = @w_operacionca
      and   ro_concepto  = dtr_concepto 
      and   ro_tipo_rubro= 'C'
      and   tr_tran      = 'RES'
      and   tr_estado    in ('ING','CON')
      and   tr_secuencial = dtr_secuencial
      and   tr_operacion  = dtr_operacion
      group by dtr_dividendo
       
      
      select @w_filas_rubros = @@rowcount
      select @w_bytes_env    = @w_bytes_env + (@w_filas_rubros * 13)

      
      
      select  di_dias_cuota
      from ca_dividendo 
      where di_operacion = @w_operacionca
      and   di_dividendo > @i_dividendo 
      order by di_dividendo

      select @w_filas = @@rowcount
      
      select @w_bytes_env  = @w_bytes_env + (@w_filas * 4) --1) 
   
   end

   
   
   if @i_opcion = 0 
   begin

   
      if @i_dividendo = 0 
      begin
         select @w_count = (@w_buffer - @w_bytes_env) / 38  
      end
      else select @w_count = @w_buffer / 38

      
      set rowcount @w_count

      
      --- FECHAS DE VENCIMIENTOS DE DIVIDENDOS Y ESTADOS
      select convert(varchar(10),di_fecha_ven,@i_formato_fecha),  substring(es_descripcion,1,20),
             0,di_prorroga
      from ca_dividendo, cob_cartera..ca_estado
      where di_operacion = @w_operacionca
      and   di_dividendo > @i_dividendo 
      and   di_estado    = es_codigo

      order by di_dividendo

      select @w_filas = @@rowcount
      select @w_bytes_env    =  (@w_filas * 38)

      
      select @w_count

   end
   else 
   begin 
      select @w_filas = 0,
             @w_count = 1,
             @w_bytes_env = 0
   end
   
   
   if @w_filas < @w_count 
   begin
      declare
         @w_total_reg  int


      select @w_total_reg = count(distinct convert(varchar, di_dividendo) + ro_concepto)
      from  ca_rubro_op                          
            inner join ca_dividendo on
               (di_dividendo > @i_dividendo
               or   (di_dividendo = @i_dividendo
               and  ro_concepto > @i_concepto)) 
               and  ro_operacion = @w_operacionca
               and  ro_fpago    in ('P','A','M','T')   
               and  di_operacion  = @w_operacionca
                  left outer join ca_amortizacion on
                  ro_concepto  = am_concepto
                  and   di_dividendo = am_dividendo
                  and   am_operacion = @w_operacionca
      
      select @w_count = (@w_buffer - @w_bytes_env) / 21  
                                                         
      
      if @i_dividendo > 0 and @i_opcion = 0
         select @i_dividendo = 0
                     
      set rowcount @w_count
 
      select di_dividendo,ro_concepto,
      convert(float, isnull(sum(am_cuota+am_gracia),0))
      from ca_rubro_op
      inner join ca_dividendo on           
         (di_dividendo > @i_dividendo
          or    (di_dividendo = @i_dividendo 
          and ro_concepto > @i_concepto)) 
          and   ro_operacion = @w_operacionca                  
          and   ro_fpago in ('P','A','M','T')  
          and   di_operacion  = @w_operacionca                           
             left outer join ca_amortizacion on
                ro_concepto  = am_concepto
                and   di_dividendo = am_dividendo
                and am_operacion = @w_operacionca      
                group by di_dividendo,ro_concepto
                order by di_dividendo,ro_concepto

      ---EPB-FEB-09-2006
      
      if @w_total_reg = @w_count 
         select @w_count = @w_count + 1
                                   
      select @w_count 
   end

end

--- ESTADO ACTUAL DETALLE 
if @i_operacion = 'L' 
begin
   select 'Rubro'              = am_concepto,
          'Estado'             = substring(es_descripcion,1,10),
          'Periodo'            = am_periodo,
          'Cuota            '  = convert(float, am_cuota),
          'Gracia           '  = convert(float, am_gracia),
          'Pagado           '  = convert(float, am_pagado),   
          'Acumulado        '  = convert(float, am_acumulado),
          'Secuencia   '    = am_secuencia
   from ca_amortizacion, 
        cob_cartera..ca_estado
   where am_operacion = @w_operacionca
   and   am_dividendo = @i_dividendo 
   and   am_estado    =  es_codigo 
    
end

--- INSTRUCCIONES OPERATIVAS 

if @i_operacion = 'I' 
begin
   select @i_numero = isnull(@i_numero , 0)
   
   set rowcount 8
   select  'N·mero'       = in_numero,
           'Tipo'            = in_codigo,
           'Instruccion'     = ti_descripcion,
           'Descripcion'     = in_texto,
           'Estado'          = in_estado,
           'Aprobado Por'    = fu_nombre,
           'Fecha Ejecucion' = convert(char(10), in_fecha_eje, 103),
           'Ejecutado Por'   = in_login_eje
            from cob_credito..cr_instrucciones
            inner join cob_credito..cr_tinstruccion on
               in_tramite = @w_tramite
               and ti_codigo = in_codigo                                   
               and in_numero > @i_numero  
                  left outer join  cobis..cl_funcionario noholdlock on
                  in_login_aprob = fu_login
   
   set rowcount 0
end


--- GARANTIAS

if @i_operacion = 'G' begin
   if @i_sucursal is null   
      select @i_sucursal = of_sucursal
      from cobis..cl_oficina
      where of_oficina = @i_oficina
      set transaction isolation level read uncommitted

   set rowcount 20
   
     select 
      distinct  gp_garantia as GARANTIA,
                cu_estado as ESTADO_GAR,
                substring(cu_tipo,1,15)+'   '+substring(tc_descripcion,1,20) as DESCRIPCION,
                cg_ente as COD_CLIENTE,
                substring(cg_nombre,1,25) as NOMBRE_CLIENTE, 
                convert(float,cu_valor_actual) as VALOR_ACTUAL,
                cu_moneda as MON,
                convert(varchar(10),cu_fecha_ingreso,103) as F_INGRESO
   from cob_custodia..cu_custodia,
        cob_custodia..cu_cliente_garantia,
        cob_custodia..cu_tipo_custodia,
        cob_credito..cr_gar_propuesta,
        cob_cartera..ca_operacion
   where ((op_banco = @i_banco ) or (op_tramite = @i_tramite))
   and op_tramite           = gp_tramite 
   and cu_codigo_externo    = gp_garantia
   and cu_codigo_externo    = cg_codigo_externo
   and cu_tipo              = tc_tipo
   and cu_estado in ('V','F','P')
   and cg_principal  = 'D' 
   order by GARANTIA,
            ESTADO_GAR,
            DESCRIPCION,
            COD_CLIENTE,
            NOMBRE_CLIENTE, 
            VALOR_ACTUAL,
            MON,
            F_INGRESO
end

--- RUBROS 
if @i_operacion = 'R'  
begin
   select 'Rubro'              = ro_concepto,
   'Descripcion'               = substring(co_descripcion,1,30), 
   'Tipo Rubro'                = ro_tipo_rubro, 
   'F. de Pago'                = ro_fpago ,
   'Valor'                     = round(convert(float, ro_valor),2), 
   'Prioridad'                 = ro_prioridad, 
   'Paga Mora'                 = ro_paga_mora,
   'Causa'                     = ro_provisiona,
   'Referencia'                = ro_referencial,
   'Signo'                     = ro_signo ,
   'Valor/Puntos'              = round(ro_factor,2),              
   'Tipo/Puntos'               = ro_tipo_puntos,   
   'Valor/Tasa Total'          = ro_porcentaje,
   'Tasa Negociada'            = ro_porcentaje_aux,
   'Tasa Ef.Anual'             = ro_porcentaje_efa,
   'Signo reaj.'               = ro_signo_reajuste ,
   'Valor/Puntos de Reaj.'     = ro_factor_reajuste,     
   'Referencia de Reaj.'       = substring(ro_referencial_reajuste,1,10),
   'Gracia'                    = ro_gracia,
   'Base de calculo'           = ro_base_calculo,
   'Por./Cobrar/TIMBRE'        = ro_porcentaje_cobrar,
   'Tipo Garantia'             = ro_tipo_garantia,
   'Nro. Garantia'             = ro_nro_garantia, 
   '%Cobertura Gar.'           = ro_porcentaje_cobertura,
   'Valor Garantia'            = ro_valor_garantia,
   'Tipo Dividendo'            = ro_tperiodo,
   'No. Periodos Int.'         = ro_periodo,
   'Tabla Otras Tasas'         = ro_tabla
   from ca_rubro_op, 
        cob_cartera..ca_concepto
   where ro_operacion   = @w_operacionca 
   and   ro_concepto=co_concepto
   and   ro_concepto > isnull(@i_concepto,'')
   order by ro_concepto
   
end

-- OPERACIONES RENOVADAS                            
/* GAL 26/MAY/2009 */
if @i_operacion = 'N'  
begin
   select 
      'Tramite'            = or_tramite,
      'Operacion Renovada' = or_num_operacion,     
      'Monto Original'     = or_monto_original,
      'Saldo Renovado'     = or_saldo_original,
      'Tipo Credito'       = or_toperacion,
      'Funcionario'        = or_login
   from ca_operacion, cob_credito..cr_op_renovar
   where op_operacion           = @w_operacionca
   and   or_tramite             = op_tramite
   and   or_finalizo_renovacion = 'S'
   order by or_num_operacion
end

return 0

ERROR:

exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_error
return @w_error

go


