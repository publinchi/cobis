/***********************************************************************/
/*  Archivo:                    cacambnota.sp                          */
/*  Stored procedure:           sp_camb_nota                           */
/*  Base de Datos:              cob_cartera                            */
/*  Producto:                   Cartera                                */
/*  Disenado por:               Jonnatan Peña                          */
/*  Fecha de Documentacion:     26/Feb/09                              */
/***********************************************************************/
/*                              IMPORTANTE                             */
/*  Este programa es parte de los paquetes bancarios propiedad de      */
/*  'MACOSA',representantes exclusivos para el Ecuador de la           */
/*  AT&T                                                               */
/*  Su uso no autorizado queda expresamente prohibido asi como         */
/*  cualquier autorizacion o agregado hecho por alguno de sus          */
/*  usuario sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de MACOSA o su representante                 */
/***********************************************************************/
/*                          PROPOSITO                                  */
/*  Este stored procedure permite realizar las siguientes              */ 
/*  operaciones: Update, Query, All, Search, de las operaciones del    */
/*  cliente que tengan la posibilidad de cambiar la nota interna       */
/***********************************************************************/
/*                              MODIFICACIONES                         */
/*  FECHA       AUTOR           RAZON                                  */
/*  26/Feb/09   Jonnatan peña   Emision Inicial                        */
/***********************************************************************/

use cob_cartera
go


if exists (select 1 from cob_cartera..sysobjects where name = 'sp_camb_nota' and xtype = 'P')
    drop proc sp_camb_nota
go


create proc sp_camb_nota (
   @t_debug              char(1)     = 'N',
   @t_file               varchar(14) = null,  
   @t_trn                smallint    = null,
   @t_from               varchar(30) = null,
   @i_operacion          char(1)     = null,   
   @i_cliente            int         = null,
   @i_nota               smallint    = null,
   @i_banco              varchar(24) = null
)
as
declare
   
   @w_return             int,          /* VALOR QUE RETORNA  */
   @w_sp_name            varchar(32),  /* NOMBRE STORED PROC */
   @w_existe             tinyint,      /* EXISTE EL REGISTRO */
   @w_msg                varchar(100),
   @w_error              int,
   @w_nota               smallint,
   @w_banco              varchar(24)
          
      
/* BUSCA LA NOTA */   
if @i_operacion = 'S' begin
   select 
   'Cod. Banco' = op_banco,
   'Operacion'   = op_toperacion,
   'Oficina'    = (select valor
				  from cobis..cl_catalogo c, cobis..cl_tabla t
				  where t.tabla = 'cl_oficina' 
				  and   t.codigo = c.tabla 
				  and   c.codigo = z.op_oficina),   
   'Ejecutivo'  = (select fu_nombre 
                  from  cobis..cc_oficial,
                  cobis..cl_funcionario                  
                  where z.op_cliente = @i_cliente                  
                  and   oc_oficial = z.op_oficial
                  and   oc_funcionario = fu_funcionario),
   'Monto Aprobado' = op_monto_aprobado,
   'Estado'     = op_estado,
   'Nota'       = ci_nota
   from cob_cartera..ca_operacion z,
        cob_credito..cr_califica_int_mod
   where ci_banco = op_banco
   and op_estado in (1,2,3)
   and op_cliente = @i_cliente
   union
   select 
   'Cod. Banco' = op_banco,
   'Operacion'   = op_toperacion,
   'Oficina'    = (select valor
				  from cobis..cl_catalogo c, cobis..cl_tabla t
				  where t.tabla = 'cl_oficina' 
				  and   t.codigo = c.tabla 
				  and   c.codigo = z.op_oficina),   
   'Ejecutivo'  = (select fu_nombre 
                  from  cobis..cc_oficial,
                  cobis..cl_funcionario                  
                  where z.op_cliente = @i_cliente                  
                  and   oc_oficial = z.op_oficial
                  and   oc_funcionario = fu_funcionario),
   'Monto Aprobado' = op_monto_aprobado,
   'Estado'     = op_estado,
   'Nota'       = ci_nota
   from cob_cartera_his..ca_operacion z,
        cob_credito_his..cr_califica_int_mod_his
   where ci_banco = op_banco
   and op_estado = 3
   and op_cliente = @i_cliente
     
             
end
       
/* UPDATE DE LA NOTA */
if @i_operacion = 'U' begin   
   update cob_credito..cr_califica_int_mod
   set ci_nota    = @i_nota
   where ci_banco = @i_banco
  
   if @@error <> 0  begin
      select
      @w_error = 2105001,
      @w_msg   = 'ERROR AL MODIFICAR LA NOTA DE LA OPERACION DEL CLIENTE'
      goto ERROR
   end         
   
   update cob_credito_his..cr_califica_int_mod_his
   set ci_nota = @i_nota
   where ci_banco = @i_banco
  
   if @@error <> 0  begin
      select
      @w_error = 2105001,
      @w_msg   = 'ERROR AL MODIFICAR LA NOTA DE LA OPERACION DEL CLIENTE'
      goto ERROR
   end         
end


/* QUERY DE LA NOTA */
if @i_operacion = 'Q' begin 
 
   select @w_nota = @i_nota,
   		  @w_banco = @i_banco
   		  
   select @w_nota,
          @w_banco 
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