/************************************************************************/
/*   Archivo:              incentivos_metas.sp                          */
/*   Stored procedure:     sp_incentivos_metas                          */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Guisela Fernandez                            */
/*   Fecha de escritura:   01/10/2021                                   */
/************************************************************************/
/*                             IMPORTANTE                               */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBISCORP'.                                                       */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBISCORP o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*  Proceso para manejar los montos de incentivos establecido a los     */
/*  acesores en cada oficina                                            */
/************************************************************************/
/* CAMBIOS                                                              */
/* FECHA           AUTOR             CAMBIO                             */
/* 01/10/2021     G. Fernandez       Versión inicial                    */
/* 30/11/2022     J. Guzman          Funcionalidad metas para incentivos*/
/*                                   individual y masivo                */
/* 02/12/2022     J. Guzman          Se arregla consulta al nombre del  */
/*                                   oficial                            */
/* 14/12/2022     K. Rodríguez       Val.regs.repetidos(anio,ofi,asesor)*/
/************************************************************************/

use cob_cartera
go

if exists(select 1 from sysobjects where name ='sp_incentivos_metas')
   drop proc sp_incentivos_metas

go

create proc sp_incentivos_metas (
   @s_user                 login,
   @s_term                 varchar(30), 
   @s_date                 datetime,
   @s_ofi                  smallint,
   @t_trn                  int              = null, 
   @i_operacion            char(1),
   @i_modo                 smallint         = null,
   @i_externo              char(1)          = 'N',
   @i_reg_inc_men          varchar(254)     = null,
   @i_oficina              int              = null,
   @i_anio                 int              = null,
   @i_cod_asesor           int              = null,
   @i_nombre_asesor        varchar(64)      = null,
   @i_mes                  int              = null,
   @i_monto_proyectado     money            = null,
   @i_observacion          varchar(254)     = null,
   @i_ope_masiva           varchar(10)      = null,
   @o_cant_errores         int              = null out
)
as 

declare
@w_sp_name               varchar (32),
@w_error                 int = 0,
@w_oficina               smallint,
@w_anio                  smallint,
@w_cod_asesor            int, 
@w_nombre_asesor         varchar(254),
@w_usuario               varchar(50),
@w_count                 smallint,
@w_mes                   smallint,
@w_monto                 money,
@w_monto_original        money,
@w_fecha_proceso         datetime,
@w_total_errores         int,
@w_mes_fecproc           tinyint,
@w_anio_fecproc          smallint,
@w_mes_inicial           tinyint


select @w_total_errores = 0


select @w_fecha_proceso = fp_fecha 
from cobis..ba_fecha_proceso

if @i_operacion in ('I', 'U', 'M') and @i_modo = 1 -- Operaciones individuales 
begin

   --Se obtiene nombre del asesor
   select @w_nombre_asesor = fu_nombre
   from cobis..cl_funcionario,cobis..cc_oficial
   where oc_funcionario = fu_funcionario
   and oc_oficial = @i_cod_asesor
   
   --Creacion de tabla temporal
   create table #montos_mensuales(
      mes    int identity(1,1),
      monto  money,
   )
   
   insert into #montos_mensuales
   select value
   from string_split(@i_reg_inc_men, '|')
   
end

