/************************************************************************/
/*      Archivo:                normalizacion.sp                        */
/*      Stored procedure:       sp_normalizacion                        */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               COBIS-CARTERA                           */
/*      Disenado por:           Luis Carlos Moreno                      */
/*      Fecha de escritura:     29-Sep-14                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA', representantes  exclusivos  para el  Ecuador  de la   */
/*      'NCR CORPORATION'.                                              */
/*      Su  uso no autorizado  queda expresamente  prohibido asi como   */
/*      cualquier   alteracion  o  agregado  hecho por  alguno de sus   */
/*      usuarios   sin el debido  consentimiento  por  escrito  de la   */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/*                              PROPOSITO                               */
/*      Este programa procesa las transacciones del store procedure     */
/*      Insercion de parametrizacion centrales de riesgo                */
/*      Modificacion de parametrizacion centrales de riesgo             */
/*      Busqueda de parametrizacion centrales de riesgo                 */
/************************************************************************/
/*                                PROPOSITO                             */
/* Normalizacion de Cartera - Prorroga de Cuota                         */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR           RAZON                           */
/*      29/Sep/14       L. Moreno       Emision Inicial                 */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_normalizacion')
   drop proc sp_normalizacion
go
--Ver.Reportes MAR.11.2015
create proc sp_normalizacion(
   @s_user           login        = 'batch',
   @s_ofi            smallint     = null,
   @s_term           varchar(30)  = null,
   @s_date           datetime     = null,
   @s_sesn           int          = null,
   @s_ssn            int          = null,
   @i_operacion      char(1),
   @i_tipo_norm      int          = null, --TIPO NORMALIZACION (1: PRORROGA DE FECHA)
   @i_banco          cuenta       = null,
   @i_cuota_prorroga tinyint      = null,
   @i_fecha_prorroga datetime     = null,
   @i_formato_fecha  int          = 103,
   @i_producto       catalogo     = null,
   @i_referencia     cuenta       = null,
   @i_cod_banco      catalogo     = null,
   @i_cheque         cuenta       = null,
   @i_tramite        int          = null,
   @i_debug          char         = 'N',
   @i_prorroga       char(1)      = 'N',
   @i_opcion         char(1)      = null ---utilizado para reportes de front-end
)
as

declare @w_operacion      int,
        @w_error          int,
        @w_sp_name        varchar(32),
        @w_msg            varchar(132),
        @w_tramite        int,
        @w_cuota          int,
        @w_fecha_prorroga varchar(10),
        @w_tipo_norm      int,
        @w_banco          varchar(24),
        @w_operacionca    int,
        @w_tram_oper      int,
        @w_pend_orden     char(1),
        @w_oper           int,
        @w_monto          money,
        @w_banco_new      cuenta,
        @w_calif_new      catalogo,
        @w_nota_new       catalogo,
        @w_rest_new       smallint,
        @w_fecha_proceso  datetime,
        @w_cliente        int,
        @w_campana        int,
        @w_tr_tipo_norm   int,
        @w_valor_excepcion char(10)

        
select @w_sp_name = 'sp_normalizacion'

/* OBTIENE FECHA DE PROCESO */
select @w_fecha_proceso = fp_fecha
from cobis..ba_fecha_proceso

/* VERIFICANDO QUE EL TRAMITE NO CONTENGA SEGUROS INGRESADOS POR DISPOTIVOS MOVILES */
if exists (select 1 from cob_credito..cr_seguros_tramite 
            where st_tramite = @i_tramite)
begin
   select @w_msg = 'ERROR, TRAMITE DE NORMALIZACION CONTIENE SEGUROS INGRESADOS POR DISPOSITIVO MOVIL',
          @w_error = 724562
   goto ERRORFIN
end
/* OBTIENE DATOS DE LA OPERACION */

if @i_prorroga = 'S'
begin

   select @w_tramite    = max(tr_tramite),
          @w_operacion  = max(op_operacion)
    from cob_cartera..ca_operacion,
         cob_credito..cr_tramite
   where op_banco   = @i_banco
   and   tr_tipo   = 'M'
   and   tr_estado = 'A' 
   and   tr_grupo = 1
   and   tr_numero_op_banco = op_banco
 
   if @@ROWCOUNT = 0  and @i_operacion <> 'Q'
   begin
      select @w_msg = 'ERROR, NO ES POSIBLE OBTENER DATOS BASICOS DE LA OPERACION',
             @w_error = 708153
             
      goto ERRORFIN
   end
