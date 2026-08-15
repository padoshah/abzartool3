import 'dart:convert';
import 'package:abzarfile/core/models/job_spec.dart';
import 'package:flutter_test/flutter_test.dart';
void main(){test('job specification preserves conversion options',(){const spec=JobSpec(inputPath:'/input.txt',outputPath:'/output.pdf',sourceFormat:'txt',targetFormat:'pdf',dpi:300,quality:80,stitchPages:true);final json=jsonDecode(spec.encode())! as Map<String,Object?>;expect(json['sourceFormat'],'txt');expect(json['targetFormat'],'pdf');expect(json['dpi'],300);expect(json['stitchPages'],isTrue);});}
