/*
DROP DATABASE IF EXISTS location_skis;

CREATE DATABASE IF NOT EXISTS location_skis;

USE location_skis;

CREATE TABLE clients (
    noCli INT AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(30) NOT NULL,
    prenom VARCHAR(30),
    adresse VARCHAR(120),
    cpo VARCHAR(5) NOT NULL,
    ville VARCHAR(80) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE fiches (
    noFic INT AUTO_INCREMENT PRIMARY KEY,
    noCli INT NOT NULL,
    dateCrea DATETIME NOT NULL,
    datePaye DATETIME,
    etat ENUM('SO', 'EC', 'RE') NOT NULL,
    FOREIGN KEY (noCli) REFERENCES clients(noCli)
) ENGINE=InnoDB;

CREATE TABLE gammes (
    codeGam CHAR(5) PRIMARY KEY,
    libelle VARCHAR(30) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE categories (
    codeCate CHAR(5) PRIMARY KEY,
    libelle VARCHAR(30) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE tarifs (
    codeTarif CHAR(5) PRIMARY KEY,
    libelle VARCHAR(30) NOT NULL,
    prixJour FLOAT NOT NULL
) ENGINE=InnoDB;

CREATE TABLE grilletarifs (
    codeGam CHAR(5),
    codeCate CHAR(5) NOT NULL,
    codeTarif CHAR(5),
    FOREIGN KEY (codeGam) REFERENCES gammes(codeGam),
    FOREIGN KEY (codeTarif) REFERENCES tarifs(codeTarif),
    FOREIGN KEY (codeCate) REFERENCES categories(codeCate)
) ENGINE=InnoDB;

CREATE TABLE articles (
    refart CHAR(8) PRIMARY KEY,
    designation VARCHAR(80) NOT NULL,
    codeGam CHAR(5),
    codeCate CHAR(5),
    FOREIGN KEY (codeGam) REFERENCES gammes(codeGam),
    FOREIGN KEY (codeCate) REFERENCES categories(codeCate)
) ENGINE=InnoDB;

CREATE TABLE lignesfic (
    noFic INT,
    noLig INT,
    refart CHAR(8) NOT NULL,
    depart DATETIME NOT NULL,
    retour DATETIME,
    FOREIGN KEY (noFic) REFERENCES fiches(noFic),
    FOREIGN KEY (refart) REFERENCES articles(refart)
) ENGINE=InnoDB;
*/

-- liste des clients dont le nom commence par d
SELECT * FROM clients WHERE nom LIKE 'd%';

-- nom et prénoms de tout les clients
SELECT nom, prenom FROM clients;

-- liste des fiches(n°, etat) pour les clients(nom,  prenom) qui habitent en Loire Atlantique (44)
SELECT fiches.noFic, fiches.etat, clients.nom, clients.prenom 
FROM fiches
JOIN clients ON fiches.noCli = clients.noCli
WHERE clients.cpo LIKE '44%'; 

-- details de la fiche n°1002
SELECT * FROM fiches WHERE noFic = 1002;

-- prix journalier moyen de location par gamme
SELECT gammes.libelle, AVG(tarifs.prixJour) AS prix_moyen
FROM gammes
JOIN grilletarifs ON gammes.codeGam = grilletarifs.codeGam
JOIN tarifs ON grilletarifs.codeTarif = tarifs.codeTarif
GROUP BY gammes.codeGam;

-- liste des articles qui ont été loués au moins 3 fois
SELECT articles.refart, articles.designation, COUNT(lignesfic.refart) AS nb_locations
FROM articles
JOIN lignesfic ON articles.refart = lignesfic.refart
GROUP BY articles.refart
HAVING nb_locations >= 3;

-- détail de la fiche n°1002 avec le total
SELECT fiches.noFic, fiches.etat, SUM(tarifs.prixJour) AS total
FROM fiches
JOIN lignesfic ON fiches.noFic = lignesfic.noFic
JOIN articles ON lignesfic.refart = articles.refart
JOIN grilletarifs ON articles.codeGam = grilletarifs.codeGam AND articles.codeCate = grilletarifs.codeCate
JOIN tarifs ON grilletarifs.codeTarif = tarifs.codeTarif
WHERE fiches.noFic = 1002
GROUP BY fiches.noFic;

