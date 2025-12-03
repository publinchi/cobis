/*caubcamia.sp***********************/
use cob_conta
go

if exists (select 1 from sysobjects where name = 'sp_causacion_bancamia')
   drop proc sp_causacion_bancamia
go

create procedure sp_causacion_bancamia
@i_fecha    datetime,
@i_forzar   char(1)    = 'N',
@i_cliente  int        = null

as 
/* GENERACION DE DATOS PARA AJUSTAR EL SALDO DE LOS CONCEPTOS QUE CAUSAN */

declare 
@w_cont      int,
@w_contador  int,
@w_oficina   smallint,
@w_contofi   int,
@w_rowcount  int,
@w_error     int

SET NOCOUNT ON


/* EL PROCESO SOLO SE CORRE LOS VIERNES, SI SE EJECUTA OTRO DIA SALE SIN HACER NADA */
if datepart(dw, @i_fecha) <> 6 and @i_forzar = 'N' return 0


create table #asientos_ajuste_p(
Numcomp1        int 		      not null, 
codempresa1     varchar(3) 	not null,
fecha_tran1     datetime      not null,
codofi_orig1    int           not null,
codar_orig1     int		      not null,
Descripcion1    varchar(60)	not null,
Codautomatico1  varchar(6)	   not null,
Estado1         varchar(1)	   not null,
codasiento1     int           identity,              -- PARA GENERAR EL NUMERO DE SECUENCIAL DEL COMPROBANTE
Codcta1         varchar(20)	not null,
Codofi_dest1    int		      not null,
Codar_dest1     int		      not null,
valorcred1      money         not null,
valordeb1       money         not null,
Concepto1       varchar(60)	not null,
Tipodoc1        varchar(1)	   not null,
Moneda1         int           not null,
Usuario1        varchar(20)	not null,
valorcred_me1   money		   not null,
valordeb_me1    money		   not null,
Cotizacion1     money		   not null,
tipotran_ban1   varchar(1)	   not null,
tipo_tercero1   varchar(5)	   not null,
id_tercero1     varchar(20)	not null,
Concepto_ret1   varchar(4)	   not null,
Base_ret1       money		   not null,
Documento1      varchar(12)	not null,
Oper_banco1     varchar(4)	   not null,
Referencia1     varchar(64)	not null,
Docum_planilla1 varchar(12)	not null,
ente            int           not null
)

create table #asientos(
Numcomp        int 		not null, 
codempresa     varchar(3) 	not null,
fecha_tran     datetime         not null,
codofi_orig    int		not null,
codar_orig     int		not null,
Descripcion    varchar(60)	not null,
Codautomatico  varchar(6)	not null,
Estado         varchar(1)	not null,
codasiento     int identity,              -- PARA GENERAR EL NUMERO DE SECUENCIAL DEL COMPROBANTE
Codcta         varchar(20)	not null,
Codofi_dest    int		not null,
Codar_dest     int		not null,
valorcred      money            not null,
valordeb       money            not null,
Concepto       varchar(60)	not null,
Tipodoc        varchar(1)	not null,
Moneda         int		not null,
Usuario        varchar(20)	not null,
valorcred_me   money		not null,
valordeb_me    money		not null,
Cotizacion     money		not null,
tipotran_ban   varchar(1)	not null,
tipo_tercero   varchar(5)	not null,
id_tercero     varchar(20)	not null,
Concepto_ret   varchar(4)	not null,
Base_ret       money		not null,
Documento      varchar(12)	not null,
Oper_banco     varchar(4)	not null,
Referencia     varchar(64)	not null,
Docum_planilla varchar(12)	not null,
ente           int              not null
)


create table #ajustes(
aj_cta_origen     varchar(24) not null,
aj_cta_destino    varchar(24) not null,
aj_deb_cred       char(1)     not null)



-- MICROCREDITO       



-- IMO

insert into #ajustes values ('16053200010','16053200010','D')

insert into #ajustes values ('16053200010','41021000010','C')



insert into #ajustes values ('16053400010','16053400010','D')

insert into #ajustes values ('16053400010','41021000010','C')



insert into #ajustes values ('16053600010','16053600010','D')

insert into #ajustes values ('16053600010','41021000010','C')



insert into #ajustes values ('16053800010','16053800010','D')

insert into #ajustes values ('16053800010','41021000010','C')



insert into #ajustes values ('16054000010','16054000010','D')

