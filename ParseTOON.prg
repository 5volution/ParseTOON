// Classe TToon - Manipulador de Arquivos TOON para Clipper 5.0
// Versão 1.0.0
// Autor: José Carlos da Rocha - 5Volution Desenvolvimento
// Data: 2024

#include "inkey.ch"
#include "fileio.ch"

// Definição da classe principal
CLASS TToon
    DATA  cFileName // Nome do arquivo TOON
    DATA  aData // Array com dados carregados
    DATA  aStructure // Estrutura dos dados
    DATA  nCurrentLine // Linha atual
    DATA  lModified // Flag de modificação
    DATA  cVersion // Versão da classe

    // Métodos principais
    METHOD New(cFile)           // Construtor
    METHOD Load()               // Carregar arquivo TOON
    METHOD Save()               // Salvar arquivo TOON
    METHOD SaveAs(cNewFile)     // Salvar como novo arquivo

    // Métodos de manipulação
    METHOD Add(cKey, xValue, cParentKey)  // Adicionar elemento
    METHOD Delete(cKey, cParentKey)       // Excluir elemento
    METHOD Update(cKey, xValue, cParentKey) // Atualizar elemento
    METHOD Find(cKey, cParentKey)         // Buscar elemento
    METHOD Get(cKey, cParentKey)          // Obter valor
    METHOD Count(cParentKey)              // Contar elementos

    // Métodos de exportação
    METHOD ToCSV(cOutputFile)             // Exportar para CSV
    METHOD ToJSON(cOutputFile)            // Exportar para JSON

    // Métodos de importação
    METHOD FromCSV(cInputFile, lAppend)   // Importar de CSV
    METHOD FromJSON(cInputFile, lAppend)  // Importar de JSON

    // Métodos auxiliares
    METHOD Reset()                        // Resetar dados
    METHOD Display()                      // Exibir dados
    METHOD GetStructure()                 // Obter estrutura
    METHOD Validate()                     // Validar dados

    // Métodos privados
    HIDDEN:
    METHOD ParseToonLine(cLine)           // Analisar linha TOON
    METHOD BuildToonLine(aElement)        // Construir linha TOON
    METHOD FindElement(cKey, cParentKey)  // Encontrar elemento
    METHOD AddToStructure(aElement)       // Adicionar à estrutura
ENDCLASS

//---------------------------------------------------------------------------
// Construtor da classe
//---------------------------------------------------------------------------
METHOD New(cFile) CLASS TToon
    LOCAL self := SELF

    // Inicializar propriedades
    ::cFileName := IF(cFile != NIL, cFile, "")
    ::aData := {}
    ::aStructure := {}
    ::nCurrentLine := 0
    ::lModified := .F.
    ::cVersion := "1.0.0"

    // Se arquivo fornecido, carregar automaticamente
    IF !EMPTY(::cFileName) .AND. FILE(::cFileName)
        ::Load()
    ENDIF
RETURN self

//---------------------------------------------------------------------------
// Carregar arquivo TOON
//---------------------------------------------------------------------------
METHOD Load() CLASS TToon
    LOCAL nHandle, cLine, aElement, nLineCount := 0

    // Verificar se arquivo existe
    IF !FILE(::cFileName)
        ? "ERRO: Arquivo " + ::cFileName + " não encontrado."
        RETURN .F.
    ENDIF

    // Abrir arquivo
    nHandle := FOPEN(::cFileName, FO_READ)
    IF nHandle == -1
        ? "ERRO: Não foi possível abrir o arquivo."
        RETURN .F.
    ENDIF

    // Limpar dados existentes
    ::aData := {}
    ::aStructure := {}

    // Ler arquivo linha por linha
    DO WHILE !FEOF(nHandle)
        cLine := FREADLN(nHandle)
        nLineCount++
    
        // Ignorar linhas vazias e comentários
        IF !EMPTY(ALLTRIM(cLine)) .AND. LEFT(ALLTRIM(cLine), 1) != "#"
            aElement := ::ParseToonLine(cLine)
            IF aElement != NIL
                AADD(::aData, aElement)
                ::AddToStructure(aElement)
            ENDIF
        ENDIF
    ENDDO

    FCLOSE(nHandle)

    ? "Arquivo " + ::cFileName + " carregado com sucesso."
    ? "Total de elementos: " + LTRIM(STR(LEN(::aData)))

    ::lModified := .F.