/* INSERTAR REGISTRO INDIVIDUAL */
if @i_operacion  = 'I'
begin
   if @i_externo = 'S'
      begin tran
      
   if @i_modo = 1 -- Actualizacion individual, CLAVE: A
   begin
   
      /* Validación del oficial */
      if not exists(select 1 
                    from cobis..cc_oficial
                    where oc_oficial = @i_cod_asesor)
      begin
         /* No existe el oficial */
         select @w_error = 725194
         goto ERROR
      end
      
      /* Validación de la oficina */
      if not exists(select 1 
                    from cobis..cl_oficina
                    where of_oficina = @i_oficina)
      begin
         /* No existe oficina */
         select @w_error = 701102
         goto ERROR
      end
      
      /* Validación oficial pertenece a oficina */
      if not exists(select 1 
                    from cobis..cc_oficial, cobis..cl_funcionario
                    where oc_funcionario = fu_funcionario
                    and   oc_oficial = @i_cod_asesor
                    and   fu_oficina = @i_oficina)
      begin
         /* El oficial no esta asignado a la oficina */
         select @w_error = 725196 
         goto ERROR
      end
      
      
      insert into ca_incentivos_metas 
      select  @i_anio, @i_oficina, @i_cod_asesor, mes, @w_nombre_asesor, monto
      from #montos_mensuales
      
      if @@error != 0 
      begin
         /* Error al insertar registro de incentivos en tabla definitiva */
         select @w_error = 725191
         goto ERROR
      end  
      
      select @w_count = 1
      
      while @w_count < = 12
      begin
         select @w_mes   = mes,
                @w_monto = monto
         from #montos_mensuales
         where mes = @w_count
         
         exec @w_error  = sp_tran_servicio
         @s_user      = @s_user,
         @s_date      = @s_date,
         @s_ofi       = @s_ofi,
         @s_term      = @s_term,
         @i_tabla     = 'ca_incentivos_metas',
         @i_clave1    = @i_anio,
         @i_clave2    = @i_oficina,
         @i_clave3    = @i_cod_asesor,
         @i_clave4    = @w_mes,
         @i_clave5    = @i_observacion,
         @i_clave6    = 'I',   --Acción: Inserción registro
         @i_clave7    = 'A'    --Opción: Actualización individual
         
         if @w_error != 0 
            goto ERROR
         
         select @w_count = @w_count +1    
      end
      
      drop table #montos_mensuales

   end 
   
   if @i_externo  = 'S'
      commit tran
end


/* CONSULTAR */
if @i_operacion  = 'S'
begin

   if exists (select 1 from sysobjects where name = '#incentivos_metas_consulta')
      drop table #incentivos_metas_consulta

   --Tabla temporal para consulta y envío al frontend
   create table #incentivos_metas_consulta (
      anio              smallint,
      oficina           smallint,
      cod_asesor        int,
      nombre_asesor     varchar(254),
      monto_ene         money,
      monto_feb         money,
      monto_mar         money,
      monto_abr         money,
      monto_may         money,
      monto_jun         money,
      monto_jul         money,
      monto_ago         money,
      monto_sep         money,
      monto_oct         money,
      monto_nov         money,
      monto_dic         money
   )
   
   if @@error != 0
   begin
      select @w_error  = 171160 --Error en creación de tabla temporal
      goto ERROR
   end
      
   if @i_modo = 1
   begin
   
      insert into #incentivos_metas_consulta (anio, oficina, cod_asesor, nombre_asesor )
      select distinct im_anio, im_oficina, im_cod_asesor, fu_nombre
      from ca_incentivos_metas,
           cobis..cl_funcionario,
           cobis..cc_oficial
      where im_anio = @i_anio 
      and   oc_funcionario = fu_funcionario
      and   oc_oficial = im_cod_asesor
      
      if @@rowcount = 0
      begin
         /* Error. No existen registros de incentivos */
         select @w_error = 725192
         goto ERROR
      end
      
      --Inicio de cursor para completar datos
      declare registros_incentivos cursor for
      select oficina, cod_asesor, nombre_asesor 
      from #incentivos_metas_consulta
      
      open registros_incentivos
      
      fetch next from registros_incentivos into
      @w_oficina, @w_cod_asesor, @w_nombre_asesor
      
      while (@@fetch_status = 0)
      begin
         
         update #incentivos_metas_consulta
         set monto_ene = im_monto_proyectado
         from ca_incentivos_metas
         where im_anio        = anio
         and   im_oficina     = oficina
         and   im_cod_asesor  = cod_asesor
         and   im_mes         = 1
         
         update #incentivos_metas_consulta
         set monto_feb = im_monto_proyectado
         from ca_incentivos_metas
         where im_anio        = anio
         and   im_oficina     = oficina
         and   im_cod_asesor  = cod_asesor
         and   im_mes         = 2
         
         update #incentivos_metas_consulta
         set monto_mar = im_monto_proyectado
         from ca_incentivos_metas
         where im_anio        = anio
         and   im_oficina     = oficina
         and   im_cod_asesor  = cod_asesor
         and   im_mes         = 3

         update #incentivos_metas_consulta
         set monto_abr = im_monto_proyectado
         from ca_incentivos_metas
         where im_anio        = anio
         and   im_oficina     = oficina
         and   im_cod_asesor  = cod_asesor
         and   im_mes         = 4

         update #incentivos_metas_consulta
         set monto_may = im_monto_proyectado
         from ca_incentivos_metas
         where im_anio        = anio
         and   im_oficina     = oficina
         and im_cod_asesor  = cod_asesor
         and   im_mes         = 5

         update #incentivos_metas_consulta
         set monto_jun = im_monto_proyectado
         from ca_incentivos_metas
         where im_anio        = anio
         and   im_oficina     = oficina
         and   im_cod_asesor  = cod_asesor
         and   im_mes         = 6

         update #incentivos_metas_consulta
         set monto_jul = im_monto_proyectado
         from ca_incentivos_metas
         where im_anio        = anio
         and   im_oficina     = oficina
         and   im_cod_asesor  = cod_asesor
         and   im_mes         = 7

         update #incentivos_metas_consulta
         set monto_ago = im_monto_proyectado
         from ca_incentivos_metas
         where im_anio        = anio
         and   im_oficina     = oficina
         and   im_cod_asesor  = cod_asesor
         and   im_mes         = 8

         update #incentivos_metas_consulta
         set monto_sep = im_monto_proyectado
         from ca_incentivos_metas
         where im_anio        = anio
         and   im_oficina     = oficina
         and   im_cod_asesor  = cod_asesor
         and   im_mes         = 9

         update #incentivos_metas_consulta
         set monto_oct = im_monto_proyectado
         from ca_incentivos_metas
         where im_anio        = anio
         and   im_oficina     = oficina
         and   im_cod_asesor  = cod_asesor
         and   im_mes         = 10

         update #incentivos_metas_consulta
         set monto_nov = im_monto_proyectado
         from ca_incentivos_metas
         where im_anio        = anio
         and   im_oficina     = oficina
         and   im_cod_asesor  = cod_asesor
         and   im_mes         = 11

         update #incentivos_metas_consulta
         set monto_dic = im_monto_proyectado
         from ca_incentivos_metas
         where im_anio        = anio
         and   im_oficina     = oficina
         and   im_cod_asesor  = cod_asesor
         and   im_mes         = 12
         
      
      fetch next from registros_incentivos into
      @w_oficina, @w_cod_asesor, @w_nombre_asesor
      
      end
      
      close registros_incentivos
      deallocate registros_incentivos
      
      select * from #incentivos_metas_consulta
      
   end
