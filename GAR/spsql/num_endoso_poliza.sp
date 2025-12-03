/*************************************************************************/
/*   Archivo:              num_endoso_poliza.sp                          */
/*   Stored procedure:     sp_num_endoso_poliza                          */
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
IF OBJECT_ID('dbo.sp_num_endoso_poliza') IS NOT NULL
    DROP PROCEDURE dbo.sp_num_endoso_poliza
go
create proc dbo.sp_num_endoso_poliza (
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

   @i_aseguradora        catalogo  = null,
   @i_tipo_poliza_veh    catalogo  = null,
   @i_num_poliza         varchar(15)  = null,
   @i_oficina            smallint  = null,
   
   @i_aseguradora_new    catalogo  = null,
   @i_tipo_poliza_veh_new catalogo  = null,
   @i_num_poliza_new     varchar(15)  = null,
   @i_oficina_new        smallint  = null,
   @i_secuencial         int  = null
)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/

   @w_aseguradora        catalogo  ,
   @w_tipo_poliza_veh    catalogo  ,
   @w_num_poliza         varchar(15) ,
   @w_oficina            smallint  ,
   @w_secuencial         int,  
   @w_error		 int

select @w_today = convert(varchar(10),getdate(),101)
select @w_sp_name = 'sp_num_endoso_poliza'

/***********************************************************/
/* Codigos de Transacciones                                */

if (@t_trn <> 19746 and @i_operacion = 'I') or
   (@t_trn <> 19747 and @i_operacion = 'U') or
   (@t_trn <> 19748 and @i_operacion = 'D') or
   (@t_trn <> 19745 and @i_operacion = 'S') 
begin
/* tipo de transaccion no corresponde */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file, 
    @t_from  = @w_sp_name,
    @i_num   = 1901006
    return 1 
end

if isnull(@i_tipo_poliza_veh,'') = '' select @i_tipo_poliza_veh = ' '

/* Chequeo de Existencias */
/**************************/
if @i_operacion <> 'S' 
begin
    select 
     @w_aseguradora = ec_empresa,
     @w_tipo_poliza_veh = ec_tipo,    
     @w_num_poliza  = ec_poliza,  
     @w_oficina     = ec_oficina,
     @w_secuencial  = ec_secuencial
    from cob_custodia..cu_endoso_colonial
    where ec_empresa = @i_aseguradora
      and ec_tipo    = @i_tipo_poliza_veh
      and ec_poliza  = @i_num_poliza
      and ec_oficina = @i_oficina

    if @@rowcount > 0
       select @w_existe = 1
    else
       select @w_existe = 0
end

/* VALIDACION DE CAMPOS NULOS */
/******************************/
if @i_operacion = 'I' or @i_operacion = 'U'
begin

    if @i_aseguradora is null or @i_num_poliza is null
    begin
    /* Campos NOT NULL con valores nulos */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1901001
        return 1 
    end
end

/* Insercion del registro */
/**************************/

if @i_operacion = 'I'
begin
    if @w_existe = 1
    begin
    /* Registro ya existe */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1901002
        return 1 
    end

    begin tran

         insert into cu_endoso_colonial(
		ec_empresa      ,
		ec_tipo         ,
		ec_poliza       ,
		ec_oficina      ,
		ec_secuencial   )
         values (
              @i_aseguradora,
              @i_tipo_poliza_veh,
              @i_num_poliza,
              @i_oficina,
              @i_secuencial)

         if @@error <> 0 
         begin
         /* Error en insercion de registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903001
             return 1 
         end

         /* Transaccion de Servicio */
         /***************************/

         insert into ts_endoso_colonial
         values (@s_ssn,@t_trn,'N',@s_date,@s_user,@s_term,@s_ofi,'cu_endoso_colonial',
              @i_aseguradora,
              @i_tipo_poliza_veh,
              @i_num_poliza,
              @i_oficina,
              @i_secuencial)

         if @@error <> 0 
         begin
         /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903003
             return 1 
         end
    commit tran 
    return 0
end

/* Actualizacion del registro */
/******************************/

