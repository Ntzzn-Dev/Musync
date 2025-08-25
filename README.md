# musync

**Projeto:** musync  
**Autor:** Jhonatan | Nathan  
**GitHub:** [https://github.com/Ntzzn-Dev](https://github.com/Ntzzn-Dev)  
**Data:** 05/07/2025  
![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)  
![Platform](https://img.shields.io/badge/Android%20%7C%20Windows-Supported-green?style=for-the-badge)   

## Descrição  

Um aplicativo mobile com capacidade de organizar musicas locais, reproduzi-las, baixar e transferir as musicas entre plataformas.   

## Demonstração  

### Tela Principal  
Tela onde ficam todas as músicas encontradas.  
O player abaixo se possui os botões principais para controle da mídia.  
<p float="left">
<img src="assets/main_tab.jpg" width="300"/>
<img src="assets/main_tab_more_opt.jpg" width="300"/>  
</p>

### Configurações e Downloads  
Na tela de configurações são definidos:  
- os diretórios onde as músicas são baixadas pelo downloader.  
- a playlist padrão que a tela de downloads carrega.  
- os diretórios onde são buscadas as mídias.  

Na tela de donwload, a playlist padrão é carregada permitindo a seleção de uma ou mais mídias para download.  
O download é feito através de vídeos do youtube.  
<p float="left">
<img src="assets/config_page.jpg" width="300"/>
<img src="assets/download_page.jpg" width="300"/>  
</p>

### Informações e Opções de Música  
<p float="left">
<img src="assets/music_info.jpg" width="300"/>
<img src="assets/music_more_opt.jpg" width="300"/>  
</p>

### Playlists  
Página que controla as playlists, criadas pelo usuário ou as separadas por artista.  
<p float="left">
<img src="assets/playlists_tab.jpg" width="300"/>
<img src="assets/add_playlist.jpg" width="300"/>  
</p>

### Player da Notificação 
Na notificação estão as ações mais importantes, incluindo controle de aleatório.   
<img src="assets/notify_bar.jpg" width="300"/>  

## Instalação  
1. Clone este repositório:  
  ```git clone https://github.com/Ntzzn-Dev/Musync.git```  
2. Entre na pasta e rode (para android):  
  ```cd musync_and```  
  ```flutter pub get```  
  ```flutter run``` 
3. Entre na pasta e rode (para desktop):  
  ```cd musync_dkt```  
  ```flutter pub get```  
  ```flutter run```  

## Tecnologias  
- Flutter (Dart)  
- SQLite (armazenamento local)  
- WebSocket (conexão via wi-fi local)

## Contribuição
Sinta-se à vontade para abrir issues ou sugerir melhorias!  

## Log de versões
- **v1.0** → Versão inicial, player básico.
- **v2.0** → Download de músicas via YouTube.
- **v3.0** → Configurações avançadas, playlists e melhorias no modo aleatório.
- **v4.0** → Integração do desktop, e configuração para que o android aja como um controle remoto.

Veja o changelog completo em [CHANGELOG.md](CHANGELOG.md)