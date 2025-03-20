packages <- c("here","dplyr", "readr", "xlsx2dfs", "tidyr", "lubridate", "rmarkdown", "shiny", "DT", "shinyjs")

for (p in packages) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, dependencies = TRUE)
  }
  suppressPackageStartupMessages(library(p, character.only = TRUE))
}

setwd(here())

# User Interface####
ui <- fluidPage(
  useShinyjs(),
  
  titlePanel(tags$h1(style = "text-align: center; font-weight: bold; color: #2a93d5; font-size: 30px;","Análises Mensais de Controle da Qualidade da Água de Soluções Alternativas Coletivas de Abastecimento (SAC)")),tags$div(style = "padding: 20px; background-color: #edfafd; border-radius: 10px; margin-bottom: 20px;",tags$h3(style = "text-align: center; font-weight: bold; color: #333333;","Divisão de Vigilância Sanitária"),tags$h4(style = "text-align: center; font-weight: bold; color: #333333;","Secretaria Municipal da Saúde de Ribeirão Preto"),tags$hr(),tags$p(style = "text-align: justify;",HTML("Este programa realiza análises dos dados de controle da qualidade da água fornecida por Soluções Alternativas Coletivas de Abastecimento (SAC) inseridos mensalmente no <a href='https://sisagua.saude.gov.br/sisagua' target='_blank'>Sistema de Informação de Vigilância da Qualidade da Água para Consumo Humano (SISAGUA)</a>, e disponibilizados no <a href='https://dados.gov.br/' target='_blank'>Portal Brasileiro de Dados Abertos</a>.")),tags$p(style = "text-align: justify;",HTML("São avaliadas a frequência de amostragem e a conformidade dos parâmetros físico-químicos (Turbidez, Cor Aparente, pH e Cloro residual livre) e microbiológicos (coliformes totais e <i>Escherichia coli</i>) com os padrões de potabilidade da água para consumo humano estabelecidos na <a href='https://www.in.gov.br/en/web/dou/-/portaria-gm/ms-n-888-de-4-de-maio-de-2021-318461562' target='_blank'>Portaria GM/MS Nº888, de 4 de maio de 2021</a>. Os relatórios gerados seguem o modelo das fichas de procedimentos do <a href = 'https://sivisa.saude.sp.gov.br/sivisa/' target='_blank'>Sistema de Informação em Vigilância Sanitária (SIVISA)</a>, elaborado pelo Centro de Vigilância Sanitária (CVS), da Secretaria de Estado da Saúde de São Paulo (SES-SP).")),tags$p(style = "text-align: justify;", HTML("<b>ATENÇÃO</b>: Nesta versão é possível filtrar os dados por município, inserindo o código IBGE (sem o dígito verificador). Consulte o código IBGE do seu município em: <a href='https://www.ibge.gov.br/explica/codigos-dos-municipios.php' target='_blank'>https://www.ibge.gov.br/explica/codigos-dos-municipios.php</a>.")),tags$p(style = "text-align: justify;","Elaborado por: Vinicius Alberici Roberto (Especialista em Ciências Ambientais - VISA/SMS-RP)."),tags$p(style = "text-align: justify;", HTML('<b>Dúvidas, correções ou sugestões de melhorias, envie um e-mail para:</b> <a href="mailto:varoberto@rp.ribeiraopreto.sp.gov.br?subject=Assunto%20do%20Email&body=Corpo%20da%20Mensagem">varoberto@rp.ribeiraopreto.sp.gov.br</a>')),tags$hr(),tags$p(style = "text-align: center; font-style: italic;",paste("Código atualizado em:", format(Sys.Date(), "%d/%m/%Y")))),
  
  sidebarLayout(
    sidebarPanel(
      numericInput(
        "codigo_ibge",
        "Código IBGE do município (ou deixe como está para Ribeirão Preto):",
        value = 354340,
        min = 100000,
        max = 999999
      ),
      numericInput(
        "ano",
        "Ano de interesse (2014 - 2025):",
        value = as.numeric(format(Sys.Date(), "%Y")),
        min = 2014,
        max = 2025
      ),
      numericInput(
        "mes",
        "Mês de interesse (1 a 12):",
        value = as.numeric(format(Sys.Date(), "%m")),
        min = 1,
        max = 12
      ),
      actionButton("analisar_btn", "Analisar")
    ),
    
    mainPanel(
      h3("Dados filtrados por município e data"),
      DTOutput("tabela_resultados"),
      actionButton("tabela_resultados_btn", "Visualizar Tabela"), 
      downloadButton("download_tabela_resultados", "Baixar Dados"),
      
      h3("Lista de SACs que preencheram o SISAGUA no período selecionado"),
      DTOutput("lista_SAC"),
      actionButton("lista_SAC_btn", "Visualizar Tabela"),  
      downloadButton("download_lista_SAC", "Baixar Dados"),
      
      h3("Ficha de procedimentos - SIVISA"),
      actionButton("relatorios", "Exportar Relatórios"),  
    )
  )
)

