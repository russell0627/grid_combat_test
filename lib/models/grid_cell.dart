/// Defines different types of terrain a grid cell can have.
enum TerrainType {
  grass,
  water,
  wall,
  // Add more terrain types as needed
}

/// Represents a single cell in the game's logical grid.
class GridCell {
  final TerrainType terrainType;

  GridCell({this.terrainType = TerrainType.grass});

  /// Determines if the cell can be moved into.
  bool get isTraversable => terrainType != TerrainType.wall;

  GridCell copyWith({
    TerrainType? terrainType,
  }) {
    return GridCell(
      terrainType: terrainType ?? this.terrainType,
    );
  }
}
