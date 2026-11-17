
%option noyywrap
%option noinput
%option nounput
%option nodefault

%x NAPIS

%{
#include <stdio.h>

/* Autor: Adam Sowinski */
%}

%%
    /* Poczatek napisu - przechodzimy do stanu NAPIS */
\" {
    ECHO;
    BEGIN(NAPIS);
}

    /* Komentarz Ada - pomijamy wszystko do konca linii */
--[^\r\n]* {
    /* Usuwamy komentarz */
}

    /* Pozostale znaki i konce linii przepisujemy */
.|\n {
    ECHO;
}

    /* Dwa cudzyslowy w napisie oznaczaja jeden znak " */
<NAPIS>\"\" {
    ECHO;
}

    /* Koniec napisu - wracamy do stanu poczatkowego */
<NAPIS>\" {
    ECHO;
    BEGIN(INITIAL);
}

    /* Zwykle znaki wewnatrz napisu */
<NAPIS>[^"\n]+ {
    ECHO;
}

    /* Koniec linii wewnatrz napisu - niepoprawny napis Ada */
<NAPIS>\n {
    ECHO;
    BEGIN(INITIAL);
}
%%

int main(void) {
    /* Uruchomienie analizatora */
    yylex();

    return 0;
}
