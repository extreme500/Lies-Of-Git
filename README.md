# ⚔️ Protótipo: RPG de Turnos 2D (`rpg-de-turnos-2d`)

Maquete completa de sistema de batalha por turnos estilo RPG clássico (Final Fantasy, Dragon Quest, Pokémon) em Godot 4, com máquina de estados, grupo de heróis, inimigos variados e feedback de combate animado.

---

## 🎮 O que está implementado:
1. **Grupo de Heróis Personalizados (`RPGCombatant`)**:
   - **Valente (Guerreiro)**: Especialista em dano físico e resistência.
     - *Ataque Básico*: Golpe com a espada que causa dano e regenera um pouco de MP.
     - *Golpe Brutal (15 MP)*: Ataque devastador com alto dano e efeito crítico.
     - *Curativo (10 MP)*: Aplica bandagens no aliado com menor vida.
     - *Defender*: Reduz em 50% o dano recebido no próximo turno e recupera MP.
   - **Luna (Maga)**: Conjuradora com alta reserva de mana.
     - *Ataque Básico*: Disparo arcano leve.
     - *Bola de Fogo (20 MP)*: Explosão mágica com dano massivo em chamas.
     - *Luz Curativa (15 MP)*: Restaura grande quantidade de vida para o aliado mais necessitado.
     - *Defender*: Cria um escudo mágico protetor.
2. **Inimigos com IA Autônoma**:
   - **Rei Goblin (Chefe)**: Alta vitalidade e ataque potente.
   - **Slime Ácido**: Ataques corrosivos rápidos.
   - IA avalia os heróis vivos e escolhe alvos dinamicamente.
3. **Game Feel & Feedback Visual**:
   - Personagens dão um passo à frente (`step_forward`) ao agir.
   - Tremor de tela e impacto (`shake_reaction`) ao sofrer dano.
   - Indicador luminoso destacando de quem é o turno ativo.
   - Números de dano e cura flutuantes subindo e sumindo suavemente.
   - Log de Batalha com texto colorido em tempo real descrevendo cada ação.
4. **Condições de Vitória e Derrota**:
   - Tela de vitória ao derrotar todos os monstros com som de celebração.
   - Tela de derrota se todos os heróis caírem.
   - Botão para reiniciar a batalha instantaneamente.

---

## ⌨️ Controles
- **Mouse**: Navegue e clique nos botões de ação e na seleção de alvos.
- **Reinício**: Botão de reiniciar na tela de final ou recarregando a cena.

---

## 💡 Como adaptar para temas comuns de GameJam:
- **Tema "Monstros são os heróis"**: Inverta as facções — o jogador controla o Goblin e o Slime defendendo a masmorra de aventureiros gananciosos.
- **Tema "Dado / Sorte"**: Adicione uma rolagem de dados para determinar acertos críticos ou efeitos elementais.
- **Tema "Controle de Tempo"**: Implemente um sistema ATB (Active Time Battle) onde barras de velocidade enchem continuamente.
- **Tema "Fusão / Alquimia"**: Permita que os heróis combinem habilidades em turnos cooperativos.
