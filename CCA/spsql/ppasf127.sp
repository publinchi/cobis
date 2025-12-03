/***********************************************************************/
/*      Archivo                :        ppasf127.sp                    */
/*      Stored procedure       :        sp_f127_masivo                 */
/*      Base de Datos          :        cob_cartera                    */
/*      Producto               :        Cartera                        */
/*      Disenado por           :        Elcira Pelaez                  */
/*      Fecha de Documentacion :   Nov-2002                            */
/***********************************************************************/
/*                                             IMPORTANTE              */
/*      Este programa es parte de los paquetes bancarios propiedad de  */  
/*      "MACOSA".                                                      */
/*      Su uso no autorizado queda expresamente prohibido asi como     */
/*      cualquier autorizacion o agregado hecho por alguno de sus      */
/*      usuario sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante             */
/***********************************************************************/  
/*                                             PROPOSITO               */
/*      Este sp permite consultar los prepagos pasivos para la pantalla*/
/* de imrpesion de F127 pprepagos pasivas                              */
/***********************************************************************/  
/*                         MODIFICACIONES                              */
/*  FECHA            AUTOR                      RAZON                  */
/*  DIC/29/2005     Elcira Pelaez            Def 5493                  */
/*  ENE/04/2006     Elcira Pelaez            Def 5682                  */
/*  MAR/03/2006     Ivan Jimenez             REQ 540                   */
/*  OCT/13/2006     Elcira Pelaez            Def 6440                  */
/***********************************************************************/

use cob_cartera 
go

if exists (select 1 from sysobjects where name = 'sp_f127_masivo')
        drop proc sp_f127_masivo
go



create proc sp_f127_masivo
@s_user                   login    = null,
@s_date                   datetime = null,
@t_trn                    int      = null,
@i_fecha                  datetime = null,
@i_codigo_prepago         catalogo = null,
@i_operacion              char(1)  = null,
@i_opcion                 char(1)  = null,
@i_banco_seg_piso         catalogo = null,
@i_secuencial             int      = 0,
@i_formato_fecha          int      = 101
  
as declare 
@w_error                  int,
@w_return                 int,
@w_sp_name                descripcion,
@w_op_tramite             int,
@w_pp_banco               cuenta,
@w_op_cliente             int,
@w_pp_tipo_novedad        char(1),  
@w_pp_tipo_reduccion      char(1),
@w_pp_valor_prepago       money,
@w_pp_fecha_aplicar       datetime,
@w_pp_llave_redescuento   cuenta,
@w_op_margen_redescuento  float,
@w_cc                     char(1),
@w_nit                    char(1),
@w_ce                     char(1),
@w_otro                   char(1),
@w_identificacion         numero,
@w_nombre                 char(25),
@w_operacion_activa       int,
@w_op_operacion_pasiva    int,
@w_tramite_activa         int,
@w_num_pagare             cuenta,
@w_tipo_tasa              char(1),
@w_num_cuota_vig          int,
@w_fecha_prox_ven         datetime,
@w_param_dias_ppas        smallint,
@w_tipo_identificacion    catalogo,
@w_cod_ofi_cen            char(3),
@w_cod_linea              catalogo,
@w_consefinagro           catalogo,
@w_consenovedades         catalogo,
@w_fecha_redes            datetime,
@w_op_fecha_liq           datetime,
@w_sec                    int,
@w_codigo_todas           catalogo,
@w_pp_codigo_prepago      catalogo,
@w_fecha_liq              datetime,
@w_long                   int,
@w_dias_diff              int,
@w_cod_prepago_icr        catalogo,
@w_pp_fecha_generacion    datetime,
@w_est_cuota_fgeneracion  int,
@w_ma_valor_saldo         money   -- IFJ 03/Mar/2006 REQ 540




select @w_sp_name = 'sp_f127_masivo',
       @i_formato_fecha  = 101


-- PARAMETROS GENERALES
select @w_param_dias_ppas = pa_smallint
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'DIPP'
set transaction isolation level read uncommitted

   
select @w_codigo_todas = pa_char
from cobis..cl_parametro
where pa_nemonico = 'TODCAU'
and pa_producto = 'CCA'
set transaction isolation level read uncommitted

select @w_cod_prepago_icr = pa_char
from  cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'COPICR'

if @i_codigo_prepago = @w_codigo_todas
 begin
    PRINT 'IMPRESION F127 --> Causal 00 Congestiona el sistema, en la impresion Masiva'
    select @w_error = 710546
    goto ERROR
 end 

