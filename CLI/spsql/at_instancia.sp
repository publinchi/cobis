
/************************************************************************/
/*      Archivo:                at_instancia.sp                         */
/*      Stored procedure:       sp_at_instancia                         */
/*      Base de datos:          cobis                                   */
/*      Producto:               CLIENTES                                */
/*      Disenado por:           Sandra Ortiz/Mauricio Bayas             */
/*      Fecha de escritura:     07-May-94                               */
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
/*                             PROPOSITO                                */
/*    Este programa procesa las transacciones del stored procedure      */
/*         Insercion de         cl_at_instancia                         */
/*         Modificacion de      cl_at_instancia                         */
/*         Borrado de           cl_at_instancia                         */
/*         Busqueda de          cl_at_instancia                         */
/*                           MODIFICACIONES                             */
/*    FECHA           AUTOR            RAZON                            */
/*    07-May-94       R. Minga V.      Emision Inicial                  */
/*    20-01-2021      GCO              Estandarizacion de clientes      */
/************************************************************************/
use cobis
GO
set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO
if exists (select * from sysobjects where name = 'sp_at_instancia')
   drop proc sp_at_instancia
go
create proc sp_at_instancia ( 
        @s_ssn           int = null, 
        @s_user          login = null, 
        @s_term          varchar(30) = null, 
        @s_date          datetime = null, 
        @s_srv           varchar(30) = null, 
        @s_lsrv          varchar(30) = null, 
        @s_ofi           smallint = null, 
        @s_rol           smallint = NULL, 
        @s_org_err       char(1) = NULL, 
        @s_error         int = NULL, 
        @s_sev           tinyint = NULL, 
        @s_msg           descripcion = NULL, 
        @s_org           char(1) = NULL, 
        @s_culture       varchar(10)   = 'NEUTRAL',         
        @t_debug         char(1) = 'N', 
        @t_file          varchar(10) = null, 
        @t_from          varchar(32) = null, 
        @t_trn           int = null, 
        @t_show_version  bit           = 0,     -- mostrar la version del programa          
        @i_operacion     char (1), 
        @i_tipo          char (1) = NULL, 
        @i_relacion      smallint = NULL, 
        @i_ente_i        int = NULL, 
        @i_ente_d        int = NULL, 
        @i_atributo      tinyint = NULL, 
        @i_valor         varchar (64) = NULL
        
) 
as 
declare 
   @w_return  int, 
   @w_sp_name varchar (32), 
   @w_seqnos  int, 
   @v_valor varchar (64), 
   @w_valor varchar (64), 
   @w_descripcion descripcion, 
   @w_tdato varchar(30),
   @w_sp_msg       varchar(132),
   @w_num           int,
   @w_param         int, 
   @w_diff          int,
   @w_date          datetime,
   @w_bloqueo       char(1)
        
select @w_sp_name = 'sp_at_instancia' 

/* VERSIONAMIENTO */
if @t_show_version = 1 begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end

--EVALUACION DEL TIPO DE TRANSACCION 
if (@t_trn <> 172142 and @i_operacion = 'I') or
   (@t_trn <> 172143 and @i_operacion = 'U') or
   (@t_trn <> 172144 and @i_operacion = 'D') or   
   (@t_trn <> 172145 and @i_operacion = 'S') or
   (@t_trn <> 172146 and @i_operacion = 'Q')    
begin 
   exec sp_cerror 
       @t_debug  = @t_debug, 
       @t_file   = @t_file, 
       @t_from   = @w_sp_name, 
       @i_num    = 1720070 
       /*  'No corresponde codigo de transaccion' */ 
   return 1
end

if @i_operacion in ('I', 'U', 'D')
begin
   /* VALIDACIONES LISTAS NEGRAS PARA EL CLIENTE */
   select @w_param         = pa_int      from cobis..cl_parametro where pa_nemonico = 'MVROC'  and pa_producto = 'CLI'
   if @i_ente_i is not null and @i_ente_i <> 0
   begin
      select @w_bloqueo = en_estado from cobis..cl_ente where en_ente = @i_ente_i
      if @w_bloqueo = 'S'
      begin
         exec sp_cerror
         @t_debug  = @t_debug,
         @t_file   = @t_file,
         @t_from   = @w_sp_name,
         @i_num    = 1720604
         return 1720604
      end
   end 
end

