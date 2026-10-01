# Les d’Amours ❤️

PWA mobile-first pour deux personnes : planning, menus, to-do, courses, dépenses et remboursements.

## 0 €
Le projet est conçu pour rester utilisable avec des services gratuits. La partie locale fonctionne sans compte. La synchronisation entre deux téléphones utilise Supabase (free tier) et nécessite la création d’un projet gratuit.

## Lancer immédiatement en local
Un navigateur bloque parfois les service workers en ouvrant `index.html` directement. Utilise un petit serveur local :

```bash
python3 -m http.server 8080
```

Puis ouvre `http://localhost:8080`.

## Activer la synchronisation entre les deux téléphones
1. Crée un projet gratuit sur Supabase.
2. Dans **Authentication > Providers**, active Email.
3. Ouvre **SQL Editor** et exécute le contenu de `supabase.sql`.
4. Copie `config.example.js` en `config.js`.
5. Dans `config.js`, mets l’URL du projet et la **Publishable key** du projet.
6. Héberge le dossier sur GitHub Pages, Cloudflare Pages ou un autre hébergeur statique gratuit.
7. Sur le premier téléphone : crée un compte puis, dans les réglages, crée/rejoins le foyer selon la version de l’interface.

### Important
Le code fourni contient déjà le moteur de synchronisation et les tables SQL. Pour un premier déploiement, il reste à ajouter dans l’interface un petit écran « créer/rejoindre un foyer » si tu veux éviter toute manipulation technique ; c’est volontairement isolé pour que ce soit facile à ajouter sans toucher au reste de l’application.

## Sauvegarde
Réglages > Exporter produit un fichier JSON complet. Réglages > Importer permet de le restaurer.

## Fonctionnalités V1
- Planning hebdomadaire et navigation
- RDV par créneaux de 5 min, personne, catégorie, icône, adresse, notes et récurrence
- Menus matin/midi/soir avec notes et liens de recette
- To-do, priorités dont « Si tu as le temps », récurrences et messages motivants
- Courses partagées, articles habituels et suggestions basées sur l’historique
- Dépenses avec payeur, bénéficiaires, répartition personnalisée et remboursements
- PWA + mode local + export/import
