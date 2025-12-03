/*qrcodeu.sp*************************************************************/
/*	Archivo: 		        qrcodeu.sp			                        */
/*	Stored procedure: 	    sp_qr_codeudor			                    */
/*	Base de datos:  	    cobis				                        */
/*	Producto: 		        Credito y Cartera		                	*/
/*	Disenado por:  		    Sandra Ortiz			                    */
/*	Fecha de escritura: 	07-Jul-1994				                    */
/************************************************************************/
/*	                    IMPORTANTE				                        */
/*	Este programa es parte de los paquetes bancarios propiedad de	    */
/*	'MACOSA'                                                            */
/*	Su uso no autorizado queda expresamente prohibido asi como	        */
/*	cualquier alteracion o agregado hecho por alguno de sus		        */
/*	usuarios sin el debido consentimiento por escrito de la 	        */
/*	Presidencia Ejecutiva de MACOSA o su representante.		            */
/************************************************************************/  
/*	                  PROPOSITO				                            */
/*	Este programa presenta la lista de deudor y codeudores de	        */
/*	una operacion definitiva.					                        */
/************************************************************************/  
/*	                     MODIFICACIONES				                    */
/*	FECHA		      AUTOR		              RAZON	                    */
/* jun-2004           Elcira Pelaez    Reverso sobrante                 */ 
/* dic -2005          Xavier Maldonado NR. 201                          */
/* mar-2006           Elcira Pelaez    NR  479                          */
/* mar-2006           Elcira Pelaez    DEF  6175                        */
/* MAY-2006           E.Pelaez         DEF-6487                         */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_qr_codeudor')
	drop proc sp_qr_codeudor
go

create proc sp_qr_codeudor (
@s_user         varchar(14),
@s_sesn         int,
@i_operacion	 char(1),
@i_numero	    varchar(24),
@i_operacionca	 int	        = null,
@i_estado	    varchar(10)     = null,
@i_accion       char(1)      = null,
@i_tipo		    char(1)      = null,
@i_ciudad	    int          = null,
@i_opcion 	    char(1)      = null,
@i_cliente      int          = null,
@t_debug 	    char(1)      = 'N',
@t_file   	    varchar(14)  = null,
@t_from  	    varchar(30)  = null,
@t_trn                  INT       = NULL
)
as
declare	
@w_sp_name		         varchar(30),
@w_producto		         tinyint,
@w_tipo			         char(1),
@w_moneda		         tinyint,
@w_det_producto		   int,
@w_operacionca 		   int,
@w_op_cliente   	      int,
@w_op_nombre    	      varchar(64),
@w_error        	      int,
@w_parametro_autofv	   varchar(30),
@w_parametro_iva	      varchar(30),
@w_parametro_itim 	   varchar(30),
@w_cobra_iva            char(1),
@w_regimen_fiscal       varchar(10),
@w_comision_fag         varchar(30),
@w_parametro_lavact     char(1),
@w_op_direccion         tinyint,
@w_tipo_compania        varchar(10),
@w_nat_juridica         char(1),
@w_ente                 int,
@w_cliente              int,
@w_tramite              int,
@w_insert               char(1),
@w_numero               float,
@w_op_tipo              char(1),
@w_op_operacionca       int,
@w_rowcount             int,
@w_estado               int,
@w_est_credito          tinyint

---  Captura Nombre de Stored Procedure  
select	@w_sp_name = 'sp_qr_codeudor'


/* ESTADOS DE CARTERA */
exec @w_error = sp_estados_cca
@o_est_credito = @w_est_credito out


if @i_operacionca <> 0
begin
   select @w_op_tipo = isnull(opt_tipo, 'R')   ---VALIDACION PARA QUE NO INGRESEN LAS PASIVAS NR-201
   from ca_operacion_tmp
   where opt_operacion = @i_operacionca
   if @@rowcount = 0
   begin
      select @w_op_tipo = isnull(op_tipo, 'R')
      from ca_operacion
      where op_operacion = @i_operacionca
   end
