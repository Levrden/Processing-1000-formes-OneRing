/*OneRing : Générateur de particules
 Ce script génère des particules au curseur de la souris pendant qu'un bouton de la souris est pressé. 
 Il dessine un trait, appelé plexus, entre chaque particules, si elles son assez proches les unes des autres
 Les particules ont une durée de vie aléatoire, comprise entre min et max (500 et 5000 par défaut) frames 
 Quand le nombre maximal de particules est atteint (1000 par défaut) il faut attendre que certaines meurent (oui, c'est triste, mais c'est comme ça)
 pour pouvoir en faire apparaître de nouvelles. (l'humanité devrait peut-être s'en inspirer...)
 
 Il y a également un trou noir, "The Ring" qui débute au centre de l'écran. On le déplace avec les flèches directionnelles, et plus il mange de particules, plus il grossit.
 
 Je ne suis pas sûr d'avoir compris pourquoi une fois arrivé à 1000 particules, impossible d'y retourner sans attendre très longtemps...
 C'est surement dû au fait que les particules ne peuvent apparaitre que toutes les frames, mais peuvent mourir plus vite...
 
 Pour améliorer et simplifier le dessin du trou noir, j'ai découvert les effets javafx qui permettent de créer des flous au lien de faire des dégradés à la main dans une boucle... qui sont très gourmands... 
 J'ai tout de même conservé ma première version du trou noir, en commentaire, à la fin, qui est plus jolie et plus ressemblante, mais plus gourmande en performances
 */

// VARIABLES EDITABLES PAR L'UTILISATEUR//
int ptSize = 3;       //la taille des particules
int vit = 1;          //la vitesse des particules
float bhVit = 0.7;    //la vitesse d'expansion du trou noir
int plexusDist = 120; //la distance maximale à laquelle les particules sont reliées par un plexus (une ligne)
int partNumb = 1000;  //quantité maximale de particules
int min = 900;        //durée de vie minimale des particules
int max = 9000;       //durée de vie maximale des particules

// VARIABLE PROPRES AU SCRIPT -- MODIFIER C'EST RISQUÉ!//
//librairie pour exporter une vidéo, mettre en commentaire si elle n'est pas installée // https://funprogramming.org/VideoExport-for-Processing/
//import com.hamoid.*;
//VideoExport videoExport;
//Effets
import javafx.scene.canvas.*;        //Importer le gestionnaire d'effets JavaFX
import javafx.scene.effect.BoxBlur;  //Importer l'effet BoxBlur, moins groumand que GaussianBlur
GraphicsContext ctx;                 //Définit un contexte graphique pour les effets
BoxBlur fxBoxBlur = new BoxBlur();   //Déclare une nouvelle variable de type Boxblur
//Mécaniques de jeu
boolean start = false;               //Affiche l'écran d'accueil
boolean gameOver = false;            //Affiche l'écran de fin
boolean mouseBeingPressed = false;   //une variable (qui devrait être native à Processing!) permettant de savoir quand un bouton de souris est enfoncé sur la durée
int osc = 0;                         //Oscillateur numérique pour l'animation des textes
boolean oscLimit = false;            //True quand l'oscillateur est arrivé en dehors de ses limites
//Particules
Particle t[];                        //créé un tableau de particules
int partCount;                       //compteur de particules affiché dans la console
int oldPartCount = partCount-1;      //mémorise le dernier compte de particules (partCount) à l'image précédente
int initPart=0;                      //compteur de particules qui permet de faire apparaitre les particules une par une. On l'apellera curseur dans les commentaires pour ne pas le confondre !
//Trou noir
int bhX, bhY;                        //la position du trou noir
float bhSize = 25;                   //la taille du trou noir

// CREATION D'UNE CLASSE PARTICULE PARCE C'EST PLUS CLASSE (pire blague a monde)//
class Particle {
  float posX;    //position en x de la particule
  float posY;    //position en y de la particule
  float vitX;    //vitesse en x de la particule
  float vitY;    //vitesse en y de la particule
  float hue;     //teinte de la particule, qu'elle gardera toute sa vie
  color col;     //couleur de la particule
  int lifeT;     //durée de vie restante de la particule

  void initialize() {                      //Initialisation des propriétés//
    posX = mouseX;                         //On veut que les particules apparaissent 
    posY = mouseY;                         //au curseur de la souris
    vitX = random(-vit, vit);              //On leur donne une vitesse aléatoire  
    vitY = random(-vit, vit);              //dans toutes les directions
    hue = map(mouseX, 0, width, 0, 360);   //la teinte de la particule dépend de son x de naissance
    lifeT = 0;                             //Quand elles sont initialisées, elles sont encore "endormies", et n'ont pas de durée de vie
  }
}

