# ⚙️ Asset: "Máquina" (Máquina Final)

Este é o elemento central do tema "Keep It Together".

## Localização no Projeto:
- **Cena**: `res://scenes/maquina.tscn`
- **Script**: `res://scripts/maquina.gd`

## Como Substituir o Visual:
1. Abra a cena `res://scenes/maquina.tscn` no editor do Godot.
2. No nó `Visual/CoreSprite` ou `Visual/Body`, troque o `ColorRect` por um `Sprite2D` ou `AnimatedSprite2D`.
3. Insira suas texturas/PNGs nesta pasta (`res://assets/maquina/`).
4. Recomenda-se criar:
   - `maquina_normal.png` (estado operacional)
   - `maquina_danificada.png` (quando integridade < 50%)
   - `maquina_fumaca.png` ou efeitos de partículas de faíscas.
