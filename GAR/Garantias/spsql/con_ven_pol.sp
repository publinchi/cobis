/*************************************************************************/
/*   Archivo:              con_ven_poliza.sp                             */
/*   Stored procedure:     sp_con_ven_poliza                             */
/*   Base de datos:        cob_custodia                                  */
/*   Producto:             Garantias                                     */
/*   Disenado por:         TEAM SENTINEL PRIME                           */
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
/*                             MODIFICACION                              */
/*    FECHA               AUTOR                     RAZON                */
/*    Marzo/2019          TEAM SENTINEL PRIME       emision inicial      */
/*                                                                       */
/*************************************************************************/

USE cob_custodia
GO

IF OBJECT_ID('dbo.sp_con_ven_poliza') IS NOT NULL
    DROP PROCEDURE dbo.sp_con_ven_poliza
go

create proc dbo.sp_con_ven_poliza(    
        @t_trn		int,
        @i_fechai       datetime = null,
        @i_fechaf       datetime = null,
        @i_sucursal 	smallint=null,
        @i_modo		int=null,
        @i_custodia	int=null,
        @i_poliza	varchar(20)=null

	) 
as

 set rowcount 20
if @i_modo=0

   begin

      select 
      "Garantia"=cu_custodia,
      "Poliza" =po_poliza,
      "Monto Poliza"=po_monto_poliza,
      "Fecha vencimiento"=convert(varchar(10),po_fvigencia_fin,101) ,
      "Cobertura"= substring(d.valor,1,20),   
      "Aseguradora"= substring(b.valor,1,30)


     from cob_custodia..cu_poliza,
          cob_custodia..cu_custodia,
          cobis..cl_tabla a,
          cobis..cl_catalogo b,
          cobis..cl_tabla c,
          cobis..cl_catalogo d
     where 
      a.tabla           = 'cu_des_aseguradora'
      and a.codigo          = b.tabla
      and b.codigo          = po_aseguradora 
      and c.tabla           = 'cu_cob_poliza'
      and c.codigo          = d.tabla
      and d.codigo          = po_cobertura 
      and cu_codigo_externo=po_codigo_externo
      and cu_estado='V'

      and cu_sucursal=@i_sucursal
      and convert(varchar(10),po_fvigencia_fin,101) between @i_fechai and @i_fechaf
      order by cu_custodia
end


if @i_modo=1
   begin
      select 
      "Garantia"=cu_custodia,
      "Poliza" =po_poliza,
      "Monto Poliza"=po_monto_poliza,
      "Fecha vencimiento"=convert(varchar(10),po_fvigencia_fin,101) ,
      "Cobertura"= substring(d.valor,1,20),   
      "Aseguradora"= substring(b.valor,1,30)


     from cob_custodia..cu_poliza,
          cob_custodia..cu_custodia,
          cobis..cl_tabla a,
          cobis..cl_catalogo b,
          cobis..cl_tabla c,
          cobis..cl_catalogo d
     where 
      a.tabla           = 'cu_des_aseguradora'
      and a.codigo          = b.tabla
      and b.codigo          = po_aseguradora 
      and c.tabla           = 'cu_cob_poliza'
      and c.codigo          = d.tabla
      and d.codigo          = po_cobertura 
      and cu_codigo_externo=po_codigo_externo
      and cu_estado='V'

      and cu_sucursal=@i_sucursal
      and convert(varchar(10),po_fvigencia_fin,101) between @i_fechai and @i_fechaf
      and (
            (cu_custodia > @i_custodia )
             or (cu_custodia=@i_custodia and po_poliza>@i_poliza)
          )

      order by cu_custodia,po_poliza
end


return 0
go