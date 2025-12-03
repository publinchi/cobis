/*************************************************************************/
/*   Archivo:              monto_garantia.sp                             */
/*   Stored procedure:     sp_monto_garantia                             */
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
IF OBJECT_ID('dbo.sp_monto_garantia') IS NOT NULL
    DROP PROCEDURE dbo.sp_monto_garantia
go
create proc dbo.sp_monto_garantia (
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
   @i_tipo               descripcion = null,
   @i_filial             tinyint = null,
   @i_cliente            int = null,
   @i_moneda             tinyint = null,
   @i_opcion             tinyint = null
)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_error              int,
   @w_grupo              int

select @w_today = convert(varchar(10),getdate(),101)
select @w_sp_name = 'sp_monto_garantia'

/***********************************************************/
/* Codigos de Transacciones                                */
if (@t_trn <> 19224 and @i_operacion = 'S') 
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
   group by ct_moneda, ct_fecha, ct_compra
   having ct_fecha = max(ct_fecha)
end

if @i_operacion = 'S'
begin
      set rowcount 20

      if @i_opcion = 1 -- MONTO DE LAS GARANTIAS DEL CLIENTE
      begin
         select cu_tipo,sum(cu_valor_actual)*isnull(cotizacion,1),cu_moneda,sum(cu_valor_actual)
         from cu_custodia
		 inner join cu_cliente_garantia ccg on cg_filial = cu_filial and cg_sucursal = cu_sucursal
			and cg_tipo_cust = cu_tipo and cg_custodia = cu_custodia
		 left join #temporal on moneda = cu_moneda 
         where cu_filial     = @i_filial
           and cg_ente       = @i_cliente
           and cu_estado in ('V','E') -- (V)igente,(E)xcepcionada
         --and co_fecha = convert(char(10),dateadd(dd,-1,getdate()),101)
           and ((cu_tipo > @i_tipo or
                (cu_tipo = @i_tipo and cu_moneda > @i_moneda)) or
                 @i_tipo is null)
          group by cu_tipo,cu_moneda,cotizacion
          order by cu_tipo,cu_moneda,cotizacion
      end
      
      if @i_opcion = 2 -- MONTO DE LAS GARANTIAS DE LOS MIEMBROS DEL GRUPO EC.
      begin 
         select @w_grupo = en_grupo 
         from cobis..cl_ente
         where en_ente = @i_cliente

         select cu_tipo,sum(cu_valor_actual)*isnull(cotizacion,1),
                cu_moneda,sum(cu_valor_actual)
         from cu_custodia
		 inner join cu_cliente_garantia ccg on cg_filial = cu_filial and cg_sucursal = cu_sucursal
			and cg_tipo_cust = cu_tipo and cg_custodia = cu_custodia
		 left join #temporal on moneda = cu_moneda 
          where cu_filial = @i_filial
            and cu_estado in ('V','E') -- (V)igente,(E)xcepcionada
            and cg_ente in (select en_ente
                            from cobis..cl_ente
                            where en_grupo = @w_grupo
                              and en_ente <> @i_cliente)
            --and co_fecha = convert(char(10),dateadd(dd,-1,getdate()),101) 
            and ((cu_tipo > @i_tipo or
                 (cu_tipo = @i_tipo and cu_moneda > @i_moneda)) or
                 @i_tipo is null)
          group by cu_tipo,cu_moneda,cotizacion
          order by cu_tipo,cu_moneda,cotizacion
      end

      if @i_opcion = 3 -- TOTAL DEL CLIENTE Y DEL GRUPO
      begin 
         select @w_grupo = en_grupo 
         from cobis..cl_ente
         where en_ente = @i_cliente

         select sum(cu_valor_actual)*isnull(cotizacion,1)
         from cu_custodia
		 inner join cu_cliente_garantia ccg on cg_filial = cu_filial and cg_sucursal = cu_sucursal
			and cg_tipo_cust = cu_tipo and cg_custodia = cu_custodia
		 left join #temporal on moneda = cu_moneda 
         where cu_filial = @i_filial
           and cu_estado in ('V','E') -- (V)igente,(E)xcepcionada
           and cg_ente in (select en_ente
                           from cobis..cl_ente
                           where en_grupo = @w_grupo)
         --and co_fecha = convert(char(10),dateadd(dd,-1,getdate()),101)
       end

       if @@rowcount = 0
       begin
           if @i_tipo is null
              select @w_error = 1901003
           else
              select @w_error = 1901004

           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file, 
           @t_from  = @w_sp_name,
           @i_num   = @w_error
           return 1 
       end
end
go