insert into #ajustes values ('16054000010','41021000010','C')



-- COMERCIAL          

-- IMO

insert into #ajustes values ('16054200010','16054200010','D')

insert into #ajustes values ('16054200010','41021000005','C')



insert into #ajustes values ('16054400010','16054400010','D')

insert into #ajustes values ('16054400010','41021000005','C')



insert into #ajustes values ('16054800010','16054800010','D')

insert into #ajustes values ('16054800010','41021000005','C')



insert into #ajustes values ('16054600010','16054600010','D')

insert into #ajustes values ('16054600010','41021000005','C')

 

-- MICROCREDITO          

-- INT

insert into #ajustes values ('16053200005','16053200005','D')

insert into #ajustes values ('16053200005','41020900005','C')



insert into #ajustes values ('16053400005','16053400005','D')

insert into #ajustes values ('16053400005','41020900005','C')



insert into #ajustes values ('16053600005','16053600005','D')

insert into #ajustes values ('16053600005','41020900005','C')



insert into #ajustes values ('16053800005','16053800005','D')

insert into #ajustes values ('16053800005','41020900005','C')



insert into #ajustes values ('16054000005','16054000005','D')

insert into #ajustes values ('16054000005','41020900005','C')



insert into #ajustes values ('16054200005','16054200005','D')                                                                                                                                                                                               
insert into #ajustes values ('16054200005','41020200005','C')




--COMERCIAL          

--INT

insert into #ajustes values ('16054400005','16054400005','D')

insert into #ajustes values ('16054400005','41020200005','C')



insert into #ajustes values ('16054800005','16054800005','D')

insert into #ajustes values ('16054800005','41020200005','C')



insert into #ajustes values ('16054600005','16054600005','D')

insert into #ajustes values ('16054600005','41020200005','C')



insert into #ajustes values ('16054900005','16054900005','D') 
insert into #ajustes values ('16054900005','41020200005','C')



insert into #ajustes values ('16054900010','16054900010','D') 
insert into #ajustes values ('16054900010','41021000010','C')


-- SEGDEUVEN

insert into #ajustes values ('16380500105','16380500105','D')

insert into #ajustes values ('16380500105','25957000005','C')      



insert into #ajustes values ('16381000105','16381000105','D')

insert into #ajustes values ('16381000105','25957000005','C')     



insert into #ajustes values ('16381500105','16381500105','D')

insert into #ajustes values ('16381500105','25957000005','C')     



insert into #ajustes values ('16382000105','16382000105','D')

insert into #ajustes values ('16382000105','25957000005','C')



insert into #ajustes values ('16382500105','16382500105','D')

insert into #ajustes values ('16382500105','25957000005','C')      



insert into #ajustes values ('16390500105','16390500105','D')

insert into #ajustes values ('16390500105','25957000005','C')



insert into #ajustes values ('16391000105','16391000105','D')

insert into #ajustes values ('16391000105','25957000005','C')      



insert into #ajustes values ('16392000105','16392000105','D')

insert into #ajustes values ('16392000105','25957000005','C') 



insert into #ajustes values ('16392500105','16392500105','D') 
insert into #ajustes values ('16392500105','25957000005','C') 



insert into #ajustes values ('16391500105','16391500105','D')

insert into #ajustes values ('16391500105','25957000005','C')



-- INT

insert into #ajustes values ('64304000005','64304000005','D')

insert into #ajustes values ('64304000005','63301900005','C')



insert into #ajustes values ('64304200005','64304200005','D')

insert into #ajustes values ('64304200005','63301900005','C')



insert into #ajustes values ('64304400005','64304400005','D')

insert into #ajustes values ('64304400005','63301900005','C')          



insert into #ajustes values ('64304600005','64304600005','D')

insert into #ajustes values ('64304600005','63301900005','C')         



insert into #ajustes values ('64304800005','64304800005','D')

insert into #ajustes values ('64304800005','63301900005','C')          



insert into #ajustes values ('64305200005','64305200005','D')

insert into #ajustes values ('64305200005','63300500005','C')          



insert into #ajustes values ('64305600005','64305600005','D')

insert into #ajustes values ('64305600005','63300500005','C')



insert into #ajustes values ('64305000005','64305000005','D')

insert into #ajustes values ('64305000005','63300500005','C')



insert into #ajustes values ('64305400005','64305400005','D')

insert into #ajustes values ('64305400005','63300500005','C')



