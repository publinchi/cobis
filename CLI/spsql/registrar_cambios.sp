/*************************************************************************/
/*   ARCHIVO:            registrar_cambios.sp                            */
/*   NOMBRE LOGICO:      sp_registrar_cambios                            */
/*   Base de datos:      cob_conta_super                                 */
/*   PRODUCTO:           REC                                             */
/*   Fecha de escritura: May 2020                                        */
/*************************************************************************/
/*                           IMPORTANTE                                  */
/*   Este programa es parte de los paquetes bancarios propiedad de       */
/*   'COBIS'.                                                            */
/*   Su uso no autorizado queda expresamente prohibido asi como          */
/*   cualquier alteracion o agregado hecho por alguno de sus             */
/*   usuarios sin el debido consentimiento por escrito de la             */
/*   Presidencia Ejecutiva de COBIS o su representante legal.            */
/*************************************************************************/
/*                           PROPOSITO                                   */
/*  Valida la existenda de un dato en el catalogo.                       */
/*************************************************************************/
/*                      MODIFICACIONES                                   */
/*  07/07/2020       FSAP                   Estandarizacion de Clientes  */
/*  15/10/20         MBA                    Uso de la variable @s_culture*/
/*************************************************************************/

use cobis
go

set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go
if exists ( select 1 from sysobjects where name = 'sp_registrar_cambios' )
   drop proc sp_registrar_cambios
go

create procedure sp_registrar_cambios(
  @s_user               login        = 'null',
  @s_term               varchar(32)  = 'null',
  @s_culture            varchar(10)  = 'NEUTRAL',
  @t_show_version       bit          = 0,
  @i_tipo_trn           char(1),  --I/U/D  Insert Update  Delete
  @i_operacion          char(1),  --A/D/C  Antes  Despues Comparar
  @i_tabla              varchar(100),
  @i_llave1             varchar(100),
  @i_campo1             varchar(30),
  @i_llave2             varchar(100) = '0',
  @i_campo2             varchar(30)  = '0',
  @i_llave3             varchar(100) = '0',
  @i_campo3             varchar(30)  = '0'
)

as

declare
  @w_sp_name             varchar(32),
  @w_sp_msg              varchar(132),
  @w_tabla_id   int,
  @w_comando    varchar(1000),
  @w_cmd        varchar(1000),
  @w_campo      varchar(100),
  @w_campo_2    varchar(100),
  @w_campo_3    varchar(100),
  @w_ente       varchar(30),
  @w_fecha_proc datetime



select @w_sp_name = 'sp_registrar_cambios'

---- VERSIONAMIENTO DEL PROGRAMA -------------------------------------------
if @t_show_version = 1 begin
   select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
   select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
   print  @w_sp_msg
   return 0
end

---- EJECUTAR SP DE LA CULTURA ---------------------------------------  
exec cobis..sp_ad_establece_cultura
        @o_culture = @s_culture out


