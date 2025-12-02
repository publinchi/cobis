/************************************************************************/
/*   Archivo:              facsin.sp                                    */
/*   Stored procedure:     sp_descdoc_sin_respon                        */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Patricia Garzon R.                           */
/*   Fecha de escritura:   noviembre 2001                               */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBISCORP'                                                        */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBISCORP o su representante.             */
/************************************************************************/  
/*                               PROPOSITO                              */
/*      Este programa hace lo siguiente:                                */
/*   - Crea la(s) obligacion(es) de los proveedores responsables de     */
/*      pago de los documentos descontados.                             */
/************************************************************************/  
/*                      MODIFICACIONES                                  */
/*   FECHA                    AUTOR           RAZON                     */
/*                                                                      */
/*   MAY-20-2002               EPB      control DFVAL para crear hijas  */
/*   24/Jun/2022               KDR           Nuevo parámetro sp_liquid  */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_descdoc_sin_respon')
   drop proc sp_descdoc_sin_respon
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO


create proc sp_descdoc_sin_respon 
        @s_ssn            int      = null,
        @s_sesn           int      = null,
        @s_ofi            smallint = null,
        @s_user           login, 
        @s_term           varchar (30) = null,
        @s_date           datetime     = null,
        @s_srv            varchar(30)  = null,
        @i_usuario_tr     login,
        @i_batch_dd       char(1)      = null,
        @i_fecha_proceso  datetime
as

declare @w_sp_name                varchar(64),
   @w_nombre_completo            varchar(64),
        @w_error                      int,
        @w_return                     int,
        @w_ente                       int,
        @w_ente_empresa               int,
        @w_empresa                    numero,
        @w_nombre                     descripcion,
        @w_p_apellido                 varchar(16),
        @w_s_apellido                 varchar(16),
        @w_sexo                       char(1),
        @w_subtipo                    char(1),
        @w_oficina_cliente            smallint,
        @w_identificacion             numero,
        @w_tipo_identificacion        numero,
        @w_linea_credito              catalogo,
        @w_monto                      money,
        @w_moneda                     tinyint,
        @w_sector                     catalogo,
        @w_oficina_oper               smallint,
        @w_oficial                    smallint,
        @w_destino                    catalogo,
        @w_ubicacion                  int,
        @w_fecha_inicio               datetime,
        @w_forma_pago                 catalogo,
        @w_referencia_pago            cuenta,
        @w_fomar_desembolso           catalogo,
        @w_referencia_desem           cuenta,
        @w_estado_registro            char(1),
        @w_relacion                   char(1),
        @w_banco                      cuenta,
        @w_ciudad                     int,
        @w_periodo                    catalogo,
        @w_num_periodos               smallint,
        @w_clase                      catalogo,
        @w_tramite                    int,
   @w_cupo_linea                 cuenta,
        @w_valor_relacion             smallint,
   @w_operacionca                int,
        @w_truta                    tinyint,
        @w_etapa                      tinyint,
        @w_max_riesgo                 money,
        @w_commit                     char(1),
        @w_do_tramite                 int,
        @w_do_grupo                   int,     
        @w_do_valor                   money,     
        @w_do_moneda                  tinyint,     
        @w_do_fecini_neg              datetime, 
        @w_do_fecfin_neg              datetime,  
        @w_do_usada                   char(1),     
        @w_do_dividendo               smallint, 
        @w_do_referencia              varchar(16), 
        @w_do_porcentaje              money,
        @w_do_num_negocio             varchar(64), 
        @w_do_proveedor               int, 
        @w_htramite                   int,      
        @w_hgrupo                     int,     
        @w_hvalor                     money,     
        @w_hmoneda                    tinyint,     
        @w_hfecini_neg                datetime, 
        @w_hfecfin_neg                datetime,          
        @w_hnum_negocio               varchar(64), 
        @w_hproveedor                 int, 
        @w_htram_prov                 int,
        @w_forma_desem                catalogo,
        @w_cotiz_ds                   money,
        @w_moneda_local               tinyint,
        @w_concepto_can               varchar(30),
        @w_fecha                      datetime,
        @w_cot_moneda                 float,
        @w_tcotizacion_mpg            char(1), 
        @w_tcot_moneda                char(1),
        @w_op_banco                   catalogo,
        @w_comentario                 varchar(100),
        @w_anticipados                float,
        @w_moneda_opearacion          smallint,
        @w_clase_cartera              catalogo,
        @w_bco_cre                    varchar(24),
        @w_banco_padre                cuenta,
        @w_fecha_ini_oper             datetime,
        @w_dias_contr                 smallint,
        @w_fecha_proceso              datetime,
        @w_dias_hoy                   int,
        @w_rowcount                   int

select @w_sp_name   = 'sp_descdoc_sin_respon',
       @w_ente      = 0,
       @w_ente_empresa = 0


