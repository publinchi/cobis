/*************************************************************************/
/*   Archivo:              intcre02.sp                                   */
/*   Stored procedure:     sp_intcre02                                   */
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
IF OBJECT_ID('dbo.sp_intcre02') IS NOT NULL
    DROP PROCEDURE dbo.sp_intcre02
go
create procedure sp_intcre02(
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
        @i_tipo_ctz	      char(1) = 'B' , --C cotizacion de credito, B contabilidad
	@i_formato_fecha      tinyint	  = 101,		--II CMI 29Ene2007
	@i_gru		      char(1)     = 'N',			--TRugel 30/10/07
	@i_grupo	      int	  = null,
	@i_cliente_grupo      int	  = null
)
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
        @w_valor_totalp      money,
        @w_valor_total       money,
        @w_valor_otras_op    money,
        @w_garante           int,
        @w_nombre_garante    varchar(64),
        @w_abierta_cerrada   char(1),
        @w_adecuada          char(1),
        @w_clasificacion     char(1),
        @w_operacion         cuenta,
        @w_poliza            varchar(20),
        @w_polizas           tinyint,
        @w                   tinyint,
        @w_poliza_aux        varchar(20),
        @w_poliza_1          varchar(20),
        @w_fec_avaluo        datetime,
        @w_def_moneda	     tinyint,
        @w_fec_poliza	     datetime,			--CMI 26Ene2007
	@w_ente		     int,			--TRugel 30/10/07
	@w_nombre	     varchar(64)

select @w_today = @s_date
select @w_today = isnull(@w_today, fp_fecha)
from cobis..ba_fecha_proceso

select @w_sp_name = 'sp_intcre02'
select @w_ayer    = convert(char(10),dateadd(dd,-1,getdate()),101)

/***********************************************************/
/* Codigos de Transacciones                                */

