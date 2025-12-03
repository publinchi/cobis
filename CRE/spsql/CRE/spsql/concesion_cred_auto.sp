/************************************************************************/
/*   Archivo:             concesion_cred_auto.sp                        */
/*   Stored procedure:    concesion_cred_auto                           */
/*   Base de datos:       cob_credito                                   */
/*   Producto:            Credito                                       */
/*   Disenado por:        Bruno Duenas                                  */
/*   Fecha de escritura:  13-Febrero-2023                               */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido sin el debido                  */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada y por lo tanto, derivará en acciones legales civiles       */
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/
/*                     PROPOSITO                                        */
/*   Se registran los clientes que aplican a un credito automatico      */
/************************************************************************/
/*                          MODIFICACIONES                              */
/* FECHA                    AUTOR                       RAZON           */
/* 13/Febrero/2023          BDU            Emision Inicial              */
/* 23/Febrero/2023          BDU            Correccion filtro estados    */
/* 08/Marzo/2023            DMO            Correccion filtro operaciones*/
/* 23/Marzo/2023            DMO            Se añade correo de jefe      */
/* 28/Abril/2023            BDU            Se especifica nombre de      */
/*                                         archivos a borrar            */
/* 03/Mayo/2023             BDU            Se eliminan registros del dia*/
/*                                         en que se ejecuta el         */
/*                                         proceso (de existir)         */
/************************************************************************/

use cob_credito
go
set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1 
           from sysobjects 
           where name = 'concesion_cred_auto')
begin
   drop proc concesion_cred_auto
end   
go

create procedure concesion_cred_auto(
   @i_param1         int          null
)
as
declare @w_sarta                    int,
        @w_batch                    int,
        @w_error                    int,    
        @w_variables                varchar(64),
        @w_return_variable          varchar(25),
        @w_return_results           varchar(25),
        @w_last_condition_parent    varchar(10),
        @w_return_results_rule      varchar(25),
        @w_id_ente                  int,
        @w_id                       int,
        @w_id_max                   int,
        @w_id_oficial               int,
        @w_num_ciclos               int,
        @w_creditos_activos         int,
        @w_creditos_auto            int,
        @w_mensaje                  varchar(250),
        @w_retorno_ej               int,
        @w_termina                  bit
        
-- Informacion proceso batch
print 'INICIO PROCESO concesion_cred_auto: '  + convert(varchar, getdate(),120)

print 'VALIDACION DE REGISTROS DEL HILO: '
if not exists(select 1
              from cr_hilos_credautomatico
              where hc_hilo = @i_param1)
begin
   update cr_hilos_credautomatico
   set hc_estado = 'P'
   where hc_hilo = @i_param1
   
   return 0
end

select @w_termina = 0
select @w_sarta = lo_sarta,
       @w_batch = lo_batch
from cobis..ba_log,
     cobis..ba_batch
where ba_arch_fuente like '%cob_credito..concesion_cred_auto%'
and   lo_batch   = ba_batch
and   lo_estatus = 'E'
if @@rowcount = 0
begin
   select @w_termina = 1
   select @w_error  = 808071 
   goto ERROR
end

if not exists(select 1
            from cob_pac..bpl_rule BPL, cob_pac..bpl_rule_version RV
            where rl_acronym = 'VACRAU'
            and rv_status = 'PRO'
            and BPL.rl_id = RV.rl_id)
begin
   select @w_termina = 1
   select @w_error  = 725109 
   goto ERROR
end


print 'INICIO DE BUCLE PARA EJECUCIÓN DE REGLA: '  + convert(varchar, getdate(),120)
select @w_id = hc_inicio 
from cr_hilos_credautomatico
where hc_hilo = @i_param1

select @w_id_max = hc_fin 
from cr_hilos_credautomatico
where hc_hilo = @i_param1

while @w_id <= @w_id_max
begin
    select  @w_num_ciclos       = null,
            @w_creditos_activos = null,
            @w_creditos_auto    = null,
            @w_id_ente          = null,
            @w_id_oficial       = null
    
    
    select  @w_num_ciclos       = uc_ciclos,
            @w_creditos_activos = uc_cred_act,
            @w_creditos_auto    = uc_cred_aut,
            @w_id_ente          = uc_ente,
            @w_id_oficial       = uc_oficial
    from cr_universo_credautomatico 
    where uc_id = @w_id

   select @w_variables =  convert(varchar(10),isnull(@w_num_ciclos, 0)) + '|' + convert(varchar(10),@w_creditos_activos)+ '|'+  convert(varchar(10),@w_creditos_auto) 
   exec @w_error               = cob_pac..sp_rules_param_run
        @s_rol                   = 3,
        @i_rule_mnemonic         = 'VACRAU',
        @i_var_values            = @w_variables,
        @i_var_separator         = '|',
        @o_return_variable       = @w_return_variable  OUT,
        @o_return_results        = @w_return_results OUT,
        @o_last_condition_parent = @w_last_condition_parent out
   select @w_return_results_rule = replace(@w_return_results,'|','')
   if(@w_return_results_rule = '0')
   begin
      insert into cr_clientes_credautomatico(cc_fecha, cc_ente, cc_oficial)
      select getdate(), @w_id_ente, @w_id_oficial
   end
   if @w_error <> 0
   begin
      goto ERROR
   end
   NEXT_LINE:
      set @w_id = @w_id + 1
end
print 'FIN DE BUCLE PARA EJECUCIÓN DE REGLA: '  + convert(varchar, getdate(),120)

update cr_hilos_credautomatico
set hc_estado = 'P'
where hc_hilo = @i_param1

select @w_termina = 1
print 'FIN PROCESO concesion_cred_auto: '  + convert(varchar, getdate(),120)

return 0

ERROR:
   update cr_hilos_credautomatico
   set hc_estado = 'E'
   where hc_hilo = @i_param1
   
   if @w_mensaje is null
   begin
      select @w_mensaje = mensaje
      from cobis..cl_errores 
      where numero = @w_error
   end
   
   if(@w_sarta is not null or @w_batch is not null)
   begin
      exec @w_retorno_ej = cobis..sp_ba_error_log
         @i_sarta   = @w_sarta,
         @i_batch   = @w_batch,
         @i_error   = @w_error,
         @i_detalle = @w_mensaje
   end
   if @w_termina = 0
   begin
      goto NEXT_LINE
   end
   if @w_retorno_ej > 0
   begin
      return @w_retorno_ej
   end
   else
   begin
      return @w_error
   end

go
