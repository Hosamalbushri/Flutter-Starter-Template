// Architecture guardrail: enforces ObjectBox schema UID stability and model
// integrity.
//
// Rules enforced:
// 1. If ObjectBox is active (packages/database depends on objectbox), both
//    `objectbox-model.json` and `objectbox.g.dart` must exist.
// 2. Existing entity, property, and relation UIDs must never change or drift,
//    as changing UIDs corrupts on-device SQLite/ObjectBox databases.
// 3. Legitimate schema expansions (adding new entities or properties) are
//    permitted, provided new UIDs are strictly unique and do not reuse
//    retired/existing UIDs.
// 4. Distinguishes between intentional absence of ObjectBox (e.g. Drift engine)
//    and accidental omission of required schema files.
//
// Pure file-scan and JSON parsing; runs in normal `fvm flutter test` / CI flow.
// ignore_for_file: avoid_js_rounded_ints

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Committed baseline of entity and property UIDs that MUST remain stable.
/// Format: EntityName -> { 'uid': int, 'properties': { PropertyName: int } }
const Map<String, ObjectBoxEntityBaseline> kCommittedObjectBoxBaseline = {
  'BookmarkEntity': ObjectBoxEntityBaseline(
    id: 1,
    uid: 8542772984841996240,
    properties: {
      'id': (id: 1, uid: 8567576389194229962, type: 6),
      'title': (id: 2, uid: 6980862471056114681, type: 9),
      'url': (id: 3, uid: 2996858872217884918, type: 9),
      'description': (id: 4, uid: 5968208247687853418, type: 9),
      'tags': (id: 5, uid: 4634236816202482171, type: 30),
      'createdAt': (id: 6, uid: 5176080626139921728, type: 12),
      'updatedAt': (id: 7, uid: 5892767454409296107, type: 12),
      'uuid': (id: 8, uid: 2736399224269339936, type: 9),
      'serverUpdatedAt': (id: 9, uid: 5777725754888659017, type: 12),
      'syncStateCode': (id: 10, uid: 5606715827893123261, type: 6),
      'imageUrls': (id: 11, uid: 5870960339971504163, type: 30),
      'videoUrl': (id: 12, uid: 2425304307927444286, type: 9),
      'rev': (id: 13, uid: 1030815829066033616, type: 6),
    },
  ),
  'ActivityEntity': ObjectBoxEntityBaseline(
    id: 2,
    uid: 919939177363945290,
    properties: {
      'id': (id: 1, uid: 1252568795501351072, type: 6),
      'uuid': (id: 2, uid: 8712645750653639276, type: 9),
      'description': (id: 3, uid: 8458822913889059882, type: 9),
      'type': (id: 4, uid: 8330749528174122264, type: 9),
      'createdAt': (id: 5, uid: 3358862512730183168, type: 12),
    },
  ),
  'NotificationEntity': ObjectBoxEntityBaseline(
    id: 3,
    uid: 1349722681213321324,
    properties: {
      'id': (id: 1, uid: 5623171801112591648, type: 6),
      'uuid': (id: 2, uid: 3490771905479002669, type: 9),
      'title': (id: 3, uid: 2530253008106623603, type: 9),
      'body': (id: 4, uid: 4962516224363033753, type: 9),
      'type': (id: 5, uid: 6903004669254115199, type: 9),
      'isRead': (id: 6, uid: 3496464928661177200, type: 1),
      'createdAt': (id: 7, uid: 1877937495822827689, type: 12),
      'pendingRead': (id: 8, uid: 310238830684819705, type: 1),
    },
  ),
  'CollectionEntity': ObjectBoxEntityBaseline(
    id: 4,
    uid: 6914250643421223724,
    properties: {
      'id': (id: 1, uid: 2023590956800309880, type: 6),
      'uuid': (id: 2, uid: 2727045548820643396, type: 9),
      'name': (id: 3, uid: 7163441175278767034, type: 9),
      'icon': (id: 4, uid: 6568231165468057271, type: 9),
      'color': (id: 5, uid: 7202019221580211710, type: 6),
      'bookmarkIds': (id: 6, uid: 8485286719118650298, type: 30),
      'createdAt': (id: 7, uid: 7311607500392150555, type: 12),
      'updatedAt': (id: 8, uid: 7855977241027702413, type: 12),
      'serverUpdatedAt': (id: 9, uid: 2362733061684217003, type: 12),
      'syncStateCode': (id: 10, uid: 5607791206085802444, type: 6),
      'rev': (id: 11, uid: 2305123718041712993, type: 6),
    },
  ),
  'SyncCursorEntity': ObjectBoxEntityBaseline(
    id: 5,
    uid: 7251944359262926434,
    properties: {
      'id': (id: 1, uid: 4099947973977249183, type: 6),
      'resource': (id: 2, uid: 8892158510897589292, type: 9),
      'rev': (id: 3, uid: 7189263519970957346, type: 6),
    },
  ),
};

