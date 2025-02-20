# Exibir o cabeçalho e as mensagens iniciais no console
cat("####################################################################################################\n")
cat("#                                                                                                  #\n")
cat("#                      ANÁLISES MENSAIS DE CONTROLE DA QUALIDADE DA ÁGUA                           #\n")
cat("#                   DE SOLUÇÕES ALTERNATIVAS COLETIVAS DE ABASTECIMENTO(SAC)                       #\n")
cat("#                                                                                                  #\n")
cat("####################################################################################################\n")
cat("\n")
cat("# Este script realiza análises dos dados de controle da qualidade da água fornecida por SACs       #\n")
cat("# inseridos mensalmente no SISAGUA - Sistema de Informação de Vigilância da Qualidade da Água para #\n")
cat("# Consumo Humano, e disponibilizados no Portal Brasileiro de Dados Abertos (https://dados.gov.br/).#\n")
cat("\n")
cat("# São analisadas a frequência de amostragem e a conformidade dos parâmetros microbiológicos        #\n")
cat("# (coliformes totais e Escherichia coli) e físico-químicos (Turbidez, Cor Aparente, pH e Cloro     #\n")
cat("# residual livre) com os padrões de potabilidade da água para consumo humano estabelecidos         #\n")
cat("# na Portaria GM/MS Nº888, de 4 de maio de 2021.                                                   #\n")
cat("\n")
cat("# ATENÇÃO: Nesta versão é possível filtrar os dados por município. Consulte o código do            #\n")
cat("# município de interesse em: https://www.ibge.gov.br/explica/codigos-dos-municipios.php            #\n")
cat("\n")
cat("# Elaborado por: Vinicius Alberici Roberto (Especialista em Ciências Ambientais da Divisão         #\n")
cat("# de Vigilância Sanitária da Secretaria Municipal da Saúde de Ribeirão Preto).                     #\n")
cat("\n")
cat("# Dúvidas, correções ou sugestões de melhorias, envie um e-mail para:                              #\n")
cat("# <varoberto@rp.ribeiraopreto.sp.gov.br>                                                           #\n")
cat("\n")
cat("# CÓDIGO ATUALIZADO EM: 19/02/2025                                                                 #\n")
cat("\n")
cat("####################################################################################################\n")
cat("\n")

# Mensagem de boas-vindas
cat("Bem-vindo!\n")
cat("Este script irá guiá-lo através de algumas perguntas para realizar as análises desejadas.\n")
cat("Por favor, siga as instruções abaixo.\n\n")

# Pausa para o usuário ler o cabeçalho
invisible(readline(prompt = "Pressione ENTER para começar..."))

# Verificar e instalar pacotes necessários
pacotes <- c("readr", "dplyr", "officer", "lubridate", "knitr", "DT", "openxlsx")

for (p in pacotes) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p)
}

# Carregar bibliotecas
suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(officer)
  library(lubridate)
  library(knitr)
  library(DT)
  library(openxlsx)
})

# Função para solicitar entrada do usuário de forma interativa
solicitar_entrada <- function(pergunta, validacao) {
  repeat {
    resposta <- readline(prompt = pergunta)
    if (validacao(resposta)) return(resposta)
    cat("Entrada inválida. Tente novamente.\n")
  }
}

# Perguntar ao usuário o código do município (IBGE)
codigo_ibge <- solicitar_entrada("Digite o código IBGE do município (ou pressione ENTER para Ribeirão Preto): ", function(x) {
  x == "" || (nchar(x) %in% c(6, 7) && !is.na(as.numeric(x)))
})

# Se a entrada for vazia, usar o código de Ribeirão Preto
if (codigo_ibge == "") {
  codigo_ibge <- 354340 
} else {
  codigo_ibge <- as.numeric(codigo_ibge)
}

# Perguntar ao usuário o ano de interesse
ano <- as.numeric(solicitar_entrada("Digite o ano de interesse para análise (Dados disponíveis desde 2014): ", function(x) {
  !is.na(as.numeric(x)) && as.numeric(x) >= 2014 && as.numeric(x) <= year(Sys.Date())
}))

# Perguntar ao usuário o mês de interesse
mes <- as.numeric(solicitar_entrada("Digite o mês de interesse para análise (1 a 12): ", function(x) {
  !is.na(as.numeric(x)) && as.numeric(x) >= 1 && as.numeric(x) <= 12
}))

# Fazer o download do arquivo correspondente
temp <- tempfile()
url_dados <- paste0("https://arquivosdadosabertos.saude.gov.br/dados/sisagua/controle_mensal_parametros_basicos_", ano, ".zip")

