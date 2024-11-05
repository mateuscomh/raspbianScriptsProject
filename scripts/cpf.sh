#!/bin/bash
# Script validador de documentos
#
# The MIT License (MIT)
# Copyright (c) 2012 Gabriel Fernandes
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# Calculadores

function calcularDvCPF() {
        # $1 deve ser um CPF de 9 dígitos sem traços e pontos, apenas números.
        local i soma dv1 dv2 cpfDv1;

        if [ ${#1} -eq 9 ]; then
                # Calcula o primeiro dv
                for ((i=0; i < ${#1} ; i++)); do
                        soma=$((soma + ${1:$i:1} * (i + 1)));
                done;
                dv1=$(expr $soma % 11);
                [ $dv1 -ge 10 ] && dv1=0;
                # Calcula o segundo dv
                cpfDv1=$1$dv1;
                soma=0;
                for ((i=1; i < ${#cpfDv1} ; i++)); do
                        soma=$((soma + ${cpfDv1:$i:1} * i));
                done;
                dv2=$(expr $soma % 11);
                [ $dv2 -ge 10 ] && dv2=0;
                # Retorna dv gerado
                echo "$dv1$dv2";
                return;
        else
                echo "$1 deve ser um CPF de 9 dígitos sem traços e pontos, apenas números.";
                return 1;
        fi;
}

function calcularDvCNPJ() {
        # $1 deve ser um CNPJ de 12 dígitos(sem o dígito verificador) sem traços e pontos, apenas números.
  local base soma dv1 cnpjDv1 dv2;

        if [ ${#1} -eq 12 ]; then
                # Calcula o primeiro dv
                base=9;
                for ((i=${#1} - 1; i >= 0 ; i--)); do
                        soma=$((soma + ${1:i:1} * base));
                        base=$((base - 1));
                        [ $base -eq 1 ] && base=9;
                done
                dv1=$(expr $soma % 11);
                [ $dv1 -ge 10 ] && dv1=0;
                # Calcula o segundo dv
                cnpjDv1=$1$dv1;
                soma=0;
                base=9;
                for ((i=${#cnpjDv1} - 1; i >= 0 ; i--)); do
                        soma=$((soma + ${cnpjDv1:i:1} * base));
                        base=$((base - 1));
                        [ $base -eq 1 ] && base=9;
                done
                dv2=$(expr $soma % 11);
                [ $dv2 -ge 10 ] && dv2=0;
                # Retorna dv gerado
                echo "$dv1$dv2";
                return;
        else
                echo "$1 deve ser um CNPJ de 12 dígitos sem traços e pontos, apenas números.";
                return 1;
        fi;
}

function calcularDvNumCheque() {
        # $1 deve ser um Cheque de 6 dígitos(sem o dígito verificador dv3) sem traços e pontos, apenas números.
        local base soma dv;

        if [ ${#1} -eq 6 ]; then
                base=2;
                for ((i=${#1}-1; i >= 0 ; i--)); do
                        soma=$((soma + ${1:i:1} * base));
                        base=$((base + 1));
                        [ $base -eq 10 ] && base=2;
                done
                dv=$(expr $soma % 11);
                #todo: -lt ou -le??
                if [ $dv -lt 2 ]; then dv=0; else       dv=$((11 - dv)); fi;

                echo "$dv";
                return;
        else
                echo "$1 deve ser um Número de Cheque de 6 dígitos sem traços e pontos, apenas números.";
                return 1;
        fi;
}

function calcularDvPIS(){
        # $1 deve ser um PIS de 10 dígitos(sem o dígito verificador) sem traços e pontos, apenas números.
        local base soma dv;

        if [ ${#1} -eq 10 ]; then
                base=2;
                for ((i=${#1}-1; i >= 0 ; i--)); do
                        soma=$((soma + ${1:i:1} * base));
                        base=$((base + 1));
                        [ $base -eq 10 ] && base=2;
                done
                dv=$((11 - $(expr $soma % 11)));
                [ $dv -ge 10 ] && dv=0;

                echo "$dv";
                return;
        else
                echo "$1 deve ser um PIS de 10 dígitos sem traços e pontos, apenas números.";
                return 1;
        fi;
}

function calcularDvCartaoCredito() {
        # $1 deve ser um CRT CRED com 13 dígitos(sem o dígito verificador) sem traços e pontos, apenas números.
        local base soma dv;

        if [ ${#1} -eq 13 ]; then
                base=2;
                for ((i=0; i < ${#1} ; i++)); do
                        valor=$((${1:$i:1} * base));
                        [ $valor -gt 9 ] && valor=$((valor - 9));
                        soma=$((soma + valor));
                        base=$((base - 1));
                        [ $base -eq 0 ] && base=2;
                done;
                dv=0;
                fator=0;
                until [ $dv -gt 0 ]; do
                  dv=$((fator - soma));
                fator=$((fator + 10));
                done;
                [ $dv -ge 10 ] && dv=0;

                echo "$dv";
                return;
        else
                echo "$1 deve ser um CRT CRED com 13 dígitos(sem o dígito verificador) sem traços e pontos, apenas números.";
                return 1;
        fi;
}

# Geradores

function gerarCPF() {
    # Gera um CPF aleatório ou usa um CPF de 9 dígitos fornecido como argumento.
    local i cpf cpfCompleto

    if [ ${#1} -eq 9 ]; then
        cpf=$1
        echo "CPF base fornecido: $cpf"
    else
        echo "Gerando um CPF aleatório..."
        for ((i=0; i<9; i++)); do
            cpf="$cpf$((RANDOM % 10))"  # Gera 9 dígitos aleatórios
        done
        echo "CPF base gerado: $cpf"
    fi

    # Calcula o dígito verificador usando a função calcularDvCPF
    dv=$(calcularDvCPF "$cpf")
    cpfCompleto="$cpf$dv"

    echo "Dígito verificador calculado: $dv"
    echo "CPF completo gerado: $cpfCompleto"
                return

    # Valida o CPF gerado
    if [ "$(validarCPF $cpfCompleto)" == "$cpfCompleto" ]; then
        echo "O CPF $cpfCompleto é válido!"
                                exit 0
    else
        echo "Erro: O CPF $cpfCompleto não é válido!"
                                exit 1
    fi

}


function gerarCNPJ() {
        # $1 deve ser um CNPJ de 12 dígitos(sem o dígito verificador) sem traços e pontos, apenas números
  # ou um número X de 0 até 9999 para gerar um CNPJ aleatório com filial X
  # ou nada para gerar um CNPJ aleatório
  local i cnpj filial;

        if [ ${#1} -eq 12 ]; then
                # Gera o digito do CNPJ informado
                echo $1$(calcularDvCNPJ $1);
                return;
        elif [ ${#1} -le 4 ]; then
                # Cria aleatóriamente a raiz do CNPJ concatena com a filial
                filial=$1;
                while [ ${#filial} -lt 4 ]; do
                        filial="0$filial";
                done;
                for ((i=0; i<8; i++)); do
                        cnpj="$cnpj$((RANDOM % 9))"
                done;
                echo $cnpj$filial$(calcularDvCNPJ $cnpj$filial);
                return;
        else
                # Cria aleatóriamente todo o conteúdo do CNPJ
                for ((i=0; i<12; i++)); do
                        cnpj="$cnpj$((RANDOM % 9))"
                done;
                echo $cnpj$(calcularDvCNPJ $cnpj);
                return;
        fi
}

function gerarNumCheque() {
        # $1 deve ser um Cheque de 6 dígitos(sem o dígito verificador dv3) sem traços e pontos, apenas números.
  # ou nada para gerar um Cheque aleatório
  local i cheque;

        if [ ${#1} -eq 6 ]; then
                echo $1$(calcularDvNumCheque $1);
                return;
        else
                for ((i=0; i<6; i++)); do
                        cheque="$cheque$((RANDOM % 9))"
                done;
                echo $cheque$(calcularDvNumCheque $cheque);
                return;
        fi
}

function gerarPIS() {
        # $1 deve ser um PIS de 10 dígitos(sem o dígito verificador) sem traços e pontos, apenas números.
  # ou nada para gerar um Cheque aleatório
  local i pis;

        if [ ${#1} -eq 10 ]; then
                echo $1$(calcularDvPIS $1);
                return;
        else
                for ((i=0; i<10; i++)); do
                        cheque="$cheque$((RANDOM % 9))"
                done;
                echo $cheque$(calcularDvPIS $cheque);
                return;
        fi
}

function gerarCartaoCredito() {
        # $1 deve ser um CRT CRED com 13 dígitos(sem o dígito verificador) sem traços e pontos, apenas números.
  # ou nada para gerar um Cheque aleatório
  local i crtCre;

        if [ ${#1} -eq 13 ]; then
                echo $1$(calcularDvCartaoCredito $1);
                return;
        else
                for ((i=0; i<13; i++)); do
                        crtCre="$crtCre$((RANDOM % 9))"
                done;
                echo $crtCre$(calcularDvCartaoCredito $crtCre);
                return;
        fi
}

# Validadores

function validarCPF() {
        # Se for válido retorna ele mesmo e se não for válido não há retorno.
        # $1 deve ser um CPF de 11 dígitos(com o dígito verificador) sem traços e pontos, apenas números.
        [ "$1" == "$(gerarCPF ${1:0:9})" ] && echo "$1";
        exit 0
}

function validarCNPJ() {
        # Se for válido retorna ele mesmo e se não for válido não há retorno.
        # $1 deve ser um CNPJ de 14 dígitos(com o dígito verificador) sem traços e pontos, apenas números.
        [ "$1" == "$(gerarCNPJ ${1:0:12})" ] && echo "$1";
}

function validarNumCheque() {
        # Se for válido retorna ele mesmo e se não for válido não há retorno.
        # $1 deve ser um Cheque de 7 dígitos(com o dígito verificador dv3) sem traços e pontos, apenas números.
        [ "$1" == "$(gerarNumCheque ${1:0:6})" ] && echo "$1";
}

function validarPIS(){
        # Se for válido retorna ele mesmo e se não for válido não há retorno.
        # $1 deve ser um PIS de 11 dígitos(com o dígito verificador) sem traços e pontos, apenas números.
        [ "$1" == "$(gerarPIS ${1:0:10})" ] && echo "$1";
}

function validarCartaoCredito(){
        # Se for válido retorna ele mesmo e se não for válido não há retorno.
        # $1 deve ser um CRT CRED de 14 dígitos(com o dígito verificador) sem traços e pontos, apenas números.
        [ "$1" == "$(gerarCartaoCredito ${1:0:13})" ] && echo "$1";
}

function validar() {
        # $1 deve ser um documento qualquer sem traços e pontos, apenas números.
        # este algorítimo tenta descobrir o tipo de código
        local tipo;
        tipo="Nenhum";
        [ "$(validarCPF $1)"  == "$1" ] && tipo="CPF";
        [ "$tipo" == "Nenhum" ] && [ "$(validarPIS $1)"  == "$1" ] && tipo="PIS";
        [ "$tipo" == "Nenhum" ] && [ "$(validarCNPJ $1)" == "$1" ] && tipo="CNPJ";
        [ "$tipo" == "Nenhum" ] && [ "$(validarCartaoCredito $1)" == "$1"  ] && tipo="CartaoCredito";
        [ "$tipo" == "Nenhum" ] && [ "$(validarNumCheque $1)" == "$1" ] && tipo="Cheque";
        echo "$tipo";
        return;
}

if [ "$1" ]; then
        case "$1" in
                -h | --help)
                        echo "Tente $0 funcao parametro1 parametro2 ... parametroN parametroN+1";
                        echo "";
                        echo "Funções disponíveis:";
                        grep function $0 | cut -d " " -f2 | tr "(){" " ";
                        echo "        [ by Gabriel Fernandes gabriel@duel.com.br ]";
      echo "        [      under GPLv2 and no warranties       ]";
                ;;
                # $1 deve ser um nome de uma função existente
                *)
                        funcao="$1";
                        if type $funcao >/dev/null 2>&1 ; then
                                shift;
                                $funcao "$@"
                        else
                                echo "$funcao deve ser uma função existente.";
                        fi;
                ;;
        esac;
fi

