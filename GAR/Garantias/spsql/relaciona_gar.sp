/****************************************************************/
/* ARCHIVO:              relaciona_gar.sp                       */
/* Stored procedure:	 sp_relaciona_gar	          	        */
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
/* 29/Mar/2019       Luis  Ramirez  	        Emision Inicial */
/****************************************************************/

USE cob_custodia
go

IF OBJECT_ID('dbo.sp_relaciona_gar') IS NOT NULL
    DROP PROCEDURE dbo.sp_relaciona_gar
go
create proc dbo.sp_relaciona_gar (
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
   @i_tipo_cca           catalogo  = null,
   @i_tarjeta            varchar(16) = null,
   @i_oficina_des        smallint  = null
)
as
declare
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


   @w_est_credito          tinyint,
   @w_est_no_vigente       tinyint,
   @w_cont                 tinyint,
   @w_tcca                 catalogo,
   @w_return		   int,
   @w_cantidad             tinyint


select @w_today = getdate(),
       @w_est_credito  = 99,
       @w_est_no_vigente = 0

---Tipos de Garantias con Reclasificacion 
-----------------------------------------
select @w_tabla_rec = codigo
  from cobis..cl_tabla 
 where tabla = 'cu_reclasifica'


---Relacion desde desembolso de operaciones
if @i_tramite_car <> null
begin
  select @w_tcca = 1--op_tipo_cca
    from cob_cartera..ca_operacion
   where op_tramite = @i_tramite_car

  insert into #garantiasG
  select gp_garantia,
         @w_tcca,
         'C'
    from cob_credito..cr_gar_propuesta
   where gp_tramite = @i_tramite_car
     and gp_est_garantia = 'V'

end

--Relacion desde VISA
if @i_tarjeta <> null
begin  
  insert into #garantiasG values
  (@i_codigo_externo, @i_tipo_cca, 'V')
end 


---------------------------------------------------------
--- CURSOR PARA OBTENER GARANTIAS RELACIONADAS A PROCESAR
---------------------------------------------------------
--declare cursor_relacion insensitive cursor for /* HHO Mayo/2012    Migracion SYBASE 15 */
declare cursor_relacion cursor for /* HHO Mayo/2012    Migracion SYBASE 15 */
select garantia, cu_oficina_contabiliza, cu_moneda,
       cu_valor_actual, cu_tipo, tipo_cca
  from #garantiasG, cu_custodia,
       cobis..cl_catalogo
 where cu_codigo_externo = garantia 
   and tabla = @w_tabla_rec
   and estado = 'V'
   and cu_tipo = codigo
   and cu_tipo_cca = null ---Si no tiene tipo de cartera no posee relacion

open cursor_relacion

fetch cursor_relacion into
 @w_codigo_externo, @w_oficina_contabiliza, @w_moneda,
 @w_valor_actual, @w_tipo, @w_tcca

while @@FETCH_STATUS != -1
begin


    select @w_oficina_contabiliza = isnull(@i_oficina_des,@w_oficina_contabiliza),
           @w_contabilizar = null   

    select @w_contabilizar = tc_contabilizar
      from cob_custodia..cu_tipo_custodia
     where tc_tipo = @w_tipo     


    if @w_contabilizar = 'S'
    begin 

      --TRANSACCION CONTABLE DE ENLACE
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
           @i_operac         = 'R',
           @i_signo          = 1,
           @i_tipo_cca       = @w_tcca,
           @i_codigo_externo = @w_codigo_externo

      if @w_return != 0 
      begin
        select @w_error = @w_return
        goto ERROR
      end 

      --Actualizar cu_custodia con el tipo de cartera
      -----------------------------------------------
      update cu_custodia
         set cu_tipo_cca = @w_tcca
       where cu_codigo_externo = @w_codigo_externo

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
   @t_from= 'sp_enlace_gar',
   @i_num = @w_error,
   @i_sev = 1

   return @w_error
go