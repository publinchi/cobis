/**********************************************************************/
/*   Archivo:                 validacion_pep.sp                       */
/*   Stored procedure:        sp_validacion_pep                       */
/*   Base de datos:           cobis                                   */
/*   Producto:                CLIENTES                                */
/*   Disenado por:            DGA                                     */
/*   Fecha de escritura:      14-May-2020                             */
/**********************************************************************/
/*                           IMPORTANTE                               */
/*   Esta aplicacion es parte de los paquetes bancarios propiedad     */
/*   de COBIS S.A.                                                    */
/*   Su uso no  autorizado queda  expresamente prohibido asi como     */
/*   cualquier  alteracion  o agregado  hecho por  alguno  de sus     */
/*   usuarios sin el debido consentimiento por escrito de COBIS S.A   */
/*   Este programa esta protegido por la ley de derechos de autor     */
/*   y por las  convenciones  internacionales de  propiedad inte-     */
/*   lectual.  Su uso no  autorizado dara  derecho a  COBIS S.A para  */
/*   obtener  ordenes de  secuestro o retencion y  para perseguir     */
/*   penalmente a los autores de cualquier infraccion.                */
/**********************************************************************/
/*                           PROPOSITO                                */
/*   Este stored procedure procesa: consulta de cliente en tabla      */
/*   cl_listas_negras, para determinar si un cliente es PEP           */
/**********************************************************************/
/*               MODIFICACIONES                                       */
/*   FECHA          AUTOR             RAZON                           */
/*   14/May/2020    DGA               Emisión Inicial                 */
/*   17/Jun/2020    FSAP              Estandarizacion de Clientes     */
/*   11/Dic/2020    EGL               Se actualiza validacion nombre  */
/*   15/Dic/2020    MGB               Ajuste para traduccion		  */
/* 	 15/12/20       MGB       		  Cambio translate por funcion 	  */
/*									  cobis      					  */
/**********************************************************************/
use cobis
go
set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select * from sysobjects where name = 'sp_validacion_pep')
	drop proc sp_validacion_pep
go

create proc sp_validacion_pep(
	@s_ssn				int				= null,
	@s_user				login			= null,
	@s_term				varchar(32)		= null,
	@s_date				datetime		= null,
	@s_srv				varchar(30)		= null,
	@s_lsrv				varchar(30)		= null,
	@s_rol				smallint		= null,
	@s_ofi				smallint		= null,
	@s_org_err			char(1)			= null,
	@s_error			int				= null,
	@s_sev				tinyint			= null,
	@s_msg				descripcion		= null,
	@s_org				char(1)			= null,
	@t_trn				int				= 2244,
	@t_debug			char (1)		= 'N',
	@t_file				varchar(14)		= null,
	@t_from				varchar(30)		= null,
	@t_show_version		bit				= 0,
	@i_ente				int				= null,
	@i_operacion		char(1),        
	@o_es_pep			varchar(10)		= null out,
	@o_dependencia		varchar(200)	= null out,
	@o_puesto			varchar(200)	= null out
)
as
declare @w_sp_name            varchar(30),
        @w_sp_msg             varchar(130),
        @w_null               int,
        @w_curp               varchar(32),
        @w_rfc                varchar(20),
        @w_ente               int,
        @w_contador           int,
        @w_nombre             varchar(200),
        @w_p_nombre           varchar(64),
        @w_s_nombre           varchar(20),
        @w_p_apellido         varchar(16),
        @w_s_apellido         varchar(16),
        @w_fecha_nac          varchar(10),
        @w_puesto             varchar(200),
        @w_es_pep             varchar(10),
        @w_dependencia        varchar(100)

/*  captura nombre de stored procedure  */
select @w_sp_name           = 'sp_validacion_pep',
       @w_es_pep            = 'N',
       @w_puesto            = '' ,
       @w_dependencia       = ''

---- VERSIONAMIENTO DEL PROGRAMA -------------------------------------------
if @t_show_version = 1
begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end

