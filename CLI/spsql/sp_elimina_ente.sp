/***********************************************************************/
/*    NOMBRE LOGICO: sp_elimina_ente                                   */
/*    NOMBRE FISICO: sp_elimina_ente.sp                                */
/*    PRODUCTO:      Clientes                                          */
/*    Disenado por:  O. Guaño                                          */
/*    Fecha de escritura: 10-Mar-23                                    */
/***********************************************************************/
/*                     IMPORTANTE                                      */
/*   Este programa es parte de los paquetes bancarios que son          */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,     */
/*   representantes exclusivos para comercializar los productos y      */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida    */
/*   y regida por las Leyes de la República de España y las            */
/*   correspondientes de la Unión Europea. Su copia, reproducción,     */
/*   alteración en cualquier sentido, ingeniería reversa,              */
/*   almacenamiento o cualquier uso no autorizado por cualquiera       */
/*   de los usuarios o personas que hayan accedido al presente         */
/*   sitio, queda expresamente prohibido; sin el debido                */
/*   consentimiento por escrito, de parte de los representantes de     */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto     */
/*   en el presente texto, causará violaciones relacionadas con la     */
/*   propiedad intelectual y la confidencialidad de la información     */
/*   tratada; y por lo tanto, derivará en acciones legales civiles     */
/*   y penales en contra del infractor según corresponda.”.            */
/***********************************************************************/
/*                           PROPOSITO                                 */
/*   Elimina de un propecto                                            */
/***********************************************************************/
/*                        MODIFICACIONES                               */
/*  FECHA              AUTOR              RAZON                        */
/*  10-Mar-2023      O. Guaño.  S763654 - Eliminarció de prospectos    */
/***********************************************************************/
use cobis
go

if exists (select 1 from sysobjects where name = 'sp_elimina_ente')
   drop proc sp_elimina_ente
go

CREATE PROCEDURE sp_elimina_ente (
    @s_ssn             int,
    @s_sesn            int           = null,
    @s_user            login         = null,
    @s_term            varchar(32)   = null,
    @s_date            datetime,
    @s_srv             varchar(30)   = null,
    @s_lsrv            varchar(30)   = null,
    @s_ofi             smallint      = null,
    @s_rol             smallint      = null,
    @s_org_err         char(1)       = null,
    @s_error           int           = null,
    @s_sev             tinyint       = null,
    @s_msg             descripcion   = null,
    @s_org             char(1)       = null,
    @s_culture         varchar(10)   = 'NEUTRAL',
    @t_debug           char(1)       = 'n',
    @t_file            varchar(10)   = null,
    @t_from            varchar(32)   = null,
    @t_trn             int           = null,
    @t_show_version    bit           = 0,     -- versionamiento
	@i_ente		       int 
 )
as
declare	
	@w_sp_name	        descripcion,
	@w_sp_msg           varchar(132)
	
       
select	@w_sp_name = 'sp_elimina_ente'
      
if @t_show_version = 1 begin
  select @w_sp_msg = concat('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = concat(@w_sp_msg , ' Version 1.0.0.0')
  print  @w_sp_msg
  return 0
end

if exists(select 1 from cobis..cl_ente_aux where ea_ente = @i_ente)
begin
   delete cobis..cl_ente_aux where ea_ente = @i_ente
end

if exists(select 1 from cobis..cl_ente where en_ente = @i_ente)
begin
   delete cobis..cl_ente where en_ente = @i_ente
end

return 0
go
