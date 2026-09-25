# 🧑‍🚀 Assets: Jogadores (Player 1 e Player 2)

## Localização no Projeto:
- **Cena**: `res://scenes/player.tscn`
- **Script**: `res://scripts/player.gd`

## Configuração:
- Na cena principal (`res://scenes/main.tscn`), temos duas instâncias de `player.tscn`:
  - `Player1` com `player_id = 1` (Controles WASD + E)
  - `Player2` com `player_id = 2` (Controles Setas + Enter)

## Como Substituir o Visual:
1. Abra `res://scenes/player.tscn`.
2. No nó `Visual`, substitua os `ColorRect`s por um `AnimatedSprite2D` ou `Sprite2D`.
3. Animações sugeridas:
   - `idle`
   - `run`
   - `jump`
   - `repair` (consertando uma máquina com ferramenta)
