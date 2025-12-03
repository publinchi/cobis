/*************************************************************************/
/*   Archivo:              intcre01.sp                                   */
/*   Stored procedure:     sp_intcre01                                   */
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
IF OBJECT_ID('dbo.sp_intcre01') IS NOT NULL
    DROP PROCEDURE dbo.sp_intcre01
go
create proc sp_intcre01  (
   @s_ssn                int      = null,
   @s_date               datetime = null,
   @s_user               login    = null,
   @s_term               descripcion = null,
   @s_corr               char(1)  = null,
   @s_ssn_corr           int      = null,
   @s_ofi                tinyint  = null,
   @t_rty                char(1)  = null,
   @t_trn                smallint = null,
   @t_debug              char(1)  = 'N',
   @t_file               varchar(14) = null,
   @t_from               varchar(30) = null,
   @i_operacion          char(1)  = null,
   @i_modo               smallint = null,
   @i_cliente            int = null, 
   @i_grupo              int = null,
   @i_tipo 		 tinyint = null,
   @i_codigo_externo     varchar(64) = null,
   @i_opcion             tinyint = null,
   @o_valor1		 money = null out,
   @o_valor2		 money = null out
)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_error              int,
   @w_estado             char(1),
   @w_cliente            int,
   @w_nombre             varchar(64),
   @w_apellido1          varchar(64),
   @w_apellido2          varchar(64),
   @w_contador           tinyint,
   @w_ayer               datetime,
   @w_valor              money,
   @w_gar                varchar(64),
   @w_gac                varchar(64),
   @w_vcu                varchar(64)

select @w_today   = getdate()
select @w_sp_name = 'sp_intcre01'
select @w_ayer    = convert(char(10),dateadd(dd,-1,getdate()),101)
/***********************************************************/
/* Codigos de Transacciones                                */

if (@t_trn <> 19494 and @i_operacion = 'S') 
begin
/* tipo de transaccion no corresponde */
    select @w_error = 1901006
    goto error
end


  
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

   if @i_opcion = 1        -- TOTAL GARANTIAS ADECUADAS POR CLIENTE
   begin
      select @o_valor1 = sum(cu_valor_actual * isnull(cz_valor,1))
        from cu_custodia cc
		inner join cu_cliente_garantia ccg on cc.cu_codigo_externo = ccg.cg_codigo_externo
		left join cob_credito..cr_cotizacion cz on cz.cz_moneda = cc.cu_moneda
       where ccg.cg_ente            = @i_cliente
         and cc.cu_tipo     not like @w_vcu  -- No incluir Valores en Custodia
         and cc.cu_garante        is null    -- Excluye garantes personales
         and cc.cu_adecuada_noadec = 'S'
         and cc.cu_estado          = 'V'
         and cz.cz_fecha          in (select max(cz_fecha)
                                     from cob_credito..cr_cotizacion,cu_custodia
                                    where cz_fecha <= @w_today
                                      and cz_moneda = cu_moneda)

      select @o_valor2 = sum(cu_valor_actual * isnull(cz_valor,1))
        from cu_custodia cc
		inner join cu_cliente_garantia ccg on cc.cu_codigo_externo = ccg.cg_codigo_externo
		left join cob_credito..cr_cotizacion cz on cz.cz_moneda = cc.cu_moneda
       where ccg.cg_ente            = @i_cliente
         and cc.cu_tipo     like 'GARPFI%'  -- No incluir Valores en Custodia
         and cc.cu_garante        is null    -- Excluye garantes personales
         and cc.cu_adecuada_noadec = 'S'
         and cc.cu_estado          = 'V'
         and cz.cz_fecha          in (select max(cz_fecha)
                                     from cob_credito..cr_cotizacion,cu_custodia
                                    where cz_fecha <= @w_today
                                      and cz_moneda = cu_moneda)

   end  -- FIN OPCION 1      

   if @i_opcion = 2       -- TOTAL GARANTIAS ADECUADAS POR CLIENTE DE GRUPO
   begin
      create table #cu_grupos2 (Ente      int          null,
                               Nombre    varchar(64)  null,
                               Valor     money        null)

