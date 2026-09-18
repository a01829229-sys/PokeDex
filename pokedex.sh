
#!/bin/bash

# URL base de PokeAPI
BASE_URL="https://pokeapi.co/api/v2/type"

# Validar que se proporcione un argumento
if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
        echo "Uso: $0 fire [cantidad]"
        exit 1
fi

# Convertir el argumento a minúsculas
TIPO="${1,,}"

# Validar que el tipo sea fuego
if [ "$TIPO" != "fire" ]; then
	echo "Error: Este programa solo consulta el tipo fire."
	exit 1
fi

CANTIDAD="${2:-10}"

# Validar que sea un número del 1 al 20
if ! [[ "$CANTIDAD" =~ ^([1-9]|1[0-9]|20)$ ]]; then
        echo "Error: La cantidad debe ser un número entre 1 y 20."
        exit 1
fi

# Realizar la petición a la API
RESPUESTA=$(curl -sS -w '\n%{http_code}' \
	"$BASE_URL/$TIPO")

# Verificar si curl pudo realizar la petición
if [ "$?" -ne 0 ]; then
	echo "Error: No se pudo conectar con la API."
	exit 1
fi

# Separar el código HTTP del JSON
HTTP_CODE="${RESPUESTA##*$'\n'}"
JSON="${RESPUESTA%$'\n'*}"

# Validar el código HTTP
if [ "$HTTP_CODE" -eq 404 ]; then
	echo "Error 404: Tipo de Pokémon no encontrado."
	exit 1
elif [ "$HTTP_CODE" -ne 200 ]; then
	echo "Error HTTP: $HTTP_CODE"
	exit 1
fi

# Comprobar que la respuesta sea JSON válido
if ! printf '%s' "$JSON" | jq empty 2>/dev/null; then
	echo "Error: La respuesta no es un JSON válido."
	exit 1
fi

# Mostrar la información
echo "=============================="
echo "       POKÉDEX - FUEGO"
echo "=============================="
echo "Tipo consultado: $TIPO"
echo ""
echo "Primeros $CANTIDAD Pokémon:"
echo "------------------------------"

# Extraer y mostrar los primeros 10 Pokémon
CONTADOR=1

while IFS= read -r POKEMON; do
	printf '%d. %s\n' "$CONTADOR" "$POKEMON"
	CONTADOR=$((CONTADOR + 1))
done < <(
	printf '%s' "$JSON" | jq -r --argjson cantidad "$CANTIDAD" '.pokemon[:$cantidad][].pokemon.name'
)

echo ""
echo "Consulta completada correctamente."

exit 0