//AU COMMENCEMENT...//
void setup() {                                                    
  colorMode(HSB, 360, 100, 100, 100);                            //mode de couleur Teinte, Saturation, Luminosité, Alpha
  fullScreen(FX2D);                                              //On se met en plein écran, environnement FX2D
  bhX = width/2;                                                 //On initialise le trou noir au centre de l'écran
  bhY = height/2;
  t = new Particle[partNumb];                                    //Initialisation du tableau de particules et réservation de la taille dans le buffer
  for (int i=0; i<t.length; i++) {                               //Première boucle qui attribue la classe Particle aux éléments de t[]
    t[i]= new Particle();
  }
  //Mettre en commentaire si la librairie n'est pas installée
  //videoExport = new VideoExport(this);
  //videoExport.startMovie();
}



//A CHAQUE FRAME...//
void draw() {      
  background(0);                         //Dessin de l'arrière plan noir à chaque nouvelle frame
  osc();                                 //On lance l'Oscillateur
  if (start) {                           //Si l'écran de démarrage n'est pas présent
    if (bhSize*2<height) {               ///Si le trou noir ne prend pas toute la hauteur de l'écran

      //DESSIN ET DEPLACEMENT DES PARTICULES//
      if (mouseBeingPressed) {           ////Si un bouton de la souris est pressé
        dessine();                       ////alors on initialise les particules
      }
      deplace();                         ///déplacer les particules suivant la fonction éponyme

      //ON LES COMPTE//
      if (oldPartCount != partCount) {   ////Si le compteur de particules a changé 
        println(partCount);              ////Alors on l'imprime
        oldPartCount = partCount;        ////On incrémente le vieuxCompteur
      }
      //TROU NOIR ET FIN DE JEU//
      blackHole(bhX, bhY, bhSize);                       ///On dessine le trou noir
    } else {                             ///Si le trou noir prend toute la hauteur de l'écran
      gameOver();                        ///Le jeu est fini, on appelle la fonction qui affiche l'écran de fin
      gameOver=true;                     ///On tourne le booléen associé à vrai
    }
    //DEBUT DU JEU//
  } else {                               //Si le jeu n'est pas démarré
    startScreen();                       //Afficher l'écran de démrrage
  }
  //Export Vidéo, mettre en commentaire si la librairie n'est pas installée
  //videoExport.saveFrame();
}

//Initialisation des particules : fonction dessine//
void dessine() {                                    //Pas de boucle ici, il s'agit d'initialiser et de ne faire apparaitre qu'une particule par frame
  if (t[initPart].lifeT<1) {                        //Si la particule au curseur est "morte"
    t[initPart].initialize();                       //alors, on la réinitialise
    t[initPart].lifeT = int(random(min, max));      //et on lui attribue une durée de vie aléatoire
  }     
  if (initPart==t.length-1) {                       //Si le curseur est arrivé au bout du tableau
    initPart=0;                                     //alors, le réinitialiser
  } else {                                          //sinon,
    initPart++;                                     //l'incrémenter
  }
}

//Déplacement des particules : fonction deplace//
void deplace() {
  partCount = t.length;                                                     //On commence par réinitialiser le compteur de particules à son maximum : la longueur du tableau

  for (int i=0; i<t.length; i++) {                                          //Boucle qui parcourt toute la longueur du tableau

    if (t[i].lifeT>0) {                                                     //Si la particule est en vie
      //DESSIN DES PARTICULES//
      t[i].col = color(t[i].hue, oldPartCount/10+10, oldPartCount/10+10);   //On lui attribue sa teinte et une saturation et une luminosité qui dépendent du nombre de particules en tout
      stroke(t[i].col);                                                     //on lui attribue sa couleur
      strokeWeight(ptSize);                                                 //on lui donne une taille
      point(t[i].posX, t[i].posY);                                          //on la dessine

      float distance = dist(t[i].posX, t[i].posY, bhX, bhY);                //On calcule sa distance avec le trou noir

      //DÉPLACEMENTS//
      if (distance<1.4*bhSize) {                                            //Si la particule est proche du trou noir
        t[i].posX=lerp(bhX, t[i].posX, 0.9);                                //Alors il l'aspire !
        t[i].posY=lerp(bhY, t[i].posY, 0.9);                                //
      } else {
        t[i].posX=t[i].posX+t[i].vitX;                                      //Sinon elle poursuit son chemin... 
        t[i].posY=t[i].posY+t[i].vitY;                                      //Et sa nouvelle position dépend de sa vitesse
      }
      if (distance<bhSize) {                                                //Mais si elle est dans le trou noir
        t[i].lifeT=0;                                                       //Alors elle meurt
        bhSize+=bhVit;
      }                                                                     //Et le trou noir grandit

      //PLEXUS//
      for (int j=0; j<t.length; j++) {             //Il s'agit maintenant de faire une boucle dans une boucle : on veut mesurer les distances entre toutes les particules
        if (t[j].lifeT>0) {                        //Si la particule comparée est en vie
          plexus(i, j);                            //Alors on appele la fonction plexus, avec les deux particules en paramètres
        }
      }

      //REBONDS//
      if (t[i].posX>width) {                       //Place aux rebonds, on vérifie que
        t[i].vitX = -t[i].vitX;                    //si la particule sort du cadre, sa vitesse est alors inversée
      }
      if (t[i].posX<0) {                           //
        t[i].vitX = -t[i].vitX;                    //
      }
      if (t[i].posY>height) {                      //
        t[i].vitY = -t[i].vitY;                    //
      }
      if (t[i].posY<0) {                           //
        t[i].vitY = -t[i].vitY;                    //
      }

      t[i].lifeT --;                               //à la fin de la boucle, on réduit la vie de la particule
    } else {
      partCount --;                                //Si la particule n'est pas en vie, on décrémente le compteur au lieu de la déplacer
    }
  }
}