end
else
begin
   select @w_op_tipo = isnull(opt_tipo, 'R'),   ---VALIDACION PARA QUE NO INGRESEN LAS PASIVAS NR-201
          @i_operacionca = opt_operacion
   from ca_operacion_tmp
   where opt_banco = @i_numero
   if @@rowcount = 0
   begin
      select @w_op_tipo = isnull(op_tipo, 'R'),
             @i_operacionca = op_operacion
      from ca_operacion
      where op_banco = @i_numero
   end

end


if @i_operacion = 'E'    ---eliminar Codeudor tabla ca_deudores_tmp
begin
    if exists (select 1 from ca_deudores_tmp
               where dt_operacion = @i_operacionca)
       delete ca_deudores_tmp
       where dt_operacion = @i_operacionca
       and   dt_deudor    = @i_cliente
end


if @i_operacion = 'Q'   ---Consulta codeudores
begin 

   select @w_tramite     = opt_tramite,
          @w_cliente     = opt_cliente,
          @w_operacionca = opt_operacion
   from ca_operacion_tmp
   where opt_banco  = @i_numero
   if @@rowcount <> 0
   begin

      select 'ROL  ' = dt_rol,
             'NOMBRE CLIENTE  ' = substring(rtrim(en_nombre) + ' '  + rtrim(p_p_apellido) + ' ' + rtrim(p_s_apellido),1,30),
             'CODIGO CLIENTE  ' = dt_cliente,
             'SEGVIDA  '        = dt_segvida
      from ca_deu_segvida, 
           cobis..cl_ente
      where dt_operacion = @w_operacionca
      and   en_ente = dt_cliente
   end

end


if (@i_operacion = 'X') and (@i_opcion = 'C') and (@w_op_tipo not in ('R','',null))
begin

   select @w_tramite     = opt_tramite,
          @w_cliente     = opt_cliente,
          @w_operacionca = opt_operacion
   from ca_operacion_tmp
   where opt_banco  = @i_numero
   if @@rowcount <> 0
   begin
      select @w_numero = convert(float,@i_numero)      

      if @w_numero = @w_operacionca   --no ha sido desembolsada
      begin

         select @w_insert  = 'N'

         if exists (select 1 from cob_credito..cr_deudores
                    where de_tramite  = @w_tramite)
         select @w_insert  = 'S'
         else 
         select @w_insert  = 'N'
 

         if not exists (select 1 from ca_deudores_tmp
                        where dt_operacion = @w_operacionca
                        and   dt_deudor    = @w_cliente
                        and   dt_rol       = 'D')  and @w_insert = 'S'
         begin
            insert into ca_deudores_tmp
            select @s_user,  
                   @s_sesn, 
                   @w_operacionca, 
                   @i_numero, 
                   de_cliente, 
                   de_rol, 
                   case de_rol 
                   when 'D' then 'S'  
                   else 'N' ---6175
                   end 
            from cob_credito..cr_deudores
            where de_tramite  = @w_tramite

            if @@error <> 0
            begin
               select @w_error = 708154
               goto ERROR
         
            end
            
         end

         select 'ROL  ' = dt_rol,
                'NOMBRE CLIENTE  ' = substring(rtrim(en_nombre) + ' '  + rtrim(p_p_apellido) + ' ' + rtrim(p_s_apellido),1,30),
                'CODIGO CLIENTE  ' = dt_deudor,
                'SEGVIDA  '        = dt_segvida
         from ca_deudores_tmp, cobis..cl_ente
         where dt_operacion = @w_operacionca
         and   en_ente = dt_deudor

      end
      else
      begin          ----si ha sido desembolsada

         select @w_insert  = 'N'

         if exists (select 1 from cob_credito..cr_deudores
                    where de_tramite  = @w_tramite)
         select @w_insert  = 'S'
         else 
         select @w_insert  = 'N'
 
         if not exists (select 1 from ca_deudores_tmp
                        where dt_operacion = @w_operacionca
                        and   dt_deudor    = @w_cliente
                        and   dt_rol       = 'D')   and @w_insert = 'S'
         begin
            insert into ca_deudores_tmp
            select @s_user,  
                   @s_sesn, 
                   @w_operacionca, 
                   @i_numero, 
                   de_cliente, 
                   de_rol, 
                   case de_rol 
                   when 'D' then 'S'
                   else 'N'
                   end 
            from cob_credito..cr_deudores
            where de_tramite  = @w_tramite
            
            if @@error <> 0
            begin
               select @w_error = 708154
               goto ERROR
         
            end
            
            update ca_deudores_tmp
            set dt_banco = @i_numero
            where dt_operacion  = @w_operacionca
            
            if @@error <> 0
            begin
               select @w_error = 708152
               goto ERROR
            end
            
         end

         if not exists (select 1 from ca_deudores_tmp
                        where dt_operacion  = @w_operacionca
                        and   dt_user = @s_user)
         begin
            update cob_cartera..ca_deudores_tmp
            set dt_operacion  = @w_operacionca
            where dt_operacion = 0
            and   dt_user = @s_user

            if @@error <> 0
            begin
               select @w_error = 708152
               goto ERROR
            end
                        
         end

         select 'ROL  ' = dt_rol,
                'NOMBRE CLIENTE  ' = substring(rtrim(en_nombre) + ' '  + rtrim(p_p_apellido) + ' ' + rtrim(p_s_apellido),1,30),
                'CODIGO CLIENTE  ' = dt_deudor,
                'SEGVIDA  '        = dt_segvida
         from ca_deudores_tmp, cobis..cl_ente
         where dt_operacion = @w_operacionca
         and   en_ente = dt_deudor
      end
   end
