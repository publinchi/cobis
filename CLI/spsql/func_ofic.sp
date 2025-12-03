/************************************************************************/
/*   ARCHIVO:              func_ofic.sp                                 */
/*   NOMBRE LOGICO:        sp_func_ofic                                 */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Clientes                                     */
/*   Disenado por:         cobis                                        */
/*   Fecha de escritura:   30-Julio-19                                  */
/************************************************************************/
/*                              IMPORTANTE                              */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*  de COBISCorp.                                                       */
/*  Su uso no    autorizado queda  expresamente   prohibido asi como    */
/*  cualquier    alteracion o  agregado  hecho por    alguno  de sus    */
/*  usuarios sin el debido consentimiento por   escrito de COBISCorp.   */
/*  Este programa esta protegido por la ley de   derechos de autor      */
/*  y por las    convenciones  internacionales   de  propiedad inte-    */
/*  lectual.   Su uso no  autorizado dara  derecho a    COBISCorp para  */
/*  obtener ordenes  de secuestro o  retencion y para  perseguir        */
/*  penalmente a los autores de cualquier   infraccion.                 */
/************************************************************************/
/*                     PROPOSITO                                        */
/*  El sp permite realizar consulta sobre oficinas y funcionarios       */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*      FECHA           AUTOR           RAZON                           */
/*      30/07/19        JSDV            Emision Inicial                 */
/*      09/06/20        MBA             Estandarizacion sp y seguridades*/
/*      07/07/20        FSAP            Estandarizacion clientes        */
/************************************************************************/

use cobis
go

SET ANSI_NULLS ON
go
SET QUOTED_IDENTIFIER OFF
go

if exists(select 1 from sysobjects where name = 'sp_func_ofic')
    drop proc sp_func_ofic
go

create procedure sp_func_ofic (
   @s_ssn                 int = NULL,
   @s_user                login = NULL,
   @s_sesn                int = NULL,
   @s_term                varchar(32) = NULL,
   @s_date                datetime = NULL,
   @s_srv                 varchar(30) = NULL,
   @s_lsrv                varchar(30) = NULL, 
   @s_rol                 smallint = NULL,
   @s_ofi                 smallint = NULL,
   @s_org_err             char(1) = NULL,
   @s_error               int = NULL,
   @s_sev                 tinyint = NULL,
   @s_msg                 descripcion = NULL,
   @s_org                 char(1) = NULL,
   @t_show_version        bit = 0,
   @t_debug               char(1) = 'N',
   @t_file                varchar(14) = null,
   @t_from                varchar(32) = null,
   @t_trn                 int =NULL,
   @i_operacion           varchar(1),
   @i_filial              tinyint = null,
   @i_oficina             smallint = null,
   @i_funcionar           smallint=null,
   @i_oficial             smallint=null
   
)
as
 declare
    @w_sp_name            varchar(32),
	@w_sp_msg             varchar(132),
    @w_today              datetime,
    @w_var                int,
    @w_aux                tinyint,   
    @w_codigo             int,
    @w_departamento       smallint,
    @w_filial             tinyint,
    @w_oficina            smallint,
    @w_descripcion        descripcion,
    @w_o_departamento     smallint,
    @w_o_oficina          smallint,
    @w_nivel              tinyint,
    @v_departamento       smallint,
    @v_filial             tinyint,
    @v_oficina            smallint,
    @v_descripcion        descripcion,
    @v_o_departamento     smallint,
    @v_o_oficina          smallint,
    @v_nivel              tinyint,
    @o_departamento       tinyint,
    @o_filial             tinyint,
    @o_finombre           descripcion,
    @o_oficina            smallint,
    @o_lonombre           descripcion,
    @o_descripcion        descripcion,
    @o_o_departamento     smallint,
    @o_o_oficina          smallint,
    @o_denombre           descripcion,
    @o_nivel              tinyint,
    @w_return             int,
    @w_cmdtransrv         varchar(64),
    @w_nt_nombre          varchar(32),
    @w_num_nodos          smallint,    
    @w_contador           smallint,
    @w_clave              int,
    @w_errmsj             int,
    @o_secuencial         int,
	@w_oficfunc           int


/* captura nombre de stored procedure  */
select @w_sp_name = 'sp_func_ofic'
select @w_sp_msg = ''

