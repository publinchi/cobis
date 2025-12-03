/*************************************************************************/
/*   Archivo:              cancela_relacion.sp                           */
/*   Stored procedure:     sp_cancela_relacion                           */
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
go

IF OBJECT_ID('dbo.sp_cancela_relacion') IS NOT NULL
    DROP PROCEDURE dbo.sp_cancela_relacion
go

create proc dbo.sp_cancela_relacion (
   @s_ssn                int      = null,
   @s_date               datetime = null,
   @s_user               login    = null,
   @s_term               varchar(64) = null,
   @s_corr               char(1)  = null,
   @s_ssn_corr           int      = null,
   @s_ofi                smallint  = null,
   @t_trn                smallint  = null,
   @i_tramite_car	 int       = null,
   @i_codigo_externo     varchar(64) = null,
   @i_tarjeta            varchar(16) = null,
   @i_tipo_cca           catalogo  = null,
   @i_oficina_des        smallint  = null
)
as
declare
   @w_sp_name              varchar(30),
   @w_today                datetime,     
   @w_sucursal             smallint,
   @w_tipo                 varchar(64),
   @w_error		   int,
   @w_contabilizar         char(1),
   @w_moneda               tinyint,
   @w_codigo_externo       varchar(64),
   @w_oficina              tinyint,
   @w_oficina_contabiliza  smallint,
   @w_valor_actual         money,   
   @w_est_vigente          tinyint,
   @w_est_vencido          tinyint,
   @w_tabla_rec            smallint,
   @w_est_cancelado        tinyint,
   @w_tcca                 catalogo,
   @w_cont                 tinyint,
   @w_cont_visa            tinyint,
   @w_new_relac            int,
   @w_new_relac_visa       varchar(16),
   @w_new_tramite          int,
   @w_new_tarjeta          varchar(16),   
   @w_new_tcca             catalogo,
   @w_return		   int

select @w_today = getdate(),
       @w_est_cancelado = 3,
       @w_sp_name = 'sp_cancela_relacion'

select @w_tabla_rec = codigo
 from cobis..cl_tabla 
where tabla = 'cu_reclasifica'


if @i_tramite_car <> null
begin
-- cambiar el numero 1 ya qu es temporal
  select @w_tcca = 1
    from cob_cartera..ca_operacion
   where op_tramite = @i_tramite_car

  insert into #garantias_C
  select gp_garantia,
         @w_tcca,
         'C'
    from cob_credito..cr_gar_propuesta
   where gp_tramite = @i_tramite_car
     and gp_est_garantia = 'V'
end

if @i_tarjeta <> null
begin
  
  insert into #garantias_C values
  (@i_codigo_externo, @i_tipo_cca, 'V')
   
end         


---------------------------------------------------------
--- CURSOR PARA OBTENER GARANTIAS RELACIONADAS A PROCESAR
---------------------------------------------------------
--declare cursor_relacion insensitive cursor for /* HHO Mayo/2012 Migracion SYBASE 15 */
declare cursor_relacion cursor for /* HHO Mayo/2012 Migracion SYBASE 15 */
select garantia, cu_oficina_contabiliza, cu_moneda,
       cu_valor_actual, cu_tipo, tipo_cca
  from #garantias_C, cu_custodia,
       cobis..cl_catalogo
 where cu_codigo_externo = garantia
   and tabla = @w_tabla_rec
   and cu_tipo = codigo
   and cu_tipo_cca <> null
   and cu_tipo_cca = tipo_cca
   and estado = 'V'

open cursor_relacion

fetch cursor_relacion into
 @w_codigo_externo, @w_oficina_contabiliza, @w_moneda,
 @w_valor_actual, @w_tipo, @w_tcca

