
%option noyywrap
%option noinput
%option nounput
%option nodefault

%x NAPIS ZNAK
%x K_Linia K_Blok
%x Dok_Linia Dok_Blok

%{
#include <stdio.h>
#include <string.h>

/* Autor: Adam Sowinski */

/* Czy zachowujemy komentarze dokumentacyjne */
int zachowaj_doxygen = 0;
%}

%%
    /* Poczatek napisu */
\" {
    ECHO;
    BEGIN(NAPIS);
}

    /* Poczatek literalu znakowego */
"'" {
    ECHO;
    BEGIN(ZNAK);
}

    /* Pusty komentarz blokowy - szczegolny przypadek */
"/**/" {
    printf(" ");
}

    /* Komentarze dokumentacyjne jednoliniowe */
"///"|"//!" {
    if (zachowaj_doxygen) ECHO;
    BEGIN(Dok_Linia);
}

    /* Zwykly komentarz jednoliniowy */
"//" {
    BEGIN(K_Linia);
}

    /* Komentarze dokumentacyjne blokowe */
"/**"|"/*!" {
    if (zachowaj_doxygen) ECHO;
    else printf(" ");
    BEGIN(Dok_Blok);
}

    /* Zwykly komentarz blokowy */
"/*" {
    printf(" ");
    BEGIN(K_Blok);
}

    /* Pozostaly kod przepisujemy bez zmian */
.|\n {
    ECHO;
}

    /* Znaki specjalne w napisie, np. \" */
<NAPIS>\\(.|\n) {
    ECHO;
}

    /* Zwykle znaki napisu */
<NAPIS>[^\\\"\n]+ {
    ECHO;
}

    /* Koniec napisu */
<NAPIS>\" {
    ECHO;
    BEGIN(INITIAL);
}

    /* Koniec linii w niepoprawnym napisie */
<NAPIS>\n {
    ECHO;
    BEGIN(INITIAL);
}

    /* Znaki specjalne w literale znakowym */
<ZNAK>\\(.|\n) {
    ECHO;
}

    /* Zwykle znaki literalu */
<ZNAK>[^\\'\n]+ {
    ECHO;
}

    /* Koniec literalu znakowego */
<ZNAK>"'" {
    ECHO;
    BEGIN(INITIAL);
}

    /* Koniec linii w niepoprawnym literale */
<ZNAK>\n {
    ECHO;
    BEGIN(INITIAL);
}

    /* Pomijamy tresc zwyklego komentarza liniowego */
<K_Linia>[^\n]+ {
    /* Pomijamy komentarz */
}

    /* Koniec komentarza liniowego */
<K_Linia>\n {
    ECHO;
    BEGIN(INITIAL);
}

    /* Tresc komentarza dokumentacyjnego liniowego */
<Dok_Linia>[^\n]+ {
    if (zachowaj_doxygen) ECHO;
}

    /* Koniec komentarza dokumentacyjnego liniowego */
<Dok_Linia>\n {
    ECHO;
    BEGIN(INITIAL);
}

    /* Koniec zwyklego komentarza blokowego */
<K_Blok>"*/" {
    BEGIN(INITIAL);
}

    /* Zachowujemy konce linii w komentarzu */
<K_Blok>\n {
    ECHO;
}

    /* Pozostale znaki komentarza usuwamy */
<K_Blok>. {
    /* Pomijamy znak */
}

    /* Koniec komentarza dokumentacyjnego blokowego */
<Dok_Blok>"*/" {
    if (zachowaj_doxygen) ECHO;
    BEGIN(INITIAL);
}

    /* Zachowujemy konce linii */
<Dok_Blok>\n {
    ECHO;
}

    /* Tresc komentarza dokumentacyjnego */
<Dok_Blok>. {
    if (zachowaj_doxygen) ECHO;
}
%%

int main(int argc, char **argv) {
    /* Sprawdzamy opcje podana przy uruchomieniu */
    if (argc == 2 && strcmp(argv[1], "--keep-doxygen") == 0) {
        zachowaj_doxygen = 1;
    } else if (argc != 1) {
        fprintf(stderr, "Uzycie: %s [--keep-doxygen]\n", argv[0]);
        return 1;
    }

    /* Uruchomienie analizatora */
    yylex();

    return 0;
}
