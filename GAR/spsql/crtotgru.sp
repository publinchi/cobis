/*************************************************************************/
/*   Archivo:              crtotgru.sp                                   */
/*   Stored procedure:     sp_crtotgru                                   */
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
IF OBJECT_ID('dbo.sp_crtotgru') IS NOT NULL
    DROP PROCEDURE dbo.sp_crtotgru
go
create proc dbo.sp_crtotgru  (
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
   @i_grupo              int = null, 
   @i_tipo 		 tinyint = null,
   @i_cliente            int = null             
)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_error              int,
   @w_estado             char(1),
   @w_tot_gru            money,
   @w_tot_cli            money,
   @w_oper_gru           money,
   @w_oper_cli           money

select @w_today = getdate()
select @w_sp_name = 'sp_crtotgru'

/***********************************************************/
/* Codigos de Transacciones                                */
if (@t_trn <> 19354 and @i_operacion = 'S') 
begin
   /* tipo de transaccion no corresponde */
    select @w_error = 1901006
    goto error
end
else
begin
   create table #temporal (moneda money, cotizacion money)
   insert into #temporal (moneda,cotizacion)
   select ct_moneda,ct_compra
   from cob_conta..cb_cotizacion a
   where    ct_fecha = (select max(b.ct_fecha)
			from cob_conta..cb_cotizacion b
			where b.ct_moneda = a.ct_moneda
			  and b.ct_fecha <= @w_today)
end
  
