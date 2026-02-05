# Changelog  
Todas as mudanças neste projeto serão documentadas aqui.  
  
### version 1.0  
- Versão mobile criada, com leitura de arquivos, reprodução e upload.  
- Versão desktop apenas recebe e armazena em uma pasta local.  
  
### version 1.1  
- Adição do player e botões utilitários.  
- Adição do slider e nome da música atual.  
- Adição de um tema padrão.  
- Botões em funcionamento (Pause/Play, Prox, Prev, Random, Loop).  
- Música muda de cor para ficar em destaque quando tocada.  
  
### version 1.2  
- Mudança da forma de reproduzir os audios.  
- Adição de uma notificação interativa.  
- Mudança na forma de procurar arquivos de musica.  
  
### version 1.3  
- Correção do modo aleatório inicial.  
- Criação de um aleatório mais elaborado.  
- Adição de botão personalizado nas notificações.  
  
### version 1.4  
- Pesquisa de arquivos apenas em pastas selecionada, ou todos os arquivos do dispositivo.  
- Definição de preferencias.  
- Correção da marca da musica atual na lista.  
- Adição de modos de organização de filas (Titulo A-Z, Titulo Z-A, Data A-Z, Data Z-A).  
  
### version 1.5  
- Correção da marca da musica atual na lista.  
- Opção de delete de músicas.  
- Criação do botão de more options.  
- Adição do popup para more options.  
- Adição da tabela de informações da música.  
  
### version 1.6  
- Criação de um letreiro próprio.  
- Musica atual é salva como a primeira quando o aleatório é ativado.  
- Correção do aleatório personalizado com o loop.  
- Barra de player dinâmica com um clique.  
  
### version 1.7  
- Criação das abas separadas.  
- Criação dos conceitos de playlist.  
- Reajuste na lógica do aleatório personalizado.  
- Criação do banco de dados com playlists.  
- Adição de um popup de criação.  
- Criação de filas separadas. (Atual e Total)  
  
### version 1.8  
- Alteração e Remoção de playlists.  
- Definição de playlist Atual.  
- Reorder padrão de playlist.  
- Dropdown no popup.  
- Retorno a todas as musicas.  
  
### version 1.9  
- Correção para reativar o suffle quando a fila é recriada.  
- Verificação se a lista atual é igual a próxima lista antes de recriar a fila.  
- Scrollagem automática até a música tocando.  
  
### version 1.9.1  
- Correção do aleatório + loop.  
- Separação de classe para a lista.  
  
### version 1.10  
- Adição do tema escuro.  
- Correção do scroll da lista.  
  
### version 2.0  
- Alteração de Arquivo principal em kotlin.  
- Adição de edição de arquivos (não 100% funcional).  
- Implementação de um download de músicas via URL youtube.  
  
### version 2.1  
- Conversão de webm para mp3.  
- Lista estática e compartilhada.  
- Adição do genero e album na lista.  
- Edição de arquivo agora sincronizado com a lista.  
- Página dedicada ao download das faixas.  
- Atualização de lista ao baixar uma faixa.  
- Edição das tags antes mesmo de baixar a faixa.  
- Visualização de porcentagem do método de baixar faixa.  
- Botões ficam indisponíveis ao fazer o download da faixa atual.  
  
### version 2.2  
- Scan todo inicio de app em todas as musicas.  
- Verificação se música ja foi baixada antes.  
- Carregamento das musicas da playlist.  
- Visualização da thumb dos videos na playlist.  
- Inicio do app com ordem de mais novo para mais velho.  
- Download de mais de uma faixa por vez atraves de uma playlist escolhida.  
#### DEFEITOS A SEREM CORRIGIDOS:  
- hashs de playlists não funcionando 100%.  
- Não usar playlist fixa.  
  
### version 2.3  
- Visualização de capa da música.  
- Download da thumbnail como capa de música.  
- Playlist padrão definida pelo usuario.  
- Uso do id do MediaStore para banco de dados.  
#### DEFEITOS A SEREM CORRIGIDOS:  
- hashs desativados temporariamente.  
  
### version 2.4  
- Correção do reorder por titulo, agora ignora letras maiusculas.  
- Adição de um novo modo de shuffle personalizado.  
- Troca de música mais manual e especifica.  
- Adição de troca de estado visual no botão da notificação.  
- Playlists corrigidas.  
  
### version 2.5  
- Adição de pesquisa por nome.  
- Troca de formato de lista.  
- Adição de Categorias de acordo com o reorder.  
- Barra de pesquisa oculta.  
- Ao baixar uma música sem reiniciar o app, a imagem é adicionada no mediaItem temporário.  
- Playlists corrigidas para aceitar as novas mudanças.  
  