RETURN .T.

//---------------------------------------------------------------------------
// Salvar arquivo TOON
//---------------------------------------------------------------------------
METHOD Save() CLASS TToon
    LOCAL nHandle, i, cLine

    // Se não há modificações, não salvar
    IF !::lModified
        ? "Nenhuma modificação para salvar."
        RETURN .T.
    ENDIF

    // Abrir arquivo para escrita
    nHandle := FCREATE(::cFileName)
    IF nHandle == -1
        ? "ERRO: Não foi possível criar o arquivo."
        RETURN .F.
    ENDIF

    // Escrever cabeçalho
    FWRITE(nHandle, "# Arquivo TOON - Gerado por TToon Class v" + ::cVersion + hb_eol())
    FWRITE(nHandle, "# Desenvolvido por José Carlos da Rocha - 5Volution Desenvolvimento" + hb_eol())
    FWRITE(nHandle, "# Data: " + DTOC(DATE()) + " Hora: " + TIME() + hb_eol() + hb_eol())

    // Escrever dados
    FOR i := 1 TO LEN(::aData)
        cLine := ::BuildToonLine(::aData[i])
        FWRITE(nHandle, cLine + hb_eol())
    NEXT

    FCLOSE(nHandle)

    ? "Arquivo " + ::cFileName + " salvo com sucesso."
    ::lModified := .F.
RETURN .T.

//---------------------------------------------------------------------------
// Salvar como novo arquivo
//---------------------------------------------------------------------------
METHOD SaveAs(cNewFile) CLASS TToon
    LOCAL cOldFile := ::cFileName

    ::cFileName := cNewFile
    IF ::Save()
        ::cFileName := cOldFile
        RETURN .T.
    ELSE
        ::cFileName := cOldFile
        RETURN .F.
    ENDIF
RETURN .T.

//---------------------------------------------------------------------------
// Adicionar elemento
//---------------------------------------------------------------------------
METHOD Add(cKey, xValue, cParentKey) CLASS TToon
    LOCAL aElement, nIndex

    // Validar parâmetros
    IF EMPTY(cKey) .OR. xValue == NIL
        ? "ERRO: Chave e valor são obrigatórios."
        RETURN .F.
    ENDIF

    // Verificar se chave já existe
    IF ::Find(cKey, cParentKey) > 0
        ? "ERRO: Chave '" + cKey + "' já existe."
        RETURN .F.
    ENDIF

    // Criar novo elemento
    aElement := Array(4)
    aElement[1] := cKey                     // Chave
    aElement[2] := xValue                   // Valor
    aElement[3] := IF(cParentKey != NIL, cParentKey, "")  // Chave pai
    aElement[4] := DATE()                   // Data de criação

    // Adicionar ao array de dados
    AADD(::aData, aElement)
    ::AddToStructure(aElement)

    ::lModified := .T.

    ? "Elemento '" + cKey + "' adicionado com sucesso."

    // Se for filho, atualizar estrutura do pai
    IF !EMPTY(cParentKey)
        ? "  Pai: " + cParentKey
    ENDIF
RETURN .T.

//---------------------------------------------------------------------------
// Excluir elemento
//---------------------------------------------------------------------------
METHOD Delete(cKey, cParentKey) CLASS TToon
    LOCAL nIndex, i, aNewData := {}

    // Encontrar elemento
    nIndex := ::Find(cKey, cParentKey)

    IF nIndex == 0
        ? "ERRO: Elemento '" + cKey + "' não encontrado."
        RETURN .F.
    ENDIF

    // Verificar se tem filhos
    FOR i := 1 TO LEN(::aData)
        IF ::aData[i][3] == cKey
            ? "AVISO: Elemento '" + cKey + "' possui filhos. Exclua-os primeiro."
            RETURN .F.
        ENDIF
    NEXT

    // Remover elemento
    FOR i := 1 TO LEN(::aData)
        IF i != nIndex
            AADD(aNewData, ::aData[i])
        ENDIF
    NEXT

    ::aData := aNewData
    ::lModified := .T.

    ? "Elemento '" + cKey + "' excluído com sucesso."
RETURN .T.