insert into #ajustes values ('64305800005','64305800005','D') 
insert into #ajustes values ('64305800005','63300500005','C')



 

-- IMO

insert into #ajustes values ('64304000010','64304000010','D')

insert into #ajustes values ('64304000010','63301900010','C')         



insert into #ajustes values ('64304200010','64304200010','D')

insert into #ajustes values ('64304200010','63301900010','C')          



insert into #ajustes values ('64304400010','64304400010','D')

insert into #ajustes values ('64304400010','63301900010','C')          



insert into #ajustes values ('64304600010','64304600010','D')

insert into #ajustes values ('64304600010','63301900010','C')          



insert into #ajustes values ('64304800010','64304800010','D')

insert into #ajustes values ('64304800010','63301900010','C')



insert into #ajustes values ('64305200010','64305200010','D')

insert into #ajustes values ('64305200010','63300500010','C')          



insert into #ajustes values ('64305600010','64305600010','D')

insert into #ajustes values ('64305600010','63300500010','C')



insert into #ajustes values ('64305000010','64305000010','D')

insert into #ajustes values ('64305000010','63300500010','C')



insert into #ajustes values ('64305400010','64305400010','D')

insert into #ajustes values ('64305400010','63300500010','C')



insert into #ajustes values ('64305800010','64305800010','D') 
insert into #ajustes values ('64305800010','63300500010','C')





-- IVAMIPYMES (solo la parte de debito)



insert into #ajustes values ('16109500005','16109500005','D')



-- CAUSACCION DE CASTIGOS



insert into #ajustes values ('81201500005','81201500005','D')

insert into #ajustes values ('81201500005','83050000005','C')

     

insert into #ajustes values ('81201500010','81201500010','D')

insert into #ajustes values ('81201500010','83050000005','C')

     

insert into #ajustes values ('81201500015','81201500015','D')

insert into #ajustes values ('81201500015','83050000005','C')

 

insert into #ajustes values ('81201500020','81201500020','D')

insert into #ajustes values ('81201500020','83050000005','C')

     

insert into #ajustes values ('81201500025','81201500025','D')

insert into #ajustes values ('81201500025','83050000005','C')



insert into #ajustes values ('81201000005','81201000005','D')
insert into #ajustes values ('81201000005','83050000005','C')
                                                                                                                                                                                                
insert into #ajustes values ('81201000010','81201000010','D')
insert into #ajustes values ('81201000010','83050000005','C')



--CUPOS DE CREDITO



insert into #ajustes values ('62250500010','61250500010','C')

insert into #ajustes values ('62250500010','62250500010','D')


--APROBADOS NO DESEMBOLSADOS

insert into #ajustes values ('62200000010','61200500010','C')
insert into #ajustes values ('62200000010','62200000010','D')



insert into #asientos
select 
Numcomp        = 1, /* REVISAR */
codempresa     = '001',
fecha_tran     = @i_fecha,
codofi_orig    = bo_oficina,
codar_orig     = 31,
Descripcion    = '  ',
Codautomatico  = '000000',
Estado         = ' ',                                                                                                                                  
--codasiento     = 0,  /* PENDIENTE */
Codcta         = aj_cta_destino,
Codofi_dest    = bo_oficina,
Codar_dest     = 31,
valorcred      = case when aj_deb_cred = 'C' and bo_diferencia > 0 then bo_diferencia when aj_deb_cred = 'D' and bo_diferencia < 0 then abs(bo_diferencia) else 0 end,
valordeb       = case when aj_deb_cred = 'D' and bo_diferencia > 0 then bo_diferencia when aj_deb_cred = 'C' and bo_diferencia < 0 then abs(bo_diferencia) else 0 end,
Concepto       = '   ',
Tipodoc        = 'N', -- NORMAL
Moneda         = 0,
Usuario        = 'consola',
valorcred_me   = 0,
valordeb_me    = 0,
Cotizacion     = 0,
tipotran_ban   = ' ',
tipo_tercero   = '',
id_tercero     = '',
Concepto_ret   = '', /* REVISAR */
Base_ret       = 0, /* REVISAR */
Documento      = '', /* REVISAR */
Oper_banco     = '', /* REVISAR */
Referencia     = '', /* REVISAR */
Docum_planilla = '', /* REVISAR */
ente           = bo_cliente
from cb_boc,#ajustes
where bo_diferencia <> 0
and   bo_cuenta     =  aj_cta_origen
and   bo_cliente    =  isnull(@i_cliente,bo_cliente)
and   bo_producto   = 200
order by bo_oficina,bo_cliente,aj_cta_origen


