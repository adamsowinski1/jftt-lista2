
%option noyywrap
%option noinput
%option nounput

%{
#include <stdio.h>

/* Autor: Adam Sowinski */

/* Liczba slow i niepustych linii */
unsigned long long liczba_slow = 0;
unsigned long long liczba_linii = 0;

/* Czy w aktualnej linii wystapilo juz slowo */
int czy_slowo = 0;
%}

%%
    /* Ciag spacji lub tabulatorow i innych bialych znakow poza \n */
[ \t\r\f\v]+  { /* Pomijamy biale znaki */ }

    /* Ciag znakow niebedacych bialymi znakami */
[^ \t\r\n\f\v]+ {
    /* Spacja tylko pomiedzy slowami */
    if (czy_slowo) {
        printf(" ");
    }

    printf("%s", yytext);
    liczba_slow++;
    czy_slowo = 1;
}

    /* Koniec linii */
\n {
    /* Wypisujemy tylko niepuste linie */
    if (czy_slowo) {
        printf("\n");
        liczba_linii++;
    }

    czy_slowo = 0;
}

    /* Koniec pliku */
<<EOF>> {
    /* Ostatnia linia moze nie konczyc sie znakiem \n */
    if (czy_slowo) {
        printf("\n");
        liczba_linii++;
    }

    printf("\nLiczba linii: %llu\n", liczba_linii);
    printf("Liczba slow: %llu\n", liczba_slow);

    return 0;
}
%%

int main(void) {
    /* Uruchomienie analizatora */
    yylex();

    return 0;
}