end


if @i_operacion = 'S' begin

   /* VERIFICAR LA EXISTENCIA DE LA OPERACION */
   select 
   @w_producto    = 7,
   @w_moneda      = op_moneda,
   @w_op_cliente  = op_cliente,
   @w_op_nombre   = op_nombre,
   @w_op_operacionca = op_operacion,
   @w_estado         = op_estado,
   @w_tramite        = op_tramite
   from ca_operacion
   where op_banco = @i_numero

   if @@rowcount = 0 begin
      select 
      @w_producto    = 7,
      @w_moneda      = opt_moneda,
      @w_op_cliente  = opt_cliente,
      @w_op_nombre   = opt_nombre,
      @w_op_operacionca = opt_operacion,
      @w_estado         = opt_estado,
      @w_tramite        = opt_tramite
      from ca_operacion_tmp
      where opt_banco = @i_numero

      if @@rowcount = 0 begin
         select @w_error = 701049 
         goto ERROR
      end
   end


   /* SOLO CONSULTAR DEUDOR PRINCIPAL */
   if @i_accion is null begin
      select 
      'ROL'     = 'D',
      'NOMBRE'  = @w_op_nombre,
      'CLIENTE' = @w_op_cliente
      return 0
   end


   /* CREAR TABLA DE TRABAJO */
   create table #clientes(
   rol              catalogo    null,     
   nombre           varchar(30) null,
   ced_ruc          varchar(12) null,
   cliente          int         null,
   calificacion     catalogo    null,
   vinculacion      catalogo    null,
   tvinculacion     catalogo    null,
   vinculacion_desc varchar(30) null,
   cobra_seguro     char(1)     null,
   central_riesgo   char(1)     null)


   /* SI EXISTEN, LOS DATOS SE TOMAN DE LA TABLA DE CARTERA */ 
   if exists (select 1 from cob_cartera..ca_deu_segvida
   where dt_operacion  = @w_op_operacionca)
   begin          

      insert into #clientes
      select
      'ROL'              = dt_rol,
      'NOMBRE'           = substring(rtrim(en_nombre) + ' '  + rtrim(p_p_apellido) + ' ' + rtrim(p_s_apellido),1,30),
      'DI./NIT'          = substring(en_ced_ruc,1,12),
      'CODIGO'           = dt_cliente,
      'CALIFICACION'     = en_calificacion,
      'VINCULACION'      = en_vinculacion,
      'T_VINCULACION'    = en_tipo_vinculacion,
      'DESCRIPCION'      = 'SIN DESCRIPCION',
      'COBRA SEGURO'     = dt_segvida,
      'CENTRAL_RIESGO'   = isnull(dt_central_riesgo, 'N')
      from cobis..cl_ente, ca_deu_segvida
      where dt_operacion = @w_op_operacionca 
      and   dt_cliente   = en_ente

      if @@error <> 0 begin
         select @w_error = 710001
         goto ERROR
      end

   end else begin
   
      if  @w_est_credito = @w_estado
         select @w_det_producto = 0
      else begin
         select @w_tipo = pd_tipo
         from   cobis..cl_producto
         where  pd_producto = @w_producto

         select  @w_det_producto = dp_det_producto
         from  cobis..cl_det_producto
         where dp_producto = @w_producto
         and   dp_tipo     = @w_tipo
         and   dp_moneda   = @w_moneda
         and   dp_cuenta   = @i_numero

         if @@rowcount = 0 begin
            select @w_error = 701047 
            goto ERROR
         end
      end

      if isnull(@w_det_producto,0) > 0 begin
         insert into #clientes
         select
         'ROL'              = cl_rol,
         'NOMBRE'           = substring(rtrim(en_nombre) + ' '  + rtrim(p_p_apellido) + ' ' + rtrim(p_s_apellido),1,30),
         'DI./NIT'          = substring(cl_ced_ruc,1,12),
         'CODIGO'           = cl_cliente,
         'CALIFICACION'     = en_calificacion,
         'VINCULACION'      = en_vinculacion,
         'T_VINCULACION'    = en_tipo_vinculacion,
         'DESCRIPCION'      = 'SIN DESCRIPCION',
         'COBRA SEGURO'     = 'N',     
         'CENTRAL_RIESGO'   = 'N'
         from cobis..cl_cliente, cobis..cl_ente
         where en_ente         =  cl_cliente
         and   cl_det_producto = @w_det_producto 
         
         if @@error <> 0 begin
            select @w_error = 710001
            goto ERROR
         end
      end
      else begin
         insert into #clientes
         select
         'ROL'              = de_rol,
         'NOMBRE'           = substring(rtrim(en_nombre) + ' '  + rtrim(p_p_apellido) + ' ' + rtrim(p_s_apellido),1,30),
         'DI./NIT'          = substring(de_ced_ruc,1,12),
         'CODIGO'           = de_cliente,
         'CALIFICACION'     = en_calificacion,
         'VINCULACION'      = en_vinculacion,
         'T_VINCULACION'    = en_tipo_vinculacion,
         'DESCRIPCION'      = 'SIN DESCRIPCION',
         'COBRA SEGURO'     = de_segvida,     
         'CENTRAL_RIESGO'   = de_cobro_cen
         from  cob_credito..cr_deudores, cobis..cl_ente
         where en_ente         =  @w_op_cliente
         and   en_ente         =  de_cliente
         and   de_tramite      =  @w_tramite
         if @@error <> 0 begin
            select @w_error = 710001
            goto ERROR
         end
      end

   end

   update #clientes set 
   vinculacion_desc = y.valor
   from cobis..cl_tabla x, cobis..cl_catalogo y
   where x.tabla  =  'cl_relacion_banco'
   and   x.codigo = y.tabla
   and   y.codigo = tvinculacion

   if @@error <> 0 begin
      select @w_error = 710002
      goto ERROR
   end

   select
   'ROL'              = rol,
   'NOMBRE'           = nombre,
   'DI./NIT'          = ced_ruc,
   'CODIGO'           = cliente,
   'CALIFICACION'     = calificacion,
   'VINCULACION'      = vinculacion,
   'DESCRIPCION'      = vinculacion_desc,
   'COBRA SEGURO'     = cobra_seguro,
   'CENTRAL RISGOS'   = central_riesgo
   from #clientes

