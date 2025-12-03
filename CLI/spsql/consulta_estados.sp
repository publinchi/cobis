/* **********************************************************************/
/*      Archivo           : consulta_estados.sp                         */
/*      Stored procedure  : sp_consulta_estados                         */
/*      Base de datos     : cobis                                       */
/*      Producto:           Clientes                                    */
/*      Disenado por:       JMEG                                        */
/*      Fecha de escritura: 30-Abril-19                                 */
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
/*                           PROPOSITO                                  */
/*  Permite consultar los estados del catalogo                          */
/* **********************************************************************/
/*                        MODIFICACIONES                                */
/*      FECHA           AUTOR           RAZON                           */
/*  30/04/19         JMEG         Emision Inicial                       */
/*  23/06/20         FSAP         Estandarizacion de Clientes           */
/************************************************************************/
use cobis 
go
set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1
           from   sysobjects
           where  name = 'sp_consulta_estados')
           drop proc sp_consulta_estados
go
create proc sp_consulta_estados(
    @i_operacion      char(1)  = null,
    @t_show_version   bit      = 0,
    @t_debug          char(1)  = 'N',
	@t_file           varchar(10) = null,
	@t_trn            int      = 0	
)
as
declare @w_codigo  int,
        @w_sp_name varchar (30),
        @w_sp_msg  varchar(130)

select w_sp_name = 'sp_consulta_estados'


---- VERSIONAMIENTO DEL PROGRAMA -------------------------------------------
if @t_show_version = 1
begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end

--EVALUACION DEL TIPO DE TRANSACCION 
if (@t_trn <> 172102 and @i_operacion = 'S')     --search
begin 
   /* Tipo de transaccion no corresponde */ 
   exec cobis..sp_cerror 
        @t_debug = @t_debug, 
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1720275
   return 1
end
if @i_operacion = 'S'
begin
   select @w_codigo = 0
   select @w_codigo = codigo  
     from cl_tabla 
    where tabla= 'cl_provincia'
   
   select codigo,
          valor
     from cl_catalogo
    where tabla = @w_codigo
    order by valor
end
go
