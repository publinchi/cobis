/************************************************************************/
/*	Archivo:		convenio.sp				*/
/*	Stored procedure:	sp_procesos_convenios		        */
/*	Base de datos:		cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Elcira Pelaez Burbanco			*/
/*	Fecha de escritura:	abril 2001 				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	"MACOSA"							*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/************************************************************************/  
/*				PROPOSITO				*/
/*	Ejecutar el sp que crea cliente rapido y realcionar este cliente*/
/*      con la empresa que le corresponde.				*/
/*      Ejecuta el sp de crear la operacion automatica	y crear el 	*/
/*      tramite en credito                                              */
/************************************************************************/  
/*				MODIFICACIONES				*/
/*	FECHA		AUTOR	    	RAZON				*/
/*	nov-6-2001       EPB  						*/
/*      feb-07-2002      EPB            Avalistas                       */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_procesos_convenios')
	drop proc sp_procesos_convenios
go

create proc sp_procesos_convenios 
        @s_ssn            int = null,
        @s_sesn           int = null,
        @s_ofi            smallint = null,
        @s_user           login,
        @s_term           varchar (30),
        @s_srv            varchar(30),
        @i_usuario_tr     login,
        @i_fecha_proceso  datetime


as


declare @w_sp_name    		      varchar(64),
	@w_nombre_completo            varchar(64),
        @w_error                      int,
        @w_return                     int,
        @w_ente                       int,
        @w_ente_empresa               int,
        @w_empresa                    numero,
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
        @w_clase_cartera              catalogo,
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
        @w_truta   	              tinyint,
        @w_etapa                      tinyint,
        @w_commit                     char(1),
        @w_descripcion                varchar(255),
        @w_banca                      catalogo,
        @w_rowcount                   int
        

select @w_sp_name   = 'sp_procesos_convenios',
       @w_ente      = 0,
       @w_ente_empresa = 0,
       @w_tramite      = 0


/* PARAMETROS GENERALES */
select @w_valor_relacion = pa_smallint
from cobis..cl_parametro
where pa_nemonico = 'R-CONV'
and   pa_producto = 'CCA'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount =  0 begin
   select @w_error = 710222
   goto  ERROR
end



declare cursor_convenios cursor for
select
con_empresa,            con_subtipo,          con_oficina_cliente,   con_identificacion,
con_tipo_identificacion,con_linea_credito,    con_monto,             con_moneda,
con_sector,             con_oficina_oper,     con_oficial,           con_destino,
con_ubicacion,          con_fecha_inicio,     con_estado_registro,   con_clase_cartera,
con_cupo_linea
from ca_convenios_tmp
where con_error_tramite = 0
order by con_error_tramite
for read only

open  cursor_convenios

fetch cursor_convenios into
@w_empresa,            @w_subtipo,            @w_oficina_cliente,   @w_identificacion,
@w_tipo_identificacion,@w_linea_credito,      @w_monto,             @w_moneda,
@w_sector,             @w_oficina_oper,       @w_oficial,           @w_destino,
@w_ubicacion,          @w_fecha_inicio,       @w_estado_registro,   @w_clase_cartera,
@w_cupo_linea