end
ELSE
begin

   select @w_operacion = op_operacion,
          @w_tramite   = op_tramite
   from ca_operacion
   where op_banco = @i_banco
  
   if @@ROWCOUNT = 0  and @i_operacion <> 'Q'
   begin
      select @w_msg = 'ERROR, NO ES POSIBLE OBTENER DATOS BASICOS DE LA OPERACION',
             @w_error = 708153
             
      goto ERRORFIN
   end
end

if @i_operacion = 'N'
begin

   --- EJECUTAR DISPARADOR DE VALIDACIONES AL MOMENTO DE NORMALIZAR 
   exec @w_error = cob_credito..SP_DISPARADOR_REGLAS
        @i_operacion          = @i_banco,
        @i_tipo_normalizacion = @i_tipo_norm,
        @i_momento            = '5',
        @i_num_cuota          = @i_cuota_prorroga,
        @i_fecha              = @i_fecha_prorroga,
        @i_tramite            = @i_tramite
        
   if @w_error <> 0
      return @w_error

   --- NORMALIZA PRORROGA DE FECHA 
   if @i_tipo_norm = 1
   begin

      if @i_fecha_prorroga <= @w_fecha_proceso
      begin
         select @w_msg = 'ERROR: LA FECHA DE PRORROGA DEBE SER MAYOR A LA FECHA DEL SISTEMA',
                @w_error = 2101263
          
         goto ERRORFIN
      end
   
      /* VALIDA CANCELACION DE LA ORDEN DE PAGO */
      exec @w_error = cob_credito..sp_trn_cj_pag_mora
      @s_date         = @s_date,
      @s_user         = @s_user,
      @i_operacion    = 'I',
      @i_cca          = 'S', --LLAMO EL PROCESO DESDE CARTERA
      @i_banco        = @i_banco  

      if @w_error <> 0
         goto ERRORFIN
   
      /* EJECUTA NORMALIZACION */
      begin tran
         exec @w_error = sp_norm_pro_cuota
              @s_user           = @s_user,
              @s_ofi            = @s_ofi,
              @s_term           = @s_term,
              @s_date           = @s_date,
              @i_operacionca    = @w_operacion,
              @i_fecha_prorroga = @i_fecha_prorroga,
              @i_cuota_prorroga = @i_cuota_prorroga,
              @i_debug          = @i_debug

         if @w_error <> 0
            goto ERRORFIN
            
      commit tran
   end
   
   -- VALIDA ORDEN DE PAGO
   if @i_tipo_norm in (2,3)
   begin
   
      select @w_banco='',
             @w_pend_orden = 'N'

      /* OBTIENE LAS OPERACIONES A NORMALIZAR */
      select banco=nm_operacion, tramite=op_tramite, operacion=op_operacion, cliente = op_cliente
      into #operaciones
      from cob_credito..cr_normalizacion, cob_cartera..ca_operacion
      where nm_tramite = @w_tramite
      and   nm_tipo_norm = @i_tipo_norm
      and   nm_operacion = op_banco
      order by nm_operacion 

      select @w_banco='',
             @w_pend_orden = 'N'
          
      while 1=1
      begin
         select top 1 @w_banco       = banco,
                      @w_operacionca = operacion,
                      @w_tram_oper   = tramite,
                      @w_cliente     = cliente 
         from #operaciones
         where banco > @w_banco

         if @@rowcount = 0
            break

      select @w_campana = cc_campana
      from cob_credito..cr_cliente_campana, cob_credito..cr_campana
      where cc_campana      = ca_codigo
      and   cc_cliente      = @w_cliente
      and   ca_tipo_campana = 3    -- tipo campaña normalizacion 3
      and   cc_estado       = 'V'
      and   ca_estado       = 'V'
         
      if @w_campana is not null
      begin
         
         select @w_valor_excepcion =  pe_char
         from   cob_credito..cr_param_especiales_norm
         where  pe_campana  = @w_campana
         and    pe_tipo_campana = 3
         and    pe_tipo_normalizacion   = @i_tipo_norm --@w_tr_tipo_norm
         and    pe_regla = 'ORDEN_PAGO'
         and    pe_estado = 'V'
         
      end --campana es no nula
      --end
      if (@w_campana is not null and isnull(@w_valor_excepcion,'0') = 'S')  or (@w_campana is  null)
      begin
         
         exec @w_error = sp_valida_orden
           @s_date         = @s_date,
           @s_user         = @s_user,
           @i_tram_norm    = @w_tramite,
           @i_tram_oper    = @w_tram_oper,
           @i_banco        = @w_banco,
           @i_tipo_norm    = @i_tipo_norm,
           @i_operacion    = @w_operacionca
          
         if @w_error <> 0
            select @w_pend_orden = 'S'
            
       end     
      end     --whilw
   end  --tipo norm 2 y 3
   
   if @w_pend_orden = 'S'
   begin
   
      select @w_msg = 'CLIENTE DEBE REALIZAR PAGO DE ORDEN'
      goto ERRORFIN
   end

   if @w_pend_orden = 'N'
   begin
   
      -- 2. NORMALIZACION POR REESTRUCTURACION
      if @i_tipo_norm = 2
      begin
            begin tran
            
               exec @w_error = sp_norm_rees
                    @s_user           = @s_user,
                    @s_ofi            = @s_ofi,
                    @s_term           = @s_term,
                    @s_date           = @s_date,
                    @i_tramite        = @w_tramite

               if @w_error <> 0
                  goto ERRORFIN
               
            commit tran
      end
      ---FIN REESTRUCTURACION
      
      ---3. NORMALIZACION POR REFINANCIACION
      if @i_tipo_norm = 3
      begin
         if @w_pend_orden = 'N'
         begin
            begin tran
               ---PRINT 'normalizacion.sp vamos para sp_norm_refinanciaciones  @i_banco : '  + cast(@i_banco as varchar) +  ' @w_tramite : '   + cast ( @w_tramite as varchar)
               exec @w_error = sp_norm_refinanciaciones
                    @s_user           = @s_user,
                    @s_ofi            = @s_ofi,
                    @s_term           = @s_term,
                    @s_date           = @s_date,
                    @i_tramite        = @w_tramite,
                    @i_banco          = @i_banco,
                    @i_producto       = @i_producto,
                    @i_referencia     = @i_referencia,
                    @i_cod_banco      = @i_cod_banco,
                    @i_cheque         = @i_cheque,
                    @i_debug          = @i_debug

               if @w_error <> 0
                  goto ERRORFIN 
               
            commit tran
         end
            
      end
      ---FIN REFINANCIACION
   end -- if @w_pend_orden = 'S'
