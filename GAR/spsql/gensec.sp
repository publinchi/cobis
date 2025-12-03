/************************************************************************/                                                 
/*  Archivo:            gensec.sp                                       */                                                 
/*  Stored procedure:   sp_gensec                                       */                                                 
/*  Base de datos:      cob_custodia                                    */                                                 
/*  Producto:           Custodia                                        */                                                 
/*  Disenado por:       Patricia Garzon                                 */                                                 
/*  Fecha de escritura: may 2001                                        */                                                 
/************************************************************************/                                                 
/*                          IMPORTANTE                                  */                                                 
/*  Este programa es parte de los paquetes bancarios propiedad de       */                                                 
/*  "MACOSA".                                                           */                                                 
/*  Su uso no autorizado queda expresamente prohibido asi como          */                                                 
/*  cualquier alteracion o agregado hecho por alguno de sus             */                                                 
/*  usuarios sin el debido consentimiento por escrito de la             */                                                 
/*  Presidencia Ejecutiva de MACOSA o su representante.                 */                                                 
/************************************************************************/                                                 
/*                         PROPOSITO                                    */                                                 
/*  Procedimiento que genera el secuenciales para transacciones de      */                                                 
/*      servicio tomando como parametro la garantia.                    */                                                 
/************************************************************************/                                                 
/*                         MODIFICACIONES                               */                                                 
/*  FECHA       AUTOR       RAZON                                       */                                                 
/************************************************************************/                                                 
use cob_custodia
go

if exists (select 1 from sysobjects where name = "sp_gen_sec")
    drop proc sp_gen_sec
go

create proc sp_gen_sec 
    @i_garantia     varchar(64)   = null
as

declare @secuencia int
begin 
   if not exists (select 1 from cu_secuenciales
                 where se_garantia = @i_garantia) 
   begin
        insert into cu_secuenciales values (@i_garantia,1)
        select @secuencia =  1
   end
   else 
   begin
      select @secuencia =  se_secuencial
      from cu_secuenciales
      where se_garantia = @i_garantia
   end

   update  cu_secuenciales
   set se_secuencial = se_secuencial + 1
   from cu_secuenciales
   where se_garantia = @i_garantia

   return @secuencia
end
go