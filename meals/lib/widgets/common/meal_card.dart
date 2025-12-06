import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import '../../data/models/meal.dart';
import '../../services/image_service.dart';

/// A reusable meal card widget
class MealCard extends StatefulWidget {
  final Meal meal;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showDetails;
  final bool compact;

  const MealCard({
    super.key,
    required this.meal,
    this.onTap,
    this.onLongPress,
    this.showDetails = true,
    this.compact = false,
  });

  @override
  State<MealCard> createState() => _MealCardState();
}

class _MealCardState extends State<MealCard> {
  String? _imageUrl;
  bool _isLoadingImage = false;

  @override
  void initState() {
    super.initState();
    _initializeImage();
  }

  @override
  void didUpdateWidget(MealCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.meal.id != widget.meal.id ||
        oldWidget.meal.imageUrl != widget.meal.imageUrl) {
      _initializeImage();
    }
  }

  void _initializeImage() {
    if (widget.meal.imageUrl != null && widget.meal.imageUrl!.isNotEmpty) {
      _imageUrl = widget.meal.imageUrl;
    } else {
      _fetchImage();
    }
  }

  Future<void> _fetchImage() async {
    if (_isLoadingImage) return;

    setState(() => _isLoadingImage = true);

    try {
      // Use static method to get a food image based on meal name
      final url = await ImageService.getFoodImageUrl(widget.meal.name);
      if (mounted && url != null) {
        setState(() {
          _imageUrl = url;
          _isLoadingImage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingImage = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.compact) {
      return _buildCompactCard(context, theme);
    }

    return _buildFullCard(context, theme);
  }

  Widget _buildCompactCard(BuildContext context, ThemeData theme) {
    return Card(
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildImage(50, 50),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.meal.name,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.meal.calories != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${widget.meal.calories} cal',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Iconsax.arrow_right_3,
                color: theme.colorScheme.secondary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullCard(BuildContext context, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImage(double.infinity, double.infinity),
                  // Meal type badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black54
                            : Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.meal.mealType.isNotEmpty
                            ? widget.meal.mealType[0].toUpperCase() +
                                  widget.meal.mealType.substring(1)
                            : 'Meal',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.meal.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.1,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.meal.cuisine != null &&
                              widget.meal.cuisine!.isNotEmpty) ...[
                            const SizedBox(height: 1),
                            Text(
                              widget.meal.cuisine!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                color: theme.colorScheme.secondary,
                              ),
                              maxLines: 1,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (widget.showDetails)
                      Row(
                        children: [
                          if (widget.meal.calories != null) ...[
                            _buildInfoChip(
                              context,
                              Iconsax.flash_1,
                              '${widget.meal.calories}',
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (widget.meal.prepTime != null)
                            _buildInfoChip(
                              context,
                              Iconsax.clock,
                              '${widget.meal.prepTime}m',
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(double width, double height) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoadingImage) {
      return Container(
        width: width,
        height: height,
        color: isDark ? Colors.white10 : Colors.grey[200],
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_imageUrl == null || _imageUrl!.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: isDark ? Colors.white10 : Colors.grey[200],
        child: Icon(
          Iconsax.cake,
          size: 32,
          color: isDark ? Colors.white38 : Colors.grey,
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: _imageUrl!,
      width: width,
      height: height,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: isDark ? Colors.white10 : Colors.grey[200],
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        color: isDark ? Colors.white10 : Colors.grey[200],
        child: Icon(
          Iconsax.cake,
          size: 32,
          color: isDark ? Colors.white38 : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: theme.colorScheme.secondary),
        const SizedBox(width: 3),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
      ],
    );
  }
}