end


/* ACTUALIZAR REGISTRO INDIVIDUAL */
if @i_operacion  = 'U'
begin

   if @i_externo = 'S'
      begin tran

   if @i_modo = 1 -- Actualizacion individual, CLAVE: A
   begin
   
      /* Validación del oficial */
      if not exists(select 1 
                    from cobis..cc_oficial
                    where oc_oficial = @i_cod_asesor)
      begin
         /* No existe el oficial */
         select @w_error = 725194
         goto ERROR
      end
      
      /* Validación de la oficina */
      if not exists(select 1 
                    from cobis..cl_oficina
                    where of_oficina = @i_oficina)
      begin
         /* No existe oficina */
         select @w_error = 701102
         goto ERROR
      end
      
      /* Validación oficial pertenece a oficina */
      if not exists(select 1 
                    from cobis..cc_oficial, cobis..cl_funcionario
                    where oc_funcionario = fu_funcionario
                    and   oc_oficial = @i_cod_asesor
                    and   fu_oficina = @i_oficina)
      begin
         /* El oficial no esta asignado a la oficina */
         select @w_error = 725196
         goto ERROR
      end
      
      select @w_count = 1
      
      while @w_count <= 12
      begin
         select @w_monto_original = im_monto_proyectado
         from ca_incentivos_metas
         where im_anio        = @i_anio
         and im_oficina       = @i_oficina
         and im_cod_asesor    = @i_cod_asesor
         and im_mes           = @w_count
         
         select @w_mes   = mes,
                @w_monto = monto
         from #montos_mensuales
         where mes = @w_count
         
         if (@w_monto_original != @w_monto)  -- Detecta cambio de monto
         begin
               
            update ca_incentivos_metas
            set im_monto_proyectado = @w_monto --@i_monto_proyectado
            where im_anio        = @i_anio
            and im_oficina       = @i_oficina
            and im_cod_asesor    = @i_cod_asesor
            and im_mes           = @w_mes
            
            if @@error != 0 
            begin
               /* Error. No se actualizo el registro de incentivos */
               select @w_error = 725193
               goto ERROR
            end
            
            exec @w_error  = sp_tran_servicio
            @s_user      = @s_user,
            @s_date      = @s_date,
            @s_ofi       = @s_ofi,
            @s_term      = @s_term,
            @i_tabla     = 'ca_incentivos_metas',
            @i_clave1    = @i_anio,
            @i_clave2    = @i_oficina,
            @i_clave3    = @i_cod_asesor,
            @i_clave4    = @w_mes,
            @i_clave5    = @i_observacion,
            @i_clave6    = 'U',   --Acción: Actualización registro
            @i_clave7    = 'A'    --Opción: Actualización individual
            
            if @w_error != 0 
               goto ERROR
         end
         
         select @w_count = @w_count + 1
         
      end
      
      drop table #montos_mensuales
      
   end
   
   if @i_externo  = 'S'
      commit tran
