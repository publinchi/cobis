/****************************************************************/
/* ARCHIVO:              total_gar.sp                           */
/* Stored procedure:	 sp_total_gar	          	            */
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
/****************************************************************/

USE cob_custodia
go

IF OBJECT_ID('dbo.sp_total_gar') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.sp_total_gar
    IF OBJECT_ID('dbo.sp_total_gar') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.sp_total_gar >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.sp_total_gar >>>'
END
go
create proc sp_total_gar (
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
   @i_toperacion         varchar(4)  = null,
   @i_producto           catalogo  = null,
   @i_modo               smallint = null,
   @i_cliente            int = null, 
   @i_tipo_cust          varchar(64) = null,
   @i_codigo_externo     varchar(64) = null
)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_error              int,
   @w_retorno            int,
   @w_ayer               datetime 

select @w_today = getdate()
select @w_sp_name = 'sp_total_gar',
       @w_ayer = '01/01/1995'--convert(char(10),dateadd(dd,-1,getdate()),101)

/***********************************************************/
/* Codigos de Transacciones                                */
if (@t_trn <> 19704 and @i_operacion = 'S') or
   (@t_trn <> 19705 and @i_operacion = 'Z') 
begin
   /* tipo de transaccion no corresponde */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file, 
    @t_from  = @w_sp_name,
    @i_num   = 1901006
    return 1 
end
else
begin
   create table #temporal (moneda money, cotizacion money)
   /*insert into #temporal (moneda,cotizacion)
   select ct_moneda,ct_compra
   from cob_conta..cb_cotizacion
   group by ct_moneda
   having ct_fecha = max(ct_fecha)*/
 
end

if @i_operacion = 'S'
begin

    set rowcount 20

    if @i_modo = 1  -- TOTALES POR TIPO DE GARANTIA
       select distinct 'TIPO' = substring(cu_tipo,1,25),
             'DESCRIPCION' = substring(tc_descripcion,1,35),
             'TOTAL VALOR ACTUAL' = sum(cu_valor_actual * isnull(cotizacion,1))
    from cu_custodia
	inner join cu_cliente_garantia on cu_filial = cg_filial and cu_sucursal = cg_sucursal 
	inner join cu_tipo_custodia on cu_tipo  = cg_tipo_cust
	left join #temporal on moneda = cu_moneda
    where cg_ente     = @i_cliente
      and cu_custodia = cg_custodia 
     -- and cu_garante is null   --  Excluye garantes personales
      and cu_estado  <> 'C'
      and tc_tipo    = cu_tipo      
      and (cu_tipo > @i_tipo_cust or @i_tipo_cust is null)
    group by cu_tipo,tc_tipo,cg_tipo_cust
    order by cu_tipo

    else            -- CODIGO,DESCRIPCION Y MONTO DE UN TIPO DADO
       select distinct 'CODIGO' = cu_codigo_externo,
              'DESCRIPCION' = substring(cu_descripcion,1,40),
              'ESTADO' = cu_estado,
              'VALOR ACTUAL' = cu_valor_actual * isnull(cotizacion,1)
       from cu_custodia
	   inner join cu_cliente_garantia on cu_filial = cg_filial and cu_sucursal  = cg_sucursal and cu_tipo = cg_tipo_cust and cu_custodia = cg_custodia 
	   left join #temporal on moneda = cu_moneda
       where cg_ente      = @i_cliente
         and cg_tipo_cust = @i_tipo_cust
--         and cu_garante   is null/*ya estaba comentada la linea*/
         and cu_estado    <> 'C'
         and (cu_codigo_externo > @i_codigo_externo or @i_codigo_externo = null)
       order by cu_codigo_externo
end

if @i_operacion = 'Z'
begin
   if @i_modo = 0
         exec @w_retorno = cob_credito..sp_con_riesgo
         @t_trn =  21839, 
         @i_cliente   = @i_cliente,
         @i_modo = 0 
		 
   else
         exec @w_retorno = cob_credito..sp_con_riesgo
         @t_trn =  21839, 
         @i_cliente   = @i_cliente,
         @i_producto = @i_producto,
         @i_toperacion = @i_toperacion,
         @i_modo = 1 

         if @w_retorno <> 0
         begin
            /*  Error en consulta de registro */
             exec cobis..sp_cerror
              @t_debug = @t_debug,
              @t_file  = @t_file, 
              @t_from  = @w_sp_name,
              @i_num   = 1909002
              return 1 
         end
end
go
--EXEC sp_procxmode 'dbo.sp_total_gar', 'unchained'
go
IF OBJECT_ID('dbo.sp_total_gar') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.sp_total_gar >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.sp_total_gar >>>'
go