-- grille des tarifs
SELECT gammes.libelle AS gamme, categories.libelle AS categorie, tarifs.libelle AS tarif, tarifs.prixJour
FROM gammes
JOIN grilletarifs ON gammes.codeGam = grilletarifs.codeGam
JOIN categories ON grilletarifs.codeCate = categories.codeCate
JOIN tarifs ON grilletarifs.codeTarif = tarifs.codeTarif;

-- liste des locations de la catégorie SURF
SELECT fiches.noFic, articles.designation, lignesfic.depart, lignesfic.retour
FROM fiches
JOIN lignesfic ON fiches.noFic = lignesfic.noFic
JOIN articles ON lignesfic.refart = articles.refart
JOIN categories ON articles.codeCate = categories.codeCate
WHERE categories.libelle = 'SURF';

-- calcul du nombre moyen d'articles loués par fiche de location
SELECT noFic, AVG(nb_articles) AS moyenne_articles
FROM (
    SELECT noFic, COUNT(refart) AS nb_articles
    FROM lignesfic
    GROUP BY noFic
) AS nb_articles_par_fiche;

-- calcul du nombre de fiches de location établies pour les catégories de location Ski alpin, Surf, Patinette
SELECT categories.libelle, COUNT(fiches.noFic) AS nb_fiches
FROM fiches
JOIN lignesfic ON fiches.noFic = lignesfic.noFic
JOIN articles ON lignesfic.refart = articles.refart
JOIN categories ON articles.codeCate = categories.codeCate
WHERE categories.libelle IN ('Ski alpin', 'Surf', 'Patinette')
GROUP BY categories.libelle;

-- calcul du montant moyen des fiches de location
SELECT AVG(total) AS montant_moyen
FROM (
    SELECT fiches.noFic, SUM(tarifs.prixJour) AS total
    FROM fiches
    JOIN lignesfic ON fiches.noFic = lignesfic.noFic
    JOIN articles ON lignesfic.refart = articles.refart
    JOIN grilletarifs ON articles.codeGam = grilletarifs.codeGam AND articles.codeCate = grilletarifs.codeCate
    JOIN tarifs ON grilletarifs.codeTarif = tarifs.codeTarif
    GROUP BY fiches.noFic
) AS total_par_fiche;

-- liste des clients (nom, prénom, adresse, code postal, ville) ayant au moins une fiche de location en cours
SELECT DISTINCT clients.nom, clients.prenom, clients.adresse, clients.cpo, clients.ville
FROM clients
JOIN fiches ON clients.noCli = fiches.noCli
WHERE fiches.etat = 'EC';

-- détail de la fiche de location de M. Dupond Jean de Paris (avec la désignation des articles loués, la date de départ et de retour)
SELECT fiches.noFic, articles.designation, lignesfic.depart, lignesfic.retour
FROM fiches
JOIN lignesfic ON fiches.noFic = lignesfic.noFic
JOIN articles ON lignesfic.refart = articles.refart
JOIN clients ON fiches.noCli = clients.noCli
WHERE clients.nom = 'Dupond' AND clients.prenom = 'Jean' AND clients.ville = 'Paris';

-- liste de tous les articles (référence, désignation et libellé de la catégorie) dont le libellé de la catégorie contient ski
SELECT articles.refart, articles.designation, categories.libelle
FROM articles
JOIN categories ON articles.codeCate = categories.codeCate
WHERE categories.libelle LIKE '%ski%';

-- calcul du montant de chaque fiche soldée et du montant total des fiches
SELECT fiches.noFic, SUM(tarifs.prixJour) AS total
FROM fiches
JOIN lignesfic ON fiches.noFic = lignesfic.noFic
JOIN articles ON lignesfic.refart = articles.refart
JOIN grilletarifs ON articles.codeGam = grilletarifs.codeGam AND articles.codeCate = grilletarifs.codeCate
JOIN tarifs ON grilletarifs.codeTarif = tarifs.codeTarif
WHERE fiches.etat = 'SO'
GROUP BY fiches.noFic
WITH ROLLUP;

-- calcul du nombre d’articles actuellement en cours de location

-- calcul du nombre d’articles loués, par client

-- liste des clients qui ont effectué (ou sont en train d’effectuer) plus de 200€ de location

-- liste de tous les articles (loués au moins une fois) et le nombre de fois où ils ont été loués, triés du plus loué au moins loué

-- liste des fiches (n°, nom, prénom) de moins de 150€

-- calcul de la moyenne des recettes de location de surf (combien peut-on espérer gagner pour une location d'un surf ?)

-- calcul de la durée moyenne d'une location d'une paire de skis (en journées entières)
