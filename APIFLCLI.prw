#Include "TOTVS.ch"    
#include "Topconn.ch"  
#include "RESTFUL.CH"

//API PARA CONSULTAR CLIENTES
//DESENVOLVIDO POR JOAO HENRIQUE
//TMJ

WSRESTFUL CONSULTARCLIENTE DESCRIPTION "Consultar clientes" FORMAT APPLICATION_JSON
WSDATA codCliente	     AS CHARACTER OPTIONAL
WSDATA nomeCliente       AS CHARACTER OPTIONAL

WSMETHOD GET ConsultaCliente;
	DESCRIPTION "API utilizada para efetuar a consulta de clientes";
	WSSYNTAX "/consultacliente/?{codCliente}&{nomeCliente}";
	PATH "/consultacliente/";
	TTALK "ConsultaCliente";
	PRODUCES APPLICATION_JSON

WSMETHOD POST InserirCliente;
	DESCRIPTION "API utilizada para efetuar a inserção dos clientes";
	WSSYNTAX "/inserircliente/?{dados}";
	PATH "/inserircliente/";
	TTALK "InserirCliente";
	PRODUCES APPLICATION_JSON   

WSMETHOD DELETE DeletarCliente;
   DESCRIPTION "API utilizada para deletar cliente indicado";
   WSSYNTAX "/deletarcliente/?{dados}";
   PATH "/deletarcliente/";
   TTALK "DeletarCliente";
   PRODUCES APPLICATION_JSON 

END WSRESTFUL

WSMETHOD GET ConsultaCliente HEADERPARAM codCliente, nomeCliente WSSERVICE CONSULTARCLIENTE

Local oResponse	    :=	Nil
Local aResponse	    :=	{}
Local oForn
Local lRet			:=	.T.
Local cCodCliente   := ""
Local cNomeCliente  := ""
Local cQuery        := ""
Local cAlias    

If ValType( self:codCliente  ) == "C" .and. !Empty( self:codCliente  )
   cCodCliente := cValToChar(self:codCliente)
   // cCodCliente := PADL(cValToChar(self:codCliente),TAMSX3("A1_COD")[1],"0")
EndIf

If ValType( self:nomeCliente  ) == "C" .and. !Empty( self:nomeCliente  )
   cNomeCliente := Upper(cValToChar(self:nomeCliente))
EndIf

cQuery := " SELECT * "+CRLF
cQuery += "	FROM " + RetSqlTab("SA1")+CRLF 
cQuery += " WHERE 1=1 "+CRLF
cQuery += " AND "+RetSqlDel("SA1")+CRLF
cQuery += " AND "+RetSqlFil("SA1")+CRLF
if !empty(cCodCliente)
cQuery += " AND A1_COD LIKE '%"+cCodCliente+"'"+CRLF
endif
if !empty(cNomeCliente)
cQuery += " AND A1_NOME LIKE '"+cNomeCliente+"%'"+CRLF
endif
cQuery += " ORDER BY A1_NOME "

conout("testapi: "+ cQuery)

TcQuery cQuery New Alias (cAlias := GetNextAlias())
DbSelectArea(cAlias)

(cAlias)->(DbGoTop())

IF (cAlias)->(EOF())
   (cAlias)->(DbcloseArea())
   oResponse := JsonObject():New()
   oResponse["consultarResultado"]	:= {}
   self:SetResponse( oResponse:ToJson() )
   FreeObj( oResponse )
   oResponse := Nil
   Return( lRet )
ELSE
   While (cAlias)->(!EoF())
         
      oForn  := nil
      oForn  := JsonObject():New()
      oForn["codigoCliente"]           := (cAlias)->A1_COD
      oForn["lojaCliente"]             := (cAlias)->A1_LOJA
      oForn["cpfCliente"]              := (cAlias)->A1_CGC
      oForn["nomeCliente"]             := AllTrim((cAlias)->A1_NOME)
      oForn["nomeFantasia"]            := AllTrim((cAlias)->A1_NREDUZ)
      oForn["endereco"]                := AllTrim((cAlias)->A1_END)
      oForn["cep"]                     := (cAlias)->A1_CEP
      oForn["bairro"]                  := AllTrim((cAlias)->A1_BAIRRO)
      oForn["estado"]                  := (cAlias)->A1_EST
      oForn["municipio"]               := (cAlias)->A1_MUN
      oForn["ibge"]                    := (calias)->A1_IBGE
      oForn["endcobranca"]             := (calias)->A1_ENDCOB
      oForn["ccontabil"]               := (calias)->A1_CONTA
      oForn["banco1"]                  := (calias)->A1_BCO1
      oForn["telefone"]                := (calias)->A1_TEL
      oForn["nomeContato"]             := (calias)->A1_CONTATO

      

      aadd(aResponse,oForn)

      (cAlias)->(dbskip())
   Enddo 
   (cAlias)->(DbcloseArea())
     
    oResponse := JsonObject():New()
    oResponse["consultarResultado"]	:= aResponse
    self:SetResponse( EncodeUTF8(oResponse:ToJson()) )