//---------------------------------------------------------------------------
// Atualizar elemento
//---------------------------------------------------------------------------
METHOD Update(cKey, xValue, cParentKey) CLASS TToon
    LOCAL nIndex

    // Encontrar elemento
    nIndex := ::Find(cKey, cParentKey)

    IF nIndex == 0
        ? "ERRO: Elemento '" + cKey + "' não encontrado."
        RETURN .F.
    ENDIF

    // Atualizar valor
    ::aData[nIndex][2] := xValue
    ::lModified := .T.

    ? "Elemento '" + cKey + "' atualizado com sucesso."
RETURN .T.

//---------------------------------------------------------------------------
// Buscar elemento
//---------------------------------------------------------------------------
METHOD Find(cKey, cParentKey) CLASS TToon
    LOCAL i

    FOR i := 1 TO LEN(::aData)
        IF ::aData[i][1] == cKey .AND. ;
           (EMPTY(cParentKey) .OR. ::aData[i][3] == cParentKey)
            RETURN i
        ENDIF
    NEXT
RETURN 0

//---------------------------------------------------------------------------
// Obter valor do elemento
//---------------------------------------------------------------------------
METHOD Get(cKey, cParentKey) CLASS TToon
    LOCAL nIndex

    nIndex := ::Find(cKey, cParentKey)

    IF nIndex > 0
        RETURN ::aData[nIndex][2]
    ENDIF
RETURN NIL

//---------------------------------------------------------------------------
// Contar elementos
//---------------------------------------------------------------------------
METHOD Count(cParentKey) CLASS TToon
    LOCAL i, nCount := 0

    FOR i := 1 TO LEN(::aData)
        IF EMPTY(cParentKey) .OR. ::aData[i][3] == cParentKey
            nCount++
        ENDIF
    NEXT
RETURN nCount

//---------------------------------------------------------------------------
// Exportar para CSV
//---------------------------------------------------------------------------
METHOD ToCSV(cOutputFile) CLASS TToon
    LOCAL nHandle, i, cLine

    // Abrir arquivo para escrita
    nHandle := FCREATE(cOutputFile)
    IF nHandle == -1
        ? "ERRO: Não foi possível criar o arquivo CSV."
        RETURN .F.
    ENDIF

    // Escrever cabeçalho
    FWRITE(nHandle, "Chave,Valor,ChavePai,DataCriacao" + hb_eol())

    // Escrever dados
    FOR i := 1 TO LEN(::aData)
        cLine := ::aData[i][1] + "," + ;
             ALLTRIM(STR(::aData[i][2])) + "," + ;
             ::aData[i][3] + "," + ;
             DTOC(::aData[i][4])
        FWRITE(nHandle, cLine + hb_eol())
    NEXT

    FCLOSE(nHandle)

    ? "Arquivo CSV exportado com sucesso: " + cOutputFile
RETURN .T.

//---------------------------------------------------------------------------
// Exportar para JSON
//---------------------------------------------------------------------------
METHOD ToJSON(cOutputFile) CLASS TToon
    LOCAL nHandle, i, cLine, cJSON := "{"

    // Abrir arquivo para escrita
    nHandle := FCREATE(cOutputFile)
    IF nHandle == -1
        ? "ERRO: Não foi possível criar o arquivo JSON."
        RETURN .F.
    ENDIF

    // Construir JSON
    cJSON += hb_eol() + '  "metadata": {' + hb_eol() + ;
         '    "gerador": "TToon Class v' + ::cVersion + '",' + hb_eol() + ;
         '    "autor": "José Carlos da Rocha - 5Volution Desenvolvimento",' + hb_eol() + ;
         '    "data_exportacao": "' + DTOC(DATE()) + '",' + hb_eol() + ;
         '    "total_elementos": ' + LTRIM(STR(LEN(::aData))) + hb_eol() + ;
         '  },' + hb_eol() + ;
         '  "dados": [' + hb_eol()

    FOR i := 1 TO LEN(::aData)
        cLine := '    {' + hb_eol() + ;
             '      "chave": "' + ::aData[i][1] + '",' + hb_eol() + ;
             '      "valor": ' + ALLTRIM(STR(::aData[i][2])) + ',' + hb_eol() + ;
             '      "chave_pai": "' + ::aData[i][3] + '",' + hb_eol() + ;
             '      "data_criacao": "' + DTOC(::aData[i][4]) + '"' + hb_eol() + ;
             '    }'
    
        IF i < LEN(::aData)
            cLine += ","
        ENDIF
    
        cJSON += cLine + hb_eol()
    NEXT

    cJSON += "  ]" + hb_eol() + "}"

    // Escrever no arquivo
    FWRITE(nHandle, cJSON)
    FCLOSE(nHandle)

    ? "Arquivo JSON exportado com sucesso: " + cOutputFile