if @i_operacion = 'U'
begin
    if @w_existe = 0
    begin
    /* Registro a actualizar no existe */
        exec cobis..sp_cerror
        @t_debug = @t_debug,

        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1905002
        return 1 
    end

    begin tran
         update cob_custodia..cu_endoso_colonial
         set 
             ec_empresa = @i_aseguradora_new,
             ec_tipo    = @i_tipo_poliza_veh_new,
             ec_poliza  = @i_num_poliza_new,
             ec_oficina = @i_oficina_new,
             ec_secuencial = @i_secuencial
         where ec_empresa = @i_aseguradora
           and ec_tipo    = @i_tipo_poliza_veh
           and ec_poliza  = @i_num_poliza
           and ec_oficina = @i_oficina

         if @@error <> 0 
         begin
         /* Error en actualizacion de registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name, 
             @i_num   = 1905001
             return 1 
         end

         /* Transaccion de Servicio */
         /***************************/

         insert into ts_endoso_colonial
         values (@s_ssn,@t_trn,'P',@s_date,@s_user,@s_term,@s_ofi,'cu_endoso_colonial',
              @w_aseguradora,
              @w_tipo_poliza_veh,
              @w_num_poliza,
              @w_oficina,
              @w_secuencial)

         if @@error <> 0 
         begin
         /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903003
             return 1 
         end

         /* Transaccion de Servicio */
         /***************************/

         insert into ts_endoso_colonial
         values (@s_ssn,@t_trn,'A',@s_date,@s_user,@s_term,@s_ofi,'cu_endoso_colonial',
              @i_aseguradora,
              @i_tipo_poliza_veh,
              @i_num_poliza,
              @i_oficina,
              @i_secuencial)

         if @@error <> 0 
         begin
         /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903003
             return 1 
         end
    commit tran
    return 0
end

/* Eliminacion de registros */
/****************************/

if @i_operacion = 'D'
begin
    if @w_existe = 0
    begin
    /* Registro a eliminar no existe */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1907002
        return 1 
    end

/***** Integridad Referencial *****/
/*****                        *****/
   if exists (select * from cu_poliza
               where po_aseguradora   = @i_aseguradora
                 and po_poliza like @i_num_poliza + '%')
   begin
      select @w_error = 1909018
      goto error
   end

    begin tran
         delete cob_custodia..cu_endoso_colonial
         where ec_empresa = @i_aseguradora
           and ec_tipo    = @i_tipo_poliza_veh
           and ec_poliza  = @i_num_poliza
           and ec_oficina = @i_oficina
                                      
         if @@error <> 0
         begin
         /*Error en eliminacion de registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1907001
             return 1 
         end

         /* Transaccion de Servicio */
         /***************************/
         insert into ts_endoso_colonial
         values (@s_ssn,@t_trn,'B',@s_date,@s_user,@s_term,@s_ofi,'cu_endoso_colonial',
              @w_aseguradora,
              @w_tipo_poliza_veh,
              @w_num_poliza,
              @w_oficina,
              @w_secuencial)

         if @@error <> 0 
         begin
         /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903003
             return 1 
         end
    commit tran
    return 0
end

if @i_operacion = 'S'
begin

   create table #cu_endoso_colonial (
        secuencial numeric identity,
	ec_empresa      varchar(20)  not null,
	ec_tipo         catalogo     not null,
	ec_poliza       catalogo     not null,
	ec_oficina      smallint     not null,
	ec_secuencial   int          not null
  )

  /* Adaptive Server has expanded all '*' elements in the following statement */ insert into #cu_endoso_colonial
  select X.ec_empresa, X.ec_tipo, X.ec_poliza, X.ec_oficina, X.ec_secuencial 
  from cu_endoso_colonial X
  order by ec_empresa, ec_tipo, ec_poliza, ec_oficina

      set rowcount 20
	 select "ASEGURADORA" = ec_empresa, 
		"NOMBRE ASEG." = (select b.valor from cobis..cl_tabla a , cobis..cl_catalogo b 
				   where a.tabla = 'cu_des_aseguradora'
				     and a.codigo = b.tabla
				     and b.codigo = X.ec_empresa),
		"TIPO POLIZA VEH"=ec_tipo,
		"NOMBRE TP.POL.VEH" = (select b.valor from cobis..cl_tabla a , cobis..cl_catalogo b 
				   where a.tabla = 'cu_tipo_poliza_veh'
				     and a.codigo = b.tabla
				     and b.codigo = X.ec_tipo),
		"NRO POLIZA" = ec_poliza,
		"OFICINA" = ec_oficina,
		"NOMBRE OFICINA" = (select b.valor from cobis..cl_tabla a , cobis..cl_catalogo b 
				   where a.tabla = 'cr_oficina_tramites'
				     and a.codigo = b.tabla
				     and b.codigo = convert(varchar(10),X.ec_oficina)),
		"SECUENCIAL ENDOSO" = ec_secuencial               
	   from #cu_endoso_colonial X
	   where secuencial > isnull(@i_secuencial,0) -- or ec_empresa > convert(varchar(2), @i_secuencial))
	 order by ec_empresa, ec_tipo, ec_poliza, ec_oficina

	 if @@rowcount = 0 and @i_secuencial <> 20   --AMH 06/01/2016 Req 1403
	  begin
	   exec cobis..sp_cerror
	   @t_debug = @t_debug,
	   @t_file  = @t_file, 
	   @t_from  = @w_sp_name,
	   @i_num   = 1901003 
	   return 1 
	  end
end


return 0

error:    /* Rutina que dispara sp_cerror dado el codigo de error */
     exec cobis..sp_cerror
     @t_debug = @t_debug,
     @t_file  = @t_file, 
     @t_from  = @w_sp_name,
     @i_num   = @w_error
     return 1
go