/************************************************************************/
/*      Archivo:                at_relacion.sp                          */
/*      Stored procedure:       sp_at_relacion                          */
/*      Base de datos:          cobis                                   */
/*      Producto:               CLIENTES                                */
/*      Disenado por:           Sandra Ortiz/Mauricio Bayas             */
/*      Fecha de escritura:     06-May-94                               */
/************************************************************************/
/*                            IMPORTANTE                                */
/*    Este programa es parte de los paquetes bancarios propiedad de     */
/*    "MACOSA", representantes  exclusivos  para el  Ecuador  de la     */
/*    "NCR CORPORATION".                                                */
/*    Su  uso no autorizado  queda expresamente  prohibido asi como     */
/*    cualquier   alteracion  o  agregado  hecho por  alguno de sus     */
/*    usuarios   sin el debido  consentimiento  por  escrito  de la     */
/*    Presidencia Ejecutiva de MACOSA o su representante.               */
/*                             PROPOSITO                                */
/*    Este programa procesa las transacciones del stored procedure      */
/*         Insercion de         cl_at_relacion                          */
/*         Modificacion de      cl_at_relacion                          */
/*         Borrado de           cl_at_relacion                          */
/*         Busqueda de          cl_at_relacion                          */
/*                           MODIFICACIONES                             */
/*    FECHA           AUTOR            RAZON                            */
/* 13/04/2021         ACA       Nueva columna descripcion tipo de dato  */
/************************************************************************/
use cobis
go
set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO
if exists (select * from sysobjects where name = 'sp_at_relacion')
   drop proc sp_at_relacion
go
create proc sp_at_relacion ( 
       	@s_ssn		        int = null, 
       	@s_user		        login = null, 
       	@s_term		        varchar(30) = null, 
       	@s_date		        datetime = null, 
       	@s_srv		        varchar(30) = null, 
       	@s_lsrv		        varchar(30) = null, 
       	@s_ofi		        smallint = null, 
	    @s_rol		        smallint = NULL, 
	    @s_org_err	        char(1) = NULL, 
	    @s_error	        int = NULL, 
	    @s_sev		        tinyint = NULL, 
	    @s_msg		        descripcion = NULL, 
	    @s_org		        char(1) = NULL, 
        @s_culture          varchar(10)   = 'NEUTRAL',   		
       	@t_debug	        char(1) = 'N', 
        @t_show_version     bit           = 0,     -- mostrar la version del programa		
       	@t_file		        varchar(10) = null, 
       	@t_from		        varchar(32) = null, 
       	@t_trn		        int = null, 
       	@i_operacion        char (1), 
       	@i_tipo  	        char (1) = NULL, 
       	@i_relacion 	    smallint = NULL, 
       	@i_atributo 	    tinyint = NULL, 
       	@i_descripcion      varchar (64) = NULL, 
       	@i_tdato 	        varchar (30) = NULL,
		@i_bdatos 	        varchar (30) = NULL,
		@i_sprocedure 	    varchar (50) = NULL,
		@i_catalogo 	    varchar (30) = NULL,
		@i_modo		        tinyint = null
	 
) 
as 
declare 
   @w_return  int, 
   @w_sp_name varchar (32), 
   @w_seqnos  int, 
   @v_relacion int, 
   @w_relacion int, 
   @v_atributo tinyint, 
   @w_atributo tinyint, 
   @v_descripcion varchar (64), 
   @w_descripcion varchar (64), 
   @v_tdato varchar (30), 
   @w_tdato varchar (30),
   @w_sp_msg          varchar(132)   
    
select @w_sp_name      = 'sp_at_relacion', 
       @w_sp_msg       = ''

/* VERSIONAMIENTO */
if @t_show_version = 1 begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end

---- EJECUTAR SP DE LA CULTURA ---------------------------------------  
exec cobis..sp_ad_establece_cultura
        @o_culture = @s_culture out
		

