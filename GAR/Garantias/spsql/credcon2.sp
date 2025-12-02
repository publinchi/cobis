/*************************************************************************/
/*   Archivo:              credcon2.sp                                   */
/*   Stored procedure:     sp_credcon2                                   */
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
IF OBJECT_ID('dbo.sp_credcon2') IS NOT NULL
    DROP PROCEDURE dbo.sp_credcon2
go
create procedure dbo.sp_credcon2(
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
        @i_estado             char(1)  = null,
        @i_cliente            int      = null,
        @i_grupo              int      = null,
        @o_total              money    = null out,
        @o_total_op           money    = null out
)
as
declare  
        @w_today              datetime,     /* fecha del dia */ 
        @w_return             int,          /* valor que retorna */
        @w_sp_name            varchar(32),  /* nombre stored proc*/

        /* Variables de la operacion de Consulta */
        @w_total_op money,
        @w_total money,
        @w_ayer datetime,
        @w_scu varchar(64)

select @w_today = getdate()
select @w_sp_name = 'sp_credcon2'

/***********************************************************/
/* Codigos de Transacciones                                */
if (@t_trn <> 19425 and @i_operacion = 'S') 
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
   insert into #temporal (moneda,cotizacion)
select ct_moneda,ct_compra
   from cob_conta..cb_cotizacion
   where ct_fecha =(SELECT max(ct_fecha) FROM cob_conta..cb_cotizacion)
   GROUP BY ct_moneda,ct_compra
end

