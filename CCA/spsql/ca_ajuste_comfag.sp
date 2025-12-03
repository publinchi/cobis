/*************************************************************************/
/*      Archivo:                ca_ajuste_comfag.sp                      */
/*      Stored procedure:       sp_ajuste_comfag                         */
/*      Base de datos:          cob_cartera                              */
/*      Producto:               CARTERA                                  */
/*      Creado por:             Andres Muñoz                             */
/*      Fecha de escritura:     16-Dic-2014                              */
/*************************************************************************/
/*                              IMPORTANTE                               */
/*      Este programa es parte de los paquetes bancarios propiedad de    */
/*      'COBISCORP', representantes exclusivos para el Ecuador de la     */
/*      Su uso no autorizado queda expresamente prohibido asi como       */
/*      cualquier alteracion o agregado hecho por alguno de sus          */
/*      usuarios sin el debido consentimiento por escrito de la          */
/*      Presidencia Ejecutiva de COBISCORP o su representante.           */
/*************************************************************************/
/*                              PROPOSITO                                */
/*      Este store procedure es un proceso batch el cual realizara la    */
/*      validacion y ajuste de cobros de comision de garantias Finagro   */
/*      confrontando el valor cobrado por finagro con el valor cobrado   */
/*      por el Core, y dependiendo el caso realizara un movimiento       */
/*      segun corresponda CXC(Cuenta por Cobrar) o PAG(Abono a capital). */                                                        
/*************************************************************************/
/*                              MODIFICACIONES                           */
/*      FECHA           AUTOR              RAZON                         */
/*      16-Dic-2014     Andres Muñoz       Emision Inicial               */
/*************************************************************************/
use cob_cartera
go

set nocount on
set ansi_nulls off

if exists (select 1 from sysobjects where name = 'sp_ajuste_comfag' and type = 'P')
   drop proc sp_ajuste_comfag
go
---VERsion Dic.19.2014
create proc sp_ajuste_comfag(
@i_param1        varchar(25) --NOMBRE ARCHIVO PROCESAR
)
as
declare
@w_archivo           varchar(25),
@w_path_plano        varchar(255),
@w_error             int,
@w_banco             varchar(40),
@w_valor             money,
@w_tipo_ajuste       char(3),
@w_srv               varchar(50),
@w_msg               varchar(255),
@w_comando           varchar(1000),
@w_s_app             varchar(255),
@w_destino           varchar(2500),
@w_errores           varchar(1500),
@w_acciones          int,
@w_acciones1         int,
@w_operacion         int,
@w_sp_name           varchar(50),
@w_iden              varchar(20),
@w_ente              int,
@w_concepto_AJFAG    catalogo,
@w_valor_diferencia  money,
@w_valor_core        money,
@w_valor_des         money,
@w_valor_pag         money,
@w_fecha_mov         datetime,
@w_com_fag_pag       catalogo,
@w_iva_com_pag       catalogo,
@w_par_fag_des       catalogo,
@w_iva_fag_des       catalogo,
@w_valor_dif         money,
@w_concepto_AJUFAG   catalogo,
@w_toperacion        catalogo,
@w_moneda            smallint,
@w_fecha_cartera     datetime,
@w_sec_tran          int,
@w_co_categoria      catalogo,
@w_op_oficina        int,
@w_nombre            varchar(255),
@w_nombre_plano      varchar(2500),
@w_col_id            int,
@w_columna           varchar(100),
@w_cabecera          varchar(2500),
@w_nom_tabla         varchar(100)

select @w_fecha_cartera = fc_fecha_cierre
from   cobis..ba_fecha_cierre
where  fc_producto = 7

-- ASIGNACION VARIABLES DE TRABAJO 
select 
@w_archivo    = @i_param1,
@w_sp_name    = 'sp_ajuste_comfag'

--Ruta de publicacion archivo marcacion
select @w_path_plano = pp_path_destino
from   cobis..ba_path_pro
where  pp_producto = 7

if @w_path_plano is null begin
   select 
   @w_error = 1,
   @w_msg   = 'NO EXISTE EL PATH DE PUBLICACION ARCHIVO AJUSTE COMISION FINAGRO'
   goto ERRORFIN
end

select @w_s_app = pa_char
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'S_APP'

if @w_s_app is null begin
   select 
   @w_error = 2,
   @w_msg   = 'NO EXISTE EL PARAMETRO S_APP'
   goto ERRORFIN
end

select @w_errores = @w_path_plano + @w_archivo + '.err'

