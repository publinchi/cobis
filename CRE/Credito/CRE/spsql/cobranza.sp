/************************************************************************/
/*   Archivo:             cobranza.sp                                   */
/*   Stored procedure:    cobranza                                      */
/*   Base de datos:       cob_credito                                   */
/*   Producto:            Credito                                       */
/*   Disenado por:        Bruno Duenas                                  */
/*   Fecha de escritura:  02-Mayo2023                                   */
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
/*   Se registran los cobros de una operacion                           */
/************************************************************************/
/*                          MODIFICACIONES                              */
/* FECHA                    AUTOR                       RAZON           */
/* 02/Mayo/2023             BDU                Emision Inicial          */
/* 09/Mayo/2023             BDU                Ajuste referencia grupal */
/* 19/Mayo/2025             BDU                Ajuste logica oficial re-*/
/*                                             cuperador                */
/* 01/Octubre/2025          BDU                Ajuste logica oficial    */
/************************************************************************/

use cob_credito
go
set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1 
           from sysobjects 
           where name = 'cobranza')
begin
   drop proc cobranza
end   
go

create procedure cobranza(
    @s_ssn                  int             = null,
    @s_sesn                 int             = null,
    @s_culture              varchar(10)     = null,
    @s_user                 login           = null,
    @s_term                 varchar(30)     = null,
    @s_date                 datetime        = null,
    @s_srv                  varchar(30)     = null,
    @s_lsrv                 varchar(30)     = null,
    @s_ofi                  smallint        = null,
    @s_rol                  smallint        = NULL,
    @s_org_err              char(1)         = NULL,
    @s_error                int             = NULL,
    @s_sev                  tinyint         = NULL,
    @s_msg                  descripcion     = NULL,
    @s_org                  char(1)         = NULL,
    @t_show_version         bit             = 0,
    @t_debug                char(1)         = 'N',
    @t_file                 varchar(10)     = null,
    @t_from                 varchar(32)     = null,
    @t_trn                  int             = null,
    @i_operacion            char(1)         = null,
    @i_oficial              login           = null,
    @i_operacion_cred       varchar(max)    = null,
    @i_monto_adeudado       varchar(max)    = null,
    @i_monto_recuperado     varchar(max)    = null
)
as
declare @w_sp_name                  varchar(32),
        @w_error                    int,
        @w_id_max                   int,
        @w_id_max_cobro             int,
        @w_login                    login,
        @w_login_cred               login,
        @w_operacion                cuenta,
        @w_cont                     int,
        @w_padre                    cuenta,
        @w_oficial_recuperador      int

if @t_trn <> 21871
begin
    select @w_error = 1720075 -- TRANSACCION NO PERMITIDA
    goto ERROR
end

select @w_sp_name = 'cob_credito..cobranza'
if @i_operacion = 'I'
begin
   
   --sacar id oficial recuperador
   select @w_oficial_recuperador = oc_oficial 
   from cobis.dbo.cc_oficial co
   inner join cobis.dbo.cl_funcionario fu on fu.fu_funcionario = co.oc_funcionario
   where fu.fu_login = @i_oficial
   
   if (OBJECT_ID('tempdb.dbo.#tmp_cobros','U')) is not null
   begin
      drop table #tmp_cobros
   end
   
   create table #tmp_cobros (
      id                   int             null,
      operacion            cuenta          null,
      ref_gr               cuenta          null,
      monto_adeudado       float           null,
      monto_recuperado     float           null
   )
   
    set @w_cont = 0
   -- Separar la cadena en valores individuales
   while charindex(';', @i_operacion_cred) > 0
   begin
      set @w_operacion  = cast(substring(@i_operacion_cred, 1, charindex(';', @i_operacion_cred) - 1) as varchar);
      set @w_cont = @w_cont + 1
      insert into #tmp_cobros (id, operacion, monto_adeudado, monto_recuperado)
      values (@w_cont, @w_operacion,
              cast(substring(@i_monto_adeudado, 1, charindex(';', @i_monto_adeudado) - 1) as float),
              cast(substring(@i_monto_recuperado, 1, charindex(';', @i_monto_recuperado) - 1) as float));
      set @i_monto_adeudado = substring(@i_monto_adeudado, charindex(';', @i_monto_adeudado) + 1, LEN(@i_monto_adeudado));
      set @i_monto_recuperado = substring(@i_monto_recuperado, charindex(';', @i_monto_recuperado) + 1, LEN(@i_monto_recuperado));
      set @i_operacion_cred = substring(@i_operacion_cred, charindex(';', @i_operacion_cred) + 1, LEN(@i_operacion_cred));
   end
   
   --Actualizar la referencia en grupales
   if((select count(*) from #tmp_cobros) > 1)
   begin
      select @w_padre = op_ref_grupal
      from cob_cartera.dbo.ca_operacion,
           #tmp_cobros
      where op_banco = operacion
      and op_ref_grupal is not null
      and op_grupal = 'S'
   end
   
   update #tmp_cobros
   set ref_gr = @w_padre
   
   set @w_cont = null
   --Sacar el maximo del id del ultimo grupo de cobros
   select @w_id_max_cobro = isnull(max(co_sec_cobro), 0) + 1
   from cob_credito.dbo.cr_cobros
   
   select @w_cont = min(id)
   from #tmp_cobros
   while @w_cont is not null
   begin
      select @w_id_max = isnull(max(co_secuencial), 0) + 1
      from cob_credito.dbo.cr_cobros
      
      select @w_login_cred = fu_login 
      from cobis.dbo.cc_oficial co,
           cobis.dbo.cl_funcionario fu 
      where oc_oficial = (select op_oficial 
                          from cob_cartera.dbo.ca_operacion 
                          where op_banco = @i_operacion_cred)
      and fu.fu_funcionario = co.oc_funcionario 
      
      insert into cob_credito.dbo.cr_cobros
      (co_secuencial, co_sec_cobro, co_operacion, co_banco, co_ref_grupal, 
       co_cliente, co_grupo, co_oficina, co_usuario, 
       co_oficial, co_recuperador, co_estado, co_fecha_recupera, 
       co_tipo_producto, co_monto_adeuda, co_monto_recuperado)
      select @w_id_max, @w_id_max_cobro, op_operacion, op_banco, ref_gr, 
             op_cliente, op_grupo, op_oficina, (select fu_login 
                                                from cobis.dbo.cc_oficial co,
                                                cobis.dbo.cl_funcionario fu 
                                                where oc_oficial = op_oficial
                                                and fu.fu_funcionario = co.oc_funcionario), 
             op_oficial, @w_oficial_recuperador, 'NA', getdate(), 
             op_toperacion, monto_adeudado, monto_recuperado
      from cob_cartera.dbo.ca_operacion,
           #tmp_cobros   
      where op_banco = operacion
      and id = @w_cont
      
      --Siguiente registro
      select @w_cont = min(id)
      from #tmp_cobros
      where id > @w_cont
   end
   
end

return 0

ERROR:
   exec cobis..sp_cerror
     @t_debug = @t_debug,
     @t_file  = @t_file,
     @t_from  = @w_sp_name,
     @i_num   = @w_error
    return @w_error
    
go