/* ** Insert ** */ 
if @i_operacion = 'I' 
begin 
if @t_trn = 172129 
begin 
   /* Verificar que exista la relacion */ 
   if not exists ( select * 
                     from cl_relacion  
                    where re_relacion = @i_relacion) 
      begin 
          /* No existe la relacion */  
          exec cobis..sp_cerror  
                @t_debug= @t_debug, 
                @t_file = @t_file, 
                @t_from = @w_sp_name, 
                @s_culture = @s_culture,                
                @i_num  = 1720401   
           return 1 
      end 
    
   begin tran 
      /* Encontrar un nuevo secuencial en atributos */ 
   
	 select @w_atributo = max(ar_atributo) + 1 
       from cl_at_relacion 
      where ar_relacion = @i_relacion 
      if @@rowcount != 1 
      begin 
          /* Error al insertar el secuencial de atributos */ 
          exec cobis..sp_cerror  
                @t_debug= @t_debug, 
                @t_file = @t_file, 
                @t_from = @w_sp_name,
                @s_culture = @s_culture, 
                @i_num  = 1720402   
           return 1 
      end 
  
      /* Actualizar secuencial de atributos */ 
      update cl_relacion 
         set re_atributo = re_atributo + 1 
       where re_relacion = @i_relacion 
      if @@error != 0  
      begin 
          /* Error al actualizar el secuencial de atributos */ 
          exec cobis..sp_cerror  
                @t_debug= @t_debug, 
                @t_file = @t_file, 
                @t_from = @w_sp_name, 
                @s_culture = @s_culture,
                @i_num  = 1720402   
           return 1 
      end 
      /* Insertar los datos de entrada */ 
      insert into cl_at_relacion ( 
                  ar_relacion, ar_atributo, ar_descripcion, ar_tdato, ar_catalogo, ar_bdatos, ar_sprocedure)  
          values (@i_relacion, isnull(@w_atributo,1), @i_descripcion, @i_tdato, @i_catalogo, @i_bdatos, @i_sprocedure) 
      /* Si no se puede insertar error */ 
      if @@error != 0 
      begin 
         /* Error al insertar atributo de relacion */ 
          exec cobis..sp_cerror  
                @t_debug= @t_debug, 
                @t_file = @t_file, 
                @t_from = @w_sp_name,
                @s_culture = @s_culture, 
                @i_num  = 1720403   
           return 1 
      end 
     /* transaccion servicio - at_relacion */ 
     /* insert into ts_at_relacion (secuencial, tipo_transaccion, clase, fecha, 
                usuario, terminal, srv, lsrv, 
                relacion, atributo, descripcion, tdato 
                ) 
        values (@s_ssn, @t_trn, 'N', @s_date, 
                @s_user, @s_term, @s_srv, @s_lsrv, 
                @i_relacion, @w_atributo, @i_descripcion, @i_tdato 
)*/  
     /* Si no se puede insertar , error */ 
     /*if @@error != 0 
     begin */ 
          /* 'Error en creacion de transaccion de servicios'*/ 
     /*     exec sp_cerror 
                @t_debug        = @t_debug, 
                @t_file         = @t_file, 
                @t_from         = @w_sp_name, 
                @i_num          = 103005  
          return 1 
     end */ 
   commit tran 
   select @w_atributo 
   return 0 
end 
else 
begin 
	exec sp_cerror 
	   @t_debug	 = @t_debug, 
	   @t_file	 = @t_file, 
	   @t_from	 = @w_sp_name,
	   @s_culture = @s_culture, 
	   @i_num	 = 1720070 
	   /*  'No corresponde codigo de transaccion' */ 
	return 1 
