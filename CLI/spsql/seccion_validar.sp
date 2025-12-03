/************************************************************************/
/*  Archivo:                seccion_validar.sp                          */
/*  Stored procedure:       sp_seccion_validar                          */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Clientes                                    */
/*  Disenado por:           JMEG                                        */
/*  Fecha de escritura:     30-Abril-19                                 */
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
/*          PROPOSITO                                                   */
/* Permite actualizar un Prospecto a Cliente de forma autom�tica        */
/* siempre que este cumpla con el ingreso de cada modulo                */
/************************************************************************/
/*                        MODIFICACIONES                                */
/* FECHA           AUTOR           RAZON                                */
/* 30/04/19         JMEG         Emision Inicial                        */
/* 22/07/2019       JES          Estado de prospecto a cliente          */
/* 12/06/20         FSAP         Estandarizacion de Clientes            */
/* 15/10/20         MBA          Uso de la variable @s_culture          */
/************************************************************************/

use cobis
go

if exists(select 1 from sysobjects where name ='sp_seccion_validar')
    drop proc sp_seccion_validar
go
set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

create proc sp_seccion_validar (
   @s_ssn             int         = null,
   @s_user            login       = null,
   @s_term            varchar(32) = null,
   @s_date            datetime    = null,
   @s_sesn            int         = null,
   @s_srv             varchar(30) = null,
   @s_lsrv            varchar(30) = null,
   @s_ofi             smallint    = null,
   @s_rol             smallint    = NULL,
   @s_org_err         char(1)     = NULL,
   @s_error           int         = NULL,
   @s_sev             tinyint     = NULL,
   @s_msg             descripcion = NULL,
   @s_org             char(1)     = NULL,
   @s_culture         varchar(10) = 'NEUTRAL',
   @t_debug           char(1)     = 'N',
   @t_file            varchar(10) = null,
   @t_from            varchar(32) = null,
   @t_trn             int         = null,
   @t_show_version    bit         = 0,
   @i_operacion       char(1),
   @i_ente            int         = null,
   @i_seccion         catalogo    = null,
   @i_completado      char(1)     = null
)as
declare
   @w_ts_name         varchar(32),
   @w_num_error       int,
   @w_sp_name         varchar(32),
   @w_sp_msg          varchar(132),
   @w_seccion         catalogo,
   @w_completado      char(1),
   @w_actual          char(1),
   @w_ultima_seccion  char(1), --Permite saber si el que se va a insertar es el último valor
   @w_contar          int,      --Permite contar cuantos modulos faltan por completar
   @w_contar_ref      int,
   @w_relacion        char(1),
   @w_nro_catalogo    int,
   @w_nro_documentos  int,
   @w_documentos      char(1)

select @w_sp_name = 'sp_seccion_validar',
       @w_ultima_seccion = 'N'

if @t_show_version = 1
begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end

---- EJECUTAR SP DE LA CULTURA ---------------------------------------  
exec cobis..sp_ad_establece_cultura
        @o_culture = @s_culture out
		

if @i_operacion = 'V'
begin
  -- LLENA LA TABLA DE SECCIONES A VALIDADAS EN CASO DE QUE ALGUNA SECCION PARAMETRIZADA NO EXISTA
  insert into cobis..cl_seccion_validar(sv_ente, sv_seccion, sv_completado)
  select @i_ente, RTRIM(c.codigo), 'N'
    from cobis..cl_catalogo AS c
   inner join cobis..cl_tabla t on t.tabla = 'cl_modulo_cliente' and t.codigo  = c.tabla
    left join cobis..cl_seccion_validar s on s.sv_seccion = c.codigo and s.sv_ente = @i_ente
  where s.sv_seccion is null

  -- VALIDA SI TIENE QUE COMPLETAR LA SECCION ACTUAL
  if exists (select 1 from cobis..cl_seccion_validar
             where sv_ente       = @i_ente
             and   sv_seccion    = @i_seccion
             and   sv_completado = 'N')
  begin
      set @i_operacion = 'U'
  end

  -- CUANTAS SECCIONES FALTAN POR LLENAR
  select @w_contar = count(1) FROM cobis..cl_seccion_validar
  where  sv_ente = @i_ente
  and    sv_completado = 'N'

  -- SI SOLO FALTA UNA SECCION POR LLENAR
  if (@w_contar = 1)
  begin
      if exists( select 1 FROM cobis..cl_seccion_validar
                 where  sv_ente       = @i_ente
                 and    sv_completado = 'N'
                 and    sv_seccion    = @i_seccion )
      begin
          set @w_ultima_seccion = 'S'
      end
  end
  if (@w_contar = 0)
  begin
      set @i_operacion = 'F'
  end
  if ((@i_operacion = 'V') and (@w_ultima_seccion = 'N'))
  begin
      return 0
  end
end

if @i_operacion = 'U'
begin
    select @w_seccion         = sv_seccion,
           @w_completado      = sv_completado
      from cobis..cl_seccion_validar
     where sv_ente = @i_ente
    
    if @@rowcount = 0
    begin
      select @w_num_error =  1720096 --No existe el registro que desea actualizar
      goto errores
    end

    if @i_seccion is not null
      select @w_seccion = @i_seccion

    if @i_completado is not null
      select @w_completado = @i_completado

    begin tran
      --Actualizar completado de sección
      update cobis..cl_seccion_validar
      set   sv_completado = @w_completado
      where sv_ente       = @i_ente
      and   sv_seccion    = @i_seccion
      if @@error != 0
      begin
        select @w_num_error = 1720097 --Error al actualizar la seccion del cliente
        goto errores
      end
    commit tran

    if (@w_ultima_seccion = 'S')
    begin
        set @i_operacion = 'F'
    end
    else
    begin
        return 0
    end
end

if @i_operacion = 'F'
begin
  begin tran
    --Actualiza automaticamente el Estado
    update cobis..cl_ente_aux
    set   ea_estado = 'A'
    where ea_ente    = @i_ente

    if @@error <> 0
    begin
      select @w_num_error = 1720098 --Error al actualizar Prospecto a Cliente!
      goto errores
    end

    --Se actualiza el estado a cliente
    update cobis..cl_ente 
       set en_cliente = 'S' 
     where en_ente = @i_ente
    
    if @@error <> 0
    begin
      select @w_num_error = 1720098 --Error al actualizar Prospecto a Cliente!
      goto errores
    end
  commit tran
  return 0
end

--Control errores
errores:
   exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = @w_num_error,
	  @s_culture = @s_culture
   return @w_num_error
GO