if (@t_trn <> 19504 and @i_operacion = 'S') 
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

      -- CREACION DE LA TABLA TEMPORAL PARA LA CONSULTA
        create table #cu_seleccion2 (
	estado      char(1)     null, 
        clasificacion char(1)   null, 
        --tipo        varchar(64) null,
        custodia    varchar(64) null,
        descripcion varchar(64) null,
        valor_mn    money       null,
        moneda      tinyint     null,
        valor_me    money       null,
        situacion   char(1)     null,
        adecuada    char(1)     null,
        operacion   varchar(24) null,
        poliza      varchar(20) null,
        fec_avaluo  datetime null,
	fec_poliza  datetime    null,		 	--II CMI 26Ene2007
	ente	    int		null,			--TRugel 30/10/07
	nombre	    varchar(64)	null)


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
	
    select @i_codigo_externo = isnull(@i_codigo_externo, ' ')
    select @i_cliente_grupo = isnull(@i_cliente_grupo, 0)		--TRugel 10/30/07

    create table #tmpgar
    (codigo	varchar(64)    null,
     valor	money	       null,
     moneda     tinyint        null
    )

   create table #tmpcursor
	(
	tem_codigo_externo              varchar (64) null, 
	tem_tipo                        varchar (64) null, 
	tem_estado                      varchar (10) null, 
	tem_var  			varchar (2) null, 
	tem_descripcion                 varchar (255) null, 
	tem_valor_actual                money null, 
	tem_moneda                      tinyint null,  
	tem_abierta_cerrada             char(1) null, 
	tem_adecuada_noadec             char(1) null, 
	tem_garante                     int null, 
	tem_fecha_insp                  datetime null,
	tem_fecha_poliza		datetime	null,		--CMI 26Ene2007
	tem_ente			int	null,			--TRugel 30/10/07	
	tem_nombre	    		varchar(64)	null)

   if @i_gru = 'S'			--TRugel 30/10/07
   begin

      insert into #tmpgar
      select distinct cu_codigo_externo,cu_valor_actual,cu_moneda
      from cu_custodia c, cobis..cl_ente, cu_cliente_garantia, cob_custodia..cu_tipo_custodia 
      where en_grupo          = @i_grupo
        and cg_ente           = en_ente
        and cg_ente           <> @i_cliente 
	and cg_codigo_externo = cu_codigo_externo
	and cu_tipo           not like @w_vcu 
        and cu_tipo           <> '950'
        and cu_tipo 	      = tc_tipo
        and cu_garante         is null
	and cu_estado         <> 'A'
	and cu_estado         <> 'C'

      insert into #tmpcursor
	(tem_codigo_externo,
	tem_tipo,
	tem_estado,
	tem_var,
	tem_descripcion,
	tem_valor_actual,
	tem_moneda,
	tem_abierta_cerrada,
	tem_adecuada_noadec,
	tem_garante,
	tem_fecha_insp,
	tem_fecha_poliza,
	tem_ente,
	tem_nombre)
      select distinct cu_codigo_externo, cu_tipo,cu_estado,'a',
	     cu_descripcion, cu_valor_actual, cu_moneda, cu_abierta_cerrada,
	     cu_adecuada_noadec, cu_garante,
	     (select in_fecha_insp
              from cob_custodia..cu_inspeccion
              where in_codigo_externo = c.cu_codigo_externo),
	     (select max(po_fvigencia_fin)
              from cob_custodia..cu_poliza
              where po_codigo_externo = c.cu_codigo_externo
                and po_estado_poliza  = 'V'
	      group by po_codigo_externo),
	     cg_ente, en_nomlar
      from cu_custodia c, cobis..cl_ente, cu_cliente_garantia, cob_custodia..cu_tipo_custodia 
      where en_grupo          = @i_grupo
        and cg_ente           = en_ente
        and cg_ente           <> @i_cliente 
	and cg_codigo_externo = cu_codigo_externo
	and cu_tipo           not like @w_vcu 
        and cu_tipo           <> '950'
        and cu_tipo 	      = tc_tipo
        and cu_garante         is null
	and cu_estado         <> 'A'
	and cu_estado         <> 'C'
   end
   else
   begin   

      select @i_cliente_grupo = @i_cliente			--TRugel 10/30/07

      insert into #tmpgar
      select distinct cu_codigo_externo,cu_valor_actual,cu_moneda
      from cu_custodia, cu_cliente_garantia
      where cg_ente = @i_cliente 
      and cg_codigo_externo  = cu_codigo_externo
      and cu_estado   <>'A'
      and cu_estado   <>'C'
      and cu_tipo     not like @w_vcu -- Excluir Valores en custodia
      --IOR, 22/08/00, solo si cliente es principal
      and cg_principal = 'S'
      and cu_tipo <> '950'   --IICMI 21Mar2006 No se consideran garantias de encargo fiduciario solicitado por GZambrano

      insert into #tmpcursor
	(tem_codigo_externo,
	tem_tipo,
	tem_estado,
	tem_var,
	tem_descripcion,
	tem_valor_actual,
	tem_moneda,
	tem_abierta_cerrada,
	tem_adecuada_noadec,
	tem_garante,
	tem_fecha_insp,
	tem_fecha_poliza,					--CMI 26Ene2007
	tem_ente)
      select distinct cu_codigo_externo,cu_tipo,cu_estado,'a',
	cu_descripcion,cu_valor_actual,cu_moneda,cu_abierta_cerrada,
	cu_adecuada_noadec,cu_garante,
	(select in_fecha_insp
         from cob_custodia..cu_inspeccion
         where in_codigo_externo = c.cu_codigo_externo),
	(select max(po_fvigencia_fin)
         from cob_custodia..cu_poliza
         where po_codigo_externo = c.cu_codigo_externo
         and po_estado_poliza = 'V'
	 group by po_codigo_externo
	 
	 ),   ---- ame 03/15/2007
	 ----having po_poliza = max(po_poliza))		--CMI 26Ene2007
	--cu_fecha_insp		CMI 23Ene2007
	
	cg_ente
      from cu_custodia c, cu_cliente_garantia 
  	where cg_ente          = @i_cliente 
	and cg_codigo_externo        = cu_codigo_externo
	and cu_estado   <> 'A'
	and cu_estado   <> 'C'
	and cu_tipo     not like @w_vcu 
	and cg_principal = 'S'
        and cu_tipo <> '950'   --IICMI 21Mar2006 No se consideran garantias de encargo fiduciario solicitado por GZambrano

      insert into #tmpcursor
	(tem_codigo_externo,
	tem_tipo,
	tem_estado,
	tem_var,
	tem_descripcion,
	tem_valor_actual,
	tem_moneda,
	tem_abierta_cerrada,
	tem_adecuada_noadec,
	tem_garante,
	tem_fecha_insp,
	tem_fecha_poliza,					--CMI 26Ene2007
	tem_ente)
      select distinct cu_codigo_externo,cu_tipo,cu_estado,'a',
	cu_descripcion,cu_valor_actual,cu_moneda,cu_abierta_cerrada,
	cu_adecuada_noadec,cu_garante,
	(select in_fecha_insp
         from cob_custodia..cu_inspeccion
         where in_codigo_externo = c.cu_codigo_externo),
	(select max(po_fvigencia_fin)
         from cob_custodia..cu_poliza
         where po_codigo_externo = c.cu_codigo_externo
         and po_estado_poliza = 'V'
	 group by po_codigo_externo
	 
	 ),    --- ame 03/15/2007
	 ---having po_poliza = max(po_poliza))		--CMI 26Ene2007
	--cu_fecha_insp		CMI 23Ene2007
 	gp_deudor
      from cu_custodia c, cob_credito..cr_gar_propuesta
  	where gp_deudor          = @i_cliente 
	and gp_garantia        = cu_codigo_externo
	and cu_estado   <> 'A'
	and cu_estado   <> 'C'
	and cu_tipo     not like @w_vcu 
        and cu_tipo <> '950'   --IICMI 21Mar2006 No se consideran garantias de encargo fiduciario solicitado por GZambrano
	and cu_codigo_externo not in 
		(select distinct cu_codigo_externo
	 	from cu_custodia, cu_cliente_garantia 
	 	where cg_ente          = @i_cliente 
		and cg_codigo_externo        = cu_codigo_externo
		and cu_estado   <> 'A'
		and cu_estado   <> 'C'
		and cu_tipo     not like @w_vcu 
                and cu_tipo <> '950'   --IICMI 21Mar2006 No se consideran garantias de encargo fiduciario solicitado por GZambrano
		and cg_principal = 'S')
   end

   select @w_valor_total = isnull(sum(valor * cotizacion),0)
   from   #tmpgar a, #cr_cotiz b
   where  a.moneda = b.moneda