end 
end 
/* ** Update ** */ 
if @i_operacion = 'U' 
begin 
if @t_trn = 172130 
begin 
   /* seleccionar los datos anteriores */ 
   select @w_descripcion = ar_descripcion 
     from cl_at_relacion 
    where ar_relacion = @i_relacion 
      and ar_atributo = @i_atributo 
   /* Si no existen o existe mas de uno, error */   
  if @@rowcount != 1  
  begin 
        /* No existe atributo de relacion */ 
	exec sp_cerror  
		@t_debug	= @t_debug, 
		@t_file		= @t_file, 
		@t_from		= @w_sp_name, 
		@s_culture  = @s_culture,
		@i_num		= 1720404 
	return 1 
  end 
  /* Guargar los datos antiguos */ 
  select @v_descripcion = @w_descripcion 
  if @w_descripcion = @i_descripcion 
     select @w_descripcion = null, @v_descripcion = null 
  else 
     select @w_descripcion= @i_descripcion 
  
  begin tran 
      
      /* Modificar el atributo con la nueva descripcion */  
      update cl_at_relacion 
         set ar_descripcion = @i_descripcion ,
		     ar_tdato       = @i_tdato,
			 ar_catalogo    = @i_catalogo, 
			 ar_bdatos      = @i_bdatos,
			 ar_sprocedure  = @i_sprocedure
       where ar_relacion = @i_relacion 
         and ar_atributo = @i_atributo 
      if @@error != 0 
      begin 
          /* error al actualizar atributo de relacion */ 
          exec cobis..sp_cerror  
                @t_debug= @t_debug, 
                @t_file = @t_file, 
                @t_from = @w_sp_name,
                @s_culture = @s_culture, 
                @i_num  = 1720405  
           return 1 
      end 
     /* transaccion servicios - at_relacion */ 
   /*  insert into ts_at_relacion (secuencial, tipo_transaccion, clase, fecha, 
                      usuario, terminal, srv, lsrv, 
                      relacion, atributo, descripcion, tdato 
 ) 
        values (@s_ssn, @t_trn, 'P', @s_date, 
                @s_user, @s_term, @s_srv, @s_lsrv, 
                @i_relacion, @i_atributo, @v_descripcion, @v_tdato 
) 
     if @@error != 0 
     begin  */ 
        /* 'Error en creacion de transaccion de servicios'*/ 
   /*     exec sp_cerror 
                @t_debug        = @t_debug, 
                @t_file         = @t_file, 
                @t_from         = @w_sp_name, 
                @i_num          = 103005 
        return 1 
     end 
     insert into ts_at_relacion (secuencial, tipo_transaccion, clase, fecha, 
                      usuario, terminal, srv, lsrv, 
                      relacion, atributo, descripcion, tdato 
) 
        values (@s_ssn, @t_trn, 'A', @s_date, 
                @s_user, @s_term, @s_srv, @s_lsrv, 
                @i_relacion, @i_atributo, @w_descripcion, @w_tdato 
) 
     if @@error != 0 
     begin */ 
        /* 'Error en creacion de transaccion de servicios'*/ 
     /*   exec sp_cerror 
                @t_debug        = @t_debug, 
                @t_file         = @t_file, 
                @t_from         = @w_sp_name, 
                @i_num          = 103005 
        return 1 
     end */ 
   commit tran 
   return 0 
end 
else 
begin 
	exec sp_cerror 
	   @t_debug	 = @t_debug, 
	   @t_file	 = @t_file, 
	   @t_from	 = @w_sp_name,
	   @s_culture = @s_culture, 
	   @i_num	 = 1720070 
	   /*  'No corresponde codigo de transaccion' */ 
	return 1 
