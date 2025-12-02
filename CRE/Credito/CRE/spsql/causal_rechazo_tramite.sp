/************************************************************************/
/*  Archivo:                causal_rechazo_tramite.sp                   */
/*  Stored procedure:       sp_causal_rechazo_tramite                   */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jose Ortiz                                  */
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
/*  23/04/19          Jose Ortiz       Emision Inicial                  */
/* **********************************************************************/
use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_causal_rechazo_tramite' and type = 'P')
   drop proc sp_causal_rechazo_tramite
go


create proc sp_causal_rechazo_tramite (
   @s_ssn                int      = null,
   @s_date               datetime = null,
   @s_user               login    = null,
   @s_term               descripcion = null,
   @s_ofi                smallint  = null,
   @s_srv                varchar(30) = null,
   @s_lsrv               varchar(30) = null,
   @t_rty                char(1)  = null,
   @t_trn                smallint = null,
   @t_debug              char(1)  = 'N',
   @t_file               varchar(14) = null,
   @t_from               varchar(30) = null,
   @i_operacion          char(1)  = null,
   @i_modo               smallint = 0,
   @i_tramite            int  = null,
   @i_tipo               varchar(10)  = null,
   @i_etapa              tinyint  = null,
   @i_requisito          catalogo  = null
 
)
as

declare
   @w_today              datetime,     /* FECHA DEL DIA      */ 
   @w_return             int,          /* VALOR QUE RETORNA  */
   @w_sp_name            varchar(32),  /* NOMBRE STORED PROC */
   @w_existe             tinyint,      /* EXISTE EL REGISTRO */
   @w_tramite            int,
   @w_tipo               char(  1),
   @w_etapa              tinyint,
   @w_requisito          catalogo,
   @w_observacion        descripcion,
   @w_fecha_modif        datetime,
   @w_naturaleza_p       catalogo,
   @w_naturaleza_c       catalogo,
   @w_naturaleza         catalogo,
   @w_desc_naturaleza    descripcion,
   @w_tipo_tramite       char(1)      --LAZ

select @w_today = @s_date
select @w_sp_name = 'sp_causal_rechazo_tramite'

/***********************************************************/
/* CODIGOS DE TRANSACCIONES                                */

if (@t_trn <> 21760 and @i_operacion = 'I')
or (@t_trn <> 21761 and @i_operacion = 'U')
or (@t_trn <> 21762 and @i_operacion = 'D')
or (@t_trn <> 21763 and @i_operacion = 'S')
or (@t_trn <> 21764 and @i_operacion = 'Q')
begin
   /* TIPO DE TRANSACCION NO CORRESPONDE */
   exec cobis..sp_cerror
   @t_debug = @t_debug,
   @t_file  = @t_file, 
   @t_from  = @w_sp_name,
   @i_num   = 2101006
   return 1 
end

/* CHEQUEO DE EXISTENCIAS */
/**************************/
if @i_operacion <> 'S' and @i_operacion <> 'Q'
begin
   select 
   @w_tramite = cr_tramite,
   @w_etapa = cr_etapa,
   @w_requisito = cr_requisito
   from cob_credito..cr_cau_tramite
   where cr_tramite   = @i_tramite
   and   cr_etapa     = @i_etapa
   and   cr_requisito = @i_requisito
   and   cr_tipo      = @i_tipo

   if @@rowcount > 0
      select @w_existe = 1
   else
      select @w_existe = 0
end

/*************************************/
/********Desistidos Aprobados*********/
/*************************************/

