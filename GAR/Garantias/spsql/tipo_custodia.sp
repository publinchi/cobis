/****************************************************************/
/* ARCHIVO:              tipo_custodia.sp                       */
/* Stored procedure:	 sp_tipo_custodia	          	        */
/* BASE DE DATOS:        cob_custodia 					        */
/* PRODUCTO:             GARANTIAS              	            */
/****************************************************************/
/*                         IMPORTANTE                           */
/* Esta aplicacion es parte de los paquetes bancarios propiedad */
/* de MACOSA S.A.						                        */
/* Su uso no  autorizado queda  expresamente prohibido asi como */
/* cualquier  alteracion  o agregado  hecho por  alguno  de sus */
/* usuarios sin el debido consentimiento por escrito de MACOSA. */
/* Este programa esta protegido por la ley de derechos de autor */
/* y por las  convenciones  internacionales de  propiedad inte- */
/* lectual.  Su uso no  autorizado dara  derecho a  MACOSA para */
/* obtener  ordenes de  secuestro o retencion y  para perseguir */
/* penalmente a los autores de cualquier infraccion.            */
/****************************************************************/
/*                      MODIFICACIONES                          */
/* FECHA               AUTOR                         RAZON      */
/* 28/Mar/2019       Luis  Ramirez  	        Emision Inicial */
/* 11/Feb/2021       Kevin Rodríguez    Obtener Param Gar Person*/
/****************************************************************/

USE cob_custodia
go

IF OBJECT_ID('dbo.sp_tipo_custodia') IS NOT NULL
    DROP PROCEDURE dbo.sp_tipo_custodia
go
create proc dbo.sp_tipo_custodia (
   @s_ssn                int      = null,
   @s_date               datetime = null,
   @s_user               login    = null,
   @s_term               descripcion = null,
   @s_corr               char(1)  = null,
   @s_ssn_corr           int      = null,
   @s_ofi                smallint  = null,
   @t_rty                char(1)  = null,
   @t_trn                smallint = null,
   @t_debug              char(1)  = 'N',
   @t_file               varchar(14) = null,
   @t_from               varchar(30) = null,
   @i_operacion          char(1)  = null,
   @i_modo               smallint = null,
   @i_tipo               descripcion  = null,
   @i_tipo_superior      descripcion  = null,
   @i_descripcion        varchar(255)  = null,
   @i_periodicidad       catalogo  = null,
   @i_param1             descripcion = null,
   @i_filial		 tinyint = null,
   @i_cuenta		 char(20) = null,
   @i_contabilizar       char(1)  = null,
   @i_porcentaje         money = null,
   @i_adecuada           char(1) = null
)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_tipo               descripcion,
   @w_tipo_superior      descripcion,
   @w_descripcion        varchar(255),
   @w_periodicidad       catalogo,
   @w_des_tiposup        descripcion,
   @w_des_periodicidad   descripcion,
   @w_contabilizar       char(1),
   @w_porcentaje         float,
   @w_valor              tinyint,
   @w_adecuada           char(1),
   @w_msg                varchar(255),
   @w_porcentaje_dep     float

select @w_today = convert(varchar(10),getdate(),101)
select @w_sp_name = 'sp_tipo_custodia'

/***********************************************************/
/* Codigos de Transacciones                                */

if (@t_trn <> 19120 and @i_operacion = 'I') or
   (@t_trn <> 19121 and @i_operacion = 'U') or
   (@t_trn <> 19122 and @i_operacion = 'D') or
   (@t_trn <> 19123 and @i_operacion = 'V') or
   (@t_trn <> 19124 and @i_operacion = 'S') or
   (@t_trn <> 19125 and @i_operacion = 'Q') or
   (@t_trn <> 19126 and @i_operacion = 'A') or
   (@t_trn <> 19127 and @i_operacion = 'H') or
   (@t_trn <> 19128 and @i_operacion = 'B')
begin
/* tipo de transaccion no corresponde */
    exec cobis..sp_cerror
    @t_debug = @t_debug,

    @t_file  = @t_file, 
    @t_from  = @w_sp_name,
    @i_num   = 1901006
    return 1 
end

