/************************************************************************/
/*	Archivo:		    his_relacion.sp	                           	    */
/*	Stored procedure:	sp_his_relacion   			                    */
/*	Base de datos:		Cobis					                        */
/*	Producto:       	M.I.S.					                        */
/*	Disenado por:       Carlos Rodriguez V.			                    */  
/*	Fecha de escritura: 16-May-94				                        */
/************************************************************************/
/*				IMPORTANTE				                                */
/*	Este programa es parte de los paquetes bancarios propiedad de	    */
/*	"MACOSA", representantes  exclusivos  para el  Ecuador  de la 	    */
/*	"NCR CORPORATION".						                            */
/*	Su  uso no autorizado  queda expresamente  prohibido asi como	    */
/*	cualquier   alteracion  o  agregado  hecho por  alguno de sus       */
/*	usuarios   sin el debido  consentimiento  por  escrito  de la 	    */
/*	Presidencia Ejecutiva de MACOSA o su representante.		            */
/*				PROPOSITO				                                */
/************************************************************************/
/*	Este programa procesa las transacciones del store procedure	        */
/*	Busqueda de Historia de Relaciones     			                    */
/************************************************************************/
/*				MODIFICACIONES				                            */
/*	FECHA		AUTOR		RAZON				                        */
/*	                           	Emision Inicial			                */
/*  27-01-2021  GCO   	        Estandarizacion de clientes             */
/*  28-01-2021  ADB             Modificación de Tipos de Dato           */
/************************************************************************/

use cobis
GO
set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO    
if exists (select * from sysobjects where name = 'sp_his_relacion')
   drop proc sp_his_relacion
go
create proc sp_his_relacion ( 
       @s_ssn		     int = null, 
       @s_user		     login = null, 
       @s_term		     varchar(30) = null, 
       @s_date		     datetime = null, 
       @s_srv		     varchar(30) = null, 
       @s_lsrv		     varchar(30) = null, 
       @s_ofi		     smallint = null, 
       @s_culture        varchar(10)   = 'NEUTRAL',         
       @t_debug		     char(1) = 'N', 
       @t_file		     varchar(10) = null, 
       @t_from		     varchar(32) = null, 
       @t_trn		     int = null, 
       @t_show_version   bit           = 0,     -- mostrar la version del programa       
       @i_modo		     tinyint = null, 
       @i_ente_i	     int, 
       @i_relacion	     int = null, 
       @i_ente_d	     int = null 
) 
as 
declare @w_return       int, 
        @w_sp_name	    varchar(32),
        @w_sp_msg       varchar(132)
         
select  @w_sp_name = 'sp_his_relacion' 
/* VERSIONAMIENTO */
if @t_show_version = 1 begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end

---- EJECUTAR SP DE LA CULTURA ---------------------------------------  
exec cobis..sp_ad_establece_cultura
        @o_culture = @s_culture out

  
if @t_trn = 172156 
begin 
     set rowcount 20 
     if @i_modo = 0 
	select  "Relacion" =  hr_relacion, 
	        "Descripcion" =  substring(re_descripcion,1,25), 
	        "Ente" =  hr_ente_d, 
	        "Nombre" =  substring(rtrim(en_nombre)+' '+ 
					rtrim(p_p_apellido)+' '+rtrim(p_s_apellido),1,65), 
	        "Fecha Inicio" =  convert(char(10),hr_fecha_ini,103), 
            "Fecha Fin" =  convert(char(10),hr_fecha_fin,103) 
	from  cl_his_relacion,cl_relacion,cl_ente 
        where hr_relacion = re_relacion  
          and hr_ente_d = en_ente  
	  and hr_ente_i = @i_ente_i 
	order by hr_relacion 
     if @i_modo = 1 
	select  "Relacion" =  hr_relacion, 
	        "Descripcion" =  substring(re_descripcion,1,25), 
	        "Ente" =  hr_ente_d, 
	        "Nombre" =  substring(rtrim(en_nombre)+' '+ 
					rtrim(p_p_apellido)+' '+rtrim(p_s_apellido),1,65), 
	        "Fecha Inicio" =  convert(char(10),hr_fecha_ini,103), 
            "Fecha Fin" =  convert(char(10),hr_fecha_fin,103) 
	from  cl_his_relacion,cl_relacion,cl_ente 
        where hr_relacion = re_relacion  
          and hr_ente_d = en_ente  
	  and (hr_relacion > @i_relacion 
	      or (hr_relacion = @i_relacion and hr_ente_d > @i_ente_d)) 
	  and hr_ente_i = @i_ente_i 
	order by hr_relacion 
     set rowcount 0 
     return 0 
end 
else 
begin 
	exec sp_cerror 
	   @t_debug	  = @t_debug, 
	   @t_file	  = @t_file, 
	   @t_from	  = @w_sp_name,
	   @s_culture = @s_culture,	    
	   @i_num	  = 1720070 
	   /*  'No corresponde codigo de transaccion' */ 
	return 1 
end                                                                                                                                                                                                
go
