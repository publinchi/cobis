/************************************************************************/
/*      Archivo:                conpendes.sp                            */
/*      Stored procedure:       sp_consulta_pend_desem                  */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Miguel Roa                              */
/*      Fecha de escritura:     May. 2008                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.	                                                      */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Presenta la relacion de operaciones pendientes de desembolso    */
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_consulta_pend_desem')
   drop proc sp_consulta_pend_desem
go

create proc sp_consulta_pend_desem
    @s_user       login     = null,
    @t_trn        smallint  = null,
    @t_debug      char(1)   = 'N',
    @i_oficina    smallint  = null,
    @i_estado     tinyint   = null,
    @i_operacion  char(1)   = null,
    @i_siguiente  varchar(30)  = '01/01/200800000'

as

declare @w_sp_name            varchar(32),
        @w_return             int,
        @w_error              int,
        @w_operacionca        int,
        @w_banco              cuenta,
        @w_op_cliente         int,
        @w_op_tramite         int,
        @w_fecha_apr          datetime,
        @w_op_monto_apr       money,
        @w_op_tplazo          catalogo,
        @w_op_plazo           smallint,
        @w_op_oficial         smallint,
        @w_nom_oficial        descripcion,
        @w_est_no_vigente     tinyint,
        @w_en_ente            int,
        @w_en_nomlar          varchar(254),
        @w_en_ced_ruc         numero,
        @w_di_ente            int,
        @w_di_direccion       tinyint,
        @w_di_descripcion     varchar(254),
        @w_tel_neg            varchar(20),
        @w_tel_dom            varchar(20),
        @w_tipo_cliente       char(10),
        @w_pa_char_tdr        char(3),
        @w_pa_char_tdn        char(3)


/* ESTADO DEL DIVIDENDO */
select @w_est_no_vigente = es_codigo
from   ca_estado 
where  ltrim(rtrim(es_descripcion)) = 'NO VIGENTE'

/* PARAMETROS DE TIPOS DE DIRECCION */
select @w_pa_char_tdr = pa_char
from   cobis..cl_parametro
where  ltrim(rtrim(pa_nemonico)) = 'TDR'

select @w_pa_char_tdn = pa_char
from   cobis..cl_parametro
where  ltrim(rtrim(pa_nemonico)) = 'TDN'

/*CREACION DE TABLA TEMPORAL DEFINITIVA */
create table #operaciones
(
tmp_cliente         int         not null, --Numero del cliente cob_cartera..ca_operacion/op_cliente
tmp_tramite         int         not null, --Numero del trámite cob_credito..cr_tramite/tr_tramite
tmp_en_ced_ruc      numero      not null, --Numero de identificación del solicitante cobis..cl_ente/en_ced_ruc
tmp_nomlar          varchar(50) not null, --Nombre largo en cl_ente cobis..cl_ente/en_nomlar
tmp_fecha_apr       datetime    not null, --Fecha de aprobación cob_credito..cr_tramite/tr_fecha_apr
tmp_monto_apr       money       not null, --Monto aprobado cob_cartera..ca_operacion/op_monto_aprobado
tmp_tplazo_apr      catalogo    not null, --Tipo de plazo aprobado cob_cartera..ca_operacion/op_tplazo
tmp_plazo_apr       smallint    not null, --Plazo aprobado cob_cartera..ca_operacion/op_plazo
tmp_oficial         smallint    not null, --Oficial del préstamo cob_cartera..ca_operacion/op_oficial
tmp_nom_oficial     descripcion not null, --Nombre del oficial del préstamo
tmp_tel_neg         varchar(16) not null, --Teléfono del negocio cobis..cl_telefono/PENDIENTE ALEXANDRA
tmp_tel_dom         varchar(16) not null, --Telefono del domicilio cobis..cl_telefono/PENDIENTE ALEXANDRA
tmp_tipo_cliente    varchar(16) not null, --Indicador de cliente nuevo o renovado (N/R)
tmp_banco           cuenta      not null, --Numero de la operacion para llamar al encabezado
)


