class Album {
  final String entregador;
  final String nrocp;
  final String turno;
  final String puerto;
  final String titular;
  final String chasis;
  final String producto;
  final String situacion;
  final String analisis;

  const Album({
    required this.entregador,
    required this.nrocp,
    required this.turno,
    required this.puerto,
    required this.titular,
    required this.chasis,
    required this.producto,
    required this.situacion,
    required this.analisis,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      entregador: json['entregador'] ?? '',
      nrocp: json['nrocp'] ?? '',
      turno: json['turno'] ?? '',
      puerto: json['puerto'] ?? '',
      titular: json["titular"] ?? '',
      chasis: json["chasis"] ?? '',
      producto: json["producto"] ?? '',
      situacion: json["situacion"] ?? '',
      analisis: json["analisis"] ?? '',
    );
  }
}