select  @w_moneda_local = pa_tinyint
from cobis..cl_parametro
where pa_nemonico = 'MLO'
and pa_producto = 'ADM' 
set transaction isolation level read uncommitted

delete cob_credito..cr_documentos_tmp WHERE do_tramite >= 0


insert into cob_credito..cr_documentos_tmp
select 
fa_tramite,     fa_grupo,        sum(fa_valor), 
fa_moneda,      fa_num_negocio,  fa_proveedor 
from cob_cartera..ca_operacion,
     cob_credito..cr_facturas
where op_fecha_liq = @i_fecha_proceso
and op_tramite = fa_tramite
and op_tipo = 'D'  ---solo sin responsabilidad
and op_estado = 3         ---El padre debe estar cancelado
and fa_con_respon = 'N'
and fa_tram_prov  is null
group by fa_num_negocio, fa_grupo, fa_proveedor, fa_moneda, fa_tramite


declare cursor_documentos cursor for
select 
do_tramite,   do_grupo,       do_valor,     
do_moneda,    do_num_negocio, do_proveedor
from cob_credito..cr_documentos_tmp
for read only

open  cursor_documentos

fetch cursor_documentos into
@w_do_tramite,  @w_do_grupo,        @w_do_valor,    
@w_do_moneda,   @w_do_num_negocio,  @w_do_proveedor