if @i_tipo = 'DEA'
begin
   select   @w_tipo_tramite   = tr_tipo
   from     cr_tramite
   where    tr_tramite   =   @i_tramite 

   if @w_tipo_tramite not in('O','R','C')
   begin
      print 'LOS TRAMITES QUE PERMITEN DESISITIMIENTO SON CUPOS/SOLICITUD, RENOVACIONES Y OPERACIONES ORIGINALES'

   end
   if @w_tipo_tramite = 'C'
   begin
      if exists (select   1
                 from     cr_linea
                 where    li_tramite = @i_tramite 
                 and      li_estado  in ('V','B'))
      begin
         select   @w_tipo_tramite   =   @w_tipo_tramite   
      end
      else
      begin
         print 'EL ESTADO DEL CUPO SOLICTUD NO PERMITE DESISTIMIENTO'
         return 0
      end
   end

   if @w_tipo_tramite in('O','R', 'T', 'U')
   begin
      if exists (select   1
                 from     cob_cartera..ca_operacion
                 where    op_tramite = @i_tramite 
                 and      op_estado  = 0)
      begin
         select   @w_tipo_tramite   =   @w_tipo_tramite   
      end
      else
      begin
         print 'EL ESTADO DE LA OBLIGACION NO PERMITE DESISTIMIENTO'
         return 0
      end
   end

end



/* VALIDACION DE CAMPOS NULOS */
/******************************/
if @i_operacion = 'I' or @i_operacion = 'U'
begin
   if @i_tramite is null
   or @i_etapa is null
   or @i_requisito is null
   begin
      /* CAMPOS NOT NULL CON VALORES NULOS */
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 2101001
      return 1 
   end
end
if @i_operacion = 'S'
begin
   if @i_tramite is null
   or @i_etapa is null
   begin
      /* CAMPOS NOT NULL CON VALORES NULOS */
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 2101001
      return 1 
   end
end


/* INSERCION DEL REGISTRO */
/**************************/

if @i_operacion = 'I'
begin
   if @w_existe = 1
   begin
      return 1 
   end

   begin tran
      insert into cr_cau_tramite (
      cr_tramite, cr_etapa,
      cr_requisito, cr_tipo )
      values (
      @i_tramite, @i_etapa,
      @i_requisito, @i_tipo)

      if @@error <> 0 
      begin
         /* ERROR EN INSERCION DE REGISTRO */
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file, 
         @t_from  = @w_sp_name,
         @i_num   = 2103001
         return 1 
      end

      /* TRANSACCION DE SERVICIO */
      /***************************/

      insert into ts_cau_tramite
      values (
      @s_ssn, @t_trn, 'N',
      @s_date, @s_user, @s_term,
      @s_ofi, 'cr_cau_tramite', @s_lsrv,
      @s_srv, @i_tramite, @i_etapa, 
      @i_requisito)

      if @@error <> 0 
      begin
         /* ERROR EN INSERCION DE TRANSACCION DE SERVICIO */
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file, 
         @t_from  = @w_sp_name,
         @i_num   = 2103003
         return 1 
      end
   commit tran 

end

/* ACTUALIZACION DEL REGISTRO */
/******************************/

if @i_operacion = 'U'
begin
   if @w_existe = 0
   begin
      /* REGISTRO A ACTUALIZAR NO EXISTE */
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 2105002
      return 1 
   end

   begin tran
      update cob_credito..cr_cau_tramite set 
      cr_tramite = @i_tramite,
      cr_etapa   = @i_etapa,
      cr_requisito = @i_requisito
      where 
      cr_tramite       = @i_tramite
      and cr_etapa     = @i_etapa
      and cr_requisito = @i_requisito
      and cr_tipo      = @i_tipo

      if @@error <> 0 
      begin
         /* ERROR EN ACTUALIZACION DE REGISTRO */
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file, 
         @t_from  = @w_sp_name,
         @i_num   = 2105001
         return 1 
      end

      /* TRANSACCION DE SERVICIO */
      /***************************/

      insert into ts_cau_tramite
      values (
      @s_ssn, @t_trn, 'P',
      @s_date, @s_user, @s_term,
      @s_ofi, 'cr_req_tramite', @s_lsrv,
      @s_srv, @w_tramite, @w_etapa, 
      @w_requisito)

      if @@error <> 0 
      begin
         /* ERROR EN INSERCION DE TRANSACCION DE SERVICIO */
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file, 
         @t_from  = @w_sp_name,
         @i_num   = 2103003
         return 1 
      end

      /* TRANSACCION DE SERVICIO */
      /***************************/

      insert into ts_cau_tramite
      values (
      @s_ssn, @t_trn, 'A',
      @s_date, @s_user, @s_term,
      @s_ofi, 'cr_req_tramite', @s_lsrv,
      @s_srv, @i_tramite, @i_etapa, 
      @i_requisito)

      if @@error <> 0 
      begin
         /* ERROR EN INSERCION DE TRANSACCION DE SERVICIO */
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file, 
         @t_from  = @w_sp_name,
         @i_num   = 2103003
         return 1 
      end
   commit tran
