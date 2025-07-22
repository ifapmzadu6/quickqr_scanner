import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickqr_scanner/quickqr_scanner_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelQuickqrScanner platform = MethodChannelQuickqrScanner();
  const MethodChannel channel = MethodChannel('quickqr_scanner');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('checkAvailability', () async {
    expect(await platform.checkAvailability(), isA<Map<String, dynamic>>());
  });
}