### version 2.6  
- Correção e alteração do repeat.  
- Ao clicar no 'X' da pesquisa, apagar qualquer termo pesquisado.  
- Ao trocar de música setando o índice e o shuffle estiver ligado, a lista será reiniciada.  
- Adição de playlists de artistas.  
  
### version 2.7  
- Correção na exibição da lista de playlists.  
- Adicionada opção de escolha ao salvar uma playlist.  
- Corrigido problema na busca de playlists pelo nome do artista.  
- Página principal agora separada para exibir uma playlist.  
- Correção na pesquisa de músicas pelo nome.  
- Atualizada opção de remover ou adicionar músicas da playlist.  
- Ordem da playlist não definida inicialmente.  
- Salvamento automático ao alterar a ordem dentro da página da playlist.  
  
### version 2.8  
- Correção da cor e do titulo ao escolher uma playlist para salvar.  
- Alteração no comportamento da separação de separação de playlist por artista.  
- Adicionada verificação de playlist em uso antes de marcar uma música como 'tocando' na lista.  
- Correção no delete de uma música.  
- Alteração da barra superior do aplicativo.  
- Adição da opção retomar ultima fila.  
  
### version 2.9  
- Sincronização do shuffle do player interno e da notificação.  
- Correção do reshuffle ao clicar em um item da lista.  
- Correção do salvamento de ultima música.  
  
### version 3.0  
- Adição da aba Configurações.  
- Adição de mudança de diretório de busca.  
- Adição da mudança de playlist predefinida para download.  
- Adição da pesquisa de artistas e playlists.  
- Correção de cores do tema.  
- Correção na sincronização do shuffle da notificação para o player interno.  
- Alteração no funcionamento do download, possibilidade de mudar tags antes de baixar foi retirada.  
- Alteração no funcionamento do download, não é possivel definir playlist padrão diretamente por essa pagina.  
  
### version 3.1  
- Ao apertar botão de voltar, reiniciar a musica caso tenha passado apenas 5 segundos.  
- Opção de compartilhar o arquivo adicionada.  
- Confirmação que o nome do arquivo não terá caracteres inválidos.  
- Separação a cada 10 índices na playlists dos downloads.  
- Correção da interface de configurações.  
  
### version 3.2  
- Alteração na separação de artistas para playlists, evitando a criação de muitas playlists com apenas uma música.  
- Implementação do sistema de seleção de múltiplas músicas (Apagar e Adicionar à uma playlist).  
- Implementação do sistema de reordem manual.  
- Inversão de ordem ao baixar músicas da playlist principal (da mais antiga até a mais nova).  
- Adição de uma etapa de confirmação antes de deletar uma música.   
- Correção ao adicionar uma música na lista após baixa-la.  
- Correção do tratamento de imagens de capa (artUri).  
  
### version 3.3  
- Correção ao exibir pagina de playlist de artista.  
- Otimização do popup de confirmação/adição.  
- Otimização de código.  
- Adição de icones no popup de opções.  
  
### version 4.0  
- Integração do desktop.  
- Comunicação bilateral.  
- Comunicações funcionais atualmente (pause, play, reprodução de audio, slider de duração).  
- Correção na pagina de configurações para comportar o IP (digitado manualmente por enquanto).  
  
### version 4.1  
- Adição de um player controlador unico, sem que a música seja reproduzida no android.  
- Upgrade visual na versão de desktop.  
- Adição de um controle de volume para desktop.  
  
### version 4.2  
- Adição de um botão superior para controlar as músicas que estão sendo baixadas, sem a necessidade de esperar na pagina download.  
- Controle de porcentagem de download melhorada.   
- Correção de exibição de imagens após download.  
- Adição de um botão para criar uma nova playlist na tela 'adicionar a playlist'.  
  
### version 4.3  
- Transmissão de músicas do smartphone para o desktop de maneira mais rápida e sem travamento.  
- Criação de lista de músicas temporária no desktop.  
  
### version 4.4  
- Envio de imagem junto com música.  
- Correção da lista.  
- Sincronização inicial corrigida.  
- Correção de index errado ao adicionar novas músicas antes do carregamento total no desktop.  
- Correção do botão de pause no android.  
- Adição de reordenação temporária.  
- Adição de porcentagem para quantidade de músicas já recebidas no desktop.  
  