while @@FETCH_STATUS != -1
begin

    select @w_oficina_contabiliza = isnull(@i_oficina_des,@w_oficina_contabiliza),
           @w_contabilizar = null,
           @w_cont = 0,
           @w_cont_visa = 0

    select @w_contabilizar = tc_contabilizar
      from cob_custodia..cu_tipo_custodia
     where tc_tipo = @w_tipo

    ---Determinar si existen otras operaciones
    ---amparadas por la misma garantia y que
    ---impidan levantar la relacion

    if @i_tramite_car <> null
    begin
      select @w_cont = count(1)
        from cob_credito..cr_gar_propuesta,
             cob_cartera..ca_operacion 
       where gp_tramite <> @i_tramite_car
         and gp_garantia = @w_codigo_externo
         and gp_est_garantia = 'V'
         and op_tramite = gp_tramite
         --and op_tipo_cca = @w_tcca
         and op_estado not in (3,0,99,11)  

      select @w_cont_visa = count(1)
        from cu_relvisa
       where rv_codigo_externo = @w_codigo_externo
         and rv_tipo_cca = @w_tcca

      select @w_cont = @w_cont + @w_cont_visa
    end

    if @i_tarjeta <> null
    begin
      select @w_cont = count(1)
        from cob_credito..cr_gar_propuesta,
             cob_cartera..ca_operacion 
       where gp_garantia = @w_codigo_externo
         and gp_est_garantia = 'V'
         and op_tramite = gp_tramite
         --and op_tipo_cca = @w_tcca
         and op_estado not in (3,0,99,11)  

      select @w_cont_visa = count(1)
        from cu_relvisa
       where rv_codigo_externo = @w_codigo_externo
         and rv_tarjeta <> @i_tarjeta
         and rv_tipo_cca = @w_tcca        

      select @w_cont = @w_cont + @w_cont_visa
    end

    if @w_contabilizar = 'S' and @w_cont = 0
    begin 
      --TRANSACCION CONTABLE DE CANCELACION DE RELACION
      exec @w_return = cob_custodia..sp_conta
           @s_date           = @s_date,
           @t_trn            = 19300,
           @i_operacion      = 'I',
           @i_filial         = 1,
           @i_oficina_orig   = @w_oficina_contabiliza,
           @i_oficina_dest   = @w_oficina_contabiliza,
           @i_tipo           = @w_tipo,
           @i_moneda         = @w_moneda,
           @i_valor          = @w_valor_actual,
           @i_operac         = 'L',
           @i_signo          = 1,
           @i_tipo_cca       = @w_tcca,
           @i_codigo_externo = @w_codigo_externo

      if @w_return != 0 
      begin
        select @w_error = @w_return
        goto ERROR
      end 

      --Actualizar cu_custodia 
      ------------------------
      update cu_custodia
         set cu_tipo_cca = null
       where cu_codigo_externo = @w_codigo_externo

      --Analizar si se debe generar una nueva relacion
      ------------------------------------------------
      select @w_new_relac = 0,
             @w_new_relac_visa = null,
             @w_new_tarjeta = null,
             @w_new_tcca = null

      if @i_tramite_car <> null
      begin

        select @w_new_relac = min(op_operacion)
          from cob_credito..cr_gar_propuesta,
               cob_cartera..ca_operacion 
         where gp_tramite <> @i_tramite_car
           and gp_garantia = @w_codigo_externo
           and gp_est_garantia = 'V'
           and op_tramite = gp_tramite
           and op_estado not in (3,0,99,11)  

        if @w_new_relac = 0 ---Evaluo Tarjetas VISA
          select @w_new_relac_visa = min(rv_tarjeta)
            from cu_relvisa
           where rv_codigo_externo = @w_codigo_externo
             and rv_tipo_cca <> @w_tcca
      end

      if @i_tarjeta <> null
      begin       

        select @w_new_relac = min(op_operacion)
          from cob_credito..cr_gar_propuesta,
               cob_cartera..ca_operacion 
         where gp_garantia = @w_codigo_externo
           and gp_est_garantia = 'V'
           and op_tramite = gp_tramite
           --and op_tipo_cca <> @w_tcca
           and op_estado not in (3,0,99,11)  

        if @w_new_relac = 0 ---Evaluo Tarjetas VISA
          select @w_new_relac_visa = min(rv_tarjeta)
            from cu_relvisa
           where rv_codigo_externo = @w_codigo_externo
             and rv_tarjeta <> @i_tarjeta
      end

      if @w_new_relac <> 0  ---Nueva relacion con Creditos
      begin
         select @w_new_tramite = op_tramite
           from cob_cartera..ca_operacion
          where op_operacion = @w_new_relac      
        
         exec @w_return = cob_custodia..sp_relaciona_gar
              @s_date  = @s_date,
              @s_ofi   = @s_ofi,
              @s_user  = @s_user,
              @i_tramite_car = @w_new_tramite,
              @i_oficina_des = @s_ofi,      
              @i_commit = "N"

         if @w_return != 0 
         begin
           select @w_error = @w_return
           goto ERROR
         end 
      end ---@w_new_relac <> 0

      else         
      begin
        if @w_new_relac_visa <> null ---Nueva Relacion con Visa
        begin
          select @w_new_tarjeta = rv_tarjeta,
                 @w_new_tcca = rv_tipo_cca
            from cu_relvisa
           where rv_codigo_externo = @w_codigo_externo
             and rv_tarjeta = @w_new_relac_visa
        
          exec @w_return = cob_custodia..sp_relaciona_gar
               @s_date  = @s_date,
               @s_ofi   = @s_ofi,
               @s_user  = @s_user,
               @i_tarjeta = @w_new_tarjeta,
               @i_codigo_externo = @w_codigo_externo,
               @i_tipo_cca = @w_new_tcca,
               @i_oficina_des = @s_ofi,      
               @i_commit = "N"

          if @w_return != 0 
          begin
            select @w_error = @w_return
            goto ERROR
          end 
        end --- @w_new_relac_visa <> null
      end -- else

    end -- @w_contabilizar

    fetch cursor_relacion into
    @w_codigo_externo, @w_oficina_contabiliza, @w_moneda,
    @w_valor_actual, @w_tipo, @w_tcca

end

close cursor_relacion
deallocate cursor_relacion

return 0

ERROR:
   exec cobis..sp_cerror
   @t_debug= 'N',
   @t_file= '',  
   @t_from= @w_sp_name,
   @i_num = @w_error,
   @i_sev = 1

   return @w_error
go