/* Chequeo de Existencias */
/**************************/
if @i_operacion <> 'S' and @i_operacion <> 'A' and @i_operacion <> 'H'
begin
    select 
         @w_tipo = tc_tipo,
         @w_tipo_superior = tc_tipo_superior,
         @w_descripcion   = tc_descripcion,
         @w_periodicidad  = tc_periodicidad,
         @w_contabilizar  = tc_contabilizar,
         @w_porcentaje    = tc_porcen_cobertura,
         @w_adecuada      = tc_adecuada,
         @w_porcentaje_dep= tc_porcentaje
    from cob_custodia..cu_tipo_custodia
    where 
         tc_tipo = @i_tipo

    if @@rowcount > 0
       select @w_existe = 1
    else
       select @w_existe = 0
end

/* VALIDACION DE CAMPOS NULOS */
/******************************/
if @i_operacion = 'I' or @i_operacion = 'U'
begin
    if @i_tipo = NULL 
    begin
    /* Campos NOT NULL con valores nulos */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1901001
        return 1 
    end

    if @i_tipo_superior <> NULL
       if exists (select * from cu_tipo_custodia  
                   where tc_tipo = @i_tipo_superior)
       begin
          select @w_valor = 1
       end
       else
       begin
       /* No existe codigo Superior */
          exec cobis..sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file, 
          @t_from  = @w_sp_name,
          @i_num   = 1901014
          return 1 
       end    
end

/* Insercion del registro */
/**************************/

if @i_operacion = 'I'
begin
    if @w_existe = 1
    begin
    /* Registro ya existe */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1901002
        return 1 
    end

    --DAR 26ENE2011
    /*if not exists(select 1 from cob_credito..cr_corresp_sib
                   where tabla = 'T42'
                     and codigo = @i_tipo)
    begin
    
        select @w_msg = 'Tipo Garantia [' + @i_tipo + '] debe crearse primero en tabla T42 del Adm.de.Credito (Parametros de la Sib)' + char(10) + char(13)
        select @w_msg = @w_msg + 'Comuniquese con Adm.de.Credito'
    
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1901002,
        @i_msg   = @w_msg
        return 1 
    end*/

    select @w_porcentaje_dep = dtc_porcentaje
      from cob_custodia..cu_dtipo_custodia
     where dtc_tipo = @i_tipo
       and dtc_anio = 1
    
    begin tran
         insert into cu_tipo_custodia(
              tc_tipo,
              tc_tipo_superior,
              tc_descripcion,
              tc_periodicidad,
              tc_contabilizar,
              tc_porcen_cobertura,
              tc_adecuada,
              tc_porcentaje)
         values (
              @i_tipo,
              @i_tipo_superior,
              @i_descripcion,
              @i_periodicidad,
              @i_contabilizar,
              @i_porcentaje,
              @i_adecuada,
              @w_porcentaje_dep)

         if @@error <> 0 
         begin
         /* Error en insercion de registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903001
             return 1 
         end

         /* Transaccion de Servicio */
         /***************************/

         insert into ts_tipo_custodia
         values (@s_ssn,@t_trn,'N',@s_date,@s_user,@s_term,@s_ofi,'cu_tipo_custodia',
         @i_tipo,
         @i_tipo_superior,
         @i_descripcion,
         @i_periodicidad,
         @i_contabilizar)

         if @@error <> 0 
         begin
         /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903003
             return 1 
         end
    commit tran 
    return 0
end

/* Actualizacion del registro */
/******************************/

if @i_operacion = 'U'
begin

    if @w_existe = 0
    begin
    /* Registro a actualizar no existe */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1905002
        return 1 
    end

    select @w_porcentaje_dep = dtc_porcentaje
      from cob_custodia..cu_dtipo_custodia
     where dtc_tipo = @i_tipo
       and dtc_anio = 1

    begin tran
         update cob_custodia..cu_tipo_custodia
         set 
              tc_tipo_superior = @i_tipo_superior,
              tc_descripcion   = @i_descripcion,
              tc_periodicidad  = @i_periodicidad,
              tc_contabilizar  = @i_contabilizar,
              tc_porcentaje    = @w_porcentaje_dep,
              tc_adecuada      = @i_adecuada,
              tc_porcen_cobertura = @i_porcentaje
    where 
         tc_tipo = @i_tipo

         if @@error <> 0 
         begin
         /* Error en actualizacion de registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1905001
             return 1 
         end

         /* Transaccion de Servicio */
         /***************************/

         insert into ts_tipo_custodia
         values (@s_ssn,@t_trn,'P',@s_date,@s_user,@s_term,@s_ofi,'cu_tipo_custodia',
         @w_tipo,
         @w_tipo_superior,
         @w_descripcion,
         @w_periodicidad,
         @w_contabilizar)

         if @@error <> 0 
         begin
         /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903003
             return 1 
         end

            

         /* Transaccion de Servicio */

         /***************************/

         insert into ts_tipo_custodia
         values (@s_ssn,@t_trn,'A',@s_date,@s_user,@s_term,@s_ofi,'cu_tipo_custodia',
         @i_tipo,
         @i_tipo_superior,
         @i_descripcion,
         @i_periodicidad,
         @i_contabilizar)

         if @@error <> 0 
         begin
         /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903003
             return 1 
         end
    commit tran
    return 0