//FONCTIONS//

//Fonction de dessin des plexus !!//
void plexus(int x, int y) {
  float distance = dist(t[x].posX, t[x].posY, t[y].posX, t[y].posY); //On commence par calculer la distance entre deux points
  if (distance<plexusDist) {                                         //la comparer à la distance max définie par l'utilisateur


    strokeWeight(ptSize/2*(plexusDist-distance)/plexusDist/2);       //Ensuite on définit l'épaisseur du plexus en fonction de l'éloignement des particules et de leur taille.
    //                                                                 Plus elles seront éloignées l'une de l'autre, plus le plexus sera fin.
    stroke(lerpColor(t[x].col, t[y].col, .5));                       //On attribue au plexus une couleur égale à la moyenne des deux
    line(t[x].posX, t[x].posY, t[y].posX, t[y].posY);                //On dessine le plexus, avec comme paramètres les positions des deux particules
  }
}

//Fonction de dessin du trou noir, x est bhX, y est bhY, l est bhSize//
void blackHole(int x, int y, float l) {                        //Pour dessiner le trou noir, j'ai voulu refaire celui qui a été récemment (été 2019) pris en photo
  //                                                           //C'est le premier a avoir pu être photographié, les représentation habituelles n'étaient que des suppositions
  //                                                           //On peut le voir ici : https://en.wikipedia.org/wiki/Black_hole#/media/File:Black_hole_-_Messier_87_crop_max_res.jpg
  ctx = ((Canvas) surface.getNative()).getGraphicsContext2D(); //Il faut initialiser le contexte des effets pour qu'ils apparaissent
  fxBoxBlur.setWidth(5);                                       //On définit la taille du flou
  fxBoxBlur.setHeight(20);                                     //Dans les deux sens
  //fxBoxBlur.setIterations(20);                               //Permet d'augmenter la résolution du flou mais est gourmand et pas vraiment nécessaire ici

  ctx.setEffect(fxBoxBlur);                                    //On active l'effet de flou

  //DESSINS//                                                  //A chaque fois, la couleur, la taille, la transparence, et la position des dessins dépendent de la taille du trou noir
  //ligne diagonale arrière
  strokeWeight(l-20);
  stroke(10, 100, 80-l/2, 80-l/2);
  line(bhX-l/2-l/8, bhY-l/2-l/8, bhX+l/2+l/8, bhY+l/2+l/8);

  //ligne basse arrière
  strokeWeight(l-20);//50-0
  stroke(10, 100, 80-l/2, 80-l/2);//25-75
  line(x-l/2-l/4, y, x+l/2+l/4, y-l/4);

  //Disque Principal
  ////Orange
  noStroke();
  fill(16, 100, 80);
  ellipse(x, y, 2*l, 2*l);
  ////Noir
  fill(0, 0, 0);
  ellipse(x, y, l+l/2, l+l/2);

  //ligne brillante avant
  strokeWeight(l/4);
  stroke(30, 100, 100, 40-l/8);
  line(x, y+l/1.1, x+l/1.1, y+l/4);

  //point brillant avant
  strokeWeight(l/4);
  stroke(30, 100, 100, 40-l/8);
  point(x-l/1.1, y+l/6);

  ctx.setEffect(null);                    //On arrête l'effet de flou
}


//DETECTION INTERACTIONS//
//Détection des clics et relâches de la souris
void mousePressed() {               //Quand un bouton est pressé
  mouseBeingPressed = true;         //On dit qu'il est pressé à mouseBeingPressed

  float distanceBegin = dist(mouseX, mouseY, width/2, height/2+80); //Distance entre la souris et le bouton Begin
  float distanceReset = dist(mouseX, mouseY, width/2, height/2+70); //Distance entre la souris et le bouton Try Again

  if (!start && distanceBegin<40) {                                 //Détection de l'appui sur Begin
    start = true;                                                   //On fait démarrer le jeu
  } 
  if (gameOver && distanceReset<40) {                               //Détection de l'appui sur Try Again
    bhSize = 25;                                                    //On réinitialise la taille du trou noir, ce qui redémarre le jeu automatiquement
  }
}

