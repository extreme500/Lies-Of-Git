# 🎮 Lies-Of-Git — GameJam Starter Kit & Protótipos (Godot 4)

Este repositório foi estruturado para ser a **base rápida definitiva para GameJams**, contendo maquetes funcionais prontas para serem testadas, modificadas e adaptadas para qualquer tema da Jam.

Cada estilo de jogo possui sua própria **branch isolada**, contendo um projeto completo e executável no Godot 4.

---

## 🕹️ Maquetes e Branches Disponíveis

| Branch | Estilo / Gênero | Principais Mecânicas Inclusas |
| :--- | :--- | :--- |
| [`plataformer-2d`](#-plataformer-2d) | **Plataforma 2D** | Movimento suave, pulo variável, coyote time, buffer de pulo, plataformas móveis, espinhos, inimigos com stomp, moedas com som/partículas e tela de vitória. |
| [`shooter-3d`](#-shooter-3d) | **Shooter 3D (FPS)** | Câmera em 1ª pessoa, mouse capturado, movimentação WASD, pulo, head-bob, arma com recuo e muzzle flash, disparos com impacto/faíscas, alvos 3D com dano e destruição. |
| [`rpg-de-turnos-2d`](#-rpg-de-turnos-2d) | **RPG de Turnos 2D** | Grupo de heróis (Guerreiro e Maga) vs Inimigos, menu de ações (Ataque, Magia/Golpe Especial, Cura, Defesa), feedback de dano flutuante, log de batalha, barras de HP/MP e tela de vitória/derrota. |
| [`point-and-click-2d`](#-point-and-click-2d) | **Point and Click 2D** | Sala investigativa (escape room), cursor contextual, inspeção de objetos com caixa de diálogos, inventário interativo, combinação de itens no cenário e resolução de enigma. |
| [`puzzle-2d`](#-puzzle-2d) | **Puzzle 2D (Sokoban)** | Movimentação em grade, empurrar caixas até placas de pressão, feedback sonoro e visual, **sistema de Desfazer passos (Undo - Tecla Z)**, reinício rápido (R), fases progressivas. |
| [`top-down-survivor-2d`](#-top-down-survivor-2d) | **Arena Survivor 2D** | Estilo Vampire Survivors: hordas de inimigos, projéteis automáticos, orbes orbitais, coleta de gemas de XP, menu de Level Up com escolha de upgrades e temporizador de sobrevivência. |
| [`infinite-runner-2d`](#-infinite-runner-2d) | **Endless Runner 2D** | Geração contínua de obstáculos e moedas, pulo e corrida com aceleração gradual, pontuação em tempo real e Game Over com reinício instantâneo. |

---

## 🚀 Como Utilizar

### 1. Clonar ou Acessar o Repositório
Abra o terminal na pasta do repositório:
```bash
cd Lies-Of-Git
```

### 2. Escolher e Alternar para a Branch do Jogo
Para trocar para o protótipo desejado:
```bash
# Exemplo para Plataforma 2D:
git checkout plataformer-2d

# Exemplo para Shooter 3D:
git checkout shooter-3d

# Exemplo para RPG de Turnos:
git checkout rpg-de-turnos-2d

# Exemplo para Point and Click:
git checkout point-and-click-2d

# Exemplo para Puzzle:
git checkout puzzle-2d

# Exemplo para Top-Down Survivor:
git checkout top-down-survivor-2d

# Exemplo para Endless Runner:
git checkout infinite-runner-2d
```

### 3. Abrir no Godot 4
1. Abra o **Godot Engine 4** (ou utilize o executável presente no sistema).
2. Clique em **Importar** (Import).
3. Selecione a pasta do repositório `Lies-Of-Git` (onde o arquivo `project.godot` da branch estará presente).
4. Clique em **Importar & Editar** (Import & Edit) ou aperte **F5** para rodar diretamente!

---

## 💡 Dicas de Ouro para GameJams

1. **Defina o Core Loop no 1º Dia**: Pegue uma dessas maquetes, jogue por 5 minutos e decida a reviravolta (twist) do tema.
2. **Juice e Game Feel**: Todas as maquetes já possuem som procedural, partículas e feedback de tela (screen shake / popups). Mantenha e expanda essa sensação!
3. **Não reinvente a física**: Use os scripts prontos de movimento e colisão e gaste o tempo de Jam na arte, narrativa, mecânica única e polimento.
4. **Crie uma nova branch para a sua submissão**:
   ```bash
   git checkout <maquete-escolhida>
   git checkout -b meu-jogo-gamejam
   ```
