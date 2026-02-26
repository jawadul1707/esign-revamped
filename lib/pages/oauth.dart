import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';
import 'package:uni_links/uni_links.dart';
import 'package:crypt/pages/dashboard.dart';
import 'dart:io';
import 'global_variable.dart' as globals;

Map<String, dynamic>? decodeJwtPart(String part) {
  try {
    String normalized = part.replaceAll('-', '+').replaceAll('_', '/');
    int paddingNeeded = (4 - normalized.length % 4) % 4;
    String padded = normalized + '=' * paddingNeeded;
    String decoded = utf8.decode(base64Url.decode(padded));
    return jsonDecode(decoded) as Map<String, dynamic>;
  } catch (e) {
    if (kDebugMode) {
      print('Error decoding JWT part "$part": $e');
    }
    return null;
  }
}

class StatsService {
  static Future<Map<String, dynamic>?> fetchSignatureStats(
      String accessToken, String userId) async {
    var headers = {'Authorization': 'Bearer $accessToken'};
    var request = http.MultipartRequest(
        'GET', Uri.parse('${globals.uri}/sign-service/api/v1/stats/$userId'));

    request.headers.addAll(headers);

    try {
      http.StreamedResponse response = await request.send();
      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        return jsonDecode(responseBody) as Map<String, dynamic>;
      } else {
        if (kDebugMode) {
          print('Stats API Error: ${response.reasonPhrase}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Stats API Exception: $e');
      }
      return null;
    }
  }
}

class BalanceService {
  static Future<Map<String, dynamic>?> fetchUserBalance(
      String accessToken, String userId) async {
    var headers = {'Authorization': 'Bearer $accessToken'};
    var request = http.Request(
        'GET',
        Uri.parse(
            '${globals.uri}/billing-service/api/v1/subscription/balance/$userId'));

    request.headers.addAll(headers);

    try {
      http.StreamedResponse response = await request.send();
      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        return jsonDecode(responseBody) as Map<String, dynamic>;
      } else {
        if (kDebugMode) {
          print('Balance API Error: ${response.reasonPhrase}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Balance API Exception: $e');
      }
      return null;
    }
  }
}

class UserService {
  static Future<Map<String, dynamic>?> fetchUserDetails(
      String accessToken, String userId) async {
    final headers = <String, String>{
      if (accessToken.isNotEmpty) 'Authorization': 'Bearer $accessToken',
    };
    final request = http.Request(
      'GET',
      Uri.parse(
          '${globals.uri}/user-management-service/api/v1/user/get/$userId'),
    );

    request.headers.addAll(headers);

    try {
      http.StreamedResponse response = await request.send();
      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        final Map<String, dynamic> jsonResponse =
            jsonDecode(responseBody) as Map<String, dynamic>;
        return jsonResponse['data'] as Map<String, dynamic>?;
      } else {
        if (kDebugMode) {
          print('User API Error: ${response.reasonPhrase}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('User API Exception: $e');
      }
      return null;
    }
  }
}

class OAuthService {
  static final String authUrl = '${globals.authuri}/oauth2/authorize';
  static final String tokenUrl = '${globals.authuri}/oauth2/token';
  static const String clientId = 'esign-mobile-dc';
  static const String redirectUri = 'com.dohatecca.esign://login-callback';
  static const String scope = 'openid email profile';

  String? _storedCodeVerifier;
  String? _storedState;
  String? accessToken;
  Map<String, dynamic>? jwtPayload;
  StreamSubscription? _deepLinkSub;

  OAuthService() {
    _initDeepLinkListener();
  }

  void dispose() {
    _deepLinkSub?.cancel();
  }

