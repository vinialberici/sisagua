@echo off
chcp 65001 >nul

REM Caminho para o Rscript.exe
set RSCRIPT="C:\Program Files\R\R-4.4.3\bin\Rscript.exe"

REM Diretório do script .bat
set CURRENT_DIR=%~dp0

REM Definir biblioteca pessoal do usuário
set R_LIBS_USER=C:/Users/%USERNAME%/R/win-library/4.4

REM Criar a biblioteca se não existir
if not exist "%R_LIBS_USER%" (
    echo Criando biblioteca pessoal em %R_LIBS_USER%...
    mkdir "%R_LIBS_USER%"
)

REM Links para os arquivos no GitHub
set APP_URL=https://raw.githubusercontent.com/vinialberici/sisagua/main/app.R
set REPORT_URL=https://raw.githubusercontent.com/vinialberici/sisagua/main/relatorios.Rmd

REM Verificar se o R está instalado
echo Verificando se o R está instalado...
if not exist %RSCRIPT% (
    echo [ERRO] O R não foi encontrado.
    echo Instale o R: https://cran.r-project.org/bin/windows/base/R-4.4.3-win.exe.
    pause
    exit /b
)

REM Verificar a versão do R
%RSCRIPT% --version | findstr "4.4.3" >nul
if %ERRORLEVEL% neq 0 (
    echo [ERRO] Versão do R incompatível.
    echo Instale a versão correta: https://cran.r-project.org/bin/windows/base/R-4.4.3-win.exe
    pause
    exit /b
)

REM Baixar arquivos do GitHub
echo Baixando arquivos mais recentes do GitHub...
curl -s -o "%CURRENT_DIR%app.R" %APP_URL%
if %ERRORLEVEL% neq 0 (
    echo [ERRO] Falha ao baixar o arquivo app.R.
    pause
    exit /b
)

curl -s -o "%CURRENT_DIR%relatorios.Rmd" %REPORT_URL%
if %ERRORLEVEL% neq 0 (
    echo [ERRO] Falha ao baixar o arquivo relatorios.Rmd.
    pause
    exit /b
)

REM Verificar a existência dos arquivos necessários
echo Verificando a existência dos arquivos necessários...
set FILES_TO_CHECK=app.R relatorios.Rmd
for %%F in (%FILES_TO_CHECK%) do (
    if not exist "%CURRENT_DIR%%%F" (
        echo [ERRO] O arquivo %%F não foi encontrado no diretório: %CURRENT_DIR%
        pause
        exit /b
    ) else (
        echo O arquivo %%F foi encontrado.
    )
)
echo.

REM Converter barras invertidas para barras normais no caminho do app
set RSCRIPT_FILE=%CURRENT_DIR:\=/% 

REM Instalar e carregar os pacotes necessários
echo Instalando e carregando os pacotes necessários...
%RSCRIPT% -e "options(repos = 'https://cloud.r-project.org'); .libPaths('%R_LIBS_USER%'); if (!requireNamespace('shiny', quietly = TRUE)) suppressMessages(install.packages('shiny', lib = '%R_LIBS_USER%')); if (!requireNamespace('rmarkdown', quietly = TRUE)) suppressMessages(install.packages('rmarkdown', lib = '%R_LIBS_USER%'))"

REM Executar o app shiny
echo Tudo pronto! Iniciando o programa...
%RSCRIPT% -e "options(repos = 'https://cloud.r-project.org'); .libPaths('%R_LIBS_USER%'); suppressMessages(shiny::runApp('%RSCRIPT_FILE%', launch.browser = TRUE))"

pause