-- IVAMIPYMES (contrapartida por el 16% de la parte de debito)
delete #ajustes
insert into #ajustes values ('16109500005','25350000005','C')

insert into #asientos
select 
Numcomp        = 1, /* REVISAR */
codempresa     = '001',
fecha_tran     = @i_fecha,
codofi_orig    = bo_oficina,
codar_orig     = 31,
Descripcion    = '  ',
Codautomatico  = '000000',
Estado         = ' ',
--codasiento     = 0,  /* PENDIENTE */
Codcta         = aj_cta_destino,
Codofi_dest    = bo_oficina,
Codar_dest     = 31,
valorcred      = case when aj_deb_cred = 'C' and ((bo_diferencia*16)/116.0) > 0 then ((bo_diferencia*16)/116.0) when aj_deb_cred = 'D' and ((bo_diferencia*16)/116.0) < 0 then abs(((bo_diferencia*16)/116.0)) else 0 end,
valordeb       = case when aj_deb_cred = 'D' and ((bo_diferencia*16)/116.0) > 0 then ((bo_diferencia*16)/116.0) when aj_deb_cred = 'C' and ((bo_diferencia*16)/116.0) < 0 then abs(((bo_diferencia*16)/116.0)) else 0 end,
Concepto       = '   ',
Tipodoc        = 'N', -- NORMAL
Moneda         = 0,
Usuario        = 'consola',
valorcred_me   = 0,
valordeb_me    = 0,
Cotizacion     = 0,
tipotran_ban   = ' ',
tipo_tercero   = '',
id_tercero     = '',
Concepto_ret   = '0281', /* REVISAR */
Base_ret       = ((bo_diferencia*100)/116.0), /* REVISAR */
Documento      = '', /* REVISAR */
Oper_banco     = '', /* REVISAR */
Referencia     = '', /* REVISAR */
Docum_planilla = '', /* REVISAR */
ente           = bo_cliente
from cb_boc, #ajustes
where bo_diferencia <> 0
and   bo_cuenta     =  aj_cta_origen
and   bo_cliente    =  isnull(@i_cliente,bo_cliente)
and   bo_producto   = 200
order by bo_oficina,bo_cliente,aj_cta_origen

delete #ajustes

-- MPYMES (contrapartida por el 84% de la parte de debito)
insert into #ajustes values ('16109500005','41159500005','C')

insert into #asientos
select 
Numcomp        = 1, /* REVISAR */
codempresa     = '001',
fecha_tran     = @i_fecha,
codofi_orig    = bo_oficina,
codar_orig     = 31,
Descripcion    = '  ',
Codautomatico  = '000000',
Estado         = ' ',
--codasiento     = 0,  /* PENDIENTE */
Codcta         = aj_cta_destino,
Codofi_dest    = bo_oficina,
Codar_dest     = 31,
valorcred      = case when aj_deb_cred = 'C' and ((bo_diferencia*100)/116.0) > 0 then ((bo_diferencia*100)/116.0) when aj_deb_cred = 'D' and ((bo_diferencia*100)/116.0) < 0 then abs(((bo_diferencia*100)/116.0)) else 0 end,
valordeb       = case when aj_deb_cred = 'D' and ((bo_diferencia*100)/116.0) > 0 then ((bo_diferencia*100)/116.0) when aj_deb_cred = 'C' and ((bo_diferencia*100)/116.0) < 0 then abs(((bo_diferencia*100)/116.0)) else 0 end,
Concepto       = '   ',
Tipodoc        = 'N', -- NORMAL
Moneda         = 0,
Usuario        = 'consola',
valorcred_me   = 0,
valordeb_me    = 0,
Cotizacion     = 0,
tipotran_ban   = ' ',
tipo_tercero   = '',
id_tercero     = '',
Concepto_ret   = '', /* REVISAR */
Base_ret       = 0, /* REVISAR */
Documento      = '', /* REVISAR */
Oper_banco     = '', /* REVISAR */
Referencia     = '', /* REVISAR */
Docum_planilla = '', /* REVISAR */
ente           = bo_cliente
from cb_boc, #ajustes
where bo_diferencia <> 0
and   bo_cuenta     =  aj_cta_origen
and   bo_cliente    =  isnull(@i_cliente,bo_cliente)
and   bo_producto   = 200
order by bo_oficina,bo_cliente,aj_cta_origen

