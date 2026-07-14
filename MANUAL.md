# qbx_spawn — Manual

Tela de seleção de spawn para Qbox, com mapa scaleform em 3D (`HEISTMAP_MP`), suporte a último local salvo, apartamentos iniciais e casas do `ps-housing`.

---

## Sumário

1. [Dependências](#dependências)
2. [Instalação](#instalação)
3. [Configuração](#configuração)
4. [Fluxo de spawn](#fluxo-de-spawn)
5. [Controles](#controles)
6. [Integrações](#integrações)
7. [Entrypoints para outros recursos](#entrypoints-para-outros-recursos)
8. [Localização](#localização)
9. [Estrutura de arquivos](#estrutura-de-arquivos)

---

## Dependências

| Recurso | Obrigatório | Observação |
|---|---|---|
| `qbx_core` | Sim | Framework base. Dispara o evento `qb-spawn:client:setupSpawns` e fornece `exports.qbx_core:GetPlayer` |
| `ox_lib` | Sim | Callbacks, locale, `lib.requestScaleformMovie` |
| `oxmysql` | Sim | Leitura da coluna `position` da tabela `players` e da tabela `properties` |
| `ps-housing` | Não | Necessário para o callback `qbx_spawn:server:getHouses` retornar casas. Sem ele, jogadores sem propriedades funcionam normalmente |

---

## Instalação

1. Copie a pasta `qbx_spawn` para `resources/`.
2. Adicione ao `server.cfg`:
   ```
   ensure qbx_spawn
   ```
3. Não há SQL próprio. O recurso lê tabelas já criadas pelo `qbx_core` (`players`) e pelo `ps-housing` (`properties`).
4. **Conflitos** — não rode junto com o `mri_Qspawn`. Os dois registram os mesmos callbacks (`qbx_spawn:server:getLastLocation`, `qbx_spawn:server:getHouses`, `qbx_spawn:server:alreadySpawned`) e o mesmo handler de `qb-spawn:client:setupSpawns`. Escolha um.

---

## Configuração

### `config/client.lua`

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `spawns` | array | Sim | Lista de pontos de spawn fixos exibidos no mapa |
| `spawns[].label` | string | Sim | Chave de tradução ou texto exibido no mapa. Passa por `locale()`, então uma chave definida em `locales/*.json` é traduzida |
| `spawns[].coords` | `vec4(x, y, z, w)` | Sim | Coordenadas do spawn. `w` é o heading aplicado ao ped |
| `clouds` | bool | Não | Quando `true`, usa a transição de nuvens (`SwitchOutPlayer`/`SwitchInPlayer`) e toca a animação de acordar (`random@peyote@generic` / `wakeup`). Quando `false` (padrão), usa fade de tela simples |

Os spawns padrão do recurso são Legion Square, Paleto Bay e Motels.

### `config/server.lua`

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `selectOnFirstSpawn` | bool | Não | Quando `true` (padrão), a tela de seleção só aparece no primeiro spawn do personagem na sessão do servidor; nos spawns seguintes o jogador vai direto para o último local salvo. Quando `false`, a tela aparece sempre |

O controle de "já spawnou" é feito pelo GlobalState `SpawnedPlayers`, indexado por `citizenid`. Ele é resetado quando o servidor reinicia.

---

## Fluxo de spawn

1. O `qbx_core` termina de carregar o personagem e dispara `qb-spawn:client:setupSpawns` com `cData`, `new` e `apps`.
2. **Personagem novo (`new = true`)** — a lista de spawns é montada apenas com os apartamentos recebidos em `apps`. Cada entrada é marcada com `first_time = true`, o que suprime a animação de acordar.
3. **Personagem existente (`new = false`)** — a lista é montada nesta ordem:
   - `last_location` (retorno de `qbx_spawn:server:getLastLocation`);
   - os spawns fixos de `config/client.lua`;
   - as casas retornadas por `qbx_spawn:server:getHouses`.
4. O client verifica `qbx_spawn:server:alreadySpawned`. Se retornar `true`, pula a seleção e teleporta direto para o último local.
5. Caso contrário, monta a câmera, o mapa scaleform e espera a escolha do jogador.
6. Após a confirmação, o ped é teleportado, os eventos `QBCore:Server:OnPlayerLoaded` e `QBCore:Client:OnPlayerLoaded` são disparados, e o client emite `qbx_spawn:server:spawn` para marcar o personagem como já spawnado.

---

## Controles

| Tecla | Controle | Ação |
|---|---|---|
| Seta para cima | `188` | Spawn anterior |
| Seta para baixo | `187` | Próximo spawn |
| Enter | `191` | Confirmar spawn selecionado |

Os três aparecem na barra de botões instrucionais (`INSTRUCTIONAL_BUTTONS`) no rodapé da tela.

---

## Integrações

### ps-housing

Se o jogador tiver linhas na tabela `properties` com `owner_citizenid` igual ao seu e `apartment` falso, cada propriedade vira uma opção de spawn. As coordenadas da porta principal são obtidas via `exports['ps-housing']:getMainDoor(property_id, 1, true)`.

Ao confirmar o spawn em uma propriedade, o client dispara `ps-housing:server:enterProperty`:

- se o spawn escolhido tem `propertyId`, o evento é disparado com o modo `'spawn'`;
- se o jogador escolheu `last_location` e o metadata `inside.property_id` existe, o evento é disparado com esse `property_id`, colocando o jogador de volta dentro do imóvel onde deslogou.

### qbx_core

O recurso não registra nenhum export próprio de spawn. Ele reage ao evento `qb-spawn:client:setupSpawns` disparado pelo fluxo de multichar do `qbx_core` e devolve o controle disparando `QBCore:Server:OnPlayerLoaded` / `QBCore:Client:OnPlayerLoaded` ao final.

---

## Entrypoints para outros recursos

### Evento `qb-spawn:client:setupSpawns` (client)

Ponto de entrada do recurso. Abre a tela de seleção de spawn.

```lua
TriggerEvent('qb-spawn:client:setupSpawns', cData, new, apps)
```

| Parâmetro | Tipo | Descrição |
|---|---|---|
| `cData` | table | Dados do personagem carregado |
| `new` | bool | `true` para personagem recém-criado |
| `apps` | table | Apartamentos iniciais disponíveis. Cada entrada precisa de `label` e `door` com `x`, `y`, `z`. Usado apenas quando `new = true` |

### Callbacks de servidor

```lua
-- Retorna a posição salva (vec4) e o propertyId do metadata `inside`, se houver.
local coords, propertyId = lib.callback.await('qbx_spawn:server:getLastLocation')

-- Retorna a lista de casas do jogador: { { label = street, coords = vec3 }, ... }
local houses = lib.callback.await('qbx_spawn:server:getHouses')

-- Retorna true se o personagem já spawnou nesta sessão do servidor.
-- Sempre false quando `selectOnFirstSpawn` está desativado.
local spawned = lib.callback.await('qbx_spawn:server:alreadySpawned')
```

### Evento de servidor `qbx_spawn:server:spawn`

Marca o `citizenid` do jogador como já spawnado no GlobalState `SpawnedPlayers`.

```lua
TriggerServerEvent('qbx_spawn:server:spawn')
```

---

## Localização

As strings do mapa (labels de spawn passados por `locale()`) são traduzidas via `ox_lib` locale. Os arquivos ficam em `locales/`:

- `de.json` — alemão
- `en.json` — inglês
- `pl.json` — polonês
- `pt-br.json` — português do Brasil
- `pt.json` — português (Portugal)

O locale ativo é definido pela convar `ox:locale` no `server.cfg`:

```
setr ox:locale "pt-br"
```

Para adicionar um idioma, crie `locales/<codigo>.json` seguindo a estrutura dos existentes e reinicie o recurso.

---

## Estrutura de arquivos

```
qbx_spawn/
├── client/
│   └── main.lua          — câmera, mapa scaleform, botões instrucionais, teleporte e transições
├── server/
│   └── main.lua          — callbacks de último local, casas e controle de primeiro spawn
├── config/
│   ├── client.lua        — lista de spawns fixos e flag `clouds`
│   └── server.lua        — flag `selectOnFirstSpawn`
├── locales/
│   ├── de.json
│   ├── en.json
│   ├── pl.json
│   ├── pt-br.json
│   └── pt.json
└── fxmanifest.lua
```
