# 🔧 Assets: Estações de Reparo e Falhas

## Localização no Projeto:
- **Cena**: `res://scenes/repair_station.tscn`
- **Script**: `res://scripts/repair_station.gd`

## Tipos de Estação (conforme o rascunho):
1. **`terminal`**: Computador com monitor e antena nos níveis superiores.
2. **`cabo`**: Conexão elétrica que se rompe e solta faíscas.
3. **`bobina`**: Mola/bobina de pressão que salta ou superaquece (marcada com seta no desenho).
4. **`valvula`**: Registro de encanamento de vapor.

## Como Substituir o Visual:
1. Abra `res://scenes/repair_station.tscn`.
2. O nó `Visual` possui os elementos visuais configuráveis conforme a propriedade `station_type`.
3. Você pode substituir os retângulos por sprites correspondentes de cada equipamento.
