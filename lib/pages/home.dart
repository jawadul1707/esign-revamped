import 'package:crypt/theme.dart';
import 'package:flutter/material.dart';
import 'package:crypt/pages/oauth.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<HomePage> {
  bool _isImagePrecached = false;
  double _opacity = 0.0;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isImagePrecached) {
      precacheImage(const AssetImage('assets/dohatecesign.png'), context)
          .then((_) {
        if (!mounted) return;
        setState(() => _opacity = 1.0);
      });
      _isImagePrecached = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: _buildUI(context),
    );
  }

  /// Builds the main UI with a gradient background and centered content
  Widget _buildUI(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 32, // Account for padding
              ),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.center,
                        child: _buildWelcomeImage(),
                      ),
                    ),
                    _buildTitleText(),
                    const SizedBox(height: 20),
                    _buildButtonSection(context),
                    _buildVersionText(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Displays the welcome image with animation
  Widget _buildWelcomeImage() {
    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(seconds: 2),
      child: SizedBox(
        width: 152,
        height: 152,
        child: Image.asset(
          'assets/dohatecesign.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  /// Builds the section containing all buttons
  Widget _buildButtonSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        children: [
          _buildSignUpButton(context),
          const SizedBox(height: 8),
          _buildLoginButton(context),
          const SizedBox(height: 8),
          _buildQRCodeButton(context),
        ],
      ),
    );
  }

  /// Builds the Sign Up button
  Widget _buildCustomButton({
    required BuildContext context,
    required String label,
    required VoidCallback? onPressed,
    required Color foregroundColor,
    required Color backgroundColor,
    Widget? icon,
  }) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.9,
      height: 40,
      child: ElevatedButton(
        onPressed: onPressed,
        style: customButtonStyle(
          foregroundColor: foregroundColor,
          backgroundColor: backgroundColor,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              icon,
              const SizedBox(width: 8),
            ],
            Text(label, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpButton(BuildContext context) {
    return _buildCustomButton(
      context: context,
      label: 'Sign up',
      onPressed: () => _navigateToPage('/mobile-number'),
      foregroundColor: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.secondary,
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    final oauthService = Provider.of<OAuthService>(context, listen: false);

    return _buildCustomButton(
      context: context,
      label: 'Login',
      onPressed: _isLoading
          ? null
          : () async {
              setState(() => _isLoading = true);
              try {
                await oauthService.startAuthorizationFlow(context);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Login failed: $e')),
                );
              } finally {
                if (!mounted) return;
                setState(() => _isLoading = false);
              }
            },
      foregroundColor: Theme.of(context).colorScheme.secondary,
      backgroundColor: Theme.of(context).colorScheme.primary,
      icon: _isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(
                  Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildQRCodeButton(BuildContext context) {
    return _buildCustomButton(
      context: context,
      label: 'Verify with QR code',
      onPressed: () => _navigateToPage('/qr-scanner'),
      foregroundColor: const Color(0xFF009973),
      backgroundColor: Theme.of(context).colorScheme.tertiary,
      icon:
          const Icon(Icons.qr_code_scanner, size: 20, color: Color(0xFF009973)),
    );
  }

  /// Builds the footer text with version and description
  Widget _buildTitleText() {
    return Text(
      'Dohatec e-Sign is an online e-Signature service developed by Dohatec CA (Certifying Authority) in Dohatec New Media',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall,
    );
  }

  /// Builds the version text
  Widget _buildVersionText() {
    return Text(
      'Version: 1.0.7',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }

  /// Navigates to a new page with error handling
  void _navigateToPage(String route) {
    try {
      Navigator.pushNamed(context, route);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Navigation failed: $e')),
      );
    }
  }
}