while @@fetch_status = 0 
begin
   if @@fetch_status = -1 
   begin
      select @w_error = 710219
      goto  ERROR
   end  


   begin tran --atomicidad por registro
      select @w_commit = 'S'

   
   select @w_fecha_ini_oper = op_fecha_ini
   from   ca_operacion
   where  op_tramite = @w_do_tramite   
 
   select @w_dias_contr = pa_smallint
   from  cobis..cl_parametro
   where pa_producto = 'CCA'
   and   pa_nemonico = 'DFVAL'
   select @w_rowcount = @@rowcount
   set transaction isolation level read uncommitted

   if @w_rowcount = 0 
   begin
          select @w_error = 710215
          goto  ERROR
   end

   select @w_fecha_proceso = fc_fecha_cierre
   from cobis..ba_fecha_cierre
   where fc_producto = 7  -- 7 pertence a Cartera


   select @w_dias_hoy = datediff(dd,@w_fecha_ini_oper,@w_fecha_proceso)

   if @w_dias_hoy > @w_dias_contr 
   begin
      PRINT '(facsin.sp) error 710212 Control Parametro DFVAL '
      select @w_error = 710212
      goto  ERROR

   end


      select @w_linea_credito = tr_toperacion,
             @w_oficina_oper  = tr_oficina,
             @w_destino       = tr_destino,
             @w_ciudad        = tr_ciudad,
             @w_clase         = tr_clase,
             @w_truta         = tr_truta  
      from cob_credito..cr_tramite
      where tr_tramite = @w_do_tramite

      select @w_sector  = en_banca,
             @w_oficial = en_oficial, 
             @w_identificacion = en_ced_ruc
      from cobis..cl_ente
      where en_ente =  @w_do_proveedor
      set transaction isolation level read uncommitted


       --- NOMBRE COMPLETO DEL PROVEEDOR
      
      select 
      @w_nombre_completo  = rtrim(p_p_apellido)+' '+rtrim(p_s_apellido)+' '+rtrim(en_nombre)
      from  cobis..cl_ente
      where en_ente = @w_do_proveedor
      set transaction isolation level read uncommitted

      ---ACAR SECUENCIALES SESIONES
      exec @s_ssn = sp_gen_sec 
         @i_operacion  = -1

      exec @s_sesn = sp_gen_sec 
         @i_operacion  = -1

      ---  INGRESAR DEUDOR 
      exec @w_return = sp_codeudor_tmp
         @s_sesn        = @s_sesn,
         @s_user        = @s_user,
         @i_borrar      = 'S',
         @i_secuencial  = 1,
         @i_titular     = @w_do_proveedor,
         @i_operacion   = 'A',
         @i_codeudor    = @w_do_proveedor,
         @i_ced_ruc     = @w_identificacion,
         @i_rol         = 'D',
         @i_externo     = 'N'
 
      if @w_return != 0 begin
         select @w_error = @w_return 
         goto  ERROR
      end



      --CREACION DEL TRAMITE EN CREDITO
      exec @w_return    =  cob_credito..sp_tram_fac
         @s_ssn            =  @s_ssn,
         @s_sesn           =  @s_sesn,
         @s_user           =  @s_user,
         @s_term           =  @s_term,
         @s_date           =  @i_fecha_proceso,
         @s_srv            =  @s_srv,
         @s_lsrv           =  @s_srv,
         @s_ofi            =  @w_oficina_oper,
         @i_tipo           =  'O',
         @i_oficina_tr     =  @w_oficina_oper,
         @i_usuario_tr     =  @i_usuario_tr,
         @i_fecha_crea     =  @i_fecha_proceso,
         @i_oficial        =  @w_oficial, 
         @i_sector         =  @w_sector,
         @i_ciudad         =  @w_ciudad,
         @i_banco          =  @w_banco,   
         @i_toperacion     =  @w_linea_credito,
         @i_producto       = 'CCA',
         @i_monto          =  @w_do_valor, 
         @i_moneda         =  @w_do_moneda, 
         @i_periodo        =  @w_periodo,
         @i_num_periodos   =  @w_num_periodos,
         @i_destino        =  @w_destino,
         @i_ciudad_destino =  @w_ubicacion,
         @i_cliente        =  @w_do_proveedor,
         @i_estado         =  'A', 
         @i_clase          =  @w_clase,
         @i_truta          =  @w_truta,
         @i_tramite_padre  =  @w_do_tramite, 
         @o_tramite        =  @w_tramite   out
         if @w_return != 0 
         begin
            select @w_error = @w_return 
            goto  ERROR
         end
         else 
         begin
             ---  ACTUALIZAR TRAMITE GENERADO PARA PROVEEDOR
            update cob_credito..cr_facturas
                   set fa_tram_prov     = @w_tramite
            where fa_tramite     = @w_do_tramite
              and fa_grupo       = @w_do_grupo
              and fa_num_negocio = @w_do_num_negocio
              and fa_proveedor   = @w_do_proveedor

            if @@error != 0 
            begin
               select @w_error = 2105050
               goto ERROR
            end
         end

     select @w_comentario = 'TRAMITE ' + convert(varchar (10), @w_do_tramite) +' DE DESC. DOC. SIN RESPONSABILIDAD'
     
   --- CREACION DE LA OPERACION EN TEMPORALES*/
      exec @w_return = sp_crear_operacion
      @s_user              = @s_user,
      @s_date              = @i_fecha_proceso,
      @s_term              = @s_term,
      @i_cliente           = @w_do_proveedor,
      @i_nombre            = @w_nombre_completo,
      @i_sector            = @w_sector,
      @i_toperacion        = @w_linea_credito,
      @i_oficina           = @w_oficina_oper,
      @i_moneda            = @w_do_moneda,
      @i_comentario        = @w_comentario,
      @i_oficial           = @w_oficial, 
      @i_fecha_ini         = @i_fecha_proceso,
      @i_monto             = @w_do_valor,
      @i_monto_aprobado    = @w_do_valor,
      @i_destino           = @w_destino,
      @i_ciudad            = @w_ciudad,
      @i_forma_pago        = @w_forma_pago,
      @i_cuenta            = @w_referencia_desem,
      @i_formato_fecha     = 101,
      @i_salida            = 'N',
      @i_fondos_propios    = 'N',
      @i_origen_fondos     = '1',
      @i_batch_dd             = 'S',
      @i_tramite_hijo      = @w_tramite,
      @o_banco             = @w_banco output
      
      if @w_return != 0 
      begin
        select @w_error = @w_return 
        goto  ERROR
      end



      select @w_periodo = opt_tplazo,
             @w_num_periodos = opt_plazo,
             @w_clase        = opt_clase,
             @w_operacionca  = opt_operacion,
             @w_moneda_opearacion = opt_moneda
      from ca_operacion_tmp
      where opt_banco = @w_banco

      --- SIEMPRE LA CARTERA EXTRANJERA ES COMERCIAL EPB:DIC:21-2001 Rosalba Sanabria


      if @w_moneda_opearacion <>  @w_moneda_local
         select @w_clase_cartera = '1'
      else
         select @w_clase_cartera = @w_clase 



    --- PASO A  DEFINITIVAS 
      exec @w_return = sp_operacion_def
    @s_date   = @i_fecha_proceso,
    @s_sesn   = @s_sesn,
    @s_user   = @s_user,
    @s_ofi    = @w_oficina_oper,
    @i_banco  = @w_banco

      if @w_return != 0  begin
    select @w_error = @w_return
    goto ERROR
      end

         select @w_banco_padre = op_banco
         from ca_operacion
         where op_tramite = @w_do_tramite

         update cob_cartera..ca_operacion 
         set op_tramite = @w_tramite,
             op_clase   = @w_clase_cartera,
             op_anterior = @w_banco_padre  
         where op_banco = @w_banco

         if @@error != 0  
         begin
             select @w_error = 705007
             goto ERROR
         end

 
      if @w_do_moneda = @w_moneda_local
      begin
         select @w_concepto_can = pa_char
         from cobis..cl_parametro
         where pa_producto = 'CCA'
         and   pa_nemonico = 'DESDML'
         set transaction isolation level read uncommitted
         end
      else
         select @w_concepto_can = pa_char
         from cobis..cl_parametro
         where pa_producto = 'CCA'
         and   pa_nemonico = 'DESDME'
     set transaction isolation level read uncommitted

      select @w_fecha = fc_fecha_cierre
      from   cobis..ba_fecha_cierre
      where  fc_producto = 7


      exec sp_buscar_cotizacion
           @i_moneda     = @w_do_moneda,
           @i_fecha      = @w_fecha,
           @o_cotizacion = @w_cot_moneda output
      
      select @w_tcotizacion_mpg = 'T',
             @w_tcot_moneda     = 'T'
 

      select @w_op_banco = op_banco,
             @w_operacionca = op_operacion 
      from cob_cartera..ca_operacion
      where op_tramite = @w_tramite


      update cob_credito..cr_tramite
      set  tr_numero_op = @w_operacionca,
           tr_numero_op_banco = @w_banco
      where tr_tramite = @w_tramite

      if @@error != 0  
      begin
         select @w_error = 2105051
         goto ERROR
      end


         --- SE COBRAN INTERESES ANTICIPADOS SOLO EN LA LIQUIDACION
         
         select @w_anticipados = round(sum(amt_cuota),2)
         from   ca_amortizacion_tmp,ca_rubro_op_tmp
         where  amt_operacion  = @w_operacionca
         and    rot_operacion  = @w_operacionca
         and    rot_concepto   = amt_concepto
         and    rot_tipo_rubro = 'I'
         and    rot_fpago      = 'A'

      
      select @w_do_valor = @w_do_valor - @w_anticipados 

      
      exec @w_return    = sp_desembolso
           @s_ofi            = @s_ofi,
           @s_term           = @s_term,
           @s_user           = @s_user,
           @s_date           = @s_date,  
           @i_producto       = @w_concepto_can,
           @i_cuenta         = '0000', 
           @i_beneficiario   = 'sa',
           @i_oficina_chg    = @s_ofi,
           @i_banco_ficticio = @w_op_banco, 
           @i_banco_real     = @w_op_banco,
           @i_monto_ds       = @w_do_valor,
           @i_tcotiz_ds      = @w_tcot_moneda,
           @i_cotiz_ds       = @w_cot_moneda,
           @i_tcotiz_op      = @w_tcotizacion_mpg,
           @i_cotiz_op       = @w_cot_moneda,
           @i_moneda_op      = @w_do_moneda,
           @i_moneda_ds      = @w_do_moneda,
           @i_operacion      = 'I',
           @i_externo        = 'N'

          if @w_return != 0 begin
             select @w_error = 710087
             goto ERROR
          end



      exec @w_return = sp_liquida
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
           @i_tramite_batc   = 'S',
           @i_tramite_hijo   = @w_tramite,
		   @i_desde_cartera  = 'N',          -- KDR No es ejecutado desde Cartera[FRONT]
           @i_externo        = 'N'
           
      if @w_return <> 0 
      begin
         select @w_error = @w_return
         goto ERROR
      end

  
      --- BORAR TEMPORALES 
      exec @w_return = sp_borrar_tmp
         @i_banco  = @w_op_banco,
         @s_date   = @i_fecha_proceso,
         @s_user   = @s_user
      if @w_return <> 0  return @w_return


      --- ACTUALIZAR NUMERO DE OPERACION EN TRAMITES 

      select @w_bco_cre = op_banco
      from cob_cartera..ca_operacion
      where op_tramite = @w_tramite


      update cob_credito..cr_tramite
      set  tr_numero_op = @w_operacionca,
           tr_numero_op_banco = @w_bco_cre
      where tr_tramite = @w_tramite

      if @@error != 0  begin
         select @w_error = 2105051
    goto ERROR
      end


   commit tran     ---Fin de la transaccion 
   select @w_commit = 'N'

   goto SIGUIENTE1

   ERROR:  
                                                     
   exec sp_errorlog                                             
   @i_fecha       = @i_fecha_proceso,
   @i_error       = @w_error,
   @i_usuario     = @s_user,
   @i_tran        = 7000, 
   @i_tran_name   = @w_sp_name,
   @i_rollback    = 'N',  
   @i_cuenta      = @w_identificacion,  ---Cedula
   @i_descripcion = 'CREACION MASIVA DE TRAMITES PARA DESC. DTOS. SIN RESPONSABILIDAD'

   if @w_commit = 'S' commit tran
   goto SIGUIENTE1

  SIGUIENTE1: 

fetch cursor_documentos into
@w_do_tramite,  @w_do_grupo,        @w_do_valor,    
@w_do_moneda,   @w_do_num_negocio,  @w_do_proveedor


end -- cursor documentos 
close cursor_documentos 
deallocate cursor_documentos 
return 0

go
