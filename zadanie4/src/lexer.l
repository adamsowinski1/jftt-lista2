
%option noyywrap
%option noinput
%option nounput
%option nodefault

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <limits.h>

/* Autor: Adam Sowinski */

/* Stos przechowujacy liczby */
long long *stos = NULL;
size_t rozmiar = 0;
size_t pojemnosc = 0;

/* Informacje o aktualnej linii */
int blad = 0;
int w_linii = 0;
char komunikat[256];

/* Zapamietujemy pierwszy blad w linii */
void ustaw_blad(const char *tekst) {
    if (!blad) {
        blad = 1;
        snprintf(komunikat, sizeof(komunikat), "%s", tekst);
    }
}

/* Dodajemy liczbe na stos */
void push(long long liczba) {
    if (blad) return;

    /* Powiekszamy stos, gdy zabraknie miejsca */
    if (rozmiar == pojemnosc) {
        size_t nowa = pojemnosc ? pojemnosc * 2 : 16;

        if (nowa < pojemnosc ||
            nowa > (size_t)-1 / sizeof(long long)) {
            ustaw_blad("brak pamieci");
            return;
        }

        long long *tmp = realloc(stos, nowa * sizeof(long long));

        if (tmp == NULL) {
            ustaw_blad("brak pamieci");
            return;
        }

        stos = tmp;
        pojemnosc = nowa;
    }

    stos[rozmiar++] = liczba;
}

/* Obliczamy potege dla wykladnika nieujemnego */
int potega(long long a, long long b, long long *wynik) {
    if (b < 0) {
        ustaw_blad("ujemny wykladnik potegi");
        return 0;
    }

    __int128 rezultat = 1;
    __int128 podstawa = a;

    /* Potegowanie przez szybkie podnoszenie do kwadratu */
    while (b > 0) {
        if (b % 2 == 1) {
            rezultat *= podstawa;

            if (rezultat > LLONG_MAX || rezultat < LLONG_MIN) {
                ustaw_blad("przepelnienie liczby calkowitej");
                return 0;
            }
        }

        b /= 2;

        if (b > 0) {
            podstawa *= podstawa;

            if (podstawa > LLONG_MAX || podstawa < LLONG_MIN) {
                ustaw_blad("przepelnienie liczby calkowitej");
                return 0;
            }
        }
    }

    *wynik = (long long)rezultat;
    return 1;
}

/* Wykonujemy operacje na dwoch liczbach ze stosu */
void wykonaj(char operator) {
    if (blad) return;

    /* Kazdy operator wymaga dwoch argumentow */
    if (rozmiar < 2) {
        ustaw_blad("za mala liczba argumentow");
        return;
    }

    long long b = stos[--rozmiar];
    long long a = stos[--rozmiar];

    long long wynik = 0;
    __int128 pomocniczy = 0;

    switch (operator) {
        case '+':
            pomocniczy = (__int128)a + b;
            break;

        case '-':
            pomocniczy = (__int128)a - b;
            break;

        case '*':
            pomocniczy = (__int128)a * b;
            break;

        case '/':
            if (b == 0) {
                ustaw_blad("dzielenie przez zero");
                return;
            }

            if (a == LLONG_MIN && b == -1) {
                ustaw_blad("przepelnienie liczby calkowitej");
                return;
            }

            wynik = a / b;
            push(wynik);
            return;

        case '%':
            if (b == 0) {
                ustaw_blad("modulo przez zero");
                return;
            }

            if (a == LLONG_MIN && b == -1) {
                ustaw_blad("przepelnienie liczby calkowitej");
                return;
            }

            wynik = a % b;
            push(wynik);
            return;

        case '^':
            if (potega(a, b, &wynik)) {
                push(wynik);
            }
            return;
    }

    /* Kontrola zakresu wyniku */
    if (pomocniczy > LLONG_MAX || pomocniczy < LLONG_MIN) {
        ustaw_blad("przepelnienie liczby calkowitej");
        return;
    }

    push((long long)pomocniczy);
}

/* Wypisujemy wynik lub blad po zakonczeniu linii */
void zakoncz_linie(void) {
    if (blad) {
        printf("Blad: %s\n", komunikat);
    } else if (rozmiar == 0) {
        printf("Blad: puste wyrazenie lub brak argumentow\n");
    } else if (rozmiar > 1) {
        printf("Blad: za mala liczba operatorow\n");
    } else {
        printf("= %lld\n", stos[0]);
    }

    /* Przygotowujemy stos do nastepnej linii */
    rozmiar = 0;
    blad = 0;
    w_linii = 0;
    komunikat[0] = '\0';
}
%}

%%
    /* Liczba calkowita dodatnia lub ujemna */
-?[0-9]+ {
    w_linii = 1;

    if (!blad) {
        errno = 0;
        char *koniec;
        long long liczba = strtoll(yytext, &koniec, 10);

        if (errno == ERANGE || *koniec != '\0') {
            ustaw_blad("liczba poza zakresem");
        } else {
            push(liczba);
        }
    }
}

    /* Operatory arytmetyczne */
[+*/%^]|"-" {
    w_linii = 1;

    if (!blad) {
        wykonaj(yytext[0]);
    }
}

    /* Spacje, tabulatory i powroty karetki */
[ \t\r]+ {
    w_linii = 1;
}

    /* Koniec linii - wypisujemy wynik lub blad */
\n {
    zakoncz_linie();
}

    /* Dowolny nierozpoznany znak */
. {
    w_linii = 1;

    if (!blad) {
        char tekst[256];
        snprintf(tekst, sizeof(tekst),
                 "zly symbol \"%s\"", yytext);
        ustaw_blad(tekst);
    }
}

    /* Koniec pliku bez ostatniego Entera */
<<EOF>> {
    if (w_linii) {
        zakoncz_linie();
    }

    yyterminate();
}
%%

int main(void) {
    /* Uruchomienie analizatora */
    yylex();

    /* Zwolnienie pamieci stosu */
    free(stos);

    return 0;
}
