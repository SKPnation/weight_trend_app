class WeightModel{
  final String weight;
  final DateTime timestamp;
  TrendType _type;
  final String uid;

  WeightModel({
    this.weight,
    this.timestamp,
    String trendType,
    this.uid
  }) {
    switch(trendType){
      case 'up':
        _type = TrendType.up;
        break;
      default:
        _type = TrendType.down;
    }
  }

  TrendType get type => _type;
}



enum TrendType { up, down }
