#!/bin/bash

# Verificar que se reciba exactamente un argumento
if [ "$#" -ne 1 ]; then
    echo "Uso: $0 nombre_o_numero"
    exit 1
fi

# Convertir el nombre a minusculas
pokemon="${1,,}"

# Verificar que curl y jq esten instalados
for comando in curl jq; do
    if ! command -v "$comando" >/dev/null 2>&1; then
        echo "Error: necesitas instalar $comando"
        exit 1
    fi
done

# Consultar PokeAPI
url="https://pokeapi.co/api/v2/pokemon/$pokemon"

respuesta=$(curl -sS -L --connect-timeout 10 --max-time 30 \
    -w '\n%{http_code}' "$url") || {
    echo "Error: no se pudo conectar con PokeAPI"
    exit 1
}

# Separar el codigo HTTP del JSON
codigo="${respuesta##*$'\n'}"
json="${respuesta%$'\n'*}"

# Comprobar la respuesta HTTP
if [ "$codigo" = "404" ]; then
    echo "No encontrado: $pokemon (HTTP 404)"
    exit 1
fi

if [ "$codigo" != "200" ]; then
    echo "Error: la API devolvio HTTP $codigo"
    exit 1
fi

# Comprobar que el JSON sea valido y tenga los campos necesarios
if ! jq -e '
    (.id | type == "number") and
    (.name | type == "string") and
    (.height | type == "number") and
    (.weight | type == "number") and
    (.types | type == "array") and
    (.stats | type == "array")
' >/dev/null 2>&1 <<< "$json"; then
    echo "Error: respuesta JSON invalida o incompleta"
    exit 1
fi

# Aceptar Pokemon que tengan water entre sus tipos
if ! jq -e '
    any(.types[]; .type.name == "water")
' >/dev/null <<< "$json"; then
    echo "Este Pokemon no es de tipo agua"
    exit 1
fi

# Mostrar la informacion
jq -r '
    "#\(.id) \(.name)",
    "",
    "Altura: \(.height / 10) m",
    "Peso: \(.weight / 10) kg",
    "Tipos: \([.types[] | .type.name] | join(", "))",
    "",
    "Stats:",
    (.stats[] | "\(.stat.name): \(.base_stat)")
' <<< "$json"