tryCatch({
  cat("Fazendo o download dos dados...\n")
  download.file(url = url_dados, destfile = temp, mode = "wb")
  
  cat("Processando os dados...\n")
  datazip <- unzip(temp, files = paste0("controle_mensal_parametros_basicos_", ano, ".csv"))
  dados <- read_delim(datazip, delim = ";", locale = locale(encoding = "WINDOWS-1252"), trim_ws = TRUE, show_col_types = FALSE)
  
  # Filtrar os dados com base nas escolhas do usuário
  dados_filtrados <- dados %>% 
    filter(`Código IBGE` == codigo_ibge & `Tipo da Forma de Abastecimento` == "SAC" & `Mês de referência` == mes)
  
  # Mostrar os resultados como tabela
  cat("\n--- Dados filtrados e prontos para análise ---\n")
  if (Sys.getenv("RSTUDIO") == "1") {
    suppressWarnings(print(datatable(dados_filtrados)))
  } else {
    head(dados_filtrados)
  }
  
}, error = function(e) {
  cat("Ocorreu um erro durante o download ou leitura do arquivo:", e$message, "\n")
}, finally = {
  unlink(temp)  # Remover o arquivo temporário
})

# Função para exportar dados para CSV e XLSX
exportar_dados <- function(dados, nome_arquivo) {
  write.csv(dados, file = paste0(nome_arquivo, ".csv"), row.names = FALSE)
  write.xlsx(dados, file = paste0(nome_arquivo, ".xlsx"))
  cat("Arquivos exportados com sucesso:", nome_arquivo, ".csv e .xlsx\n")
}

# Função para listar SACs que preencheram o SISAGUA no ano e mês selecionados
listar_sacs <- function(dados_filtrados, ano, mes) {
  sacs <- dados_filtrados %>%
    select(`Código Forma de abastecimento`, `Nome da Forma de Abastecimento`) %>%
    distinct() %>%
    arrange(`Código Forma de abastecimento`)
  
  if (Sys.getenv("RSTUDIO") == "1") {
    print(datatable(sacs, colnames = c("Código SISAGUA", "Nome da SAC"))) 
  } else {
    print(kable(sacs, col.names = c("Código SISAGUA", "Nome da SAC")))
  }
  
  if (tolower(readline(prompt = "Deseja exportar a lista de SACs? (S/N): ")) == "s") {
    exportar_dados(sacs, paste0("controle_mensal_2-Lista_SACs_", ano, "_", sprintf("%02d", mes)))
  } else {
    cat("Exportação cancelada.\n")
  }
}

# Função para exportar relatório SIVISA (mantida como está)
exportar_relatorio_sivisa <- function(dados_filtrados, mes, ano) {
  codigo_sisagua <- solicitar_entrada(
    "Digite o Código do SISAGUA da SAC ou pressione ENTER para exportar relatórios para todas as SACs: ",
    function(x) x == "" || grepl("^C\\d{12}$", x)
  )
  
  if (codigo_sisagua == "") {
    cat("Exportando fichas para todas as SACs...\n")
  } else if (codigo_sisagua %in% dados_filtrados$`Código Forma de abastecimento`) {
    cat("Exportando ficha para a SAC", codigo_sisagua, "...\n")
  } else {
    cat("A SAC não inseriu os dados de controle mensal no SISAGUA em", nomes_meses[mes], "de", ano, "\n")
  }
}

# Loop principal
repeat {
  cat("\nQual operação deseja realizar:\n")
  cat("\n")
  cat("1 - Exportar planilha bruta de dados (.csv e .xlsx)\n")
  cat("2 - Visualizar lista de SACs que preencheram o SISAGUA\n")
  cat("3 - Exportar relatório (Ficha de procedimentos SIVISA)\n\n")
  
  opcao <- as.numeric(solicitar_entrada("Escolha uma opção (1, 2 ou 3): ", function(x) x %in% c("1", "2", "3")))
  
  if (opcao == 1) {
    exportar_dados(dados_filtrados, paste0("controle_mensal_1-Dados_brutos_", ano, "_", sprintf("%02d", mes)))
  } else if (opcao == 2) {
    listar_sacs(dados_filtrados, ano, mes)
  } else if (opcao == 3) {
    exportar_relatorio_sivisa(dados_filtrados, mes, ano)
  }
  
  if (tolower(solicitar_entrada("Deseja realizar outra operação? (S/N): ", function(x) x %in% c("s", "n"))) == "n") {
    cat("Finalizando o programa...\n")
    break
  }
}