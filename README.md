# 🏃 Protótipo: Infinite Runner 2D (`infinite-runner-2d`)

Maquete completa de jogo de corrida infinita (estilo Dino do Chrome, Subway Surfers 2D, Canabalt, Jetpack Joyride) em Godot 4, com geração procedural contínua de obstáculos e moedas, pulo duplo, mecânica de deslizar/agachar e progressão de velocidade.

---

## 🎮 O que está implementado:
1. **Controle do Corredor (`RunnerPlayer`)**:
   - Corrida contínua com partículas de poeira nos pés.
   - Pulo com gravidade realista e suporte a **Pulo Duplo**.
   - Mecânica de **Deslizar / Agachar (Slide)**: achata a colisão e o visual para passar por baixo de raios e obstáculos aéreos.
   - Squash & stretch dinâmico nos saltos.
2. **Gerador Procedural de Obstáculos**:
   - **Obstáculos Terrestres (Espinhos / Rochas)**: Exigem pulo preciso.
   - **Obstáculos Aéreos (Lasers / Feixes)**: Exigem agachar e deslizar por baixo.
   - **Trilhas de Moedas**: Arcos de moedas com pontuação bônus e som de coleta.
3. **Escalonamento de Dificuldade**:
   - A velocidade de corrida começa em 420 px/s e aumenta gradualmente com o tempo de sobrevivência.
   - Os intervalos de spawn diminuem proporcionalmente para manter o desafio sempre crescente.
4. **Interface e Estatísticas**:
   - Marcador de Distância percorrida em metros em tempo real.
   - Contador de moedas coletadas.
   - Velocímetro em km/h.
   - Painel de Game Over com resumo da corrida e reinício instantâneo pressionando `Espaço` ou `R`.

---

## ⌨️ Controles
- **Pular / Pulo Duplo**: `Espaço`, `W` ou `Seta Cima`
- **Deslizar / Agachar (Slide)**: `S` ou `Seta Baixo` (segurar)
- **Reiniciar Corrida**: `R` ou `Espaço` (após a derrota)

---

## 💡 Como adaptar para temas comuns de GameJam:
- **Tema "Mudança de Gravidade"**: Adicione a mecânica de inverter a gravidade para correr no teto.
- **Tema "Música / Ritmo"**: Sincronize os obstáculos com a batida de uma trilha sonora (estilo Geometry Dash).
- **Tema "Combustível / Energia"**: O corredor precisa coletar baterias antes que o jetpack acabe.
- **Tema "Transformação"**: O personagem alterna entre formas (pássaro para voar, toupeira para cavar, corredor para pular).
