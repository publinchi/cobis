/*************************************************************************/
/*   Archivo:              relacion_visa.sp                              */
/*   Stored procedure:     sp_relacion_visa                              */
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
IF OBJECT_ID('dbo.sp_relacion_visa') IS NOT NULL
    DROP PROCEDURE dbo.sp_relacion_visa
go
create proc sp_relacion_visa  (
   @s_ssn                int      = null,
   @s_date               datetime = null,
   @s_user               login    = null,
   @s_term               descripcion = null,
   @s_corr               char(1)  = null,
   @s_ssn_corr           int      = null,
   @s_ofi                smallint  = null,
   @s_rol		 tinyint   = null,	--II CMI 02Dic2006
   @t_rty                char(1)  = null,
   @t_trn                smallint = null,
   @t_debug              char(1)  = 'N',
   @t_file               varchar(14) = null,
   @t_from               varchar(30) = null,
   @i_operacion          char(1)     = null,
   @i_modo               tinyint     = null,
   @i_cliente            int         = null,
   @i_cliente_sig        int         = null,
   @i_codigo_externo  	 varchar(64) = null,   
   @i_codigo_sig  	 varchar(64) = null,
   @i_tarjeta            varchar(16) = null,
   @i_tipo_cca           catalogo    = null,
   @i_formato_fecha      tinyint     = null,
   @i_param1             varchar(64) = null
)
as

declare
   @w_sp_name            varchar(32),
   @w_tabla_rec          smallint,
   @w_error              int,
   @w_cliente            int,
   @w_grupo              int,
   @w_tcca               catalogo,
   @w_return		 int		--II CMI 02Dic2006

select @w_sp_name = 'sp_relacion_visa'

if @i_operacion in ('I','D')
begin
  create table #garantiasG (
  garantia   varchar(64) null,
  tipo_cca   catalogo null,
  producto   char(1) null)

  create table #garantias_C (
  garantia   varchar(64) null,
  tipo_cca   catalogo null,
  producto   char(1) null)
end


---Tipos de Garantias con Reclasificacion 
-----------------------------------------
select @w_tabla_rec = codigo
  from cobis..cl_tabla 
 where tabla = 'cu_reclasifica'


if @i_operacion = 'Q'
begin

    select @i_codigo_sig = @i_param1

    set rowcount 20
    select 'GARANTIA' = cu_codigo_externo,
           'CLIENTE' = cg_nombre,
           'VALOR ACTUAL' = cu_valor_actual,
           'TIPO' = valor           
     from cobis..cl_catalogo,cu_custodia, cu_cliente_garantia 
    where tabla =  @w_tabla_rec
      and codigo = cu_tipo
      and estado = 'V'
      and cu_codigo_externo = cg_codigo_externo
      and (cg_ente = @i_cliente or @i_cliente = null)
      and cg_principal = 'S'
      and cu_estado = 'V'     
      and (cu_codigo_externo > @i_codigo_sig or @i_codigo_sig = null)
    order by cu_codigo_externo
    set rowcount 0
end 


if @i_operacion = 'V'
begin
    select valor           
     from cobis..cl_catalogo,cu_custodia, cu_cliente_garantia 
    where tabla =  @w_tabla_rec
      and codigo = cu_tipo
      and estado = 'V'
      and cu_codigo_externo = @i_codigo_externo
      and cu_codigo_externo = cg_codigo_externo
      and (cg_ente = @i_cliente or @i_cliente = null)
      and cg_principal = 'S'
      and cu_estado = 'V'     

    if @@rowcount <> 1
    begin
      select @w_error = 1901005
      goto ERROR
    end

end 


if @i_operacion = 'S'
begin

  --Busqueda de Tarjetas Disponibles
  ----------------------------------
  if @i_modo = 0 
  begin

    if not exists (select 1                
                     from cobis..cl_catalogo,
                          cu_custodia,
                          cu_cliente_garantia 
                     where tabla =  @w_tabla_rec
                       and codigo = cu_tipo
                       and estado = 'V'
                       and cu_codigo_externo = @i_codigo_externo
                       and cu_codigo_externo = cg_codigo_externo
                       and cg_principal = 'S'
                       and cu_estado = 'V')

    begin
      select @w_error = 1909013
      goto ERROR
    end
 
    select @w_grupo = 0

    create table #entes (
      cliente  int  null)

    insert into #entes
    select cg_ente  
      from cu_cliente_garantia
     where cg_codigo_externo = @i_codigo_externo
       and cg_principal = 'S'

    select @w_grupo = isnull(en_grupo,0),
           @w_cliente = en_ente
      from #entes, cobis..cl_ente
     where en_ente = cliente

    if @w_grupo <> 0
    begin
     insert into #entes
     select en_ente
       from cobis..cl_ente
      where en_grupo = @w_grupo
        and en_ente <> @w_cliente
    end    

    set rowcount 20   
    select 'TARJETA' = vi_tarjeta,
           'CLIENTE' = vi_cliente,
           'NOMBRE' = vi_ncliente,
           'F.VENCIMIENTO ' = convert(varchar(10),vi_fecha_venc,@i_formato_fecha),
           'SALDO TOTAL' = vi_saldo_total
       from cob_credito..cr_visa V, #entes
      where vi_cliente = cliente
        and vi_tarjeta > '' 
        and vi_fecha_venc >= @s_date
        and (vi_tarjeta not in (select rv_tarjeta
                                 from cu_relvisa
                                where rv_codigo_externo = @i_codigo_externo
                                  and rv_tarjeta = V.vi_tarjeta))
        and (
             (vi_cliente = @i_cliente_sig and (vi_tarjeta > @i_tarjeta or @i_tarjeta = null)) or
             (vi_cliente > @i_cliente_sig or @i_cliente_sig = null)
            )
    order by vi_cliente, vi_tarjeta
    set rowcount 0

  end --@i_modo = 0


  --Busqueda de Tarjetas Relacionadas
  -----------------------------------
  if @i_modo = 1
  begin    
    set rowcount 20
    select 'TARJETA' = rv_tarjeta,
           'CLIENTE' = vi_ncliente,
           'T.CREDITO' = C.valor,
           'F.VENCIMIENTO' = convert(varchar(10),vi_fecha_venc,@i_formato_fecha),
           'F.RELACION' = convert(varchar(10),rv_fecha,@i_formato_fecha)
      from cu_relvisa, cob_credito..cr_visa,
           cobis..cl_tabla T, cobis..cl_catalogo C
     where rv_codigo_externo = @i_codigo_externo    
       and rv_tarjeta = vi_tarjeta
       and vi_cliente = rv_cliente_tarjeta
       and T.tabla = 'ca_tipo_cartera'
       and C.tabla = T.codigo
       and C.codigo = rv_tipo_cca
       and (rv_tarjeta > @i_tarjeta or @i_tarjeta = null)
    order by rv_tarjeta
    set rowcount 0
  end --@i_modo = 1

