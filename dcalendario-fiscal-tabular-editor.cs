// Este script realiza as seguintes operações:
// 1. Faz a ordenação das colunas de texto pelas colunas numéricas
// 2. Organiza as colunas em pastas por granularidade
// 3. Aplica o formato short date para colunas do tipo data
// 4. Remove agregações das colunas numéricas
// 5. Marca a tabela como tabela de data

// Acessa a tabela dCalendario
var dcalendariofiscal = Model.Tables["dCalendarioFiscal"];  

// Cria um mapeamento das colunas de texto e suas respectivas colunas numéricas para ordenação
var columnPairs = new Dictionary<string, string>
{
    {"BimestreAnoFiscalNome", "BimestreAnoFiscalNum"},
    {"BimestreFiscalNome", "BimestreFiscalNum"},
    {"DiaSemanaFiscalNome", "DiaSemanaFiscalNum"},
    {"DiaSemanaFiscalNomeAbrev", "DiaSemanaFiscalNum"},
    {"MesAnoFiscalNome", "MesAnoFiscalNum"},
    {"MesAnoFiscalNumTexto", "MesAnoFiscalNum"},
    {"MesFiscalNome", "MesFiscalNum"},
    {"MesFiscalNomeAbrev", "MesFiscalNum"},
    {"SemanaAnoFiscalNome", "SemanaAnoFiscalNum"},
    {"SemestreAnoFiscalNome", "SemestreAnoFiscalNum"},
    {"SemestreFiscalNome", "SemestreFiscalNum"},
    {"TrimestreAnoFiscalNome", "TrimestreAnoFiscalNum"},
    {"TrimestreFiscalNome", "TrimestreFiscalNum"}

};

// Aplica a ordenação para cada coluna de texto
foreach (var pair in columnPairs)
{
    var textColumn = dcalendariofiscal.Columns[pair.Key];  // Coluna de texto
    var sortColumn = dcalendariofiscal.Columns[pair.Value];  // Coluna numérica correspondente

    // Verifica se ambas as colunas existem e aplica a ordenação
    if (textColumn != null && sortColumn != null)
    {
        textColumn.SortByColumn = sortColumn;  // Ordena a coluna de texto pela coluna numérica
    }
}

// Dicionário para associar as colunas às pastas correspondentes
var displayFolders = new Dictionary<string, string[]>
{
    { "Data Fiscal", new[] { "DataFiscal", "DataFiscalIndice" }},
    { "Ano Fiscal", new[] { "AnoFiscal", "AnoFiscalFinal", "AnoFiscalInicial"}},
    { "Bimestre Fiscal", new[] { "BimestreAnoFiscalNome", "BimestreAnoFiscalNum", "BimestreFiscalNome", "BimestreFiscalNum"}},
    { "Dia da Semana", new[] { "DiaSemanaFiscalNome", "DiaSemanaFiscalNomeAbrev", "DiaSemanaFiscalNum"}},
    { "Mês Fiscal", new[] { "MesAnoFiscalNome", "MesAnoFiscalNum", "MesAnoFiscalNumTexto", "MesFiscalNome", "MesFiscalNomeAbrev", "MesFiscalNum"}},
    { "Semana do Ano Fiscal", new[] { "SemanaFiscalNum", "SemanaAnoFiscalNome", "SemanaAnoFiscalNum", "SemanaAnoFiscalNome", "SemanaAnoFiscalNum"}},
    { "Semestre Fiscal", new[] { "SemestreAnoFiscalNome", "SemestreAnoFiscalNum", "SemestreFiscalNome", "SemestreFiscalNum"}},
    { "Trimestre Fiscal", new[] { "TrimestreAnoFiscalNome", "TrimestreAnoFiscalNum", "TrimestreFiscalNome", "TrimestreFiscalNum"}}
};

// Itera sobre as pastas e aplica o DisplayFolder a cada coluna associada
foreach (var folder in displayFolders)
{
    var folderName = folder.Key;
    var columns = folder.Value;

    foreach (var columnName in columns)
    {
        var column = dcalendariofiscal.Columns[columnName];
        if (column != null)
        {
            column.DisplayFolder = folderName; // Atribue as colunas à pasta correspondente
        }
    }
}

// Desabilitar agregações para todas as colunas da tabela
foreach (var column in dcalendariofiscal.Columns)
{
    column.SummarizeBy = AggregateFunction.None;  // Desabilitar agregação
}

// Definir o formato para as colunas do tipo Data
var dateColumns = new[] { "DataFiscal" };  // Colunas que contêm datas
foreach (var columnName in dateColumns)
{
    var column = dcalendariofiscal.Columns[columnName];
    if (column != null)
    {
        column.FormatString = "Short Date";  // Aplica o formato de data curta
    }
}

// Marcar como uma tabela de data
dcalendariofiscal.DataCategory = "Time";
dcalendariofiscal.Columns["DataFiscal"].IsKey = true; 