ENDIF

FreeObj( oResponse )
oResponse := Nil

Return( lRet )

WSMETHOD POST InserirCliente WSRECEIVE RECEIVE WSSERVICE CONSULTARCLIENTE

   Local cJSON := Self:GetContent() // Pega a string do JSON
   Local oParseJSON := JsonObject():new()
   Local aDadosCli := {} //–> Array para ExecAuto do MATA030
   Local cJsonRet := ""
   Local cArqLog := ""
   Local cErro := ""
   Local lRet := .T.

   Private lMsErroAuto := .F.
   Private lMsHelpAuto := .F.

   // –> Cria o diretório para salvar os arquivos de log

   If !ExistDir("\log_cli")
      MakeDir("\log_cli")
   EndIf

   // –> Deserializa a string JSON
   
   oParseJSON:fromJson(FwNoAccent(cJSON))

   SA1->( DbSetOrder(1) )
   If !(SA1->( DbSeek( xFilial("SA1") + oParseJSON['codigoCliente'] + oParseJSON['lojaCliente'] )))
      Aadd(aDadosCli, {"A1_FILIAL"           , xFilial("SA1")              , Nil}) // Obrigatorios v
      Aadd(aDadosCli, {"A1_COD"              , oParseJSON['codigoCliente']    , Nil})
      Aadd(aDadosCli, {"A1_LOJA"             , oParseJSON['lojaCliente']      , Nil})
      Aadd(aDadosCli, {"A1_NOME"             , oParseJSON['nomeCliente']      , Nil})
      Aadd(aDadosCli, {"A1_NREDUZ"           , oParseJSON['nomeFantasia']     , Nil})
      Aadd(aDadosCli, {"A1_TIPO"             , "F"                         , Nil}) //Cons. Final
      Aadd(aDadosCli, {"A1_END"              , oParseJSON['endereco']         , Nil})
      Aadd(aDadosCli, {"A1_CEP"              , oParseJSON['cep']              , Nil})
      Aadd(aDadosCli, {"A1_EST"              , oParseJSON['estado']           , Nil})
      Aadd(aDadosCli, {"A1_MUN"              , oParseJSON['municipio']        , Nil})
      Aadd(aDadosCli, {"A1_TEL"              , oParseJSON['telefone']         , Nil})
      // Valida os campos que nao sao obrigatorios
      If oParseJSON:GetJsonObject('cpfCliente') != Nil
         Aadd(aDadosCli, {"A1_CGC"              , oParseJSON['cpfCliente']       , Nil})
         Aadd(aDadosCli, {"A1_PESSOA"           , Iif(Len(oParseJSON['cpfCliente'])== 11, "F", "J") , Nil} )
      EndIf
      If oParseJSON:GetJsonObject('bairro') != Nil
         Aadd(aDadosCli, {"A1_BAIRRO"           , oParseJSON['bairro']           , Nil}) 
      EndIF
      If oParseJSON:GetJsonObject('ibge') != Nil
         Aadd(aDadosCli, {"A1_IBGE"             , oParseJSON['ibge']             , Nil}) 
      EndIf
      If oParseJSON:GetJsonObject('nomeContato') != Nil
         Aadd(aDadosCli, {"A1_CONTATO"          , oParseJSON['nomeContato']      , Nil}) 
      EndIf

      MsExecAuto({|x,y| MATA030(x,y)}, aDadosCli, 3)

      If lMsErroAuto
         cArqLog := oParseJSON['codigoCliente'] + " - " +SubStr(Time(),1,5 ) + ".log"
         RollBackSX8()
         cErro := MostraErro("\log_cli", cArqLog)
         SetRestFault(415, cErro)
         lRet := .F.
      Else
         ConfirmSX8()
         cJSONRet := '{"cod_cli":"' + SA1->A1_COD + '"';
         + ',"loja”:"' + SA1->A1_LOJA + '"';
         + ',"msg":"' + "Sucesso" + '"';
         +'}'
         ::SetResponse( cJSONRet )
      EndIf
   Else
      SetRestFault(400, "Cliente já cadastrado: " + SA1->A1_COD + " - " + SA1->A1_LOJA)
      lRet := .F.
   EndIf

Return(lRet)

WSMETHOD DELETE DeletarCliente WSSERVICE CONSULTARCLIENTE

   Local lRet  := .T.
   Local cliente := Self:GetContent()

   conout(cliente+CRLF+CRLF+CRLF+CRLF+CRLF+CRLF+CRLF+CRLF+CRLF+CRLF)
   

Return lRet