void main() {
  final isDriftActive = File(
    'packages/database/lib/src/app_database.dart',
  ).existsSync();

  group('ObjectBox schema presence and configuration', () {
    test(
      'distinguishes between intentional absence (Drift) and accidental omission',
      () {
        final dbPubspec = File('packages/database/pubspec.yaml');
        expect(
          dbPubspec.existsSync(),
          isTrue,
          reason: 'packages/database/pubspec.yaml must exist.',
        );

        final pubspecContent = dbPubspec.readAsStringSync();
        final declaresObjectBox = pubspecContent.contains('objectbox:');

        if (!declaresObjectBox || isDriftActive) {
          // Legitimate intentional absence: project is configured for Drift
          return;
        }

        // If ObjectBox is declared in pubspec, the model and binding MUST exist.
        final modelFile = File('packages/database/lib/objectbox-model.json');
        final bindingFile = File('packages/database/lib/objectbox.g.dart');

        expect(
          modelFile.existsSync(),
          isTrue,
          reason:
              'packages/database/pubspec.yaml declares objectbox, but '
              'packages/database/lib/objectbox-model.json is missing. '
              'ObjectBox schema model files must be committed.',
        );
        expect(
          bindingFile.existsSync(),
          isTrue,
          reason:
              'packages/database/pubspec.yaml declares objectbox, but '
              'packages/database/lib/objectbox.g.dart is missing. '
              'Committed ObjectBox binding must exist to prevent UID regeneration drift.',
        );
      },
    );
  });

  group('ObjectBox live schema integrity against baseline', () {
    test('model UIDs match committed baseline without drift', () {
      if (isDriftActive) return; // Skip when on Drift engine

      final modelFile = File('packages/database/lib/objectbox-model.json');
      if (!modelFile.existsSync()) return;

      final modelJson =
          jsonDecode(modelFile.readAsStringSync()) as Map<String, dynamic>;
      final violations = validateObjectBoxSchema(
        currentModel: modelJson,
        baseline: kCommittedObjectBoxBaseline,
      );

      expect(
        violations,
        isEmpty,
        reason:
            'ObjectBox schema model drift detected:\n\n'
            '${violations.map((v) => '  $v').join('\n')}',
      );
    });
  });

  group('ObjectBox schema integrity regression tests (mutations)', () {
    test('passes on valid model matching baseline', () {
      final validModel = _createMockModel(
        entities: [
          _createMockEntity(
            name: 'BookmarkEntity',
            idStr: '1:8542772984841996240',
            properties: [
              {'id': '1:8567576389194229962', 'name': 'id', 'type': 6},
            ],
          ),
        ],
      );

      final miniBaseline = {
        'BookmarkEntity': const ObjectBoxEntityBaseline(
          id: 1,
          uid: 8542772984841996240,
          properties: {'id': (id: 1, uid: 8567576389194229962, type: 6)},
        ),
      };

      final violations = validateObjectBoxSchema(
        currentModel: validModel,
        baseline: miniBaseline,
      );
      expect(violations, isEmpty);
    });

    test('rejects changed entity UID (UID drift)', () {
      final driftedModel = _createMockModel(
        entities: [
          _createMockEntity(
            name: 'BookmarkEntity',
            idStr: '1:8111222333444555666', // drifted UID!
            properties: [
              {'id': '1:8567576389194229962', 'name': 'id', 'type': 6},
            ],
          ),
        ],
      );

      final miniBaseline = {
        'BookmarkEntity': const ObjectBoxEntityBaseline(
          id: 1,
          uid: 8542772984841996240,
          properties: {'id': (id: 1, uid: 8567576389194229962, type: 6)},
        ),
      };

      final violations = validateObjectBoxSchema(
        currentModel: driftedModel,
        baseline: miniBaseline,
      );
      expect(violations, isNotEmpty);
      expect(
        violations.first,
        contains(
          'Entity "BookmarkEntity" UID changed from 8542772984841996240 to 8111222333444555666',
        ),
      );
    });

    test('rejects changed property UID (property UID drift)', () {
      final driftedModel = _createMockModel(
        entities: [
          _createMockEntity(
            name: 'BookmarkEntity',
            idStr: '1:8542772984841996240',
            properties: [
              {
                'id': '1:7777777777777777777',
                'name': 'id',
                'type': 6,
              }, // drifted!
            ],
          ),
        ],
      );

      final miniBaseline = {
        'BookmarkEntity': const ObjectBoxEntityBaseline(
          id: 1,
          uid: 8542772984841996240,
          properties: {'id': (id: 1, uid: 8567576389194229962, type: 6)},
        ),
      };

      final violations = validateObjectBoxSchema(
        currentModel: driftedModel,
        baseline: miniBaseline,
      );
      expect(violations, isNotEmpty);
      expect(
        violations.first,
        contains(
          'Property "BookmarkEntity.id" UID changed from 8567576389194229962 to 7777777777777777777',
        ),
      );
    });

    test('allows legitimate schema expansion with new unique UIDs', () {
      final expandedModel = _createMockModel(
        entities: [
          _createMockEntity(
            name: 'BookmarkEntity',
            idStr: '1:8542772984841996240',
            properties: [
              {'id': '1:8567576389194229962', 'name': 'id', 'type': 6},
              // New legitimate property added
              {'id': '2:3333333333333333333', 'name': 'isArchived', 'type': 1},
            ],
          ),
        ],
      );

      final miniBaseline = {
        'BookmarkEntity': const ObjectBoxEntityBaseline(
          id: 1,
          uid: 8542772984841996240,
          properties: {'id': (id: 1, uid: 8567576389194229962, type: 6)},
        ),
      };

      final violations = validateObjectBoxSchema(
        currentModel: expandedModel,
        baseline: miniBaseline,
      );
      expect(violations, isEmpty);
    });

    test('rejects reused UIDs across properties', () {
      final duplicateUidModel = _createMockModel(
        entities: [
          _createMockEntity(
            name: 'BookmarkEntity',
            idStr: '1:8542772984841996240',
            properties: [
              {'id': '1:8567576389194229962', 'name': 'id', 'type': 6},
              // Reusing existing property's UID!
              {'id': '2:8567576389194229962', 'name': 'duplicate', 'type': 9},
            ],
          ),
        ],
      );

      final miniBaseline = {
        'BookmarkEntity': const ObjectBoxEntityBaseline(
          id: 1,
          uid: 8542772984841996240,
          properties: {'id': (id: 1, uid: 8567576389194229962, type: 6)},
        ),
      };

      final violations = validateObjectBoxSchema(
        currentModel: duplicateUidModel,
        baseline: miniBaseline,
      );
      expect(violations, isNotEmpty);
      expect(violations.first, contains('Duplicate UID 8567576389194229962'));
    });

    test(
      'false positive test: adding an entirely new entity with unique UIDs is permitted',
      () {
        final modelWithNewEntity = _createMockModel(
          entities: [
            _createMockEntity(
              name: 'BookmarkEntity',
              idStr: '1:8542772984841996240',
              properties: [
                {'id': '1:8567576389194229962', 'name': 'id', 'type': 6},
              ],
            ),
            // Brand new entity added by a feature
            _createMockEntity(
              name: 'TagEntity',
              idStr: '2:1234567890123456789',
              properties: [
                {'id': '1:9876543210987654321', 'name': 'id', 'type': 6},
                {'id': '2:4567891234567891234', 'name': 'label', 'type': 9},
              ],
            ),
          ],
        );

        final miniBaseline = {
          'BookmarkEntity': const ObjectBoxEntityBaseline(
            id: 1,
            uid: 8542772984841996240,
            properties: {'id': (id: 1, uid: 8567576389194229962, type: 6)},
          ),
        };

        final violations = validateObjectBoxSchema(
          currentModel: modelWithNewEntity,
          baseline: miniBaseline,
        );
        expect(violations, isEmpty);
      },
    );

    test(
      'false negative test: property UID colliding with an entity UID is caught',
      () {
        final collidingModel = _createMockModel(
          entities: [
            _createMockEntity(
              name: 'BookmarkEntity',
              idStr: '1:8542772984841996240', // Entity UID
              properties: [
                // Property uses the same UID as the entity itself!
                {'id': '1:8542772984841996240', 'name': 'id', 'type': 6},
              ],
            ),
          ],
        );

        final violations = validateObjectBoxSchema(
          currentModel: collidingModel,
          baseline: const {},
        );
        expect(violations, isNotEmpty);
        expect(violations.first, contains('Duplicate UID 8542772984841996240'));
      },
    );

    test(
      'false positive test: adding an entirely new entity with unique UIDs is permitted',
      () {
        final modelWithNewEntity = _createMockModel(
          entities: [
            _createMockEntity(
              name: 'BookmarkEntity',
              idStr: '1:8542772984841996240',
              properties: [
                {'id': '1:8567576389194229962', 'name': 'id', 'type': 6},
              ],
            ),
            // Brand new entity added by a feature
            _createMockEntity(
              name: 'TagEntity',
              idStr: '2:1234567890123456789',
              properties: [
                {'id': '1:9876543210987654321', 'name': 'id', 'type': 6},
                {'id': '2:4567891234567891234', 'name': 'label', 'type': 9},
              ],
            ),
          ],
        );

        final miniBaseline = {
          'BookmarkEntity': const ObjectBoxEntityBaseline(
            id: 1,
            uid: 8542772984841996240,
            properties: {'id': (id: 1, uid: 8567576389194229962, type: 6)},
          ),
        };

        final violations = validateObjectBoxSchema(
          currentModel: modelWithNewEntity,
          baseline: miniBaseline,
        );
        expect(violations, isEmpty);
      },
    );

    test(
      'false negative test: property UID colliding with an entity UID is caught',
      () {
        final collidingModel = _createMockModel(
          entities: [
            _createMockEntity(
              name: 'BookmarkEntity',
              idStr: '1:8542772984841996240', // Entity UID
              properties: [
                // Property uses the same UID as the entity itself!
                {'id': '1:8542772984841996240', 'name': 'id', 'type': 6},
              ],
            ),
          ],
        );

        final violations = validateObjectBoxSchema(
          currentModel: collidingModel,
          baseline: const {},
        );
        expect(violations, isNotEmpty);
        expect(violations.first, contains('Duplicate UID 8542772984841996240'));
      },
    );
  });
}

