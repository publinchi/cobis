/*************************************************************************/
/*   Archivo:              item_custodia.sp                              */
/*   Stored procedure:     sp_item_custodia                              */
/*   Base de datos:        cob_custodia                                  */
/*   Producto:             Garantias                                     */
/*   Disenado por:                                                       */
/*   Fecha de escritura:   Marzo 2019                                    */
/*************************************************************************/
/*                                  IMPORTANTE                           */
/*   Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*   de MACOSA S.A.                                                      */
/*   Su uso no autorizado queda expresamente prohibido asi como          */
/*   cualquier alteracion o agregado hecho por alguno de sus             */
/*   usuarios sin el debido consentimiento por escrito de MACOSA         */
/*   Este programa esta protegido por la ley de derechos de autor        */
/*   y por las  convenciones  internacionales de  propiedad inte-        */
/*   lectual.  Su uso no  autorizado dara  derecho a  MACOSA para        */
/*   obtener  ordenes de  secuestro o retencion y  para perseguir        */
/*   penalmente a los autores de cualquier infraccion.                   */
/*************************************************************************/
/*                                   PROPOSITO                           */
/*    Creacion de objetos de la base. Comprende: tablas, indices,sp      */
/*    tipos de datos, claves primarias y foraneas                        */
/*                                                                       */
/*			                                                             */
/*************************************************************************/
/*                             MODIFICACION                              */
/*    FECHA                   AUTOR                 RAZON                */
/*    Marzo/2019                                      emision inicial    */
/*                                                                       */
/*************************************************************************/
USE cob_custodia
go
IF OBJECT_ID('dbo.sp_item_custodia') IS NOT NULL
    DROP PROCEDURE dbo.sp_item_custodia
go
create proc dbo.sp_item_custodia (
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
   @i_filial             tinyint  = null,
   @i_sucursal           smallint  = null,
   @i_tipo_cust          descripcion  = null,
   @i_custodia           int  = null,
   @i_item               tinyint  = null,
   @i_valor_item         descripcion  = null,
   @i_nombre             descripcion = null,
   @i_secuencial	 smallint = null,
   @i_numerocount        tinyint  = null,
   @i_codigo_externo     varchar(64) = null,
   @i_val_item            char(1) = 'S' --REF:LRC mar.12.2009

)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_error              int, 
   @w_filial             tinyint,
   @w_sucursal           smallint,
   @w_tipo_cust          descripcion,
   @w_custodia           int,
   @w_item               tinyint,
   @w_item_actual        tinyint,
   @w_valor_item         descripcion,
   @w_secuencial  	 smallint,
   @w_numitems    	 tinyint,
   @w_mandatorio  	 char(1),
   @w_codigo_externo  	 varchar(64),
   @w_msg                varchar(100)


select @w_today = convert(varchar(10),getdate(),101)
select @w_sp_name = 'sp_item_custodia'

/***********************************************************/
/* Codigos de Transacciones                                */

if (@t_trn <> 19050 and @i_operacion = 'I') or
   (@t_trn <> 19051 and @i_operacion = 'U') or
   (@t_trn <> 19052 and @i_operacion = 'D') or
   (@t_trn <> 19053 and @i_operacion = 'V') or
   (@t_trn <> 19054 and @i_operacion = 'S') or
   (@t_trn <> 19055 and @i_operacion = 'Q') or
   (@t_trn <> 19056 and @i_operacion = 'A') or
   (@t_trn <> 19057 and @i_operacion = 'C') or
   (@t_trn <> 19056 and @i_operacion = 'T') or
   (@t_trn <> 19054 and @i_operacion = 'X') 
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
if @i_operacion <> 'S' and @i_operacion <> 'A' and @i_operacion <> 'Q' and @i_operacion <> 'D' and @i_operacion <> 'X' and @i_operacion <> 'T'  
begin
    select @w_item       = it_item,
           @w_mandatorio = it_mandatorio
                           from cu_item
                             where it_tipo_custodia = @i_tipo_cust
                               and it_nombre = @i_nombre
    if @@rowcount = 0
    begin
    /* Nombre del item no existe */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1901007
        return 1 
    end
    select 
         @w_filial = ic_filial,
         @w_sucursal = ic_sucursal,
         @w_tipo_cust = ic_tipo_cust,
         @w_custodia = ic_custodia,
         @w_item_actual = ic_item,
         @w_valor_item = ic_valor_item,
         @w_secuencial = ic_secuencial,
         @w_codigo_externo = ic_codigo_externo 
    from cob_custodia..cu_item_custodia
    where 
         ic_filial = @i_filial and
         ic_sucursal = @i_sucursal and
         ic_tipo_cust = @i_tipo_cust and
         ic_custodia = @i_custodia and
         ic_secuencial = @i_secuencial and
         ic_item = @w_item

    if @@rowcount > 0
            select @w_existe = 1
    else
            select @w_existe = 0
