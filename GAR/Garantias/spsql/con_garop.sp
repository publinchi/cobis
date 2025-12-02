/*************************************************************************/
/*   Archivo:              con_garop.sp                                  */
/*   Stored procedure:     sp_con_garop                                  */
/*   Base de datos:        cob_custodia                                  */
/*   Producto:             Garantias                                     */
/*   Disenado por:         TEAM SENTINEL PRIME                           */
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
/*                             MODIFICACION                              */
/*    FECHA               AUTOR                     RAZON                */
/*    Marzo/2019          TEAM SENTINEL PRIME       emision inicial      */
/*                                                                       */
/*************************************************************************/

USE cob_custodia
GO

IF OBJECT_ID('dbo.sp_con_garop') IS NOT NULL
    DROP PROCEDURE dbo.sp_con_garop
go

create proc dbo.sp_con_garop      (
   @s_ssn                int      = null,
   @s_date               datetime = null,
   @s_user               login    = null,
   @s_term               descripcion = null,
   @s_corr               char(1)  = null,
   @s_ssn_corr           int      = null,
   @s_ofi                smallint  = null,
   @s_rol		 tinyint   = null,	--II CMI 02Dic2006
   @t_rty                char(1)  = null,
   @t_trn                smallint = null,
   @t_debug              char(1)  = 'N',
   @t_file               varchar(14) = null,
   @t_from               varchar(30) = null,
   @i_operacion          char(1)  = null,
   @i_modo               smallint = null,
   @i_producto		 tinyint = null,
   @i_operac             descripcion = null,
   @i_tipo_cust          descripcion = null,
   @i_custodia           int = null,
   @i_param1             descripcion = null,
   @i_cond1              descripcion = null,
   @i_cond2              descripcion = null,
   @i_param2             descripcion = null,
   @i_filial             tinyint     = null,
   @i_sucursal           smallint    = null,
   @i_oficina            smallint    = null,
   @i_numero_op_banco    varchar(20) = null,
   @i_numero_op          varchar(20) = null,
   @i_tipo_op1           varchar(10) = null,
   @i_tipo_op            varchar(10) = null
)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_error              int,
   @w_abreviatura        char(3),
   @w_param_busqueda	 varchar(24)		--II CMI 02Dic2006

select @w_today = convert(varchar(10),getdate(),101)
select @w_sp_name = 'sp_con_garop'

if @i_operacion = 'V'
begin
   select to_descripcion
   from cob_credito..cr_toperacion
   where to_toperacion = @i_tipo_op

   if @@rowcount = 0
   begin
      exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file, 
         @t_from  = @w_sp_name,
         @i_num   = 1901005
      return 1 
   end
end

if @i_operacion = 'A'
begin 
   set rowcount 20
   select "PRODUCTO"=to_producto,
          "TIPO OPERACION"=to_toperacion,
          "DESCRIPCION"=substring(to_descripcion,1,30) 
   from cob_credito..cr_toperacion
   where ((to_producto > @i_param1 or (to_producto = @i_param1 and
          to_toperacion > @i_param2)) or @i_param1 is null)
   order by to_producto,to_toperacion
end

if @i_operacion = 'O'
begin
   set rowcount 20
   select "PRODUCTO"=tr_toperacion,
          "OPERACION"=tr_numero_op_banco
   from cob_credito..cr_tramite
   where (tr_toperacion  = @i_tipo_op)
     and tr_numero_op_banco is not null
     and ((tr_toperacion > @i_tipo_op1 or (tr_toperacion = @i_tipo_op1 and 
           tr_numero_op_banco > @i_numero_op)) or @i_numero_op is null)  
   order by tr_toperacion,tr_numero_op_banco
   
   if @@rowcount = 0
    begin
        exec cobis..sp_cerror
               @t_debug = @t_debug,
               @t_file  = @t_file, 
               @t_from  = @w_sp_name,
               @i_num   = 1901003
          return 1901003
    end
   --if @@rowcount = 0
   --   return 1
end
 
if @i_operacion = 'S'
begin
    if @i_sucursal is null   
       select @i_sucursal = a_sucursal
       from cobis..cl_oficina
       where of_oficina = @i_oficina

    set rowcount 20
    select distinct 'GARANTIA' = cu_custodia,
          'TIPO' = substring(cu_tipo,1,15)+'   '+substring(tc_descripcion,1,20),
          'CLIENTE' = cg_ente,
          ' ' = substring(cg_nombre,1,25),
          'VALOR       ' = cu_valor_actual,
          'MON. ' = cu_moneda,
          'INGRESO' = convert(varchar(10),cu_fecha_ingreso,101)
    from cu_custodia,cu_cliente_garantia,cu_tipo_custodia,
         cob_credito..cr_gar_propuesta, cob_cartera..ca_operacion
    where op_tramite             = gp_tramite 
          and cu_codigo_externo      = gp_garantia
      and cu_codigo_externo      = cg_codigo_externo
      and cu_tipo                = tc_tipo
      and op_banco     = @i_numero_op
      and op_toperacion          = @i_tipo_op         
      and cu_filial              = @i_filial
      and cu_sucursal            = @i_sucursal
      and cg_principal           = 'S'
    order by 2,1,3
    
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

--Guarda log auditoria
--II CMI 02Dic2006
if @i_operacion in ('V', 'O')
   select @w_param_busqueda = @i_tipo_op
if @i_operacion = 'A'
   select @w_param_busqueda = @i_param2
if @i_operacion = 'S'
   select @w_param_busqueda = @i_numero_op

/*exec @w_return = cob_cartera..sp_trnlog_auditoria_activas
   @s_ssn 		= @s_ssn,                   
   @i_cod_alterno	= 0,
   @t_trn		= @t_trn,
   @i_producto	= '19',      
   @s_date		= @s_date,
   @s_user		= @s_user,
   @s_term		= @s_term,
   @s_rol		= @s_rol,
   @s_ofi		= @s_ofi,
   @i_tipo_trn	= @i_operacion,
   @i_num_banco	= @w_param_busqueda

if @w_return <> 0 
begin
   /* Error en actualizacion de registro */
   exec cobis..sp_cerror
   @t_debug = @t_debug,
   @t_file  = @t_file, 
   @t_from  = @w_sp_name,
   @i_num   = 1903003
   return 1 
end*/
go