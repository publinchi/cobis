/************************************************************************/
/*	Archivo:		consacpa.sp				*/
/*	Stored procedure:	sp_consulta_act_pas			*/
/*	Base de datos:		cob_cartera				*/
/*	Producto: 		Credito y Cartera			*/
/*	Disenado por:  		Ramiro Buitron 				*/
/*	Fecha de escritura:	19/05/1999				*/
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
/*	Este stored procedure realiza la consulta de operaciones pasivas*/
/*	relacionadas a operaciones activas y viceversa                  */
/*	S: Busqueda de operaciones 					*/
/************************************************************************/

use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_consulta_act_pas')
	drop proc sp_consulta_act_pas
go


create proc sp_consulta_act_pas (
@i_oper          int      = null,
@i_operacion	 char(1)  = null,
@i_modo 	 tinyint  = null,
@i_sec           cuenta   = null,
@i_formato_fecha int  	  = null,
@i_tipo          char(1)  = null
)
as
declare 
@w_sp_name	descripcion,
@w_error	int


/*  INICIALIZAR VARIABLES  */
	select	@w_sp_name = 'sp_consulta_act_pas'


/* SEARCH */

if @i_operacion = 'S' begin   
  select @w_error = 0
   if @i_modo = 0 begin
      truncate table ca_actpas_tmp
      set rowcount 0

      insert into ca_actpas_tmp
      select
      (select A.op_banco from ca_operacion A where A.op_operacion = B.rp_activa), 
      (select valor from cobis..cl_tabla X, cobis..cl_catalogo Y
              where X.tabla = 'ca_toperacion' and X.codigo= Y.tabla
              and   Y.codigo= B.rp_lin_activa), 
      A.op_nombre,
      (select A.op_banco from ca_operacion A where A.op_operacion = B.rp_pasiva),
      (select valor from cobis..cl_tabla X, cobis..cl_catalogo Y
              where X.tabla = 'ca_toperacion' and X.codigo= Y.tabla
              and   Y.codigo= B.rp_lin_pasiva),
      null,
      B.rp_fecha_ini, B.rp_fecha_fin, B.rp_saldo_act, B.rp_saldo_pas, B.rp_fecha_grb,
      B.rp_usuario_grb, B.rp_fecha_upd, B.rp_usuario_upd, A.op_tipo,
      (select A.op_fondos_propios from ca_operacion A where A.op_operacion = B.rp_pasiva), 
      (select A.op_origen_fondos from ca_operacion A where A.op_operacion = B.rp_pasiva),
      B.rp_hora_grb, B.rp_hora_upd,
      (select A.op_moneda from ca_operacion A where A.op_operacion = B.rp_activa)
      from ca_operacion A, ca_relacion_ptmo B --(index ca_relacion_ptmo_1) (index ca_operacion_1)
	   where (A.op_operacion = @i_oper and B.rp_activa = @i_oper)
              or (A.op_operacion = @i_oper and B.rp_pasiva = @i_oper)
    
      if @@rowcount = 0 begin  
	 select @w_error = 1
         goto ERROR
      end


      update ca_actpas_tmp  set ap_entidad_pasiva = Y.valor       
             from cobis..cl_tabla X, cobis..cl_catalogo Y
             where X.codigo = Y.tabla
             and Y.codigo = ap_origen_fondos
             and ((ap_fondos_propios = 'S' and X.tabla = 'ca_fondos_propios')
             or (ap_fondos_propios = 'N' and X.tabla = 'ca_fondos_nopropios'))
 

      set rowcount 20
  
      select
      'Oper. Activa'         = ap_oper_act,
      'Línea Crédito Activa' = ap_lin_cre_act,  
      'Nombre Cliente'       = ap_nom_cli,
      'Oper. Pasiva'         = ap_oper_pas,
      'Línea Crédito Pasiva' = ap_lin_cre_pas,
      'Entidad Pasiva'       = ap_entidad_pasiva,
      'Inicio Relación'      = convert(varchar(10),ap_fec_ini,@i_formato_fecha),
      'Fin Relación'         = convert(varchar(10),ap_fec_fin,@i_formato_fecha),
      'Saldo Activo Antes Rel.'  = convert(float,ap_saldo_act),
      'Saldo Pasivo Antes Rel.'  = convert(float,ap_saldo_pas),
      'Registro Rel.'  = convert(varchar(10),ap_fecha_grb,@i_formato_fecha),
      'Usuario Rel.'     = ap_usuario_grb,
      'Hora Rel.'        = ap_hora_grb,
      'Modificación'  = convert(varchar(10),ap_fecha_upd,@i_formato_fecha),
      'Usuario Modif.' = ap_usuario_upd,
      'Hora Modif.'    = ap_hora_upd,
      'Tipo'                 = ap_tipo,
      'Moneda'               = ap_moneda
      from ca_actpas_tmp
      order by ap_fec_fin desc, ap_oper_act, ap_oper_pas 
      if @@rowcount = 0  begin
	   select @w_error = 1
	   goto ERROR
      end
  end      

  /* TRAER LOS VEINTE SIGUIENTES */
   if @i_modo = 1 begin
           
      if   @i_tipo <> 'R' begin
         set rowcount 20
	 select
      'Oper. Activa'         = ap_oper_act,
      'Línea Crédito Activa' = ap_lin_cre_act,  
      'Nombre Cliente'       = ap_nom_cli,
      'Oper. Pasiva'         = ap_oper_pas,
      'Línea Crédito Pasiva' = ap_lin_cre_pas,
      'Entidad Pasiva'       = ap_entidad_pasiva,
      'Inicio Relación'      = convert(varchar(10),ap_fec_ini,@i_formato_fecha),
      'Fin Relación'         = convert(varchar(10),ap_fec_fin,@i_formato_fecha),
      'Saldo Activo Antes Rel.'  = convert(float,ap_saldo_act),
      'Saldo Pasivo Antes Rel.'  = convert(float,ap_saldo_pas),
      'Registro Rel.'  = convert(varchar(10),ap_fecha_grb,@i_formato_fecha),
      'Usuario Rel.'     = ap_usuario_grb,
      'Hora Rel.'        = ap_hora_grb,
      'Modificación'  = convert(varchar(10),ap_fecha_upd,@i_formato_fecha),
      'Usuario Modif.' = ap_usuario_upd,
      'Hora Modif.'    = ap_hora_upd,
      'Tipo'                 = ap_tipo,
      'Moneda'               = ap_moneda
         from ca_actpas_tmp where ap_oper_pas > @i_sec
         order by ap_fec_fin desc, ap_oper_act, ap_oper_pas       

         if @@rowcount = 0 begin
	    truncate table ca_actpas_tmp
            select @w_error = 1
	    goto ERROR
	 end
      end else begin
         set rowcount 20
         select
      'Oper. Activa'         = ap_oper_act,
      'Línea Crédito Activa' = ap_lin_cre_act,  
      'Nombre Cliente'       = ap_nom_cli,
      'Oper. Pasiva'         = ap_oper_pas,
      'Línea Crédito Pasiva' = ap_lin_cre_pas,
      'Entidad Pasiva'       = ap_entidad_pasiva,
      'Inicio Relación'      = convert(varchar(10),ap_fec_ini,@i_formato_fecha),
      'Fin Relación'         = convert(varchar(10),ap_fec_fin,@i_formato_fecha),
      'Saldo Activo Antes Rel.'  = convert(float,ap_saldo_act),
      'Saldo Pasivo Antes Rel.'  = convert(float,ap_saldo_pas),
      'Registro Rel.'  = convert(varchar(10),ap_fecha_grb,@i_formato_fecha),
      'Usuario Rel.'     = ap_usuario_grb,
      'Hora Rel.'        = ap_hora_grb,
      'Modificación'  = convert(varchar(10),ap_fecha_upd,@i_formato_fecha),
      'Usuario Modif.' = ap_usuario_upd,
      'Hora Modif.'    = ap_hora_upd,
      'Tipo'                 = ap_tipo,
      'Moneda'               = ap_moneda
         from ca_actpas_tmp where ap_oper_act > @i_sec
         order by ap_fec_fin desc, ap_oper_act, ap_oper_pas       

         if @@rowcount = 0 begin
            truncate table ca_actpas_tmp
 	    select @w_error = 1
	    goto ERROR
	 end
     end
  end
end


return 0

ERROR:
if @w_error = 1 print 'No existen mas operaciones'
   return 1
go
                                                                               
		
