/************************************************************************/
/*   Archivo:          gensec.sp                                        */
/*   Stored procedure: sp_gen_sec                                       */
/*   Base de datos:    cob_cartera                                      */
/*   Producto:         Cartera                                          */
/************************************************************************/
/*                              IMPORTANTE                              */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/  
/*                              PROPOSITO                               */
/*   Generador de secuenciales por operacion.                           */
/************************************************************************/  
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_gen_sec')
   drop proc sp_gen_sec
go

create proc sp_gen_sec 
   @i_operacion      int =  null
as

declare @w_secuencial int

update ca_secuenciales with (rowlock) set
--@w_secuencial = se_secuencial + 1,  --LPO Ajustes migracio a Java
se_secuencial = se_secuencial + 1
where se_operacion = isnull(@i_operacion, -1)

if @@rowcount = 0 begin
   insert into ca_secuenciales with (rowlock) values (isnull(@i_operacion, -1), 1)
   return 1
end

--LPO Ajustes migracio a Java INICIO
SELECT @w_secuencial = se_secuencial
FROM ca_secuenciales
WHERE se_operacion = isnull(@i_operacion, -1)
--LPO Ajustes migracio a Java FIN

return @w_secuencial

go
