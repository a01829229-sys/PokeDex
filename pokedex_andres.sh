#!/bin/bash

# Verificar que jq esté instalado
if ! command -v jq >/dev/null 2>&1; then
    echo "Error: necesitas instalar jq." >&2
    exit 1
fi

# Verificar que se haya indicado un Pokémon
if [ -z "${1:-}" ]; then
    echo "Uso: $0 nombre_o_numero_del_pokemon" >&2
    exit 1
fi

# Aceptar nombres en mayúsculas y minúsculas
nombre=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')

# Consultar la API y separar el JSON del código HTTP
respuesta=$(curl -sS -w '\n%{http_code}' "https://pokeapi.co/api/v2/pokemon/$nombre") || {
    echo "Error: no se pudo conectar con PokeAPI." >&2
    exit 1
}

codigo=${respuesta##*$'\n'}
pokemon=${respuesta%$'\n'*}

if [ "$codigo" = "404" ]; then
    echo "No encontrado: $nombre"
    exit 1
fi

if [ "$codigo" != "200" ]; then
    echo "Error HTTP: $codigo" >&2
    exit 1
fi

if ! printf '%s' "$pokemon" | jq -e . >/dev/null 2>&1; then
    echo "Error: la API no devolvió un JSON válido." >&2
    exit 1
fi

# Mostrar los datos y las seis estadísticas
printf '\n========================================\n'
printf '                POKÉDEX\n'
printf '========================================\n'

printf '%s\n' "$pokemon" | jq -r '
    "#\(.id) - \(.name)",
    "",
    "Altura: \(.height / 10) m",
    "Peso:   \(.weight / 10) kg",
    "Tipos:  \([.types[].type.name] | join(", "))",
    "",
    "------------ ESTADÍSTICAS --------------",
    (.stats[] | "\(.stat.name): \(.base_stat)")
'

# Conservar la consulta de Pokémon del mismo tipo
tipo=$(printf '%s' "$pokemon" | jq -r '.types[0].type.name')

printf '\n------ PRIMEROS 20 DEL TIPO %s ------\n' "$tipo"

respuesta_tipo=$(curl -sS -f "https://pokeapi.co/api/v2/type/$tipo") || {
    echo "Error: no se pudo consultar la lista del tipo $tipo." >&2
    exit 1
}

if ! printf '%s' "$respuesta_tipo" |
    jq -r '.pokemon[:20][] | .pokemon.name'; then
    echo "Error: no se pudo procesar la lista de Pokémon." >&2
    exit 1
fi

printf '========================================\n'
