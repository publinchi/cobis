/*************************************************************************/
/*   Archivo:              intcre04.sp                                   */
/*   Stored procedure:     sp_intcre04                                   */
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
IF OBJECT_ID('dbo.sp_intcre04') IS NOT NULL
    DROP PROCEDURE dbo.sp_intcre04
go
create procedure sp_intcre04(
        @s_ssn                int      = null,
        @s_date               datetime = null,
        @s_user               login    = null,
        @s_term               varchar(64) = null,
        @s_corr               char(1)  = null,
        @s_ssn_corr           int      = null,
        @s_ofi                smallint  = null,
        @t_rty                char(1)  = null,
        @t_trn                smallint = null,
        @t_debug              char(1)  = 'N',
        @t_file               varchar(14) = null,
        @t_from               varchar(30) = null,
        @i_operacion          char(1)     = null,
        @i_modo               smallint    = null,
        @i_cliente            int         = null,
        @i_estado             catalogo    = null,
        @i_estado1            tinyint     = null,
        @i_codigo_externo     varchar(64) = null,
        @i_opcion             tinyint     = null,
        @i_opcion1            tinyint     = null,
        @i_abierta_cerrada    char(1)     = 'A',
        @i_tramite            int         = null)
as
declare  
        @w_today              datetime,     /* fecha del dia */ 
        @w_return             int,          /* valor que retorna */
        @w_sp_name            varchar(32),  /* nombre stored proc*/

        /* Variables de la operacion de Consulta */
        @w_custodia          int,
        @w_tipo              varchar(64),
        @w_descripcion       varchar(64),
        @w_codigo_externo    varchar(64),
        @w_producto          char(3),
        @w_moneda            tinyint,
        @w_valor_actual      money,
        @w_total             money,
        @w_cotizacion        money,
        @w_valor_mn          money,
        @w_valor_me          money,
        @w_total_op          money,
        @w_estado            catalogo,
        @w_ayer              datetime,
        @w_contador          smallint,
        @w_gar               varchar(64), 
        @w_gac               varchar(64), 
        @w_vcu               varchar(64), 
        @w_valor_total       money,
        @w_valor_totalp      money,
        @w_valor_otras_op    money,
        @w_garante           int,
        @w_nombre_garante    varchar(64),
        @w_abierta_cerrada   char(1),
        @w_adecuada          char(1), 
        @w_clasificacion     char(1),
        @w_poliza            varchar(20),
        @w_polizas           tinyint,
        @w                   tinyint,
        @w_poliza_aux        varchar(20),
        @w_poliza_1          varchar(20),
        @w_fec_avaluo        datetime

select @w_today   = getdate()
select @w_sp_name = 'sp_intcre04'
select @w_ayer    = convert(char(10),dateadd(dd,-1,getdate()),101)

/***********************************************************/
/* Codigos de Transacciones                                */

if (@t_trn <> 19524 and @i_operacion = 'S') 
begin
/* tipo de transaccion no corresponde */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file, 
    @t_from  = @w_sp_name,
    @i_num   = 1901006
    return 1 
end

/* TOTAL DE GARANTIAS REGISTRADAS EN EL BANCO */

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