/* ** Insert ** */ 
if @i_operacion = 'I' 
begin 
if @t_trn = 172142 
begin 
   /* Verificar que exista el atributo para la relacion dada */ 
   if not exists ( select * 
                     from cl_at_relacion 
                    where ar_relacion = @i_relacion 
                      and ar_atributo = @i_atributo 
                 ) 
      begin 
          exec cobis..sp_cerror  
                @t_debug= @t_debug, 
                @t_file = @t_file, 
                @t_from = @w_sp_name, 
                @i_num  = 1720426  
           return 1 
      end 
   /* Verificar que existan los entes en la relacion dada */ 
   if not exists ( select * 
                     from cl_instancia  
                    where in_relacion = @i_relacion 
                      and in_ente_i = @i_ente_i 
                      and in_ente_d = @i_ente_d 
                 ) 
      begin 
          exec cobis..sp_cerror  
                @t_debug= @t_debug, 
                @t_file = @t_file, 
                @t_from = @w_sp_name, 
                @i_num  = 1720427  
           return 1 
      end 
   /* comprobar que no existan datos duplicados */ 
   if exists ( select * 
                 from cl_at_instancia  
                where ai_relacion = @i_relacion 
                  and ai_ente_i = @i_ente_i 
                  and ai_ente_d = @i_ente_d 
                  and ai_atributo = @i_atributo 
             ) 
      begin 
          exec cobis..sp_cerror  
                @t_debug= @t_debug, 
                @t_file = @t_file, 
                @t_from = @w_sp_name, 
                @i_num  = 1720428  
           return 1 
      end 
   begin tran 
      /* Insertar los datos de entrada */ 
      insert into cl_at_instancia ( ai_relacion, ai_ente_i, ai_ente_d,  
                                    ai_atributo, ai_valor)  
                           values ( @i_relacion, @i_ente_i, @i_ente_d, 
                                    @i_atributo, @i_valor) 
      /* Si no se puede insertar error */ 
      if @@error != 0 
      begin 
          exec cobis..sp_cerror  
                @t_debug= @t_debug, 
                @t_file = @t_file, 
                @t_from = @w_sp_name, 
                @i_num  = 1720429   
           return 1 
      end 
      /* Insertar los datos de entrada (Resiproco) */ 
      insert into cl_at_instancia ( ai_relacion, ai_ente_i, ai_ente_d,  
                                    ai_atributo, ai_valor)  
                           values ( @i_relacion, @i_ente_d, @i_ente_i, 
                                    @i_atributo, @i_valor) 
      /* Si no se puede insertar error */ 
      if @@error != 0 
      begin 
          exec cobis..sp_cerror  
                @t_debug= @t_debug, 
                @t_file = @t_file, 
                @t_from = @w_sp_name, 
                @i_num  = 1720429   
           return 1 
      end  
   commit tran 
   return 0 
end 
else 
begin 
    exec sp_cerror 
       @t_debug  = @t_debug, 
       @t_file   = @t_file, 
       @t_from   = @w_sp_name, 
       @i_num    = 1720070 
       /*  'No corresponde codigo de transaccion' */ 
    return 1 
end 
end 
/* ** Update ** */ 
if @i_operacion = 'U' 
begin 
if @t_trn = 172143 
begin 
   /* Verificar que exista el dato a modificar y que no este duplicado */ 
   select @w_valor = ai_valor 
     from cl_at_instancia 
    where ai_relacion = @i_relacion 
      and ai_ente_i = @i_ente_i 
      and ai_ente_d = @i_ente_d 
      and ai_atributo = @i_atributo 
   if @@rowcount != 1   
   begin 
         exec sp_cerror 
                @t_debug        = @t_debug, 
                @t_file         = @t_file, 
                @t_from         = @w_sp_name, 
                @i_num          = 1720426 
          return 1 
   end 
  /* Guargar los datos antiguos */ 
  select @v_valor = @w_valor 
  if @w_valor = @i_valor 
     select @w_valor = null, @v_valor = null 
  else 
     select @w_valor= @i_valor 
  
   begin tran 
      /* Modificar datos antiguos */ 
      update cl_at_instancia 
      set ai_valor = @i_valor 
      where ai_relacion = @i_relacion 
        and ai_ente_i = @i_ente_i 
        and ai_ente_d = @i_ente_d 
        and ai_atributo = @i_atributo 
      /* Error en actualizacion de atributos */ 
      if @@error != 0 
      begin 
          exec cobis..sp_cerror  
                @t_debug= @t_debug, 
                @t_file = @t_file, 
                @t_from = @w_sp_name, 
                @i_num  = 1720430   
           return 1 
      end 
      /* Modificar datos antiguos (Reciproco) */ 
      update cl_at_instancia 
      set ai_valor = @i_valor 
      where ai_relacion = @i_relacion 
        and ai_ente_i = @i_ente_d 
        and ai_ente_d = @i_ente_i 
        and ai_atributo = @i_atributo 
      /* Error en actualizacion de atributos */ 
      if @@error != 0 
      begin 
          exec cobis..sp_cerror  
                @t_debug= @t_debug, 
                @t_file = @t_file, 
                @t_from = @w_sp_name, 
                @i_num  = 1720430   
           return 1 
      end  
   commit tran 
   return 0 