end

/* Eliminación de registro individual de metas para incentivos */
if @i_operacion = 'D'
begin
   if @i_externo = 'S'
      begin tran

   if exists(select 1
             from ca_incentivos_calculo_comisiones
             where icc_anio    = @i_anio
             and   icc_oficina = @i_oficina
             and   icc_oficial = @i_cod_asesor)
   begin
      /* Error de eliminación, Oficial cuenta con calculo de incentivos en el año solicitado */
      select @w_error = 725198
      goto ERROR
   end
      
   declare cur_eliminar_metas cursor for
   select im_anio, im_oficina, im_cod_asesor, im_mes, im_nombre_asesor
   from ca_incentivos_metas
   where im_anio       = @i_anio
   and   im_oficina    = @i_oficina
   and   im_cod_asesor = @i_cod_asesor
   
   open cur_eliminar_metas
   
   fetch next from cur_eliminar_metas into
   @w_anio, @w_oficina, @w_cod_asesor, @w_mes, @w_nombre_asesor
   
   while (@@fetch_status = 0)
   begin
      exec @w_error  = sp_tran_servicio
      @s_user      = @s_user,
      @s_date      = @s_date,
      @s_ofi       = @s_ofi,
      @s_term      = @s_term,
      @i_tabla     = 'ca_incentivos_metas',
      @i_clave1    = @w_anio,
      @i_clave2    = @w_oficina,
      @i_clave3    = @w_cod_asesor,
      @i_clave4    = @w_mes, 
      @i_clave5    = @i_observacion,
      @i_clave6    = 'D',   --Acción: Eliminación registro
      @i_clave7    = 'A'    --Opción: Actualización individual
            
      if @w_error != 0 
      begin
         close cur_eliminar_metas
         deallocate cur_eliminar_metas
         
         goto ERROR
      end
         
      delete from ca_incentivos_metas
      where im_anio       = @w_anio
      and   im_oficina    = @w_oficina
      and   im_cod_asesor = @w_cod_asesor
      and   im_mes        = @w_mes
      
      if @@error != 0 
      begin
         /* Error en eliminacion tabla ca_incentivos_metas */
         select @w_error = 707082
         
         close cur_eliminar_metas
         deallocate cur_eliminar_metas
         
         goto ERROR
      end
         
      fetch next from cur_eliminar_metas into
      @w_anio, @w_oficina, @w_cod_asesor, @w_mes, @w_nombre_asesor
      
   end  --End while
   
   close cur_eliminar_metas
   deallocate cur_eliminar_metas
      
   if @i_externo = 'S'
      commit tran
end

/* REGISTRO EN TABLA TEMPORAL DE INSERCIONES O ACTUALIZACIONES MASIVAS */
if @i_operacion = 'M'
begin
   
   if @i_externo = 'S'
      begin tran

   insert into ca_incentivos_metas_tmp 
   select @i_anio, @i_oficina, @i_cod_asesor, mes, @i_nombre_asesor, monto, @s_user
   from #montos_mensuales
   
   if @@error != 0 
   begin
      /* Error al insertar registro de incentivos en tabla temporal */
      select @w_error = 725195
      goto ERROR
   end
   
   if @i_externo = 'S'
      commit tran
      
   drop table #montos_mensuales
   
end