end

/* Eliminacion de registros */
/****************************/

if @i_operacion = 'D'
begin
    if @w_existe = 0
    begin
    /* Registro a eliminar no existe */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1907002
        return 1 
    end

    if exists (select * from cu_tipo_custodia
                  where tc_tipo_superior = @i_tipo)
    begin
    /* Existen tipos Hijos que no han sido eliminados */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1907003
        return 1 
    end

    if exists (select * from cu_custodia
                  where cu_tipo = @i_tipo)
    begin
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1907004
        return 1 
    end

/***** Integridad Referencial *****/
/*****                        *****/

    
    begin tran
         delete cob_custodia..cu_tipo_custodia
    where 
         tc_tipo = @i_tipo

         delete cu_item            
         where it_tipo_custodia = @i_tipo

                          
         if @@error <> 0
         begin
         /*Error en eliminacion de registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1907001


             return 1 
         end


         /* Transaccion de Servicio */
         /***************************/

         insert into ts_tipo_custodia
         values (@s_ssn,@t_trn,'B',@s_date,@s_user,@s_term,@s_ofi,'cu_tipo_custodia',
         @w_tipo,
         @w_tipo_superior,
         @w_descripcion,
         @w_periodicidad,
         @w_contabilizar)

         if @@error <> 0 
         begin
         /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903003
             return 1 
         end
    commit tran
    return 0
end

/* Consulta opcion VALUE */
/*************************/

if @i_operacion = 'V'
begin
   select tc_descripcion from cu_tipo_custodia where tc_tipo = @i_tipo
         if @@rowcount = 0 
         begin
         /* No existe el registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1901005
             return 1 
         end
end 

/* Consulta opcion QUERY */
/*************************/

if @i_operacion = 'Q'
begin
    if @w_existe = 1
    begin    
         select @w_des_tiposup = tc_descripcion
           from cu_tipo_custodia
          where tc_tipo = @w_tipo_superior
 
	 select @w_des_periodicidad = A.valor
         from cobis..cl_catalogo A,cobis..cl_tabla B
         where B.codigo = A.tabla
             and B.tabla = 'cu_des_periodicidad'
             and A.codigo = @w_periodicidad
         select
              @w_tipo,
              @w_tipo_superior,
              @w_des_tiposup,               
              @w_descripcion,
              @w_periodicidad,
              @w_des_periodicidad,
              @w_contabilizar, 
              @w_porcentaje,
              @w_adecuada,
              @s_ofi,
              @w_porcentaje_dep
         return 0
    end    
    else
      return 1 
end


 /* Todos los datos de la tabla */
 /*******************************/
if @i_operacion = 'A'
begin
      set rowcount 20
      if @i_tipo is null
         select @i_tipo = @i_param1
      if @i_modo = 0 
      begin
         select 'TIPO' = tc_tipo, 'DESCRIPCION' = substring(tc_descripcion,1,25)
           from cu_tipo_custodia WITH(index (cu_tipo_custodia_Key)) 
         if @@rowcount = 0
         begin 
           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file, 
           @t_from  = @w_sp_name,
           @i_num   = 1901003
           return 1 
         end
      end
      else 
      begin
         select tc_tipo,tc_descripcion 
         from cu_tipo_custodia WITH(index (cu_tipo_custodia_Key))  
         where tc_tipo > @i_tipo  
         order by tc_tipo
         if @@rowcount = 0
         begin
           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file, 
           @t_from  = @w_sp_name,
           @i_num   = 1901004
           return 1 
         end
      end
end