--CAB CARGAR EL CURSOR DEPEDIENDO SI ES LA PRIMERA VEZ O NO   

	if @i_codigo_externo=' '
	begin
--	      declare cursor_garantia insensitive cursor for /* HHO Mayo/2012    Migracion SYBASE 15 */
	      declare cursor_garantia cursor for /* HHO Mayo/2012    Migracion SYBASE 15 */
	      select distinct tem_codigo_externo, tem_tipo, tem_estado,
		tem_var,tem_descripcion, tem_valor_actual,
		tem_moneda, tem_abierta_cerrada, tem_adecuada_noadec,
		tem_garante, tem_fecha_insp, tem_fecha_poliza, tem_ente, tem_nombre
	      from #tmpcursor
        	order by tem_ente, tem_codigo_externo, tem_estado
	end
	else
	begin
	      declare cursor_garantia insensitive cursor for /* HHO Mayo/2012    Migracion SYBASE 15 */
	      select distinct tem_codigo_externo, tem_tipo, tem_estado,
		tem_var,tem_descripcion, tem_valor_actual,
		tem_moneda, tem_abierta_cerrada, tem_adecuada_noadec,
		tem_garante, tem_fecha_insp, tem_fecha_poliza, tem_ente, tem_nombre
	      from #tmpcursor
	      --where tem_codigo_externo>@i_codigo_externo			--TRugel 10/30/07
	      where (tem_ente = @i_cliente_grupo and (tem_codigo_externo > @i_codigo_externo or @i_codigo_externo = null)) or
                    (tem_ente > @i_cliente_grupo or tem_ente = null)
              order by tem_ente, tem_codigo_externo, tem_estado
	end