if (@t_trn <> 172055 and @i_operacion = 'S')
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
	
  select
        @w_p_apellido  = upper(rtrim(ltrim( isnull(p_p_apellido,'') ))),
        @w_s_apellido  = upper(rtrim(ltrim( isnull(p_s_apellido,'') ))),
        @w_p_nombre    = upper(rtrim(ltrim( isnull(en_nombre,'')))),
		@w_s_nombre    = upper(rtrim(ltrim( isnull(p_s_nombre,''))))
  from cobis..cl_ente
   where en_ente       = @i_ente

  select
        @w_p_apellido   = cobis.dbo.fn_filtra_acentos(@w_p_apellido ),
        @w_s_apellido   = cobis.dbo.fn_filtra_acentos(@w_s_apellido ),
        @w_p_nombre     = cobis.dbo.fn_filtra_acentos(@w_p_nombre ),
		@w_s_nombre		= cobis.dbo.fn_filtra_acentos(@w_s_nombre )

  select @w_curp       = UPPER(en_ced_ruc),
         @w_rfc        = UPPER(en_rfc),
         @w_ente       = en_ente,
         @w_fecha_nac  = convert(varchar, p_fecha_nac, 112)
    from cobis..cl_ente
   where en_ente       = @i_ente
     
  --select @w_nombre = rtrim(@w_p_nombre + ' ' + @w_s_nombre) + ' ' +  rtrim(@w_p_apellido + ' ' + @w_s_apellido)
  select @w_nombre = CONCAT(RTRIM(@w_p_nombre), ' ')
  select @w_nombre = RTRIM(CONCAT(@w_nombre,@w_s_nombre))
  select @w_nombre = CONCAT(@w_nombre,' ')
  select @w_nombre = RTRIM(CONCAT(@w_nombre, RTRIM(@w_p_apellido)))
  select @w_nombre = CONCAT(@w_nombre, ' ')
  select @w_nombre = RTRIM(CONCAT(@w_nombre, RTRIM(@w_s_apellido)))
  
    
  --print 'nombre =' +  '*' + @w_nombre +'*' + convert(varchar, @i_ente) + 'curp: ' + @w_curp
  --select @w_nombre = CONCAT('nombre =*', @w_nombre)
  --select @w_nombre = CONCAT(@w_nombre, '*' )
  --select @w_nombre = CONCAT(@w_nombre, convert(varchar, @i_ente) )  
  --select @w_nombre = CONCAT(@w_nombre, 'curp: ' ) 
  --select @w_nombre = CONCAT(@w_nombre, @w_curp ) 
  
  
  -- coinciden rfc
  if exists (select 1
               from cobis..cl_listas_negras
              where upper(pe_rfc)    = @w_rfc
                and px_excluidos_id  = 3)
  and @w_rfc is not null
  and @w_rfc <> ''
    begin
      select @w_puesto        = upper(pe_puesto),
             @w_es_pep        = 'S',
             @w_dependencia   = upper(pe_dependencia)
        from cobis..cl_listas_negras
       where upper(pe_rfc)    = @w_rfc
         and px_excluidos_id  = 3
  
      goto FIN
    end
  
  -- coinciden curp
  if exists (select 1
               from cobis..cl_listas_negras
              where upper(rtrim(pe_curp)) = rtrim(@w_curp)
                and px_excluidos_id  = 3)
  and @w_curp is not null
  and @w_curp <> ''
    begin
      select @w_puesto       = upper(pe_puesto),
             @w_es_pep       = 'S',
             @w_dependencia  = upper(pe_dependencia)
        from cobis..cl_listas_negras
       where upper(pe_curp)  = @w_curp
         and px_excluidos_id = 3
  
      goto FIN
    end
  
  -- coinciden nombres --> entonces buscar por fecha
  select @w_contador       = count(1)
    from cobis..cl_listas_negras
   where pe_nomcomp = @w_nombre
     and px_excluidos_id   = 3
  
  --print 'contador '   + convert(varchar, @w_contador)
  
  if @w_contador > 1
    begin
      if exists (select 1
                   from cobis..cl_listas_negras
                  where pe_nomcomp   = @w_nombre
                    and pe_fecha_nacimiento = @w_fecha_nac
                    and px_excluidos_id     = 3)
      begin
        select @w_puesto           = upper(pe_puesto),
               @w_es_pep           = 'S',
               @w_dependencia      = upper(pe_dependencia)
          from cobis..cl_listas_negras
         where pe_nomcomp   = @w_nombre
           and pe_fecha_nacimiento = @w_fecha_nac
           and px_excluidos_id     = 3
  
        --print ' nombre y si fecha---' + @w_curp
        goto FIN
      end
    else
      begin
        --print ' nombre y no fecha---' + @w_curp
        select @w_puesto      = '',
               @w_es_pep      = 'N',
               @w_dependencia = ''
       goto FIN
      end
    end
  else
	begin
		if @w_contador = 1
		begin
			select @w_puesto         = upper(pe_puesto),
				@w_es_pep         = 'S',
				@w_dependencia    = upper(pe_dependencia)
			from cobis..cl_listas_negras
			where pe_nomcomp   = @w_nombre
			and px_excluidos_id   = 3
  
			--print ' solo nombre ---  ' + @w_nombre
			goto FIN
		end
	end
end
FIN:

select @o_puesto      = @w_puesto,
       @o_es_pep      = @w_es_pep,
       @o_dependencia = @w_dependencia

return 0
go