end

if @i_operacion = 'Q'
begin
if @i_opcion = '3'
begin
   select 'Dividendo'    = di_dividendo,
          'Fecha Inicio' = convert(varchar(15),di_fecha_ini,103),
          'Fecha Inicio' = convert(varchar(15),di_fecha_ven,103),
          'Dias Cuota'   = di_dias_cuota,
          'ValorCuota'   = sum(am_cuota),
          'Estado'       = es_descripcion
   from ca_dividendo,ca_amortizacion,ca_estado
   where am_operacion = @w_operacion 
   and am_operacion = di_operacion
   and am_dividendo = di_dividendo
   and di_estado <> 3
   and di_estado = es_codigo
   group by di_dividendo,di_fecha_ini,di_fecha_ven,di_dias_cuota,es_descripcion
   order by di_dividendo

end
ELSE
   begin
        select  'Nro.Operacion' = op_banco,
                'Calificacion'  = op_calificacion,     
                'Nro.Reest.'    = op_numero_reest,
                'Nota'          = ci_nota,
                'Est.Op.'       = op_estado,
                'Monto'         = op_monto,
                'Linea'         = op_toperacion,
                'Tasa.Efa'      = ro_porcentaje_efa,
                'Tasa Nom.'     = ro_porcentaje
         from ca_operacion,
              ca_rubro_op,
              cob_credito..cr_califica_int_mod
         where op_tramite =  @i_tramite
         and ci_banco  = op_banco
         and ro_operacion = op_operacion
         and ro_tipo_rubro = 'I'
   end
end

