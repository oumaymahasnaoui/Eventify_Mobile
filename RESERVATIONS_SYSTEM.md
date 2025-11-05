# 📝 Système de Gestion des Réservations - Eventify

## 🎯 Vue d'ensemble

Le système de gestion des réservations permet aux utilisateurs de :
- **Consulter** la liste des événements disponibles
- **Créer** des réservations pour les événements
- **Voir** toutes leurs réservations
- **Modifier** les détails d'une réservation
- **Supprimer** une réservation
- **Changer le statut** d'une réservation (en attente, confirmée, annulée)

---

## 📊 Modèles de données

### Event (Événement)
```dart
class Event {
  final int id;
  final String title;
  final DateTime date;
  final String location;
  final String description;
  final String category;
  final double? latitude;
  final double? longitude;
  final List<int> participants;
}
```

### Reservation
```dart
class Reservation {
  final int? id;
  final int eventId;           // Référence à l'événement
  final int userId;            // Référence à l'utilisateur
  final DateTime reservationDate;
  final int numberOfPeople;    // Nombre de personnes
  final String status;         // 'pending', 'confirmed', 'cancelled'
  final String? notes;         // Notes optionnelles
}
```

---

## 🗄️ Base de données

### Table `reservations`
```sql
CREATE TABLE reservations(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  event_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  reservation_date TEXT NOT NULL,
  number_of_people INTEGER NOT NULL,
  status TEXT DEFAULT 'pending',
  notes TEXT,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
)
```

### Méthodes CRUD disponibles

#### Créer une réservation
```dart
Future<int> createReservation(Reservation reservation)
```

#### Lire les réservations
```dart
Future<List<Reservation>> getAllReservations()
Future<List<Reservation>> getUserReservations(int userId)
Future<List<Reservation>> getEventReservations(int eventId)
Future<Reservation?> getReservationById(int id)
```

#### Mettre à jour une réservation
```dart
Future<int> updateReservation(Reservation reservation)
Future<int> updateReservationStatus(int id, String status)
```

#### Supprimer une réservation
```dart
Future<int> deleteReservation(int id)
```

#### Statistiques
```dart
Future<Map<String, int>> getUserReservationStats(int userId)
// Retourne: {'pending': 2, 'confirmed': 5, 'cancelled': 1, 'total': 8}
```

---

## 🖼️ Pages de l'interface

### 1. EventListPage
**Fichier**: `lib/modules/reservations/pages/event_list_page.dart`

**Fonctionnalités** :
- Liste des événements disponibles avec filtres par catégorie
- Catégories : Tous, Musique, Gastronomie, Sport, Culture, Technologie
- Affichage des détails de chaque événement
- Bouton "Réserver" pour créer une nouvelle réservation
- Design avec cartes colorées selon la catégorie

**Navigation** :
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => EventListPage(userId: userId),
  ),
);
```

---

### 2. CreateReservationPage
**Fichier**: `lib/modules/reservations/pages/create_reservation_page.dart`

**Fonctionnalités** :
- Affichage des détails de l'événement sélectionné
- Formulaire de réservation :
  - Nombre de personnes (1-10)
  - Notes optionnelles
- Validation des données
- Création de la réservation dans la base de données
- Redirection vers "Mes réservations" après succès

**Paramètres requis** :
```dart
CreateReservationPage({
  required Event event,
  required int userId,
})
```

---

### 3. MyReservationsPage
**Fichier**: `lib/modules/reservations/pages/my_reservations_page.dart`

**Fonctionnalités** :
- Affichage des statistiques (Total, En attente, Confirmées, Annulées)
- Filtres par statut
- Liste de toutes les réservations de l'utilisateur
- Actions rapides :
  - ✅ Confirmer une réservation
  - ❌ Annuler une réservation
  - ✏️ Modifier une réservation
  - 🗑️ Supprimer une réservation
- Pull-to-refresh pour actualiser la liste
- Bouton FAB "Nouvelle réservation"

**Navigation** :
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => MyReservationsPage(userId: userId),
  ),
);
```

---

### 4. EditReservationPage
**Fichier**: `lib/modules/reservations/pages/edit_reservation_page.dart`

**Fonctionnalités** :
- Affichage des informations de la réservation
- Modification :
  - Nombre de personnes
  - Statut (En attente, Confirmée, Annulée)
  - Notes