### version 4.5  
- ### Desativação do modo Download, por conta de mudanças internas do próprio Youtube.  
- Correção do manifest.  
- Correção da desconexão através do mobile.  
- Correção do valor do IP padrão definido na versão mobile.  
- Correção da mudança de index na versão mobile enquanto a versão desktop ainda não havia recebido a música.  
- Correção de indices relativos ao começo da lista.  
- Adição de icone para app Android.  
  
### version 4.6  
- Correção no mobile ao index recebido pelo desktop ser diferente antes de receber todas as músicas.  
- Correção de modo aleatório e repetição no desktop para funcionar de maneira autônoma.  
- Correção na visualização dos modos, incluindo a imagem do shuffle especial.  
  
### version 4.6.1  
- Adição da seleção através do clique na lista, na versão de desktop.  
- Adição de identificação visual de música atual na lista.  
- Correção na visualização de modos do player do ekosystem.  
  
### version 5.0  
- Adição da tela de Controle.  
- Otimização no recebimento de mensagens do ekosystem.  
- Implementação de memória para playlist no player principal.  
  
### version 5.1  
- Alteração em algumas cores do tema escuro.  
- Ativação do modo passar playlist.  
- Correção do padding de todas as listas por conta do player.  
- Adição de um relógio no superControle.  
- Alteração na visualização da playlist no superControle.  
  
### version 5.2  
- Foi adicionada a conexão com desktop usando QRCode.  
- Alteração de logo.  
- Adição de um menu mais controlável, principalmente sobre reordem.  
- Correção na altura do player e playerEko.  
- Adição do playerEko nas playlists.  
  
### version 5.3  
- Adicionada resposta tátil ao adicionar mais de uma musica a uma playlist.  
- Alterado tamanho das faixas de 78 para 65, para um melhor preenchimento de espaço.  
- Alterada a maneira em que as músicas das playlists eram puxadas, sem necessidade de reorganização após consulta de banco de dados.  
- Melhora na barra de pesquisa, ignora assentos e sai de foco ao fechar.  
- Melhora em pequenos aspectos de UI.  
  
### version 5.4  
- Adicionada imagem da música no supercontrol.  
- Correção para que música inicial seja definida desde o inicio do app.  
- Fonte do aplicativo trocada.  
- Adição de função superior para mais de uma seleção em playlists.  
- Correção do clique no desktop mudar atual no mobile.  
- Inicio da implementação do modo de união de musicas de mobile para desktop.  
  
### version 5.5  
- Otimização em algumas partes do código.  
- Correção da falta de mensagem de permissão de acesso aos arquivos.  
- Verificação de ethernet adicionada para QRcode de conexão.  
- Pequenas correções na união de musicas de mobile para desktop.  
  
### verion 5.6  
- Otimização no superControl e implementação do modo Ekosystem.  
- Tentativa de correção do download.  
- Alteração do slider de audio no player_Eko.  
  
### version 5.7  
- Adição do botão de up.  
- Adição da separação por pastas na aba playlists.  
- Troca de playlist onde era a aba Todas.  
- Correção no supercontrol, para que tenha acesso a novas playlists, incluindo a playlist principal.  
- Adição de um número que indica quantas faixas estão selecionadas atualmente.  
- Ao fazer alguma ação com as musicas selecionadas, a seleção é retirada.  
  
### version 5.8  
- Adicionado suporte para linux.  
- Correção de máximo de linhas para os artistas.  
- Adição da função de up para músicas, onde um up faz ela subir na ordem.  
- Alterações na mediaAtual.  
  
### version 5.8.1   
- Ao iniciar o app pela primeira vez, todas as músicas serão exibidas na tela inicial.  
- Correção no up para seu uso ser apenas local.  
- Alterações feitas no UP para que seja mais estável.  
- Possibilidade de apagar todos os UPs de uma ou todas as playlists.  
  
### version 5.9  
- Correção de Slices no topo das listas de conteudo quando organização em UP.  
- DESUP adicionado, com reorganização (UP - DataAZ - DESUP).  
- UP e DESUP funcionando em todas as setlists, sem necessidade de torna-la principal.  
  
### verion 5.10  
- Otimização de código e inicio de controle de fila dinâmica.  
- Correção do travamento por conta de troca abrupta de faixas consecutivamente.  
  
### version 5.10.2  
- Mais otimizações de código.  
- Introdução de boas práticas de programação para evitar dados dynamics.  
- União do player_eko com o player normal.  
- Otimização no código da edição desktop.  
- Correção no desktop para não ficar acumulando músicas no temporário.  
- Novas indentificações de conexão com o desktop.  
- Correção das playlists no modo SuperControl.  
- Adição do botão de up e checkpoint no SuperControl.  
  