RETURN .T.

//---------------------------------------------------------------------------
// Importar de CSV
//---------------------------------------------------------------------------
METHOD FromCSV(cInputFile, lAppend) CLASS TToon
    LOCAL nHandle, cLine, aFields, nLineCount := 0

    // Verificar se arquivo existe
    IF !FILE(cInputFile)
        ? "ERRO: Arquivo CSV não encontrado."
        RETURN .F.
    ENDIF

    // Se não for append, limpar dados
    IF lAppend != NIL .AND. !lAppend
        ::Reset()
    ENDIF

    // Abrir arquivo
    nHandle := FOPEN(cInputFile, FO_READ)
    IF nHandle == -1
        ? "ERRO: Não foi possível abrir o arquivo CSV."
        RETURN .F.
    ENDIF

    // Pular cabeçalho
    cLine := FREADLN(nHandle)

    // Ler dados
    DO WHILE !FEOF(nHandle)
        cLine := FREADLN(nHandle)
        nLineCount++
    
        IF !EMPTY(ALLTRIM(cLine))
            aFields := hb_ATokens(cLine, ",")
        
            IF LEN(aFields) >= 4
                ::Add(aFields[1], VAL(aFields[2]), aFields[3])
            ENDIF
        ENDIF
    ENDDO

    FCLOSE(nHandle)

    ? "Arquivo CSV importado com sucesso: " + cInputFile
    ? "Linhas importadas: " + LTRIM(STR(nLineCount))
RETURN .T.

//---------------------------------------------------------------------------
// Importar de JSON
//---------------------------------------------------------------------------
METHOD FromJSON(cInputFile, lAppend) CLASS TToon
    LOCAL cJSON, nPos, cKey, cValue, cParentKey, cDate

    // Verificar se arquivo existe
    IF !FILE(cInputFile)
        ? "ERRO: Arquivo JSON não encontrado."
        RETURN .F.
    ENDIF

    // Para simplificar, esta é uma versão básica
    // Em uma implementação real, usar um parser JSON completo

    ? "Importação de JSON - Versão simplificada"
    ? "Para implementação completa, use um parser JSON dedicado."

    // Se não for append, limpar dados
    IF lAppend != NIL .AND. !lAppend
        ::Reset()
    ENDIF

    // Ler arquivo
    cJSON := MEMOREAD(cInputFile)
    
    // Parsing simples (apenas para demonstração)
    // Nota: Esta é uma implementação simplificada

    ? "Arquivo JSON lido. Implemente o parser completo conforme necessidade."
RETURN .T.

//---------------------------------------------------------------------------
// Métodos auxiliares
//---------------------------------------------------------------------------

// Resetar dados
METHOD Reset() CLASS TToon
    ::aData := {}
    ::aStructure := {}
    ::lModified := .T.
    ? "Dados resetados."
RETURN .T.

// Exibir dados
METHOD Display() CLASS TToon
    LOCAL i, nLevel

    ? "=== CONTEÚDO DO ARQUIVO TOON ==="
    ? "Arquivo: " + ::cFileName
    ? "Elementos: " + LTRIM(STR(LEN(::aData)))

    FOR i := 1 TO LEN(::aData)
        nLevel := IF(EMPTY(::aData[i][3]), 0, 1)
        ? REPLICATE("  ", nLevel) + "[" + ::aData[i][1] + "] = " + ;
          ALLTRIM(STR(::aData[i][2]))
        
        IF !EMPTY(::aData[i][3])
            ? REPLICATE("  ", nLevel) + "  Pai: " + ::aData[i][3]
        ENDIF
    NEXT

RETURN .T.

// Obter estrutura
METHOD GetStructure() CLASS TToon
    LOCAL i

    ? "=== ESTRUTURA DO ARQUIVO ==="

    FOR i := 1 TO LEN(::aStructure)
        ? ::aStructure[i]
    NEXT
RETURN ::aStructure

