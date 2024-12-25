# Sistema de Gerenciamento de VIP

- author: [@drypzz](https://github.com/drypzz)
- version: 1.1.0


## 🚀 Tecnologias

Esse projeto foi desenvolvido com as seguintes tecnologias:

- Lua

## 🔨 Funções exportadas (server-side)

Esse projeto conta com 3 funções exportadas para serem utilizadas em qualquer outro resource

- getTimeVip(player)<br>
    ```lua
    -- @param player: Elemento do Jogador
    -- @return: "00 Dias e 00 Horas - 00 Min"
    ```
- getDateLimitVip(player)<br>
    ```lua
    -- @param player: Elemento do Jogador
    -- @return: "00/00/0000"
    ```
- getTypeVip(player)<br>
    ```lua
    -- @param player: Elemento do Jogador
    -- @return: "Nome do VIP"
    ```

## 🗿🍷 Arquivo de configuração:

- Arquivo de configuração `default`:
```lua
config = {

    debuggingEnabled = false, -- Habilitar debugging para ver os prints no console (Recomendado desativar em produção)

    id_elementData = "ID", -- ElementData que será usado para identificar o player

    infoDx = {
        sounds = { -- Sons que podem ser tocados
            "gtasa_Instrumental.mp3",
            "snoop_dogg.mp3",
            "still_dre.mp3",
        },

        timer_activation = 18, -- Tempo em segundos para sumir a mensagem e musica (Só pesquisar no google "segundos em minutos")

        textsToAllPlayers = {
            -- Mensagem de ativação de VIP
            ["addedVip"] = "* O jogador(a) %s[%s] agora é um %s *", -- %s = Nome do player, %s = ID do player, %s = Nome do VIP (Adicionado)

            -- Mensagem do ganhador do Sorteio
            ["givedVip"] = "* O jogador(a) %s[%s] ganhou um %s *", -- %s = Nome do player, %s = ID do player, %s = Nome do VIP (Sorteado)

            -- Mnensagem de renovação de VIP
            ["renewVip"] = "* O %s[%s] teve seu VIP renovado *", -- %s = Nome do player, %s = ID do player, %s = Nome do VIP (Renovado)
        },
    },

    manager = {
        acl = { -- ACLs que podem abrir o painel
            "Admin",
            "Console",
        },

        open = {
            ["bind"] = {"F4", true}, -- Bind para abrir o painel, true = Ativado
            ["cmd"] = {"vipadmin", false}, -- Comando para abrir o painel, false = Desativado
        },

        cmd_salary = "salariovip", -- Comando para resgatar o salario
        hours_salary = 12, -- Horas para resgatar o salario

        vips = { -- Vips que podem ser adicionados
            ["Vip Avancado"] = { bonus = 100000, salary = 100000 }, -- [ACL], bonus que ele ganha, salario que ele ganha
            ["Vip Basico"] = { bonus = 50000, salary = 50000 }, -- [ACL], bonus que ele ganha, salario que ele ganha
        },
    },

    giveaway = {
        acl = { -- ACLs que podem criar um sorteio e ver a lista de players
            "Admin",
            "Console",
        },

        cmd_join = "participarsorteio", -- Comando para participar do sorteio
        cmd_create = "criarsorteio", -- Comando para criar um sorteio
        show_giveaway = "versorteio", -- Comando para mostrar a lista de players no sorteio

        timer_giveaway = 60, -- Tempo em segundos para sortear um player (Só pesquisar no google "segundos em minutos")
    },
};
```


---

Feito com ♥ by drypzz