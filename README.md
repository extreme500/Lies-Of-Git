# 🏃 Protótipo: Plataforma 2D (`plataformer-2d`)

Maquete completa de jogo de plataforma 2D em Godot 4, desenvolvida com foco em game feel, responsividade e código limpo para rápida adaptação durante uma GameJam.

---

## 🎮 O que está implementado:
1. **Controle do Jogador (`CharacterBody2D`)**:
   - Movimentação suave com aceleração e desaceleração.
   - Pulo variável (soltar o botão reduz a altura do pulo).
   - **Coyote Time** (tolerância para pular logo após sair da beira da plataforma).
   - **Jump Buffer** (registro de clique de pulo instantes antes de aterrissar).
   - **Squash & Stretch** (deformação visual animada ao pular e aterrissar).
   - Emissão de partículas de poeira ao correr no chão.
   - Detecção de queda no vazio com respawn automático.
2. **Inimigo com Mecânica de Stomp**:
   - Patrulha horizontal automática.
   - Se o jogador cair por cima (stomp), o inimigo é esmagado e o jogador salta para cima.
   - Se encostar pela lateral ou por baixo, o jogador sofre dano e renasce.
3. **Obstáculos e Perigos**:
   - Espinhos letais com área de colisão.
   - Plataforma móvel flutuante (`AnimatableBody2D`) com interpolação suave via `Tween`.
4. **Coletáveis & Feedback**:
   - Moedas flutuantes com animação de onda e rotação.
   - Efeitos sonoros procedurais para pulo, moeda, dano, passos e vitória.
   - Bandeira de meta que aciona a tela de vitória.
5. **HUD Completo**:
   - Contador de moedas coletadas.
   - Contador de mortes.
   - Cronômetro de tempo de fase.
   - Painel de vitória com resumo e botão de reiniciar.

---

## ⌨️ Controles
- **Mover para a Esquerda**: `A` ou `Seta Esquerda`
- **Mover para a Direita**: `D` ou `Seta Direita`
- **Pular**: `Espaço`, `W` ou `Seta Cima`
- **Reiniciar Fase**: `R`

---

## 💡 Como adaptar para temas comuns de GameJam:
- **Tema "Luz e Sombras"**: Adicione um nó `PointLight2D` no jogador e `CanvasModulate` escuro para fazer um jogo de exploração em cavernas.
- **Tema "Reverso / Troca de Papéis"**: Mude o script do jogador para controlar o inimigo tentando fugir dos heróis.
- **Tema "Gravidade / Rotação"**: Inverta `gravity` para fazer fases no teto.
- **Tema "Tempo Limitado"**: Adicione contagem regressiva no HUD.
