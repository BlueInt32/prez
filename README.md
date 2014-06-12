#Retour d'expérience

Ce document présente mon expérience technique de création d'un écran de monitoring des fichiers échangés par un service de gestion d'inscriptions de jeu Canal+.

##L'entreprise RAPP
RAPP est une agence de communication située à Saint-Ouen. Les projets qui y sont développés sont de type vitrine ou tirage au sort.

##Contexte du projet

Rapp développe depuis 2 ans des jeux pour Canal + portant le nom Collecte : l'objectif est de créer de nouveaux abonnés en faisant gagner des cadeaux. Le jeu collecte en cours est le n°4.

![Jeu actuel](https://raw.githubusercontent.com/BlueInt32/prez/master/img/ScreensJeu/Home.jpg)

Pour ces jeux, RAPP fait appel à une entreprise marketing, TradeDoubler, dont le rôle est d'amener un maximum de gens sur le jeu via des bannières sur des sites affiliés. 

**La problématique fonctionnelle principale du projet est que Canal+ doit donc rémunérer TradeDoubler pour les inscrits au jeu qu'il n'avait pas encore dans sa base, les "leads validés" mais pas les autres !**

####Les intervenants du projet
Le processus de collecte fait intervenir 3 entités différentes : RAPP, Canal+ et TradeDoubler. 

**RAPP** développe le jeu : le site web et les services associés. Il remplit essentiellement une base de données d'inscrits (table Users).

**Canal+** n'a comme mission de notre point de vue que de dire si une personne est déjà inscrite ou non dans sa base de données.

**TradeDoubler** est une entreprise spécialisée dans le marketing internet. Elle est lié à un grand nombre de sites dits "affiliés" acceptant de diffuser de la publicité pour les clients de TradeDoubler (en l'occurence Canal+), et dans ce cas pour amener les gens sur le jeu Collecte. Canal+ doit rémunérer TradeDoubler pour cela, en fonction du nombre d'inscrits au jeu provenant des affiliés TradeDoubler.

####Le fonctionnel en bref
Pendant le jeu, RAPP fournit quotidiennement à Canal+ la liste des inscrits du jour. Canal+ doit comparer ces données avec sa base et retourner la liste complétée indiquant pour chaque inscrit un statut OK ou KO suivant le fait qu'il est validé ou non.

RAPP transforme cette liste pour TradeDoubler ne gardant que les ID et le status validé ou non et l'envoie à TradeDoubler qui sera capable de retrouver les gens qu'elle a ramenés avec un système de tracker mis en place sur le jeu.
Concrètement, les listes en question sont des fichiers csv et xml déposés sur les différents serveurs FTP des intervenants. C'est un service Windows, appelé "Moulinette" qui gère chez RAPP l'envoi et la réception de ces fichiers.

Pour les temps précédents, la mécanique n'était pas rodée et il y a eu plusieurs problemes d'accès, de moulinette cassée, de démission de chefs de projet... Ce qui a posé quelques problèmes de sous.
Pour le jeu n°4, il a été décidé de mettre en place un système de monitoring de l'ensemble des fichiers reçus et envoyés à l'ensemble des instances dans un format compréhensible par l'ensemble des personnes concernées chez Rapp.

Une journée de service comprend donc 3 fichiers de données utilisateurs collectées la veille (J-1):
- un fichier csv "IN" (généré par Rapp pour Canal)
- un fichier csv "OUT" (généré par Canal, modifié avec les status "déjà inscrits")
- un fichier xml (généré par Rapp pour TradeDoubler)

####La technique en bref
Le service Moulinette tourne en permanence sur le serveur web pendant toute la phase de jeu. Tous les jours à minuit, il récupère la liste de tous les inscrits de la journée, les insère dans un csv (fichier "IN") et les envoie en ftp à Canal+. 

Canal est censé retourner cette même liste modifiée (portant les status "déjà inscrits" ) vers midi dans un répertoire ftp, c'est le fichier "OUT". La Moulinette détecte la création d'un fichier dans le répertoire, recoupe les données avec la base de données du jeu, génère un fichier XML avec les id ("lead numbers") et les status Canal+ correspondant et enfin envoie le fichier chez TradeDoubler.

L'écran de monitoring de cette mécanique, beaucoup plus simple que tout cela, est l'objet de cette présentation.

##L'Ecran de monitoring

L'objectif de cette simple page web est de montrer une structure d'arbre représentative de groupes de fichiers et leur metadonnées triés par date décroissante, groupés par semaines. On veut pouvoir prévisualiser le contenu de chaque fichier ou le sauvegarder.  

Un groupe de fichiers est appelé "Bundle". Il est fondamentalement lié à une date (car le service tourne une fois par jour) contient une énumération d'état, plusieurs informations sur les données envoyées et reçues et une liste de BundleFile (les fameux fichiers IN, OUT et XML), eux-meme ayant une date de creation.

Ma présentation se fera logiquement dans le sens de la couche d'accès aux données en EF 6 Code First jusqu'au front-end en AngularJS, en passant par Web API 2.

Ce projet est essentiellement à mon initiative et a été pour moi un excellent prétexte pour mettre en place l'ensemble des technologies sur lesquelles je me suis penché récemment. La possibilité d'autogérer un projet de bout en bout, très spécifique au client RAPP (de type agence) permet de d'avoir un bon recul sur l'ensemble des problématiques techniques d'un projet.

#Code First 

Code First est une brique d'Entity Framework dont la philosophie est de coder son modèle de données en C# (ou en VB.net), et de laisser Entity Framework gérer la base de données grace à quelques commandes et à un système de migration.

###Créer les POCO

On commence donc naturellement par la définition des POCO, ou "Entités". Dans la définition de nos POCO, il n'est fait aucune mention du systeme de persistance, aucun héritage particulier n'est nécéssaire. Cela permet de compter sur ces POCO partout dans l'application sans se soucier des références. 

![](https://raw.githubusercontent.com/BlueInt32/prez/master/img/ClassDiagram.png)

![](https://raw.githubusercontent.com/BlueInt32/prez/master/img/ScreensCode/Code%20First/CollecteContext%20-%20POCO%20-%20Bundle.jpg) 


![](https://raw.githubusercontent.com/BlueInt32/prez/master/img/ScreensCode/Code%20First/CollecteContext%20-%20POCO%20-%20BundleFile.jpg)


![](https://raw.githubusercontent.com/BlueInt32/prez/master/img/ScreensCode/Code%20First/CollecteContext%20-%20POCO%20-%20BundleFileType.jpg)


![](https://raw.githubusercontent.com/BlueInt32/prez/master/img/ScreensCode/Code%20First/CollecteContext%20-%20POCO%20-%20BundleStatus.jpg)

Dans le POCO, par convention on distingue 2 types de propriétés : les propriétés scalaires et les propriétés de navigation (interactions entre entités).

On ajoute virtual sur les propriétés de navigation pour permettre le lazy loading. 


On peut désactiver le lazy-loading. [Définir : Lazy Loading]


###Création du contexte

![](https://raw.githubusercontent.com/BlueInt32/prez/master/img/ScreensCode/Code%20First/CollecteContext.jpg)

C'est une classe qui dérive de DbContext, une brique de base d'EF. 

Le contexte représente une session d'accès à la base de donnée, et permet de requeter et de sauvegarder des données. DbContext applique les patterns Unit Of Work et Repository Pattern, de sorte que les changements qu'on effectue sur celui-ci sont regroupés pour être appliqués d'un seul coup. 

[Définir : Unit Of Work, Repository Pattern]


Pour chaque type que l'ont veut persister dans la base, on doit créer dans notre contexte un DbSet correspondant. Le DbSet représente une collection d'entités, reflétant une table de la base.

###Utilisation du contexte

Le DbContext s'utilise pratiquement comme
Montrer comment on crée des POCO, comment on ajoute des entités aux dbsets, comment on sauvegarde. Montrer comment on requete la base (en linq).


###Systeme de migration

Sans rien faire de plus (config), par défaut, EF crée en local une base portant le nom qualifié du contexte que l'on a créé et y ajoute les tables correspondantes aux DbSets quand il en a besoin, c'est à dire lors de la premiere session de debug. Pour ne pas laisser EF faire lui-meme le update-database : voir ici Si l'on veut modifier notre model pendant le developpement, on peut utiliser les migrations.

`Enable-Migrations`

Ceci fait les choses suivantes :

- Créer un dossier Migrations et deux classes dans le projet
- Configuration.cs : elle contient les informations necessaires à la gestion des migrations (dossiers, enregistrement de providers, seed) notemment la valeur de propriété AutomativMigrationsEnabled par défaut à false (cela implique qu'on est obligé de créer les fichiers de mimgration localement pour appliquer les changements sur la base).
- Un fichier de migration (héritant de DbMigration) horodaté : représente la création effective des tables de la base, au moment où la commande a été lancée.
- Créer une table migration dans la base, qui référence la derniere migration effectuée et spécifie qu'elle a été appliquée.
Après la modification du modele (ajout de propriété dans une entité par exemple) :

`Add-migration <Nomchoisi>`

Ceci ajoute un fichier de migration représentant le delta effectué dans la base, mais également l'eventuel rollback. Ceci ne modifie pas la base de données.

`Update-Database`


Ceci regarde dans la table migration de la base de données, constate quelle migration a été appliquée en dernier et applique celles qui ne le sont pas encore.
Sortir des conventions :
* Data Annotations (possible aussi avec FluentApi mais j'ai jamais été voir)
Les conventions Code First attendent que les propriétés de nos poco correspondant aux clefs primaires soient suffixées par "Id". Si on ne veut pas cela, il faut ajouter un attribut de type DataAnnotations nommé Key à la propriété désirée pour qu'EF s'y retrouve.
* Fluent Api
Permet de modifier à loisir la persistance par défaut effectuée par code first. Par exemple, il est possible de modifier le nom d'une colonne dans la table en overridant OnModelCreating de notre contexte : modelBuilder.Entity<PocoClass>().Property(poco => poco.propertyName).HasColumnName("salut")
Web API
La brique WebApi d'ASP.net permet de mettre en place des services "RESTful" accessible dans un format d'échange compris par une large gamme de clients (ici JSON) : le point clef est l'interroperabilité.

Meme si cet aspect n'a pas été exploité dans ce projet, il aurait été relativement facile d'implémenter l'interface d'affichage dans une application desktop, sur iPhone ou n'importe quelle plateforme "Front".

Contrairement à ASP.net MVC, Web Api utilise le verbe HTTP pour déterminer quelle action de controlleur sera effectuée : 

HTTP GET pour récupérer des données (liste ou élément unique)
HTTP POST : pour enregistrer un nouvel element
HTTP PUT : pour modifier un element
HTTP DELETE : pour supprimer un élément

Ainsi pour le routing, on ne précisera plus l'action de controlleur, car elle sera mappée automatiquement en fonction du paramètres et du verbe HTTP.


Le monitoring n'a besoin que de 2 gets : 
- un get pour les bundles, groupés par numéros de semaine. Concrètement :
public IEnumerable< KeyValuePair< int, List< Bundle>>> GetAllBundles()
Cette méthode devra être accessible en GET via la route : api/bundles/
- un get pour le contenu d'un fichier dont le chemin relatif est fourni en paramètre : 
public string Get( string path)



Cette méthode devra être accessible en GET via les routes api/bundlefiles/[relative/path/to/file/filename.csv]


La première route est définie par défaut dans la configuration de l'API : 

La seconde est définie en utilisant l'Attribute Routing : 



Front End Angular JS

























