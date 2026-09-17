# Spécification de Conception : Tableau de bord de régularité (سجل الالتزام والأوراد)

## 1. Objectif & Vision
Offrir aux utilisateurs un **tableau de bord de constance discret, motivant et 100% privé** (stocké localement sur l'appareil) pour les encourager à maintenir la récitation quotidienne de leurs Adhkar (Matin, Soir, et 5 Prières) selon le hadith :
> *« أَحَبُّ الأَعْمَالِ إِلَى اللَّهِ أَدْوَمُهَا وَإِنْ قَلَّ »* (رواه البخاري ومسلم).

---

## 2. Architecture & Modèle de Données

### A. Stockage Local (`SharedPreferences`)
- **Structure des données (`StreakData`)** :
  ```json
  {
    "2026-08-17": {
      "morning": true,
      "evening": false,
      "prayers": ["fajr", "dhuhr", "asr"],
      "totalDhikrCount": 120
    }
  }
  ```
- **Métriques calculées automatiquement** :
  1. **Série en cours (`currentStreak`)** : Nombre de jours consécutifs où au moins un wird (Matin, Soir ou Prière) a été accompli.
  2. **Meilleur record (`bestStreak`)** : Plus longue série consécutive jamais atteinte.
  3. **Total des séances (`totalCompletedSessions`)** : Cumul de toutes les sessions d'Adhkar complétées depuis l'installation.
  4. **Complétion du jour (`todayCompletion`)** : Statut en temps réel pour Matin, Soir, et chacune des 5 Prières.

---

## 3. Composants et Interfaces Utilisateur

### A. Carte Résumé sur l'Écran d'Accueil (`HomeScreen`)
- Située sous les cartes de catégories d'Adhkar.
- Affiche :
  - Badge de la série en cours : **🔥 7 أيام متتالية** (ou icône noble).
  - Indicateurs rapides de la journée : **الصباح ✓**, **المساء ⌛**, **الصلوات (3/5)**.
  - Bouton / Clic pour ouvrir l'écran complet : **عرض سجل الالتزام الكامل ←**.

### B. Écran Complet du Tableau de Bord (`StreakDashboardScreen`)
- **En-tête Glassmorphism** avec titre `سجل الالتزام`.
- **Cartes Statistiques Clés (Hero KPI Cards)** :
  - 🔥 **السلسلة الحالية** (Série actuelle en jours).
  - 🏆 **أفضل التزام** (Record de jours consécutifs).
  - 📿 **إجمالي الأوراد** (Nombre total de sessions d'Adhkar accomplies).
- **Suivi de la Journée en Cours (أوراد اليوم)** :
  - 🌅 **أذكار الصباح** (Accompli / À faire).
  - 🌇 **أذكار المساء** (Accompli / À faire).
  - 🕌 **أذكار الصلوات الخمس** (Fajr, Dhuhr, Asr, Maghrib, Isha avec compteurs détaillés).
- **Calendrier Mensuel Interactif (التقويم الشهري)** :
  - Navigation mois par mois (`<` Mois en cours `>`).
  - Grille complète des jours avec pastilles d'accomplissement :
    - 🟢 **Or / Émeraude vif** : Journée exemplaire (Matin + Soir + Prières).
    - 🟡 **Émeraude doux** : Journée avec au moins un wird accompli.
    - ⚪ **Gris discret** : Jour sans activité.
  - Clic sur n'importe quel jour pour afficher la modale détaillée des invocations récitées ce jour-là.
- **Hadith de rappel sur la constance** :
  - Citation noble de l'Imam An-Nawawi et du Prophète ﷺ sur la bénédiction de la régularité.

---

## 4. Intégration Automatique avec les Adhkar
- Dès que l'utilisateur atteint l'écran de complétion (`_CompletionView`) dans `AdhkarScreen` :
  - Enregistrement immédiat et silencieux de la complétion pour la catégorie correspondante (`morning`, `evening`, `after_fajr`, etc.).
  - Notification automatique du `StreakProvider` pour mettre à jour instantanément la carte d'accueil et le tableau de bord.

---

## 5. Plan de Vérification
1. Validation du calcul des streaks (série consécutive, saut de jour, calcul du record).
2. Vérification de l'enregistrement lors de la complétion des adhkar (Matin, Soir, Prières).
3. Test de l'affichage du calendrier en mode sombre et clair.
4. Build web et déploiement de test sur Cloudflare Pages.