/*CAB ANTIGUA PARTE
      declare cursor_garantia cursor for
       select distinct tem_codigo_externo, tem_tipo, tem_estado,
		tem_var,tem_descripcion, tem_valor_actual,
		tem_moneda, tem_abierta_cerrada, tem_adecuada_noadec,
		tem_garante, tem_fecha_insp 
        from #tmpcursor
        order by tem_codigo_externo, tem_estado
*/

     select @w_valor_totalp = 0            
      -- EXTRACCION DE DATOS

      open cursor_garantia
      fetch cursor_garantia into @w_codigo_externo,@w_tipo,@w_estado,
                          @w_clasificacion,@w_descripcion,@w_valor_actual,
                          @w_moneda,@w_abierta_cerrada,@w_adecuada,@w_garante,
                          @w_fec_avaluo,
			  @w_fec_poliza, @w_ente, @w_nombre				--CMI 26Ene2007

      if (@@FETCH_STATUS = -1)    --  No existen garantias
      begin
        --print "No existen garantias para este cliente"
        close cursor_garantia
        select 	estado, 
		clasificacion, 
	        custodia,
        	descripcion,
	        valor_mn,
        	moneda,
	        valor_me,
        	situacion,
	        adecuada,
        	operacion,
	        poliza,
        	fec_avaluo,
		fec_poliza					--CMI 26Ene2007
	from #cu_seleccion2
        return 0
      end

      select @w_contador = 1   -- Para ingresar solo 20 registros
      while (@@FETCH_STATUS = 0)  and (@w_contador <=20) -- Lazo de busqueda
      begin
         select @w_contador = @w_contador + 1
      

	/* valor moneda extranjera */
	if @w_def_moneda <> @w_moneda
	  select @w_valor_me = @w_valor_actual 
	else
	  select @w_valor_me = null



	select @w_valor_mn = @w_valor_actual * cotizacion
	from 	#cr_cotiz
	where 	moneda = @w_moneda


         if @w_garante is not null 
         begin
            select @w_nombre_garante= p_p_apellido+p_s_apellido+en_nombre
              from cobis..cl_ente
             where en_ente = @w_garante
            select @w_descripcion   ='[' + convert(varchar(10),@w_garante) + ']' +
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
            select @w_poliza = ltrim(@w_poliza + ' ' + @w_poliza_aux)
         end


         if @w_abierta_cerrada = 'C'
         begin
            select @w_operacion = tr_numero_op_banco 
              from cob_credito..cr_tramite,cob_credito..cr_gar_propuesta
             where gp_garantia = @w_codigo_externo
               and gp_tramite  = tr_tramite
	   select @w_operacion = isnull ( @w_operacion,'')
         end
                        
         if @w_tipo = 'GARGPE' 
            select @w_fec_avaluo = null

         /* Se suman los valores al gran total */
         select @w_valor_totalp      = @w_valor_totalp+@w_valor_mn



         /* Insercion en la tabla temporal     */
         insert into #cu_seleccion2 (estado,
				     clasificacion,--tipo,
                                     custodia,
                                     descripcion,
				     valor_mn,
				     moneda,
				     valor_me,
                                     situacion,
				     adecuada,
				     operacion,
				     poliza,
				     fec_avaluo,
				     fec_poliza,
				     ente,
				     nombre)				--CMI 26Ene2007
                     values(@w_estado ,@w_clasificacion,--@w_tipo,
                           @w_codigo_externo,@w_descripcion,@w_valor_mn,
                           @w_moneda,@w_valor_me,@w_abierta_cerrada,
                           @w_adecuada,@w_operacion,@w_poliza,
			   @w_fec_avaluo, @w_fec_poliza, @w_ente, @w_nombre)			--CMI 29Ene2007


         select @w_operacion      = null,
                @w_estado         = null,
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
                @w_fec_poliza      = null,				--CMI 26Ene2007
                @w_cotizacion      = null

         fetch cursor_garantia into @w_codigo_externo,@w_tipo,@w_estado,
                             @w_clasificacion,@w_descripcion,@w_valor_actual,
                             @w_moneda,@w_abierta_cerrada,@w_adecuada,
                             @w_garante,@w_fec_avaluo,
 			     @w_fec_poliza, @w_ente, @w_nombre			--CMI 26Ene2007

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
      close cursor_garantia
      deallocate cursor_garantia



      if @i_opcion = 1
         select estado,
                custodia,
                descripcion,
                valor_mn,
                moneda,
                valor_me,
                situacion,
                adecuada,
                operacion,
                poliza,
                convert(varchar(10),fec_avaluo,@i_formato_fecha),
                convert(varchar(10),fec_poliza,@i_formato_fecha) 			--CMI 26Ene2007
           from #cu_seleccion2

      if @i_opcion = 2				--TRugel 30/10/07
         select estado,
                custodia,
                descripcion,
                valor_mn,
                moneda,
                valor_me,
                situacion,
                adecuada,
                operacion,
                poliza,
                convert(varchar(10),fec_avaluo,@i_formato_fecha),
                convert(varchar(10),fec_poliza,@i_formato_fecha),
		ente,
		nombre
           from #cu_seleccion2
     
      select @w_valor_total      

end
GO