select @w_srv = nl_nombre
from   cobis..ad_nodo_oficina
where  nl_nodo = 1

-- BORRA REGISTROS CARGAS ANTERIORES TABLA TRABAJO
if exists (select 1 from sysobjects where name = 'ca_carga_finagro' and type = 'U')
   delete from cob_cartera..ca_carga_finagro WHERE fi_secuencia >= 0
else
begin
   select 
   @w_error = 3,
   @w_msg   = 'NO EXISTE LA TABLA DE TRABAJO FINAGRO'
   goto ERRORFIN
end

-- BORRA REGISTROS CARGAS ANTERIORES TABLA TEMPORAL
if exists (select 1 from sysobjects where name = 'ca_carga_finagro_tmp' and type = 'U')
   delete from cob_cartera..ca_carga_finagro_tmp WHERE fi_fecha_mov >= '1990/01/01'

---ANTES DE CARGAR HAY QUE VALIDAR QUE EXISTAN LOS PARAMETROS NECESARIOS
---=============================================================================
select @w_concepto_AJFAG = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'AJFAG'

if @w_concepto_AJFAG is null
begin
   select 
   @w_error = 4,
   @w_msg   = 'ERROR NO EXISTE LA FORMA PAGO AJUSTE COMISION FINAGRO (AJFAG)'
   goto ERRORFIN
end

select @w_concepto_AJUFAG = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'AJUFAG'

if @w_concepto_AJUFAG is null
begin
   select 
   @w_error = 5,
   @w_msg   = 'ERROR NO EXISTE EL PARAMETRO PARA REGISTRO DE CXC (AJUFAG)'
   goto ERRORFIN
end

select @w_co_categoria =  co_categoria
from   ca_concepto
where  co_concepto = @w_concepto_AJUFAG

if @w_co_categoria is null
begin
   select 
   @w_error = 7,
   @w_msg   = 'ERROR NO EXISTE EL CONCEPTO PARA REGISTRAR CXC'
   goto ERRORFIN
end                  
                                  
---CODIGO DEL RUBRO COMISION FAG DES
select @w_par_fag_des = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'CMFAGD'  -- JAR REQ 197
set transaction isolation level read uncommitted

if @w_par_fag_des is null
begin
   select 
   @w_error = 8,
   @w_msg   = 'ERROR NO EXISTE EL RUBRO PARA COMSION FAG EN DESEMBOLSO'
   goto ERRORFIN
end

select @w_iva_fag_des = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'ICFAGD'
set transaction isolation level read uncommitted

if @w_iva_fag_des is null
begin
   select 
   @w_error = 9,
   @w_msg   = 'ERROR NO EXISTE EL RUBRO PARA IVA DE COMISION FAG EN DESEMBOLSO'
   goto ERRORFIN
end

select @w_com_fag_pag = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'CMFAGP'
set transaction isolation level read uncommitted

if @w_com_fag_pag is null
begin
   select 
   @w_error = 10,
   @w_msg   = 'ERROR NO EXISTE EL RUBRO PARA COMISION FAG EN EL PAGO'
   goto ERRORFIN
end

select @w_iva_com_pag = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'ICMFAG'
set transaction isolation level read uncommitted

if @w_iva_com_pag is null
begin
   select 
   @w_error = 11,
   @w_msg   = 'ERROR NO EXISTE EL RUBRO PARA IVA COMISION FAG EN EL PAGO'
   goto ERRORFIN
end

---FIN VALIDAR PARAMETROS NECESARIOS
---=============================================================================

---  CARGA DE DATOS ENVIADOS EN ARCHIVO A TABLA DE TRABAJO 
select @w_comando = @w_s_app + 's_app bcp -auto -login cob_cartera..ca_carga_finagro_tmp in ' + @w_path_plano + '\' + @w_archivo + 
                       ' -b5000 -c -e ' + @w_errores + ' -F2 -t "|" -config ' + @w_s_app + 's_app.ini'
                       
exec @w_error = xp_cmdshell @w_comando
   
if @w_error <> 0 
begin
   select 
   @w_error = 12,
   @w_msg   = 'ERROR CARGANDO EL ARCHIVO: ' + @w_archivo
   goto ERRORFIN
end
else
begin
   -- elimina archivo errores de no existir 
   select @w_comando = 'del ' + @w_path_plano + @w_archivo + '.err'

   exec @w_error = xp_cmdshell @w_comando

   if @w_error <> 0 begin
      select @w_msg = 'EJECUCION comando bcp FALLIDA (Eliminacion temp .err). REVISAR ARCHIVOS DE LOG GENERADOS. '
      goto ERRORFIN
   end
