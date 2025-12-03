/*************************************************************************/
/*   Archivo:              intcre03.sp                                   */
/*   Stored procedure:     sp_intcre03                                   */
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
/*   penalmente a los autores de cualquier infraccion.                   */
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
IF OBJECT_ID('dbo.sp_intcre03') IS NOT NULL
    DROP PROCEDURE dbo.sp_intcre03
go
create proc sp_intcre03  (
   @s_ssn                int      = null,
   @s_date               datetime = null,
   @s_user               login    = null,
   @s_term               varchar(64) = null,
   @s_corr               char(1)     = null,
   @s_ssn_corr           int         = null,
   @s_ofi                smallint     = null,
   @t_rty                char(1)     = null,
   @t_trn                smallint    = null,
   @t_debug              char(1)     = 'N',
   @t_file               varchar(14) = null,
   @t_from               varchar(30) = null,
   @i_operacion          char(1)     = null,
   @i_modo               smallint    = null,
   @i_grupo              int         = null, 
   @i_tipo_cust          varchar(64) = null,
   @i_cliente            int         = null,
   @i_ente               int         = null,
   @i_tipo_ctz	         char(1) = 'B',  --C cotizacion de credito, B contabilidad
   @i_codigo_externo     varchar(64) = null,
   @i_opcion 		 tinyint = 1   
)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_error              int,
   @w_grupo              int,
   @w_scu                varchar(64),
   @w_ayer               datetime,
   @w_ente               int,
   @w_nombre             varchar(64),
   @w_valor              money,
   @w_otras              money,
   @w_cliente            int,
   @w_contador           tinyint,
   @w_apellido1          varchar(64),
   @w_apellido2          varchar(64),
   @w_tipo               varchar(64),
   @w_descripcion        varchar(64),
   @w_codigo             varchar(64),
   @w_estado             varchar(64),
   @w_gar                varchar(64),
   @w_gac                varchar(64), 
   @w_vcu                varchar(64),
   @w_total              money,
   @w_garantia           varchar(64),
   @w_def_moneda	 tinyint,	-- moneda local
   @w_moneda		 tinyint	-- moneda de la garantia
  

select @w_today = @s_date
select @w_today = isnull(@w_today, fp_fecha)
from cobis..ba_fecha_proceso

select @w_sp_name = 'sp_intcre03',
       @w_ayer    = convert(char(10),dateadd(dd,-1,getdate()),101)

/***********************************************************/
/* Codigos de Transacciones                                */

if (@t_trn <> 19514 and @i_operacion = 'S') 
     
begin
/* tipo de transaccion no corresponde */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file, 
    @t_from  = @w_sp_name,
    @i_num   = 1901006
    return 1 
end


/* Seleccion de codigo de moneda local */
SELECT @w_def_moneda = pa_tinyint  
    FROM cobis..cl_parametro  
    WHERE pa_nemonico = 'MLOCR'   


CREATE TABLE #cr_cotiz
(	moneda			tinyint null,
	cotizacion		money null
)

If @i_tipo_ctz = 'C'  -- cotizacion de credito
	insert into #cr_cotiz
	(moneda, cotizacion)
	select	
	a.cz_moneda, a.cz_valor
	from   cob_credito..cr_cotizacion a
        where    cz_fecha = (select max(b.cz_fecha)
			    from cob_credito..cr_cotizacion b
			    where 
			        b.cz_moneda = a.cz_moneda
			    and b.cz_fecha <= @w_today)
else  -- cotizacion de la contabilidad
	insert into #cr_cotiz
	(moneda, cotizacion)
	select	
	a.ct_moneda, a.ct_compra
        from   cob_conta..cb_cotizacion a
        where    ct_fecha = (select max(b.ct_fecha)
                            from cob_conta..cb_cotizacion b
			    where 
			        b.ct_moneda = a.ct_moneda
			    and b.ct_fecha <= @w_today)

-- insertar un registro para la moneda local
       

if not exists (select * from #cr_cotiz
	       where moneda = @w_def_moneda)
insert into #cr_cotiz
(moneda, cotizacion)
values (@w_def_moneda, 1)



