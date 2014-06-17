#Retour d'expérience

Ce document présente mon expérience technique de création d'un écran de monitoring des fichiers échangés par un service de gestion d'inscriptions de jeu Canal+.


##Contexte du projet

###L'entreprise RAPP
RAPP est une agence de communication située à Saint-Ouen. Les projets qui y sont développés sont de type vitrine ou tirage au sort. 

RAPP développe depuis 2 ans des jeux pour Canal + portant le nom Collecte : l'objectif est de créer de nouveaux abonnés en faisant gagner des cadeaux. Le jeu collecte en cours est le n°4.

![Jeu actuel](https://raw.githubusercontent.com/BlueInt32/prez/master/img/ScreensJeu/Home.jpg)

Pour ces jeux, RAPP fait appel à une entreprise marketing, TradeDoubler, dont le rôle est d'amener un maximum de gens sur le jeu via des bannières sur des sites affiliés. 

**La problématique fonctionnelle principale du projet est que Canal+ doit rémunérer TradeDoubler pour les inscrits au jeu qu'il n'avait pas encore dans sa base, les "leads valides" mais pas les autres !**

###Les intervenants du projet
Le processus de collecte fait intervenir 3 entités différentes : RAPP, Canal+ et TradeDoubler. 

**RAPP** développe le jeu : le site web et les services associés. Il remplit essentiellement une base de données d'inscrits (table Users).

**Canal+** n'a comme mission de notre point de vue que de dire si une personne est déjà inscrite ou non dans sa base de données.

**TradeDoubler** est une entreprise spécialisée dans le marketing internet. Elle est lié à un grand nombre de sites dits "affiliés" acceptant de diffuser de la publicité pour les clients de TradeDoubler (en l'occurence Canal+), et dans ce cas pour amener les gens sur le jeu Collecte. Canal+ doit rémunérer TradeDoubler pour cela, en fonction du nombre d'inscrits au jeu provenant des affiliés TradeDoubler.

###Le fonctionnel en bref
Pendant le jeu, RAPP fournit quotidiennement à Canal+ la liste des inscrits du jour. Canal+ doit comparer ces données avec sa base et retourner la liste complétée indiquant pour chaque inscrit un statut OK ou KO suivant le fait qu'il est validé ou non.
![](https://raw.githubusercontent.com/BlueInt32/prez/master/img/Fonctionnel%20Moulinette%20Donn%C3%A9es.png)

RAPP transforme cette liste pour TradeDoubler ne gardant que les ID et le status validé ou non et l'envoie à TradeDoubler qui sera capable de retrouver les gens qu'elle a ramenés avec un système de tracker mis en place sur le jeu.
Concrètement, les listes en question sont des fichiers csv et xml déposés sur les différents serveurs FTP des intervenants. C'est un service Windows, appelé "Moulinette" qui gère chez RAPP l'envoi et la réception de ces fichiers.


Pour les temps précédents, la mécanique n'était pas rodée et il y a eu plusieurs problemes d'accès, de moulinette cassée, de démission de chefs de projet... Ce qui a posé quelques problèmes de sous.
Pour le jeu n°4, il a été décidé de mettre en place un système de monitoring de l'ensemble des fichiers reçus et envoyés à l'ensemble des instances dans un format compréhensible par l'ensemble des personnes concernées chez Rapp.

Une journée de service comprend donc 3 fichiers de données utilisateurs collectées la veille (J-1):
- un fichier csv "IN" (généré par Rapp pour Canal)
- un fichier csv "OUT" (généré par Canal, modifié avec les status "déjà inscrits")
- un fichier xml (généré par Rapp pour TradeDoubler)

![](https://raw.githubusercontent.com/BlueInt32/prez/master/img/Fonctionnel%20Moulinette%20Fichiers.png)


###La technique en bref
Le service Moulinette tourne en permanence sur le serveur web pendant toute la phase de jeu. Tous les jours à minuit, il récupère la liste de tous les inscrits de la journée, les insère dans un csv (fichier "IN") et les envoie en ftp à Canal+. 

![](https://raw.githubusercontent.com/BlueInt32/prez/master/img/Collecte%20Flowchart%20-%20Apr%C3%A8s%20-%202.png)

Canal est censé retourner cette même liste modifiée (portant les status "déjà inscrits" ) vers midi dans un répertoire ftp, c'est le fichier "OUT". La Moulinette détecte la création d'un fichier dans le répertoire, recoupe les données avec la base de données du jeu, génère un fichier XML avec les id ("lead numbers") et les status Canal+ correspondant et enfin envoie le fichier chez TradeDoubler.

L'écran de monitoring de cette mécanique, beaucoup plus simple que tout cela, est l'objet de cette présentation.

##Le vif du sujet : L'écran de monitoring

L'objectif de cette simple page web est de montrer une structure d'arbre représentative des groupes de fichiers et leur metadonnées triés par date décroissante, groupés par semaines. On veut pouvoir prévisualiser le contenu de chaque fichier ou le sauvegarder.  

![](https://raw.githubusercontent.com/BlueInt32/prez/master/img/Screens%20Monitoring/Screen.jpg)

On peut prévisualiser les fichiers : 

![](https://raw.githubusercontent.com/BlueInt32/prez/master/img/Screens%20Monitoring/ScreenLarge.png)

Un groupe de fichiers est appelé `Bundle`. Il est fondamentalement lié à une date (car le service tourne une fois par jour) contient une énumération d'état, plusieurs informations sur les données envoyées et reçues et une liste de `BundleFile` représentant les fichiers IN, OUT et XML, eux-meme ayant un type et une date de creation.

----------

Cette présentation se fera logiquement dans le sens de la couche d'accès aux données en EF 6 Code First jusqu'au front-end en AngularJS, en passant par Web API 2.

![](https://raw.githubusercontent.com/BlueInt32/prez/master/img/Monitoring%20-%20Architecture.png)

> Ce projet a été pour moi un excellent prétexte pour mettre en place plusieurs technologies sur lesquelles je me suis penché récemment. La possibilité d'autogérer un projet de bout en bout, spécifique au client RAPP (de type agence) permet d'avoir un bon recul sur l'ensemble des problématiques techniques d'un projet.

##Code First 

Code First est une brique d'Entity Framework dont la philosophie est de coder son modèle de données en C# (ou en VB.net), et de laisser Entity Framework gérer la base de données grace à quelques commandes et à un système de migration.

###Créer les POCO

On commence donc de manière intuitive par la définition des POCO ou "Entités". Dans la définition de nos POCO, il n'est fait aucune mention du systeme de persistance, aucun héritage particulier n'est nécéssaire. Cela permet de compter sur ces POCO partout dans l'application sans se soucier des références. 

![](https://raw.githubusercontent.com/BlueInt32/prez/master/img/ClassDiagram.png)


![](https://raw.githubusercontent.com/BlueInt32/prez/master/img/ScreensCode/Code%20First/CollecteContext%20-%20POCO%20-%20Bundle.jpg) 


![](https://raw.githubusercontent.com/BlueInt32/prez/master/img/ScreensCode/Code%20First/CollecteContext%20-%20POCO%20-%20BundleFile.jpg)


![](https://raw.githubusercontent.com/BlueInt32/prez/master/img/ScreensCode/Code%20First/CollecteContext%20-%20POCO%20-%20BundleFileType.jpg)


![](https://raw.githubusercontent.com/BlueInt32/prez/master/img/ScreensCode/Code%20First/CollecteContext%20-%20POCO%20-%20BundleStatus.jpg)

Dans le POCO, on distingue 2 types de propriétés : les "propriétés scalaires" propres aux entités et les "propriétés de navigation" spécifiant les relations entre entités.

Sur les propriétés de navigation, le mot clef virtual permet d'utiliser le Lazy Loading.  


On peut désactiver le lazy-loading. [Définir : Lazy Loading]


###Création du contexte


C'est une classe qui dérive de DbContext, la brique de base d'EF Code First. 

Le contexte représente une session d'accès à la base de donnée, et permet de requeter et de sauvegarder des données. DbContext applique les patterns Unit Of Work et Repository Pattern, de sorte que les changements qu'on effectue sur celui-ci sont regroupés logiquement pour être appliqués d'un seul coup sous forme de transaction. 

![](https://raw.githubusercontent.com/BlueInt32/prez/master/img/ScreensCode/Code%20First/CollecteContext.jpg)

[Définir : [Unit Of Work](http://msdn.microsoft.com/en-us/magazine/dd882510.aspx), Repository Pattern]


Pour chaque type que l'ont veut persister dans la base, on doit créer dans notre contexte un DbSet correspondant. Le DbSet représente une collection d'entités, reflétant une table de la base.


> Attention : dans le constructeur, on spécifie plusieurs options notemment la manière dont la base est initialisée. Par défaut, Code First initialise une base "au besoin", ceci est à éviter : il **faut** contrôler soi-même les manipulations sur la base de données et spécifier qu'aucun Initializer ne doit être appliqué automatiquement.

###Utilisation du contexte

Le DbContext s'utilise comme classiquement dans Entity Framework, voici la creation, update et List pour les bundles : 

![](https://raw.githubusercontent.com/BlueInt32/prez/master/img/ScreensCode/Code%20First/Create_Bundle.jpg)

![](https://raw.githubusercontent.com/BlueInt32/prez/master/img/ScreensCode/Code%20First/Update_Bundle.jpg)

![](https://raw.githubusercontent.com/BlueInt32/prez/master/img/ScreensCode/Code%20First/List_Bundle.jpg)



###Systeme de migration
EF Code First fournit un ensemble de commandes permettant d'effectuer la migration du modele (DbContext) vers la base de données de manière incrémentale.
Après chaque modification du modele, on ajoute une migration décrivant le delta sur la base de données par rapport à l'état précédent détecté en base.
Ces migrations sont stockées dans la base de données dans une table nommée _Migration_History. Chaque migration référence les modifications effectuées.
EF stocke également par défaut localement les migrations effectuées dans un répertoire Migrations de l'assembly du DbContext, cela est désactivé si on actionne la migration automatique.


###Commandes
EF est embarqué avec plusieurs commandes saisissables dans Package Manager Console permettant d'effectuer les actions principales du framework. Voici les principales : 


`Enable-Migrations`

Cette commande initialise les migrations en créant un dossier Migrations et en y ajoutant une classe Configuration.cs qui contient les informations necessaires à leur gestion, notemment la valeur de propriété AutomaticMigrationsEnabled par défaut à false. Si cette valeur est à true, la commande `Add-migration` n'a pas à être utilisée et les migrations sont appliquées automatiquement sur la base.
![](https://raw.githubusercontent.com/BlueInt32/prez/master/img/ScreensCode/Code%20First/Enabling%20Migrations.jpg)


`Add-migration <Nomchoisi>`

Ceci ajoute un fichier de migration représentant le delta effectué dans la base, mais également l'eventuel rollback. Ceci ne modifie pas la base de données.

![](https://raw.githubusercontent.com/BlueInt32/prez/master/img/ScreensCode/Code%20First/Migrations%20Directory.jpg)

La classe générée hérite de DbMigration : 

![](https://raw.githubusercontent.com/BlueInt32/prez/master/img/ScreensCode/Code%20First/DbMigration%20Generated%20Code.jpg)

Code first refuse d'ajouter une nouvelle migration tant que la dernière migration est en attente ("pending") : 

![](https://raw.githubusercontent.com/BlueInt32/prez/master/img/ScreensCode/Code%20First/Add%20Migration%20Error.jpg)

`Update-Database`

Cette commande compare l'état de la base de données par rapport aux migrations créées en local et passe les modifications si besoin.
Note : si les migrations automatiques sont activées, cette seule commande suffit pour mettre à jour la base.
Les options suivantes sont très utiles: 

`Update-Database -force -verbose -script`

- `force` : quand la migration fait potentiellement perdre des données (drops), cela peut être utile. Sinon, EF remonte un warning.
- `verbose` : affiche l'ensemble des actions effectuées. On devrait toujours utiliser cette option.
- `script` : n'applique aucune modification sur la base, mais ouvre un fichier .sql avec les modifications apportées. Utile quand on n'est pas serein et/ou qu'on n'a pas d'accès à la base de données.
 
### ConnectionString
Lors de l'application des commandes, c'est dans **le projet de démarrage** qu'est récupérée la ConnectionString : pour appliquer des migrations il faut donc en général mettre le projet contenant le DbContext en projet de démarrage et vérifier la chaine de connexion désirée dans App.config.
Si EF ne trouve pas de configuration de connection, il créé par défaut une base LocalDB (successeur de SQLExpress) portant le nom qualifié de notre DbContext.
Attention : le nom de la connection doit être le même que le contexte : par exemple si le contexte porte le nom 
CollectContext, la connection string devra être : 
![](https://raw.githubusercontent.com/BlueInt32/prez/master/img/ScreensCode/Code%20First/collectContextConnectionString.png)


###Conventions :

Par défaut, Code First détecte les clefs primaires et étrangères en fonction des noms données aux propriétés du modele : 
par exemple le champ nommé Id ou ID est la clef primaire. Si plusieurs champs finissent par Id, c'est celui qui porte le nom de la classe qui constituera la clef primaire.

###Modifications du mapping par défaut
Il existe plusieurs moyens de changer le mapping par défaut effectué par Code First.

####Data Annotations
Il existe plusieurs attributs qu'on peut appliquer aux propriétés du modèle, en voici quelques unes : 
- Key : force la clef primaire sur ce champ
- StringLength(int) : détermine la taille maximale du champ. Attention : sur un string si rien n'est précisé, cela génère un varchar(Max) !
- Required : rejette les valeurs nulles.
- NotMapped : ce champ ne sera pas ajouté à la base de données.

![](https://raw.githubusercontent.com/BlueInt32/prez/master/img/ScreensCode/Code%20First/CollecteContext%20-%20POCO%20-%20Bundle.jpg)

####Fluent Api
Permet d'effectuer des modifications plus pointues que les dataAnnotations sur la génération de la base de données, ou d'aider EF à s'y retrouver quand on veut mapper une base déjà existante. Je n'ai pas expérimenté beaucoup ces fonctionnalités. On utilise la Fluent Api dans la méthode du DbContext `OnModelCreating` : 

![](https://raw.githubusercontent.com/BlueInt32/prez/master/img/ScreensCode/Code%20First/CollecteContext%20-%20OnModelCreating.jpg)
 

##Web API
La brique WebApi d'ASP.net permet de mettre en place des services "RESTful" accessibles dans un format d'échange compris par une large gamme de clients (dans mon cas JSON) : le point clef est l'interroperabilité.

Meme si cet aspect n'a pas été exploité dans ce projet, il aurait été relativement facile d'implémenter l'interface d'affichage dans une application desktop, sur iPhone ou n'importe quelle plateforme "Front".

Contrairement à ASP.net MVC, Web Api utilise le verbe HTTP pour déterminer quelle action de controlleur sera effectuée : 

- GET pour récupérer des données (liste ou élément unique)
- POST : pour enregistrer un nouvel element
- PUT : pour modifier un element
- DELETE : pour supprimer un élément

Ainsi pour le routing, on ne précisera plus l'action de controlleur, car elle sera mappée automatiquement en fonction du paramètres et du verbe HTTP.

###Routing

Le monitoring n'a besoin que de 2 accès GET : 

 - une liste des bundles, groupés par numéros de semaine
 - le contenu d'un fichier dont le chemin relatif est fourni en paramètre


    public IEnumerable< KeyValuePair< int, List< Bundle>>> GetAllBundles(){...}
et 

    public string Get(string path){...}


Cette méthode devra être accessible en GET via les routes de type `api/bundlefiles/[relative/path/to/file/filename.csv]`


La première route est définie par défaut dans la configuration de l'API (App_Start/WebApiConfig.cs par défaut) : 
![](https://raw.githubusercontent.com/BlueInt32/prez/master/img/ScreensCode/Web%20API/api_routing_1%20Default%20Routing.png)
>On note effectivement que le paramètre "action" n'est pas présent comme dans asp.net MVC : l'action de controlleur d'API est mappé grâce au verbe HTTP.

La seconde est définie en utilisant l'Attribute Routing : 

![](https://raw.githubusercontent.com/BlueInt32/prez/master/img/ScreensCode/Web%20API/api_routing_2%20Attribute%20Routing.png)


###Formatters
Par défaut, l'api pourra fournir plusieurs types mime différents : XML et Json. C'est le client de l'API qui décide avec le header HTTP "Accept" le type mime qu'il préfère.
Web api utilise des "media-type formatters" pour sérialiser/déserialiser des objets CLR : il est possible de définie ses propres formatters : csvFormatter par exemple.

 Voir : [json and xml serialization](http://www.asp.net/web-api/overview/formats-and-model-binding/json-and-xml-serialization)

![](https://raw.githubusercontent.com/BlueInt32/prez/master/img/ScreensCode/Web%20API/xml.jpg)

Il est possible de supprimer un formatter avec l'appel suivant dans la configuration de l'api : 

![](https://raw.githubusercontent.com/BlueInt32/prez/master/img/ScreensCode/Web%20API/config_api_remove_formatter.png)

### Authentification : filtre d'action
Les filtres d'action fonctionnent comme dans asp.net MVC : on peut les appliquer par action, par controlleur ou dans l'application toute entière. 
Les filtres servent souvent à effectuer des tâches transverses avant ou après l'action. J'ai protégé l'écran de monitoring de manière sommaire en dérivant `BasicAuthenticationFilter`, héritant lui-même de `AuthorizationFilterAttribute` : 
![](https://raw.githubusercontent.com/BlueInt32/prez/master/img/ScreensCode/Web%20API/Config_auth_filter_class.png)

Il est facile d'appliquer un filtre pour toutes les méthodes de l'api : ceci se fait dans la méthode Application_Start du fichier global.asax : 
![](https://raw.githubusercontent.com/BlueInt32/prez/master/img/ScreensCode/Web%20API/Config_auth_filter_add.png)

### Implémentation des actions

####Liste des bundles groupés par semaine

On utilise la méthode suivante pour grouper les bundles par semaine : 

![](https://raw.githubusercontent.com/BlueInt32/prez/master/img/ScreensCode/Web%20API/Logic_GroupBundlesByWeeks.png)

Et l'action de controlleur ne fait que rapatrier cela avec comme type de retour un IEnumerable : 
![](https://raw.githubusercontent.com/BlueInt32/prez/master/img/ScreensCode/Web%20API/apiBundlesList2.png)

![](https://raw.githubusercontent.com/BlueInt32/prez/master/img/ScreensCode/Web%20API/json.jpg)

TODO : comparer les résultats obtenus avec les réglages de serialisation de l'api.



##Front End Angular JS

[Voir tuto](https://github.com/mjhea0/thinkful-angular)

Angular JS est un framework javascript libre maintenu par Google et la communauté permettant de développer des applications riches coté client, ou des Single Page Applications.

Dans l'écran de Monitoring je n'ai pas eu besoin de plusieurs vues, ce qui simplifiera l'exposé.

![](https://raw.githubusercontent.com/BlueInt32/prez/master/img/ScreensCode/AngularJS/files.png)

### Le module
C'est la brique principale d'une application angularJS. De façon conventionelle on place le module principal d'une application dans le fichier app.js à la racine du répertoire JS. On déclare un module de la façon suivante : 

    angular.module('monitoringController', []);
	angular.module('app', ['myServices', 'monitoringController', 'monitoringDirectives']);

Un module est rattaché à une section du DOM à l'aide d'attributs HTML (qu'on appelle "directive") : 

    <body ng-app="app" ...>

Un module peut être comparé à la notion d'assembly .Net : on peut y ajouter des controleurs, des directives, des services et d'autres objets angular.

### Le controleur

Le controleur est, comme le module application, rattaché à une section du DOM à l'aide d'une directive ng-controller. 
	<body ng-app="app" ng-controller="mainCtrl">

> Note : on aurait pu placer la directive ng-controller sur n'importe quel sous élément de app.

A chaque portion de DOM sur laquelle un controleur a la main est associé un modele nommé $scope. $scope est relié par le moteur Angular à son controleur.

Suivant le pattern MVC, le controleur AngularJS modifie ce modele et le passe à la vue (fichier html modifié). Le data-binding peut alors se faire dans les deux sens.



### Quelques directives prédefinies 

##### ng-show et ng-hide
Lorsque l'on charge en Ajax les bundles de l'API, comme la connexion à la base de donnée peut être longue on voudrait afficher une zone de chargement. Pour cela, deux div et l'utilisation de deux directives angular, `ng-show` et `ng-hide` qui vont paramétrer la visibilité de chaque div : 

![](https://raw.githubusercontent.com/BlueInt32/prez/master/img/ScreensCode/AngularJS/index.zoomLoader.html.png)

Dans la déclaration du controller, on initialise à false un booléen dans le $scope : 
	$scope.showLoaderTree = true;

Et lorsque l'appel http se termine, 
	$scope.showLoaderTree = false;

##### ng-repeat

Cette directive permet de refléter un tableau javascript du $scope dans le DOM :
![](https://raw.githubusercontent.com/BlueInt32/prez/master/img/ScreensCode/AngularJS/index.zoomng-repeat.html.png)

On retrouve dans la déclaration du ng-repeat l'objet week rempli dans le callback http du controleur. L'objet week reflétant directement la list de KeyValuePair générée coté serveur, on voit qu'on peut utiliser la notation "moustache" pour afficher directement une propriété du sous-modele (en l'occurence une instance de keyValuePair
, soit une semaine de bundles) : 

	{{week.Key}}

### Directive custom

Il est bien sûr possible de déclarer ses propres directives. J'ai créé dans ce projet deux directives:  `bundle` qui encapsule un bundle, et `previewLink` dont l'objectif est de paramétrer les liens d'accès aux BundleFiles.

La déclaration d'une directive se fait de façon assez proche d'un controleur : 

	angular.module('monitoringDirectives', ['monitoringController'])
		.directive('bundle', [ function ()
		{
			return {
				restrict: 'E',
				templateUrl: 'bundle.partial.html',
				scope: {
					bundle: '=which'
				}			
			};
		}]);

Coté HTML :

	<bundle ng-repeat="bundle in week.Value | filter:mainFilter" which="bundle" />

Partial :

	<li>
		<span class="{{bundle.displayClass}}">{{bundle.Date}} &ndash; {{bundle.displayStatus}} </span>
		<ul>
			<li ng-if='bundle.NbInscriptions > 0'>
				<span>
					<span ng-if='bundle.NbInscriptions > 0'>Inscrits : {{bundle.NbInscriptions}}</span>
					<span ng-if='bundle.NbRetoursCanal > 0'>De Canal : {{bundle.NbRetoursCanal}}</span>
					<span ng-if='bundle.NbOk > 0'>Ok :  {{bundle.NbOk}}</span>
					<span ng-if='bundle.NbKo > 0'>Ko :  {{bundle.NbKo}}</span>
				</span>
			</li>
			<li ng-repeat="bundleFile in bundle.BundleFiles">
				<span><i class="icon-time"></i> {{bundleFile.CreationDate}}</span>
				<previewlink file="bundleFile">{{bundleFile.FileName}}</previewlink>
			</li>
		</ul>
	</li>



### Les dépendances
Pour attaquer une api an ajax, on va avoir besoin de charger un module externe : $http.
Les modules prédéfinis dans AngularJS sont préfixés d'un $.

Chaque module ou sous-élément AngularJS (controleur, service, directive) peut dépendre d'un module. On l'injecte en le sépcifiant dans la déclaration de l'objet.

![](https://raw.githubusercontent.com/BlueInt32/prez/master/img/ScreensCode/AngularJS/Controller.png)

Il existe une notation moins redondante pour charger les dépendances, mais elle ne résiste pas à la minification JS : en effet les noms des modules injectés dans les functions de déclaration sont reconnus
par AngularJS, or la minification peut les détruire. 


### La directive

### Le service





