end

/* VALIDACION DE CAMPOS NULOS */
/******************************/
if @i_operacion = 'I' or @i_operacion = 'U'
begin
    if @i_filial = NULL or 
       @i_sucursal = NULL or 
       @i_tipo_cust = NULL or 
       @i_custodia = NULL or 
       @w_item = NULL or
      (@w_mandatorio = 'S' and @i_valor_item = NULL)
         
    begin
    if @i_val_item = 'S' --REF:LRC mar.12.2009 
    begin
    /* Campos NOT NULL con valores nulos */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1901001
        return 1 
    end
    end
    
   --REF:LRC mar.12.2009 Inicio
   if @i_val_item = 'S'
   begin
   --REF:LRC ene.28.2008 Inicio   
   select @w_error = 0
   exec cob_custodia..sp_valida_valores_items
        @i_tipo_cust  = @i_tipo_cust,
        @i_valor_item = @i_valor_item,
        @i_nombre     = @i_nombre,
        @o_error      = @w_error out,
        @o_msg        = @w_msg out
   
   if @w_error = 1
   begin
     exec cobis..sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file, 
          @t_from  = @w_sp_name,
          @i_num   = 1900000,
          @i_msg   = @w_msg

   
     delete cob_custodia..cu_item_custodia
      where ic_filial = @i_filial 
        and ic_sucursal = @i_sucursal 
        and ic_tipo_cust = @i_tipo_cust 
        and ic_custodia = @i_custodia        
     return 1     
   end      
   --REF:LRC ene.28.2008 Inicio   
   end
   --REF:LRC mar.12.2009 Fin
end

/* Insercion del registro */
/**************************/