end


if @i_operacion = 'T' -- OPERACION DESDE CREDITO
begin 
   select 
   @w_producto    = 7,
   @w_moneda      = opt_moneda,
   @w_operacionca = opt_operacion
   from ca_operacion_tmp
   where opt_banco = @i_numero

   if @@rowcount = 0 
   begin
      select @w_error = 701049 
      goto ERROR
   end
   
       
   select @w_tipo = pd_tipo
   from cobis..cl_producto
   where pd_producto = @w_producto
  set transaction isolation level read uncommitted
   select
   'ROL'        = clt_rol,
   'NOMBRE'     = rtrim(en_nombre) + ' '  + rtrim(p_p_apellido) + ' ' +
                  rtrim(p_s_apellido),
   'DI./NIT'    = clt_ced_ruc,
   'CODIGO'     = clt_cliente
   from	cobis..cl_ente,
   ca_cliente_tmp
   where  clt_operacion  = @i_numero
   and	  en_ente        = clt_cliente
   order by clt_rol desc

end


if @i_operacion = 'A' 
begin
   select @w_parametro_autofv = pa_char
   from cobis..cl_parametro
   where pa_nemonico = 'AUTOFV'
   and pa_producto = 'CCA'
   select @w_rowcount = @@rowcount
   set transaction isolation level read uncommitted

   if @w_rowcount =  0 
   begin  
      select @w_error = 710361
      goto ERROR
   end
   else
      select 'AutoFV' = ltrim(rtrim(@w_parametro_autofv))