end

---CARGARLA EN UNA TEMPORAL CON CONSECUTIVOS
select
fecha_movimiento = fi_fecha_mov,
identificacion   = fi_indentificacion,    
banco            = fi_Obligacion,
valor            = fi_valor,
tipo             = fi_tipo,
orden            = ROW_NUMBER() OVER(ORDER BY fi_Obligacion)
into #tmp_ENVIOFINAGRO
from ca_carga_finagro_tmp
--order by fi_Obligacion

---CARGAR EN TABLA DE TRABAJO EN ADELANTE
insert into cob_cartera..ca_carga_finagro(
fi_fecha_carga,       fi_secuencia,              fi_identificacion,         
fi_banco ,            fi_valor,                  fi_tipo_ajuste,       
fi_estado_carga,      fi_desc_carga,             fi_cod_error,
fi_diferencia,        fi_fecha_mov)
select 
getdate(),            orden,                     identificacion,
banco,                valor,                     null,
'I',                  null,                      0,
0,                    convert(varchar(10), fecha_movimiento, 103)
from #tmp_ENVIOFINAGRO
         
select @w_acciones = count(1) from #tmp_ENVIOFINAGRO
select @w_acciones1 = 1

while  @w_acciones1 <= @w_acciones
begin
   /*** INICIALIZACION DE VARIABLES ***/
   select 
   @w_operacion         = null,
   @w_ente              = null,
   @w_toperacion        = null,
   @w_moneda            = null,
   @w_op_oficina        = null,
   @w_banco             = null,
   @w_valor             = null,
   @w_iden              = null,
   @w_tipo_ajuste       = null,
   @w_error             = null,
   @w_msg               = null,
   @w_valor_core        = null,
   @w_valor_des         = null,
   @w_valor_pag         = null,
   @w_valor_dif         = null,
   @w_valor_diferencia  = null,
   @w_banco             = null,
   @w_valor             = null,
   @w_iden              = null,
   @w_tipo_ajuste       = null,
   @w_fecha_mov         = null      
   
   select 
   @w_banco       = banco,
   @w_valor       = valor,
   @w_iden        = identificacion,
   @w_tipo_ajuste = tipo,
   @w_fecha_mov   = convert(datetime,substring(fecha_movimiento,4,2) + '/' + substring(fecha_movimiento,1,2)+ '/' + substring(fecha_movimiento,7,4))
   from #tmp_ENVIOFINAGRO
   where  orden = @w_acciones1

   ---INICIO VALIDACION
   ---VALIDAR EXISTENCIA DE OPERACION
   select 
   @w_operacion   = op_operacion,
   @w_toperacion  = op_toperacion,
   @w_moneda      = op_moneda,
   @w_op_oficina  = op_oficina
   from ca_operacion
   where op_banco = @w_banco
   
   if @w_operacion is null
   begin
      select @w_error = 13, @w_msg = 'ERROR OPERACION ENVIADA NO EXISTE'
      goto ERROR_SIG
   end
   
   --- VALIDA SI LA IDENTIFICACION EXISTE EN EL CORE 
   select @w_ente    = en_ente
   from   cobis..cl_ente
   where  en_ced_ruc = @w_iden

   if @w_ente is null
   begin
      select @w_error = 14, @w_msg = 'ERROR NRO IDENTIFICACION ENVIADO NO EXISTE'
      goto ERROR_SIG   
   end
      
   ---VALIDAR CEDULA QUE PERTENEZCA AL CLIENTE DE LA OPERACION
   if (select 1 
       from ca_operacion ,
            cobis..cl_ente
       where op_cliente   = @w_ente 
       and   en_ente      = op_cliente
       and   en_ced_ruc   = rtrim(ltrim(@w_iden))
       and   op_operacion = @w_operacion) is null
   begin
      select @w_error = 15, @w_msg = 'ERROR IDENTIFICACION ENVIADA NO PERTENECE AL CLIENTE DE LA OPERACION'
      goto ERROR_SIG
   end

   if exists (select 1 from ca_operacion where op_operacion = @w_operacion and op_estado = 3)
   begin
      select @w_error = 16, @w_msg = 'ERROR OPERACION EN ESTADO CANCELADO'
      goto ERROR_SIG
   end
   
   --VALIDAR QUE LA OPERACION NO SE HALLA PROCESADO EN ANTERIORES CARGAS
   if exists (select 1 from ca_ajuste_finagro where af_identificacion = @w_iden and af_banco = @w_banco)
   begin
      select @w_error = 17, @w_msg = 'ERROR LA OPERACION YA A SIDO AJUSTADA CON ANTERIORIDAD'
      goto ERROR_SIG
   end
   
   ---VALIDAR QUE LA OPERACION NO TENGA UN PAGO YA REGISTRADO
   ---CON ESTA FORMA DE PAGO PARA NO DUPLICAR EL ABONO O EL IOC
   if exists (select 1 from  ca_abono, ca_abono_det
                       where abd_operacion     = @w_operacion
                       and   abd_concepto      = @w_concepto_AJFAG
                       and   ab_estado         in ('ING','A')
                       and   ab_operacion      = abd_operacion
                       and   ab_secuencial_ing = abd_secuencial_ing
              )
   begin
      select @w_error = 18, @w_msg = 'ERROR YA SE APLICO PARA ESTA OPERACION EL PAGO POR COMISION'
      goto ERROR_SIG
   end

   /*** SE OBTIENE EL VALOR DESCONTADO EN EL DESEMBOLSO ***/
   select @w_valor_des  = isnull(SUM(dtr_monto), 0)
   from   ca_transaccion, ca_det_trn
   where  tr_operacion  = @w_operacion
   and    tr_tran       = 'DES'
   and    tr_estado     <> 'RV'
   and    tr_secuencial > 0
   and    tr_operacion  = dtr_operacion
   and    tr_secuencial = dtr_secuencial
   and    tr_fecha_mov  = @w_fecha_mov
   and    dtr_concepto in (@w_par_fag_des,@w_iva_fag_des)
   
   /*** SE OBTIENE EL VALOR DESCONTADO EN EL PAGO ***/
   select @w_valor_pag  = isnull(SUM(dtr_monto), 0)
   from   ca_transaccion, ca_det_trn
   where  tr_operacion  = @w_operacion
   and    tr_tran       = 'PAG'
   and    tr_estado     <> 'RV'
   and    tr_secuencial > 0
   and    tr_operacion  = dtr_operacion
   and    tr_secuencial = dtr_secuencial
   and    tr_fecha_mov  = @w_fecha_mov
   and    dtr_concepto in (@w_com_fag_pag,@w_iva_com_pag)
   
   select @w_valor_core = @w_valor_des + @w_valor_pag
   
   if @w_valor_core = 0
   begin
      select @w_error = 19, @w_msg = 'ERROR OPERACION NO TIENE COBRO DE COMISION FAG, PARA LA FECHA DADA'
      goto ERROR_SIG
   end

   ---VALIDAR EL TIPO DE AJUSTE QUE HAY QUE HACER
   select @w_valor_diferencia =  @w_valor - @w_valor_core
   
   if @w_valor_diferencia = 0
   begin
      select @w_error = 20, @w_msg = 'LA OBLIGACION ENVIADA SE ENCUENTRA CONSISTENTE FRENTE A LO ENVIADO POR FINAGRO, NO SE REALIZA NINGUNA ACCION'
      goto ERROR_SIG
   end  
       ---ABONO A CAPITAL
   if @w_valor_diferencia > 0
   begin
      --- FINAGRO COBRO MAS QUE EL BANCO POR TANTO HAY REGISTRARLE EL FALTANTE AL CLIENTE EN LA OPERACION
      ---CON UN Ingreso de Otro Cargo 
      if @w_tipo_ajuste = '1'
      begin
         select @w_error = 21, @w_msg = 'EL TIPO DE AJUSTE ENVIADO NO CORRESPONDE AL MOVIMIENTO A APLICAR (CXC)'
         goto ERROR_SIG
      end
      else
         select @w_tipo_ajuste = 'IOC' 
   end
   ELSE
   begin
      --- FINAGRO COBRO MENOS QUE EL BANCO POR TANTO HAY QUE HACERLE UN PAGO
      --- A CAPITAL
      if @w_tipo_ajuste = '2'
      begin
         select @w_error = 22, @w_msg = 'EL TIPO DE AJUSTE ENVIADO NO CORRESPONDE AL MOVIMIENTO A APLICAR (ABONO CAP)'
         goto ERROR_SIG
      end
      else
         select @w_tipo_ajuste = 'PAG' 
   end
   
   ---PONER LA DIFERENCIA EN LA TABLA
   update cob_cartera..ca_carga_finagro
   set fi_diferencia  = @w_valor_diferencia,
       fi_tipo_ajuste = @w_tipo_ajuste
   where  fi_banco = @w_banco
      
   select @w_valor_dif =  abs(@w_valor - @w_valor_core)
      
   if @w_tipo_ajuste = 'PAG'
   begin
      ---EJECUTAR EL SP QUE HACE EL PAGO
      ---print ' va para sp_procesa_comfag operacion ' + cast (@w_banco as varchar) + ' valor ' + cast (@w_valor_dif as varchar)
      exec @w_error = sp_procesa_comfag
         @i_banco          = @w_banco,
         @i_valor          = @w_valor_dif,
         @i_archivo        = @w_archivo,
         @i_fpago          = @w_concepto_AJFAG,
         @i_user           = 'op_batch',
         @i_terminal       = 'CONSOLA'
      
      if @w_error <> 0
      begin
         select 
         @w_msg   = 'ERROR EN EJECUCION PROCESO sp_procesa_comfag ' + cast( @w_error as varchar)
         goto ERROR_SIG
      end    
      else
      begin
         update cob_cartera..ca_carga_finagro
         set fi_estado_carga = 'P',
             fi_desc_carga   = 'ABONO A CAPITAL REALIZADO SATISFACTORIAMENTE'
         where  fi_banco = @w_banco
      end 
      ---FIN EJECUTAR EL SP QUE HACE EL PAGO
   end  ---FIN REGSITRO PAG
   
   if @w_tipo_ajuste = 'IOC'
   begin
      ----VALIDAR QUE LA OPERACION TENGA UN IOC REGISTRADO
      if exists (select 1 from ca_otro_cargo
                 where oc_operacion  = @w_operacion
                 and   oc_concepto   = @w_concepto_AJUFAG
                 and   oc_estado     = 'A'
                 and   oc_referencia like '%OTRO CARGO POR COMISION DEJADA DE COBRAR%'
                 )
      begin
         select 
         @w_msg   = 'CXC POR COMISION YA REGISTRADO PARA ESTA OPERACION' 
         goto ERROR_SIG
      end    
          
      exec @w_error        = cob_cartera..sp_otros_cargos
      @s_ssn               = 1,
      @s_date              = @w_fecha_cartera,
      @s_ofi               = @w_op_oficina,   
      @s_user              = 'op_batch',   
      @s_term              = 'CONSOLA',
      @s_srv               = @w_srv,   
      @i_banco             = @w_banco,
      @i_operacion         = 'I',   
      @i_formato_fecha     = 101,
      @i_toperacion        = @w_toperacion,
      @i_moneda            = @w_moneda,
      @i_concepto          = @w_concepto_AJUFAG,
      @i_tipo_rubro        = @w_co_categoria, 
      @i_monto             = @w_valor_dif,      
      @i_comentario        = 'OTRO CARGO POR COMISION DEJADA DE COBRAR',   
      @i_base_calculo      = 0,      
      @i_div_desde         = 1,      
      @i_div_hasta         = 1,         
      @i_saldo_op          = 'N',         
      @i_saldo_por_desem   = 'N',            
      @i_tasa              = 0,            
      @i_num_dec_tapl      = null,
      @i_credito           = 'N',
      @o_sec_tran          = @w_sec_tran out 
         
      if @w_error <> 0 
      begin
         select 
         @w_msg   = 'ERROR EN EJECUCION PROCESO sp_otros_cargos ' + cast( @w_error as varchar)
         goto ERROR_SIG
      end    
      ELSE
      begin
         update cob_cartera..ca_carga_finagro
         set fi_estado_carga = 'P',
             fi_desc_carga   = 'CXC GENERADA SATISFACTORIAMENTE'
         where  fi_banco = @w_banco
      end
   end   ----FIN REGISTRO IOC
   
   goto SIGUIENTE
   
   ERROR_SIG:
      begin
         update cob_cartera..ca_carga_finagro
         set fi_estado_carga  = 'E',
             fi_desc_carga    = @w_msg,
             fi_cod_error     = @w_error
         where  fi_banco = @w_banco
         if @@ERROR <> 0
         begin
            select 
            @w_error = 22,
            @w_msg   = 'ERROR ACTUALIZANDO OPERACION CON ERROR'
            goto ERRORFIN
         end         
      end
   
   SIGUIENTE:
   select @w_acciones1 = @w_acciones1 + 1

