/***********************************************************************/
/*  Archivo:                    porcondusu.sp                          */
/*  Stored procedure:           sp_porc_cond                           */
/*  Base de Datos:              cob_cartera                            */
/*  Producto:                   Cartera                                */
/*  Disenado por:               Jonnatan Peña                          */
/*  Fecha de Documentacion:     27/May/09                              */
/***********************************************************************/
/*                              IMPORTANTE                             */
/*  Este programa es parte de los paquetes bancarios propiedad de      */
/*  "MACOSA",representantes exclusivos para el Ecuador de la           */
/*  AT&T                                                               */
/*  Su uso no autorizado queda expresamente prohibido asi como         */
/*  cualquier autorizacion o agregado hecho por alguno de sus          */
/*  usuario sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de MACOSA o su representante                 */
/***********************************************************************/
/*                          PROPOSITO                                  */
/*  Este stored procedure permite realizar las siguientes              */ 
/*  operaciones: Update, Query, All, Search, de las condonaciones      */
/*  que pueda realizar cada usuario que este autorizado para ello.     */
/***********************************************************************/
/*                              MODIFICACIONES                         */
/*  FECHA       AUTOR           RAZON                                  */
/*  27/May/09   Jonnatan peña   Emision Inicial                        */
/*  03/Feb/10   Ivonne Torres   Condonaci¢n por Rol Req00072           */
/***********************************************************************/

use cob_cartera
go


if exists (select 1 from cob_cartera..sysobjects where name = 'sp_porc_cond' and xtype = 'P')
    drop proc sp_porc_cond
go


create proc sp_porc_cond (
   @t_debug              char(1)     = 'N',
   @t_file               varchar(14) = null,  
   @t_trn                smallint    = null,
   @t_from               varchar(30) = null,
   @i_usuario            varchar(64) = '1',
   @i_rubros             varchar(64) = null,
   @i_porcentaje         smallint    = null,
   @i_operacion          char(1)     = null,
   @i_des_rubro          varchar(64) = null,
   @i_cargo              int         = null    -- ITO 3/Feb/2010 Req00072
 )
as
declare
   
   @w_return             int,          
   @w_sp_name            varchar(32),  
   @w_existe             tinyint,      
   @w_msg                varchar(100),
   @w_error              int,
-- @w_usuario            varchar(64),       -- ITO 3/Feb/2010 Req00072
   @w_rubro              varchar(64),     
   @w_porcentaje         smallint,
   @w_nombre             varchar(100),
   @w_des_rubro          varchar(64),
   @w_cargo              int                -- ITO 3/Feb/2010 Req00072

   select @w_sp_name  = 'sp_porc_cond' 
                
/* INSERT EL PORCENTAJE DE CONDONACION*/

if @i_operacion = 'I' begin

   if exists (select 1 from ca_autorizacion_condonacion
               where ac_cargo = @i_cargo 
                 and ac_rubro = @i_rubros) 
   select @i_operacion = 'U'
   else begin
 
      insert ca_autorizacion_condonacion
      values (@i_usuario,'USUARIO COBIS', @i_rubros, @i_des_rubro, @i_porcentaje, @i_cargo)  -- ITO 3/Feb/2010 Req00072
                   
      if @@error <> 0  begin
         select
         @w_error = 710001,
         @w_msg   = 'ERROR AL INSERTAR LA CONDONACION POR CARGO'    -- ITO 3/Feb/2010 Req00072
         goto ERROR
      end   	
   end	   
end
   
         
/* BUSCA EL PORCENTAJE DE CONDONACION*/

if @i_operacion = 'S' begin

   select 
   'CARGO'             = ac_cargo,
   'DESCRIPCION CARGO' = valor,
   'RUBROS'            = ac_rubro, 
   'DESCRIPCION'       = ac_des_rubro,
   'PORCENTAJE'                 = ac_procentaje
   from ca_autorizacion_condonacion, cobis..cl_catalogo 
   where tabla  = (select codigo from cobis..cl_tabla where tabla = 'cl_cargo')
   and   ac_cargo = codigo 

         
   if @@rowcount = 0  begin                        
      select                                 
      @w_error = 2101005,                    
      @w_msg   = 'NO EXISTEN REGISTROS'     
      goto ERROR                             
   end                                  
             
end
       
/* UPDATE EL PORCENTAJE DE CONDONACION*/

if @i_operacion = 'U' begin   
    
   update ca_autorizacion_condonacion
   set ac_cargo       = @i_cargo,     -- ITO 3/Feb/2010 Req00072
       ac_procentaje  = @i_porcentaje     
   where ac_cargo     = @i_cargo        -- ITO 3/Feb/2010 Req00072
   and   ac_rubro     = @i_rubros
  
   if @@error <> 0  begin
      select
      @w_error = 710002,
      @w_msg   = 'ERROR AL MODIFICAR LA CONDONACION POR CARGO'  -- ITO 3/Feb/2010 Req00072
      goto ERROR
   end         
end

/* DELETE EL PORCENTAJE DE CONDONACION*/

if @i_operacion = 'D' begin 
 
   delete ca_autorizacion_condonacion 
   where ac_cargo   = @i_cargo   -- ITO 3/Feb/2010 Req00072
   and   ac_rubro   = @i_rubros          
   
   if @@error <> 0  begin
      select
      @w_error = 710003,
      @w_msg   = 'ERROR AL ELIMINAR LA CONDONACION POR CARGO' -- ITO 3/Feb/2010 Req00072
      goto ERROR
   end   		   
end



/* QUERY DEL PORCENTAJE DE CONDONACION**/
if @i_operacion = 'Q' begin 

   select 
   @w_cargo       = ac_cargo,            -- ITO 3/Feb/2010 Req00072
-- @w_nombre      = ac_nombre,         -- ITO 3/Feb/2010 Req00072
   @w_rubro       = ac_rubro, 
   @w_des_rubro   = ac_des_rubro,   
   @w_porcentaje  = ac_procentaje
   from ca_autorizacion_condonacion
   where ac_cargo = @i_cargo             -- ITO 3/Feb/2010 Req00072
   and   ac_rubro   = @i_rubros 
   
   select 
   @w_cargo,               -- ITO 3/Feb/2010 Req00072
-- @w_nombre, 
   @w_rubro,  
   @w_des_rubro,   
   @w_porcentaje         	
end


return 0

ERROR:

exec cobis..sp_cerror
@t_debug = 'N',
@t_file  = null, 
@t_from  = @w_sp_name,
@i_num   = @w_error,
@i_msg   = @w_msg

return @w_error
go