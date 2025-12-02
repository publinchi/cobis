/************************************************************************/
/*	Archivo:		desemconv.sp				*/
/*	Stored procedure:	sp_desembolso_conv		        */
/*	Base de datos:		cob_cartera				*/
/*	Producto: 		Credito y Cartera			*/
/*	Disenado por:  		Julio Quintero				*/
/*	Fecha de escritura:	Feb.2004 				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	"MACOSA".							*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/************************************************************************/
/*				PROPOSITO				*/
/*	LLena estructura para plano de desembolso, interfaz             */
/*      PIT                                                             */
/************************************************************************/
/*                              CAMBIOS                                 */
/*      FECHA              AUTOR             CAMBIOS                    */
/*			  		  				*/   
/************************************************************************/

use cob_cartera
go



if exists (select 1 from sysobjects where name = 'ca_desembolso_conv')
   drop table ca_desembolso_conv
go

create table ca_desembolso_conv
(oficina     	char(4),
 cuenta		char(7),
 aplicacion	char(1),
 transaccion	char(2),
 tipotrans	char(2),
 nro_docum	char(8),
 vr_total	char(14),
 vr_canje	char(14),
 ofic_origen	char(4),
 filler		char(44))
go




if exists (select 1 from sysobjects where name = 'sp_desembolso_conv')
   drop proc sp_desembolso_conv
go

create proc sp_desembolso_conv
@i_fecha_proceso     	datetime
as

declare 
	@w_return         	int,
	@w_sp_name        	descripcion,
	@w_dm_oficina		smallint,		
	@w_dm_cuenta		cuenta,		
	@w_dm_producto		catalogo,
	@w_dm_monto_mn		money,		
	@w_op_oficina		smallint, 
 	@w_oficina     		char(4),
 	@w_cuenta		char(7),
	@w_aplicacion		char(1),
	@w_transaccion		char(2),
	@w_tipotrans		char(2),
	@w_nro_docum		char(8),
	@w_vr_total		char(14),
	@w_vr_canje		char(14),
	@w_ofic_origen		char(4),
	@w_filler		char(44)


--CARGADO DE VARIABLES DE TRABAJO 
select 
@w_sp_name          = 'sp_desembolso_conv',
@w_vr_total	    = '00000000000000'


truncate table ca_desembolso_conv

--- CURSO PARA DESEMBOLSO

declare cursor_desembolso cursor for
select 	dm_oficina,		dm_cuenta,		dm_producto,
	dm_monto_mn,		op_oficina 
from cob_cartera..ca_desembolso, ca_operacion, ca_transaccion
where dm_producto in ('DESEMNCCC', 'DESEMNCCH')  
and   op_operacion =  dm_operacion
and   op_operacion = tr_operacion
and   op_tipo      <> 'R'  ---Las pasivas no deben ir a este archivo
and   dm_operacion = tr_operacion
and   dm_estado    = 'A'
and   tr_tran      = 'DES'
and   tr_estado    <> 'RV'
and   tr_fecha_mov = @i_fecha_proceso
order by dm_operacion
for read only

   open  cursor_desembolso
   fetch cursor_desembolso into 
	@w_dm_oficina,		@w_dm_cuenta,		@w_dm_producto,
	@w_dm_monto_mn,		@w_op_oficina 

	while @@fetch_status = 0 
	begin   
	   if @@fetch_status = -1 
	   begin    
       	     PRINT 'desembolconv.sp error en lectura del cursor conciliacion diaria'
           end
   

	   select @w_oficina     = substring(@w_dm_cuenta,2,4),
       		  @w_cuenta      = substring(@w_dm_cuenta,6,7),
       		  @w_vr_total    = replicate('0',14-datalength(convert(varchar(14),@w_dm_monto_mn))) + convert(varchar(14),@w_dm_monto_mn), 
		  @w_ofic_origen = replicate('0',4-datalength(convert(varchar(4),@w_op_oficina))) + convert(varchar(4),@w_op_oficina)



           if ltrim(rtrim(@w_dm_producto)) = ltrim(rtrim('DESEMNCCC'))
           --if ltrim(rtrim(@w_dm_producto)) = ltrim(rtrim('CHEGER'))
              select @w_aplicacion = '1'


           if ltrim(rtrim(@w_dm_producto)) = ltrim(rtrim('DESEMNCCH'))
           --if ltrim(rtrim(@w_dm_producto)) = ltrim(rtrim('NCAHO'))
              select @w_aplicacion = '2'


           select @w_transaccion  = '10'
           select @w_tipotrans    = '00'
           select @w_nro_docum    = '00000000'
           select @w_vr_canje     = '00000000000000'
           select @w_filler       = replicate('',44)


           insert into ca_desembolso_conv
           values (@w_oficina,		@w_cuenta,	@w_aplicacion,	@w_transaccion,
		   @w_tipotrans,	@w_nro_docum,	'0' + substring(@w_vr_total,1,11) + '00',	
		   @w_vr_canje,  	'0000', 	@w_filler)


           fetch cursor_desembolso into 
	   @w_dm_oficina,		@w_dm_cuenta,		@w_dm_producto,
   	   @w_dm_monto_mn,		@w_op_oficina 
        end /* cursor_desembolso */

	close cursor_desembolso
	deallocate cursor_desembolso

return 0

go