if @i_operacion in ('A','D') begin

   if @i_operacion = 'A' delete cl_registro_cambio where ente = @i_campo1 and tabla = @i_tabla

   select @w_comando = sc_script
     from cl_scripts
    where sc_operacion = 'INSERT'
      and sc_tipo      = 'RC'

   select @w_campo = ''
   
   while 1=1 begin
   
      select top 1 @w_campo = COLUMN_NAME
        from INFORMATION_SCHEMA.COLUMNS
       where TABLE_NAME  = @i_tabla
         and COLUMN_NAME > @w_campo
       order
          by COLUMN_NAME
      
      if @@rowcount = 0 break
      
      
      select @w_cmd = @w_comando
      select @w_cmd = replace(@w_cmd,'@i_operacion',@i_operacion)
      select @w_cmd = replace(@w_cmd,'@i_tabla',    @i_tabla)
      select @w_cmd = replace(@w_cmd,'@w_campo',    @w_campo)
      select @w_cmd = replace(@w_cmd,'@i_llave1',   @i_llave1)
      select @w_cmd = replace(@w_cmd,'@i_campo1',   @i_campo1)
      select @w_cmd = replace(@w_cmd,'@i_llave2',   @i_llave2)
      select @w_cmd = replace(@w_cmd,'@i_campo2',   @i_campo2)
      select @w_cmd = replace(@w_cmd,'@i_llave3',   @i_llave3)
      select @w_cmd = replace(@w_cmd,'@i_campo3',   @i_campo3)
      select @w_cmd = replace(@w_cmd,'*','''')
      
      exec (@w_cmd)
      
   end
end

if @i_operacion in ('C') begin

   select @w_fecha_proc = fp_fecha from cobis..ba_fecha_proceso
   
   select @w_campo_2 = convert(int,@i_campo2)
   select @w_campo_3 = convert(int,@i_campo3)
      
   if @i_tipo_trn = 'I' begin

      insert into cobis..cl_actualiza(
      ac_ente               , ac_fecha               , ac_tabla      ,
      ac_campo              , ac_valor_ant           , ac_valor_nue  ,
      ac_transaccion        , ac_secuencial1         , ac_secuencial2,
      ac_hora               , ac_user                , ac_term)
      select
      convert(int,@i_campo1), @w_fecha_proc          , @i_tabla,
      d.campo               , ''                     , d.valor,
      'I'                   , @w_campo_2             , @w_campo_3,
      getdate()             , @s_user                , @s_term
      from cl_registro_cambio d
	  where d.tabla   =  @i_tabla
	  and   d.ente    =  @i_campo1
      and   d.sec1    =  @i_campo2
      and   d.sec2    =  @i_campo3
	  and   d.tipo    =  'D'
	  and   d.valor   <> ''
      
   end
   
   if @i_tipo_trn = 'U' begin

      insert into cobis..cl_actualiza(
      ac_ente               , ac_fecha               , ac_tabla      ,
      ac_campo              , ac_valor_ant           , ac_valor_nue  ,
      ac_transaccion        , ac_secuencial1         , ac_secuencial2,
      ac_hora               , ac_user                , ac_term)
      select
      convert(int,@i_campo1), @w_fecha_proc          , @i_tabla,
      a.campo               , a.valor                , d.valor,
      'U'                   , @w_campo_2             , @w_campo_3,
      getdate()             , @s_user                , @s_term
      from cl_registro_cambio a, cl_registro_cambio d
      where a.tabla   =  @i_tabla
      and   a.ente    =  @i_campo1
      and   a.sec1    =  @i_campo2
      and   a.sec2    =  @i_campo3
      and   a.tipo    =  'A'
      and   a.tabla   =  d.tabla
      and   a.campo   =  d.campo
      and   a.ente    =  d.ente
      and   a.sec1    =  d.sec1
      and   a.sec2    =  d.sec2
      and   d.tipo    =  'D'
      and   a.valor   <> d.valor
   end
   
   
   if @i_tipo_trn = 'D' begin

      insert into cobis..cl_actualiza(
      ac_ente               , ac_fecha               , ac_tabla      ,
      ac_campo              , ac_valor_ant           , ac_valor_nue  ,
      ac_transaccion        , ac_secuencial1         , ac_secuencial2,
      ac_hora               , ac_user                , ac_term)
      select
      convert(int,@i_campo1), @w_fecha_proc          , @i_tabla,
      a.campo               , a.valor                , '',
      'D'                   , @w_campo_2             , @w_campo_3,
      getdate()             , @s_user                , @s_term
      from cl_registro_cambio a
      where a.tabla   =  @i_tabla
      and   a.ente    =  @i_campo1
      and   a.sec1    =  @i_campo2
      and   a.sec2    =  @i_campo3
      and   a.tipo    =  'A'
      and   a.valor   <> ''
      
   end
   
   
end

return 0
   
go