library jaguar.martini.core;

import 'dart:async';
import 'dart:convert';
import 'package:jaguar/jaguar.dart';
import 'package:jaguar_cache/jaguar_cache.dart';
import 'package:markd/markdown.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:jaguar_martini/collectors/collectors.dart';
import 'package:jaguar_martini/models/models.dart';

part 'composer.dart';
part 'processor.dart';
part 'writer.dart';

// Serves the static site
Future serve() async {
  final server = new Jaguar();

  // TODO

  await server.serve();
}

class CollectedPost {
  /// Metadata of the post
  PostMeta meta;

  /// Content of the post
  String content;

  CollectedPost(this.meta, this.content);
}

class ShortCodeCall {
  final String name;

  final Map<String, String> values;

  ShortCodeCall(this.name, this.values);

  String toString() => 'ShortCodeCall($name, $values)';

  static ShortCodeCall parse(String line) {
    String core = line.substring(3, line.length - 3);
    if(core.endsWith('/')) {
      core = core.substring(0, core.length - 1);
    }

    core = core.trim();

    final int nameIdx = core.indexOf(new RegExp('[ \t]'));
    final String name = core.substring(0, nameIdx);

    core = core.substring(nameIdx).trim();

    final values = <String, String>{};

    while(core.length != 0) {
      core = findArg(core, values).trim();
    }

    return new ShortCodeCall(name, values);
  }

  static String finaArgName(String core) {
    final Match match = new RegExp(r'([a-zA-Z0-9_]+)=').firstMatch(core);
    if(match == null) {
      throw new Exception('Invalid shortcode! (1)');
    }

    return match.group(1);
  }

  static String findArgValue(String core) {
    if(core.startsWith('"')) {
      final Match match = new RegExp(r'("[^\s]+")[\s]?').firstMatch(core);
      if(match == null) {
        throw new Exception('Invalid shortcode! (2)');
      }

      return match.group(1);
    } else {
      final Match match = new RegExp(r'([^\s]+)[\s]?').firstMatch(core);
      if(match == null) {
        throw new Exception('Invalid shortcode! (3)');
      }

      return match.group(1);
    }
  }

  static String findArg(String core, Map<String, String> values) {
    final String key = finaArgName(core);
    core = core.substring(key.length + 1);
    final String value = findArgValue(core);

    values[key] = !value.startsWith('"')? value: value.substring(1, value.length - 1);

    return core.substring(value.length);
  }
}

abstract class ShortCode {
  String get name;

  String transform(Map<String, String> params, String content);

  static bool isTag(String line) {
    if (!line.startsWith(r'{{<')) return false;
    if (!line.endsWith(r'>}}')) return false;

    return true;
  }

  static bool isEndTagNamed(String line, String name) {
    return line.startsWith(new RegExp(r'{{<[ \t]*/' + name + r'[ \t]*>}}$'));
  }

  static bool isSingleLineTag(String line) {
    if (!line.startsWith(r'{{<')) return false;
    if (!line.endsWith('/>}}')) return false;

    return true;
  }
}