end

if @i_operacion = 'W' 
begin
   if @i_tipo = 'P'
   begin
      select @w_op_cliente  = op_cliente
      from   ca_operacion
      where  op_banco = @i_numero

      select @w_regimen_fiscal = en_asosciada 
      from cobis..cl_ente
      where en_ente = @w_op_cliente
      set transaction isolation level read uncommitted

      select @w_cobra_iva    = rf_iva
      from cob_conta..cb_regimen_fiscal
      where rf_codigo = @w_regimen_fiscal
      
      if @w_cobra_iva is null
         select @w_cobra_iva = 'N'

      select @w_cobra_iva
      
   end
   if @i_tipo = 'C'
      select 'Ciudad' = convert(varchar(10),count(*))
      from   cob_conta..cb_exencion_ciudad
      where  ec_impuesto = 'I'
      and    ec_ciudad   = @i_ciudad
end

if @i_operacion = 'P' 
begin
   if @i_opcion = '0' 
   begin
      select ltrim(rtrim(pa_char))
      from cobis..cl_parametro
      where pa_nemonico = 'PIVA'
      and pa_producto = 'CCA'
      select @w_rowcount = @@rowcount
      set transaction isolation level read uncommitted

      if @w_rowcount =  0 
       begin  
         select @w_error = 710362
         goto ERROR
      end

      select ltrim(rtrim(pa_char))
      from cobis..cl_parametro
      where pa_nemonico = 'COMFAG'
      and pa_producto = 'CCA'
      select @w_rowcount = @@rowcount
      set transaction isolation level read uncommitted

      if @w_rowcount =  0 
      begin  
         select @w_error = 710362
         goto ERROR
      end


   end 

   if @i_opcion = '1' 
   begin
      select @w_parametro_itim = pa_char
      from cobis..cl_parametro
      where pa_nemonico = 'TIMBRE'
      and pa_producto = 'CCA'
      select @w_rowcount = @@rowcount
      set transaction isolation level read uncommitted

      if @w_rowcount =  0 
      begin  
         select @w_error = 710363
         goto ERROR
      end
      else
         select 'IVA' = ltrim(rtrim(@w_parametro_itim))
   end 