if @i_operacion = 'S'
begin
      set rowcount 20
      if @i_modo = 0 
      begin
         select 'TIPO' = tc_tipo, 
				'TIPO SUPERIOR' = tc_tipo_superior
          from cu_tipo_custodia WITH(index (cu_tipo_custodia_Key))  
          where (tc_tipo like @i_tipo or @i_tipo is null)
           and (tc_tipo_superior = @i_tipo_superior or @i_tipo_superior is null)
          order by tc_tipo
       	if @@rowcount = 0
        begin
           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file, 
           @t_from  = @w_sp_name,
           @i_num   = 1901003
           return 1 
        end    
      end
      else 
      begin
         select 'TIPO' = tc_tipo, 'TIPO SUPERIOR' = tc_tipo_superior
           from cu_tipo_custodia WITH(index (cu_tipo_custodia_Key)) 
	 where tc_tipo > @i_tipo  
           and (tc_tipo like @i_tipo or @i_tipo is null)
           and (tc_tipo_superior = @i_tipo_superior or @i_tipo_superior is null)
           order by tc_tipo
         if @@rowcount = 0
         begin
           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file, 
           @t_from  = @w_sp_name,
           @i_num   = 1901004
           return 1 
         end
      end
end


if @i_operacion = 'H'
begin
    if @i_modo = 0 
    begin
		if @i_tipo is null
		begin
			select 'TIPO' = substring(tc_tipo,1,20), 
				   'DESCRIPCION' = tc_descripcion
			from cu_tipo_custodia WITH(index( cu_tipo_custodia_Key))    
			where tc_tipo_superior is null
			order by tc_tipo
			if @@rowcount = 0
			begin
			   exec cobis..sp_cerror
			   @t_debug = @t_debug,
			   @t_file  = @t_file, 
			   @t_from  = @w_sp_name,
			   @i_num   = 1901003
			   return 1 
			end
		end
		else
		begin
			select 'TIPO' = substring(tc_tipo,1,20), 
				   'DESCRIPCION' = tc_descripcion
			from cu_tipo_custodia WITH(index( cu_tipo_custodia_Key))    
			where tc_tipo_superior = @i_tipo
			order by tc_tipo
			if @@rowcount = 0
			begin
				exec cobis..sp_cerror
				@t_debug = @t_debug,
				@t_file  = @t_file, 
				@t_from  = @w_sp_name,
				@i_num   = 1901003
				return 1 
			end
		end
	end
    else 
    begin
        select 'TIPO' = substring(tc_tipo,1,20), 'DESCRIPCION' = tc_descripcion
        from cu_tipo_custodia WITH(index (cu_tipo_custodia_Key))
	    where tc_tipo > @i_tipo 
		and (tc_tipo_superior = @i_tipo)
        order by tc_tipo
        if @@rowcount = 0
        begin
            exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file, 
            @t_from  = @w_sp_name,
            @i_num   = 1901004
            return 1 
        end
    end
	print 'pendiente'
end

if @i_operacion = 'B'   -- Cuenta Contable
begin
   select cu_nombre
     from cob_conta..cb_cuenta
     where cu_empresa     = @i_filial
       and cu_cuenta      = @i_cuenta
       and cu_movimiento  = 'S'
         if @@rowcount = 0
         begin
           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file, 
           @t_from  = @w_sp_name,
           @i_num   = 1901009
           return 1 
         end
		 
		
end
if @i_operacion = 'N'   
begin
     if @i_modo = 0
     begin
         select 'tc_tipo'       =  tc_tipo,  
                'tc_descripcion'=  tc_descripcion
         from cob_custodia..cu_tipo_custodia 
         where tc_tipo not in (select tc_tipo
                               from cob_custodia..cu_tipo_custodia
                               where tc_tipo in (select tc_tipo_superior 
                                                 from  cob_custodia..cu_tipo_custodia))
         if @@rowcount = 0
         begin 
             exec cobis..sp_cerror
              @t_debug = @t_debug,
              @t_file  = @t_file, 
              @t_from  = @w_sp_name,
              @i_num   = 1901003
              return 1 
         end
     end
	 
	 -- KDR Parámetro General de Garantías Personales (Para front-End)
	 if @i_modo = 1
	 begin
	    select 'Tipo' = pa_char  from cobis..cl_parametro
        where pa_nemonico = 'GARGPE'
        and pa_producto = 'GAR'

        if @@rowcount = 0
        begin
		   exec cobis..sp_cerror
              @t_debug = @t_debug,
              @t_file  = @t_file, 
              @t_from  = @w_sp_name,
              @i_num   = 1909033
              return 1   
		end
	 end
	 return 0
end

GO