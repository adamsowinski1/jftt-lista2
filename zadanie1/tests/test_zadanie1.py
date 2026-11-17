#!/usr/bin/env python3

"""Automatyczne testy zadania 1 we FLEX-ie. Uruchamiamy z katalogu zadanie1."""

# Biblioteki standardowe Pythona
import argparse       # obsluga argumentow podanych w terminalu, np. --random 1000
import random         # generowanie losowych przypadkow testowych
import re             # wyrazenia regularne - podobne do wzorcow we FLEX-ie
import subprocess     # uruchamianie z Pythona innych programow (make, lexer)
import sys            # zwracanie kodu zakonczenia programu
from pathlib import Path  # wygodna obsluga sciezek do plikow

# Litera b przed napisem oznacza bytes (bajty), a nie zwykly tekst str.
# Wzorzec slowa: ciag co najmniej jednego znaku innego niz bialy znak.
SLOWO = rb"[^ \t\r\n\f\v]+"


def oczekiwany_wynik(dane: bytes) -> bytes:
    """Wyliczamy poprawny wynik, z ktorym porownamy program FLEX."""
    gotowe_linie = []  # tu zapiszemy oczyszczone, niepuste linie
    liczba_slow = 0

    # Dzielimy wejscie na linie. b"\n" to znak konca linii zapisany jako bajt.
    for linia in dane.split(b"\n"):
        # Znajdujemy wszystkie slowa w aktualnej linii.
        slowa = re.findall(SLOWO, linia)

        # Pusta linia nie ma zadnych slow, wiec ja pomijamy.
        if slowa:
            # Laczymy slowa dokladnie jedna spacja.
            gotowe_linie.append(b" ".join(slowa))
            liczba_slow += len(slowa)

    # Laczymy pozostawione linie znakami nowej linii.
    tekst = b"\n".join(gotowe_linie)
    if gotowe_linie:
        tekst += b"\n"  # konczymy ostatnia niepusta linie

    # Dopisujemy podsumowanie; encode() zmienia tekst na bajty.
    podsumowanie = (
        f"\nLiczba linii: {len(gotowe_linie)}\n"
        f"Liczba slow: {liczba_slow}\n"
    ).encode("utf-8")
    return tekst + podsumowanie


def przypadki():
    """Recznie przygotowane przypadki, rowniez nietypowe i trudne."""
    return [
        ("pusty plik", b""),
        ("jedna litera bez Entera", b"a"),
        ("jedna litera z Enterem", b"a\n"),
        ("same spacje, taby i Entery", b" \t \n\n\t  \n"),
        ("spacje na poczatku i koncu", b"   Ala    ma kota   \n"),
        ("puste linie miedzy slowami", b"\n\n  Ala\n\n\n  kot  \n\n"),
        ("bez ostatniego Entera", b"Ala ma kota\n  ostatnie slowo"),
        ("windowsowe CRLF", b"  Ala\t ma  \r\n\r\n  kota  \r\n"),
        ("samotne CR i inne biale znaki", b"Ala\r\f\vma\t\tkota\n"),
        ("interpunkcja i cyfry to slowa", b"  ! ? 123 -1 x.y a  \n"),
        # Polskie litery kodujemy do UTF-8, bo litera b"..." przyjmuje tylko ASCII.
        ("polskie znaki UTF-8", "  żółw   gęś\tzażółć  \n".encode("utf-8")),
        ("bardzo dlugie slowo", b"a" * 20000 + b"  z\n"),
        (
            "TRUDNY: mieszane biale znaki, puste wiersze, CRLF, brak Entera",
            b" \t\r\f\v\n"
            b"\n"
            b" \t   Ala\t\tma   7!  \r\n"
            b"\t\r\n"
            b"  a\t b\f\v c \r\n"
            b"\r\f\v\n"
            + "\tżółw   !?  123".encode("utf-8"),
        ),
    ]