end ---@i_operacion = 'S'


if @i_operacion = 'I'
begin

  if exists (select 1
               from cu_relvisa
              where rv_codigo_externo = @i_codigo_externo
                and rv_tarjeta  = @i_tarjeta)
  begin
    select @w_error = 1909010
    goto ERROR
  end 


  BEGIN TRAN

    insert into cu_relvisa (
      rv_codigo_externo , rv_tarjeta, rv_cliente_tarjeta,
      rv_fecha, rv_tipo_cca)
    values (
      @i_codigo_externo, @i_tarjeta, @i_cliente,
      @s_date, @i_tipo_cca)

    if @@error <> 0
    begin
      select @w_error = 1909011
      goto ERROR
    end

    ---Transaccion de Servicio
    insert into ts_relvisa values (
      @s_ssn, @t_trn, 'I', getdate(),
      @s_user, @s_term, @s_ofi,'cu_relvisa',
      @i_codigo_externo, @i_tarjeta, @i_cliente,
      @s_date, @i_tipo_cca)

    if @@error <> 0 
    begin
      select @w_error = 1903003
      goto ERROR
    end

    exec @w_error = cob_custodia..sp_relaciona_gar
         @s_date  = @s_date,
         @s_ofi   = @s_ofi,
         @s_user  = @s_user,
         @i_tarjeta = @i_tarjeta,
         @i_codigo_externo = @i_codigo_externo,
         @i_tipo_cca = @i_tipo_cca,
         @i_oficina_des = @s_ofi,
         @i_commit = 'N'

    if @w_error <> 0 
     goto ERROR 


  COMMIT TRAN

end ---@i_opcion = 'I'


if @i_operacion = 'D'
begin

  select @w_tcca = rv_tipo_cca,
         @w_cliente = rv_cliente_tarjeta
    from cu_relvisa
   where rv_codigo_externo = @i_codigo_externo
     and rv_tarjeta = @i_tarjeta

  if @@rowcount = 0
  begin
     select @w_error = 1901003
     goto ERROR
  end

  BEGIN TRAN   

   exec @w_error = cob_custodia..sp_cancela_relacion
        @s_date  = @s_date,
        @s_ofi   = @s_ofi,
        @s_user  = @s_user,
        @i_tarjeta = @i_tarjeta,
        @i_codigo_externo = @i_codigo_externo,
        @i_tipo_cca = @w_tcca,
        @i_oficina_des = @s_ofi,
        @i_commit = 'N'

   if @w_error <> 0 
    goto ERROR 

   delete cu_relvisa
    where rv_codigo_externo = @i_codigo_externo
      and rv_tarjeta = @i_tarjeta   
   
   if @@error <> 0
   begin
     select @w_error = 1909012
     goto ERROR
   end

   ---Transaccion de Servicio
   insert into ts_relvisa values (
      @s_ssn, @t_trn, 'D', getdate(),
      @s_user, @s_term, @s_ofi,'cu_relvisa',
      @i_codigo_externo, @i_tarjeta, @w_cliente,
      @s_date, @w_tcca)

   if @@error <> 0 
   begin
      select @w_error = 1903003
      goto ERROR
   end



  COMMIT TRAN

end ---@i_opcion = 'D'

--Guarda log auditoria
--II CMI 02Dic2006
if @i_operacion in ('Q', 'V', 'S')
begin
	select @i_codigo_externo = substring(@i_codigo_externo, 1, 24)
	/*exec @w_return = cob_cartera..sp_trnlog_auditoria_activas
	@s_ssn 		= @s_ssn,                   
   	@i_cod_alterno	= 0,
   	@t_trn		= @t_trn,
	@i_producto	= '19',      
   	@s_date		= @s_date,
   	@s_user		= @s_user,
   	@s_term		= @s_term,
   	@s_rol		= @s_rol,
   	@s_ofi		= @s_ofi,
   	@i_tipo_trn	= @i_operacion,
   	@i_num_banco	= @i_codigo_externo,
	@i_cliente	= @i_cliente

   if @w_return <> 0 
   begin
      select @w_error = 1903003
      goto ERROR
   end*/

--FI CMI 02Dic2006
end


return 0

ERROR:
   exec cobis..sp_cerror 
   @t_debug='N',
   @t_file='',  
   @t_from=@w_sp_name,
   @i_num = @w_error,
   @i_sev = 1
   return @w_error
go