// Validar dados
METHOD Validate() CLASS TToon
    LOCAL i, lValid := .T., cError := ""

    FOR i := 1 TO LEN(::aData)
        // Validar chave não vazia
        IF EMPTY(::aData[i][1])
            cError := "Chave vazia na linha " + LTRIM(STR(i))
            lValid := .F.
            EXIT
        ENDIF
        
        // Validar valor não nulo
        IF ::aData[i][2] == NIL
            cError := "Valor nulo para chave " + ::aData[i][1]
            lValid := .F.
            EXIT
        ENDIF
    
        // Se tem pai, verificar se pai existe
        IF !EMPTY(::aData[i][3])
            IF ::Find(::aData[i][3]) == 0
                cError := "Pai '" + ::aData[i][3] + "' não encontrado para chave " + ::aData[i][1]
                lValid := .F.
                EXIT
            ENDIF
        ENDIF
    NEXT

    IF lValid
        ? "Dados validados com sucesso."
    ELSE
        ? "ERRO na validação: " + cError
    ENDIF
RETURN lValid

//---------------------------------------------------------------------------
// Métodos privados
//---------------------------------------------------------------------------

// Analisar linha TOON
METHOD ParseToonLine(cLine) CLASS TToon
    LOCAL aElement, aParts, cKey, xValue, cParentKey

    // Formato: chave=valor ou chave_pai.chave=valor
    aParts := hb_ATokens(cLine, "=")

    IF LEN(aParts) != 2
        RETURN NIL
    ENDIF

    // Verificar se tem hierarquia
    IF AT(".", aParts[1]) > 0
        // Tem hierarquia: pai.filho
        aElement := hb_ATokens(aParts[1], ".")
        IF LEN(aElement) != 2
            RETURN NIL
        ENDIF
    
        cParentKey := ALLTRIM(aElement[1])
        cKey := ALLTRIM(aElement[2])
    ELSE
        // Não tem hierarquia
        cParentKey := ""
        cKey := ALLTRIM(aParts[1])
    ENDIF

    // Converter valor
    xValue := VAL(ALLTRIM(aParts[2]))

    // Criar array do elemento
    aElement := Array(4)
    aElement[1] := cKey
    aElement[2] := xValue
    aElement[3] := cParentKey
    aElement[4] := DATE()  // Data será atualizada no carregamento real
RETURN aElement

// Construir linha TOON
METHOD BuildToonLine(aElement) CLASS TToon
    LOCAL cLine

    IF LEN(aElement) < 4
        RETURN ""
    ENDIF

    IF EMPTY(aElement[3])
        cLine := aElement[1] + "=" + ALLTRIM(STR(aElement[2]))
    ELSE
        cLine := aElement[3] + "." + aElement[1] + "=" + ALLTRIM(STR(aElement[2]))
    ENDIF
RETURN cLine

// Encontrar elemento (versão privada)
METHOD FindElement(cKey, cParentKey) CLASS TToon
RETURN ::Find(cKey, cParentKey)

// Adicionar à estrutura
METHOD AddToStructure(aElement) CLASS TToon
    LOCAL cPath

    IF EMPTY(aElement[3])
        cPath := aElement[1]
    ELSE
        cPath := aElement[3] + "." + aElement[1]
    ENDIF

    AADD(::aStructure, cPath)
RETURN .T.