/*--VERSIONAMIENTO--*/
if @t_show_version = 1
begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end
/*--FIN DE VERSIONAMIENTO--*/   

   
   -- VALIDACION DE TRANSACCIONES
   if (@t_trn <> 172011)
   begin
      exec sp_cerror
       @t_debug  = @t_debug,
       @t_file   = @t_file,
       @t_from   = @w_sp_name,
       @i_num    = 1720075                  
       --NO CORRESPONDE CODIGO DE TRANSACCION
      return 1720075
   end

   --VALIDACION MENSAJE ERROR
   if (@i_funcionar > 0)
      select @w_errmsj = 1720086
   else
      select @w_errmsj = 1720087
   
   
-- INSERT
if (@i_operacion = 'I')
   begin      
  
   --SECUENCIAL TABLA
    exec sp_cseqnos
         @t_debug    = @t_debug,
         @t_file     = @t_file,
         @t_from     = @w_sp_name,
         @i_tabla    = 'cl_ofic_func',
         @o_siguiente= @o_secuencial out
     
   --VALIDACION: RELACION OFICINA - SUPERVISOR NO EXISTA
      if exists(select 1 
                  from cl_ofic_func
                 where of_filial     = @i_filial 
                   and of_oficina    = @i_oficina
                   and of_funcionar  = @i_funcionar)
                   --and of_secuencial = @o_secuencial)
       begin
          exec sp_cerror
               @t_debug = @t_debug,
               @t_file  = @t_file,
               @t_from  = @w_sp_name,
               @i_num   = 1720088                        
             --EL SUPERVISOR YA ESTA ASOCIADO A ESA OFICINA
          return 1720088
       end
            
       begin tran
          insert into cl_ofic_func (of_secuencial,of_oficina, of_filial, of_funcionar)
                            values (@o_secuencial,@i_oficina, @i_filial, @i_funcionar)
          if (@@error != 0)
          begin
             exec sp_cerror
              @t_debug  = @t_debug,
              @t_file   = @t_file,
              @t_from   = @w_sp_name,
              @i_num    = 1720089                     
              --ERROR EN CREACION DE RELACION OFICINA - SUPERVISOR
              return 1720089
          end
            
          --TRANSACCION OFICINA -SUPERVISOR 
          insert into ts_ofic_func (secuencia,  tipo_transaccion,   clase,       fecha, 
                                    oficina_s,  usuario,            terminal_s,  srv,
                                    lsrv,       hora,               filial,      oficina,
                                    funcionario)
                            values (@s_ssn,     172011,              'N',         @s_date,
                                    @s_ofi,     @s_user,            @s_term,     @s_srv, 
                                    @s_lsrv,    getdate(),          @i_filial,   @i_oficina,
                                    @i_funcionar)
                   
          if (@@error != 0)
             begin
                exec sp_cerror
                 @t_debug = @t_debug,
                 @t_file  = @t_file,
                 @t_from  = @w_sp_name,
                 @i_num   = 1720090
                 --'ERROR EN CREACION DE TRANSACCION OFICNA SUPERVISOR
                 return 1720090
              end      
                  
       commit tran            
              
       return 0
   end
      
--DELETE
if (@i_operacion = 'D')
begin
   --VALIDAR ROLES DE UN SUPERVISOR
      select @w_oficfunc  = of_secuencial
       from cl_ofic_func  
      where of_oficina   = @i_oficina
        and of_filial    = @i_filial
        and of_funcionar = @i_funcionar

    if exists(select  1 from cl_ofic_func_rol
           where or_oficfunc   = @w_oficfunc)
    begin
       exec sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file,
            @t_from  = @w_sp_name,
            @i_num   = 1720091
            --'ERROR, NO SE PUEDE ELIMINAR EL SUPERVISOR TIENE ROLES ASIGNADOS
       return 1720091
    end

    begin tran
        
      --ELIMINANDO SUPERVISOR DE OFICINA
      delete from cl_ofic_func
                 where of_oficina   = @i_oficina
                   and of_filial    = @i_filial
                   and of_funcionar = @i_funcionar
         
      if (@@error != 0)
         begin
            exec sp_cerror
               @t_debug  = @t_debug,
               @t_file   = @t_file,
               @t_from   = @w_sp_name,
               @i_num    = 1720092
            --ERROR AL ELIMINAR RELACION OFICINA - SUPERVISOR
            return 1720092
         end
      
      --TRANSACCION OFICINA - SUPERVISOR
      insert into ts_ofic_func (secuencia, tipo_transaccion, clase,      fecha,
                                oficina_s, usuario,          terminal_s, srv, 
                                lsrv,      hora,             filial,     oficina,
                                funcionario)
                        values (@s_ssn,    172011,           'B',        @s_date,
                                @s_ofi,    @s_user,          @s_term,    @s_srv, 
                                @s_lsrv,   getdate(),        @i_filial,  @i_oficina,
                                @i_funcionar)
            
      if (@@error != 0)
         begin
            exec sp_cerror
               @t_debug  = @t_debug,
               @t_file   = @t_file,
               @t_from   = @w_sp_name,
               @i_num    = 1720093
            --ERROR EN CREACION DE TRANSACCION DE SERVICIO FINANCIERO
            return 1720093
         end
      
   commit tran
   
   return 0
