#!/bin/bash
# Script per verificare la presenza di dati sensibili prima del commit

echo "🔍 Controllo file per dati sensibili..."
echo ""

# Pattern da cercare (case insensitive)
PATTERNS=(
    "password[[:space:]]*=[[:space:]]*[^{\$]"
    "token[[:space:]]*=[[:space:]]*[^{\$]"
    "key[[:space:]]*=[[:space:]]*[^{\$]"
    "secret[[:space:]]*=[[:space:]]*[^{\$]"
    "api_key[[:space:]]*=[[:space:]]*[^{\$]"
    "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"
    "parroz4"
    "@hotmail"
    "cloudflare.*=[[:space:]]*[a-zA-Z0-9]{20,}"
)

FOUND_ISSUES=0
FILES=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null)

if [ -z "$FILES" ]; then
    echo "ℹ️  Nessun file in staging da controllare"
    exit 0
fi

for file in $FILES; do
    if [ -f "$file" ]; then
        for pattern in "${PATTERNS[@]}"; do
            if grep -qiE "$pattern" "$file" 2>/dev/null; then
                echo "⚠️  ATTENZIONE: Possibile dato sensibile in: $file"
                echo "   Pattern trovato: $pattern"
                echo ""
                FOUND_ISSUES=1
            fi
        done
    fi
done

if [ $FOUND_ISSUES -eq 0 ]; then
    echo "✅ Nessun dato sensibile rilevato"
    echo ""
else
    echo "❌ TROVATI DATI SENSIBILI!"
    echo ""
    echo "Azioni consigliate:"
    echo "1. Rimuovi i file con: git reset HEAD <file>"
    echo "2. Sposta i dati sensibili in file .env"
    echo "3. Usa variabili d'ambiente: \${NOME_VARIABILE}"
    echo "4. Aggiungi il file a .gitignore se necessario"
    echo ""
    exit 1
fi

exit 0