end 
end 
/* ** Delete ** */ 
if @i_operacion = 'D' 
begin 
if @t_trn = 172131 
begin 
   /* Verificar que existe el atributo a borrar */ 
   Select @w_descripcion = ar_descripcion, 
          @w_tdato = ar_tdato 
     from cl_at_relacion 
    where ar_relacion = @i_relacion 
      and ar_atributo = @i_atributo 
   if @@rowcount != 1 
      begin 
         /* no existe atributo a borrar */ 
          exec cobis..sp_cerror  
                @t_debug= @t_debug, 
                @t_file = @t_file, 
                @t_from = @w_sp_name, 
                @s_culture = @s_culture,
                @i_num  = 1720404   
           return 1 
      end 
   
   /* chequear si existe referencia en atributos de instancia */ 
   if exists (select * 
              from cl_at_instancia  
              where ai_relacion = @i_relacion 
                and ai_atributo = @i_atributo 
              ) 
      begin 
          /* existe referencia en atributo de instancia */ 
          exec cobis..sp_cerror  
                @t_debug= @t_debug, 
                @t_file = @t_file, 
                @t_from = @w_sp_name,
                @s_culture = @s_culture, 
                @i_num  = 1720406   
           return 1 
      end 
   begin tran 
      /* Disminuir el numero de atributos de una relacion */ 
      Update cl_relacion 
         set re_atributo = re_atributo - 1 
       where re_relacion = @i_relacion 
      if @@error != 0  
      begin 
          /* Error al actualizar el secuencial de atributos */ 
          exec cobis..sp_cerror  
                @t_debug= @t_debug, 
                @t_file = @t_file, 
                @t_from = @w_sp_name,
                @s_culture = @s_culture, 
                @i_num  = 1720402   
           return 1 
      end 
      delete cl_at_relacion 
      where ar_relacion = @i_relacion 
        and ar_atributo = @i_atributo 
      /* si no se puede borrar, error */ 
      if @@error != 0 
      begin 
          exec cobis..sp_cerror  
                @t_debug= @t_debug, 
                @t_file = @t_file, 
                @t_from = @w_sp_name,
                @s_culture = @s_culture, 
                @i_num  = 1720407 
           return 1 
      end 
     /* transaccion servicio - at_relacion */ 
   /*  insert into ts_at_relacion (secuencial, tipo_transaccion, clase, fecha, 
                usuario, terminal, srv, lsrv, 
                relacion, atributo, descripcion, tdato 
) 
        values (@s_ssn, @t_trn, 'N', @s_date, 
                @s_user, @s_term, @s_srv, @s_lsrv, 
                @i_relacion, @i_atributo, @w_descripcion, @w_tdato 
) */ 
     /* Si no se puede insertar , error */ 
     /* if @@error != 0 
     begin 
          exec sp_cerror 
                @t_debug        = @t_debug, 
                @t_file         = @t_file, 
                @t_from         = @w_sp_name, 
                @i_num          = 103005 */ 
            /* 'Error en creacion de transaccion de servicios'*/ 
          /* return 1 
     end */  
   commit tran 
   return 0 
end 
else 
begin 
	exec sp_cerror 
	   @t_debug	 = @t_debug, 
	   @t_file	 = @t_file, 
	   @t_from	 = @w_sp_name, 
	   @s_culture = @s_culture,
	   @i_num	 = 1720070 
	   /*  'No corresponde codigo de transaccion' */ 
	return 1 
end 
end 
/* ** Search** */ 
if @i_operacion = 'S'  
begin 
if @t_trn = 172132 
begin 

    set rowcount 20 
    if @i_modo = 0 
	 
		   select  "Atributo"        =  a.ar_atributo, 
            "Descripcion"        =  convert (char(30), a.ar_descripcion),
				"Tipo de Dato"       =  a.ar_tdato,
				"Desc tipo de dato"  = (select valor 
										      from cobis..cl_catalogo c, cobis..cl_tabla t 
										      where t.tabla = 'cl_tipos_datos' and t.codigo = c.tabla and c.codigo = a.ar_tdato),
			   "Catalogo"           =  a.ar_catalogo,
            "Base D." 	         =  a.ar_bdatos,
			   "Proce." 	         =  a.ar_sprocedure,
				"Relacion."          =  a.ar_relacion
         from cl_at_relacion a
         where ar_relacion = @i_relacion 
		   order  by ar_atributo 
		 
		 
    if @i_modo = 1  
		   select  "Atributo"        =  a.ar_atributo, 
            "Descripcion"        =  convert (char(30), a.ar_descripcion),
				"Tipo de Dato"       =  a.ar_tdato,
				"Desc tipo de dato"  = (select valor 
										      from cobis..cl_catalogo c, cobis..cl_tabla t 
										      where t.tabla = 'cl_tipos_datos' and t.codigo = c.tabla and c.codigo = a.ar_tdato),
			   "Catalogo"           =  a.ar_catalogo,
            "Base D." 	         =  a.ar_bdatos,
			   "Proce." 	         =  a.ar_sprocedure,
				"Relacion."          =  a.ar_relacion
         from cl_at_relacion a
         where ar_relacion = @i_relacion 
		   and 	ar_atributo > @i_atributo 
		  order  by ar_atributo 
		 		 
    set rowcount 0 
    return 0