if @i_codigo_prepago =  @w_cod_prepago_icr
 begin
    PRINT 'IMPRESION F127 --> Este Codigo de Prepago  esta deshabilitado para generacion de F127'
    select @w_error = 710546
    goto ERROR
 end 
     

if @i_operacion = 'C'
begin    
   select @w_sec = 0
   delete ca_f127_masivo
   where ma_user = @s_user    
   
     declare cursor_ppas_f127 cursor for 
     select op_operacion,
            op_tramite,
            pp_banco,
            op_cliente,
            pp_tipo_novedad, 
            pp_tipo_reduccion,
              pp_valor_prepago,
              pp_fecha_aplicar,
            isnull(pp_llave_redescuento,'NO TIENE LLAVE'),
            isnull(op_margen_redescuento,100),
            op_fecha_liq,
            pp_codigo_prepago,
            pp_fecha_generacion
      from  cob_cartera..ca_prepagos_pasivas,
            cob_cartera..ca_operacion
            where  pp_codigo_prepago  = @i_codigo_prepago 
            and    pp_fecha_aplicar = @i_fecha
            and    pp_estado_aplicar  = 'N'
            and    pp_estado_registro = 'I'  ---No estan procesados aun
            and    op_tipo_linea = @i_banco_seg_piso
            and    op_banco = pp_banco
     for read only
   
     open cursor_ppas_f127 
     fetch cursor_ppas_f127 into 
            @w_op_operacion_pasiva,
            @w_op_tramite,
            @w_pp_banco,
            @w_op_cliente,
            @w_pp_tipo_novedad, 
            @w_pp_tipo_reduccion,
            @w_pp_valor_prepago,
            @w_pp_fecha_aplicar,
            @w_pp_llave_redescuento,
            @w_op_margen_redescuento,
            @w_op_fecha_liq,
                 @w_pp_codigo_prepago   ,
                 @w_pp_fecha_generacion
     while (@@fetch_status = 0) 
     begin
        if (@@fetch_status = -1) 
        begin
          select @w_error = 710544 
          goto ERROR
        end 


        ---VALIDACION DE LA FECHA A APLICAR CON RESPECTOA LA FECHA DE VENCIMIENTO DE LA CUOTA VIGENTE
        ---DE LAOP PASIVA
                
        
        --MANEJO DE LA IDENTIFICACION DEL CLIENTE
           select 
                @w_cc     =     (SELECT 'X' FROM cobis..cl_ente 
                                     WHERE en_ente = A.en_ente 
                                     AND en_tipo_ced in ('CC','TI')),
                @w_nit    =     (SELECT 'X' FROM cobis..cl_ente 
                                    WHERE en_ente = A.en_ente 
                                    AND en_tipo_ced in ('NI','N','F')),
                @w_ce     =     (SELECT 'X' FROM cobis..cl_ente 
                                    WHERE en_ente = A.en_ente 
                                    AND en_tipo_ced in ('CE','PA')),
                @w_otro   =     (SELECT 'X' FROM cobis..cl_ente 
                                       WHERE en_ente = A.en_ente 
                                       AND en_tipo_ced NOT IN ('CC','CE','NI','N','F', 'PA','TI')),
            @w_identificacion  = en_ced_ruc,
            @w_nombre          =   ltrim(rtrim(en_nombre )) + '' + ltrim(rtrim(p_p_apellido))  +''+ ltrim(rtrim(p_s_apellido ))
          from  cob_credito..cr_deudores,cobis..cl_ente A
            where       de_cliente = A.en_ente
            and     de_tramite   = @w_op_tramite
          and     de_rol in('D', 'S')
          and     en_ente  = @w_op_cliente
          if @@rowcount = 0
           begin

            fetch cursor_ppas_f127 into 
            @w_op_operacion_pasiva,
            @w_op_tramite,
            @w_pp_banco,
            @w_op_cliente,
            @w_pp_tipo_novedad, 
            @w_pp_tipo_reduccion,
            @w_pp_valor_prepago,
            @w_pp_fecha_aplicar,
            @w_pp_llave_redescuento,
            @w_op_margen_redescuento,
            @w_op_fecha_liq,
                 @w_pp_codigo_prepago,
                 @w_pp_fecha_generacion
            CONTINUE            
           end
          
          if @w_cc is not null
             select @w_tipo_identificacion = 'CC'
   
          if @w_nit is not null
             select @w_tipo_identificacion = 'NIT'
   
          if @w_ce is not null
             select @w_tipo_identificacion = 'CE'
             
          if @w_otro is not null
             select @w_tipo_identificacion = 'OTRO'
             
    
          --No. DEL PAGARE
          
           select  @w_operacion_activa = rp_activa 
           from  cob_cartera..ca_relacion_ptmo     
           where rp_pasiva = @w_op_operacion_pasiva   
                                                   
           select @w_tramite_activa = op_tramite  
           from cob_cartera..ca_operacion          
           where op_operacion = @w_operacion_activa
           
 
   
           --MODALIDAD DE LA TASA
           
           select   @w_tipo_tasa = ro_fpago                                                                                               
           from     cob_cartera..ca_rubro_op                                                                                              
           where   ro_operacion = @w_op_operacion_pasiva                                                                                    
           and     ro_tipo_rubro = 'I'                                                                                                   
                                                                                                                                         
           if      @w_tipo_tasa = 'P'                                                                                                    
                   select  @w_tipo_tasa = 'V'  
   
           --FECHA PROXIMO VENCIMIENTO
           select @w_num_cuota_vig = 0
           select @w_num_cuota_vig = isnull(max(di_dividendo),0)
           from  ca_dividendo 
           where di_operacion = @w_op_operacion_pasiva  
           and   di_estado = 1           
   
           if @w_num_cuota_vig  = 0
           begin
 
            fetch cursor_ppas_f127 into 
            @w_op_operacion_pasiva,
            @w_op_tramite,
            @w_pp_banco,
            @w_op_cliente,
            @w_pp_tipo_novedad, 
            @w_pp_tipo_reduccion,
            @w_pp_valor_prepago,
            @w_pp_fecha_aplicar,
            @w_pp_llave_redescuento,
            @w_op_margen_redescuento,
            @w_op_fecha_liq,
                 @w_pp_codigo_prepago,
                 @w_pp_fecha_generacion
            CONTINUE            
                        
           end
         
           --DATOS ARCHIVO REDESCUENTO

           select  @w_fecha_liq  = op_fecha_liq
           from  cob_cartera..ca_operacion
           where op_tramite = @w_op_tramite           
           
           if @w_fecha_liq <= '10/31/1999'
           begin
           select 
              @w_cod_ofi_cen     = re_cod_entidad,
              @w_cod_linea       = re_toperacion,
              @w_consefinagro    = substring(re_llave_redescuento,14,datalength(re_llave_redescuento)-15),
              @w_consenovedades  = substring(re_llave_redescuento,datalength(re_llave_redescuento)- 1,datalength(re_llave_redescuento)),
              @w_fecha_redes     = @w_fecha_liq,
              @w_num_pagare      = re_num_pagare
              from  cob_credito..cr_archivo_redescuento
              where re_tramite = @w_op_tramite
           end

           if @w_fecha_liq  between '11/02/1999' and  '04/30/2002'
           begin
           select 
              @w_cod_ofi_cen     = re_cod_entidad,
              @w_cod_linea       = re_toperacion,
              @w_consefinagro    = substring(re_llave_redescuento,12,datalength(re_llave_redescuento)-13),
              @w_consenovedades  = substring(re_llave_redescuento,datalength(re_llave_redescuento)- 1,datalength(re_llave_redescuento)),
              @w_fecha_redes     = @w_fecha_liq,
              @w_num_pagare      = re_num_pagare
              from  cob_credito..cr_archivo_redescuento
              where re_tramite = @w_op_tramite
           end       
           
           if @w_fecha_liq  >= '05/01/2002'
           begin
           select 
              @w_cod_ofi_cen     = re_cod_entidad,
              @w_cod_linea       = re_toperacion,
              @w_consefinagro    = substring(re_llave_redescuento,11,datalength(re_llave_redescuento)-12),
              @w_consenovedades  = substring(re_llave_redescuento,datalength(re_llave_redescuento)- 1,datalength(re_llave_redescuento)),
              @w_fecha_redes     = @w_fecha_liq,
              @w_num_pagare      = re_num_pagare
              from  cob_credito..cr_archivo_redescuento
              where re_tramite = @w_op_tramite
           end
           
           select @w_long =  datalength(@w_consefinagro)
           if @w_long = 5
              select @w_consefinagro = '0' + @w_consefinagro
              
              
           ---VALIDACION DE LOS CAMPOS QUE VAN EN NULL
   
           if @w_cod_ofi_cen is null
              select @w_cod_ofi_cen = 'NO HAY'
              
           if @w_cod_linea is null
              select @w_cod_linea = 'NO HAY'
              
           if @w_consefinagro  is null
              select @w_consefinagro = 'NO HAY'
           
           if @w_consenovedades  is null
              select @w_consenovedades = 'NO HAY'
              
           if @w_fecha_redes   is null
              select @w_fecha_redes = @w_op_fecha_liq


            select @w_est_cuota_fgeneracion = di_estado,
                   @w_fecha_prox_ven        = di_fecha_ven
            from ca_dividendo
            where di_operacion = @w_op_operacion_pasiva
            and @w_pp_fecha_generacion between  di_fecha_ini and di_fecha_ven 
                                
         
           --VALIDAR SI LA CUOTA EN QUE SE GENERO EL PREPGO YA ESTA CACNELADA SOLO PARA EL PREPAGO VOLUNTARIO
              if  @w_pp_codigo_prepago = '11' 
              begin
                 if  @w_est_cuota_fgeneracion = 1
                 begin
                    select @w_dias_diff = datediff(dd, @w_pp_fecha_aplicar,@w_fecha_prox_ven)  
                    if (@w_dias_diff < @w_param_dias_ppas)
                    begin
                      select @w_fecha_prox_ven = '01/01/1900'
                    end
   
                  end
                  else
                  begin
                   select @w_fecha_prox_ven = '01/01/1900'
                 end
              end  
             
              select @w_sec = @w_sec + 1
              
              -- SALDO DE LA OBLIGACION  --  IFJ 03/Mar/2006 REQ 540
              
              select @w_ma_valor_saldo = sum(am_acumulado-am_pagado)
              from   ca_amortizacion
              where  am_operacion = @w_op_operacion_pasiva
              and    am_concepto  = 'CAP'
              and    am_estado   in (0,1,2,4)
              
              --Fin IFJ 03/Mar/2006 REQ 540
              insert into  ca_f127_masivo 
                          (
                           ma_user,                 
                           ma_codigo_prepago,       
                           ma_fecha_prepago,   
                           ma_banco_segundo_piso,     
                           ma_banco,
                           ma_llave_redes,
                           ma_tipo_novedad,         
                           ma_cod_ofi_cen,          
                           ma_cod_linea,            
                           ma_fecha_redes,          
                           ma_consecutivo_fina,     
                           ma_num_novedades,        
                           ma_nombre_cliente,       
                           ma_identificacion,       
                           ma_tipo_identificacion,  
                           ma_num_pagare,           
                           ma_margen_redes,         
                           ma_modalidad_int,        
                           ma_fecha_prox_pago,      
                           ma_tipo_reduccion,       
                           ma_valor_prepago,
                           ma_fecha_generacion,
                           ma_sec,
                           ma_valor_saldo     -- IFJ 03/Mar/2006 REQ 540
                           )
              values       (
                           @s_user,                 
                           @w_pp_codigo_prepago,       
                           @w_pp_fecha_aplicar,   
                           @i_banco_seg_piso,
                           @w_pp_banco, 
                           @w_pp_llave_redescuento,    
                           @w_pp_tipo_novedad,         
                           @w_cod_ofi_cen,          
                           @w_cod_linea,            
                           @w_fecha_redes,          
                           @w_consefinagro,     
                           @w_consenovedades,        
                           @w_nombre,       
                           @w_identificacion,       
                           @w_tipo_identificacion,  
                           @w_num_pagare,           
                           @w_op_margen_redescuento,         
                           @w_tipo_tasa,        
                           @w_fecha_prox_ven,      
                           @w_pp_tipo_reduccion,       
                           @w_pp_valor_prepago,
                           @i_fecha,
                           @w_sec,
                           @w_ma_valor_saldo     -- IFJ 03/Mar/2006 REQ 540
                            )       
 
       fetch cursor_ppas_f127 into 
            @w_op_operacion_pasiva,
            @w_op_tramite,
            @w_pp_banco,
            @w_op_cliente,
            @w_pp_tipo_novedad, 
            @w_pp_tipo_reduccion,
            @w_pp_valor_prepago,
            @w_pp_fecha_aplicar,
            @w_pp_llave_redescuento,
            @w_op_margen_redescuento,
            @w_op_fecha_liq,
            @w_pp_codigo_prepago,
            @w_pp_fecha_generacion
          
     end  ---Cursor  cursor_ppas_f127
     close cursor_ppas_f127
     deallocate cursor_ppas_f127

 --Actualizar sobre la temporal  ca_f127_masivo las fechas  = '01/01/1990' como rechazos
 update ca_prepagos_pasivas
 set pp_estado_registro = 'I',
     pp_estado_aplicar  = 'P',
     pp_causal_rechazo  = '5',
     pp_comentario    = 'RECHAZADO VALIDACION DEL PARAMETRO DIPP'
 from ca_prepagos_pasivas,
      ca_f127_masivo
 where pp_banco =  ma_banco
 and   pp_codigo_prepago = ma_codigo_prepago
 and   pp_fecha_aplicar  = ma_fecha_prepago
 and   ma_fecha_prox_pago = '01/01/1900'
         
 delete ca_f127_masivo
 where  ma_fecha_prox_pago = '01/01/1900'
 
