/**************************************************************************/
/*   NOMBRE LOGICO:      tellopdesem.sp                                   */
/*   NOMBRE FISICO:      sp_teller_op_por_desembolsar                     */
/*   BASE DE DATOS:      cob_cartera                                      */
/*   PRODUCTO:           Cartera                                          */
/*   DISENADO POR:       Guisela Fernandez                                */
/*   FECHA DE ESCRITURA: Mar. 2023                                        */
/**************************************************************************/
/*                     IMPORTANTE                                         */
/*   Este programa es parte de los paquetes bancarios que son             */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,        */
/*   representantes exclusivos para comercializar los productos y         */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida       */
/*   y regida por las Leyes de la República de España y las               */
/*   correspondientes de la Unión Europea. Su copia, reproducción,        */
/*   alteración en cualquier sentido, ingeniería reversa,                 */
/*   almacenamiento o cualquier uso no autorizado por cualquiera          */
/*   de los usuarios o personas que hayan accedido al presente            */
/*   sitio, queda expresamente prohibido; sin el debido                   */
/*   consentimiento por escrito, de parte de los representantes de        */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto        */
/*   en el presente texto, causará violaciones relacionadas con la        */
/*   propiedad intelectual y la confidencialidad de la información        */
/*   tratada; y por lo tanto, derivará en acciones legales civiles        */
/*   y penales en contra del infractor según corresponda.                 */
/**************************************************************************/
/*                     PROPOSITO                                          */
/*   Retorna datos de los prestamos que estan pendientes de desembolsar   */
/**************************************************************************/
/*                     MODIFICACIONES                                     */
/*   FECHA              AUTOR              RAZON                          */
/*   23-Mar-2023       G. Fernandez      Emision Inicial                  */
/*   06-Sep-2023       G. Fernandez      R214759 Se cambia condiciones de */
/*                                       consulta de operaciones          */
/**************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_teller_op_por_desembolsar')
    drop proc sp_teller_op_por_desembolsar
go

create proc sp_teller_op_por_desembolsar

   @s_user                  login       = null,
   @s_date                  datetime    = null,
   @s_ofi                   smallint    = null,
   @t_trn                   INT         = null, 
   @i_oficina               int         = null,
   @i_tipo_operacion        char(1),
   @i_siguiente             int         = 0  
as

declare @w_sp_name          descripcion,
        @w_error            int,
		@w_est_novigente    tinyint,
		@w_est_anulado      tinyint,
		@w_est_credito      tinyint,
		@w_est_cancelado    tinyint
		
select @w_sp_name = 'sp_teller_op_por_desembolsar'

exec @w_error = sp_estados_cca
@o_est_novigente       = @w_est_novigente out,
@o_est_anulado         = @w_est_anulado   out,
@o_est_credito         = @w_est_credito   out,
@o_est_cancelado       = @w_est_cancelado out

/*   Tabla temporal de información de prestamos pendientes de desembolso  */
if exists (select 1 from sysobjects where name = '#ca_op_por_desembolsar')
   drop table #ca_op_por_desembolsar

create table #ca_op_por_desembolsar(
   opd_secuencial           int          identity(1,1),
   opd_banco                cuenta       not null,
   opd_nom_cliente          descripcion  not null,
   opd_cod_cliente          int          not null,
   opd_monto_efectivo       money,
   opd_monto_cheque         money,
   opd_cod_oficina          int          not null,
   opd_oficina              varchar(160) not null
)

/*  Operaciones individuales  */
if @i_tipo_operacion = 'I'
begin
   insert into #ca_op_por_desembolsar (opd_banco,opd_nom_cliente,opd_cod_cliente,opd_monto_efectivo,opd_monto_cheque,opd_cod_oficina,opd_oficina)
   select op_banco, 
          op_nombre,
          op_cliente,
          dm_monto_mn,
          0,
          op_oficina,
          (select of_nombre from cobis..cl_oficina where of_oficina = op_oficina)
   from ca_operacion, ca_desembolso, ca_producto
   where op_operacion = dm_operacion
   and op_estado not in (@w_est_cancelado,@w_est_anulado,@w_est_credito)
   and dm_pagado    = 'N'
   and dm_producto  = cp_producto
   and cp_categoria = 'EFEC'
   and (op_oficina  = @i_oficina OR @i_oficina is null)
   and op_grupal    = 'N'
   
end

/*  Operaciones grupales hijas  */
if @i_tipo_operacion = 'H'
begin
   insert into #ca_op_por_desembolsar (opd_banco,opd_nom_cliente,opd_cod_cliente,opd_monto_efectivo,opd_monto_cheque,opd_cod_oficina,opd_oficina)
   select op_banco, 
          op_nombre,
          op_cliente,
          dm_monto_mn,
          0,
          op_oficina,
          (select of_nombre from cobis..cl_oficina where of_oficina = op_oficina)
   from ca_operacion, ca_desembolso, ca_producto
   where op_operacion = dm_operacion
   and op_estado not in (@w_est_novigente,@w_est_cancelado,@w_est_anulado,@w_est_credito)
   and dm_pagado    = 'N'
   and dm_producto  = cp_producto
   and cp_categoria = 'EFEC'
   and (op_oficina  = @i_oficina OR @i_oficina is null)
   and op_grupal    = 'S'
   and op_ref_grupal is not null
   
   if @@rowcount = 0
   begin
      /* No existe informacion para los criterios consultados*/
      select @w_error  = 725277
      goto ERROR
   end
   
end

/*  Todas las operaciones pendientes de desembolso  */
if @i_tipo_operacion = 'T'
begin

   insert into #ca_op_por_desembolsar (opd_banco,opd_nom_cliente,opd_cod_cliente,opd_monto_efectivo,opd_monto_cheque,opd_cod_oficina,opd_oficina)
   select op_banco, 
          op_nombre,
          op_cliente,
          dm_monto_mn,
          0,
          op_oficina,
          (select of_nombre from cobis..cl_oficina where of_oficina = op_oficina)
   from ca_operacion, ca_desembolso, ca_producto
   where op_operacion = dm_operacion
   and dm_pagado    = 'N'
   and dm_producto  = cp_producto
   and cp_categoria = 'EFEC'
   and (op_oficina  = @i_oficina OR @i_oficina is null)
   and ((op_grupal   = 'N' and op_estado not in (@w_est_cancelado,@w_est_anulado,@w_est_credito)) 
        OR (op_grupal = 'S' and op_ref_grupal is not null and op_estado not in (@w_est_novigente,@w_est_cancelado,@w_est_anulado,@w_est_credito)))
   
end

/*  Resultados */
set rowcount  20
select 'No.'             =  opd_secuencial,
       'Num. Operacion'  = opd_banco,
       'Nom. Cliente'    = opd_nom_cliente,
       'Cod. Cliente'    = opd_cod_cliente,
       'Monto Efec'      = opd_monto_efectivo,
       'Monto Cheq'      = opd_monto_cheque,
	   'Cod. Oficina'    = opd_cod_oficina,
	   'Oficina'         = opd_oficina
from #ca_op_por_desembolsar
where opd_secuencial > @i_siguiente
order by opd_secuencial

set rowcount 0  

select 'Total' = sum(opd_monto_efectivo) 
from #ca_op_por_desembolsar

return 0

ERROR:

   exec cobis..sp_cerror 
   @t_debug  = 'N',    
   @t_file   = null,  
   @t_from   = @w_sp_name,   
   @i_num    = @w_error
   
   return @w_error
go
