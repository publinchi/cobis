/*************************************************************************/
/*   Archivo:              con_garante.sp                                */
/*   Stored procedure:     sp_con_garante                                */
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

IF OBJECT_ID('dbo.sp_con_garante') IS NOT NULL
   drop  PROC dbo.sp_con_garante
go

create procedure dbo.sp_con_garante  
(
   @s_ssn            int         = null,
   @s_date           datetime    = null,
   @s_user           login       = null,
   @s_term           descripcion = null,
   @s_corr           char(1)     = null,
   @s_ssn_corr       int         = null,
   @s_ofi            smallint    = null,
   @s_rol		     tinyint     = null,	--II CMI 02Dic2006
   @t_rty            char(1)     = null,
   @t_trn            smallint    = null,
   @t_debug          char(1)     = 'N',
   @t_file           varchar(14) = null,
   @t_from           varchar(30) = null,
   @i_operacion      char(1)     = null,
   @i_modo           smallint    = null,
   @i_ente           int         = null,
   @i_filial 		 tinyint     = null,
   @i_sucursal		 smallint    = null,
   @i_tipo_cust		 varchar(64) = null,
   @i_custodia 		 int         = null,
   @i_tramite        int         = null,
   @i_estado		 tinyint     =null
)
as



declare
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_error              int

select @w_sp_name = 'sp_con_garante'


/***********************************************************/
/* Codigos de Transacciones                                */

if (@t_trn <> 19184 and @i_operacion = 'S') 
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

    if @i_tramite is null
    begin 
      set rowcount 20

      select 'TRAMITE' = tr_tramite,
			 --'PRODUCTO' = tr_producto,
             'DEUDOR' = de_cliente,
			 'NOMBRE' = en_nombre + ' ' + p_p_apellido + ' ' + p_s_apellido,
             'TIPO OPERACION' = tr_toperacion,
             'NUM OPERACION' = tr_numero_op_banco,
             'VALOR ML' = isnull(tr_monto,0)*isnull(cotizacion,1),
             'ESTADO GARANTIA' = cu_estado
      from cu_custodia
	  inner join cob_credito..cr_gar_propuesta on gp_garantia = cu_codigo_externo
	  inner join cob_credito..cr_tramite on tr_tramite = gp_tramite
      inner join cob_cartera..ca_operacion on op_tramite = tr_tramite
	  inner join cob_credito..cr_deudores on de_tramite = tr_tramite
	  inner join cobis..cl_ente on en_ente = de_cliente
	  left join #temporal on moneda = tr_moneda
      where cu_garante   =  @i_ente
         and de_rol = 'D'
         and (op_estado = @i_estado or @i_estado is null )
       order by tr_tramite
       if @@rowcount = 0
       begin
           exec cobis..sp_cerror
               @t_debug = @t_debug,
               @t_file  = @t_file, 
               @t_from  = @w_sp_name,
               @i_num   = 1901003
           return 1
       end
    end
	else    --tramite <>null
    begin 
      set rowcount 20

      select "TRAMITE"=tr_tramite,
--            "PRODUCTO"=tr_producto,
			'DEUDOR' = de_cliente,
			"NOMBRE"= en_nombre + ' ' + p_p_apellido + ' ' + p_s_apellido,
            "TIPO OPERACION" = tr_toperacion,
            "NUM OPERACION"=tr_numero_op_banco,
            "VALOR ML"=isnull(tr_monto,0)*isnull(cotizacion,1),
            "ESTADO GARANTIA"=cu_estado
      from cu_custodia
	  inner join cob_credito..cr_gar_propuesta on gp_garantia = cu_codigo_externo
	  inner join cob_credito..cr_tramite on tr_tramite = gp_tramite
	  inner join cob_cartera..ca_operacion on op_tramite = tr_tramite
      inner join cob_credito..cr_deudores on tr_tramite = de_tramite
	  inner join cobis..cl_ente on de_cliente = en_ente
	  left join #temporal on moneda = tr_moneda
      where cu_garante   =  @i_ente
         and tr_tramite > @i_tramite
         and de_rol = 'D'
         and (op_estado = @i_estado or @i_estado is null )
       order by tr_tramite

       if @@rowcount = 0
       begin
          exec cobis..sp_cerror
               @t_debug = @t_debug,
               @t_file  = @t_file, 
               @t_from  = @w_sp_name,
               @i_num   = 1901003
           return 1 
       end
    end
end 
/* ### DEFNCOPY: END OF DEFINITION */
return 0
go