/* VALIDACIONES DE REGISTROS DE INSERCIÓN O ACTUALIZACIÓN MASIVA */
if @i_operacion = 'V'
begin

   if @i_externo = 'S'
      begin tran
   
   delete from ca_errores_ope_masivas
   where eom_usuario = @s_user
   
   if @@error != 0 
   begin
      /* Error en eliminacion tabla ca_errores_ope_masivas */
      select @w_error = 707081
      goto ERROR
   end
   
   if @i_ope_masiva = 'AM'  --Actualización Masiva
   begin
      /* Validación de registros en tabla definitiva para el año seleccionado */
      if not exists(select 1
                    from ca_incentivos_metas
                    where im_anio = @i_anio)
      begin
         insert into ca_errores_ope_masivas
         values ('No se han cargado las metas para el año seleccionado. No existen registros para el año ' + convert(varchar, @i_anio), @s_user)
         
         if @@error != 0 
         begin
            /* Error en insercion */
            select @w_error = 708154
            goto ERROR
         end
      end
   end
   
   declare cur_registros_masivos cursor for
   select distinct imt_anio, imt_oficina, imt_cod_asesor, imt_usuario_login
   from ca_incentivos_metas_tmp
   where imt_usuario_login = @s_user

   open cur_registros_masivos
   
   fetch next from cur_registros_masivos into
   @w_anio, @w_oficina, @w_cod_asesor, @w_usuario
   
   while (@@fetch_status = 0)
   begin
   
      /* Validación de no repetir registros para el año, oficina, asesor*/
	  if (select count(1) from ca_incentivos_metas_tmp 
	      where imt_anio     = @w_anio
          and imt_oficina    = @w_oficina 
		  and imt_cod_asesor = @w_cod_asesor
		  and imt_usuario_login = @w_usuario) > 12
      begin
         insert into ca_errores_ope_masivas
         values ('Datos repetidos para el año: ' + convert(varchar, @w_anio) + ', oficina: ' + convert(varchar, @w_oficina) + ', asesor: ' + convert(varchar, @w_cod_asesor) , @s_user)
         
         if @@error != 0 
         begin
            select @w_error = 708154
            close cur_registros_masivos
            deallocate cur_registros_masivos
            goto ERROR
         end
	  end
      
      /* Validación de oficial */
      if not exists(select 1 
                    from cobis..cc_oficial
                    where oc_oficial = @w_cod_asesor)
      begin
         insert into ca_errores_ope_masivas
         values ('El oficial con código ' + convert(varchar, @w_cod_asesor) + ' no existe', @s_user)
         
         if @@error != 0 
         begin
            /* Error en insercion */
            select @w_error = 708154
            
            close cur_registros_masivos
            deallocate cur_registros_masivos
   
            goto ERROR
         end
      end
         
      /* Validación de oficina */
      if not exists(select 1 
                    from cobis..cl_oficina
                    where of_oficina = @w_oficina)
      begin
         insert into ca_errores_ope_masivas
         values ('La oficina ' + convert(varchar, @w_oficina) + ' no existe', @s_user)
         
         if @@error != 0 
         begin
            /* Error en insercion */
            select @w_error = 708154
            
            close cur_registros_masivos
            deallocate cur_registros_masivos
            
            goto ERROR
         end
      end
         
      /* Validación oficial pertenece a oficina */
      if not exists(select 1 
                    from cobis..cc_oficial, cobis..cl_funcionario
                    where oc_funcionario = fu_funcionario
                    and   oc_oficial = @w_cod_asesor
                    and   fu_oficina = @w_oficina)
      begin
         insert into ca_errores_ope_masivas
         values ('El oficial con código ' + convert(varchar, @w_cod_asesor) + ' no pertenece a la oficina ' + convert(varchar, @w_oficina), @s_user)
         
         if @@error != 0 
         begin
            /* Error en insercion */
            select @w_error = 708154
            
            close cur_registros_masivos
            deallocate cur_registros_masivos
            
            goto ERROR
         end
      end
         
     
      fetch next from cur_registros_masivos into
      @w_anio, @w_oficina, @w_cod_asesor, @w_usuario
   end --end while
   
   close cur_registros_masivos
   deallocate cur_registros_masivos
   
   select @w_total_errores = count(1)
   from ca_errores_ope_masivas
   where eom_usuario = @s_user
   
   select @o_cant_errores = @w_total_errores
   
   if @w_total_errores > 0
   begin
      delete from ca_incentivos_metas_tmp
      where imt_usuario_login = @s_user
   
      if @@error != 0 
      begin
         /* Error en eliminacion tabla ca_incentivos_metas_tmp */
         select @w_error = 707080
         goto ERROR
      end
   end
   
   if @i_externo = 'S'
      commit tran