- Validation et sauvegarde
- Retour à la liste après succès

**Paramètres requis** :
```dart
EditReservationPage({
  required Reservation reservation,
})
```

---

## 🎨 Codes couleur des statuts

| Statut | Couleur | Icône |
|--------|---------|-------|
| `pending` (En attente) | Orange | `Icons.schedule` |
| `confirmed` (Confirmée) | Vert | `Icons.check_circle` |
| `cancelled` (Annulée) | Rouge | `Icons.cancel` |

---

## 🚀 Intégration dans l'application

### HomePage - Actions rapides
Le système de réservations est accessible depuis la page d'accueil via deux boutons :

1. **"Réserver un événement"** → `EventListPage`
2. **"Mes réservations"** → `MyReservationsPage`

```dart
_buildActionCard(
  icon: Icons.event_available,
  title: 'Réserver un événement',
  color: const Color(0xFFCE1126),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventListPage(userId: userId),
      ),
    );
  },
),
_buildActionCard(
  icon: Icons.bookmark,
  title: 'Mes réservations',
  color: Colors.purple,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyReservationsPage(userId: userId),
      ),
    );
  },
),
```

---

## 📝 Flux utilisateur

### Scénario 1 : Créer une réservation
1. Utilisateur clique sur "Réserver un événement" depuis l'accueil
2. Liste des événements s'affiche avec filtres par catégorie
3. Utilisateur sélectionne un événement
4. Formulaire de réservation s'ouvre
5. Utilisateur remplit le nombre de personnes et des notes (optionnel)
6. Utilisateur confirme
7. Réservation créée avec statut "En attente"
8. Redirection vers "Mes réservations"

### Scénario 2 : Gérer ses réservations
1. Utilisateur clique sur "Mes réservations" depuis l'accueil
2. Page affiche les statistiques et la liste des réservations
3. Utilisateur peut :
   - Filtrer par statut
   - Confirmer une réservation en attente
   - Annuler une réservation
   - Modifier les détails
   - Supprimer une réservation

---

## 🔔 Notifications et feedbacks

### SnackBars utilisés
- ✅ **Succès** (vert) : Réservation créée, mise à jour, supprimée
- ⚠️ **Avertissement** (orange) : Actions annulées
- ❌ **Erreur** (rouge) : Erreurs de validation ou de base de données

### Dialogues de confirmation
- Suppression de réservation

---

## 🎯 Événements de démonstration

L'application inclut 5 événements de test :

1. **Concert Jazz sous les étoiles** (Musique)
   - 15 Nov 2025, 20h00
   - Théâtre Municipal, Tunis

2. **Festival de Gastronomie** (Gastronomie)
   - 20 Nov 2025, 18h00
   - Marina de Sousse

3. **Marathon de Carthage** (Sport)
   - 1 Déc 2025, 07h00
   - Site archéologique de Carthage

4. **Exposition d'Art Contemporain** (Culture)
   - 25 Nov 2025, 10h00
   - Galerie El Marsa, La Marsa

5. **Conférence Tech & Innovation** (Technologie)
   - 5 Déc 2025, 09h00
   - Centre de Conférences, Lac 2

---

## 🛠️ Tests recommandés

### Tests unitaires
- [ ] Création de réservation
- [ ] Mise à jour de réservation
- [ ] Suppression de réservation
- [ ] Changement de statut
- [ ] Validation du nombre de personnes (1-10)

### Tests d'interface
- [ ] Navigation entre les pages
- [ ] Filtres par catégorie et statut
- [ ] Formulaires de création et édition
- [ ] Affichage des statistiques
- [ ] Pull-to-refresh

### Tests de base de données
- [ ] Migration de v1 à v2
- [ ] Contraintes de clés étrangères
- [ ] Cascade de suppression (user deleted → reservations deleted)

---

## 📦 Dépendances requises

```yaml
dependencies:
  flutter:
    sdk: flutter
  sqflite: ^2.3.0
  path_provider: ^2.1.1
  path: ^1.8.3
```

---

## 🔄 Version de la base de données

**Version actuelle** : `2`

**Changelog** :
- v1 : Table `users`
- v2 : Ajout de la table `reservations`

---

## 📧 Support

Pour toute question ou problème, contactez l'équipe de développement.

---

**Dernière mise à jour** : 30 Octobre 2025
**Version** : 1.0.0
