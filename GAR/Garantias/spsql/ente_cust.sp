/*************************************************************************/
/*   Archivo:              ente_cust.sp                                  */
/*   Stored procedure:     sp_ente_custodia                              */
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
IF OBJECT_ID('dbo.sp_ente_custodia') IS NOT NULL
    DROP PROCEDURE dbo.sp_ente_custodia
go
create proc dbo.sp_ente_custodia  (
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
   @i_ente               int      = null,
   @i_oficial            smallint = null,
   @i_ente1              int      = null,
   @i_ente2              int      = null,
   @i_ente3              int      = null,
   @i_nombre             descripcion = null,
   @i_ced_ruc            varchar(30) = null,
   @i_cuenta             varchar(20) = null,
   @i_tipo_ente          char(1)     = null,
   @i_cond1              varchar(8)  = null,
   @i_param1             varchar(8)  = null,
   @i_codigo_externo     varchar(64) = null,
   @o_tipo_cta           char(3)     = null out
)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_ente1              int,     
   @w_ente2              int,      
   @w_nombre             descripcion,
   @w_ced_ruc            varchar(30),
   @w_tipo_cta           char(3),
   @w_tipocta            char(3),
   @w_codigo_externo     varchar(64)

select @w_today = convert(varchar(10),getdate(),101)
select @w_sp_name = 'sp_ente_custodia'

/***********************************************************/
/* Codigos de Transacciones                                */

if (@t_trn <> 19140 and @i_operacion = 'S') or
   (@t_trn <> 19141 and @i_operacion = 'V') or
   (@t_trn <> 19142 and @i_operacion = 'C') or
   (@t_trn <> 19143 and @i_operacion = 'M') or
   (@t_trn <> 19144 and @i_operacion = 'B') or
   (@t_trn <> 19145 and @i_operacion = 'O') or
   (@t_trn <> 19146 and @i_operacion = 'Z') or
   (@t_trn <> 19147 and @i_operacion = 'R') 
     
begin
/* tipo de transaccion no corresponde */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file, 
    @t_from  = @w_sp_name,

    @i_num   = 1901006
    return 1 
end

if @i_operacion = 'S'
begin
      set rowcount 20
      if @i_modo = 0 
      begin
         select 'ENTE' = en_ente,'NOMBRE' = p_p_apellido + ' ' + p_s_apellido + ' ' + en_nombre,
                'CEDULA' = en_ced_ruc, 'OFICIAL' = en_oficial
         from cobis..cl_ente
         where (en_ente >= @i_ente1 or @i_ente1 is null) and
               (en_ente <= @i_ente2 or @i_ente2 is null) and 
               (p_p_apellido + ' ' + p_s_apellido + ' ' + en_nombre like @i_nombre or @i_nombre is null) and
               (en_ced_ruc like @i_ced_ruc or @i_ced_ruc is null) and
               (en_subtipo = @i_tipo_ente or @i_tipo_ente is null)
         order by en_ente
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
      else 
      begin
         select 'ENTE' = en_ente,'NOMBRE' = p_p_apellido + ' ' + p_s_apellido + ' ' + en_nombre,
                'CEDULA' = en_ced_ruc, 'OFICIAL' = en_oficial  
         from cobis..cl_ente
         where (en_ente > @i_ente3) and
               (en_ente >= @i_ente1 or @i_ente1 is null) and
               (en_ente <= @i_ente2 or @i_ente2 is null) and
               (p_p_apellido + ' ' + p_s_apellido + ' ' + en_nombre like @i_nombre or @i_nombre is null) and
               (en_ced_ruc like @i_ced_ruc or @i_ced_ruc is null) and
               (en_subtipo = @i_tipo_ente or @i_tipo_ente is null)
         order by en_ente
         if @@rowcount = 0
         begin
           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file, 
           @t_from  = @w_sp_name,
           @i_num   = 1901004
           return 1 
         end
      end
end

