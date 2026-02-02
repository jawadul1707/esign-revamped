import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';
import 'package:uni_links/uni_links.dart';
import 'package:crypt/pages/dashboard.dart';
import 'dart:io';
import 'global_variable.dart' as globals;

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

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
        'GET',
        Uri.parse(
            'https://staging-gw.e-sign.com.bd:9100/sign-service/api/v1/stats/$userId'));

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
            'https://staging-gw.e-sign.com.bd:9100/billing-service/api/v1/subscription/balance/$userId'));

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
  static const String authUrl =
      'https://staging-auth.e-sign.com.bd:9104/oauth2/authorize';
  static const String tokenUrl =
      'https://staging-auth.e-sign.com.bd:9104/oauth2/token';
  static const String clientId = 'esign_mobile';
  static const String redirectUri = 'com.example.app://login-callback';
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
    if (uri.scheme == 'com.example.app' && uri.host == 'login-callback') {
      final authCode = uri.queryParameters['code'];
      final state = uri.queryParameters['state'];
      if (authCode != null && state != null) {
        // Context must be provided externally (e.g., via startAuthorizationFlow)
        if (_lastContext != null) {
          exchangeCodeForToken(authCode, state, _lastContext!);
        } else {
          if (kDebugMode) {
            print('No BuildContext available for navigation');
          }
        }
      } else {
        if (kDebugMode) {
          print('Missing code or state in deep link');
        }
      }
    }
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
      });

      if (await canLaunchUrl(authUri)) {
        await launchUrl(authUri, mode: LaunchMode.inAppBrowserView);
        _storedCodeVerifier = codeVerifier;
        _storedState = state;
        if (kDebugMode) {
          print('Stored State: $_storedState');
        }
      } else {
        if (kDebugMode) {
          print('Could not launch $authUri');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error launching auth URL: $e');
      }
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
        globals.accessToken = accessToken; // Store in global variable
        print('Access Token: $accessToken');

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
                    globals.name = userDetails['commonName']?.toString();
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
