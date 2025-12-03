/*************************************************************************/
/*   Archivo:              credito5.sp                                   */
/*   Stored procedure:     sp_credito5                                   */
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
IF OBJECT_ID('dbo.sp_credito5') IS NOT NULL
    DROP PROCEDURE dbo.sp_credito5
go
create proc sp_credito5  (
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
   @i_codigo_externo     varchar(64) = null,
   @i_tipo_ctz           char(1) = "C" -- tipo de cotizacion C(credito) B(contabilidad)
)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_error              int,
   @w_grupo              int,
   @w_vcu                varchar(64),
   @w_gar                varchar(64),
   @w_gac                varchar(64),
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
   @w_def_moneda         tinyint,       -- moneda default (moneda local)
   @w_moneda             tinyint        -- moneda de la garantia

select @w_today   = getdate()
select @w_sp_name = 'sp_credito5',
       @w_ayer    = convert(char(10),dateadd(dd,-1,getdate()),101)

/***********************************************************/
/* Codigos de Transacciones                                */

if (@t_trn <> 19394 and @i_operacion = 'S') 
     
begin
/* tipo de transaccion no corresponde */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file, 
    @t_from  = @w_sp_name,
    @i_num   = 1901006
    return 1 
end

if @i_operacion = 'S'
begin
   
   select @w_vcu = pa_char + '%' -- TIPOS SIMPLE CUSTODIA EXCLUIR
    from cobis..cl_parametro
   where pa_producto = 'GAR'
     and pa_nemonico = 'VCU'
   
   select @w_gar = pa_char + '%' -- TIPOS DE GARANTIA
    from cobis..cl_parametro
   where pa_producto = 'GAR'
     and pa_nemonico = 'GAR'
   
   select @w_gac = pa_char + '%' -- TIPOS DE GARANTIA AL COBRO 
    from cobis..cl_parametro
   where pa_producto = 'GAR'
     and pa_nemonico = 'GAC'


  -- creacion de tabla temporal para cotizaciones
  /* Seleccion de codigo de moneda local */
  SELECT @w_def_moneda = pa_tinyint  
  FROM cobis..cl_parametro  
  WHERE pa_nemonico = 'MLOCR'  

  if @@rowcount = 0
  begin
    /*Registro no existe */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 2101005
        return 1
  end

  CREATE TABLE #cr_cotiz
  (     moneda                  tinyint null,
        cotizacion              money null
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
      insert into #cr_cotiz (moneda, cotizacion)
      values (@w_def_moneda, 1)


   /* TOTALES POR MIEMBRO DE GRUPO Y TIPO DE GARANTIA */
   if @i_modo = 2
   begin

      create table #cu_grupos1 (Ente      int          null,
                               Nombre    varchar(64)  null,
                               Valor     money        null)


--      declare grupos insensitive cursor for /* HHO Mayo/2012    Migracion SYBASE 15 */
      declare grupos cursor for /* HHO Mayo/2012    Migracion SYBASE 15 */
      select distinct en_ente,en_nombre,p_p_apellido,p_s_apellido, 
                      cu_codigo_externo, cu_valor_actual, cu_moneda
        from cobis..cl_ente,cu_custodia,cu_cliente_garantia
       where en_grupo          = @i_grupo 
         and en_ente           = cg_ente
         and cg_codigo_externo = cu_codigo_externo
         and cu_estado         not in ('A')
         and cu_tipo           = @i_tipo_cust
       order by en_ente

      open grupos
      fetch grupos into @w_cliente,@w_nombre,@w_apellido1,@w_apellido2, 
                        @w_codigo, @w_valor, @w_moneda


      while @@FETCH_STATUS != -1
      begin

         if (@@FETCH_STATUS = -2)    --  ERROR DEL CURSOR
         begin
            exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file, 
            @t_from  = @w_sp_name,
            @i_num   = 1909001 
            
            close grupos
            deallocate grupos
            select Ente, Nombre, Valor from #cu_grupos1
            return 1 
         end


         select @w_valor = @w_valor * cotizacion
         from   #cr_cotiz
         where  moneda = @w_moneda

         select @w_valor = isnull(@w_valor,0)

         insert into #cu_grupos1 values (@w_cliente,
                                   @w_apellido1+' '+@w_apellido2+' '+@w_nombre,
                                   @w_valor)

         fetch grupos into @w_cliente,@w_nombre,@w_apellido1,@w_apellido2,
                           @w_codigo, @w_valor, @w_moneda

      end   --  FIN DEL WHILE

      close grupos
      deallocate grupos

      -- Envio de resultados al front-end
      set rowcount 20
      select Ente, Nombre, sum(Valor)
      from #cu_grupos1
      where  (Ente > @i_cliente or @i_cliente is null)
      group by Ente, Nombre
      order by Ente, Nombre /* HHO Mayo/2012    Migracion SYBASE 15 */
      set rowcount 0
   end 
   else  
   begin
      -- TOTALES POR TIPOS    **********************
      if @i_modo = 1  
      begin

        create table #cu_tipos1  (Tipo           varchar(15)  null,
                                 Descripcion    varchar(64)  null,
                                 Valor          money        null)


