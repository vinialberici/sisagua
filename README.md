# Guia de Uso do Script .bat

Este script `.bat` automatiza o processo de verificação de dependências, download de arquivos e execução de um aplicativo Shiny utilizando o R. Siga as instruções abaixo para configurá-lo e executá-lo corretamente.

---

## Pré-requisitos

1. **Sistema Operacional:** Windows.
2. **R instalado:** Certifique-se de que a versão 4.4.3 do R esteja instalada.  
   - Caso ainda não tenha o R, faça o download aqui: [R 4.4.3 para Windows](https://cran.r-project.org/bin/windows/base/R-4.4.3-win.exe).
3. **Conexão com a Internet:** Necessária para baixar os arquivos do GitHub.

---

## Como usar o script

1. **Faça o download do script .bat**:
   - Certifique-se de que o arquivo `.bat` está localizado no diretório desejado.

2. **Execute o script**:
   - Clique duas vezes no arquivo `.bat` ou abra um terminal (Prompt de Comando) e execute:
     caminho_do_arquivo.bat

3. **Processo realizado pelo script**:
   - Verificação da instalação e da versão do R.
   - Download dos arquivos `app.R` e `relatorios.Rmd` do repositório GitHub.
   - Verificação dos arquivos baixados.
   - Instalação dos pacotes necessários (`shiny`, `rmarkdown`).
   - Execução do aplicativo Shiny em seu navegador padrão.

---

## Resolução de Problemas

### Mensagem de erro: `O R não foi encontrado.`
- Certifique-se de que o R está instalado no seguinte diretório:
  C:\Program Files\R\R-4.4.3\

### Mensagem de erro: `Versão do R incompatível.`
- A versão instalada do R não é 4.4.3. Instale a versão correta: [R 4.4.3 para Windows](https://cran.r-project.org/bin/windows/base/R-4.4.3-win.exe).

### Mensagem de erro: `Falha ao baixar o arquivo app.R ou relatorios.Rmd.`
- Caso o download dos arquivos não funcione, você pode baixá-los manualmente diretamente do repositório GitHub:
  - [Repositório Sisagua](https://github.com/vinialberici/sisagua).

---

## Observações

- Certifique-se de manter o script .bat no mesmo diretório onde os arquivos `app.R` e `relatorios.Rmd` serão baixados.
- Para perguntas ou suporte, entre em contato com o administrador do repositório.