if @i_operacion = 'I'
begin
   begin tran

        exec sp_externo 
        @i_filial = @i_filial,
        @i_sucursal = @i_sucursal,
        @i_tipo     = @i_tipo_cust,
        @i_custodia = @i_custodia,
        @o_compuesto = @w_codigo_externo out

   	/*print 'Filial  %1!',@i_filial
   	print 'Sucursal  %1!',@i_sucursal
   	print 'Tipo  %1!',@i_tipo_cust
   	print 'Custodia  %1!',@i_custodia
   	print 'Sec  %1!',@i_secuencial
   	print 'item  %1!',@w_item
   	print 'valor  %1!',@i_valor_item
   	print 'codig  %1!',@w_codigo_externo*/

   insert into cu_item_custodia (
   	ic_filial,
   	ic_sucursal,
   	ic_tipo_cust,
   	ic_custodia,
   	ic_secuencial,
   	ic_item,
   	ic_valor_item,
        ic_codigo_externo)
   values (
   	@i_filial,
   	@i_sucursal,
   	@i_tipo_cust,
   	@i_custodia,
   	@i_secuencial,
   	@w_item,
   	@i_valor_item,
   	@w_codigo_externo)
   
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
         insert into ts_item_custodia
         values (@s_ssn,@t_trn,'N',@s_date,@s_user,@s_term,@s_ofi,'cu_item',
         @i_filial,
         @i_sucursal,
         @i_tipo_cust,
         @i_custodia,
         @i_item,
         @i_valor_item,
         @i_secuencial,
   	 @w_codigo_externo)

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
  begin tran
        exec sp_externo 
        @i_filial = @i_filial,
        @i_sucursal = @i_sucursal,
        @i_tipo     = @i_tipo_cust,
        @i_custodia = @i_custodia,
        @o_compuesto = @w_codigo_externo out

    -- MVI 07/08/96 cuando luego creo un nuevo item
    if not exists (select ic_item from cu_item_custodia
                  where  ic_item           = @i_item 
                  and    ic_secuencial     = @i_secuencial
                  and    ic_codigo_externo = @w_codigo_externo)
    begin  
         insert into cu_item_custodia(
              ic_filial,
              ic_sucursal,
              ic_tipo_cust,
              ic_custodia,
              ic_item,
              ic_valor_item,
              ic_secuencial,
              ic_codigo_externo)
         values (
              @i_filial,
              @i_sucursal,
              @i_tipo_cust,
              @i_custodia,
              @i_item,
              @i_valor_item,
              @i_secuencial,
              @w_codigo_externo)

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

         insert into ts_item_custodia
         values (@s_ssn,@t_trn,'N',@s_date,@s_user,@s_term,@s_ofi,'cu_item_custodia',
         @i_filial,
         @i_sucursal,
         @i_tipo_cust,
         @i_custodia,
         @i_item,
         @i_valor_item,
         @i_secuencial,
         @w_codigo_externo)

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
    end
    else
    begin     --MVI 07/08/96 hasta aqui aumento 
      update cob_custodia..cu_item_custodia
      set 
              ic_valor_item = @i_valor_item
      where 
         ic_filial = @i_filial and
         ic_sucursal = @i_sucursal and
         ic_tipo_cust = @i_tipo_cust and
         ic_custodia = @i_custodia and
         ic_secuencial = @i_secuencial and
         ic_item = @w_item
         
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

         insert into ts_item_custodia
         values (@s_ssn,@t_trn,'P',@s_date,@s_user,@s_term,@s_ofi,'cu_item_custodia',
         @w_filial,
         @w_sucursal,
         @w_tipo_cust,
         @w_custodia,
         @w_item_actual,
         @w_valor_item,
	 @i_secuencial,
   	 @w_codigo_externo)

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

         insert into ts_item_custodia
         values (@s_ssn,@t_trn,'A',@s_date,@s_user,@s_term,@s_ofi,'cu_item_custodia',
         @i_filial,
         @i_sucursal,
         @i_tipo_cust,
         @i_custodia,
         @w_item,
         @i_valor_item,
         @i_secuencial,
   	 @w_codigo_externo)

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
    end
    commit tran
    return 0
end
   
/* Eliminacion de registros */
/****************************/

if @i_operacion = 'D'
begin

    begin tran
         delete cob_custodia..cu_item_custodia
    where 
         ic_filial = @i_filial and
         ic_sucursal = @i_sucursal and
         ic_tipo_cust = @i_tipo_cust and
         ic_custodia = @i_custodia and
         ic_secuencial = @i_secuencial 

                          
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

	 update cu_item_custodia
	 set ic_secuencial = ic_secuencial - 1
	 where 
         ic_filial = @i_filial and
         ic_sucursal = @i_sucursal and
         ic_tipo_cust = @i_tipo_cust and
         ic_custodia = @i_custodia and
         ic_secuencial > @i_secuencial 

         /* Transaccion de Servicio */
         /***************************/

         insert into ts_item_custodia
         values (@s_ssn,@t_trn,'B',@s_date,@s_user,@s_term,@s_ofi,'cu_item_custodia',
         @w_filial,
         @w_sucursal,
         @w_tipo_cust,
         @w_custodia,
         @w_item_actual,
         @w_valor_item,
         @w_secuencial,
   	 @w_codigo_externo)

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

/* Consulta opcion QUERY */
/*************************/

if @i_operacion = 'Q'
begin
    select max(ic_secuencial)
      from cu_item_custodia
     where ic_filial = @i_filial
       and ic_sucursal = @i_sucursal
       and ic_tipo_cust = @i_tipo_cust
       and ic_custodia = @i_custodia

    return 0
end


