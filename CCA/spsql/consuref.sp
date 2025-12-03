/************************************************************************/
/*	Archivo:		consuref.sp        			*/
/*	Stored procedure:	sp_consulta_ref                         */
/*	Base de datos:		cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Jorge Latorre               		*/
/*	Fecha de escritura:	Ene  2 2000  				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	"MACOSA".							*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/*				PROPOSITO				*/
/*	                                                                */ 
/*	I: Validar si el usuario posee malas referencias                */
/************************************************************************/

use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_consulta_ref')
	drop proc sp_consulta_ref
go

create proc sp_consulta_ref (
	@s_ssn			int = NULL,
	@s_user			login = NULL,
	@s_sesn			int = NULL,
	@s_term			varchar(30) = NULL,
	@s_date			datetime = NULL,
	@s_srv			varchar(30) = NULL,
	@s_lsrv			varchar(30) = NULL, 
	@s_rol			smallint = NULL,
	@s_ofi			smallint = NULL,
	@s_org_err		char(1) = NULL,
	@s_error		int = NULL,
	@s_sev			tinyint = NULL,
	@s_msg			descripcion = NULL,
	@s_org			char(1) = NULL,
	@t_debug		char(1) = 'N',
	@t_file			varchar(14) = null,
	@t_from			varchar(32) = null,
	@t_trn			smallint = null,
 	@i_operacion		char(2),
 	@i_codigo		char(10) = null,
 	@i_modo			tinyint = null,
 	@i_nit 		        int = null,
 	@i_tramite              int  = null
 	


)
as
declare  @w_sp_name varchar(32),
         @w_op_naturaleza   char(1),
         @w_tr_tipo         char(1),
         @w_mala_ref        char(1),
         @w_banca           catalogo,
         @w_rowcount        int

select @w_sp_name = 'sp_consulta_ref'


--  Search 
if @i_operacion = 'S' begin
 if @t_trn =7225 begin
    select @w_mala_ref  = en_mala_referencia,  ---1
           @w_banca     = en_banca             ---2
    from cobis..cl_ente where en_ente = @i_nit
    select @w_rowcount = @@rowcount
    set transaction isolation level read uncommitted

    -- INI - para pruebas en ambiente TEST
   select @w_mala_ref  = 'N',  ---1
           @w_banca     = en_banca             ---2
    from cobis..cl_ente where en_ente = @i_nit
   -- FIN - para pruebas en ambiente TEST
   
    if @w_rowcount = 0 
    begin
       exec cobis..sp_cerror
       @t_debug	 = @t_debug,
       @t_file	    = @t_file,
       @t_from	    = @w_sp_name,
       @i_num	    = 710200
	    return 1
    end

  
    if @w_mala_ref = 'S'
       begin
         select @w_tr_tipo = 'O'
         select @w_tr_tipo = tr_tipo
         from cob_credito..cr_tramite
         where tr_tramite = @i_tramite
         
         select @w_op_naturaleza = op_naturaleza
         from ca_operacion
         where op_tramite = @i_tramite
         
         --SI ES UNA NOVEDAD O UNA OBLIGACION PASIVA
         if @w_tr_tipo = 'R' or @w_op_naturaleza = 'P'
            select @w_mala_ref = 'N'
       end
     select @w_mala_ref,
            @w_banca
     return 0
 end

 else begin
      exec cobis.. sp_cerror
      @t_debug	 = @t_debug,
      @t_file	 = @t_file,
      @t_from	 = @w_sp_name,
      @i_num	 = 151051
	return 1
 end
end
go

