/************************************************************************/
/*    Archivo:                 ca_matriz_doc.sp                        */
/*    Stored procedure:        sp_matriz_doc                           */
/*    Base de Datos:           cob_cartera                             */
/*    Producto:                Cartera                                 */
/************************************************************************/
/*                                  IMPORTANTE                          */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                            PROPOSITO                                 */
/*   Se encarga de devolver el archivo rpt fisico el cual se usara      */
/*   para visualizar el reporte segun valores del catalogo              */
/*   'cl_tipos_contratos_camp'                                          */
/*                                                                      */
/************************************************************************/
/*                            CAMBIOS                                   */
/************************************************************************/
/*     Fecha          User      Descripcion                             */
/*   30/jul/2012   Jose Cortes  Creacion (Req 0220 OTO)                 */
/************************************************************************/
 
use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_matriz_doc')
   drop proc sp_matriz_doc
go

create proc sp_matriz_doc
(  @s_ssn              int          = null,
   @s_sesn             int          = null,
   @s_srv              varchar (30) = null,
   @s_lsrv             varchar (30) = null,
   @s_user             login        = null,
   @s_date             datetime     = null,
   @s_ofi              int          = null,
   @s_rol              tinyint      = null,
   @s_org              char(1)      = null,
   @s_term             varchar (30) = null,
   @i_banco            varchar(24), 
   @i_tipo_doc         char(1)    ,              --Tipo de Documento a imprimir (C=Carta de Aprobación, P=Pagaré)
   @o_reporte          varchar(50)  out
   
)
as declare
   @w_return               int,
   @w_sp_name              varchar(32),
   @w_error                int,
   @w_tramite              int,
   @w_toperacion           catalogo,
   @w_cliente              int,
   @w_lin_credito          varchar(24),
   @w_campana              int,
   @w_tipo_tramite         char(1),
   @w_rotativo             char(1),
   @w_nombre_contrato      varchar(64),
   @w_valor                int,
   @w_msg                  varchar(64),
   @w_fecha_proceso        datetime,
   @w_alianza              int

   select @w_sp_name       = 'sp_matriz_doc'
   select @w_campana = 0
   /*DETERMINAR LA FECHA DE PROCESO*/
   select @w_fecha_proceso = fp_fecha from cobis..ba_fecha_proceso
   
   /*OBTIENE DATOS DE LA OPERACIÓN*/
   select 
   @w_tramite     = op_tramite,
   @w_toperacion  = op_toperacion,
   @w_cliente     = op_cliente,
   @w_lin_credito = op_lin_credito,
   @w_alianza     = tr_alianza
   from ca_operacion with (nolock),
        cob_credito..cr_tramite with (nolock)
   where op_banco   = @i_banco
   and   op_tramite = tr_tramite
   
   if @@rowcount = 0 
   begin
      select @w_error = 701049 --No Existe Operacion
      goto ERROR
   end
   
   /*OBTIENE LA CAMPAÑA SEG+N EL CLIENTE*/
   select @w_campana = cc_campana
   from cob_credito..cr_cliente_campana with (nolock)
   where cc_cliente = @w_cliente
      
   
   /* VALIDA TIPO DE OPERACION HABILITADO */
   
   if exists(select 1
             from cob_credito..cr_campana with (nolock), cob_credito..cr_campana_toperacion with (nolock)
             where ca_codigo     = ct_campana
             and   ct_toperacion = @w_toperacion
             and   ca_codigo     = @w_campana
             and   ca_estado     = 'V' )
      and @w_alianza is null

   begin
    /*INVOCA LA MATRIZ PARA LA RESPECTIVA CONSULTA DE REPORTE A UTILIZAR*/
    
    exec @w_error = sp_matriz_valor
	@i_matriz         = 'GEN_CNTRAC',
	@i_fecha_vig      = @w_fecha_proceso,
	@i_eje1           = @w_campana,
	@i_eje2           = 'X',
    @i_eje3           = 'X',
	@i_eje4           = @i_tipo_doc ,
	@o_valor          = @w_valor out,
	@o_msg            = @w_msg out
	if @w_error <> 0 goto ERROR
	
   end
   else
   begin
     select @w_campana = 0
     
   	 select @w_tipo_tramite = tr_tipo 	
     from cob_credito..cr_tramite with (nolock)
     where tr_tramite = @w_tramite
     
     if @@rowcount = 0 
	 begin
	 	select @w_error = 701187 --No Existe Tramite
	    goto ERROR
	 end
       
     --select @w_rotativo = case 
     --                       when @w_lin_credito is not null then 'S'
     --                       else 'N'
     --                       end
	 
     if @w_lin_credito is not null
        select @w_rotativo = 'S'
     else
        select @w_rotativo = 'N'
	 
       
     exec @w_error  = cob_cartera..sp_matriz_valor
     @i_matriz      = 'GEN_CNTRAC',
     @i_fecha_vig   = @w_fecha_proceso,  
     @i_eje1        = @w_campana,
     @i_eje2        = @w_tipo_tramite,
     @i_eje3        = @w_rotativo,
     @i_eje4        = @i_tipo_doc ,
     @o_valor       = @w_valor out, 
     @o_msg         = @w_msg   out 
      
     if @w_error <> 0 goto ERROR
     
   end
   
   select @w_nombre_contrato= y.valor 
   from cobis..cl_tabla x, cobis..cl_catalogo y
   where x.codigo = y.tabla
   and y.codigo = @w_valor
   and x.tabla = 'cl_tipos_contratos_camp'
   and y.estado = 'V'
	
   if @w_nombre_contrato is null
   begin
   	select @w_error = 721908
    goto ERROR
   end
	
   select @o_reporte = @w_nombre_contrato
   
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
   