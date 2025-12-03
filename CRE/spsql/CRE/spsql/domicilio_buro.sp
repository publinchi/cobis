/************************************************************************/
/*  Archivo:                domicilio_buro.sp                           */
/*  Stored procedure:       sp_domicilio_buro                           */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jonatan Rueda                               */
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
/*  23/04/19          LOGIN_DESA       Emision Inicial                  */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_domicilio_buro')
    drop proc sp_domicilio_buro
go

create proc sp_domicilio_buro(

   @s_ssn           int          = null,
   @s_user          login        = null,
   @s_sesn          int          = null,
   @s_term          descripcion  = null,
   @s_date          datetime     = null,
   @s_srv           varchar(30)  = null,
   @s_lsrv          varchar(30)  = null,
   @s_rol           smallint     = null,
   @s_ofi           smallint     = null,
   @s_org_err             char(1)      = null,
   @s_error               int          = null,
   @s_sev                 tinyint      = null,
   @s_msg                 descripcion  = null,
   @s_org                 char(1)      = null,
   @t_rty                 char(1)      = null,
   @t_trn                 smallint     = null,
   @t_debug               char(1)      = 'N',
   @t_file                varchar(14)  = null,
   @t_from                varchar(30)  = null,
   @i_operacion           char(1)      = null,  
   @i_cliente             int          = null,
   @i_direccion_uno       varchar(150) = null,
   @i_direccion_dos       varchar(150) = null,
   @i_colonia             varchar(150) = null,
   @i_delegacion          varchar(150) = null,
   @i_ciudad              varchar(150) = null,
   @i_estado              varchar(20)  = null,
   @i_codigo_postal       varchar(50)  = null,
   @i_num_telefono        varchar(50)  = null,
   @i_tipo_domicilio      varchar(10)  = null,
   @i_indicador_especial  varchar(10)  = null,
   @i_codigo_pais         varchar(10)  = null,
   @i_fecha_reporte       varchar(20)  = null
   )
   as
   declare @w_fecha          datetime,
           @w_error_number   int     ,
           @w_sp_name        varchar(100)
   
   select @w_sp_name = 'sp_domicilio_buro'
   
   select @w_fecha = fp_fecha
   from cobis..ba_fecha_proceso
      
   if @i_operacion='Q'
   begin
          select db_fecha, 
                 db_cliente, 
                 db_direccion_uno, 
                 db_direccion_dos, 
                 db_colonia, 
                 db_delegacion, 
                 db_estado, 
                 db_codigo_postal, 
                 db_numero_telefono, 
                 db_tipo_domicilio, 
                 db_indicador_especial, 
                 db_codigo_pais, 
                 db_fecha_reporte
          from cr_direccion_buro
          where db_cliente = @i_cliente
  
   end --@i_operacion
   
   if @i_operacion='I'
   begin
         insert into cr_direccion_buro (
                 db_fecha         , db_cliente           , db_direccion_uno  , 
                 db_direccion_dos , db_colonia           , db_delegacion     , 
                 db_estado        , db_codigo_postal     , db_numero_telefono, 
                 db_tipo_domicilio, db_indicador_especial, db_codigo_pais    , 
                 db_fecha_reporte , db_ciudad)
         values (@w_fecha         , @i_cliente           , @i_direccion_uno  , 
                 @i_direccion_dos , @i_colonia           , @i_delegacion     , 
                 @i_estado        , @i_codigo_postal     , @i_num_telefono   , 
                 @i_tipo_domicilio, @i_indicador_especial, @i_codigo_pais    , 
                 @i_fecha_reporte , @i_ciudad )
        if @@error <> 0 
	    begin
             set @w_error_number = 708152        
             goto ERROR
        end
   end  
   
   if @i_operacion='U'
   begin
        update cr_direccion_buro
        set db_direccion_uno      = @i_direccion_uno,
	        db_direccion_dos      = @i_direccion_dos,
	        db_colonia            = @i_colonia,
	        db_delegacion         = @i_delegacion,
	        db_estado             = @i_estado,
	        db_codigo_postal      = @i_codigo_postal,
	        db_numero_telefono    = @i_num_telefono,
	        db_tipo_domicilio     = @i_tipo_domicilio,
	        db_indicador_especial = @i_indicador_especial,
	        db_codigo_pais        = @i_codigo_pais,
	        db_fecha_reporte      = @i_fecha_reporte,
	        db_ciudad             = @i_ciudad
	    where db_cliente          = @i_cliente
	    
	    if @@error <> 0 
	    begin
             set @w_error_number = 708152        
             goto ERROR
        end        
   end  
   
   if @i_operacion = 'D' 
   begin
	     delete 
	     from cr_direccion_buro 
	     where db_cliente          = @i_cliente
   end
      
   return 0

   ERROR:
   EXEC cobis..sp_cerror
        @t_from  = @w_sp_name,
        @i_num   = @w_error_number

    
   RETURN 1

GO

