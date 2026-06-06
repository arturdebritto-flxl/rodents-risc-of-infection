# Projeto Echo

Jogo em RISC-V Assembly para RARS16_Custom1.

## Como validar

```powershell
java -jar C:\Users\Usuario\Desktop\Rars16_Custom1.jar nc a main.s
java -jar C:\Users\Usuario\Desktop\Rars16_Custom1.jar nc a test_progression.s
java -jar C:\Users\Usuario\Desktop\Rars16_Custom1.jar nc me test_progression.s
```

## RARS GUI

- Use `main.s` como arquivo principal.
- Use o RARS16_Custom1.
- Conecte o Bitmap Display conforme o projeto da disciplina.
- Conecte o KDMMIO para teclado.

## Controles

- `WASD`: mover.
- `IJKL`: atirar.
- `SPACE` ou `ENTER`: iniciar no menu.
- `R`: reiniciar em game over ou victory.
- `H`: usar cura quando houver item.

## Arquitetura

- `src/enemies.s`: ratos common, Echo, mutant e spitter.
- `src/enemy_bullets.s`: projeteis inimigos.
- `src/boss.s`: boss final separado dos inimigos normais.
- `src/powerups.s`: power-ups coletaveis.
- `src/inventory.s`: arma, municao normal, municao boss e cura.
- `src/hud.s`: informacoes numericas de gameplay.
- `src/screens.s`: menu, game over, victory e reset de partida.

## Sprites

Os desenhos atuais usam quadrados simples. Para integrar sprites do grupo, mantenha as interfaces e substitua por dentro de:

- `draw_player_square`
- `draw_enemies`
- `draw_boss_square`
- `draw_inventory`
- `draw_powerups`

## Balanceamento

Os ajustes principais ficam em `src/constants.s`:

- HP e velocidade dos ratos.
- Delay do spitter.
- HP e delay de tiro do boss.
- Dano da arma normal e da arma boss.
- Ganho de municao normal, municao boss e cura.
- Quantidade de waves e inimigos por wave.

## Checklist

- `main.s` monta.
- `test_progression.s` monta.
- Teste de progressao executa e termina.
- Menu inicia jogo.
- Player move e atira.
- Ratos aparecem e sofrem dano.
- Mutant exige mais de um hit normal.
- Spitter dispara projetil inimigo.
- Projetil inimigo tira vida.
- Power-ups de municao e cura podem ser coletados.
- Arma e municao boss aparecem na batalha final.
- Inventario numerico atualiza.
- Boss aparece e so ele dispara victory ao morrer.
- Game over aparece quando vidas chegam a zero.
- `R` reinicia para o menu.