/*CONSULTAR OPERACIONES */
if @i_operacion = 'Q'
begin
   /* CURSOR PARA DETERMINAR TODAS LAS OPERACIONES OBJETO DE LA CONSULTA */
   declare
   cursor_operaciones cursor
   for select
         op_cliente,         op_tramite,          op_monto_aprobado,                 op_tplazo,
         op_plazo,           op_oficial,          isnull(tr_fecha_apr,op_fecha_liq), op_nombre,
         op_banco
   from  ca_operacion, cob_credito..cr_tramite
   where op_oficina = @i_oficina
   and   op_estado  = @w_est_no_vigente
   and   tr_tramite = op_tramite
   and   convert(varchar(10),tr_fecha_apr,103) + convert(varchar,tr_tramite) > @i_siguiente
   order by isnull(convert(varchar(10),tr_fecha_apr,103),op_fecha_liq), tr_tramite
   
   for read only
   
   open  cursor_operaciones
   fetch cursor_operaciones
   into  @w_op_cliente,      @w_op_tramite,       @w_op_monto_apr,           @w_op_tplazo,
         @w_op_plazo,        @w_op_oficial,       @w_fecha_apr,              @w_en_nomlar,
         @w_banco

   while   @@fetch_status = 0
   begin
      if (@@fetch_status = -1) return 710004

      insert into #operaciones
             (tmp_cliente,        tmp_tramite,    tmp_en_ced_ruc,   tmp_nomlar,      tmp_fecha_apr,   tmp_monto_apr,
              tmp_tplazo_apr,     tmp_plazo_apr,  tmp_oficial,      tmp_nom_oficial, tmp_tel_neg,     tmp_tel_dom,
              tmp_tipo_cliente,   tmp_banco)
      values (
              @w_op_cliente,      @w_op_tramite,  0,                ' ',            @w_fecha_apr,    @w_op_monto_apr,
              @w_op_tplazo,       @w_op_plazo,    @w_op_oficial,    ' ',            0,               0,
              ' ',                @w_banco)
                       
      
      /* BUSQUEDA DATOS DEL CLIENTE */
      select 
      @w_en_ente    = en_ente, 
      @w_en_nomlar  = en_nomlar, 
      @w_en_ced_ruc = en_ced_ruc
      from cobis..cl_ente
      where en_ente      = @w_op_cliente
    
      --print '@w_op_cliente' + cast(@w_op_cliente as varchar)
      
      /* DETERMINA DIRECCIONES Y TELEFONO DOMICILIO DEL CLIENTE */
      select @w_tel_dom = ''
      select @w_tel_dom = substring(te_prefijo,1,3) +'-'+ isnull(te_valor,0)
      from   cobis..cl_direccion
             left outer join cobis..cl_telefono on
                  te_ente      = di_ente
             and  te_direccion = di_direccion
      where di_ente      = @w_op_cliente
      and   di_tipo      = @w_pa_char_tdn
      if @@rowcount = 0 select @w_tel_dom = 0

      /* DETERMINA DIRECCIONES Y TELEFONO NEGOCIO DEL CLIENTE */
      select @w_tel_neg = ''
      select @w_tel_neg = substring(te_prefijo,1,3) +'-'+ isnull(substring(te_valor,1,10),0)
      from   cobis..cl_direccion
             left outer join cobis..cl_telefono on
                  te_ente      = di_ente
             and  te_direccion = di_direccion
      where di_ente          = @w_op_cliente
      and   di_tipo          = @w_pa_char_tdr
      if @@rowcount = 0 select @w_tel_neg = 0


      /* DETERMINA CLIENTE NUEVO O RENOVADO */
      if exists (select 1
                 from ca_operacion
                 where op_cliente =  @w_op_cliente
                 and   op_tramite <> @w_op_tramite)
          select @w_tipo_cliente = 'RENOVADO'
      else
          select @w_tipo_cliente = 'NUEVO'

      /* CONVIERTE PLAZO A MESES */
      select @w_op_plazo = (@w_op_plazo * isnull((select td_factor
                                          from ca_tdividendo
                                          where td_tdividendo = @w_op_tplazo
                                          and   td_estado     = 'V'),0))/30

      /* OBTIENE NOMBRE DEL OFICIAL */
      select  @w_nom_oficial = fu_login   ---fu_nombre
      from  cobis..cc_oficial,
            cobis..cl_funcionario,
            cobis..cl_catalogo
      where oc_oficial       = @w_op_oficial
      and   oc_funcionario   = fu_funcionario 
      and   codigo           = oc_tipo_oficial
      and   tabla = (select codigo 
                     from cobis..cl_tabla
                     where tabla = 'cc_tipo_oficial')
      set transaction isolation level read uncommitted
      
      /* ACTUALIZA TEMPORAL CON DATOS ENCONTRADOS */
      if exists (select 1
                 from #operaciones
                 where tmp_cliente = @w_op_cliente)
      begin
          update #operaciones
          set   tmp_en_ced_ruc   = @w_en_ced_ruc,
                tmp_nomlar       = @w_en_nomlar,
                tmp_tel_neg      = @w_tel_neg,
                tmp_tel_dom      = @w_tel_dom,
                tmp_tipo_cliente = @w_tipo_cliente,
                tmp_plazo_apr    = @w_op_plazo,
                tmp_nom_oficial  = @w_nom_oficial
          where tmp_cliente      = @w_op_cliente
      end


      fetch cursor_operaciones
      into  @w_op_cliente,      @w_op_tramite,       @w_op_monto_apr,           @w_op_tplazo,
            @w_op_plazo,        @w_op_oficial,       @w_fecha_apr,              @w_en_nomlar,
            @w_banco
   end --end while cursor_operaciones
   close cursor_operaciones
   deallocate cursor_operaciones
end



set rowcount 20
select tmp_tramite,   tmp_en_ced_ruc,  tmp_nomlar,    convert(varchar(10),tmp_fecha_apr,103), tmp_monto_apr,
       tmp_plazo_apr, tmp_nom_oficial, tmp_tel_neg,   tmp_tel_dom,                            tmp_tipo_cliente,       tmp_banco
from #operaciones
where convert(varchar(10),tmp_fecha_apr,103) + convert(varchar,tmp_tramite) > @i_siguiente
order by convert(varchar(10),tmp_fecha_apr,103), tmp_tramite

set rowcount 0


return 0

ERROR:

exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_error
   
return @w_error
                        
go