### version 5.11  
- Correção da lista ficar sendo reindexada enquanto recebia novas midias, no desktop.  
- Otimização de codigo no desktop.  
- Adição da tecla de atalho `espaço` para pausar a midia em reprodução.  
- Relayout de desktop com versão horizontal e vertical.  
  
### version 5.11.1  
- Troca de plugin do ffmpeg para audiotags.  
- Correção da visualização da imagem.  
  
### trying_github_actions  
- Criando uma maneira de buildar para windows, programando pelo linux.  
  
### version 5.12  
- Correção de bugs de redimensionamento.  
- Mudança na logica da imagem.  
- Melhora no frame da imagem.  
- Adição da troca de dados entre android e desktop para shuffle e loop.  
- Correção no slider de tempo da musica ao redimensionar janela.  
  
### version 5.13  
- Adição das opções minimizar/restaurar e fechar musync de Desktop via controle remoto(android).  
- Correção do modo de loop one.  
- Correção em algumas lógicas de comunicação.  
  - Shuffle e Repeat não precisam ser enviados pela media atual.  
  - Shuffle e Repeat são sincronizados no Desktop de acordo com o Android logo no inicio da conexão.  
  - Nome da playlist atual é enviada para o Desktop.  
- Adição de fontes para textos especificos.  
- Correção dos valores nos campos de informações de cada musica.  
- Implementação da logica para indices ainda não recebidos (inacabado).  

### version 5.13.1  
- Novo icone adicionado.  
- Correção de varios deletes simultaneos.  
- Correção da logica para indices não recebidos, fazendo que o botão de next não falhe silenciosamente numa conexão.  
- Correção da altura do player conectado.  
- Adaptação do widget de volume do android para a versão de desktop.  
- Adição da barra de pesquisa (Apenas visual).  
- Correção de slices desnecessários na listContent de desktop.  
  
### version 5.13.2  
- Barra de pesquisa no desktop funcionando.  
- Mudança na logica de algumas listas.  
- Adição do subtitulo ao nome da playlist enviada para o desktop.  
- Alteração no tamanho da imagem no desktop, para escala da tela.  
- Remoção da possibilidade de selecionar mais de uma musica na versão de desktop.  
- Adição de um modo desenvolvedor para visualizar a comunicação do desktop com o android.  
- Otimização na lógica de envio de dados.  
- Tentativa de manter o app em funcionamento por mais tempo no android, antes que ele seja fechado e tenha que reiniciar.  

### version 5.13.3  
- Correção de visualização de log.  
- Correção de redundancia.  
- Correção ao selecionar uma musica no android, enviar o indice correto para o desktop.  
- Adição de highlight aos logs do desktop, permitindo parametros visuais que não são necessários para o sistema.  

### version 5.14  
- ### REATIVAÇÃO DA PAGINA DE DOWNLOAD.  
- Mudanças na maneira que um audio é baixado.  
- Alterações na pagina de downloads.  
- Alteração na logica de recreateQueue, onde o indice é mantido caso haja delete de musicas, e o indice atual não esta sendo deletado.  
  
### TO FUTURE VERSIONS  
+ Corrigir indices não recebidos quando o item ainda for clicado manualmente no android. Verificar se não foi clicado no botão de next com o shuffle ativo, e mostrar mensagem na tela dizendo que o indice ainda não foi enviado para o desktop, alem de retornar a musica anterior. [O erro ocorre no android side, função SendMediaIndexShuffleOutOfLimits].  
+ Corrigir separação de indices não recebidos enviados pelo desktop para o android na segunda metade [O erro ocorre no android side, função SendMediaIndexShuffleOutOfLimits].  
+ Criar checkpoint para reiniciar músicas.  
+ Atualizar o README para explicar novas adições.  
+ Fazer com que ao dar up em uma música a lista se mantenha intacta até que a faixa termine, e só depois a musica upada vai para o primeiro da lista, evitando que um up te tire do index em que estava.  
+ Criar formato de fila dinamica, para guardar musicas, organização, tipo de reprodução de stack [aleatorio/repetir], agrupamento de musicas iguais / semelhantes [slowed/spedup] TO v6.0.   
+ Criar notificador para quando uma música for upada.  
+ Corrigir inicio de musica ao recriar lista no desktop.  
+ Corrigir Mudança de playlist antes de carregamento total deve parar de enviar a playlist antiga e começar a nova.  
+ Dividir lista de ids de musicas ja baixadas no desktop para não ocupar toda a memoria do socket.  