end
         
--BUSQUEDA DE TODAS LOS SUPERVISORS ASOCIADOS A UNA OFICINA
if (@i_operacion = 'S')
   begin
      set rowcount 20
      select 'CODIGO'     = f.fu_funcionario,   
             'NOMBRE'     = f.fu_nombre,
             'SECUENCIAL' = o.of_secuencial
        from cl_ofic_func o,cl_funcionario f
       where o.of_funcionar = f.fu_funcionario
         and o.of_oficina   = @i_oficina
         and o.of_filial    = @i_filial
         and (@i_funcionar is null or f.fu_funcionario > @i_funcionar)
         order by f.fu_funcionario
   
      if (@@rowcount=0)
         begin
            exec sp_cerror
             @t_debug  = @t_debug,
             @t_file   = @t_file,
             @t_from   = @w_sp_name,
             @i_num    = @w_errmsj
            set rowcount 0
            return 1
            --NO HAY REGISTROS
         end
       set rowcount 0
    end   
          
--BUSQUEDA DE UN FUCNIONARIO POR ID
if (@i_operacion = 'Q')
   begin
      select 'CODIGO'=f.fu_funcionario,   
             'NOMBRE'=f.fu_nombre,
             'SECUENCIAL' = o.of_secuencial
      from cl_ofic_func o,cl_funcionario f
     where o.of_funcionar= f.fu_funcionario
       and o.of_oficina  = @i_oficina
       and o.of_filial   = @i_filial
       and o.of_funcionar= @i_funcionar
   
      if (@@rowcount=0)
         begin
            exec sp_cerror
             @t_debug  = @t_debug,
             @t_file   = @t_file,
             @t_from   = @w_sp_name,
             @i_num    = 1720094
            set rowcount 0
            return 1
            --NO HAY MAS REGISTROS
         end  
end

if (@i_operacion = 'B')
begin
    select 'CODIGO' = oc_oficial,   
        'NOMBRE' = fu_nombre
    from cobis..cl_oficina inner join cobis..cl_funcionario
        on fu_oficina = of_oficina inner join cobis..cc_oficial
        on oc_funcionario = fu_funcionario
    where of_oficina = @i_oficina
        
    if (@@rowcount = 0)
   begin
      -- USTED NO TIENE ASIGNADO UN CODIGO DE OFICIAL PARA REALIZAR ESTE TIPO DE CAMBIOS 
      exec cobis..sp_cerror
           @t_debug     = @t_debug,
           @t_file      = @t_file,
           @t_from      = @w_sp_name,
           @i_num       = 1720095
      return 1
   end
end
   
-- BUSQUEDA DE OFICIAL FILTRANDO POR ID   
if (@i_operacion = 'L')
begin

    select 'CODIGO' = oc_oficial,   
           'NOMBRE' = fu_nombre
    from cobis..cc_oficial inner join cobis..cl_funcionario 
        on oc_funcionario = fu_funcionario
        where oc_oficial = @i_oficial
        
    if (@@rowcount = 0)
   begin
      -- USTED NO TIENE ASIGNADO UN CODIGO DE OFICIAL PARA REALIZAR ESTE TIPO DE CAMBIOS 
      exec cobis..sp_cerror
           @t_debug     = @t_debug,
           @t_file      = @t_file,
           @t_from      = @w_sp_name,
           @i_num       = 1720095
      return 1
   end
end
   
return 0
go