end 
else 
begin 
	exec sp_cerror 
	   @t_debug	 = @t_debug, 
	   @t_file	 = @t_file, 
	   @t_from	 = @w_sp_name, 
	   @s_culture = @s_culture,
	   @i_num	 = 1720070 
	   /*  'No corresponde codigo de transaccion' */ 
	return 1 
end 
end 
/* ** Query especifico para cada sp ** */ 
if @i_operacion = "Q" 
begin 
if @t_trn = 172133 
begin 
   select  "Descripcion" =  ar_descripcion, 
           "Tipo de Dato" =  ar_tdato 
     from cl_at_relacion 
    where ar_relacion = @i_relacion 
      and ar_atributo = @i_atributo 
    if @@rowcount != 1 
    begin 
          /* No existe atributo de relacion */ 
          exec sp_cerror 
                @t_debug        = @t_debug, 
                @t_file         = @t_file, 
                @t_from         = @w_sp_name,
                @s_culture      = @s_culture, 
                @i_num          = 1720404 
          return 1 
    end   
return 0 
end 
else 
begin 
	exec sp_cerror 
	   @t_debug	 = @t_debug, 
	   @t_file	 = @t_file, 
	   @t_from	 = @w_sp_name, 
       @s_culture = @s_culture,	   
	   @i_num	 = 1720070 
	   /*  'No corresponde codigo de transaccion' */ 
	return 1 
end 
end 
/* ** Help ** */ 
if @i_operacion = "H" 
begin 
if @t_trn = 172134 
begin 
   /* seleccionar todos los atributos */ 
   if @i_tipo = "A" 
      select  "5018" =  ar_atributo, 
              "5019" =  convert (char(30),ar_descripcion), 
              "3072" =  ar_tdato,
			  "Catalogo" 	 =  ar_catalogo,
              "Base D." 	 =  ar_bdatos,
			  "Proce." 		 =  ar_sprocedure
        from cl_at_relacion 
       where ar_relacion = @i_relacion 
   /* seleccionar un atributo dado su codigo */ 
   if @i_tipo = "V" 
   begin 
      select  "2937" =  ar_descripcion, 
              "3072" =  ar_tdato,
			  "Catalogo" 	 =  ar_catalogo,
              "Base D." 	 =  ar_bdatos,
			  "Proce." 		 =  ar_sprocedure
        from cl_at_relacion 
       where ar_relacion = @i_relacion 
         and ar_atributo = @i_atributo 
       if @@rowcount != 1 
       begin 
          /* No existe atributo de relacion */ 
          exec sp_cerror 
                @t_debug        = @t_debug, 
                @t_file         = @t_file, 
                @t_from         = @w_sp_name, 
                @s_culture      = @s_culture,                
                @i_num          = 1720404 
          return 1 
       end   
   end  
return 0 
end 
else 
begin 
	exec sp_cerror 
	   @t_debug	 = @t_debug, 
	   @t_file	 = @t_file, 
	   @t_from	 = @w_sp_name, 
       @s_culture = @s_culture,	   
	   @i_num	 = 1720070 
	   /*  'No corresponde codigo de transaccion' */ 
	return 1 
end 
       
end 
              
go