end --Ooperacion C

if @i_operacion = 'B'
begin

   if @i_opcion = "0"
   begin
      
      if exists (select 1 from ca_f127_masivo
                 where ma_user = @s_user)
      begin
         set rowcount 10
         select 
            'FechaGEneracion'       = convert(char(10),ma_fecha_generacion,@i_formato_fecha),
            'FechaPago'             = convert(char(10),ma_fecha_prepago,@i_formato_fecha),
            'No.Obligacion'         = ma_banco,
            'Llave Redes'           = ma_llave_redes,
            'Tipo Novedad'          = ma_tipo_novedad,         
            'OficinaCentralizadora' = ma_cod_ofi_cen,          
            'CodLineaFinagro'       = ma_cod_linea,            
            'Fecha Redes'           = convert(char(10),ma_fecha_redes,@i_formato_fecha),
            'Cosecutivo Finagro'    = ma_consecutivo_fina,     
            'Consec.Novedades'      = ma_num_novedades,        
            'Nombre Cliente'        = substring(ma_nombre_cliente,1,25),
            'Identificacion'        = ma_identificacion,       
            'Tipo Identif'          = ma_tipo_identificacion,  
            'No.Pagare'             = ma_num_pagare,           
            '% Redes'               = ma_margen_redes,         
            'Modalidad Int.'        = ma_modalidad_int,        
            'FEchaProximoPAgago'    = convert(char(10),ma_fecha_prox_pago,@i_formato_fecha),
            'TipoReduccion'         = ma_tipo_reduccion,       
            'ValorPRepago'          = ma_valor_prepago,
            'Sec'                   = ma_sec,
            'Saldo de Obligacion'   = ma_valor_saldo     -- IFJ 03/Mar/2006 REQ 540
         from ca_f127_masivo
         where ma_user = @s_user
         and   ma_codigo_prepago    = @i_codigo_prepago 
         and   ma_fecha_generacion   = @i_fecha
         and   ma_banco_segundo_piso = @i_banco_seg_piso
         order by ma_sec
         set rowcount 0         
      end
      else
      begin
         select @w_error = 710545
         goto ERROR
      end
   end  -- opcion 0
   

   if @i_opcion = "1"
   begin   
      set rowcount 10

         select 
            'FechaGEneracion'       = convert(char(10),ma_fecha_generacion,@i_formato_fecha),
            'FechaPago'             = convert(char(10),ma_fecha_prepago,@i_formato_fecha),            
            'No.Obligacion'         = ma_banco,
            'Llave Redes'           = ma_llave_redes,
            'Tipo Novedad'          = ma_tipo_novedad,         
            'OficinaCentralizadora' = ma_cod_ofi_cen,          
            'CodLineaFinagro'       = ma_cod_linea,            
            'Fecha Redes'           = convert(char(10),ma_fecha_redes,@i_formato_fecha),
            'Cosecutivo Finagro'    = ma_consecutivo_fina,     
            'Consec.Novedades'      = ma_num_novedades,        
            'Nombre Cliente'        = substring(ma_nombre_cliente,1,35),
            'Identificacion'        = ma_identificacion,       
            'Tipo Identif'          = ma_tipo_identificacion,  
            'No.Pagare'             = ma_num_pagare,           
            '% Redes'               = ma_margen_redes,         
            'Modalidad Int.'        = ma_modalidad_int,        
            'FEchaProximoPAgago'    = convert(char(10),ma_fecha_prox_pago,@i_formato_fecha),
            'TipoReduccion'         = ma_tipo_reduccion,       
            'ValorPRepago'          = ma_valor_prepago,
            'Sec'                   = ma_sec,
            'Saldo de Obligacion'   = ma_valor_saldo     -- IFJ 03/Mar/2006 REQ 540         
         from ca_f127_masivo
         where ma_user = @s_user
         and   ma_codigo_prepago    = @i_codigo_prepago 
         and   ma_fecha_generacion   = @i_fecha
         and   ma_banco_segundo_piso = @i_banco_seg_piso
         and   ma_sec > @i_secuencial
         order by ma_sec      
      set rowcount 0
   end  -- opcion 1
end  --operacion B

return 0

ERROR:
   exec cobis..sp_cerror
   @t_debug  = 'N',    
   @t_file   =  null,
   @t_from   =  @w_sp_name,
   @i_num    =  @w_error
   return   @w_error
                                                    
go

