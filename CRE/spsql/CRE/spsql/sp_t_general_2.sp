/************************************************************************/
/*  Archivo:                sp_t_general_2.sp                           */
/*  Stored procedure:       sp_t_general_2                              */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               COBIS                           			*/
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
/*  Proceso para la construccion de lineas de credito                   */
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  04/05/21		  PQU		 	Integracion  ingreso solicitud      */
/*									credito	GFI                         */
/* **********************************************************************/

USE cob_credito
GO

IF OBJECT_ID ('dbo.sp_t_general_2') IS NOT NULL
	DROP PROCEDURE dbo.sp_t_general_2
GO

create proc sp_t_general_2(
   @s_ssn               int      = null,
   @s_user              login    = null,
   @s_sesn              int    = null,
   @s_term              descripcion = null,
   @s_date              datetime = null,
   @s_srv		varchar(30) = null,
   @s_lsrv	  	varchar(30) = null,
   @s_rol		smallint = null,
   @s_ofi               smallint  = null,
   @s_org_err		char(1) = null,
   @s_error		tinyint = null,
   @s_sev		tinyint = null,
   @s_msg		descripcion = null,
   @s_org		char(1) = null,
   @t_rty               char(1)  = null,
   @t_trn               smallint = null,
   @t_debug             char(1)  = 'N',
   @t_file              varchar(14) = null,
   @t_from              varchar(30) = null,
   @i_cliente		int = null,
   @i_tramite	 int = null,
   @i_grupo             int = null,
   @i_aprobado          char(1)  = null,
   @i_modo              int = null,
   @i_modo1             tinyint = 0,
   @i_etapa             tinyint = null,
   @i_tipo              char(1)  = null,  
   @i_codigo           	catalogo  = null, 
   @i_descripcion     	varchar(255)  = null,
   @i_garantia        	varchar(64)  = null,
   @i_fecha_tope	datetime = null,
   @i_operacion       	char(1)  = null,
   @i_numero           	tinyint  = null,
   @i_toperacion        catalogo = null,
   @i_area              catalogo = null,
   @i_requisito         catalogo = null,
   @i_sector            catalogo = null,                                 
   @o_retorno1          tinyint = null out 
)
as
declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_cliente 		 int,
   @w_tramite            int,
   @w_grupo              int,
   @w_ins		 tinyint,
   @w_return1           int
   
select @w_today = @s_date
select @w_sp_name = 'sp_t_general_2'
select @w_ins = 0
select @w_today = isnull(@w_today, getdate())
if @s_user is null
   select @s_user   =us_login from cobis..ad_usuario
if @s_date is null
   select @s_date   =fp_fecha from cobis..ba_fecha_proceso 
/* Debug */
/*********/
if @t_debug = 'S'
begin
    exec cobis..sp_begin_debug @t_file = @t_file
        select '/** Stored Procedure **/ ' = @w_sp_name,
                s_ssn                      = @s_ssn,       
                s_user                     = @s_user,
                s_term                     = @s_term,
                s_date                     = @s_date,
                s_srv                      = @s_srv,
                s_lsrv                     = @s_lsrv,
                s_ofi                      = @s_ofi,
		t_trn			   = @t_trn,
		t_file			   = @t_file,
		t_from			   = @t_from,
		i_cliente		   = @i_cliente,
		i_tramite		   = @i_tramite,
   		i_grupo                    = @i_grupo,
                i_aprobado		   = @i_aprobado,
                i_modo                     = @i_modo,
		i_modo1                    = @i_modo1,
                i_etapa                    = @i_etapa,
                i_tipo                     = @i_tipo, 
                i_codigo                   = @i_codigo, 
                i_descripcion              = @i_descripcion,
                i_garantia                 = @i_garantia,      
                i_fecha_tope	           = @i_fecha_tope,	
                i_operacion                = @i_operacion,      
                i_numero                   = @i_numero,  
                -- Se agrega el Sector JCL CRET-004 10/Jun/98
                i_sector                   = @i_sector,
                o_retorno1  	           = @o_retorno1  	
    exec cobis..sp_end_debug