insert into #asientos_ajuste_p
select 
Numcomp1 	    = Numcomp, 
codempresa1	    = codempresa,
fecha_tran1	    = fecha_tran,
codofi_orig1	 = codofi_orig,
codar_orig1	    = codar_orig,
Descripcion1	 = Descripcion,
Codautomatico1	 = Codautomatico,
Estado1         = Estado,
Codcta1         = Codcta,
Codofi_dest1	 = Codofi_dest,
Codar_dest1     = Codar_dest,
valorcred1      = 0,
valordeb1       = sum(isnull(valordeb,0)-isnull(valorcred,0)),
Concepto1       = Concepto,
Tipodoc1        = Tipodoc,
Moneda1         = Moneda,
Usuario1        = Usuario,
valorcred_me1	 = valorcred_me,
valordeb_me1    = valordeb_me,	
Cotizacion1	    = Cotizacion,
tipotran_ban1	 = tipotran_ban,
tipo_tercero1	 = tipo_tercero,
id_tercero1	    = id_tercero,
Concepto_ret1	 = Concepto_ret,
Base_ret1	    = Base_ret,
Documento1	    = Documento,
Oper_banco1	    = Oper_banco,
Referencia1	    = Referencia,
Docum_planilla1 = Docum_planilla,
ente            = ente
from #asientos
where valorcred > 0 or valordeb > 0
group by
Numcomp,           codempresa,        fecha_tran,
codofi_orig,       codar_orig,        Descripcion,
Codautomatico,     Estado,            Codcta,
Codofi_dest,       Codar_dest,
Concepto,          Tipodoc,           Moneda,
Usuario,           valorcred_me,      valordeb_me,
Cotizacion,        tipotran_ban,      tipo_tercero,
id_tercero,        Concepto_ret,      Base_ret,
Documento,         Oper_banco,        Referencia,
Docum_planilla,    ente
having abs(sum(isnull(valordeb,0)-isnull(valorcred,0))) <> 0

/* NUMERAR COMPROBANTES POR OFICINA */
create table #oficinas(
   id   int identity,
   ofi  int
)

insert into #oficinas
select distinct codofi_orig1
from #asientos_ajuste_p
order by codofi_orig1


update #asientos_ajuste_p set
Numcomp1 = id
from #oficinas
where codofi_orig1 = ofi


/* INSERTAR ASIENTOS GENERADOS EN TABLA DE INTERFAZ NOCOBIS - COB_CONTA */

truncate table cob_conta..cb_convivencia_tmp

select @w_cont = 0

while 1 = 1 begin	
    select @w_cont = @w_cont + 1
    
    insert into cob_conta..cb_convivencia_tmp
    select
    Numcomp1,       
    codempresa1,    
    fecha_tran1,    
    codofi_orig1,   
    codar_orig1,    
    'COMPROBANTE AUT AJUSTE CAUSACION',
    Codautomatico1, 
    Estado1,        
    row_number() over(order by Numcomp1),
    Codcta1,        
    Codofi_dest1,   
    Codar_dest1,
    case when valordeb1 < 0 then abs(valordeb1) else 0 end,
    case when valordeb1 > 0 then     valordeb1  else 0 end,
    'ASIENTO AUT COMPROBANTE AJUSTE CAUSACION',
    Tipodoc1,       
    Moneda1,        
    Usuario1,       
    valorcred_me1,  
    valordeb_me1,   
    Cotizacion1,    
    tipotran_ban1,  
    tipo_tercero1  = en_tipo_ced,  
    id_tercero1    = en_ced_ruc,    
    Concepto_ret1,  
    Base_ret1,      
    Documento1,     
    Oper_banco1,    
    Referencia1,    
    Docum_planilla1
    from #asientos_ajuste_p, cobis..cl_ente
    where Numcomp1 = @w_cont
    and   en_ente  = ente

    select 
    @w_rowcount = @@rowcount,
    @w_error    = @@error
    
    if @w_error <> 0  print 'Error en insercion en tabla cb_convivencia_tmp'    
    if @w_rowcount = 0 break    
end

go

/* PRUEBA

select getdate()
declare @w_error int

exec @w_error = sp_causacion_bancamia
@i_fecha = '11/30/2008'

select @w_error

select getdate()

*/