void mouseReleased() {              //Quand le même bouton est relâché
  mouseBeingPressed = false;        //On dit qu'il est relâché à mouseBeingPressed
}

//Détection des touches du clavier//
void keyPressed() {
  if (key == CODED) {
    //Déplacement du trou noir
    if (keyCode == UP && bhY>0) {
      bhY=bhY-5;
    } else if (keyCode == DOWN && bhY<height) {
      bhY=bhY+5;
    } else if (keyCode == LEFT && bhX>0) {
      bhX=bhX-5;
    } else if (keyCode == RIGHT && bhX<width) {
      bhX=bhX+5;
    //Arrêt de l'enregistrement vidéo
    } else if (key == 'r') {
      //videoExport.endMovie();
      exit();
    }
  }
}
//TEXTES//

//Oscillateur pour les boutons de texte
void osc() {
  if (osc<360 && !oscLimit) {
    osc=osc+3;
  } else if (osc>0) {
    osc=osc-3;
    oscLimit = true;
  } else {
    oscLimit = false;
  }
}

//Base pour les écrans
void screenCommon() {
  blackHole(bhX, bhY, bhSize);                      //On dessine le trou noir
  noStroke();
  fill(0, 0, 0, 50);
  square(0, 0, width);                              //On dessine un écran noir semi transparent sur tout l'écran
  PFont mono;
  mono = loadFont("Consolas-32.vlw");               //On charge une police rétro
  fill(360);                                        //On attribue de la couleur à un texte
  textFont(mono);                                   //On lui attribue la bonne police
  textAlign(CENTER);                                //On l'aligne
  textSize(25);                                     //On lui donne une taille
}

//Écran de démarrage
void startScreen() {
  //On appelle la base des écrans
  screenCommon();
  //On écrit le texte démoniaque
  text("You are the ring, a black hole.", width/2, height/2-100);                  
  text("You can rule them all, find them, bring them, ", width/2, height/2-50);
  text("And in the darkness bind them.", width/2, height/2);
  text("Clic to rule, arrows to find", width/2, height/2+50);
  //Sans oublier d'activer l'oscillateur pour la couleur du bouton
  fill(osc);
  text("BEGIN", width/2, height/2 + 100);
}

//Écran de fin
void gameOver() {
  //On appelle la base des écrans
  screenCommon();
  //On se moque du joueur
  text("Oooooh, too bad, you've lost...", width/2, height/2);
  textSize(8);
  text("Oh, by the way, there's no way to win... but you can try again !", width/2, height-64);
  textSize(25);
  fill(osc);
  text("TRY AGAIN", width/2, height/2+64);
}

/*//Ancien Dessin du trou noir...Ca fonctionne, et c'est plus joli, mais encore plus gourmand que le box blur //
 void blackHole(int x, int y) {                   //J'ai superposé des lignes dans des boucles pour créer des dégradés
 
 //ligne diagonale
 for (float f=bhL; f<bhR; f=f+2) {
 strokeWeight(bhR-f);//50-0
 stroke(16, 50, 30, 2);//25-75
 line(x-35, y-35, x+35, y+35);
 }
 
 //ligne basse
 for (float f=bhL; f<bhR; f=f+2) {
 strokeWeight(bhR-f);//50-0
 stroke(16, 50, 30, 2);//25-75
 line(x-40, y, x+35, y-5);
 }
 
 //ligne brillante
 for (float f=bhL; f<bhR-20; f=f+0.7) {
 float g=25;
 strokeWeight(bhR-f-20+bhL/3-8);//50-0
 stroke(1.4*g-20, 100, 80, 1);
 line(x+bhL/4-6, y+bhL/4+19, x+bhL/4+14, y+bhL/4+4);
 g=g+0.7;
 }
 //point brillant
 for (float f=bhL; f<bhR-20; f=f+0.7) {
 float g=25;
 strokeWeight(bhR-f-20+bhL/3-8);
 stroke(1.4*g-20, 100, 80, 1);
 point(x-bhL/4-9, y+bhL/4+10);
 g=g+0.7;
 }
 
 //Disque Principal
 for (float f=bhL; f<bhR; f=f+0.5) {
 noStroke();
 fill(18, 100, 80, 1);
 ellipse(x, y, f, f);
 }
 for (float f=0; f<bhR-25; f=f+0.5) {
 fill(0, 0, 0, 2);
 ellipse(x, y, f, f);
 }
 }*/