if @i_operacion = 'S'
begin
   if @i_tipo = 1 or @i_tipo = 2 -- VIGENTES O PROPUESTAS
   begin
      if @i_tipo = 1 -- VIGENTES 
         select @w_estado = 'V'
      else
         select @w_estado = 'P'
      select @w_tot_gru = sum(cu_valor_actual * isnull(a.cotizacion,1)),
            @w_oper_gru = sum(isnull(gp_monto_exceso,0) + (tr_monto * isnull(b.cotizacion,1)) * isnull(gp_monto_exceso-gp_monto_exceso,1))
       from cu_custodia
	   inner join cu_cliente_garantia on cu_filial = cg_filial and cu_sucursal = cg_sucursal and cu_tipo = cg_tipo_cust and cu_custodia = cg_custodia 
	   left join #temporal a on a.moneda = cu_moneda
	   left join cob_credito..cr_gar_propuesta on gp_garantia = cu_codigo_externo
	   left join cob_credito..cr_tramite on gp_tramite = tr_tramite
	   left join cob_credito..cr_deudores on de_tramite = tr_tramite
	   left join #temporal b on b.moneda = tr_moneda
	   where cg_ente = @i_grupo
         and cu_garante is null   --  Excluye garantes personales
         and cu_estado = @w_estado 
         --and a.co_fecha = dateadd(dd,-1,getdate())
         and de_rol = 'C'    --  Codeudor 
         --and b.co_fecha = dateadd(dd,-1,getdate()) 

      if @i_cliente is null
         select @w_tot_gru,@w_oper_gru 
      else 
      begin
         select @w_tot_cli = sum(cu_valor_actual * isnull(a.cotizacion,1)),
                @w_oper_cli = sum(isnull(gp_monto_exceso,0) + (tr_monto * isnull(b.cotizacion,1)) * isnull(gp_monto_exceso-gp_monto_exceso,1))
          from cu_custodia
		  inner join cu_cliente_garantia on cu_filial = cg_filial and cu_sucursal = cg_sucursal and cu_tipo = cg_tipo_cust and cu_custodia = cg_custodia 
		  left join cob_credito..cr_gar_propuesta on gp_garantia = cu_codigo_externo
		  left join cob_credito..cr_tramite on gp_tramite = tr_tramite
		  left join cob_credito..cr_deudores on de_tramite = tr_tramite
		  left join #temporal a on a.moneda = cu_moneda
		  left join #temporal b on b.moneda = tr_moneda 
		  where cg_ente = @i_cliente
            and cu_garante is null   --  Excluye garantes personales
            and cu_estado = @w_estado 
            --and a.co_fecha = dateadd(dd,-1,getdate())
            and de_rol = 'C'    --  Codeudor 
            --and b.co_fecha = dateadd(dd,-1,getdate())
         select @w_tot_gru - @w_tot_cli,@w_oper_gru - @w_oper_cli
      end
   end
   if @i_tipo = 3 -- EXCEPCIONADAS
   begin
      select @w_estado = 'E' --(E)xcepcionada
      select @w_tot_gru = sum(cu_valor_actual * isnull(a.cotizacion,1)),
             @w_oper_gru = sum(isnull(gp_monto_exceso,0) + (tr_monto * isnull(b.cotizacion,1)) * isnull(gp_monto_exceso-gp_monto_exceso,1))
       from cu_custodia
	   inner join cu_cliente_garantia on cu_filial = cg_filial and cu_sucursal = cg_sucursal and cu_tipo = cg_tipo_cust and cu_custodia = cg_custodia 
	   inner join cob_credito..cr_excepciones on ex_garantia = cu_codigo_externo
	   left join cob_credito..cr_gar_propuesta on gp_garantia = cu_codigo_externo
	   left join cob_credito..cr_tramite on gp_tramite = tr_tramite
	   left join cob_credito..cr_deudores on de_tramite = tr_tramite
	   left join #temporal a on a.moneda = cu_moneda
	   left join #temporal b on b.moneda = tr_moneda 
	   where cg_ente = @i_grupo
         and cu_garante is null   --  Excluye garantes personales
         and cu_estado = @w_estado
         --and a.co_fecha = dateadd(dd,-1,getdate())
         and de_rol = 'C'    --  Codeudor 
         --and b.co_fecha = dateadd(dd,-1,getdate())
         and ex_fecha_reg is null

      if @i_cliente is null
         select @w_tot_gru,@w_oper_gru 
      else begin
         select @w_tot_cli = sum(cu_valor_actual * isnull(a.cotizacion,1)),
                @w_oper_cli = sum(isnull(gp_monto_exceso,0) + (tr_monto * isnull(b.cotizacion,1)) * isnull(gp_monto_exceso-gp_monto_exceso,1))
          from cu_custodia
		  inner join cu_cliente_garantia on cu_filial = cg_filial and cu_sucursal = cg_sucursal and cu_tipo = cg_tipo_cust and cu_custodia = cg_custodia 
		  inner join cob_credito..cr_excepciones on ex_garantia = cu_codigo_externo
	      left join cob_credito..cr_gar_propuesta on gp_garantia = cu_codigo_externo
	      left join cob_credito..cr_tramite on gp_tramite = tr_tramite
	      left join cob_credito..cr_deudores on de_tramite = tr_tramite
	      left join #temporal a on a.moneda = cu_moneda
	      left join #temporal b on b.moneda = tr_moneda 
          where cg_ente = @i_cliente
            and cu_garante is null   --  Excluye garantes personales
            --and a.co_fecha = dateadd(dd,-1,getdate())
            and de_rol = 'C'    --  Codeudor 
            --and b.co_fecha = dateadd(dd,-1,getdate())
            and ex_fecha_reg is null

         select @w_tot_gru - @w_tot_cli,@w_oper_gru - @w_oper_cli
      end
   end
   if @i_tipo = 4 -- TOTAL
   begin
      select @w_tot_gru = sum(cu_valor_actual * isnull(a.cotizacion,1)),
             @w_oper_gru = sum(isnull(gp_monto_exceso,0) + (tr_monto * isnull(b.cotizacion,1)) * isnull(gp_monto_exceso-gp_monto_exceso,1))
       from cu_custodia
		  inner join cu_cliente_garantia on cu_filial = cg_filial and cu_sucursal = cg_sucursal and cu_tipo = cg_tipo_cust and cu_custodia = cg_custodia 
		  left join cob_credito..cr_gar_propuesta on gp_garantia = cu_codigo_externo
		  left join cob_credito..cr_tramite on gp_tramite = tr_tramite
		  left join cob_credito..cr_deudores on de_tramite = tr_tramite
		  left join #temporal a on a.moneda = cu_moneda
		  left join #temporal b on b.moneda = tr_moneda 
	   where cg_ente = @i_grupo
         and cu_garante is null   --  Excluye garantes personales
         --and a.co_fecha = dateadd(dd,-1,getdate())
         and de_rol = 'C'    --  (C)odeudor 
         --and b.co_fecha = dateadd(dd,-1,getdate())
         and cu_estado <> 'C'  --(C)errada
       
      if @i_cliente is null
         select @w_tot_gru,@w_oper_gru 
      else begin
         select @w_tot_cli = sum(cu_valor_actual * isnull(a.cotizacion,1)),
                @w_oper_cli = sum(isnull(gp_monto_exceso,0) + (tr_monto * isnull(b.cotizacion,1)) * isnull(gp_monto_exceso-gp_monto_exceso,1))
          from cu_custodia
		  inner join cu_cliente_garantia on cu_filial = cg_filial and cu_sucursal = cg_sucursal and cu_tipo = cg_tipo_cust and cu_custodia = cg_custodia 
		  left join cob_credito..cr_gar_propuesta on gp_garantia = cu_codigo_externo
		  left join cob_credito..cr_tramite on gp_tramite = tr_tramite
		  left join cob_credito..cr_deudores on de_tramite = tr_tramite
		  left join #temporal a on a.moneda = cu_moneda
		  left join #temporal b on b.moneda = tr_moneda 
          where cg_ente = @i_cliente
            and cu_garante is null   --  Excluye garantes personales
            --and a.co_fecha = dateadd(dd,-1,getdate())
            and de_rol = 'C'    --  Codeudor 
            --and b.co_fecha = dateadd(dd,-1,getdate())
            and cu_estado <> 'C'    -- (C)errada
          
         select @w_tot_gru - @w_tot_cli,@w_oper_gru - @w_oper_cli
      end
   end
end

return 0 
error:

   exec cobis..sp_cerror
   @t_debug = @t_debug,
   @t_file  = @t_file, 
   @t_from  = @w_sp_name,
   @i_num   = @w_error
   return 1
go