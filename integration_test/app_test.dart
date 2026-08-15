import 'package:abzarfile/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
void main(){IntegrationTestWidgetsFlutterBinding.ensureInitialized();testWidgets('launches the offline dashboard',(tester)async{await tester.pumpWidget(const ProviderScope(child:AbzarFileApp()));await tester.pumpAndSettle();expect(find.text('AbzarFile'),findsWidgets);});}