end 
else 
begin 
    exec sp_cerror 
       @t_debug  = @t_debug, 
       @t_file   = @t_file, 
       @t_from   = @w_sp_name, 
       @i_num    = 1720070 
       /*  'No corresponde codigo de transaccion' */ 
    return 1 
end 
end 
/* ** Delete ** */ 
if @i_operacion = 'D' 
begin 
if @t_trn = 172144 
begin 
   /* Verificar que exista el dato a borrar */ 
    select @w_valor = ai_valor  
      from cl_at_instancia 
     where ai_relacion = @i_relacion 
       and ai_ente_i = @i_ente_i 
       and ai_ente_d = @i_ente_d 
       and ai_atributo = @i_atributo 
   if @@rowcount != 1   
   begin 
         exec sp_cerror 
                @t_debug        = @t_debug, 
                @t_file         = @t_file, 
                @t_from         = @w_sp_name, 
                @i_num          = 1720426 
          return 1 
   end 
   begin tran 
      /* borrar el registro correspondiente */ 
      delete cl_at_instancia 
       where ai_relacion = @i_relacion 
         and ai_ente_i = @i_ente_i 
         and ai_ente_d = @i_ente_d 
         and ai_atributo = @i_atributo 
      /* si no se puede borrar, error */ 
      if @@error != 0 
      begin 
          exec cobis..sp_cerror  
                @t_debug= @t_debug, 
                @t_file = @t_file, 
                @t_from = @w_sp_name, 
                @i_num  = 1720431   
           return 1 
      end 
      /* borrar el registro correspondiente (Reciproco) */ 
      delete cl_at_instancia 
       where ai_relacion = @i_relacion 
         and ai_ente_i = @i_ente_d 
         and ai_ente_d = @i_ente_i 
         and ai_atributo = @i_atributo 
      /* si no se puede borrar, error */ 
      if @@error != 0 
      begin 
          exec cobis..sp_cerror  
                @t_debug= @t_debug, 
                @t_file = @t_file, 
                @t_from = @w_sp_name, 
                @i_num  = 1720431   
           return 1 
      end  
   commit tran 
   return 0 
end 
else 
begin 
    exec sp_cerror 
       @t_debug  = @t_debug, 
       @t_file   = @t_file, 
       @t_from   = @w_sp_name, 
       @i_num    = 1720070 
       /*  'No corresponde codigo de transaccion' */ 
    return 1 
end 
end 
/* ** Search** */ 
if @i_operacion = 'S'  
begin 
if @t_trn = 172145 
begin 
   select  "5018" =  ai_atributo, 
           "5019" =  ar_descripcion, 
           "2999" =  ai_valor,
           "Catalogo" = ar_catalogo,
           "Base D."  = ar_bdatos,
           "Proce."   = ar_sprocedure          
     from cl_at_instancia, cl_at_relacion 
    where ai_relacion = ar_relacion 
      and ai_atributo = ar_atributo 
      and ai_relacion = @i_relacion 
      and ai_ente_i = @i_ente_i 
      and ai_ente_d = @i_ente_d 
return 0 
end 
else 
begin 
    exec sp_cerror 
       @t_debug  = @t_debug, 
       @t_file   = @t_file, 
       @t_from   = @w_sp_name, 
       @i_num    = 1720070 
       /*  'No corresponde codigo de transaccion' */ 
    return 1 
end 
end 
/* ** Query especifico ** */ 
if @i_operacion = "Q" 
begin 
if @t_trn = 172146 
begin 
   select @w_descripcion = ar_descripcion, 
          @w_valor = ltrim(rtrim(ai_valor)), 
      @w_tdato = ar_tdato 
     from cl_at_instancia, cl_at_relacion 
    where ai_relacion = ar_relacion 
      and ai_atributo = ar_atributo 
      and ai_relacion = @i_relacion 
      and ai_ente_i = @i_ente_i 
      and ai_ente_d = @i_ente_d 
      and ai_atributo = @i_atributo 
      if @@rowcount != 1 
         begin 
          exec cobis..sp_cerror  
                @t_debug= @t_debug, 
                @t_file = @t_file, 
                @t_from = @w_sp_name, 
                @i_num  = 1720426   
           return 1 
         end 
select @w_descripcion, @w_valor, @w_tdato 
return 0 
end 
else 
begin 
    exec sp_cerror 
       @t_debug  = @t_debug, 
       @t_file   = @t_file, 
       @t_from   = @w_sp_name, 
       @i_num    = 1720070 
       /*  'No corresponde codigo de transaccion' */ 
    return 1 
end 
end 
                                                                                                                                                                                                                           
go