--      declare grupos insensitive cursor  for /* HHO Mayo/2012    Migracion SYBASE 15 */
      declare grupos cursor  for /* HHO Mayo/2012    Migracion SYBASE 15 */
      select distinct en_ente,en_nombre,p_p_apellido,p_s_apellido
        from cobis..cl_ente,cobis..cl_grupo,cu_cliente_garantia,cu_custodia  
       where gr_grupo          = @i_grupo 
         and en_grupo          = gr_grupo
         and en_ente           = cg_ente
         and cg_codigo_externo = cu_codigo_externo
         and cu_estado         not in ('A')
         and cu_garante        is null    -- Excluye garantes personales
         and cu_tipo     not like @w_vcu  -- No incluir Valores en custodia
         and (en_ente > @i_cliente or @i_cliente is null) -- PARA 20 SIGTES.
       order by en_ente

      open grupos
      fetch grupos into @w_cliente,@w_nombre,@w_apellido1,@w_apellido2

      if (@@FETCH_STATUS = -1)    --  No existen grupos
      begin
        --print "No existen clientes para este grupo"
        select  Ente, Nombre, Valor
        from #cu_grupos2
        close grupos
        --return 0
      end

      select @w_contador = 1   -- Para ingresar solo 20 registros
      while (@@FETCH_STATUS = 0)  and (@w_contador <=20) -- Lazo de busqueda
      begin
         select @w_contador = @w_contador + 1
         select @w_valor    = sum(cu_valor_actual * isnull(cz.cz_valor,1))
           from cu_custodia cc
			inner join cu_cliente_garantia ccg on cc.cu_codigo_externo = ccg.cg_codigo_externo
			left join cob_credito..cr_cotizacion cz on cz.cz_moneda = cc.cu_moneda
		    --cu_tipo_custodia
          where ccg.cg_ente            = @w_cliente
            and cc.cu_garante        is null   --  Excluye garantes personales  
            and cz.cz_fecha          in (select max(cz_fecha)
                                        from cob_credito..cr_cotizacion,
                                             cu_custodia 
                                        where cz_fecha <= @w_today
                                         and cz_moneda = cu_moneda)
            and cc.cu_estado          = 'V'
            and cc.cu_adecuada_noadec = 'S' 
            --and tc_tipo            = cu_tipo
            --and tc_tipo_superior  is not null  
          --order by cg_ente

         insert into #cu_grupos2 values (@w_cliente,
                                @w_apellido1+' '+@w_apellido2+' '+@w_nombre,
                                @w_valor)

         fetch grupos into @w_cliente,@w_nombre,@w_apellido1,@w_apellido2

      end   --  FIN DEL WHILE

      if (@@FETCH_STATUS = -2)  -- ERROR DEL CURSOR
      begin
            exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file, 
            @t_from  = @w_sp_name,
            @i_num   = 1909001 
            return 1 
      end
      close grupos
      deallocate grupos
      select  Ente, Nombre, Valor from #cu_grupos2
   end   -- FIN DE OPCION 2

   if @i_opcion = 3   -- TOTALES DE GARANTIAS DEL GRUPO
   begin
      select 'TOTAL GRUPO' = sum(cu_valor_actual*isnull(cz_valor,1))    
        from cu_custodia cc
			inner join cu_cliente_garantia ccg on cc.cu_codigo_externo = ccg.cg_codigo_externo
			inner join cobis..cl_ente en on en.en_ente = ccg.cg_ente
			inner join cobis..cl_grupo gr on gr.gr_grupo = en.en_grupo
			left join cob_credito..cr_cotizacion cz on cz.cz_moneda = cc.cu_moneda
       where gr_grupo				= @i_grupo
         and cu_garante				is null   --  Excluye garantes personales
         and cu_tipo				not like @w_vcu  -- No incluir Valores en custodia
         and cu_estado				= 'V'
         and cu_adecuada_noadec		= 'S'
         and cz_fecha				in (select max(cz_fecha)
										from cob_credito..cr_cotizacion,cu_custodia
										where cz_fecha <= @w_today
										and cz_moneda = cu_moneda)
   end  -- FIN OPCION 3
end
return 0 
error:
   exec cobis..sp_cerror
   @t_debug = @t_debug,
   @t_file  = @t_file, 
   @t_from  = @w_sp_name,
   @i_num   = @w_error
   return 1
go