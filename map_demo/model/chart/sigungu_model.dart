import 'dart:convert';

class SigunguFeatureCollection {
  final String type;
  final List<SigunguFeature> features;

  SigunguFeatureCollection({
    required this.type,
    required this.features,
  });

  factory SigunguFeatureCollection.fromJson(String str) => SigunguFeatureCollection.fromMap(json.decode(str));

  factory SigunguFeatureCollection.fromMap(Map<String, dynamic> json) => SigunguFeatureCollection(
        type: json["type"],
        features: List<SigunguFeature>.from(json["features"].map((x) => SigunguFeature.fromMap(x))),
      );
}

class SigunguFeature {
  final String type;
  final Geometry geometry;
  final Properties properties;

  SigunguFeature({
    required this.type,
    required this.geometry,
    required this.properties,
  });

  factory SigunguFeature.fromMap(Map<String, dynamic> json) => SigunguFeature(
        type: json["type"],
        geometry: Geometry.fromMap(json["geometry"]),
        properties: Properties.fromMap(json["properties"]),
      );
}

class Geometry {
  final String type;
  final List<List<List<double>>> coordinates;

  Geometry({
    required this.type,
    required this.coordinates,
  });

  factory Geometry.fromMap(Map<String, dynamic> json) => Geometry(
        type: json["type"],
        coordinates: List<List<List<double>>>.from(json["coordinates"].map((x) => List<List<double>>.from(x.map((x) => List<double>.from(x.map((x) => x.toDouble())))))),
      );
}

class Properties {
  final String sigCd;
  final String sigEngNm;
  final String sigKorNm;

  Properties({
    required this.sigCd,
    required this.sigEngNm,
    required this.sigKorNm,
  });

  factory Properties.fromMap(Map<String, dynamic> json) => Properties(
        sigCd: json["SIG_CD"],
        sigEngNm: json["SIG_ENG_NM"],
        sigKorNm: json["SIG_KOR_NM"],
      );
}
