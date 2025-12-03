/*************************************************************************/
/*   Archivo:              consult1.sp                                   */
/*   Stored procedure:     sp_consult1                                   */
/*   Base de datos:        cob_custodia                                  */
/*   Producto:             Garantias                                     */
/*   Disenado por:         TEAM SENTINEL PRIME                           */
/*   Fecha de escritura:   Marzo 2019                                    */
/*************************************************************************/
/*                                  IMPORTANTE                           */
/*   Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*   de MACOSA S.A.                                                      */
/*   Su uso no autorizado queda expresamente prohibido asi como          */
/*   cualquier alteracion o agregado hecho por alguno de sus             */
/*   usuarios sin el debido consentimiento por escrito de MACOSA         */
/*   Este programa esta protegido por la ley de derechos de autor        */
/*   y por las  convenciones  internacionales de  propiedad inte-        */
/*   lectual.  Su uso no  autorizado dara  derecho a  MACOSA para        */
/*   obtener  ordenes de  secuestro o retencion y  para perseguir        */
/*   penalmente a los autores de cualquier infraccion.                   */
/*************************************************************************/
/*                             MODIFICACION                              */
/*    FECHA               AUTOR                     RAZON                */
/*    Marzo/2019          TEAM SENTINEL PRIME       emision inicial      */
/*                                                                       */
/*************************************************************************/

USE cob_custodia
GO

IF OBJECT_ID('dbo.sp_consult1') IS NOT NULL
    DROP PROCEDURE dbo.sp_consult1
go

create proc dbo.sp_consult1  (
   @s_ssn                int      = null,
   @s_date               datetime = null,
   @s_user               login    = null,
   @s_term               descripcion = null,
   @s_corr               char(1)  = null,
   @s_ssn_corr           int      = null,
   @s_ofi                smallint  = null,
   @t_rty                char(1)  = null,
   @t_trn                int      = null,
   @t_debug              char(1)  = 'N',
   @t_file               varchar(14) = null,
   @t_from               varchar(30) = null,
   @i_operacion          char(1)     = null,
   @i_modo               smallint    = null,
   @i_filial             tinyint     = null,
   @i_sucursal           smallint    = null,
   @i_tipo_cust          varchar(64) = null,
   @i_custodia           int         = null,
   @i_codigo_compuesto   varchar(64) = null
)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_error              int,
   @w_estado             catalogo,
   @w_des_est_custodia   descripcion,
   @w_valor_inicial      money,
   @w_moneda             tinyint,
   @w_valor_actual       money,
   @w_descripcion        varchar(255),			--descripcion, TRugel 04/30/08
   @w_des_moneda         descripcion,
   @w_fecha_ingreso      datetime,
   @w_cliente            int,
   @w_nombre_cliente     descripcion,
   @w_abierta_cerrada    char(1),
   @w_garante            int,
   @w_des_garante        descripcion,
   @w_estado_comp        descripcion,
   @w_moneda_comp        descripcion,
   @w_cliente_comp       descripcion,
   @w_garante_comp       descripcion,
   @w_ciudad             descripcion,  --MVI 07/11/96 mayor inf.
   @w_direccion          descripcion,
   @w_telefono           varchar(20),
   
   --IIcmendieta 2012/ene/04
   @w_cod_externo        varchar(64),
   @w_ins_valor_avaluo   money,
   @w_ins_fecha_insp     datetime,
   @w_ins_inspector      tinyint,
   @w_ins_nombre_ins     descripcion,
   
   @w_pol_valor_endoso         money,
   @w_pol_nom_asegura          descripcion,
   @w_pol_fec_emision_poliza   datetime,
   @w_pol_fec_caducidad_poliza datetime
   
   --FIcmendieta 2012/ene/04
   

select @w_today = convert(varchar(10),getdate(),101)
select @w_sp_name = 'sp_consult1'

/***********************************************************/
/* Codigos de Transacciones                                */

if (@t_trn <> 19455 and @i_operacion = 'Q') 
begin
/* tipo de transaccion no corresponde */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file, 
    @t_from  = @w_sp_name,
    @i_num   = 1901006
    return 1 
end
        if @i_codigo_compuesto <> null
        begin
           exec sp_compuesto
           @t_trn = 19245,
           @i_operacion = 'Q',
           @i_compuesto = @i_codigo_compuesto,
           @o_filial    = @i_filial out,
           @o_sucursal  = @i_sucursal out,
           @o_tipo      = @i_tipo_cust out,
           @o_custodia  = @i_custodia out
       end