if @i_operacion = 'S'
begin

   select top 1 @w_tramite        = nm_tramite,
                @w_cuota          = nm_cuota,
                @w_fecha_prorroga = convert(varchar(10),nm_fecha,@i_formato_fecha),
                @w_tipo_norm      = tr_grupo
          from cob_credito..cr_normalizacion, cob_credito..cr_tramite
   where tr_tramite = nm_tramite
   and   tr_tipo   = 'M' --NORMALIZACION
   and   tr_estado = 'A' --APLICADO
   and   tr_numero_op_banco = @i_banco
   order by tr_tramite desc
   
   if @@ROWCOUNT = 0
   begin
   
      select top 1 @w_tipo_norm      = tr_grupo
      from cob_cartera..ca_operacion, cob_credito..cr_tramite
      where tr_tramite = op_tramite 
      and   tr_tipo   = 'M' --NORMALIZACION
      and   tr_estado = 'A' --APLICADO
      and   op_banco = @i_banco
      order by tr_tramite desc
      
      if @@ROWCOUNT = 0
      begin
         select @w_msg = 'ERROR, TRAMITE DE NORMALIZACION NO ENCONTRADO',
                @w_error = 708153
         goto ERRORFIN
      end
   end
   
   if @w_tipo_norm <> 1
   begin
      if exists (select 1 from cob_cartera..ca_normalizacion
                 where nm_tramite = @w_tramite
                 and   nm_estado = 'A')
      begin
         select @w_msg = 'ERROR, TRAMITE DE NORMALIZACION YA PERFECCIONADO',
                @w_error = 708153
         goto ERRORFIN
      end
   end
   
   if @w_tipo_norm = 1 --PRORROGA DE CUOTA
   begin
      select @w_cuota, @w_fecha_prorroga
   end
   
   if @w_tipo_norm = 2 --REESTRUCTURACION
   begin
      select 'Nro. Operacion'    = nm_operacion,
             'Linea '            = op_toperacion,
             'Moneda Op'         = op_moneda,
             'Monto  Op'         = op_monto,
             'Calificacion'      = op_calificacion,
             'Nor. Reest'        = op_numero_reest
      from   cob_credito..cr_normalizacion, cob_cartera..ca_operacion
      where  op_banco   = nm_operacion
      and    nm_tramite = @w_tramite
   
      select op_banco,
             op_moneda,
             (select c.valor from   cobis..cl_tabla t, cobis..cl_catalogo c where  t.tabla = 'cl_moneda' and c.tabla = t.codigo and c.codigo = convert(varchar, o.op_moneda)),
             op_toperacion,
             (select c.valor from   cobis..cl_tabla t, cobis..cl_catalogo c where  t.tabla = 'ca_toperacion' and c.tabla = t.codigo and c.codigo = o.op_toperacion),
             op_monto,
             op_tramite
      from   cob_cartera..ca_operacion o
      where  op_tramite = @w_tramite
   end ---2
   
   if @w_tipo_norm = 3 ---REFINANCIACION
   begin
    select  'banco'  = nm_operacion,
            'estado' = op_estado,
            'linea'  = op_toperacion,
            'moneda' = op_moneda,
            'monto'  = 0,
            'calif'  = op_calificacion,
            'reest'   = op_numero_reest,
            'oper'   = op_operacion,
            'nota'   = ci_nota
      into #oper              
      from   cob_credito..cr_normalizacion,
             cob_cartera..ca_operacion,
             cob_credito..cr_tramite,
             cob_credito..cr_califica_int_mod
      where  op_banco   = nm_operacion
      and  nm_tramite = @w_tramite
      and  tr_tramite = op_tramite
      and  tr_tipo <> 'M'
      and  ci_banco = op_banco
      
   
      select @w_oper = 0
      while 1 = 1
      begin
             set rowcount 1
             select @w_oper = oper
             from #oper
             where oper > @w_oper
             order by oper
      
             if @@rowcount = 0 begin
               set rowcount 0
               break
             end
      
         set rowcount 0
         exec @w_error = sp_calcula_saldo
         @i_operacion = @w_oper,
         @i_tipo_pago = 'A',
         @o_saldo     = @w_monto out
      
         update #oper
         set monto = @w_monto
         where oper = @w_oper
      end 
      
      select 'Nro.Operacion'    = banco,
             'Estado   '    =  case estado when 1 then 'VIGENTE'
                                       when 2 then 'VENCIDO'
                                        when 9  then 'SUSPENSO'
                                        else 'VIGENTE'
                            end,
             'Linea     '          = linea,
             'Moneda Op.'          = moneda,
             'Saldo      '         = convert(money,monto),
             'Calificacion'        = calif,
             'Nor. Reest'          = reest,
             'Nota'                = nota
      from     #oper
      ---DATOS DE LA OPERACION A REFINACIAR             
      select op_banco,
             op_moneda,
             (select c.valor from   cobis..cl_tabla t, cobis..cl_catalogo c where  t.tabla = 'cl_moneda' and c.tabla = t.codigo and c.codigo = convert(varchar, o.op_moneda)),
             op_toperacion,
             (select c.valor from   cobis..cl_tabla t, cobis..cl_catalogo c where  t.tabla = 'ca_toperacion' and c.tabla = t.codigo and c.codigo = o.op_toperacion),
             op_tramite,
             op_cliente,
             op_nombre,
             op_oficina
      from   cob_cartera..ca_operacion o
      where  op_tramite = @w_tramite
   end ---3
   
