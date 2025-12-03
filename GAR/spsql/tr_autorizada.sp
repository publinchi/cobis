/****************************************************************/
/* ARCHIVO:              tr_autorizada.sp                       */
/* Stored procedure:	 sp_tr_autorizada	          	        */
/* BASE DE DATOS:        cob_custodia 					        */
/* PRODUCTO:             GARANTIAS              	            */
/****************************************************************/
/*                         IMPORTANTE                           */
/* Esta aplicacion es parte de los paquetes bancarios propiedad */
/* de MACOSA S.A.						                        */
/* Su uso no  autorizado queda  expresamente prohibido asi como */
/* cualquier  alteracion  o agregado  hecho por  alguno  de sus */
/* usuarios sin el debido consentimiento por escrito de MACOSA. */
/* Este programa esta protegido por la ley de derechos de autor */
/* y por las  convenciones  internacionales de  propiedad inte- */
/* lectual.  Su uso no  autorizado dara  derecho a  MACOSA para */
/* obtener  ordenes de  secuestro o retencion y  para perseguir */
/* penalmente a los autores de cualquier infraccion.            */
/****************************************************************/
/*                      MODIFICACIONES                          */
/* FECHA               AUTOR                         RAZON      */
/* 29/Mar/2019       Luis  Ramirez  	        Emision Inicial */
/****************************************************************/

USE cob_custodia
go

IF OBJECT_ID('dbo.sp_tr_autorizada') IS NOT NULL
    DROP PROCEDURE dbo.sp_tr_autorizada
go
create proc dbo.sp_tr_autorizada
as

/* Transacciones Autorizadas */
declare cursor_trn cursor
	for select tn_trn_code
	    from cobis..cl_ttransaccion
	    where tn_trn_code between 19000 and 19999

declare @w_rol  smallint

select @w_rol = ro_rol
from cobis..ad_rol
where ro_descripcion = 'ADMINISTRADOR GARANTIA' and
      ro_filial = 1


declare @w_trn smallint

open cursor_trn
fetch cursor_trn into @w_trn
while (@@FETCH_STATUS = 0)  
begin
	insert into cobis..ad_tr_autorizada values (19,'R',0,@w_trn,@w_rol,getdate(),1,'V',getdate())
	fetch cursor_trn into @w_trn
end
close cursor_trn
deallocate cursor_trn
go