end 



if @i_operacion = 'J'    --SI EL CLIENTE ES PERSONA NATURAL O JURIDICA 
begin

   select @w_tipo_compania = en_subtipo
   from cobis..cl_ente
   where en_ente = @w_ente
   set transaction isolation level read uncommitted

   select @w_tipo_compania

end


---PARA CxP SIDAC

if @i_operacion = 'C' 
begin
    /*select
    'ORIGEN'              = rp_modulo_origen,
    'CONSECUTIVO'         = rp_consecutivo,
    'CxC/CxP'             = rp_submodulo,
    'DESCRIPCION CUENTA'  = substring(rp_descripcion,1,45),
    'VALOR'               = rp_saldo,
    'CONCEPTO'            = rp_concepto, 
    'No.REFERENCIA'       = rp_numero_referencia,    
    'ESTADO'              = case rp_estado
                            when 'V' then  'VIGENTE'
                            when 'C' then  'CANCELADO'
                            when 'P' then  'PENDIENTE'
                           end
                                      
     from  cob_sidac..sid_registros_padre
     where rp_empresa = 1 
     and rp_submodulo in ('CC','CP')
     and   rp_ente =  @i_cliente
     and   rp_saldo > 0
     and   rp_estado in ('V','P')     
     order by rp_modulo_origen,rp_consecutivo*/
     
     exec cob_interface..sp_codeudor_interfase
        @i_operacion       = 'C',
        @i_cliente         = @i_cliente

end

if @i_operacion = 'D' 
begin
   select 
      'No.'         = di_direccion,
      'DESCRIPCION' = substring(di_descripcion,1,40) ,
      'TELEFONO'    = isnull(te_valor,'NO TIENE')   
            from cobis..cl_ente
            LEFT OUTER JOIN cobis..cl_direccion on
                        en_ente = di_ente 
                         LEFT OUTER JOIN cobis..cl_telefono on
                         te_ente = di_ente and
                         di_direccion = te_direccion
                         where en_ente = @i_cliente
   /*if @@rowcount = 0 
   begin
   select @w_error = 701049 
   goto ERROR
   end*/
end

---Parametro para lavado de activos en front-end

if @i_operacion = 'L' 
begin
  if not exists (select 1 from cobis..cl_ente
     where en_ente = @i_cliente
     and en_subtipo = 'C')
     begin
      select @w_error =  710474
      goto ERROR
     end
end

---NR  479
if @i_operacion = 'F' 
begin

 if not exists (select 1 from cobis..cl_catalogo
                where tabla = ( select codigo
                    from cobis..cl_tabla
                    where tabla = 'ca_concepto_dpg'))
      begin  
         select @w_error = 711023
         goto ERROR
       end
      
    /* select 
      'VALOR' =rp_saldo,
      'No.REFERENCIA' = rp_numero_referencia,
      'CONSECUTIVO' = rp_consecutivo,
      'OFICINA' = rp_oficina
            
      from cob_sidac..sid_registros_padre
      where rp_numero_referencia > ''
      and   rp_consecutivo >= 0
      and   rp_ente = @i_cliente
      and   rp_concepto in ( select codigo from cobis..cl_catalogo
                             where tabla = ( select codigo
                                            from cobis..cl_tabla
                                            where tabla = 'ca_concepto_dpg')
                            )
      and   rp_submodulo = 'CP'
      and   rp_saldo > 0
      and   rp_estado in ( 'V','P')
      and   rp_empresa = 1
    order by rp_consecutivo */
     exec cob_interface..sp_codeudor_interfase
        @i_operacion       = 'F',
        @i_cliente         = @i_cliente
         
end

return 0

ERROR:

exec cobis..sp_cerror
 @t_debug  ='N',
 @t_file   = null,
 @t_from   = @w_sp_name,
 @i_num    = @w_error

 return  @w_error
go