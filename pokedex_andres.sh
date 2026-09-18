#!/usr/bin/env bash

if ! command -v jq >/dev/null 2>&1; then
    echo "Error: necesitas instalar jq" >&2
    exit 1
fi

if [ -z "${1:-}" ]; then
    echo "Uso: $0 nombre_del_pokemon"
    exit 1
fi

nombre=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')

respuesta=$(curl -sS -w '\n%{http_code}' "https://pokeapi.co/api/v2/pokemon/$nombre") || exit 1
codigo=${respuesta##*$'\n'}
pokemon=${respuesta%$'\n'*}

if [ "$codigo" = "404" ]; then
    echo "No encontrado"
    exit 1
fi

if [ "$codigo" != "200" ]; then
    echo "Error HTTP: $codigo" >&2
    exit 1
fi

printf '%s\n' "$pokemon" | jq -r '
    "ID: \(.id)",
    "Nombre: \(.name)",
    "Altura: \(.height)",
    "Peso: \(.weight)",
    "Tipos: \([.types[].type.name] | join(", "))"
'

tipo=$(printf '%s\n' "$pokemon" | jq -r '.types[0].type.name')

printf '\nPrimeros 20 pokemon del tipo %s:\n' "$tipo"
curl -fsS "https://pokeapi.co/api/v2/type/$tipo" |
    jq -r '.pokemon[:20][].pokemon.name'