if @i_operacion = 'V'
begin
       select p_p_apellido + ' ' + p_s_apellido + ' ' + en_nombre
         from cobis..cl_ente
         where 
               en_ente = @i_ente
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

if @i_operacion = 'C'
begin
       
    /* if exists (select 1 
         from cob_cuentas..cc_ctacte
         where 
               cc_cliente = @i_ente  and
               cc_cta_banco = @i_cuenta)
      begin 
         select @w_tipo_cta = 'CTE'   
         --print "Existe la cuenta cte del Cliente" 
      end 
      else
      begin*/
         if exists (select 1
           from cob_ahorros..ah_cuenta
           where ah_cliente = @i_ente
             and ah_cta_banco = @i_cuenta)
         begin
            select @w_tipo_cta = 'AHO'   
            --print "Existe la cuenta aho del Cliente" 
         end
         else
         begin
              exec cobis..sp_cerror
              @t_debug = @t_debug,
              @t_file  = @t_file, 
              @t_from  = @w_sp_name,
              @i_num   = 1901008
              return 1 
         end
      /*end*/
      select @o_tipo_cta = @w_tipo_cta
      select @o_tipo_cta
end 

if @i_operacion = 'M'
begin
       
       if exists (select * 
         /*from cob_cuentas..cc_ctacte,*/
           from   cob_ahorros..ah_cuenta
         where 
               (
                /*cc_cta_banco = @i_cuenta
                or */
                ah_cta_banco = @i_cuenta))
      begin  
         --print "Existe la cuenta del Cliente" 
         return 0 
      end 
      else
      begin
           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file, 
           @t_from  = @w_sp_name,
           @i_num   = 1901008
           return 1 
      end

end 

if @i_operacion = 'B'
begin
   create table #cuentas(tipocta  varchar(3),
                         numero   varchar(24))
   select @i_ente = convert(int,@i_cond1)
/*   if exists (select 1
      from cob_cuentas..cc_ctacte
     where cc_cliente = @i_ente)  
   begin
     select @w_tipocta = 'CTE'
     insert into #cuentas
     select @w_tipocta,cc_cta_banco
      from cob_cuentas..cc_ctacte
     where cc_cliente = @i_ente
   end*/
   if exists (select 1
      from cob_ahorros..ah_cuenta
     where ah_cliente = @i_ente)
   begin
      select @w_tipocta = 'AHO'
      insert into #cuentas
      select @w_tipocta,ah_cta_banco
        from cob_ahorros..ah_cuenta
       where ah_cliente = @i_ente
  end
  select 'TIPO CUENTA' = tipocta,'NUMERO CUENTA' = numero from #cuentas
 /* if @@rowcount = 0
  begin
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1901003
      return 1 
  end */
end

if @i_operacion = 'O'
begin
    select p_p_apellido + ' ' + p_s_apellido + ' ' + en_nombre,
           convert(varchar(10),en_oficial) + '  ' + fu_nombre
      from cobis..cc_oficial,cobis..cl_ente,cobis..cl_funcionario
     where en_ente        = @i_ente
       and en_oficial     = oc_oficial
       and oc_funcionario = fu_funcionario

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

if @i_operacion = 'Z'
begin
    select fu_nombre
      from cobis..cc_oficial,cobis..cl_funcionario
     where oc_oficial     = @i_oficial
       and oc_funcionario = fu_funcionario

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

if @i_operacion = 'R'
begin
   if @i_oficial is null
      select @i_oficial = convert(int,@i_param1)

   /*set rowcount 20*/
   select "OFICIAL"=oc_oficial,"NOMBRE OFICIAL"=fu_nombre
     from cobis..cl_funcionario,cobis..cc_oficial
    where oc_funcionario = fu_funcionario
      and (oc_oficial > @i_oficial or @i_oficial is null) 
    order by oc_oficial
   if @@rowcount = 0
   begin
      if @i_oficial is null
      begin
      /*Registro no existe */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1901003
        return 1 
      end
      else
      begin
      /*Registro no existe */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1901004
        return 1 
      end    
   end
end
go