def losowe_przypadki(ile: int):
    """Tworzymy dodatkowe przypadki testowe z losowych slow i separatorow."""
    # Stale ziarno sprawia, ze za kazdym razem losujemy te same testy.
    rng = random.Random(20261117)
    atomy = [b"a", b"b", b"123", b"!", b"-1", "żółw".encode("utf-8")]
    biale = [b" ", b"\t", b"\r", b"\f", b"\v"]

    for numer in range(ile):
        linie = []
        # Losujemy liczbe wierszy: od 0 do 14.
        for _ in range(rng.randrange(0, 15)):
            # Losowe biale znaki na poczatku linii.
            linia = b"".join(rng.choice(biale) for _ in range(rng.randrange(0, 5)))
            # Doklejamy losowe slowa oraz biale znaki.
            for _ in range(rng.randrange(0, 12)):
                linia += rng.choice(atomy)
                linia += b"".join(rng.choice(biale) for _ in range(rng.randrange(0, 5)))
            linie.append(linia)

        dane = b"\n".join(linie)
        # Czasem ostatnia linia konczy sie Enterem, a czasem nie.
        if rng.choice([True, False]):
            dane += b"\n"

        # yield zwraca kolejny przypadek; funkcja moze potem generowac dalsze.
        yield (f"losowy #{numer + 1}", dane)


def pokaz(dane: bytes, limit: int = 400) -> str:
    """Wyswietlamy dane diagnostyczne, ucinajac bardzo dlugie teksty."""
    if len(dane) > limit:
        return f"{dane[:limit]!r} ... (lacznie {len(dane)} bajtow)"
    # repr pokazuje rowniez niewidoczne znaki, np. \n i \t.
    return repr(dane)


def main():
    # Odczytujemy opcje przekazane w terminalu.
    parser = argparse.ArgumentParser(description="Testy automatyczne zadania 1 FLEX")
    parser.add_argument("--program", default="build/lexer", help="sciezka do programu")
    parser.add_argument("--random", type=int, default=100, help="liczba testow losowych")
    parser.add_argument("--no-build", action="store_true", help="nie uruchamiaj make")
    args = parser.parse_args()

    # Najpierw kompilujemy program poleceniem make (chyba ze podano --no-build).
    if not args.no_build:
        budowanie = subprocess.run(["make"], capture_output=True, text=True)
        if budowanie.returncode != 0:
            print("BLAD: kompilacja sie nie powiodla:\n" + budowanie.stdout + budowanie.stderr)
            return 1

    # Sprawdzamy, czy istnieje skompilowany program FLEX.
    program = Path(args.program).resolve()
    if not program.is_file():
        print(f"BLAD: nie znaleziono programu {program}")
        return 1

    # Laczymy testy reczne z losowymi.
    testy = przypadki() + list(losowe_przypadki(max(0, args.random)))
    zaliczone = 0

    # Kazdy test uruchamia program FLEX jako osobny proces.
    for nazwa, dane in testy:
        try:
            wynik = subprocess.run(
                [str(program)],   # plik wykonywalny FLEX-a
                input=dane,       # dane testowe przekazane na standardowe wejscie
                capture_output=True,  # przechwytujemy stdout oraz stderr
                timeout=5,        # maksymalnie 5 sekund na test
            )
        except subprocess.TimeoutExpired:
            print(f"[BLAD] {nazwa}: przekroczono 5 sekund")
            return 1

        oczekiwane = oczekiwany_wynik(dane)

        # Kod zakonczenia powinien wynosic 0, a wynik musi byc identyczny bajt po bajcie.
        if wynik.returncode != 0 or wynik.stdout != oczekiwane:
            print(f"[BLAD] {nazwa}")
            print("WEJSCIE:    ", pokaz(dane))
            print("OCZEKIWANO: ", pokaz(oczekiwane))
            print("OTRZYMANO:  ", pokaz(wynik.stdout))
            print("KOD WYJSCIA:", wynik.returncode)
            if wynik.stderr:
                print("STDERR:     ", pokaz(wynik.stderr))
            print(f"Zaliczone przed bledem: {zaliczone}/{len(testy)}")
            return 1

        print(f"[OK] {nazwa}")
        zaliczone += 1

    # Jesli doszlismy tutaj, wszystkie przypadki przeszly pomyslnie.
    print(f"\nWszystko OK: {zaliczone}/{len(testy)} testow.")
    return 0


# Ten warunek uruchamia main() tylko przy bezposrednim uruchomieniu pliku.
if __name__ == "__main__":
    sys.exit(main())