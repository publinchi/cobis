/************************************************************************/
/*   Archivo:            segmentacion_cli.sp                            */
/*   Stored procedure:   sp_segmentacion_cli                            */
/*   Base de datos:      cobis                                          */
/*   Producto:           CLIENTES                                       */
/*   Disenado por:       Bruno Duenas                                   */
/*   Fecha de escritura: 08-Mar-2023                                    */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido sin el debido                  */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada y por lo tanto, derivará en acciones legales civiles       */
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/
/*               PROPOSITO                                              */
/*   Este programa procesa las transacciones                            */
/*   DML de direcciones                                                 */
/*               MODIFICACIONES                                         */
/*   FECHA          AUTOR          RAZON                                */
/*   08/03/23       BDU         Versión Inicial                         */
/*************************************************************************/
use cobis
go
set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO

if exists (select 1 
             from sysobjects 
            where name = 'sp_segmentacion_cli')
   drop proc sp_segmentacion_cli 
go

create proc sp_segmentacion_cli (
   @s_ssn                int,
   @s_user               login        = null,
   @s_sesn               int          = null,
   @s_term               varchar(32)  = null,
   @s_date               datetime,
   @s_srv                varchar(30)  = null,
   @s_lsrv               varchar(30)  = null,
   @s_ofi                smallint     = NULL,
   @s_rol                smallint     = NULL,
   @s_org_err            char(1)      = NULL,
   @s_error              int          = NULL,
   @s_sev                tinyint      = NULL,
   @s_msg                descripcion  = NULL,
   @s_org                char(1)      = NULL,
   @s_culture            varchar(10)  = 'NEUTRAL',
   @t_debug              char(1)      = 'N',
   @t_file               varchar(10)  = null,
   @t_from               varchar(32)  = null,
   @t_trn                int          = null,
   @t_show_version       bit          = 0,    -- Mostrar la version del programa
   @i_operacion          char(1),             -- Opcion con la que se ejecuta el programa
   @i_ente               int          = null -- Codigo secuencial del cliente
)
as
declare
   @w_sp_name              varchar(32),   
   @w_sp_msg               varchar(132),
   @w_codigo               int,
   @w_error                int,
   @w_return               int


select @w_sp_name = 'sp_segmentacion_cli'
   
-------------- VERSIONAMIENTO DEL PROGRAMA -------------------------------------------
if @t_show_version = 1
begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 1.0.0')
  print  @w_sp_msg
  return 0
end
--------------------------------------------------------------------------------------

---- EJECUTAR SP DE LA CULTURA ---------------------------------------  
exec cobis..sp_ad_establece_cultura
        @o_culture = @s_culture out
------------LOGICA SP-----------------------------------

--Validacion trn 172227
if @t_trn <> 172227
begin 
   select @w_error = 1720121
   goto ERROR_FIN
end

if(@i_operacion = 'Q')
begin
   select ROW_NUMBER() over (order by sc_fecha desc) as [Index],
          'Fecha'    = FORMAT(sc_fecha,'dd/MM/yyyy hh:mm:ss'),
          'Segmento'    = sc_segmento + ' - ' + (select valor from cobis..cl_catalogo c, 
                                                 cobis..cl_tabla t 
                                                 where c.tabla = t.codigo 
                                                 and t.tabla = 'cr_segmento'
                                                 and c.estado = 'V'
                                                 and c.codigo = sc_segmento),
          'Subsegmento' = sc_subsegmento + ' - ' + (select valor from cobis..cl_catalogo c, 
                                                 cobis..cl_tabla t 
                                                 where c.tabla = t.codigo 
                                                 and t.tabla = 'cr_subsegmento'
                                                 and c.estado = 'V'
                                                 and c.codigo = sc_subsegmento),
          'Rango'       = sc_rango,
          'Puntaje'     = sc_puntaje 
   from cob_credito.dbo.cr_segmentacion_cliente with (NOLOCK)
   where sc_fecha > dateadd(month, -6, getdate())
   and sc_ente = @i_ente
   order by sc_fecha desc
end 
      
return 0

ERROR_FIN:
   exec cobis..sp_cerror
      @t_debug   = @t_debug,
      @t_file    = @t_file,
      @t_from    = @w_sp_name,             
      @i_num     = @w_error,
      @s_culture = @s_culture
   return @w_error

go