if @i_operacion = 'Q'
begin
    select @w_estado            = cu_estado,
           @w_abierta_cerrada   = cu_abierta_cerrada,
           @w_descripcion       = cu_descripcion,
           @w_fecha_ingreso     = cu_fecha_ingreso,
           @w_valor_inicial     = cu_valor_inicial,
           @w_moneda            = cu_moneda,
           @w_valor_actual      = cu_valor_actual,
           @w_garante           = cu_garante,
           @w_ciudad            = cu_ciudad_prenda,
           @w_direccion         = cu_direccion_prenda,
           @w_telefono          = cu_telefono_prenda
      from cu_custodia
     where cu_filial   = @i_filial
       and cu_sucursal = @i_sucursal
       and cu_tipo     = @i_tipo_cust
       and cu_custodia = @i_custodia

    if @@rowcount > 0
       select @w_existe = 1
    else
       select @w_existe = 0 

    if @w_existe = 1
    begin

         select @w_des_est_custodia = A.valor
           from cobis..cl_catalogo A,cobis..cl_tabla B
           where B.codigo = A.tabla and
               B.tabla = 'cu_est_custodia' and
               A.codigo = @w_estado

         select @w_cliente = cg_ente,
                @w_nombre_cliente = cg_nombre,
                @w_cod_externo    = cg_codigo_externo  --cmendieta 2012/ene/04
           from cu_cliente_garantia
          where cg_filial     = @i_filial
            and cg_sucursal   = @i_sucursal
            and cg_tipo_cust  = @i_tipo_cust
            and cg_custodia   = @i_custodia 
            and cg_principal  = 'S'
      /*
         select @w_nombre_cliente = p_p_apellido+' '+p_s_apellido+' '+en_nombre
           from cobis..cl_ente
          where en_ente = @w_cliente
      */
      
           --II cmendieta 2012/ene/04
              --------------------------------------------------------
              --busca datos de inspección
              --------------------------------------------------------
	       select @w_ins_valor_avaluo = null,
	              @w_ins_fecha_insp   = null,
	              @w_ins_inspector    = null,
	              @w_ins_nombre_ins   = null

           
		select 
		       @w_ins_valor_avaluo = ins.in_valor_avaluo,
		       @w_ins_fecha_insp   = ins.in_fecha_insp,
		       @w_ins_inspector    = ins.in_inspector,
		       @w_ins_nombre_ins   = inp.is_nombre
		  from cob_custodia..cu_inspeccion ins,
		       cob_custodia..cu_inspector  inp 
		 where in_filial      = @i_filial
		   and in_sucursal    = @i_sucursal
		   and in_tipo_cust   = @i_tipo_cust
		   and in_custodia    = @i_custodia
		   --and ins.in_codigo_externo = '501200000000255'
		   --and in_estado
		   and ins.in_inspector      =  inp.is_inspector
		   
		   
		------------------------------------------------------
		--datos de poliza
		------------------------------------------------------
                select  @w_pol_nom_asegura = null,
	        	@w_pol_valor_endoso  = null,
	        	@w_pol_fec_emision_poliza  = null,
	        	@w_pol_fec_caducidad_poliza = null

 
		select 
		       @w_pol_nom_asegura =  (
			select ca.valor
			  from cobis..cl_tabla    ta,
			       cobis..cl_catalogo ca
			 where ta.tabla  = 'cu_des_aseguradora'
			   and ca.tabla  = ta.codigo
			   and ca.codigo = po.po_aseguradora 
		       ) ,
		       @w_pol_valor_endoso         = po.po_monto_endozo,
		       @w_pol_fec_emision_poliza   = po.po_fvigencia_inicio,
		       @w_pol_fec_caducidad_poliza = po.po_fvigencia_fin
		from cob_custodia..cu_poliza po
		where po.po_codigo_externo = @w_cod_externo 
		  and po.po_estado_poliza in ('V', 'P') 
		  and po_fecha_endozo = (select max(po_fecha_endozo) 
		  			   from cob_custodia..cu_poliza
		                          where po_codigo_externo = po.po_codigo_externo )
		order by po.po_fvigencia_inicio

           
           --FI cmendieta 2012/ene/04
           
           
           
         select @w_des_moneda = mo_descripcion
           from cobis..cl_moneda
           where mo_moneda = @w_moneda
         
         select @w_des_garante = p_p_apellido+' '+p_s_apellido+' '+en_nombre
           from cobis..cl_ente
           where en_ente = @w_garante 

         select @w_estado_comp=@w_estado + '   ' + @w_des_est_custodia,
           @w_moneda_comp=convert(varchar(2),@w_moneda)+'   '+@w_des_moneda,
           @w_cliente_comp=convert(varchar(10),@w_cliente)+'   '+@w_nombre_cliente,
           @w_garante_comp=convert(varchar(10),@w_garante)+'   '+@w_des_garante

         select 
              'ESTADO'            = @w_estado_comp,
              'ABIERTA/CERRADA'   = @w_abierta_cerrada,
              'FECHA INGRESO'     = convert(varchar(10),@w_fecha_ingreso,101),
              'CLIENTE'           = @w_cliente_comp,
              --II cmendieta 2012/ene/04
              --'VALOR INICIAL'     = @w_valor_inicial,
              --'VALOR ACTUAL'      = @w_valor_actual,   
              'VALOR COMERCIAL'      = @w_valor_inicial,
              'VALOR DE REALIZACION' = @w_valor_actual, 
              --FI cmendieta 2012/ene/04
              'MONEDA'            = @w_moneda_comp,
              'DESCRIPCION'       = @w_descripcion,
              'GARANTE'           = @w_garante_comp,
              'CIUDAD'            = @w_ciudad,  --MVI 07/11/96 mas inf.
              'DIRECCION'         = @w_direccion,
              'TELEFONO'          = @w_telefono,
              --II cmendieta 2012/ene/04
              ' ' = '',
              '**DATOS INSPECCION**' = '',
              'VALOR AVALUO ANTERIOR' = @w_ins_valor_avaluo ,
              'FECHA AVALUO VIGENTE'  = convert(char(10),@w_ins_fecha_insp,101),
	      'PERITO AVALUADOR       '  = @w_ins_nombre_ins   ,
	      '   ' = '',
	      '**DATOS POLIZA DE SEGURO**' = '',
              'ASEGURADORA     '    = @w_pol_nom_asegura ,
	      'VALOR ENDOSO    '    = @w_pol_valor_endoso,
	      'FECHA EMISION   '    = convert(char(10), @w_pol_fec_emision_poliza ,101),   
	      'FECHA CADUCIDAD '    = convert(char(10), @w_pol_fec_caducidad_poliza ,101)
	      
              --FI cmendieta 2012/ene/04
    end
    else
    begin
    /*Registro no existe 
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1901005 */
    return 1 
    end  
return 0
end
go