while @@fetch_status = 0 begin

   if @@fetch_status = -1 begin
       select @w_error = 710219
       goto  ERROR
   end  



   begin tran --atomicidad por registro
   select @w_commit = 'S'
        	
    select @w_descripcion = ''
    ---PRINT 'convenio.sp cedula que va %1!,@w_cupo_linea %2!'+ @w_identificacion + @w_cupo_linea
    
   /*VALIDACION EXISTENCIA DE LA EMPRESA*/
  select @w_ente_empresa = en_ente
  from cobis..cl_ente
  where en_ced_ruc = @w_empresa
  select @w_rowcount = @@rowcount
  set transaction isolation level read uncommitted

  if @w_rowcount = 0
     select @w_ente_empresa = 0

  if @w_ente_empresa <> 0  begin
  
     select  @w_ente = en_ente
     from cobis..cl_ente
     where en_ced_ruc = @w_identificacion
     and   en_subtipo = @w_subtipo
     select @w_rowcount = @@rowcount
     set transaction isolation level read uncommitted

     if @w_rowcount = 0
        select @w_ente = 0
   
     if @w_ente = 0 begin   ---EPB:feb-07-2002 Retorno error si no existe el cliente
         select @w_error = 710104
         goto  ERROR
     end
     
     if @w_ente <> 0 begin

         /* ACTUALIZAR EL CEM DEL CLIENTE */

         update cobis..cl_ente
         set en_max_riesgo = isnull(en_max_riesgo,0) + @w_monto
         where en_ente = @w_ente


           select @w_ciudad = of_ciudad
           from cobis..cl_oficina
           where of_oficina = @w_oficina_oper
	   set transaction isolation level read uncommitted

            
        /*VALIDAR LA EXISTENCIA DE LA RELACION EMPRESA - EMPLEADO*/

        select @w_relacion = 'N'
        if exists (select 1 from cobis..cl_instancia
                   where in_relacion = @w_valor_relacion
                   and   in_ente_i = @w_ente_empresa
                   and   in_ente_d = @w_ente 
                   and   in_lado   = 'D')
         select @w_relacion = 'S'


         if @w_relacion = 'N' begin

            exec @w_return = cobis..sp_instancia
            @t_debug     = 'N',
            @t_trn       = 1367,
            @i_operacion = 'I',
            @i_relacion  = @w_valor_relacion,
            @i_derecha   = @w_ente,
            @i_izquierda = @w_ente_empresa,
            @i_lado      = 'D'
           if @w_return != 0 begin
              select @w_error = @w_return 
              if @w_error = 1
                 select @w_descripcion =  'Genero error ejecutando cobis..sp_instancia'

              goto  ERROR
           end

         end

         /*NOMBRE COMPLETO*/
	 select 
         @w_nombre_completo  = rtrim(p_p_apellido)+' '+rtrim(p_s_apellido)+' '+rtrim(en_nombre)
         from  cobis..cl_ente
         where en_ente = @w_ente
	 set transaction isolation level read uncommitted

         /*SACAR SECUENCIALES SESIONES*/
            exec @s_ssn = sp_gen_sec 
            @i_operacion  = -1

            exec @s_sesn = sp_gen_sec 
            @i_operacion  = -1


	 /* INGRESAR DEUDOR */
	 exec @w_return = sp_codeudor_tmp
         @s_sesn        = @s_sesn,
         @s_user        = @s_user,
         @i_borrar      = 'S',
         @i_secuencial  = 1,
         @i_titular     = @w_ente,
         @i_operacion   = 'A',
         @i_codeudor    = @w_ente,
         @i_ced_ruc     = @w_identificacion,
         @i_rol         = 'D',
         @i_externo     = 'N'

          if @w_return != 0 begin
             select @w_error = @w_return 
             if @w_error = 1
                select @w_descripcion =  'Genero error ejecutando sp_codeudor_tmp'

             goto  ERROR
          end

	 /*CREACION DE LA OPERACION EN TEMPORALES*/

          PRINT 'convenio.sp Va para  sp_crear_operacion @w_clase_cartera'+ @w_clase_cartera

          exec @w_return = sp_crear_operacion
 	  @s_user              = @s_user,
	  @s_date              = @i_fecha_proceso,
	  @s_term              = @s_term,
	  @i_cliente           = @w_ente,
	  @i_nombre            = @w_nombre_completo,
	  @i_sector            = @w_sector,
	  @i_toperacion        = @w_linea_credito,
	  @i_oficina           = @w_oficina_oper,
	  @i_moneda            = @w_moneda,
	  @i_comentario        = 'OPERACION DE CONVENIO',
	  @i_oficial           = @w_oficial,
	  @i_fecha_ini         = @i_fecha_proceso,
	  @i_monto             = @w_monto,
	  @i_monto_aprobado    = @w_monto,
	  @i_destino           = @w_destino,
	  @i_ciudad            = @w_ciudad,
	  @i_formato_fecha     = 101,
	  @i_salida            = 'N',
	  @i_fondos_propios    = 'N',
	  @i_origen_fondos     = '15',
          @i_lin_credito       = @w_cupo_linea,	
          @i_clase_cartera     = @w_clase_cartera,
	  @o_banco             = @w_banco output
          if @w_return != 0 begin
             select @w_error = @w_return 
             if @w_error = 1
                select @w_descripcion =  'Genero error ejecutando sp_crear_operacion'
              goto  ERROR
          end


         select @w_periodo = opt_tplazo,
                @w_num_periodos = opt_plazo,
                @w_clase        = isnull(opt_clase,'2'),
                @w_operacionca  = opt_operacion
          from ca_operacion_tmp
          where opt_banco = @w_banco

	   /* PASO A  DEFINITIVAS */

	   exec @w_return = sp_operacion_def
	   @s_date   = @i_fecha_proceso,
	   @s_sesn   = @s_sesn,
	   @s_user   = @s_user,
	   @s_ofi    = @w_oficina_oper,
	   @i_banco  = @w_banco

	   if @w_return != 0  begin
	      select @w_error = @w_return
              if @w_error = 1
                 select @w_descripcion =  'Genero error ejecutando sp_operacion_def'

	      goto ERROR
	   end

           /* BORAR TEMPORALES */
           exec @w_return = sp_borrar_tmp
           @i_banco  = @w_banco,
           @s_date   = @i_fecha_proceso,
           @s_user   = @s_user
           if @w_return <> 0  begin
              select @w_error = @w_return 
              if @w_error = 1
                 select @w_descripcion =  'Genero error ejecutando sp_borrar_tmp'
             goto  ERROR
           end
          select @w_tramite = 0


          PRINT 'convenio.sp va para cob_credito..sp_convenios  @w_banco' + @w_banco + '@w_clase' + @w_clase

          exec @w_return =  cob_credito..sp_convenios
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
          @i_linea_credito  =  @w_cupo_linea,  
          @i_toperacion     =  @w_linea_credito,
          @i_producto       = 'CCA',
          @i_monto          =  @w_monto, 
          @i_moneda         =  @w_moneda, 
          @i_periodo        =  @w_periodo,
          @i_num_periodos   =  @w_num_periodos,
          @i_destino        =  @w_destino,
          @i_ciudad_destino =  @w_ubicacion,
          @i_cliente        =  @w_ente,
          @i_estado         =  @w_estado_registro,
          @i_clase          =  @w_clase,
          @o_tramite        =  @w_tramite   out
          if @w_return != 0 begin
             select @w_error = @w_return 
             if @w_tramite  = 0
                select @w_descripcion =  'Genero error cob_credito..sp_convenios'

             goto  ERROR
          end
          else begin
             /* ACTUALIZAR EL TRAMITE LA OPERACION DEFINITIVA */
             update ca_operacion 
             set op_tramite = @w_tramite,
                 op_banco   = convert(varchar(10),@w_operacionca),
                 op_estado  = 99,
                 op_comentario = 'CREADO POR BATH - CREACION MASIVA TRAMITES CONVENIO'
             where op_operacion = @w_operacionca

             /* ACTUALIZAR ca_convenio_tmp PARA REPORTE */
	     update ca_convenios_tmp
	     set con_error_tramite = @w_tramite
	    where con_identificacion  = @w_identificacion
          end

          ---PRINT 'convenio.sp Salio de cob_credito..sp_convenios  @w_tramite' + @w_tramite

     end

  end
  else begin
    select @w_error = 710220
    goto  ERROR
  end 

   commit tran     ---Fin de la transaccion 
   select @w_commit = 'N'

   goto SIGUIENTE

   ERROR:  
   
   select @w_descripcion = 'CREACION MASIVA DE TRAMITES' + @w_descripcion                                                  
   exec sp_errorlog                                             
   @i_fecha     = @i_fecha_proceso,
   @i_error     = @w_error,
   @i_usuario   = @s_user,
   @i_tran      = 7000, 
   @i_tran_name = @w_sp_name,
   @i_rollback  = 'N',  
   @i_cuenta= @w_identificacion, 
   @i_descripcion = @w_descripcion

   if @w_commit = 'S' commit tran
   goto SIGUIENTE

  SIGUIENTE: 

  fetch cursor_convenios into
  @w_empresa,            @w_subtipo,            @w_oficina_cliente,   @w_identificacion,
  @w_tipo_identificacion,@w_linea_credito,      @w_monto,             @w_moneda,
  @w_sector,             @w_oficina_oper,       @w_oficial,           @w_destino,
  @w_ubicacion,          @w_fecha_inicio,       @w_estado_registro,   @w_clase_cartera,
  @w_cupo_linea

end /*Cursor convenios*/


close cursor_convenios
deallocate cursor_convenios

return 0

go

