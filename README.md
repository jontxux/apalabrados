# Extraer y buscar palabra
- El diccionario lo creamos con el siguiente comando:
```bash
aspell -d es dump master | aspell -l es expand | perl -pe 's/\s//g' | \
perl -Mutf8::all -pe 'tr/áéíóú/aeiou/;' | sort | uniq > todas.txt
```