--      declare cursor_garantia insensitive cursor for /* HHO Mayo/2012    Migracion SYBASE 15 */
      declare cursor_garantia cursor for /* HHO Mayo/2012    Migracion SYBASE 15 */
       select distinct cu_codigo_externo,cu_tipo,cu_estado,gp_clasificacion,
              cu_descripcion,cu_valor_actual,cu_moneda,cu_abierta_cerrada,
              cu_adecuada_noadec,cu_garante,
              convert(char(10),cu_fecha_insp,101)
         from cu_custodia, cob_credito..cr_gar_propuesta
        where gp_deudor          = @i_cliente 
          and (gp_tramite = @i_tramite or @i_tramite is null)
          and cu_codigo_externo  = gp_garantia
          and cu_estado          not in ('A','C') -- No las Canceladas
          and cu_tipo     not like @w_vcu -- Excluir Valores en custodia
          and cu_abierta_cerrada = @i_abierta_cerrada
          and (cu_codigo_externo > @i_codigo_externo or @i_codigo_externo is null)
        order by cu_codigo_externo,cu_estado

      -- CREACION DE LA TABLA TEMPORAL PARA LA CONSULTA
 
      create table #cu_seleccion3   (estado      char(1)     null, 
                                    clasificacion char (1)  null,
                                    tipo        varchar(64) null,
                                    custodia    varchar(64) null,
                                    descripcion varchar(64) null,
                                    valor_mn    money       null,
                                    moneda      tinyint     null,
                                    valor_me    money       null,
                                    adecuada    char(1)     null,
                                    poliza       varchar(20) null,
                                    fec_avaluo   datetime   null)

      select @w_valor_total    = 0,
             @w_valor_totalp   = 0
            

      -- EXTRACCION DE DATOS

      open cursor_garantia
      fetch cursor_garantia into @w_codigo_externo,@w_tipo,@w_estado,
                          @w_clasificacion,@w_descripcion,@w_valor_actual,
                          @w_moneda,@w_abierta_cerrada,@w_adecuada,@w_garante,
                          @w_fec_avaluo

      if (@@FETCH_STATUS = -1)    --  No existen garantias
      begin
        --print "No existen garantias para este cliente"
         close cursor_garantia
         select estado, 
                clasificacion,
                tipo,
                custodia,
                descripcion,
                valor_mn,
                moneda,
                valor_me,
                adecuada,
                poliza,
                fec_avaluo 
	 from #cu_seleccion3
         return 0
      end

      select @w_contador = 1   -- Para ingresar solo 20 registros
      while (@@FETCH_STATUS = 0)  and (@w_contador <=20) -- Lazo de busqueda
      begin
         select @w_contador = @w_contador + 1


         select @w_cotizacion = cz_valor 
           from cob_credito..cr_cotizacion
          where cz_moneda = @w_moneda
            and cz_fecha in (select max(cz_fecha)
                               from cob_credito..cr_cotizacion
                              where cz_fecha <= @w_today
                                and cz_moneda = @w_moneda)

         if @w_cotizacion = null or @w_cotizacion = 0
            select @w_valor_mn = @w_valor_actual,
                   @w_valor_me = 0
         else
            select @w_valor_mn = @w_valor_actual * @w_cotizacion,
                   @w_valor_me = @w_valor_actual

         if @w_garante is not null 
         begin
            select @w_nombre_garante= p_p_apellido+p_s_apellido+en_nombre
              from cobis..cl_ente
             where en_ente = @w_garante
            select @w_descripcion   = '[' + convert(varchar(10),@w_garante) + '] '+
                                      @w_nombre_garante 
         end                        
 
         select @w_polizas = count(*)
           from cu_poliza
          where po_codigo_externo = @w_codigo_externo
 
         select @w_poliza = ''
         select @w = 0
         
         while @w < @w_polizas 
         begin 
            select @w = @w + 1 
            select @w_poliza_aux = ''

            select @w_poliza_aux = po_poliza 
              from cu_poliza
             where po_codigo_externo = @w_codigo_externo
               and po_poliza != @w_poliza_1   
            order by po_poliza

            select @w_poliza_1 = @w_poliza_aux

            if @w_poliza_aux is null
               break
            select @w_poliza = ltrim(@w_poliza + '  ' + @w_poliza_aux)
         end

         if @w_tipo = 'GARGPE' 
            select @w_fec_avaluo = null

         /* Se suman los valores al gran total */
         select @w_valor_totalp      = @w_valor_totalp+@w_valor_mn

         /* Insercion en la tabla temporal     */
         insert into #cu_seleccion3 (estado,clasificacion,tipo,custodia,
                                    descripcion,valor_mn,moneda,valor_me,
                                    adecuada,poliza,fec_avaluo)
                    values(@w_estado,@w_clasificacion,@w_tipo,@w_codigo_externo,
                           @w_descripcion,@w_valor_mn,@w_moneda,@w_valor_me,
                           @w_adecuada,@w_poliza,@w_fec_avaluo)

         select @w_estado         = null,
                @w_clasificacion  = null,
                @w_codigo_externo = null,
                @w_descripcion    = null,
                @w_valor_mn       = null,
                @w_valor_me       = null,
                @w_moneda         = null,   
                @w_abierta_cerrada = null,
                @w_poliza          = null,
                @w_adecuada        = null,
                @w_fec_avaluo      = null,
                @w_cotizacion      = null


         fetch cursor_garantia into @w_codigo_externo,@w_tipo,@w_estado,
                               @w_clasificacion,@w_descripcion,@w_valor_actual,
                               @w_moneda,@w_abierta_cerrada,@w_adecuada,
                               @w_garante,@w_fec_avaluo

      end   --  FIN DEL WHILE

      select @w_valor_total       = @w_valor_total+@w_valor_totalp
      select @w_valor_totalp      = 0


      if (@@FETCH_STATUS = -2)  -- ERROR DEL CURSOR
      begin
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file, 
         @t_from  = @w_sp_name,
         @i_num   = 1909001 
         return 1 
      end
      close cursor_garantia
      deallocate cursor_garantia
      if @i_opcion = 1
         select estado, 
                clasificacion,
                tipo,
                custodia,
                descripcion,
                valor_mn,
                moneda,
                valor_me,
                adecuada,
                poliza,
                fec_avaluo
	 from #cu_seleccion3
      select @w_valor_total      
end
go