if @i_operacion = 'S'
begin
   select @w_gar = pa_char + '%' -- TIPOS GARANTIA
     from cobis..cl_parametro
    where pa_producto = 'GAR'
      and pa_nemonico = 'GAR'

   select @w_gac = pa_char + '%' -- TIPOS GARANTIA AL COBRO
     from cobis..cl_parametro
    where pa_producto = 'GAR'
      and pa_nemonico = 'GAC'

    select @w_vcu = pa_char + '%' -- TIPOS VALORES EN CUSTODIA
     from cobis..cl_parametro
    where pa_producto = 'GAR'
      and pa_nemonico = 'VCU'

   -- para cuando mando solamente el cliente
   if @i_cliente is not null and @i_grupo is null
   begin
      select @i_grupo = en_grupo
      from cobis..cl_ente
      where en_ente = @i_cliente
   end

 
   -- Totales de Garantias por cliente de un grupo
   if @i_modo = 1
   begin


      create table #cu_grupos3 (Ente      int          null,
                               Producto  varchar(64)  null,
                               Valor     money        null,
			       Codigo	 varchar(64)  null)


      if @i_grupo is null
      begin

           select Ente, Producto, Valor, Codigo 
           from #cu_grupos3
           select @w_total = 0 
	   select @w_total
	   return 0
      end


      -- inicializar el total
      select @w_total = 0

--      declare grupos insensitive cursor for /* HHO Mayo/2012    Migracion SYBASE 15 */
      declare grupos cursor for /* HHO Mayo/2012    Migracion SYBASE 15 */
      select distinct en_ente,cu_codigo_externo, cu_valor_actual, cu_moneda
        from cobis..cl_ente,cu_custodia,cu_cliente_garantia
       where en_grupo          = @i_grupo
         and cg_ente         = en_ente
         and cg_ente        <> @i_ente   -- No incluir al ente dado
         and cg_codigo_externo   = cu_codigo_externo
         and cu_tipo    not like @w_vcu   -- Excluir Valores en custodia
         and cu_tipo <> '950'   --IICMI 21Mar2006 No se consideran garantias de encargo fiduciario solicitado por GZambrano
         and cu_estado        not in ('A','C')  
         and cu_garante        is null    -- Excluir garante
       order by en_ente

      open grupos
      fetch grupos into @w_cliente,@w_garantia, @w_valor, @w_moneda


      while (@@FETCH_STATUS != -1)  -- Lazo de busqueda
      begin

         if (@@FETCH_STATUS = -2)    --  Error del Cursor
         begin
           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file, 
           @t_from  = @w_sp_name,
           @i_num   = 1909001 
           
           select Ente, Producto, Valor, Codigo from #cu_grupos3
	   
           close grupos
	   deallocate grupos
	   return 1

	 end

         /* Cambiar a Moneda Local*/

	 select @w_valor = @w_valor * cotizacion
	 from #cr_cotiz
	 where  moneda = @w_moneda
	 
   	 select @w_valor = isnull(@w_valor,0)


	-- totalizar el valor de garantÂ¡as del grupo
	-- se usa el exists para no sumar mas de una vez la misma garantia
	if not exists (	select 1
                        from #cu_grupos3
			where Codigo = @w_garantia)	
		select @w_total = @w_total + isnull(@w_valor,0)
     
     
	-- insertar en la tabla temporal   
        insert into #cu_grupos3 values (@w_cliente,
                                       @w_tipo,
                                       @w_valor,
				       @w_garantia)

	
        fetch grupos into @w_cliente,@w_garantia,@w_valor, @w_moneda

      end   --  FIN DEL WHILE

      close grupos
      deallocate grupos

      -- Retornar los datos al front-end
      if @i_opcion = 1
      begin
         set rowcount 20

         select 'Cliente' = Ente, 
	        'Tipo' = Producto, 
	        'Valor' = sum(Valor)
         from #cu_grupos3
         where (Ente > @i_cliente or @i_cliente is null)
         group by Ente, Producto
         order by  Ente, Producto /* HHO Mayo/2012    Migracion SYBASE 15 */

         set rowcount 0
      end

      select @w_total
   end 
   else  
   begin
      -- TOTALES POR TIPOS    *********************
      if @i_modo = 2  
      begin


      create table #cu_tipos  (Producto  varchar(64)  null,
                               Valor     money        null,
			       Codigo	 varchar(64)  null)


      if @i_grupo is null
      begin
	   if @i_opcion = 1
	      select 'Tipo' = null, 'Total Valor' = null

           select @w_total = 0 
	   select @w_total
	   return 0
      end

      -- inicializar total
         select @w_total = isnull(@w_total,0)

         select @i_tipo_cust = isnull(@i_tipo_cust,' ')