  String _generateRandomString(int length) {
    const String chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random.secure();
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  String _generateCodeVerifier() {
    const String chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890-._~';
    Random rnd = Random.secure();
    return String.fromCharCodes(Iterable.generate(
        128, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  String _generateCodeChallenge(String codeVerifier) {
    var bytes = utf8.encode(codeVerifier);
    var digest = sha256.convert(bytes);
    return base64Url
        .encode(digest.bytes)
        .replaceAll('+', '-')
        .replaceAll('/', '_')
        .replaceAll('=', '');
  }

  Future<void> _initDeepLinkListener() async {
    try {
      final initialUri = await getInitialUri();
      if (kDebugMode) {
        print('Initial URI from getInitialUri(): $initialUri');
      }
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } on FormatException {
      if (kDebugMode) {
        print('Invalid initial URI');
      }
    }

    _deepLinkSub = uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    }, onError: (err) {
      if (kDebugMode) {
        print('Deep link error: $err');
      }
    });
  }

  void _handleDeepLink(Uri uri) {
    if (kDebugMode) {
      print('Deep link received: $uri');
    }

    // Check the scheme first (ensure it matches the registered intent/URI scheme)
    if (uri.scheme == 'com.dohatecca.esign') {
      // 1. Handle LOGIN (host: login-callback)
      if (uri.host == 'login-callback') {
        final authCode = uri.queryParameters['code'];
        final state = uri.queryParameters['state'];

        if (authCode != null && state != null) {
          if (_lastContext != null) {
            // Show loading and exchange code
            _showLoadingDialog(_lastContext!);
            exchangeCodeForToken(authCode, state, _lastContext!);
          }
        }
      }

      // 2. Handle LOGOUT (host: oauth2redirect)
      else if (uri.host == 'oauth2redirect') {
        if (kDebugMode) {
          print('User returned from successful logout');
        }

        if (_lastContext != null && _lastContext!.mounted) {
          // Navigate back to the very first screen (usually login/home)
          Navigator.of(_lastContext!).pushNamedAndRemoveUntil(
            '/',
            (route) => false,
          );
        }
      }
    }
  }

// Helper to keep code clean
  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  BuildContext? _lastContext;

  Future<void> startAuthorizationFlow(BuildContext context) async {
    _lastContext = context; // Store context for deep link navigation
    try {
      String codeVerifier = _generateCodeVerifier();
      String codeChallenge = _generateCodeChallenge(codeVerifier);
      String nonce = _generateRandomString(32);
      String state = _generateRandomString(32);

      if (kDebugMode) {
        print('Generated State: $state');
      }

      final authUri = Uri.parse(authUrl).replace(queryParameters: {
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': scope,
        'nonce': nonce,
        'state': state,
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
        // force the authorization server to show the login form every time
        'prompt': 'login',
      });

      if (kDebugMode) {
        print('Auth URL: ${authUri.toString()}');
      }

      bool launched = false;

      // Try standard launch first
      try {
        bool canLaunch = await canLaunchUrl(authUri);
        if (kDebugMode) {
          print('canLaunchUrl result: $canLaunch');
        }

        if (canLaunch) {
          await launchUrl(authUri, mode: LaunchMode.externalApplication);
          launched = true;
          _storedCodeVerifier = codeVerifier;
          _storedState = state;
          if (kDebugMode) {
            print('Stored State: $_storedState');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Standard launch threw exception: $e');
        }
      }

      // If standard launch failed, try fallbacks
      if (!launched && Platform.isAndroid) {
        if (kDebugMode) {
          print('Standard launch failed, trying Chrome fallback...');
        }
        bool chromeOpened = await _tryOpenInChrome(authUri);
        if (chromeOpened) {
          launched = true;
          _storedCodeVerifier = codeVerifier;
          _storedState = state;
          if (kDebugMode) {
            print('Opened via Chrome');
          }
        } else {
          // Try Firefox fallback
          if (kDebugMode) {
            print('Chrome fallback failed, trying Firefox...');
          }
          bool firefoxOpened = await _tryOpenInFirefox(authUri);
          if (firefoxOpened) {
            launched = true;
            _storedCodeVerifier = codeVerifier;
            _storedState = state;
            if (kDebugMode) {
              print('Opened via Firefox');
            }
          }
        }
      }

      // If launch still failed, show error dialog
      if (!launched) {
        if (kDebugMode) {
          print('Could not launch $authUri via any method');
        }
        if (context.mounted) {
          _showBrowserNotFoundDialog(context, authUri.toString());
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error launching auth URL: $e');
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<bool> _tryOpenInChrome(Uri authUri) async {
    try {
      // Try Chrome with intent scheme (Android-specific)
      final String url = authUri.toString();
      final String chromeUrl =
          'intent: $url#Intent;scheme=https;package=com.android.chrome;end';
      if (kDebugMode) {
        print('Trying Chrome intent: $chromeUrl');
      }
      bool canLaunchChrome = await canLaunchUrl(Uri.parse(chromeUrl));
      if (kDebugMode) {
        print('canLaunchUrl Chrome intent: $canLaunchChrome');
      }
      if (canLaunchChrome) {
        await launchUrl(Uri.parse(chromeUrl),
            mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (e) {
      if (kDebugMode) print('Chrome intent failed: $e');
    }

    // Fallback: try googlechrome:// scheme
    try {
      final String url = authUri.toString();
      final String chromeUrl = url.replaceFirst('https://', 'googlechrome://');
      if (kDebugMode) {
        print('Trying Chrome googlechrome:// scheme: $chromeUrl');
      }
      bool canLaunchChrome = await canLaunchUrl(Uri.parse(chromeUrl));
      if (kDebugMode) {
        print('canLaunchUrl Chrome googlechrome://: $canLaunchChrome');
      }
      if (canLaunchChrome) {
        await launchUrl(Uri.parse(chromeUrl),
            mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (e) {
      if (kDebugMode) print('Chrome googlechrome:// scheme failed: $e');
    }

    return false;
  }

  Future<bool> _tryOpenInFirefox(Uri authUri) async {
    try {
      final String url = authUri.toString();
      // Firefox uses intent scheme on Android
      final String firefoxUrl =
          'intent: $url#Intent;scheme=https;package=org.mozilla.firefox;end';
      if (kDebugMode) {
        print('Trying Firefox intent: $firefoxUrl');
      }
      bool canLaunchFirefox = await canLaunchUrl(Uri.parse(firefoxUrl));
      if (kDebugMode) {
        print('canLaunchUrl Firefox intent: $canLaunchFirefox');
      }
      if (canLaunchFirefox) {
        await launchUrl(Uri.parse(firefoxUrl),
            mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (e) {
      if (kDebugMode) print('Firefox intent failed: $e');
    }

    // Fallback: try firefox:// scheme
    try {
      final String url = authUri.toString();
      final String firefoxUrl = url.replaceFirst('https://', 'firefox://');
      if (kDebugMode) {
        print('Trying Firefox firefox:// scheme: $firefoxUrl');
      }
      bool canLaunchFirefox = await canLaunchUrl(Uri.parse(firefoxUrl));
      if (kDebugMode) {
        print('canLaunchUrl Firefox firefox://: $canLaunchFirefox');
      }
      if (canLaunchFirefox) {
        await launchUrl(Uri.parse(firefoxUrl),
            mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (e) {
      if (kDebugMode) print('Firefox firefox:// scheme failed: $e');
    }

    return false;
  }

  void _showBrowserNotFoundDialog(BuildContext context, String authUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Browser Not Found'),
        content: const Text(
          'No default browser is configured on your device. '
          'Please install and set a default browser (Chrome, Firefox, etc.), '
          'then try again.\n\n'
          'Alternatively, you can copy the login URL and open it manually in any browser.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dismiss'),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: authUrl));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Login URL copied to clipboard')),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Copy URL'),
          ),
        ],
      ),
    );
  }

  Future<void> clearBrowserSession() async {
    if (globals.idToken == null) {
      debugPrint('Cannot logout: ID Token is null');
      return;
    }

    // Use the Uri constructor to handle encoding automatically
    // The scheme must match what the app listens for (double slash).
    final logoutUri = Uri.parse('${globals.authuri}/connect/logout').replace(
      queryParameters: {
        'id_token_hint': globals.idToken,
        'post_logout_redirect_uri': 'com.dohatecca.esign://oauth2redirect',
      },
    );

    debugPrint(
        'Logout URL: $logoutUri'); // Check console to see if it looks correct

    if (await canLaunchUrl(logoutUri)) {
      // externalApplication is required to access the browser cookies
      await launchUrl(logoutUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> exchangeCodeForToken(
      String authCode, String returnedState, BuildContext context) async {
    if (kDebugMode) {
      print('Received State: $returnedState');
    }
    if (kDebugMode) {
      print('Stored State: $_storedState');
    }
    if (_storedCodeVerifier == null || _storedState == null) {
      if (kDebugMode) {
        print('Missing stored values');
      }
      return;
    }

    if (returnedState != _storedState) {
      if (kDebugMode) {
        print('State mismatch - possible CSRF attack');
      }
      return;
    }

    try {
      var headers = {'Content-Type': 'application/x-www-form-urlencoded'};

      var request = http.Request('POST', Uri.parse(tokenUrl));
      request.bodyFields = {
        'redirect_uri': redirectUri,
        'grant_type': 'authorization_code',
        'code': authCode,
        'code_verifier': _storedCodeVerifier!,
        'client_id': clientId,
      };
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        var jsonResponse = jsonDecode(responseBody);
        accessToken = jsonResponse['access_token'];
        String? idToken = jsonResponse['id_token'];
        globals.accessToken = accessToken;
        globals.idToken = idToken; // Store in global variable
        print('Access Token: $accessToken');
        print('ID Token: $idToken');

        if (accessToken != null) {
          List<String> tokenParts = accessToken!.split('.');
          if (tokenParts.length == 3) {
            try {
              Map<String, dynamic>? header = decodeJwtPart(tokenParts[0]);
              if (kDebugMode) {
                print('JWT Header: ${jsonEncode(header)}');
              }

              jwtPayload = decodeJwtPart(tokenParts[1]);
              if (kDebugMode) {
                print('JWT Payload: ${jsonEncode(jwtPayload)}');
              }

              if (jwtPayload != null) {
                String? userId = jwtPayload!['user_id']?.toString();
                Map<String, dynamic>? stats;
                Map<String, dynamic>? balance;
                Map<String, dynamic>? userDetails;

                if (userId != null) {
                  debugPrint('Authenticated userId: $userId');
                  globals.userid = userId;

                  stats = await StatsService.fetchSignatureStats(
                      accessToken!, userId);
                  balance = await BalanceService.fetchUserBalance(
                      accessToken!, userId);
                  userDetails =
                      await UserService.fetchUserDetails(accessToken!, userId);

                  if (userDetails != null) {
                    globals.mobileNumber = userDetails['phoneNo']?.toString();
                    globals.email = userDetails['email']?.toString();
                    globals.dOB = userDetails['dateOfBirth']?.toString();
                    globals.nameUser = userDetails['commonName']?.toString();
                    globals.father = userDetails['fathersName']?.toString();
                    globals.mother = userDetails['mothersName']?.toString();
                    globals.houseIdentifier =
                        userDetails['houseIdentifier']?.toString();
                    globals.streetAddress =
                        userDetails['streetAddress']?.toString();
                    globals.locality = userDetails['locality']?.toString();
                    globals.state = userDetails['state']?.toString();
                    globals.postalCode = userDetails['postalCode']?.toString();
                    globals.country = userDetails['country']?.toString();

                    final serialValue =
                        userDetails['serialNumberValue']?.toString();
                    globals.nidNumber =
                        serialValue != null ? int.tryParse(serialValue) : null;
                    globals.nidAsString = globals.nidNumber?.toString() ?? '';

                    debugPrint('User Details: ${jsonEncode(userDetails)}');
                  }
                }

                if (!context.mounted) return;

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserInfoScreen(
                      jwtPayload: jwtPayload!,
                      statsData: stats,
                      balanceData: balance,
                    ),
                  ),
                );
              }
            } catch (e) {
              if (kDebugMode) {
                print('Error decoding JWT: $e');
              }
            }
          } else {
            if (kDebugMode) {
              print('Invalid JWT format');
            }
          }
        }
      } else {
        String errorMessage = await response.stream.bytesToString();
        if (kDebugMode) {
          print('Error: ${response.statusCode} - ${response.reasonPhrase}');
          print('Error Details: $errorMessage');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Exception occurred: $e');
      }
    }
  }
}