/* Busqueda de valores */
if @i_operacion = 'A'
begin
   if @i_codigo_externo is not null
   begin
        exec sp_compuesto 
          @t_trn = 19245,
          @i_operacion = 'Q',
          @i_compuesto = @i_tipo_cust,
          @o_tipo = @i_tipo_cust out
   end

   if @i_modo = 0
   begin
      select "ITEM"=it_item,"NOMBRE"=substring(it_nombre,1,50),"TIPO"=it_tipo_dato,"MANDATORIEDAD"=it_mandatorio,"DESCRIPCION"='                                     ' 
      from cu_item --,cu_item_custodia 
      where it_tipo_custodia  = @i_tipo_cust
       -- and ic_filial         = @i_filial
       -- and ic_sucursal       = @i_sucursal
       -- and it_tipo_custodia *= ic_tipo_cust
       -- and it_item          *= ic_item
       -- and ic_custodia       = @i_custodia
      order by it_item
      if @@rowcount = 0
       begin
      --No existen registros 

           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file, 
           @t_from  = @w_sp_name,
           @i_num   = 1901003 
           return 1901003
       end
   end
   if @i_modo = 1
   begin
      select "ITEM"=it_item,"NOMBRE"=substring(it_nombre,1,50),"TIPO"=it_tipo_dato,"MANDATORIEDAD"=it_mandatorio,"DESCRIPCION"='                                     '
      from cu_item --,cu_item_custodia
      where it_tipo_custodia  = @i_tipo_cust
        --and ic_filial         = @i_filial
        --and ic_sucursal       = @i_sucursal
        --and it_tipo_custodia *= ic_tipo_cust          
        --and it_item          *= ic_item
        --and ic_custodia       = @i_custodia
        and it_item           > @i_item
      order by it_item
      if @@rowcount = 0
       begin
      /* No existen mas registros */

           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file, 
           @t_from  = @w_sp_name,
           @i_num   = 1901004
           return 1901004 
       end
   end   
end

/* Busqueda de todas las ocurrencias para la garantia dada */

if @i_operacion = 'S'
begin
    if @i_codigo_externo is not null
    begin
        exec sp_compuesto 
          @t_trn = 19245,
          @i_operacion = 'Q',
          @i_compuesto = @i_tipo_cust,
          @o_filial = @i_filial out,
          @o_sucursal = @i_sucursal out,
          @o_tipo = @i_tipo_cust out,
          @o_custodia = @i_custodia out
    end 
    /* Seteo el Contador de Filas */
    if @i_numerocount = 16
       set rowcount 16
    if @i_numerocount = 17
       set rowcount 17
    if @i_numerocount = 18
       set rowcount 18
    if @i_numerocount = 19
       set rowcount 19
    if @i_numerocount = 20
       set rowcount 20
    if @i_numerocount = 21
       set rowcount 21
    if @i_numerocount = 22
       set rowcount 22
    if @i_numerocount = 23
       set rowcount 23
    if @i_numerocount = 24
       set rowcount 24
    if @i_numerocount = 25
       set rowcount 25
    if @i_numerocount = 26
       set rowcount 26
    if @i_numerocount = 27
       set rowcount 27
    if @i_numerocount = 28
       set rowcount 28
    if @i_numerocount = 29
       set rowcount 29
    if @i_numerocount = 30
       set rowcount 30

      select "SECUENCIAL"=ic_secuencial,ic_item,"NOMBRE"=substring(it_nombre,1,50),"DESCRIPCION"=substring(ic_valor_item,1,37)
       from cu_item,cu_item_custodia 
      where it_tipo_custodia  = @i_tipo_cust
        and ic_filial         = @i_filial
        and ic_sucursal       = @i_sucursal
        and it_tipo_custodia  = ic_tipo_cust
        and it_item           = ic_item
        and ic_custodia       = @i_custodia
        and ((ic_secuencial    > @i_secuencial
             or (ic_secuencial = @i_secuencial and ic_item > @i_item)) or
            @i_item is null)
      order by ic_secuencial,it_item

      /*if @@rowcount = 0
      begin
         if @i_secuencial is null
             select @w_error  = 1901003
         else
             select @w_error  = 1901004
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file, 
         @t_from  = @w_sp_name,
         @i_num   = @w_error 
         return 1  
      end   */