end
/***********************************************************/
/* Codigos de Transacciones                                */
if (@t_trn <> 21795) 
begin
/* tipo de transaccion no corresponde */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file, 
    @t_from  = @w_sp_name,
    @i_num   = 2101006
    return 1 
end
 select  @w_cliente=@i_cliente,
         @w_tramite=@i_tramite,
         @w_grupo=@i_grupo
	
/* RIESGOS INDIVIDUALES Y DE GRUPO*/
if  
@i_modo = 1 
begin
   --obtengo el grupo de cliente
   if @w_grupo is null
  	select @w_grupo = en_grupo
	from   cobis..cl_ente
	where  en_ente = @i_cliente
   
   exec @w_return = sp_riesgo_i
       @t_trn=21815,
       @i_cliente=@w_cliente,
       @i_tramite=@w_tramite,
       @i_aprobado = 'N'
  
   if @w_return <> 0
	return @w_return
   /*PQU integracion
   if @w_grupo is not null 
   begin
       exec @w_return = sp_riesgo_g
	   @t_trn=21833,
	   @i_cliente=@w_cliente,
	   @i_grupo=@w_grupo,
	   @i_tramite=@w_tramite,  
 	   @i_aprobado = 'N'
       
       if @w_return <> 0
	   return @w_return
   end        */ --fin PQU
        
end
/*GARANTIAS INDIVIDUALES Y DE GRUPO*/
if @i_modo = 2 
   return 0

