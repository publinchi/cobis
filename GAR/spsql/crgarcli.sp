/*************************************************************************/
/*   Archivo:              crgarcli.sp                                   */
/*   Stored procedure:     sp_crgarcli                                   */
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
IF OBJECT_ID('dbo.sp_crgarcli') IS NOT NULL
    DROP PROCEDURE dbo.sp_crgarcli
go
create proc sp_crgarcli  (
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
   @i_tipo               tinyint = null,
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
   @w_estado             char(1) 

select @w_today = getdate()
select @w_sp_name = 'sp_crgarcli'

/***********************************************************/
/* Codigos de Transacciones                                */
if (@t_trn <> 19334 and @i_operacion = 'S') 
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

   if @i_tipo = 1 or @i_tipo = 2 -- VIGENTES O PROPUESTAS
   begin
      if @i_tipo = 1 -- VIGENTES 
         select @w_estado = 'V'
      else
         select @w_estado = 'P'

      select 'TIPO'= cu_tipo,'NUMERO' = cu_custodia,
             'DESCRIPCION'= cu_descripcion, 
             'VALOR MN' =  cu_valor_actual* isnull(a.cotizacion,1), 
             'OTRAS OPER' = sum(isnull(gp_monto_exceso,0) + (tr_monto * isnull(b.cotizacion,1)) * isnull(gp_monto_exceso-gp_monto_exceso,1)),
             'MONEDA' = cu_moneda,
             'VALOR ME' = cu_valor_actual*(1-isnull(a.cotizacion-a.cotizacion,1))
      from cu_custodia
	  inner join cu_cliente_garantia on cu_filial = cg_filial and cu_sucursal = cg_sucursal and cu_tipo = cg_tipo_cust and cu_custodia = cg_custodia 
	  left join cob_credito..cr_gar_propuesta on gp_garantia = cu_codigo_externo
	  left join cob_credito..cr_tramite on gp_tramite = tr_tramite
	  left join cob_credito..cr_deudores on de_tramite = tr_tramite
	  left join #temporal a on a.moneda = cu_moneda
	  left join #temporal b on b.moneda = tr_moneda
      where cg_ente            = @i_cliente
        and cu_garante        is null   --  Excluye garantes personales
        and cu_estado          = @w_estado
        --and a.co_fecha         = dateadd(dd,-1,getdate())
        and de_rol             = 'C'    --  Codeudor 
        --and b.co_fecha         = dateadd(dd,-1,getdate()) 
        and (cu_codigo_externo > @i_codigo_externo or @i_codigo_externo = null)
     group by cu_tipo, cu_moneda,a.cotizacion
    -- order by cu_tipo, cu_moneda,a.cotizacion 
    order by cu_tipo, cu_custodia, cu_moneda,a.cotizacion /* HHO Mayo/2012    Migracion SYBASE 15 */

     if @@rowcount = 0 
        select @w_error = 19010003
     else
        select @w_error = 19010004
    end

     if @i_tipo = 3 --(E)xcepcionadas
     begin
         select @w_estado = 'E'

         select 'TIPO'= cu_tipo,'NUMERO' = cu_custodia,
             'DESCRIPCION'= cu_descripcion, 
             'VALOR MN' =  cu_valor_actual * isnull(a.cotizacion,1),
             'OTRAS OPER' = sum(isnull(gp_monto_exceso,0) + (tr_monto * isnull(b.cotizacion,1)) * isnull(gp_monto_exceso-gp_monto_exceso,1)),
             'MONEDA' = cu_moneda,
             'VALOR ME' = cu_valor_actual*(1-isnull(a.cotizacion-a.cotizacion,1))
      from cu_custodia
	  inner join cu_cliente_garantia on cu_filial = cg_filial and cu_sucursal = cg_sucursal and cu_tipo = cg_tipo_cust and cu_custodia = cg_custodia 
	  left join cob_credito..cr_gar_propuesta on gp_garantia = cu_codigo_externo
	  left join cob_credito..cr_tramite on gp_tramite = tr_tramite
	  left join cob_credito..cr_deudores on de_tramite = tr_tramite
	  left join cob_credito..cr_excepciones on ex_garantia = cu_codigo_externo
	  left join #temporal a on a.moneda = cu_moneda
	  left join #temporal b on b.moneda = tr_moneda
      where cg_ente = @i_cliente
        and cu_garante is null   --  Excluye garantes personales
        and cu_estado = @w_estado
        --and a.co_fecha = dateadd(dd,-1,getdate())
        and de_rol = 'C'    --  Codeudor 
        --and b.co_fecha         = dateadd(dd,-1,getdate()) 
        and (cu_codigo_externo > @i_codigo_externo or @i_codigo_externo = null)
      group by cu_tipo,cg_tipo_cust
      order by cu_tipo,cg_tipo_cust

     if @@rowcount = 0 
        select @w_error = 1901003
     else
        select @w_error = 1901004
    end
end
return 0

ERROR:
           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file, 
           @t_from  = @w_sp_name,
           @i_num   = @w_error
           return 1
go