--        declare grupos1 insensitive cursor for /* HHO Mayo/2012    Migracion SYBASE 15 */
        declare grupos1 cursor for /* HHO Mayo/2012    Migracion SYBASE 15 */
         select distinct substring (tc_tipo,1,15),
                tc_descripcion,
                cu_codigo_externo,
                cu_valor_actual,
                cu_moneda
           from cu_custodia
           inner join cu_tipo_custodia on cu_tipo = tc_tipo
		   inner join cu_cliente_garantia on cg_codigo_externo = cu_codigo_externo
		   inner join cobis..cl_ente on cg_ente = en_ente
           left join #cr_cotiz on moneda = cu_moneda  
          where en_grupo = @i_grupo
            and cu_garante   is null   --  Excluye garantes personales
            and cu_estado    not in ('C','A')    
            and cu_tipo not like @w_vcu
           order by substring(tc_tipo,1,15), tc_descripcion

         open grupos1
         fetch grupos1 into @w_tipo,@w_descripcion,
                           @w_codigo, @w_valor, @w_moneda


         while @@FETCH_STATUS != -1
         begin

            if (@@FETCH_STATUS = -2)    --  ERROR DEL CURSOR
            begin
               exec cobis..sp_cerror
               @t_debug = @t_debug,
               @t_file  = @t_file, 
               @t_from  = @w_sp_name,
               @i_num   = 1909001 
            
               close grupos1
               deallocate grupos1
               select Tipo, Descripcion, Valor from #cu_tipos1
               return 1 
            end


            select @w_valor = @w_valor * cotizacion
            from   #cr_cotiz
            where  moneda = @w_moneda

            select @w_valor = isnull(@w_valor,0)

            insert into #cu_tipos1  values (@w_tipo,
                                           @w_descripcion,
                                           @w_valor)

            fetch grupos1 into @w_tipo, @w_descripcion,
                              @w_codigo, @w_valor, @w_moneda

      end   --  FIN DEL WHILE

      close grupos1
      deallocate grupos1


         -- Envio de Resultados al Front-end

         set rowcount 20

         select distinct 'TIPO'          = Tipo,
                         'DESCRIPCION'   = Descripcion,
                         'TOTAL VALOR'   = sum(Valor)
         from   #cu_tipos1
         where  (Tipo > @i_tipo_cust or @i_tipo_cust is null)
         group by Tipo, Descripcion
         --order by  Tipo     ---  ame 28/sept/2004
         order by Tipo, Descripcion/* HHO Mayo/2012    Migracion SYBASE 15 */

         set rowcount 0
      end

      if @i_modo = 3  --CODIGO,DESCRIPCION y ESTADO DE UN TIPO
      begin
         set rowcount 20
         select distinct 'CODIGO' = cu_codigo_externo,
                'DESCRIPCION' = substring(cu_descripcion,1,35),
                'ESTADO' = cu_estado,
                'VALOR ACTUAL'=cu_valor_actual * isnull(cotizacion,1)
          from cu_custodia
		  inner join cu_cliente_garantia on cg_codigo_externo = cu_codigo_externo
		  left join cu_tipo_custodia on cu_tipo = tc_tipo
          left join #cr_cotiz on moneda = cu_moneda  
		  --cobis..cl_ente,
               
         where cg_ente           = @i_cliente
           and cu_garante        is null   --  Excluye garantes personales
           and cu_estado   not in ('C','A')
           and cu_tipo not like @w_vcu
           and cu_tipo      = @i_tipo_cust
           and (cu_codigo_externo>@i_codigo_externo or @i_codigo_externo=null)
         set rowcount 0
      end

      return 0 

   end -- ELSE
end
go