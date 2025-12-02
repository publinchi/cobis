
/************************************************************************/
/*  Archivo:                riesgos_asb.sp                              */
/*  Stored procedure:       sp_riesgos_asb                              */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Geovanny Guaman                             */
/*  Fecha de Documentacion: 23/Abr/2019                                 */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP S.A.representantes exclusivos para el Ecuador de la       */
/*  AT&T                                                                */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante               */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  SP GENERADO POR EXTRACCION DE LA BB.DD. cob_credito                 */ 
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  23/04/19          gguaman        Emision Inicial                    */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_riesgos_asb')
    drop proc sp_riesgos_asb
go

create proc sp_riesgos_asb (
   @s_ssn               int         = null,
   @s_user              login       = null,
   @s_sesn              int         = null,
   @s_term              descripcion = null, --MTA
   @s_date              datetime    = null,
   @s_srv               varchar(30) = null,
   @s_lsrv              varchar(30) = null,
   @s_rol               smallint    = NULL,
   @s_ofi               smallint    = NULL,
   @s_org_err           char(1)     = NULL,
   @s_error             int         = NULL,
   @s_sev               tinyint     = NULL,
   @s_msg               descripcion = NULL,
   @s_org               char(1)     = NULL,
   @t_show_version      bit         = 0, -- Mostrar la version del programa
   @t_rty               char(1)     = null,
   @t_trn               smallint    = null,
   @t_debug             char(1)     = 'N',
   @t_file              varchar(14) = null,
   @t_from              varchar(30) = null,
   @i_tramite           int         = 0,
   @i_operacion_i       int         = 0,
   @i_cliente           int         = null,
   @i_cliente_sig       int         = 0,
   @i_grupo             int         = null,
   @i_operacion_ban     cuenta      = ' ',
   @i_operacion         char(1)     = null,
   @i_cabecera          char(1)     = null,
   @i_modo              int         = null,
   @i_retorna           char(1)     = null,
   @i_usuario           login       = null,
   @i_secuencia         int         = null,
   @i_limite            char(1)     = null,  -- S si N no
   @i_aprobado          char(1)     = null,  -- S si N no
   @i_consulta          char(1)     = 'I',   -- I=Riesgo Individual   T=Total
   @i_en_tramite        char(1)     = 'N',   -- N no incuye tramites  S incluye tramites
   @i_modo_c            char(2)     = 'T',   -- Modo de Consulta 1=individual o 2=total
   @i_carga             char(2)     = 'T',   -- Modo de Consulta 1=individual o 2=total
   @i_categoria         char(2)     = null,
   @i_formato_fecha     int         = 101,
   @i_tramite_d         int         = null,
   @i_tipo_deuda        char(1)     = 'D',
   @i_bandera           char(1)     = 'S',
   @i_prendario         char(1)     = 'S',
   @i_impresion         char(1)     = 'S',  --Si se lo llama desde la impresion del MAC viene 'N'
   @i_desde_front       char(1)     = 'N',  --Si viene desde las pantallas de Credito, Forigin..etc
   @i_vista_360         char(1)     = 'S',  -- INDICA SI LA CONSULTA VIENE DESDE LA VISTA 360 PARA NO ENVIAR CABECERAS
   @i_act_can           char(1)     = 'N',   -- ECA: para determinar si se conuslta las operaciones canceladas
   @i_grupo_vinculado   char(1)     = 'N',
   @o_total_deuda       money       = null out
)
as

declare
   @w_sp_name       descripcion,
   @w_today         datetime,
   @w_return        int,
   @w_error         int

 --set STRING_RTRUNCATION off -- Sentencia agregada al migrar a Sybase 15. AAV

 select @w_today = getdate()
 select @w_sp_name = 'sp_riesgos_asb'

if @t_show_version = 1
begin
    print 'Stored procedure sp_riesgos_asb, Version 4.0.0.2'
    return 0
end

select @i_tramite = isnull(@i_tramite,0)