end  ---WHILE GENERAL

insert into cob_cartera..ca_ajuste_finagro(
af_fecha_carga,      af_identificacion,      af_banco,            af_valor,
af_tipo_ajuste,      af_diferencia,          af_estado_carga,     af_desc_carga,
af_fecha_mov)
select
fi_fecha_carga,      fi_identificacion,      fi_banco,            fi_valor,
fi_tipo_ajuste,      ABS(fi_diferencia),     fi_estado_carga,     fi_desc_carga,
fi_fecha_mov
from   cob_cartera..ca_carga_finagro
where  fi_estado_carga = 'P'

if @@ERROR <> 0
begin
   select 
   @w_error = 23,
   @w_msg   = 'ERROR INSERTANDO EN OPERACIONES PROCESADAS'
   goto ERRORFIN 
end

/*** Modificar tipo de ajuste para mostrar ***/
update cob_cartera..ca_carga_finagro set
fi_tipo_ajuste = 'CXC'
where fi_tipo_ajuste = 'IOC'

----------------------------------------
--Generar Archivo de Cabeceras
----------------------------------------
select 
@w_nombre       = 'CONCFINAGRO',
@w_nom_tabla    = 'ca_carga_finagro',
@w_col_id       = 0,
@w_columna      = '',
@w_cabecera     = convert(varchar(2000), '')