//---------------------------------------------------------------------------
// Programa de exemplo
//---------------------------------------------------------------------------
PROCEDURE Main()
    LOCAL oToon, nOpcao

    CLS
    ? "=== TTOON CLASS - Exemplo de Uso ==="
    ? "Desenvolvido por José Carlos da Rocha - 5Volution Desenvolvimento"
    ? "Versão: 1.0.0"
    ?

    // Criar objeto
    oToon := TToon():New("exemplo.toon")

    // Menu principal
    DO WHILE .T.
        ?
        ? "MENU PRINCIPAL:"
        ? "1. Carregar arquivo TOON"
        ? "2. Exibir conteúdo"
        ? "3. Adicionar elemento"
        ? "4. Excluir elemento"
        ? "5. Atualizar elemento"
        ? "6. Buscar elemento"
        ? "7. Exportar para CSV"
        ? "8. Exportar para JSON"
        ? "9. Importar de CSV"
        ? "10. Validar dados"
        ? "11. Salvar arquivo"
        ? "12. Sair"
        ?
    
        ACCEPT "Escolha uma opção: " TO nOpcao
    
        DO CASE
            CASE nOpcao == "1"
                ACCEPT "Nome do arquivo TOON: " TO cFile
                oToon:cFileName := cFile
                oToon:Load()
            
            CASE nOpcao == "2"
                oToon:Display()
            
            CASE nOpcao == "3"
                LOCAL cKey, nValue, cParent
                ACCEPT "Chave: " TO cKey
                ACCEPT "Valor: " TO nValue
                ACCEPT "Chave pai (enter para nenhum): " TO cParent
                oToon:Add(cKey, VAL(nValue), IF(EMPTY(cParent), NIL, cParent))
            
            CASE nOpcao == "4"
                LOCAL cKey, cParent
                ACCEPT "Chave a excluir: " TO cKey
                ACCEPT "Chave pai (enter para nenhum): " TO cParent
                oToon:Delete(cKey, IF(EMPTY(cParent), NIL, cParent))
            
            CASE nOpcao == "5"
                LOCAL cKey, nValue, cParent
                ACCEPT "Chave a atualizar: " TO cKey
                ACCEPT "Novo valor: " TO nValue
                ACCEPT "Chave pai (enter para nenhum): " TO cParent
                oToon:Update(cKey, VAL(nValue), IF(EMPTY(cParent), NIL, cParent))
            
            CASE nOpcao == "6"
                LOCAL cKey, cParent, nIndex
                ACCEPT "Chave a buscar: " TO cKey
                ACCEPT "Chave pai (enter para nenhum): " TO cParent
                nIndex := oToon:Find(cKey, IF(EMPTY(cParent), NIL, cParent))
                IF nIndex > 0
                    ? "Elemento encontrado na posição: " + LTRIM(STR(nIndex))
                ELSE
                    ? "Elemento não encontrado."
                ENDIF
            
            CASE nOpcao == "7"
                ACCEPT "Nome do arquivo CSV: " TO cFile
                oToon:ToCSV(cFile)
            
            CASE nOpcao == "8"
                ACCEPT "Nome do arquivo JSON: " TO cFile
                oToon:ToJSON(cFile)
            
            CASE nOpcao == "9"
                ACCEPT "Nome do arquivo CSV: " TO cFile
                ACCEPT "Anexar aos dados existentes? (S/N): " TO cAppend
                oToon:FromCSV(cFile, UPPER(cAppend) == "S")
            
            CASE nOpcao == "10"
                oToon:Validate()
            
            CASE nOpcao == "11"
                IF oToon:Save()
                    ? "Arquivo salvo com sucesso."
                ENDIF
            
            CASE nOpcao == "12"
                EXIT
            
            OTHERWISE
                ? "Opção inválida!"
        ENDCASE
    
        WAIT
    ENDDO

    // Liberar objeto
    oToon := NIL

    ?
    ? "Programa encerrado."
    ?
RETURN

//---------------------------------------------------------------------------
// Exemplo de arquivo TOON (exemplo.toon)
//---------------------------------------------------------------------------
/* **** **** **** ****
Arquivo TOON de exemplo com hierarquia de duas dimensões
Gerado por TToon Class v1.0.0
Elementos raiz
usuario=1
produto=10
pedido=5

Elementos filhos de usuario
usuario.nome=1
usuario.email=1
usuario.ativo=1

Elementos filhos de produto
produto.nome=10
produto.preco=25.50
produto.estoque=100

Elementos filhos de pedido
pedido.numero=5
pedido.data=20241215
pedido.total=127.50
*/

//---------------------------------------------------------------------------
// Instruções de compilação:
//---------------------------------------------------------------------------
/* **** **** **** ****
Para compilar no Clipper 5.0:

Salve o código como TTOON.PRG

Compile com: CLIPPER TTOON

Link com: RTLINK FI TTOON

Ou use o script de build:

@echo off
echo Compilando TToon Class...
CLIPPER TTOON
RTLINK FI TTOON
echo Compilação concluída!
echo Execute: TTOON.exe
pause
*/

//---------------------------------------------------------------------------
// Histórico de versões:
//---------------------------------------------------------------------------
/* **** **** **** ****
v1.0.0 (2024) - Versão inicial

Implementação da classe TToon

Métodos básicos CRUD

Exportação para CSV e JSON

Importação de CSV

Suporte a hierarquia de 2 níveis

Validação de dados

Programa de exemplo com menu
*/