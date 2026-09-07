import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design/design.dart';
import '../../services/localization_service.dart';
import '../../services/recipe_image_service.dart';
import '../../services/translations.dart';
import 'recipe_models.dart';

/// Une recette dans une liste : sa photo, son nom, ce qu'elle coûte en temps
/// et en calories.
///
/// Le chiffre qui décide est à droite, comme partout ailleurs depuis la
/// refonte, et les macros restent en dessous du nom sans réclamer de couleur.
class RecipeListCard extends StatelessWidget {
  const RecipeListCard({
    super.key,
    required this.recipe,
    this.onTap,
    this.useSimpleMacros = false,
  });

  final Recipe recipe;
  final VoidCallback? onTap;

  /// Une seule ligne de macros au lieu de trois puces.
  final bool useSimpleMacros;

  @override
  Widget build(BuildContext context) {
    final lang = LocalizationService.instance.currentLanguageCode;

    return Pressable(
      onTap: onTap == null
          ? null
          : () {
              RyzeFeedback.select();
              onTap!();
            },
      child: Container(
        padding: EdgeInsets.all(context.vw(2.6)),
        decoration: BoxDecoration(
          color: RyzeColors.surf,
          borderRadius: BorderRadius.circular(RyzeRadius.md),
          border: Border.all(color: RyzeColors.line),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(RyzeRadius.sm),
              child: RecipeImageService.buildRecipeImage(
                imageUrl: recipe.image,
                width: context.vw(18.5),
                height: context.vw(18.5),
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: context.vw(3.6)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    recipe.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: RyzeText.body(context, 3.9, weight: FontWeight.w600),
                  ),
                  SizedBox(height: context.vw(1)),
                  Text(
                    '${recipe.duration} ${'recipe_minutes'.tr(lang)} · ${recipe.safeServings} ${'recipe_servings'.tr(lang)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: RyzeText.body(context, 3.1, color: RyzeColors.mute),
                  ),
                  SizedBox(height: context.vw(0.8)),
                  Text(
                    'P ${recipe.safeProteins} · G ${recipe.safeCarbs} · L ${recipe.safeFats}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: RyzeText.body(context, 3.0, color: RyzeColors.mute2),
                  ),
                ],
              ),
            ),
            SizedBox(width: context.vw(2.6)),
            Padding(
              padding: EdgeInsets.only(right: context.vw(1.5)),
              child: Text.rich(
                TextSpan(
                  style: RyzeText.body(context, 3.9, weight: FontWeight.w600).copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  children: [
                    TextSpan(text: '${recipe.safeCalories}'),
                    TextSpan(text: ' kcal', style: RyzeText.body(context, 3.0, color: RyzeColors.mute)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Une recette mise en avant : la photo tient la carte, le nom se pose dessus.
class RecipeCarouselCard extends StatelessWidget {
  const RecipeCarouselCard({super.key, required this.recipe, this.onTap});

  final Recipe recipe;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final lang = LocalizationService.instance.currentLanguageCode;

    return Pressable(
      onTap: onTap == null
          ? null
          : () {
              RyzeFeedback.select();
              onTap!();
            },
      child: SizedBox(
        width: context.vw(56),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(RyzeRadius.md),
          child: Stack(
            fit: StackFit.expand,
            children: [
              RecipeImageService.buildRecipeImage(
                imageUrl: recipe.image,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
              // Le nom doit rester lisible quelle que soit la photo.
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [RyzeColors.ink.withValues(alpha: 0.82), RyzeColors.ink.withValues(alpha: 0)],
                      stops: const [0, 0.62],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: context.vw(3.6),
                right: context.vw(3.6),
                bottom: context.vw(3.1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      recipe.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: RyzeText.body(context, 3.9, weight: FontWeight.w600, color: RyzeColors.surf, height: 1.2),
                    ),
                    SizedBox(height: context.vw(1)),
                    Text(
                      '${recipe.safeCalories} kcal · ${recipe.duration} ${'recipe_minutes'.tr(lang)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: RyzeText.body(context, 3.0, color: RyzeColors.surf.withValues(alpha: 0.82)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Un filtre actif : ce qu'il retient, et la croix qui l'enlève.
class ActiveFilterChip extends StatelessWidget {
  const ActiveFilterChip({super.key, required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () {
        RyzeFeedback.removed();
        onRemove();
      },
      child: Container(
        padding: EdgeInsets.fromLTRB(context.vw(3.1), context.vw(1.8), context.vw(2.3), context.vw(1.8)),
        decoration: BoxDecoration(
          color: RyzeColors.ink,
          borderRadius: BorderRadius.circular(RyzeRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: RyzeText.body(context, 3.1, weight: FontWeight.w600, color: RyzeColors.surf)),
            SizedBox(width: context.vw(1.5)),
            Icon(LucideIcons.x, size: context.vw(3.3), color: RyzeColors.surf.withValues(alpha: 0.8)),
          ],
        ),
      ),
    );
  }
}
