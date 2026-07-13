# Manual do qbx_spawn

Sistema de seleção de spawn para Qbox — interface moderna com mapa interativo, suporte ao último local, propriedades e casas.

## Funcionalidades Principais

### Mapa Interativo
- Mapa scaleform em tela cheia com áreas de spawn clicáveis
- Visualização clara de todos os pontos de spawn disponíveis
- Interface intuitiva para seleção de local de spawn

### Sistema de Spawn
- **Último Local**: Spawna o jogador na última posição salva automaticamente
- **Propriedades**: Spawn em propriedades possuídas via integração ps-housing
- **Casas**: Spawn em casas possuídas pelos jogadores
- **Primeira Vez**: Tratamento especial para novos personagens com pontos de spawn específicos

### Navegação
- **Teclado**: Use as setas direcionais para navegar pelos pontos de spawn
- **Confirmação**: Pressione ENTER para confirmar a seleção
- **Mouse**: Clique diretamente nas áreas do mapa

### Transições
- **Nuvens**: Efeito de transição de nuvens opcional ao spawnar
- Animações suaves entre a seleção e o spawn

## Configuração

### config/server.lua
```lua
config = {
    selectOnFirstSpawn = true, -- Mostrar seleção no primeiro spawn
    spawns = {
        {
            label = 'Aeroporto',
            coords = vector4(-1037.37, -2737.66, 13.76, 206.12)
        },
        {
            label = 'Prefeitura',
            coords = vector4(-269.13, -955.28, 31.22, 205.0)
        },
        {
            label = 'Hospital',
            coords = vector4(306.96, -601.33, 43.28, 270.0)
        },
        -- Adicione mais pontos de spawn conforme necessário
    }
}
```

### config/client.lua
```lua
config = {
    clouds = false,      -- Ativar efeito de transição de nuvens
    debugPoly = false,   -- Mostrar polígonos de debug
}
```

## Uso

### Evento de Spawn

O sistema usa o evento padrão do QBCore para configurar spawns:

```lua
-- Disparado automaticamente pelo qbx_core
TriggerEvent('qb-spawn:client:setupSpawns', cData, new, apps)
```

**Parâmetros:**
- `cData`: Dados do personagem
- `new`: Boolean indicando se é primeiro spawn
- `apps`: Tabela de pontos de spawn de apartamentos (para novos personagens)

### Callbacks do Servidor

| Callback | Parâmetros | Retorno | Descrição |
|----------|------------|--------|-------------|
| `qbx_spawn:server:getLastLocation` | `source` | `vector4, propertyId?` | Obter último local salvo |
| `qbx_spawn:server:getHouses` | `source` | `table[]` | Obter casas possuídas |
| `qbx_spawn:server:alreadySpawned` | `source` | `boolean` | Verificar se já spawnou |

## Eventos

### Client Events

| Evento | Payload | Descrição |
|-------|----------|-------------|
| `qb-spawn:client:setupSpawns` | `cData, new, apps` | Configurar pontos de spawn |

## Fluxo de Spawn

1. **Jogador faz login** → qbx_core carrega personagem
2. **Verifica se já spawnou** → `alreadySpawned` callback
3. **Se primeiro spawn**:
   - Mostra seleção se `selectOnFirstSpawn = true`
   - Inclui pontos de apartamentos se disponíveis
4. **Se já spawnou antes**:
   - Oferece opção de "Último Local"
   - Carrega pontos de spawn configurados
5. **Jogador seleciona spawn** → Confirma com ENTER
6. **Teleporta jogador** → Aplica coordenadas e efeito de nuvens

## Estrutura de Arquivos

```
qbx_spawn/
├── client/
│   └── main.lua           # UI de spawn, renderização do mapa, entrada
├── server/
│   └── main.lua           # Dados de spawn, último local, casas
├── config/
│   ├── client.lua         # Config do client (nuvens, debug)
│   └── server.lua         # Config do servidor (spawns, selectOnFirstSpawn)
└── locales/               # Traduções
```

## Dependências

| Dependência | Versão Mínima | Obrigatória |
|------------|-------------------|----------|
| ox_lib | - | ✅ |
| oxmysql | - | ✅ |
| qbx_core | - | ✅ |
| ps-housing | - | ❌ (opcional) |

## Integrações

### ps-housing
- Detecta automaticamente propriedades possuídas
- Adiciona pontos de spawn de propriedades à lista
- Permite spawn direto na propriedade do jogador

### qbx_core
- Recebe dados do personagem via eventos
- Salva última posição no logout
- Integra com sistema multicharacter

## Solução de Problemas

### Mapa não aparece
- Verifique se o qbx_core inicializou corretamente
- Confirme que o personagem foi carregado
- Verifique se há erros no console do client

### Spawn no último local não funciona
- Verifique se o jogador já fez spawn anteriormente
- Confirme que a posição foi salva no logout
- Verifique o callback `getLastLocation`

### Pontos de spawn não aparecem
- Verifique a configuração em `config/server.lua`
- Confirme que `spawns` é uma tabela válida
- Verifique se as coordenadas estão corretas (vector4)

### Teclado não navega
- Certifique-se de que o mapa está ativo
- Use as setas direcionais (não WASD)
- Pressione ENTER para confirmar seleção