end

if @i_operacion = 'C'
begin
    set rowcount 20
       select ic_tipo_cust,ic_custodia
         from cu_item_custodia
		 left join cu_item on it_tipo_custodia = ic_tipo_cust and it_item = ic_item
        where ic_filial         = @i_filial
          and ic_sucursal       = @i_sucursal
          and (ic_valor_item like @i_valor_item or @i_valor_item is null)
          and ((ic_tipo_cust > @i_tipo_cust or 
             (ic_tipo_cust = @i_tipo_cust and ic_custodia > @i_custodia) or
              ic_custodia is null))  

        order by ic_secuencial,it_item
    
      if @@rowcount = 0
      begin
            if @i_custodia is null /* Modo 0 */
               select @w_error  = 1901003
            else
               select @w_error  = 1901004
            exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file, 
            @t_from  = @w_sp_name,
            @i_num   = @w_error
            return 1
      end 
      return 0
end 

if @i_operacion = 'T'  --FAndrade 08/04/2008
 begin
 
 	if @i_codigo_externo is not null
   	 begin
	        exec sp_compuesto 
	          @t_trn = 19245,
	          @i_operacion = 'Q',
	          @i_compuesto = @i_tipo_cust,
	          @o_tipo = @i_tipo_cust out
   	 end
   
 	select 	count(*)
	  from 	cu_item --,cu_item_custodia 
         where 	it_tipo_custodia  = @i_tipo_cust
         
	if @@rowcount = 0
         begin
      		/* No existen mas registros */

           	exec cobis..sp_cerror
           	@t_debug = @t_debug,
           	@t_file  = @t_file, 
           	@t_from  = @w_sp_name,
           	@i_num   = 1901004
           	return 1 
	 end 
 end

if @i_operacion = 'X'	--FAndrade 08/04/2008
 begin
 
 	if @i_codigo_externo is not null
	    begin
	        exec sp_compuesto 
	          @t_trn = 19245,
	          @i_operacion = 'Q',
	          @i_compuesto = @i_tipo_cust,
	          @o_filial = @i_filial out,
	          @o_sucursal = @i_sucursal out,
	          @o_tipo = @i_tipo_cust out,
	          @o_custodia = @i_custodia out
	    end 
	    /* Seteo el Contador de Filas */
	    if @i_numerocount = 16
	       set rowcount 16
	    if @i_numerocount = 17
	       set rowcount 17
	    if @i_numerocount = 18
	       set rowcount 18
	    if @i_numerocount = 19
	       set rowcount 19
	    if @i_numerocount = 20
	       set rowcount 20
	    if @i_numerocount = 21
	       set rowcount 21
	    if @i_numerocount = 22
	       set rowcount 22
	    if @i_numerocount = 23
	       set rowcount 23
	    if @i_numerocount = 24
	       set rowcount 24
	    if @i_numerocount = 25
	       set rowcount 25
	    if @i_numerocount = 26
	       set rowcount 26
	    if @i_numerocount = 27
	       set rowcount 27
	    if @i_numerocount = 28
	       set rowcount 28
	    if @i_numerocount = 29
	       set rowcount 29
	    if @i_numerocount = 30
	       set rowcount 30
	
	select 	"ITEM"=it_item,
		"NOMBRE"=substring(it_nombre,1,50),
		"TIPO"=it_tipo_dato,
		"MANDATORIEDAD"=it_mandatorio,
		"DESCRIPCION"=substring(ic_valor_item,1,37)
          from 	cu_item,cu_item_custodia 
      	 where 	it_tipo_custodia  = @i_tipo_cust
	   and 	ic_filial         = @i_filial
	   and 	ic_sucursal       = @i_sucursal
	   and 	it_tipo_custodia  = ic_tipo_cust
	   and 	it_item           = ic_item
	   and 	ic_custodia       = @i_custodia
	 order 	by 
	 	ic_secuencial,
	 	it_item
 
 end
go