if @i_operacion = 'S'
begin

   select @w_scu = pa_char + '%' -- TIPOS DE GARANTIA SIMPLE CUSTODIA EXCLUIR
   from cobis..cl_parametro
   where pa_producto = 'GAR'
     and pa_nemonico = 'SCU'

   select @w_ayer = convert(char(10),dateadd(dd,-1,@s_date),101)
   if @i_estado = 'P' or @i_estado = 'V' -- (P)ropuestas o (V)igentes 
   begin
      select @w_total = sum(cu_valor_actual*isnull(cotizacion,1))
      from cu_custodia
	  inner join cu_cliente_garantia on cu_filial = cg_filial and cu_sucursal = cg_sucursal and cu_tipo = cg_tipo_cust and cu_custodia = cg_custodia
	  left join #temporal on moneda = cu_moneda
      where (cg_ente = @i_grupo or
             cg_ente in (select en_ente from cobis..cl_ente
                          where en_grupo = @i_grupo) and
             (cg_ente <> @i_cliente or @i_cliente is null)) 
        and cu_garante  is null
        and cu_estado   <> 'C' -- (C)ancelada
        --and co_fecha     = @w_ayer
        and cu_estado    = @i_estado 
        and cu_tipo not like @w_scu -- Excluir simples custodias

      select @w_total_op = sum((1-floor(power(cos(gp_monto_exceso),2))) * gp_monto_exceso + floor(power(cos(gp_monto_exceso),2)) * tr_monto * isnull(cotizacion,1))
      from cu_custodia
	  inner join cu_cliente_garantia on cg_filial = cu_filial and cg_sucursal = cu_sucursal and cg_tipo_cust = cu_tipo and cg_custodia = cu_custodia
	  inner join cob_credito..cr_gar_propuesta on gp_garantia = cu_codigo_externo
	  inner join cob_credito..cr_tramite on gp_tramite = tr_tramite
      left join cob_credito..cr_deudores on tr_tramite = de_tramite
      left join #temporal on moneda = tr_moneda 
      where de_rol         =  'C'          -- (C)odeudor
        and tr_tipo        in ('O','R')    -- (O)riginales,(R)enovaciones
        --and co_fecha       =  @w_ayer
        and cu_estado      =  @i_estado 
        and cu_tipo not like @w_scu -- Excluir simples custodias
        and cu_garante     is  null
        and (cg_ente = @i_grupo or
             cg_ente in (select en_ente from cobis..cl_ente
                         where en_grupo = @i_grupo) and
             (cg_ente <> @i_cliente or @i_cliente is null)) 

      select @w_total,@w_total_op
   end

   if @i_estado = 'E' -- (E)xcepcionadas
   begin
      select @w_total = sum(cu_valor_actual*isnull(cotizacion,1))
      from cu_custodia
	  inner join cu_cliente_garantia on cu_filial = cg_filial and cu_sucursal = cg_sucursal and cu_tipo = cg_tipo_cust and cu_custodia = cg_custodia
	  inner join cob_credito..cr_excepciones on cu_codigo_externo = ex_garantia
	  left join #temporal on moneda = cu_moneda
      where (cg_ente = @i_grupo or
             cg_ente in (select en_ente from cobis..cl_ente
                         where en_grupo = @i_grupo)  and
             (cg_ente <> @i_cliente or @i_cliente is null)) 
        and cu_garante       is null
        and cu_estado        <> 'C' -- (C)ancelada
        --and co_fecha          = @w_ayer
        and cu_estado         = @i_estado 
        and cu_tipo not like @w_scu -- Excluir simples custodias
        
      select @w_total_op = sum((1-floor(power(cos(gp_monto_exceso),2))) * gp_monto_exceso + floor(power(cos(gp_monto_exceso),2)) * tr_monto * isnull(cotizacion,1))
      from cu_custodia
	  inner join cu_cliente_garantia on cg_filial = cu_filial and cg_sucursal = cu_sucursal and cg_tipo_cust = cu_tipo and cg_custodia = cu_custodia
	  inner join cob_credito..cr_excepciones on cu_codigo_externo = ex_garantia
	  inner join cob_credito..cr_gar_propuesta on gp_garantia = cu_codigo_externo
	  inner join cob_credito..cr_tramite on gp_tramite = tr_tramite
      left join cob_credito..cr_deudores on tr_tramite = de_tramite
	  left join #temporal on moneda = tr_moneda
      where de_rol =  'C'          -- (C)odeudor
        and tr_tipo in ('O','R')    -- (O)riginales,(R)enovaciones
        --and co_fecha =  @w_ayer 
        and cu_estado <> 'C' -- (C)ancelada
        and cu_garante is null
        and cu_tipo not like @w_scu -- Excluir simples custodias
        and (cg_ente      = @i_grupo or
             cg_ente in (select en_ente from cobis..cl_ente
                         where en_grupo = @i_grupo) and
             (cg_ente <> @i_cliente or @i_cliente is null)) 

      select @w_total,@w_total_op
   end

   if @i_estado is null -- TOTAL GENERAL 
   begin
      select @w_total = sum(cu_valor_actual*isnull(cotizacion,1))
      from cu_custodia
	  inner join cu_cliente_garantia on cu_filial = cg_filial and cu_sucursal = cg_sucursal and cu_tipo = cg_tipo_cust and cu_custodia = cg_custodia
	  left join #temporal on moneda = cu_moneda
      where (cg_ente = @i_grupo or
             cg_ente in (select en_ente from cobis..cl_ente
                         where en_grupo = @i_grupo) and
             (cg_ente <> @i_cliente or @i_cliente is null)) 
        and cu_garante  is null
        and cu_estado   <> 'C' -- (C)ancelada
        --and co_fecha     = @w_ayer
        and cu_tipo not like @w_scu -- Excluir simples custodias

      select @w_total_op = sum((1-floor(power(cos(gp_monto_exceso),2))) * gp_monto_exceso + floor(power(cos(gp_monto_exceso),2)) * tr_monto * isnull(cotizacion,1))
      from cu_custodia
	  inner join cu_cliente_garantia on cg_filial = cu_filial and cg_sucursal = cu_sucursal and cg_tipo_cust = cu_tipo and cg_custodia = cu_custodia
	  inner join cob_credito..cr_gar_propuesta on gp_garantia =  cu_codigo_externo
	  inner join cob_credito..cr_tramite on gp_tramite = tr_tramite
      left join cob_credito..cr_deudores on tr_tramite = de_tramite
      left join #temporal on moneda = tr_moneda 
      where de_rol      =  'C'          -- (C)odeudor
        and tr_tipo     in ('O','R')    -- (O)riginales,(R)enovaciones
        --and co_fecha    =  @w_ayer
        and cu_estado   <> 'C' -- (C)ancelada
        and cu_garante is  null
        and cu_tipo not like @w_scu -- Excluir simples custodias
        and (cg_ente= @i_grupo or
             cg_ente in (select en_ente from cobis..cl_ente
                         where en_grupo = @i_grupo) and
             (cg_ente <> @i_cliente or @i_cliente is null)) 

      select @w_total,@w_total_op
   end
end
return 0
go