end

/* ELIMINACION DE REGISTROS */
/****************************/

if @i_operacion = 'D'
begin
   if @w_existe = 0
   begin
      return 1 
   end

   begin tran

      delete cob_credito..cr_cau_tramite
      where cr_tramite = @i_tramite
      and cr_etapa = @i_etapa
      and cr_requisito = @i_requisito
      and cr_tipo = @i_tipo

      if @@error <> 0
      begin
         /*ERROR EN ELIMINACION DE REGISTRO */
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file, 
         @t_from  = @w_sp_name,
         @i_num   = 2107001
         return 1 
      end

      /* TRANSACCION DE SERVICIO */
      /***************************/

      insert into ts_cau_tramite
      values (
      @s_ssn, @t_trn, 'B',
      @s_date, @s_user, @s_term,
      @s_ofi, 'cr_req_tramite', @s_lsrv,
      @s_srv, @w_tramite, @w_etapa, 
      @w_requisito)

      if @@error <> 0 
      begin
         /* ERROR EN INSERCION DE TRANSACCION DE SERVICIO */
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file, 
         @t_from  = @w_sp_name,
         @i_num   = 2103003
         return 1 
      end
   commit tran
end

/**** SEARCH ****/
/****************/
if @i_operacion = 'S'
begin

select
@w_tipo_tramite = tr_tipo
from cr_tramite
where tr_tramite = @i_tramite


if @i_modo = 0
begin
      select distinct 
      'Requisito'   = X.cq_causal,
      'Descripci¢n' = 	(select valor from cobis..cl_catalogo 
			where tabla in 	(select codigo from cobis..cl_tabla 
					where tabla = 'cr_causales_devolucion')
			and   codigo = X.cq_causal)
      from  cr_cau_etapa X, cr_cau_tramite
      where cr_tramite = @i_tramite
      and cr_etapa   = @i_etapa
      and X.cq_etapa = @i_etapa
      and X.cq_etapa = cr_etapa   
      and X.cq_tipo = @i_tipo
      and X.cq_tipo = cr_tipo
      and cr_tipo   = @i_tipo
      and X.cq_causal = cr_requisito
      and X.cq_tipo_tramite = @w_tipo_tramite

      select distinct 
      'Requisito'   = X.cq_causal,
      'Descripci¢n' = 	(select valor from cobis..cl_catalogo 
			where tabla in 	(select codigo from cobis..cl_tabla 
					where tabla = 'cr_causales_devolucion')
			and   codigo = X.cq_causal)
      from  cr_cau_etapa X
      where X.cq_etapa = @i_etapa
      and   X.cq_tipo = @i_tipo
      and   X.cq_tipo_tramite = @w_tipo_tramite
      and   X.cq_causal not in 	(select cr_requisito  from cr_cau_tramite 
				 where cr_tramite = @i_tramite
				 and   cr_etapa   = @i_etapa
				 and   cr_tipo    = @i_tipo)
end

if @i_modo = 1
begin
      select distinct 
      'Requisito'   = X.cq_causal,
      'Descripci¢n' = 	(select valor from cobis..cl_catalogo 
			where tabla in 	(select codigo from cobis..cl_tabla 
					where tabla = 'cr_causales_devolucion')
			and   codigo = X.cq_causal),
      'Tipo'	    = cq_tipo
      from  cr_cau_etapa X, cr_cau_tramite
      where cr_tramite = @i_tramite
      and cr_etapa   = @i_etapa
      and X.cq_etapa = @i_etapa
      and X.cq_etapa = cr_etapa         
      and X.cq_tipo  = cr_tipo
      and X.cq_causal = cr_requisito
      and X.cq_tipo_tramite = @w_tipo_tramite
end

end
return 0

GO