/* REQUISITOS APROBADOS Y NO APROBADOS DEL TRAMITE*/
/*PQU integracion
if @i_modo=3 
begin
   if @i_modo1 = 0   
   begin
	exec @w_return = sp_req_tramite
	@t_trn=21451,
	@i_operacion="S",
	@i_tramite=@w_tramite,
	@i_tipo=@i_tipo,
	@i_etapa=@i_etapa,
	@i_modo=0,
        @i_sector=@i_sector,                                             
        @i_toperacion = @i_toperacion,
        @i_requisito  = @i_requisito
   end
   
   if @i_modo1 = 1
   begin
	exec @w_return = sp_req_tramite
	@t_trn=21451,
	@i_operacion="S",
	@i_tramite=@w_tramite,
	@i_tipo=@i_tipo,
        @i_con_etapa = "S",
	@i_etapa=@i_etapa,
	@i_modo = 1,        
@i_sector=@i_sector,
        @i_toperacion = @i_toperacion,
        @i_requisito  = @i_requisito
	if @w_return <> 0
		return @w_return
   end
end
*/ --fin PQU
/* INGRESO, MODIFICACION DE EXCEPCIONES Y VERIFICACION DE RUTEO*/
/*PQU integracion
if @i_modo=4
begin
begin tran
 
     if @i_operacion='I'
     begin  
         exec @w_return = sp_excepciones
           @s_ssn= @s_ssn,
           @s_user=@s_user,
           @s_sesn=@s_sesn,
           @s_term=@s_term,
           @s_date=@s_date,
           @s_srv=@s_srv,
           @s_lsrv=@s_lsrv,
           @s_rol=@s_rol,
           @s_ofi= @s_ofi,
           @s_org_err=@s_org_err,
           @s_error= @s_error,	
           @s_sev=@s_sev,
           @s_msg=@s_msg,
           @s_org=@s_org,
           @t_rty=@t_rty,
           @t_debug= @t_debug,
           @t_file=@t_file,
           @t_from=@t_from, 
	       @t_trn=21015,
           @i_operacion="I",
           @i_tramite=@w_tramite,
           @i_codigo=@i_codigo,
           @i_texto=@i_descripcion,
           @i_garantia=@i_garantia,         
   @i_fecha_tope=@i_fecha_tope,
           @i_today = @w_today,
           @i_login_reg = @s_user
           
     end
     else
     begin    
         exec @w_return = sp_excepciones
           @s_ssn= @s_ssn,
           @s_user=@s_user,
           @s_sesn=@s_sesn,
           @s_term=@s_term,
           @s_date=@s_date,
           @s_srv=@s_srv,
           @s_lsrv=@s_lsrv,
           @s_rol=@s_rol,
           @s_ofi= @s_ofi,
           @s_org_err=@s_org_err,
           @s_error= @s_error,	
           @s_sev=@s_sev,
           @s_msg=@s_msg,
           @s_org=@s_org,
           @t_rty=@t_rty,
           @t_debug= @t_debug,
           @t_file=@t_file,
           @t_from=@t_from, 
	   @t_trn=21115,
           @i_operacion="U",
           @i_numero=@i_numero,
           @i_tramite=@w_tramite,
           @i_codigo=@i_codigo,
           @i_texto=@i_descripcion,
           @i_garantia=@i_garantia,
           @i_fecha_tope=@i_fecha_tope,
           @i_today = @w_today,
           @i_login_reg = @s_user
      end
         
--VERIFICAR LA SECUENCIA DE APROBACION
   
    select @o_retorno1 = 0
commit tran
 
   if @w_return > 0 or @w_return1 > 0
          return 1
   else 
          return 0
END
*/ --PQU integracion 
/* INGRESO, MODIFICACION DE INSTRUCCIONES Y VERIFICACION DE RUTEO*/
/*PQU integracion
if @i_modo = 5
begin
begin tran
 
     if @i_operacion='I' 

     begin  
         exec @w_return=sp_instrucciones
           @s_ssn= @s_ssn,
           @s_user=@s_user,
           @s_sesn=@s_sesn,
           @s_term=@s_term,
           @s_date=@s_date,
           @s_srv=@s_srv,
           @s_lsrv=@s_lsrv,       
     @s_rol=@s_rol,
           @s_ofi= @s_ofi,
           @s_org_err=@s_org_err,
           @s_error= @s_error,	
           @s_sev=@s_sev,
           @s_msg=@s_msg,
           @s_org=@s_org,
           @t_rty=@t_rty,
           @t_debug= @t_debug,        
    @t_file=@t_file,
           @t_from=@t_from, 
           @t_trn=21014,
           @i_operacion= "I",
	   @i_tramite=@w_tramite,
	   @i_codigo=@i_codigo,
  	   @i_texto=@i_descripcion,
	   @i_garantia = @i_garantia,
-- Se agrega el Tipo no lo trae ERROR de MACOSA
           @i_tipo = @i_tipo,
           @i_area = @i_area
           
     end
     else
     begin    
         exec @w_return = sp_instrucciones
           @s_ssn= @s_ssn,
           @s_user=@s_user,
           @s_sesn=@s_sesn,
           @s_term=@s_term,
           @s_date=@s_date,
           @s_srv=@s_srv,
           @s_lsrv=@s_lsrv,
           @s_rol=@s_rol,
           @s_ofi= @s_ofi,
           @s_org_err=@s_org_err,
           @s_error= @s_error,	
           @s_sev=@s_sev,
           @s_msg=@s_msg,
           @s_org=@s_org,
           @t_rty=@t_rty,
           @t_debug= @t_debug,
           @t_file=@t_file,
           @t_from=@t_from, 
	   @t_trn=21114,
 	   @i_operacion="U",
	   @i_numero=@i_numero,
	   @i_tramite=@w_tramite,
	   @i_codigo=@i_codigo,
	   @i_texto=@i_descripcion,
           @i_area = @i_area
      end
         
--VERIFICAR LA SECUENCIA DE APROBACION
         
      select @o_retorno1 = 0
commit tran
     if @w_return > 0 or @w_return1 > 0
          return 1
   else 
          return 0
end
                        
*/ --fin PQU
go