# Server####
server <- function(input, output, session) {
  # Criar uma variável reativa para armazenar os dados filtrados
  dados_filtrados <- reactiveVal(NULL)
  
  # Desabilitar os botões inicialmente
  shinyjs::disable("tabela_resultados_btn")
  shinyjs::disable("download_tabela_resultados")
  shinyjs::disable("lista_SAC_btn")
  shinyjs::disable("download_lista_SAC")
  shinyjs::disable("relatorios")
  
  # Evento para processar os dados ao clicar no botão "Analisar"
  observeEvent(input$analisar_btn, {
    
    # Valida as entradas
    if (is.null(input$codigo_ibge) || is.na(input$codigo_ibge) || input$codigo_ibge == "" ||
        is.null(input$ano) || is.na(input$ano) || input$ano == "" ||
        is.null(input$mes) || is.na(input$mes) || input$mes == "") {
      showNotification("Por favor, insira valores válidos para o ano, mês e código IBGE.", type = "error")
      return()
    }
    
    # Verifica se o código IBGE tem 6 dígitos
    if (input$codigo_ibge < 100000 || input$codigo_ibge > 999999) {
      showNotification("O código IBGE deve ter exatamente 6 dígitos.", type = "error")
      return()
    }
    
    # Verifica se o ano está dentro do intervalo esperado
    if (input$ano < 2014 || input$ano > 2025) {
      showNotification("Por favor, insira um ano entre 2014 e 2025.", type = "error")
      return()
    }
    
    # Verifica se o mês está dentro do intervalo esperado
    if (input$mes < 1 || input$mes > 12) {
      showNotification("Por favor, insira um mês entre 1 e 12.", type = "error")
      return()
    }
    
    withProgress(message = 'Processando dados...', value = 0, {
      # Incremento inicial da barra de progresso
      setProgress(value = 0.1, detail = "Iniciando download...")
      
      # Construção do URL com ano dinâmico
      url_dados <- paste0(
        "https://arquivosdadosabertos.saude.gov.br/dados/sisagua/controle_mensal_parametros_basicos_",
        input$ano,
        ".zip"
      )
      
      temp <- tempfile()
      tryCatch({
        # Baixar e processar os dados
        download.file(url = url_dados, destfile = temp, mode = "wb")
        setProgress(value = 0.3, detail = "Extraindo arquivos...")
        
        datazip <- unzip(temp, files = paste0("controle_mensal_parametros_basicos_", input$ano, ".csv"))
        setProgress(value = 0.5, detail = "Lendo os dados...")
        
        dados <- read_delim(
          datazip,
          delim = ";",
          locale = locale(encoding = "WINDOWS-1252"),
          trim_ws = TRUE,
          show_col_types = FALSE
        )
        
        setProgress(value = 0.7, detail = "Filtrando os dados...")
        
        # Filtrar os dados com validação
        df_filtrado <- dados %>%
          filter(
            `Código IBGE` == as.numeric(input$codigo_ibge) &
              `Tipo da Forma de Abastecimento` == "SAC" &
              `Mês de referência` == input$mes
          )
        
        setProgress(value = 0.9, detail = "Finalizando...")
        
        # Atualiza a variável reativa com os dados filtrados
        dados_filtrados(df_filtrado)
        
        # Verificação: exibe um modal se não houver dados
        if (nrow(df_filtrado) == 0) {
          showModal(
            modalDialog(
              title = "Aviso",
              "Nenhum dado encontrado para os parâmetros selecionados.",
              easyClose = TRUE
            )
          )
        } else {
          # Exibe uma notificação ao usuário
          showNotification(
            "Análise concluída! Você já pode visualizar a tabela ou exportar os dados.",
            type = "message",
            duration = 5
          )
          
          # Removendo arquivos temporários
          unlink(paste0("controle_mensal_parametros_basicos_", input$ano, ".csv"))
          
          # Habilitar os botões após a análise
          shinyjs::enable("tabela_resultados_btn")
          shinyjs::enable("download_tabela_resultados")
          shinyjs::enable("lista_SAC_btn")
          shinyjs::enable("download_lista_SAC")
          shinyjs::enable("relatorios")        
        }
      }, error = function(e) {
        showModal(
          modalDialog(
            title = "Erro",
            paste("Ocorreu um erro:", e$message),
            easyClose = TRUE
          )
        )
      })
      
      setProgress(value = 1, detail = "Concluído!")
    })
  })
  
  # Renderizar a tabela de dados filtrados no botão Visualizar
  observeEvent(input$tabela_resultados_btn, {
    output$tabela_resultados <- renderDT({
      req(dados_filtrados())  # Garante que os dados filtrados existam
      datatable(
        dados_filtrados(),
        options = list(
          pageLength = 5,
          language = list(
            search = "Buscar:",
            lengthMenu = "Mostrar _MENU_ entradas",
            info = "Mostrando _START_ até _END_ de _TOTAL_ entradas",
            emptyTable = "Nenhum dado disponível",
            zeroRecords = "Nenhum registro correspondente encontrado",
            paginate = list(
              first = "Primeira",
              last = "Última",
              `next` = "Próximo",
              previous = "Anterior"
            )
          )
        )
      )
    })
  })
  
  # Função para exportar os dados filtrados
  output$download_tabela_resultados <- downloadHandler(
    filename = function() {
      paste0("dados_filtrados_", input$codigo_ibge, "_", input$ano, "_", sprintf("%02d", input$mes), ".csv")
    },
    content = function(file) {
      # Garante que os dados existam antes de permitir o download
      req(dados_filtrados())
      write.csv(dados_filtrados(), file, row.names = FALSE, fileEncoding = "WINDOWS-1252")
    }
  )
  
  # Evento para exibir a Lista de SACs
  observeEvent(input$lista_SAC_btn, {
    output$lista_SAC <- renderDT({
      req(dados_filtrados())  # Garante que os dados filtrados existam
      sacs <- dados_filtrados() %>%
        select(`Código Forma de abastecimento`, `Nome da Forma de Abastecimento`) %>%
        distinct() %>%
        arrange(`Código Forma de abastecimento`)
      
      datatable(
        sacs,
        colnames = c("Código SISAGUA", "Nome da SAC"),
        options = list(
          pageLength = 5,
          language = list(
            search = "Buscar:",
            lengthMenu = "Mostrar _MENU_ entradas",
            info = "Mostrando _START_ até _END_ de _TOTAL_ entradas",
            emptyTable = "Nenhum dado disponível",
            zeroRecords = "Nenhum registro correspondente encontrado",
            paginate = list(
              first = "Primeira",
              last = "Última",
              `next` = "Próximo",
              previous = "Anterior"
            )
          )
        )
      )
    })
  })
  
  # Função para exportar a lista de SACs
  output$download_lista_SAC <- downloadHandler(
    filename = function() {
      paste0("lista_SAC_", input$codigo_ibge, "_", input$ano, "_", sprintf("%02d", input$mes), ".csv")
    },
    content = function(file) {
      # Garante que os dados filtrados existam antes de permitir o download
      req(dados_filtrados())
      sacs <- dados_filtrados() %>%
        select(`Código Forma de abastecimento`, `Nome da Forma de Abastecimento`) %>%
        distinct() %>%
        arrange(`Código Forma de abastecimento`)
      write.csv(sacs, file, row.names = FALSE, fileEncoding = "WINDOWS-1252")
    }
  )
  
  # Função para verificar frequência de amostragem e conformidade dos parâmetros
  verificar <- function(dados_filtrados) {
    dados_filtrados() %>%
      select(9, 8, 13, 14, 19, 20, 21, 22) %>%
      filter(Campo %in% c(
        "Número de amostras analisadas",
        "N de amostras com presença de coliformes totais",
        "N de amostras com presença para Escherichia coli",
        "Número de dados < 0,2 mg/L",
        "Número de dados > 5,0 mg/L",
        "Número de dados > 5,0 uT",
        "Número de dados > 15,0 uH",
        "Percentil 95"
      )) %>%
      pivot_wider(names_from = `Ponto de Monitoramento`, values_from = Valor, values_fill = list(Valor = NA)) %>%
      rename_with(~c("CNPJ", "Nome_da_Instituicao", "Codigo_SISAGUA", "Nome_da_SAC",
                     "Parametro", "Campo", "Saida_tratamento", "Ponto_consumo",
                     "Pós-filtração ou Pré-desinfecção"), everything()) %>%
      arrange(Codigo_SISAGUA, Parametro) %>%
      mutate(
        freq_ST = case_when(
          Campo == "Número de amostras analisadas" & Parametro == "Cloro Residual Livre (mg/L)" ~ Saida_tratamento >= days_in_month(input$mes),
          Campo == "Número de amostras analisadas" & Parametro %in% c("Coliformes totais", "Cor (uH)", "Escherichia coli", "pH") ~ Saida_tratamento >= 1,
          Campo == "Número de amostras analisadas" & Parametro == "Turbidez (uT)" ~ Saida_tratamento >= 4,
          TRUE ~ NA
        ),
        freq_PC = case_when(
          Campo == "Número de amostras analisadas" & Parametro == "Cloro Residual Livre (mg/L)" ~ Ponto_consumo >= days_in_month(input$mes),
          Campo == "Número de amostras analisadas" & Parametro %in% c("Coliformes totais", "Cor (uH)", "Escherichia coli", "pH") ~ Ponto_consumo >= 1,
          Campo == "Número de amostras analisadas" & Parametro == "Turbidez (uT)" ~ Ponto_consumo >= 1,
          TRUE ~ NA
        ),
        conf_ST = case_when(
          Campo %in% c("N de amostras com presença de coliformes totais",
                       "N de amostras com presença para Escherichia coli",
                       "Número de dados < 0,2 mg/L",
                       "Número de dados > 5,0 mg/L",
                       "Número de dados > 5,0 uT",
                       "Número de dados > 15,0 uH") ~ Saida_tratamento == 0,
          TRUE ~ NA
        ),
        conf_PC = case_when(
          Campo %in% c("N de amostras com presença de coliformes totais",
                       "N de amostras com presença para Escherichia coli",
                       "Número de dados < 0,2 mg/L",
                       "Número de dados > 5,0 mg/L",
                       "Número de dados > 5,0 uT",
                       "Número de dados > 15,0 uH") ~ Ponto_consumo == 0,
          TRUE ~ NA
        ),
        p95_ST = case_when(
          Campo == "Percentil 95" & Parametro == "Cloro Residual Livre (mg/L)"  ~ (Saida_tratamento > 0.2 & Saida_tratamento <= 5),
          Campo == "Percentil 95" & Parametro == "Cor (uH)"  ~ Saida_tratamento <= 15,
          Campo == "Percentil 95" & Parametro == "Turbidez (uT)"  ~ Saida_tratamento <= 5,
          TRUE ~ NA
        ),
        p95_PC = case_when(
          Campo == "Percentil 95" & Parametro == "Cloro Residual Livre (mg/L)"  ~ (Ponto_consumo > 0.2 & Ponto_consumo <= 5),
          Campo == "Percentil 95" & Parametro == "Cor (uH)"  ~ Ponto_consumo <= 15,
          Campo == "Percentil 95" & Parametro == "Turbidez (uT)"  ~ Ponto_consumo <= 5,
          TRUE ~ NA
        )
      )
  }
  
  # Evento para rodar o script quando o botão "Exportar Relatórios" for clicado
  observeEvent(input$relatorios, {
    # Define o nome da pasta
    pasta_relatorios <- paste0("relatorios_SAC", "_", input$codigo_ibge, "_", input$ano, "_", input$mes)
    
    # Define o caminho completo para a pasta
    caminho_completo <- file.path(getwd(), pasta_relatorios)
    
    # Cria a pasta se ela não existir
    if (!dir.exists(caminho_completo)) {
      dir.create(caminho_completo)
      showNotification(paste("Pasta criada em:", caminho_completo), type = "message")
    } else {
      showNotification("A pasta já existe.", type = "warning")
    }
    
    # Executa a função de verificação
    resultado <- reactive({
      req(dados_filtrados())  # Garante que há dados
      verificar(dados_filtrados())  # Executa a função com os dados reativos
    })
    
    # Salva o resultado após avaliar a função reativa
    observe({
      req(resultado())  # Garante que a função reativa tenha retornado um valor
      saveRDS(resultado(), "resultado.RDS")
    })
    
    # Lista com os códigos das SACs
    lista_sacs <- reactive({
      req(resultado())  # Garante que a função reativa tenha retornado um valor
      unique(resultado()$Codigo_SISAGUA)
    })
    
    # Gera relatórios para cada SAC
    observeEvent(input$relatorios, {
      req(lista_sacs())  # Certifica-se de que a lista de SACs está pronta
      
      # Garante que o arquivo RDS será removido, independentemente do resultado
      on.exit(unlink("resultado.RDS"), add = TRUE)
      
      tryCatch({
        withProgress(message = "Exportando...", value = 0, {
          # Loop para gerar relatórios
          for (i in seq_along(lista_sacs())) {
            incProgress(1 / length(lista_sacs()), detail = paste("SAC:", lista_sacs()[i]))
            
            # Tenta renderizar o relatório
            rmarkdown::render(
              input = "relatorios.Rmd",
              output_file = file.path(caminho_completo, paste0(lista_sacs()[i], ".docx")),
              params = list(codigo_sac = lista_sacs()[i]),
              envir = new.env()
            )
          }
        })
        
        # Mensagem de sucesso
        showNotification("Relatórios exportados com sucesso!", type = "message")
      }, error = function(e) {
        # Mensagem única de erro
        showNotification(
          "Falha na exportação: verifique suas permissões de gravação no diretório e se há espaço suficiente no disco.",
          type = "error"
        )
      })
    })
  })
}  

# Rodar aplicação
shinyApp(ui = ui, server = server)