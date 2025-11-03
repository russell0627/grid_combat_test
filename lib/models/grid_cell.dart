/// Represents a single cell in the game's logical grid.
class GridCell {
  final bool isTraversable;

  GridCell({this.isTraversable = true});

  GridCell copyWith({
    bool? isTraversable,
  }) {
    return GridCell(
      isTraversable: isTraversable ?? this.isTraversable,
    );
  }
}
