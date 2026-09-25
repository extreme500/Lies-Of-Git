# 📋 TODO LIST — GameJam "Keep It Together"

Lista de tarefas prioritárias, melhorias e recursos extras planejados para o jogo cooperativo split-screen da Máquina.

---

## 🎮 1. Suporte a Controles (Gamepad / Joystick)
- [ ] **Mapear Device 0 (Player 1)**:
  - Analógico Esquerdo / D-Pad: Movimentação horizontal (`p1_left`, `p1_right`).
  - Botão A / Cruz (`JOY_BUTTON_A`): Pulo (`p1_jump`).
  - Botão X / Quadrado ou Gatilho (`JOY_BUTTON_X`): Interagir / Consertar (`p1_interact`).
- [ ] **Mapear Device 1 (Player 2)**:
  - Analógico Esquerdo / D-Pad do segundo joystick: Movimentação (`p2_left`, `p2_right`).
  - Botão A / Cruz do segundo joystick: Pulo (`p2_jump`).
  - Botão X / Quadrado ou Gatilho do segundo joystick: Interagir / Consertar (`p2_interact`).
- [ ] **Detecção Automática de Controles**:
  - Exibir ícone ou texto no HUD: "P1: Teclado [WASD + E] / Controle 1" e "P2: Teclado [Setas + Enter] / Controle 2".
  - Suporte a vibração leve no controle durante alarmes ou falhas críticas.

---

## 🎨 2. Arte, Sprites e Animações (Substituir Protótipos)
- [ ] **Asset Central: "Máquina" (`res://scenes/maquina.tscn` / `res://assets/maquina/`)**:
  - Criar sprite/ilustração detalhada para a carcaça central da máquina (estilo industrial/steampunk/sci-fi com tubos, válvulas e mostradores analógicos).
  - Animação de idle com fumaça e luzes pulsantes.
  - Estado de perigo: chamas e faíscas saindo da cúpula central quando a integridade estiver < 30%.
- [ ] **Jogadores (Player 1 e Player 2)**:
  - Sprites com diferenciação de cor clara (ex: Macacão Azul/Ciano para P1, Macacão Laranja/Vermelho para P2).
  - Animação de corrida, pulo e conserto (segurando chave inglesa ou maçarico).
- [ ] **Estações de Reparo e Falhas**:
  - **Terminais de Controle**: Telas com osciloscópio / código ou aviso de ERRO.
  - **Cabos Elétricos**: Fios partidos balançando com partículas de choque elétrico.
  - **Bobina / Mola de Pressão**: Modelo da bobina/mola saltando e emitindo fumaça.
  - **Válvula de Vapor**: Efeito de jato de vapor quente.
- [ ] **Cenário e Background**:
  - Paredes metálicas com texturas, rebites e vidro central reforçado que separa as duas salas.
  - Detalhes de iluminação volumétrica / luzes de emergência giratórias vermelhas.

---

## 🔊 3. Áudio e Efeitos Sonoros (SFX)
- [ ] Sirene de alarme de emergência tocando em loop quando uma falha crítica estiver ativa.
- [ ] Som de chiado de vapor / fuga de ar pressurizado.
- [ ] Som de choque / arco elétrico estalando.
- [ ] Som de ferramenta de conserto (marteladas / solda / chave de boca girando).
- [ ] Trilha sonora retro/synthwave ou orquestral tensa que aumenta de pitch/andamento conforme o tempo acaba ou a integridade diminui.

---

## ⚙️ 4. Mecânicas da Fase 2 e Modos Avançados
- [ ] **Tubo Pneumático / Escotilha de Troca**:
  - Um item de reposição (ex: Fusível ou Engrenagem) surge na sala de um jogador, mas deve ser arremessado ou enviado para a sala do outro jogador através de um duto central.
- [ ] **Alavanca de Purga Sincronizada (Keep It Together)**:
  - A máquina entra em sobrepressão total. Os dois jogadores precisam subir até o topo e segurar a alavanca simultaneamente durante 3 segundos para estabilizar.
- [ ] **Vazamento de Gás / Área de Risco**:
  - Vapores tóxicos sobem temporariamente no chão da sala, forçando o jogador a pular pelas plataformas superiores enquanto conserta o defeito.
- [ ] **Fase 0 (Tutorial Interativo)**:
  - Sala de treino segura ensinando os controles, como pular e como segurar a tecla de conserto.
