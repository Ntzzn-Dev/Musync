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
- Adição da tela de Controle
- Otimização no recebimento de mensagens do ekosystem
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