--      declare grupos1 insensitive  cursor for /* HHO Mayo/2012    Migracion SYBASE 15 */
      declare grupos1 cursor for /* HHO Mayo/2012    Migracion SYBASE 15 */
         select distinct
	        substring(tc_descripcion,1,30),  --LRE 09/15/05
		cu_tipo,
		cu_codigo_externo,
                cu_valor_actual,
		cu_moneda
         from cu_custodia,
              cobis..cl_ente,cu_cliente_garantia, cob_custodia..cu_tipo_custodia
         where en_grupo     = @i_grupo 
         and cg_ente    = en_ente
         and cg_ente   <> @i_ente   -- No incluir al ente dado
         and cg_codigo_externo  = cu_codigo_externo
         and cu_tipo    not like @w_vcu   -- Excluir Valores en custodia
         and cu_tipo <> '950'   --IICMI 21Mar2006 No se consideran garantias de encargo fiduciario solicitado por GZambrano
         and cu_tipo = tc_tipo
         and cu_garante   is null   --  Excluye garantes personales
         and cu_estado    <> 'C'
	 and cu_estado    <> 'A'
         order by cu_tipo

      open grupos1
      fetch grupos1 into @w_tipo,@w_garantia, @w_valor, @w_moneda


      while (@@FETCH_STATUS != -1)  -- Lazo de busqueda
      begin

         if (@@FETCH_STATUS = -2)    --  Error del Cursor
         begin
           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file, 
           @t_from  = @w_sp_name,
           @i_num   = 1909001 

           select Producto, Valor,Codigo from #cu_tipos
	   
           close grupos1
           deallocate grupos1
	   return 1

	 end

         /* Cambiar a Moneda Local*/

	 select @w_valor = @w_valor * cotizacion
	 from #cr_cotiz
	 where  moneda = @w_moneda
	 
   	 select @w_valor = isnull(@w_valor,0)


	-- totalizar el valor de garantÂ¡as del grupo
		select @w_total = @w_total + isnull(@w_valor,0)
     
     
	-- insertar en la tabla temporal   
        insert into #cu_tipos  values (@w_tipo,
                                       @w_valor,
				       @w_garantia)

	
        fetch grupos1 into @w_tipo,@w_garantia, @w_valor, @w_moneda

      end   --  FIN DEL WHILE

      close grupos1
      deallocate grupos1

      -- Retornar los datos al front-end
      if @i_opcion = 1
      begin
         set rowcount 20

         select 'Tipo' = Producto, 
	        'Valor' = sum(Valor)
         from #cu_tipos
         where Producto > @i_tipo_cust
         group by Producto
         order by Producto /* HHO Mayo/2012    Migracion SYBASE 15 */

         set rowcount 0
      end

      select @w_total

      end


      if @i_modo = 3  --  TOTAL DEL GRUPO
      begin

	--inicializar total
	select @w_total = isnull(@w_total, 0)

	-- crear tabla temporal
	create table #cu_total   (Codigo    varchar(64)  null,
				  Valor     money        null,
				  Moneda    tinyint	 null)


        if @i_grupo is null
        begin
	   select @w_total
	   return 0
        end



	-- insertar registros en la tabla temporal
	insert into #cu_total
	(Codigo, Valor, Moneda)
	select distinct
	cu_codigo_externo, cu_valor_actual,cu_moneda
         from cu_custodia,
              cobis..cl_ente,cu_cliente_garantia
         where en_grupo     = @i_grupo 
         and cg_ente    = en_ente
         and cg_ente   <> @i_ente   -- No incluir al ente dado
         and cg_codigo_externo   = cu_codigo_externo
         and cu_tipo    not like @w_vcu   -- Excluir Valores en custodia
         and cu_tipo <> '950'   --IICMI 21Mar2006 No se consideran garantias de encargo fiduciario solicitado por GZambrano
         and cu_garante   is null   --  Excluye garantes personales
         and cu_estado    <> 'C'
	 and cu_estado    <> 'A'



	-- otener el total en moneda local
     select  @w_total   = sum(Valor * isnull(cotizacion,1))
     from #cu_total
	 left join #cr_cotiz on Moneda = moneda
	 
	-- inicializar
	 select @w_total = isnull(@w_total,0)

	-- retornar el front-end
           select @w_total
      end
   end -- FIN DEL ELSE
end

return 0
go