end

if @i_operacion = 'T'
begin

   select top 1 @w_tipo_norm      = tr_grupo
   from cob_credito..cr_normalizacion, cob_credito..cr_tramite
   where tr_tramite = nm_tramite
   and   tr_tipo   = 'M' --NORMALIZACION
   and   tr_estado = 'A' --APLICADO
   and   tr_numero_op_banco = @i_banco
   order by tr_tramite desc
   
   if @@ROWCOUNT = 0
   begin
      select top 1 @w_tipo_norm      = tr_grupo
      from cob_cartera..ca_operacion, cob_credito..cr_tramite
      where tr_tramite = op_tramite 
      and   tr_tipo   = 'M' --NORMALIZACION
      and   tr_estado = 'A' --APLICADO
      and   op_banco = @i_banco
      order by tr_tramite desc
      
      if @@ROWCOUNT = 0
      begin
         select @w_msg = 'ERROR, TRAMITE DE NORMALIZACION NO EXISTE',
                @w_error = 708153
         goto ERRORFIN
      end
   end

   if @w_tipo_norm <> 1
   begin
      if exists (select 1 from cob_cartera..ca_normalizacion
                 where nm_tramite = @w_tramite
                 and   nm_estado = 'A')
                 and   @i_opcion  is null
      begin
         select @w_msg = 'ERROR, TRAMITE DE NORMALIZACION YA PERFECCIONADO',
                @w_error = 708153
         goto ERRORFIN
      end
   end

   ---ESTA VALIDACIONA PLICA EN ESTE PUNTO PARA REFIANCIACION
   if @w_tipo_norm  = 3 and  @i_opcion  is null
   begin
      select top 1 @w_tramite        = nm_tramite
      from cob_credito..cr_normalizacion, cob_credito..cr_tramite
      where tr_tramite = nm_tramite
      and   tr_tipo   = 'M' --NORMALIZACION
      and   tr_estado = 'A' --APLICADO
      and   tr_numero_op_banco = @i_banco
      order by tr_tramite desc   
      
      if exists (select 1 from cob_cartera..ca_normalizacion
                 where nm_tramite = @w_tramite
                 and   nm_estado = 'A')
      begin
         select @w_msg = 'ERROR, TRAMITE DE NORMALIZACION YA PERFECCIONADO',
                @w_error = 708153
         goto ERRORFIN
      end
         
   end 
     
   select @w_tipo_norm
end

if @i_operacion = 'R' --Reportes Front-end
begin
 
   select @w_tipo_norm =  nm_tipo_norm
   from cob_cartera..ca_normalizacion
   where nm_tramite = @w_tramite
   and   nm_estado = 'A'
   if @@ROWCOUNT = 0
   begin
      select @w_tramite = tr_tramite
      from cob_credito..cr_tramite,ca_operacion
      where tr_numero_op  = @w_operacion
      and tr_numero_op = op_operacion
      and tr_tipo = 'M'
      and tr_estado <> 'Z'

      select @w_tipo_norm =  nm_tipo_norm
      from cob_cartera..ca_normalizacion
      where nm_tramite = @w_tramite
      and   nm_estado = 'A'
      if @@ROWCOUNT = 0
      begin
         
         select @w_msg = 'ERROR, TRAMITE DE NORMALIZACION NO ENCONTRADO',
                @w_error = 708153
                goto ERRORFIN
      end
   end

            
   exec sp_reportes_norm 
   @s_user          = @s_user,
   @i_banco         = @i_banco,
   @i_tramite       = @w_tramite,
   @i_tipo_norm     = @w_tipo_norm

end


return 0
ERRORFIN:

   if @@trancount > 0 rollback tran

   exec cobis..sp_cerror
   @t_from  = @w_sp_name,
   @i_num   = @w_error,
   @i_msg   = @w_msg
   return @w_error
  
go