select 
@w_nombre_plano = @w_path_plano + @w_nombre + '_' + convert(varchar(2), datepart(dd,getdate())) + '_' + convert(varchar(2), datepart(mm,getdate())) + '_' + convert(varchar(4), datepart(yyyy, getdate())) + '.txt'

while 1 = 1 
begin
   set rowcount 1
   select 
   @w_columna = c.name,
   @w_col_id  = c.colid
   from cob_cartera..sysobjects o, cob_cartera..syscolumns c
   where o.id    = c.id
   and   o.name  = @w_nom_tabla
   and   c.colid > @w_col_id
   order by c.colid

   if @@rowcount = 0 begin
      set rowcount 0
      break
   end

   select @w_cabecera = @w_cabecera + @w_columna + '^|'
end

select @w_cabecera = left(@w_cabecera, datalength(@w_cabecera) - 2)

--Escribir Cabecera
select @w_comando = 'echo ' + @w_cabecera + ' > ' + @w_nombre_plano

exec @w_error = xp_cmdshell @w_comando

if @w_error <> 0 begin
   select @w_msg = 'EJECUCION comando bcp FALLIDA. REVISAR ARCHIVOS DE LOG GENERADOS.'
   goto ERRORFIN
end

--Ejecucion para Generar Archivo Datos
select @w_comando = @w_s_app + 's_app bcp -auto -login cob_cartera..' + @w_nom_tabla + ' out '

