# Interface WPF inspirada no Winutil com identidade vermelha

A interface do TotemAutomacao foi padronizada para um visual proximo ao Winutil (organizacao por abas, cards e barra superior), mantendo identidade propria com paleta vermelha predominante e removendo texto de atribuicao no painel "Sobre". O logo passou a usar um asset com fundo transparente para evitar bordas brancas no header, preservando legibilidade e consistencia visual no tema escuro.

## Considered Options

- Manter layout atual e apenas trocar cores: menor impacto, mas distancia visual grande do Winutil.
- Migrar para navegacao lateral completa: aproximacao alta, mas exigia refatoracao maior de layout e eventos.
- Barra superior com abas em cards e acoes globais separadas: melhor equilibrio entre semelhanca com Winutil e baixo risco de regressao.
