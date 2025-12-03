/*************************************************************************/
/*   Archivo:              credito4.sp                                   */
/*   Stored procedure:     sp_credito4                                   */
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
IF OBJECT_ID('dbo.sp_credito4') IS NOT NULL
    DROP PROCEDURE dbo.sp_credito4
go
create proc sp_credito4  (
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
   @i_operacion          char(1)  = null,
   @i_modo               smallint = null,
   @i_cliente            int = null, 
   @i_tipo_cust          varchar(64) = null,
   @i_codigo_externo     varchar(64) = null,
   @i_tipo_ctz           char(1) = "B" -- tipo de cotizacion C(credito) B(contabilidad)
)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_error              int,
   @w_vcu 		 varchar(64),
   @w_gar 		 varchar(64),
   @w_gac 		 varchar(64),
   @w_ayer               datetime ,
   @w_cotizacion         money,
   @w_moneda             tinyint,
   @w_codigo_externo     varchar(64),
   @w_tipo               varchar(20),
   @w_descripcion        varchar(30),
   @w_valor_mn           money,
   @w_valor_me           money,
   @w_valor_actual       money ,
   @w_contador           tinyint ,
   @w_valor              money,
   @w_def_moneda	 tinyint

select @w_today = getdate()
select @w_sp_name = 'sp_credito4',
       @w_ayer = '01/01/1995'--convert(char(10),dateadd(dd,-1,getdate()),101)

/***********************************************************/
/* Codigos de Transacciones                                */

if (@t_trn <> 19384 and @i_operacion = 'S') 
     
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

   select @w_gar = pa_char + '%' -- TIPOS GARANTIA 
     from cobis..cl_parametro
    where pa_producto = 'GAR'
      and pa_nemonico = 'GAR'

   select @w_vcu = pa_char + '%' -- TIPOS VALORES EN CUSTODIA
     from cobis..cl_parametro
    where pa_producto = 'GAR'
      and pa_nemonico = 'VCU'

   select @w_gac = pa_char + '%' -- TIPOS GARANTIAS AL CANJE 
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
      insert into #cr_cotiz (moneda, cotizacion)
      values (@w_def_moneda, 1)


  if @i_modo = 1  -- TOTALES POR TIPO DE GARANTIA
  begin
    create table #consulta (tipo         varchar(20) null,
                            descripcion  varchar(30) null,
                            valor        money   null)

/*
/* Comentado hay garantías no asociadas en la cr_gar_propuesta JMM 06sep04*/
     declare consulta cursor for
     select distinct cu_tipo,tc_descripcion,cu_codigo_externo,cu_moneda,
                     cu_valor_actual
     from cu_custodia,
          cob_credito..cr_gar_propuesta,cu_tipo_custodia
     where gp_deudor          = @i_cliente
     and   gp_garantia        = cu_codigo_externo
      --and cu_garante        is null   --  Excluye garantes personales
     and   cu_estado     not in ('C','A')
     and   cu_tipo       not like @w_vcu -- Excluir simples custodias
     and tc_tipo            = cu_tipo      
     order by cu_tipo,cu_codigo_externo

*/



--     declare consulta insensitive cursor for /* HHO Mayo/2012    Migracion SYBASE 15 */
     declare consulta cursor for /* HHO Mayo/2012    Migracion SYBASE 15 */
     select distinct cu_tipo,tc_descripcion,cu_codigo_externo,cu_moneda,
                     cu_valor_actual
     from cu_custodia, cu_tipo_custodia, cu_cliente_garantia
     where cg_ente = @i_cliente 
     and   cg_codigo_externo        = cu_codigo_externo
     and   cu_estado     not in ('C','A')
     and   cu_tipo       not like @w_vcu -- Excluir simples custodias
     and tc_tipo            = cu_tipo      
     order by cu_tipo,cu_codigo_externo



   
      -- EXTRACCION DE DATOS

      open consulta
      fetch consulta  into @w_tipo,@w_descripcion,@w_codigo_externo,@w_moneda,
                           @w_valor_actual


      while @@FETCH_STATUS != -1
      begin
         if (@@FETCH_STATUS = -2)    --  No existen garantias
         begin
           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file, 
           @t_from  = @w_sp_name,
           @i_num   = 1909001 
           close consulta
	   deallocate consulta
           select tipo, descripcion, valor
           from #consulta
           return 1 
         end

      
	 if @w_moneda <> @w_def_moneda
	    select @w_valor_me = @w_valor_actual
	 else
	    select @w_valor_me = 0

         select @w_valor_mn = @w_valor_actual * cotizacion
	 from   #cr_cotiz
	 where  moneda = @w_moneda

         insert into  #consulta (tipo,descripcion,valor)
         values(@w_tipo,@w_descripcion,@w_valor_mn)



         fetch consulta into @w_tipo,@w_descripcion,@w_codigo_externo,@w_moneda,
                           @w_valor_actual

      end  --While

      deallocate consulta

      -- envio de resultados al front-end 
      set rowcount 20
      select tipo, descripcion, sum(valor)
      from #consulta
      where (tipo > @i_tipo_cust or @i_tipo_cust is null)
      group by tipo, descripcion
      order by tipo, descripcion /* HHO Mayo/2012    Migracion SYBASE 15 */
      set rowcount 0

    end
    else            -- CODIGO,DESCRIPCION Y MONTO DE UN TIPO DADO
    begin
       set rowcount 20
-- IOR, 22/08/2000,  modifico query para que salgan todas las gtias del cliente
-- y no solo las que estan asociadas a operaciones
       select distinct 'CODIGO' = cu_codigo_externo,
              'DESCRIPCION' = cu_descripcion,
              'ESTADO' = cu_estado,
              'VALOR ACTUAL' = cu_valor_actual * isnull(cotizacion,1)
        from  cu_custodia
		inner join cu_cliente_garantia on cu_codigo_externo  = cg_codigo_externo
		left join #cr_cotiz on moneda = cu_moneda
		--IOR cob_credito..cr_gar_propuesta 
       where cg_ente = @i_cliente
         and cu_tipo      = @i_tipo_cust
         --and cu_garante   is null
         and cu_estado    not in ('C','A')
         and cu_tipo      not like @w_vcu -- Excluir simples custodias
         and (cu_codigo_externo > @i_codigo_externo or @i_codigo_externo = null)
       order by cu_codigo_externo

       set rowcount 0
      
    end
end
go