final class ObjectBoxEntityBaseline {
  const ObjectBoxEntityBaseline({
    required this.id,
    required this.uid,
    required this.properties,
  });

  final int id;
  final int uid;
  final Map<String, ({int id, int uid, int type})> properties;
}

List<String> validateObjectBoxSchema({
  required Map<String, dynamic> currentModel,
  required Map<String, ObjectBoxEntityBaseline> baseline,
}) {
  final violations = <String>[];
  final entities = currentModel['entities'] as List<dynamic>? ?? const [];
  final seenUids = <int, String>{};

  for (final entityMap in entities.whereType<Map<String, dynamic>>()) {
    final entityName = entityMap['name'] as String?;
    final entityIdStr = entityMap['id'] as String?;
    if (entityName == null || entityIdStr == null) continue;

    final parts = entityIdStr.split(':');
    final entityUid = int.tryParse(parts.length > 1 ? parts[1] : parts[0]) ?? 0;

    if (seenUids.containsKey(entityUid)) {
      violations.add(
        'Duplicate UID $entityUid detected between entity "$entityName" and "${seenUids[entityUid]}"',
      );
    } else {
      seenUids[entityUid] = 'Entity $entityName';
    }

    final baselineEntity = baseline[entityName];
    if (baselineEntity != null) {
      if (baselineEntity.uid != entityUid) {
        violations.add(
          'Entity "$entityName" UID changed from ${baselineEntity.uid} to $entityUid. '
          'UID drift will cause ObjectBox migration failures on deployed devices!',
        );
      }
    }

    final properties = entityMap['properties'] as List<dynamic>? ?? const [];
    for (final propMap in properties.whereType<Map<String, dynamic>>()) {
      final propName = propMap['name'] as String?;
      final propIdStr = propMap['id'] as String?;
      final propType = propMap['type'] as int?;
      if (propName == null || propIdStr == null) continue;

      final propParts = propIdStr.split(':');
      final propUid =
          int.tryParse(propParts.length > 1 ? propParts[1] : propParts[0]) ?? 0;

      if (seenUids.containsKey(propUid)) {
        violations.add(
          'Duplicate UID $propUid detected between property "$entityName.$propName" and "${seenUids[propUid]}"',
        );
      } else {
        seenUids[propUid] = '$entityName.$propName';
      }

      if (baselineEntity != null) {
        final baselineProp = baselineEntity.properties[propName];
        if (baselineProp != null) {
          if (baselineProp.uid != propUid) {
            violations.add(
              'Property "$entityName.$propName" UID changed from ${baselineProp.uid} to $propUid.',
            );
          }
          if (propType != null && baselineProp.type != propType) {
            violations.add(
              'Property "$entityName.$propName" type changed from ${baselineProp.type} to $propType.',
            );
          }
        }
      }
    }

    final relations = entityMap['relations'] as List<dynamic>? ?? const [];
    for (final relMap in relations.whereType<Map<String, dynamic>>()) {
      final relName = relMap['name'] as String?;
      final relIdStr = relMap['id'] as String?;
      if (relName == null || relIdStr == null) continue;

      final relParts = relIdStr.split(':');
      final relUid =
          int.tryParse(relParts.length > 1 ? relParts[1] : relParts[0]) ?? 0;

      if (seenUids.containsKey(relUid)) {
        violations.add(
          'Duplicate UID $relUid detected between relation "$entityName.$relName" and "${seenUids[relUid]}"',
        );
      } else {
        seenUids[relUid] = 'Relation $entityName.$relName';
      }
    }
  }

  // Check if any baseline entity is missing
  for (final entry in baseline.entries) {
    final exists = entities.any(
      (e) => e is Map<String, dynamic> && e['name'] == entry.key,
    );
    if (!exists) {
      violations.add(
        'Required baseline entity "${entry.key}" is missing from objectbox-model.json',
      );
    }
  }

  return violations;
}

Map<String, dynamic> _createMockModel({
  required List<Map<String, dynamic>> entities,
}) => {
  '_note1': 'Mock model',
  'entities': entities,
  'lastEntityId': '1:1000',
  'lastIndexId': '0:0',
  'lastRelationId': '0:0',
  'lastSequenceId': '0:0',
  'modelVersion': 5,
  'modelVersionParserMinimum': 5,
  'version': 1,
};

Map<String, dynamic> _createMockEntity({
  required String name,
  required String idStr,
  required List<Map<String, dynamic>> properties,
}) => {
  'id': idStr,
  'lastPropertyId': '1:1',
  'name': name,
  'properties': properties,
};