end

/* Consulta de errores de validaciones en carga y/o actualización masiva */
if @i_operacion = 'E'
begin
   select distinct
      'ERRORES' = eom_error 
   from ca_errores_ope_masivas
   where eom_usuario = @s_user
   
   if @@error != 0 
   begin
      /* Error en consulta de tabla ca_errores_ope_masivas */
      select @w_error = 725197
      goto ERROR
   end
end

/* Paso a tabla definitiva de metas de incentivos */
if @i_operacion = 'P'
begin

   if @i_ope_masiva = 'CM'  --Carga Masiva
   begin
      if @i_externo = 'S'
         begin tran
   
      delete from ca_incentivos_metas
      where im_anio = @i_anio
      
      declare cur_paso_definitivas_carga cursor for
      select distinct imt_anio, imt_oficina, imt_cod_asesor, imt_nombre_asesor, imt_usuario_login
      from ca_incentivos_metas_tmp
      where imt_usuario_login = @s_user
      
      open cur_paso_definitivas_carga
   
      fetch next from cur_paso_definitivas_carga into
      @w_anio, @w_oficina, @w_cod_asesor, @w_nombre_asesor, @w_usuario
      
      while (@@fetch_status = 0)
      begin
      
         select @w_count = 1
      
         while @w_count <= 12
         begin
         
            insert into ca_incentivos_metas 
            select  imt_anio, imt_oficina, imt_cod_asesor, imt_mes, imt_nombre_asesor, imt_monto_proyectado
            from ca_incentivos_metas_tmp
            where imt_anio          = @w_anio
            and   imt_oficina       = @w_oficina
            and   imt_cod_asesor    = @w_cod_asesor
            and   imt_mes           = @w_count
            and   imt_usuario_login = @w_usuario
            
            if @@error != 0 
            begin
               /* Error al insertar registro de incentivos en tabla definitiva */
               select @w_error = 725191
               
               close cur_paso_definitivas_carga
               deallocate cur_paso_definitivas_carga
               
               goto ERROR
            end 
         
            exec @w_error  = sp_tran_servicio
            @s_user      = @s_user,
            @s_date      = @s_date,
            @s_ofi       = @s_ofi,
            @s_term      = @s_term,
            @i_tabla     = 'ca_incentivos_metas',
            @i_clave1    = @w_anio,
            @i_clave2    = @w_oficina,
            @i_clave3    = @w_cod_asesor,
            @i_clave4    = @w_count,
            @i_clave5    = @i_observacion,
            @i_clave6    = 'I',   --Acción: Inserción registro
            @i_clave7    = 'M'    --Opción: Carga Masiva
         
            if @w_error != 0 
            begin
               close cur_paso_definitivas_carga
               deallocate cur_paso_definitivas_carga
               
               goto ERROR
            end
         
            select @w_count = @w_count + 1    
         end --End while interno
         
         
         fetch next from cur_paso_definitivas_carga into
         @w_anio, @w_oficina, @w_cod_asesor, @w_nombre_asesor, @w_usuario
         
      end --end while
      
      close cur_paso_definitivas_carga
      deallocate cur_paso_definitivas_carga
      
      if @i_externo = 'S'
         commit tran
         
      delete from ca_incentivos_metas_tmp
      where imt_usuario_login = @s_user
   
      if @@error != 0 
      begin
         /* Error en eliminacion tabla ca_incentivos_metas_tmp */
         select @w_error = 707080
         goto ERROR
      end
      
   end

   if @i_ope_masiva = 'AM'  --Actualización Masiva
   begin
      select @w_anio_fecproc = year(@w_fecha_proceso)
      select @w_mes_fecproc = month(@w_fecha_proceso)
      
      if @w_anio_fecproc = @i_anio
         select @w_mes_inicial = @w_mes_fecproc
      else
         select @w_mes_inicial = 1
         
      if @i_externo = 'S'
         begin tran
         
         
      /* Primer cursor que toma los datos de la tabla temporal y los compara contra la tabla definitiva */   
      
      declare cur_paso_definitivas_act_1 cursor for
      select distinct imt_anio, imt_oficina, imt_cod_asesor, imt_nombre_asesor, imt_usuario_login
      from ca_incentivos_metas_tmp
      where imt_usuario_login = @s_user
      
      open cur_paso_definitivas_act_1
   
      fetch next from cur_paso_definitivas_act_1 into
      @w_anio, @w_oficina, @w_cod_asesor, @w_nombre_asesor, @w_usuario
      
      while (@@fetch_status = 0)
      begin
      
         /* Si existe en tablas temporales y no existe en tabla definitiva */
         if not exists(select 1
                       from ca_incentivos_metas
                       where im_anio       = @w_anio
                       and   im_oficina    = @w_oficina
                       and   im_cod_asesor = @w_cod_asesor)
         begin
            select @w_count = 1
      
            while @w_count <= 12
            begin
               
               if @w_count < @w_mes_inicial
               begin
                  select @w_monto = 0
               end
               else /* El mes del @w_count es mayor o igual al mes en curso  */
               begin
                  select @w_monto = imt_monto_proyectado
                  from ca_incentivos_metas_tmp
                  where imt_anio          = @w_anio
                  and   imt_oficina       = @w_oficina
                  and   imt_cod_asesor    = @w_cod_asesor
                  and   imt_mes           = @w_count
                  and   imt_usuario_login = @w_usuario
               end
               
               insert into ca_incentivos_metas (
                  im_anio,    im_oficina,         im_cod_asesor, 
                  im_mes,     im_nombre_asesor,   im_monto_proyectado)
               values (
                  @w_anio,    @w_oficina,         @w_cod_asesor,
                  @w_count,   @w_nombre_asesor,   @w_monto)
                   
               if @@error != 0 
               begin
                  /* Error al insertar registro de incentivos en tabla definitiva */
                  select @w_error = 725191
                  
                  close cur_paso_definitivas_act_1
                  deallocate cur_paso_definitivas_act_1
                  
                  goto ERROR
               end 
               
               exec @w_error  = sp_tran_servicio
               @s_user      = @s_user,
               @s_date      = @s_date,
               @s_ofi       = @s_ofi,
               @s_term      = @s_term,
               @i_tabla     = 'ca_incentivos_metas',
               @i_clave1    = @w_anio,
               @i_clave2    = @w_oficina,
               @i_clave3    = @w_cod_asesor,
               @i_clave4    = @w_count,  --Mes
               @i_clave5    = @i_observacion,
               @i_clave6    = 'I',   --Acción: Inserción registro
               @i_clave7    = 'U'    --Opción: Actualización masiva
               
               
               if @w_error != 0 
               begin
                  close cur_paso_definitivas_act_1
                  deallocate cur_paso_definitivas_act_1
                  
                  goto ERROR
               end
               
               select @w_count = @w_count + 1
            end --End while interno
            
            goto NEXT_LINE_CURSOR
         end
            
            
         /* Si existe en temporales y en tabla definitiva */
         if exists(select 1
                   from ca_incentivos_metas
                   where im_anio       = @w_anio
                   and   im_oficina    = @w_oficina
                   and   im_cod_asesor = @w_cod_asesor)
         begin
            select @w_count = @w_mes_inicial
      
            while @w_count <= 12
            begin
               
               update ca_incentivos_metas
               set im_monto_proyectado = imt_monto_proyectado
               from ca_incentivos_metas_tmp
               where imt_anio          = im_anio
               and   imt_anio          = @w_anio
               and   imt_oficina       = im_oficina
               and   imt_oficina       = @w_oficina
               and   imt_cod_asesor    = im_cod_asesor
               and   imt_cod_asesor    = @w_cod_asesor
               and   imt_mes           = im_mes
               and   imt_mes           = @w_count
               and   imt_usuario_login = @w_usuario
               
               if @@error != 0 
               begin
                  /* Error. No se actualizo el registro de incentivos */
                  select @w_error = 725193
                  
                  close cur_paso_definitivas_act_1
                  deallocate cur_paso_definitivas_act_1
                  
                  goto ERROR
               end
               
               exec @w_error  = sp_tran_servicio
               @s_user      = @s_user,
               @s_date      = @s_date,
               @s_ofi       = @s_ofi,
               @s_term      = @s_term,
               @i_tabla     = 'ca_incentivos_metas',
               @i_clave1    = @w_anio,
               @i_clave2    = @w_oficina,
               @i_clave3    = @w_cod_asesor,
               @i_clave4    = @w_count,  --Mes
               @i_clave5    = @i_observacion,
               @i_clave6    = 'U',   --Acción: Actualización registro
               @i_clave7    = 'U'    --Opción: Actualización masiva
               
               
               if @w_error != 0 
               begin
                  close cur_paso_definitivas_act_1
                  deallocate cur_paso_definitivas_act_1
                  
                  goto ERROR
               end
               
               select @w_count = @w_count + 1
            end  -- End While interno
         end
         
         NEXT_LINE_CURSOR: 
         fetch next from cur_paso_definitivas_act_1 into
         @w_anio, @w_oficina, @w_cod_asesor, @w_nombre_asesor, @w_usuario
      end --End while externo
      
      close cur_paso_definitivas_act_1
      deallocate cur_paso_definitivas_act_1
      
      
      /* Segundo cursor que toma los datos de la tabla definitiva para validar los registros que no están en la temporal */
          
      declare cur_paso_definitivas_act_2 cursor for
      select distinct im_anio, im_oficina, im_cod_asesor, im_nombre_asesor
      from ca_incentivos_metas
      where im_anio = @i_anio
      
      open cur_paso_definitivas_act_2
   
      fetch next from cur_paso_definitivas_act_2 into
      @w_anio, @w_oficina, @w_cod_asesor, @w_nombre_asesor
      
      while (@@fetch_status = 0)
      begin
         /* Si existe en tabla definitiva y no existe en temporales, se coloca en 0 los saldos desde el mes en curso en adelante */
         if not exists(select 1
                       from ca_incentivos_metas_tmp
                       where imt_anio          = @w_anio
                       and   imt_oficina       = @w_oficina
                       and   imt_cod_asesor    = @w_cod_asesor
                       and   imt_usuario_login = @s_user)
         begin
            select @w_count = @w_mes_inicial
      
            while @w_count <= 12
            begin
               update ca_incentivos_metas
               set im_monto_proyectado = 0
               where im_anio          = @w_anio
               and   im_oficina       = @w_oficina
               and   im_cod_asesor    = @w_cod_asesor
               and   im_mes           = @w_count
               
               if @@error != 0 
               begin
                  /* Error. No se actualizo el registro de incentivos */
                  select @w_error = 725193
                  
                  close cur_paso_definitivas_act_2
                  deallocate cur_paso_definitivas_act_2
                  
                  goto ERROR
               end
               
               exec @w_error  = sp_tran_servicio
               @s_user      = @s_user,
               @s_date      = @s_date,
               @s_ofi       = @s_ofi,
               @s_term      = @s_term,
               @i_tabla     = 'ca_incentivos_metas',
               @i_clave1    = @w_anio,
               @i_clave2    = @w_oficina,
               @i_clave3    = @w_cod_asesor,
               @i_clave4    = @w_count,  --Mes
               @i_clave5    = @i_observacion,
               @i_clave6    = 'U',   --Acción: Actualización registro
               @i_clave7    = 'U'    --Opción: Actualización masiva
               
               
               if @w_error != 0 
               begin
                  close cur_paso_definitivas_act_2
                  deallocate cur_paso_definitivas_act_2
                  
                  goto ERROR
               end
               
               select @w_count = @w_count + 1
            end -- End while interno
         end
         
         fetch next from cur_paso_definitivas_act_2 into
         @w_anio, @w_oficina, @w_cod_asesor, @w_nombre_asesor
      end -- End while cursor
      
      close cur_paso_definitivas_act_2
      deallocate cur_paso_definitivas_act_2
      
      
      if @i_externo = 'S'
         commit tran
         
      delete from ca_incentivos_metas_tmp
      where imt_usuario_login = @s_user
   
      if @@error != 0 
      begin
         /* Error en eliminacion tabla ca_incentivos_metas_tmp */
         select @w_error = 707080
         goto ERROR
      end
   end
end

return 0

ERROR:
if @i_externo = 'S' 
rollback tran

if exists(select 1 
          from ca_incentivos_metas_tmp
          where imt_usuario_login = @s_user)
begin
   delete from ca_incentivos_metas_tmp
   where imt_usuario_login = @s_user
end

exec cobis..sp_cerror
@t_debug = 'N',
@t_file = null,
@t_from = 'sp_metas_incentivos',
@i_num  = @w_error

return @w_error

go