select 
@w_destino  = @w_path_plano + @w_nombre + '.txt',
@w_errores  = @w_path_plano + @w_nombre + '.err'

select @w_comando = @w_comando + @w_destino + ' -b5000 -c -e' + @w_errores + ' -t"|" ' + '-config '+ @w_s_app + 's_app.ini'

exec @w_error = xp_cmdshell @w_comando

if @w_error <> 0 begin
   select @w_msg = 'Error Generando Archivo mg_personas_BJD001' 
   goto ERRORFIN
end

----------------------------------------
--Union de archivos (cab) y (dat)
----------------------------------------

select @w_comando = 'copy ' + @w_nombre_plano + ' + ' + @w_path_plano + @w_nombre + '.txt' + ' ' + @w_nombre_plano

exec @w_error = xp_cmdshell @w_comando

if @w_error <> 0 begin
   select @w_msg = 'EJECUCION comando bcp FALLIDA. REVISAR ARCHIVOS DE LOG GENERADOS.'
   goto ERRORFIN
end
else
begin
   -- elimina archivo errores de no existir 
   select @w_comando = 'del ' + @w_destino

   exec @w_error = xp_cmdshell @w_comando

   if @w_error <> 0 begin
      select @w_msg = 'EJECUCION comando bcp FALLIDA (Eliminacion temp .err). REVISAR ARCHIVOS DE LOG GENERADOS. '
      goto ERRORFIN
   end
   
   select @w_comando = 'del ' + @w_errores

   exec @w_error = xp_cmdshell @w_comando

   if @w_error <> 0 begin
      select @w_msg = 'EJECUCION comando bcp FALLIDA (Eliminacion temp .err). REVISAR ARCHIVOS DE LOG GENERADOS. '
      goto ERRORFIN
   end
end

return 0

ERRORFIN: 
   print  @w_msg
   return @w_error
go