--print 'RIASB Usuario .. %1! Secuencia .. %2! Tramite %3!', @s_user, @s_sesn, @i_tramite
if (@t_trn <> 21084 and @i_operacion = 'I') or
   (@t_trn <> 21085 and @i_operacion = 'S') or
   (@t_trn <> 21086 and @i_operacion = 'C') or
   (@t_trn <> 21087 and @i_operacion = 'D')
begin
   exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file,
      @t_from  = @w_sp_name,
      @i_num   = 2101006
   return 1
end

if @i_operacion = 'I'
begin
   if @i_cliente = null and @i_grupo = null
   begin
       /* Campos NOT NULL con valores nulos */
      exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = 2101001
      return  1
   end

   exec  @w_return = sp_situacion_asb
@i_operacion     = @i_operacion,
      @i_carga         = @i_carga,
      @i_cliente       = @i_cliente,
      @i_grupo         = @i_grupo,
      @i_consulta      = @i_consulta,
      @i_limite        = @i_limite,
      @i_aprobado      = @i_aprobado,
      @s_ssn           = @s_ssn,
      @s_sesn          = @s_sesn,
      @s_user          = @s_user,
      @s_date          = @s_date,
      @i_formato_fecha = @i_formato_fecha,
      @i_tramite       = @i_tramite,
      @i_tipo_deuda    = @i_tipo_deuda,   --Vivi
      @i_bandera       = @i_bandera,
      @i_impresion     = @i_impresion,
      @i_desde_front   = @i_desde_front,
      @i_vista_360     = @i_vista_360,
      @i_act_can       = @i_act_can,
      @i_grupo_vinculado =  @i_grupo_vinculado

   if @w_return <> 0
      return @w_return
end

if @i_operacion = 'S'
begin
   exec @w_return        = sp_situacion_asb
      @s_sesn            = @s_sesn,
      @s_user            = @s_user,
      @i_operacion       = @i_operacion,
      @i_cliente         = @i_cliente,
      --SRO Envio de Grupo 06/03/2009
      @i_grupo           = @i_grupo,
      @i_cliente_sig     = @i_cliente_sig,
      @i_modo_c          = @i_modo_c,
      @i_modo            = @i_modo,
      @i_operacion_ban   = @i_operacion_ban,
      @i_tramite         = @i_tramite,
      @i_operacion_i     = @i_operacion_i,
      @i_cabecera        = @i_cabecera,
      @i_usuario         = @i_usuario,
      @i_secuencia       = @i_secuencia,
      @i_categoria       = @i_categoria,
      @s_date            = @s_date,
      @i_formato_fecha   = @i_formato_fecha,
      @i_tramite_d       = @i_tramite_d,
      @i_tipo_deuda      = @i_tipo_deuda,      --Vivi
      @i_impresion       = @i_impresion,
      @i_desde_front     = @i_desde_front,
      @i_vista_360       = @i_vista_360,
      @i_grupo_vinculado = @i_grupo_vinculado

   if @w_return <> 0
      return @w_return
end

if @i_operacion = 'C'
begin
   exec @w_return = sp_situacion_asb    -- Consulto Datos Consolidados
      @s_ssn              = @s_ssn,
      @s_sesn             = @s_sesn,
      @s_user             = @s_user,
      @s_date             = @s_date,
      @i_operacion        = 'C',
      @i_carga            = @i_carga,
      @i_cliente          = @i_cliente,
      @i_grupo            = @i_grupo,
      @i_consulta         = @i_consulta,
      @i_limite           = @i_limite,
      @i_tramite          = @i_tramite,
      @i_en_tramite       = @i_en_tramite,
      @i_aprobado         = @i_aprobado,
      @i_prendario        = @i_prendario,
      @i_categoria        = @i_categoria,
      @i_retorna          = 'S',
      @i_formato_fecha    = @i_formato_fecha,
      @i_tramite_d        = @i_tramite_d,
      @i_tipo_deuda       = @i_tipo_deuda,      --Vivi
      @i_impresion        = @i_impresion,
      @i_desde_front      = @i_desde_front,
      @i_vista_360        = @i_vista_360,
      @i_grupo_vinculado  = @i_grupo_vinculado,
      @o_total_deuda      = @o_total_deuda out

   if @w_return <> 0
      return @w_return

end

return 0

GO
